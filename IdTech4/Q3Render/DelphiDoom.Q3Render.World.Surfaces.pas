{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R1) - the surfaces of  }
{  the world that a view sees                                                  }
{                                                                              }
{  R_MarkLeaves, R_RecursiveWorldNode, R_CullSurface (with R_CullGrid and      }
{  R_CullTriSurf), R_DlightSurface, R_AddWorldSurface, R_AddWorldSurfaces and  }
{  R_AddBrushModelSurfaces of renderer\tr_world.c, over the tree, the PVS      }
{  and the surfaces that TQ3WorldLoader keeps. Based on the Quake III Arena    }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.World.Surfaces;

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.MapFile.Bsp.Types,
  DelphiDoom.MapFile.Bsp.RenderTypes,
  DelphiDoom.MathCore.Patch.Intf, DelphiDoom.Q3Render.Scene.Types, DelphiDoom.Q3Render.Intf,
  DelphiDoom.Q3Render.View.Culler, DelphiDoom.Q3Render.Draw.List;

type
  /// <summary>
  ///   The world of a renderer for the views of a frame: which nodes the PVS marks, which surfaces the frustum and the
  ///   back face test leave, and the drawSurfs they become. It holds the state that the C keeps in the nodes
  ///   (visframe) and in the surfaces (viewCount), and the shader table index of every surface
  /// </summary>
  TQ3WorldSurfaceAdder = class
  strict private
    FWorld: IQ3RenderWorld;
    FShaders: IQ3ShaderTable;
    FSettings: TQ3RenderSettings;
    FNodes: TArray<TBspRenderNode>;
    FNodeMins: TArray<TQ3Vec3>;
    FNodeMaxs: TArray<TQ3Vec3>;
    FPlanes: TArray<TQ3Plane>;
    FLeafSurfaces: TArray<Integer>;
    FSurfaces: TArray<TQ3WorldSurface>;
    FGrids: TArray<IPatchGrid>;
    FFaces: TArray<TBspFaceSurface>;
    FTriangles: TArray<TBspTriangleSurface>;
    FVisibility: TBspVisibility;
    FSurfaceShader: TArray<Integer>;
    FSurfaceViewCount: TArray<Integer>;
    FVisFrame: TArray<Integer>;
    FVisCount: Integer;
    FViewCluster: Integer;
    FMarked: Boolean;
    FStats: TQ3FrontEndStats;
    // the view that is being added
    FVisBounds: array[0..1] of TQ3Vec3;
    FRefDef: TQ3RefDef;
    FCuller: TQ3ViewCuller;
    FList: TQ3DrawList;
    FViewOrigin: TQ3Vec3;
    FPvsOrigin: TQ3Vec3;
    FDlights: TArray<TQ3DynamicLight>;
    FDlightCount: Integer;
    FViewCount: Integer;
    FCurrentIsWorld: Boolean;
    FAreaMaskModified: Boolean;
    FOrientationViewOrigin: TQ3Vec3;
    procedure ResolveWorld;
    function PointInLeaf(const APoint: TQ3Vec3): Integer;
    procedure MarkLeaves;
    function CullGrid(ASurface: Integer): Boolean;
    function CullSurface(ASurface: Integer): Boolean;
    function DlightSurface(ASurface, ADlightBits: Integer): Integer;
    procedure AddWorldSurface(ASurface, ADlightBits: Integer);
    procedure RecursiveWorldNode(ANode, APlaneBits, ADlightBits: Integer);
  public
    constructor Create(const AWorld: IQ3RenderWorld; const AShaders: IQ3ShaderTable;
      const ASettings: TQ3RenderSettings);
    /// <summary>The shader table index of a surface (what ShaderForShaderNum resolved)</summary>
    function SurfaceShader(ASurface: Integer): Integer;
    /// <summary>
    ///   The view the next calls add to: the position of the viewer and where the PVS is taken from, the refdef (the
    ///   mask of the shut areas, the flags), the culler with the frustum, the list that gets the surfaces, the
    ///   dlights of the scene and tr.viewCount in AViewCount (it is increased twice for every view, and a surface
    ///   already added for this count is not added again)
    /// </summary>
    procedure BeginView(const AViewOrigin, APvsOrigin: TQ3Vec3; const ARefDef: TQ3RefDef;
      const ACuller: TQ3ViewCuller; const AList: TQ3DrawList; const ADlights: TArray<TQ3DynamicLight>;
      ADlightCount, AViewCount: Integer; AAreaMaskModified: Boolean);
    /// <summary>R_AddWorldSurfaces; AVisBounds gets the bounds of the leafs that were reached (ClearBounds first)</summary>
    procedure AddWorldSurfaces(var AMins, AMaxs: TQ3Vec3);
    /// <summary>
    ///   R_AddBrushModelSurfaces for the brush model N of an entity (the culler has its orientation); the origin of
    ///   the viewer is the one of the orientation (tr.or.viewOrigin)
    /// </summary>
    procedure AddBrushModelSurfaces(ABrushIndex: Integer; const AOrientationViewOrigin: TQ3Vec3);
    property Stats: TQ3FrontEndStats read FStats;
    /// <summary>The number of the nodes that the last marking left visible</summary>
    function VisibleNodeCount: Integer;
  end;

