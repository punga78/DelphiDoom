{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the effects of the channels of the tracker             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Tracker.Channel;

interface

uses
  System.Math,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Tests.Tracker.ModuleBuilder,
  DelphiDoom.Tracker.Player,
  DelphiDoom.Tracker.Types;

type
  [TestFixture]
  [Category('tracker')]
  TTestTrackerChannel = class(TObject)
  private
    FModule: TTrackerModule;
    FPlayer: TTrackerPlayer;
    FOutput: TArray<SmallInt>;
    FRendered: Integer;
    procedure Start;
    // Renders, from where the player is, up to the middle of the tick ATick
    // of the row ARow counted from the start of the song
    procedure RenderTo(const ARow, ATick: Integer);
    procedure Render(const AFrames: Integer);
    function Left(const AFrame: Integer): Integer;
    function Right(const AFrame: Integer): Integer;
    function Increment: Double;
    class function AmigaFrequency(const APeriod: Double): Double; static;
    class function MakeEnvelope(const ATicks, AValues: array of Integer): TTrackerEnvelope; static;
    function VoiceVolume: Double;
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestVolumeSlideDelMod;
    [Test]
    procedure TestVolumeSlideSuDelloS3m;
    [Test]
    procedure TestVolumeSlideFineDelloS3m;
    [Test]
    procedure TestVolumeSlideNonScendeSottoZero;
    [Test]
    procedure TestPortamentoSuDelMod;
    [Test]
    procedure TestPortamentoGiuDelMod;
    [Test]
    procedure TestPortamentoFineDelMod;
    [Test]
    procedure TestPortamentoFineEExtraFineDelloS3m;
    [Test]
    procedure TestPortamentoLinearDiIt;
    [Test]
    procedure TestPortamentoRicordaIlParametro;
    [Test]
    procedure TestTonePortamentoNonRiavviaIlCampione;
    [Test]
    procedure TestTonePortamentoSiFermaAlBersaglio;
    [Test]
    procedure TestArpeggio;
    [Test]
    procedure TestVibrato;
    [Test]
    procedure TestTremolo;
    [Test]
    procedure TestPannelloImpostato;
    [Test]
    procedure TestSampleOffset;
    [Test]
    procedure TestNotaRitardata;
    [Test]
    procedure TestNotaTagliata;
    [Test]
    procedure TestRiavvioDelloS3m;
    [Test]
    procedure TestRiavvioDelMod;
    [Test]
    procedure TestCicloDelPattern;
    [Test]
    procedure TestRitardoDelPattern;
    [Test]
    procedure TestVolumeGlobaleDellXm;
    [Test]
    procedure TestKeyOffDellXm;
    [Test]
    procedure TestPortamentoDellaColonnaDelVolumeDiIt;
    [Test]
    procedure TestInviluppoDelVolumeSegueITick;
    [Test]
    procedure TestInviluppoDelVolumeInTuttiITickDiUnaRiga;
    [Test]
    procedure TestKeyOffDellXmConInviluppoSfuma;
    [Test]
    procedure TestKeyOffDellXmSenzaInviluppoTaglia;
    [Test]
    procedure TestKeyOffDiItSenzaSfumaturaMantieneIlVolume;
    [Test]
    procedure TestKeyOffRilasciaIlSostegno;
    [Test]
    procedure TestInviluppoDelPanning;
    [Test]
    procedure TestNuovaNotaRiavviaGliInviluppi;
    [Test]
    procedure TestNnaTagliaDiDefaultLaNotaPrecedente;
    [Test]
    procedure TestNnaContinuaLasciaLaNotaInSottofondo;
    [Test]
    procedure TestNnaSfumaFaScendereIlVolumeDellaNotaInSottofondo;
    [Test]
    procedure TestNnaInSottofondoNonSegueLeNoteDelCanale;
    [Test]
    procedure TestNnaSoloInIt;
    [Test]
    procedure TestControlloDuplicatiDiNotaTagliaLaNotaPrecedente;
    [Test]
    procedure TestControlloDuplicatiConNotaDiversaNonTaglia;
    [Test]
    procedure TestInviluppoDelPitchSpostaLaFrequenza;
    [Test]
    procedure TestVibratoConOndaQuadra;
    [Test]
    procedure TestVibratoConOndaARampa;
    [Test]
    procedure TestVibratoConOndaCheNonRipartePerOgniNota;
    [Test]
    procedure TestVibratoConOndaCheRipartePerOgniNota;
    [Test]
    procedure TestTremoloConOndaQuadra;
    [Test]
    procedure TestVibratoDellaColonnaDelVolumeDellXm;
    [Test]
    procedure TestVibratoCasualeSempreUguale;
  end;

implementation

const
  SAMPLE_RATE = 8363;
  TICK_FRAMES = 167;
  TICKS_PER_ROW = 6;
  ROW_FRAMES = TICK_FRAMES * TICKS_PER_ROW;
  AMIGA_CONSTANT = 8363.0 * 1712.0;

{ TTestTrackerChannel }

procedure TTestTrackerChannel.TearDown;
begin
  FreeAndNil(FPlayer);
  FreeAndNil(FModule);
end;

procedure TTestTrackerChannel.Start;
begin
  // DUnitX uses one instance of the fixture for all the tests
  FRendered := 0;
  FOutput := nil;
  FPlayer := TTrackerPlayer.Create(FModule, SAMPLE_RATE, False);
end;

procedure TTestTrackerChannel.Render(const AFrames: Integer);
begin
  SetLength(FOutput, 2 * AFrames);
  FPlayer.Render(FOutput, AFrames);
  Inc(FRendered, AFrames);
end;

procedure TTestTrackerChannel.RenderTo(const ARow, ATick: Integer);
var
  LTarget: Integer;
begin
  LTarget := ARow * ROW_FRAMES + ATick * TICK_FRAMES + 10;
  if LTarget > FRendered then
    Render(LTarget - FRendered);
end;

function TTestTrackerChannel.Left(const AFrame: Integer): Integer;
begin
  Result := FOutput[2 * AFrame];
end;

function TTestTrackerChannel.Right(const AFrame: Integer): Integer;
begin
  Result := FOutput[2 * AFrame + 1];
end;

function TTestTrackerChannel.Increment: Double;
begin
  Result := FPlayer.Mixer.Voices[0].Increment;
end;

class function TTestTrackerChannel.AmigaFrequency(const APeriod: Double): Double;
begin
  Result := AMIGA_CONSTANT / APeriod;
end;

procedure TTestTrackerChannel.TestVolumeSlideDelMod;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  // A02: down by 2 in each tick after the first
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $0A, $02);
  Start;

  RenderTo(0, 5);

  Assert.AreEqual(64 - 5 * 2, FPlayer.Channels[0].Volume);
