{******************************************************************************}
{                                                                              }
{  DelphiDoom: Radix game - things that fly through a sky                      }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of P_SectorJumpOverhead and P_SectorJumpUnderhead (p_map.pas of        }
{  Rad-X), without the offset that they gave a player under a sloped plane     }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.RadixSky;

interface

uses
  m_fixed,
  p_mobj_h,
  r_defs;

type
  /// <summary>
  ///   MF3_EX_THRUSKY and MF3_EX_PREVENTTHRYSKY of Rad-X in the engine: a missile, or a thing with
  ///   THRUSKY, goes up to 64 map units past a sky ceiling and below a sky floor, unless it has
  ///   PREVENTTHRYSKY. The numbers are in TRadixMovementRules, the flags per kind of thing in
  ///   radix_pickups
  /// </summary>
  /// <remarks>Class of static methods: P_CheckPosition and P_ZMovement ask it for every move</remarks>
  TRadixSkyEngine = class sealed
  public
    /// <summary>How far past the ceiling (ACeiling) or below the floor of the sector the thing can go</summary>
    class function Offset(mo: Pmobj_t; sector: Psector_t; ACeiling: Boolean): fixed_t; static;
    /// <summary>
    ///   P_CheckPosition: the base planes of the sector under the thing that is moved (TMapCheck)
    ///   are lowered and raised by the offsets; the lines then close them as they always did
    /// </summary>
    class procedure AdjustCheckedPlanes; static;
  end;

implementation

uses
  p_map,
  p_setup,
  r_main,
  r_sky,
  radix_pickups,
  DelphiDoom.Radix.Physics.Movement;

class function TRadixSkyEngine.Offset(mo: Pmobj_t; sector: Psector_t; ACeiling: Boolean): fixed_t;
var
  LThruSky, LPrevent: Boolean;
  LMiddleLimit: fixed_t;
  LIsSky: Boolean;
begin
  RX_ActorSkyFlight(mo._type, LThruSky, LPrevent);
  LMiddleLimit := 0;
  if sector.midsec >= 0 then
  begin
    if ACeiling then
      LMiddleLimit := sectors[sector.midsec].floorheight
    else
      LMiddleLimit := sectors[sector.midsec].ceilingheight;
  end;
  if ACeiling then
    LIsSky := sector.ceilingpic = skyflatnum
  else
    LIsSky := sector.floorpic = skyflatnum;
  Result := TRadixMovementRules.SectorSkyOffset(ACeiling, sector.midsec >= 0, mo.z, LMiddleLimit, LIsSky,
    mo.flags and MF_MISSILE <> 0, LThruSky, LPrevent);
end;

class procedure TRadixSkyEngine.AdjustCheckedPlanes;
var
  LThing: Pmobj_t;
  LSector: Psector_t;
  LThruSky, LPrevent: Boolean;
  LUnder: fixed_t;
begin
  LThing := TMapCheck.Thing;
  // nearly every thing asks: only a missile or a thing that flies through skies has anything to do
  if LThing.flags and MF_MISSILE = 0 then
  begin
    RX_ActorSkyFlight(LThing._type, LThruSky, LPrevent);
    if not LThruSky then
      Exit;
  end;
  LSector := R_PointInSubsector(TMapCheck.X, TMapCheck.Y).sector;
  TMapCheck.CeilingZ := TMapCheck.CeilingZ + Offset(LThing, LSector, True);
  LUnder := Offset(LThing, LSector, False);
  TMapCheck.DropOffZ := TMapCheck.DropOffZ - LUnder;
  TMapCheck.FloorZ := TMapCheck.FloorZ - LUnder;
end;

end.
