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
//  Radix: the mission briefing, the screen before a level (radix_briefing.pas
//  of Rad-X): the map of the level that scrolls, the text that is typed, the
//  animation window.
//  Rad-X had a game state of its own (GS_BRIEFING). Here the game states are
//  the ones of Doom: the briefing runs inside GS_INTERMISSION, whose ticker and
//  drawer are already the ones of Radix (WI_ConfigureReplacement): the level is
//  loaded, the state goes back to GS_INTERMISSION until the briefing ends, then
//  to GS_LEVEL. The script and its run are TRadixBriefingScript and
//  TRadixBriefingPlayer of IdTech1\Radix; this unit draws.
//  Differences from Rad-X: no key of its own ("ESC to play"): fire and use go
//  on and, at the end, start the level; the pictures of the animation window,
//  made for 640x400, are drawn at half size on the 320x200 screen.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit radix_briefing;

interface

var
  showbriefingscreen: boolean = true;

//==============================================================================
//
// RB_LevelLoaded
// To call when a level has just been loaded: starts its briefing and takes the
// game out of GS_LEVEL, unless the game is a demo or a net game, the briefings
// are off, or the level has none
//
//==============================================================================
procedure RB_LevelLoaded(const epi, map: integer);

//==============================================================================
//
// RB_Active
// True while the briefing is on the screen
//
//==============================================================================
function RB_Active: boolean;

//==============================================================================
//
// RB_Ticker
//
//==============================================================================
procedure RB_Ticker;

//==============================================================================
//
// RB_Drawer
//
//==============================================================================
procedure RB_Drawer;

//==============================================================================
//
// RB_Exit
// Ends the briefing (a saved game that is loaded over it, or the pilot): the
// level starts
//
//==============================================================================
procedure RB_Exit;

implementation

uses
  SysUtils,
  d_delphi,
  doomdata,
  doomdef,
  d_event,
  d_main,
  d_player,
  g_game,
  i_system,
  m_argv,
  m_fixed,
  mn_font,
  p_setup,
  r_data,
  r_defs,
  v_data,
  v_video,
  w_wad,
  z_zone,
  radix_map_extra,
  radix_score,
  DelphiDoom.Engine.Parity.Hooks,
  DelphiDoom.Radix.Types,
  DelphiDoom.Radix.Level.Types,
  DelphiDoom.Radix.LevelLogic.Types,
  DelphiDoom.Radix.Briefing.Types,
  DelphiDoom.Radix.Briefing.Script,
  DelphiDoom.Radix.Briefing.Player;

const
  MAPX = 100;
  MAPY = 4000;
  // the flag that the translator of RADIX.DAT gives to the lines that the maps do not show
  // (ML_AUTOMAPIGNOGE of Rad-X; the engine of today gives this bit another meaning)
  RADIX_ML_AUTOMAPIGNORE = 2048;
  // a script (-autoscript, -autodemo) flies the level as a demo does: no briefing, unless asked
  BRIEFING_OPTION = '-briefing';

type
  // The map of the briefing for the commands of the script
  TBriefingMap = class(TInterfacedObject, IRadixBriefingMap)
  public
    function IsReady: Boolean;
    procedure MarkPoint(AX, AY, ARed, AGreen, ABlue: Integer);
    procedure Print(AX, AY: Integer; const AText: string);
  end;

var
  briefing: TRadixBriefingPlayer = nil;
  briefingactive: boolean = false;
  briefingfiredown: boolean = false;
  mapcreated: boolean = false;
  mapscreen: array[0..MAPY - 1] of array[0..MAPX - 1] of byte;
  mapscale: int64;
  mapleft: integer;
  maptop: integer;
  // the color of the lines between two sectors (aprox_lightblue of Rad-X)
  maplightblue: byte;

//==============================================================================
//
// RB_PointToRadix
// --- Map drawing
//
//==============================================================================
procedure RB_PointToRadix(const pl: Pline_t; const x, y: integer; var rx, ry: integer);
var
  sec: Psector_t;
  secid: integer;
begin
  sec := pl.frontsector;
  if sec = nil then
    sec := pl.backsector;
  secid := RX_SectorIndex(sec);
  if (secid < 0) or (secid >= Length(radixsectorinfo)) then
  begin
    rx := x div FRACUNIT;
    ry := y div FRACUNIT;
    exit;
  end;
  rx := radixsectorinfo[secid].XMul * (x div FRACUNIT - radixsectorinfo[secid].XAdd);
  ry := radixsectorinfo[secid].YMul * (y div FRACUNIT - radixsectorinfo[secid].YAdd);
