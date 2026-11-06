{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the net library (DUnitX)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Net;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Clock.Intf in '..\Libs\Clock\DelphiDoom.Clock.Intf.pas',
  DelphiDoom.GameState.Intf in '..\Libs\GameState\DelphiDoom.GameState.Intf.pas',
  DelphiDoom.Net.Types in '..\Libs\Net\DelphiDoom.Net.Types.pas',
  DelphiDoom.Net.Intf in '..\Libs\Net\DelphiDoom.Net.Intf.pas',
  DelphiDoom.Net.PacketCodec in '..\Libs\Net\DelphiDoom.Net.PacketCodec.pas',
  DelphiDoom.Net.TicSync in '..\Libs\Net\DelphiDoom.Net.TicSync.pas',
  DelphiDoom.Net.ConsistencyTracker in '..\Libs\Net\DelphiDoom.Net.ConsistencyTracker.pas',
  DelphiDoom.Net.StartArbiter in '..\Libs\Net\DelphiDoom.Net.StartArbiter.pas',
  DelphiDoom.Net.NodeListParser in '..\Libs\Net\DelphiDoom.Net.NodeListParser.pas',
  DelphiDoom.Net.WinsockTransport in '..\Libs\Net\DelphiDoom.Net.WinsockTransport.pas',
  DelphiDoom.Net.Factory in '..\Libs\Net\DelphiDoom.Net.Factory.pas',
  DelphiDoom.Tests.Net.Fakes in 'Source\DelphiDoom.Tests.Net.Fakes.pas',
  DelphiDoom.Tests.Net.PacketCodec in 'Source\DelphiDoom.Tests.Net.PacketCodec.pas',
  DelphiDoom.Tests.Net.TicSync in 'Source\DelphiDoom.Tests.Net.TicSync.pas',
  DelphiDoom.Tests.Net.TicPlanner in 'Source\DelphiDoom.Tests.Net.TicPlanner.pas',
  DelphiDoom.Tests.Net.ConsistencyTracker in 'Source\DelphiDoom.Tests.Net.ConsistencyTracker.pas',
  DelphiDoom.Tests.Net.StartArbiter in 'Source\DelphiDoom.Tests.Net.StartArbiter.pas',
  DelphiDoom.Tests.Net.NodeListParser in 'Source\DelphiDoom.Tests.Net.NodeListParser.pas',
  DelphiDoom.Tests.Net.WinsockTransport in 'Source\DelphiDoom.Tests.Net.WinsockTransport.pas';

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
