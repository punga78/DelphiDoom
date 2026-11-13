{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  loading from the BSP                                                        }
{                                                                              }
{  Port of the CMod_Load* functions, CM_BoundBrush and CM_LoadMap of cm_load.c }
{  from the Quake III Arena GPL Source Code (id Software), on top of the       }
{  records of Libs\MapFile. Copyright (C) 1999-2005 Id Software, Inc. This     }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.Loader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.MapFile.Bsp.Types, DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.Collision.Q3.Types,
  DelphiDoom.Collision.Q3.Intf, DelphiDoom.Collision.Q3.ClipMap;

type
  /// <summary>
  ///   Fills a clip map from a BSP file that TBspReader has read. The functions follow the
  ///   order of CM_LoadMap. The original does not look at the indexes of the lumps (it reads
  ///   past its arrays on a corrupt file): here a validator is injected and the first problem
  ///   it reports raises EQ3CollisionException before anything is built.
  /// </summary>
  TQ3ClipMapLoader = class
  strict private
    FValidator: IBspValidator;
    FPatchBuilder: IQ3PatchCollideBuilder;
    procedure LoadShaders(const AFile: IBspFile; const AMap: TQ3ClipMap);
    procedure LoadLeafs(const AFile: IBspFile; const AMap: TQ3ClipMap);
    procedure LoadLeafBrushes(const AFile: IBspFile; const AMap: TQ3ClipMap);
    procedure LoadLeafSurfaces(const AFile: IBspFile; const AMap: TQ3ClipMap);
    procedure LoadPlanes(const AFile: IBspFile; const AMap: TQ3ClipMap);
    procedure LoadBrushSides(const AFile: IBspFile; const AMap: TQ3ClipMap);
    procedure LoadBrushes(const AFile: IBspFile; const AMap: TQ3ClipMap);
    procedure LoadSubmodels(const AFile: IBspFile; const AMap: TQ3ClipMap);
    procedure LoadNodes(const AFile: IBspFile; const AMap: TQ3ClipMap);
    procedure LoadEntityString(const AFile: IBspFile; const AMap: TQ3ClipMap);
    procedure LoadVisibility(const AFile: IBspFile; const AMap: TQ3ClipMap);
    procedure LoadPatches(const AFile: IBspFile; const AMap: TQ3ClipMap);
    procedure BoundBrush(const AMap: TQ3ClipMap; const ABrush: Integer);
  public
    /// <param name="AValidator">checks the references between the lumps (nil: no check)</param>
    /// <param name="APatchBuilder">makes the collision geometry of a patch (nil: the patches do not collide)</param>
    constructor Create(const AValidator: IBspValidator; const APatchBuilder: IQ3PatchCollideBuilder);
    /// <summary>CM_LoadMap without the file: the map is ready, with the box hull and the areas flooded</summary>
    function Load(const AFile: IBspFile; const AName: AnsiString): TQ3ClipMap;
  end;

implementation

uses
  DelphiDoom.Collision.Q3.Math, DelphiDoom.Collision.Q3.BoxHull, DelphiDoom.Collision.Q3.AreaFlood;

resourcestring
  SInvalidBsp = 'CM_LoadMap: %s: %s (%d problems)';
  SNoShaders = 'Map with no shaders';
  SNoLeafs = 'Map with no leafs';
  SNoPlanes = 'Map with no planes';
  SNoModels = 'Map with no models';
  SNoNodes = 'Map has no nodes';
  STooManyModels = 'MAX_SUBMODELS exceeded';
  SBadBrushSides = 'CM_BoundBrush: brush %d starts at the side %d: the six axial sides are outside the %d sides';
  SMaxPatchVerts = 'ParseMesh: MAX_PATCH_VERTS';
  SBadPatchVerts = 'CMod_LoadPatches: surface %d has %d vertices from %d, the file has %d';

constructor TQ3ClipMapLoader.Create(const AValidator: IBspValidator; const APatchBuilder: IQ3PatchCollideBuilder);
begin
  inherited Create;
  FValidator := AValidator;
  FPatchBuilder := APatchBuilder;
