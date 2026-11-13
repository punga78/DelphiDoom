{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the map file library (DUnitX)                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.MapFile;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Tests.IdLib.Fakes in 'Source\DelphiDoom.Tests.IdLib.Fakes.pas',
  DelphiDoom.Tests.MapFile.Dump in 'Source\DelphiDoom.Tests.MapFile.Dump.pas',
  DelphiDoom.Tests.MapFile.Golden in 'Source\DelphiDoom.Tests.MapFile.Golden.pas',
  DelphiDoom.Tests.MapFile.Model in 'Source\DelphiDoom.Tests.MapFile.Model.pas',
  DelphiDoom.Tests.MapFile.Reader in 'Source\DelphiDoom.Tests.MapFile.Reader.pas',
  DelphiDoom.Tests.MapFile.ProcReader in 'Source\DelphiDoom.Tests.MapFile.ProcReader.pas',
  DelphiDoom.Tests.MapFile.ProcSample in 'Source\DelphiDoom.Tests.MapFile.ProcSample.pas',
  DelphiDoom.Tests.MapFile.ProcValidator in 'Source\DelphiDoom.Tests.MapFile.ProcValidator.pas',
  DelphiDoom.Tests.MapFile.ProcWriter in 'Source\DelphiDoom.Tests.MapFile.ProcWriter.pas',
  DelphiDoom.Tests.MapFile.Writer in 'Source\DelphiDoom.Tests.MapFile.Writer.pas';

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
