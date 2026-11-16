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
//  Radix: the wipe between two screens (radix_wipe.pas of Rad-X). Radix does
//  not melt the screen: the old screen fades to a dark gray and the new one
//  comes out of it, in 32 tics. The wipe of the engine (f_wipe) keeps the two
//  screens and the timing; wipe_ConfigureCustom gives it this fade.
//  Software renderer only; one loop over the pixels (Rad-X used four threads).
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit radix_wipe;

interface

uses
  d_delphi;

//==============================================================================
//
// RX_WipeFade
// wipe_custom_t of f_wipe
//
//==============================================================================
function RX_WipeFade(const scr_start, scr_end, dest: PLongWordArray; const count, ticks: integer;
  const first: boolean): boolean;

implementation

uses
  m_fixed;

const
  FADESPEED = 2048;
  FADECOLOR = $16;

var
  fadefactor: fixed_t = 0;

//==============================================================================
//
// RX_FadeChannel
// A channel of a color on its way to the gray (factor 0: the color, FRACUNIT: the gray)
//
//==============================================================================
function RX_FadeChannel(const c: integer; const factor: fixed_t): LongWord; inline;
begin
  result := LongWord(c + (FADECOLOR - c) * factor div FRACUNIT) and $FF;
end;

//==============================================================================
//
// RX_FadeColor
//
//==============================================================================
function RX_FadeColor(const c: LongWord; const factor: fixed_t): LongWord; inline;
begin
  result := RX_FadeChannel(c and $FF, factor) or
    (RX_FadeChannel((c shr 8) and $FF, factor) shl 8) or
    (RX_FadeChannel((c shr 16) and $FF, factor) shl 16);
end;

//==============================================================================
//
// RX_WipeFade
//
//==============================================================================
function RX_WipeFade(const scr_start, scr_end, dest: PLongWordArray; const count, ticks: integer;
  const first: boolean): boolean;
var
  i: integer;
  ffade: fixed_t;
begin
  if first then
    fadefactor := FRACUNIT;

  fadefactor := fadefactor - ticks * FADESPEED;
  if fadefactor < 0 then
    fadefactor := 0;

  if fadefactor > FRACUNIT div 2 then
  begin
    // the first half: the old screen goes to the gray
    ffade := (FRACUNIT - fadefactor) * 2;
    for i := 0 to count - 1 do
      dest[i] := RX_FadeColor(scr_start[i], ffade);
  end
  else
  begin
    // the second half: the new screen comes out of the gray
    ffade := fadefactor * 2;
    for i := 0 to count - 1 do
      dest[i] := RX_FadeColor(scr_end[i], ffade);
  end;

  result := fadefactor = 0;
end;

end.
