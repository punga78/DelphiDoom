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
//  Radix: the codepointers of the states that the engine of Doom does not have
//  and their registration (RX_RegisterActions). The ones of the weapons are in
//  radix_weapons; here are the ones of the actors: A_AmbientSound (radix_sounds
//  of Rad-X), the vertical fight (radix_vertical_fight) and the ones that Rad-X
//  added to p_common.
//
//  Rad-X added fields to mobj_t (bouncecnt, wallbouncefactor, idleexplodespeed)
//  and bits to flags3_ex (BOBING, CANSPAWNCHILDREN, NOSOUND, INACTIVE) that the
//  mobj_t of Doom does not have: where an action only wrote one of them, here it
//  writes a custom parameter of the mobj (they go into the savegames) and the
//  comment of the action says what the engine does not do with it yet.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit radix_codepointers;

interface

uses
  m_fixed,
  p_mobj_h;

//==============================================================================
//
// RX_RegisterActions
// Adds the codepointers of Radix to the actions of the engine. To call after
// DEH_Init and before GAMEDEF and the ACTORDEF lumps are parsed
//
//==============================================================================
procedure RX_RegisterActions;

//==============================================================================
//
// RX_AmbientSound
// S_AmbientSound of Rad-X: a sound at a place of the map
//
//==============================================================================
function RX_AmbientSound(const x, y: fixed_t; const sndname: string): Pmobj_t;

//==============================================================================
//
// RX_SpawnRadixBigExplosion
//
//==============================================================================
function RX_SpawnRadixBigExplosion(const x, y, z: fixed_t): Pmobj_t;

//==============================================================================
//
// A_AmbientSound(x, y, sound)
//
//==============================================================================
procedure A_AmbientSound(actor: Pmobj_t);

//==============================================================================
//
// A_AmbientSoundFV(x, y, sound)
//
//==============================================================================
procedure A_AmbientSoundFV(actor: Pmobj_t);

//==============================================================================
//
// A_VericalLookForPlayers(z1, z1, radius=128,[state=see])
//
//==============================================================================
procedure A_VericalLookForPlayers(actor: Pmobj_t);

//==============================================================================
//
// A_VerticalMissileUp(missiletype: string, x, y, z, maxmomxy)
//
//==============================================================================
procedure A_VerticalMissileUp(actor: Pmobj_t);

//==============================================================================
//
// A_VerticalMissileDown(missiletype: string, x, y, z, maxmomxy)
//
//==============================================================================
procedure A_VerticalMissileDown(actor: Pmobj_t);

//==============================================================================
//
// A_SpawnChildEx
//
//==============================================================================
procedure A_SpawnChildEx(actor: Pmobj_t);

//==============================================================================
//
// A_CanSpawnChildren
//
//==============================================================================
procedure A_CanSpawnChildren(actor: Pmobj_t);

//==============================================================================
//
// A_NoCanSpawnChildren
//
//==============================================================================
procedure A_NoCanSpawnChildren(actor: Pmobj_t);

//==============================================================================
//
// A_LimitBounceControl(numbounces: integer)
//
//==============================================================================
procedure A_LimitBounceControl(actor: Pmobj_t);

//==============================================================================
//
// A_WallBounceFactor(factor: float)
//
//==============================================================================
procedure A_WallBounceFactor(actor: Pmobj_t);

//==============================================================================
//
// A_NoBobing
//
//==============================================================================
procedure A_NoBobing(actor: Pmobj_t);

//==============================================================================
//
// A_DropFarTarget(dist, propability)
//
//==============================================================================
procedure A_DropFarTarget(actor: Pmobj_t);

//==============================================================================
//
// A_CheckPlayerAndExplode(mindist: float)
//
//==============================================================================
procedure A_CheckPlayerAndExplode(actor: Pmobj_t);

//==============================================================================
//
// A_IdleExplode([minidlevelocity: float=1.0])
//
//==============================================================================
procedure A_IdleExplode(actor: Pmobj_t);

//==============================================================================
//
// A_PlayerPain
//
//==============================================================================
procedure A_PlayerPain(actor: Pmobj_t);

