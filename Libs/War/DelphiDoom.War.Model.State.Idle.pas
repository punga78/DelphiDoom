{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the idle state                                    }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_idle.c, (c) 2019 Alejandro   }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Idle;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine,
  DelphiDoom.War.Model.Context;

type
  /// <summary>
  ///   A unit that stands: it occupies its tiles, looks around now and then (one chance in five, each second, to turn a
  ///   step) and a warrior attacks the first enemy that it sees within 5 tiles. The state updates once a second. The
  ///   entity of the wall (the pieces are in the walls of the context) is idle too: every tic its pieces free or
  ///   fill their tiles by their hit points
  /// </summary>
  TWarIdleState = class
  strict private
    /// <summary>
    ///   The idle state of the wall (wst_updateIdleState for a wall): a piece with no hit points frees its tile, any other
    ///   one fills it with the entity of the wall. No delay: it runs at every tic
    /// </summary>
    class procedure UpdateWall(AContext: TWarModelContext; AEntity: PWarEntity); static;
  public
    /// <summary>wst_enterIdleState</summary>
    class procedure Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase); static;
    /// <summary>wst_exitIdleState</summary>
    class procedure Leave(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase; AReason: Integer); static;
    /// <summary>wst_updateIdleStates</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.ActionTable, DelphiDoom.War.Model.UnitClassifier,
  DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.StateStorage, DelphiDoom.War.Model.Construction.Types;

{ TWarIdleState }

class procedure TWarIdleState.UpdateWall(AContext: TWarModelContext; AEntity: PWarEntity);
var
  LIndex: Integer;
  LPiece: PWarWallPiece;
  LPercent: Integer;
begin
  for LIndex := 0 to AContext.Walls.Count - 1 do
  begin
    LPiece := AContext.Walls[LIndex];
    // a piece with no maximum has no hit points (the original divides by zero there)
    if LPiece^.MaxHp <= 0 then
      LPercent := 0
    else
      LPercent := TWarModelMath.PercentOf(LPiece^.Hp, LPiece^.MaxHp);
    if LPercent <= 0 then
      AContext.Occupancy.SetFreeTiles(LPiece^.TileX, LPiece^.TileY, 1, 1)
    else
      AContext.Occupancy.SetStaticEntity(LPiece^.TileX, LPiece^.TileY, 1, 1, AEntity^.Id);
  end;
end;

class procedure TWarIdleState.Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase);
var
  LEntity: PWarEntity;
  LTile: TWarVec2;
begin
  LEntity := AMachine.Context.Pool.Slots[ASlot];
  if LEntity^.EntityType = WAR_ENTITY_UNIT then
  begin
    LTile := TWarUnitGeometry.Tile(LEntity);
    AMachine.Context.Occupancy.SetStaticEntity(Trunc(LTile.X), Trunc(LTile.Y), LEntity^.UnitData.SizeX,
      LEntity^.UnitData.SizeY, LEntity^.Id);
    TWarActionTable.SetAction(LEntity^.UnitData, WAR_ACTION_IDLE, True, 1.0);
  end;
end;

class procedure TWarIdleState.Leave(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase;
  AReason: Integer);
var
  LEntity: PWarEntity;
  LTile: TWarVec2;
begin
  LEntity := AMachine.Context.Pool.Slots[ASlot];
  if LEntity^.EntityType = WAR_ENTITY_UNIT then
  begin
    LTile := TWarUnitGeometry.Tile(LEntity);
    AMachine.Context.Occupancy.SetFreeTiles(Trunc(LTile.X), Trunc(LTile.Y), LEntity^.UnitData.SizeX,
      LEntity^.UnitData.SizeY);
  end;
end;

class procedure TWarIdleState.UpdateAll(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateIdle;
  LSlot: Integer;
  LEntity: PWarEntity;
  LEnemy: Integer;
  LAttack: PWarStateAttack;
  LStep: Integer;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_IDLE, LIndex] then
      Continue;
    LState := PWarStateIdle(LContext.Storage.StateAt(WAR_STATE_IDLE, LIndex));
    LSlot := LContext.Pool.FindSlot(LState^.Base.EntityId);
    if LSlot = 0 then
      Continue;
    if AMachine.ActiveState(LSlot) <> PWarStateBase(LState) then
      Continue;
    if not AMachine.IsNextUpdateTime(PWarStateBase(LState)) then
      Continue;
    LEntity := LContext.Pool.Slots[LSlot];
    if LEntity^.EntityType = WAR_ENTITY_WALL then
    begin
      UpdateWall(LContext, LEntity);
      Continue;
    end;
    if LEntity^.EntityType <> WAR_ENTITY_UNIT then
      Continue;
    if LState^.LookAround then
    begin
      if LContext.Random.Below(100) < 20 then
      begin
        // randomi(-1, 2)
        LStep := LContext.Random.Below(3) - 1;
        LEntity^.UnitData.Direction := LEntity^.UnitData.Direction + LStep;
        if (LEntity^.UnitData.Direction < 0) and not LContext.UnsignedDirections then
          LEntity^.UnitData.Direction := WAR_DIRECTION_NORTH_WEST
        else if (LEntity^.UnitData.Direction >= WAR_DIRECTION_COUNT) or (LEntity^.UnitData.Direction < 0) then
          LEntity^.UnitData.Direction := WAR_DIRECTION_NORTH;
      end;
    end;
    // look for foes to attack them if they are in range
    if TWarUnitClassifier.IsWarrior(LEntity^.UnitData.UnitType) then
    begin
      LEnemy := LContext.Queries.NearEnemy(LSlot);
      if (LEnemy <> 0) and AMachine.CanSubmitTransition(LSlot, WAR_INTERRUPT_AUTONOMOUS) then
      begin
        LAttack := AMachine.CreateAttack(LSlot, LContext.Pool.Slots[LEnemy]^.Id, LContext.Pool.Slots[LEnemy]^.Position);
        AMachine.ReplaceState(LSlot, PWarStateBase(LAttack), WAR_CAUSE_AUTONOMOUS);
      end;
    end;
    // a way to tell the state machine not to update this state for the given time
    LState^.Base.Delay := 1.0;
  end;
end;

end.
