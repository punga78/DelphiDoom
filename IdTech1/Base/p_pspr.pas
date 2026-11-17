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
//  Sprite animation.
//  Weapon sprite animation, weapon objects.
//
//  One copy for the four games (issue #185, step 2f-3). What a game does
//  differently (the weapons and the actions of the weapons, what depends on the
//  record of the player) is in the unit
//  DelphiDoom.Engine.World.PspriteRules of the folder of the game (chosen by
//  the project: static calls, no virtual call and no interface in this path).
//  This unit has the code that the games share: the state machine of the
//  weapon sprites (P_SetPsprite) and what moves and lowers them.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_pspr;

interface

uses
// Basic data types.
// Needs fixed point, and BAM angles.
  m_fixed,
  info_h,
  p_pspr_h,
  d_player;

const
//
// Frame flags:
// handles maximum brightness (torches, muzzle flare, light sources)
//
  FF_FULLBRIGHT = $8000; // flag in thing->frame
  FF_FRAMEMASK = $7fff;

//
// Adjust weapon bottom and top
//
  WEAPONTOP = 32 * FRACUNIT;
  WEAPONBOTTOM = WEAPONTOP + 96 * FRACUNIT;

  LOWERSPEED = 6 * FRACUNIT;
  RAISESPEED = 6 * FRACUNIT;

// the most states that P_SetPsprite follows in a row (a state of 0 tics
// chains to the next one) before it takes them for an infinite cycle
  PSPR_CYCLE_LIMIT = 1000000;

//==============================================================================
//
// P_SetPsprite
//
//==============================================================================
procedure P_SetPsprite(player: Pplayer_t; position: integer; stnum: statenum_t);

