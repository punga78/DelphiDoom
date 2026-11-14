{******************************************************************************}
{                                                                              }
{  DelphiDoom: Radix game - the triggers and the actions of a level            }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of radix_logic.pas of Rad-X (RX_RunTriggers, RX_RunTrigger,            }
{  RX_RunActions), of the loading of RGRID, RMAPGRID, RACTION and RTRIGGER of  }
{  its P_SetupLevel, of RX_PlayerMessage (radix_player.pas), of                }
{  P_PlaneTranspoMove (p_user.pas) and of G_ExitRadixLevel (g_game.pas).       }
{                                                                              }
{  The state of the triggers and of the actions is TRadixTriggerLogic of       }
{  Libs\Radix. Rad-X ran triggers and actions from P_Ticker; here a thinker of }
{  the level does it (P_Ticker is not touched), as radix_pilot does. What      }
{  Rad-X kept in player_t for the actions is in radixlevelplayers              }
{                                                                              }
{******************************************************************************}

{$I Doom32.inc}

unit radix_logic;

interface

uses
  doomdef,
  d_player,
  m_fixed,
  tables,
  p_mobj_h,
  DelphiDoom.Radix.Intf,
  DelphiDoom.Radix.Level.Types,
  DelphiDoom.Radix.LevelLogic.Types,
  DelphiDoom.Radix.TriggerLogic,
  DelphiDoom.Radix.Messages;

type
  Pradixaction_t = PRadixLevelAction;
  Pradixtrigger_t = PRadixLevelTrigger;

  // What the actions of a level keep for each player (fields of the player_t of Rad-X)
  radixlevelplayer_t = record
    mo: Pmobj_t;                      // The body at the last tic: another one is a pilot born again
    messagetime: array[0..TRadixMessages.COUNT - 1] of integer; // leveltime of the last show
    secondaryobjective: boolean;
    planetranspo_start_x: fixed_t;    // JVAL: 20200313 - Radix (RA_PlaneTranspo)
    planetranspo_start_y: fixed_t;
    planetranspo_start_z: fixed_t;
    planetranspo_start_a: angle_t;
    planetranspo_target_x: fixed_t;
    planetranspo_target_y: fixed_t;
    planetranspo_target_z: fixed_t;
    planetranspo_target_a: angle_t;
    planetranspo_start_tics: integer;
    planetranspo_tics: integer;
  end;
  Pradixlevelplayer_t = ^radixlevelplayer_t;

var
  // The triggers and the actions of the level; nil before the first level is loaded
  radixlogic: TRadixTriggerLogic = nil;
  radixplayer: integer; // The player that activates a radix trigger
  radixlevelplayers: array[0..MAXPLAYERS - 1] of radixlevelplayer_t;
  levelhassecondaryobjective: boolean = false; // JVAL: 20200314 - Radix secondary objective
  totalradixkills: integer = 0; // JVAL: 20200429 - The enemies of the map of Radix

const
  // the places of the lumps of Radix after the lumps of a map of Doom (ML_R???? of Rad-X)
  RADIX_LUMP_RMAP = 1;
  RADIX_LUMP_RTHINGS = 2;
  RADIX_LUMP_RGRID = 3;
  RADIX_LUMP_RMAPGRID = 4;
  RADIX_LUMP_RACTION = 5;
  RADIX_LUMP_RTRIGGER = 6;

//==============================================================================
//
// RX_ConfigureLevelLogic
// Gives the unit the reader of the lumps of Radix of a level. The composition
// root calls it; without it RX_LoadLevelLogic is an I_Error
//
//==============================================================================
procedure RX_ConfigureLevelLogic(const AReader: IRadixLevelLumpReader);

//==============================================================================
//
// RX_ReadThingExtras
// The lump RTHINGS of the level whose last lump of Doom (BLOCKMAP) is
// lastdoomlump; nothing when the lump is not there or is not good
//
//==============================================================================
function RX_ReadThingExtras(const lastdoomlump: integer): TArray<TRadixDoomThingExtra>;

//==============================================================================
//
// RX_LoadLevelLogic
// Reads RGRID, RMAPGRID, RACTION and RTRIGGER and adds the thinker that runs
// them. To call after RMAP is read and the things of the map are spawned
//
//==============================================================================
procedure RX_LoadLevelLogic(const lastdoomlump: integer);

//==============================================================================
//
// RX_RunTrigger
//
//==============================================================================
procedure RX_RunTrigger(const trig_id: integer);

//==============================================================================
//
// RX_ActivateAndRunTrigger
// What a wall, a kill count or a moving surface do to a trigger
//
//==============================================================================
procedure RX_ActivateAndRunTrigger(const trig_id: integer);

