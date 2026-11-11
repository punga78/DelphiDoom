{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - a simple software synthesizer for the MIDI  }
{  music (no sound bank: a few waveforms with an envelope, noise for the drums) }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.MidiSynth;

// The noise of the drums is a linear congruential generator that wraps around on purpose
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.XcomAudio.Intf;

type
  /// <summary>
  ///   IXcomMidiSynth with 32 voices. The sound of a melodic patch is chosen by its family (piano, organ, strings,
  ///   brass...) among four waveforms and an envelope; channel 10 plays the drums as noise or a falling sine. It is not
  ///   a General MIDI sound bank (the music of GM.CAT is written for one): it makes the notes, the volumes, the pans
  ///   and the pitch bends of the song audible without a device or a bank
  /// </summary>
  TXcomMidiSynth = class(TInterfacedObject, IXcomMidiSynth)
  strict private
    type
      TWaveform = (wfSine, wfTriangle, wfSaw, wfSquare);
      TChannelState = record
        Program_: Integer;
        Volume: Integer;
        Expression: Integer;
        Pan: Integer;
        Bend: Integer;
      end;
      TVoice = record
        Active: Boolean;
        Released: Boolean;
        Peaked: Boolean;
        Channel: Integer;
        Note: Integer;
        Gain: Single;
        Phase: Double;
        Increment: Double;
        Waveform: TWaveform;
        Drum: Boolean;
        Level: Single;
        Attack: Single;
        Decay: Single;
        Sustain: Single;
        ReleaseRate: Single;
        Age: Integer;
        Noise: Cardinal;
      end;
    const
      VOICE_COUNT = 32;
      CHANNEL_COUNT = 16;
    var
      FRate: Integer;
      FChannels: array[0..CHANNEL_COUNT - 1] of TChannelState;
      FVoices: array[0..VOICE_COUNT - 1] of TVoice;
      FClock: Integer;
    procedure NoteOn(AChannel, ANote, AVelocity: Integer);
    procedure NoteOff(AChannel, ANote: Integer);
    procedure AllNotes(AChannel: Integer; AImmediately: Boolean);
    procedure Control(AChannel, AController, AValue: Integer);
    function FreeVoice: Integer;
    procedure Configure(var AVoice: TVoice; AProgram: Integer);
    function BendedIncrement(const AVoice: TVoice): Double;
    function Sample(var AVoice: TVoice): Single;
  public
    /// <param name="ARate">The rate of the mixer</param>
    constructor Create(ARate: Integer);
    procedure Send(AStatus, AData1, AData2: Byte);
    procedure Reset;
    procedure Render(ABuffer: PSmallInt; ABytes: Integer);
    /// <summary>The voices that sound now (for the tests)</summary>
    function ActiveVoices: Integer;
  end;

implementation

uses
  System.Math, DelphiDoom.XcomAudio.Types;

constructor TXcomMidiSynth.Create(ARate: Integer);
begin
  inherited Create;
  if ARate <= 0 then
    raise EArgumentOutOfRangeException.Create('ARate');
  FRate := ARate;
  Reset;
end;

procedure TXcomMidiSynth.Reset;
var
  LIndex: Integer;
begin
  for LIndex := 0 to VOICE_COUNT - 1 do
    FVoices[LIndex].Active := False;
  for LIndex := 0 to CHANNEL_COUNT - 1 do
  begin
    FChannels[LIndex].Program_ := 0;
    FChannels[LIndex].Volume := 100;
    FChannels[LIndex].Expression := 127;
    FChannels[LIndex].Pan := 64;
    FChannels[LIndex].Bend := 8192;
  end;
end;

function TXcomMidiSynth.ActiveVoices: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to VOICE_COUNT - 1 do
    if FVoices[LIndex].Active then
      Inc(Result);
end;

function TXcomMidiSynth.FreeVoice: Integer;
var
  LIndex: Integer;
  LOldest: Integer;
begin
  for LIndex := 0 to VOICE_COUNT - 1 do
    if not FVoices[LIndex].Active then
      Exit(LIndex);
  // none free: a released voice first, then the oldest
  Result := -1;
  LOldest := MaxInt;
  for LIndex := 0 to VOICE_COUNT - 1 do
    if FVoices[LIndex].Released and (FVoices[LIndex].Age < LOldest) then
    begin
      LOldest := FVoices[LIndex].Age;
      Result := LIndex;
    end;
  if Result >= 0 then
    Exit;
  for LIndex := 0 to VOICE_COUNT - 1 do
    if FVoices[LIndex].Age < LOldest then
    begin
      LOldest := FVoices[LIndex].Age;
      Result := LIndex;
    end;
end;

procedure TXcomMidiSynth.Configure(var AVoice: TVoice; AProgram: Integer);
var
  LFamily: Integer;
