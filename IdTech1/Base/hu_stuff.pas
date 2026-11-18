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
{$IF DEFINED(HERETIC)}
  h_strings,
{$ELSEIF DEFINED(HEXEN)}
  xn_strings,
{$ELSE}
  d_englsh,
{$ENDIF}
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
  mapnames: array[0..44] of string = (
    HUSTR_E1M1, HUSTR_E1M2, HUSTR_E1M3, HUSTR_E1M4,
    HUSTR_E1M5, HUSTR_E1M6, HUSTR_E1M7, HUSTR_E1M8,
    HUSTR_E1M9, HUSTR_E2M1, HUSTR_E2M2, HUSTR_E2M3,
    HUSTR_E2M4, HUSTR_E2M5, HUSTR_E2M6, HUSTR_E2M7,
    HUSTR_E2M8, HUSTR_E2M9, HUSTR_E3M1, HUSTR_E3M2,
    HUSTR_E3M3, HUSTR_E3M4, HUSTR_E3M5, HUSTR_E3M6,
    HUSTR_E3M7, HUSTR_E3M8, HUSTR_E3M9, HUSTR_E4M1,
    HUSTR_E4M2, HUSTR_E4M3, HUSTR_E4M4, HUSTR_E4M5,
    HUSTR_E4M6, HUSTR_E4M7, HUSTR_E4M8, HUSTR_E4M9,
    HUSTR_E5M1, HUSTR_E5M2, HUSTR_E5M3, HUSTR_E5M4,
    HUSTR_E5M5, HUSTR_E5M6, HUSTR_E5M7, HUSTR_E5M8,
    HUSTR_E5M9);

  player_names: array[0..3] of string;
{$ELSEIF DEFINED(HEXEN)}
var
  player_names: array[0..3] of string;
{$ELSEIF DEFINED(STRIFE)}
var
// STRIFE MAP NAMES
  mapnames: array[0..33] of string = (
    HUSTR_1, HUSTR_2, HUSTR_3, HUSTR_4,
    HUSTR_5, HUSTR_6, HUSTR_7, HUSTR_8,
    HUSTR_9, HUSTR_10, HUSTR_11, HUSTR_12,
    HUSTR_13, HUSTR_14, HUSTR_15, HUSTR_16,
    HUSTR_17, HUSTR_18, HUSTR_19, HUSTR_20,
    HUSTR_21, HUSTR_22, HUSTR_23, HUSTR_24,
    HUSTR_25, HUSTR_26, HUSTR_27, HUSTR_28,
    HUSTR_29, HUSTR_30, HUSTR_31, HUSTR_32,
    HUSTR_33, HUSTR_34);

  player_names: array[0..7] of string;
{$ELSE}
const
  NUM_MAPNAMES = 45;
  NUM_MAPNAMES2 = 33;
  NUM_MAPNAMESP = 32;
  NUM_MAPNAMEST = 32;

var
// DOOM shareware/registered/retail (Ultimate) names.
  mapnames: array[0..NUM_MAPNAMES - 1] of string = (
    HUSTR_E1M1, HUSTR_E1M2, HUSTR_E1M3, HUSTR_E1M4,
    HUSTR_E1M5, HUSTR_E1M6, HUSTR_E1M7, HUSTR_E1M8,
    HUSTR_E1M9, HUSTR_E2M1, HUSTR_E2M2, HUSTR_E2M3,
    HUSTR_E2M4, HUSTR_E2M5, HUSTR_E2M6, HUSTR_E2M7,
    HUSTR_E2M8, HUSTR_E2M9, HUSTR_E3M1, HUSTR_E3M2,
    HUSTR_E3M3, HUSTR_E3M4, HUSTR_E3M5, HUSTR_E3M6,
    HUSTR_E3M7, HUSTR_E3M8, HUSTR_E3M9, HUSTR_E4M1,
    HUSTR_E4M2, HUSTR_E4M3, HUSTR_E4M4, HUSTR_E4M5,
    HUSTR_E4M6, HUSTR_E4M7, HUSTR_E4M8, HUSTR_E4M9,
    'NEWLEVEL', 'NEWLEVEL', 'NEWLEVEL', 'NEWLEVEL',
    'NEWLEVEL', 'NEWLEVEL', 'NEWLEVEL', 'NEWLEVEL',
    'NEWLEVEL');

