{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdMatXKernels, the vector kernels  }
{  of the LCP solver                                                           }
{                                                                              }
{  Port of the generic functions idSIMD_Generic::Dot, Mul, MulAdd,             }
{  MatX_LowerTriangularSolve, MatX_LowerTriangularSolveTranspose and          }
{  MatX_LDLTFactor (idlib\math\Simd_Generic.cpp) of the Doom 3 GPL Source      }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.MatX.Kernels;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.MatX, DelphiDoom.MathCore.Float.Types, DelphiDoom.MathCore.Float.VecX;

type
  /// <summary>
  ///   The few SIMD processor functions that <c>idLCP</c> calls, in their generic (plain C++)
  ///   version. The triangular solves and the LDL' factorization are the loop forms of the
  ///   original: the original selects, for small sizes, unrolled code that sums in float
  ///   instead of in double, so the last bit can differ.
  /// </summary>
  TIdMatXKernels = class sealed
  public
    /// <summary>dot = sum of src1[i] * src2[i], summed in four double accumulators as the original does</summary>
    class function Dot(const ASource1, ASource2: PIdSingleArray; const ACount: Integer): Single; static;
    /// <summary>dst[i] = src0[i] * src1[i]</summary>
    class procedure Multiply(const ADestination, ASource0, ASource1: PIdSingleArray;
      const ACount: Integer); static;
    /// <summary>dst[i] += constant * src[i] (the constant as a double)</summary>
    class procedure MultiplyAdd(const ADestination: PIdSingleArray; const AConstant: Single;
      const ASource: PIdSingleArray; const ACount: Integer); static;
    /// <summary>
    ///   Solves x in Lx = b for the n * n sub-matrix of L (implicit ones on the diagonal); if skip
    ///   &gt; 0 the first skip elements of x are valid already; x and b may be the same
    /// </summary>
    class procedure LowerTriangularSolve(const AL: TIdMatX; const AX, AB: PIdSingleArray;
      const AN: Integer; const ASkip: Integer = 0); static;
    /// <summary>Solves x in L'x = b for the n * n sub-matrix of L; x and b may be the same</summary>
    class procedure LowerTriangularSolveTranspose(const AL: TIdMatX; const AX, AB: PIdSingleArray;
      const AN: Integer); static;
    /// <summary>In-place LDL' of the n * n sub-matrix; the reciprocals of the diagonal go to invDiag</summary>
    class function LdltFactor(const AMatrix: TIdMatX; const AInvDiagonal: TIdVecX;
      const AN: Integer): Boolean; static;
  end;

implementation

{ TIdMatXKernels }

class function TIdMatXKernels.Dot(const ASource1, ASource2: PIdSingleArray;
  const ACount: Integer): Single;
var
  LIndex: Integer;
  LS0, LS1, LS2, LS3, LSum: Double;
begin
  case ACount of
    0:
      Result := 0.0;
    1:
      Result := ASource1^[0] * ASource2^[0];
    2:
      Result := ASource1^[0] * ASource2^[0] + ASource1^[1] * ASource2^[1];
    3:
      Result := ASource1^[0] * ASource2^[0] + ASource1^[1] * ASource2^[1] +
        ASource1^[2] * ASource2^[2];
  else
    LS0 := ASource1^[0] * ASource2^[0];
    LS1 := ASource1^[1] * ASource2^[1];
    LS2 := ASource1^[2] * ASource2^[2];
    LS3 := ASource1^[3] * ASource2^[3];
    LIndex := 4;
    while LIndex < ACount - 7 do
    begin
      LS0 := LS0 + ASource1^[LIndex] * ASource2^[LIndex];
      LS1 := LS1 + ASource1^[LIndex + 1] * ASource2^[LIndex + 1];
      LS2 := LS2 + ASource1^[LIndex + 2] * ASource2^[LIndex + 2];
      LS3 := LS3 + ASource1^[LIndex + 3] * ASource2^[LIndex + 3];
      LS0 := LS0 + ASource1^[LIndex + 4] * ASource2^[LIndex + 4];
      LS1 := LS1 + ASource1^[LIndex + 5] * ASource2^[LIndex + 5];
      LS2 := LS2 + ASource1^[LIndex + 6] * ASource2^[LIndex + 6];
      LS3 := LS3 + ASource1^[LIndex + 7] * ASource2^[LIndex + 7];
      Inc(LIndex, 8);
    end;
    // the switch of the original falls through from the number of elements that are left
    if ACount - LIndex >= 7 then
      LS0 := LS0 + ASource1^[LIndex + 6] * ASource2^[LIndex + 6];
    if ACount - LIndex >= 6 then
      LS1 := LS1 + ASource1^[LIndex + 5] * ASource2^[LIndex + 5];
    if ACount - LIndex >= 5 then
      LS2 := LS2 + ASource1^[LIndex + 4] * ASource2^[LIndex + 4];
    if ACount - LIndex >= 4 then
      LS3 := LS3 + ASource1^[LIndex + 3] * ASource2^[LIndex + 3];
    if ACount - LIndex >= 3 then
      LS0 := LS0 + ASource1^[LIndex + 2] * ASource2^[LIndex + 2];
    if ACount - LIndex >= 2 then
      LS1 := LS1 + ASource1^[LIndex + 1] * ASource2^[LIndex + 1];
    if ACount - LIndex >= 1 then
      LS2 := LS2 + ASource1^[LIndex] * ASource2^[LIndex];
    LSum := LS3;
    LSum := LSum + LS2;
    LSum := LSum + LS1;
    LSum := LSum + LS0;
    Result := LSum;
  end;
