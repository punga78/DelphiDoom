{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotReplyChatLoader, BotLoadReplyChat                  }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): BotLoadReplyChat of }
{  code\botlib\be_ai_chat.c. Based on the Quake III Arena GPL Source Code      }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.ReplyChatLoader;

interface

uses
  System.Generics.Collections, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Chat.ReplyChat,
  DelphiDoom.BotAi.Chat.IntegrityChecker;

type
  /// <summary>Reads the file of reply chats: <c>[ keys ] = priority { messages }</c></summary>
  TBotReplyChatLoader = class
  strict private
    FImport: IBotImport;
    FFiles: IBotFileSource;
    FChecker: TBotChatIntegrityChecker;
    procedure ParseFile(const AFileName: AnsiString; const AList: TObjectList<TBotReplyChat>);
  public
    constructor Create(const AImport: IBotImport; const AFiles: IBotFileSource; const AChecker: TBotChatIntegrityChecker);
    /// <summary>
    ///   BotLoadReplyChat; with <c>ADeveloper</c> (bot_developer) the messages are checked afterwards.
    ///   False (list empty, the reason printed) if the file cannot be loaded.
    /// </summary>
    function Load(const AFileName: AnsiString; const AList: TObjectList<TBotReplyChat>; const ADeveloper: Boolean): Boolean;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Chat.Types,
  DelphiDoom.BotAi.Chat.Source, DelphiDoom.BotAi.Chat.MatchPieceReader, DelphiDoom.BotAi.Chat.MessageReader,
  DelphiDoom.BotAi.Chat.ReplyKeyChecker, DelphiDoom.BotAi.Chat.Message;

{ TBotReplyChatLoader }

constructor TBotReplyChatLoader.Create(const AImport: IBotImport; const AFiles: IBotFileSource;
  const AChecker: TBotChatIntegrityChecker);
begin
  inherited Create;
  FImport := AImport;
  FFiles := AFiles;
  FChecker := AChecker;
end;

procedure TBotReplyChatLoader.ParseFile(const AFileName: AnsiString; const AList: TObjectList<TBotReplyChat>);
var
  LSource: TBotChatSource;
  LToken: TIdToken;
  LReply: TBotReplyChat;
  LKey: TBotReplyChatKey;
  LNames: AnsiString;
begin
  LSource := TBotChatSource.Open(FImport, FFiles, AFileName);
  if LSource = nil then
  begin
    FImport.Print(PRT_ERROR, 'counldn''t load ' + AFileName + #10);
    raise EBotChatParseException.Create('counldn''t load ' + string(AFileName), string(AFileName), 0);
  end;
  try
    while LSource.ReadToken(LToken) do
    begin
      if TBotChatSource.CText(LToken) <> '[' then
        LSource.Fail('expected [, found ' + string(TBotChatSource.CText(LToken)));
      // the reply chats and their keys are put at the front
      LReply := TBotReplyChat.Create;
      AList.Insert(0, LReply);
      // read the keys, there must be at least one key
      repeat
        LKey := Default(TBotReplyChatKey);
        // MUST BE PRESENT and MUST BE ABSENT keys
        if LSource.CheckTokenString('&') then
          LKey.Flags := LKey.Flags or RCKFL_AND
        else if LSource.CheckTokenString('!') then
          LKey.Flags := LKey.Flags or RCKFL_NOT;
        // special keys
        if LSource.CheckTokenString('name') then
          LKey.Flags := LKey.Flags or RCKFL_NAME
        else if LSource.CheckTokenString('female') then
          LKey.Flags := LKey.Flags or RCKFL_GENDERFEMALE
        else if LSource.CheckTokenString('male') then
          LKey.Flags := LKey.Flags or RCKFL_GENDERMALE
        else if LSource.CheckTokenString('it') then
          LKey.Flags := LKey.Flags or RCKFL_GENDERLESS
        else if LSource.CheckTokenString('(') then
        begin
          LKey.Flags := LKey.Flags or RCKFL_VARIABLES;
          LKey.Match := TBotMatchPieceReader.Read(LSource, ')');
          if Length(LKey.Match) = 0 then
            raise EBotChatParseException.Create('no match pieces', LSource.FileName, 0);
        end
        else if LSource.CheckTokenString('<') then
        begin
          // bot names, separated by a backslash
          LKey.Flags := LKey.Flags or RCKFL_BOTNAMES;
          LNames := '';
          repeat
            LSource.ExpectTokenType(TT_STRING, 0, LToken);
            if LNames <> '' then
              LNames := LNames + '\';
            LNames := LNames + LToken.Text;
          until not LSource.CheckTokenString(',');
          LSource.ExpectTokenString('>');
          LKey.Text := LNames;
        end
        else
        begin
          LKey.Flags := LKey.Flags or RCKFL_STRING;
          LSource.ExpectTokenType(TT_STRING, 0, LToken);
          LKey.Text := LToken.Text;
        end;
        LReply.Keys.Insert(0, LKey);
        LSource.CheckTokenString(',');
      until LSource.CheckTokenString(']');
      TBotReplyKeyChecker.Check(LSource, LReply.Keys);
      // the = sign, the priority and the messages
      LSource.ExpectTokenString('=');
      LSource.ExpectTokenType(TT_NUMBER, 0, LToken);
      LReply.Priority := LToken.GetDoubleValue;
      LSource.ExpectTokenString('{');
      while not LSource.CheckTokenString('}') do
        LReply.Messages.Insert(0, TBotChatMessage.Create(TBotChatMessageReader.Read(LSource), -2 * CHATMESSAGE_RECENTTIME));
    end;
  finally
    LSource.Free;
  end;
end;

function TBotReplyChatLoader.Load(const AFileName: AnsiString; const AList: TObjectList<TBotReplyChat>;
  const ADeveloper: Boolean): Boolean;
begin
  AList.Clear;
  try
    ParseFile(AFileName, AList);
  except
    on EBotChatParseException do
    begin
      AList.Clear;
      Exit(False);
    end;
  end;
  FImport.Print(PRT_MESSAGE, 'loaded ' + AFileName + #10);
  if ADeveloper then
    FChecker.CheckReplyChats(AList);
  if AList.Count = 0 then
    FImport.Print(PRT_MESSAGE, 'no rchats'#10);
  Result := True;
end;

end.
