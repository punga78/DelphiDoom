{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the collision library - helpers                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 (the library       }
{  derives from Doom 3 GPL Source Code)                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Collision.Support;

interface

uses
  System.Generics.Collections, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane,
  DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Winding, DelphiDoom.Collision.Types,
  DelphiDoom.Collision.Intf, DelphiDoom.Collision.Model;

type
  /// <summary>A material catalog that creates a solid material for every new name</summary>
  TFakeMaterialCatalog = class(TInterfacedObject, ICollisionMaterialCatalog)
  private
    FMaterials: TObjectDictionary<string, TCollisionMaterial>;
  public
    constructor Create;
    destructor Destroy; override;
    function FindMaterial(const AName: string): TCollisionMaterial;
    /// <summary>Registers a material with given contents, replacing an existing one of the same name</summary>
    function Define(const AName: string; AContents: Integer; ATwoSided: Boolean = False): TCollisionMaterial;
  end;

  /// <summary>Geometry source made of lists, for the tests</summary>
  TFakeGeometrySource = class(TInterfacedObject, ICollisionGeometrySource)
  private
    FName: string;
    FBrushes: TList<TArray<TCollisionBrushSide>>;
    FWindings: TObjectList<TGeoWinding>;
    FPlanes: TList<TGeoPlane>;
    FMaterials: TList<TCollisionMaterial>;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;
    procedure AddBox(const ABounds: TGeoBounds; AMaterial: TCollisionMaterial);
    /// <summary>A brush from its sides (any convex brush)</summary>
    procedure AddBrushSides(const ASides: TArray<TCollisionBrushSide>);
    /// <summary>Takes a copy of the winding</summary>
    procedure AddPolygon(AWinding: TGeoWinding; const APlane: TGeoPlane; AMaterial: TCollisionMaterial);
    function ModelName: string;
    function BrushCount: Integer;
    function BrushSides(ABrushIndex: Integer): TArray<TCollisionBrushSide>;
    function PolygonCount: Integer;
    function PolygonWinding(APolygonIndex: Integer): TGeoWinding;
    function PolygonPlane(APolygonIndex: Integer): TGeoPlane;
    function PolygonMaterial(APolygonIndex: Integer): TCollisionMaterial;
  end;

/// <summary>The six outward planes of a box</summary>
function BoxSides(const ABounds: TGeoBounds; AMaterial: TCollisionMaterial): TArray<TCollisionBrushSide>;
function Bounds3(AMinX, AMinY, AMinZ, AMaxX, AMaxY, AMaxZ: Single): TGeoBounds;

implementation

function Bounds3(AMinX, AMinY, AMinZ, AMaxX, AMaxY, AMaxZ: Single): TGeoBounds;
begin
  Result.Mins := TGeoVec3.Make(AMinX, AMinY, AMinZ);
  Result.Maxs := TGeoVec3.Make(AMaxX, AMaxY, AMaxZ);
end;

function BoxSides(const ABounds: TGeoBounds; AMaterial: TCollisionMaterial): TArray<TCollisionBrushSide>;
begin
  SetLength(Result, 6);
  Result[0].Plane := TGeoPlane.Make(TGeoVec3.Make(1, 0, 0), ABounds.Maxs.X);
  Result[1].Plane := TGeoPlane.Make(TGeoVec3.Make(-1, 0, 0), -ABounds.Mins.X);
  Result[2].Plane := TGeoPlane.Make(TGeoVec3.Make(0, 1, 0), ABounds.Maxs.Y);
  Result[3].Plane := TGeoPlane.Make(TGeoVec3.Make(0, -1, 0), -ABounds.Mins.Y);
  Result[4].Plane := TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), ABounds.Maxs.Z);
  Result[5].Plane := TGeoPlane.Make(TGeoVec3.Make(0, 0, -1), -ABounds.Mins.Z);
  Result[0].Material := AMaterial;
  Result[1].Material := AMaterial;
  Result[2].Material := AMaterial;
  Result[3].Material := AMaterial;
  Result[4].Material := AMaterial;
  Result[5].Material := AMaterial;
end;

{ TFakeMaterialCatalog }

constructor TFakeMaterialCatalog.Create;
begin
  inherited Create;
  FMaterials := TObjectDictionary<string, TCollisionMaterial>.Create([doOwnsValues]);
end;

destructor TFakeMaterialCatalog.Destroy;
begin
  FMaterials.Free;
  inherited Destroy;
end;

function TFakeMaterialCatalog.FindMaterial(const AName: string): TCollisionMaterial;
begin
  if not FMaterials.TryGetValue(AName, Result) then
    Result := Define(AName, CONTENTS_SOLID);
end;

function TFakeMaterialCatalog.Define(const AName: string; AContents: Integer;
  ATwoSided: Boolean): TCollisionMaterial;
begin
  Result := TCollisionMaterial.Create(AName, AContents, ATwoSided);
  FMaterials.AddOrSetValue(AName, Result);
end;

{ TFakeGeometrySource }

constructor TFakeGeometrySource.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FBrushes := TList<TArray<TCollisionBrushSide>>.Create;
  FWindings := TObjectList<TGeoWinding>.Create(True);
  FPlanes := TList<TGeoPlane>.Create;
  FMaterials := TList<TCollisionMaterial>.Create;
end;

destructor TFakeGeometrySource.Destroy;
begin
  FMaterials.Free;
  FPlanes.Free;
  FWindings.Free;
  FBrushes.Free;
  inherited Destroy;
end;

procedure TFakeGeometrySource.AddBox(const ABounds: TGeoBounds; AMaterial: TCollisionMaterial);
begin
  FBrushes.Add(BoxSides(ABounds, AMaterial));
end;

procedure TFakeGeometrySource.AddBrushSides(const ASides: TArray<TCollisionBrushSide>);
begin
  FBrushes.Add(ASides);
end;

procedure TFakeGeometrySource.AddPolygon(AWinding: TGeoWinding; const APlane: TGeoPlane;
  AMaterial: TCollisionMaterial);
begin
  FWindings.Add(AWinding.Copy);
  FPlanes.Add(APlane);
  FMaterials.Add(AMaterial);
end;

function TFakeGeometrySource.ModelName: string;
begin
  Result := FName;
end;

function TFakeGeometrySource.BrushCount: Integer;
begin
  Result := FBrushes.Count;
end;

function TFakeGeometrySource.BrushSides(ABrushIndex: Integer): TArray<TCollisionBrushSide>;
begin
  Result := FBrushes[ABrushIndex];
end;

function TFakeGeometrySource.PolygonCount: Integer;
begin
  Result := FWindings.Count;
end;

function TFakeGeometrySource.PolygonWinding(APolygonIndex: Integer): TGeoWinding;
begin
  Result := FWindings[APolygonIndex].Copy;
end;

function TFakeGeometrySource.PolygonPlane(APolygonIndex: Integer): TGeoPlane;
begin
  Result := FPlanes[APolygonIndex];
end;

function TFakeGeometrySource.PolygonMaterial(APolygonIndex: Integer): TCollisionMaterial;
begin
  Result := FMaterials[APolygonIndex];
end;

end.
