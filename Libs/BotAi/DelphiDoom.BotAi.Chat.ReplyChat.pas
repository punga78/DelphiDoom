{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotReplyChat, the keys and the replies of a "rchat"   }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): bot_replychat_t,    }
{  code\botlib\be_ai_chat.c. Based on the Quake III Arena GPL Source Code      }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.ReplyChat;

interface

uses
  System.Generics.Collections, DelphiDoom.BotAi.Chat.Types, DelphiDoom.BotAi.Chat.Message;

type
  /// <summary>A reply chat: the keys that select it, the priority and the messages to answer with</summary>
  TBotReplyChat = class
  strict private
    FKeys: TList<TBotReplyChatKey>;
    FMessages: TObjectList<TBotChatMessage>;
    FPriority: Single;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The keys in list order: the last one read is the first (the original prepends)</summary>
    property Keys: TList<TBotReplyChatKey> read FKeys;
    property Messages: TObjectList<TBotChatMessage> read FMessages;
    property Priority: Single read FPriority write FPriority;
  end;

implementation

{ TBotReplyChat }

constructor TBotReplyChat.Create;
begin
  inherited Create;
  FKeys := TList<TBotReplyChatKey>.Create;
  FMessages := TObjectList<TBotChatMessage>.Create(True);
end;

destructor TBotReplyChat.Destroy;
begin
  FMessages.Free;
  FKeys.Free;
  inherited Destroy;
end;

end.
