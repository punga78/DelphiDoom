{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the attack state                                  }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_attack.c, (c) 2019 Alejandro }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Attack;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   A unit that attacks a target (a unit, or a point where there is none). Out of range it pushes a move (to a point)
  ///   or a follow (to a unit); in range it turns to the target, plays its attack action and, when the action has reached its
  ///   blow, hits (a projectile for a shooter) and asks for the sound, at most one every quarter of a second. A target
  ///   that is gone, or dying, ends the state; one that is inside a building makes the unit wait a second. When the
  ///   target is the wall the unit goes within range of the tile of the attack and hits the piece of wall of that tile,
  ///   until the piece has no hit points; with no piece on the tile it swings forever (as the original). Defect of the original kept: it reads the action that is current, not the attack
  ///   one, so a unit that has no attack action (it keeps the one it had) never hits; with no current action it does not
  ///   hit either (the original reads before the array)
  /// </summary>
  TWarAttackState = class
  public
    /// <summary>wst_updateAttackStates</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.Math, DelphiDoom.War.Model.ActionTable,
  DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.TargetGeometry,
  DelphiDoom.War.Model.StateStorage, DelphiDoom.War.Model.Combat.Intf;

const
  MIN_ATTACK_SOUND_INTERVAL: Single = 0.25;

function TargetIsFinished(AMachine: TWarStateMachine; ASlot: Integer): Boolean;
begin
  Result := AMachine.IsDead(ASlot) or AMachine.IsGoingToDie(ASlot) or AMachine.IsCollapsing(ASlot) or
    AMachine.IsGoingToCollapse(ASlot);
end;

