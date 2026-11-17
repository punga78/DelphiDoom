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
//  Radix: what the craft carries. The pickups of Radix give what their INVENTORY
//  block says (the custom pickups of P_TouchSpecialThing of Rad-X) and shield and
//  energy come back with the time (RX_PlayerThink of Rad-X). The rules are
//  TRadixPilotRules (IdTech1\Radix); the Radix part of the actors was read by
//  TRadixActorProperties while the engine parsed ACTORDEF.
//
//  P_TouchSpecialThing of Doom knows its pickups by sprite and stops the game
//  for any other: the custom pickups lose MF_SPECIAL when a level starts and the
//  thinker of the crafts (radix_pilot) looks for them around each craft.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit radix_pickups;

interface

uses
  d_player,
  DelphiDoom.Radix.ActorProperties;

//==============================================================================
//
// RX_ConfigureActors
// The Radix part of the definitions of the actors (given by ComposeRadix)
//
//==============================================================================
procedure RX_ConfigureActors(const ATable: IRadixActorTable);

//==============================================================================
//
// RX_InitActors
// Binds the Radix part of the actors to the mobjinfo of the engine. A level
// that starts calls it: definitions can be added until then
//
//==============================================================================
procedure RX_InitActors;

//==============================================================================
//
// RX_PilotInventoryTick
// A tic of what the craft carries: regeneration, power ups, pickups
//
//==============================================================================
procedure RX_PilotInventoryTick(const p: Pplayer_t);

//==============================================================================
//
// RX_ActorTouchDamage
// The touch damage of the definition of a kind of thing (touchdamage of the
// mobjinfo_t of Rad-X); 0 for a thing without a Radix part
//
//==============================================================================
function RX_ActorTouchDamage(const mobjtype: integer): integer;

//==============================================================================
//
// RX_ActorCanDamageWalls
// MF3_EX_CANDAMAGEWALLS of Rad-X: the missile of this kind of thing damages the
// walls that it explodes against
//
//==============================================================================
function RX_ActorCanDamageWalls(const mobjtype: integer): boolean;

//==============================================================================
//
// RX_ActorSkyFlight
// MF3_EX_THRUSKY and MF3_EX_PREVENTTHRYSKY of Rad-X: whether a thing of this kind
// flies through a sky (a missile always does, unless it has PREVENTTHRYSKY)
//
//==============================================================================
procedure RX_ActorSkyFlight(const mobjtype: integer; out thrusky, preventthrusky: boolean);

implementation

uses
  SysUtils,
  d_delphi,
  doomdef,
  g_game,
  info,
  info_h,
  info_common,
  i_system,
  m_argv,
  m_fixed,
  p_local,
  p_maputl,
  p_mobj,
  p_mobj_h,
  p_setup,
  p_tick,
  s_sound,
  radix_playerstate,
  DelphiDoom.Radix.Physics.Contact,
  DelphiDoom.Radix.Pilot.Rules;

const
  BONUSADD = 6;
  // "-radixblockspecies": the actors with MF3_EX_DONTBLOCKSPECIES do not get MF3_EX_THRUSPECIES of the
  // engine (they do by default)
  THRUSPECIES_OPTION = '-radixblockspecies';

  neutronlevelmessages: array[0..MAXNEUTRONCANNONLEVEL - 1] of string = (
    '',
    'Level 2 %s Acquired',
    '1 Powerup required for next level',
    'Level 3 %s Acquired',
    '2 Powerups required for next level',
    '1 Powerup required for next level',
    'Level 4 %s Acquired'
  );
  S_NEUTRONCANNONS = 'Neutron Cannons';
  S_NEUTRONSPREADER = 'Neutron Spreader';
  S_ENHANCEDEPC = 'Enchanced EPC aquired';
  S_SUPEREPC = 'Super EPC aquired';

var
  radix_actors: IRadixActorTable = nil;
  // the Radix part of each mobjinfo; hasinfo tells the ones that have one
  radixmobjinfo: array of TRadixActorInfo;
  radixmobjhasinfo: array of boolean;

//==============================================================================
//
// RX_ConfigureActors
//
//==============================================================================
procedure RX_ConfigureActors(const ATable: IRadixActorTable);
begin
  radix_actors := ATable;
