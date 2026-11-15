{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotCFormat, the number formats of printf              }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software), botlib.         }
{  Licensed under the GNU General Public License, version 2 or later.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Text.CFormat;

interface

uses
  System.SysUtils, System.Math;

type
  /// <summary>The conversions of printf that the messages and the dumps of the library use</summary>
  TBotCFormat = class
  public
    /// <summary>"%f": six decimals, with a point (a float is promoted to a double by the caller)</summary>
    class function Fixed6(const AValue: Double): AnsiString; static;
    /// <summary>
    ///   "%1.1f": one decimal. A value exactly half way between two decimals (x.25, x.75) is rounded to the even
    ///   decimal, as printf does with the exact value of the double (the decimal text of Delphi rounds up).
    /// </summary>
    class function Fixed1(const AValue: Double): AnsiString; static;
    /// <summary>"%d"</summary>
    class function Int(const AValue: Integer): AnsiString; static;
  end;

implementation

{ TBotCFormat }

class function TBotCFormat.Fixed6(const AValue: Double): AnsiString;
begin
  // the runtime of the tool that made the golden files writes these as "nan", "inf" and "-inf"
  if IsNan(AValue) then
    Exit('nan');
  if IsInfinite(AValue) then
  begin
    if AValue > 0 then
      Exit('inf');
    Exit('-inf');
  end;
  // 18 digits: enough to round the exact decimal expansion of a double correctly at six decimals
  Result := AnsiString(FloatToStrF(AValue, ffFixed, 18, 6, TFormatSettings.Invariant));
  // printf keeps the sign of a negative number that rounds to zero ("-0.000000")
  if (PInt64(@AValue)^ < 0) and (Copy(Result, 1, 1) <> '-') then
    Result := '-' + Result;
end;

class function TBotCFormat.Fixed1(const AValue: Double): AnsiString;
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
  if (PInt64(@AValue)^ < 0) and (Copy(Result, 1, 1) <> '-') then
    Result := '-' + Result;
end;

class function TBotCFormat.Int(const AValue: Integer): AnsiString;
begin
  Result := AnsiString(IntToStr(AValue));
end;

end.
