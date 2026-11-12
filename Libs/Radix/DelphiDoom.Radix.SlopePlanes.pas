{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixSlopePlanes                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of calc_radix_plane, RX_CalcFloorSlope, RX_CalcCeilingSlope and of     }
{  RX_RadixX2Doom/RX_RadixY2Doom (sector form) of radix_map_extra.pas          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.SlopePlanes;

interface

uses
  DelphiDoom.Radix.MapInfo.Types;

type
  /// <summary>
  ///   The planes of the sloped floors and ceilings of a sector of Radix. RADIX.DAT has the
  ///   equation of the plane too, but with integers that overflow: as the old code did, the plane
  ///   is made again from the three points of the sector, in floating point (Single, as the float
  ///   of the engine: the parity with the old code is on Win32)
  /// </summary>
  TRadixSlopePlanes = class
  public
    /// <summary>The Doom x of a x of RADIX.DAT in that sector (XMul * x + XAdd)</summary>
    class function ToDoomX(const ASector: TRadixSectorInfo; AX: Integer): Integer; static;
    /// <summary>The Doom y of a y of RADIX.DAT in that sector (YMul * y + YAdd)</summary>
    class function ToDoomY(const ASector: TRadixSectorInfo; AY: Integer): Integer; static;
    /// <summary>The plane through three points; Valid is false when it has no height for a point (c = 0)</summary>
    class function FromPoints(const AX1, AY1, AZ1, AX2, AY2, AZ2, AX3, AY3, AZ3: Single): TRadixSlopePlane; static;
    /// <summary>The plane of the floor, from the height nodes and the floor heights of the sector</summary>
    class function Floor(const ASector: TRadixSectorInfo): TRadixSlopePlane; static;
    /// <summary>The plane of the ceiling, from the height nodes and the ceiling heights of the sector</summary>
    class function Ceiling(const ASector: TRadixSectorInfo): TRadixSlopePlane; static;
    /// <summary>The height of the plane over a point, in map units (ZatPointFloor of the engine, without fixed point)</summary>
    class function HeightAt(const APlane: TRadixSlopePlane; const AX, AY: Single): Single; static;
    /// <summary>
    ///   The angle of a flat as the engine wants it (a 32 bit angle): the angle of RADIX.DAT has
    ///   4096 steps in a turn and the old code took away half a turn from 2048 on
    /// </summary>
    class function ToEngineAngle(ARadixAngle: Cardinal): Cardinal; static;
  end;

implementation

{$Q-}
{$R-}
// the angle wraps around 2^32 on purpose, as in the old code (ang * $200000)

const
  RADIX_HALF_TURN = 2048;
  RADIX_ANGLE_TO_ENGINE = $200000;

{ TRadixSlopePlanes }

class function TRadixSlopePlanes.ToDoomX(const ASector: TRadixSectorInfo; AX: Integer): Integer;
begin
  Result := AX * ASector.XMul + ASector.XAdd;
end;

class function TRadixSlopePlanes.ToDoomY(const ASector: TRadixSectorInfo; AY: Integer): Integer;
begin
  Result := AY * ASector.YMul + ASector.YAdd;
end;

class function TRadixSlopePlanes.FromPoints(const AX1, AY1, AZ1, AX2, AY2, AZ2, AX3, AY3,
  AZ3: Single): TRadixSlopePlane;
var
  LA1, LB1, LC1: Single;
  LA2, LB2, LC2: Single;
  LC: Single;
begin
  LA1 := AX2 - AX1;
  LB1 := AY2 - AY1;
  LC1 := AZ2 - AZ1;
  LA2 := AX3 - AX1;
  LB2 := AY3 - AY1;
  LC2 := AZ3 - AZ1;
  Result.A := LB1 * LC2 - LB2 * LC1;
  Result.B := LA2 * LC1 - LA1 * LC2;
  LC := LA1 * LB2 - LB1 * LA2;
  Result.D := -Result.A * AX1 - Result.B * AY1 - LC * AZ1;
  // the old code divided anyway (1 / fc): three points on a line stopped the game
  Result.Valid := LC <> 0;
  if Result.Valid then
    Result.InverseC := 1 / LC
  else
    Result.InverseC := 0;
end;

class function TRadixSlopePlanes.Floor(const ASector: TRadixSectorInfo): TRadixSlopePlane;
begin
  Result := FromPoints(
    ToDoomX(ASector, ASector.HeightNodesX[0]), ToDoomY(ASector, ASector.HeightNodesY[0]), ASector.FloorHeights[0],
    ToDoomX(ASector, ASector.HeightNodesX[1]), ToDoomY(ASector, ASector.HeightNodesY[1]), ASector.FloorHeights[1],
    ToDoomX(ASector, ASector.HeightNodesX[2]), ToDoomY(ASector, ASector.HeightNodesY[2]), ASector.FloorHeights[2]);
end;

class function TRadixSlopePlanes.Ceiling(const ASector: TRadixSectorInfo): TRadixSlopePlane;
begin
  Result := FromPoints(
    ToDoomX(ASector, ASector.HeightNodesX[0]), ToDoomY(ASector, ASector.HeightNodesY[0]), ASector.CeilingHeights[0],
    ToDoomX(ASector, ASector.HeightNodesX[1]), ToDoomY(ASector, ASector.HeightNodesY[1]), ASector.CeilingHeights[1],
    ToDoomX(ASector, ASector.HeightNodesX[2]), ToDoomY(ASector, ASector.HeightNodesY[2]), ASector.CeilingHeights[2]);
end;

class function TRadixSlopePlanes.HeightAt(const APlane: TRadixSlopePlane; const AX, AY: Single): Single;
begin
  Result := (-APlane.A * AX - APlane.B * AY - APlane.D) * APlane.InverseC;
end;

class function TRadixSlopePlanes.ToEngineAngle(ARadixAngle: Cardinal): Cardinal;
begin
  if ARadixAngle >= RADIX_HALF_TURN then
    ARadixAngle := ARadixAngle - RADIX_HALF_TURN;
  Result := ARadixAngle * RADIX_ANGLE_TO_ENGINE;
end;

end.