begin
  LFamily := AProgram div 8;
  AVoice.Attack := 0.02;
  AVoice.Decay := 0.4;
  AVoice.Sustain := 0.3;
  AVoice.ReleaseRate := 0.05;
  case LFamily of
    0:
      begin
        AVoice.Waveform := wfTriangle;
        AVoice.Decay := 0.6;
        AVoice.Sustain := 0.1;
      end;
    1:
      begin
        AVoice.Waveform := wfSine;
        AVoice.Decay := 1.5;
        AVoice.Sustain := 0;
      end;
    2:
      begin
        AVoice.Waveform := wfSquare;
        AVoice.Decay := 0.0;
        AVoice.Sustain := 0.8;
      end;
    3:
      begin
        AVoice.Waveform := wfTriangle;
        AVoice.Decay := 0.8;
        AVoice.Sustain := 0.2;
      end;
    4:
      begin
        AVoice.Waveform := wfSaw;
        AVoice.Decay := 0.5;
        AVoice.Sustain := 0.5;
      end;
    5, 6:
      begin
        AVoice.Waveform := wfSaw;
        AVoice.Attack := 0.15;
        AVoice.Decay := 0.0;
        AVoice.Sustain := 0.8;
        AVoice.ReleaseRate := 0.2;
      end;
    7, 8:
      begin
        AVoice.Waveform := wfSquare;
        AVoice.Attack := 0.05;
        AVoice.Decay := 0.0;
        AVoice.Sustain := 0.7;
      end;
    9:
      begin
        AVoice.Waveform := wfSine;
        AVoice.Decay := 0.0;
        AVoice.Sustain := 0.8;
      end;
    10:
      begin
        AVoice.Waveform := wfSaw;
        AVoice.Decay := 0.0;
        AVoice.Sustain := 0.7;
      end;
    11, 12:
      begin
        AVoice.Waveform := wfSine;
        AVoice.Attack := 0.3;
        AVoice.Decay := 0.0;
        AVoice.Sustain := 0.8;
        AVoice.ReleaseRate := 0.4;
      end;
  else
    begin
      AVoice.Waveform := wfTriangle;
      AVoice.Decay := 0.7;
      AVoice.Sustain := 0.2;
    end;
  end;
end;

procedure TXcomMidiSynth.NoteOn(AChannel, ANote, AVelocity: Integer);
var
  LIndex: Integer;
begin
  if AVelocity = 0 then
  begin
    NoteOff(AChannel, ANote);
    Exit;
  end;
  LIndex := FreeVoice;
  Inc(FClock);
  FVoices[LIndex] := Default(TVoice);
  FVoices[LIndex].Active := True;
  FVoices[LIndex].Channel := AChannel;
  FVoices[LIndex].Note := ANote;
  FVoices[LIndex].Gain := AVelocity / 127;
  FVoices[LIndex].Age := FClock;
  FVoices[LIndex].Noise := Cardinal(Int64(ANote) * 2654435761) or 1;
  FVoices[LIndex].Drum := AChannel = 9;
  if FVoices[LIndex].Drum then
  begin
    FVoices[LIndex].Waveform := wfSine;
    FVoices[LIndex].Attack := 0.001;
    // the kicks fall, the hats are short, the rest is a noise burst
    case ANote of
      35, 36:
        FVoices[LIndex].Decay := 0.18;
      42, 44, 46:
        FVoices[LIndex].Decay := 0.06;
    else
      FVoices[LIndex].Decay := 0.16;
    end;
    FVoices[LIndex].Sustain := 0;
    FVoices[LIndex].ReleaseRate := 0.02;
    FVoices[LIndex].Increment := 70.0 / FRate;
  end
  else
  begin
    Configure(FVoices[LIndex], FChannels[AChannel].Program_);
    FVoices[LIndex].Increment := 440.0 * Power(2, (ANote - 69) / 12) / FRate;
  end;
end;

