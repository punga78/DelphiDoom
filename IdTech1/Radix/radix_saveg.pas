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
//  Radix: the state of Radix in the saved games (the part of p_saveg that Rad-X
//  changed). The saved game of the engine is the one of Doom, untouched: what
//  Radix keeps beside player_t, line_t and the thinkers of Doom (the craft of
//  each pilot, the triggers and the actions of the level, the walls that can
//  be shot, the shots in flight) goes in a file beside it, with the name of
//  the saved game and ".radix" after it (TRadixSaveGameCodec).
//  A saved game without that file (one of before, or the file was deleted) is
//  loaded as the level it is of, with the state of Radix of a level that starts.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit radix_saveg;

interface

uses
  DelphiDoom.MathCore.Intf;

const
  RADIXSAVEEXTENSION = '.radix';

//==============================================================================
//
// RX_ConfigureSaveGame
// The random numbers of the game, given by the composition root: where they
// are goes in the file and comes back from it. Without it saving and loading
// are an I_Error
//
//==============================================================================
procedure RX_ConfigureSaveGame(const ARandom: IGameRandom);

//==============================================================================
//
// RX_SaveGame
// The extension of G_DoSaveGameInFile (G_ConfigureSaveGameExtension): writes
// the state of Radix beside the saved game that the engine has just written
//
//==============================================================================
procedure RX_SaveGame(const filename: string);

//==============================================================================
//
// RX_LoadGame
// The extension of G_DoLoadGame: the engine has loaded the level again and read
// its saved game. Puts back the two thinkers of Radix (the engine frees the
// thinkers it does not know) and the state of the file beside the saved game
//
//==============================================================================
procedure RX_LoadGame(const filename: string);

//==============================================================================
//
// RX_ScriptSaveGame, RX_ScriptLoadGame
// The steps "save" and "load" of a script of commands (-autoscript): the
// routines of the menus of the engine for the saved game of a slot
//
//==============================================================================
procedure RX_ScriptSaveGame(slot: integer);

procedure RX_ScriptLoadGame(slot: integer);

implementation

uses
  SysUtils,
  Classes,
  doomdef,
  d_player,
  g_game,
  i_system,
  radix_playerstate,
  radix_pilot,
  radix_briefing,
  radix_logic,
  radix_map_extra,
  radix_walls,
  radix_statelog,
  DelphiDoom.Radix.Types,
  DelphiDoom.Radix.SaveGame.Types,
  DelphiDoom.Radix.SaveGame.Codec,
  DelphiDoom.Radix.Messages;

// the arrays of the records of the file are as long as the ones of the game
{$IF (NUMRADIXWEAPONS <> RADIX_SAVE_WEAPONS) or (Ord(NUMRADIXPOWERUPS) <> RADIX_SAVE_POWERUPS)}
  {$MESSAGE ERROR 'radix_saveg: the weapons or the power ups of the saved game are not the ones of the game'}
{$IFEND}
{$IF TRadixMessages.COUNT <> RADIX_SAVE_MESSAGES}
  {$MESSAGE ERROR 'radix_saveg: the messages of the saved game are not the ones of the game'}
{$IFEND}

var
  radix_random: IGameRandom = nil;

//==============================================================================
//
// RX_ConfigureSaveGame
//
//==============================================================================
procedure RX_ConfigureSaveGame(const ARandom: IGameRandom);
begin
  radix_random := ARandom;
end;

//==============================================================================
//
// RX_Random
//
//==============================================================================
function RX_Random: IGameRandom;
begin
  if radix_random = nil then
    I_Error('RX_ConfigureSaveGame() was not called: the random numbers are missing');
  result := radix_random;
end;

//==============================================================================
//
// RX_ResetCrafts
// Without the state of a saved game the crafts are the ones of a level that starts
//
//==============================================================================
procedure RX_ResetCrafts;
var
  i: integer;
begin
  for i := 0 to MAXPLAYERS - 1 do
    RX_ResetPlayerState(@players[i]);
end;

//==============================================================================
//
// RX_CollectState
//
//==============================================================================
function RX_CollectState: TRadixSaveState;
var
  i, j: integer;
  rp: Pradixplayer_t;
  lp: Pradixlevelplayer_t;
