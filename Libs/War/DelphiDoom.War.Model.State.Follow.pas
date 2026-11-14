{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the follow state                                  }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_follow.c, (c) 2019 Alejandro }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Follow;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   A unit that goes after a unit (or a point, with no target id) until it is within a distance in pixels. Each update
  ///   it pushes a move to where the target is now (a point of the target that is closest, for a unit); within the
  ///   distance, or with the target gone, it ends (the target gone is TARGET_INVALID)
  /// </summary>
  TWarFollowState = class
  public
    /// <summary>wst_updateFollowStates</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.Math, DelphiDoom.War.Model.UnitGeometry,
  DelphiDoom.War.Model.TargetGeometry, DelphiDoom.War.Model.StateStorage;

procedure UpdateOne(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateFollow);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LTarget: PWarEntity;
  LStart: TWarVec2;
  LEnd: TWarVec2;
  LDistanceSqr: Single;
  LLimit: Single;
  LMove: PWarStateMove;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LStart := TWarUnitGeometry.CenterPosition(LEntity);
  LEnd := AState^.TargetPosition;
  if AState^.TargetEntityId <> 0 then
  begin
    LTarget := LContext.Pool.Slots[LContext.Pool.FindSlot(AState^.TargetEntityId)];
    if LTarget^.Id = 0 then
    begin
      // the target does not exist any more: resume what was before, or idle
      AMachine.PopState(ASlot, WAR_CAUSE_COMPLETION, WAR_RESULT_TARGET_INVALID);
      Exit;
    end;
    if LTarget^.EntityType = WAR_ENTITY_UNIT then
      LEnd := TWarTargetGeometry.PointOnTarget(LEntity, LTarget)
    else if LTarget^.HasUnit then
      LEnd := TWarUnitGeometry.CenterPosition(LTarget)
    else
      LEnd := LTarget^.Position;
  end;
  LDistanceSqr := TWarModelMath.DistanceSqr(LStart, LEnd);
  // already in distance: resume what was before
  LLimit := AState^.TargetDistance * AState^.TargetDistance;
  if LDistanceSqr <= LLimit then
  begin
    AMachine.PopState(ASlot, WAR_CAUSE_COMPLETION, WAR_RESULT_SUCCESS);
    Exit;
  end;
  LMove := AMachine.CreateMove(ASlot, [LStart, LEnd], False);
  AMachine.PushState(ASlot, PWarStateBase(LMove), WAR_CAUSE_COMPLETION);
end;

{ TWarFollowState }

class procedure TWarFollowState.UpdateAll(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateBase;
  LSlot: Integer;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_FOLLOW, LIndex] then
      Continue;
    LState := LContext.Storage.StateAt(WAR_STATE_FOLLOW, LIndex);
    LSlot := LContext.Pool.FindSlot(LState^.EntityId);
    if LSlot = 0 then
      Continue;
    if AMachine.ActiveState(LSlot) <> LState then
      Continue;
    if not AMachine.IsNextUpdateTime(LState) then
      Continue;
    UpdateOne(AMachine, LSlot, PWarStateFollow(LState));
  end;
end;

end.
