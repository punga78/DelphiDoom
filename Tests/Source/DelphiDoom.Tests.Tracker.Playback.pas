{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the playback of the tracker, on a fake output          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Tracker.Playback;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Tests.Tracker.FakeOutput,
  DelphiDoom.Tracker.Output.Intf,
  DelphiDoom.Tracker.Playback,
  DelphiDoom.Tracker.Types;

type
  [TestFixture]
  [Category('tracker')]
  TTestTrackerPlayback = class(TObject)
  private
    FModule: TTrackerModule;
    FOutputs: TFakeTrackerOutputFactory;
    FOutputsIntf: ITrackerOutputFactory;
    FPlayback: TTrackerPlayback;
    function Device: TFakeTrackerAudioDevice;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnUscitaMancante;
    [Test]
    procedure DovrebbeFinireDaSolaUnBranoSenzaRipetizione;
    [Test]
    procedure DovrebbeAspettareIlDispositivoPrimaDiScrivere;
    [Test]
    procedure DovrebbeNonSuonareSenzaDispositivo;
    [Test]
    procedure DovrebbeFermarsiQuandoRichiesto;
    [Test]
    procedure DovrebbeMettereInPausaERiprendereIlDispositivo;
    [Test]
    procedure DovrebbeScalareIlSegnaleColVolume;
    [Test]
    procedure DovrebbeEssereInRiproduzioneSoloDuranteIlLavoro;
    [Test]
    procedure DovrebbeFermareIlBranoPrimaDiRicominciare;
  end;

implementation

uses
  DelphiDoom.Tests.Tracker.ModuleBuilder;

const
  // The note C-4 advances by one sample of the square wave per frame
  SAMPLE_RATE = 8363;
  // A tenth of a second, two channels
  BUFFER_SAMPLES = 2 * (SAMPLE_RATE div 10);
  BUFFER_COUNT = 4;

{ TTestTrackerPlayback }

procedure TTestTrackerPlayback.Setup;
begin
  FModule := TTestModuleBuilder.SquareWave(tfMod, 1);
  TTestModuleBuilder.SetCell(FModule, 0, 0, 49, 1, 0, 0);
  FOutputs := TFakeTrackerOutputFactory.Create;
  FOutputsIntf := FOutputs;
  FPlayback := TTrackerPlayback.Create(FModule, SAMPLE_RATE, FOutputsIntf);
end;

procedure TTestTrackerPlayback.TearDown;
begin
  FreeAndNil(FPlayback);
  FOutputsIntf := nil;
  FOutputs := nil;
  FreeAndNil(FModule);
end;

function TTestTrackerPlayback.Device: TFakeTrackerAudioDevice;
begin
  Result := FOutputs.Device;
end;

procedure TTestTrackerPlayback.DovrebbeRifiutareUnUscitaMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TTrackerPlayback.Create(FModule, SAMPLE_RATE, nil).Free;
    end, EArgumentNilException);
end;

// A device that has always played everything: the old loop never looked at
// the end of the song in that case and went round for ever (the fake stops it)
procedure TTestTrackerPlayback.DovrebbeFinireDaSolaUnBranoSenzaRipetizione;
begin
  FPlayback.Play(False);

  Assert.AreEqual(1, Device.OpenCalls);
  Assert.AreEqual(SAMPLE_RATE, Device.OpenedRate);
  Assert.AreEqual(BUFFER_COUNT, Device.OpenedBuffers);
  Assert.AreEqual(1, Device.CloseCalls);
  Assert.IsFalse(FPlayback.IsPlaying);
  // 4 rows of 6 ticks of 167 frames: the fifth buffer reaches the end of the song,
  // then the four buffers are played out
  Assert.AreEqual(5, Length(Device.Written));
  Assert.AreEqual(5, Device.IsDoneCalls);
  Assert.AreEqual(BUFFER_SAMPLES, Length(Device.Written[0]));
end;

procedure TTestTrackerPlayback.DovrebbeAspettareIlDispositivoPrimaDiScrivere;
begin
  Device.BusyChecks := 2;

  FPlayback.Play(False);

  // Every answer "not done" is followed by a wait
  Assert.AreEqual(5, Length(Device.Written));
  Assert.AreEqual(Device.IsDoneCalls - 5, Device.WaitCalls);
  Assert.AreEqual(10, Device.WaitCalls);
end;

procedure TTestTrackerPlayback.DovrebbeNonSuonareSenzaDispositivo;
begin
  Device.OpenResult := False;

  FPlayback.Play(True);

  Assert.AreEqual(1, Device.OpenCalls);
  Assert.AreEqual(0, Length(Device.Written));
  Assert.AreEqual(0, Device.CloseCalls);
  Assert.IsFalse(FPlayback.IsPlaying);
end;

procedure TTestTrackerPlayback.DovrebbeFermarsiQuandoRichiesto;
begin
  Device.BusyChecks := 1;
  Device.OnWait :=
    procedure
    begin
      if Device.WaitCalls = 20 then
        FPlayback.Stop;
    end;

  // A song that starts again: only Stop ends it
  FPlayback.Play(True);

  Assert.AreEqual(20, Device.WaitCalls);
  Assert.AreEqual(1, Device.CloseCalls);
  Assert.IsTrue(Length(Device.Written) > 5);
end;

procedure TTestTrackerPlayback.DovrebbeMettereInPausaERiprendereIlDispositivo;
begin
  Device.BusyChecks := 1;
  Device.OnWait :=
    procedure
    begin
      case Device.WaitCalls of
        2: FPlayback.Pause;
        4: FPlayback.Resume;
        6: FPlayback.Pause;
        8: FPlayback.Stop;
      end;
    end;

  FPlayback.Play(True);

  Assert.AreEqual(2, Device.PauseCalls);
  Assert.AreEqual(1, Device.RestartCalls);
  Assert.IsTrue(FPlayback.Paused);
end;

procedure TTestTrackerPlayback.DovrebbeScalareIlSegnaleColVolume;
var
  LFull: Integer;
begin
  FPlayback.Play(False);
  LFull := Device.Written[0][0];
  Assert.AreEqual(8192, LFull);

  FOutputs.Device.Written := nil;
  FPlayback.Volume := 64;
  FPlayback.Play(False);

  Assert.AreEqual(4096, Integer(Device.Written[0][0]));
  Assert.AreEqual(4096, Integer(Device.Written[0][1]));
  Assert.AreEqual(-4096, Integer(Device.Written[0][2 * 8]));
end;

procedure TTestTrackerPlayback.DovrebbeEssereInRiproduzioneSoloDuranteIlLavoro;
var
  LPlayingInside: Boolean;
begin
  LPlayingInside := False;
  Device.BusyChecks := 1;
  Device.OnWait :=
    procedure
    begin
      LPlayingInside := FPlayback.IsPlaying;
    end;

  Assert.IsFalse(FPlayback.IsPlaying);
  FPlayback.Play(False);

  Assert.IsTrue(LPlayingInside);
  Assert.IsFalse(FPlayback.IsPlaying);
end;

procedure TTestTrackerPlayback.DovrebbeFermareIlBranoPrimaDiRicominciare;
begin
  FPlayback.Play(False);
  FPlayback.Play(False);

  Assert.AreEqual(2, FOutputs.Worker.StartCalls);
  // Play waits for the song before; Stop in the destructor comes later
  Assert.AreEqual(2, FOutputs.Worker.WaitForCalls);
  Assert.AreEqual(2, FOutputs.DeviceCalls);
  Assert.AreEqual(2, Device.CloseCalls);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTrackerPlayback);

end.
