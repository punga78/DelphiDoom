{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the height of the floor and of the ceiling       }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): RF_GetFloorZ and            }
{  RF_GetCeilingZ of r_public.pas                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Terrain;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Greed.Types, DelphiDoom.Greed.World.Intf;

type
  /// <summary>
  ///   How high the floor and the ceiling are at a point of the map (fixed point, the tile is 64 units of
  ///   2^16): flat, with a constant slope or triangulated with the heights of the four corners of the tile. The
  ///   water flats (57..59) lower the floor by 20 units. The wraparound of the products is wanted, as in the
  ///   original; a corner outside the map has height 0 (the original read what came after the array)
  /// </summary>
  TGreedTerrain = class
  public
    class function FloorZ(const AWorld: IGreedWorld; AX, AY: TGreedFixed): TGreedFixed; static;
    class function CeilingZ(const AWorld: IGreedWorld; AX, AY: TGreedFixed): TGreedFixed; static;
  end;

implementation

uses
  DelphiDoom.Greed.FixedMath, DelphiDoom.MathCore.FixedMath;

const
  TILE_UNIT = 64 * GREED_FRACUNIT;
  TILE_SHIFT = GREED_FRACBITS + 6;
  FIRST_WATER = 57;
  LAST_WATER = 59;
  WATER_DEPTH = 20 * GREED_FRACUNIT;

type
  TCorners = record
    H1, H2, H3, H4: TGreedFixed;
    FractionX, FractionY: TGreedFixed;
  end;

function Height(const AWorld: IGreedWorld; APlane: TGreedPlane; ASpot: Integer): TGreedFixed;
begin
  Result := AWorld.GetValue(APlane, ASpot) * GREED_FRACUNIT;
end;

function CornersOf(const AWorld: IGreedWorld; APlane: TGreedPlane; ASpot: Integer; AX, AY: TGreedFixed): TCorners;
begin
  Result.H1 := Height(AWorld, APlane, ASpot);
  Result.H2 := Height(AWorld, APlane, ASpot + 1);
  Result.H3 := Height(AWorld, APlane, ASpot + GREED_MAP_SIZE);
  Result.H4 := Height(AWorld, APlane, ASpot + GREED_MAP_SIZE + 1);
  // from 0 to FRACUNIT - 1
  Result.FractionX := (AX and (TILE_UNIT - 1)) div 64;
  Result.FractionY := (AY and (TILE_UNIT - 1)) div 64;
end;

// the plane of the triangle that the point is in, from the three corners that are in it
function Triangulated(var C: TCorners; APolyType: Integer): TGreedFixed;
var
  LTop, LBottom: TGreedFixed;
begin
  if APolyType = GREED_POLY_UL_TO_LR then
  begin
    if C.FractionX > C.FractionY then
      C.H3 := C.H1 - (C.H2 - C.H1)
    else
      C.H2 := C.H1 + (C.H1 - C.H3);
  end
  else
  begin
    if C.FractionX < GREED_FRACUNIT - C.FractionY then
      C.H4 := C.H2 + (C.H2 - C.H1)
    else
      C.H1 := C.H2 - (C.H4 - C.H2);
  end;
  LTop := C.H1 + TGreedFixedMath.Mul(C.H2 - C.H1, C.FractionX);
  LBottom := C.H3 + TGreedFixedMath.Mul(C.H4 - C.H3, C.FractionX);
  Result := LTop + TGreedFixedMath.Mul(LBottom - LTop, C.FractionY);
end;

{ TGreedTerrain }

class function TGreedTerrain.FloorZ(const AWorld: IGreedWorld; AX, AY: TGreedFixed): TGreedFixed;
var
  LSpot, LPolyType, LPicture: Integer;
  LWater: TGreedFixed;
  C: TCorners;
begin
  LSpot := TGreedFixedMath.ShiftRight(AY, TILE_SHIFT) * GREED_MAP_SIZE + TGreedFixedMath.ShiftRight(AX, TILE_SHIFT);
  LPolyType := (AWorld.GetMapFlags(LSpot) and GREED_FL_FLOOR) shr GREED_FLS_FLOOR;
  LPicture := AWorld.GetValue(gpFloorPic, LSpot);
  if (LPicture >= FIRST_WATER) and (LPicture <= LAST_WATER) then
    LWater := -WATER_DEPTH
  else
    LWater := 0;
  if LPolyType = GREED_POLY_FLAT then
    Exit(Height(AWorld, gpFloorHeight, LSpot) + LWater);
  C := CornersOf(AWorld, gpFloorHeight, LSpot, AX, AY);
  if LPolyType = GREED_POLY_SLOPE then
  begin
    if C.H1 = C.H2 then
      Result := C.H1 + TGreedFixedMath.Mul(C.H3 - C.H1, C.FractionY) + LWater
    else
      Result := C.H1 + TGreedFixedMath.Mul(C.H2 - C.H1, C.FractionX) + LWater;
    Exit;
  end;
  Result := Triangulated(C, LPolyType) + LWater;
end;

class function TGreedTerrain.CeilingZ(const AWorld: IGreedWorld; AX, AY: TGreedFixed): TGreedFixed;
var
  LSpot, LPolyType: Integer;
  C: TCorners;
begin
  LSpot := TGreedFixedMath.ShiftRight(AY, TILE_SHIFT) * GREED_MAP_SIZE + TGreedFixedMath.ShiftRight(AX, TILE_SHIFT);
  LPolyType := (AWorld.GetMapFlags(LSpot) and GREED_FL_CEILING) shr GREED_FLS_CEILING;
  if LPolyType = GREED_POLY_FLAT then
    Exit(Height(AWorld, gpCeilingHeight, LSpot));
  C := CornersOf(AWorld, gpCeilingHeight, LSpot, AX, AY);
  if LPolyType = GREED_POLY_SLOPE then
  begin
    if C.H1 = C.H2 then
      Result := C.H1 + TGreedFixedMath.Mul(C.H3 - C.H1, C.FractionY)
    else
      Result := C.H1 + TGreedFixedMath.Mul(C.H2 - C.H1, C.FractionX);
    Exit;
  end;
  Result := Triangulated(C, LPolyType);
end;

end.
