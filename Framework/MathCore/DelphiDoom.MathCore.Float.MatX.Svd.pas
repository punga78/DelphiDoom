{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdMatXSvd, singular values         }
{                                                                              }
{  Port of the SVD_* members of idMatX (idlib\math\Matrix.cpp) of the Doom 3   }
{  GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media   }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Framework\IdLib); the repository as a whole is GPL v2 or later.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.MatX.Svd;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.MatX, DelphiDoom.MathCore.Float.VecX;

type
  /// <summary>
  ///   The singular value decomposition U * Diag(w) * V' of a matrix with at least as many rows
  ///   as columns (the <c>SVD_*</c> members of idMatX). U overwrites the matrix and is column
  ///   orthogonal, w holds the singular values (all >= 0) and V is the transpose of an
  ///   orthogonal matrix.
  /// </summary>
  TIdMatXSvd = class sealed
  strict private
    class procedure BiDiagonalize(const AMatrix: TIdMatX; const AW, ARv1: TIdVecX;
      out ANorm: Single); static;
    class procedure InitialWV(const AMatrix: TIdMatX; const AW: TIdVecX; const AV: TIdMatX;
      const ARv1: TIdVecX); static;
  public
    /// <summary>
    ///   True when <c>|a| + b = b</c> in the 64 bit mantissa of the x87 (the C++ evaluates the test of the QR
    ///   iteration of <c>SVD_Factor</c> in extended precision): <c>|a|</c> is at most half a unit in the
    ///   last place of <c>b</c>. Exact and the same at 32 and 64 bit.
    /// </summary>
    class function IsNegligible(const AValue, ANorm: Single): Boolean; static;
    /// <summary>(a^2 + b^2)^1/2 without underflow or overflow (idMatX::Pythag)</summary>
    class function Pythag(const AA, AB: Single): Single; static;
    /// <summary>False when the matrix has fewer rows than columns or the iteration does not converge in 30 steps</summary>
    class function Factor(const AMatrix: TIdMatX; const AW: TIdVecX; const AV: TIdMatX): Boolean;
      static;
    /// <summary>Solves Ax = b with A factored as U * Diag(w) * V'</summary>
    class procedure Solve(const AMatrix: TIdMatX; const AX, AB, AW: TIdVecX; const AV: TIdMatX);
      static;
    class procedure Inverse(const AMatrix, AInverse: TIdMatX; const AW: TIdVecX;
      const AV: TIdMatX); static;
    class procedure MultiplyFactors(const AMatrix, AResult: TIdMatX; const AW: TIdVecX;
      const AV: TIdMatX); static;
  end;

implementation

uses
  System.Math, DelphiDoom.IdLib.Math.Math;

{ TIdMatXSvd }

class function TIdMatXSvd.IsNegligible(const AValue, ANorm: Single): Boolean;
var
  LBits: Cardinal;
  LExponent: Integer;
  LValue: Single;
begin
  LValue := Abs(AValue);
  if LValue = 0.0 then
    Exit(True);
  LBits := PCardinal(@ANorm)^ and $7FFFFFFF;
  if (LBits = 0) or (LBits >= $7F800000) then
    Exit(False);
  LExponent := Integer(LBits shr 23);
  if LExponent = 0 then
    Exit(False);
  // half a unit in the last place of a 64 bit mantissa; a tie goes to the even value, which is ANorm
  Result := LValue <= Ldexp(1.0, LExponent - 127 - 64);
end;
class function TIdMatXSvd.Pythag(const AA, AB: Single): Single;
var
  LAt, LBt, LCt: Double;
begin
  LAt := Abs(AA);
  LBt := Abs(AB);
  if LAt > LBt then
  begin
    LCt := LBt / LAt;
    Result := LAt * TIdMath.Sqrt(1.0 + LCt * LCt);
  end
  else if LBt <> 0.0 then
  begin
    LCt := LAt / LBt;
    Result := LBt * TIdMath.Sqrt(1.0 + LCt * LCt);
  end
  else
    Result := 0.0;
