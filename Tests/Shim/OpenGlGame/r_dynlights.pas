{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of r_dynlights for the per-game OpenGL scene tests     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Base\r_dynlights.pas in DelphiDoom.Tests.OpenGl.<Game> only: the same names, types and
// field order of the OPENGL branch of the real unit (keep them aligned), without its other uses.
unit r_dynlights;

interface

uses
  d_delphi,
  DelphiDoom.DynLights.Types;

type
  GLDRenderLight = TDynLightRender;
  PGLDRenderLight = PDynLightRender;

  dlsortitem_t = record
    l: PGLDRenderLight;
    squaredist: single;
    x, y, z: float;
  end;
  Pdlsortitem_t = ^dlsortitem_t;
  dlsortitem_tArray = array[0..$FFFF] of dlsortitem_t;
  Pdlsortitem_tArray = ^dlsortitem_tArray;

var
  dlbuffer: Pdlsortitem_tArray = nil;
  numdlitems: integer = 0;
  realdlitems: integer = 0;
  lightdeflumppresent: boolean = false;
  gldefs_as_lightdef: boolean = true;

implementation

end.
