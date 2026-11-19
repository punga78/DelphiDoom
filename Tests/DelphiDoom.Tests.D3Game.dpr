{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom 3 game library (idClass, the entity      }
{  table, spawning, DUnitX)                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.D3Game;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.D3Game.Types in '..\IdTech4\D3Game\DelphiDoom.D3Game.Types.pas',
  DelphiDoom.D3Game.Intf in '..\IdTech4\D3Game\DelphiDoom.D3Game.Intf.pas',
  DelphiDoom.D3Game.Errors in '..\IdTech4\D3Game\DelphiDoom.D3Game.Errors.pas',
  DelphiDoom.D3Game.ClassBase in '..\IdTech4\D3Game\DelphiDoom.D3Game.ClassBase.pas',
  DelphiDoom.D3Game.ClassSystem in '..\IdTech4\D3Game\DelphiDoom.D3Game.ClassSystem.pas',
  DelphiDoom.D3Game.Entity in '..\IdTech4\D3Game\DelphiDoom.D3Game.Entity.pas',
  DelphiDoom.D3Game.Local in '..\IdTech4\D3Game\DelphiDoom.D3Game.Local.pas',
  DelphiDoom.Tests.Shared.Files in 'Source\DelphiDoom.Tests.Shared.Files.pas',
  DelphiDoom.Tests.Shared.Golden in 'Source\DelphiDoom.Tests.Shared.Golden.pas',
  DelphiDoom.Tests.D3Game.World in 'Source\DelphiDoom.Tests.D3Game.World.pas',
  DelphiDoom.Tests.D3Game.Classes in 'Source\DelphiDoom.Tests.D3Game.Classes.pas',
  DelphiDoom.Tests.D3Game.Rig in 'Source\DelphiDoom.Tests.D3Game.Rig.pas',
  DelphiDoom.Tests.D3Game.Scenario in 'Source\DelphiDoom.Tests.D3Game.Scenario.pas',
  DelphiDoom.Tests.D3Game.Parity in 'Source\DelphiDoom.Tests.D3Game.Parity.pas',
  DelphiDoom.Tests.D3Game.Units in 'Source\DelphiDoom.Tests.D3Game.Units.pas',
  DelphiDoom.Tests.D3Game.WorldRig in 'Source\DelphiDoom.Tests.D3Game.WorldRig.pas',
  DelphiDoom.Tests.D3Game.Triggers in 'Source\DelphiDoom.Tests.D3Game.Triggers.pas',
  DelphiDoom.Tests.D3Game.Movers in 'Source\DelphiDoom.Tests.D3Game.Movers.pas',
  DelphiDoom.Tests.D3Game.WorldScenario in 'Source\DelphiDoom.Tests.D3Game.WorldScenario.pas',
  DelphiDoom.Tests.D3Game.WorldParity in 'Source\DelphiDoom.Tests.D3Game.WorldParity.pas',
  DelphiDoom.Tests.D3Game.ClipRig in 'Source\DelphiDoom.Tests.D3Game.ClipRig.pas',
  DelphiDoom.Tests.D3Game.ClipScenario in 'Source\DelphiDoom.Tests.D3Game.ClipScenario.pas',
  DelphiDoom.Tests.D3Game.ClipParity in 'Source\DelphiDoom.Tests.D3Game.ClipParity.pas';

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