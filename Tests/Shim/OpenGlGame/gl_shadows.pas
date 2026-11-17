{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of gl_shadows for the per-game OpenGL scene tests      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\OpenGl\Legacy\gl_shadows.pas in DelphiDoom.Tests.OpenGl.<Game> only: the shadow of a
// radius is one record of a table, the same one every time (the real unit keeps one per radius too), so the
// tests see which radius the light marker asked for; the initialization call is a line of EventLog.
unit gl_shadows;

interface

uses
  r_dynlights;

function gld_GetDynamicShadow(const radious: integer): PGLDRenderLight;
procedure gld_InitDynamicShadows;

implementation

uses
  d_delphi;

var
  GShadows: array[0..255] of GLDRenderLight;

function gld_GetDynamicShadow(const radious: integer): PGLDRenderLight;
begin
  Result := @GShadows[radious and 255];
  Result.Radius := radious;
  Result.Shadow := True;
end;

procedure gld_InitDynamicShadows;
begin
  ShimEvent('gld_InitDynamicShadows');
end;

end.
