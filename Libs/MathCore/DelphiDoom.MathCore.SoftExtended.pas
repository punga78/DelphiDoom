{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the 80 bit FPU (Extended) in software       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.SoftExtended;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   The Extended of the 32 bit FPU (x87): a sign, a mantissa of 64 bits and a binary exponent, with the
  ///   operations of the processor (add, subtract, multiply, divide) rounded to the nearest even at 64 bits.
  ///   The 64 bit compiler has no Extended (it is a Double): where a golden file was made with the 32 bit code,
  ///   which keeps every intermediate of an expression in 64 bits of mantissa and rounds only when the result is
  ///   stored in a Double, the same expression written with this type gives the same bits. Only finite numbers in
  ///   the normal range are supported (no infinity, NaN, denormal or overflow of the exponent)
  /// </summary>
  /// <remarks>
  ///   It is slow (some tens of nanoseconds per operation): it is for the tests, the generators of tables and the
  ///   loading of data, not for the hot paths
  /// </remarks>
  TSoftExtended = record
  strict private
    FMantissa: UInt64;
    FExponent: Integer;
    FNegative: Boolean;
    class function Normalized(ANegative: Boolean; AHigh, ALow: UInt64; AExponent: Integer;
      ASticky: Boolean): TSoftExtended; static;
    class procedure Multiply128(const A, B: UInt64; out AHigh, ALow: UInt64); static;
    class function CompareMagnitude(const ALeft, ARight: TSoftExtended): Integer; static;
  public
    /// <summary>The number of a Double (exact)</summary>
    class function FromDouble(const AValue: Double): TSoftExtended; static;
    /// <summary>The number of an integer (exact)</summary>
    class function FromInt64(AValue: Int64): TSoftExtended; static;
    /// <summary>ANumerator / ADenominator rounded to 64 bits: the Extended that a decimal literal of the compiler is</summary>
    /// <summary>AMantissa * 2^AExponent, the mantissa of 64 bits as the FPU keeps it (a constant such as Pi)</summary>
    class function FromMantissa(AMantissa: UInt64; AExponent: Integer): TSoftExtended; static;
    class function FromRatio(const ANumerator, ADenominator: Int64): TSoftExtended; static;

    class operator Implicit(const AValue: Double): TSoftExtended;
    class operator Implicit(AValue: Integer): TSoftExtended;
    class operator Implicit(AValue: Int64): TSoftExtended;
    class operator Negative(const AValue: TSoftExtended): TSoftExtended;
    class operator Add(const ALeft, ARight: TSoftExtended): TSoftExtended;
    class operator Subtract(const ALeft, ARight: TSoftExtended): TSoftExtended;
    class operator Multiply(const ALeft, ARight: TSoftExtended): TSoftExtended;
    class operator Divide(const ALeft, ARight: TSoftExtended): TSoftExtended;
    class operator Equal(const ALeft, ARight: TSoftExtended): Boolean;
    class operator NotEqual(const ALeft, ARight: TSoftExtended): Boolean;
    class operator LessThan(const ALeft, ARight: TSoftExtended): Boolean;
    class operator LessThanOrEqual(const ALeft, ARight: TSoftExtended): Boolean;
    class operator GreaterThan(const ALeft, ARight: TSoftExtended): Boolean;
    class operator GreaterThanOrEqual(const ALeft, ARight: TSoftExtended): Boolean;

    /// <summary>Stored in a Double: rounded to 53 bits, to the nearest even (what fstp qword does)</summary>
    function ToDouble: Double;
    /// <summary>Trunc: the integer part (fistp with the truncation of the Delphi runtime)</summary>
    function Truncate: Int64;
    /// <summary>Round: to the nearest integer, halves to the even one</summary>
    function Round: Int64;
    function IsZero: Boolean;
    function IsNegative: Boolean;
    /// <summary>-1, 0 or 1</summary>
    class function Compare(const ALeft, ARight: TSoftExtended): Integer; static;
    property Mantissa: UInt64 read FMantissa;
    property BinaryExponent: Integer read FExponent;
  end;

implementation

uses
  System.SysUtils, System.Math;

{ TSoftExtended }

class procedure TSoftExtended.Multiply128(const A, B: UInt64; out AHigh, ALow: UInt64);
var
  LA0, LA1, LB0, LB1: UInt64;
  LP00, LP01, LP10, LP11: UInt64;
  LMiddle: UInt64;
begin
  LA0 := A and $FFFFFFFF;
  LA1 := A shr 32;
  LB0 := B and $FFFFFFFF;
  LB1 := B shr 32;
  LP00 := LA0 * LB0;
  LP01 := LA0 * LB1;
  LP10 := LA1 * LB0;
  LP11 := LA1 * LB1;
  LMiddle := (LP00 shr 32) + (LP01 and $FFFFFFFF) + (LP10 and $FFFFFFFF);
  ALow := (LP00 and $FFFFFFFF) or (LMiddle shl 32);
  AHigh := LP11 + (LP01 shr 32) + (LP10 shr 32) + (LMiddle shr 32);
end;

// value = (AHigh * 2^64 + ALow) * 2^AExponent, plus a part under the last bit when ASticky: normalized to 64 bits
// of mantissa and rounded to the nearest even
class function TSoftExtended.Normalized(ANegative: Boolean; AHigh, ALow: UInt64; AExponent: Integer;
  ASticky: Boolean): TSoftExtended;
var
  LShift: Integer;
  LRoundBit: Boolean;
  LRest: Boolean;
begin
  if (AHigh = 0) and (ALow = 0) then
  begin
    Result.FMantissa := 0;
    Result.FExponent := 0;
    Result.FNegative := False;
    Exit;
  end;
  if AHigh = 0 then
  begin
    AHigh := ALow;
    ALow := 0;
    Dec(AExponent, 64);
  end;
  LShift := 0;
  while (AHigh and $8000000000000000) = 0 do
  begin
    AHigh := AHigh shl 1;
    if (ALow and $8000000000000000) <> 0 then
      AHigh := AHigh or 1;
    ALow := ALow shl 1;
    Inc(LShift);
  end;
  Inc(AExponent, 64 - LShift);
  LRoundBit := (ALow and $8000000000000000) <> 0;
  LRest := ASticky or ((ALow and $7FFFFFFFFFFFFFFF) <> 0);
  if LRoundBit and (LRest or ((AHigh and 1) <> 0)) then
  begin
    Inc(AHigh);
    if AHigh = 0 then
    begin
      AHigh := $8000000000000000;
      Inc(AExponent);
    end;
  end;
  Result.FMantissa := AHigh;
  Result.FExponent := AExponent;
  Result.FNegative := ANegative;
end;

class function TSoftExtended.FromDouble(const AValue: Double): TSoftExtended;
var
  LBits: UInt64;
  LExponent: Integer;
  LFraction: UInt64;
begin
  LBits := PUInt64(@AValue)^;
  LExponent := Integer((LBits shr 52) and $7FF);
  LFraction := LBits and $000FFFFFFFFFFFFF;
  if LExponent = 0 then
    Result := Normalized((LBits shr 63) <> 0, 0, LFraction, -1074, False)
  else
    Result := Normalized((LBits shr 63) <> 0, 0, LFraction or $0010000000000000, LExponent - 1075, False);
end;

class function TSoftExtended.FromInt64(AValue: Int64): TSoftExtended;
begin
  if AValue < 0 then
    Result := Normalized(True, 0, UInt64(-(AValue + 1)) + 1, 0, False)
  else
    Result := Normalized(False, 0, UInt64(AValue), 0, False);
end;

class function TSoftExtended.FromMantissa(AMantissa: UInt64; AExponent: Integer): TSoftExtended;
begin
  Result := Normalized(False, 0, AMantissa, AExponent, False);
end;

class function TSoftExtended.FromRatio(const ANumerator, ADenominator: Int64): TSoftExtended;
begin
  Result := FromInt64(ANumerator) / FromInt64(ADenominator);
end;

class operator TSoftExtended.Implicit(const AValue: Double): TSoftExtended;
begin
  Result := FromDouble(AValue);
end;

class operator TSoftExtended.Implicit(AValue: Integer): TSoftExtended;
begin
  Result := FromInt64(AValue);
end;

class operator TSoftExtended.Implicit(AValue: Int64): TSoftExtended;
begin
  Result := FromInt64(AValue);
end;

class operator TSoftExtended.Negative(const AValue: TSoftExtended): TSoftExtended;
begin
  Result := AValue;
  if Result.FMantissa <> 0 then
    Result.FNegative := not Result.FNegative;
end;

class function TSoftExtended.CompareMagnitude(const ALeft, ARight: TSoftExtended): Integer;
begin
  if ALeft.FMantissa = 0 then
  begin
    if ARight.FMantissa = 0 then
      Exit(0);
    Exit(-1);
  end;
  if ARight.FMantissa = 0 then
    Exit(1);
  if ALeft.FExponent <> ARight.FExponent then
  begin
    if ALeft.FExponent > ARight.FExponent then
      Exit(1);
    Exit(-1);
  end;
  if ALeft.FMantissa > ARight.FMantissa then
    Exit(1);
  if ALeft.FMantissa < ARight.FMantissa then
    Exit(-1);
  Result := 0;
end;

class operator TSoftExtended.Add(const ALeft, ARight: TSoftExtended): TSoftExtended;
var
  LBig, LSmall: TSoftExtended;
  LDistance: Integer;
  LBigHigh, LBigLow, LSmallHigh, LSmallLow: UInt64;
  LHigh, LLow: UInt64;
  LSticky: Boolean;
  LExponent: Integer;
begin
  if ALeft.FMantissa = 0 then
    Exit(ARight);
  if ARight.FMantissa = 0 then
    Exit(ALeft);
  if CompareMagnitude(ALeft, ARight) >= 0 then
  begin
    LBig := ALeft;
    LSmall := ARight;
  end
  else
  begin
    LBig := ARight;
    LSmall := ALeft;
  end;
  // both as (high, low) with the mantissa in the high word: value = (high * 2^64 + low) * 2^(exponent - 64)
  LDistance := LBig.FExponent - LSmall.FExponent;
  LBigHigh := LBig.FMantissa;
  LBigLow := 0;
  LSticky := False;
  LSmallHigh := LSmall.FMantissa;
  LSmallLow := 0;
  if LDistance >= 128 then
  begin
    LSmallHigh := 0;
    LSticky := True;
  end
  else if LDistance >= 64 then
  begin
    if LDistance > 64 then
      LSticky := (LSmallHigh and ((UInt64(1) shl (LDistance - 64)) - 1)) <> 0
    else
      LSticky := False;
    LSmallLow := LSmallHigh shr (LDistance - 64);
    LSmallHigh := 0;
  end
  else if LDistance > 0 then
  begin
    LSmallLow := LSmallHigh shl (64 - LDistance);
    LSmallHigh := LSmallHigh shr LDistance;
  end;
  LExponent := LBig.FExponent - 64;
  if LBig.FNegative = LSmall.FNegative then
  begin
    LLow := LBigLow + LSmallLow;
    LHigh := LBigHigh + LSmallHigh;
    if LLow < LBigLow then
      Inc(LHigh);
    if LHigh < LBigHigh then
    begin
      // the carry out of 128 bits: one more bit on the left, the last one goes to the sticky
      LSticky := LSticky or ((LLow and 1) <> 0);
      LLow := (LLow shr 1) or (LHigh shl 63);
      LHigh := (LHigh shr 1) or $8000000000000000;
      Inc(LExponent);
    end;
    Result := Normalized(LBig.FNegative, LHigh, LLow, LExponent, LSticky);
  end
  else
  begin
    // the big one is not smaller in magnitude; when something was lost under the last bit of the small one the
    // exact difference is the integer one less plus a fraction
    LLow := LBigLow - LSmallLow;
    LHigh := LBigHigh - LSmallHigh;
    if LBigLow < LSmallLow then
      Dec(LHigh);
    if LSticky then
    begin
      if LLow = 0 then
        Dec(LHigh);
      Dec(LLow);
    end;
    Result := Normalized(LBig.FNegative, LHigh, LLow, LExponent, LSticky);
    if (LHigh = 0) and (LLow = 0) and not LSticky then
      Result := Normalized(False, 0, 0, 0, False);
  end;
end;

class operator TSoftExtended.Subtract(const ALeft, ARight: TSoftExtended): TSoftExtended;
begin
  Result := ALeft + (-ARight);
end;

class operator TSoftExtended.Multiply(const ALeft, ARight: TSoftExtended): TSoftExtended;
var
  LHigh, LLow: UInt64;
begin
  if (ALeft.FMantissa = 0) or (ARight.FMantissa = 0) then
    Exit(Normalized(False, 0, 0, 0, False));
  Multiply128(ALeft.FMantissa, ARight.FMantissa, LHigh, LLow);
  Result := Normalized(ALeft.FNegative <> ARight.FNegative, LHigh, LLow, ALeft.FExponent + ARight.FExponent,
    False);
end;

class operator TSoftExtended.Divide(const ALeft, ARight: TSoftExtended): TSoftExtended;
var
  LRemainder: UInt64;
  LHigh, LLow: UInt64;
  LIndex: Integer;
  LBit: UInt64;
  LCarry: Boolean;
begin
  if ARight.FMantissa = 0 then
    raise EZeroDivide.Create('Division by zero');
  if ALeft.FMantissa = 0 then
    Exit(Normalized(False, 0, 0, 0, False));
  // 66 bits of quotient of two mantissas in [2^63, 2^64): the first one is the integer part (0 or 1)
  LRemainder := ALeft.FMantissa;
  LHigh := 0;
  LLow := 0;
  for LIndex := 0 to 66 do
  begin
    if LIndex > 0 then
    begin
      LCarry := (LRemainder and $8000000000000000) <> 0;
      LRemainder := LRemainder shl 1;
    end
    else
      LCarry := False;
    if LCarry or (LRemainder >= ARight.FMantissa) then
    begin
      LRemainder := LRemainder - ARight.FMantissa;
      LBit := 1;
    end
    else
      LBit := 0;
    LHigh := (LHigh shl 1) or (LLow shr 63);
    LLow := (LLow shl 1) or LBit;
  end;
  // (LHigh:LLow) holds the quotient times 2^66
  Result := Normalized(ALeft.FNegative <> ARight.FNegative, LHigh, LLow,
    ALeft.FExponent - ARight.FExponent - 66, LRemainder <> 0);
end;

class function TSoftExtended.Compare(const ALeft, ARight: TSoftExtended): Integer;
begin
  if ALeft.FMantissa = 0 then
  begin
    if ARight.FMantissa = 0 then
      Exit(0);
    if ARight.FNegative then
      Exit(1);
    Exit(-1);
  end;
  if ARight.FMantissa = 0 then
  begin
    if ALeft.FNegative then
      Exit(-1);
    Exit(1);
  end;
  if ALeft.FNegative <> ARight.FNegative then
  begin
    if ALeft.FNegative then
      Exit(-1);
    Exit(1);
  end;
  Result := CompareMagnitude(ALeft, ARight);
  if ALeft.FNegative then
    Result := -Result;
end;

class operator TSoftExtended.Equal(const ALeft, ARight: TSoftExtended): Boolean;
begin
  Result := Compare(ALeft, ARight) = 0;
end;

class operator TSoftExtended.NotEqual(const ALeft, ARight: TSoftExtended): Boolean;
begin
  Result := Compare(ALeft, ARight) <> 0;
end;

class operator TSoftExtended.LessThan(const ALeft, ARight: TSoftExtended): Boolean;
begin
  Result := Compare(ALeft, ARight) < 0;
end;

class operator TSoftExtended.LessThanOrEqual(const ALeft, ARight: TSoftExtended): Boolean;
begin
  Result := Compare(ALeft, ARight) <= 0;
end;

class operator TSoftExtended.GreaterThan(const ALeft, ARight: TSoftExtended): Boolean;
begin
  Result := Compare(ALeft, ARight) > 0;
end;

class operator TSoftExtended.GreaterThanOrEqual(const ALeft, ARight: TSoftExtended): Boolean;
begin
  Result := Compare(ALeft, ARight) >= 0;
end;

function TSoftExtended.ToDouble: Double;
var
  LSignificand: UInt64;
  LLow: UInt64;
begin
  if FMantissa = 0 then
    Exit(0.0);
  LSignificand := FMantissa shr 11;
  LLow := FMantissa and $7FF;
  if (LLow > $400) or ((LLow = $400) and ((LSignificand and 1) <> 0)) then
    Inc(LSignificand);
  // LSignificand has at most 54 bits (2^53 exactly after a carry), both exact in a Double
  Result := Ldexp(Double(LSignificand), FExponent + 11);
  if FNegative then
    Result := -Result;
end;

function TSoftExtended.Truncate: Int64;
var
  LShift: Integer;
begin
  if FMantissa = 0 then
    Exit(0);
  if FExponent >= 0 then
    Result := Int64(FMantissa shl FExponent)
  else
  begin
    LShift := -FExponent;
    if LShift >= 64 then
      Result := 0
    else
      Result := Int64(FMantissa shr LShift);
  end;
  if FNegative then
    Result := -Result;
end;

function TSoftExtended.Round: Int64;
var
  LShift: Integer;
  LQuotient: UInt64;
  LRest: UInt64;
  LHalf: UInt64;
begin
  if FMantissa = 0 then
    Exit(0);
  if FExponent >= 0 then
    LQuotient := FMantissa shl FExponent
  else
  begin
    LShift := -FExponent;
    if LShift > 64 then
      LQuotient := 0
    else if LShift = 64 then
    begin
      // the value is in [0.5, 1): a half goes to 0 (even), the rest to 1
      if FMantissa > $8000000000000000 then
        LQuotient := 1
      else
        LQuotient := 0;
    end
    else
    begin
      LQuotient := FMantissa shr LShift;
      LRest := FMantissa and ((UInt64(1) shl LShift) - 1);
      LHalf := UInt64(1) shl (LShift - 1);
      if (LRest > LHalf) or ((LRest = LHalf) and ((LQuotient and 1) <> 0)) then
        Inc(LQuotient);
    end;
  end;
  Result := Int64(LQuotient);
  if FNegative then
    Result := -Result;
end;

function TSoftExtended.IsZero: Boolean;
begin
  Result := FMantissa = 0;
end;

function TSoftExtended.IsNegative: Boolean;
begin
  Result := FNegative;
end;

end.
