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
//  DESCRIPTION:
//   AutoMap module.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit am_map;

interface

uses
  d_delphi,
  z_zone,
  doomdef,
  doomdata,
  d_player,
  r_defs,
  d_event,
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  st_stuff,
{$ENDIF}
  p_local,
{$IFDEF STRIFE}
  tables,
{$ENDIF}
  w_wad,
  m_cheat,
  DelphiDoom.Automap.Types,
  DelphiDoom.Automap.Intf,
{$IF DEFINED(HERETIC)}
  i_system,
  h_strings,
  tables,
{$ELSEIF DEFINED(HEXEN)}
  i_system,
  xn_strings,
  tables,
{$ELSEIF DEFINED(STRIFE)}
  i_system,
{$ELSE}
  tables,
{$ENDIF}
  m_fixed;

const
  AM_MSGHEADER = (Ord('a') shl 24) + (Ord('m') shl 16);
  AM_MSGENTERED = AM_MSGHEADER or (Ord('e') shl 8);
  AM_MSGEXITED = AM_MSGHEADER or (Ord('x') shl 8);

const
{$IF DEFINED(HERETIC)}
  REDS = 12 * 8;
  REDRANGE = 1;
  BLUES = (256 - (4 * 16)) + 8;
  BLUERANGE = 1;
  GREENS = 216;
  GREENRANGE = 8;
  GRAYS = 5 * 8;
  GRAYSRANGE = 1;
  BROWNS = 14 * 8;
  BROWNRANGE = 1;
  YELLOWS = 10 * 8;
  YELLOWRANGE = 1;
  WHITE = 35;
{$ELSEIF DEFINED(HEXEN)}
  REDS = 12 * 8;
  REDRANGE = 1;
  BLUES = (256 - (4 * 16)) + 8;
  BLUERANGE = 1;
  GREENS = 215;
  GREENRANGE = 2;
  TRACEGREEN = 211;
  GRAYS = 5 * 8;
  GRAYSRANGE = 1;
  BROWNS = 14 * 8;
  BROWNRANGE = 1;
  YELLOWS = 10 * 8;
  YELLOWRANGE = 1;
  WHITE = 255;
{$ELSEIF DEFINED(STRIFE)}

  GRAYS = 1;
  GRAYSRANGE = 15;
{$ELSE}
  REDS = 256 - (5 * 16);
  REDRANGE = 16;
  BLUES = (256 - (4 * 16)) + 8;
  BLUERANGE = 8;
  GREENS = 7 * 16;
  GREENRANGE = 16;
  GRAYS = 6 * 16;
  GRAYSRANGE = 16;
  BROWNS = 4 * 16;
  BROWNRANGE = 16;
  YELLOWS = (256 - 32) + 7;
  YELLOWRANGE = 1;
  WHITE = 256 - 47;
{$ENDIF}

  { Automap colors }
{$IF DEFINED(HEXEN)}
  YOURCOLORS = WHITE;
  WALLCOLORS = 83;
  WALLRANGE = 8;
  TSWALLCOLORS = 40;
  TSWALLRANGE = 8;
  FDWALLCOLORS = 96;
  FDWALLRANGE = 8;
  CDWALLCOLORS = 107;
  CDWALLRANGE = 8;
  THINGCOLORS = GREENS;
  THINGRANGE = GREENRANGE;
  SECRETWALLCOLORS = WALLCOLORS;
  SECRETWALLRANGE = WALLRANGE;
{$ELSEIF DEFINED(STRIFE)}
  BACKGROUND = 240;         // haleyjd [STRIFE]
  WALLCOLORS = 5;           // villsa [STRIFE]
  WALLRANGE = 16;
  TSWALLCOLORS = 16;
  FDWALLCOLORS = 122;       // villsa [STRIFE]
  CDWALLCOLORS = 116;
  CTWALLCOLORS = 19;        // villsa [STRIFE]
  SPWALLCOLORS = 243;       // villsa [STRIFE]
  THINGCOLORS = 233;        // villsa [STRIFE]
  MISSILECOLORS = 227;      // villsa [STRIFE]
  SHOOTABLECOLORS = 235;    // villsa [STRIFE]

// JVAL: We keep grid in DelphiStrife
{$ELSE}
  YOURCOLORS = WHITE;
  WALLCOLORS = REDS;
  WALLRANGE = REDRANGE;
  TSWALLCOLORS = GRAYS;
  TSWALLRANGE = GRAYSRANGE;
  FDWALLCOLORS = BROWNS;
  FDWALLRANGE = BROWNRANGE;
  CDWALLCOLORS = YELLOWS;
  CDWALLRANGE = YELLOWRANGE;
  THINGCOLORS = GREENS;
  THINGRANGE = GREENRANGE;
  SECRETWALLCOLORS = WALLCOLORS;
  SECRETWALLRANGE = WALLRANGE;
{$ENDIF}
  GRIDCOLORS = GRAYS + (GRAYSRANGE div 2);
  XHAIRCOLORS = GRAYS;

  AM_PANDOWNKEY = KEY_DOWNARROW;
  AM_PANUPKEY = KEY_UPARROW;
  AM_PANRIGHTKEY = KEY_RIGHTARROW;
  AM_PANLEFTKEY = KEY_LEFTARROW;
  AM_ZOOMINKEY = '=';
  AM_ZOOMINKEY2 = '+';
  AM_ZOOMOUTKEY = '-';
  AM_TONGLEKEY = KEY_TAB;

var
  AM_GOBIGKEY: integer = Ord('o');
  AM_FOLLOWKEY: integer = Ord('f');
  AM_GRIDKEY: integer = Ord('g');
  AM_ROTATEKEY: integer = Ord('r');
  AM_TEXTUREDAUTOMAP: integer = Ord('t');
  AM_MARKKEY: integer = Ord('m');
  AM_CLEARMARKKEY: integer = Ord('c');

const
  AM_NUMMARKPOINTS = AUTOMAP_MAX_MARKS;

// scale on entry

// how much the automap moves window per tic in frame-buffer coordinates }
// moves 140 pixels in 1 second }
  F_PANINC = 4;

const
  MAPUNIT = AUTOMAP_MAPUNIT;
  FRACTOMAPUNIT = AUTOMAP_FRACTOMAPUNIT;

{ the following is crap }

const
  LINE_NEVERSEE = ML_DONTDRAW;

type
  fpoint_t = TAutomapFramePoint;
  Pfpoint_t = PAutomapFramePoint;

  fline_t = TAutomapFrameLine;
  Pfline_t = PAutomapFrameLine;

  mpoint_t = TAutomapPoint;
  Pmpoint_t = PAutomapPoint;

  mline_t = TAutomapLine;
  Pmline_t = PAutomapLine;
  mline_tArray = packed array[0..$FFFF] of mline_t;
  Pmline_tArray = ^mline_tArray;

  islope_t = record
    slp: fixed_t;
    islp: fixed_t;
  end;
  Pislope_t = ^islope_t;

//
// The vector graphics for the automap.
//  A line drawing of the player pointing right,
//   starting from the middle.
//
const
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  NUMPLYRLINES = 10;
{$ELSE}
  NUMPLYRLINES = 7;
{$ENDIF}

var
  player_arrow: array[0..NUMPLYRLINES - 1] of mline_t;

const
  NUMCHEATPLYRLINES = 16;

var
  cheat_player_arrow: array[0..NUMCHEATPLYRLINES - 1] of mline_t;

const
  NUMTRIANGLEGUYLINES = 3;

var
  triangle_guy: array[0..NUMTRIANGLEGUYLINES - 1] of mline_t;

const
  NUMTHINTRIANGLEGUYLINES = 3;

var
  thintriangle_guy: array[0..NUMTHINTRIANGLEGUYLINES - 1] of mline_t;

const
  NUMTTRACEPLAYERLINES = 3;

var
  traceplayer_guy: array[0..NUMTTRACEPLAYERLINES - 1] of mline_t;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}

const
  NUMKEYSQUARELINES = 8;

