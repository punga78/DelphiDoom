{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the state of the game, from its globals                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.GameContext;

interface

uses
  DelphiDoom.GameState.Intf;

type
  /// <summary>The only class that reads these globals for the ones that receive an IGameContext</summary>
  TEngineGameContext = class(TInterfacedObject, IGameContext)
  public
    function IsDeveloperMode: Boolean;
    function IsNetGame: Boolean;
    function IsDemoRecording: Boolean;
    function IsDemoPlayback: Boolean;
    function IsPaused: Boolean;
    function GameTic: Integer;
  end;

implementation

uses
{$IFDEF HEXEN}
  g_demo,
{$ENDIF}
  g_game,
  d_main;

{ TEngineGameContext }

function TEngineGameContext.IsDeveloperMode: Boolean;
begin
  Result := devparm;
end;

function TEngineGameContext.IsNetGame: Boolean;
begin
  Result := netgame;
end;

function TEngineGameContext.IsDemoRecording: Boolean;
begin
  Result := demorecording;
end;

function TEngineGameContext.IsDemoPlayback: Boolean;
begin
  Result := demoplayback;
end;

function TEngineGameContext.IsPaused: Boolean;
begin
  Result := paused;
end;

function TEngineGameContext.GameTic: Integer;
begin
  // qualified: inside the class "gametic" would be this very method
  Result := g_game.gametic;
end;

end.
