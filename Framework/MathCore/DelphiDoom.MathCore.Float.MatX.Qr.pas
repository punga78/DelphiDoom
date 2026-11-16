{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdMatXQr, the QR factorization     }
{                                                                              }
{  Port of the QR_* members of idMatX (idlib\math\Matrix.cpp) of the Doom 3    }
{  GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media   }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Framework\IdLib); the repository as a whole is GPL v2 or later.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.MatX.Qr;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.MatX, DelphiDoom.MathCore.Float.VecX;

type
  /// <summary>
  ///   The QR factorization of a square matrix (the <c>QR_*</c> members of idMatX). The in-place
  ///   form keeps Q as a product of Householder matrices in the lower triangle and in the vector
  ///   c, and R in the upper triangle with its diagonal in the vector d. The update functions
  ///   work on the unpacked factors (Q in the matrix, R in a second matrix).
  /// </summary>
  TIdMatXQr = class sealed
  public
    /// <summary>In-place factorization; false if the matrix is singular (the factors are still made)</summary>
    class function Factor(const AMatrix: TIdMatX; const AC, AD: TIdVecX): Boolean; static;
    /// <summary>A Jacobi rotation of the rows i and i+1 of R and of the columns i and i+1 of Q</summary>
    class procedure Rotate(const AMatrix, AR: TIdMatX; const AIndex: Integer; const AA, AB: Single);
      static;
    /// <summary>The unpacked factors of QR + alpha * v * w'</summary>
    class function UpdateRankOne(const AMatrix, AR: TIdMatX; const AV, AW: TIdVecX;
      const AAlpha: Single): Boolean; static;
    /// <summary>
    ///   The unpacked factors of QR plus a row and a column at r (a = v[0,r-1], b = v[r],
    ///   c = v[r+1,rows-1], d = w[0,r-1], w[r] = 0, e = w[r+1,columns-1])
    /// </summary>
    class function UpdateRowColumn(const AMatrix, AR: TIdMatX; const AV, AW: TIdVecX;
      const ARow: Integer): Boolean; static;
    /// <summary>The unpacked factors of [A a; c b] (a = v[0,rows-1], b = v[rows], c = w[0,columns-1])</summary>
    class function UpdateIncrement(const AMatrix, AR: TIdMatX; const AV, AW: TIdVecX): Boolean;
      static;
    /// <summary>The unpacked factors of the matrix without row r and column r (v and w: column and row of the original)</summary>
    class function UpdateDecrement(const AMatrix, AR: TIdMatX; const AV, AW: TIdVecX;
      const ARow: Integer): Boolean; static;
    /// <summary>Solves Ax = b with A factored in place</summary>
    class procedure Solve(const AMatrix: TIdMatX; const AX, AB, AC, AD: TIdVecX); overload; static;
    /// <summary>Solves Ax = b with the unpacked factors (Q in the matrix)</summary>
    class procedure Solve(const AMatrix: TIdMatX; const AX, AB: TIdVecX; const AR: TIdMatX);
      overload; static;
    class procedure Inverse(const AMatrix, AInverse: TIdMatX; const AC, AD: TIdVecX); static;
    class procedure UnpackFactors(const AMatrix, AQ, AR: TIdMatX; const AC, AD: TIdVecX); static;
    class procedure MultiplyFactors(const AMatrix, AResult: TIdMatX; const AC, AD: TIdVecX); static;
  end;

implementation

uses
  System.Math, DelphiDoom.IdLib.Math.Math;

{ TIdMatXQr }

class function TIdMatXQr.Factor(const AMatrix: TIdMatX; const AC, AD: TIdVecX): Boolean;
var
  LRows, LI, LJ, LK: Integer;
  LScale, LS, LT, LSum: Double;
  LSingular: Boolean;