implementation

uses
  DelphiDoom.Collision.Q3.Math, DelphiDoom.Geometry.Vec3, DelphiDoom.Decl.Q3Shader.Types;

function ToVec(const AValue: TGeoVec3): TQ3Vec3;
begin
  Result[0] := AValue.X;
  Result[1] := AValue.Y;
  Result[2] := AValue.Z;
end;

constructor TQ3WorldSurfaceAdder.Create(const AWorld: IQ3RenderWorld; const AShaders: IQ3ShaderTable;
  const ASettings: TQ3RenderSettings);
begin
  inherited Create;
  if not Assigned(AWorld) then
    raise EArgumentNilException.Create('AWorld');
  if not Assigned(AShaders) then
    raise EArgumentNilException.Create('AShaders');
  FWorld := AWorld;
  FShaders := AShaders;
  FSettings := ASettings;
  ResolveWorld;
end;

procedure TQ3WorldSurfaceAdder.ResolveWorld;
var
  LBsp: IBspFile;
  LBspPlanes: TArray<TBspPlane>;
  LFogs: TArray<TQ3WorldFog>;
  LNames: TArray<AnsiString>;
  LIndex, LAxis, LLightmap: Integer;
  LName: AnsiString;
  LTree: TBspRenderTree;
begin
  LBsp := FWorld.GetBsp;
  LTree := FWorld.GetTree;
  FNodes := LTree.Nodes;
  FVisibility := FWorld.GetVisibility;
  FSurfaces := FWorld.GetSurfaces;
  FGrids := FWorld.GetGrids;
  FFaces := FWorld.GetFaces;
  FTriangles := FWorld.GetTriangleSurfaces;
  FLeafSurfaces := LBsp.LeafSurfaces;
  SetLength(FNodeMins, Length(FNodes));
  SetLength(FNodeMaxs, Length(FNodes));
  SetLength(FVisFrame, Length(FNodes));
  for LIndex := 0 to High(FNodes) do
  begin
    FNodeMins[LIndex] := ToVec(FNodes[LIndex].Mins);
    FNodeMaxs[LIndex] := ToVec(FNodes[LIndex].Maxs);
  end;
  LBspPlanes := LBsp.Planes;
  SetLength(FPlanes, Length(LBspPlanes));
  for LIndex := 0 to High(LBspPlanes) do
  begin
    for LAxis := 0 to 2 do
      FPlanes[LIndex].Normal[LAxis] := LBspPlanes[LIndex].Normal[LAxis];
    FPlanes[LIndex].Dist := LBspPlanes[LIndex].Dist;
  end;
  // the shaders in the order of RE_LoadWorldMap: the fogs (LIGHTMAP_NONE), then the surfaces
  FShaders.SetLightmapCount(FWorld.GetLightmapCount);
  LFogs := FWorld.GetFogs;
  for LIndex := 1 to High(LFogs) do
    FShaders.FindShader(LFogs[LIndex].ShaderName, LIGHTMAP_NONE);
  LNames := FWorld.ShaderNames;
  SetLength(FSurfaceShader, Length(FSurfaces));
  SetLength(FSurfaceViewCount, Length(FSurfaces));
  for LIndex := 0 to High(FSurfaces) do
  begin
    FSurfaceShader[LIndex] := 0;
    if FSurfaces[LIndex].Kind in [skBad] then
      Continue;
    if (FSurfaces[LIndex].ShaderNum < 0) or (FSurfaces[LIndex].ShaderNum >= Length(LNames)) then
      Continue;
    LName := LNames[FSurfaces[LIndex].ShaderNum];
    LLightmap := FSurfaces[LIndex].LightmapNum;
    // r_vertexLight and r_fullbright change the lightmap number of every shader
    if FSettings.VertexLight then
      LLightmap := LIGHTMAP_BY_VERTEX;
    if FSettings.FullBright then
      LLightmap := LIGHTMAP_WHITEIMAGE;
    // a shader that had errors is the default shader (entry 0), and so is a face that has too many points
    if FSurfaces[LIndex].UsesDefaultShader or FSettings.SingleShader then
      FSurfaceShader[LIndex] := 0
    else
      FSurfaceShader[LIndex] := FShaders.FindShader(LName, LLightmap);
  end;
  FViewCluster := -1;
