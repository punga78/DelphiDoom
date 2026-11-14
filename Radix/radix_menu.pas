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
//  Radix: the menus (what m_menu.pas of Rad-X has that the one of Doom has
//  not). The menu is the one of the engine (Doom\m_menu.pas); this unit is
//  its extension (M_ConfigureExtension, given by ComposeRadix):
//   - the look: head lines with the big fonts in place of the title patches,
//     items as words (orange under the cursor), sliders and frames drawn,
//     the pictures SelectSkill/SelectEpisode, the main menu centered, the
//     help pages HELP01..14;
//   - the name of the pilot, asked before a new game;
//   - the table of the ten best pilots (main menu, "Top Ten");
//   - the gameplay options of Radix (options menu, "Gameplay");
//   - the load and save screens on the picture SaveLoadScreen;
//   - the keys of Radix in the key bindings.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit radix_menu;

interface

uses
  m_menu;

//==============================================================================
//
// RX_MenuExtension
// What ComposeRadix gives to M_ConfigureExtension
//
//==============================================================================
function RX_MenuExtension: menuextension_t;

var
  // the gameplay options as the numbers of the configuration file (0 or 1)
  radix_cfg_vanillal1neutroncannon: integer = 0;
  radix_cfg_vanillal1plasmaspreader: integer = 0;
  radix_cfg_fastweaponrefire: integer = 0;
  radix_cfg_bigbarrelexplosion: integer = 0;

implementation

uses
  d_delphi,
  doomdef,
  g_game,
  hu_stuff,
  mn_font,
  mn_screenshot,
  r_defs,
  v_data,
  v_video,
  w_wad,
  z_zone,
  radix_codepointers,
  radix_controls,
  radix_score,
  radix_weapons,
  DelphiDoom.Engine.Configuration.Table,
  DelphiDoom.Imaging.SaveThumbnail,
  DelphiDoom.Radix.Score.Table;

const
  // LINEHEIGHT2 of m_menu: the menus of small text
  SMALLLINEHEIGHT = 8;
  MAINLINEHEIGHT = 14;
  SAVELOADLINEHEIGHT = 15;
  DEF_MENU_ITEMS_START_X = 32;
  DEF_MENU_ITEMS_START_Y = 65;
  OPTIONS_START_Y = 44;
  ARROWXOFFS = -8;
  ARROWYOFFS = -1;
  SAVESTRINGSIZE = 24;
  MAXMAINITEMS = 8;
  MAXOPTIONSITEMS = 10;

type
  titlekind_t = (tk_head, tk_subhead);

  menutitle_t = record
    patch: string;
    kind: titlekind_t;
    y: integer;
    text: string;
  end;

  menuword_t = record
    patch: string;
    text: string;
  end;

