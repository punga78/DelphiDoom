{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotChat, the chats of one bot character               }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): bot_chat_t,         }
{  code\botlib\be_ai_chat.c. Based on the Quake III Arena GPL Source Code      }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.Chat;

interface

uses
  System.Generics.Collections, DelphiDoom.BotAi.Chat.ChatType;

type
  /// <summary>The chat of a bot ("chat "name" { type ... }" of a chat file): its types of chat</summary>
  TBotChat = class
  strict private
    FTypes: TObjectList<TBotChatType>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The type with the name, compared without case (Q_stricmp); nil if missing</summary>
    function FindType(const AName: AnsiString): TBotChatType;
    /// <summary>The types in list order: the last one read from the file is the first (the original prepends)</summary>
    property Types: TObjectList<TBotChatType> read FTypes;
  end;

implementation

uses
  DelphiDoom.BotAi.Chat.Text;

{ TBotChat }

constructor TBotChat.Create;
begin
  inherited Create;
  FTypes := TObjectList<TBotChatType>.Create(True);
end;

destructor TBotChat.Destroy;
begin
  FTypes.Free;
  inherited Destroy;
end;

function TBotChat.FindType(const AName: AnsiString): TBotChatType;
var
  LType: TBotChatType;
begin
  for LType in FTypes do
  begin
    if TBotChatText.SameTextAscii(LType.Name, AName) then
      Exit(LType);
  end;
  Result := nil;
end;

end.
