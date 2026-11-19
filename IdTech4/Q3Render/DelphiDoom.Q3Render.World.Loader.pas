{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R0) - RE_LoadWorldMap  }
{                                                                              }
{  The order of RE_LoadWorldMap and R_LoadSurfaces of renderer\tr_bsp.c; every }
{  lump is loaded by the classes of IdTech4\MapFile (which have the parity     }
{  with the C). Based on the Quake III Arena GPL Source Code (id Software).    }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.World.Loader;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.Q3Render.Types,
  DelphiDoom.Q3Render.Intf;

type
  /// <summary>
  ///   Loads a BSP into an IQ3RenderWorld. The overbright shift is r_mapOverBrightBits - overbrightBits (1 for the
  ///   defaults of the game). A surface that a loader refuses (a vertex or an index past its lump) is counted in
  ///   RefusedCount and left out: the C reads past the lump or ends the program. A BSP that is not valid at all
  ///   (identifier, version, lump sizes) is an EQ3RenderException with the message of the reader
  /// </summary>
  TQ3WorldLoader = class(TInterfacedObject, IQ3WorldLoader)
  strict private
    FFiles: IQ3RenderFiles;
    FReader: IBspReader;
    FTreeLoader: IBspTreeLoader;
    FVisibilityLoader: IBspVisibilityLoader;
    FLightmapLoader: IBspLightmapLoader;
    FLightGridLoader: IBspLightGridLoader;
    FFaceLoader: IBspFaceLoader;
    FTriangleLoader: IBspTriangleLoader;
    FFlareLoader: IBspFlareLoader;
    FPatchLoader: IBspPatchLoader;
    FShift: Integer;
    FLog: ILog;
  public
    constructor Create(const AFiles: IQ3RenderFiles; const AReader: IBspReader; const ATreeLoader: IBspTreeLoader;
      const AVisibilityLoader: IBspVisibilityLoader; const ALightmapLoader: IBspLightmapLoader;
      const ALightGridLoader: IBspLightGridLoader; const AFaceLoader: IBspFaceLoader;
      const ATriangleLoader: IBspTriangleLoader; const AFlareLoader: IBspFlareLoader;
      const APatchLoader: IBspPatchLoader; AShift: Integer; const ALog: ILog = nil);
    function Load(const AName: AnsiString): IQ3RenderWorld;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.MapFile.Bsp.Types,
  DelphiDoom.MapFile.Bsp.RenderTypes, DelphiDoom.MapFile.Bsp.GridSizeReader, DelphiDoom.MathCore.Patch.Intf,
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Q3Render.Scene.Types, DelphiDoom.Q3Render.World.Data;

function EmptyFog: TQ3WorldFog;
var
  LAxis: Integer;
begin
  Result := Default(TQ3WorldFog);
  // a box with the minimum above the maximum: no point is inside it
  for LAxis := 0 to 2 do
  begin
    Result.Mins[LAxis] := 1.0E9;
    Result.Maxs[LAxis] := -1.0E9;
  end;
end;

// R_LoadFogs: the bounds from the six axial sides at the start of the brush (the minimum of an axis is minus the
// distance of the plane of the first side)
function FogOf(const ABsp: IBspFile; AFogIndex: Integer): TQ3WorldFog;
var
  LSides: TArray<TBspBrushSide>;
  LPlanes: TArray<TBspPlane>;
  LFirstSide, LAxis: Integer;
  LFog: TBspFog;

  function SideDistance(ASide: Integer): Single;
  begin
    Result := LPlanes[LSides[LFirstSide + ASide].PlaneNum].Dist;
  end;