var
  keysquare: array[0..NUMKEYSQUARELINES - 1] of mline_t;
{$ENDIF}

type
  automapstate_t = (am_inactive, am_only, am_overlay, AM_NUMSTATES);

var
  am_cheating: integer = 0;
  automapgrid: boolean = false;
  automaptraceplayer: integer = 0;

  leveljuststarted: integer = 1;   // kluge until AM_LevelInit() is called

  amstate: automapstate_t = am_inactive; //boolean = false;

// location of window on screen
  f_x: integer;
  f_y: integer;

// size of window on screen
  f_w: integer;
  f_h: integer;

  lightlev: integer;      // used for funky strobing effect
  fb: PByteArray;         // pseudo-frame buffer
  fb32: PLongWordArray;   // pseudo-frame buffer
  amclock: integer;

// The window on the map (where it is, the scale, the limits of the level, the pan and the zoom)
// and the marks are in Libs\Automap: see AM_Configure().

  plr: Pplayer_t; // the player represented by an arrow

var
  marknums: array[0..9] of Ppatch_t;  // numbers used for marking by the automap
  marknumsid: array[0..9] of integer; // numbers used for marking by the automap
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}

  maplump: PByteArray;
  maplumpsize: integer;
  maplumpheight: integer;
{$ENDIF}

const
{$IFDEF STRIFE}
  cheat_amap_seq: string = Chr($2e) + Chr($f6) + Chr($2a) + Chr($f6) + Chr($ff); // topo
{$ELSE}
  cheat_amap_seq: string = Chr($b2) + Chr($26) + Chr($26) + Chr($2e) + Chr($ff); // iddt
{$ENDIF}

var
  cheat_amap: cheatseq_t;

  stopped: boolean = true;

//==============================================================================
//
// AM_Responder
//
//==============================================================================
function AM_Responder(ev: Pevent_t): boolean;

//==============================================================================
// AM_Ticker
//
// Called by main loop.
//
//==============================================================================
procedure AM_Ticker;

//==============================================================================
// AM_Drawer
//
// Called by main loop,
// called instead of view drawer if automap active.
//
//==============================================================================
procedure AM_Drawer;

//==============================================================================
//
// AM_Init
//
//==============================================================================
procedure AM_Init;

//==============================================================================
// AM_Stop
//
// Called to force the automap to quit
// if the level is completed while it is up.
//
//==============================================================================
procedure AM_Stop;

//==============================================================================
//
// AM_Start
//
//==============================================================================
procedure AM_Start;

var
  allowautomapoverlay: boolean;
  allowautomaprotate: boolean;
  texturedautomap: boolean;

//==============================================================================
//
// AM_ShutDown
//
//==============================================================================
procedure AM_ShutDown;

//==============================================================================
// AM_Configure
//
// Gives the automap the window on the map and the marks of Libs\Automap (done by
// ComposeEngine). Without it the automap stops with I_Error.
//
//==============================================================================
procedure AM_Configure(const AView: IAutomapView; const ANavigator: IAutomapNavigator;
  const AMarks: IAutomapMarks);

implementation

uses
  DelphiDoom.Console.Numbers,
  am_textured,
  c_cmds,
{$IFDEF DOOM}
  i_system,
{$ENDIF}
  DelphiDoom.Automap.Rotation,
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  d_englsh,
{$ENDIF}
  g_game,
  mt_utils,
  p_mobj_h,
  p_setup,
  p_maputl,
  p_playertrace,
  p_tick,
{$IF DEFINED(HERETIC)}
  r_data,
  info_h,
{$ELSEIF DEFINED(HEXEN)}
  info_h,
{$ELSE}
  r_data,
{$ENDIF}
{$IFNDEF OPENGL}
  r_draw,
  r_hires,
{$ELSE}
  gl_automap,
{$ENDIF}
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  sb_bar,
{$ENDIF}
  v_data,
  v_video;

const
  AM_MIN_SCALE = 2048;
// player radius
  PLAYERRADIUS = AUTOMAP_PLAYERRADIUS;

var
  // The window on the map and the marks (Libs\Automap), given by AM_Configure()
  am_view: IAutomapView = nil;
  am_navigator: IAutomapNavigator = nil;
  am_marks: IAutomapMarks = nil;

//==============================================================================
//
// CmdAllowautomapoverlay
//
//==============================================================================
procedure CmdAllowautomapoverlay(const parm: string);
begin
  allowautomapoverlay := TConsoleNumbers.EvaluateBoolean(parm, allowautomapoverlay);
  if not allowautomapoverlay and (amstate = am_overlay) then
    amstate := am_inactive;
end;

//==============================================================================
//
// AM_Configure
//
//==============================================================================
procedure AM_Configure(const AView: IAutomapView; const ANavigator: IAutomapNavigator;
  const AMarks: IAutomapMarks);
begin
  am_view := AView;
  am_navigator := ANavigator;
  am_marks := AMarks;
end;

//==============================================================================
//
// AM_CheckConfigured
//
//==============================================================================
procedure AM_CheckConfigured;
begin
  if not (Assigned(am_view) and Assigned(am_navigator) and Assigned(am_marks)) then
    I_Error('AM_CheckConfigured(): the automap was not configured (see ComposeEngine)');
end;

//==============================================================================
//
// AM_PlayerX, AM_PlayerY
//
// Where the player is, in the coordinates of the level
//
//==============================================================================
function AM_PlayerX: fixed_t;
begin
  if (plr <> nil) and (plr.mo <> nil) then
    result := plr.mo.x
  else
    result := 0;
end;

function AM_PlayerY: fixed_t;
begin
  if (plr <> nil) and (plr.mo <> nil) then
    result := plr.mo.y
  else
    result := 0;
end;

//==============================================================================
// AM_findMinMaxBoundaries
//
// Determines bounding box of all vertices,
// sets the limits of the zoom range.
//
//==============================================================================
procedure AM_findMinMaxBoundaries;
begin
  am_navigator.FitToVertices(PAutomapPoint(@vertexes[0]), numvertexes, SizeOf(vertex_t));
end;

//==============================================================================
// AM_addMark
//
// adds a marker at the current location
//
//==============================================================================
procedure AM_addMark;
var
  window: TAutomapWindow;
begin
  window := am_view.Window;
  am_marks.Add(window.MapX + window.MapWidth div 2, window.MapY + window.MapHeight div 2);
end;

//
//
//
var
  st_notify_AM_initVariables: event_t;

//==============================================================================
//
// AM_initVariables
//
//==============================================================================
procedure AM_initVariables;
var
  pnum: integer;
  i: integer;
  hasplayer: boolean;
  playerx, playery: fixed_t;
begin
  fb := screens[SCN_FG];
  fb32 := screen32;

  amclock := 0;
  lightlev := 0;

  hasplayer := false;
  playerx := 0;
  playery := 0;

  if gamestate = GS_LEVEL then
  begin
    // find player to center on initially
    pnum := consoleplayer;
    if not playeringame[pnum] then
    begin
      pnum := -1;
      for i := 0 to MAXPLAYERS - 1 do
        if playeringame[i] then
        begin
          pnum := i;
          break;
        end;
    end;

    if pnum >= 0 then
    begin
      plr := @players[pnum];
      if plr.mo <> nil then
      begin
        hasplayer := true;
        playerx := plr.mo.x;
        playery := plr.mo.y;
      end;
    end;
  end;

  // no pan, no zoom, the window on the player; the place and scale are kept for recovery
  am_navigator.StartWindow(hasplayer, playerx, playery);

  // inform the status bar of the change
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  SB_Responder(@st_notify_AM_initVariables);
{$ELSE}
  ST_Responder(@st_notify_AM_initVariables);
{$ENDIF}
end;

