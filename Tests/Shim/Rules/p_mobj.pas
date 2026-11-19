{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of p_mobj for the rule tests                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for the real p_mobj in the rule test projects only: P_SpawnMobj gives a zeroed record and remembers what was asked (the real unit is the whole world of the engine).
{$I Doom32.inc}
unit p_mobj;

interface

uses
  doomdata,
  m_fixed,
  p_mobj_h;

type
  TShimMobjSpawn = class sealed
  public
    class var Count: integer;
    class var LastType: integer;
    class var Mobj: mobj_t;
  end;

function P_SpawnMobj(x, y, z: fixed_t; _type: integer; const mthing: Pmapthing_t = nil): Pmobj_t;

implementation

function P_SpawnMobj(x, y, z: fixed_t; _type: integer; const mthing: Pmapthing_t = nil): Pmobj_t;
begin
  FillChar(TShimMobjSpawn.Mobj, SizeOf(TShimMobjSpawn.Mobj), 0);
  TShimMobjSpawn.Mobj.x := x;
  TShimMobjSpawn.Mobj.y := y;
  TShimMobjSpawn.Mobj.z := z;
  TShimMobjSpawn.LastType := _type;
  inc(TShimMobjSpawn.Count);
  result := @TShimMobjSpawn.Mobj;
end;

end.
