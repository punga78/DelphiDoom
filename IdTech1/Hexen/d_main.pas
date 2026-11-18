//------------------------------------------------------------------------------
//
//  DelphiHexen is a source port of the game Hexen and it is
//  based on original Linux Doom as published by "id Software", on
//  Hexen source as published by "Raven" software and DelphiDoom
//  as published by Jim Valavanis.
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
// DESCRIPTION (d_main.h):
//  System specific interface stuff.
//
// DESCRIPTION (d_main.c):
//  DOOM main program (D_DoomMain) and game loop (D_DoomLoop),
//  plus functions to determine game mode (shareware, registered),
//  parse command line parameters, configure game parameters (turbo),
//  and call the startup functions.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit d_main;

interface

uses
  DelphiDoom.Engine.Level.Intf,
  d_event,
  doomdef,
  DelphiDoom.IdTech.Intf,
  DelphiDoom.Iwad.Intf,
  DelphiDoom.Engine.Nodes.Intf,
  DelphiDoom.Engine.Console.Intf,
  DelphiDoom.Engine.Net.Intf,
  DelphiDoom.Engine.Configuration.Intf,
  DelphiDoom.Engine.Screenshot.Intf,
  DelphiDoom.Scanner.Preprocessor.Intf,
  DelphiDoom.Engine.ActorDef.Intf,
  DelphiDoom.Scanner.AutoLoad.Intf,
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.Video.Intf;

const
{$IFNDEF FPC}
  AppTitle = 'Delphi Hexen';
{$ELSE}
  AppTitle = 'Free Pascal Hexen';
{$ENDIF}

// wipegamestate can be set to -1 to force a wipe on the next draw
var
  wipegamestate: integer = -1;   // JVAL was gamestate_t = GS_DEMOSCREEN;
  wipedisplay: boolean = false;

  devparm: boolean;             // started game with -devparm
  singletics: boolean;          // debug flag to cancel adaptiveness
  noartiskip: boolean;          // whether shift-enter skips an artifact
  autostart: boolean;
  startskill: skill_t;
  defaultskill: integer = 2;
  randomclass: boolean;         // checkparm of -randclass

  startepisode: integer;
  startmap: integer;
  advancedemo: boolean;

  basedefault: string;          // default file

var
  autoloadgwafiles: boolean = true;
  searchdoomwaddir: boolean = true;
  searchdoomwadpath: boolean = true;
  searchsteampaths: boolean = true;
  additionalwadpaths: string = '';

var
  wads_autoload: string = '';
  paks_autoload: string = '';

{$IFDEF OPENGL}

{$ENDIF}

var
  hexdd_pack: boolean = false; // Death Kings of the Dark Citadel pack

var
  showmessageboxonmodified: boolean = false;
{$IFNDEF OPENGL}
  showfullhdlogo: boolean = false;
{$ENDIF}

type
  /// <summary>
  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #185,
  ///   wave 11): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TMainRoutines = class sealed
  public
    //==============================================================================
    //
    // D_ProcessEvents
    //
    //==============================================================================
    class procedure D_ProcessEvents; static;

    //==============================================================================
    //
    // D_DoAdvanceDemo
    //
    //==============================================================================
    class procedure D_DoAdvanceDemo; static;

    //==============================================================================
    //
    // D_AddFile
    //
    //==============================================================================
    class procedure D_AddFile(const fname1: string); static;

    //==============================================================================
    //
    // D_DoomMain()
    // Not a globally visible function, just included for source reference,
    // calls all startup code, parses command line options.
    // If not overrided by user input, calls N_AdvanceDemo.
    //
    //==============================================================================
    class procedure D_DoomMain; static;

    //==============================================================================
    // D_PostEvent
    //
    // Called by IO functions when input is detected.
    //
    //==============================================================================
    class procedure D_PostEvent(ev: Pevent_t); static;

    //==============================================================================
    // D_PageTicker
    //
    // BASE LEVEL
    //
    //==============================================================================
    class procedure D_PageTicker; static;

    //==============================================================================
    //
    // D_PageDrawer
    //
    //==============================================================================
    class procedure D_PageDrawer; static;

    //==============================================================================
    //
    // D_AdvanceDemo
    //
    //==============================================================================
    class procedure D_AdvanceDemo; static;

    //==============================================================================
    //
    // D_StartTitle
    //
    //==============================================================================
    class procedure D_StartTitle; static;

    //==============================================================================
    //
    // D_Display
    //
    //==============================================================================
    class procedure D_Display; static;

    //==============================================================================
    //
    // D_Configure
    // Gives the unit the engine this port runs on. The composition root calls it
    //
    //==============================================================================
    class procedure D_Configure(const AEngine: IIdTechEngine); static;

    //==============================================================================
    //
    // D_EngineVersion
    // The version number of the engine (207 for 2.07)
    //
    //==============================================================================
    class function D_EngineVersion: integer; static;

    //==============================================================================
    //
    // D_Version
    //
    //==============================================================================
    class function D_Version: string; static;

    //==============================================================================
    //
    // D_VersionBuilt
    //
    //==============================================================================
    class function D_VersionBuilt: string; static;

    //==============================================================================
    //
    // D_ShutDown
    //
    //==============================================================================
    class procedure D_ShutDown; static;

    //==============================================================================
    //
    // D_FileInDoomPath
    //
    //==============================================================================
    class function D_FileInDoomPath(const fn: string): string; static;

    //==============================================================================
    //
    // D_ConfigureIwad
    //
    //==============================================================================
    class procedure D_ConfigureIwad(const ALocator: IIwadLocator; const AIdentifier: IIwadIdentifier); static;

{$IFDEF OPENGL}
    //==============================================================================
    //
    // D_ConfigureGlbsp
    // Gives the glBSP runner that builds the GL nodes of the files added at startup
    // (ComposeEngine, OpenGL only)
    //
    //==============================================================================
    class procedure D_ConfigureGlbsp(const ARunner: IEngineGlbspRunner); static;
{$ENDIF}

    //==============================================================================
    //
    // D_ConfigureGameDefines
    //
    // The defines of the game (D_FillGameDefines adds them), that the script
    // preprocessor reads: given by the composition root; without it the start of the
    // game stops with I_Error.
    //
    //==============================================================================
    class procedure D_ConfigureGameDefines(const ADefines: IScriptGameDefines); static;

    //==============================================================================
    //
    // D_ConfigureActorDef
    //
    // The reader of the ACTORDEF, DECORATE and SNDINFO lumps, given by the
    // composition root; without it the start of the game stops with I_Error.
    //
    //==============================================================================
    class procedure D_ConfigureActorDef(const ALumps: IEngineActorDefLumps); static;

    //==============================================================================
    //
    // D_ConfigureAutoLoad
    //
    // The reader of the AUTOLOAD lumps, given by the composition root; without it the
    // start of the game stops with I_Error.
    //
    //==============================================================================
    class procedure D_ConfigureAutoLoad(const AReader: IAutoLoadReader); static;

    //==============================================================================
    //
    // D_ConfigureStartup
    //
    // The expander of the response files (@name) and the resolver of the screen size from the
    // command line, given by the composition root; without them the start of the game stops
    // with I_Error.
    //
    //==============================================================================
    class procedure D_ConfigureStartup(const AResponseFiles: IResponseFileExpander;
      const AScreenSize: IScreenSizeResolver); static;

    //==============================================================================
    //
    // D_ConfigureConsole
    //
    // The console, given by the composition root: D_DoomMain starts it, the loop gives it
    // the keys and draws it, D_ShutDown frees it.
    //
    //==============================================================================
    class procedure D_ConfigureConsole(const AConsole: IEngineConsole); static;

    //==============================================================================
    //
    // D_ConfigureNetGame
    //
    // The loop of the game around the network, given by the composition root.
    //
    //==============================================================================
    class procedure D_ConfigureNetGame(const ANetGame: IEngineNetGame); static;

    //==============================================================================
    //
    // D_ConfigureDefaults
    //
    // The defaults of the configuration file, given by the composition root.
    //
    //==============================================================================
    class procedure D_ConfigureDefaults(const ADefaults: IEngineDefaults); static;

    //==============================================================================
    //
    // D_ConfigureScreenshot
    //
    // The screenshots (-shot), given by the composition root.
    //
    //==============================================================================
    class procedure D_ConfigureScreenshot(const AScreenshot: IEngineScreenshot); static;

    //==============================================================================
    //
    // D_ConfigureLevel
    //
    // The loading of the levels, given by the composition root: D_DoomMain starts it and frees it.
    // Without it the game stops with I_Error.
    //
    //==============================================================================
    class procedure D_ConfigureLevel(const ALoader: ILevelLoader); static;
  end;


implementation

uses
  DelphiDoom.Engine.Parity.Hooks,
  d_delphi,
  DelphiDoom.CommandLine.FileList,
  DelphiDoom.Wad.Pak.GameDirectories,
  deh_base,
  deh_main,
  doomstat,
  d_ticcmd,
  d_player,
  d_net,
  d_notifications,
  c_con,
  c_cmds,
{$IFNDEF OPENGL}
  f_wipe,
{$ENDIF}
  f_finale,
  m_argv,
  m_base,
  m_misc,
  m_menu,
  mt_utils,
  xn_strings,
  info,
  info_common,
  info_rnd,
  i_system,
  i_io,
  i_startup,
  DelphiDoom.Iwad.Types,
{$IFDEF OPENGL}
  gl_main,
{$ELSE}
  r_defs,
  r_fake3d,
  i_video,
  DelphiDoom.Video.Types,
{$ENDIF}
  g_game,
  g_demo,
  sb_bar,
  hu_stuff,
  in_stuff,
  am_map,
  p_setup,
  p_mobj_h,
  p_mobj,
  p_acs,
  ps_main,
  psi_overlay,
  r_draw,
  r_main,
  r_hires,
  r_intrpl,
  r_data,
  r_camera,
  r_lights,
  sounddata,
  s_sound,
  s_sndseq,
  s_pk3sounds,
  sc_states,
  sv_save,
  sv_hexen,
  v_data,
  v_video,
  w_wad,
  w_pak,
  z_zone;

