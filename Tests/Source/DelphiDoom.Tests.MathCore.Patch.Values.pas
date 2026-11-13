{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - patches of Quake III Arena:    }
{  values computed by hand, errors and limits                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Patch.Values;

{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Patch.Intf,
  DelphiDoom.MathCore.Patch.Types;

type
  [TestFixture]
  [Category('mathcore')]
  TTestPatchValues = class(TObject)
  private
    class function MakePoints(const AWidth, AHeight: Integer; const AA, AB: Single): TArray<TPatchVertex>; static;
    class function MakeVertex(const AX, AY, AZ: Single): TPatchVertex; static;
  public
    [Test]
    procedure TPatchVertexDovrebbeAvereLeStesseDimensioniDelC;
    [Test]
    procedure UnaPatchPianaDovrebbeDareUnaGrigliaDiQuattroVerticiConLaNormaleSuZ;
    [Test]
    procedure UnaPatchPianaDovrebbeAvereBoundsOrigineERaggio;
    [Test]
    procedure UnErroreMassimoGrandeDovrebbeLasciareLaPatchSenzaSuddivisione;
    [Test]
    procedure UnErroreMassimoPiuPiccoloDovrebbeDareUnaGrigliaPiuFitta;
    [Test]
    procedure IlLodErrorDiUnaColonnaNonSuddivisaDovrebbeEssereIlReciprocoDellErrore;
    [Test]
    procedure UnaPatchBombataDovrebbeAvereLeNormaliUnitarie;
    [Test]
    procedure IlPuntoCentraleDiUnaPatchBombataDovrebbeEssereSullaCurva;
    [Test]
    procedure LeDimensioniNonValideDovrebberoSollevareUnaEccezione;
    [Test]
    procedure TroppiPochiPuntiDovrebberoSollevareUnaEccezione;
    [Test]
    procedure IlSuddivisoreDovrebbeRicordareLErroreMassimo;
    [Test]
    procedure LaFabbricaDovrebbeDareOggettiUtilizzabili;
    [Test]
    procedure LerpDovrebbeFareLaMediaDiPosizioniEDimezzareIColori;
    [Test]
    procedure NormalizeDovrebbeLasciareUnVettoreNulloEDareLunghezzaZero;
    [Test]
    procedure Normalize2DovrebbeDareIlVettoreUnitario;
    [Test]
    procedure IlProdottoVettorialeDovrebbeDareLAsseOrtogonale;
    [Test]
    procedure LaMesaDiLavoroDovrebbeRifiutareLeCelleFuoriDalRange;
    [Test]
    procedure UnaColonnaInseritaDovrebbeAggiungereUnaColonnaEMantenereIlLod;
    [Test]
    procedure UnaRigaInseritaDovrebbeAggiungereUnaRigaEIlPuntoDato;
    [Test]
    procedure InserireAiBordiDovrebbeSollevareUnaEccezione;
    [Test]
    procedure UnaGrigliaPienaDovrebbeDareNilAllInserimento;
    [Test]
    procedure IlLodDellaGrigliaDovrebbeEssereModificabile;
  end;

implementation

uses
  System.SysUtils, System.Math, DelphiDoom.MathCore.Patch.ControlMesh,
  DelphiDoom.MathCore.Patch.Factory, DelphiDoom.MathCore.Patch.Subdivider,
  DelphiDoom.MathCore.Patch.VertexMath;

procedure Near(const AExpected, AActual, ATolerance: Single);
begin
  Assert.AreEqual(Double(AExpected), Double(AActual), Double(ATolerance));
end;

class function TTestPatchValues.MakeVertex(const AX, AY, AZ: Single): TPatchVertex;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Position.SetValues(AX, AY, AZ);
end;

class function TTestPatchValues.MakePoints(const AWidth, AHeight: Integer; const AA, AB: Single): TArray<TPatchVertex>;
var
  LI, LJ: Integer;
  LZ: Single;
begin
  SetLength(Result, AWidth * AHeight);
  for LJ := 0 to AHeight - 1 do
    for LI := 0 to AWidth - 1 do
    begin
      LZ := 0;
      if LI mod 2 = 1 then
        LZ := LZ + AA;
      if LJ mod 2 = 1 then
        LZ := LZ + AB;
      Result[LJ * AWidth + LI] := MakeVertex(LI * 64, LJ * 64, LZ);
      Result[LJ * AWidth + LI].TexCoord.SetValues(LI / (AWidth - 1), LJ / (AHeight - 1));
    end;
end;

procedure TTestPatchValues.TPatchVertexDovrebbeAvereLeStesseDimensioniDelC;
begin
  Assert.AreEqual<Integer>(44, SizeOf(TPatchVertex));
end;

procedure TTestPatchValues.UnaPatchPianaDovrebbeDareUnaGrigliaDiQuattroVerticiConLaNormaleSuZ;
var
  LGrid: IPatchGrid;
  LIndex: Integer;
begin
  LGrid := TPatchFactory.CreateSubdivider.SubdividePatchToGrid(3, 3, MakePoints(3, 3, 0, 0));
  Assert.AreEqual<Integer>(2, LGrid.Width);
  Assert.AreEqual<Integer>(2, LGrid.Height);
  for LIndex := 0 to 3 do
  begin
    Near(1.0, LGrid.Vertices[LIndex].Normal.Z, 0.0001);
    Near(0.0, LGrid.Vertices[LIndex].Normal.X, 0.0001);
  end;
  Near(128.0, LGrid.Vertices[3].Position.X, 0.0001);
  Near(128.0, LGrid.Vertices[3].Position.Y, 0.0001);
  // the two culled lines leave no error behind
  Near(0.0, LGrid.WidthLodError[1], 0.0);
end;

procedure TTestPatchValues.UnaPatchPianaDovrebbeAvereBoundsOrigineERaggio;
var
  LGrid: IPatchGrid;
begin
  LGrid := TPatchFactory.CreateSubdivider.SubdividePatchToGrid(3, 3, MakePoints(3, 3, 0, 0));
  Near(0.0, LGrid.BoundsMin.X, 0.0);
  Near(128.0, LGrid.BoundsMax.Y, 0.0);
  Near(64.0, LGrid.LocalOrigin.X, 0.0);
  // half of the diagonal of a 128 x 128 square
  Near(Sqrt(64.0 * 64.0 * 2), LGrid.MeshRadius, 0.001);
  Near(LGrid.MeshRadius, LGrid.LodRadius, 0.0);
  Near(64.0, LGrid.LodOrigin.Y, 0.0);
end;

procedure TTestPatchValues.UnErroreMassimoGrandeDovrebbeLasciareLaPatchSenzaSuddivisione;
var
  LGrid: IPatchGrid;
begin
  LGrid := TPatchFactory.CreateSubdivider(1000).SubdividePatchToGrid(3, 3, MakePoints(3, 3, 96, 48));
  Assert.AreEqual<Integer>(3, LGrid.Width);
  Assert.AreEqual<Integer>(3, LGrid.Height);
end;

procedure TTestPatchValues.UnErroreMassimoPiuPiccoloDovrebbeDareUnaGrigliaPiuFitta;
var
  LCoarse, LMedium, LFine: IPatchGrid;
  LPoints: TArray<TPatchVertex>;
begin
  LPoints := MakePoints(3, 3, 96, 48);
  LCoarse := TPatchFactory.CreateSubdivider(16).SubdividePatchToGrid(3, 3, LPoints);
  LMedium := TPatchFactory.CreateSubdivider(4).SubdividePatchToGrid(3, 3, LPoints);
  LFine := TPatchFactory.CreateSubdivider(1).SubdividePatchToGrid(3, 3, LPoints);
  Assert.IsTrue(LCoarse.Width < LMedium.Width);
  Assert.IsTrue(LMedium.Width < LFine.Width);
  Assert.IsTrue(LFine.Width <= MAX_GRID_SIZE);
end;

procedure TTestPatchValues.IlLodErrorDiUnaColonnaNonSuddivisaDovrebbeEssereIlReciprocoDellErrore;
var
  LGrid: IPatchGrid;
  LPoints: TArray<TPatchVertex>;
  LMiddle: Single;
begin
  // a 3x3 patch with the bulge only in the columns: the middle column curves by
  // (0 + 2 * 96 + 0) / 4 = 48 above the line between the outer ones
  LPoints := MakePoints(3, 3, 96, 0);
  LGrid := TPatchFactory.CreateSubdivider(1000).SubdividePatchToGrid(3, 3, LPoints);
  LMiddle := LGrid.WidthLodError[1];
  Near(1 / 48, LMiddle, 0.0001);
end;

procedure TTestPatchValues.UnaPatchBombataDovrebbeAvereLeNormaliUnitarie;
var
  LGrid: IPatchGrid;
  LIndex: Integer;
begin
  LGrid := TPatchFactory.CreateSubdivider.SubdividePatchToGrid(3, 3, MakePoints(3, 3, 96, 48));
  for LIndex := 0 to LGrid.Width * LGrid.Height - 1 do
    Near(1.0, TPatchVertexMath.Length(LGrid.Vertices[LIndex].Normal), 0.0001);
end;

procedure TTestPatchValues.IlPuntoCentraleDiUnaPatchBombataDovrebbeEssereSullaCurva;
var
  LGrid: IPatchGrid;
  LCenter: TPatchVertex;
begin
  // the centre of the patch is the biquadratic curve at t = 1/2: x = 64, y = 64 and
  // z = (a * 2 + b * 2 + ...) with the weights 1/4, 1/2, 1/4 on each axis
  LGrid := TPatchFactory.CreateSubdivider(1000).SubdividePatchToGrid(3, 3, MakePoints(3, 3, 96, 48));
  LCenter := LGrid.Vertices[4];
  Near(64.0, LCenter.Position.X, 0.0001);
  Near(64.0, LCenter.Position.Y, 0.0001);
  // z of the control points: (1,*) = 96, (*,1) = 48, (1,1) = 144; the corners are 0
  // 1/4 * (1/4 * 0 + 1/2 * 96 + 1/4 * 0) + 1/2 * (1/4 * 48 + 1/2 * 144 + 1/4 * 48)
  //   + 1/4 * (...0 + 96/2 + 0) = 12 + 48 + 12 = 72
  Near(72.0, LCenter.Position.Z, 0.0001);
end;

procedure TTestPatchValues.LeDimensioniNonValideDovrebberoSollevareUnaEccezione;
var
  LSubdivider: IPatchSubdivider;
  LPoints: TArray<TPatchVertex>;
begin
  LSubdivider := TPatchFactory.CreateSubdivider;
  SetLength(LPoints, 100 * 100);
  Assert.WillRaise(procedure begin LSubdivider.SubdividePatchToGrid(2, 3, LPoints); end, EPatchException);
  Assert.WillRaise(procedure begin LSubdivider.SubdividePatchToGrid(3, 4, LPoints); end, EPatchException);
  Assert.WillRaise(procedure begin LSubdivider.SubdividePatchToGrid(33, 3, LPoints); end, EPatchException);
  Assert.WillRaise(procedure begin LSubdivider.SubdividePatchToGrid(3, 35, LPoints); end, EPatchException);
end;

procedure TTestPatchValues.TroppiPochiPuntiDovrebberoSollevareUnaEccezione;
var
  LSubdivider: IPatchSubdivider;
  LPoints: TArray<TPatchVertex>;
begin
  LSubdivider := TPatchFactory.CreateSubdivider;
  SetLength(LPoints, 8);
  Assert.WillRaise(procedure begin LSubdivider.SubdividePatchToGrid(3, 3, LPoints); end, EPatchException);
end;

procedure TTestPatchValues.IlSuddivisoreDovrebbeRicordareLErroreMassimo;
begin
  Near(2.5, (TPatchFactory.CreateSubdivider(2.5) as TPatchSubdivider).Subdivisions, 0.0);
  Near(DEFAULT_PATCH_SUBDIVISIONS,
    (TPatchFactory.CreateSubdivider as TPatchSubdivider).Subdivisions, 0.0);
end;

procedure TTestPatchValues.LaFabbricaDovrebbeDareOggettiUtilizzabili;
begin
  Assert.IsNotNull(TPatchFactory.CreateSubdivider);
  Assert.IsNotNull(TPatchFactory.CreateGridEditor);
end;

procedure TTestPatchValues.LerpDovrebbeFareLaMediaDiPosizioniEDimezzareIColori;
var
  LA, LB, LResult: TPatchVertex;
begin
  LA := MakeVertex(0, 10, -4);
  LB := MakeVertex(8, 20, 4);
  LA.TexCoord.SetValues(0, 1);
  LB.TexCoord.SetValues(1, 1);
  LA.Lightmap.SetValues(0.5, 0);
  LB.Lightmap.SetValues(1.5, 1);
  LA.Color[0] := 255;
  LB.Color[0] := 1;
  LA.Color[3] := 7;
  LB.Color[3] := 2;
  LResult := TPatchVertexMath.Lerp(LA, LB);
  Near(4, LResult.Position.X, 0.0);
  Near(15, LResult.Position.Y, 0.0);
  Near(0, LResult.Position.Z, 0.0);
  Near(0.5, LResult.TexCoord.X, 0.0);
  Near(1.0, LResult.Lightmap.X, 0.0);
  Near(0.5, LResult.Lightmap.Y, 0.0);
  Assert.AreEqual<Integer>(128, LResult.Color[0]);
  Assert.AreEqual<Integer>(4, LResult.Color[3]);
end;

procedure TTestPatchValues.NormalizeDovrebbeLasciareUnVettoreNulloEDareLunghezzaZero;
var
  LVector: TIdVec3;
begin
  LVector.Zero;
  Near(0, TPatchVertexMath.Normalize(LVector), 0.0);
  Near(0, LVector.X, 0.0);
  LVector.SetValues(3, 0, 4);
  Near(5, TPatchVertexMath.Normalize(LVector), 0.0);
  Near(0.6, LVector.X, 0.00001);
  Near(0.8, LVector.Z, 0.00001);
end;

procedure TTestPatchValues.Normalize2DovrebbeDareIlVettoreUnitario;
var
  LVector, LOut: TIdVec3;
begin
  LVector.SetValues(0, -2, 0);
  LOut.SetValues(9, 9, 9);
  Near(2, TPatchVertexMath.Normalize2(LVector, LOut), 0.0);
  Near(-1, LOut.Y, 0.0);
  Near(2, -LVector.Y, 0.0);
  LVector.Zero;
  Near(0, TPatchVertexMath.Normalize2(LVector, LOut), 0.0);
  Near(0, LOut.X, 0.0);
end;

procedure TTestPatchValues.IlProdottoVettorialeDovrebbeDareLAsseOrtogonale;
var
  LX, LY, LZ: TIdVec3;
begin
  LX.SetValues(1, 0, 0);
  LY.SetValues(0, 1, 0);
  LZ := TPatchVertexMath.Cross(LX, LY);
  Near(1, LZ.Z, 0.0);
  Near(0, LZ.X, 0.0);
  Near(0, TPatchVertexMath.Dot(LX, LY), 0.0);
  Near(1, TPatchVertexMath.LengthSquared(LZ), 0.0);
end;

procedure TTestPatchValues.LaMesaDiLavoroDovrebbeRifiutareLeCelleFuoriDalRange;
var
  LMesh: TPatchControlMesh;
  LVertex: TPatchVertex;
begin
  LMesh := TPatchControlMesh.Create;
  try
    LVertex := MakeVertex(1, 2, 3);
    LMesh[MAX_GRID_SIZE - 1, 0] := LVertex;
    Near(1, LMesh[MAX_GRID_SIZE - 1, 0].Position.X, 0.0);
    Assert.WillRaise(procedure begin LMesh[MAX_GRID_SIZE, 0] := LVertex; end, EPatchException);
    Assert.WillRaise(procedure begin LMesh[0, -1] := LVertex; end, EPatchException);
    Assert.WillRaise(procedure begin LVertex := LMesh[0, MAX_GRID_SIZE]; end, EPatchException);
    Assert.WillRaise(procedure begin LVertex := LMesh[-1, 0]; end, EPatchException);
  finally
    LMesh.Free;
  end;
end;

procedure TTestPatchValues.UnaColonnaInseritaDovrebbeAggiungereUnaColonnaEMantenereIlLod;
var
  LGrid, LNew: IPatchGrid;
  LOrigin: TIdVec3;
begin
  LGrid := TPatchFactory.CreateSubdivider(4).SubdividePatchToGrid(3, 3, MakePoints(3, 3, 96, 48));
  LGrid.LodRadius := 77;
  LOrigin.SetValues(1, 2, 3);
  LGrid.LodOrigin := LOrigin;
  LNew := TPatchFactory.CreateGridEditor.InsertColumn(LGrid, 2, 1, TIdVec3.Create(5, 6, 7), 0.5);
  Assert.AreEqual<Integer>(LGrid.Width + 1, LNew.Width);
  Assert.AreEqual<Integer>(LGrid.Height, LNew.Height);
  Near(0.5, LNew.WidthLodError[2], 0.0);
  Near(5, LNew.Vertices[1 * LNew.Width + 2].Position.X, 0.0);
  Near(77, LNew.LodRadius, 0.0);
  Near(2, LNew.LodOrigin.Y, 0.0);
  Near(LGrid.WidthLodError[2], LNew.WidthLodError[3], 0.0);
end;

procedure TTestPatchValues.UnaRigaInseritaDovrebbeAggiungereUnaRigaEIlPuntoDato;
var
  LGrid, LNew: IPatchGrid;
begin
  LGrid := TPatchFactory.CreateSubdivider(4).SubdividePatchToGrid(3, 3, MakePoints(3, 3, 96, 48));
  LNew := TPatchFactory.CreateGridEditor.InsertRow(LGrid, 3, 4, TIdVec3.Create(-5, -6, -7), 0.25);
  Assert.AreEqual<Integer>(LGrid.Height + 1, LNew.Height);
  Near(0.25, LNew.HeightLodError[3], 0.0);
  Near(-6, LNew.Vertices[3 * LNew.Width + 4].Position.Y, 0.0);
end;

procedure TTestPatchValues.InserireAiBordiDovrebbeSollevareUnaEccezione;
var
  LGrid: IPatchGrid;
  LEditor: IPatchGridEditor;
begin
  LGrid := TPatchFactory.CreateSubdivider(4).SubdividePatchToGrid(3, 3, MakePoints(3, 3, 96, 48));
  LEditor := TPatchFactory.CreateGridEditor;
  Assert.WillRaise(procedure begin LEditor.InsertColumn(LGrid, 0, 1, TIdVec3.Create(0, 0, 0), 1); end,
    EPatchException);
  Assert.WillRaise(procedure begin LEditor.InsertColumn(LGrid, LGrid.Width, 1, TIdVec3.Create(0, 0, 0), 1); end,
    EPatchException);
  Assert.WillRaise(procedure begin LEditor.InsertRow(LGrid, 0, 1, TIdVec3.Create(0, 0, 0), 1); end,
    EPatchException);
  Assert.WillRaise(procedure begin LEditor.InsertRow(LGrid, LGrid.Height, 1, TIdVec3.Create(0, 0, 0), 1); end,
    EPatchException);
end;

procedure TTestPatchValues.UnaGrigliaPienaDovrebbeDareNilAllInserimento;
var
  LPoints: TArray<TPatchVertex>;
  LGrid: IPatchGrid;
  LEditor: IPatchGridEditor;
begin
  // a very bumpy 31x31 patch at an error of 1 unit fills the grid to 65 x 65
  LPoints := MakePoints(31, 31, 4000, -3000);
  LGrid := TPatchFactory.CreateSubdivider(1).SubdividePatchToGrid(31, 31, LPoints);
  Assert.AreEqual<Integer>(MAX_GRID_SIZE, LGrid.Width);
  Assert.AreEqual<Integer>(MAX_GRID_SIZE, LGrid.Height);
  LEditor := TPatchFactory.CreateGridEditor;
  Assert.IsNull(LEditor.InsertColumn(LGrid, 2, 1, TIdVec3.Create(0, 0, 0), 1));
  Assert.IsNull(LEditor.InsertRow(LGrid, 2, 1, TIdVec3.Create(0, 0, 0), 1));
end;

procedure TTestPatchValues.IlLodDellaGrigliaDovrebbeEssereModificabile;
var
  LGrid: IPatchGrid;
begin
  LGrid := TPatchFactory.CreateSubdivider.SubdividePatchToGrid(3, 3, MakePoints(3, 3, 96, 48));
  LGrid.LodRadius := 12.5;
  Near(12.5, LGrid.LodRadius, 0.0);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPatchValues);

end.
