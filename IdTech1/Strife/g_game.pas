//------------------------------------------------------------------------------
//
//  DelphiStrife is a source port of the game Strife.
//
//  Based on:
//    - Linux Doom by "id Software"
//    - Chocolate Strife by "Simon Howard"
//    - DelphiDoom by "Jim Valavanis"
//
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2005 Simon Howard
//  Copyright (C) 2010 James Haley, Samuel Villarreal
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
  tables,
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
procedure G_InitNew(skill: skill_t; map: integer);

//==============================================================================
// G_DeferedInitNew
//
// Can be called by the startup code or M_Responder.
// A normal game starts at map 1,
// but a warp test can start elsewhere
//
//==============================================================================
procedure G_DeferedInitNew(skill: skill_t; map: integer);

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
procedure G_DoLoadGame(const userload: boolean);

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
procedure G_ExitLevel(dest: integer);

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

//==============================================================================
//
// G_Quit
//
//==============================================================================
procedure G_Quit;

//==============================================================================
// G_DemoProgress
//
// 19/9/2009 JVAL: For drawing demo progress
//
//==============================================================================
function G_DemoProgress: fixed_t;

type
  /// <summary>
  ///   The state of the game in progress that outlives a level (issue #245). Plain class vars with
  ///   a fixed address, like the globals they replace: no property (the address is taken), no
  ///   method (it would be a call at every read); the class lives here, in the unit that writes
  ///   the most, because a variable of another unit costs a load more (see PIANO_TUTTO_A_CLASSI 11.16)
  /// </summary>
  TGameSession = class sealed
  public
    /// <summary>The game was started by the player (ok to save / end game); false while a demo plays</summary>
    class var UserGame: boolean;
    /// <summary>Monsters respawn (nightmare skill or -respawn)</summary>
    class var RespawnMonsters: boolean;
    /// <summary>A demo is being recorded</summary>
    class var DemoRecording: boolean;
    /// <summary>The tic of the game in progress</summary>
    class var GameTic: integer;
    /// <summary>The action the game loop does at the start of the next tic</summary>
    class var GameAction: gameaction_t;
    /// <summary>The game is paused</summary>
    class var Paused: boolean;
    /// <summary>A demo is being played back</summary>
    class var DemoPlayback: boolean;
    /// <summary>The demo being played was recorded in a net game</summary>
    class var NetDemo: boolean;
    /// <summary>If true, exit with a report when the demo ends</summary>
    class var TimingDemo: boolean;
    /// <summary>The level of a demo is being set up, before the demo plays</summary>
    class var PreparingDemoPlayback: boolean;
    /// <summary>Checkparm of -nomonsters (or the demo header)</summary>
    class var NoMonsters: boolean;
    /// <summary>Checkparm of -fast (or the demo header)</summary>
    class var FastParm: boolean;
    /// <summary>Checkparm of -respawn (or the demo header)</summary>
    class var RespawnParm: boolean;
    /// <summary>Player taking events and displaying</summary>
    class var ConsolePlayer: integer;
    /// <summary>Only true if packets are broadcast</summary>
    class var NetGame: boolean;
    /// <summary>Only if started as net death</summary>
    class var DeathMatch: integer;
    /// <summary>Map of the level in progress</summary>
    class var GameMap: integer;
    /// <summary>Skill of the game in progress</summary>
    class var GameSkill: skill_t;
    /// <summary>
    ///   The state a new game or the end of a demo starts from: no demo of a net game, no net game, no
    ///   deathmatch, one player, no -respawn, -fast or -nomonsters, the console player is the first
    /// </summary>
    class procedure ResetForNewGame; static;
  end;
var
  sendpause: boolean;        // send a pause event next tic


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
// JVAL Look Left and Right
  key_lookright: integer;
  key_lookleft: integer;

  key_strafeleft: integer;
  key_straferight: integer;
  key_fire: integer;
  key_use: integer;
  key_strafe: integer;
  key_speed: integer;

  key_invleft: integer; //  KEY_INS;
  key_invright: integer; // KEY_DEL;

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
  key_weapon8: integer = Ord('9');
  key_weapon9: integer = Ord('0');

  KEY_WEAPONS: array[0..Ord(NUMWEAPONS) - 1] of PInteger;

// Inventory
  key_usehealth: integer; // 'h'
  key_invquery: integer;  // 'q';
  key_mission: integer;   // 'w';
  key_invpop: integer;    // 'z';
  key_invkey: integer;    // 'k';
  key_invhome: integer;   // KEY_HOME;
  key_invend: integer;    // KEY_END;
  key_invuse: integer;    // KEY_ENTER;
  key_invdrop: integer;   // KEY_BACKSPACE;

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

  showdemoplaybackprogress: boolean;

  gamemapinfo: Pmapentry_t;

  playeringame: array[0..MAXPLAYERS - 1] of boolean;

  displayplayer: integer; // view being displayed


  wminfo: wbstartstruct_t; // parms for world map / intermission



  precache: boolean; // if true, load all graphics at start


  viewactive: boolean;

  singledemo: boolean; // quit after playing a demo from cmdline




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

//==============================================================================
//
// G_StartFinale
//
//==============================================================================
procedure G_StartFinale;

//==============================================================================
//
// G_RiftExitLevel
//
//==============================================================================
procedure G_RiftExitLevel(map, spot: integer; angle: angle_t);

//==============================================================================
//
// G_RiftCheat
//
//==============================================================================
function G_RiftCheat(riftSpotNum: integer): boolean;

//==============================================================================
//
// G_WriteSaveName
//
//==============================================================================
function G_WriteSaveName(slot: integer; charname: string): boolean;

//==============================================================================
//
// G_ReadCurrent
//
//==============================================================================
procedure G_ReadCurrent(path: string);

var
  sendsave: boolean;         // send a save event next tic

const
  SAVEGAMESIZE = $1000000; // Originally $2C000
  SAVESTRINGSIZE = 24;

const
  NUMKEYS = 256;

var
  gamekeydown: array[0..NUMKEYS - 1] of boolean;
  mousebuttons: PBooleanArray;
  joybuttons: PBooleanArray;

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
  DelphiDoom.Demo.DeathTrimmer,
  DelphiDoom.Input.EventScaling,
  DelphiDoom.Thinkers.PlayerRespawn.Intf,
  DelphiDoom.Thinkers.PlayerRespawn,
  DelphiDoom.Thinkers.SpawnSpot,
  DelphiDoom.Engine.World.PlayerRespawnHost,
  DelphiDoom.MapInfo.MapName,
  DelphiDoom.MapInfo.NewGameLimits,
  DelphiDoom.MapInfo.SkillSpeed,
  deh_main,
  c_cmds,
  z_zone,
  doomstat,
  doomdata,
  d_items,
  am_map,
  d_net,
  d_net_h,
  d_main,
  f_finale,
  info_h,
  info,
  i_system,
{$IFNDEF OPENGL}
  r_draw,
{$ENDIF}
  m_argv,
  m_misc,
  m_menu,
  m_rnd,
  m_saves,
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
  p_dialog,
  p_acs,
  p_levelinfo,
  ps_main,
  hu_stuff,
  st_stuff,
  w_wad,
  s_sound,