var
  // given by the composition root (D_ConfigureGameDefines)
  main_gamedefines: IScriptGameDefines = nil;

//==============================================================================
//
// D_ConfigureGameDefines
//
//==============================================================================
class procedure TMainRoutines.D_ConfigureGameDefines(const ADefines: IScriptGameDefines);
begin
  main_gamedefines := ADefines;
end;

type
  /// <summary>
  ///   The routines that only this unit calls, as static methods with the text and the names of the old free routines
  ///   (issue #185, wave 11): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TMainLocalRoutines = class sealed
  public
    class function D_GameDefines: IScriptGameDefines; static;
    class function D_ActorDef: IEngineActorDefLumps; static;
    class function D_AutoLoad: IAutoLoadReader; static;
    class function D_ResponseFiles: IResponseFileExpander; static;
    class function D_ScreenSize: IScreenSizeResolver; static;
    class function D_Console: IEngineConsole; static;
    class function D_NetGame: IEngineNetGame; static;
    class function D_Defaults: IEngineDefaults; static;
    class function D_Screenshot: IEngineScreenshot; static;
    class procedure D_FinishUpdate; static;
    class procedure D_RenderPlayerView(player: Pplayer_t); static;
    class procedure D_DoomLoop; static;
{$IFDEF OPENGL}
    class function D_GlbspRunner: IEngineGlbspRunner; static;
{$ENDIF}
    class procedure D_WadsAutoLoad(fnames: string); static;
    class procedure D_PaksAutoload(fnames: string); static;
    class procedure D_AddSystemWAD; static;
    class procedure IdentifyVersion; static;
    class procedure FindResponseFile; static;
{$IFNDEF OPENGL}
    class procedure D_CmdHOM; static;
{$ENDIF}
    class procedure D_CmdVersion; static;
    class procedure D_CmdAddPakFile(const parm: string); static;
    class procedure D_StartThinkers; static;
    class procedure D_StopThinkers; static;
    class procedure D_AddWADFiles(const parm: string); static;
    class procedure D_AddPAKFiles(const parm: string); static;
    class procedure D_AddDEHFiles(const parm: string); static;
    class procedure D_IdentifyGameDirectories; static;
    class procedure D_CheckCommonParams; static;
    class procedure D_CheckInteterminedMode; static;
    class procedure D_FillGameDefines; static;
    class procedure M_FindDefaultFile; static;
    class function D_LevelLoader: ILevelLoader; static;
  end;

//==============================================================================
//
// D_GameDefines
//
//==============================================================================
class function TMainLocalRoutines.D_GameDefines: IScriptGameDefines;
begin
  if main_gamedefines = nil then
    I_Error('D_ConfigureGameDefines() was not called: the defines of the game are missing');
  result := main_gamedefines;
end;

var
  // given by the composition root (D_ConfigureActorDef)
  main_actordef: IEngineActorDefLumps = nil;

//==============================================================================
//
// D_ConfigureActorDef
//
//==============================================================================
class procedure TMainRoutines.D_ConfigureActorDef(const ALumps: IEngineActorDefLumps);
begin
  main_actordef := ALumps;
end;

//==============================================================================
//
// D_ActorDef
//
//==============================================================================
class function TMainLocalRoutines.D_ActorDef: IEngineActorDefLumps;
begin
  if main_actordef = nil then
    I_Error('D_ConfigureActorDef() was not called: the ACTORDEF lumps cannot be read');
  result := main_actordef;
end;
var
  // given by the composition root (D_ConfigureAutoLoad)
  main_autoload: IAutoLoadReader = nil;

//==============================================================================
//
// D_ConfigureAutoLoad
//
//==============================================================================
class procedure TMainRoutines.D_ConfigureAutoLoad(const AReader: IAutoLoadReader);
begin
  main_autoload := AReader;
end;

//==============================================================================
//
// D_AutoLoad
//
//==============================================================================
class function TMainLocalRoutines.D_AutoLoad: IAutoLoadReader;
begin
  if main_autoload = nil then
    I_Error('D_ConfigureAutoLoad() was not called: the AUTOLOAD lumps cannot be read');
  result := main_autoload;
end;

var
  // given by the composition root (D_ConfigureStartup)
  main_responsefiles: IResponseFileExpander = nil;
  main_screensize: IScreenSizeResolver = nil;

//==============================================================================
//
// D_ConfigureStartup
//
//==============================================================================
class procedure TMainRoutines.D_ConfigureStartup(const AResponseFiles: IResponseFileExpander;
  const AScreenSize: IScreenSizeResolver);
begin
  main_responsefiles := AResponseFiles;
  main_screensize := AScreenSize;
end;

//==============================================================================
//
// D_ResponseFiles
//
//==============================================================================
class function TMainLocalRoutines.D_ResponseFiles: IResponseFileExpander;
begin
  if main_responsefiles = nil then
    I_Error('D_ConfigureStartup() was not called: the response files cannot be read');
  result := main_responsefiles;
end;

//==============================================================================
//
// D_ScreenSize
//
//==============================================================================
class function TMainLocalRoutines.D_ScreenSize: IScreenSizeResolver;
begin
  if main_screensize = nil then
    I_Error('D_ConfigureStartup() was not called: the screen size cannot be read');
  result := main_screensize;
end;
var
  // given by the composition root (D_ConfigureConsole, D_ConfigureNetGame,
  // D_ConfigureDefaults, D_ConfigureScreenshot)
  main_console: IEngineConsole = nil;
  main_netgame: IEngineNetGame = nil;
  main_defaults: IEngineDefaults = nil;
  main_screenshot: IEngineScreenshot = nil;

//==============================================================================
//
// D_ConfigureConsole
//
//==============================================================================
class procedure TMainRoutines.D_ConfigureConsole(const AConsole: IEngineConsole);
begin
  main_console := AConsole;
end;

//==============================================================================
//
// D_Console
//
//==============================================================================
class function TMainLocalRoutines.D_Console: IEngineConsole;
begin
  if main_console = nil then
    I_Error('D_ConfigureConsole() was not called: the console is missing');
  result := main_console;
end;

//==============================================================================
//
// D_ConfigureNetGame
//
//==============================================================================
class procedure TMainRoutines.D_ConfigureNetGame(const ANetGame: IEngineNetGame);
begin
  main_netgame := ANetGame;
end;

//==============================================================================
//
// D_NetGame
//
//==============================================================================
class function TMainLocalRoutines.D_NetGame: IEngineNetGame;
begin
  if main_netgame = nil then
    I_Error('D_ConfigureNetGame() was not called: the network is missing');
  result := main_netgame;
end;

//==============================================================================
//
// D_ConfigureDefaults
//
//==============================================================================
class procedure TMainRoutines.D_ConfigureDefaults(const ADefaults: IEngineDefaults);
begin
  main_defaults := ADefaults;
end;

//==============================================================================
//
// D_Defaults
//
//==============================================================================
class function TMainLocalRoutines.D_Defaults: IEngineDefaults;
begin
  if main_defaults = nil then
    I_Error('D_ConfigureDefaults() was not called: the defaults are missing');
  result := main_defaults;
end;

//==============================================================================
//
// D_ConfigureScreenshot
//
//==============================================================================
class procedure TMainRoutines.D_ConfigureScreenshot(const AScreenshot: IEngineScreenshot);
begin
  main_screenshot := AScreenshot;
end;

//==============================================================================
//
// D_Screenshot
//
//==============================================================================
class function TMainLocalRoutines.D_Screenshot: IEngineScreenshot;
begin
  if main_screenshot = nil then
    I_Error('D_ConfigureScreenshot() was not called: the screenshots are missing');
  result := main_screenshot;
end;


const
  BGCOLOR = 7;
  FGCOLOR = 8;

//==============================================================================
//
// D_DoomLoop()
// Not a globally visible function,
//  just included for source reference,
//  called by D_DoomMain, never exits.
// Manages timing and IO,
//  calls all ?_Responder, ?_Ticker, and ?_Drawer,
//  calls I_GetTime, I_StartFrame, and I_StartTic
//
// D_PostEvent
// Called by the I/O functions when input is detected
//
//==============================================================================
class procedure TMainRoutines.D_PostEvent(ev: Pevent_t);
begin
  events[eventhead] := ev^;
  inc(eventhead);
  eventhead := eventhead and (MAXEVENTS - 1);
end;

//==============================================================================
//
// D_ProcessEvents
// Send all the events of the given timestamp down the responder chain
//
//==============================================================================
class procedure TMainRoutines.D_ProcessEvents;
var
  ev: Pevent_t;
begin
  if I_GameFinished then
    exit;

  while eventtail <> eventhead do
  begin
    ev := @events[eventtail];
    if TMainLocalRoutines.D_Console.Respond(ev) then
      // console ate the event
    else if TMenuRoutines.M_Responder(ev) then
      // menu ate the event
    else
      G_Responder(ev);
    if I_GameFinished then
    begin
      eventtail := eventhead;
      exit;
    end;
    inc(eventtail);
    eventtail := eventtail and (MAXEVENTS - 1);
  end;
end;

//
// D_Display
//  draw current display, possibly wiping it from the previous
//

var
  viewactivestate: boolean = false;
  menuactivestate: boolean = false;
  inhelpscreensstate: boolean = false;
  borderdrawcount: integer;
  nodrawers: boolean = false; // for comparative timing purposes
  noblit: boolean = false;    // for comparative timing purposes
  norender: boolean = false;  // for comparative timing purposes
{$IFNDEF OPENGL}
  hom: boolean = false; // HOM detection
  blancbeforerender: boolean = false;
{$ENDIF}
  autoscreenshot: boolean = false;
  shotnumber: integer = 0;
  lastshotnumber: integer = -1;