end;

//==============================================================================
//
// RB_RadixYToMapX
//
//==============================================================================
function RB_RadixYToMapX(const x: integer): integer;
begin
  result := MAPY - Trunc((x - mapleft) / mapscale * FRACUNIT) - 1;
end;

//==============================================================================
//
// RB_RadixXToMapY
//
//==============================================================================
function RB_RadixXToMapY(const y: integer): integer;
begin
  result := Trunc((y - maptop) / mapscale * FRACUNIT);
end;

//==============================================================================
//
// RB_LineIsHidden
//
//==============================================================================
function RB_LineIsHidden(const pl: Pline_t; const lineid: integer): boolean;
begin
  result := true;
  if pl.flags and RADIX_ML_AUTOMAPIGNORE <> 0 then
    exit;
  if lineid < Length(radixwallinfo) then
    if radixwallinfo[lineid].Flags and RWF_LINEBRIEFINGIGNORE <> 0 then
      exit;
  if (pl.frontsector = nil) and (pl.backsector = nil) then
    exit;
  result := false;
end;

//==============================================================================
//
// RB_SectorIsHidden
//
//==============================================================================
function RB_SectorIsHidden(const sec: Psector_t): boolean;
var
  secid: integer;
begin
  result := false;
  if sec = nil then
    exit;
  secid := RX_SectorIndex(sec);
  if (secid >= 0) and (secid < Length(radixsectorinfo)) then
    result := radixsectorinfo[secid].Flags and RSF_HIDDEN <> 0;
end;

//==============================================================================
//
// RB_FindBoundaries
//
//==============================================================================
procedure RB_FindBoundaries;
var
  i, j: integer;
  rx, ry: integer;
  pl: Pline_t;
  min_x, min_y, max_x, max_y: integer;
  i64: int64;
begin
  min_x := MAXINT;
  min_y := MAXINT;
  max_x := -MAXINT;
  max_y := -MAXINT;

  for i := 0 to numlines - 1 do
  begin
    pl := @lines[i];
    if not RB_LineIsHidden(pl, i) then
      for j := 0 to 1 do
      begin
        if j = 0 then
          RB_PointToRadix(pl, pl.v1.x, pl.v1.y, rx, ry)
        else
          RB_PointToRadix(pl, pl.v2.x, pl.v2.y, rx, ry);
        // "else if" as in Rad-X: a point is never the smallest and the largest at once
        if rx < min_x then
          min_x := rx
        else if rx > max_x then
          max_x := rx;
        if ry < min_y then
          min_y := ry
        else if ry > max_y then
          max_y := ry;
      end;
  end;

  mapleft := min_x;
  maptop := min_y;
  i64 := int64(max_x) - min_x + 1;
  mapscale := i64 * FRACUNIT div MAPY;
  i64 := int64(max_y) - min_y + 1;
  i64 := i64 * FRACUNIT div MAPX;
  if mapscale < i64 then
    mapscale := i64;
  // a level without lines to show
  if mapscale <= 0 then
    mapscale := FRACUNIT;
end;

//==============================================================================
//
// RB_DrawLine
//
//==============================================================================
procedure RB_DrawLine(const pl: Pline_t; const lineid: integer; const twosided: boolean);
var
  x1, y1, x2, y2: integer;
  rx, ry: integer;
  x, y: integer;
  dx, dy: integer;
  sx, sy: integer;
  ax, ay: integer;
  d: integer;
  color: byte;
  sec: Psector_t;
