{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of gl_render for the per-game OpenGL scene tests      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\OpenGl\Legacy\gl_render.pas in DelphiDoom.Tests.OpenGl.<Game> only: the light helpers the painters call, as lines of EventLog (floats as bits).
unit gl_render;

interface

uses
  d_delphi;

var
  extra_red: float = 0.0;
  extra_green: float = 0.0;
  extra_blue: float = 0.0;
  extra_alpha: float = 0.0;

procedure gld_SetPalette(palette: integer);
procedure gld_DrawBackgroundFrame;

/// <summary>A light that depends on the level only (the line shows the argument)</summary>
function gld_CalcLightLevel(lightlevel: integer): float;
procedure gld_StaticLight(light: float);
procedure gld_StaticLightAlpha(light: float; alpha: float);

implementation

uses
  System.SysUtils;

function FloatBits(const AValue: Single): string;
begin
  Result := IntToHex(PCardinal(@AValue)^, 8);
end;

procedure gld_SetPalette(palette: integer);
begin
  ShimEvent('gld_SetPalette ' + IntToStr(palette));
end;

procedure gld_DrawBackgroundFrame;
begin
  ShimEvent('gld_DrawBackgroundFrame');
end;

function gld_CalcLightLevel(lightlevel: integer): float;
begin
  ShimEvent('gld_CalcLightLevel ' + IntToStr(lightlevel));
  Result := (lightlevel and 255) / 255.0;
end;

procedure gld_StaticLight(light: float);
begin
  ShimEvent('gld_StaticLight ' + FloatBits(light));
end;

procedure gld_StaticLightAlpha(light: float; alpha: float);
begin
  ShimEvent('gld_StaticLightAlpha ' + FloatBits(light) + ' ' + FloatBits(alpha));
end;

end.