end;

//==============================================================================
//
// RX_InitActors
//
//==============================================================================
procedure RX_InitActors;
var
  i: integer;
  thruspecies: boolean;
  patrol: integer;
begin
  if radix_actors = nil then
    I_Error('RX_InitActors(): RX_ConfigureActors() was not called');

  // On, as in Rad-X, now that the damage to the craft is the scale of P_DamageMobj of Rad-X (the
  // option turns it off, for the comparison)
  thruspecies := M_CheckParm(THRUSPECIES_OPTION) = 0;

  SetLength(radixmobjinfo, nummobjtypes);
  SetLength(radixmobjhasinfo, nummobjtypes);
  for i := 0 to nummobjtypes - 1 do
  begin
    radixmobjhasinfo[i] := radix_actors.TryGet(Info_GetMobjName(i), radixmobjinfo[i]);
    // a thing that only a patch describes (the fields of Rad-X of a Thing block with a number)
    if not radixmobjhasinfo[i] then
      radixmobjhasinfo[i] := radix_actors.TryGetByNumber(i, radixmobjinfo[i]);
    if radixmobjhasinfo[i] then
    begin
      if TRadixActorFlag.CustomPickup in radixmobjinfo[i].Flags then
        mobjinfo[i].flags := mobjinfo[i].flags and not MF_SPECIAL;
      // MF3_EX_DONTBLOCKSPECIES of Rad-X is the "thru species" flag that the engine has now
      // (PIT_CheckThing): things of the same kind, or with the same ancestor, do not block each
      // other. Rad-X let any two things with the flag through (TRadixContactRules.PassesSpecies)
      if thruspecies and (TRadixActorFlag.DontBlockSpecies in radixmobjinfo[i].Flags) then
        mobjinfo[i].flags3_ex := mobjinfo[i].flags3_ex or MF3_EX_THRUSPECIES;
      // MF3_EX_LIMITPATROLRANGE / PatrolRange of Rad-X (P_LookForPlayers): a limit on the distance
      // of the pilot an enemy can pick is what "max target range" of the engine already is, so
      // P_LookForPlayers needs no change (TRadixContactRules.MaxTargetRange)
      patrol := TRadixContactRules.MaxTargetRange(TRadixActorFlag.LimitPatrolRange in radixmobjinfo[i].Flags,
        radixmobjinfo[i].PatrolRange);
      if patrol > 0 then
        mobjinfo[i].maxtargetrange := patrol;
    end;
  end;
end;

//==============================================================================
//
// RX_ActorTouchDamage
//
//==============================================================================
function RX_ActorTouchDamage(const mobjtype: integer): integer;
begin
  result := 0;
  if (mobjtype < 0) or (mobjtype >= Length(radixmobjhasinfo)) then
    exit;
  if radixmobjhasinfo[mobjtype] then
    result := radixmobjinfo[mobjtype].TouchDamage;
end;

//==============================================================================
//
// RX_ActorSkyFlight
//
//==============================================================================
procedure RX_ActorSkyFlight(const mobjtype: integer; out thrusky, preventthrusky: boolean);
begin
  thrusky := false;
  preventthrusky := false;
  if (mobjtype < 0) or (mobjtype >= Length(radixmobjhasinfo)) then
    exit;
  if radixmobjhasinfo[mobjtype] then
  begin
    thrusky := TRadixActorFlag.ThruSky in radixmobjinfo[mobjtype].Flags;
    preventthrusky := TRadixActorFlag.PreventThruSky in radixmobjinfo[mobjtype].Flags;
  end;
end;

//==============================================================================
//
// RX_ActorCanDamageWalls
//
//==============================================================================
function RX_ActorCanDamageWalls(const mobjtype: integer): boolean;
begin
  result := false;
  if (mobjtype < 0) or (mobjtype >= Length(radixmobjhasinfo)) then
    exit;
  if radixmobjhasinfo[mobjtype] then
    result := TRadixActorFlag.CanDamageWalls in radixmobjinfo[mobjtype].Flags;
end;

//==============================================================================
//
// RX_ReadInventory
//
//==============================================================================
procedure RX_ReadInventory(const p: Pplayer_t; const rp: Pradixplayer_t; out inv: TRadixInventory);
var
  i: integer;
