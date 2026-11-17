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

/// <summary>The texture gld_RegisterPatch and gld_RegisterFlat give (nil: the lump has no texture)</summary>
  ShimTexture: PGLTexture = nil;

procedure gld_InitPalettedTextures;
function gld_RegisterPatch(lump: integer; cm: integer; const unload: boolean = true): PGLTexture;
procedure gld_BindPatch(gltexture: PGLTexture; cm: integer);
function gld_RegisterFlat(lump: integer; mipmap: boolean; flat: integer): PGLTexture;
procedure gld_BindFlat(gltexture: PGLTexture; const ripple: integer);
function gld_GetCurrTexFiltering: gl_filter_t;
procedure gld_SetCurrTexFiltering(const flt: gl_filter_t);

implementation

uses
  System.SysUtils,
  d_delphi;

function gld_RegisterPatch(lump: integer; cm: integer; const unload: boolean): PGLTexture;
begin
  ShimEvent('gld_RegisterPatch ' + IntToStr(lump) + ' ' + IntToStr(cm) + ' ' + BoolToStr(unload, True));
  Result := ShimTexture;
end;

procedure gld_BindPatch(gltexture: PGLTexture; cm: integer);
begin
  ShimEvent('gld_BindPatch ' + BoolToStr(Assigned(gltexture), True) + ' ' + IntToStr(cm));
end;

function gld_RegisterFlat(lump: integer; mipmap: boolean; flat: integer): PGLTexture;
begin
  ShimEvent('gld_RegisterFlat ' + IntToStr(lump) + ' ' + BoolToStr(mipmap, True) + ' ' + IntToStr(flat));
  Result := ShimTexture;
end;

procedure gld_BindFlat(gltexture: PGLTexture; const ripple: integer);
begin
  ShimEvent('gld_BindFlat ' + BoolToStr(Assigned(gltexture), True) + ' ' + IntToStr(ripple));
end;

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
