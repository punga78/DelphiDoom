{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom 3 host library (idCommon and the event   }
{  loop, DUnitX)                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.D3Host;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.D3Host.Types in '..\IdTech4\D3Host\DelphiDoom.D3Host.Types.pas',
  DelphiDoom.D3Host.Intf in '..\IdTech4\D3Host\DelphiDoom.D3Host.Intf.pas',
  DelphiDoom.D3Host.Input.Types in '..\IdTech4\D3Host\DelphiDoom.D3Host.Input.Types.pas',
  DelphiDoom.D3Host.Input.Intf in '..\IdTech4\D3Host\DelphiDoom.D3Host.Input.Intf.pas',
  DelphiDoom.D3Host.Lifecycle.Intf in '..\IdTech4\D3Host\DelphiDoom.D3Host.Lifecycle.Intf.pas',
  DelphiDoom.D3Host.KeyNames in '..\IdTech4\D3Host\DelphiDoom.D3Host.KeyNames.pas',
  DelphiDoom.D3Host.KeyInput in '..\IdTech4\D3Host\DelphiDoom.D3Host.KeyInput.pas',
  DelphiDoom.D3Host.EditField in '..\IdTech4\D3Host\DelphiDoom.D3Host.EditField.pas',
  DelphiDoom.D3Host.UsercmdGen in '..\IdTech4\D3Host\DelphiDoom.D3Host.UsercmdGen.pas',
  DelphiDoom.D3Host.Console in '..\IdTech4\D3Host\DelphiDoom.D3Host.Console.pas',
  DelphiDoom.D3Host.Lifecycle in '..\IdTech4\D3Host\DelphiDoom.D3Host.Lifecycle.pas',
  DelphiDoom.D3Host.Session.Intf in '..\IdTech4\D3Host\DelphiDoom.D3Host.Session.Intf.pas',
  DelphiDoom.D3Host.Session in '..\IdTech4\D3Host\DelphiDoom.D3Host.Session.pas',
  DelphiDoom.D3Host.Printer in '..\IdTech4\D3Host\DelphiDoom.D3Host.Printer.pas',
  DelphiDoom.D3Host.Diagnostics in '..\IdTech4\D3Host\DelphiDoom.D3Host.Diagnostics.pas',
  DelphiDoom.D3Host.ErrorHandler in '..\IdTech4\D3Host\DelphiDoom.D3Host.ErrorHandler.pas',
  DelphiDoom.D3Host.CommandLine in '..\IdTech4\D3Host\DelphiDoom.D3Host.CommandLine.pas',
  DelphiDoom.D3Host.EventLoop in '..\IdTech4\D3Host\DelphiDoom.D3Host.EventLoop.pas',
  DelphiDoom.D3Host.Common in '..\IdTech4\D3Host\DelphiDoom.D3Host.Common.pas',
  DelphiDoom.D3Host.Factory in '..\IdTech4\D3Host\DelphiDoom.D3Host.Factory.pas',
  DelphiDoom.Tests.Shared.Files in 'Source\DelphiDoom.Tests.Shared.Files.pas',
  DelphiDoom.Tests.Shared.Golden in 'Source\DelphiDoom.Tests.Shared.Golden.pas',
  DelphiDoom.Tests.D3Host.World in 'Source\DelphiDoom.Tests.D3Host.World.pas',
  DelphiDoom.Tests.D3Host.Scenario in 'Source\DelphiDoom.Tests.D3Host.Scenario.pas',
  DelphiDoom.Tests.D3Host.Parity in 'Source\DelphiDoom.Tests.D3Host.Parity.pas',
  DelphiDoom.Tests.D3Host.HostWorld in 'Source\DelphiDoom.Tests.D3Host.HostWorld.pas',
  DelphiDoom.Tests.D3Host.HostScenario in 'Source\DelphiDoom.Tests.D3Host.HostScenario.pas',
  DelphiDoom.Tests.IdLib.Fakes in 'Source\DelphiDoom.Tests.IdLib.Fakes.pas',
  DelphiDoom.Tests.DoomScript.Fakes in 'Source\DelphiDoom.Tests.DoomScript.Fakes.pas',
  DelphiDoom.Tests.DoomScript.Rig in 'Source\DelphiDoom.Tests.DoomScript.Rig.pas',
  DelphiDoom.Tests.D3Host.Proof in 'Source\DelphiDoom.Tests.D3Host.Proof.pas',
  DelphiDoom.Tests.D3Host.WorldProof in 'Source\DelphiDoom.Tests.D3Host.WorldProof.pas',
  DelphiDoom.Tests.D3Host.HostParity in 'Source\DelphiDoom.Tests.D3Host.HostParity.pas',
  DelphiDoom.Tests.D3Host.Classes in 'Source\DelphiDoom.Tests.D3Host.Classes.pas';

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