end;

procedure TTestTrackerChannel.TestVolumeSlideSuDelloS3m;
begin
  FModule := TTestModuleBuilder.SquareWave(tfS3m, 1);
  // Volume 20, then D30: up by 3 in each tick after the first
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 4, $30, 20);
  Start;

  RenderTo(0, 5);

  Assert.AreEqual(20 + 5 * 3, FPlayer.Channels[0].Volume);
end;

procedure TTestTrackerChannel.TestVolumeSlideFineDelloS3m;
begin
  FModule := TTestModuleBuilder.SquareWave(tfS3m, 1);
  // DF2 is a fine slide down by 2, in the first tick only
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 4, $F2);
  Start;

  RenderTo(0, 4);

  Assert.AreEqual(62, FPlayer.Channels[0].Volume);
end;

procedure TTestTrackerChannel.TestVolumeSlideNonScendeSottoZero;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $0C, 4);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 0, 0, $0A, $0F);
  Start;

  RenderTo(1, 5);

  Assert.AreEqual(0, FPlayer.Channels[0].Volume);
end;

procedure TTestTrackerChannel.TestPortamentoSuDelMod;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $01, $04);
  Start;

  RenderTo(0, 5);

  // Five ticks of 4 (16 in the units of Scream Tracker) from the period 1712
  Assert.AreEqual(AmigaFrequency(1712 - 5 * 16), FPlayer.Channels[0].Frequency, 0.01);
end;

