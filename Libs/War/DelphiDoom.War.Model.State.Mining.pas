{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the mining state                                  }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_mining.c, (c) 2019 Alejandro }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Mining;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   A worker inside a gold mine: not drawn, for two seconds; then it comes out on a free tile next to the mine carrying
  ///   what it took (up to 100 gold) and takes it to the closest town hall of its race. If the mine is gone or collapses
  ///   the worker comes out at once with nothing and goes idle
  /// </summary>
  TWarMiningState = class
  public
    /// <summary>wst_enterMiningState</summary>
    class procedure Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase); static;
    /// <summary>wst_exitMiningState: a worker that leaves because the mine is gone is drawn again</summary>
    class procedure Leave(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase; AReason: Integer); static;
    /// <summary>wst_updateMiningState</summary>
    class procedure UpdateState(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateMining); static;
    /// <summary>wst_updateMiningStates</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  System.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateStorage,
  DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.TargetGeometry, DelphiDoom.War.Model.UnitSprites,
  DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitSearch, DelphiDoom.War.Model.ActionRunner,
  DelphiDoom.War.Model.Mine, DelphiDoom.War.Model.State.GatherFactory;

const
  UNIT_MAX_CARRY_GOLD = WAR_MODEL_MAX_CARRY;

// the unit leaves the mine (or the place where the mine was) on the first free tile near the given center tile
procedure StepOut(AContext: TWarModelContext; AEntity: PWarEntity; const ATile: TWarVec2);
var
  LSpawn: TPoint;
begin
  LSpawn := AContext.RequireGather.Grid.FindEmptyTile(Trunc(ATile.X), Trunc(ATile.Y));
  TWarTargetGeometry.SetCenterTile(AEntity, LSpawn.X, LSpawn.Y);
end;

{ TWarMiningState }

class procedure TWarMiningState.Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase);
var
  LEntity: PWarEntity;
begin
  LEntity := AMachine.Context.Pool.Slots[ASlot];
  PWarStateMining(AState)^.MiningTime := 2.0;
  TWarUnitSprites.Remove(LEntity);
  TWarActionRunner.Reset(LEntity^.UnitData, LEntity^.UnitData.ActionType);
  AMachine.Context.Selection.Remove(LEntity^.Id);
  AMachine.Context.Events.EntityLeftSelection(LEntity^.Id);
end;

class procedure TWarMiningState.Leave(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase;
  AReason: Integer);
var
  LMine: Integer;
begin
  LMine := AMachine.Context.Pool.FindSlot(PWarStateMining(AState)^.GoldmineId);
  // restore back the sprite component to the worker, so it should be visible again
  if (LMine = 0) or AMachine.IsCollapsing(LMine) or AMachine.IsGoingToCollapse(LMine) then
    TWarUnitSprites.AddDefault(AMachine.Context.Pool.Slots[ASlot]);
end;

class procedure TWarMiningState.UpdateState(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateMining);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LMine: Integer;
  LMineEntity: PWarEntity;
  LTownHall: Integer;
  LDeliver: PWarStateDeliver;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LMine := LContext.Pool.FindSlot(AState^.GoldmineId);
  // the mine is gone (it ran out of gold, or others destroyed it): the worker gets nothing and goes idle
  if LMine = 0 then
  begin
    StepOut(LContext, LEntity, TWarUnitGeometry.CenterTile(LEntity));
    TWarGatherStateFactory.ReplaceWithIdle(AMachine, ASlot);
    Exit;
  end;
  LMineEntity := LContext.Pool.Slots[LMine];
  if AMachine.IsCollapsing(LMine) or AMachine.IsGoingToCollapse(LMine) then
  begin
    StepOut(LContext, LEntity, TWarUnitGeometry.CenterTile(LMineEntity));
    TWarGatherStateFactory.ReplaceWithIdle(AMachine, ASlot);
    Exit;
  end;
  AState^.MiningTime := AState^.MiningTime - LContext.Clock^.DeltaTime;
  if AState^.MiningTime < 0 then
  begin
    LEntity^.UnitData.Amount := LEntity^.UnitData.Amount + TWarMine.Take(AMachine, LMine, UNIT_MAX_CARRY_GOLD);
    if LEntity^.UnitData.Amount > 0 then
      LEntity^.UnitData.ResourceKind := wrkGold;
    StepOut(LContext, LEntity, TWarUnitGeometry.CenterTile(LMineEntity));
    // set the carrying gold sprites
    TWarUnitSprites.Add(LEntity, TWarUnitSprites.CarryingGold(LEntity^.UnitData.UnitType));
    // find the closest town hall to deliver the gold
    LTownHall := TWarUnitSearch.FindClosestOfType(LContext, ASlot,
      TWarUnitSearch.TownHallOfRace(TWarUnitClassifier.RaceOf(LEntity^.UnitData.UnitType)));
    // if the town hall doesn't exists (it could be under attack and get destroyed), go idle
    if LTownHall = 0 then
    begin
      TWarGatherStateFactory.ReplaceWithIdle(AMachine, ASlot);
      Exit;
    end;
    LDeliver := TWarGatherStateFactory.NewDeliver(AMachine, ASlot, LContext.Pool.Slots[LTownHall]^.Id);
    if Assigned(LDeliver) then
    begin
      LDeliver^.Cycle := True;
      LDeliver^.SourceKind := wrkGold;
      LDeliver^.SourceId := LMineEntity^.Id;
    end;
    AMachine.ReplaceState(ASlot, PWarStateBase(LDeliver), WAR_CAUSE_COMPLETION);
  end;
end;

class procedure TWarMiningState.UpdateAll(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateMining;
  LSlot: Integer;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_MINING, LIndex] then
      Continue;
    LState := PWarStateMining(LContext.Storage.StateAt(WAR_STATE_MINING, LIndex));
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