const
  NUMMENUTITLES = 15;
  // the title patches of the menus of Doom and the head lines that Rad-X writes in their place
  menutitles: array[0..NUMMENUTITLES - 1] of menutitle_t = (
    (patch: 'M_OPTTTL'; kind: tk_head; y: 15; text: 'Options'),
    (patch: 'MENU_KEY'; kind: tk_head; y: 15; text: 'Key Bindings'),
    (patch: 'M_LOADG'; kind: tk_head; y: 4; text: 'Load Game'),
    (patch: 'M_SAVEG'; kind: tk_head; y: 4; text: 'Save Game'),
    (patch: 'M_SVOL'; kind: tk_head; y: 15; text: 'Sound Volume'),
    (patch: 'M_DISOPT'; kind: tk_head; y: 15; text: 'Display Options'),
    (patch: 'MENU_COM'; kind: tk_subhead; y: 40; text: 'Compatibility'),
    (patch: 'MENU_CON'; kind: tk_subhead; y: 40; text: 'Controls'),
    (patch: 'MENU_SOU'; kind: tk_subhead; y: 40; text: 'Sound'),
    (patch: 'MENU_SYS'; kind: tk_subhead; y: 40; text: 'System'),
    (patch: 'M_MSENS'; kind: tk_subhead; y: 40; text: 'Mouse Sensitivity'),
    (patch: 'MENU_ASP'; kind: tk_subhead; y: 40; text: 'Aspect Ratio'),
    (patch: 'MENU_CAM'; kind: tk_subhead; y: 40; text: 'Camera'),
    (patch: 'MENU_LIG'; kind: tk_subhead; y: 40; text: 'Lightmap'),
    (patch: 'MENU_UNC'; kind: tk_subhead; y: 40; text: 'Uncapped Framerate')
  );

  NUMMENUWORDS = 27;
  // the patches of the items of the menus of Doom and the words of Rad-X
  menuwords: array[0..NUMMENUWORDS - 1] of menuword_t = (
    (patch: 'M_NGAME'; text: 'New Game'),
    (patch: 'M_OPTION'; text: 'Options'),
    (patch: 'M_LOADG'; text: 'Load Game'),
    (patch: 'M_SAVEG'; text: 'Save Game'),
    (patch: 'M_RDTHIS'; text: 'Read This!'),
    (patch: 'M_QUITG'; text: 'Quit Radix'),
    (patch: 'M_EPI1'; text: 'Episode 1'),
    (patch: 'M_EPI2'; text: 'Episode 2'),
    (patch: 'M_EPI3'; text: 'Episode 3'),
    (patch: 'M_EPI4'; text: 'Episode 4'),
    (patch: 'MENU_GEN'; text: 'General'),
    (patch: 'MENU_DIS'; text: 'Display'),
    (patch: 'MENU_SOU'; text: 'Sound'),
    (patch: 'MENU_COM'; text: 'Compatibility'),
    (patch: 'MENU_CON'; text: 'Controls'),
    (patch: 'MENU_SYS'; text: 'System'),
    (patch: 'M_ENDGAM'; text: 'End Game'),
    (patch: 'M_MESSG'; text: 'Messages'),
    (patch: 'M_SCRNSZ'; text: 'Screen Size'),
    (patch: 'M_MSENS'; text: 'Mouse Sensitivity'),
    (patch: 'MENU_OPE'; text: 'OpenGL'),
    (patch: 'MENU_DET'; text: 'Detail'),
    (patch: 'MENU_MAP'; text: 'Automap'),
    (patch: 'MENU_APP'; text: 'Appearance'),
    (patch: 'MENU_ADV'; text: 'Advanced'),
    (patch: 'MENU_32B'; text: '32 bit Rendering'),
    (patch: 'M_SFXVOL'; text: 'Sfx Volume')
  );

var
  rxmenus: menuset_t;

  rxmainmenu: array[0..MAXMAINITEMS - 1] of menuitem_t;
  rxoptionsmenu: array[0..MAXOPTIONSITEMS - 1] of menuitem_t;
  // the routine of "New Game" of the engine: it runs after the name of the pilot
  rxnewgameroutine: PmessageRoutine = nil;

  PilotNameMenu: array[0..0] of menuitem_t;
  PilotNameDef: menu_t;
  TopTenMenu: array[0..0] of menuitem_t;
  TopTenDef: menu_t;
  GameplayMenu: array[0..4] of menuitem_t;
  GameplayDef: menu_t;

  // the name of the pilot is being typed
  pilotStringEnter: boolean = false;
  // the name before the edit
  pilotOldString: AnsiString;

//==============================================================================
//
// RX_MenuHorzLine
//
//==============================================================================
procedure RX_MenuHorzLine(const x1, x2, y: integer; const color: byte);
var
  i: integer;
begin
  if (y < 0) or (y > 199) then
    exit;
  for i := y * 320 + x1 to y * 320 + x2 do
    screens[SCN_TMP][i] := color;
end;

//==============================================================================
//
// RX_MenuVertLine
//
//==============================================================================
procedure RX_MenuVertLine(const x, y1, y2: integer; const color: byte);
var
  i: integer;
begin
  for i := y1 to y2 do
    if (i >= 0) and (i <= 199) then
      screens[SCN_TMP][i * 320 + x] := color;
end;

//==============================================================================
//
// RX_MenuFrame3d
//
//==============================================================================
procedure RX_MenuFrame3d(const x1, y1, x2, y2: integer; const color1, color2, color3: byte);
var
  i: integer;
begin
  RX_MenuHorzLine(x1, x2, y1, color1);
  RX_MenuHorzLine(x1, x2, y2, color2);
  RX_MenuVertLine(x1, y1, y2, color2);
  RX_MenuVertLine(x2, y1, y2, color1);
  for i := y1 + 1 to y2 - 1 do
    RX_MenuHorzLine(x1 + 1, x2 - 1, i, color3);
