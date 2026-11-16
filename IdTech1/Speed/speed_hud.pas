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
//  Speed Haste: the display of the race (speed_hud of the fork): the rev
//  gauge with the speed and the gear, the lap, the position, the time of the
//  race, the numbers of the start and the picture of the result.
//  ST_ConfigureReplacement (st_stuff) puts SH_HudDrawer in the place of the
//  status bar of Doom (the fork had emptied it).
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit speed_hud;

interface

//==============================================================================
//
// SH_HudDrawer
// Draws the display of the car of the console player over the view
//
//==============================================================================
procedure SH_HudDrawer;

implementation

uses
  SysUtils,
  d_delphi,
  doomdef,
  g_game,
  m_fixed,
  p_tick,
  r_defs,
  v_data,
  v_video,
  w_wad,
  z_zone,
  speed_race,
  speed_text,
  DelphiDoom.Racing.Types,
  DelphiDoom.Racing.Intf,
  DelphiDoom.Racing.TextFormat,
  DelphiDoom.Engine.Speed.RaceEvents;

const
  SCN_HUD = SCN_TMP; // 320x200, drawn again at every frame
  HUD_WIDTH = 320;
  HUD_HEIGHT = 200;
  // how long the number of the start stays on the screen (the states of MT_RACESTART: 37 tics)
  COUNTDOWN_TICS = 36;
  FINAL_LAP_TICS = 105;
  // where the gauge sits (its top left corner) and where the needle turns
  GAUGE_X = 250;
  GAUGE_Y = 138;
  GAUGE_CENTER_X = 32;
  GAUGE_CENTER_Y = 29;
  GAUGE_RADIUS = 22;
  // the needle goes round three quarters of a circle: 0 rpm at the lower left, the maximum at the lower right
  GAUGE_START_DEGREES = 225;
  GAUGE_SWEEP_DEGREES = 270;
  NEEDLE_COLOR_RGB = $0000FF;

var
  hud_loaded: boolean = false;
  hud_gauge: Ppatch_t;
  hud_digits: array[0..9] of Ppatch_t;
  hud_gearmarks: array[0..7] of Ppatch_t;
  hud_gearcolumn: Ppatch_t;
  hud_labellap: Ppatch_t;
  hud_labelpos: Ppatch_t;
  hud_labeltime: Ppatch_t;
  hud_positions: array[0..4] of Ppatch_t;
  hud_countdown: array[0..3] of Ppatch_t;
  hud_finallap: Ppatch_t;
  hud_youwin: Ppatch_t;
  hud_gameover: Ppatch_t;
  hud_needlecolor: byte;

//==============================================================================
//
// SH_HudPatch
// A picture of the game by its name, nil when the data do not have it
//
//==============================================================================
function SH_HudPatch(const name: string): Ppatch_t;
var
  lump: integer;
begin
  lump := W_CheckNumForName(name);
  if lump < 0 then
    Result := nil
  else
    Result := W_CacheLumpNum(lump, PU_STATIC);
end;

//==============================================================================
//
// SH_HudNearestColor
// The index of the palette of the game that is nearest to a color
//
//==============================================================================
function SH_HudNearestColor(const rgb: integer): byte;
var
  pal: PByteArray;
  i, best, dist, r, g, b: integer;
begin
  Result := 0;
  pal := W_CacheLumpName('PLAYPAL', PU_STATIC);
  best := MAXINT;
  r := rgb and $FF;
  g := (rgb shr 8) and $FF;
  b := (rgb shr 16) and $FF;
  for i := 16 to 239 do
  begin
    dist := (r - pal[i * 3]) * (r - pal[i * 3]) + (g - pal[i * 3 + 1]) * (g - pal[i * 3 + 1]) +
      (b - pal[i * 3 + 2]) * (b - pal[i * 3 + 2]);
    if dist < best then
    begin
      best := dist;
      Result := i;
    end;
  end;
end;

//==============================================================================
//
// SH_HudLoad
//
//==============================================================================
procedure SH_HudLoad;
var
  i: integer;
begin
  hud_loaded := true;
  hud_gauge := SH_HudPatch('MREVO1');
  for i := 0 to 9 do
    hud_digits[i] := SH_HudPatch('MFMW' + IntToStr(i));
  for i := 0 to 7 do
    hud_gearmarks[i] := SH_HudPatch('MG' + IntToStr(i));
  hud_gearcolumn := SH_HudPatch('MGEAR');
  hud_labellap := SH_HudPatch('MLAP');
  hud_labelpos := SH_HudPatch('MPOS');
  hud_labeltime := SH_HudPatch('MTIME');
  for i := 0 to 4 do
    hud_positions[i] := SH_HudPatch('RACEPOS' + IntToStr(i));
  for i := 0 to 3 do
    hud_countdown[i] := SH_HudPatch('RACE_' + IntToStr(i));
  hud_finallap := SH_HudPatch('RFINLAP');
  hud_youwin := SH_HudPatch('YOUWIN');
  hud_gameover := SH_HudPatch('GAMEOVER');
  hud_needlecolor := SH_HudNearestColor(NEEDLE_COLOR_RGB);