procedure TTestTrackerChannel.TestPortamentoGiuDelMod;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $02, $04);
  Start;

  RenderTo(0, 5);

  Assert.AreEqual(AmigaFrequency(1712 + 5 * 16), FPlayer.Channels[0].Frequency, 0.01);
end;

procedure TTestTrackerChannel.TestPortamentoFineDelMod;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  // E13: a fine slide by 3, in the first tick only
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $0E, $13);
  Start;

  RenderTo(0, 4);

  Assert.AreEqual(AmigaFrequency(1712 - 12), FPlayer.Channels[0].Frequency, 0.01);
end;

procedure TTestTrackerChannel.TestPortamentoFineEExtraFineDelloS3m;
begin
  FModule := TTestModuleBuilder.SquareWave(tfS3m, 1);
  // FF3: fine up by 3 (12 units); EE2: extra fine down by 2 (2 units)
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 6, $F3);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 49, 1, 5, $E2);
  Start;

  RenderTo(0, 4);
  Assert.AreEqual(AmigaFrequency(1712 - 12), FPlayer.Channels[0].Frequency, 0.01);

  RenderTo(1, 4);
  Assert.AreEqual(AmigaFrequency(1712 + 2), FPlayer.Channels[0].Frequency, 0.01);
end;

procedure TTestTrackerChannel.TestPortamentoLinearDiIt;
begin
  FModule := TTestModuleBuilder.SquareWave(tfIt, 1);
  FModule.LinearSlides := True;
  // F08: up by 8 (32 linear units) in each tick after the first
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 6, 8);
  Start;

  RenderTo(0, 5);

  Assert.AreEqual(8363 * Power(2, 5 * 32 / 768), FPlayer.Channels[0].Frequency, 0.01);
end;

procedure TTestTrackerChannel.TestPortamentoRicordaIlParametro;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $01, $04);
  // Parameter 0: the last one
  TTestModuleBuilder.SetCell(FModule, 0, 1, 0, 0, $01, $00);
  Start;

  RenderTo(1, 5);

  Assert.AreEqual(AmigaFrequency(1712 - 10 * 16), FPlayer.Channels[0].Frequency, 0.01);
end;

procedure TTestTrackerChannel.TestTonePortamentoNonRiavviaIlCampione;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  // C-5 with the effect 3: the note is the target, nothing restarts
  TTestModuleBuilder.SetCell(FModule, 0, 1, 61, 0, $03, $08);
  Start;

  RenderTo(1, 5);

  Assert.AreEqual(AmigaFrequency(1712 - 5 * 32), FPlayer.Channels[0].Frequency, 0.01);
  Assert.AreEqual(64, FPlayer.Channels[0].Volume);
end;

procedure TTestTrackerChannel.TestTonePortamentoSiFermaAlBersaglio;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  // A fast slide to C-5: the target is the period 856 (an octave)
  TTestModuleBuilder.SetCell(FModule, 0, 1, 61, 0, $03, $FF);
  Start;

  RenderTo(1, 5);

  Assert.AreEqual(8363 * 2.0, FPlayer.Channels[0].Frequency, 0.01);
end;

procedure TTestTrackerChannel.TestArpeggio;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $00, $37);
  Start;

  // The first tick has the note, the second 3 semitones up, the third 7
  Render(10);
  Assert.AreEqual(1.0, Increment, 1E-9);
  RenderTo(0, 1);
  Assert.AreEqual(Power(2, 3 / 12), Increment, 1E-9);
  RenderTo(0, 2);
  Assert.AreEqual(Power(2, 7 / 12), Increment, 1E-9);
  RenderTo(0, 3);
  Assert.AreEqual(1.0, Increment, 1E-9);
end;

procedure TTestTrackerChannel.TestVibrato;
var
  LExpected: Double;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $04, $48);
  Start;

  RenderTo(0, 1);

  // Speed 4 puts the position at 4, where the table of the sine has 97; the
  // depth is 8: 97 * 8 / 128 = 6.0625 in the units of ProTracker, four times
  // that in the units of Scream Tracker
  LExpected := AMIGA_CONSTANT / (1712 + 97 * 8 / 128 * 4) / SAMPLE_RATE;
  Assert.AreEqual(LExpected, Increment, 1E-6);
  // The base note does not change
  Assert.AreEqual(8363.0, FPlayer.Channels[0].Frequency, 1E-6);
