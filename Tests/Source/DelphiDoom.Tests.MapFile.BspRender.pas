{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - the lightmaps, the light grid   }
{  and the tree of the renderer, with the parity of the real tr_bsp.c          }
{  (bsp_render.golden.txt)                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.BspRender;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Geometry.Vec3,
  DelphiDoom.MapFile.Bsp.Types, DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.MapFile.Bsp.RenderTypes;

type
  [TestFixture]
  [Category('MapFile')]
  TTestBspRenderGolden = class
  strict private
    FSeed: Cardinal;
    FOutput: TStringList;
    function DataFolder: string;
    function NextRandom: Cardinal;
    function RandomBytes(const ACount: Integer; const ASeed: Cardinal): TBytes;
    function Hash(const ABytes: TBytes; const ACount: Integer): Cardinal;
    function Bits(const AValue: Single): string;
    function VectorBits(const ATag: string; const AValue: TGeoVec3): string;
    procedure LightmapCase(const ATag: string; const ALump: TBytes);
    procedure GridCase(const AIndex: Integer; const AMins, AMaxs, ASize: TGeoVec3; const AShift, ADelta: Integer);
    procedure PrintTree(const ATag: string; const ATree: TBspRenderTree);
    procedure MakeTree(out ANodes: TArray<TBspNode>; out ALeafs: TArray<TBspLeaf>);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    /// <summary>
    ///   bsp_render.golden.txt is what the real R_LoadLightmaps, R_LoadLightGrid,
    ///   R_LoadNodesAndLeafs and R_SetParent of tr_bsp.c print for the lumps of the sample BSP
    ///   (variant 0) and for lumps made here with a generator xorshift32 and a fixed seed
    /// </summary>
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroTrBsp;
  end;

  [TestFixture]
  [Category('MapFile')]
  TTestBspRenderLoaders = class
  public
    [Test]
    procedure DovrebbeContareLeLightmapComeIlRenderer;
    [Test]
    procedure DovrebbeDareAlfa255EIlColoreSpostato;
    [Test]
    procedure DovrebbeNormalizzareIlColoreSeSuperaIl255;
    [Test]
    procedure DovrebbeIgnorareLaLightmapIncompleta;
    [Test]
    procedure DovrebbeDareNeroPerLaSecondaLightmapDellHack;
    [Test]
    procedure DovrebbeSegnalareLaGrigliaDiLuceChenonCorrisponde;
    [Test]
    procedure DovrebbeSpostareICampiDellaGrigliaDiLuce;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneDellaGrigliaNonPositiva;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiCelleFuoriDalLimite;
    [Test]
    procedure DovrebbeLeggereLaDimensioneDellaGrigliaDalWorldspawn;
    [Test]
    procedure DovrebbeUsareLaDimensionePredefinitaSenzaGridsize;
    [Test]
    procedure DovrebbeFermarsiAUnaRemapSenzaPuntoEVirgola;
    [Test]
    procedure DovrebbeSaltareLeRemapConIlPuntoEVirgola;
    [Test]
    procedure DovrebbeLeggereSoloIlWorldspawn;
    [Test]
    procedure DovrebbeSaltareICommentiEIValoriVuotiFermanoLaLettura;
    [Test]
    procedure DovrebbeLeggereUnaDimensioneIncompleta;
    [Test]
    procedure DovrebbeCatenareIGenitoriDellAlbero;
    [Test]
    procedure DovrebbeCalcolareIlNumeroDiCluster;
    [Test]
    procedure DovrebbeCaricareUnAlberoVuotoEUnaSolaFoglia;
    [Test]
    procedure DovrebbeRifiutareUnPianoFuoriDalLump;
    [Test]
    procedure DovrebbeRifiutareUnFiglioFuoriDaiNodiEDalleFoglie;
    [Test]
    procedure DovrebbeRifiutareUnNodoConDueGenitori;
    [Test]
    procedure DovrebbeCrearePerMezzoDellaFactory;
  end;

implementation

uses
  System.IOUtils, System.Math, DelphiDoom.Geometry.Bounds, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.MapFile.Bsp.Factory, DelphiDoom.MapFile.Bsp.GridSizeReader, DelphiDoom.Tests.IdLib.Fakes,
  DelphiDoom.Tests.MapFile.BspSample;

const
  DEFAULT_GRID: array[0..2] of Single = (64, 64, 128);

function FloatBits(const AValue: Single): Cardinal;
var
  LValue: Single;
begin
  LValue := AValue;
  Result := PCardinal(@LValue)^;
end;

{ TTestBspRenderGolden }

procedure TTestBspRenderGolden.Setup;
begin
  FOutput := TStringList.Create;
end;

procedure TTestBspRenderGolden.TearDown;
begin
  FOutput.Free;
end;

function TTestBspRenderGolden.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\MapFile\');
end;

function TTestBspRenderGolden.NextRandom: Cardinal;
begin
  FSeed := FSeed xor (FSeed shl 13);
  FSeed := FSeed xor (FSeed shr 17);
  FSeed := FSeed xor (FSeed shl 5);
  Result := FSeed;
end;

function TTestBspRenderGolden.RandomBytes(const ACount: Integer; const ASeed: Cardinal): TBytes;
var
  LIndex: Integer;
begin
  FSeed := ASeed;
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    Result[LIndex] := Byte(NextRandom shr 9);
end;

function TTestBspRenderGolden.Hash(const ABytes: TBytes; const ACount: Integer): Cardinal;
var
  LIndex: Integer;
begin
  Result := 2166136261;
  for LIndex := 0 to ACount - 1 do
    Result := (Result xor ABytes[LIndex]) * 16777619;
end;

function TTestBspRenderGolden.Bits(const AValue: Single): string;
begin
  Result := LowerCase(IntToHex(FloatBits(AValue), 8));
end;

function TTestBspRenderGolden.VectorBits(const ATag: string; const AValue: TGeoVec3): string;
begin
  Result := Format(' %s %s %s %s', [ATag, Bits(AValue.X), Bits(AValue.Y), Bits(AValue.Z)]);
end;

procedure TTestBspRenderGolden.LightmapCase(const ATag: string; const ALump: TBytes);
const
  MAP_BITS: array[0..3] of Integer = (2, 2, 1, 3);
  OVERBRIGHT: array[0..3] of Integer = (1, 0, 1, 0);
var
  LLoader: IBspLightmapLoader;
  LImages: TArray<TBytes>;
  LVariant, LImage, LShift: Integer;
begin
  LLoader := TBspFactory.CreateLightmapLoader;
  for LVariant := 0 to 3 do
  begin
    LShift := MAP_BITS[LVariant] - OVERBRIGHT[LVariant];
    if ATag = 'vertexlight' then
    begin
      // in vertex light mode the images are not made: only the count is known
      FOutput.Add(Format('lm %s len %d shift %d count %d', [ATag, Length(ALump), LShift,
        LLoader.LightmapCount(Length(ALump))]));
      Continue;
    end;
    LImages := LLoader.Load(ALump, LShift);
    FOutput.Add(Format('lm %s len %d shift %d count %d', [ATag, Length(ALump), LShift, Length(LImages)]));
    for LImage := 0 to High(LImages) do
      FOutput.Add(Format('lmimg %d %s', [LImage, LowerCase(IntToHex(Hash(LImages[LImage], Length(LImages[LImage])), 8))]));
  end;
end;

procedure TTestBspRenderGolden.GridCase(const AIndex: Integer; const AMins, AMaxs, ASize: TGeoVec3;
  const AShift, ADelta: Integer);
var
  LLoader: IBspLightGridLoader;
  LGrid: TBspLightGrid;
  LBounds: TGeoBounds;
  LCells: Integer;
  LRandom, LLump: TBytes;
  LLine: string;
begin
  LLoader := TBspFactory.CreateLightGridLoader;
  LBounds := TGeoBounds.Make(AMins, AMaxs);
  // the probe: a lump of one byte never fits, the cells are known
  LGrid := LLoader.Load(LBounds, ASize, TBytes.Create(0), AShift);
  LCells := LGrid.Bounds[0] * LGrid.Bounds[1] * LGrid.Bounds[2];
  LRandom := RandomBytes(LCells * 8 + 8, 777 + Cardinal(AIndex));
  LLump := Copy(LRandom, 0, LCells * 8 + ADelta);
  LGrid := LLoader.Load(LBounds, ASize, LLump, AShift);
  LLine := Format('grid %d bounds %d %d %d n %d', [AIndex, LGrid.Bounds[0], LGrid.Bounds[1], LGrid.Bounds[2], LCells]);
  LLine := LLine + VectorBits('origin', LGrid.Origin) + VectorBits('size', LGrid.Size) +
    VectorBits('inv', LGrid.InverseSize);
  if Length(LGrid.Data) = 0 then
    LLine := LLine + ' data null'
  else
    LLine := LLine + ' data ' + LowerCase(IntToHex(Hash(LGrid.Data, LCells * 8), 8));
  FOutput.Add(LLine);
end;

procedure TTestBspRenderGolden.PrintTree(const ATag: string; const ATree: TBspRenderTree);
var
  LIndex: Integer;
  LNode: TBspRenderNode;
  LContents, LPlane, LFirstChild, LSecondChild, LMark: Integer;
begin
  FOutput.Add(Format('tree %s nodes %d decision %d clusters %d', [ATag, Length(ATree.Nodes),
    ATree.NumDecisionNodes, ATree.NumClusters]));
  for LIndex := 0 to High(ATree.Nodes) do
  begin
    LNode := ATree.Nodes[LIndex];
    if LNode.IsNode then
    begin
      LContents := -1;
      LPlane := LNode.PlaneNum;
      LFirstChild := LNode.Children[0];
      LSecondChild := LNode.Children[1];
      LMark := -1;
    end
    else
    begin
      LContents := 0;
      LPlane := -1;
      LFirstChild := -1;
      LSecondChild := -1;
      LMark := LNode.FirstMarkSurface;
    end;
    FOutput.Add(Format('n %d %d %d %d %d %d | %d %d %d | %d %d %d | %d %d %d %d', [LIndex, LContents, LNode.Parent,
      LPlane, LFirstChild, LSecondChild, Trunc(LNode.Mins.X), Trunc(LNode.Mins.Y), Trunc(LNode.Mins.Z),
      Trunc(LNode.Maxs.X), Trunc(LNode.Maxs.Y), Trunc(LNode.Maxs.Z), LNode.Cluster, LNode.Area, LMark,
      LNode.NumMarkSurfaces]));
  end;
end;

procedure TTestBspRenderGolden.MakeTree(out ANodes: TArray<TBspNode>; out ALeafs: TArray<TBspLeaf>);
var
  LIndex, LSide, LChild, LAxis, LLeaf: Integer;
begin
  FSeed := $5EED1234;
  SetLength(ANodes, 40);
  SetLength(ALeafs, 41);
  LLeaf := 0;
  for LIndex := 0 to 39 do
  begin
    ANodes[LIndex].PlaneNum := LIndex mod 8;
    for LSide := 0 to 1 do
    begin
      LChild := 2 * LIndex + 1 + LSide;
      if LChild < 40 then
        ANodes[LIndex].Children[LSide] := LChild
      else
      begin
        ANodes[LIndex].Children[LSide] := -1 - LLeaf;
        Inc(LLeaf);
      end;
    end;
    for LAxis := 0 to 2 do
      ANodes[LIndex].Mins[LAxis] := Integer(NextRandom mod 2001) - 1000;
    for LAxis := 0 to 2 do
      ANodes[LIndex].Maxs[LAxis] := ANodes[LIndex].Mins[LAxis] + Integer(NextRandom mod 500);
  end;
  for LIndex := 0 to 40 do
  begin
    ALeafs[LIndex].Cluster := Integer(NextRandom mod 14) - 1;
    ALeafs[LIndex].Area := Integer(NextRandom mod 5);
    for LAxis := 0 to 2 do
      ALeafs[LIndex].Mins[LAxis] := Integer(NextRandom mod 2001) - 1000;
    for LAxis := 0 to 2 do
      ALeafs[LIndex].Maxs[LAxis] := ALeafs[LIndex].Mins[LAxis] + Integer(NextRandom mod 500);
    ALeafs[LIndex].FirstLeafSurface := Integer(NextRandom mod 50);
    ALeafs[LIndex].NumLeafSurfaces := Integer(NextRandom mod 7);
    ALeafs[LIndex].FirstLeafBrush := Integer(NextRandom mod 10);
    ALeafs[LIndex].NumLeafBrushes := Integer(NextRandom mod 3);
  end;
end;

procedure TTestBspRenderGolden.DovrebbeDareLeStesseRisposteDelVeroTrBsp;
var
  LGolden: TStringList;
  LBuilder: TBspSampleBuilder;
  LFile: IBspFile;
  LNodes: TArray<TBspNode>;
  LLeafs: TArray<TBspLeaf>;
  LLine: string;
  LIndex: Integer;
  LExpected: TStringList;
begin
  LGolden := TStringList.Create;
  LExpected := TStringList.Create;
  try
    Assert.IsTrue(TFile.Exists(DataFolder + 'bsp_render.golden.txt'), 'bsp_render.golden.txt not found');
    LGolden.LoadFromFile(DataFolder + 'bsp_render.golden.txt');
    // the warnings of the log are tested apart
    for LLine in LGolden do
      if not LLine.StartsWith('ri ') then
        LExpected.Add(LLine);
    Assert.IsTrue(LExpected.Count > 100, 'too few golden lines');

    LBuilder := TBspSampleBuilder.Create;
    try
      LFile := TBspFactory.CreateReader.ParseBytes(LBuilder.Build(0), 'sample');
    finally
      LBuilder.Free;
    end;
    LightmapCase('file', LFile.Lightmaps);
    LightmapCase('one', RandomBytes(49152, 4242));
    LightmapCase('twoandahalf', RandomBytes(49152 * 2 + 1000, 99));
    LightmapCase('none', nil);
    LightmapCase('vertexlight', RandomBytes(49152 * 2, 0));

    GridCase(0, TGeoVec3.Make(-64, -64, -64), TGeoVec3.Make(64, 64, 64), TGeoVec3.Make(64, 64, 128), 1, 0);
    GridCase(1, TGeoVec3.Make(-100, -37.5, -8), TGeoVec3.Make(230.25, 90, 300), TGeoVec3.Make(64, 64, 128), 1, 0);
    GridCase(2, TGeoVec3.Make(-1000, -900.5, -1200), TGeoVec3.Make(1800, 1500.75, 2200),
      TGeoVec3.Make(50, 40, 30), 3, 0);
    GridCase(3, TGeoVec3.Make(10, 10, 10), TGeoVec3.Make(500, 500, 500), TGeoVec3.Make(100, 100, 100), 0, 0);
    GridCase(4, TGeoVec3.Make(-100, -37.5, -8), TGeoVec3.Make(230.25, 90, 300), TGeoVec3.Make(64, 64, 128), 1, 8);

    MakeTree(LNodes, LLeafs);
    PrintTree('heap', TBspFactory.CreateTreeLoader.Load(LNodes, LLeafs, 8));
    PrintTree('file', TBspFactory.CreateTreeLoader.Load(LFile.Nodes, LFile.Leafs, Length(LFile.Planes)));

    Assert.AreEqual<Integer>(LExpected.Count, FOutput.Count, 'number of lines');
    for LIndex := 0 to LExpected.Count - 1 do
      Assert.AreEqual(LExpected[LIndex], FOutput[LIndex], 'line ' + IntToStr(LIndex + 1));
  finally
    LExpected.Free;
    LGolden.Free;
  end;
end;

{ TTestBspRenderLoaders }

procedure TTestBspRenderLoaders.DovrebbeContareLeLightmapComeIlRenderer;
var
  LLoader: IBspLightmapLoader;
begin
  LLoader := TBspFactory.CreateLightmapLoader;
  Assert.AreEqual<Integer>(0, LLoader.LightmapCount(0));
  Assert.AreEqual<Integer>(0, LLoader.LightmapCount(100));
  Assert.AreEqual<Integer>(2, LLoader.LightmapCount(BSP_LIGHTMAP_BYTES));
  Assert.AreEqual<Integer>(2, LLoader.LightmapCount(BSP_LIGHTMAP_BYTES * 2));
  Assert.AreEqual<Integer>(3, LLoader.LightmapCount(BSP_LIGHTMAP_BYTES * 3 + 5));
end;

procedure TTestBspRenderLoaders.DovrebbeDareAlfa255EIlColoreSpostato;
var
  LBytes: TBytes;
  LImages: TArray<TBytes>;
begin
  SetLength(LBytes, BSP_LIGHTMAP_BYTES * 2);
  LBytes[0] := 10;
  LBytes[1] := 20;
  LBytes[2] := 30;
  LImages := TBspFactory.CreateLightmapLoader.Load(LBytes, 1);
  Assert.AreEqual<Integer>(2, Length(LImages));
  Assert.AreEqual<Integer>(128 * 128 * 4, Length(LImages[0]));
  Assert.AreEqual<Integer>(20, LImages[0][0]);
  Assert.AreEqual<Integer>(40, LImages[0][1]);
  Assert.AreEqual<Integer>(60, LImages[0][2]);
  Assert.AreEqual<Integer>(255, LImages[0][3]);
  Assert.AreEqual<Integer>(255, LImages[0][7]);
end;

procedure TTestBspRenderLoaders.DovrebbeNormalizzareIlColoreSeSuperaIl255;
var
  LBytes: TBytes;
  LImages: TArray<TBytes>;
begin
  SetLength(LBytes, BSP_LIGHTMAP_BYTES * 2);
  LBytes[0] := 200;
  LBytes[1] := 100;
  LBytes[2] := 50;
  // 400 200 100 over 255: scaled so that the largest is 255
  LImages := TBspFactory.CreateLightmapLoader.Load(LBytes, 1);
  Assert.AreEqual<Integer>(255, LImages[0][0]);
  Assert.AreEqual<Integer>(127, LImages[0][1]);
  Assert.AreEqual<Integer>(63, LImages[0][2]);
end;

procedure TTestBspRenderLoaders.DovrebbeIgnorareLaLightmapIncompleta;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, BSP_LIGHTMAP_BYTES * 2 + 3000);
  Assert.AreEqual<Integer>(2, Length(TBspFactory.CreateLightmapLoader.Load(LBytes, 0)));
  Assert.AreEqual<Integer>(0, Length(TBspFactory.CreateLightmapLoader.Load(nil, 0)));
