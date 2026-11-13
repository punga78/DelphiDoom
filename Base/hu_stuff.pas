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
//    Head up display
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}


unit hu_stuff;

interface

uses
  doomdef,
  d_event,
  r_defs,
  DelphiDoom.Hud.Intf,
  DelphiDoom.Engine.Hud.Intf;

{$IFDEF HEXEN}
//-----------------------------------------------------------------------------
//
// DESCRIPTION:  Head up display
//
//-----------------------------------------------------------------------------

{$ENDIF}
const
//
// Globally visible constants.
//
  HU_FONTSTART = '!'; // the first font characters
{$IF DEFINED(HERETIC)}
  HU_FONTEND = '[';   // the last font characters
  HU_FONT4END = ']';   // the last font characters
  HU_CFONTEND = '_';  // the last console font character
  HU_FONTCURSOR = 62; // Console cursor
{$ELSEIF DEFINED(HEXEN)}
  HU_FONTEND = '[';   // the last font characters
  HU_CFONTEND = '_';  // the last console font character
  HU_FONTCURSOR = 62; // Console cursor
{$ELSEIF DEFINED(RADIX)}
  HU_FONTEND = 'z'; // the last font characters (Radix: FNTAnnn has the small letters too)
{$ELSE}
  HU_FONTEND = '_'; // the last font characters
{$ENDIF}

// Calculate # of glyphs in font.
  HU_FONTSIZE = (Ord(HU_FONTEND) - Ord(HU_FONTSTART)) + 1;
{$IF DEFINED(HERETIC)}
  HU_FONTSIZE4 = (Ord(HU_FONT4END) - Ord(HU_FONTSTART)) + 1;
  HU_CFONTSIZE = (Ord(HU_CFONTEND) - Ord(HU_FONTSTART)) + 1;
  HU_BROADCAST = 5;
{$ELSEIF DEFINED(HEXEN)}
  HU_CFONTSIZE = (Ord(HU_CFONTEND) - Ord(HU_FONTSTART)) + 1;
  HU_BROADCAST = 5;
{$ELSEIF DEFINED(STRIFE)}
  HU_BROADCAST = 9;   // haleyjd [STRIFE] Changed 5 -> 9
  HU_CHANGENAME = 10; // haleyjd [STRIFE] Special command
{$ELSE}
  HU_BROADCAST = 5;
{$ENDIF}

{$IFDEF STRIFE}
  HU_MSGREFRESH = Ord('/');
{$ELSE}
  HU_MSGREFRESH = KEY_ENTER;
{$ENDIF}
  HU_MSGX = 0;
  HU_MSGY = 0;
{$IFDEF STRIFE}
  HU_MSGHEIGHT = 2; // in lines
{$ELSE}
  HU_MSGHEIGHT = 1; // in lines
{$ENDIF}

{$IFDEF STRIFE}
  HU_MSGTIMEOUT = 8 * TICRATE;  // haleyjd [STRIFE] Doubled message timeout
{$ELSE}
  HU_MSGTIMEOUT = 4 * TICRATE;
{$ENDIF}

//==============================================================================
//
// HU_Configure
//
// The heads-up display is Libs\Hud (the model) and DelphiDoom.Engine.Hud.* (the
// drawing): ComposeEngine gives them here. Without it HU_Init stops with I_Error.
//
//==============================================================================
procedure HU_Configure(const AHeadsUp: IHeadsUp; const AScreen: IHudScreen);

//==============================================================================
// HU_Init
//
// HEADS UP TEXT
//
//==============================================================================
procedure HU_Init;

//==============================================================================
//
// HU_Start
//
//==============================================================================
procedure HU_Start;

//==============================================================================
//
// HU_Responder
//
//==============================================================================
function HU_Responder(ev: Pevent_t): boolean;

//==============================================================================
//
// HU_Ticker
//
//==============================================================================
procedure HU_Ticker;

//==============================================================================
//
// HU_Drawer
//
//==============================================================================
procedure HU_Drawer;

