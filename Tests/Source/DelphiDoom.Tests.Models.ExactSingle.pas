{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - a Single computed without      }
{  the rounding of the FPU                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.ExactSingle;

// SetPrecisionMode is a no-op on 64 bit and the whole point on 32 bit
{$WARN SYMBOL_PLATFORM OFF}

interface

type
  /// <summary>
  ///   The Single nearest to Start + (End - Start) * Fraction, the same on 32 and 64 bit. The golden
  ///   files were made on the 32 bit FPU, which keeps 64 bits in every intermediate value of an
  ///   expression and rounds only when the Single is stored; the 64 bit compiler rounds to 53 bits
  ///   at every step, and the Single that comes out differs in the last bit now and then (a test
  ///   input one ULP away changes every vertex of a model). The value is computed with the error
  ///   free transformations of Dekker and Knuth (the exact result as the sum of a Double and a
  ///   small remainder) and rounded once, so the result does not depend on the FPU.
  /// </summary>
  TModelsExactSingle = class
  strict private
    class procedure TwoSum(const AFirst, ASecond: Double; out ASum, AError: Double); static;
    class procedure TwoProduct(const AFirst, ASecond: Double; out AProduct, AError: Double); static;
    /// <summary>The Single nearest to ASum + ARemainder, where ASum is the Double nearest to that value</summary>
    class function RoundToSingle(const ASum, ARemainder: Double): Single; static;
  public
    /// <summary>The Single nearest to AStart + (AEnd - AStart) * AFraction</summary>
    class function Interpolate(const AStart, AEnd, AFraction: Double): Single; static;
  end;

implementation

uses
  System.Math;

const
  // 2^27 + 1: splits a Double in two halves of 26 bits
  DEKKER_SPLITTER = 134217729.0;
  // the 29 bits of a Double that a Single does not have
  SINGLE_TAIL_MASK = Int64($1FFFFFFF);
  SINGLE_TIE = Int64($10000000);

{ TModelsExactSingle }

class procedure TModelsExactSingle.TwoSum(const AFirst, ASecond: Double; out ASum, AError: Double);
var
  LVirtual: Double;
begin
  ASum := AFirst + ASecond;
  LVirtual := ASum - AFirst;
  AError := (AFirst - (ASum - LVirtual)) + (ASecond - LVirtual);
end;

class procedure TModelsExactSingle.TwoProduct(const AFirst, ASecond: Double; out AProduct, AError: Double);
var
  LScaled, LFirstHigh, LFirstLow, LSecondHigh, LSecondLow: Double;
begin
  AProduct := AFirst * ASecond;
  LScaled := DEKKER_SPLITTER * AFirst;
  LFirstHigh := LScaled - (LScaled - AFirst);
  LFirstLow := AFirst - LFirstHigh;
  LScaled := DEKKER_SPLITTER * ASecond;
  LSecondHigh := LScaled - (LScaled - ASecond);
  LSecondLow := ASecond - LSecondHigh;
  AError := ((LFirstHigh * LSecondHigh - AProduct) + LFirstHigh * LSecondLow + LFirstLow * LSecondHigh) +
    LFirstLow * LSecondLow;
end;

class function TModelsExactSingle.RoundToSingle(const ASum, ARemainder: Double): Single;
var
  LBits: Int64;
begin
  Result := ASum;
  if ARemainder = 0 then
    Exit;
  LBits := PInt64(@ASum)^;
  // the Double is exactly between two Singles: the remainder says on which side the real value is
  if (LBits and SINGLE_TAIL_MASK) = SINGLE_TIE then
  begin
    if (ARemainder > 0) = (ASum > 0) then
      Inc(LBits)
    else
      Dec(LBits);
    Result := PDouble(@LBits)^;
  end;
end;

class function TModelsExactSingle.Interpolate(const AStart, AEnd, AFraction: Double): Single;
var
  LMode: TFPUPrecisionMode;
  LDelta, LDeltaError, LProduct, LProductError, LSum, LSumError, LHigh, LRest: Double;
begin
  // with the 53 bit precision of the 32 bit FPU the error free transformations hold as on SSE
  LMode := SetPrecisionMode(pmDouble);
  try
    TwoSum(AEnd, -AStart, LDelta, LDeltaError);
    TwoProduct(LDelta, AFraction, LProduct, LProductError);
    TwoSum(AStart, LProduct, LSum, LSumError);
    // the three remainders can add up to more than half a ULP of the sum: one more step puts the Double
    // nearest to the real value in LHigh and what is left in LRest
    TwoSum(LSum, LSumError + LProductError + LDeltaError * AFraction, LHigh, LRest);
    Result := RoundToSingle(LHigh, LRest);
  finally
    SetPrecisionMode(LMode);
  end;
end;

end.
