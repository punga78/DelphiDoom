{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the obituary library (DUnitX)                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Obituary;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Obituary.Types in '..\Libs\Obituary\DelphiDoom.Obituary.Types.pas',
  DelphiDoom.Obituary.Intf in '..\Libs\Obituary\DelphiDoom.Obituary.Intf.pas',
  DelphiDoom.Obituary.Genders in '..\Libs\Obituary\DelphiDoom.Obituary.Genders.pas',
  DelphiDoom.Obituary.GenderTable in '..\Libs\Obituary\DelphiDoom.Obituary.GenderTable.pas',
  DelphiDoom.Obituary.Formatter in '..\Libs\Obituary\DelphiDoom.Obituary.Formatter.pas',
  DelphiDoom.Obituary.Factory in '..\Libs\Obituary\DelphiDoom.Obituary.Factory.pas',
  DelphiDoom.Tests.Obituary.Genders in 'Source\DelphiDoom.Tests.Obituary.Genders.pas',
  DelphiDoom.Tests.Obituary.GenderTable in 'Source\DelphiDoom.Tests.Obituary.GenderTable.pas',
  DelphiDoom.Tests.Obituary.Formatter in 'Source\DelphiDoom.Tests.Obituary.Formatter.pas';

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