{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
{$IFDEF OPENGL}

//==============================================================================
//
// HU_Height
//
//==============================================================================
function HU_Height: integer;
{$ENDIF}

{$ENDIF}
{$IFDEF STRIFE}

//==============================================================================
//
// HU_DrawYellowText
//
// hu_lib.pas gives HUlib_drawYellowText to it
//
//==============================================================================
procedure HU_DrawYellowText(x, y: integer; const txt: string; const scn: integer);
{$ENDIF}

//==============================================================================
//
// HU_dequeueChatChar
//
//==============================================================================
function HU_dequeueChatChar: char;

//==============================================================================
//
// HU_Erase
//
//==============================================================================
procedure HU_Erase;

var
  hu_font: array[0..HU_FONTSIZE - 1] of Ppatch_t;
{$IF DEFINED(HERETIC)}
  hu_font2: array[0..HU_FONTSIZE - 2] of Ppatch_t;
  hu_font3: array[0..HU_CFONTSIZE - 1] of Ppatch_t; // Console font
  hu_font4: array[0..HU_FONTSIZE4 - 1] of Ppatch_t;  // Menu secondary font
{$ELSEIF DEFINED(HEXEN)}
  hu_fonty: array[0..HU_FONTSIZE - 1] of Ppatch_t;  // Yellow font
  hu_font2: array[0..HU_FONTSIZE - 1] of Ppatch_t;
  hu_font3: array[0..HU_CFONTSIZE - 1] of Ppatch_t; // Console font
{$ELSEIF DEFINED(STRIFE)}
  yfont: array[0..HU_FONTSIZE - 1] of Ppatch_t;  // haleyjd 09/18/10: [STRIFE]

var
  m_font3: array['A'..Chr(Ord('Z') + 1)] of Ppatch_t;
{$ENDIF}

  chat_on: boolean;

  message_dontfuckwithme: boolean;

{$IF DEFINED(HERETIC)}
var
// Heretic shareware/registered/extended names.
  mapnames: array[0..44] of string;

  player_names: array[0..3] of string;
{$ELSEIF DEFINED(HEXEN)}
var
  player_names: array[0..3] of string;
{$ELSEIF DEFINED(STRIFE)}
var
// STRIFE MAP NAMES
  mapnames: array[0..33] of string;

  player_names: array[0..7] of string;
{$ELSE}
const
  NUM_MAPNAMES = 45;
  NUM_MAPNAMES2 = 33;
  NUM_MAPNAMESP = 32;
  NUM_MAPNAMEST = 32;

var
// DOOM shareware/registered/retail (Ultimate) names.
  mapnames: array[0..NUM_MAPNAMES - 1] of string;

// DOOM 2 map names.
  mapnames2: array[0..NUM_MAPNAMES2 - 1] of string;

// Plutonia WAD map names.
  mapnamesp: array[0..NUM_MAPNAMESP - 1] of string;

// TNT WAD map names.
  mapnamest: array[0..NUM_MAPNAMEST - 1] of string;

  player_names: array[0..3] of string;
{$ENDIF}

var
  chat_macros: array[0..9] of string;

var
{$IFDEF STRIFE}
  key_multi_msgplayer: array[0..MAXPLAYERS - 1] of string;
{$ELSE}
  destination_keys: array[0..MAXPLAYERS - 1] of string;
{$ENDIF}

var
  shiftxform: array[0..127] of Char;

//==============================================================================
//
// HU_DoFPSStuff
//
//==============================================================================
procedure HU_DoFPSStuff;

//==============================================================================
//
// HU_FPS
//
//==============================================================================
function HU_FPS: integer;

var
  drawfps: boolean;
  drawcrosshair: boolean;
{$IF DEFINED(DOOM)}
  amdrawstats: boolean;
{$ELSEIF DEFINED(STRIFE)}
{$ELSE}

//==============================================================================
//
// HU_TITLE
//
//==============================================================================
function HU_TITLE: string;
{$ENDIF}

implementation

uses
  d_delphi,
  c_cmds,
{$IFNDEF HEXEN}
  z_zone,
  w_wad,
{$ENDIF}
  i_system,
  doomstat,
{$IF DEFINED(HERETIC)}
  h_strings,
{$ELSEIF DEFINED(HEXEN)}
  xn_strings,
{$ELSE}
  d_englsh,
{$ENDIF}
  d_player,
{$IFDEF STRIFE}
  d_main,
{$ENDIF}
  g_game,
{$IFDEF HEXEN}
  p_mapinfo,
{$ENDIF}
{$IFDEF RADIX}
  radix_fonts,
{$ENDIF}
  v_data,
{$IFDEF HEXEN}
  v_video,
  w_wad,
  z_zone,
{$ELSE}
  v_video,
{$ENDIF}
  DelphiDoom.Hud.Types,
  DelphiDoom.Hud.MapTitle;

// The heads-up display (issue #185, slice 1a): the model is in Libs\Hud (THeadsUp) and
// the drawing in DelphiDoom.Engine.Hud.Drawer. What stays here is what is tied to the
// globals that other units own: the fonts and their loading, the tables of names that the
// Dehacked patches change, chat_on and message_dontfuckwithme (the menu writes them), the
// geometry of the widgets (it reads the fonts and the screen) and the routines that call.
var
  GHeadsUp: IHeadsUp = nil;
  GScreen: IHudScreen = nil;

//==============================================================================
//
// HU_Configure
//
//==============================================================================
procedure HU_Configure(const AHeadsUp: IHeadsUp; const AScreen: IHudScreen);
begin
  GHeadsUp := AHeadsUp;
  GScreen := AScreen;
end;

//==============================================================================
//
// HU_CheckConfigured
//
//==============================================================================
procedure HU_CheckConfigured;
begin
  if (GHeadsUp = nil) or (GScreen = nil) then
    I_Error('HU_CheckConfigured(): the heads-up display is not configured (HU_Configure)');
end;

//==============================================================================
//
// HU_DoFPSStuff
//
//==============================================================================
procedure HU_DoFPSStuff;
begin
  HU_CheckConfigured;
  GHeadsUp.RecordFrameTime(I_GetFracTime);
end;

//==============================================================================
//
// HU_FPS
//
//==============================================================================
function HU_FPS: integer;
begin
  HU_CheckConfigured;
  result := GHeadsUp.FramesPerSecond;
end;

//==============================================================================
//
// HU_CmdFPS
//
//==============================================================================
procedure HU_CmdFPS;
begin
  printf('%d fps'#13#10, [HU_FPS]);
end;

//==============================================================================
//
// HU_CmdPlayerMessage
//
//==============================================================================
procedure HU_CmdPlayerMessage(const parm1, parm2: string);
begin
  players[consoleplayer]._message := parm1 + ' ' + parm2;
end;

//==============================================================================
//
// HU_TITLE
//
//==============================================================================
function HU_TITLE: string;
begin
{$IF DEFINED(HERETIC)}
  result := mapnames[(gameepisode - 1) * 9 + gamemap - 1];
{$ELSEIF DEFINED(HEXEN)}
  result := P_GetMapDescName(gamemap);
{$ELSEIF DEFINED(STRIFE)}
  result := mapnames[gamemap - 1];
{$ELSE}
  result := THudMapTitle.ForEpisode(mapnames, gameepisode, gamemap);
{$ENDIF}
end;
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN) OR DEFINED(STRIFE))}