end;

function TQ3ClipMapLoader.Load(const AFile: IBspFile; const AName: AnsiString): TQ3ClipMap;
var
  LIssues: TArray<string>;
  LFlood: TQ3AreaFlood;
begin
  if Assigned(FValidator) then
  begin
    LIssues := FValidator.Validate(AFile);
    if Length(LIssues) > 0 then
      raise EQ3CollisionException.CreateFmt(SInvalidBsp, [string(AName), LIssues[0], Length(LIssues)]);
  end;

  Result := TQ3ClipMap.Create;
  try
    LoadShaders(AFile, Result);
    LoadLeafs(AFile, Result);
    LoadLeafBrushes(AFile, Result);
    LoadLeafSurfaces(AFile, Result);
    LoadPlanes(AFile, Result);
    LoadBrushSides(AFile, Result);
    LoadBrushes(AFile, Result);
    LoadSubmodels(AFile, Result);
    LoadNodes(AFile, Result);
    LoadEntityString(AFile, Result);
    LoadVisibility(AFile, Result);
    LoadPatches(AFile, Result);

    TQ3BoxHull.Initialize(Result);

    LFlood := TQ3AreaFlood.Create(Result);
    try
      LFlood.FloodConnections;
    finally
      LFlood.Free;
    end;

    Result.Name := AName;
  except
    Result.Free;
    raise;
  end;
end;

procedure TQ3ClipMapLoader.LoadShaders(const AFile: IBspFile; const AMap: TQ3ClipMap);
begin
  AMap.NumShaders := Length(AFile.Shaders);
  if AMap.NumShaders < 1 then
    raise EQ3CollisionException.Create(SNoShaders);
  AMap.Shaders := Copy(AFile.Shaders);
end;

procedure TQ3ClipMapLoader.LoadLeafs(const AFile: IBspFile; const AMap: TQ3ClipMap);
var
  LIn: TArray<TBspLeaf>;
  LIndex: Integer;
begin
  LIn := AFile.Leafs;
  AMap.NumLeafs := Length(LIn);
  if AMap.NumLeafs < 1 then
    raise EQ3CollisionException.Create(SNoLeafs);

  SetLength(AMap.Leafs, AMap.NumLeafs);
  for LIndex := 0 to AMap.NumLeafs - 1 do
  begin
    AMap.Leafs[LIndex].Cluster := LIn[LIndex].Cluster;
    AMap.Leafs[LIndex].Area := LIn[LIndex].Area;
    AMap.Leafs[LIndex].FirstLeafBrush := LIn[LIndex].FirstLeafBrush;
    AMap.Leafs[LIndex].NumLeafBrushes := LIn[LIndex].NumLeafBrushes;
    AMap.Leafs[LIndex].FirstLeafSurface := LIn[LIndex].FirstLeafSurface;
    AMap.Leafs[LIndex].NumLeafSurfaces := LIn[LIndex].NumLeafSurfaces;

    if AMap.Leafs[LIndex].Cluster >= AMap.NumClusters then
      AMap.NumClusters := AMap.Leafs[LIndex].Cluster + 1;
    if AMap.Leafs[LIndex].Area >= AMap.NumAreas then
      AMap.NumAreas := AMap.Leafs[LIndex].Area + 1;
  end;

  SetLength(AMap.Areas, AMap.NumAreas);
  SetLength(AMap.AreaPortals, AMap.NumAreas * AMap.NumAreas);
end;

procedure TQ3ClipMapLoader.LoadLeafBrushes(const AFile: IBspFile; const AMap: TQ3ClipMap);
var
  LIn: TArray<Integer>;
  LModels: TArray<TBspModel>;
  LTotal, LIndex: Integer;