//==============================================================================
//
// A_PlayerFloorSlide(dist: float)
//
//==============================================================================
procedure A_PlayerFloorSlide(actor: Pmobj_t);

//==============================================================================
//
// A_BarrelExplosion
//
//==============================================================================
procedure A_BarrelExplosion(actor: Pmobj_t);

//==============================================================================
//
// A_DroneExplosion
//
//==============================================================================
procedure A_DroneExplosion(actor: Pmobj_t);

const
  // the custom parameters of a mobj that stand for the fields of the mobj_t of Rad-X
  S_PARAM_BOUNCECNT = 'RADIXBOUNCECNT';
  S_PARAM_WALLBOUNCEFACTOR = 'RADIXWALLBOUNCEFACTOR';
  S_PARAM_IDLEEXPLODESPEED = 'RADIXIDLEEXPLODESPEED';
  S_PARAM_NOSPAWNCHILDREN = 'RADIXNOSPAWNCHILDREN';

var
  // gameplay option of Rad-X (g_gameplay.pas)
  g_bigbarrelexplosion: boolean = false;

implementation

uses
  d_delphi,
  doomdef,
  d_player,
  deh_base,
  g_game,
  i_system,
  info,
  info_h,
  info_common,
  m_rnd,
  p_common,
  p_local,
  p_maputl,
  p_mobj,
  p_params,
  p_setup,
  p_sounds,
  r_defs,
  r_main,
  s_sound,
  sc_states,
  radix_playerstate,
  radix_weapons;

var
  m_ambient: integer = -1;

const
  STR_AMBIENTSOUND = 'AMBIENTSOUND';

//==============================================================================
//
// RX_AmbientSound
//
//==============================================================================
function RX_AmbientSound(const x, y: fixed_t; const sndname: string): Pmobj_t;
begin
  if m_ambient = -1 then
    m_ambient := Info_GetMobjNumForName(STR_AMBIENTSOUND);

  if m_ambient = -1 then
  begin
    result := nil;
    exit;
  end;

  result := P_SpawnMobj(x, y, ONFLOATZ, m_ambient);
  S_StartSound(result, sndname);
end;

var
  radixbigexposion_id: integer = -1;

//==============================================================================
//
// RX_SpawnRadixBigExplosion
//
//==============================================================================
function RX_SpawnRadixBigExplosion(const x, y, z: fixed_t): Pmobj_t;
begin
  if radixbigexposion_id < 0 then
    radixbigexposion_id := Info_GetMobjNumForName('MT_RADIXBIGEXPLOSION');

  if radixbigexposion_id < 0 then
  begin
    result := nil;
    exit;
  end;

  result := P_SpawnMobj(x, y, z, radixbigexposion_id);
end;

//==============================================================================
//
// A_AmbientSound
//
//==============================================================================
procedure A_AmbientSound(actor: Pmobj_t);
var
  dx, dy: fixed_t;
  snd: string;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  dx := actor.state.params.FixedVal[0];
  dy := actor.state.params.FixedVal[1];

  // JVAL: 20200304 -
  //  Hack! Allow zero string length sound inside RANDOMPICK to avoid playing the sound :)
  snd := actor.state.params.StrVal[2];
  if snd <> '' then
    RX_AmbientSound(actor.x + dx, actor.y + dy, snd);
end;

//==============================================================================
//
// A_AmbientSoundFV
// The sound at full volume wherever the listener is. S_StartSound of Rad-X had
// a "full volume" flag; in the engine of today a sound without a place is at
// full volume: the thing of the sound is born as for A_AmbientSound (the state
// of the game stays the one of Rad-X) and the sound is played without a place
//
//==============================================================================
procedure A_AmbientSoundFV(actor: Pmobj_t);
var
  dx, dy: fixed_t;
  snd: string;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  dx := actor.state.params.FixedVal[0];
  dy := actor.state.params.FixedVal[1];

  snd := actor.state.params.StrVal[2];
  if snd = '' then
    exit;

  if m_ambient = -1 then
    m_ambient := Info_GetMobjNumForName(STR_AMBIENTSOUND);
  if m_ambient <> -1 then
    P_SpawnMobj(actor.x + dx, actor.y + dy, ONFLOATZ, m_ambient);
  S_StartSound(nil, snd);