//==============================================================================
//
// HU_TITLE2
//
//==============================================================================
function HU_TITLE2: string;
begin
  result := THudMapTitle.ForMap(mapnames2, gamemap);
end;

//==============================================================================
//
// HU_TITLEP
//
//==============================================================================
function HU_TITLEP: string;
begin
  result := THudMapTitle.ForMap(mapnamesp, gamemap);
end;

//==============================================================================
//
// HU_TITLET
//
//==============================================================================
function HU_TITLET: string;
begin
  result := THudMapTitle.ForMap(mapnamest, gamemap);
end;
{$ENDIF}

const
  HU_TITLEHEIGHT = 1;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  HU_TITLEX = 32;
  HU_LEVELTIMEX = 32;
{$ELSE}
  HU_TITLEX = 0;
  HU_LEVELTIMEX = 0;
{$ENDIF}

//==============================================================================
{$IFDEF STRIFE}
// HU_TITLEY
{$ENDIF}
//
{$IFDEF STRIFE}
// haleyjd 09/01/10: [STRIFE] 167 -> 160 to move up level name
{$ELSE}
// HU_TITLEY
{$ENDIF}
//
//==============================================================================
function HU_TITLEY: integer;
begin
{$IF DEFINED(HERETIC)}
  result := {$IFDEF OPENGL}V_GetScreenHeight(SCN_FG) * 157 div 200{$ELSE}157{$ENDIF} - hu_font[0].height;
{$ELSEIF DEFINED(HEXEN)}
  result := {$IFDEF OPENGL}V_GetScreenHeight(SCN_FG) * 150 div 200{$ELSE}150{$ENDIF} - hu_font[0].height;
{$ELSEIF DEFINED(STRIFE)}
  result := {$IFDEF OPENGL}V_GetScreenHeight(SCN_FG) * 160 div 200{$ELSE}160{$ENDIF} - hu_font[0].height;
{$ELSE}
  result := {$IFDEF OPENGL}V_GetScreenHeight(SCN_FG) * 167 div 200{$ELSE}167{$ENDIF} - hu_font[0].height;
{$ENDIF}
end;

//==============================================================================
//
// HU_LEVELTIMEY
//
//==============================================================================
function HU_LEVELTIMEY: integer;
begin
{$IF DEFINED(HERETIC)}
  result := {$IFDEF OPENGL}V_GetScreenHeight(SCN_FG) * 157 div 200{$ELSE}157{$ENDIF} - 2 * hu_font[0].height;
{$ELSEIF DEFINED(HEXEN)}
  result := {$IFDEF OPENGL}V_GetScreenHeight(SCN_FG) * 150 div 200{$ELSE}150{$ENDIF} - 2 * hu_font[0].height - 1;
{$ELSEIF DEFINED(STRIFE)}
  result := {$IFDEF OPENGL}V_GetScreenHeight(SCN_FG) * 160 div 200{$ELSE}160{$ENDIF} - 2 * hu_font[0].height;
{$ELSE}
  result := {$IFDEF OPENGL}V_GetScreenHeight(SCN_FG) * 167 div 200{$ELSE}167{$ENDIF} - 2 * hu_font[0].height;
{$ENDIF}
end;

//==============================================================================
//
// HU_INPUTX
//
//==============================================================================
function HU_INPUTX: integer;
begin
  result := HU_MSGX;
