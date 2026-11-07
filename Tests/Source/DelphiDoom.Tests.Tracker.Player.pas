{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sequencer of the tracker                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Tracker.Player;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Tests.Tracker.ModuleBuilder,
  DelphiDoom.Tracker.Player,
  DelphiDoom.Tracker.Types;

type
  [TestFixture]
  [Category('tracker')]
  TTestTrackerPlayer = class(TObject)
  private
    FModule: TTrackerModule;
    FPlayer: TTrackerPlayer;
    FOutput: TArray<SmallInt>;
    // The sample rate is the center frequency of the sample, so that the
    // note C-4 advances by one sample per frame
    procedure Start(const ALooping: Boolean = False);
    procedure Render(const AFrames: Integer);
    function Left(const AFrame: Integer): Integer;
    function Right(const AFrame: Integer): Integer;
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestLaNotaAvviaIlCampione;
    [Test]
    procedure TestSilenzioPrimaDellaNota;
    [Test]
    procedure TestLaVelocitaDelMod;
    [Test]
    procedure TestIlTempoDelMod;
    [Test]
    procedure TestLaVelocitaDelloS3m;
    [Test]
    procedure TestVolumeDellaColonnaDelloS3m;
    [Test]
    procedure TestVolumeDellaColonnaDelloXm;
    [Test]
    procedure TestImpostaVolumeDelMod;
    [Test]
    procedure TestInterruzioneDelPattern;
    [Test]
    procedure TestSaltoDiPosizione;
    [Test]
    procedure TestFineDelBranoSenzaRipetizione;
    [Test]
    procedure TestIlBranoRicomincia;
    [Test]
    procedure TestLaNotaSpentaZittisceIlCanale;
    [Test]
    procedure TestPannelloDelCampione;
    [Test]
    procedure TestOttavaPiuAlta;
    [Test]
    procedure TestOrdineSaltatoEFineMarcata;
    [Test]
    procedure TestVolumeGlobale;
    [Test]
    procedure TestSenzaPatternNelleOrdiniFinisceSubito;
    [Test]
    procedure TestRigaVistaDueVolteFinisceIlBrano;
  end;

implementation

const
  SAMPLE_RATE = 8363;
  // 6 ticks of 167 frames: Round(8363 * 2.5 / 125) = 167
  ROW_FRAMES = 6 * 167;

{ TTestTrackerPlayer }

procedure TTestTrackerPlayer.TearDown;
begin
  FreeAndNil(FPlayer);
  FreeAndNil(FModule);
end;

procedure TTestTrackerPlayer.Start(const ALooping: Boolean);
begin
  FPlayer := TTrackerPlayer.Create(FModule, SAMPLE_RATE, ALooping);
end;

procedure TTestTrackerPlayer.Render(const AFrames: Integer);
begin
  SetLength(FOutput, 2 * AFrames);
  FPlayer.Render(FOutput, AFrames);
end;

function TTestTrackerPlayer.Left(const AFrame: Integer): Integer;
begin
  Result := FOutput[2 * AFrame];
end;

function TTestTrackerPlayer.Right(const AFrame: Integer): Integer;
begin
  Result := FOutput[2 * AFrame + 1];
end;

procedure TTestTrackerPlayer.TestLaNotaAvviaIlCampione;
var
  LFrame: Integer;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  Start;

  Render(32);

  // The square wave, in the middle: half in each side
  for LFrame := 0 to 31 do
  begin
    if (LFrame mod 16) < 8 then
      Assert.AreEqual(8192, Left(LFrame), 'frame ' + IntToStr(LFrame))
    else
      Assert.AreEqual(-8192, Left(LFrame), 'frame ' + IntToStr(LFrame));
    Assert.AreEqual(Left(LFrame), Right(LFrame));
  end;
end;

procedure TTestTrackerPlayer.TestSilenzioPrimaDellaNota;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 49, 1, 0, 0);
  Start;

  Render(ROW_FRAMES + 20);

  Assert.AreEqual(0, Left(0));
  Assert.AreEqual(0, Left(ROW_FRAMES - 1));
  Assert.AreEqual(8192, Left(ROW_FRAMES));