// DOOM 2 map names.
  mapnames2: array[0..NUM_MAPNAMES2 - 1] of string = (
    HUSTR_1, HUSTR_2, HUSTR_3, HUSTR_4,
    HUSTR_5, HUSTR_6, HUSTR_7, HUSTR_8,
    HUSTR_9, HUSTR_10, HUSTR_11, HUSTR_12,
    HUSTR_13, HUSTR_14, HUSTR_15, HUSTR_16,
    HUSTR_17, HUSTR_18, HUSTR_19, HUSTR_20,
    HUSTR_21, HUSTR_22, HUSTR_23, HUSTR_24,
    HUSTR_25, HUSTR_26, HUSTR_27, HUSTR_28,
    HUSTR_29, HUSTR_30, HUSTR_31, HUSTR_32,
    HUSTR_33);

// Plutonia WAD map names.
  mapnamesp: array[0..NUM_MAPNAMESP - 1] of string = (
    PHUSTR_1, PHUSTR_2, PHUSTR_3, PHUSTR_4,
    PHUSTR_5, PHUSTR_6, PHUSTR_7, PHUSTR_8,
    PHUSTR_9, PHUSTR_10, PHUSTR_11, PHUSTR_12,
    PHUSTR_13, PHUSTR_14, PHUSTR_15, PHUSTR_16,
    PHUSTR_17, PHUSTR_18, PHUSTR_19, PHUSTR_20,
    PHUSTR_21, PHUSTR_22, PHUSTR_23, PHUSTR_24,
    PHUSTR_25, PHUSTR_26, PHUSTR_27, PHUSTR_28,
    PHUSTR_29, PHUSTR_30, PHUSTR_31, PHUSTR_32);

// TNT WAD map names.
  mapnamest: array[0..NUM_MAPNAMEST - 1] of string = (
    THUSTR_1, THUSTR_2, THUSTR_3, THUSTR_4,
    THUSTR_5, THUSTR_6, THUSTR_7, THUSTR_8,
    THUSTR_9, THUSTR_10, THUSTR_11, THUSTR_12,
    THUSTR_13, THUSTR_14, THUSTR_15, THUSTR_16,
    THUSTR_17, THUSTR_18, THUSTR_19, THUSTR_20,
    THUSTR_21, THUSTR_22, THUSTR_23, THUSTR_24,
    THUSTR_25, THUSTR_26, THUSTR_27, THUSTR_28,
    THUSTR_29, THUSTR_30, THUSTR_31, THUSTR_32);

  player_names: array[0..3] of string;
{$ENDIF}

var
  chat_macros: array[0..9] of string = (
    HUSTR_CHATMACRO0, HUSTR_CHATMACRO1, HUSTR_CHATMACRO2, HUSTR_CHATMACRO3,
    HUSTR_CHATMACRO4, HUSTR_CHATMACRO5, HUSTR_CHATMACRO6, HUSTR_CHATMACRO7,
    HUSTR_CHATMACRO8, HUSTR_CHATMACRO9);

var
{$IFDEF STRIFE}
  key_multi_msgplayer: array[0..MAXPLAYERS - 1] of string = (
    '1', '2', '3', '4',
    '5', '6', '7', '8');
{$ELSE}
  destination_keys: array[0..MAXPLAYERS - 1] of string;
{$ENDIF}

var
  shiftxform: array[0..127] of Char;

var
  drawfps: boolean;
  drawcrosshair: boolean;
{$IF DEFINED(DOOM)}
  amdrawstats: boolean;
{$ENDIF}

type
  /// <summary>
  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #185,
  ///   wave 11): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  THudRoutines = class sealed
  public
    //==============================================================================
    //
    // HU_Configure
    //
    // The heads-up display is IdTech1\Hud (the model) and DelphiDoom.Engine.Hud.* (the
    // drawing): ComposeEngine gives them here. Without it HU_Init stops with I_Error.
    //
    //==============================================================================
    class procedure HU_Configure(const AHeadsUp: IHeadsUp; const AScreen: IHudScreen); static;

    //==============================================================================
    // HU_Init
    //
    // HEADS UP TEXT
    //
    //==============================================================================
    class procedure HU_Init; static;

    //==============================================================================
    //
    // HU_Start
    //
    //==============================================================================
    class procedure HU_Start; static;

    //==============================================================================
    //
    // HU_Responder
    //
    //==============================================================================
    class function HU_Responder(ev: Pevent_t): boolean; static;

    //==============================================================================
    //
    // HU_Ticker
    //
    //==============================================================================
    class procedure HU_Ticker; static;

    //==============================================================================
    //
    // HU_Drawer
    //
    //==============================================================================
    class procedure HU_Drawer; static;

{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
{$IFDEF OPENGL}
    //==============================================================================
    //
    // HU_Height
    //
    //==============================================================================
    class function HU_Height: integer; static;

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
    class procedure HU_DrawYellowText(x, y: integer; const txt: string; const scn: integer); static;

{$ENDIF}

