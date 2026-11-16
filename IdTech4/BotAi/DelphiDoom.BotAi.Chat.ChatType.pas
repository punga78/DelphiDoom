{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotChatType, the messages of one type of chat         }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): bot_chattype_t,     }
{  code\botlib\be_ai_chat.c. Based on the Quake III Arena GPL Source Code      }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.ChatType;

interface

uses
  System.Generics.Collections, DelphiDoom.BotAi.Chat.Message;

type
  /// <summary>A type of chat ("game_enter", "death_insult"...) with its messages</summary>
  TBotChatType = class
  strict private
    FName: AnsiString;
    FMessages: TObjectList<TBotChatMessage>;
  public
    constructor Create(const AName: AnsiString);
    destructor Destroy; override;
    property Name: AnsiString read FName;
    /// <summary>The messages in list order: the last one read from the file is the first (the original prepends)</summary>
    property Messages: TObjectList<TBotChatMessage> read FMessages;
  end;

implementation

{ TBotChatType }

constructor TBotChatType.Create(const AName: AnsiString);
begin
  inherited Create;
  FName := AName;
  FMessages := TObjectList<TBotChatMessage>.Create(True);
end;

destructor TBotChatType.Destroy;
begin
  FMessages.Free;
  inherited Destroy;
end;

end.
