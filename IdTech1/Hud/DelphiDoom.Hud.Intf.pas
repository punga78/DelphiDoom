{******************************************************************************}
{                                                                              }
{  DelphiDoom: heads-up display library - the contracts                        }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Hud.Intf;

interface

uses
  DelphiDoom.Hud.Types;

type
  /// <summary>
  ///   The two switches that the rest of the engine (the menu) reads and writes: they stay in the
  ///   engine because other units own them
  /// </summary>
  IHudFlags = interface
    ['{4D0B7C32-91A5-4E68-8F27-3B5A6C1E9D04}']
    function GetChatOn: Boolean;
    procedure SetChatOn(const AValue: Boolean);
    function GetMessageForced: Boolean;
    procedure SetMessageForced(const AValue: Boolean);
    /// <summary>The chat line is open (chat_on)</summary>
    property ChatOn: Boolean read GetChatOn write SetChatOn;
    /// <summary>The next message must be shown even with the messages off (message_dontfuckwithme)</summary>
    property MessageForced: Boolean read GetMessageForced write SetMessageForced;
  end;

  /// <summary>What the heads-up display asks about the players and the network game</summary>
  IHudPlayers = interface
    ['{0F6E2A18-5C3D-47B9-A1E4-92D07B8C5F13}']
    /// <summary>The game is played on the network (netgame)</summary>
    function IsNetGame: Boolean;
    /// <summary>Number of the player of this computer (consoleplayer)</summary>
    function ConsolePlayerIndex: Integer;
    /// <summary>The player takes part in the game (playeringame)</summary>
    function IsInGame(const AIndex: Integer): Boolean;
    /// <summary>The character the player typed in the last tic (cmd.chatchar), zero if none</summary>
    function ChatChar(const AIndex: Integer): Byte;
    /// <summary>Forgets the character of the player</summary>
    procedure ClearChatChar(const AIndex: Integer);
  end;

  /// <summary>The message of the player of this computer (_message of its player_t)</summary>
  IHudPlayerMessage = interface
    ['{7B31C5E0-2A94-4D86-B3F1-6E0A8D47C259}']
    /// <summary>Starts to follow the player of this computer (HU_Start)</summary>
    procedure AttachConsolePlayer;
    /// <summary>The message waiting to be shown, empty if none or if there is no player</summary>
    function ReadMessage: string;
    /// <summary>Sets the message of the player, empty to forget it</summary>
    procedure WriteMessage(const AValue: string);
  end;

  /// <summary>The settings and the texts of the game that can change while it runs</summary>
  IHudSettings = interface
    ['{C8A4D917-3E52-4B60-9F8A-1D7E5B2C0A36}']
    /// <summary>The language is French: the keyboard map changes (language = french)</summary>
    function IsFrench: Boolean;
    /// <summary>The messages are shown (showMessages is not zero)</summary>
    function AreMessagesShown: Boolean;
    /// <summary>
    ///   The code of the key that starts a message to the player, -1 if there is none (the first
    ///   character of destination_keys or key_multi_msgplayer)
    /// </summary>
    function DestinationKeyCode(const AIndex: Integer): Integer;
    /// <summary>The text sent by the macro (chat_macros)</summary>
    function ChatMacro(const AIndex: Integer): string;
    /// <summary>The name written before the text of the player (player_names)</summary>
    function PlayerName(const AIndex: Integer): string;
    /// <summary>The message that says the chat queue is full (HUSTR_MSGU)</summary>
    function QueueFullMessage: string;
    /// <summary>The message of someone who talks to himself, ALevel from 1 to 5 (HUSTR_TALKTOSELF1..5)</summary>
    function TalkToSelfMessage(const ALevel: Integer): string;
  end;

  /// <summary>The sound that tells a chat message arrived</summary>
  IHudChatSound = interface
    ['{2E59B0F4-6D18-4A73-8C05-F4A3917D6B8E}']
    procedure PlayChatSound;
  end;

  /// <summary>Where the messages are copied (the console)</summary>
  IHudEcho = interface
    ['{91C3D7A5-04BE-4F29-A650-3E8B2D1F7C94}']
    procedure Echo(const AText: string);
  end;

  /// <summary>What the chat tells the message bar</summary>
  IHudMessageTarget = interface
    ['{5A07E4B9-C1D2-4836-B9F5-0D6E3A8C7142}']
    /// <summary>Shows the last message again for the whole timeout</summary>
    procedure Refresh;
    /// <summary>Puts a line of chat in the window and protects it from other messages</summary>
    procedure PostChat(const APrefix, AText: string);
  end;

  /// <summary>The routines of the heads-up display that the game calls (the old HU_* routines)</summary>
  IHeadsUp = interface
    ['{E1B6A038-7F4C-4D95-82A1-C5D90E3B6F27}']
    /// <summary>The first thing (HU_Init): picks the keyboard map of the language and clears the history</summary>
    procedure Initialize;
    /// <summary>A level starts (HU_Start)</summary>
    procedure Start(const AParams: THudStartParams);
    /// <summary>A tic (HU_Ticker)</summary>
    procedure Ticker;
    /// <summary>
    ///   A key (HU_Responder): the code and whether it is a key going down. Returns true if the
    ///   chat ate it
    /// </summary>
    function Responder(const AKey: Integer; const AIsKeyDown: Boolean): Boolean;
    /// <summary>The next character to send to the other players, #0 if none (HU_dequeueChatChar)</summary>
    function DequeueChatChar: Char;
    /// <summary>A frame is drawn, at the given time (HU_DoFPSStuff)</summary>
    procedure RecordFrameTime(const ATime: Integer);
    /// <summary>Frames per second now (HU_FPS)</summary>
    function FramesPerSecond: Integer;
    /// <summary>The keyboard map for the shift key, to copy into the global one of the engine</summary>
    function GetShiftTable: THudShiftTable;
  end;

implementation

end.
