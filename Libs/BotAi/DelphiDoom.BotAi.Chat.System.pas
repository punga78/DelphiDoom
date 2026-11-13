{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotChatSystem, the chat AI of the bots                }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): code\botlib\        }
{  be_ai_chat.c. Based on the Quake III Arena GPL Source Code (id Software).   }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.System;

{$Q-}
{$R-}

interface

uses
  System.Generics.Collections, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Chat.Types,
  DelphiDoom.BotAi.Chat.Intf, DelphiDoom.BotAi.Chat.Chat, DelphiDoom.BotAi.Chat.State, DelphiDoom.BotAi.Chat.Tables,
  DelphiDoom.BotAi.Chat.ConsoleHeap, DelphiDoom.BotAi.Chat.RandomStrings, DelphiDoom.BotAi.Chat.SynonymReplacer,
  DelphiDoom.BotAi.Chat.Matcher, DelphiDoom.BotAi.Chat.MessageBuilder, DelphiDoom.BotAi.Chat.IntegrityChecker,
  DelphiDoom.BotAi.Chat.SynonymLoader, DelphiDoom.BotAi.Chat.RandomListLoader,
  DelphiDoom.BotAi.Chat.MatchTemplateLoader, DelphiDoom.BotAi.Chat.ReplyChatLoader,
  DelphiDoom.BotAi.Chat.InitialChatLoader, DelphiDoom.BotAi.Chat.Message;

type
  /// <summary>
  ///   The chat AI: the tables loaded by Setup, the chat states by handle and the cache of the chats
  ///   loaded from a file. The globals of the original are fields: two systems do not share anything.
  ///   Create it with <c>TBotChatFactory</c>.
  /// </summary>
  TBotChatSystem = class(TInterfacedObject, IBotChatSystem)
  strict private
    type
      TCachedChat = record
        Chat: TBotChat;
        FileName: AnsiString;
        ChatName: AnsiString;
      end;
  strict private
    FImport: IBotImport;
    FFiles: IBotFileSource;
    FLibVars: IBotLibVars;
    FRandom: IBotRandom;
    FTables: TBotChatTables;
    FHeap: TBotConsoleMessageHeap;
    FRandomStrings: TBotRandomStrings;
    FReplacer: TBotSynonymReplacer;
    FMatcher: TBotChatMatcher;
    FBuilder: TBotChatMessageBuilder;
    FChecker: TBotChatIntegrityChecker;
    FSynonymLoader: TBotSynonymLoader;
    FRandomListLoader: TBotRandomListLoader;
    FMatchTemplateLoader: TBotMatchTemplateLoader;
    FReplyChatLoader: TBotReplyChatLoader;
    FInitialChatLoader: TBotInitialChatLoader;
    FStates: array[0..BOT_MAX_CLIENTS] of TBotChatState;
    FCache: array[0..BOT_MAX_CLIENTS - 1] of TCachedChat;
    FChats: TObjectList<TBotChat>;
    FDeveloper: Boolean;
    function StateFromHandle(const AHandle: Integer): TBotChatState;
    function IsCached(const AChat: TBotChat): Boolean;
    procedure FreeChatFile(const AState: TBotChatState);
    procedure ReleaseState(const AState: TBotChatState);
    function ChooseInitialChatMessage(const AState: TBotChatState; const AType: AnsiString): AnsiString;
    function HasInitialMessage(const AState: TBotChatState; const AType: AnsiString; out AText: AnsiString): Boolean;
    class function BuildMatch(const ABase: AnsiString; const AVariables: TBotChatVariables): TBotMatch; static;
    function IsFuture(const AMessage: TBotChatMessage): Boolean;
  public
    constructor Create(const AImport: IBotImport; const AFiles: IBotFileSource; const ALibVars: IBotLibVars;
      const ARandom: IBotRandom);
    destructor Destroy; override;
    function Setup: Integer;
    procedure Shutdown;
    function AllocChatState: Integer;
    procedure FreeChatState(const AHandle: Integer);
    procedure QueueConsoleMessage(const AChatState, AMessageType: Integer; const AMessage: AnsiString);
    procedure RemoveConsoleMessage(const AChatState, AHandle: Integer);
    function NextConsoleMessage(const AChatState: Integer; out AMessage: TBotConsoleMessage): Integer;
    function NumConsoleMessages(const AChatState: Integer): Integer;
    procedure InitialChat(const AChatState: Integer; const AType: AnsiString; const AMessageContext: Integer;
      const AVariables: TBotChatVariables);
    function NumInitialChats(const AChatState: Integer; const AType: AnsiString): Integer;
    function ReplyChat(const AChatState: Integer; const AMessage: AnsiString; const AMessageContext,
      AVariableContext: Integer; const AVariables: TBotChatVariables): Boolean;
    function ChatLength(const AChatState: Integer): Integer;
    procedure EnterChat(const AChatState, AClientTo, ASendTo: Integer);
    function GetChatMessage(const AChatState, ASize: Integer): AnsiString;
    procedure SetChatGender(const AChatState, AGender: Integer);
    procedure SetChatName(const AChatState: Integer; const AName: AnsiString; const AClient: Integer);
    function LoadChatFile(const AChatState: Integer; const AChatFile, AChatName: AnsiString): Integer;
    procedure ResetChatAI;
    function FindMatch(const AText: AnsiString; var AMatch: TBotMatch; const AContext: Cardinal): Boolean;
    function MatchVariable(const AMatch: TBotMatch; const AVariable, ASize: Integer): AnsiString;
    function ReplaceSynonyms(const AText: AnsiString; const AContext: Cardinal): AnsiString;
    function ReplaceWeightedSynonyms(const AText: AnsiString; const AContext: Cardinal): AnsiString;
    function ReplaceReplySynonyms(const AText: AnsiString; const AContext: Cardinal): AnsiString;
    procedure ConstructChatMessage(const AChatState: Integer; const AMessage: AnsiString; const AMessageContext,
      AVariableContext: Cardinal; const AMatch: TBotMatch; const AReply: Boolean);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.Chat.ChatType, DelphiDoom.BotAi.Chat.ReplyChat, DelphiDoom.BotAi.Chat.Text;