//==============================================================================
//
// RX_PlayerMessage
// Shows the message of a level to a player; false when it was shown a moment ago
//
//==============================================================================
function RX_PlayerMessage(const p: Pplayer_t; const msgid: integer): boolean;

//==============================================================================
//
// RX_SoundName
// The name of SNDINFO of the sound of RADIX.DAT with that number; '' when the
// number is not a sound
//
//==============================================================================
function RX_SoundName(const radix_snd: integer): string;

//==============================================================================
//
// RX_SoundDuration
// Returns duration of sound in tics, -1 when it is not known
//
//==============================================================================
function RX_SoundDuration(const radix_snd: integer): integer;

//==============================================================================
//
// RX_ExitLevel
// G_ExitRadixLevel of Rad-X: -1 ends the episode, 0 goes to the next level,
// 9 to the secret level, another number to that level
//
//==============================================================================
procedure RX_ExitLevel(const nextlevel: integer);

implementation

uses
  SysUtils,
  d_delphi,
  d_think,
  d_event,
  d_main,
  g_game,
  i_system,
  p_tick,
  w_wad,
  z_zone,
  radix_actions,
  radix_forcefield,
  radix_grid,
  radix_map_extra,
  radix_walls,
  DelphiDoom.Radix.Types,
  DelphiDoom.Radix.SoundPart,
  DelphiDoom.Radix.Action.Rules;

type
  radixlevellogic_t = record
    thinker: thinker_t;
  end;
  Pradixlevellogic_t = ^radixlevellogic_t;

const
  SOUND_DURATION_UNKNOWN = -2;

var
  radix_levellumpreader: IRadixLevelLumpReader = nil;
  radixsoundnames: TArray<string>;
  radixsounddurations: array[0..TRadixMessages.SOUND_COUNT - 1] of integer;

//==============================================================================
//
// RX_ConfigureLevelLogic
//
//==============================================================================
procedure RX_ConfigureLevelLogic(const AReader: IRadixLevelLumpReader);
begin
  radix_levellumpreader := AReader;
end;

//==============================================================================
//
// RX_LumpBytes
// The bytes of a lump of Radix of the level; nothing when the lump at that
// place has another name
//
//==============================================================================
function RX_LumpBytes(const lumpnum: integer; const lumpname: string): TBytes;
var
  lump: integer;
begin
  result := nil;
  lump := RX_RadixLump(lumpnum, lumpname);
  if lump < 0 then
    exit;
  SetLength(result, W_LumpLength(lump));
  if Length(result) > 0 then
    W_ReadLump(lump, @result[0]);
end;

