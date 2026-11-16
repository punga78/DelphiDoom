{******************************************************************************}
{                                                                              }
{  DelphiDoom: heads-up display library - the time of the level                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Hud.LevelTime;

interface

type
  /// <summary>The time of the level as the automap shows it</summary>
  THudLevelTime = class sealed
  public
    /// <summary>"Time: HH:MM:SS" for the given tics from the start of the level</summary>
    class function Format(const ALevelTime, ATicRate: Integer): string; static;
  end;

implementation

uses
  System.SysUtils;

function TwoDigits(const AValue: Integer): string;
begin
  Result := IntToStr(AValue);
  while Length(Result) < 2 do
    Result := '0' + Result;
end;

{ THudLevelTime }

class function THudLevelTime.Format(const ALevelTime, ATicRate: Integer): string;
var
  LValue: Integer;
  LSeconds: string;
  LMinutes: string;
begin
  LValue := ALevelTime div ATicRate;
  LSeconds := TwoDigits(LValue mod 60);
  LValue := LValue div 60;
  LMinutes := TwoDigits(LValue mod 60);
  LValue := LValue div 60;
  Result := 'Time: ' + TwoDigits(LValue) + ':' + LMinutes + ':' + LSeconds;
end;

end.
