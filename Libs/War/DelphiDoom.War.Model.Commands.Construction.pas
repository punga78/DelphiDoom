{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the orders of building, repairing and training     }
{                                                                              }
{  Port of war1 (acoto87/war1), war_commands.c (wcmd_tryPlaceBuilding,         }
{  wcmd_executeRepairCommand, wcmd_cancel and the cases of training,           }
{  upgrading and walls of wcmd_executeCommand) and we_checkRectToBuild of      }
{  war_entities.c, (c) 2019 Alejandro Coto Gutierrez, zlib License (see        }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Commands.Construction;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Model.Economy;

type
  /// <summary>
  ///   What the player (or a script, or the AI) orders about building: where a building can go and putting it there,
  ///   sending workers to repair, training a unit, researching an upgrade, cancelling what a building is doing, putting
  ///   a piece of wall. Everything is by slot of the pool; the choice of the tile with the mouse, the selection and the
  ///   buttons are the interface's business. The orders that the state of the unit does not accept (see the masks of the
  ///   states) are ignored, as the original does
  /// </summary>
  TWarConstructionCommands = class
  strict private
    FContext: TWarModelContext;
    FMachine: TWarStateMachine;
    FEconomy: TWarEconomy;
    FRejectOverbookedUpgrades: Boolean;


  public
    constructor Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine;
      const AEconomy: TWarEconomy);
    /// <summary>
    ///   we_checkRectToBuild: every tile of the rectangle that is in the map is empty and known (a tile outside the map does not
    ///   count: the original skips it)
    /// </summary>
    function CheckRectToBuild(ATileX, ATileY, AWidth, AHeight: Integer): Boolean;
    /// <summary>we_checkTileToBuild: the same for a building of the type; the status bar says "can't build there" if it fails</summary>
    function CheckTileToBuild(ABuildingType, ATileX, ATileY: Integer): Boolean;
    /// <summary>
    ///   The command of a building at a tile (the case BUILD_* of wcmd_executeCommand after the click): if the building does
    ///   not fit, a sound of cancel; otherwise (wcmd_tryPlaceBuilding) the worker must accept orders, the cost is charged, the
    ///   building is made with the state of its construction and the worker gets the order to repair it (and so to build it). If any
    ///   step fails nothing is left: the money comes back and the building goes away
    /// </summary>
    function PlaceBuilding(AWorkerSlot, ABuildingType, ATileX, ATileY: Integer): Boolean;
    /// <summary>
    ///   wcmd_tryPlaceBuilding alone, for a tile that was checked already (PlaceBuilding is the check, the sound of cancel and this)
    /// </summary>
    function TryPlaceBuilding(AWorkerSlot, ABuildingType, ATileX, ATileY: Integer): Boolean;
    /// <summary>
    ///   How many researches of the pair of upgrades (AUpgrade div 2: arrows and spears, swords and axes, horses and wolves) the units
    ///   of the player have going or waiting to start, on the stack of their states or as a request, not counting the cancelled
    ///   ones
    /// </summary>
    function UpgradesInProgress(APlayer, APair: Integer): Integer;
    /// <summary>
    ///   wcmd_executeRepairCommand for the workers of the player 0 that are given: those that accept the order, belong to the
    ///   owner of the target, are workers and are not the target itself repair it; the acknowledgement is said once if any
    ///   of them does. True if one does
    /// </summary>
    function OrderRepair(const AWorkerSlots: array of Integer; ATargetSlot: Integer): Boolean;
    /// <summary>
    ///   The case TRAIN_* of wcmd_executeCommand: if the building accepts the order, there is room for one more unit in the
    ///   farms (with the message otherwise) and the owner can pay, the training starts. True if it does
    /// </summary>
    function OrderTrain(ABuildingSlot, AUnitType: Integer): Boolean; overload;
    /// <summary>
    ///   The same order with its cause: WAR_CAUSE_AI_ORDER is the training that the computer orders (war_ai.c), which
    ///   interrupts what WAR_INTERRUPT_AI_ORDER can
    /// </summary>
    function OrderTrain(ABuildingSlot, AUnitType, ACause: Integer): Boolean; overload;
    /// <summary>
    ///   The case BUILD_ROAD of wcmd_executeCommand after the click: as PlaceWall, with the cost of a road and a piece of
    ///   the road of the context (of the player 0, as in the original). True if it was built
    /// </summary>
    function PlaceRoad(APlayer, ATileX, ATileY: Integer): Boolean;
    /// <summary>
    ///   The case UPGRADE_* of wcmd_executeCommand: the cost is the one of the level that the player has now. The
    ///   upgrades of a pair (arrows and spears, swords and axes, ...) share a level, so two of them in progress at once would
    ///   push it over the maximum (the original stops on an assert when the second ends): with RejectOverbookedUpgrades
    ///   (the default) the order that would do so is refused. An upgrade that the player has at the maximum is refused (the original
    ///   asserts too). True if the research starts
    /// </summary>
    function OrderUpgrade(ABuildingSlot, AUpgrade: Integer): Boolean;
    /// <summary>
    ///   wcmd_cancel for one entity: a building that is being built collapses (and gives the money back, since it was not
    ///   finished), one that trains or researches goes idle (with the money back). Nothing for the rest. True if an order was given
    /// </summary>
    function Cancel(ABuildingSlot: Integer): Boolean;
    /// <summary>
    ///   The case BUILD_WALL of wcmd_executeCommand after the click: the tile must be free (the status bar says
    ///   otherwise), the player pays and the piece is put there with all its hit points, its type decided by its neighbors, and
    ///   a sound. The piece belongs to the player 0, as in the original. True if it was built
    /// </summary>
    function PlaceWall(APlayer, ATileX, ATileY: Integer): Boolean;
    /// <summary>
    ///   See OrderUpgrade. Default True. With False the orders are accepted as in the original, and the second upgrade of
    ///   a pair that ends over the maximum is EWarException
    /// </summary>
    property RejectOverbookedUpgrades: Boolean read FRejectOverbookedUpgrades write FRejectOverbookedUpgrades;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.Stats.Types, DelphiDoom.War.Model.StateStorage,
  DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.Construction.Types,
  DelphiDoom.War.Model.State.Train, DelphiDoom.War.Model.State.Upgrade, DelphiDoom.War.Model.State.Repair,
  DelphiDoom.War.Model.State.Collapse, DelphiDoom.War.Model.Commands.Types;

