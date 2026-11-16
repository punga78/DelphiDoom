//------------------------------------------------------------------------------
//
//  DelphiHeretic is a source port of the game Heretic and it is
//  based on original Linux Doom as published by "id Software", on
//  Heretic source as published by "Raven" software and DelphiDoom
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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit g_game;

interface

uses
  DelphiDoom.Engine.Level.Intf,
  d_delphi,
  doomdef,
  m_fixed,
  d_event,
  DelphiDoom.Input.Intf,
  DelphiDoom.Engine.Net.Intf,
  DelphiDoom.Engine.Screenshot.Intf,
  DelphiDoom.Engine.Platform.Intf,
  DelphiDoom.Engine.Endoom.Intf,
  d_player,
  d_ticcmd,
  p_umapinfo;

//==============================================================================
// G_DeathMatchSpawnPlayer
//
// GAME
//
//==============================================================================
procedure G_DeathMatchSpawnPlayer(playernum: integer);

//==============================================================================
//
// G_InitNew
//
//==============================================================================
procedure G_InitNew(skill: skill_t; episode: integer; map: integer);

//==============================================================================
// G_DeferedInitNew
//
// Can be called by the startup code or M_Responder.
// A normal game starts at map 1,
// but a warp test can start elsewhere
//
//==============================================================================
procedure G_DeferedInitNew(skill: skill_t; episode: integer; map: integer);

//==============================================================================
//
// G_CmdNewGame
//
//==============================================================================
procedure G_CmdNewGame(const parm1, parm2: string);

//==============================================================================
//
// G_DeferedPlayDemo
//
//==============================================================================
function G_DeferedPlayDemo(const name: string): boolean;

//==============================================================================
//
// G_CmdPlayDemo
//
//==============================================================================
procedure G_CmdPlayDemo(const name: string);

{ Can be called by the startup code or M_Responder, }
{ calls P_SetupLevel or W_EnterWorld. }

//==============================================================================
//
// G_LoadGame
//
//==============================================================================
procedure G_LoadGame(const name: string);

//==============================================================================
//
// G_DoLoadGame
//
//==============================================================================
procedure G_DoLoadGame;

{ Called by M_Responder. }

//==============================================================================
//
// G_SaveGame
//
//==============================================================================
procedure G_SaveGame(slot: integer; const description: string);

//==============================================================================
//
// G_SaveGameNow
//
//==============================================================================
procedure G_SaveGameNow(slot: integer; const description: string);

//==============================================================================
//
// G_CmdSaveGame
//
//==============================================================================
procedure G_CmdSaveGame(const sname: string; const description: string);

{ Only called by startup code. }

//==============================================================================
//
// G_RecordDemo
//
//==============================================================================
procedure G_RecordDemo(const name: string);

//==============================================================================
//
// G_BeginRecording
//
//==============================================================================
procedure G_BeginRecording;

//==============================================================================
//
// G_TimeDemo
//
//==============================================================================
procedure G_TimeDemo(const name: string);

//==============================================================================
//
// G_CheckDemoStatus
//
//==============================================================================
function G_CheckDemoStatus: boolean;

//==============================================================================
//
// G_ExitLevel
//
//==============================================================================
procedure G_ExitLevel;

//==============================================================================
//
// G_SecretExitLevel
//
//==============================================================================
procedure G_SecretExitLevel;

//==============================================================================
//
// G_WorldDone
//
//==============================================================================
procedure G_WorldDone;

//==============================================================================
//
// G_Ticker
//
//==============================================================================
procedure G_Ticker;

//==============================================================================
//
// G_Responder
//
//==============================================================================
function G_Responder(ev: Pevent_t): boolean;

//==============================================================================
//
// G_ScreenShot
//
//==============================================================================
procedure G_ScreenShot;

var
  sendpause: boolean;        // send a pause event next tic

  paused: boolean;

//
// controls (have defaults)
//
  key_right: integer;
  key_left: integer;

  key_up: integer;
  key_down: integer;

// JVAL Look Up and Down
  key_lookup: integer;
  key_lookdown: integer;
  key_lookcenter: integer;
// Fly move
  key_flyup: integer;
  key_flydown: integer;
  key_flycenter: integer;
// JVAL Look Left and Right
  key_lookright: integer;
  key_lookleft: integer;
  key_lookforward: integer;

  key_strafeleft: integer;
  key_straferight: integer;
  key_fire: integer;
  key_use: integer;
  key_strafe: integer;
  key_speed: integer;
// JVAL Jump
  key_jump: integer;
// JVAL: 20211101 - Crouch
  key_crouch: integer;

// JVAL 20191207 Key bindings for weapon change
  key_weapon0: integer = Ord('1');
  key_weapon1: integer = Ord('2');
  key_weapon2: integer = Ord('3');
  key_weapon3: integer = Ord('4');
  key_weapon4: integer = Ord('5');
  key_weapon5: integer = Ord('6');
  key_weapon6: integer = Ord('7');
  key_weapon7: integer = Ord('8');

  KEY_WEAPONS: array[0..Ord(NUMWEAPONS) - 1] of PInteger;

  key_invleft,
  key_invright,
  key_useartifact: integer;

  usemouse: boolean;
  invertmouseturn: boolean;
  invertmouselook: boolean;
  mousebfire: integer;
  mousebstrafe: integer;
  mousebforward: integer;

  usejoystick: boolean;
  joybfire: integer;
  joybstrafe: integer;
  joybuse: integer;
  joybspeed: integer;
  joybjump: integer;
  joybcrouch: integer;  // JVAL: 20211101 - Crouch
  joyblleft: integer;
  joyblright: integer;

  demoplayback: boolean;
  preparingdemoplayback: boolean = false;

  gameepisode: integer;
  gamemap: integer;
  gamemapinfo: Pmapentry_t;

  deathmatch: integer; // only if started as net death
  netgame: boolean; // only true if packets are broadcast
  playeringame: array[0..MAXPLAYERS - 1] of boolean;

  consoleplayer: integer; // player taking events and displaying
  displayplayer: integer; // view being displayed
  gametic: integer;


  wminfo: wbstartstruct_t; // parms for world map / intermission

  gameskill: skill_t;


  precache: boolean; // if true, load all graphics at start

  respawnmonsters: boolean;

  viewactive: boolean;

  singledemo: boolean; // quit after playing a demo from cmdline

  demorecording: boolean = false;

  gameaction: gameaction_t;

  usergame: boolean; // ok to save / end game

//==============================================================================
//
// G_SetKeyboardMode
//
//==============================================================================
procedure G_SetKeyboardMode(const mode: integer);

//==============================================================================
//
// G_PlayerReborn
//
//==============================================================================
procedure G_PlayerReborn(player: integer);

//==============================================================================
//
// G_BuildTiccmd
//
//==============================================================================
procedure G_BuildTiccmd(cmd: Pticcmd_t);

var
  statcopy: pointer = nil;        // for statistics driver

var
  forwardmove: array[0..1] of shortint;
  sidemove: array[0..1] of shortint;
  angleturn: array[0..2] of smallint;

//==============================================================================
//
// G_NeedsCompatibilityMode
//
//==============================================================================
function G_NeedsCompatibilityMode: boolean;

//==============================================================================
//
// G_PlayingEngineVersion
//
//==============================================================================
function G_PlayingEngineVersion: byte;

//==============================================================================
//
// G_Quit
//
//==============================================================================
procedure G_Quit;

//==============================================================================
//
// G_LookupMapinfo
//
//==============================================================================
function G_LookupMapinfo(const episode, map: integer): Pmapentry_t;

//==============================================================================
//
// G_ValidateMapName
//
//==============================================================================
function G_ValidateMapName(const amap: string; const pepi, pmapnum: PInteger): boolean;

var
  compatibilitymode: boolean = false;
  oldcompatibilitymode: boolean = false;

type
//
// LOAD GAME MENU
//
  load_e = (
    load1,
    load2,
    load3,
    load4,
    load5,
    load6,
    load7,
    load8,
    load_end
  );

var
  autorunmode: integer = 2;
  keepcheatsinplayerreborn: boolean = false;
  allowplayerjumps: boolean = true;
  allowplayercrouch: boolean = true;

var
// HERETIC Par Times
  pars: array[1..5, 1..9] of integer;

const
  SAVEGAMESIZE = $1000000; // Originally $2C000
  SAVESTRINGSIZE = 24;
  SAVEVERSIONSIZE = 16;

const
  NUMKEYS = 256;

var
  gamekeydown: array[0..NUMKEYS - 1] of boolean;
  mousebuttons: PBooleanArray;
  joybuttons: PBooleanArray;

var
  secretexit: boolean;
  wandstart: boolean;

//==============================================================================
//
// G_ConfigureInput
//
// The poller of the input, given by the composition root: the caps lock is the speed
// with autorunmode = 2. Without it G_BuildTiccmd stops with I_Error.
//
//==============================================================================
procedure G_ConfigureInput(const APoller: IInputPoller);

//==============================================================================
//
// G_ConfigureEndoom
//
// The end screen, given by the composition root: G_Quit starts it and G_Responder gives
// it the keys. Without it they stop with I_Error.
//
//==============================================================================
procedure G_ConfigureEndoom(const AScreen: IEngineEndoomScreen);

//==============================================================================
//
// G_ConfigureNetGame
// The network, given by the composition root
//
//==============================================================================
procedure G_ConfigureNetGame(const ANetGame: IEngineNetGame);

//==============================================================================
//
// G_ConfigureScreenshot
// The screenshots, given by the composition root
//
//==============================================================================
procedure G_ConfigureScreenshot(const AScreenshot: IEngineScreenshot);

//==============================================================================
//
// G_ConfigureFiles
// The files, given by the composition root
//
//==============================================================================
procedure G_ConfigureFiles(const AFiles: IEngineFiles);

//==============================================================================
//
// G_ConfigureLevel
//
// The loading of the levels, given by the composition root: G_DoLoadLevel calls it.
// Without it the game stops with I_Error.
//
//==============================================================================
procedure G_ConfigureLevel(const ALoader: ILevelLoader);

implementation

uses
  DelphiDoom.Demo.Types,
  DelphiDoom.Demo.Profiles,
  DelphiDoom.Demo.HeaderCodec,
  DelphiDoom.Demo.CommandCodec,
  DelphiDoom.Input.EventScaling,
  DelphiDoom.Serializer.SaveGameName,
  DelphiDoom.MapInfo.LevelProgression,
  DelphiDoom.MapInfo.MapName,
  DelphiDoom.MapInfo.NewGameLimits,
  DelphiDoom.MapInfo.SkillSpeed,
  DelphiDoom.Input.KeyboardLayout,
  c_cmds,
  d_check,
  z_zone,
  doomstat,
  doomdata,
  am_map,
  d_net,
  d_net_h,
  d_main,
  f_finale,
  info_h,
  info,
  i_system,
  m_argv,
  m_misc,
  m_menu,
  m_rnd,
  p_setup,
  p_saveg,
  DelphiDoom.Serializer.SaveGameHeader,
  DelphiDoom.Serializer.SaveGameVersions,
  p_tick,
  p_local,
  p_mobj_h,
  p_mobj,
  p_inter,
  DelphiDoom.Engine.World.InterRules,
  p_map,
  p_acs,
  p_levelinfo,
  ps_main,
  in_stuff,
  hu_stuff,
  sb_bar,
  w_wad,
  s_sound,