end;

function TQ3WorldSurfaceAdder.SurfaceShader(ASurface: Integer): Integer;
begin
  Result := FSurfaceShader[ASurface];
end;

procedure TQ3WorldSurfaceAdder.BeginView(const AViewOrigin, APvsOrigin: TQ3Vec3; const ARefDef: TQ3RefDef;
  const ACuller: TQ3ViewCuller; const AList: TQ3DrawList; const ADlights: TArray<TQ3DynamicLight>;
  ADlightCount, AViewCount: Integer; AAreaMaskModified: Boolean);
begin
  FAreaMaskModified := AAreaMaskModified;
  FViewOrigin := AViewOrigin;
  FPvsOrigin := APvsOrigin;
  FRefDef := ARefDef;
  FCuller := ACuller;
  FList := AList;
  FDlights := ADlights;
  FDlightCount := ADlightCount;
  FViewCount := AViewCount;
end;

function TQ3WorldSurfaceAdder.PointInLeaf(const APoint: TQ3Vec3): Integer;
var
  LDistance: Single;
  LPlane: Integer;
begin
  // R_PointInLeaf: down the tree, the front child when the point is strictly in front of the plane
  Result := 0;
  while FNodes[Result].IsNode do
  begin
    LPlane := FNodes[Result].PlaneNum;
    LDistance := TQ3Math.Dot(APoint, FPlanes[LPlane].Normal);
    LDistance := LDistance - FPlanes[LPlane].Dist;
    if LDistance > 0 then
      Result := FNodes[Result].Children[0]
    else
      Result := FNodes[Result].Children[1];
  end;
end;

procedure TQ3WorldSurfaceAdder.MarkLeaves;
var
  LLeaf, LCluster, LIndex, LParent: Integer;
  LRow: TBytes;
  LRowStart: Integer;
