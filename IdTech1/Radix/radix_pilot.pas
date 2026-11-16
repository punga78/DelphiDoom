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
//  Radix: the flight of the craft (the part of P_MovePlayer and G_PlayerReborn
//  that Rad-X changed). The player code of Doom is not touched: a thinker of the
//  level runs after it at every tic and
//   - makes the player of Doom a craft when a body is born (weapons, armour,
//     energy; the thrust in the air is the "low gravity" flight that the engine
//     already has);
//   - applies the drag and the climb/dive of the pitch (TRadixFlightModel).
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit radix_pilot;

interface

//==============================================================================
//
// RX_SpawnPilotThinker
// Adds the thinker of the crafts to the level that has just been loaded, or to
// the one of a saved game that the engine has just read; nothing when the level
// already has it
//
//==============================================================================
procedure RX_SpawnPilotThinker;

var
  // For how many tics each craft was stopped by a wall in this level (wallhits of the player_t of
  // Rad-X): the debriefing takes them from the "proficient flying" mark
  radixwallhits: array[0..3] of integer;

implementation

uses
  d_delphi,
  doomdef,
  d_player,
  d_think,
  d_ticcmd,
  d_englsh,
  g_game,
  m_argv,
  m_fixed,
  tables,
  p_genlin,
  p_map,
  p_mobj_h,
  p_tick,
  r_defs,
  r_main,
  z_zone,
  radix_playerstate,
  radix_pickups,
  radix_weapons,
  radix_controls,
  radix_pilotsound,
  radix_physics,
  radix_statelog,
  DelphiDoom.Radix.Control.Rules,
  DelphiDoom.Radix.Flight.Model,
  DelphiDoom.Radix.Messages;

type
  radixpilot_t = record
    thinker: thinker_t;
  end;
  Pradixpilot_t = ^radixpilot_t;

  // the body a craft had at the end of the tic before
  pilotlastmove_t = record
    mo: Pmobj_t;
  end;

const
  STARTUPMESSAGETICS = 2;

var
  pilotlastmoves: array[0..MAXPLAYERS - 1] of pilotlastmove_t;

//==============================================================================
//
// RX_PilotStartup
// The hits of a craft against the walls are counted where the engine blocks the move
// (TPhysicsExtension.PlayerHitWall); here only the message of a craft at the start of a level
// (P_SpawnPlayer of Rad-X)
//
//==============================================================================
procedure RX_PilotStartup(const pnum: integer; const p: Pplayer_t);
var
  last: ^pilotlastmove_t;
begin
  last := @pilotlastmoves[pnum];
  // a saved game that is loaded has a new body too, later in the level
  if (last.mo <> p.mo) and (TTickState.LevelTime <= STARTUPMESSAGETICS) then
    p._message := ShortString(TRadixMessages.StartUp(TGameSession.GameEpisode, TGameSession.GameMap));
  last.mo := p.mo;
end;

//==============================================================================
//
// RX_PlayerBecomesCraft
// What G_PlayerReborn of Rad-X gave to a new pilot
//
//==============================================================================
procedure RX_PlayerBecomesCraft(const p: Pplayer_t);
var
  i: integer;
begin
  RX_ResetPlayerState(p);
  p.armorpoints := PLAYERSPAWNARMOR;
  p.armortype := p.armorpoints div 100;
  // the neutron cannons are the first weapon (the slot of the fist of Doom) and need no ammo
  for i := 0 to Ord(NUMWEAPONS) - 1 do
    p.weaponowned[i] := 0;
  p.weaponowned[Ord(rwp_neutroncannons)] := 1;
  p.readyweapon := weapontype_t(Ord(rwp_neutroncannons));
  p.pendingweapon := weapontype_t(Ord(rwp_neutroncannons));
  for i := 0 to Ord(NUMAMMO) - 1 do
    p.ammo[i] := 0;
  // for the tests at runtime: at the skills of a script no plasma bomb of E1M1 can be reached
  i := M_CheckParm('-radixbombs');
  if (i > 0) and (i < myargc - 1) then
    RX_PlayerState(p).plasmabombs := atoi(myargv[i + 1]);
end;

//==============================================================================
//
// RX_PilotFly
//
//==============================================================================
procedure RX_PilotFly(const p: Pplayer_t; const rp: Pradixplayer_t);
var
  pmo: Pmobj_t;
  has_mj: boolean;
  an: angle_t;
  xyspeed: fixed_t;
  newthrust: fixed_t;
begin
  pmo := p.mo;

  // the engine thrusts a player in the air only in its "low gravity" flight
  p.cheats := p.cheats or CF_LOWGRAVITY;
  pmo.flags := pmo.flags or MF_NOGRAVITY;

  // what hits a craft is scaled by the skill and by a random factor in TInterGameRules.DamageMobj
  // (the hook ScalesPlayerDamage of DelphiDoom.Engine.World.PhysicsExtension), as in P_DamageMobj
  // of Rad-X: the approximation that stood here (MF_EX_FIRERESIST, half the damage) is gone

  has_mj := rp.radixpowers[Ord(rpu_maneuverjets)] > 0;
  pmo.momx := TRadixFlightModel.Drag(pmo.momx, has_mj);
  pmo.momy := TRadixFlightModel.Drag(pmo.momy, has_mj);

  newthrust := 0;
  if p.lookdir16 <> 0 then
  begin
    an := (R_PointToAngle2(0, 0, pmo.momx, pmo.momy) - pmo.angle) shr FRACBITS;
    xyspeed := FixedMul(FixedSqrt(FixedMul(pmo.momx, pmo.momx) + FixedMul(pmo.momy, pmo.momy)), fixedcosine[an]);
    newthrust := TRadixFlightModel.PitchThrust(xyspeed, p.lookdir16);
  end;
  pmo.momz := TRadixFlightModel.VerticalMomentum(pmo.momz, rp.thrustmomz, newthrust);
  rp.thrustmomz := newthrust;

  // the keys "fly up" and "fly down" of Rad-X are the jump and the crouch keys of the engine: its
  // ticcmd has no field for them (the jump of Doom pushes up only when the key goes down)
  if p.cmd.jump_crouch and CMD_JUMP_MASK <> 0 then
    pmo.momz := TRadixFlightModel.FLY_KEY_SPEED
  else if p.cmd.jump_crouch and CMD_CROUCH_MASK <> 0 then
    pmo.momz := -TRadixFlightModel.FLY_KEY_SPEED;
