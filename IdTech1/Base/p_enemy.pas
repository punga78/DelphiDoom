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
//
// DESCRIPTION:
//  Enemy thinking, AI.
//  Action Pointer Functions
//  that are associated with states/frames.
//
//  One copy for the four games (issue #185, step 2f-4). What a game does
//  differently is in TEnemyGameRules, the class of the unit
//  DelphiDoom.Engine.World.EnemyRules of the folder of the game (chosen by
//  the project: static calls, no virtual call and no interface in this path).
//  The actions of the monsters of each game (and the routines that only one
//  game has) stay in that unit.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_enemy;

interface

uses
  m_fixed,
  p_mobj_h;

//==============================================================================
//
// P_NoiseAlert
//
//==============================================================================
procedure P_NoiseAlert(target: Pmobj_t; emmiter: Pmobj_t);

//==============================================================================
//
// P_MeleeRange
//
//==============================================================================
function P_MeleeRange(actor: Pmobj_t): fixed_t;

//==============================================================================
//
// P_TryWalk
//
//==============================================================================
function P_TryWalk(actor: Pmobj_t): boolean;

//==============================================================================
//
// P_LookForTargets
//
//==============================================================================
function P_LookForTargets(actor: Pmobj_t; allaround: boolean): boolean;

//==============================================================================
//
// A_FaceTarget
//
//==============================================================================
procedure A_FaceTarget(actor: Pmobj_t);

type
  dirtype_t = (
    DI_EAST,
    DI_NORTHEAST,
    DI_NORTH,
    DI_NORTHWEST,
    DI_WEST,
    DI_SOUTHWEST,
    DI_SOUTH,
    DI_SOUTHEAST,
    DI_NODIR,
    NUMDIRS
  );

const
  /// <summary>The opposite direction, by direction (the one a monster turns around to)</summary>
  opposite: array[0..8] of dirtype_t = (
    DI_WEST, DI_SOUTHWEST, DI_SOUTH, DI_SOUTHEAST,
    DI_EAST, DI_NORTHEAST, DI_NORTH, DI_NORTHWEST, DI_NODIR
  );

//==============================================================================
//
// P_Move
//
//==============================================================================
function P_Move(actor: Pmobj_t): boolean;

//==============================================================================
//
// P_NewChaseDir
//
//==============================================================================
procedure P_NewChaseDir(actor: Pmobj_t);

implementation

uses
  d_delphi,
  d_player,
  doomdata,
  doomdef,
  g_game,
  i_system,
  m_rnd,
  p_common,
  p_friends,
  p_local,
  p_map,
  p_mobj,
  p_maputl,
  p_setup,
  r_defs,
  r_main,
  DelphiDoom.Engine.World.EnemyRules;

//
// ENEMY THINKING
// Enemies are allways spawned
// with targetplayer = -1, threshold = 0
// Most monsters are spawned unaware of all players,
// but some can be made preaware
//

//
// Called by P_NoiseAlert.
// Recursively traverse adjacent sectors,
// sound blocking lines cut off traversal.
//

var
  soundtarget: Pmobj_t;

const
  diags: array[0..3] of dirtype_t = (
    DI_NORTHWEST, DI_NORTHEAST, DI_SOUTHWEST, DI_SOUTHEAST
  );

//==============================================================================
//
// P_RecursiveSound
//
//==============================================================================
procedure P_RecursiveSound(sec: Psector_t; soundblocks: integer);
var
  i: integer;
  check: Pline_t;
  other: Psector_t;
begin
  // wake up all monsters in this sector
  if (sec.validcount = validcount) and
     (sec.soundtraversed <= soundblocks + 1) then
    exit; // already flooded

  sec.validcount := validcount;
  sec.soundtraversed := soundblocks + 1;
  sec.soundtarget := soundtarget;

  for i := 0 to sec.linecount - 1 do
  begin
    check := sec.lines[i];
    if check.flags and ML_TWOSIDED = 0 then
      continue;
    // JVAL: 20200407 - Avoid false ML_TWOSIDED flag
    if (check.sidenum[1] < 0) or (check.sidenum[0] < 0) then
      continue;

    TMapUtilRoutines.P_LineOpening(check, false);

    if openrange <= 0 then
      continue; // closed door

    if sides[check.sidenum[0]].sector = sec then
      other := sides[check.sidenum[1]].sector
    else
      other := sides[check.sidenum[0]].sector;

    if check.flags and ML_SOUNDBLOCK <> 0 then
    begin
      if soundblocks = 0 then
        P_RecursiveSound(other, 1);
    end
    else
      P_RecursiveSound(other, soundblocks);
  end;
