{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the lines a monster bumps into (p_enemy)               }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.EnemyMoveSpecials;

interface

uses
  p_mobj_h;

type
  /// <summary>
  ///   What a monster of Doom, Heretic and Strife does with the special lines its move bumped
  ///   into (issue #185, step 2f-4): it runs the scripts and tries to use them, like a player.
  ///   Hexen has other rules (the activation of its own specials) and does not compile this unit
  /// </summary>
  TEnemyMoveSpecials = class sealed
  public
    /// <summary>
    ///   Uses the lines in TMapCheck.SpecHit (TMapCheck.NumSpecHit goes down to 0). True if the last of them was
    ///   activated or used (a door that opens)
    /// </summary>
    class function UseHitLines(actor: Pmobj_t): boolean; static;
  end;

implementation

uses
  d_delphi,
  doomdata,
  doomdef,
  p_local,
  p_map,
  p_maputl,
  p_setup,
  DelphiDoom.Engine.World.SwitchRules,
  p_switch,
  p_udmf,
  ps_main,
  r_defs,
  udmf_spec;

//==============================================================================
//
// TEnemyMoveSpecials.UseHitLines
//
//==============================================================================
class function TEnemyMoveSpecials.UseHitLines(actor: Pmobj_t): boolean;
var
  ld: Pline_t;
  ret1, ret2: boolean;
begin
  result := false;
  while TMapCheck.NumSpecHit > 0 do
  begin
    dec(TMapCheck.NumSpecHit);
    ld := TMapCheck.SpecHit[TMapCheck.NumSpecHit];

    if ld.flags and ML_TRIGGERSCRIPTS <> 0 then
      if actor.flags2_ex and MF2_EX_DONTRUNSCRIPTS = 0 then
        PS_EventUseLine(actor, pDiff(ld, lines, SizeOf(line_t)), P_PointOnLineSide(actor.x, actor.y, ld));

    // if the special is not a door
    // that can be opened,
    // return false
    ret1 := P_ActivateLine(ld, actor, 0, ULAC_USE);
    ret2 := P_UseSpecialLine(actor, ld, 0);
    result := ret1 or ret2;
  end;
end;

end.