end;

//==============================================================================
//
// HU_INPUTY
//
//==============================================================================
function HU_INPUTY: integer;
begin
  result := HU_MSGY + HU_MSGHEIGHT * (hu_font[0].height + 1)
end;

//==============================================================================
//
// HU_Init
//
//==============================================================================
procedure HU_Init;
var
  i: integer;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  lump: integer;
{$ELSE}
  j: integer;
{$ENDIF}
  buffer: string;
{$IFDEF STRIFE}
  c: char;
{$ENDIF}
  shifttable: THudShiftTable;
begin
  HU_CheckConfigured;

  // the keyboard map of the language and the history of the frame times
  GHeadsUp.Initialize;
  shifttable := GHeadsUp.GetShiftTable;
  for i := 0 to 127 do
    shiftxform[i] := shifttable[i];

  // load the heads-up font
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  for i := 1 to HU_FONTSIZE do
{$ELSE}
  j := Ord(HU_FONTSTART);
  for i := 0 to HU_FONTSIZE - 1 do
{$ENDIF}
  begin
{$IF DEFINED(HERETIC)}
    buffer := 'FONTA' + IntToStrZfill(2, i);
    hu_font[i - 1] := W_CacheLumpName(buffer, PU_STATIC);
  end;

  for i := 1 to HU_FONTSIZE - 1 do
  begin
    buffer := 'FONTB' + IntToStrZfill(2, i);
    hu_font2[i - 1] := W_CacheLumpName(buffer, PU_STATIC);
  end;

  for i := 1 to HU_CFONTSIZE do
  begin
    buffer := 'FONTC' + IntToStrZfill(2, i);
    lump := W_CheckNumForName(buffer);
    if lump >= 0 then
      hu_font3[i - 1] := W_CacheLumpNum(lump, PU_STATIC)
    else if i < Ord(HU_FONTSIZE) then
      hu_font3[i - 1] := hu_font[i - 1]
    else if i = 59 then
      hu_font3[58] := hu_font[7]
    else if i = 60 then
      hu_font3[59] := hu_font[14]
    else if i = 61 then
      hu_font3[60] := hu_font[8]
    else
      hu_font3[i - 1] := hu_font[HU_FONTSIZE - 1]
  end;

  for i := 1 to HU_FONTSIZE4 do
  begin
    buffer := 'STCFN' + IntToStrZfill(3, i + 32);
    hu_font4[i - 1] := W_CacheLumpName(buffer, PU_STATIC);
{$ELSEIF DEFINED(HEXEN)}
    buffer := 'FONTA' + IntToStrZfill(2, i);
    hu_font[i - 1] := W_CacheLumpName(buffer, PU_STATIC);
  end;

  // Yellow bold fonts
  for i := 1 to HU_FONTSIZE - 1 do
  begin
    buffer := 'FONTAY' + IntToStrZfill(2, i);
    hu_fonty[i - 1] := W_CacheLumpName(buffer, PU_STATIC);
  end;

  for i := 1 to HU_FONTSIZE - 1 do
  begin
    buffer := 'FONTB' + IntToStrZfill(2, i);
    hu_font2[i - 1] := W_CacheLumpName(buffer, PU_STATIC);
  end;

  for i := 1 to HU_CFONTSIZE do
  begin
    buffer := 'FONTC' + IntToStrZfill(2, i);
    lump := W_CheckNumForName(buffer);
    if lump >= 0 then
      hu_font3[i - 1] := W_CacheLumpNum(lump, PU_STATIC)
    else if i < Ord(HU_FONTSIZE) then
      hu_font3[i - 1] := hu_font[i - 1]
    else if i = 59 then
      hu_font3[58] := hu_font[7]
    else if i = 60 then
      hu_font3[59] := hu_font[14]
    else if i = 61 then
      hu_font3[60] := hu_font[8]
    else
      hu_font3[i - 1] := hu_font[HU_FONTSIZE - 1]
{$ELSEIF DEFINED(STRIFE)}
    buffer := 'STCFN' + IntToStrZfill(3, j);
    inc(j);
    hu_font[i] := W_CacheLumpName(buffer, PU_STATIC);
    // haleyjd 09/18/10: load yfont as well; and yes, this is exactly
    // how Rogue did it :P
    buffer[3] := 'B';
    yfont[i] := W_CacheLumpName(buffer, PU_STATIC);
{$ELSEIF DEFINED(RADIX)}
    // the small font of RADIX.DAT; a character it does not have is the empty sprite
    buffer := 'FNTA';
    hu_font[i] := W_CacheLumpNum(RX_FontLumpNum(buffer, j), PU_STATIC);
    inc(j);
{$ELSE}
    buffer := 'STCFN' + IntToStrZfill(3, j);
    inc(j);
    hu_font[i] := W_CacheLumpName(buffer, PU_STATIC);
{$ENDIF}
  end;
{$IFDEF STRIFE}

  for c := 'A' to 'Z' do
    m_font3[c] := W_CacheLumpName('FONT3_' + c, PU_STATIC);
  m_font3[Chr(Ord('Z') + 1)] := W_CacheLumpName('FONT3_!', PU_STATIC);
{$ENDIF}
{$IFDEF RADIX}

  RX_InitFonts;
{$ENDIF}


  // the widths of the glyphs and the crosshairs
  GScreen.Initialize;

  C_AddCmd('fps', @HU_CmdFPS);
  C_AddCmd('playermessage', @HU_CmdPlayerMessage);