end;

procedure TTestTrackerChannel.TestTremolo;
begin
  FModule := TTestModuleBuilder.SquareWave(tfS3m, 1);
  // The volume 32, then R48
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 18, $48, 32);
  Start;

  RenderTo(0, 1);

  // Speed 4: the table of the sine has 97, the depth is 8: 97 * 8 div 64 = 12
  Assert.AreEqual(Double((32 + 97 * 8 div 64) / 64), FPlayer.Mixer.Voices[0].Volume, 1E-9);
end;

procedure TTestTrackerChannel.TestPannelloImpostato;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $08, $00);
  Start;

  Render(4);

  Assert.AreEqual(16384, Left(0));
  Assert.AreEqual(0, Right(0));
end;

procedure TTestTrackerChannel.TestSampleOffset;
var
  LIndex: Integer;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  // A sample of 600 values (the index), without loop
  SetLength(FModule.Samples[0].Data, 600);
  for LIndex := 0 to 599 do
    FModule.Samples[0].Data[LIndex] := LIndex;
  FModule.Samples[0].LoopType := tlNone;
  // 901: the start is the sample 256
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $09, $01);
  Start;

  Render(4);

  // The values 256 and 258, a half of each (in the middle)
  Assert.AreEqual(128, Left(0));
  Assert.AreEqual(129, Left(2));
end;

procedure TTestTrackerChannel.TestNotaRitardata;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  // ED3: the note starts in the tick 3
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $0E, $D3);
  Start;

  Render(3 * TICK_FRAMES + 10);

  Assert.AreEqual(0, Left(3 * TICK_FRAMES - 1));
  Assert.AreEqual(8192, Left(3 * TICK_FRAMES));
end;

procedure TTestTrackerChannel.TestNotaTagliata;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  // EC2: the volume goes to zero in the tick 2
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $0E, $C2);
  Start;

  Render(3 * TICK_FRAMES);

  Assert.AreNotEqual(0, Left(2 * TICK_FRAMES - 1));
  Assert.AreEqual(0, Left(2 * TICK_FRAMES));
end;

procedure TTestTrackerChannel.TestRiavvioDelloS3m;
begin
  FModule := TTestModuleBuilder.SquareWave(tfS3m, 1);
  // Q01: the sample restarts in each tick; at the frame 3 of the tick 1 it is
  // at the position 3 (positive), without the restart it would be at 10
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 17, $01);
  Start;

  Render(TICK_FRAMES + 10);

  Assert.AreEqual(8192, Left(TICK_FRAMES + 3));
  Assert.AreEqual(8192, Left(TICK_FRAMES));
end;

procedure TTestTrackerChannel.TestRiavvioDelMod;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  // E91: the sample restarts in each tick
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $0E, $91);
  Start;

  Render(TICK_FRAMES + 10);

  Assert.AreEqual(8192, Left(TICK_FRAMES + 3));
end;

procedure TTestTrackerChannel.TestCicloDelPattern;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  // E60 marks the start of the loop; E62 on the row 2 repeats the rows 0 to 2
  // two more times; the note on the row 3 comes after nine rows
  TTestModuleBuilder.SetCell(FModule, 0, 0, 0, 0, $0E, $60);
  TTestModuleBuilder.SetCell(FModule, 0, 2, 0, 0, $0E, $62);
  TTestModuleBuilder.SetCell(FModule, 0, 3, 49, 1, 0, 0);
  Start;

  Render(9 * ROW_FRAMES + 20);

  Assert.AreEqual(0, Left(9 * ROW_FRAMES - 1));
  Assert.AreEqual(8192, Left(9 * ROW_FRAMES));
  Assert.IsFalse(FPlayer.Finished);
end;

