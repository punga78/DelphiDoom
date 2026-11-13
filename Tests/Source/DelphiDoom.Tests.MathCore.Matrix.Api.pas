{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the matrices of MathCore - operators and helpers of    }
{  the vectors and matrices, with values worked out by hand                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Matrix.Api;

{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('mathcore')]
  TTestMatrixApi = class(TObject)
  public
    [Test]
    procedure TIdVec5DovrebbeCostruireEConvertire;
    [Test]
    procedure TIdVec6DovrebbeFareLeOperazioniDiBase;
    [Test]
    procedure TIdMat2DovrebbeFareLeOperazioniDiBase;
    [Test]
    procedure TIdVecXDovrebbeFareLeOperazioniDiBase;
    [Test]
    procedure TIdVecXDovrebbeDareISottoVettori;
    [Test]
    procedure TIdMatXDovrebbeFareLeOperazioniDiBase;
    [Test]
    procedure TIdMatXDovrebbeFareLeOperazioniConIVettori;
    [Test]
    procedure TIdMatXDovrebbeCostruireDaBlocchiDi3x3;
    [Test]
    procedure TIdMatXDovrebbeInvertireEDeterminareLeDimensioniFinoASei;
    [Test]
    procedure TIdMatXDovrebbeEseguireLeVerifiche;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.MathCore.Float.Mat2, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.MathCore.Float.MatX,
  DelphiDoom.MathCore.Float.Types, DelphiDoom.MathCore.Float.Vec5, DelphiDoom.MathCore.Float.Vec6,
  DelphiDoom.MathCore.Float.VecX;

procedure Near(const AExpected, AActual: Double; const ATolerance: Double = 1E-5);
begin
  Assert.IsTrue(System.Abs(AExpected - AActual) <= ATolerance,
    Format('atteso %g, ottenuto %g', [AExpected, AActual]));
end;

procedure TTestMatrixApi.TIdVec5DovrebbeCostruireEConvertire;
var
  LVector: TIdVec5;
begin
  LVector := TIdVec5.Create(TIdVec3.Create(1.0, 2.0, 3.0), TIdVec2.Create(4.0, 5.0));
  Near(4.0, LVector.S, 0);
  Near(5.0, LVector[4], 0);
  LVector[3] := 7.0;
  Near(7.0, LVector.S, 0);
  Assert.AreEqual(5, LVector.GetDimension);
  Near(3.0, LVector.ToVec3.Z, 0);
  Assert.AreEqual(AnsiString('1 2 3 7 5'), LVector.ToString);
end;

procedure TTestMatrixApi.TIdVec6DovrebbeFareLeOperazioniDiBase;
var
  LA, LB: TIdVec6;
  LNormalized: TIdVec6;
begin
  LA := TIdVec6.Create(1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
  LB := TIdVec6.Create(6.0, 5.0, 4.0, 3.0, 2.0, 1.0);
  Near(56.0, LA * LB, 0);
  LNormalized := -LA;
  Near(-3.0, LNormalized[2], 0);
  LNormalized := LA / 2.0;
  Near(1.0, LNormalized[1], 0);
  LNormalized := LA * 2.0;
  Near(14.0, LNormalized[5] + 2.0, 0);
  LNormalized := 2.0 * LB;
  Near(7.0, LNormalized[0] - 5.0, 0);
  LNormalized := LA + LB;
  Near(7.0, LNormalized[0], 0);
  LNormalized := LA - LB;
  Near(-5.0, LNormalized[0], 0);
  Assert.IsTrue(LA <> LB);
  Assert.IsTrue(LA = LA);
  Assert.IsTrue(LA.Compare(LB, 5.0));
  Assert.IsFalse(LA.Compare(LB, 4.0));
  LNormalized := LA;
  Near(Sqrt(91.0), LNormalized.NormalizeFast, 5E-2);
  Near(1.0, LNormalized.Length, 5E-3);
  LNormalized.Zero;
  Near(0.0, LNormalized.LengthSqr, 0);
  LNormalized.SetSubVec3(1, TIdVec3.Create(7.0, 8.0, 9.0));
  Near(9.0, LNormalized[5], 0);
  Assert.AreEqual(6, LNormalized.GetDimension);
  Assert.AreEqual(AnsiString('0 0 0 7 8 9'), LNormalized.ToString);
end;

procedure TTestMatrixApi.TIdMat2DovrebbeFareLeOperazioniDiBase;
var
  LA, LB, LResult: TIdMat2;
begin
  LA := TIdMat2.Create(1.0, 2.0, 3.0, 4.0);
  LB := TIdMat2.Create(0.0, 1.0, 1.0, 0.0);
  LResult := LA * LB;
  Near(2.0, LResult.Rows[0].X, 0);
  Near(1.0, LResult.Rows[0].Y, 0);
  LResult := LA + LB;
  Near(5.0, LResult.Rows[1].Y + 1.0, 0);
  LResult := LA - LB;
  Near(1.0, LResult.Rows[0].X, 0);
  LResult := -LA;
  Near(-4.0, LResult.Rows[1].Y, 0);
  LResult := LA * 2.0;
  Near(8.0, LResult.Rows[1].Y, 0);
  LResult := 2.0 * LA;
  Near(6.0, LResult.Rows[1].X, 0);
  Near(5.0, (LA * TIdVec2.Create(1.0, 2.0)).X, 0);
  Near(5.0, (TIdVec2.Create(1.0, 2.0) * LA).X, 0);
  Assert.IsTrue(LA <> LB);
  Assert.IsTrue(LA = LA);
  Assert.IsTrue(LA.Compare(LB, 4.0));
  Near(5.0, LA.Trace, 0);
  Near(-2.0, LA.Determinant, 0);
  Assert.IsFalse(LA.IsSymmetric);
  Assert.IsTrue(LB.IsSymmetric);
  Assert.IsFalse(LB.IsDiagonal);
  LResult := LA.Transpose;
  Near(3.0, LResult.Rows[0].Y, 0);
  LResult.TransposeSelf;
  Assert.IsTrue(LResult = LA);
  LResult := LA.InverseFast;
  Near(-2.0, LResult.Rows[0].X, 1E-5);
  LResult.Zero;
  Assert.IsTrue(LResult.IsDiagonal);
  LResult.SetIdentity;
  Assert.IsTrue(LResult.IsIdentity);
  Assert.AreEqual(4, LA.GetDimension);
  Assert.AreEqual(AnsiString('1 2 3 4'), LA.ToString);
end;

procedure TTestMatrixApi.TIdVecXDovrebbeFareLeOperazioniDiBase;
var
  LA, LB, LResult: TIdVecX;
begin
  LA := TIdVecX.Create(3);
  LB := TIdVecX.Create(3);
  try
    LA[0] := 1.0;
    LA[1] := 2.0;
    LA[2] := 2.0;
    LB[0] := 3.0;
    LB[1] := 0.0;
    LB[2] := -1.0;
    Near(1.0, LA.Multiply(LB), 0);
    LResult := LA.Subtract(LB);
    try
      Near(-2.0, LResult[0], 0);
    finally
      LResult.Free;
    end;
    LResult := LA.Multiply(2.0);
    try
      Near(4.0, LResult[1], 0);
    finally
      LResult.Free;
    end;
    LResult := LA.Divide(2.0);
    try
      Near(1.0, LResult[2], 0);
    finally
      LResult.Free;
    end;
    LResult := LA.Negative;
    try
      Near(-2.0, LResult[2], 0);
    finally
      LResult.Free;
    end;
    LResult := LA.Normalize;
    try
      Near(2.0 / 3.0, LResult[1], 1E-3);
    finally
      LResult.Free;
    end;
    Near(9.0, LA.LengthSqr, 0);
    Near(3.0, LA.Length, 1E-3);
    LA.AddAssign(LB);
    Near(4.0, LA[0], 0);
    LA.SubtractAssign(LB);
    LA.MultiplyAssign(2.0);
    Near(4.0, LA[2], 0);
    LA.DivideAssign(2.0);
    Near(2.0, LA[2], 0);
    LA.Clamp(0.0, 1.5);
    Near(1.0, LA[0], 0);
    Near(1.5, LA[1], 0);
    LA.SwapElements(0, 2);
    Near(1.5, LA[0], 0);
    Near(3.0, LB.Multiply(LB) - 7.0, 0);
    Assert.IsTrue(LA.Compare(LA, 0.0));
    Assert.IsFalse(LA.Compare(LB, 0.5));
    LA.Random(4, 7, 0.0, 2.0);
    Assert.AreEqual(4, LA.Size);
    Assert.IsTrue((LA[3] >= 0.0) and (LA[3] <= 2.0));
    LA.Zero(2);
    Assert.AreEqual(2, LA.GetDimension);
    Assert.AreEqual(AnsiString('0 0'), LA.ToString);
    Near(Sqrt(10.0), LB.NormalizeSelf, 1E-2);
  finally
    LB.Free;
    LA.Free;
  end;
end;

procedure TTestMatrixApi.TIdVecXDovrebbeDareISottoVettori;
var
  LVector: TIdVecX;
  LSix: TIdVec6;
begin
  LVector := TIdVecX.Create(12);
  try
    LVector.SetSubVec3(2, TIdVec3.Create(1.0, 2.0, 3.0));
    Near(3.0, LVector[8], 0);
    Near(2.0, LVector.GetSubVec3(2).Y, 0);
    LSix := TIdVec6.Create(1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
    LVector.SetSubVec6(1, LSix);
    Near(6.0, LVector[11], 0);
    Near(4.0, LVector.GetSubVec6(1).P[3], 0);
  finally
    LVector.Free;
  end;
end;

procedure TTestMatrixApi.TIdMatXDovrebbeFareLeOperazioniDiBase;
var
  LA, LB, LResult, LZero: TIdMatX;
begin
  LA := TIdMatX.Create(2, 3);
  LB := TIdMatX.Create(3, 2);
  LZero := TIdMatX.Create;
  try
    LA.Random(2, 3, 5, -1.0, 1.0);
    LResult := LA.Transpose;
    try
      LB.Assign(LResult);
    finally
      LResult.Free;
    end;
    LResult := LA.Multiply(LB);
    try
      Assert.AreEqual(2, LResult.NumRows);
      Assert.AreEqual(2, LResult.NumColumns);
      Near(LA[0, 0] * LA[0, 0] + LA[0, 1] * LA[0, 1] + LA[0, 2] * LA[0, 2], LResult[0, 0], 1E-5);
      Assert.IsTrue(LResult.IsSymmetric(1E-5));
    finally
      LResult.Free;
    end;
    LResult := LA.Multiply(2.0);
    try
      Near(LA[1, 2] * 2.0, LResult[1, 2], 0);
      LResult.AddAssign(LA);
      Near(LA[1, 2] * 3.0, LResult[1, 2], 1E-6);
      LResult.SubtractAssign(LA);
      LResult.MultiplyAssign(0.5);
      Near(LA[1, 2], LResult[1, 2], 1E-6);
    finally
      LResult.Free;
    end;
    LResult := LA.Add(LA);
    try
      Near(LA[0, 1] * 2.0, LResult[0, 1], 0);
    finally
      LResult.Free;
    end;
    LResult := LA.Subtract(LA);
    try
      Assert.IsTrue(LResult.IsZero);
    finally
      LResult.Free;
    end;
    LResult := LA.TransposeMultiply(LA);
    try
      Assert.AreEqual(3, LResult.NumRows);
    finally
      LResult.Free;
    end;
    LResult := TIdMatX.Create;
    try
      LResult.Assign(LA);
      LResult.MultiplyAssign(LB);
      Assert.AreEqual(2, LResult.NumColumns);
      LResult.Negate;
      LResult.Clamp(-0.1, 0.1);
      Assert.IsTrue(System.Abs(LResult[0, 0]) <= 0.1 + 1E-7);
      LResult.Identity(3, 3);
      Assert.IsTrue(LResult.IsIdentity);
      LResult.Zero(2, 2);
      Assert.IsTrue(LResult.IsZero);
      LResult[0, 1] := 2.0;
      LResult.TransposeSelf;
      Near(2.0, LResult[1, 0], 0);
      LResult.SwapRowsColumns(0, 1);
      Near(2.0, LResult[0, 1], 0);
      Assert.AreEqual(4, LResult.GetDimension);
      Assert.AreEqual(AnsiString('0 2 0 0'), LResult.ToString);
      Assert.IsTrue(LResult.IsTriDiagonal);
      Near(0.0, LResult.Trace, 0);
      LZero.Zero(2, 2);
      Near(2.0, LResult.MaxDifference(LZero), 0);
    finally
      LResult.Free;
    end;
  finally
    LZero.Free;
    LB.Free;
    LA.Free;
  end;
end;

procedure TTestMatrixApi.TIdMatXDovrebbeFareLeOperazioniConIVettori;
var
  LMatrix: TIdMatX;
  LVector, LResult, LDiagonal: TIdVecX;
  LRow: TIdVecX;
begin
  LMatrix := TIdMatX.Create(2, 3);
  LVector := TIdVecX.Create(3);
  LDiagonal := TIdVecX.Create(2);
  try
    LMatrix[0, 0] := 1.0;
    LMatrix[0, 1] := 2.0;
    LMatrix[0, 2] := 3.0;
    LMatrix[1, 0] := 4.0;
    LMatrix[1, 1] := 5.0;
    LMatrix[1, 2] := 6.0;
    LVector[0] := 1.0;
    LVector[1] := 0.0;
    LVector[2] := -1.0;
    LResult := LMatrix.Multiply(LVector);
    try
      Near(-2.0, LResult[0], 0);
      Near(-2.0, LResult[1], 0);
    finally
      LResult.Free;
    end;
    LDiagonal[0] := 1.0;
    LDiagonal[1] := 2.0;
    LResult := LMatrix.TransposeMultiply(LDiagonal);
    try
      Near(9.0, LResult[0], 0);
      Near(12.0, LResult[1], 0);
      Near(15.0, LResult[2], 0);
    finally
      LResult.Free;
    end;
    LRow := LMatrix.SubVecX(1);
    try
      Near(5.0, LRow[1], 0);
      LRow[1] := 50.0;
      Near(50.0, LMatrix[1, 1], 0);
    finally
      LRow.Free;
    end;
    LMatrix.Diag(LDiagonal);
    Assert.AreEqual(2, LMatrix.NumColumns);
    Near(2.0, LMatrix[1, 1], 0);
  finally
    LDiagonal.Free;
    LVector.Free;
    LMatrix.Free;
  end;
end;

procedure TTestMatrixApi.TIdMatXDovrebbeCostruireDaBlocchiDi3x3;
var
  LM: array[0..3] of TIdMat3;
  LMatrix: TIdMatX;
  LIndex: Integer;
  LSix: TIdVec6;
begin
  for LIndex := 0 to 3 do
  begin
    LM[LIndex] := TIdMat3.Identity * Single(LIndex + 1.0);
  end;
  LMatrix := TIdMatX.Create;
  try
    LMatrix.SetValues(LM[0], LM[1]);
    Assert.AreEqual(3, LMatrix.NumRows);
    Assert.AreEqual(6, LMatrix.NumColumns);
    Near(2.0, LMatrix[0, 3], 0);
    LMatrix.SetValues(LM[0], LM[1], LM[2], LM[3]);
    Assert.AreEqual(6, LMatrix.NumRows);
    Near(3.0, LMatrix[3, 0], 0);
    Near(4.0, LMatrix[5, 5], 0);
    LSix := LMatrix.GetSubVec6(5);
    Near(4.0, LSix.P[5], 0);
    LSix.P[0] := 9.0;
    LMatrix.SetSubVec6(0, LSix);
    Near(9.0, LMatrix[0, 0], 0);
    Near(3.0, LMatrix.Row(3)^[0], 0);
  finally
    LMatrix.Free;
  end;
end;

procedure TTestMatrixApi.TIdMatXDovrebbeInvertireEDeterminareLeDimensioniFinoASei;
var
  LMatrix, LInverse: TIdMatX;
  LSize, LIndex: Integer;
  LFast: Boolean;
  LExpected: Double;
begin
  for LSize := 1 to 6 do
  begin
    for LFast := False to True do
    begin
      LMatrix := TIdMatX.Create(LSize, LSize);
      try
        LMatrix.Zero;
        LExpected := 1.0;
        for LIndex := 0 to LSize - 1 do
        begin
          LMatrix[LIndex, LIndex] := LIndex + 2.0;
          LExpected := LExpected * (LIndex + 2.0);
        end;
        Near(LExpected, LMatrix.Determinant, 1E-4);
        if LFast then
          LInverse := LMatrix.InverseFast
        else
          LInverse := LMatrix.Inverse;
        try
          Near(1.0 / (LSize + 1.0), LInverse[LSize - 1, LSize - 1], 1E-6);
        finally
          LInverse.Free;
        end;
        if LFast then
          Assert.IsTrue(LMatrix.InverseFastSelf)
        else
          Assert.IsTrue(LMatrix.InverseSelf);
        LMatrix.Zero;
        if LFast then
          Assert.IsFalse(LMatrix.InverseFastSelf, 'singolare')
        else
          Assert.IsFalse(LMatrix.InverseSelf, 'singolare');
      finally
        LMatrix.Free;
      end;
    end;
  end;
end;

procedure TTestMatrixApi.TIdMatXDovrebbeEseguireLeVerifiche;
var
  LMatrix: TIdMatX;
begin
  LMatrix := TIdMatX.Create(3, 3);
  try
    LMatrix.Identity;
    Assert.IsTrue(LMatrix.IsIdentity);
    Assert.IsTrue(LMatrix.IsDiagonal);
    Assert.IsTrue(LMatrix.IsPMatrix);
    Assert.IsTrue(LMatrix.IsZMatrix);
    Assert.IsTrue(LMatrix.IsPositiveDefinite);
    Assert.IsTrue(LMatrix.IsPositiveSemiDefinite);
    LMatrix[0, 1] := 5.0;
    Assert.IsFalse(LMatrix.IsZMatrix, 'un elemento fuori diagonale positivo');
    LMatrix.ClearUpperTriangle;
    Assert.IsTrue(LMatrix.IsDiagonal);
    LMatrix[1, 1] := -1.0;
    Assert.IsFalse(LMatrix.IsPMatrix, 'minore negativo');
    Assert.IsFalse(LMatrix.IsPositiveDefinite);
    Assert.IsFalse(LMatrix.IsPositiveSemiDefinite);
    LMatrix.SetSize(2, 3);
    Assert.IsFalse(LMatrix.IsSymmetric);
    Assert.IsFalse(LMatrix.IsTriDiagonal);
    Assert.IsFalse(LMatrix.IsPMatrix);
    Assert.IsFalse(LMatrix.IsOrthogonal);
  finally
    LMatrix.Free;
  end;
end;

end.