begin
  LRows := AMatrix.NumRows;
  Assert(LRows = AMatrix.NumColumns);
  Assert((AC.Size >= LRows) and (AD.Size >= LRows));
  LSingular := False;
  for LK := 0 to LRows - 2 do
  begin
    LScale := 0.0;
    for LI := LK to LRows - 1 do
    begin
      LS := Abs(AMatrix[LI, LK]);
      if LS > LScale then
        LScale := LS;
    end;
    if LScale = 0.0 then
    begin
      LSingular := True;
      AC[LK] := 0.0;
      AD[LK] := 0.0;
    end
    else
    begin
      LS := 1.0 / LScale;
      for LI := LK to LRows - 1 do
      begin
        AMatrix[LI, LK] := AMatrix[LI, LK] * LS;
      end;
      LSum := 0.0;
      for LI := LK to LRows - 1 do
      begin
        LS := AMatrix[LI, LK];
        LSum := LSum + LS * LS;
      end;
      LS := TIdMath.Sqrt(LSum);
      if AMatrix[LK, LK] < 0.0 then
        LS := -LS;
      AMatrix[LK, LK] := AMatrix[LK, LK] + LS;
      AC[LK] := LS * AMatrix[LK, LK];
      AD[LK] := -LScale * LS;
      for LJ := LK + 1 to LRows - 1 do
      begin
        LSum := 0.0;
        for LI := LK to LRows - 1 do
        begin
          LSum := LSum + AMatrix[LI, LK] * AMatrix[LI, LJ];
        end;
        LT := LSum / AC[LK];
        for LI := LK to LRows - 1 do
        begin
          AMatrix[LI, LJ] := AMatrix[LI, LJ] - LT * AMatrix[LI, LK];
        end;
      end;
    end;
  end;
  AD[LRows - 1] := AMatrix[LRows - 1, LRows - 1];
  if AD[LRows - 1] = 0.0 then
    LSingular := True;
  Result := not LSingular;
end;

class procedure TIdMatXQr.Rotate(const AMatrix, AR: TIdMatX; const AIndex: Integer;
  const AA, AB: Single);
var
  LRows, LJ: Integer;
  LF, LC, LS, LW, LY, LRoot, LProduct1, LProduct2: Single;
begin
  LRows := AMatrix.NumRows;
  if AA = 0.0 then
  begin
    LC := 0.0;
    if AB >= 0.0 then
      LS := 1.0
    else
      LS := -1.0;
  end
  else if Abs(AA) > Abs(AB) then
  begin
    LF := AB / AA;
    LProduct1 := LF * LF;
    LProduct1 := 1.0 + LProduct1;
    LRoot := TIdMath.Sqrt(LProduct1);
    LC := Abs(1.0 / LRoot);
    if AA < 0.0 then
      LC := -LC;
    LS := LF * LC;
  end
  else
  begin
    LF := AA / AB;
    LProduct1 := LF * LF;
    LProduct1 := 1.0 + LProduct1;
    LRoot := TIdMath.Sqrt(LProduct1);
    LS := Abs(1.0 / LRoot);
    if AB < 0.0 then
      LS := -LS;
    LC := LF * LS;
  end;
  for LJ := AIndex to LRows - 1 do
  begin
    LY := AR[AIndex, LJ];
    LW := AR[AIndex + 1, LJ];
    LProduct1 := LC * LY;
    LProduct2 := LS * LW;
    AR[AIndex, LJ] := LProduct1 - LProduct2;
    LProduct1 := LS * LY;
    LProduct2 := LC * LW;
    AR[AIndex + 1, LJ] := LProduct1 + LProduct2;
  end;
  for LJ := 0 to LRows - 1 do
  begin
    LY := AMatrix[LJ, AIndex];
    LW := AMatrix[LJ, AIndex + 1];
    LProduct1 := LC * LY;
    LProduct2 := LS * LW;
    AMatrix[LJ, AIndex] := LProduct1 - LProduct2;
    LProduct1 := LS * LY;
    LProduct2 := LC * LW;
    AMatrix[LJ, AIndex + 1] := LProduct1 + LProduct2;
  end;
end;

class function TIdMatXQr.UpdateRankOne(const AMatrix, AR: TIdMatX; const AV, AW: TIdVecX;
  const AAlpha: Single): Boolean;
var
  LI, LK: Integer;
  LF, LProduct: Single;
  LU: TIdVecX;
begin
  Assert(AV.Size >= AMatrix.NumColumns);
  Assert(AW.Size >= AMatrix.NumRows);
  LU := TIdVecX.Create(AV.Size);
  try
    AMatrix.TransposeMultiply(LU, AV);
    LU.MultiplyAssign(AAlpha);
    LK := AV.Size - 1;
    while LK > 0 do
    begin
      if LU[LK] <> 0.0 then
        Break;
      Dec(LK);
    end;
    for LI := LK - 1 downto 0 do
    begin
      Rotate(AMatrix, AR, LI, LU[LI], -LU[LI + 1]);
      if LU[LI] = 0.0 then
        LU[LI] := Abs(LU[LI + 1])
      else if Abs(LU[LI]) > Abs(LU[LI + 1]) then
      begin
        LF := LU[LI + 1] / LU[LI];
        LProduct := LF * LF;
        LProduct := 1.0 + LProduct;
        LU[LI] := Abs(LU[LI]) * TIdMath.Sqrt(LProduct);
      end
      else
      begin
        LF := LU[LI] / LU[LI + 1];
        LProduct := LF * LF;
        LProduct := 1.0 + LProduct;
        LU[LI] := Abs(LU[LI + 1]) * TIdMath.Sqrt(LProduct);
      end;
    end;
    for LI := 0 to AV.Size - 1 do
    begin
      AR[0, LI] := AR[0, LI] + LU[0] * AW[LI];
    end;
    for LI := 0 to LK - 1 do
    begin
      Rotate(AMatrix, AR, LI, -AR[LI, LI], AR[LI + 1, LI]);
    end;
  finally
    LU.Free;
  end;
  Result := True;
