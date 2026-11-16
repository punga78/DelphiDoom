{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the texts of the times and of the positions    }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of speed_string_format.pas (GLSpeed).                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.TextFormat;

interface

type
  /// <summary>
  ///   How the race writes a distance, a time and a position (the HUD, the intermission and the
  ///   tables of the times use them); without state
  /// </summary>
  TRacingTextFormat = class
  public
    /// <summary>
    ///   A distance in meters as kilometers with three decimals and "km": 1234 is 1.234km, 5 is
    ///   0.005km (the old SH_Meters2KM)
    /// </summary>
    class function MetersToKilometers(AMeters: Integer): string; static;
    /// <summary>
    ///   A time in tics as mm'ss"cc (minutes, seconds and hundredths), with the hours in front when
    ///   there are any: h'mm'ss"cc (the old SH_TicsToTimeStr)
    /// </summary>
    class function TicsToTime(ATics: Integer): string; static;
    /// <summary>
    ///   1st, 2nd, 3rd, 4th ... up to the number of cars of a race; "-" for any other number (the
    ///   old SH_FmtRacePostion)
    /// </summary>
    class function RacePosition(APosition: Integer): string; static;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Racing.Types;

const
  KILOMETER_DECIMALS = 3;
  KILOMETER_SUFFIX = 'km';
  ORDINAL_SUFFIXES: array[1..3] of string = ('st', 'nd', 'rd');
  ORDINAL_SUFFIX = 'th';
  NO_POSITION = '-';

{ TRacingTextFormat }

class function TRacingTextFormat.MetersToKilometers(AMeters: Integer): string;
var
  LDigits: string;
  LIndex: Integer;
begin
  LDigits := IntToStr(AMeters);
  Result := '';
  for LIndex := Length(LDigits) downto 1 do
  begin
    Result := LDigits[LIndex] + Result;
    if Length(Result) = KILOMETER_DECIMALS then
      Result := '.' + Result;
  end;
  if Pos('.', Result) = 1 then
    Result := '0' + Result
  else if Pos('.', Result) = 0 then
  begin
    while Length(Result) < KILOMETER_DECIMALS do
      Result := '0' + Result;
    Result := '0.' + Result;
  end;
  Result := Result + KILOMETER_SUFFIX;
end;

class function TRacingTextFormat.TicsToTime(ATics: Integer): string;
var
  LRest: Integer;
  LHundredths: Integer;
  LSeconds: Integer;
  LMinutes: Integer;
begin
  LRest := ATics * 100 div RACING_TICKS_PER_SECOND;
  LHundredths := LRest mod 100;
  LRest := (LRest - LHundredths) div 100;
  LSeconds := LRest mod 60;
  LRest := LRest div 60;
  LMinutes := LRest mod 60;
  LRest := LRest div 60;
  Result := Format('%.2d''%.2d"%.2d', [LMinutes, LSeconds, LHundredths]);
  if LRest <> 0 then
    Result := IntToStr(LRest) + '''' + Result;
end;

class function TRacingTextFormat.RacePosition(APosition: Integer): string;
begin
  if (APosition >= Low(ORDINAL_SUFFIXES)) and (APosition <= High(ORDINAL_SUFFIXES)) then
    Result := IntToStr(APosition) + ORDINAL_SUFFIXES[APosition]
  else if (APosition > High(ORDINAL_SUFFIXES)) and (APosition <= RACING_MAX_CARS) then
    Result := IntToStr(APosition) + ORDINAL_SUFFIX
  else
    Result := NO_POSITION;
end;

end.
