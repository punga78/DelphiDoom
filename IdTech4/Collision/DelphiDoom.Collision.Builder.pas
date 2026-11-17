{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - building a model from geometry              }
{                                                                              }
{  Port of CollisionModelForMapEntity, ConvertBrush, ConvertBrushSides,        }
{  ConvertPatch, CreatePatchPolygons, PolygonFromWinding, CreatePolygon and    }
{  FinishModel of CollisionModel_load.cpp, Doom 3 GPL Source Code. Copyright   }
{  (C) 1999-2011 id Software LLC, a ZeniMax Media company. Based on the Doom   }
{  3 GPL Source Code (id Software). This unit is derived from the Doom 3 GPL   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 3 or (at your option) any later version, with the          }
{  additional terms of the Doom 3 Source Code License                          }
{  (Reference\doom3\COPYING.txt: preservation of legal notices and             }
{  trademarks, no use of the licensors' names for publicity, warranty          }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{  The merging of polygons, the internal edges, the removal of polygons that   }
{  are inside brushes or in solid space of the proc BSP tree are in the units   }
{  Builder.Merger, Builder.InternalEdges and Builder.Chopper.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Builder;

interface

uses
  DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Winding, DelphiDoom.Geometry.Surface.Patch,
  DelphiDoom.Logging.Intf, DelphiDoom.MapFile.Entity, DelphiDoom.MapFile.Patch, DelphiDoom.MapFile.Brush,
  DelphiDoom.Collision.Types, DelphiDoom.Collision.Intf, DelphiDoom.Collision.Model,
  DelphiDoom.Collision.CheckCounter, DelphiDoom.Collision.Builder.Table, DelphiDoom.Collision.Builder.Chopper;

type
  /// <summary>
  ///   Builds collision models from brushes, patches and polygons. Replaces the part of
  ///   idCollisionModelManagerLocal that converts a map entity; the input is a map entity
  ///   (BuildFromEntity) or an ICollisionGeometrySource. The builder keeps no state between two models.
  /// </summary>
  TCollisionModelBuilder = class
  private
    FLog: ILog;
    FModel: TCollisionModel;
    FTable: TCollisionGeometryTable;
    FCounter: TCollisionCheckCounter;
    FChopper: TCollisionChopper;
    FProcNodes: TArray<TCollisionProcNode>;
    FModelNumber: Integer;
    procedure ConvertBrush(const ASides: TArray<TCollisionBrushSide>; APrimitiveNum: Integer);
    procedure ConvertBrushSides(const ASides: TArray<TCollisionBrushSide>; APrimitiveNum: Integer);
    procedure CreatePolygon(AWinding: TGeoWinding; const APlane: TGeoPlane; AMaterial: TCollisionMaterial);
    procedure PolygonFromWinding(AWinding: TGeoWinding; const APlane: TGeoPlane;
      AMaterial: TCollisionMaterial; APrimitiveNum: Integer);
    procedure CreatePatchPolygons(AMesh: TGeoSurfacePatch; AMaterial: TCollisionMaterial; APrimitiveNum: Integer);
    procedure ConvertPatch(APatch: TMapPatch; const ACatalog: ICollisionMaterialCatalog; APrimitiveNum: Integer);
    procedure FinishModel;
    procedure BeginModel(const AName: string);
    procedure PrepareHash;
    procedure EndModel;
    procedure Warn(const AText: string);
    class function SidesOf(ABrush: TMapBrush; const ACatalog: ICollisionMaterialCatalog): TArray<TCollisionBrushSide>; static;
  public
    /// <summary>ALog may be nil: then warnings are dropped</summary>
    constructor Create(const ALog: ILog);
    /// <summary>
    ///   The nodes of the proc BSP tree that remove polygons which lie in solid space (LoadProcBSP);
    ///   only the world model (model number 0) is cleaned with it. An empty array: no pruning
    /// </summary>
    procedure SetProcNodes(const ANodes: TArray<TCollisionProcNode>);
    /// <summary>
    ///   Builds the model of the source; nil when the source has no brush and no polygon
    ///   (CollisionModelForMapEntity). The caller owns the returned model
    /// </summary>
    function Build(const ASource: ICollisionGeometrySource): TCollisionModel;
    /// <summary>
    ///   Builds the model of a map entity (CollisionModelForMapEntity): its brushes and patches, in
    ///   the order of the primitives (the primitive number is the index). AModelNumber is the number of
    ///   models built so far (0: the world). The name is the "model" key, else the "name" key, else
    ///   "worldMap" for the first model and "unnamed inline model" for the others. Nil when the entity has
    ///   no primitive. The caller owns the returned model
    /// </summary>
    function BuildFromEntity(AEntity: TMapEntity; const ACatalog: ICollisionMaterialCatalog;
      AModelNumber: Integer): TCollisionModel;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Types, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds,
  DelphiDoom.Geometry.DrawVert, DelphiDoom.Geometry.FloatMath, DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.MapFile.Primitive, DelphiDoom.MapFile.BrushSide, DelphiDoom.MapFile.Types,
  DelphiDoom.Collision.Model.Types, DelphiDoom.Collision.Model.Polygon,
  DelphiDoom.Collision.Model.Brush, DelphiDoom.Collision.Builder.Bsp,
  DelphiDoom.Collision.Builder.EdgeNormals, DelphiDoom.Collision.Builder.Optimizer,
  DelphiDoom.Collision.Builder.Merger, DelphiDoom.Collision.Builder.InternalEdges;

resourcestring
  SPolygonMoreEdges = 'TCollisionModelBuilder.CreatePolygon: polygon has more than %d edges';
  SPolygonDegenerate = 'TCollisionModelBuilder.PolygonFromWinding: model %s primitive %d is degenerate';
  SWorldMap = 'worldMap';
  SUnnamedModel = 'unnamed inline model';

{ TCollisionModelBuilder }

constructor TCollisionModelBuilder.Create(const ALog: ILog);
begin
  inherited Create;
  FLog := ALog;
end;

procedure TCollisionModelBuilder.SetProcNodes(const ANodes: TArray<TCollisionProcNode>);
begin
  FProcNodes := ANodes;
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
var
  LContents: Integer;
  LWinding: TGeoWinding;
begin
  LContents := AMaterial.Contents;

  // if this polygon is part of the world model
  if FModelNumber = 0 then
    // if the polygon is fully chopped away by the proc bsp tree
    if FChopper.ChoppedAwayByProcBSP(AWinding, APlane, LContents) then
    begin
      Inc(FModel.NumRemovedPolys);
      Exit;
    end;

  // get one winding that is not or only partly contained in brushes
  LWinding := FChopper.WindingOutsideBrushes(AWinding, APlane, LContents, APrimitiveNum, FModel.Node);

  // if the polygon is fully contained within a brush
  if not Assigned(LWinding) then
  begin
    Inc(FModel.NumRemovedPolys);
    Exit;
  end;
  try
    if LWinding.IsHuge then
    begin
      Warn(Format(SPolygonDegenerate, [FModel.Name, Abs(APrimitiveNum)]));
      Exit;
    end;

    CreatePolygon(LWinding, APlane, AMaterial);

    if AMaterial.TwoSided then
    begin
      LWinding.ReverseSelf;
      CreatePolygon(LWinding, -APlane, AMaterial);
    end;
  finally
    if LWinding <> AWinding then
      LWinding.Free;
  end;
end;

procedure TCollisionModelBuilder.CreatePatchPolygons(AMesh: TGeoSurfacePatch; AMaterial: TCollisionMaterial;
  APrimitiveNum: Integer);
var
  LI: Integer;
  LJ: Integer;
  LV1: Integer;
  LV2: Integer;
  LV3: Integer;
  LV4: Integer;
  LDot: Single;
  LWinding: TGeoWinding;
  LPlane: TGeoPlane;
  LD1: TGeoVec3;
  LD2: TGeoVec3;
  LMesh: array of TGeoVec3;
  LCount: Integer;
begin
  LCount := AMesh.NumVertices;
  SetLength(LMesh, LCount);
  for LI := 0 to LCount - 1 do
    LMesh[LI] := AMesh.Vertices[LI].Xyz;

  LWinding := TGeoWinding.Create;
  try
    for LI := 0 to AMesh.Width - 2 do
      for LJ := 0 to AMesh.Height - 2 do
      begin
        LV1 := LJ * AMesh.Width + LI;
        LV2 := LV1 + 1;
        LV3 := LV1 + AMesh.Width + 1;
        LV4 := LV1 + AMesh.Width;

        LD1 := LMesh[LV2] - LMesh[LV1];
        LD2 := LMesh[LV3] - LMesh[LV1];
        LPlane.SetNormal(LD1.Cross(LD2));
        if LPlane.NormalizeSelf <> 0 then
        begin
          LPlane.FitThroughPoint(LMesh[LV1]);
          LDot := LPlane.Distance(LMesh[LV4]);
          // if we can turn it into a quad
          if TGeoMath.Fabs(LDot) < 0.1 then
          begin
            LWinding.Clear;
            LWinding.AddPoint(LMesh[LV1]);
            LWinding.AddPoint(LMesh[LV2]);
            LWinding.AddPoint(LMesh[LV3]);
            LWinding.AddPoint(LMesh[LV4]);

            PolygonFromWinding(LWinding, LPlane, AMaterial, -APrimitiveNum);
            Continue;
          end
          else
          begin
            // create one of the triangles
            LWinding.Clear;
            LWinding.AddPoint(LMesh[LV1]);
            LWinding.AddPoint(LMesh[LV2]);
            LWinding.AddPoint(LMesh[LV3]);

            PolygonFromWinding(LWinding, LPlane, AMaterial, -APrimitiveNum);
          end;
        end;
        // create the other triangle
        LD1 := LMesh[LV3] - LMesh[LV1];
        LD2 := LMesh[LV4] - LMesh[LV1];
        LPlane.SetNormal(LD1.Cross(LD2));
        if LPlane.NormalizeSelf <> 0 then
        begin
          LPlane.FitThroughPoint(LMesh[LV1]);

          LWinding.Clear;
          LWinding.AddPoint(LMesh[LV1]);
          LWinding.AddPoint(LMesh[LV3]);
          LWinding.AddPoint(LMesh[LV4]);

          PolygonFromWinding(LWinding, LPlane, AMaterial, -APrimitiveNum);
        end;
      end;
  finally
    LWinding.Free;
  end;
end;

procedure TCollisionModelBuilder.ConvertPatch(APatch: TMapPatch; const ACatalog: ICollisionMaterialCatalog;
  APrimitiveNum: Integer);
var
  LMaterial: TCollisionMaterial;
  LCopy: TGeoSurfacePatch;
  LIndex: Integer;
  LVert: TGeoDrawVert;
  LSource: TMapPatchVertex;
begin
  LMaterial := ACatalog.FindMaterial(string(APatch.Material));
  if (LMaterial.Contents and CONTENTS_REMOVE_UTIL) = 0 then
    Exit;

  // copy the patch
  LCopy := TGeoSurfacePatch.Create(APatch.Width, APatch.Height);
  try
    LCopy.SetSize(APatch.Width, APatch.Height);
    for LIndex := 0 to APatch.GetNumVertices - 1 do
    begin
      LSource := APatch.Vertices[LIndex];
      LVert := Default(TGeoDrawVert);
      LVert.Xyz := LSource.Position;
      LVert.St := TIdVec2.Create(LSource.S, LSource.T);
      LCopy.Vertices[LIndex] := LVert;
    end;

    // if the patch has an explicit number of subdivisions use it to avoid cracks
    if APatch.ExplicitlySubdivided then
      LCopy.SubdivideExplicit(APatch.HorzSubdivisions, APatch.VertSubdivisions, False, True)
    else
      LCopy.Subdivide(DEFAULT_CURVE_MAX_ERROR_CD, DEFAULT_CURVE_MAX_ERROR_CD, DEFAULT_CURVE_MAX_LENGTH_CD, False);

    // create collision polygons for the patch
    CreatePatchPolygons(LCopy, LMaterial, APrimitiveNum);
  finally
    LCopy.Free;
  end;
end;

procedure TCollisionModelBuilder.FinishModel;
var
  LMerger: TCollisionPolygonMerger;
  LInternal: TCollisionInternalEdges;
begin
  // try to merge polygons
  FCounter.Next;
  LMerger := TCollisionPolygonMerger.Create(FModel, FTable, FCounter);
  try
    LMerger.MergeTreePolygons(FModel.Node);
  finally
    LMerger.Free;
  end;
  // find internal edges (no mesh can ever collide with internal edges)
  FCounter.Next;
  LInternal := TCollisionInternalEdges.Create(FModel, FCounter);
  try
    LInternal.FindInternalEdges(FModel.Node);
  finally
    LInternal.Free;
  end;
  // calculate edge normals
  TCollisionEdgeNormals.Calculate(FModel);
  // remove all unused vertices and edges
  TCollisionArrayOptimizer.Optimize(FModel);
  // get model bounds from brush and polygon bounds
  FModel.CalculateBounds;
  // get model contents
  FModel.CalculateContents;
end;

procedure TCollisionModelBuilder.BeginModel(const AName: string);
begin
  FModel := TCollisionModel.Create;
  FTable := TCollisionGeometryTable.Create(FModel);
  FCounter := TCollisionCheckCounter.Create;
  FChopper := TCollisionChopper.Create(FModel, FCounter, FProcNodes, FModelNumber = 0, FLog);
  FModel.Name := AName;
  FModel.IsConvex := False;
  FModel.Node := FModel.CreateNode(nil);
end;

procedure TCollisionModelBuilder.PrepareHash;
var
  LBrushCount: Integer;
  LBounds: TGeoBounds;
  LBsp: TCollisionBspBuilder;
begin
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
end;

procedure TCollisionModelBuilder.EndModel;
begin
  FreeAndNil(FChopper);
  FreeAndNil(FCounter);
  FreeAndNil(FTable);
  FModel := nil;
end;

class function TCollisionModelBuilder.SidesOf(ABrush: TMapBrush;
  const ACatalog: ICollisionMaterialCatalog): TArray<TCollisionBrushSide>;
var
  LIndex: Integer;
begin
  SetLength(Result, ABrush.GetNumSides);
  for LIndex := 0 to High(Result) do
  begin
    Result[LIndex].Plane := ABrush.GetSide(LIndex).Plane;
    Result[LIndex].Material := ACatalog.FindMaterial(string(ABrush.GetSide(LIndex).Material));
  end;
end;

function TCollisionModelBuilder.Build(const ASource: ICollisionGeometrySource): TCollisionModel;
var
  LIndex: Integer;
  LWinding: TGeoWinding;
begin
  Result := nil;
  if (ASource.BrushCount + ASource.PolygonCount) < 1 then
    Exit;

  FModelNumber := 1;
  BeginModel(ASource.ModelName);
  try
    try
      // convert brushes
      for LIndex := 0 to ASource.BrushCount - 1 do
        ConvertBrush(ASource.BrushSides(LIndex), LIndex);

      PrepareHash;

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
    EndModel;
  end;
end;

function TCollisionModelBuilder.BuildFromEntity(AEntity: TMapEntity; const ACatalog: ICollisionMaterialCatalog;
  AModelNumber: Integer): TCollisionModel;
var
  LIndex: Integer;
  LName: string;
  LPrimitive: TMapPrimitive;
begin
  Result := nil;
  // if the entity has no primitives
  if AEntity.GetNumPrimitives < 1 then
    Exit;

  // get a name for the collision model
  LName := string(AEntity.Epairs.GetString('model', ''));
  if LName = '' then
  begin
    LName := string(AEntity.Epairs.GetString('name', ''));
    if LName = '' then
    begin
      if AModelNumber = 0 then
        // first model is always the world
        LName := SWorldMap
      else
        LName := SUnnamedModel;
    end;
  end;

  FModelNumber := AModelNumber;
  BeginModel(LName);
  try
    try
      // convert brushes
      for LIndex := 0 to AEntity.GetNumPrimitives - 1 do
      begin
        LPrimitive := AEntity.GetPrimitive(LIndex);
        if LPrimitive.PrimitiveType = mptBrush then
          ConvertBrush(SidesOf(TMapBrush(LPrimitive), ACatalog), LIndex);
      end;

      PrepareHash;

      // create polygons from patches and brushes
      for LIndex := 0 to AEntity.GetNumPrimitives - 1 do
      begin
        LPrimitive := AEntity.GetPrimitive(LIndex);
        if LPrimitive.PrimitiveType = mptPatch then
          ConvertPatch(TMapPatch(LPrimitive), ACatalog, LIndex)
        else if LPrimitive.PrimitiveType = mptBrush then
          ConvertBrushSides(SidesOf(TMapBrush(LPrimitive), ACatalog), LIndex);
      end;

      FinishModel;
      Result := FModel;
    except
      FModel.Free;
      raise;
    end;
  finally
    EndModel;
  end;
end;

end.