end;

class function TIdMatXQr.UpdateRowColumn(const AMatrix, AR: TIdMatX; const AV, AW: TIdVecX;
  const ARow: Integer): Boolean;
var
  LS: TIdVecX;
  LSize: Integer;
begin
  Assert(AV.Size >= AMatrix.NumColumns);
  Assert(AW.Size >= AMatrix.NumRows);
  Assert((ARow >= 0) and (ARow < AMatrix.NumRows) and (ARow < AMatrix.NumColumns));
  Assert(AW[ARow] = 0.0);
  LSize := Max(AMatrix.NumRows, AMatrix.NumColumns);
  LS := TIdVecX.Create(LSize);
  try
    LS.Zero;
    LS[ARow] := 1.0;
    if not UpdateRankOne(AMatrix, AR, AV, LS, 1.0) then
      Exit(False);
    if not UpdateRankOne(AMatrix, AR, LS, AW, 1.0) then
      Exit(False);
  finally
    LS.Free;
  end;
  Result := True;
end;

class function TIdMatXQr.UpdateIncrement(const AMatrix, AR: TIdMatX; const AV,
  AW: TIdVecX): Boolean;
var
  LRows: Integer;
  LV2: TIdVecX;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  Assert(AV.Size >= AMatrix.NumRows + 1);
  Assert(AW.Size >= AMatrix.NumColumns + 1);
  AMatrix.ChangeSize(AMatrix.NumRows + 1, AMatrix.NumColumns + 1, True);
  LRows := AMatrix.NumRows;
  AMatrix[LRows - 1, LRows - 1] := 1.0;
  AR.ChangeSize(AR.NumRows + 1, AR.NumColumns + 1, True);
  AR[AR.NumRows - 1, AR.NumRows - 1] := 1.0;
  // the C++ keeps v2 as a vector of numRows floats copied from v
  LV2 := TIdVecX.Create(LRows);
  try
    LV2.Assign(AV);
    LV2[LRows - 1] := LV2[LRows - 1] - 1.0;
    Result := UpdateRowColumn(AMatrix, AR, LV2, AW, LRows - 1);
  finally
    LV2.Free;
  end;
end;

class function TIdMatXQr.UpdateDecrement(const AMatrix, AR: TIdMatX; const AV, AW: TIdVecX;
  const ARow: Integer): Boolean;
var
  LV1, LW1: TIdVecX;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  Assert(AV.Size >= AMatrix.NumRows);
  Assert(AW.Size >= AMatrix.NumColumns);
  Assert((ARow >= 0) and (ARow < AMatrix.NumRows));
  LV1 := AV.Negative;
  LW1 := AW.Negative;
  try
    LV1[ARow] := LV1[ARow] + 1.0;
    LW1[ARow] := 0.0;
    if not UpdateRowColumn(AMatrix, AR, LV1, LW1, ARow) then
      Exit(False);
  finally
    LW1.Free;
    LV1.Free;
  end;
  // physically remove the row and column
  AMatrix.UpdateDecrement(ARow);
  AR.UpdateDecrement(ARow);
  Result := True;
end;

class procedure TIdMatXQr.Solve(const AMatrix: TIdMatX; const AX, AB, AC, AD: TIdVecX);
var
  LRows, LI, LJ: Integer;
  LSum, LT: Double;
begin
  LRows := AMatrix.NumRows;
  Assert(LRows = AMatrix.NumColumns);
  Assert((AX.Size >= LRows) and (AB.Size >= LRows));
  Assert((AC.Size >= LRows) and (AD.Size >= LRows));
  for LI := 0 to LRows - 1 do
  begin
    AX[LI] := AB[LI];
  end;
  // multiply b with transpose of Q
  for LI := 0 to LRows - 2 do
  begin
    LSum := 0.0;
    for LJ := LI to LRows - 1 do
    begin
      LSum := LSum + AMatrix[LJ, LI] * AX[LJ];
    end;
    LT := LSum / AC[LI];
    for LJ := LI to LRows - 1 do
    begin
      AX[LJ] := AX[LJ] - LT * AMatrix[LJ, LI];
    end;
  end;
  // backsubstitution with R
  for LI := LRows - 1 downto 0 do
  begin
    LSum := AX[LI];
    for LJ := LI + 1 to LRows - 1 do
    begin
      LSum := LSum - AMatrix[LI, LJ] * AX[LJ];
    end;
    AX[LI] := LSum / AD[LI];
  end;
