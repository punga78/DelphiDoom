{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the heads-up display library - the fakes               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Hud.Fakes;

interface

uses
  System.SysUtils, DelphiDoom.Hud.Types, DelphiDoom.Hud.Intf;

type
  /// <summary>
  ///   A game that is only fields: the six services that the library asks of the engine, one
  ///   object, so that a test sets what it wants and reads what the library did
  /// </summary>
  TFakeHudWorld = class(TInterfacedObject, IHudFlags, IHudPlayers, IHudPlayerMessage,
    IHudSettings, IHudChatSound, IHudEcho)
  public
    ChatOn: Boolean;
    MessageForced: Boolean;
    NetGame: Boolean;
    French: Boolean;
    MessagesShown: Boolean;
    Attached: Boolean;
    Console: Integer;
    InGame: array[0..HUD_MAX_PLAYERS - 1] of Boolean;
    ChatChars: array[0..HUD_MAX_PLAYERS - 1] of Byte;
    PlayerMessage: string;
    DestinationKeys: array[0..HUD_MAX_PLAYERS - 1] of string;
    Macros: array[0..9] of string;
    Names: array[0..HUD_MAX_PLAYERS - 1] of string;
    Sounds: Integer;
    EchoLog: string;
    QueueFull: string;
    TalkToSelf: array[1..HUD_TALK_TO_SELF_LEVELS] of string;
    constructor Create;
    function GetChatOn: Boolean;
    procedure SetChatOn(const AValue: Boolean);
    function GetMessageForced: Boolean;
    procedure SetMessageForced(const AValue: Boolean);
    function IsNetGame: Boolean;
    function ConsolePlayerIndex: Integer;
    function IsInGame(const AIndex: Integer): Boolean;
    function ChatChar(const AIndex: Integer): Byte;
    procedure ClearChatChar(const AIndex: Integer);
    procedure AttachConsolePlayer;
    function ReadMessage: string;
    procedure WriteMessage(const AValue: string);
    function IsFrench: Boolean;
    function AreMessagesShown: Boolean;
    function DestinationKeyCode(const AIndex: Integer): Integer;
    function ChatMacro(const AIndex: Integer): string;
    function PlayerName(const AIndex: Integer): string;
    function QueueFullMessage: string;
    function TalkToSelfMessage(const ALevel: Integer): string;
    procedure PlayChatSound;
    procedure Echo(const AText: string);
  end;

/// <summary>The rules of Doom, as Engine.Hud.Rules builds them</summary>
function DoomHudRules: THudRules;

implementation

{ TFakeHudWorld }

constructor TFakeHudWorld.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  MessagesShown := True;
  QueueFull := '[Message unsent]';
  for LIndex := 1 to HUD_TALK_TO_SELF_LEVELS do
    TalkToSelf[LIndex] := 'You mumble ' + IntToStr(LIndex);
  for LIndex := 0 to 9 do
    Macros[LIndex] := 'macro' + IntToStr(LIndex);
  for LIndex := 0 to HUD_MAX_PLAYERS - 1 do
  begin
    Names[LIndex] := 'Player' + IntToStr(LIndex) + ': ';
    DestinationKeys[LIndex] := Chr(Ord('a') + LIndex);
  end;
end;

function TFakeHudWorld.GetChatOn: Boolean;
begin
  Result := ChatOn;
end;

procedure TFakeHudWorld.SetChatOn(const AValue: Boolean);
begin
  ChatOn := AValue;
end;

function TFakeHudWorld.GetMessageForced: Boolean;
begin
  Result := MessageForced;
end;

procedure TFakeHudWorld.SetMessageForced(const AValue: Boolean);
begin
  MessageForced := AValue;
end;

function TFakeHudWorld.IsNetGame: Boolean;
begin
  Result := NetGame;
end;

function TFakeHudWorld.ConsolePlayerIndex: Integer;
begin
  Result := Console;
end;

function TFakeHudWorld.IsInGame(const AIndex: Integer): Boolean;
begin
  Result := InGame[AIndex];
end;

function TFakeHudWorld.ChatChar(const AIndex: Integer): Byte;
begin
  Result := ChatChars[AIndex];
end;

procedure TFakeHudWorld.ClearChatChar(const AIndex: Integer);
begin
  ChatChars[AIndex] := 0;
end;

procedure TFakeHudWorld.AttachConsolePlayer;
begin
  Attached := True;
end;

function TFakeHudWorld.ReadMessage: string;
begin
  if Attached then
    Result := PlayerMessage
  else
    Result := '';
end;

procedure TFakeHudWorld.WriteMessage(const AValue: string);
begin
  PlayerMessage := AValue;
end;

function TFakeHudWorld.IsFrench: Boolean;
begin
  Result := French;
end;

function TFakeHudWorld.AreMessagesShown: Boolean;
begin
  Result := MessagesShown;
end;

function TFakeHudWorld.DestinationKeyCode(const AIndex: Integer): Integer;
begin
  if DestinationKeys[AIndex] = '' then
    Result := -1
  else
    Result := Ord(DestinationKeys[AIndex][1]);
end;

function TFakeHudWorld.ChatMacro(const AIndex: Integer): string;
begin
  Result := Macros[AIndex];
end;

function TFakeHudWorld.PlayerName(const AIndex: Integer): string;
begin
  Result := Names[AIndex];
end;

function TFakeHudWorld.QueueFullMessage: string;
begin
  Result := QueueFull;
end;

function TFakeHudWorld.TalkToSelfMessage(const ALevel: Integer): string;
begin
  Result := TalkToSelf[ALevel];
end;

procedure TFakeHudWorld.PlayChatSound;
begin
  Inc(Sounds);
end;

procedure TFakeHudWorld.Echo(const AText: string);
begin
  EchoLog := EchoLog + AText + #13#10;
end;

function DoomHudRules: THudRules;
begin
  Result.MessageTimeout := 4 * 35;
  Result.TicRate := 35;
  Result.FpsLongHistory := 512;
  Result.Broadcast := 5;
  Result.LastDestination := 5;
  Result.MessageRefreshKey := 13;
  Result.InputToggleKey := Ord('t');
  Result.MaxPlayers := 4;
  Result.Keys.Enter := 13;
  Result.Keys.Escape := 27;
  Result.Keys.Backspace := 127;
  Result.Keys.RightShift := $80 + $36;
  Result.Keys.RightAlt := $80 + $38;
  Result.Keys.LeftAlt := $80 + $38;
end;

end.
