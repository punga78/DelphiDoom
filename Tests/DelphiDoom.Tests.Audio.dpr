{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the audio library (DUnitX)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Audio;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Logging.Recorder in '..\Libs\Logging\DelphiDoom.Logging.Recorder.pas',
  DelphiDoom.Logging.Log in '..\Libs\Logging\DelphiDoom.Logging.Log.pas',
  DelphiDoom.Logging.Factory in '..\Libs\Logging\DelphiDoom.Logging.Factory.pas',
  DelphiDoom.Audio.Types in '..\Libs\Audio\DelphiDoom.Audio.Types.pas',
  DelphiDoom.Audio.Intf in '..\Libs\Audio\DelphiDoom.Audio.Intf.pas',
  DelphiDoom.Audio.Levels in '..\Libs\Audio\DelphiDoom.Audio.Levels.pas',
  DelphiDoom.Audio.SfxPlayer in '..\Libs\Audio\DelphiDoom.Audio.SfxPlayer.pas',
  DelphiDoom.Audio.MusicPlayer in '..\Libs\Audio\DelphiDoom.Audio.MusicPlayer.pas',
  DelphiDoom.Audio.ExternalMusicCache in '..\Libs\Audio\DelphiDoom.Audio.ExternalMusicCache.pas',
  DelphiDoom.Audio.Factory in '..\Libs\Audio\DelphiDoom.Audio.Factory.pas',
  DelphiDoom.Audio.SoundParameters in '..\Libs\Audio\DelphiDoom.Audio.SoundParameters.pas',
  DelphiDoom.Audio.WaveParser in '..\Libs\Audio\DelphiDoom.Audio.WaveParser.pas',
  DelphiDoom.Audio.MusConverter in '..\Libs\Audio\DelphiDoom.Audio.MusConverter.pas',
  DelphiDoom.Tests.Audio.Scenarios in 'Source\DelphiDoom.Tests.Audio.Scenarios.pas',
  DelphiDoom.Tests.Audio.WaveParser in 'Source\DelphiDoom.Tests.Audio.WaveParser.pas',
  DelphiDoom.Tests.Audio.MusConverter in 'Source\DelphiDoom.Tests.Audio.MusConverter.pas',
  DelphiDoom.Tests.Audio.Fakes in 'Source\DelphiDoom.Tests.Audio.Fakes.pas',
  DelphiDoom.Tests.Audio.SfxPlayer in 'Source\DelphiDoom.Tests.Audio.SfxPlayer.pas',
  DelphiDoom.Tests.Audio.ExternalMusicCache in 'Source\DelphiDoom.Tests.Audio.ExternalMusicCache.pas',
  DelphiDoom.Tests.Audio.MusicPlayer in 'Source\DelphiDoom.Tests.Audio.MusicPlayer.pas';

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