begin
  // r_lockpvs lets the designers walk around to see the extent of the PVS
  if FSettings.LockPvs then
    Exit;
  LLeaf := PointInLeaf(FPvsOrigin);
  LCluster := FNodes[LLeaf].Cluster;
  // the same cluster and no door that opened: what is marked is still right (the first call marks: the flag of
  // r_showcluster is modified when the cvar is made)
  if FMarked and (FViewCluster = LCluster) and not FAreaMaskModified then
    Exit;
  Inc(FVisCount);
  FViewCluster := LCluster;
  FMarked := True;
  if FSettings.NoVis or (FViewCluster = -1) then
  begin
    // every node that is not solid: all of them (a decision node has contents -1 and a leaf 0)
    for LIndex := 0 to High(FNodes) do
      FVisFrame[LIndex] := FVisCount;
    Exit;
  end;
  // R_ClusterPVS: the novis row (all ones) for a world without visibility lump and for a cluster out of the table
  if (Length(FVisibility.Vis) = 0) or (FViewCluster < 0) or (FViewCluster >= FVisibility.NumClusters) then
  begin
    LRow := FVisibility.Novis;
    LRowStart := 0;
  end
  else
  begin
    LRow := FVisibility.Vis;
    LRowStart := FViewCluster * FVisibility.ClusterBytes;
  end;
  for LIndex := 0 to High(FNodes) do
  begin
    // the decision nodes are in this loop too, with the cluster and the area 0 that nothing sets for them
    LCluster := FNodes[LIndex].Cluster;
    if (LCluster < 0) or (LCluster >= FVisibility.NumClusters) then
      Continue;
    // the general PVS
    if (LRowStart + (LCluster shr 3) >= Length(LRow)) or
      ((LRow[LRowStart + (LCluster shr 3)] and (1 shl (LCluster and 7))) = 0) then
      Continue;
    // the connection of the areas (a door)
    if (FRefDef.AreaMask[FNodes[LIndex].Area shr 3] and (1 shl (FNodes[LIndex].Area and 7))) <> 0 then
      Continue;
    LParent := LIndex;
    while LParent >= 0 do
    begin
      if FVisFrame[LParent] = FVisCount then
        Break;
      FVisFrame[LParent] := FVisCount;
      LParent := FNodes[LParent].Parent;
    end;
  end;
end;

function TQ3WorldSurfaceAdder.VisibleNodeCount: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to High(FVisFrame) do
    if FVisFrame[LIndex] = FVisCount then
      Inc(Result);
end;

function TQ3WorldSurfaceAdder.CullGrid(ASurface: Integer): Boolean;
var
  LGrid: IPatchGrid;
  LOrigin, LMins, LMaxs: TQ3Vec3;
  LSphereCull: Integer;
begin
  if FSettings.NoCurves then
    Exit(True);
  LGrid := FGrids[ASurface];
  LOrigin[0] := LGrid.LocalOrigin.X;
  LOrigin[1] := LGrid.LocalOrigin.Y;
  LOrigin[2] := LGrid.LocalOrigin.Z;
  if FCurrentIsWorld then
    LSphereCull := FCuller.CullPointAndRadius(LOrigin, LGrid.MeshRadius)
  else
    LSphereCull := FCuller.CullLocalPointAndRadius(LOrigin, LGrid.MeshRadius);
  // the trivial reject
  if LSphereCull = CULL_OUT then
    Exit(True);
  // the box, when the sphere crosses the frustum
  if LSphereCull = CULL_CLIP then
  begin
    LMins[0] := LGrid.BoundsMin.X;
    LMins[1] := LGrid.BoundsMin.Y;
    LMins[2] := LGrid.BoundsMin.Z;
    LMaxs[0] := LGrid.BoundsMax.X;
    LMaxs[1] := LGrid.BoundsMax.Y;
    LMaxs[2] := LGrid.BoundsMax.Z;
    if FCuller.CullLocalBox(LMins, LMaxs) = CULL_OUT then
      Exit(True);
  end;
  Result := False;
end;

function TQ3WorldSurfaceAdder.CullSurface(ASurface: Integer): Boolean;
var
  LFace: TBspFaceSurface;
  LTriangle: TBspTriangleSurface;
  LNormal, LMins, LMaxs: TQ3Vec3;
  LDistance, LLimit: Single;
  LCullType: TQ3CullType;
  LAxis: Integer;
