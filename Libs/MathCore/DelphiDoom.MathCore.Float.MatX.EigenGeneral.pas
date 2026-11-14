{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdMatXEigenGeneral                 }
{                                                                              }
{  Port of Eigen_Solve, HessenbergReduction, ComplexDivision and               }
{  HessenbergToRealSchur of idMatX (idlib\math\Matrix.cpp) of the Doom 3 GPL   }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.MatX.EigenGeneral;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.MatX, DelphiDoom.MathCore.Float.VecX;

type
  /// <summary>
  ///   The eigenvalues and eigenvectors of a square matrix that is not symmetric: reduction to
  ///   Hessenberg form and then to the real Schur form (from the JAMA package, as in the C++).
  ///   The symmetric case is <c>TIdMatXEigen</c>. The eigenvalues come as a real and an imaginary
  ///   vector; after <c>Solve</c> column i of the matrix is the eigenvector of value i (a
  ///   complex pair takes two columns: real and imaginary part).
  /// </summary>
  TIdMatXEigenGeneral = class sealed
  public
    /// <summary>
    ///   idMatX::Eigen_Solve. False when the matrix is all zeros or when the QR iteration does
    ///   not converge (the C++ would loop for ever on such input, for example with a NaN: here
    ///   the iteration stops after 100 steps per row).
    /// </summary>
    class function Solve(const AMatrix: TIdMatX; const ARealEigenValues,
      AImaginaryEigenValues: TIdVecX): Boolean; static;
    /// <summary>Reduces H to Hessenberg form and puts the accumulated transformations in the matrix</summary>
    class procedure HessenbergReduction(const AMatrix, AH: TIdMatX); static;
    /// <summary>The complex quotient (xr + i xi) / (yr + i yi)</summary>
    class procedure ComplexDivision(const AXr, AXi, AYr, AYi: Single; out ACdivr, ACdivi: Single);
      static;
    class function HessenbergToRealSchur(const AMatrix, AH: TIdMatX; const ARealEigenValues,
      AImaginaryEigenValues: TIdVecX): Boolean; static;
  end;

implementation

uses
  System.Math, DelphiDoom.IdLib.Math.Math;

{ TIdMatXEigenGeneral }

class procedure TIdMatXEigenGeneral.ComplexDivision(const AXr, AXi, AYr, AYi: Single;
  out ACdivr, ACdivi: Single);
var
  LR, LD, LT: Single;
begin
  if Abs(AYr) > Abs(AYi) then
  begin
    LR := AYi / AYr;
    LT := LR * AYi;
    LD := AYr + LT;
    LT := LR * AXi;
    LT := AXr + LT;
    ACdivr := LT / LD;
    LT := LR * AXr;
    LT := AXi - LT;
    ACdivi := LT / LD;
  end
  else
  begin
    LR := AYr / AYi;
    LT := LR * AYr;
    LD := AYi + LT;
    LT := LR * AXr;
    LT := LT + AXi;
    ACdivr := LT / LD;
    LT := LR * AXi;
    LT := LT - AXr;
    ACdivi := LT / LD;
  end;
end;

class procedure TIdMatXEigenGeneral.HessenbergReduction(const AMatrix, AH: TIdMatX);
var
  LI, LJ, LM, LLow, LHigh, LRows: Integer;
  LScale, LF, LG, LH: Single;
  LV: TIdVecX;