procedure UpdateOne(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateAttack);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LUnit: PWarUnitComponent;
  LTargetSlot: Integer;
  LTarget: PWarEntity;
  LPosition: TWarVec2;
  LUnitTile: TWarVec2;
  LTargetPosition: TWarVec2;
  LTargetTile: TWarVec2;
  LTargetIsUnit: Boolean;
  LTargetIsWall: Boolean;
  LPiece: Integer;
  LMove: PWarStateMove;
  LFollow: PWarStateFollow;
  LWait: PWarStateWait;
  LDx: Single;
  LDy: Single;
  LAction: ^TWarUnitAction;
  LSoundPosition: TWarVec2;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LUnit := @LEntity^.UnitData;
  LPosition := TWarUnitGeometry.CenterPosition(LEntity);
  LUnitTile := TWarUnitGeometry.CenterTile(LEntity);
  LTargetSlot := LContext.Pool.FindSlot(AState^.TargetEntityId);
  LTargetPosition := AState^.TargetPosition;
  LTargetTile := TWarModelMath.MapToTile(LTargetPosition);
  // the target is gone: go to the point of the attack, or finish
  if LTargetSlot = 0 then
  begin
    // going to a point where there is no unit, range 1 is enough, whatever the range of the unit
    if not TWarUnitGeometry.TileInRange(LEntity, LTargetTile, 1) then
    begin
      LMove := AMachine.CreateMove(ASlot, [LPosition, LTargetPosition], True);
      AMachine.PushState(ASlot, PWarStateBase(LMove), WAR_CAUSE_COMPLETION);
      Exit;
    end;
    AMachine.PopState(ASlot, WAR_CAUSE_COMPLETION, WAR_RESULT_SUCCESS);
    Exit;
  end;
  LTarget := LContext.Pool.Slots[LTargetSlot];
  LTargetIsUnit := LTarget^.EntityType = WAR_ENTITY_UNIT;
  if LTargetIsUnit then
  begin
    // a point of the unit that is closest to the attacker, not where the player clicked
    LTargetPosition := TWarTargetGeometry.PointOnTarget(LEntity, LTarget);
    LTargetTile := TWarModelMath.MapToTile(LTargetPosition);
    if not TWarTargetGeometry.UnitInRange(LEntity, LTarget, LUnit^.Range) then
    begin
      LFollow := AMachine.CreateFollow(ASlot, AState^.TargetEntityId, LTargetPosition,
        LUnit^.Range * WAR_MODEL_MEGA_TILE);
      AMachine.PushState(ASlot, PWarStateBase(LFollow), WAR_CAUSE_COMPLETION);
      Exit;
    end;
  end;
  LTargetIsWall := LTarget^.EntityType = WAR_ENTITY_WALL;
  if LTargetIsWall and not TWarUnitGeometry.TileInRange(LEntity, LTargetTile, LUnit^.Range) then
  begin
    LFollow := AMachine.CreateFollow(ASlot, 0, LTargetPosition, LUnit^.Range * WAR_MODEL_MEGA_TILE);
    AMachine.PushState(ASlot, PWarStateBase(LFollow), WAR_CAUSE_COMPLETION);
    Exit;
  end;
  // a worker that gathers inside a mine or a town hall: stop for a moment until it comes out
  if AMachine.IsInsideBuilding(LTargetSlot) then
  begin
    LWait := AMachine.CreateWait(ASlot, 1.0);
    AMachine.PushState(ASlot, PWarStateBase(LWait), WAR_CAUSE_COMPLETION);
    Exit;
  end;
  LContext.Occupancy.SetStaticEntity(Trunc(LUnitTile.X), Trunc(LUnitTile.Y), LUnit^.SizeX, LUnit^.SizeY, LEntity^.Id);
  LDx := LTargetTile.X - LUnitTile.X;
  LDy := LTargetTile.Y - LUnitTile.Y;
  LUnit^.Direction := TWarModelMath.DirectionFromDiff(LDx, LDy);
  TWarActionTable.SetAction(LUnit^, WAR_ACTION_ATTACK, False, 1.0);
  if LUnit^.ActionType < 0 then
    Exit;
  LAction := @LUnit^.Actions[LUnit^.ActionType];
  if LAction^.LastActionStep <> WAR_ACTION_STEP_ATTACK then
    Exit;
  // when the unit begins an attack it is not invisible any more
  LUnit^.Invisible := False;
  LUnit^.InvisibilityTime := 0;
  if LTargetIsUnit then
  begin
    // do this check before the damage, in case of many attackers: one of them could kill the target
    if TargetIsFinished(AMachine, LTargetSlot) then
      AMachine.PopState(ASlot, WAR_CAUSE_COMPLETION, WAR_RESULT_SUCCESS)
    else
    begin
      if TWarUnitClassifier.IsRange(LUnit^.UnitType) then
        LContext.Combat.RangeAttack(ASlot, LTargetSlot)
      else
        LContext.Combat.MeleeAttack(ASlot, LTargetSlot);
      if LContext.Clock^.GameTime - LUnit^.LastAttackSoundGameTime >= MIN_ATTACK_SOUND_INTERVAL then
      begin
        LSoundPosition := TWarUnitGeometry.CenterPosition(LTarget);
        if Assigned(LContext.CombatEvents) then
          LContext.CombatEvents.AttackSound(LSoundPosition, LAction^.LastSoundStep);
        LUnit^.LastAttackSoundGameTime := LContext.Clock^.GameTime;
      end;
    end;
  end
  else if LTargetIsWall then
  begin
    LPiece := LContext.Walls.IndexAt(Trunc(LTargetTile.X), Trunc(LTargetTile.Y));
    if LPiece >= 0 then
    begin
      // checked before the damage, in case of many attackers: one of them could have destroyed the piece
      if LContext.Walls[LPiece]^.Hp = 0 then
        AMachine.PopState(ASlot, WAR_CAUSE_COMPLETION, WAR_RESULT_SUCCESS)
      else
      begin
        if TWarUnitClassifier.IsRange(LUnit^.UnitType) then
          LContext.Combat.RangeWallAttack(ASlot, LTargetSlot, LPiece)
        else
          LContext.Combat.MeleeWallAttack(ASlot, LPiece);
        if LContext.Clock^.GameTime - LUnit^.LastAttackSoundGameTime >= MIN_ATTACK_SOUND_INTERVAL then
        begin
          LSoundPosition := TWarModelMath.TileToMap(LTargetTile, True);
          if Assigned(LContext.CombatEvents) then
            LContext.CombatEvents.AttackSound(LSoundPosition, LAction^.LastSoundStep);
          LUnit^.LastAttackSoundGameTime := LContext.Clock^.GameTime;
        end;
      end;
    end;
  end;
  // the actions and the state machine have to talk somehow
  LAction^.LastActionStep := WAR_ACTION_STEP_NONE;
  LAction^.LastSoundStep := WAR_ACTION_STEP_NONE;
end;

{ TWarAttackState }

class procedure TWarAttackState.UpdateAll(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateBase;
  LSlot: Integer;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_ATTACK, LIndex] then
      Continue;
    LState := LContext.Storage.StateAt(WAR_STATE_ATTACK, LIndex);
    LSlot := LContext.Pool.FindSlot(LState^.EntityId);
    if LSlot = 0 then
      Continue;
    if AMachine.ActiveState(LSlot) <> LState then
      Continue;
    if not AMachine.IsNextUpdateTime(LState) then
      Continue;
    UpdateOne(AMachine, LSlot, PWarStateAttack(LState));
  end;
end;

end.
