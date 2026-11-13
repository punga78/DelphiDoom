{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - idTech 4 command system                       }
{                                                                              }
{  Port of Doom 3 (id Software, GPL v3): framework\CmdSystem.h, CmdSystem.cpp  }
{  (idCmdSystemLocal, without its own commands: see StandardCommands).         }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CmdSystem.System;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.CmdArgs,
  DelphiDoom.Console.CmdSystem.Types, DelphiDoom.Console.CmdSystem.Intf,
  DelphiDoom.Console.CmdSystem.CommandList, DelphiDoom.Console.CmdSystem.Buffer;

type
  /// <summary>
  ///   idCmdSystemLocal as an object (not a singleton): the list of commands, the text buffer and the
  ///   execution of a line (a registered command, else a variable, else "Unknown command").
  ///   The collaborators are all optional: without a session the game is single player, without
  ///   the cvar system a line that is not a command is unknown. A command registered with
  ///   CMD_FL_CHEAT or CMD_FL_TOOL is refused in a multiplayer game unless the variable
  ///   "net_allowCheats" is set. Use it through the interfaces (it counts references).
  /// </summary>
  TCmdSystem = class(TInterfacedObject, ICmdCommands, ICmdBuffer)
  strict private
    FLog: IIdLibLog;
    FSession: IConsoleSession;
    FCVarCommand: ICVarCommand;
    FCVars: ICVarReader;
    FList: TCmdCommandList;
    FBuffer: TCmdBuffer;
    FPostReload: TIdCmdArgs;
    procedure ExecuteTokenizedString(const AArgs: TIdCmdArgs);
    procedure ExecuteCommandText(const AText: AnsiString);
  public
    constructor Create(const ALog: IIdLibLog = nil; const ASession: IConsoleSession = nil;
      const ACVarCommand: ICVarCommand = nil; const ACVars: ICVarReader = nil);
    destructor Destroy; override;

    // ICmdCommands
    procedure AddCommand(const ACommandName: AnsiString; const AFunction: TCmdFunction; const AFlags: Integer;
      const ADescription: AnsiString); overload;
    procedure AddCommand(const ACommandName: AnsiString; const AFunction: TCmdFunction; const AFlags: Integer;
      const ADescription: AnsiString; const AArgCompletion: TCmdArgCompletion); overload;
    procedure RemoveCommand(const ACommandName: AnsiString);
    procedure RemoveFlaggedCommands(const AFlags: Integer);
    procedure CommandCompletion(const ACallback: TCmdCompletionCallback);
    procedure ArgCompletion(const ACommandString: AnsiString; const ACallback: TCmdCompletionCallback);
    function Commands: TArray<TCmdInfo>;

    // ICmdBuffer
    procedure BufferCommandText(const AExecution: TCmdExecution; const AText: AnsiString);
    procedure BufferCommandArgs(const AExecution: TCmdExecution; const AArgs: TIdCmdArgs);
    procedure ExecuteCommandBuffer;
    procedure SetWait(const AFrames: Integer);
    procedure SetupReloadEngine(const AArgs: TIdCmdArgs);
    function PostReloadEngine: Boolean;

    /// <summary>idCmdSystemLocal::Shutdown: removes every command and empties the buffer</summary>
    procedure Shutdown;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

{ TCmdSystem }

constructor TCmdSystem.Create(const ALog: IIdLibLog; const ASession: IConsoleSession;
  const ACVarCommand: ICVarCommand; const ACVars: ICVarReader);
begin
  inherited Create;
  FLog := ALog;
  FSession := ASession;
  FCVarCommand := ACVarCommand;
  FCVars := ACVars;
  FList := TCmdCommandList.Create(ALog);
  FBuffer := TCmdBuffer.Create(ExecuteTokenizedString, ALog, ACVars);
  FPostReload := TIdCmdArgs.Create(ACVars);
end;

destructor TCmdSystem.Destroy;
begin
  FPostReload.Free;
  FBuffer.Free;
  FList.Free;
  inherited Destroy;
end;

procedure TCmdSystem.AddCommand(const ACommandName: AnsiString; const AFunction: TCmdFunction; const AFlags: Integer;
  const ADescription: AnsiString);
var
  LNoCompletion: TCmdArgCompletion;
begin
  LNoCompletion := nil;
  AddCommand(ACommandName, AFunction, AFlags, ADescription, LNoCompletion);
end;

procedure TCmdSystem.AddCommand(const ACommandName: AnsiString; const AFunction: TCmdFunction; const AFlags: Integer;
  const ADescription: AnsiString; const AArgCompletion: TCmdArgCompletion);
begin
  FList.Add(ACommandName, AFunction, AFlags, ADescription, AArgCompletion);
end;