begin
  LIn := AFile.LeafBrushes;
  AMap.NumLeafBrushes := Length(LIn);

  // room for the entry of the box brush, then for the lists of the brush models (the original
  // makes a block of memory for each, and keeps the distance from the first as an index)
  LTotal := AMap.NumLeafBrushes + Q3_BOX_BRUSHES;
  LModels := AFile.Models;
  for LIndex := 1 to High(LModels) do
    Inc(LTotal, LModels[LIndex].NumBrushes);
  SetLength(AMap.LeafBrushes, LTotal);
  for LIndex := 0 to AMap.NumLeafBrushes - 1 do
    AMap.LeafBrushes[LIndex] := LIn[LIndex];
end;

procedure TQ3ClipMapLoader.LoadLeafSurfaces(const AFile: IBspFile; const AMap: TQ3ClipMap);
var
  LIn: TArray<Integer>;
  LModels: TArray<TBspModel>;
  LTotal, LIndex: Integer;
begin
  LIn := AFile.LeafSurfaces;
  AMap.NumLeafSurfaces := Length(LIn);

  LTotal := AMap.NumLeafSurfaces;
  LModels := AFile.Models;
  for LIndex := 1 to High(LModels) do
    Inc(LTotal, LModels[LIndex].NumSurfaces);
  SetLength(AMap.LeafSurfaces, LTotal);
  for LIndex := 0 to AMap.NumLeafSurfaces - 1 do
    AMap.LeafSurfaces[LIndex] := LIn[LIndex];
end;

procedure TQ3ClipMapLoader.LoadPlanes(const AFile: IBspFile; const AMap: TQ3ClipMap);
var
  LIn: TArray<TBspPlane>;
  LIndex, LAxis: Integer;
begin
  LIn := AFile.Planes;
  AMap.NumPlanes := Length(LIn);
  if AMap.NumPlanes < 1 then
    raise EQ3CollisionException.Create(SNoPlanes);

  SetLength(AMap.Planes, AMap.NumPlanes + Q3_BOX_PLANES);
  for LIndex := 0 to AMap.NumPlanes - 1 do
  begin
    for LAxis := 0 to 2 do
      AMap.Planes[LIndex].Normal[LAxis] := LIn[LIndex].Normal[LAxis];
    AMap.Planes[LIndex].Dist := LIn[LIndex].Dist;
    AMap.Planes[LIndex].PlaneType := TQ3Math.PlaneTypeForNormal(AMap.Planes[LIndex].Normal);
    AMap.Planes[LIndex].SignBits := TQ3Math.SignBitsOf(AMap.Planes[LIndex].Normal);
  end;
end;

procedure TQ3ClipMapLoader.LoadBrushSides(const AFile: IBspFile; const AMap: TQ3ClipMap);
var
  LIn: TArray<TBspBrushSide>;
  LIndex: Integer;
begin
  LIn := AFile.BrushSides;
  AMap.NumBrushSides := Length(LIn);
  SetLength(AMap.BrushSides, AMap.NumBrushSides + Q3_BOX_SIDES);
  for LIndex := 0 to AMap.NumBrushSides - 1 do
  begin
    AMap.BrushSides[LIndex].PlaneNum := LIn[LIndex].PlaneNum;
    AMap.BrushSides[LIndex].ShaderNum := LIn[LIndex].ShaderNum;
    AMap.BrushSides[LIndex].SurfaceFlags := AMap.Shaders[LIn[LIndex].ShaderNum].SurfaceFlags;
  end;
end;

procedure TQ3ClipMapLoader.BoundBrush(const AMap: TQ3ClipMap; const ABrush: Integer);
var
  LFirst, LAxis: Integer;
begin
  LFirst := AMap.Brushes[ABrush].FirstSide;
  // the original reads the six sides after the first whatever the brush has: a brush with
  // fewer sides takes the bounds from the sides of the next brushes
  if (LFirst < 0) or (LFirst + 5 >= AMap.NumBrushSides) then
    raise EQ3CollisionException.CreateFmt(SBadBrushSides, [ABrush, LFirst, AMap.NumBrushSides]);
  for LAxis := 0 to 2 do
  begin
    AMap.Brushes[ABrush].Bounds[0][LAxis] := -AMap.Planes[AMap.BrushSides[LFirst + LAxis * 2].PlaneNum].Dist;
    AMap.Brushes[ABrush].Bounds[1][LAxis] := AMap.Planes[AMap.BrushSides[LFirst + LAxis * 2 + 1].PlaneNum].Dist;
  end;
