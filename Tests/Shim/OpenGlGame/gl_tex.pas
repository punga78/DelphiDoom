{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of gl_tex for the per-game OpenGL scene tests          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\OpenGl\Legacy\gl_tex.pas in DelphiDoom.Tests.OpenGl.<Game> only: the sizes the
// driver gives, the texture filter (a variable the test reads) and the calls the initializer makes, as
// lines of EventLog.
unit gl_tex;

interface

uses
  gl_defs;

var
  gld_max_texturesize: integer = 0;
  gld_max_texturesize3d: integer = 0;
  /// <summary>The filter gld_GetCurrTexFiltering gives</summary>
  ShimTexFilter: gl_filter_t = FLT_LINEAR;

procedure gld_InitPalettedTextures;
function gld_GetCurrTexFiltering: gl_filter_t;
procedure gld_SetCurrTexFiltering(const flt: gl_filter_t);

implementation

uses
  d_delphi;

procedure gld_InitPalettedTextures;
begin
  ShimEvent('gld_InitPalettedTextures');
end;

function gld_GetCurrTexFiltering: gl_filter_t;
begin
  ShimEvent('gld_GetCurrTexFiltering');
  Result := ShimTexFilter;
end;

procedure gld_SetCurrTexFiltering(const flt: gl_filter_t);
begin
  ShimEvent('gld_SetCurrTexFiltering ' + gl_tex_filters[Ord(flt)]);
end;

end.
