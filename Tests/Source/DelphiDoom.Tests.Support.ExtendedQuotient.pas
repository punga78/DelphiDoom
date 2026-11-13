{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests - the quotient of the 32 bit FPU at 32 and 64 bit         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Support.ExtendedQuotient;

interface

type
  /// <summary>
  ///   The data of some tests were made (and their golden files too) with the 32 bit compiler, that
  ///   divides an integer by a Double in Extended and rounds the result to Double: two roundings, which
  ///   give a number one bit away from the correctly rounded quotient once in a thousand. The 64 bit
  ///   compiler has no Extended and rounds once. This class gives the 32 bit number on both
  /// </summary>
  TExtendedQuotient = class
  public
    /// <summary>Double(Extended(ANumerator) / Extended(ADenominator)), as the 32 bit compiler computes it</summary>
    class function Divide(ANumerator: Integer; const ADenominator: Double): Double; static;
  end;

implementation

uses
  System.Math;

{ TExtendedQuotient }

class function TExtendedQuotient.Divide(ANumerator: Integer; const ADenominator: Double): Double;
{$IF SizeOf(Extended) > SizeOf(Double)}
begin
  Result := Extended(ANumerator) / Extended(ADenominator);
end;
{$ELSE}
const
  // 2^27 + 1: Dekker's split of a Double in two halves
  SPLITTER = 134217729.0;
var
  LNumerator: Double;
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
  if ANumerator = 0 then
    Exit(0.0);
  LNumerator := Abs(ANumerator);
  LQuotient := LNumerator / ADenominator;

  // the exact remainder of the numerator less quotient * denominator (the product has up to 106 bits)
  LProduct := LQuotient * ADenominator;
  LSplit := SPLITTER * LQuotient;
  LQuotientHigh := LSplit - (LSplit - LQuotient);
  LQuotientLow := LQuotient - LQuotientHigh;
  LSplit := SPLITTER * ADenominator;
  LDenominatorHigh := LSplit - (LSplit - ADenominator);
  LDenominatorLow := ADenominator - LDenominatorHigh;
  LError := ((LQuotientHigh * LDenominatorHigh - LProduct) + LQuotientHigh * LDenominatorLow +
    LQuotientLow * LDenominatorHigh) + LQuotientLow * LDenominatorLow;
  LRemainder := (LNumerator - LProduct) - LError;

  // the exact quotient is LQuotient + LDelta. With 64 bits of mantissa it is first rounded to a multiple of
  // a 2048th of the unit of the last place: when that gives the middle between two Doubles, the second
  // rounding goes to the one with an even mantissa
  LDelta := LRemainder / ADenominator;
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
  if ANumerator < 0 then
    Result := -Result;
end;
{$IFEND}

end.
