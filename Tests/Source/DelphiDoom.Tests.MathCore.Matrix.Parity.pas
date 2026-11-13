{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the matrices of MathCore - parity with the C++ idLib   }
{  (idMat2, idMat4, idMat5, idMat6, idMatX, idVec5, idVec6, idPolar3, idLCP)   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Matrix.Parity;

{$Q-}
{$R-}

interface

uses
  System.Classes, DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity with the real idlib\math of Doom 3 (Tests\Data\MathCore\matx.golden.txt: about
  ///   400 lines written by the C++ classes compiled with bcc32c on the x87, harness in
  ///   Tests\Data\MathCore\harness\matx). A line is "name inputs | outputs", with one ';name'
  ///   token before the answer of each operation; every line is recomputed from its inputs.
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMatrixParity = class(TObject)
  private
    FLines: TStringList;
    procedure Run(const APrefix: string; const AMaxUlps: Integer; const ARelative,
      AAbsolute: Single);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TIdMat2DovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdMat4DovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdMat5DovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdMat6DovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LeConversioniFraMatriciDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdVec5TIdVec6ETIdPolar3DovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdMatXDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LeModificheDiTIdMatXDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdMatXCholeskyDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdMatXLdltDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdMatXEigenETriDiagonalDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdLcpSquareDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdLcpSymmetricDovrebbeDareLeStesseRispostePerIlCpp;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Math.Vec4, DelphiDoom.MathCore.Float.Lcp.Factory,
  DelphiDoom.MathCore.Float.Lcp.Intf, DelphiDoom.MathCore.Float.Mat2,
  DelphiDoom.MathCore.Float.Mat3, DelphiDoom.MathCore.Float.Mat4, DelphiDoom.MathCore.Float.Mat5,
  DelphiDoom.MathCore.Float.Mat6, DelphiDoom.MathCore.Float.MatX,
  DelphiDoom.MathCore.Float.MatX.Cholesky, DelphiDoom.MathCore.Float.MatX.Inverse,
  DelphiDoom.MathCore.Float.MatX.Eigen, DelphiDoom.MathCore.Float.MatX.Ldlt,
  DelphiDoom.MathCore.Float.MatX.TriDiagonal, DelphiDoom.MathCore.Float.Polar3,
  DelphiDoom.MathCore.Float.Types, DelphiDoom.MathCore.Float.Vec5, DelphiDoom.MathCore.Float.Vec6,
  DelphiDoom.MathCore.Float.VecX, DelphiDoom.Tests.MathCore.Matrix.Lines;

const
  ScaleFactor: Single = 0.75;

procedure ComputeFixed2(const AFloats: TFloats; var ALine: string);
var
  LA, LB, LR: TIdMat2;
  LV, LVR: TIdVec2;
  LOk: Boolean;
begin
  Move(AFloats[0], LA, SizeOf(LA));
  Move(AFloats[4], LB, SizeOf(LB));
  Move(AFloats[8], LV, SizeOf(LV));
  TMatrixLines.Sep(ALine, 'F2_det');
  TMatrixLines.Put(ALine, LA.Determinant);
  LR := LA;
  LOk := LR.InverseSelf;
  TMatrixLines.Sep(ALine, 'F2_inv');
  TMatrixLines.PutFlag(ALine, LOk);
  TMatrixLines.PutFlat(ALine, @LR, 4);
  LR := LA;
  LOk := LR.InverseFastSelf;
  TMatrixLines.Sep(ALine, 'F2_invfast');
  TMatrixLines.PutFlag(ALine, LOk);
  TMatrixLines.PutFlat(ALine, @LR, 4);
  LR := LA.Transpose;
  TMatrixLines.Sep(ALine, 'F2_transpose');
  TMatrixLines.PutFlat(ALine, @LR, 4);
  LR := LA * LB;
  TMatrixLines.Sep(ALine, 'F2_mul');
  TMatrixLines.PutFlat(ALine, @LR, 4);
  LR := LA + LB;
  TMatrixLines.Sep(ALine, 'F2_add');
  TMatrixLines.PutFlat(ALine, @LR, 4);
  LR := LA - LB;
  TMatrixLines.Sep(ALine, 'F2_sub');
  TMatrixLines.PutFlat(ALine, @LR, 4);
  LR := LA * ScaleFactor;
  TMatrixLines.Sep(ALine, 'F2_scale');
  TMatrixLines.PutFlat(ALine, @LR, 4);
  LVR := LA * LV;
  TMatrixLines.Sep(ALine, 'F2_mulvec');
  TMatrixLines.PutFlat(ALine, @LVR, 2);
  TMatrixLines.Sep(ALine, 'F2_misc');
  TMatrixLines.Put(ALine, LA.Trace);
  TMatrixLines.PutFlag(ALine, LA.IsSymmetric);
  TMatrixLines.PutFlag(ALine, LA.IsDiagonal);
  TMatrixLines.PutFlag(ALine, LA.IsIdentity);
  TMatrixLines.PutFlag(ALine, LA = LB);
  TMatrixLines.PutFlag(ALine, LA.Compare(LB, 1.0));
  LR := LA;
  LR.TransposeSelf;
  TMatrixLines.Sep(ALine, 'F2_transposeself');
  TMatrixLines.PutFlat(ALine, @LR, 4);
end;

procedure ComputeFixed4(const AFloats: TFloats; var ALine: string);
var
  LA, LB, LR: TIdMat4;
  LV, LVR: TIdVec4;
  LOk: Boolean;
begin
  Move(AFloats[0], LA, SizeOf(LA));
  Move(AFloats[16], LB, SizeOf(LB));
  Move(AFloats[32], LV, SizeOf(LV));
  TMatrixLines.Sep(ALine, 'F4_det');
  TMatrixLines.Put(ALine, LA.Determinant);
  LR := LA;
  LOk := LR.InverseSelf;
  TMatrixLines.Sep(ALine, 'F4_inv');
  TMatrixLines.PutFlag(ALine, LOk);
  TMatrixLines.PutFlat(ALine, @LR, 16);
  LR := LA;
  LOk := LR.InverseFastSelf;
  TMatrixLines.Sep(ALine, 'F4_invfast');
  TMatrixLines.PutFlag(ALine, LOk);
  TMatrixLines.PutFlat(ALine, @LR, 16);
  LR := LA.Transpose;
  TMatrixLines.Sep(ALine, 'F4_transpose');
  TMatrixLines.PutFlat(ALine, @LR, 16);
  LR := LA * LB;
  TMatrixLines.Sep(ALine, 'F4_mul');
  TMatrixLines.PutFlat(ALine, @LR, 16);
  LR := LA + LB;
  TMatrixLines.Sep(ALine, 'F4_add');
  TMatrixLines.PutFlat(ALine, @LR, 16);
  LR := LA - LB;
  TMatrixLines.Sep(ALine, 'F4_sub');
  TMatrixLines.PutFlat(ALine, @LR, 16);
  LR := LA * ScaleFactor;
  TMatrixLines.Sep(ALine, 'F4_scale');
  TMatrixLines.PutFlat(ALine, @LR, 16);
  LVR := LA * LV;
  TMatrixLines.Sep(ALine, 'F4_mulvec');
  TMatrixLines.PutFlat(ALine, @LVR, 4);
  TMatrixLines.Sep(ALine, 'F4_misc');
  TMatrixLines.Put(ALine, LA.Trace);
  TMatrixLines.PutFlag(ALine, LA.IsSymmetric);
  TMatrixLines.PutFlag(ALine, LA.IsDiagonal);
  TMatrixLines.PutFlag(ALine, LA.IsIdentity);
  TMatrixLines.PutFlag(ALine, LA = LB);
  TMatrixLines.PutFlag(ALine, LA.Compare(LB, 1.0));
  LR := LA;
  LR.TransposeSelf;
  TMatrixLines.Sep(ALine, 'F4_transposeself');
  TMatrixLines.PutFlat(ALine, @LR, 16);
end;

procedure ComputeFixed5(const AFloats: TFloats; var ALine: string);
var
  LA, LB, LR: TIdMat5;
  LV, LVR: TIdVec5;
  LOk: Boolean;
begin
  Move(AFloats[0], LA, SizeOf(LA));
  Move(AFloats[25], LB, SizeOf(LB));
  Move(AFloats[50], LV, SizeOf(LV));
  TMatrixLines.Sep(ALine, 'F5_det');
  TMatrixLines.Put(ALine, LA.Determinant);
  LR := LA;
  LOk := LR.InverseSelf;
  TMatrixLines.Sep(ALine, 'F5_inv');
  TMatrixLines.PutFlag(ALine, LOk);
  TMatrixLines.PutFlat(ALine, @LR, 25);
  LR := LA;
  LOk := LR.InverseFastSelf;
  TMatrixLines.Sep(ALine, 'F5_invfast');
  TMatrixLines.PutFlag(ALine, LOk);
  TMatrixLines.PutFlat(ALine, @LR, 25);
  LR := LA.Transpose;
  TMatrixLines.Sep(ALine, 'F5_transpose');
  TMatrixLines.PutFlat(ALine, @LR, 25);
  LR := LA * LB;
  TMatrixLines.Sep(ALine, 'F5_mul');
  TMatrixLines.PutFlat(ALine, @LR, 25);
  LR := LA + LB;
  TMatrixLines.Sep(ALine, 'F5_add');
  TMatrixLines.PutFlat(ALine, @LR, 25);
  LR := LA - LB;
  TMatrixLines.Sep(ALine, 'F5_sub');
  TMatrixLines.PutFlat(ALine, @LR, 25);
  LR := LA * ScaleFactor;
  TMatrixLines.Sep(ALine, 'F5_scale');
  TMatrixLines.PutFlat(ALine, @LR, 25);
  LVR := LA * LV;
  TMatrixLines.Sep(ALine, 'F5_mulvec');
  TMatrixLines.PutFlat(ALine, @LVR, 5);
  TMatrixLines.Sep(ALine, 'F5_misc');
  TMatrixLines.Put(ALine, LA.Trace);
  TMatrixLines.PutFlag(ALine, LA.IsSymmetric);
  TMatrixLines.PutFlag(ALine, LA.IsDiagonal);
  TMatrixLines.PutFlag(ALine, LA.IsIdentity);
  TMatrixLines.PutFlag(ALine, LA = LB);
  TMatrixLines.PutFlag(ALine, LA.Compare(LB, 1.0));
  LR := LA;
  LR.TransposeSelf;
  TMatrixLines.Sep(ALine, 'F5_transposeself');
  TMatrixLines.PutFlat(ALine, @LR, 25);
end;

procedure ComputeFixed6(const AFloats: TFloats; var ALine: string);
var
  LA, LB, LR: TIdMat6;
  LV, LVR: TIdVec6;
  LOk: Boolean;
begin
  Move(AFloats[0], LA, SizeOf(LA));
  Move(AFloats[36], LB, SizeOf(LB));
  Move(AFloats[72], LV, SizeOf(LV));
  TMatrixLines.Sep(ALine, 'F6_det');
  TMatrixLines.Put(ALine, LA.Determinant);
  LR := LA;
  LOk := LR.InverseSelf;
  TMatrixLines.Sep(ALine, 'F6_inv');
  TMatrixLines.PutFlag(ALine, LOk);
  TMatrixLines.PutFlat(ALine, @LR, 36);
  LR := LA;
  LOk := LR.InverseFastSelf;
  TMatrixLines.Sep(ALine, 'F6_invfast');
  TMatrixLines.PutFlag(ALine, LOk);
  TMatrixLines.PutFlat(ALine, @LR, 36);
  LR := LA.Transpose;
  TMatrixLines.Sep(ALine, 'F6_transpose');
  TMatrixLines.PutFlat(ALine, @LR, 36);
  LR := LA * LB;
  TMatrixLines.Sep(ALine, 'F6_mul');
  TMatrixLines.PutFlat(ALine, @LR, 36);
  LR := LA + LB;
  TMatrixLines.Sep(ALine, 'F6_add');
  TMatrixLines.PutFlat(ALine, @LR, 36);
  LR := LA - LB;
  TMatrixLines.Sep(ALine, 'F6_sub');
  TMatrixLines.PutFlat(ALine, @LR, 36);
  LR := LA * ScaleFactor;
  TMatrixLines.Sep(ALine, 'F6_scale');
  TMatrixLines.PutFlat(ALine, @LR, 36);
  LVR := LA * LV;
  TMatrixLines.Sep(ALine, 'F6_mulvec');
  TMatrixLines.PutFlat(ALine, @LVR, 6);
  TMatrixLines.Sep(ALine, 'F6_misc');
  TMatrixLines.Put(ALine, LA.Trace);
  TMatrixLines.PutFlag(ALine, LA.IsSymmetric);
  TMatrixLines.PutFlag(ALine, LA.IsDiagonal);
  TMatrixLines.PutFlag(ALine, LA.IsIdentity);
  TMatrixLines.PutFlag(ALine, LA = LB);
  TMatrixLines.PutFlag(ALine, LA.Compare(LB, 1.0));
  LR := LA;
  LR.TransposeSelf;
  TMatrixLines.Sep(ALine, 'F6_transposeself');
  TMatrixLines.PutFlat(ALine, @LR, 36);
end;

procedure ComputeBlocks(const AFloats: TFloats; var ALine: string);
var
  LM: array[0..3] of TIdMat3;
  LMat6: TIdMat6;
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
  begin
    Move(AFloats[LIndex * 9], LM[LIndex], SizeOf(TIdMat3));
  end;
  LMat6 := TIdMat6.Create(LM[0], LM[1], LM[2], LM[3]);
  TMatrixLines.PutFlat(ALine, @LMat6, 36);
  for LIndex := 0 to 3 do
  begin
    LM[0] := LMat6.SubMat3(LIndex);
    TMatrixLines.PutFlat(ALine, @LM[0], 9);
  end;
end;

procedure ComputeRotationTranslation(const AFloats: TFloats; var ALine: string);
var
  LM0: TIdMat3;
  LMat4: TIdMat4;
begin
  Move(AFloats[0], LM0, SizeOf(LM0));
  LMat4 := TIdMat4.Create(LM0, TIdVec3.Create(AFloats[0], AFloats[10], AFloats[20]));
  TMatrixLines.PutFlat(ALine, @LMat4, 16);
  LMat4 := TIdMat4.FromMat3(LM0);
  TMatrixLines.PutFlat(ALine, @LMat4, 16);
end;

procedure ComputeMultiplyVec3(const AFloats: TFloats; var ALine: string);
var
  LMat4: TIdMat4;
  LVec3, LResult3: TIdVec3;
  LVec4, LProjected, LUnprojected: TIdVec4;
begin
  Move(AFloats[0], LMat4, SizeOf(LMat4));
  LVec3 := TIdVec3.Create(AFloats[16], AFloats[17], AFloats[18]);
  LResult3 := LMat4 * LVec3;
  TMatrixLines.PutFlat(ALine, @LResult3, 3);
  LVec4 := TIdVec4.Create(AFloats[16], AFloats[17], AFloats[18], 1.0);
  LMat4.ProjectVector(LVec4, LProjected);
  LMat4.UnprojectVector(LVec4, LUnprojected);
  TMatrixLines.PutFlat(ALine, @LProjected, 4);
  TMatrixLines.PutFlat(ALine, @LUnprojected, 4);
  TMatrixLines.PutFlag(ALine, LMat4.IsRotated);
end;

procedure ComputeVec6Operations(const AFloats: TFloats; var ALine: string);
var
  LA, LB, LR: TIdVec6;
begin
  Move(AFloats[0], LA, SizeOf(LA));
  Move(AFloats[6], LB, SizeOf(LB));
  LR := LA + LB;
  TMatrixLines.PutFlat(ALine, @LR, 6);
  LR := LA - LB;
  TMatrixLines.PutFlat(ALine, @LR, 6);
  LR := -LA;
  TMatrixLines.PutFlat(ALine, @LR, 6);
  LR := LA * 1.25;
  TMatrixLines.PutFlat(ALine, @LR, 6);
  LR := LA / 3.0;
  TMatrixLines.PutFlat(ALine, @LR, 6);
  TMatrixLines.Put(ALine, LA * LB);
  TMatrixLines.Put(ALine, LA.Length);
  TMatrixLines.Put(ALine, LA.LengthSqr);
  TMatrixLines.PutFlag(ALine, LA = LB);
  TMatrixLines.PutFlag(ALine, LA.Compare(LB, 4.0));
end;

procedure ComputeVec6Normalize(const AFloats: TFloats; var ALine: string);
var
  LA, LR: TIdVec6;
begin
  Move(AFloats[0], LA, SizeOf(LA));
  LR := LA;
  TMatrixLines.Put(ALine, LR.Normalize);
  TMatrixLines.PutFlat(ALine, @LR, 6);
  LR := LA;
  TMatrixLines.Put(ALine, LR.NormalizeFast);
  TMatrixLines.PutFlat(ALine, @LR, 6);
end;

procedure ComputeVec5Lerp(const AFloats: TFloats; var ALine: string);
var
  LP, LQ, LR: TIdVec5;
begin
  LP := TIdVec5.Create(AFloats[0], AFloats[1], AFloats[2], AFloats[3], AFloats[4]);
  LQ := TIdVec5.Create(AFloats[6], AFloats[7], AFloats[8], AFloats[9], AFloats[10]);
  LR.Lerp(LP, LQ, AFloats[12]);
  TMatrixLines.PutFlat(ALine, @LR, 5);
end;

procedure ComputePolar3(const AFloats: TFloats; var ALine: string);
var
  LPolar, LNegated: TIdPolar3;
  LVector: TIdVec3;
begin
  LPolar := TIdPolar3.Create(System.Abs(AFloats[0]) + 0.1, AFloats[1], AFloats[2]);
  LVector := LPolar.ToVec3;
  TMatrixLines.PutFlat(ALine, @LVector, 3);
  LNegated := -LPolar;
  LVector := LNegated.ToVec3;
  TMatrixLines.PutFlat(ALine, @LVector, 3);
end;

procedure ComputeMatX(const AFloats: TFloats; var ALine: string);
var
  LN, LIndex, LRow: Integer;
  LA, LT, LInverse, LL, LU, LBack, LSquare, LTransposed: TIdMatX;
  LB, LX, LResult, LAccumulator: TIdVecX;
  LOrder: TArray<Integer>;
  LDeterminant: Single;
  LOk: Boolean;
begin
  LN := Round(AFloats[0]);
  LA := TIdMatX.Create;
  LT := TIdMatX.Create;
  LInverse := TIdMatX.Create;
  LL := TIdMatX.Create;
  LU := TIdMatX.Create;
  LBack := TIdMatX.Create;
  LB := TIdVecX.Create(LN);
  LX := TIdVecX.Create(LN);
  LResult := TIdVecX.Create(LN);
  LAccumulator := TIdVecX.Create(LN);
  try
    LA.SetValues(LN, LN, PIdSingleArray(@AFloats[1]));
    for LIndex := 0 to LN - 1 do
    begin
      LB[LIndex] := AFloats[1 + LN * LN + LIndex];
    end;
    TMatrixLines.Sep(ALine, 'X_det');
    TMatrixLines.Put(ALine, LA.Determinant);
    LT.Assign(LA);
    LOk := LT.InverseSelf;
    TMatrixLines.Sep(ALine, 'X_inv');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LT);
    LT.Assign(LA);
    LOk := TIdMatXInverse.GaussJordan(LT);
    TMatrixLines.Sep(ALine, 'X_gj');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LT);
    SetLength(LOrder, LN);
    LDeterminant := 0.0;
    LT.Assign(LA);
    LOk := LT.LuFactor(PIdIntegerArray(LOrder), @LDeterminant);
    TMatrixLines.Sep(ALine, 'X_lu');
    TMatrixLines.PutFlag(ALine, LOk);
    if LOk then
    begin
      TMatrixLines.Put(ALine, LDeterminant);
      TMatrixLines.PutMatX(ALine, LT);
      for LIndex := 0 to LN - 1 do
      begin
        TMatrixLines.PutInt(ALine, LOrder[LIndex]);
      end;
      LT.LuSolve(LX, LB, PIdIntegerArray(LOrder));
      TMatrixLines.PutVecX(ALine, LX);
      LT.LuInverse(LInverse, PIdIntegerArray(LOrder));
      TMatrixLines.PutMatX(ALine, LInverse);
      LT.LuUnpackFactors(LL, LU);
      TMatrixLines.PutMatX(ALine, LL);
      TMatrixLines.PutMatX(ALine, LU);
      LT.LuMultiplyFactors(LBack, PIdIntegerArray(LOrder));
      TMatrixLines.PutMatX(ALine, LBack);
    end;
    LT.Assign(LA);
    LOk := LT.LuFactor(nil, @LDeterminant);
    TMatrixLines.Sep(ALine, 'X_lunp');
    TMatrixLines.PutFlag(ALine, LOk);
    if LOk then
    begin
      TMatrixLines.Put(ALine, LDeterminant);
      TMatrixLines.PutMatX(ALine, LT);
    end;
    LT.Assign(LA);
    LOk := LT.LowerTriangularInverse;
    TMatrixLines.Sep(ALine, 'X_lowinv');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LT);
    LT.Assign(LA);
    LOk := LT.UpperTriangularInverse;
    TMatrixLines.Sep(ALine, 'X_upinv');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LT);
    LA.Multiply(LResult, LB);
    TMatrixLines.Sep(ALine, 'X_mulvec');
    TMatrixLines.PutVecX(ALine, LResult);
    LA.TransposeMultiply(LResult, LB);
    TMatrixLines.PutVecX(ALine, LResult);
    for LRow := 0 to LN - 1 do
    begin
      LAccumulator[LRow] := 1.0;
    end;
    LA.MultiplyAdd(LAccumulator, LB);
    TMatrixLines.PutVecX(ALine, LAccumulator);
    LA.MultiplySub(LAccumulator, LB);
    TMatrixLines.PutVecX(ALine, LAccumulator);
    LA.TransposeMultiplyAdd(LAccumulator, LB);
    TMatrixLines.PutVecX(ALine, LAccumulator);
    LA.TransposeMultiplySub(LAccumulator, LB);
    TMatrixLines.PutVecX(ALine, LAccumulator);
    LSquare := LA.Multiply(LA);
    try
      TMatrixLines.PutMatX(ALine, LSquare);
    finally
      LSquare.Free;
    end;
    LSquare := LA.TransposeMultiply(LA);
    try
      TMatrixLines.PutMatX(ALine, LSquare);
    finally
      LSquare.Free;
    end;
    LTransposed := LA.Transpose;
    try
      TMatrixLines.PutMatX(ALine, LTransposed);
      TMatrixLines.Sep(ALine, 'X_is');
      TMatrixLines.PutFlag(ALine, LA.IsSquare);
      TMatrixLines.PutFlag(ALine, LA.IsZero);
      TMatrixLines.PutFlag(ALine, LA.IsDiagonal);
      TMatrixLines.PutFlag(ALine, LA.IsTriDiagonal);
      TMatrixLines.PutFlag(ALine, LA.IsSymmetric);
      TMatrixLines.PutFlag(ALine, LA.IsPMatrix(1E-6));
      TMatrixLines.PutFlag(ALine, LA.IsZMatrix);
      TMatrixLines.PutFlag(ALine, LA.IsPositiveDefinite);
      TMatrixLines.PutFlag(ALine, TIdMatXCholesky.IsSymmetricPositiveDefinite(LA));
      TMatrixLines.PutFlag(ALine, LA.IsPositiveSemiDefinite);
      TMatrixLines.PutFlag(ALine, TIdMatXCholesky.IsSymmetricPositiveSemiDefinite(LA));
      TMatrixLines.PutFlag(ALine, LA.IsOrthogonal);
      TMatrixLines.PutFlag(ALine, LA.IsOrthonormal);
      TMatrixLines.Put(ALine, LA.Trace);
      TMatrixLines.Put(ALine, LA.MaxDifference(LTransposed));
    finally
      LTransposed.Free;
    end;
  finally
    LAccumulator.Free;
    LResult.Free;
    LX.Free;
    LB.Free;
    LBack.Free;
    LU.Free;
    LL.Free;
    LInverse.Free;
    LT.Free;
    LA.Free;
  end;