{ TBotChatSystem }

constructor TBotChatSystem.Create(const AImport: IBotImport; const AFiles: IBotFileSource; const ALibVars: IBotLibVars;
  const ARandom: IBotRandom);
begin
  inherited Create;
  FImport := AImport;
  FFiles := AFiles;
  FLibVars := ALibVars;
  FRandom := ARandom;
  FTables := TBotChatTables.Create;
  FHeap := TBotConsoleMessageHeap.Create;
  FChats := TObjectList<TBotChat>.Create(True);
  FRandomStrings := TBotRandomStrings.Create(FTables, FRandom);
  FReplacer := TBotSynonymReplacer.Create(FTables, FRandom);
  FMatcher := TBotChatMatcher.Create(FTables, FImport);
  FBuilder := TBotChatMessageBuilder.Create(FImport, FRandomStrings, FReplacer);
  FChecker := TBotChatIntegrityChecker.Create(FImport, FRandomStrings);
  FSynonymLoader := TBotSynonymLoader.Create(FImport, FFiles);
  FRandomListLoader := TBotRandomListLoader.Create(FImport, FFiles);
  FMatchTemplateLoader := TBotMatchTemplateLoader.Create(FImport, FFiles);
  FReplyChatLoader := TBotReplyChatLoader.Create(FImport, FFiles, FChecker);
  FInitialChatLoader := TBotInitialChatLoader.Create(FImport, FFiles, FChecker);
end;

