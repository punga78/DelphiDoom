{******************************************************************************}
{                                                                              }
{  DelphiDoom: Radix game - the fonts of the menus and of the cockpit          }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the font part of HU_Init of Rad-X (Radix\hu_stuff.pas): the seven   }
{  fonts that the translation of RADIX.DAT writes besides the small one        }
{  (DOSFA/DOSFB, BIGFA/BIGFB/BIGFC, DOSSA/DOSSB)                               }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}

unit radix_fonts;

interface

uses
  r_defs;

const
  DOS_FONTSTART = '!'; // the first dos font characters
  DOS_FONTEND = #128; // the last dos font characters

// Calculate # of glyphs in font.
  DOS_FONTSIZE = (Ord(DOS_FONTEND) - Ord(DOS_FONTSTART)) + 1;

  BIG_FONTSTART = '!'; // the first big font characters
  BIG_FONTEND = #128; // the last big font characters

  BIG_FONTSIZE = (Ord(BIG_FONTEND) - Ord(BIG_FONTSTART)) + 1;

type
  radixfont_t = array[0..DOS_FONTSIZE - 1] of Ppatch_t;
  Pradixfont_t = ^radixfont_t;

var
  dos_fontA: radixfont_t; // Red DOS font
  dos_fontB: radixfont_t; // White DOS font

  big_fontA: radixfont_t; // Red BIG font
  big_fontB: radixfont_t; // Gray BIG font
  big_fontC: radixfont_t; // Orange BIG font

  small_fontA: radixfont_t; // Red small font
  small_fontB: radixfont_t; // White small font

//==============================================================================
//
// RX_FontLumpNum
// The lump of a character of a font; the empty sprite (TNT1A0) for a character
// that the font does not have
//
//==============================================================================
function RX_FontLumpNum(const prefix: string; const ch: integer): integer;

//==============================================================================
//
// RX_LumpNumOrEmpty
// The lump with the name, or the empty sprite (TNT1A0) when the data of Radix
// do not have a picture that the engine of Doom draws
//
//==============================================================================
function RX_LumpNumOrEmpty(const name: string): integer;

//==============================================================================
//
// RX_InitFonts
// Loads the seven fonts. HU_Init calls it after the small font (FNTAnnn)
//
//==============================================================================
procedure RX_InitFonts;

implementation

uses
  d_delphi,
  w_wad,
  z_zone;

const
  S_NOCHARLUMP = 'TNT1A0';

//==============================================================================
//
// RX_FontLumpNum
//
//==============================================================================
function RX_FontLumpNum(const prefix: string; const ch: integer): integer;
begin
  result := RX_LumpNumOrEmpty(prefix + IntToStrZfill(3, ch));
end;

//==============================================================================
//
// RX_LumpNumOrEmpty
//
//==============================================================================
function RX_LumpNumOrEmpty(const name: string): integer;
begin
  result := W_CheckNumForName(name);
  if result < 0 then
    result := W_GetNumForName(S_NOCHARLUMP);
end;

//==============================================================================
//
// RX_LoadFont
//
//==============================================================================
procedure RX_LoadFont(const prefix: string; const font: Pradixfont_t);
var
  i: integer;
begin
  for i := 0 to DOS_FONTSIZE - 1 do
    font[i] := W_CacheLumpNum(RX_FontLumpNum(prefix, Ord(DOS_FONTSTART) + i), PU_STATIC);
end;

//==============================================================================
//
// RX_InitFonts
//
//==============================================================================
procedure RX_InitFonts;
begin
  RX_LoadFont('DOSFA', @dos_fontA);
  RX_LoadFont('DOSFB', @dos_fontB);
  RX_LoadFont('BIGFA', @big_fontA);
  RX_LoadFont('BIGFB', @big_fontB);
  RX_LoadFont('BIGFC', @big_fontC);
  RX_LoadFont('DOSSA', @small_fontA);
  RX_LoadFont('DOSSB', @small_fontB);
end;

end.