begin
  Result := EmptyFog;
  LFog := ABsp.Fogs[AFogIndex];
  if (LFog.BrushNum < 0) or (LFog.BrushNum >= Length(ABsp.Brushes)) then
    Exit;
  LSides := ABsp.BrushSides;
  LPlanes := ABsp.Planes;
  LFirstSide := ABsp.Brushes[LFog.BrushNum].FirstSide;
  if (LFirstSide < 0) or (LFirstSide + 5 >= Length(LSides)) then
    Exit;
  for LAxis := 0 to 5 do
    if (LSides[LFirstSide + LAxis].PlaneNum < 0) or (LSides[LFirstSide + LAxis].PlaneNum >= Length(LPlanes)) then
      Exit;
  Result.Mins[0] := -SideDistance(0);
  Result.Maxs[0] := SideDistance(1);
  Result.Mins[1] := -SideDistance(2);
  Result.Maxs[1] := SideDistance(3);
  Result.Mins[2] := -SideDistance(4);
  Result.Maxs[2] := SideDistance(5);
  Result.ShaderName := ABsp.FogShaderName(AFogIndex);
end;

constructor TQ3WorldLoader.Create(const AFiles: IQ3RenderFiles; const AReader: IBspReader;
  const ATreeLoader: IBspTreeLoader; const AVisibilityLoader: IBspVisibilityLoader;
  const ALightmapLoader: IBspLightmapLoader; const ALightGridLoader: IBspLightGridLoader;
  const AFaceLoader: IBspFaceLoader; const ATriangleLoader: IBspTriangleLoader; const AFlareLoader: IBspFlareLoader;
  const APatchLoader: IBspPatchLoader; AShift: Integer; const ALog: ILog);
begin
  inherited Create;
  FFiles := AFiles;
  FReader := AReader;
  FTreeLoader := ATreeLoader;
  FVisibilityLoader := AVisibilityLoader;
  FLightmapLoader := ALightmapLoader;
  FLightGridLoader := ALightGridLoader;
  FFaceLoader := AFaceLoader;
  FTriangleLoader := ATriangleLoader;
  FFlareLoader := AFlareLoader;
  FPatchLoader := APatchLoader;
  FShift := AShift;
  FLog := ALog;
end;

function TQ3WorldLoader.Load(const AName: AnsiString): IQ3RenderWorld;
var
  LData: TBytes;
  LBsp: IBspFile;
  LTree: TBspRenderTree;
  LVisibility: TBspVisibility;
  LLightGrid: TBspLightGrid;
  LLightmaps: TArray<TBytes>;
  LFaces: TList<TBspFaceSurface>;
  LTriangles: TList<TBspTriangleSurface>;
  LFlares: TList<TBspFlareSurface>;
  LGrids: TArray<IPatchGrid>;
  LSurfaces: TArray<TBspSurface>;
  LNames: TArray<AnsiString>;
  LSurface: TBspSurface;
  LFace: TBspFaceSurface;
  LTable: TArray<TQ3WorldSurface>;
  LFogTable: TArray<TQ3WorldFog>;
  LWorldBounds: TGeoBounds;
  LGridSize: TGeoVec3;
  LIndex, LShaderCount, LPatches, LRefused, LFogs: Integer;