begin
  result := Default(TRadixSaveState);
  result.Episode := gameepisode;
  result.Map := gamemap;
  result.NamedLevel := radixnamedlevel;
  result.RandomIndexes[0] := RX_Random.MenuIndex;
  result.RandomIndexes[1] := RX_Random.PlayIndex;
  result.RandomIndexes[2] := RX_Random.NonCompatibleIndex;
  result.RandomIndexes[3] := RX_Random.SystemIndex;

  SetLength(result.Players, MAXPLAYERS);
  SetLength(result.LevelPlayers, MAXPLAYERS);
  for i := 0 to MAXPLAYERS - 1 do
  begin
    rp := @radixplayers[i];
    result.Players[i].Energy := rp.energy;
    result.Players[i].EnergyReserve := rp.energy_reserve;
    result.Players[i].Threat := Ord(rp.threat);
    result.Players[i].ScannerJam := Ord(rp.scannerjam);
    result.Players[i].PlasmaBombDown := Ord(rp.plasmabombdown);
    result.Players[i].Afterburner := Ord(rp.afterburner);
    result.Players[i].PlasmaEnergyCountdown := rp.plasmaenergycountdown;
    result.Players[i].EnergyWeaponFireTics := rp.energyweaponfiretics;
    result.Players[i].ThrustMomZ := rp.thrustmomz;
    for j := 0 to RADIX_SAVE_POWERUPS - 1 do
      result.Players[i].Powers[j] := rp.radixpowers[j];
    result.Players[i].PlasmaBombs := rp.plasmabombs;
    result.Players[i].NeutronCannonLevel := rp.neutroncannonlevel;
    result.Players[i].NeutronSpreaderLevel := rp.neutronspreaderlevel;
    result.Players[i].WeaponFlags := rp.weaponflags;
    result.Players[i].LastBonusTime := rp.lastbonustime;
    result.Players[i].GravityWave := rp.gravitywave;
    result.Players[i].CrossTic := rp.pcrosstic;
    for j := 0 to RADIX_SAVE_WEAPONS - 1 do
      result.Players[i].LastFire[j] := rp.lastfire[j];
    result.Players[i].PlasmaBombCount := rp.plasmabombcount;
    result.Players[i].FloorSlideTics := rp.floorslidetics;

    lp := @radixlevelplayers[i];
    result.LevelPlayers[i].HasBody := Ord(lp.mo <> nil);
    result.LevelPlayers[i].SecondaryObjective := Ord(lp.secondaryobjective);
    // the seconds of the hits against the walls (the debriefing counts seconds) in the spare word
    if radixwallhits[i] div TICRATE > High(Word) then
      result.LevelPlayers[i].Reserved := High(Word)
    else if radixwallhits[i] > 0 then
      result.LevelPlayers[i].Reserved := radixwallhits[i] div TICRATE;
    for j := 0 to RADIX_SAVE_MESSAGES - 1 do
      result.LevelPlayers[i].MessageTime[j] := lp.messagetime[j];
    result.LevelPlayers[i].TranspoStartX := lp.planetranspo_start_x;
    result.LevelPlayers[i].TranspoStartY := lp.planetranspo_start_y;
    result.LevelPlayers[i].TranspoStartZ := lp.planetranspo_start_z;
    result.LevelPlayers[i].TranspoStartAngle := lp.planetranspo_start_a;
    result.LevelPlayers[i].TranspoTargetX := lp.planetranspo_target_x;
    result.LevelPlayers[i].TranspoTargetY := lp.planetranspo_target_y;
    result.LevelPlayers[i].TranspoTargetZ := lp.planetranspo_target_z;
    result.LevelPlayers[i].TranspoTargetAngle := lp.planetranspo_target_a;
    result.LevelPlayers[i].TranspoStartTics := lp.planetranspo_start_tics;
    result.LevelPlayers[i].TranspoTics := lp.planetranspo_tics;
  end;

  if radixlogic <> nil then
    radixlogic.CopyState(result.Actions, result.Triggers, result.LastTriggers);
  // a level without logic still has a last trigger for each player in the file
  if Length(result.LastTriggers) <> MAXPLAYERS then
    SetLength(result.LastTriggers, MAXPLAYERS);

  SetLength(result.Walls, Length(radixwallinfo));
  for i := 0 to Length(radixwallinfo) - 1 do
  begin
    result.Walls[i].Flags := radixwallinfo[i].Flags;
    result.Walls[i].HitPoints := radixwallinfo[i].HitPoints;
    result.Walls[i].Trigger := radixwallinfo[i].Trigger;
  end;

  // the shots that were in flight are no more kept (the walls are damaged where a missile
  // explodes); the field stays in the file so that a saved game of before still loads
  result.Shots := nil;
