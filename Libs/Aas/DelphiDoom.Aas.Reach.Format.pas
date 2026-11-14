{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the printf of the messages of be_aas_reach.c      }
{                                                                              }
{  The messages print floats with %f, %1.0f, %1.1f and %6.1f: printf rounds    }
{  the exact value of the double and takes the even digit on a tie, which      }
{  Format of Delphi does not (and on Win64 it has 17 digits only). The digits  }
{  come from the integer mantissa. Based on the Quake III Arena GPL Source     }
{  Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is  }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Format;

{$Q-}
{$R-}

interface

type
  /// <summary>printf("%.Nf") of a double</summary>
  TAasReachFormat = class sealed
  public
    /// <summary>The value with ADecimals decimals (at most 9), rounded as printf does, padded on the left to AWidth</summary>
    class function Fixed(const AValue: Double; const ADecimals: Integer; const AWidth: Integer = 0): string; static;
  end;

implementation

uses
  System.SysUtils;

{ TAasReachFormat }

class function TAasReachFormat.Fixed(const AValue: Double; const ADecimals, AWidth: Integer): string;
var
  LBits, LMantissa, LInteger, LFraction, LOne, LRemainder: UInt64;
  LExponent, LShift, LIndex: Integer;
  LNegative, LRoundUp: Boolean;
  LDigits: string;
  LDigit: Integer;
begin
  LBits := PUInt64(@AValue)^;
  LNegative := (LBits shr 63) <> 0;
  LExponent := Integer((LBits shr 52) and $7FF);
  LMantissa := LBits and ((UInt64(1) shl 52) - 1);
  if LExponent <> 0 then
    LMantissa := LMantissa or (UInt64(1) shl 52)
  else
    LExponent := 1;
  // the value is the mantissa times 2^(exponent - 1075)
  LShift := 1075 - LExponent;
  if (LExponent = $7FF) or (LShift < 0) or (LShift > 60) then
  begin
    // out of the range of the integer arithmetic: infinity, not a number, huge or tiny values
    Result := Format('%.*f', [ADecimals, AValue], TFormatSettings.Invariant);
    if Length(Result) < AWidth then
      Result := StringOfChar(' ', AWidth - Length(Result)) + Result;
    Exit;
  end;
  LInteger := LMantissa shr LShift;
  LOne := UInt64(1) shl LShift;
  LFraction := LMantissa and (LOne - 1);
  LDigits := UIntToStr(LInteger);
  for LIndex := 1 to ADecimals do
  begin
    LFraction := LFraction * 10;
    LDigit := Integer(LFraction shr LShift);
    LFraction := LFraction and (LOne - 1);
    LDigits := LDigits + Chr(Ord('0') + LDigit);
  end;
  // what is left is compared with one half: the tie goes to the even digit
  LRemainder := LFraction;
  LRoundUp := (LRemainder > (LOne shr 1)) or ((LRemainder = (LOne shr 1)) and (LShift > 0) and
    (((Ord(LDigits[Length(LDigits)]) - Ord('0')) and 1) = 1));
  if LRoundUp then
  begin
    LIndex := Length(LDigits);
    while LIndex >= 1 do
    begin
      if LDigits[LIndex] = '9' then
      begin
        LDigits[LIndex] := '0';
        Dec(LIndex);
      end
      else
      begin
        LDigits[LIndex] := Chr(Ord(LDigits[LIndex]) + 1);
        Break;
      end;
    end;
    if LIndex < 1 then
      LDigits := '1' + LDigits;
  end;
  if ADecimals > 0 then
    Result := Copy(LDigits, 1, Length(LDigits) - ADecimals) + '.' + Copy(LDigits, Length(LDigits) - ADecimals + 1,
      ADecimals)
  else
    Result := LDigits;
  if LNegative then
    Result := '-' + Result;
  if Length(Result) < AWidth then
    Result := StringOfChar(' ', AWidth - Length(Result)) + Result;
end;

end.
