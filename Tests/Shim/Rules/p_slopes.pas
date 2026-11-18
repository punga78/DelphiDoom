{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of p_slopes for the rule tests}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for the real p_slopes in DelphiDoom.Tests.Rules only: the floor and ceiling heights of a sector without slopes.
{$I Doom32.inc}
unit p_slopes;

interface

uses
  m_fixed,
  r_defs;

type
  TSlopeRoutines = class sealed
  public
    class function P_FloorHeight(const sec: Psector_t; const x, y: fixed_t): fixed_t; static;
    class function P_CeilingHeight(const sec: Psector_t; const x, y: fixed_t): fixed_t; static;
  end;

implementation

class function TSlopeRoutines.P_FloorHeight(const sec: Psector_t; const x, y: fixed_t): fixed_t;
begin
  result := sec.floorheight;
end;

class function TSlopeRoutines.P_CeilingHeight(const sec: Psector_t; const x, y: fixed_t): fixed_t;
begin
  result := sec.ceilingheight;
end;

end.