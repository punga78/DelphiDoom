{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the patrol state                                  }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_patrol.c, (c) 2019 Alejandro }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Patrol;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   A unit that walks a list of waypoints to the last one and back, for ever (a move that looks for attacks is
  ///   pushed; when it is over the list is reversed and a new one is pushed). With fewer than two waypoints it ends
  ///   (NO_DESTINATION); if when the move is over the unit is not at the last waypoint, it goes idle
  /// </summary>
  TWarPatrolState = class
  public
    /// <summary>wst_enterPatrolState</summary>
    class procedure Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase); static;
    /// <summary>wst_updatePatrolStates</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.Math, DelphiDoom.War.Model.UnitGeometry,
  DelphiDoom.War.Model.StateStorage;

const
  MOVE_EPSILON: Single = 0.5;

procedure PushMove(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStatePatrol);
var
  LMove: PWarStateMove;
begin
  LMove := AMachine.CreateMove(ASlot, Slice(AState^.Waypoints, AState^.WaypointsCount), True);
  AMachine.PushState(ASlot, PWarStateBase(LMove), WAR_CAUSE_COMPLETION);
end;

procedure UpdateOne(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStatePatrol);
var
  LActual: TWarVec2;
  LShouldBeAt: TWarVec2;
  LLimit: Single;
  LIdle: PWarStateIdle;
  LIndex: Integer;
  LTemp: TWarVec2;
begin
  // if the unit is not where it should be, the move had a problem: abort and go idle
  LActual := TWarUnitGeometry.CenterPosition(AMachine.Context.Pool.Slots[ASlot]);
  LShouldBeAt := AState^.Waypoints[AState^.WaypointsCount - 1];
  LLimit := MOVE_EPSILON * MOVE_EPSILON;
  if TWarModelMath.DistanceSqr(LActual, LShouldBeAt) >= LLimit then
  begin
    LIdle := AMachine.CreateIdle(ASlot, True);
    AMachine.ReplaceState(ASlot, PWarStateBase(LIdle), WAR_CAUSE_COMPLETION);
    Exit;
  end;
  // otherwise reverse the waypoints in place and move again
  AState^.Dir := AState^.Dir * -1;
  for LIndex := 0 to AState^.WaypointsCount div 2 - 1 do
  begin
    LTemp := AState^.Waypoints[LIndex];
    AState^.Waypoints[LIndex] := AState^.Waypoints[AState^.WaypointsCount - 1 - LIndex];
    AState^.Waypoints[AState^.WaypointsCount - 1 - LIndex] := LTemp;
  end;
  PushMove(AMachine, ASlot, AState);
end;

{ TWarPatrolState }

class procedure TWarPatrolState.Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase);
var
  LState: PWarStatePatrol;
begin
  LState := PWarStatePatrol(AState);
  if LState^.WaypointsCount <= 1 then
  begin
    AMachine.PopState(ASlot, WAR_CAUSE_COMPLETION, WAR_RESULT_NO_DESTINATION);
    Exit;
  end;
  PushMove(AMachine, ASlot, LState);
end;

class procedure TWarPatrolState.UpdateAll(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateBase;
  LSlot: Integer;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_PATROL, LIndex] then
      Continue;
    LState := LContext.Storage.StateAt(WAR_STATE_PATROL, LIndex);
    LSlot := LContext.Pool.FindSlot(LState^.EntityId);
    if LSlot = 0 then
      Continue;
    if AMachine.ActiveState(LSlot) <> LState then
      Continue;
    if not AMachine.IsNextUpdateTime(LState) then
      Continue;
    UpdateOne(AMachine, LSlot, PWarStatePatrol(LState));
  end;
end;

end.
