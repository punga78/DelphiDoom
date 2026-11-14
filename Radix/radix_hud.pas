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
//  Radix: status bar, cockpit and small HUD of the craft (radix_hud of Rad-X).
//  The numbers of the instruments are TRadixHudGauges (Libs\Radix); here there
//  is only the drawing. ST_ConfigureReplacement (st_stuff) puts RX_HudDrawer in
//  the place of the status bar of Doom.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit radix_hud;

interface

//==============================================================================
//
// RX_InitRadixHud
// Loads the pictures. Idempotent: the first drawing calls it
//
//==============================================================================
procedure RX_InitRadixHud;

//==============================================================================
//
// RX_HudDrawer
// Draws the display of the craft of the console player over the view
//
//==============================================================================
procedure RX_HudDrawer;

var
  radix_drawcrosshair: boolean = true;
  radix_drawkeybar: boolean = true;

implementation

uses
  d_delphi,
  doomdef,
  am_map,
  d_net,
  d_player,
  d_items,
  g_game,
  mn_font,
  m_fixed,
  tables,
  p_local,
  p_maputl,
  p_mobj_h,
  p_setup,
  p_tick,
  r_defs,
  r_main,
  v_data,
  v_video,
  w_wad,
  z_zone,
  radix_playerstate,
  DelphiDoom.Radix.Hud.Gauges;

const
  STATUSBAR_HEIGHT = 41;
  SCN_HUD = SCN_TMP; // 320x200, drawn again at every frame
  HUD_WIDTH = 320;
  HUD_HEIGHT = 200;
  COCKPIT_UP_PART = 120;
  MAXRADARTHINGS = 256;
  S_PRESS_SPACE_RESTART = 'PRESS SPACE'#13#10'TO RESTART LEVEL';

type
  speedindicatorcolumn_t = packed array[0..6] of byte;
  Pspeedindicatorcolumn_t = ^speedindicatorcolumn_t;

  radarlist_t = record
    count: integer;
    things: array[0..MAXRADARTHINGS - 1] of Pmobj_t;
  end;

const
  statusbarspeed: speedindicatorcolumn_t = (244, 241, 236, 239, 242, 244, 247);

  weaponxlatpos: array[0..8] of integer = (0, 1, 2, 3, 4, 5, 6, 1, 1);

var
  hud_initialized: boolean = false;
  radar_list: radarlist_t;
  radar_friendlist: radarlist_t;
  cockpitspeed: speedindicatorcolumn_t;
  cockpit: Ppatch_t;
  statusbarimage: Ppatch_t;
  weaponimages: array[0..8] of Ppatch_t;
  WeaponNumOn: array[0..8] of Ppatch_t;
  WeaponNumOff: array[0..8] of Ppatch_t;
  WeaponNumUse: array[0..8] of Ppatch_t;
  treatimages: array[boolean] of Ppatch_t;
  ArmourBar: Ppatch_t;
  ShieldBar: Ppatch_t;
  EnergyBar: Ppatch_t;
  hud_player: Pplayer_t;
  hud_radix: Pradixplayer_t;
  statammo: array[0..3] of Ppatch_t;
  PowerUpIcons: array[0..4] of Ppatch_t;
  PlasmaIcon: Ppatch_t;
  crosshairs: array[0..6] of Ppatch_t;
  ckeybar: Ppatch_t;
  skeybar: Ppatch_t;
  stkeys: array[0..Ord(NUMCARDS) - 1] of Ppatch_t;
  hud_black: byte;
  hud_blue: byte;
  hud_yellow: byte;
  hud_lightblue: byte;

//==============================================================================
//
// RX_HudPatch
// A picture of RADIX.DAT by its long name (the aliases of RADIXINF find the lump)
//
//==============================================================================
function RX_HudPatch(const name: string): Ppatch_t;
begin
  result := W_CacheLumpName(name, PU_STATIC);
end;

//==============================================================================
//
// RX_InitRadixHud
//
//==============================================================================
procedure RX_InitRadixHud;
var
  i: integer;
  playpal: PByteArray;
  cpal: array[0..255] of LongWord;
