{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the cvar and command system calls      }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_game.c,      }
{  cl_cgame.c, cl_ui.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is  }
{  derived from the Quake III Arena source code and is therefore available      }
{  under the GNU General Public License, version 2 or (at your option) any      }
{  later version.                                                               }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.CvarSyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Console.Q3.Intf, DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf;

type
  /// <summary>
  ///   Cvar_Register, Cvar_Update, Cvar_Set, Cvar_VariableValue, Cvar_VariableIntegerValue,
  ///   Cvar_VariableStringBuffer, Cvar_SetValue, Cvar_Reset, Cvar_Get, Cvar_InfoStringBuffer, Cmd_Argc, Cmd_ArgvBuffer,
  ///   Cmd_ArgsBuffer, Cbuf_ExecuteText, Cbuf_AddText, Cmd_AddCommand and Cmd_RemoveCommand as the three modules
  ///   call them: each module has the subset of sv_game.c, cl_cgame.c and cl_ui.c. The work is the one of
  ///   IQ3CVarSystem, IQ3CommandArguments and IQ3CommandBuffer (Framework\Console, equal to the C); here only the
  ///   vmCvar_t of 272 bytes (handle, modificationCount, value, integer, string[256]) is read and written in the
  ///   data of the program
  /// </summary>
  TQ3CvarSyscalls = class
  public
    class procedure Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry; const ACVars: IQ3CVarSystem;
      const AArguments: IQ3CommandArguments; const ABuffer: IQ3CommandBuffer;
      const ACommands: IQ3CommandRegistry); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Console.Q3.Types,
  DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Arguments;

const
  // the layout of vmCvar_t (Tests\Data\Q3Host\layout.golden.txt)
  VMCVAR_MODIFICATION_COUNT = 4;
  VMCVAR_VALUE = 8;
  VMCVAR_INTEGER = 12;
  VMCVAR_STRING = 16;
  MAX_CVAR_VALUE_STRING = 256;
  NONE = -1;

type
  TCvarNumbers = record
    Register, Update, SetText, VariableValue, VariableInteger, VariableStringBuffer, SetValue, Reset, Create,
    InfoStringBuffer, Argc, Argv, Args, ExecuteText, AddText, AddCommand, RemoveCommand: Integer;
  end;

const
  CVAR_NUMBERS: array[TQ3Module] of TCvarNumbers = (
    (Register: G_CVAR_REGISTER; Update: G_CVAR_UPDATE; SetText: G_CVAR_SET; VariableValue: NONE;
     VariableInteger: G_CVAR_VARIABLE_INTEGER_VALUE; VariableStringBuffer: G_CVAR_VARIABLE_STRING_BUFFER;
     SetValue: NONE; Reset: NONE; Create: NONE; InfoStringBuffer: NONE; Argc: G_ARGC; Argv: G_ARGV; Args: NONE;
     ExecuteText: G_SEND_CONSOLE_COMMAND; AddText: NONE; AddCommand: NONE; RemoveCommand: NONE),
    (Register: CG_CVAR_REGISTER; Update: CG_CVAR_UPDATE; SetText: CG_CVAR_SET; VariableValue: NONE;
     VariableInteger: NONE; VariableStringBuffer: CG_CVAR_VARIABLESTRINGBUFFER; SetValue: NONE; Reset: NONE;
     Create: NONE; InfoStringBuffer: NONE; Argc: CG_ARGC; Argv: CG_ARGV; Args: CG_ARGS; ExecuteText: NONE;
     AddText: CG_SENDCONSOLECOMMAND; AddCommand: CG_ADDCOMMAND; RemoveCommand: CG_REMOVECOMMAND),
    (Register: UI_CVAR_REGISTER; Update: UI_CVAR_UPDATE; SetText: UI_CVAR_SET; VariableValue: UI_CVAR_VARIABLEVALUE;
     VariableInteger: NONE; VariableStringBuffer: UI_CVAR_VARIABLESTRINGBUFFER; SetValue: UI_CVAR_SETVALUE;
     Reset: UI_CVAR_RESET; Create: UI_CVAR_CREATE; InfoStringBuffer: UI_CVAR_INFOSTRINGBUFFER; Argc: UI_ARGC;
     Argv: UI_ARGV; Args: NONE; ExecuteText: UI_CMD_EXECUTETEXT; AddText: NONE; AddCommand: NONE;
     RemoveCommand: NONE));
  CALL_NAMES: array[TQ3Module] of string = ('qagame', 'cgame', 'ui');

