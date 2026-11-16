{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - a note that goes on in the background (IT)            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.Ghost;

interface

uses
  DelphiDoom.Tracker.NoteEnvelopes,
  DelphiDoom.Tracker.Types,
  DelphiDoom.Tracker.Voice;

type
  /// <summary>
  ///   A note that a channel has left when a new one started: it keeps
  ///   sounding on its own voice, with the envelopes it had, until it ends
  ///   or until the pool needs the voice
  /// </summary>
  /// <remarks>
  ///   Its volume, frequency and panning are the ones of the channel at the
  ///   moment it was left: the effects of the channel do not follow it
  /// </remarks>
  TTrackerGhost = class
  private
    FVoice: TTrackerVoice;
    FEnvelopes: TTrackerNoteEnvelopes;
    FChannelIndex: Integer;
    FNote: Integer;
    FInstrument: TTrackerInstrument;
    FSample: TTrackerSample;
    FBaseVolume: Double;
    FFrequency: Double;
    FPanning: Double;
    FDead: Boolean;
  public
    /// <param name="AVoice">The voice of the mixer that plays the note; it already holds the sound</param>
    /// <param name="AEnvelopes">The envelopes of the note; the ghost owns them</param>
    /// <param name="ABaseVolume">Volume of the channel, 0..1, without the envelope</param>
    /// <param name="AFrequency">Frequency of the note in Hz, without the envelope of the pitch</param>
    /// <param name="APanning">0..255</param>
    constructor Create(const AVoice: TTrackerVoice; const AEnvelopes: TTrackerNoteEnvelopes;
      const AChannelIndex, ANote: Integer; const AInstrument: TTrackerInstrument;
      const ASample: TTrackerSample; const ABaseVolume, AFrequency, APanning: Double);
    destructor Destroy; override;

    /// <summary>One tick: the envelopes go on and the voice follows them</summary>
    procedure Update(const ASampleRate: Integer; const AGlobalVolume: Double);

    /// <summary>Ends the note at once and frees the voice</summary>
    procedure Cut;

    property Voice: TTrackerVoice read FVoice;
    property Envelopes: TTrackerNoteEnvelopes read FEnvelopes;
    property ChannelIndex: Integer read FChannelIndex;
    property Note: Integer read FNote;
    property Instrument: TTrackerInstrument read FInstrument;
    property Sample: TTrackerSample read FSample;
    property Dead: Boolean read FDead;
  end;

implementation

uses
  System.Math;

const
  MAX_PANNING = 255;

{ TTrackerGhost }

constructor TTrackerGhost.Create(const AVoice: TTrackerVoice; const AEnvelopes: TTrackerNoteEnvelopes;
  const AChannelIndex, ANote: Integer; const AInstrument: TTrackerInstrument;
  const ASample: TTrackerSample; const ABaseVolume, AFrequency, APanning: Double);
begin
  inherited Create;
  FVoice := AVoice;
  FEnvelopes := AEnvelopes;
  FChannelIndex := AChannelIndex;
  FNote := ANote;
  FInstrument := AInstrument;
  FSample := ASample;
  FBaseVolume := ABaseVolume;
  FFrequency := AFrequency;
  FPanning := APanning;
end;

destructor TTrackerGhost.Destroy;
begin
  FEnvelopes.Free;
  inherited Destroy;
end;

procedure TTrackerGhost.Update(const ASampleRate: Integer; const AGlobalVolume: Double);
begin
  if FDead then
    Exit;
  FEnvelopes.Advance;
  if not FVoice.Active or FEnvelopes.IsFinished then
  begin
    Cut;
    Exit;
  end;
  FVoice.Increment := FFrequency * FEnvelopes.PitchFactor / ASampleRate;
  FVoice.Volume := FBaseVolume * AGlobalVolume * FEnvelopes.VolumeFactor;
  FVoice.Panning := Max(0, Min(1, FEnvelopes.AdjustPanning(FPanning) / MAX_PANNING));
end;

procedure TTrackerGhost.Cut;
begin
  FDead := True;
  FVoice.Stop;
end;

end.
