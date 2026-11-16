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
//  Radix: the physics of Rad-X. The rules are the classes
//  DelphiDoom.Radix.Physics.* of IdTech1\Radix. Two parts:
//   - what runs from the thinkers of the level: a craft that hits a floor or
//     a ceiling, or lands (RX_PlaneHitFloor and the penalty of P_HitFloor of
//     Rad-X): sound, smoke, count of the hits of the debriefing; the missiles
//     that explode when they stand still (P_VelocityHandler of Rad-X,
//     A_IdleExplode);
//   - what the movement code of the engine asks for through
//     DelphiDoom.Engine.World.PhysicsExtension (the version of IdTech1\Radix\): a
//     craft that is blocked by a wall (RX_PlayerHitsWall) and the touch damage
//     of two things that overlap (RX_ThingTouched, PIT_CheckThing of Rad-X).
//  What is not hooked yet (the bounces, the force fields of the sectors, the
//  move in steps...) is listed in IdTech1\Radix\CLAUDE.md.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit radix_physics;

interface

uses
  d_player,
  m_fixed,
  p_mobj_h;

var
  // The part of radixwallhits of each craft that comes from the hits against floors and ceilings and
  // from the landings of this level (tics): for the log of the debriefing
  radiximpacttics: array[0..3] of integer;

//==============================================================================
//
// RX_PhysicsReset
// A level starts
//
//==============================================================================
procedure RX_PhysicsReset;

//==============================================================================
//
// RX_PilotImpacts
// To call at every tic for a living craft, after the engine has moved it
//
//==============================================================================
procedure RX_PilotImpacts(const pnum: integer; const p: Pplayer_t);

//==============================================================================
//
// RX_IdleExplodeTick
// To call at every tic: the missiles that A_IdleExplode has marked explode
// when they are slow enough
//
//==============================================================================
procedure RX_IdleExplodeTick;

//==============================================================================
//
// RX_PlayerHitsWall
// The move of a craft was blocked by a wall and the engine has slid it along it
// (PIT_CheckLine and P_XYMovement of Rad-X: RX_PlaneHitWall): a hit for the
// score, the sound and, one time out of two, a puff of smoke. The place that
// was tried is tryx, tryy
//
//==============================================================================
procedure RX_PlayerHitsWall(const p: Pplayer_t; const tryx, tryy: fixed_t);

//==============================================================================
//
// RX_ThingTouched
// A thing that moves (toucher) overlaps another one: the touch damage of each
// of the two (PIT_CheckThing of Rad-X), with the other as the inflictor
//
//==============================================================================
procedure RX_ThingTouched(const thing, toucher: Pmobj_t);

implementation

uses
  d_delphi,
  d_think,
  doomdef,
  g_game,
  info_common,
  m_rnd,
  tables,
  p_local,
  p_maputl,
  p_mobj,
  p_inter,
  p_params,
  p_setup,
  p_slopes,
  p_tick,
  r_data,
  r_defs,
  r_main,
  s_sound,
  radix_codepointers,
  radix_logic,
  radix_map_extra,
  radix_pickups,
  radix_pilot,
  radix_pilotsound,
  DelphiDoom.Radix.Level.Types,
  DelphiDoom.Radix.Physics.Contact,
  DelphiDoom.Radix.Physics.Damage,
  DelphiDoom.Radix.Physics.Impact,
  DelphiDoom.Radix.Physics.Movement;

const
  SND_SCRAPE = 'SndScrape';
  SND_PLANEHIT = 'SndPlaneHit';
  // a sound whose length is not known is asked again after a second
  UNKNOWNDURATIONTICS = TICRATE;

type
  // where a craft was at the end of the tic before
  pilotimpact_t = record
    mo: Pmobj_t;
    x, y, z: fixed_t;
    planehittics: integer; // JVAL: 20200505 - For plane hit (sound duration)
  end;

  idlemissile_t = record
    key: LongWord;
    x, y, z: fixed_t;
  end;
  idlemissile_tArray = array of idlemissile_t;

var
  pilotimpacts: array[0..MAXPLAYERS - 1] of pilotimpact_t;
  impactorigins: array[0..MAXPLAYERS - 1] of degenmobj_t;
  id_hitsmoke1: integer = -2;
  id_hitsmoke2: integer = -2;
  snd_scrape_id: integer = -2;
  snd_planehit_id: integer = -2;
  idlemissiles: idlemissile_tArray;
  numidlemissiles: integer = 0;
  previdlemissiles: idlemissile_tArray;
  numprevidlemissiles: integer = 0;

//==============================================================================
//
// RX_PhysicsReset
//
//==============================================================================
procedure RX_PhysicsReset;
begin
  ZeroMemory(@pilotimpacts, SizeOf(pilotimpacts));
  ZeroMemory(@radiximpacttics, SizeOf(radiximpacttics));
  numidlemissiles := 0;
  numprevidlemissiles := 0;
