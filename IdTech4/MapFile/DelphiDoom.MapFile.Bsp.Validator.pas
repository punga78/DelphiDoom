{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the BSP of Quake III Arena: references       }
{  between the lumps                                                           }
{                                                                              }
{  Written for this library. The checks of CMod_LoadBrushes, CMod_LoadBrush-   }
{  Sides, ParseTriSurf, ShaderForShaderNum and CM_LoadMap are in it; the       }
{  others are the ones whose absence makes the original read out of its        }
{  arrays. Based on the Quake III Arena GPL Source Code (id Software).         }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.Validator;

{$Q-}
{$R-}

interface

uses
  System.Generics.Collections, DelphiDoom.MapFile.Bsp.Intf;

type
  /// <summary>
  ///   Looks for indexes that point outside their lump: node planes and children, ranges of
  ///   leaves, models, brushes and surfaces, shader numbers, planes of the brush sides, fog
  ///   brushes, vertices and indexes of the surfaces, patch sizes, the clusters of the leaves
  ///   and the size of the visibility rows. It reports every problem it finds.
  /// </summary>
  TBspValidator = class(TInterfacedObject, IBspValidator)
  strict private
    FIssues: TList<string>;
    procedure Report(const AFormat: string; const AArguments: array of const);
    procedure CheckRange(const AWhat: string; const AIndex, AFirst, ACount, ALimit: Integer;
      const ALimitName: string);
    procedure CheckNodes(const AFile: IBspFile);
    procedure CheckLeafs(const AFile: IBspFile);
    procedure CheckModels(const AFile: IBspFile);
    procedure CheckBrushes(const AFile: IBspFile);
    procedure CheckFogs(const AFile: IBspFile);
    procedure CheckSurfaces(const AFile: IBspFile);
    procedure CheckVisibility(const AFile: IBspFile);
  public
    function Validate(const AFile: IBspFile): TArray<string>;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MapFile.Bsp.Types, DelphiDoom.MathCore.Patch.Types;

procedure TBspValidator.Report(const AFormat: string; const AArguments: array of const);
begin
  FIssues.Add(Format(AFormat, AArguments));
end;

procedure TBspValidator.CheckRange(const AWhat: string; const AIndex, AFirst, ACount, ALimit: Integer;
  const ALimitName: string);
begin
  if (AFirst < 0) or (ACount < 0) or (Int64(AFirst) + ACount > ALimit) then
    Report('%s %d: %d entries from %d are outside the %d of %s', [AWhat, AIndex, ACount, AFirst, ALimit,
      ALimitName]);
end;

procedure TBspValidator.CheckNodes(const AFile: IBspFile);
var
  LNodes: TArray<TBspNode>;
  LIndex, LSide, LChild: Integer;
begin
  LNodes := AFile.Nodes;
  for LIndex := 0 to High(LNodes) do
  begin
    if (LNodes[LIndex].PlaneNum < 0) or (LNodes[LIndex].PlaneNum >= Length(AFile.Planes)) then
      Report('node %d: plane %d is outside the %d planes', [LIndex, LNodes[LIndex].PlaneNum,
        Length(AFile.Planes)]);
    for LSide := 0 to 1 do
    begin
      LChild := LNodes[LIndex].Children[LSide];
      if LChild >= 0 then
      begin
        if LChild >= Length(LNodes) then
          Report('node %d: child %d is outside the %d nodes', [LIndex, LChild, Length(LNodes)]);
      end
      else if -(Int64(LChild) + 1) >= Length(AFile.Leafs) then
        Report('node %d: child %d is the leaf %d, outside the %d leafs',
          [LIndex, LChild, -(Int64(LChild) + 1), Length(AFile.Leafs)]);
    end;
  end;
end;

procedure TBspValidator.CheckLeafs(const AFile: IBspFile);
var
  LLeafs: TArray<TBspLeaf>;
  LIndex: Integer;
