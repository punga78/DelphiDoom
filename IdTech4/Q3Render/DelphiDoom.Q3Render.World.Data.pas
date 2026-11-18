{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R0) - a loaded world   }
{                                                                              }
{  The world_t of renderer\tr_local.h as data, with R_PointInLeaf and          }
{  R_inPVS of tr_main.c and tr_world.c. Based on the Quake III Arena GPL       }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.World.Data;

interface

uses
  System.SysUtils, DelphiDoom.MapFile.Bsp.Types, DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.MapFile.Bsp.RenderTypes,
  DelphiDoom.Q3Render.Types, DelphiDoom.Q3Render.Intf;

type
  /// <summary>
  ///   What RE_LoadWorldMap builds, without the OpenGL part: the tree, the visibility rows, the lightmaps as RGBA
  ///   bytes, the light grid and the surfaces by type. Built by TQ3WorldLoader, read only afterwards
  /// </summary>
  TQ3RenderWorld = class(TInterfacedObject, IQ3RenderWorld)
  strict private
    FBsp: IBspFile;
    FTree: TBspRenderTree;
    FVisibility: TBspVisibility;
    FLightGrid: TBspLightGrid;
    FLightmaps: TArray<TBytes>;
    FFaces: TArray<TBspFaceSurface>;
    FTriangles: TArray<TBspTriangleSurface>;
    FFlares: TArray<TBspFlareSurface>;
    FPatchCount: Integer;
    FRefused: Integer;
    FFogCount: Integer;
    FShaderNames: TArray<AnsiString>;
    function PointInLeaf(const APoint: TQ3RenderVec3): Integer;
  public
    constructor Create(const ABsp: IBspFile; const ATree: TBspRenderTree; const AVisibility: TBspVisibility;
      const ALightGrid: TBspLightGrid; const ALightmaps: TArray<TBytes>; const AFaces: TArray<TBspFaceSurface>;
      const ATriangles: TArray<TBspTriangleSurface>; const AFlares: TArray<TBspFlareSurface>; APatchCount,
      ARefused, AFogCount: Integer; const AShaderNames: TArray<AnsiString>);
    function GetBsp: IBspFile;
    function GetTree: TBspRenderTree;
    function GetVisibility: TBspVisibility;
    function GetLightGrid: TBspLightGrid;
    function GetLightmaps: TArray<TBytes>;
    function GetFaces: TArray<TBspFaceSurface>;
    function GetTriangleSurfaces: TArray<TBspTriangleSurface>;
    function GetFlares: TArray<TBspFlareSurface>;
    function PatchCount: Integer;
    function SurfaceCount: Integer;
    function RefusedCount: Integer;
    function FogCount: Integer;
    function SubmodelCount: Integer;
    function ShaderNames: TArray<AnsiString>;
    function InPvs(const APoint1, APoint2: TQ3RenderVec3): Boolean;
    function SubmodelBounds(AIndex: Integer; out AMins, AMaxs: TQ3RenderVec3): Boolean;
  end;

implementation

constructor TQ3RenderWorld.Create(const ABsp: IBspFile; const ATree: TBspRenderTree;
  const AVisibility: TBspVisibility; const ALightGrid: TBspLightGrid; const ALightmaps: TArray<TBytes>;
  const AFaces: TArray<TBspFaceSurface>; const ATriangles: TArray<TBspTriangleSurface>;
  const AFlares: TArray<TBspFlareSurface>; APatchCount, ARefused, AFogCount: Integer;
  const AShaderNames: TArray<AnsiString>);
begin
  inherited Create;
  FBsp := ABsp;
  FTree := ATree;
  FVisibility := AVisibility;
  FLightGrid := ALightGrid;
  FLightmaps := ALightmaps;
  FFaces := AFaces;
  FTriangles := ATriangles;
  FFlares := AFlares;
  FPatchCount := APatchCount;
  FRefused := ARefused;
  FFogCount := AFogCount;
  FShaderNames := AShaderNames;
end;

function TQ3RenderWorld.GetBsp: IBspFile;
begin
  Result := FBsp;
end;

function TQ3RenderWorld.GetTree: TBspRenderTree;
begin
  Result := FTree;
end;

function TQ3RenderWorld.GetVisibility: TBspVisibility;
begin
  Result := FVisibility;
end;

function TQ3RenderWorld.GetLightGrid: TBspLightGrid;
begin
  Result := FLightGrid;
end;

function TQ3RenderWorld.GetLightmaps: TArray<TBytes>;
begin
  Result := FLightmaps;
