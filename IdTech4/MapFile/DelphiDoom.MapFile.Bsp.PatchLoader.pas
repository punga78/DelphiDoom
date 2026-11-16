{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the BSP of Quake III Arena: the patches      }
{  of the surfaces                                                             }
{                                                                              }
{  Port of ParseMesh and of the patch part of R_LoadSurfaces (tr_bsp.c). Based }
{  on the Quake III Arena GPL Source Code (id Software). Copyright (C)         }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.PatchLoader;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.MapFile.Bsp.Types, DelphiDoom.MathCore.Patch.Intf;

type
  /// <summary>
  ///   Turns the patch surfaces of a BSP into subdivided grids, with the LOD origin and radius
  ///   that the file gives to the group they are in, then stitches them and fixes the errors of
  ///   the vertices they share (with PATCH_STITCHING the engine does both; without a stitcher
  ///   only the second). Everything the original leaves to the shader system is left out: a
  ///   patch whose shader has SURF_NODRAW gives nil, as the "skip" surface of the original.
  /// </summary>
  TBspPatchLoader = class(TInterfacedObject, IBspPatchLoader)
  strict private
    FSubdivider: IPatchSubdivider;
    FStitcher: IBspPatchStitcher;
    FLodFixer: IBspLodFixer;
    FColorShift: Integer;
    FStitchCount: Integer;
    function ParseMesh(const AFile: IBspFile; const AIndex: Integer): IPatchGrid;
  public
    /// <param name="AColorShift">r_mapOverBrightBits - overbrightBits (see TBspColorShift)</param>
    /// <param name="AStitcher">nil to leave out R_StitchAllPatches</param>
    constructor Create(const ASubdivider: IPatchSubdivider; const AStitcher: IBspPatchStitcher;
      const ALodFixer: IBspLodFixer; const AColorShift: Integer);
    function LoadGrids(const AFile: IBspFile): TArray<IPatchGrid>;
    function GetStitchCount: Integer;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MapFile.Bsp.ColorShift,
  DelphiDoom.MathCore.Patch.Types, DelphiDoom.MathCore.Patch.VertexMath;

resourcestring
  SBspBadShaderNum = 'ShaderForShaderNum: bad num %d';
  SBspBadSurfaceType = 'Bad surfaceType';
  SBspPatchVertsOutside = 'ParseMesh: surface %d needs vertices %d to %d of %d';
  SBspBadPatch = 'ParseMesh: surface %d is not a valid patch: %s';

{ TBspPatchLoader }

constructor TBspPatchLoader.Create(const ASubdivider: IPatchSubdivider;
  const AStitcher: IBspPatchStitcher; const ALodFixer: IBspLodFixer; const AColorShift: Integer);
begin
  inherited Create;
  FSubdivider := ASubdivider;
  FStitcher := AStitcher;
  FLodFixer := ALodFixer;
  FColorShift := AColorShift;
end;

function TBspPatchLoader.ParseMesh(const AFile: IBspFile; const AIndex: Integer): IPatchGrid;
var
  LSurface: TBspSurface;
  LShaders: TArray<TBspShader>;
  LVerts: TArray<TBspDrawVert>;
  LPoints: TArray<TPatchVertex>;
  LWidth, LHeight, LNumPoints, LIndex, LAxis: Integer;
  LColor, LShifted: TBspColor;
  LBounds0, LBounds1, LOrigin, LTemp: TIdVec3;
begin
  LSurface := AFile.Surfaces[AIndex];
  LShaders := AFile.Shaders;
  // get shader value
  if (LSurface.ShaderNum < 0) or (LSurface.ShaderNum >= Length(LShaders)) then
    raise EBspFileException.CreateFmt(SBspBadShaderNum, [LSurface.ShaderNum]);
  // we may have a nodraw surface, because they might still need to be around for movement clipping
  if (LShaders[LSurface.ShaderNum].SurfaceFlags and SURF_NODRAW) <> 0 then
    Exit(nil);

  LWidth := LSurface.PatchWidth;
  LHeight := LSurface.PatchHeight;
  LVerts := AFile.DrawVerts;
  if (LWidth < 1) or (LHeight < 1) or (LSurface.FirstVert < 0) or
     (Int64(LSurface.FirstVert) + Int64(LWidth) * LHeight > Length(LVerts)) then
    raise EBspFileException.CreateFmt(SBspPatchVertsOutside, [AIndex, LSurface.FirstVert,
      Int64(LSurface.FirstVert) + Int64(LWidth) * LHeight, Length(LVerts)]);
  LNumPoints := LWidth * LHeight;
  SetLength(LPoints, LNumPoints);
  for LIndex := 0 to LNumPoints - 1 do
  begin
    with LVerts[LSurface.FirstVert + LIndex] do
    begin
      LPoints[LIndex].Position.SetValues(Xyz[0], Xyz[1], Xyz[2]);
      LPoints[LIndex].Normal.SetValues(Normal[0], Normal[1], Normal[2]);
      LPoints[LIndex].TexCoord.X := St[0];
      LPoints[LIndex].TexCoord.Y := St[1];
      LPoints[LIndex].Lightmap.X := Lightmap[0];
      LPoints[LIndex].Lightmap.Y := Lightmap[1];
      for LAxis := 0 to 3 do
        LColor[LAxis] := Color[LAxis];
    end;
    TBspColorShift.Apply(FColorShift, LColor, LShifted);
    for LAxis := 0 to 3 do
      LPoints[LIndex].Color[LAxis] := LShifted[LAxis];
  end;

  // pre-tesseleate
  try
    Result := FSubdivider.SubdividePatchToGrid(LWidth, LHeight, LPoints);
  except
    on E: EPatchException do
      raise EBspFileException.CreateFmt(SBspBadPatch, [AIndex, E.Message]);
  end;

  // copy the level of detail origin, which is the center of the group of all curves that
  // must subdivide the same to avoid cracking
  LBounds0.SetValues(LSurface.LightmapVecs[0, 0], LSurface.LightmapVecs[0, 1], LSurface.LightmapVecs[0, 2]);
  LBounds1.SetValues(LSurface.LightmapVecs[1, 0], LSurface.LightmapVecs[1, 1], LSurface.LightmapVecs[1, 2]);
  LBounds1 := LBounds0 + LBounds1;
  LOrigin := LBounds1 * 0.5;
  Result.LodOrigin := LOrigin;
  LTemp := LBounds0 - LOrigin;
  Result.LodRadius := TPatchVertexMath.Length(LTemp);
end;

function TBspPatchLoader.LoadGrids(const AFile: IBspFile): TArray<IPatchGrid>;
var
  LSurfaces: TArray<TBspSurface>;
  LIndex: Integer;
begin
  LSurfaces := AFile.Surfaces;
  SetLength(Result, Length(LSurfaces));
  for LIndex := 0 to High(LSurfaces) do
    case LSurfaces[LIndex].SurfaceType of
      MST_PATCH:
        Result[LIndex] := ParseMesh(AFile, LIndex);
      MST_TRIANGLE_SOUP, MST_PLANAR, MST_FLARE:
        Result[LIndex] := nil;
    else
      raise EBspFileException.Create(SBspBadSurfaceType);
    end;

  FStitchCount := 0;
  if Assigned(FStitcher) then
    FStitchCount := FStitcher.StitchAll(Result);
  if Assigned(FLodFixer) then
    FLodFixer.Fix(Result);
end;

function TBspPatchLoader.GetStitchCount: Integer;
begin
  Result := FStitchCount;
end;

end.
