{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the train state                                    }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_train.c, (c) 2019 Alejandro  }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Train;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   A building that trains a unit. The cost is charged when the state is entered (if the player can not pay any more
  ///   the state cancels itself); the time runs at the speed of the clock (100 times faster with the hurry up
  ///   cheat); at the end the unit appears on the nearest empty tile and the building says so with the voice of its race. A
  ///   cancelled training gives the money back, once. The AI request that the original keeps in the state is not here
  ///   (the AI is not ported)
  /// </summary>
  TWarTrainState = class
  strict private
    class function ApplyTransaction(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateTrain): Boolean; static;
    class procedure UpdateOne(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateTrain); static;
  public
    /// <summary>wst_createTrainState: nothing is charged yet</summary>
    class function CreateState(AMachine: TWarStateMachine; ASlot: Integer; AUnitToBuild: Integer; ABuildTime: Single;
      AGoldCost, AWoodCost: Integer): PWarStateTrain; static;
    /// <summary>wst_enterTrainState</summary>
    class procedure Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase); static;
    /// <summary>wst_exitTrainState</summary>
    class procedure Leave(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase; AReason: Integer); static;
    /// <summary>wst_updateTrainStates</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.Math,
  DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitPlacement, DelphiDoom.War.Model.Purse,
  DelphiDoom.War.Model.Construction.Types, DelphiDoom.War.Model.StateStorage;

{ TWarTrainState }

class function TWarTrainState.CreateState(AMachine: TWarStateMachine; ASlot: Integer; AUnitToBuild: Integer;
  ABuildTime: Single; AGoldCost, AWoodCost: Integer): PWarStateTrain;
begin
  Result := PWarStateTrain(AMachine.AllocState(ASlot, WAR_STATE_TRAIN));
  if not Assigned(Result) then
    Exit;
  Result^.UnitToBuild := AUnitToBuild;
  Result^.BuildTime := 0;
  Result^.TotalBuildTime := ABuildTime;
  Result^.GoldCost := AGoldCost;
  Result^.WoodCost := AWoodCost;
  Result^.TransactionApplied := False;
  Result^.OutputCommitted := False;
  Result^.Cancelled := False;
  Result^.AlreadyRefunded := False;
end;

class function TWarTrainState.ApplyTransaction(AMachine: TWarStateMachine; ASlot: Integer;
  AState: PWarStateTrain): Boolean;
var
  LContext: TWarModelContext;
begin
  LContext := AMachine.Context;
  Result := TWarPurse.Decrease(LContext, LContext.Players[LContext.Pool.Slots[ASlot]^.UnitData.Player],
    AState^.GoldCost, AState^.WoodCost);
  if Result then
    AState^.TransactionApplied := True;
end;

class procedure TWarTrainState.Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LTrain: PWarStateTrain;
  LPosition: TWarVec2;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LTrain := PWarStateTrain(AState);
  // the player can not pay any more: the training is cancelled at once
  if not ApplyTransaction(AMachine, ASlot, LTrain) then
  begin
    LTrain^.Cancelled := True;
    AMachine.PopState(ASlot, WAR_CAUSE_COMPLETION, WAR_RESULT_CANCELLED);
    Exit;
  end;
  LPosition := TWarModelMath.MapToTile(LEntity^.Position);
  LContext.Occupancy.SetStaticEntity(Trunc(LPosition.X), Trunc(LPosition.Y), LEntity^.UnitData.SizeX,
    LEntity^.UnitData.SizeY, LEntity^.Id);
  LEntity^.UnitData.Building := True;
  LEntity^.UnitData.BuildPercent := 0;
end;

class procedure TWarTrainState.Leave(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase;
  AReason: Integer);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LTrain: PWarStateTrain;
  LPosition: TWarVec2;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LTrain := PWarStateTrain(AState);
  if LTrain^.Cancelled and LTrain^.TransactionApplied and not LTrain^.OutputCommitted and
    not LTrain^.AlreadyRefunded then
  begin
    LTrain^.AlreadyRefunded := True;
    TWarPurse.Increase(LContext.Players[LEntity^.UnitData.Player], LTrain^.GoldCost, LTrain^.WoodCost);
  end;
  // a state that never paid never took the tiles
  if not LTrain^.TransactionApplied then
    Exit;
  LPosition := TWarModelMath.MapToTile(LEntity^.Position);
  LContext.Occupancy.SetFreeTiles(Trunc(LPosition.X), Trunc(LPosition.Y), LEntity^.UnitData.SizeX,
    LEntity^.UnitData.SizeY);
  LEntity^.UnitData.Building := False;
end;

class procedure TWarTrainState.UpdateOne(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateTrain);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LUnit: PWarUnitComponent;
  LSpeed: Single;
  LNew: Integer;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LUnit := @LEntity^.UnitData;
  if AState^.Cancelled then
  begin
    AMachine.PopState(ASlot, WAR_CAUSE_COMPLETION, WAR_RESULT_CANCELLED);
    Exit;
  end;
  if AState^.OutputCommitted then
    Exit;
  LSpeed := LContext.Clock^.DeltaTime;
  if LContext.HurryUp then
    LSpeed := LSpeed * WAR_MODEL_HURRY_UP_FACTOR;
  AState^.BuildTime := AState^.BuildTime + LSpeed;
  if AState^.BuildTime >= AState^.TotalBuildTime then
  begin
    LUnit^.BuildPercent := 1;
    LNew := LContext.Entities.CreateDude(AState^.UnitToBuild, 0, 0, LUnit^.Player, False);
    // the pool is full (the original would use a null pointer): the unit is made at the next update
    if LNew = 0 then
      Exit;
    TWarUnitPlacement.PlaceNear(LContext, LEntity, LContext.Pool.Slots[LNew]);
    LContext.Entities.SetInitialIdle(LNew);
    AState^.OutputCommitted := True;
    AMachine.PopState(ASlot, WAR_CAUSE_COMPLETION, WAR_RESULT_SUCCESS);
    if LUnit^.Player = 0 then
    begin
      if TWarUnitClassifier.RaceOf(LContext.Pool.Slots[LNew]^.UnitData.UnitType) = wraHumans then
        LContext.ConstructionHost.PlaySound(WAR_SOUND_HUMAN_READY)
      else
        LContext.ConstructionHost.PlaySound(WAR_SOUND_ORC_READY);
    end;
    Exit;
  end;
  LUnit^.BuildPercent := AState^.BuildTime / AState^.TotalBuildTime;
end;

class procedure TWarTrainState.UpdateAll(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateBase;
  LSlot: Integer;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_TRAIN, LIndex] then
      Continue;
    LState := LContext.Storage.StateAt(WAR_STATE_TRAIN, LIndex);
    LSlot := LContext.Pool.FindSlot(LState^.EntityId);
    if LSlot = 0 then
      Continue;
    if AMachine.ActiveState(LSlot) <> LState then
      Continue;
    if not AMachine.IsNextUpdateTime(LState) then
      Continue;
    UpdateOne(AMachine, LSlot, PWarStateTrain(LState));
  end;
end;

end.
