{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the output of Windows of the tracker                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Tracker.WindowsOutput;

// No device is opened here: the tests never make a sound

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Tracker.Output.Intf;

type
  [TestFixture]
  [Category('tracker')]
  TTestTrackerWindowsOutput = class(TObject)
  public
    [Test]
    procedure DovrebbeDareUnDispositivoEUnLavoratore;
    [Test]
    procedure DovrebbeChiudereSenzaErroriUnDispositivoMaiAperto;
  end;

implementation

uses
  DelphiDoom.Tracker.ThreadWorker,
  DelphiDoom.Tracker.WaveOut,
  DelphiDoom.Tracker.WindowsOutput;

{ TTestTrackerWindowsOutput }

procedure TTestTrackerWindowsOutput.DovrebbeDareUnDispositivoEUnLavoratore;
var
  LOutputs: ITrackerOutputFactory;
  LDevice: ITrackerAudioDevice;
  LWorker: ITrackerWorker;
begin
  LOutputs := TTrackerWindowsOutputFactory.Create;
  LDevice := LOutputs.CreateDevice;
  LWorker := LOutputs.CreateWorker;

  Assert.IsTrue((LDevice as TObject) is TTrackerWaveOutDevice);
  Assert.IsTrue((LWorker as TObject) is TTrackerThreadWorker);
  Assert.IsFalse(LWorker.IsRunning);
end;

procedure TTestTrackerWindowsOutput.DovrebbeChiudereSenzaErroriUnDispositivoMaiAperto;
var
  LDevice: ITrackerAudioDevice;
begin
  LDevice := TTrackerWaveOutDevice.Create;
  LDevice.Close;
  LDevice := nil;
  Assert.Pass('closed');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTrackerWindowsOutput);

end.