// Data.
  dstrings,
  d_englsh,
  sounddata,
// SKY handling - still the wrong place.
  r_data,
  r_sky,
  r_defs,
  r_main,
  r_intrpl;

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

// Used for prev/next weapon keys.
// STRIFE-TODO: Check this table makes sense.

type
  weapon_order_item_t = record
    weapon: weapontype_t;
    weapon_num: weapontype_t;
  end;

const
  WEAPONORDERSIZE = 11;

var
  weapon_order_table: array[0..WEAPONORDERSIZE - 1] of weapon_order_item_t = (
    (weapon: wp_fist       ; weapon_num: wp_fist),
    (weapon: wp_poisonbow  ; weapon_num: wp_elecbow),
    (weapon: wp_elecbow    ; weapon_num: wp_elecbow),
    (weapon: wp_rifle      ; weapon_num: wp_rifle),
    (weapon: wp_missile    ; weapon_num: wp_missile),
    (weapon: wp_wpgrenade  ; weapon_num: wp_hegrenade),
    (weapon: wp_hegrenade  ; weapon_num: wp_hegrenade),
    (weapon: wp_flame      ; weapon_num: wp_flame),
    (weapon: wp_torpedo    ; weapon_num: wp_mauler),
    (weapon: wp_mauler     ; weapon_num: wp_mauler),
    (weapon: wp_sigil      ; weapon_num: wp_sigil)
  );

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
procedure G_DoSaveGame(path: string); forward;

//==============================================================================
//
// G_FinishedDemoPlayback
//
//==============================================================================
procedure G_FinishedDemoPlayback;
begin
  TGameSession.DemoPlayback := false;
  // Restore old compatibility mode
  compatibilitymode := oldcompatibilitymode;
end;

var
  sendcmdsave: boolean;      // send a save event next tic (console)

  starttime: integer;        // for comparative timing purposes

  demoname: string;
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
  lookupdown: integer;    // JVAL Look up and down
  look16: integer;        // JVAL Smooth Look Up/Down
  lookleftright: integer; // JVAL look left and right
  base: Pticcmd_t;
  imousex: integer;
  imousey: integer;
  player: Pplayer_t;
  cmd_jump, cmd_crouch: byte;
begin
  base := I_BaseTiccmd;    // empty, or external driver

  memcpy(cmd, base, SizeOf(cmd^));

  cmd.consistency := G_NetGame.ExpectedConsistency;

  player := @players[TGameSession.ConsolePlayer];

  // villsa [STRIFE] inventory use key
  if gamekeydown[key_invuse] then
  begin
    if player.numinventory > 0 then
    begin
      cmd.buttons2 := cmd.buttons2 or BT2_INVUSE;
      cmd.inventory := player.inventory[player.inventorycursor].sprite;
    end;
  end;

  // villsa [STRIFE] inventory drop key
  if gamekeydown[key_invdrop] then
  begin
    player := @players[TGameSession.ConsolePlayer];
    if player.numinventory > 0 then
    begin
      cmd.buttons2 := cmd.buttons2 or BT2_INVDROP;
      cmd.inventory := player.inventory[player.inventorycursor].sprite;
    end;
  end;

  // villsa [STRIFE] use medkit
  if gamekeydown[key_usehealth] then
    cmd.buttons2 := cmd.buttons2 or BT2_HEALTH;

  strafe := gamekeydown[key_strafe] or
            (usemouse and mousebuttons[mousebstrafe]) or
            (usejoystick and joybuttons[joybstrafe]);

  if player.health <= 15 then
    speed := 0
  else
  begin
    speed := intval(gamekeydown[key_speed] or joybuttons[joybspeed]);
    if autorunmode = 0 then
    else if autorunmode = 1 then
      speed := 1 - speed
    else if G_InputPoller.IsCapsLockOn then
      speed := 1 - speed;
  end;

  _forward := 0;
  side := 0;
  lookupdown := 0;
  look16 := 0; // JVAL Smooth Look Up/Down
  lookleftright := 0;

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
      lookupdown := lspeed;

    if gamekeydown[key_lookdown] then
      lookupdown := -lspeed;

    if gamekeydown[key_lookcenter] then
      lookupdown := TOCENTER;

    look16 := 256 * lookupdown; // JVAL Smooth Look Up/Down
  end;

  // JVAL Look right/left/forward keys
  if gamekeydown[key_lookleft] or (usejoystick and joybuttons[joyblleft]) then
    lookleftright := lspeed2;

  if gamekeydown[key_lookright] or (usejoystick and joybuttons[joyblright]) then
    lookleftright := -lspeed2;

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
    if players[TGameSession.ConsolePlayer].nextfire > TTickState.LevelTime then
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
    lookupdown := lookupdown + imousey div 16;
    if imousey < 0 then
    begin
      if lookupdown < -4 then
        lookupdown := -4;
    end
    else if imousey > 0 then
    begin
      if lookupdown > 4 then
        lookupdown := 4;
    end;

    // JVAL Smooth Look Up/Down
    if G_PlayingEngineVersion < VERSION203 then
      look16 := 256 * lookupdown
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

  if players[TGameSession.ConsolePlayer].playerstate = PST_LIVE then
  begin
    if zaxisshift then
    begin
      if lookupdown < 0 then
        lookupdown := lookupdown + 16;
      cmd.lookupdown := lookupdown;

      // JVAL Smooth Look Up/Down
      if look16 < 0 then
        look16 := look16 + 16 * 256;
      cmd.lookupdown16 := look16;
    end;
    if lookleftright < 0 then
      lookleftright := lookleftright + 16;
    cmd.lookleftright:= lookleftright;
    // JVAL
    // allowplayerjumps variable controls if we accept input for jumping
    if allowplayerjumps and (gamekeydown[key_jump] or (usejoystick and joybuttons[joybjump])) then
    begin
      if players[TGameSession.ConsolePlayer].oldjump <> 0 then
        cmd_jump := 1
      else
        cmd_jump := 2
      end
    else
      cmd_jump := 0;
    players[TGameSession.ConsolePlayer].oldjump := cmd_jump;
    // JVAL: 20211101 - Crouch
    // allowplayercrouch variable controls if we accept input for crouching
    if cmd_jump = 0 then
    begin
      if allowplayercrouch and (gamekeydown[key_crouch] or (usejoystick and joybuttons[joybcrouch])) then
      begin
        if players[TGameSession.ConsolePlayer].oldcrouch <> 0 then
          cmd_crouch := 2
        else
          cmd_crouch := 1
        end
      else
        cmd_crouch := 0;
    end
    else
      cmd_crouch := 0;
    players[TGameSession.ConsolePlayer].oldcrouch := cmd_crouch;

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

  skytexture := -1;
  skytexture2 := -1;
  if (gamemapinfo <> nil) and (gamemapinfo.skytexture <> '') then
  begin
    skytexture := R_TextureNumForName(gamemapinfo.skytexture);
    skytexture2 := R_TextureNumForName(gamemapinfo.skytexture2);
  end;
  if skytexture < 0 then
  begin
    if (TGameSession.GameMap >= 9) and (TGameSession.GameMap < 32) then
      skytexture := R_TextureNumForName('skymnt01')
    else
      skytexture := R_TextureNumForName('skymnt02');
  end;
  skytexture1 := skytexture;
  if skytexture2 < 0 then
    skytexture2 := skytexture;

  if wipegamestate = Ord(GS_LEVEL) then
    wipegamestate := -1;  // force a wipe

  gamestate := GS_LEVEL;

  for i := 0 to MAXPLAYERS - 1 do
  begin
    if playeringame[i] and ((players[i].playerstate = PST_DEAD) or (players[i].health <= 0)) then
      players[i].playerstate := PST_REBORN;
    ZeroMemory(@players[i].frags, SizeOf(players[i].frags));
  end;

  PS_NewMap;
  G_LevelLoader.SetupLevel(0, TGameSession.GameMap, 0, TGameSession.GameSkill);

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

  displayplayer := TGameSession.ConsolePlayer;    // view the guy you are playing
  starttime := I_GetTime;
  TGameSession.GameAction := ga_nothing;
  Z_CheckHeap;
  // JVAL: Extra debug check
  if debugmode then
    Z_CheckMemory;

  // clear cmd building stuff
  ZeroMemory(@gamekeydown, SizeOf(gamekeydown));
  joyxmove := 0;
  joyymove := 0;
  mousex := 0;
  mousey := 0;
  sendpause := false;
  sendsave := false;
  sendcmdsave := false;
  TGameSession.Paused := false;
  ZeroMemory(mousebuttons, SizeOf(mousebuttons));
  ZeroMemory(joybuttons, SizeOf(joybuttons));

  P_DialogLoad; // villsa [STRIFE]
