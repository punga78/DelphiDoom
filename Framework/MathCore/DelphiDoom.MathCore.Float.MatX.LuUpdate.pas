{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdMatXLuUpdate, LU updates         }
{                                                                              }
{  Port of the LU_Update* members of idMatX (idlib\math\Matrix.cpp) of the     }
{  Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax  }
{  Media company. Based on the Doom 3 GPL Source Code (id Software).           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Framework\IdLib); the repository as a whole is GPL v2 or later.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.MatX.LuUpdate;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.MatX, DelphiDoom.MathCore.Float.Types,
  DelphiDoom.MathCore.Float.VecX;

type
  /// <summary>
  ///   The functions that update an in-place LU factorization (made by
  ///   <c>TIdMatX.LuFactor</c>) when the matrix changes by a rank one term, a row and a column,
  ///   a new last row and column, or a removed row and column. They are the
  ///   <c>LU_UpdateRankOne</c>, <c>LU_UpdateRowColumn</c>, <c>LU_UpdateIncrement</c> and
  ///   <c>LU_UpdateDecrement</c> members of idMatX. The row permutation <c>AIndex</c> may be nil
  ///   (no pivoting). Each function returns false when a pivot becomes zero.
  /// </summary>
  TIdMatXLuUpdate = class sealed
  public
    /// <summary>The factors of LU + alpha * v * w'</summary>
    class function UpdateRankOne(const AMatrix: TIdMatX; const AV, AW: TIdVecX;
      AAlpha: Single; const AIndex: PIdIntegerArray): Boolean; static;
    /// <summary>
    ///   The factors of LU + the matrix that is zero but for the row r (d, b, e) and the column
    ///   r (a, b, c), where a = v[0,r-1], b = v[r], c = v[r+1,rows-1], d = w[0,r-1], w[r] = 0 and
    ///   e = w[r+1,columns-1]
    /// </summary>
    class function UpdateRowColumn(const AMatrix: TIdMatX; const AV, AW: TIdVecX;
      const ARow: Integer; const AIndex: PIdIntegerArray): Boolean; static;
    /// <summary>
    ///   The factors of [A a; c b] with a = v[0,rows-1], b = v[rows] and c = w[0,columns-1];
    ///   the matrix grows by one row and one column
    /// </summary>
    class function UpdateIncrement(const AMatrix: TIdMatX; const AV, AW: TIdVecX;
      const AIndex: PIdIntegerArray): Boolean; static;
    /// <summary>
    ///   The factors of the matrix without row r and column r; v and w are the column and the
    ///   row of the original matrix. With an index u is row index[r] of the original matrix,
    ///   without it u = w
    /// </summary>
    class function UpdateDecrement(const AMatrix: TIdMatX; const AV, AW, AU: TIdVecX;
      const ARow: Integer; const AIndex: PIdIntegerArray): Boolean; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Math;

{ TIdMatXLuUpdate }

class function TIdMatXLuUpdate.UpdateRankOne(const AMatrix: TIdMatX; const AV, AW: TIdVecX;
  AAlpha: Single; const AIndex: PIdIntegerArray): Boolean;
var
  LRows, LColumns, LRowIndex, LOther, LMax: Integer;
  LY, LZ: TArray<Single>;
  LDiagonal, LBeta, LP0, LP1, LD: Double;
begin
  LRows := AMatrix.NumRows;
  LColumns := AMatrix.NumColumns;
  Assert(AV.Size >= LColumns);
  Assert(AW.Size >= LRows);
  SetLength(LY, AV.Size);
  SetLength(LZ, AW.Size);
  if AIndex <> nil then
  begin
    for LRowIndex := 0 to LRows - 1 do
    begin
      LY[LRowIndex] := AAlpha * AV[AIndex^[LRowIndex]];
    end;
  end
  else
  begin
    for LRowIndex := 0 to LRows - 1 do
    begin
      LY[LRowIndex] := AAlpha * AV[LRowIndex];
    end;
  end;
  for LRowIndex := 0 to AW.Size - 1 do
  begin
    LZ[LRowIndex] := AW[LRowIndex];
  end;
  LMax := LRows;
  if LColumns < LMax then
    LMax := LColumns;
  for LRowIndex := 0 to LMax - 1 do
  begin
    LDiagonal := AMatrix[LRowIndex, LRowIndex];
    LP0 := LY[LRowIndex];
    LP1 := LZ[LRowIndex];
    LDiagonal := LDiagonal + LP0 * LP1;
    if LDiagonal = 0.0 then
      Exit(False);
    LBeta := LP1 / LDiagonal;
    AMatrix[LRowIndex, LRowIndex] := LDiagonal;
    for LOther := LRowIndex + 1 to LColumns - 1 do
    begin
      LD := AMatrix[LRowIndex, LOther];
      LD := LD + LP0 * LZ[LOther];
      LZ[LOther] := LZ[LOther] - LBeta * LD;
      AMatrix[LRowIndex, LOther] := LD;
    end;
    for LOther := LRowIndex + 1 to LRows - 1 do
    begin
      LD := AMatrix[LOther, LRowIndex];
      LY[LOther] := LY[LOther] - LP0 * LD;
      LD := LD + LBeta * LY[LOther];
      AMatrix[LOther, LRowIndex] := LD;
    end;
  end;
  Result := True;
