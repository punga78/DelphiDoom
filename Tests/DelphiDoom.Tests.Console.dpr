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
  DelphiDoom.Logging.Types in '..\Framework\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Framework\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.GameState.Intf in '..\IdTech1\GameState\DelphiDoom.GameState.Intf.pas',
  DelphiDoom.Console.Types in '..\Framework\Console\DelphiDoom.Console.Types.pas',
  DelphiDoom.Console.Intf in '..\Framework\Console\DelphiDoom.Console.Intf.pas',
  DelphiDoom.Console.Text in '..\Framework\Console\DelphiDoom.Console.Text.pas',
  DelphiDoom.Console.Numbers in '..\Framework\Console\DelphiDoom.Console.Numbers.pas',
  DelphiDoom.Console.MaskMatcher in '..\Framework\Console\DelphiDoom.Console.MaskMatcher.pas',
  DelphiDoom.Console.CommandRegistry in '..\Framework\Console\DelphiDoom.Console.CommandRegistry.pas',
  DelphiDoom.Console.Interpreter in '..\Framework\Console\DelphiDoom.Console.Interpreter.pas',
  DelphiDoom.Console.CommandLister in '..\Framework\Console\DelphiDoom.Console.CommandLister.pas',
  DelphiDoom.Console.VariableCommands in '..\Framework\Console\DelphiDoom.Console.VariableCommands.pas',
  DelphiDoom.Console.StandardCommands in '..\Framework\Console\DelphiDoom.Console.StandardCommands.pas',
  DelphiDoom.Console.ScriptRunner in '..\Framework\Console\DelphiDoom.Console.ScriptRunner.pas',
  DelphiDoom.Console.AutoExec in '..\Framework\Console\DelphiDoom.Console.AutoExec.pas',
  DelphiDoom.Console.CommandQueue in '..\Framework\Console\DelphiDoom.Console.CommandQueue.pas',
  DelphiDoom.Console.History in '..\Framework\Console\DelphiDoom.Console.History.pas',
  DelphiDoom.Console.Completer in '..\Framework\Console\DelphiDoom.Console.Completer.pas',
  DelphiDoom.Console.InputLine in '..\Framework\Console\DelphiDoom.Console.InputLine.pas',
  DelphiDoom.Console.CheatScrambler in '..\Framework\Console\DelphiDoom.Console.CheatScrambler.pas',
  DelphiDoom.Console.CheatSequence in '..\Framework\Console\DelphiDoom.Console.CheatSequence.pas',
  DelphiDoom.Console.CheatSequenceReader in '..\Framework\Console\DelphiDoom.Console.CheatSequenceReader.pas',
  DelphiDoom.Console.CheatTable in '..\Framework\Console\DelphiDoom.Console.CheatTable.pas',
  DelphiDoom.Console.UtilityCommands in '..\Framework\Console\DelphiDoom.Console.UtilityCommands.pas',
  DelphiDoom.Console.LumpCommands in '..\Framework\Console\DelphiDoom.Console.LumpCommands.pas',
  DelphiDoom.Console.Factory in '..\Framework\Console\DelphiDoom.Console.Factory.pas',
  DelphiDoom.Console.CmdSystem.Types in '..\Framework\Console\DelphiDoom.Console.CmdSystem.Types.pas',
  DelphiDoom.Console.CmdSystem.Intf in '..\Framework\Console\DelphiDoom.Console.CmdSystem.Intf.pas',
  DelphiDoom.Console.CmdSystem.CommandList in '..\Framework\Console\DelphiDoom.Console.CmdSystem.CommandList.pas',
  DelphiDoom.Console.CmdSystem.Buffer in '..\Framework\Console\DelphiDoom.Console.CmdSystem.Buffer.pas',
  DelphiDoom.Console.CmdSystem.System in '..\Framework\Console\DelphiDoom.Console.CmdSystem.System.pas',
  DelphiDoom.Console.CmdSystem.Completions in '..\Framework\Console\DelphiDoom.Console.CmdSystem.Completions.pas',
  DelphiDoom.Console.CmdSystem.FolderCompletion in '..\Framework\Console\DelphiDoom.Console.CmdSystem.FolderCompletion.pas',
  DelphiDoom.Console.CmdSystem.StandardCommands in '..\Framework\Console\DelphiDoom.Console.CmdSystem.StandardCommands.pas',
  DelphiDoom.Console.CVar.Types in '..\Framework\Console\DelphiDoom.Console.CVar.Types.pas',
  DelphiDoom.Console.CVar.Context in '..\Framework\Console\DelphiDoom.Console.CVar.Context.pas',
  DelphiDoom.Console.CVar.Variable in '..\Framework\Console\DelphiDoom.Console.CVar.Variable.pas',
  DelphiDoom.Console.CVar.Intf in '..\Framework\Console\DelphiDoom.Console.CVar.Intf.pas',
  DelphiDoom.Console.CVar.System in '..\Framework\Console\DelphiDoom.Console.CVar.System.pas',
  DelphiDoom.Console.CVar.Lister in '..\Framework\Console\DelphiDoom.Console.CVar.Lister.pas',
  DelphiDoom.Console.CVar.Commands in '..\Framework\Console\DelphiDoom.Console.CVar.Commands.pas',
  DelphiDoom.Console.IdTech4.Factory in '..\Framework\Console\DelphiDoom.Console.IdTech4.Factory.pas',
  DelphiDoom.Console.Q3.Types in '..\Framework\Console\DelphiDoom.Console.Q3.Types.pas',
  DelphiDoom.Console.Q3.CVar in '..\Framework\Console\DelphiDoom.Console.Q3.CVar.pas',
  DelphiDoom.Console.Q3.Intf in '..\Framework\Console\DelphiDoom.Console.Q3.Intf.pas',
  DelphiDoom.Console.Q3.CommandArguments in '..\Framework\Console\DelphiDoom.Console.Q3.CommandArguments.pas',
  DelphiDoom.Console.Q3.CommandBuffer in '..\Framework\Console\DelphiDoom.Console.Q3.CommandBuffer.pas',
  DelphiDoom.Console.Q3.CommandSystem in '..\Framework\Console\DelphiDoom.Console.Q3.CommandSystem.pas',
  DelphiDoom.Console.Q3.StandardCommands in '..\Framework\Console\DelphiDoom.Console.Q3.StandardCommands.pas',
  DelphiDoom.Console.Q3.CVarSystem in '..\Framework\Console\DelphiDoom.Console.Q3.CVarSystem.pas',
  DelphiDoom.Console.Q3.CVarCommands in '..\Framework\Console\DelphiDoom.Console.Q3.CVarCommands.pas',
  DelphiDoom.Console.Q3.Factory in '..\Framework\Console\DelphiDoom.Console.Q3.Factory.pas',
  DelphiDoom.Wad.Fs.Types in '..\Framework\Wad\DelphiDoom.Wad.Fs.Types.pas',
  DelphiDoom.Wad.Fs.Intf in '..\Framework\Wad\DelphiDoom.Wad.Fs.Intf.pas',
  DelphiDoom.Console.Q3.Field.Types in '..\Framework\Console\DelphiDoom.Console.Q3.Field.Types.pas',
  DelphiDoom.Console.Q3.Field.Intf in '..\Framework\Console\DelphiDoom.Console.Q3.Field.Intf.pas',
  DelphiDoom.Console.Q3.Field.Editor in '..\Framework\Console\DelphiDoom.Console.Q3.Field.Editor.pas',
  DelphiDoom.Console.Q3.Field.History in '..\Framework\Console\DelphiDoom.Console.Q3.Field.History.pas',
  DelphiDoom.Console.Q3.Field.Completer in '..\Framework\Console\DelphiDoom.Console.Q3.Field.Completer.pas',
  DelphiDoom.Console.Q3.ConsoleInput in '..\Framework\Console\DelphiDoom.Console.Q3.ConsoleInput.pas',
  DelphiDoom.Console.Q3.LogAdapter in '..\Framework\Console\DelphiDoom.Console.Q3.LogAdapter.pas',
  DelphiDoom.Console.Q3.GameFileSystem in '..\Framework\Console\DelphiDoom.Console.Q3.GameFileSystem.pas',
  DelphiDoom.Console.Q3.UnhandledCommands in '..\Framework\Console\DelphiDoom.Console.Q3.UnhandledCommands.pas',
  DelphiDoom.Net.Q3.Types in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.Types.pas',
  DelphiDoom.Net.Q3.InfoString in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.InfoString.pas',
  DelphiDoom.Net.Q3.ConsoleInfoWriter in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.ConsoleInfoWriter.pas',
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
  DelphiDoom.Tests.Console.UtilityCommands in 'Source\DelphiDoom.Tests.Console.UtilityCommands.pas',
  DelphiDoom.Tests.Console.LumpCommands in 'Source\DelphiDoom.Tests.Console.LumpCommands.pas',
  DelphiDoom.Tests.Console.IdTech4.Fakes in 'Source\DelphiDoom.Tests.Console.IdTech4.Fakes.pas',
  DelphiDoom.Tests.Console.CmdSystem in 'Source\DelphiDoom.Tests.Console.CmdSystem.pas',
  DelphiDoom.Tests.Console.IdTech4.Scenario in 'Source\DelphiDoom.Tests.Console.IdTech4.Scenario.pas',
  DelphiDoom.Tests.Console.IdTech4.Golden in 'Source\DelphiDoom.Tests.Console.IdTech4.Golden.pas',
  DelphiDoom.Tests.Console.CVar in 'Source\DelphiDoom.Tests.Console.CVar.pas',
  DelphiDoom.Tests.Console.CmdSystem.Standard in 'Source\DelphiDoom.Tests.Console.CmdSystem.Standard.pas',
  DelphiDoom.Tests.Console.Q3.Fakes in 'Source\DelphiDoom.Tests.Console.Q3.Fakes.pas',
  DelphiDoom.Tests.Console.Q3.Scenario in 'Source\DelphiDoom.Tests.Console.Q3.Scenario.pas',
  DelphiDoom.Tests.Console.Q3.FieldHost in 'Source\DelphiDoom.Tests.Console.Q3.FieldHost.pas',
  DelphiDoom.Tests.Console.Q3.Field in 'Source\DelphiDoom.Tests.Console.Q3.Field.pas',
  DelphiDoom.Tests.Console.Q3.Adapters in 'Source\DelphiDoom.Tests.Console.Q3.Adapters.pas',
  DelphiDoom.Tests.Console.Q3.Golden in'Source\DelphiDoom.Tests.Console.Q3.Golden.pas',
  DelphiDoom.Tests.Console.Q3.CommandArguments in 'Source\DelphiDoom.Tests.Console.Q3.CommandArguments.pas',
  DelphiDoom.Tests.Console.Q3.CommandBuffer in 'Source\DelphiDoom.Tests.Console.Q3.CommandBuffer.pas',
  DelphiDoom.Tests.Console.Q3.CommandSystem in 'Source\DelphiDoom.Tests.Console.Q3.CommandSystem.pas',
  DelphiDoom.Tests.Console.Q3.StandardCommands in 'Source\DelphiDoom.Tests.Console.Q3.StandardCommands.pas',
  DelphiDoom.Tests.Console.Q3.CVarSystem in 'Source\DelphiDoom.Tests.Console.Q3.CVarSystem.pas',
  DelphiDoom.Tests.Console.Q3.CVarCommands in 'Source\DelphiDoom.Tests.Console.Q3.CVarCommands.pas',
  DelphiDoom.Tests.Console.Q3.Factory in 'Source\DelphiDoom.Tests.Console.Q3.Factory.pas';

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
