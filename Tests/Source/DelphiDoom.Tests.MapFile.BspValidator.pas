{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - references of a BSP             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.BspValidator;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MapFile.Bsp.Intf;

type
  [TestFixture]
  [Category('MapFile')]
  TTestBspValidator = class
  strict private
    FBytes: TBytes;
    function Issues(const ABytes: TBytes): TArray<string>;
    function Broken(const ALump, AOffset, AValue: Integer): TArray<string>;
    procedure ExpectIssue(const AIssues: TArray<string>; const APart: string);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeNonTrovareProblemiNeiCampioni;
    [Test]
    procedure DovrebbeTrovareUnPianoDiUnNodoFuoriDalLump;
    [Test]
    procedure DovrebbeTrovareUnFiglioDiUnNodoFuoriDalLump;
    [Test]
    procedure DovrebbeTrovareUnaFogliaFiglioFuoriDalLump;
    [Test]
    procedure DovrebbeTrovareUnIntervalloDiUnaFogliaFuoriDalLump;
    [Test]
    procedure DovrebbeTrovareUnClusterFuoriDalleRighe;
    [Test]
    procedure DovrebbeTrovareUnaSuperficieDiUnaFogliaCheNonEsiste;
    [Test]
    procedure DovrebbeTrovareUnIntervalloDiUnModelloFuoriDalLump;
    [Test]
    procedure DovrebbeTrovareUnaShaderNumSbagliataInUnBrush;
    [Test]
    procedure DovrebbeTrovareUnPianoDiUnLatoCheNonEsiste;
    [Test]
    procedure DovrebbeTrovareUnBrushDiUnaNebbiaCheNonEsiste;
    [Test]
    procedure DovrebbeTrovareUnLatoVisibileCheNonEDelBrush;
    [Test]
    procedure DovrebbeTrovareUnaShaderNumSbagliataInUnaSuperficie;
    [Test]
    procedure DovrebbeTrovareUnTipoDiSuperficieSbagliato;
    [Test]
    procedure DovrebbeTrovareUnaPatchConDimensioniPari;
    [Test]
    procedure DovrebbeTrovareUnaPatchCheHaPiuPuntiDeiVertici;
    [Test]
    procedure DovrebbeTrovareUnIndiceFuoriDalleSuperficiPiane;
    [Test]
    procedure DovrebbeTrovareIndiciCheNonSonoTriangoli;
    [Test]
    procedure DovrebbeTrovareLeRigheDiVisibilitaTroppoCorte;
    [Test]
    procedure DovrebbeDireTuttiIProblemiNonSoloIlPrimo;
  end;

implementation

uses
  DelphiDoom.MapFile.Bsp.Factory, DelphiDoom.MapFile.Bsp.Types, DelphiDoom.Tests.MapFile.BspSample;

const
  SURFACE_SIZE = 104;
  LEAF_SIZE = 48;
  PLANAR_SURFACE = 0;
  PATCH_SURFACE = 3;

procedure TTestBspValidator.Setup;
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

function TTestBspValidator.Issues(const ABytes: TBytes): TArray<string>;
begin
  Result := TBspFactory.CreateValidator.Validate(TBspFactory.CreateReader.ParseBytes(ABytes, 'test.bsp'));
end;

function TTestBspValidator.Broken(const ALump, AOffset, AValue: Integer): TArray<string>;
var
  LBytes: TBytes;
begin
  LBytes := Copy(FBytes);
  BspPatchInt(LBytes, ALump, AOffset, AValue);
  Result := Issues(LBytes);
end;

procedure TTestBspValidator.ExpectIssue(const AIssues: TArray<string>; const APart: string);
var
  LIssue: string;
begin
  for LIssue in AIssues do
    if Pos(APart, LIssue) > 0 then
      Exit;
  Assert.Fail('no issue with "' + APart + '" among ' + IntToStr(Length(AIssues)));
end;

procedure TTestBspValidator.DovrebbeNonTrovareProblemiNeiCampioni;
var
  LBuilder: TBspSampleBuilder;
  LVariant: Integer;
begin
  LBuilder := TBspSampleBuilder.Create;
  try
    for LVariant := 0 to 2 do
      Assert.AreEqual<Integer>(0, Length(Issues(LBuilder.Build(LVariant))), 'variant ' + IntToStr(LVariant));
  finally
    LBuilder.Free;
  end;
end;

procedure TTestBspValidator.DovrebbeTrovareUnPianoDiUnNodoFuoriDalLump;
begin
  ExpectIssue(Broken(LUMP_NODES, 0, 8), 'node 0: plane 8');
  ExpectIssue(Broken(LUMP_NODES, 0, -1), 'node 0: plane -1');
end;

procedure TTestBspValidator.DovrebbeTrovareUnFiglioDiUnNodoFuoriDalLump;
begin
  ExpectIssue(Broken(LUMP_NODES, 4, 1), 'node 0: child 1 is outside the 1 nodes');
end;

procedure TTestBspValidator.DovrebbeTrovareUnaFogliaFiglioFuoriDalLump;
begin
  ExpectIssue(Broken(LUMP_NODES, 8, -3), 'node 0: child -3 is the leaf 2');
end;

procedure TTestBspValidator.DovrebbeTrovareUnIntervalloDiUnaFogliaFuoriDalLump;
begin
  ExpectIssue(Broken(LUMP_LEAFS, 36, 99), 'leaf 0');
  ExpectIssue(Broken(LUMP_LEAFS, 44, 99), 'leaf 0');
  ExpectIssue(Broken(LUMP_LEAFS, 32, -1), 'leaf 0');
end;

procedure TTestBspValidator.DovrebbeTrovareUnClusterFuoriDalleRighe;
begin
  ExpectIssue(Broken(LUMP_LEAFS, LEAF_SIZE, 5), 'leaf 1: cluster 5');
end;

procedure TTestBspValidator.DovrebbeTrovareUnaSuperficieDiUnaFogliaCheNonEsiste;
begin
  ExpectIssue(Broken(LUMP_LEAFSURFACES, 4, 40), 'leafsurface 1: surface 40');
  ExpectIssue(Broken(LUMP_LEAFBRUSHES, 0, 3), 'leafbrush 0: brush 3');
end;

procedure TTestBspValidator.DovrebbeTrovareUnIntervalloDiUnModelloFuoriDalLump;
begin
  ExpectIssue(Broken(LUMP_MODELS, 28, 9), 'model 0');
  ExpectIssue(Broken(LUMP_MODELS, 36, 2), 'model 0');
end;

procedure TTestBspValidator.DovrebbeTrovareUnaShaderNumSbagliataInUnBrush;
begin
  ExpectIssue(Broken(LUMP_BRUSHES, 8, 7), 'brush 0: bad shaderNum: 7');
  ExpectIssue(Broken(LUMP_BRUSHES, 4, 20), 'brush 0');
  ExpectIssue(Broken(LUMP_BRUSHSIDES, 4, -2), 'brushside 0: bad shaderNum: -2');
end;

procedure TTestBspValidator.DovrebbeTrovareUnPianoDiUnLatoCheNonEsiste;
begin
  ExpectIssue(Broken(LUMP_BRUSHSIDES, 8, 8), 'brushside 1: plane 8');
end;

procedure TTestBspValidator.DovrebbeTrovareUnBrushDiUnaNebbiaCheNonEsiste;
begin
  ExpectIssue(Broken(LUMP_FOGS, 64, 4), 'fog 0: brush 4');
end;

procedure TTestBspValidator.DovrebbeTrovareUnLatoVisibileCheNonEDelBrush;
begin
  ExpectIssue(Broken(LUMP_FOGS, 68, 6), 'fog 0: visible side 6');
  Assert.AreEqual<Integer>(0, Length(Broken(LUMP_FOGS, 68, 5)));
end;

procedure TTestBspValidator.DovrebbeTrovareUnaShaderNumSbagliataInUnaSuperficie;
begin
  ExpectIssue(Broken(LUMP_SURFACES, PLANAR_SURFACE * SURFACE_SIZE, 9), 'surface 0: bad shaderNum: 9');
  ExpectIssue(Broken(LUMP_SURFACES, PLANAR_SURFACE * SURFACE_SIZE + 4, 2), 'surface 0: fog 2');
end;

procedure TTestBspValidator.DovrebbeTrovareUnTipoDiSuperficieSbagliato;
begin
  ExpectIssue(Broken(LUMP_SURFACES, PLANAR_SURFACE * SURFACE_SIZE + 8, 9), 'surface 0: bad surfaceType 9');
  ExpectIssue(Broken(LUMP_SURFACES, PLANAR_SURFACE * SURFACE_SIZE + 8, 0), 'surface 0: bad surfaceType 0');
end;

procedure TTestBspValidator.DovrebbeTrovareUnaPatchConDimensioniPari;
begin
  ExpectIssue(Broken(LUMP_SURFACES, PATCH_SURFACE * SURFACE_SIZE + 96, 4), 'surface 3: patch size 4x3');
  ExpectIssue(Broken(LUMP_SURFACES, PATCH_SURFACE * SURFACE_SIZE + 100, 33), 'surface 3: patch size 3x33');
end;

procedure TTestBspValidator.DovrebbeTrovareUnaPatchCheHaPiuPuntiDeiVertici;
begin
  ExpectIssue(Broken(LUMP_SURFACES, PATCH_SURFACE * SURFACE_SIZE + 96, 5), 'surface 3: patch 5x3 needs more');
end;

procedure TTestBspValidator.DovrebbeTrovareUnIndiceFuoriDalleSuperficiPiane;
begin
  ExpectIssue(Broken(LUMP_DRAWINDEXES, 8, 4), 'surface 0: bad index 4');
  ExpectIssue(Broken(LUMP_DRAWINDEXES, 8, -1), 'bad index -1');
  ExpectIssue(Broken(LUMP_SURFACES, PLANAR_SURFACE * SURFACE_SIZE + 20, 4), 'surface 0');
end;

procedure TTestBspValidator.DovrebbeTrovareIndiciCheNonSonoTriangoli;
begin
  ExpectIssue(Broken(LUMP_SURFACES, PLANAR_SURFACE * SURFACE_SIZE + 24, 5), 'surface 0: 5 indexes are not whole');
end;

procedure TTestBspValidator.DovrebbeTrovareLeRigheDiVisibilitaTroppoCorte;
begin
  ExpectIssue(Broken(LUMP_VISIBILITY, 4, 100), 'visibility: 2 clusters of 100 bytes');
  ExpectIssue(Broken(LUMP_VISIBILITY, 0, -1), 'visibility');
end;

procedure TTestBspValidator.DovrebbeDireTuttiIProblemiNonSoloIlPrimo;
var
  LBytes: TBytes;
  LIssues: TArray<string>;
begin
  LBytes := Copy(FBytes);
  BspPatchInt(LBytes, LUMP_NODES, 0, 99);
  BspPatchInt(LBytes, LUMP_BRUSHES, 8, 99);
  BspPatchInt(LBytes, LUMP_FOGS, 64, 99);
  LIssues := Issues(LBytes);
  Assert.AreEqual<Integer>(3, Length(LIssues));
end;

end.