end;

class procedure TIdMatXSvd.BiDiagonalize(const AMatrix: TIdMatX; const AW, ARv1: TIdVecX;
  out ANorm: Single);
var
  LRows, LColumns, LI, LJ, LK, LL: Integer;
  LF, LH, LR, LG, LS, LScale: Double;
begin
  LRows := AMatrix.NumRows;
  LColumns := AMatrix.NumColumns;
  ANorm := 0.0;
  LG := 0.0;
  LS := 0.0;
  LScale := 0.0;
  for LI := 0 to LColumns - 1 do
  begin
    LL := LI + 1;
    ARv1[LI] := LScale * LG;
    LG := 0.0;
    LS := 0.0;
    LScale := 0.0;
    if LI < LRows then
    begin
      for LK := LI to LRows - 1 do
      begin
        LScale := LScale + Abs(AMatrix[LK, LI]);
      end;
      if LScale <> 0.0 then
      begin
        for LK := LI to LRows - 1 do
        begin
          AMatrix[LK, LI] := AMatrix[LK, LI] / LScale;
          LS := LS + AMatrix[LK, LI] * AMatrix[LK, LI];
        end;
        LF := AMatrix[LI, LI];
        LG := TIdMath.Sqrt(LS);
        if LF >= 0.0 then
          LG := -LG;
        LH := LF * LG - LS;
        AMatrix[LI, LI] := LF - LG;
        if LI <> (LColumns - 1) then
        begin
          for LJ := LL to LColumns - 1 do
          begin
            LS := 0.0;
            for LK := LI to LRows - 1 do
            begin
              LS := LS + AMatrix[LK, LI] * AMatrix[LK, LJ];
            end;
            LF := LS / LH;
            for LK := LI to LRows - 1 do
            begin
              AMatrix[LK, LJ] := AMatrix[LK, LJ] + LF * AMatrix[LK, LI];
            end;
          end;
        end;
        for LK := LI to LRows - 1 do
        begin
          AMatrix[LK, LI] := AMatrix[LK, LI] * LScale;
        end;
      end;
    end;
    AW[LI] := LScale * LG;
    LG := 0.0;
    LS := 0.0;
    LScale := 0.0;
    if (LI < LRows) and (LI <> (LColumns - 1)) then
    begin
      for LK := LL to LColumns - 1 do
      begin
        LScale := LScale + Abs(AMatrix[LI, LK]);
      end;
      if LScale <> 0.0 then
      begin
        for LK := LL to LColumns - 1 do
        begin
          AMatrix[LI, LK] := AMatrix[LI, LK] / LScale;
          LS := LS + AMatrix[LI, LK] * AMatrix[LI, LK];
        end;
        LF := AMatrix[LI, LL];
        LG := TIdMath.Sqrt(LS);
        if LF >= 0.0 then
          LG := -LG;
        LH := 1.0 / (LF * LG - LS);
        AMatrix[LI, LL] := LF - LG;
        for LK := LL to LColumns - 1 do
        begin
          ARv1[LK] := AMatrix[LI, LK] * LH;
        end;
        if LI <> (LRows - 1) then
        begin
          for LJ := LL to LRows - 1 do
          begin
            LS := 0.0;
            for LK := LL to LColumns - 1 do
            begin
              LS := LS + AMatrix[LJ, LK] * AMatrix[LI, LK];
            end;
            for LK := LL to LColumns - 1 do
            begin
              AMatrix[LJ, LK] := AMatrix[LJ, LK] + LS * ARv1[LK];
            end;
          end;
        end;
        for LK := LL to LColumns - 1 do
        begin
          AMatrix[LI, LK] := AMatrix[LI, LK] * LScale;
        end;
      end;
    end;
    LR := Abs(AW[LI]) + Abs(ARv1[LI]);
    if LR > ANorm then
      ANorm := LR;
  end;