end;

//==============================================================================
//
// RX_ApplyState
// Raises ERadixException for the state of another level; nothing is changed then
//
//==============================================================================
procedure RX_ApplyState(const state: TRadixSaveState);
var
  i, j: integer;
  rp: Pradixplayer_t;
  lp: Pradixlevelplayer_t;
begin
  if (state.Episode <> gameepisode) or (state.Map <> gamemap) then
    raise ERadixException.CreateFmt('the state is of the level %d of the episode %d, the saved game of %d of %d',
      [state.Map, state.Episode, gamemap, gameepisode]);
  if (Length(state.Players) <> MAXPLAYERS) or (Length(state.Walls) <> Length(radixwallinfo)) then
    raise ERadixException.CreateFmt('the state has %d players and %d walls, the level %d and %d',
      [Length(state.Players), Length(state.Walls), MAXPLAYERS, Length(radixwallinfo)]);

  // the only part that can refuse comes first
  if radixlogic <> nil then
    radixlogic.RestoreState(state.Actions, state.Triggers, state.LastTriggers)
  else if (Length(state.Actions) <> 0) or (Length(state.Triggers) <> 0) then
    raise ERadixException.Create('the state has actions and triggers, the level has none');

  radixnamedlevel := state.NamedLevel;
  // the game goes on with the numbers it would have drawn
  RX_Random.MenuIndex := state.RandomIndexes[0];
  RX_Random.PlayIndex := state.RandomIndexes[1];
  RX_Random.NonCompatibleIndex := state.RandomIndexes[2];
  RX_Random.SystemIndex := state.RandomIndexes[3];
  for i := 0 to MAXPLAYERS - 1 do
  begin
    rp := @radixplayers[i];
    rp.energy := state.Players[i].Energy;
    rp.energy_reserve := state.Players[i].EnergyReserve;
    rp.threat := state.Players[i].Threat <> 0;
    rp.scannerjam := state.Players[i].ScannerJam <> 0;
    rp.plasmabombdown := state.Players[i].PlasmaBombDown <> 0;
    rp.afterburner := state.Players[i].Afterburner <> 0;
    rp.plasmaenergycountdown := state.Players[i].PlasmaEnergyCountdown;
    rp.energyweaponfiretics := state.Players[i].EnergyWeaponFireTics;
    rp.thrustmomz := state.Players[i].ThrustMomZ;
    for j := 0 to RADIX_SAVE_POWERUPS - 1 do
      rp.radixpowers[j] := state.Players[i].Powers[j];
    rp.plasmabombs := state.Players[i].PlasmaBombs;
    rp.neutroncannonlevel := state.Players[i].NeutronCannonLevel;
    rp.neutronspreaderlevel := state.Players[i].NeutronSpreaderLevel;
    rp.weaponflags := state.Players[i].WeaponFlags;
    rp.lastbonustime := state.Players[i].LastBonusTime;
    rp.gravitywave := state.Players[i].GravityWave;
    // the target of the crosshair is found again at the next tic
    rp.plinetarget := nil;
    rp.pcrosstic := state.Players[i].CrossTic;
    for j := 0 to RADIX_SAVE_WEAPONS - 1 do
      rp.lastfire[j] := state.Players[i].LastFire[j];
    rp.plasmabombcount := state.Players[i].PlasmaBombCount;
    rp.floorslidetics := state.Players[i].FloorSlideTics;

    lp := @radixlevelplayers[i];
    // the body that the engine has just loaded: with another one the logic would take the
    // pilot for one that is born again and forget its last trigger
    if (state.LevelPlayers[i].HasBody <> 0) and playeringame[i] then
      lp.mo := players[i].mo
    else
      lp.mo := nil;
    lp.secondaryobjective := state.LevelPlayers[i].SecondaryObjective <> 0;
    radixwallhits[i] := state.LevelPlayers[i].Reserved * TICRATE;
    for j := 0 to RADIX_SAVE_MESSAGES - 1 do
      lp.messagetime[j] := state.LevelPlayers[i].MessageTime[j];
    lp.planetranspo_start_x := state.LevelPlayers[i].TranspoStartX;
    lp.planetranspo_start_y := state.LevelPlayers[i].TranspoStartY;
    lp.planetranspo_start_z := state.LevelPlayers[i].TranspoStartZ;
    lp.planetranspo_start_a := state.LevelPlayers[i].TranspoStartAngle;
    lp.planetranspo_target_x := state.LevelPlayers[i].TranspoTargetX;
    lp.planetranspo_target_y := state.LevelPlayers[i].TranspoTargetY;
    lp.planetranspo_target_z := state.LevelPlayers[i].TranspoTargetZ;
    lp.planetranspo_target_a := state.LevelPlayers[i].TranspoTargetAngle;
    lp.planetranspo_start_tics := state.LevelPlayers[i].TranspoStartTics;
    lp.planetranspo_tics := state.LevelPlayers[i].TranspoTics;
  end;

  for i := 0 to Length(radixwallinfo) - 1 do
  begin
    radixwallinfo[i].Flags := state.Walls[i].Flags;
    radixwallinfo[i].HitPoints := state.Walls[i].HitPoints;
    radixwallinfo[i].Trigger := state.Walls[i].Trigger;
  end;