end;

function VectorOf(const AFloats: TFloats; const AStart, ASize: Integer): TIdVecX;
var
  LIndex: Integer;
begin
  Result := TIdVecX.Create(ASize);
  for LIndex := 0 to ASize - 1 do
  begin
    Result[LIndex] := AFloats[AStart + LIndex];
  end;
end;

procedure ComputeMatXShape(const AFloats: TFloats; var ALine: string);
var
  LN, LRow, LK: Integer;
  LM, LT, LSub, LInverse, LU, LD: TIdMatX;
  LV, LW, LV1, LW1: TIdVecX;
  LOk: Boolean;
begin
  LN := Round(AFloats[0]);
  LK := 1 + 2 * LN * LN;
  LRow := Round(AFloats[LK]);
  LM := TIdMatX.Create;
  LT := TIdMatX.Create;
  LSub := TIdMatX.Create;
  LInverse := TIdMatX.Create;
  LU := TIdMatX.Create;
  LD := TIdMatX.Create;
  LV := VectorOf(AFloats, LK + 1, LN);
  LW := VectorOf(AFloats, LK + 1 + LN, LN);
  LV1 := VectorOf(AFloats, LK + 1 + 2 * LN, LN + 1);
  LW1 := VectorOf(AFloats, LK + 1 + 3 * LN + 1, LN + 1);
  try
    LM.SetValues(LN, LN, PIdSingleArray(@AFloats[1]));
    LD.SetValues(LN, LN, PIdSingleArray(@AFloats[1 + LN * LN]));
    LT.Assign(LM);
    LT.RemoveRow(LRow);
    TMatrixLines.Sep(ALine, 'X_remrow');
    TMatrixLines.PutMatX(ALine, LT);
    LT.Assign(LM);
    LT.RemoveColumn(LRow);
    TMatrixLines.Sep(ALine, 'X_remcol');
    TMatrixLines.PutMatX(ALine, LT);
    LT.Assign(LM);
    LT.RemoveRowColumn(LRow);
    TMatrixLines.Sep(ALine, 'X_remrc');
    TMatrixLines.PutMatX(ALine, LT);
    LT.Assign(LM);
    LT.ChangeSize(LN + 2, LN + 1, True);
    TMatrixLines.Sep(ALine, 'X_grow');
    TMatrixLines.PutMatX(ALine, LT);
    LT.Assign(LM);
    LT.ChangeSize(LN - 1, LN - 1, False);
    TMatrixLines.Sep(ALine, 'X_shrink');
    TMatrixLines.PutMatX(ALine, LT);
    LT.Assign(LM);
    LT.SwapRows(0, LRow);
    LT.SwapColumns(1, LRow);
    TMatrixLines.Sep(ALine, 'X_swap');
    TMatrixLines.PutMatX(ALine, LT);
    LT.Assign(LM);
    LT.ClearUpperTriangle;
    TMatrixLines.Sep(ALine, 'X_clrup');
    TMatrixLines.PutMatX(ALine, LT);
    LT.Assign(LM);
    LT.ClearLowerTriangle;
    TMatrixLines.Sep(ALine, 'X_clrlow');
    TMatrixLines.PutMatX(ALine, LT);
    LSub.SquareSubMatrix(LM, LN - 1);
    TMatrixLines.Sep(ALine, 'X_sub');
    TMatrixLines.PutMatX(ALine, LSub);
    LT.Assign(LM);
    LT.UpdateRankOne(LV, LW, 0.5);
    TMatrixLines.Sep(ALine, 'X_updr1');
    TMatrixLines.PutMatX(ALine, LT);
    LT.Assign(LM);
    LT.UpdateRankOneSymmetric(LV, -0.25);
    TMatrixLines.Sep(ALine, 'X_updr1s');
    TMatrixLines.PutMatX(ALine, LT);
    LT.Assign(LM);
    LT.UpdateRowColumn(LV, LW, LRow);
    TMatrixLines.Sep(ALine, 'X_updrc');
    TMatrixLines.PutMatX(ALine, LT);
    LT.Assign(LM);
    LT.UpdateRowColumnSymmetric(LV, LRow);
    TMatrixLines.Sep(ALine, 'X_updrcs');
    TMatrixLines.PutMatX(ALine, LT);
    LT.Assign(LM);
    LT.UpdateIncrement(LV1, LW1);
    TMatrixLines.Sep(ALine, 'X_updinc');
    TMatrixLines.PutMatX(ALine, LT);
    LT.Assign(LM);
    LT.UpdateIncrementSymmetric(LV1);
    TMatrixLines.Sep(ALine, 'X_updincs');
    TMatrixLines.PutMatX(ALine, LT);
    LT.Assign(LD);
    LT.InverseSelf;
    LInverse.Assign(LT);
    LU.Assign(LInverse);
    LOk := TIdMatXInverse.UpdateRankOne(LU, LV, LW, 0.5);
    TMatrixLines.Sep(ALine, 'X_invupd1');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LU);
    LU.Assign(LInverse);
    LOk := TIdMatXInverse.UpdateRowColumn(LU, LV, LW, LRow);
    TMatrixLines.Sep(ALine, 'X_invupdrc');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LU);
    LU.Assign(LInverse);
    LOk := TIdMatXInverse.UpdateDecrement(LU, LV, LW, LRow);
    TMatrixLines.Sep(ALine, 'X_invupddec');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LU);
    LU.Assign(LInverse);
    LOk := TIdMatXInverse.UpdateIncrement(LU, LV1, LW1);
    TMatrixLines.Sep(ALine, 'X_invupdinc');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LU);
  finally
    LW1.Free;
    LV1.Free;
    LW.Free;
    LV.Free;
    LD.Free;
    LU.Free;
    LInverse.Free;
    LSub.Free;
    LT.Free;
    LM.Free;
  end;
