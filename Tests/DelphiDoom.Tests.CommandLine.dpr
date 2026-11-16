{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the command line library (DUnitX)                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.CommandLine;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.CommandLine.Types in '..\Framework\CommandLine\DelphiDoom.CommandLine.Types.pas',
  DelphiDoom.CommandLine.Intf in '..\Framework\CommandLine\DelphiDoom.CommandLine.Intf.pas',
  DelphiDoom.CommandLine.Arguments in '..\Framework\CommandLine\DelphiDoom.CommandLine.Arguments.pas',
  DelphiDoom.CommandLine.DefaultFile in '..\Framework\CommandLine\DelphiDoom.CommandLine.DefaultFile.pas',
  DelphiDoom.CommandLine.Builder in '..\Framework\CommandLine\DelphiDoom.CommandLine.Builder.pas',
  DelphiDoom.CommandLine.Queried in '..\Framework\CommandLine\DelphiDoom.CommandLine.Queried.pas',
  DelphiDoom.CommandLine.SaveFileNames in '..\Framework\CommandLine\DelphiDoom.CommandLine.SaveFileNames.pas',
  DelphiDoom.CommandLine.Factory in '..\Framework\CommandLine\DelphiDoom.CommandLine.Factory.pas',
  DelphiDoom.CommandLine.Startup in '..\Framework\CommandLine\DelphiDoom.CommandLine.Startup.pas',
  DelphiDoom.CommandLine.ResponseFile in '..\Framework\CommandLine\DelphiDoom.CommandLine.ResponseFile.pas',
  DelphiDoom.CommandLine.FileList in '..\Framework\CommandLine\DelphiDoom.CommandLine.FileList.pas',
  DelphiDoom.CommandLine.Verbatim in '..\Framework\CommandLine\DelphiDoom.CommandLine.Verbatim.pas',
  DelphiDoom.CommandLine.Cursor in '..\Framework\CommandLine\DelphiDoom.CommandLine.Cursor.pas',
  DelphiDoom.CommandLine.ProgramFactory in '..\Framework\CommandLine\DelphiDoom.CommandLine.ProgramFactory.pas',
  DelphiDoom.Logging.Types in '..\Framework\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Framework\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Tests.CommandLine.Arguments in 'Source\DelphiDoom.Tests.CommandLine.Arguments.pas',
  DelphiDoom.Tests.CommandLine.DefaultFile in 'Source\DelphiDoom.Tests.CommandLine.DefaultFile.pas',
  DelphiDoom.Tests.CommandLine.Builder in 'Source\DelphiDoom.Tests.CommandLine.Builder.pas',
  DelphiDoom.Tests.CommandLine.ResponseFile in 'Source\DelphiDoom.Tests.CommandLine.ResponseFile.pas',
  DelphiDoom.Tests.CommandLine.FileList in 'Source\DelphiDoom.Tests.CommandLine.FileList.pas',
  DelphiDoom.Tests.CommandLine.Queried in 'Source\DelphiDoom.Tests.CommandLine.Queried.pas',
  DelphiDoom.Tests.CommandLine.SaveFileNames in 'Source\DelphiDoom.Tests.CommandLine.SaveFileNames.pas',
  DelphiDoom.Tests.CommandLine.Verbatim in 'Source\DelphiDoom.Tests.CommandLine.Verbatim.pas',
  DelphiDoom.Tests.CommandLine.Cursor in 'Source\DelphiDoom.Tests.CommandLine.Cursor.pas',
  DelphiDoom.Tests.CommandLine.Startup in 'Source\DelphiDoom.Tests.CommandLine.Startup.pas';

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
