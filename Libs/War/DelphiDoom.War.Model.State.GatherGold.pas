{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the gather gold state                             }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_gather_gold.c, (c) 2019      }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.GatherGold;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   A worker that goes to a gold mine: if the mine is gone or collapsing it goes idle, if it is not within range
  ///   it follows the mine (pushed on top of this state), if it is there it goes in to mine
  /// </summary>
  TWarGatherGoldState = class
  public
    /// <summary>wst_updateGatherGoldState</summary>
    class procedure UpdateState(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateGold); static;
    /// <summary>wst_updateGoldStates</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateStorage, DelphiDoom.War.Model.UnitRange,
  DelphiDoom.War.Model.State.FollowRequest, DelphiDoom.War.Model.State.GatherFactory;

{ TWarGatherGoldState }

class procedure TWarGatherGoldState.UpdateState(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateGold);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LMine: Integer;
  LRange: Integer;
  LZero: TWarVec2;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LRange := LContext.Database.GetUnitStats(LEntity^.UnitData.UnitType).Range;
  LMine := LContext.Pool.FindSlot(AState^.GoldmineId);
  // if the goldmine doesn't exists (it could ran out of gold, or other units attacking it), go idle
  if (LMine = 0) or AMachine.IsCollapsing(LMine) or AMachine.IsGoingToCollapse(LMine) then
  begin
    TWarGatherStateFactory.ReplaceWithIdle(AMachine, ASlot);
    Exit;
  end;
  // if the goldmine is not in range, go to it
  if not TWarUnitRange.InRange(LEntity, LContext.Pool.Slots[LMine], LRange) then
  begin
    LZero.X := 0;
    LZero.Y := 0;
    AMachine.PushState(ASlot, PWarStateBase(TWarFollowRequest.New(AMachine, ASlot, LContext.Pool.Slots[LMine]^.Id, LZero,
      LRange * WAR_MEGA_TILE_SIZE)), WAR_CAUSE_COMPLETION);
    Exit;
  end;
  // the unit arrive to the goldmine, go mining
  AMachine.ReplaceState(ASlot, PWarStateBase(TWarGatherStateFactory.NewMining(AMachine, ASlot,
    LContext.Pool.Slots[LMine]^.Id)), WAR_CAUSE_COMPLETION);
end;

class procedure TWarGatherGoldState.UpdateAll(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateGold;
  LSlot: Integer;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_GOLD, LIndex] then
      Continue;
    LState := PWarStateGold(LContext.Storage.StateAt(WAR_STATE_GOLD, LIndex));
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
