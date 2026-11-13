{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotRandomListLoader, BotLoadRandomStrings             }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): BotLoadRandomStrings}
{  of code\botlib\be_ai_chat.c. Based on the Quake III Arena GPL Source Code   }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.RandomListLoader;

interface

uses
  System.Generics.Collections, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Chat.RandomList;

type
  /// <summary>Reads the file of random strings: <c>name = { message; message; }</c></summary>
  TBotRandomListLoader = class
  strict private
    FImport: IBotImport;
    FFiles: IBotFileSource;
    procedure ParseFile(const AFileName: AnsiString; const AList: TObjectList<TBotRandomList>; const ABuild: Boolean);
  public
    constructor Create(const AImport: IBotImport; const AFiles: IBotFileSource);
    /// <summary>BotLoadRandomStrings (two passes like the original); false if the file cannot be loaded</summary>
    function Load(const AFileName: AnsiString; const AList: TObjectList<TBotRandomList>): Boolean;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Chat.Types,
  DelphiDoom.BotAi.Chat.Source, DelphiDoom.BotAi.Chat.MessageReader;

{ TBotRandomListLoader }

constructor TBotRandomListLoader.Create(const AImport: IBotImport; const AFiles: IBotFileSource);
begin
  inherited Create;
  FImport := AImport;
  FFiles := AFiles;
end;

procedure TBotRandomListLoader.ParseFile(const AFileName: AnsiString; const AList: TObjectList<TBotRandomList>;
  const ABuild: Boolean);
var
  LSource: TBotChatSource;
  LToken: TIdToken;
  LRandom: TBotRandomList;
  LMessage: AnsiString;
begin
  LSource := TBotChatSource.Open(FImport, FFiles, AFileName);
  if LSource = nil then
  begin
    FImport.Print(PRT_ERROR, 'counldn''t load ' + AFileName + #10);
    raise EBotChatParseException.Create('counldn''t load ' + string(AFileName), string(AFileName), 0);
  end;
  try
    LRandom := nil;
    while LSource.ReadToken(LToken) do
    begin
      if LToken.TokenType <> TT_NAME then
        LSource.Fail('unknown random ' + string(TBotChatSource.CText(LToken)));
      if ABuild then
      begin
        LRandom := TBotRandomList.Create(LToken.Text);
        AList.Add(LRandom);
      end;
      LSource.ExpectTokenString('=');
      LSource.ExpectTokenString('{');
      while not LSource.CheckTokenString('}') do
      begin
        LMessage := TBotChatMessageReader.Read(LSource);
        // the strings of a list are put at the front
        if ABuild then
          LRandom.Strings.Insert(0, LMessage);
      end;
    end;
  finally
    LSource.Free;
  end;
end;

function TBotRandomListLoader.Load(const AFileName: AnsiString; const AList: TObjectList<TBotRandomList>): Boolean;
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
