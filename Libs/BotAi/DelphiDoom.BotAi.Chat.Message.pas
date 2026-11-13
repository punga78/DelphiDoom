{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotChatMessage, a chat message of a type or a reply   }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): bot_chatmessage_t,  }
{  code\botlib\be_ai_chat.c. Based on the Quake III Arena GPL Source Code      }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.Message;

interface

type
  /// <summary>A compiled chat message (with the escape characters) and the last time it was used</summary>
  TBotChatMessage = class
  strict private
    FText: AnsiString;
    FTime: Single;
  public
    constructor Create(const AText: AnsiString; const ATime: Single);
    /// <summary>chatmessage</summary>
    property Text: AnsiString read FText;
    /// <summary>The last time the message was used; a message is not chosen again while it is in the future</summary>
    property Time: Single read FTime write FTime;
  end;

implementation

{ TBotChatMessage }

constructor TBotChatMessage.Create(const AText: AnsiString; const ATime: Single);
begin
  inherited Create;
  FText := AText;
  FTime := ATime;
end;

end.