end;

procedure ComputeEigen(const AFloats: TFloats; var ALine: string);
var
  LN: Integer;
  LM, LT, LTri, LInverse: TIdMatX;
  LB, LX, LEigenValues: TIdVecX;
  LOk: Boolean;
begin
  LN := Round(AFloats[0]);
  LM := TIdMatX.Create;
  LT := TIdMatX.Create;
  LTri := TIdMatX.Create;
  LInverse := TIdMatX.Create;
  LB := VectorOf(AFloats, 1 + LN * LN, LN);
  LX := TIdVecX.Create(LN);
  LEigenValues := TIdVecX.Create;
  try
    LM.SetValues(LN, LN, PIdSingleArray(@AFloats[1]));
    LT.Assign(LM);
    LOk := TIdMatXEigen.SolveSymmetric(LT, LEigenValues);
    TMatrixLines.Sep(ALine, 'X_eig');
    TMatrixLines.PutFlag(ALine, LOk);
    if LOk then
    begin
      // the order in which QL finds the eigenvalues depends on the rounding: only the sorted ones are compared
      TIdMatXEigen.SortIncreasing(LT, LEigenValues);
      TMatrixLines.PutVecX(ALine, LEigenValues);
      TMatrixLines.PutEigen(ALine, LT);
      TIdMatXEigen.SortDecreasing(LT, LEigenValues);
      TMatrixLines.PutVecX(ALine, LEigenValues);
      TMatrixLines.PutEigen(ALine, LT);
    end;
    LTri.Assign(LM);
    TIdMatXTriDiagonal.ClearTriangles(LTri);
    TMatrixLines.Sep(ALine, 'X_tri');
    TMatrixLines.PutMatX(ALine, LTri);
    LOk := TIdMatXTriDiagonal.Solve(LTri, LX, LB);
    TMatrixLines.PutFlag(ALine, LOk);
    if LOk then
      TMatrixLines.PutVecX(ALine, LX);
    TIdMatXTriDiagonal.Inverse(LTri, LInverse);
    TMatrixLines.Sep(ALine, 'X_triinv');
    TMatrixLines.PutMatX(ALine, LInverse);
    LT.Assign(LTri);
    LOk := TIdMatXEigen.SolveSymmetricTriDiagonal(LT, LEigenValues);
    TMatrixLines.Sep(ALine, 'X_eigtri');
    TMatrixLines.PutFlag(ALine, LOk);
    if LOk then
    begin
      TIdMatXEigen.SortIncreasing(LT, LEigenValues);
      TMatrixLines.PutVecX(ALine, LEigenValues);
      TMatrixLines.PutEigen(ALine, LT);
    end;
  finally
    LEigenValues.Free;
    LX.Free;
    LB.Free;
    LInverse.Free;
    LTri.Free;
    LT.Free;
    LM.Free;
  end;
