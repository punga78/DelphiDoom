{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the numbers of printf                              }
{                                                                              }
{  Port of war1 (acoto87/war1), the use of SDL_snprintf in                      }
{  war_state_machine_debug.c ("%.1f", "%-10s"), (c) 2019 Alejandro Coto        }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered  }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Text.CFormat;

{$R-}
{$Q-}

interface

type
  /// <summary>
  ///   What the text of the debug of the state machine needs of printf: a number with one decimal (the same as SDL_snprintf of the real SDL3, which is the C library: 200000 values; an exact half goes to the even decimal) and a text padded to the right
  /// </summary>
  TWarCFormat = class
  public
    /// <summary>"%.1f"</summary>
    class function Fixed1(AValue: Double): AnsiString; static;
    /// <summary>"%-*s": the text padded with spaces to the right up to AWidth characters</summary>
    class function PadRight(const AText: AnsiString; AWidth: Integer): AnsiString; static;
  end;

implementation

uses
  System.SysUtils, System.Math;

{ TWarCFormat }

class function TWarCFormat.Fixed1(AValue: Double): AnsiString;
var
  LBits: UInt64;
  LExponent: Integer;
  LMantissa: UInt64;
  LShift: Integer;
  LTenths: UInt64;
  LRemainder: UInt64;
  LHalf: UInt64;
  LNegative: Boolean;
begin
  if IsNan(AValue) then
    Exit('nan');
  if IsInfinite(AValue) then
  begin
    if AValue > 0 then
      Exit('inf');
    Exit('-inf');
  end;
  // the exact value of the double is mantissa * 2^exponent: the tenths are rounded with integers (an exact half goes to the
  // even tenth, as printf does), so the same text comes out at 32 and 64 bit (FloatToStrF does not: it rounds a decimal
  // of 15 digits on Win64)
  LBits := PUInt64(@AValue)^;
  LNegative := (LBits shr 63) <> 0;
  LExponent := Integer((LBits shr 52) and $7FF);
  LMantissa := LBits and $000FFFFFFFFFFFFF;
  if LExponent = 0 then
    LExponent := -1074
  else
  begin
    LMantissa := LMantissa or (UInt64(1) shl 52);
    LExponent := LExponent - 1075;
  end;
  LMantissa := LMantissa * 10;
  if LExponent >= 0 then
  begin
    // 2^6 times the mantissa of 57 bits would overflow: so big a number is written by the library
    if LExponent > 6 then
      Exit(AnsiString(FloatToStrF(AValue, ffFixed, 18, 1, TFormatSettings.Invariant)));
    LTenths := LMantissa shl LExponent;
  end
  else
  begin
    LShift := -LExponent;
    if LShift >= 58 then
      LTenths := 0
    else
    begin
      LTenths := LMantissa shr LShift;
      LRemainder := LMantissa and ((UInt64(1) shl LShift) - 1);
      LHalf := UInt64(1) shl (LShift - 1);
      if (LRemainder > LHalf) or ((LRemainder = LHalf) and Odd(LTenths)) then
        Inc(LTenths);
    end;
  end;
  Result := AnsiString(UIntToStr(LTenths div 10) + '.' + UIntToStr(LTenths mod 10));
  if LNegative then
    Result := '-' + Result;
end;
class function TWarCFormat.PadRight(const AText: AnsiString; AWidth: Integer): AnsiString;
begin
  Result := AText;
  while Length(Result) < AWidth do
    Result := Result + ' ';
end;

end.
