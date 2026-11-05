{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Mikmod library (DUnitX)                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Mikmod;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Mikmod.Intf in '..\Libs\Mikmod\DelphiDoom.Mikmod.Intf.pas',
  DelphiDoom.Mikmod.Client in '..\Libs\Mikmod\DelphiDoom.Mikmod.Client.pas',
  DelphiDoom.Mikmod.Loader in '..\Libs\Mikmod\DelphiDoom.Mikmod.Loader.pas',
  DelphiDoom.Mikmod.Provider in '..\Libs\Mikmod\DelphiDoom.Mikmod.Provider.pas',
  DelphiDoom.Tracker.Types in '..\Libs\Mikmod\DelphiDoom.Tracker.Types.pas',
  DelphiDoom.Tracker.ByteReader in '..\Libs\Mikmod\DelphiDoom.Tracker.ByteReader.pas',
  DelphiDoom.Tracker.Loader.ProTracker in '..\Libs\Mikmod\DelphiDoom.Tracker.Loader.ProTracker.pas',
  DelphiDoom.Tracker.Loader.S3m in '..\Libs\Mikmod\DelphiDoom.Tracker.Loader.S3m.pas',
  DelphiDoom.Tests.Tracker.Loader.ProTracker in 'Source\DelphiDoom.Tests.Tracker.Loader.ProTracker.pas',
  DelphiDoom.Tests.Tracker.Loader.S3m in 'Source\DelphiDoom.Tests.Tracker.Loader.S3m.pas',
  DelphiDoom.Tracker.Decompressor.It in '..\Libs\Mikmod\DelphiDoom.Tracker.Decompressor.It.pas',
  DelphiDoom.Tracker.Loader.Xm in '..\Libs\Mikmod\DelphiDoom.Tracker.Loader.Xm.pas',
  DelphiDoom.Tracker.Loader.It in '..\Libs\Mikmod\DelphiDoom.Tracker.Loader.It.pas',
  DelphiDoom.Tests.Tracker.Decompressor.It in 'Source\DelphiDoom.Tests.Tracker.Decompressor.It.pas',
  DelphiDoom.Tests.Tracker.Loader.Xm in 'Source\DelphiDoom.Tests.Tracker.Loader.Xm.pas',
  DelphiDoom.Tests.Tracker.Loader.It in 'Source\DelphiDoom.Tests.Tracker.Loader.It.pas',
  DelphiDoom.Tracker.Voice in '..\Libs\Mikmod\DelphiDoom.Tracker.Voice.pas',
  DelphiDoom.Tracker.Mixer in '..\Libs\Mikmod\DelphiDoom.Tracker.Mixer.pas',
  DelphiDoom.Tracker.Player in '..\Libs\Mikmod\DelphiDoom.Tracker.Player.pas',
  DelphiDoom.Tests.Tracker.ModuleBuilder in 'Source\DelphiDoom.Tests.Tracker.ModuleBuilder.pas',
  DelphiDoom.Tests.Tracker.Mixer in 'Source\DelphiDoom.Tests.Tracker.Mixer.pas',
  DelphiDoom.Tests.Tracker.Player in 'Source\DelphiDoom.Tests.Tracker.Player.pas',
  DelphiDoom.Tracker.Effects in '..\Libs\Mikmod\DelphiDoom.Tracker.Effects.pas',
  DelphiDoom.Tracker.EnvelopeCursor in '..\Libs\Mikmod\DelphiDoom.Tracker.EnvelopeCursor.pas',
  DelphiDoom.Tests.Tracker.EnvelopeCursor in 'Source\DelphiDoom.Tests.Tracker.EnvelopeCursor.pas',
  DelphiDoom.Tracker.NoteEnvelopes in '..\Libs\Mikmod\DelphiDoom.Tracker.NoteEnvelopes.pas',
  DelphiDoom.Tracker.Ghost in '..\Libs\Mikmod\DelphiDoom.Tracker.Ghost.pas',
  DelphiDoom.Tracker.GhostPool in '..\Libs\Mikmod\DelphiDoom.Tracker.GhostPool.pas',
  DelphiDoom.Tests.Tracker.NoteEnvelopes in 'Source\DelphiDoom.Tests.Tracker.NoteEnvelopes.pas',
  DelphiDoom.Tests.Tracker.GhostPool in 'Source\DelphiDoom.Tests.Tracker.GhostPool.pas',
  DelphiDoom.Tracker.Channel in '..\Libs\Mikmod\DelphiDoom.Tracker.Channel.pas',
  DelphiDoom.Tests.Tracker.Effects in 'Source\DelphiDoom.Tests.Tracker.Effects.pas',
  DelphiDoom.Tests.Tracker.Channel in 'Source\DelphiDoom.Tests.Tracker.Channel.pas',
  DelphiDoom.Tracker.WaveOut in '..\Libs\Mikmod\DelphiDoom.Tracker.WaveOut.pas',
  DelphiDoom.Mikmod.TrackerPlayer in '..\Libs\Mikmod\DelphiDoom.Mikmod.TrackerPlayer.pas',
  DelphiDoom.Mikmod.TrackerEngine in '..\Libs\Mikmod\DelphiDoom.Mikmod.TrackerEngine.pas',
  DelphiDoom.Tests.Mikmod.TrackerEngine in 'Source\DelphiDoom.Tests.Mikmod.TrackerEngine.pas',
  DelphiDoom.Audio.ModuleDetector in '..\Base\DelphiDoom.Audio.ModuleDetector.pas',
  DelphiDoom.Tests.Audio.ModuleDetector in 'Source\DelphiDoom.Tests.Audio.ModuleDetector.pas',
  DelphiDoom.Tests.Mikmod.Client in 'Source\DelphiDoom.Tests.Mikmod.Client.pas',
  DelphiDoom.Tests.Mikmod.Loader in 'Source\DelphiDoom.Tests.Mikmod.Loader.pas',
  DelphiDoom.Tests.Mikmod.Provider in 'Source\DelphiDoom.Tests.Mikmod.Provider.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
  NUnitLogger: ITestLogger;

begin
  try
    TDUnitX.CheckCommandLine;
    Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;
    Runner.FailsOnNoAsserts := False;

    Logger := TDUnitXConsoleLogger.Create(True);
    Runner.AddLogger(Logger);
    NUnitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    Runner.AddLogger(NUnitLogger);

    Results := Runner.Execute;
    if not Results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.

