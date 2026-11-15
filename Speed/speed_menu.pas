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
//  Speed Haste: the menu of the new race (the choice of the course, of the car,
//  of the laps, of the transmission, of the kind of game and of the skill of the
//  computer drivers). The menus of Doom are not copied: M_ConfigureExtension
//  (m_menu) lets the game change its items and draw them, and the menu of the
//  skills of Doom becomes the menu of the race: "New Game" opens it at once (the
//  episodes are not chosen: there is one, the courses are its maps).
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit speed_menu;

interface

uses
  m_menu;

//==============================================================================
//
// SH_MenuExtension
// What the game gives to M_ConfigureExtension
//
//==============================================================================
function SH_MenuExtension: menuextension_t;

//==============================================================================
//
// SH_MenuCourseCount
// How many courses the data have (E1M1, E1M2...)
//
//==============================================================================
function SH_MenuCourseCount: integer;

var
  // the course that the menu has chosen (the map of the episode 1)
  speed_course: integer = 1;

implementation

uses
  SysUtils,
  d_delphi,
  doomdef,
  d_main,
  g_game,
  v_data,
  w_wad,
  speed_controls,
  speed_text,
  DelphiDoom.Racing.CarData,
  DelphiDoom.Racing.Types;

const
  ITEM_COURSE = 0;
  ITEM_CAR = 1;
  ITEM_LAPS = 2;
  ITEM_TRANSMISSION = 3;
  ITEM_GAMETYPE = 4;
  ITEM_SKILL = 5;
  ITEM_START = 6;
  NUM_ITEMS = 7;
  ITEM_HEIGHT = 15;
  MENU_X = 40;
  MENU_Y = 50;
  MAX_COURSES = 8;
  SKILL_NAMES: array[0..4] of string = ('Baby', 'Easy', 'Medium', 'Hard', 'Nightmare');
  GAME_NAMES: array[0..2] of string = ('Championship', 'Single race', 'Practice');
  LABELS: array[0..NUM_ITEMS - 1] of string = ('Course', 'Car', 'Laps', 'Gearbox', 'Game', 'Skill', 'Start the race');

type
  menuword_t = record
    patch: string;
    text: string;
  end;

const
  NUMMENUWORDS = 24;
  // the patches of the menus of Doom (the IWAD has them, Speed Haste has not) and their words
  menuwords: array[0..NUMMENUWORDS - 1] of menuword_t = (
    (patch: 'M_DOOM'; text: 'SPEED HASTE'),
    (patch: 'M_NGAME'; text: 'New Game'),
    (patch: 'M_OPTION'; text: 'Options'),
    (patch: 'M_LOADG'; text: 'Load Game'),
    (patch: 'M_SAVEG'; text: 'Save Game'),
    (patch: 'M_RDTHIS'; text: 'Help'),
    (patch: 'M_QUITG'; text: 'Quit'),
    (patch: 'M_OPTTTL'; text: 'OPTIONS'),
    (patch: 'M_ENDGAM'; text: 'End Game'),
    (patch: 'M_MESSG'; text: 'Messages'),
    (patch: 'M_DETAIL'; text: 'Detail'),
    (patch: 'M_SCRNSZ'; text: 'Screen Size'),
    (patch: 'M_MSENS'; text: 'Mouse Sensitivity'),
    (patch: 'M_SVOL'; text: 'SOUND VOLUME'),
    (patch: 'M_SFXVOL'; text: 'Sfx Volume'),
    (patch: 'M_MUSVOL'; text: 'Music Volume'),
    (patch: 'MENU_GEN'; text: 'General'),
    (patch: 'MENU_DIS'; text: 'Display'),
    (patch: 'MENU_SOU'; text: 'Sound'),
    (patch: 'MENU_COM'; text: 'Compatibility'),
    (patch: 'MENU_CON'; text: 'Controls'),
    (patch: 'MENU_SYS'; text: 'System'),
    (patch: 'MENU_32B'; text: '32 bit Rendering'),
    (patch: 'MENU_ADV'; text: 'Advanced')
  );

