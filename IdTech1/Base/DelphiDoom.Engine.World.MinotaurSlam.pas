{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the slam of the Maulotaur (Heretic, Hexen)             }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.MinotaurSlam;

// The thrust and the damage of a charging Maulotaur (issue #185, step 2f-2b). They
// were in p_inter, the same in Heretic and Hexen but for the dice of the damage
// (MinotaurSlamDice of TInterGameRules)

interface

uses
  p_mobj_h;

//==============================================================================
//
// P_MinotaurSlam
//
//==============================================================================
procedure P_MinotaurSlam(source: Pmobj_t; target: Pmobj_t);

implementation

uses
  m_fixed,
  m_rnd,
  p_inter,
  p_local,
  r_main,
  tables,
  DelphiDoom.Engine.World.InterRules;

//==============================================================================
//
// P_MinotaurSlam
//
//==============================================================================
procedure P_MinotaurSlam(source: Pmobj_t; target: Pmobj_t);
var
  angle: angle_t;
  thrust: fixed_t;
begin
  angle := TRendererMain.R_PointToAngle2(source.x, source.y, target.x, target.y);
  angle := angle shr ANGLETOFINESHIFT;
  thrust := 16 * FRACUNIT + (P_Random * 1024);
  target.momx := target.momx + FixedMul(thrust, finecosine[angle]);
  target.momy := target.momy + FixedMul(thrust, finesine[angle]);
  P_DamageMobj(target, nil, nil, HITDICE(TInterGameRules.MinotaurSlamDice));
  if target.player <> nil then
    target.reactiontime := 14 + (P_Random and 7);
end;

end.