end;

//==============================================================================
//
// RX_MenuHeadBar
//
//==============================================================================
procedure RX_MenuHeadBar(const y: integer);
var
  i: integer;
begin
  RX_MenuHorzLine(0, 319, y, 64);
  RX_MenuHorzLine(0, 319, y + 15, 80);
  for i := y + 1 to y + 14 do
    RX_MenuHorzLine(0, 319, i, 63);
end;

//==============================================================================
//
// RX_MenuDrawHeadLine
//
//==============================================================================
procedure RX_MenuDrawHeadLine(const y: integer; const str: string);
begin
  RX_MenuHeadBar(y);
  M_WriteBigTextRedCenter(y, str, SCN_TMP);
end;

//==============================================================================
//
// RX_MenuDrawSubHeadLine
//
//==============================================================================
procedure RX_MenuDrawSubHeadLine(const y: integer; const str: string);
begin
  RX_MenuHeadBar(y);
  M_WriteBigTextGray(25, y, str, SCN_TMP);
end;

//==============================================================================
//
// RX_MenuDrawPicture
// A picture of RADIX.DAT, if the data have it (the 1.0 has not all of them)
//
//==============================================================================
procedure RX_MenuDrawPicture(const x, y: integer; const name: string);
var
  lump: integer;
begin
  lump := W_CheckNumForName(name);
  if lump >= 0 then
    V_DrawPatch(x, y, SCN_TMP, lump, false);
end;

//==============================================================================
//
// RX_MenuPatch
// menuextension_t.patch
//
//==============================================================================
function RX_MenuPatch(const x, y: integer; const name: string): boolean;
var
  i: integer;
  p: Ppatch_t;
begin
  result := true;

  for i := 0 to NUMMENUTITLES - 1 do
    if menutitles[i].patch = name then
    begin
      if menutitles[i].kind = tk_head then
        RX_MenuDrawHeadLine(menutitles[i].y, menutitles[i].text)
      else
        RX_MenuDrawSubHeadLine(menutitles[i].y, menutitles[i].text);
      exit;
    end;

  if name = 'M_DOOM' then
  begin
    p := W_CacheLumpName('M_RADIX', PU_STATIC);
    V_DrawPatch((320 - p.width) div 2, 6, SCN_TMP, p, false);
    Z_ChangeTag(p, PU_CACHE);
  end
  else if name = 'M_NEWG' then
  begin
    RX_MenuDrawPicture(0, 0, 'SelectSkill');
    case M_ItemOn of
      0: RX_MenuDrawPicture(51, 16, 'SkillButton1');
      1: RX_MenuDrawPicture(50, 62, 'SkillButton2');
      2: RX_MenuDrawPicture(52, 106, 'SkillButton3');
      3: RX_MenuDrawPicture(52, 150, 'SkillButton4');
    end;
  end
  else if name = 'M_SKILL' then
    // the picture of the skills has its own title
  else if name = 'M_EPISOD' then
  begin
    RX_MenuDrawPicture(0, 0, 'SelectEpisode');
    case M_ItemOn of
      0: RX_MenuDrawPicture(36, 22, 'EpisodeButton1');
      1: RX_MenuDrawPicture(36, 81, 'EpisodeButton2');
      2: RX_MenuDrawPicture(37, 142, 'EpisodeButton3');
    end;
  end
  else if name = 'M_MSGOFF' then
    M_WriteBigTextRed(x + 30, y, 'Off', SCN_TMP)
  else if name = 'M_MSGON' then
    M_WriteBigTextRed(x + 30, y, 'On', SCN_TMP)
  else
    result := false;
end;

//==============================================================================
//
// RX_MenuIsPictureMenu
// The menus that are a picture of RADIX.DAT: the engine draws neither their
// items nor a cursor
//
//==============================================================================
function RX_MenuIsPictureMenu(const menu: Pmenu_t): boolean;
begin
  result := (menu = rxmenus.newgame) or (menu = rxmenus.episode) or (menu = @PilotNameDef) or
    (menu = @TopTenDef) or (menu = rxmenus.load) or (menu = rxmenus.save);
end;

//==============================================================================
//
// RX_MenuItem
// menuextension_t.item: an item is a word in the big font, orange under the
// cursor; a custom episode (UMAPINFO) gives its text
//
//==============================================================================
function RX_MenuItem(const menu: Pmenu_t; const idx, x, y: integer; const selected: boolean): boolean;
var
  i: integer;
  str: string;