begin
  if FSettings.NoCull then
    Exit(False);
  case FSurfaces[ASurface].Kind of
    skGrid:
      Exit(CullGrid(ASurface));
    skTriangles:
      begin
        LTriangle := FTriangles[FSurfaces[ASurface].DataIndex];
        for LAxis := 0 to 2 do
        begin
          LMins[LAxis] := LTriangle.Mins[LAxis];
          LMaxs[LAxis] := LTriangle.Maxs[LAxis];
        end;
        Exit(FCuller.CullLocalBox(LMins, LMaxs) = CULL_OUT);
      end;
    skFace:
      ;
  else
    Exit(False);
  end;
  LCullType := FShaders.GetEntry(FSurfaceShader[ASurface]).Data.CullType;
  if LCullType = ctTwoSided then
    Exit(False);
  if not FSettings.FacePlaneCull then
    Exit(False);
  LFace := FFaces[FSurfaces[ASurface].DataIndex];
  for LAxis := 0 to 2 do
    LNormal[LAxis] := LFace.PlaneNormal[LAxis];
  LDistance := TQ3Math.Dot(FOrientationViewOrigin, LNormal);
  // not exactly on the plane: the roundings of the BSP and of the card could leave pixel gaps
  if LCullType = ctFrontSided then
  begin
    LLimit := LFace.PlaneDist - 8;
    if LDistance < LLimit then
      Exit(True);
  end
  else
  begin
    LLimit := LFace.PlaneDist + 8;
    if LDistance > LLimit then
      Exit(True);
  end;
  Result := False;
end;

function TQ3WorldSurfaceAdder.DlightSurface(ASurface, ADlightBits: Integer): Integer;
var
  LIndex, LAxis: Integer;
  LFace: TBspFaceSurface;
  LNormal: TQ3Vec3;
  LDistance: Single;
  LGrid: IPatchGrid;
  LLow, LHigh, LOrigin: array[0..2] of Single;
  LRadius: Single;
begin
  Result := ADlightBits;
  case FSurfaces[ASurface].Kind of
    skFace:
      begin
        LFace := FFaces[FSurfaces[ASurface].DataIndex];
        for LAxis := 0 to 2 do
          LNormal[LAxis] := LFace.PlaneNormal[LAxis];
        for LIndex := 0 to FDlightCount - 1 do
        begin
          if (Result and (1 shl LIndex)) = 0 then
            Continue;
          LDistance := TQ3Math.Dot(FDlights[LIndex].Origin, LNormal);
          LDistance := LDistance - LFace.PlaneDist;
          // the dlight does not reach the plane
          if (LDistance < -FDlights[LIndex].Radius) or (LDistance > FDlights[LIndex].Radius) then
            Result := Result and not (1 shl LIndex);
        end;
      end;
    skGrid:
      begin
        LGrid := FGrids[ASurface];
        LLow[0] := LGrid.BoundsMin.X;
        LLow[1] := LGrid.BoundsMin.Y;
        LLow[2] := LGrid.BoundsMin.Z;
        LHigh[0] := LGrid.BoundsMax.X;
        LHigh[1] := LGrid.BoundsMax.Y;
        LHigh[2] := LGrid.BoundsMax.Z;
        for LIndex := 0 to FDlightCount - 1 do
        begin
          if (Result and (1 shl LIndex)) = 0 then
            Continue;
          LRadius := FDlights[LIndex].Radius;
          for LAxis := 0 to 2 do
            LOrigin[LAxis] := FDlights[LIndex].Origin[LAxis];
          // the dlight does not reach the bounds
          if (LOrigin[0] - LRadius > LHigh[0]) or (LOrigin[0] + LRadius < LLow[0]) or
            (LOrigin[1] - LRadius > LHigh[1]) or (LOrigin[1] + LRadius < LLow[1]) or
            (LOrigin[2] - LRadius > LHigh[2]) or (LOrigin[2] + LRadius < LLow[2]) then
            Result := Result and not (1 shl LIndex);
        end;
      end;
    skTriangles:
      ;
  else
    Result := 0;
  end;
end;

procedure TQ3WorldSurfaceAdder.AddWorldSurface(ASurface, ADlightBits: Integer);
var
  LReference: TQ3SurfaceRef;
