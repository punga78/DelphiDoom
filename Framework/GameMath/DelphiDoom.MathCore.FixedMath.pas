{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the fixed point arithmetic (16.16)          }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.FixedMath;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types;

type
  /// <summary>
  ///   The functions of the old m_fixed in pure Pascal (no asm, so they work at 32 and 64 bit).
  ///   They have no state. The results are the same as the old ones for every input where the old
  ///   ones gave a result; where the old code raised the exception of the processor (idiv with a
  ///   zero divisor or a quotient that does not fit) these raise EMathCoreException.
  /// </summary>
  /// <remarks>
  ///   Performance: these are the functions of the hot paths of the renderer. They are static and
  ///   inline (no virtual calls) and are meant for new code and for the tests: the engine keeps
  ///   its own functions (see WIRING.md).
  /// </remarks>
  TFixedMath = class
  public
    /// <summary>Arithmetic shift to the right (the Delphi shr is logical)</summary>
    class function ShiftRight(AValue: Integer; ABits: Integer): Integer; static; inline;
    /// <summary>The absolute value; the smallest integer stays negative as it did</summary>
    class function AbsWrap(AValue: Integer): Integer; static; inline;
    /// <summary>
    ///   ANumerator / ADenominator rounded to the nearest integer, halves to the even one (the
    ///   rounding of Round and of the FPU); ADenominator must be positive
    /// </summary>
    class function RoundDivide(ANumerator, ADenominator: Int64): Int64; static;

    /// <summary>The old FixedMul: (a * b) shr 16 on 64 bits, the low 32 bits</summary>
    class function Mul(const A, B: TFixed): TFixed; static; inline;
    class function MulShl3(const A, B: TFixed): TFixed; static; inline;
    class function MulShl4(const A, B: TFixed): TFixed; static; inline;
    class function MulShl5(const A, B: TFixed): TFixed; static; inline;
    class function MulShl8(const A, B: TFixed): TFixed; static; inline;
    class function MulShl10(const A, B: TFixed): TFixed; static; inline;
    class function MulShl14(const A, B: TFixed): TFixed; static; inline;
    /// <summary>(a * b) shr 19 (the old FixedMulDiv8)</summary>
    class function MulDiv8(const A, B: TFixed): TFixed; static; inline;
    /// <summary>(a * b) shr 20 (the old FixedMulDiv16)</summary>
    class function MulDiv16(const A, B: TFixed): TFixed; static; inline;
    /// <summary>(a * b) shr 24 (the old FixedMulDiv256)</summary>
    class function MulDiv256(const A, B: TFixed): TFixed; static; inline;
    /// <summary>Round(a / 65536 * b): the product rounded, halves to even (the old FixedMulEx)</summary>
    class function MulRounded(const A, B: TFixed): TFixed; static;
    /// <summary>(a sar 8) * (b sar 8) in fixed point (the old FixedMul88)</summary>
    class function Mul88(const A, B: TFixed): TFixed; static; inline;
    /// <summary>(a sar 8) * b in fixed point (the old FixedMul8)</summary>
    class function Mul8(const A, B: TFixed): TFixed; static; inline;
    /// <summary>a * (b sar 16): b is read as an integer (the old FixedIntMul)</summary>
    class function MulByInteger(const A, B: TFixed): TFixed; static; inline;
    /// <summary>(a sar 16) * b: a is read as an integer (the old IntFixedMul)</summary>
    class function IntegerMul(const A, B: TFixed): TFixed; static; inline;
    /// <summary>The integer part of the product (the old FixedInt_FixedMul)</summary>
    class function IntegerOfMul(const A, B: TFixed): TFixed; static; inline;

    /// <summary>The division with the overflow check: a / b saturates (the old FixedDiv)</summary>
    class function Divide(const A, B: TFixed): TFixed; static;
    /// <summary>As Divide but for a positive divisor and no check of the sign (the old FixedDiv_Positive)</summary>
    class function DividePositive(const A, B: TFixed): TFixed; static;
    /// <summary>The division of the unsigned values (the old FixedDivLW), the idiv of the signed ones</summary>
    class function DivideUnsigned(const A, B: Cardinal): Cardinal; static;
    /// <summary>
    ///   FIXED_ONE minus DivideUnsigned, wrapping around (the old ASM_CalcFactor of the light maps)
    /// </summary>
    class function OneMinusDivideUnsigned(const A, B: Cardinal): Cardinal; static;
    /// <summary>Only the zero divisor is checked (the old FixedDiv_fast)</summary>
    class function DivideFast(const A, B: TFixed): TFixed; static;
    /// <summary>The division in floating point, rounded to the nearest (the old FixedDivEx)</summary>
    class function DivideEx(const A, B: TFixed): TFixed; static;
    /// <summary>The bare division, (a shl 16) / b (the old FixedDiv2); raises if it does not fit</summary>
    class function DivideRaw(const A, B: TFixed): TFixed; static;

    /// <summary>The integer part (the old FixedInt)</summary>
    class function ToInteger(const X: Integer): Integer; static; inline;
    class function FromSingle(const F: Single): TFixed; static;
    class function FromDouble(const F: Double): TFixed; static;
    class function FromExtended(const F: Extended): TFixed; static;
    class function ToSingle(const X: TFixed): Single; static;
    class function ToDouble(const X: TFixed): Double; static;
    class function ToExtended(const X: TFixed): Extended; static;
    /// <summary>Round(Sqrt(a / 65536) * 65536); a negative number raises the exception of the FPU</summary>
    class function Sqrt(const A: TFixed): TFixed; static;
    /// <summary>The integer part of a 16.16 number held in 64 bits (the old FixedInt64)</summary>
    class function Int64ToInteger(const X: Int64): Integer; static;
    /// <summary>
    ///   Round(a / 65536 * b) of the old FixedMul64, in integers (no floating point, so 32 and 64 bit give the
    ///   same number). The old code did it in the Extended of the x87 (64 bits of mantissa): the product is
    ///   exact up to 63 bits and it is rounded once to the nearest even; beyond that the product is rounded
    ///   to 64 significant bits first and then to the integer (two roundings, done here on purpose). When
    ///   the result does not fit in an Int64 the x87 gives the integer indefinite, Low(Int64), and so does this
    /// </summary>
    class function Mul64(const A, B: Int64): Int64; static;
    /// <summary>
    ///   Double(Extended(A) / Extended(B)) as the 32 bit FPU computes it: the quotient is rounded to 64
    ///   bits of mantissa and then to 53. The 64 bit compiler has no Extended and rounds once, which gives a
    ///   number one bit away once in a thousand: here the double rounding is done on purpose, so the golden
    ///   files made with the 32 bit code hold at 64 bit too
    /// </summary>
    class function ExtendedQuotient(const A, B: Double): Double; static;
    class function FloatDivide(const A, B: Double): Double; static;
    class function FloatMul(const A, B: Double): Double; static;
    /// <summary>a mod b guaranteed to be in 0..b-1 (the old FixedMod)</summary>
    class function Modulo(const A, B: TFixed): TFixed; static;
  end;