end;

procedure TTestBspRenderLoaders.DovrebbeDareNeroPerLaSecondaLightmapDellHack;
var
  LBytes: TBytes;
  LImages: TArray<TBytes>;
begin
  SetLength(LBytes, BSP_LIGHTMAP_BYTES);
  FillChar(LBytes[0], Length(LBytes), 77);
  LImages := TBspFactory.CreateLightmapLoader.Load(LBytes, 0);
  Assert.AreEqual<Integer>(2, Length(LImages));
  Assert.AreEqual<Integer>(77, LImages[0][100]);
  Assert.AreEqual<Integer>(0, LImages[1][100]);
  Assert.AreEqual<Integer>(255, LImages[1][103]);
end;

procedure TTestBspRenderLoaders.DovrebbeSegnalareLaGrigliaDiLuceChenonCorrisponde;
var
  LLog: TIdLibLogRecorder;
  LLoader: IBspLightGridLoader;
  LGrid: TBspLightGrid;
  LLogIntf: IIdLibLog;
begin
  LLog := TIdLibLogRecorder.Create;
  LLogIntf := LLog;
  LLoader := TBspFactory.CreateLightGridLoader(LLogIntf);
  LGrid := LLoader.Load(TGeoBounds.Make(TGeoVec3.Make(-64, -64, -64), TGeoVec3.Make(64, 64, 64)),
    TGeoVec3.Make(64, 64, 128), TBytes.Create(1, 2, 3), 0);
  Assert.AreEqual<Integer>(0, Length(LGrid.Data));
  Assert.AreEqual<Integer>(3, LGrid.Bounds[0]);
  Assert.AreEqual<Integer>(1, LLog.Entries.Count);
  Assert.Contains(LLog.Entries[0], 'light grid mismatch');
