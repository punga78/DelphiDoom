{******************************************************************************}
{                                                                              }
{  DelphiDoom: clock library - the source on the Windows counters               }
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
  ///   QueryPerformanceCounter; if it fails (or there is no such counter) it goes on with
  ///   GetTickCount at 1000 steps per second, and the frequency it reports changes with it
  /// </summary>
  TPerformanceClockSource = class(TInterfacedObject, IClockSource)
  private
    FFrequency: Int64;
  public
    constructor Create;
    function GetFrequency: Int64;
    function Read: Int64;
    procedure Sleep(AMilliseconds: Integer);
  end;

implementation

uses
  Winapi.Windows;

{ TPerformanceClockSource }

constructor TPerformanceClockSource.Create;
begin
  inherited Create;
  if not QueryPerformanceFrequency(FFrequency) then
    FFrequency := 1000;
end;

function TPerformanceClockSource.GetFrequency: Int64;
begin
  Result := FFrequency;
end;

function TPerformanceClockSource.Read: Int64;
begin
  if FFrequency = 1000 then
    Result := GetTickCount
  else if not QueryPerformanceCounter(Result) then
  begin
    FFrequency := 1000;
    Result := GetTickCount;
  end;
end;

procedure TPerformanceClockSource.Sleep(AMilliseconds: Integer);
begin
  Winapi.Windows.Sleep(AMilliseconds);
end;

end.
