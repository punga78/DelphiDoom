{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of r_data for the per-game OpenGL scene tests          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Base\r_data.pas in DelphiDoom.Tests.OpenGl.<Game> only: whether the level has the
// fog of Hexen.
unit r_data;

interface

var
  LevelUseFog: boolean = False;

implementation

end.
