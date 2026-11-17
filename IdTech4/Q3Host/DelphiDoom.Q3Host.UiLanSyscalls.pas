{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the server list calls of ui             }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_ui.c          }
{  (CL_UISystemCalls, the LAN_* functions). Copyright (C) 1999-2005 Id          }
{  Software, Inc. This unit is derived from the Quake III Arena source code     }
{  and is therefore available under the GNU General Public License, version 2   }
{  or (at your option) any later version.                                       }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.UiLanSyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Client.Intf;

type
  /// <summary>
  ///   The 18 UI_LAN_* calls. A text that has nothing to say (an unknown slot) only puts a zero in the first byte of
  ///   the buffer, as the C does; the others fill the buffer as Q_strncpyz does
  /// </summary>
  TQ3LanSyscalls = class
  public
    class procedure Register(const ARegistry: IQ3SyscallRegistry; const ALan: IQ3HostLan); static;
  end;

implementation

uses
  DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Arguments;

// Q_strncpyz of a text, or only the zero of the first byte when there is no text
procedure PutText(const AMachine: IQvmMachine; AAddress: Integer; const AText: AnsiString; ASize: Integer);
begin
  if AText = '' then
    AMachine.Memory.WriteByte(AAddress, 0)
  else
    AMachine.Memory.WriteString(AAddress, AText, ASize);
end;

class procedure TQ3LanSyscalls.Register(const ARegistry: IQ3SyscallRegistry; const ALan: IQ3HostLan);
begin
  ARegistry.Register(UI_LAN_LOADCACHEDSERVERS,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      ALan.LoadCachedServers;
      Result := 0;
    end);
  ARegistry.Register(UI_LAN_SAVECACHEDSERVERS,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      ALan.SaveCachedServers;
      Result := 0;
    end);
  ARegistry.Register(UI_LAN_ADDSERVER,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := ALan.AddServer(AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2], 'UI_LAN_ADDSERVER'),
        TQ3SyscallArguments.Text(AMachine, AArgs[3], 'UI_LAN_ADDSERVER'));
    end);
  ARegistry.Register(UI_LAN_REMOVESERVER,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      ALan.RemoveServer(AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2], 'UI_LAN_REMOVESERVER'));
      Result := 0;
    end);
  ARegistry.Register(UI_LAN_GETPINGQUEUECOUNT,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := ALan.GetPingQueueCount;
    end);
  ARegistry.Register(UI_LAN_CLEARPING,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      ALan.ClearPing(AArgs[1]);
      Result := 0;
    end);
  ARegistry.Register(UI_LAN_GETPING,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    var
      LAddress: AnsiString;
      LPingTime: Integer;
    begin
      ALan.GetPing(AArgs[1], LAddress, LPingTime);
      PutText(AMachine, AArgs[2], LAddress, AArgs[3]);
      AMachine.Memory.WriteInt32(AArgs[4], LPingTime);
      Result := 0;
    end);
  ARegistry.Register(UI_LAN_GETPINGINFO,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      if AArgs[3] <> 0 then
        PutText(AMachine, AArgs[2], ALan.GetPingInfo(AArgs[1]), AArgs[3]);
      Result := 0;
    end);
  ARegistry.Register(UI_LAN_GETSERVERCOUNT,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := ALan.GetServerCount(AArgs[1]);
    end);
  ARegistry.Register(UI_LAN_GETSERVERADDRESSSTRING,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      PutText(AMachine, AArgs[3], ALan.GetServerAddressString(AArgs[1], AArgs[2]), AArgs[4]);
      Result := 0;
    end);
  ARegistry.Register(UI_LAN_GETSERVERINFO,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      PutText(AMachine, AArgs[3], ALan.GetServerInfo(AArgs[1], AArgs[2]), AArgs[4]);
      Result := 0;
    end);
  ARegistry.Register(UI_LAN_GETSERVERPING,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := ALan.GetServerPing(AArgs[1], AArgs[2]);
    end);
  ARegistry.Register(UI_LAN_MARKSERVERVISIBLE,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      ALan.MarkServerVisible(AArgs[1], AArgs[2], AArgs[3] <> 0);
      Result := 0;
    end);
  ARegistry.Register(UI_LAN_SERVERISVISIBLE,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := Ord(ALan.ServerIsVisible(AArgs[1], AArgs[2]));
    end);
  ARegistry.Register(UI_LAN_UPDATEVISIBLEPINGS,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := Ord(ALan.UpdateVisiblePings(AArgs[1]));
    end);
  ARegistry.Register(UI_LAN_RESETPINGS,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      ALan.ResetPings(AArgs[1]);
      Result := 0;
    end);
  ARegistry.Register(UI_LAN_SERVERSTATUS,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    var
      LStatus: AnsiString;
    begin
      // a NULL address resets the requests of the client: nothing is pending here
      if AArgs[1] = 0 then
        Exit(0);
      Result := ALan.ServerStatus(AMachine.Memory.ReadString(AArgs[1]), LStatus);
      if Result <> 0 then
        AMachine.Memory.WriteString(AArgs[2], LStatus, AArgs[3]);
    end);
  ARegistry.Register(UI_LAN_COMPARESERVERS,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := ALan.CompareServers(AArgs[1], AArgs[2], AArgs[3], AArgs[4], AArgs[5]);
    end);
end;

end.