implementation

{$IF SizeOf(Extended) = SizeOf(Double)}
uses
  System.Math;
{$IFEND}

// The 128 bit product of two unsigned 64 bit numbers, as four 32 bit parts
procedure Multiply64x64(const A, B: UInt64; out AHigh, ALow: UInt64);
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
  // the sum of the three terms that weigh 2^32 cannot overflow 64 bits
  LMiddle := (LP00 shr 32) + (LP01 and $FFFFFFFF) + (LP10 and $FFFFFFFF);
  ALow := (LP00 and $FFFFFFFF) or (LMiddle shl 32);
  AHigh := LP11 + (LP01 shr 32) + (LP10 shr 32) + (LMiddle shr 32);
end;

function BitLength(AValue: UInt64): Integer;
begin
  Result := 0;
  while AValue <> 0 do
  begin
    Inc(Result);
    AValue := AValue shr 1;
  end;
end;

// AValue / 2^AShift rounded to the nearest, a half to the even one; AShift is 1..63
function ShiftRightRounded(AValue: UInt64; AShift: Integer): UInt64;
var
  LRemainder: UInt64;
  LHalf: UInt64;
begin
  Result := AValue shr AShift;
  LRemainder := AValue and ((UInt64(1) shl AShift) - 1);
  LHalf := UInt64(1) shl (AShift - 1);
  if (LRemainder > LHalf) or ((LRemainder = LHalf) and Odd(Result)) then
    Inc(Result);
