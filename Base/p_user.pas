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
//  Player related stuff.
//  Bobbing POV/weapon, movement.
//  Pending weapon.
//
//  One copy for the four games (issue #185, step 2f-1). What a game does
//  differently is in TUserGameRules, the class of the unit
//  DelphiDoom.Engine.World.UserRules of the folder of the game (chosen by
//  the project: static calls, no virtual call and no interface in this path).
//  The routines are the ones of Doom: the rules add what the other games do
//  at the same place (the text of a rule is the text of the old routine).
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_user;

interface

uses
  m_fixed,
  tables,
  p_mobj_h,
  d_player;

var
  /// The player stands on the floor or on a thing: written by P_MovePlayer and
  /// P_DeathThink, read by the P_CalcHeight routines (the state of the old
  /// unit, moved as it was: there is no other copy)
  onground: boolean;

//==============================================================================
//
// P_PlayerThink
//
//==============================================================================
procedure P_PlayerThink(player: Pplayer_t);

//==============================================================================
//
// P_CalcHeight
// Calculate the walking / running height adjustment
//
//==============================================================================
procedure P_CalcHeight(player: Pplayer_t);

//==============================================================================
//
// P_SlopesCalcHeight
//
// JVAL: Slopes
//
//==============================================================================
procedure P_SlopesCalcHeight(player: Pplayer_t);

//==============================================================================
//
// P_Thrust
// Moves the given origin along a given angle.
//
//==============================================================================
procedure P_Thrust(player: Pplayer_t; angle: angle_t; const move: fixed_t);

implementation

uses
  g_game,
  p_local,
  p_tick,
  p_3dfloors, // JVAL: Slopes
  r_defs,
  doomdef,
  DelphiDoom.Engine.World.MapRules,
  DelphiDoom.Engine.World.UserRules;

//
// Movement.
//
const
// 16 pixels of bob
  MAXBOB = $100000;

//==============================================================================
//
// P_PlayerThink
//
//==============================================================================
procedure P_PlayerThink(player: Pplayer_t);
begin
  TUserGameRules.PlayerThink(player);
end;

//==============================================================================
//
// P_Thrust
// Moves the given origin along a given angle.
//
//==============================================================================
procedure P_Thrust(player: Pplayer_t; angle: angle_t; const move: fixed_t);
begin
  {$IFDEF FPC}
  angle := _SHRW(angle, ANGLETOFINESHIFT);
  {$ELSE}
  angle := angle shr ANGLETOFINESHIFT;
  {$ENDIF}

  player.mo.momx := player.mo.momx + FixedMul(TUserGameRules.ThrustMove(player, move), finecosine[angle]);
  player.mo.momy := player.mo.momy + FixedMul(TUserGameRules.ThrustMove(player, move), finesine[angle]);
end;

//==============================================================================
//
// P_CalcHeight
// Calculate the walking / running height adjustment
//
//==============================================================================
procedure P_CalcHeight(player: Pplayer_t);
var
  angle: integer;
  clheight: fixed_t; // JVAL: 20211101 - Crouch
  flheight: fixed_t; // JVAL: 20211101 - Crouch
  range: fixed_t; // JVAL: 20211101 - Crouch
begin
  // Regular movement bobbing
  // (needs to be calculated for gun swing
  // even if not on ground)
  // OPTIMIZE: tablify angle
  // Note: a LUT allows for effects
  //  like a ramp with low health.

  if TUserGameRules.FlyBobs(player) then
    player.bob := FRACUNIT div 2
  else
  begin
    player.bob := FixedMul(player.mo.momx, player.mo.momx) +
                  FixedMul(player.mo.momy, player.mo.momy);
    player.bob := player.bob div 4;

    if player.bob > MAXBOB then
      player.bob := MAXBOB;
  end;

  player.oldviewz := player.viewz;  // JVAL: Slopes

  // JVAL: 20211101 - Crouch
  if TUserGameRules.IsMorphed(player) then
    player.crouchheight := 0
  else
  begin
    player.mo.height := player.mo.info.height - player.crouchheight;
    clheight := P_3dCeilingHeight(player.mo);
    if player.mo.z + player.mo.height > clheight then
    begin
      flheight := P_3dFloorHeight(player.mo);
      player.mo.z := clheight - player.mo.height;
      if player.mo.z < flheight then
      begin
        player.mo.z := flheight;
        player.lastautocrouchtime := leveltime;
        player.lastongroundtime := leveltime;
        range := clheight - flheight;
        player.crouchheight := player.mo.info.height - range;
        if player.crouchheight > PMAXCROUCHHEIGHT then
          player.crouchheight := PMAXCROUCHHEIGHT;
        player.mo.height := player.mo.info.height - player.crouchheight;
      end;
    end;
  end;

  if (player.cheats and CF_NOMOMENTUM <> 0) or not onground then
  begin
    player.viewz := player.mo.z + PVIEWHEIGHT - player.crouchheight;  // JVAL: 20211101 - Crouch

    if player.viewz > player.mo.ceilingz - 4 * FRACUNIT then
      player.viewz := player.mo.ceilingz - 4 * FRACUNIT;

