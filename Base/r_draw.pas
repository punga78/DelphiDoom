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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_draw;

interface

uses
  d_delphi,
  doomdef,
  r_defs,
// Needs access to LFB (guess what).
  v_video,
  DelphiDoom.Palette.Intf;

//==============================================================================
//
// R_VideoErase
//
//==============================================================================
procedure R_VideoErase(const ofs: integer; const count: integer);

//==============================================================================
//
// R_VideoBlanc
//
//==============================================================================
procedure R_VideoBlanc(const scn: integer; const ofs: integer; const count: integer; const black: byte = 0);

//==============================================================================
//
// R_PlayerViewBlanc
//
//==============================================================================
procedure R_PlayerViewBlanc(const black: byte);

//==============================================================================
//
// R_InitBuffer
//
//==============================================================================
procedure R_InitBuffer(width, height: integer);

//==============================================================================
//
// R_ConfigurePlayerTranslations
// The color ramps of the players of Libs\Palette, given by the composition root
// (not in Hexen: it reads its tables from the lumps TRANTBL)
//
//==============================================================================
procedure R_ConfigurePlayerTranslations(const ATranslations: IPlayerTranslations);

//==============================================================================
// R_InitTranslationTables
//
// Initialize color translation tables,
//  for player rendering etc.
//
//==============================================================================
procedure R_InitTranslationTables;

//==============================================================================
// R_FillBackScreen
//
// Rendering function.
//
//==============================================================================
procedure R_FillBackScreen;
{$IFDEF DOOM}

{$IFNDEF OPENGL}
//==============================================================================
//
// R_FillBackStatusbar
//
//==============================================================================
procedure R_FillBackStatusbar;
{$ENDIF}

{$ELSE}

{$ENDIF}
//==============================================================================
// R_DrawViewBorder
//
// If the view size is not full screen, draws a border around it.
//
//==============================================================================
procedure R_DrawViewBorder;

//==============================================================================
// R_DrawDiskBusy
//
// Draw disk busy patch
//
//==============================================================================
procedure R_DrawDiskBusy;

var
  displaydiskbusyicon: boolean = true;

  translationtables: PByteArray;
{$IFDEF HEXEN}
  tinttable: PByteArray;
{$ENDIF}
  dc_translation: PByteArray;

  viewwidth: integer;
  viewheight: integer;
  scaledviewwidth: integer;

  viewwindowx: integer;
  viewwindowy: integer;
{$IFDEF HEXEN}

  borderneedsrefresh: boolean = false;
{$ENDIF}

//
// All drawing to the view buffer is accomplished in this file.
// The other refresh files only know about ccordinates,
//  not the architecture of the frame buffer.
// Conveniently, the frame buffer is a linear one,
//  and we need only the base address,
//  and the total size == width*height*depth/8.,
//

var
  ylookup: array[0..MAXHEIGHT - 1] of PByteArray;
  ylookupl: array[0..MAXHEIGHT - 1] of PLongWordArray;
  columnofs: array[0..MAXWIDTH - 1] of integer;

type
  crange_idx_e = (
    CR_BRICK,   //0
    CR_TAN,     //1
    CR_GRAY,    //2
    CR_GREEN,   //3
    CR_BROWN,   //4
    CR_GOLD,    //5
    CR_RED,     //6
    CR_BLUE,    //7
    CR_ORANGE,  //8
    CR_YELLOW,  //9
    CR_BLUE2,   //10
    CR_BLACK,   //11
    CR_PURPL,   //12
    CR_WHITE,   //13
    CR_TRANS0,  //14
    CR_TRANS1,  //15
    CR_TRANS2,  //16
    CR_TRANS3,  //17
    CR_TRANS4,  //18
    CR_TRANS5,  //19
    CR_TRANS6,  //20
    CR_TRANS7,  //21
    CR_TRANS8,  //22
    CR_TRANS9,  //23
    CR_LIMIT    //24
  );

var
  colorregions: array[0..Ord(CR_LIMIT) - 1] of PByteArray;
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
{$IFDEF OPENGL}
  diskbusy_height: integer = 0;
{$ENDIF}
{$ENDIF}

{$IFDEF STRIFE}
var
  xlatab: PByteArray;

{$ENDIF}
implementation

