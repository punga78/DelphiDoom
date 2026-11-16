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
//  Radix: the weapons of the craft (radix_weapons.pas of Rad-X). The states of
//  the weapons come from GAMEDEF and name these codepointers; the Radix part of
//  the player is radixplayer_t (radix_playerstate) and the rules that need no
//  engine are TRadixWeaponRules (IdTech1\Radix).
//
//  The weapon code of Doom (p_pspr) is not touched: what P_CheckAmmo of Rad-X
//  knew (the energy of the gravity wave, the two seeking missiles) is asked by
//  the codepointers when they fire (RX_CheckAmmo).
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit radix_weapons;

interface

uses
  d_player,
  p_mobj_h,
  p_pspr_h;

//==============================================================================
//
// A_RaiseRadixWeapon
//
//==============================================================================
procedure A_RaiseRadixWeapon(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_LowerRadixWeapon
//
//==============================================================================
procedure A_LowerRadixWeapon(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_FireRadixPlasma
//
//==============================================================================
procedure A_FireRadixPlasma(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_FireRadixStandardEPC
//
//==============================================================================
procedure A_FireRadixStandardEPC(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_FireRadixEnhancedEPC
//
//==============================================================================
procedure A_FireRadixEnhancedEPC(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_FireRadixSuperEPC1
//
//==============================================================================
procedure A_FireRadixSuperEPC1(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_FireRadixSuperEPC2
//
//==============================================================================
procedure A_FireRadixSuperEPC2(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_FireRadixPlasmaSpread
//
//==============================================================================
procedure A_FireRadixPlasmaSpread(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_FireRadixSeekingMissiles
//
//==============================================================================
procedure A_FireRadixSeekingMissiles(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_FireRadixNuke
//
//==============================================================================
procedure A_FireRadixNuke(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_FireRadixPhaseTorpedo
//
//==============================================================================
procedure A_FireRadixPhaseTorpedo(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_PhaseTorpedoSplit
//
//==============================================================================
procedure A_PhaseTorpedoSplit(actor: Pmobj_t);

//==============================================================================
//
// A_FireRadixGravityWave
//
//==============================================================================
procedure A_FireRadixGravityWave(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_FireALDS
//
//==============================================================================
procedure A_FireALDS(const player: Pplayer_t);

//==============================================================================
//
// RX_FirePlasmaBomb
//
//==============================================================================
procedure RX_FirePlasmaBomb(const player: Pplayer_t);

//==============================================================================
//
// RX_PilotWeaponsTick
// A tic of the weapons of a craft that is alive: the target under the
// crosshair, the ALDS, the flash of the plasma bomb (RX_PlayerThink of Rad-X)
//
//==============================================================================
procedure RX_PilotWeaponsTick(const p: Pplayer_t);

var
  // gameplay options of Rad-X (g_gameplay.pas)
  g_vanillalevel1neutroncannon: boolean = false;
  g_vanillalevel1plasmaspreader: boolean = false;
  g_fastweaponrefire: boolean = false;

implementation

uses
  d_delphi,
  doomdef,
  doomstat,
  d_items,
  g_game,
  r_defs,
  r_main,
  info,
  info_h,
  info_common,
  m_rnd,
  m_fixed,
  tables,
  p_tick,
  p_pspr,
  DelphiDoom.Engine.World.PspriteRules,
  p_inter,
  p_local,
  p_map,
  p_setup,
  p_mobj,
  p_maputl,
  p_sight,
  p_sounds,
  p_params,
  p_3dfloors,
  radix_playerstate,
  radix_codepointers,
  DelphiDoom.Radix.Weapon.Rules;

const
  // the phase torpedo that has already split (MF3_EX_NOPHASETORPEDOSPLIT of Rad-X: the mobj_t of
  // Doom has no bit for it, a custom parameter of the mobj goes with it also in the savegames)
  S_PARAM_NOTORPEDOSPLIT = 'RADIXNOPHASETORPEDOSPLIT';

  // WEAPONBOTTOM of p_pspr (exported by p_pspr since step 2f-3; here a local copy of its value): a weapon that comes up starts from here
  WEAPONBOTTOM = (32 + 96) * FRACUNIT;

//==============================================================================
//
// RX_Sign
//
//==============================================================================
function RX_Sign(const x: integer): integer;
begin
  if x < 0 then
    result := -1
  else if x > 0 then
    result := 1
  else
    result := 0;
end;

//==============================================================================
//
// RX_CheckNextRefire
// JVAL: 20200401 - Check if weapon can refire
//
//==============================================================================
function RX_CheckNextRefire(const p: Pplayer_t): boolean;
var
  rp: Pradixplayer_t;
  w: integer;
begin
  rp := RX_PlayerState(p);
  w := Ord(p.readyweapon);
  if (w < 0) or (w >= NUMRADIXWEAPONS) then
  begin
    result := false;
    exit;
  end;

  if not TRadixWeaponRules.CanRefire(TTickState.LevelTime, rp.lastfire[w],
    TRadixWeaponRules.RefireTics(w, g_fastweaponrefire)) then
  begin
    result := false;
    exit;
  end;

  rp.lastfire[w] := TTickState.LevelTime;
  result := true;
end;

//==============================================================================
//
// RX_BringUpWeapon
// P_BringUpWeapon of Rad-X (the one of Doom is not exported and plays the sound
// of the chainsaw for the slot of the enhanced EPC)
//
//==============================================================================
procedure RX_BringUpWeapon(const player: Pplayer_t);
var
  newstate: statenum_t;
begin
  if player.pendingweapon = wp_nochange then
    player.pendingweapon := player.readyweapon;

  newstate := statenum_t(weaponinfo[Ord(player.pendingweapon)].upstate);

  player.pendingweapon := wp_nochange;
  player.psprites[Ord(ps_weapon)].sy := WEAPONBOTTOM;

  P_SetPsprite(player, Ord(ps_weapon), newstate);
end;

//==============================================================================
//
// RX_CheckAmmo
// The part of P_CheckAmmo of Rad-X that the one of Doom does not know: returns
// true if the weapon can fire, if not selects the next weapon to use.
//
//==============================================================================
function RX_CheckAmmo(const player: Pplayer_t): boolean;
var
  rp: Pradixplayer_t;
  ammotype: integer;
  ammo: integer;
  owned: array[0..NUMRADIXWEAPONS - 1] of boolean;
  ammos: array[0..Ord(NUMAMMO) - 1] of integer;
  i: integer;
begin
  rp := RX_PlayerState(player);

  ammotype := Ord(weaponinfo[Ord(player.readyweapon)].ammo);
  if (ammotype < 0) or (ammotype >= Ord(NUMAMMO)) then
  begin
    ammotype := TRadixWeaponRules.NO_AMMO;
    ammo := 0;
  end
  else
    ammo := player.ammo[ammotype];

  if TRadixWeaponRules.CanFire(Ord(player.readyweapon), ammotype, ammo, rp.energy, GRAVITYWAVEENERGY) then
  begin
    result := true;
    exit;
  end;

  // Out of ammo, pick a weapon to change to.
  for i := 0 to NUMRADIXWEAPONS - 1 do
    owned[i] := player.weaponowned[i] <> 0;
  for i := 0 to Ord(NUMAMMO) - 1 do
    ammos[i] := player.ammo[i];
  player.pendingweapon := weapontype_t(
    TRadixWeaponRules.NextWeapon(owned, ammos, rp.neutroncannonlevel, gamemode = shareware));

  // Now set appropriate weapon overlay.
  P_SetPsprite(player, Ord(ps_weapon), statenum_t(weaponinfo[Ord(player.readyweapon)].downstate));

  result := false;
end;

//==============================================================================
//
// A_RaiseRadixWeapon
//
//==============================================================================
procedure A_RaiseRadixWeapon(player: Pplayer_t; psp: Ppspdef_t);
var
  newstate: statenum_t;
begin
  // The weapon has been raised all the way,
  //  so change to the ready state.
  newstate := statenum_t(weaponinfo[Ord(player.readyweapon)].readystate);

  P_SetPsprite(player, Ord(ps_weapon), newstate);
end;

//==============================================================================
//
// A_LowerRadixWeapon
//
//==============================================================================
procedure A_LowerRadixWeapon(player: Pplayer_t; psp: Ppspdef_t);
begin
  // Player is dead.
  if player.playerstate = PST_DEAD then
    // don't bring weapon back up
    exit;

  // The old weapon has been lowered off the screen,
  // so change the weapon and start raising it
  if player.health = 0 then
  begin
    // Player is dead, so keep the weapon off screen.
    P_SetPsprite(player, Ord(ps_weapon), S_NULL);
    exit;
  end;

  // Rad-X copied the pending weapon also when there was none
  if player.pendingweapon <> wp_nochange then
    player.readyweapon := player.pendingweapon;

  RX_BringUpWeapon(player);
end;

//==============================================================================
//
// RX_SpawnRadixPlayerMissile
// P_SpawnRadixPlayerMissile of Rad-X: the missile leaves from the place of the
// source, not from the height of the gun of the marine
//
//==============================================================================
procedure RX_SpawnRadixPlayerMissile(source: Pmobj_t; _type: integer);
var
  th: Pmobj_t;
  an: angle_t;
  slope: fixed_t;
  speed: fixed_t;
begin
  // see which target is to be aimed at
  an := source.angle;
  slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

  if TMapAim.LineTarget = nil then
  begin
    an := an + $4000000;
    slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

    if TMapAim.LineTarget = nil then
    begin
      an := an - $8000000;
      slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

      if TMapAim.LineTarget = nil then
      begin
        an := source.angle;
        slope := (Pplayer_t(source.player).lookdir16 * (FRACUNIT div 16)) div 173;
      end;

    end;
  end;

  th := P_SpawnMobj(source.x, source.y, source.z, _type);

  A_SeeSound(th, th);

  th.target := source;
  th.angle := an;
  an := an shr ANGLETOFINESHIFT;
  speed := th.info.speed;
  th.momx := FixedMul(speed, finecosine[an]);
  th.momy := FixedMul(speed, finesine[an]);
  th.momz := FixedMul(speed, slope);

  P_CheckMissileSpawn(th);
end;

//==============================================================================
//
// RX_SpawnPlayerMissileOffsZ
// P_SpawnPlayerMissileOffsZ of Rad-X: a missile of the player that leaves doffs
// to the side of the craft and dz above it, not beyond a wall
//
//==============================================================================
procedure RX_SpawnPlayerMissileOffsZ(source: Pmobj_t; _type: integer; const doffs, dz: fixed_t);
var
  oldx, oldy, oldz: fixed_t;
  spawnx, spawny, spawnz: fixed_t;
  newx, newy, newz: fixed_t;
  dx, dy: fixed_t;
  offs: fixed_t;
  offsx, offsy: fixed_t;
  stepx, stepy: fixed_t;
  sfloor, sceiling: fixed_t;
  ang: angle_t;
  sec: Psector_t;
begin
  if _type < 0 then
    exit; // the definitions of the actors do not have this missile

  oldx := source.x;
  oldy := source.y;
  oldz := source.z;

  ang := (source.angle - ANG90) shr ANGLETOFINESHIFT;

  offs := doffs + RX_Sign(doffs) * mobjinfo[_type].radius;
  dx := FixedMul(offs, finecosine[ang]);
  dy := FixedMul(offs, finesine[ang]);

  // A little forward
  stepx := FixedMul(source.radius div 2, finecosine[source.angle shr ANGLETOFINESHIFT]);
  stepy := FixedMul(source.radius div 2, finesine[source.angle shr ANGLETOFINESHIFT]);

  spawnx := source.x + dx + stepx;
  spawny := source.y + dy + stepy;
  spawnz := source.z + dz;

  P_LineTrace(oldx, oldy, oldz, spawnx, spawny, spawnz, newx, newy, newz);

  // JVAL: 20200502 - Limit z spawn height of missile
  if abs(oldz - newz) > TRadixWeaponRules.MAX_WEAPON_Z_OFFSET then
    newz := oldz + RX_Sign(newz - oldz) * TRadixWeaponRules.MAX_WEAPON_Z_OFFSET;

  offsx := FixedMul(RX_Sign(doffs) * mobjinfo[_type].radius, finecosine[ang]);
  offsy := FixedMul(RX_Sign(doffs) * mobjinfo[_type].radius, finesine[ang]);

  source.x := newx - offsx;
  source.y := newy - offsy;

  sec := R_PointInSubsector(source.x, source.y).sector;

  sfloor := P_3dFloorHeight(sec, source.x, source.y, newz);
  sceiling := P_3dCeilingHeight(sec, source.x, source.y, newz);

  if newz - mobjinfo[_type].height < sfloor then
    newz := newz + mobjinfo[_type].height;

  if newz + mobjinfo[_type].height > sceiling then
    newz := newz - mobjinfo[_type].height;

  source.z := newz;
  RX_SpawnRadixPlayerMissile(source, _type);

  source.x := oldx;
  source.y := oldy;
  source.z := oldz;
end;

//==============================================================================
//
// RX_WeaponFlash
//
//==============================================================================
procedure RX_WeaponFlash(const player: Pplayer_t);
begin
  P_SetPsprite(player,
    Ord(ps_flash), statenum_t(weaponinfo[Ord(player.readyweapon)].flashstate + (P_Random and 1)));
end;

//==============================================================================
//
// RX_FireVolley
// Fires what the rules decided for an energy weapon: drains the energy, spawns
// the missiles and keeps the left/right flag of the weapon
//
//==============================================================================
procedure RX_FireVolley(const player: Pplayer_t; const volley: TRadixVolley; const flag: LongWord;
  const id_standard, id_left, id_right: integer);
var
  rp: Pradixplayer_t;
  energy: TRadixWeaponEnergy;
  i: integer;
  id: integer;
begin
  rp := RX_PlayerState(player);

  if volley.Drain > 0 then
  begin
    energy.Energy := rp.energy;
    energy.Reserve := rp.energy_reserve;
    energy.Countdown := rp.plasmaenergycountdown;
    energy.FireTics := rp.energyweaponfiretics;
    TRadixWeaponRules.DrainPlasmaEnergy(energy, volley.Drain);
    rp.energy := energy.Energy;
    rp.energy_reserve := energy.Reserve;
    rp.plasmaenergycountdown := energy.Countdown;
    rp.energyweaponfiretics := energy.FireTics;
  end;

  for i := 0 to volley.Count - 1 do
  begin
    case volley.Shots[i].Kind of
      TRadixShotKind.SpreadLeft: id := id_left;
      TRadixShotKind.SpreadRight: id := id_right;
    else
      id := id_standard;
    end;
    RX_SpawnPlayerMissileOffsZ(player.mo, id, volley.Shots[i].Offset, volley.Shots[i].Z);
  end;

  if volley.Alternate then
    rp.weaponflags := rp.weaponflags or flag
  else
    rp.weaponflags := rp.weaponflags and not flag;
end;

//
// A_FireRadixPlasma
//
var
  radixplasma_id: integer = -1;

//==============================================================================
//
// A_FireRadixPlasma
//
//==============================================================================
procedure A_FireRadixPlasma(player: Pplayer_t; psp: Ppspdef_t);
var
  rp: Pradixplayer_t;
  volley: TRadixVolley;
begin
  if not RX_CheckNextRefire(player) then
    exit;

  rp := RX_PlayerState(player);

  // JVAL: 20200412 -> Do not fire if low on energy
  if not TRadixWeaponRules.HasPlasmaEnergy(rp.energy) then
    exit;

  RX_WeaponFlash(player);

  if radixplasma_id < 0 then
    radixplasma_id := Info_GetMobjNumForName('MT_RADIXPLASMA');

  volley := TRadixWeaponRules.NeutronVolley(rp.neutroncannonlevel, rp.energy,
    rp.weaponflags and PWF_NEURONCANNON <> 0,
    g_vanillalevel1neutroncannon and not TGameSession.DemoPlayback and not TGameSession.DemoRecording);
  RX_FireVolley(player, volley, PWF_NEURONCANNON, radixplasma_id, radixplasma_id, radixplasma_id);
end;

//
// P_EPCFire
//
var
  radixepcshell_id: integer = -1;

//==============================================================================
//
// RX_EPCFire
//
//==============================================================================
procedure RX_EPCFire(const player: Pplayer_t; const tbl: TRadixEpcTable);
var
  ammoid: integer;
  i, actualammo: integer;
  accuracy: integer;
  r1, r2: integer;
  doffs, dz: fixed_t;
  shot: TRadixShot;
begin
  ammoid := Ord(weaponinfo[Ord(player.readyweapon)].ammo);
  if (ammoid < 0) or (ammoid >= Ord(NUMAMMO)) then
    exit; // GAMEDEF gave no ammo to the weapon

  // Find the actual ammo
  actualammo := TRadixWeaponRules.EpcShells(player.ammo[ammoid], TRadixWeaponRules.EpcSize(tbl));
  player.ammo[ammoid] := player.ammo[ammoid] - actualammo;

  RX_WeaponFlash(player);

  if radixepcshell_id < 0 then
    radixepcshell_id := Info_GetMobjNumForName('MT_RADIXEPCSHELL');

  accuracy := TRadixWeaponRules.EpcAccuracy(tbl);
  for i := 0 to actualammo - 1 do
  begin
    // accuracy -> lower values, better accuracy
    if accuracy = 0 then
    begin
      doffs := 0;
      dz := 0;
    end
    else
    begin
      // one random number for each statement: the order must be the same at 32 and at 64 bit
      r1 := P_Random mod accuracy;
      r2 := P_Random mod accuracy;
      doffs := r1 * FRACUNIT - r2 * FRACUNIT;
      r1 := P_Random mod accuracy;
      r2 := P_Random mod accuracy;
      dz := r1 * FRACUNIT - r2 * FRACUNIT;
    end;

    shot := TRadixWeaponRules.EpcShot(tbl, i);
    RX_SpawnPlayerMissileOffsZ(player.mo, radixepcshell_id, shot.Offset + doffs, shot.Z + dz);
  end;
end;

//==============================================================================
//
// A_FireRadixStandardEPC
//
//==============================================================================
procedure A_FireRadixStandardEPC(player: Pplayer_t; psp: Ppspdef_t);
begin
  if not RX_CheckNextRefire(player) then
    exit;

  RX_EPCFire(player, TRadixEpcTable.Standard);
end;

//==============================================================================
//
// A_FireRadixEnhancedEPC
//
//==============================================================================
procedure A_FireRadixEnhancedEPC(player: Pplayer_t; psp: Ppspdef_t);
begin
  if not RX_CheckNextRefire(player) then
    exit;

  RX_EPCFire(player, TRadixEpcTable.Enhanced);
end;

//==============================================================================
//
// A_FireRadixSuperEPC1
//
//==============================================================================
procedure A_FireRadixSuperEPC1(player: Pplayer_t; psp: Ppspdef_t);
begin
  if not RX_CheckNextRefire(player) then
    exit;

  RX_EPCFire(player, TRadixEpcTable.Super1);
end;

//==============================================================================
//
// A_FireRadixSuperEPC2
//
//==============================================================================
procedure A_FireRadixSuperEPC2(player: Pplayer_t; psp: Ppspdef_t);
begin
  if not RX_CheckNextRefire(player) then
    exit;

  RX_EPCFire(player, TRadixEpcTable.Super2);
end;

//
// A_FireRadixPlasmaSpread
//
var
  radixplasmaspreadleft_id: integer = -1;
  radixplasmaspreadright_id: integer = -1;

//==============================================================================
//
// A_FireRadixPlasmaSpread
//
//==============================================================================
procedure A_FireRadixPlasmaSpread(player: Pplayer_t; psp: Ppspdef_t);
var
  rp: Pradixplayer_t;
  volley: TRadixVolley;
begin
  if not RX_CheckNextRefire(player) then
    exit;

  rp := RX_PlayerState(player);

  // JVAL: 20200412 -> Do not fire if low on energy
  if not TRadixWeaponRules.HasPlasmaEnergy(rp.energy) then
    exit;

  RX_WeaponFlash(player);

  if radixplasmaspreadleft_id < 0 then
    radixplasmaspreadleft_id := Info_GetMobjNumForName('MT_RADIXPLASMASPREADLEFT');

  if radixplasmaspreadright_id < 0 then
    radixplasmaspreadright_id := Info_GetMobjNumForName('MT_RADIXPLASMASPREADRIGHT');

  volley := TRadixWeaponRules.SpreaderVolley(rp.neutronspreaderlevel, rp.energy,
    rp.weaponflags and PWF_NEURONSPREADER <> 0,
    g_vanillalevel1plasmaspreader and not TGameSession.DemoPlayback and not TGameSession.DemoRecording);
  RX_FireVolley(player, volley, PWF_NEURONSPREADER, radixplasmaspreadleft_id,
    radixplasmaspreadleft_id, radixplasmaspreadright_id);
end;

//
// A_FireRadixTorpedos
//
var
  radixseekingmissile_id: integer = -1;

//==============================================================================
//
// A_FireRadixSeekingMissiles
//
//==============================================================================
procedure A_FireRadixSeekingMissiles(player: Pplayer_t; psp: Ppspdef_t);
var
  ammoid: integer;
begin
  if not RX_CheckNextRefire(player) then
    exit;

  // less than two missiles: change weapon (P_CheckAmmo of Rad-X did it before the attack state)
  if not RX_CheckAmmo(player) then
    exit;

  RX_WeaponFlash(player);

  if radixseekingmissile_id < 0 then
    radixseekingmissile_id := Info_GetMobjNumForName('MT_RADIXSEEKINGMISSILE');

  ammoid := Ord(weaponinfo[Ord(player.readyweapon)].ammo);
  if (ammoid < 0) or (ammoid >= Ord(NUMAMMO)) then
    exit;

  if player.ammo[ammoid] <= 0 then
    exit;
  dec(player.ammo[ammoid]);

  RX_SpawnPlayerMissileOffsZ(
    player.mo, radixseekingmissile_id,
      -32 * FRACUNIT, -8 * FRACUNIT + TRadixWeaponRules.WEAPON_Z_OFFSET
  );

  if player.ammo[ammoid] <= 0 then
    exit;
  dec(player.ammo[ammoid]);

  RX_SpawnPlayerMissileOffsZ(
    player.mo, radixseekingmissile_id,
      32 * FRACUNIT, -8 * FRACUNIT + TRadixWeaponRules.WEAPON_Z_OFFSET
  );
end;

//==============================================================================
//
// RX_FireAlternating
// One missile that costs one unit of ammo, in turn from the left and from the
// right of the craft (the nuke and the phase torpedo)
//
//==============================================================================
procedure RX_FireAlternating(const player: Pplayer_t; const id: integer; const flag: LongWord; const z: fixed_t);
var
  rp: Pradixplayer_t;
  ammoid: integer;
begin
  ammoid := Ord(weaponinfo[Ord(player.readyweapon)].ammo);
  if (ammoid < 0) or (ammoid >= Ord(NUMAMMO)) then
    exit;

  if player.ammo[ammoid] <= 0 then
    exit;
  dec(player.ammo[ammoid]);

  rp := RX_PlayerState(player);
  if rp.weaponflags and flag <> 0 then
  begin
    RX_SpawnPlayerMissileOffsZ(player.mo, id, -32 * FRACUNIT, z);
    rp.weaponflags := rp.weaponflags and not flag;
  end
  else
  begin
    RX_SpawnPlayerMissileOffsZ(player.mo, id, 32 * FRACUNIT, z);
    rp.weaponflags := rp.weaponflags or flag;
  end;
end;

//
// A_FireRadixNuke
//
var
  radixnuke_id: integer = -1;

//==============================================================================
//
// A_FireRadixNuke
//
//==============================================================================
procedure A_FireRadixNuke(player: Pplayer_t; psp: Ppspdef_t);
begin
  if not RX_CheckNextRefire(player) then
    exit;

  RX_WeaponFlash(player);

  if radixnuke_id < 0 then
    radixnuke_id := Info_GetMobjNumForName('MT_RADIXNUKE');

  RX_FireAlternating(player, radixnuke_id, PWF_NUKE, -8 * FRACUNIT + TRadixWeaponRules.WEAPON_Z_OFFSET);
end;

//
// A_FireRadixPhaseTorpedo
//
var
  radixphasetorpedo_id: integer = -1;

//==============================================================================
//
// A_FireRadixPhaseTorpedo
//
//==============================================================================
procedure A_FireRadixPhaseTorpedo(player: Pplayer_t; psp: Ppspdef_t);
begin
  if not RX_CheckNextRefire(player) then
    exit;

  RX_WeaponFlash(player);

  if radixphasetorpedo_id < 0 then
    radixphasetorpedo_id := Info_GetMobjNumForName('MT_RADIXPHASETORPEDO');

  RX_FireAlternating(player, radixphasetorpedo_id, PWF_PHASETORPEDO,
    8 * FRACUNIT + TRadixWeaponRules.WEAPON_Z_OFFSET);
end;

//==============================================================================
//
// RX_SplitTorpedo
// One of the two torpedoes that leave a phase torpedo, side is -1 (left) or 1
//
//==============================================================================
procedure RX_SplitTorpedo(const actor: Pmobj_t; const side: integer);
var
  mo: Pmobj_t;
  mv: fixed_t;
  ang: angle_t;
begin
  mo := P_SpawnMobj(actor.x + actor.momx, actor.y + actor.momy, actor.z + actor.momz, radixphasetorpedo_id);
  mo.flags3_ex := actor.flags3_ex;
  P_SetMobjCustomParam(mo, S_PARAM_NOTORPEDOSPLIT, 1);
  mo.target := actor.target;
  mo.tracer := actor.tracer;
  mo.momx := actor.momx;
  mo.momy := actor.momy;
  mo.momz := actor.momz;

  mv := (4 + (P_Random and 1)) * FRACUNIT div 4;
  if side < 0 then
    ang := (actor.angle - ANG90 - ANG5) shr ANGLETOFINESHIFT
  else
    ang := (actor.angle + ANG90 + ANG5) shr ANGLETOFINESHIFT;
  mo.momx := mo.momx + FixedMul(mv, finecosine[ang]);
  mo.momy := mo.momy + FixedMul(mv, finesine[ang]);
  mo.momz := mo.momz - (4 + (P_Random and 1)) * FRACUNIT div 16;
end;

//==============================================================================
//
// A_PhaseTorpedoSplit
//
//==============================================================================
procedure A_PhaseTorpedoSplit(actor: Pmobj_t);
begin
  if P_GetMobjCustomParamValue(actor, S_PARAM_NOTORPEDOSPLIT) <> 0 then
    exit;

  P_SetMobjCustomParam(actor, S_PARAM_NOTORPEDOSPLIT, 1);

  if radixphasetorpedo_id < 0 then
    radixphasetorpedo_id := Info_GetMobjNumForName('MT_RADIXPHASETORPEDO');
  if radixphasetorpedo_id < 0 then
    exit;

  RX_SplitTorpedo(actor, -1);
  RX_SplitTorpedo(actor, 1);

  actor.momz := actor.momz + (4 + (P_Random and 1)) * FRACUNIT div 16;
end;

//
// A_FireRadixGravityWave
//
var
  radixgravitywave_id: integer = -1;

//==============================================================================
//
// A_FireRadixGravityWave
//
//==============================================================================
procedure A_FireRadixGravityWave(player: Pplayer_t; psp: Ppspdef_t);
var
  rp: Pradixplayer_t;
  owned: array[0..NUMRADIXWEAPONS - 1] of boolean;
  i: integer;
  w: integer;
begin
  rp := RX_PlayerState(player);

  // not enough energy: change weapon (P_CheckAmmo of Rad-X did it before the attack state)
  if rp.gravitywave > 0 then
    if not RX_CheckAmmo(player) then
      exit;

  if RX_CheckNextRefire(player) then
  begin

    if (rp.gravitywave > 0) and (rp.energy >= GRAVITYWAVEENERGY) then
    begin
      if radixgravitywave_id < 0 then
        radixgravitywave_id := Info_GetMobjNumForName('MT_RADIXGRAVITYWAVE');

      dec(rp.gravitywave);
      rp.energy := rp.energy - GRAVITYWAVEENERGY;
      RX_SpawnPlayerMissileOffsZ(player.mo, radixgravitywave_id, 0, 0 + TRadixWeaponRules.WEAPON_Z_OFFSET);
    end;
  end;

  if rp.gravitywave = 0 then
  begin
    for i := 0 to NUMRADIXWEAPONS - 1 do
      owned[i] := player.weaponowned[i] <> 0;
    w := TRadixWeaponRules.WeaponAfterGravityWave(owned);
    if w >= 0 then
      player.pendingweapon := weapontype_t(w);
  end;
end;

//
// A_FireALDS
//
var
  radixaldslaser_id: integer = -1;

//==============================================================================
//
// A_FireALDS
//
//==============================================================================
procedure A_FireALDS(const player: Pplayer_t);
begin
  if radixaldslaser_id < 0 then
    radixaldslaser_id := Info_GetMobjNumForName('MT_ALDSLASER');

  if player.extralight = 0 then
    player.extralight := 1;

  RX_SpawnPlayerMissileOffsZ(player.mo, radixaldslaser_id, 0, TRadixWeaponRules.WEAPON_Z_OFFSET);
end;

//
// Plasma bomb fire
//
var
  pbplayer: Pplayer_t;

//==============================================================================
//
// PIT_Plasmabomb
//
//==============================================================================
function PIT_Plasmabomb(thing: Pmobj_t): boolean;
var
  dist: fixed_t;
begin
  result := true;

  if thing.player <> nil then
    exit;

  dist := P_AproxDistance(thing.x - pbplayer.mo.x, thing.y - pbplayer.mo.y);

  if dist >= TRadixWeaponRules.PLASMA_BOMB_RADIUS then
    exit; // out of range

  if P_CheckSight(thing, pbplayer.mo) then
  begin
    // must be in direct path
    P_DamageMobj(thing, pbplayer.mo, pbplayer.mo, TRadixWeaponRules.PLASMA_BOMB_DAMAGE);
  end;
end;

//==============================================================================
//
// RX_PlasmaBombAttack
//
//==============================================================================
procedure RX_PlasmaBombAttack(const p: Pplayer_t);
var
  x: integer;
  y: integer;
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  dist: fixed_t;
begin
  dist := TRadixWeaponRules.PLASMA_BOMB_RADIUS;
  yh := MapBlockIntY(int64(p.mo.y) + int64(dist) - int64(bmaporgy));
  yl := MapBlockIntY(int64(p.mo.y) - int64(dist) - int64(bmaporgy));
  xh := MapBlockIntX(int64(p.mo.x) + int64(dist) - int64(bmaporgx));
  xl := MapBlockIntX(int64(p.mo.x) - int64(dist) - int64(bmaporgx));
  pbplayer := p;

  for y := yl to yh do
    for x := xl to xh do
      P_BlockThingsIterator(x, y, PIT_Plasmabomb);
end;

//==============================================================================
//
// RX_FirePlasmaBomb
//
//==============================================================================
procedure RX_FirePlasmaBomb(const player: Pplayer_t);
var
  rp: Pradixplayer_t;
begin
  rp := RX_PlayerState(player);

  if not TRadixWeaponRules.CanFirePlasmaBomb(rp.plasmabombs, rp.plasmabombcount) then
    exit;

  rp.plasmabombcount := TRadixWeaponRules.PLASMA_BOMB_TICS;

  RX_PlasmaBombAttack(player);
  RX_AmbientSound(player.mo.x, player.mo.y, 'radix/SndPlasmaBomb');

  dec(rp.plasmabombs);
end;

//==============================================================================
//
// RX_PilotWeaponsTick
//
//==============================================================================
procedure RX_PilotWeaponsTick(const p: Pplayer_t);
var
  rp: Pradixplayer_t;
  i: integer;
begin
  rp := RX_PlayerState(p);

  // a new level starts its time again (Rad-X cleared lastfire when the player was spawned)
  for i := 0 to NUMRADIXWEAPONS - 1 do
    if rp.lastfire[i] > TTickState.LevelTime then
      rp.lastfire[i] := 0;

  // JVAL: 20200504 - Plasma bomb count down
  if rp.plasmabombcount > 0 then
    dec(rp.plasmabombcount);

  // JVAL: 20200507 - Slide to floors/ceilings
  if rp.floorslidetics > 0 then
    dec(rp.floorslidetics);

  // JVAL: 20200501 - Retrieve TMapAim.LineTarget
  P_AimLineAttack(p.mo, p.mo.angle, 16 * 64 * FRACUNIT);
  if (rp.plinetarget = nil) and (TMapAim.LineTarget <> nil) then
    rp.pcrosstic := TTickState.LevelTime;
  rp.plinetarget := TMapAim.LineTarget;

  // JVAL: 20200503 - ALDS
  if (rp.radixpowers[Ord(rpu_alds)] > 0) and (TTickState.LevelTime and $3 = 0) then
  begin
    if TMapAim.LineTarget = nil then
    begin
      P_AimLineAttack(p.mo, p.mo.angle + $4000000, 16 * 64 * FRACUNIT);
      if TMapAim.LineTarget = nil then
        P_AimLineAttack(p.mo, p.mo.angle - $4000000, 16 * 64 * FRACUNIT);
    end;
    if TMapAim.LineTarget <> nil then
      A_FireALDS(p);
  end;
end;

end.