end;

//==============================================================================
//
// RX_SaveGame
//
//==============================================================================
procedure RX_SaveGame(const filename: string);
var
  data: TBytes;
  f: TFileStream;
begin
  try
    data := TRadixSaveGameCodec.Encode(RX_CollectState);
    f := TFileStream.Create(filename + RADIXSAVEEXTENSION, fmCreate);
    try
      if Length(data) > 0 then
        f.WriteBuffer(data[0], Length(data));
    finally
      f.Free;
    end;
  except
    on e: Exception do
      I_Warning('RX_SaveGame(): %s: %s'#13#10, [filename + RADIXSAVEEXTENSION, e.Message]);
  end;
end;

//==============================================================================
//
// RX_LoadGame
//
//==============================================================================
procedure RX_LoadGame(const filename: string);
var
  data: TBytes;
  f: TFileStream;
begin
  // the engine has loaded the level again and its briefing has started: a saved game is in the level
  RB_Exit;
  // the level that the engine has loaded again has them, its saved game has freed them
  RX_SpawnPilotThinker;
  RX_SpawnLevelLogicThinker;

  if not FileExists(filename + RADIXSAVEEXTENSION) then
  begin
    I_Warning('RX_LoadGame(): %s not found: the craft and the level of Radix start again'#13#10,
      [filename + RADIXSAVEEXTENSION]);
    RX_ResetCrafts;
    exit;
  end;

  try
    f := TFileStream.Create(filename + RADIXSAVEEXTENSION, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(data, f.Size);
      if Length(data) > 0 then
        f.ReadBuffer(data[0], Length(data));
    finally
      f.Free;
    end;
    RX_ApplyState(TRadixSaveGameCodec.Decode(data));
  except
    on e: Exception do
    begin
      I_Warning('RX_LoadGame(): %s: %s'#13#10, [filename + RADIXSAVEEXTENSION, e.Message]);
      RX_ResetCrafts;
    end;
  end;
end;

//==============================================================================
//
// RX_ScriptSaveGame
//
//==============================================================================
procedure RX_ScriptSaveGame(slot: integer);
begin
  G_SaveGame(slot, 'AUTOSCRIPT');
end;

//==============================================================================
//
// RX_ScriptLoadGame
//
//==============================================================================
procedure RX_ScriptLoadGame(slot: integer);
begin
  G_LoadGame(IntToStr(slot));
end;

//==============================================================================
//
// RX_StateLogLine
// The fingerprints of the parts of the state, for -radixstate
//
//==============================================================================
function RX_StateLogLine: string;
var
  state: TRadixSaveState;
  prints: TRadixSaveFingerprints;
  i: integer;
  hp: integer;
  suspended: integer;
begin
  state := RX_CollectState;
  prints := TRadixSaveGameCodec.Fingerprints(state);
  hp := 0;
  for i := 0 to Length(state.Walls) - 1 do
    hp := hp + state.Walls[i].HitPoints;
  suspended := 0;
  for i := 0 to Length(state.Triggers) - 1 do
    if state.Triggers[i].Suspended <> 0 then
      inc(suspended);
  result := Format('lasttrigger=%d suspended=%d wallhp=%d shots=%d players=%.8x levelplayers=%.8x ' +
    'actions=%.8x triggers=%.8x walls=%.8x',
    [state.LastTriggers[consoleplayer], suspended, hp, Length(state.Shots), prints.Players, prints.LevelPlayers,
     prints.Actions, prints.Triggers, prints.Walls]);
end;

initialization
  RX_StateLogAddSource(@RX_StateLogLine);

end.
