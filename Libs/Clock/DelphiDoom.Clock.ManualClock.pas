{******************************************************************************}
{                                                                              }
{  DelphiDoom: clock library - a clock that only moves when it is told to       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Clock.ManualClock;

// the milliseconds are a 32 bit counter that wraps around, as the one of the system: no overflow checks
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Clock.Intf;

type
  /// <summary>
  ///   IClock for tests and for runs that must give the same result every time (screenshots, scripts): the time is
  ///   a number of milliseconds that only Advance, Sleep and Wait increase, so nothing waits and nothing depends
  ///   on the machine. Steps is computed with whole numbers: Steps(1000) is exactly the milliseconds
  /// </summary>
  TManualClock = class(TInterfacedObject, IClock)
  strict private
    FMilliseconds: Cardinal;
  public
    constructor Create(AStartMilliseconds: Cardinal = 0);
    function Seconds: Double;
    function Steps(ARate: Integer): Integer;
    function ScaledSteps(ARate, AScale: Integer): Integer;
    /// <summary>The wait is only an advance of the clock</summary>
    procedure Sleep(AMilliseconds: Integer);
    /// <summary>The wait is only an advance of the clock</summary>
    procedure Wait(AMilliseconds: Integer);
    /// <summary>Moves the time forward</summary>
    procedure Advance(AMilliseconds: Cardinal);
    /// <summary>The time now; it wraps around after 2^32 milliseconds</summary>
    function Milliseconds: Cardinal;
  end;

implementation

const
  MILLISECONDS_PER_SECOND = 1000;

constructor TManualClock.Create(AStartMilliseconds: Cardinal);
begin
  inherited Create;
  FMilliseconds := AStartMilliseconds;
end;

function TManualClock.Seconds: Double;
begin
  Result := FMilliseconds / MILLISECONDS_PER_SECOND;
end;

function TManualClock.Steps(ARate: Integer): Integer;
begin
  Result := Integer((Int64(FMilliseconds) * ARate) div MILLISECONDS_PER_SECOND);
end;

function TManualClock.ScaledSteps(ARate, AScale: Integer): Integer;
begin
  Result := Integer((Int64(FMilliseconds) * ARate * AScale) div MILLISECONDS_PER_SECOND);
end;

procedure TManualClock.Sleep(AMilliseconds: Integer);
begin
  if AMilliseconds > 0 then
    Advance(Cardinal(AMilliseconds));
end;

procedure TManualClock.Wait(AMilliseconds: Integer);
begin
  Sleep(AMilliseconds);
end;

procedure TManualClock.Advance(AMilliseconds: Cardinal);
begin
  Inc(FMilliseconds, AMilliseconds);
end;

function TManualClock.Milliseconds: Cardinal;
begin
  Result := FMilliseconds;
end;

end.
