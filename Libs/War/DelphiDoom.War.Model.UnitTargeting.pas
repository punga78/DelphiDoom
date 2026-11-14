{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - how near a unit is to another one                  }
{                                                                              }
{  Port of war1 (acoto87/war1), rect_closestPointOnRect of war_math.c and      }
{  wu_unitTileOnTarget, wu_unitPointOnTarget, wu_unitDistanceInTiles and       }
{  wu_unitInRange of war_units.c, (c) 2019 Alejandro Coto Gutierrez, zlib      }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version, not    }
{  the original.                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.UnitTargeting;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types;

type
  /// <summary>
  ///   Where a unit stands in relation to the rectangle of another one (a building is many tiles wide, so its
  ///   distance is the distance to the nearest of them). Static functions on the entities: the states ask at every tic
  /// </summary>
  TWarUnitTargeting = class
  public
    /// <summary>
    ///   rect_closestPointOnRect: the point of the rectangle (whose last column and row are X + W - 1 and Y + H - 1, as in the
    ///   original) that is nearest to the point; the point itself if it is inside
    /// </summary>
    class function ClosestPointOnRect(AX, AY, AWidth, AHeight: Single; const APoint: TWarVec2): TWarVec2; static;
    /// <summary>wu_unitTileOnTarget: the tile of the target nearest to the center tile of the unit</summary>
    class function TileOnTarget(AEntity, ATarget: PWarEntity): TWarVec2; static;
    /// <summary>wu_unitPointOnTarget: the point (pixels) of the target nearest to the center of the unit</summary>
    class function PointOnTarget(AEntity, ATarget: PWarEntity): TWarVec2; static;
    /// <summary>wu_unitDistanceInTiles</summary>
    class function DistanceInTiles(AEntity, ATarget: PWarEntity): Integer; static;
    /// <summary>wu_unitInRange: the nearest tile of the target is at most ARange tiles away</summary>
    class function InRange(AEntity, ATarget: PWarEntity; ARange: Integer): Boolean; static;
  end;

implementation

uses
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.UnitGeometry;

{ TWarUnitTargeting }

class function TWarUnitTargeting.ClosestPointOnRect(AX, AY, AWidth, AHeight: Single;
  const APoint: TWarVec2): TWarVec2;
var
  LRight: Single;
  LBottom: Single;
begin
  LRight := AX + AWidth;
  LRight := LRight - 1;
  LBottom := AY + AHeight;
  LBottom := LBottom - 1;
  Result := APoint;
  if (APoint.X < AX) and (APoint.Y < AY) then
    Result := TWarModelMath.Vec(AX, AY)
  else if (APoint.X >= AX) and (APoint.X <= LRight) and (APoint.Y < AY) then
    Result := TWarModelMath.Vec(APoint.X, AY)
  else if (APoint.X > LRight) and (APoint.Y < AY) then
    Result := TWarModelMath.Vec(LRight, AY)
  else if (APoint.X > LRight) and (APoint.Y >= AY) and (APoint.Y <= LBottom) then
    Result := TWarModelMath.Vec(LRight, APoint.Y)
  else if (APoint.X > LRight) and (APoint.Y > LBottom) then
    Result := TWarModelMath.Vec(LRight, LBottom)
  else if (APoint.X >= AX) and (APoint.X <= LRight) and (APoint.Y > LBottom) then
    Result := TWarModelMath.Vec(APoint.X, LBottom)
  else if (APoint.X < AX) and (APoint.Y > LBottom) then
    Result := TWarModelMath.Vec(AX, LBottom)
  else if (APoint.X < AX) and (APoint.Y >= AY) and (APoint.Y <= LBottom) then
    Result := TWarModelMath.Vec(AX, APoint.Y);
end;

class function TWarUnitTargeting.TileOnTarget(AEntity, ATarget: PWarEntity): TWarVec2;
var
  LTile: TWarVec2;
  LTargetTile: TWarVec2;
begin
  LTile := TWarUnitGeometry.CenterTile(AEntity);
  LTargetTile := TWarUnitGeometry.Tile(ATarget);
  Result := ClosestPointOnRect(LTargetTile.X, LTargetTile.Y, ATarget^.UnitData.SizeX, ATarget^.UnitData.SizeY, LTile);
end;

class function TWarUnitTargeting.PointOnTarget(AEntity, ATarget: PWarEntity): TWarVec2;
var
  LPosition: TWarVec2;
  LSize: TWarVec2;
begin
  LPosition := TWarUnitGeometry.CenterPosition(AEntity);
  LSize := TWarUnitGeometry.SpriteSize(ATarget);
  Result := ClosestPointOnRect(ATarget^.Position.X, ATarget^.Position.Y, LSize.X, LSize.Y, LPosition);
end;

class function TWarUnitTargeting.DistanceInTiles(AEntity, ATarget: PWarEntity): Integer;
begin
  Result := TWarUnitGeometry.TileDistance(AEntity, TileOnTarget(AEntity, ATarget));
end;

class function TWarUnitTargeting.InRange(AEntity, ATarget: PWarEntity; ARange: Integer): Boolean;
begin
  Result := DistanceInTiles(AEntity, ATarget) <= ARange;
end;

end.