procedure TTestTrackerChannel.TestRitardoDelPattern;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  // EE1: the row 0 lasts twice
  TTestModuleBuilder.SetCell(FModule, 0, 0, 0, 0, $0E, $E1);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 49, 1, 0, 0);
  Start;

  Render(2 * ROW_FRAMES + 20);

  Assert.AreEqual(0, Left(2 * ROW_FRAMES - 1));
  Assert.AreEqual(8192, Left(2 * ROW_FRAMES));
end;

procedure TTestTrackerChannel.TestVolumeGlobaleDellXm;
begin
  FModule := TTestModuleBuilder.SquareWave(tfXm, 1);
  // G32: the global volume is 32 of 64
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 16, 32);
  Start;

  Render(4);

  Assert.AreEqual(4096, Left(0));
  Assert.AreEqual(64, FPlayer.GlobalVolume);
end;

procedure TTestTrackerChannel.TestKeyOffDellXm;
begin
  FModule := TTestModuleBuilder.SquareWave(tfXm, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 20, 0);
  Start;

  Render(4);

  Assert.AreEqual(0, Left(0));
end;

class function TTestTrackerChannel.MakeEnvelope(const ATicks, AValues: array of Integer): TTrackerEnvelope;
var
  LIndex: Integer;
begin
  Result := Default(TTrackerEnvelope);
  Result.Enabled := True;
  SetLength(Result.Points, Length(ATicks));
  for LIndex := 0 to High(ATicks) do
  begin
    Result.Points[LIndex].Tick := ATicks[LIndex];
    Result.Points[LIndex].Value := AValues[LIndex];
  end;
end;

function TTestTrackerChannel.VoiceVolume: Double;
begin
  Result := FPlayer.Mixer.Voices[0].Volume;
end;

procedure TTestTrackerChannel.TestInviluppoDelVolumeSegueITick;
var
  LBase: Double;
begin
  FModule := TTestModuleBuilder.SquareWave(tfXm, 1);
  // From 64 at the first tick to 0 at the 12th
  FModule.Instruments[0].VolumeEnvelope := MakeEnvelope([0, 12], [64, 0]);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  Start;
  RenderTo(0, 0);
  LBase := VoiceVolume;

  RenderTo(0, 3);

  Assert.AreEqual(LBase * 0.75, VoiceVolume, 0.0001);
end;

procedure TTestTrackerChannel.TestInviluppoDelVolumeInTuttiITickDiUnaRiga;
var
  LBase: Double;
begin
  FModule := TTestModuleBuilder.SquareWave(tfXm, 1);
  FModule.Instruments[0].VolumeEnvelope := MakeEnvelope([0, 12], [64, 0]);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  Start;
  RenderTo(0, 0);
  LBase := VoiceVolume;

  // The first tick of the second row is the 7th tick of the note
  RenderTo(1, 0);

  Assert.AreEqual(LBase * 0.5, VoiceVolume, 0.0001);
end;

procedure TTestTrackerChannel.TestKeyOffDellXmConInviluppoSfuma;
var
  LBase: Double;
begin
  FModule := TTestModuleBuilder.SquareWave(tfXm, 1);
  FModule.Instruments[0].VolumeEnvelope := MakeEnvelope([0, 1000], [64, 64]);
  // 1024 * 2 of 65536 in each tick
  FModule.Instruments[0].FadeOut := 1024;
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  TTestModuleBuilder.SetCell(FModule, 0, 1, TRACKER_NOTE_OFF, 0, 0, 0);
  Start;
  RenderTo(0, 0);
  LBase := VoiceVolume;

  RenderTo(1, 0);
  Assert.AreEqual(LBase, VoiceVolume, 0.0001);
  RenderTo(1, 3);

  Assert.AreEqual(LBase * (65536 - 3 * 2048) / 65536, VoiceVolume, 0.0001);
end;

procedure TTestTrackerChannel.TestKeyOffDellXmSenzaInviluppoTaglia;
begin
  FModule := TTestModuleBuilder.SquareWave(tfXm, 1);
  FModule.Instruments[0].FadeOut := 1;
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  TTestModuleBuilder.SetCell(FModule, 0, 1, TRACKER_NOTE_OFF, 0, 0, 0);
  Start;

  RenderTo(1, 0);

  Assert.AreEqual(0.0, VoiceVolume, 0.0001);
end;