begin
  if hud_initialized then
    exit;
  hud_initialized := true;

  playpal := W_CacheLumpName('PLAYPAL', PU_STATIC);
  for i := 0 to 255 do
    cpal[i] := (LongWord(playpal[i * 3]) shl 16) or (LongWord(playpal[i * 3 + 1]) shl 8) or playpal[i * 3 + 2];
  Z_ChangeTag(playpal, PU_CACHE);
  hud_black := V_FindAproxColorIndex(@cpal, $0, 1, 255);
  hud_blue := V_FindAproxColorIndex(@cpal, $80, 1, 255);
  hud_yellow := V_FindAproxColorIndex(@cpal, $FFFF00, 1, 255);
  hud_lightblue := V_FindAproxColorIndex(@cpal, $FF, 1, 255);
  for i := 0 to 6 do
    cockpitspeed[i] := hud_black;

  cockpit := RX_HudPatch('COCKPIT');
  statusbarimage := RX_HudPatch('StatusBarImage');
  for i := 0 to 6 do
  begin
    weaponimages[i] := RX_HudPatch('Weapon' + itoa(i + 1) + 'Image');
    WeaponNumOn[i] := RX_HudPatch('WeaponNumOn' + itoa(i + 1));
    WeaponNumOff[i] := RX_HudPatch('WeaponNumOff' + itoa(i + 1));
    WeaponNumUse[i] := RX_HudPatch('WeaponNumUse' + itoa(i + 1));
  end;
  weaponimages[7] := RX_HudPatch('EnhancedEPCWeaponPicture');
  weaponimages[8] := RX_HudPatch('SuperEPCWeaponPicture');
  for i := 7 to 8 do
  begin
    WeaponNumOn[i] := WeaponNumOn[1];
    WeaponNumOff[i] := WeaponNumOff[1];
    WeaponNumUse[i] := WeaponNumUse[1];
  end;
  treatimages[true] := RX_HudPatch('ThreatOnMap');
  treatimages[false] := RX_HudPatch('ThreatOffMap');
  ArmourBar := RX_HudPatch('ArmourBar');
  ShieldBar := RX_HudPatch('ShieldBar');
  EnergyBar := RX_HudPatch('EnergyBar');
  statammo[0] := RX_HudPatch('StatAmmo1');
  statammo[1] := RX_HudPatch('StatAmmo4');
  statammo[2] := RX_HudPatch('StatAmmo2');
  statammo[3] := RX_HudPatch('StatAmmo3');
  for i := 0 to 4 do
    PowerUpIcons[i] := RX_HudPatch('PowerUpIcon[' + itoa(i + 1) + ']');
  PlasmaIcon := RX_HudPatch('PlasmaIcon');
  crosshairs[0] := RX_HudPatch('CrossHair');
  for i := 1 to 6 do
    crosshairs[i] := RX_HudPatch('CrossLock' + itoa(i));
  ckeybar := RX_HudPatch('CKEYBAR');
  skeybar := RX_HudPatch('SKEYBAR');
  for i := 0 to Ord(NUMCARDS) - 1 do
    stkeys[i] := RX_HudPatch('STKEYS' + itoa(i));
end;

//==============================================================================
//
// RX_HudPutPixel
//
//==============================================================================
procedure RX_HudPutPixel(const x, y: integer; const color: byte);
begin
  if (x >= 0) and (x < HUD_WIDTH) and (y >= 0) and (y < HUD_HEIGHT) then
    screens[SCN_HUD][y * HUD_WIDTH + x] := color;
end;

//==============================================================================
//
// RX_HudDrawPatchStencil
// Draws a patch only over what has already been drawn (V_DrawPatchStencil of
// Rad-X with the stencil 0: the empty pixels of the HUD screen stay empty)
//
//==============================================================================
procedure RX_HudDrawPatchStencil(x, y: integer; const patch: Ppatch_t);
var
  col: integer;
  column: Pcolumn_t;
  source: PByte;
  count: integer;
  yy: integer;
  dest: PByte;
