{******************************************************************************}
{                                                                              }
{  DelphiDoom: clock library - the source on the counters of the system         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Clock.PerformanceSource;

interface

uses
  DelphiDoom.Clock.Intf;

type
  /// <summary>
  ///   The high resolution counter; if it fails (or there is no such counter) it goes on with
  ///   the milliseconds at 1000 steps per second, and the frequency it reports changes with it
  /// </summary>
  TPerformanceClockSource = class(TInterfacedObject, IClockSource)
  strict private
    FCounters: IClockCounters;
    FFrequency: Int64;
  public
    /// <summary>ACounters are the counters of the system (a fake one, in the tests)</summary>
    constructor Create(const ACounters: IClockCounters);
    function GetFrequency: Int64;
    function Read: Int64;
    procedure Sleep(AMilliseconds: Integer);
  end;

implementation

uses
  System.SysUtils;

const
  // The steps of the counter of the milliseconds in a second
  TICK_FREQUENCY = 1000;

{ TPerformanceClockSource }

constructor TPerformanceClockSource.Create(const ACounters: IClockCounters);
begin
  inherited Create;
  if not Assigned(ACounters) then
    raise EArgumentNilException.Create('ACounters');
  FCounters := ACounters;
  if not FCounters.QueryFrequency(FFrequency) then
    FFrequency := TICK_FREQUENCY;
end;

function TPerformanceClockSource.GetFrequency: Int64;
begin
  Result := FFrequency;
end;

function TPerformanceClockSource.Read: Int64;
begin
  if FFrequency = TICK_FREQUENCY then
    Result := FCounters.TickCount
  else if not FCounters.QueryCounter(Result) then
  begin
    FFrequency := TICK_FREQUENCY;
    Result := FCounters.TickCount;
  end;
end;

procedure TPerformanceClockSource.Sleep(AMilliseconds: Integer);
begin
  FCounters.Sleep(AMilliseconds);
end;

end.
