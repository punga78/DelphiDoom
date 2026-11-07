{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the clock library (DUnitX)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Clock;

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
  DelphiDoom.Clock.Intf in '..\Libs\Clock\DelphiDoom.Clock.Intf.pas',
  DelphiDoom.Clock.Clock in '..\Libs\Clock\DelphiDoom.Clock.Clock.pas',
  DelphiDoom.Clock.PerformanceSource in '..\Libs\Clock\DelphiDoom.Clock.PerformanceSource.pas',
  DelphiDoom.Clock.WindowsCounters in '..\Libs\Clock\DelphiDoom.Clock.WindowsCounters.pas',
  DelphiDoom.Clock.Factory in '..\Libs\Clock\DelphiDoom.Clock.Factory.pas',
  DelphiDoom.Tests.Clock.Clock in 'Source\DelphiDoom.Tests.Clock.Clock.pas',
  DelphiDoom.Tests.Clock.PerformanceSource in 'Source\DelphiDoom.Tests.Clock.PerformanceSource.pas';

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
