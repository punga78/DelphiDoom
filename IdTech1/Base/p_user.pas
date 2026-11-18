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
// P_DeathThink
// Fall on your face when dying.
// Decrease POV height to floor height.
//
//==============================================================================
procedure P_DeathThink(player: Pplayer_t);

//==============================================================================
//
// P_MovePlayer
//
//==============================================================================
procedure P_MovePlayer(player: Pplayer_t);

//==============================================================================
//
// P_Thrust
// Moves the given origin along a given angle.
//
//==============================================================================
procedure P_Thrust(player: Pplayer_t; angle: angle_t; const move: fixed_t);

implementation

uses
  d_delphi,
  g_game,
  p_common,
  p_local,
  p_tick,
  p_3dfloors, // JVAL: Slopes
  r_defs,
  r_main,
  p_pspr,
  d_ticcmd,
  d_event,
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
        player.lastautocrouchtime := TTickState.LevelTime;
        player.lastongroundtime := TTickState.LevelTime;
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

  angle := (FINEANGLES div 20 * TTickState.LevelTime) and FINEMASK;
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

  angle := (FINEANGLES div 20 * TTickState.LevelTime) and FINEMASK;
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

  angle := (FINEANGLES div 20 * TTickState.LevelTime) and FINEMASK;
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

//
// P_DeathThink
// Fall on your face when dying.
// Decrease POV height to floor height.
//
const
  ANG5 = ANG90 div 18;
  ANG355 = ANG270 +  ANG5 * 17; // add by JVAL

//==============================================================================
//
// P_DeathThink
//
//==============================================================================
procedure P_DeathThink(player: Pplayer_t);
var
  angle: angle_t;
  delta: angle_t;
begin
  if TUserGameRules.OwnsDeathThink then
  begin
    TUserGameRules.DeathThink(player);
    exit;
  end;

  P_MovePsprites(player);

  // fall to the ground
  if player.viewheight > 6 * FRACUNIT then
    player.viewheight := player.viewheight - FRACUNIT;

  if player.viewheight < 6 * FRACUNIT then
    player.viewheight := 6 * FRACUNIT;

  if player.viewheight > 6 * FRACUNIT then
    if player.lookdir < 45 then
    begin
      player.lookdir := player.lookdir + 5;
      player.lookdir16 := player.lookdir * 16; // JVAL Smooth Look Up/Down
    end;

  player.deltaviewheight := 0;
  onground := player.mo.z <= player.mo.floorz;
  P_SlopesCalcHeight(player); // JVAL: Slopes

  if (player.attacker <> nil) and (player.attacker <> player.mo) then
  begin

    angle := TRendererMain.R_PointToAngle2(
      player.mo.x, player.mo.y, player.attackerx, player.attackery);

    delta := angle - player.mo.angle;

    if (delta < ANG5) or (delta > ANG355) then
    begin
      // Looking at killer,
      //  so fade damage flash down.
      player.mo.angle := angle;

      if player.damagecount <> 0 then
        player.damagecount := player.damagecount - 1;
    end
    else if delta < ANG180 then
      player.mo.angle := player.mo.angle + ANG5
    else
      player.mo.angle := player.mo.angle - ANG5;

  end
  else if player.damagecount <> 0 then
    player.damagecount := player.damagecount - 1;

  if player.cmd.buttons and BT_USE <> 0 then
    player.playerstate := PST_REBORN;
end;

//==============================================================================
//
// P_JumpAndCrouch
// The jump and the crouch of a move (JVAL: 20211101 - Crouch)
//
//==============================================================================
procedure P_JumpAndCrouch(player: Pplayer_t; const cmd_jump, cmd_crouch: byte);
begin
  if (onground or (player.cheats and CF_LOWGRAVITY <> 0)) and (cmd_jump > 1) then
  begin
    // JVAL: 20211101 - Crouch
    if cmd_crouch > 0 then
      player.mo.momz := 4 * FRACUNIT
    else
      player.mo.momz := 8 * FRACUNIT;
  end;

  // JVAL: 20211101 - Crouch
  if (TTickState.LevelTime - player.lastongroundtime < TICRATE) and (cmd_crouch <> 0) then
  begin
    player.crouchheight := player.crouchheight + cmd_crouch * FRACUNIT;
    if player.crouchheight > PMAXCROUCHHEIGHT then
      player.crouchheight := PMAXCROUCHHEIGHT;
  end
  else if (TTickState.LevelTime - player.lastautocrouchtime > TICRATE) and (player.crouchheight <> 0) then
  begin
    player.crouchheight := player.crouchheight - 2 * FRACUNIT;
    if player.crouchheight < 0 then
      player.crouchheight := 0;
  end;
  if not onground and (cmd_crouch <> 0) then
    if player.mo.momz > -4 * FRACUNIT then
    begin
      player.mo.momz := player.mo.momz - FRACUNIT div 2;
      if player.mo.momz < -4 * FRACUNIT then
        player.mo.momz := -4 * FRACUNIT;
    end;
end;

//==============================================================================
//
// P_MovePlayer
//
//==============================================================================
procedure P_MovePlayer(player: Pplayer_t);
var
  cmd: Pticcmd_t;
  look: integer;
  look16: integer; // JVAL Smooth Look Up/Down
  look2: integer;
  cmd_crouch, cmd_jump: byte;