end;

//==============================================================================
//
// SH_HudDrawNumber
// A number with the digits of the game, its right end at x; the result is
// the x of its left end
//
//==============================================================================
function SH_HudDrawNumber(const x, y: integer; const value: integer): integer;
var
  s: string;
  i, total: integer;
  p: Ppatch_t;
  cx: integer;
begin
  s := IntToStr(abs(value));
  total := 0;
  for i := 1 to Length(s) do
  begin
    p := hud_digits[Ord(s[i]) - Ord('0')];
    if p <> nil then
      total := total + p.width;
  end;
  cx := x - total;
  Result := cx;
  for i := 1 to Length(s) do
  begin
    p := hud_digits[Ord(s[i]) - Ord('0')];
    if p <> nil then
    begin
      V_DrawPatch(cx, y, SCN_HUD, p, false);
      cx := cx + p.width;
    end;
  end;
end;

//==============================================================================
//
// SH_HudDrawLine
// A line of one color on the screen of the display (Bresenham)
//
//==============================================================================
procedure SH_HudDrawLine(x0, y0, x1, y1: integer; const color: byte);
var
  dx, dy, sx, sy, err, e2: integer;
begin
  dx := abs(x1 - x0);
  dy := -abs(y1 - y0);
  if x0 < x1 then
    sx := 1
  else
    sx := -1;
  if y0 < y1 then
    sy := 1
  else
    sy := -1;
  err := dx + dy;
  while true do
  begin
    if (x0 >= 0) and (x0 < HUD_WIDTH) and (y0 >= 0) and (y0 < HUD_HEIGHT) then
      screens[SCN_HUD][y0 * HUD_WIDTH + x0] := color;
    if (x0 = x1) and (y0 = y1) then
      break;
    e2 := 2 * err;
    if e2 >= dy then
    begin
      err := err + dy;
      x0 := x0 + sx;
    end;
    if e2 <= dx then
    begin
      err := err + dx;
      y0 := y0 + sy;
    end;
  end;
end;

//==============================================================================
//
// SH_HudDrawGauge
// The rev gauge, its needle, the speed and the gear
//
//==============================================================================
procedure SH_HudDrawGauge(const car: PRacingCarState);
var
  fraction: double;
  degrees: double;
  needlex, needley, mark: integer;
begin
  if hud_gauge <> nil then
    V_DrawPatch(GAUGE_X + hud_gauge.leftoffset, GAUGE_Y + hud_gauge.topoffset, SCN_HUD, hud_gauge, false);

  fraction := car.Rpm / RACING_MAX_RPM;
  if fraction < 0 then
    fraction := 0
  else if fraction > 1 then
    fraction := 1;
  degrees := GAUGE_START_DEGREES - GAUGE_SWEEP_DEGREES * fraction;
  needlex := GAUGE_X + GAUGE_CENTER_X + Round(GAUGE_RADIUS * Cos(degrees * Pi / 180));
  needley := GAUGE_Y + GAUGE_CENTER_Y - Round(GAUGE_RADIUS * Sin(degrees * Pi / 180));
  SH_HudDrawLine(GAUGE_X + GAUGE_CENTER_X, GAUGE_Y + GAUGE_CENTER_Y, needlex, needley, hud_needlecolor);

  // the speed in the box under the gauge
  SH_HudDrawNumber(GAUGE_X + 62, GAUGE_Y + 46, abs(car.EngineSpeed) div RACING_KMH_TO_FIXED);

  // the gear: the column of the numbers and the mark at the one in use (reverse, neutral, 1..6)
  if hud_gearcolumn <> nil then
    V_DrawPatch(GAUGE_X - 24 + hud_gearcolumn.leftoffset, GAUGE_Y - 10 + hud_gearcolumn.topoffset, SCN_HUD,
      hud_gearcolumn, false);
  // the marks MG0..MG6 are the boxes of N and of the gears, MG7 the one of reverse
  if car.Gear >= 0 then
    mark := car.Gear
  else
    mark := 7;
  if (mark >= 0) and (mark <= 7) and (hud_gearmarks[mark] <> nil) then
    V_DrawPatch(GAUGE_X - 24 + 1 + hud_gearmarks[mark].leftoffset,
      GAUGE_Y - 10 + (car.Gear + 1) * 9 + hud_gearmarks[mark].topoffset, SCN_HUD, hud_gearmarks[mark], false);