end;

// The product of A and B divided by 65536 with the roundings of the x87 (see TFixedMath.Mul64)
function WideMul64(const A, B: Int64): Int64;
var
  LAbsA, LAbsB: UInt64;
  LHigh, LLow: UInt64;
  LBits: Integer;
  LDrop: Integer;
  LShift: Integer;
  LRemainder: UInt64;
  LHalf: UInt64;
  LCarry: Boolean;
  LQuotient: UInt64;
begin
  if A < 0 then
    LAbsA := UInt64(0) - UInt64(A)
  else
    LAbsA := UInt64(A);
  if B < 0 then
    LAbsB := UInt64(0) - UInt64(B)
  else
    LAbsB := UInt64(B);
  Multiply64x64(LAbsA, LAbsB, LHigh, LLow);

  // 2^80 / 2^16 = 2^64: it does not fit in an Int64, whatever the roundings
  if LHigh >= $10000 then
    Exit(Low(Int64));

  if LHigh <> 0 then
    LBits := 64 + BitLength(LHigh)
  else
    LBits := BitLength(LLow);

  LCarry := False;
  LDrop := 0;
  if LBits > 64 then
  begin
    // first rounding: to the 64 significant bits of the mantissa (LDrop is 1..16)
    LDrop := LBits - 64;
    LRemainder := LLow and ((UInt64(1) shl LDrop) - 1);
    LHalf := UInt64(1) shl (LDrop - 1);
    LLow := (LLow shr LDrop) or (LHigh shl (64 - LDrop));
    if (LRemainder > LHalf) or ((LRemainder = LHalf) and Odd(LLow)) then
    begin
      Inc(LLow);
      LCarry := LLow = 0;
    end;
  end;

  // second rounding: the mantissa is worth mantissa * 2^LDrop / 2^16 (LShift is 0..16)
  LShift := 16 - LDrop;
  if LCarry then
  begin
    // the mantissa became 2^64
    if LShift = 0 then
      Exit(Low(Int64));
    LQuotient := UInt64(1) shl (64 - LShift);
  end
  else if LShift = 0 then
    LQuotient := LLow
  else
    LQuotient := ShiftRightRounded(LLow, LShift);

  // 2^63 is Low(Int64) when it is negative and the integer indefinite when it is positive: the same
  if LQuotient >= UInt64(1) shl 63 then
    Exit(Low(Int64));
  if (A < 0) <> (B < 0) then
    Result := -Int64(LQuotient)
  else
    Result := Int64(LQuotient);
end;

{ TFixedMath }

class function TFixedMath.ShiftRight(AValue: Integer; ABits: Integer): Integer;
begin
  if AValue >= 0 then
    Result := AValue shr ABits
  else
    Result := not ((not AValue) shr ABits);
end;

class function TFixedMath.AbsWrap(AValue: Integer): Integer;
begin
  if AValue < 0 then
    Result := -AValue
  else
    Result := AValue;
end;

class function TFixedMath.RoundDivide(ANumerator, ADenominator: Int64): Int64;
var
  LQuotient: Int64;
  LRemainder: Int64;
  LTwice: Int64;
begin
  LQuotient := ANumerator div ADenominator;
  LRemainder := ANumerator mod ADenominator;
  // div and mod truncate towards zero: bring them to the floor
  if LRemainder < 0 then
  begin
    Dec(LQuotient);
    Inc(LRemainder, ADenominator);
  end;
  LTwice := LRemainder * 2;
  if LTwice > ADenominator then
    Inc(LQuotient)
  else if (LTwice = ADenominator) and Odd(LQuotient) then
    Inc(LQuotient);
  Result := LQuotient;
end;

class function TFixedMath.Mul(const A, B: TFixed): TFixed;
begin
  Result := Integer((Int64(A) * B) shr 16);
end;

class function TFixedMath.MulShl3(const A, B: TFixed): TFixed;
begin
  Result := Integer((Int64(A) * B) shr 16) shl 3;
