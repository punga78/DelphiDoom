{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the printf of the messages of be_aas_reach.c      }
{                                                                              }
{  The messages print floats with %f, %1.0f, %1.1f and %6.1f: printf rounds    }
{  the exact value of the double and takes the even digit on a tie, which      }
{  Format of Delphi does not. Based on the Quake III Arena GPL Source Code     }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is       }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Format;

interface

type
  /// <summary>printf("%.Nf") of a double</summary>
  TAasReachFormat = class sealed
  public
    /// <summary>The value with ADecimals decimals (at most 6), rounded as printf does, padded on the left to AWidth</summary>
    class function Fixed(const AValue: Double; const ADecimals: Integer; const AWidth: Integer = 0): string; static;
  end;

implementation

uses
  System.SysUtils;

{ TAasReachFormat }

class function TAasReachFormat.Fixed(const AValue: Double; const ADecimals, AWidth: Integer): string;
var
  LText, LDigits, LRest: string;
  LPoint, LIndex, LCarry, LDigit: Integer;
  LNegative, LRoundUp: Boolean;
begin
  // the exact decimals of the double (a float has at most 24 bits, so 12 decimals are enough to see a tie)
  LText := Format('%.12f', [Abs(AValue)], TFormatSettings.Invariant);
  LNegative := AValue < 0;
  LPoint := Pos('.', LText);
  LDigits := Copy(LText, 1, LPoint - 1) + Copy(LText, LPoint + 1, ADecimals);
  LRest := Copy(LText, LPoint + 1 + ADecimals, 12);
  LRoundUp := False;
  if LRest <> '' then
  begin
    if LRest[1] > '5' then
      LRoundUp := True
    else if LRest[1] = '5' then
    begin
      if Copy(LRest, 2, 12) <> StringOfChar('0', Length(LRest) - 1) then
        LRoundUp := True
      else
        // a tie: the even digit
        LRoundUp := (Ord(LDigits[Length(LDigits)]) - Ord('0')) mod 2 = 1;
    end;
  end;
  if LRoundUp then
  begin
    LCarry := 1;
    LIndex := Length(LDigits);
    while (LIndex >= 1) and (LCarry > 0) do
    begin
      LDigit := Ord(LDigits[LIndex]) - Ord('0') + LCarry;
      if LDigit >= 10 then
      begin
        LDigit := LDigit - 10;
        LCarry := 1;
      end
      else
        LCarry := 0;
      LDigits[LIndex] := Chr(Ord('0') + LDigit);
      Dec(LIndex);
    end;
    if LCarry > 0 then
      LDigits := '1' + LDigits;
  end;
  if ADecimals > 0 then
    Result := Copy(LDigits, 1, Length(LDigits) - ADecimals) + '.' + Copy(LDigits, Length(LDigits) - ADecimals + 1, ADecimals)
  else
    Result := LDigits;
  if LNegative then
    Result := '-' + Result;
  if Length(Result) < AWidth then
    Result := StringOfChar(' ', AWidth - Length(Result)) + Result;
end;

end.