begin
  inv.Shield := p.health;
  inv.Armor := p.armorpoints;
  inv.Energy := rp.energy;
  inv.EnergyReserve := rp.energy_reserve;
  for i := 0 to RADIX_AMMO_TYPES - 1 do
  begin
    inv.Ammo[i] := p.ammo[i];
    inv.MaxAmmo[i] := p.maxammo[i];
  end;
  for i := 0 to RADIX_WEAPONS - 1 do
    inv.WeaponOwned[i] := p.weaponowned[i] <> 0;
  inv.PendingWeapon := -1;
  inv.Powers[TRadixPowerUp.RapidShield] := rp.radixpowers[Ord(rpu_rapidshield)];
  inv.Powers[TRadixPowerUp.RapidEnergy] := rp.radixpowers[Ord(rpu_rapidenergy)];
  inv.Powers[TRadixPowerUp.ManeuverJets] := rp.radixpowers[Ord(rpu_maneuverjets)];
  inv.Powers[TRadixPowerUp.NightVision] := rp.radixpowers[Ord(rpu_nightvision)];
  inv.Powers[TRadixPowerUp.Alds] := rp.radixpowers[Ord(rpu_alds)];
  inv.PlasmaBombs := rp.plasmabombs;
  inv.NeutronCannonLevel := rp.neutroncannonlevel;
  inv.NeutronSpreaderLevel := rp.neutronspreaderlevel;
end;

//==============================================================================
//
// RX_WriteInventory
//
//==============================================================================
procedure RX_WriteInventory(const p: Pplayer_t; const rp: Pradixplayer_t; const inv: TRadixInventory);
var
  i: integer;
begin
  p.health := inv.Shield;
  if p.mo <> nil then
    p.mo.health := inv.Shield;
  p.armorpoints := inv.Armor;
  p.armortype := (inv.Armor + 99) div 100;
  rp.energy := inv.Energy;
  rp.energy_reserve := inv.EnergyReserve;
  for i := 0 to RADIX_AMMO_TYPES - 1 do
    p.ammo[i] := inv.Ammo[i];
  for i := 0 to RADIX_WEAPONS - 1 do
    p.weaponowned[i] := Ord(inv.WeaponOwned[i]);
  if inv.PendingWeapon >= 0 then
    p.pendingweapon := weapontype_t(inv.PendingWeapon);
  rp.radixpowers[Ord(rpu_rapidshield)] := inv.Powers[TRadixPowerUp.RapidShield];
  rp.radixpowers[Ord(rpu_rapidenergy)] := inv.Powers[TRadixPowerUp.RapidEnergy];
  rp.radixpowers[Ord(rpu_maneuverjets)] := inv.Powers[TRadixPowerUp.ManeuverJets];
  rp.radixpowers[Ord(rpu_nightvision)] := inv.Powers[TRadixPowerUp.NightVision];
  rp.radixpowers[Ord(rpu_alds)] := inv.Powers[TRadixPowerUp.Alds];
  rp.plasmabombs := inv.PlasmaBombs;
  rp.neutroncannonlevel := inv.NeutronCannonLevel;
  rp.neutronspreaderlevel := inv.NeutronSpreaderLevel;
end;

//==============================================================================
//
// RX_PilotLimits
//
//==============================================================================
function RX_PilotLimits: TRadixPilotLimits;
begin
  result := TRadixPilotLimits.Default;
  result.SpawnShield := PLAYERSPAWNSHIELD;
  result.SpawnEnergy := PLAYERSPAWNENERGY;
end;

var
  pickuptoucher: Pmobj_t;
  pickupfound: Pmobj_t;

//==============================================================================
//
// PIT_FindRadixPickup
// The first custom pickup that the craft touches
//
//==============================================================================
function PIT_FindRadixPickup(thing: Pmobj_t): boolean;
var
  blockdist: fixed_t;
  delta: fixed_t;
