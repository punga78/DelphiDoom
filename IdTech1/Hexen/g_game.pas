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
  d_player,
  d_ticcmd;

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
procedure G_DeferedInitNew(skill: skill_t; map: integer);

//==============================================================================
//
// G_DeferedInitNewUntranslated
//
//==============================================================================
procedure G_DeferedInitNewUntranslated(skill: skill_t; map: integer);

//==============================================================================
//
// G_CmdNewGame
//
//==============================================================================
procedure G_CmdNewGame(const parm1, parm2: string);

{ Can be called by the startup code or TMenuRoutines.M_Responder, }
{ calls P_SetupLevel or W_EnterWorld. }

//==============================================================================
//
// G_LoadGame
//
//==============================================================================
procedure G_LoadGame(slot: integer);

//==============================================================================
//
// G_DoLoadGame
//
//==============================================================================
procedure G_DoLoadGame;

{ Called by TMenuRoutines.M_Responder. }

//==============================================================================
//
// G_SaveGame
//
//==============================================================================
procedure G_SaveGame(slot: integer; description: string);

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
    /// <summary>Quit after playing a demo from the command line</summary>
    class var SingleDemo: boolean;
    /// <summary>If true, load all the graphics at the start of a level</summary>
    class var Precache: boolean;
    /// <summary>Parameters for the world map and the intermission</summary>
    class var WmInfo: wbstartstruct_t;
    /// <summary>Compatibility mode of the level in progress</summary>
    class var CompatibilityMode: boolean;
    /// <summary>The compatibility mode before a demo changed it</summary>
    class var OldCompatibilityMode: boolean;
    /// <summary>The player records</summary>
    class var Players: array[0..MAXPLAYERS - 1] of player_t;
    /// <summary>The player slots in use</summary>
    class var PlayerInGame: array[0..MAXPLAYERS - 1] of boolean;
    /// <summary>Level, intermission, finale or demo screen</summary>
    class var GameState: gamestate_t;
    /// <summary>The game state of the last frame drawn</summary>
    class var OldGameState: integer;
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
    /// <summary>Episode of the level in progress</summary>
    class var GameEpisode: integer;
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

  key_invleft,
  key_invright,
  key_useartifact: integer;

// JVAL 20191207 Key bindings for weapon change
  key_weapon0: integer = Ord('1');
  key_weapon1: integer = Ord('2');
  key_weapon2: integer = Ord('3');
  key_weapon3: integer = Ord('4');

  KEY_WEAPONS: array[0..Ord(NUMWEAPONS) - 1] of PInteger;

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



  PlayerClass: array[0..MAXPLAYERS - 1] of pclass_t;

  displayplayer: integer; // view being displayed







  viewactive: boolean;





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

//==============================================================================
//
// G_Completed
//
//==============================================================================
procedure G_Completed(map, position: integer);

var
  statcopy: pointer = nil;  // for statistics driver

var
  forwardmove: array[0..Ord(NUMCLASSES) - 1, 0..1] of integer = (
    ($1D, $3C),
    ($19, $32),
    ($16, $2E),
    ($18, $31)
  );

  sidemove: array[0..Ord(NUMCLASSES) - 1, 0..1] of integer = (
    ($1B, $3B),
    ($18, $28),
    ($15, $25),
    ($17, $27)
  );

  angleturn: array[0..2] of integer = (640, 1280, 320);

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
  LeaveMap: integer;
  LeavePosition: integer;

var
  starttime: integer;        // for comparative timing purposes

const
  SAVEGAMESIZE = $80000; // Originally $2C000

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
// G_ConfigureLevel
//
// The loading of the levels, given by the composition root: G_DoLoadLevel calls it.
// Without it the game stops with I_Error.
//
//==============================================================================
procedure G_ConfigureLevel(const ALoader: ILevelLoader);

implementation