end;

//==============================================================================
//
// G_Responder
// Get info needed to make ticcmd_ts for the players.
//
//==============================================================================
function G_Responder(ev: Pevent_t): boolean;
var
  i: integer;
begin
  if gamestate = GS_ENDOOM then
  begin
    result := G_EndoomScreen.Respond(ev);
    exit;
  end;
  // allow spy mode changes even during the demo
  if (gamestate = GS_LEVEL) and (ev._type = ev_keydown) and
     (ev.data1 = KEY_F12) and (singledemo or (TGameSession.GameSkill = sk_baby)) then
  begin
  // spy mode
    repeat
      inc(displayplayer);
      if displayplayer = MAXPLAYERS then
        displayplayer := 0;
    until not ((not playeringame[displayplayer]) and (displayplayer <> TGameSession.ConsolePlayer));
    result := true;
    exit;
  end;

  // any other key pops up menu if in demos
  if (TGameSession.GameAction = ga_nothing) and not singledemo and
     (TGameSession.DemoPlayback or (gamestate = GS_DEMOSCREEN)) then
  begin
    if (ev._type = ev_keydown) or
       ((ev._type = ev_mouse) and (ev.data1 <> 0)) or
       ((ev._type = ev_joystick) and (ev.data1 <> 0)) then
    begin
      if devparm and (ev.data1 = Ord('g')) then
        D_PageTicker  // [STRIFE]: wat? o_O
      else
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
    if ST_Responder(ev) then
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
  while (TGameSession.GameAction <> ga_nothing) do
  begin
    case TGameSession.GameAction of
      ga_loadlevel:
        G_DoLoadLevel;
      ga_newgame:
        G_DoNewGame;
      ga_loadgame:
        begin
          G_DoLoadGame(true);
          M_SaveMoveHereToMap;
          M_ReadMisObj;
          M_ReadWorldVars;
        end;
      ga_savegame:
        begin
          M_SaveMoveMapToHere;
          M_SaveMisObj(savepath);
          M_SaveWorldVars(savepath);
          M_SaveSaveScreenShot(savepath);
          G_DoSaveGame(savepath);
        end;
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
          TGameSession.GameAction := ga_nothing;
        end;
    end;
  end;

  // get commands, check consistancy,
  // and build new consistancy check
  buf := (TGameSession.GameTic div ticdup) mod BACKUPTICS;

  for i := 0 to MAXPLAYERS - 1 do
  begin
    if playeringame[i] then
    begin
      pl := @players[i];
      cmd := @pl.cmd;

      G_NetGame.GetCommand(i, buf, cmd);

      if TGameSession.DemoPlayback then
        G_ReadDemoTiccmd(cmd);

      if TGameSession.DemoRecording then
        G_WriteDemoTiccmd(cmd);

      // check for turbo cheats
      if (cmd.forwardmove > TURBOTHRESHOLD) and
         ((TGameSession.GameTic and 31) = 0) and
         (((_SHR(TGameSession.GameTic, 5)) and 3) = i) then
      begin
        sprintf(msg, '%s is turbo!', [player_names[i]]);
        players[TGameSession.ConsolePlayer]._message := msg;
      end;

      if TGameSession.NetGame and not TGameSession.NetDemo and (TGameSession.GameTic mod ticdup = 0) then
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
        TGameSession.GameAction := ga_savegame;
      end;
      if pl.cmd.buttons and BT_SPECIAL <> 0 then
      begin
        case pl.cmd.buttons and BT_SPECIALMASK of
          BTS_PAUSE:
            begin
              TGameSession.Paused := not TGameSession.Paused;
              if TGameSession.Paused then
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
              TGameSession.GameAction := ga_savegame;
            end;
        end;
      end;
    end;
  end;

  // do main actions
  case gamestate of
    GS_LEVEL:
      begin
        P_Ticker;
        ST_Ticker;
        AM_Ticker;
        HU_Ticker;
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
  allegiance: integer;
  cheats: integer;
begin
  p := @players[player];
  memcpy(@frags, @p.frags, SizeOf(frags));
  killcount := p.killcount;
  allegiance := p.allegiance;

  // JVAL: added option to keep cheats
  if keepcheatsinplayerreborn and not TGameSession.PreparingDemoPlayback then
  begin
    cheats := p.cheats;
    ZeroMemory(p, SizeOf(player_t));
    p.cheats := cheats;
  end
  else
    ZeroMemory(p, SizeOf(player_t));

  memcpy(@p.frags, @frags, SizeOf(players[player].frags));
  p.killcount := killcount;
  p.allegiance := allegiance;

  p.usedown := true;
  p.attackdown := true;  // don't do anything immediately
  p.inventorydown := true;
  p.playerstate := PST_LIVE;
  p.health := mobjinfo[Ord(MT_PLAYER)].spawnhealth;
  p.readyweapon := wp_fist;
  p.pendingweapon := wp_fist;
  p.weaponowned[Ord(wp_fist)] := true;
  p.cheats := CF_AUTOHEALTH;
  p.centerview := true;

  for i := 0 to Ord(NUMAMMO) - 1 do
    p.maxammo[i] := maxammo[i];

  // [STRIFE] clear inventory
  for i := 0 to NUMINVENTORY - 1 do
    p.inventory[i]._type := nummobjtypes;

  // villsa [STRIFE]: Default objective
  mission_objective := DEH_GetString('Find help');
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
  host: ISpawnSpotHost;
