{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the M2m library (DUnitX)                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.M2m;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.M2m.Intf in '..\Libs\M2m\DelphiDoom.M2m.Intf.pas',
  DelphiDoom.M2m.Types in '..\Libs\M2m\DelphiDoom.M2m.Types.pas',
  DelphiDoom.M2m.MidiFile in '..\Libs\M2m\DelphiDoom.M2m.MidiFile.pas',
  DelphiDoom.M2m.MidiReader in '..\Libs\M2m\DelphiDoom.M2m.MidiReader.pas',
  DelphiDoom.M2m.TrackMerger in '..\Libs\M2m\DelphiDoom.M2m.TrackMerger.pas',
  DelphiDoom.M2m.MusTrack in '..\Libs\M2m\DelphiDoom.M2m.MusTrack.pas',
  DelphiDoom.M2m.Converter in '..\Libs\M2m\DelphiDoom.M2m.Converter.pas',
  DelphiDoom.M2m.Engine in '..\Libs\M2m\DelphiDoom.M2m.Engine.pas',
  DelphiDoom.M2m.Client in '..\Libs\M2m\DelphiDoom.M2m.Client.pas',
  DelphiDoom.M2m.Provider in '..\Libs\M2m\DelphiDoom.M2m.Provider.pas',
  DelphiDoom.Tests.M2m.MidiBuilder in 'Source\DelphiDoom.Tests.M2m.MidiBuilder.pas',
  DelphiDoom.Tests.M2m.MidiReader in 'Source\DelphiDoom.Tests.M2m.MidiReader.pas',
  DelphiDoom.Tests.M2m.TrackMerger in 'Source\DelphiDoom.Tests.M2m.TrackMerger.pas',
  DelphiDoom.Tests.M2m.MusTrack in 'Source\DelphiDoom.Tests.M2m.MusTrack.pas',
  DelphiDoom.Tests.M2m.Converter in 'Source\DelphiDoom.Tests.M2m.Converter.pas',
  DelphiDoom.Tests.M2m.Engine in 'Source\DelphiDoom.Tests.M2m.Engine.pas';

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
