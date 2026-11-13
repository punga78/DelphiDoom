{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdMatXEigen, eigenvalues and       }
{  eigenvectors of a symmetric matrix                                          }
{                                                                              }
{  Port of HouseholderReduction, QL, Eigen_SolveSymmetricTriDiagonal,          }
{  Eigen_SolveSymmetric, Eigen_SortIncreasing and Eigen_SortDecreasing of      }
{  idMatX (idlib\math\Matrix.cpp) of the Doom 3 GPL Source Code. Copyright     }
{  (C) 1999-2011 id Software LLC, a ZeniMax Media company. Based on the Doom 3 }
{  GPL Source Code (id Software).                                              }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.MatX.Eigen;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.MatX, DelphiDoom.MathCore.Float.VecX;

type
  /// <summary>
  ///   Eigenvalues and eigenvectors of a symmetric matrix by Householder reduction and the QL
  ///   algorithm. The column i of the matrix holds the eigenvector of <c>eigenValues[i]</c> on
  ///   exit. The solver of the general (non symmetric) case of idMatX
  ///   (<c>Eigen_Solve</c>: Hessenberg reduction and real Schur form) is not ported.
  /// </summary>
  TIdMatXEigen = class sealed
  strict private
    class procedure HouseholderReduction(const AMatrix: TIdMatX; const ADiagonal,
      ASubDiagonal: TIdVecX); static;
    class function QL(const AMatrix: TIdMatX; const ADiagonal, ASubDiagonal: TIdVecX): Boolean; static;
  public
    /// <summary>Eigenvalues and eigenvectors of a symmetric tri-diagonal matrix</summary>
    class function SolveSymmetricTriDiagonal(const AMatrix: TIdMatX;
      const AEigenValues: TIdVecX): Boolean; static;
    /// <summary>Eigenvalues and eigenvectors of a symmetric matrix; false if QL does not converge</summary>
    class function SolveSymmetric(const AMatrix: TIdMatX; const AEigenValues: TIdVecX): Boolean; static;
    class procedure SortIncreasing(const AMatrix: TIdMatX; const AEigenValues: TIdVecX); static;
    class procedure SortDecreasing(const AMatrix: TIdMatX; const AEigenValues: TIdVecX); static;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.MathCore.Float.Types;

{ TIdMatXEigen }

class procedure TIdMatXEigen.HouseholderReduction(const AMatrix: TIdMatX; const ADiagonal,
  ASubDiagonal: TIdVecX);