uses
  DelphiDoom.Thinkers.PlayerRespawn.Intf,
  DelphiDoom.Thinkers.PlayerRespawn,
  DelphiDoom.Thinkers.SpawnSpot,
  DelphiDoom.Thinkers.CoopReborn,
  DelphiDoom.Engine.World.PlayerRespawnHost,
  DelphiDoom.Engine.World.CoopRebornHost,
  DelphiDoom.MapInfo.NewGameLimits,
  DelphiDoom.MapInfo.SkillSpeed,
  DelphiDoom.Input.EventScaling,
  DelphiDoom.Input.KeyboardLayout,
  c_cmds,
  z_zone,
  doomdata,
  am_map,
  d_net,
  d_net_h,
  d_main,
  f_finale,
  info_h,
  info,
  i_system,
  m_misc,
  m_menu,
  m_rnd,
  g_demo,
  a_action,
  p_mapinfo,
  p_setup,
  p_tick,
  p_local,
  p_mobj_h,
  p_mobj,
  p_inter,
  DelphiDoom.Engine.World.InterRules,
  p_map,
  p_user,
  DelphiDoom.Engine.World.UserRules,
  p_acs,
  p_levelinfo,
  ps_main,
  in_stuff,
  hu_stuff,
  sb_bar,
  w_wad,
  s_sound,
// Data.
  xn_strings,
  sounddata,
// SKY handling - still the wrong place.
  r_data,
  r_sky,
  r_defs,
  r_main,
  r_draw,
  r_intrpl,
  s_sndseq,
  sv_save,
  udmf_telept,
  tables;

var
  // given by the composition root
  g_netgame_ref: IEngineNetGame = nil;
  g_screenshot_ref: IEngineScreenshot = nil;

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

//
// G_StartNewInit
//

var
  RebornPosition: integer;

//==============================================================================
//
// G_StartNewInit
//
//==============================================================================
procedure G_StartNewInit;
begin
  SV_InitBaseSlot;
  SV_ClearRebornSlot;
  P_ACSInitNewGame;
  // Default the player start spot group to 0
  RebornPosition := 0;
end;

//
// G_StartNewGame
//
var
  TempSkill: skill_t;

//==============================================================================
//
// G_StartNewGame
//
//==============================================================================
procedure G_StartNewGame(skill: skill_t);
var
  realMap: integer;
begin
  G_StartNewInit;
  realMap := P_TranslateMap(1);
  if realMap = -1 then
    realMap := 1;
  G_InitNew(TempSkill, 1, realMap);
end;

//==============================================================================
//
// G_DoNewGame
//
//==============================================================================
procedure G_DoNewGame;
begin
  G_FinishedDemoPlayback; // JVAL: remove???
  G_StartNewGame(TempSkill);
  TGameSession.GameAction := ga_nothing;
end;

var
  TempEpisode: integer;
  TempMap: integer;

//==============================================================================
//
// G_DoInitNew
//
//==============================================================================
procedure G_DoInitNew;
begin
  SV_InitBaseSlot;
  SV_ClearRebornSlot;
  G_InitNew(TempSkill, TempEpisode, TempMap);
  TGameSession.GameAction := ga_nothing;
end;

var
  sendsave: boolean;         // send a save event next tic
  sendcmdsave: boolean;      // send a save event next tic (console)

  levelstarttic: integer;    // gametic at level start


//==============================================================================
//
// MAXPLMOVE
//
//==============================================================================
function MAXPLMOVE(pclass: integer): fixed_t;
begin
  result := forwardmove[pclass, 1];
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
  pclass: integer;
  cmd_jump, cmd_crouch: byte;
