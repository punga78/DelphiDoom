{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the key calls of cgame and ui           }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_cgame.c and   }
{  cl_ui.c (Key_KeynumToStringBuf, Key_GetBindingBuf and the Key_* calls).      }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the      }
{  Quake III Arena source code and is therefore available under the GNU         }
{  General Public License, version 2 or (at your option) any later version.     }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.ClientKeySyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Client.Intf;

type
  /// <summary>
  ///   CG_KEY_ISDOWN, CG_KEY_GETCATCHER, CG_KEY_SETCATCHER, CG_KEY_GETKEY and UI_KEY_KEYNUMTOSTRINGBUF,
  ///   UI_KEY_GETBINDINGBUF, UI_KEY_SETBINDING, UI_KEY_ISDOWN, UI_KEY_GETOVERSTRIKEMODE,
  ///   UI_KEY_SETOVERSTRIKEMODE, UI_KEY_CLEARSTATES, UI_KEY_GETCATCHER, UI_KEY_SETCATCHER
  /// </summary>
  TQ3KeySyscalls = class
  public
    class procedure Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
      const AKeys: IQ3HostKeys); static;
  end;

implementation

uses
  DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Arguments;

class procedure TQ3KeySyscalls.Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
  const AKeys: IQ3HostKeys);
begin
  case AModule of
    TQ3Module.CGame:
      begin
        ARegistry.Register(CG_KEY_ISDOWN,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            Result := Ord(AKeys.IsDown(AArgs[1]));
          end);
        ARegistry.Register(CG_KEY_GETCATCHER,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            Result := AKeys.GetCatcher;
          end);
        ARegistry.Register(CG_KEY_SETCATCHER,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            AKeys.SetCatcher(AArgs[1]);
            Result := 0;
          end);
        ARegistry.Register(CG_KEY_GETKEY,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            // a NULL binding is no key
            if AArgs[1] = 0 then
              Exit(-1);
            Result := AKeys.GetKey(AMachine.Memory.ReadString(AArgs[1]));
          end);
      end;
    TQ3Module.Ui:
      begin
        ARegistry.Register(UI_KEY_KEYNUMTOSTRINGBUF,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            AMachine.Memory.WriteString(AArgs[2], AKeys.KeynumToString(AArgs[1]), AArgs[3]);
            Result := 0;
          end);
        ARegistry.Register(UI_KEY_GETBINDINGBUF,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          var
            LBinding: AnsiString;
          begin
            // an unbound key only puts a zero in the first byte (*buf = 0), a binding is copied by Q_strncpyz
            LBinding := AKeys.GetBinding(AArgs[1]);
            if LBinding = '' then
              AMachine.Memory.WriteByte(AArgs[2], 0)
            else
              AMachine.Memory.WriteString(AArgs[2], LBinding, AArgs[3]);
            Result := 0;
          end);
        ARegistry.Register(UI_KEY_SETBINDING,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            AKeys.SetBinding(AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2], 'UI_KEY_SETBINDING'));
            Result := 0;
          end);
        ARegistry.Register(UI_KEY_ISDOWN,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            Result := Ord(AKeys.IsDown(AArgs[1]));
          end);
        ARegistry.Register(UI_KEY_GETOVERSTRIKEMODE,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            Result := Ord(AKeys.GetOverstrikeMode);
          end);
        ARegistry.Register(UI_KEY_SETOVERSTRIKEMODE,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            AKeys.SetOverstrikeMode(AArgs[1] <> 0);
            Result := 0;
          end);
        ARegistry.Register(UI_KEY_CLEARSTATES,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            AKeys.ClearStates;
            Result := 0;
          end);
        ARegistry.Register(UI_KEY_GETCATCHER,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            Result := AKeys.GetCatcher;
          end);
        ARegistry.Register(UI_KEY_SETCATCHER,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            AKeys.SetCatcher(AArgs[1]);
            Result := 0;
          end);
      end;
  end;
end;

end.
