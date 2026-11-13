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
    /// <summary>Round(a / 65536 * b) in floating point on 64 bits (the old FixedMul64)</summary>
    class function Mul64(const A, B: Int64): Int64; static;
    class function FloatDivide(const A, B: Double): Double; static;
    class function FloatMul(const A, B: Double): Double; static;
    /// <summary>a mod b guaranteed to be in 0..b-1 (the old FixedMod)</summary>
    class function Modulo(const A, B: TFixed): TFixed; static;
  end;

implementation

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
    LValue := (A / B) * FIXED_ONE;
    if LValue < FIXED_MIN + 1 then
      Result := FIXED_MIN
    else if LValue > FIXED_MAX - 1 then
      Result := FIXED_MAX
    else
    begin
      // http://stereopsis.com/sree/fpu2006.html - fast round of a double
      LValue := LValue + 6755399441055744.0;
      Move(LValue, LBits, SizeOf(LBits));
      Result := Integer(LBits);
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
  if (Abs(A) < $80000000) and (Abs(B) < $80000000) then
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
    Result := Round(A / FIXED_ONE * B);
end;

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
    Result := (LA / LB) * FIXED_ONE;
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
