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
  System.SysUtils;

type
  /// <summary>The conversions of printf that the messages and the dumps of the library use</summary>
  TBotCFormat = class
  public
    /// <summary>"%f": six decimals, with a point (a float is promoted to a double by the caller)</summary>
    class function Fixed6(const AValue: Double): AnsiString; static;
    /// <summary>"%d"</summary>
    class function Int(const AValue: Integer): AnsiString; static;
  end;

implementation

{ TBotCFormat }

class function TBotCFormat.Fixed6(const AValue: Double): AnsiString;
begin
  // 18 digits: enough to round the exact decimal expansion of a double correctly at six decimals
  Result := AnsiString(FloatToStrF(AValue, ffFixed, 18, 6, TFormatSettings.Invariant));
  // printf keeps the sign of a negative number that rounds to zero ("-0.000000")
  if (PInt64(@AValue)^ < 0) and (Copy(Result, 1, 1) <> '-') then
    Result := '-' + Result;
end;

class function TBotCFormat.Int(const AValue: Integer): AnsiString;
begin
  Result := AnsiString(IntToStr(AValue));
end;

end.