var
  LRows, LI0, LI1, LI2, LI3: Integer;
  LH, LF, LG, LInvH, LHalfFDivH, LScale, LInvScale, LSum: Single;
  LM: PIdSingleArray;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  LRows := AMatrix.NumRows;
  LM := AMatrix.Data;
  ADiagonal.SetSize(LRows);
  ASubDiagonal.SetSize(LRows);
  LI0 := LRows - 1;
  LI3 := LRows - 2;
  while LI0 >= 1 do
  begin
    LH := 0.0;
    LScale := 0.0;
    if LI3 > 0 then
    begin
      for LI2 := 0 to LI3 do
      begin
        LScale := LScale + TIdMath.Fabs(LM^[LI0 * LRows + LI2]);
      end;
      if LScale = 0.0 then
        ASubDiagonal[LI0] := LM^[LI0 * LRows + LI3]
      else
      begin
        LInvScale := 1.0 / LScale;
        for LI2 := 0 to LI3 do
        begin
          LM^[LI0 * LRows + LI2] := LM^[LI0 * LRows + LI2] * LInvScale;
          LH := LH + LM^[LI0 * LRows + LI2] * LM^[LI0 * LRows + LI2];
        end;
        LF := LM^[LI0 * LRows + LI3];
        LG := TIdMath.Sqrt(LH);
        if LF > 0.0 then
          LG := -LG;
        ASubDiagonal[LI0] := LScale * LG;
        LH := LH - LF * LG;
        LM^[LI0 * LRows + LI3] := LF - LG;
        LF := 0.0;
        LInvH := 1.0 / LH;
        for LI1 := 0 to LI3 do
        begin
          LM^[LI1 * LRows + LI0] := LM^[LI0 * LRows + LI1] * LInvH;
          LG := 0.0;
          for LI2 := 0 to LI1 do
          begin
            LG := LG + LM^[LI1 * LRows + LI2] * LM^[LI0 * LRows + LI2];
          end;
          for LI2 := LI1 + 1 to LI3 do
          begin
            LG := LG + LM^[LI2 * LRows + LI1] * LM^[LI0 * LRows + LI2];
          end;
          ASubDiagonal[LI1] := LG * LInvH;
          LF := LF + ASubDiagonal[LI1] * LM^[LI0 * LRows + LI1];
        end;
        LHalfFDivH := 0.5 * LF * LInvH;
        for LI1 := 0 to LI3 do
        begin
          LF := LM^[LI0 * LRows + LI1];
          LG := ASubDiagonal[LI1] - LHalfFDivH * LF;
          ASubDiagonal[LI1] := LG;
          for LI2 := 0 to LI1 do
          begin
            LM^[LI1 * LRows + LI2] := LM^[LI1 * LRows + LI2] -
              (LF * ASubDiagonal[LI2] + LG * LM^[LI0 * LRows + LI2]);
          end;
        end;
      end;
    end
    else
      ASubDiagonal[LI0] := LM^[LI0 * LRows + LI3];
    ADiagonal[LI0] := LH;
    Dec(LI0);
    Dec(LI3);
  end;
  ADiagonal[0] := 0.0;
  ASubDiagonal[0] := 0.0;
  LI0 := 0;
  LI3 := -1;
  while LI0 <= LRows - 1 do
  begin
    if ADiagonal[LI0] <> 0.0 then
    begin
      for LI1 := 0 to LI3 do
      begin
        LSum := 0.0;
        for LI2 := 0 to LI3 do
        begin
          LSum := LSum + LM^[LI0 * LRows + LI2] * LM^[LI2 * LRows + LI1];
        end;
        for LI2 := 0 to LI3 do
        begin
          LM^[LI2 * LRows + LI1] := LM^[LI2 * LRows + LI1] - LSum * LM^[LI2 * LRows + LI0];
        end;
      end;
    end;
    ADiagonal[LI0] := LM^[LI0 * LRows + LI0];
    LM^[LI0 * LRows + LI0] := 1.0;
    for LI1 := 0 to LI3 do
    begin
      LM^[LI1 * LRows + LI0] := 0.0;
      LM^[LI0 * LRows + LI1] := 0.0;
    end;
    Inc(LI0);
    Inc(LI3);
  end;
  // re-order
  LI0 := 1;
  LI3 := 0;
  while LI0 < LRows do
  begin
    ASubDiagonal[LI3] := ASubDiagonal[LI0];
    Inc(LI0);
    Inc(LI3);
  end;
  ASubDiagonal[LRows - 1] := 0.0;
end;

class function TIdMatXEigen.QL(const AMatrix: TIdMatX; const ADiagonal,
  ASubDiagonal: TIdVecX): Boolean;
const
  MaxIterations = 32;
var
  LRows, LI0, LI1, LI2, LI3, LI4: Integer;
  LA, LB, LF, LG, LR, LP, LS, LC: Single;
  LM: PIdSingleArray;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  LRows := AMatrix.NumRows;
  LM := AMatrix.Data;
  for LI0 := 0 to LRows - 1 do
  begin
    LI1 := 0;
    while LI1 < MaxIterations do
    begin
      LI2 := LI0;
      while LI2 <= LRows - 2 do
      begin
        LA := TIdMath.Fabs(ADiagonal[LI2]) + TIdMath.Fabs(ADiagonal[LI2 + 1]);
        if TIdMath.Fabs(ASubDiagonal[LI2]) + LA = LA then
          Break;
        Inc(LI2);
      end;
      if LI2 = LI0 then
        Break;
      LG := (ADiagonal[LI0 + 1] - ADiagonal[LI0]) / (2.0 * ASubDiagonal[LI0]);
      LR := TIdMath.Sqrt(LG * LG + 1.0);
      if LG < 0.0 then
        LG := ADiagonal[LI2] - ADiagonal[LI0] + ASubDiagonal[LI0] / (LG - LR)
      else
        LG := ADiagonal[LI2] - ADiagonal[LI0] + ASubDiagonal[LI0] / (LG + LR);
      LS := 1.0;
      LC := 1.0;
      LP := 0.0;
      LI3 := LI2 - 1;
      while LI3 >= LI0 do
      begin
        LF := LS * ASubDiagonal[LI3];
        LB := LC * ASubDiagonal[LI3];
        if TIdMath.Fabs(LF) >= TIdMath.Fabs(LG) then
        begin
          LC := LG / LF;
          LR := TIdMath.Sqrt(LC * LC + 1.0);
          ASubDiagonal[LI3 + 1] := LF * LR;
          LS := 1.0 / LR;
          LC := LC * LS;
        end
        else
        begin
          LS := LF / LG;
          LR := TIdMath.Sqrt(LS * LS + 1.0);
          ASubDiagonal[LI3 + 1] := LG * LR;
          LC := 1.0 / LR;
          LS := LS * LC;
        end;
        LG := ADiagonal[LI3 + 1] - LP;
        LR := (ADiagonal[LI3] - LG) * LS + 2.0 * LB * LC;
        LP := LS * LR;
        ADiagonal[LI3 + 1] := LG + LP;
        LG := LC * LR - LB;
        for LI4 := 0 to LRows - 1 do
        begin
          LF := LM^[LI4 * LRows + LI3 + 1];
          LM^[LI4 * LRows + LI3 + 1] := LS * LM^[LI4 * LRows + LI3] + LC * LF;
          LM^[LI4 * LRows + LI3] := LC * LM^[LI4 * LRows + LI3] - LS * LF;
        end;
        Dec(LI3);
      end;
      ADiagonal[LI0] := ADiagonal[LI0] - LP;
      ASubDiagonal[LI0] := LG;
      ASubDiagonal[LI2] := 0.0;
      Inc(LI1);
    end;
    if LI1 = MaxIterations then
      Exit(False);
  end;
  Result := True;
