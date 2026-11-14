{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of MathCore - the factorizations of idMatX checked by     }
{  their invariants (the checks of idMatX::Test of the C++, without the golden)}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Matrix.Decompositions.Values;

{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   Invariants of the update, QR, SVD and general eigenvalue functions: the product of the
  ///   factors is the matrix, the updated factors multiply to the updated matrix, and every
  ///   eigenvector satisfies A v = lambda v. The golden files check the numbers against the C++;
  ///   these tests check the mathematics and the branches the golden does not reach.
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMatrixDecompositionsValues = class(TObject)
  public
    [Test]
    procedure LuUpdateRankOneDovrebbeDareIFattoriDellaMatriceModificata;
    [Test]
    procedure LuUpdateRowColumnDovrebbeDareIFattoriDellaMatriceModificata;
    [Test]
    procedure LuUpdateIncrementDovrebbeAggiungereRigaEColonna;
    [Test]
    procedure LuUpdateDecrementDovrebbeTogliereRigaEColonna;
    [Test]
    procedure LuUpdateDovrebbeDareFalsoSePivotNullo;
    [Test]
    procedure QrDovrebbeDareFattoriOrtogonaleETriangolare;
    [Test]
    procedure QrDovrebbeRisolvereIlSistema;
    [Test]
    procedure QrDovrebbeDareFalsoPerMatriceSingolare;
    [Test]
    procedure QrUpdateRankOneDovrebbeDareIFattoriDellaMatriceModificata;
    [Test]
    procedure QrUpdateIncrementEDecrementDovrebberoCambiareLeDimensioni;
    [Test]
    procedure SvdDovrebbeRicostruireLaMatrice;
    [Test]
    procedure SvdDovrebbeRisolvereEInvertire;
    [Test]
    procedure SvdDovrebbeDareFalsoConMenoRigheCheColonne;
    [Test]
    procedure SvdDovrebbeAnnullareIValoriSingolariPiccoli;
    [Test]
    procedure EigenGeneralDovrebbeDareAutovettoriReali;
    [Test]
    procedure EigenGeneralDovrebbeDareAutovettoriComplessi;
    [Test]
    procedure EigenGeneralDovrebbeDareFalsoPerMatriceNulla;
    [Test]
    procedure EigenGeneralDovrebbeDareFalsoPerMatriceConNaN;
    [Test]
    procedure EigenGeneralDovrebbeGestireUnaMatriceDiUnaRiga;
    [Test]
    procedure EigenGeneralDovrebbeGestireMatriciDefettive;
    [Test]
    procedure ComplexDivisionDovrebbeDividereNumeriComplessi;
  end;

implementation

uses
  System.Math, System.SysUtils, DelphiDoom.MathCore.Float.MatX,
  DelphiDoom.MathCore.Float.MatX.EigenGeneral, DelphiDoom.MathCore.Float.MatX.LuUpdate,
  DelphiDoom.MathCore.Float.MatX.Qr, DelphiDoom.MathCore.Float.MatX.Svd,
  DelphiDoom.MathCore.Float.Types, DelphiDoom.MathCore.Float.VecX;

const
  Tolerance = 2E-3;

var
  GSeed: Cardinal = 20240101;

function NextValue: Single;
begin
  GSeed := GSeed * 1664525 + 1013904223;
  Result := (GSeed shr 8) / 8388608.0 - 1.0;
end;

function DominantMatrix(const ARows, AColumns: Integer): TIdMatX;
var
  LRow, LColumn: Integer;
begin
  Result := TIdMatX.Create(ARows, AColumns);
  for LRow := 0 to ARows - 1 do
  begin
    for LColumn := 0 to AColumns - 1 do
    begin
      Result[LRow, LColumn] := NextValue * 2.0;
    end;
    if LRow < AColumns then
      Result[LRow, LRow] := Result[LRow, LRow] + 3.0;
  end;
end;

function RandomVector(const ASize: Integer): TIdVecX;
var
  LIndex: Integer;
begin
  Result := TIdVecX.Create(ASize);
  for LIndex := 0 to ASize - 1 do
  begin
    Result[LIndex] := NextValue;
  end;
end;

procedure CheckSame(const AExpected, AActual: TIdMatX; const AMessage: string);
var
  LRow, LColumn: Integer;
begin
  Assert.AreEqual(AExpected.NumRows, AActual.NumRows, AMessage + ': righe');
  Assert.AreEqual(AExpected.NumColumns, AActual.NumColumns, AMessage + ': colonne');
  for LRow := 0 to AExpected.NumRows - 1 do
  begin
    for LColumn := 0 to AExpected.NumColumns - 1 do
    begin
      Assert.AreEqual(Double(AExpected[LRow, LColumn]), Double(AActual[LRow, LColumn]), Tolerance,
        Format('%s: (%d, %d)', [AMessage, LRow, LColumn]));
    end;
  end;
end;

/// <summary>The matrix that the LU factors in place stand for</summary>
function LuProduct(const AFactors: TIdMatX; const AIndex: PIdIntegerArray): TIdMatX;
begin
  Result := TIdMatX.Create(AFactors.NumRows, AFactors.NumColumns);
  AFactors.LuMultiplyFactors(Result, AIndex);
end;

procedure TTestMatrixDecompositionsValues.LuUpdateRankOneDovrebbeDareIFattoriDellaMatriceModificata;
var
  LPivot, LRow, LColumn: Integer;
  LMatrix, LFactors, LExpected, LActual: TIdMatX;
  LV, LW: TIdVecX;
  LIndex: TArray<Integer>;
  LPointer: PIdIntegerArray;
begin
  for LPivot := 0 to 1 do
  begin
    LMatrix := DominantMatrix(5, 5);
    LFactors := TIdMatX.Create;
    LV := RandomVector(5);
    LW := RandomVector(5);
    LExpected := TIdMatX.Create;
    SetLength(LIndex, 8);
    try
      LFactors.Assign(LMatrix);
      if LPivot = 1 then
        LPointer := PIdIntegerArray(@LIndex[0])
      else
        LPointer := nil;
      Assert.IsTrue(LFactors.LuFactor(LPointer));
      // the update takes v in the original row order; the expected matrix is A + alpha * v w'
      LExpected.Assign(LMatrix);
      for LRow := 0 to 4 do
      begin
        for LColumn := 0 to 4 do
        begin
          LExpected[LRow, LColumn] := LExpected[LRow, LColumn] + 0.5 * LV[LRow] * LW[LColumn];
        end;
      end;
      Assert.IsTrue(TIdMatXLuUpdate.UpdateRankOne(LFactors, LV, LW, 0.5, LPointer));
      LActual := LuProduct(LFactors, LPointer);
      try
        CheckSame(LExpected, LActual, 'rango uno, pivot ' + IntToStr(LPivot));
      finally
        LActual.Free;
      end;
    finally
      LExpected.Free;
      LW.Free;
      LV.Free;
      LFactors.Free;
      LMatrix.Free;
    end;
  end;
end;

procedure TTestMatrixDecompositionsValues.LuUpdateRowColumnDovrebbeDareIFattoriDellaMatriceModificata;
var
  LPivot, LItem, LRow: Integer;
  LMatrix, LFactors, LExpected, LActual: TIdMatX;
  LV, LW: TIdVecX;
  LIndex: TArray<Integer>;
  LPointer: PIdIntegerArray;
begin
  LRow := 2;
  for LPivot := 0 to 1 do
  begin
    LMatrix := DominantMatrix(5, 5);
    LFactors := TIdMatX.Create;
    LV := RandomVector(5);
    LW := RandomVector(5);
    LW[LRow] := 0.0;
    LExpected := TIdMatX.Create;
    SetLength(LIndex, 8);
    try
      LFactors.Assign(LMatrix);
      if LPivot = 1 then
        LPointer := PIdIntegerArray(@LIndex[0])
      else
        LPointer := nil;
      Assert.IsTrue(LFactors.LuFactor(LPointer));
      // column r gets v (the entry r,r gets v[r]), row r gets w
      LExpected.Assign(LMatrix);
      for LItem := 0 to 4 do
      begin
        LExpected[LItem, LRow] := LExpected[LItem, LRow] + LV[LItem];
        LExpected[LRow, LItem] := LExpected[LRow, LItem] + LW[LItem];
      end;
      Assert.IsTrue(TIdMatXLuUpdate.UpdateRowColumn(LFactors, LV, LW, LRow, LPointer));
      LActual := LuProduct(LFactors, LPointer);
      try
        CheckSame(LExpected, LActual, 'riga e colonna, pivot ' + IntToStr(LPivot));
      finally
        LActual.Free;
      end;
    finally
      LExpected.Free;
      LW.Free;
      LV.Free;
      LFactors.Free;
      LMatrix.Free;
    end;
  end;
end;

procedure TTestMatrixDecompositionsValues.LuUpdateIncrementDovrebbeAggiungereRigaEColonna;
var
  LPivot, LItem: Integer;
  LMatrix, LFactors, LExpected, LActual: TIdMatX;
  LV, LW: TIdVecX;
  LIndex: TArray<Integer>;
  LPointer: PIdIntegerArray;
begin
  for LPivot := 0 to 1 do
  begin
    LMatrix := DominantMatrix(4, 4);
    LFactors := TIdMatX.Create;
    LV := RandomVector(5);
    LW := RandomVector(5);
    LW[4] := 0.0;
    LExpected := TIdMatX.Create;
    SetLength(LIndex, 8);
    try
      LFactors.Assign(LMatrix);
      if LPivot = 1 then
        LPointer := PIdIntegerArray(@LIndex[0])
      else
        LPointer := nil;
      Assert.IsTrue(LFactors.LuFactor(LPointer));
      LExpected.Assign(LMatrix);
      LExpected.ChangeSize(5, 5, True);
      for LItem := 0 to 4 do
      begin
        LExpected[LItem, 4] := LV[LItem];
      end;
      for LItem := 0 to 3 do
      begin
        LExpected[4, LItem] := LW[LItem];
      end;
      Assert.IsTrue(TIdMatXLuUpdate.UpdateIncrement(LFactors, LV, LW, LPointer));
      Assert.AreEqual(5, LFactors.NumRows);
      LActual := LuProduct(LFactors, LPointer);
      try
        CheckSame(LExpected, LActual, 'incremento, pivot ' + IntToStr(LPivot));
      finally
        LActual.Free;
      end;
    finally
      LExpected.Free;
      LW.Free;
      LV.Free;
      LFactors.Free;
      LMatrix.Free;
    end;
  end;
end;

procedure TTestMatrixDecompositionsValues.LuUpdateDecrementDovrebbeTogliereRigaEColonna;
var
  LPivot, LItem, LRow, LSource: Integer;
  LMatrix, LFactors, LExpected, LActual: TIdMatX;
  LColumn, LRowVector, LURow: TIdVecX;
  LIndex: TArray<Integer>;
  LPointer: PIdIntegerArray;
begin
  LRow := 1;
  for LPivot := 0 to 1 do
  begin
    LMatrix := DominantMatrix(5, 5);
    // a small first pivot makes the factorization swap rows
    LMatrix[0, 0] := 0.01;
    LFactors := TIdMatX.Create;
    LColumn := TIdVecX.Create(5);
    LRowVector := TIdVecX.Create(5);
    LURow := TIdVecX.Create(5);
    LExpected := TIdMatX.Create;
    SetLength(LIndex, 8);
    try
      LFactors.Assign(LMatrix);
      if LPivot = 1 then
        LPointer := PIdIntegerArray(@LIndex[0])
      else
        LPointer := nil;
      Assert.IsTrue(LFactors.LuFactor(LPointer));
      for LItem := 0 to 4 do
      begin
        LColumn[LItem] := LMatrix[LItem, LRow];
        LRowVector[LItem] := LMatrix[LRow, LItem];
      end;
      if LPivot = 1 then
        LSource := LIndex[LRow]
      else
        LSource := LRow;
      for LItem := 0 to 4 do
      begin
        LURow[LItem] := LMatrix[LSource, LItem];
      end;
      LExpected.Assign(LMatrix);
      LExpected.RemoveRowColumn(LRow);
      Assert.IsTrue(TIdMatXLuUpdate.UpdateDecrement(LFactors, LColumn, LRowVector, LURow, LRow,
        LPointer));
      Assert.AreEqual(4, LFactors.NumRows);
      LActual := LuProduct(LFactors, LPointer);
      try
        CheckSame(LExpected, LActual, 'decremento, pivot ' + IntToStr(LPivot));
      finally
        LActual.Free;
      end;
    finally
      LExpected.Free;
      LURow.Free;
      LRowVector.Free;
      LColumn.Free;
      LFactors.Free;
      LMatrix.Free;
    end;
  end;
end;

procedure TTestMatrixDecompositionsValues.LuUpdateDovrebbeDareFalsoSePivotNullo;
var
  LFactors: TIdMatX;
  LV, LW: TIdVecX;
begin
  LFactors := TIdMatX.Create(2, 2);
  LV := TIdVecX.Create(2);
  LW := TIdVecX.Create(2);
  try
    LFactors.Identity;
    LV[0] := 1.0;
    LW[0] := -1.0;
    // 1 + (1 * -1) = 0 on the first pivot
    Assert.IsFalse(TIdMatXLuUpdate.UpdateRankOne(LFactors, LV, LW, 1.0, nil));
  finally
    LW.Free;
    LV.Free;
    LFactors.Free;
  end;
end;

procedure TTestMatrixDecompositionsValues.QrDovrebbeDareFattoriOrtogonaleETriangolare;
var
  LMatrix, LFactors, LQ, LR, LProduct, LBack, LTransposed, LIdentity: TIdMatX;
  LC, LD: TIdVecX;
  LRow, LColumn: Integer;
begin
  LMatrix := DominantMatrix(5, 5);
  LFactors := TIdMatX.Create;
  LQ := TIdMatX.Create;
  LR := TIdMatX.Create;
  LBack := TIdMatX.Create(5, 5);
  LC := TIdVecX.Create(5);
  LD := TIdVecX.Create(5);
  try
    LFactors.Assign(LMatrix);
    Assert.IsTrue(TIdMatXQr.Factor(LFactors, LC, LD));
    TIdMatXQr.UnpackFactors(LFactors, LQ, LR, LC, LD);
    LProduct := LQ.Multiply(LR);
    LTransposed := LQ.Transpose;
    LIdentity := LTransposed.Multiply(LQ);
    try
      CheckSame(LMatrix, LProduct, 'Q * R');
      Assert.IsTrue(LIdentity.IsIdentity(1E-4), 'Q ortogonale');
      for LRow := 1 to 4 do
      begin
        for LColumn := 0 to LRow - 1 do
        begin
          Assert.AreEqual(0.0, Double(LR[LRow, LColumn]), 1E-6, 'R triangolare');
        end;
      end;
    finally
      LIdentity.Free;
      LTransposed.Free;
      LProduct.Free;
    end;
    // QR_MultiplyFactors of the C++ does not give back the matrix (the sum over k < i uses the
    // transposed factor: the golden shows the same numbers); only the shape is checked
    TIdMatXQr.MultiplyFactors(LFactors, LBack, LC, LD);
    Assert.AreEqual(5, LBack.NumRows);
  finally
    LD.Free;
    LC.Free;
    LBack.Free;
    LR.Free;
    LQ.Free;
    LFactors.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixDecompositionsValues.QrDovrebbeRisolvereIlSistema;
var
  LMatrix, LFactors, LQ, LR, LInverse, LProduct: TIdMatX;
  LC, LD, LB, LX, LCheck, LXR: TIdVecX;
  LIndex: Integer;
begin
  LMatrix := DominantMatrix(4, 4);
  LFactors := TIdMatX.Create;
  LQ := TIdMatX.Create;
  LR := TIdMatX.Create;
  LInverse := TIdMatX.Create;
  LC := TIdVecX.Create(4);
  LD := TIdVecX.Create(4);
  LB := RandomVector(4);
  LX := TIdVecX.Create(4);
  LXR := TIdVecX.Create(4);
  try
    LFactors.Assign(LMatrix);
    Assert.IsTrue(TIdMatXQr.Factor(LFactors, LC, LD));
    TIdMatXQr.Solve(LFactors, LX, LB, LC, LD);
    LCheck := LMatrix.Multiply(LX);
    try
      for LIndex := 0 to 3 do
      begin
        Assert.AreEqual(Double(LB[LIndex]), Double(LCheck[LIndex]), Tolerance, 'A x = b');
      end;
    finally
      LCheck.Free;
    end;
    TIdMatXQr.UnpackFactors(LFactors, LQ, LR, LC, LD);
    TIdMatXQr.Solve(LQ, LXR, LB, LR);
    for LIndex := 0 to 3 do
    begin
      Assert.AreEqual(Double(LX[LIndex]), Double(LXR[LIndex]), Tolerance, 'soluzione con R');
    end;
    TIdMatXQr.Inverse(LFactors, LInverse, LC, LD);
    LProduct := LMatrix.Multiply(LInverse);
    try
      Assert.IsTrue(LProduct.IsIdentity(1E-3), 'A * inversa');
    finally
      LProduct.Free;
    end;
  finally
    LXR.Free;
    LX.Free;
    LB.Free;
    LD.Free;
    LC.Free;
    LInverse.Free;
    LR.Free;
    LQ.Free;
    LFactors.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixDecompositionsValues.QrDovrebbeDareFalsoPerMatriceSingolare;
var
  LMatrix: TIdMatX;
  LC, LD: TIdVecX;
begin
  LMatrix := TIdMatX.Create(3, 3);
  LC := TIdVecX.Create(3);
  LD := TIdVecX.Create(3);
  try
    LMatrix.Zero;
    Assert.IsFalse(TIdMatXQr.Factor(LMatrix, LC, LD));
  finally
    LD.Free;
    LC.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixDecompositionsValues.QrUpdateRankOneDovrebbeDareIFattoriDellaMatriceModificata;
var
  LMatrix, LFactors, LQ, LR, LExpected, LProduct: TIdMatX;
  LC, LD, LV, LW: TIdVecX;
  LRow, LColumn: Integer;
begin
  LMatrix := DominantMatrix(4, 4);
  LFactors := TIdMatX.Create;
  LQ := TIdMatX.Create;
  LR := TIdMatX.Create;
  LExpected := TIdMatX.Create;
  LC := TIdVecX.Create(4);
  LD := TIdVecX.Create(4);
  LV := RandomVector(4);
  LW := RandomVector(4);
  try
    LFactors.Assign(LMatrix);
    Assert.IsTrue(TIdMatXQr.Factor(LFactors, LC, LD));
    TIdMatXQr.UnpackFactors(LFactors, LQ, LR, LC, LD);
    LExpected.Assign(LMatrix);
    for LRow := 0 to 3 do
    begin
      for LColumn := 0 to 3 do
      begin
        LExpected[LRow, LColumn] := LExpected[LRow, LColumn] + 0.5 * LV[LRow] * LW[LColumn];
      end;
    end;
    Assert.IsTrue(TIdMatXQr.UpdateRankOne(LQ, LR, LV, LW, 0.5));
    LProduct := LQ.Multiply(LR);
    try
      CheckSame(LExpected, LProduct, 'Q R aggiornati');
    finally
      LProduct.Free;
    end;
  finally
    LW.Free;
    LV.Free;
    LD.Free;
    LC.Free;
    LExpected.Free;
    LR.Free;
    LQ.Free;
    LFactors.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixDecompositionsValues.QrUpdateIncrementEDecrementDovrebberoCambiareLeDimensioni;
var
  LMatrix, LFactors, LQ, LR, LExpected, LProduct: TIdMatX;
  LC, LD, LV, LW, LColumn, LRowVector: TIdVecX;
  LItem: Integer;
begin
  LMatrix := DominantMatrix(4, 4);
  LFactors := TIdMatX.Create;
  LQ := TIdMatX.Create;
  LR := TIdMatX.Create;
  LExpected := TIdMatX.Create;
  LC := TIdVecX.Create(4);
  LD := TIdVecX.Create(4);
  LV := RandomVector(5);
  LW := RandomVector(5);
  LW[4] := 0.0;
  LColumn := TIdVecX.Create(5);
  LRowVector := TIdVecX.Create(5);
  try
    LFactors.Assign(LMatrix);
    Assert.IsTrue(TIdMatXQr.Factor(LFactors, LC, LD));
    TIdMatXQr.UnpackFactors(LFactors, LQ, LR, LC, LD);
    // increment
    LExpected.Assign(LMatrix);
    LExpected.ChangeSize(5, 5, True);
    for LItem := 0 to 4 do
    begin
      LExpected[LItem, 4] := LV[LItem];
    end;
    for LItem := 0 to 3 do
    begin
      LExpected[4, LItem] := LW[LItem];
    end;
    Assert.IsTrue(TIdMatXQr.UpdateIncrement(LQ, LR, LV, LW));
    Assert.AreEqual(5, LQ.NumRows);
    LProduct := LQ.Multiply(LR);
    try
      CheckSame(LExpected, LProduct, 'incremento');
    finally
      LProduct.Free;
    end;
    // decrement of the row and the column 2 of the 5x5 matrix
    for LItem := 0 to 4 do
    begin
      LColumn[LItem] := LExpected[LItem, 2];
      LRowVector[LItem] := LExpected[2, LItem];
    end;
    LExpected.RemoveRowColumn(2);
    Assert.IsTrue(TIdMatXQr.UpdateDecrement(LQ, LR, LColumn, LRowVector, 2));
    Assert.AreEqual(4, LQ.NumRows);
    Assert.AreEqual(4, LR.NumRows);
    LProduct := LQ.Multiply(LR);
    try
      CheckSame(LExpected, LProduct, 'decremento');
    finally
      LProduct.Free;
    end;
  finally
    LRowVector.Free;
    LColumn.Free;
    LW.Free;
    LV.Free;
    LD.Free;
    LC.Free;
    LExpected.Free;
    LR.Free;
    LQ.Free;
    LFactors.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixDecompositionsValues.SvdDovrebbeRicostruireLaMatrice;
var
  LRows, LColumns, LRow, LColumn, LK: Integer;
  LMatrix, LFactors, LV, LBack: TIdMatX;
  LW: TIdVecX;
  LSum: Double;
begin
  LRows := 6;
  LColumns := 4;
  LMatrix := DominantMatrix(LRows, LColumns);
  LFactors := TIdMatX.Create;
  LV := TIdMatX.Create;
  LW := TIdVecX.Create;
  try
    LFactors.Assign(LMatrix);
    Assert.IsTrue(TIdMatXSvd.Factor(LFactors, LW, LV));
    for LColumn := 0 to LColumns - 1 do
    begin
      Assert.IsTrue(LW[LColumn] >= 0.0, 'valori singolari non negativi');
    end;
    // U * Diag(w) * V' = A
    for LRow := 0 to LRows - 1 do
    begin
      for LColumn := 0 to LColumns - 1 do
      begin
        LSum := 0.0;
        for LK := 0 to LColumns - 1 do
        begin
          LSum := LSum + LFactors[LRow, LK] * LW[LK] * LV[LColumn, LK];
        end;
        Assert.AreEqual(Double(LMatrix[LRow, LColumn]), LSum, Tolerance, 'U w V'' = A');
      end;
    end;
    LBack := TIdMatX.Create;
    try
      LBack.SetSize(LColumns, LColumns);
      LV.TransposeMultiply(LBack, LV);
      Assert.IsTrue(LBack.IsIdentity(1E-3), 'V ortogonale');
    finally
      LBack.Free;
    end;
  finally
    LW.Free;
    LV.Free;
    LFactors.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixDecompositionsValues.SvdDovrebbeRisolvereEInvertire;
var
  LMatrix, LFactors, LV, LInverse, LProduct, LBack: TIdMatX;
  LW, LB, LX, LCheck: TIdVecX;
  LIndex: Integer;
begin
  LMatrix := DominantMatrix(4, 4);
  LFactors := TIdMatX.Create;
  LV := TIdMatX.Create;
  LInverse := TIdMatX.Create(4, 4);
  LBack := TIdMatX.Create;
  LW := TIdVecX.Create;
  LB := RandomVector(4);
  LX := TIdVecX.Create(4);
  try
    LFactors.Assign(LMatrix);
    Assert.IsTrue(TIdMatXSvd.Factor(LFactors, LW, LV));
    TIdMatXSvd.Solve(LFactors, LX, LB, LW, LV);
    LCheck := LMatrix.Multiply(LX);
    try
      for LIndex := 0 to 3 do
      begin
        Assert.AreEqual(Double(LB[LIndex]), Double(LCheck[LIndex]), Tolerance, 'A x = b');
      end;
    finally
      LCheck.Free;
    end;
    TIdMatXSvd.Inverse(LFactors, LInverse, LW, LV);
    LProduct := LMatrix.Multiply(LInverse);
    try
      Assert.IsTrue(LProduct.IsIdentity(1E-3), 'A * inversa');
    finally
      LProduct.Free;
    end;
    // SVD_MultiplyFactors of the C++ scales row r by w[r] where U * Diag(w) * V' scales column j by
    // w[j]: it is not the original matrix (the golden shows the same numbers), only the shape is checked
    TIdMatXSvd.MultiplyFactors(LFactors, LBack, LW, LV);
    Assert.AreEqual(4, LBack.NumRows);
    Assert.AreEqual(4, LBack.NumColumns);
  finally
    LX.Free;
    LB.Free;
    LW.Free;
    LBack.Free;
    LInverse.Free;
    LV.Free;
    LFactors.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixDecompositionsValues.SvdDovrebbeDareFalsoConMenoRigheCheColonne;
var
  LMatrix, LV: TIdMatX;
  LW: TIdVecX;
begin
  LMatrix := DominantMatrix(2, 3);
  LV := TIdMatX.Create;
  LW := TIdVecX.Create;
  try
    Assert.IsFalse(TIdMatXSvd.Factor(LMatrix, LW, LV));
  finally
    LW.Free;
    LV.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixDecompositionsValues.SvdDovrebbeAnnullareIValoriSingolariPiccoli;
var
  LMatrix, LFactors, LV, LInverse: TIdMatX;
  LW, LB, LX: TIdVecX;
begin
  // two equal columns: one singular value is zero and the solver and the inverse leave it out
  LMatrix := TIdMatX.Create(3, 3);
  LFactors := TIdMatX.Create;
  LV := TIdMatX.Create;
  LInverse := TIdMatX.Create(3, 3);
  LW := TIdVecX.Create;
  LB := TIdVecX.Create(3);
  LX := TIdVecX.Create(3);
  try
    LMatrix.Zero;
    LMatrix[0, 0] := 1.0;
    LMatrix[0, 1] := 1.0;
    LMatrix[1, 0] := 2.0;
    LMatrix[1, 1] := 2.0;
    LMatrix[2, 2] := 3.0;
    LFactors.Assign(LMatrix);
    Assert.IsTrue(TIdMatXSvd.Factor(LFactors, LW, LV));
    LB[0] := 1.0;
    LB[1] := 2.0;
    LB[2] := 3.0;
    TIdMatXSvd.Solve(LFactors, LX, LB, LW, LV);
    // the minimum norm solution of x0 + x1 = 1, x2 = 1
    Assert.AreEqual(0.5, Double(LX[0]), Tolerance);
    Assert.AreEqual(0.5, Double(LX[1]), Tolerance);
    Assert.AreEqual(1.0, Double(LX[2]), Tolerance);
    TIdMatXSvd.Inverse(LFactors, LInverse, LW, LV);
    Assert.AreEqual(1.0 / 3.0, Double(LInverse[2, 2]), Tolerance);
  finally
    LX.Free;
    LB.Free;
    LW.Free;
    LInverse.Free;
    LV.Free;
    LFactors.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixDecompositionsValues.EigenGeneralDovrebbeDareAutovettoriReali;
var
  LMatrix, LSolved: TIdMatX;
  LReal, LImaginary: TIdVecX;
  LRow, LColumn, LK: Integer;
  LProduct: Double;
begin
  // a triangular matrix has its eigenvalues on the diagonal; the vectors are checked with A v = l v
  LMatrix := TIdMatX.Create(4, 4);
  LSolved := TIdMatX.Create;
  LReal := TIdVecX.Create;
  LImaginary := TIdVecX.Create;
  try
    LMatrix.Zero;
    for LRow := 0 to 3 do
    begin
      LMatrix[LRow, LRow] := LRow + 1.0;
      for LColumn := LRow + 1 to 3 do
      begin
        LMatrix[LRow, LColumn] := 0.5 * (LRow + LColumn);
      end;
    end;
    LSolved.Assign(LMatrix);
    Assert.IsTrue(TIdMatXEigenGeneral.Solve(LSolved, LReal, LImaginary));
    for LColumn := 0 to 3 do
    begin
      Assert.AreEqual(0.0, Double(LImaginary[LColumn]), 1E-6, 'autovalore reale');
      for LRow := 0 to 3 do
      begin
        LProduct := 0.0;
        for LK := 0 to 3 do
        begin
          LProduct := LProduct + LMatrix[LRow, LK] * LSolved[LK, LColumn];
        end;
        Assert.AreEqual(LReal[LColumn] * Double(LSolved[LRow, LColumn]), LProduct, Tolerance,
          Format('A v = l v, colonna %d riga %d', [LColumn, LRow]));
      end;
    end;
  finally
    LImaginary.Free;
    LReal.Free;
    LSolved.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixDecompositionsValues.EigenGeneralDovrebbeDareAutovettoriComplessi;
var
  LMatrix, LSolved: TIdMatX;
  LReal, LImaginary: TIdVecX;
  LRow, LK, LColumn: Integer;
  LAvr, LAvi, LExpectedR, LExpectedI: Double;
  LPairs: Integer;
begin
  // two rotation-scaling blocks and a real eigenvalue: 2 (cos + i sin) pairs
  LMatrix := TIdMatX.Create(5, 5);
  LSolved := TIdMatX.Create;
  LReal := TIdVecX.Create;
  LImaginary := TIdVecX.Create;
  try
    LMatrix.Zero;
    LMatrix[0, 0] := 1.0;
    LMatrix[0, 1] := -2.0;
    LMatrix[1, 0] := 2.0;
    LMatrix[1, 1] := 1.0;
    LMatrix[2, 2] := 3.0;
    LMatrix[3, 3] := 0.5;
    LMatrix[3, 4] := -1.0;
    LMatrix[4, 3] := 1.5;
    LMatrix[4, 4] := 0.5;
    LMatrix[0, 3] := 0.3;
    LMatrix[1, 2] := 0.7;
    LMatrix[2, 4] := -0.4;
    LSolved.Assign(LMatrix);
    Assert.IsTrue(TIdMatXEigenGeneral.Solve(LSolved, LReal, LImaginary));
    LPairs := 0;
    LColumn := 0;
    while LColumn < 5 do
    begin
      if Abs(LImaginary[LColumn]) < 1E-6 then
      begin
        for LRow := 0 to 4 do
        begin
          LAvr := 0.0;
          for LK := 0 to 4 do
          begin
            LAvr := LAvr + LMatrix[LRow, LK] * LSolved[LK, LColumn];
          end;
          Assert.AreEqual(LReal[LColumn] * Double(LSolved[LRow, LColumn]), LAvr, Tolerance,
            'vettore reale');
        end;
        Inc(LColumn);
      end
      else
      begin
        // the pair takes two columns: real and imaginary part of the vector of the value with a positive imaginary part
        Assert.IsTrue(LImaginary[LColumn] > 0.0);
        Assert.AreEqual(-Double(LImaginary[LColumn]), Double(LImaginary[LColumn + 1]), 1E-6);
        for LRow := 0 to 4 do
        begin
          LAvr := 0.0;
          LAvi := 0.0;
          for LK := 0 to 4 do
          begin
            LAvr := LAvr + LMatrix[LRow, LK] * LSolved[LK, LColumn];
            LAvi := LAvi + LMatrix[LRow, LK] * LSolved[LK, LColumn + 1];
          end;
          LExpectedR := LReal[LColumn] * Double(LSolved[LRow, LColumn]) -
            LImaginary[LColumn] * Double(LSolved[LRow, LColumn + 1]);
          LExpectedI := LReal[LColumn] * Double(LSolved[LRow, LColumn + 1]) +
            LImaginary[LColumn] * Double(LSolved[LRow, LColumn]);
          Assert.AreEqual(LExpectedR, LAvr, Tolerance, 'parte reale del vettore complesso');
          Assert.AreEqual(LExpectedI, LAvi, Tolerance, 'parte immaginaria del vettore complesso');
        end;
        Inc(LPairs);
        Inc(LColumn, 2);
      end;
    end;
    Assert.AreEqual(2, LPairs, 'coppie complesse');
  finally
    LImaginary.Free;
    LReal.Free;
    LSolved.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixDecompositionsValues.EigenGeneralDovrebbeDareFalsoPerMatriceNulla;
var
  LMatrix: TIdMatX;
  LReal, LImaginary: TIdVecX;
begin
  LMatrix := TIdMatX.Create(3, 3);
  LReal := TIdVecX.Create;
  LImaginary := TIdVecX.Create;
  try
    LMatrix.Zero;
    Assert.IsFalse(TIdMatXEigenGeneral.Solve(LMatrix, LReal, LImaginary));
  finally
    LImaginary.Free;
    LReal.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixDecompositionsValues.EigenGeneralDovrebbeDareFalsoPerMatriceConNaN;
var
  LMatrix: TIdMatX;
  LReal, LImaginary: TIdVecX;
begin
  // the C++ iterates for ever on a NaN: here the iteration stops after 100 steps per row
  LMatrix := DominantMatrix(4, 4);
  LReal := TIdVecX.Create;
  LImaginary := TIdVecX.Create;
  try
    LMatrix[1, 2] := NaN;
    Assert.IsFalse(TIdMatXEigenGeneral.Solve(LMatrix, LReal, LImaginary));
  finally
    LImaginary.Free;
    LReal.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixDecompositionsValues.EigenGeneralDovrebbeGestireUnaMatriceDiUnaRiga;
var
  LMatrix: TIdMatX;
  LReal, LImaginary: TIdVecX;
begin
  LMatrix := TIdMatX.Create(1, 1);
  LReal := TIdVecX.Create;
  LImaginary := TIdVecX.Create;
  try
    LMatrix[0, 0] := 4.0;
    Assert.IsTrue(TIdMatXEigenGeneral.Solve(LMatrix, LReal, LImaginary));
    Assert.AreEqual(4.0, Double(LReal[0]), 1E-6);
    Assert.AreEqual(0.0, Double(LImaginary[0]), 1E-6);
    Assert.AreEqual(1.0, Double(LMatrix[0, 0]), 1E-6);
  finally
    LImaginary.Free;
    LReal.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixDecompositionsValues.EigenGeneralDovrebbeGestireMatriciDefettive;
var
  LMatrix: TIdMatX;
  LReal, LImaginary: TIdVecX;
  LIndex: Integer;
begin
  // a Jordan block: the eigenvalue 2 is double and the iteration still ends
  LMatrix := TIdMatX.Create(3, 3);
  LReal := TIdVecX.Create;
  LImaginary := TIdVecX.Create;
  try
    LMatrix.Zero;
    for LIndex := 0 to 2 do
    begin
      LMatrix[LIndex, LIndex] := 2.0;
    end;
    LMatrix[0, 1] := 1.0;
    LMatrix[1, 2] := 1.0;
    Assert.IsTrue(TIdMatXEigenGeneral.Solve(LMatrix, LReal, LImaginary));
    for LIndex := 0 to 2 do
    begin
      Assert.AreEqual(2.0, Double(LReal[LIndex]), 1E-4);
    end;
  finally
    LImaginary.Free;
    LReal.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixDecompositionsValues.ComplexDivisionDovrebbeDividereNumeriComplessi;
var
  LReal, LImaginary: Single;
begin
  // (1 + 2i) / (3 + 4i) = (11 + 2i) / 25 with the real part of the divisor larger, then smaller
  TIdMatXEigenGeneral.ComplexDivision(1.0, 2.0, 4.0, 3.0, LReal, LImaginary);
  Assert.AreEqual(10.0 / 25.0, Double(LReal), 1E-6);
  Assert.AreEqual(5.0 / 25.0, Double(LImaginary), 1E-6);
  TIdMatXEigenGeneral.ComplexDivision(1.0, 2.0, 3.0, 4.0, LReal, LImaginary);
  Assert.AreEqual(11.0 / 25.0, Double(LReal), 1E-6);
  Assert.AreEqual(2.0 / 25.0, Double(LImaginary), 1E-6);
end;

end.