begin
  // already in this view
  if FSurfaceViewCount[ASurface] = FViewCount then
    Exit;
  FSurfaceViewCount[ASurface] := FViewCount;
  if FSurfaces[ASurface].Kind = skBad then
    Exit;
  // try to cull before dlighting or adding
  if CullSurface(ASurface) then
    Exit;
  LReference := Default(TQ3SurfaceRef);
  if ADlightBits <> 0 then
  begin
    ADlightBits := DlightSurface(ASurface, ADlightBits);
    // R_DlightSurface keeps the mask in the surface: the dlight pass of the backend reads it
    LReference.DlightMask := ADlightBits;
    if ADlightBits <> 0 then
      ADlightBits := 1;
  end;
  LReference.Kind := FSurfaces[ASurface].Kind;
  LReference.Index := ASurface;
  LReference.Sub := 0;
  FList.Add(LReference, FSurfaceShader[ASurface], FSurfaces[ASurface].FogIndex, ADlightBits);
  Inc(FStats.WorldSurfaces);
end;

procedure TQ3WorldSurfaceAdder.RecursiveWorldNode(ANode, APlaneBits, ADlightBits: Integer);
var
  LResult, LPlane, LIndex, LCount, LMark: Integer;
  LNewDlights: array[0..1] of Integer;
  LDistance, LNegative: Single;
begin
  while True do
  begin
    // a node that the PVS did not mark: nothing inside can be visible
    if FVisFrame[ANode] <> FVisCount then
      Exit;
    // the bounds outside the frustum: nothing inside can be visible
    if not FSettings.NoCull then
      for LPlane := 0 to 3 do
        if (APlaneBits and (1 shl LPlane)) <> 0 then
        begin
          LResult := TQ3Math.BoxOnPlaneSide(FNodeMins[ANode], FNodeMaxs[ANode], FCuller.FrustumPlane(LPlane));
          if LResult = 2 then
            Exit;
          // in front: all the descendants are in front too
          if LResult = 1 then
            APlaneBits := APlaneBits and not (1 shl LPlane);
        end;
    if not FNodes[ANode].IsNode then
      Break;
    // a decision node: both sides, the front first; the dlights that are needed on each side
    LNewDlights[0] := 0;
    LNewDlights[1] := 0;
    if ADlightBits <> 0 then
      for LIndex := 0 to FDlightCount - 1 do
        if (ADlightBits and (1 shl LIndex)) <> 0 then
        begin
          LPlane := FNodes[ANode].PlaneNum;
          LDistance := TQ3Math.Dot(FDlights[LIndex].Origin, FPlanes[LPlane].Normal);
          LDistance := LDistance - FPlanes[LPlane].Dist;
          LNegative := -FDlights[LIndex].Radius;
          if LDistance > LNegative then
            LNewDlights[0] := LNewDlights[0] or (1 shl LIndex);
          if LDistance < FDlights[LIndex].Radius then
            LNewDlights[1] := LNewDlights[1] or (1 shl LIndex);
        end;
    RecursiveWorldNode(FNodes[ANode].Children[0], APlaneBits, LNewDlights[0]);
    // the other side: the tail of the recursion
    ADlightBits := LNewDlights[1];
    ANode := FNodes[ANode].Children[1];
  end;
  // a leaf: its bounds go in the bounds of what is visible, then its surfaces
  Inc(FStats.Leafs);
  for LIndex := 0 to 2 do
  begin
    if FNodeMins[ANode][LIndex] < FVisBounds[0][LIndex] then
      FVisBounds[0][LIndex] := FNodeMins[ANode][LIndex];
    if FNodeMaxs[ANode][LIndex] > FVisBounds[1][LIndex] then
      FVisBounds[1][LIndex] := FNodeMaxs[ANode][LIndex];
  end;
  LCount := FNodes[ANode].NumMarkSurfaces;
  for LMark := 0 to LCount - 1 do
  begin
    LIndex := FNodes[ANode].FirstMarkSurface + LMark;
    if (LIndex < 0) or (LIndex >= Length(FLeafSurfaces)) then
      Continue;
    LResult := FLeafSurfaces[LIndex];
    if (LResult < 0) or (LResult >= Length(FSurfaces)) then
      Continue;
    // the surface may have been added already if it spans several leafs
    AddWorldSurface(LResult, ADlightBits);
  end;
