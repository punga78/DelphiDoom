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
//  Radix: the end of an episode (the part of f_finale.pas that Rad-X changed):
//  the text "EndEpisode<n>Text" of RADIX.DAT typed over a flight among the
//  stars. F_ConfigureReplacement (f_finale) puts these three procedures in
//  the place of the finale of Doom. As in Rad-X the text stays on the screen:
//  the menu is the way out.
//  Difference from Rad-X: the stars come from a generator of their own with a
//  fixed seed (Rad-X used the one of the run time library).
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit radix_finale;

interface

//==============================================================================
//
// RX_Finale_Start
//
//==============================================================================
procedure RX_Finale_Start;

//==============================================================================
//
// RX_Finale_Ticker
//
//==============================================================================
procedure RX_Finale_Ticker;

//==============================================================================
//
// RX_Finale_Drawer
//
//==============================================================================
procedure RX_Finale_Drawer;

implementation

uses
  d_delphi,
  g_game,
  hu_stuff,
  s_sound,
  sounddata,
  v_data,
  v_video,
  w_wad;

const
  TEXTSPEED = 3;
  STARS_MAX_Z = 2048;
  STARS_MAX_VELOCITY = 32;
  NUMSTARS = 200;
  NUMSTARCOLORS = 32;

type
  starinfo_t = record
    x, y, z: integer;
    velocity: integer;
    color: byte;
  end;
  Pstarinfo_t = ^starinfo_t;

var
  finalecount: integer;
  finaletext: string;
  starsinitialized: boolean = false;
  starinfo: array[0..NUMSTARS - 1] of starinfo_t;
  starcolors: array[0..NUMSTARCOLORS - 1] of byte;
  starseed: LongWord = 20200502;

//==============================================================================
//
// RX_StarRandom
// 0..range - 1
//
//==============================================================================
function RX_StarRandom(const range: integer): integer;
begin
  {$Q-}{$R-}
  starseed := starseed * 1664525 + 1013904223;
  result := integer((starseed shr 8) mod LongWord(range));
end;

//==============================================================================
//
// RX_Finale_Start
//
//==============================================================================
procedure RX_Finale_Start;
var
  lumpname: string;
  lump: integer;
begin
  TSoundRoutines.S_ChangeMusic(Ord(mus_intro), true);

  sprintf(lumpname, 'EndEpisode%dText', [TGameSession.GameEpisode]);
  lump := TWadRoutines.W_CheckNumForName(lumpname);
  if lump >= 0 then
    finaletext := TWadRoutines.W_TextLumpNum(lump)
  else
    finaletext := 'The End';
  finalecount := 0;
end;

//==============================================================================
//
// RX_NewStar
// A star is born on the border of the screen
//
//==============================================================================
procedure RX_NewStar(const i: integer; const pstar: Pstarinfo_t);
begin
  case i mod 8 of
    0:
      begin
        pstar.x := -RX_StarRandom(160);
        pstar.y := -100;
      end;
    1:
      begin
        pstar.x := RX_StarRandom(160);
        pstar.y := -100;
      end;
    2:
      begin
        pstar.x := 160;
        pstar.y := -RX_StarRandom(100);
      end;
    3:
      begin
        pstar.x := 160;
        pstar.y := RX_StarRandom(100);
      end;
    4:
      begin
        pstar.x := RX_StarRandom(160);
        pstar.y := 100;
      end;
    5:
      begin
        pstar.x := -RX_StarRandom(160);
        pstar.y := 100;
      end;
    6:
      begin
        pstar.x := -160;
        pstar.y := RX_StarRandom(100);
      end;
  else
    begin
      pstar.x := -160;
      pstar.y := -RX_StarRandom(100);
    end;
  end;
  pstar.velocity := STARS_MAX_VELOCITY + RX_StarRandom(STARS_MAX_VELOCITY);
  pstar.color := RX_StarRandom(NUMSTARCOLORS div 8);
end;