//==============================================================================
// AM_loadPics
//
//==============================================================================
procedure AM_loadPics;
var
  i: integer;
  namebuf: string;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  lump: integer;
{$ENDIF}
begin
{$IFDEF STRIFE}
  if W_CheckNumForName('PLMNUM0') >= 0 then
{$ELSE}
  for i := 0 to AM_NUMMARKPOINTS - 1 do
{$ENDIF}
  begin
{$IF DEFINED(DOOM)}
{$IFDEF RADIX}
    // the marks are the digits of the small font of Radix
    sprintf(namebuf, 'FNTA%.3d', [i + Ord('0')]);
{$ELSE}
    sprintf(namebuf, 'AMMNUM%d', [i]);
{$ENDIF}
    marknumsid[i] := W_GetNumForName(namebuf);
    marknums[i] := W_CacheLumpNum(marknumsid[i], PU_STATIC);
  end;
{$ELSEIF DEFINED(STRIFE)}
    for i := 0 to AM_NUMMARKPOINTS - 1 do
    begin
      sprintf(namebuf, 'PLMNUM%d', [i]);
      marknumsid[i] := W_GetNumForName(namebuf);
      marknums[i] := W_CacheLumpNum(marknumsid[i], PU_STATIC);
    end;
  end
  else  // JVAL: support for the old demo version
  begin
    for i := 0 to AM_NUMMARKPOINTS - 1 do
    begin
      sprintf(namebuf, 'AMMNUM%d', [i]);
      marknumsid[i] := W_GetNumForName(namebuf);
      marknums[i] := W_CacheLumpNum(marknumsid[i], PU_STATIC);
    end;
  end
{$ELSE}
    sprintf(namebuf, 'SMALLIN%d', [i]);
    marknumsid[i] := W_GetNumForName(namebuf);
    marknums[i] := W_CacheLumpNum(marknumsid[i], PU_STATIC);
  end;
  lump := W_CheckNumForName('AUTOPAGE');
  if lump >= 0 then
  begin
    maplump := W_CacheLumpNum(lump, PU_STATIC);
    maplumpsize := W_LumpLength(lump);
    maplumpheight := maplumpsize div 320;
  end
  else
  begin
    maplump := nil;
    maplumpsize := 0;
    maplumpheight := 0;
    I_Warning('AM_loadPics(): "AUTOPAGE" lump not found, using background color'#13#10);
  end;
{$ENDIF}
end;

//==============================================================================
//
// AM_unloadPics
//
//==============================================================================
procedure AM_unloadPics;
var
  i: integer;
begin
  for i := 0 to AM_NUMMARKPOINTS - 1 do
    Z_ChangeTag(marknums[i], PU_CACHE);
end;

//==============================================================================
//
// AM_clearMarks
//
//==============================================================================
procedure AM_clearMarks;
begin
  am_marks.Clear;
end;

//==============================================================================
// AM_LevelInit
//
// should be called at the start of every level
// right now, i figure it out myself
//
//==============================================================================
procedure AM_LevelInit;
begin
  leveljuststarted := 0;

  f_x := 0;
  f_y := 0;
  f_w := SCREENWIDTH;
{$IF DEFINED(DOOM)}
  f_h := ST_Y * SCREENHEIGHT div 200;
{$ELSEIF DEFINED(STRIFE)}
  f_h := ST_Y * SCREENHEIGHT div 200; //V_PreserveY(ST_Y);
{$ELSE}
  f_h := SB_Y * SCREENHEIGHT div 200;
{$ENDIF}

  am_view.SetFrame(f_x, f_y, f_w, f_h);

  AM_clearMarks;

  AM_findMinMaxBoundaries;
  am_navigator.InitializeScale;
end;

//
//
//
var
  st_notify_AM_Stop: event_t;

//==============================================================================
//
// AM_Stop
//
//==============================================================================
procedure AM_Stop;
begin
  if not stopped then
  begin
    AM_unloadPics;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
    SB_Responder(@st_notify_AM_Stop);
{$ELSE}
    ST_Responder(@st_notify_AM_Stop);
{$ENDIF}
    stopped := true;
  end;
end;

//
//
//
var
  lastlevel: integer = -1;
{$IFNDEF STRIFE}
  lastepisode: integer = -1;
{$ENDIF}
  lastscreenwidth: integer = -1;
  lastscreenheight: integer = -1;

//==============================================================================
//
// AM_Start
//
//==============================================================================
procedure AM_Start;
begin
  AM_CheckConfigured;

  AM_Stop;

  stopped := false;

{$IFDEF STRIFE}
  if (lastlevel <> gamemap) or
{$ELSE}
  if (lastlevel <> gamemap) or (lastepisode <> gameepisode) or
{$ENDIF}
     (lastscreenwidth <> SCREENWIDTH) or (lastscreenheight <> SCREENHEIGHT) then
  begin
    AM_LevelInit;
    lastlevel := gamemap;
{$IFNDEF STRIFE}
    lastepisode := gameepisode;
{$ENDIF}
    lastscreenwidth := SCREENWIDTH;
    lastscreenheight := SCREENHEIGHT;
  end;
  AM_initVariables;
  AM_loadPics;
end;

//==============================================================================
// AM_minOutWindowScale
//
// set the window scale to the maximum size
//
//==============================================================================
procedure AM_minOutWindowScale;
begin
  am_navigator.MinOutWindowScale;
end;

//
// Handle events (user inputs) in automap mode
//
var
  bigstate: boolean = false;

//==============================================================================
//
// AM_Responder
//
//==============================================================================
function AM_Responder(ev: Pevent_t): boolean;
var
  _message: string;
begin
  result := false;

  if amstate = am_inactive then
  begin
    if (ev._type = ev_keydown) and (ev.data1 = AM_TONGLEKEY) then
    begin
      if allowautomapoverlay then
        amstate := automapstate_t((Ord(amstate) + 1) mod Ord(AM_NUMSTATES))
      else
      begin
        if amstate = am_inactive then
          amstate := am_only
        else
          amstate := am_inactive
      end;
      AM_Start;
      viewactive := false;
      result := true;
    end;
  end
  else if ev._type = ev_keydown then
  begin
    result := true;
    case ev.data1 of
      AM_PANRIGHTKEY: // pan right
        begin
          if not am_navigator.FollowPlayer then
            am_navigator.PanX := am_view.FrameToMap(F_PANINC)
          else
            result := false;
        end;
      AM_PANLEFTKEY: // pan left
        begin
          if not am_navigator.FollowPlayer then
            am_navigator.PanX := -am_view.FrameToMap(F_PANINC)
          else
            result := false;
        end;
      AM_PANUPKEY: // pan up
        begin
          if not am_navigator.FollowPlayer then
            am_navigator.PanY := am_view.FrameToMap(F_PANINC)
          else
            result := false;
        end;
      AM_PANDOWNKEY: // pan down
        begin
          if not am_navigator.FollowPlayer then
            am_navigator.PanY := -am_view.FrameToMap(F_PANINC)
          else
            result := false;
        end;
      Ord(AM_ZOOMOUTKEY): // zoom out
        begin
          am_navigator.SetZoom(AUTOMAP_ZOOM_OUT, AUTOMAP_ZOOM_IN);
        end;
      Ord(AM_ZOOMINKEY),
      Ord(AM_ZOOMINKEY2): // zoom in
        begin
          am_navigator.SetZoom(AUTOMAP_ZOOM_IN, AUTOMAP_ZOOM_OUT);
        end;
      AM_TONGLEKEY:
        begin
          amstate := automapstate_t((Ord(amstate) + 1) mod Ord(AM_NUMSTATES));
          if amstate <> am_only then
          begin
            bigstate := false;
            viewactive := true;
            if amstate = am_inactive then
              AM_Stop;
          end;
        end;
      else
      begin
        if ev.data1 = AM_GOBIGKEY then
        begin
          bigstate := not bigstate;
          if bigstate then
          begin
            am_navigator.SaveScaleAndLocation;
            AM_minOutWindowScale;
          end
          else
            am_navigator.RestoreScaleAndLocation(AM_PlayerX, AM_PlayerY);
        end
        else if ev.data1 = AM_FOLLOWKEY then
        begin
          am_navigator.FollowPlayer := not am_navigator.FollowPlayer;
          am_navigator.ForgetPlayerLocation;
          if am_navigator.FollowPlayer then
            plr._message := AMSTR_FOLLOWON
          else
            plr._message := AMSTR_FOLLOWOFF;
        end
        else if ev.data1 = AM_GRIDKEY then
        begin
          automapgrid := not automapgrid;
          if automapgrid then
            plr._message := AMSTR_GRIDON
          else
            plr._message := AMSTR_GRIDOFF;
        end
        else if ev.data1 = AM_ROTATEKEY then
        begin
          allowautomaprotate := not allowautomaprotate;
          if allowautomaprotate then
            plr._message := AMSTR_ROTATEON
          else
            plr._message := AMSTR_ROTATEOFF;
        end
        else if ev.data1 = AM_TEXTUREDAUTOMAP then
        begin
          texturedautomap := not texturedautomap;
          if texturedautomap then
            plr._message := 'TEXTURED AUTOMAP ON'
          else
            plr._message := 'TEXTURED AUTOMAP OFF';
        end
        else if ev.data1 = AM_MARKKEY then
        begin
          sprintf(_message, '%s %d', [AMSTR_MARKEDSPOT, am_marks.NextIndex]);
          plr._message := _message;
          AM_addMark;
        end
        else if ev.data1 = AM_CLEARMARKKEY then
        begin
          AM_clearMarks;
          plr._message := AMSTR_MARKSCLEARED;
        end
        else
          result := false;
      end;
    end;
  end
  else if ev._type = ev_keyup then
  begin
    result := false;
    case ev.data1 of
      AM_PANRIGHTKEY:
        begin
          if not am_navigator.FollowPlayer then
            am_navigator.PanX := 0;
        end;
      AM_PANLEFTKEY:
        begin
          if not am_navigator.FollowPlayer then
            am_navigator.PanX := 0;
        end;
      AM_PANUPKEY:
        begin
          if not am_navigator.FollowPlayer then
            am_navigator.PanY := 0;
        end;
      AM_PANDOWNKEY:
        begin
          if not am_navigator.FollowPlayer then
            am_navigator.PanY := 0;
        end;
      Ord(AM_ZOOMOUTKEY),
      Ord(AM_ZOOMINKEY),
      Ord(AM_ZOOMINKEY2):
        begin
          am_navigator.SetZoom(FRACUNIT, FRACUNIT);
        end;
    end;
  end;

end;

//
//
//
const
  NUMLITELEVELS = 8;

var
  nexttic: integer = 0;
  litelevels: array[0..NUMLITELEVELS - 1] of integer = (0, 4, 7, 10, 12, 14, 15, 15);
  litelevelscnt: integer = 0;

//==============================================================================
//
// AM_Ticker
//
//==============================================================================
procedure AM_Ticker;
begin
  if amstate = am_inactive then
    exit;

  inc(amclock);

  // follow the player, change the zoom and the location of the window
  AM_CheckConfigured;
  am_navigator.Tick(AM_PlayerX, AM_PlayerY);

    // Update light level
    // AM_updateLightLev();

end;

//
// Clear automap frame buffer.
//
{$IFNDEF OPENGL}

//==============================================================================
//
// AM_clearFB
//
//==============================================================================
procedure AM_clearFB(color: integer);
var
  c: LongWord;
{$IF DEFINED(HERETIC)}
  dest: PLongWord;
  deststop: PLongWord;
{$ELSEIF DEFINED(HEXEN)}
  dest: PLongWord;
  deststop: PLongWord;
  remain: integer;
  actual: integer;
  y: integer;
{$ENDIF}
begin
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  if (maplump <> nil) and (maplumpsize > 0) then
{$ELSE}
  if videomode = vm32bit then
{$ENDIF}
  begin
{$IF DEFINED(HERETIC)}
    memcpy(screens[SCN_TMP], maplump, maplumpsize);
    V_CopyRect(0, 0, SCN_TMP, 320, maplumpheight, 0, 0, SCN_FG, true);
{$ELSEIF DEFINED(HEXEN)}
    remain := SB_Y;
    memcpy(screens[SCN_TMP], maplump, maplumpsize);
    y := 0;
    while remain > 0 do
    begin
      actual := remain;
      if actual > maplumpheight then
      begin
        actual := maplumpheight;
        remain := remain - maplumpheight;
      end
      else
        remain := 0;
      V_CopyRect(0, 0, SCN_TMP, 320, actual, 0, y, SCN_FG, true);
      y := y + actual;
    end;
{$ELSE}
    c := videopal[color];
    MT_memseti(fb32, c, f_w * f_h);
{$ENDIF}
  end
  else
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  begin
    if videomode = vm32bit then
    begin
      c := videopal[color];
      dest := @fb32[0];
      deststop := @fb32[f_w * f_h];
      while integer(dest) < integer(deststop) do
      begin
        dest^ := c;
        inc(dest);
      end;
    end
    else
      MT_memset(fb, color, f_w * f_h);
  end;
{$ELSE}
    MT_memset(fb, color, f_w * f_h);
{$ENDIF}
end;
{$ENDIF}

//==============================================================================
// AM_clipMline
//
// Automap clipping of lines (Cohen-Sutherland, in Libs\Automap).
//
//==============================================================================
function AM_clipMline(ml: Pmline_t; fl: Pfline_t): boolean;
begin
  result := am_view.ClipLine(ml^, fl^);
end;
//==============================================================================
// AM_drawFline
//
// Classic Bresenham w/ whatever optimizations needed for speed
//
//==============================================================================
procedure AM_drawFline(fl: Pfline_t; color: integer);
{$IFDEF OPENGL}
begin
  gld_AddAutomapLine(fl.a.x, fl.a.y, fl.b.x, fl.b.y,  videopal[color]);
end;
{$ELSE}
var
  x, y,
  dx, dy,
  sx, sy,
  ax, ay,
  d: integer;

  procedure PUTDOT(xx, yy, cc: integer);
  begin
  // JVAL Clip line if in overlay mode
    if amstate = am_overlay then
    begin
      if yy <= viewwindowy then
        exit;
      if yy >= viewwindowy + viewheight then
        exit;
      if xx <= viewwindowx then
        exit;
      if xx >= viewwindowx + viewwidth then
        exit;
    end;
    if videomode = vm32bit then
      fb32[yy * f_w + xx] := videopal[cc]
    else
      fb[yy * f_w + xx] := cc;
  end;

begin
  // For debugging only
  {$IFDEF DEBUG}
  if (fl.a.x < 0) or (fl.a.x >= f_w) or
     (fl.a.y < 0) or (fl.a.y >= f_h) or
     (fl.b.x < 0) or (fl.b.x >= f_w) or
     (fl.b.y < 0) or (fl.b.y >= f_h) then
  begin
    I_Error('AM_drawFline(): fuck!');
    exit;
  end;
  {$ENDIF}

  dx := fl.b.x - fl.a.x;
  ax := 2 * abs(dx);
  if dx < 0 then
    sx := -1
  else
    sx := 1;

  dy := fl.b.y - fl.a.y;
  ay := 2 * abs(dy);
  if dy < 0 then
    sy := -1
  else
    sy := 1;

  x := fl.a.x;
  y := fl.a.y;

  if ax > ay then
  begin
    d := ay - ax div 2;
    while true do
    begin
      PUTDOT(x, y, color);
      if x = fl.b.x then exit;
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
      PUTDOT(x, y, color);
      if y = fl.b.y then exit;
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
{$ENDIF}

//
// Clip lines, draw visible parts of lines.
//
var
  fl: fline_t;

//==============================================================================
//
// AM_drawMline
//
//==============================================================================
procedure AM_drawMline(ml: Pmline_t; color: integer);
begin
  if AM_clipMline(ml, @fl) then
    AM_drawFline(@fl, color); // draws it on frame buffer using fb coords
end;

//==============================================================================
// AM_drawGrid
//
// Draws flat (floor/ceiling tile) aligned grid lines.
//
//==============================================================================
procedure AM_drawGrid(color: integer);
var
  x, y: fixed_t;
  start, finish: fixed_t;
  ml: mline_t;
  dw, dh: double;
  minlen, extx, exty: fixed_t;
  minx, miny: fixed_t;
  rx, ry: fixed_t;
  window: TAutomapWindow;
begin
  window := am_view.Window;
  dw := window.MapWidth;
  dh := window.MapHeight;

  minlen := trunc(sqrt(2.0 * dw * dw + 2.0 * dh * dh));
  extx := (minlen - window.MapWidth) div 2;
  exty := (minlen - window.MapHeight) div 2;

  minx := window.MapX;
  miny := window.MapY;

  rx := plr.mo.x div FRACTOMAPUNIT;
  ry := plr.mo.y div FRACTOMAPUNIT;

  // Figure out start of vertical gridlines
  start := window.MapX - extx;
  if ((start - bmaporgx div FRACTOMAPUNIT) mod (MAPBLOCKUNITS * FRACUNIT)) <> 0 then
    start := start {+ (MAPBLOCKUNITS * FRACUNIT)}
          - ((start - bmaporgx div FRACTOMAPUNIT) mod (MAPBLOCKUNITS * FRACUNIT));
  finish := minx + minlen - extx;

  // draw vertical gridlines
  x := start;
  while x < finish do
  begin
    ml.a.x := x;
    ml.b.x := x;
    ml.a.y := miny - exty;
    ml.b.y := ml.a.y + minlen;

    if allowautomaprotate then
    begin
      TAutomapRotation.Rotate(ml.a.x, ml.a.y, ANG90 - plr.mo.angle, rx, ry);
      TAutomapRotation.Rotate(ml.b.x, ml.b.y, ANG90 - plr.mo.angle, rx, ry);
    end;

    AM_drawMline(@ml, color);
    x := x + (MAPBLOCKUNITS * MAPUNIT);
  end;

  // Figure out start of horizontal gridlines
  start := miny - exty;
  if ((start - bmaporgy) mod (MAPBLOCKUNITS * FRACUNIT)) <> 0 then
    start := start {+ (MAPBLOCKUNITS * FRACUNIT)}
          - ((start - bmaporgy) mod (MAPBLOCKUNITS * FRACUNIT));
  finish := miny + minlen - exty;

  // draw horizontal gridlines
  y := start;
  while y < finish do
  begin
    ml.a.x := minx - extx;
    ml.b.x := ml.a.x + minlen;
    ml.a.y := y;
    ml.b.y := y;

    if allowautomaprotate then
    begin
      TAutomapRotation.Rotate(ml.a.x, ml.a.y, ANG90 - plr.mo.angle, rx, ry);
      TAutomapRotation.Rotate(ml.b.x, ml.b.y, ANG90 - plr.mo.angle, rx, ry);
    end;

    AM_drawMline(@ml, color);
    y := y + (MAPBLOCKUNITS * MAPUNIT);
  end;
end;

//==============================================================================
//
// AM_rotate_dbl
//
//==============================================================================
procedure AM_rotate_dbl(x: Pfixed_t; y: Pfixed_t; a: angle_t; xpos, ypos: fixed_t);
begin
  TAutomapRotation.RotateExact(x^, y^, a, xpos, ypos);
end;
{$IFDEF HERETIC}
const
  BLUEKEYCOLOR = 197;
  YELLOWKEYCOLOR = 144;
  GREENKEYCOLOR = 220;

{$ENDIF}
//==============================================================================
// AM_drawWalls
//
// Determines visible lines, draws them.
// This is LineDef based, not LineSeg based.
//
//==============================================================================
procedure AM_drawWalls;
var
  i: integer;
  l: mline_t;
  pl: Pline_t;
  plrx, plry: fixed_t;
  plra: angle_t;
begin
  plrx := plr.mo.x div FRACTOMAPUNIT;
  plry := plr.mo.y div FRACTOMAPUNIT;
  plra := ANG90 - plr.mo.angle;
  pl := @lines[0];
  for i := 0 to numlines - 1 do
  begin
    l.a.x := pl.v1.x div FRACTOMAPUNIT;
    l.a.y := pl.v1.y div FRACTOMAPUNIT;
    l.b.x := pl.v2.x div FRACTOMAPUNIT;
    l.b.y := pl.v2.y div FRACTOMAPUNIT;

    if allowautomaprotate then
    begin
      TAutomapRotation.Rotate(l.a.x, l.a.y, plra, plrx, plry);
      TAutomapRotation.Rotate(l.b.x, l.b.y, plra, plrx, plry);
    end;

    if (am_cheating <> 0) or (pl.flags and ML_MAPPED <> 0) then
    begin
      if (pl.flags and LINE_NEVERSEE <> 0) and (am_cheating = 0) then
      begin
        inc(pl);
        continue;
      end;
{$IFDEF STRIFE}
      if (pl.special = 145) or (pl.special = 186) then
{$ELSE}
      if pl.backsector = nil then
{$ENDIF}
      begin
{$IFDEF STRIFE}
        AM_drawMline(@l, SPWALLCOLORS);
      end
      else if pl.backsector = nil then
      begin
        AM_drawMline(@l, WALLCOLORS);
{$ELSE}
        AM_drawMline(@l, WALLCOLORS + lightlev);
{$ENDIF}
      end
      else
      begin
{$IFDEF HEXEN}
        if (pl.special = 13) or (pl.special = 83) then
        begin // Locked door line -- all locked doors are greed
          AM_drawMline(@l, 198);
        end
        else if (pl.special = 70) or (pl.special = 71) then
        begin // intra-level teleports are blue
          AM_drawMline(@l, 157);
        end
        else if (pl.special = 74) or (pl.special = 75) then
        begin // intra-level teleports are blue
          AM_drawMline(@l, 177);
{$ELSE}
        if pl.special = 39 then
        begin // teleporters
          AM_drawMline(@l, WALLCOLORS + WALLRANGE div 2);
{$ENDIF}
        end
        else if pl.flags and ML_SECRET <> 0 then // secret door
        begin
{$IFDEF STRIFE}
          AM_drawMline(@l, WALLCOLORS + lightlev);
{$ELSE}
          if am_cheating <> 0 then
            AM_drawMline(@l, SECRETWALLCOLORS + lightlev)
          else
            AM_drawMline(@l, WALLCOLORS + lightlev);
{$ENDIF}
        end
{$IFDEF HERETIC}
        else if (pl.special = 26) or (pl.special = 32) then
          AM_drawMline(@l, BLUEKEYCOLOR)
        else if (pl.special = 27) or (pl.special = 34) then
          AM_drawMline(@l, YELLOWKEYCOLOR)
        else if (pl.special = 28) or (pl.special = 33) then
          AM_drawMline(@l, GREENKEYCOLOR)
{$ENDIF}
        else if pl.backsector.floorheight <> pl.frontsector.floorheight then
        begin
{$IFDEF STRIFE}
          AM_drawMline(@l, FDWALLCOLORS); // floor level change
{$ELSE}
          AM_drawMline(@l, FDWALLCOLORS + lightlev); // floor level change
{$ENDIF}
        end
        else if pl.backsector.ceilingheight <> pl.frontsector.ceilingheight then
        begin
{$IFDEF STRIFE}
          AM_drawMline(@l, CDWALLCOLORS); // ceiling level change
{$ELSE}
          AM_drawMline(@l, CDWALLCOLORS + lightlev); // ceiling level change
{$ENDIF}
        end
        else if am_cheating <> 0 then
        begin
{$IFDEF STRIFE}
          AM_drawMline(@l, TSWALLCOLORS);
{$ELSE}
          AM_drawMline(@l, TSWALLCOLORS + lightlev);
{$ENDIF}
        end;
      end;
    end
{$IFDEF STRIFE}
    else if (plr.powers[Ord(pw_allmap)] <> 0) or (gamemap = 15) then
{$ELSE}
    else if plr.powers[Ord(pw_allmap)] <> 0 then
{$ENDIF}
    begin
      if pl.flags and LINE_NEVERSEE = 0 then
{$IFDEF STRIFE}
        AM_drawMline(@l, CTWALLCOLORS);
{$ELSE}
        AM_drawMline(@l, GRAYS + 3);
{$ENDIF}
    end;
    inc(pl);
  end;
end;

//==============================================================================
//
// AM_drawLineCharacter
//
//==============================================================================
procedure AM_drawLineCharacter(lineguy: Pmline_tArray; lineguylines: integer;
  scale: fixed_t; angle: angle_t; color: integer;
  x: fixed_t; y: fixed_t);
var
  i: integer;
  l: mline_t;
  plg: Pmline_t;
begin
  if allowautomaprotate then
    angle := angle + ANG90 - plr.mo.angle;

  plg := @lineguy[0];
  for i := 0 to lineguylines - 1 do
  begin
    l.a.x := plg.a.x;
    l.a.y := plg.a.y;

    if scale <> 0 then
    begin
      l.a.x := FixedMul(scale, l.a.x);
      l.a.y := FixedMul(scale, l.a.y);
    end;

    if angle <> 0 then
      AM_rotate_dbl(@l.a.x, @l.a.y, angle, 0, 0);

    l.a.x := l.a.x + x;
    l.a.y := l.a.y + y;

    l.b.x := plg.b.x;
    l.b.y := plg.b.y;

    if scale <> 0 then
    begin
      l.b.x := FixedMul(scale, l.b.x);
      l.b.y := FixedMul(scale, l.b.y);
    end;

    if angle <> 0 then
      AM_rotate_dbl(@l.b.x, @l.b.y, angle, 0, 0);

    l.b.x := l.b.x + x;
    l.b.y := l.b.y + y;

    AM_drawMline(@l, color);
    inc(plg);
  end;
end;

//==============================================================================
//
// AM_drawPlayerTrace
//
//==============================================================================
procedure AM_drawPlayerTrace(const p: Pplayer_t; const color1: Integer);
const
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  PTRACECOLORRANGE = 4;
{$ELSE}
  PTRACECOLORRANGE = 8;
{$ENDIF}
var
  i: integer;
  x, y, x2, y2: fixed_t;
  trace: Pplayertrace_t;
  plrx, plry: fixed_t;
  plra: angle_t;
  traceline: mline_t;
  color: integer;
  colordiff: integer;
begin
  plrx := plr.mo.x div FRACTOMAPUNIT;
  plry := plr.mo.y div FRACTOMAPUNIT;
  plra := ANG90 - plr.mo.angle;

  x2 := plrx;
  y2 := plry;

  automaptraceplayer := ibetween(automaptraceplayer, 0, NUMPLAYERTRACEHISTORY - 1);
  for i := 1 to automaptraceplayer do
  begin
    trace := P_GetPlayerTraceAtPos(p, i);
    if trace <> nil then
    begin
      x := trace.x div FRACTOMAPUNIT;
      y := trace.y div FRACTOMAPUNIT;

      if allowautomaprotate then
        TAutomapRotation.Rotate(x, y, plra, plrx, plry);

      if P_AproxDistance(x - x2, y - y2) < (128 * FRACUNIT) div FRACTOMAPUNIT then
      begin

        colordiff := (i + leveltime div 4) and (2 * PTRACECOLORRANGE - 1);
        if colordiff > PTRACECOLORRANGE then
          colordiff := 2 * PTRACECOLORRANGE - colordiff;

        color := color1 + colordiff;

        AM_drawLineCharacter
          (@traceplayer_guy, NUMTTRACEPLAYERLINES, 4 * FRACUNIT, trace.angle,
           color, x, y);

        traceline.a.x := x2 div 2 + x div 2;
        traceline.a.y := y2 div 2 + y div 2;
        traceline.b.x := x2;
        traceline.b.y := y2;
        AM_drawMline(@traceline, color);
      end;
      x2 := x;
      y2 := y;
    end;
  end;
end;

{$IFDEF HEXEN}
const
  AM_PLR1_COLOR = 157; // Blue
  AM_PLR2_COLOR = 177; // Red
  AM_PLR3_COLOR = 137; // Yellow
  AM_PLR4_COLOR = 198; // Green
  AM_PLR5_COLOR = 215; // Jade
  AM_PLR6_COLOR =  32; // White
  AM_PLR7_COLOR = 106; // Hazel
  AM_PLR8_COLOR = 234; // Purple
  AM_TR1_COLOR = 154; // Blue
  AM_TR2_COLOR = 176; // Red
  AM_TR3_COLOR = 136; // Yellow
  AM_TR4_COLOR = 197; // Green
  AM_TR5_COLOR = 211; // Jade
  AM_TR6_COLOR =  25; // White
  AM_TR7_COLOR = 106; // Hazel
  AM_TR8_COLOR = 233; // Purple

{$ENDIF}
//==============================================================================
//
// AM_drawPlayers
//
//==============================================================================
procedure AM_drawPlayers;
const
{$IF DEFINED(HEXEN)}
  their_colors: array[0..MAXPLAYERS - 1] of integer = (
    AM_PLR1_COLOR,
    AM_PLR2_COLOR,
    AM_PLR3_COLOR,
    AM_PLR4_COLOR,
    AM_PLR5_COLOR,
    AM_PLR6_COLOR,
    AM_PLR7_COLOR,
    AM_PLR8_COLOR
  );
  trace_colors: array[0..MAXPLAYERS - 1] of integer = (
    AM_TR1_COLOR,
    AM_TR2_COLOR,
    AM_TR3_COLOR,
    AM_TR4_COLOR,
    AM_TR5_COLOR,
    AM_TR6_COLOR,
    AM_TR7_COLOR,
    AM_TR8_COLOR
  );
{$ELSEIF DEFINED(STRIFE)}
  their_colors: array[0..MAXPLAYERS] of integer = ($80, $40, $B0, $10, $30, $50, $A0, $60, $90);
{$ELSE}
  their_colors: array[0..MAXPLAYERS - 1] of integer = (GREENS, GRAYS, BROWNS, REDS);
{$ENDIF}
var
  i: integer;
  p: Pplayer_t;
{$IFDEF HEXEN}
  their_color, color, trcolor: integer;
{$ELSE}
  their_color, color: integer;
{$ENDIF}
  x, y: fixed_t;
begin
  if not netgame then
  begin
    if am_cheating <> 0 then
      AM_drawLineCharacter
        (@cheat_player_arrow, NUMCHEATPLYRLINES, 0,
{$IFDEF STRIFE}
        plr.mo.angle, 224, plr.mo.x div FRACTOMAPUNIT, plr.mo.y div FRACTOMAPUNIT)
{$ELSE}
        plr.mo.angle, WHITE, plr.mo.x div FRACTOMAPUNIT, plr.mo.y div FRACTOMAPUNIT)
{$ENDIF}
    else
      AM_drawLineCharacter
        (@player_arrow, NUMPLYRLINES, 0, plr.mo.angle,
{$IF DEFINED(HEXEN)}
        WHITE, plr.mo.x div FRACTOMAPUNIT, plr.mo.y div FRACTOMAPUNIT);
    AM_drawPlayerTrace(plr, TRACEGREEN);
{$ELSEIF DEFINED(STRIFE)}
        224, plr.mo.x div FRACTOMAPUNIT, plr.mo.y div FRACTOMAPUNIT);
    AM_drawPlayerTrace(plr, 224);
{$ELSE}
        WHITE, plr.mo.x div FRACTOMAPUNIT, plr.mo.y div FRACTOMAPUNIT);
    AM_drawPlayerTrace(plr, GREENS);
{$ENDIF}
    exit;
  end;

  their_color := -1;
  for i := 0 to MAXPLAYERS - 1 do
  begin
    inc(their_color);
    p := @players[i];

    if (deathmatch <> 0) and not singledemo and (p <> plr) then
      continue;

    if not playeringame[i] then
      continue;

