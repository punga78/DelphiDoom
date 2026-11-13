{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the matrices of MathCore - values worked out by hand,  }
{  identities and limit cases                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Matrix.Values;

{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('mathcore')]
  TTestMatrixValues = class(TObject)
  public
    [Test]
    procedure IRecordDovrebberoAvereLeDimensioniDelCpp;
    [Test]
    procedure UnaMatriceMoltiplicataPerLaSuaInversaDovrebbeDareLIdentita;
    [Test]
    procedure UnaMatriceSingolareNonDovrebbeEssereInvertita;
    [Test]
    procedure TIdMat6DovrebbeSeparareECompossareIBlocchi;
    [Test]
    procedure TIdMat4DovrebbeDividerePerLaCoordinataOmogenea;
    [Test]
    procedure TIdVec5LerpDovrebbeLimitareIlParametro;
    [Test]
    procedure TIdVec6DovrebbeNormalizzare;
    [Test]
    procedure TIdPolar3DovrebbeConvertireInCoordinateCartesiane;
    [Test]
    procedure TIdVecXDovrebbeCopiareECalcolare;
    [Test]
    procedure TIdVecXSuMemoriaEsternaNonDovrebbeRidimensionarsi;
    [Test]
    procedure TIdMatXDovrebbeCalcolareDeterminanteEInversaOltreLaDimensioneSei;
    [Test]
    procedure TIdMatXLuDovrebbeRisolvereUnSistema;
    [Test]
    procedure TIdMatXDovrebbeCambiareDimensioneConservandoIValori;
    [Test]
    procedure TIdMatXCholeskyELdltDovrebberoRisolvereUnSistemaSimmetrico;
    [Test]
    procedure IlRiordinoDiUnaFattorizzazioneDovrebbeDareLaMatriceAggiornata;
    [Test]
    procedure TIdMatXEigenDovrebbeTrovareGliAutovalori;
    [Test]
    procedure TIdMatXKernelsDotDovrebbeSommareComeUnCicloSemplice;
    [Test]
    procedure TIdLcpDovrebbeRisolvereUnSistemaSenzaLimiti;
    [Test]
    procedure TIdLcpDovrebbeFermareUnaVariabileAlSuoLimite;
    [Test]
    procedure TIdLcpDovrebbeRiportareLaMatriceComeEra;
    [Test]
    procedure TIdLcpDovrebbeUsareLIndiceDellaScatola;
    [Test]
    procedure TIdPlaneFitDovrebbeAdattareUnPianoAiPunti;
    [Test]
    procedure TIdBoxFitDovrebbeAdattareUnaScatolaAiPunti;
  end;

implementation

uses
  System.Math, System.SysUtils, DelphiDoom.Geometry.Box, DelphiDoom.Geometry.Plane,
  DelphiDoom.Geometry.Vec3, DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Math.Vec4, DelphiDoom.MathCore.Float.BoxFit, DelphiDoom.MathCore.Float.Lcp.Factory,
  DelphiDoom.MathCore.Float.Lcp.Intf, DelphiDoom.MathCore.Float.Mat2, DelphiDoom.MathCore.Float.Mat3,
  DelphiDoom.MathCore.Float.Mat4, DelphiDoom.MathCore.Float.Mat5, DelphiDoom.MathCore.Float.Mat6,
  DelphiDoom.MathCore.Float.MatX, DelphiDoom.MathCore.Float.MatX.Cholesky,
  DelphiDoom.MathCore.Float.MatX.Eigen, DelphiDoom.MathCore.Float.MatX.Kernels,
  DelphiDoom.MathCore.Float.MatX.Ldlt, DelphiDoom.MathCore.Float.PlaneFit,
  DelphiDoom.MathCore.Float.Polar3, DelphiDoom.MathCore.Float.Types, DelphiDoom.MathCore.Float.Vec5,
  DelphiDoom.MathCore.Float.Vec6, DelphiDoom.MathCore.Float.VecX;

procedure CheckNear(const AExpected, AActual, ATolerance: Double; const AMessage: string = '');
begin
  Assert.IsTrue(System.Abs(AExpected - AActual) <= ATolerance,
    Format('%s: atteso %g, ottenuto %g', [AMessage, AExpected, AActual]));
end;

function ResidualOfIdentity(const AProduct: Pointer; const ASize: Integer): Single;
var
  LRow, LColumn: Integer;
  LExpected: Single;
begin
  Result := 0.0;
  for LRow := 0 to ASize - 1 do
  begin
    for LColumn := 0 to ASize - 1 do
    begin
      LExpected := Ord(LRow = LColumn);
      Result := System.Math.Max(Result, System.Abs(PIdSingleArray(AProduct)^[LRow * ASize + LColumn] -
        LExpected));
    end;
  end;
end;

procedure FillWellConditioned(const AMatrix: TIdMatX; const ASize: Integer);
var
  LRow, LColumn: Integer;
begin
  AMatrix.SetSize(ASize, ASize);
  for LRow := 0 to ASize - 1 do
  begin
    for LColumn := 0 to ASize - 1 do
    begin
      AMatrix[LRow, LColumn] := Sin(LRow * 3.0 + LColumn * 1.7 + 0.3) + 4.0 * Ord(LRow = LColumn);
    end;
  end;
end;

procedure TTestMatrixValues.IRecordDovrebberoAvereLeDimensioniDelCpp;
begin
  Assert.AreEqual(16, SizeOf(TIdMat2), 'idMat2');
  Assert.AreEqual(64, SizeOf(TIdMat4), 'idMat4');
  Assert.AreEqual(100, SizeOf(TIdMat5), 'idMat5');
  Assert.AreEqual(144, SizeOf(TIdMat6), 'idMat6');
  Assert.AreEqual(20, SizeOf(TIdVec5), 'idVec5');
  Assert.AreEqual(24, SizeOf(TIdVec6), 'idVec6');
  Assert.AreEqual(12, SizeOf(TIdPolar3), 'idPolar3');
end;

procedure TTestMatrixValues.UnaMatriceMoltiplicataPerLaSuaInversaDovrebbeDareLIdentita;
var
  LMat2, LInverse2: TIdMat2;
  LMat4, LInverse4, LProduct4: TIdMat4;
  LMat5, LInverse5, LProduct5: TIdMat5;
  LMat6, LInverse6, LProduct6: TIdMat6;
  LRow, LColumn: Integer;
  LProduct2: TIdMat2;
begin
  LMat2 := TIdMat2.Create(4.0, 1.0, 2.0, 3.0);
  LInverse2 := LMat2.Inverse;
  LProduct2 := LMat2 * LInverse2;
  Assert.IsTrue(LProduct2.IsIdentity(1E-5), 'idMat2');
  for LRow := 0 to 3 do
  begin
    for LColumn := 0 to 3 do
    begin
      LMat4.Rows[LRow][LColumn] := Sin(LRow * 3.0 + LColumn * 1.7) + 4.0 * Ord(LRow = LColumn);
    end;
  end;
  LInverse4 := LMat4.Inverse;
  LProduct4 := LMat4 * LInverse4;
  Assert.IsTrue(LProduct4.IsIdentity(1E-5), 'idMat4');
  LInverse4 := LMat4.InverseFast;
  LProduct4 := LMat4 * LInverse4;
  Assert.IsTrue(LProduct4.IsIdentity(1E-5), 'idMat4 fast');
  for LRow := 0 to 4 do
  begin
    for LColumn := 0 to 4 do
    begin
      LMat5.Rows[LRow][LColumn] := Sin(LRow * 3.0 + LColumn * 1.7) + 4.0 * Ord(LRow = LColumn);
    end;
  end;
  LInverse5 := LMat5.Inverse;
  LProduct5 := LMat5 * LInverse5;
  Assert.IsTrue(LProduct5.IsIdentity(1E-5), 'idMat5');
  LInverse5 := LMat5.InverseFast;
  LProduct5 := LMat5 * LInverse5;
  Assert.IsTrue(LProduct5.IsIdentity(1E-5), 'idMat5 fast');
  for LRow := 0 to 5 do
  begin
    for LColumn := 0 to 5 do
    begin
      LMat6.Rows[LRow][LColumn] := Sin(LRow * 3.0 + LColumn * 1.7) + 4.0 * Ord(LRow = LColumn);
    end;
  end;
  LInverse6 := LMat6.Inverse;
  LProduct6 := LMat6 * LInverse6;
  Assert.IsTrue(LProduct6.IsIdentity(1E-5), 'idMat6');
  LInverse6 := LMat6.InverseFast;
  LProduct6 := LMat6 * LInverse6;
  Assert.IsTrue(LProduct6.IsIdentity(1E-5), 'idMat6 fast');
  CheckNear(8.0, TIdMat2.Create(2.0, 0.0, 0.0, 4.0).Determinant, 0.0);
end;

procedure TTestMatrixValues.UnaMatriceSingolareNonDovrebbeEssereInvertita;
var
  LMat4: TIdMat4;
  LMat2: TIdMat2;
begin
  LMat2 := TIdMat2.Create(1.0, 2.0, 2.0, 4.0);
  Assert.IsFalse(LMat2.InverseSelf, 'idMat2');
  CheckNear(1.0, LMat2.Rows[0].X, 0.0, 'la matrice resta com''era');
  LMat4 := TIdMat4.Identity;
  LMat4.Rows[1].Zero;
  Assert.IsFalse(LMat4.InverseSelf, 'idMat4');
  Assert.IsFalse(LMat4.InverseFastSelf, 'idMat4 fast');
end;

procedure TTestMatrixValues.TIdMat6DovrebbeSeparareECompossareIBlocchi;
var
  LBlocks: array[0..3] of TIdMat3;
  LMat6: TIdMat6;
  LIndex, LRow, LColumn: Integer;
  LBlock: TIdMat3;
begin
  for LIndex := 0 to 3 do
  begin
    for LRow := 0 to 2 do
    begin
      for LColumn := 0 to 2 do
      begin
        LBlocks[LIndex].Rows[LRow][LColumn] := LIndex * 100 + LRow * 10 + LColumn;
      end;
    end;
  end;
  LMat6 := TIdMat6.Create(LBlocks[0], LBlocks[1], LBlocks[2], LBlocks[3]);
  CheckNear(112.0, LMat6.Rows[1][3 + 2], 0.0, 'riga 1 colonna 5: blocco 1');
  CheckNear(321.0, LMat6.Rows[5][5 - 1], 0.0, 'riga 5 colonna 4: blocco 3');
  for LIndex := 0 to 3 do
  begin
    LBlock := LMat6.SubMat3(LIndex);
    Assert.IsTrue(LBlock = LBlocks[LIndex], 'blocco ' + IntToStr(LIndex));
  end;
end;

procedure TTestMatrixValues.TIdMat4DovrebbeDividerePerLaCoordinataOmogenea;
var
  LMatrix: TIdMat4;
  LResult: TIdVec3;
begin
  LMatrix := TIdMat4.Identity;
  LMatrix.Rows[3].SetValues(0.0, 0.0, 0.0, 2.0);
  LResult := LMatrix * TIdVec3.Create(4.0, 6.0, 8.0);
  CheckNear(2.0, LResult.X, 0.0);
  CheckNear(3.0, LResult.Y, 0.0);
  CheckNear(4.0, LResult.Z, 0.0);
  LMatrix.Rows[3].SetValues(0.0, 0.0, 0.0, 0.0);
  LResult := LMatrix * TIdVec3.Create(4.0, 6.0, 8.0);
  CheckNear(0.0, LResult.X, 0.0, 'w = 0 dà il vettore nullo');
  LResult := TIdMat4.Create(TIdMat3.Identity, TIdVec3.Create(1.0, 2.0, 3.0)) * TIdVec3.Create(1.0, 1.0, 1.0);
  CheckNear(2.0, LResult.X, 0.0, 'la traslazione si somma con w = 1');
end;

procedure TTestMatrixValues.TIdVec5LerpDovrebbeLimitareIlParametro;
var
  LA, LB, LResult: TIdVec5;
begin
  LA := TIdVec5.Create(0.0, 0.0, 0.0, 0.0, 0.0);
  LB := TIdVec5.Create(2.0, 4.0, 6.0, 8.0, 10.0);
  LResult.Lerp(LA, LB, 0.5);
  CheckNear(4.0, LResult.S, 0.0);
  LResult.Lerp(LA, LB, -3.0);
  CheckNear(0.0, LResult.T, 0.0, 'sotto zero: il primo');
  LResult.Lerp(LA, LB, 7.0);
  CheckNear(10.0, LResult.T, 0.0, 'sopra uno: il secondo');
  CheckNear(6.0, TIdVec5.FromVec3(TIdVec3.Create(1.0, 2.0, 3.0)).X + 5.0, 0.0);
  CheckNear(0.0, TIdVec5.FromVec3(TIdVec3.Create(1.0, 2.0, 3.0)).T, 0.0);
end;

procedure TTestMatrixValues.TIdVec6DovrebbeNormalizzare;
var
  LVector: TIdVec6;
  LLength: Single;
begin
  LVector := TIdVec6.Create(3.0, 4.0, 0.0, 0.0, 0.0, 0.0);
  LLength := LVector.Normalize;
  CheckNear(5.0, LLength, 1E-3);
  CheckNear(0.6, LVector.P[0], 1E-3);
  CheckNear(1.0, LVector.Length, 1E-3);
  CheckNear(25.0, TIdVec6.Create(3.0, 4.0, 0.0, 0.0, 0.0, 0.0).LengthSqr, 0.0);
  CheckNear(2.0, TIdVec6.Create(2.0, 0.0, 0.0, 0.0, 0.0, 0.0).GetSubVec3(0).X, 0.0);
end;

procedure TTestMatrixValues.TIdPolar3DovrebbeConvertireInCoordinateCartesiane;
var
  LVector: TIdVec3;
begin
  LVector := TIdPolar3.Create(2.0, 0.0, 0.0).ToVec3;
  CheckNear(2.0, LVector.X, 1E-5);
  CheckNear(0.0, LVector.Z, 1E-5);
  LVector := TIdPolar3.Create(3.0, 0.0, ID_HALF_PI).ToVec3;
  CheckNear(3.0, LVector.Z, 1E-5, 'phi = 90 gradi punta in alto');
  LVector := TIdPolar3.Create(1.0, 0.25, 0.5).ToVec3;
  CheckNear(1.0, LVector.Length, 1E-5);
end;

procedure TTestMatrixValues.TIdVecXDovrebbeCopiareECalcolare;
var
  LA, LB, LSum: TIdVecX;
begin
  LA := TIdVecX.Create(5);
  LB := TIdVecX.Create(5);
  try
    LA.Random(1, -1.0, 1.0);
    LB.Assign(LA);
    Assert.IsTrue(LA.Compare(LB), 'copia uguale');
    LSum := LA.Add(LB);
    try
      CheckNear(LA[2] * 2.0, LSum[2], 0.0);
    finally
      LSum.Free;
    end;
    LB.Negate;
    Assert.IsFalse(LA.Compare(LB), 'opposto diverso');
    LA.Zero;
    CheckNear(0.0, LA.Length, 0.0);
    LA.ChangeSize(8, True);
    Assert.AreEqual(8, LA.Size);
    CheckNear(0.0, LA[7], 0.0);
  finally
    LB.Free;
    LA.Free;
  end;
end;

procedure TTestMatrixValues.TIdVecXSuMemoriaEsternaNonDovrebbeRidimensionarsi;
var
  LMemory: array[0..7] of Single;
  LVector: TIdVecX;
begin
  LMemory[0] := 1.0;
  LMemory[1] := 2.0;
  LVector := TIdVecX.Create(2, PIdSingleArray(@LMemory[0]));
  try
    LVector[1] := 9.0;
    CheckNear(9.0, LMemory[1], 0.0, 'scrive nella memoria del chiamante');
    LVector.SetSize(4);
    LVector[3] := 5.0;
    CheckNear(5.0, LMemory[3], 0.0, 'la memoria esterna non viene mai riallocata');
  finally
    LVector.Free;
  end;
end;

procedure TTestMatrixValues.TIdMatXDovrebbeCalcolareDeterminanteEInversaOltreLaDimensioneSei;
var
  LMatrix, LInverse, LProduct: TIdMatX;
  LSize: Integer;
begin
  for LSize := 1 to 9 do
  begin
    LMatrix := TIdMatX.Create;
    try
      FillWellConditioned(LMatrix, LSize);
      LInverse := LMatrix.Inverse;
      try
        LProduct := LMatrix.Multiply(LInverse);
        try
          Assert.IsTrue(ResidualOfIdentity(LProduct.Data, LSize) < 1E-4, 'dimensione ' + IntToStr(LSize));
        finally
          LProduct.Free;
        end;
      finally
        LInverse.Free;
      end;
    finally
      LMatrix.Free;
    end;
  end;
  LMatrix := TIdMatX.Create(7, 7);
  try
    LMatrix.Identity;
    LMatrix[0, 0] := 3.0;
    LMatrix[6, 6] := 2.0;
    CheckNear(6.0, LMatrix.Determinant, 1E-5, 'determinante generico per LU');
    LMatrix.Zero;
    Assert.IsFalse(LMatrix.InverseSelf, 'matrice nulla');
  finally
    LMatrix.Free;
  end;
end;

procedure TTestMatrixValues.TIdMatXLuDovrebbeRisolvereUnSistema;
var
  LMatrix, LFactored: TIdMatX;
  LB, LX, LCheck: TIdVecX;
  LIndex: TArray<Integer>;
  LRow: Integer;
begin
  LMatrix := TIdMatX.Create;
  LFactored := TIdMatX.Create;
  LB := TIdVecX.Create(6);
  LX := TIdVecX.Create(6);
  try
    FillWellConditioned(LMatrix, 6);
    for LRow := 0 to 5 do
    begin
      LB[LRow] := LRow + 1.0;
    end;
    LFactored.Assign(LMatrix);
    SetLength(LIndex, 6);
    Assert.IsTrue(LFactored.LuFactor(PIdIntegerArray(LIndex), nil));
    LFactored.LuSolve(LX, LB, PIdIntegerArray(LIndex));
    LCheck := LMatrix.Multiply(LX);
    try
      Assert.IsTrue(LCheck.Compare(LB, 1E-4), 'A x = b');
    finally
      LCheck.Free;
    end;
  finally
    LX.Free;
    LB.Free;
    LFactored.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixValues.TIdMatXDovrebbeCambiareDimensioneConservandoIValori;
var
  LMatrix: TIdMatX;
begin
  LMatrix := TIdMatX.Create(2, 2);
  try
    LMatrix[0, 0] := 1.0;
    LMatrix[0, 1] := 2.0;
    LMatrix[1, 0] := 3.0;
    LMatrix[1, 1] := 4.0;
    LMatrix.ChangeSize(3, 4, True);
    CheckNear(3.0, LMatrix[1, 0], 0.0);
    CheckNear(4.0, LMatrix[1, 1], 0.0);
    CheckNear(0.0, LMatrix[2, 3], 0.0, 'i valori nuovi sono zero');
    LMatrix.ChangeSize(2, 2, False);
    CheckNear(4.0, LMatrix[1, 1], 0.0);
    LMatrix.RemoveRowColumn(0);
    Assert.AreEqual(1, LMatrix.NumRows);
    CheckNear(4.0, LMatrix[0, 0], 0.0, 'resta l''elemento (1,1)');
  finally
    LMatrix.Free;
  end;
end;

procedure TTestMatrixValues.TIdMatXCholeskyELdltDovrebberoRisolvereUnSistemaSimmetrico;
var
  LMatrix, LCholesky, LLdlt: TIdMatX;
  LB, LX1, LX2: TIdVecX;
begin
  LMatrix := TIdMatX.Create(3, 3);
  LCholesky := TIdMatX.Create;
  LLdlt := TIdMatX.Create;
  LB := TIdVecX.Create(3);
  LX1 := TIdVecX.Create(3);
  LX2 := TIdVecX.Create(3);
  try
    LMatrix[0, 0] := 4.0;
    LMatrix[0, 1] := 1.0;
    LMatrix[0, 2] := 0.0;
    LMatrix[1, 0] := 1.0;
    LMatrix[1, 1] := 3.0;
    LMatrix[1, 2] := 1.0;
    LMatrix[2, 0] := 0.0;
    LMatrix[2, 1] := 1.0;
    LMatrix[2, 2] := 2.0;
    LB[0] := 1.0;
    LB[1] := 2.0;
    LB[2] := 3.0;
    LCholesky.Assign(LMatrix);
    LLdlt.Assign(LMatrix);
    Assert.IsTrue(TIdMatXCholesky.Factor(LCholesky));
    Assert.IsTrue(TIdMatXLdlt.Factor(LLdlt));
    TIdMatXCholesky.Solve(LCholesky, LX1, LB);
    TIdMatXLdlt.Solve(LLdlt, LX2, LB);
    Assert.IsTrue(LX1.Compare(LX2, 1E-5), 'la stessa soluzione');
    CheckNear(1.0, 4.0 * LX1[0] + LX1[1] - LB[0] + 1.0, 1E-5);
    LMatrix[1, 1] := -1.0;
    Assert.IsFalse(TIdMatXCholesky.IsSymmetricPositiveDefinite(LMatrix), 'non definita positiva');
  finally
    LX2.Free;
    LX1.Free;
    LB.Free;
    LLdlt.Free;
    LCholesky.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixValues.IlRiordinoDiUnaFattorizzazioneDovrebbeDareLaMatriceAggiornata;
var
  LMatrix, LFactored, LBack, LProduct: TIdMatX;
  LVector: TIdVecX;
begin
  LMatrix := TIdMatX.Create;
  LFactored := TIdMatX.Create;
  LBack := TIdMatX.Create;
  LVector := TIdVecX.Create(4);
  try
    FillWellConditioned(LMatrix, 4);
    // a symmetric positive definite matrix
    LProduct := LMatrix.TransposeMultiply(LMatrix);
    try
      LMatrix.Assign(LProduct);
    finally
      LProduct.Free;
    end;
    LVector[0] := 0.3;
    LVector[1] := -0.2;
    LVector[2] := 0.1;
    LVector[3] := 0.4;
    LFactored.Assign(LMatrix);
    Assert.IsTrue(TIdMatXLdlt.Factor(LFactored));
    Assert.IsTrue(TIdMatXLdlt.UpdateRankOne(LFactored, LVector, 0.5, 0));
    LMatrix.UpdateRankOneSymmetric(LVector, 0.5);
    TIdMatXLdlt.MultiplyFactors(LFactored, LBack);
    // the upper triangle of the factors is not cleared, so only the lower one is compared
    LBack.ClearUpperTriangle;
    LMatrix.ClearUpperTriangle;
    Assert.IsTrue(LBack.Compare(LMatrix, 1E-3), 'LDL'' aggiornato = A + alpha v v''');
  finally
    LVector.Free;
    LBack.Free;
    LFactored.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixValues.TIdMatXEigenDovrebbeTrovareGliAutovalori;
var
  LMatrix, LProduct: TIdMatX;
  LValues: TIdVecX;
begin
  LMatrix := TIdMatX.Create(3, 3);
  LValues := TIdVecX.Create;
  try
    LMatrix.Zero;
    LMatrix[0, 0] := 5.0;
    LMatrix[1, 1] := 2.0;
    LMatrix[2, 2] := 3.0;
    Assert.IsTrue(TIdMatXEigen.SolveSymmetric(LMatrix, LValues));
    TIdMatXEigen.SortIncreasing(LMatrix, LValues);
    CheckNear(2.0, LValues[0], 1E-5);
    CheckNear(3.0, LValues[1], 1E-5);
    CheckNear(5.0, LValues[2], 1E-5);
    LProduct := LMatrix.TransposeMultiply(LMatrix);
    try
      Assert.IsTrue(ResidualOfIdentity(LProduct.Data, 3) < 1E-5, 'gli autovettori sono ortonormali');
    finally
      LProduct.Free;
    end;
    LMatrix.Zero;
    LMatrix[0, 0] := 2.0;
    LMatrix[0, 1] := 1.0;
    LMatrix[1, 0] := 1.0;
    LMatrix[1, 1] := 2.0;
    LMatrix[2, 2] := 1.0;
    Assert.IsTrue(TIdMatXEigen.SolveSymmetric(LMatrix, LValues));
    TIdMatXEigen.SortDecreasing(LMatrix, LValues);
    CheckNear(3.0, LValues[0], 1E-4);
    CheckNear(1.0, LValues[1], 1E-4);
  finally
    LValues.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixValues.TIdMatXKernelsDotDovrebbeSommareComeUnCicloSemplice;
var
  LA, LB: array[0..39] of Single;
  LIndex, LCount: Integer;
  LSum: Double;
begin
  for LIndex := 0 to 39 do
  begin
    LA[LIndex] := LIndex * 0.25 + 1.0;
    LB[LIndex] := 2.0 - LIndex * 0.125;
  end;
  for LCount := 0 to 40 do
  begin
    LSum := 0.0;
    for LIndex := 0 to LCount - 1 do
    begin
      LSum := LSum + LA[LIndex] * LB[LIndex];
    end;
    CheckNear(LSum, TIdMatXKernels.Dot(PIdSingleArray(@LA[0]), PIdSingleArray(@LB[0]),
      LCount), 1E-3, 'elementi: ' + IntToStr(LCount));
  end;
end;

procedure TTestMatrixValues.TIdLcpDovrebbeRisolvereUnSistemaSenzaLimiti;
var
  LMatrix: TIdMatX;
  LX, LB, LLow, LHigh, LCheck: TIdVecX;
  LSolver: IIdLcp;
  LIndex: Integer;
  LSymmetric: Boolean;
begin
  for LSymmetric := False to True do
  begin
    LMatrix := TIdMatX.Create(2, 2);
    LX := TIdVecX.Create(2);
    LB := TIdVecX.Create(2);
    LLow := TIdVecX.Create(2);
    LHigh := TIdVecX.Create(2);
    try
      LMatrix[0, 0] := 4.0;
      LMatrix[0, 1] := 1.0;
      LMatrix[1, 0] := 1.0;
      LMatrix[1, 1] := 3.0;
      LB[0] := 1.0;
      LB[1] := 2.0;
      for LIndex := 0 to 1 do
      begin
        LLow[LIndex] := -ID_INFINITY;
        LHigh[LIndex] := ID_INFINITY;
      end;
      if LSymmetric then
        LSolver := TIdLcpFactory.AllocSymmetric
      else
        LSolver := TIdLcpFactory.AllocSquare;
      Assert.AreEqual(32, LSolver.GetMaxIterations, 'iterazioni di default');
      Assert.IsTrue(LSolver.Solve(LMatrix, LX, LB, LLow, LHigh, nil));
      LCheck := LMatrix.Multiply(LX);
      try
        Assert.IsTrue(LCheck.Compare(LB, 1E-5), 'A x = b senza limiti');
      finally
        LCheck.Free;
      end;
    finally
      LHigh.Free;
      LLow.Free;
      LB.Free;
      LX.Free;
      LMatrix.Free;
    end;
  end;
end;

procedure TTestMatrixValues.TIdLcpDovrebbeFermareUnaVariabileAlSuoLimite;
var
  LMatrix: TIdMatX;
  LX, LB, LLow, LHigh: TIdVecX;
  LSolver: IIdLcp;
begin
  LMatrix := TIdMatX.Create(2, 2);
  LX := TIdVecX.Create(2);
  LB := TIdVecX.Create(2);
  LLow := TIdVecX.Create(2);
  LHigh := TIdVecX.Create(2);
  try
    LMatrix.Identity;
    LB[0] := -2.0;
    LB[1] := 3.0;
    LLow[0] := 0.0;
    LLow[1] := 0.0;
    LHigh[0] := ID_INFINITY;
    LHigh[1] := 1.0;
    LSolver := TIdLcpFactory.AllocSymmetric;
    Assert.IsTrue(LSolver.Solve(LMatrix, LX, LB, LLow, LHigh, nil));
    CheckNear(0.0, LX[0], 1E-6, 'x0 vorrebbe -2: resta a zero');
    CheckNear(1.0, LX[1], 1E-6, 'x1 vorrebbe 3: resta a uno');
  finally
    LHigh.Free;
    LLow.Free;
    LB.Free;
    LX.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixValues.TIdLcpDovrebbeRiportareLaMatriceComeEra;
var
  LMatrix, LBefore, LProduct: TIdMatX;
  LX, LB, LLow, LHigh: TIdVecX;
  LSolver: IIdLcp;
  LIndex: Integer;
begin
  LMatrix := TIdMatX.Create;
  LBefore := TIdMatX.Create;
  LX := TIdVecX.Create(5);
  LB := TIdVecX.Create(5);
  LLow := TIdVecX.Create(5);
  LHigh := TIdVecX.Create(5);
  try
    FillWellConditioned(LMatrix, 5);
    LProduct := LMatrix.TransposeMultiply(LMatrix);
    try
      LMatrix.Assign(LProduct);
    finally
      LProduct.Free;
    end;
    LBefore.Assign(LMatrix);
    for LIndex := 0 to 4 do
    begin
      LB[LIndex] := Cos(LIndex * 2.0) * 3.0;
      if LIndex mod 2 = 0 then
        LLow[LIndex] := 0.0
      else
        LLow[LIndex] := -ID_INFINITY;
      LHigh[LIndex] := ID_INFINITY;
    end;
    LSolver := TIdLcpFactory.AllocSymmetric;
    Assert.IsTrue(LSolver.Solve(LMatrix, LX, LB, LLow, LHigh, nil));
    Assert.IsTrue(LMatrix.Compare(LBefore), 'le colonne permutate sono rimesse a posto');
    for LIndex := 0 to 4 do
    begin
      if LIndex mod 2 = 0 then
        Assert.IsTrue(LX[LIndex] >= 0.0, 'rispetta il limite inferiore');
    end;
  finally
    LHigh.Free;
    LLow.Free;
    LB.Free;
    LX.Free;
    LBefore.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixValues.TIdLcpDovrebbeUsareLIndiceDellaScatola;
var
  LMatrix: TIdMatX;
  LX, LB, LLow, LHigh: TIdVecX;
  LSolver: IIdLcp;
begin
  LMatrix := TIdMatX.Create(2, 2);
  LX := TIdVecX.Create(2);
  LB := TIdVecX.Create(2);
  LLow := TIdVecX.Create(2);
  LHigh := TIdVecX.Create(2);
  try
    LMatrix.Identity;
    // x0 is unbounded and gets 3; x1 would get 5 but is limited to |0.5 * x0| = 1.5
    LB[0] := 3.0;
    LB[1] := 5.0;
    LLow[0] := -ID_INFINITY;
    LHigh[0] := ID_INFINITY;
    LLow[1] := 0.5;
    LHigh[1] := 0.5;
    LSolver := TIdLcpFactory.AllocSquare;
    Assert.IsTrue(LSolver.Solve(LMatrix, LX, LB, LLow, LHigh, [-1, 0]));
    CheckNear(3.0, LX[0], 1E-5);
    CheckNear(1.5, LX[1], 1E-5);
  finally
    LHigh.Free;
    LLow.Free;
    LB.Free;
    LX.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixValues.TIdPlaneFitDovrebbeAdattareUnPianoAiPunti;
var
  LPlane: TGeoPlane;
  LPoints: array[0..3] of TGeoVec3;
begin
  // the plane z = 0.5 x + 2 through four points
  LPoints[0] := TGeoVec3.Make(0.0, 0.0, 2.0);
  LPoints[1] := TGeoVec3.Make(2.0, 0.0, 3.0);
  LPoints[2] := TGeoVec3.Make(0.0, 2.0, 2.0);
  LPoints[3] := TGeoVec3.Make(2.0, 2.0, 3.0);
  Assert.IsTrue(TIdPlaneFit.HeightFit(LPlane, LPoints));
  CheckNear(0.0, LPlane.Distance(LPoints[0]), 1E-4);
  CheckNear(0.0, LPlane.Distance(LPoints[3]), 1E-4);
  CheckNear(1.0, LPlane.Normal.Length, 1E-4);
  Assert.IsTrue(TIdPlaneFit.HeightFit(LPlane, [LPoints[0]]), 'un solo punto');
  CheckNear(-2.0, LPlane.D, 0.0);
  Assert.IsTrue(TIdPlaneFit.HeightFit(LPlane, [LPoints[0], LPoints[1]]), 'due punti');
  CheckNear(0.0, LPlane.Distance(LPoints[1]), 1E-4);
  // points on a vertical line: the system is singular
  Assert.IsFalse(TIdPlaneFit.HeightFit(LPlane, [TGeoVec3.Make(1.0, 1.0, 0.0),
    TGeoVec3.Make(1.0, 1.0, 1.0), TGeoVec3.Make(1.0, 1.0, 2.0)]));
end;

procedure TTestMatrixValues.TIdBoxFitDovrebbeAdattareUnaScatolaAiPunti;
var
  LBox: TGeoBox;
  LPoints: array[0..7] of TGeoVec3;
  LIndex: Integer;
  LLimit: Single;
begin
  // the corners of a box of half sizes 4, 2 and 1 centered at (1, 2, 3)
  for LIndex := 0 to 7 do
  begin
    LPoints[LIndex] := TGeoVec3.Make(1.0 + 4.0 * (((LIndex shr 0) and 1) * 2 - 1),
      2.0 + 2.0 * (((LIndex shr 1) and 1) * 2 - 1), 3.0 + 1.0 * (((LIndex shr 2) and 1) * 2 - 1));
  end;
  Assert.IsTrue(TIdBoxFit.FromPoints(LBox, LPoints));
  CheckNear(1.0, LBox.Center.X, 1E-3);
  CheckNear(2.0, LBox.Center.Y, 1E-3);
  CheckNear(3.0, LBox.Center.Z, 1E-3);
  // every point is inside the box: |axis * (point - center)| <= extents (rows of the axis are the projection axes)
  for LIndex := 0 to 7 do
  begin
    LLimit := LBox.Extents.X + 1E-3;
    Assert.IsTrue(System.Abs(LBox.Axis.Rows[0].Dot(LPoints[LIndex] - LBox.Center)) <= LLimit + 1E-2, 'proiezione X');
  end;
  CheckNear(7.0, LBox.Extents.X + LBox.Extents.Y + LBox.Extents.Z, 1E-2, 'somma delle semi dimensioni');
end;

end.