end;

//==============================================================================
//
// HU_Start
//
//==============================================================================
procedure HU_Start;
var
  params: THudStartParams;
  s: string;
begin
  HU_CheckConfigured;

{$IF DEFINED(DOOM)}
  if (gamemapinfo <> nil) and (gamemapinfo.levelname <> '') then
    s := THudMapTitle.FromMapInfo(gamemapinfo.mapname, gamemapinfo.mlabel, gamemapinfo.levelname)
  else
  begin
    case gamemode of
      shareware,
      registered,
      retail: s := HU_TITLE;
    else
      begin
        case gamemission of
          pack_tnt: s := HU_TITLET;
          pack_plutonia: s := HU_TITLEP;
        else
          s := HU_TITLE2;
        end;
      end;
    end;
  end;
{$ELSEIF DEFINED(HERETIC)}
  if (gamemapinfo <> nil) and (gamemapinfo.levelname <> '') then
    s := THudMapTitle.FromMapInfo(gamemapinfo.mapname, gamemapinfo.mlabel, gamemapinfo.levelname)
  else
    s := HU_TITLE;
{$ELSE}
  s := HU_TITLE;
{$ENDIF}

  // where the message window, the map title, the time of the level and the chat line go
  params.MessageX := HU_MSGX;
  params.MessageY := HU_MSGY;
  params.MessageHeight := HU_MSGHEIGHT;
  params.LineHeight := hu_font[0].height + 1;
  params.StartChar := Ord(HU_FONTSTART);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  params.TitleX := HU_TITLEX{$IFDEF OPENGL} * V_GetScreenWidth(SCN_FG) div 200{$ENDIF};
{$ELSE}
  params.TitleX := HU_TITLEX;
{$ENDIF}
  params.TitleY := HU_TITLEY;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  params.LevelTimeX := HU_LEVELTIMEX{$IFDEF OPENGL} * V_GetScreenWidth(SCN_FG) div 200{$ENDIF};
{$ELSE}
  params.LevelTimeX := HU_LEVELTIMEX;
{$ENDIF}
  params.LevelTimeY := HU_LEVELTIMEY;
  params.InputX := HU_INPUTX;
  params.InputY := HU_INPUTY;
  params.Title := s;
  GHeadsUp.Start(params);
{$IFDEF STRIFE}

  // haleyjd 09/18/10: [STRIFE] nickname weirdness.
  if nickname <> player_names[consoleplayer] then
    if nickname <> '' then
    begin
      printf('have one'#13#10);
      nickname := player_names[consoleplayer];
    end;
{$ENDIF}
end;
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}

{$IFDEF OPENGL}

//==============================================================================
//
// HU_Height
//
//==============================================================================
function HU_Height: integer;
begin
  HU_CheckConfigured;
  result := GScreen.Height;
end;
{$ENDIF}
{$ENDIF}
{$IFDEF STRIFE}

//==============================================================================
//
// HU_DrawYellowText
//
//==============================================================================
procedure HU_DrawYellowText(x, y: integer; const txt: string; const scn: integer);
begin
  HU_CheckConfigured;
  GScreen.DrawYellowText(x, y, txt, scn);
end;
{$ENDIF}

//==============================================================================
//
// HU_Drawer
//
//==============================================================================
procedure HU_Drawer;
begin
  HU_CheckConfigured;
  GScreen.Draw;
end;

//==============================================================================
//
// HU_Erase
//
//==============================================================================
procedure HU_Erase;
begin
  HU_CheckConfigured;
  GScreen.Erase;
end;

//==============================================================================
//
// HU_Ticker
//
//==============================================================================
procedure HU_Ticker;
begin
  HU_CheckConfigured;
  GHeadsUp.Ticker;
end;

//==============================================================================
//
// HU_dequeueChatChar
//
//==============================================================================
function HU_dequeueChatChar: char;
begin
  HU_CheckConfigured;
  result := GHeadsUp.DequeueChatChar;
end;

//==============================================================================
//
// HU_Responder
//
//==============================================================================
function HU_Responder(ev: Pevent_t): boolean;
begin
  HU_CheckConfigured;
  result := GHeadsUp.Responder(ev.data1, ev._type = ev_keydown);
end;

