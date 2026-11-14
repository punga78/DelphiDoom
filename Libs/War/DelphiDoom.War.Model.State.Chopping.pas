{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the chopping state                                }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_chopping.c, (c) 2019         }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Chopping;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   A worker that chops a tree: each blow of its harvest action (the step that the action sets, see
  ///   TWarActionRunner) takes 2 wood from the tree, and when it carries 100 it takes them to the closest town hall.
  ///   If the tree is gone it asks for a new one (gather wood). The unit holds its tile while it chops
  /// </summary>
  TWarChoppingState = class
  public
    /// <summary>wst_enterChoppingState</summary>
    class procedure Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase); static;
    /// <summary>wst_updateChoppingState</summary>
    class procedure UpdateState(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateChopping); static;
    /// <summary>wst_updateChoppingStates</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Autotile.Types, DelphiDoom.War.Map.Forest, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.StateStorage, DelphiDoom.War.Model.UnitGeometry,
  DelphiDoom.War.Model.UnitSprites, DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitSearch,
  DelphiDoom.War.Model.ActionTable, DelphiDoom.War.Model.ActionRunner, DelphiDoom.War.Model.State.GatherFactory;

const
  UNIT_MAX_CARRY_WOOD = WAR_MODEL_MAX_CARRY;
  // the wood that a blow takes
  WOOD_PER_BLOW = 2;

{ TWarChoppingState }

class procedure TWarChoppingState.Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LUnitTile: TWarVec2;
  LTreeTile: TWarVec2;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LUnitTile := TWarUnitGeometry.CenterTile(LEntity);
  LTreeTile := TWarModelMath.MapToTile(PWarStateChopping(AState)^.Position);
  LContext.Occupancy.SetStaticEntity(Trunc(LUnitTile.X), Trunc(LUnitTile.Y), LEntity^.UnitData.SizeX,
    LEntity^.UnitData.SizeY, LEntity^.Id);
  LEntity^.UnitData.Direction := TWarModelMath.DirectionFromDiff(LTreeTile.X - LUnitTile.X, LTreeTile.Y - LUnitTile.Y);
  TWarActionTable.SetAction(LEntity^.UnitData, WAR_ACTION_HARVEST, True, 1.0);
end;

class procedure TWarChoppingState.UpdateState(AMachine: TWarStateMachine; ASlot: Integer;
  AState: PWarStateChopping);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LUnit: PWarUnitComponent;
  LForest: TWarMapForest;
  LTree: TWarTree;
  LTreeTile: TWarVec2;
  LAction: ^TWarUnitAction;
  LTownHall: Integer;
  LDeliver: PWarStateDeliver;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LUnit := @LEntity^.UnitData;
  LForest := nil;
  if LContext.Pool.FindSlot(AState^.ForestId) <> 0 then
    LForest := LContext.RequireGather.Forests.FindForest(AState^.ForestId);
  // if the forest doesn't exists, go idle
  if not Assigned(LForest) then
  begin
    TWarGatherStateFactory.ReplaceWithIdle(AMachine, ASlot);
    Exit;
  end;
  LTreeTile := TWarModelMath.MapToTile(AState^.Position);
  if (not LForest.TryGetTreeAt(Trunc(LTreeTile.X), Trunc(LTreeTile.Y), LTree)) or (LTree.Amount = 0) then
  begin
    AMachine.ReplaceState(ASlot, PWarStateBase(TWarGatherStateFactory.NewWood(AMachine, ASlot, LForest.Id,
      AState^.Position)), WAR_CAUSE_COMPLETION);
    Exit;
  end;
  // the original indexes the actions with the one of the unit, which is always one of the seven here
  if (LUnit^.ActionType < 0) or (LUnit^.ActionType >= WAR_ACTION_TYPE_COUNT) then
    Exit;
  LAction := @LUnit^.Actions[LUnit^.ActionType];
  if LAction^.LastActionStep = WAR_ACTION_STEP_ATTACK then
  begin
    LUnit^.Amount := LUnit^.Amount + LContext.RequireGather.Forests.ChopTree(LForest, Trunc(LTreeTile.X),
      Trunc(LTreeTile.Y), WOOD_PER_BLOW);
    if LUnit^.Amount > 0 then
      LUnit^.ResourceKind := wrkWood;
    if LAction^.LastSoundStep = WAR_ACTION_STEP_SOUND_CHOPPING then
      LContext.RequireGather.Events.TreeChopped(AState^.Position);
    if LUnit^.Amount = UNIT_MAX_CARRY_WOOD then
    begin
      // set the carrying wood sprites
      TWarUnitSprites.Remove(LEntity);
      TWarUnitSprites.Add(LEntity, TWarUnitSprites.CarryingWood(LUnit^.UnitType));
      // find the closest town hall to deliver the wood
      LTownHall := TWarUnitSearch.FindClosestOfType(LContext, ASlot,
        TWarUnitSearch.TownHallOfRace(TWarUnitClassifier.RaceOf(LUnit^.UnitType)));
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
        LDeliver^.SourceKind := wrkWood;
        LDeliver^.SourceId := LForest.Id;
        LDeliver^.SourcePosition := AState^.Position;
      end;
      AMachine.ReplaceState(ASlot, PWarStateBase(LDeliver), WAR_CAUSE_COMPLETION);
    end;
    // the actions and the state machine have to comunicate somehow
    LAction^.LastActionStep := WAR_ACTION_STEP_NONE;
    LAction^.LastSoundStep := WAR_ACTION_STEP_NONE;
  end;
end;

class procedure TWarChoppingState.UpdateAll(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateChopping;
  LSlot: Integer;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_CHOPPING, LIndex] then
      Continue;
    LState := PWarStateChopping(LContext.Storage.StateAt(WAR_STATE_CHOPPING, LIndex));
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