// Data.
  h_strings,
  sounddata,
// SKY handling - still the wrong place.
  r_data,
  r_sky,
  r_defs,
  r_main,
  r_draw,
  r_intrpl,
  tables;

var
  // given by the composition root
  g_netgame_ref: IEngineNetGame = nil;
  g_screenshot_ref: IEngineScreenshot = nil;
  g_files_ref: IEngineFiles = nil;

//==============================================================================
//
// G_ConfigureNetGame
//
//==============================================================================
procedure G_ConfigureNetGame(const ANetGame: IEngineNetGame);
begin
  g_netgame_ref := ANetGame;
end;

//==============================================================================
//
// G_NetGame
//
//==============================================================================
function G_NetGame: IEngineNetGame;
begin
  if g_netgame_ref = nil then
    I_Error('G_ConfigureNetGame() was not called: the network is missing');
  result := g_netgame_ref;
end;

//==============================================================================
//
// G_ConfigureScreenshot
//
//==============================================================================
procedure G_ConfigureScreenshot(const AScreenshot: IEngineScreenshot);
begin
  g_screenshot_ref := AScreenshot;
end;

//==============================================================================
//
// G_Screenshots
//
//==============================================================================
function G_Screenshots: IEngineScreenshot;
begin
  if g_screenshot_ref = nil then
    I_Error('G_ConfigureScreenshot() was not called: the screenshots are missing');
  result := g_screenshot_ref;
end;

//==============================================================================
//
// G_ConfigureFiles
//
//==============================================================================
procedure G_ConfigureFiles(const AFiles: IEngineFiles);
begin
  g_files_ref := AFiles;
end;

//==============================================================================
//
// G_Files
//
//==============================================================================
function G_Files: IEngineFiles;
begin
  if g_files_ref = nil then
    I_Error('G_ConfigureFiles() was not called: the files are missing');
  result := g_files_ref;
end;

var
  // given by the composition root (G_ConfigureInput)
  game_input: IInputPoller = nil;

//==============================================================================
//
// G_ConfigureInput
//
//==============================================================================
procedure G_ConfigureInput(const APoller: IInputPoller);
begin
  game_input := APoller;
end;

//==============================================================================
//
// G_InputPoller
//
//==============================================================================
function G_InputPoller: IInputPoller;
begin
  if game_input = nil then
    I_Error('G_ConfigureInput() was not called: the input is missing');
  result := game_input;
end;

var
  // given by the composition root (G_ConfigureEndoom)
  game_endoom: IEngineEndoomScreen = nil;

//==============================================================================
//
// G_ConfigureEndoom
//
//==============================================================================
procedure G_ConfigureEndoom(const AScreen: IEngineEndoomScreen);
begin
  game_endoom := AScreen;
end;

//==============================================================================
//
// G_EndoomScreen
//
//==============================================================================
function G_EndoomScreen: IEngineEndoomScreen;
begin
  if game_endoom = nil then
    I_Error('G_ConfigureEndoom() was not called: the end screen is missing');
  result := game_endoom;
end;

//==============================================================================
//
// G_ReadDemoTiccmd
//
//==============================================================================
procedure G_ReadDemoTiccmd(cmd: Pticcmd_t); forward;

//==============================================================================
//
// G_WriteDemoTiccmd
//
//==============================================================================
procedure G_WriteDemoTiccmd(cmd: Pticcmd_t); forward;

//==============================================================================
//
// G_DoReborn
//
//==============================================================================
procedure G_DoReborn(playernum: integer); forward;

//==============================================================================
//
// G_DoLoadLevel
//
//==============================================================================
procedure G_DoLoadLevel; forward;

//==============================================================================
//
// G_DoNewGame
//
//==============================================================================
procedure G_DoNewGame; forward;

//==============================================================================
//
// G_DoPlayDemo
//
//==============================================================================
procedure G_DoPlayDemo; forward;

//==============================================================================
//
// G_DoCompleted
//
//==============================================================================
procedure G_DoCompleted; forward;

//==============================================================================
//
// G_DoWorldDone
//
//==============================================================================
procedure G_DoWorldDone; forward;

//==============================================================================
//
// G_DoSaveGame
//
//==============================================================================
procedure G_DoSaveGame; forward;

//==============================================================================
//
// G_FinishedDemoPlayback
//
//==============================================================================
procedure G_FinishedDemoPlayback;
begin
  demoplayback := false;
  // Restore old compatibility mode
  compatibilitymode := oldcompatibilitymode;
end;

var
  sendsave: boolean;         // send a save event next tic
  sendcmdsave: boolean;      // send a save event next tic (console)

  timingdemo: boolean;       // if true, exit with report on completion
  starttime: integer;        // for comparative timing purposes

  levelstarttic: integer;    // gametic at level start

  demoname: string;
  netdemo: boolean;
  demobuffer: PByteArray;
  demo_p: PByteArray;
  demoend: PByte;


  savebuffer: PByteArray;

const
  TURBOTHRESHOLD = $32;

//==============================================================================
//
// MAXPLMOVE
//
//==============================================================================
function MAXPLMOVE: fixed_t;
begin
  result := forwardmove[1];
end;

const
  SLOWTURNTICS = 6;

var
  turnheld: integer;

  lookheld: integer;  // JVAL Look UP and DOWN
  lookheld2: integer; // JVAL Look RIGHT and LEFT

  mousearray: array[0..2] of boolean;

// mouse values are used once
  mousex: integer = 0;
  mousey: integer = 0;

  dclicktime: integer;
  dclickstate: boolean;
  dclicks: integer;
  dclicktime2: integer;
  dclickstate2: boolean;
  dclicks2: integer;

// joystick values are repeated
  joyxmove: integer;
  joyymove: integer;
  joyarray: array[0..NUMJOYBUTTONS - 1] of boolean;

  savegameslot: integer;
  savedescription: string;

var
  usearti: boolean = true;

//==============================================================================
//
// G_BuildTiccmd
// Builds a ticcmd from all of the available inputs
// or reads it from the demo buffer.
// If recording a demo, write it out
//
//==============================================================================
procedure G_BuildTiccmd(cmd: Pticcmd_t);
var
  i: integer;
  strafe: boolean;
  bstrafe: boolean;
  speed: integer;
  tspeed: integer;
  lspeed: integer;  // JVAL Look up and down
  lspeed2: integer; // JVAL look left and right
  _forward: integer;
  side: integer;
  look: integer;    // JVAL Look up and down
  look16: integer;  // JVAL Smooth Look Up/Down
  look2: integer;   // JVAL look left and right
  flyheight: integer;
  base: Pticcmd_t;
  imousex: integer;
  imousey: integer;
  cmd_jump, cmd_crouch: byte;