initialization
  chat_macros[0] := HUSTR_CHATMACRO0;
  chat_macros[1] := HUSTR_CHATMACRO1;
  chat_macros[2] := HUSTR_CHATMACRO2;
  chat_macros[3] := HUSTR_CHATMACRO3;
  chat_macros[4] := HUSTR_CHATMACRO4;
  chat_macros[5] := HUSTR_CHATMACRO5;
  chat_macros[6] := HUSTR_CHATMACRO6;
  chat_macros[7] := HUSTR_CHATMACRO7;
  chat_macros[8] := HUSTR_CHATMACRO8;
  chat_macros[9] := HUSTR_CHATMACRO9;

{$IFDEF STRIFE}
  player_names[0] := HUSTR_PLAYER1;
  player_names[1] := HUSTR_PLAYER2;
  player_names[2] := HUSTR_PLAYER3;
  player_names[3] := HUSTR_PLAYER4;
  player_names[4] := HUSTR_PLAYER5;
  player_names[5] := HUSTR_PLAYER6;
  player_names[6] := HUSTR_PLAYER7;
  player_names[7] := HUSTR_PLAYER8;
{$ELSE}
  player_names[0] := HUSTR_PLRGREEN;
  player_names[1] := HUSTR_PLRINDIGO;
  player_names[2] := HUSTR_PLRBROWN;
  player_names[3] := HUSTR_PLRRED;
{$ENDIF}

{$IF DEFINED(HERETIC)}

////////////////////////////////////////////////////////////////////////////////
//
// Builtin map names.
// The actual names can be found in h_strings.pas
//
////////////////////////////////////////////////////////////////////////////////

// DOOM shareware/registered/retail (Ultimate) names.

  mapnames[0] := HUSTR_E1M1;
  mapnames[1] := HUSTR_E1M2;
  mapnames[2] := HUSTR_E1M3;
  mapnames[3] := HUSTR_E1M4;
  mapnames[4] := HUSTR_E1M5;
  mapnames[5] := HUSTR_E1M6;
  mapnames[6] := HUSTR_E1M7;
  mapnames[7] := HUSTR_E1M8;
  mapnames[8] := HUSTR_E1M9;

  mapnames[9] := HUSTR_E2M1;
  mapnames[10] := HUSTR_E2M2;
  mapnames[11] := HUSTR_E2M3;
  mapnames[12] := HUSTR_E2M4;
  mapnames[13] := HUSTR_E2M5;
  mapnames[14] := HUSTR_E2M6;
  mapnames[15] := HUSTR_E2M7;
  mapnames[16] := HUSTR_E2M8;
  mapnames[17] := HUSTR_E2M9;

  mapnames[18] := HUSTR_E3M1;
  mapnames[19] := HUSTR_E3M2;
  mapnames[20] := HUSTR_E3M3;
  mapnames[21] := HUSTR_E3M4;
  mapnames[22] := HUSTR_E3M5;
  mapnames[23] := HUSTR_E3M6;
  mapnames[24] := HUSTR_E3M7;
  mapnames[25] := HUSTR_E3M8;
  mapnames[26] := HUSTR_E3M9;

  mapnames[27] := HUSTR_E4M1;
  mapnames[28] := HUSTR_E4M2;
  mapnames[29] := HUSTR_E4M3;
  mapnames[30] := HUSTR_E4M4;
  mapnames[31] := HUSTR_E4M5;
  mapnames[32] := HUSTR_E4M6;
  mapnames[33] := HUSTR_E4M7;
  mapnames[34] := HUSTR_E4M8;
  mapnames[35] := HUSTR_E4M9;

  mapnames[36] := HUSTR_E5M1;
  mapnames[37] := HUSTR_E5M2;
  mapnames[38] := HUSTR_E5M3;
  mapnames[39] := HUSTR_E5M4;
  mapnames[40] := HUSTR_E5M5;
  mapnames[41] := HUSTR_E5M6;
  mapnames[42] := HUSTR_E5M7;
  mapnames[43] := HUSTR_E5M8;
  mapnames[44] := HUSTR_E5M9;

////////////////////////////////////////////////////////////////////////////////

  destination_keys[0] := HUSTR_KEYGREEN;
  destination_keys[1] := HUSTR_KEYINDIGO;
  destination_keys[2] := HUSTR_KEYBROWN;
  destination_keys[3] := HUSTR_KEYRED;
{$ELSEIF DEFINED(HEXEN)}
  destination_keys[0] := HUSTR_KEYGREEN;
  destination_keys[1] := HUSTR_KEYINDIGO;
  destination_keys[2] := HUSTR_KEYBROWN;
  destination_keys[3] := HUSTR_KEYRED;
{$ELSEIF DEFINED(STRIFE)}
////////////////////////////////////////////////////////////////////////////////
//
// Builtin map names.
// The actual names can be found in DStrings.h.
//
////////////////////////////////////////////////////////////////////////////////