{$IF DEFINED(HERETIC)}
    if p.powers[Ord(pw_invisibility)] <> 0 then
      color := 99 // *close* to background
    else
      color := their_colors[their_color];
{$ELSEIF DEFINED(HEXEN)}
    color := their_colors[their_color];
    trcolor := trace_colors[their_color];
    if p.mo <> nil then
      if p.mo.flags and (MF_SHADOW or MF_ALTSHADOW) <> 0 then
      begin
        color := 111; // *close* to background
        trcolor := 111;
      end;
{$ELSEIF DEFINED(STRIFE)}
    if p.powers[Ord(pw_invisibility)] <> 0 then
      color := 27 // *close* to black
    else
      color := their_colors[their_color];
{$ELSE}
    if p.powers[Ord(pw_invisibility)] <> 0 then
      color := 246 // *close* to black
    else
      color := their_colors[their_color];
{$ENDIF}

    x := p.mo.x;
    y := p.mo.y;

    if allowautomaprotate then
      TAutomapRotation.Rotate(x, y, ANG90 - plr.mo.angle, plr.mo.x div FRACTOMAPUNIT, plr.mo.y div FRACTOMAPUNIT);

    AM_drawLineCharacter
      (@player_arrow, NUMPLYRLINES, 0, p.mo.angle,
       color, x div FRACTOMAPUNIT, y div FRACTOMAPUNIT);