uses
  am_map,
  DelphiDoom.Palette.ColorRegionLumps,
  m_argv,
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  r_hires,
{$ENDIF}
  w_wad,
  z_zone,
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  sb_bar,
{$ELSE}
  st_stuff,
{$ENDIF}
  i_system,
{$IF DEFINED(DOOM)}
{$IFDEF OPENGL}
  gl_render,
{$ELSE}
  r_hires,
{$ENDIF}
  r_main,
{$ELSEIF DEFINED(STRIFE)}
{$IFDEF OPENGL}
  gl_render,
{$ELSE}
  r_hires,
{$ENDIF}
{$ELSE}
{$IFDEF OPENGL}
  gl_render,
{$ENDIF}
{$ENDIF}
// State.
  doomstat,
  v_data;

var
  player_translations: IPlayerTranslations = nil;

//==============================================================================
//
// R_ConfigurePlayerTranslations
//
//==============================================================================
procedure R_ConfigurePlayerTranslations(const ATranslations: IPlayerTranslations);
begin
  player_translations := ATranslations;
end;

//==============================================================================
//
// R_InitTranslationTables
// Creates the translation tables to map
//  the green color ramp to gray, brown, red.
// Assumes a given structure of the PLAYPAL.
// Could be read from a lump instead.
//
//==============================================================================
procedure R_InitTranslationTables;
var
  i, j: integer;
{$IFDEF HEXEN}
  transLump: PByteArray;
  trlmp: integer;
  idx: integer;
{$ENDIF}
  lump: integer;
  lump2: integer;
  numcrlumps: integer;
  crnames: TArray<string>;
  crlengths: TArray<Integer>;
  crsources: TArray<Integer>;
{$IFDEF STRIFE}
  col1, col2: byte;
{$ENDIF}
{$IFNDEF HEXEN}
  tables: TArray<Byte>;
{$ENDIF}
begin
{$IF DEFINED(HEXEN)}
  tinttable := W_CacheLumpName('TINTTAB', PU_STATIC);
  translationtables := Z_Malloc(256 * 3 * (MAXPLAYERS - 1), PU_STATIC, nil);

  trlmp := W_GetNumForName('TRANTBL0');
  idx := trlmp;
  for i := 0 to 3 * (MAXPLAYERS - 1) - 1 do
  begin
    transLump := W_CacheLumpNum(idx, PU_STATIC);
    memcpy(@translationtables[i * 256], transLump, 256);
    Z_Free(transLump);
    // JVAL: Circle thru translation tables
    inc(idx);
    if Pos('TRANTBL', strupper(char8tostring(W_GetNameForNum(idx)))) = 0 then
      idx := trlmp;
  end;
{$ELSE}
  if player_translations = nil then
    I_Error('R_InitTranslationTables(): the player translations are not configured (ComposeEngine was not called)');
{$IF DEFINED(STRIFE)}
  xlatab := W_CacheLumpName('XLATAB', PU_STATIC);
  translationtables := Z_Malloc(256 * 8, PU_STATIC, nil);
{$ELSE}
  translationtables := Z_Malloc(256 * 3 + 255, PU_STATIC, nil);
  translationtables := PByteArray((integer(translationtables) + 255 ) and not 255);
{$ENDIF}
  // the color ramps of the players, mapped by Libs\Palette
  tables := player_translations.Build;
  memcpy(translationtables, @tables[0], Length(tables));
{$ENDIF}
  // JVAL: Initialize ColorRegions
  lump := W_CheckNumForName('CR_START');
  for i := 0 to Ord(CR_LIMIT) - 1 do
    colorregions[i] := Z_Malloc(256, PU_STATIC, nil);
  if lump = -1 then
  begin
    printf(#13#10); // JVAL: keep stdout happy...
    I_Warning('Colormap extensions not found, using default translations'#13#10);
    for i := 0 to Ord(CR_LIMIT) - 1 do
      for j := 0 to 255 do
        colorregions[i][j] := j;
  end
  else
  begin
    // The WAD can have fewer color regions than the engine wants (the system WAD of Rad-X
    // stops at CRBLUE2): the lumps after CR_END are not tables and are not read into the
    // 256 bytes of a region (the heap of the zone was overwritten), the region stays identity
    numcrlumps := 0;
    SetLength(crnames, Ord(CR_LIMIT));
    SetLength(crlengths, Ord(CR_LIMIT));
    SetLength(crsources, Ord(CR_LIMIT));
    for i := 0 to Ord(CR_LIMIT) - 1 do
    begin
      if lump + 1 + i >= W_NumLumps then
        Break;
      lump2 := W_CheckNumForName(W_GetNameForNum(lump + 1 + i));
      crnames[i] := char8tostring(W_GetNameForNum(lump + 1 + i));
      if W_LumpLength(lump2) = 256 then
        crsources[i] := lump2
      else
        crsources[i] := lump + 1 + i;
      crlengths[i] := W_LumpLength(crsources[i]);
      inc(numcrlumps);
    end;
    SetLength(crnames, numcrlumps);
    SetLength(crlengths, numcrlumps);
    numcrlumps := TColorRegionLumps.ValidCount(crnames, crlengths);

    for i := 0 to Ord(CR_LIMIT) - 1 do
      if i < numcrlumps then
        W_ReadLump(crsources[i], colorregions[i])
      else
        for j := 0 to 255 do
          colorregions[i][j] := j;
  end;

end;

//==============================================================================
//
// R_InitBuffer
// Creats lookup tables that avoid
//  multiplies and other hazzles
//  for getting the framebuffer address
//  of a pixel to draw.
//
//==============================================================================
procedure R_InitBuffer(width, height: integer);
var
  i: integer;
begin
  // Handle resize,
  //  e.g. smaller view windows
  //  with border and/or status bar.
  viewwindowx := (SCREENWIDTH - width) div 2;

  // Column offset. For windows.
  for i := 0 to width - 1 do
    columnofs[i] := viewwindowx + i;

  // Same with base row offset.
  if width = SCREENWIDTH then
  begin
    viewwindowy := 0;
  end
  else
  begin
  {$IFDEF OPENGL}
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
    viewwindowy := (trunc(SB_Y * SCREENHEIGHT / 200) - height) div 2;
{$ELSE}
    viewwindowy := (trunc(ST_Y * SCREENHEIGHT / 200) - height) div 2;
{$ENDIF}
  {$ELSE}
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
    viewwindowy := (V_PreserveY(SB_Y) - height) div 2;
{$ELSE}
    viewwindowy := (V_PreserveY(ST_Y) - height) div 2;
{$ENDIF}
  {$ENDIF}
  end;

{$IFNDEF OPENGL}
  // Preclaculate all row offsets.
  for i := 0 to height - 1 do
  begin
    ylookup[i] := PByteArray(integer(screens[SCN_FG]) + (i + viewwindowy) * SCREENWIDTH);
    ylookupl[i] := PLongWordArray(@screen32[(i + viewwindowy) * SCREENWIDTH]);
  end;
{$ENDIF}
end;

//==============================================================================
//
// R_ScreenBlanc
//
//==============================================================================
procedure R_ScreenBlanc(const scn: integer; const black: byte = 0);
var
  x, i: integer;
begin
  x := viewwindowy * SCREENWIDTH + viewwindowx;
  for i := 0 to viewheight - 1 do
  begin
    R_VideoBlanc(scn, x, scaledviewwidth, black);
    inc(x, SCREENWIDTH);
  end;
end;

//==============================================================================
//
// R_FillBackScreen
// Fills the back screen with a pattern
//  for variable screen sizes
// Also draws a beveled edge.
//
//==============================================================================
procedure R_FillBackScreen;
{$IFDEF HEXEN}
{$IFNDEF OPENGL}
var
  src: PByteArray;
  dest: PByteArray;
  x: integer;
  y: integer;
  patch: Ppatch_t;
  tviewwindowx: integer;
  tviewwindowy: integer;
  tviewheight: integer;
  tscaledviewwidth: integer;
{$ENDIF}
{$ELSE}
var
{$IFNDEF OPENGL}
  src: PByteArray;
  dest: PByteArray;
  x: integer;
  y: integer;
  patch: Ppatch_t;
  tviewwindowx: integer;
  tviewwindowy: integer;
  tviewheight: integer;
  tscaledviewwidth: integer;
{$ENDIF}
  name: string;
{$ENDIF}
begin
{$IFDEF SPEED}
{$IFNDEF OPENGL}
  // Speed Haste has no pictures for the border of the view (brdr_t ...): nothing is drawn around it
  needsbackscreen := false;
  exit;
{$ENDIF}
{$ENDIF}
{$IF DEFINED(DOOM)}
  {$IFDEF OPENGL}
  if not statusbarstretch then
  {$ENDIF}
    if scaledviewwidth = SCREENWIDTH then
      exit;
{$ELSEIF DEFINED(STRIFE)}
  if scaledviewwidth = SCREENWIDTH then
    exit;
{$ELSE}
  needsbackscreen := false;
{$ENDIF}

{$IF DEFINED(HERETIC)}
  if scaledviewwidth = SCREENWIDTH then
    exit;

  if gamemode = shareware then
    name := 'FLOOR04'   // Shareware border patch.
  else
    name := 'FLAT513';  // Register border patch.
{$ELSEIF DEFINED(HEXEN)}
  if scaledviewwidth = SCREENWIDTH then
    exit;
{$ELSEIF DEFINED(STRIFE)}
  name := 'F_PAVE01'; // Border patch
{$ELSE}
{$IFDEF SPEED}
  name := 'FLAT0001'; // Speed Haste has no border flat of its own: its first flat.
{$ELSE}
  if gamemode = commercial then
    name := 'GRNROCK'   // DOOM II border patch.
  else
    name := 'FLOOR7_2'; // DOOM border patch.
{$ENDIF}
{$ENDIF}

{$IFDEF OPENGL}
{$IFDEF HEXEN}
  gld_DrawBackground('F_022');
{$ELSE}
  gld_DrawBackground(name);
{$ENDIF}
{$ELSE}
{$IF DEFINED(HERETIC)}
  src := W_CacheLumpName(name, PU_CACHE);
{$ELSEIF DEFINED(HEXEN)}
  src := W_CacheLumpName('F_022', PU_CACHE);
{$ELSE}

  needsbackscreen := false;

  src := W_CacheLumpName(name, PU_STATIC);
{$ENDIF}

  dest := screens[SCN_TMP];

{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  for y := 0 to 200 - SB_HEIGHT do
{$ELSE}
  for y := 0 to 200 - ST_HEIGHT do
{$ENDIF}
  begin
    for x := 0 to 320 div 64 - 1 do
    begin
      memcpy(dest, PByteArray(integer(src) + _SHL(y and 63, 6)), 64);
      dest := @dest[64];
    end;
    if 320 and 63 <> 0 then
    begin
      memcpy(dest, PByteArray(integer(src) + _SHL(y and 63, 6)), 320 and 63);
      dest := @dest[64];
    end;
  end;

{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  Z_ChangeTag(src, PU_CACHE);

{$ENDIF}
  tviewwindowx := viewwindowx * 320 div SCREENWIDTH + 1;
  tviewwindowy := viewwindowy * 200 div SCREENHEIGHT + 1;
  tviewheight := viewheight * 200 div SCREENHEIGHT - 2;
  tscaledviewwidth := scaledviewwidth * 320 div SCREENWIDTH - 2;

{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  patch := W_CacheLumpName('bordt', PU_STATIC);
{$ELSE}
  patch := W_CacheLumpName('brdr_t', PU_STATIC);
{$ENDIF}
  x := 0;
  while x < tscaledviewwidth do
  begin
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
    V_DrawPatch(tviewwindowx + x, tviewwindowy - 4, SCN_TMP, patch, false);
    x := x + 16;
{$ELSE}
    V_DrawPatch(tviewwindowx + x, tviewwindowy - 8, SCN_TMP, patch, false);
    x := x + 8;
{$ENDIF}
  end;
  Z_ChangeTag(patch, PU_CACHE);

{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  patch := W_CacheLumpName('bordb', PU_STATIC);
{$ELSE}
  patch := W_CacheLumpName('brdr_b', PU_STATIC);
{$ENDIF}
  x := 0;
  while x < tscaledviewwidth do
  begin
    V_DrawPatch(tviewwindowx + x, tviewwindowy + tviewheight, SCN_TMP, patch, false);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
    x := x + 16;
{$ELSE}
    x := x + 8;
{$ENDIF}
  end;
  Z_ChangeTag(patch, PU_CACHE);

{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  patch := W_CacheLumpName('bordl', PU_STATIC);
{$ELSE}
  patch := W_CacheLumpName('brdr_l', PU_STATIC);
{$ENDIF}
  y := 0;
  while y < tviewheight do
  begin
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
    V_DrawPatch(tviewwindowx - 4, tviewwindowy + y, SCN_TMP, patch, false);
    y := y + 16;
{$ELSE}
    V_DrawPatch(tviewwindowx - 8, tviewwindowy + y, SCN_TMP, patch, false);
    y := y + 8;
{$ENDIF}
  end;
  Z_ChangeTag(patch, PU_CACHE);

{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  patch := W_CacheLumpName('bordr', PU_STATIC);
{$ELSE}
  patch := W_CacheLumpName('brdr_r', PU_STATIC);
{$ENDIF}
  y := 0;
  while y < tviewheight do
  begin
    V_DrawPatch(tviewwindowx + tscaledviewwidth, tviewwindowy + y, SCN_TMP, patch, false);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
    y := y + 16;
{$ELSE}
    y := y + 8;
{$ENDIF}
  end;
  Z_ChangeTag(patch, PU_CACHE);

  // Draw beveled edge.
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  V_DrawPatch(tviewwindowx - 4, tviewwindowy - 4, SCN_TMP,
    'bordtl', false);
{$ELSE}
  V_DrawPatch(tviewwindowx - 8, tviewwindowy - 8, SCN_TMP,
    'brdr_tl', false);
{$ENDIF}

{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  V_DrawPatch(tviewwindowx + tscaledviewwidth, tviewwindowy - 4, SCN_TMP,
    'bordtr', false);
{$ELSE}
  V_DrawPatch(tviewwindowx + tscaledviewwidth, tviewwindowy - 8, SCN_TMP,
    'brdr_tr', false);
{$ENDIF}

{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  V_DrawPatch(tviewwindowx - 4, tviewwindowy + tviewheight, SCN_TMP,
    'bordbl', false);
{$ELSE}
  V_DrawPatch(tviewwindowx - 8, tviewwindowy + tviewheight, SCN_TMP,
    'brdr_bl', false);
{$ENDIF}

  V_DrawPatch(tviewwindowx + tscaledviewwidth, tviewwindowy + tviewheight, SCN_TMP,
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
    'bordbr', false);
{$ELSE}
    'brdr_br', false);
{$ENDIF}

  V_RemoveTransparency(SCN_TMP, 0, -1);
  V_CopyRect(0, 0, SCN_TMP, V_GetScreenWidth(SCN_TMP), V_GetScreenHeight(SCN_TMP), 0, 0, SCN_BG, true);

  R_ScreenBlanc(SCN_BG);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  x := V_PreserveY(SB_Y) * SCREENWIDTH;
  R_VideoBlanc(SCN_BG, x, (SCREENHEIGHT - V_PreserveY(SB_Y)) * SCREENWIDTH);
{$ELSE}
  x := V_PreserveY(ST_Y) * V_GetScreenWidth(SCN_BG); //SCREENWIDTH;
  R_VideoBlanc(SCN_BG, x, (V_GetScreenHeight(SCN_BG) - V_PreserveY(ST_Y)) * V_GetScreenWidth(SCN_BG));
{$ENDIF}
{$ENDIF}
end;
{$IFDEF DOOM}

{$IFNDEF OPENGL}
var
  oldstatusbarfillblocks: integer = -1;

//==============================================================================
//
// R_FillBackStatusbar
//
//==============================================================================
procedure R_FillBackStatusbar;
var
  src: PByteArray;
  dest: PByteArray;
  x: integer;
  y: integer;
  patch: Ppatch_t;
  name: string;
begin
{$IFDEF SPEED}
  // Speed Haste has no status bar: there is nothing to fill behind it
  needsstatusbarback := false;
  exit;
{$ENDIF}
  if (oldstatusbarfillblocks <> 10) <> (screenblocks <> 10) then
  begin
    oldstatusbarfillblocks := screenblocks;
    needsstatusbarback := true;
  end;

  if not needsstatusbarback then
    exit;

  needsstatusbarback := false;

{$IFDEF SPEED}
  name := 'FLAT0001'; // Speed Haste has no border flat of its own: its first flat.
{$ELSE}
  if gamemode = commercial then
    name := 'GRNROCK'   // DOOM II border patch.
  else
    name := 'FLOOR7_2'; // DOOM border patch.
{$ENDIF}

  src := W_CacheLumpName(name, PU_STATIC);

  dest := screens[SCN_ST2];

  for y := 200 - ST_HEIGHT + 1 to 200 do
  begin
    for x := 0 to 320 div 64 - 1 do
    begin
      memcpy(dest, PByteArray(integer(src) + _SHL(y and 63, 6)), 64);
      dest := @dest[64];
    end;
  end;

  Z_ChangeTag(src, PU_CACHE);

  if screenblocks = 10 then
  begin
    patch := W_CacheLumpName('brdr_b', PU_STATIC);
    x := 0;
    while x < 320 do
    begin
      V_DrawPatch(x, patch.topoffset, SCN_ST2, patch, false);
      x := x + 8;
    end;
    Z_ChangeTag(patch, PU_CACHE);
  end;

  V_RemoveTransparency(SCN_ST2, 0, -1);
end;
{$ENDIF}
{$ENDIF}

//==============================================================================
// R_VideoErase
//
// Copy a screen buffer.
//
//==============================================================================
procedure R_VideoErase(const ofs: integer; const count: integer);
var
  i: integer;
  src: PByte;
  dest: PLongWord;
begin
  // LFB copy.
  // This might not be a good idea if memcpy
  //  is not optiomal, e.g. byte by byte on
  //  a 32bit CPU, as GNU GCC/Linux libc did
  //  at one point.
{$IFNDEF OPENGL}
  if videomode = vm32bit then
  begin
{$ENDIF}
    src := PByte(integer(screens[SCN_BG]) + ofs);
    dest := @screen32[ofs];
    for i := 1 to count do
    begin
      dest^ := videopal[src^];
      inc(dest);
      inc(src);
    end;
{$IFNDEF OPENGL}
  end
  else
    memcpy(Pointer(integer(screens[SCN_FG]) + ofs), Pointer(integer(screens[SCN_BG]) + ofs), count);
{$ENDIF}
end;

//==============================================================================
//
// R_VideoBlanc
//
//==============================================================================
procedure R_VideoBlanc(const scn: integer; const ofs: integer; const count: integer; const black: byte = 0);
var
  start: PByte;
  lstrart: PLongWord;
  i: integer;
  lblack: LongWord;
begin
  if {$IFNDEF OPENGL}(videomode = vm32bit) and{$ENDIF} (scn = SCN_FG) then
  begin
    lblack := curpal[black];
    lstrart := @screen32[ofs];
    for i := 0 to count - 1 do
    begin
      lstrart^ := lblack;
      inc(lstrart);
    end;
  end
  else
  begin
    start := @screens[scn][ofs];
    memset(start, black, count);
  end;
end;

//==============================================================================
//
// R_PlayerViewBlanc
//
//==============================================================================
procedure R_PlayerViewBlanc(const black: byte);
begin
  R_ScreenBlanc(SCN_FG, black);
end;

//==============================================================================
//
// R_DrawViewBorder
// Draws the border around the view
//  for different size windows?
//
//==============================================================================
procedure R_DrawViewBorder;
begin
  if scaledviewwidth < SCREENWIDTH then
    if (gamestate = GS_LEVEL) and (amstate <> am_only) then
      V_CopyScreenTransparent(SCN_BG, SCN_FG);
end;

var
  disklump: integer = -2;
  diskpatch: Ppatch_t = nil;

//==============================================================================
//
// R_DrawDiskBusy
//
//==============================================================================
procedure R_DrawDiskBusy;
begin
{$IFDEF DOOM}
  {$IFDEF OPENGL}
  diskbusy_height := 0;
  {$ENDIF}
{$ENDIF}
  if not displaydiskbusyicon then
    exit;

// Draw disk busy patch
  if disklump = -2 then
  begin
{$IFDEF STRIFE}
    disklump := W_CheckNumForName('STDISK');
{$ELSE}
    if M_CheckParmCDROM then
      disklump := W_CheckNumForName('STCDROM');
    if disklump < 0 then
      disklump := W_CheckNumForName('STDISK');
{$ENDIF}
    if disklump >= 0 then
      diskpatch := W_CacheLumpNum(disklump, PU_STATIC)
    else
    begin
      I_Warning('Disk busy lump not found!'#13#10);
      exit;
    end;
  end;

  if diskpatch <> nil then
    V_DrawPatch(318 - diskpatch.width, 2, SCN_FG,
      diskpatch, true);
{$IF DEFINED(DOOM)}
  {$IFDEF OPENGL}
  if diskpatch <> nil then
    diskbusy_height := diskpatch.height + 3;
  {$ENDIF}
{$ELSEIF DEFINED(STRIFE)}
  {$IFDEF OPENGL}
  diskbusy_height := diskpatch.height + 3;
  {$ENDIF}
{$ENDIF}
end;

end.