end;

class procedure TIdMatXSvd.InitialWV(const AMatrix: TIdMatX; const AW: TIdVecX;
  const AV: TIdMatX; const ARv1: TIdVecX);
var
  LRows, LColumns, LI, LJ, LK, LL: Integer;
  LF, LG, LS: Double;
begin
  LRows := AMatrix.NumRows;
  LColumns := AMatrix.NumColumns;
  LG := 0.0;
  for LI := LColumns - 1 downto 0 do
  begin
    LL := LI + 1;
    if LI < LColumns - 1 then
    begin
      if LG <> 0.0 then
      begin
        for LJ := LL to LColumns - 1 do
        begin
          // double division to reduce underflow
          AV[LJ, LI] := (AMatrix[LI, LJ] / AMatrix[LI, LL]) / LG;
        end;
        for LJ := LL to LColumns - 1 do
        begin
          LS := 0.0;
          for LK := LL to LColumns - 1 do
          begin
            LS := LS + AMatrix[LI, LK] * AV[LK, LJ];
          end;
          for LK := LL to LColumns - 1 do
          begin
            AV[LK, LJ] := AV[LK, LJ] + LS * AV[LK, LI];
          end;
        end;
      end;
      for LJ := LL to LColumns - 1 do
      begin
        AV[LJ, LI] := 0.0;
        AV[LI, LJ] := 0.0;
      end;
    end;
    AV[LI, LI] := 1.0;
    LG := ARv1[LI];
  end;
  for LI := LColumns - 1 downto 0 do
  begin
    LL := LI + 1;
    LG := AW[LI];
    if LI < LColumns - 1 then
    begin
      for LJ := LL to LColumns - 1 do
      begin
        AMatrix[LI, LJ] := 0.0;
      end;
    end;
    if LG <> 0.0 then
    begin
      LG := 1.0 / LG;
      if LI <> LColumns - 1 then
      begin
        for LJ := LL to LColumns - 1 do
        begin
          LS := 0.0;
          for LK := LL to LRows - 1 do
          begin
            LS := LS + AMatrix[LK, LI] * AMatrix[LK, LJ];
          end;
          LF := (LS / AMatrix[LI, LI]) * LG;
          for LK := LI to LRows - 1 do
          begin
            AMatrix[LK, LJ] := AMatrix[LK, LJ] + LF * AMatrix[LK, LI];
          end;
        end;
      end;
      for LJ := LI to LRows - 1 do
      begin
        AMatrix[LJ, LI] := AMatrix[LJ, LI] * LG;
      end;
    end
    else
    begin
      for LJ := LI to LRows - 1 do
      begin
        AMatrix[LJ, LI] := 0.0;
      end;
    end;
    AMatrix[LI, LI] := AMatrix[LI, LI] + 1.0;
  end;
end;

class function TIdMatXSvd.Factor(const AMatrix: TIdMatX; const AW: TIdVecX;
  const AV: TIdMatX): Boolean;
var
  LRows, LColumns, LFlag, LI, LIts, LJ, LJJ, LK, LL, LNm: Integer;
  LC, LF, LH, LS, LX, LY, LZ, LR, LG: Double;
  LNorm: Single;
  LRv1: TIdVecX;