{$IFDEF HEXEN}
    AM_drawPlayerTrace(p, trcolor);
{$ELSE}
    AM_drawPlayerTrace(p, color);
{$ENDIF}
  end;
end;

//==============================================================================
//
// AM_drawThings
//
//==============================================================================
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
procedure AM_drawThings(colors: integer; colorrange: integer);
{$ELSE}
procedure AM_drawThings;
{$ENDIF}
var
  i: integer;
  t: Pmobj_t;
  x, y: fixed_t;
{$IFDEF STRIFE}
  colors: integer;
  radius: fixed_t;
{$ENDIF}
  plrx, plry: fixed_t;
  plra: angle_t;
{$IFDEF DOOM}
  color: integer;
{$ENDIF}
begin
  plrx := plr.mo.x div FRACTOMAPUNIT;
  plry := plr.mo.y div FRACTOMAPUNIT;
  plra := ANG90 - plr.mo.angle;
  for i := 0 to numsectors - 1 do
  begin
    t := sectors[i].thinglist;
    while t <> nil do
    begin
{$IFDEF STRIFE}
      radius := t.radius;
{$ENDIF}
      x := t.x div FRACTOMAPUNIT;
      y := t.y div FRACTOMAPUNIT;

      if allowautomaprotate then
        TAutomapRotation.Rotate(x, y, plra, plrx, plry);

