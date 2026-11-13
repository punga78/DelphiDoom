{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdMatXInverse, inversion and       }
{  updates of an inverse                                                       }
{                                                                              }
{  Port of the Inverse_* members of idMatX (idlib\math\Matrix.cpp) of the      }
{  Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a          }
{  ZeniMax Media company. Based on the Doom 3 GPL Source Code (id Software).   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.MatX.Inverse;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.MatX, DelphiDoom.MathCore.Float.VecX;

type
  /// <summary>
  ///   Gauss-Jordan inversion with full pivoting and the formulas that update an inverse
  ///   in place when the matrix changes (Sherman-Morrison and its row/column variants).
  /// </summary>
  TIdMatXInverse = class sealed
  public
    /// <summary>In-place inversion; false if the matrix is not invertible</summary>
    class function GaussJordan(const AMatrix: TIdMatX): Boolean; static;
    /// <summary>Updates the inverse for the matrix A + alpha * v * w'</summary>
    class function UpdateRankOne(const AMatrix: TIdMatX; const AV, AW: TIdVecX;
      AAlpha: Single): Boolean; static;
    class function UpdateRowColumn(const AMatrix: TIdMatX; const AV, AW: TIdVecX;
      const ARow: Integer): Boolean; static;
    class function UpdateIncrement(const AMatrix: TIdMatX; const AV, AW: TIdVecX): Boolean; static;
    class function UpdateDecrement(const AMatrix: TIdMatX; const AV, AW: TIdVecX;
      const ARow: Integer): Boolean; static;
    /// <summary>Solves Ax = b with A inverted</summary>
    class procedure Solve(const AMatrix: TIdMatX; const AX, AB: TIdVecX); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Math, DelphiDoom.MathCore.Float.Types;

{ TIdMatXInverse }

class function TIdMatXInverse.GaussJordan(const AMatrix: TIdMatX): Boolean;
var
  LRows, LI, LJ, LK, LR, LC: Integer;
  LD, LMax: Single;
  LColumnIndex, LRowIndex: TArray<Integer>;
  LPivot: TArray<Boolean>;
  LData: PIdSingleArray;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  LRows := AMatrix.NumRows;
  LData := AMatrix.Data;
  SetLength(LColumnIndex, LRows);
  SetLength(LRowIndex, LRows);
  SetLength(LPivot, LRows);
  for LI := 0 to LRows - 1 do
  begin
    LPivot[LI] := False;
  end;
  // elimination with full pivoting
  for LI := 0 to LRows - 1 do
  begin
    // search the whole matrix except for pivoted rows for the maximum absolute value
    LMax := 0.0;
    LR := 0;
    LC := 0;
    for LJ := 0 to LRows - 1 do
    begin
      if not LPivot[LJ] then
      begin
        for LK := 0 to LRows - 1 do
        begin
          if not LPivot[LK] then
          begin
            LD := TIdMath.Fabs(LData^[LJ * LRows + LK]);
            if LD > LMax then
            begin
              LMax := LD;
              LR := LJ;
              LC := LK;
            end;
          end;
        end;
      end;
    end;
    if LMax = 0.0 then
      Exit(False);
    LPivot[LC] := True;
    // swap rows such that entry (c,c) has the pivot entry
    if LR <> LC then
      AMatrix.SwapRows(LR, LC);
    // keep track of the row permutation
    LRowIndex[LI] := LR;
    LColumnIndex[LI] := LC;
    // scale the row to make the pivot entry equal to 1
    LD := 1.0 / LData^[LC * LRows + LC];
    LData^[LC * LRows + LC] := 1.0;
    for LK := 0 to LRows - 1 do
    begin
      LData^[LC * LRows + LK] := LData^[LC * LRows + LK] * LD;
    end;
    // zero out the pivot column entries in the other rows
    for LJ := 0 to LRows - 1 do
    begin
      if LJ <> LC then
      begin
        LD := LData^[LJ * LRows + LC];
        LData^[LJ * LRows + LC] := 0.0;
        for LK := 0 to LRows - 1 do
        begin
          LData^[LJ * LRows + LK] := LData^[LJ * LRows + LK] - LData^[LC * LRows + LK] * LD;
        end;
      end;
    end;
  end;
  // reorder rows to store the inverse of the original matrix
  for LJ := LRows - 1 downto 0 do
  begin
    if LRowIndex[LJ] <> LColumnIndex[LJ] then
    begin
      for LK := 0 to LRows - 1 do
      begin
        LD := LData^[LK * LRows + LRowIndex[LJ]];
        LData^[LK * LRows + LRowIndex[LJ]] := LData^[LK * LRows + LColumnIndex[LJ]];
        LData^[LK * LRows + LColumnIndex[LJ]] := LD;
      end;
    end;
  end;
  Result := True;
end;

class function TIdMatXInverse.UpdateRankOne(const AMatrix: TIdMatX; const AV, AW: TIdVecX;
  AAlpha: Single): Boolean;
var
  LI, LJ: Integer;
  LBeta, LS: Single;
  LY, LZ: TIdVecX;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  Assert((AV.Size >= AMatrix.NumColumns) and (AW.Size >= AMatrix.NumRows));
  LY := TIdVecX.Create(AMatrix.NumRows);
  LZ := TIdVecX.Create(AMatrix.NumRows);
  try
    AMatrix.Multiply(LY, AV);
    AMatrix.TransposeMultiply(LZ, AW);
    LBeta := 1.0 + AW.Multiply(LY);
    if LBeta = 0.0 then
      Exit(False);
    AAlpha := AAlpha / LBeta;
    for LI := 0 to AMatrix.NumRows - 1 do
    begin
      LS := LY[LI] * AAlpha;
      for LJ := 0 to AMatrix.NumColumns - 1 do
      begin
        AMatrix[LI, LJ] := AMatrix[LI, LJ] - LS * LZ[LJ];
      end;
    end;
    Result := True;
  finally
    LZ.Free;
    LY.Free;
  end;
end;

class function TIdMatXInverse.UpdateRowColumn(const AMatrix: TIdMatX; const AV, AW: TIdVecX;
  const ARow: Integer): Boolean;
var
  LS: TIdVecX;
  LSize: Integer;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  Assert((AV.Size >= AMatrix.NumColumns) and (AW.Size >= AMatrix.NumRows));
  Assert((ARow >= 0) and (ARow < AMatrix.NumRows));
  Assert(AW[ARow] = 0.0);
  LSize := AMatrix.NumRows;
  if AMatrix.NumColumns > LSize then
    LSize := AMatrix.NumColumns;
  LS := TIdVecX.Create(LSize);
  try
    LS.Zero;
    LS[ARow] := 1.0;
    if not UpdateRankOne(AMatrix, AV, LS, 1.0) then
      Exit(False);
    Result := UpdateRankOne(AMatrix, LS, AW, 1.0);
  finally
    LS.Free;
  end;
end;

class function TIdMatXInverse.UpdateIncrement(const AMatrix: TIdMatX; const AV,
  AW: TIdVecX): Boolean;
var
  LV2: TIdVecX;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  Assert((AV.Size >= AMatrix.NumRows + 1) and (AW.Size >= AMatrix.NumColumns + 1));
  AMatrix.ChangeSize(AMatrix.NumRows + 1, AMatrix.NumColumns + 1, True);
  AMatrix[AMatrix.NumRows - 1, AMatrix.NumRows - 1] := 1.0;
  LV2 := TIdVecX.Create(AMatrix.NumRows);
  try
    LV2.Assign(AV);
    // the copy takes the size of v (one more than the matrix, as in the C++ the data is a view)
    LV2[AMatrix.NumRows - 1] := LV2[AMatrix.NumRows - 1] - 1.0;
    Result := UpdateRowColumn(AMatrix, LV2, AW, AMatrix.NumRows - 1);
  finally
    LV2.Free;
  end;
end;

class function TIdMatXInverse.UpdateDecrement(const AMatrix: TIdMatX; const AV, AW: TIdVecX;
  const ARow: Integer): Boolean;
var
  LV1, LW1: TIdVecX;
  LIndex: Integer;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  Assert((AV.Size >= AMatrix.NumRows) and (AW.Size >= AMatrix.NumColumns));
  Assert((ARow >= 0) and (ARow < AMatrix.NumRows));
  LV1 := TIdVecX.Create(AMatrix.NumRows);
  LW1 := TIdVecX.Create(AMatrix.NumRows);
  try
    // update the row and column to identity
    for LIndex := 0 to AMatrix.NumRows - 1 do
    begin
      LV1[LIndex] := -AV[LIndex];
      LW1[LIndex] := -AW[LIndex];
    end;
    LV1[ARow] := LV1[ARow] + 1.0;
    LW1[ARow] := 0.0;
    if not UpdateRowColumn(AMatrix, LV1, LW1, ARow) then
      Exit(False);
    // physically remove the row and column
    AMatrix.UpdateDecrement(ARow);
    Result := True;
  finally
    LW1.Free;
    LV1.Free;
  end;
end;

class procedure TIdMatXInverse.Solve(const AMatrix: TIdMatX; const AX, AB: TIdVecX);
begin
  AMatrix.Multiply(AX, AB);
end;

end.
