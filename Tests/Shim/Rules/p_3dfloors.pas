{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of p_3dfloors for the rule tests}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for the real p_3dfloors in DelphiDoom.Tests.Rules only: the floor and ceiling heights of a place without 3d floors (the real unit scans the 3d floors of the sectors).
{$I Doom32.inc}
unit p_3dfloors;

interface

uses
  m_fixed,
  p_mobj_h,
  r_defs;

type
  T3dFloorRoutines = class sealed
  public
    class function P_3dFloorHeight(const x, y, z: fixed_t): fixed_t; overload; static;
    class function P_3dCeilingHeight(const x, y, z: fixed_t): fixed_t; overload; static;
    class function P_3dFloorHeight(const s: Psector_t; const x, y, z: fixed_t): fixed_t; overload; static;
    class function P_3dCeilingHeight(const s: Psector_t; const x, y, z: fixed_t): fixed_t; overload; static;
  end;

implementation

class function T3dFloorRoutines.P_3dFloorHeight(const x, y, z: fixed_t): fixed_t;
begin
  result := -MaxInt;
end;

class function T3dFloorRoutines.P_3dCeilingHeight(const x, y, z: fixed_t): fixed_t;
begin
  result := MaxInt;
end;

class function T3dFloorRoutines.P_3dFloorHeight(const s: Psector_t; const x, y, z: fixed_t): fixed_t;
begin
  result := s.floorheight;
end;

class function T3dFloorRoutines.P_3dCeilingHeight(const s: Psector_t; const x, y, z: fixed_t): fixed_t;
begin
  result := s.ceilingheight;
end;

end.