{ TWarConstructionCommands }

constructor TWarConstructionCommands.Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine;
  const AEconomy: TWarEconomy);
begin
  inherited Create;
  FContext := AContext;
  FMachine := AMachine;
  FEconomy := AEconomy;
  FRejectOverbookedUpgrades := True;
end;

function TWarConstructionCommands.CheckRectToBuild(ATileX, ATileY, AWidth, AHeight: Integer): Boolean;
var
  LDeltaX: Integer;
  LDeltaY: Integer;
  LX: Integer;
  LY: Integer;
begin
  for LDeltaY := 0 to AHeight - 1 do
    for LDeltaX := 0 to AWidth - 1 do
    begin
      LX := ATileX + LDeltaX;
      LY := ATileY + LDeltaY;
      if (LX >= 0) and (LX < WAR_MAP_TILES_WIDTH) and (LY >= 0) and (LY < WAR_MAP_TILES_HEIGHT) then
        if (not FContext.Probe.IsEmpty(LX, LY)) or (not FContext.ConstructionHost.IsTileKnown(LX, LY)) then
          Exit(False);
    end;
  Result := True;
end;

function TWarConstructionCommands.CheckTileToBuild(ABuildingType, ATileX, ATileY: Integer): Boolean;
var
  LSizeX: Integer;
  LSizeY: Integer;
begin
  if not FContext.Database.TryGetUnitSize(ABuildingType, LSizeX, LSizeY) then
    raise EWarException.CreateFmt(SWarModelNoUnitData, [ABuildingType]);
  Result := CheckRectToBuild(ATileX, ATileY, LSizeX, LSizeY);
  if not Result then
    FContext.Events.FlashStatus(wsmCantBuildThere);
end;