begin
  host := TPlayerRespawnHost.Create(@TGameSession.ConsolePlayer, @TGameSession.GameAction, @G_NeedsCompatibilityMode, nil);
  result := TSpawnSpot.Check(host, playernum, mthing.x * FRACUNIT, mthing.y * FRACUNIT, mthing.angle);
end;

//==============================================================================
//
// G_LoadPath
//
// haleyjd 20101003: [STRIFE] New function
// Sets loadpath based on the map and "savepathtemp"
//
//==============================================================================
procedure G_LoadPath(const map: integer);
var
  mapbuf: string;
begin
  mapbuf := itoa(map);

  // haleyjd: free if already set, and use M_SafeFilePath
  loadpath := M_SafeFilePath(savepathtemp, mapbuf);
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
  respawn: TPlayerRespawn;
begin
  respawn := TPlayerRespawn.Create(TPlayerRespawnHost.Create(@TGameSession.ConsolePlayer, @TGameSession.GameAction, @G_NeedsCompatibilityMode, nil));
  try
    respawn.SpawnDeathMatch(playernum);
  finally
    respawn.Free;
  end;
end;

procedure G_PrepareReload;
begin
  G_LoadPath(TGameSession.GameMap);
end;

//==============================================================================
//
// G_DoReborn
//
//==============================================================================
procedure G_DoReborn(playernum: integer);
var
  respawn: TPlayerRespawn;
begin
  respawn := TPlayerRespawn.Create(TPlayerRespawnHost.Create(@TGameSession.ConsolePlayer, @TGameSession.GameAction, @G_NeedsCompatibilityMode, @G_PrepareReload));
  try
    respawn.Respawn(playernum, TGameSession.NetGame, TGameSession.DeathMatch, MAXPLAYERS);
  finally
    respawn.Free;
  end;
end;

//==============================================================================
//
// G_ScreenShot
//
//==============================================================================
procedure G_ScreenShot;
begin
  TGameSession.GameAction := ga_screenshot;
end;

//
// G_DoCompleted
//

// haleyjd 08/24/10: [STRIFE] New variables
var
  destmap: integer;   // current destination map when exiting
  riftdest: integer;  // destination spot for player
  riftangle: angle_t; // player angle saved during exit

//==============================================================================
//
// G_RiftExitLevel
//
// haleyjd 20100824: [STRIFE] New function
// * Called from some exit linedefs to exit to a specific riftspot in the
//   given destination map.
//
//==============================================================================
procedure G_RiftExitLevel(map, spot: integer; angle: angle_t);
begin
  TGameSession.GameAction := ga_completed;

  // special handling for post-Sigil map changes
  if not isdemoversion then
    if players[0].weaponowned[Ord(wp_sigil)] then
    begin
      if map = 3 then // Front Base -> Abandoned Front Base
        map := 30
      else if map = 7 then // Castle -> New Front Base
        map := 10;
    end;

  // no rifting in deathmatch games
  if TGameSession.DeathMatch <> 0 then
    spot := 0;

  riftangle := angle;
  riftdest := spot;
  destmap := map;
end;

//==============================================================================
//
// G_ExitLevel
//
//==============================================================================
procedure G_ExitLevel(dest: integer);
begin
  if dest = 0 then
    dest := TGameSession.GameMap + 1;
  destmap := dest;
  riftdest := 0;
  TGameSession.GameAction := ga_completed;
end;

//==============================================================================
//
// G_StartFinale
//
//==============================================================================
procedure G_StartFinale;
begin
  TGameSession.GameAction := ga_victory;
end;

//==============================================================================
//
// G_DoCompleted
//
//==============================================================================
procedure G_DoCompleted;
var
  i: integer;
begin
  TGameSession.GameAction := ga_nothing;

  // deal with powerup states
  for i := 0 to MAXPLAYERS - 1 do
  begin
    if playeringame[i] then
    begin
      // [STRIFE] restore pw_allmap power from mapstate cache
      if destmap < 40 then
      begin
        if players[i].mapstate[destmap] then
          players[i].powers[Ord(pw_allmap)] := 1
        else
          players[i].powers[Ord(pw_allmap)] := 0;
      end;

      // Shadowarmor doesn't persist between maps in netgames
      if TGameSession.NetGame then
        players[i].powers[Ord(pw_invisibility)] := 0;
    end;
  end;

  stonecold := false;  // villsa [STRIFE]

  if amstate <> am_inactive then
  begin
    amstate := am_inactive;
    AM_Stop;
  end;

  // [STRIFE] HUB SAVE
  if TGameSession.DeathMatch = 0 then
    G_DoSaveGame(savepathtemp);

  TGameSession.GameAction := ga_worlddone;
  viewactive := false;

end;

//==============================================================================
//
// G_RiftPlayer
//
// haleyjd 20100824: [STRIFE] New function
// Teleports the player to the appropriate rift spot.
//
//==============================================================================
procedure G_RiftPlayer;
begin
  if riftdest <> 0 then
  begin
    P_TeleportMove(
      players[0].mo,
      riftSpots[riftdest - 1].x * FRACUNIT,
      riftSpots[riftdest - 1].y * FRACUNIT
    );
    players[0].mo.angle := riftangle;
    players[0].mo.health := players[0].health;
  end;
end;

//==============================================================================
//
// G_RiftCheat
//
// haleyjd 20100824: [STRIFE] New function
// Called from the cheat code to jump to a rift spot.
//
//==============================================================================
function G_RiftCheat(riftSpotNum: integer): boolean;
begin
  result := P_TeleportMove(players[0].mo,
                           riftSpots[riftSpotNum - 1].x * FRACUNIT,
                           riftSpots[riftSpotNum - 1].y * FRACUNIT);
end;

//==============================================================================
//
// G_DoWorldDone
//
//==============================================================================
procedure G_DoWorldDone;
var
  temp_leveltime: integer;
  temp_shadow, temp_mvis: boolean;
