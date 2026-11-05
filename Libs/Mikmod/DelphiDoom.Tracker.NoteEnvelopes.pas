{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - the envelopes and the fade out of a note              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.NoteEnvelopes;

interface

uses
  DelphiDoom.Tracker.EnvelopeCursor,
  DelphiDoom.Tracker.Types;

type
  /// <summary>
  ///   What the instrument does to a note while it sounds: the envelopes of
  ///   volume, panning and pitch, and the fade out that follows the key off
  /// </summary>
  /// <remarks>
  ///   It goes with the note, not with the channel: a note that continues in
  ///   the background (IT) takes it along
  /// </remarks>
  TTrackerNoteEnvelopes = class
  private
    FFormat: TTrackerFormat;
    FInstrument: TTrackerInstrument;
    FVolumeCursor: TTrackerEnvelopeCursor;
    FPanningCursor: TTrackerEnvelopeCursor;
    FPitchCursor: TTrackerEnvelopeCursor;
    FKeyOff: Boolean;
    FFading: Boolean;
    FFade: Integer;
    function FadeStep: Integer;
  public
    constructor Create(const AFormat: TTrackerFormat);
    destructor Destroy; override;

    /// <summary>A new note of the instrument: everything starts again</summary>
    procedure Start(const AInstrument: TTrackerInstrument);

    /// <summary>
    ///   The key off: the envelopes leave the sustain and the fade out begins.
    ///   In XM, without the envelope of the volume, the note ends at once
    /// </summary>
    procedure KeyOff;

    /// <summary>Begins the fade out without the key off (the action "fade" of IT)</summary>
    procedure StartFade;

    /// <summary>One tick of the envelopes and of the fade out</summary>
    procedure Advance;

    /// <summary>0..1, the envelope of the volume with the fade out</summary>
    function VolumeFactor: Double;

    /// <summary>Multiplier of the frequency from the envelope of the pitch (IT), 1 for none</summary>
    function PitchFactor: Double;

    /// <summary>
    ///   Moves the panning ABase (0..255) by the envelope of the panning: it
    ///   moves up to half the way to the sides
    /// </summary>
    function AdjustPanning(const ABase: Double): Double;

    /// <summary>True when nothing can be heard of the note any more</summary>
    function IsFinished: Boolean;

    property KeyedOff: Boolean read FKeyOff;
  end;

implementation

uses
  System.Math;

const
  FADE_FULL = 65536;
  // The fade out of the instrument per tick, in 1/65536: XM counts 1/32768, IT 1/1024 of 128 steps
  XM_FADE_UNIT = 2;
  IT_FADE_UNIT = 64;
  CENTER_ENVELOPE = 32;
  MAX_ENVELOPE = 64;
  PANNING_RANGE = 128;
  // The pitch envelope of IT goes up and down by 16 semitones at most
  PITCH_STEPS_PER_SEMITONE = 2;
  SEMITONES_PER_OCTAVE = 12;
  SILENCE = 0.0005;

{ TTrackerNoteEnvelopes }

constructor TTrackerNoteEnvelopes.Create(const AFormat: TTrackerFormat);
begin
  inherited Create;
  FFormat := AFormat;
  FFade := FADE_FULL;
  FVolumeCursor := TTrackerEnvelopeCursor.Create;
  FPanningCursor := TTrackerEnvelopeCursor.Create;
  FPitchCursor := TTrackerEnvelopeCursor.Create;
end;

destructor TTrackerNoteEnvelopes.Destroy;
begin
  FPitchCursor.Free;
  FPanningCursor.Free;
  FVolumeCursor.Free;
  inherited Destroy;
end;

function TTrackerNoteEnvelopes.FadeStep: Integer;
begin
  if not Assigned(FInstrument) then
    Exit(0);
  if FFormat = tfXm then
    Result := FInstrument.FadeOut * XM_FADE_UNIT
  else
    Result := FInstrument.FadeOut * IT_FADE_UNIT;
end;

procedure TTrackerNoteEnvelopes.Start(const AInstrument: TTrackerInstrument);
begin
  FInstrument := AInstrument;
  FKeyOff := False;
  FFading := False;
  FFade := FADE_FULL;
  if Assigned(AInstrument) then
  begin
    FVolumeCursor.Start(AInstrument.VolumeEnvelope);
    FPanningCursor.Start(AInstrument.PanningEnvelope);
    FPitchCursor.Start(AInstrument.PitchEnvelope);
  end;
end;

procedure TTrackerNoteEnvelopes.KeyOff;
begin
  FKeyOff := True;
  FFading := True;
  FVolumeCursor.Release;
  FPanningCursor.Release;
  FPitchCursor.Release;
  if (FFormat = tfXm) and not FVolumeCursor.Active then
    FFade := 0;
end;

procedure TTrackerNoteEnvelopes.StartFade;
begin
  FFading := True;
end;

procedure TTrackerNoteEnvelopes.Advance;
begin
  FVolumeCursor.Advance;
  FPanningCursor.Advance;
  FPitchCursor.Advance;
  if FFading and (FFade > 0) then
    FFade := Max(0, FFade - FadeStep);
end;

function TTrackerNoteEnvelopes.VolumeFactor: Double;
begin
  Result := FVolumeCursor.Value / MAX_ENVELOPE * (FFade / FADE_FULL);
end;

function TTrackerNoteEnvelopes.PitchFactor: Double;
begin
  if not FPitchCursor.Active then
    Exit(1);
  Result := Power(2, (FPitchCursor.Value - CENTER_ENVELOPE) / PITCH_STEPS_PER_SEMITONE /
    SEMITONES_PER_OCTAVE);
end;

function TTrackerNoteEnvelopes.AdjustPanning(const ABase: Double): Double;
begin
  Result := ABase;
  if FPanningCursor.Active then
    Result := Result + (FPanningCursor.Value - CENTER_ENVELOPE) *
      (PANNING_RANGE - Abs(ABase - PANNING_RANGE)) / CENTER_ENVELOPE;
end;

function TTrackerNoteEnvelopes.IsFinished: Boolean;
begin
  Result := (FFade <= 0) or
    (FVolumeCursor.Active and FVolumeCursor.Released and (VolumeFactor < SILENCE));
end;

end.
