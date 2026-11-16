{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotChatState, the chat state of one bot               }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): bot_chatstate_t of  }
{  code\botlib\be_ai_chat.c. Based on the Quake III Arena GPL Source Code      }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.State;

interface

uses
  System.Generics.Collections, DelphiDoom.BotAi.Chat.Types, DelphiDoom.BotAi.Chat.Chat;

type
  /// <summary>The gender, the name, the chat, the selected message and the console messages of a bot</summary>
  TBotChatState = class
  strict private
    FGender: Integer;
    FClient: Integer;
    FName: AnsiString;
    FHandle: Integer;
    FChat: TBotChat;
    FMessageBuffer: TBotMessageBuffer;
    FConsoleMessages: TList<TBotConsoleMessage>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The selected message (strlen of chatmessage)</summary>
    function ChatMessage: AnsiString;
    /// <summary>strcpy(cs->chatmessage, ""): only the first character is cleared, like the original</summary>
    procedure ClearChatMessage;
    /// <summary>Writes the text and its zero over the buffer; the bytes behind stay (the original works in place)</summary>
    procedure SetChatMessage(const AText: AnsiString);
    /// <summary>The buffer the message builder writes to</summary>
    function BufferPointer: PBotMessageBuffer;
    /// <summary>0 = it, 1 = female, 2 = male</summary>
    property Gender: Integer read FGender write FGender;
    property Client: Integer read FClient write FClient;
    property Name: AnsiString read FName write FName;
    /// <summary>The last handle given to a console message</summary>
    property Handle: Integer read FHandle write FHandle;
    /// <summary>The chat of the bot, not owned: the chat system owns the loaded chats</summary>
    property Chat: TBotChat read FChat write FChat;
    property ConsoleMessages: TList<TBotConsoleMessage> read FConsoleMessages;
  end;

implementation

uses
  DelphiDoom.BotAi.Chat.MessageBuilder;

{ TBotChatState }

constructor TBotChatState.Create;
begin
  inherited Create;
  FConsoleMessages := TList<TBotConsoleMessage>.Create;
end;

destructor TBotChatState.Destroy;
begin
  FConsoleMessages.Free;
  inherited Destroy;
end;

procedure TBotChatState.SetChatMessage(const AText: AnsiString);
var
  LLength: Integer;
begin
  LLength := Length(AText);
  if LLength > MAX_MESSAGE_SIZE - 1 then
    LLength := MAX_MESSAGE_SIZE - 1;
  if LLength > 0 then
    Move(AText[1], FMessageBuffer[0], LLength);
  FMessageBuffer[LLength] := #0;
end;

function TBotChatState.BufferPointer: PBotMessageBuffer;
begin
  Result := @FMessageBuffer;
end;

function TBotChatState.ChatMessage: AnsiString;
begin
  Result := TBotChatMessageBuilder.BufferText(FMessageBuffer);
end;

procedure TBotChatState.ClearChatMessage;
begin
  FMessageBuffer[0] := #0;
end;

end.