end;

//==============================================================================
//
// P_PtInMap
// Checks if a given point is in map boundaries, also checks 3d floors
//
//==============================================================================
function P_PtInMap(const x, y, z: fixed_t; const step: fixed_t): boolean;
var
  s: Psubsector_t;
  sec: Psector_t;
begin
  s := R_PointInSubsector(x, y);
  if s.sector.midsec >= 0 then
  begin
    sec := @sectors[s.sector.midsec];
    result := (z >= sec.floorheight - step) and (z <= sec.ceilingheight + step);
  end
  else
    result := false;
  if not result then
    result := (z + step > s.sector.floorheight) and (z - step < s.sector.ceilingheight);
end;

var
  vsthing: Pmobj_t;
  vsz1, vsz2: fixed_t;
  vsradius: fixed_t;

const
  VSRADIUSSTEP = 32;

//==============================================================================
//
// PIT_CheckVerticalSight
//
//==============================================================================
function PIT_CheckVerticalSight(thing: Pmobj_t): boolean;
var
  x1, y1, z1: fixed_t;
  x2, y2, z2: fixed_t;
  dx, dy, dz: integer;
  maxstep: integer;
  i, iters: integer;
begin
  result := true;

  if thing = vsthing then
    exit; // Don't check against self

  if (abs(thing.x - vsthing.x) >= vsradius) or (abs(thing.y - vsthing.y) >= vsradius) then
    exit; // Don't see thing

  if thing.z > MaxI(vsz1, vsz2) then
    exit
  else if thing.z + thing.height < MinI(vsz1, vsz2) then
    exit; // under thing

  // JVAL: 20200424 - Trace to catch 3d floors or  sector obstacles
  x1 := thing.x;
  y1 := thing.y;
  z1 := thing.z;
  x2 := vsthing.x;
  y2 := vsthing.y;
  z2 := vsthing.z;
  dx := x2 - x1;
  dy := y2 - y1;
  dz := z2 - z1;

  maxstep := Max3I(abs(dx), abs(dy), abs(dz));
  iters := (maxstep div VSRADIUSSTEP) div FRACUNIT + 1;
  dx := dx div iters;
  dy := dy div iters;
  dz := dz div iters;

  for i := 0 to iters do
  begin
    x2 := x1 + i * dx;
    y2 := y1 + i * dy;
    z2 := z1 + i * dz;
    if not P_PtInMap(x2, y2, z2, VSRADIUSSTEP * FRACUNIT) then
      exit;
  end;

  result := false;
end;

//==============================================================================
//
// P_FindVericalPlayerTarget
//
//==============================================================================
function P_FindVericalPlayerTarget(vthing: Pmobj_t; const z1, z2: fixed_t; const radius: fixed_t): Pmobj_t;
var
  i: integer;
begin
  vsthing := vthing;
  vsz1 := z1;
  vsz2 := z2;
  vsradius := radius;
  for i := 0 to MAXPLAYERS - 1 do
    if TGameSession.PlayerInGame[i] then
      if TGameSession.Players[i].mo <> nil then
        if not PIT_CheckVerticalSight(TGameSession.Players[i].mo) then
        begin
          result := TGameSession.Players[i].mo;
          exit;
        end;
  result := nil;
end;

//==============================================================================
//
// A_VericalLookForPlayers(z1, z1, radius=128,[state=see])
// Missing: the inactive (stub) enemies of Rad-X (MF3_EX_INACTIVE) look too
//
//==============================================================================
procedure A_VericalLookForPlayers(actor: Pmobj_t);
var
  z1, z2: fixed_t;
  radius: fixed_t;
  targ: Pmobj_t;
  st: integer;