    //==============================================================================
    //
    // HU_dequeueChatChar
    //
    //==============================================================================
    class function HU_dequeueChatChar: char; static;

    //==============================================================================
    //
    // HU_Erase
    //
    //==============================================================================
    class procedure HU_Erase; static;

    //==============================================================================
    //
    // HU_DoFPSStuff
    //
    //==============================================================================
    class procedure HU_DoFPSStuff; static;

    //==============================================================================
    //
    // HU_FPS
    //
    //==============================================================================
    class function HU_FPS: integer; static;

    //==============================================================================
    //
    // HU_TITLE
    //
    //==============================================================================
    class function HU_TITLE: string; static;
  end;


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

// The heads-up display (issue #185, slice 1a): the model is in IdTech1\Hud (THeadsUp) and
// the drawing in DelphiDoom.Engine.Hud.Drawer. What stays here is what is tied to the
// globals that other units own: the fonts and their loading, the tables of names that the
// Dehacked patches change, chat_on and message_dontfuckwithme (the menu writes them), the
// geometry of the widgets (it reads the fonts and the screen) and the routines that call.
var
  GHeadsUp: IHeadsUp = nil;
  GScreen: IHudScreen = nil;

type
  /// <summary>
  ///   The routines that only this unit calls, as static methods with the text and the names of the old free routines
  ///   (issue #185, wave 12): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  THudLocalRoutines = class sealed
  public
    class procedure HU_CheckConfigured; static;
    class procedure HU_CmdFPS; static;
    class procedure HU_CmdPlayerMessage(const parm1, parm2: string); static;
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN) OR DEFINED(STRIFE))}
    class function HU_TITLE2: string; static;
    class function HU_TITLEP: string; static;
    class function HU_TITLET: string; static;
{$ENDIF}
    class function HU_TITLEY: integer; static;
    class function HU_LEVELTIMEY: integer; static;
    class function HU_INPUTX: integer; static;
    class function HU_INPUTY: integer; static;
  end;
//==============================================================================
//
// HU_Configure
//
//==============================================================================
class procedure THudRoutines.HU_Configure(const AHeadsUp: IHeadsUp; const AScreen: IHudScreen);
begin
  GHeadsUp := AHeadsUp;
  GScreen := AScreen;
end;

//==============================================================================
//
// HU_CheckConfigured
//
//==============================================================================
class procedure THudLocalRoutines.HU_CheckConfigured;
begin
  if (GHeadsUp = nil) or (GScreen = nil) then
    I_Error('HU_CheckConfigured(): the heads-up display is not configured (HU_Configure)');
end;

//==============================================================================
//
// HU_DoFPSStuff
//
//==============================================================================
class procedure THudRoutines.HU_DoFPSStuff;
begin
  THudLocalRoutines.HU_CheckConfigured;
  GHeadsUp.RecordFrameTime(I_GetFracTime);
end;

//==============================================================================
//
// HU_FPS
//
//==============================================================================
class function THudRoutines.HU_FPS: integer;
begin
  THudLocalRoutines.HU_CheckConfigured;
  result := GHeadsUp.FramesPerSecond;
end;

//==============================================================================
//
// HU_CmdFPS
//
//==============================================================================
class procedure THudLocalRoutines.HU_CmdFPS;
begin
  printf('%d fps'#13#10, [THudRoutines.HU_FPS]);
end;

//==============================================================================
//
// HU_CmdPlayerMessage
//
//==============================================================================
class procedure THudLocalRoutines.HU_CmdPlayerMessage(const parm1, parm2: string);
begin
  TGameSession.Players[TGameSession.ConsolePlayer]._message := parm1 + ' ' + parm2;
end;

//==============================================================================
//
// HU_TITLE
//
//==============================================================================
class function THudRoutines.HU_TITLE: string;
begin
{$IF DEFINED(HERETIC)}
  result := mapnames[(TGameSession.GameEpisode - 1) * 9 + TGameSession.GameMap - 1];
{$ELSEIF DEFINED(HEXEN)}
  result := P_GetMapDescName(TGameSession.GameMap);
{$ELSEIF DEFINED(STRIFE)}
  result := mapnames[TGameSession.GameMap - 1];
{$ELSE}
  result := THudMapTitle.ForEpisode(mapnames, TGameSession.GameEpisode, TGameSession.GameMap);
{$ENDIF}
end;
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN) OR DEFINED(STRIFE))}

//==============================================================================
//
// HU_TITLE2
//
//==============================================================================
class function THudLocalRoutines.HU_TITLE2: string;
begin
  result := THudMapTitle.ForMap(mapnames2, TGameSession.GameMap);