//==============================================================================
//
// RX_StarAnimationTicker
//
//==============================================================================
procedure RX_StarAnimationTicker;
var
  i: integer;
  pstar: Pstarinfo_t;
begin
  if not starsinitialized then
  begin
    for i := 0 to NUMSTARCOLORS - 1 do
      starcolors[i] := V_FindAproxColorIndex(@videopal, (i * 6) shl 16 + (i * 6) shl 8 + (i * 6), 1, 252);
    for i := 0 to NUMSTARS - 1 do
    begin
      pstar := @starinfo[i];
      RX_NewStar(i, pstar);
      pstar.z := RX_StarRandom(STARS_MAX_Z) + 1;
    end;
    starsinitialized := true;
  end;

  // JVAL: 20200502 - Animate flight simulation
  for i := 0 to NUMSTARS - 1 do
  begin
    pstar := @starinfo[i];
    pstar.z := pstar.z - pstar.velocity;
    if pstar.z <= 0 then
    begin
      RX_NewStar(i, pstar);
      pstar.z := STARS_MAX_Z;
    end;
  end;
end;

//==============================================================================
//
// RX_Finale_Ticker
//
//==============================================================================
procedure RX_Finale_Ticker;
begin
  inc(finalecount);
  RX_StarAnimationTicker;
end;

//==============================================================================
//
// RX_StarAnimationDrawer
//
//==============================================================================
procedure RX_StarAnimationDrawer;
var
  i: integer;
  pstar: Pstarinfo_t;
  z: integer;
  screenx, screeny: integer;
begin
  if not starsinitialized then
    RX_StarAnimationTicker;

  ZeroMemory(screens[SCN_TMP], 320 * 200);
  for i := 0 to NUMSTARS - 1 do
  begin
    pstar := @starinfo[i];
    z := pstar.z;
    if z <= 0 then
      z := 1;
    screenx := 160 + round(pstar.x * (1 - z / STARS_MAX_Z));
    screeny := 100 + round(pstar.y * (1 - z / STARS_MAX_Z));
    if IsIntegerInRange(screenx, 0, 319) and IsIntegerInRange(screeny, 0, 199) then
      screens[SCN_TMP][screeny * 320 + screenx] :=
        starcolors[GetIntegerInRange(round(pstar.color + (1 - sqrt(z / STARS_MAX_Z)) * NUMSTARCOLORS),
          0, NUMSTARCOLORS - 1)];
  end;
end;

//==============================================================================
//
// RX_Finale_Drawer
//
//==============================================================================
procedure RX_Finale_Drawer;
var
  w: integer;
  count: integer;
  c: char;
  c1: integer;
  i: integer;
  len: integer;
  cx: integer;
  cy: integer;
  commahack: boolean;
begin
  RX_StarAnimationDrawer;

  // draw some of the text onto the screen
  cx := 4;
  cy := 4;
  len := Length(finaletext);
  count := (finalecount - 10) div TEXTSPEED;
  if count < 0 then
    count := 0
  else if count > len then
    count := len;
  for i := 1 to count do
  begin
    c := finaletext[i];
    if c = #13 then
      continue;
    if c = #10 then
    begin
      cx := 3;
      cy := cy + 8;
      continue;
    end;

    if c = Chr($27) then
    begin
      // the font has no apostrophe: a comma, higher
      c1 := Ord(',') - Ord(HU_FONTSTART);
      commahack := true;
    end
    else
    begin
      commahack := false;
      c1 := Ord(toupper(c)) - Ord(HU_FONTSTART);
      if (c1 < 0) or (c1 >= HU_FONTSIZE) then
      begin
        cx := cx + 3;
        continue;
      end;
    end;

    w := hu_font[c1].width;
    if cx + w > 320 then
      continue;
    if commahack then
      V_DrawPatch(cx, cy - 4, SCN_TMP, hu_font[c1], false)
    else
      V_DrawPatch(cx, cy, SCN_TMP, hu_font[c1], false);
    cx := cx + w;
  end;

  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);
  V_FullScreenStretch;
end;

end.
