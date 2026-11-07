{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - building a model from geometry              }
{                                                                              }
{  Port of CollisionModelForMapEntity, ConvertBrush, ConvertBrushSides,        }
{  PolygonFromWinding, CreatePolygon and FinishModel of CollisionModel_load.   }
{  cpp, Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a     }
{  ZeniMax Media company. Doom 3 Source Code: GNU General Public License       }
{  version 3 with additional terms. This unit is a derived work (GPL v3).      }
{                                                                              }
{  Not ported: patches (idSurface_Patch), the removal of polygons chopped away }
{  by the proc BSP or contained in brushes, the merging of coplanar polygons   }
{  and the search of internal edges (see README.md of the library).            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Builder;

interface

uses
  DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Winding, DelphiDoom.Logging.Intf,
  DelphiDoom.Collision.Types, DelphiDoom.Collision.Intf, DelphiDoom.Collision.Model,
  DelphiDoom.Collision.Builder.Table;

type
  /// <summary>
  ///   Builds collision models from brushes and polygons. Replaces the part of
  ///   idCollisionModelManagerLocal that converts a map entity; the input is an
  ///   ICollisionGeometrySource. The builder keeps no state between two models.
  /// </summary>
  TCollisionModelBuilder = class
  private
    FLog: ILog;
    FModel: TCollisionModel;
    FTable: TCollisionGeometryTable;
    procedure ConvertBrush(const ASides: TArray<TCollisionBrushSide>; APrimitiveNum: Integer);
    procedure ConvertBrushSides(const ASides: TArray<TCollisionBrushSide>; APrimitiveNum: Integer);
    procedure CreatePolygon(AWinding: TGeoWinding; const APlane: TGeoPlane; AMaterial: TCollisionMaterial);
    procedure PolygonFromWinding(AWinding: TGeoWinding; const APlane: TGeoPlane;
      AMaterial: TCollisionMaterial; APrimitiveNum: Integer);
    procedure FinishModel;
    procedure Warn(const AText: string);
  public
    /// <summary>ALog may be nil: then warnings are dropped</summary>
    constructor Create(const ALog: ILog);
    /// <summary>
    ///   Builds the model of the source; nil when the source has no brush and no polygon
    ///   (CollisionModelForMapEntity). The caller owns the returned model
    /// </summary>
    function Build(const ASource: ICollisionGeometrySource): TCollisionModel;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Types, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds,
  DelphiDoom.Collision.Model.Types, DelphiDoom.Collision.Model.Polygon,
  DelphiDoom.Collision.Model.Brush, DelphiDoom.Collision.Builder.Bsp,
  DelphiDoom.Collision.Builder.EdgeNormals, DelphiDoom.Collision.Builder.Optimizer;

resourcestring
  SPolygonMoreEdges = 'TCollisionModelBuilder.CreatePolygon: polygon has more than %d edges';
  SPolygonDegenerate = 'TCollisionModelBuilder.PolygonFromWinding: model %s primitive %d is degenerate';

{ TCollisionModelBuilder }

constructor TCollisionModelBuilder.Create(const ALog: ILog);
begin
  inherited Create;
  FLog := ALog;
end;

procedure TCollisionModelBuilder.Warn(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AText);
end;

procedure TCollisionModelBuilder.ConvertBrush(const ASides: TArray<TCollisionBrushSide>; APrimitiveNum: Integer);
var
  LPlanes: TArray<TGeoPlane>;
  LIndex: Integer;
  LOther: Integer;
  LContents: Integer;
  LBounds: TGeoBounds;
  LMaterial: TCollisionMaterial;
  LWinding: TGeoWinding;
  LBrush: TCmBrush;
begin
  LContents := 0;
  LMaterial := nil;
  LBounds.Clear;

  // fix degenerate planes
  SetLength(LPlanes, Length(ASides));
  for LIndex := 0 to High(ASides) do
  begin
    LPlanes[LIndex] := ASides[LIndex].Plane;
    LPlanes[LIndex].FixDegeneracies(DEGENERATE_DIST_EPSILON);
  end;

  // we are only getting the bounds for the brush so there's no need
  // to create a winding for the last brush side
  LWinding := TGeoWinding.Create;
  try
    for LIndex := 0 to Length(ASides) - 2 do
    begin
      LMaterial := ASides[LIndex].Material;
      LContents := LContents or (LMaterial.Contents and CONTENTS_REMOVE_UTIL);
      LWinding.BaseForPlane(-LPlanes[LIndex]);
      LOther := 0;
      while (LOther < Length(ASides)) and (LWinding.NumPoints > 0) do
      begin
        if LIndex <> LOther then
          LWinding.ClipInPlace(-LPlanes[LOther], 0);
        Inc(LOther);
      end;
      for LOther := 0 to LWinding.NumPoints - 1 do
        LBounds.AddPoint(LWinding[LOther]);
    end;
  finally
    LWinding.Free;
  end;
  if LContents = 0 then
    Exit;
  // create brush for position test
  LBrush := FModel.CreateBrush(Length(ASides));
  LBrush.CheckCount := 0;
  LBrush.Contents := LContents;
  LBrush.Material := LMaterial;
  LBrush.PrimitiveNum := APrimitiveNum;
  LBrush.Bounds := LBounds;
  for LIndex := 0 to High(ASides) do
    LBrush.Planes[LIndex] := LPlanes[LIndex];
  FModel.AddBrushToNode(FModel.Node, LBrush);
end;

procedure TCollisionModelBuilder.ConvertBrushSides(const ASides: TArray<TCollisionBrushSide>;
  APrimitiveNum: Integer);
var
  LPlanes: TArray<TGeoPlane>;
  LIndex: Integer;
  LOther: Integer;
  LWinding: TGeoWinding;
begin
  // fix degenerate planes
  SetLength(LPlanes, Length(ASides));
  for LIndex := 0 to High(ASides) do
  begin
    LPlanes[LIndex] := ASides[LIndex].Plane;
    LPlanes[LIndex].FixDegeneracies(DEGENERATE_DIST_EPSILON);
  end;

  // create a collision polygon for each brush side
  LWinding := TGeoWinding.Create;
  try
    for LIndex := 0 to High(ASides) do
    begin
      if (ASides[LIndex].Material.Contents and CONTENTS_REMOVE_UTIL) = 0 then
        Continue;
      LWinding.BaseForPlane(-LPlanes[LIndex]);
      LOther := 0;
      while (LOther < Length(ASides)) and (LWinding.NumPoints > 0) do
      begin
        if LIndex <> LOther then
          LWinding.ClipInPlace(-LPlanes[LOther], 0);
        Inc(LOther);
      end;
      if LWinding.NumPoints > 0 then
        PolygonFromWinding(LWinding, LPlanes[LIndex], ASides[LIndex].Material, APrimitiveNum);
    end;
  finally
    LWinding.Free;
  end;
end;

procedure TCollisionModelBuilder.CreatePolygon(AWinding: TGeoWinding; const APlane: TGeoPlane;
  AMaterial: TCollisionMaterial);
var
  LPolyEdges: TArray<Integer>;
  LNumPolyEdges: Integer;
  LIndex: Integer;
  LNext: Integer;
  LOther: Integer;
  LV1Num: Integer;
  LEdgeNum: Integer;
  LEdgeVertex: Integer;
  LPolygon: TCmPolygon;
  LBsp: TCollisionBspBuilder;
begin
  SetLength(LPolyEdges, AWinding.NumPoints);
  // turn the winding into a sequence of edges
  LNumPolyEdges := 0;
  LV1Num := -1; // first vertex unknown
  LNext := 1;
  for LIndex := 0 to AWinding.NumPoints - 1 do
  begin
    if LNext >= AWinding.NumPoints then
      LNext := 0;
    FTable.GetEdge(AWinding[LIndex], AWinding[LNext], LEdgeNum, LV1Num);
    LPolyEdges[LNumPolyEdges] := LEdgeNum;
    if LEdgeNum <> 0 then
    begin
      // last vertex of this edge is the first vertex of the next edge
      if LEdgeNum >= 0 then
        LEdgeVertex := 1
      else
        LEdgeVertex := 0;
      LV1Num := FModel.Edges[Abs(LEdgeNum)].VertexNum[LEdgeVertex];
      // this edge is valid so keep it
      Inc(LNumPolyEdges);
    end;
    Inc(LNext);
  end;
  // should have at least 3 edges
  if LNumPolyEdges < 3 then
    Exit;
  // the polygon is invalid if some edge is found twice
  for LIndex := 0 to LNumPolyEdges - 1 do
    for LOther := LIndex + 1 to LNumPolyEdges - 1 do
      if Abs(LPolyEdges[LIndex]) = Abs(LPolyEdges[LOther]) then
        Exit;
  // don't overflow max edges
  if LNumPolyEdges > CM_MAX_POLYGON_EDGES then
  begin
    Warn(Format(SPolygonMoreEdges, [LNumPolyEdges]));
    LNumPolyEdges := CM_MAX_POLYGON_EDGES;
  end;

  LPolygon := FModel.CreatePolygon(LNumPolyEdges);
  LPolygon.Contents := AMaterial.Contents;
  LPolygon.Material := AMaterial;
  LPolygon.CheckCount := 0;
  LPolygon.Plane := APlane;
  LPolygon.Bounds := AWinding.GetBounds;
  for LIndex := 0 to LNumPolyEdges - 1 do
    LPolygon.Edges[LIndex] := LPolyEdges[LIndex];
  LBsp := TCollisionBspBuilder.Create(FModel);
  try
    LBsp.FilterPolygonIntoTree(FModel.Node, LPolygon);
  finally
    LBsp.Free;
  end;
end;

procedure TCollisionModelBuilder.PolygonFromWinding(AWinding: TGeoWinding; const APlane: TGeoPlane;
  AMaterial: TCollisionMaterial; APrimitiveNum: Integer);
begin
  if AWinding.IsHuge then
  begin
    Warn(Format(SPolygonDegenerate, [FModel.Name, Abs(APrimitiveNum)]));
    Exit;
  end;

  CreatePolygon(AWinding, APlane, AMaterial);

  if AMaterial.TwoSided then
  begin
    AWinding.ReverseSelf;
    CreatePolygon(AWinding, -APlane, AMaterial);
  end;
end;

procedure TCollisionModelBuilder.FinishModel;
begin
  // calculate edge normals
  TCollisionEdgeNormals.Calculate(FModel);
  // remove all unused vertices and edges
  TCollisionArrayOptimizer.Optimize(FModel);
  // get model bounds from brush and polygon bounds
  FModel.CalculateBounds;
  // get model contents
  FModel.CalculateContents;
end;

function TCollisionModelBuilder.Build(const ASource: ICollisionGeometrySource): TCollisionModel;
var
  LIndex: Integer;
  LBrushCount: Integer;
  LBounds: TGeoBounds;
  LBsp: TCollisionBspBuilder;
  LWinding: TGeoWinding;
begin
  Result := nil;
  if (ASource.BrushCount + ASource.PolygonCount) < 1 then
    Exit;

  FModel := TCollisionModel.Create;
  FTable := TCollisionGeometryTable.Create(FModel);
  try
    try
      FModel.Name := ASource.ModelName;
      FModel.IsConvex := False;
      FModel.Node := FModel.CreateNode(nil);

      // convert brushes
      for LIndex := 0 to ASource.BrushCount - 1 do
        ConvertBrush(ASource.BrushSides(LIndex), LIndex);

      // create an axial bsp tree for the model if it has more than just a bunch brushes
      LBrushCount := FModel.Node.Brushes.Count;
      if LBrushCount > 4 then
      begin
        LBsp := TCollisionBspBuilder.Create(FModel);
        try
          FModel.Node := LBsp.CreateAxialBSPTree(FModel.Node);
        finally
          LBsp.Free;
        end;
      end
      else
        FModel.Node.PlaneType := -1;

      // get bounds for hash
      if LBrushCount > 0 then
      begin
        FModel.CalculateBounds;
        LBounds := FModel.Bounds;
      end
      else
      begin
        LBounds.Mins := TGeoVec3.Make(-256, -256, -256);
        LBounds.Maxs := TGeoVec3.Make(256, 256, 256);
      end;

      // different models do not share edges and vertices with each other, so clear the hash
      FTable.Clear(LBounds);

      // create polygons from the brush sides and from the loose polygons
      for LIndex := 0 to ASource.BrushCount - 1 do
        ConvertBrushSides(ASource.BrushSides(LIndex), LIndex);
      for LIndex := 0 to ASource.PolygonCount - 1 do
      begin
        if (ASource.PolygonMaterial(LIndex).Contents and CONTENTS_REMOVE_UTIL) = 0 then
          Continue;
        LWinding := ASource.PolygonWinding(LIndex);
        try
          PolygonFromWinding(LWinding, ASource.PolygonPlane(LIndex), ASource.PolygonMaterial(LIndex),
            ASource.BrushCount + LIndex);
        finally
          LWinding.Free;
        end;
      end;

      FinishModel;
      Result := FModel;
    except
      FModel.Free;
      raise;
    end;
  finally
    FreeAndNil(FTable);
    FModel := nil;
  end;
end;

end.