begin
  LRows := AMatrix.NumRows;
  LLow := 0;
  LHigh := LRows - 1;
  LV := TIdVecX.Create(LRows);
  try
    for LM := LLow + 1 to LHigh - 1 do
    begin
      LScale := 0.0;
      for LI := LM to LHigh do
      begin
        LScale := LScale + Abs(AH[LI, LM - 1]);
      end;
      if LScale <> 0.0 then
      begin
        // compute Householder transformation
        LH := 0.0;
        for LI := LHigh downto LM do
        begin
          LV[LI] := AH[LI, LM - 1] / LScale;
          LH := LH + LV[LI] * LV[LI];
        end;
        LG := TIdMath.Sqrt(LH);
        if LV[LM] > 0.0 then
          LG := -LG;
        LH := LH - LV[LM] * LG;
        LV[LM] := LV[LM] - LG;
        // apply Householder similarity transformation
        // H = (I-u*u'/h)*H*(I-u*u')/h)
        for LJ := LM to LRows - 1 do
        begin
          LF := 0.0;
          for LI := LHigh downto LM do
          begin
            LF := LF + LV[LI] * AH[LI, LJ];
          end;
          LF := LF / LH;
          for LI := LM to LHigh do
          begin
            AH[LI, LJ] := AH[LI, LJ] - LF * LV[LI];
          end;
        end;
        for LI := 0 to LHigh do
        begin
          LF := 0.0;
          for LJ := LHigh downto LM do
          begin
            LF := LF + LV[LJ] * AH[LI, LJ];
          end;
          LF := LF / LH;
          for LJ := LM to LHigh do
          begin
            AH[LI, LJ] := AH[LI, LJ] - LF * LV[LJ];
          end;
        end;
        LV[LM] := LScale * LV[LM];
        AH[LM, LM - 1] := LScale * LG;
      end;
    end;
    // accumulate transformations
    AMatrix.Identity;
    for LM := LHigh - 1 downto LLow + 1 do
    begin
      if AH[LM, LM - 1] <> 0.0 then
      begin
        for LI := LM + 1 to LHigh do
        begin
          LV[LI] := AH[LI, LM - 1];
        end;
        for LJ := LM to LHigh do
        begin
          LG := 0.0;
          for LI := LM to LHigh do
          begin
            LG := LG + LV[LI] * AMatrix[LI, LJ];
          end;
          // float division to avoid possible underflow
          LG := (LG / LV[LM]) / AH[LM, LM - 1];
          for LI := LM to LHigh do
          begin
            AMatrix[LI, LJ] := AMatrix[LI, LJ] + LG * LV[LI];
          end;
        end;
      end;
    end;
  finally
    LV.Free;
  end;
end;

class function TIdMatXEigenGeneral.HessenbergToRealSchur(const AMatrix, AH: TIdMatX;
  const ARealEigenValues, AImaginaryEigenValues: TIdVecX): Boolean;
const
  CEps: Single = 2E-16;
var
  LI, LJ, LK, LN, LLow, LHigh, LRows, LIter, LL, LM, LSteps, LMaxSteps: Integer;
  LExShift, LP, LQ, LR, LS, LZ, LT, LW, LX, LY, LNorm, LRa, LSa, LVr, LVi: Single;
  LNotLast: Boolean;
  LCr, LCi: Single;