begin
  temp_leveltime := TTickState.LevelTime;
  temp_shadow := false;
  temp_mvis := false;

  gamestate := GS_LEVEL;
  TGameSession.GameMap := destmap;
  gamemapinfo := G_LookupMapinfo(0, TGameSession.GameMap);

  // [STRIFE] HUB LOAD
  G_LoadPath(destmap);
  if TGameSession.DeathMatch = 0 then
  begin
    // Remember Shadowarmor across hub loads
    if players[0].mo.flags and MF_SHADOW <> 0 then
      temp_shadow := true;
    if players[0].mo.flags and MF_MVIS <> 0 then
      temp_mvis := true;
  end;
  G_DoLoadGame(false);

  // [STRIFE] leveltime carries over between maps
  TTickState.LevelTime := temp_leveltime;

  if TGameSession.DeathMatch = 0 then
  begin
    // [STRIFE]: transfer saved powerups
    players[0].mo.flags := players[0].mo.flags and not (MF_SHADOW or MF_MVIS);
    if temp_shadow then
      players[0].mo.flags := players[0].mo.flags or MF_SHADOW;
    if temp_mvis then
      players[0].mo.flags := players[0].mo.flags or MF_MVIS;

    // [STRIFE] HUB SAVE
    G_RiftPlayer();
    G_DoSaveGame(savepathtemp);
    M_SaveMisObj(savepathtemp);
    M_SaveWorldVars(savepathtemp);
  end;

  TGameSession.GameAction := ga_nothing;
  viewactive := true;
end;

//==============================================================================
//
// G_ReadCurrent
//
// haleyjd 20101003: [STRIFE] New function.
// Reads the "CURRENT" file from the given path and then sets it to
// gamemap.
//
//==============================================================================
procedure G_ReadCurrent(path: string);
var
  temppath: string;
  buffer: PByteArray;
begin
  temppath := M_SafeFilePath(path, 'current');

  if G_Files.ReadFile(temppath, pointer(buffer)) <= 0 then
    TGameSession.GameAction := ga_newgame
  else
  begin
    // haleyjd 20110211: do endian-correct read
    TGameSession.GameMap := buffer[0];
    TGameSession.GameAction := ga_loadgame;
    Z_Free(buffer);
  end;

  G_LoadPath(TGameSession.GameMap);
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
  TGameSession.GameAction := ga_loadgame;
end;

const
  VERSIONSIZE = 11;

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
  versions := TSaveGameVersions.Create(VERSION);
  try
    // JVAL: check for compatible game versions here
    versions.AddCompatible('version 120', VERSION120);
    versions.AddCompatible('version 121', VERSION121);
    versions.AddCompatible('version 122', VERSION122);
    versions.AddCompatible('version 203', VERSION203);
    versions.AddCompatible('version 204', VERSION204);
    versions.AddCompatible('version 205', VERSION205);
    versions.AddCompatible('version 206', VERSION206);
    versions.AddCompatible('version 001', VERSION206, 1);
    status := versions.Resolve(header, filelength, loadedversion, hack, vsaved);
  finally
    versions.Free;
  end;

  savegameversion := loadedversion;
  savegameversionhack := hack;
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
procedure G_DoLoadGame(const userload: boolean);
var
  len: integer;
  i: integer;
  savedleveltime: integer;
begin
  TGameSession.GameAction := ga_nothing;

  if not fexists(loadpath) then
  begin
    G_DoLoadLevel;
    exit;
  end;

  savegameversion := VERSION; // Assume current version
  savegameversionhack := 0;

  len := G_Files.ReadFile(loadpath, pointer(savebuffer));
  save_p := PByteArray(NativeInt(savebuffer) + SAVESTRINGSIZE);

  if not G_ReadSaveVersion(System.PByte(save_p), len) then
  begin
    Z_Free(savebuffer);
    exit; // bad version
  end;

  save_p := PByteArray(NativeInt(save_p) + VERSIONSIZE);

  TGameSession.GameSkill := skill_t(save_p[0]);
  defaultskill := save_p[0];
  save_p := PByteArray(NativeInt(save_p) + 1);

  TGameSession.GameMap := save_p[0];
  save_p := PByteArray(NativeInt(save_p) + 1);

  gamemapinfo := G_LookupMapinfo(0, TGameSession.GameMap);

  for i := 0 to MAXPLAYERS - 1 do
  begin
    playeringame[i] := save_p[0] <> 0;
    save_p := PByteArray(NativeInt(save_p) + 1);
  end;

  // get the times
  savedleveltime := TSaveGameHeader.ReadLevelTime(System.PByte(save_p));
  save_p := PByteArray(NativeInt(save_p) + 3);

  // load a base level

  // STRIFE-TODO: ????
  if userload then
    G_InitNew(TGameSession.GameSkill, TGameSession.GameMap)
  else
    G_DoLoadLevel();

  P_World.Time.LevelTime^ := savedleveltime;

  // dearchive all the modifications
  P_UnArchivePlayers(userload);
  P_UnArchiveWorld;
  P_UnArchiveThinkers;
  P_UnArchiveSpecials;
  P_UnArchiveMapVariables;
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
// G_WriteSaveName
//
// haleyjd 20101003: [STRIFE] New function
//
// Writes the character name to the NAME file.
//
//==============================================================================
function G_WriteSaveName(slot: integer; charname: string): boolean;
var
  tmpname: string;
  buf: array[0..31] of AnsiChar;
  i: integer;
begin
  savegameslot := slot;

  // haleyjd: as above.
  savepath := M_SafeFilePath(M_SaveFileName(''), M_MakeStrifeSaveDir(savegameslot, ''));

  // haleyjd: memset full character_name for safety
  character_name := charname;

  // haleyjd: use M_SafeFilePath
  tmpname := M_SafeFilePath(savepathtemp, 'name');

  for i := 1 to length(character_name) do
  begin
    if i > 32 then
      break;
    buf[i - 1] := AnsiChar(character_name[i]);
  end;

  for i := length(character_name) to 31 do
    buf[i] := #0;

  // Write the "name" file under the directory
  result := G_Files.WriteFile(tmpname, @buf, 32);

end;

//==============================================================================
//
// G_DoSaveGame
//
//==============================================================================
procedure G_DoSaveGame(path: string);
var
  description: string;
  len: integer;
  i: integer;
  maxsize: integer;
  current_path: string;
  savegame_file: string;
  gamemapbytes: array[0..3] of byte;
  gamemapstr: string;
