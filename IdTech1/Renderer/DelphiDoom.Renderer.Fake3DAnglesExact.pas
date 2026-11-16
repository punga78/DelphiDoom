{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the angles of the "fake 3D" view with the    }
{  result of the 32 bit code                                                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The expressions are those of TRendererFake3DAngles                          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.Fake3DAnglesExact;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The table of TRendererFake3DAngles computed without the FPU: every intermediate has the 64 bits of
  ///   mantissa of the x87 and the result is stored in a Double, so it is the table of the 32 bit code (issue
  ///   #40). The 64 bit renderer calls it (there Extended is a Double); the 32 bit one never links it
  /// </summary>
  TRendererFake3DAnglesExact = class
  public
    /// <summary>The cosines of the angles of AMinIndex..AMaxIndex of the look direction</summary>
    class function Cosines(AMinIndex, AMaxIndex: Integer): TArray<Double>; static;
  end;

implementation

uses
  DelphiDoom.MathCore.SoftExtended;

const
  // Pi of the System unit as an Extended
  PI_MANTISSA = UInt64($C90FDAA22168C235);
  PI_EXPONENT = -62;

class function TRendererFake3DAnglesExact.Cosines(AMinIndex, AMaxIndex: Integer): TArray<Double>;
var
  LPi, LAngleScale, LEpsilon, LRangeEpsilon, LTwo: TSoftExtended;
  A1, A2, B1, B2, C1, C2: TSoftExtended;
  LDeterminant, LU, LV: TSoftExtended;
  X, Y, R: TSoftExtended;
  LRoot, LDelta, V1, V2: TSoftExtended;
  LLow, LHigh: TSoftExtended;
  LIndex: Integer;
  LInside: Boolean;
begin
  if AMaxIndex < AMinIndex then
    raise EArgumentException.Create('AMaxIndex');
  SetLength(Result, AMaxIndex - AMinIndex + 1);
  LPi := TSoftExtended.FromMantissa(PI_MANTISSA, PI_EXPONENT);
  LAngleScale := TSoftExtended.FromRatio(1, 32); // 0.5 / 16
  LRangeEpsilon := TSoftExtended.FromRatio(1, 1000);
  LEpsilon := TSoftExtended.FromRatio(1, 10000000000);
  LTwo := TSoftExtended.FromInt64(2);
  A1 := TSoftExtended.FromInt64(AMinIndex);
  A2 := A1 * LAngleScale * LPi / TSoftExtended.FromInt64(270);
  LLow := A2 - LRangeEpsilon;
  B1 := TSoftExtended.FromInt64(0);
  B2 := TSoftExtended.FromInt64(0);
  C1 := TSoftExtended.FromInt64(AMaxIndex);
  C2 := C1 * LAngleScale * LPi / TSoftExtended.FromInt64(180);
  LHigh := C2 + LRangeEpsilon;
  LDeterminant := (A1 - B1) * (B2 - C2) - (B1 - C1) * (A2 - B2);
  if (LDeterminant > -LEpsilon) and (LDeterminant < LEpsilon) then
  begin
    // unreachable with the real range: the points are not collinear
    for LIndex := 0 to High(Result) do
      Result[LIndex] := 1.0;
    Exit;
  end;
  LU := (A1 * A1 - B1 * B1 + A2 * A2 - B2 * B2) / LTwo;
  LV := (B1 * B1 - C1 * C1 + B2 * B2 - C2 * C2) / LTwo;
  X := (LU * (B2 - C2) - LV * (A2 - B2)) / LDeterminant;
  Y := (LV * (A1 - B1) - LU * (B1 - C1)) / LDeterminant;
  R := TSoftExtended.Sqrt((X - A1) * (X - A1) + (Y - A2) * (Y - A2));
  for LIndex := AMinIndex to AMaxIndex do
  begin
    LDelta := TSoftExtended.FromInt64(LIndex) - X;
    LRoot := TSoftExtended.Sqrt(R * R - LDelta * LDelta);
    V1 := Y - LRoot;
    V2 := Y + LRoot;
    if LLow < LHigh then
      LInside := (V1 >= LLow) and (V1 <= LHigh)
    else
      LInside := (V1 >= LHigh) and (V1 <= LLow);
    if LInside then
      Result[LIndex - AMinIndex] := TSoftExtended.Cos(V1).ToDouble
    else
      Result[LIndex - AMinIndex] := TSoftExtended.Cos(V2).ToDouble;
  end;
end;

end.