begin
  y := y - patch.topoffset;
  x := x - patch.leftoffset;
  for col := 0 to patch.width - 1 do
  begin
    if (x + col < 0) or (x + col >= HUD_WIDTH) then
      continue;
    column := Pcolumn_t(NativeUInt(patch) + NativeUInt(patch.columnofs[col]));
    while column.topdelta <> $ff do
    begin
      source := PByte(NativeUInt(column) + 3);
      yy := y + column.topdelta;
      count := column.length;
      while count > 0 do
      begin
        if (yy >= 0) and (yy < HUD_HEIGHT) then
        begin
          dest := @screens[SCN_HUD][yy * HUD_WIDTH + x + col];
          if dest^ <> 0 then
            dest^ := source^;
        end;
        inc(source);
        inc(yy);
        dec(count);
      end;
      column := Pcolumn_t(NativeUInt(column) + NativeUInt(column.length) + 4);
    end;
  end;
end;

//==============================================================================
//
// RX_HudDrawTime
//
//==============================================================================
procedure RX_HudDrawTime(const x, y: integer);
var
  clock: TRadixHudClock;
begin
  clock := TRadixHudGauges.Clock(leveltime);
  if clock.Overflow then
    M_WriteSmallText(x, y, 'SUCKS', SCN_HUD) // JVAL 20200316 - SUCKS easter egg
  else
  begin
    M_WriteSmallText(x, y, IntToStrZfill(2, clock.Minutes) + ':', SCN_HUD);
    M_WriteSmallText(x + 14, y, IntToStrZfill(2, clock.Seconds), SCN_HUD);
  end;
end;

//==============================================================================
//
// RX_HudDrawSpeedIndicator
//
//==============================================================================
procedure RX_HudDrawSpeedIndicator(const x, y: integer; const column: Pspeedindicatorcolumn_t; const up: boolean);
var
  bars: TRadixSpeedBars;
  i, j: integer;
  xpos: integer;
begin
  if hud_player.mo = nil then
    exit;
  bars := TRadixHudGauges.SpeedBars(hud_player.mo.momx, hud_player.mo.momy, hud_player.mo.momz, up);
  xpos := x;
  for i := 0 to bars.Count - 1 do
  begin
    for j := 0 to 6 do
      RX_HudPutPixel(xpos, y + j, column[j]);
    xpos := xpos + bars.Step;
  end;
end;

//==============================================================================
//
// PIT_AddRadarThing
//
//==============================================================================
function PIT_AddRadarThing(thing: Pmobj_t): boolean;
begin
  if thing.health > 0 then
  begin
    if thing.flags2_ex and MF2_EX_FRIEND <> 0 then
    begin
      if radar_friendlist.count < MAXRADARTHINGS then
      begin
        radar_friendlist.things[radar_friendlist.count] := thing;
        inc(radar_friendlist.count);
      end;
    end
    else if thing.flags and MF_COUNTKILL <> 0 then
    begin
      if radar_list.count < MAXRADARTHINGS then
      begin
        radar_list.things[radar_list.count] := thing;
        inc(radar_list.count);
      end;
    end;
  end;
  result := true;
end;

//==============================================================================
//
// RX_HudReplaceColor
//
//==============================================================================
procedure RX_HudReplaceColor(const x1, y1, x2, y2: integer; const oldcolor, newcolor: byte);
var
  i, j: integer;
  pb: PByte;
begin
  for j := y1 to y2 do
    if (j >= 0) and (j < HUD_HEIGHT) then
      for i := x1 to x2 do
        if (i >= 0) and (i < HUD_WIDTH) then
        begin
          pb := @screens[SCN_HUD][j * HUD_WIDTH + i];
          if pb^ = oldcolor then
            pb^ := newcolor;
        end;
end;

//==============================================================================
//
// RX_DrawRadar
//
//==============================================================================
procedure RX_DrawRadar(const x, y: integer; const range: integer);
var
  r: int64;
  xl, xh, yl, yh: integer;
  bx, by: integer;
  newcolor: byte;
  an: angle_t;
  asin, acos: fixed_t;
  mo: Pmobj_t;

  procedure _draw_list(const lst: radarlist_t; const color: byte);
  var
    i: integer;
    dx, dy: integer;
  begin
    for i := 0 to lst.count - 1 do
      if TRadixHudGauges.RadarOffset(mo.x, mo.y, lst.things[i].x, lst.things[i].y, asin, acos, range, dx, dy) then
        RX_HudPutPixel(x + dx, y + dy, color);
  end;