procedure TCmdSystem.RemoveCommand(const ACommandName: AnsiString);
begin
  FList.Remove(ACommandName);
end;

procedure TCmdSystem.RemoveFlaggedCommands(const AFlags: Integer);
begin
  FList.RemoveFlagged(AFlags);
end;

procedure TCmdSystem.CommandCompletion(const ACallback: TCmdCompletionCallback);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FList.Count - 1 do
    ACallback(FList.Item(LIndex).Name);
end;

procedure TCmdSystem.ArgCompletion(const ACommandString: AnsiString; const ACallback: TCmdCompletionCallback);
var
  LArgs: TIdCmdArgs;
  LDefinition: TCmdDefinition;
begin
  LArgs := TIdCmdArgs.Create(FCVars);
  try
    LArgs.TokenizeString(ACommandString, False);
    LDefinition := FList.FindWithCompletion(LArgs.Argv(0));
    if Assigned(LDefinition) then
      LDefinition.ArgCompletion(LArgs, ACallback);
  finally
    LArgs.Free;
  end;
end;

function TCmdSystem.Commands: TArray<TCmdInfo>;
var
  LIndex: Integer;
begin
  SetLength(Result, FList.Count);
  for LIndex := 0 to FList.Count - 1 do
  begin
    Result[LIndex].Name := FList.Item(LIndex).Name;
    Result[LIndex].Description := FList.Item(LIndex).Description;
    Result[LIndex].Flags := FList.Item(LIndex).Flags;
  end;
end;

procedure TCmdSystem.ExecuteTokenizedString(const AArgs: TIdCmdArgs);
var
  LDefinition: TCmdDefinition;
begin
  // execute the command line
  if AArgs.Argc = 0 then
    Exit; // no tokens

  // check registered command functions
  LDefinition := FList.FindAndPromote(AArgs.Argv(0));
  if Assigned(LDefinition) then
  begin
    if ((LDefinition.Flags and (CMD_FL_CHEAT or CMD_FL_TOOL)) <> 0) and Assigned(FSession) and
      FSession.IsMultiplayer and not (Assigned(FCVars) and FCVars.GetCVarBool('net_allowCheats')) then
    begin
      if Assigned(FLog) then
        FLog.Printf('Command ''' + string(LDefinition.Name) + ''' not valid in multiplayer mode.'#10);
      Exit;
    end;
    // perform the action; a command without function goes on to the variables
    if Assigned(LDefinition.CommandFunction) then
    begin
      LDefinition.CommandFunction(AArgs);
      Exit;
    end;
  end;

  // check cvars
  if Assigned(FCVarCommand) and FCVarCommand.Command(AArgs) then
    Exit;

  if Assigned(FLog) then
    FLog.Printf('Unknown command ''' + string(AArgs.Argv(0)) + ''''#10);
end;

procedure TCmdSystem.ExecuteCommandText(const AText: AnsiString);
var
  LArgs: TIdCmdArgs;
begin
  LArgs := TIdCmdArgs.Create(FCVars);
  try
    LArgs.TokenizeString(AText, False);
    ExecuteTokenizedString(LArgs);
  finally
    LArgs.Free;
  end;
end;

procedure TCmdSystem.BufferCommandText(const AExecution: TCmdExecution; const AText: AnsiString);
begin
  case AExecution of
    ceNow:
      ExecuteCommandText(AText);
    ceInsert:
      FBuffer.InsertText(AText);
    ceAppend:
      FBuffer.AppendText(AText);
  end;
end;

procedure TCmdSystem.BufferCommandArgs(const AExecution: TCmdExecution; const AArgs: TIdCmdArgs);
begin
  case AExecution of
    ceNow:
      ExecuteTokenizedString(AArgs);
    ceAppend:
      FBuffer.AppendTokenized(AArgs);
  else
    raise ECmdSystemException.Create('idCmdSystemLocal::BufferCommandArgs: bad exec type');
  end;
end;

procedure TCmdSystem.ExecuteCommandBuffer;
begin
  FBuffer.Execute;
end;

procedure TCmdSystem.SetWait(const AFrames: Integer);
begin
  FBuffer.SetWait(AFrames);
end;

procedure TCmdSystem.SetupReloadEngine(const AArgs: TIdCmdArgs);
begin
  BufferCommandText(ceAppend, 'reloadEngine'#10);
  FPostReload.Assign(AArgs);
end;

function TCmdSystem.PostReloadEngine: Boolean;
begin
  if FPostReload.Argc = 0 then
    Exit(False);
  BufferCommandArgs(ceAppend, FPostReload);
  FPostReload.Clear;
  Result := True;
end;

procedure TCmdSystem.Shutdown;
begin
  FList.Clear;
  FBuffer.Clear;
  FPostReload.Clear;
end;

end.