begin
  result := true;
  if (thing._type < 0) or (thing._type >= Length(radixmobjhasinfo)) then
    exit;
  if not radixmobjhasinfo[thing._type] then
    exit;
  if not (TRadixActorFlag.CustomPickup in radixmobjinfo[thing._type].Flags) then
    exit;

  blockdist := thing.radius + pickuptoucher.radius;
  if (abs(thing.x - pickuptoucher.x) >= blockdist) or (abs(thing.y - pickuptoucher.y) >= blockdist) then
    exit;

  delta := thing.z - pickuptoucher.z;
  if (delta > pickuptoucher.height) or (delta < -thing.height) then
    exit; // out of reach

  pickupfound := thing;
  result := false;
end;

//==============================================================================
//
// RX_PilotTouchPickups
//
//==============================================================================
procedure RX_PilotTouchPickups(const p: Pplayer_t; const rp: Pradixplayer_t);
var
  xl, xh, yl, yh: integer;
  bx, by: integer;
  r: fixed_t;
  inv: TRadixInventory;
  info: TRadixActorInfo;
  res: TRadixPickupResult;
  special: Pmobj_t;
begin
  if rp.lastbonustime = TTickState.LevelTime then
    exit;

  pickuptoucher := p.mo;
  pickupfound := nil;
  r := p.mo.radius + MAXRADIUS;
  xl := MapBlockIntX(int64(p.mo.x) - r - int64(bmaporgx));
  xh := MapBlockIntX(int64(p.mo.x) + r - int64(bmaporgx));
  yl := MapBlockIntY(int64(p.mo.y) - r - int64(bmaporgy));
  yh := MapBlockIntY(int64(p.mo.y) + r - int64(bmaporgy));
  for bx := xl to xh do
  begin
    for by := yl to yh do
      if not P_BlockThingsIterator(bx, by, PIT_FindRadixPickup) then
        break;
    if pickupfound <> nil then
      break;
  end;

  special := pickupfound;
  if special = nil then
    exit;

  info := radixmobjinfo[special._type];
  RX_ReadInventory(p, rp, inv);
  res := TRadixPilotRules.Pickup(info, mobjinfo[special._type].doomednum, TGameSession.GameEpisode,
    TGameSession.GameSkill = sk_nightmare, RX_PilotLimits, inv);
  if not res.Taken then
    exit;
  RX_WriteInventory(p, rp, inv);

  rp.lastbonustime := TTickState.LevelTime;
  case res.Message of
    TRadixPickupMessage.NeutronCannons:
      p._message := ShortString(Format(neutronlevelmessages[rp.neutroncannonlevel], [S_NEUTRONCANNONS]));
    TRadixPickupMessage.NeutronSpreader:
      p._message := ShortString(Format(neutronlevelmessages[rp.neutronspreaderlevel], [S_NEUTRONSPREADER]));
    TRadixPickupMessage.EnhancedEpc:
      p._message := S_ENHANCEDEPC;
    TRadixPickupMessage.SuperEpc:
      p._message := S_SUPEREPC;
  else
    p._message := ShortString(info.PickupMessage);
  end;

  if special.flags and MF_COUNTITEM <> 0 then
    p.itemcount := p.itemcount + 1;
  P_RemoveMobj(special);
  p.bonuscount := p.bonuscount + BONUSADD;
  if (p = @TGameSession.Players[TGameSession.ConsolePlayer]) and (info.PickupSound <> '') then
    S_StartSound(nil, info.PickupSound);
end;

//==============================================================================
//
// RX_PilotInventoryTick
//
//==============================================================================
procedure RX_PilotInventoryTick(const p: Pplayer_t);
var
  rp: Pradixplayer_t;
  inv: TRadixInventory;
  limits: TRadixPilotLimits;
begin
  rp := RX_PlayerState(p);
  limits := RX_PilotLimits;

  if rp.energyweaponfiretics > 0 then
    dec(rp.energyweaponfiretics);

  RX_ReadInventory(p, rp, inv);
  TRadixPilotRules.TickPowers(inv);
  TRadixPilotRules.Regenerate(TTickState.LevelTime, p.damagecount <> 0, rp.energyweaponfiretics > 0, limits, inv);
  RX_WriteInventory(p, rp, inv);
  rp.threat := TRadixPilotRules.Threat(p.health, limits);

  RX_PilotTouchPickups(p, rp);
end;

end.
