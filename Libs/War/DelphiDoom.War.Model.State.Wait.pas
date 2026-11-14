{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the wait state                                    }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_wait.c, (c) 2019 Alejandro   }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Wait;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   A unit that waits for a given game time, standing on its tiles, and then ends (the state below goes on).
  ///   Defect of the original kept: the exit hook frees the tiles only if the stack is empty, but the stack is never empty
  ///   when a state leaves (the state is popped after), so a wait never frees them
  /// </summary>
  TWarWaitState = class
  public
    /// <summary>wst_enterWaitState</summary>
    class procedure Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase); static;
    /// <summary>wst_exitWaitState</summary>
    class procedure Leave(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase; AReason: Integer); static;
    /// <summary>wst_updateWaitStates</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.ActionTable, DelphiDoom.War.Model.StateStorage;

{ TWarWaitState }

class procedure TWarWaitState.Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase);
var
  LEntity: PWarEntity;
  LPosition: TWarVec2;
begin
  LEntity := AMachine.Context.Pool.Slots[ASlot];
  LPosition := TWarModelMath.MapToTile(LEntity^.Position);
  AMachine.Context.Occupancy.SetStaticEntity(Trunc(LPosition.X), Trunc(LPosition.Y), LEntity^.UnitData.SizeX,
    LEntity^.UnitData.SizeY, LEntity^.Id);
  TWarActionTable.SetAction(LEntity^.UnitData, WAR_ACTION_IDLE, True, 1.0);
end;

class procedure TWarWaitState.Leave(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase;
  AReason: Integer);
var
  LEntity: PWarEntity;
  LPosition: TWarVec2;
begin
  LEntity := AMachine.Context.Pool.Slots[ASlot];
  if LEntity^.HasStateMachine and (LEntity^.StateMachine.Depth > 0) then
    Exit;
  LPosition := TWarModelMath.MapToTile(LEntity^.Position);
  AMachine.Context.Occupancy.SetFreeTiles(Trunc(LPosition.X), Trunc(LPosition.Y), LEntity^.UnitData.SizeX,
    LEntity^.UnitData.SizeY);
end;

class procedure TWarWaitState.UpdateAll(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateBase;
  LSlot: Integer;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_WAIT, LIndex] then
      Continue;
    LState := LContext.Storage.StateAt(WAR_STATE_WAIT, LIndex);
    LSlot := LContext.Pool.FindSlot(LState^.EntityId);
    if LSlot = 0 then
      Continue;
    if AMachine.ActiveState(LSlot) <> LState then
      Continue;
    if not AMachine.IsNextUpdateTime(LState) then
      Continue;
    if LContext.Clock^.GameTime >= PWarStateWait(LState)^.WaitEndGameTime then
      AMachine.PopState(LSlot, WAR_CAUSE_COMPLETION, WAR_RESULT_SUCCESS);
  end;
end;

end.