end;

class procedure TIdMatXKernels.Multiply(const ADestination, ASource0, ASource1: PIdSingleArray;
  const ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    ADestination^[LIndex] := ASource0^[LIndex] * ASource1^[LIndex];
  end;
end;

class procedure TIdMatXKernels.MultiplyAdd(const ADestination: PIdSingleArray;
  const AConstant: Single; const ASource: PIdSingleArray; const ACount: Integer);
var
  LIndex: Integer;
  LConstant: Double;
begin
  LConstant := AConstant;
  for LIndex := 0 to ACount - 1 do
  begin
    ADestination^[LIndex] := ADestination^[LIndex] + LConstant * ASource^[LIndex];
  end;
end;

class procedure TIdMatXKernels.LowerTriangularSolve(const AL: TIdMatX; const AX, AB: PIdSingleArray;
  const AN: Integer; const ASkip: Integer);
var
  LRow, LColumn, LColumns: Integer;
  LSum: Double;
  LData: PIdSingleArray;
begin
  if ASkip >= AN then
    Exit;
  LData := AL.Data;
  LColumns := AL.NumColumns;
  for LRow := ASkip to AN - 1 do
  begin
    LSum := AB^[LRow];
    for LColumn := 0 to LRow - 1 do
    begin
      LSum := LSum - LData^[LRow * LColumns + LColumn] * AX^[LColumn];
    end;
    AX^[LRow] := LSum;
  end;
end;

class procedure TIdMatXKernels.LowerTriangularSolveTranspose(const AL: TIdMatX; const AX,
  AB: PIdSingleArray; const AN: Integer);
var
  LRow, LColumn, LColumns: Integer;
  LSum: Double;
  LData: PIdSingleArray;
begin
  LData := AL.Data;
  LColumns := AL.NumColumns;
  for LRow := AN - 1 downto 0 do
  begin
    LSum := AB^[LRow];
    for LColumn := LRow + 1 to AN - 1 do
    begin
      LSum := LSum - LData^[LColumn * LColumns + LRow] * AX^[LColumn];
    end;
    AX^[LRow] := LSum;
  end;
end;

class function TIdMatXKernels.LdltFactor(const AMatrix: TIdMatX; const AInvDiagonal: TIdVecX;
  const AN: Integer): Boolean;
var
  LRow, LColumn, LK, LColumns: Integer;
  LV: TArray<Single>;
  LData: PIdSingleArray;
  LD, LSum: Double;
begin
  LColumns := AMatrix.NumColumns;
  LData := AMatrix.Data;
  SetLength(LV, AN);
  for LRow := 0 to AN - 1 do
  begin
    LSum := LData^[LRow * LColumns + LRow];
    for LColumn := 0 to LRow - 1 do
    begin
      LD := LData^[LRow * LColumns + LColumn];
      LV[LColumn] := LData^[LColumn * LColumns + LColumn] * LD;
      LSum := LSum - LV[LColumn] * LD;
    end;
    if LSum = 0.0 then
      Exit(False);
    LData^[LRow * LColumns + LRow] := LSum;
    LD := 1.0 / LSum;
    AInvDiagonal[LRow] := LD;
    if LRow + 1 >= AN then
      Continue;
    for LColumn := LRow + 1 to AN - 1 do
    begin
      LSum := LData^[LColumn * LColumns + LRow];
      for LK := 0 to LRow - 1 do
      begin
        LSum := LSum - LData^[LColumn * LColumns + LK] * LV[LK];
      end;
      LData^[LColumn * LColumns + LRow] := LSum * LD;
    end;
  end;
  Result := True;
end;

end.