procedure TTestTrackerChannel.TestKeyOffDiItSenzaSfumaturaMantieneIlVolume;
var
  LBase: Double;
begin
  FModule := TTestModuleBuilder.SquareWave(tfIt, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  TTestModuleBuilder.SetCell(FModule, 0, 1, TRACKER_NOTE_OFF, 0, 0, 0);
  Start;
  RenderTo(0, 0);
  LBase := VoiceVolume;

  RenderTo(2, 0);

  Assert.AreEqual(LBase, VoiceVolume, 0.0001);
end;

procedure TTestTrackerChannel.TestKeyOffRilasciaIlSostegno;
var
  LBase: Double;
  LEnvelope: TTrackerEnvelope;
begin
  FModule := TTestModuleBuilder.SquareWave(tfXm, 1);
  // 64 for 6 ticks, then it goes down to 0 at the tick 18; sustained at the first point
  LEnvelope := MakeEnvelope([0, 6, 18], [64, 64, 0]);
  LEnvelope.Sustain := True;
  LEnvelope.SustainStart := 1;
  LEnvelope.SustainEnd := 1;
  FModule.Instruments[0].VolumeEnvelope := LEnvelope;
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  TTestModuleBuilder.SetCell(FModule, 0, 2, TRACKER_NOTE_OFF, 0, 0, 0);
  Start;
  RenderTo(0, 0);
  LBase := VoiceVolume;

  // The sustain holds the volume for the rows 1 and 2
  RenderTo(2, 0);
  Assert.AreEqual(LBase, VoiceVolume, 0.0001);
  // After the key off the envelope goes down from the tick 6: 3 ticks later it is at 3/12 down
  RenderTo(2, 3);

  Assert.AreEqual(LBase * (1 - 3 / 12), VoiceVolume, 0.0001);
end;

procedure TTestTrackerChannel.TestInviluppoDelPanning;
begin
  FModule := TTestModuleBuilder.SquareWave(tfXm, 1);
  // 64 is the full right
  FModule.Instruments[0].PanningEnvelope := MakeEnvelope([0, 100], [64, 64]);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  Start;

  RenderTo(0, 0);

  Assert.AreEqual(1.0, FPlayer.Mixer.Voices[0].Panning, 0.01);
end;

procedure TTestTrackerChannel.TestNuovaNotaRiavviaGliInviluppi;
var
  LBase: Double;
begin
  FModule := TTestModuleBuilder.SquareWave(tfXm, 1);
  FModule.Instruments[0].VolumeEnvelope := MakeEnvelope([0, 12], [64, 0]);
  FModule.Instruments[0].FadeOut := 1024;
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  TTestModuleBuilder.SetCell(FModule, 0, 1, TRACKER_NOTE_OFF, 0, 0, 0);
  TTestModuleBuilder.SetCell(FModule, 0, 2, 49, 1, 0, 0);
  Start;
  RenderTo(0, 0);
  LBase := VoiceVolume;

  RenderTo(2, 0);

  Assert.AreEqual(LBase, VoiceVolume, 0.0001);
end;

procedure TTestTrackerChannel.TestNnaTagliaDiDefaultLaNotaPrecedente;
begin
  FModule := TTestModuleBuilder.SquareWave(tfIt, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 52, 1, 0, 0);
  Start;

  RenderTo(1, 0);

  Assert.IsTrue(FPlayer.Mixer.Voices[0].Active);
  Assert.IsFalse(FPlayer.Mixer.Voices[1].Active);
end;

procedure TTestTrackerChannel.TestNnaContinuaLasciaLaNotaInSottofondo;
begin
  FModule := TTestModuleBuilder.SquareWave(tfIt, 1);
  FModule.Instruments[0].NewNoteAction := nnaContinue;
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 52, 1, 0, 0);
  Start;
  RenderTo(0, 0);

  RenderTo(1, 0);

  Assert.IsTrue(FPlayer.Mixer.Voices[0].Active);
  Assert.IsTrue(FPlayer.Mixer.Voices[1].Active);
  // The old note goes on at its own frequency, the new one is a minor third higher
  Assert.AreEqual(FPlayer.Mixer.Voices[0].Increment * Power(2, -3 / 12), FPlayer.Mixer.Voices[1].Increment,
    0.0001);
