{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the system calls only qagame has       }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_game.c       }
{  (SV_GameSystemCalls). Copyright (C) 1999-2005 Id Software, Inc. This unit   }
{  is derived from the Quake III Arena source code and is therefore available  }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.GameSyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Console.Q3.Intf, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Services.Intf, DelphiDoom.Q3Host.GameWorld,
  DelphiDoom.Q3Host.EntityTokens;

type
  /// <summary>
  ///   G_LOCATE_GAME_DATA, G_DROP_CLIENT, G_SEND_SERVER_COMMAND, the configstrings, the user infos and the
  ///   server info, G_SET_BRUSH_MODEL, G_TRACE, G_TRACECAPSULE, G_POINT_CONTENTS, G_IN_PVS, the area portals,
  ///   G_LINKENTITY, G_UNLINKENTITY, G_ENTITIES_IN_BOX, G_ENTITY_CONTACT, the bots, G_GET_USERCMD,
  ///   G_GET_ENTITY_TOKEN and the two debug polygon calls (which do nothing: a debug drawing) of sv_game.c. The
  ///   work is the world (TQ3GameWorld, sv_world.c), the server state and the commands the server sends; here
  ///   the arguments are read and the answers written in the data of the program
  /// </summary>
  TQ3GameSyscalls = class
  public
    class procedure Register(const ARegistry: IQ3SyscallRegistry; const AWorld: TQ3GameWorld;
      const AState: IQ3HostServerState; const ACommands: IQ3HostServerCommands; const AClipMap: IQ3HostClipMap;
      const ATokens: TQ3EntityTokens; const ACVars: IQ3CVarSystem); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Console.Q3.Types,
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Arguments,
  DelphiDoom.Q3Host.TraceMemory;

resourcestring
  SBufferTooSmall = '%s: bufferSize == %d';
  SNoMap = 'The collision model was used before a map was loaded';

// VMA of a string that may be NULL: the C turns it into ""
function OptionalText(const AMachine: IQvmMachine; AAddress: Integer; const ACall: string): AnsiString;
begin
  if AAddress = 0 then
    Result := ''
  else
    Result := TQ3SyscallArguments.Text(AMachine, AAddress, ACall);
end;

procedure RequireBuffer(ASize: Integer; const ACall: string);
begin
  if ASize < 1 then
    raise EQ3HostException.CreateFmt(SBufferTooSmall, [ACall, ASize]);
end;

class procedure TQ3GameSyscalls.Register(const ARegistry: IQ3SyscallRegistry; const AWorld: TQ3GameWorld;
  const AState: IQ3HostServerState; const ACommands: IQ3HostServerCommands; const AClipMap: IQ3HostClipMap;
  const ATokens: TQ3EntityTokens; const ACVars: IQ3CVarSystem);
  procedure TraceCall(ANumber: Integer; ACapsule: Boolean);
  begin
    ARegistry.Register(ANumber,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LMemory: IQvmMemory;
      begin
        LMemory := AMachine.Memory;
        TQ3TraceMemory.WriteTrace(LMemory, AArgs[1], AWorld.Trace(LMemory, TQ3TraceMemory.ReadVec3(LMemory, AArgs[2]),
          TQ3TraceMemory.ReadVec3(LMemory, AArgs[3]), TQ3TraceMemory.ReadVec3(LMemory, AArgs[4]),
          TQ3TraceMemory.ReadVec3(LMemory, AArgs[5]), AArgs[6], AArgs[7], ACapsule));
        Result := 0;
      end);
  end;
  procedure ContactCall(ANumber: Integer; ACapsule: Boolean);
  begin
    ARegistry.Register(ANumber,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := Ord(AWorld.EntityContact(AMachine.Memory, TQ3TraceMemory.ReadVec3(AMachine.Memory, AArgs[1]),
          TQ3TraceMemory.ReadVec3(AMachine.Memory, AArgs[2]), AArgs[3], ACapsule));
      end);
  end;
  procedure PvsCall(ANumber: Integer; AIgnorePortals: Boolean);
  begin
    ARegistry.Register(ANumber,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := Ord(AWorld.InPvs(TQ3TraceMemory.ReadVec3(AMachine.Memory, AArgs[1]),
          TQ3TraceMemory.ReadVec3(AMachine.Memory, AArgs[2]), AIgnorePortals));
      end);
  end;

