{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the actions library (DUnitX)                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Actions;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Actions.Intf in '..\Libs\Actions\DelphiDoom.Actions.Intf.pas',
  DelphiDoom.Actions.Names in '..\Libs\Actions\DelphiDoom.Actions.Names.pas',
  DelphiDoom.Actions.Registry in '..\Libs\Actions\DelphiDoom.Actions.Registry.pas',
  DelphiDoom.Actions.Factory in '..\Libs\Actions\DelphiDoom.Actions.Factory.pas',
  DelphiDoom.Tests.Actions.Names in 'Source\DelphiDoom.Tests.Actions.Names.pas',
  DelphiDoom.Tests.Actions.Registry in 'Source\DelphiDoom.Tests.Actions.Registry.pas';

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