end;

class function TFixedMath.MulShl4(const A, B: TFixed): TFixed;
begin
  Result := Integer((Int64(A) * B) shr 16) shl 4;
end;

class function TFixedMath.MulShl5(const A, B: TFixed): TFixed;
begin
  Result := Integer((Int64(A) * B) shr 16) shl 5;
end;

class function TFixedMath.MulShl8(const A, B: TFixed): TFixed;
begin
  Result := Integer((Int64(A) * B) shr 16) shl 8;
end;

class function TFixedMath.MulShl10(const A, B: TFixed): TFixed;
begin
  Result := Integer((Int64(A) * B) shr 16) shl 10;
end;

class function TFixedMath.MulShl14(const A, B: TFixed): TFixed;
begin
  Result := Integer((Int64(A) * B) shr 16) shl 14;
end;

class function TFixedMath.MulDiv8(const A, B: TFixed): TFixed;
begin
  Result := Integer((Int64(A) * B) shr 19);
end;

class function TFixedMath.MulDiv16(const A, B: TFixed): TFixed;
begin
  Result := Integer((Int64(A) * B) shr 20);
end;

class function TFixedMath.MulDiv256(const A, B: TFixed): TFixed;
begin
  Result := Integer((Int64(A) * B) shr 24);
end;

class function TFixedMath.MulRounded(const A, B: TFixed): TFixed;
begin
  // The old code was Round(a / FRACUNIT * b): a / 65536 and the product are exact in the 64 bit
  // mantissa of the FPU, so this is the same number, also where Extended is a Double
  Result := Integer(RoundDivide(Int64(A) * B, FIXED_ONE));
end;

class function TFixedMath.Mul88(const A, B: TFixed): TFixed;
begin
  Result := Integer((Int64(ShiftRight(A, 8)) * ShiftRight(B, 8)) shr 16);
end;

class function TFixedMath.Mul8(const A, B: TFixed): TFixed;
begin
  Result := Integer((Int64(ShiftRight(A, 8)) * B) shr 16);
end;

class function TFixedMath.MulByInteger(const A, B: TFixed): TFixed;
begin
  Result := Integer((Int64(A) * ShiftRight(B, FIXED_FRACBITS)) shr 16);
end;

class function TFixedMath.IntegerMul(const A, B: TFixed): TFixed;
begin
  Result := Integer((Int64(ShiftRight(A, FIXED_FRACBITS)) * B) shr 16);
end;

class function TFixedMath.IntegerOfMul(const A, B: TFixed): TFixed;
begin
  Result := ShiftRight(Integer((Int64(A) * B) shr 16), FIXED_FRACBITS);
end;

class function TFixedMath.Divide(const A, B: TFixed): TFixed;
begin
  if ShiftRight(AbsWrap(A), 14) >= AbsWrap(B) then
  begin
    if (A xor B) < 0 then
      Result := FIXED_MIN
    else
      Result := FIXED_MAX;
  end
  else
    Result := DivideRaw(A, B);
end;

class function TFixedMath.DividePositive(const A, B: TFixed): TFixed;
begin
  if (A shr 14) >= B then
    Result := FIXED_MAX
  else
    Result := DivideRaw(A, B);
end;

class function TFixedMath.DivideUnsigned(const A, B: Cardinal): Cardinal;
var
  LQuotient: Int64;
begin
  if (B <= (A shr 14)) or (B = 0) then
    Result := FIXED_MAX
  else
  begin
    // the processor divides the values as signed ones
    LQuotient := (Int64(Integer(A)) shl 16) div Integer(B);
    if (LQuotient < FIXED_MIN) or (LQuotient > FIXED_MAX) then
      raise EMathCoreException.Create(SDivisionOverflow);
    Result := Cardinal(Integer(LQuotient));
  end;
end;

class function TFixedMath.OneMinusDivideUnsigned(const A, B: Cardinal): Cardinal;
begin
  // sub eax, FRACUNIT; neg eax: the same as FIXED_ONE - quotient, modulo 2^32
  Result := Cardinal(FIXED_ONE) - DivideUnsigned(A, B);
end;

