{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotWeightReader, the file of fuzzy weights            }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): ReadValue,          }
{  ReadFuzzyWeight, ReadFuzzySeperators_r and ReadWeightConfig of              }
{  code\botlib\be_ai_weight.c. Based on the Quake III Arena GPL Source Code    }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Weight.Reader;

interface

uses
  System.SysUtils, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Chat.Source, DelphiDoom.BotAi.Weight.Separator,
  DelphiDoom.BotAi.Weight.Config;

type
  /// <summary>
  ///   Reads <c>weight "name" { switch (n) { case v: return x; default: return balance(x, min, max); } }</c>.
  ///   The configuration is not cached here (see <c>TBotWeightCache</c>).
  /// </summary>
  TBotWeightReader = class
  strict private
    FImport: IBotImport;
    FFiles: IBotFileSource;
    class function ReadValue(const ASource: TBotChatSource): Single; static;
    class procedure ReadFuzzyWeight(const ASource: TBotChatSource; const ASeparator: TBotFuzzySeparator); static;
    class function ReadSeparators(const ASource: TBotChatSource): TBotFuzzySeparator; static;
    function ReadConfig(const ASource: TBotChatSource; const AFileName: AnsiString): TBotWeightConfig;
  public
    constructor Create(const AImport: IBotImport; const AFiles: IBotFileSource);
    /// <summary>
    ///   The reading of ReadWeightConfig (the file read from the base folder): nil if the file cannot be
    ///   read or has an error, which is reported to botimport.Print as the original does.
    /// </summary>
    function Read(const AFileName: AnsiString): TBotWeightConfig;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Chat.Types,
  DelphiDoom.BotAi.Weight.Types;

{ TBotWeightReader }

constructor TBotWeightReader.Create(const AImport: IBotImport; const AFiles: IBotFileSource);
begin
  inherited Create;
  FImport := AImport;
  FFiles := AFiles;
end;

class function TBotWeightReader.ReadValue(const ASource: TBotChatSource): Single;
var
  LToken: TIdToken;