begin
  LRows := AMatrix.NumRows;
  LColumns := AMatrix.NumColumns;
  if LRows < LColumns then
    Exit(False);
  LG := 0.0;
  LNorm := 0.0;
  LRv1 := TIdVecX.Create(LColumns);
  try
    LRv1.Zero;
    AW.Zero(LColumns);
    AV.Zero(LColumns, LColumns);
    BiDiagonalize(AMatrix, AW, LRv1, LNorm);
    InitialWV(AMatrix, AW, AV, LRv1);
    for LK := LColumns - 1 downto 0 do
    begin
      LIts := 1;
      while LIts <= 30 do
      begin
        LFlag := 1;
        LNm := 0;
        LL := LK;
        while LL >= 0 do
        begin
          LNm := LL - 1;
          if IsNegligible(LRv1[LL], LNorm) then
          begin
            LFlag := 0;
            Break;
          end;
          if IsNegligible(AW[LNm], LNorm) then
            Break;
          Dec(LL);
        end;
        if LFlag <> 0 then
        begin
          LC := 0.0;
          LS := 1.0;
          for LI := LL to LK do
          begin
            LF := LS * LRv1[LI];
            if not IsNegligible(LF, LNorm) then
            begin
              LG := AW[LI];
              LH := Pythag(LF, LG);
              AW[LI] := LH;
              LH := 1.0 / LH;
              LC := LG * LH;
              LS := -LF * LH;
              for LJ := 0 to LRows - 1 do
              begin
                LY := AMatrix[LJ, LNm];
                LZ := AMatrix[LJ, LI];
                AMatrix[LJ, LNm] := LY * LC + LZ * LS;
                AMatrix[LJ, LI] := LZ * LC - LY * LS;
              end;
            end;
          end;
        end;
        LZ := AW[LK];
        if LL = LK then
        begin
          if LZ < 0.0 then
          begin
            AW[LK] := -LZ;
            for LJ := 0 to LColumns - 1 do
            begin
              AV[LJ, LK] := -AV[LJ, LK];
            end;
          end;
          Break;
        end;
        if LIts = 30 then
          Exit(False); // no convergence
        LX := AW[LL];
        LNm := LK - 1;
        LY := AW[LNm];
        LG := LRv1[LNm];
        LH := LRv1[LK];
        LF := ((LY - LZ) * (LY + LZ) + (LG - LH) * (LG + LH)) / (2.0 * LH * LY);
        LG := Pythag(LF, 1.0);
        if LF >= 0.0 then
          LR := LG
        else
          LR := -LG;
        LF := ((LX - LZ) * (LX + LZ) + LH * ((LY / (LF + LR)) - LH)) / LX;
        LC := 1.0;
        LS := 1.0;
        for LJ := LL to LNm do
        begin
          LI := LJ + 1;
          LG := LRv1[LI];
          LY := AW[LI];
          LH := LS * LG;
          LG := LC * LG;
          LZ := Pythag(LF, LH);
          LRv1[LJ] := LZ;
          LC := LF / LZ;
          LS := LH / LZ;
          LF := LX * LC + LG * LS;
          LG := LG * LC - LX * LS;
          LH := LY * LS;
          LY := LY * LC;
          for LJJ := 0 to LColumns - 1 do
          begin
            LX := AV[LJJ, LJ];
            LZ := AV[LJJ, LI];
            AV[LJJ, LJ] := LX * LC + LZ * LS;
            AV[LJJ, LI] := LZ * LC - LX * LS;
          end;
          LZ := Pythag(LF, LH);
          AW[LJ] := LZ;
          if LZ <> 0.0 then
          begin
            LZ := 1.0 / LZ;
            LC := LF * LZ;
            LS := LH * LZ;
          end;
          LF := (LC * LG) + (LS * LY);
          LX := (LC * LY) - (LS * LG);
          for LJJ := 0 to LRows - 1 do
          begin
            LY := AMatrix[LJJ, LJ];
            LZ := AMatrix[LJJ, LI];
            AMatrix[LJJ, LJ] := LY * LC + LZ * LS;
            AMatrix[LJJ, LI] := LZ * LC - LY * LS;
          end;
        end;
        LRv1[LL] := 0.0;
        LRv1[LK] := LF;
        AW[LK] := LX;
        Inc(LIts);
      end;
    end;
  finally
    LRv1.Free;
  end;
  Result := True;
end;