end;

//==============================================================================
//
// HU_TITLEP
//
//==============================================================================
class function THudLocalRoutines.HU_TITLEP: string;
begin
  result := THudMapTitle.ForMap(mapnamesp, TGameSession.GameMap);
end;

//==============================================================================
//
// HU_TITLET
//
//==============================================================================
class function THudLocalRoutines.HU_TITLET: string;
begin
  result := THudMapTitle.ForMap(mapnamest, TGameSession.GameMap);
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
class function THudLocalRoutines.HU_TITLEY: integer;
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
class function THudLocalRoutines.HU_LEVELTIMEY: integer;
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
class function THudLocalRoutines.HU_INPUTX: integer;
begin
  result := HU_MSGX;
end;

//==============================================================================
//
// HU_INPUTY
//
//==============================================================================
class function THudLocalRoutines.HU_INPUTY: integer;
begin
  result := HU_MSGY + HU_MSGHEIGHT * (hu_font[0].height + 1)
end;

//==============================================================================
//
// HU_Init
//
//==============================================================================
class procedure THudRoutines.HU_Init;
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
  THudLocalRoutines.HU_CheckConfigured;

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
    hu_font[i - 1] := TWadRoutines.W_CacheLumpName(buffer, PU_STATIC);
  end;

  for i := 1 to HU_FONTSIZE - 1 do
  begin
    buffer := 'FONTB' + IntToStrZfill(2, i);
    hu_font2[i - 1] := TWadRoutines.W_CacheLumpName(buffer, PU_STATIC);
  end;

  for i := 1 to HU_CFONTSIZE do
  begin
    buffer := 'FONTC' + IntToStrZfill(2, i);
    lump := TWadRoutines.W_CheckNumForName(buffer);
    if lump >= 0 then
      hu_font3[i - 1] := TWadRoutines.W_CacheLumpNum(lump, PU_STATIC)
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
    hu_font4[i - 1] := TWadRoutines.W_CacheLumpName(buffer, PU_STATIC);
{$ELSEIF DEFINED(HEXEN)}
    buffer := 'FONTA' + IntToStrZfill(2, i);
    hu_font[i - 1] := TWadRoutines.W_CacheLumpName(buffer, PU_STATIC);
  end;

  // Yellow bold fonts
  for i := 1 to HU_FONTSIZE - 1 do
  begin
    buffer := 'FONTAY' + IntToStrZfill(2, i);
    hu_fonty[i - 1] := TWadRoutines.W_CacheLumpName(buffer, PU_STATIC);
  end;

  for i := 1 to HU_FONTSIZE - 1 do
  begin
    buffer := 'FONTB' + IntToStrZfill(2, i);
    hu_font2[i - 1] := TWadRoutines.W_CacheLumpName(buffer, PU_STATIC);
  end;

  for i := 1 to HU_CFONTSIZE do
  begin
    buffer := 'FONTC' + IntToStrZfill(2, i);
    lump := TWadRoutines.W_CheckNumForName(buffer);
    if lump >= 0 then
      hu_font3[i - 1] := TWadRoutines.W_CacheLumpNum(lump, PU_STATIC)
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
    hu_font[i] := TWadRoutines.W_CacheLumpName(buffer, PU_STATIC);
    // haleyjd 09/18/10: load yfont as well; and yes, this is exactly
    // how Rogue did it :P
    buffer[3] := 'B';
    yfont[i] := TWadRoutines.W_CacheLumpName(buffer, PU_STATIC);
{$ELSEIF DEFINED(RADIX)}
    // the small font of RADIX.DAT; a character it does not have is the empty sprite
    buffer := 'FNTA';
    hu_font[i] := TWadRoutines.W_CacheLumpNum(RX_FontLumpNum(buffer, j), PU_STATIC);
    inc(j);
{$ELSE}
    buffer := 'STCFN' + IntToStrZfill(3, j);
    inc(j);
    hu_font[i] := TWadRoutines.W_CacheLumpName(buffer, PU_STATIC);
{$ENDIF}
  end;
{$IFDEF STRIFE}

  for c := 'A' to 'Z' do
    m_font3[c] := TWadRoutines.W_CacheLumpName('FONT3_' + c, PU_STATIC);
  m_font3[Chr(Ord('Z') + 1)] := TWadRoutines.W_CacheLumpName('FONT3_!', PU_STATIC);
{$ENDIF}
{$IFDEF RADIX}

  RX_InitFonts;
{$ENDIF}


  // the widths of the glyphs and the crosshairs
  GScreen.Initialize;

  C_AddCmd('fps', @THudLocalRoutines.HU_CmdFPS);
  C_AddCmd('playermessage', @THudLocalRoutines.HU_CmdPlayerMessage);