//    player.viewz := player.mo.z + player.viewheight;  JVAL removed!
    exit;
  end;

  angle := (FINEANGLES div 20 * leveltime) and FINEMASK;
  player.viewbob := FixedMul(player.bob div 2, finesine[angle]);

  // move viewheight
  if player.playerstate = PST_LIVE then
  begin
    player.viewheight := player.viewheight + player.deltaviewheight;

    if player.viewheight > PVIEWHEIGHT then
    begin
      player.viewheight := PVIEWHEIGHT;
      player.deltaviewheight := 0;
    end;

    if player.viewheight < PVIEWHEIGHT div 2 then
    begin
      player.viewheight := PVIEWHEIGHT div 2;
      if player.deltaviewheight <= 0 then
        player.deltaviewheight := 1;
    end;

    if player.deltaviewheight <> 0 then
    begin
      player.deltaviewheight := player.deltaviewheight + FRACUNIT div 4;
      if player.deltaviewheight = 0 then
        player.deltaviewheight := 1;
    end;
  end;

  if TUserGameRules.IsMorphed(player) then
    player.viewz := player.mo.z + player.viewheight - (20 * FRACUNIT)
  else
    player.viewz := player.mo.z + player.viewheight + player.viewbob - player.crouchheight; // JVAL: 20211101 - Crouch

  TUserGameRules.AdjustViewZ(player);

  if player.viewz > player.mo.ceilingz - 4 * FRACUNIT then
    player.viewz := player.mo.ceilingz - 4 * FRACUNIT;

  TUserGameRules.ClampViewZ(player);
end;

//==============================================================================
//
// P_CalcHeight205
//
//==============================================================================
procedure P_CalcHeight205(player: Pplayer_t);
var
  angle: integer;
begin
  // Regular movement bobbing
  // (needs to be calculated for gun swing
  // even if not on ground)
  // OPTIMIZE: tablify angle
  // Note: a LUT allows for effects
  //  like a ramp with low health.

  if TUserGameRules.FlyBobs(player) then
    player.bob := FRACUNIT div 2
  else
  begin
    player.bob := FixedMul(player.mo.momx, player.mo.momx) +
                  FixedMul(player.mo.momy, player.mo.momy);
    player.bob := player.bob div 4;

    if player.bob > MAXBOB then
      player.bob := MAXBOB;
  end;

  player.oldviewz := player.viewz;  // JVAL: Slopes

  if (player.cheats and CF_NOMOMENTUM <> 0) or not onground then
  begin
    player.viewz := player.mo.z + PVIEWHEIGHT;

    if player.viewz > player.mo.ceilingz - 4 * FRACUNIT then
      player.viewz := player.mo.ceilingz - 4 * FRACUNIT;

//    player.viewz := player.mo.z + player.viewheight;  JVAL removed!
    exit;
  end;

  angle := (FINEANGLES div 20 * leveltime) and FINEMASK;
  player.viewbob := FixedMul(player.bob div 2, finesine[angle]);

  // move viewheight
  if player.playerstate = PST_LIVE then
  begin
    player.viewheight := player.viewheight + player.deltaviewheight;

    if player.viewheight > PVIEWHEIGHT then
    begin
      player.viewheight := PVIEWHEIGHT;
      player.deltaviewheight := 0;
    end;

    if player.viewheight < PVIEWHEIGHT div 2 then
    begin
      player.viewheight := PVIEWHEIGHT div 2;
      if player.deltaviewheight <= 0 then
        player.deltaviewheight := 1;
    end;

    if player.deltaviewheight <> 0 then
    begin
      player.deltaviewheight := player.deltaviewheight + FRACUNIT div 4;
      if player.deltaviewheight = 0 then
        player.deltaviewheight := 1;
    end;
  end;

  if TUserGameRules.IsMorphed(player) then
    player.viewz := player.mo.z + player.viewheight - (20 * FRACUNIT)
  else
    player.viewz := player.mo.z + player.viewheight + player.viewbob;

  TUserGameRules.AdjustViewZ(player);

  if player.viewz > player.mo.ceilingz - 4 * FRACUNIT then
    player.viewz := player.mo.ceilingz - 4 * FRACUNIT;

  TUserGameRules.ClampViewZ(player);