//==============================================================================
//
// A_Light0
//
//==============================================================================
procedure A_Light0(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// P_DropWeapon
// The player died, so put the weapon away.
//
//==============================================================================
procedure P_DropWeapon(player: Pplayer_t);

//==============================================================================
//
// A_ReFire
// The player can re fire the weapon without lowering it entirely.
//
//==============================================================================
procedure A_ReFire(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_Lower
// Lowers current weapon, and changes weapon at bottom.
//
//==============================================================================
procedure A_Lower(player: Pplayer_t; psp: Ppspdef_t);

//==============================================================================
//
// A_Raise
//
//==============================================================================
procedure A_Raise(player: Pplayer_t; psp: Ppspdef_t);
//==============================================================================
//
// P_SetupPsprites
//
//==============================================================================
procedure P_SetupPsprites(player: Pplayer_t);

//==============================================================================
//
// P_MovePsprites
//
//==============================================================================
procedure P_MovePsprites(player: Pplayer_t);

implementation

uses
  d_delphi,
  d_event,
  doomdef,
  i_system,
  info,
  p_common,
  DelphiDoom.Engine.World.PspriteRules;

//==============================================================================
//
// P_SetPsprite
//
//==============================================================================
procedure P_SetPsprite(player: Pplayer_t; position: integer; stnum: statenum_t);
var
  psp: Ppspdef_t;
  state: Pstate_t;
  cycle_counter: integer;
begin
  cycle_counter := 0;
  psp := @player.psprites[position];
  repeat
    if Ord(stnum) = 0 then
    begin
      // object removed itself
      psp.state := nil;
      break;
    end;

    state := @states[Ord(stnum)];
    psp.state := state;
    psp.tics := P_TicsFromState(state); // could be 0

    // coordinate set
    if state.misc1 <> 0 then
      psp.sx := state.misc1 * FRACUNIT;

    if state.misc2 <> 0 then
      psp.sy := state.misc2 * FRACUNIT;

    // Call action routine.
    // Modified handling.
    if Assigned(state.action.acp2) then
    begin
      if state.params <> nil then
        state.params.actor := player.mo;
      state.action.acp2(player, psp);
      if psp.state = nil then
        break;
    end;

    stnum := psp.state.nextstate;

    inc(cycle_counter);
    if cycle_counter > PSPR_CYCLE_LIMIT then
      I_Error('P_SetPsprite(): Infinite state cycle detected in player sprites (readyweapon=%d, pendinfweapon=%d)!',
        [Ord(player.readyweapon), Ord(player.pendingweapon)]);
  until psp.tics <> 0;
  // an initial state of 0 could cycle through
end;

//==============================================================================
//
// A_Light0
//
//==============================================================================
procedure A_Light0(player: Pplayer_t; psp: Ppspdef_t);
begin
  player.extralight := 0;
end;

//==============================================================================
//
// P_DropWeapon
// The player died, so put the weapon away.
//
//==============================================================================
procedure P_DropWeapon(player: Pplayer_t);
begin
  P_SetPsprite(player, Ord(ps_weapon), TPspriteGameRules.DropWeaponState(player));
end;

//==============================================================================
//
// A_ReFire
// The player can re fire the weapon without lowering it entirely.
//
//==============================================================================
procedure A_ReFire(player: Pplayer_t; psp: Ppspdef_t);
begin
  // check for fire
  //  (if a weaponchange is pending, let it go through instead)
  if (player.cmd.buttons and BT_ATTACK <> 0) and
     (player.pendingweapon = wp_nochange) and
     (player.health > 0) then
  begin
    player.refire := player.refire + 1;
    TWeaponBaseActions.P_FireWeapon(player);
  end
  else
  begin
    player.refire := 0;
    TPspriteGameRules.CheckSupplies(player);
  end;
end;

//==============================================================================
//
// A_Lower
// Lowers current weapon, and changes weapon at bottom.
//
//==============================================================================
procedure A_Lower(player: Pplayer_t; psp: Ppspdef_t);
begin
  if TPspriteGameRules.StaysLowered(player) then
    psp.sy := WEAPONBOTTOM
  else
    psp.sy := psp.sy + LOWERSPEED;

  // Is already down.
  if psp.sy < WEAPONBOTTOM then
    exit;

  // Player is dead.
  if player.playerstate = PST_DEAD then
  begin
    psp.sy := WEAPONBOTTOM;
    // don't bring weapon back up
    exit;
  end;

  // The old weapon has been lowered off the screen,
  // so change the weapon and start raising it
  if player.health = 0 then
  begin
    // Player is dead, so keep the weapon off screen.
    P_SetPsprite(player, Ord(ps_weapon), S_NULL);
    exit;
  end;

  TPspriteGameRules.AfterLowered(player);

  player.readyweapon := player.pendingweapon;

  TWeaponBaseActions.P_BringUpWeapon(player);
end;

//==============================================================================
//
// A_Raise
//
//==============================================================================
procedure A_Raise(player: Pplayer_t; psp: Ppspdef_t);
begin
  psp.sy := psp.sy - RAISESPEED;

  if psp.sy > WEAPONTOP then // Not raised all the way yet
    exit;

  psp.sy := WEAPONTOP;

  // The weapon has been raised all the way,
  //  so change to the ready state.
  P_SetPsprite(player, Ord(ps_weapon), TPspriteGameRules.RaisedState(player));
end;
//==============================================================================
//
// P_SetupPsprites
// Called at start of level for each player.
//
//==============================================================================
procedure P_SetupPsprites(player: Pplayer_t);
var
  i: integer;
begin
  // remove all psprites
  for i := 0 to Ord(NUMPSPRITES) - 1 do
    player.psprites[i].state := nil;

  // spawn the gun
  player.pendingweapon := player.readyweapon;
  TWeaponBaseActions.P_BringUpWeapon(player);
end;

//==============================================================================
//
// P_MovePsprites
// Called every tic by player thinking routine.
//
//==============================================================================
procedure P_MovePsprites(player: Pplayer_t);
var
  i: integer;
  psp: Ppspdef_t;
  state: Pstate_t;
begin
  for i := 0 to Ord(NUMPSPRITES) - 1 do
  begin
    psp := @player.psprites[i];
    // a null state means not active
    state := psp.state;
    if state <> nil then
    begin
      // drop tic count and possibly change state
      // a -1 tic count never changes
      if psp.tics <> -1 then
      begin
        psp.tics := psp.tics - 1;
        if psp.tics = 0 then
          P_SetPsprite(player, i, psp.state.nextstate);
      end;
    end;
  end;

  player.psprites[Ord(ps_flash)].sx := player.psprites[Ord(ps_weapon)].sx;
  player.psprites[Ord(ps_flash)].sy := player.psprites[Ord(ps_weapon)].sy;

  TPspriteGameRules.AfterMovePsprites(player);
end;

end.