{$IF DEFINED(HERETIC)}
      if t._type = Ord(MT_CKEY) then
        AM_drawLineCharacter(
          @keysquare, NUMKEYSQUARELINES,
          0, ANGLE_MAX - plra, YELLOWKEYCOLOR, x, y)
      else if t._type = Ord(MT_AKYY) then
        AM_drawLineCharacter(
          @keysquare, NUMKEYSQUARELINES,
          0, ANGLE_MAX - plra, GREENKEYCOLOR, x, y)
      else if t._type = Ord(MT_BKYY) then
        AM_drawLineCharacter(
          @keysquare, NUMKEYSQUARELINES,
          0, ANGLE_MAX - plra, BLUEKEYCOLOR, x, y)
      else if (t.flags2_ex and MF2_EX_FRIEND <> 0) or (t.player <> nil) then
        AM_drawLineCharacter
          (@thintriangle_guy, NUMTHINTRIANGLEGUYLINES,
          16 * FRACUNIT, t.angle, WHITE, x, y)
      else
        AM_drawLineCharacter
          (@thintriangle_guy, NUMTHINTRIANGLEGUYLINES,
          16 * FRACUNIT, t.angle, colors + lightlev, x, y);
{$ELSEIF DEFINED(HEXEN)}
      if (t.sprite >= Ord(SPR_KEY1)) and (t.sprite <= Ord(SPR_KEYB)) then
        AM_drawLineCharacter(
          @keysquare, NUMKEYSQUARELINES,
          0, ANGLE_MAX - plra, colors + lightlev, x, y)
      else if (t.flags2_ex and MF2_EX_FRIEND <> 0) or (t.player <> nil) then
        AM_drawLineCharacter
          (@thintriangle_guy, NUMTHINTRIANGLEGUYLINES,
          16 * FRACUNIT, t.angle, WHITE, x, y)
      else
        AM_drawLineCharacter
          (@thintriangle_guy, NUMTHINTRIANGLEGUYLINES,
          16 * FRACUNIT, t.angle, colors + lightlev, x, y);
{$ELSEIF DEFINED(STRIFE)}
      if t.flags and (MF_MISSILE or MF_SPECIAL) <> 0 then
        colors := MISSILECOLORS
      else if t.flags and MF_COUNTKILL <> 0 then
        colors := SHOOTABLECOLORS
      else
      begin
        colors := THINGCOLORS;
        radius := 16 * FRACUNIT;
      end;

      if t.flags2_ex and MF2_EX_FRIEND <> 0 then
        colors := GRAYS;

      AM_drawLineCharacter
        (@thintriangle_guy, NUMTHINTRIANGLEGUYLINES,
        radius, t.angle, colors, x, y);
{$ELSE}
      if t.flags2_ex and MF2_EX_FRIEND <> 0 then
        color := WHITE
      else if t.flags and MF_SHOOTABLE <> 0 then
        color := THINGCOLORS + lightlev
      else if t.flags and MF_SPECIAL <> 0 then
        color := BLUES
      else
        color := GRAYS;

      if t.radius >= 40 * FRACUNIT then
        AM_drawLineCharacter
          (@triangle_guy, NUMTRIANGLEGUYLINES,
          16 * FRACUNIT, t.angle, color, x, y)
      else
        AM_drawLineCharacter
          (@thintriangle_guy, NUMTHINTRIANGLEGUYLINES,
          16 * FRACUNIT, t.angle, color, x, y);
{$ENDIF}
      t := t.snext;
    end;
  end;
