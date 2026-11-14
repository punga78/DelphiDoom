{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the move state                                    }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_move.c, (c) 2019 Alejandro   }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Move;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   A unit that goes through a list of waypoints (centers in pixels, the first is where it was). Every tic runs the
  ///   seven passes of the original over all the moving units: no velocity, look for an attacker, preferred
  ///   velocity, adjusted velocity, new position, progress and recovery, and the velocity kept for the next tic. Without
  ///   an IWarMovementSteering (the pathfinding and the avoidance of the units, issue #195) a unit goes straight to the
  ///   next waypoint: it is what the original does on a free field with no other unit near, and what the golden of parity
  ///   covers. A unit that does not get closer by 4 pixels for 3 seconds gives up (BLOCKED)
  /// </summary>
  TWarMoveState = class
  public
    /// <summary>wst_enterMoveState: a move with fewer than two waypoints ends at once (NO_DESTINATION)</summary>
    class procedure Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase); static;
    /// <summary>wst_exitMoveState</summary>
    class procedure Leave(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase; AReason: Integer); static;
    /// <summary>wst_updateMoveStates</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Math, DelphiDoom.War.Model.ActionTable,
  DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.StateStorage, DelphiDoom.War.Model.StraightSteering,
  DelphiDoom.War.Model.Intf;

const
  // the constants of war_state_machine_move.c, as 32 bit floats
  PROGRESS_DISTANCE: Single = 4.0;
  PATH_REFRESH_TIME: Single = 0.5;
  AVOIDANCE_RECOVERY_TIME: Single = 1.5;
  BLOCKED_TIME: Single = 3.0;
  LOW_VELOCITY: Single = 1.0;
  ARRIVAL_SLOWDOWN_RADIUS: Single = 48.0;
  ARRIVAL_MIN_SCALE: Single = 0.25;
  MOVE_EPSILON: Single = 0.5;
  SINGLE_MAX: Single = 3.402823466E+38;

type
  TMovePass = procedure(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateMove);

procedure ResetProgress(AEntity: PWarEntity; AState: PWarStateMove);
var
  LPosition: TWarVec2;
  LGoal: TWarVec2;
begin
  AState^.Progress := Default(TWarMoveProgress);
  AState^.Progress.BestDistanceSq := SINGLE_MAX;
  AState^.ProgressGoalPosition.X := 0;
  AState^.ProgressGoalPosition.Y := 0;
  AState^.ProgressWaypointIndex := -1;
  if AState^.WaypointsIndex >= AState^.WaypointsCount - 1 then
    Exit;
  LPosition := TWarUnitGeometry.CenterPosition(AEntity);
  LGoal := AState^.Waypoints[AState^.WaypointsIndex + 1];
  AState^.Progress.BestDistanceSq := TWarModelMath.DistanceSqr(LPosition, LGoal);
  AState^.ProgressGoalPosition := LGoal;
  AState^.ProgressWaypointIndex := AState^.WaypointsIndex;
end;

procedure ClearVelocities(AState: PWarStateMove);
begin
  AState^.RvoPreferredVelocity.X := 0;
  AState^.RvoPreferredVelocity.Y := 0;
end;

// pass 2: an enemy that attacks the unit takes the attention of a unit that looks for attacks
procedure CheckForAttacks(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateMove);
var
  LContext: TWarModelContext;
  LEnemy: Integer;
  LAttack: PWarStateAttack;
begin
  if not AState^.CheckForAttacks then
    Exit;
  LContext := AMachine.Context;
  LEnemy := LContext.Queries.Attacker(ASlot);
  if (LEnemy <> 0) and LContext.Queries.AreEnemies(ASlot, LEnemy) and LContext.Queries.CanAttack(ASlot, LEnemy) and
    AMachine.CanSubmitTransition(ASlot, WAR_INTERRUPT_AUTONOMOUS) then
  begin
    LAttack := AMachine.CreateAttack(ASlot, LContext.Pool.Slots[LEnemy]^.Id, LContext.Pool.Slots[LEnemy]^.Position);
    AMachine.PushState(ASlot, PWarStateBase(LAttack), WAR_CAUSE_AUTONOMOUS);
  end;
end;

// pass 3
procedure UpdatePreferredVelocity(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateMove);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LPosition: TWarVec2;
  LNext: TWarVec2;
  LGoal: TWarVec2;
  LDirection: TWarVec2;
  LSpeed: Single;
  LPreferred: TWarVec2;
  LDistanceSqr: Single;
  LDistance: Single;
  LScale: Single;
  LRadiusSqr: Single;