end;

procedure TQ3ClipMapLoader.LoadBrushes(const AFile: IBspFile; const AMap: TQ3ClipMap);
var
  LIn: TArray<TBspBrush>;
  LIndex: Integer;
begin
  LIn := AFile.Brushes;
  AMap.NumBrushes := Length(LIn);
  SetLength(AMap.Brushes, AMap.NumBrushes + Q3_BOX_BRUSHES);
  for LIndex := 0 to AMap.NumBrushes - 1 do
  begin
    AMap.Brushes[LIndex].FirstSide := LIn[LIndex].FirstSide;
    AMap.Brushes[LIndex].NumSides := LIn[LIndex].NumSides;
    AMap.Brushes[LIndex].ShaderNum := LIn[LIndex].ShaderNum;
    AMap.Brushes[LIndex].Contents := AMap.Shaders[LIn[LIndex].ShaderNum].ContentFlags;
    BoundBrush(AMap, LIndex);
  end;
end;

procedure TQ3ClipMapLoader.LoadSubmodels(const AFile: IBspFile; const AMap: TQ3ClipMap);
var
  LIn: TArray<TBspModel>;
  LIndex, LAxis, LJ, LNextBrush, LNextSurface: Integer;
begin
  LIn := AFile.Models;
  AMap.NumSubModels := Length(LIn);
  if AMap.NumSubModels < 1 then
    raise EQ3CollisionException.Create(SNoModels);
  SetLength(AMap.Models, AMap.NumSubModels);
  if AMap.NumSubModels > Q3_MAX_SUBMODELS then
    raise EQ3CollisionException.Create(STooManyModels);

  LNextBrush := AMap.NumLeafBrushes + Q3_BOX_BRUSHES;
  LNextSurface := AMap.NumLeafSurfaces;
  for LIndex := 0 to AMap.NumSubModels - 1 do
  begin
    // spread the mins / maxs by a pixel
    for LAxis := 0 to 2 do
    begin
      AMap.Models[LIndex].Mins[LAxis] := LIn[LIndex].Mins[LAxis] - 1;
      AMap.Models[LIndex].Maxs[LAxis] := LIn[LIndex].Maxs[LAxis] + 1;
    end;

    if LIndex = 0 then
      Continue; // world model does not need other info

    // make a "leaf" just to hold the model's brushes and surfaces
    AMap.Models[LIndex].Leaf.NumLeafBrushes := LIn[LIndex].NumBrushes;
    AMap.Models[LIndex].Leaf.FirstLeafBrush := LNextBrush;
    for LJ := 0 to LIn[LIndex].NumBrushes - 1 do
      AMap.LeafBrushes[LNextBrush + LJ] := LIn[LIndex].FirstBrush + LJ;
    Inc(LNextBrush, LIn[LIndex].NumBrushes);

    AMap.Models[LIndex].Leaf.NumLeafSurfaces := LIn[LIndex].NumSurfaces;
    AMap.Models[LIndex].Leaf.FirstLeafSurface := LNextSurface;
    for LJ := 0 to LIn[LIndex].NumSurfaces - 1 do
      AMap.LeafSurfaces[LNextSurface + LJ] := LIn[LIndex].FirstSurface + LJ;
    Inc(LNextSurface, LIn[LIndex].NumSurfaces);
  end;
end;

procedure TQ3ClipMapLoader.LoadNodes(const AFile: IBspFile; const AMap: TQ3ClipMap);
var
  LIn: TArray<TBspNode>;
  LIndex: Integer;
begin
  LIn := AFile.Nodes;
  AMap.NumNodes := Length(LIn);
  if AMap.NumNodes < 1 then
    raise EQ3CollisionException.Create(SNoNodes);
  SetLength(AMap.Nodes, AMap.NumNodes);
  for LIndex := 0 to AMap.NumNodes - 1 do
  begin
    AMap.Nodes[LIndex].PlaneNum := LIn[LIndex].PlaneNum;
    AMap.Nodes[LIndex].Children[0] := LIn[LIndex].Children[0];
    AMap.Nodes[LIndex].Children[1] := LIn[LIndex].Children[1];
  end;
