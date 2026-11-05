{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - a channel: its note, its volume and its effects       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.Channel;

interface

uses
  DelphiDoom.Tracker.Effects,
  DelphiDoom.Tracker.GhostPool,
  DelphiDoom.Tracker.NoteEnvelopes,
  DelphiDoom.Tracker.Types,
  DelphiDoom.Tracker.Voice;

type
  /// <summary>
  ///   The state of a channel of the module and the effects that change its
  ///   note while the row goes by: slides, vibrato, tremolo, arpeggio,
  ///   retrigger, cut and delay of the note
  /// </summary>
  /// <remarks>
  ///   The effects of the song flow (speed, tempo, jump, break, loop, delay of
  ///   the pattern, global volume) belong to the player. Not done yet: the
  ///   effects of IT that change the action of a single note (S70 to S76)
  /// </remarks>
  TTrackerChannel = class
  private
    type
      TMemory = (mmPortamentoUp, mmPortamentoDown, mmTonePortamento, mmVibratoSpeed,
        mmVibratoDepth, mmTremoloSpeed, mmTremoloDepth, mmVolumeSlide, mmSampleOffset,
        mmRetrigger, mmArpeggio);
  private
    FModule: TTrackerModule;
    FVoice: TTrackerVoice;
    FSampleRate: Integer;
    FIndex: Integer;
    FInstrument: TTrackerInstrument;
    FSample: TTrackerSample;
    FVolume: Integer;
    FPanning: Double;
    FFrequency: Double;
    FPortamentoTarget: Double;
    FVibratoPosition: Integer;
    FTremoloPosition: Integer;
    // 0 sine, 1 ramp, 2 square, 3 random; 4 and more: a new note does not start the wave again
    FVibratoWaveform: Integer;
    FTremoloWaveform: Integer;
    FNoiseState: Int64;
    FNoise: Integer;
    FEffect: TTrackerEffect;
    FVolumeEffect: TTrackerEffect;
    FMemory: array[TMemory] of Byte;
    FStartOffset: Integer;
    FDelayedNote: Integer;
    FVibratoDelta: Double;
    FTremoloDelta: Integer;
    FArpeggioSemitones: Integer;
    FGlobalVolume: Double;
    FEnvelopes: TTrackerNoteEnvelopes;
    FGhosts: TTrackerGhostPool;
    // The note that sounds: its number, its instrument (the sample is FSample)
    FNoteNumber: Integer;
    FNoteInstrument: TTrackerInstrument;
    function Remember(const AMemory: TMemory; const AParam: Byte): Byte;
    function IsLinear: Boolean;
    procedure SlideUp(const ADelta: Double);
    procedure SlideDown(const ADelta: Double);
    procedure SlideToTarget(const ASpeed: Double);
    procedure SlideVolume(const AParam: Byte; const AOnTickZero: Boolean);
    procedure TriggerNote(const ANote: Integer);
    procedure SetTarget(const ANote: Integer);
    function NoteFrequency(const ANote: Integer): Double;
    procedure RunTickZero(var AEffect: TTrackerEffect);
    procedure RunTick(const AEffect: TTrackerEffect; const ATick: Integer);
    procedure Retrigger(const AParam: Byte);
    function WaveformValue(const AWaveform, APosition: Integer): Integer;
    procedure AdvanceNoise;
    procedure UpdateVibrato(const AAdvance: Boolean);
    procedure UpdateTremolo(const AAdvance: Boolean);
    function ClampVolume(const AValue: Integer): Integer;
    function IsTonePortamento(const AEffect: TTrackerEffect): Boolean;
    procedure KeyOff;
    procedure ReleaseOldNote(const ANote: Integer; const ANewSample: TTrackerSample);
  public
    /// <param name="AModule">The module that is played</param>
    /// <param name="AVoice">The voice of the mixer that this channel drives</param>
    /// <param name="ASampleRate">Frames per second of the output</param>
    /// <param name="AIndex">Number of the channel</param>
    constructor Create(const AModule: TTrackerModule; const AVoice: TTrackerVoice;
      const ASampleRate, AIndex: Integer);
    destructor Destroy; override;

    /// <summary>
    ///   Starts a row: the instrument and the note, and the effects that act
    ///   on the first tick
    /// </summary>
    procedure StartRow(const ACell: TTrackerCell);

    /// <summary>The effects of the ticks after the first, ATick from 1</summary>
    procedure ProcessTick(const ATick: Integer);

    /// <summary>
    ///   Gives the voice the frequency, the volume and the panning of this
    ///   moment, with the modulation of the effects
    /// </summary>
    procedure UpdateVoice;

    /// <summary>Silences the channel</summary>
    procedure Silence;

    /// <summary>0..64</summary>
    property Volume: Integer read FVolume;
    /// <summary>0 (left) to 255 (right)</summary>
    property Panning: Double read FPanning;
    /// <summary>Frequency of the note in Hz, without vibrato and arpeggio</summary>
    property Frequency: Double read FFrequency;
    property Sample: TTrackerSample read FSample;
    /// <summary>Scale 0..1 of the global volume of the module</summary>
    property GlobalVolume: Double read FGlobalVolume write FGlobalVolume;
    /// <summary>
    ///   Where the notes that a new one pushes away go on (IT); not owned, nil for none
    /// </summary>
    property Ghosts: TTrackerGhostPool read FGhosts write FGhosts;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Tracker.Ghost;

const
  // The period of a note, in the units of Scream Tracker: 8363 * 1712 / frequency
  AMIGA_CONSTANT = 8363.0 * 1712.0;
  // A semitone is 64 units of period in the linear slides, an octave 768
  LINEAR_UNITS_PER_OCTAVE = 768.0;
  // ProTracker limits the periods to the notes C-1 and B-3 (four times these
  // in the units of Scream Tracker)
  MOD_MIN_PERIOD = 113.0 * 4;
  MOD_MAX_PERIOD = 856.0 * 4;
  MIN_PERIOD = 1.0;
  MAX_VOLUME = 64;
  CENTER_PANNING = 127.5;
  SLIDE_UNIT = 4;
  FINE_VOLUME_NIBBLE = $0F;
  EXTRA_FINE_BASE = $E0;
  FINE_BASE = $F0;
  VIBRATO_STEPS = 64;
  VIBRATO_HALF = 32;
  OFFSET_UNIT = 256;
  WAVEFORM_CONTINUES = 4;
  WAVEFORM_RAMP = 1;
  WAVEFORM_SQUARE = 2;
  WAVEFORM_RANDOM = 3;
  WAVEFORM_KINDS = 3;
  MAX_WAVEFORM = 7;
  WAVE_PEAK = 255;
  RAMP_STEP = 8;
  NOISE_MULTIPLIER = 1103515245;
  NOISE_INCREMENT = 12345;
  NOISE_MASK = $7FFFFFFF;
  NOISE_SHIFT = 16;

  // sin(i * pi / 32) * 255, the table of the vibrato of ProTracker
  VIBRATO_TABLE: array[0..31] of Integer = (
    0, 24, 49, 74, 97, 120, 141, 161, 180, 197, 212, 224, 235, 244, 250, 253,
    255, 253, 250, 244, 235, 224, 212, 197, 180, 161, 141, 120, 97, 74, 49, 24);

  // The change of volume of the retrigger of Scream Tracker (Qxy), by x:
  // plus or minus an amount, or a ratio in sixteenths
  RETRIGGER_ADD: array[0..15] of Integer = (0, -1, -2, -4, -8, -16, 0, 0, 0, 1, 2, 4, 8, 16, 0, 0);
  RETRIGGER_MULTIPLY: array[0..15] of Integer = (16, 16, 16, 16, 16, 16, 10, 8, 16, 16, 16, 16, 16, 16, 24, 32);

{ TTrackerChannel }

constructor TTrackerChannel.Create(const AModule: TTrackerModule; const AVoice: TTrackerVoice;
  const ASampleRate, AIndex: Integer);
begin
  inherited Create;
  FModule := AModule;
  FVoice := AVoice;
  FSampleRate := ASampleRate;
  FIndex := AIndex;
  FPanning := CENTER_PANNING;
  FGlobalVolume := 1;
  FDelayedNote := TRACKER_NOTE_NONE;
  FEnvelopes := TTrackerNoteEnvelopes.Create(AModule.Format);
end;

destructor TTrackerChannel.Destroy;
begin
  FEnvelopes.Free;
  inherited Destroy;
end;

function TTrackerChannel.IsLinear: Boolean;
begin
  Result := FModule.LinearSlides;
end;

function TTrackerChannel.ClampVolume(const AValue: Integer): Integer;
begin
  Result := Max(0, Min(MAX_VOLUME, AValue));
end;

// The parameter 0 means "the last one" in most effects
function TTrackerChannel.Remember(const AMemory: TMemory; const AParam: Byte): Byte;
begin
  if AParam <> 0 then
    FMemory[AMemory] := AParam;
  Result := FMemory[AMemory];
end;

function TTrackerChannel.NoteFrequency(const ANote: Integer): Double;
begin
  Result := FSample.CenterFrequency * Power(2, (ANote - TRACKER_CENTER_NOTE) / 12);
end;

procedure TTrackerChannel.SlideUp(const ADelta: Double);
var
  LPeriod: Double;
begin
  if IsLinear then
    FFrequency := FFrequency * Power(2, ADelta / LINEAR_UNITS_PER_OCTAVE)
  else
  begin
    LPeriod := AMIGA_CONSTANT / FFrequency - ADelta;
    if FModule.Format = tfMod then
      LPeriod := Max(MOD_MIN_PERIOD, LPeriod)
    else
      LPeriod := Max(MIN_PERIOD, LPeriod);
    FFrequency := AMIGA_CONSTANT / LPeriod;
  end;
end;

procedure TTrackerChannel.SlideDown(const ADelta: Double);
var
  LPeriod: Double;
begin
  if IsLinear then
    FFrequency := FFrequency * Power(2, -ADelta / LINEAR_UNITS_PER_OCTAVE)
  else
  begin
    LPeriod := AMIGA_CONSTANT / FFrequency + ADelta;
    if FModule.Format = tfMod then
      LPeriod := Min(MOD_MAX_PERIOD, LPeriod);
    FFrequency := AMIGA_CONSTANT / LPeriod;
  end;
end;

// Moves the note toward the target of the tone portamento, without going past it
procedure TTrackerChannel.SlideToTarget(const ASpeed: Double);
var
  LBefore: Double;
begin
  if FPortamentoTarget <= 0 then
    Exit;
  LBefore := FFrequency;
  if FFrequency < FPortamentoTarget then
  begin
    SlideUp(ASpeed);
    if FFrequency > FPortamentoTarget then
      FFrequency := FPortamentoTarget;
  end
  else if FFrequency > FPortamentoTarget then
  begin
    SlideDown(ASpeed);
    if FFrequency < FPortamentoTarget then
      FFrequency := FPortamentoTarget;
  end;
  if LBefore = 0 then
    FFrequency := FPortamentoTarget;
end;

// Volume slide with the parameter of the format: MOD and XM slide on the ticks
// after the first; S3M and IT also have fine slides, in the first tick
procedure TTrackerChannel.SlideVolume(const AParam: Byte; const AOnTickZero: Boolean);
var
  LUp, LDown: Integer;
begin
  LUp := AParam shr 4;
  LDown := AParam and $0F;

  if FModule.Format in [tfS3m, tfIt] then
  begin
    if AOnTickZero then
    begin
      if (LDown = FINE_VOLUME_NIBBLE) and (LUp > 0) then
        FVolume := ClampVolume(FVolume + LUp)
      else if (LUp = FINE_VOLUME_NIBBLE) and (LDown > 0) then
        FVolume := ClampVolume(FVolume - LDown);
    end
    else
    begin
      if (LDown = FINE_VOLUME_NIBBLE) and (LUp > 0) then
        Exit;
      if (LUp = FINE_VOLUME_NIBBLE) and (LDown > 0) then
        Exit;
      if LDown = 0 then
        FVolume := ClampVolume(FVolume + LUp)
      else if LUp = 0 then
        FVolume := ClampVolume(FVolume - LDown);
    end;
  end
  else if not AOnTickZero then
  begin
    if LUp > 0 then
      FVolume := ClampVolume(FVolume + LUp)
    else
      FVolume := ClampVolume(FVolume - LDown);
  end;
end;

procedure TTrackerChannel.TriggerNote(const ANote: Integer);
var
  LSampleIndex, LPlayedNote: Integer;
begin
  if not Assigned(FInstrument) then
    Exit;
  LSampleIndex := FInstrument.SampleMap[ANote - 1];
  LPlayedNote := FInstrument.NoteMap[ANote - 1];
  if LSampleIndex >= FInstrument.Samples.Count then
    Exit;

  // The note that sounds goes on in the background, or ends (IT)
  if Assigned(FGhosts) and (FModule.Format = tfIt) then
    ReleaseOldNote(ANote, FInstrument.Samples[LSampleIndex]);

  FSample := FInstrument.Samples[LSampleIndex];
  FNoteNumber := ANote;
  FNoteInstrument := FInstrument;
  FFrequency := NoteFrequency(LPlayedNote);
  FVolume := FSample.Volume;
  if FSample.Panning >= 0 then
    FPanning := FSample.Panning
  else if (FIndex < Length(FModule.ChannelPanning)) and (FModule.ChannelPanning[FIndex] >= 0) then
    FPanning := FModule.ChannelPanning[FIndex]
  else
    FPanning := CENTER_PANNING;

  if FVibratoWaveform < WAVEFORM_CONTINUES then
    FVibratoPosition := 0;
  if FTremoloWaveform < WAVEFORM_CONTINUES then
    FTremoloPosition := 0;
  FEnvelopes.Start(FInstrument);
  FVoice.Start(FSample, FStartOffset);
  FStartOffset := 0;
end;

// Tone portamento: the new note is not played, it is the place to go to
procedure TTrackerChannel.SetTarget(const ANote: Integer);
var
  LPlayedNote, LSampleIndex: Integer;
begin
  if not Assigned(FInstrument) then
    Exit;
  LSampleIndex := FInstrument.SampleMap[ANote - 1];
  LPlayedNote := FInstrument.NoteMap[ANote - 1];
  if LSampleIndex >= FInstrument.Samples.Count then
    Exit;
  if not Assigned(FSample) then
  begin
    // Nothing is playing yet: the note is played, there is nowhere to slide from
    TriggerNote(ANote);
    Exit;
  end;
  FPortamentoTarget := FInstrument.Samples[LSampleIndex].CenterFrequency *
    Power(2, (LPlayedNote - TRACKER_CENTER_NOTE) / 12);
end;

function TTrackerChannel.IsTonePortamento(const AEffect: TTrackerEffect): Boolean;
begin
  Result := AEffect.Kind in [ekTonePortamento, ekTonePortamentoVolumeSlide];
end;

procedure TTrackerChannel.StartRow(const ACell: TTrackerCell);
var
  LNote: Integer;
begin
  // A new note starts the envelopes again, after this step
  FEnvelopes.Advance;
  FEffect := TTrackerEffectMapper.Map(FModule.Format, ACell.Effect, ACell.Param);
  FVolumeEffect := TTrackerEffectMapper.MapVolumeColumn(FModule.Format, ACell.Volume);
  FVibratoDelta := 0;
  FTremoloDelta := 0;
  FArpeggioSemitones := 0;
  FDelayedNote := TRACKER_NOTE_NONE;

  if (ACell.Instrument > 0) and (ACell.Instrument <= FModule.Instruments.Count) then
    FInstrument := FModule.Instruments[ACell.Instrument - 1];

  // The offset of the sample must be known before the note starts
  if FEffect.Kind = ekSampleOffset then
    FStartOffset := Remember(mmSampleOffset, FEffect.Param) * OFFSET_UNIT;

  LNote := ACell.Note;
  if (LNote >= TRACKER_NOTE_FIRST) and (LNote <= TRACKER_NOTE_LAST) then
  begin
    if IsTonePortamento(FEffect) or (FVolumeEffect.Kind = ekTonePortamento) then
      SetTarget(LNote)
    else if (FEffect.Kind = ekNoteDelay) and (FEffect.Param > 0) then
    begin
      // The note starts at the tick of the delay
      FDelayedNote := LNote;
    end
    else
      TriggerNote(LNote);
  end
  else if LNote = TRACKER_NOTE_OFF then
    KeyOff
  else if LNote = TRACKER_NOTE_CUT then
    Silence
  else if (ACell.Instrument > 0) and Assigned(FSample) then
    // An instrument without a note sets its volume again
    FVolume := FSample.Volume;
  RunTickZero(FVolumeEffect);
  RunTickZero(FEffect);
  UpdateVoice;
end;

procedure TTrackerChannel.RunTickZero(var AEffect: TTrackerEffect);
begin
  // The parameters that mean "the last one" are resolved here, once
  case AEffect.Kind of
    ekSetVolume:
      FVolume := ClampVolume(AEffect.Param);
    ekSetPanning:
      FPanning := AEffect.Param;
    ekFinePortamentoUp:
      SlideUp(AEffect.Param * SLIDE_UNIT);
    ekFinePortamentoDown:
      SlideDown(AEffect.Param * SLIDE_UNIT);
    ekExtraFinePortamentoUp:
      SlideUp(AEffect.Param);
    ekExtraFinePortamentoDown:
      SlideDown(AEffect.Param);
    ekFineVolumeSlideUp:
      FVolume := ClampVolume(FVolume + AEffect.Param);
    ekFineVolumeSlideDown:
      FVolume := ClampVolume(FVolume - AEffect.Param);
    ekPortamentoUp:
      begin
        AEffect.Param := Remember(mmPortamentoUp, AEffect.Param);
        // Scream Tracker and Impulse Tracker have the fine slides in the same
        // effect: the high nibble tells. They act in the first tick
        if FModule.Format in [tfS3m, tfIt] then
        begin
          if AEffect.Param >= FINE_BASE then
            SlideUp((AEffect.Param and $0F) * SLIDE_UNIT)
          else if AEffect.Param >= EXTRA_FINE_BASE then
            SlideUp(AEffect.Param and $0F);
        end;
      end;
    ekPortamentoDown:
      begin
        AEffect.Param := Remember(mmPortamentoDown, AEffect.Param);
        if FModule.Format in [tfS3m, tfIt] then
        begin
          if AEffect.Param >= FINE_BASE then
            SlideDown((AEffect.Param and $0F) * SLIDE_UNIT)
          else if AEffect.Param >= EXTRA_FINE_BASE then
            SlideDown(AEffect.Param and $0F);
        end;
      end;
    ekTonePortamento:
      AEffect.Param := Remember(mmTonePortamento, AEffect.Param);
    ekTonePortamentoVolumeSlide:
      begin
        AEffect.Param := Remember(mmVolumeSlide, AEffect.Param);
        SlideVolume(AEffect.Param, True);
      end;
    ekVibratoWaveform:
      FVibratoWaveform := AEffect.Param and MAX_WAVEFORM;
    ekTremoloWaveform:
      FTremoloWaveform := AEffect.Param and MAX_WAVEFORM;
    ekSetVibratoSpeed:
      if AEffect.Param <> 0 then
        FMemory[mmVibratoSpeed] := AEffect.Param;
    ekVibrato:
      begin
        if (AEffect.Param shr 4) <> 0 then
          FMemory[mmVibratoSpeed] := AEffect.Param shr 4;
        if (AEffect.Param and $0F) <> 0 then
          FMemory[mmVibratoDepth] := AEffect.Param and $0F;
      end;
    ekVibratoVolumeSlide:
      begin
        AEffect.Param := Remember(mmVolumeSlide, AEffect.Param);
        SlideVolume(AEffect.Param, True);
      end;
    ekTremolo:
      begin
        if (AEffect.Param shr 4) <> 0 then
          FMemory[mmTremoloSpeed] := AEffect.Param shr 4;
        if (AEffect.Param and $0F) <> 0 then
          FMemory[mmTremoloDepth] := AEffect.Param and $0F;
      end;
    ekVolumeSlide:
      begin
        AEffect.Param := Remember(mmVolumeSlide, AEffect.Param);
        SlideVolume(AEffect.Param, True);
      end;
    ekArpeggio:
      AEffect.Param := Remember(mmArpeggio, AEffect.Param);
    ekRetrigger:
      AEffect.Param := Remember(mmRetrigger, AEffect.Param);
    ekNoteCut:
      if AEffect.Param = 0 then
        FVolume := 0;
    ekKeyOff:
      KeyOff;
  end;
end;

procedure TTrackerChannel.Retrigger(const AParam: Byte);
var
  LInterval, LChange: Integer;
begin
  if FModule.Format in [tfS3m, tfIt] then
  begin
    // Qxy: every y ticks, with a change of volume by x
    LInterval := AParam and $0F;
    LChange := AParam shr 4;
    if LInterval = 0 then
      Exit;
    FVolume := ClampVolume(FVolume + RETRIGGER_ADD[LChange]);
    FVolume := ClampVolume(FVolume * RETRIGGER_MULTIPLY[LChange] div 16);
  end;
  if Assigned(FSample) then
    FVoice.Start(FSample);
end;

// The shape of the wave at a position (0..63), from -255 to 255: positive in the first half
function TTrackerChannel.WaveformValue(const AWaveform, APosition: Integer): Integer;
var
  LIndex: Integer;
begin
  LIndex := APosition mod VIBRATO_HALF;
  case AWaveform and WAVEFORM_KINDS of
    WAVEFORM_RAMP:
      begin
        Result := LIndex * RAMP_STEP;
        if APosition >= VIBRATO_HALF then
          Result := WAVE_PEAK - Result;
      end;
    WAVEFORM_SQUARE:
      Result := WAVE_PEAK;
    WAVEFORM_RANDOM:
      Result := FNoise;
  else
    Result := VIBRATO_TABLE[LIndex];
  end;
  if APosition >= VIBRATO_HALF then
    Result := -Result;
end;

// A new value of the random wave, always the same sequence
procedure TTrackerChannel.AdvanceNoise;
begin
  FNoiseState := (FNoiseState * NOISE_MULTIPLIER + NOISE_INCREMENT) and NOISE_MASK;
  FNoise := (FNoiseState shr NOISE_SHIFT) and WAVE_PEAK;
end;

procedure TTrackerChannel.UpdateVibrato(const AAdvance: Boolean);
var
  LSpeed, LDepth: Integer;
begin
  LSpeed := FMemory[mmVibratoSpeed];
  LDepth := FMemory[mmVibratoDepth];
  if AAdvance then
  begin
    FVibratoPosition := (FVibratoPosition + LSpeed) mod VIBRATO_STEPS;
    AdvanceNoise;
  end;

  // ProTracker: the amplitude is wave * depth / 128 in its units of period,
  // four times that in the units of Scream Tracker. The same in XM, where the
  // linear units are the same as these; IT is taken as the others
  FVibratoDelta := WaveformValue(FVibratoWaveform, FVibratoPosition) * LDepth / 128 * SLIDE_UNIT;
end;

procedure TTrackerChannel.UpdateTremolo(const AAdvance: Boolean);
var
  LSpeed, LDepth, LValue: Integer;
begin
  LSpeed := FMemory[mmTremoloSpeed];
  LDepth := FMemory[mmTremoloDepth];
  if AAdvance then
  begin
    FTremoloPosition := (FTremoloPosition + LSpeed) mod VIBRATO_STEPS;
    AdvanceNoise;
  end;

  LValue := WaveformValue(FTremoloWaveform, FTremoloPosition);
  FTremoloDelta := LValue * LDepth div 64;
end;

procedure TTrackerChannel.RunTick(const AEffect: TTrackerEffect; const ATick: Integer);
var
  LInterval: Integer;
begin
  case AEffect.Kind of
    ekPortamentoUp, ekPortamentoDown:
      begin
        // The fine slides were done in the first tick
        if (FModule.Format in [tfS3m, tfIt]) and (AEffect.Param >= EXTRA_FINE_BASE) then
          Exit;
        if AEffect.Kind = ekPortamentoUp then
          SlideUp(AEffect.Param * SLIDE_UNIT)
        else
          SlideDown(AEffect.Param * SLIDE_UNIT);
      end;
    ekTonePortamento:
      SlideToTarget(AEffect.Param * SLIDE_UNIT);
    ekTonePortamentoVolumeSlide:
      begin
        SlideToTarget(FMemory[mmTonePortamento] * SLIDE_UNIT);
        SlideVolume(AEffect.Param, False);
      end;
    ekVibrato:
      UpdateVibrato(True);
    ekVibratoVolumeSlide:
      begin
        UpdateVibrato(True);
        SlideVolume(AEffect.Param, False);
      end;
    ekTremolo:
      UpdateTremolo(True);
    ekVolumeSlide:
      SlideVolume(AEffect.Param, False);
    ekArpeggio:
      case ATick mod 3 of
        1: FArpeggioSemitones := AEffect.Param shr 4;
        2: FArpeggioSemitones := AEffect.Param and $0F;
      else
        FArpeggioSemitones := 0;
      end;
    ekRetrigger:
      begin
        if FModule.Format in [tfS3m, tfIt] then
          LInterval := AEffect.Param and $0F
        else
          LInterval := AEffect.Param;
        if (LInterval > 0) and (ATick mod LInterval = 0) then
          Retrigger(AEffect.Param);
      end;
    ekNoteCut:
      if ATick = AEffect.Param then
        FVolume := 0;
    ekNoteDelay:
      if (ATick = AEffect.Param) and (FDelayedNote <> TRACKER_NOTE_NONE) then
      begin
        TriggerNote(FDelayedNote);
        FDelayedNote := TRACKER_NOTE_NONE;
      end;
  end;
end;

procedure TTrackerChannel.ProcessTick(const ATick: Integer);
begin
  FEnvelopes.Advance;
  FVibratoDelta := 0;
  FTremoloDelta := 0;
  // The volume column acts on every tick too (the slides and the portamento)
  RunTick(FVolumeEffect, ATick);
  RunTick(FEffect, ATick);
  UpdateVoice;
end;

procedure TTrackerChannel.Silence;
begin
  FVoice.Stop;
end;

// The key off of XM and IT: the envelopes go on past the sustain and the
// instrument fades out. The other formats have no such thing: the note stops
procedure TTrackerChannel.KeyOff;
begin
  if not (FModule.Format in [tfXm, tfIt]) or not Assigned(FNoteInstrument) then
    Silence
  else
    FEnvelopes.KeyOff;
end;

// What happens to the note that sounds when a new one starts (IT): the new
// instrument can ask to check the duplicates, and the instrument of the old
// note says what to do with it (cut, continue in the background, key off, fade)
procedure TTrackerChannel.ReleaseOldNote(const ANote: Integer; const ANewSample: TTrackerSample);
var
  LCheck: TTrackerDuplicateCheck;
  LDuplicateAction: TTrackerDuplicateAction;
  LAction: TTrackerNewNoteAction;
  LGhost: TTrackerGhost;
begin
  LCheck := TTrackerDuplicateCheck(Min(FInstrument.DuplicateCheckType, Ord(High(TTrackerDuplicateCheck))));
  LDuplicateAction := TTrackerDuplicateAction(Min(FInstrument.DuplicateCheckAction,
    Ord(High(TTrackerDuplicateAction))));
  FGhosts.ApplyDuplicateCheck(FIndex, LCheck, LDuplicateAction, ANote, ANewSample, FInstrument);

  if not FVoice.Active or not Assigned(FNoteInstrument) then
    Exit;

  LAction := FNoteInstrument.NewNoteAction;
  if TTrackerGhostPool.IsDuplicate(LCheck, FNoteNumber, FSample, FNoteInstrument, ANote, ANewSample,
    FInstrument) then
  begin
    case LDuplicateAction of
      daCut:
        LAction := nnaCut;
      daOff:
        LAction := nnaOff;
      daFade:
        LAction := nnaFade;
    end;
  end;
  if LAction = nnaCut then
    Exit;

  LGhost := FGhosts.Capture(FVoice, FEnvelopes, FIndex, FNoteNumber, FNoteInstrument, FSample,
    ClampVolume(FVolume) / MAX_VOLUME, FFrequency, FPanning);
  if not Assigned(LGhost) then
    Exit;
  // The envelopes went with the note: the channel starts with new ones
  FEnvelopes := TTrackerNoteEnvelopes.Create(FModule.Format);
  case LAction of
    nnaOff:
      LGhost.Envelopes.KeyOff;
    nnaFade:
      LGhost.Envelopes.StartFade;
  end;
end;

procedure TTrackerChannel.UpdateVoice;
var
  LFrequency: Double;
begin
  if not Assigned(FSample) then
    Exit;

  LFrequency := FFrequency;
  if FVibratoDelta <> 0 then
  begin
    if IsLinear then
      LFrequency := LFrequency * Power(2, -FVibratoDelta / LINEAR_UNITS_PER_OCTAVE)
    else
      LFrequency := AMIGA_CONSTANT / Max(MIN_PERIOD, AMIGA_CONSTANT / LFrequency + FVibratoDelta);
  end;
  if FArpeggioSemitones <> 0 then
    LFrequency := LFrequency * Power(2, FArpeggioSemitones / 12);
  LFrequency := LFrequency * FEnvelopes.PitchFactor;

  FVoice.Increment := LFrequency / FSampleRate;
  FVoice.Volume := ClampVolume(FVolume + FTremoloDelta) / MAX_VOLUME * FGlobalVolume *
    FEnvelopes.VolumeFactor;
  FVoice.Panning := Max(0, Min(1, FEnvelopes.AdjustPanning(FPanning) / 255));
end;

end.