begin
  mo := hud_player.mo;
  if mo = nil then
    exit;

  if TRadixHudGauges.RadarJammed(hud_player.playerstate = PST_DEAD, hud_radix.scannerjam, leveltime) then
  begin
    RX_HudReplaceColor(x - range - 1, y - range, x + range + 1, y + range,
      TRadixHudGauges.RADAR_BASE_COLOR, TRadixHudGauges.RADAR_JAMMED_COLOR);
    exit;
  end;

  // JVAL: 20200424 - Radar glow effect
  newcolor := TRadixHudGauges.RadarGlowColor(leveltime);
  if newcolor <> TRadixHudGauges.RADAR_BASE_COLOR then
    RX_HudReplaceColor(x - range - 1, y - range, x + range + 1, y + range,
      TRadixHudGauges.RADAR_BASE_COLOR, newcolor);

  r := range * 128 * FRACUNIT;
  xl := MapBlockIntX(int64(mo.x) - r - int64(bmaporgx));
  xh := MapBlockIntX(int64(mo.x) + r - int64(bmaporgx));
  yl := MapBlockIntY(int64(mo.y) - r - int64(bmaporgy));
  yh := MapBlockIntY(int64(mo.y) + r - int64(bmaporgy));

  radar_list.count := 0;
  radar_friendlist.count := 0;
  for bx := xl to xh do
    for by := yl to yh do
      P_BlockThingsIterator(bx, by, PIT_AddRadarThing);

  RX_HudPutPixel(x, y, hud_blue);

  an := (ANG90 - mo.angle) div FRACUNIT;
  asin := fixedsine[an];
  acos := fixedcosine[an];
  _draw_list(radar_friendlist, hud_lightblue);
  _draw_list(radar_list, hud_yellow);
end;

//==============================================================================
//
// RX_HudDrawBar
//
//==============================================================================
procedure RX_HudDrawBar(const x, y: integer; const bar: Ppatch_t; const pct: integer);
var
  i, j: integer;
  fill: integer;
  b: byte;
begin
  fill := TRadixHudGauges.BarFill(bar.width, pct);
  if fill = 0 then
    exit;

  b := screens[SCN_HUD][HUD_WIDTH * y + x]; // JVAL: 20200316 - Keep background color
  V_DrawPatch(x, y, SCN_HUD, bar, false);

  // Fill with background color:
  for j := y to y + bar.height - 1 do
    for i := fill to bar.width - 1 do
      RX_HudPutPixel(x + i, j, b);
end;

//==============================================================================
//
// RX_HudDrawPowerUpIcons
//
//==============================================================================
procedure RX_HudDrawPowerUpIcons;
begin
  // Rapid shield icon
  if TRadixHudGauges.PowerUpVisible(hud_radix.radixpowers[Ord(rpu_rapidshield)]) then
    V_DrawPatch(300, 22, SCN_HUD, PowerUpIcons[0], false);

  // Rapid energy icon
  if TRadixHudGauges.PowerUpVisible(hud_radix.radixpowers[Ord(rpu_rapidenergy)]) then
    V_DrawPatch(300, 42, SCN_HUD, PowerUpIcons[1], false);

  // Maneuver jets icon
  if TRadixHudGauges.PowerUpVisible(hud_radix.radixpowers[Ord(rpu_maneuverjets)]) then
    V_DrawPatch(300, 62, SCN_HUD, PowerUpIcons[2], false);

  // Ultra shields icon
  if hud_player.health > PLAYERSPAWNSHIELD then
    V_DrawPatch(300, 82, SCN_HUD, PowerUpIcons[3], false);

  // ALDS icon
  if TRadixHudGauges.PowerUpVisible(hud_radix.radixpowers[Ord(rpu_alds)]) then
    V_DrawPatch(300, 102, SCN_HUD, PowerUpIcons[4], false);
end;

