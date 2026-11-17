{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of r_colormaps for the per-game OpenGL scene tests     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Base\r_colormaps.pas in DelphiDoom.Tests.OpenGl.<Game> only: the fog fields of the
// custom colormap (the OPENGL branch of customcolormap_t) and the current one.
unit r_colormaps;

interface

uses
  d_delphi;

type
  customcolormap_t = record
    fog_r, fog_g, fog_b: float;
    fog_density: float;
  end;
  Pcustomcolormap_t = ^customcolormap_t;

var
  customcolormap: Pcustomcolormap_t = nil;

implementation

end.
