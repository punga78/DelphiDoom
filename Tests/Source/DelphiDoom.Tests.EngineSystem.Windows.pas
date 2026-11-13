{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the engine system library - the Windows adapters and   }
{  the factory                                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.EngineSystem.Windows;

// Only what can be tried without a sound card, a window or a crash: the commands that MCI refuses for a
// file and a device that do not exist, the provider of MikMod with a fake, the factory.

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf, DelphiDoom.EngineSystem.Intf,
  DelphiDoom.Tests.EngineSystem.Fakes;

type
  [TestFixture]
  [Category('enginesystem')]
  TTestWindowsAdapters = class(TObject)
  public
    [Test]
    procedure DovrebbeDareUnErroreSeIlFileNonEsiste;
    [Test]
    procedure DovrebbeDareErroriPerUnaPerifericaCheNonCe;
    [Test]
    procedure DovrebbeUsareIlClientDelProvider;
    [Test]
    procedure DovrebbeLasciareIlClientDelProvider;
    [Test]
    procedure DovrebbeInstallareELevareIlLoggerDiCrash;
  end;

  [TestFixture]
  [Category('enginesystem')]
  TTestEngineSystemFactory = class(TObject)
  public
    [Test]
    procedure DovrebbeFareLeClassiDiWindows;
    [Test]
    procedure DovrebbeRifiutareParametriNulli;
  end;

implementation

uses
  DelphiDoom.CommandLine.Factory, DelphiDoom.Mikmod.Provider, DelphiDoom.Mikmod.Intf,
  DelphiDoom.EngineSystem.Factory, DelphiDoom.EngineSystem.MikModProviderSource,
  DelphiDoom.EngineSystem.WindowsMciSequencer, DelphiDoom.EngineSystem.WindowsCrashLogger;

{ TTestWindowsAdapters }

procedure TTestWindowsAdapters.DovrebbeDareUnErroreSeIlFileNonEsiste;
var
  LSequencer: IMciSequencer;
  LDevice: Cardinal;
begin
  LSequencer := TWindowsMciSequencer.Create;
  Assert.IsTrue(LSequencer.Open('C:\enginesystem\no_such_song.mid', LDevice) <> 0);
  Assert.AreEqual(Cardinal(0), LDevice);
end;

procedure TTestWindowsAdapters.DovrebbeDareErroriPerUnaPerifericaCheNonCe;
var
  LSequencer: IMciSequencer;
  LIsMapper: Boolean;
begin
  LSequencer := TWindowsMciSequencer.Create;
  // device 0 is no device: MCI answers with an error code and nothing happens
  Assert.IsTrue(LSequencer.QueryMapperPort(0, LIsMapper) <> 0);
  Assert.IsFalse(LIsMapper);
  Assert.IsTrue(LSequencer.Play(0, 0) <> 0);
  Assert.IsTrue(LSequencer.SeekToStart(0, 0) <> 0);
  LSequencer.Stop(0);
  LSequencer.Pause(0);
  LSequencer.Resume(0);
  LSequencer.Close(0);
end;

procedure TTestWindowsAdapters.DovrebbeUsareIlClientDelProvider;
var
  LMikMod: TRecordingMikMod;
  LMikModRef: IMikMod;
  LSource: IMikModClientSource;
begin
  LMikMod := TRecordingMikMod.Create;
  LMikModRef := LMikMod;
  TMikModProvider.Use(LMikModRef);
  try
    LSource := TMikModProviderSource.Create;
    LSource.Client.Initialize(44100, True, True, True, 3);
    Assert.AreEqual('initialize 44100 True True True 3 0', LMikMod.Calls[0]);
    // the same client every time, until it is released
    Assert.IsTrue(LSource.Client = LSource.Client);
  finally
    TMikModProvider.Release;
  end;
end;

procedure TTestWindowsAdapters.DovrebbeLasciareIlClientDelProvider;
var
  LMikMod: TRecordingMikMod;
  LMikModRef: IMikMod;
  LSource: IMikModClientSource;
begin
  LMikMod := TRecordingMikMod.Create;
  LMikModRef := LMikMod;
  TMikModProvider.Use(LMikModRef);
  try
    LSource := TMikModProviderSource.Create;
    LSource.Client.Initialize(44100, True, True, True, 3);
    LSource.Release;
    // the client was shut down when it was freed
    Assert.AreEqual('shutdown', LMikMod.Calls[LMikMod.Calls.Count - 1]);
  finally
    TMikModProvider.Release;
  end;
end;

procedure TTestWindowsAdapters.DovrebbeInstallareELevareIlLoggerDiCrash;
begin
  // the default file is crash.txt next to the executable: it is only written by a crash
  TWindowsCrashLogger.Install;
  TWindowsCrashLogger.Install;
  TWindowsCrashLogger.Uninstall;
  TWindowsCrashLogger.Uninstall;
  Assert.IsFalse(FileExists(ExtractFilePath(ParamStr(0)) + 'crash.txt'));
end;

{ TTestEngineSystemFactory }

procedure TTestEngineSystemFactory.DovrebbeFareLeClassiDiWindows;
var
  LLog: ILog;
begin
  LLog := TRecordingLog.Create;
  Assert.IsNotNull(TEngineSystemFactory.CreateLegacyMidiPlayer(LLog));
  Assert.IsNotNull(TEngineSystemFactory.CreateModuleMusicPlayer(LLog,
    function: NativeUInt
    begin
      Result := 0;
    end));
  Assert.IsNotNull(TEngineSystemFactory.CreateNetCommandLineReader(
    TCommandLineFactory.CreateCommandLine(nil), LLog));
end;

procedure TTestEngineSystemFactory.DovrebbeRifiutareParametriNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TEngineSystemFactory.CreateLegacyMidiPlayer(nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TEngineSystemFactory.CreateFatalErrorHandler(nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TEngineSystemFactory.CreateShutdownSequence(nil, nil, nil);
    end, EArgumentNilException);
end;

end.