destructor TBotChatSystem.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to BOT_MAX_CLIENTS do
    FreeAndNil(FStates[LIndex]);
  FInitialChatLoader.Free;
  FReplyChatLoader.Free;
  FMatchTemplateLoader.Free;
  FRandomListLoader.Free;
  FSynonymLoader.Free;
  FChecker.Free;
  FBuilder.Free;
  FMatcher.Free;
  FReplacer.Free;
  FRandomStrings.Free;
  FChats.Free;
  FHeap.Free;
  FTables.Free;
  inherited Destroy;
end;

function TBotChatSystem.StateFromHandle(const AHandle: Integer): TBotChatState;
begin
  Result := nil;
  if (AHandle <= 0) or (AHandle > BOT_MAX_CLIENTS) then
  begin
    FImport.Print(PRT_FATAL, 'chat state handle ' + AnsiString(IntToStr(AHandle)) + ' out of range'#10);
    Exit;
  end;
  if FStates[AHandle] = nil then
  begin
    FImport.Print(PRT_FATAL, 'invalid chat state ' + AnsiString(IntToStr(AHandle)) + #10);
    Exit;
  end;
  Result := FStates[AHandle];
end;

function TBotChatSystem.IsFuture(const AMessage: TBotChatMessage): Boolean;
begin
  // m->time > AAS_Time()
  Result := AMessage.Time > FImport.Time;
end;

function TBotChatSystem.Setup: Integer;
begin
  FDeveloper := Trunc(FLibVars.GetValue('bot_developer')) <> 0;
  FSynonymLoader.Load(FLibVars.GetStringOrCreate('synfile', 'syn.c'), FTables.Synonyms);
  FRandomListLoader.Load(FLibVars.GetStringOrCreate('rndfile', 'rnd.c'), FTables.RandomLists);
  FMatchTemplateLoader.Load(FLibVars.GetStringOrCreate('matchfile', 'match.c'), FTables.Templates);
  if FLibVars.GetValueOrCreate('nochat', '0') = 0 then
    FReplyChatLoader.Load(FLibVars.GetStringOrCreate('rchatfile', 'rchat.c'), FTables.ReplyChats, FDeveloper);
  FHeap.Init(Trunc(FLibVars.GetValueOrCreate('max_messages', '1024')));
  Result := BLERR_NOERROR;
end;

procedure TBotChatSystem.Shutdown;
var
  LIndex: Integer;
begin
  // the original frees the states from 0 to MAX_CLIENTS - 1; the last one is freed here without messages
  for LIndex := 0 to BOT_MAX_CLIENTS - 1 do
  begin
    if FStates[LIndex] <> nil then
      FreeChatState(LIndex);
  end;
  FreeAndNil(FStates[BOT_MAX_CLIENTS]);
  for LIndex := 0 to BOT_MAX_CLIENTS - 1 do
    FCache[LIndex] := Default(TCachedChat);
  FChats.Clear;
  FHeap.Init(0);
  FTables.Templates.Clear;
  FTables.RandomLists.Clear;
  FTables.Synonyms.Clear;
  FTables.ReplyChats.Clear;
end;

function TBotChatSystem.AllocChatState: Integer;
var
  LIndex: Integer;
begin
  for LIndex := 1 to BOT_MAX_CLIENTS do
  begin
    if FStates[LIndex] = nil then
    begin
      FStates[LIndex] := TBotChatState.Create;
      Exit(LIndex);
    end;
  end;
  Result := 0;
end;

function TBotChatSystem.IsCached(const AChat: TBotChat): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to BOT_MAX_CLIENTS - 1 do
  begin
    if FCache[LIndex].Chat = AChat then
      Exit(True);
  end;
  Result := False;
end;

procedure TBotChatSystem.FreeChatFile(const AState: TBotChatState);
begin
  // a cached chat stays (other states use it); the original frees it and leaves the cache pointing at it
  if (AState.Chat <> nil) and not IsCached(AState.Chat) then
    FChats.Remove(AState.Chat);
  AState.Chat := nil;
end;

procedure TBotChatSystem.ReleaseState(const AState: TBotChatState);
begin
  while AState.ConsoleMessages.Count > 0 do
  begin
    AState.ConsoleMessages.Delete(0);
    FHeap.Release;
  end;
end;

procedure TBotChatSystem.FreeChatState(const AHandle: Integer);
var
  LState: TBotChatState;
begin
  if (AHandle <= 0) or (AHandle > BOT_MAX_CLIENTS) then
  begin
    FImport.Print(PRT_FATAL, 'chat state handle ' + AnsiString(IntToStr(AHandle)) + ' out of range'#10);
    Exit;
  end;
  if FStates[AHandle] = nil then
  begin
    FImport.Print(PRT_FATAL, 'invalid chat state ' + AnsiString(IntToStr(AHandle)) + #10);
    Exit;
  end;
  LState := FStates[AHandle];
  if FLibVars.GetValue('bot_reloadcharacters') <> 0 then
    FreeChatFile(LState);
  // free all the console messages left in the chat state
  ReleaseState(LState);
  FStates[AHandle] := nil;
  LState.Free;
end;

procedure TBotChatSystem.QueueConsoleMessage(const AChatState, AMessageType: Integer; const AMessage: AnsiString);
var
  LState: TBotChatState;
  LMessage: TBotConsoleMessage;
begin
  LState := StateFromHandle(AChatState);
  if LState = nil then
    Exit;
  if not FHeap.TryAllocate then
  begin
    FImport.Print(PRT_ERROR, 'empty console message heap'#10);
    Exit;
  end;
  LState.Handle := LState.Handle + 1;
  if (LState.Handle <= 0) or (LState.Handle > 8192) then
    LState.Handle := 1;
  LMessage.Handle := LState.Handle;
  LMessage.Time := FImport.Time;
  LMessage.MessageType := AMessageType;
  LMessage.Text := Copy(AMessage, 1, MAX_MESSAGE_SIZE - 1);
  LState.ConsoleMessages.Add(LMessage);
end;

procedure TBotChatSystem.RemoveConsoleMessage(const AChatState, AHandle: Integer);
var
  LState: TBotChatState;
  LIndex: Integer;
begin
  LState := StateFromHandle(AChatState);
  if LState = nil then
    Exit;
  for LIndex := 0 to LState.ConsoleMessages.Count - 1 do
  begin
    if LState.ConsoleMessages[LIndex].Handle = AHandle then
    begin
      LState.ConsoleMessages.Delete(LIndex);
      FHeap.Release;
      Break;
    end;
  end;
end;

function TBotChatSystem.NextConsoleMessage(const AChatState: Integer; out AMessage: TBotConsoleMessage): Integer;
var
  LState: TBotChatState;
begin
  AMessage := Default(TBotConsoleMessage);
  Result := 0;
  LState := StateFromHandle(AChatState);
  if LState = nil then
    Exit;
  if LState.ConsoleMessages.Count > 0 then
  begin
    AMessage := LState.ConsoleMessages[0];
    Result := AMessage.Handle;
  end;
end;

function TBotChatSystem.NumConsoleMessages(const AChatState: Integer): Integer;
var
  LState: TBotChatState;
begin
  LState := StateFromHandle(AChatState);
  if LState = nil then
    Exit(0);
  Result := LState.ConsoleMessages.Count;
end;

class function TBotChatSystem.BuildMatch(const ABase: AnsiString; const AVariables: TBotChatVariables): TBotMatch;
var
  LIndex: Integer;
  LText: AnsiString;
begin
  // the variables are appended to the text of the match; the original overflows the buffer with
  // more than MAX_MESSAGE_SIZE - 1 characters, here the text is cut there
  Result := Default(TBotMatch);
  Result.Text := Copy(ABase, 1, MAX_MESSAGE_SIZE - 1);
  for LIndex := 0 to MAX_MATCHVARIABLES - 1 do
  begin
    if not AVariables.Items[LIndex].IsSet then
      Continue;
    LText := AVariables.Items[LIndex].Text;
    Result.Variables[LIndex].Offset := ShortInt(Length(Result.Text));
    Result.Variables[LIndex].Length := Length(LText);
    Result.Text := Copy(Result.Text + LText, 1, MAX_MESSAGE_SIZE - 1);
  end;
end;

function TBotChatSystem.HasInitialMessage(const AState: TBotChatState; const AType: AnsiString;
  out AText: AnsiString): Boolean;
begin
  AText := ChooseInitialChatMessage(AState, AType);
  Result := AText <> '';
end;

function TBotChatSystem.ChooseInitialChatMessage(const AState: TBotChatState; const AType: AnsiString): AnsiString;
var
  LType: TBotChatType;
  LMessage: TBotChatMessage;
  LBest: TBotChatMessage;
  LBestTime: Single;
  LCount: Integer;
  LValue: Single;
  LNumber: Integer;
begin
  Result := '';
  LType := AState.Chat.FindType(AType);
  if LType = nil then
    Exit;
  LCount := 0;
  for LMessage in LType.Messages do
  begin
    if not IsFuture(LMessage) then
      Inc(LCount);
  end;
  if LCount <= 0 then
  begin
    // all chat messages have been used recently: the oldest one
    LBestTime := 0;
    LBest := nil;
    for LMessage in LType.Messages do
    begin
      if (LBestTime = 0) or (LMessage.Time < LBestTime) then
      begin
        LBest := LMessage;
        LBestTime := LMessage.Time;
      end;
    end;
    if LBest <> nil then
      Result := LBest.Text;
  end
  else
  begin
    // choose a chat message randomly
    LValue := FRandom.NextFloat * LCount;
    LNumber := Trunc(LValue);
    for LMessage in LType.Messages do
    begin
      if IsFuture(LMessage) then
        Continue;
      Dec(LNumber);
      if LNumber < 0 then
      begin
        LMessage.Time := FImport.Time + CHATMESSAGE_RECENTTIME;
        Result := LMessage.Text;
        Exit;
      end;
    end;
  end;
end;

procedure TBotChatSystem.InitialChat(const AChatState: Integer; const AType: AnsiString;
  const AMessageContext: Integer; const AVariables: TBotChatVariables);
var
  LState: TBotChatState;
  LText: AnsiString;
  LMatch: TBotMatch;
begin
  LState := StateFromHandle(AChatState);
  if LState = nil then
    Exit;
  // if no chat file is loaded
  if LState.Chat = nil then
    Exit;
  // choose a chat message randomly of the given type; if there is none of the type nothing happens
  if not HasInitialMessage(LState, AType, LText) then
    Exit;
  LMatch := BuildMatch('', AVariables);
  FBuilder.Construct(LState.BufferPointer^, LText, Cardinal(AMessageContext), LMatch, 0, False);
end;

function TBotChatSystem.NumInitialChats(const AChatState: Integer; const AType: AnsiString): Integer;
var
  LState: TBotChatState;
  LType: TBotChatType;
begin
  Result := 0;
  LState := StateFromHandle(AChatState);
  // the original dereferences the missing chat of a state without one
  if (LState = nil) or (LState.Chat = nil) then
    Exit;
  LType := LState.Chat.FindType(AType);
  if LType = nil then
    Exit;
  if FLibVars.GetValue('bot_testichat') <> 0 then
  begin
    FImport.Print(PRT_MESSAGE, AType + ' has ' + AnsiString(IntToStr(LType.Messages.Count)) + ' chat lines'#10);
    FImport.Print(PRT_MESSAGE, '-------------------'#10);
  end;
  Result := LType.Messages.Count;
end;

function TBotChatSystem.ReplyChat(const AChatState: Integer; const AMessage: AnsiString; const AMessageContext,
  AVariableContext: Integer; const AVariables: TBotChatVariables): Boolean;
var
  LState: TBotChatState;
  LMatch: TBotMatch;
  LBestMatch: TBotMatch;
  LReply: TBotReplyChat;
  LBestReply: TBotReplyChat;
  LBestMessage: TBotChatMessage;
  LMessage: TBotChatMessage;
  LKey: TBotReplyChatKey;
  LBestPriority: Integer;
  LFound: Boolean;
  LResult: Boolean;
  LCount: Integer;
  LNumber: Integer;
  LValue: Single;
  LIndex: Integer;
  LIndexVar: Integer;
  LText: AnsiString;
begin
  Result := False;
  LState := StateFromHandle(AChatState);
  if LState = nil then
    Exit;
  LMatch := Default(TBotMatch);
  LMatch.Text := Copy(AMessage, 1, MAX_MESSAGE_SIZE - 1);
  LBestPriority := -1;
  LBestMessage := nil;
  LBestReply := nil;
  LBestMatch := Default(TBotMatch);
  // go through all the reply chats
  for LReply in FTables.ReplyChats do
  begin
    LFound := False;
    for LKey in LReply.Keys do
    begin
      LResult := False;
      // get the match result
      if (LKey.Flags and RCKFL_NAME) <> 0 then
        LResult := TBotChatText.StringContains(AMessage, LState.Name, False) <> -1
      else if (LKey.Flags and RCKFL_BOTNAMES) <> 0 then
        LResult := TBotChatText.StringContains(LKey.Text, LState.Name, False) <> -1
      else if (LKey.Flags and RCKFL_GENDERFEMALE) <> 0 then
        LResult := LState.Gender = CHAT_GENDERFEMALE
      else if (LKey.Flags and RCKFL_GENDERMALE) <> 0 then
        LResult := LState.Gender = CHAT_GENDERMALE
      else if (LKey.Flags and RCKFL_GENDERLESS) <> 0 then
        LResult := LState.Gender = CHAT_GENDERLESS
      else if (LKey.Flags and RCKFL_VARIABLES) <> 0 then
        LResult := FMatcher.StringsMatch(LKey.Match, LMatch)
      else if (LKey.Flags and RCKFL_STRING) <> 0 then
        LResult := TBotChatText.StringContainsWord(AMessage, LKey.Text, False) >= 0;
      if (LKey.Flags and RCKFL_AND) <> 0 then
      begin
        // the key must be present
        if not LResult then
        begin
          LFound := False;
          Break;
        end;
      end
      else if (LKey.Flags and RCKFL_NOT) <> 0 then
      begin
        // the key must be absent
        if LResult then
        begin
          LFound := False;
          Break;
        end;
      end
      else if LResult then
        LFound := True;
    end;
    if LFound and (LReply.Priority > LBestPriority) then
    begin
      LCount := 0;
      for LMessage in LReply.Messages do
      begin
        if not IsFuture(LMessage) then
          Inc(LCount);
      end;
      LValue := FRandom.NextFloat * LCount;
      LNumber := Trunc(LValue);
      // the original counts the messages that are too recent too when it walks to the chosen one
      LMessage := nil;
      for LIndex := 0 to LReply.Messages.Count - 1 do
      begin
        Dec(LNumber);
        if LNumber < 0 then
        begin
          LMessage := LReply.Messages[LIndex];
          Break;
        end;
      end;
      // if the reply chat has a message
      if LMessage <> nil then
      begin
        LBestMatch := LMatch;
        LBestMessage := LMessage;
        LBestReply := LReply;
        LBestPriority := Trunc(LReply.Priority);
      end;
    end;
  end;
  if LBestMessage = nil then
    Exit;
  // the variables the game gives follow the text of the match
  for LIndexVar := 0 to MAX_MATCHVARIABLES - 1 do
  begin
    if not AVariables.Items[LIndexVar].IsSet then
      Continue;
    LText := AVariables.Items[LIndexVar].Text;
    LBestMatch.Variables[LIndexVar].Offset := ShortInt(Length(LBestMatch.Text));
    LBestMatch.Variables[LIndexVar].Length := Length(LText);
    LBestMatch.Text := Copy(LBestMatch.Text + LText, 1, MAX_MESSAGE_SIZE - 1);
  end;
  if FLibVars.GetValue('bot_testrchat') <> 0 then
  begin
    for LMessage in LBestReply.Messages do
    begin
      FBuilder.Construct(LState.BufferPointer^, LMessage.Text, Cardinal(AMessageContext), LBestMatch,
        Cardinal(AVariableContext), True);
      LState.SetChatMessage(TBotChatText.RemoveTildes(LState.ChatMessage));
      FImport.Print(PRT_MESSAGE, LState.ChatMessage + #10);
    end;
  end
  else
  begin
    LBestMessage.Time := FImport.Time + CHATMESSAGE_RECENTTIME;
    FBuilder.Construct(LState.BufferPointer^, LBestMessage.Text, Cardinal(AMessageContext), LBestMatch,
      Cardinal(AVariableContext), True);
  end;
  Result := True;
end;

function TBotChatSystem.ChatLength(const AChatState: Integer): Integer;
var
  LState: TBotChatState;
begin
  LState := StateFromHandle(AChatState);
  if LState = nil then
    Exit(0);
  Result := Length(LState.ChatMessage);
end;

procedure TBotChatSystem.EnterChat(const AChatState, AClientTo, ASendTo: Integer);
var
  LState: TBotChatState;
  LMessage: AnsiString;
begin
  LState := StateFromHandle(AChatState);
  if LState = nil then
    Exit;
  LMessage := LState.ChatMessage;
  if LMessage = '' then
    Exit;
  LMessage := TBotChatText.RemoveTildes(LMessage);
  LState.SetChatMessage(LMessage);
  if FLibVars.GetValue('bot_testichat') <> 0 then
    FImport.Print(PRT_MESSAGE, LMessage + #10)
  else
  begin
    case ASendTo of
      CHAT_TEAM:
        FImport.Command(LState.Client, 'say_team ' + LMessage);
      CHAT_TELL:
        FImport.Command(LState.Client, 'tell ' + AnsiString(IntToStr(AClientTo)) + ' ' + LMessage);
    else
      FImport.Command(LState.Client, 'say ' + LMessage);
    end;
  end;
  // clear the chat message from the state
  LState.ClearChatMessage;
end;

function TBotChatSystem.GetChatMessage(const AChatState, ASize: Integer): AnsiString;
var
  LState: TBotChatState;
begin
  Result := '';
  LState := StateFromHandle(AChatState);
  if LState = nil then
    Exit;
  LState.SetChatMessage(TBotChatText.RemoveTildes(LState.ChatMessage));
  if ASize > 1 then
    Result := Copy(LState.ChatMessage, 1, ASize - 1);
  LState.ClearChatMessage;
end;

procedure TBotChatSystem.SetChatGender(const AChatState, AGender: Integer);
var
  LState: TBotChatState;
begin
  LState := StateFromHandle(AChatState);
  if LState = nil then
    Exit;
  case AGender of
    CHAT_GENDERFEMALE: LState.Gender := CHAT_GENDERFEMALE;
    CHAT_GENDERMALE: LState.Gender := CHAT_GENDERMALE;
  else
    LState.Gender := CHAT_GENDERLESS;
  end;
end;

procedure TBotChatSystem.SetChatName(const AChatState: Integer; const AName: AnsiString; const AClient: Integer);
var
  LState: TBotChatState;
begin
  LState := StateFromHandle(AChatState);
  if LState = nil then
    Exit;
  LState.Client := AClient;
  LState.Name := Copy(AName, 1, 31);
end;

function TBotChatSystem.LoadChatFile(const AChatState: Integer; const AChatFile, AChatName: AnsiString): Integer;
var
  LState: TBotChatState;
  LReload: Boolean;
  LAvailable: Integer;
  LIndex: Integer;
  LChat: TBotChat;
begin
  LState := StateFromHandle(AChatState);
  if LState = nil then
    Exit(BLERR_CANNOTLOADICHAT);
  FreeChatFile(LState);
  LReload := FLibVars.GetValue('bot_reloadcharacters') <> 0;
  LAvailable := 0;
  if not LReload then
  begin
    LAvailable := -1;
    for LIndex := 0 to BOT_MAX_CLIENTS - 1 do
    begin
      if FCache[LIndex].Chat = nil then
      begin
        if LAvailable = -1 then
          LAvailable := LIndex;
        Continue;
      end;
      if (FCache[LIndex].FileName <> AChatFile) or (FCache[LIndex].ChatName <> AChatName) then
        Continue;
      LState.Chat := FCache[LIndex].Chat;
      Exit(BLERR_NOERROR);
    end;
    if LAvailable = -1 then
    begin
      FImport.Print(PRT_FATAL, 'ichatdata table full; couldn''t load chat ' + AChatName + ' from ' + AChatFile + #10);
      Exit(BLERR_CANNOTLOADICHAT);
    end;
  end;
  LChat := FInitialChatLoader.Load(AChatFile, AChatName, FDeveloper);
  if LChat = nil then
  begin
    FImport.Print(PRT_FATAL, 'couldn''t load chat ' + AChatName + ' from ' + AChatFile + #10);
    Exit(BLERR_CANNOTLOADICHAT);
  end;
  FChats.Add(LChat);
  LState.Chat := LChat;
  if not LReload then
  begin
    FCache[LAvailable].Chat := LChat;
    FCache[LAvailable].FileName := AChatFile;
    FCache[LAvailable].ChatName := AChatName;
  end;
  Result := BLERR_NOERROR;
end;

procedure TBotChatSystem.ResetChatAI;
var
  LReply: TBotReplyChat;
  LMessage: TBotChatMessage;
begin
  for LReply in FTables.ReplyChats do
    for LMessage in LReply.Messages do
      LMessage.Time := 0;
end;

function TBotChatSystem.FindMatch(const AText: AnsiString; var AMatch: TBotMatch; const AContext: Cardinal): Boolean;
begin
  Result := FMatcher.FindMatch(AText, AContext, AMatch);
end;

function TBotChatSystem.MatchVariable(const AMatch: TBotMatch; const AVariable, ASize: Integer): AnsiString;
begin
  Result := FMatcher.MatchVariable(AMatch, AVariable, ASize);
end;

function TBotChatSystem.ReplaceSynonyms(const AText: AnsiString; const AContext: Cardinal): AnsiString;
begin
  Result := FReplacer.ReplaceSynonyms(AText, AContext);
end;

function TBotChatSystem.ReplaceWeightedSynonyms(const AText: AnsiString; const AContext: Cardinal): AnsiString;
begin
  Result := FReplacer.ReplaceWeightedSynonyms(AText, AContext);
end;

function TBotChatSystem.ReplaceReplySynonyms(const AText: AnsiString; const AContext: Cardinal): AnsiString;
begin
  Result := FReplacer.ReplaceReplySynonyms(AText, AContext);
end;

procedure TBotChatSystem.ConstructChatMessage(const AChatState: Integer; const AMessage: AnsiString;
  const AMessageContext, AVariableContext: Cardinal; const AMatch: TBotMatch; const AReply: Boolean);
var
  LState: TBotChatState;
begin
  LState := StateFromHandle(AChatState);
  if LState = nil then
    Exit;
  FBuilder.Construct(LState.BufferPointer^, AMessage, AMessageContext, AMatch, AVariableContext, AReply);
end;

end.
