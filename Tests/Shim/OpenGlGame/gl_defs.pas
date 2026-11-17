{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of gl_defs for the per-game OpenGL scene tests         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\OpenGl\Legacy\gl_defs.pas in DelphiDoom.Tests.OpenGl.<Game> only: the options the
// scene units read, same names and same initial values as the real ones.
unit gl_defs;

interface

var
  use_fog: boolean = false;
  fog_density: integer = 100;
  use_white_fog: boolean = true;
  white_fog_density: integer = 200;

implementation

end.
