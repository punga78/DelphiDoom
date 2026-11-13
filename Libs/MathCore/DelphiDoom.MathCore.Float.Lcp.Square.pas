{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdLcpSquare, the LCP solver for a  }
{  square matrix                                                               }
{                                                                              }
{  Port of idLCP_Square (idlib\math\Lcp.cpp) of the Doom 3 GPL Source Code.    }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. Based on  }
{  the Doom 3 GPL Source Code (id Software).                                   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Lcp.Square;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Lcp.Base, DelphiDoom.MathCore.Float.Types,
  DelphiDoom.MathCore.Float.VecX;

type
  /// <summary>
  ///   The solver for any square matrix: the clamped sub matrix is factored as L*U without
  ///   pivoting (idLCP_Square), the diagonal of U is stored as reciprocals.
  /// </summary>
  TIdLcpSquare = class(TIdLcpBase)
  protected
    function FactorClamped: Boolean; override;
    procedure SolveClamped(const AX: TIdVecX; const AB: PIdSingleArray); override;
    procedure AddClamped(const ARow: Integer; const AUseSolveCache: Boolean); override;
    procedure RemoveClamped(const ARow: Integer); override;
    procedure CalcForceDelta(const ADelta: Integer; const ADirection: Single); override;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math;

{ TIdLcpSquare }

function TIdLcpSquare.FactorClamped: Boolean;
var
  LI, LJ, LK, LColumns: Integer;
  LS, LD: Single;
  LClamped: PIdSingleArray;
begin
  LColumns := FClamped.NumColumns;
  LClamped := FClamped.Data;
  for LI := 0 to FNumClamped - 1 do
  begin
    for LJ := 0 to FNumClamped - 1 do
    begin
      LClamped^[LI * LColumns + LJ] := RowPointer(LI)^[LJ];
    end;
  end;
  for LI := 0 to FNumClamped - 1 do
  begin
    LS := TIdMath.Fabs(LClamped^[LI * LColumns + LI]);
    if LS = 0.0 then
      Exit(False);
    LD := 1.0 / LClamped^[LI * LColumns + LI];
    FDiagonal[LI] := LD;
    for LJ := LI + 1 to FNumClamped - 1 do
    begin
      LClamped^[LJ * LColumns + LI] := LClamped^[LJ * LColumns + LI] * LD;
    end;
    for LJ := LI + 1 to FNumClamped - 1 do
    begin
      LD := LClamped^[LJ * LColumns + LI];
      for LK := LI + 1 to FNumClamped - 1 do
      begin
        LClamped^[LJ * LColumns + LK] := LClamped^[LJ * LColumns + LK] -
          LD * LClamped^[LI * LColumns + LK];
      end;
    end;
  end;
  Result := True;
end;

procedure TIdLcpSquare.SolveClamped(const AX: TIdVecX; const AB: PIdSingleArray);
var
  LI, LJ, LColumns: Integer;
  LSum: Single;
  LClamped: PIdSingleArray;
begin
  LColumns := FClamped.NumColumns;
  LClamped := FClamped.Data;
  // solve L
  for LI := 0 to FNumClamped - 1 do
  begin
    LSum := AB^[LI];
    for LJ := 0 to LI - 1 do
    begin
      LSum := LSum - LClamped^[LI * LColumns + LJ] * AX[LJ];
    end;
    AX[LI] := LSum;
  end;
  // solve U
  for LI := FNumClamped - 1 downto 0 do
  begin
    LSum := AX[LI];
    for LJ := LI + 1 to FNumClamped - 1 do
    begin
      LSum := LSum - LClamped^[LI * LColumns + LJ] * AX[LJ];
    end;
    AX[LI] := LSum * FDiagonal[LI];
  end;
end;

procedure TIdLcpSquare.AddClamped(const ARow: Integer; const AUseSolveCache: Boolean);
var
  LI, LJ, LColumns: Integer;
  LSum: Single;
  LClamped: PIdSingleArray;
begin
  Assert(ARow >= FNumClamped);
  LColumns := FClamped.NumColumns;
  LClamped := FClamped.Data;
  // add a row at the bottom and a column at the right of the factored matrix for the clamped variables
  Swap(FNumClamped, ARow);
  // add row to L
  for LI := 0 to FNumClamped - 1 do
  begin
    LSum := RowPointer(FNumClamped)^[LI];
    for LJ := 0 to LI - 1 do
    begin
      LSum := LSum - LClamped^[FNumClamped * LColumns + LJ] * LClamped^[LJ * LColumns + LI];
    end;
    LClamped^[FNumClamped * LColumns + LI] := LSum * FDiagonal[LI];
  end;
  // add column to U
  for LI := 0 to FNumClamped do
  begin
    LSum := RowPointer(LI)^[FNumClamped];
    for LJ := 0 to LI - 1 do
    begin
      LSum := LSum - LClamped^[LI * LColumns + LJ] * LClamped^[LJ * LColumns + FNumClamped];
    end;
    LClamped^[LI * LColumns + FNumClamped] := LSum;
  end;
  FDiagonal[FNumClamped] := 1.0 / LClamped^[FNumClamped * LColumns + FNumClamped];
  Inc(FNumClamped);
end;

procedure TIdLcpSquare.RemoveClamped(const ARow: Integer);
var
  LI, LJ, LColumns: Integer;
  LY0, LZ0, LY1, LZ1: TArray<Single>;
  LDiag, LBeta0, LBeta1, LP0, LP1, LQ0, LQ1, LD: Double;
  LClamped: PIdSingleArray;
begin
  Assert(ARow < FNumClamped);
  Dec(FNumClamped);
  // no need to swap and update the factored matrix when the last row and column are removed
  if ARow = FNumClamped then
    Exit;
  LColumns := FClamped.NumColumns;
  LClamped := FClamped.Data;
  SetLength(LY0, FNumClamped);
  SetLength(LZ0, FNumClamped);
  SetLength(LY1, FNumClamped);
  SetLength(LZ1, FNumClamped);
  // the row/column need to be subtracted from the factorization
  for LI := 0 to FNumClamped - 1 do
  begin
    LY0[LI] := -RowPointer(LI)^[ARow];
  end;
  for LI := 0 to FNumClamped - 1 do
  begin
    LY1[LI] := 0.0;
    LZ0[LI] := 0.0;
  end;
  LY1[ARow] := 1.0;
  LZ0[ARow] := 1.0;
  for LI := 0 to FNumClamped - 1 do
  begin
    LZ1[LI] := -RowPointer(ARow)^[LI];
  end;
  // swap the to be removed row/column with the last row/column
  Swap(ARow, FNumClamped);
  // the swapped last row/column need to be added to the factorization
  for LI := 0 to FNumClamped - 1 do
  begin
    LY0[LI] := LY0[LI] + RowPointer(LI)^[ARow];
  end;
  for LI := 0 to FNumClamped - 1 do
  begin
    LZ1[LI] := LZ1[LI] + RowPointer(ARow)^[LI];
  end;
  LZ1[ARow] := 0.0;
  // update the beginning of the to be updated row and column
  for LI := 0 to ARow - 1 do
  begin
    LP0 := LY0[LI];
    LBeta1 := LZ1[LI] * FDiagonal[LI];
    LClamped^[LI * LColumns + ARow] := LClamped^[LI * LColumns + ARow] + LP0;
    for LJ := LI + 1 to FNumClamped - 1 do
    begin
      LZ1[LJ] := LZ1[LJ] - LBeta1 * LClamped^[LI * LColumns + LJ];
    end;
    for LJ := LI + 1 to FNumClamped - 1 do
    begin
      LY0[LJ] := LY0[LJ] - LP0 * LClamped^[LJ * LColumns + LI];
    end;
    LClamped^[ARow * LColumns + LI] := LClamped^[ARow * LColumns + LI] + LBeta1;
  end;
  // update the lower right corner starting at r,r
  for LI := ARow to FNumClamped - 1 do
  begin
    LDiag := LClamped^[LI * LColumns + LI];
    LP0 := LY0[LI];
    LP1 := LZ0[LI];
    LDiag := LDiag + LP0 * LP1;
    if LDiag = 0.0 then
    begin
      Print('idLCP_Square::RemoveClamped: updating factorization failed');
      Exit;
    end;
    LBeta0 := LP1 / LDiag;
    LQ0 := LY1[LI];
    LQ1 := LZ1[LI];
    LDiag := LDiag + LQ0 * LQ1;
    if LDiag = 0.0 then
    begin
      Print('idLCP_Square::RemoveClamped: updating factorization failed');
      Exit;
    end;
    LD := 1.0 / LDiag;
    LBeta1 := LQ1 * LD;
    LClamped^[LI * LColumns + LI] := LDiag;
    FDiagonal[LI] := LD;
    for LJ := LI + 1 to FNumClamped - 1 do
    begin
      LD := LClamped^[LI * LColumns + LJ];
      LD := LD + LP0 * LZ0[LJ];
      LZ0[LJ] := LZ0[LJ] - LBeta0 * LD;
      LD := LD + LQ0 * LZ1[LJ];
      LZ1[LJ] := LZ1[LJ] - LBeta1 * LD;
      LClamped^[LI * LColumns + LJ] := LD;
    end;
    for LJ := LI + 1 to FNumClamped - 1 do
    begin
      LD := LClamped^[LJ * LColumns + LI];
      LY0[LJ] := LY0[LJ] - LP0 * LD;
      LD := LD + LBeta0 * LY0[LJ];
      LY1[LJ] := LY1[LJ] - LQ0 * LD;
      LD := LD + LBeta1 * LY1[LJ];
      LClamped^[LJ * LColumns + LI] := LD;
    end;
  end;
end;

procedure TIdLcpSquare.CalcForceDelta(const ADelta: Integer; const ADirection: Single);
var
  LI: Integer;
  LColumn: TArray<Single>;
begin
  FDeltaForce[ADelta] := ADirection;
  if FNumClamped = 0 then
    Exit;
  // get column d of matrix
  SetLength(LColumn, FNumClamped);
  for LI := 0 to FNumClamped - 1 do
  begin
    LColumn[LI] := RowPointer(LI)^[ADelta];
  end;
  // solve force delta
  SolveClamped(FDeltaForce, PIdSingleArray(LColumn));
  // flip force delta based on direction
  if ADirection > 0.0 then
  begin
    for LI := 0 to FNumClamped - 1 do
    begin
      FDeltaForce[LI] := -FDeltaForce[LI];
    end;
  end;
end;

end.
