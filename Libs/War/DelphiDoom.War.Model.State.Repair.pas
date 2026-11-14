{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the repair state                                   }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_repair.c, (c) 2019           }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Repair;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   A worker that has been told to repair (or to build) a building: if the building is gone or is collapsing the
  ///   worker goes idle; if it is not within reach (the range of the worker, in tiles, from the nearest tile of the
  ///   building) it follows it; when it is there it starts repairing. It is the state that a worker has when it is sent to
  ///   build a building too: the build state of the building waits for the worker. The follow state is not ported yet
  ///   in this model: until it is registered the worker that has to walk stays in this state
  /// </summary>
  TWarRepairState = class
  public
    /// <summary>wst_createRepairState</summary>
    class function CreateState(AMachine: TWarStateMachine; ASlot: Integer; ABuildingId: Word): PWarStateRepair; static;
    /// <summary>wst_updateRepairStates</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.UnitTargeting,
  DelphiDoom.War.Model.State.Repairing,
  DelphiDoom.War.Model.StateStorage;

{ TWarRepairState }

class function TWarRepairState.CreateState(AMachine: TWarStateMachine; ASlot: Integer;
  ABuildingId: Word): PWarStateRepair;
begin
  Result := PWarStateRepair(AMachine.AllocState(ASlot, WAR_STATE_REPAIR));
  if Assigned(Result) then
    Result^.BuildingId := ABuildingId;
end;

class procedure TWarRepairState.UpdateAll(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateBase;
  LSlot: Integer;
  LEntity: PWarEntity;
  LBuilding: Integer;
  LRange: Integer;
  LIdle: PWarStateIdle;
  LFollow: PWarStateFollow;
  LRepairing: PWarStateRepairing;
  LPoint: TWarVec2;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_REPAIR, LIndex] then
      Continue;
    LState := LContext.Storage.StateAt(WAR_STATE_REPAIR, LIndex);
    LSlot := LContext.Pool.FindSlot(LState^.EntityId);
    if LSlot = 0 then
      Continue;
    if AMachine.ActiveState(LSlot) <> LState then
      Continue;
    if not AMachine.IsNextUpdateTime(LState) then
      Continue;
    LEntity := LContext.Pool.Slots[LSlot];
    LBuilding := LContext.Pool.FindSlot(PWarStateRepair(LState)^.BuildingId);
    // the building is not there or it is collapsing (it can be attacked by other units): go idle
    if (LBuilding = 0) or AMachine.IsCollapsing(LBuilding) or AMachine.IsGoingToCollapse(LBuilding) then
    begin
      LIdle := AMachine.CreateIdle(LSlot, True);
      AMachine.ReplaceState(LSlot, PWarStateBase(LIdle), WAR_CAUSE_COMPLETION);
      Continue;
    end;
    LRange := LContext.Database.GetUnitStats(LEntity^.UnitData.UnitType).Range;
    // the building is not within reach: walk to it
    if not TWarUnitTargeting.InRange(LEntity, LContext.Pool.Slots[LBuilding], LRange) then
    begin
      LPoint := TWarUnitTargeting.PointOnTarget(LEntity, LContext.Pool.Slots[LBuilding]);
      LFollow := PWarStateFollow(AMachine.AllocState(LSlot, WAR_STATE_FOLLOW));
      if Assigned(LFollow) then
      begin
        LFollow^.TargetEntityId := LContext.Pool.Slots[LBuilding]^.Id;
        LFollow^.TargetPosition := LPoint;
        LFollow^.TargetDistance := LRange * WAR_MEGA_TILE_SIZE;
        AMachine.PushState(LSlot, PWarStateBase(LFollow), WAR_CAUSE_COMPLETION);
      end;
      Continue;
    end;
    // the worker is at the building: start to repair
    LRepairing := TWarRepairingState.CreateState(AMachine, LSlot, LContext.Pool.Slots[LBuilding]^.Id);
    AMachine.ReplaceState(LSlot, PWarStateBase(LRepairing), WAR_CAUSE_COMPLETION);
  end;
end;

end.
