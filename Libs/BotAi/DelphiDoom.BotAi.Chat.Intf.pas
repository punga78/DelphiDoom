{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - IBotChatSystem, the interface of the bot chat          }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): the functions of    }
{  code\game\be_ai_chat.h. Based on the Quake III Arena GPL Source Code        }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.Intf;

interface

uses
  DelphiDoom.BotAi.Chat.Types;

type
  /// <summary>
  ///   The chat AI of the bots with the handles of the original (chat states from 1 to MAX_CLIENTS).
  ///   The contexts are bit masks; the functions that take a handle that is out of range or not
  ///   allocated report it to botimport.Print and do nothing.
  /// </summary>
  IBotChatSystem = interface
    ['{4F0C1A52-7B63-4C57-9E2D-3A6B8D1E0F75}']
    /// <summary>BotSetupChatAI: loads synfile, rndfile, matchfile and rchatfile (library variables)</summary>
    function Setup: Integer;
    /// <summary>BotShutdownChatAI</summary>
    procedure Shutdown;
    /// <summary>BotAllocChatState: the handle, 0 if there is no free state</summary>
    function AllocChatState: Integer;
    procedure FreeChatState(const AHandle: Integer);
    procedure QueueConsoleMessage(const AChatState, AMessageType: Integer; const AMessage: AnsiString);
    procedure RemoveConsoleMessage(const AChatState, AHandle: Integer);
    /// <summary>BotNextConsoleMessage: the handle of the first message (0 if none) and the message</summary>
    function NextConsoleMessage(const AChatState: Integer; out AMessage: TBotConsoleMessage): Integer;
    function NumConsoleMessages(const AChatState: Integer): Integer;
    /// <summary>BotInitialChat: chooses a message of the type and builds it with the variables</summary>
    procedure InitialChat(const AChatState: Integer; const AType: AnsiString; const AMessageContext: Integer;
      const AVariables: TBotChatVariables);
    function NumInitialChats(const AChatState: Integer; const AType: AnsiString): Integer;
    /// <summary>BotReplyChat: finds and builds a reply to the message; false if there is none</summary>
    function ReplyChat(const AChatState: Integer; const AMessage: AnsiString; const AMessageContext,
      AVariableContext: Integer; const AVariables: TBotChatVariables): Boolean;
    function ChatLength(const AChatState: Integer): Integer;
    /// <summary>BotEnterChat: sends the message with say, say_team or tell (CHAT_ALL, CHAT_TEAM, CHAT_TELL)</summary>
    procedure EnterChat(const AChatState, AClientTo, ASendTo: Integer);
    /// <summary>BotGetChatMessage: at most size - 1 characters; the message of the state is cleared</summary>
    function GetChatMessage(const AChatState, ASize: Integer): AnsiString;
    procedure SetChatGender(const AChatState, AGender: Integer);
    procedure SetChatName(const AChatState: Integer; const AName: AnsiString; const AClient: Integer);
    /// <summary>BotLoadChatFile: BLERR_NOERROR or BLERR_CANNOTLOADICHAT</summary>
    function LoadChatFile(const AChatState: Integer; const AChatFile, AChatName: AnsiString): Integer;
    /// <summary>BotResetChatAI: the reply messages can be used again</summary>
    procedure ResetChatAI;
    /// <summary>BotFindMatch</summary>
    function FindMatch(const AText: AnsiString; var AMatch: TBotMatch; const AContext: Cardinal): Boolean;
    /// <summary>BotMatchVariable</summary>
    function MatchVariable(const AMatch: TBotMatch; const AVariable, ASize: Integer): AnsiString;
    /// <summary>BotReplaceSynonyms</summary>
    function ReplaceSynonyms(const AText: AnsiString; const AContext: Cardinal): AnsiString;
    /// <summary>BotReplaceWeightedSynonyms</summary>
    function ReplaceWeightedSynonyms(const AText: AnsiString; const AContext: Cardinal): AnsiString;
    /// <summary>BotReplaceReplySynonyms</summary>
    function ReplaceReplySynonyms(const AText: AnsiString; const AContext: Cardinal): AnsiString;
    /// <summary>
    ///   BotConstructChatMessage (internal in the original): builds a compiled message with the match
    ///   into the message of the chat state
    /// </summary>
    procedure ConstructChatMessage(const AChatState: Integer; const AMessage: AnsiString; const AMessageContext,
      AVariableContext: Cardinal; const AMatch: TBotMatch; const AReply: Boolean);
  end;

implementation

end.
