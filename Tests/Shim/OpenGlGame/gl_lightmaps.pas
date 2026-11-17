{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of gl_lightmaps for the per-game OpenGL scene tests    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\OpenGl\Legacy\gl_lightmaps.pas in DelphiDoom.Tests.OpenGl.<Game> only: the two
// options (same names and initial values as the real ones) and the initialization call, a line of EventLog.
unit gl_lightmaps;

interface

var
  gl_uselightmaps: boolean = true;
  canuselightmaps: boolean = true;

procedure gld_InitLightmap;

implementation

uses
  d_delphi;

procedure gld_InitLightmap;
begin
  ShimEvent('gld_InitLightmap');
end;

end.
