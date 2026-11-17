{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the red blood of the map objects (TMobjRoutines.P_SpawnBlood)        }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.BloodSpawner;

interface

uses
  m_fixed,
  p_mobj_h;

type
  /// <summary>
  ///   P_SpawnBlood, the same in Doom and Heretic (Strife has its own: three differences in the data)
  /// </summary>
  /// <remarks>
  ///   Once per hit on a bleeding thing, not per tic. The numbers of the random generator are
  ///   drawn in the order of the old code, in separate calls where the order matters
  /// </remarks>
  TBloodSpawner = class sealed
  public
    /// <summary>A drop of red blood at the point of a hit; the color comes from the thing that bleeds</summary>
    /// <param name="damage">The damage of the hit: a small one gives a smaller drop</param>
    /// <param name="originator">The thing that bleeds; it cannot be nil</param>
    class procedure SpawnRed(x, y, z: fixed_t; damage: integer; const originator: Pmobj_t); static;
  end;

implementation

uses
  d_delphi,
  m_rnd,
  info_h,
  p_mobj,
  r_translations;

{ TBloodSpawner }

class procedure TBloodSpawner.SpawnRed(x, y, z: fixed_t; damage: integer; const originator: Pmobj_t);
var
  th: Pmobj_t;
begin
  z := z + _SHL(P_Random - P_Random, 10);
  th := P_SpawnMobj(x, y, z, Ord(MT_BLOOD));

  if originator.bloodcolor <> 0 then
    R_SetMobjBloodTranslation(th, originator.bloodcolor);

  th.momz := FRACUNIT * 2;
  th.tics := th.tics - (P_Random and 3);

  if th.tics < 1 then
    th.tics := 1;

  if th.flags3_ex and MF3_EX_BLOODIGNOREDAMAGE = 0 then
  begin
    if (damage <= 12) and (damage >= 9) then
      P_SetMobjState(th, S_BLOOD2)
    else if damage < 9 then
      P_SetMobjState(th, S_BLOOD3);
  end;
end;

end.
