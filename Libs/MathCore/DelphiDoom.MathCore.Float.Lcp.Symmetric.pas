{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdLcpSymmetric, the LCP solver for }
{  a symmetric matrix                                                          }
{                                                                              }
{  Port of idLCP_Symmetric (idlib\math\Lcp.cpp) of the Doom 3 GPL Source       }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Lcp.Symmetric;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Lcp.Base, DelphiDoom.MathCore.Float.Types,
  DelphiDoom.MathCore.Float.VecX;

type
  /// <summary>
  ///   The solver for a symmetric matrix: the clamped sub matrix is factored as L*D*L'
  ///   (idLCP_Symmetric), which is cheaper to update than the LU of <c>TIdLcpSquare</c>;
  ///   the lower triangular solve is cached between <c>CalcForceDelta</c> and <c>AddClamped</c>.
  /// </summary>
  TIdLcpSymmetric = class(TIdLcpBase)
  strict private
    FSolveCache1: TIdVecX;
    FSolveCache2: TIdVecX;
    /// <summary>The lowest row/column changed in the clamped matrix during an iteration</summary>
    FClampedChangeStart: Integer;
  protected
    procedure CreateExtra(const ARows: Integer); override;
    procedure FreeExtra; override;
    procedure BeginVariable; override;
    function FactorClamped: Boolean; override;
    procedure SolveClamped(const AX: TIdVecX; const AB: PIdSingleArray); override;
    procedure AddClamped(const ARow: Integer; const AUseSolveCache: Boolean); override;
    procedure RemoveClamped(const ARow: Integer); override;
    procedure CalcForceDelta(const ADelta: Integer; const ADirection: Single); override;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Math, DelphiDoom.MathCore.Float.MatX.Kernels;

{ TIdLcpSymmetric }

procedure TIdLcpSymmetric.CreateExtra(const ARows: Integer);
begin
  FSolveCache1 := TIdVecX.Create(ARows);
  FSolveCache2 := TIdVecX.Create(ARows);
end;

procedure TIdLcpSymmetric.FreeExtra;
begin
  FreeAndNil(FSolveCache2);
  FreeAndNil(FSolveCache1);
end;

procedure TIdLcpSymmetric.BeginVariable;
begin
  FClampedChangeStart := 0;
end;

function TIdLcpSymmetric.FactorClamped: Boolean;
var
  LI, LJ, LColumns: Integer;
begin
  FClampedChangeStart := 0;
  LColumns := FClamped.NumColumns;
  for LI := 0 to FNumClamped - 1 do
  begin
    for LJ := 0 to FNumClamped - 1 do
    begin
      FClamped.Data^[LI * LColumns + LJ] := RowPointer(LI)^[LJ];
    end;
  end;
  Result := TIdMatXKernels.LdltFactor(FClamped, FDiagonal, FNumClamped);
end;

procedure TIdLcpSymmetric.SolveClamped(const AX: TIdVecX; const AB: PIdSingleArray);
begin
  // solve L
  TIdMatXKernels.LowerTriangularSolve(FClamped, FSolveCache1.Data, AB, FNumClamped,
    FClampedChangeStart);
  // solve D
  TIdMatXKernels.Multiply(FSolveCache2.Data, FSolveCache1.Data, FDiagonal.Data, FNumClamped);
  // solve Lt
  TIdMatXKernels.LowerTriangularSolveTranspose(FClamped, AX.Data, FSolveCache2.Data, FNumClamped);
  FClampedChangeStart := FNumClamped;
end;

procedure TIdLcpSymmetric.AddClamped(const ARow: Integer; const AUseSolveCache: Boolean);
var
  LD, LDot: Single;
  LV: TArray<Single>;
  LColumns, LIndex: Integer;
  LClampedRow: PIdSingleArray;