begin
  if AState^.WaypointsIndex >= AState^.WaypointsCount - 1 then
    Exit;
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LPosition := TWarUnitGeometry.CenterPosition(LEntity);
  LNext := AState^.Waypoints[AState^.WaypointsIndex + 1];
  // the flow field of the original is zero on a free field and the unit goes straight: a vector to the next waypoint
  LDirection := TWarModelMath.Sub(LNext, LPosition);
  LDirection := TWarModelMath.Normalize(LDirection);
  LSpeed := LContext.UnitSpeed(LEntity^.UnitData.UnitType, LEntity^.UnitData.Speed);
  LPreferred := TWarModelMath.Scale(LDirection, LSpeed);
  // slow down when approaching the final waypoint to avoid overshooting
  if AState^.WaypointsIndex >= AState^.WaypointsCount - 2 then
  begin
    LGoal := AState^.Waypoints[AState^.WaypointsCount - 1];
    LDistanceSqr := TWarModelMath.DistanceSqr(LPosition, LGoal);
    LRadiusSqr := ARRIVAL_SLOWDOWN_RADIUS * ARRIVAL_SLOWDOWN_RADIUS;
    if LDistanceSqr < LRadiusSqr then
    begin
      LDistance := Sqrt(LDistanceSqr);
      LScale := LDistance / ARRIVAL_SLOWDOWN_RADIUS;
      if not (LScale > ARRIVAL_MIN_SCALE) then
        LScale := ARRIVAL_MIN_SCALE;
      LPreferred := TWarModelMath.Scale(LPreferred, LScale);
    end;
  end;
  AState^.RvoPreferredVelocity := LPreferred;
end;

// pass 4
procedure UpdateAdjustedVelocity(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateMove);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LSpeed: Single;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LSpeed := LContext.UnitSpeed(LEntity^.UnitData.UnitType, LEntity^.UnitData.Speed);
  AState^.RvoAdjustedVelocity := TWarStraightSteering.NewVelocity(AState^.RvoPreferredVelocity, LSpeed);
end;

// pass 5
procedure UpdatePosition(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateMove);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LPosition: TWarVec2;
  LNext: TWarVec2;
  LStep: TWarVec2;
  LToNext: TWarVec2;
  LNewPosition: TWarVec2;
  LDistanceSqr: Single;
  LEpsilonSqr: Single;
begin
  if AState^.WaypointsIndex >= AState^.WaypointsCount - 1 then
    Exit;
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LPosition := TWarUnitGeometry.CenterPosition(LEntity);
  LNext := AState^.Waypoints[AState^.WaypointsIndex + 1];
  // overshoot clamp: a step that would go past the waypoint stops on it
  LStep := TWarModelMath.Scale(AState^.RvoAdjustedVelocity, LContext.Clock^.DeltaTime);
  LToNext := TWarModelMath.Sub(LNext, LPosition);
  if TWarModelMath.LengthSqr(LStep) > TWarModelMath.LengthSqr(LToNext) then
    LStep := LToNext;
  LNewPosition := TWarModelMath.Add(LPosition, LStep);
  LEntity^.UnitData.Direction := TWarModelMath.DirectionFromDiff(AState^.RvoAdjustedVelocity.X,
    AState^.RvoAdjustedVelocity.Y);
  TWarActionTable.SetAction(LEntity^.UnitData, WAR_ACTION_WALK, False, TWarUnitGeometry.ActionScale(LEntity));
  TWarUnitGeometry.SetCenterPosition(LEntity, LNewPosition);
  LDistanceSqr := TWarModelMath.DistanceSqr(LNewPosition, LNext);
  LEpsilonSqr := MOVE_EPSILON * MOVE_EPSILON;
  if LDistanceSqr < LEpsilonSqr then
  begin
    LNewPosition := LNext;
    TWarUnitGeometry.SetCenterPosition(LEntity, LNewPosition);
    Inc(AState^.WaypointsIndex);
    if AState^.WaypointsIndex >= AState^.WaypointsCount - 1 then
    begin
      AState^.RvoVelocity.X := 0;
      AState^.RvoVelocity.Y := 0;
      AState^.RvoPreferredVelocity.X := 0;
      AState^.RvoPreferredVelocity.Y := 0;
      AMachine.PopState(ASlot, WAR_CAUSE_COMPLETION, WAR_RESULT_SUCCESS);
    end;
  end;
end;

// pass 6
procedure UpdateProgressAndRecovery(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateMove);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LPosition: TWarVec2;
  LGoal: TWarVec2;
  LGoalChanged: Boolean;
  LEpsilonSqr: Single;
  LDistanceSqr: Single;
  LDistance: Single;
  LBestDistance: Single;
  LGain: Single;
  LVelocitySqr: Single;
  LLowSqr: Single;