end;

//==============================================================================
//
// RX_ImpactSound
// The place of the sound follows the craft (no thing of the map is added, as
// the sound of the engine of radix_pilotsound)
//
//==============================================================================
procedure RX_ImpactSound(const pnum: integer; const pmo: Pmobj_t; const impact: TRadixImpact);
var
  sndid: integer;
  duration: integer;
begin
  if snd_scrape_id = -2 then
  begin
    snd_scrape_id := RX_PilotSoundIndex(SND_SCRAPE);
    snd_planehit_id := RX_PilotSoundIndex(SND_PLANEHIT);
  end;

  if impact.Sound = TRadixImpactSound.PlaneHit then
    sndid := snd_planehit_id
  else
    sndid := snd_scrape_id;

  if (impact.Sound <> TRadixImpactSound.None) and (sndid >= 0) then
  begin
    impactorigins[pnum].x := pmo.x;
    impactorigins[pnum].y := pmo.y;
    impactorigins[pnum].z := pmo.z;
    S_StartSound(@impactorigins[pnum], RX_SoundName(sndid));
  end;

  if impact.StartsSoundTimer then
  begin
    duration := RX_SoundDuration(sndid);
    if duration <= 0 then
      duration := UNKNOWNDURATIONTICS;
    pilotimpacts[pnum].planehittics := duration;
  end;
end;

//==============================================================================
//
// RX_InitSmokeIds
//
//==============================================================================
procedure RX_InitSmokeIds;
begin
  if id_hitsmoke1 = -2 then
  begin
    id_hitsmoke1 := Info_GetMobjNumForName('MT_RADIXDRONEHITWALLSMOKE1');
    id_hitsmoke2 := Info_GetMobjNumForName('MT_RADIXDRONEHITWALLSMOKE2');
  end;
end;

//==============================================================================
//
// RX_SpawnHitSmoke
// _spawn_burner_smoke_floor of RX_PlaneHitFloor: a ring of smoke around the
// craft, on the floor (dir < 0) or under the ceiling
//
//==============================================================================
procedure RX_SpawnHitSmoke(const pmo: Pmobj_t; const velx, vely: fixed_t; const dir: integer;
  const num_hit_smokes: integer);
var
  i: integer;
  an, an1: angle_t;
  dist: fixed_t;
  x, y, z: fixed_t;
  momz: fixed_t;
  psec, sec: Psector_t;
  mo: Pmobj_t;
  rnd: integer;
begin
  RX_InitSmokeIds;
  if (id_hitsmoke1 < 0) or (id_hitsmoke2 < 0) or (num_hit_smokes <= 0) then
    exit;

  an := pmo.angle;
  an1 := 0;
  psec := Psubsector_t(pmo.subsector).sector;
  for i := 0 to num_hit_smokes - 1 do
  begin
    // one random number for each statement: the order must not depend on the compiler
    rnd := Sys_Random;
    dist := pmo.radius + rnd * 1024;
    x := pmo.x + FixedMul(dist, finecosine[an shr ANGLETOFINESHIFT]);
    y := pmo.y + FixedMul(dist, finesine[an shr ANGLETOFINESHIFT]);
    sec := R_PointInSubsector(x, y).sector;
    if sec = psec then
    begin
      rnd := Sys_Random;
      if dir < 0 then
      begin
        z := P_FloorHeight(sec, x, y) + 4 * FRACUNIT;
        momz := FRACUNIT div 2 + rnd * 64;
      end
      else
      begin
        z := P_CeilingHeight(sec, x, y) - 4 * FRACUNIT;
        momz := -FRACUNIT div 2 - rnd * 64;
      end;
      if Sys_Random < 128 then
        mo := P_SpawnMobj(x, y, z, id_hitsmoke1)
      else
        mo := P_SpawnMobj(x, y, z, id_hitsmoke2);
      rnd := Sys_Random;
      dist := rnd * 64;
      mo.momx := velx + FixedMul(dist, finecosine[an1 shr ANGLETOFINESHIFT]);
      mo.momy := vely + FixedMul(dist, finesine[an1 shr ANGLETOFINESHIFT]);
      mo.momz := momz;
    end;
    an1 := an1 + ANGLE_MAX div LongWord(num_hit_smokes);
    an := an + ANGLE_MAX div LongWord(num_hit_smokes);
  end;
end;

//==============================================================================
//
// RX_PlainFloor
// The tests of P_HitFloor before its penalty: the floor under the craft is the
// one of its sector
//
//==============================================================================
function RX_PlainFloor(const pmo: Pmobj_t): boolean;
var
  ss: Psubsector_t;