begin
  if not P_CheckStateParams(actor, 2, CSP_AT_LEAST) then
    exit;

  z1 := actor.state.params.FixedVal[0];
  z2 := actor.state.params.FixedVal[1];
  if actor.state.params.Count > 2 then
    radius := actor.state.params.FixedVal[2]
  else
    radius := 128 * FRACUNIT;

  targ := P_FindVericalPlayerTarget(actor, z1, z2, radius);
  if targ <> nil then
  begin
    actor.threshold := 0;
    actor.target := targ;

    if actor.info.seesound <> 0 then
      A_SeeSound(actor, actor);

    if actor.state.params.Count > 3 then
    begin
      st := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[3]);
      if @states[st] <> actor.state then
        P_SetMobjState(actor, statenum_t(st));
    end
    else
      P_SetMobjState(actor, statenum_t(actor.info.seestate));
  end;
end;

//==============================================================================
//
// P_VerticalMissile
//
//==============================================================================
procedure P_VerticalMissile(actor: Pmobj_t; const direction: integer);
var
  targ, th: Pmobj_t;
  mobj_no: integer;
  x, y, z: fixed_t;
  speed: fixed_t;
  tics: integer;
  maxmomxy: fixed_t;
  dx, dy, dz: fixed_t;
begin
  if not P_CheckStateParams(actor, 4, CSP_AT_LEAST) then
    exit;

  targ := actor.target;
  if (targ = nil) or (targ = actor) then
    exit;

  if actor.state.params.IsComputed[0] then
    mobj_no := actor.state.params.IntVal[0]
  else
  begin
    mobj_no := Info_GetMobjNumForName(actor.state.params.StrVal[0]);
    actor.state.params.IntVal[0] := mobj_no;
  end;
  if mobj_no = -1 then
  begin
    I_Warning('P_VerticalMissile(): Unknown missile %s'#13#10, [actor.state.params.StrVal[0]]);
    exit;
  end;

  x := actor.x + actor.state.params.FixedVal[1];
  y := actor.y + actor.state.params.FixedVal[2];
  z := actor.z + actor.state.params.FixedVal[3];

  dx := targ.x - x;
  dy := targ.y - y;
  dz := targ.z - z;

  // the target must be on the side the missile goes to (Isign of Rad-X: 0 has no side)
  if (dz = 0) or ((dz < 0) <> (direction < 0)) then
    exit;

  th := P_SpawnMobj(x, y, z, mobj_no);

  speed := th.info.speed;
  if speed < 2048 then
    speed := speed * FRACUNIT;
  if speed = 0 then
    speed := 12 * FRACUNIT;

  tics := abs(dz) div speed;
  if tics < 1 then
    tics := 1;

  A_SeeSound(th, th);

  th.target := actor;  // where it came from

  if actor.state.params.Count >= 5 then
    maxmomxy := abs(actor.state.params.FixedVal[4])
  else
    maxmomxy := speed;
  // Limit speed (Rad-X matched the velocity of the target first and then overwrote it here)
  th.momx := GetIntegerInRange(dx div tics, -maxmomxy, maxmomxy);
  th.momy := GetIntegerInRange(dy div tics, -maxmomxy, maxmomxy);

  if dz < 0 then
    th.momz := -speed
  else
    th.momz := speed;

  P_CheckMissileSpawn(th);
end;

//==============================================================================
//
// A_VerticalMissileUp
//
//==============================================================================
procedure A_VerticalMissileUp(actor: Pmobj_t);
begin
  P_VerticalMissile(actor, 1);
end;

//==============================================================================
//
// A_VerticalMissileDown
//
//==============================================================================
procedure A_VerticalMissileDown(actor: Pmobj_t);
begin
  P_VerticalMissile(actor, -1);
end;

//==============================================================================
//
// A_SpawnChildEx
// In Rad-X an actor spawned children while it had MF3_EX_CANSPAWNCHILDREN (a
// flag of its definition) and A_NoCanSpawnChildren took it away. The flag does
// not exist here: every actor can, until A_NoCanSpawnChildren says no.
// Missing: the child does not get the actor as master (A_SpawnItemEx of the
// engine does not return what it spawned) unless its flags ask for it
//
//==============================================================================
procedure A_SpawnChildEx(actor: Pmobj_t);
begin
  if P_GetMobjCustomParamValue(actor, S_PARAM_NOSPAWNCHILDREN) = 0 then
    A_SpawnItemEx(actor);
end;

//==============================================================================
//
// A_CanSpawnChildren
//
//==============================================================================
procedure A_CanSpawnChildren(actor: Pmobj_t);
begin
  if P_GetMobjCustomParamValue(actor, S_PARAM_NOSPAWNCHILDREN) <> 0 then
    P_SetMobjCustomParam(actor, S_PARAM_NOSPAWNCHILDREN, 0);
end;

//==============================================================================
//
// A_NoCanSpawnChildren
//
//==============================================================================
procedure A_NoCanSpawnChildren(actor: Pmobj_t);
begin
  P_SetMobjCustomParam(actor, S_PARAM_NOSPAWNCHILDREN, 1);
end;

//==============================================================================
//
// A_LimitBounceControl
// Missing: the count is kept but nothing reads it (in Rad-X P_XYMovement and
// P_ZMovement took a bounce away at every bounce and exploded the missile at 0)
//
//==============================================================================
procedure A_LimitBounceControl(actor: Pmobj_t);
begin
  if not P_CheckStateParams(actor, 1) then
    exit;

  P_SetMobjCustomParam(actor, S_PARAM_BOUNCECNT, actor.state.params.IntVal[0]);
end;

//==============================================================================
//
// A_WallBounceFactor
// Missing: the factor is kept but nothing reads it (in Rad-X the bounce on a
// wall multiplied the momentum by it)
//
//==============================================================================
procedure A_WallBounceFactor(actor: Pmobj_t);
begin
  if not P_CheckStateParams(actor, 1) then
    exit;

  P_SetMobjCustomParam(actor, S_PARAM_WALLBOUNCEFACTOR, actor.state.params.FixedVal[0]);
end;

//==============================================================================
//
// A_NoBobing
// Missing: MF3_EX_BOBING (the bobbing of Rad-X that P_MobjThinker applied) is
// not in the engine, so there is no bobbing to stop: the action does nothing
//
//==============================================================================
procedure A_NoBobing(actor: Pmobj_t);
begin
end;

//==============================================================================
//
// A_DropFarTarget(dist, propability)
//
//==============================================================================
procedure A_DropFarTarget(actor: Pmobj_t);
var
  dist: fixed_t;
  propability: integer;
begin
  if not P_CheckStateParams(actor, 1, CSP_AT_LEAST) then
    exit;

  if actor.target = nil then
    exit;

  if actor.state.params.Count > 1 then
  begin
    propability := actor.state.params.IntVal[1];
    if N_Random < propability then
      exit;
  end;

  dist := actor.state.params.FixedVal[0];
  if P_AproxDistance(actor.x - actor.target.x, actor.y - actor.target.y) > dist then
    P_SetMobjState(actor, statenum_t(actor.info.spawnstate));
end;

//==============================================================================
//
// A_CheckPlayerAndExplode
//
//==============================================================================
procedure A_CheckPlayerAndExplode(actor: Pmobj_t);
var
  mindist: fixed_t;
  dest: Pmobj_t;
  i: integer;
  nearest, distance: integer;
begin
  if not P_CheckStateParams(actor, 1, CSP_AT_LEAST) then
    exit;

  mindist := actor.state.params.FixedVal[0];

  dest := nil;
  nearest := MAXINT;

  for i := 0 to MAXPLAYERS - 1 do
    if TGameSession.PlayerInGame[i] then
      if TGameSession.Players[i].mo <> nil then
        if TGameSession.Players[i].mo.health >= 0 then
        begin
          distance := P_AproxDistance(TGameSession.Players[i].mo.x - actor.x, TGameSession.Players[i].mo.y - actor.y);
          if distance < nearest then
          begin
            nearest := distance;
            dest := TGameSession.Players[i].mo;
          end;
        end;

  if dest = nil then
    exit;

  if nearest > mindist then
    exit;

  if abs(dest.z - actor.z) > mindist then
    exit;

  P_ExplodeMissile(actor);
end;

//==============================================================================
//
// A_IdleExplode
// Missing: the speed is kept but nothing reads it (in Rad-X P_MobjThinker
// exploded the missile that moved slower than it)
//
//==============================================================================
procedure A_IdleExplode(actor: Pmobj_t);
var
  speed: fixed_t;
begin
  speed := FRACUNIT;
  if actor.state.params <> nil then
    if actor.state.params.Count > 0 then
      speed := actor.state.params.FixedVal[0];

  P_SetMobjCustomParam(actor, S_PARAM_IDLEEXPLODESPEED, speed);
end;

//==============================================================================
//
// A_PlayerPain
// Missing: MF3_EX_NOSOUND of Rad-X (the sound is always played)
//
//==============================================================================
procedure A_PlayerPain(actor: Pmobj_t);
begin
  S_StartSound(actor, 'radix/SndPlaneHit');
end;

//==============================================================================
//
// A_PlayerFloorSlide
// Missing: floorslidetics is set and counted down (RX_PilotWeaponsTick) but the
// movement of the player of Doom does not slide on floors and ceilings with it
//
//==============================================================================
procedure A_PlayerFloorSlide(actor: Pmobj_t);
var
  i: integer;
  dist: integer;
  x1, x2, y1, y2: integer;
  pmo: Pmobj_t;
begin
  if not P_CheckStateParams(actor, 1, CSP_AT_LEAST) then
    exit;

  dist := (actor.state.params.FixedVal[0] div 2) + 1;
  x1 := actor.x - dist;
  x2 := actor.x + dist;
  y1 := actor.y - dist;
  y2 := actor.y + dist;
  for i := 0 to MAXPLAYERS - 1 do
    if TGameSession.PlayerInGame[i] then
    begin
      pmo := TGameSession.Players[i].mo;
      if pmo <> nil then
        if IsIntegerInRange(pmo.x, x1, x2) and IsIntegerInRange(pmo.y, y1, y2) then
          RX_PlayerState(@TGameSession.Players[i]).floorslidetics := 2;
    end;
end;

//==============================================================================
//
// RX_ShortenExplosion
// A random part of the tics of an explosion that was just spawned
//
//==============================================================================
procedure RX_ShortenExplosion(const mo: Pmobj_t);
begin
  if mo.tics > 0 then
    mo.tics := P_Random mod mo.tics
  else
    P_Random; // Rad-X always took a number here
  if mo.tics = 0 then
    mo.tics := 1;
end;

//==============================================================================
//
// A_BarrelExplosion
// Missing: MF3_EX_NOSOUND of Rad-X (the explosion that is added plays its own
// sound too); velz of Rad-X (the z the barrel really moved) is momz here
//
//==============================================================================
procedure A_BarrelExplosion(actor: Pmobj_t);
var
  mo: Pmobj_t;
begin
  if TGameSession.DemoPlayback or TGameSession.DemoRecording then
    exit;
  if actor.momz < 0 then
    exit;
  if g_bigbarrelexplosion then
  begin
    mo := RX_SpawnRadixBigExplosion(actor.x, actor.y, actor.z);
    if mo <> nil then
    begin
      mo.momz := -FRACUNIT;
      RX_ShortenExplosion(mo);
    end;
    RX_AmbientSound(actor.x, actor.y, 'radix/SndExplode');
  end;
end;

//==============================================================================
//
// A_DroneExplosion
// Missing: MF3_EX_NOSOUND of Rad-X, as A_BarrelExplosion
//
//==============================================================================
procedure A_DroneExplosion(actor: Pmobj_t);
var
  mo: Pmobj_t;
  i: integer;
begin
  if TGameSession.DemoPlayback or TGameSession.DemoRecording then
    exit;
  if g_bigbarrelexplosion then
  begin
    for i := 0 to 5 do
    begin
      mo := RX_SpawnRadixBigExplosion(actor.x, actor.y, actor.z);
      if mo = nil then
        break;
      RX_ShortenExplosion(mo);
      mo.momx := 2 * FRACUNIT - P_Random * 1024;
      mo.momy := 2 * FRACUNIT - P_Random * 1024;
    end;
    RX_AmbientSound(actor.x, actor.y, 'radix/SndExplode');
  end;
end;

//==============================================================================
//
// RX_RegisterActions
//
//==============================================================================
procedure RX_RegisterActions;
begin
  // weapons (radix_weapons)
  DEH_AddAction(@A_RaiseRadixWeapon, 'A_RaiseRadixWeapon()');
  DEH_AddAction(@A_LowerRadixWeapon, 'A_LowerRadixWeapon()');
  DEH_AddAction(@A_FireRadixPlasma, 'A_FireRadixPlasma()');
  DEH_AddAction(@A_FireRadixStandardEPC, 'A_FireRadixStandardEPC()');
  DEH_AddAction(@A_FireRadixEnhancedEPC, 'A_FireRadixEnhancedEPC()');
  DEH_AddAction(@A_FireRadixSuperEPC1, 'A_FireRadixSuperEPC1()');
  DEH_AddAction(@A_FireRadixSuperEPC2, 'A_FireRadixSuperEPC2()');
  DEH_AddAction(@A_FireRadixPlasmaSpread, 'A_FireRadixPlasmaSpread()');
  DEH_AddAction(@A_FireRadixSeekingMissiles, 'A_FireRadixSeekingMissiles()');
  DEH_AddAction(@A_FireRadixNuke, 'A_FireRadixNuke()');
  DEH_AddAction(@A_FireRadixPhaseTorpedo, 'A_FireRadixPhaseTorpedo()');
  DEH_AddAction(@A_FireRadixGravityWave, 'A_FireRadixGravityWave()');
  DEH_AddAction(@A_PhaseTorpedoSplit, 'A_PhaseTorpedoSplit()');
  // actors
  DEH_AddAction(@A_PlayerPain, 'A_PlayerPain()');
  DEH_AddAction(@A_AmbientSound, 'A_AmbientSound(x: integer, y: integer, sound: string)');
  DEH_AddAction(@A_AmbientSoundFV, 'A_AmbientSoundFV(x: integer, y: integer, sound: string)');
  DEH_AddAction(@A_VericalLookForPlayers, 'A_VericalLookForPlayers(z1: float, z2: float, radius: float=128, state: state_t=see])');
  DEH_AddAction(@A_VerticalMissileUp, 'A_VerticalMissileUp(missiletype: string, x: float, y: float, z: float, [maxmomxy: fixed_t])');
  DEH_AddAction(@A_VerticalMissileDown, 'A_VerticalMissileDown(missiletype: string, x: float, y: float, z: float, [maxmomxy: fixed_t])');
  DEH_AddAction(@A_SpawnChildEx, 'A_SpawnChildEx(itemtype: string, [xofs: float], [yofs: float], [zofs: float], [momx: float], [momy: float], [momz: float], [ang: angle], [flags: integer], [chance: integer])');
  DEH_AddAction(@A_CanSpawnChildren, 'A_CanSpawnChildren()');
  DEH_AddAction(@A_NoCanSpawnChildren, 'A_NoCanSpawnChildren()');
  DEH_AddAction(@A_LimitBounceControl, 'A_LimitBounceControl(numbounces: integer)');
  DEH_AddAction(@A_WallBounceFactor, 'A_WallBounceFactor(factor: float)');
  DEH_AddAction(@A_NoBobing, 'A_NoBobing()');
  DEH_AddAction(@A_DropFarTarget, 'A_DropFarTarget(distance: integer; propability: integer)');
  DEH_AddAction(@A_CheckPlayerAndExplode, 'A_CheckPlayerAndExplode(mindist: float)');
  DEH_AddAction(@A_IdleExplode, 'A_IdleExplode([minidlevelocity: float=1.0])');
  DEH_AddAction(@A_PlayerFloorSlide, 'A_PlayerFloorSlide(dist: float)');
  DEH_AddAction(@A_BarrelExplosion, 'A_BarrelExplosion()');
  DEH_AddAction(@A_DroneExplosion, 'A_DroneExplosion()');
end;

end.