begin
  base := I_BaseTiccmd;    // empty, or external driver

  memcpy(cmd, base, SizeOf(cmd^));

  cmd.consistency := G_NetGame.ExpectedConsistency;

  strafe := gamekeydown[key_strafe] or
            (usemouse and mousebuttons[mousebstrafe]) or
            (usejoystick and joybuttons[joybstrafe]);
  speed := intval(gamekeydown[key_speed] or joybuttons[joybspeed]);
  if autorunmode = 0 then
  else if autorunmode = 1 then
    speed := 1 - speed
  else if G_InputPoller.IsCapsLockOn then
    speed := 1 - speed;

  _forward := 0;
  side := 0;
  look := 0;
  look16 := 0; // JVAL Smooth Look Up/Down
  look2 := 0;
  flyheight := 0;

  // use two stage accelerative turning
  // on the keyboard and joystick
  if (joyxmove <> 0) or
     (gamekeydown[key_right]) or
     (gamekeydown[key_left]) then
    turnheld := turnheld + ticdup
  else
    turnheld := 0;

  if turnheld < SLOWTURNTICS then
    tspeed := 2             // slow turn
  else
    tspeed := speed;

  if gamekeydown[key_lookdown] or gamekeydown[key_lookup] then
    lookheld := lookheld + ticdup
  else
    lookheld := 0;

  if lookheld < SLOWTURNTICS then
    lspeed := 1
  else
    lspeed := 2;

  if gamekeydown[key_lookleft] or gamekeydown[key_lookright] or
    (usejoystick and (joybuttons[joyblleft] or joybuttons[joyblright])) then
    lookheld2 := lookheld2 + ticdup
  else
    lookheld2 := 0;

  if lookheld2 < SLOWTURNTICS then
    lspeed2 := 1
  else
    lspeed2 := 2;

  // let movement keys cancel each other out
  if strafe then
  begin
    if gamekeydown[key_right] then
      side := side + sidemove[speed];
    if gamekeydown[key_left] then
      side := side - sidemove[speed];
    if joyxmove > 0 then
      side := side + sidemove[speed];
    if joyxmove < 0 then
      side := side - sidemove[speed];
  end
  else
  begin
    if gamekeydown[key_right] then
      cmd.angleturn := cmd.angleturn - angleturn[tspeed];
    if gamekeydown[key_left] then
      cmd.angleturn := cmd.angleturn + angleturn[tspeed];
    if joyxmove > 0 then
      cmd.angleturn := cmd.angleturn - angleturn[tspeed];
    if joyxmove < 0 then
      cmd.angleturn := cmd.angleturn + angleturn[tspeed];
  end;

  if gamekeydown[key_up] then
    _forward := _forward + forwardmove[speed];

  if gamekeydown[key_down] then
    _forward := _forward - forwardmove[speed];

  // JVAL Look up/down/center keys
  if zaxisshift then
  begin
    if gamekeydown[key_lookup] then
      look := lspeed;

    if gamekeydown[key_lookdown] then
      look := -lspeed;

    if gamekeydown[key_lookcenter] then
      look := TOCENTER;

    look16 := 256 * look; // JVAL Smooth Look Up/Down
  end;

  // JVAL Look right/left/forward keys
  if gamekeydown[key_lookleft] or (usejoystick and joybuttons[joyblleft]) then
    look2 := lspeed2;

  if gamekeydown[key_lookright] or (usejoystick and joybuttons[joyblright]) then
    look2 := -lspeed2;

  if gamekeydown[key_lookforward] then
    look2 := TOFORWARD;

  if joyymove < 0 then
    _forward := _forward + forwardmove[speed];

  if joyymove > 0 then
    _forward := _forward - forwardmove[speed];

  if gamekeydown[key_straferight] then
    side := side + sidemove[speed];

  if gamekeydown[key_strafeleft] then
    side := side - sidemove[speed];

  // buttons
  cmd.chatchar := Ord(HU_dequeueChatChar);

  if gamekeydown[key_fire] or
     (usemouse and mousebuttons[mousebfire]) or
     (usejoystick and joybuttons[joybfire]) then
    cmd.buttons := cmd.buttons or BT_ATTACK;

  if G_PlayingEngineVersion >= VERSION207 then
    if players[consoleplayer].nextfire > leveltime then
      cmd.buttons := cmd.buttons and not BT_ATTACK;

  if gamekeydown[key_use] or (usejoystick and joybuttons[joybuse]) then
  begin
    cmd.buttons := cmd.buttons or BT_USE;
  // clear double clicks if hit use button
    dclicks := 0;
  end;

  // chainsaw overrides
  for i := 0 to Ord(NUMWEAPONS) - 2 do
    if gamekeydown[KEY_WEAPONS[i]^] then
    begin
      cmd.buttons := cmd.buttons or BT_CHANGE;
      cmd.buttons := cmd.buttons or _SHL(i, BT_WEAPONSHIFT);
      break;
    end;

  // mouse
  if (usemouse and mousebuttons[mousebforward]) then
    _forward := _forward + forwardmove[speed];

  // forward double click
  if usemouse and (mousebuttons[mousebforward] <> dclickstate) and (dclicktime > 1) then
  begin
    dclickstate := mousebuttons[mousebforward];
    if dclickstate then
      inc(dclicks);
    if dclicks = 2 then
    begin
      cmd.buttons := cmd.buttons or BT_USE;
      dclicks := 0;
    end
    else
      dclicktime := 0;
  end
  else
  begin
    dclicktime := dclicktime + ticdup;
    if dclicktime > 20 then
    begin
      dclicks := 0;
      dclickstate := false;
    end
  end;

  // strafe double click
  bstrafe := (usemouse and mousebuttons[mousebstrafe]) or
             (usejoystick and joybuttons[joybstrafe]);
  if (bstrafe <> dclickstate2) and (dclicktime2 > 1) then
  begin
    dclickstate2 := bstrafe;
    if bstrafe then
      inc(dclicks2);
    if dclicks2 = 2 then
    begin
      cmd.buttons := cmd.buttons or BT_USE;
      dclicks2 := 0;
    end
    else
      dclicktime2 := 0;
  end
  else
  begin
    dclicktime2 := dclicktime2 + ticdup;
    if dclicktime2 > 20 then
    begin
      dclicks2 := 0;
      dclickstate2 := false;
    end;
  end;

  // JVAL: invert mouse
  if invertmouseturn then
    imousex := -mousex
  else
    imousex := mousex;

  if strafe then
    side := side - imousex * 2
  else
    cmd.angleturn := cmd.angleturn + imousex * $8;

  if invertmouselook then
    imousey := -mousey
  else
    imousey := mousey;

  if usemouse then
  begin
    look := look + imousey div 16;
    if imousey < 0 then
    begin
      if look < -4 then
        look := -4;
    end
    else if imousey > 0 then
    begin
      if look > 4 then
        look := 4;
    end;

    // JVAL Smooth Look Up/Down
    if G_PlayingEngineVersion < VERSION203 then
      look16 := 256 * look
    else
    begin
      look16 := look16 + imousey * 16;
      if imousey < 0 then
      begin
        if look16 < -4 * 256 then
          look16 := -4 * 256;
      end
      else if imousey > 0 then
      begin
        if look16 > 4 * 256 then
          look16 := 4 * 256;
      end;
    end;
  end;

  // JVAL: For smooth mouse movement
  mousex := mousex div 4;
  mousey := mousey div 4;

  if _forward > MAXPLMOVE then
    _forward := MAXPLMOVE
  else if _forward < -MAXPLMOVE then
    _forward := -MAXPLMOVE;

  if side > MAXPLMOVE then
    side := MAXPLMOVE
  else if side < -MAXPLMOVE then
    side := -MAXPLMOVE;

  cmd.forwardmove := cmd.forwardmove + _forward;
  cmd.sidemove := cmd.sidemove + side;

  if players[consoleplayer].playerstate = PST_LIVE then
  begin
    if zaxisshift then
    begin
      if look < 0 then
        look := look + 16;
      cmd.lookfly := look;

      // JVAL Smooth Look Up/Down
      if look16 < 0 then
        look16 := look16 + 16 * 256;
      cmd.lookupdown16 := look16;
    end;
    if look2 < 0 then
      look2 := look2 + 16;
    cmd.lookleftright:= look2;
    // JVAL
    // allowplayerjumps variable controls if we accept input for jumping
    if allowplayerjumps and (gamekeydown[key_jump] or (usejoystick and joybuttons[joybjump])) then
    begin
      if players[consoleplayer].oldjump <> 0 then
        cmd_jump := 1
      else
        cmd_jump := 2
      end
    else
      cmd_jump := 0;
    players[consoleplayer].oldjump := cmd_jump;
    // JVAL: 20211101 - Crouch
    // allowplayercrouch variable controls if we accept input for crouching
    if cmd_jump = 0 then
    begin
      if allowplayercrouch and (gamekeydown[key_crouch] or (usejoystick and joybuttons[joybcrouch])) then
      begin
        if players[consoleplayer].oldcrouch <> 0 then
          cmd_crouch := 2
        else
          cmd_crouch := 1
        end
      else
        cmd_crouch := 0;
    end
    else
      cmd_crouch := 0;
    players[consoleplayer].oldcrouch := cmd_crouch;

    cmd.jump_crouch :=
      ((cmd_jump shl CMD_JUMP_SHIFT) and CMD_JUMP_MASK) +
      ((cmd_crouch shl CMD_CROUCH_SHIFT) and CMD_CROUCH_MASK);
  end;

  // special buttons
  if sendpause then
  begin
    sendpause := false;
    cmd.buttons := BT_SPECIAL or BTS_PAUSE;
  end;

  // Fly up/down/drop keys
  if gamekeydown[key_flyup] then
    flyheight := 5; // note that the actual flyheight will be twice this

  if gamekeydown[key_flydown] then
    flyheight := -5;

  if gamekeydown[key_flycenter] then
    flyheight := TOCENTER;

  if flyheight < 0 then
    flyheight := flyheight + 16;

  cmd.lookfly := cmd.lookfly or _SHL(flyheight, 4);

  // Use artifact key
  if gamekeydown[key_useartifact] then
  begin
    if gamekeydown[key_speed] and not noartiskip then
    begin
      if players[consoleplayer].inventory[inv_ptr]._type <> Ord(arti_none) then
      begin
        gamekeydown[key_useartifact] := false;
        cmd.arti := $ff; // skip artifact code
      end
    end
    else
    begin
      if inventory then
      begin
        players[consoleplayer].readyArtifact :=
          artitype_t(players[consoleplayer].inventory[inv_ptr]._type);
        inventory := false;
        cmd.arti := 0;
        usearti := false;
      end
      else if usearti then
      begin
        cmd.arti := players[consoleplayer].inventory[inv_ptr]._type;
        usearti := false;
      end;
    end;
  end;

  if gamekeydown[127] and (cmd.arti = 0) and (players[consoleplayer].powers[Ord(pw_weaponlevel2)] = 0) then
  begin
    gamekeydown[127] := false;
    cmd.arti := Ord(arti_tomeofpower);
  end;

  if sendsave then
  begin
    sendsave := false;
    cmd.buttons := BT_SPECIAL or BTS_SAVEGAME or _SHL(savegameslot, BTS_SAVESHIFT);
  end;

  if sendcmdsave then
  begin
    sendcmdsave := false;
    cmd.commands := CM_SAVEGAME;
  end;

end;

//
// G_DoLoadLevel
//
const
  skyLumpNames: array[0..4] of string = (
    'SKY1', 'SKY2', 'SKY3', 'SKY1', 'SKY3'
  );

var
  // given by the composition root (G_ConfigureLevel)
  game_levelloader: ILevelLoader = nil;

//==============================================================================
//
// G_ConfigureLevel
//
//==============================================================================
procedure G_ConfigureLevel(const ALoader: ILevelLoader);
begin
  game_levelloader := ALoader;
end;

//==============================================================================
//
// G_LevelLoader
//
//==============================================================================
function G_LevelLoader: ILevelLoader;
begin
  if game_levelloader = nil then
    I_Error('G_ConfigureLevel() was not called: the loading of the levels is missing');
  result := game_levelloader;
end;

//==============================================================================
//
// G_DoLoadLevel
//
//==============================================================================
procedure G_DoLoadLevel;
var
  i: integer;