end;

class function TIdMatXEigen.SolveSymmetricTriDiagonal(const AMatrix: TIdMatX;
  const AEigenValues: TIdVecX): Boolean;
var
  LI, LRows: Integer;
  LSubDiagonal: TIdVecX;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  LRows := AMatrix.NumRows;
  LSubDiagonal := TIdVecX.Create(LRows);
  try
    AEigenValues.SetSize(LRows);
    for LI := 0 to LRows - 2 do
    begin
      AEigenValues[LI] := AMatrix[LI, LI];
      LSubDiagonal[LI] := AMatrix[LI + 1, LI];
    end;
    AEigenValues[LRows - 1] := AMatrix[LRows - 1, LRows - 1];
    AMatrix.Identity;
    Result := QL(AMatrix, AEigenValues, LSubDiagonal);
  finally
    LSubDiagonal.Free;
  end;
end;

class function TIdMatXEigen.SolveSymmetric(const AMatrix: TIdMatX;
  const AEigenValues: TIdVecX): Boolean;
var
  LSubDiagonal: TIdVecX;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  LSubDiagonal := TIdVecX.Create(AMatrix.NumRows);
  try
    AEigenValues.SetSize(AMatrix.NumRows);
    HouseholderReduction(AMatrix, AEigenValues, LSubDiagonal);
    Result := QL(AMatrix, AEigenValues, LSubDiagonal);
  finally
    LSubDiagonal.Free;
  end;
end;

class procedure TIdMatXEigen.SortIncreasing(const AMatrix: TIdMatX; const AEigenValues: TIdVecX);
var
  LI, LJ, LK: Integer;
  LMin: Single;
begin
  for LI := 0 to AMatrix.NumRows - 2 do
  begin
    LJ := LI;
    LMin := AEigenValues[LJ];
    for LK := LI + 1 to AMatrix.NumRows - 1 do
    begin
      if AEigenValues[LK] < LMin then
      begin
        LJ := LK;
        LMin := AEigenValues[LJ];
      end;
    end;
    if LJ <> LI then
    begin
      AEigenValues.SwapElements(LI, LJ);
      AMatrix.SwapColumns(LI, LJ);
    end;
  end;
end;

class procedure TIdMatXEigen.SortDecreasing(const AMatrix: TIdMatX; const AEigenValues: TIdVecX);
var
  LI, LJ, LK: Integer;
  LMax: Single;
begin
  for LI := 0 to AMatrix.NumRows - 2 do
  begin
    LJ := LI;
    LMax := AEigenValues[LJ];
    for LK := LI + 1 to AMatrix.NumRows - 1 do
    begin
      if AEigenValues[LK] > LMax then
      begin
        LJ := LK;
        LMax := AEigenValues[LJ];
      end;
    end;
    if LJ <> LI then
    begin
      AEigenValues.SwapElements(LI, LJ);
      AMatrix.SwapColumns(LI, LJ);
    end;
  end;
end;

end.
