{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - walks along the envelope of an instrument             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.EnvelopeCursor;

interface

uses
  DelphiDoom.Tracker.Types;

type
  /// <summary>
  ///   The position of a note on a volume or panning envelope: one step for
  ///   each tick, with the sustain loop (until the key off) and the loop
  /// </summary>
  /// <remarks>
  ///   The value is read before the step: the first tick of a note is at the
  ///   first point. In XM the sustain is a single point (start and end are
  ///   the same); in IT it is a range that is repeated
  /// </remarks>
  TTrackerEnvelopeCursor = class
  private
    FEnvelope: TTrackerEnvelope;
    FActive: Boolean;
    FReleased: Boolean;
    FPosition: Integer;
    function IsValidPoint(const AIndex: Integer): Boolean;
    function PointTick(const AIndex: Integer): Integer;
  public
    /// <summary>Starts from the beginning with the envelope of a new note</summary>
    procedure Start(const AEnvelope: TTrackerEnvelope);

    /// <summary>The key off: the sustain loop is left</summary>
    procedure Release;

    /// <summary>One tick forward</summary>
    procedure Advance;

    /// <summary>The value at this moment, 0..64; 64 when the envelope is not active</summary>
    function Value: Double;

    /// <summary>True when the envelope is enabled and has points</summary>
    property Active: Boolean read FActive;
    property Released: Boolean read FReleased;
    /// <summary>In ticks from the start of the envelope</summary>
    property Position: Integer read FPosition;
  end;

implementation

const
  MAX_VALUE = 64;

{ TTrackerEnvelopeCursor }

function TTrackerEnvelopeCursor.IsValidPoint(const AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < Length(FEnvelope.Points));
end;

function TTrackerEnvelopeCursor.PointTick(const AIndex: Integer): Integer;
begin
  Result := FEnvelope.Points[AIndex].Tick;
end;

procedure TTrackerEnvelopeCursor.Start(const AEnvelope: TTrackerEnvelope);
begin
  FEnvelope := AEnvelope;
  FActive := FEnvelope.Enabled and (Length(FEnvelope.Points) > 0);
  FReleased := False;
  FPosition := 0;
end;

procedure TTrackerEnvelopeCursor.Release;
begin
  FReleased := True;
end;

procedure TTrackerEnvelopeCursor.Advance;
var
  LLastTick: Integer;
begin
  if not FActive then
    Exit;

  Inc(FPosition);

  if FEnvelope.Sustain and not FReleased and IsValidPoint(FEnvelope.SustainStart) and
    IsValidPoint(FEnvelope.SustainEnd) and (FPosition >= PointTick(FEnvelope.SustainEnd)) then
  begin
    FPosition := PointTick(FEnvelope.SustainStart);
    Exit;
  end;

  if FEnvelope.Loop and IsValidPoint(FEnvelope.LoopStart) and IsValidPoint(FEnvelope.LoopEnd) and
    (FPosition >= PointTick(FEnvelope.LoopEnd)) then
  begin
    FPosition := PointTick(FEnvelope.LoopStart);
    Exit;
  end;

  // After the last point the value stays there
  LLastTick := PointTick(High(FEnvelope.Points));
  if FPosition > LLastTick then
    FPosition := LLastTick;
end;

function TTrackerEnvelopeCursor.Value: Double;
var
  LIndex, LSpan: Integer;
  LFrom, LTo: TTrackerEnvelopePoint;
begin
  if not FActive then
    Exit(MAX_VALUE);

  if FPosition <= PointTick(0) then
    Exit(FEnvelope.Points[0].Value);

  for LIndex := 0 to High(FEnvelope.Points) - 1 do
  begin
    LFrom := FEnvelope.Points[LIndex];
    LTo := FEnvelope.Points[LIndex + 1];
    if FPosition < LTo.Tick then
    begin
      LSpan := LTo.Tick - LFrom.Tick;
      if LSpan <= 0 then
        Exit(LTo.Value);
      Exit(LFrom.Value + (LTo.Value - LFrom.Value) * (FPosition - LFrom.Tick) / LSpan);
    end;
  end;

  Result := FEnvelope.Points[High(FEnvelope.Points)].Value;
end;

end.