end;

class procedure TIdMatXQr.Solve(const AMatrix: TIdMatX; const AX, AB: TIdVecX; const AR: TIdMatX);
var
  LRows, LI, LJ: Integer;
  LSum: Double;
begin
  LRows := AMatrix.NumRows;
  Assert(LRows = AMatrix.NumColumns);
  // multiply b with transpose of Q
  AMatrix.TransposeMultiply(AX, AB);
  // backsubstitution with R
  for LI := LRows - 1 downto 0 do
  begin
    LSum := AX[LI];
    for LJ := LI + 1 to LRows - 1 do
    begin
      LSum := LSum - AR[LI, LJ] * AX[LJ];
    end;
    AX[LI] := LSum / AR[LI, LI];
  end;
end;

class procedure TIdMatXQr.Inverse(const AMatrix, AInverse: TIdMatX; const AC, AD: TIdVecX);
var
  LRows, LI, LJ: Integer;
  LX, LB: TIdVecX;
begin
  LRows := AMatrix.NumRows;
  Assert(LRows = AMatrix.NumColumns);
  LX := TIdVecX.Create(LRows);
  LB := TIdVecX.Create(LRows);
  try
    LB.Zero;
    AInverse.SetSize(LRows, AMatrix.NumColumns);
    for LI := 0 to LRows - 1 do
    begin
      LB[LI] := 1.0;
      Solve(AMatrix, LX, LB, AC, AD);
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

class procedure TIdMatXQr.UnpackFactors(const AMatrix, AQ, AR: TIdMatX; const AC, AD: TIdVecX);
var
  LRows, LColumns, LI, LJ, LK: Integer;
  LSum: Double;
begin
  LRows := AMatrix.NumRows;
  LColumns := AMatrix.NumColumns;
  AQ.Identity(LRows, LColumns);
  for LI := 0 to LColumns - 2 do
  begin
    if AC[LI] = 0.0 then
      Continue;
    for LJ := 0 to LRows - 1 do
    begin
      LSum := 0.0;
      for LK := LI to LColumns - 1 do
      begin
        LSum := LSum + AMatrix[LK, LI] * AQ[LJ, LK];
      end;
      LSum := LSum / AC[LI];
      for LK := LI to LColumns - 1 do
      begin
        AQ[LJ, LK] := AQ[LJ, LK] - LSum * AMatrix[LK, LI];
      end;
    end;
  end;
  AR.Zero(LRows, LColumns);
  for LI := 0 to LRows - 1 do
  begin
    AR[LI, LI] := AD[LI];
    for LJ := LI + 1 to LColumns - 1 do
    begin
      AR[LI, LJ] := AMatrix[LI, LJ];
    end;
  end;
end;

class procedure TIdMatXQr.MultiplyFactors(const AMatrix, AResult: TIdMatX; const AC,
  AD: TIdVecX);
var
  LRows, LColumns, LI, LJ, LK: Integer;
  LSum: Double;
  LQ: TIdMatX;
begin
  LRows := AMatrix.NumRows;
  LColumns := AMatrix.NumColumns;
  LQ := TIdMatX.Create;
  try
    LQ.Identity(LRows, LColumns);
    for LI := 0 to LColumns - 2 do
    begin
      if AC[LI] = 0.0 then
        Continue;
      for LJ := 0 to LRows - 1 do
      begin
        LSum := 0.0;
        for LK := LI to LColumns - 1 do
        begin
          LSum := LSum + AMatrix[LK, LI] * LQ[LJ, LK];
        end;
        LSum := LSum / AC[LI];
        for LK := LI to LColumns - 1 do
        begin
          LQ[LJ, LK] := LQ[LJ, LK] - LSum * AMatrix[LK, LI];
        end;
      end;
    end;
    for LI := 0 to LRows - 1 do
    begin
      for LJ := 0 to LColumns - 1 do
      begin
        LSum := LQ[LI, LJ] * AD[LI];
        for LK := 0 to LI - 1 do
        begin
          LSum := LSum + LQ[LI, LK] * AMatrix[LJ, LK];
        end;
        AResult[LI, LJ] := LSum;
      end;
    end;
  finally
    LQ.Free;
  end;
end;

end.