//==============================================================================
//
// D_FinishUpdate
//
//==============================================================================
class procedure TMainLocalRoutines.D_FinishUpdate;
begin
  Parity_AfterFrame; // the parity tools (nothing when they are off)
  if not noblit then
    I_FinishUpdate; // page flip or blit buffer
  if autoscreenshot then
  begin
    shotnumber := I_GetTime;
    if shotnumber <> lastshotnumber then
    begin
      D_Screenshot.Take(IntToStrZFill(8, shotnumber), true);
      inc(shotnumber);
    end;
  end;
end;

//==============================================================================
//
// D_RenderPlayerView
//
//==============================================================================
class procedure TMainLocalRoutines.D_RenderPlayerView(player: Pplayer_t);
{$IFNDEF OPENGL}
var
  stime: extended;
{$ENDIF}
begin
  if norender then
  begin
    R_PlayerViewBlanc(aprox_black);
    exit;
  end;

{$IFNDEF OPENGL}
  if hom then
  begin
    stime := I_GetSysTime;
    if round(stime) = Trunc(stime) then
      R_PlayerViewBlanc(aprox_black)
    else
      R_PlayerViewBlanc(aprox_red);
  end
  else if blancbeforerender then
    R_PlayerViewBlanc(aprox_black);
{$ENDIF}

  if player <> nil then
    R_RenderPlayerView(player);
end;

var
  diskbusyend: integer = -1;
  {$IFNDEF OPENGL}
  oldusemultithread: boolean = false;
  {$ENDIF}

//==============================================================================
//
// D_Display
//
//==============================================================================
class procedure TMainRoutines.D_Display;

{$IFDEF OPENGL}

//==============================================================================
//
// D_DisplayHU
//
//==============================================================================
procedure D_DisplayHU;
{$ENDIF}
var
  y: integer;
  redrawsbar: boolean;
  redrawbkscn: boolean;
  palette: PByteArray;
  drawhu: boolean;
  nowtime: integer;
{$IFNDEF OPENGL}
  tics: integer;
  wipe: boolean;
  wipestart: integer;
  done: boolean;
  oldvideomode: videomode_t;
{$ENDIF}
begin
{$IFNDEF OPENGL}
  HU_DoFPSStuff;
{$ENDIF}

  if nodrawers then
    exit; // for comparative timing / profiling

  redrawsbar := false;
  redrawbkscn := false;
  drawhu := false;

  if borderneedsrefresh then
    borderdrawcount := 3;

  // change the view size if needed
  if setsizeneeded then
  begin
    R_ExecuteSetViewSize;
    TGameSession.OldGameState := -1; // force background redraw
    borderdrawcount := 3;
  end;
{$IFNDEF OPENGL}
  if oldusemultithread <> usemultithread then
  begin
    R_SetRenderingFunctions;
    oldusemultithread := usemultithread;
  end;
{$ENDIF}

{$IFNDEF OPENGL}
  // save the current screen if about to wipe
  if (Ord(TGameSession.GameState) <> wipegamestate) and ((TGameSession.GameState = GS_DEMOSCREEN) or (wipegamestate = Ord(GS_DEMOSCREEN))) then
  begin
    wipe := true;
    wipe_StartScreen;
  end
  else
    wipe := false;
{$ENDIF}

  if (TGameSession.GameState = GS_LEVEL) and (TGameSession.GameTic <> 0) then
    HU_Erase;

  // do buffered drawing
  case TGameSession.GameState of
    GS_LEVEL:
      begin
        if TGameSession.GameTic <> 0 then
        begin
          if amstate = am_only then
            AM_Drawer;
          redrawsbar := true;
        end;
      end;
    GS_INTERMISSION:
      TIntermissionRoutines.IN_Drawer;
    GS_FINALE:
      TFinaleRoutines.F_Drawer;
    GS_DEMOSCREEN:
      D_PageDrawer;
  end;

  if Ord(TGameSession.GameState) <> TGameSession.OldGameState then
  begin
  // clean up border stuff
    palette := V_ReadPalette(PU_STATIC);
    I_SetPalette(palette);
    V_SetPalette(palette);
    Z_ChangeTag(palette, PU_CACHE);
    borderdrawcount := 3;
  end;

  // draw the view directly
  if TGameSession.GameState = GS_LEVEL then
  begin
    if (amstate <> am_only) and (TGameSession.GameTic <> 0) then
    begin
      TMainLocalRoutines.D_RenderPlayerView(@TGameSession.Players[displayplayer]);
      if amstate = am_overlay then
        AM_Drawer;
    end;

    redrawsbar := true;
    if TGameSession.GameTic <> 0 then
      drawhu := true;

  // see if the border needs to be initially drawn
{$IFNDEF OPENGL}
    if needsbackscreen or (TGameSession.OldGameState <> Ord(GS_LEVEL)) then
    begin
      viewactivestate := false; // view was not active
      R_FillBackScreen;         // draw the pattern into the back screen
    end;
{$ENDIF}
  // see if the border needs to be updated to the screen
    if amstate <> am_only then
    begin
      if scaledviewwidth <> SCREENWIDTH then
      begin
        if sbiconsactive or menuactive or menuactivestate or not viewactivestate or TMainLocalRoutines.D_Console.IsActive then
          borderdrawcount := 3;
        if borderdrawcount > 0 then
        begin
          R_DrawViewBorder; // erase old menu stuff
          redrawbkscn := true;
          dec(borderdrawcount);
        end;
      end;
    end;
  end;

  menuactivestate := menuactive;
  viewactivestate := viewactive;
  inhelpscreensstate := inhelpscreens;
  TGameSession.OldGameState := Ord(TGameSession.GameState);
  wipegamestate := Ord(TGameSession.GameState);

  // draw pause pic
  if TGameSession.Paused then
  begin
    if amstate = am_only then
      y := 4
    else
      y := (viewwindowy * 200) div SCREENHEIGHT + 4;
    V_DrawPatch(160, y, SCN_FG,
      'PAUSED', true);
  end;

  if drawhu then
    HU_Drawer;

  nowtime := I_GetTime;

  if isdiskbusy then
  begin
    diskbusyend := nowtime + 4; // Display busy disk for a little...
    isdiskbusy := false;
  end;

  if diskbusyend > nowtime then
  begin
    // JVAL: Overlay Drawer before menus
    OVR_Drawer;

    if redrawsbar then
      TStatusBarRoutines.SB_Drawer;

    // Menus go directly to the screen
    TMenuRoutines.M_Drawer; // Menu is drawn even on top of everything

    // Console goes directly to the screen
    TMainLocalRoutines.D_Console.Draw;   // Console is drawn even on top of menus

    // Draw disk busy patch
    R_DrawDiskBusy; // Draw disk busy on top of console
  end
  else if (diskbusyend <= nowtime) and (diskbusyend <> -1) then
  begin
    if not redrawbkscn then
    begin
      R_DrawViewBorder;
      if drawhu then
        HU_Drawer;
    end;

    // JVAL: Overlay Drawer before menus
    OVR_Drawer;

    if redrawsbar then
      TStatusBarRoutines.SB_Drawer;

    TMenuRoutines.M_Drawer;
    TMainLocalRoutines.D_Console.Draw;
    diskbusyend := -1;
  end
  else
  begin
    // JVAL: Overlay Drawer before menus
    OVR_Drawer;

    if redrawsbar then
      TStatusBarRoutines.SB_Drawer;

    TMenuRoutines.M_Drawer;
    TMainLocalRoutines.D_Console.Draw;
  end;

  TMainLocalRoutines.D_NetGame.Update; // send out any new accumulation

  {$IFNDEF OPENGL}
  // normal update
  if not wipe then
  begin
    TMainLocalRoutines.D_FinishUpdate; // page flip or blit buffer
    exit;
  end;

  // wipe update
  wipe_EndScreen;

  wipedisplay := true;
  wipestart := I_GetTime - 1;

  oldvideomode := videomode;
  videomode := vm32bit;
  repeat
    repeat
      nowtime := I_GetTime;
      tics := nowtime - wipestart;
    until tics <> 0;
    wipestart := nowtime;
    done := wipe_Ticker(tics);
    TMenuRoutines.M_Drawer;         // Menu is drawn even on top of wipes
    TMainLocalRoutines.D_Console.Draw;         // Console draw on top of wipes and menus
    TMainLocalRoutines.D_FinishUpdate;   // page flip or blit buffer
    HU_DoFPSStuff;
  until done;
  videomode := oldvideomode;
  wipedisplay := false;
  {$ENDIF}
end;
{$IFDEF OPENGL}
begin
  I_StartUpdate;
  HU_DoFPSStuff;
  if firstinterpolation then
    MT_ZeroMemory(screen32, V_GetScreenWidth(SCN_FG) * V_GetScreenHeight(SCN_FG) * 4);
  if TGameSession.GameState = GS_LEVEL then
  begin
    if (amstate <> am_only) and (TGameSession.GameTic <> 0) then
    begin
      R_FillBackScreen; // draw the pattern into the back screen
      TMainLocalRoutines.D_RenderPlayerView(@TGameSession.Players[displayplayer]);
    end;
  end;
  if TGameSession.GameState = GS_LEVEL then
    if amstate = am_overlay then
      AM_Drawer;
  D_DisplayHU;
  TMainLocalRoutines.D_FinishUpdate; // page flip or blit buffer
end;
{$ENDIF}

//
//  D_DoomLoop
//

{$IFDEF DEBUG}
var
  internalerrors: integer = 0;
{$ENDIF}