begin
  LLeafs := AFile.Leafs;
  for LIndex := 0 to High(LLeafs) do
  begin
    CheckRange('leaf', LIndex, LLeafs[LIndex].FirstLeafSurface, LLeafs[LIndex].NumLeafSurfaces,
      Length(AFile.LeafSurfaces), 'leafsurfaces');
    CheckRange('leaf', LIndex, LLeafs[LIndex].FirstLeafBrush, LLeafs[LIndex].NumLeafBrushes,
      Length(AFile.LeafBrushes), 'leafbrushes');
    if AFile.NumClusters > 0 then
      if LLeafs[LIndex].Cluster >= AFile.NumClusters then
        Report('leaf %d: cluster %d is outside the %d clusters', [LIndex, LLeafs[LIndex].Cluster,
          AFile.NumClusters]);
  end;
  for LIndex := 0 to High(AFile.LeafSurfaces) do
    if (AFile.LeafSurfaces[LIndex] < 0) or (AFile.LeafSurfaces[LIndex] >= Length(AFile.Surfaces)) then
      Report('leafsurface %d: surface %d is outside the %d surfaces', [LIndex, AFile.LeafSurfaces[LIndex],
        Length(AFile.Surfaces)]);
  for LIndex := 0 to High(AFile.LeafBrushes) do
    if (AFile.LeafBrushes[LIndex] < 0) or (AFile.LeafBrushes[LIndex] >= Length(AFile.Brushes)) then
      Report('leafbrush %d: brush %d is outside the %d brushes', [LIndex, AFile.LeafBrushes[LIndex],
        Length(AFile.Brushes)]);
end;

procedure TBspValidator.CheckModels(const AFile: IBspFile);
var
  LModels: TArray<TBspModel>;
  LIndex: Integer;
begin
  LModels := AFile.Models;
  for LIndex := 0 to High(LModels) do
  begin
    CheckRange('model', LIndex, LModels[LIndex].FirstSurface, LModels[LIndex].NumSurfaces,
      Length(AFile.Surfaces), 'surfaces');
    CheckRange('model', LIndex, LModels[LIndex].FirstBrush, LModels[LIndex].NumBrushes,
      Length(AFile.Brushes), 'brushes');
  end;
end;

procedure TBspValidator.CheckBrushes(const AFile: IBspFile);
var
  LBrushes: TArray<TBspBrush>;
  LSides: TArray<TBspBrushSide>;
  LIndex: Integer;
begin
  LBrushes := AFile.Brushes;
  for LIndex := 0 to High(LBrushes) do
  begin
    CheckRange('brush', LIndex, LBrushes[LIndex].FirstSide, LBrushes[LIndex].NumSides,
      Length(AFile.BrushSides), 'brushsides');
    // CMod_LoadBrushes
    if (LBrushes[LIndex].ShaderNum < 0) or (LBrushes[LIndex].ShaderNum >= Length(AFile.Shaders)) then
      Report('brush %d: bad shaderNum: %d', [LIndex, LBrushes[LIndex].ShaderNum]);
  end;
  LSides := AFile.BrushSides;
  for LIndex := 0 to High(LSides) do
  begin
    if (LSides[LIndex].PlaneNum < 0) or (LSides[LIndex].PlaneNum >= Length(AFile.Planes)) then
      Report('brushside %d: plane %d is outside the %d planes', [LIndex, LSides[LIndex].PlaneNum,
        Length(AFile.Planes)]);
    // CMod_LoadBrushSides
    if (LSides[LIndex].ShaderNum < 0) or (LSides[LIndex].ShaderNum >= Length(AFile.Shaders)) then
      Report('brushside %d: bad shaderNum: %d', [LIndex, LSides[LIndex].ShaderNum]);
  end;
end;

procedure TBspValidator.CheckFogs(const AFile: IBspFile);
var
  LFogs: TArray<TBspFog>;
  LIndex: Integer;
begin
  LFogs := AFile.Fogs;
  for LIndex := 0 to High(LFogs) do
  begin
    if (LFogs[LIndex].BrushNum < 0) or (LFogs[LIndex].BrushNum >= Length(AFile.Brushes)) then
      Report('fog %d: brush %d is outside the %d brushes', [LIndex, LFogs[LIndex].BrushNum,
        Length(AFile.Brushes)])
    else if LFogs[LIndex].VisibleSide <> -1 then
      if (LFogs[LIndex].VisibleSide < 0) or
         (LFogs[LIndex].VisibleSide >= AFile.Brushes[LFogs[LIndex].BrushNum].NumSides) then
        Report('fog %d: visible side %d is not a side of brush %d', [LIndex, LFogs[LIndex].VisibleSide,
          LFogs[LIndex].BrushNum]);
  end;
end;