end;

/// <summary>The lines XC_all (Cholesky) and XL_all (LDL')</summary>
procedure ComputeFactorization(const AFloats: TFloats; const ALdlt: Boolean; var ALine: string);
var
  LN, LRow, LOffset: Integer;
  LAlpha: Single;
  LM, LF, LInverse, LBack, LL, LD, LU: TIdMatX;
  LB, LX, LVector, LVector1: TIdVecX;
  LOk: Boolean;
  LName: string;
begin
  LN := Round(AFloats[0]);
  LRow := Round(AFloats[1 + LN * LN + LN + LN + 1]);
  LAlpha := AFloats[1 + LN * LN + LN + LN + 2];
  if ALdlt then
    LName := 'X_ldlt'
  else
    LName := 'X_chol';
  LM := TIdMatX.Create;
  LF := TIdMatX.Create;
  LInverse := TIdMatX.Create;
  LBack := TIdMatX.Create;
  LL := TIdMatX.Create;
  LD := TIdMatX.Create;
  LU := TIdMatX.Create;
  LB := VectorOf(AFloats, 1 + LN * LN, LN);
  LX := TIdVecX.Create(LN);
  LVector1 := VectorOf(AFloats, 1 + LN * LN + LN, LN + 1);
  LVector := VectorOf(AFloats, 1 + LN * LN + LN, LN);
  try
    LM.SetValues(LN, LN, PIdSingleArray(@AFloats[1]));
    LF.Assign(LM);
    if ALdlt then
      LOk := TIdMatXLdlt.Factor(LF)
    else
      LOk := TIdMatXCholesky.Factor(LF);
    TMatrixLines.Sep(ALine, LName);
    TMatrixLines.PutFlag(ALine, LOk);
    if not LOk then
      Exit;
    TMatrixLines.PutMatX(ALine, LF);
    if ALdlt then
    begin
      TIdMatXLdlt.Solve(LF, LX, LB);
      TMatrixLines.PutVecX(ALine, LX);
      TIdMatXLdlt.Inverse(LF, LInverse);
      TMatrixLines.PutMatX(ALine, LInverse);
      TIdMatXLdlt.MultiplyFactors(LF, LBack);
      TMatrixLines.PutMatX(ALine, LBack);
      TIdMatXLdlt.UnpackFactors(LF, LL, LD);
      TMatrixLines.PutMatX(ALine, LL);
      TMatrixLines.PutMatX(ALine, LD);
    end
    else
    begin
      TIdMatXCholesky.Solve(LF, LX, LB);
      TMatrixLines.PutVecX(ALine, LX);
      TIdMatXCholesky.Inverse(LF, LInverse);
      TMatrixLines.PutMatX(ALine, LInverse);
      TIdMatXCholesky.MultiplyFactors(LF, LBack);
      TMatrixLines.PutMatX(ALine, LBack);
    end;
    LU.Assign(LF);
    if ALdlt then
      LOk := TIdMatXLdlt.UpdateRankOne(LU, LVector, LAlpha, 0)
    else
      LOk := TIdMatXCholesky.UpdateRankOne(LU, LVector, LAlpha, 0);
    TMatrixLines.Sep(ALine, LName + 'r1');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LU);
    if LN > 1 then
    begin
      LOffset := LRow mod LN;
      LU.Assign(LF);
      if ALdlt then
        LOk := TIdMatXLdlt.UpdateRankOne(LU, LVector, LAlpha, LOffset)
      else
        LOk := TIdMatXCholesky.UpdateRankOne(LU, LVector, LAlpha, LOffset);
      TMatrixLines.Sep(ALine, LName + 'r1o');
      TMatrixLines.PutFlag(ALine, LOk);
      TMatrixLines.PutMatX(ALine, LU);
    end;
    LU.Assign(LF);
    if ALdlt then
      LOk := TIdMatXLdlt.UpdateRowColumn(LU, LVector, LRow)
    else
      LOk := TIdMatXCholesky.UpdateRowColumn(LU, LVector, LRow);
    TMatrixLines.Sep(ALine, LName + 'rc');
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutMatX(ALine, LU);
    LU.Assign(LF);
    if ALdlt then
      LOk := TIdMatXLdlt.UpdateIncrement(LU, LVector1)
    else
      LOk := TIdMatXCholesky.UpdateIncrement(LU, LVector1);
    TMatrixLines.Sep(ALine, LName + 'inc');
    TMatrixLines.PutFlag(ALine, LOk);
    // after a failed update the C++ leaves the new diagonal entry uninitialized
    if LOk then
      TMatrixLines.PutLower(ALine, LU);
    if LN > 1 then
    begin
      LU.Assign(LF);
      if ALdlt then
        LOk := TIdMatXLdlt.UpdateDecrement(LU, LVector, LRow)
      else
        LOk := TIdMatXCholesky.UpdateDecrement(LU, LVector, LRow);
      TMatrixLines.Sep(ALine, LName + 'dec');
      TMatrixLines.PutFlag(ALine, LOk);
      TMatrixLines.PutMatX(ALine, LU);
    end;
  finally
    LVector.Free;
    LVector1.Free;
    LX.Free;
    LB.Free;
    LU.Free;
    LD.Free;
    LL.Free;
    LBack.Free;
    LInverse.Free;
    LF.Free;
    LM.Free;
  end;