end;

class function TIdMatXLuUpdate.UpdateRowColumn(const AMatrix: TIdMatX; const AV, AW: TIdVecX;
  const ARow: Integer; const AIndex: PIdIntegerArray): Boolean;
var
  LRows, LColumns, LI, LJ, LMin, LMax, LRp: Integer;
  LY0, LZ0, LY1, LZ1: TArray<Single>;
  LDiagonal, LBeta0, LBeta1, LP0, LP1, LQ0, LQ1, LD: Double;
  LBetaSingle: Single;
begin
  LRows := AMatrix.NumRows;
  LColumns := AMatrix.NumColumns;
  Assert(AV.Size >= LColumns);
  Assert(AW.Size >= LRows);
  Assert((ARow >= 0) and (ARow < LColumns) and (ARow < LRows));
  Assert(AW[ARow] = 0.0);
  SetLength(LY0, AV.Size);
  SetLength(LZ0, AW.Size);
  SetLength(LY1, AV.Size);
  SetLength(LZ1, AW.Size);
  if AIndex <> nil then
  begin
    for LI := 0 to LRows - 1 do
    begin
      LY0[LI] := AV[AIndex^[LI]];
    end;
    LRp := ARow;
    for LI := 0 to LRows - 1 do
    begin
      if AIndex^[LI] = ARow then
      begin
        LRp := LI;
        Break;
      end;
    end;
  end
  else
  begin
    for LI := 0 to AV.Size - 1 do
    begin
      LY0[LI] := AV[LI];
    end;
    LRp := ARow;
  end;
  LY1[LRp] := 1.0;
  LZ0[ARow] := 1.0;
  for LI := 0 to AW.Size - 1 do
  begin
    LZ1[LI] := AW[LI];
  end;
  // update the beginning of the to be updated row and column
  LMin := ARow;
  if LRp < LMin then
    LMin := LRp;
  for LI := 0 to LMin - 1 do
  begin
    LP0 := LY0[LI];
    // float division in the C++
    LBetaSingle := LZ1[LI] / AMatrix[LI, LI];
    LBeta1 := LBetaSingle;
    AMatrix[LI, ARow] := AMatrix[LI, ARow] + LP0;
    for LJ := LI + 1 to LColumns - 1 do
    begin
      LZ1[LJ] := LZ1[LJ] - LBeta1 * AMatrix[LI, LJ];
    end;
    for LJ := LI + 1 to LRows - 1 do
    begin
      LY0[LJ] := LY0[LJ] - LP0 * AMatrix[LJ, LI];
    end;
    AMatrix[LRp, LI] := AMatrix[LRp, LI] + LBeta1;
  end;
  // update the lower right corner starting at r,r
  LMax := LRows;
  if LColumns < LMax then
    LMax := LColumns;
  for LI := LMin to LMax - 1 do
  begin
    LDiagonal := AMatrix[LI, LI];
    LP0 := LY0[LI];
    LP1 := LZ0[LI];
    LDiagonal := LDiagonal + LP0 * LP1;
    if LDiagonal = 0.0 then
      Exit(False);
    LBeta0 := LP1 / LDiagonal;
    LQ0 := LY1[LI];
    LQ1 := LZ1[LI];
    LDiagonal := LDiagonal + LQ0 * LQ1;
    if LDiagonal = 0.0 then
      Exit(False);
    LBeta1 := LQ1 / LDiagonal;
    AMatrix[LI, LI] := LDiagonal;
    for LJ := LI + 1 to LColumns - 1 do
    begin
      LD := AMatrix[LI, LJ];
      LD := LD + LP0 * LZ0[LJ];
      LZ0[LJ] := LZ0[LJ] - LBeta0 * LD;
      LD := LD + LQ0 * LZ1[LJ];
      LZ1[LJ] := LZ1[LJ] - LBeta1 * LD;
      AMatrix[LI, LJ] := LD;
    end;
    for LJ := LI + 1 to LRows - 1 do
    begin
      LD := AMatrix[LJ, LI];
      LY0[LJ] := LY0[LJ] - LP0 * LD;
      LD := LD + LBeta0 * LY0[LJ];
      LY1[LJ] := LY1[LJ] - LQ0 * LD;
      LD := LD + LBeta1 * LY1[LJ];
      AMatrix[LJ, LI] := LD;
    end;
  end;
  Result := True;