procedure TBspValidator.CheckSurfaces(const AFile: IBspFile);
var
  LSurfaces: TArray<TBspSurface>;
  LSurface: TBspSurface;
  LIndex, LTriangle: Integer;
begin
  LSurfaces := AFile.Surfaces;
  for LIndex := 0 to High(LSurfaces) do
  begin
    LSurface := LSurfaces[LIndex];
    // ShaderForShaderNum
    if (LSurface.ShaderNum < 0) or (LSurface.ShaderNum >= Length(AFile.Shaders)) then
      Report('surface %d: bad shaderNum: %d', [LIndex, LSurface.ShaderNum]);
    if (LSurface.FogNum < -1) or (LSurface.FogNum >= Length(AFile.Fogs)) then
      Report('surface %d: fog %d is outside the %d fogs', [LIndex, LSurface.FogNum, Length(AFile.Fogs)]);
    CheckRange('surface', LIndex, LSurface.FirstVert, LSurface.NumVerts, Length(AFile.DrawVerts), 'drawverts');
    case LSurface.SurfaceType of
      MST_PATCH:
        begin
          if (LSurface.PatchWidth < MIN_PATCH_SIZE) or (LSurface.PatchWidth > MAX_PATCH_SIZE) or
             (LSurface.PatchHeight < MIN_PATCH_SIZE) or (LSurface.PatchHeight > MAX_PATCH_SIZE) or
             not Odd(LSurface.PatchWidth) or not Odd(LSurface.PatchHeight) then
            Report('surface %d: patch size %dx%d is not odd numbers from %d to %d', [LIndex, LSurface.PatchWidth,
              LSurface.PatchHeight, MIN_PATCH_SIZE, MAX_PATCH_SIZE])
          else if Int64(LSurface.PatchWidth) * LSurface.PatchHeight > LSurface.NumVerts then
            Report('surface %d: patch %dx%d needs more than the %d vertices of the surface', [LIndex,
              LSurface.PatchWidth, LSurface.PatchHeight, LSurface.NumVerts]);
        end;
      MST_PLANAR, MST_TRIANGLE_SOUP:
        begin
          CheckRange('surface', LIndex, LSurface.FirstIndex, LSurface.NumIndexes, Length(AFile.DrawIndexes),
            'drawindexes');
          if LSurface.NumIndexes mod 3 <> 0 then
            Report('surface %d: %d indexes are not whole triangles', [LIndex, LSurface.NumIndexes]);
          if (LSurface.FirstIndex >= 0) and (LSurface.NumIndexes >= 0) and
             (Int64(LSurface.FirstIndex) + LSurface.NumIndexes <= Length(AFile.DrawIndexes)) then
            for LTriangle := 0 to LSurface.NumIndexes - 1 do
              // ParseTriSurf: Bad index in triangle surface
              if (AFile.DrawIndexes[LSurface.FirstIndex + LTriangle] < 0) or
                 (AFile.DrawIndexes[LSurface.FirstIndex + LTriangle] >= LSurface.NumVerts) then
              begin
                Report('surface %d: bad index %d in triangle surface', [LIndex,
                  AFile.DrawIndexes[LSurface.FirstIndex + LTriangle]]);
                Break;
              end;
        end;
      MST_FLARE:
        ;
    else
      Report('surface %d: bad surfaceType %d', [LIndex, LSurface.SurfaceType]);
    end;
  end;
end;

procedure TBspValidator.CheckVisibility(const AFile: IBspFile);
begin
  if AFile.Lumps[LUMP_VISIBILITY].FileLen = 0 then
    Exit;
  if (AFile.NumClusters < 0) or (AFile.ClusterBytes < 0) or
     (Int64(AFile.NumClusters) * AFile.ClusterBytes > Length(AFile.Visibility)) then
    Report('visibility: %d clusters of %d bytes do not fit in the %d bytes of the lump',
      [AFile.NumClusters, AFile.ClusterBytes, Length(AFile.Visibility)]);
end;

function TBspValidator.Validate(const AFile: IBspFile): TArray<string>;
begin
  FIssues := TList<string>.Create;
  try
    CheckNodes(AFile);
    CheckLeafs(AFile);
    CheckModels(AFile);
    CheckBrushes(AFile);
    CheckFogs(AFile);
    CheckSurfaces(AFile);
    CheckVisibility(AFile);
    Result := FIssues.ToArray;
  finally
    FreeAndNil(FIssues);
  end;
end;

end.