// STRIFE map names.

  mapnames[0] := HUSTR_1;
  mapnames[1] := HUSTR_2;
  mapnames[2] := HUSTR_3;
  mapnames[3] := HUSTR_4;
  mapnames[4] := HUSTR_5;
  mapnames[5] := HUSTR_6;
  mapnames[6] := HUSTR_7;
  mapnames[7] := HUSTR_8;
  mapnames[8] := HUSTR_9;
  mapnames[9] := HUSTR_10;
  mapnames[10] := HUSTR_11;

  mapnames[11] := HUSTR_12;
  mapnames[12] := HUSTR_13;
  mapnames[13] := HUSTR_14;
  mapnames[14] := HUSTR_15;
  mapnames[15] := HUSTR_16;
  mapnames[16] := HUSTR_17;
  mapnames[17] := HUSTR_18;
  mapnames[18] := HUSTR_19;
  mapnames[19] := HUSTR_20;

  mapnames[20] := HUSTR_21;
  mapnames[21] := HUSTR_22;
  mapnames[22] := HUSTR_23;
  mapnames[23] := HUSTR_24;
  mapnames[24] := HUSTR_25;
  mapnames[25] := HUSTR_26;
  mapnames[26] := HUSTR_27;
  mapnames[27] := HUSTR_28;
  mapnames[28] := HUSTR_29;
  mapnames[29] := HUSTR_30;
  mapnames[30] := HUSTR_31;
  mapnames[31] := HUSTR_32;
  mapnames[32] := HUSTR_33;
  mapnames[33] := HUSTR_34;

////////////////////////////////////////////////////////////////////////////////

  key_multi_msgplayer[0] := '1';
  key_multi_msgplayer[1] := '2';
  key_multi_msgplayer[2] := '3';
  key_multi_msgplayer[3] := '4';
  key_multi_msgplayer[4] := '5';
  key_multi_msgplayer[5] := '6';
  key_multi_msgplayer[6] := '7';
  key_multi_msgplayer[7] := '8';
{$ELSE}
////////////////////////////////////////////////////////////////////////////////
//
// Builtin map names.
// The actual names can be found in DStrings.h.
//
////////////////////////////////////////////////////////////////////////////////

// DOOM shareware/registered/retail (Ultimate) names.

  mapnames[0] := HUSTR_E1M1;
  mapnames[1] := HUSTR_E1M2;
  mapnames[2] := HUSTR_E1M3;
  mapnames[3] := HUSTR_E1M4;
  mapnames[4] := HUSTR_E1M5;
  mapnames[5] := HUSTR_E1M6;
  mapnames[6] := HUSTR_E1M7;
  mapnames[7] := HUSTR_E1M8;
  mapnames[8] := HUSTR_E1M9;

  mapnames[9] := HUSTR_E2M1;
  mapnames[10] := HUSTR_E2M2;
  mapnames[11] := HUSTR_E2M3;
  mapnames[12] := HUSTR_E2M4;
  mapnames[13] := HUSTR_E2M5;
  mapnames[14] := HUSTR_E2M6;
  mapnames[15] := HUSTR_E2M7;
  mapnames[16] := HUSTR_E2M8;
  mapnames[17] := HUSTR_E2M9;

  mapnames[18] := HUSTR_E3M1;
  mapnames[19] := HUSTR_E3M2;
  mapnames[20] := HUSTR_E3M3;
  mapnames[21] := HUSTR_E3M4;
  mapnames[22] := HUSTR_E3M5;
  mapnames[23] := HUSTR_E3M6;
  mapnames[24] := HUSTR_E3M7;
  mapnames[25] := HUSTR_E3M8;
  mapnames[26] := HUSTR_E3M9;

  mapnames[27] := HUSTR_E4M1;
  mapnames[28] := HUSTR_E4M2;
  mapnames[29] := HUSTR_E4M3;
  mapnames[30] := HUSTR_E4M4;
  mapnames[31] := HUSTR_E4M5;
  mapnames[32] := HUSTR_E4M6;
  mapnames[33] := HUSTR_E4M7;
  mapnames[34] := HUSTR_E4M8;
  mapnames[35] := HUSTR_E4M9;

  mapnames[36] := 'NEWLEVEL';
  mapnames[37] := mapnames[36];
  mapnames[38] := mapnames[36];
  mapnames[39] := mapnames[36];
  mapnames[40] := mapnames[36];
  mapnames[41] := mapnames[36];
  mapnames[42] := mapnames[36];
  mapnames[43] := mapnames[36];
  mapnames[44] := mapnames[36];

////////////////////////////////////////////////////////////////////////////////