//==============================================================================
//
// RX_HudDrawPlasmaBall
//
//==============================================================================
procedure RX_HudDrawPlasmaBall;
begin
  V_DrawPatch(282, 0, SCN_HUD, PlasmaIcon, false);
  M_WriteSmallText(305, 4, IntToStrZfill(2, hud_radix.plasmabombs), SCN_HUD);
end;

//==============================================================================
//
// RX_HudDrawRestartMessage
//
//==============================================================================
procedure RX_HudDrawRestartMessage;
begin
  if hud_player.playerstate = PST_DEAD then
    M_WriteSmallTextCenter(76, S_PRESS_SPACE_RESTART, SCN_HUD);
end;

//==============================================================================
//
// RX_HudDrawCrossHair
//
//==============================================================================
procedure RX_HudDrawCrossHair(const withstatusbar: boolean);
var
  p: Ppatch_t;
begin
  if not radix_drawcrosshair then
    exit;

  if amstate = am_only then
    exit;

  if hud_player.playerstate = PST_DEAD then
    exit;

  p := crosshairs[TRadixHudGauges.CrossHairIndex(hud_radix.plinetarget <> nil, leveltime, hud_radix.pcrosstic)];
  if withstatusbar then
    V_DrawPatch(160 - p.width div 2, 100 - (STATUSBAR_HEIGHT + p.height) div 2, SCN_HUD, p, false)
  else
    V_DrawPatch(160 - p.width div 2, 100 - p.height div 2, SCN_HUD, p, false);
end;

//==============================================================================
//
// RX_HudDrawKeys
//
//==============================================================================
procedure RX_HudDrawKeys(const x, y: integer; const kbar: Ppatch_t);
var
  i: integer;
begin
  if not radix_drawkeybar then
    exit;

  V_DrawPatch(x, y, SCN_HUD, kbar, false);
  for i := 0 to Ord(NUMCARDS) - 1 do
    if hud_player.cards[i] then
      V_DrawPatch(x + i * 8 + 2, y + 2, SCN_HUD, stkeys[i], false);
end;

//==============================================================================
//
// RX_HudReadyWeapon
//
//==============================================================================
function RX_HudReadyWeapon: integer;
begin
  result := Ord(hud_player.readyweapon);
  if (result < 0) or (result > 8) then
    result := 0;
end;

//==============================================================================
//
// RX_HudDrawKills
//
//==============================================================================
procedure RX_HudDrawKills(const x1, x2, y: integer);
begin
  M_WriteSmallText(x1, y, IntToStrZfill(3, GetIntegerInRange(hud_player.killcount, 0, 999)), SCN_HUD);
  M_WriteSmallText(x2, y, IntToStrZfill(3, GetIntegerInRange(totalkills, 0, 999)), SCN_HUD);
end;

//==============================================================================
//
// RX_HudDrawWeaponLevel
// The level of the neutron cannons or of the spreader beside the ready weapon
//
//==============================================================================
procedure RX_HudDrawWeaponLevel(const x, y: integer);
var
  level: integer;
begin
  if RX_HudReadyWeapon = Ord(rwp_neutroncannons) then
    level := hud_radix.neutroncannonlevel
  else if RX_HudReadyWeapon = Ord(rwp_plasmaspreader) then
    level := hud_radix.neutronspreaderlevel
  else
    exit;
  level := GetIntegerInRange(level, 0, MAXNEUTRONCANNONLEVEL - 1);
  V_DrawPatch(x, y, SCN_HUD, WeaponNumUse[neutronfirelevel[level]], false);
end;

//==============================================================================
//
// RX_HudDrawerStatusbar
//
//==============================================================================
procedure RX_HudDrawerStatusbar;
const
  SB_Y = 200 - STATUSBAR_HEIGHT;
var
  p: Ppatch_t;
  i: integer;
