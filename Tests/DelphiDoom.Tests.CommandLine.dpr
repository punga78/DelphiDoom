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
  DelphiDoom.CommandLine.Types in '..\Libs\CommandLine\DelphiDoom.CommandLine.Types.pas',
  DelphiDoom.CommandLine.Intf in '..\Libs\CommandLine\DelphiDoom.CommandLine.Intf.pas',
  DelphiDoom.CommandLine.Arguments in '..\Libs\CommandLine\DelphiDoom.CommandLine.Arguments.pas',
  DelphiDoom.CommandLine.DefaultFile in '..\Libs\CommandLine\DelphiDoom.CommandLine.DefaultFile.pas',
  DelphiDoom.CommandLine.Builder in '..\Libs\CommandLine\DelphiDoom.CommandLine.Builder.pas',
  DelphiDoom.CommandLine.Factory in '..\Libs\CommandLine\DelphiDoom.CommandLine.Factory.pas',
  DelphiDoom.Tests.CommandLine.Arguments in 'Source\DelphiDoom.Tests.CommandLine.Arguments.pas',
  DelphiDoom.Tests.CommandLine.DefaultFile in 'Source\DelphiDoom.Tests.CommandLine.DefaultFile.pas',
  DelphiDoom.Tests.CommandLine.Builder in 'Source\DelphiDoom.Tests.CommandLine.Builder.pas';

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