end;

//==============================================================================
//
// HU_Start
//
//==============================================================================
class procedure THudRoutines.HU_Start;
var
  params: THudStartParams;
  s: string;
begin
  THudLocalRoutines.HU_CheckConfigured;

{$IF DEFINED(DOOM)}
  if (TGameSession.GameMapInfo <> nil) and (TGameSession.GameMapInfo.levelname <> '') then
    s := THudMapTitle.FromMapInfo(TGameSession.GameMapInfo.mapname, TGameSession.GameMapInfo.mlabel, TGameSession.GameMapInfo.levelname)
  else
  begin
    case gamemode of
      shareware,
      registered,
      retail: s := HU_TITLE;
    else
      begin
        case gamemission of
          pack_tnt: s := THudLocalRoutines.HU_TITLET;
          pack_plutonia: s := THudLocalRoutines.HU_TITLEP;
        else
          s := THudLocalRoutines.HU_TITLE2;
        end;
      end;
    end;
  end;
{$ELSEIF DEFINED(HERETIC)}
  if (TGameSession.GameMapInfo <> nil) and (TGameSession.GameMapInfo.levelname <> '') then
    s := THudMapTitle.FromMapInfo(TGameSession.GameMapInfo.mapname, TGameSession.GameMapInfo.mlabel, TGameSession.GameMapInfo.levelname)
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
  params.TitleY := THudLocalRoutines.HU_TITLEY;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  params.LevelTimeX := HU_LEVELTIMEX{$IFDEF OPENGL} * V_GetScreenWidth(SCN_FG) div 200{$ENDIF};
{$ELSE}
  params.LevelTimeX := HU_LEVELTIMEX;
{$ENDIF}
  params.LevelTimeY := THudLocalRoutines.HU_LEVELTIMEY;
  params.InputX := THudLocalRoutines.HU_INPUTX;
  params.InputY := THudLocalRoutines.HU_INPUTY;
  params.Title := s;
  GHeadsUp.Start(params);
{$IFDEF STRIFE}

  // haleyjd 09/18/10: [STRIFE] nickname weirdness.
  if nickname <> player_names[TGameSession.ConsolePlayer] then
    if nickname <> '' then
    begin
      printf('have one'#13#10);
      nickname := player_names[TGameSession.ConsolePlayer];
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
class function THudRoutines.HU_Height: integer;
begin
  THudLocalRoutines.HU_CheckConfigured;
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
class procedure THudRoutines.HU_DrawYellowText(x, y: integer; const txt: string; const scn: integer);
begin
  THudLocalRoutines.HU_CheckConfigured;
  GScreen.DrawYellowText(x, y, txt, scn);
end;
{$ENDIF}

//==============================================================================
//
// HU_Drawer
//
//==============================================================================
class procedure THudRoutines.HU_Drawer;
begin
  THudLocalRoutines.HU_CheckConfigured;
  GScreen.Draw;
end;

//==============================================================================
//
// HU_Erase
//
//==============================================================================
class procedure THudRoutines.HU_Erase;
begin
  THudLocalRoutines.HU_CheckConfigured;
  GScreen.Erase;
end;

//==============================================================================
//
// HU_Ticker
//
//==============================================================================
class procedure THudRoutines.HU_Ticker;
begin
  THudLocalRoutines.HU_CheckConfigured;
  GHeadsUp.Ticker;
end;

//==============================================================================
//
// HU_dequeueChatChar
//
//==============================================================================
class function THudRoutines.HU_dequeueChatChar: char;
begin
  THudLocalRoutines.HU_CheckConfigured;
  result := GHeadsUp.DequeueChatChar;
end;

//==============================================================================
//
// HU_Responder
//
//==============================================================================
class function THudRoutines.HU_Responder(ev: Pevent_t): boolean;
begin
  THudLocalRoutines.HU_CheckConfigured;
  result := GHeadsUp.Responder(ev.data1, ev._type = ev_keydown);
end;

initialization
  // the names of the maps, the chat macros and the keys of the players of Strife are initialized in the
  // declarations above (issue #185, wave 12); what stays here are the typed constants, which are not constant
  // expressions
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

  destination_keys[0] := HUSTR_KEYGREEN;
  destination_keys[1] := HUSTR_KEYINDIGO;
  destination_keys[2] := HUSTR_KEYBROWN;
  destination_keys[3] := HUSTR_KEYRED;
{$ENDIF}

end.
