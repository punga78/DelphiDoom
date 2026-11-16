{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotCharacterLoader, BotLoadCharacterFromFile          }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later):                     }
{  BotLoadCharacterFromFile of code\botlib\be_ai_char.c. Based on the Quake    }
{  III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id         }
{  Software, Inc.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Character.Loader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Chat.Source, DelphiDoom.BotAi.Character.Data;

type
  /// <summary>
  ///   Reads one skill level of a character file: <c>skill 1 { 0 "name" 1 0.5 ... }</c>. The
  ///   other levels are skipped. Defect of the original that is kept: a level that ends at the end of the file
  ///   (the closing brace is missing) is accepted, with a message.
  /// </summary>
  TBotCharacterLoader = class
  strict private
    FImport: IBotImport;
    FFiles: IBotFileSource;
    class procedure ReadLevel(const ASource: TBotChatSource; const ACharacter: TBotCharacter); static;
    class procedure SkipLevel(const ASource: TBotChatSource); static;
    function ReadFile(const ASource: TBotChatSource; const ACharacter: TBotCharacter; const ASkill: Integer): Boolean;
  public
    constructor Create(const AImport: IBotImport; const AFiles: IBotFileSource);
    /// <summary>
    ///   The character of the file for the skill level (a negative skill takes the first level);
    ///   nil, with the reason printed, if the file or the level is missing or the file has an error.
    /// </summary>
    function Load(const AFileName: AnsiString; const ASkill: Integer): TBotCharacter;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Chat.Types,
  DelphiDoom.BotAi.Character.Types;

{ TBotCharacterLoader }

constructor TBotCharacterLoader.Create(const AImport: IBotImport; const AFiles: IBotFileSource);
begin
  inherited Create;
  FImport := AImport;
  FFiles := AFiles;
end;

class procedure TBotCharacterLoader.ReadLevel(const ASource: TBotChatSource; const ACharacter: TBotCharacter);
var
  LToken: TIdToken;
  LIndex: Integer;
begin
  while True do
  begin
    try
      ASource.ExpectAnyToken(LToken);
    except
      // "while (PC_ExpectAnyToken(...))": at the end of the file the message is printed (by the source) and the
      // level that was read so far is the character, as in the original
      on EBotChatParseException do
        Break;
    end;
    if TBotChatSource.CText(LToken) = '}' then
      Break;
    if (LToken.TokenType <> TT_NUMBER) or ((LToken.SubType and TT_INTEGER) = 0) then
      ASource.Fail('expected integer index, found ' + string(TBotChatSource.CText(LToken)) + #10);
    LIndex := LToken.GetIntValue;
    if (LIndex < 0) or (LIndex > MAX_CHARACTERISTICS) then
      ASource.Fail('characteristic index out of range [0, ' + IntToStr(MAX_CHARACTERISTICS) + ']'#10);
    if ACharacter.Characteristics[LIndex].CharType <> 0 then
      ASource.Fail('characteristic ' + IntToStr(LIndex) + ' already initialized'#10);
    ASource.ExpectAnyToken(LToken);
    if LToken.TokenType = TT_NUMBER then
    begin
      if (LToken.SubType and TT_FLOAT) <> 0 then
      begin
        ACharacter.Characteristics[LIndex].FloatValue := LToken.GetFloatValue;
        ACharacter.Characteristics[LIndex].CharType := CT_FLOAT;
      end
      else
      begin
        ACharacter.Characteristics[LIndex].IntegerValue := LToken.GetIntValue;
        ACharacter.Characteristics[LIndex].CharType := CT_INTEGER;
      end;
    end
    else if LToken.TokenType = TT_STRING then
    begin
      ACharacter.Characteristics[LIndex].StringValue := LToken.Text;
      ACharacter.Characteristics[LIndex].CharType := CT_STRING;
    end
    else
      ASource.Fail('expected integer, float or string, found ' + string(TBotChatSource.CText(LToken)) + #10);
  end;
end;

class procedure TBotCharacterLoader.SkipLevel(const ASource: TBotChatSource);
var
  LToken: TIdToken;
  LIndent: Integer;
begin
  LIndent := 1;
  while LIndent <> 0 do
  begin
    ASource.ExpectAnyToken(LToken);
    if TBotChatSource.CText(LToken) = '{' then
      Inc(LIndent)
    else if TBotChatSource.CText(LToken) = '}' then
      Dec(LIndent);
  end;
end;

function TBotCharacterLoader.ReadFile(const ASource: TBotChatSource; const ACharacter: TBotCharacter;
  const ASkill: Integer): Boolean;
var
  LToken: TIdToken;
begin
  Result := False;
  // a bot character is parsed in two phases
  while ASource.ReadToken(LToken) do
  begin
    if TBotChatSource.CText(LToken) = 'skill' then
    begin
      ASource.ExpectTokenType(TT_NUMBER, 0, LToken);
      ASource.ExpectTokenString('{');
      // if it's the correct skill
      if (ASkill < 0) or (LToken.GetUnsignedLongValue = Cardinal(ASkill)) then
      begin
        Result := True;
        ACharacter.Skill := LToken.GetUnsignedLongValue;
        ReadLevel(ASource, ACharacter);
        Break;
      end
      else
        SkipLevel(ASource);
    end
    else
      ASource.Fail('unknown definition ' + string(TBotChatSource.CText(LToken)) + #10);
  end;
end;

function TBotCharacterLoader.Load(const AFileName: AnsiString; const ASkill: Integer): TBotCharacter;
var
  LSource: TBotChatSource;
  LFound: Boolean;
begin
  LSource := TBotChatSource.Open(FImport, FFiles, AFileName);
  if not Assigned(LSource) then
  begin
    FImport.Print(PRT_ERROR, 'counldn''t load ' + AFileName + #10);
    Exit(nil);
  end;
  Result := TBotCharacter.Create;
  try
    Result.FileName := AFileName;
    try
      LFound := ReadFile(LSource, Result, ASkill);
    except
      // the source already printed the error (SourceError); the original returns NULL
      on EBotChatParseException do
        LFound := False;
    end;
  finally
    LSource.Free;
  end;
  if not LFound then
    FreeAndNil(Result);
end;

end.
