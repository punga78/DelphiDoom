{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the MIDI library (DUnitX)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Midi;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Audio.Types in '..\Libs\Audio\DelphiDoom.Audio.Types.pas',
  DelphiDoom.Audio.MusConverter in '..\Libs\Audio\DelphiDoom.Audio.MusConverter.pas',
  DelphiDoom.M2m.Intf in '..\Libs\M2m\DelphiDoom.M2m.Intf.pas',
  DelphiDoom.M2m.Types in '..\Libs\M2m\DelphiDoom.M2m.Types.pas',
  DelphiDoom.M2m.MidiFile in '..\Libs\M2m\DelphiDoom.M2m.MidiFile.pas',
  DelphiDoom.M2m.MidiReader in '..\Libs\M2m\DelphiDoom.M2m.MidiReader.pas',
  DelphiDoom.M2m.TrackMerger in '..\Libs\M2m\DelphiDoom.M2m.TrackMerger.pas',
  DelphiDoom.Midi.Types in '..\Libs\Midi\DelphiDoom.Midi.Types.pas',
  DelphiDoom.Midi.Intf in '..\Libs\Midi\DelphiDoom.Midi.Intf.pas',
  DelphiDoom.Midi.SequenceLoader in '..\Libs\Midi\DelphiDoom.Midi.SequenceLoader.pas',
  DelphiDoom.Midi.StreamSequencer in '..\Libs\Midi\DelphiDoom.Midi.StreamSequencer.pas',
  DelphiDoom.Midi.Volume in '..\Libs\Midi\DelphiDoom.Midi.Volume.pas',
  DelphiDoom.Midi.EventFeeder in '..\Libs\Midi\DelphiDoom.Midi.EventFeeder.pas',
  DelphiDoom.Midi.Factory in '..\Libs\Midi\DelphiDoom.Midi.Factory.pas',
  DelphiDoom.Tests.M2m.MidiBuilder in 'Source\DelphiDoom.Tests.M2m.MidiBuilder.pas',
  DelphiDoom.Tests.Midi.Scenarios in 'Source\DelphiDoom.Tests.Midi.Scenarios.pas',
  DelphiDoom.Tests.Midi.FakeLog in 'Source\DelphiDoom.Tests.Midi.FakeLog.pas',
  DelphiDoom.Tests.Midi.Driver in 'Source\DelphiDoom.Tests.Midi.Driver.pas',
  DelphiDoom.Tests.Midi.ReaderOptions in 'Source\DelphiDoom.Tests.Midi.ReaderOptions.pas',
  DelphiDoom.Tests.Midi.SequenceLoader in 'Source\DelphiDoom.Tests.Midi.SequenceLoader.pas',
  DelphiDoom.Tests.Midi.StreamSequencer in 'Source\DelphiDoom.Tests.Midi.StreamSequencer.pas',
  DelphiDoom.Tests.Midi.Volume in 'Source\DelphiDoom.Tests.Midi.Volume.pas',
  DelphiDoom.Tests.Midi.EventFeeder in 'Source\DelphiDoom.Tests.Midi.EventFeeder.pas',
  DelphiDoom.Tests.Midi.Parity in 'Source\DelphiDoom.Tests.Midi.Parity.pas';

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