begin
  ASource.ExpectAnyToken(LToken);
  if TBotChatSource.CText(LToken) = '-' then
  begin
    // the message says "set to zero", the original then takes the number without its sign
    ASource.Warning('negative value set to zero'#10);
    ASource.ExpectTokenType(TT_NUMBER, 0, LToken);
  end;
  if LToken.TokenType <> TT_NUMBER then
    ASource.Fail('invalid return value ' + string(TBotChatSource.CText(LToken)) + #10);
  Result := LToken.GetFloatValue;
end;

class procedure TBotWeightReader.ReadFuzzyWeight(const ASource: TBotChatSource; const ASeparator: TBotFuzzySeparator);
begin
  if ASource.CheckTokenString('balance') then
  begin
    ASeparator.WeightType := WT_BALANCE;
    ASource.ExpectTokenString('(');
    ASeparator.Weight := ReadValue(ASource);
    ASource.ExpectTokenString(',');
    ASeparator.MinWeight := ReadValue(ASource);
    ASource.ExpectTokenString(',');
    ASeparator.MaxWeight := ReadValue(ASource);
    ASource.ExpectTokenString(')');
  end
  else
  begin
    ASeparator.WeightType := 0;
    ASeparator.Weight := ReadValue(ASource);
    ASeparator.MinWeight := ASeparator.Weight;
    ASeparator.MaxWeight := ASeparator.Weight;
  end;
  ASource.ExpectTokenString(';');
end;

class function TBotWeightReader.ReadSeparators(const ASource: TBotChatSource): TBotFuzzySeparator;
var
  LToken: TIdToken;
  LIndex: Integer;
  LNewIndent: Boolean;
  LDefault: Boolean;
  LFoundDefault: Boolean;
  LCurrent: TBotFuzzySeparator;
  LLast: TBotFuzzySeparator;
  LFirst: TBotFuzzySeparator;
begin
  LFoundDefault := False;
  LFirst := nil;
  LLast := nil;
  ASource.ExpectTokenString('(');
  ASource.ExpectTokenType(TT_NUMBER, TT_INTEGER, LToken);
  LIndex := LToken.GetIntValue;
  ASource.ExpectTokenString(')');
  ASource.ExpectTokenString('{');
  ASource.ExpectAnyToken(LToken);
  try
    repeat
      LDefault := TBotChatSource.CText(LToken) = 'default';
      if LDefault or (TBotChatSource.CText(LToken) = 'case') then
      begin
        LCurrent := TBotFuzzySeparator.Create;
        LCurrent.Index := LIndex;
        if Assigned(LLast) then
          LLast.Next := LCurrent
        else
          LFirst := LCurrent;
        LLast := LCurrent;
        if LDefault then
        begin
          if LFoundDefault then
            ASource.Fail('switch already has a default'#10);
          LCurrent.Value := MAX_INVENTORYVALUE;
          LFoundDefault := True;
        end
        else
        begin
          ASource.ExpectTokenType(TT_NUMBER, TT_INTEGER, LToken);
          LCurrent.Value := LToken.GetIntValue;
        end;
        ASource.ExpectTokenString(':');
        ASource.ExpectAnyToken(LToken);
        LNewIndent := False;
        if TBotChatSource.CText(LToken) = '{' then
        begin
          LNewIndent := True;
          ASource.ExpectAnyToken(LToken);
        end;
        if TBotChatSource.CText(LToken) = 'return' then
          ReadFuzzyWeight(ASource, LCurrent)
        else if TBotChatSource.CText(LToken) = 'switch' then
          LCurrent.Child := ReadSeparators(ASource)
        else
          ASource.Fail('invalid name ' + string(TBotChatSource.CText(LToken)) + #10);
        if LNewIndent then
          ASource.ExpectTokenString('}');
      end
      else
        ASource.Fail('invalid name ' + string(TBotChatSource.CText(LToken)) + #10);
      ASource.ExpectAnyToken(LToken);
    until TBotChatSource.CText(LToken) = '}';
    if not LFoundDefault then
    begin
      ASource.Warning('switch without default'#10);
      LCurrent := TBotFuzzySeparator.Create;
      LCurrent.Index := LIndex;
      LCurrent.Value := MAX_INVENTORYVALUE;
      LCurrent.Weight := 0;
      if Assigned(LLast) then
        LLast.Next := LCurrent
      else
        LFirst := LCurrent;
    end;
  except
    LFirst.Free;
    raise;
  end;
  Result := LFirst;
end;

function TBotWeightReader.ReadConfig(const ASource: TBotChatSource; const AFileName: AnsiString): TBotWeightConfig;
var
  LToken: TIdToken;
  LName: AnsiString;
  LNewIndent: Boolean;
  LSeparator: TBotFuzzySeparator;
begin
  Result := TBotWeightConfig.Create(AFileName);
  try
    // parse the item config file
    while ASource.ReadToken(LToken) do
    begin
      if TBotChatSource.CText(LToken) = 'weight' then
      begin
        if Result.Count >= MAX_WEIGHTS then
        begin
          ASource.Warning('too many fuzzy weights'#10);
          Break;
        end;
        ASource.ExpectTokenType(TT_STRING, 0, LToken);
        LName := LToken.Text;
        ASource.ExpectAnyToken(LToken);
        LNewIndent := False;
        if TBotChatSource.CText(LToken) = '{' then
        begin
          LNewIndent := True;
          ASource.ExpectAnyToken(LToken);
        end;
        if TBotChatSource.CText(LToken) = 'switch' then
          LSeparator := ReadSeparators(ASource)
        else if TBotChatSource.CText(LToken) = 'return' then
        begin
          LSeparator := TBotFuzzySeparator.Create;
          try
            LSeparator.Index := 0;
            LSeparator.Value := MAX_INVENTORYVALUE;
            ReadFuzzyWeight(ASource, LSeparator);
          except
            LSeparator.Free;
            raise;
          end;
        end
        else
        begin
          ASource.Fail('invalid name ' + string(TBotChatSource.CText(LToken)) + #10);
          LSeparator := nil;
        end;
        try
          if LNewIndent then
            ASource.ExpectTokenString('}');
        except
          LSeparator.Free;
          raise;
        end;
        Result.Add(LName, LSeparator);
      end
      else
        ASource.Fail('invalid name ' + string(TBotChatSource.CText(LToken)) + #10);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TBotWeightReader.Read(const AFileName: AnsiString): TBotWeightConfig;
var
  LSource: TBotChatSource;
begin
  LSource := TBotChatSource.Open(FImport, FFiles, AFileName);
  if not Assigned(LSource) then
  begin
    FImport.Print(PRT_ERROR, 'counldn''t load ' + AFileName + #10);
    Exit(nil);
  end;
  try
    try
      Result := ReadConfig(LSource, AFileName);
    except
      // the source already printed the error (SourceError); the original returns NULL
      on EBotChatParseException do
        Exit(nil);
    end;
  finally
    LSource.Free;
  end;
  FImport.Print(PRT_MESSAGE, 'loaded ' + AFileName + #10);
end;

end.
