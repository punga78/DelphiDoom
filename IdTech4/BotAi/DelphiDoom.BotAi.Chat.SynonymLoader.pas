{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotSynonymLoader, BotLoadSynonyms                     }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): BotLoadSynonyms of  }
{  code\botlib\be_ai_chat.c. Based on the Quake III Arena GPL Source Code      }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.SynonymLoader;

interface

uses
  System.Generics.Collections, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Chat.SynonymList;

type
  /// <summary>
  ///   Reads the synonym file: contexts (numbers) with braces around lists of ("word", weight)
  ///   in square brackets. Like the original it reads the file twice (the first time to check it)
  ///   so the messages of the preprocessor are printed twice.
  /// </summary>
  TBotSynonymLoader = class
  strict private
    FImport: IBotImport;
    FFiles: IBotFileSource;
    procedure ParseFile(const AFileName: AnsiString; const AList: TObjectList<TBotSynonymList>; const ABuild: Boolean);
  public
    constructor Create(const AImport: IBotImport; const AFiles: IBotFileSource);
    /// <summary>BotLoadSynonyms: fills the list; false (list empty, the reason printed) if the file cannot be loaded</summary>
    function Load(const AFileName: AnsiString; const AList: TObjectList<TBotSynonymList>): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.BotAi.Types,
  DelphiDoom.BotAi.Chat.Types, DelphiDoom.BotAi.Chat.Source;

{ TBotSynonymLoader }

constructor TBotSynonymLoader.Create(const AImport: IBotImport; const AFiles: IBotFileSource);
begin
  inherited Create;
  FImport := AImport;
  FFiles := AFiles;
end;

procedure TBotSynonymLoader.ParseFile(const AFileName: AnsiString; const AList: TObjectList<TBotSynonymList>;
  const ABuild: Boolean);
var
  LSource: TBotChatSource;
  LToken: TIdToken;
  LContext: Cardinal;
  LContextStack: array[0..31] of Cardinal;
  LContextLevel: Integer;
  LSynonyms: TBotSynonymList;
  LCount: Integer;
  LText: AnsiString;
begin
  LSource := TBotChatSource.Open(FImport, FFiles, AFileName);
  if LSource = nil then
  begin
    FImport.Print(PRT_ERROR, 'counldn''t load ' + AFileName + #10);
    raise EBotChatParseException.Create('counldn''t load ' + string(AFileName), string(AFileName), 0);
  end;
  try
    LContext := 0;
    LContextLevel := 0;
    while LSource.ReadToken(LToken) do
    begin
      if LToken.TokenType = TT_NUMBER then
      begin
        LContext := LContext or LToken.GetUnsignedLongValue;
        LContextStack[LContextLevel] := LToken.GetUnsignedLongValue;
        Inc(LContextLevel);
        if LContextLevel >= 32 then
          LSource.Fail('more than 32 context levels');
        LSource.ExpectTokenString('{');
      end
      else if LToken.TokenType = TT_PUNCTUATION then
      begin
        if LToken.Text = '}' then
        begin
          Dec(LContextLevel);
          if LContextLevel < 0 then
            LSource.Fail('too many }');
          LContext := LContext and not LContextStack[LContextLevel];
        end
        else if LToken.Text = '[' then
        begin
          LSynonyms := nil;
          if ABuild then
          begin
            LSynonyms := TBotSynonymList.Create(LContext);
            AList.Add(LSynonyms);
          end;
          LCount := 0;
          while True do
          begin
            LSource.ExpectTokenString('(');
            LSource.ExpectTokenType(TT_STRING, 0, LToken);
            LText := LToken.Text;
            if LText = '' then
              LSource.Fail('empty string');
            Inc(LCount);
            LSource.ExpectTokenString(',');
            LSource.ExpectTokenType(TT_NUMBER, 0, LToken);
            LSource.ExpectTokenString(')');
            if ABuild then
              LSynonyms.Add(LText, LToken.GetDoubleValue);
            if LSource.CheckTokenString(']') then
              Break;
            LSource.ExpectTokenString(',');
          end;
          if LCount < 2 then
            LSource.Fail('synonym must have at least two entries'#10);
        end
        else
          LSource.Fail('unexpected ' + string(LToken.Text));
      end;
    end;
    // the original frees the source and then reports on it (a use after free): here it reports first
    if LContextLevel > 0 then
      LSource.Fail('missing }');
  finally
    LSource.Free;
  end;
end;

function TBotSynonymLoader.Load(const AFileName: AnsiString; const AList: TObjectList<TBotSynonymList>): Boolean;
var
  LPass: Integer;
begin
  AList.Clear;
  try
    for LPass := 0 to 1 do
      ParseFile(AFileName, AList, LPass = 1);
  except
    on EBotChatParseException do
    begin
      AList.Clear;
      Exit(False);
    end;
  end;
  FImport.Print(PRT_MESSAGE, 'loaded ' + AFileName + #10);
  Result := True;
end;

end.
