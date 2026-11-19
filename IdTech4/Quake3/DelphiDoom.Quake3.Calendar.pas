{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III program - the calendar of the game                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Quake3.Calendar;

interface

uses
  DelphiDoom.Q3Host.Services.Intf;

type
  /// <summary>
  ///   G_REALTIME of the game: the local time of the computer as a struct tm (years from 1900, months from 0,
  ///   Sunday 0) and time( NULL ), the seconds from 1970
  /// </summary>
  TQ3SystemCalendar = class(TInterfacedObject, IQ3HostCalendar)
  public
    /// <summary>The same decoding for any moment (the tests ask for a known one)</summary>
    class function Decode(AMoment: TDateTime; out ATime: TQ3HostRealTime): Integer; static;
    function RealTime(out ATime: TQ3HostRealTime): Integer;
  end;

implementation

uses
  System.SysUtils, System.DateUtils;

{ TQ3SystemCalendar }

class function TQ3SystemCalendar.Decode(AMoment: TDateTime; out ATime: TQ3HostRealTime): Integer;
var
  LYear, LMonth, LDay, LHour, LMinute, LSecond, LMilli: Word;
begin
  DecodeDateTime(AMoment, LYear, LMonth, LDay, LHour, LMinute, LSecond, LMilli);
  ATime.Second := LSecond;
  ATime.Minute := LMinute;
  ATime.Hour := LHour;
  ATime.DayOfMonth := LDay;
  ATime.Month := LMonth - 1;
  ATime.Year := LYear - 1900;
  // DayOfWeek: Sunday is 1
  ATime.DayOfWeek := DayOfWeek(AMoment) - 1;
  ATime.DayOfYear := DayOfTheYear(AMoment) - 1;
  ATime.IsDst := 0;
  Result := Integer(DateTimeToUnix(AMoment, False));
end;

function TQ3SystemCalendar.RealTime(out ATime: TQ3HostRealTime): Integer;
begin
  Result := Decode(Now, ATime);
end;

end.