begin
  result := true;
  if RX_MenuIsPictureMenu(menu) then
    exit;

  str := menu.menuitems[idx].name;
  for i := 0 to NUMMENUWORDS - 1 do
    if menuwords[i].patch = str then
    begin
      str := menuwords[i].text;
      break;
    end;
  if str = 'M_MUSVOL' then
    str := 'Music Volume';
  if menu.menuitems[idx].alttext <> '' then
    str := string(menu.menuitems[idx].alttext);

  if menu = rxmenus.main then
  begin
    // the main menu of Rad-X: the items in the middle of the screen
    if selected then
      M_WriteBigTextOrangeCenter(y, str, SCN_TMP)
    else
      M_WriteBigTextGrayCenter(y, str, SCN_TMP);
  end
  else if menu.itemheight <= SMALLLINEHEIGHT then
    M_WriteWhiteText(x, y, str)
  else if selected then
    M_WriteBigTextOrange(x, y, str, SCN_TMP)
  else
    M_WriteBigTextGray(x, y, str, SCN_TMP);
end;

//==============================================================================
//
// RX_MenuCursor
// menuextension_t.cursor: Radix has no skull, the big item under the cursor is
// orange; the small menus keep the arrow of the engine
//
//==============================================================================
function RX_MenuCursor(const menu: Pmenu_t; const idx: integer): boolean;
begin
  result := (menu.itemheight > SMALLLINEHEIGHT) or RX_MenuIsPictureMenu(menu);
end;

//==============================================================================
//
// RX_MenuThermo
// menuextension_t.thermo
//
//==============================================================================
function RX_MenuThermo(const x, y, thermWidth, thermDot, numdots: integer): boolean;
var
  i: integer;
  p: integer;
  dots: integer;
begin
  RX_MenuFrame3d(x, y, x + thermWidth * 8 + 2, y + 10, 64, 80, 72);

  dots := numdots;
  if dots <= 1 then
    dots := thermWidth;
  if dots < 2 then
    dots := 2;
  p := Round(thermDot / (dots - 1) * thermWidth * 8 + 1);
  for i := 1 to thermWidth * 8 do
    if not odd(i) then
    begin
      if i < p then
        RX_MenuVertLine(x + i, y + 2, y + 8, 136)
      else
        RX_MenuVertLine(x + i, y + 2, y + 8, 251);
    end;
  result := true;
end;

//==============================================================================
//
// RX_MenuSaveLoadBorder
// menuextension_t.saveloadborder
//
//==============================================================================
function RX_MenuSaveLoadBorder(const x, y: integer): boolean;
begin
  RX_MenuFrame3d(x - 6, y - 3, x + 24 * 8 + 6, y + 10, 64, 80, 72);
  result := true;
end;

//==============================================================================
//
// RX_MenuDrawScreenShot
// The picture of a saved game inside the frame of SaveLoadScreen. The frame
// is the one of the 94x72 picture of Rad-X; the engine keeps 80x50 in its
// saved games: it goes in the middle
//
//==============================================================================
procedure RX_MenuDrawScreenShot(const screenshot: Pmenuscreenbuffer_t);
const
  SHOT_X = 196 + (94 - MN_SCREENSHOTWIDTH) div 2;
  SHOT_Y = 14 + (72 - MN_SCREENSHOTHEIGHT) div 2;
var
  x, y, spos: integer;
  b: byte;
begin
  if screenshot = nil then
    exit;
  if not TImagingSaveThumbnailFormat.IsValid(screenshot^) then
    exit;

  for y := 0 to MN_SCREENSHOTHEIGHT - 1 do
  begin
    spos := (y + SHOT_Y) * 320 + SHOT_X;
    for x := 0 to MN_SCREENSHOTWIDTH - 1 do
    begin
      b := screenshot.Data[y * MN_SCREENSHOTWIDTH + x];
      if b <> 0 then
        screens[SCN_TMP][spos] := b;
      inc(spos);
    end;
  end;
end;

//==============================================================================
//
// RX_MenuLoadSave
// menuextension_t.loadsave: the screens of Rad-X on the picture SaveLoadScreen
//
//==============================================================================
function RX_MenuLoadSave(const info: menuloadsave_t): boolean;
var
  i: integer;
  menu: Pmenu_t;
  desc: string;