begin
  Result := nil;
  if not FFiles.ReadFile(AName, LData) then
    Exit;
  try
    LBsp := FReader.ParseBytes(LData, AName);
    LTree := FTreeLoader.Load(LBsp.Nodes, LBsp.Leafs, Length(LBsp.Planes));
    LVisibility := FVisibilityLoader.LoadFromFile(LBsp, LTree.NumClusters);
    LLightmaps := FLightmapLoader.Load(LBsp.Lightmaps, FShift);
    if Length(LBsp.Models) > 0 then
    begin
      LWorldBounds.Mins.SetValues(LBsp.Models[0].Mins[0], LBsp.Models[0].Mins[1], LBsp.Models[0].Mins[2]);
      LWorldBounds.Maxs.SetValues(LBsp.Models[0].Maxs[0], LBsp.Models[0].Maxs[1], LBsp.Models[0].Maxs[2]);
      LGridSize := TBspGridSizeReader.Read(LBsp.EntityText);
      LLightGrid := FLightGridLoader.Load(LWorldBounds, LGridSize, LBsp.LumpData[LUMP_LIGHTGRID], FShift);
    end
    else
      LLightGrid := Default(TBspLightGrid);
    LGrids := FPatchLoader.LoadGrids(LBsp);
  except
    on E: EBspFileException do
      raise EQ3RenderException.CreateFmt('RE_LoadWorldMap: %s: %s', [string(AName), E.Message]);
  end;
  LSurfaces := LBsp.Surfaces;
  LShaderCount := Length(LBsp.Shaders);
  LFaces := TList<TBspFaceSurface>.Create;
  LTriangles := TList<TBspTriangleSurface>.Create;
  LFlares := TList<TBspFlareSurface>.Create;
  try
    LPatches := 0;
    LRefused := 0;
    SetLength(LTable, Length(LSurfaces));
    for LIndex := 0 to High(LSurfaces) do
    begin
      LSurface := LSurfaces[LIndex];
      LTable[LIndex] := Default(TQ3WorldSurface);
      LTable[LIndex].Kind := skBad;
      LTable[LIndex].ShaderNum := LSurface.ShaderNum;
      LTable[LIndex].FogIndex := LSurface.FogNum + 1;
      LTable[LIndex].LightmapNum := LIGHTMAP_BY_VERTEX;
      try
        case LSurface.SurfaceType of
          MST_PLANAR:
            begin
              LFace := FFaceLoader.Parse(LSurface, LBsp.DrawVerts, LBsp.DrawIndexes, LShaderCount);
              LTable[LIndex].Kind := skFace;
              LTable[LIndex].DataIndex := LFaces.Count;
              LTable[LIndex].LightmapNum := LSurface.LightmapNum;
              LTable[LIndex].UsesDefaultShader := LFace.UsesDefaultShader;
              LFaces.Add(LFace);
            end;
          MST_TRIANGLE_SOUP:
            begin
              LTriangles.Add(FTriangleLoader.Parse(LSurface, LBsp.DrawVerts, LBsp.DrawIndexes, LShaderCount));
              LTable[LIndex].Kind := skTriangles;
              LTable[LIndex].DataIndex := LTriangles.Count - 1;
            end;
          MST_FLARE:
            begin
              LFlares.Add(FFlareLoader.Parse(LSurface, LShaderCount));
              LTable[LIndex].Kind := skFlare;
              LTable[LIndex].DataIndex := LFlares.Count - 1;
            end;
          MST_PATCH:
            begin
              LTable[LIndex].LightmapNum := LSurface.LightmapNum;
              // a patch with SURF_NODRAW has no grid: the surface is a skip surface (it stays for the clipping)
              if (LIndex < Length(LGrids)) and Assigned(LGrids[LIndex]) then
              begin
                Inc(LPatches);
                LTable[LIndex].Kind := skGrid;
                LTable[LIndex].DataIndex := LIndex;
              end
              else
                LTable[LIndex].Kind := skSkip;
            end;
        else
          Inc(LRefused);
        end;
      except
        on E: EBspFileException do
        begin
          Inc(LRefused);
          LTable[LIndex].Kind := skBad;
          if Assigned(FLog) then
            FLog.Warning(Format('R_LoadSurfaces: surface %d: %s', [LIndex, E.Message]));
        end;
      end;
    end;
    // R_LoadFogs: a fog whose brush is not in the lumps is skipped with a warning; the table keeps its place with
    // a box that nothing is inside, so the fog numbers of the surfaces stay right
    LFogs := 0;
    SetLength(LFogTable, Length(LBsp.Fogs) + 1);
    LFogTable[0] := EmptyFog;
    for LIndex := 0 to High(LBsp.Fogs) do
    begin
      LFogTable[LIndex + 1] := FogOf(LBsp, LIndex);
      if (LBsp.Fogs[LIndex].BrushNum >= 0) and (LBsp.Fogs[LIndex].BrushNum < Length(LBsp.Brushes)) then
        Inc(LFogs);
    end;
    SetLength(LNames, LShaderCount);
    for LIndex := 0 to LShaderCount - 1 do
      LNames[LIndex] := LBsp.ShaderName(LIndex);
    Result := TQ3RenderWorld.Create(LBsp, LTree, LVisibility, LLightGrid, LLightmaps, LFaces.ToArray,
      LTriangles.ToArray, LFlares.ToArray, LPatches, LRefused, LFogs, LNames, LTable, LGrids, LFogTable,
      Length(LLightmaps));
  finally
    LFaces.Free;
    LTriangles.Free;
    LFlares.Free;
  end;
end;

end.