end;

procedure ComputeLcp(const AFloats: TFloats; const ASymmetric: Boolean; var ALine: string);
var
  LN, LIndex, LStart: Integer;
  LMatrix: TIdMatX;
  LX, LB, LLow, LHigh: TIdVecX;
  LBox: TArray<Integer>;
  LSolver: IIdLcp;
  LBoxed, LOk, LUnchanged: Boolean;
  LBefore: TArray<Single>;
begin
  LN := Round(AFloats[0]);
  LMatrix := TIdMatX.Create;
  LX := TIdVecX.Create(LN);
  LB := VectorOf(AFloats, 1 + LN * LN, LN);
  LLow := VectorOf(AFloats, 1 + LN * LN + LN, LN);
  LHigh := VectorOf(AFloats, 1 + LN * LN + 2 * LN, LN);
  try
    LMatrix.SetValues(LN, LN, PIdSingleArray(@AFloats[1]));
    LStart := 1 + LN * LN + 3 * LN;
    SetLength(LBox, LN);
    LBoxed := False;
    for LIndex := 0 to LN - 1 do
    begin
      LBox[LIndex] := Round(AFloats[LStart + LIndex]);
      if LBox[LIndex] >= 0 then
        LBoxed := True;
    end;
    if not LBoxed then
      SetLength(LBox, 0);
    SetLength(LBefore, LN * LN);
    for LIndex := 0 to LN * LN - 1 do
    begin
      LBefore[LIndex] := LMatrix.Data^[LIndex];
    end;
    LX.Zero;
    if ASymmetric then
      LSolver := TIdLcpFactory.AllocSymmetric
    else
      LSolver := TIdLcpFactory.AllocSquare;
    LOk := LSolver.Solve(LMatrix, LX, LB, LLow, LHigh, LBox);
    TMatrixLines.PutFlag(ALine, LBoxed);
    TMatrixLines.PutFlag(ALine, LOk);
    TMatrixLines.PutVecX(ALine, LX);
    LUnchanged := True;
    for LIndex := 0 to LN * LN - 1 do
    begin
      if LBefore[LIndex] <> LMatrix.Data^[LIndex] then
        LUnchanged := False;
    end;
    TMatrixLines.PutFlag(ALine, LUnchanged);
  finally
    LHigh.Free;
    LLow.Free;
    LB.Free;
    LX.Free;
    LMatrix.Free;
  end;