begin
  result := false;
  if pmo.flags2_ex and MF2_EX_NOHITFLOOR <> 0 then
    exit;
  if G_NeedsCompatibilityMode then
    exit;
  ss := pmo.subsector;
  if ss.flags and SSF_BRIDGE <> 0 then
    exit;
  if pmo.floorz <> ss.sector.floorheight then
    exit;
  result := ss.sector.heightsec = -1;
end;

//==============================================================================
//
// RX_InRadixSector
// The sector comes from RADIX.DAT (RSF_RADIXSECTOR): the hits make the sound of
// scraping there
//
//==============================================================================
function RX_InRadixSector(const sec: Psector_t): boolean;
var
  secid: integer;
begin
  secid := RX_SectorIndex(sec);
  result := (secid >= 0) and (secid < Length(radixsectorinfo)) and
    (radixsectorinfo[secid].Flags and RSF_RADIXSECTOR <> 0);
end;

//==============================================================================
//
// RX_PilotImpacts
// Rad-X called RX_PlaneHitFloor at the start of P_MobjThinker of the craft,
// with the height it had moved in the tic before; here the thinker of the
// pilots runs after the craft has moved: the numbers are the same
//
//==============================================================================
procedure RX_PilotImpacts(const pnum: integer; const p: Pplayer_t);
var
  last: ^pilotimpact_t;
  pmo: Pmobj_t;
  sec: Psector_t;
  velx, vely, velz: fixed_t;
  onfloor, onceiling: boolean;
  radixsector: boolean;
  impact: TRadixImpact;
  penalty: integer;
begin
  last := @pilotimpacts[pnum];
  pmo := p.mo;

  if last.mo <> pmo then
  begin
    // a new body
    last.mo := pmo;
    last.planehittics := 0;
  end
  else
  begin
    last.planehittics := TRadixCraftImpactRules.CountDown(last.planehittics);
    velx := pmo.x - last.x;
    vely := pmo.y - last.y;
    velz := pmo.z - last.z;
    onfloor := pmo.z <= pmo.floorz;
    onceiling := pmo.z + pmo.height >= pmo.ceilingz;
    sec := Psubsector_t(pmo.subsector).sector;

    // JVAL: 20200428 - inc wall count to use in score
    penalty := TRadixCraftImpactRules.LandingPenalty(last.z > pmo.floorz, onfloor, RX_PlainFloor(pmo));

    radixsector := RX_InRadixSector(sec);
    impact := TRadixCraftImpactRules.PlaneHit(last.planehittics,
      onfloor, P_GetThingFloorType(pmo) = FLOOR_SOLID,
      onceiling, flats[sec.ceilingpic].terraintype = FLOOR_SOLID,
      false, radixsector, velz);
    if impact.Hit then
    begin
      RX_ImpactSound(pnum, pmo, impact);
      penalty := penalty + impact.Penalty;
      if onfloor and (P_GetThingFloorType(pmo) = FLOOR_SOLID) then
        RX_SpawnHitSmoke(pmo, velx, vely, -1, impact.Smokes)
      else
        RX_SpawnHitSmoke(pmo, velx, vely, 1, impact.Smokes);
    end;
    inc(radixwallhits[pnum], penalty);
    inc(radiximpacttics[pnum], penalty);
  end;

  last.x := pmo.x;
  last.y := pmo.y;
  last.z := pmo.z;
end;

//==============================================================================
//
// RX_IdleExplodeTick
// P_VelocityHandler of Rad-X. The speed of a missile is how far it has really
// moved in the last tic; a missile that is seen for the first time is left
// alone (MF_JUSTAPPEARED of Rad-X)
//
//==============================================================================
procedure RX_IdleExplodeTick;
var
  think: Pthinker_t;
  mo: Pmobj_t;
  i: integer;
  idlespeed: fixed_t;
  velocity: fixed_t;
  tmp: idlemissile_tArray;