end;

//==============================================================================
//
// P_NoiseAlert
//
//==============================================================================
procedure P_NoiseAlert(target: Pmobj_t; emmiter: Pmobj_t);
begin
  soundtarget := target;
  inc(validcount);
  P_RecursiveSound(Psubsector_t(emmiter.subsector).sector, 0);
end;

//==============================================================================
//
// P_MeleeRange
//
//==============================================================================
function P_MeleeRange(actor: Pmobj_t): fixed_t;
begin
  result := actor.info.meleerange;
  if result = 0 then
    result := MELEERANGE
  else if result < FRACUNIT then
    result := result * FRACUNIT;
end;

//==============================================================================
//
// P_TryWalk
//
//==============================================================================
function P_TryWalk(actor: Pmobj_t): boolean;
begin
  if not P_Move(actor) then
    result := false
  else
  begin
    actor.movecount := P_Random and 15;
    result := true;
  end;
end;

//==============================================================================
//
// P_LookForTargets
//
//==============================================================================
function P_LookForTargets(actor: Pmobj_t; allaround: boolean): boolean;
begin
  if actor.flags2_ex and MF2_EX_FRIEND <> 0 then
  begin
    result := P_LookForMonsters(actor);
    if not result then
      if P_Random < 200 then
        result := TMonsterBaseActions.P_LookForPlayers(actor, true);
  end
  else
    result := TMonsterBaseActions.P_LookForPlayers(actor, allaround);
end;

//==============================================================================
//
// P_MoveDefault
// The move of Doom, Heretic and Strife (Hexen has its own, in the rules)
//
//==============================================================================
function P_MoveDefault(actor: Pmobj_t): boolean;
var
  tryx: fixed_t;
  tryy: fixed_t;
  try_ok: boolean;
begin
  if actor.movedir = Ord(DI_NODIR) then
  begin
    result := false;
    exit;
  end;

  if Ord(actor.movedir) >= 8 then
    I_Error(TEnemyGameRules.WeirdMoveDirMessage, [Ord(actor.movedir)]);

  tryx := actor.x + actor.info.speed * xspeed[actor.movedir];
  tryy := actor.y + actor.info.speed * yspeed[actor.movedir];

  try_ok := P_TryMove(actor, tryx, tryy);

  if not try_ok then
  begin
    // open any specials
    if (actor.flags and MF_FLOAT <> 0) and TMapCheck.FloatOk then
    begin
      // must adjust height
      if actor.z < TMapCheck.FloorZ then
        actor.z := actor.z + TCommonMovementActions.P_FloatSpeed(actor)
      else
        actor.z := actor.z - TCommonMovementActions.P_FloatSpeed(actor);

      actor.flags := actor.flags or MF_INFLOAT;
      result := true;
      exit;
    end;

    if TMapCheck.NumSpecHit = 0 then
    begin
      result := false;
      exit;
    end;

    actor.movedir := Ord(DI_NODIR);
    result := TEnemyGameRules.UseSpecialLines(actor);
    exit;
  end
  else
    TEnemyGameRules.ClearFloating(actor);

  if actor.flags and MF_FLOAT = 0 then
  begin
    if actor.z > actor.floorz then
      P_HitFloor(actor);
    actor.z := actor.floorz;
  end;

  result := true;
end;

//==============================================================================
//
// P_Move
//
//==============================================================================
function P_Move(actor: Pmobj_t): boolean;
begin
  if TEnemyGameRules.OwnsMove then
    result := TEnemyGameRules.Move(actor)
  else
    result := P_MoveDefault(actor);
end;

//==============================================================================
//
// A_FaceTarget
//
//==============================================================================
procedure A_FaceTarget(actor: Pmobj_t);
begin
  if actor.target = nil then
    exit;

  actor.flags := actor.flags and not MF_AMBUSH;

  actor.angle :=
    TRendererMain.R_PointToAngle2(actor.x, actor.y, actor.target.x, actor.target.y);

  TEnemyGameRules.BlurAim(actor);
end;

