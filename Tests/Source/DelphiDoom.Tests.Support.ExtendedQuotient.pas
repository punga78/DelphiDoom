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
  DelphiDoom.MathCore.FixedMath;


{ TExtendedQuotient }

class function TExtendedQuotient.Divide(ANumerator: Integer; const ADenominator: Double): Double;
begin
  Result := TFixedMath.ExtendedQuotient(ANumerator, ADenominator);
end;

end.
