{******************************************************************************}
{                                                                              }
{  DelphiDoom: clock library - the factory: the composition root                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Clock.Factory;

interface

uses
  DelphiDoom.Clock.Intf, DelphiDoom.Logging.Intf;

type
  /// <summary>The only place that knows the classes behind IClock</summary>
  TClockFactory = class
  public
    /// <summary>The clock of the program, on the counters of Windows; ALog may be nil</summary>
    class function CreateClock(const ALog: ILog): IClock; overload; static;
    /// <summary>A clock on any source (a fake one, in the tests)</summary>
    class function CreateClock(const ASource: IClockSource; const ALog: ILog): IClock; overload; static;
    /// <summary>Asks Windows for a timer of AMilliseconds; it is given back when the result is released</summary>
    class function AcquireTimerResolution(AMilliseconds: Integer): ITimerResolutionLease; overload; static;
    /// <summary>The same on any system (a fake one, in the tests)</summary>
    class function AcquireTimerResolution(const ASystem: ITimerResolutionSystem;
      AMilliseconds: Integer): ITimerResolutionLease; overload; static;
  end;

implementation

uses
  DelphiDoom.Clock.Clock, DelphiDoom.Clock.PerformanceSource, DelphiDoom.Clock.WindowsCounters,
  DelphiDoom.Clock.TimerResolution, DelphiDoom.Clock.WindowsTimerResolution;

{ TClockFactory }

class function TClockFactory.CreateClock(const ALog: ILog): IClock;
begin
  Result := TClock.Create(TPerformanceClockSource.Create(TWindowsClockCounters.Create), ALog);
end;

class function TClockFactory.CreateClock(const ASource: IClockSource; const ALog: ILog): IClock;
begin
  Result := TClock.Create(ASource, ALog);
end;

class function TClockFactory.AcquireTimerResolution(AMilliseconds: Integer): ITimerResolutionLease;
begin
  Result := TTimerResolutionLease.Create(TWindowsTimerResolutionSystem.Create, AMilliseconds);
end;

class function TClockFactory.AcquireTimerResolution(const ASystem: ITimerResolutionSystem;
  AMilliseconds: Integer): ITimerResolutionLease;
begin
  Result := TTimerResolutionLease.Create(ASystem, AMilliseconds);
end;

end.
