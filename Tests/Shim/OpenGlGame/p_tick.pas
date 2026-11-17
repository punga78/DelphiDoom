{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of p_tick for the per-game OpenGL scene tests          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Base\p_tick.pas in DelphiDoom.Tests.OpenGl.<Game> only: the tic of the level.
unit p_tick;

interface

type
  TTickState = class sealed
  public
    class var LevelTime: integer;
  end;

implementation

end.
