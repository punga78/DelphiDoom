{******************************************************************************}
{                                                                              }
{  DelphiDoom: clock library - the counters of Windows                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Clock.WindowsCounters;

interface

uses
  DelphiDoom.Clock.Intf;

type
  /// <summary>QueryPerformanceFrequency, QueryPerformanceCounter, GetTickCount and Sleep</summary>
  TWindowsClockCounters = class(TInterfacedObject, IClockCounters)
  public
    function QueryFrequency(out AFrequency: Int64): Boolean;
    function QueryCounter(out ACounter: Int64): Boolean;
    function TickCount: Cardinal;
    procedure Sleep(AMilliseconds: Integer);
  end;

implementation

uses
  Winapi.Windows;

{ TWindowsClockCounters }

function TWindowsClockCounters.QueryFrequency(out AFrequency: Int64): Boolean;
begin
  AFrequency := 0;
  Result := QueryPerformanceFrequency(AFrequency);
end;

function TWindowsClockCounters.QueryCounter(out ACounter: Int64): Boolean;
begin
  ACounter := 0;
  Result := QueryPerformanceCounter(ACounter);
end;

function TWindowsClockCounters.TickCount: Cardinal;
begin
  Result := GetTickCount;
end;

procedure TWindowsClockCounters.Sleep(AMilliseconds: Integer);
begin
  Winapi.Windows.Sleep(AMilliseconds);
end;

end.
