{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what the network library asks of the game              }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Net.Services;

{$I Doom32.inc}

interface

uses
  System.SysUtils,
  DelphiDoom.Clock.Intf,
  DelphiDoom.Net.Intf,
  DelphiDoom.Engine.Shutdown.Intf;

type
  /// <summary>
  ///   The questions of the network synchronization, answered by the game: the local input and the
  ///   commands of the console player, the players of the game, the trace of the network (the
  ///   debug file) and the check of the key ESC while the game waits for the other players.
  ///   One class for several small interfaces: each user of the library sees only its own
  /// </summary>
  TEngineNetServices = class(TInterfacedObject, INetLocalInput, INetPlayers, INetTrace, INetAbortCheck)
  strict private
    FClock: IClock;
    FShutdown: IEngineShutdown;
  public
    /// <param name="AClock">Times the wait for the other players</param>
    /// <param name="AShutdown">Stops the game when the player aborts the wait (I_Error)</param>
    /// <remarks>Raises EArgumentNilException if one of them is nil</remarks>
    constructor Create(const AClock: IClock; const AShutdown: IEngineShutdown);
    procedure PollInput;
    function IsGameFinished: Boolean;
    function BuildTicCmd(ATic: Integer): TBytes;
    function IsPlayerInGame(APlayer: Integer): Boolean;
    procedure PlayerLeft(APlayer: Integer);
    procedure Trace(const AText: string);
    procedure Check;
  end;

implementation

uses
  DelphiDoom.Engine.Parity.Hooks,
  d_delphi,
  d_event,
  d_main,
  d_player,
  d_ticcmd,
  doomdef,
{$IFDEF HEXEN}
  g_demo,
{$ENDIF}
  g_game,
  i_io,
  i_system;

{ TEngineNetServices }

constructor TEngineNetServices.Create(const AClock: IClock; const AShutdown: IEngineShutdown);
begin
  inherited Create;
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  if not Assigned(AShutdown) then
    raise EArgumentNilException.Create('AShutdown');
  FClock := AClock;
  FShutdown := AShutdown;
end;

procedure TEngineNetServices.PollInput;
begin
  I_StartTic;
  D_ProcessEvents;
end;

function TEngineNetServices.IsGameFinished: Boolean;
begin
  Result := I_GameFinished;
end;

function TEngineNetServices.BuildTicCmd(ATic: Integer): TBytes;
var
  LCommand: ticcmd_t;
begin
  FillChar(LCommand, SizeOf(LCommand), 0);
  G_BuildTiccmd(@LCommand);
  Parity_BuildTicCmd(@LCommand);
  SetLength(Result, SizeOf(ticcmd_t));
  Move(LCommand, Result[0], SizeOf(ticcmd_t));
end;

function TEngineNetServices.IsPlayerInGame(APlayer: Integer): Boolean;
begin
  Result := playeringame[APlayer];
end;

procedure TEngineNetServices.PlayerLeft(APlayer: Integer);
var
  LMessage: string;
begin
  playeringame[APlayer] := False;
  LMessage := 'Player 1 left the game';
  LMessage[8] := Chr(Ord(LMessage[8]) + APlayer);
  players[consoleplayer]._message := LMessage;
  if demorecording then
    G_CheckDemoStatus;
end;

procedure TEngineNetServices.Trace(const AText: string);
begin
  if devparm and (debugfile <> nil) then
    fprintf(debugfile, '%s', [AText]);
end;

// Called while the game waits for the other players: the key ESC aborts
procedure TEngineNetServices.Check;
var
  LEvent: Pevent_t;
  LStopTic: Integer;
begin
  LStopTic := FClock.Steps(TICRATE) + 2;
  while FClock.Steps(TICRATE) < LStopTic do
  begin
    FClock.Wait(1);
    I_StartTic;
    I_ProcessWindows;
  end;

  I_StartTic;
  repeat
    LEvent := @events[eventtail];
    if (LEvent._type = ev_keydown) and (LEvent.data1 = KEY_ESCAPE) then
      FShutdown.Fail('D_CheckAbort(): Network game synchronization aborted.');

    eventtail := (eventtail + 1) and (MAXEVENTS - 1);
  until eventtail = eventhead;
end;

end.