var
  speedmenu: array[0..NUM_ITEMS - 1] of menuitem_t;
  speedskill: integer = Ord(sk_medium);
  menus: menuset_t;

//==============================================================================
//
// SH_MenuCourseCount
//
//==============================================================================
function SH_MenuCourseCount: integer;
var
  i: integer;
begin
  Result := 0;
  for i := 1 to MAX_COURSES do
    if W_CheckNumForName(Format('E1M%d', [i])) >= 0 then
      Result := i;
end;

//==============================================================================
//
// SH_MenuStep
// The value of a setting moved one step left (0) or right (1) inside its range
//
//==============================================================================
function SH_MenuStep(const value, choice, minimum, maximum: integer): integer;
begin
  Result := value;
  if choice = 0 then
    dec(Result)
  else
    inc(Result);
  if Result < minimum then
    Result := maximum
  else if Result > maximum then
    Result := minimum;
end;

procedure SH_MenuCourse(choice: integer);
var
  count: integer;
begin
  count := SH_MenuCourseCount;
  if count > 0 then
    speed_course := SH_MenuStep(speed_course, choice, 1, count);
end;

procedure SH_MenuCar(choice: integer);
begin
  speed_car := SH_MenuStep(speed_car, choice, 0, RACING_CAR_COUNT - 1);
end;

procedure SH_MenuLaps(choice: integer);
begin
  speed_laps := SH_MenuStep(speed_laps, choice, RACING_MIN_LAPS, RACING_MAX_LAPS);
end;

procedure SH_MenuTransmission(choice: integer);
begin
  speed_transmission := 1 - speed_transmission;
end;

procedure SH_MenuGameType(choice: integer);
begin
  speed_gametype := SH_MenuStep(speed_gametype, choice, SH_GAME_CHAMPIONSHIP, SH_GAME_PRACTICE);
end;

procedure SH_MenuSkill(choice: integer);
begin
  speedskill := SH_MenuStep(speedskill, choice, Ord(sk_baby), Ord(sk_nightmare));
end;

procedure SH_MenuStart(choice: integer);
var
  course: integer;
begin
  defaultskill := speedskill;
  course := speed_course;
  // a championship begins with the first course
  if speed_gametype = SH_GAME_CHAMPIONSHIP then
    course := 1;
  G_DeferedInitNew(skill_t(speedskill), 1, course);
  menuactive := false;
end;

//==============================================================================
//
// SH_MenuValue
// The text on the right of a setting
//
//==============================================================================
function SH_MenuValue(const idx: integer): string;
begin
  case idx of
    ITEM_COURSE:
      if speed_gametype = SH_GAME_CHAMPIONSHIP then
        Result := 'all'
      else
        Result := Format('E1M%d', [speed_course]);
    ITEM_CAR: Result := RACING_CAR_DATA[speed_car].Name;
    ITEM_LAPS: Result := IntToStr(speed_laps);
    ITEM_TRANSMISSION:
      if speed_transmission = 1 then
        Result := 'manual'
      else
        Result := 'automatic';
    ITEM_GAMETYPE: Result := GAME_NAMES[speed_gametype];
    ITEM_SKILL: Result := SKILL_NAMES[speedskill];
  else
    Result := '';
  end;
end;

//==============================================================================
//
// SH_MenuItem
// menuextension_t.item: the items of the menu of the race
//
//==============================================================================
function SH_MenuWord(const name: string): string;
var
  i: integer;
begin
  Result := name;
  for i := 0 to NUMMENUWORDS - 1 do
    if menuwords[i].patch = name then
    begin
      Result := menuwords[i].text;
      exit;
    end;
end;

function SH_MenuItem(const menu: Pmenu_t; const idx, x, y: integer; const selected: boolean): boolean;
var
  font: integer;