begin
  if RB_LineIsHidden(pl, lineid) then
    exit;

  sec := pl.frontsector;
  if sec = nil then
    sec := pl.backsector;
  if RB_SectorIsHidden(sec) then
    exit;

  if twosided and (pl.flags and ML_TWOSIDED <> 0) then
  begin
    color := maplightblue;
    if (pl.frontsector <> nil) and (pl.backsector <> nil) then
      if RB_SectorIsHidden(pl.frontsector) or RB_SectorIsHidden(pl.backsector) then
        color := aprox_red;
  end
  else if not twosided and (pl.flags and ML_TWOSIDED = 0) then
    color := aprox_red
  else
    exit;

  RB_PointToRadix(pl, pl.v1.x, pl.v1.y, rx, ry);
  x1 := RB_RadixXToMapY(ry);
  y1 := RB_RadixYToMapX(rx);
  RB_PointToRadix(pl, pl.v2.x, pl.v2.y, rx, ry);
  x2 := RB_RadixXToMapY(ry);
  y2 := RB_RadixYToMapX(rx);

  dx := x2 - x1;
  ax := 2 * abs(dx);
  if dx < 0 then
    sx := -1
  else
    sx := 1;

  dy := y2 - y1;
  ay := 2 * abs(dy);
  if dy < 0 then
    sy := -1
  else
    sy := 1;

  x := x1;
  y := y1;

  if ax > ay then
  begin
    d := ay - ax div 2;
    while true do
    begin
      mapscreen[ibetween(y, 0, MAPY - 1), ibetween(x, 0, MAPX - 1)] := color;
      if x = x2 then
        exit;
      if d >= 0 then
      begin
        y := y + sy;
        d := d - ax;
      end;
      x := x + sx;
      d := d + ay;
    end;
  end
  else
  begin
    d := ax - ay div 2;
    while true do
    begin
      mapscreen[ibetween(y, 0, MAPY - 1), ibetween(x, 0, MAPX - 1)] := color;
      if y = y2 then
        exit;
      if d >= 0 then
      begin
        x := x + sx;
        d := d - ay;
      end;
      y := y + sy;
      d := d + ax;
    end;
  end;
end;

//==============================================================================
//
// RB_CreateMap
//
//==============================================================================
procedure RB_CreateMap;
var
  i: integer;
begin
  if mapcreated then
    exit;

  RB_FindBoundaries;
  maplightblue := V_FindAproxColorIndex(@curpal, $8080FF, 1, 255);

  ZeroMemory(@mapscreen, SizeOf(mapscreen));
  for i := 0 to numlines - 1 do
    RB_DrawLine(@lines[i], i, true);   // Two-sided lines first
  for i := 0 to numlines - 1 do
    RB_DrawLine(@lines[i], i, false);  // Single-sided lines

  mapcreated := true;
end;

//==============================================================================
//
// RB_DrawMap
//
//==============================================================================
procedure RB_DrawMap;
var
  dest: PByteArray;
  src: PByteArray;
  i, drow, srow: integer;
begin
  if not mapcreated then
    exit;

  for drow := 6 to 179 do
  begin
    srow := RB_RadixYToMapX(briefing.MapPosition) + drow - 87;
    if IsIntegerInRange(srow, 0, MAPY - 1) then
    begin
      src := @mapscreen[srow][0];
      dest := @screens[SCN_TMP][drow * 320 + 9];
      for i := 0 to MAPX - 1 do
        if src[i] <> 0 then
          dest[i] := src[i];
    end;
  end;
end;

{ TBriefingMap }

function TBriefingMap.IsReady: Boolean;
begin
  Result := mapcreated;
end;

procedure TBriefingMap.MarkPoint(AX, AY, ARed, AGreen, ABlue: Integer);
var
  x, y, i: integer;
  r, g, b, c: byte;
begin
  y := RB_RadixYToMapX(AX);
  x := RB_RadixXToMapY(AY);
  r := (ARed * 4 + 2) and $FF;
  g := (AGreen * 4 + 2) and $FF;
  b := (ABlue * 4 + 2) and $FF;
  c := V_FindAproxColorIndex(@curpal, b + g shl 8 + r shl 16, 1, 255);
  for i := -2 to 2 do
  begin
    mapscreen[ibetween(y + i, 0, MAPY - 1), ibetween(x + i, 0, MAPX - 1)] := c;
    mapscreen[ibetween(y + i, 0, MAPY - 1), ibetween(x - i, 0, MAPX - 1)] := c;
  end;
end;

procedure TBriefingMap.Print(AX, AY: Integer; const AText: string);
var
  x, y, i, j, w, h: integer;
  src: PByteArray;
  swidth, sheight: integer;
  mx: integer;
