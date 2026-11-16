{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotInitialChatLoader, BotLoadInitialChat              }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): BotLoadInitialChat  }
{  of code\botlib\be_ai_chat.c. Based on the Quake III Arena GPL Source Code   }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.InitialChatLoader;

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Chat.Chat, DelphiDoom.BotAi.Chat.IntegrityChecker;

type
  /// <summary>Reads one chat of a chat file: <c>chat "name" { type "type" { messages } }</c></summary>
  TBotInitialChatLoader = class
  strict private
    FImport: IBotImport;
    FFiles: IBotFileSource;
    FChecker: TBotChatIntegrityChecker;
    function ParsePass(const AChatFile, AChatName: AnsiString; const ABuild: Boolean; var AFound: Boolean): TBotChat;
  public
    constructor Create(const AImport: IBotImport; const AFiles: IBotFileSource; const AChecker: TBotChatIntegrityChecker);
    /// <summary>
    ///   BotLoadInitialChat: the chat with the name (compared without case) or nil, the reason printed.
    ///   With <c>ADeveloper</c> (bot_developer) the messages are checked afterwards.
    /// </summary>
    function Load(const AChatFile, AChatName: AnsiString; const ADeveloper: Boolean): TBotChat;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.BotAi.Types,
  DelphiDoom.BotAi.Chat.Types, DelphiDoom.BotAi.Chat.Source, DelphiDoom.BotAi.Chat.MessageReader,
  DelphiDoom.BotAi.Chat.ChatType, DelphiDoom.BotAi.Chat.Message, DelphiDoom.BotAi.Chat.Text;

{ TBotInitialChatLoader }

constructor TBotInitialChatLoader.Create(const AImport: IBotImport; const AFiles: IBotFileSource;
  const AChecker: TBotChatIntegrityChecker);
begin
  inherited Create;
  FImport := AImport;
  FFiles := AFiles;
  FChecker := AChecker;
end;

function TBotInitialChatLoader.ParsePass(const AChatFile, AChatName: AnsiString; const ABuild: Boolean;
  var AFound: Boolean): TBotChat;
var
  LSource: TBotChatSource;
  LToken: TIdToken;
  LName: AnsiString;
  LType: TBotChatType;
  LIndent: Integer;
begin
  Result := nil;
  LSource := TBotChatSource.Open(FImport, FFiles, AChatFile);
  if LSource = nil then
  begin
    FImport.Print(PRT_ERROR, 'counldn''t load ' + AChatFile + #10);
    raise EBotChatParseException.Create('counldn''t load ' + string(AChatFile), string(AChatFile), 0);
  end;
  try
    if ABuild then
      Result := TBotChat.Create;
    try
      while LSource.ReadToken(LToken) do
      begin
        if TBotChatSource.CText(LToken) <> 'chat' then
          LSource.Fail('unknown definition ' + string(TBotChatSource.CText(LToken)) + #10);
        LSource.ExpectTokenType(TT_STRING, 0, LToken);
        LName := LToken.Text;
        // after the chat name we expect an opening brace
        LSource.ExpectTokenString('{');
        if TBotChatText.SameTextAscii(LName, AChatName) then
        begin
          AFound := True;
          // read the chat types
          while True do
          begin
            LSource.ExpectAnyToken(LToken);
            if TBotChatSource.CText(LToken) = '}' then
              Break;
            if TBotChatSource.CText(LToken) <> 'type' then
              LSource.Fail('expected type found ' + string(TBotChatSource.CText(LToken)) + #10);
            LSource.ExpectTokenType(TT_STRING, 0, LToken);
            LSource.ExpectTokenString('{');
            LType := nil;
            if ABuild then
            begin
              LType := TBotChatType.Create(Copy(LToken.Text, 1, MAX_CHATTYPE_NAME - 1));
              Result.Types.Insert(0, LType);
            end;
            // read the chat messages, put at the front
            while not LSource.CheckTokenString('}') do
            begin
              LName := TBotChatMessageReader.Read(LSource);
              if ABuild then
                LType.Messages.Insert(0, TBotChatMessage.Create(LName, -2 * CHATMESSAGE_RECENTTIME));
            end;
          end;
        end
        else
        begin
          // skip the bot chat
          LIndent := 1;
          while LIndent <> 0 do
          begin
            LSource.ExpectAnyToken(LToken);
            if TBotChatSource.CText(LToken) = '{' then
              Inc(LIndent)
            else if TBotChatSource.CText(LToken) = '}' then
              Dec(LIndent);
          end;
        end;
      end;
    except
      Result.Free;
      raise;
    end;
  finally
    LSource.Free;
  end;
end;

function TBotInitialChatLoader.Load(const AChatFile, AChatName: AnsiString; const ADeveloper: Boolean): TBotChat;
var
  LPass: Integer;
  LFound: Boolean;
begin
  Result := nil;
  LFound := False;
  try
    for LPass := 0 to 1 do
    begin
      Result.Free;
      Result := ParsePass(AChatFile, AChatName, LPass = 1, LFound);
      // if the requested chat is not found
      if not LFound then
      begin
        FImport.Print(PRT_ERROR, 'couldn''t find chat ' + AChatName + ' in ' + AChatFile + #10);
        Exit(nil);
      end;
    end;
  except
    on EBotChatParseException do
    begin
      FreeAndNil(Result);
      Exit(nil);
    end;
  end;
  FImport.Print(PRT_MESSAGE, 'loaded ' + AChatName + ' from ' + AChatFile + #10);
  if ADeveloper then
    FChecker.CheckInitialChat(Result);
end;

end.