procedure TXcomMidiSynth.NoteOff(AChannel, ANote: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to VOICE_COUNT - 1 do
    if FVoices[LIndex].Active and (not FVoices[LIndex].Released) and (FVoices[LIndex].Channel = AChannel) and
      (FVoices[LIndex].Note = ANote) then
    begin
      // the drums ring out by themselves
      if not FVoices[LIndex].Drum then
        FVoices[LIndex].Released := True;
      Exit;
    end;
end;

procedure TXcomMidiSynth.AllNotes(AChannel: Integer; AImmediately: Boolean);
var
  LIndex: Integer;
begin
  for LIndex := 0 to VOICE_COUNT - 1 do
    if FVoices[LIndex].Active and (FVoices[LIndex].Channel = AChannel) then
      if AImmediately then
        FVoices[LIndex].Active := False
      else
        FVoices[LIndex].Released := True;
end;

procedure TXcomMidiSynth.Control(AChannel, AController, AValue: Integer);
begin
  case AController of
    7:
      FChannels[AChannel].Volume := AValue;
    10:
      FChannels[AChannel].Pan := AValue;
    11:
      FChannels[AChannel].Expression := AValue;
    120:
      AllNotes(AChannel, True);
    121:
      begin
        FChannels[AChannel].Expression := 127;
        FChannels[AChannel].Bend := 8192;
      end;
    123:
      AllNotes(AChannel, False);
  end;
end;

procedure TXcomMidiSynth.Send(AStatus, AData1, AData2: Byte);
var
  LChannel: Integer;
begin
  LChannel := AStatus and $0F;
  case AStatus and $F0 of
    $80:
      NoteOff(LChannel, AData1 and $7F);
    $90:
      NoteOn(LChannel, AData1 and $7F, AData2 and $7F);
    $B0:
      Control(LChannel, AData1 and $7F, AData2 and $7F);
    $C0:
      FChannels[LChannel].Program_ := AData1 and $7F;
    $E0:
      FChannels[LChannel].Bend := (AData1 and $7F) or ((AData2 and $7F) shl 7);
  end;
end;

function TXcomMidiSynth.BendedIncrement(const AVoice: TVoice): Double;
begin
  // two semitones up or down
  Result := AVoice.Increment * Power(2, ((FChannels[AVoice.Channel].Bend - 8192) / 8192) * 2 / 12);
end;

function TXcomMidiSynth.Sample(var AVoice: TVoice): Single;
var
  LWave: Single;
  LStep: Single;
  LPhase: Single;
  LTarget: Single;
begin
  // the envelope: attack, decay to the sustain, release
  if AVoice.Decay > 0 then
    LTarget := 1
  else
    LTarget := AVoice.Sustain;
  if AVoice.Released then
  begin
    LStep := 1 / (AVoice.ReleaseRate * FRate);
    AVoice.Level := AVoice.Level - LStep;
    if AVoice.Level <= 0 then
    begin
      AVoice.Active := False;
      Exit(0);
    end;
  end
  else if (not AVoice.Peaked) and (AVoice.Level < LTarget) then
  begin
    AVoice.Level := Min(LTarget, AVoice.Level + 1 / (AVoice.Attack * FRate));
    if AVoice.Level >= LTarget then
      AVoice.Peaked := True;
  end
  else if (AVoice.Decay > 0) and (AVoice.Level > AVoice.Sustain) then
    AVoice.Level := Max(AVoice.Sustain, AVoice.Level - (1 - AVoice.Sustain) / (AVoice.Decay * FRate));
  if AVoice.Drum then
  begin
    // a drum that has reached its sustain (zero) is over
    if (AVoice.Level <= 0.001) and (AVoice.Sustain = 0) then
    begin
      AVoice.Active := False;
      Exit(0);
    end;
    if AVoice.Note in [35, 36] then
    begin
      AVoice.Increment := AVoice.Increment * 0.99995;
      LWave := Sin(AVoice.Phase * 2 * Pi);
    end
    else
    begin
      AVoice.Noise := AVoice.Noise * 1664525 + 1013904223;
      LWave := ((AVoice.Noise shr 8) and $FFFF) / 32768 - 1;
    end;
    AVoice.Phase := AVoice.Phase + AVoice.Increment;
    Exit(LWave * AVoice.Level * AVoice.Gain);
  end;
  LPhase := Frac(AVoice.Phase);
  case AVoice.Waveform of
    wfSine:
      LWave := Sin(LPhase * 2 * Pi);
    wfTriangle:
      LWave := 4 * Abs(LPhase - 0.5) - 1;
    wfSaw:
      LWave := 2 * LPhase - 1;
  else
    if LPhase < 0.5 then
      LWave := 1
    else
      LWave := -1;
  end;
  AVoice.Phase := AVoice.Phase + BendedIncrement(AVoice);
  Result := LWave * AVoice.Level * AVoice.Gain;
end;

procedure TXcomMidiSynth.Render(ABuffer: PSmallInt; ABytes: Integer);
var
  LFrames: Integer;
  LFrame: Integer;
  LVoice: Integer;
  LLeft: Single;
  LRight: Single;
  LValue: Single;
  LPan: Single;
  LVolume: Single;
  LSum: Integer;
begin
  if (ABytes <= 0) or ((ABytes and 3) <> 0) then
    raise EXcomAudioException.Create(SXcomBufferNotWhole);
  LFrames := ABytes div 4;
  for LFrame := 0 to LFrames - 1 do
  begin
    LLeft := 0;
    LRight := 0;
    for LVoice := 0 to VOICE_COUNT - 1 do
      if FVoices[LVoice].Active then
      begin
        LValue := Sample(FVoices[LVoice]);
        if not FVoices[LVoice].Active then
          Continue;
        with FChannels[FVoices[LVoice].Channel] do
        begin
          LVolume := (Volume / 127) * (Expression / 127);
          LPan := Pan / 127;
        end;
        // the gain puts the music of GM.CAT near the level of the Adlib music (RMS about 1000 at the volume of the game)
        LValue := LValue * LVolume * 0.3;
        LLeft := LLeft + LValue * Cos(LPan * Pi / 2);
        LRight := LRight + LValue * Sin(LPan * Pi / 2);
      end;
    LSum := Integer(ABuffer^) + Round(LLeft * 32767);
    ABuffer^ := SmallInt(EnsureRange(LSum, -32768, 32767));
    Inc(ABuffer);
    LSum := Integer(ABuffer^) + Round(LRight * 32767);
    ABuffer^ := SmallInt(EnsureRange(LSum, -32768, 32767));
    Inc(ABuffer);
  end;
end;

end.