begin
  gamemapstr := itoa(TGameSession.GameMap);
  savegame_file := M_SafeFilePath(path, gamemapstr);

  // [STRIFE] write the "current" file, which tells which hub map
  //   the save slot is currently on.
  current_path := M_SafeFilePath(path, 'current');
  // haleyjd: endian-agnostic IO
  gamemapbytes[0] := TGameSession.GameMap;
  gamemapbytes[1] := 0;
  gamemapbytes[2] := 0;
  gamemapbytes[3] := 0;
  G_Files.WriteFile(current_path, @gamemapbytes, 4);

  description := savedescription;

  maxsize := SAVEGAMESIZE + PS_MapScriptSaveSize;
  repeat
    savebuffer := Z_Malloc2(maxsize, PU_STATIC, nil);
    if savebuffer = nil then
      maxsize := maxsize * 3 div 4;
  until savebuffer <> nil;

  save_p := savebuffer;

  // The description is stored as 8 bit text
  TSaveGameHeader.WriteDescription(System.PByte(save_p), SAVESTRINGSIZE, description, Ord(' '));

  save_p := PByteArray(NativeInt(save_p) + SAVESTRINGSIZE);

  savegameversion := VERSION;
  // The version is stored as 8 bit text
  TSaveGameHeader.WriteVersion(System.PByte(save_p), VERSION, VERSIONSIZE);
  save_p := PByteArray(NativeInt(save_p) + VERSIONSIZE);

  save_p[0] := Ord(TGameSession.GameSkill);
  save_p := PByteArray(NativeInt(save_p) + 1);

  save_p[0] := TGameSession.GameMap;
  save_p := PByteArray(NativeInt(save_p) + 1);

  for i := 0 to MAXPLAYERS - 1 do
  begin
    save_p[0] := intval(playeringame[i]);
    save_p := PByteArray(NativeInt(save_p) + 1);
  end;

  TSaveGameHeader.WriteLevelTime(System.PByte(save_p), P_World.Time.LevelTime^);
  save_p := PByteArray(NativeInt(save_p) + 3);

  len := NativeInt(save_p) - NativeInt(savebuffer);
  G_Files.WriteFile(savegame_file, savebuffer, len);
  save_p := savebuffer;

  P_ArchivePlayers;

  len := NativeInt(save_p) - NativeInt(savebuffer);
  G_Files.AppendFile(savegame_file, savebuffer, len);
  save_p := savebuffer;

  P_ArchiveWorld;

  len := NativeInt(save_p) - NativeInt(savebuffer);
  G_Files.AppendFile(savegame_file, savebuffer, len);
  save_p := savebuffer;

  P_ArchiveThinkers;

  len := NativeInt(save_p) - NativeInt(savebuffer);
  G_Files.AppendFile(savegame_file, savebuffer, len);
  save_p := savebuffer;

  P_ArchiveSpecials;

  len := NativeInt(save_p) - NativeInt(savebuffer);
  G_Files.AppendFile(savegame_file, savebuffer, len);
  save_p := savebuffer;

  P_ArchiveMapVariables;

  len := NativeInt(save_p) - NativeInt(savebuffer);
  G_Files.AppendFile(savegame_file, savebuffer, len);
  save_p := savebuffer;

  P_ArchivePSMapScript;

  len := NativeInt(save_p) - NativeInt(savebuffer);
  G_Files.AppendFile(savegame_file, savebuffer, len);
  save_p := savebuffer;

  P_ArchiveOverlay;

  save_p[0] := $1d; // consistancy marker

  len := NativeInt(save_p) - NativeInt(savebuffer) + 1;
  if len > maxsize then
    I_Error('G_DoSaveGame(): Savegame buffer overrun');
  G_Files.AppendFile(savegame_file, savebuffer, len);

  Z_Free(savebuffer);
  TGameSession.GameAction := ga_nothing;
  savedescription := '';

  // [STRIFE]: custom message logic
  if path <> savepath then
    players[TGameSession.ConsolePlayer]._message := GGSAVED;

  // draw the pattern into the back screen
{$IFNDEF OPENGL}
  R_FillBackScreen;
{$ENDIF}
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
  // as M_DoSave of the menu does, without waiting for the command of the next tic
  G_WriteSaveName(slot, description);
  M_ClearSlot;
  M_FromCurr;
  TGameSession.GameAction := ga_savegame;
end;

//==============================================================================
//
// G_CmdSaveGame
//
//==============================================================================
procedure G_CmdSaveGame(const sname: string; const description: string);
begin
  if not TGameSession.UserGame or (gamestate <> GS_LEVEL) then
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
  d_map: integer;

//==============================================================================
//
// G_DeferedInitNew
//
//==============================================================================
procedure G_DeferedInitNew(skill: skill_t; map: integer);
begin
  d_skill := skill;
  d_map := map;
  TGameSession.GameAction := ga_newgame;
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

  TMapName.FromArguments(True, parm1, parm2, epsd, map);

  if W_CheckNumForName(P_GetMapName(map)) > -1 then
  begin
    players[TGameSession.ConsolePlayer]._message := STSTR_CLEV;
    G_DeferedInitNew(TGameSession.GameSkill, map);
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
begin
  G_FinishedDemoPlayback; // JVAL: remove???
  TGameSession.ResetForNewGame;
  stonecold := false;      // villsa [STRIFE]
  G_InitNew(d_skill, d_map);
  TGameSession.GameAction := ga_nothing;
end;

//==============================================================================
//
// G_InitNew
//
// haleyjd 20100824: [STRIFE]:
// * Added riftdest initialization
// * Removed episode parameter
//
//==============================================================================
procedure G_InitNew(skill: skill_t; map: integer);
var
  i: integer;
  levelinf: Plevelinfo_t;
  LEdition: TNewGameEdition;
  LSpeedChange: TSkillSpeedChange;
