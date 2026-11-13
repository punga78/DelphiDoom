{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the engine system library (DUnitX)                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.EngineSystem;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  d_delphi in '..\Common\d_delphi.pas',
  DelphiDoom.EngineSystem.Types in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.Types.pas',
  DelphiDoom.EngineSystem.Intf in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.Intf.pas',
  DelphiDoom.EngineSystem.NetCommandLineReader in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.NetCommandLineReader.pas',
  DelphiDoom.EngineSystem.MidiPlayerSelection in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.MidiPlayerSelection.pas',
  DelphiDoom.EngineSystem.MidiPlaylist in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.MidiPlaylist.pas',
  DelphiDoom.EngineSystem.LegacyMidiPlayer in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.LegacyMidiPlayer.pas',
  DelphiDoom.EngineSystem.WindowsMciSequencer in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.WindowsMciSequencer.pas',
  DelphiDoom.EngineSystem.WindowsMidiNotifyWindow in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.WindowsMidiNotifyWindow.pas',
  DelphiDoom.EngineSystem.ModuleMusicPlayer in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.ModuleMusicPlayer.pas',
  DelphiDoom.EngineSystem.MikModProviderSource in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.MikModProviderSource.pas',
  DelphiDoom.EngineSystem.StdoutBuffer in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.StdoutBuffer.pas',
  DelphiDoom.EngineSystem.LogFileNames in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.LogFileNames.pas',
  DelphiDoom.EngineSystem.MachineProfileBuilder in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.MachineProfileBuilder.pas',
  DelphiDoom.EngineSystem.ShutdownSequence in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.ShutdownSequence.pas',
  DelphiDoom.EngineSystem.FatalErrorHandler in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.FatalErrorHandler.pas',
  DelphiDoom.EngineSystem.CrashReportWriter in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.CrashReportWriter.pas',
  DelphiDoom.EngineSystem.WindowsCrashMemory in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.WindowsCrashMemory.pas',
  DelphiDoom.EngineSystem.FileCrashSink in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.FileCrashSink.pas',
  DelphiDoom.EngineSystem.WindowsCrashLogger in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.WindowsCrashLogger.pas',
  DelphiDoom.EngineSystem.Factory in '..\Libs\EngineSystem\DelphiDoom.EngineSystem.Factory.pas',
  DelphiDoom.Tests.EngineSystem.Fakes in 'Source\DelphiDoom.Tests.EngineSystem.Fakes.pas',
  DelphiDoom.Tests.EngineSystem.Legacy in 'Source\DelphiDoom.Tests.EngineSystem.Legacy.pas',
  DelphiDoom.Tests.EngineSystem.LegacyCrash in 'Source\DelphiDoom.Tests.EngineSystem.LegacyCrash.pas',
  DelphiDoom.Tests.EngineSystem.NetCommandLineReader in 'Source\DelphiDoom.Tests.EngineSystem.NetCommandLineReader.pas',
  DelphiDoom.Tests.EngineSystem.Midi in 'Source\DelphiDoom.Tests.EngineSystem.Midi.pas',
  DelphiDoom.Tests.EngineSystem.ModuleMusicPlayer in 'Source\DelphiDoom.Tests.EngineSystem.ModuleMusicPlayer.pas',
  DelphiDoom.Tests.EngineSystem.Io in 'Source\DelphiDoom.Tests.EngineSystem.Io.pas',
  DelphiDoom.Tests.EngineSystem.Lifecycle in 'Source\DelphiDoom.Tests.EngineSystem.Lifecycle.pas',
  DelphiDoom.Tests.EngineSystem.Crash in 'Source\DelphiDoom.Tests.EngineSystem.Crash.pas';

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
