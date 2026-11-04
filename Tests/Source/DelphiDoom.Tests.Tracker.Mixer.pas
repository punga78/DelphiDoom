{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voice and of the mixer of the tracker              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Tracker.Mixer;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Tracker.Mixer,
  DelphiDoom.Tracker.Types,
  DelphiDoom.Tracker.Voice;

type
  [TestFixture]
  [Category('tracker')]
  TTestTrackerMixer = class(TObject)
  private
    FSample: TTrackerSample;
    FMixer: TTrackerMixer;
    FOutput: TArray<SmallInt>;
    function NewSample(const AValues: array of SmallInt): TTrackerSample;
    function Left(const AFrame: Integer): Integer;
    function Right(const AFrame: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestLaVoceSuonaIlCampioneInOrdine;
    [Test]
    procedure TestSenzaRipetizioneLaVoceSiFerma;
    [Test]
    procedure TestInterpolazioneLineare;
    [Test]
    procedure TestRipetizioneInAvanti;
    [Test]
    procedure TestRipetizioneAndataERitorno;
    [Test]
    procedure TestPannelloATuttaSinistraETuttaDestra;
    [Test]
    procedure TestIlVolumeScalaIlSegnale;
    [Test]
    procedure TestLeVociSiSommano;
    [Test]
    procedure TestIlGuadagnoPredefinitoDipendeDalNumeroDiVoci;
    [Test]
    procedure TestLUscitaVieneLimitata;
    [Test]
    procedure TestPartenzaDaUnaPosizione;
    [Test]
    procedure TestCampioneVuotoNonSuona;
  end;

implementation

{ TTestTrackerMixer }

procedure TTestTrackerMixer.Setup;
begin
  FMixer := TTrackerMixer.Create(8000, 2);
  FMixer.Gain := 1;
  SetLength(FOutput, 2 * 16);
end;

procedure TTestTrackerMixer.TearDown;
begin
  FMixer.Free;
  FSample.Free;
end;

function TTestTrackerMixer.NewSample(const AValues: array of SmallInt): TTrackerSample;
var
  LIndex: Integer;
begin
  FSample.Free;
  FSample := TTrackerSample.Create;
  SetLength(FSample.Data, Length(AValues));
  for LIndex := 0 to High(AValues) do
    FSample.Data[LIndex] := AValues[LIndex];
  Result := FSample;
end;

function TTestTrackerMixer.Left(const AFrame: Integer): Integer;
begin
  Result := FOutput[2 * AFrame];
end;

function TTestTrackerMixer.Right(const AFrame: Integer): Integer;
begin
  Result := FOutput[2 * AFrame + 1];
end;

procedure TTestTrackerMixer.TestLaVoceSuonaIlCampioneInOrdine;
begin
  FMixer.Voices[0].Start(NewSample([100, 200, 300, 400]));
  FMixer.Voices[0].Panning := 0;

  FMixer.Mix(FOutput, 0, 4);

  Assert.AreEqual(100, Left(0));
  Assert.AreEqual(200, Left(1));
  Assert.AreEqual(300, Left(2));
  Assert.AreEqual(400, Left(3));
end;

procedure TTestTrackerMixer.TestSenzaRipetizioneLaVoceSiFerma;
begin
  FMixer.Voices[0].Start(NewSample([100, 200, 300, 400]));
  FMixer.Voices[0].Panning := 0;

  FMixer.Mix(FOutput, 0, 8);

  Assert.AreEqual(400, Left(3));
  Assert.AreEqual(0, Left(4));
  Assert.AreEqual(0, Left(7));
  Assert.IsFalse(FMixer.Voices[0].Active);
end;

procedure TTestTrackerMixer.TestInterpolazioneLineare;
begin
  FMixer.Voices[0].Start(NewSample([0, 1000]));
  FMixer.Voices[0].Panning := 0;
  FMixer.Voices[0].Increment := 0.5;

  FMixer.Mix(FOutput, 0, 4);

  // 0, a half of the way, 1000, and then a half of the way to the silence
  Assert.AreEqual(0, Left(0));
  Assert.AreEqual(500, Left(1));
  Assert.AreEqual(1000, Left(2));
  Assert.AreEqual(500, Left(3));
end;

procedure TTestTrackerMixer.TestRipetizioneInAvanti;
begin
  NewSample([10, 20, 30, 40]);
  FSample.LoopType := tlForward;
  FSample.LoopStart := 1;
  FSample.LoopEnd := 3;
  FMixer.Voices[0].Start(FSample);
  FMixer.Voices[0].Panning := 0;

  FMixer.Mix(FOutput, 0, 8);

  // 10, 20, 30, then back to the start of the loop (20, 30, 20, 30...)
  Assert.AreEqual(10, Left(0));
  Assert.AreEqual(20, Left(1));
  Assert.AreEqual(30, Left(2));
  Assert.AreEqual(20, Left(3));
  Assert.AreEqual(30, Left(4));
  Assert.AreEqual(20, Left(5));
  Assert.IsTrue(FMixer.Voices[0].Active);
end;

procedure TTestTrackerMixer.TestRipetizioneAndataERitorno;
begin
  NewSample([0, 100, 200, 300]);
  FSample.LoopType := tlPingPong;
  FSample.LoopStart := 0;
  FSample.LoopEnd := 4;
  FMixer.Voices[0].Start(FSample);
  FMixer.Voices[0].Panning := 0;

  FMixer.Mix(FOutput, 0, 8);

  Assert.AreEqual(0, Left(0));
  Assert.AreEqual(300, Left(3));
  Assert.AreEqual(200, Left(4));
  Assert.AreEqual(100, Left(5));
  Assert.AreEqual(0, Left(6));
  Assert.AreEqual(100, Left(7));
end;

procedure TTestTrackerMixer.TestPannelloATuttaSinistraETuttaDestra;
begin
  FMixer.Voices[0].Start(NewSample([1000, 1000]));
  FMixer.Voices[0].Panning := 0;
  FMixer.Mix(FOutput, 0, 1);
  Assert.AreEqual(1000, Left(0));
  Assert.AreEqual(0, Right(0));

  FMixer.Voices[0].Start(FSample);
  FMixer.Voices[0].Panning := 1;
  FMixer.Mix(FOutput, 0, 1);
  Assert.AreEqual(0, Left(0));
  Assert.AreEqual(1000, Right(0));

  // In the middle each side gets a half
  FMixer.Voices[0].Start(FSample);
  FMixer.Voices[0].Panning := 0.5;
  FMixer.Mix(FOutput, 0, 1);
  Assert.AreEqual(500, Left(0));
  Assert.AreEqual(500, Right(0));
end;

procedure TTestTrackerMixer.TestIlVolumeScalaIlSegnale;
begin
  FMixer.Voices[0].Start(NewSample([1000, 1000]));
  FMixer.Voices[0].Panning := 0;
  FMixer.Voices[0].Volume := 0.25;

  FMixer.Mix(FOutput, 0, 1);

  Assert.AreEqual(250, Left(0));
end;

procedure TTestTrackerMixer.TestLeVociSiSommano;
begin
  FMixer.Voices[0].Start(NewSample([1000, 1000]));
  FMixer.Voices[0].Panning := 0;
  FMixer.Voices[1].Start(FSample);
  FMixer.Voices[1].Panning := 0;
  FMixer.Voices[1].Volume := 0.5;

  FMixer.Mix(FOutput, 0, 1);

  Assert.AreEqual(1500, Left(0));
end;

procedure TTestTrackerMixer.TestIlGuadagnoPredefinitoDipendeDalNumeroDiVoci;
var
  LMixer: TTrackerMixer;
begin
  LMixer := TTrackerMixer.Create(8000, 4);
  try
    Assert.AreEqual(Double(0.5), LMixer.Gain, 1E-9);
  finally
    LMixer.Free;
  end;
end;

procedure TTestTrackerMixer.TestLUscitaVieneLimitata;
begin
  FMixer.Voices[0].Start(NewSample([30000, 30000]));
  FMixer.Voices[0].Panning := 0;
  FMixer.Voices[1].Start(FSample);
  FMixer.Voices[1].Panning := 0;

  FMixer.Mix(FOutput, 0, 1);

  Assert.AreEqual(32767, Left(0));
end;

procedure TTestTrackerMixer.TestPartenzaDaUnaPosizione;
begin
  FMixer.Voices[0].Start(NewSample([100, 200, 300, 400]), 2);
  FMixer.Voices[0].Panning := 0;

  FMixer.Mix(FOutput, 0, 2);

  Assert.AreEqual(300, Left(0));
  Assert.AreEqual(400, Left(1));
end;

procedure TTestTrackerMixer.TestCampioneVuotoNonSuona;
begin
  FMixer.Voices[0].Start(NewSample([]));

  Assert.IsFalse(FMixer.Voices[0].Active);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTrackerMixer);

end.