end;

//==============================================================================
//
// RX_PilotControls
// The afterburner and the plasma bomb (the bits of the ticcmd of radix_controls).
// Rad-X made the ticcmd of the afterburner larger (70 instead of 50) and its
// P_MovePlayer had no top speed; P_MovePlayer of Doom stops a flying player at
// 18 units a tic, so a larger thrust would change nothing: the craft slides
// 2/5 farther along its momentum instead (the same ratio, 70 / 50).
// The energy is asked again here: a ticcmd of a script (-autoscript) has not
// passed through RX_TiccmdKeys
//
//==============================================================================
procedure RX_PilotControls(const p: Pplayer_t; const rp: Pradixplayer_t);
var
  pmo: Pmobj_t;
begin
  pmo := p.mo;

  rp.afterburner := TRadixControlRules.AfterburnerOn(p.cmd.jump_crouch and RXCMD_AFTERBURNER <> 0,
    rp.energy, p.cmd.forwardmove, p.cmd.sidemove);
  if rp.afterburner then
  begin
    TRadixControlRules.DrainAfterburner(TTickState.LevelTime, rp.energy_reserve, rp.energy);
    // a wall in the way: no slide, the move of the engine has already found it
    P_TryMove(pmo,
      pmo.x + TRadixControlRules.AfterburnerSlide(pmo.momx),
      pmo.y + TRadixControlRules.AfterburnerSlide(pmo.momy));
  end;

  if TRadixControlRules.PlasmaBombAsked(p.cmd.jump_crouch and RXCMD_PLASMABOMB <> 0, rp.plasmabombdown) then
    RX_FirePlasmaBomb(p);
end;

//==============================================================================
//
// RX_PilotFindsSecret
// JVAL: 20200409 - Secret sector handling does not require to be on ground.
// P_PlayerInSpecialSector of Doom looks at the sector only when the player
// stands on its floor, and a craft never does: the secret sectors of Radix
// (RA_SecretSprite marks them with the generalized type) are counted here
//
//==============================================================================
procedure RX_PilotFindsSecret(const p: Pplayer_t);
var
  sec: Psector_t;
begin
  sec := Psubsector_t(p.mo.subsector).sector;
  if sec.special and SECRET_MASK = 0 then
    exit;
  inc(p.secretcount);
  p._message := ShortString(MSGSECRETSECTOR);
  sec.special := sec.special and not SECRET_MASK;
  if sec.special < 32 then // if all extended bits clear,
    sec.special := 0;      // sector is not special anymore
end;

//==============================================================================
//
// T_RadixPilot
//
//==============================================================================
procedure T_RadixPilot(pilot: Pradixpilot_t);
var
  i: integer;
  p: Pplayer_t;
begin
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
    begin
      p := @players[i];
      if p.mo = nil then
        continue;
      // G_PlayerReborn clears the whole player and a level that ends does not: the flag of the
      // backpack of Doom (Radix has no backpack) tells a pilot that is already a craft, and it
      // goes into the savegames with the player
      if not p.backpack then
      begin
        p.backpack := true;
        RX_PlayerBecomesCraft(p);
      end;
      if p.playerstate = PST_LIVE then
      begin
        RX_PilotStartup(i, p);
        RX_PilotImpacts(i, p);
        RX_PilotFly(p, RX_PlayerState(p));
        RX_PilotControls(p, RX_PlayerState(p));
        RX_PilotFindsSecret(p);
        RX_PilotInventoryTick(p);
        RX_PilotWeaponsTick(p);
        RX_PilotEngineSound(i, p, RX_PlayerState(p));
        RX_PilotSiren(i, p, RX_PlayerState(p));
      end;
    end;
  RX_StateLogTick;
end;

//==============================================================================
//
// RX_SpawnPilotThinker
//
//==============================================================================
procedure RX_SpawnPilotThinker;
var
  pilot: Pradixpilot_t;
  think: Pthinker_t;
begin
  // one for a level: a saved game that is loaded asks again (the engine frees the thinkers it
  // does not know when it loads its own)
  think := TTickState.ThinkerCap.next;
  while think <> @TTickState.ThinkerCap do
  begin
    if @think._function.acp1 = @T_RadixPilot then
      exit;
    think := think.next;
  end;

  // a level that starts (a saved game puts its count back after this)
  ZeroMemory(@radixwallhits, SizeOf(radixwallhits));
  ZeroMemory(@pilotlastmoves, SizeOf(pilotlastmoves));
  RX_PilotSoundsReset;
  RX_PhysicsReset;

  pilot := Z_Malloc(SizeOf(radixpilot_t), PU_LEVSPEC, nil);
  P_AddThinker(@pilot.thinker);
  pilot.thinker._function.acp1 := @T_RadixPilot;
end;

end.