begin
  if info.saving then
    menu := rxmenus.save
  else
    menu := rxmenus.load;

  RX_MenuDrawPicture(0, 0, 'SaveLoadScreen');
  if info.saving then
    M_WriteSmallText(270, 96, 'SAVE', SCN_TMP)
  else
    M_WriteSmallText(270, 96, 'LOAD', SCN_TMP);

  for i := 0 to info.numslots - 1 do
  begin
    desc := info.descriptions[i];
    if info.itemon = i then
    begin
      RX_MenuDrawPicture(menu.x + ARROWXOFFS, menu.y + i * menu.itemheight + ARROWYOFFS, 'RightArrow');
      RX_MenuDrawPicture(menu.x + (1 + SAVESTRINGSIZE) * 5 + ARROWXOFFS, menu.y + i * menu.itemheight + ARROWYOFFS,
        'LeftArrow');
    end;
    M_WriteSmallText(menu.x, menu.y + menu.itemheight * i, desc, SCN_TMP);
  end;

  if info.entering then
    if (info.slot >= 0) and (info.slot < info.numslots) then
      if (gametic div 18) mod 2 = 0 then
        M_WriteSmallText(menu.x + M_SmallStringWidth(info.descriptions[info.slot]),
          menu.y + menu.itemheight * info.slot, '_', SCN_TMP);

  RX_MenuDrawScreenShot(info.screenshot);
  result := true;
end;

//==============================================================================
//
// RX_MenuKeyboardMode
// menuextension_t.keyboardmode: the three presets give the same keys of Radix
//
//==============================================================================
procedure RX_MenuKeyboardMode(const mode: integer);
begin
  if mode in [0, 1, 2] then
  begin
    key_afterburner := 47;
    key_plasmabomb := Ord('b');
  end;
end;

//==============================================================================
//
// RX_MenuBindingText
// menuextension_t.bindingtext
//
//==============================================================================
function RX_MenuBindingText(const text: string): string;
begin
  if text = 'Jump' then
    result := 'Fly up'
  else if text = 'Crouch' then
    result := 'Fly down'
  else
    result := '';
end;

//==============================================================================
//
// RX_MenuPilotNameDone
// The name is typed: the menu goes on as "New Game" of the engine does
//
//==============================================================================
function RX_MenuPilotNameDone(choice: integer): pointer;
begin
  result := nil;
  pilotStringEnter := false;
  RX_SavePilotName;
  if Assigned(rxnewgameroutine) then
    rxnewgameroutine(0);
end;

//==============================================================================
//
// RX_MenuNewGame
// "New Game": first the name of the pilot
//
//==============================================================================
function RX_MenuNewGame(choice: integer): pointer;
begin
  result := nil;
  if netgame and not demoplayback then
  begin
    // the engine tells why a new game cannot start
    if Assigned(rxnewgameroutine) then
      rxnewgameroutine(choice);
    exit;
  end;

  pilotStringEnter := true;
  pilotOldString := pilotname;
  M_SetupNextMenu(@PilotNameDef);
end;

//==============================================================================
//
// RX_MenuDrawPilotName
//
//==============================================================================
procedure RX_MenuDrawPilotName;
const
  XPILOT = 12;
  YPILOT = 22;
var
  name: string;
begin
  RX_MenuDrawPicture(0, 0, 'SelectEpisode');
  RX_MenuDrawPicture(PilotNameDef.x, PilotNameDef.y, 'PlayerNameBox');

  name := string(pilotname);
  M_WriteSmallText(PilotNameDef.x + XPILOT, PilotNameDef.y + YPILOT, name, SCN_TMP);

  if pilotStringEnter then
    if Length(name) < PILOTNAMESIZE then
      if (gametic div 18) mod 2 = 0 then
        M_WriteSmallText(PilotNameDef.x + XPILOT + M_SmallStringWidth(name), PilotNameDef.y + YPILOT, '_', SCN_TMP);
end;

//==============================================================================
//
// RX_MenuResponder
// menuextension_t.responder: the keys while the name of the pilot is typed
//
//==============================================================================
function RX_MenuResponder(const ch: integer): boolean;
var
  c: integer;
