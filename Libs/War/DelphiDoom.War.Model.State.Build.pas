{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the build state                                    }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_build.c, (c) 2019 Alejandro  }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Build;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   A building that is being built (the state of the building, not of the worker): it occupies its tiles and shows
  ///   the image of the construction, whose frames follow the percent that is done; the time runs only while a worker is
  ///   inside (the worker says so by setting WorkerId). When the time is over the worker comes out on the nearest empty
  ///   tile and the building takes its real image. A cancelled build gives the money back (once) and, if the building
  ///   was not finished, it collapses; the hurry up cheat makes the time run 100 times faster
  /// </summary>
  TWarBuildState = class
  strict private
    class procedure UpdateOne(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBuild); static;
  public
    /// <summary>wst_createBuildState: the cost is the one that was paid (no new charge)</summary>
    class function CreateState(AMachine: TWarStateMachine; ASlot: Integer; ABuildTime: Single;
      AGoldCost, AWoodCost: Integer): PWarStateBuild; static;
    /// <summary>wst_enterBuildState</summary>
    class procedure Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase); static;
    /// <summary>wst_exitBuildState</summary>
    class procedure Leave(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase; AReason: Integer); static;
    /// <summary>wst_updateBuildStates</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.Math,
  DelphiDoom.War.Model.ActionTable, DelphiDoom.War.Model.UnitPlacement, DelphiDoom.War.Model.Purse,
  DelphiDoom.War.Model.Construction.Types, DelphiDoom.War.Model.StateStorage;

{ TWarBuildState }

class function TWarBuildState.CreateState(AMachine: TWarStateMachine; ASlot: Integer; ABuildTime: Single;
  AGoldCost, AWoodCost: Integer): PWarStateBuild;
begin
  // the state machine makes it (the entity manager creates a building to be built with it): the cost is marked as paid
  Result := PWarStateBuild(AMachine.CreateBuild(ASlot, ABuildTime, AGoldCost, AWoodCost));
end;

class procedure TWarBuildState.Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LPosition: TWarVec2;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LPosition := TWarModelMath.MapToTile(LEntity^.Position);
  LContext.Occupancy.SetStaticEntity(Trunc(LPosition.X), Trunc(LPosition.Y), LEntity^.UnitData.SizeX,
    LEntity^.UnitData.SizeY, LEntity^.Id);
  // the image of the construction in place of the one of the building
  LEntity^.HasSprite := True;
  LEntity^.SpriteEnabled := True;
  LEntity^.SpriteFrames := LContext.ConstructionHost.ConstructionFrames(LEntity^.UnitData.UnitType);
  LEntity^.SpriteFrame := 0;
  TWarActionTable.SetAction(LEntity^.UnitData, WAR_ACTION_NONE, True, 1.0);
  LEntity^.UnitData.Building := True;
  LEntity^.UnitData.BuildPercent := 0;
end;

class procedure TWarBuildState.Leave(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase;
  AReason: Integer);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LBuild: PWarStateBuild;
  LPosition: TWarVec2;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LBuild := PWarStateBuild(AState);
  if LBuild^.Cancelled and LBuild^.TransactionApplied and not LBuild^.OutputCommitted and
    not LBuild^.AlreadyRefunded then
  begin
    LBuild^.AlreadyRefunded := True;
    TWarPurse.Increase(LContext.Players[LEntity^.UnitData.Player], LBuild^.GoldCost, LBuild^.WoodCost);
  end;
  if LBuild^.Cancelled and not LBuild^.OutputCommitted then
    LContext.ConstructionHost.PlayRandomSound(WAR_SOUND_BUILDING_COLLAPSE_1, WAR_SOUND_BUILDING_COLLAPSE_3);
  LPosition := TWarModelMath.MapToTile(LEntity^.Position);
  LContext.Occupancy.SetFreeTiles(Trunc(LPosition.X), Trunc(LPosition.Y), LEntity^.UnitData.SizeX,
    LEntity^.UnitData.SizeY);
  LEntity^.UnitData.Building := False;