begin
  Assert(ARow >= FNumClamped);
  if FNumClamped < FClampedChangeStart then
    FClampedChangeStart := FNumClamped;
  // add a row at the bottom and a column at the right of the factored matrix for the clamped variables
  Swap(FNumClamped, ARow);
  LColumns := FClamped.NumColumns;
  LClampedRow := PIdSingleArray(@FClamped.Data^[FNumClamped * LColumns]);
  // solve for v in L * v = rowPtr[numClamped]
  if AUseSolveCache then
  begin
    // the lower triangular solve was cached in SolveClamped called by CalcForceDelta
    for LIndex := 0 to FNumClamped - 1 do
    begin
      LClampedRow^[LIndex] := FSolveCache2.Data^[LIndex];
    end;
    // calculate row dot product
    LDot := TIdMatXKernels.Dot(FSolveCache2.Data, FSolveCache1.Data, FNumClamped);
  end
  else
  begin
    SetLength(LV, FNumClamped + 1);
    TIdMatXKernels.LowerTriangularSolve(FClamped, PIdSingleArray(LV), RowPointer(FNumClamped),
      FNumClamped);
    // add bottom row to L
    TIdMatXKernels.Multiply(LClampedRow, PIdSingleArray(LV), FDiagonal.Data, FNumClamped);
    // calculate row dot product
    LDot := TIdMatXKernels.Dot(LClampedRow, PIdSingleArray(LV), FNumClamped);
  end;
  // update diagonal[numClamped]
  LD := RowPointer(FNumClamped)^[FNumClamped] - LDot;
  if LD = 0.0 then
  begin
    Print('idLCP_Symmetric::AddClamped: updating factorization failed');
    Inc(FNumClamped);
    Exit;
  end;
  LClampedRow^[FNumClamped] := LD;
  FDiagonal[FNumClamped] := 1.0 / LD;
  Inc(FNumClamped);
end;

procedure TIdLcpSymmetric.RemoveClamped(const ARow: Integer);
var
  LI, LJ, LN, LColumns: Integer;
  LAddSub, LV, LV1, LV2: TArray<Single>;
  LOriginal, LPointer: PIdSingleArray;
  LDot, LSum0, LSum1: Single;
  LSum, LDiag, LNewDiag, LInvNewDiag, LP1, LP2, LAlpha1, LAlpha2, LBeta1, LBeta2: Double;
  LClamped: PIdSingleArray;
