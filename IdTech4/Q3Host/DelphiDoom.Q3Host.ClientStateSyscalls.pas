{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the state of the client seen by         }
{  cgame and ui                                                                 }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_cgame.c and   }
{  cl_ui.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is derived      }
{  from the Quake III Arena source code and is therefore available under the    }
{  GNU General Public License, version 2 or (at your option) any later          }
{  version.                                                                     }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.ClientStateSyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Client.Intf;

type
  /// <summary>
  ///   CG_GETGAMESTATE, CG_GETCURRENTSNAPSHOTNUMBER, CG_GETSNAPSHOT, CG_GETSERVERCOMMAND, CG_GETCURRENTCMDNUMBER,
  ///   CG_GETUSERCMD, CG_SETUSERCMDVALUE, CG_SENDCLIENTCOMMAND of cgame, and UI_GETCONFIGSTRING,
  ///   UI_GETCLIENTSTATE of ui. Only the fields the C writes are written: the rest of snapshot_t (the server
  ///   commands of the snapshot, "FIXME" in the C) is the memory of the module as it was
  /// </summary>
  TQ3ClientStateSyscalls = class
  public
    class procedure RegisterCGame(const ARegistry: IQ3SyscallRegistry; const AState: IQ3HostClientState); static;
    class procedure RegisterUi(const ARegistry: IQ3SyscallRegistry; const AState: IQ3HostClientState;
      const AConnection: IQ3HostUiConnection); static;
    /// <summary>
    ///   CG_UPDATESCREEN, CG_MEMORY_REMAINING, UI_UPDATESCREEN, UI_MEMORY_REMAINING and UI_GETCLIPBOARDDATA
    /// </summary>
    class procedure RegisterSystem(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
      const ASystem: IQ3HostClientSystem); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Client.Types,
  DelphiDoom.Q3Host.Arguments;

class procedure TQ3ClientStateSyscalls.RegisterCGame(const ARegistry: IQ3SyscallRegistry;
  const AState: IQ3HostClientState);
begin
  ARegistry.Register(CG_GETGAMESTATE,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      AMachine.Memory.WriteBytes(AArgs[1], AState.GameState);
      Result := 0;
    end);

  ARegistry.Register(CG_GETCURRENTSNAPSHOTNUMBER,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    var
      LNumber, LServerTime: Integer;
    begin
      AState.CurrentSnapshotNumber(LNumber, LServerTime);
      AMachine.Memory.WriteInt32(AArgs[1], LNumber);
      AMachine.Memory.WriteInt32(AArgs[2], LServerTime);
      Result := 0;
    end);

  ARegistry.Register(CG_GETSNAPSHOT,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    var
      LSnapshot: TQ3HostSnapshot;
      LMemory: IQvmMemory;
      LAddress: Integer;
    begin
      Result := 0;
      if not AState.TryGetSnapshot(AArgs[1], LSnapshot) then
        Exit;
      LMemory := AMachine.Memory;
      LAddress := AArgs[2];
      LMemory.WriteInt32(LAddress, LSnapshot.SnapFlags);
      LMemory.WriteInt32(LAddress + Q3_SNAPSHOT_SERVERCOMMANDSEQUENCE, LSnapshot.ServerCommandSequence);
      LMemory.WriteInt32(LAddress + Q3_SNAPSHOT_PING, LSnapshot.Ping);
      LMemory.WriteInt32(LAddress + Q3_SNAPSHOT_SERVERTIME, LSnapshot.ServerTime);
      Move(LSnapshot.AreaMask, LMemory.Range(LAddress + Q3_SNAPSHOT_AREAMASK, SizeOf(LSnapshot.AreaMask))^,
        SizeOf(LSnapshot.AreaMask));
      Move(LSnapshot.PlayerState, LMemory.Range(LAddress + Q3_SNAPSHOT_PS, SizeOf(LSnapshot.PlayerState))^,
        SizeOf(LSnapshot.PlayerState));
      LMemory.WriteInt32(LAddress + Q3_SNAPSHOT_NUMENTITIES, LSnapshot.NumEntities);
      if LSnapshot.NumEntities > 0 then
        LMemory.WriteBytes(LAddress + Q3_SNAPSHOT_ENTITIES, LSnapshot.Entities);
      Result := 1;
    end);

  ARegistry.Register(CG_GETSERVERCOMMAND,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := Ord(AState.GetServerCommand(AArgs[1]));
    end);

  ARegistry.Register(CG_GETCURRENTCMDNUMBER,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := AState.CurrentCommandNumber;
    end);

  ARegistry.Register(CG_GETUSERCMD,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    var
      LCommand: TQ3HostUserCmd;
    begin
      Result := Ord(AState.TryGetUserCmd(AArgs[1], LCommand));
      if Result <> 0 then
        Move(LCommand, AMachine.Memory.Range(AArgs[2], SizeOf(LCommand))^, SizeOf(LCommand));
    end);

  ARegistry.Register(CG_SETUSERCMDVALUE,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      AState.SetUserCmdValue(AArgs[1], TQ3SyscallArguments.ToSingle(AArgs[2]));
      Result := 0;
    end);

  ARegistry.Register(CG_SENDCLIENTCOMMAND,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      AState.AddReliableCommand(TQ3SyscallArguments.Text(AMachine, AArgs[1], 'CG_SENDCLIENTCOMMAND'));
      Result := 0;
    end);
