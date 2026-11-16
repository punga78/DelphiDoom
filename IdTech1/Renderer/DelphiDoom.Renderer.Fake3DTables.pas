{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the tables of the "fake 3D" view with the    }
{  result of the 32 bit code                                                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The expressions are those of R_ComputeFake3DTables of r_fake3d.pas          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.Fake3DTables;

interface

uses
  System.SysUtils;

type
  PFake3DInteger = ^Integer;

  /// <summary>
  ///   The floating point part of R_ComputeFake3DTables computed without the FPU (issue #40): every
  ///   intermediate has the 64 bits of mantissa of the x87 and is rounded to 53 bits only where the old code
  ///   stores it in a Double, so the 64 bit renderer gets the tables of the 32 bit one. The 32 bit renderer
  ///   never links this unit. The sine of the correction is TSoftExtended.Sin (equal to fsin but, rarely, for
  ///   the last bit of 64)
  /// </summary>
  TRendererFake3DTables = class
  public
    /// <summary>The aspect of the table: 2 - ACosine stored in a Double</summary>
    class function Aspect(const ACosine: Double): Double; static;
    /// <summary>
    ///   ylookup before the clamp, for the rows 0..AViewHeight - 1: Round(invc2 * (i + r * (buffer2[i] - i)))
    ///   for ALookDirection >= 0, Round(invc2 * (i - r * (buffer2[i] - i))) otherwise
    /// </summary>
    class procedure RowLookup(ALookDirection: Integer; const ACosine: Double; AViewHeight: Integer;
      AResult: PFake3DInteger); static;
    /// <summary>
    ///   The corners of the view (ALeftTop, ARightTop, ALeftBottom, ARightBottom) and the tables left, right and
    ///   fracstep of the rows that come from the corners (the first AViewHeightDiff + 1 rows for a look up,
    ///   AViewHeightDiff rows from AViewHeightRest for a look down; the others are copies, done by the caller)
    /// </summary>
    class procedure RowEdges(ALookDirection, AMaxLookDirection: Integer; const AAspect: Double;
      AViewWidth, AViewHeight, AViewHeightDiff, AViewHeightRest: Integer;
      out ALeftTop, ARightTop, ALeftBottom, ARightBottom: Integer;
      ALeft, ARight, AFracStep: PFake3DInteger); static;
  end;

implementation

uses
  DelphiDoom.MathCore.SoftExtended;

const
  FRACTION_UNIT = 65536;

function Ext(AValue: Int64): TSoftExtended; inline;
begin
  Result := TSoftExtended.FromInt64(AValue);
end;

function Dbl(const AValue: Double): TSoftExtended; inline;
begin
  Result := TSoftExtended.FromDouble(AValue);
end;

function At(ABase: PFake3DInteger; AIndex: Integer): PFake3DInteger; inline;
begin
  Result := PFake3DInteger(PByte(ABase) + AIndex * SizeOf(Integer));
end;

class function TRendererFake3DTables.Aspect(const ACosine: Double): Double;
begin
  Result := (Ext(2) - Dbl(ACosine)).ToDouble;
end;

class procedure TRendererFake3DTables.RowLookup(ALookDirection: Integer; const ACosine: Double;
  AViewHeight: Integer; AResult: PFake3DInteger);
var
  LBuffer, LBuffer2: TArray<Double>;
  LC1, LC2, LInverse, LC1Fraction, LRoot: Double;
  LIndex: Integer;
  LValue: TSoftExtended;
begin
  SetLength(LBuffer, AViewHeight);
  SetLength(LBuffer2, AViewHeight);
  LC1 := (Ext(2) * (Dbl(ACosine) - Ext(1))).ToDouble;
  LC2 := (Ext(2) - Dbl(ACosine)).ToDouble;
  LInverse := (Ext(1) / Dbl(LC2)).ToDouble;
  LC1Fraction := (Dbl(LC1) / Ext(AViewHeight)).ToDouble;
  LBuffer[0] := 0;
  for LIndex := 1 to AViewHeight - 1 do
    LBuffer[LIndex] := (Dbl(LBuffer[LIndex - 1]) + Ext(LIndex) * Dbl(LC1Fraction)).ToDouble;
  for LIndex := 0 to AViewHeight - 1 do
    LBuffer2[LIndex] := (Dbl(LBuffer[LIndex]) + Ext(LIndex) * Dbl(LC2)).ToDouble;
  LRoot := TSoftExtended.Sqrt(Ext(3)).ToDouble;
  for LIndex := 0 to AViewHeight - 1 do
  begin
    if ALookDirection >= 0 then
      LValue := Dbl(LInverse) * (Ext(LIndex) + Dbl(LRoot) * (Dbl(LBuffer2[LIndex]) - Ext(LIndex)))
    else
      LValue := Dbl(LInverse) * (Ext(LIndex) - Dbl(LRoot) * (Dbl(LBuffer2[LIndex]) - Ext(LIndex)));
    At(AResult, LIndex)^ := Integer(LValue.Round);
  end;
end;

class procedure TRendererFake3DTables.RowEdges(ALookDirection, AMaxLookDirection: Integer; const AAspect: Double;
  AViewWidth, AViewHeight, AViewHeightDiff, AViewHeightRest: Integer;
  out ALeftTop, ARightTop, ALeftBottom, ARightBottom: Integer;
  ALeft, ARight, AFracStep: PFake3DInteger);
var
  LStepLeft, LStepRight, LFactor, LCorrection: Double;
  LIndex, LRow: Integer;
  LLeftValue, LRightValue: Integer;
begin
  if ALookDirection >= 0 then
  begin
    ALeftTop := 0;
    ARightTop := AViewWidth - 1;
    LFactor := (Ext(AViewWidth) / Dbl(AAspect)).ToDouble;
    ALeftBottom := Integer((Ext(AViewWidth) - Dbl(LFactor)).Round);
    ARightBottom := AViewWidth - ALeftBottom - 1;
    LStepLeft := ALeftBottom - ALeftTop;
    LStepRight := ARightBottom - ARightTop;
    LFactor := (Ext(FRACTION_UNIT) / Ext(AViewWidth)).ToDouble;
    for LIndex := 0 to AViewHeightDiff do
    begin
      LCorrection := (Ext(ALookDirection) / Ext(AMaxLookDirection) *
        TSoftExtended.Sin(Ext(LIndex) / Ext(AViewHeight + AViewHeightRest)) * Ext(AViewHeight) / Ext(10)).ToDouble;
      LLeftValue := Integer((Ext(ALeftTop) + Dbl(LStepLeft) * Ext(LIndex) / Ext(AViewHeightDiff) -
        Dbl(LCorrection)).Round);
      if LLeftValue < 0 then
        LLeftValue := 0;
      At(ALeft, LIndex)^ := LLeftValue;
      LRightValue := Integer((Ext(ARightTop) + Dbl(LStepRight) * Ext(LIndex) / Ext(AViewHeightDiff) +
        Dbl(LCorrection)).Round);
      if LRightValue >= AViewWidth then
        LRightValue := AViewWidth - 1;
      At(ARight, LIndex)^ := LRightValue;
      At(AFracStep, LIndex)^ := Integer((Ext(LRightValue - LLeftValue) * Dbl(LFactor)).Round);
    end;
  end
  else
  begin
    LFactor := (Ext(AViewWidth) / Dbl(AAspect)).ToDouble;
    ALeftTop := Integer((Ext(AViewWidth) - Dbl(LFactor)).Round);
    ARightTop := AViewWidth - ALeftTop - 1;
    ALeftBottom := 0;
    ARightBottom := AViewWidth - 1;
    LStepLeft := ALeftBottom - ALeftTop;
    LStepRight := ARightBottom - ARightTop;
    LFactor := (Ext(FRACTION_UNIT) / Ext(AViewWidth)).ToDouble;
    for LIndex := 0 to AViewHeightDiff - 1 do
    begin
      LRow := LIndex + AViewHeightRest;
      LLeftValue := Integer((Ext(ALeftTop) + Dbl(LStepLeft) * Ext(LIndex) / Ext(AViewHeightDiff)).Round);
      if LLeftValue < 0 then
        LLeftValue := 0;
      At(ALeft, LRow)^ := LLeftValue;
      LRightValue := Integer((Ext(ARightTop) + Dbl(LStepRight) * Ext(LIndex) / Ext(AViewHeightDiff)).Round);
      if LRightValue >= AViewWidth then
        LRightValue := AViewWidth - 1;
      At(ARight, LRow)^ := LRightValue;
      At(AFracStep, LRow)^ := Integer((Ext(LRightValue - LLeftValue) * Dbl(LFactor)).Round);
    end;
  end;
end;

end.
