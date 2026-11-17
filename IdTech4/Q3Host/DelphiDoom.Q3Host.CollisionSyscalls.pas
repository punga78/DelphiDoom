{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the collision system calls of cgame    }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_cgame.c.     }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.CollisionSyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Services.Intf, DelphiDoom.Q3Host.EntityTokens;

type
  /// <summary>
  ///   CG_CM_LOADMAP, NUMINLINEMODELS, INLINEMODEL, TEMPBOXMODEL, TEMPCAPSULEMODEL, POINTCONTENTS,
  ///   TRANSFORMEDPOINTCONTENTS, BOXTRACE, CAPSULETRACE, TRANSFORMEDBOXTRACE, TRANSFORMEDCAPSULETRACE and
  ///   CG_GET_ENTITY_TOKEN: the client game asks the same clipmap the server has. The answers are the ones of the
  ///   collision model of IdTech4\Collision (equal to cm_*.c on the maps of OpenArena); here only the vectors
  ///   and trace_t are moved in and out of the data of the program (a NULL mins or maxs is the zero vector as in
  ///   CM_BoxTrace). A call when no map is loaded raises EQ3HostException
  /// </summary>
  TQ3CollisionSyscalls = class
  public
    /// <param name="ATokens">The entity tokens of the cgame (the renderer's entity string); may be nil</param>
    class procedure RegisterCGame(const ARegistry: IQ3SyscallRegistry; const AClipMap: IQ3HostClipMap;
      const ATokens: TQ3EntityTokens); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Collision.Q3.Intf,
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Arguments, DelphiDoom.Q3Host.TraceMemory;

resourcestring
  SNoMap = 'The collision model was used before a map was loaded';

function RequireModel(const AClipMap: IQ3HostClipMap): IQ3CollisionModel;
begin
  Result := AClipMap.Model;
  if not Assigned(Result) then
    raise EQ3HostException.Create(SNoMap);
end;

class procedure TQ3CollisionSyscalls.RegisterCGame(const ARegistry: IQ3SyscallRegistry;
  const AClipMap: IQ3HostClipMap; const ATokens: TQ3EntityTokens);
  procedure Trace(ANumber: Integer; ACapsule, ATransformed: Boolean);
  begin
    ARegistry.Register(ANumber,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LMemory: IQvmMemory;
        LTrace: TQ3Trace;
      begin
        LMemory := AMachine.Memory;
        if ATransformed then
          LTrace := RequireModel(AClipMap).TransformedBoxTrace(TQ3TraceMemory.ReadVec3(LMemory, AArgs[2]),
            TQ3TraceMemory.ReadVec3(LMemory, AArgs[3]), TQ3TraceMemory.ReadVec3(LMemory, AArgs[4]),
            TQ3TraceMemory.ReadVec3(LMemory, AArgs[5]), AArgs[6], AArgs[7],
            TQ3TraceMemory.ReadVec3(LMemory, AArgs[8]), TQ3TraceMemory.ReadVec3(LMemory, AArgs[9]), ACapsule)
        else
          LTrace := RequireModel(AClipMap).BoxTrace(TQ3TraceMemory.ReadVec3(LMemory, AArgs[2]),
            TQ3TraceMemory.ReadVec3(LMemory, AArgs[3]), TQ3TraceMemory.ReadVec3(LMemory, AArgs[4]),
            TQ3TraceMemory.ReadVec3(LMemory, AArgs[5]), AArgs[6], AArgs[7], ACapsule);
        TQ3TraceMemory.WriteTrace(LMemory, AArgs[1], LTrace);
        Result := 0;
      end);
  end;

begin
  ARegistry.Register(CG_CM_LOADMAP,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      AClipMap.Load(TQ3SyscallArguments.Text(AMachine, AArgs[1], 'CG_CM_LOADMAP'));
      Result := 0;
    end);

  ARegistry.Register(CG_CM_NUMINLINEMODELS,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := RequireModel(AClipMap).NumInlineModels;
    end);

  ARegistry.Register(CG_CM_INLINEMODEL,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := RequireModel(AClipMap).InlineModel(AArgs[1]);
    end);

  ARegistry.Register(CG_CM_TEMPBOXMODEL,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := RequireModel(AClipMap).TempBoxModel(TQ3TraceMemory.ReadVec3(AMachine.Memory, AArgs[1]),
        TQ3TraceMemory.ReadVec3(AMachine.Memory, AArgs[2]), False);
    end);

  ARegistry.Register(CG_CM_TEMPCAPSULEMODEL,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := RequireModel(AClipMap).TempBoxModel(TQ3TraceMemory.ReadVec3(AMachine.Memory, AArgs[1]),
        TQ3TraceMemory.ReadVec3(AMachine.Memory, AArgs[2]), True);
    end);

  ARegistry.Register(CG_CM_POINTCONTENTS,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := RequireModel(AClipMap).PointContents(TQ3TraceMemory.ReadVec3(AMachine.Memory, AArgs[1]), AArgs[2]);
    end);

  ARegistry.Register(CG_CM_TRANSFORMEDPOINTCONTENTS,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := RequireModel(AClipMap).TransformedPointContents(TQ3TraceMemory.ReadVec3(AMachine.Memory, AArgs[1]),
        AArgs[2], TQ3TraceMemory.ReadVec3(AMachine.Memory, AArgs[3]),
        TQ3TraceMemory.ReadVec3(AMachine.Memory, AArgs[4]));
    end);

  Trace(CG_CM_BOXTRACE, False, False);
  Trace(CG_CM_CAPSULETRACE, True, False);
  Trace(CG_CM_TRANSFORMEDBOXTRACE, False, True);
  Trace(CG_CM_TRANSFORMEDCAPSULETRACE, True, True);

  if Assigned(ATokens) then
    ARegistry.Register(CG_GET_ENTITY_TOKEN,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LToken: AnsiString;
      begin
        // re.GetEntityToken: Q_strncpyz( buffer, token, size ); True while there is text
        Result := Ord(ATokens.Next(LToken));
        AMachine.Memory.WriteString(AArgs[1], LToken, AArgs[2]);
      end);
end;

end.
