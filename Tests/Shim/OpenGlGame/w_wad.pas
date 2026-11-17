{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of w_wad for the per-game OpenGL scene tests          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Base\w_wad.pas in DelphiDoom.Tests.OpenGl.<Game> only: one lump (GLGAMMA) whose presence and text the test sets.
unit w_wad;

interface

var
  /// <summary>The number W_CheckNumForName gives for GLGAMMA (-1: the lump is missing)</summary>
  ShimGlGammaLump: integer = -1;
  /// <summary>The text of that lump</summary>
  ShimGlGammaText: string = '';

function W_CheckNumForName(const name: string; const flags: LongWord = $0): integer;
function W_TextLumpNum(const lump: integer): string;
function W_GetNumForName(const name: string): integer;

implementation

uses
  System.SysUtils,
  d_delphi;

function W_CheckNumForName(const name: string; const flags: LongWord): integer;
begin
  ShimEvent('W_CheckNumForName ' + name);
  if name = 'GLGAMMA' then
    Result := ShimGlGammaLump
  else
    Result := -1;
end;

function W_GetNumForName(const name: string): integer;
begin
  ShimEvent('W_GetNumForName ' + name);
  Result := 100 + Length(name);
end;

function W_TextLumpNum(const lump: integer): string;
begin
  ShimEvent('W_TextLumpNum ' + IntToStr(lump));
  Result := ShimGlGammaText;
end;

end.