class procedure TIdMatXSvd.Solve(const AMatrix: TIdMatX; const AX, AB, AW: TIdVecX;
  const AV: TIdMatX);
var
  LRows, LColumns, LI, LJ: Integer;
  LSum: Double;
  LTemp: TIdVecX;
begin
  LRows := AMatrix.NumRows;
  LColumns := AMatrix.NumColumns;
  Assert(AX.Size >= LColumns);
  Assert(AB.Size >= LColumns);
  Assert(AW.Size = LColumns);
  Assert((AV.NumRows = LColumns) and (AV.NumColumns = LColumns));
  LTemp := TIdVecX.Create(LColumns);
  try
    for LI := 0 to LColumns - 1 do
    begin
      LSum := 0.0;
      if AW[LI] >= ID_FLT_EPSILON then
      begin
        for LJ := 0 to LRows - 1 do
        begin
          LSum := LSum + AMatrix[LJ, LI] * AB[LJ];
        end;
        LSum := LSum / AW[LI];
      end;
      LTemp[LI] := LSum;
    end;
    for LI := 0 to LColumns - 1 do
    begin
      LSum := 0.0;
      for LJ := 0 to LColumns - 1 do
      begin
        LSum := LSum + AV[LI, LJ] * LTemp[LJ];
      end;
      AX[LI] := LSum;
    end;
  finally
    LTemp.Free;
  end;
end;

class procedure TIdMatXSvd.Inverse(const AMatrix, AInverse: TIdMatX; const AW: TIdVecX;
  const AV: TIdMatX);
var
  LRows, LColumns, LI, LJ, LK: Integer;
  LWi, LSum: Double;
  LV2: TIdMatX;
begin
  LRows := AMatrix.NumRows;
  LColumns := AMatrix.NumColumns;
  Assert(LRows = LColumns);
  LV2 := TIdMatX.Create;
  try
    LV2.Assign(AV);
    // V * [diag(1/w[i])]
    for LI := 0 to LRows - 1 do
    begin
      LWi := AW[LI];
      if LWi < ID_FLT_EPSILON then
        LWi := 0.0
      else
        LWi := 1.0 / LWi;
      for LJ := 0 to LColumns - 1 do
      begin
        LV2[LJ, LI] := LV2[LJ, LI] * LWi;
      end;
    end;
    // V * [diag(1/w[i])] * Ut
    for LI := 0 to LRows - 1 do
    begin
      for LJ := 0 to LColumns - 1 do
      begin
        LSum := LV2[LI, 0] * AMatrix[LJ, 0];
        for LK := 1 to LColumns - 1 do
        begin
          LSum := LSum + LV2[LI, LK] * AMatrix[LJ, LK];
        end;
        AInverse[LI, LJ] := LSum;
      end;
    end;
  finally
    LV2.Free;
  end;
end;

class procedure TIdMatXSvd.MultiplyFactors(const AMatrix, AResult: TIdMatX; const AW: TIdVecX;
  const AV: TIdMatX);
var
  LRows, LColumns, LRow, LI, LJ: Integer;
  LSum: Double;
begin
  LRows := AMatrix.NumRows;
  LColumns := AMatrix.NumColumns;
  AResult.SetSize(LRows, AV.NumRows);
  for LRow := 0 to LRows - 1 do
  begin
    // calculate row of matrix
    if (LRow < AW.Size) and (AW[LRow] >= ID_FLT_EPSILON) then
    begin
      for LI := 0 to AV.NumRows - 1 do
      begin
        LSum := 0.0;
        for LJ := 0 to LColumns - 1 do
        begin
          LSum := LSum + AMatrix[LRow, LJ] * AV[LI, LJ];
        end;
        AResult[LRow, LI] := LSum * AW[LRow];
      end;
    end
    else
    begin
      for LI := 0 to AV.NumRows - 1 do
      begin
        AResult[LRow, LI] := 0.0;
      end;
    end;
  end;
end;

end.