begin
  numidlemissiles := 0;
  think := thinkercap.next;
  while think <> @thinkercap do
  begin
    if @think._function.acp1 = @P_MobjThinker then
    begin
      mo := Pmobj_t(think);
      if mo.flags and MF_MISSILE <> 0 then
      begin
        idlespeed := P_GetMobjCustomParamValue(mo, S_PARAM_IDLEEXPLODESPEED);
        if idlespeed > 0 then
        begin
          if numidlemissiles >= Length(idlemissiles) then
            SetLength(idlemissiles, numidlemissiles + 64);
          idlemissiles[numidlemissiles].key := mo.key;
          idlemissiles[numidlemissiles].x := mo.x;
          idlemissiles[numidlemissiles].y := mo.y;
          idlemissiles[numidlemissiles].z := mo.z;
          inc(numidlemissiles);

          for i := 0 to numprevidlemissiles - 1 do
            if previdlemissiles[i].key = mo.key then
            begin
              velocity := TRadixMovementRules.ApproximateDistance(
                TRadixMovementRules.ApproximateDistance(mo.x - previdlemissiles[i].x, mo.y - previdlemissiles[i].y),
                mo.z - previdlemissiles[i].z);
              case TRadixMovementRules.IdleAction(velocity, idlespeed, mo.info.speed) of
                TRadixIdleAction.Explode:
                  begin
                    // Explode in very low speeds
                    P_SetMobjCustomParam(mo, S_PARAM_IDLEEXPLODESPEED, 0);
                    dec(numidlemissiles);
                    P_ExplodeMissile(mo);
                  end;
                TRadixIdleAction.Accelerate:
                  begin
                    // Accelerate in low (but not very low) speeds
                    mo.momx := TRadixMovementRules.Accelerate(mo.momx);
                    mo.momy := TRadixMovementRules.Accelerate(mo.momy);
                    mo.momz := TRadixMovementRules.Accelerate(mo.momz);
                  end;
              end;
              break;
            end;
        end;
      end;
    end;
    think := think.next;
  end;

  tmp := previdlemissiles;
  previdlemissiles := idlemissiles;
  idlemissiles := tmp;
  numprevidlemissiles := numidlemissiles;
  numidlemissiles := 0;
end;

//==============================================================================
//
// RX_PlayerHitsWall
// RX_PlaneHitWall of Rad-X: one hit for the score; the sound when the one before
// has ended; one time out of two a puff of smoke between the craft and the place
// that was tried, with the speed the craft had in the tic before. A random
// number for each statement: the order must not depend on the compiler
//
//==============================================================================
procedure RX_PlayerHitsWall(const p: Pplayer_t; const tryx, tryy: fixed_t);
var
  pnum: integer;
  pmo: Pmobj_t;
  last: ^pilotimpact_t;
  impact: TRadixImpact;
  gate: integer;
  kind: integer;
  heightrnd: integer;
  first, second: integer;
  smokeid: integer;
  velx, vely, velz: fixed_t;
  mo: Pmobj_t;
begin
  pnum := pDiff(p, @players[0], SizeOf(players[0]));
  if (pnum < 0) or (pnum >= MAXPLAYERS) then
    exit;
  pmo := p.mo;
  if pmo = nil then
    exit;

  last := @pilotimpacts[pnum];
  if last.mo <> pmo then
  begin
    // a new body: where it is now is where it was
    last.mo := pmo;
    last.x := pmo.x;
    last.y := pmo.y;
    last.z := pmo.z;
    last.planehittics := 0;
  end;

  gate := Sys_Random;
  impact := TRadixCraftImpactRules.WallHit(last.planehittics, false,
    RX_InRadixSector(Psubsector_t(pmo.subsector).sector), gate);
  inc(radixwallhits[pnum], impact.Penalty);
  RX_ImpactSound(pnum, pmo, impact);

  if impact.Smokes <= 0 then
    exit;
  RX_InitSmokeIds;
  if (id_hitsmoke1 < 0) or (id_hitsmoke2 < 0) then
    exit;

  kind := Sys_Random;
  if kind < 128 then
    smokeid := id_hitsmoke1
  else
    smokeid := id_hitsmoke2;
  heightrnd := Sys_Random;
  mo := P_SpawnMobj(pmo.x div 2 + tryx div 2, pmo.y div 2 + tryy div 2,
    pmo.z + (pmo.height div 256 * heightrnd), smokeid);
  velx := pmo.x - last.x;
  vely := pmo.y - last.y;
  velz := pmo.z - last.z;
  first := Sys_Random;
  second := Sys_Random;
  mo.momx := velx + (first - second) * 64;
  first := Sys_Random;
  second := Sys_Random;
  mo.momy := vely + (first - second) * 64;
  first := Sys_Random;
  second := Sys_Random;
  mo.momz := velz + (first - second) * 64;
end;

//==============================================================================
//
// RX_TouchDamageOf
// The touch damage that a thing takes from the one that touches it
//
//==============================================================================
procedure RX_TouchDamageOf(const target, toucher: Pmobj_t);
var
  damage: integer;
begin
  damage := TRadixDamageRules.TouchDamage(target.flags and MF_SHOOTABLE <> 0, target.health,
    RX_ActorTouchDamage(target._type), false, toucher.player <> nil);
  if damage > 0 then
    P_DamageMobj(target, toucher, toucher.target, damage);
end;

//==============================================================================
//
// RX_ThingTouched
//
//==============================================================================
procedure RX_ThingTouched(const thing, toucher: Pmobj_t);
begin
  RX_TouchDamageOf(thing, toucher);
  // the damage above may have killed the toucher
  if toucher.health > 0 then
    RX_TouchDamageOf(toucher, thing);
end;

end.
