{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of g_game for the rule tests}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for the real g_game in DelphiDoom.Tests.Rules only: the session values that the rules read (the real unit is the game loop).
{$I Doom32.inc}
unit g_game;

interface

uses
  d_player,
  doomdef;

type
  TGameSession = class sealed
  public
    class var NetGame: boolean;
    class var DeathMatch: integer;
    class var DemoPlayback: boolean;
    class var DemoRecording: boolean;
    class var GameState: gamestate_t;
    class var ConsolePlayer: integer;
    class var Players: array[0..MAXPLAYERS - 1] of player_t;
  end;

function G_PlayingEngineVersion: integer;

function G_IsOldDemoPlaying: boolean;

var
  shim_engineversion: integer = 203;

implementation

function G_PlayingEngineVersion: integer;
begin
  result := shim_engineversion;
end;

function G_IsOldDemoPlaying: boolean;
begin
  result := false;
end;

end.