begin
  // Draw statusbar
  V_DrawPatch(0, SB_Y, SCN_HUD, statusbarimage, false);

  // Draw ready weapon
  V_DrawPatch(5, SB_Y + 4, SCN_HUD, weaponimages[RX_HudReadyWeapon], false);
  RX_HudDrawWeaponLevel(60, SB_Y + 4);

  // Draw weapon indicators
  for i := 0 to 8 do
  begin
    if Ord(hud_player.readyweapon) = i then
      p := WeaponNumUse[i]
    else if i > 6 then
      continue
    else if hud_player.weaponowned[i] <> 0 then
      p := WeaponNumOn[i]
    else
      p := WeaponNumOff[i];
    V_DrawPatch(6 + weaponxlatpos[i] * 8, SB_Y + 31, SCN_HUD, p, false);
  end;

  // Draw kills
  RX_HudDrawKills(204, 227, SB_Y + 30);

  // Draw threat indicator
  V_DrawPatch(290, SB_Y + 16, SCN_HUD, treatimages[TRadixHudGauges.ThreatLit(hud_radix.threat, leveltime)], false);

  // Draw armor, shield and energy bars
  RX_HudDrawBar(189, SB_Y + 7, ArmourBar, hud_player.armorpoints);
  RX_HudDrawBar(189, SB_Y + 14, ShieldBar, hud_player.health);
  RX_HudDrawBar(189, SB_Y + 21, EnergyBar, hud_radix.energy);

  // Draw time
  RX_HudDrawTime(93, SB_Y + 30);

  // Draw speed indicator
  RX_HudDrawSpeedIndicator(128, SB_Y + 30, @statusbarspeed, true);

  // Draw radar
  RX_DrawRadar(269, SB_Y + 19, 12);

  // Draw ammo
  M_WriteSmallText(96, SB_Y + 8, itoa(hud_player.ammo[0]), SCN_HUD);
  M_WriteSmallText(145, SB_Y + 8, itoa(hud_player.ammo[1]), SCN_HUD);
  M_WriteSmallText(96, SB_Y + 19, itoa(hud_player.ammo[2]), SCN_HUD);
  M_WriteSmallText(145, SB_Y + 19, itoa(hud_player.ammo[3]), SCN_HUD);
  case Ord(weaponinfo[RX_HudReadyWeapon].ammo) of
    0: V_DrawPatch(75, SB_Y + 8, SCN_HUD, statammo[0], false);
    1: V_DrawPatch(124, SB_Y + 8, SCN_HUD, statammo[1], false);
    2: V_DrawPatch(75, SB_Y + 19, SCN_HUD, statammo[2], false);
    3: V_DrawPatch(124, SB_Y + 19, SCN_HUD, statammo[3], false);
  end;

  // Draw power up icons
  RX_HudDrawPowerUpIcons;

  // Draw plasma balls
  RX_HudDrawPlasmaBall;

  // Gravity wave shots left
  if RX_HudReadyWeapon = Ord(rwp_gravitywave) then
    M_WriteSmallText(55, SB_Y + 16, IntToStrZfill(2, hud_radix.gravitywave), SCN_HUD);

  // Draw restart message if the player is dead
  RX_HudDrawRestartMessage;

  // Draw crosshair
  RX_HudDrawCrossHair(true);

  // Draw keycards
  RX_HudDrawKeys(11, 151, skeybar);
end;

//==============================================================================
//
// RX_HudDrawerCockpit
//
//==============================================================================
procedure RX_HudDrawerCockpit(const full: boolean);
var
  p: Ppatch_t;
  i: integer;