end;

procedure TTestTrackerPlayer.TestLaVelocitaDelMod;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  // Speed 3 on the row 0: a row is 3 ticks
  TTestModuleBuilder.SetCell(FModule, 0, 0, 0, 0, $0F, 3);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 49, 1, 0, 0);
  Start;

  Render(3 * 167 + 20);

  Assert.AreEqual(0, Left(3 * 167 - 1));
  Assert.AreEqual(8192, Left(3 * 167));
  Assert.AreEqual(3, FPlayer.Speed);
end;

procedure TTestTrackerPlayer.TestIlTempoDelMod;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  // Tempo 250: a tick is Round(8363 * 2.5 / 250) = 84 frames
  TTestModuleBuilder.SetCell(FModule, 0, 0, 0, 0, $0F, 250);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 49, 1, 0, 0);
  Start;

  Render(6 * 84 + 20);

  Assert.AreEqual(0, Left(6 * 84 - 1));
  Assert.AreEqual(8192, Left(6 * 84));
  Assert.AreEqual(250, FPlayer.Tempo);
end;

procedure TTestTrackerPlayer.TestLaVelocitaDelloS3m;
begin
  FModule := TTestModuleBuilder.SquareWave(tfS3m, 1);
  // The effect A (1) sets the speed
  TTestModuleBuilder.SetCell(FModule, 0, 0, 0, 0, 1, 3);
  TTestModuleBuilder.SetCell(FModule, 0, 1, 49, 1, 0, 0);
  Start;

  Render(3 * 167 + 20);

  Assert.AreEqual(0, Left(3 * 167 - 1));
  Assert.AreEqual(8192, Left(3 * 167));
end;

procedure TTestTrackerPlayer.TestVolumeDellaColonnaDelloS3m;
begin
  FModule := TTestModuleBuilder.SquareWave(tfS3m, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0, 32);
  Start;

  Render(4);

  Assert.AreEqual(4096, Left(0));
end;

procedure TTestTrackerPlayer.TestVolumeDellaColonnaDelloXm;
begin
  FModule := TTestModuleBuilder.SquareWave(tfXm, 1);
  // $10 + 32
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0, $30);
  Start;

  Render(4);

  Assert.AreEqual(4096, Left(0));
end;

procedure TTestTrackerPlayer.TestImpostaVolumeDelMod;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  // The effect C sets the volume to 16 of 64
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, $0C, 16);
  Start;

  Render(4);

  Assert.AreEqual(2048, Left(0));
end;

procedure TTestTrackerPlayer.TestInterruzioneDelPattern;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 2);
  // Pattern break (D) on the row 0 of the first pattern: the next pattern
  // starts after one row only
  TTestModuleBuilder.SetCell(FModule, 0, 0, 0, 0, $0D, 0);
  TTestModuleBuilder.SetCell(FModule, 1, 0, 49, 1, 0, 0);
  Start;

  Render(ROW_FRAMES + 20);

  Assert.AreEqual(0, Left(ROW_FRAMES - 1));
  Assert.AreEqual(8192, Left(ROW_FRAMES));
end;

procedure TTestTrackerPlayer.TestSaltoDiPosizione;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 3);
  // Position jump (B) to the order 2: the order 1 is not played
  TTestModuleBuilder.SetCell(FModule, 0, 0, 0, 0, $0B, 2);
  TTestModuleBuilder.SetCell(FModule, 1, 0, 49, 1, 0, 0);
  TTestModuleBuilder.SetCell(FModule, 2, 1, 49, 1, 0, 0);
  Start;

  Render(2 * ROW_FRAMES + 20);

  Assert.AreEqual(0, Left(ROW_FRAMES - 1));
  Assert.AreEqual(0, Left(2 * ROW_FRAMES - 1));
  Assert.AreEqual(8192, Left(2 * ROW_FRAMES));
  Assert.AreEqual(2, FPlayer.OrderIndex);
end;