class function TFixedMath.DivideFast(const A, B: TFixed): TFixed;
begin
  if B = 0 then
    Result := FIXED_MAX
  else
    Result := DivideRaw(A, B);
end;

class function TFixedMath.DivideEx(const A, B: TFixed): TFixed;
var
  LValue: Double;
  LBits: Int64;
  {$IF SizeOf(Extended) = SizeOf(Double)}
  LFloor: Double;
  LScaled: Integer;
  {$IFEND}
begin
  if B = 0 then
  begin
    if A < 0 then
      Result := FIXED_MIN
    else
      Result := FIXED_MAX;
  end
  else
  begin
    LValue := ExtendedQuotient(A, B) * FIXED_ONE;
    if LValue < FIXED_MIN + 1 then
      Result := FIXED_MIN
    else if LValue > FIXED_MAX - 1 then
      Result := FIXED_MAX
    else
    begin
      // http://stereopsis.com/sree/fpu2006.html - fast round of a double
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LValue := LValue + 6755399441055744.0;
      Move(LValue, LBits, SizeOf(LBits));
      Result := Integer(LBits);
      {$ELSE}
      // The sum is made by the 32 bit FPU in 64 bits of mantissa (a step of 1/2048 at that magnitude) and then
      // rounded to the 53 of the Double: a value that is a bit over (or under) the half of an integer is first
      // brought to the half and then goes to the even one. Done here on purpose, to give the same number
      LFloor := Floor(LValue);
      LScaled := Round((LValue - LFloor) * 2048);
      if LScaled > 1024 then
        LBits := Trunc(LFloor) + 1
      else if LScaled < 1024 then
        LBits := Trunc(LFloor)
      else if Odd(Trunc(LFloor)) then
        LBits := Trunc(LFloor) + 1
      else
        LBits := Trunc(LFloor);
      Result := Integer(LBits);
      {$IFEND}
    end;
  end;
end;

class function TFixedMath.DivideRaw(const A, B: TFixed): TFixed;
var
  LQuotient: Int64;
begin
  if B = 0 then
    raise EMathCoreException.Create(SDivisionByZero);
  LQuotient := (Int64(A) shl 16) div B;
  if (LQuotient < FIXED_MIN) or (LQuotient > FIXED_MAX) then
    raise EMathCoreException.Create(SDivisionOverflow);
  Result := Integer(LQuotient);
end;

class function TFixedMath.ToInteger(const X: Integer): Integer;
begin
  Result := ShiftRight(X, FIXED_FRACBITS);
end;

class function TFixedMath.FromSingle(const F: Single): TFixed;
begin
  Result := Round(F * FIXED_ONE);
end;

class function TFixedMath.FromDouble(const F: Double): TFixed;
begin
  Result := Round(F * FIXED_ONE);
end;

class function TFixedMath.FromExtended(const F: Extended): TFixed;
begin
  Result := Round(F * FIXED_ONE);
end;

class function TFixedMath.ToSingle(const X: TFixed): Single;
begin
  Result := X / FIXED_ONE;
end;

class function TFixedMath.ToDouble(const X: TFixed): Double;
begin
  Result := X / FIXED_ONE;
end;

class function TFixedMath.ToExtended(const X: TFixed): Extended;
begin
  Result := X / FIXED_ONE;
end;

class function TFixedMath.Sqrt(const A: TFixed): TFixed;
begin
  Result := Round(System.Sqrt(A / FIXED_ONE) * FIXED_ONE);
end;

class function TFixedMath.Int64ToInteger(const X: Int64): Integer;
var
  LMagnitude: Int64;
begin
  // bits 16..47 of the number, as the old code read them from memory
  if X < 0 then
  begin
    LMagnitude := -X;
    Result := -Integer(Cardinal((LMagnitude shr 16) and $FFFFFFFF));
  end
  else
    Result := Integer(Cardinal((X shr 16) and $FFFFFFFF));
end;

class function TFixedMath.Mul64(const A, B: Int64): Int64;
var
  LProduct: Int64;
  LQuotient: Int64;
  LRemainder: Int64;
