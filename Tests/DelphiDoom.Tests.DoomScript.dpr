{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.DoomScript;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Tests.IdLib.Fakes in 'Source\DelphiDoom.Tests.IdLib.Fakes.pas',
  DelphiDoom.Tests.DoomScript.Fakes in 'Source\DelphiDoom.Tests.DoomScript.Fakes.pas',
  DelphiDoom.Tests.DoomScript.Support in 'Source\DelphiDoom.Tests.DoomScript.Support.pas',
  DelphiDoom.Tests.DoomScript.Convert in 'Source\DelphiDoom.Tests.DoomScript.Convert.pas',
  DelphiDoom.Tests.DoomScript.Memory in 'Source\DelphiDoom.Tests.DoomScript.Memory.pas',
  DelphiDoom.Tests.DoomScript.EventDef in 'Source\DelphiDoom.Tests.DoomScript.EventDef.pas',
  DelphiDoom.Tests.DoomScript.EventRegistry in 'Source\DelphiDoom.Tests.DoomScript.EventRegistry.pas',
  DelphiDoom.Tests.DoomScript.ClassInfo in 'Source\DelphiDoom.Tests.DoomScript.ClassInfo.pas',
  DelphiDoom.Tests.DoomScript.ClassRegistry in 'Source\DelphiDoom.Tests.DoomScript.ClassRegistry.pas',
  DelphiDoom.Tests.DoomScript.EventTarget in 'Source\DelphiDoom.Tests.DoomScript.EventTarget.pas',
  DelphiDoom.Tests.DoomScript.SaveStream in 'Source\DelphiDoom.Tests.DoomScript.SaveStream.pas',
  DelphiDoom.Tests.DoomScript.TypeDef in 'Source\DelphiDoom.Tests.DoomScript.TypeDef.pas',
  DelphiDoom.Tests.DoomScript.VarDef in 'Source\DelphiDoom.Tests.DoomScript.VarDef.pas',
  DelphiDoom.Tests.DoomScript.Opcodes in 'Source\DelphiDoom.Tests.DoomScript.Opcodes.pas',
  DelphiDoom.Tests.DoomScript.EventQueue in 'Source\DelphiDoom.Tests.DoomScript.EventQueue.pas',
  DelphiDoom.Tests.DoomScript.Entities in 'Source\DelphiDoom.Tests.DoomScript.Entities.pas',
  DelphiDoom.Tests.DoomScript.ScriptObject in 'Source\DelphiDoom.Tests.DoomScript.ScriptObject.pas',
  DelphiDoom.Tests.DoomScript.Machine in 'Source\DelphiDoom.Tests.DoomScript.Machine.pas',
  DelphiDoom.Tests.DoomScript.Parity.Output in 'Source\DelphiDoom.Tests.DoomScript.Parity.Output.pas',
  DelphiDoom.Tests.DoomScript.Parity.FileSystem in 'Source\DelphiDoom.Tests.DoomScript.Parity.FileSystem.pas',
  DelphiDoom.Tests.DoomScript.Parity.Entity in 'Source\DelphiDoom.Tests.DoomScript.Parity.Entity.pas',
  DelphiDoom.Tests.DoomScript.Parity.Game in 'Source\DelphiDoom.Tests.DoomScript.Parity.Game.pas',
  DelphiDoom.Tests.DoomScript.Parity.Dump in 'Source\DelphiDoom.Tests.DoomScript.Parity.Dump.pas',
  DelphiDoom.Tests.DoomScript.Parity.Scenario in 'Source\DelphiDoom.Tests.DoomScript.Parity.Scenario.pas',
  DelphiDoom.Tests.DoomScript.Parity in 'Source\DelphiDoom.Tests.DoomScript.Parity.pas';

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