end;

procedure TQ3ClipMapLoader.LoadEntityString(const AFile: IBspFile; const AMap: TQ3ClipMap);
begin
  AMap.NumEntityChars := AFile.Lumps[LUMP_ENTITIES].FileLen;
  // the engine uses it as a C string: up to the first NUL
  AMap.EntityString := AFile.EntityText;
end;

procedure TQ3ClipMapLoader.LoadVisibility(const AFile: IBspFile; const AMap: TQ3ClipMap);
var
  LIndex: Integer;
begin
  if AFile.Lumps[LUMP_VISIBILITY].FileLen = 0 then
  begin
    // as the original: the number of bytes is the number of clusters rounded to 32
    AMap.ClusterBytes := (AMap.NumClusters + 31) and not 31;
    SetLength(AMap.Visibility, AMap.ClusterBytes);
    for LIndex := 0 to AMap.ClusterBytes - 1 do
      AMap.Visibility[LIndex] := 255;
    Exit;
  end;

  AMap.Vised := True;
  AMap.Visibility := Copy(AFile.Visibility);
  AMap.NumClusters := AFile.NumClusters;
  AMap.ClusterBytes := AFile.ClusterBytes;
end;

procedure TQ3ClipMapLoader.LoadPatches(const AFile: IBspFile; const AMap: TQ3ClipMap);
var
  LSurfaces: TArray<TBspSurface>;
  LVerts: TArray<TBspDrawVert>;
  LIndex, LJ, LCount, LAxis: Integer;
begin
  LSurfaces := AFile.Surfaces;
  LVerts := AFile.DrawVerts;
  AMap.NumSurfaces := Length(LSurfaces);
  SetLength(AMap.Patches, AMap.NumSurfaces);
  SetLength(AMap.PatchCollides, AMap.NumSurfaces);

  // scan through all the surfaces, but only load patches, not planar faces
  for LIndex := 0 to AMap.NumSurfaces - 1 do
  begin
    if LSurfaces[LIndex].SurfaceType <> MST_PATCH then
      Continue; // ignore other surfaces

    // load the full drawverts
    LCount := LSurfaces[LIndex].PatchWidth * LSurfaces[LIndex].PatchHeight;
    if LCount > Q3_MAX_PATCH_VERTS then
      raise EQ3CollisionException.Create(SMaxPatchVerts);
    if (LCount < 0) or (LSurfaces[LIndex].FirstVert < 0) or
       (Int64(LSurfaces[LIndex].FirstVert) + LCount > Length(LVerts)) then
      raise EQ3CollisionException.CreateFmt(SBadPatchVerts, [LIndex, LCount, LSurfaces[LIndex].FirstVert,
        Length(LVerts)]);

    AMap.Patches[LIndex].Present := True;
    AMap.Patches[LIndex].Width := LSurfaces[LIndex].PatchWidth;
    AMap.Patches[LIndex].Height := LSurfaces[LIndex].PatchHeight;
    SetLength(AMap.Patches[LIndex].Points, LCount);
    for LJ := 0 to LCount - 1 do
      for LAxis := 0 to 2 do
        AMap.Patches[LIndex].Points[LJ][LAxis] := LVerts[LSurfaces[LIndex].FirstVert + LJ].Xyz[LAxis];

    AMap.Patches[LIndex].Contents := AMap.Shaders[LSurfaces[LIndex].ShaderNum].ContentFlags;
    AMap.Patches[LIndex].SurfaceFlags := AMap.Shaders[LSurfaces[LIndex].ShaderNum].SurfaceFlags;

    // create the internal facet structure
    if Assigned(FPatchBuilder) then
      AMap.PatchCollides[LIndex] := FPatchBuilder.Generate(AMap.Patches[LIndex].Width,
        AMap.Patches[LIndex].Height, AMap.Patches[LIndex].Points);
  end;
end;

end.