begin
  // the text is written on the spare screen of the status bar and its pixels go on the map
  swidth := V_GetScreenWidth(SCN_ST);
  sheight := V_ScreensSize(SCN_ST) div swidth;
  ZeroMemory(screens[SCN_ST], V_ScreensSize(SCN_ST));
  y := RB_RadixYToMapX(AX);
  x := ibetween(RB_RadixXToMapY(AY), 1, MAPX - 1);
  w := M_SmallStringWidthNarrow(AText);
  h := M_SmallStringHeight(AText);
  M_WriteSmallTextNarrow(x, 1, AText, SCN_ST);
  for i := 0 to h + 1 do
  begin
    if i >= sheight then
      break;
    src := @screens[SCN_ST][i * swidth + x - 1];
    mx := x - 1;
    for j := 0 to w + 1 do
    begin
      if (mx >= MAPX) or (x - 1 + j >= swidth) then
        break;
      mapscreen[ibetween(y + i, 0, MAPY - 1)][mx] := src[j];
      inc(mx);
    end;
  end;
end;

//==============================================================================
//
// RB_Start
// False when the level has no briefing
//
//==============================================================================
function RB_Start(const epi, map: integer): boolean;
var
  lumpname: string;
  lump: integer;
  commands: TArray<TRadixBriefingCommand>;