procedure ReadVmCvar(const AMemory: IQvmMemory; AAddress: Integer; out AVmCvar: TQ3VmCvar);
begin
  AVmCvar.Handle := AMemory.ReadInt32(AAddress);
  AVmCvar.ModificationCount := AMemory.ReadInt32(AAddress + VMCVAR_MODIFICATION_COUNT);
  AVmCvar.Value := 0;
  AVmCvar.IntegerValue := 0;
  AVmCvar.StringValue := '';
end;

procedure WriteVmCvar(const AMemory: IQvmMemory; AAddress: Integer; const AVmCvar: TQ3VmCvar; AWriteHandle: Boolean);
begin
  if AWriteHandle then
    AMemory.WriteInt32(AAddress, AVmCvar.Handle);
  AMemory.WriteInt32(AAddress + VMCVAR_MODIFICATION_COUNT, AVmCvar.ModificationCount);
  AMemory.WriteInt32(AAddress + VMCVAR_VALUE, TQ3SyscallArguments.FromSingle(AVmCvar.Value));
  AMemory.WriteInt32(AAddress + VMCVAR_INTEGER, AVmCvar.IntegerValue);
  AMemory.WriteString(AAddress + VMCVAR_STRING, AVmCvar.StringValue, MAX_CVAR_VALUE_STRING);
end;

class procedure TQ3CvarSyscalls.Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
  const ACVars: IQ3CVarSystem; const AArguments: IQ3CommandArguments; const ABuffer: IQ3CommandBuffer;
  const ACommands: IQ3CommandRegistry);
var
  LNumbers: TCvarNumbers;
  LName: string;
