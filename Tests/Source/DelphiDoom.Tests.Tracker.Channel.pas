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
  FPlayer.Free;
  FModule.Free;
end;

procedure TTestTrackerChannel.Start;
begin
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