end;

procedure TTestBspRenderLoaders.DovrebbeSpostareICampiDellaGrigliaDiLuce;
var
  LLump: TBytes;
  LGrid: TBspLightGrid;
begin
  SetLength(LLump, 9 * 8);
  LLump[0] := 100;
  LLump[1] := 50;
  LLump[2] := 10;
  LLump[3] := 7;
  LLump[4] := 20;
  LLump[5] := 30;
  LLump[6] := 255;
  LLump[7] := 9;
  // the second colour starts at the byte 3 of the cell, where the first one has its fourth
  LGrid := TBspFactory.CreateLightGridLoader.Load(TGeoBounds.Make(TGeoVec3.Make(-64, -64, -64),
    TGeoVec3.Make(64, 64, 64)), TGeoVec3.Make(64, 64, 128), LLump, 1);
  Assert.AreEqual<Integer>(200, LGrid.Data[0]);
  Assert.AreEqual<Integer>(100, LGrid.Data[1]);
  Assert.AreEqual<Integer>(20, LGrid.Data[2]);
  Assert.AreEqual<Integer>(14, LGrid.Data[3]);
  Assert.AreEqual<Integer>(40, LGrid.Data[4]);
  Assert.AreEqual<Integer>(60, LGrid.Data[5]);
  Assert.AreEqual<Integer>(255, LGrid.Data[6]);
  Assert.AreEqual<Integer>(9, LGrid.Data[7]);
  Assert.AreEqual<Single>(1 / 64, LGrid.InverseSize.X);