end;

//==============================================================================
//
// SH_HudDrawRaceInfo
// The lap, the position and the time
//
//==============================================================================
procedure SH_HudDrawRaceInfo(const car: PRacingCarState);
var
  race: IRacingRaceState;
  lap, x: integer;
begin
  race := SH_RaceSettings;
  if race = nil then
    exit;

  lap := car.LapsCompleted + 1;
  if lap < 1 then
    lap := 1;
  if lap > race.NumLaps then
    lap := race.NumLaps;

  if hud_labellap <> nil then
    V_DrawPatch(8 + hud_labellap.leftoffset, 26 + hud_labellap.topoffset, SCN_HUD, hud_labellap, false);
  SH_DrawText(60, 24, Format('%d/%d', [lap, race.NumLaps]), SPEED_FONT_B, SCN_HUD);

  if hud_labelpos <> nil then
    V_DrawPatch(8 + hud_labelpos.leftoffset, 38 + hud_labelpos.topoffset, SCN_HUD, hud_labelpos, false);
  x := SH_DrawText(86, 36, TRacingTextFormat.RacePosition(car.RacePosition), SPEED_FONT_B, SCN_HUD);
  SH_DrawText(x, 36, Format(' of %d', [SH_Race.Count]), SPEED_FONT_A, SCN_HUD);

  if hud_labeltime <> nil then
    V_DrawPatch(8 + hud_labeltime.leftoffset, 50 + hud_labeltime.topoffset, SCN_HUD, hud_labeltime, false);
  SH_DrawText(56, 48, TRacingTextFormat.TicsToTime(race.RaceTime), SPEED_FONT_B, SCN_HUD);
end;

//==============================================================================
//
// SH_HudDrawBanners
// The numbers of the start, the last lap and the result
//
//==============================================================================
procedure SH_HudDrawBanners(const events: TEngineSpeedRaceEvents);
var
  p: Ppatch_t;
  step: integer;
begin
  step := events.CountdownStep;
  // the start: Engines (0) has no picture, then 3, 2, 1 and GO (RACE_0 .. RACE_3 of the game are 3, 2, 1, GO!)
  if (step >= Ord(TRacingCountdownStep.Three)) and (leveltime - events.CountdownTic < COUNTDOWN_TICS) then
  begin
    p := hud_countdown[4 - step];
    if p <> nil then
      V_DrawPatch(HUD_WIDTH div 2 + p.leftoffset, HUD_HEIGHT div 2 + p.topoffset, SCN_HUD, p, false);
  end;

  if (events.LapCompletedTic >= 0) and (leveltime - events.LapCompletedTic < FINAL_LAP_TICS) and
     (SH_Race.Cars[SH_Race.PlayerIndex].LapsCompleted = SH_RaceSettings.NumLaps - 1) and (hud_finallap <> nil) then
    V_DrawPatch(HUD_WIDTH div 2 + hud_finallap.leftoffset, 60 + hud_finallap.topoffset, SCN_HUD, hud_finallap, false);

  case events.Outcome of
    soWon: p := hud_youwin;
    soLost: p := hud_gameover;
  else
    p := nil;
  end;
  if p <> nil then
    V_DrawPatch(HUD_WIDTH div 2 + p.leftoffset, HUD_HEIGHT div 2 + p.topoffset, SCN_HUD, p, false);
end;

//==============================================================================
//
// SH_HudDrawer
//
//==============================================================================
procedure SH_HudDrawer;
var
  car: PRacingCarState;
begin
  if (SH_Race = nil) or (SH_Race.PlayerIndex < 0) or (SH_RaceEvents = nil) or (gamestate <> GS_LEVEL) then
    exit;
  if not hud_loaded then
    SH_HudLoad;

  // SCN_HUD is the temporary screen of the engine: the display is drawn again at every frame
  ZeroMemory(screens[SCN_HUD], HUD_WIDTH * HUD_HEIGHT);
  car := SH_Race.Cars[SH_Race.PlayerIndex];
  SH_HudDrawGauge(car);
  SH_HudDrawRaceInfo(car);
  SH_HudDrawBanners(SH_RaceEvents);
  V_CopyRectTransparent(0, 0, SCN_HUD, HUD_WIDTH, HUD_HEIGHT, 0, 0, SCN_FG, true);
end;

end.
