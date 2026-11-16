{******************************************************************************}
{                                                                              }
{  DelphiDoom: clock library - the clock                                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Clock.Clock;

interface

uses
  DelphiDoom.Clock.Intf, DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   Seconds from the first reading. When the source changes its frequency (it had to give up
  ///   its counter) the time starts again from 0, and the log is told
  /// </summary>
  TClock = class(TInterfacedObject, IClock)
  private
    FSource: IClockSource;
    FLog: ILog;
    FBase: Int64;
    FHasBase: Boolean;
    FFrequency: Int64;
  public
    /// <summary>ALog may be nil</summary>
    constructor Create(const ASource: IClockSource; const ALog: ILog);
    function Seconds: Double;
    function Steps(ARate: Integer): Integer;
    function ScaledSteps(ARate, AScale: Integer): Integer;
    procedure Sleep(AMilliseconds: Integer);
    procedure Wait(AMilliseconds: Integer);
  end;

implementation

uses
  System.SysUtils;

const
  SFrequencyChanged = 'The counter of the clock was replaced, time restarts from zero.'#13#10;

{ TClock }

constructor TClock.Create(const ASource: IClockSource; const ALog: ILog);
begin
  inherited Create;
  FSource := ASource;
  FLog := ALog;
  FFrequency := ASource.Frequency;
end;

function TClock.Seconds: Double;
var
  LValue: Int64;
  LFrequency: Int64;
begin
  LValue := FSource.Read;
  LFrequency := FSource.Frequency;
  if LFrequency <> FFrequency then
  begin
    FFrequency := LFrequency;
    FHasBase := False;
    if Assigned(FLog) then
      FLog.Warning(SFrequencyChanged);
  end;
  if not FHasBase then
  begin
    FBase := LValue;
    FHasBase := True;
  end;
  Result := (LValue - FBase) / FFrequency;
end;

function TClock.Steps(ARate: Integer): Integer;
begin
  Result := Trunc(Seconds * ARate);
end;

function TClock.ScaledSteps(ARate, AScale: Integer): Integer;
begin
  Result := Trunc(Seconds * ARate * AScale);
end;

procedure TClock.Sleep(AMilliseconds: Integer);
begin
  FSource.Sleep(AMilliseconds);
end;

procedure TClock.Wait(AMilliseconds: Integer);
var
  LUntil: Double;
begin
  LUntil := Seconds + AMilliseconds / 1000;
  repeat
    FSource.Sleep(0);
  until Seconds >= LUntil;
end;

end.