// DOOM 2 map names.

  mapnames2[0] := HUSTR_1;
  mapnames2[1] := HUSTR_2;
  mapnames2[2] := HUSTR_3;
  mapnames2[3] := HUSTR_4;
  mapnames2[4] := HUSTR_5;
  mapnames2[5] := HUSTR_6;
  mapnames2[6] := HUSTR_7;
  mapnames2[7] := HUSTR_8;
  mapnames2[8] := HUSTR_9;
  mapnames2[9] := HUSTR_10;
  mapnames2[10] := HUSTR_11;

  mapnames2[11] := HUSTR_12;
  mapnames2[12] := HUSTR_13;
  mapnames2[13] := HUSTR_14;
  mapnames2[14] := HUSTR_15;
  mapnames2[15] := HUSTR_16;
  mapnames2[16] := HUSTR_17;
  mapnames2[17] := HUSTR_18;
  mapnames2[18] := HUSTR_19;
  mapnames2[19] := HUSTR_20;

  mapnames2[20] := HUSTR_21;
  mapnames2[21] := HUSTR_22;
  mapnames2[22] := HUSTR_23;
  mapnames2[23] := HUSTR_24;
  mapnames2[24] := HUSTR_25;
  mapnames2[25] := HUSTR_26;
  mapnames2[26] := HUSTR_27;
  mapnames2[27] := HUSTR_28;
  mapnames2[28] := HUSTR_29;
  mapnames2[29] := HUSTR_30;
  mapnames2[30] := HUSTR_31;
  mapnames2[31] := HUSTR_32;
  mapnames2[32] := HUSTR_33;

////////////////////////////////////////////////////////////////////////////////

// Plutonia WAD map names.

  mapnamesp[0] := PHUSTR_1;
  mapnamesp[1] := PHUSTR_2;
  mapnamesp[2] := PHUSTR_3;
  mapnamesp[3] := PHUSTR_4;
  mapnamesp[4] := PHUSTR_5;
  mapnamesp[5] := PHUSTR_6;
  mapnamesp[6] := PHUSTR_7;
  mapnamesp[7] := PHUSTR_8;
  mapnamesp[8] := PHUSTR_9;
  mapnamesp[9] := PHUSTR_10;
  mapnamesp[10] := PHUSTR_11;

  mapnamesp[11] := PHUSTR_12;
  mapnamesp[12] := PHUSTR_13;
  mapnamesp[13] := PHUSTR_14;
  mapnamesp[14] := PHUSTR_15;
  mapnamesp[15] := PHUSTR_16;
  mapnamesp[16] := PHUSTR_17;
  mapnamesp[17] := PHUSTR_18;
  mapnamesp[18] := PHUSTR_19;
  mapnamesp[19] := PHUSTR_20;

  mapnamesp[20] := PHUSTR_21;
  mapnamesp[21] := PHUSTR_22;
  mapnamesp[22] := PHUSTR_23;
  mapnamesp[23] := PHUSTR_24;
  mapnamesp[24] := PHUSTR_25;
  mapnamesp[25] := PHUSTR_26;
  mapnamesp[26] := PHUSTR_27;
  mapnamesp[27] := PHUSTR_28;
  mapnamesp[28] := PHUSTR_29;
  mapnamesp[29] := PHUSTR_30;
  mapnamesp[30] := PHUSTR_31;
  mapnamesp[31] := PHUSTR_32;

////////////////////////////////////////////////////////////////////////////////

// TNT WAD map names.

  mapnamest[0] := THUSTR_1;
  mapnamest[1] := THUSTR_2;
  mapnamest[2] := THUSTR_3;
  mapnamest[3] := THUSTR_4;
  mapnamest[4] := THUSTR_5;
  mapnamest[5] := THUSTR_6;
  mapnamest[6] := THUSTR_7;
  mapnamest[7] := THUSTR_8;
  mapnamest[8] := THUSTR_9;
  mapnamest[9] := THUSTR_10;
  mapnamest[10] := THUSTR_11;

  mapnamest[11] := THUSTR_12;
  mapnamest[12] := THUSTR_13;
  mapnamest[13] := THUSTR_14;
  mapnamest[14] := THUSTR_15;
  mapnamest[15] := THUSTR_16;
  mapnamest[16] := THUSTR_17;
  mapnamest[17] := THUSTR_18;
  mapnamest[18] := THUSTR_19;
  mapnamest[19] := THUSTR_20;

  mapnamest[20] := THUSTR_21;
  mapnamest[21] := THUSTR_22;
  mapnamest[22] := THUSTR_23;
  mapnamest[23] := THUSTR_24;
  mapnamest[24] := THUSTR_25;
  mapnamest[25] := THUSTR_26;
  mapnamest[26] := THUSTR_27;
  mapnamest[27] := THUSTR_28;
  mapnamest[28] := THUSTR_29;
  mapnamest[29] := THUSTR_30;
  mapnamest[30] := THUSTR_31;
  mapnamest[31] := THUSTR_32;

////////////////////////////////////////////////////////////////////////////////

  destination_keys[0] := HUSTR_KEYGREEN;
  destination_keys[1] := HUSTR_KEYINDIGO;
  destination_keys[2] := HUSTR_KEYBROWN;
  destination_keys[3] := HUSTR_KEYRED;
{$ENDIF}

end.