end;

{ TTestMatrixParity }

procedure TTestMatrixParity.Setup;
begin
  FLines := TStringList.Create;
  FLines.LoadFromFile(TMatrixLines.DataPath('matx.golden.txt'));
end;

procedure TTestMatrixParity.TearDown;
begin
  FLines.Free;
end;

procedure TTestMatrixParity.Run(const APrefix: string; const AMaxUlps: Integer;
  const ARelative, AAbsolute: Single);
var
  LIndex: Integer;
  LName, LLine: string;
  LFloats: TFloats;
  LActual, LExpected: TStringList;
begin
  LActual := TStringList.Create;
  LExpected := TStringList.Create;
  try
    for LIndex := 0 to FLines.Count - 1 do
    begin
      if not FLines[LIndex].StartsWith(APrefix + ' ') then
        Continue;
      LFloats := TMatrixLines.ParseInputs(FLines[LIndex], LName);
      LLine := TMatrixLines.HeadOf(FLines[LIndex]);
      if LName = 'F2_all' then
        ComputeFixed2(LFloats, LLine)
      else if LName = 'F4_all' then
        ComputeFixed4(LFloats, LLine)
      else if LName = 'F5_all' then
        ComputeFixed5(LFloats, LLine)
      else if LName = 'F6_all' then
        ComputeFixed6(LFloats, LLine)
      else if LName = 'F6_blocks' then
        ComputeBlocks(LFloats, LLine)
      else if LName = 'F4_rt' then
        ComputeRotationTranslation(LFloats, LLine)
      else if LName = 'F4_mulvec3' then
        ComputeMultiplyVec3(LFloats, LLine)
      else if LName = 'V6_ops' then
        ComputeVec6Operations(LFloats, LLine)
      else if LName = 'V6_norm' then
        ComputeVec6Normalize(LFloats, LLine)
      else if LName = 'V5_lerp' then
        ComputeVec5Lerp(LFloats, LLine)
      else if LName = 'P3_tovec3' then
        ComputePolar3(LFloats, LLine)
      else if LName = 'X_all' then
        ComputeMatX(LFloats, LLine)
      else if LName = 'XS_all' then
        ComputeMatXShape(LFloats, LLine)
      else if LName = 'XC_all' then
        ComputeFactorization(LFloats, False, LLine)
      else if LName = 'XL_all' then
        ComputeFactorization(LFloats, True, LLine)
      else if LName = 'XE_all' then
        ComputeEigen(LFloats, LLine)
      else if LName = 'LCP_sq' then
        ComputeLcp(LFloats, False, LLine)
      else if LName = 'LCP_sym' then
        ComputeLcp(LFloats, True, LLine)
      else
        Assert.Fail('operazione sconosciuta ' + LName);
      LActual.Add(LLine);
      LExpected.Add(FLines[LIndex]);
    end;
    Assert.IsTrue(LExpected.Count > 0, 'nessuna riga nel golden per ' + APrefix);
    TMatrixLines.CompareLines(LExpected, LActual, AMaxUlps, ARelative, AAbsolute);
  finally
    LExpected.Free;
    LActual.Free;
  end;