begin
  cmd := @player.cmd;

  player.mo.angle := player.mo.angle + _SHLW(cmd.angleturn, 16);

  // Do not let the player control movement
  //  if not onground.
  TUserGameRules.SetOnGround(player);

  if onground then
    player.lastongroundtime := TTickState.LevelTime; // JVAL: 20211101 - Crouch

  // JVAL: 20220225 - NOJUMP sector flag (UDMF)
  if Psubsector_t(player.mo.subsector).sector.flags and SF_NOJUMP <> 0 then
    cmd_jump := 0
  else if TUserGameRules.MapNoJump then
    cmd_jump := 0
  else
    cmd_jump := (cmd.jump_crouch and CMD_JUMP_MASK) shr CMD_JUMP_SHIFT;

  // JVAL: 20220226 - NOCROUCH sector flag (UDMF)
  if Psubsector_t(player.mo.subsector).sector.flags and SF_NOCROUCH <> 0 then
    cmd_crouch := 0
  else if TUserGameRules.MapNoCrouch then
    cmd_crouch := 0
  else
    cmd_crouch := (cmd.jump_crouch and CMD_CROUCH_MASK) shr CMD_CROUCH_SHIFT;

  TUserGameRules.MoveByCommand(player, cmd, cmd_jump, cmd_crouch);

// JVAL Look UP and DOWN
  if zaxisshift then
  begin
    if G_PlayingEngineVersion < VERSION203 then // JVAL Smooth Look Up/Down
    begin
      look := TUserGameRules.LookUpDown(cmd);
      if look > 7 then
        look := look - 16;

      if TUserGameRules.AimsAtTarget(player) then
        player.centering := true
      else if look <> 0 then
      begin
        if look = TOCENTER then
          player.centering := true
        else
        begin
          player.lookdir := player.lookdir + 5 * look;
          if player.lookdir > MAXLOOKDIR then
            player.lookdir := MAXLOOKDIR
          else if player.lookdir < MINLOOKDIR then
            player.lookdir := MINLOOKDIR;
        end;
      end;
      player.lookdir16 := player.lookdir * 16;
    end
    else
    begin // JVAL Smooth Look Up/Down
      look16 := cmd.lookupdown16;
      if look16 > 7 * 256 then
        look16 := look16 - 16 * 256;

      if TUserGameRules.AimsAtTarget(player) then
        player.centering := true
      else if look16 <> 0 then
      begin
        if look16 = TOCENTER * 256 then
          player.centering := true
        else
        begin
          player.lookdir16 := player.lookdir16 + Round(5 * look16 / 16);
          player.lookdir := player.lookdir16 div 16;

          if player.lookdir16 > MAXLOOKDIR * 16 then
            player.lookdir16 := MAXLOOKDIR * 16
          else if player.lookdir16 < MINLOOKDIR * 16 then
            player.lookdir16 := MINLOOKDIR * 16;

          if player.lookdir > MAXLOOKDIR then
            player.lookdir := MAXLOOKDIR
          else if player.lookdir < MINLOOKDIR then
            player.lookdir := MINLOOKDIR;
        end;
      end;
    end;

    if player.centering then
    begin
      if G_PlayingEngineVersion < VERSION203 then // JVAL Smooth Look Up/Down
      begin
        if player.lookdir > 0 then
          player.lookdir := player.lookdir - 8
        else if player.lookdir < 0 then
          player.lookdir := player.lookdir + 8;

        if abs(player.lookdir) < 8 then
        begin
          player.lookdir := 0;
          player.centering := false;
        end;

        player.lookdir16 := player.lookdir * 16;
      end
      else
      begin // JVAL Smooth Look Up/Down
        if player.lookdir16 > 0 then
          player.lookdir16 := player.lookdir16 - 8 * 16
        else if player.lookdir16 < 0 then
          player.lookdir16 := player.lookdir16 + 8 * 16;

        if abs(player.lookdir16) < 8 * 16 then
        begin
          player.lookdir16 := 0;
          player.centering := false;
        end;

        player.lookdir := player.lookdir16 div 16;
      end;
    end;
  end;

  if not G_NeedsCompatibilityMode then
  begin
  // JVAL Look LEFT and RIGHT
    look2 := cmd.lookleftright;
    if look2 > 7 then
      look2 := look2 - 16;

    if TUserGameRules.AimsAtTarget(player) then
      player.forwarding := true
    else if look2 <> 0 then
    begin
      if look2 = TOFORWARD then
        player.forwarding := true
      else
      begin
        player.lookdir2 := (player.lookdir2 + 2 * look2) and 255;
        if player.lookdir2 in [64..127] then
          player.lookdir2 := 63
        else if player.lookdir2 in [128..191] then
          player.lookdir2 := 192;
      end;
    end
    else
      if player.oldlook2 <> 0 then
        player.forwarding := true;

    if player.forwarding then
    begin
      if player.lookdir2 in [3..63] then
        player.lookdir2 := player.lookdir2 - 6
      else if player.lookdir2 in [192..251] then
        player.lookdir2 := player.lookdir2 + 6;

      if (player.lookdir2 < 8) or (player.lookdir2 > 247) then
      begin
        player.lookdir2 := 0;
        player.forwarding := false;
      end;
    end;
    player.mo.viewangle := player.lookdir2 shl 24;

    player.oldlook2 := look2;

    if not TUserGameRules.JumpsAlways then
      P_JumpAndCrouch(player, cmd_jump, cmd_crouch);
  end
  else
    player.lookdir2 := 0;

  if TUserGameRules.JumpsAlways then
    P_JumpAndCrouch(player, cmd_jump, cmd_crouch);

  TUserGameRules.AfterMove(player, cmd);
end;

end.
