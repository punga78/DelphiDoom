{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the sound calls on the      }
{  sound system of Framework\Audio (device and clock of its own tests) and the   }
{  messages of the precompiler on the console of the host                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.ClientSound;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Audio.Q3.Intf, DelphiDoom.Audio.Q3.SoundSystem, DelphiDoom.Tests.Audio.Q3.Fakes;

type
  [TestFixture]
  [Category('Q3Host')]
  TTestQ3ClientSound = class
  strict private
    FClock: TQ3FakeClock;
    FClockIntf: IQ3SoundClock;
    FDevice: TQ3FakeDevice;
    FDeviceIntf: IQ3SoundDevice;
    FSystem: TQ3SoundSystem;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlSuonoRegistratoDovrebbeAvereLoStessoNumeroEPartire;
    [Test]
    procedure LaMusicaDiSottofondoNonDovrebbeFareNulla;
    [Test]
    procedure IMessaggiDelPrecompilatoreDovrebberoArrivareAllaConsole;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Audio.Q3.Factory, DelphiDoom.Scanner.Q3.Intf, DelphiDoom.Q3Host.Client.Types, DelphiDoom.Q3Host.ClientSoundAdapter,
  DelphiDoom.Q3Host.ClientScriptLog, DelphiDoom.Tests.Q3Host.Support;

procedure TTestQ3ClientSound.Setup;
begin
  FClock := TQ3FakeClock.Create;
  FClockIntf := FClock;
  FDevice := TQ3FakeDevice.Create;
  FDeviceIntf := FDevice;
  FDevice.Configure(2, 8192, 16, 22050, 1024);
  FSystem := TQ3SoundSystemFactory.CreateSoundSystem(FDeviceIntf, FClockIntf, nil, nil);
  FSystem.Init;
  FSystem.BeginRegistration;
end;

procedure TTestQ3ClientSound.TearDown;
begin
  FSystem.Free;
  FDeviceIntf := nil;
  FClockIntf := nil;
end;

procedure TTestQ3ClientSound.IlSuonoRegistratoDovrebbeAvereLoStessoNumeroEPartire;
var
  LSamples: TArray<SmallInt>;
  LHandle: Integer;
  LAdapter: TQ3SoundSystemAdapter;
  LAdapterIntf: IInterface;
begin
  SetLength(LSamples, 200);
  LHandle := FSystem.Registry.AddSound('sound/test.wav', LSamples, 200);
  LAdapter := TQ3SoundSystemAdapter.Create(FSystem);
  LAdapterIntf := LAdapter;
  // a name the registry knows gives its number, and the compressed flag changes nothing
  Assert.AreEqual(LHandle, LAdapter.RegisterSound('sound/test.wav', False));
  Assert.AreEqual(LHandle, LAdapter.RegisterSound('sound/test.wav', True));
  Assert.IsFalse(FSystem.Pool.ScanChannelStarts);
  LAdapter.StartLocalSound(LHandle, 0);
  Assert.IsTrue(FSystem.Pool.ScanChannelStarts);
  LAdapter.ClearLoopingSounds(True);
  LAdapter.StopLoopingSound(3);
end;

procedure TTestQ3ClientSound.LaMusicaDiSottofondoNonDovrebbeFareNulla;
var
  LAdapter: TQ3SoundSystemAdapter;
  LAdapterIntf: IInterface;
begin
  LAdapter := TQ3SoundSystemAdapter.Create(FSystem);
  LAdapterIntf := LAdapter;
  LAdapter.StartBackgroundTrack('music/a.wav', 'music/b.wav');
  LAdapter.StopBackgroundTrack;
  Assert.IsFalse(FSystem.Pool.ScanChannelStarts);
end;

procedure TTestQ3ClientSound.IMessaggiDelPrecompilatoreDovrebberoArrivareAllaConsole;
var
  LConsole: TQ3RecordingConsole;
  LConsoleIntf: IInterface;
  LLog: IQ3ScriptLog;
begin
  LConsole := TQ3RecordingConsole.Create(nil);
  LConsoleIntf := LConsole;
  LLog := TQ3HostScriptLog.Create(LConsole);
  LLog.Print(2, 'file x, line 3: oops'#10);
  Assert.AreEqual(1, LConsole.Texts.Count);
  Assert.AreEqual('file x, line 3: oops'#10, LConsole.Texts[0]);
  // no console: nothing to say it to, and no error
  LLog := TQ3HostScriptLog.Create(nil);
  LLog.Print(2, 'ignored');
end;

end.