function TWarConstructionCommands.TryPlaceBuilding(AWorkerSlot, ABuildingType, ATileX, ATileY: Integer): Boolean;
var
  LPlayer: PWarPlayerInfo;
  LStats: TWarBuildingStatsFull;
  LBuilding: Integer;
  LRepair: PWarStateRepair;
begin
  Result := False;
  if not FMachine.CanSubmitTransition(AWorkerSlot, WAR_INTERRUPT_PLAYER_ORDER) then
    Exit;
  LPlayer := FContext.Players[FContext.Pool.Slots[AWorkerSlot]^.UnitData.Player];
  LStats := FContext.Database.GetBuildingStats(ABuildingType);
  if not FEconomy.DecreaseResources(LPlayer, LStats.GoldCost, LStats.WoodCost) then
    Exit;
  LBuilding := FContext.Entities.CreateBuilding(ABuildingType, ATileX, ATileY, LPlayer^.Index, True);
  if LBuilding = 0 then
  begin
    FEconomy.IncreaseResources(LPlayer, LStats.GoldCost, LStats.WoodCost);
    Exit;
  end;
  LRepair := TWarRepairState.CreateState(FMachine, AWorkerSlot, FContext.Pool.Slots[LBuilding]^.Id);
  if (not Assigned(LRepair)) or (not FMachine.ResetState(AWorkerSlot, PWarStateBase(LRepair), WAR_CAUSE_PLAYER_ORDER)) then
  begin
    FContext.Entities.RemoveEntity(LBuilding);
    FEconomy.IncreaseResources(LPlayer, LStats.GoldCost, LStats.WoodCost);
    Exit;
  end;
  Result := True;
end;

function TWarConstructionCommands.PlaceBuilding(AWorkerSlot, ABuildingType, ATileX, ATileY: Integer): Boolean;
begin
  if not CheckTileToBuild(ABuildingType, ATileX, ATileY) then
  begin
    FContext.ConstructionHost.PlaySound(WAR_SOUND_UI_CANCEL);
    Exit(False);
  end;
  Result := TryPlaceBuilding(AWorkerSlot, ABuildingType, ATileX, ATileY);
end;

function TWarConstructionCommands.OrderRepair(const AWorkerSlots: array of Integer; ATargetSlot: Integer): Boolean;
var
  LIndex: Integer;
  LSlot: Integer;
  LUnit: PWarUnitComponent;
  LTarget: PWarEntity;
  LRepair: PWarStateRepair;
  LPlayer: Integer;
begin
  Result := False;
  LPlayer := -1;
  LTarget := FContext.Pool.Slots[ATargetSlot];
  for LIndex := 0 to High(AWorkerSlots) do
  begin
    LSlot := AWorkerSlots[LIndex];
    LUnit := @FContext.Pool.Slots[LSlot]^.UnitData;
    // wu_isFriendlyUnit: it belongs to the player 0; the repair is of the buildings of the same owner
    if (LUnit^.Player = FContext.Players[0]^.Index) and
      FMachine.CanSubmitTransition(LSlot, WAR_INTERRUPT_PLAYER_ORDER) and (LUnit^.Player = LTarget^.UnitData.Player) then
    begin
      // a unit can not repair itself
      if LSlot = ATargetSlot then
        Continue;
      if TWarUnitClassifier.IsWorker(LUnit^.UnitType) then
      begin
        LRepair := TWarRepairState.CreateState(FMachine, LSlot, LTarget^.Id);
        FMachine.ResetState(LSlot, PWarStateBase(LRepair), WAR_CAUSE_PLAYER_ORDER);
        if LPlayer < 0 then
          LPlayer := LUnit^.Player;
        Result := True;
      end;
    end;
  end;
  if Result then
    FContext.ConstructionHost.Acknowledge(LPlayer);
end;

function TWarConstructionCommands.OrderTrain(ABuildingSlot, AUnitType: Integer): Boolean;
begin
  Result := OrderTrain(ABuildingSlot, AUnitType, WAR_CAUSE_PLAYER_ORDER);
end;