//==============================================================================
//
// RX_ReadThingExtras
//
//==============================================================================
function RX_ReadThingExtras(const lastdoomlump: integer): TArray<TRadixDoomThingExtra>;
begin
  result := nil;
  if radix_levellumpreader = nil then
    I_Error('RX_ReadThingExtras(): RX_ConfigureLevelLogic was not called');
  try
    result := radix_levellumpreader.ReadThingExtras(RX_LumpBytes(lastdoomlump + RADIX_LUMP_RTHINGS, 'RTHINGS'));
  except
    on e: ERadixException do
      I_Warning('RX_ReadThingExtras(): %s'#13#10, [e.Message]);
  end;
end;

//==============================================================================
//
// RX_RunTrigger
//
//==============================================================================
procedure RX_RunTrigger(const trig_id: integer);
begin
  if radixlogic <> nil then
    radixlogic.RunTrigger(trig_id);
end;

//==============================================================================
//
// RX_ActivateAndRunTrigger
//
//==============================================================================
procedure RX_ActivateAndRunTrigger(const trig_id: integer);
begin
  if radixlogic <> nil then
    radixlogic.ActivateAndRunTrigger(trig_id);
end;

//==============================================================================
//
// RX_PlayerMessage
//
//==============================================================================
function RX_PlayerMessage(const p: Pplayer_t; const msgid: integer): boolean;
var
  lp: Pradixlevelplayer_t;
begin
  result := false;
  if not TRadixMessages.IsMessage(msgid) then
    exit;
  lp := @radixlevelplayers[pDiff(p, @players[0], SizeOf(player_t))];
  if not TRadixActionRules.CanShowMessage(lp.messagetime[msgid], leveltime) then
    exit;
  p._message := ShortString(TRadixMessages.Get(msgid).Text);
  lp.messagetime[msgid] := leveltime;
  result := true;
end;

//==============================================================================
//
// RX_SoundName
//
//==============================================================================
function RX_SoundName(const radix_snd: integer): string;
begin
  if Length(radixsoundnames) = 0 then
    radixsoundnames := TRadixSoundPart.SoundNames;
  if (radix_snd >= 0) and (radix_snd < Length(radixsoundnames)) then
    result := TRadixMessages.SOUND_PREFIX + radixsoundnames[radix_snd]
  else
    result := '';
end;

//==============================================================================
//
// RX_SoundDuration
//
//==============================================================================
function RX_SoundDuration(const radix_snd: integer): integer;
var
  lump: integer;
  wave: TBytes;
begin
  if (radix_snd < 0) or (radix_snd >= TRadixMessages.SOUND_COUNT) then
  begin
    result := -1;
    exit;
  end;

  result := radixsounddurations[radix_snd];
  if result <> SOUND_DURATION_UNKNOWN then
    exit;

  result := -1;
  lump := W_CheckNumForName(TRadixActionRules.SoundLumpName(radix_snd));
  if lump >= 0 then
  begin
    SetLength(wave, W_LumpLength(lump));
    if Length(wave) > 0 then
    begin
      W_ReadLump(lump, @wave[0]);
      result := TRadixActionRules.WaveDurationTics(wave);
    end;
  end;
  radixsounddurations[radix_snd] := result;
end;

//==============================================================================
//
// RX_ExitLevel
// Missing: the level that the action names (the way back from the secret
// level) needs G_DoCompleted, that knows only the levels of Doom
//
//==============================================================================
procedure RX_ExitLevel(const nextlevel: integer);
var
  ex: TRadixExit;
begin
  ex := TRadixActionRules.ExitOf(nextlevel, gamemap);
  case ex.Kind of
    rekVictory:
      if gamemap = TRadixActionRules.LAST_MAP then
        G_ExitLevel // G_DoCompleted ends the episode
      else
        gameaction := ga_victory;
    rekSecretLevel:
      G_SecretExitLevel;
    rekNamedLevel:
      begin
        I_Warning('RX_ExitLevel(): The level asks for the level %d, the engine goes to its own next level'#13#10,
          [ex.Map]);
        G_ExitLevel;
      end;
  else
    G_ExitLevel;
  end;
end;

//==============================================================================
//
// RX_PlaneTranspoMove
// JVAL: 20200313 - New function (RA_PlaneTranspo action)
// The thinker runs after the code of the player: the momentum of the craft of
// this tic is the one of the transporter
//
//==============================================================================
procedure RX_PlaneTranspoMove(const p: Pplayer_t; const lp: Pradixlevelplayer_t);
var
  pmo: Pmobj_t;
begin
  dec(lp.planetranspo_tics);
  pmo := p.mo;
  if lp.planetranspo_tics <= 0 then
  begin
    pmo.momx := 0;
    pmo.momy := 0;
    pmo.momz := 0;
    pmo.angle := lp.planetranspo_target_a;
    exit;
  end;

  pmo.momx := TRadixActionRules.TranspoMomentum(lp.planetranspo_start_x, lp.planetranspo_target_x,
    lp.planetranspo_start_tics, lp.planetranspo_tics);
  pmo.momy := TRadixActionRules.TranspoMomentum(lp.planetranspo_start_y, lp.planetranspo_target_y,
    lp.planetranspo_start_tics, lp.planetranspo_tics);
  pmo.momz := TRadixActionRules.TranspoMomentum(lp.planetranspo_start_z, lp.planetranspo_target_z,
    lp.planetranspo_start_tics, lp.planetranspo_tics);
  pmo.angle := TRadixActionRules.TranspoAngle(lp.planetranspo_start_a, lp.planetranspo_target_a,
    lp.planetranspo_tics, lp.planetranspo_start_tics);
end;

//==============================================================================
// RX_RunTriggers
//
// JVAL: Handle radix triggers
// Note: No voodoo dolls
//
//==============================================================================
procedure RX_RunTriggers;
var
  i: integer;
  lp: Pradixlevelplayer_t;
begin
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] and (players[i].mo <> nil) then
    begin
      lp := @radixlevelplayers[i];
      if lp.mo <> players[i].mo then
      begin
        // a new body: what P_SpawnPlayer of Rad-X cleared
        lp.mo := players[i].mo;
        lp.planetranspo_tics := 0;
        radixlogic.ResetPlayer(i);
      end;
      radixplayer := i;
      radixlogic.PlayerCrosses(i, radixgrid, RX_PosInGrid(players[i].mo));
      if lp.planetranspo_tics > 0 then
        RX_PlaneTranspoMove(@players[i], lp);
    end;
end;

//==============================================================================
//
// RX_RunActions
//
//==============================================================================
procedure RX_RunActions;
var
  i: integer;
  cnt: integer;
begin
  cnt := radixlogic.ActionCount;
  i := radixlogic.NextRunnable(0);
  while i < cnt do
  begin
    RX_RunAction(radixlogic.Action(i));
    i := radixlogic.NextRunnable(i + 1);
  end;