end;

function TQ3RenderWorld.GetFaces: TArray<TBspFaceSurface>;
begin
  Result := FFaces;
end;

function TQ3RenderWorld.GetTriangleSurfaces: TArray<TBspTriangleSurface>;
begin
  Result := FTriangles;
end;

function TQ3RenderWorld.GetFlares: TArray<TBspFlareSurface>;
begin
  Result := FFlares;
end;

function TQ3RenderWorld.PatchCount: Integer;
begin
  Result := FPatchCount;
end;

function TQ3RenderWorld.SurfaceCount: Integer;
begin
  Result := Length(FBsp.Surfaces);
end;

function TQ3RenderWorld.RefusedCount: Integer;
begin
  Result := FRefused;
end;

function TQ3RenderWorld.FogCount: Integer;
begin
  Result := FFogCount;
end;

function TQ3RenderWorld.SubmodelCount: Integer;
begin
  Result := Length(FBsp.Models);
end;

function TQ3RenderWorld.ShaderNames: TArray<AnsiString>;
begin
  Result := FShaderNames;
end;

function TQ3RenderWorld.PointInLeaf(const APoint: TQ3RenderVec3): Integer;
var
  LPlanes: TArray<TBspPlane>;
  LNode: TBspRenderNode;
  LDistance: Single;
begin
  // R_PointInLeaf: down the tree, the front child when the point is strictly in front of the plane
  Result := 0;
  LPlanes := FBsp.Planes;
  if Length(FTree.Nodes) = 0 then
    Exit(-1);
  LNode := FTree.Nodes[Result];
  while LNode.IsNode do
  begin
    LDistance := APoint[0] * LPlanes[LNode.PlaneNum].Normal[0];
    LDistance := LDistance + APoint[1] * LPlanes[LNode.PlaneNum].Normal[1];
    LDistance := LDistance + APoint[2] * LPlanes[LNode.PlaneNum].Normal[2];
    LDistance := LDistance - LPlanes[LNode.PlaneNum].Dist;
    if LDistance > 0 then
      Result := LNode.Children[0]
    else
      Result := LNode.Children[1];
    LNode := FTree.Nodes[Result];
  end;
end;

function TQ3RenderWorld.InPvs(const APoint1, APoint2: TQ3RenderVec3): Boolean;
var
  LCluster1, LCluster2, LRow: Integer;
  LLeaf: Integer;
begin
  LLeaf := PointInLeaf(APoint1);
  if LLeaf < 0 then
    Exit(True);
  LCluster1 := FTree.Nodes[LLeaf].Cluster;
  LLeaf := PointInLeaf(APoint2);
  LCluster2 := FTree.Nodes[LLeaf].Cluster;
  // CM_ClusterPVS: without visibility data the row is all ones (everything is seen); with it, a cluster outside
  // the table gets the row of cluster 0 (cm.visibility itself)
  if (Length(FVisibility.Vis) = 0) or (FVisibility.ClusterBytes <= 0) then
    Exit(True);
  if (LCluster1 < 0) or (LCluster1 >= FVisibility.NumClusters) then
    LRow := 0
  else
    LRow := LCluster1 * FVisibility.ClusterBytes;
  // vis[cluster >> 3] with an arithmetic shift: the cluster -1 of a solid leaf is the byte before the row (the last
  // byte of the row of the cluster before, or memory before the block for the first row: read as zero here), bit 7
  if LCluster2 < 0 then
    LRow := LRow - 1
  else
    LRow := LRow + (LCluster2 shr 3);
  if (LRow < 0) or (LRow >= Length(FVisibility.Vis)) then
    Exit(False);
  Result := (FVisibility.Vis[LRow] and (1 shl (LCluster2 and 7))) <> 0;
end;

function TQ3RenderWorld.SubmodelBounds(AIndex: Integer; out AMins, AMaxs: TQ3RenderVec3): Boolean;
var
  LModels: TArray<TBspModel>;
  LAxis: Integer;
begin
  AMins := Default(TQ3RenderVec3);
  AMaxs := Default(TQ3RenderVec3);
  LModels := FBsp.Models;
  Result := (AIndex >= 0) and (AIndex < Length(LModels));
  if not Result then
    Exit;
  for LAxis := 0 to 2 do
  begin
    AMins[LAxis] := LModels[AIndex].Mins[LAxis];
    AMaxs[LAxis] := LModels[AIndex].Maxs[LAxis];
  end;
end;

end.