function TWarConstructionCommands.PlaceRoad(APlayer, ATileX, ATileY: Integer): Boolean;
begin
  Result := False;
  if CheckRectToBuild(ATileX, ATileY, 1, 1) then
  begin
    if FEconomy.DecreaseResources(FContext.Players[APlayer], WAR_ROAD_GOLD_COST, WAR_ROAD_WOOD_COST) then
    begin
      // the piece is of the player 0 whoever builds it (we_addRoadPiece(context, road, x, y, 0))
      FContext.Roads.AddPiece(ATileX, ATileY, 0);
      FContext.Roads.DetermineTypes;
      FContext.ConstructionHost.PlaySound(WAR_SOUND_BUILD_ROAD);
      Result := True;
    end;
  end
  else
  begin
    FContext.Events.FlashStatus(wsmCantBuildThere);
    FContext.ConstructionHost.PlaySound(WAR_SOUND_UI_CANCEL);
  end;
end;

function TWarConstructionCommands.OrderTrain(ABuildingSlot, AUnitType, ACause: Integer): Boolean;
var
  LPlayer: PWarPlayerInfo;
  LStats: TWarUnitStatsFull;
  LTrain: PWarStateTrain;
  LInterrupt: Integer;
begin
  Result := False;
  if ACause = WAR_CAUSE_AI_ORDER then
    LInterrupt := WAR_INTERRUPT_AI_ORDER
  else
    LInterrupt := WAR_INTERRUPT_PLAYER_ORDER;
  if not FMachine.CanSubmitTransition(ABuildingSlot, LInterrupt) then
    Exit;
  LPlayer := FContext.Players[FContext.Pool.Slots[ABuildingSlot]^.UnitData.Player];
  LStats := FContext.Database.GetUnitStats(AUnitType);
  if FEconomy.CheckFarmFood(LPlayer) and FEconomy.EnoughResources(LPlayer, LStats.GoldCost, LStats.WoodCost) then
  begin
    LTrain := TWarTrainState.CreateState(FMachine, ABuildingSlot, AUnitType, LStats.BuildTime, LStats.GoldCost,
      LStats.WoodCost);
    Result := FMachine.ResetState(ABuildingSlot, PWarStateBase(LTrain), ACause);
  end;
end;

function TWarConstructionCommands.UpgradesInProgress(APlayer, APair: Integer): Integer;
var
  LSlot: Integer;
  LEntity: PWarEntity;
  LMachine: PWarStateMachineComponent;
  LDepth: Integer;
  LState: PWarStateBase;
begin
  Result := 0;
  for LSlot := 1 to WAR_MODEL_MAX_ENTITIES - 1 do
  begin
    LEntity := FContext.Pool.Slots[LSlot];
    if (LEntity^.Id = 0) or not LEntity^.HasStateMachine or not LEntity^.HasUnit or
      (LEntity^.UnitData.Player <> APlayer) then
      Continue;
    LMachine := @LEntity^.StateMachine;
    for LDepth := 0 to LMachine^.Depth - 1 do
    begin
      LState := FContext.Storage.Deref(LMachine^.Stack[LDepth]);
      if Assigned(LState) and (LState^.StateType = WAR_STATE_UPGRADE) and
        not PWarStateUpgrade(LState)^.Cancelled and (PWarStateUpgrade(LState)^.UpgradeToBuild div 2 = APair) then
        Inc(Result);
    end;
    if (LMachine^.Pending.Operation <> WAR_OP_NONE) and (LMachine^.Pending.StateRef.StateType = WAR_STATE_UPGRADE) then
    begin
      LState := FContext.Storage.Deref(LMachine^.Pending.StateRef);
      if Assigned(LState) and (PWarStateUpgrade(LState)^.UpgradeToBuild div 2 = APair) then
        Inc(Result);
    end;
  end;
end;

function TWarConstructionCommands.OrderUpgrade(ABuildingSlot, AUpgrade: Integer): Boolean;
var
  LPlayer: PWarPlayerInfo;
  LStats: TWarUpgradeStats;
  LLevel: Integer;
  LCost: Integer;
  LUpgrade: PWarStateUpgrade;