end;

//==============================================================================
//
// T_RadixLevelLogic
//
//==============================================================================
procedure T_RadixLevelLogic(th: Pradixlevellogic_t);
begin
  if (radixlogic = nil) or (radixgrid = nil) then
    exit;

  RX_RunForceFields; // JVAL: 20200429 - Forcefields
  RX_TrackShots;
  RX_RunTriggers; // JVAL: 20200305 - Run radix triggers
  RX_RunActions;  // JVAL: 20200305 - Run radix actions
end;

//==============================================================================
//
// RX_MarkMissileWalls
// The walls of the actions that fire missiles can be shot (P_LoadRadixSprites)
//
//==============================================================================
procedure RX_MarkMissileWalls;
var
  walls: TArray<integer>;
  i: integer;
  ll: integer;
begin
  walls := radixlogic.MissileWalls;
  for i := 0 to Length(walls) - 1 do
  begin
    ll := walls[i];
    if not RX_ValidLine(ll) then
      continue;
    radixwallinfo[ll].Flags := radixwallinfo[ll].Flags or RWF_MISSILEWALL;
    if radixwallinfo[ll].HitPoints <= 0 then
      radixwallinfo[ll].HitPoints := RADIX_MISSILE_WALL_HIT_POINTS;
  end;
end;

//==============================================================================
//
// RX_LoadLevelLogic
//
//==============================================================================
procedure RX_LoadLevelLogic(const lastdoomlump: integer);
var
  grid: TRadixTriggerGridData;
  mappoints: TArray<TRadixLevelMapPoint>;
  actions: TArray<TRadixLevelAction>;
  triggers: TArray<TRadixLevelTrigger>;
  logic: Pradixlevellogic_t;
  i: integer;
begin
  if radix_levellumpreader = nil then
    I_Error('RX_LoadLevelLogic(): RX_ConfigureLevelLogic was not called');

  try
    grid := radix_levellumpreader.ReadGrid(RX_LumpBytes(lastdoomlump + RADIX_LUMP_RGRID, 'RGRID'));
    mappoints := radix_levellumpreader.ReadMapPoints(RX_LumpBytes(lastdoomlump + RADIX_LUMP_RMAPGRID, 'RMAPGRID'));
    actions := radix_levellumpreader.ReadActions(RX_LumpBytes(lastdoomlump + RADIX_LUMP_RACTION, 'RACTION'));
    triggers := radix_levellumpreader.ReadTriggers(RX_LumpBytes(lastdoomlump + RADIX_LUMP_RTRIGGER, 'RTRIGGER'));
  except
    on e: ERadixException do
    begin
      // a level without triggers and actions
      I_Warning('RX_LoadLevelLogic(): %s'#13#10, [e.Message]);
      grid := radix_levellumpreader.ReadGrid(nil);
      mappoints := nil;
      actions := nil;
      triggers := nil;
    end;
  end;

  RX_InitRadixGrid(grid, mappoints);
  FreeAndNil(radixlogic);
  radixlogic := TRadixTriggerLogic.Create(actions, triggers, MAXPLAYERS);

  levelhassecondaryobjective := radixlogic.HasActionOfKind(RADIX_ACTION_SECONDARY_OBJECTIVE);
  ZeroMemory(@radixlevelplayers, SizeOf(radixlevelplayers));
  radixplayer := consoleplayer;

  RX_MarkMissileWalls;
  RX_InitWalls;
  RX_InitForceFields; // JVAL: 20200429 - Initalize forcefields

  logic := Z_Malloc(SizeOf(radixlevellogic_t), PU_LEVSPEC, nil);
  P_AddThinker(@logic.thinker);
  logic.thinker._function.acp1 := @T_RadixLevelLogic;

  if devparm then
    printf('RX_LoadLevelLogic(): %d actions, %d triggers, grid %d x %d'#13#10,
      [radixlogic.ActionCount, radixlogic.TriggerCount, grid.Width, grid.Height]);
  for i := 0 to radixlogic.ActionCount - 1 do
    if (radixlogic.Action(i).ActionType < 0) or (radixlogic.Action(i).ActionType >= RADIX_ACTION_KINDS) then
      I_Warning('RX_LoadLevelLogic(): The action %d has the unknown kind %d'#13#10,
        [i, radixlogic.Action(i).ActionType]);
end;

var
  sndinit: integer;

initialization
  for sndinit := 0 to TRadixMessages.SOUND_COUNT - 1 do
    radixsounddurations[sndinit] := SOUND_DURATION_UNKNOWN;

finalization
  FreeAndNil(radixlogic);

end.