end;

//==============================================================================
// P_SlopesCalcHeight
//
// JVAL: Slopes
//
//==============================================================================
procedure P_SlopesCalcHeight(player: Pplayer_t);
var
  angle: integer;
  oldviewz: fixed_t;
  oldviewz2: fixed_t;
begin
  // Regular movement bobbing
  // (needs to be calculated for gun swing
  // even if not on ground)
  // OPTIMIZE: tablify angle
  // Note: a LUT allows for effects
  //  like a ramp with low health.

  if G_PlayingEngineVersion >= VERSION207 then
  begin
    P_CalcHeight(player);
    exit;
  end;

  if (G_PlayingEngineVersion < TMapGameRules.SlopesVersion) or
     (G_PlayingEngineVersion >= VERSION205) then
  begin
    P_CalcHeight205(player);
    exit;
  end;

  if TUserGameRules.FlyBobs(player) then
    player.bob := FRACUNIT div 2
  else
  begin
    player.bob := FixedMul(player.mo.momx, player.mo.momx) +
                  FixedMul(player.mo.momy, player.mo.momy);
    player.bob := player.bob div 4;

    if player.bob > MAXBOB then
      player.bob := MAXBOB;
  end;

  oldviewz := player.viewz;

  if (player.cheats and CF_NOMOMENTUM <> 0) or not onground then
  begin
    player.viewz := player.mo.z + PVIEWHEIGHT;

    if player.viewz > player.mo.ceilingz - 4 * FRACUNIT then
      player.viewz := player.mo.ceilingz - 4 * FRACUNIT;

    if TUserGameRules.KeepsOldViewZInAir then
      player.oldviewz := oldviewz;

//    player.viewz := player.mo.z + player.viewheight;  JVAL removed!
    exit;
  end;

  angle := (FINEANGLES div 20 * leveltime) and FINEMASK;
  player.viewbob := FixedMul(player.bob div 2, finesine[angle]) div (player.slopetics + 1);

  // move viewheight
  if player.playerstate = PST_LIVE then
  begin
    player.viewheight := player.viewheight + player.deltaviewheight;

    if player.viewheight > PVIEWHEIGHT then
    begin
      player.viewheight := PVIEWHEIGHT;
      player.deltaviewheight := 0;
    end;

    if player.viewheight < PVIEWHEIGHT div 2 then
    begin
      player.viewheight := PVIEWHEIGHT div 2;
      if player.deltaviewheight <= 0 then
        player.deltaviewheight := 1;
    end;

    if player.deltaviewheight <> 0 then
    begin
      if player.slopetics > 0 then
        player.deltaviewheight := player.deltaviewheight + (FRACUNIT div 4) * player.slopetics
      else
        player.deltaviewheight := player.deltaviewheight + FRACUNIT div 4;
      if player.deltaviewheight = 0 then
        player.deltaviewheight := 1;
    end;
  end;

  if TUserGameRules.IsMorphed(player) then
    player.viewz := player.mo.z + player.viewheight - (20 * FRACUNIT)
  else if player.slopetics > 0 then
  begin
    oldviewz2 := player.oldviewz;

    player.viewz :=
      (player.slopetics * player.viewz +
       player.mo.z + player.viewheight + player.viewbob) div (player.slopetics + 1); // Extra smooth

    if oldviewz2 < oldviewz then
    begin
      if player.viewz < oldviewz then
        player.viewz := oldviewz;
    end
    else if oldviewz2 > oldviewz then
    begin
      if player.viewz > oldviewz then
        player.viewz := oldviewz;
    end;

    if player.viewz < player.mo.floorz + PVIEWHEIGHT div 2 - 4 * FRACUNIT then
      player.viewz := player.mo.floorz + PVIEWHEIGHT div 2 - 4 * FRACUNIT;
    if player.viewz < player.mo.floorz + 4 * FRACUNIT then
      player.viewz := player.mo.floorz + 4 * FRACUNIT;
  end
  else
    player.viewz := player.mo.z + player.viewheight + player.viewbob;

  TUserGameRules.AdjustViewZ(player);

  if player.viewz > player.mo.ceilingz - 4 * FRACUNIT then
    player.viewz := player.mo.ceilingz - 4 * FRACUNIT;

  if player.viewz < player.mo.floorz + TUserGameRules.SlopesFloorMargin then
    player.viewz := player.mo.floorz + TUserGameRules.SlopesFloorMargin;

  player.oldviewz := oldviewz;
end;

end.
