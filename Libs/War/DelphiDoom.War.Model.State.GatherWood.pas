{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the gather wood state                             }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_gather_wood.c, (c) 2019      }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.GatherWood;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   A worker that goes to a tree of a forest: if the tree is gone, empty or has no free tile next to it the worker
  ///   takes the closest tree that it can reach (and remembers it); if no tree is left it goes idle; if the tree is not
  ///   within range it walks there (a move pushed on top of this state); if it is there it starts to chop
  /// </summary>
  TWarGatherWoodState = class
  public
    /// <summary>wst_updateGatherWoodState</summary>
    class procedure UpdateState(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateWood); static;
    /// <summary>wst_updateWoodStates</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  DelphiDoom.War.Autotile.Types, DelphiDoom.War.Map.Forest, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.Math,
  DelphiDoom.War.Model.StateStorage, DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.State.GatherFactory;

{ TWarGatherWoodState }

class procedure TWarGatherWoodState.UpdateState(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateWood);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LForest: TWarMapForest;
  LTree: TWarTree;
  LTreeTile: TWarVec2;
  LTreePosition: TWarVec2;
  LPosition: TWarVec2;
  LRange: Integer;
  LFound: Boolean;
  LMove: PWarStateMove;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LRange := LContext.Database.GetUnitStats(LEntity^.UnitData.UnitType).Range;
  LForest := nil;
  if LContext.Pool.FindSlot(AState^.ForestId) <> 0 then
    LForest := LContext.RequireGather.Forests.FindForest(AState^.ForestId);
  if not Assigned(LForest) then
  begin
    TWarGatherStateFactory.ReplaceWithIdle(AMachine, ASlot);
    Exit;
  end;
  LTreePosition := AState^.Position;
  LTreeTile := TWarModelMath.MapToTile(LTreePosition);
  LFound := LForest.TryGetTreeAt(Trunc(LTreeTile.X), Trunc(LTreeTile.Y), LTree);
  if (not LFound) or (LTree.Amount = 0) or
    not LContext.RequireGather.Grid.IsTileAccessible(Trunc(LTreeTile.X), Trunc(LTreeTile.Y)) then
  begin
    if not LContext.RequireGather.Forests.FindAccessibleTree(LForest, Trunc(LTreeTile.X), Trunc(LTreeTile.Y), LTree) then
    begin
      TWarGatherStateFactory.ReplaceWithIdle(AMachine, ASlot);
      Exit;
    end;
    LTreeTile := TWarModelMath.Vec(LTree.TileX, LTree.TileY);
    LTreePosition := TWarModelMath.TileToMap(LTreeTile, True);
    AState^.Position := LTreePosition;
  end;
  if not TWarUnitGeometry.TileInRange(LEntity, LTreeTile, LRange) then
  begin
    LPosition := TWarUnitGeometry.CenterPosition(LEntity);
    LMove := AMachine.CreateMove(ASlot, [LPosition, LTreePosition], False);
    AMachine.PushState(ASlot, PWarStateBase(LMove), WAR_CAUSE_COMPLETION);
    Exit;
  end;
  AMachine.ReplaceState(ASlot, PWarStateBase(TWarGatherStateFactory.NewChopping(AMachine, ASlot, AState^.ForestId,
    LTreePosition)), WAR_CAUSE_COMPLETION);
end;

class procedure TWarGatherWoodState.UpdateAll(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateWood;
  LSlot: Integer;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_WOOD, LIndex] then
      Continue;
    LState := PWarStateWood(LContext.Storage.StateAt(WAR_STATE_WOOD, LIndex));
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