begin
  Assert(ARow < FNumClamped);
  if ARow < FClampedChangeStart then
    FClampedChangeStart := ARow;
  Dec(FNumClamped);
  // no need to swap and update the factored matrix when the last row and column are removed
  if ARow = FNumClamped then
    Exit;
  // swap the to be removed row/column with the last row/column
  Swap(ARow, FNumClamped);
  LColumns := FClamped.NumColumns;
  LClamped := FClamped.Data;
  // update the factored matrix
  SetLength(LAddSub, FNumClamped);
  if ARow = 0 then
  begin
    if FNumClamped = 1 then
    begin
      LDiag := RowPointer(0)^[0];
      if LDiag = 0.0 then
      begin
        Print('idLCP_Symmetric::RemoveClamped: updating factorization failed');
        Exit;
      end;
      LClamped^[0] := LDiag;
      FDiagonal[0] := 1.0 / LDiag;
      Exit;
    end;
    // calculate the row/column to be added to the lower right sub matrix starting at (r, r)
    LOriginal := RowPointer(FNumClamped);
    LPointer := RowPointer(ARow);
    LAddSub[0] := LPointer^[0] - LOriginal^[FNumClamped];
    for LI := 1 to FNumClamped - 1 do
    begin
      LAddSub[LI] := LPointer^[LI] - LOriginal^[LI];
    end;
  end
  else
  begin
    SetLength(LV, FNumClamped);
    // solve for v in L * v = rowPtr[r]
    TIdMatXKernels.LowerTriangularSolve(FClamped, PIdSingleArray(LV), RowPointer(ARow), ARow);
    // update removed row
    TIdMatXKernels.Multiply(PIdSingleArray(@LClamped^[ARow * LColumns]), PIdSingleArray(LV),
      FDiagonal.Data, ARow);
    // if the last row/column of the matrix is updated only the new diagonal is calculated
    if ARow = FNumClamped - 1 then
    begin
      LDot := TIdMatXKernels.Dot(PIdSingleArray(@LClamped^[ARow * LColumns]), PIdSingleArray(LV),
        ARow);
      LDiag := RowPointer(ARow)^[ARow] - LDot;
      if LDiag = 0.0 then
      begin
        Print('idLCP_Symmetric::RemoveClamped: updating factorization failed');
        Exit;
      end;
      LClamped^[ARow * LColumns + ARow] := LDiag;
      FDiagonal[ARow] := 1.0 / LDiag;
      Exit;
    end;
    // calculate the row/column to be added to the lower right sub matrix starting at (r, r)
    for LI := 0 to ARow - 1 do
    begin
      LV[LI] := LClamped^[ARow * LColumns + LI] * LClamped^[LI * LColumns + LI];
    end;
    for LI := ARow to FNumClamped - 1 do
    begin
      if LI = ARow then
        LSum := LClamped^[ARow * LColumns + ARow]
      else
        LSum := LClamped^[ARow * LColumns + ARow] * LClamped^[LI * LColumns + ARow];
      for LJ := 0 to ARow - 1 do
      begin
        LSum := LSum + LClamped^[LI * LColumns + LJ] * LV[LJ];
      end;
      LAddSub[LI] := RowPointer(ARow)^[LI] - LSum;
    end;
  end;
  // add row/column to the lower right sub matrix starting at (r, r)
  SetLength(LV1, FNumClamped);
  SetLength(LV2, FNumClamped);
  LDiag := ID_SQRT_1OVER2;
  LV1[ARow] := (0.5 * LAddSub[ARow] + 1.0) * LDiag;
  LV2[ARow] := (0.5 * LAddSub[ARow] - 1.0) * LDiag;
  for LI := ARow + 1 to FNumClamped - 1 do
  begin
    LV1[LI] := LAddSub[LI] * LDiag;
    LV2[LI] := LV1[LI];
  end;
  LAlpha1 := 1.0;
  LAlpha2 := -1.0;
  // simultaneous update/downdate of the sub matrix starting at (r, r)
  LN := LColumns;
  for LI := ARow to FNumClamped - 1 do
  begin
    LDiag := LClamped^[LI * LN + LI];
    LP1 := LV1[LI];
    LNewDiag := LDiag + LAlpha1 * LP1 * LP1;
    if LNewDiag = 0.0 then
    begin
      Print('idLCP_Symmetric::RemoveClamped: updating factorization failed');
      Exit;
    end;
    LAlpha1 := LAlpha1 / LNewDiag;
    LBeta1 := LP1 * LAlpha1;
    LAlpha1 := LAlpha1 * LDiag;
    LDiag := LNewDiag;
    LP2 := LV2[LI];
    LNewDiag := LDiag + LAlpha2 * LP2 * LP2;
    if LNewDiag = 0.0 then
    begin
      Print('idLCP_Symmetric::RemoveClamped: updating factorization failed');
      Exit;
    end;
    LClamped^[LI * LN + LI] := LNewDiag;
    LInvNewDiag := 1.0 / LNewDiag;
    FDiagonal[LI] := LInvNewDiag;
    LAlpha2 := LAlpha2 * LInvNewDiag;
    LBeta2 := LP2 * LAlpha2;
    LAlpha2 := LAlpha2 * LDiag;
    // update column below diagonal (i,i)
    LJ := LI + 1;
    while LJ < FNumClamped - 1 do
    begin
      LSum0 := LClamped^[(LJ + 0) * LN + LI];
      LSum1 := LClamped^[(LJ + 1) * LN + LI];
      LV1[LJ + 0] := LV1[LJ + 0] - LP1 * LSum0;
      LV1[LJ + 1] := LV1[LJ + 1] - LP1 * LSum1;
      LSum0 := LSum0 + LBeta1 * LV1[LJ + 0];
      LSum1 := LSum1 + LBeta1 * LV1[LJ + 1];
      LV2[LJ + 0] := LV2[LJ + 0] - LP2 * LSum0;
      LV2[LJ + 1] := LV2[LJ + 1] - LP2 * LSum1;
      LSum0 := LSum0 + LBeta2 * LV2[LJ + 0];
      LSum1 := LSum1 + LBeta2 * LV2[LJ + 1];
      LClamped^[(LJ + 0) * LN + LI] := LSum0;
      LClamped^[(LJ + 1) * LN + LI] := LSum1;
      Inc(LJ, 2);
    end;
    while LJ < FNumClamped do
    begin
      LSum := LClamped^[LJ * LN + LI];
      LV1[LJ] := LV1[LJ] - LP1 * LSum;
      LSum := LSum + LBeta1 * LV1[LJ];
      LV2[LJ] := LV2[LJ] - LP2 * LSum;
      LSum := LSum + LBeta2 * LV2[LJ];
      LClamped^[LJ * LN + LI] := LSum;
      Inc(LJ);
    end;
  end;
end;

procedure TIdLcpSymmetric.CalcForceDelta(const ADelta: Integer; const ADirection: Single);
var
  LI: Integer;
begin
  FDeltaForce[ADelta] := ADirection;
  if FNumClamped = 0 then
    Exit;
  // solve force delta
  SolveClamped(FDeltaForce, RowPointer(ADelta));
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