begin
  LNumbers := CVAR_NUMBERS[AModule];
  LName := CALL_NAMES[AModule];

  if LNumbers.Register <> NONE then
    ARegistry.Register(LNumbers.Register,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LVmCvar: TQ3VmCvar;
        LCVarName, LDefault: AnsiString;
      begin
        LCVarName := TQ3SyscallArguments.Text(AMachine, AArgs[2], LName);
        LDefault := TQ3SyscallArguments.Text(AMachine, AArgs[3], LName);
        // a null vmCvar only creates the variable
        if AArgs[1] = 0 then
          ACVars.Get(LCVarName, LDefault, AArgs[4])
        else
        begin
          ReadVmCvar(AMachine.Memory, AArgs[1], LVmCvar);
          ACVars.Register(LVmCvar, LCVarName, LDefault, AArgs[4]);
          WriteVmCvar(AMachine.Memory, AArgs[1], LVmCvar, True);
        end;
        Result := 0;
      end);

  if LNumbers.Update <> NONE then
    ARegistry.Register(LNumbers.Update,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LVmCvar: TQ3VmCvar;
        LBefore: Integer;
      begin
        ReadVmCvar(AMachine.Memory, AArgs[1], LVmCvar);
        LBefore := LVmCvar.ModificationCount;
        ACVars.Update(LVmCvar);
        // the C writes only when the count changed
        if LVmCvar.ModificationCount <> LBefore then
          WriteVmCvar(AMachine.Memory, AArgs[1], LVmCvar, False);
        Result := 0;
      end);

  if LNumbers.SetText <> NONE then
    ARegistry.Register(LNumbers.SetText,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ACVars.SetValueText(TQ3SyscallArguments.Text(AMachine, AArgs[1], LName),
          TQ3SyscallArguments.Text(AMachine, AArgs[2], LName));
        Result := 0;
      end);

  if LNumbers.VariableValue <> NONE then
    ARegistry.Register(LNumbers.VariableValue,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := TQ3SyscallArguments.FromSingle(
          ACVars.VariableValue(TQ3SyscallArguments.Text(AMachine, AArgs[1], LName)));
      end);

  if LNumbers.VariableInteger <> NONE then
    ARegistry.Register(LNumbers.VariableInteger,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ACVars.VariableIntegerValue(TQ3SyscallArguments.Text(AMachine, AArgs[1], LName));
      end);

  if LNumbers.VariableStringBuffer <> NONE then
    ARegistry.Register(LNumbers.VariableStringBuffer,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LCVarName: AnsiString;
      begin
        LCVarName := TQ3SyscallArguments.Text(AMachine, AArgs[1], LName);
        if (ACVars.Find(LCVarName) <> nil) and (AArgs[3] < 1) then
          raise EQ3ModuleErrorException.Create('Q_strncpyz: destsize < 1');
        if ACVars.Find(LCVarName) = nil then
          // *buffer = 0
          AMachine.Memory.WriteByte(AArgs[2], 0)
        else
          // Q_strncpyz: a size below 1 is the error of the C
          AMachine.Memory.WriteString(AArgs[2], ACVars.VariableStringBuffer(LCVarName, AArgs[3]), AArgs[3]);
        Result := 0;
      end);

  if LNumbers.SetValue <> NONE then
    ARegistry.Register(LNumbers.SetValue,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ACVars.SetNumber(TQ3SyscallArguments.Text(AMachine, AArgs[1], LName),
          TQ3SyscallArguments.ToSingle(AArgs[2]));
        Result := 0;
      end);

  if LNumbers.Reset <> NONE then
    ARegistry.Register(LNumbers.Reset,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ACVars.Reset(TQ3SyscallArguments.Text(AMachine, AArgs[1], LName));
        Result := 0;
      end);

  if LNumbers.Create <> NONE then
    ARegistry.Register(LNumbers.Create,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ACVars.Get(TQ3SyscallArguments.Text(AMachine, AArgs[1], LName),
          TQ3SyscallArguments.Text(AMachine, AArgs[2], LName), AArgs[3]);
        Result := 0;
      end);

  if LNumbers.InfoStringBuffer <> NONE then
    ARegistry.Register(LNumbers.InfoStringBuffer,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        AMachine.Memory.WriteString(AArgs[2], ACVars.InfoStringBuffer(AArgs[1], AArgs[3]), AArgs[3]);
        Result := 0;
      end);

  if LNumbers.Argc <> NONE then
    ARegistry.Register(LNumbers.Argc,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := AArguments.Count;
      end);

  if LNumbers.Argv <> NONE then
    ARegistry.Register(LNumbers.Argv,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        AMachine.Memory.WriteString(AArgs[2], AArguments.ArgvBuffer(AArgs[1], AArgs[3]), AArgs[3]);
        Result := 0;
      end);

  if LNumbers.Args <> NONE then
    ARegistry.Register(LNumbers.Args,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        AMachine.Memory.WriteString(AArgs[1], AArguments.ArgsBuffer(AArgs[2]), AArgs[2]);
        Result := 0;
      end);

  if LNumbers.ExecuteText <> NONE then
    ARegistry.Register(LNumbers.ExecuteText,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        // cbufExec_t: EXEC_NOW 0, EXEC_INSERT 1, EXEC_APPEND 2
        if (AArgs[1] < 0) or (AArgs[1] > 2) then
          raise EQ3HostException.CreateFmt('Cbuf_ExecuteText: bad execution time %d', [AArgs[1]]);
        ABuffer.ExecuteText(TQ3Execution(AArgs[1]), TQ3SyscallArguments.Text(AMachine, AArgs[2], LName));
        Result := 0;
      end);

  if LNumbers.AddText <> NONE then
    ARegistry.Register(LNumbers.AddText,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ABuffer.AddText(TQ3SyscallArguments.Text(AMachine, AArgs[1], LName));
        Result := 0;
      end);

  if LNumbers.AddCommand <> NONE then
    ARegistry.Register(LNumbers.AddCommand,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        // CL_AddCgameCommand: a command the client game handles itself (no function)
        ACommands.AddCommand(TQ3SyscallArguments.Text(AMachine, AArgs[1], LName), nil);
        Result := 0;
      end);

  if LNumbers.RemoveCommand <> NONE then
    ARegistry.Register(LNumbers.RemoveCommand,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ACommands.RemoveCommand(TQ3SyscallArguments.Text(AMachine, AArgs[1], LName));
        Result := 0;
      end);
end;

end.
