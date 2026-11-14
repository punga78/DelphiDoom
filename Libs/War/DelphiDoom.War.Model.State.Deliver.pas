{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the deliver state                                 }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_deliver.c, (c) 2019          }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Deliver;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   A worker that takes what it carries to a town hall: it follows the building until it is within range, gives
  ///   the gold or wood to its player and goes inside (not drawn) for a second; then it comes out on a free tile near the
  ///   building and, if the delivery is part of a cycle, goes back to the mine or to the tree, else it resumes what it was
  ///   doing (a state under this one) or goes idle
  /// </summary>
  TWarDeliverState = class
  public
    /// <summary>wst_updateDeliverState</summary>
    class procedure UpdateState(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateDeliver); static;
    /// <summary>wst_updateDeliverStates</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  System.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.StateStorage, DelphiDoom.War.Model.UnitRange,
  DelphiDoom.War.Model.UnitSprites, DelphiDoom.War.Model.Economy, DelphiDoom.War.Model.State.FollowRequest,
  DelphiDoom.War.Model.State.GatherFactory, DelphiDoom.War.Model.UnitGeometry;

{ TWarDeliverState }

class procedure TWarDeliverState.UpdateState(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateDeliver);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LUnit: PWarUnitComponent;
  LTownHall: Integer;
  LTownHallEntity: PWarEntity;
  LRange: Integer;
  LTarget: TWarVec2;
  LTile: TWarVec2;
  LSpawn: TPoint;
  LPlayer: PWarPlayerInfo;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LUnit := @LEntity^.UnitData;
  LRange := LContext.Database.GetUnitStats(LUnit^.UnitType).Range;
  LTownHall := LContext.Pool.FindSlot(AState^.TownHallId);
  // if the town hall doesn't exists (or other units attacking it), go idle
  if LTownHall = 0 then
  begin
    TWarGatherStateFactory.ReplaceWithIdle(AMachine, ASlot);
    Exit;
  end;
  LTownHallEntity := LContext.Pool.Slots[LTownHall];
  if not TWarUnitRange.InRange(LEntity, LTownHallEntity, LRange) then
  begin
    LTarget := TWarUnitRange.PointOnTarget(LEntity, LTownHallEntity);
    AMachine.PushState(ASlot, PWarStateBase(TWarFollowRequest.New(AMachine, ASlot, LTownHallEntity^.Id, LTarget,
      LRange * WAR_MEGA_TILE_SIZE)), WAR_CAUSE_COMPLETION);
    Exit;
  end;
  if AState^.InsideBuilding then
  begin
    // find a valid spawn position for the unit
    LTile := TWarUnitGeometry.CenterTile(LTownHallEntity);
    LSpawn := LContext.RequireGather.Grid.FindEmptyTile(Trunc(LTile.X), Trunc(LTile.Y));
    TWarUnitRange.SetCenterTile(LEntity, LSpawn.X, LSpawn.Y);
    TWarUnitSprites.Remove(LUnit^);
    TWarUnitSprites.AddDefault(LUnit^);
    if AState^.Cycle then
    begin
      if AState^.SourceKind = wrkGold then
        AMachine.ReplaceState(ASlot, PWarStateBase(TWarGatherStateFactory.NewGold(AMachine, ASlot, AState^.SourceId)),
          WAR_CAUSE_COMPLETION)
      else
        AMachine.ReplaceState(ASlot, PWarStateBase(TWarGatherStateFactory.NewWood(AMachine, ASlot, AState^.SourceId,
          AState^.SourcePosition)), WAR_CAUSE_COMPLETION);
    end
    else if LEntity^.StateMachine.Depth > 1 then
      AMachine.PopState(ASlot, WAR_CAUSE_COMPLETION, WAR_RESULT_SUCCESS)
    else
      TWarGatherStateFactory.ReplaceWithIdle(AMachine, ASlot);
    Exit;
  end;
  LPlayer := LContext.Players[LUnit^.Player];
  if LUnit^.ResourceKind = wrkGold then
    TWarEconomy.Increase(LPlayer, LUnit^.Amount, 0)
  else if LUnit^.ResourceKind = wrkWood then
    TWarEconomy.Increase(LPlayer, 0, LUnit^.Amount);
  LUnit^.ResourceKind := wrkNone;
  LUnit^.Amount := 0;
  // the unit goes inside the building for some time to simulate the depositing, then goes back to the mine or the trees
  AState^.InsideBuilding := True;
  TWarUnitSprites.Disable(LUnit^);
  // out of the selection, so that the player does not give it orders while it is inside
  LContext.Events.EntityLeftSelection(LEntity^.Id);
  AState^.Base.Delay := TWarModelMath.ScaledTime(LContext.Clock^, 1.0);
end;

class procedure TWarDeliverState.UpdateAll(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateDeliver;
  LSlot: Integer;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_DELIVER, LIndex] then
      Continue;
    LState := PWarStateDeliver(LContext.Storage.StateAt(WAR_STATE_DELIVER, LIndex));
    LSlot := LContext.Pool.FindSlot(LState^.Base.EntityId);
    if LSlot = 0 then
      Continue;
    if AMachine.ActiveState(LSlot) <> PWarStateBase(LState) then
      Continue;
    if not AMachine.IsNextUpdateTime(PWarStateBase(LState)) then
      Continue;
    UpdateState(AMachine, LSlot, LState);
  end;
end;

end.
