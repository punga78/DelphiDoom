{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - how far a unit is from another                    }
{                                                                              }
{  Port of war1 (acoto87/war1), rect_closestPointOnRect of war_math.c and      }
{  wu_unitTileOnTarget, wu_unitPointOnTarget, wu_unitDistanceInTiles,          }
{  wu_unitInRange and wu_setUnitCenterTile of war_units.c, (c) 2019 Alejandro  }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.UnitRange;

interface

uses
  DelphiDoom.War.Model.Types;

type
  /// <summary>Distances between a unit and a building or another unit, in tiles. Static functions: the states call them in their loops</summary>
  TWarUnitRange = class
  public
    /// <summary>rect_closestPointOnRect: the rectangle includes its last pixel (the right edge is x + width - 1)</summary>
    class function ClosestPointOnRect(AX, AY, AWidth, AHeight: Single; const APoint: TWarVec2): TWarVec2; static;
    /// <summary>wu_unitTileOnTarget: the tile of the target that is closest to the center tile of the unit</summary>
    class function TileOnTarget(AEntity, ATarget: PWarEntity): TWarVec2; static;
    /// <summary>wu_unitPointOnTarget: the point of the target (pixels) that is closest to the center of the unit</summary>
    class function PointOnTarget(AEntity, ATarget: PWarEntity): TWarVec2; static;
    /// <summary>wu_unitDistanceInTiles</summary>
    class function DistanceInTiles(AEntity, ATarget: PWarEntity): Integer; static;
    /// <summary>wu_unitInRange</summary>
    class function InRange(AEntity, ATarget: PWarEntity; ARange: Integer): Boolean; static;
    /// <summary>wu_setUnitCenterTile: the center of the unit goes to the middle of the tile</summary>
    class procedure SetCenterTile(AEntity: PWarEntity; AX, AY: Integer); static;
  end;

implementation

uses
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.UnitGeometry;

{ TWarUnitRange }

class function TWarUnitRange.ClosestPointOnRect(AX, AY, AWidth, AHeight: Single; const APoint: TWarVec2): TWarVec2;
var
  LRight: Single;
  LBottom: Single;
begin
  LRight := AX + AWidth;
  LRight := LRight - 1;
  LBottom := AY + AHeight;
  LBottom := LBottom - 1;
  if (APoint.X < AX) and (APoint.Y < AY) then
    Exit(TWarModelMath.Vec(AX, AY));
  if (APoint.X >= AX) and (APoint.X <= LRight) and (APoint.Y < AY) then
    Exit(TWarModelMath.Vec(APoint.X, AY));
  if (APoint.X > LRight) and (APoint.Y < AY) then
    Exit(TWarModelMath.Vec(LRight, AY));
  if (APoint.X > LRight) and (APoint.Y >= AY) and (APoint.Y <= LBottom) then
    Exit(TWarModelMath.Vec(LRight, APoint.Y));
  if (APoint.X > LRight) and (APoint.Y > LBottom) then
    Exit(TWarModelMath.Vec(LRight, LBottom));
  if (APoint.X >= AX) and (APoint.X <= LRight) and (APoint.Y > LBottom) then
    Exit(TWarModelMath.Vec(APoint.X, LBottom));
  if (APoint.X < AX) and (APoint.Y > LBottom) then
    Exit(TWarModelMath.Vec(AX, LBottom));
  if (APoint.X < AX) and (APoint.Y >= AY) and (APoint.Y <= LBottom) then
    Exit(TWarModelMath.Vec(AX, APoint.Y));
  Result := APoint;
end;

class function TWarUnitRange.TileOnTarget(AEntity, ATarget: PWarEntity): TWarVec2;
var
  LTile: TWarVec2;
  LTargetTile: TWarVec2;
begin
  LTile := TWarUnitGeometry.CenterTile(AEntity);
  LTargetTile := TWarUnitGeometry.Tile(ATarget);
  Result := ClosestPointOnRect(LTargetTile.X, LTargetTile.Y, ATarget^.UnitData.SizeX, ATarget^.UnitData.SizeY, LTile);
end;

class function TWarUnitRange.PointOnTarget(AEntity, ATarget: PWarEntity): TWarVec2;
var
  LPosition: TWarVec2;
  LSize: TWarVec2;
begin
  LPosition := TWarUnitGeometry.CenterPosition(AEntity);
  LSize := TWarUnitGeometry.SpriteSize(ATarget);
  Result := ClosestPointOnRect(ATarget^.Position.X, ATarget^.Position.Y, LSize.X, LSize.Y, LPosition);
end;

class function TWarUnitRange.DistanceInTiles(AEntity, ATarget: PWarEntity): Integer;
var
  LTile: TWarVec2;
begin
  LTile := TileOnTarget(AEntity, ATarget);
  Result := TWarUnitGeometry.TileDistance(AEntity, LTile);
end;

class function TWarUnitRange.InRange(AEntity, ATarget: PWarEntity; ARange: Integer): Boolean;
begin
  Result := DistanceInTiles(AEntity, ATarget) <= ARange;
end;

class procedure TWarUnitRange.SetCenterTile(AEntity: PWarEntity; AX, AY: Integer);
var
  LPosition: TWarVec2;
begin
  LPosition := TWarModelMath.TileToMap(TWarModelMath.Vec(AX, AY), True);
  TWarUnitGeometry.SetCenterPosition(AEntity, LPosition);
end;

end.
