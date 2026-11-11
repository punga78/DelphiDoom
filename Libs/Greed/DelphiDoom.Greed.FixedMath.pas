{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the fixed point functions of the original        }
{  Port of xGreed (Jim Valavanis, GPL v2 or later), r_public.pas and g_delphi.pas }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.FixedMath;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.MathCore.FixedMath;

type
  /// <summary>
  ///   FIXEDMUL, FIXEDMUL1, FIXEDADD, FIXEDMUL64, FIXEDDIV and the shifts of xGreed in pure Pascal (the
  ///   original FIXEDMUL, FIXEDDIV2, _SHL and _SHR are asm). The arithmetic is the one of Libs\MathCore
  ///   (TFixedMath); the wraparound is wanted, as in the original, so range and overflow checks are off.
  /// </summary>
  TGreedFixedMath = class
  public
    /// <summary>FIXEDMUL: (a * b) shr 16 on 64 bits, low 32 bits (the original is imul and shrd)</summary>
    class function Mul(const A, B: TFixed): TFixed; static; inline;
    /// <summary>FIXEDMUL1: Round(a / 65536 * b), halves to even, saturated to the 32 bit range</summary>
    class function MulSaturated(const A, B: TFixed): TFixed; static;
    /// <summary>FIXEDADD: the sum saturated to the 32 bit range</summary>
    class function AddSaturated(const A, B: TFixed): TFixed; static;
    /// <summary>
    ///   FIXEDMUL64: Round(a / 65536 * b) on 64 bits. When the product fits in 64 bits it is exact (the same
    ///   as the Extended of the original, whose mantissa has 64 bits); beyond, the floating point of the original
    /// </summary>
    class function Mul64(const A, B: Int64): Int64; static;
    /// <summary>FIXEDDIV: a / b in 16.16, saturated when the quotient does not fit; a zero divisor raises</summary>
    class function Divide(const A, B: TFixed): TFixed; static;
    /// <summary>_SHL (arithmetic left shift, count taken modulo 32 as the processor does)</summary>
    class function ShiftLeft(const AValue, ABits: Integer): Integer; static; inline;
    /// <summary>_SHR (arithmetic right shift, count taken modulo 32 as the processor does)</summary>
    class function ShiftRight(const AValue, ABits: Integer): Integer; static; inline;
  end;

implementation

{ TGreedFixedMath }

class function TGreedFixedMath.Mul(const A, B: TFixed): TFixed;
begin
  Result := TFixedMath.Mul(A, B);
end;

class function TGreedFixedMath.MulSaturated(const A, B: TFixed): TFixed;
var
  LValue: Int64;
begin
  // |a * b| < 2^62: the Int64 product is exact, as the 64 bit mantissa of the original
  LValue := TFixedMath.RoundDivide(Int64(A) * B, FIXED_ONE);
  if LValue > High(Integer) then
    Result := High(Integer)
  else if LValue < Low(Integer) then
    Result := Low(Integer)
  else
    Result := Integer(LValue);
end;

class function TGreedFixedMath.AddSaturated(const A, B: TFixed): TFixed;
var
  LValue: Int64;
begin
  LValue := Int64(A) + B;
  if LValue > High(Integer) then
    Result := High(Integer)
  else if LValue < Low(Integer) then
    Result := Low(Integer)
  else
    Result := Integer(LValue);
end;

class function TGreedFixedMath.Mul64(const A, B: Int64): Int64;
var
  LAbsA: UInt64;
  LAbsB: UInt64;
begin
  if A < 0 then
    LAbsA := UInt64(-A)
  else
    LAbsA := UInt64(A);
  if B < 0 then
    LAbsB := UInt64(-B)
  else
    LAbsB := UInt64(B);
  if (LAbsA = 0) or (LAbsB = 0) then
    Result := 0
  else if (A <> Low(Int64)) and (B <> Low(Int64)) and (LAbsA <= UInt64(High(Int64)) div LAbsB) then
    Result := TFixedMath.RoundDivide(A * B, FIXED_ONE)
  else
    Result := TFixedMath.Mul64(A, B);
end;

class function TGreedFixedMath.Divide(const A, B: TFixed): TFixed;
begin
  // the guard is the original one: the absolute value of the smallest integer stays negative and the shr is
  // logical (TFixedMath.Divide shifts it arithmetically, so it would differ for that value)
  if Integer(Cardinal(TFixedMath.AbsWrap(A)) shr 14) >= TFixedMath.AbsWrap(B) then
  begin
    if (A xor B) < 0 then
      Result := FIXED_MIN
    else
      Result := FIXED_MAX;
  end
  else
    Result := TFixedMath.DivideRaw(A, B);
end;

class function TGreedFixedMath.ShiftLeft(const AValue, ABits: Integer): Integer;
begin
  Result := AValue shl (ABits and 31);
end;

class function TGreedFixedMath.ShiftRight(const AValue, ABits: Integer): Integer;
begin
  Result := TFixedMath.ShiftRight(AValue, ABits and 31);
end;

end.