begin
  result := false;
  FreeAndNil(briefing);
  mapcreated := false;
  briefingfiredown := true; // the key that chose the skill, or ended the debriefing, is still down

  sprintf(lumpname, 'MissionBrief[%d][%d]', [epi, map]);
  lump := W_CheckNumForName(lumpname);
  if lump < 0 then
    exit;

  try
    commands := TRadixBriefingScript.Parse(W_TextLumpNum(lump), string(pilotname));
  except
    on e: ERadixException do
    begin
      I_Warning('RB_Start(): %s: %s'#13#10, [lumpname, e.Message]);
      exit;
    end;
  end;
  if Length(commands) = 0 then
    exit;

  briefing := TRadixBriefingPlayer.Create(commands, TBriefingMap.Create);
  result := true;
end;

//==============================================================================
//
// RB_LevelLoaded
//
//==============================================================================
procedure RB_LevelLoaded(const epi, map: integer);
begin
  briefingactive := false;
  if demoplayback or TGameSession.DemoRecording or netgame or not showbriefingscreen then
    exit;
  if (parity_hooks <> nil) and (M_CheckParm(BRIEFING_OPTION) <= 0) then
    exit;
  if not RB_Start(epi, map) then
    exit;

  briefingactive := true;
  // the ticker and the drawer of this state are the ones of Radix (radix_intermission)
  gamestate := GS_INTERMISSION;
  wipegamestate := -1; // force a wipe
end;

//==============================================================================
//
// RB_Active
//
//==============================================================================
function RB_Active: boolean;
begin
  result := briefingactive;
end;

//==============================================================================
//
// RB_Exit
//
//==============================================================================
procedure RB_Exit;
begin
  if not briefingactive then
    exit;
  briefingactive := false;
  FreeAndNil(briefing);
  wipegamestate := -1;
  gamestate := GS_LEVEL;
end;

//==============================================================================
//
// RB_Ticker
//
//==============================================================================
procedure RB_Ticker;
var
  i: integer;
  down, acts: boolean;
begin
  if not briefingactive then
    exit;

  RB_CreateMap;

  // fire or use: once for every press
  down := false;
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
      if players[i].cmd.buttons and (BT_ATTACK or BT_USE) <> 0 then
        down := true;
  acts := down and not briefingfiredown;
  briefingfiredown := down;

  if briefing.Finished then
  begin
    if acts then
      RB_Exit;
    exit;
  end;

  briefing.Tick(acts);
end;

//==============================================================================
//
// RB_DrawFrame
//
//==============================================================================
procedure RB_DrawFrame(const bx, by, bw, bh: integer);
var
  p: Ppatch_t;
  x, y, pix: integer;
  cmap: PByteArray;

  function Border(const name: string): Ppatch_t;
  var
    lump: integer;
  begin
    lump := W_CheckNumForName(name);
    if lump < 0 then
      result := nil
    else
      result := W_CacheLumpNum(lump, PU_CACHE);
  end;

begin
  cmap := @def_colormaps[(NUMCOLORMAPS div 2) * 256];
  for y := by to by + bh do
    for x := bx to bx + bw do
    begin
      pix := y * 320 + x;
      screens[SCN_TMP][pix] := cmap[screens[SCN_TMP][pix]];
    end;

  p := Border('brdr_t');
  if p <> nil then
  begin
    x := bx;
    while x < bx + bw do
    begin
      if x + p.width > bx + bw then
        x := bx + bw - p.width;
      V_DrawPatch(x, by, SCN_TMP, p, false);
      x := x + 8;
    end;
  end;

  p := Border('brdr_b');
  if p <> nil then
  begin
    x := bx;
    while x < bx + bw do
    begin
      if x + p.width > bx + bw then
        x := bx + bw - p.width;
      V_DrawPatch(x, by + bh, SCN_TMP, p, false);
      x := x + 8;
    end;
  end;

  p := Border('brdr_l');
  if p <> nil then
  begin
    y := by;
    while y < by + bh do
    begin
      if y + p.height > by + bh then
        y := by + bh - p.height;
      V_DrawPatch(bx, y, SCN_TMP, p, false);
      y := y + 8;
    end;
  end;

  p := Border('brdr_r');
  if p <> nil then
  begin
    y := by;
    while y < by + bh do
    begin
      if y + p.height > by + bh then
        y := by + bh - p.height;
      V_DrawPatch(bx + bw, y, SCN_TMP, p, false);
      y := y + 8;
    end;
  end;

  // Draw beveled edge.
  p := Border('brdr_tl');
  if p <> nil then
    V_DrawPatch(bx, by, SCN_TMP, p, false);
  p := Border('brdr_tr');
  if p <> nil then
    V_DrawPatch(bx + bw, by, SCN_TMP, p, false);
  p := Border('brdr_bl');
  if p <> nil then
    V_DrawPatch(bx, by + bh, SCN_TMP, p, false);
  p := Border('brdr_br');
  if p <> nil then
    V_DrawPatch(bx + bw, by + bh, SCN_TMP, p, false);
end;

//==============================================================================
//
// RB_DrawPictureHalf
// A picture of the animation window. Rad-X drew it on a 640x400 screen with its
// middle at (448, 84); the screens here are 320x200: one pixel out of four
//
//==============================================================================
procedure RB_DrawPictureHalf(const name: string);
const
  CENTER_X = 448;
  CENTER_Y = 84;
var
  lump: integer;
  p: Ppatch_t;
  col, x, y, top, lasttop: integer;
  post: PByteArray;
  i, len: integer;
begin
  lump := W_CheckNumForName(name);
  if lump < 0 then
    exit;
  p := W_CacheLumpNum(lump, PU_CACHE);

  col := 0;
  while col < p.width do
  begin
    x := (CENTER_X - p.leftoffset + col) div 2;
    if (x >= 0) and (x < 320) then
    begin
      post := PByteArray(NativeInt(p) + p.columnofs[col]);
      lasttop := -1;
      while post[0] <> $FF do
      begin
        // a tall patch gives the top of a post from the one before
        top := post[0];
        if top <= lasttop then
          top := lasttop + top;
        lasttop := top;
        len := post[1];
        for i := 0 to len - 1 do
          if not odd(top + i) then
          begin
            y := (CENTER_Y - p.height div 2 + top + i) div 2;
            if (y >= 0) and (y < 200) then
              screens[SCN_TMP][y * 320 + x] := post[3 + i];
          end;
        post := @post[len + 4];
      end;
    end;
    inc(col, 2);
  end;
end;

//==============================================================================
//
// RB_Drawer
//
//==============================================================================
procedure RB_Drawer;
begin
  if not briefingactive then
    exit;

  if W_CheckNumForName('BACKIMG') >= 0 then
    V_DrawPatchFullScreenTMP320x200('BACKIMG')
  else
    ZeroMemory(screens[SCN_TMP], 320 * 200);

  RB_DrawFrame(2, 2, 110, 178);
  RB_DrawMap;
  RB_DrawFrame(136, 2, 170, 80);
  RB_DrawFrame(136, 94, 170, 86);
  if briefing.Picture <> '' then
    RB_DrawPictureHalf(briefing.Picture);
  M_WriteSmallTextNarrow(140, 100, briefing.Message, SCN_TMP);
  if briefing.Finished then
    M_WriteSmallWhiteTextCenter(189, 'PRESS "CTRL" OR "SPACE" TO PLAY', SCN_TMP)
  else
    M_WriteSmallWhiteTextCenter(189, 'PRESS "CTRL" OR "SPACE" TO CONTINUE', SCN_TMP);

  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);

  V_FullScreenStretch;
end;

initialization

finalization
  briefing.Free;

end.
