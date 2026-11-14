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
  strict private
    const
      TILE_SHIFT = GREED_FRACBITS + 6;
      FIRST_WATER = 57;
      LAST_WATER = 59;
      WATER_DEPTH = 20 * GREED_FRACUNIT;
    class function TileOf(AValue: TGreedFixed): Integer; static; inline;
    class function ShapedFloorZ(AWorld: PGreedWorldView; ASpot: Integer; AX, AY: TGreedFixed): TGreedFixed; static;
    class function ShapedCeilingZ(AWorld: PGreedWorldView; ASpot: Integer; AX, AY: TGreedFixed): TGreedFixed; static;
  public
    /// <summary>
    ///   On the memory of the world (IGreedWorld.View), for who asks for every tile of every sprite at every
    ///   tic: no call to the interface, and no call at all where the floor (or the ceiling) is flat
    /// </summary>
    class function FloorZ(AWorld: PGreedWorldView; AX, AY: TGreedFixed): TGreedFixed; overload; static; inline;
    class function CeilingZ(AWorld: PGreedWorldView; AX, AY: TGreedFixed): TGreedFixed; overload; static; inline;
    class function FloorZ(const AWorld: IGreedWorld; AX, AY: TGreedFixed): TGreedFixed; overload; static;
    class function CeilingZ(const AWorld: IGreedWorld; AX, AY: TGreedFixed): TGreedFixed; overload; static;
  end;

implementation

uses
  DelphiDoom.Greed.FixedMath, DelphiDoom.MathCore.FixedMath;

const
  TILE_UNIT = 64 * GREED_FRACUNIT;

type
  TCorners = record
    H1, H2, H3, H4: TGreedFixed;
    FractionX, FractionY: TGreedFixed;
  end;

function Height(AWorld: PGreedWorldView; APlane: TGreedPlane; ASpot: Integer): TGreedFixed; inline;
begin
  Result := AWorld^.Value(APlane, ASpot) * GREED_FRACUNIT;
end;

function CornersOf(AWorld: PGreedWorldView; APlane: TGreedPlane; ASpot: Integer; AX, AY: TGreedFixed): TCorners;
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

class function TGreedTerrain.TileOf(AValue: TGreedFixed): Integer;
begin
  // _SHR of the original: the shift that keeps the sign
  if AValue >= 0 then
    Result := AValue shr TILE_SHIFT
  else
    Result := not ((not AValue) shr TILE_SHIFT);
end;

class function TGreedTerrain.FloorZ(AWorld: PGreedWorldView; AX, AY: TGreedFixed): TGreedFixed;
var
  LSpot: Integer;
  LPicture: Byte;
begin
  LSpot := TileOf(AY) * GREED_MAP_SIZE + TileOf(AX);
  if Cardinal(LSpot) >= GREED_MAP_TILES then
    // outside the map every plane reads 0: a flat floor of height 0 that is not water
    Result := 0
  else if AWorld^.MapFlags^[LSpot] and GREED_FL_FLOOR <> 0 then
    Result := ShapedFloorZ(AWorld, LSpot, AX, AY)
  else
  begin
    Result := AWorld^.Planes[gpFloorHeight]^[LSpot] * GREED_FRACUNIT;
    LPicture := AWorld^.Planes[gpFloorPic]^[LSpot];
    if (LPicture >= FIRST_WATER) and (LPicture <= LAST_WATER) then
      Result := Result - WATER_DEPTH;
  end;
end;

class function TGreedTerrain.CeilingZ(AWorld: PGreedWorldView; AX, AY: TGreedFixed): TGreedFixed;
var
  LSpot: Integer;
begin
  LSpot := TileOf(AY) * GREED_MAP_SIZE + TileOf(AX);
  if Cardinal(LSpot) >= GREED_MAP_TILES then
    Result := 0
  else if AWorld^.MapFlags^[LSpot] and GREED_FL_CEILING <> 0 then
    Result := ShapedCeilingZ(AWorld, LSpot, AX, AY)
  else
    Result := AWorld^.Planes[gpCeilingHeight]^[LSpot] * GREED_FRACUNIT;
end;

class function TGreedTerrain.FloorZ(const AWorld: IGreedWorld; AX, AY: TGreedFixed): TGreedFixed;
begin
  Result := FloorZ(AWorld.View, AX, AY);
end;

class function TGreedTerrain.CeilingZ(const AWorld: IGreedWorld; AX, AY: TGreedFixed): TGreedFixed;
begin
  Result := CeilingZ(AWorld.View, AX, AY);
end;

// the floor of a tile of the map that is not flat: a constant slope or two triangles
class function TGreedTerrain.ShapedFloorZ(AWorld: PGreedWorldView; ASpot: Integer;
  AX, AY: TGreedFixed): TGreedFixed;
var
  LPolyType, LPicture: Integer;
  LWater: TGreedFixed;
  C: TCorners;
begin
  LPolyType := (AWorld^.Flags(ASpot) and GREED_FL_FLOOR) shr GREED_FLS_FLOOR;
  LPicture := AWorld^.Value(gpFloorPic, ASpot);
  if (LPicture >= FIRST_WATER) and (LPicture <= LAST_WATER) then
    LWater := -WATER_DEPTH
  else
    LWater := 0;
  C := CornersOf(AWorld, gpFloorHeight, ASpot, AX, AY);
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

class function TGreedTerrain.ShapedCeilingZ(AWorld: PGreedWorldView; ASpot: Integer;
  AX, AY: TGreedFixed): TGreedFixed;
var
  LPolyType: Integer;
  C: TCorners;
begin
  LPolyType := (AWorld^.Flags(ASpot) and GREED_FL_CEILING) shr GREED_FLS_CEILING;
  C := CornersOf(AWorld, gpCeilingHeight, ASpot, AX, AY);
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
