{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the heads-up display reads and writes the game         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Hud.Environment;

{$I Doom32.inc}

interface

uses
  d_player,
  DelphiDoom.Hud.Intf;

type
  /// <summary>
  ///   What Libs\Hud asks of the game, answered from the globals of the engine (the players, the
  ///   network game, the settings, the strings that the Dehacked patches change, the sounds): one
  ///   object, six small contracts. The drawing of the heads-up display asks it for the player
  /// </summary>
  TEngineHudEnvironment = class(TInterfacedObject, IHudFlags, IHudPlayers, IHudPlayerMessage,
    IHudSettings, IHudChatSound, IHudEcho)
  strict private
    FPlayer: Pplayer_t;
  public
    { IHudFlags }
    function GetChatOn: Boolean;
    procedure SetChatOn(const AValue: Boolean);
    function GetMessageForced: Boolean;
    procedure SetMessageForced(const AValue: Boolean);
    { IHudPlayers }
    function IsNetGame: Boolean;
    function ConsolePlayerIndex: Integer;
    function IsInGame(const AIndex: Integer): Boolean;
    function ChatChar(const AIndex: Integer): Byte;
    procedure ClearChatChar(const AIndex: Integer);
    { IHudPlayerMessage }
    procedure AttachConsolePlayer;
    function ReadMessage: string;
    procedure WriteMessage(const AValue: string);
    { IHudSettings }
    function IsFrench: Boolean;
    function AreMessagesShown: Boolean;
    function DestinationKeyCode(const AIndex: Integer): Integer;
    function ChatMacro(const AIndex: Integer): string;
    function PlayerName(const AIndex: Integer): string;
    function QueueFullMessage: string;
    function TalkToSelfMessage(const ALevel: Integer): string;
    { IHudChatSound }
    procedure PlayChatSound;
    { IHudEcho }
    procedure Echo(const AText: string);
    /// <summary>The player of this computer, nil until the first level starts (plr)</summary>
    property Player: Pplayer_t read FPlayer;
  end;

implementation

uses
  d_delphi,
  doomdef,
  doomstat,
  g_game,
  hu_stuff,
  m_menu,
{$IF DEFINED(HERETIC)}
  h_strings
{$ELSEIF DEFINED(HEXEN)}
  xn_strings
{$ELSE}
  d_englsh
{$ENDIF}
{$IF DEFINED(DOOM) OR DEFINED(STRIFE)}
  ,
  s_sound,
  sounddata
{$ENDIF}
  ;

{ TEngineHudEnvironment }

function TEngineHudEnvironment.GetChatOn: Boolean;
begin
  Result := chat_on;
end;

procedure TEngineHudEnvironment.SetChatOn(const AValue: Boolean);
begin
  chat_on := AValue;
end;

function TEngineHudEnvironment.GetMessageForced: Boolean;
begin
  Result := message_dontfuckwithme;
end;

procedure TEngineHudEnvironment.SetMessageForced(const AValue: Boolean);
begin
  message_dontfuckwithme := AValue;
end;

function TEngineHudEnvironment.IsNetGame: Boolean;
begin
  Result := netgame;
end;

function TEngineHudEnvironment.ConsolePlayerIndex: Integer;
begin
  Result := consoleplayer;
end;

function TEngineHudEnvironment.IsInGame(const AIndex: Integer): Boolean;
begin
  Result := playeringame[AIndex];
end;

function TEngineHudEnvironment.ChatChar(const AIndex: Integer): Byte;
begin
  Result := players[AIndex].cmd.chatchar;
end;

procedure TEngineHudEnvironment.ClearChatChar(const AIndex: Integer);
begin
  players[AIndex].cmd.chatchar := 0;
end;

procedure TEngineHudEnvironment.AttachConsolePlayer;
begin
  FPlayer := @players[consoleplayer];
end;

function TEngineHudEnvironment.ReadMessage: string;
begin
  if FPlayer = nil then
    Result := ''
  else
    Result := string(FPlayer._message);
end;

procedure TEngineHudEnvironment.WriteMessage(const AValue: string);
begin
  if FPlayer <> nil then
    FPlayer._message := ShortString(AValue);
end;

function TEngineHudEnvironment.IsFrench: Boolean;
begin
  Result := language = french;
end;

function TEngineHudEnvironment.AreMessagesShown: Boolean;
begin
  Result := showMessages <> 0;
end;

function TEngineHudEnvironment.DestinationKeyCode(const AIndex: Integer): Integer;
var
  LKeys: string;
begin
{$IFDEF STRIFE}
  LKeys := key_multi_msgplayer[AIndex];
{$ELSE}
  LKeys := destination_keys[AIndex];
{$ENDIF}
  if LKeys = '' then
    Result := -1
  else
    Result := Ord(LKeys[1]);
end;

function TEngineHudEnvironment.ChatMacro(const AIndex: Integer): string;
begin
  Result := chat_macros[AIndex];
end;

function TEngineHudEnvironment.PlayerName(const AIndex: Integer): string;
begin
  Result := player_names[AIndex];
end;

function TEngineHudEnvironment.QueueFullMessage: string;
begin
  Result := HUSTR_MSGU;
end;

function TEngineHudEnvironment.TalkToSelfMessage(const ALevel: Integer): string;
begin
  case ALevel of
    1: Result := HUSTR_TALKTOSELF1;
    2: Result := HUSTR_TALKTOSELF2;
    3: Result := HUSTR_TALKTOSELF3;
    4: Result := HUSTR_TALKTOSELF4;
  else
    Result := HUSTR_TALKTOSELF5;
  end;
end;

procedure TEngineHudEnvironment.PlayChatSound;
begin
{$IF DEFINED(DOOM)}
  if gamemode = commercial then
    S_StartSound(nil, Ord(sfx_radio))
  else
    S_StartSound(nil, Ord(sfx_tink));
{$ELSEIF DEFINED(STRIFE)}
  S_StartSound(nil, Ord(sfx_radio));
{$ENDIF}
end;

procedure TEngineHudEnvironment.Echo(const AText: string);
begin
  printf('%s'#13#10, [AText]);
end;

end.
