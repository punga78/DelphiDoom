{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the threading library (DUnitX)                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Threading;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Threading.Types in '..\Libs\Threading\DelphiDoom.Threading.Types.pas',
  DelphiDoom.Threading.Intf in '..\Libs\Threading\DelphiDoom.Threading.Intf.pas',
  DelphiDoom.Threading.WorkerThread in '..\Libs\Threading\DelphiDoom.Threading.WorkerThread.pas',
  DelphiDoom.Threading.WorkerPool in '..\Libs\Threading\DelphiDoom.Threading.WorkerPool.pas',
  DelphiDoom.Threading.ThreadFactory in '..\Libs\Threading\DelphiDoom.Threading.ThreadFactory.pas',
  DelphiDoom.Threading.PoolFactory in '..\Libs\Threading\DelphiDoom.Threading.PoolFactory.pas',
  DelphiDoom.Threading.JobRunner in '..\Libs\Threading\DelphiDoom.Threading.JobRunner.pas',
  DelphiDoom.Threading.MemoryRunner in '..\Libs\Threading\DelphiDoom.Threading.MemoryRunner.pas',
  DelphiDoom.Threading.TaskScheduler in '..\Libs\Threading\DelphiDoom.Threading.TaskScheduler.pas',
  DelphiDoom.Threading.Factory in '..\Libs\Threading\DelphiDoom.Threading.Factory.pas',
  DelphiDoom.Tests.Threading.Helpers in 'Source\DelphiDoom.Tests.Threading.Helpers.pas',
  DelphiDoom.Tests.Threading.Fakes in 'Source\DelphiDoom.Tests.Threading.Fakes.pas',
  DelphiDoom.Tests.Threading.Types in 'Source\DelphiDoom.Tests.Threading.Types.pas',
  DelphiDoom.Tests.Threading.WorkerThread in 'Source\DelphiDoom.Tests.Threading.WorkerThread.pas',
  DelphiDoom.Tests.Threading.WorkerPool in 'Source\DelphiDoom.Tests.Threading.WorkerPool.pas',
  DelphiDoom.Tests.Threading.Factory in 'Source\DelphiDoom.Tests.Threading.Factory.pas',
  DelphiDoom.Tests.Threading.Recording in 'Source\DelphiDoom.Tests.Threading.Recording.pas',
  DelphiDoom.Tests.Threading.Legacy in 'Source\DelphiDoom.Tests.Threading.Legacy.pas',
  DelphiDoom.Tests.Threading.JobRunner in 'Source\DelphiDoom.Tests.Threading.JobRunner.pas',
  DelphiDoom.Tests.Threading.MemoryRunner in 'Source\DelphiDoom.Tests.Threading.MemoryRunner.pas',
  DelphiDoom.Tests.Threading.TaskScheduler in 'Source\DelphiDoom.Tests.Threading.TaskScheduler.pas';

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