//==============================================================================
//
// P_NewChaseDir
//
//==============================================================================
procedure P_NewChaseDir(actor: Pmobj_t);
var
  deltax: fixed_t;
  deltay: fixed_t;
  target: Pmobj_t;
  d: array[0..2] of dirtype_t;
  olddir: dirtype_t;
  turnaround: dirtype_t;
  idx: integer;
  dist: fixed_t;

  procedure _DoNewChaseDir;
  var
    tdir: dirtype_t;
  begin
    if deltax > 10 * FRACUNIT then
      d[1] := DI_EAST
    else if deltax < -10 * FRACUNIT then
      d[1] := DI_WEST
    else
      d[1] := DI_NODIR;

    if deltay < -10 * FRACUNIT then
      d[2] := DI_SOUTH
    else if deltay > 10 * FRACUNIT then
      d[2] := DI_NORTH
    else
      d[2] := DI_NODIR;

    // try direct route
    if (d[1] <> DI_NODIR) and (d[2] <> DI_NODIR) then
    begin
      if deltay < 0 then
        idx := 2
      else
        idx := 0;
      if deltax > 0 then
        inc(idx);
      actor.movedir := Ord(diags[idx]);
      if (actor.movedir <> Ord(turnaround)) and P_TryWalk(actor) then
        exit;
    end;

    // try other directions
    if (P_Random > 200) or (abs(deltay) > abs(deltax)) then
    begin
      tdir := d[1];
      d[1] := d[2];
      d[2] := tdir;
    end;

    if d[1] = turnaround then
      d[1] := DI_NODIR;
    if d[2] = turnaround then
      d[2] := DI_NODIR;

    if d[1] <> DI_NODIR then
    begin
      actor.movedir := Ord(d[1]);
      if P_TryWalk(actor) then
        exit; // either moved forward or attacked
    end;

    if d[2] <> DI_NODIR then
    begin
      actor.movedir := Ord(d[2]);
      if P_TryWalk(actor) then
        exit;
    end;

    // there is no direct path to the player,
    // so pick another direction.
    if olddir <> DI_NODIR then
    begin
      actor.movedir := Ord(olddir);
      if P_TryWalk(actor) then
        exit;
    end;

    // randomly determine direction of search
    if P_Random and 1 <> 0 then
    begin
      for tdir := DI_EAST to DI_SOUTHEAST do
      begin
        if tdir <> turnaround then
        begin
          actor.movedir := Ord(tdir);
          if P_TryWalk(actor) then
            exit;
        end;
      end;
    end
    else
    begin
      for tdir := DI_SOUTHEAST downto DI_EAST do
      begin
        if tdir <> turnaround then
        begin
          actor.movedir := Ord(tdir);
          if P_TryWalk(actor) then
            exit;
        end;
      end;
    end;

    if turnaround <> DI_NODIR then
    begin
      actor.movedir := Ord(turnaround);
      if P_TryWalk(actor) then
        exit;
    end;

    actor.movedir := Ord(DI_NODIR); // can not move
  end;

begin
  target := actor.target;
  if target = nil then
  begin
    TEnemyGameRules.NoTarget(actor);
    exit;
  end;

  olddir := dirtype_t(actor.movedir);
  turnaround := opposite[Ord(olddir)];

  deltax := target.x - actor.x;
  deltay := target.y - actor.y;

  actor.strafecount := 0;

  // JVAL: 20210209 - MF3_EX_CAUSEFEAR & MF3_EX_NOFEAR flags
  if target.flags3_ex and MF3_EX_CAUSEFEAR <> 0 then
    if actor.flags3_ex and MF3_EX_NOFEAR <> 0 then
      actor.flags2_ex := actor.flags2_ex or MF2_EX_FRIGHTENED;

  if actor.flags2_ex and MF2_EX_FRIGHTENED <> 0 then
  begin
    deltax := -deltax;
    deltay := -deltay;
  end
  else if (target.health > 0) and (actor.flags4_ex and MF4_EX_BACKINGMELEE <> 0) and not P_BothFriends(actor, actor.target) then
  begin
    if G_PlayingEngineVersion >= VERSION207 then
    begin
      dist := TMapUtilRoutines.P_AproxDistance(deltax, deltay);
      if (actor.info.missilestate <> 0) and
         TEnemyGameRules.CanBackAway(actor) and
        (((target.info.missilestate = 0) and (dist < P_MeleeRange(target) * 2)) or
         ((target.player <> nil) and (dist < P_MeleeRange(target) * 3) and
          TEnemyGameRules.FleesMeleeWeapon(Pplayer_t(target.player)))) then
      begin// Back away from melee attacker
        actor.strafecount := P_Random and 15;
        deltax := -deltax;
        deltay := -deltay;
      end;
    end;
  end;

  _DoNewChaseDir;

  if actor.strafecount > 0 then
    actor.movecount := actor.strafecount;
end;

end.