begin
  if TGameSession.Paused then
  begin
    TGameSession.Paused := false;
    S_ResumeSound;
  end;

  if skill > sk_nightmare then
    skill := sk_nightmare;

  if gamemode = shareware then
    LEdition := ngeShareware
  else
    LEdition := ngeRegistered;
  TNewGameLimits.Strife(LEdition, map);

  levelinf := P_GetLevelInfo(P_GetMapName(map));
  levelinf.musname := stringtochar8('');
  levelinf.skyflat := stringtochar8('');

  R_ResetInterpolationBuffer;

  M_ClearRandom;
  PS_NewWorld;
  P_ACSInitNewGame;

  TGameSession.RespawnMonsters := TSkillSpeed.RespawnMonsters(skill = sk_nightmare, TGameSession.RespawnParm);

  // JVAL: 20210207 -> Support for fast speed mobj info field
  LSpeedChange := TSkillSpeed.Change(TGameSession.FastParm, skill = sk_nightmare, TGameSession.GameSkill = sk_nightmare);
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

  // [STRIFE] Strife skill level mobjinfo/states tweaking
  if skill = sk_baby then
  begin
    // Setting to Baby skill... make things easier.

    // Acolytes walk, attack, and feel pain slower
    for i := Ord(S_AGRD_13) to Ord(S_AGRD_23) do
      states[i].tics := originalstates[i].tics * 2;

    // Reavers attack slower
    for i := Ord(S_ROB1_10) to Ord(S_ROB1_15) do
      states[i].tics := originalstates[i].tics * 2;

    // Turrets attack slower
    for i := Ord(S_TURT_02) to Ord(S_TURT_03) do
      states[i].tics := originalstates[i].tics* 2;

    // Crusaders attack and feel pain slower
    for i := Ord(S_ROB2_09) to Ord(S_ROB2_19) do
      states[i].tics := originalstates[i].tics * 2;

    // Stalkers think, walk, and attack slower
    for i := Ord(S_SPID_03) to Ord(S_SPID_10) do
      states[i].tics := originalstates[i].tics * 2;

    // The Bishop's homing missiles are slower
    mobjinfo[Ord(MT_SEEKMISSILE)].speed := originalmobjinfo[Ord(MT_SEEKMISSILE)].speed div 2;
  end
  else
  begin
    // Setting a higher skill when previously on baby... make things normal

    // Acolytes
    for i := Ord(S_AGRD_13) to Ord(S_AGRD_23) do
      states[i].tics := originalstates[i].tics;

    // Reavers
    for i := Ord(S_ROB1_10) to Ord(S_ROB1_15) do
      states[i].tics := originalstates[i].tics;

    // Turrets
    for i := Ord(S_TURT_02) to Ord(S_TURT_03) do
      states[i].tics := originalstates[i].tics;

    // Crusaders
    for i := Ord(S_ROB2_09) to Ord(S_ROB2_19) do
      states[i].tics := originalstates[i].tics;

    // Stalkers
    for i := Ord(S_SPID_03) to Ord(S_SPID_10) do
      states[i].tics := originalstates[i].tics;

    // The Bishop's homing missiles
     mobjinfo[Ord(MT_SEEKMISSILE)].speed := originalmobjinfo[Ord(MT_SEEKMISSILE)].speed;
  end;

  if TGameSession.FastParm or (skill = sk_nightmare) then
  begin
    // BLOODBATH! Make some things super-aggressive.

    // Acolytes walk, attack, and feel pain twice as fast
    // (This makes just getting out of the first room almost impossible)
    for i := Ord(S_AGRD_13) to Ord(S_AGRD_23) do
      states[i].tics := originalstates[i].tics div 2;

    // Bishop's homing missiles get FASTER
    mobjinfo[Ord(MT_SEEKMISSILE)].speed := originalmobjinfo[Ord(MT_SEEKMISSILE)].speed * 2;
  end;

  // force players to be initialized upon first level load
  for i := 0 to MAXPLAYERS - 1 do
    players[i].playerstate := PST_REBORN;

  TGameSession.UserGame := true;  // will be set false if a demo
  TGameSession.Paused := false;
  G_FinishedDemoPlayback;
  amstate := am_inactive;
  viewactive := true;
  TGameSession.GameMap := map;
  TGameSession.GameSkill := skill;
  gamemapinfo := G_LookupMapinfo(0, TGameSession.GameMap);
  riftdest := 0; // haleyjd 08/24/10: [STRIFE] init riftdest to zero on new game

  viewactive := true;

  // [STRIFE] HUBS
  G_LoadPath(TGameSession.GameMap);

  G_DoLoadLevel;
end;

//
// DEMO PLAYBACK
//
const
  DEMOMARKER = $80;

var
  compatibility_done: boolean;

//==============================================================================
// G_SafeCompatibilityDemo
//
// Old game versions compatibility
//
//==============================================================================
procedure G_SafeCompatibilityDemo;
begin
  if compatibility_done then
    exit;

  if players[TGameSession.ConsolePlayer].playerstate = PST_DEAD then
  begin
    compatibility_done := true;
    TDemoDeathTrimmer.Trim(System.PByte(demo_p), System.PByte(demoend));
  end;
end;

var
  demoversion: byte;

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

  G_SafeCompatibilityDemo;

  LPosition := System.PByte(demo_p);
  TDemoCommandCodec.Read(LPosition, dlStrife, demoversion, false, LCommand);
  demo_p := PByteArray(LPosition);

  cmd.forwardmove := LCommand.ForwardMove;
  cmd.sidemove := LCommand.SideMove;
  cmd.angleturn := LCommand.AngleTurn;
  cmd.buttons := LCommand.Buttons;
  cmd.buttons2 := LCommand.Buttons2;
  cmd.inventory := LCommand.Inventory;
  cmd.lookupdown := LCommand.LookUpDown;
  cmd.lookleftright := LCommand.LookLeftRight;
  cmd.jump_crouch := LCommand.JumpCrouch;
  cmd.lookupdown16 := LCommand.LookUpDown16; // JVAL Smooth Look Up/Down
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
  LCommand.Buttons2 := cmd.buttons2;
  LCommand.Inventory := cmd.inventory;
  LCommand.LookUpDown := cmd.lookupdown;
  LCommand.LookLeftRight := cmd.lookleftright;
  LCommand.JumpCrouch := cmd.jump_crouch;
  LCommand.LookUpDown16 := cmd.lookupdown16; // JVAL Smooth Look Up/Down
  TDemoCommandCodec.Write(System.PByte(demo_p), dlStrife, LCommand);

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
  TGameSession.UserGame := false;
  demoname := name;
  if CharPos('.', demoname) = 0 then
    demoname := demoname + '.lmp';

  i := M_CheckParm ('-maxdemo');
  if (i <> 0) and (i < myargc - 1) then
    maxsize := atoi(myargv[i + 1]) * 1024
  else
    maxsize := SAVEGAMESIZE;

  repeat
    demobuffer := Z_Malloc2(maxsize, PU_STATIC, nil);
    if demobuffer = nil then
      maxsize := maxsize * 3 div 4;
  until demobuffer <> nil;

  demoend := @demobuffer[maxsize];

  TGameSession.DemoRecording := true;
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
  LHeader.Skill := Ord(TGameSession.GameSkill);
  LHeader.Map := TGameSession.GameMap;
  LHeader.Deathmatch := TGameSession.DeathMatch;
  LHeader.Respawn := TGameSession.RespawnParm;
  LHeader.Fast := TGameSession.FastParm;
  LHeader.NoMonsters := TGameSession.NoMonsters;
  LHeader.Compatibility := compatibilitymode;
  LHeader.SpawnRandomMonsters := spawnrandommonsters;
  LHeader.Seed := M_GetSystemRandomSeed;
  LHeader.ConsolePlayer := TGameSession.ConsolePlayer;
  for i := 0 to MAXPLAYERS - 1 do
    LHeader.PlayersInGame[i] := playeringame[i];

  LPosition := System.PByte(demo_p);
  TDemoHeaderCodec.Write(LPosition, TDemoProfiles.Strife(MAXPLAYERS), LHeader);
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
    TGameSession.GameAction := ga_playdemo;
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
      TGameSession.GameAction := ga_playdemo;
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

var
  demotickstart: pointer = nil;

//==============================================================================
//
// G_DoPlayDemo
//
//==============================================================================
procedure G_DoPlayDemo;
var
  skill: skill_t;
  i, map: integer;
  lump: integer;
  len: integer;
  oldspawnrandommonsters: boolean;
  LProfile: TDemoHeaderProfile;
  LPosition: System.PByte;
  LHeader: TDemoHeader;
  LVersion: byte;
