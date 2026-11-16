{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - the clock of a deterministic run               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.VirtualClock;

interface

uses
  DelphiDoom.Clock.Intf;

type
  /// <summary>
  ///   A clock that counts tics and not time: it moves by one tic at every end of a frame (AdvanceFrame), at
  ///   every Sleep and Wait, and after a long series of readings with no movement (a loop that waits for
  ///   the time to pass would never end). What the game draws then depends only on the number of tics, never
  ///   on the speed of the machine
  /// </summary>
  TParityVirtualClock = class(TInterfacedObject, IClock)
  strict private
    FRate: Integer;
    FTics: Integer;
    FReads: Integer;
    procedure CountRead;
  public
    /// <summary>ARate: the tics in a second of the game (35)</summary>
    constructor Create(ARate: Integer);
    function Seconds: Double;
    function Steps(ARate: Integer): Integer;
    function ScaledSteps(ARate, AScale: Integer): Integer;
    procedure Sleep(AMilliseconds: Integer);
    procedure Wait(AMilliseconds: Integer);
    /// <summary>One tic goes by (the end of a frame)</summary>
    procedure AdvanceFrame;
    /// <summary>The tics gone by until now</summary>
    function Tics: Integer;
  end;

implementation

const
  READS_BEFORE_ADVANCE = 100000;

{ TParityVirtualClock }

constructor TParityVirtualClock.Create(ARate: Integer);
begin
  inherited Create;
  FRate := ARate;
end;

procedure TParityVirtualClock.CountRead;
begin
  Inc(FReads);
  if FReads >= READS_BEFORE_ADVANCE then
    AdvanceFrame;
end;

procedure TParityVirtualClock.AdvanceFrame;
begin
  Inc(FTics);
  FReads := 0;
end;

function TParityVirtualClock.Tics: Integer;
begin
  Result := FTics;
end;

function TParityVirtualClock.Seconds: Double;
begin
  CountRead;
  Result := FTics / FRate;
end;

function TParityVirtualClock.Steps(ARate: Integer): Integer;
begin
  CountRead;
  Result := Integer((Int64(FTics) * ARate) div FRate);
end;

function TParityVirtualClock.ScaledSteps(ARate, AScale: Integer): Integer;
begin
  CountRead;
  Result := Integer((Int64(FTics) * ARate * AScale) div FRate);
end;

procedure TParityVirtualClock.Sleep(AMilliseconds: Integer);
begin
  AdvanceFrame;
end;

procedure TParityVirtualClock.Wait(AMilliseconds: Integer);
begin
  AdvanceFrame;
end;

end.