begin
  // Set the sky map.
  // First thing, we have a dummy sky texture name,
  //  a flat. The data is in the WAD only because
  //  we look for an actual index, instead of simply
  //  setting one.
  skyflatnum := R_FlatNumForName(SKYFLATNAME);

  if (gamemapinfo <> nil) and (gamemapinfo.skytexture <> '') then
  begin
    skytexture := R_TextureNumForName(gamemapinfo.skytexture);
    if skytexture < 0 then
      skytexture := R_TextureNumForName(skyLumpNames[0]);
  end
  else
  begin
    // Heretic determines the sky texture to be used
    // depending on the current episode.
    // Set the sky map
    if gameepisode > 5 then
      skytexture := R_TextureNumForName(skyLumpNames[0]) // ???
    else
    begin
      skytexture := R_CheckTextureNumForName(skyLumpNames[gameepisode - 1]);
      if skytexture < 0 then
        skytexture := R_TextureNumForName(skyLumpNames[0]);
    end;
  end;
  skytexture1 := skytexture;
  skytexture2 := -1;
  if (gamemapinfo <> nil) and (gamemapinfo.skytexture2 <> '') then
    skytexture2 := R_TextureNumForName(gamemapinfo.skytexture2);
  if skytexture2 < 0 then
    skytexture2 := skytexture;

  levelstarttic := gametic;        // for time calculation

  if wipegamestate = Ord(GS_LEVEL) then
    wipegamestate := -1;  // force a wipe

  gamestate := GS_LEVEL;

  for i := 0 to MAXPLAYERS - 1 do
  begin
    if playeringame[i] and (players[i].playerstate = PST_DEAD) then
      players[i].playerstate := PST_REBORN;
    ZeroMemory(@players[i].frags, SizeOf(players[i].frags));
  end;

  // automatic wand start when advancing from one level to the next
  if wandstart then
  begin
    if not demorecording and not demoplayback and not netgame then
      G_PlayerReborn(0)
    else if (demoplayback or netdemo) and not singledemo then
    begin
      // no-op - silently ignore pistolstart when playing demo from the
      // demo reel
    end
    else
    begin
      if demo_p = nil then
        demorecording := false;
      I_Error('The -wandstart option is not supported for demos and'#13#10' network play.');
    end;
  end;

  PS_NewMap;
  G_LevelLoader.SetupLevel(gameepisode, gamemap, 0, gameskill);

  // JVAL: Prevent erroneous demos
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
      if players[i].mo = nil then
      begin
        I_Warning('G_DoLoadLevel(): Null player actor, is player start missing?'#13#10);
        gamestate := GS_DEMOSCREEN;
        D_StartTitle;
        exit;
      end;

  displayplayer := consoleplayer;    // view the guy you are playing
  starttime := I_GetTime;
  gameaction := ga_nothing;
  Z_CheckHeap;

  // clear cmd building stuff
  ZeroMemory(@gamekeydown, SizeOf(gamekeydown));
  joyxmove := 0;
  joyymove := 0;
  mousex := 0;
  mousey := 0;
  sendpause := false;
  sendsave := false;
  sendcmdsave := false;
  paused := false;
  ZeroMemory(mousebuttons, SizeOf(mousebuttons));
  ZeroMemory(joybuttons, SizeOf(joybuttons));
end;

var
  inventoryTics: integer = 0;

//==============================================================================
//
// G_Responder
// Get info needed to make ticcmd_ts for the players.
//
//==============================================================================
function G_Responder(ev: Pevent_t): boolean;
var
  i: integer;
  plr: Pplayer_t;
begin
  if gamestate = GS_ENDOOM then
  begin
    result := G_EndoomScreen.Respond(ev);
    exit;
  end;

  plr := @players[consoleplayer];
//  if (ev._type = ev_keyup) and (ev.data1 = key_useartifact) then
  if (ev._type = ev_keydown) and (ev.data1 = key_useartifact) then
  begin // flag to denote that it's okay to use an artifact
    if not inventory then
      plr.readyArtifact := artitype_t(plr.inventory[inv_ptr]._type);
    usearti := true;
    gamekeydown[key_useartifact] := true;
    result := true;
    exit;
  end;

  // allow spy mode changes even during the demo
  if (gamestate = GS_LEVEL) and (ev._type = ev_keydown) and
     (ev.data1 = KEY_F12) and (singledemo or (deathmatch = 0)) then
  begin
  // spy mode
    repeat
      inc(displayplayer);
      if displayplayer = MAXPLAYERS then
        displayplayer := 0;
    until not ((not playeringame[displayplayer]) and (displayplayer <> consoleplayer));
    result := true;
    exit;
  end;

  // any other key pops up menu if in demos
  if (gameaction = ga_nothing) and not singledemo and
     (demoplayback or (gamestate = GS_DEMOSCREEN)) then
  begin
    if (ev._type = ev_keydown) or
       ((ev._type = ev_mouse) and (ev.data1 <> 0)) or
       ((ev._type = ev_joystick) and (ev.data1 <> 0)) then
    begin
      M_StartControlPanel;
      result := true;
      exit;
    end;
    result := false;
    exit;
  end;

  if gamestate = GS_LEVEL then
  begin
    if HU_Responder(ev) then
    begin
      result := true; // chat ate the event
      exit;
    end;
    if SB_Responder(ev) then
    begin
      result := true; // status window ate it
      exit;
    end;
    if AM_Responder(ev) then
    begin
      result := true; // automap ate it
      exit;
    end;
  end;

  if gamestate = GS_FINALE then
  begin
    if F_Responder(ev) then
    begin
      result := true; // finale ate the event
      exit;
    end;
  end;

  // For smooth mouse movement
  mousex := mousex div 2;
  mousey := mousey div 2;

  case ev._type of
    ev_keydown:
      begin
        if ev.data1 = key_invleft then
        begin
          inventoryTics := 5 * TICRATE;
          if inventory then
          begin
            dec(inv_ptr);
            if inv_ptr < 0 then
              inv_ptr := 0
            else
            begin
              dec(curpos);
              if curpos < 0 then
                curpos := 0;
            end;
            result := true;
            exit;
          end
          else
            inventory := true;
        end;

        if ev.data1 = key_invright then
        begin
          inventoryTics := 5 * TICRATE;
          if inventory then
          begin
            inc(inv_ptr);
            if inv_ptr >= plr.inventorySlotNum then
            begin
              dec(inv_ptr);
              if inv_ptr < 0 then
                inv_ptr := 0;
            end
            else
            begin
              inc(curpos);
              if curpos > 6 then
                curpos := 6;
            end;
            result := true;
            exit;
          end
          else
            inventory := true;
        end;

        if ev.data1 = KEY_PAUSE then
        begin
          sendpause := true;
          result := true;
          exit;
        end;

        if ev.data1 < NUMKEYS then
          gamekeydown[ev.data1] := true;

        result := true; // eat key down events
        exit;
      end;

    ev_keyup:
      begin
        if ev.data1 < NUMKEYS then
          gamekeydown[ev.data1] := false;
        result := false; // always let key up events filter down
        exit;
      end;

    ev_mouse:
      begin
        if usemouse then
        begin
          mousebuttons[0] := ev.data1 and 1 <> 0;
          mousebuttons[1] := ev.data1 and 2 <> 0;
          mousebuttons[2] := ev.data1 and 4 <> 0;
          mousex := mousex + TInputEventScaling.MouseMotion(ev.data2, mouseSensitivity, mouseSensitivityX);
          mousey := mousey + TInputEventScaling.MouseMotion(ev.data3, mouseSensitivity, mouseSensitivityY);
        end
        else
        begin
          mousebuttons[0] := false;
          mousebuttons[1] := false;
          mousebuttons[2] := false;
          mousex := 0;
          mousey := 0;
        end;
        result := true;    // eat events
        exit;
      end;

    ev_joystick:
      begin
        if usejoystick then
        begin
          TInputEventScaling.JoystickButtons(ev.data1, @joybuttons[0], NUMJOYBUTTONS);
          joyxmove := ev.data2;
          joyymove := ev.data3;
        end
        else
        begin
          for i := 0 to NUMJOYBUTTONS - 1 do
            joybuttons[i] := false;
          joyxmove := 0;
          joyymove := 0;
        end;
        result := true;    // eat events
        exit;
      end;
  end;

  result := false;
end;

//==============================================================================
//
// G_Ticker
// Make ticcmd_ts for the players.
//
//==============================================================================
procedure G_Ticker;
var
  i: integer;
  buf: integer;
  cmd: Pticcmd_t;
  msg: string;
  pl: Pplayer_t;
begin
  // do player reborns if needed
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] and (players[i].playerstate = PST_REBORN) then
      G_DoReborn(i);

  // do things to change the game state
  while (gameaction <> ga_nothing) do
  begin
    case gameaction of
      ga_loadlevel:
        G_DoLoadLevel;
      ga_newgame:
        G_DoNewGame;
      ga_loadgame:
        G_DoLoadGame;
      ga_savegame:
        G_DoSaveGame;
      ga_playdemo:
        G_DoPlayDemo;
      ga_completed:
        G_DoCompleted;
      ga_victory:
        F_StartFinale;
      ga_worlddone:
        G_DoWorldDone;
      ga_screenshot:
        begin
          G_Screenshots.Take;
          gameaction := ga_nothing;
        end;
    end;
  end;

  // get commands, check consistancy,
  // and build new consistancy check
  buf := (gametic div ticdup) mod BACKUPTICS;

  for i := 0 to MAXPLAYERS - 1 do
  begin
    if playeringame[i] then
    begin
      pl := @players[i];
      cmd := @pl.cmd;

      G_NetGame.GetCommand(i, buf, cmd);

      if demoplayback then
        G_ReadDemoTiccmd(cmd);

      if demorecording then
        G_WriteDemoTiccmd(cmd);

      // check for turbo cheats
      if (cmd.forwardmove > TURBOTHRESHOLD) and
         ((gametic and 31) = 0) and
         (((_SHR(gametic, 5)) and 3) = i) then
      begin
        sprintf(msg, '%s is turbo!', [player_names[i]]);
        players[consoleplayer]._message := msg;
      end;

      if netgame and not netdemo and ((gametic mod ticdup) = 0) then
      begin
        if pl.mo <> nil then
          G_NetGame.VerifyConsistency(i, cmd.consistency, pl.mo.x)
        else
          G_NetGame.VerifyConsistency(i, cmd.consistency, M_GetMenuRandomIndex);
      end;
    end;
  end;

  // check for special buttons
  for i := 0 to MAXPLAYERS - 1 do
  begin
    if playeringame[i] then
    begin
      pl := @players[i];
      if pl.cmd.commands and CM_SAVEGAME <> 0 then
      begin
        savegameslot := Ord(load_end);
        gameaction := ga_savegame;
      end;
      if pl.cmd.buttons and BT_SPECIAL <> 0 then
      begin
        case pl.cmd.buttons and BT_SPECIALMASK of
          BTS_PAUSE:
            begin
              paused := not paused;
              if paused then
                S_PauseSound
              else
                S_ResumeSound;
            end;
          BTS_SAVEGAME:
            begin
              if savedescription = '' then
                savedescription := 'NET GAME';
              savegameslot :=
                _SHR((pl.cmd.buttons and BTS_SAVEMASK), BTS_SAVESHIFT);
              gameaction := ga_savegame;
            end;
        end;
      end;

      // turn inventory off after a certain amount of time
      if inventory then
      begin
        if inventoryTics = 0 then
        begin
          players[consoleplayer].readyArtifact :=  artitype_t(players[consoleplayer].inventory[inv_ptr]._type);
          inventory := false;
          pl.cmd.arti := 0;
        end;
        dec(inventoryTics);
      end;
    end;

  end;

  // do main actions
  case gamestate of
    GS_LEVEL:
      begin
        P_Ticker;
        SB_Ticker;
        AM_Ticker;
        HU_Ticker;
      end;
    GS_INTERMISSION:
      begin
        IN_Ticker;
      end;
    GS_FINALE:
      begin
        F_Ticker;
      end;
    GS_DEMOSCREEN:
      begin
        D_PageTicker;
      end;
  end;
end;

//
// PLAYER STRUCTURE FUNCTIONS
// also see P_SpawnPlayer in P_Things
//

{

//==============================================================================
//
// G_InitPlayer
// Called at the start.
// Called by the game initialization functions.
//
//==============================================================================
procedure G_InitPlayer(player: integer);
var
  p: Pplayer_t;
begin
  // set up the saved info
  p := @players[player];

  // clear everything else to defaults
  G_PlayerReborn(player);
end;
}

//==============================================================================
//
// G_PlayerFinishLevel
// Can when a player completes a level.
//
//==============================================================================
procedure G_PlayerFinishLevel(p: Pplayer_t);
begin
  ZeroMemory(@p.powers, SizeOf(p.powers));
  ZeroMemory(@p.keys, SizeOf(p.keys));
  if p.mo <> nil then
    p.mo.flags := p.mo.flags and not MF_SHADOW; // cancel invisibility
  p.lookdir := 0;       // JVAL cancel lookdir Up/Down
  p.lookdir16 := 0;     // JVAL Smooth Look Up/Down
  p.centering := false;
  p.lookdir2 := 0;      // JVAL cancel lookdir Left/Right
  p.forwarding := false;
  p.extralight := 0;    // cancel gun flashes
  p.fixedcolormap := 0; // cancel ir gogles
  p.damagecount := 0;   // no palette changes
  p.bonuscount := 0;
end;

//==============================================================================
//
// G_SetKeyboardMode
//
//==============================================================================
procedure G_SetKeyboardMode(const mode: integer);
var
  layout: TKeyboardLayout;
begin
  if TKeyboardLayouts.TryGet(klHeretic, mode, layout) then
  begin
    key_right := layout.Right;
    key_left := layout.Left;
    key_up := layout.Up;
    key_down := layout.Down;
    key_strafeleft := layout.StrafeLeft;
    key_straferight := layout.StrafeRight;
    key_jump := layout.Jump;
    key_crouch := layout.Crouch;
    key_fire := layout.Fire;
    key_use := layout.Use;
    key_strafe := layout.Strafe;
    key_speed := layout.Speed;
    key_lookup := layout.LookUp;
    key_lookdown := layout.LookDown;
    key_lookcenter := layout.LookCenter;
    key_lookright := layout.LookRight;
    key_lookleft := layout.LookLeft;
    key_lookforward := layout.LookForward;
    key_flyup := layout.FlyUp;
    key_flydown := layout.FlyDown;
    key_flycenter := layout.FlyCenter;
    key_invleft := layout.InventoryLeft;
    key_invright := layout.InventoryRight;
    key_weapon0 := layout.Weapons[0];
    key_weapon1 := layout.Weapons[1];
    key_weapon2 := layout.Weapons[2];
    key_weapon3 := layout.Weapons[3];
    key_weapon4 := layout.Weapons[4];
    key_weapon5 := layout.Weapons[5];
    key_weapon6 := layout.Weapons[6];
    key_weapon7 := layout.Weapons[7];
    AM_GOBIGKEY := layout.AutomapBig;
    AM_FOLLOWKEY := layout.AutomapFollow;
    AM_GRIDKEY := layout.AutomapGrid;
    AM_ROTATEKEY := layout.AutomapRotate;
    AM_TEXTUREDAUTOMAP := layout.AutomapTextured;
    AM_MARKKEY := layout.AutomapMark;
    AM_CLEARMARKKEY := layout.AutomapClearMarks;
  end;
end;

//==============================================================================
//
// G_PlayerReborn
// Called after a player dies
// almost everything is cleared and initialized
//
//==============================================================================
procedure G_PlayerReborn(player: integer);
var
  p: Pplayer_t;
  i: integer;
  frags: array[0..MAXPLAYERS - 1] of integer;
  killcount: integer;
  itemcount: integer;
  secretcount: integer;
  cheats: integer;
begin
  p := @players[player];
  memcpy(@frags, @p.frags, SizeOf(frags));
  killcount := p.killcount;
  itemcount := p.itemcount;
  secretcount := p.secretcount;

  // JVAL: added option to keep cheats
  if keepcheatsinplayerreborn and not preparingdemoplayback then
  begin
    cheats := p.cheats;
    ZeroMemory(p, SizeOf(player_t));
    p.cheats := cheats;
  end
  else
    ZeroMemory(p, SizeOf(player_t));

  memcpy(@p.frags, @frags, SizeOf(players[player].frags));
  p.killcount := killcount;
  p.itemcount := itemcount;
  p.secretcount := secretcount;

  p.usedown := true;
  p.attackdown := true;  // don't do anything immediately
  p.playerstate := PST_LIVE;
  p.health := mobjinfo[Ord(MT_PLAYER)].spawnhealth;

  // Initial weapons
  p.readyweapon := wp_goldwand;
  p.pendingweapon := wp_goldwand;
  p.weaponowned[Ord(wp_staff)] := 1;
  p.weaponowned[Ord(wp_goldwand)] := 1;
  p.ammo[Ord(am_goldwand)] := 50;

  for i := 0 to Ord(NUMAMMO) - 1 do
    p.maxammo[i] := maxammo[i];

  if player = consoleplayer then
  begin
    SB_state := -1; // refresh the status bar
    inv_ptr := 0; // reset the inventory pointer
    curpos := 0;
  end;

end;

//==============================================================================
//
// G_CheckSpot
// Returns false if the player cannot be respawned
// at the given mapthing_t spot
// because something is occupying it
//
//==============================================================================
function G_CheckSpot(playernum: integer; mthing: Pmapthing_t): boolean;
var
  x: fixed_t;
  y: fixed_t;
  z: fixed_t; // JVAL: 3d floor
  ss: Psubsector_t;
  an: angle_t; // JVAL was u long
  mo: Pmobj_t;
  i: integer;
begin
  x := mthing.x * FRACUNIT;
  y := mthing.y * FRACUNIT;

  if players[playernum].mo = nil then
  begin
    // first spawn of level, before corpses
    for i := 0 to playernum - 1 do
      if (players[i].mo.x = x) and
         (players[i].mo.y = y) then
      begin
        result := false;
        exit;
      end;
    result := true;
    exit;
  end;

  players[playernum].mo.flags2 := players[playernum].mo.flags2 and not MF2_PASSMOBJ;

  // JVAL: 3d floors
  ss := R_PointInSubsector(x, y);
  z := ss.sector.floorheight;
  if ss.sector.midsec >= 0 then
    if players[playernum].mo.spawnpoint.options and MTF_ONMIDSECTOR <> 0 then
      z := sectors[ss.sector.midsec].ceilingheight;

  if not P_CheckPosition(players[playernum].mo, x, y) then
  begin
    players[playernum].mo.flags2 := players[playernum].mo.flags2 or MF2_PASSMOBJ;
    result := false;
    exit;
  end;
  players[playernum].mo.flags2 := players[playernum].mo.flags2 or MF2_PASSMOBJ;

  // flush an old corpse if needed
  P_World.AddPlayerCorpse(players[playernum].mo);

  // spawn a teleport fog
  {$IFDEF FPC}
  an := _SHRW(ANG45 * (mthing.angle div 45), ANGLETOFINESHIFT);
  {$ELSE}
  an := (ANG45 * (mthing.angle div 45)) shr ANGLETOFINESHIFT;
  {$ENDIF}

  mo := P_SpawnMobj(x + 20 * finecosine[an], y + 20 * finesine[an],
          z + TELEFOGHEIGHT, Ord(MT_TFOG));

  if players[consoleplayer].viewz <> 1 then
    S_StartSound(mo, Ord(sfx_telept));  // don't start sound on first frame

  result := true;
end;

//==============================================================================
//
// G_DeathMatchSpawnPlayer
// Spawns a player at one of the random death match spots
// called at level load and each death
//
//==============================================================================
procedure G_DeathMatchSpawnPlayer(playernum: integer);
var
  i, j: integer;
  selections: integer;
begin
  selections := deathmatch_p; // JVAL - deathmatchstarts;
  if selections < 4 then
    I_Error('G_DeathMatchSpawnPlayer(): Only %d deathmatch spots, 4 required', [selections]);

  for j := 0 to 19 do
  begin
    i := P_Random mod selections;
    if G_CheckSpot(playernum, @deathmatchstarts[i]) then
    begin
      deathmatchstarts[i]._type := playernum + 1;
      P_SpawnPlayer(@deathmatchstarts[i], @udeathmatchstarts[i]);
      exit;
    end;
  end;

  // no good spot, so the player will probably get stuck
  P_SpawnPlayer(@playerstarts[playernum], @udeathmatchstarts[playernum]);
end;

//==============================================================================
//
// G_DoReborn
//
//==============================================================================
procedure G_DoReborn(playernum: integer);
var
  i: integer;
begin
  if not netgame then
    // reload the level from scratch
    gameaction := ga_loadlevel
  else
  begin
    // respawn at the start

    // first dissasociate the corpse
    players[playernum].mo.player := nil;

    // spawn at random spot if in death match
    if deathmatch <> 0 then
    begin
      G_DeathMatchSpawnPlayer(playernum);
      exit;
    end;

    if G_CheckSpot(playernum, @playerstarts[playernum]) then
    begin
      P_SpawnPlayer(@playerstarts[playernum], @udeathmatchstarts[playernum]);
      exit;
    end;

    // try to spawn at one of the other players spots
    for i := 0 to MAXPLAYERS - 1 do
    begin
      if G_CheckSpot (playernum, @playerstarts[i]) then
      begin
        playerstarts[i]._type := playernum + 1; // fake as other player
        P_SpawnPlayer(@playerstarts[i], @udeathmatchstarts[i]);
        playerstarts[i]._type := i + 1; // restore
        exit;
      end;
      // he's going to be inside something.  Too bad.
    end;
    P_SpawnPlayer(@playerstarts[playernum], @udeathmatchstarts[playernum]);
  end;
end;

//==============================================================================
//
// G_ScreenShot
//
//==============================================================================
procedure G_ScreenShot;
begin
  gameaction := ga_screenshot;
end;

//==============================================================================
// G_ExitLevel
//
// G_DoCompleted
//
//==============================================================================
procedure G_ExitLevel;
begin
  secretexit := false;
  gameaction := ga_completed;
end;

//==============================================================================
// G_SecretExitLevel
//
// Here's for the german edition.
//
//==============================================================================
procedure G_SecretExitLevel;
begin
  secretexit := true;
  gameaction := ga_completed;
end;

//==============================================================================
//
// G_DoCompleted
//
//==============================================================================
procedure G_DoCompleted;
var
  i: integer;
  next: string;
label
  frommapinfo;
begin
  gameaction := ga_nothing;

  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
      G_PlayerFinishLevel(@players[i]); // take away cards and stuff

  if amstate <> am_inactive then
  begin
    amstate := am_inactive;
    AM_Stop;
  end;

  case gamemap of
    3:
      begin
        if customgame = cg_beta then
        begin
          gameaction := ga_victory;
          exit;
        end;
      end;
    8:
      begin
        gameaction := ga_victory;
        exit;
      end;
    9:
      begin
        for i := 0 to MAXPLAYERS - 1 do
          players[i].didsecret := true;
      end;
  end;

  wminfo.didsecret := players[consoleplayer].didsecret;
  wminfo.epsd := gameepisode - 1;
  wminfo.nextep := gameepisode - 1;
  wminfo.last := gamemap - 1;

  wminfo.lastmapinfo := gamemapinfo;
  wminfo.nextmapinfo := nil;
  if gamemapinfo <> nil then
  begin
    if (gamemapinfo.endpic <> '') and (gamemapinfo.endpic <> '-') and gamemapinfo.nointermission then
    begin
      gameaction := ga_victory;
      exit;
    end;
    next := '';
    if secretexit then
      next := gamemapinfo.nextsecret;
    if next = '' then
      next := gamemapinfo.nextmap;
    if next <> '' then
      if G_ValidateMapName(next, @wminfo.nextep, @wminfo.next) then
      begin
        Dec(wminfo.nextep);
        Dec(wminfo.next);
        // episode change
        if wminfo.nextep <> wminfo.epsd then
          for i := 0 to MAXPLAYERS - 1 do
            players[i].didsecret := false;
        wminfo.didsecret := players[consoleplayer].didsecret;
        wminfo.partime := gamemapinfo.partime;
        goto frommapinfo; // skip past the default setup.
      end;
  end;

  TLevelProgression.HereticNextMap(secretexit, gameepisode, gamemap, wminfo.next);

  wminfo.partime := TICRATE * pars[gameepisode][gamemap];

frommapinfo:
  wminfo.nextmapinfo := G_LookupMapinfo(wminfo.nextep + 1, wminfo.next + 1);

  wminfo.maxkills := P_World.Totals.Kills;
  wminfo.maxitems := P_World.Totals.Items;
  wminfo.maxsecret := P_World.Totals.Secrets;
  wminfo.maxfrags := 0;

  wminfo.pnum := consoleplayer;

  for i := 0 to MAXPLAYERS - 1 do
  begin
    wminfo.plyr[i]._in := playeringame[i];
    wminfo.plyr[i].skills := players[i].killcount;
    wminfo.plyr[i].sitems := players[i].itemcount;
    wminfo.plyr[i].ssecret := players[i].secretcount;
    wminfo.plyr[i].stime := leveltime;
    memcpy(@wminfo.plyr[i].frags, @players[i].frags, SizeOf(wminfo.plyr[i].frags));
  end;

  gamestate := GS_INTERMISSION;
  viewactive := false;
  amstate := am_inactive;

  if statcopy <> nil then
    memcpy(statcopy, @wminfo, SizeOf(wminfo));

  IN_Start(@wminfo);
end;

//==============================================================================
//
// G_WorldDone
//
//==============================================================================
procedure G_WorldDone;
begin
  gameaction := ga_worlddone;

  if secretexit then
    players[consoleplayer].didsecret := true;

  if gamemapinfo <> nil then
  begin
    if (gamemapinfo.intertextsecret[0] <> #0) and secretexit then
    begin
      if gamemapinfo.intertextsecret[0] <> '-' then // '-' means that any default intermission was cleared.
        F_StartFinale;
      exit;
    end
    else if (gamemapinfo.intertext[0] <> #0) and not secretexit then
    begin
      if gamemapinfo.intertext[0] <> '-' then // '-' means that any default intermission was cleared.
        F_StartFinale;
      exit;
    end
    else if (gamemapinfo.endpic <> '') and (gamemapinfo.endpic <> '-') then
    begin
      // game ends without a status screen.
      gameaction := ga_victory;
      exit;
    end;
    // if nothing applied, use the defaults.
  end;

end;

//==============================================================================
//
// G_DoWorldDone
//
//==============================================================================
procedure G_DoWorldDone;
begin
  gamestate := GS_LEVEL;
  gameepisode := wminfo.nextep + 1;
  gamemap := wminfo.next + 1;
  gamemapinfo := G_LookupMapinfo(gameepisode, gamemap);
  G_DoLoadLevel;
  gameaction := ga_nothing;
  viewactive := true;
end;

//==============================================================================
//
// G_GetSaveName
//
//==============================================================================
function G_GetSaveName(name: string): string;
begin
  result := TSaveGameName.Resolve(name, Ord(load_end), D_GetSavePath + SAVEGAMENAME);
end;

//
// G_InitFromSavegame
// Can be called by the startup code or the menu task.
//
var
  savename: string;

//==============================================================================
//
// G_LoadGame
//
//==============================================================================
procedure G_LoadGame(const name: string);
begin
  savename := name;
  gameaction := ga_loadgame;
end;

const
  VERSIONSIZE = 16;

//==============================================================================
//
// G_ReadSaveVersion
// Checks the version of a saved game (the text after the description)
//
//==============================================================================
function G_ReadSaveVersion(const header: System.PByte; const filelength: integer): boolean;
var
  versions: TSaveGameVersions;
  status: TSaveGameVersionStatus;
  loadedversion, hack: integer;
  vsaved: string;
begin
  versions := TSaveGameVersions.Create(VERSION, 'heretic');
  try
    // JVAL: check for compatible game versions here
    versions.AddCompatible('version 110', 110);
    versions.AddCompatible('heretic 111', 111);
    versions.AddCompatible('heretic 112', 112);
    versions.AddCompatible('heretic 113', 113);
    versions.AddCompatible('heretic 114', 114);
    versions.AddCompatible('heretic 115', 115);
    versions.AddCompatible('heretic 203', 203);
    versions.AddCompatible('heretic 204', 204);
    versions.AddCompatible('heretic 205', 205);
    versions.AddCompatible('heretic 206', 206);
    status := versions.Resolve(header, filelength, loadedversion, hack, vsaved);
  finally
    versions.Free;
  end;

  savegameversion := loadedversion;
  result := true;
  if status = sgvTooShort then
  begin
    I_Warning('G_DoLoadGame(): Saved game is from an unsupported version.'#13#10);
    result := false;
  end
  else if status = sgvUnsupported then
  begin
    I_Warning('G_DoLoadGame(): Saved game is from an unsupported version: %s!'#13#10, [vsaved]);
    result := false;
  end;
end;

//==============================================================================
//
// G_DoLoadGame
//
//==============================================================================
procedure G_DoLoadGame;
var
  len: integer;
  i: integer;
begin
  gameaction := ga_nothing;

  savename := G_GetSaveName(savename);
  if not fexists(savename) then
  begin
    I_Warning('Can not open %s'#13#10, [savename]);
    exit;
  end;

  len := G_Files.ReadFile(savename, pointer(savebuffer));
  save_p := PByteArray(NativeInt(savebuffer) + SAVESTRINGSIZE);

  savegameversion := VERSION; // Assume current version

  if not G_ReadSaveVersion(System.PByte(save_p), len) then
  begin
    Z_Free(savebuffer);
    exit; // bad version
  end;

  save_p := PByteArray(NativeInt(save_p) + VERSIONSIZE);

  P_UnArchiveScreenShot;

  gameskill := skill_t(save_p[0]);
  defaultskill := save_p[0];
  save_p := PByteArray(NativeInt(save_p) + 1);

  gameepisode := save_p[0];
  save_p := PByteArray(NativeInt(save_p) + 1);

  gamemap := save_p[0];
  save_p := PByteArray(NativeInt(save_p) + 1);

  gamemapinfo := G_LookupMapinfo(gameepisode, gamemap);

  for i := 0 to MAXPLAYERS - 1 do
  begin
    playeringame[i] := save_p[0] <> 0;
    save_p := PByteArray(NativeInt(save_p) + 1);
  end;

  // load a base level
  G_InitNew(gameskill, gameepisode, gamemap);

  // get the times
  P_World.Time.LevelTime^ := TSaveGameHeader.ReadLevelTime(System.PByte(save_p));
  save_p := PByteArray(NativeInt(save_p) + 3);

  // dearchive all the modifications
  P_UnArchivePlayers;
  P_UnArchiveWorld;
  P_UnArchiveThinkers;
  P_UnArchiveSpecials;
  P_UnArchiveVariables;
  P_UnArchivePSMapScript;
  P_UnArchiveOverlay;

  if save_p[0] <> $1d then
    I_Error('G_DoLoadGame(): Bad savegame');

  // done
  Z_Free(savebuffer);

  if setsizeneeded then
    R_ExecuteSetViewSize;

  P_LevelInfoChangeMusic;

  // draw the pattern into the back screen
{$IFNDEF OPENGL}
  R_FillBackScreen;
{$ENDIF}
end;

//==============================================================================
//
// G_SaveGame
// Called by the menu task.
// Description is a 24 byte text string
//
//==============================================================================
procedure G_SaveGame(slot: integer; const description: string);
begin
  savegameslot := slot;
  savedescription := description;
  sendsave := true;
end;

//==============================================================================
//
// G_DoSaveGameInFile
//
//==============================================================================
procedure G_DoSaveGameInFile(name: string);
var
  description: string;
  len: integer;
  i: integer;
  maxsize: integer;
begin
  name := G_GetSaveName(name);

  description := savedescription;

  maxsize := SAVEGAMESIZE + PS_MapScriptSaveSize;
  repeat
    savebuffer := PByteArray(Z_Malloc2(maxsize, PU_STATIC, nil));
    if savebuffer = nil then
      maxsize := maxsize * 3 div 4;
  until savebuffer <> nil;

  save_p := savebuffer;

  // The description is stored as 8 bit text
  TSaveGameHeader.WriteDescription(System.PByte(save_p), SAVESTRINGSIZE, description, 0);

  save_p := PByteArray(NativeInt(save_p) + SAVESTRINGSIZE);

  savegameversion := VERSION;
  // The version is stored as 8 bit text
  TSaveGameHeader.WriteVersion(System.PByte(save_p), VERSION, VERSIONSIZE, 'heretic');
  save_p := PByteArray(NativeInt(save_p) + VERSIONSIZE);
  P_ArchiveScreenShot;

  save_p[0] := Ord(gameskill);
  save_p := PByteArray(NativeInt(save_p) + 1);

  save_p[0] := gameepisode;
  save_p := PByteArray(NativeInt(save_p) + 1);

  save_p[0] := gamemap;
  save_p := PByteArray(NativeInt(save_p) + 1);

  for i := 0 to MAXPLAYERS - 1 do
  begin
    save_p[0] := intval(playeringame[i]);
    save_p := PByteArray(NativeInt(save_p) + 1);
  end;

  TSaveGameHeader.WriteLevelTime(System.PByte(save_p), P_World.Time.LevelTime^);
  save_p := PByteArray(NativeInt(save_p) + 3);

  len := NativeInt(save_p) - NativeInt(savebuffer);
  G_Files.WriteFile(name, savebuffer, len);
  save_p := savebuffer;

  P_ArchivePlayers;

  len := NativeInt(save_p) - NativeInt(savebuffer);
  G_Files.AppendFile(name, savebuffer, len);
  save_p := savebuffer;

  P_ArchiveWorld;

  len := NativeInt(save_p) - NativeInt(savebuffer);
  G_Files.AppendFile(name, savebuffer, len);
  save_p := savebuffer;

  P_ArchiveThinkers;

  len := NativeInt(save_p) - NativeInt(savebuffer);
  G_Files.AppendFile(name, savebuffer, len);
  save_p := savebuffer;

  P_ArchiveSpecials;

  len := NativeInt(save_p) - NativeInt(savebuffer);
  G_Files.AppendFile(name, savebuffer, len);
  save_p := savebuffer;

  P_ArchiveVariables;

  len := NativeInt(save_p) - NativeInt(savebuffer);
  G_Files.AppendFile(name, savebuffer, len);
  save_p := savebuffer;

  P_ArchivePSMapScript;

  len := NativeInt(save_p) - NativeInt(savebuffer);
  G_Files.AppendFile(name, savebuffer, len);
  save_p := savebuffer;

  P_ArchiveOverlay;

  save_p[0] := $1d; // consistancy marker

  len := NativeInt(save_p) - NativeInt(savebuffer) + 1;
  if len > maxsize then
    I_Error('G_DoSaveGame(): Savegame buffer overrun');
  G_Files.AppendFile(name, savebuffer, len);

  Z_Free(savebuffer);
  gameaction := ga_nothing;
  savedescription := '';

  players[consoleplayer]._message := GGSAVED;

  // draw the pattern into the back screen
{$IFNDEF OPENGL}
  R_FillBackScreen;
{$ENDIF}
end;

//==============================================================================
//
// G_DoSaveGame
//
//==============================================================================
procedure G_DoSaveGame;
var
  name: string;
begin
  if savegameslot = Ord(load_end) then
    name := savename
  else
  begin
    sprintf(name, M_SaveFileName(D_GetSavePath + SAVEGAMENAME) + '%d.dsg', [savegameslot]);
  end;

  G_DoSaveGameInFile(name);

end;

//==============================================================================
//
// G_SaveGameNow
//
// The save of the test options (-autosave): the game is saved at the start of the
// next tic, whatever the commands of the players are (a demo or the automatic pilot
// replace them, so the button of G_SaveGame would be lost).
//
//==============================================================================
procedure G_SaveGameNow(slot: integer; const description: string);
begin
  savegameslot := slot;
  savedescription := description;
  gameaction := ga_savegame;
end;

//==============================================================================
//
// G_CmdSaveGame
//
//==============================================================================
procedure G_CmdSaveGame(const sname: string; const description: string);
begin
  if not usergame or (gamestate <> GS_LEVEL) then
  begin
    printf('You can''t save if you aren''t playing!'#13#10);
    exit;
  end;

  if sname <> '' then
  begin
    savename := sname;
    if description <> '' then
      savedescription := description
    else
      savedescription := savename;
    sendcmdsave := true;
  end
  else
    printf('Usage: savegame [slot(integer)] [description(string)]');
end;

//
// G_InitNew
// Can be called by the startup code or the menu task,
// consoleplayer, displayplayer, playeringame[] should be set.
//
var
  d_skill: skill_t;
  d_episode: integer;
  d_map: integer;

//==============================================================================
//
// G_DeferedInitNew
//
//==============================================================================
procedure G_DeferedInitNew(skill: skill_t; episode, map: integer);
begin
  d_skill := skill;
  d_episode := episode;
  d_map := map;
  gameaction := ga_newgame;
end;

//==============================================================================
//
// G_CmdNewGame
//
//==============================================================================
procedure G_CmdNewGame(const parm1, parm2: string);
var
  epsd, map: integer;
begin
  if parm1 = '' then
  begin
    printf('Please specify the level to play'#13#10);
    exit;
  end;

  TMapName.FromArguments(False, parm1, parm2, epsd, map);

  if W_CheckNumForName(P_GetMapName(epsd, map)) > -1 then
  begin
    players[consoleplayer]._message := STSTR_CLEV;
    G_DeferedInitNew(gameskill, epsd, map);
    C_ExecuteCmd('closeconsole', '1');
  end
  else
    I_Warning('G_CmdNewGame(): Can not load map.'#13#10);
end;

//==============================================================================
//
// G_DoNewGame
//
//==============================================================================
procedure G_DoNewGame;
var
  i: integer;
begin
  G_FinishedDemoPlayback; // JVAL: remove???
  netdemo := false;
  netgame := false;
  deathmatch := 0;
  for i := 1 to MAXPLAYERS - 1 do
    playeringame[i] := false;
  respawnparm := false;
  fastparm := false;
  nomonsters := false;
  consoleplayer := 0;
  G_InitNew(d_skill, d_episode, d_map);
  gameaction := ga_nothing;
end;

//==============================================================================
//
// G_InitNew
//
//==============================================================================
procedure G_InitNew(skill: skill_t; episode, map: integer);
var
  i: integer;
  levelinf: Plevelinfo_t;
  LMapMissing: boolean;
  LEdition: TNewGameEdition;
  LSpeedChange: TSkillSpeedChange;
begin
  if paused then
  begin
    paused := false;
    S_ResumeSound;
  end;

  if skill > sk_nightmare then
    skill := sk_nightmare;

  if episode < 1 then
    episode := 1;

  // The episode and the map are brought to the limits first: the lump of the map is looked for after
  if episode < 1 then
    episode := 1;
  if map < 1 then
    map := 1
  else if map > 9 then
    map := 9;
  LMapMissing := not EpiCustom and (W_CheckNumForName(P_GetMapName(episode, map)) < 0);

  case gamemode of
    shareware: LEdition := ngeShareware;
    extendedwad: LEdition := ngeExtended;
  else
    LEdition := ngeRegistered;
  end;
  TNewGameLimits.Heretic(LMapMissing, LEdition, episode, map);

  levelinf := P_GetLevelInfo(P_GetMapName(episode, map));
  levelinf.musname := stringtochar8('');
  levelinf.skyflat := stringtochar8('');

  R_ResetInterpolationBuffer;

  M_ClearRandom;
  PS_NewWorld;
  P_ACSInitNewGame;

  respawnmonsters := TSkillSpeed.RespawnMonsters(skill = sk_nightmare, respawnparm);

  // JVAL: 20210207 -> Support for fast speed mobj info field
  LSpeedChange := TSkillSpeed.Change(fastparm, skill = sk_nightmare, gameskill = sk_nightmare);
  if LSpeedChange = sscFast then
  begin
    for i := 0 to nummobjtypes - 1 do
      if mobjinfo[i].fastspeed <> 0 then
        mobjinfo[i].speed := mobjinfo[i].fastspeed;
  end
  else if LSpeedChange = sscNormal then
  begin
    for i := 0 to nummobjtypes - 1 do
      if mobjinfo[i].normalspeed <> 0 then
        mobjinfo[i].speed := mobjinfo[i].normalspeed;
  end;

  // force players to be initialized upon first level load
  for i := 0 to MAXPLAYERS - 1 do
    players[i].playerstate := PST_REBORN;

  usergame := true;  // will be set false if a demo
  paused := false;
  G_FinishedDemoPlayback;
  amstate := am_inactive;
  viewactive := true;
  gameepisode := episode;
  gamemap := map;
  gameskill := skill;
  gamemapinfo := G_LookupMapinfo(gameepisode, gamemap);

  viewactive := true;

  G_DoLoadLevel;
end;

var
  demoversion: byte;

//
// DEMO PLAYBACK
//
const
  DEMOMARKER = $80;

var
  compatibility_done: boolean;

//==============================================================================
//
// G_ReadDemoTiccmd
//
//==============================================================================
procedure G_ReadDemoTiccmd(cmd: Pticcmd_t);
var
  LPosition: System.PByte;
  LCommand: TDemoCommand;
begin
  if demo_p[0] = DEMOMARKER then
  begin
    // end of demo data stream
    G_CheckDemoStatus;
    exit;
  end;

  LPosition := System.PByte(demo_p);
  TDemoCommandCodec.Read(LPosition, dlHeretic, demoversion, false, LCommand);
  demo_p := PByteArray(LPosition);

  cmd.forwardmove := LCommand.ForwardMove;
  cmd.sidemove := LCommand.SideMove;
  cmd.angleturn := LCommand.AngleTurn;
  cmd.buttons := LCommand.Buttons;
  cmd.lookfly := LCommand.LookFly;
  cmd.arti := LCommand.Arti;
  cmd.lookleftright := LCommand.LookLeftRight;
  cmd.jump_crouch := LCommand.JumpCrouch;
  cmd.lookupdown16 := LCommand.LookUpDown16; // JVAL Smooth Look Up/Down
  cmd.lookupdown := LCommand.LookUpDown; // JVAL unused :)
end;

//==============================================================================
// G_IncreaseDemoBuffer
//
// DEMO RECORDING
//
// Increase the size of the demo buffer to allow unlimited demos
//
//==============================================================================
procedure G_IncreaseDemoBuffer;
var
  current_length: integer;
  new_demobuffer: PByteArray;
  new_demop: PByteArray;
  new_length: integer;
begin
  // Find the current size

  current_length := NativeInt(demoend) - NativeInt(demobuffer);

  // Generate a new buffer twice the size
  new_length := current_length + $80000;

  new_demobuffer := Z_Malloc2(new_length, PU_STATIC, nil);
  if new_demobuffer = nil then
    G_CheckDemoStatus;

  new_demop := @new_demobuffer[NativeInt(demo_p) - NativeInt(demobuffer)];

  // Copy over the old data

  memcpy(new_demobuffer, demobuffer, current_length);

  // Free the old buffer and point the demo pointers at the new buffer.

  Z_Free(demobuffer);

  demobuffer := new_demobuffer;
  demo_p := new_demop;
  demoend := @demobuffer[new_length];
end;

//==============================================================================
//
// G_WriteDemoTiccmd
//
//==============================================================================
procedure G_WriteDemoTiccmd(cmd: Pticcmd_t);
var
  LCommand: TDemoCommand;
begin
  if gamekeydown[Ord('q')] then // press q to end demo recording
    G_CheckDemoStatus;

  LCommand := Default(TDemoCommand);
  LCommand.ForwardMove := cmd.forwardmove;
  LCommand.SideMove := cmd.sidemove;
  LCommand.AngleTurn := cmd.angleturn;
  LCommand.Buttons := cmd.buttons;
  LCommand.LookFly := cmd.lookfly;
  LCommand.Arti := cmd.arti;
  LCommand.LookLeftRight := cmd.lookleftright;
  LCommand.JumpCrouch := cmd.jump_crouch;
  LCommand.LookUpDown16 := cmd.lookupdown16; // JVAL Smooth Look Up/Down
  TDemoCommandCodec.Write(System.PByte(demo_p), dlHeretic, LCommand);

  if NativeInt(demo_p) >= NativeInt(demoend) - 2 * SizeOf(ticcmd_t) then
    G_IncreaseDemoBuffer;

  G_ReadDemoTiccmd(cmd);  // make SURE it is exactly the same
end;

//==============================================================================
//
// G_RecordDemo
//
//==============================================================================
procedure G_RecordDemo(const name: string);
var
  i: integer;
  maxsize: integer;
begin
  usergame := false;
  demoname := name;
  if CharPos('.', demoname) = 0 then
    demoname := demoname + '.lmp';

  i := M_CheckParm ('-maxdemo');
  if (i <> 0) and (i < myargc - 1) then
    maxsize := atoi(myargv[i + 1]) * 1024
  else
    maxsize := $80000; // JVAL Originally was $20000

  repeat
    demobuffer := Z_Malloc2(maxsize, PU_STATIC, nil);
    if demobuffer = nil then
      maxsize := maxsize * 3 div 4;
  until demobuffer <> nil;

  demoend := @demobuffer[maxsize];

  demorecording := true;
  Info_Init(true); // JVAL: Start thinkers
end;

//==============================================================================
//
// G_BeginRecording
//
//==============================================================================
procedure G_BeginRecording;
var
  i: integer;
  LPosition: System.PByte;
  LHeader: TDemoHeader;
begin
  demo_p := demobuffer;
  demoversion := VERSION;

  LHeader := Default(TDemoHeader);
  LHeader.Version := VERSION;
  LHeader.Skill := Ord(gameskill);
  LHeader.Episode := gameepisode;
  LHeader.Map := gamemap;
  LHeader.Deathmatch := deathmatch;
  LHeader.Respawn := respawnparm;
  LHeader.Fast := fastparm;
  LHeader.NoMonsters := nomonsters;
  LHeader.Compatibility := compatibilitymode;
  LHeader.SpawnRandomMonsters := spawnrandommonsters;
  LHeader.Seed := M_GetSystemRandomSeed;
  LHeader.ConsolePlayer := consoleplayer;
  for i := 0 to MAXPLAYERS - 1 do
    LHeader.PlayersInGame[i] := playeringame[i];

  LPosition := System.PByte(demo_p);
  TDemoHeaderCodec.Write(LPosition, TDemoProfiles.Heretic(MAXPLAYERS), LHeader);
  demo_p := PByteArray(LPosition);
end;

//
// G_PlayDemo
//
var
  defdemoname: string;
  externaldemo: boolean = false;

//==============================================================================
//
// G_DoPlayExternalDemo
//
//==============================================================================
function G_DoPlayExternalDemo(const name: string): boolean;
var
  dmname: string;
begin
  dmname := name;
  if not fexists(dmname) then
    if M_CheckParmCDROM then
      dmname := CD_WORKDIR + dmname;
  if fexists(dmname) then
  begin
    externaldemo := true;
    defdemoname := dmname;
    gameaction := ga_playdemo;
    printf('Playing demo %s'#13#10, [defdemoname]);
    result := true;
    exit;
  end;
  result := false;
end;

//==============================================================================
//
// G_DeferedPlayDemo
//
//==============================================================================
function G_DeferedPlayDemo(const name: string): boolean;
var
  dmname: string;
  dmname2: string;
  defdemoname8: char8_t;
  i: integer;
  pdot: integer;
begin
  dmname := name;
  for i := 0 to 9 do
    if itoa(i) = name then
    begin
      sprintf(dmname, 'demo%d', [i]);
      break;
    end;

  pdot := CharPos('.', dmname);
  if ((Length(dmname) <= 8) and (pdot = 0)) or ((pdot < 9) and (pdot <> 0)) then
  begin
    ExtractFileBase8(dmname, defdemoname8);
    defdemoname := char8tostring(defdemoname8);
    if W_CheckNumForName(defdemoname) >= 0 then
    begin
      externaldemo := false;
      gameaction := ga_playdemo;
      printf('Playing demo %s'#13#10, [defdemoname]);
      result := true;
      exit;
    end;
  end;

  // JVAL
  // Playdemo command also looks for a filename in current or CD_WORK directory
  dmname2 := dmname;
  if pdot = 0 then
    dmname := dmname + '.lmp';
  if G_DoPlayExternalDemo(dmname) then
  begin
    result := true;
    exit;
  end;

  if pdot = 0 then
  begin
    dmname := dmname2 + '.dem';
    if G_DoPlayExternalDemo(dmname) then
    begin
      result := true;
      exit;
    end;
  end;

  I_Warning('G_DeferedPlayDemo(): Can not find demo %s.'#13#10, [defdemoname]);
  result := false;
end;

//==============================================================================
//
// G_CmdPlayDemo
//
//==============================================================================
procedure G_CmdPlayDemo(const name: string);
begin
  if G_DeferedPlayDemo(name) then
    C_ExecuteCmd('closeconsole', '1');
end;

//==============================================================================
//
// G_DoPlayDemo
//
//==============================================================================
procedure G_DoPlayDemo;
var
  skill: skill_t;
  i, episode, map: integer;
  lump: integer;
  len: integer;
  oldspawnrandommonsters: boolean;
  LProfile: TDemoHeaderProfile;
  LPosition: System.PByte;
  LHeader: TDemoHeader;
begin
  gameaction := ga_nothing;
  if externaldemo then
    len := G_Files.ReadFile(defdemoname, pointer(demobuffer))
  else
  begin
    lump := W_GetNumForName(defdemoname);
    demobuffer := W_CacheLumpNum(lump, PU_STATIC);
    len := W_LumpLength(lump);
  end;

  demo_p := demobuffer;
  demoend := @demo_p[len];

  LProfile := TDemoProfiles.Heretic(MAXPLAYERS);
  LPosition := System.PByte(demo_p);
  TDemoHeaderCodec.ReadVersion(LPosition, LProfile.Magic, demoversion);
  demo_p := PByteArray(LPosition);

  if demoversion < VERSION110 then
  begin
    I_Warning('G_DoPlayDemo(): Demo is from an unsupported game version = %d.%.*d' + #13#10,
      [demo_p[0] div 100, 2, demo_p[0] mod 100]);
    gameaction := ga_nothing;
    exit;
  end
  else if demoversion <> VERSION then
    I_Warning('G_DoPlayDemo(): Demo is from a partial supported game version = %d.%.*d' + #13#10,
      [demo_p[0] div 100, 2, demo_p[0] mod 100]);

  LPosition := System.PByte(demo_p);
  TDemoHeaderCodec.Read(LPosition, LProfile, false, LHeader);
  demo_p := PByteArray(LPosition);

  skill := skill_t(LHeader.Skill);
  episode := LHeader.Episode;
  map := LHeader.Map;
  deathmatch := LHeader.Deathmatch;
  respawnparm := LHeader.Respawn;
  fastparm := LHeader.Fast;
  nomonsters := LHeader.NoMonsters;

  oldcompatibilitymode := compatibilitymode;
  compatibilitymode := LHeader.Compatibility;

  oldspawnrandommonsters := spawnrandommonsters;
  spawnrandommonsters := LHeader.SpawnRandomMonsters;
  if LHeader.HasSeed then
    M_SetSystemRandomSeed(LHeader.Seed);

  consoleplayer := LHeader.ConsolePlayer;

  for i := 0 to MAXPLAYERS - 1 do
    playeringame[i] := LHeader.PlayersInGame[i];

  if playeringame[1] then
  begin
    netgame := true;
    netdemo := true;
  end;

  preparingdemoplayback := true;
  // don't spend a lot of time in loadlevel if not singledemo
  precache := singledemo; // JVAL original code: precache := false
  G_InitNew(skill, episode, map);
  preparingdemoplayback := false;
  spawnrandommonsters := oldspawnrandommonsters;  // Back to default
  precache := true;
  usergame := false;
  demoplayback := true;
  Info_Init(true); // JVAL: Start thinkers

  compatibility_done := false;

end;

//==============================================================================
//
// G_TimeDemo
//
//==============================================================================
procedure G_TimeDemo(const name: string);
begin
  timingdemo := true;
  singletics := true;

  defdemoname := name;
  gameaction := ga_playdemo;
end;

(*
===================
=
= G_CheckDemoStatus
=
= Called after a death or level completion to allow demos to be cleaned up
= Returns true if a new demo loop action will take place
===================
*)

//==============================================================================
//
// G_CheckDemoStatus
//
//==============================================================================
function G_CheckDemoStatus: boolean;
var
  endtime: integer;
  i: integer;
begin
  if timingdemo then
  begin
    endtime := I_GetTime;
    // The result goes to the log and the program ends like after a single demo: with I_Error it was a
    // message box that waited for a click while the worker threads kept running (#147)
    printf('G_CheckDemoStatus(): timed %d gametics in %d realtics'#13#10, [gametic, endtime - starttime]);
    timingdemo := false;
    singledemo := true;
  end;

  if demoplayback then
  begin
    if singledemo then
      I_Quit;

    Z_Free(demoBuffer);
    G_FinishedDemoPlayback;
    netdemo := false;
    netgame := false;
    deathmatch := 0;
    for i := 1 to MAXPLAYERS - 1 do
      playeringame[i] := false;
    respawnparm := false;
    fastparm := false;
    nomonsters := false;
    consoleplayer := 0;
    D_AdvanceDemo;
    result := true;
    exit;
  end;

  if demorecording then
  begin
    demo_p[0] := DEMOMARKER;
    demo_p := @demo_p[1];

    G_Files.WriteFile(demoname, demobuffer, pDiff(demo_p, demobuffer, SizeOf(byte)));
    Z_Free(demobuffer);
    demorecording := false;
    I_Error('G_CheckDemoStatus(): Demo %s recorded', [demoname]);
  end;

  result := false;
end;

//==============================================================================
//
// G_NeedsCompatibilityMode
//
//==============================================================================
function G_NeedsCompatibilityMode: boolean;
begin
  result := compatibilitymode;
end;

//==============================================================================
//
// G_PlayingEngineVersion
//
//==============================================================================
function G_PlayingEngineVersion: byte;
begin
  if demoplayback then
    result := demoversion
  else
    result := VERSION;
end;

//==============================================================================
//
// G_Quit
//
//==============================================================================
procedure G_Quit;
begin
  if displayendscreen then
  begin
    gamestate := GS_ENDOOM;
    S_PauseSound; // Stop music in ENDOOM screen
    printf('E_Init: Initializing ENDTEXT screen.'#13#10, [mb_used]);
    G_EndoomScreen.Initialize;
  end
  else
    I_Quit;
end;

//==============================================================================
//
// G_LookupMapinfo
//
//==============================================================================
function G_LookupMapinfo(const episode, map: integer): Pmapentry_t;
var
  lumpname: string;
  i: integer;
begin
  lumpname := TMapName.EpisodeName(episode, map);
  for i := 0 to u_mapinfo.mapcount - 1 do
    if lumpname = u_mapinfo.maps[i].mapname then
    begin
      result := @u_mapinfo.maps[i];
      exit;
    end;

  for i := 0 to default_mapinfo.mapcount - 1 do
    if lumpname = default_mapinfo.maps[i].mapname then
    begin
      result := @default_mapinfo.maps[i];
      exit;
    end;

  result := nil;
end;

//==============================================================================
//
// G_ValidateMapName
//
//==============================================================================
function G_ValidateMapName(const amap: string; const pepi, pmapnum: PInteger): boolean;
var
  epi, mapnum: integer;
begin
  result := TMapName.TryParse(amap, TMapName.HereticRules, epi, mapnum);
  if result then
  begin
    if pepi <> nil then
      pepi^ := epi;
    if pmapnum <> nil then
      pmapnum^ := mapnum;
  end;
end;

initialization

  forwardmove[0] := $19;
  forwardmove[1] := $32;
  sidemove[0] := $18;
  sidemove[1] := $28;
  angleturn[0] := 640;
  angleturn[1] := 1280;
  angleturn[2] := 320;

  mousebuttons := PBooleanArray(@mousearray[0]);
  joybuttons := PBooleanArray(@joyarray[0]);

  ZeroMemory(@pars, SizeOf(pars));

  pars[1, 1] := 30;
  pars[1, 2] := 75;
  pars[1, 3] := 120;
  pars[1, 4] := 90;
  pars[1, 5] := 165;
  pars[1, 6] := 180;
  pars[1, 7] := 180;
  pars[1, 8] := 30;
  pars[1, 9] := 165;

  pars[2, 1] := 90;
  pars[2, 2] := 90;
  pars[2, 3] := 90;
  pars[2, 4] := 120;
  pars[2, 5] := 90;
  pars[2, 6] := 360;
  pars[2, 7] := 240;
  pars[2, 8] := 30;
  pars[2, 9] := 170;

  pars[3, 1] := 90;
  pars[3, 2] := 45;
  pars[3, 3] := 90;
  pars[3, 4] := 150;
  pars[3, 5] := 90;
  pars[3, 6] := 90;
  pars[3, 7] := 165;
  pars[3, 8] := 30;
  pars[3, 9] := 135;

  precache := true;

  KEY_WEAPONS[0] := @key_weapon0;
  KEY_WEAPONS[1] := @key_weapon1;
  KEY_WEAPONS[2] := @key_weapon2;
  KEY_WEAPONS[3] := @key_weapon3;
  KEY_WEAPONS[4] := @key_weapon4;
  KEY_WEAPONS[5] := @key_weapon5;
  KEY_WEAPONS[6] := @key_weapon6;
  KEY_WEAPONS[7] := @key_weapon7;

end.