end;

//==============================================================================
//
// AM_drawMarks
//
//==============================================================================
procedure AM_drawMarks;
var
  i, fx, fy, w, h: integer;
begin
  for i := 0 to AM_NUMMARKPOINTS - 1 do
  begin
    if am_marks.IsUsed(i) then
    begin
      w := 5; // because something's wrong with the wad, i guess
      h := 6; // because something's wrong with the wad, i guess
      fx := am_marks.Point(i).X;
      fy := am_marks.Point(i).Y;

      if allowautomaprotate then
        TAutomapRotation.Rotate(fx, fy, ANG90 - plr.mo.angle, plr.mo.x div FRACTOMAPUNIT, plr.mo.y div FRACTOMAPUNIT);

      fx := am_view.MapToFrameX(fx);
      fy := am_view.MapToFrameY(fy);

      if (fx >= f_x) and (fx <= f_w - w) and (fy >= f_y) and (fy <= f_h - h) then
      {$IFDEF OPENGL}
        gld_AddAutomapPatch(fx, fy, marknumsid[i])
      {$ELSE}
        V_DrawPatchZoomed(fx, fy, SCN_FG, marknums[i], false, FRACUNIT * SCREENHEIGHT div 200);
      {$ENDIF}
    end;
  end;
end;

//==============================================================================
//
// AM_drawCrosshair
//
//==============================================================================
procedure AM_drawCrosshair(color: integer);
begin
  {$IFNDEF OPENGL}
  if videomode = vm32bit then
    fb32[(f_w * (f_h div 2)) + (f_w div 2)] := videopal[color] // single point for now
  else
    fb[(f_w * (f_h div 2)) + (f_w div 2)] := color; // single point for now
  {$ELSE}
  gld_AddAutomapLine(f_w div 2 - 1, f_h div 2, f_w div 2 + 1, f_h div 2,  videopal[color]);
  gld_AddAutomapLine(f_w div 2, f_h div 2 - 1, f_w div 2, f_h div 2 + 1,  videopal[color]);
  {$ENDIF}
end;

