//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Speed Haste: the text of the display and of the screens. The fonts are the
//  ones of SPEEDH.JCL (SFNTAnnn..SFNTEnnn small, BFNTAnnn big, one lump for
//  each character from 33 to 127), five colors of the small one.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit speed_text;

interface

const
  // the small fonts of the game, by color
  SPEED_FONT_A = 0;
  SPEED_FONT_B = 1;
  SPEED_FONT_C = 2;
  SPEED_FONT_D = 3;
  SPEED_FONT_E = 4;

//==============================================================================
//
// SH_TextWidth
// How wide the text is, in pixels of the 320x200 screen
//
//==============================================================================
function SH_TextWidth(const text: string): integer;

//==============================================================================
//
// SH_DrawText
// Writes the text with its top left corner at (x, y) on the screen scrn; the
// result is the x after the last character
//
//==============================================================================
function SH_DrawText(const x, y: integer; const text: string; const font: integer;
  const scrn: integer): integer;

//==============================================================================
//
// SH_DrawTextRight
// As SH_DrawText, with the right end of the text at x
//
//==============================================================================
procedure SH_DrawTextRight(const x, y: integer; const text: string; const font: integer;
  const scrn: integer);

//==============================================================================
//
// SH_DrawTextCenter
// As SH_DrawText, with the text centered on x
//
//==============================================================================
procedure SH_DrawTextCenter(const x, y: integer; const text: string; const font: integer;
  const scrn: integer);

implementation

uses
  SysUtils,
  d_delphi,
  r_defs,
  v_video,
  w_wad,
  z_zone;

const
  FIRST_CHAR = 33;
  LAST_CHAR = 127;
  FONT_COUNT = 5;
  SPACE_WIDTH = 5;
  CHAR_SPACING = 1;
  FONT_LETTERS = 'ABCDE';

var
  glyphs: array[0..FONT_COUNT - 1, FIRST_CHAR..LAST_CHAR] of Ppatch_t;
  glyphs_loaded: boolean = false;

//==============================================================================
//
// SH_LoadGlyphs
//
//==============================================================================
procedure SH_LoadGlyphs;
var
  f, c, lump: integer;
begin
  glyphs_loaded := true;
  for f := 0 to FONT_COUNT - 1 do
    for c := FIRST_CHAR to LAST_CHAR do
    begin
      lump := TWadRoutines.W_CheckNumForName(Format('SFNT%s%.3d', [FONT_LETTERS[f + 1], c]));
      if lump >= 0 then
        glyphs[f, c] := TWadRoutines.W_CacheLumpNum(lump, PU_STATIC)
      else
        glyphs[f, c] := nil;
    end;
end;

//==============================================================================
//
// SH_Glyph
//
//==============================================================================
function SH_Glyph(const font: integer; const ch: char): Ppatch_t;
var
  c: integer;
begin
  Result := nil;
  if not glyphs_loaded then
    SH_LoadGlyphs;
  c := Ord(UpCase(ch));
  if (c < FIRST_CHAR) or (c > LAST_CHAR) or (font < 0) or (font >= FONT_COUNT) then
    exit;
  Result := glyphs[font, c];
end;

//==============================================================================
//
// SH_TextWidth
//
//==============================================================================
function SH_TextWidth(const text: string): integer;
var
  i: integer;
  p: Ppatch_t;
begin
  Result := 0;
  for i := 1 to Length(text) do
  begin
    p := SH_Glyph(0, text[i]);
    if p = nil then
      Result := Result + SPACE_WIDTH
    else
      Result := Result + p.width + CHAR_SPACING;
  end;
end;

//==============================================================================
//
// SH_DrawText
//
//==============================================================================
function SH_DrawText(const x, y: integer; const text: string; const font: integer;
  const scrn: integer): integer;
var
  i: integer;
  p: Ppatch_t;
begin
  Result := x;
  for i := 1 to Length(text) do
  begin
    p := SH_Glyph(font, text[i]);
    if p = nil then
      Result := Result + SPACE_WIDTH
    else
    begin
      V_DrawPatch(Result, y, scrn, p, false);
      Result := Result + p.width + CHAR_SPACING;
    end;
  end;
end;

//==============================================================================
//
// SH_DrawTextRight
//
//==============================================================================
procedure SH_DrawTextRight(const x, y: integer; const text: string; const font: integer;
  const scrn: integer);
begin
  SH_DrawText(x - SH_TextWidth(text), y, text, font, scrn);
end;

//==============================================================================
//
// SH_DrawTextCenter
//
//==============================================================================
procedure SH_DrawTextCenter(const x, y: integer; const text: string; const font: integer;
  const scrn: integer);
begin
  SH_DrawText(x - SH_TextWidth(text) div 2, y, text, font, scrn);
end;

end.