begin
  Result := False;
  if not FMachine.CanSubmitTransition(ABuildingSlot, WAR_INTERRUPT_PLAYER_ORDER) then
    Exit;
  LPlayer := FContext.Players[FContext.Pool.Slots[ABuildingSlot]^.UnitData.Player];
  LLevel := LPlayer^.Upgrades[AUpgrade div 2].Level;
  // no level left (the original asserts) or two orders for the same pair that would take it over the maximum
  if LLevel >= LPlayer^.Upgrades[AUpgrade div 2].Allowed then
    Exit;
  if FRejectOverbookedUpgrades and
    (LLevel + UpgradesInProgress(LPlayer^.Index, AUpgrade div 2) >= LPlayer^.Upgrades[AUpgrade div 2].Allowed) then
    Exit;
  LStats := FContext.Database.GetUpgradeStats(AUpgrade);
  // goldCost has two levels: the third one is not in the table
  if LLevel = 0 then
    LCost := LStats.GoldCost1
  else if LLevel = 1 then
    LCost := LStats.GoldCost2
  else
    Exit;
  if FEconomy.EnoughResources(LPlayer, LCost, 0) then
  begin
    LUpgrade := TWarUpgradeState.CreateState(FMachine, ABuildingSlot, AUpgrade, LStats.BuildTime, LCost, 0);
    Result := FMachine.ResetState(ABuildingSlot, PWarStateBase(LUpgrade), WAR_CAUSE_PLAYER_ORDER);
  end;
end;

function TWarConstructionCommands.Cancel(ABuildingSlot: Integer): Boolean;
var
  LUnit: PWarUnitComponent;
  LCollapse: PWarStateBase;
  LIdle: PWarStateIdle;
begin
  Result := False;
  LUnit := @FContext.Pool.Slots[ABuildingSlot]^.UnitData;
  if not TWarUnitClassifier.IsBuilding(LUnit^.UnitType) or
    not FMachine.CanSubmitTransition(ABuildingSlot, WAR_INTERRUPT_PLAYER_ORDER) then
    Exit;
  if FMachine.IsBuilding(ABuildingSlot) or FMachine.IsGoingToBuild(ABuildingSlot) then
  begin
    LCollapse := TWarCollapseState.CreateState(FMachine, ABuildingSlot);
    Result := FMachine.ResetStateForCancellation(ABuildingSlot, LCollapse, WAR_CAUSE_PLAYER_ORDER);
  end
  else if FMachine.Contains(ABuildingSlot, WAR_STATE_TRAIN) or FMachine.HasPending(ABuildingSlot, WAR_STATE_TRAIN) or
    FMachine.Contains(ABuildingSlot, WAR_STATE_UPGRADE) or FMachine.HasPending(ABuildingSlot, WAR_STATE_UPGRADE) then
  begin
    LIdle := FMachine.CreateIdle(ABuildingSlot, False);
    Result := FMachine.ResetStateForCancellation(ABuildingSlot, PWarStateBase(LIdle), WAR_CAUSE_PLAYER_ORDER);
  end;
end;

function TWarConstructionCommands.PlaceWall(APlayer, ATileX, ATileY: Integer): Boolean;
var
  LIndex: Integer;
  LPiece: PWarWallPiece;
begin
  Result := False;
  if CheckRectToBuild(ATileX, ATileY, 1, 1) then
  begin
    if FEconomy.DecreaseResources(FContext.Players[APlayer], WAR_WALL_GOLD_COST, WAR_WALL_WOOD_COST) then
    begin
      // the piece is of the player 0 whoever builds it (we_addWallPiece(context, wall, x, y, 0))
      LIndex := FContext.Walls.Add(ATileX, ATileY, 0);
      LPiece := FContext.Walls[LIndex];
      LPiece^.Hp := WAR_WALL_MAX_HP;
      LPiece^.MaxHp := WAR_WALL_MAX_HP;
      FContext.Walls.DetermineTypes;
      FContext.ConstructionHost.PlaySound(WAR_SOUND_BUILD_ROAD);
      Result := True;
    end;
  end
  else
  begin
    FContext.Events.FlashStatus(wsmCantBuildThere);
    FContext.ConstructionHost.PlaySound(WAR_SOUND_UI_CANCEL);
  end;
end;

end.