end;

class procedure TQ3ClientStateSyscalls.RegisterUi(const ARegistry: IQ3SyscallRegistry;
  const AState: IQ3HostClientState; const AConnection: IQ3HostUiConnection);
begin
  if Assigned(AState) then
    ARegistry.Register(UI_GETCONFIGSTRING,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LValue: AnsiString;
      begin
        if AState.TryGetConfigString(AArgs[1], LValue) then
        begin
          AMachine.Memory.WriteString(AArgs[2], LValue, AArgs[3]);
          Exit(1);
        end;
        // an index in range with no string: the buffer is emptied if there is room
        if (AArgs[1] >= 0) and (AArgs[1] < Q3_MAX_CONFIGSTRINGS) and (AArgs[3] <> 0) then
          AMachine.Memory.WriteByte(AArgs[2], 0);
        Result := 0;
      end);

  if Assigned(AConnection) then
    ARegistry.Register(UI_GETCLIENTSTATE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LState: TQ3HostUiClientState;
        LMemory: IQvmMemory;
        LAddress: Integer;
      begin
        LState := AConnection.GetClientState;
        LMemory := AMachine.Memory;
        LAddress := AArgs[1];
        LMemory.WriteInt32(LAddress + 4, LState.ConnectPacketCount);
        LMemory.WriteInt32(LAddress, LState.ConnectionState);
        LMemory.WriteString(LAddress + Q3_UICLIENTSTATE_SERVERNAME, LState.ServerName, Q3_MAX_STRING_CHARS);
        LMemory.WriteString(LAddress + Q3_UICLIENTSTATE_UPDATEINFO, LState.UpdateInfoString, Q3_MAX_STRING_CHARS);
        LMemory.WriteString(LAddress + Q3_UICLIENTSTATE_MESSAGE, LState.MessageString, Q3_MAX_STRING_CHARS);
        LMemory.WriteInt32(LAddress + 8, LState.ClientNumber);
        Result := 0;
      end);
end;

class procedure TQ3ClientStateSyscalls.RegisterSystem(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
  const ASystem: IQ3HostClientSystem);
begin
  case AModule of
    TQ3Module.CGame:
      begin
        ARegistry.Register(CG_UPDATESCREEN,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ASystem.UpdateScreen;
            Result := 0;
          end);
        ARegistry.Register(CG_MEMORY_REMAINING,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            Result := ASystem.MemoryRemaining;
          end);
      end;
    TQ3Module.Ui:
      begin
        ARegistry.Register(UI_UPDATESCREEN,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ASystem.UpdateScreen;
            Result := 0;
          end);
        ARegistry.Register(UI_MEMORY_REMAINING,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            Result := ASystem.MemoryRemaining;
          end);
        ARegistry.Register(UI_GETCLIPBOARDDATA,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          var
            LText: AnsiString;
          begin
            // no clipboard only puts a zero in the first byte (*buf = 0), a text is copied by Q_strncpyz
            LText := ASystem.ClipboardText;
            if LText = '' then
              AMachine.Memory.WriteByte(AArgs[1], 0)
            else
              AMachine.Memory.WriteString(AArgs[1], LText, AArgs[2]);
            Result := 0;
          end);
      end;
  end;
end;

end.