begin
  result := false;
  if not pilotStringEnter then
    exit;
  if currentMenu <> @PilotNameDef then
  begin
    // the menu was left another way (a console command): the edit is over
    pilotStringEnter := false;
    exit;
  end;

  result := true;
  case ch of
    KEY_BACKSPACE:
      if Length(pilotname) > 0 then
        SetLength(pilotname, Length(pilotname) - 1);
    KEY_ESCAPE:
      begin
        pilotname := pilotOldString;
        RX_MenuPilotNameDone(0);
      end;
    KEY_ENTER:
      RX_MenuPilotNameDone(0);
  else
    begin
      c := Ord(toupper(Chr(ch and $FF)));
      if (c = 32) or ((c - Ord(HU_FONTSTART) >= 0) and (c - Ord(HU_FONTSTART) < HU_FONTSIZE)) then
        if (c >= 32) and (c <= 127) and (Length(pilotname) < PILOTNAMESIZE - 1) then
          pilotname := pilotname + AnsiChar(c and $FF);
    end;
  end;
end;

//==============================================================================
//
// RX_MenuTopTen
// "Top Ten" of the main menu
//
//==============================================================================
function RX_MenuTopTen(choice: integer): pointer;
begin
  result := nil;
  M_SetupNextMenu(@TopTenDef);
end;

//==============================================================================
//
// RX_MenuTopTenExit
//
//==============================================================================
function RX_MenuTopTenExit(choice: integer): pointer;
begin
  result := nil;
  M_SetupNextMenu(rxmenus.main);
end;

//==============================================================================
//
// RX_MenuDrawTopTen
//
//==============================================================================
procedure RX_MenuDrawTopTen;
const
  AA_START = 18;
  NAME_START = 26;
  EPIDODE_START = 112;
  MAP_START = 174;
  SKILL_START = 204;
  SCORE_START = 250;
  Y_TITLE = 30;
  Y_START = 50;
  Y_SPACING = 12;
var
  i, y: integer;
  score: TRadixScoreEntry;
  s: string;
begin
  RX_MenuDrawPicture(0, 0, 'TopTenScreen');

  M_WriteSmallWhiteText(NAME_START, Y_TITLE, 'Name', SCN_TMP);
  M_WriteSmallWhiteText(EPIDODE_START, Y_TITLE, 'Episode', SCN_TMP);
  M_WriteSmallWhiteText(MAP_START, Y_TITLE, 'Map', SCN_TMP);
  M_WriteSmallWhiteText(SKILL_START, Y_TITLE, 'Skill', SCN_TMP);
  M_WriteSmallWhiteText(SCORE_START, Y_TITLE, 'Score', SCN_TMP);

  for i := 0 to RADIX_SCORE_COUNT - 1 do
    if RX_ScoreTable.IsUsed(i) then
    begin
      score := RX_ScoreTable[i];
      y := Y_START + i * Y_SPACING;

      s := itoa(i + 1);
      M_WriteSmallWhiteText(AA_START - M_SmallStringWidth(s), y, s, SCN_TMP);

      M_WriteSmallText(NAME_START, y, string(score.Name), SCN_TMP);

      case score.Episode of
        1: s := 'THETA 2';
        2: s := 'VEGEANCE';
        3: s := 'THE VOID';
      else
        s := itoa(score.Episode);
      end;
      M_WriteSmallText(EPIDODE_START, y, s, SCN_TMP);

      M_WriteSmallText(MAP_START, y, itoa(score.Map), SCN_TMP);

      case score.Skill of
        0: s := 'Easiest';
        1: s := 'Easy';
        2: s := 'Normal';
        3: s := 'Hard';
      else
        s := itoa(score.Skill);
      end;
      M_WriteSmallText(SKILL_START, y, s, SCN_TMP);

      M_WriteSmallText(SCORE_START, y, itoa(score.Rating), SCN_TMP);
    end;
end;

//==============================================================================
//
// RX_MenuGameplay
// "Gameplay" of the options menu
//
//==============================================================================
function RX_MenuGameplay(choice: integer): pointer;
begin
  result := nil;
  M_SetupNextMenu(@GameplayDef);
end;

//==============================================================================
//
// RX_MenuDrawGameplay
//
//==============================================================================
procedure RX_MenuDrawGameplay;
begin
  RX_MenuDrawHeadLine(15, 'Options');
  RX_MenuDrawSubHeadLine(40, 'Gameplay');
end;

