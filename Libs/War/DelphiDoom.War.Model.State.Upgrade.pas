{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the upgrade state                                  }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_upgrade.c, (c) 2019          }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Upgrade;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   A building that researches an upgrade (swords, shields, a spell ...). Like the training: the cost is charged on
  ///   entering (and the state cancels itself if the player can not pay), the time runs at the speed of the clock, a
  ///   cancelled research gives the money back once. At the end the player's level of the upgrade goes up and the
  ///   units of the player change (TWarEconomy.IncreaseUpgradeLevel)
  /// </summary>
  TWarUpgradeState = class
  strict private
    class function ApplyTransaction(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateUpgrade): Boolean; static;
    class procedure UpdateOne(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateUpgrade); static;
  public
    /// <summary>wst_createUpgradeState: nothing is charged yet</summary>
    class function CreateState(AMachine: TWarStateMachine; ASlot: Integer; AUpgradeToBuild: Integer;
      ABuildTime: Single; AGoldCost, AWoodCost: Integer): PWarStateUpgrade; static;
    /// <summary>wst_enterUpgradeState</summary>
    class procedure Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase); static;
    /// <summary>wst_exitUpgradeState</summary>
    class procedure Leave(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase; AReason: Integer); static;
    /// <summary>wst_updateUpgradeStates</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.Economy, DelphiDoom.War.Model.Purse,
  DelphiDoom.War.Model.Construction.Types, DelphiDoom.War.Model.StateStorage;

{ TWarUpgradeState }

class function TWarUpgradeState.CreateState(AMachine: TWarStateMachine; ASlot: Integer; AUpgradeToBuild: Integer;
  ABuildTime: Single; AGoldCost, AWoodCost: Integer): PWarStateUpgrade;
begin
  Result := PWarStateUpgrade(AMachine.AllocState(ASlot, WAR_STATE_UPGRADE));
  if not Assigned(Result) then
    Exit;
  Result^.UpgradeToBuild := AUpgradeToBuild;
  Result^.BuildTime := 0;
  Result^.TotalBuildTime := ABuildTime;
  Result^.GoldCost := AGoldCost;
  Result^.WoodCost := AWoodCost;
  Result^.TransactionApplied := False;
  Result^.OutputCommitted := False;
  Result^.Cancelled := False;
  Result^.AlreadyRefunded := False;
end;

class function TWarUpgradeState.ApplyTransaction(AMachine: TWarStateMachine; ASlot: Integer;
  AState: PWarStateUpgrade): Boolean;
var
  LContext: TWarModelContext;
begin
  LContext := AMachine.Context;
  Result := TWarPurse.Decrease(LContext, LContext.Players[LContext.Pool.Slots[ASlot]^.UnitData.Player],
    AState^.GoldCost, AState^.WoodCost);
  if Result then
    AState^.TransactionApplied := True;
end;

class procedure TWarUpgradeState.Enter(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LUpgrade: PWarStateUpgrade;
  LPosition: TWarVec2;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LUpgrade := PWarStateUpgrade(AState);
  if not ApplyTransaction(AMachine, ASlot, LUpgrade) then
  begin
    LUpgrade^.Cancelled := True;
    AMachine.PopState(ASlot, WAR_CAUSE_COMPLETION, WAR_RESULT_CANCELLED);
    Exit;
  end;
  LPosition := TWarModelMath.MapToTile(LEntity^.Position);
  LContext.Occupancy.SetStaticEntity(Trunc(LPosition.X), Trunc(LPosition.Y), LEntity^.UnitData.SizeX,
    LEntity^.UnitData.SizeY, LEntity^.Id);
  LEntity^.UnitData.Building := True;
  LEntity^.UnitData.BuildPercent := 0;
end;

class procedure TWarUpgradeState.Leave(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateBase;
  AReason: Integer);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LUpgrade: PWarStateUpgrade;
  LPosition: TWarVec2;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LUpgrade := PWarStateUpgrade(AState);
  if LUpgrade^.Cancelled and LUpgrade^.TransactionApplied and not LUpgrade^.OutputCommitted and
    not LUpgrade^.AlreadyRefunded then
  begin
    LUpgrade^.AlreadyRefunded := True;
    TWarPurse.Increase(LContext.Players[LEntity^.UnitData.Player], LUpgrade^.GoldCost, LUpgrade^.WoodCost);
  end;
  if not LUpgrade^.TransactionApplied then
    Exit;
  LPosition := TWarModelMath.MapToTile(LEntity^.Position);
  LContext.Occupancy.SetFreeTiles(Trunc(LPosition.X), Trunc(LPosition.Y), LEntity^.UnitData.SizeX,
    LEntity^.UnitData.SizeY);
  LEntity^.UnitData.Building := False;
end;

class procedure TWarUpgradeState.UpdateOne(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateUpgrade);
var
  LContext: TWarModelContext;
  LUnit: PWarUnitComponent;
  LPlayer: PWarPlayerInfo;
  LSpeed: Single;
  LEconomy: TWarEconomy;
begin
  LContext := AMachine.Context;
  LUnit := @LContext.Pool.Slots[ASlot]^.UnitData;
  LPlayer := LContext.Players[LUnit^.Player];
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
    // the economy has no state of its own: one made for the call does what the one of the world does
    LEconomy := TWarEconomy.Create(LContext, LContext.Queries);
    try
      LEconomy.IncreaseUpgradeLevel(LPlayer, AState^.UpgradeToBuild);
    finally
      LEconomy.Free;
    end;
    AState^.OutputCommitted := True;
    AMachine.PopState(ASlot, WAR_CAUSE_COMPLETION, WAR_RESULT_SUCCESS);
    Exit;
  end;
  LUnit^.BuildPercent := AState^.BuildTime / AState^.TotalBuildTime;
end;

class procedure TWarUpgradeState.UpdateAll(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateBase;
  LSlot: Integer;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_UPGRADE, LIndex] then
      Continue;
    LState := LContext.Storage.StateAt(WAR_STATE_UPGRADE, LIndex);
    LSlot := LContext.Pool.FindSlot(LState^.EntityId);
    if LSlot = 0 then
      Continue;
    if AMachine.ActiveState(LSlot) <> LState then
      Continue;
    if not AMachine.IsNextUpdateTime(LState) then
      Continue;
    UpdateOne(AMachine, LSlot, PWarStateUpgrade(LState));
  end;
end;

end.