//==============================================================================
//
// AM_Drawer
//
//==============================================================================
procedure AM_Drawer;
begin
  if amstate = am_inactive then
    exit;

  if am_navigator.FollowPlayer then
    am_navigator.CenterOnPlayer(plr.mo.x, plr.mo.y);

  if amstate = am_only then
  begin
    {$IFDEF OPENGL}
{$IF DEFINED(HERETIC)}
    gld_ClearAMBuffer(f_w, f_h, videopal[104]);
{$ELSEIF DEFINED(HEXEN)}
    gld_ClearAMBuffer(f_w, f_h, videopal[90]);
{$ELSEIF DEFINED(STRIFE)}
    gld_ClearAMBuffer(f_w, f_h, videopal[BACKGROUND]);
{$ELSE}
    gld_ClearAMBuffer(f_w, f_h, $080808);
{$ENDIF}
    {$ELSE}
{$IF DEFINED(HERETIC)}
    AM_clearFB(104);
{$ELSEIF DEFINED(HEXEN)}
    AM_clearFB(90);
{$ELSEIF DEFINED(STRIFE)}
    AM_clearFB(BACKGROUND);
{$ELSE}
    AM_clearFB(aprox_black);
{$ENDIF}
    {$ENDIF}
    if texturedautomap then
    begin
      AM_setSubSectorDrawFuncs;
      AM_drawSubSectors(am_view.Window);
    end;
  end;
  if automapgrid then
    AM_drawGrid(GRIDCOLORS);
  AM_drawWalls;

  AM_drawMarks;

  AM_drawPlayers;
{$IF DEFINED(DOOM)}
  if am_cheating = 2 then
    AM_drawThings;
{$ELSEIF DEFINED(STRIFE)}
  if (am_cheating = 2) or (plr.powers[Ord(pw_allmap)] <> 0) then
    AM_drawThings;
{$ELSE}
  if am_cheating = 2 then
    AM_drawThings(THINGCOLORS, THINGRANGE);
{$ENDIF}
  AM_drawCrosshair(XHAIRCOLORS);

  {$IFDEF OPENGL}
  gld_DrawAutomap;
  {$ENDIF}
end;

//==============================================================================
//
// AM_Init
//
//==============================================================================
procedure AM_Init;
var
  pl: Pmline_t;
begin
  AM_InitTextured;

  pl := @player_arrow[0];
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
{$ELSE}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
{$ENDIF}
  pl.a.y := 0;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.b.x := 0;
  pl.b.y := 0;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 8;
{$ENDIF}
  pl.b.x := ((8 * PLAYERRADIUS) div 7);
  pl.b.y := 0;

  inc(pl);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.x := ((8 * PLAYERRADIUS) div 7);
  pl.b.y := 0;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
{$ELSE}
  pl.a.x := ((8 * PLAYERRADIUS) div 7);
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 2;
{$ENDIF}
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
{$ELSE}
  pl.a.x := ((8 * PLAYERRADIUS) div 7);
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 2;
{$ENDIF}
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
{$ELSE}
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 8;
{$ENDIF}
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 8;
{$ELSE}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 4;
{$ENDIF}

  inc(pl);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 8;
{$ELSE}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + 3 * ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
{$ENDIF}
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 8;
{$ELSE}
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;
{$ENDIF}

  inc(pl);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 8;
{$ELSE}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + 3 * ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
{$ENDIF}
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 8;
{$ELSE}
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 4;
{$ENDIF}

////////////////////////////////////////////////////////////////////////////////

  pl := @cheat_player_arrow[0];
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7);
  pl.b.y := 0;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7);
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7);
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + 3 * ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + 3 * ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 2;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 2;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) div 2 + ((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 2 + ((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) div 2 + ((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.x := 0;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := 0;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.x := 0;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 7;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 7;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 6 + ((8 * PLAYERRADIUS) div 7) div 32;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 7 - ((8 * PLAYERRADIUS) div 7) div 32;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 6 + ((8 * PLAYERRADIUS) div 7) div 32;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 7 - ((8 * PLAYERRADIUS) div 7) div 32;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 6 + ((8 * PLAYERRADIUS) div 7) div 10;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 7;

////////////////////////////////////////////////////////////////////////////////

  pl := @triangle_guy[0];
  pl.a.x := round(-0.867 * MAPUNIT);
  pl.a.y := round(-0.5 * MAPUNIT);
  pl.b.x := round(0.867 * MAPUNIT);
  pl.b.y := round(-0.5 * MAPUNIT);

  inc(pl);
  pl.a.x := round(0.867 * MAPUNIT);
  pl.a.y := round(-0.5 * MAPUNIT);
  pl.b.x := 0;
  pl.b.y := MAPUNIT;

  inc(pl);
  pl.a.x := 0;
  pl.a.y := MAPUNIT;
  pl.b.x := round(-0.867 * MAPUNIT);
  pl.b.y := round(-0.5 * MAPUNIT);

////////////////////////////////////////////////////////////////////////////////

  pl := @thintriangle_guy[0];
  pl.a.x := round(-0.5 * MAPUNIT);
  pl.a.y := round(-0.7 * MAPUNIT);
  pl.b.x := MAPUNIT;
  pl.b.y := 0;

  inc(pl);
  pl.a.x := MAPUNIT;
  pl.a.y := 0;
  pl.b.x := round(-0.5 * MAPUNIT);
  pl.b.y := round(0.7 * MAPUNIT);

  inc(pl);
  pl.a.x := round(-0.5 * MAPUNIT);
  pl.a.y := round(0.7 * MAPUNIT);
  pl.b.x := round(-0.5 * MAPUNIT);
  pl.b.y := round(-0.7 * MAPUNIT);

////////////////////////////////////////////////////////////////////////////////
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl := @keysquare[0];
  pl.a.x := 0;
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 2;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 2;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 2;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 2;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 2;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 2;

  inc(pl);  // handle part type thing
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.x := 0;
  pl.b.y := 0;

  inc(pl);  // stem
  pl.a.x := 0;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7);
  pl.b.y := 0;

  inc(pl);  // end lockpick part
  pl.a.x := -((8 * PLAYERRADIUS) div 7);
  pl.a.y :=  0;
  pl.b.x :=  -((8 * PLAYERRADIUS) div 7);
  pl.b.y :=  -((8 * PLAYERRADIUS) div 7) div 2;

  inc(pl);
  pl.a.x := -3 * ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := 0;
  pl.b.x := -3 * ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 4;

////////////////////////////////////////////////////////////////////////////////
{$ENDIF}

  pl := @traceplayer_guy[0];
  pl.a.x := 0;
  pl.a.y := round(-0.7 * MAPUNIT);
  pl.b.x := round(0.7 * MAPUNIT);
  pl.b.y := 0;

  inc(pl);
  pl.a.x := 0;
  pl.a.y := round(0.7 * MAPUNIT);
  pl.b.x := round(0.7 * MAPUNIT);
  pl.b.y := 0;

  inc(pl);
  pl.a.x := 0;
  pl.a.y := 0;
  pl.b.x := round(0.7 * MAPUNIT);
  pl.b.y := 0;

////////////////////////////////////////////////////////////////////////////////
  cheat_amap.sequence := get_cheatseq_string(cheat_amap_seq);
  cheat_amap.p := get_cheatseq_string(0);

////////////////////////////////////////////////////////////////////////////////
  ZeroMemory(@st_notify_AM_initVariables, SizeOf(st_notify_AM_initVariables));
  st_notify_AM_initVariables._type := ev_keyup;
  st_notify_AM_initVariables.data1 := AM_MSGENTERED;

////////////////////////////////////////////////////////////////////////////////
  ZeroMemory(@st_notify_AM_Stop, SizeOf(st_notify_AM_Stop));
  st_notify_AM_Stop._type := ev_keyup;
  st_notify_AM_Stop.data1 := AM_MSGEXITED;

  C_AddCmd('allowautomapoverlay', @CmdAllowautomapoverlay);
end;

//==============================================================================
//
// AM_ShutDown
//
//==============================================================================
procedure AM_ShutDown;
begin
  AM_ShutDownTextured;
end;

end.