begin
  LRows := AMatrix.NumRows;
  LN := LRows - 1;
  LLow := 0;
  LHigh := LRows - 1;
  LExShift := 0.0;
  LP := 0.0;
  LQ := 0.0;
  LR := 0.0;
  LS := 0.0;
  LZ := 0.0;
  LX := 0.0;
  LY := 0.0;
  LW := 0.0;
  // store roots isolated by balanc and compute matrix norm
  LNorm := 0.0;
  for LI := 0 to LRows - 1 do
  begin
    if (LI < LLow) or (LI > LHigh) then
    begin
      ARealEigenValues[LI] := AH[LI, LI];
      AImaginaryEigenValues[LI] := 0.0;
    end;
    for LJ := Max(LI - 1, 0) to LRows - 1 do
    begin
      LNorm := LNorm + Abs(AH[LI, LJ]);
    end;
  end;
  LIter := 0;
  LSteps := 0;
  LMaxSteps := 100 * (LRows + 1);
  while LN >= LLow do
  begin
    Inc(LSteps);
    if LSteps > LMaxSteps then
      Exit(False);
    // look for single small sub-diagonal element
    LL := LN;
    while LL > LLow do
    begin
      LS := Abs(AH[LL - 1, LL - 1]) + Abs(AH[LL, LL]);
      if LS = 0.0 then
        LS := LNorm;
      if Abs(AH[LL, LL - 1]) < CEps * LS then
        Break;
      Dec(LL);
    end;
    // check for convergence
    if LL = LN then
    begin
      // one root found
      AH[LN, LN] := AH[LN, LN] + LExShift;
      ARealEigenValues[LN] := AH[LN, LN];
      AImaginaryEigenValues[LN] := 0.0;
      Dec(LN);
      LIter := 0;
    end
    else if LL = LN - 1 then
    begin
      // two roots found
      LW := AH[LN, LN - 1] * AH[LN - 1, LN];
      LP := (AH[LN - 1, LN - 1] - AH[LN, LN]) / 2.0;
      LQ := LP * LP + LW;
      LZ := TIdMath.Sqrt(Abs(LQ));
      AH[LN, LN] := AH[LN, LN] + LExShift;
      AH[LN - 1, LN - 1] := AH[LN - 1, LN - 1] + LExShift;
      LX := AH[LN, LN];
      if LQ >= 0.0 then
      begin
        // real pair
        if LP >= 0.0 then
          LZ := LP + LZ
        else
          LZ := LP - LZ;
        ARealEigenValues[LN - 1] := LX + LZ;
        ARealEigenValues[LN] := ARealEigenValues[LN - 1];
        if LZ <> 0.0 then
          ARealEigenValues[LN] := LX - LW / LZ;
        AImaginaryEigenValues[LN - 1] := 0.0;
        AImaginaryEigenValues[LN] := 0.0;
        LX := AH[LN, LN - 1];
        LS := Abs(LX) + Abs(LZ);
        LP := LX / LS;
        LQ := LZ / LS;
        LR := TIdMath.Sqrt(LP * LP + LQ * LQ);
        LP := LP / LR;
        LQ := LQ / LR;
        // modify row
        for LJ := LN - 1 to LRows - 1 do
        begin
          LZ := AH[LN - 1, LJ];
          AH[LN - 1, LJ] := LQ * LZ + LP * AH[LN, LJ];
          AH[LN, LJ] := LQ * AH[LN, LJ] - LP * LZ;
        end;
        // modify column
        for LI := 0 to LN do
        begin
          LZ := AH[LI, LN - 1];
          AH[LI, LN - 1] := LQ * LZ + LP * AH[LI, LN];
          AH[LI, LN] := LQ * AH[LI, LN] - LP * LZ;
        end;
        // accumulate transformations
        for LI := LLow to LHigh do
        begin
          LZ := AMatrix[LI, LN - 1];
          AMatrix[LI, LN - 1] := LQ * LZ + LP * AMatrix[LI, LN];
          AMatrix[LI, LN] := LQ * AMatrix[LI, LN] - LP * LZ;
        end;
      end
      else
      begin
        // complex pair
        ARealEigenValues[LN - 1] := LX + LP;
        ARealEigenValues[LN] := LX + LP;
        AImaginaryEigenValues[LN - 1] := LZ;
        AImaginaryEigenValues[LN] := -LZ;
      end;
      LN := LN - 2;
      LIter := 0;
    end
    else
    begin
      // no convergence yet: form shift
      LX := AH[LN, LN];
      LY := 0.0;
      LW := 0.0;
      if LL < LN then
      begin
        LY := AH[LN - 1, LN - 1];
        LW := AH[LN, LN - 1] * AH[LN - 1, LN];
      end;
      // Wilkinson's original ad hoc shift
      if LIter = 10 then
      begin
        LExShift := LExShift + LX;
        for LI := LLow to LN do
        begin
          AH[LI, LI] := AH[LI, LI] - LX;
        end;
        LS := Abs(AH[LN, LN - 1]) + Abs(AH[LN - 1, LN - 2]);
        LX := 0.75 * LS;
        LY := LX;
        LW := -0.4375 * LS * LS;
      end;
      // new ad hoc shift
      if LIter = 30 then
      begin
        LS := (LY - LX) / 2.0;
        LS := LS * LS + LW;
        if LS > 0 then
        begin
          LS := TIdMath.Sqrt(LS);
          if LY < LX then
            LS := -LS;
          LS := LX - LW / ((LY - LX) / 2.0 + LS);
          for LI := LLow to LN do
          begin
            AH[LI, LI] := AH[LI, LI] - LS;
          end;
          LExShift := LExShift + LS;
          LX := 0.964;
          LY := LX;
          LW := LX;
        end;
      end;
      Inc(LIter);
      // look for two consecutive small sub-diagonal elements
      LM := LN - 2;
      while LM >= LL do
      begin
        LZ := AH[LM, LM];
        LR := LX - LZ;
        LS := LY - LZ;
        LP := (LR * LS - LW) / AH[LM + 1, LM] + AH[LM, LM + 1];
        LQ := AH[LM + 1, LM + 1] - LZ - LR - LS;
        LR := AH[LM + 2, LM + 1];
        LS := Abs(LP) + Abs(LQ) + Abs(LR);
        LP := LP / LS;
        LQ := LQ / LS;
        LR := LR / LS;
        if LM = LL then
          Break;
        if Abs(AH[LM, LM - 1]) * (Abs(LQ) + Abs(LR)) <
          CEps * (Abs(LP) * (Abs(AH[LM - 1, LM - 1]) + Abs(LZ) + Abs(AH[LM + 1, LM + 1]))) then
          Break;
        Dec(LM);
      end;
      for LI := LM + 2 to LN do
      begin
        AH[LI, LI - 2] := 0.0;
        if LI > LM + 2 then
          AH[LI, LI - 3] := 0.0;
      end;
      // double QR step involving rows l:n and columns m:n
      for LK := LM to LN - 1 do
      begin
        LNotLast := LK <> LN - 1;
        if LK <> LM then
        begin
          LP := AH[LK, LK - 1];
          LQ := AH[LK + 1, LK - 1];
          if LNotLast then
            LR := AH[LK + 2, LK - 1]
          else
            LR := 0.0;
          LX := Abs(LP) + Abs(LQ) + Abs(LR);
          if LX <> 0.0 then
          begin
            LP := LP / LX;
            LQ := LQ / LX;
            LR := LR / LX;
          end;
        end;
        if LX = 0.0 then
          Break;
        LS := TIdMath.Sqrt(LP * LP + LQ * LQ + LR * LR);
        if LP < 0.0 then
          LS := -LS;
        if LS <> 0.0 then
        begin
          if LK <> LM then
            AH[LK, LK - 1] := -LS * LX
          else if LL <> LM then
            AH[LK, LK - 1] := -AH[LK, LK - 1];
          LP := LP + LS;
          LX := LP / LS;
          LY := LQ / LS;
          LZ := LR / LS;
          LQ := LQ / LP;
          LR := LR / LP;
          // modify row
          for LJ := LK to LRows - 1 do
          begin
            LP := AH[LK, LJ] + LQ * AH[LK + 1, LJ];
            if LNotLast then
            begin
              LP := LP + LR * AH[LK + 2, LJ];
              AH[LK + 2, LJ] := AH[LK + 2, LJ] - LP * LZ;
            end;
            AH[LK, LJ] := AH[LK, LJ] - LP * LX;
            AH[LK + 1, LJ] := AH[LK + 1, LJ] - LP * LY;
          end;
          // modify column
          for LI := 0 to Min(LN, LK + 3) do
          begin
            LP := LX * AH[LI, LK] + LY * AH[LI, LK + 1];
            if LNotLast then
            begin
              LP := LP + LZ * AH[LI, LK + 2];
              AH[LI, LK + 2] := AH[LI, LK + 2] - LP * LR;
            end;
            AH[LI, LK] := AH[LI, LK] - LP;
            AH[LI, LK + 1] := AH[LI, LK + 1] - LP * LQ;
          end;
          // accumulate transformations
          for LI := LLow to LHigh do
          begin
            LP := LX * AMatrix[LI, LK] + LY * AMatrix[LI, LK + 1];
            if LNotLast then
            begin
              LP := LP + LZ * AMatrix[LI, LK + 2];
              AMatrix[LI, LK + 2] := AMatrix[LI, LK + 2] - LP * LR;
            end;
            AMatrix[LI, LK] := AMatrix[LI, LK] - LP;
            AMatrix[LI, LK + 1] := AMatrix[LI, LK + 1] - LP * LQ;
          end;
        end;
      end;
    end;
  end;
  // backsubstitute to find vectors of upper triangular form
  if LNorm = 0.0 then
    Exit(False);
  for LN := LRows - 1 downto 0 do
  begin
    LP := ARealEigenValues[LN];
    LQ := AImaginaryEigenValues[LN];
    if LQ = 0.0 then
    begin
      // real vector
      LL := LN;
      AH[LN, LN] := 1.0;
      for LI := LN - 1 downto 0 do
      begin
        LW := AH[LI, LI] - LP;
        LR := 0.0;
        for LJ := LL to LN do
        begin
          LR := LR + AH[LI, LJ] * AH[LJ, LN];
        end;
        if AImaginaryEigenValues[LI] < 0.0 then
        begin
          LZ := LW;
          LS := LR;
        end
        else
        begin
          LL := LI;
          if AImaginaryEigenValues[LI] = 0.0 then
          begin
            if LW <> 0.0 then
              AH[LI, LN] := -LR / LW
            else
              AH[LI, LN] := -LR / (CEps * LNorm);
          end
          else
          begin
            // solve real equations
            LX := AH[LI, LI + 1];
            LY := AH[LI + 1, LI];
            LQ := (ARealEigenValues[LI] - LP) * (ARealEigenValues[LI] - LP) +
              AImaginaryEigenValues[LI] * AImaginaryEigenValues[LI];
            LT := (LX * LS - LZ * LR) / LQ;
            AH[LI, LN] := LT;
            if Abs(LX) > Abs(LZ) then
              AH[LI + 1, LN] := (-LR - LW * LT) / LX
            else
              AH[LI + 1, LN] := (-LS - LY * LT) / LZ;
          end;
          // overflow control
          LT := Abs(AH[LI, LN]);
          if (CEps * LT) * LT > 1 then
          begin
            for LJ := LI to LN do
            begin
              AH[LJ, LN] := AH[LJ, LN] / LT;
            end;
          end;
        end;
      end;
    end
    else if LQ < 0.0 then
    begin
      // complex vector
      LL := LN - 1;
      // last vector component imaginary so matrix is triangular
      if Abs(AH[LN, LN - 1]) > Abs(AH[LN - 1, LN]) then
      begin
        AH[LN - 1, LN - 1] := LQ / AH[LN, LN - 1];
        AH[LN - 1, LN] := -(AH[LN, LN] - LP) / AH[LN, LN - 1];
      end
      else
      begin
        ComplexDivision(0.0, -AH[LN - 1, LN], AH[LN - 1, LN - 1] - LP, LQ, LCr, LCi);
        AH[LN - 1, LN - 1] := LCr;
        AH[LN - 1, LN] := LCi;
      end;
      AH[LN, LN - 1] := 0.0;
      AH[LN, LN] := 1.0;
      for LI := LN - 2 downto 0 do
      begin
        LRa := 0.0;
        LSa := 0.0;
        for LJ := LL to LN do
        begin
          LRa := LRa + AH[LI, LJ] * AH[LJ, LN - 1];
          LSa := LSa + AH[LI, LJ] * AH[LJ, LN];
        end;
        LW := AH[LI, LI] - LP;
        if AImaginaryEigenValues[LI] < 0.0 then
        begin
          LZ := LW;
          LR := LRa;
          LS := LSa;
        end
        else
        begin
          LL := LI;
          if AImaginaryEigenValues[LI] = 0.0 then
          begin
            ComplexDivision(-LRa, -LSa, LW, LQ, LCr, LCi);
            AH[LI, LN - 1] := LCr;
            AH[LI, LN] := LCi;
          end
          else
          begin
            // solve complex equations
            LX := AH[LI, LI + 1];
            LY := AH[LI + 1, LI];
            LVr := (ARealEigenValues[LI] - LP) * (ARealEigenValues[LI] - LP) +
              AImaginaryEigenValues[LI] * AImaginaryEigenValues[LI] - LQ * LQ;
            LVi := (ARealEigenValues[LI] - LP) * 2.0 * LQ;
            if (LVr = 0.0) and (LVi = 0.0) then
              LVr := CEps * LNorm * (Abs(LW) + Abs(LQ) + Abs(LX) + Abs(LY) + Abs(LZ));
            ComplexDivision(LX * LR - LZ * LRa + LQ * LSa, LX * LS - LZ * LSa - LQ * LRa, LVr,
              LVi, LCr, LCi);
            AH[LI, LN - 1] := LCr;
            AH[LI, LN] := LCi;
            if Abs(LX) > (Abs(LZ) + Abs(LQ)) then
            begin
              AH[LI + 1, LN - 1] := (-LRa - LW * AH[LI, LN - 1] + LQ * AH[LI, LN]) / LX;
              AH[LI + 1, LN] := (-LSa - LW * AH[LI, LN] - LQ * AH[LI, LN - 1]) / LX;
            end
            else
            begin
              ComplexDivision(-LR - LY * AH[LI, LN - 1], -LS - LY * AH[LI, LN], LZ, LQ, LCr,
                LCi);
              AH[LI + 1, LN - 1] := LCr;
              AH[LI + 1, LN] := LCi;
            end;
          end;
          // overflow control
          LT := Max(Abs(AH[LI, LN - 1]), Abs(AH[LI, LN]));
          if (CEps * LT) * LT > 1 then
          begin
            for LJ := LI to LN do
            begin
              AH[LJ, LN - 1] := AH[LJ, LN - 1] / LT;
              AH[LJ, LN] := AH[LJ, LN] / LT;
            end;
          end;
        end;
      end;
    end;
  end;
  // vectors of isolated roots
  for LI := 0 to LRows - 1 do
  begin
    if (LI < LLow) or (LI > LHigh) then
    begin
      for LJ := LI to LRows - 1 do
      begin
        AMatrix[LI, LJ] := AH[LI, LJ];
      end;
    end;
  end;
  // back transformation to get eigenvectors of original matrix
  for LJ := LRows - 1 downto LLow do
  begin
    for LI := LLow to LHigh do
    begin
      LZ := 0.0;
      for LK := LLow to Min(LJ, LHigh) do
      begin
        LZ := LZ + AMatrix[LI, LK] * AH[LK, LJ];
      end;
      AMatrix[LI, LJ] := LZ;
    end;
  end;
  Result := True;
end;

class function TIdMatXEigenGeneral.Solve(const AMatrix: TIdMatX; const ARealEigenValues,
  AImaginaryEigenValues: TIdVecX): Boolean;
var
  LH: TIdMatX;
begin
  Assert(AMatrix.NumRows = AMatrix.NumColumns);
  ARealEigenValues.SetSize(AMatrix.NumRows);
  AImaginaryEigenValues.SetSize(AMatrix.NumRows);
  LH := TIdMatX.Create;
  try
    LH.Assign(AMatrix);
    // reduce to Hessenberg form
    HessenbergReduction(AMatrix, LH);
    // reduce Hessenberg to real Schur form
    Result := HessenbergToRealSchur(AMatrix, LH, ARealEigenValues, AImaginaryEigenValues);
  finally
    LH.Free;
  end;
end;

end.