end;

procedure TTestTrackerChannel.TestNnaSfumaFaScendereIlVolumeDellaNotaInSottofondo;
var
  LBase: Double;
begin
  FModule := TTestModuleBuilder.SquareWave(tfIt, 1);
  FModule.Instruments[0].NewNoteAction := nnaFade;
  // 16 * 64 of 65536 in each tick
  FModule.Instruments[0].FadeOut := 16;
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 52, 1, 0, 0);
  Start;
  RenderTo(0, 0);
  LBase := FPlayer.Mixer.Voices[0].Volume;

  RenderTo(1, 3);

  Assert.AreEqual(LBase * (65536 - 3 * 1024) / 65536, FPlayer.Mixer.Voices[1].Volume, 0.0001);
  Assert.AreEqual(LBase, FPlayer.Mixer.Voices[0].Volume, 0.0001);
end;

procedure TTestTrackerChannel.TestNnaInSottofondoNonSegueLeNoteDelCanale;
var
  LBackground: Double;
begin
  FModule := TTestModuleBuilder.SquareWave(tfIt, 1);
  FModule.LinearSlides := True;
  FModule.Instruments[0].NewNoteAction := nnaContinue;
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  // The second note slides up (F08): the first does not
  TTestModuleBuilder.SetCell(FModule, 0, 1, 52, 1, 6, 8);
  Start;
  RenderTo(1, 0);
  LBackground := FPlayer.Mixer.Voices[1].Increment;

  RenderTo(1, 5);

  Assert.AreEqual(LBackground, FPlayer.Mixer.Voices[1].Increment, 0.0001);
  Assert.IsTrue(FPlayer.Mixer.Voices[0].Increment > LBackground * Power(2, 3 / 12));
end;

procedure TTestTrackerChannel.TestNnaSoloInIt;
begin
  FModule := TTestModuleBuilder.SquareWave(tfXm, 1);
  FModule.Instruments[0].NewNoteAction := nnaContinue;
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 52, 1, 0, 0);
  Start;

  RenderTo(1, 0);

  Assert.IsFalse(FPlayer.Mixer.Voices[1].Active);
end;

procedure TTestTrackerChannel.TestControlloDuplicatiDiNotaTagliaLaNotaPrecedente;
begin
  FModule := TTestModuleBuilder.SquareWave(tfIt, 1);
  FModule.Instruments[0].NewNoteAction := nnaContinue;
  // Check of the notes, action cut: the same note twice leaves nothing in the background
  FModule.Instruments[0].DuplicateCheckType := 1;
  FModule.Instruments[0].DuplicateCheckAction := 0;
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 49, 1, 0, 0);
  Start;

  RenderTo(1, 0);

  Assert.IsFalse(FPlayer.Mixer.Voices[1].Active);
end;

procedure TTestTrackerChannel.TestControlloDuplicatiConNotaDiversaNonTaglia;
begin
  FModule := TTestModuleBuilder.SquareWave(tfIt, 1);
  FModule.Instruments[0].NewNoteAction := nnaContinue;
  FModule.Instruments[0].DuplicateCheckType := 1;
  FModule.Instruments[0].DuplicateCheckAction := 0;
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 52, 1, 0, 0);
  Start;

  RenderTo(1, 0);

  Assert.IsTrue(FPlayer.Mixer.Voices[1].Active);
end;

procedure TTestTrackerChannel.TestInviluppoDelPitchSpostaLaFrequenza;
begin
  FModule := TTestModuleBuilder.SquareWave(tfIt, 1);
  // 64 is the top of the envelope: sixteen semitones up
  FModule.Instruments[0].PitchEnvelope := MakeEnvelope([0, 100], [64, 64]);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  Start;

  RenderTo(0, 0);

  Assert.AreEqual(FPlayer.Channels[0].Frequency * Power(2, 16 / 12) / SAMPLE_RATE,
    FPlayer.Mixer.Voices[0].Increment, 0.0001);
end;

