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
    function Skill: Integer;
    function Episode: Integer;
    function Map: Integer;
    function Deathmatch: Integer;
    function ConsolePlayer: Integer;
    function MaxPlayers: Integer;
  end;

implementation

uses
  doomdef,
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
  Result := TGameSession.NetGame;
end;

function TEngineGameContext.IsDemoRecording: Boolean;
begin
  Result := TGameSession.DemoRecording;
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

function TEngineGameContext.Skill: Integer;
begin
  Result := Ord(TGameSession.GameSkill);
end;

function TEngineGameContext.Episode: Integer;
begin
{$IFDEF STRIFE}
  // Strife has no episodes (and no gameepisode)
  Result := 1;
{$ELSE}
  Result := TGameSession.GameEpisode;
{$ENDIF}
end;

function TEngineGameContext.Map: Integer;
begin
  Result := TGameSession.GameMap;
end;

function TEngineGameContext.Deathmatch: Integer;
begin
  // qualified: inside the class "deathmatch" would be this very method
  Result := TGameSession.DeathMatch;
end;

function TEngineGameContext.ConsolePlayer: Integer;
begin
  // qualified, as above
  Result := TGameSession.ConsolePlayer;
end;

function TEngineGameContext.MaxPlayers: Integer;
begin
  // qualified, as above
  Result := doomdef.MAXPLAYERS;
end;

end.