//==============================================================================
//
// RX_MenuApplyGameplay
// The numbers of the configuration file to the switches of the game
//
//==============================================================================
procedure RX_MenuApplyGameplay;
begin
  g_vanillalevel1neutroncannon := radix_cfg_vanillal1neutroncannon <> 0;
  g_vanillalevel1plasmaspreader := radix_cfg_vanillal1plasmaspreader <> 0;
  g_fastweaponrefire := radix_cfg_fastweaponrefire <> 0;
  g_bigbarrelexplosion := radix_cfg_bigbarrelexplosion <> 0;
end;

//==============================================================================
//
// RX_MenuToggleGameplay
// One routine for the items of the gameplay menu: each one has its switch
//
//==============================================================================
function RX_MenuToggleGameplay(choice: integer): pointer;
var
  pb: PBoolean;
begin
  result := nil;
  if (choice < 0) or (choice >= GameplayDef.numitems) then
    exit;
  pb := GameplayMenu[choice].pBoolVal;
  if pb = nil then
    exit;
  pb^ := not pb^;
  radix_cfg_vanillal1neutroncannon := Ord(g_vanillalevel1neutroncannon);
  radix_cfg_vanillal1plasmaspreader := Ord(g_vanillalevel1plasmaspreader);
  radix_cfg_fastweaponrefire := Ord(g_fastweaponrefire);
  radix_cfg_bigbarrelexplosion := Ord(g_bigbarrelexplosion);
end;

//==============================================================================
//
// RX_MenuSetItem
//
//==============================================================================
procedure RX_MenuSetItem(const pmi: Pmenuitem_t; const name: string; const routine: PmessageRoutine;
  const pb: PBoolean; const key: char);
begin
  pmi.status := 1;
  pmi.name := name;
  pmi.cmd := '';
  pmi.routine := routine;
  pmi.pBoolVal := pb;
  pmi.alphaKey := key;
  pmi.alttext := '';
end;

//==============================================================================
//
// RX_MenuSetDef
//
//==============================================================================
procedure RX_MenuSetDef(const def: Pmenu_t; const numitems: integer; const prev: Pmenu_t;
  const items: Pmenuitem_tArray; const drawproc: PProcedure; const x, y, itemheight: integer;
  const texturebk: boolean);
begin
  def.numitems := numitems;
  def.prevMenu := prev;
  def.leftMenu := nil;
  def.rightMenu := nil;
  def.menuitems := items;
  def.drawproc := drawproc;
  def.x := x;
  def.y := y;
  def.lastOn := 0;
  def.itemheight := itemheight;
  def.texturebk := texturebk;
  def.runonselect := false;
end;

//==============================================================================
//
// RX_MenuInit
// menuextension_t.init: the menus of the engine are made, Radix changes them
//
//==============================================================================
procedure RX_MenuInit(const menus: menuset_t);
var
  i, n: integer;