end;

class procedure TWarBuildState.UpdateOne(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBuild);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LUnit: PWarUnitComponent;
  LCollapse: PWarStateBase;
  LWorker: Integer;
  LSpeed: Single;
  LFrames: Integer;
  LFrame: Integer;
  LStep: Single;
  LThreshold: Single;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LUnit := @LEntity^.UnitData;
  if AState^.OutputCommitted then
  begin
    AMachine.PopState(ASlot, WAR_CAUSE_COMPLETION, WAR_RESULT_SUCCESS);
    Exit;
  end;
  if AState^.Cancelled then
  begin
    if LEntity^.StateMachine.Depth > 1 then
      AMachine.PopState(ASlot, WAR_CAUSE_COMPLETION, WAR_RESULT_CANCELLED)
    else
    begin
      LCollapse := AMachine.CreateCollapse(ASlot);
      AMachine.ReplaceState(ASlot, LCollapse, WAR_CAUSE_LIFECYCLE);
    end;
    Exit;
  end;
  // nobody is working on it
  if AState^.WorkerId = 0 then
    Exit;
  LWorker := LContext.Pool.FindSlot(AState^.WorkerId);
  if LWorker = 0 then
  begin
    AState^.WorkerId := 0;
    Exit;
  end;
  LSpeed := LContext.Clock^.DeltaTime;
  if LContext.HurryUp then
    LSpeed := LSpeed * WAR_MODEL_HURRY_UP_FACTOR;
  AState^.BuildTime := AState^.BuildTime + LSpeed;
  if AState^.BuildTime >= AState^.TotalBuildTime then
  begin
    LUnit^.BuildPercent := 1;
    AState^.OutputCommitted := True;
    // the worker comes out on the nearest empty tile
    TWarUnitPlacement.PlaceNear(LContext, LEntity, LContext.Pool.Slots[LWorker]);
    // the building takes its own image
    LEntity^.HasSprite := True;
    LEntity^.SpriteEnabled := True;
    LEntity^.SpriteFrames := LContext.ConstructionHost.UnitFrames(LUnit^.UnitType);
    LEntity^.SpriteFrame := 0;
    AMachine.PopState(ASlot, WAR_CAUSE_COMPLETION, WAR_RESULT_SUCCESS);
    if LUnit^.Player = 0 then
    begin
      if LContext.Players[0]^.Race = wraHumans then
        LContext.ConstructionHost.PlaySound(WAR_SOUND_HUMAN_WORK_COMPLETE)
      else
        LContext.ConstructionHost.PlaySound(WAR_SOUND_ORC_WORK_COMPLETE);
    end;
    Exit;
  end;
  LUnit^.BuildPercent := AState^.BuildTime / AState^.TotalBuildTime;
  // the image of the building shows the steps of the construction
  LFrames := LEntity^.SpriteFrames;
  LFrame := LEntity^.SpriteFrame;
  if LFrames > 0 then
  begin
    // 1.0f / framesCount: with no frames the original divides by zero and gets infinity, which no percent reaches
    LStep := 1.0 / LFrames;
    LThreshold := (LFrame + 1) * LStep;
    if LUnit^.BuildPercent >= LThreshold then
      if LFrame + 1 < LFrames then
        Inc(LFrame);
  end;
  LEntity^.SpriteFrame := LFrame;
end;

class procedure TWarBuildState.UpdateAll(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateBase;
  LSlot: Integer;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_BUILD, LIndex] then
      Continue;
    LState := LContext.Storage.StateAt(WAR_STATE_BUILD, LIndex);
    LSlot := LContext.Pool.FindSlot(LState^.EntityId);
    if LSlot = 0 then
      Continue;
    if AMachine.ActiveState(LSlot) <> LState then
      Continue;
    if not AMachine.IsNextUpdateTime(LState) then
      Continue;
    UpdateOne(AMachine, LSlot, PWarStateBuild(LState));
  end;
end;

end.