begin
  TGameSession.GameAction := ga_nothing;
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

  LProfile := TDemoProfiles.Strife(MAXPLAYERS);
  LPosition := System.PByte(demo_p);
  if not TDemoHeaderCodec.ReadVersion(LPosition, LProfile.Magic, LVersion) then
  begin
    I_Warning('G_DoPlayDemo(): Demo is from an unsupported game version' + #13#10);
    TGameSession.GameAction := ga_nothing;
    exit;
  end;

  demo_p := PByteArray(LPosition);
  demoversion := LVersion;

  if demoversion < VERSION122 then
  begin
    I_Warning('G_DoPlayDemo(): Demo is from an unsupported game version = %d.%.*d' + #13#10,
      [demo_p[0] div 100, 2, demo_p[0] mod 100]);
    TGameSession.GameAction := ga_nothing;
    exit;
  end
  else if demoversion <> VERSION then
    I_Warning('G_DoPlayDemo(): Demo is from a partial supported game version = %d.%.*d' + #13#10,
      [demo_p[0] div 100, 2, demo_p[0] mod 100]);

  LPosition := System.PByte(demo_p);
  TDemoHeaderCodec.Read(LPosition, LProfile, false, LHeader);
  demo_p := PByteArray(LPosition);

  skill := skill_t(LHeader.Skill);
  map := LHeader.Map;
  TGameSession.DeathMatch := LHeader.Deathmatch;
  TGameSession.RespawnParm := LHeader.Respawn;
  TGameSession.FastParm := LHeader.Fast;
  TGameSession.NoMonsters := LHeader.NoMonsters;

  oldcompatibilitymode := compatibilitymode;
  compatibilitymode := LHeader.Compatibility;

  oldspawnrandommonsters := spawnrandommonsters;
  spawnrandommonsters := LHeader.SpawnRandomMonsters;
  M_SetSystemRandomSeed(LHeader.Seed);

  TGameSession.ConsolePlayer := LHeader.ConsolePlayer;

  for i := 0 to MAXPLAYERS - 1 do
    playeringame[i] := LHeader.PlayersInGame[i];

  if playeringame[1] then
  begin
    TGameSession.NetGame := true;
    TGameSession.NetDemo := true;
  end;

  TGameSession.PreparingDemoPlayback := true;
  // don't spend a lot of time in loadlevel if not singledemo
  precache := singledemo; // JVAL original code: precache := false
  G_InitNew(skill, map);
  TGameSession.PreparingDemoPlayback := false;
  spawnrandommonsters := oldspawnrandommonsters;  // Back to default
  precache := true;
  TGameSession.UserGame := false;
  TGameSession.DemoPlayback := true;
  demotickstart := demo_p;
  Info_Init(true); // JVAL: Start thinkers

  compatibility_done := false;

end;

//==============================================================================
// G_DemoProgress
//
// 19/9/2009 JVAL: For drawing demo progress
//
//==============================================================================
function G_DemoProgress: fixed_t;
begin
  result := round((NativeInt(demo_p) - NativeInt(demotickstart)) / (NativeInt(demoend) - NativeInt(demotickstart)) * FRACUNIT);
  if result > FRACUNIT then
    result := FRACUNIT
  else if result < 0 then
    result := 0;
end;

//==============================================================================
//
// G_TimeDemo
//
//==============================================================================
procedure G_TimeDemo(const name: string);
begin
  TGameSession.TimingDemo := true;
  singletics := true;

  defdemoname := name;
  TGameSession.GameAction := ga_playdemo;
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
  realtics: integer;
begin
  if TGameSession.TimingDemo then
  begin
    realtics := I_GetTime - starttime;
    // The result goes to the log and the program ends like after a single demo: with I_Error it was a
    // message box that waited for a click while the worker threads kept running (#147)
    if realtics > 0 then
      printf('G_CheckDemoStatus(): timed %d gametics in %d realtics'#13#10'(%3.2ffps)'#13#10,
        [TGameSession.GameTic, realtics, TGameSession.GameTic / realtics * TICRATE])
    else
      printf('G_CheckDemoStatus(): timed %d gametics in %d realtics'#13#10,
        [TGameSession.GameTic, realtics]);
    TGameSession.TimingDemo := false;
    singledemo := true;
  end;

  if TGameSession.DemoPlayback then
  begin
    if singledemo then
      I_Quit;

    Z_Free(demoBuffer);
    G_FinishedDemoPlayback;
    TGameSession.ResetForNewGame;
    D_AdvanceDemo;
    result := true;
    exit;
  end;

  if TGameSession.DemoRecording then
  begin
    demo_p[0] := DEMOMARKER;
    demo_p := @demo_p[1];

    G_Files.WriteFile(demoname, demobuffer, pDiff(demo_p, demobuffer, SizeOf(byte)));
    Z_Free(demobuffer);
    TGameSession.DemoRecording := false;
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
  if TGameSession.DemoPlayback then
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
    printf('E_Init: Initializing ENDSTRF screen.'#13#10);
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
  lumpname := TMapName.NumberedName(map);

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
  result := TMapName.TryParse(amap, TMapName.StrifeRules, epi, mapnum);
  if result then
  begin
    if pepi <> nil then
      pepi^ := epi;
    if pmapnum <> nil then
      pmapnum^ := mapnum;
  end;
end;

//==============================================================================
//
// TGameSession.ResetForNewGame
//
//==============================================================================
class procedure TGameSession.ResetForNewGame;
var
  i: integer;
begin
  NetDemo := false;
  NetGame := false;
  DeathMatch := 0;
  for i := 1 to MAXPLAYERS - 1 do
    playeringame[i] := false;
  RespawnParm := false;
  FastParm := false;
  NoMonsters := false;
  ConsolePlayer := 0;
end;

initialization

  TGameSession.GameSkill := sk_medium;
  forwardmove[0] := $19;
  forwardmove[1] := $32;
  sidemove[0] := $18;
  sidemove[1] := $28;
  angleturn[0] := 640;
  angleturn[1] := 1280;
  angleturn[2] := 320;

  mousebuttons := PBooleanArray(@mousearray[0]);
  joybuttons := PBooleanArray(@joyarray[0]);

  precache := true;

  KEY_WEAPONS[0] := @key_weapon0;
  KEY_WEAPONS[1] := @key_weapon1;
  KEY_WEAPONS[2] := @key_weapon2;
  KEY_WEAPONS[3] := @key_weapon3;
  KEY_WEAPONS[4] := @key_weapon4;
  KEY_WEAPONS[5] := @key_weapon5;
  KEY_WEAPONS[6] := @key_weapon6;
  KEY_WEAPONS[7] := @key_weapon7;
  KEY_WEAPONS[8] := @key_weapon8;
  KEY_WEAPONS[9] := @key_weapon9;

end.