end;

procedure TQ3WorldSurfaceAdder.AddWorldSurfaces(var AMins, AMaxs: TQ3Vec3);
var
  LAxis, LBits: Integer;
begin
  if not FSettings.DrawWorld then
    Exit;
  if (FRefDef.RdFlags and RDF_NOWORLDMODEL) <> 0 then
    Exit;
  FCurrentIsWorld := True;
  FOrientationViewOrigin := FViewOrigin;
  FList.SetEntity(Q3_ENTITYNUM_WORLD);
  if Length(FNodes) = 0 then
    Exit;
  // the leafs that the PVS and the areas let through
  MarkLeaves;
  for LAxis := 0 to 2 do
  begin
    FVisBounds[0][LAxis] := 99999;
    FVisBounds[1][LAxis] := -99999;
  end;
  if FDlightCount > Q3_MAX_DLIGHTS then
    FDlightCount := Q3_MAX_DLIGHTS;
  // (1 << n) - 1; for 32 lights the C shifts by 32, which the x86 does as a shift by 0 (the bits are then 0)
  if FDlightCount >= 32 then
    LBits := 0
  else
    LBits := (1 shl FDlightCount) - 1;
  RecursiveWorldNode(0, 15, LBits);
  AMins := FVisBounds[0];
  AMaxs := FVisBounds[1];
end;

procedure TQ3WorldSurfaceAdder.AddBrushModelSurfaces(ABrushIndex: Integer; const AOrientationViewOrigin: TQ3Vec3);
var
  LModels: TArray<TBspModel>;
  LMins, LMaxs: TQ3Vec3;
  LAxis, LIndex: Integer;
  LNeed: Integer;
  LMask: Integer;
  LLocal: TQ3Vec3;
  LDelta: TQ3Vec3;
  LRadius: Single;
  LOrientation: TQ3ViewOrientation;
  LOutside: Boolean;
begin
  LModels := FWorld.GetBsp.Models;
  if (ABrushIndex < 0) or (ABrushIndex >= Length(LModels)) then
    Exit;
  for LAxis := 0 to 2 do
  begin
    LMins[LAxis] := LModels[ABrushIndex].Mins[LAxis];
    LMaxs[LAxis] := LModels[ABrushIndex].Maxs[LAxis];
  end;
  if FCuller.CullLocalBox(LMins, LMaxs) = CULL_OUT then
    Exit;
  FCurrentIsWorld := False;
  FOrientationViewOrigin := AOrientationViewOrigin;
  // R_DlightBmodel: the lights in the space of the model; the ones near enough to its bounds are needed
  LOrientation := FCuller.Orientation;
  LMask := 0;
  for LIndex := 0 to FDlightCount - 1 do
  begin
    for LAxis := 0 to 2 do
      LDelta[LAxis] := FDlights[LIndex].Origin[LAxis] - LOrientation.Origin[LAxis];
    for LAxis := 0 to 2 do
      LLocal[LAxis] := TQ3Math.Dot(LDelta, LOrientation.Axis[LAxis]);
    LRadius := FDlights[LIndex].Radius;
    LOutside := False;
    for LAxis := 0 to 2 do
      if (LLocal[LAxis] - LMaxs[LAxis] > LRadius) or (LMins[LAxis] - LLocal[LAxis] > LRadius) then
      begin
        LOutside := True;
        Break;
      end;
    if not LOutside then
      LMask := LMask or (1 shl LIndex);
  end;
  LNeed := Ord(LMask <> 0);
  // the surfaces of the model, with the entity number that the list has now
  for LIndex := 0 to LModels[ABrushIndex].NumSurfaces - 1 do
  begin
    LAxis := LModels[ABrushIndex].FirstSurface + LIndex;
    if (LAxis >= 0) and (LAxis < Length(FSurfaces)) then
      AddWorldSurface(LAxis, LNeed);
  end;
end;

end.
