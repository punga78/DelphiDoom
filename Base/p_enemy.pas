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

implementation

uses
  doomdata,
  doomdef,
  m_rnd,
  p_friends,
  p_local,
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

    P_LineOpening(check, false);

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
        result := P_LookForPlayers(actor, true);
  end
  else
    result := P_LookForPlayers(actor, allaround);
end;

end.