procedure TTestTrackerPlayer.TestFineDelBranoSenzaRipetizione;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  Start;

  Render(4 * ROW_FRAMES + 100);

  Assert.AreEqual(8192, Left(4 * ROW_FRAMES - 1));
  Assert.AreEqual(0, Left(4 * ROW_FRAMES));
  Assert.AreEqual(0, Left(4 * ROW_FRAMES + 99));
  Assert.IsTrue(FPlayer.Finished);
end;

procedure TTestTrackerPlayer.TestIlBranoRicomincia;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  TTestModuleBuilder.SetCell(FModule, 0, 2, TRACKER_NOTE_OFF, 0, 0, 0);
  Start(True);

  Render(4 * ROW_FRAMES + 20);

  // Silence from the note off to the end, then the song starts again
  Assert.AreEqual(8192, Left(2 * ROW_FRAMES - 1));
  Assert.AreEqual(0, Left(2 * ROW_FRAMES));
  Assert.AreEqual(0, Left(4 * ROW_FRAMES - 1));
  Assert.AreEqual(8192, Left(4 * ROW_FRAMES));
  Assert.IsFalse(FPlayer.Finished);
end;

procedure TTestTrackerPlayer.TestLaNotaSpentaZittisceIlCanale;
begin
  FModule := TTestModuleBuilder.SquareWave(tfS3m, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  TTestModuleBuilder.SetCell(FModule, 0, 1, TRACKER_NOTE_CUT, 0, 0, 0);
  Start;

  Render(2 * ROW_FRAMES);

  // The last frame of the first row is still the note
  Assert.AreNotEqual(0, Left(ROW_FRAMES - 1));
  Assert.AreEqual(0, Left(ROW_FRAMES));
end;

procedure TTestTrackerPlayer.TestPannelloDelCampione;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  FModule.Samples[0].Panning := 0;
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  Start;

  Render(4);

  Assert.AreEqual(16384, Left(0));
  Assert.AreEqual(0, Right(0));
end;

procedure TTestTrackerPlayer.TestOttavaPiuAlta;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  // C-5 is an octave above: two samples go by in each frame
  TTestModuleBuilder.SetCell(FModule, 0, 0, 61, 1, 0, 0);
  Start;

  Render(8);

  Assert.AreEqual(8192, Left(0));
  Assert.AreEqual(8192, Left(3));
  Assert.AreEqual(-8192, Left(4));
  Assert.AreEqual(-8192, Left(7));
end;

procedure TTestTrackerPlayer.TestOrdineSaltatoEFineMarcata;
begin
  FModule := TTestModuleBuilder.SquareWave(tfS3m, 2);
  SetLength(FModule.Orders, 4);
  // Order 0, a gap (254), order 1 and the end (255)
  FModule.Orders[0] := 0;
  FModule.Orders[1] := 254;
  FModule.Orders[2] := 1;
  FModule.Orders[3] := 255;
  TTestModuleBuilder.SetCell(FModule, 1, 0, 49, 1, 0, 0);
  Start;

  Render(8 * ROW_FRAMES);

  Assert.AreEqual(0, Left(4 * ROW_FRAMES - 1));
  Assert.AreEqual(8192, Left(4 * ROW_FRAMES));
  Assert.AreEqual(8192, Left(8 * ROW_FRAMES - 1));
  Assert.IsTrue(FPlayer.Finished);
end;

procedure TTestTrackerPlayer.TestVolumeGlobale;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  FModule.GlobalVolume := 64;
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  Start;

  Render(4);

  Assert.AreEqual(4096, Left(0));
end;

procedure TTestTrackerPlayer.TestSenzaPatternNelleOrdiniFinisceSubito;
begin
  FModule := TTestModuleBuilder.SquareWave(tfS3m, 1);
  FModule.Orders[0] := 255;
  Start;

  Render(10);

  Assert.IsTrue(FPlayer.Finished);
  Assert.AreEqual(0, Left(5));
end;

procedure TTestTrackerPlayer.TestRigaVistaDueVolteFinisceIlBrano;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  // Position jump to the same order: the row 0 would be played again and again
  TTestModuleBuilder.SetCell(FModule, 0, 0, 0, 0, $0B, 0);
  Start;

  Render(3 * ROW_FRAMES);

  Assert.IsTrue(FPlayer.Finished);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTrackerPlayer);

end.