begin
  rxmenus := menus;

  RX_LoadScoreTable;
  RX_MenuApplyGameplay;

  // the picture of the skills has four buttons
  if menus.newgame.numitems > 4 then
    menus.newgame.numitems := 4;
  if menus.newgame.lastOn > 3 then
    menus.newgame.lastOn := 3;

  // the main menu: the items of the engine and "Top Ten" before the last one (quit); "New Game"
  // asks the name of the pilot first
  n := menus.main.numitems;
  if n > MAXMAINITEMS - 1 then
    n := MAXMAINITEMS - 1;
  for i := 0 to n - 2 do
    rxmainmenu[i] := menus.main.menuitems[i];
  RX_MenuSetItem(@rxmainmenu[n - 1], 'Top Ten', @RX_MenuTopTen, nil, 't');
  rxmainmenu[n] := menus.main.menuitems[n - 1];
  rxnewgameroutine := rxmainmenu[0].routine;
  rxmainmenu[0].routine := @RX_MenuNewGame;
  menus.main.menuitems := Pmenuitem_tArray(@rxmainmenu);
  menus.main.numitems := n + 1;
  menus.main.y := DEF_MENU_ITEMS_START_Y;
  menus.main.itemheight := MAINLINEHEIGHT;

  // the options menu: one more item, "Gameplay"
  n := menus.options.numitems;
  if n > MAXOPTIONSITEMS - 1 then
    n := MAXOPTIONSITEMS - 1;
  for i := 0 to n - 1 do
    rxoptionsmenu[i] := menus.options.menuitems[i];
  RX_MenuSetItem(@rxoptionsmenu[n], 'Gameplay', @RX_MenuGameplay, nil, 'p');
  menus.options.menuitems := Pmenuitem_tArray(@rxoptionsmenu);
  menus.options.numitems := n + 1;
  // seven items of 16 lines: higher, clear of the cockpit
  menus.options.y := OPTIONS_START_Y;

  // the load and save screens of Rad-X
  menus.load.x := 26;
  menus.load.y := 10;
  menus.load.itemheight := SAVELOADLINEHEIGHT;
  menus.save.x := 26;
  menus.save.y := 10;
  menus.save.itemheight := SAVELOADLINEHEIGHT;

  RX_MenuSetItem(@PilotNameMenu[0], 'Pilot name', @RX_MenuPilotNameDone, nil, 'p');
  RX_MenuSetDef(@PilotNameDef, 1, menus.main, Pmenuitem_tArray(@PilotNameMenu), @RX_MenuDrawPilotName,
    108, 80, 16, false);

  RX_MenuSetItem(@TopTenMenu[0], 'Top Ten', @RX_MenuTopTenExit, nil, 't');
  RX_MenuSetDef(@TopTenDef, 1, menus.main, Pmenuitem_tArray(@TopTenMenu), @RX_MenuDrawTopTen,
    DEF_MENU_ITEMS_START_X, DEF_MENU_ITEMS_START_Y, 16, true);

  RX_MenuSetItem(@GameplayMenu[0], '!Neutron cannon L1 vanilla fire', @RX_MenuToggleGameplay,
    @g_vanillalevel1neutroncannon, 'n');
  RX_MenuSetItem(@GameplayMenu[1], '!Plasma spreader L1 vanilla fire', @RX_MenuToggleGameplay,
    @g_vanillalevel1plasmaspreader, 'p');
  RX_MenuSetItem(@GameplayMenu[2], '!Fast weapon refire', @RX_MenuToggleGameplay, @g_fastweaponrefire, 'f');
  RX_MenuSetItem(@GameplayMenu[3], '!Big barrel death explosion', @RX_MenuToggleGameplay,
    @g_bigbarrelexplosion, 'b');
  RX_MenuSetDef(@GameplayDef, 4, menus.options, Pmenuitem_tArray(@GameplayMenu), @RX_MenuDrawGameplay,
    DEF_MENU_ITEMS_START_X, 68, SMALLLINEHEIGHT, true);
end;

//==============================================================================
//
// RX_MenuExtension
//
//==============================================================================
function RX_MenuExtension: menuextension_t;
begin
  ZeroMemory(@result, SizeOf(menuextension_t));
  result.patch := @RX_MenuPatch;
  result.item := @RX_MenuItem;
  result.cursor := @RX_MenuCursor;
  result.thermo := @RX_MenuThermo;
  result.saveloadborder := @RX_MenuSaveLoadBorder;
  result.loadsave := @RX_MenuLoadSave;
  result.responder := @RX_MenuResponder;
  result.keyboardmode := @RX_MenuKeyboardMode;
  result.bindingtext := @RX_MenuBindingText;
  result.init := @RX_MenuInit;
  // HELP01 and HELP02 are the two help pages of the menu, the others follow as extended help screens
  result.helppages := 2;
  result.numbindings := 2;
  result.bindings[0].text := 'Afterburner';
  result.bindings[0].pkey := @key_afterburner;
  result.bindings[1].text := 'Plasma Bomb';
  result.bindings[1].pkey := @key_plasmabomb;
end;

initialization
  // the names of m_defs of Rad-X (its rows were booleans: 0 or 1 here)
  TEngineConfigurationTable.RegisterExtraKey('g_vanillalevel1neutroncannon', @radix_cfg_vanillal1neutroncannon, 0);
  TEngineConfigurationTable.RegisterExtraKey('g_vanillalevel1plasmaspreader', @radix_cfg_vanillal1plasmaspreader, 0);
  TEngineConfigurationTable.RegisterExtraKey('g_fastweaponrefire', @radix_cfg_fastweaponrefire, 0);
  TEngineConfigurationTable.RegisterExtraKey('g_bigbarrelexplosion', @radix_cfg_bigbarrelexplosion, 0);

end.
