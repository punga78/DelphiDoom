{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the BOTLIB_AAS_* system calls          }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_game.c.      }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.Bot.AasSyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Q3Host.Bot.Registrar;

type
  /// <summary>
  ///   The 30 calls of the AAS (aas_export_t): the arguments are read and the answers written where the module keeps
  ///   them (bot_entitystate_t is not here: BOTLIB_UPDATENTITY). The work is IQ3BotAas
  /// </summary>
  TQ3BotAasSyscalls = class
  public
    class procedure Register(const ARegistrar: TQ3BotRegistrar); static;
  end;

implementation

uses
  System.SysUtils, System.Math, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types,
  DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Move.Types, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Arguments,
  DelphiDoom.Q3Host.Bot.Intf, DelphiDoom.Q3Host.Bot.Memory;

const
  // a limit for the arrays the library answers with (the C writes into the memory of the module as far as it is told)
  MAX_ANSWER = 1 shl 16;

class procedure TQ3BotAasSyscalls.Register(const ARegistrar: TQ3BotRegistrar);
  // a pointer that may be NULL, as the pointer to a vector the routing functions accept
  procedure RegisterRoute;
  begin
    ARegistrar.Add(BOTLIB_AAS_AREA_TRAVEL_TIME_TO_GOAL_AREA,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LOrigin: TVec3;
      begin
        if AArgs[2] = 0 then
          Exit(ARegistrar.Lib.Aas.AreaTravelTimeToGoalArea(AArgs[1], nil, AArgs[3], AArgs[4]));
        LOrigin := TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[2]);
        Result := ARegistrar.Lib.Aas.AreaTravelTimeToGoalArea(AArgs[1], @LOrigin, AArgs[3], AArgs[4]);
      end);

    ARegistrar.Add(BOTLIB_AAS_ENABLE_ROUTING_AREA,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Aas.EnableRoutingArea(AArgs[1], AArgs[2]);
      end);

    ARegistrar.Add(BOTLIB_AAS_PREDICT_ROUTE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LRoute: TAasPredictRoute;
      begin
        LRoute := Default(TAasPredictRoute);
        Result := Ord(ARegistrar.Lib.Aas.PredictRoute(LRoute, AArgs[2], TQ3BotMemory.ReadVec3(AMachine.Memory,
          AArgs[3]), AArgs[4], AArgs[5], AArgs[6], AArgs[7], AArgs[8], AArgs[9], AArgs[10], AArgs[11]));
        TQ3BotMemory.WritePredictRoute(AMachine.Memory, AArgs[1], LRoute);
      end);

    ARegistrar.Add(BOTLIB_AAS_ALTERNATIVE_ROUTE_GOAL,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LGoals: TArray<TAasAltRouteGoal>;
        LIndex: Integer;
      begin
        if (AArgs[7] > 0) then
          SetLength(LGoals, Integer(Min(AArgs[7], MAX_ANSWER)))
        else
          LGoals := nil;
        Result := ARegistrar.Lib.Aas.AlternativeRouteGoals(TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[1]), AArgs[2],
          TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[3]), AArgs[4], AArgs[5], LGoals, AArgs[7], AArgs[8]);
        for LIndex := 0 to Result - 1 do
          TQ3BotMemory.WriteAltRouteGoal(AMachine.Memory, AArgs[6] + LIndex * TQ3BotMemory.SIZE_ALTROUTEGOAL,
            LGoals[LIndex]);
      end);

    ARegistrar.Add(BOTLIB_AAS_AREA_REACHABILITY,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Aas.AreaReachability(AArgs[1]);
      end);
  end;

  procedure RegisterBsp;
  begin
    ARegistrar.Add(BOTLIB_AAS_POINT_CONTENTS,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Aas.PointContents(TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[1]));
      end);

    ARegistrar.Add(BOTLIB_AAS_NEXT_BSP_ENTITY,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Aas.NextBspEntity(AArgs[1]);
      end);

    ARegistrar.Add(BOTLIB_AAS_VALUE_FOR_BSP_EPAIR_KEY,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LValue: AnsiString;
      begin
        Result := Ord(ARegistrar.Lib.Aas.ValueForBspEpairKey(AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2],
          'BOTLIB_AAS_VALUE_FOR_BSP_EPAIR_KEY'), LValue, AArgs[4]));
        // value[0] = 0 first, then strncpy( value, epair->value, size - 1 ); value[size - 1] = 0
        if AArgs[4] > 0 then
          AMachine.Memory.WriteString(AArgs[3], LValue, AArgs[4])
        else
          AMachine.Memory.WriteByte(AArgs[3], 0);
      end);

    ARegistrar.Add(BOTLIB_AAS_VECTOR_FOR_BSP_EPAIR_KEY,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LValue: TVec3;
      begin
        Result := Ord(ARegistrar.Lib.Aas.VectorForBspEpairKey(AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2],
          'BOTLIB_AAS_VECTOR_FOR_BSP_EPAIR_KEY'), LValue));
        TQ3BotMemory.WriteVec3(AMachine.Memory, AArgs[3], LValue);
      end);

    ARegistrar.Add(BOTLIB_AAS_FLOAT_FOR_BSP_EPAIR_KEY,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LValue: Single;
      begin
        Result := Ord(ARegistrar.Lib.Aas.FloatForBspEpairKey(AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2],
          'BOTLIB_AAS_FLOAT_FOR_BSP_EPAIR_KEY'), LValue));
        AMachine.Memory.WriteInt32(AArgs[3], TQ3BotMemory.Bits(LValue));
      end);

    ARegistrar.Add(BOTLIB_AAS_INT_FOR_BSP_EPAIR_KEY,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LValue: Integer;
      begin
        Result := Ord(ARegistrar.Lib.Aas.IntForBspEpairKey(AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2],
          'BOTLIB_AAS_INT_FOR_BSP_EPAIR_KEY'), LValue));
        AMachine.Memory.WriteInt32(AArgs[3], LValue);
      end);
  end;

  procedure RegisterAreas;
  begin
    ARegistrar.Add(BOTLIB_AAS_BBOX_AREAS,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LAreas: TArray<Integer>;
        LIndex: Integer;
      begin
        LAreas := ARegistrar.Lib.Aas.BBoxAreas(TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[1]),
          TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[2]), AArgs[4]);
        for LIndex := 0 to Length(LAreas) - 1 do
          AMachine.Memory.WriteInt32(AArgs[3] + 4 * LIndex, LAreas[LIndex]);
        Result := Length(LAreas);
      end);

    ARegistrar.Add(BOTLIB_AAS_AREA_INFO,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LInfo: TAasAreaInfo;
      begin
        // if ( !info ) return 0
        if AArgs[2] = 0 then
          Exit(0);
        Result := ARegistrar.Lib.Aas.AreaInfo(AArgs[1], LInfo);
        if Result <> 0 then
          TQ3BotMemory.WriteAreaInfo(AMachine.Memory, AArgs[2], LInfo);
      end);

    ARegistrar.Add(BOTLIB_AAS_ENTITY_INFO,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        TQ3BotMemory.WriteEntityInfo(AMachine.Memory, AArgs[2], ARegistrar.Lib.Aas.EntityInfo(AArgs[1]));
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AAS_INITIALIZED,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := Ord(ARegistrar.Lib.Aas.Initialized);
      end);

    ARegistrar.Add(BOTLIB_AAS_PRESENCE_TYPE_BOUNDING_BOX,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LMins, LMaxs: TVec3;
      begin
        ARegistrar.Lib.Aas.PresenceTypeBoundingBox(AArgs[1], LMins, LMaxs);
        TQ3BotMemory.WriteVec3(AMachine.Memory, AArgs[2], LMins);
        TQ3BotMemory.WriteVec3(AMachine.Memory, AArgs[3], LMaxs);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AAS_TIME,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := TQ3SyscallArguments.FromSingle(ARegistrar.Lib.Aas.Time);
      end);

    ARegistrar.Add(BOTLIB_AAS_POINT_AREA_NUM,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Aas.PointAreaNum(TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[1]));
      end);

    ARegistrar.Add(BOTLIB_AAS_POINT_REACHABILITY_AREA_INDEX,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LPoint: TVec3;
      begin
        // NULL is the total of the reachability areas of the map
        if AArgs[1] = 0 then
          Exit(ARegistrar.Lib.Aas.PointReachabilityAreaIndex(nil));
        LPoint := TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[1]);
        Result := ARegistrar.Lib.Aas.PointReachabilityAreaIndex(@LPoint);
      end);

    ARegistrar.Add(BOTLIB_AAS_TRACE_AREAS,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LAreas: TArray<Integer>;
        LPoints: TArray<TVec3>;
        LIndex: Integer;
      begin
        // areas[0] = 0 before anything else
        if AArgs[3] <> 0 then
          AMachine.Memory.WriteInt32(AArgs[3], 0);
        Result := ARegistrar.Lib.Aas.TraceAreas(TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[1]),
          TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[2]), AArgs[5], LAreas, LPoints);
        for LIndex := 0 to Result - 1 do
        begin
          if (AArgs[3] <> 0) and (LIndex < Length(LAreas)) then
            AMachine.Memory.WriteInt32(AArgs[3] + 4 * LIndex, LAreas[LIndex]);
          if (AArgs[4] <> 0) and (LIndex < Length(LPoints)) then
            TQ3BotMemory.WriteVec3(AMachine.Memory, AArgs[4] + 12 * LIndex, LPoints[LIndex]);
        end;
      end);
  end;

  procedure RegisterMovement;
  begin
    ARegistrar.Add(BOTLIB_AAS_SWIMMING,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := Ord(ARegistrar.Lib.Aas.Swimming(TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[1])));
      end);

    ARegistrar.Add(BOTLIB_AAS_PREDICT_CLIENT_MOVEMENT,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LMove: TAasClientMove;
      begin
        Result := Ord(ARegistrar.Lib.Aas.PredictClientMovement(LMove, AArgs[2],
          TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[3]), AArgs[4], AArgs[5] <> 0,
          TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[6]), TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[7]),
          AArgs[8], AArgs[9], TQ3SyscallArguments.ToSingle(AArgs[10]), AArgs[11], AArgs[12], AArgs[13] <> 0));
        // the move may be NULL
        if AArgs[1] <> 0 then
          TQ3BotMemory.WriteClientMove(AMachine.Memory, AArgs[1], LMove);
      end);
  end;

begin
  RegisterRoute;
  RegisterBsp;
  RegisterAreas;
  RegisterMovement;
end;

end.
