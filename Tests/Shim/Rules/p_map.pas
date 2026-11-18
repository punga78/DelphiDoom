{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of p_map for the rule tests}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for the real p_map in DelphiDoom.Tests.Rules only: the scratch variables of the movement check that p_maputl reads (the real unit is the movement code).
{$I Doom32.inc}
unit p_map;

interface

uses
  m_fixed,
  p_mobj_h,
  r_defs;

type
  TMapCheck = class sealed
  public
    class var Thing: Pmobj_t;
    class var X: fixed_t;
    class var Y: fixed_t;
    class var FloorPic: integer;
  end;

function P_SectorJumpOverhead(const s: Psector_t; const p: pointer = nil): integer;

implementation

function P_SectorJumpOverhead(const s: Psector_t; const p: pointer = nil): integer;
begin
  // the sectors of the tests have no jump overhead
  result := 0;
end;

end.