//==============================================================================
//
// D_DoomLoop
//
//==============================================================================
class procedure TMainLocalRoutines.D_DoomLoop;
{$IFNDEF DEBUG}
var
  iscritical: boolean;
{$ENDIF}
begin
  if TGameSession.DemoRecording then
    G_BeginRecording;

  while true do
  begin
{$IFDEF DEBUG}
    try
{$ENDIF}
    // frame syncronous IO operations
    I_StartFrame;

{$IFNDEF DEBUG}
    iscritical := not usemultithread and not devparm and criticalcpupriority;
    if iscritical then
      I_SetCriticalCPUPriority;
{$ENDIF}

    // process one or more tics
    if singletics then
      D_NetGame.RunSingleTic // will run only one tick
    else
      D_NetGame.RunMultipleTics; // will run at least one tick

{$IFNDEF DEBUG}
    if iscritical then
      I_SetNormalCPUPriority;
{$ENDIF}

    S_UpdateSounds(TGameSession.Players[TGameSession.ConsolePlayer].mo);// move positional sounds

    D_RunNotifications;

{$IFDEF DEBUG}
    except
      inc(internalerrors);
      fprintf(debugfile, 'Internal Error No %d'#13#10, [internalerrors]);
    end;
{$ENDIF}
  end;
end;

//
//  DEMO LOOP
//
var
  demosequence: integer;
  pagetic: integer;
  pagename: string;

//==============================================================================
//
// D_PageTicker
// Handles timing for warped projection
//
//==============================================================================
class procedure TMainRoutines.D_PageTicker;
begin
  dec(pagetic);
  if pagetic < 0 then
    D_AdvanceDemo;
end;

//
// D_PageDrawer
//
{$IFNDEF OPENGL}
var
  fullhdpatch: integer = -2;
{$ENDIF}

//==============================================================================
//
// D_PageDrawer
//
//==============================================================================
class procedure TMainRoutines.D_PageDrawer;
{$IFNDEF OPENGL}
var
  pt: Ppatch_t;
{$ENDIF}
begin
  V_PageDrawer(pagename);
  {$IFNDEF OPENGL}
  if showfullhdlogo then
    if demosequence = 0 then
      if (SCREENWIDTH = 1920) and (SCREENHEIGHT = 1080) then
      begin
        if fullhdpatch = -2 then
          fullhdpatch := W_CheckNumForName('FULLHD');
        if fullhdpatch > 0 then
        begin
          pt := W_CacheLumpNum(fullhdpatch, PU_STATIC);
          V_DrawPatch(120, 1020, SCN_FG, pt, false);
          Z_ChangeTag(pt, PU_CACHE);
        end;
      end;
  {$ENDIF}
  if demosequence = 1 then
    V_DrawPatch(4, 160, SCN_FG, W_CacheLumpName('ADVISOR', PU_CACHE), true);
end;

//==============================================================================
//
// D_AdvanceDemo
// Called after each demo or intro demosequence finishes
//
//==============================================================================
class procedure TMainRoutines.D_AdvanceDemo;
begin
  advancedemo := true;
end;

//==============================================================================
// D_DoAdvanceDemo
//
// This cycles through the demo sequences.
// FIXME - version dependend demo numbers?
//
//==============================================================================
class procedure TMainRoutines.D_DoAdvanceDemo;
begin
  TGameSession.Players[TGameSession.ConsolePlayer].playerstate := PST_LIVE;  // not reborn
  advancedemo := false;
  TGameSession.UserGame := false; // no save/end game here
  TGameSession.Paused := false;
  TGameSession.GameAction := ga_nothing;

  demosequence := (demosequence + 1) mod 7;

  case demosequence of
    0:
      begin
        pagetic := 280;
        TGameSession.GameState := GS_DEMOSCREEN;
        pagename := pg_TITLE;
        S_StartMusic(Ord(mus_hexen));
      end;
    1:
      begin
        pagetic := 210;
        TGameSession.GameState := GS_DEMOSCREEN;
        pagename := pg_TITLE;
      end;
    2:
      begin
        G_DeferedPlayDemo('1');
      end;
    3:
      begin
        pagetic := 200;
        TGameSession.GameState := GS_DEMOSCREEN;
        pagename := pg_CREDIT;
      end;
    4:
      begin
        G_DeferedPlayDemo('2');
      end;
    5:
      begin
        pagetic := 200;
        TGameSession.GameState := GS_DEMOSCREEN;
        pagename := pg_CREDIT;
      end;
    6:
      begin
        G_DeferedPlayDemo('3');
      end;
  end;
end;

//==============================================================================
//
// D_StartTitle
//
//==============================================================================
class procedure TMainRoutines.D_StartTitle;
begin
  TGameSession.GameAction := ga_nothing;
  demosequence := -1;
  D_AdvanceDemo;
end;

var
  wadfiles: TDStringList;

{$IFDEF OPENGL}
var
  // given by the composition root (D_ConfigureGlbsp)
  glbsp_runner: IEngineGlbspRunner = nil;

//==============================================================================
//
// D_ConfigureGlbsp
//
//==============================================================================
class procedure TMainRoutines.D_ConfigureGlbsp(const ARunner: IEngineGlbspRunner);
begin
  glbsp_runner := ARunner;
end;

//==============================================================================
//
// D_GlbspRunner
//
//==============================================================================
class function TMainLocalRoutines.D_GlbspRunner: IEngineGlbspRunner;
begin
  if glbsp_runner = nil then
    I_Error('D_AddFile(): the glBSP runner was not given (D_ConfigureGlbsp)');
  result := glbsp_runner;
end;
{$ENDIF}

//==============================================================================
//
// D_AddFile
//
//==============================================================================
class procedure TMainRoutines.D_AddFile(const fname1: string);
var
  fname2: string;
{$IFDEF OPENGL}
  path: string;
  ext: string;
  len: integer;
  gwafname: string;
{$ENDIF}
begin
  if fname1 <> '' then
  begin
    fname2 := D_FileInDoomPath(fname1);
    if wadfiles.IndexOf(fname2) >= 0 then
      exit;
    try
      wadfiles.Add(fname2);
      PAK_AddFile(fname2);
      if strupper(fname(fname2)) = 'HEXDD.WAD' then
        hexdd_pack := true
      else
      // the parms after p are wadfile/lump names,
      // until end of parms or another - preceded parm
        modifiedgame := true; // homebrew levels
    {$IFDEF OPENGL}
    // JVAL: If exists automatically loads GWA file
    // GL_xxxx lumps has lower priority from GWA files, that's for we
    // first add the *.GWA file.
      if autoloadgwafiles then
      begin
        ext := strupper(fext(fname2));
        if ext = '.WAD' then
        begin
          gwafname := fname2;
          len := Length(gwafname);
          gwafname[len - 2] := 'G';
          gwafname[len - 1] := 'W';
          gwafname[len] := 'A';
          if fexists(gwafname) then
            wadfiles.Add(gwafname)
          else
          begin
            path := M_SaveFileName('DATA\');
            MkDir(path);
            path := path + 'BSP\';
            MkDir(path);
            gwafname := path + fname(gwafname);
            if fexists(gwafname) then
              wadfiles.Add(gwafname)
            else if TMainLocalRoutines.D_GlbspRunner.BuildGlFriendly(fname2, gwafname) then
              wadfiles.Add(gwafname);
          end;
        end;
      end;
    {$ENDIF}
    except
      printf('D_AddFile(): Can not add %s'#13#10, [fname1]);
    end;
  end;
end;

//==============================================================================
//
// D_WadsAutoLoad
//
//==============================================================================
class procedure TMainLocalRoutines.D_WadsAutoLoad(fnames: string);
var
  names: TArray<string>;
  i: integer;
begin
  names := TCommandLineFileList.Split(fnames);
  for i := 0 to Length(names) - 1 do
    TMainRoutines.D_AddFile(names[i]);
end;

//==============================================================================
//
// D_PaksAutoload
//
//==============================================================================
class procedure TMainLocalRoutines.D_PaksAutoload(fnames: string);
var
  names: TArray<string>;
  i: integer;
begin
  names := TCommandLineFileList.Split(fnames);
  for i := 0 to Length(names) - 1 do
    PAK_AddFile(names[i]);
end;

var
  // given by the composition root (D_ConfigureIwad)
  iwad_locator: IIwadLocator = nil;
  iwad_identifier: IIwadIdentifier = nil;

//==============================================================================
//
// D_ConfigureIwad
//
//==============================================================================
class procedure TMainRoutines.D_ConfigureIwad(const ALocator: IIwadLocator; const AIdentifier: IIwadIdentifier);
begin
  iwad_locator := ALocator;
  iwad_identifier := AIdentifier;
end;

//==============================================================================
//
// D_FileInDoomPath
//
//==============================================================================
class function TMainRoutines.D_FileInDoomPath(const fn: string): string;
begin
  if iwad_locator = nil then
    I_Error('D_FileInDoomPath(): the IWAD locator was not given (D_ConfigureIwad)');
  result := iwad_locator.Locate(fn);
end;

const
  SYSWAD = 'Hexen32.swd';

//==============================================================================
//
// D_AddSystemWAD
//
//==============================================================================
class procedure TMainLocalRoutines.D_AddSystemWAD;
var
  ddsyswad: string;
begin
  ddsyswad := TMainRoutines.D_FileInDoomPath(SYSWAD);
  if fexists(ddsyswad) then
    TMainRoutines.D_AddFile(ddsyswad)
  else
    I_Warning('D_AddSystemWAD(): System WAD %s not found.'#13#10, [SYSWAD]);
end;

//==============================================================================
//
// IdentifyVersion
// Checks availability of IWAD files by name,
// to determine whether registered/commercial features
// should be executed (notably loading PWAD's).
//
//==============================================================================
class procedure TMainLocalRoutines.IdentifyVersion;
var
  customname: string;
  ident: TIwadIdentification;
  p: integer;
  i: integer;
begin
  if iwad_identifier = nil then
    I_Error('IdentifyVersion(): the IWAD identifier was not given (D_ConfigureIwad)');

  // the file that the player chose
  customname := '';
  p := M_CheckParm('-mainwad');
  if p = 0 then
    p := M_CheckParm('-iwad');
  if (p > 0) and (p < myargc - 1) then
    customname := myargv[p + 1];
  if iwad_identifier.TryIdentifyCustom(customname, ident) then
  begin
    // Deathkings of the Dark Citadel does not tell the game mode: Hexen is added before it
    if ident.Mode <> igmUnchanged then
      gamemode := indetermined;
    for i := 0 to High(ident.Files) do
    begin
      if i = High(ident.Files) then
        printf(' External main wad in use: %s'#13#10, [ident.CustomPath]);
      TMainRoutines.D_AddFile(ident.Files[i]);
    end;
    exit;
  end;
  ident := iwad_identifier.IdentifyKnown;
  if not ident.Found then
  begin
    printf('Game mode indeterminate.'#13#10);
    gamemode := indetermined;
    exit;
  end;

  case ident.Mode of
    igmShareware: gamemode := shareware;
    igmIndetermined: gamemode := indetermined; // Will check if register or extended wad later
  end;
  TMainRoutines.D_AddFile(ident.Files[0]);
end;

//==============================================================================
// FindResponseFile
//
// Find a Response File
//
// JVAL: Changed to handle more than 1 response files
//
//==============================================================================
class procedure TMainLocalRoutines.FindResponseFile;
var
  arguments: TArray<string>;
  i: integer;
begin
  SetLength(arguments, myargc);
  for i := 0 to myargc - 1 do
    arguments[i] := myargv[i];
  arguments := D_ResponseFiles.Expand(arguments, MAXARGS);
  for i := 0 to Length(arguments) - 1 do
    myargv[i] := arguments[i];
  myargc := Length(arguments);
end;

{$IFNDEF OPENGL}

//==============================================================================
//
// D_CmdHOM
//
//==============================================================================
class procedure TMainLocalRoutines.D_CmdHOM;
begin
  hom := not hom;
  if hom then
    printf('HOM detection enabled'#13#10)
  else
    printf('HOM detection disabled'#13#10);
end;
{$ENDIF}

var
  // The engine this port runs on, given by the composition root (D_Configure)
  idtech_engine: IIdTechEngine = nil;

//==============================================================================
//
// D_Configure
//
//==============================================================================
class procedure TMainRoutines.D_Configure(const AEngine: IIdTechEngine);
begin
  idtech_engine := AEngine;
end;

//==============================================================================
//
// D_EngineVersion
//
//==============================================================================
class function TMainRoutines.D_EngineVersion: integer;
begin
  if idtech_engine <> nil then
    result := idtech_engine.Version.Number
  else
    result := VERSION;
end;

//==============================================================================
//
// D_Version
//
//==============================================================================
class function TMainRoutines.D_Version: string;
begin
  sprintf(result, Apptitle + ' version %d.%.*d', [D_EngineVersion div 100, 2, D_EngineVersion mod 100]);
end;

//==============================================================================
//
// D_VersionBuilt
//
//==============================================================================
class function TMainRoutines.D_VersionBuilt: string;
begin
  sprintf(result, ' built %s', [I_VersionBuilt]);
end;

//==============================================================================
//
// D_CmdVersion
//
//==============================================================================
class procedure TMainLocalRoutines.D_CmdVersion;
begin
  printf('%s,%s'#13#10, [TMainRoutines.D_Version, TMainRoutines.D_VersionBuilt]);
end;

//==============================================================================
//
// D_CmdAddPakFile
//
//==============================================================================
class procedure TMainLocalRoutines.D_CmdAddPakFile(const parm: string);
var
  files: TDStringList;
  i: integer;
begin
  if parm = '' then
  begin
    printf('Please specify the pak file or directory to load'#13#10);
    exit;
  end;

  // JVAL
  // If a shareware game do not allow external files
  if gamemode = shareware then
  begin
    I_Warning('You cannot use external files with the shareware version. Register!'#13#10);
    exit;
  end;

  if (Pos('*', parm) > 0) or (Pos('?', parm) > 0) then // It's a mask
    files := findfiles(parm)
  else
  begin
    files := TDStringList.Create;
    files.Add(parm)
  end;

  try

    for i := 0 to files.Count - 1 do
      if not PAK_AddFile(files[i]) then
        I_Warning('PAK_AddFile(): %s could not be added to PAK file system.'#13#10, [files[i]]);

  finally
    files.Free;
  end;

end;

//==============================================================================
//
// D_StartThinkers
//
//==============================================================================
class procedure TMainLocalRoutines.D_StartThinkers;
begin
  Info_Init(true);
  printf('Thinkers initialized'#13#10);
end;

//==============================================================================
//
// D_StopThinkers
//
//==============================================================================
class procedure TMainLocalRoutines.D_StopThinkers;
begin
  if TGameSession.DemoPlayback then
  begin
    I_Warning('Thinkers can not be disabled during demo playback.'#13#10);
    exit;
  end;

  if TGameSession.DemoRecording then
  begin
    I_Warning('Thinkers can not be disabled during demo recording.'#13#10);
    exit;
  end;

  Info_Init(false);
  printf('Thinkers disabled'#13#10);
end;

//==============================================================================
//
// D_AddWADFiles
//
//==============================================================================
class procedure TMainLocalRoutines.D_AddWADFiles(const parm: string);
var
  p: integer;
begin
  p := M_CheckParm(parm);
  if p <> 0 then
  begin
    inc(p);
    while (p < myargc) and (myargv[p][1] <> '-') do
    begin
      TMainRoutines.D_AddFile(TMainRoutines.D_FileInDoomPath(myargv[p]));
      inc(p);
    end;
  end;
end;

//==============================================================================
//
// D_AddPAKFiles
//
//==============================================================================
class procedure TMainLocalRoutines.D_AddPAKFiles(const parm: string);
var
  p: integer;
begin
  p := M_CheckParm(parm);
  if p <> 0 then
  begin
  // the parms after p are wadfile/lump names,
  // until end of parms or another - preceded parm
    modifiedgame := true; // homebrew levels
    externalpakspresent := true;
    inc(p);
    while (p < myargc) and (myargv[p][1] <> '-') do
    begin
      PAK_AddFile(myargv[p]);
      inc(p);
    end;
  end;
end;

//==============================================================================
//
// D_AddDEHFiles
//
//==============================================================================
class procedure TMainLocalRoutines.D_AddDEHFiles(const parm: string);
var
  p: integer;
begin
  p := M_CheckParm(parm);
  if p <> 0 then
  begin
  // the parms after p are wadfile/lump names,
  // until end of parms or another - preceded parm
    modifiedgame := true; // homebrew levels
    externaldehspresent := true;
    inc(p);
    while (p < myargc) and (myargv[p][1] <> '-') do
    begin
      DEH_ParseFile(myargv[p]);
      inc(p);
    end;
  end;
end;

//==============================================================================
//
// D_IdentifyGameDirectories
//
//==============================================================================
class procedure TMainLocalRoutines.D_IdentifyGameDirectories;
var
  gamedirectorystring: string;
  wadnames: TArray<string>;
  i: integer;
  wad: string;
begin
  gamedirectorystring := 'HEXEN,HEXEN1';
  if hexdd_pack then
    gamedirectorystring := 'HEXDD,' + gamedirectorystring;
  SetLength(wadnames, wadfiles.Count);
  for i := 0 to wadfiles.Count - 1 do
    wadnames[i] := strupper(fname(wadfiles[i]));
  gamedirectorystring := TPakGameDirectories.Compose(gamedirectorystring, wadnames);

  gamedirectories := PAK_GetDirectoryListFromString(gamedirectorystring);
  for i := 0 to gamedirectories.Count - 1 do
  begin
    wad := gamedirectories[i];
    if wad <> '' then
      if wad[length(wad)] = '\' then
        printf(' %s'#13#10, [wad]);
  end;
  MakeDir(SAVEPATH);
end;

//==============================================================================
//
// D_CheckCommonParams
//
//==============================================================================
class procedure TMainLocalRoutines.D_CheckCommonParams;
var
  p: integer;
begin
  p := M_CheckParm('-fullscreen');
  if (p <> 0) and (p <= myargc - 1) then
    fullscreen := {$IFDEF OPENGL}true{$ELSE}FULLSCREEN_SHARED{$ENDIF};

  p := M_CheckParm('-nofullscreen');
  if p = 0 then
    p := M_CheckParm('-windowed');
  if (p <> 0) and (p <= myargc - 1) then
    fullscreen := {$IFDEF OPENGL}false{$ELSE}FULLSCREEN_OFF{$ENDIF};

  p := M_CheckParm('-zaxisshift');
  if (p <> 0) and (p <= myargc - 1) then
    zaxisshift := true;

  p := M_CheckParm('-nozaxisshift');
  if (p <> 0) and (p <= myargc - 1) then
    zaxisshift := false;

{$IFNDEF OPENGL}
  p := M_CheckParm('-fake3d');
  if (p <> 0) and (p <= myargc - 1) then
    usefake3d := true;

  p := M_CheckParm('-nofake3d');
  if (p <> 0) and (p <= myargc - 1) then
    usefake3d := false;
{$ENDIF}

  if M_Checkparm('-ultrares') <> 0 then
    detailLevel := DL_ULTRARES;

  if M_Checkparm('-hires') <> 0 then
    detailLevel := DL_HIRES;

  if M_Checkparm('-normalres') <> 0 then
    detailLevel := DL_NORMAL;

  if M_Checkparm('-mediumres') <> 0 then
    detailLevel := DL_MEDIUM;

  if M_Checkparm('-lowres') <> 0 then
    detailLevel := DL_LOW;

  if M_Checkparm('-lowestres') <> 0 then
    detailLevel := DL_LOWEST;

  if M_Checkparm('-interpolate') <> 0 then
    interpolate := true;

  if M_Checkparm('-nointerpolate') <> 0 then
    interpolate := false;

  p := M_CheckParm('-compatibilitymode');
  if (p <> 0) and (p <= myargc - 1) then
    TGameSession.CompatibilityMode := true;

  p := M_CheckParm('-nocompatibilitymode');
  if (p <> 0) and (p <= myargc - 1) then
    TGameSession.CompatibilityMode := false;

  TGameSession.OldCompatibilityMode := TGameSession.CompatibilityMode;

  p := M_CheckParm('-spawnrandommonsters');
  if (p <> 0) and (p <= myargc - 1) then
    spawnrandommonsters := true;

  p := M_CheckParm('-nospawnrandommonsters');
  if (p <> 0) and (p <= myargc - 1) then
    spawnrandommonsters := false;

  p := M_CheckParm('-mouse');
  if (p <> 0) and (p <= myargc - 1) then
    usemouse := true;

  p := M_CheckParm('-nomouse');
  if (p <> 0) and (p <= myargc - 1) then
    usemouse := false;

  p := M_CheckParm('-invertmouselook');
  if (p <> 0) and (p <= myargc - 1) then
    invertmouselook := true;

  p := M_CheckParm('-noinvertmouselook');
  if (p <> 0) and (p <= myargc - 1) then
    invertmouselook := false;

  p := M_CheckParm('-invertmouseturn');
  if (p <> 0) and (p <= myargc - 1) then
    invertmouseturn := true;

  p := M_CheckParm('-noinvertmouseturn');
  if (p <> 0) and (p <= myargc - 1) then
    invertmouseturn := false;

  p := M_CheckParm('-nojoystick');
  if (p <> 0) and (p <= myargc - 1) then
    usejoystick := false;

  p := M_CheckParm('-joystick');
  if (p <> 0) and (p <= myargc - 1) then
    usejoystick := true;

  D_ScreenSize.Resolve(SCREENWIDTH, SCREENHEIGHT);

  {$IFNDEF OPENGL}
  WINDOWWIDTH := SCREENWIDTH;
  WINDOWHEIGHT := SCREENHEIGHT;
  {$ENDIF}

  singletics := M_CheckParm('-singletics') > 0;
  noartiskip := M_CheckParm('-noartiskip') > 0;

  p := M_CheckParm('-autoscreenshot');
  autoscreenshot := p > 0;

  nodrawers := M_CheckParm('-nodraw') <> 0;
  noblit := M_CheckParm('-noblit') <> 0;
  norender := M_CheckParm('-norender') <> 0;
{$IFNDEF OPENGL}
  blancbeforerender := M_CheckParm('-blancbeforerender') <> 0;
{$ENDIF}

  if M_CheckParm('-usetransparentsprites') <> 0 then
    usetransparentsprites := true;
  if M_CheckParm('-dontusetransparentsprites') <> 0 then
    usetransparentsprites := false;
  if M_CheckParm('-uselightboost') <> 0 then
    uselightboost := true;
  if M_CheckParm('-dontuselightboost') <> 0 then
    uselightboost := false;
  p := M_CheckParm('-lightboostfactor');
  if (p <> 0) and (p < myargc - 1) then
  begin
    p := atoi(myargv[p + 1], -1);
    if (p >= LFACTORMIN) and (p <= LFACTORMAX) then
      lightboostfactor := p
    else
      I_Warning('Invalid lightboostfactor specified from command line %d. Specify a value in range (%d..%d)'#13#10, [p, LFACTORMIN, LFACTORMAX]);
  end;
  if M_CheckParm('-chasecamera') <> 0 then
    chasecamera := true;
  if M_CheckParm('-nochasecamera') <> 0 then
    chasecamera := false;
end;

var
  numwadmaps: integer;

//==============================================================================
//
// D_CheckInteterminedMode
//
//==============================================================================
class procedure TMainLocalRoutines.D_CheckInteterminedMode;
var
  i: integer;
begin
  numwadmaps := 0;
  for i := 0 to 9 do
    if W_CheckNumForName('MAP0' + itoa(i)) <> -1 then
      inc(numwadmaps);
  for i := 10 to 99 do
    if W_CheckNumForName('MAP' + itoa(i)) <> -1 then
      inc(numwadmaps);

  if gamemode = indetermined then
  begin
    // JVAL: OK, let's guess, official demo had 4 maps
    if numwadmaps > 6 then
      gamemode := registered
    else
      gamemode := shareware;
  end;
end;

//==============================================================================
//
// D_FillGameDefines
//
//==============================================================================
class procedure TMainLocalRoutines.D_FillGameDefines;
begin
  D_GameDefines.Add('hexen');
  if hexdd_pack then D_GameDefines.Add('hexdd');
  if gamemode = shareware then
    D_GameDefines.Add('shareware')
  else
    D_GameDefines.Add('registered');

  {$IFDEF OPENGL}
  D_GameDefines.Add('OPENGL');
  {$ENDIF}
end;

//==============================================================================
//
// M_FindDefaultFile
//
//==============================================================================
class procedure TMainLocalRoutines.M_FindDefaultFile;
begin
  if M_CheckParmCDROM then
  begin
    printf(D_CDROM);
    basedefault := CD_WORKDIR + 'Hexen32.ini';
  end
  else
    basedefault := 'Hexen32.ini';
end;

var
  // given by the composition root (D_ConfigureLevel)
  main_levelloader: ILevelLoader = nil;

//==============================================================================
//
// D_ConfigureLevel
//
//==============================================================================
class procedure TMainRoutines.D_ConfigureLevel(const ALoader: ILevelLoader);
begin
  main_levelloader := ALoader;
end;

//==============================================================================
//
// D_LevelLoader
//
//==============================================================================
class function TMainLocalRoutines.D_LevelLoader: ILevelLoader;
begin
  if main_levelloader = nil then
    I_Error('D_ConfigureLevel() was not called: the loading of the levels is missing');
  result := main_levelloader;
end;

//==============================================================================
//
// D_DoomMain
//
//==============================================================================
class procedure TMainRoutines.D_DoomMain;
var
  p: integer;
  filename: string;
  scale: integer;
  _time: integer;
  startloadingtime: LongWord;
  i: integer;
  oldoutproc: TOutProc;
  mb_min: integer; // minimum zone size
  uext: string;
  sharewaremsg: string;
  kparm: string;
  lump: integer;
begin
  startloadingtime := I_GetTickCount;

  SUC_Open;
  outproc := @SUC_Outproc;
  wadfiles := TDSTringList.Create;

  printf('Starting %s, %s'#13#10, [D_Version, D_VersionBuilt]);
{$IFNDEF OPENGL}
  C_AddCmd('tnthom, hom', @TMainLocalRoutines.D_CmdHOM);
{$ENDIF}
  C_AddCmd('ver, version', @TMainLocalRoutines.D_CmdVersion);
  C_AddCmd('addpakfile, loadpakfile, addpak, loadpak', @TMainLocalRoutines.D_CmdAddPakFile);
  C_AddCmd('startthinkers', @TMainLocalRoutines.D_StartThinkers);
  C_AddCmd('stopthinkers', @TMainLocalRoutines.D_StopThinkers);

  SUC_Progress(1);

  printf('M_InitArgv: Initializing command line parameters.'#13#10);
  M_InitArgv;

  SUC_Progress(2);

  TMainLocalRoutines.FindResponseFile;

  printf('I_InitializeIO: Initializing input/output streams.'#13#10);
  I_InitializeIO;

  SUC_Progress(3);

  printf('M_LoadDefaults: Load system defaults.'#13#10);
  TMainLocalRoutines.M_FindDefaultFile;
  TMainLocalRoutines.D_Defaults.Load;              // load before initing other systems

  TMainLocalRoutines.D_AddSystemWAD; // Add system wad first

  SUC_Progress(4);

  TMainLocalRoutines.IdentifyVersion;

  SUC_Progress(5);

  modifiedgame := false;

  TGameSession.NoMonsters := M_CheckParm('-nomonsters') > 0;
  TGameSession.RespawnParm := M_CheckParm('-respawn') > 0;
  TGameSession.FastParm := M_CheckParm('-fast') > 0;
  devparm := M_CheckParm('-devparm') > 0;
  randomclass := M_CheckParm('-randclass') > 0;

  SUC_Progress(6);

  if M_CheckParm('-altdeath') > 0 then
    TGameSession.DeathMatch := 2
  else if M_CheckParm('-deathmatch') > 0 then
    TGameSession.DeathMatch := 1;

  if gamemode = shareware then
    printf(
           '                           ' +
           'Hexen Shareware Startup v%d.%.*d' +
           '                         '#13#10,
            [D_EngineVersion div 100, 2, D_EngineVersion mod 100])
  else
    printf(
           '                            ' +
           '   Hexen Startup v%d.%.*d' +
           '                           '#13#10,
            [D_EngineVersion div 100, 2, D_EngineVersion mod 100]);

  if devparm then
    printf(D_DEVSTR);

  // turbo option
  p := M_CheckParm('-turbo');
  if p <> 0 then
  begin
    if p < myargc - 1 then
    begin
      scale := atoi(myargv[p + 1], 200);
      if scale < 10 then
        scale := 10
      else if scale > 200 then
        scale := 200;
    end
    else
      scale := 200;
    printf(' turbo scale: %d'#13#10, [scale]);
    for i := 0 to Ord(NUMCLASSES) - 1 do
    begin
      forwardmove[i, 0] := forwardmove[i, 0] * scale div 100;
      forwardmove[i, 1] := forwardmove[i, 1] * scale div 100;
      sidemove[i, 0] := sidemove[i, 0] * scale div 100;
      sidemove[i, 1] := sidemove[i, 1] * scale div 100;
    end;
  end;

  SUC_Progress(7);

  // add any files specified on the command line with -file wadfile
  // to the wad list
  //
  // convenience hack to allow -wart e m to add a wad file
  // prepend a tilde to the filename so wadfile will be reloadable
  p := M_CheckParm('-wart');
  if (p <> 0) and (p < myargc - 2) then
  begin
    myargv[p][5] := 'p';     // big hack, change to -warp

  // Map name handling.
    if p < myargc - 2 then
    begin
      sprintf(filename, '~' + DEVMAPS + 'E%sM%s.wad',
        [myargv[p + 1][1], myargv[p + 2][1]]);
      printf('Warping to Episode %s, Map %s.'#13#10,
      [myargv[p + 1], myargv[p + 2]]);
    end;

    D_AddFile(filename);
  end;

  SUC_Progress(8);

  TMainLocalRoutines.D_AddWADFiles('-file');
  for p := 1 to 9 do
    TMainLocalRoutines.D_AddWADFiles('-file' + itoa(p));
  TMainLocalRoutines.D_AddWADFiles('-lfile');  // JVAL launcher specific

  SUC_Progress(9);

  printf('PAK_InitFileSystem: Init PAK/ZIP/PK3/PK4 files.'#13#10);
  PAK_InitFileSystem;

  SUC_Progress(10);

  PAK_LoadPendingPaks;

  SUC_Progress(11);

  TMainLocalRoutines.D_AddPAKFiles('-pakfile');
  for p := 1 to 9 do
    TMainLocalRoutines.D_AddPAKFiles('-pakfile' + itoa(p));

  SUC_Progress(15);

  TMainLocalRoutines.D_AddPAKFiles('-lpakfile'); // JVAL launcher specific

  SUC_Progress(16);

  p := M_CheckParm('-playdemo');

  if p = 0 then
    p := M_CheckParm('-timedemo');

  if (p <> 0) and (p < myargc - 1) then
  begin
    inc(p);
    if CharPos('.', myargv[p]) > 0 then
      filename := myargv[p]
    else
      sprintf(filename,'%s.lmp', [myargv[p]]);
    D_AddFile(filename);
    printf('Playing demo %s.'#13#10, [filename]);
  end;

  // get skill / episode / map from parms
  startskill := skill_t(GetIntegerInRange(defaultskill, Ord(sk_baby), Ord(sk_nightmare)));
  startepisode := 1;
  startmap := 1;
  autostart := false;

  p := M_CheckParm('-skill');
  if (p <> 0) and (p < myargc - 1) then
  begin
    startskill := skill_t(Ord(myargv[p + 1][1]) - Ord('1'));
    autostart := true;
  end;

  p := M_CheckParm('-timer');
  if (p <> 0) and (p < myargc - 1) and (TGameSession.DeathMatch <> 0) then
  begin
    _time := atoi(myargv[p + 1]);
    printf('Levels will end after %d minute' + decide(_time > 1, 's', '') + #13#10, [_time]);
  end;

  p := M_CheckParm('-avg');
  if (p <> 0) and (p <= myargc - 1) and (TGameSession.DeathMatch <> 0) then
    printf('Austin Virtual Gaming: Levels will end after 20 minutes'#13#10);

  TMainLocalRoutines.D_WadsAutoLoad(wads_autoload);
  TMainLocalRoutines.D_PaksAutoload(paks_autoload);

  SUC_Progress(20);

  TMainLocalRoutines.D_CheckCommonParams;

// Try to guess minimum zone memory to allocate
// Give Hexen a little more minimum zone memory than Doom and Heretic
  mb_min := 8 + V_ScreensSize(SCN_FG) div (1024 * 1024);
  if zonesize < mb_min then
    zonesize := mb_min;

  mb_used := zonesize;

  p := M_CheckParm('-zone');
  if (p <> 0) and (p < myargc - 1) then
  begin
    mb_used := atoi(myargv[p + 1]);
    if mb_used < mb_min then
    begin
      printf('Zone memory allocation needs at least %d MB (%d).'#13#10, [mb_min, mb_used]);
      mb_used := mb_min;
    end;
    zonesize := mb_used;
  end;

  // init subsystems
  printf('Z_Init: Init zone memory allocation daemon, allocation %d MB.'#13#10, [mb_used]);
  Z_Init;

  SUC_Progress(30);

  p := M_CheckParm('-nothinkers');
  if p = 0 then
  begin
    printf('I_InitInfo: Initialize information tables.'#13#10);
    Info_Init(true);
  end
  else
  begin
    I_Warning('Thinkers not initialized.'#13#10);
    Info_Init(false);
  end;

  SUC_Progress(31);

  printf('Info_InitStateOwners(): Initialize State Owners.'#13#10);
  Info_InitStateOwners;

  SUC_Progress(32);

  for p := 1 to myargc do
  begin
    uext := strupper(fext(myargv[p]));
    if (uext = '.WAD') or (uext = '.IWAD') or (uext = '.OUT') then
      D_AddFile(D_FileInDoomPath(myargv[p]));
    if (uext = '.PK3') or
       (uext = '.PK4') or
       (uext = '.ZIP') or
       (uext = '.PAK') then
    begin
      modifiedgame := true;
      externalpakspresent := true;
      PAK_AddFile(myargv[p]);
    end;
  end;

  printf('W_Init: Init WADfiles.'#13#10);
  if W_InitMultipleFiles(wadfiles) = 0 then
  begin
    // JVAL
    //  If none wadfile has found as far,
    //  we search the current directory
    //  and we use the first WAD we find
    filename := findfile('*.wad');
    if filename <> '' then
    begin
      I_Warning('Loading unspecified wad file: %s'#13#10, [filename]);
      D_AddFile(filename);
    end
    else
    begin
      filename := findfile('*.iwad');
      if filename <> '' then
      begin
        I_Warning('Loading unspecified wad file: %s'#13#10, [filename]);
        D_AddFile(filename);
      end
    end;
    if W_InitMultipleFiles(wadfiles) = 0 then
      I_Error('W_InitMultipleFiles(): no files found');
  end;

  TMainLocalRoutines.D_CheckInteterminedMode;

  SUC_Progress(38);

  printf('SC_InitGameDefines: Determine global defines.'#13#10);
  TMainLocalRoutines.D_GameDefines.Clear;
  TMainLocalRoutines.D_FillGameDefines;

  SUC_Progress(39);

  printf('W_AutoLoadPakFiles: Autoload required pak files.'#13#10);
  TMainLocalRoutines.D_AutoLoad.Load;

  SUC_Progress(40);

  printf('SC_Init: Initializing script engine.'#13#10);
  TMainLocalRoutines.D_ActorDef.Initialize;

  SUC_Progress(41);

  printf('DEH_Init: Initializing dehacked subsystem.'#13#10);
  SC_DefaultStatedefLump;
  TDehMainRoutines.DEH_Init;

  if M_CheckParm('-internalgamedef') = 0 then
  begin
    lump := W_CheckNumForName('GAMEDEF');
    if lump >= 0 then
    begin
      if strupper(W_LumpCRC32(lump)) <> '39AB9D20' then
        DEH_ParseLumpNum(lump);
    end
    else
      I_Warning('DEH_ParseLumpName(): GAMEDEF lump not found, using defaults.'#13#10);
  end;

  SUC_Progress(42);

  // JVAL: PascalScript
  printf('PS_Init: Initializing pascal script compiler.'#13#10);
  PS_Init;

  SUC_Progress(43);

  printf('SC_ParseSndInfoLumps: Parsing SNDINFO lumps.'#13#10);
  TMainLocalRoutines.D_ActorDef.ParseSoundInfoLumps;

  SUC_Progress(44);

  p := M_CheckParm('-noactordef');
  if p <= 0 then
  begin
    printf('SC_ParseActordefLumps: Parsing ACTORDEF lumps.'#13#10);
    TMainLocalRoutines.D_ActorDef.ParseActorDefLumps;
  end;

  SUC_Progress(45);

  if M_CheckParm('-nowaddehacked') = 0 then
    if not DEH_ParseLumpNames('DEHACKED') then
      printf('DEH_ParseLumpName: DEHACKED lump(s) not found.'#13#10);

  // JVAL Adding dehached files
  TMainLocalRoutines.D_AddDEHFiles('-deh');
  TMainLocalRoutines.D_AddDEHFiles('-bex');

  printf('Info_CheckStates: Check states tables'#13#10);
  Info_CheckStates;

  printf('Info_CheckStatesArgs: Checking states arguments'#13#10);
  Info_CheckStatesArgs;

  printf('Info_SaveActions: Saving state actions'#13#10);
  Info_SaveActions;

  SUC_Progress(50);

  for i := 0 to NUM_STARTUPMESSAGES - 1 do
    if startmsg[i] <> '' then
      printf('%s'#13#10, [startmsg[i]]);

  SUC_Progress(51);

  printf('P_ACSInit: Initializing ACS script.'#13#10);
  P_ACSInit;

  SUC_Progress(52);

  printf('SV_Init: Initializing load/save game subsystem.'#13#10);
  SV_Init;

  SUC_Progress(53);

  printf('T_Init: Initializing texture manager.'#13#10);
  V_InitDrawTextures;

  SUC_Progress(55);

  printf('V_Init: allocate screens.'#13#10);
  V_Init;

  SUC_Progress(56);

  printf('AM_Init: initializing automap.'#13#10);
  AM_Init;

  printf('MObj_Init: initializing mobj commands.'#13#10);
  MObj_Init;

  SUC_Progress(57);

  p := M_CheckParm('-autoexec');
  if (p <> 0) and (p < myargc - 1) then
    autoexecfile := myargv[p + 1]
  else
    autoexecfile := DEFAUTOEXEC;

  printf('M_InitMenus: Initializing menus.'#13#10);
  TMenuRoutines.M_InitMenus;

  SUC_Progress(58);

  sharewaremsg := '';
  sprintf(sharewaremsg, MSG_SHAREWARE, [numwadmaps]);

  SUC_Progress(59);

  printf('D_IdentifyGameDirectories: Identify game directories.'#13#10);
  TMainLocalRoutines.D_IdentifyGameDirectories;

  SUC_Progress(60);

  p := M_CheckParm('-warp');
  if (p <> 0) and (p < myargc - 1) then
  begin
    startmap := atoi(myargv[p + 1]);
    autostart := true;
  end;

  SUC_Progress(61);

  // Check for -file in shareware
  // JVAL
  // Allow modified games if -devparm is specified, for debuging reasons
  if modifiedgame and not devparm then
  begin
    if gamemode = shareware then
      I_DevError(#13#10 + 'D_DoomMain(): You cannot use external files with the shareware version. Register!');

  // If additonal PWAD files are used, print modified banner
    printf(MSG_MODIFIEDGAME);
    if showmessageboxonmodified then
    begin
      oldoutproc := outproc;
      I_IOSetWindowHandle(SUC_GetHandle);
      outproc := @I_IOMessageBox; // Print the message again to messagebox
      printf(MSG_MODIFIEDGAME);
      outproc := oldoutproc;
    end;
  end;

  SUC_Progress(65);

  if hexdd_pack then
  begin
    printf(MSG_HEXDD);
    SUC_SetGameMode('Hexen: Death Kings of the Dark Citadel');
  end
  else if gamemode = registered then
    SUC_SetGameMode('Registered Hexen')
  else
    SUC_SetGameMode('Shareware Hexen');

  case gamemode of
    shareware:
      printf(sharewaremsg);
    registered:
      printf(MSG_COMMERCIAL);
  else
    begin
      printf(MSG_UNDETERMINED);
    end;
  end;

  SUC_Progress(66);

  printf('Info_InitRandom: Initializing randomizers.'#13#10);
  Info_InitRandom;

  SUC_Progress(67);

  printf('M_Init: Init miscellaneous info.'#13#10);
  TMenuRoutines.M_Init;

  SUC_Progress(68);

  p := M_CheckParm('-mmx');
  if p > 0 then
    usemmx := true;

  p := M_CheckParm('-nommx');
  if p > 0 then
    usemmx := false;

  if usemmx then
  begin
    printf('I_DetectCPU: Detecting CPU extensions.'#13#10);
    I_DetectCPU;
  end;
  printf('MT_Init: Initializing multithreading utilities.'#13#10);
  MT_Init;

  SUC_Progress(69);

  printf('W_InitPK3Sounds: Initializing sound files in pk3 filesystem'#13#10);
  W_InitPK3Sounds;

  SUC_Progress(70);

  printf('R_Init: Init %s refresh daemon.'#13#10, [strupper(_GAME)]);
  R_Init;

  SUC_Progress(80);

  printf('P_Init: Init Playloop state.'#13#10);
  TMainLocalRoutines.D_LevelLoader.Initialize;

  SUC_Progress(81);

  printf('D_CheckNetGame: Checking network game status.'#13#10);
  TMainLocalRoutines.D_NetGame.Start;

  SUC_Progress(85);

  printf('S_Init: Setting up sound.'#13#10);
  S_Init(snd_SfxVolume, snd_MusicVolume);

  SUC_Progress(89);

  printf('SV_InitializeSerializers: Setting up serializers.'#13#10);
  SV_InitializeSerializers;

  SUC_Progress(90);

  printf('S_InitSequenceScript: Registering sound sequences.'#13#10);
  S_InitSequenceScript;

  printf('HU_Init: Setting up heads up display.'#13#10);
  HU_Init;

  SUC_Progress(91);

  printf('SB_Init: Init status bar.'#13#10);
  TStatusBarRoutines.SB_Init;

  SUC_Progress(92);

  // check for a driver that wants intermission stats
  p := M_CheckParm('-statcopy');
  if (p > 0) and (p < myargc - 1) then
  begin
    // for statistics driver
    statcopy := pointer(atoi(myargv[p + 1]));
    printf('External statistics registered.'#13#10);
  end;

  // start the apropriate game based on parms
  p := M_CheckParm('-record');

  if (p <> 0) and (p < myargc - 1) then
  begin
    G_RecordDemo(myargv[p + 1]);
    autostart := true;
  end;

  SUC_Progress(93);

{$IFDEF OPENGL}
  GL_InitGraphics;
{$ELSE}
  I_InitGraphics;
{$ENDIF}

  SUC_Progress(96);

  printf('I_Init: Setting up machine state.'#13#10);
  I_Init;

  SUC_Progress(97);

  printf('C_Init: Initializing console.'#13#10);
  TMainLocalRoutines.D_Console.Initialize;

  p := M_CheckParm('-keyboardmode');
  if (p > 0) and (p < myargc - 1) then
  begin
    inc(p);
    kparm := strupper(myargv[p]);
    if (kparm = '0') or (kparm = 'ARROWS') then
      TMenuRoutines.M_SetKeyboardMode(0)
    else if (kparm = '1') or (kparm = 'WASD') then
      TMenuRoutines.M_SetKeyboardMode(1)
    else if (kparm = '2') or (kparm = 'ESDF') then
      TMenuRoutines.M_SetKeyboardMode(2);
  end;

  SUC_Progress(98);

  // JVAL: PascalScript
  printf('PS_CompileAllScripts: Compiling all scripts.'#13#10);
  PS_CompileAllScripts;

  SUC_Progress(100);

  SUC_Close;

  printf(StringOfChar('-', 21) + #13#10);
  printf('Load time: %2.3f secs'#13#10, [(I_GetTickCount - startloadingtime) / 1000]);
  printf(StringOfChar('-', 21) + #13#10);

  p := M_CheckParm('-playdemo');
  if (p <> 0) and (p < myargc - 1) then
  begin
  // JVAL
  /// if -nosingledemo param exists does not
  // quit after one demo
    TGameSession.SingleDemo := M_CheckParm('-nosingledemo') = 0;
    G_DeferedPlayDemo(myargv[p + 1]);
    TMainLocalRoutines.D_DoomLoop;  // never returns
  end;

  p := M_CheckParm('-timedemo');
  if (p <> 0) and (p < myargc - 1) then
  begin
    G_TimeDemo(myargv[p + 1]);
    TMainLocalRoutines.D_DoomLoop;  // never returns
  end;

  p := M_CheckParm('-loadgame');
  if (p <> 0) and (p < myargc - 1) then
    G_LoadGame(Ord(myargv[p + 1][1]) - Ord('0'));

  if TGameSession.GameAction <> ga_loadgame then
  begin
    if autostart or TGameSession.NetGame then
    begin
      G_InitNew(startskill, startepisode, startmap);
    end
    else
      D_StartTitle; // start up intro loop
  end;

  TMainLocalRoutines.D_DoomLoop;  // never returns
end;

//==============================================================================
//
// D_ShutDown
//
//==============================================================================
class procedure TMainRoutines.D_ShutDown;
var
  i: integer;
begin
  printf('M_ShutDownMenus: Shut down menus.'#13#10);
  TMenuRoutines.M_ShutDownMenus;
  printf('C_ShutDown: Shut down console.'#13#10);
  if main_console <> nil then
    main_console.Shutdown;
  printf('P_ShutDown: Shut down Playloop state.'#13#10);
  TMainLocalRoutines.D_LevelLoader.ShutDown;
  printf('R_ShutDown: Shut down %s refresh daemon.', [strupper(_GAME)]);
  R_ShutDown;
  printf('Info_ShutDownRandom: Shut down randomizers.'#13#10);
  Info_ShutDownRandom;
  printf('P_ACSShutDown: Shut down ACS script.'#13#10);
  P_ACSShutDown;
  printf('T_ShutDown: Shut down texture manager.'#13#10);
  V_ShutDownDrawTextures;
  printf('SC_ShutDown: Shut down script engine.'#13#10);
  TMainLocalRoutines.D_ActorDef.ShutDown;
  printf('SC_ShutDownGameDefines: Shut down global defines.'#13#10);
  TMainLocalRoutines.D_GameDefines.Clear;
  // JVAL: PascalScript
  printf('PS_ShutDown: Shut down pascal script compiler.'#13#10);
  PS_ShutDown;
  printf('DEH_ShutDown: Shut down dehacked subsystem.'#13#10);
  TDehMainRoutines.DEH_ShutDown;
  printf('Info_ShutDown: Shut down game definition.'#13#10);
  Info_ShutDown;
  printf('PAK_ShutDown: Shut down PAK/ZIP/PK3/PK4 file system.'#13#10);
  PAK_ShutDown;
  printf('Z_ShutDown: Shut down zone memory allocation daemon.'#13#10);
  Z_ShutDown;
  printf('W_ShutDown: Shut down WAD file system.'#13#10);
  W_ShutDown;
  printf('V_ShutDown: Shut down screens.'#13#10);
  V_ShutDown;
  printf('MT_ShutDown: Shut down multithreading utilities.'#13#10);
  MT_ShutDown;
  printf('AM_ShutDown: Shut down automap.'#13#10);
  AM_ShutDown;
  printf('MObj_ShutDown: Shut down mobjs.'#13#10);
  MObj_ShutDown;
  printf('SV_ShutDownSerializers: Shut down serializers.'#13#10);
  SV_ShutDownSerializers;

  gamedirectories.Free;

  if wadfiles <> nil then
  begin
    for i := 0 to wadfiles.Count - 1 do
      if wadfiles.Objects[i] <> nil then
        wadfiles.Objects[i].Free;

    wadfiles.Free;
  end;

end;

end.