begin
  ARegistry.Register(G_LOCATE_GAME_DATA,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      AWorld.LocateGameData(AArgs[1], AArgs[2], AArgs[3], AArgs[4], AArgs[5]);
      Result := 0;
    end);

  ARegistry.Register(G_DROP_CLIENT,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      // a client that does not exist is ignored
      if (AArgs[1] >= 0) and (AArgs[1] < AState.MaxClients) then
        ACommands.Drop(AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2], 'G_DROP_CLIENT'));
      Result := 0;
    end);

  ARegistry.Register(G_SEND_SERVER_COMMAND,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      if (AArgs[1] = -1) or ((AArgs[1] >= 0) and (AArgs[1] < AState.MaxClients)) then
        ACommands.Send(AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2], 'G_SEND_SERVER_COMMAND'));
      Result := 0;
    end);

  ARegistry.Register(G_SET_CONFIGSTRING,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      AState.SetConfigstring(AArgs[1], OptionalText(AMachine, AArgs[2], 'G_SET_CONFIGSTRING'));
      Result := 0;
    end);

  ARegistry.Register(G_GET_CONFIGSTRING,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      RequireBuffer(AArgs[3], 'SV_GetConfigstring');
      AMachine.Memory.WriteString(AArgs[2], AState.GetConfigstring(AArgs[1]), AArgs[3]);
      Result := 0;
    end);

  ARegistry.Register(G_SET_USERINFO,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      AState.SetUserinfo(AArgs[1], OptionalText(AMachine, AArgs[2], 'G_SET_USERINFO'));
      Result := 0;
    end);

  ARegistry.Register(G_GET_USERINFO,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      RequireBuffer(AArgs[3], 'SV_GetUserinfo');
      AMachine.Memory.WriteString(AArgs[2], AState.GetUserinfo(AArgs[1]), AArgs[3]);
      Result := 0;
    end);

  ARegistry.Register(G_GET_SERVERINFO,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      RequireBuffer(AArgs[2], 'SV_GetServerinfo');
      AMachine.Memory.WriteString(AArgs[1], ACVars.InfoStringBuffer(Q3_CVAR_SERVERINFO, AArgs[2]), AArgs[2]);
      Result := 0;
    end);

  ARegistry.Register(G_SET_BRUSH_MODEL,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      if AArgs[2] = 0 then
        raise EQ3HostException.Create('SV_SetBrushModel: NULL');
      AWorld.SetBrushModel(AMachine.Memory, AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2], 'G_SET_BRUSH_MODEL'));
      Result := 0;
    end);

  TraceCall(G_TRACE, False);
  TraceCall(G_TRACECAPSULE, True);
  ContactCall(G_ENTITY_CONTACT, False);
  ContactCall(G_ENTITY_CONTACTCAPSULE, True);
  PvsCall(G_IN_PVS, False);
  PvsCall(G_IN_PVS_IGNORE_PORTALS, True);

  ARegistry.Register(G_POINT_CONTENTS,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := AWorld.PointContents(AMachine.Memory, TQ3TraceMemory.ReadVec3(AMachine.Memory, AArgs[1]), AArgs[2]);
    end);

  ARegistry.Register(G_ADJUST_AREA_PORTAL_STATE,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      AWorld.AdjustAreaPortalState(AMachine.Memory, AArgs[1], AArgs[2] <> 0);
      Result := 0;
    end);

  ARegistry.Register(G_AREAS_CONNECTED,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      if not Assigned(AClipMap.Model) then
        raise EQ3HostException.Create(SNoMap);
      Result := Ord(AClipMap.Model.AreasConnected(AArgs[1], AArgs[2]));
    end);

  ARegistry.Register(G_LINKENTITY,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      AWorld.LinkEntity(AMachine.Memory, AArgs[1]);
      Result := 0;
    end);

  ARegistry.Register(G_UNLINKENTITY,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      AWorld.UnlinkEntity(AMachine.Memory, AArgs[1]);
      Result := 0;
    end);

  ARegistry.Register(G_ENTITIES_IN_BOX,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    var
      LList: TArray<Integer>;
      LIndex: Integer;
    begin
      LList := AWorld.AreaEntities(AMachine.Memory, TQ3TraceMemory.ReadVec3(AMachine.Memory, AArgs[1]),
        TQ3TraceMemory.ReadVec3(AMachine.Memory, AArgs[2]), AArgs[4]);
      for LIndex := 0 to Length(LList) - 1 do
        AMachine.Memory.WriteInt32(AArgs[3] + 4 * LIndex, LList[LIndex]);
      Result := Length(LList);
    end);

  ARegistry.Register(G_BOT_ALLOCATE_CLIENT,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := AState.BotAllocateClient;
      if Result >= 0 then
        AWorld.SetEntityNumber(AMachine.Memory, Result);
    end);

  ARegistry.Register(G_BOT_FREE_CLIENT,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      if AState.BotFreeClient(AArgs[1]) then
        AWorld.ClearBotFlag(AMachine.Memory, AArgs[1]);
      Result := 0;
    end);

  ARegistry.Register(G_GET_USERCMD,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      AMachine.Memory.WriteBytes(AArgs[2], AState.GetUsercmd(AArgs[1]));
      Result := 0;
    end);

  ARegistry.Register(G_GET_ENTITY_TOKEN,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    var
      LToken: AnsiString;
    begin
      RequireBuffer(AArgs[2], 'Q_strncpyz');
      Result := Ord(ATokens.Next(LToken));
      AMachine.Memory.WriteString(AArgs[1], LToken, AArgs[2]);
    end);

  // a debug drawing: no handle, nothing to delete
  ARegistry.Register(G_DEBUG_POLYGON_CREATE,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := 0;
    end);
  ARegistry.Register(G_DEBUG_POLYGON_DELETE,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := 0;
    end);
end;

end.
