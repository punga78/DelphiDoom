{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - the patches of a BSP: loader,   }
{  stitching, LOD errors and the colour shift                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.BspPatches;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MapFile.Bsp.Intf;

type
  [TestFixture]
  [Category('MapFile')]
  TTestBspPatchLoader = class
  strict private
    FBytes: TBytes;
    function Load(const ABytes: TBytes): IBspFile;
    procedure ExpectLoadError(const ABytes: TBytes; const AMessagePart: string);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareUnaGrigliaPerOgniPatchCheSiDisegna;
    [Test]
    procedure DovrebbeDareNilPerLeSuperficiCheNonSonoPatch;
    [Test]
    procedure DovrebbeSaltareUnaPatchConSurfNodraw;
    [Test]
    procedure DovrebbeDareALeGriglieLOrigineELIlRaggioDelGruppo;
    [Test]
    procedure DovrebbeUsareLaSuddivisioneDelCostruttore;
    [Test]
    procedure DovrebbeSpostareIColoriDeiVertici;
    [Test]
    procedure DovrebbeContareLeCucitureEModificareLeGriglie;
    [Test]
    procedure DovrebbeLasciareLeGriglieComeIlCSenzaCucitura;
    [Test]
    procedure DovrebbeRifiutareUnaShaderNumSbagliata;
    [Test]
    procedure DovrebbeRifiutareUnTipoDiSuperficieSbagliato;
    [Test]
    procedure DovrebbeRifiutareUnaPatchConIVerticiFuoriDalLump;
    [Test]
    procedure DovrebbeRifiutareUnaPatchConDimensioniPari;
    [Test]
    procedure DovrebbeDareLeStesseGriglieDueVolte;
  end;

  [TestFixture]
  [Category('MapFile')]
  TTestBspPatchStitcher = class
  public
    [Test]
    procedure DovrebbeInserireLaColonnaMancanteDaUnaRigaDelLatoDelSecondo;
    [Test]
    procedure DovrebbeInserireLaRigaMancanteDaUnaColonna;
    [Test]
    procedure DovrebbeLeggereLErroreInRangeAllIndiceKPiuUnoCome;
    [Test]
    procedure DovrebbeLeggereZeroOltreLaTabellaDegliErroriComeFaIlC;
    [Test]
    procedure NonDovrebbeCucireGriglieDiGruppiDiversi;
    [Test]
    procedure NonDovrebbeCucireSeIlSecondoHaGiaIlVertice;
    [Test]
    procedure NonDovrebbeCucireSeIlSecondoHaGiaILimitiDellaGriglia;
    [Test]
    procedure NonDovrebbeCucireSeIlLatoHaPuntiUniti;
    [Test]
    procedure DovrebbeIgnorareLeCaselleVuote;
    [Test]
    procedure DovrebbeRipetereLaCuciturafinoAlLimite;
  end;

  [TestFixture]
  [Category('MapFile')]
  TTestBspLodFixer = class
  public
    [Test]
    procedure DovrebbeDareAlSecondoGliErroriDelPrimoSuiVerticiCondivisi;
    [Test]
    procedure DovrebbeLasciareStareLeGriglieDiUnAltroGruppo;
    [Test]
    procedure DovrebbePropagareAttraversoLeGriglieCheSiToccano;
    [Test]
    procedure DovrebbeFissareGliErroriDelleRigheEDelleColonne;
    [Test]
    procedure DovrebbeIgnorareLeCaselleVuote;
  end;

  [TestFixture]
  [Category('MapFile')]
  TTestBspColorShift = class
  public
    [Test]
    procedure NonDovrebbeCambiareIlColoreSenzaSpostamento;
    [Test]
    procedure DovrebbeRaddoppiareSenzaSaturare;
    [Test]
    procedure DovrebbeNormalizzarePerColoreSeSupera255;
    [Test]
    procedure DovrebbeLasciareInalteratoLAlfa;
    [Test]
    procedure DovrebbeSpostareADestraConUnoSpostamentoNegativo;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MapFile.Bsp.ColorShift, DelphiDoom.MapFile.Bsp.Factory,
  DelphiDoom.MapFile.Bsp.LodFixer, DelphiDoom.MapFile.Bsp.PatchLoader, DelphiDoom.MapFile.Bsp.PatchStitcher,
  DelphiDoom.MapFile.Bsp.Types, DelphiDoom.MathCore.Patch.Factory, DelphiDoom.MathCore.Patch.Intf,
  DelphiDoom.MathCore.Patch.Types, DelphiDoom.Tests.MapFile.BspFakeGrid, DelphiDoom.Tests.MapFile.BspSample;

const
  SURFACE_SIZE = 104;

{ TTestBspPatchLoader }

procedure TTestBspPatchLoader.Setup;
var
  LBuilder: TBspSampleBuilder;
begin
  LBuilder := TBspSampleBuilder.Create;
  try
    FBytes := LBuilder.Build(0);
  finally
    LBuilder.Free;
  end;
end;

function TTestBspPatchLoader.Load(const ABytes: TBytes): IBspFile;
begin
  Result := TBspFactory.CreateReader.ParseBytes(ABytes, 'test.bsp');
end;

procedure TTestBspPatchLoader.ExpectLoadError(const ABytes: TBytes; const AMessagePart: string);
var
  LMessage: string;
begin
  LMessage := '';
  try
    TBspFactory.CreatePatchLoader.LoadGrids(Load(ABytes));
  except
    on E: EBspFileException do
      LMessage := E.Message;
  end;
  Assert.IsTrue(Pos(AMessagePart, LMessage) > 0, 'error was "' + LMessage + '"');
end;

procedure TTestBspPatchLoader.DovrebbeDareUnaGrigliaPerOgniPatchCheSiDisegna;
var
  LGrids: TArray<IPatchGrid>;
  LIndex, LCount: Integer;
begin
  LGrids := TBspFactory.CreatePatchLoader.LoadGrids(Load(FBytes));
  Assert.AreEqual<Integer>(8, Length(LGrids));
  LCount := 0;
  for LIndex := 0 to High(LGrids) do
    if Assigned(LGrids[LIndex]) then
      Inc(LCount);
  // five patches, one of them nodraw
  Assert.AreEqual(4, LCount);
  Assert.AreEqual(9, LGrids[3].Width);
  Assert.AreEqual(9, LGrids[3].Height);
end;

procedure TTestBspPatchLoader.DovrebbeDareNilPerLeSuperficiCheNonSonoPatch;
var
  LGrids: TArray<IPatchGrid>;
begin
  LGrids := TBspFactory.CreatePatchLoader.LoadGrids(Load(FBytes));
  Assert.IsFalse(Assigned(LGrids[0]), 'planar');
  Assert.IsFalse(Assigned(LGrids[1]), 'triangle soup');
  Assert.IsFalse(Assigned(LGrids[2]), 'flare');
end;

procedure TTestBspPatchLoader.DovrebbeSaltareUnaPatchConSurfNodraw;
var
  LGrids: TArray<IPatchGrid>;
begin
  LGrids := TBspFactory.CreatePatchLoader.LoadGrids(Load(FBytes));
  Assert.IsFalse(Assigned(LGrids[6]), 'the fourth patch has the nodraw shader');
  Assert.IsTrue(Assigned(LGrids[7]));
end;

procedure TTestBspPatchLoader.DovrebbeDareALeGriglieLOrigineELIlRaggioDelGruppo;
var
  LGrids: TArray<IPatchGrid>;
begin
  LGrids := TBspFactory.CreatePatchLoader.LoadGrids(Load(FBytes));
  // group 0: (0, 0, -128) .. (256, 256, 256): origin (128, 128, 64), radius of the half diagonal
  Assert.AreEqual<Single>(128, LGrids[3].LodOrigin.X);
  Assert.AreEqual<Single>(128, LGrids[3].LodOrigin.Y);
  Assert.AreEqual<Single>(64, LGrids[3].LodOrigin.Z);
  Assert.AreEqual(Double(Sqrt(128.0 * 128 + 128 * 128 + 192 * 192)), Double(LGrids[3].LodRadius), 0.001);
  Assert.AreEqual<Single>(LGrids[3].LodRadius, LGrids[4].LodRadius);
  Assert.AreEqual<Single>(1128, LGrids[7].LodOrigin.X);
  Assert.AreNotEqual<Single>(LGrids[3].LodRadius, 0);
end;

procedure TTestBspPatchLoader.DovrebbeUsareLaSuddivisioneDelCostruttore;
var
  LCoarse, LFine: TArray<IPatchGrid>;
  LFile: IBspFile;
begin
  LFile := Load(FBytes);
  LCoarse := TBspPatchLoader.Create(TPatchFactory.CreateSubdivider(64.0), nil, nil, 1).LoadGrids(LFile);
  LFine := TBspPatchLoader.Create(TPatchFactory.CreateSubdivider(1.0), nil, nil, 1).LoadGrids(LFile);
  Assert.IsTrue(LCoarse[3].Width < LFine[3].Width);
end;

procedure TTestBspPatchLoader.DovrebbeSpostareIColoriDeiVertici;
var
  LFile: IBspFile;
  LNone, LShifted: TArray<IPatchGrid>;
  LCount: Integer;
begin
  LFile := Load(FBytes);
  LNone := TBspPatchLoader.Create(TPatchFactory.CreateSubdivider(4.0), nil, nil, 0).LoadGrids(LFile);
  LShifted := TBspPatchLoader.Create(TPatchFactory.CreateSubdivider(4.0), nil, nil, 1).LoadGrids(LFile);
  // the last vertex of the grid is the last control point, (2, 2): color (0, 135, 171, 68);
  // shifted by one bit (0, 270, 342) it is normalised by the largest channel: g = 270 * 255 / 342
  LCount := LNone[3].Width * LNone[3].Height - 1;
  Assert.AreEqual(135, Integer(LNone[3].Vertices[LCount].Color[1]));
  Assert.AreEqual(171, Integer(LNone[3].Vertices[LCount].Color[2]));
  Assert.AreEqual(201, Integer(LShifted[3].Vertices[LCount].Color[1]));
  Assert.AreEqual(255, Integer(LShifted[3].Vertices[LCount].Color[2]));
  Assert.AreEqual(68, Integer(LShifted[3].Vertices[LCount].Color[3]));
end;

procedure TTestBspPatchLoader.DovrebbeContareLeCucitureEModificareLeGriglie;
var
  LLoader: IBspPatchLoader;
  LGrids, LRaw: TArray<IPatchGrid>;
  LFile: IBspFile;
begin
  LFile := Load(FBytes);
  LLoader := TBspFactory.CreatePatchLoader;
  LGrids := LLoader.LoadGrids(LFile);
  LRaw := TBspPatchLoader.Create(TPatchFactory.CreateSubdivider(4.0), nil, nil, 1).LoadGrids(LFile);
  Assert.AreEqual(4, LLoader.StitchCount);
  // the second patch (5 x 5 before) got four rows from the first (bsp.golden.txt: 5 x 9)
  Assert.AreEqual(5, LRaw[4].Height);
  Assert.AreEqual(9, LGrids[4].Height);
end;

procedure TTestBspPatchLoader.DovrebbeLasciareLeGriglieComeIlCSenzaCucitura;
var
  LLoader: IBspPatchLoader;
  LGrids: TArray<IPatchGrid>;
begin
  LLoader := TBspFactory.CreatePatchLoader(1, 4.0, False);
  LGrids := LLoader.LoadGrids(Load(FBytes));
  Assert.AreEqual(0, LLoader.StitchCount);
  Assert.AreEqual(5, LGrids[4].Height);
end;

procedure TTestBspPatchLoader.DovrebbeRifiutareUnaShaderNumSbagliata;
var
  LBytes: TBytes;
begin
  LBytes := Copy(FBytes);
  BspPatchInt(LBytes, LUMP_SURFACES, 3 * SURFACE_SIZE, 9);
  ExpectLoadError(LBytes, 'bad num 9');
end;

procedure TTestBspPatchLoader.DovrebbeRifiutareUnTipoDiSuperficieSbagliato;
var
  LBytes: TBytes;
begin
  LBytes := Copy(FBytes);
  BspPatchInt(LBytes, LUMP_SURFACES, SURFACE_SIZE + 8, 7);
  ExpectLoadError(LBytes, 'Bad surfaceType');
end;

procedure TTestBspPatchLoader.DovrebbeRifiutareUnaPatchConIVerticiFuoriDalLump;
var
  LBytes: TBytes;
begin
  LBytes := Copy(FBytes);
  BspPatchInt(LBytes, LUMP_SURFACES, 3 * SURFACE_SIZE + 12, 60);
  ExpectLoadError(LBytes, 'needs vertices');
end;

procedure TTestBspPatchLoader.DovrebbeRifiutareUnaPatchConDimensioniPari;
var
  LBytes: TBytes;
begin
  // the original lets the subdivider read points it never set
  LBytes := Copy(FBytes);
  BspPatchInt(LBytes, LUMP_SURFACES, 3 * SURFACE_SIZE + 96, 4);
  ExpectLoadError(LBytes, 'not a valid patch');
end;

procedure TTestBspPatchLoader.DovrebbeDareLeStesseGriglieDueVolte;
var
  LFile: IBspFile;
  LLoader: IBspPatchLoader;
  LFirst, LSecond: TArray<IPatchGrid>;
  LIndex: Integer;
begin
  LFile := Load(FBytes);
  LLoader := TBspFactory.CreatePatchLoader;
  LFirst := LLoader.LoadGrids(LFile);
  LSecond := LLoader.LoadGrids(LFile);
  for LIndex := 0 to High(LFirst) do
    if Assigned(LFirst[LIndex]) then
    begin
      Assert.AreEqual(LFirst[LIndex].Width, LSecond[LIndex].Width);
      Assert.AreEqual(LFirst[LIndex].Height, LSecond[LIndex].Height);
    end;
  Assert.AreEqual(4, LLoader.StitchCount);
end;

{ TTestBspPatchStitcher }

procedure TTestBspPatchStitcher.DovrebbeInserireLaColonnaMancanteDaUnaRigaDelLatoDelSecondo;
var
  LStitcher: IBspPatchStitcher;
  LGrids: TArray<IPatchGrid>;
begin
  // the first grid has the vertices x = 0, 64, 128 on its edge, the second only 0 and 128
  LStitcher := TBspFactory.CreatePatchStitcher;
  SetLength(LGrids, 2);
  LGrids[0] := TFakeGrid.Create([0, 64, 128], [0, 64], [10, 20, 30], [0, 0]);
  LGrids[1] := TFakeGrid.Create([0, 128], [0, 64], [0, 0], [0, 0]);
  Assert.IsTrue(LStitcher.StitchPair(LGrids, 0, 1));
  Assert.AreEqual(3, LGrids[1].Width);
  Assert.AreEqual<Single>(64, LGrids[1].Vertices[1].Position.X);
  Assert.AreEqual<Single>(20, LGrids[1].WidthLodError[1]);
  Assert.AreEqual(3, LGrids[0].Width, 'the first grid is not changed');
  Assert.IsFalse(LStitcher.StitchPair(LGrids, 0, 1), 'nothing more to stitch');
end;

procedure TTestBspPatchStitcher.DovrebbeInserireLaRigaMancanteDaUnaColonna;
var
  LStitcher: IBspPatchStitcher;
  LGrids: TArray<IPatchGrid>;
begin
  LStitcher := TBspFactory.CreatePatchStitcher;
  SetLength(LGrids, 2);
  LGrids[0] := TFakeGrid.Create([0, 64], [0, 64, 128], [0, 0], [5, 6, 7]);
  LGrids[1] := TFakeGrid.Create([0, 64], [0, 128], [0, 0], [0, 0]);
  Assert.IsTrue(LStitcher.StitchPair(LGrids, 0, 1));
  Assert.AreEqual(3, LGrids[1].Height);
  Assert.AreEqual<Single>(64, LGrids[1].Vertices[2].Position.Y);
  Assert.AreEqual<Single>(6, LGrids[1].HeightLodError[1]);
end;

procedure TTestBspPatchStitcher.DovrebbeLeggereLErroreInRangeAllIndiceKPiuUnoCome;
var
  LStitcher: IBspPatchStitcher;
  LGrids: TArray<IPatchGrid>;
begin
  // the third block of R_StitchPatches searches the edge from its end and reads the error
  // at k + 1 for the vertex k - 1 (k = 2 here: index 3, not 1): kept because the C does it
  LStitcher := TBspFactory.CreatePatchStitcher;
  SetLength(LGrids, 2);
  LGrids[0] := TFakeGrid.Create([0, 32, 64, 96, 128], [0, 64], [1, 2, 3, 4, 5], [0, 0]);
  LGrids[1] := TFakeGrid.Create([64, 0], [0, 64], [0, 0], [0, 0]);
  Assert.IsTrue(LStitcher.StitchPair(LGrids, 0, 1));
  Assert.AreEqual(3, LGrids[1].Width);
  Assert.AreEqual<Single>(32, LGrids[1].Vertices[1].Position.X);
  Assert.AreEqual<Single>(4, LGrids[1].WidthLodError[1]);
end;

procedure TTestBspPatchStitcher.DovrebbeLeggereZeroOltreLaTabellaDegliErroriComeFaIlC;
var
  LStitcher: IBspPatchStitcher;
  LGrids: TArray<IPatchGrid>;
begin
  // k = Width - 1: the C reads widthLodError[Width], one past the table: the ZONEID marker of the
  // zone, a denormal float that is 0 for every comparison (a real map of OpenArena does it)
  LStitcher := TBspFactory.CreatePatchStitcher;
  SetLength(LGrids, 2);
  LGrids[0] := TFakeGrid.Create([0, 64, 128], [0, 64], [10, 20, 30], [0, 0]);
  LGrids[1] := TFakeGrid.Create([128, 0], [0, 64], [0, 0], [0, 0]);
  Assert.IsTrue(LStitcher.StitchPair(LGrids, 0, 1));
  Assert.AreEqual<Single>(0, LGrids[1].WidthLodError[1]);
  Assert.AreEqual<Single>(64, LGrids[1].Vertices[1].Position.X);
end;

procedure TTestBspPatchStitcher.NonDovrebbeCucireGriglieDiGruppiDiversi;
var
  LStitcher: IBspPatchStitcher;
  LGrids: TArray<IPatchGrid>;
begin
  LStitcher := TBspFactory.CreatePatchStitcher;
  SetLength(LGrids, 2);
  LGrids[0] := TFakeGrid.Create([0, 64, 128], [0, 64], [10, 20, 30], [0, 0], 10);
  LGrids[1] := TFakeGrid.Create([0, 128], [0, 64], [0, 0], [0, 0], 11);
  Assert.AreEqual(0, LStitcher.StitchAll(LGrids));
  Assert.AreEqual(2, LGrids[1].Width);
end;

procedure TTestBspPatchStitcher.NonDovrebbeCucireSeIlSecondoHaGiaIlVertice;
var
  LStitcher: IBspPatchStitcher;
  LGrids: TArray<IPatchGrid>;
begin
  LStitcher := TBspFactory.CreatePatchStitcher;
  SetLength(LGrids, 2);
  LGrids[0] := TFakeGrid.Create([0, 64, 128], [0, 64], [10, 20, 30], [0, 0]);
  LGrids[1] := TFakeGrid.Create([0, 64, 128], [0, 64], [0, 0, 0], [0, 0]);
  Assert.IsFalse(LStitcher.StitchPair(LGrids, 0, 1));
end;

procedure TTestBspPatchStitcher.NonDovrebbeCucireSeIlSecondoHaGiaILimitiDellaGriglia;
var
  LStitcher: IBspPatchStitcher;
  LGrids: TArray<IPatchGrid>;
  LXs, LErrors: array of Single;
  LIndex: Integer;
begin
  // a second grid with MAX_GRID_SIZE columns cannot get another one
  LStitcher := TBspFactory.CreatePatchStitcher;
  SetLength(LXs, MAX_GRID_SIZE);
  SetLength(LErrors, MAX_GRID_SIZE);
  for LIndex := 0 to MAX_GRID_SIZE - 1 do
  begin
    LXs[LIndex] := LIndex * 2;
    LErrors[LIndex] := 0;
  end;
  SetLength(LGrids, 2);
  LGrids[0] := TFakeGrid.Create([0, 1, 2], [0, 64], [1, 2, 3], [0, 0]);
  LGrids[1] := TFakeGrid.Create(LXs, [0, 64], LErrors, [0, 0]);
  Assert.IsFalse(LStitcher.StitchPair(LGrids, 0, 1));
  Assert.AreEqual(MAX_GRID_SIZE, LGrids[1].Width);
end;

procedure TTestBspPatchStitcher.NonDovrebbeCucireSeIlLatoHaPuntiUniti;
var
  LStitcher: IBspPatchStitcher;
  LGrids: TArray<IPatchGrid>;
begin
  // R_MergedWidthPoints: two inner vertices of the edge of the first grid at the same place
  LStitcher := TBspFactory.CreatePatchStitcher;
  SetLength(LGrids, 2);
  LGrids[0] := TFakeGrid.Create([0, 64, 64, 64, 128], [0, 64], [1, 2, 3, 4, 5], [0, 0]);
  LGrids[1] := TFakeGrid.Create([0, 128], [0, 64], [0, 0], [0, 0]);
  Assert.IsFalse(LStitcher.StitchPair(LGrids, 0, 1));
end;

procedure TTestBspPatchStitcher.DovrebbeIgnorareLeCaselleVuote;
var
  LStitcher: IBspPatchStitcher;
  LGrids: TArray<IPatchGrid>;
begin
  LStitcher := TBspFactory.CreatePatchStitcher;
  SetLength(LGrids, 3);
  LGrids[1] := TFakeGrid.Create([0, 64, 128], [0, 64], [10, 20, 30], [0, 0]);
  Assert.AreEqual(0, LStitcher.StitchAll(LGrids));
  Assert.IsFalse(Assigned(LGrids[0]));
  Assert.IsFalse(Assigned(LGrids[2]));
  SetLength(LGrids, 0);
  Assert.AreEqual(0, LStitcher.StitchAll(LGrids));
end;

procedure TTestBspPatchStitcher.DovrebbeRipetereLaCuciturafinoAlLimite;
var
  LStitcher: IBspPatchStitcher;
  LGrids: TArray<IPatchGrid>;
begin
  // the first grid has 5 vertices on the edge, the second 3 (a vertex is missing at 32 and at
  // 96): StitchAll adds both, one at a time, and a second call finds nothing
  LStitcher := TBspFactory.CreatePatchStitcher;
  SetLength(LGrids, 2);
  LGrids[0] := TFakeGrid.Create([0, 32, 64, 96, 128], [0, 64], [1, 2, 3, 4, 5], [0, 0]);
  LGrids[1] := TFakeGrid.Create([0, 64, 128], [0, 64], [0, 0, 0], [0, 0]);
  Assert.AreEqual(2, LStitcher.StitchAll(LGrids));
  Assert.AreEqual(5, LGrids[1].Width);
  Assert.AreEqual<Single>(2, LGrids[1].WidthLodError[1]);
  Assert.AreEqual<Single>(4, LGrids[1].WidthLodError[3]);
  Assert.AreEqual(0, LStitcher.StitchAll(LGrids));
end;

{ TTestBspLodFixer }

procedure TTestBspLodFixer.DovrebbeDareAlSecondoGliErroriDelPrimoSuiVerticiCondivisi;
var
  LGrids: TArray<IPatchGrid>;
begin
  SetLength(LGrids, 2);
  LGrids[0] := TFakeGrid.Create([0, 32, 64, 96, 128], [0, 64], [0, 7, 8, 9, 0], [0, 0]);
  LGrids[1] := TFakeGrid.Create([0, 32, 64, 96, 128], [0, 64], [0, 1, 1, 1, 0], [0, 0]);
  TBspFactory.CreateLodFixer.Fix(LGrids);
  Assert.AreEqual<Single>(7, LGrids[1].WidthLodError[1]);
  Assert.AreEqual<Single>(8, LGrids[1].WidthLodError[2]);
  Assert.AreEqual<Single>(9, LGrids[1].WidthLodError[3]);
  Assert.AreEqual<Single>(0, LGrids[1].WidthLodError[0], 'the corners are not touched');
  Assert.AreEqual<Single>(7, LGrids[0].WidthLodError[1], 'the first one is not changed');
end;

procedure TTestBspLodFixer.DovrebbeLasciareStareLeGriglieDiUnAltroGruppo;
var
  LGrids: TArray<IPatchGrid>;
begin
  SetLength(LGrids, 2);
  LGrids[0] := TFakeGrid.Create([0, 32, 64, 96, 128], [0, 64], [0, 7, 8, 9, 0], [0, 0], 10);
  LGrids[1] := TFakeGrid.Create([0, 32, 64, 96, 128], [0, 64], [0, 1, 1, 1, 0], [0, 0], 20);
  TBspFactory.CreateLodFixer.Fix(LGrids);
  Assert.AreEqual<Single>(1, LGrids[1].WidthLodError[2]);
end;

procedure TTestBspLodFixer.DovrebbePropagareAttraversoLeGriglieCheSiToccano;
var
  LGrids: TArray<IPatchGrid>;
begin
  // 0 touches 1, 1 touches 2 but 0 does not touch 2: the grid 1 is fixed by the first step, so
  // the outer loop skips it and only the recursion reaches the grid 2
  SetLength(LGrids, 3);
  LGrids[0] := TFakeGrid.Create([0, 32, 64], [0, 64], [0, 7, 0], [0, 0]);
  LGrids[1] := TFakeGrid.Create([0, 32, 64, 96, 128], [0, 64], [0, 1, 1, 5, 0], [0, 0]);
  LGrids[2] := TFakeGrid.Create([64, 96, 128], [0, 64], [0, 1, 0], [0, 0]);
  TBspFactory.CreateLodFixer.Fix(LGrids);
  Assert.AreEqual<Single>(7, LGrids[1].WidthLodError[1]);
  Assert.AreEqual<Single>(5, LGrids[2].WidthLodError[1]);
end;

procedure TTestBspLodFixer.DovrebbeFissareGliErroriDelleRigheEDelleColonne;
var
  LGrids: TArray<IPatchGrid>;
begin
  // the first grid has a column x = 32 with the inner vertex (32, 32) and the second a row
  // y = 32 with the same inner vertex: the error of the row of the first goes to the column
  // of the second
  SetLength(LGrids, 2);
  LGrids[0] := TFakeGrid.Create([32, 96], [0, 32, 64], [0, 0], [0, 6, 0]);
  LGrids[1] := TFakeGrid.Create([0, 32, 64], [32, 64], [0, 1, 0], [0, 0]);
  TBspFactory.CreateLodFixer.Fix(LGrids);
  Assert.AreEqual<Single>(6, LGrids[1].WidthLodError[1]);
end;

procedure TTestBspLodFixer.DovrebbeIgnorareLeCaselleVuote;
var
  LGrids: TArray<IPatchGrid>;
begin
  SetLength(LGrids, 3);
  LGrids[1] := TFakeGrid.Create([0, 32, 64], [0, 64], [0, 1, 0], [0, 0]);
  TBspFactory.CreateLodFixer.Fix(LGrids);
  Assert.IsFalse(Assigned(LGrids[0]));
  Assert.AreEqual<Single>(1, LGrids[1].WidthLodError[1]);
end;

{ TTestBspColorShift }

procedure TTestBspColorShift.NonDovrebbeCambiareIlColoreSenzaSpostamento;
var
  LIn, LOut: TBspColor;
begin
  LIn[0] := 200;
  LIn[1] := 100;
  LIn[2] := 7;
  LIn[3] := 33;
  TBspColorShift.Apply(0, LIn, LOut);
  Assert.AreEqual(200, Integer(LOut[0]));
  Assert.AreEqual(100, Integer(LOut[1]));
  Assert.AreEqual(7, Integer(LOut[2]));
  Assert.AreEqual(33, Integer(LOut[3]));
end;

procedure TTestBspColorShift.DovrebbeRaddoppiareSenzaSaturare;
var
  LIn, LOut: TBspColor;
begin
  LIn[0] := 100;
  LIn[1] := 50;
  LIn[2] := 1;
  LIn[3] := 0;
  TBspColorShift.Apply(1, LIn, LOut);
  Assert.AreEqual(200, Integer(LOut[0]));
  Assert.AreEqual(100, Integer(LOut[1]));
  Assert.AreEqual(2, Integer(LOut[2]));
end;

procedure TTestBspColorShift.DovrebbeNormalizzarePerColoreSeSupera255;
var
  LIn, LOut: TBspColor;
begin
  // (400, 200, 20) * 255 / 400: the hue is kept, as the original does instead of clamping
  LIn[0] := 200;
  LIn[1] := 100;
  LIn[2] := 10;
  LIn[3] := 0;
  TBspColorShift.Apply(1, LIn, LOut);
  Assert.AreEqual(255, Integer(LOut[0]));
  Assert.AreEqual(127, Integer(LOut[1]));
  Assert.AreEqual(12, Integer(LOut[2]));
end;

procedure TTestBspColorShift.DovrebbeLasciareInalteratoLAlfa;
var
  LIn, LOut: TBspColor;
begin
  LIn[0] := 255;
  LIn[1] := 255;
  LIn[2] := 255;
  LIn[3] := 77;
  TBspColorShift.Apply(2, LIn, LOut);
  Assert.AreEqual(77, Integer(LOut[3]));
  Assert.AreEqual(255, Integer(LOut[0]));
end;

procedure TTestBspColorShift.DovrebbeSpostareADestraConUnoSpostamentoNegativo;
var
  LIn, LOut: TBspColor;
begin
  // undefined in C: a right shift here
  LIn[0] := 200;
  LIn[1] := 100;
  LIn[2] := 3;
  LIn[3] := 0;
  TBspColorShift.Apply(-1, LIn, LOut);
  Assert.AreEqual(100, Integer(LOut[0]));
  Assert.AreEqual(50, Integer(LOut[1]));
  Assert.AreEqual(1, Integer(LOut[2]));
end;

end.
