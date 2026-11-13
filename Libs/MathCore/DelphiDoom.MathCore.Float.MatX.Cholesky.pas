{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdMatXCholesky, the Cholesky       }
{  factorization                                                               }
{                                                                              }
{  Port of the Cholesky_* members of idMatX (idlib\math\Matrix.cpp) of the     }
{  Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a          }
{  ZeniMax Media company. Based on the Doom 3 GPL Source Code (id Software).   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.MatX.Cholesky;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Mat3, DelphiDoom.MathCore.Float.MatX, DelphiDoom.MathCore.Float.VecX;

type
  /// <summary>
  ///   The Cholesky factorization LL' of a symmetric positive definite matrix, in place (the
  ///   <c>Cholesky_*</c> members of idMatX): L in the lower triangle, the upper one is not
  ///   cleared. Also the two tests of idMatX that need it (<c>IsSymmetricPositiveDefinite</c>,
  ///   <c>IsSymmetricPositiveSemiDefinite</c>), which cannot be members of <c>TIdMatX</c>
  ///   because the units would depend on each other.
  /// </summary>
  TIdMatXCholesky = class sealed
  public
    /// <summary>False if the matrix is not positive definite</summary>
    class function Factor(const AMatrix: TIdMatX): Boolean; static;
    class function UpdateRankOne(const AMatrix: TIdMatX; const AV: TIdVecX; AAlpha: Single;
      const AOffset: Integer = 0): Boolean; static;
    class function UpdateRowColumn(const AMatrix: TIdMatX; const AV: TIdVecX;
      const ARow: Integer): Boolean; static;
    class function UpdateIncrement(const AMatrix: TIdMatX; const AV: TIdVecX): Boolean; static;
    class function UpdateDecrement(const AMatrix: TIdMatX; const AV: TIdVecX;
      const ARow: Integer): Boolean; static;
    class procedure Solve(const AMatrix: TIdMatX; const AX, AB: TIdVecX); static;
    class procedure Inverse(const AMatrix: TIdMatX; const AInverse: TIdMatX); static;
    class procedure MultiplyFactors(const AMatrix: TIdMatX; const AResult: TIdMatX); static;
    /// <summary>idMatX::IsSymmetricPositiveDefinite: symmetric and Cholesky succeeds on a copy</summary>
    class function IsSymmetricPositiveDefinite(const AMatrix: TIdMatX;
      const AEpsilon: Single = MAT_EPSILON): Boolean; static;
    class function IsSymmetricPositiveSemiDefinite(const AMatrix: TIdMatX;
      const AEpsilon: Single = MAT_EPSILON): Boolean; static;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.MathCore.Float.Types;

{ TIdMatXCholesky }

class function TIdMatXCholesky.Factor(const AMatrix: TIdMatX): Boolean;
var
  LRows, LI, LJ, LK: Integer;
  LInvSqrt: TArray<Single>;
  LData: PIdSingleArray;
  LSum: Double;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  LRows := AMatrix.NumRows;
  LData := AMatrix.Data;
  SetLength(LInvSqrt, LRows);
  for LI := 0 to LRows - 1 do
  begin
    for LJ := 0 to LI - 1 do
    begin
      LSum := LData^[LI * LRows + LJ];
      for LK := 0 to LJ - 1 do
      begin
        LSum := LSum - LData^[LI * LRows + LK] * LData^[LJ * LRows + LK];
      end;
      LData^[LI * LRows + LJ] := LSum * LInvSqrt[LJ];
    end;
    LSum := LData^[LI * LRows + LI];
    for LK := 0 to LI - 1 do
    begin
      LSum := LSum - LData^[LI * LRows + LK] * LData^[LI * LRows + LK];
    end;
    if LSum <= 0.0 then
      Exit(False);
    LInvSqrt[LI] := TIdMath.InvSqrt(Single(LSum));
    LData^[LI * LRows + LI] := LInvSqrt[LI] * LSum;
  end;
  Result := True;
end;

class function TIdMatXCholesky.UpdateRankOne(const AMatrix: TIdMatX; const AV: TIdVecX;
  AAlpha: Single; const AOffset: Integer): Boolean;
var
  LRows, LI, LJ: Integer;
  LY: TArray<Single>;
  LData: PIdSingleArray;
  LDiagonal, LInvDiagonal, LDiagonalSqr, LNewDiagonal, LNewDiagonalSqr, LBeta, LP, LD: Double;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  Assert(AV.Size >= AMatrix.NumRows);
  Assert((AOffset >= 0) and (AOffset < AMatrix.NumRows));
  LRows := AMatrix.NumRows;
  LData := AMatrix.Data;
  SetLength(LY, AV.Size);
  for LI := 0 to AV.Size - 1 do
  begin
    LY[LI] := AV[LI];
  end;
  for LI := AOffset to LRows - 1 do
  begin
    LP := LY[LI];
    LDiagonal := LData^[LI * LRows + LI];
    LInvDiagonal := 1.0 / LDiagonal;
    LDiagonalSqr := LDiagonal * LDiagonal;
    LNewDiagonalSqr := LDiagonalSqr + AAlpha * LP * LP;
    if LNewDiagonalSqr <= 0.0 then
      Exit(False);
    LNewDiagonal := TIdMath.Sqrt(Single(LNewDiagonalSqr));
    LData^[LI * LRows + LI] := LNewDiagonal;
    // alpha is a float in the C++: every assignment rounds
    AAlpha := AAlpha / LNewDiagonalSqr;
    LBeta := LP * AAlpha;
    AAlpha := AAlpha * LDiagonalSqr;
    for LJ := LI + 1 to LRows - 1 do
    begin
      LD := LData^[LJ * LRows + LI] * LInvDiagonal;
      LY[LJ] := LY[LJ] - LP * LD;
      LD := LD + LBeta * LY[LJ];
      LData^[LJ * LRows + LI] := LD * LNewDiagonal;
    end;
  end;
  Result := True;
end;

class function TIdMatXCholesky.UpdateRowColumn(const AMatrix: TIdMatX; const AV: TIdVecX;
  const ARow: Integer): Boolean;
var
  LColumns, LI, LJ: Integer;
  LData: PIdSingleArray;
  LSum, LD, LDiagonal, LInvDiagonal, LDiagonalSqr, LNewDiagonal, LNewDiagonalSqr: Double;
  LAlpha1, LAlpha2, LBeta1, LBeta2, LP1, LP2, LV0: Double;
  LOriginal, LAddSub, LV1, LV2: TArray<Single>;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  Assert(AV.Size >= AMatrix.NumRows);
  Assert((ARow >= 0) and (ARow < AMatrix.NumRows));
  LColumns := AMatrix.NumColumns;
  LData := AMatrix.Data;
  SetLength(LAddSub, LColumns);
  if ARow = 0 then
  begin
    if LColumns = 1 then
    begin
      LV0 := AV[0];
      LSum := LData^[0];
      LSum := LSum * LSum;
      LSum := LSum + LV0;
      if LSum <= 0.0 then
        Exit(False);
      LData^[0] := TIdMath.Sqrt(Single(LSum));
      Exit(True);
    end;
    for LI := 0 to LColumns - 1 do
    begin
      LAddSub[LI] := AV[LI];
    end;
  end
  else
  begin
    SetLength(LOriginal, LColumns);
    // calculate original row/column of matrix
    for LI := 0 to AMatrix.NumRows - 1 do
    begin
      LSum := 0.0;
      for LJ := 0 to LI do
      begin
        LSum := LSum + LData^[ARow * LColumns + LJ] * LData^[LI * LColumns + LJ];
      end;
      LOriginal[LI] := LSum;
    end;
    // solve for y in L * y = original + v
    for LI := 0 to ARow - 1 do
    begin
      LSum := LOriginal[LI] + AV[LI];
      for LJ := 0 to LI - 1 do
      begin
        LSum := LSum - LData^[ARow * LColumns + LJ] * LData^[LI * LColumns + LJ];
      end;
      LData^[ARow * LColumns + LI] := LSum / LData^[LI * LColumns + LI];
    end;
    // if the last row/column of the matrix is updated only the new diagonal is calculated
    if ARow = LColumns - 1 then
    begin
      LSum := LOriginal[ARow] + AV[ARow];
      for LJ := 0 to ARow - 1 do
      begin
        LSum := LSum - LData^[ARow * LColumns + LJ] * LData^[ARow * LColumns + LJ];
      end;
      if LSum <= 0.0 then
        Exit(False);
      LData^[ARow * LColumns + ARow] := TIdMath.Sqrt(Single(LSum));
      Exit(True);
    end;
    // calculate the row/column to be added to the lower right sub matrix starting at (r, r)
    for LI := ARow to LColumns - 1 do
    begin
      LSum := 0.0;
      for LJ := 0 to ARow do
      begin
        LSum := LSum + LData^[ARow * LColumns + LJ] * LData^[LI * LColumns + LJ];
      end;
      LAddSub[LI] := AV[LI] - (LSum - LOriginal[LI]);
    end;
  end;
  // add row/column to the lower right sub matrix starting at (r, r): simultaneous update/downdate
  SetLength(LV1, LColumns);
  SetLength(LV2, LColumns);
  LD := ID_SQRT_1OVER2;
  LV1[ARow] := (0.5 * LAddSub[ARow] + 1.0) * LD;
  LV2[ARow] := (0.5 * LAddSub[ARow] - 1.0) * LD;
  for LI := ARow + 1 to LColumns - 1 do
  begin
    LV1[LI] := LAddSub[LI] * LD;
    LV2[LI] := LV1[LI];
  end;
  LAlpha1 := 1.0;
  LAlpha2 := -1.0;
  for LI := ARow to LColumns - 1 do
  begin
    LP1 := LV1[LI];
    LDiagonal := LData^[LI * LColumns + LI];
    LInvDiagonal := 1.0 / LDiagonal;
    LDiagonalSqr := LDiagonal * LDiagonal;
    LNewDiagonalSqr := LDiagonalSqr + LAlpha1 * LP1 * LP1;
    if LNewDiagonalSqr <= 0.0 then
      Exit(False);
    LAlpha1 := LAlpha1 / LNewDiagonalSqr;
    LBeta1 := LP1 * LAlpha1;
    LAlpha1 := LAlpha1 * LDiagonalSqr;
    LP2 := LV2[LI];
    LDiagonalSqr := LNewDiagonalSqr;
    LNewDiagonalSqr := LDiagonalSqr + LAlpha2 * LP2 * LP2;
    if LNewDiagonalSqr <= 0.0 then
      Exit(False);
    LNewDiagonal := TIdMath.Sqrt(Single(LNewDiagonalSqr));
    LData^[LI * LColumns + LI] := LNewDiagonal;
    LAlpha2 := LAlpha2 / LNewDiagonalSqr;
    LBeta2 := LP2 * LAlpha2;
    LAlpha2 := LAlpha2 * LDiagonalSqr;
    for LJ := LI + 1 to AMatrix.NumRows - 1 do
    begin
      LD := LData^[LJ * LColumns + LI] * LInvDiagonal;
      LV1[LJ] := LV1[LJ] - LP1 * LD;
      LD := LD + LBeta1 * LV1[LJ];
      LV2[LJ] := LV2[LJ] - LP2 * LD;
      LD := LD + LBeta2 * LV2[LJ];
      LData^[LJ * LColumns + LI] := LD * LNewDiagonal;
    end;
  end;
  Result := True;
end;

class function TIdMatXCholesky.UpdateIncrement(const AMatrix: TIdMatX; const AV: TIdVecX): Boolean;
var
  LRows, LI, LJ: Integer;
  LData: PIdSingleArray;
  LX: TArray<Single>;
  LSum: Double;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  Assert(AV.Size >= AMatrix.NumRows + 1);
  AMatrix.ChangeSize(AMatrix.NumRows + 1, AMatrix.NumColumns + 1, False);
  LRows := AMatrix.NumRows;
  LData := AMatrix.Data;
  SetLength(LX, LRows);
  // solve for x in L * x = v
  for LI := 0 to LRows - 2 do
  begin
    LSum := AV[LI];
    for LJ := 0 to LI - 1 do
    begin
      LSum := LSum - LData^[LI * LRows + LJ] * LX[LJ];
    end;
    LX[LI] := LSum / LData^[LI * LRows + LI];
  end;
  // calculate new row of L and calculate the square of the diagonal entry
  LSum := AV[LRows - 1];
  for LI := 0 to LRows - 2 do
  begin
    LData^[(LRows - 1) * LRows + LI] := LX[LI];
    LSum := LSum - LX[LI] * LX[LI];
  end;
  if LSum <= 0.0 then
    Exit(False);
  LData^[(LRows - 1) * LRows + LRows - 1] := TIdMath.Sqrt(Single(LSum));
  Result := True;
end;

class function TIdMatXCholesky.UpdateDecrement(const AMatrix: TIdMatX; const AV: TIdVecX;
  const ARow: Integer): Boolean;
var
  LV1: TIdVecX;
  LIndex: Integer;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  Assert(AV.Size >= AMatrix.NumRows);
  Assert((ARow >= 0) and (ARow < AMatrix.NumRows));
  LV1 := TIdVecX.Create(AMatrix.NumRows);
  try
    for LIndex := 0 to AMatrix.NumRows - 1 do
    begin
      LV1[LIndex] := -AV[LIndex];
    end;
    LV1[ARow] := LV1[ARow] + 1.0;
    if not UpdateRowColumn(AMatrix, LV1, ARow) then
      Exit(False);
    AMatrix.UpdateDecrement(ARow);
    Result := True;
  finally
    LV1.Free;
  end;
end;

class procedure TIdMatXCholesky.Solve(const AMatrix: TIdMatX; const AX, AB: TIdVecX);
var
  LRows, LI, LJ: Integer;
  LData: PIdSingleArray;
  LSum: Double;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  Assert((AX.Size >= AMatrix.NumRows) and (AB.Size >= AMatrix.NumRows));
  LRows := AMatrix.NumRows;
  LData := AMatrix.Data;
  // solve L
  for LI := 0 to LRows - 1 do
  begin
    LSum := AB[LI];
    for LJ := 0 to LI - 1 do
    begin
      LSum := LSum - LData^[LI * LRows + LJ] * AX[LJ];
    end;
    AX[LI] := LSum / LData^[LI * LRows + LI];
  end;
  // solve Lt
  for LI := LRows - 1 downto 0 do
  begin
    LSum := AX[LI];
    for LJ := LI + 1 to LRows - 1 do
    begin
      LSum := LSum - LData^[LJ * LRows + LI] * AX[LJ];
    end;
    AX[LI] := LSum / LData^[LI * LRows + LI];
  end;
end;

class procedure TIdMatXCholesky.Inverse(const AMatrix: TIdMatX; const AInverse: TIdMatX);
var
  LRows, LI, LJ: Integer;
  LX, LB: TIdVecX;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  LRows := AMatrix.NumRows;
  LX := TIdVecX.Create(LRows);
  LB := TIdVecX.Create(LRows);
  try
    LB.Zero;
    AInverse.SetSize(LRows, AMatrix.NumColumns);
    for LI := 0 to LRows - 1 do
    begin
      LB[LI] := 1.0;
      Solve(AMatrix, LX, LB);
      for LJ := 0 to LRows - 1 do
      begin
        AInverse[LJ, LI] := LX[LJ];
      end;
      LB[LI] := 0.0;
    end;
  finally
    LB.Free;
    LX.Free;
  end;
end;

class procedure TIdMatXCholesky.MultiplyFactors(const AMatrix: TIdMatX; const AResult: TIdMatX);
var
  LRows, LRow, LI, LJ: Integer;
  LData: PIdSingleArray;
  LSum: Double;
begin
  LRows := AMatrix.NumRows;
  LData := AMatrix.Data;
  AResult.SetSize(LRows, AMatrix.NumColumns);
  for LRow := 0 to LRows - 1 do
  begin
    for LI := 0 to LRows - 1 do
    begin
      LSum := 0.0;
      LJ := 0;
      while (LJ <= LI) and (LJ <= LRow) do
      begin
        LSum := LSum + LData^[LRow * AMatrix.NumColumns + LJ] * LData^[LI * AMatrix.NumColumns + LJ];
        Inc(LJ);
      end;
      AResult[LRow, LI] := LSum;
    end;
  end;
end;

class function TIdMatXCholesky.IsSymmetricPositiveDefinite(const AMatrix: TIdMatX;
  const AEpsilon: Single): Boolean;
var
  LCopy: TIdMatX;
begin
  if not AMatrix.IsSymmetric(AEpsilon) then
    Exit(False);
  LCopy := TIdMatX.Create;
  try
    LCopy.Assign(AMatrix);
    // being able to obtain Cholesky factors is both a necessary and sufficient condition
    Result := Factor(LCopy);
  finally
    LCopy.Free;
  end;
end;

class function TIdMatXCholesky.IsSymmetricPositiveSemiDefinite(const AMatrix: TIdMatX;
  const AEpsilon: Single): Boolean;
begin
  Result := AMatrix.IsSymmetric(AEpsilon) and AMatrix.IsPositiveSemiDefinite(AEpsilon);
end;

end.
