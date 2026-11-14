{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the repairing state                                }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_repairing.c, (c) 2019        }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Repairing;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   A worker that is at a building. If the building is still to be built the worker goes inside (its sprite is
  ///   hidden) and is the one who builds it: the build state of the building runs while the worker is there, and when
  ///   the building is done the worker comes out on a free tile. If the building is built, the worker looks at it and
  ///   at each blow of the hammer (the step ATTACK of its repair action) pays 1 gold and 1 lumber and gives the
  ///   building 9 hit points, until the building is whole or the money is over. If the building is gone or collapses,
  ///   the worker goes idle
  /// </summary>
  TWarRepairingState = class
  strict private
    class procedure GoIdle(AMachine: TWarStateMachine; ASlot: Integer); static;
  public
    /// <summary>wst_createRepairingState</summary>
    class function CreateState(AMachine: TWarStateMachine; ASlot: Integer; ABuildingId: Word): PWarStateRepairing; static;
    /// <summary>wst_enterRepairingState</summary>
    class procedure Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase); static;
    /// <summary>wst_exitRepairingState</summary>
    class procedure Leave(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase; AReason: Integer); static;
    /// <summary>wst_updateRepairingStates</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.Math,
  DelphiDoom.War.Model.ActionTable, DelphiDoom.War.Model.ActionStepper, DelphiDoom.War.Model.UnitGeometry,
  DelphiDoom.War.Model.UnitPlacement, DelphiDoom.War.Model.Purse, DelphiDoom.War.Model.Construction.Types,
  DelphiDoom.War.Model.StateStorage;

{ TWarRepairingState }

class function TWarRepairingState.CreateState(AMachine: TWarStateMachine; ASlot: Integer;
  ABuildingId: Word): PWarStateRepairing;
begin
  Result := PWarStateRepairing(AMachine.AllocState(ASlot, WAR_STATE_REPAIRING));
  if not Assigned(Result) then
    Exit;
  Result^.BuildingId := ABuildingId;
  Result^.InsideBuilding := False;
end;

class procedure TWarRepairingState.GoIdle(AMachine: TWarStateMachine; ASlot: Integer);
var
  LIdle: PWarStateIdle;
begin
  LIdle := AMachine.CreateIdle(ASlot, True);
  AMachine.ReplaceState(ASlot, PWarStateBase(LIdle), WAR_CAUSE_COMPLETION);
end;

class procedure TWarRepairingState.Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LRepairing: PWarStateRepairing;
  LBuilding: Integer;
  LBuild: PWarStateBuild;
  LTile: TWarVec2;
  LTargetTile: TWarVec2;
  LDeltaX: Single;
  LDeltaY: Single;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LRepairing := PWarStateRepairing(AState);
  LBuilding := LContext.Pool.FindSlot(LRepairing^.BuildingId);
  // the building is not there or it is collapsing: go idle
  if (LBuilding = 0) or AMachine.IsCollapsing(LBuilding) or AMachine.IsGoingToCollapse(LBuilding) then
  begin
    GoIdle(AMachine, ASlot);
    Exit;
  end;
  if AMachine.IsBuilding(LBuilding) or AMachine.IsGoingToBuild(LBuilding) then
  begin
    LBuild := PWarStateBuild(AMachine.FindState(LBuilding, WAR_STATE_BUILD));
    // the building is waiting to be built but its build state is not on the stack yet (the original asserts)
    if not Assigned(LBuild) then
      raise EWarException.CreateFmt(SWarModelNoBuildState, [LContext.Pool.Slots[LBuilding]^.Id]);
    // someone is building it already
    if LBuild^.WorkerId <> 0 then
    begin
      GoIdle(AMachine, ASlot);
      Exit;
    end;
    LEntity^.SpriteEnabled := False;
    LRepairing^.InsideBuilding := True;
    LBuild^.WorkerId := LEntity^.Id;
  end
  else
  begin
    LTile := TWarUnitGeometry.CenterTile(LEntity);
    LTargetTile := TWarUnitGeometry.CenterTile(LContext.Pool.Slots[LBuilding]);
    LContext.Occupancy.SetStaticEntity(Trunc(LTile.X), Trunc(LTile.Y), LEntity^.UnitData.SizeX,
      LEntity^.UnitData.SizeY, LEntity^.Id);
    LDeltaX := LTargetTile.X - LTile.X;
    LDeltaY := LTargetTile.Y - LTile.Y;
    LEntity^.UnitData.Direction := TWarModelMath.DirectionFromDiff(LDeltaX, LDeltaY);
    TWarActionTable.SetAction(LEntity^.UnitData, WAR_ACTION_REPAIR, True, 1.0);
  end;
