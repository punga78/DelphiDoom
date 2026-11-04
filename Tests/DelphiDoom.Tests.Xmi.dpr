{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Xmi library (DUnitX)                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Xmi;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Xmi.Intf in '..\Libs\Xmi\DelphiDoom.Xmi.Intf.pas',
  DelphiDoom.Xmi.Midi.Types in '..\Libs\Xmi\DelphiDoom.Xmi.Midi.Types.pas',
  DelphiDoom.Xmi.Midi.Track in '..\Libs\Xmi\DelphiDoom.Xmi.Midi.Track.pas',
  DelphiDoom.Xmi.Midi.Song in '..\Libs\Xmi\DelphiDoom.Xmi.Midi.Song.pas',
  DelphiDoom.Xmi.Midi.ByteReader in '..\Libs\Xmi\DelphiDoom.Xmi.Midi.ByteReader.pas',
  DelphiDoom.Xmi.Iff in '..\Libs\Xmi\DelphiDoom.Xmi.Iff.pas',
  DelphiDoom.Xmi.Reader.SystemEvent in '..\Libs\Xmi\DelphiDoom.Xmi.Reader.SystemEvent.pas',
  DelphiDoom.Xmi.Reader.MidiTrack in '..\Libs\Xmi\DelphiDoom.Xmi.Reader.MidiTrack.pas',
  DelphiDoom.Xmi.Reader.Xmi in '..\Libs\Xmi\DelphiDoom.Xmi.Reader.Xmi.pas',
  DelphiDoom.Xmi.Reader.Cmf in '..\Libs\Xmi\DelphiDoom.Xmi.Reader.Cmf.pas',
  DelphiDoom.Xmi.Converter.XmiToMidi in '..\Libs\Xmi\DelphiDoom.Xmi.Converter.XmiToMidi.pas',
  DelphiDoom.Xmi.Converter.CmfToMidi in '..\Libs\Xmi\DelphiDoom.Xmi.Converter.CmfToMidi.pas',
  DelphiDoom.Xmi.Writer.Midi in '..\Libs\Xmi\DelphiDoom.Xmi.Writer.Midi.pas',
  DelphiDoom.Xmi.FormatDetector in '..\Libs\Xmi\DelphiDoom.Xmi.FormatDetector.pas',
  DelphiDoom.Xmi.Converter in '..\Libs\Xmi\DelphiDoom.Xmi.Converter.pas',
  DelphiDoom.Xmi.Engine in '..\Libs\Xmi\DelphiDoom.Xmi.Engine.pas',
  DelphiDoom.Xmi.Client in '..\Libs\Xmi\DelphiDoom.Xmi.Client.pas',
  DelphiDoom.Xmi.Loader in '..\Libs\Xmi\DelphiDoom.Xmi.Loader.pas',
  DelphiDoom.Xmi.Provider in '..\Libs\Xmi\DelphiDoom.Xmi.Provider.pas',
  DelphiDoom.Xmi.Midi.Types in '..\Libs\Xmi\DelphiDoom.Xmi.Midi.Types.pas',
  DelphiDoom.Xmi.Midi.Track in '..\Libs\Xmi\DelphiDoom.Xmi.Midi.Track.pas',
  DelphiDoom.Xmi.Midi.Song in '..\Libs\Xmi\DelphiDoom.Xmi.Midi.Song.pas',
  DelphiDoom.Xmi.Midi.ByteReader in '..\Libs\Xmi\DelphiDoom.Xmi.Midi.ByteReader.pas',
  DelphiDoom.Xmi.Iff in '..\Libs\Xmi\DelphiDoom.Xmi.Iff.pas',
  DelphiDoom.Xmi.Reader.Xmi in '..\Libs\Xmi\DelphiDoom.Xmi.Reader.Xmi.pas',
  DelphiDoom.Xmi.Reader.SystemEvent in '..\Libs\Xmi\DelphiDoom.Xmi.Reader.SystemEvent.pas',
  DelphiDoom.Xmi.Reader.MidiTrack in '..\Libs\Xmi\DelphiDoom.Xmi.Reader.MidiTrack.pas',
  DelphiDoom.Xmi.Reader.Cmf in '..\Libs\Xmi\DelphiDoom.Xmi.Reader.Cmf.pas',
  DelphiDoom.Xmi.Converter.CmfToMidi in '..\Libs\Xmi\DelphiDoom.Xmi.Converter.CmfToMidi.pas',
  DelphiDoom.Xmi.Converter.XmiToMidi in '..\Libs\Xmi\DelphiDoom.Xmi.Converter.XmiToMidi.pas',
  DelphiDoom.Xmi.Writer.Midi in '..\Libs\Xmi\DelphiDoom.Xmi.Writer.Midi.pas',
  DelphiDoom.Xmi.FormatDetector in '..\Libs\Xmi\DelphiDoom.Xmi.FormatDetector.pas',
  DelphiDoom.Xmi.Converter in '..\Libs\Xmi\DelphiDoom.Xmi.Converter.pas',
  DelphiDoom.Tests.Xmi.Samples in 'Source\DelphiDoom.Tests.Xmi.Samples.pas',
  DelphiDoom.Tests.Xmi.Engine in 'Source\DelphiDoom.Tests.Xmi.Engine.pas',
  DelphiDoom.Tests.Xmi.Client in 'Source\DelphiDoom.Tests.Xmi.Client.pas',
  DelphiDoom.Tests.Xmi.Loader in 'Source\DelphiDoom.Tests.Xmi.Loader.pas',
  DelphiDoom.Tests.Xmi.Provider in 'Source\DelphiDoom.Tests.Xmi.Provider.pas',
  DelphiDoom.Tests.Xmi.Converter in 'Source\DelphiDoom.Tests.Xmi.Converter.pas';

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
