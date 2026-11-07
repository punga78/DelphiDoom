{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the zone library (DUnitX)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Zone;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Zone.Types in '..\Libs\Zone\DelphiDoom.Zone.Types.pas',
  DelphiDoom.Zone.Intf in '..\Libs\Zone\DelphiDoom.Zone.Intf.pas',
  DelphiDoom.Zone.Allocator in '..\Libs\Zone\DelphiDoom.Zone.Allocator.pas',
  DelphiDoom.Zone.HeapMemory in '..\Libs\Zone\DelphiDoom.Zone.HeapMemory.pas',
  DelphiDoom.Zone.Factory in '..\Libs\Zone\DelphiDoom.Zone.Factory.pas',
  DelphiDoom.Tests.Zone.FakeMemory in 'Source\DelphiDoom.Tests.Zone.FakeMemory.pas',
  DelphiDoom.Tests.Zone.Replay in 'Source\DelphiDoom.Tests.Zone.Replay.pas',
  DelphiDoom.Tests.Zone.Allocator in 'Source\DelphiDoom.Tests.Zone.Allocator.pas',
  DelphiDoom.Tests.Zone.Golden in 'Source\DelphiDoom.Tests.Zone.Golden.pas';

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