end;

class procedure TWarRepairingState.Leave(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase;
  AReason: Integer);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LBuilding: Integer;
  LBuild: PWarStateBuild;
  LTile: TWarVec2;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LBuilding := LContext.Pool.FindSlot(PWarStateRepairing(AState)^.BuildingId);
  if LBuilding <> 0 then
  begin
    LBuild := PWarStateBuild(AMachine.FindState(LBuilding, WAR_STATE_BUILD));
    if Assigned(LBuild) and (LBuild^.WorkerId = LEntity^.Id) then
      LBuild^.WorkerId := 0;
  end;
  LTile := TWarUnitGeometry.CenterTile(LEntity);
  LContext.Occupancy.SetFreeTiles(Trunc(LTile.X), Trunc(LTile.Y), LEntity^.UnitData.SizeX, LEntity^.UnitData.SizeY);
end;

class procedure TWarRepairingState.UpdateAll(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateBase;
  LRepairing: PWarStateRepairing;
  LSlot: Integer;
  LEntity: PWarEntity;
  LBuilding: Integer;
  LBuildingUnit: PWarUnitComponent;
  LAction: ^TWarUnitAction;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_REPAIRING, LIndex] then
      Continue;
    LState := LContext.Storage.StateAt(WAR_STATE_REPAIRING, LIndex);
    LSlot := LContext.Pool.FindSlot(LState^.EntityId);
    if LSlot = 0 then
      Continue;
    if AMachine.ActiveState(LSlot) <> LState then
      Continue;
    if not AMachine.IsNextUpdateTime(LState) then
      Continue;
    LRepairing := PWarStateRepairing(LState);
    LEntity := LContext.Pool.Slots[LSlot];
    LBuilding := LContext.Pool.FindSlot(LRepairing^.BuildingId);
    // the building is not there or it is collapsing: the worker comes out (if it was inside) and goes idle
    if (LBuilding = 0) or AMachine.IsCollapsing(LBuilding) or AMachine.IsGoingToCollapse(LBuilding) then
    begin
      if LRepairing^.InsideBuilding then
      begin
        LEntity^.SpriteEnabled := True;
        TWarUnitPlacement.PlaceNear(LContext, LEntity, LEntity);
      end;
      GoIdle(AMachine, LSlot);
      Continue;
    end;
    // a worker that is inside is building it: a new building has all its hit points, so no repair
    if not LRepairing^.InsideBuilding then
    begin
      if LEntity^.UnitData.ActionType < 0 then
        Continue;
      LAction := @LEntity^.UnitData.Actions[LEntity^.UnitData.ActionType];
      if LAction^.LastActionStep = WAR_ACTION_STEP_ATTACK then
      begin
        if not TWarPurse.Decrease(LContext, LContext.Players[LEntity^.UnitData.Player], 1, 1) then
        begin
          GoIdle(AMachine, LSlot);
          Continue;
        end;
        // 12 percent of the damage is what the repair costs: 1 gold and 1 lumber each second, 100 / 12 = 8.33 hit
        // points that the original rounds to 9
        LBuildingUnit := @LContext.Pool.Slots[LBuilding]^.UnitData;
        LBuildingUnit^.Hp := LBuildingUnit^.Hp + WAR_REPAIR_HP_PER_STEP;
        if LBuildingUnit^.Hp >= LBuildingUnit^.MaxHp then
        begin
          LBuildingUnit^.Hp := LBuildingUnit^.MaxHp;
          GoIdle(AMachine, LSlot);
        end;
        LAction^.LastActionStep := WAR_ACTION_STEP_NONE;
      end;
    end
    else if not AMachine.IsBuilding(LBuilding) and not AMachine.IsGoingToBuild(LBuilding) then
    begin
      // the building is done: the worker comes out
      LEntity^.SpriteEnabled := True;
      TWarUnitPlacement.PlaceNear(LContext, LEntity, LEntity);
      GoIdle(AMachine, LSlot);
    end;
  end;
end;

end.