end;

procedure TTestMatrixParity.TIdMat2DovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('F2_all', 2, 4E-6, 0);
end;

procedure TTestMatrixParity.TIdMat4DovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('F4_all', 2, 4E-6, 0);
end;

procedure TTestMatrixParity.TIdMat5DovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('F5_all', 2, 5E-5, 0);
end;

procedure TTestMatrixParity.TIdMat6DovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('F6_all', 2, 5E-5, 0);
end;

procedure TTestMatrixParity.LeConversioniFraMatriciDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run('F6_blocks', 2, 4E-6, 0);
  Run('F4_rt', 2, 4E-6, 0);
  Run('F4_mulvec3', 2, 4E-6, 0);
end;

procedure TTestMatrixParity.TIdVec5TIdVec6ETIdPolar3DovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run('V6_ops', 2, 4E-6, 0);
  Run('V6_norm', 2, 4E-6, 0);
  Run('V5_lerp', 2, 4E-6, 0);
  Run('P3_tovec3', 2, 4E-6, 0);
end;

procedure TTestMatrixParity.TIdMatXDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('X_all', 2, 1E-4, 1E-5);
end;

procedure TTestMatrixParity.LeModificheDiTIdMatXDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run('XS_all', 2, 1E-4, 1E-5);
end;

procedure TTestMatrixParity.TIdMatXCholeskyDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('XC_all', 2, 1E-4, 1E-5);
end;

procedure TTestMatrixParity.TIdMatXLdltDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('XL_all', 2, 1E-4, 1E-5);
end;

procedure TTestMatrixParity.TIdMatXEigenETriDiagonalDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run('XE_all', 2, 1E-4, 1E-5);
end;

procedure TTestMatrixParity.TIdLcpSquareDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('LCP_sq', 2, 1E-4, 1E-5);
end;

procedure TTestMatrixParity.TIdLcpSymmetricDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run('LCP_sym', 2, 1E-4, 1E-5);
end;

end.
