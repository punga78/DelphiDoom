{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of g_game for the per-game OpenGL scene tests          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\<Game>\g_game.pas in DelphiDoom.Tests.OpenGl.<Game> only: the players and the
// displayed one, with the names the OpenGL scene units use (TGameSession.Players, displayplayer).
unit g_game;

interface

uses
  d_player;

const
  MAXPLAYERS = 4;

type
  TGameSession = class sealed
  public
    class var Players: array[0..MAXPLAYERS - 1] of player_t;
  end;

var
  displayplayer: integer = 0;

implementation

end.
