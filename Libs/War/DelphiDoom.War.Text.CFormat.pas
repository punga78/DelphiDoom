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
  ///   What the text of the debug of the state machine needs of printf: a number with one decimal (proved equal to
  ///   SDL_snprintf of the real SDL3 on 200000 values: an exact half goes to the even decimal) and a text padded to the right
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
  LQuarters: Double;
  LTenths: Double;
  LLow: Double;
begin
  if IsNan(AValue) then
    Exit('nan');
  if IsInfinite(AValue) then
  begin
    if AValue > 0 then
      Exit('inf');
    Exit('-inf');
  end;
  LQuarters := Abs(AValue) * 4;
  if (LQuarters < 4.0E15) and (Frac(LQuarters) = 0) and Odd(Trunc(LQuarters)) then
  begin
    // exactly half way (0.25, 0.75, 1.25 ...): to the even decimal
    LTenths := Abs(AValue) * 10;
    LLow := Floor(LTenths);
    if Odd(Trunc(LLow)) then
      LLow := LLow + 1;
    Result := AnsiString(FloatToStrF(LLow / 10, ffFixed, 18, 1, TFormatSettings.Invariant));
    if AValue < 0 then
      Result := '-' + Result;
    Exit;
  end;
  Result := AnsiString(FloatToStrF(AValue, ffFixed, 18, 1, TFormatSettings.Invariant));
  // printf keeps the sign of a negative number that rounds to zero
  if (PInt64(@AValue)^ < 0) and (Copy(Result, 1, 1) <> '-') then
    Result := '-' + Result;
end;

class function TWarCFormat.PadRight(const AText: AnsiString; AWidth: Integer): AnsiString;
begin
  Result := AText;
  while Length(Result) < AWidth do
    Result := Result + ' ';
end;

end.