begin
  if selected then
    font := SPEED_FONT_A
  else
    font := SPEED_FONT_B;
  Result := menu = menus.newgame;
  if not Result then
  begin
    // an item of the menus of Doom whose picture is not in the data: its words
    Result := W_CheckNumForName(menu.menuitems[idx].name) < 0;
    if Result then
      SH_DrawText(x, y, SH_MenuWord(menu.menuitems[idx].name), font, SCN_TMP);
    exit;
  end;
  if idx = ITEM_START then
    SH_DrawText(x, y, LABELS[idx], font, SCN_TMP)
  else
  begin
    SH_DrawText(x, y, LABELS[idx], font, SCN_TMP);
    SH_DrawText(x + 100, y, SH_MenuValue(idx), font, SCN_TMP);
  end;
end;

//==============================================================================
//
// SH_MenuCursor
// menuextension_t.cursor: no skull in the menu of the race (the item under the cursor is yellow)
//
//==============================================================================
function SH_MenuCursor(const menu: Pmenu_t; const idx: integer): boolean;
begin
  Result := (menu = menus.newgame) or (W_CheckNumForName('M_SKULL1') < 0);
  if Result and (menu <> menus.newgame) then
    SH_DrawText(menu.x - 14, menu.y + idx * menu.itemheight, '>', SPEED_FONT_A, SCN_TMP);
end;

//==============================================================================
//
// SH_MenuPatch
// menuextension_t.patch: the title of the menu of the skills becomes the one of the race
//
//==============================================================================
function SH_MenuPatch(const x, y: integer; const name: string): boolean;
begin
  Result := (name = 'M_NEWG') or (name = 'M_SKILL');
  if Result then
  begin
    SH_DrawTextCenter(160, 28, 'NEW RACE', SPEED_FONT_A, SCN_TMP);
    exit;
  end;
  // a title or a picture of the menus of Doom that the data do not have: its words, centered
  Result := (Length(name) > 2) and (Copy(name, 1, 2) = 'M_') and (W_CheckNumForName(name) < 0);
  if Result and (SH_MenuWord(name) <> name) then
    SH_DrawTextCenter(160, y + 8, SH_MenuWord(name), SPEED_FONT_A, SCN_TMP);
end;

//==============================================================================
//
// SH_MenuInit
// menuextension_t.init: the menu of the skills is the menu of the race, and the
// menu of the episodes is skipped
//
//==============================================================================
procedure SH_MenuInit(const set_: menuset_t);
var
  i: integer;
  routines: array[0..NUM_ITEMS - 1] of PmessageRoutine;
begin
  menus := set_;
  routines[ITEM_COURSE] := @SH_MenuCourse;
  routines[ITEM_CAR] := @SH_MenuCar;
  routines[ITEM_LAPS] := @SH_MenuLaps;
  routines[ITEM_TRANSMISSION] := @SH_MenuTransmission;
  routines[ITEM_GAMETYPE] := @SH_MenuGameType;
  routines[ITEM_SKILL] := @SH_MenuSkill;
  routines[ITEM_START] := @SH_MenuStart;
  for i := 0 to NUM_ITEMS - 1 do
  begin
    if i = ITEM_START then
      speedmenu[i].status := 1
    else
      speedmenu[i].status := 2;
    speedmenu[i].name := LABELS[i];
    speedmenu[i].cmd := '';
    speedmenu[i].routine := routines[i];
    speedmenu[i].pBoolVal := nil;
    speedmenu[i].alphaKey := #0;
    speedmenu[i].alttext := '';
  end;
  menus.newgame.menuitems := Pmenuitem_tArray(@speedmenu);
  menus.newgame.numitems := NUM_ITEMS;
  menus.newgame.x := MENU_X;
  menus.newgame.y := MENU_Y;
  menus.newgame.itemheight := ITEM_HEIGHT;
  menus.newgame.lastOn := ITEM_START;
  menus.episode.numitems := 0;
  speedskill := Ord(sk_medium);
  if speed_course < 1 then
    speed_course := 1;
end;

//==============================================================================
//
// SH_MenuExtension
//
//==============================================================================
function SH_MenuExtension: menuextension_t;
begin
  ZeroMemory(@Result, SizeOf(Result));
  Result.item := @SH_MenuItem;
  Result.cursor := @SH_MenuCursor;
  Result.patch := @SH_MenuPatch;
  Result.init := @SH_MenuInit;
end;

end.