begin
  if (A > -$80000000) and (A < $80000000) and (B > -$80000000) and (B < $80000000) then
  begin
    // The old code computed Round(a / 65536 * b) with the 64 bits of mantissa of the 32 bit FPU,
    // which hold the product (at most 62 bits) exactly: the result is the exact product divided
    // by 65536 and rounded to the nearest even. With Double (53 bits) it would be another number
    LProduct := A * B;
    LQuotient := LProduct div FIXED_ONE;
    LRemainder := Abs(LProduct - LQuotient * FIXED_ONE);
    if (LRemainder > FIXED_ONE div 2) or ((LRemainder = FIXED_ONE div 2) and Odd(LQuotient)) then
    begin
      if LProduct < 0 then
        Dec(LQuotient)
      else
        Inc(LQuotient);
    end;
    Result := LQuotient;
  end
  else
    Result := WideMul64(A, B);
end;

class function TFixedMath.ExtendedQuotient(const A, B: Double): Double;
{$IF SizeOf(Extended) > SizeOf(Double)}
begin
  Result := Extended(A) / Extended(B);
end;
{$ELSE}
const
  // 2^27 + 1: Dekker's split of a Double in two halves
  SPLITTER = 134217729.0;
var
  LNumerator: Double;
  LDenominator: Double;
  LQuotient: Double;
  LProduct: Double;
  LError: Double;
  LRemainder: Double;
  LSplit: Double;
  LQuotientHigh, LQuotientLow, LDenominatorHigh, LDenominatorLow: Double;
  LMantissa: Double;
  LExponent: Integer;
  LUnit: Double;
  LDelta: Double;
begin
  Result := A / B;
  if (A = 0) or IsNan(Result) or IsInfinite(Result) or (Abs(Result) < 1E-290) then
    Exit;
  LNumerator := Abs(A);
  LDenominator := Abs(B);
  LQuotient := Abs(Result);

  // the exact remainder of the numerator less quotient * denominator (the product has up to 106 bits)
  LProduct := LQuotient * LDenominator;
  LSplit := SPLITTER * LQuotient;
  LQuotientHigh := LSplit - (LSplit - LQuotient);
  LQuotientLow := LQuotient - LQuotientHigh;
  LSplit := SPLITTER * LDenominator;
  LDenominatorHigh := LSplit - (LSplit - LDenominator);
  LDenominatorLow := LDenominator - LDenominatorHigh;
  LError := ((LQuotientHigh * LDenominatorHigh - LProduct) + LQuotientHigh * LDenominatorLow +
    LQuotientLow * LDenominatorHigh) + LQuotientLow * LDenominatorLow;
  LRemainder := (LNumerator - LProduct) - LError;

  // the exact quotient is LQuotient + LDelta. With 64 bits of mantissa it is first rounded to a multiple of
  // a 2048th of the unit of the last place: when that gives the middle between two Doubles, the second
  // rounding goes to the one with an even mantissa
  LDelta := LRemainder / LDenominator;
  Frexp(LQuotient, LMantissa, LExponent);
  LUnit := Ldexp(1.0, LExponent - 53);
  Result := LQuotient;
  if Abs(LDelta) >= LUnit / 2 - LUnit / 4096 then
    if Odd(Trunc(LQuotient / LUnit)) then
    begin
      if LDelta > 0 then
        Result := LQuotient + LUnit
      else
        Result := LQuotient - LUnit;
    end;
  if (A < 0) <> (B < 0) then
    Result := -Result;
end;
{$IFEND}

class function TFixedMath.FloatDivide(const A, B: Double): Double;
var
  LA: Double;
  LB: Double;
begin
  if B = 0 then
  begin
    if A < 0 then
      Result := FIXED_MIN
    else
      Result := FIXED_MAX;
  end
  else
  begin
    LA := A / FIXED_ONE;
    LB := B / FIXED_ONE;
    Result := ExtendedQuotient(LA, LB) * FIXED_ONE;
  end;
end;

class function TFixedMath.FloatMul(const A, B: Double): Double;
begin
  Result := A / FIXED_ONE * B;
end;

class function TFixedMath.Modulo(const A, B: TFixed): TFixed;
begin
  if (B and (B - 1)) <> 0 then
  begin
    Result := A mod B;
    if Result < 0 then
      Result := Result + B;
  end
  else
    Result := A and (B - 1);
end;

end.