procedure TTestTrackerChannel.TestVibratoConOndaQuadra;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  // E42: the square wave, then 4 8: speed 4, depth 8
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $0E, $42);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 0, 0, $04, $48);
  Start;

  RenderTo(1, 1);

  // The square wave is 255 in all the first half: 255 * 8 / 128 = 15.9375
  Assert.AreEqual(AMIGA_CONSTANT / (1712 + 255 * 8 / 128 * 4) / SAMPLE_RATE, Increment, 1E-6);
end;

procedure TTestTrackerChannel.TestVibratoConOndaARampa;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $0E, $41);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 0, 0, $04, $48);
  Start;

  RenderTo(1, 1);

  // At the position 4 the ramp is 4 * 8 = 32
  Assert.AreEqual(AMIGA_CONSTANT / (1712 + 32 * 8 / 128 * 4) / SAMPLE_RATE, Increment, 1E-6);
end;

procedure TTestTrackerChannel.TestVibratoConOndaCheNonRipartePerOgniNota;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  // E44: the sine that does not start again with a note
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $0E, $44);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 0, 0, $04, $48);
  TTestModuleBuilder.SetCell(FModule, 0, 2, 49, 1, $04, $48);
  Start;

  RenderTo(2, 1);

  // 5 ticks of row 1 (position 20) and one of row 2: position 24, where the sine has 180
  Assert.AreEqual(AMIGA_CONSTANT / (1712 + 180 * 8 / 128 * 4) / SAMPLE_RATE, Increment, 1E-6);
end;

procedure TTestTrackerChannel.TestVibratoConOndaCheRipartePerOgniNota;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $0E, $40);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 0, 0, $04, $48);
  TTestModuleBuilder.SetCell(FModule, 0, 2, 49, 1, $04, $48);
  Start;

  RenderTo(2, 1);

  // The note starts the wave again: position 4, where the sine has 97
  Assert.AreEqual(AMIGA_CONSTANT / (1712 + 97 * 8 / 128 * 4) / SAMPLE_RATE, Increment, 1E-6);
end;

procedure TTestTrackerChannel.TestTremoloConOndaQuadra;
begin
  FModule := TTestModuleBuilder.SquareWave(tfS3m, 1);
  // The volume 32 with S42 (the square wave of the tremolo), then R48
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 19, $42, 32);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 0, 0, 18, $48);
  Start;

  RenderTo(1, 1);

  // 255 * 8 div 64 = 31
  Assert.AreEqual(Double((32 + 255 * 8 div 64) / 64), FPlayer.Mixer.Voices[0].Volume, 1E-9);
end;

procedure TTestTrackerChannel.TestVibratoDellaColonnaDelVolumeDellXm;
begin
  FModule := TTestModuleBuilder.SquareWave(tfXm, 1);
  // The column A4 sets the speed, B8 gives the depth and starts the vibrato
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0, $A4);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 0, 0, 0, 0, $B8);
  Start;

  RenderTo(1, 1);

  Assert.AreEqual(AMIGA_CONSTANT / (1712 + 97 * 8 / 128 * 4) / SAMPLE_RATE, Increment, 1E-6);
end;

procedure TTestTrackerChannel.TestVibratoCasualeSempreUguale;
var
  LFirst: Double;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $0E, $43);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 0, 0, $04, $4F);
  Start;
  RenderTo(1, 3);
  LFirst := Increment;
  FPlayer.Free;
  FPlayer := nil;

  Start;
  RenderTo(1, 3);

  Assert.AreEqual(LFirst, Increment, 1E-12);
  Assert.IsTrue(LFirst <> AMIGA_CONSTANT / 1712 / SAMPLE_RATE);
end;

procedure TTestTrackerChannel.TestPortamentoDellaColonnaDelVolumeDiIt;
begin
  FModule := TTestModuleBuilder.SquareWave(tfIt, 1);
  FModule.LinearSlides := True;
  // The column 115 + 2 is a slide up with the parameter 2 * 4, like F08
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0, 117);
  Start;

  RenderTo(0, 5);

  Assert.AreEqual(8363 * Power(2, 5 * 8 * 4 / 768), FPlayer.Channels[0].Frequency, 0.01);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTrackerChannel);

end.