begin
  pclass := Ord(TGameSession.Players[TGameSession.ConsolePlayer]._class);

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
      side := side + sidemove[pclass, speed];
    if gamekeydown[key_left] then
      side := side - sidemove[pclass, speed];
    if joyxmove > 0 then
      side := side + sidemove[pclass, speed];
    if joyxmove < 0 then
      side := side - sidemove[pclass, speed];
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
    _forward := _forward + forwardmove[pclass, speed];

  if gamekeydown[key_down] then
    _forward := _forward - forwardmove[pclass, speed];

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
    _forward := _forward + forwardmove[pclass, speed];

  if joyymove > 0 then
    _forward := _forward - forwardmove[pclass, speed];

  if gamekeydown[key_straferight] then
    side := side + sidemove[pclass, speed];

  if gamekeydown[key_strafeleft] then
    side := side - sidemove[pclass, speed];

  // buttons
  cmd.chatchar := Ord(THudRoutines.HU_dequeueChatChar);

  if gamekeydown[key_fire] or
     (usemouse and mousebuttons[mousebfire]) or
     (usejoystick and joybuttons[joybfire]) then
    cmd.buttons := cmd.buttons or BT_ATTACK;

  if G_PlayingEngineVersion >= VERSION207 then
    if TGameSession.Players[TGameSession.ConsolePlayer].nextfire > TTickState.LevelTime then
      cmd.buttons := cmd.buttons and not BT_ATTACK;

  if gamekeydown[key_use] or (usejoystick and joybuttons[joybuse]) then
  begin
    cmd.buttons := cmd.buttons or BT_USE;
  // clear double clicks if hit use button
    dclicks := 0;
  end;

  // chainsaw overrides
  for i := 0 to Ord(NUMWEAPONS) - 1 do
    if gamekeydown[KEY_WEAPONS[i]^] then
    begin
      cmd.buttons := cmd.buttons or BT_CHANGE;
      cmd.buttons := cmd.buttons or _SHL(i, BT_WEAPONSHIFT);
      break;
    end;

  // mouse
  if (usemouse and mousebuttons[mousebforward]) then
    _forward := _forward + forwardmove[pclass, speed];

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

  if _forward > MAXPLMOVE(pclass) then
    _forward := MAXPLMOVE(pclass)
  else if _forward < -MAXPLMOVE(pclass) then
    _forward := -MAXPLMOVE(pclass);

  if side > MAXPLMOVE(pclass) then
    side := MAXPLMOVE(pclass)
  else if side < -MAXPLMOVE(pclass) then
    side := -MAXPLMOVE(pclass);

  // Adjust for a player with a speed artifact
  if (TGameSession.Players[TGameSession.ConsolePlayer].powers[Ord(pw_speed)] > 0) and
     (TGameSession.Players[TGameSession.ConsolePlayer].morphTics = 0) then
  begin
    _forward := _SHR1(3 * _forward);
    side := _SHR1(3 * side);
  end;

  cmd.forwardmove := cmd.forwardmove + _forward;
  cmd.sidemove := cmd.sidemove + side;

  if TGameSession.Players[TGameSession.ConsolePlayer].playerstate = PST_LIVE then
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
      if TGameSession.Players[TGameSession.ConsolePlayer].oldjump <> 0 then
        cmd_jump := 1
      else
        cmd_jump := 2
      end
    else
      cmd_jump := 0;
    TGameSession.Players[TGameSession.ConsolePlayer].oldjump := cmd_jump;
    // JVAL: 20211101 - Crouch
    // allowplayercrouch variable controls if we accept input for crouching
    if cmd_jump = 0 then
    begin
      if allowplayercrouch and (gamekeydown[key_crouch] or (usejoystick and joybuttons[joybcrouch])) then
      begin
        if TGameSession.Players[TGameSession.ConsolePlayer].oldcrouch <> 0 then
          cmd_crouch := 2
        else
          cmd_crouch := 1
        end
      else
        cmd_crouch := 0;
    end
    else
      cmd_crouch := 0;
    TGameSession.Players[TGameSession.ConsolePlayer].oldcrouch := cmd_crouch;

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
  cmd.arti := 0;
  if gamekeydown[key_useartifact] then
  begin
    if gamekeydown[key_speed] and not noartiskip then
    begin
      if TGameSession.Players[TGameSession.ConsolePlayer].inventory[inv_ptr]._type <> Ord(arti_none) then
      begin
        gamekeydown[key_useartifact] := false;
        cmd.arti := $ff; // skip artifact code
      end
    end
    else
    begin
      if inventory then
      begin
        TGameSession.Players[TGameSession.ConsolePlayer].readyArtifact :=
          artitype_t(TGameSession.Players[TGameSession.ConsolePlayer].inventory[inv_ptr]._type);
        inventory := false;
        cmd.arti := 0;
        usearti := false;
      end
      else if usearti then
      begin
        cmd.arti := TGameSession.Players[TGameSession.ConsolePlayer].inventory[inv_ptr]._type;
        usearti := false;
      end;
    end;
  end
  else if gamekeydown[KEY_BACKSPACE] then
  begin
    gamekeydown[KEY_BACKSPACE] := false;   // Use one of each artifact
    cmd.arti := Ord(NUMARTIFACTS);
  end
  else if gamekeydown[Ord('0')] then
  begin
    gamekeydown[Ord('0')] := false;
    cmd.arti := Ord(arti_poisonbag);
  end
  else if gamekeydown[Ord('9')] then
  begin
    gamekeydown[Ord('9')] := false;
    cmd.arti := Ord(arti_blastradius);
  end
  else if gamekeydown[Ord('8')] then
  begin
    gamekeydown[Ord('8')] := false;
    cmd.arti := Ord(arti_teleport);
  end
  else if gamekeydown[Ord('7')] then
  begin
    gamekeydown[Ord('7')] := false;
    cmd.arti := Ord(arti_teleportother);
  end
  else if gamekeydown[Ord('6')] then
  begin
    gamekeydown[Ord('6')] := false;
    cmd.arti := Ord(arti_egg);
  end
  else if gamekeydown[Ord('5')] and (TGameSession.Players[TGameSession.ConsolePlayer].powers[Ord(pw_invulnerability)] = 0) then
  begin
    gamekeydown[Ord('5')] := false;
    cmd.arti := Ord(arti_invulnerability);
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

  levelstarttic := TGameSession.GameTic;        // for time calculation

  if wipegamestate = Ord(GS_LEVEL) then
    wipegamestate := -1;  // force a wipe

  TGameSession.GameState := GS_LEVEL;

  for i := 0 to MAXPLAYERS - 1 do
  begin
    if TGameSession.PlayerInGame[i] and (TGameSession.Players[i].playerstate = PST_DEAD) then
      TGameSession.Players[i].playerstate := PST_REBORN;
    ZeroMemory(@TGameSession.Players[i].frags, SizeOf(TGameSession.Players[i].frags));
  end;

  S_StopAllSequences;
  PS_NewMap;
  G_LevelLoader.SetupLevel(0, TGameSession.GameMap, 0, TGameSession.GameSkill);

  // JVAL: Prevent erroneous demos
  for i := 0 to MAXPLAYERS - 1 do
    if TGameSession.PlayerInGame[i] then
      if TGameSession.Players[i].mo = nil then
      begin
        I_Warning('G_DoLoadLevel(): Null player actor, is player start missing?'#13#10);
        TGameSession.GameState := GS_DEMOSCREEN;
        TMainRoutines.D_StartTitle;
        exit;
      end;

  displayplayer := TGameSession.ConsolePlayer;    // view the guy you are playing
  starttime := I_GetTime;
  TGameSession.GameAction := ga_nothing;
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
  TGameSession.Paused := false;
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
  plr := @TGameSession.Players[TGameSession.ConsolePlayer];
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
  if (TGameSession.GameState = GS_LEVEL) and (ev._type = ev_keydown) and
     (ev.data1 = KEY_F12) and (TGameSession.SingleDemo or (TGameSession.DeathMatch = 0)) then
  begin
  // spy mode
    repeat
      inc(displayplayer);
      if displayplayer = MAXPLAYERS then
        displayplayer := 0;
    until not ((not TGameSession.PlayerInGame[displayplayer]) and (displayplayer <> TGameSession.ConsolePlayer));
    result := true;
    exit;
  end;

  // any other key pops up menu if in demos
  if (TGameSession.GameAction = ga_nothing) and not TGameSession.SingleDemo and
     (TGameSession.DemoPlayback or (TGameSession.GameState = GS_DEMOSCREEN)) then
  begin
    if (ev._type = ev_keydown) or
       ((ev._type = ev_mouse) and (ev.data1 <> 0)) or
       ((ev._type = ev_joystick) and (ev.data1 <> 0)) then
    begin
      TMenuRoutines.M_StartControlPanel;
      result := true;
      exit;
    end;
    result := false;
    exit;
  end;

  if TGameSession.GameState = GS_LEVEL then
  begin
    if THudRoutines.HU_Responder(ev) then
    begin
      result := true; // chat ate the event
      exit;
    end;
    if TStatusBarRoutines.SB_Responder(ev) then
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

  if TGameSession.GameState = GS_FINALE then
  begin
    if TFinaleRoutines.F_Responder(ev) then
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

//
// PLAYER STRUCTURE FUNCTIONS
// also see P_SpawnPlayer in P_Things
//

//==============================================================================
//
// G_PlayerExitMap
//
// Called when the player leaves a map.
//
//==============================================================================
procedure G_PlayerExitMap(playerNumber: integer);
var
  i: integer;
  player: Pplayer_t;
  flightPower: integer;
begin
  player := @TGameSession.Players[playerNumber];

  // Strip all current powers (retain flight)
  flightPower := player.powers[Ord(pw_flight)];
  memset(@player.powers, 0, SizeOf(player.powers));
  player.powers[Ord(pw_flight)] := flightPower;

  if TGameSession.DeathMatch <> 0 then
  begin
    player.powers[Ord(pw_flight)] := 0;
  end
  else
  begin
    if P_GetMapCluster(TGameSession.GameMap) <> P_GetMapCluster(LeaveMap) then
    begin // Entering new cluster
      // Strip all keys
      player.keys := 0;

      // Strip flight artifact
      for i := 0 to p_maxartifacts - 1 do
      begin
        player.powers[Ord(pw_flight)] := 0;
        TUserRoutines.P_PlayerUseArtifact(player, arti_fly);
      end;
      player.powers[Ord(pw_flight)] := 0;
    end;
  end;

  if player.morphTics <> 0 then
  begin
    player.readyweapon := weapontype_t(player.mo.special1); // Restore weapon
    player.morphTics := 0;
  end;
  player.messageTics := 0;
  player.lookdir := 0;
  player.mo.flags := player.mo.flags and not MF_SHADOW; // Remove invisibility
  player.extralight := 0; // Remove weapon flashes
  player.fixedcolormap := 0; // Remove torch
  player.damagecount := 0; // No palette changes
  player.bonuscount := 0;
  player.poisoncount := 0;
  if player = @TGameSession.Players[TGameSession.ConsolePlayer] then
  begin
    viewangleoffset := 0;
  end;
end;

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
  if TKeyboardLayouts.TryGet(klHexen, mode, layout) then
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
  frags: array[0..MAXPLAYERS - 1] of integer;
  killcount: integer;
  itemcount: integer;
  secretcount: integer;
  worldTimer: integer;
  cheats: integer;
begin
  p := @TGameSession.Players[player];
  memcpy(@frags, @p.frags, SizeOf(frags));
  killcount := p.killcount;
  itemcount := p.itemcount;
  secretcount := p.secretcount;
  worldTimer := p.worldTimer;

  // JVAL: added option to keep cheats
  if keepcheatsinplayerreborn and not TGameSession.PreparingDemoPlayback then
  begin
    cheats := p.cheats;
    ZeroMemory(p, SizeOf(player_t));
    p.cheats := cheats;
  end
  else
    ZeroMemory(p, SizeOf(player_t));

  memcpy(@p.frags, @frags, SizeOf(TGameSession.Players[player].frags));
  p.killcount := killcount;
  p.itemcount := itemcount;
  p.secretcount := secretcount;
  p.worldTimer := worldTimer;
  p._class := PlayerClass[player];

  p.usedown := true;
  p.attackdown := true;  // don't do anything immediately
  p.playerstate := PST_LIVE;

  case p._class of
    PCLASS_FIGHTER: p.health := mobjinfo[Ord(MT_PLAYER_FIGHTER)].spawnhealth;
    PCLASS_CLERIC: p.health := mobjinfo[Ord(MT_PLAYER_CLERIC)].spawnhealth;
    PCLASS_MAGE: p.health := mobjinfo[Ord(MT_PLAYER_MAGE)].spawnhealth;
  else
    p.health := p_maxmorphhealth;
  end;

  // Initial weapons
  p.readyweapon := WP_FIRST;
  p.pendingweapon := WP_FIRST;
  p.weaponowned[Ord(WP_FIRST)] := true;

  localQuakeHappening[player] := 0;

  if player = TGameSession.ConsolePlayer then
  begin
    inv_ptr := 0; // reset the inventory pointer
    curpos := 0;
    viewangleoffset := 0;
  end;

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
  respawn := TPlayerRespawn.Create(TPlayerRespawnHost.Create(@TGameSession.ConsolePlayer));
  try
    respawn.SpawnDeathMatch(playernum);
  finally
    respawn.Free;
  end;
end;

//==============================================================================
//
// G_DoReborn
//
//==============================================================================
procedure G_DoReborn(playernum: integer);
var
  reborn: TCoopReborn;
begin
  if G_CheckDemoStatus then
    exit;

  reborn := TCoopReborn.Create(TCoopRebornHost.Create(@RebornPosition, @TGameSession.ConsolePlayer));
  try
    reborn.Respawn(playernum, TGameSession.NetGame, TGameSession.DeathMatch, MAXPLAYERS);
  finally
    reborn.Free;
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

//==============================================================================
//
// G_DoTeleportNewMap
//
//==============================================================================
procedure G_DoTeleportNewMap;
begin
  SV_MapTeleport(LeaveMap, LeavePosition);
  TGameSession.GameState := GS_LEVEL;
  TGameSession.GameAction := ga_nothing;
  RebornPosition := LeavePosition;
end;

//==============================================================================
//
// G_Completed
//
// Starts intermission routine, which is used only during hub exits,
// and DeathMatch games.
//
//==============================================================================
procedure G_Completed(map, position: integer);
begin
  TGameSession.GameAction := ga_completed;
  LeaveMap := map;
  LeavePosition := position;
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
  if G_CheckDemoStatus then
    exit;

  for i := 0 to MAXPLAYERS - 1 do
    if TGameSession.PlayerInGame[i] then
      G_PlayerExitMap(i);

  if amstate <> am_inactive then
  begin
    amstate := am_inactive;
    AM_Stop;
  end;

  if (LeaveMap = -1) and (LeavePosition = -1) then
    TGameSession.GameAction := ga_victory
  else
  begin
    TGameSession.GameState := GS_INTERMISSION;
    TIntermissionRoutines.IN_Start;
  end;
end;

//==============================================================================
//
// G_DoWorldDone
//
//==============================================================================
procedure G_DoWorldDone;
begin
  TGameSession.GameState := GS_LEVEL;
  G_DoLoadLevel;
  TGameSession.GameAction := ga_nothing;
  viewactive := true;
end;

//==============================================================================
//
// G_DoSingleReborn
//
// Called by G_Ticker based on gameaction.  Loads a game from the reborn
// save slot.
//
//==============================================================================
procedure G_DoSingleReborn;
begin
  TGameSession.GameAction := ga_nothing;
  SV_LoadGame(SV_GetRebornSlot);
  TStatusBarRoutines.SB_SetClassData;
end;

//
// G_LoadGame
//
// Can be called by the startup code or the menu task.
//

var
  GameLoadSlot: integer;

//==============================================================================
//
// G_LoadGame
//
//==============================================================================
procedure G_LoadGame(slot: integer);
begin
  GameLoadSlot := slot;
  TGameSession.GameAction := ga_loadgame;
end;

//==============================================================================
//
// G_DoLoadGame
//
// Called by G_Ticker based on gameaction.
//
//==============================================================================
procedure G_DoLoadGame;
begin
  TGameSession.GameAction := ga_nothing;
  SV_LoadGame(GameLoadSlot);
  if not TGameSession.NetGame then
  begin // Copy the base slot to the reborn slot
    SV_UpdateRebornSlot;
  end;
  TStatusBarRoutines.SB_SetClassData;
  P_LevelInfoChangeMusic;
  borderneedsrefresh := true;
end;

//==============================================================================
//
// G_SaveGame
//
// Called by the menu task.  <description> is a 24 byte text string.
//
//==============================================================================
procedure G_SaveGame(slot: integer; description: string);
begin
  savegameslot := slot;
  savedescription := description;
  sendsave := true;
end;

//==============================================================================
//
// G_DoSaveGame
//
// Called by G_Ticker based on gameaction.
//
//==============================================================================
procedure G_DoSaveGame;
begin
  SV_SaveGame(savegameslot, savedescription);
  TGameSession.GameAction := ga_nothing;
  savedescription := '';
  TInterRoutines.P_SetMessage(@TGameSession.Players[TGameSession.ConsolePlayer], GGSAVED, true);
  borderneedsrefresh := true;
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
  TGameSession.GameAction := ga_savegame;
end;

//==============================================================================
//
// G_CmdSaveGame
//
//==============================================================================
procedure G_CmdSaveGame(const sname: string; const description: string);
var
  slot: integer;
begin
  if not TGameSession.UserGame or (TGameSession.GameState <> GS_LEVEL) then
  begin
    printf('You can''t save if you aren''t playing!'#13#10);
    exit;
  end;

  slot := atoi(sname, -1);

  if (slot < 0) or (slot >= Ord(load_end)) then
  begin
    printf('Invalid savegame slot (%s)'#13#10, [sname]);
    exit;
  end;

  G_SaveGame(slot, description);
end;

//==============================================================================
// G_DeferedInitNew
//
// G_InitNew
// Can be called by the startup code or the menu task,
// consoleplayer, displayplayer, playeringame[] should be set.
//
//==============================================================================
procedure G_DeferedInitNew(skill: skill_t; map: integer);
begin
  TempSkill := skill;
  TempEpisode := 1;
  TempMap := P_TranslateMap(map);
  TGameSession.GameAction := ga_initnew;
end;

//==============================================================================
//
// G_DeferedInitNewUntranslated
//
//==============================================================================
procedure G_DeferedInitNewUntranslated(skill: skill_t; map: integer);
begin
  TempSkill := skill;
  TempEpisode := 1;
  TempMap := map;
  TGameSession.GameAction := ga_initnew;
end;

//==============================================================================
//
// G_CmdNewGame
//
//==============================================================================
procedure G_CmdNewGame(const parm1, parm2: string);
var
  map: integer;
  mapname: string;
begin
  if (parm1 = '') or (parm2 <> '') then
  begin
    printf('Please specify the level to play'#13#10);
    exit;
  end;

  map := atoi(parm1, -1);
  if TWadRoutines.W_CheckNumForName(P_GetMapName(map)) < 0 then
  begin
    mapname := strupper(parm1);

    if length(mapname) = 5 then
      if (mapname[1] = 'M') then
        if (mapname[2] = 'A') then
          if (mapname[3] = 'P') then
            map := atoi(mapname[4] + mapname[5], -1);
  end;

  if TWadRoutines.W_CheckNumForName(P_GetMapName(map)) > -1 then
  begin
    TGameSession.Players[TGameSession.ConsolePlayer]._message := STSTR_CLEV;
    G_DeferedInitNewUntranslated(TGameSession.GameSkill, map);
    C_ExecuteCmd('closeconsole', '1');
  end
  else
    I_Warning('G_CmdNewGame(): Can not load map: %s.'#13#10, [parm1]);
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
  LSpeedChange: TSkillSpeedChange;
begin
  if TGameSession.Paused then
  begin
    TGameSession.Paused := false;
    TSoundRoutines.S_ResumeSound;
  end;

  if skill < sk_baby then
    skill := sk_baby
  else if skill > sk_nightmare then
    skill := sk_nightmare;

  TNewGameLimits.Hexen(map);

  levelinf := P_GetLevelInfo(P_GetMapName(map));
  levelinf.musname := TWadRoutines.stringtochar8('');
  levelinf.skyflat := TWadRoutines.stringtochar8('');

  TRendererInterpolation.R_ResetInterpolationBuffer;

  M_ClearRandom;
  PS_NewWorld;

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

  // force players to be initialized upon first level load
  for i := 0 to MAXPLAYERS - 1 do
  begin
    TGameSession.Players[i].playerstate := PST_REBORN;
    TGameSession.Players[i].worldTimer := 0;
  end;

  TGameSession.UserGame := true;  // will be set false if a demo
  TGameSession.Paused := false;
  G_FinishedDemoPlayback;
  amstate := am_inactive;
  viewactive := true;
  TGameSession.GameEpisode := episode;
  TGameSession.GameMap := map;
  TGameSession.GameSkill := skill;

  viewactive := true;

  // Initialize the sky
  TRendererSky.R_InitSky(map);

  G_DoLoadLevel;
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
  pl: Pplayer_t;
begin
  // do player reborns if needed
  for i := 0 to MAXPLAYERS - 1 do
    if TGameSession.PlayerInGame[i] and (TGameSession.Players[i].playerstate = PST_REBORN) then
      G_DoReborn(i);

  // do things to change the game state
  while (TGameSession.GameAction <> ga_nothing) do
  begin
    case TGameSession.GameAction of
      ga_loadlevel:
        G_DoLoadLevel;
      ga_initnew:
        G_DoInitNew;
      ga_newgame:
        G_DoNewGame;
      ga_loadgame:
        begin
          TMenuRoutines.M_DrawLoadIcon;
          G_DoLoadGame;
        end;
      ga_savegame:
        begin
          TMenuRoutines.M_DrawSaveIcon;
          G_DoSaveGame;
        end;
      ga_singlereborn:
        G_DoSingleReborn;
      ga_playdemo:
        G_DoPlayDemo;
      ga_completed:
        G_DoCompleted;
      ga_victory:
        TFinaleRoutines.F_StartFinale;
      ga_worlddone:
        G_DoWorldDone;
      ga_screenshot:
        begin
          G_Screenshots.Take;
          TGameSession.GameAction := ga_nothing;
        end;
      ga_leavemap:
        begin
          G_DoTeleportNewMap;
        end;
    end;
  end;

  // get commands, check consistancy,
  // and build new consistancy check
  buf := (TGameSession.GameTic div ticdup) mod BACKUPTICS;

  for i := 0 to MAXPLAYERS - 1 do
  begin
    if TGameSession.PlayerInGame[i] then
    begin
      pl := @TGameSession.Players[i];
      cmd := @pl.cmd;

      G_NetGame.GetCommand(i, buf, cmd);

      if TGameSession.DemoPlayback then
        G_ReadDemoTiccmd(cmd);
      if TGameSession.DemoRecording then
        G_WriteDemoTiccmd(cmd);

      if TGameSession.NetGame and not TGameSession.NetDemo and ((TGameSession.GameTic mod ticdup) = 0) then
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
    if TGameSession.PlayerInGame[i] then
    begin
      pl := @TGameSession.Players[i];
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
                TSoundRoutines.S_PauseSound
              else
                TSoundRoutines.S_ResumeSound;
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

      // turn inventory off after a certain amount of time
      if inventory then
      begin
        if inventoryTics = 0 then
        begin
          TGameSession.Players[TGameSession.ConsolePlayer].readyArtifact := artitype_t(TGameSession.Players[TGameSession.ConsolePlayer].inventory[inv_ptr]._type);
          inventory := false;
          pl.cmd.arti := 0;
        end;
        dec(inventoryTics);
      end;
    end;

  end;

  // do main actions
  case TGameSession.GameState of
    GS_LEVEL:
      begin
        TTickRoutines.P_Ticker;
        TStatusBarRoutines.SB_Ticker;
        AM_Ticker;
        THudRoutines.HU_Ticker;
      end;
    GS_INTERMISSION:
      begin
        TIntermissionRoutines.IN_Ticker;
      end;
    GS_FINALE:
      begin
        TFinaleRoutines.F_Ticker;
      end;
    GS_DEMOSCREEN:
      begin
        TMainRoutines.D_PageTicker;
      end;
  end;
end;

//==============================================================================
//
// G_NeedsCompatibilityMode
//
//==============================================================================
function G_NeedsCompatibilityMode: boolean;
begin
  result := TGameSession.CompatibilityMode;
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
    TGameSession.PlayerInGame[i] := false;
  RespawnParm := false;
  FastParm := false;
  NoMonsters := false;
  ConsolePlayer := 0;
end;

initialization

  TGameSession.Precache := true;
  TGameSession.OldGameState := -1;
  mousebuttons := PBooleanArray(@mousearray[0]);
  joybuttons := PBooleanArray(@joyarray[0]);

  KEY_WEAPONS[0] := @key_weapon0;
  KEY_WEAPONS[1] := @key_weapon1;
  KEY_WEAPONS[2] := @key_weapon2;
  KEY_WEAPONS[3] := @key_weapon3;

end.

