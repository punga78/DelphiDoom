{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R1) - the front end    }
{                                                                              }
{  RE_RenderScene, R_RenderView, R_GenerateDrawSurfs, R_AddEntitySurfaces,     }
{  R_AddPolygonSurfaces, R_AddMD3Surfaces (with R_CullModel and                }
{  R_ComputeFogNum) and R_SortDrawSurfs of renderer\tr_scene.c, tr_main.c and  }
{  tr_mesh.c: from the scene that the module built to the sorted list of       }
{  drawSurfs of a view. Based on the Quake III Arena GPL Source Code (id       }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Scene.FrontEnd;

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Models.Static.Md3.Intf,
  DelphiDoom.Q3Render.Scene.Types, DelphiDoom.Q3Render.Intf, DelphiDoom.Q3Render.Scene.Buffers,
  DelphiDoom.Q3Render.Draw.List, DelphiDoom.Q3Render.View.Culler, DelphiDoom.Q3Render.World.Surfaces;

type
  /// <summary>Turns a handle of the module (the host numbers) into the index of the renderer's own table</summary>
  TQ3HandleMapper = reference to function(AHostHandle: Integer): Integer;

  /// <summary>What a view left: its parameters and where its sorted drawSurfs are in the list</summary>
  TQ3ViewResult = record
    View: TQ3FrontViewParms;
    FirstDrawSurf: Integer;
    NumDrawSurfs: Integer;
  end;

  /// <summary>
  ///   The first half of the renderer: the buffers of the scene, and for RenderScene the view, the surfaces of the
  ///   world that it sees, the polys, the entities and the sort. The result is the sorted list of drawSurfs of the
  ///   view (TQ3DrawList) that the backend draws
  /// </summary>
  /// <remarks>
  ///   Not ported: the views through a portal or a mirror (R_MirrorViewBySurface: the surfaces whose shader sorts as
  ///   SS_PORTAL are counted in Stats.PortalSurfaces and stay in the list), the levels of detail of the md3 (lod 0),
  ///   the skins (a model with a custom skin takes the default shader for its surfaces: the C does so for a skin
  ///   that has no entry for the surface), the lighting of the entities and MD4 models
  /// </remarks>
  TQ3FrontEnd = class
  strict private
    FShaders: IQ3ShaderTable;
    FModels: IQ3ModelRegistry;
    FShaderMapper: TQ3HandleMapper;
    FModelMapper: TQ3HandleMapper;
    FSettings: TQ3RenderSettings;
    FBuffers: TQ3SceneBuffers;
    FList: TQ3DrawList;
    FCuller: TQ3ViewCuller;
    FWorld: IQ3RenderWorld;
    FAdder: TQ3WorldSurfaceAdder;
    FRefDef: TQ3RefDef;
    FViewCount: Integer;
    FFirstSceneDrawSurf: Integer;
    FVidHeight: Integer;
    FAreaMask: array[0..Q3_MAX_MAP_AREA_BYTES - 1] of Byte;
    FStats: TQ3FrontEndStats;
    FLastResult: TQ3ViewResult;
    FEntities: TArray<TQ3RefEntity>;
    FPolys: TArray<TQ3ScenePoly>;
    FDlights: TArray<TQ3DynamicLight>;
    FVisMins: TQ3Vec3;
    FVisMaxs: TQ3Vec3;
    FAreaMaskModified: Boolean;
    procedure AddPolygonSurfaces;
    procedure AddEntitySurfaces(const AView: TQ3FrontViewParms);
    procedure AddMd3Surfaces(AEntityNumber: Integer; var AEntity: TQ3RefEntity; const AModel: IMd3Model;
      const AView: TQ3FrontViewParms);
    function CullModel(const AEntity: TQ3RefEntity; const AModel: IMd3Model): Integer;
    function SpriteFogNumber(const AEntity: TQ3RefEntity): Integer;
    function ModelFogNumber(const AEntity: TQ3RefEntity; const AModel: IMd3Model): Integer;
    procedure GenerateDrawSurfs(var AView: TQ3FrontViewParms);
    procedure SortDrawSurfs(AFirst, ACount: Integer);
    procedure RenderView(var AParms: TQ3FrontViewParms);
  public
    constructor Create(const AShaders: IQ3ShaderTable; const AModels: IQ3ModelRegistry;
      const AShaderMapper, AModelMapper: TQ3HandleMapper; const ASettings: TQ3RenderSettings);
    destructor Destroy; override;
    /// <summary>RE_LoadWorldMap: the world the views draw (nil forgets it)</summary>
    procedure SetWorld(const AWorld: IQ3RenderWorld);
    /// <summary>RE_ClearScene, RE_AddRefEntityToScene, RE_AddPolyToScene, RE_AddDynamicLightToScene</summary>
    procedure ClearScene;
    procedure AddRefEntity(const AEntity: TQ3RefEntity);
    procedure AddPolys(AHostShader, ANumVerts: Integer; const AVerts: TArray<TQ3PolyVert>; ANumPolys: Integer);
    procedure AddLight(const AOrigin: TQ3Vec3; AIntensity, ARed, AGreen, ABlue: Single; AAdditive: Boolean);
    /// <summary>
    ///   RE_RenderScene: a view of the scene, its surfaces added to the list and sorted. Without a world and without
    ///   RDF_NOWORLDMODEL the C ends with ERR_DROP: here an EQ3RenderException
    /// </summary>
    procedure RenderScene(const ARefDef: TQ3RefDef);
    /// <summary>The frame is over: R_ToggleSmpFrame</summary>
    procedure EndFrame;
    property Buffers: TQ3SceneBuffers read FBuffers;
    property DrawList: TQ3DrawList read FList;
    property Stats: TQ3FrontEndStats read FStats;
    /// <summary>The view of the last RenderScene and where its sorted drawSurfs are in the list</summary>
    property LastResult: TQ3ViewResult read FLastResult;
    /// <summary>The height of the window (glConfig.vidHeight): the viewport of a view is counted from the bottom</summary>
    property VidHeight: Integer read FVidHeight write FVidHeight;
    property Settings: TQ3RenderSettings read FSettings;
  end;

implementation

uses
  System.Math, DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Models.Static.Md3.Types, DelphiDoom.Q3Render.Types,
  DelphiDoom.Q3Render.View.Setup;

resourcestring
  SQ3RenderNoWorld = 'R_RenderScene: NULL worldmodel';
  SQ3RenderBadEntityType = 'R_AddEntitySurfaces: Bad reType %d';
  SQ3RenderBadShaderSort = 'Shader ''%s'' with sort == SS_BAD';

constructor TQ3FrontEnd.Create(const AShaders: IQ3ShaderTable; const AModels: IQ3ModelRegistry;
  const AShaderMapper, AModelMapper: TQ3HandleMapper; const ASettings: TQ3RenderSettings);
begin
  inherited Create;
  if not Assigned(AShaders) then
    raise EArgumentNilException.Create('AShaders');
  if not Assigned(AModels) then
    raise EArgumentNilException.Create('AModels');
  FShaders := AShaders;
  FModels := AModels;
  FShaderMapper := AShaderMapper;
  FModelMapper := AModelMapper;
  FSettings := ASettings;
  FBuffers := TQ3SceneBuffers.Create(ASettings.MaxPolys, ASettings.MaxPolyVerts);
  FList := TQ3DrawList.Create(AShaders);
  FCuller := TQ3ViewCuller.Create(ASettings.NoCull);
  FVidHeight := 480;
end;

destructor TQ3FrontEnd.Destroy;
begin
  FAdder.Free;
  FCuller.Free;
  FList.Free;
  FBuffers.Free;
  inherited Destroy;
end;

procedure TQ3FrontEnd.SetWorld(const AWorld: IQ3RenderWorld);
begin
  FreeAndNil(FAdder);
  FWorld := AWorld;
  if Assigned(AWorld) then
  begin
    FAdder := TQ3WorldSurfaceAdder.Create(AWorld, FShaders, FSettings);
    FBuffers.SetFogs(AWorld.GetFogs);
  end
  else
    FBuffers.SetFogs(nil);
end;

procedure TQ3FrontEnd.ClearScene;
begin
  FBuffers.ClearScene;
end;

procedure TQ3FrontEnd.AddRefEntity(const AEntity: TQ3RefEntity);
begin
  FBuffers.AddEntity(AEntity);
end;

procedure TQ3FrontEnd.AddPolys(AHostShader, ANumVerts: Integer; const AVerts: TArray<TQ3PolyVert>;
  ANumPolys: Integer);
begin
  // the null shader: the C warns and adds nothing
  if AHostShader = 0 then
    Exit;
  FBuffers.AddPolys(FShaderMapper(AHostShader), ANumVerts, AVerts, ANumPolys);
end;

procedure TQ3FrontEnd.AddLight(const AOrigin: TQ3Vec3; AIntensity, ARed, AGreen, ABlue: Single;
  AAdditive: Boolean);
begin
  FBuffers.AddLight(AOrigin, AIntensity, ARed, AGreen, ABlue, AAdditive);
end;

procedure TQ3FrontEnd.EndFrame;
begin
  FBuffers.ResetFrame;
  FList.Clear;
  FFirstSceneDrawSurf := 0;
end;

function TQ3FrontEnd.SpriteFogNumber(const AEntity: TQ3RefEntity): Integer;
var
  LFogs: TArray<TQ3WorldFog>;
  LFog, LAxis: Integer;
  LOutside: Boolean;
begin
  Result := 0;
  if (FRefDef.RdFlags and RDF_NOWORLDMODEL) <> 0 then
    Exit;
  if not Assigned(FWorld) then
    Exit;
  LFogs := FWorld.GetFogs;
  for LFog := 1 to High(LFogs) do
  begin
    LOutside := False;
    for LAxis := 0 to 2 do
      if (AEntity.Origin[LAxis] - AEntity.Radius >= LFogs[LFog].Maxs[LAxis]) or
        (AEntity.Origin[LAxis] + AEntity.Radius <= LFogs[LFog].Mins[LAxis]) then
      begin
        LOutside := True;
        Break;
      end;
    if not LOutside then
      Exit(LFog);
  end;
end;

function TQ3FrontEnd.ModelFogNumber(const AEntity: TQ3RefEntity; const AModel: IMd3Model): Integer;
var
  LFogs: TArray<TQ3WorldFog>;
  LFrame: TMd3Frame;
  LOrigin: TQ3Vec3;
  LFog, LAxis: Integer;
  LOutside: Boolean;
begin
  Result := 0;
  if (FRefDef.RdFlags and RDF_NOWORLDMODEL) <> 0 then
    Exit;
  if not Assigned(FWorld) then
    Exit;
  LFogs := FWorld.GetFogs;
  LFrame := AModel.Frames[AEntity.Frame];
  LOrigin[0] := AEntity.Origin[0] + LFrame.LocalOrigin.X;
  LOrigin[1] := AEntity.Origin[1] + LFrame.LocalOrigin.Y;
  LOrigin[2] := AEntity.Origin[2] + LFrame.LocalOrigin.Z;
  for LFog := 1 to High(LFogs) do
  begin
    LOutside := False;
    for LAxis := 0 to 2 do
      if (LOrigin[LAxis] - LFrame.Radius >= LFogs[LFog].Maxs[LAxis]) or
        (LOrigin[LAxis] + LFrame.Radius <= LFogs[LFog].Mins[LAxis]) then
      begin
        LOutside := True;
        Break;
      end;
    if not LOutside then
      Exit(LFog);
  end;
end;

function TQ3FrontEnd.CullModel(const AEntity: TQ3RefEntity; const AModel: IMd3Model): Integer;
var
  LNewFrame, LOldFrame: TMd3Frame;
  LOrigin: TQ3Vec3;
  LMins, LMaxs: TQ3Vec3;
  LSphere, LSphereOld: Integer;

  function LocalOrigin(const AFrame: TMd3Frame): TQ3Vec3;
  begin
    Result[0] := AFrame.LocalOrigin.X;
    Result[1] := AFrame.LocalOrigin.Y;
    Result[2] := AFrame.LocalOrigin.Z;
  end;

begin
  LNewFrame := AModel.Frames[AEntity.Frame];
  LOldFrame := AModel.Frames[AEntity.OldFrame];
  // the bounding sphere is tested only if the entity is not scaled up
  if AEntity.NonNormalizedAxes = 0 then
  begin
    if AEntity.Frame = AEntity.OldFrame then
    begin
      LOrigin := LocalOrigin(LNewFrame);
      case FCuller.CullLocalPointAndRadius(LOrigin, LNewFrame.Radius) of
        CULL_OUT:
          Exit(CULL_OUT);
        CULL_IN:
          Exit(CULL_IN);
      end;
    end
    else
    begin
      LOrigin := LocalOrigin(LNewFrame);
      LSphere := FCuller.CullLocalPointAndRadius(LOrigin, LNewFrame.Radius);
      LOrigin := LocalOrigin(LOldFrame);
      LSphereOld := FCuller.CullLocalPointAndRadius(LOrigin, LOldFrame.Radius);
      if LSphere = LSphereOld then
      begin
        if LSphere = CULL_OUT then
          Exit(CULL_OUT);
        if LSphere = CULL_IN then
          Exit(CULL_IN);
      end;
    end;
  end;
  // a box in the current coordinate system: the union of the two frames
  LMins[0] := Min(LOldFrame.BoundsMin.X, LNewFrame.BoundsMin.X);
  LMins[1] := Min(LOldFrame.BoundsMin.Y, LNewFrame.BoundsMin.Y);
  LMins[2] := Min(LOldFrame.BoundsMin.Z, LNewFrame.BoundsMin.Z);
  LMaxs[0] := Max(LOldFrame.BoundsMax.X, LNewFrame.BoundsMax.X);
  LMaxs[1] := Max(LOldFrame.BoundsMax.Y, LNewFrame.BoundsMax.Y);
  LMaxs[2] := Max(LOldFrame.BoundsMax.Z, LNewFrame.BoundsMax.Z);
  Result := FCuller.CullLocalBox(LMins, LMaxs);
end;

procedure TQ3FrontEnd.AddMd3Surfaces(AEntityNumber: Integer; var AEntity: TQ3RefEntity; const AModel: IMd3Model;
  const AView: TQ3FrontViewParms);
var
  LPersonal: Boolean;
  LSurface, LCull, LFog, LShader, LIndex: Integer;
  LNames: TArray<AnsiString>;
  LReference: TQ3SurfaceRef;
begin
  // third person objects are not added if the view is not through a portal
  LPersonal := ((AEntity.RenderFx and RF_THIRD_PERSON) <> 0) and not AView.IsPortal;
  if (AEntity.RenderFx and RF_WRAP_FRAMES) <> 0 then
  begin
    AEntity.Frame := AEntity.Frame mod AModel.NumFrames;
    AEntity.OldFrame := AEntity.OldFrame mod AModel.NumFrames;
  end;
  // the frames are validated so that nothing after this has to check them
  if (AEntity.Frame >= AModel.NumFrames) or (AEntity.Frame < 0) or (AEntity.OldFrame >= AModel.NumFrames) or
    (AEntity.OldFrame < 0) then
  begin
    AEntity.Frame := 0;
    AEntity.OldFrame := 0;
  end;
  // the whole model is culled if the box of both frames is outside the frustum
  LCull := CullModel(AEntity, AModel);
  if LCull = CULL_OUT then
    Exit;
  LFog := ModelFogNumber(AEntity, AModel);
  LReference.Kind := skMd3;
  LReference.Index := AEntityNumber;
  for LSurface := 0 to AModel.NumSurfaces - 1 do
  begin
    LReference.Sub := LSurface;
    LNames := AModel.Surfaces[LSurface].Shaders;
    if AEntity.CustomShader <> 0 then
      LShader := FShaderMapper(AEntity.CustomShader)
    else if AEntity.CustomSkin > 0 then
      // the skins are not kept: the surface has no entry, which is the default shader
      LShader := 0
    else if Length(LNames) <= 0 then
      LShader := 0
    else
    begin
      LIndex := AEntity.SkinNum mod Length(LNames);
      if LIndex < 0 then
        LIndex := 0;
      LShader := FShaders.FindShader(LNames[LIndex], LIGHTMAP_NONE);
    end;
    // stencil shadows and projection shadows: another surface with the shadow shader
    if (not LPersonal) and (FSettings.Shadows = 2) and (LFog = 0) and
      ((AEntity.RenderFx and (RF_NOSHADOW or RF_DEPTHHACK)) = 0) and
      (FShaders.GetEntry(LShader).Data.Sort = SS_OPAQUE) then
      FList.Add(LReference, 1, 0, 0);
    if (FSettings.Shadows = 3) and (LFog = 0) and ((AEntity.RenderFx and 256) <> 0) and
      (FShaders.GetEntry(LShader).Data.Sort = SS_OPAQUE) then
      FList.Add(LReference, FShaders.FindShader('projectionShadow', LIGHTMAP_NONE), 0, 0);
    if not LPersonal then
      FList.Add(LReference, LShader, LFog, 0);
  end;
end;

procedure TQ3FrontEnd.AddPolygonSurfaces;
var
  LIndex: Integer;
  LReference: TQ3SurfaceRef;
begin
  FList.SetEntity(Q3_ENTITYNUM_WORLD);
  LReference.Kind := skPoly;
  LReference.Sub := 0;
  for LIndex := 0 to High(FPolys) do
  begin
    LReference.Index := LIndex;
    FList.Add(LReference, FPolys[LIndex].HShader, FPolys[LIndex].FogIndex, 0);
  end;
end;

procedure TQ3FrontEnd.AddEntitySurfaces(const AView: TQ3FrontViewParms);
var
  LNumber, LBrush, LHandle: Integer;
  LEntity: TQ3RefEntity;
  LOrientation: TQ3ViewOrientation;
  LModel: IMd3Model;
  LReference: TQ3SurfaceRef;
  LNotDrawnInView: Boolean;
begin
  if not FSettings.DrawEntities then
    Exit;
  for LNumber := 0 to High(FEntities) do
  begin
    LEntity := FEntities[LNumber];
    // the entity number is shifted into the sort key of the surfaces that follow
    FList.SetEntity(LNumber);
    // the weapon is not in the mirrors: the true body is drawn there
    if ((LEntity.RenderFx and RF_FIRST_PERSON) <> 0) and AView.IsPortal then
      Continue;
    LNotDrawnInView := ((LEntity.RenderFx and RF_THIRD_PERSON) <> 0) and not AView.IsPortal;
    LReference.Index := LNumber;
    LReference.Sub := 0;
    case LEntity.ReType of
      RT_PORTALSURFACE:
        ;
      RT_SPRITE, RT_BEAM, RT_LIGHTNING, RT_RAIL_CORE, RT_RAIL_RINGS:
        begin
          // sprites and beams are not culled; blood and talk balloons of the player are not in the main view
          if LNotDrawnInView then
            Continue;
          LReference.Kind := skEntity;
          FList.Add(LReference, FShaderMapper(LEntity.CustomShader), SpriteFogNumber(LEntity), 0);
        end;
      RT_MODEL:
        begin
          // the orientation of the entity for the culling of the model
          TQ3ViewSetup.RotateForEntity(LEntity, AView, LOrientation);
          FCuller.SetOrientation(LOrientation);
          LHandle := FModelMapper(LEntity.HModel);
          LBrush := FModels.BrushIndex(LHandle);
          LModel := FModels.GetModel(LHandle);
          if LBrush >= 0 then
          begin
            if Assigned(FAdder) then
              FAdder.AddBrushModelSurfaces(LBrush, LOrientation.ViewOrigin);
          end
          else if Assigned(LModel) then
            AddMd3Surfaces(LNumber, LEntity, LModel, AView)
          else if not LNotDrawnInView then
          begin
            // MOD_BAD: the null model axis, with the default shader
            LReference.Kind := skEntity;
            FList.Add(LReference, 0, 0, 0);
          end;
        end;
    else
      raise EQ3RenderException.CreateFmt(SQ3RenderBadEntityType, [LEntity.ReType]);
    end;
  end;
end;

procedure TQ3FrontEnd.GenerateDrawSurfs(var AView: TQ3FrontViewParms);
var
  LDelta: Integer;
begin
  LDelta := FList.Count;
  if Assigned(FAdder) then
  begin
    FAdder.BeginView(AView.Orientation.Origin, AView.PvsOrigin, FRefDef, FCuller, FList, FDlights,
      Length(FDlights), FViewCount, FAreaMaskModified);
    FAdder.AddWorldSurfaces(FVisMins, FVisMaxs);
    AView.VisBounds[0] := FVisMins;
    AView.VisBounds[1] := FVisMaxs;
  end;
  Inc(FStats.WorldSurfaces, FList.Count - LDelta);
  LDelta := FList.Count;
  AddPolygonSurfaces;
  Inc(FStats.PolySurfaces, FList.Count - LDelta);
  // the projection with the smallest far plane now that the world is bounded: the entities use it for their
  // level of detail
  TQ3ViewSetup.SetupProjection(AView, FRefDef, FSettings.ZNear);
  LDelta := FList.Count;
  AddEntitySurfaces(AView);
  Inc(FStats.EntitySurfaces, FList.Count - LDelta);
end;

procedure TQ3FrontEnd.SortDrawSurfs(AFirst, ACount: Integer);
var
  LIndex: Integer;
  LEntity, LSortedShader, LFog, LDlight: Integer;
  LEntry: TQ3ShaderEntry;
begin
  // a view can have no surfaces at all
  if ACount < 1 then
    Exit;
  // when MAX_DRAWSURFS overflowed the surfaces wrapped around: the first ones are gone, not the last
  if ACount > Q3_MAX_DRAWSURFS then
    ACount := Q3_MAX_DRAWSURFS;
  if AFirst + ACount > Q3_MAX_DRAWSURFS then
    ACount := Q3_MAX_DRAWSURFS - AFirst;
  FList.SortRange(AFirst, ACount);
  // pass through drawing (portals and mirrors) comes first in the order: counted, not rendered
  for LIndex := AFirst to AFirst + ACount - 1 do
  begin
    TQ3DrawList.Decompose(FList.Item(LIndex).Sort, LEntity, LSortedShader, LFog, LDlight);
    LEntry := FShaders.GetSortedEntry(LSortedShader);
    if LEntry.Data.Sort > SS_PORTAL then
      Break;
    if LEntry.Data.Sort = SS_BAD then
      raise EQ3RenderException.CreateFmt(SQ3RenderBadShaderSort, [string(LEntry.Name)]);
    Inc(FStats.PortalSurfaces);
  end;
end;

procedure TQ3FrontEnd.RenderView(var AParms: TQ3FrontViewParms);
var
  LFirst: Integer;
  LWorld: TQ3ViewOrientation;
begin
  if (AParms.ViewportWidth <= 0) or (AParms.ViewportHeight <= 0) then
    Exit;
  Inc(FViewCount);
  LFirst := FList.Count;
  Inc(FViewCount);
  // viewParms.world: the modelview matrix of the viewer
  TQ3ViewSetup.RotateForViewer(AParms, LWorld);
  TQ3ViewSetup.SetupFrustum(AParms);
  FCuller.SetView(AParms, LWorld);
  GenerateDrawSurfs(AParms);
  SortDrawSurfs(LFirst, FList.Count - LFirst);
  FLastResult.View := AParms;
  FLastResult.FirstDrawSurf := LFirst;
  FLastResult.NumDrawSurfs := FList.Count - LFirst;
end;

procedure TQ3FrontEnd.RenderScene(const ARefDef: TQ3RefDef);
var
  LParms: TQ3FrontViewParms;
  LDifference: Byte;
  LIndex: Integer;
begin
  if (not Assigned(FWorld)) and ((ARefDef.RdFlags and RDF_NOWORLDMODEL) = 0) then
    raise EQ3RenderException.Create(SQ3RenderNoWorld);
  FRefDef := ARefDef;
  // a door that opened or shut forces the leafs to be marked again
  FAreaMaskModified := False;
  if (FRefDef.RdFlags and RDF_NOWORLDMODEL) = 0 then
  begin
    LDifference := 0;
    for LIndex := 0 to Q3_MAX_MAP_AREA_BYTES - 1 do
    begin
      LDifference := LDifference or (FAreaMask[LIndex] xor ARefDef.AreaMask[LIndex]);
      FAreaMask[LIndex] := ARefDef.AreaMask[LIndex];
    end;
    FAreaMaskModified := LDifference <> 0;
  end;
  FList.Count := FFirstSceneDrawSurf;
  FEntities := FBuffers.SceneEntities;
  FDlights := FBuffers.SceneDlights;
  FPolys := FBuffers.ScenePolys;
  // dynamic lighting off, or vertex lighting: no dlight at all
  if (not FSettings.DynamicLight) or FSettings.VertexLight then
    FDlights := nil;
  Inc(FStats.Scenes);
  // the view: the window (the refdef counts from the top, GL from the bottom), the field of view, the viewer
  LParms := Default(TQ3FrontViewParms);
  LParms.ViewportX := FRefDef.X;
  LParms.ViewportY := FVidHeight - (FRefDef.Y + FRefDef.Height);
  LParms.ViewportWidth := FRefDef.Width;
  LParms.ViewportHeight := FRefDef.Height;
  LParms.IsPortal := False;
  LParms.FovX := FRefDef.FovX;
  LParms.FovY := FRefDef.FovY;
  LParms.Orientation.Origin := FRefDef.ViewOrigin;
  for LIndex := 0 to 2 do
    LParms.Orientation.Axis[LIndex] := FRefDef.ViewAxis[LIndex];
  LParms.PvsOrigin := FRefDef.ViewOrigin;
  FLastResult := Default(TQ3ViewResult);
  RenderView(LParms);
  // the next scene of the frame goes after this one
  FFirstSceneDrawSurf := FList.Count;
  FBuffers.CloseScene;
  FStats.DrawSurfs := FList.Count;
end;

end.
