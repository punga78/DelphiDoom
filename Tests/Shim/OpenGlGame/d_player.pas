{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of d_player for the per-game OpenGL scene tests       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\<Game>\d_player.pas in DelphiDoom.Tests.OpenGl.<Game> only: the fields of player_t the OpenGL scene units read, same names and types.
unit d_player;

interface

uses
  p_mobj_h;

type
  player_t = record
    mo: Pmobj_t;
    fixedcolormap: integer;
    lookdir16: integer;
  end;
  Pplayer_t = ^player_t;

implementation

end.