{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - how far a unit is from another                    }
{                                                                              }
{  Port of war1 (acoto87/war1), rect_closestPointOnRect of war_math.c and      }
{  wu_unitPointOnTarget, wu_unitTileOnTarget, wu_unitInRange of war_units.c,   }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                        }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.TargetGeometry;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types;

type
  /// <summary>The point of a unit that is closest to another, and the distance to it. Static: used every tic by the states</summary>
  TWarTargetGeometry = class
  public
    /// <summary>rect_closestPointOnRect: the rectangle is left, top, width and height; its right and bottom are the last pixel (minus one)</summary>
    class function ClosestPointOnRect(ALeft, ATop, AWidth, AHeight: Single; const APoint: TWarVec2): TWarVec2; static;
    /// <summary>wu_unitPointOnTarget: the point of the target unit (in pixels) closest to the center of the entity</summary>
    class function PointOnTarget(AEntity, ATarget: PWarEntity): TWarVec2; static;
    /// <summary>wu_unitTileOnTarget: the tile of the target closest to the center tile of the entity</summary>
    class function TileOnTarget(AEntity, ATarget: PWarEntity): TWarVec2; static;
    /// <summary>wu_unitInRange</summary>
    class function UnitInRange(AEntity, ATarget: PWarEntity; ARange: Integer): Boolean; static;
    /// <summary>wu_unitDistanceInTiles: the distance in tiles to the nearest tile of the target</summary>
    class function DistanceInTiles(AEntity, ATarget: PWarEntity): Integer; static;
    /// <summary>wu_setUnitCenterTile: the center of the unit goes to the middle of the tile</summary>
    class procedure SetCenterTile(AEntity: PWarEntity; AX, AY: Integer); static;
  end;

implementation

uses
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.UnitGeometry;

{ TWarTargetGeometry }

class function TWarTargetGeometry.ClosestPointOnRect(ALeft, ATop, AWidth, AHeight: Single;
  const APoint: TWarVec2): TWarVec2;
var
  LRight: Single;
  LBottom: Single;
begin
  LRight := ALeft + AWidth;
  LRight := LRight - 1;
  LBottom := ATop + AHeight;
  LBottom := LBottom - 1;
  if (APoint.X < ALeft) and (APoint.Y < ATop) then
    Exit(TWarModelMath.Vec(ALeft, ATop));
  if (APoint.X >= ALeft) and (APoint.X <= LRight) and (APoint.Y < ATop) then
    Exit(TWarModelMath.Vec(APoint.X, ATop));
  if (APoint.X > LRight) and (APoint.Y < ATop) then
    Exit(TWarModelMath.Vec(LRight, ATop));
  if (APoint.X > LRight) and (APoint.Y >= ATop) and (APoint.Y <= LBottom) then
    Exit(TWarModelMath.Vec(LRight, APoint.Y));
  if (APoint.X > LRight) and (APoint.Y > LBottom) then
    Exit(TWarModelMath.Vec(LRight, LBottom));
  if (APoint.X >= ALeft) and (APoint.X <= LRight) and (APoint.Y > LBottom) then
    Exit(TWarModelMath.Vec(APoint.X, LBottom));
  if (APoint.X < ALeft) and (APoint.Y > LBottom) then
    Exit(TWarModelMath.Vec(ALeft, LBottom));
  if (APoint.X < ALeft) and (APoint.Y >= ATop) and (APoint.Y <= LBottom) then
    Exit(TWarModelMath.Vec(ALeft, APoint.Y));
  Result := APoint;
end;

class function TWarTargetGeometry.PointOnTarget(AEntity, ATarget: PWarEntity): TWarVec2;
var
  LSize: TWarVec2;
begin
  LSize := TWarUnitGeometry.SpriteSize(ATarget);
  Result := ClosestPointOnRect(ATarget^.Position.X, ATarget^.Position.Y, LSize.X, LSize.Y,
    TWarUnitGeometry.CenterPosition(AEntity));
end;

class function TWarTargetGeometry.TileOnTarget(AEntity, ATarget: PWarEntity): TWarVec2;
var
  LTile: TWarVec2;
begin
  LTile := TWarUnitGeometry.Tile(ATarget);
  Result := ClosestPointOnRect(LTile.X, LTile.Y, ATarget^.UnitData.SizeX, ATarget^.UnitData.SizeY,
    TWarUnitGeometry.CenterTile(AEntity));
end;

class function TWarTargetGeometry.UnitInRange(AEntity, ATarget: PWarEntity; ARange: Integer): Boolean;
begin
  Result := TWarUnitGeometry.TileInRange(AEntity, TileOnTarget(AEntity, ATarget), ARange);
end;

class function TWarTargetGeometry.DistanceInTiles(AEntity, ATarget: PWarEntity): Integer;
begin
  Result := TWarUnitGeometry.TileDistance(AEntity, TileOnTarget(AEntity, ATarget));
end;

class procedure TWarTargetGeometry.SetCenterTile(AEntity: PWarEntity; AX, AY: Integer);
begin
  TWarUnitGeometry.SetCenterPosition(AEntity, TWarModelMath.TileToMap(TWarModelMath.Vec(AX, AY), True));
end;

end.
