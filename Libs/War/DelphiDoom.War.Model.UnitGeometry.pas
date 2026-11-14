{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - where a unit is                                   }
{                                                                              }
{  Port of war1 (acoto87/war1), the wu_getUnit*Position/Tile/Size/Center and   }
{  wu_setUnit*Position functions of war_units.c, (c) 2019 Alejandro Coto       }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.UnitGeometry;

interface

uses
  DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Math;

type
  /// <summary>
  ///   The geometry of a unit: the position is the top left corner in pixels, the center is half the size of its
  ///   sprite (the size in tiles by 16) away. Static functions on the entity: the loops of the states use them
  /// </summary>
  TWarUnitGeometry = class
  public
    /// <summary>wu_getUnitSpriteSize: the size in pixels (the original does not read the frame of the sprite here)</summary>
    class function SpriteSize(AEntity: PWarEntity): TWarVec2; static;
    /// <summary>wu_getUnitTile: the tile of the top left corner</summary>
    class function Tile(AEntity: PWarEntity): TWarVec2; static;
    /// <summary>wu_getUnitCenterPosition</summary>
    class function CenterPosition(AEntity: PWarEntity): TWarVec2; static;
    /// <summary>wu_getUnitCenterTile</summary>
    class function CenterTile(AEntity: PWarEntity): TWarVec2; static;
    /// <summary>wu_setUnitCenterPosition</summary>
    class procedure SetCenterPosition(AEntity: PWarEntity; const APosition: TWarVec2); static;
    /// <summary>wu_getUnitActionScale: 1 - speed * 0.1</summary>
    class function ActionScale(AEntity: PWarEntity): Single; static;
    /// <summary>wu_entityTileDistance: tiles from the center tile of the unit to a tile</summary>
    class function TileDistance(AEntity: PWarEntity; const ATargetTile: TWarVec2): Integer; static;
    /// <summary>wu_tileInRange</summary>
    class function TileInRange(AEntity: PWarEntity; const ATargetTile: TWarVec2; ARange: Integer): Boolean; static;
  end;

implementation

const
  // 0.1f of the original: the float, not the double 0.1
  SINGLE_TENTH: Single = 0.1;

{ TWarUnitGeometry }

class function TWarUnitGeometry.SpriteSize(AEntity: PWarEntity): TWarVec2;
begin
  Result.X := AEntity^.UnitData.SizeX * WAR_MEGA_TILE_SIZE;
  Result.Y := AEntity^.UnitData.SizeY * WAR_MEGA_TILE_SIZE;
end;

class function TWarUnitGeometry.Tile(AEntity: PWarEntity): TWarVec2;
begin
  Result := TWarModelMath.MapToTile(AEntity^.Position);
end;

class function TWarUnitGeometry.CenterPosition(AEntity: PWarEntity): TWarVec2;
begin
  Result := TWarModelMath.Add(AEntity^.Position, TWarModelMath.Half(SpriteSize(AEntity)));
end;

class function TWarUnitGeometry.CenterTile(AEntity: PWarEntity): TWarVec2;
begin
  Result := TWarModelMath.MapToTile(CenterPosition(AEntity));
end;

class procedure TWarUnitGeometry.SetCenterPosition(AEntity: PWarEntity; const APosition: TWarVec2);
begin
  AEntity^.Position := TWarModelMath.Sub(APosition, TWarModelMath.Half(SpriteSize(AEntity)));
end;

class function TWarUnitGeometry.ActionScale(AEntity: PWarEntity): Single;
var
  LStep: Single;
begin
  LStep := AEntity^.UnitData.Speed * SINGLE_TENTH;
  Result := 1 - LStep;
end;

class function TWarUnitGeometry.TileDistance(AEntity: PWarEntity; const ATargetTile: TWarVec2): Integer;
begin
  Result := Trunc(TWarModelMath.DistanceInTiles(CenterTile(AEntity), ATargetTile));
end;

class function TWarUnitGeometry.TileInRange(AEntity: PWarEntity; const ATargetTile: TWarVec2;
  ARange: Integer): Boolean;
begin
  Result := TileDistance(AEntity, ATargetTile) <= ARange;
end;

end.
