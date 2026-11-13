{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the console library (DUnitX)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Console;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.GameState.Intf in '..\Libs\GameState\DelphiDoom.GameState.Intf.pas',
  DelphiDoom.Console.Types in '..\Libs\Console\DelphiDoom.Console.Types.pas',
  DelphiDoom.Console.Intf in '..\Libs\Console\DelphiDoom.Console.Intf.pas',
  DelphiDoom.Console.Text in '..\Libs\Console\DelphiDoom.Console.Text.pas',
  DelphiDoom.Console.Numbers in '..\Libs\Console\DelphiDoom.Console.Numbers.pas',
  DelphiDoom.Console.MaskMatcher in '..\Libs\Console\DelphiDoom.Console.MaskMatcher.pas',
  DelphiDoom.Console.CommandRegistry in '..\Libs\Console\DelphiDoom.Console.CommandRegistry.pas',
  DelphiDoom.Console.Interpreter in '..\Libs\Console\DelphiDoom.Console.Interpreter.pas',
  DelphiDoom.Console.CommandLister in '..\Libs\Console\DelphiDoom.Console.CommandLister.pas',
  DelphiDoom.Console.VariableCommands in '..\Libs\Console\DelphiDoom.Console.VariableCommands.pas',
  DelphiDoom.Console.StandardCommands in '..\Libs\Console\DelphiDoom.Console.StandardCommands.pas',
  DelphiDoom.Console.ScriptRunner in '..\Libs\Console\DelphiDoom.Console.ScriptRunner.pas',
  DelphiDoom.Console.AutoExec in '..\Libs\Console\DelphiDoom.Console.AutoExec.pas',
  DelphiDoom.Console.CommandQueue in '..\Libs\Console\DelphiDoom.Console.CommandQueue.pas',
  DelphiDoom.Console.History in '..\Libs\Console\DelphiDoom.Console.History.pas',
  DelphiDoom.Console.Completer in '..\Libs\Console\DelphiDoom.Console.Completer.pas',
  DelphiDoom.Console.InputLine in '..\Libs\Console\DelphiDoom.Console.InputLine.pas',
  DelphiDoom.Console.CheatScrambler in '..\Libs\Console\DelphiDoom.Console.CheatScrambler.pas',
  DelphiDoom.Console.CheatSequence in '..\Libs\Console\DelphiDoom.Console.CheatSequence.pas',
  DelphiDoom.Console.CheatSequenceReader in '..\Libs\Console\DelphiDoom.Console.CheatSequenceReader.pas',
  DelphiDoom.Console.CheatTable in '..\Libs\Console\DelphiDoom.Console.CheatTable.pas',
  DelphiDoom.Console.UtilityCommands in '..\Libs\Console\DelphiDoom.Console.UtilityCommands.pas',
  DelphiDoom.Console.Factory in '..\Libs\Console\DelphiDoom.Console.Factory.pas',
  DelphiDoom.Tests.Console.Fakes in 'Source\DelphiDoom.Tests.Console.Fakes.pas',
  DelphiDoom.Tests.Console.Golden in 'Source\DelphiDoom.Tests.Console.Golden.pas',
  DelphiDoom.Tests.Console.Text in 'Source\DelphiDoom.Tests.Console.Text.pas',
  DelphiDoom.Tests.Console.Numbers in 'Source\DelphiDoom.Tests.Console.Numbers.pas',
  DelphiDoom.Tests.Console.MaskMatcher in 'Source\DelphiDoom.Tests.Console.MaskMatcher.pas',
  DelphiDoom.Tests.Console.CommandRegistry in 'Source\DelphiDoom.Tests.Console.CommandRegistry.pas',
  DelphiDoom.Tests.Console.Interpreter in 'Source\DelphiDoom.Tests.Console.Interpreter.pas',
  DelphiDoom.Tests.Console.VariableCommands in 'Source\DelphiDoom.Tests.Console.VariableCommands.pas',
  DelphiDoom.Tests.Console.StandardCommands in 'Source\DelphiDoom.Tests.Console.StandardCommands.pas',
  DelphiDoom.Tests.Console.ScriptRunner in 'Source\DelphiDoom.Tests.Console.ScriptRunner.pas',
  DelphiDoom.Tests.Console.AutoExec in 'Source\DelphiDoom.Tests.Console.AutoExec.pas',
  DelphiDoom.Tests.Console.CommandQueue in 'Source\DelphiDoom.Tests.Console.CommandQueue.pas',
  DelphiDoom.Tests.Console.History in 'Source\DelphiDoom.Tests.Console.History.pas',
  DelphiDoom.Tests.Console.Completer in 'Source\DelphiDoom.Tests.Console.Completer.pas',
  DelphiDoom.Tests.Console.InputLine in 'Source\DelphiDoom.Tests.Console.InputLine.pas',
  DelphiDoom.Tests.Console.CheatData in 'Source\DelphiDoom.Tests.Console.CheatData.pas',
  DelphiDoom.Tests.Console.CheatScrambler in 'Source\DelphiDoom.Tests.Console.CheatScrambler.pas',
  DelphiDoom.Tests.Console.CheatSequenceReader in 'Source\DelphiDoom.Tests.Console.CheatSequenceReader.pas',
  DelphiDoom.Tests.Console.CheatSequence in 'Source\DelphiDoom.Tests.Console.CheatSequence.pas',
  DelphiDoom.Tests.Console.CheatTable in 'Source\DelphiDoom.Tests.Console.CheatTable.pas',
  DelphiDoom.Tests.Console.UtilityCommands in 'Source\DelphiDoom.Tests.Console.UtilityCommands.pas';

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
