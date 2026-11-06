{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - the factory: the composition root             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Factory;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.GameState.Intf, DelphiDoom.Console.Intf,
  DelphiDoom.Console.AutoExec, DelphiDoom.Console.CommandQueue, DelphiDoom.Console.CheatTable,
  DelphiDoom.Console.CheatSequence, DelphiDoom.Console.Completer, DelphiDoom.Console.History,
  DelphiDoom.Console.InputLine, DelphiDoom.Console.StandardCommands,
  DelphiDoom.Console.VariableCommands;

type
  /// <summary>
  ///   The only place that knows the classes of the console. What gives back an object (not an
  ///   interface) is owned by the caller
  /// </summary>
  TConsoleFactory = class
  public
    class function CreateRegistry: ICommandRegistry; static;
    class function CreateInterpreter(const ARegistry: ICommandRegistry): IConsoleInterpreter; static;
    class function CreateScriptRunner(const AInterpreter: IConsoleInterpreter;
      const AFileSystem: IConsoleFileSystem; const AOutput: IConsoleOutput;
      const ALog: ILog): IConsoleScriptRunner; static;
    class function CreateVariableCommands(const ARegistry: ICommandRegistry;
      const AVariables: IConsoleVariableSource; const AOutput: IConsoleOutput; const ALog: ILog;
      const AGame: IGameContext): TConsoleVariableCommands; static;
    class function CreateStandardCommands(const ARegistry: ICommandRegistry;
      const AOutput: IConsoleOutput; const ARunner: IConsoleScriptRunner): TConsoleStandardCommands; static;
    class function CreateAutoExec(const AStartup: IConsoleStartupSource;
      const ARunner: IConsoleScriptRunner; const AOutput: IConsoleOutput;
      const AApplicationTitle: string): TConsoleAutoExec; static;
    class function CreateCommandQueue(const AInterpreter: IConsoleInterpreter): TConsoleCommandQueue; static;
    class function CreateHistory: TConsoleHistory; static;
    class function CreateCompleter(const ARegistry: ICommandRegistry;
      const AVariables: IConsoleVariableSource): TConsoleCompleter; static;
    /// <summary>The line owns AHistory and ACompleter (the completer may be nil)</summary>
    class function CreateInputLine(const APrompt: string; const AInterpreter: IConsoleInterpreter;
      const AOutput: IConsoleOutput; AHistory: TConsoleHistory;
      ACompleter: TConsoleCompleter): TConsoleInputLine; static;
    class function CreateCheatTable: TCheatTable; static;
    class function CreateCheatSequence(const ASequence: AnsiString): TCheatSequence; static;
  end;

implementation

uses
  DelphiDoom.Console.CommandRegistry, DelphiDoom.Console.Interpreter,
  DelphiDoom.Console.ScriptRunner;

{ TConsoleFactory }

class function TConsoleFactory.CreateRegistry: ICommandRegistry;
begin
  Result := TCommandRegistry.Create;
end;

class function TConsoleFactory.CreateInterpreter(const ARegistry: ICommandRegistry): IConsoleInterpreter;
begin
  Result := TConsoleInterpreter.Create(ARegistry);
end;

class function TConsoleFactory.CreateScriptRunner(const AInterpreter: IConsoleInterpreter;
  const AFileSystem: IConsoleFileSystem; const AOutput: IConsoleOutput;
  const ALog: ILog): IConsoleScriptRunner;
begin
  Result := TConsoleScriptRunner.Create(AInterpreter, AFileSystem, AOutput, ALog);
end;

class function TConsoleFactory.CreateVariableCommands(const ARegistry: ICommandRegistry;
  const AVariables: IConsoleVariableSource; const AOutput: IConsoleOutput; const ALog: ILog;
  const AGame: IGameContext): TConsoleVariableCommands;
begin
  Result := TConsoleVariableCommands.Create(ARegistry, AVariables, AOutput, ALog, AGame);
end;

class function TConsoleFactory.CreateStandardCommands(const ARegistry: ICommandRegistry;
  const AOutput: IConsoleOutput; const ARunner: IConsoleScriptRunner): TConsoleStandardCommands;
begin
  Result := TConsoleStandardCommands.Create(ARegistry, AOutput, ARunner);
end;

class function TConsoleFactory.CreateAutoExec(const AStartup: IConsoleStartupSource;
  const ARunner: IConsoleScriptRunner; const AOutput: IConsoleOutput;
  const AApplicationTitle: string): TConsoleAutoExec;
begin
  Result := TConsoleAutoExec.Create(AStartup, ARunner, AOutput, AApplicationTitle);
end;

class function TConsoleFactory.CreateCommandQueue(
  const AInterpreter: IConsoleInterpreter): TConsoleCommandQueue;
begin
  Result := TConsoleCommandQueue.Create(AInterpreter);
end;

class function TConsoleFactory.CreateHistory: TConsoleHistory;
begin
  Result := TConsoleHistory.Create;
end;

class function TConsoleFactory.CreateCompleter(const ARegistry: ICommandRegistry;
  const AVariables: IConsoleVariableSource): TConsoleCompleter;
begin
  Result := TConsoleCompleter.Create(ARegistry, AVariables);
end;

class function TConsoleFactory.CreateInputLine(const APrompt: string;
  const AInterpreter: IConsoleInterpreter; const AOutput: IConsoleOutput;
  AHistory: TConsoleHistory; ACompleter: TConsoleCompleter): TConsoleInputLine;
begin
  Result := TConsoleInputLine.Create(APrompt, AInterpreter, AOutput, AHistory, ACompleter);
end;

class function TConsoleFactory.CreateCheatTable: TCheatTable;
begin
  Result := TCheatTable.Create;
end;

class function TConsoleFactory.CreateCheatSequence(const ASequence: AnsiString): TCheatSequence;
begin
  Result := TCheatSequence.Create(ASequence);
end;

end.
