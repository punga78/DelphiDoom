{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom strategy library (DUnitX)                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later: see           }
{  Libs\XcomFormats\README.md)                                                  }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.XcomStrategy;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Tests.XcomSave.Sim in 'Source\DelphiDoom.Tests.XcomSave.Sim.pas',
  DelphiDoom.Tests.XcomStrategy.Production in 'Source\DelphiDoom.Tests.XcomStrategy.Production.pas',
  DelphiDoom.Tests.XcomStrategy.Research in 'Source\DelphiDoom.Tests.XcomStrategy.Research.pas',
  DelphiDoom.Tests.XcomStrategy.Mission in 'Source\DelphiDoom.Tests.XcomStrategy.Mission.pas',
  DelphiDoom.Tests.XcomStrategy.Time in 'Source\DelphiDoom.Tests.XcomStrategy.Time.pas',
  DelphiDoom.Tests.XcomStrategy.StatString in 'Source\DelphiDoom.Tests.XcomStrategy.StatString.pas',
  DelphiDoom.Tests.XcomStrategy.Units in 'Source\DelphiDoom.Tests.XcomStrategy.Units.pas',
  DelphiDoom.Tests.XcomStrategy.Scripts in 'Source\DelphiDoom.Tests.XcomStrategy.Scripts.pas';

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