end;

class function TIdMatXLuUpdate.UpdateIncrement(const AMatrix: TIdMatX; const AV, AW: TIdVecX;
  const AIndex: PIdIntegerArray): Boolean;
var
  LRows, LI, LJ: Integer;
  LSum: Single;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  Assert(AV.Size >= AMatrix.NumRows + 1);
  Assert(AW.Size >= AMatrix.NumColumns + 1);
  AMatrix.ChangeSize(AMatrix.NumRows + 1, AMatrix.NumColumns + 1, True);
  LRows := AMatrix.NumRows;
  // add row to L
  for LI := 0 to LRows - 2 do
  begin
    LSum := AW[LI];
    for LJ := 0 to LI - 1 do
    begin
      LSum := LSum - AMatrix[LRows - 1, LJ] * AMatrix[LJ, LI];
    end;
    AMatrix[LRows - 1, LI] := LSum / AMatrix[LI, LI];
  end;
  // add row to the permutation index
  if AIndex <> nil then
    AIndex^[LRows - 1] := LRows - 1;
  // add column to U
  for LI := 0 to LRows - 1 do
  begin
    if AIndex <> nil then
      LSum := AV[AIndex^[LI]]
    else
      LSum := AV[LI];
    for LJ := 0 to LI - 1 do
    begin
      LSum := LSum - AMatrix[LI, LJ] * AMatrix[LJ, LRows - 1];
    end;
    AMatrix[LI, LRows - 1] := LSum;
  end;
  Result := True;
end;

class function TIdMatXLuUpdate.UpdateDecrement(const AMatrix: TIdMatX; const AV, AW,
  AU: TIdVecX; const ARow: Integer; const AIndex: PIdIntegerArray): Boolean;
var
  LRows, LI, LP, LSwapped: Integer;
  LV1, LW1, LTemp: TIdVecX;
  LValue: Single;
begin
  LRows := AMatrix.NumRows;
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  Assert(AV.Size >= AMatrix.NumColumns);
  Assert(AW.Size >= LRows);
  Assert((ARow >= 0) and (ARow < LRows));
  LV1 := nil;
  LW1 := nil;
  try
    if AIndex <> nil then
    begin
      // find the pivot row
      LP := 0;
      for LI := 0 to LRows - 1 do
      begin
        if AIndex^[LI] = ARow then
        begin
          LP := LI;
          Break;
        end;
      end;
      // update the row and column to identity
      LV1 := AV.Negative;
      LW1 := AU.Negative;
      if LP <> ARow then
      begin
        LValue := LV1[AIndex^[ARow]];
        LV1[AIndex^[ARow]] := LV1[AIndex^[LP]];
        LV1[AIndex^[LP]] := LValue;
        LSwapped := AIndex^[ARow];
        AIndex^[ARow] := AIndex^[LP];
        AIndex^[LP] := LSwapped;
      end;
      LV1[ARow] := LV1[ARow] + 1.0;
      LW1[ARow] := 0.0;
      if not UpdateRowColumn(AMatrix, LV1, LW1, ARow, AIndex) then
        Exit(False);
      if LP <> ARow then
      begin
        // move row index[r] of the original matrix to row index[p] of the original matrix
        LV1.Zero;
        LV1[AIndex^[LP]] := 1.0;
        LTemp := AU.Subtract(AW);
        try
          LW1.Assign(LTemp);
        finally
          LTemp.Free;
        end;
        if not UpdateRankOne(AMatrix, LV1, LW1, 1.0, AIndex) then
          Exit(False);
      end;
      // remove the row from the permutation index
      for LI := ARow to LRows - 2 do
      begin
        AIndex^[LI] := AIndex^[LI + 1];
      end;
      for LI := 0 to LRows - 2 do
      begin
        if AIndex^[LI] > ARow then
          AIndex^[LI] := AIndex^[LI] - 1;
      end;
    end
    else
    begin
      LV1 := AV.Negative;
      LW1 := AW.Negative;
      LV1[ARow] := LV1[ARow] + 1.0;
      LW1[ARow] := 0.0;
      if not UpdateRowColumn(AMatrix, LV1, LW1, ARow, AIndex) then
        Exit(False);
    end;
    // physically remove the row and column
    AMatrix.UpdateDecrement(ARow);
  finally
    LW1.Free;
    LV1.Free;
  end;
  Result := True;
end;

end.