begin
  // Draw cockpit
  V_DrawPatch(0, 0, SCN_HUD, cockpit, false);
  if not full then
    ZeroMemory(screens[SCN_HUD], HUD_WIDTH * COCKPIT_UP_PART);

  // Draw ready weapon
  V_DrawPatch(23, 142, SCN_HUD, weaponimages[RX_HudReadyWeapon], false);
  RX_HudDrawWeaponLevel(78, 142);

  // Draw weapon indicators
  for i := 0 to 8 do
  begin
    if Ord(hud_player.readyweapon) = i then
      p := WeaponNumUse[i]
    else if (i <= 6) and (hud_player.weaponowned[i] <> 0) then
      p := WeaponNumOn[i]
    else
      continue; // Already in cockpit patch
    RX_HudDrawPatchStencil(26 + weaponxlatpos[i] * 8, 162, p);
  end;

  // Draw kills
  RX_HudDrawKills(145, 168, 141);

  // Draw threat indicator
  if full then
    V_DrawPatch(147, 23, SCN_HUD, treatimages[TRadixHudGauges.ThreatLit(hud_radix.threat, leveltime)], false);

  // Draw armor, shield and energy bars
  RX_HudDrawBar(202, 156, ArmourBar, hud_player.armorpoints);
  RX_HudDrawBar(202, 171, ShieldBar, hud_player.health);
  RX_HudDrawBar(233, 186, EnergyBar, hud_radix.energy);

  // Draw time
  RX_HudDrawTime(107, 183);

  // Draw speed indicator
  RX_HudDrawSpeedIndicator(136, 148, @cockpitspeed, false);

  // Draw radar
  RX_DrawRadar(163, 171, 15);

  // Draw ammo
  M_WriteSmallText(31, 174, itoa(hud_player.ammo[0]), SCN_HUD);
  M_WriteSmallText(74, 174, itoa(hud_player.ammo[1]), SCN_HUD);
  M_WriteSmallText(31, 185, itoa(hud_player.ammo[2]), SCN_HUD);
  M_WriteSmallText(74, 185, itoa(hud_player.ammo[3]), SCN_HUD);
  case Ord(weaponinfo[RX_HudReadyWeapon].ammo) of
    0: RX_HudDrawPatchStencil(10, 174, statammo[0]);
    1: RX_HudDrawPatchStencil(53, 174, statammo[1]);
    2: RX_HudDrawPatchStencil(10, 185, statammo[2]);
    3: RX_HudDrawPatchStencil(54, 185, statammo[3]);
  end;

  // Draw power up icons
  RX_HudDrawPowerUpIcons;

  // Draw plasma balls
  RX_HudDrawPlasmaBall;

  // Gravity wave shots left
  if RX_HudReadyWeapon = Ord(rwp_gravitywave) then
    M_WriteSmallText(73, 154, IntToStrZfill(2, hud_radix.gravitywave), SCN_HUD);

  // Draw restart message if the player is dead
  RX_HudDrawRestartMessage;

  // Draw crosshair
  RX_HudDrawCrossHair(false);

  // Draw keycards
  RX_HudDrawKeys(204, 134, ckeybar);
end;

//==============================================================================
//
// RX_HudDrawerSmall
//
//==============================================================================
procedure RX_HudDrawerSmall;
begin
  // Draw armor, shield and energy bars
  RX_HudDrawBar(2, 200 - 21, ArmourBar, hud_player.armorpoints);
  RX_HudDrawBar(2, 200 - 14, ShieldBar, hud_player.health);
  RX_HudDrawBar(2, 200 - 7, EnergyBar, hud_radix.energy);

  // Draw power up icons
  RX_HudDrawPowerUpIcons;

  // Draw plasma balls
  RX_HudDrawPlasmaBall;

  // Draw restart message if the player is dead
  RX_HudDrawRestartMessage;

  // Draw crosshair
  RX_HudDrawCrossHair(false);
end;

//==============================================================================
//
// RX_HudDrawer
//
//==============================================================================
procedure RX_HudDrawer;
var
  mode: TRadixHudMode;
begin
  hud_player := @players[consoleplayer];
  hud_radix := RX_PlayerState(hud_player);

  mode := TRadixHudGauges.Mode(screenblocks, amstate = am_only, hud_player.playerstate = PST_DEAD);
  if mode = rhmNone then
    exit;

  RX_InitRadixHud;

  // SCN_HUD is the temporary screen of the engine (others draw on it between two frames): the
  // display is drawn again at every frame, not only at the first one of an interpolation
  ZeroMemory(screens[SCN_HUD], HUD_WIDTH * HUD_HEIGHT);
  case mode of
    rhmRestartOnly: RX_HudDrawRestartMessage;
    rhmCockpit: RX_HudDrawerCockpit(true);
    rhmHalfCockpit: RX_HudDrawerCockpit(false);
    rhmSmall: RX_HudDrawerSmall;
  else
    RX_HudDrawerStatusbar;
  end;

  V_CopyRectTransparent(0, 0, SCN_HUD, HUD_WIDTH, HUD_HEIGHT, 0, 0, SCN_FG, true);
end;

end.
