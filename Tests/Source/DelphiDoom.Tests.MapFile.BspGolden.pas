{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - parity of the BSP reader and of }
{  the stitching of patches with the real tr_bsp.c of Quake III Arena          }
{  (bsp.golden.txt)                                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.BspGolden;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  /// <summary>
  ///   bsp.golden.txt is what Tools\Verifica\116\bspgen.exe prints for three BSPs it writes
  ///   itself: the sizes of the real structs of qfiles.h, the CRC-32 of the lumps and, from the
  ///   lines of tr_bsp.c and tr_curve.c compiled by gcc, the patch grids after ParseMesh
  ///   ("pre") and after R_StitchAllPatches and R_FixSharedVertexLodError ("grid"). This
  ///   fixture builds the same BSPs, reads them with the classes of the library and prints
  ///   the same lines; the comparison is exact (float bits, FNV-1a of the vertices).
  /// </summary>
  [TestFixture]
  [Category('MapFile')]
  TTestBspGolden = class
  strict private
    function DataFolder: string;
    function Expected(const AVariant: Integer): TStringList;
    function Actual(const AVariant: Integer): TStringList;
    procedure Compare(const AVariant: Integer);
  public
    [Test]
    procedure LaStanzaDovrebbeDareLeStesseRisposteDelC;
    [Test]
    procedure IlCampoDiPatchDovrebbeDareLeStesseRisposteDelC;
    [Test]
    procedure IlSecondoCampoDiPatchDovrebbeDareLeStesseRisposteDelC;
    [Test]
    procedure IlC11DovrebbeRicucireLeFessureDelleTreVarianti;
  end;

implementation

uses
  System.IOUtils, System.Generics.Collections, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MapFile.Bsp.BspFile,
  DelphiDoom.MapFile.Bsp.Factory, DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.MapFile.Bsp.LodFixer,
  DelphiDoom.MapFile.Bsp.PatchLoader, DelphiDoom.MapFile.Bsp.Types, DelphiDoom.MathCore.Crc32,
  DelphiDoom.MathCore.Patch.Factory, DelphiDoom.MathCore.Patch.Intf, DelphiDoom.MathCore.Patch.Types,
  DelphiDoom.Tests.MapFile.BspSample;

function Bits(const AValue: Single): Cardinal;
begin
  Result := PCardinal(@AValue)^;
end;

function Hex(const AValue: Cardinal): string;
begin
  Result := LowerCase(IntToHex(AValue, 8));
end;

function FnvByte(const AHash, AByte: Cardinal): Cardinal;
begin
  Result := (AHash xor (AByte and 255)) * 16777619;
end;

function FnvFloat(AHash: Cardinal; const AValue: Single): Cardinal;
var
  LBits: Cardinal;
begin
  LBits := Bits(AValue);
  AHash := FnvByte(AHash, LBits);
  AHash := FnvByte(AHash, LBits shr 8);
  AHash := FnvByte(AHash, LBits shr 16);
  Result := FnvByte(AHash, LBits shr 24);
end;

procedure PrintGrid(const AOutput: TStrings; const ATag: string; const AIndex: Integer;
  const AGrid: IPatchGrid);
var
  LI: Integer;
  LHash: Cardinal;
  LVertex: TPatchVertex;
  LLine: string;
begin
  LHash := 2166136261;
  for LI := 0 to AGrid.Width * AGrid.Height - 1 do
  begin
    LVertex := AGrid.Vertices[LI];
    LHash := FnvFloat(LHash, LVertex.Position.X);
    LHash := FnvFloat(LHash, LVertex.Position.Y);
    LHash := FnvFloat(LHash, LVertex.Position.Z);
    LHash := FnvFloat(LHash, LVertex.TexCoord.X);
    LHash := FnvFloat(LHash, LVertex.TexCoord.Y);
    LHash := FnvFloat(LHash, LVertex.Lightmap.X);
    LHash := FnvFloat(LHash, LVertex.Lightmap.Y);
    LHash := FnvFloat(LHash, LVertex.Normal.X);
    LHash := FnvFloat(LHash, LVertex.Normal.Y);
    LHash := FnvFloat(LHash, LVertex.Normal.Z);
    LHash := FnvByte(LHash, LVertex.Color[0]);
    LHash := FnvByte(LHash, LVertex.Color[1]);
    LHash := FnvByte(LHash, LVertex.Color[2]);
    LHash := FnvByte(LHash, LVertex.Color[3]);
  end;
  AOutput.Add(Format('%s %d %d %d %s', [ATag, AIndex, AGrid.Width, AGrid.Height, Hex(LHash)]));
  LLine := 'we';
  for LI := 0 to AGrid.Width - 1 do
    LLine := LLine + ' ' + Hex(Bits(AGrid.WidthLodError[LI]));
  AOutput.Add(LLine);
  LLine := 'he';
  for LI := 0 to AGrid.Height - 1 do
    LLine := LLine + ' ' + Hex(Bits(AGrid.HeightLodError[LI]));
  AOutput.Add(LLine);
  AOutput.Add(Format('lod %s %s %s %s', [Hex(Bits(AGrid.LodOrigin.X)), Hex(Bits(AGrid.LodOrigin.Y)),
    Hex(Bits(AGrid.LodOrigin.Z)), Hex(Bits(AGrid.LodRadius))]));
end;

procedure PrintGrids(const AOutput: TStrings; const ATag: string; const AGrids: TArray<IPatchGrid>);
var
  LI: Integer;
begin
  for LI := 0 to High(AGrids) do
    if Assigned(AGrids[LI]) then
      PrintGrid(AOutput, ATag, LI, AGrids[LI]);
end;

{ TTestBspGolden }

function TTestBspGolden.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\MapFile\');
end;

function TTestBspGolden.Expected(const AVariant: Integer): TStringList;
var
  LAll: TStringList;
  LIndex: Integer;
  LInside: Boolean;
begin
  Result := TStringList.Create;
  LAll := TStringList.Create;
  try
    LAll.LoadFromFile(DataFolder + 'bsp.golden.txt');
    LInside := False;
    for LIndex := 0 to LAll.Count - 1 do
    begin
      if LAll[LIndex].StartsWith('bsp ') then
      begin
        LInside := LAll[LIndex] = 'bsp ' + IntToStr(AVariant);
        Continue;
      end;
      if LInside then
        Result.Add(LAll[LIndex]);
    end;
  finally
    LAll.Free;
  end;
end;

function TTestBspGolden.Actual(const AVariant: Integer): TStringList;
const
  RECORD_LUMPS: array[0..12] of Integer = (LUMP_SHADERS, LUMP_PLANES, LUMP_NODES, LUMP_LEAFS,
    LUMP_LEAFSURFACES, LUMP_LEAFBRUSHES, LUMP_MODELS, LUMP_BRUSHES, LUMP_BRUSHSIDES, LUMP_DRAWVERTS,
    LUMP_DRAWINDEXES, LUMP_FOGS, LUMP_SURFACES);
  RECORD_NAMES: array[0..12] of string = ('shaders', 'planes', 'nodes', 'leafs', 'leafsurfaces',
    'leafbrushes', 'models', 'brushes', 'brushsides', 'drawverts', 'drawindexes', 'fogs', 'surfaces');
  RECORD_SIZES: array[0..12] of Integer = (SizeOf(TBspShader), SizeOf(TBspPlane), SizeOf(TBspNode),
    SizeOf(TBspLeaf), 4, 4, SizeOf(TBspModel), SizeOf(TBspBrush), SizeOf(TBspBrushSide),
    SizeOf(TBspDrawVert), 4, SizeOf(TBspFog), SizeOf(TBspSurface));
var
  LBuilder: TBspSampleBuilder;
  LBytes: TBytes;
  LFile: IBspFile;
  LLoader, LRaw: IBspPatchLoader;
  LGrids, LRawGrids: TArray<IPatchGrid>;
  LIndex, LPatches: Integer;
  LLump: TBspLump;
  LData: TBytes;
begin
  Result := TStringList.Create;
  LBuilder := TBspSampleBuilder.Create;
  try
    LBytes := LBuilder.Build(AVariant);
  finally
    LBuilder.Free;
  end;
  LFile := TBspFactory.CreateReader.ParseBytes(LBytes, 'sample');
  Result.Add(Format('header %d %d size %d', [LFile.Version, SizeOf(TBspHeader), Length(LBytes)]));
  for LIndex := 0 to HEADER_LUMPS - 1 do
  begin
    LLump := LFile.Lumps[LIndex];
    LData := LFile.LumpData[LIndex];
    if Length(LData) > 0 then
      Result.Add(Format('lump %d %d %d %s', [LIndex, LLump.FileOfs, LLump.FileLen,
        Hex(TCrc32.Calculate(LData[0], Length(LData)))]))
    else
      Result.Add(Format('lump %d %d %d %s', [LIndex, LLump.FileOfs, LLump.FileLen, Hex(0)]));
  end;
  for LIndex := 0 to High(RECORD_LUMPS) do
    Result.Add(Format('count %s %d size %d', [RECORD_NAMES[LIndex],
      LFile.Lumps[RECORD_LUMPS[LIndex]].FileLen div RECORD_SIZES[LIndex], RECORD_SIZES[LIndex]]));
  Result.Add(Format('sizeof dplane %d dnode %d dleaf %d dmodel %d dbrush %d dbrushside %d dfog %d dshader %d ' +
    'dsurface %d drawvert %d', [SizeOf(TBspPlane), SizeOf(TBspNode), SizeOf(TBspLeaf), SizeOf(TBspModel),
    SizeOf(TBspBrush), SizeOf(TBspBrushSide), SizeOf(TBspFog), SizeOf(TBspShader), SizeOf(TBspSurface),
    SizeOf(TBspDrawVert)]));

  LPatches := 0;
  for LIndex := 0 to High(LFile.Surfaces) do
    if LFile.Surfaces[LIndex].SurfaceType = MST_PATCH then
      Inc(LPatches);
  Result.Add(Format('patches %d', [LPatches]));

  // "pre": ParseMesh only
  LRaw := TBspPatchLoader.Create(TPatchFactory.CreateSubdivider(4.0), nil, nil, 1);
  LRawGrids := LRaw.LoadGrids(LFile);
  PrintGrids(Result, 'pre', LRawGrids);
  LLoader := TBspFactory.CreatePatchLoader(1);
  LGrids := LLoader.LoadGrids(LFile);
  Result.Add(Format('ri stitched %d LoD cracks', [LLoader.StitchCount]));
  PrintGrids(Result, 'grid', LGrids);
end;

procedure TTestBspGolden.Compare(const AVariant: Integer);
var
  LExpected, LActual: TStringList;
  LIndex: Integer;
begin
  LExpected := Expected(AVariant);
  LActual := Actual(AVariant);
  try
    Assert.IsTrue(LExpected.Count > 20, 'bsp.golden.txt not found or empty (variant ' + IntToStr(AVariant) + ')');
    for LIndex := 0 to LExpected.Count - 1 do
    begin
      Assert.IsTrue(LIndex < LActual.Count, 'missing line ' + IntToStr(LIndex) + ': ' + LExpected[LIndex]);
      Assert.AreEqual(LExpected[LIndex], LActual[LIndex], 'line ' + IntToStr(LIndex));
    end;
    Assert.AreEqual(LExpected.Count, LActual.Count, 'number of lines');
  finally
    LExpected.Free;
    LActual.Free;
  end;
end;

procedure TTestBspGolden.LaStanzaDovrebbeDareLeStesseRisposteDelC;
begin
  Compare(0);
end;

procedure TTestBspGolden.IlCampoDiPatchDovrebbeDareLeStesseRisposteDelC;
begin
  Compare(1);
end;

procedure TTestBspGolden.IlSecondoCampoDiPatchDovrebbeDareLeStesseRisposteDelC;
begin
  Compare(2);
end;

procedure TTestBspGolden.IlC11DovrebbeRicucireLeFessureDelleTreVarianti;
var
  LExpected: TStringList;
  LCounts: array[0..2] of Integer;
  LVariant, LIndex: Integer;
  LLoader: IBspPatchLoader;
  LBuilder: TBspSampleBuilder;
  LFile: IBspFile;
begin
  // the number of stitches the C printed: 4, 20, 27 (the cracks are real, the test would
  // pass on an empty stitcher otherwise)
  LCounts[0] := 4;
  LCounts[1] := 20;
  LCounts[2] := 27;
  for LVariant := 0 to 2 do
  begin
    LExpected := Expected(LVariant);
    try
      LIndex := LExpected.IndexOf(Format('ri stitched %d LoD cracks', [LCounts[LVariant]]));
      Assert.IsTrue(LIndex >= 0, 'the golden does not say ' + IntToStr(LCounts[LVariant]) + ' stitches');
    finally
      LExpected.Free;
    end;
    LBuilder := TBspSampleBuilder.Create;
    try
      LFile := TBspFactory.CreateReader.ParseBytes(LBuilder.Build(LVariant), 'sample');
    finally
      LBuilder.Free;
    end;
    LLoader := TBspFactory.CreatePatchLoader(1);
    LLoader.LoadGrids(LFile);
    Assert.AreEqual(LCounts[LVariant], LLoader.StitchCount, 'variant ' + IntToStr(LVariant));
  end;
end;

end.
