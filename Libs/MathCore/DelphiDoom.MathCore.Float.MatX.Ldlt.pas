{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdMatXLdlt, the LDL' factorization }
{                                                                              }
{  Port of the LDLT_* members of idMatX (idlib\math\Matrix.cpp) of the Doom 3  }
{  GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media   }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.MatX.Ldlt;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.MatX, DelphiDoom.MathCore.Float.VecX;

type
  /// <summary>
  ///   The LDL' factorization of a symmetric matrix, in place (the <c>LDLT_*</c> members of
  ///   idMatX). L is stored in the strictly lower triangle with an implicit unit diagonal, D on
  ///   the diagonal; the upper triangle is not cleared. The update functions are the ones that
  ///   <c>TIdLcp</c> uses to add and remove rows and columns of the matrix.
  /// </summary>
  TIdMatXLdlt = class sealed
  public
    /// <summary>False if a pivot is zero (the matrix has to be symmetric)</summary>
    class function Factor(const AMatrix: TIdMatX): Boolean; static;
    /// <summary>Factors of LDL' + alpha * v * v'; with an offset only the lower right corner from (offset, offset) is updated</summary>
    class function UpdateRankOne(const AMatrix: TIdMatX; const AV: TIdVecX; AAlpha: Single;
      const AOffset: Integer = 0): Boolean; static;
    /// <summary>Factors of LDL' with row and column r replaced as in the header of the C++ (a, b, c from v)</summary>
    class function UpdateRowColumn(const AMatrix: TIdMatX; const AV: TIdVecX;
      const ARow: Integer): Boolean; static;
    /// <summary>Factors of the matrix [A a; a b] with a = v[0..n-1], b = v[n]</summary>
    class function UpdateIncrement(const AMatrix: TIdMatX; const AV: TIdVecX): Boolean; static;
    /// <summary>Factors of the matrix without row and column r; v is the row of the original matrix</summary>
    class function UpdateDecrement(const AMatrix: TIdMatX; const AV: TIdVecX;
      const ARow: Integer): Boolean; static;
    /// <summary>Solves Ax = b with A factored in place</summary>
    class procedure Solve(const AMatrix: TIdMatX; const AX, AB: TIdVecX); static;
    class procedure Inverse(const AMatrix: TIdMatX; const AInverse: TIdMatX); static;
    class procedure UnpackFactors(const AMatrix: TIdMatX; const AL, AD: TIdMatX); static;
    class procedure MultiplyFactors(const AMatrix: TIdMatX; const AResult: TIdMatX); static;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.MathCore.Float.Types;

{ TIdMatXLdlt }

class function TIdMatXLdlt.Factor(const AMatrix: TIdMatX): Boolean;
var
  LRows, LRow, LColumn, LK: Integer;
  LV: TArray<Single>;
  LData: PIdSingleArray;
  LD, LSum: Double;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  LRows := AMatrix.NumRows;
  LData := AMatrix.Data;
  SetLength(LV, LRows);
  for LRow := 0 to LRows - 1 do
  begin
    LSum := LData^[LRow * LRows + LRow];
    for LColumn := 0 to LRow - 1 do
    begin
      LD := LData^[LRow * LRows + LColumn];
      LV[LColumn] := LData^[LColumn * LRows + LColumn] * LD;
      LSum := LSum - LV[LColumn] * LD;
    end;
    if LSum = 0.0 then
      Exit(False);
    LData^[LRow * LRows + LRow] := LSum;
    LD := 1.0 / LSum;
    for LColumn := LRow + 1 to LRows - 1 do
    begin
      LSum := LData^[LColumn * LRows + LRow];
      for LK := 0 to LRow - 1 do
      begin
        LSum := LSum - LData^[LColumn * LRows + LK] * LV[LK];
      end;
      LData^[LColumn * LRows + LRow] := LSum * LD;
    end;
  end;
  Result := True;
end;

class function TIdMatXLdlt.UpdateRankOne(const AMatrix: TIdMatX; const AV: TIdVecX;
  AAlpha: Single; const AOffset: Integer): Boolean;
var
  LRows, LRow, LColumn: Integer;
  LY: TArray<Single>;
  LData: PIdSingleArray;
  LDiagonal, LNewDiagonal, LBeta, LP, LD: Double;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  Assert(AV.Size >= AMatrix.NumRows);
  Assert((AOffset >= 0) and (AOffset < AMatrix.NumRows));
  LRows := AMatrix.NumRows;
  LData := AMatrix.Data;
  SetLength(LY, AV.Size);
  for LRow := 0 to AV.Size - 1 do
  begin
    LY[LRow] := AV[LRow];
  end;
  for LRow := AOffset to LRows - 1 do
  begin
    LP := LY[LRow];
    LDiagonal := LData^[LRow * LRows + LRow];
    LNewDiagonal := LDiagonal + AAlpha * LP * LP;
    LData^[LRow * LRows + LRow] := LNewDiagonal;
    if LNewDiagonal = 0.0 then
      Exit(False);
    // alpha is a float in the C++: every assignment rounds
    AAlpha := AAlpha / LNewDiagonal;
    LBeta := LP * AAlpha;
    AAlpha := AAlpha * LDiagonal;
    for LColumn := LRow + 1 to LRows - 1 do
    begin
      LD := LData^[LColumn * LRows + LRow];
      LY[LColumn] := LY[LColumn] - LP * LD;
      LD := LD + LBeta * LY[LColumn];
      LData^[LColumn * LRows + LRow] := LD;
    end;
  end;
  Result := True;
end;

class function TIdMatXLdlt.UpdateRowColumn(const AMatrix: TIdMatX; const AV: TIdVecX;
  const ARow: Integer): Boolean;
var
  LColumns, LI, LJ: Integer;
  LData: PIdSingleArray;
  LSum, LD, LDiagonal, LNewDiagonal, LP1, LP2, LAlpha1, LAlpha2, LBeta1, LBeta2: Double;
  LOriginal, LY, LAddSub, LV1, LV2: TArray<Single>;
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
      LData^[0] := LData^[0] + AV[0];
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
    SetLength(LY, LColumns);
    // calculate original row/column of matrix
    for LI := 0 to ARow - 1 do
    begin
      LY[LI] := LData^[ARow * LColumns + LI] * LData^[LI * LColumns + LI];
    end;
    for LI := 0 to LColumns - 1 do
    begin
      if LI < ARow then
        LSum := LData^[LI * LColumns + LI] * LData^[ARow * LColumns + LI]
      else if LI = ARow then
        LSum := LData^[ARow * LColumns + ARow]
      else
        LSum := LData^[ARow * LColumns + ARow] * LData^[LI * LColumns + ARow];
      LJ := 0;
      while (LJ < LI) and (LJ < ARow) do
      begin
        LSum := LSum + LData^[LI * LColumns + LJ] * LY[LJ];
        Inc(LJ);
      end;
      LOriginal[LI] := LSum;
    end;
    // solve for y in L * y = original + v
    for LI := 0 to ARow - 1 do
    begin
      LSum := LOriginal[LI] + AV[LI];
      for LJ := 0 to LI - 1 do
      begin
        LSum := LSum - LData^[LI * LColumns + LJ] * LY[LJ];
      end;
      LY[LI] := LSum;
    end;
    // calculate new row of L
    for LI := 0 to ARow - 1 do
    begin
      LData^[ARow * LColumns + LI] := LY[LI] / LData^[LI * LColumns + LI];
    end;
    // if the last row/column of the matrix is updated only the new diagonal is calculated
    if ARow = LColumns - 1 then
    begin
      LSum := LOriginal[ARow] + AV[ARow];
      for LJ := 0 to ARow - 1 do
      begin
        LSum := LSum - LData^[ARow * LColumns + LJ] * LY[LJ];
      end;
      if LSum = 0.0 then
        Exit(False);
      LData^[ARow * LColumns + ARow] := LSum;
      Exit(True);
    end;
    // calculate the row/column to be added to the lower right sub matrix starting at (r, r)
    for LI := 0 to ARow - 1 do
    begin
      LY[LI] := LData^[ARow * LColumns + LI] * LData^[LI * LColumns + LI];
    end;
    for LI := ARow to LColumns - 1 do
    begin
      if LI = ARow then
        LSum := LData^[ARow * LColumns + ARow]
      else
        LSum := LData^[ARow * LColumns + ARow] * LData^[LI * LColumns + ARow];
      for LJ := 0 to ARow - 1 do
      begin
        LSum := LSum + LData^[LI * LColumns + LJ] * LY[LJ];
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
    LDiagonal := LData^[LI * LColumns + LI];
    LP1 := LV1[LI];
    LNewDiagonal := LDiagonal + LAlpha1 * LP1 * LP1;
    if LNewDiagonal = 0.0 then
      Exit(False);
    LAlpha1 := LAlpha1 / LNewDiagonal;
    LBeta1 := LP1 * LAlpha1;
    LAlpha1 := LAlpha1 * LDiagonal;
    LDiagonal := LNewDiagonal;
    LP2 := LV2[LI];
    LNewDiagonal := LDiagonal + LAlpha2 * LP2 * LP2;
    if LNewDiagonal = 0.0 then
      Exit(False);
    LAlpha2 := LAlpha2 / LNewDiagonal;
    LBeta2 := LP2 * LAlpha2;
    LAlpha2 := LAlpha2 * LDiagonal;
    LData^[LI * LColumns + LI] := LNewDiagonal;
    for LJ := LI + 1 to AMatrix.NumRows - 1 do
    begin
      LD := LData^[LJ * LColumns + LI];
      LV1[LJ] := LV1[LJ] - LP1 * LD;
      LD := LD + LBeta1 * LV1[LJ];
      LV2[LJ] := LV2[LJ] - LP2 * LD;
      LD := LD + LBeta2 * LV2[LJ];
      LData^[LJ * LColumns + LI] := LD;
    end;
  end;
  Result := True;
end;

class function TIdMatXLdlt.UpdateIncrement(const AMatrix: TIdMatX; const AV: TIdVecX): Boolean;
var
  LRows, LI, LJ: Integer;
  LData: PIdSingleArray;
  LX: TArray<Single>;
  LSum, LD: Double;
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
    LX[LI] := LSum;
  end;
  // calculate new row of L and calculate the diagonal entry
  LSum := AV[LRows - 1];
  for LI := 0 to LRows - 2 do
  begin
    LD := LX[LI] / LData^[LI * LRows + LI];
    LData^[(LRows - 1) * LRows + LI] := LD;
    LSum := LSum - LD * LX[LI];
  end;
  if LSum = 0.0 then
    Exit(False);
  LData^[(LRows - 1) * LRows + LRows - 1] := LSum;
  Result := True;
end;

class function TIdMatXLdlt.UpdateDecrement(const AMatrix: TIdMatX; const AV: TIdVecX;
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
    // update the row and column to identity
    for LIndex := 0 to AMatrix.NumRows - 1 do
    begin
      LV1[LIndex] := -AV[LIndex];
    end;
    LV1[ARow] := LV1[ARow] + 1.0;
    if not UpdateRowColumn(AMatrix, LV1, ARow) then
      Exit(False);
    // physically remove the row and column
    AMatrix.UpdateDecrement(ARow);
    Result := True;
  finally
    LV1.Free;
  end;
end;

class procedure TIdMatXLdlt.Solve(const AMatrix: TIdMatX; const AX, AB: TIdVecX);
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
    AX[LI] := LSum;
  end;
  // solve D
  for LI := 0 to LRows - 1 do
  begin
    AX[LI] := AX[LI] / LData^[LI * LRows + LI];
  end;
  // solve Lt
  for LI := LRows - 2 downto 0 do
  begin
    LSum := AX[LI];
    for LJ := LI + 1 to LRows - 1 do
    begin
      LSum := LSum - LData^[LJ * LRows + LI] * AX[LJ];
    end;
    AX[LI] := LSum;
  end;
end;

class procedure TIdMatXLdlt.Inverse(const AMatrix: TIdMatX; const AInverse: TIdMatX);
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

class procedure TIdMatXLdlt.UnpackFactors(const AMatrix: TIdMatX; const AL, AD: TIdMatX);
var
  LI, LJ: Integer;
begin
  AL.Zero(AMatrix.NumRows, AMatrix.NumColumns);
  AD.Zero(AMatrix.NumRows, AMatrix.NumColumns);
  for LI := 0 to AMatrix.NumRows - 1 do
  begin
    for LJ := 0 to LI - 1 do
    begin
      AL[LI, LJ] := AMatrix[LI, LJ];
    end;
    AL[LI, LI] := 1.0;
    AD[LI, LI] := AMatrix[LI, LI];
  end;
end;

class procedure TIdMatXLdlt.MultiplyFactors(const AMatrix: TIdMatX; const AResult: TIdMatX);
var
  LRow, LI, LJ, LColumns: Integer;
  LData: PIdSingleArray;
  LV: TArray<Single>;
  LSum: Double;
begin
  LColumns := AMatrix.NumColumns;
  LData := AMatrix.Data;
  SetLength(LV, AMatrix.NumRows);
  AResult.SetSize(AMatrix.NumRows, LColumns);
  for LRow := 0 to AMatrix.NumRows - 1 do
  begin
    for LI := 0 to LRow - 1 do
    begin
      LV[LI] := LData^[LRow * LColumns + LI] * LData^[LI * LColumns + LI];
    end;
    for LI := 0 to LColumns - 1 do
    begin
      if LI < LRow then
        LSum := LData^[LI * LColumns + LI] * LData^[LRow * LColumns + LI]
      else if LI = LRow then
        LSum := LData^[LRow * LColumns + LRow]
      else
        LSum := LData^[LRow * LColumns + LRow] * LData^[LI * LColumns + LRow];
      LJ := 0;
      while (LJ < LI) and (LJ < LRow) do
      begin
        LSum := LSum + LData^[LI * LColumns + LJ] * LV[LJ];
        Inc(LJ);
      end;
      AResult[LRow, LI] := LSum;
    end;
  end;
end;

end.