begin
  if AState^.WaypointsIndex >= AState^.WaypointsCount - 1 then
    Exit;
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LPosition := TWarUnitGeometry.CenterPosition(LEntity);
  LGoal := AState^.Waypoints[AState^.WaypointsIndex + 1];
  LEpsilonSqr := MOVE_EPSILON * MOVE_EPSILON;
  LGoalChanged := (AState^.ProgressWaypointIndex <> AState^.WaypointsIndex) or
    (TWarModelMath.DistanceSqr(AState^.ProgressGoalPosition, LGoal) >= LEpsilonSqr);
  if LGoalChanged then
  begin
    ResetProgress(LEntity, AState);
    Exit;
  end;
  LDistanceSqr := TWarModelMath.DistanceSqr(LPosition, LGoal);
  LDistance := Sqrt(LDistanceSqr);
  LBestDistance := Sqrt(AState^.Progress.BestDistanceSq);
  LGain := LBestDistance - LDistance;
  if LGain >= PROGRESS_DISTANCE then
  begin
    AState^.Progress.BestDistanceSq := LDistanceSqr;
    AState^.Progress.NoProgressTime := 0;
    AState^.Progress.LowVelocityTime := 0;
    AState^.Progress.RecoveryAttempt := 0;
    Exit;
  end;
  AState^.Progress.NoProgressTime := AState^.Progress.NoProgressTime + LContext.Clock^.DeltaTime;
  LVelocitySqr := TWarModelMath.LengthSqr(AState^.RvoAdjustedVelocity);
  LLowSqr := LOW_VELOCITY * LOW_VELOCITY;
  if LVelocitySqr <= LLowSqr then
    AState^.Progress.LowVelocityTime := AState^.Progress.LowVelocityTime + LContext.Clock^.DeltaTime
  else
    AState^.Progress.LowVelocityTime := 0;
  // the first recovery asks for a new flow field, which is the business of the pathfinding
  if (AState^.Progress.RecoveryAttempt < 1) and (AState^.Progress.NoProgressTime >= PATH_REFRESH_TIME) then
    AState^.Progress.RecoveryAttempt := 1;
  if (AState^.Progress.RecoveryAttempt < 2) and (AState^.Progress.NoProgressTime >= AVOIDANCE_RECOVERY_TIME) then
    AState^.Progress.RecoveryAttempt := 2;
  if AState^.Progress.NoProgressTime >= BLOCKED_TIME then
  begin
    AState^.Progress.RecoveryAttempt := 3;
    AState^.RvoPreferredVelocity.X := 0;
    AState^.RvoPreferredVelocity.Y := 0;
    AState^.RvoAdjustedVelocity.X := 0;
    AState^.RvoAdjustedVelocity.Y := 0;
    AState^.RvoVelocity.X := 0;
    AState^.RvoVelocity.Y := 0;
    AMachine.PopState(ASlot, WAR_CAUSE_COMPLETION, WAR_RESULT_BLOCKED);
  end;
end;

// pass 7
procedure KeepVelocity(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateMove);
begin
  AState^.RvoVelocity := AState^.RvoAdjustedVelocity;
end;

// pass 1
procedure ForgetPreferredVelocity(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateMove);
begin
  ClearVelocities(AState);
end;

procedure RunPass(AMachine: TWarStateMachine; APass: TMovePass);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateMove;
  LSlot: Integer;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_MOVE, LIndex] then
      Continue;
    LState := PWarStateMove(LContext.Storage.StateAt(WAR_STATE_MOVE, LIndex));
    LSlot := LContext.Pool.FindSlot(LState^.Base.EntityId);
    if (LSlot = 0) or (LContext.Pool.Slots[LSlot]^.EntityType <> WAR_ENTITY_UNIT) then
      Continue;
    if AMachine.ActiveState(LSlot) <> PWarStateBase(LState) then
      Continue;
    APass(AMachine, LSlot, LState);
  end;
end;

{ TWarMoveState }

class procedure TWarMoveState.Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase);
var
  LState: PWarStateMove;
begin
  LState := PWarStateMove(AState);
  if LState^.WaypointsCount <= 1 then
  begin
    AMachine.PopState(ASlot, WAR_CAUSE_COMPLETION, WAR_RESULT_NO_DESTINATION);
    Exit;
  end;
  LState^.WaypointsIndex := 0;
  LState^.RvoVelocity.X := 0;
  LState^.RvoVelocity.Y := 0;
  ResetProgress(AMachine.Context.Pool.Slots[ASlot], LState);
end;

class procedure TWarMoveState.Leave(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase;
  AReason: Integer);
begin
  PWarStateMove(AState)^.RvoVelocity.X := 0;
  PWarStateMove(AState)^.RvoVelocity.Y := 0;
end;

class procedure TWarMoveState.UpdateAll(AMachine: TWarStateMachine);
begin
  RunPass(AMachine, ForgetPreferredVelocity);
  RunPass(AMachine, CheckForAttacks);
  RunPass(AMachine, UpdatePreferredVelocity);
  RunPass(AMachine, UpdateAdjustedVelocity);
  RunPass(AMachine, UpdatePosition);
  RunPass(AMachine, UpdateProgressAndRecovery);
  RunPass(AMachine, KeepVelocity);
end;

end.
