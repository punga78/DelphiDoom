{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the CD key calls of ui                  }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_ui.c          }
{  (CLUI_GetCDKey, CLUI_SetCDKey, UI_usesUniqueCDKey, UI_VERIFY_CDKEY and       }
{  UI_SET_PBCLSTATUS). Copyright (C) 1999-2005 Id Software, Inc. This unit is   }
{  derived from the Quake III Arena source code and is therefore available      }
{  under the GNU General Public License, version 2 or (at your option) any      }
{  later version.                                                               }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.UiCdKeySyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Console.Q3.Intf, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.ClientCdKey;

type
  /// <summary>
  ///   UI_GET_CDKEY, UI_SET_CDKEY, UI_VERIFY_CDKEY and UI_SET_PBCLSTATUS. Whether the second key is the one in use
  ///   is asked to the module (UI_HASUNIQUECDKEY, a call into the machine from inside a system call) and to the
  ///   cvar fs_game, as CLUI_GetCDKey does
  /// </summary>
  TQ3CdKeySyscalls = class
  public
    class procedure Register(const ARegistry: IQ3SyscallRegistry; const AKey: TQ3ClientCdKey;
      const ACVars: IQ3CVarSystem); static;
  end;

implementation

uses
  DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.CVar,
  DelphiDoom.Q3Host.Opcodes;

function UsesUniqueKey(const AMachine: IQvmMachine; const ACVars: IQ3CVarSystem): Boolean;
var
  LGame: TQ3CVar;
begin
  LGame := ACVars.Get('fs_game', '', Q3_CVAR_INIT or Q3_CVAR_SYSTEMINFO);
  // UI_usesUniqueCDKey: VM_Call( uivm, UI_HASUNIQUECDKEY ) == qtrue
  Result := (AMachine.Call(UI_HASUNIQUECDKEY, []) = 1) and Assigned(LGame) and (LGame.StringValue <> '');
end;

class procedure TQ3CdKeySyscalls.Register(const ARegistry: IQ3SyscallRegistry; const AKey: TQ3ClientCdKey;
  const ACVars: IQ3CVarSystem);
begin
  ARegistry.Register(UI_GET_CDKEY,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      // the 16 characters and a zero, whatever the length of the buffer
      AMachine.Memory.WriteBytes(AArgs[1], AKey.Get(UsesUniqueKey(AMachine, ACVars)));
      Result := 0;
    end);

  ARegistry.Register(UI_SET_CDKEY,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    var
      LUnique: Boolean;
    begin
      LUnique := UsesUniqueKey(AMachine, ACVars);
      // set the flag so the file will be written at the next opportunity
      if AKey.Put(LUnique, AMachine.Memory.ReadBytes(AArgs[1], TQ3ClientCdKey.CDKEY_LEN)) then
        ACVars.ModifiedFlags := ACVars.ModifiedFlags or Q3_CVAR_ARCHIVE;
      Result := 0;
    end);

  ARegistry.Register(UI_VERIFY_CDKEY,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    var
      LKey: AnsiString;
    begin
      if AArgs[1] = 0 then
        LKey := ''
      else
        LKey := AMachine.Memory.ReadString(AArgs[1]);
      if AArgs[2] = 0 then
        Result := Ord(TQ3ClientCdKey.Validate(LKey, False, ''))
      else
        Result := Ord(TQ3ClientCdKey.Validate(LKey, True, AMachine.Memory.ReadString(AArgs[2])));
    end);

  ARegistry.Register(UI_SET_PBCLSTATUS,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := 0;
    end);
end;

end.