end;

procedure TTestBspRenderLoaders.DovrebbeRifiutareUnaDimensioneDellaGrigliaNonPositiva;
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    TBspFactory.CreateLightGridLoader.Load(TGeoBounds.Make(TGeoVec3.Origin, TGeoVec3.Make(1, 1, 1)),
      TGeoVec3.Make(64, 0, 128), nil, 0);
  except
    on E: EBspFileException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestBspRenderLoaders.DovrebbeRifiutareUnNumeroDiCelleFuoriDalLimite;
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    TBspFactory.CreateLightGridLoader.Load(TGeoBounds.Make(TGeoVec3.Make(-1E30, 0, 0), TGeoVec3.Make(1E30, 1, 1)),
      TGeoVec3.Make(1, 1, 1), nil, 0);
  except
    on E: EBspFileException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestBspRenderLoaders.DovrebbeLeggereLaDimensioneDellaGrigliaDalWorldspawn;
var
  LSize: TGeoVec3;
begin
  LSize := TBspGridSizeReader.Read('{ "classname" "worldspawn" "GridSize" "32 48 96" }'#10'{ "gridsize" "1 1 1" }');
  Assert.AreEqual<Single>(32, LSize.X);
  Assert.AreEqual<Single>(48, LSize.Y);
  Assert.AreEqual<Single>(96, LSize.Z);
end;

procedure TTestBspRenderLoaders.DovrebbeUsareLaDimensionePredefinitaSenzaGridsize;
var
  LSize: TGeoVec3;
begin
  LSize := TBspGridSizeReader.Read('{ "classname" "worldspawn" }');
  Assert.AreEqual<Single>(DEFAULT_GRID[0], LSize.X);
  Assert.AreEqual<Single>(DEFAULT_GRID[1], LSize.Y);
  Assert.AreEqual<Single>(DEFAULT_GRID[2], LSize.Z);
  // no entity at all, or text that does not begin with a brace
  Assert.AreEqual<Single>(128, TBspGridSizeReader.Read('').Z);
  Assert.AreEqual<Single>(128, TBspGridSizeReader.Read('"gridsize" "1 2 3"').Z);
end;

procedure TTestBspRenderLoaders.DovrebbeFermarsiAUnaRemapSenzaPuntoEVirgola;
begin
  Assert.AreEqual<Single>(128, TBspGridSizeReader.Read(
    '{ "remapshader" "textures/a" "gridsize" "10 10 10" }').Z);
  Assert.AreEqual<Single>(128, TBspGridSizeReader.Read(
    '{ "vertexremapshader" "textures/a" "gridsize" "10 10 10" }').Z);
end;

procedure TTestBspRenderLoaders.DovrebbeSaltareLeRemapConIlPuntoEVirgola;
begin
  Assert.AreEqual<Single>(10, TBspGridSizeReader.Read(
    '{ "remapshader" "textures/a;textures/b;0" "gridsize" "10 10 10" }').Z);
  Assert.AreEqual<Single>(10, TBspGridSizeReader.Read(
    '{ "remapshader2" "a;b" "vertexremapshader1" "a;b" "gridsize" "10 10 10" }').Z);
end;

procedure TTestBspRenderLoaders.DovrebbeLeggereSoloIlWorldspawn;
begin
  Assert.AreEqual<Single>(128, TBspGridSizeReader.Read('{ "classname" "worldspawn" } { "gridsize" "9 9 9" }').Z);
end;

procedure TTestBspRenderLoaders.DovrebbeSaltareICommentiEIValoriVuotiFermanoLaLettura;
begin
  Assert.AreEqual<Single>(7, TBspGridSizeReader.Read(
    '{ // a comment'#10' /* another */ "gridsize" "7 7 7" }').Z);
  // an empty value is an empty token: it ends the reading, as in COM_ParseExt
  Assert.AreEqual<Single>(128, TBspGridSizeReader.Read('{ "message" "" "gridsize" "7 7 7" }').Z);
  // a word that is not between quotes ends at the first space
  Assert.AreEqual<Single>(5, TBspGridSizeReader.Read('{ gridsize 5 5 5 }').X);
  Assert.AreEqual<Single>(64, TBspGridSizeReader.Read('{ gridsize 5 5 5 }').Y);
end;

procedure TTestBspRenderLoaders.DovrebbeLeggereUnaDimensioneIncompleta;
var
  LSize: TGeoVec3;
begin
  // sscanf stops at the first number that is missing: the others keep their default
  LSize := TBspGridSizeReader.Read('{ "gridsize" "16 24" }');
  Assert.AreEqual<Single>(16, LSize.X);
  Assert.AreEqual<Single>(24, LSize.Y);
  Assert.AreEqual<Single>(128, LSize.Z);
end;

procedure TTestBspRenderLoaders.DovrebbeCatenareIGenitoriDellAlbero;
var
  LNodes: TArray<TBspNode>;
  LLeafs: TArray<TBspLeaf>;
  LTree: TBspRenderTree;
begin
  SetLength(LNodes, 2);
  SetLength(LLeafs, 3);
  LNodes[0].Children[0] := 1;
  LNodes[0].Children[1] := -3;
  LNodes[1].Children[0] := -1;
  LNodes[1].Children[1] := -2;
  LTree := TBspFactory.CreateTreeLoader.Load(LNodes, LLeafs, 1);
  Assert.AreEqual<Integer>(5, Length(LTree.Nodes));
  Assert.AreEqual<Integer>(2, LTree.NumDecisionNodes);
  Assert.AreEqual<Integer>(-1, LTree.Nodes[0].Parent);
  Assert.AreEqual<Integer>(0, LTree.Nodes[1].Parent);
  // leaf -1 is index 2, leaf -3 is index 4
  Assert.AreEqual<Integer>(4, LTree.Nodes[0].Children[1]);
  Assert.AreEqual<Integer>(1, LTree.Nodes[2].Parent);
  Assert.AreEqual<Integer>(1, LTree.Nodes[3].Parent);
  Assert.AreEqual<Integer>(0, LTree.Nodes[4].Parent);
  Assert.IsTrue(LTree.Nodes[0].IsNode);
  Assert.IsFalse(LTree.Nodes[2].IsNode);
end;

procedure TTestBspRenderLoaders.DovrebbeCalcolareIlNumeroDiCluster;
var
  LNodes: TArray<TBspNode>;
  LLeafs: TArray<TBspLeaf>;
begin
  SetLength(LNodes, 1);
  SetLength(LLeafs, 2);
  LNodes[0].Children[0] := -1;
  LNodes[0].Children[1] := -2;
  LLeafs[0].Cluster := -1;
  LLeafs[1].Cluster := 6;
  Assert.AreEqual<Integer>(7, TBspFactory.CreateTreeLoader.Load(LNodes, LLeafs, 1).NumClusters);
  LLeafs[1].Cluster := -1;
  Assert.AreEqual<Integer>(0, TBspFactory.CreateTreeLoader.Load(LNodes, LLeafs, 1).NumClusters);
end;

procedure TTestBspRenderLoaders.DovrebbeCaricareUnAlberoVuotoEUnaSolaFoglia;
var
  LLeafs: TArray<TBspLeaf>;
  LTree: TBspRenderTree;
begin
  LTree := TBspFactory.CreateTreeLoader.Load(nil, nil, 0);
  Assert.AreEqual<Integer>(0, Length(LTree.Nodes));
  SetLength(LLeafs, 1);
  LTree := TBspFactory.CreateTreeLoader.Load(nil, LLeafs, 0);
  Assert.AreEqual<Integer>(1, Length(LTree.Nodes));
  Assert.AreEqual<Integer>(-1, LTree.Nodes[0].Parent);
  Assert.IsFalse(LTree.Nodes[0].IsNode);
end;

procedure TTestBspRenderLoaders.DovrebbeRifiutareUnPianoFuoriDalLump;
var
  LNodes: TArray<TBspNode>;
  LLeafs: TArray<TBspLeaf>;
  LRaised: Boolean;
begin
  SetLength(LNodes, 1);
  SetLength(LLeafs, 2);
  LNodes[0].Children[0] := -1;
  LNodes[0].Children[1] := -2;
  LNodes[0].PlaneNum := 3;
  LRaised := False;
  try
    TBspFactory.CreateTreeLoader.Load(LNodes, LLeafs, 3);
  except
    on E: EBspFileException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestBspRenderLoaders.DovrebbeRifiutareUnFiglioFuoriDaiNodiEDalleFoglie;
var
  LNodes: TArray<TBspNode>;
  LLeafs: TArray<TBspLeaf>;
  LRaised: Boolean;
begin
  SetLength(LNodes, 1);
  SetLength(LLeafs, 1);
  LNodes[0].Children[0] := -1;
  LNodes[0].Children[1] := 5;
  LRaised := False;
  try
    TBspFactory.CreateTreeLoader.Load(LNodes, LLeafs, 1);
  except
    on E: EBspFileException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised, 'node');
  LNodes[0].Children[1] := -2;
  LRaised := False;
  try
    TBspFactory.CreateTreeLoader.Load(LNodes, LLeafs, 1);
  except
    on E: EBspFileException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised, 'leaf');
end;

procedure TTestBspRenderLoaders.DovrebbeRifiutareUnNodoConDueGenitori;
var
  LNodes: TArray<TBspNode>;
  LLeafs: TArray<TBspLeaf>;
  LRaised: Boolean;
begin
  SetLength(LNodes, 2);
  SetLength(LLeafs, 1);
  // node 1 is the child of node 0 twice; and node 1 leads back to the root
  LNodes[0].Children[0] := 1;
  LNodes[0].Children[1] := 1;
  LNodes[1].Children[0] := -1;
  LNodes[1].Children[1] := -1;
  LRaised := False;
  try
    TBspFactory.CreateTreeLoader.Load(LNodes, LLeafs, 1);
  except
    on E: EBspFileException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised, 'shared');
  LNodes[0].Children[1] := -1;
  LNodes[1].Children[1] := 0;
  LRaised := False;
  try
    TBspFactory.CreateTreeLoader.Load(LNodes, LLeafs, 1);
  except
    on E: EBspFileException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised, 'cycle');
end;

procedure TTestBspRenderLoaders.DovrebbeCrearePerMezzoDellaFactory;
begin
  Assert.IsNotNull(TBspFactory.CreateLightmapLoader);
  Assert.IsNotNull(TBspFactory.CreateLightGridLoader);
  Assert.IsNotNull(TBspFactory.CreateTreeLoader);
  Assert.IsNotNull(TBspFactory.CreateWriter);
end;

end.
