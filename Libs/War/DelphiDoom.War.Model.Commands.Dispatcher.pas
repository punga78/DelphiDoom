{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the commands of a player                          }
{                                                                              }
{  Port of war1 (acoto87/war1), wcmd_executeCommand, wcmd_cancel and the       }
{  wcmd_train*, wcmd_upgrade* and wcmd_build* tables of war_commands.c, and    }
{  updateCommandFromRightClick of war_map.c, (c) 2019 Alejandro Coto           }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Commands.Dispatcher;

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine,
  DelphiDoom.War.Model.Economy, DelphiDoom.War.Model.Commands.Types, DelphiDoom.War.Model.Commands.Intf,
  DelphiDoom.War.Model.Commands.Family, DelphiDoom.War.Model.Commands.Movement,
  DelphiDoom.War.Model.Commands.Attack, DelphiDoom.War.Model.Commands.Gather,
  DelphiDoom.War.Model.Commands.Spells, DelphiDoom.War.Model.Commands.Construction,
  DelphiDoom.War.Model.Commands.Selection;

type
  /// <summary>What executes a type of command; a family of commands gives one for each type it knows</summary>
  TWarCommandHandler = function(const ACommand: TWarCommand): TWarCommandOutcome of object;

  /// <summary>
  ///   The orders of one commander (the player, or a computer player: issue #196 gives its orders through the same
  ///   class) to its selection: a registry from the type of the command to the family that executes it (no big case:
  ///   RegisterHandler adds or replaces a type), with the lookup of the target under the point that the original does
  ///   in wcmd_executeCommand and updateCommandFromRightClick. There is no mouse, no button and no panel here: a command
  ///   that waits for a click is executed when the click is known (the point is in the command). Created by
  ///   TWarModelFactory.CreateCommands; it owns its families
  /// </summary>
  TWarCommands = class
  strict private
    FContext: TWarModelContext;
    FMachine: TWarStateMachine;
    FCommander: TWarCommander;
    FMap: IWarCommandMap;
    FMovement: TWarMovementCommands;
    FAttack: TWarAttackCommands;
    FGather: TWarGatherCommands;
    FSpells: TWarSpellCommands;
    FConstruction: TWarConstructionCommands;
    FSelecting: TWarSelectionCommands;
    FHandlers: array[0..WAR_COMMAND_COUNT - 1] of TWarCommandHandler;
    function TargetSlotAt(const ATarget: TWarVec2; out ATileX, ATileY: Integer): Integer;
    function IsUnknown(ASlot: Integer): Boolean;
    function IsEnemy(ASlot: Integer): Boolean;
    function SingleBuilding(ACommandType: Integer): Integer;
    function FirstSelected(ACommandType: Integer): Integer;
    function HarvestAt(const ATarget: TWarVec2; AQueue, AVisibleOnly: Boolean; ATargetSlot, ATileX,
      ATileY: Integer): Boolean;
    function DoMove(const ACommand: TWarCommand): TWarCommandOutcome;
    function DoStop(const ACommand: TWarCommand): TWarCommandOutcome;
    function DoHarvest(const ACommand: TWarCommand): TWarCommandOutcome;
    function DoDeliver(const ACommand: TWarCommand): TWarCommandOutcome;
    function DoRepair(const ACommand: TWarCommand): TWarCommandOutcome;
    function DoAttack(const ACommand: TWarCommand): TWarCommandOutcome;
    function DoTrain(const ACommand: TWarCommand): TWarCommandOutcome;
    function DoUpgrade(const ACommand: TWarCommand): TWarCommandOutcome;
    function DoBuild(const ACommand: TWarCommand): TWarCommandOutcome;
    function DoBuildWall(const ACommand: TWarCommand): TWarCommandOutcome;
    function DoBuildRoad(const ACommand: TWarCommand): TWarCommandOutcome;
    function DoSummon(const ACommand: TWarCommand): TWarCommandOutcome;
    function DoSpell(const ACommand: TWarCommand): TWarCommandOutcome;
    function DoCancel(const ACommand: TWarCommand): TWarCommandOutcome;
    function DoNothing(const ACommand: TWarCommand): TWarCommandOutcome;
  public
    /// <summary>The map tells who stands on a tile and what the player sees (nil: nobody, everything)</summary>
    constructor Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine;
      const AEconomy: TWarEconomy; const ACommander: TWarCommander; const AMap: IWarCommandMap);
    destructor Destroy; override;
    /// <summary>Sets who executes a type of command; EWarException for a type that does not exist</summary>
    procedure RegisterHandler(ACommandType: Integer; const AHandler: TWarCommandHandler);
    /// <summary>
    ///   wcmd_executeCommand once the click of the command is known. wcoNotExecuted for the two menus of the buildings
    ///   and for no command; EWarException for a type that does not exist (the original logs an error) or a selection
    ///   that the command can not have (an assert of the original)
    /// </summary>
    function Execute(const ACommand: TWarCommand): TWarCommandOutcome; overload;
    function Execute(ACommandType: Integer): TWarCommandOutcome; overload;
    function Execute(ACommandType: Integer; const ATarget: TWarVec2; AQueue: Boolean = False): TWarCommandOutcome; overload;
    /// <summary>
    ///   updateCommandFromRightClick with no command pending: the order that fits what is under the point (harvest a mine
    ///   or a tree, deliver to an own town hall, attack an enemy, follow a friend, move). False with no selection
    /// </summary>
    function RightClick(const ATarget: TWarVec2; AQueue: Boolean = False): Boolean;
    /// <summary>wcmd_cancel: every selected building stops what it builds, trains or researches</summary>
    function Cancel: Boolean;
    /// <summary>The unit that a train command trains and the building that trains it; False if it is not a train command</summary>
    class function TrainOf(ACommandType: Integer; out AUnitType, ABuildingType: Integer): Boolean; static;
    /// <summary>The upgrade of an upgrade command (-1 if it is not one) and the building of a build command (-1)</summary>
    class function UpgradeOf(ACommandType: Integer): Integer; static;
    class function BuildingOf(ACommandType: Integer): Integer; static;
    property Commander: TWarCommander read FCommander;
    property Movement: TWarMovementCommands read FMovement;
    property Attack: TWarAttackCommands read FAttack;
    property Gather: TWarGatherCommands read FGather;
    property Spells: TWarSpellCommands read FSpells;
    property Construction: TWarConstructionCommands read FConstruction;
    property Selecting: TWarSelectionCommands read FSelecting;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Forest, DelphiDoom.War.Autotile.Types,
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry,
  DelphiDoom.War.Model.UnitSearch;

const
  // wcmd_train*: the unit of each train command and the building that the command belongs to
  TRAIN_UNITS: array[0..13] of Integer = (WAR_UNIT_FOOTMAN, WAR_UNIT_GRUNT, WAR_UNIT_PEASANT, WAR_UNIT_PEON,
    WAR_UNIT_CATAPULT_HUMANS, WAR_UNIT_CATAPULT_ORCS, WAR_UNIT_KNIGHT, WAR_UNIT_RAIDER, WAR_UNIT_ARCHER,
    WAR_UNIT_SPEARMAN, WAR_UNIT_CONJURER, WAR_UNIT_WARLOCK, WAR_UNIT_CLERIC, WAR_UNIT_NECROLYTE);
  TRAIN_BUILDINGS: array[0..13] of Integer = (WAR_UNIT_BARRACKS_HUMANS, WAR_UNIT_BARRACKS_ORCS,
    WAR_UNIT_TOWNHALL_HUMANS, WAR_UNIT_TOWNHALL_ORCS, WAR_UNIT_BARRACKS_HUMANS, WAR_UNIT_BARRACKS_ORCS,
    WAR_UNIT_BARRACKS_HUMANS, WAR_UNIT_BARRACKS_ORCS, WAR_UNIT_BARRACKS_HUMANS, WAR_UNIT_BARRACKS_ORCS,
    WAR_UNIT_TOWER_HUMANS, WAR_UNIT_TOWER_ORCS, WAR_UNIT_CHURCH, WAR_UNIT_TEMPLE);
  // wcmd_build*
  BUILD_TYPES: array[0..15] of Integer = (WAR_UNIT_FARM_HUMANS, WAR_UNIT_FARM_ORCS, WAR_UNIT_BARRACKS_HUMANS,
    WAR_UNIT_BARRACKS_ORCS, WAR_UNIT_CHURCH, WAR_UNIT_TEMPLE, WAR_UNIT_TOWER_HUMANS, WAR_UNIT_TOWER_ORCS,
    WAR_UNIT_TOWNHALL_HUMANS, WAR_UNIT_TOWNHALL_ORCS, WAR_UNIT_LUMBERMILL_HUMANS, WAR_UNIT_LUMBERMILL_ORCS,
    WAR_UNIT_STABLE, WAR_UNIT_KENNEL, WAR_UNIT_BLACKSMITH_HUMANS, WAR_UNIT_BLACKSMITH_ORCS);
  // wcmd_upgrade*
  UPGRADE_TYPES: array[0..19] of Integer = (WAR_UPGRADE_SWORDS, WAR_UPGRADE_AXES, WAR_UPGRADE_SHIELD,
    WAR_UPGRADE_SHIELD, WAR_UPGRADE_ARROWS, WAR_UPGRADE_SPEARS, WAR_UPGRADE_HORSES, WAR_UPGRADE_WOLVES,
    WAR_UPGRADE_SCORPIONS, WAR_UPGRADE_SPIDERS, WAR_UPGRADE_RAIN_OF_FIRE, WAR_UPGRADE_POISON_CLOUD,
    WAR_UPGRADE_WATER_ELEMENTAL, WAR_UPGRADE_DAEMON, WAR_UPGRADE_HEALING, WAR_UPGRADE_RAISE_DEAD,
    WAR_UPGRADE_FAR_SIGHT, WAR_UPGRADE_DARK_VISION, WAR_UPGRADE_INVISIBILITY, WAR_UPGRADE_UNHOLY_ARMOR);

{ TWarCommands }

constructor TWarCommands.Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine;
  const AEconomy: TWarEconomy; const ACommander: TWarCommander; const AMap: IWarCommandMap);
var
  LType: Integer;
begin
  inherited Create;
  FContext := AContext;
  FMachine := AMachine;
  FCommander := ACommander;
  FMap := AMap;
  FMovement := TWarMovementCommands.Create(AContext, AMachine, ACommander);
  FAttack := TWarAttackCommands.Create(AContext, AMachine, ACommander);
  FGather := TWarGatherCommands.Create(AContext, AMachine, ACommander);
  FSpells := TWarSpellCommands.Create(AContext, AMachine, ACommander);
  FConstruction := TWarConstructionCommands.Create(AContext, AMachine, AEconomy);
  FSelecting := TWarSelectionCommands.Create(AContext, AMachine, ACommander.Selection, AMap);
  RegisterHandler(WAR_COMMAND_NONE, DoNothing);
  RegisterHandler(WAR_COMMAND_MOVE, DoMove);
  RegisterHandler(WAR_COMMAND_STOP, DoStop);
  RegisterHandler(WAR_COMMAND_HARVEST, DoHarvest);
  RegisterHandler(WAR_COMMAND_DELIVER, DoDeliver);
  RegisterHandler(WAR_COMMAND_REPAIR, DoRepair);
  RegisterHandler(WAR_COMMAND_ATTACK, DoAttack);
  for LType := WAR_COMMAND_TRAIN_FIRST to WAR_COMMAND_TRAIN_LAST do
    RegisterHandler(LType, DoTrain);
  for LType := WAR_COMMAND_SPELL_HEALING to WAR_COMMAND_SPELL_UNHOLY_ARMOR do
    RegisterHandler(LType, DoSpell);
  for LType := WAR_COMMAND_SUMMON_SPIDER to WAR_COMMAND_SUMMON_WATER_ELEMENTAL do
    RegisterHandler(LType, DoSummon);
  RegisterHandler(WAR_COMMAND_BUILD_BASIC, DoNothing);
  RegisterHandler(WAR_COMMAND_BUILD_ADVANCED, DoNothing);
  for LType := WAR_COMMAND_BUILD_FIRST to WAR_COMMAND_BUILD_LAST do
    RegisterHandler(LType, DoBuild);
  RegisterHandler(WAR_COMMAND_BUILD_ROAD, DoBuildRoad);
  RegisterHandler(WAR_COMMAND_BUILD_WALL, DoBuildWall);
  for LType := WAR_COMMAND_UPGRADE_FIRST to WAR_COMMAND_UPGRADE_LAST do
    RegisterHandler(LType, DoUpgrade);
  RegisterHandler(WAR_COMMAND_CANCEL, DoCancel);
end;

destructor TWarCommands.Destroy;
begin
  FSelecting.Free;
  FConstruction.Free;
  FSpells.Free;
  FGather.Free;
  FAttack.Free;
  FMovement.Free;
  inherited;
end;

procedure TWarCommands.RegisterHandler(ACommandType: Integer; const AHandler: TWarCommandHandler);
begin
  if (ACommandType < 0) or (ACommandType >= WAR_COMMAND_COUNT) then
    raise EWarException.CreateFmt(SWarModelBadCommand, [ACommandType]);
  FHandlers[ACommandType] := AHandler;
end;

function TWarCommands.Execute(const ACommand: TWarCommand): TWarCommandOutcome;
begin
  if (ACommand.CommandType < 0) or (ACommand.CommandType >= WAR_COMMAND_COUNT) or
    not Assigned(FHandlers[ACommand.CommandType]) then
    raise EWarException.CreateFmt(SWarModelBadCommand, [ACommand.CommandType]);
  Result := FHandlers[ACommand.CommandType](ACommand);
end;

function TWarCommands.Execute(ACommandType: Integer): TWarCommandOutcome;
var
  LCommand: TWarCommand;
begin
  LCommand := Default(TWarCommand);
  LCommand.CommandType := ACommandType;
  Result := Execute(LCommand);
end;

function TWarCommands.Execute(ACommandType: Integer; const ATarget: TWarVec2; AQueue: Boolean): TWarCommandOutcome;
var
  LCommand: TWarCommand;
begin
  LCommand.CommandType := ACommandType;
  LCommand.Target := ATarget;
  LCommand.Queue := AQueue;
  Result := Execute(LCommand);
end;

class function TWarCommands.TrainOf(ACommandType: Integer; out AUnitType, ABuildingType: Integer): Boolean;
begin
  Result := (ACommandType >= WAR_COMMAND_TRAIN_FIRST) and (ACommandType <= WAR_COMMAND_TRAIN_LAST);
  AUnitType := -1;
  ABuildingType := -1;
  if Result then
  begin
    AUnitType := TRAIN_UNITS[ACommandType - WAR_COMMAND_TRAIN_FIRST];
    ABuildingType := TRAIN_BUILDINGS[ACommandType - WAR_COMMAND_TRAIN_FIRST];
  end;
end;

class function TWarCommands.UpgradeOf(ACommandType: Integer): Integer;
begin
  if (ACommandType >= WAR_COMMAND_UPGRADE_FIRST) and (ACommandType <= WAR_COMMAND_UPGRADE_LAST) then
    Result := UPGRADE_TYPES[ACommandType - WAR_COMMAND_UPGRADE_FIRST]
  else
    Result := -1;
end;

class function TWarCommands.BuildingOf(ACommandType: Integer): Integer;
begin
  if (ACommandType >= WAR_COMMAND_BUILD_FIRST) and (ACommandType <= WAR_COMMAND_BUILD_LAST) then
    Result := BUILD_TYPES[ACommandType - WAR_COMMAND_BUILD_FIRST]
  else
    Result := -1;
end;

// the tile of the point and the slot of who occupies it (0 if nobody, or if the map does not tell)
function TWarCommands.TargetSlotAt(const ATarget: TWarVec2; out ATileX, ATileY: Integer): Integer;
var
  LTile: TWarVec2;
begin
  LTile := TWarModelMath.MapToTile(ATarget);
  ATileX := Trunc(LTile.X);
  ATileY := Trunc(LTile.Y);
  Result := 0;
  if Assigned(FMap) then
    Result := FContext.Pool.FindSlot(FMap.EntityIdAt(ATileX, ATileY));
end;

// wmap_isUnitUnknown
function TWarCommands.IsUnknown(ASlot: Integer): Boolean;
var
  LEntity: PWarEntity;
  LTile: TWarVec2;
begin
  if not Assigned(FMap) then
    Exit(False);
  LEntity := FContext.Pool.Slots[ASlot];
  LTile := TWarUnitGeometry.Tile(LEntity);
  Result := FMap.IsAreaUnknown(Trunc(LTile.X), Trunc(LTile.Y), LEntity^.UnitData.SizeX, LEntity^.UnitData.SizeY);
end;

// wu_isEnemyUnit: a unit of another player that is not neutral
function TWarCommands.IsEnemy(ASlot: Integer): Boolean;
var
  LEntity: PWarEntity;
begin
  LEntity := FContext.Pool.Slots[ASlot];
  Result := LEntity^.HasUnit and (LEntity^.UnitData.Player <> FCommander.Player) and
    (FContext.Players[LEntity^.UnitData.Player]^.Race <> wraNeutral);
end;

function TWarCommands.SingleBuilding(ACommandType: Integer): Integer;
begin
  if FCommander.Selection.Count <> 1 then
    raise EWarException.CreateFmt(SWarModelBadSelection, [ACommandType, 'one selected building']);
  Result := FContext.Pool.FindSlot(FCommander.Selection[0]);
  if (Result = 0) or not FContext.Pool.Slots[Result]^.HasUnit or
    not TWarUnitClassifier.IsBuilding(FContext.Pool.Slots[Result]^.UnitData.UnitType) then
    raise EWarException.CreateFmt(SWarModelBadSelection, [ACommandType, 'one selected building']);
end;

function TWarCommands.FirstSelected(ACommandType: Integer): Integer;
begin
  Result := 0;
  if FCommander.Selection.Count > 0 then
    Result := FContext.Pool.FindSlot(FCommander.Selection[0]);
  if (Result = 0) or not FContext.Pool.Slots[Result]^.HasUnit then
    raise EWarException.CreateFmt(SWarModelBadSelection, [ACommandType, 'a selected unit']);
end;

function TWarCommands.DoNothing(const ACommand: TWarCommand): TWarCommandOutcome;
begin
  Result := wcoNotExecuted;
end;

function TWarCommands.DoMove(const ACommand: TWarCommand): TWarCommandOutcome;
begin
  FMovement.Move(ACommand.Target, ACommand.Queue);
  Result := wcoExecuted;
end;

function TWarCommands.DoStop(const ACommand: TWarCommand): TWarCommandOutcome;
begin
  FMovement.Stop;
  Result := wcoExecuted;
end;

// the harvest of what is under the point: a mine that the player knows, a tree (or the nearest one that can be reached when
// the tile is not seen); otherwise a move. False if the target is neither
function TWarCommands.HarvestAt(const ATarget: TWarVec2; AQueue, AVisibleOnly: Boolean; ATargetSlot, ATileX,
  ATileY: Integer): Boolean;
var
  LEntity: PWarEntity;
  LSeen: Boolean;
  LTree: TWarTree;
  LForest: TWarMapForest;
begin
  LEntity := FContext.Pool.Slots[ATargetSlot];
  if LEntity^.HasUnit and (LEntity^.UnitData.UnitType = WAR_UNIT_GOLDMINE) then
  begin
    if not IsUnknown(ATargetSlot) then
      FGather.Harvest(ATargetSlot, ATileX, ATileY)
    else
      FMovement.Move(ATarget, AQueue);
    Exit(True);
  end;
  if LEntity^.EntityType <> WAR_ENTITY_FOREST then
    Exit(False);
  // the command asks that the tile is not unknown, the right click that it is visible
  if AVisibleOnly then
    LSeen := not Assigned(FMap) or FMap.IsTileVisible(ATileX, ATileY)
  else
    LSeen := not Assigned(FMap) or not FMap.IsTileUnknown(ATileX, ATileY);
  if LSeen then
    FGather.Harvest(ATargetSlot, ATileX, ATileY)
  else
  begin
    LForest := FContext.RequireGather.Forests.FindForest(LEntity^.Id);
    if Assigned(LForest) and FContext.RequireGather.Forests.FindAccessibleTree(LForest, ATileX, ATileY, LTree) then
      FGather.Harvest(ATargetSlot, LTree.TileX, LTree.TileY)
    else
      FMovement.Move(ATarget, AQueue);
  end;
  Result := True;
end;

function TWarCommands.DoHarvest(const ACommand: TWarCommand): TWarCommandOutcome;
var
  LTileX: Integer;
  LTileY: Integer;
  LTarget: Integer;
begin
  LTarget := TargetSlotAt(ACommand.Target, LTileX, LTileY);
  if LTarget <> 0 then
    HarvestAt(ACommand.Target, ACommand.Queue, False, LTarget, LTileX, LTileY);
  Result := wcoExecuted;
end;

function TWarCommands.DoDeliver(const ACommand: TWarCommand): TWarCommandOutcome;
begin
  FGather.Deliver(0);
  Result := wcoExecuted;
end;

function TWarCommands.DoRepair(const ACommand: TWarCommand): TWarCommandOutcome;
var
  LTileX: Integer;
  LTileY: Integer;
  LTarget: Integer;
  LWorkers: TArray<Integer>;
  LIndex: Integer;
begin
  LTarget := TargetSlotAt(ACommand.Target, LTileX, LTileY);
  if (LTarget <> 0) and (FMap.IsTileVisible(LTileX, LTileY) or FMap.IsTileFog(LTileX, LTileY)) and
    FContext.Pool.Slots[LTarget]^.HasUnit and
    TWarUnitClassifier.IsBuilding(FContext.Pool.Slots[LTarget]^.UnitData.UnitType) then
  begin
    SetLength(LWorkers, FCommander.Selection.Count);
    for LIndex := 0 to High(LWorkers) do
    begin
      LWorkers[LIndex] := FContext.Pool.FindSlot(FCommander.Selection[LIndex]);
      if LWorkers[LIndex] = 0 then
        raise EWarException.CreateFmt(SWarModelSelectionGone, [FCommander.Selection[LIndex]]);
    end;
    FConstruction.OrderRepair(LWorkers, LTarget);
  end;
  Result := wcoExecuted;
end;

function TWarCommands.DoAttack(const ACommand: TWarCommand): TWarCommandOutcome;
var
  LTileX: Integer;
  LTileY: Integer;
  LTarget: Integer;
begin
  LTarget := TargetSlotAt(ACommand.Target, LTileX, LTileY);
  if LTarget <> 0 then
  begin
    // a target that the player does not see is the attack of the point
    if FContext.Pool.Slots[LTarget]^.EntityType = WAR_ENTITY_UNIT then
    begin
      if IsUnknown(LTarget) then
        LTarget := 0;
    end
    else if FContext.Pool.Slots[LTarget]^.EntityType = WAR_ENTITY_WALL then
    begin
      if not FMap.IsTileVisible(LTileX, LTileY) then
        LTarget := 0;
    end;
  end;
  FAttack.Attack(LTarget, ACommand.Target);
  Result := wcoExecuted;
end;

function TWarCommands.DoTrain(const ACommand: TWarCommand): TWarCommandOutcome;
var
  LBuilding: Integer;
  LUnitType: Integer;
  LBuildingType: Integer;
begin
  LBuilding := SingleBuilding(ACommand.CommandType);
  TrainOf(ACommand.CommandType, LUnitType, LBuildingType);
  if FContext.Pool.Slots[LBuilding]^.UnitData.UnitType <> LBuildingType then
    raise EWarException.CreateFmt(SWarModelBadSelection, [ACommand.CommandType, 'the building that trains that unit']);
  FConstruction.OrderTrain(LBuilding, LUnitType, FCommander.Cause);
  Result := wcoExecuted;
end;

function TWarCommands.DoUpgrade(const ACommand: TWarCommand): TWarCommandOutcome;
begin
  FConstruction.OrderUpgrade(SingleBuilding(ACommand.CommandType), UpgradeOf(ACommand.CommandType));
  Result := wcoExecuted;
end;

function TWarCommands.DoBuild(const ACommand: TWarCommand): TWarCommandOutcome;
var
  LTileX: Integer;
  LTileY: Integer;
  LWorker: Integer;
begin
  LWorker := FirstSelected(ACommand.CommandType);
  TargetSlotAt(ACommand.Target, LTileX, LTileY);
  FConstruction.PlaceBuilding(LWorker, BuildingOf(ACommand.CommandType), LTileX, LTileY);
  Result := wcoExecuted;
end;

function TWarCommands.DoBuildWall(const ACommand: TWarCommand): TWarCommandOutcome;
var
  LTileX: Integer;
  LTileY: Integer;
  LTownHall: Integer;
  LPlayer: Integer;
begin
  LTownHall := FirstSelected(ACommand.CommandType);
  LPlayer := FContext.Pool.Slots[LTownHall]^.UnitData.Player;
  if FContext.Pool.Slots[LTownHall]^.UnitData.UnitType <>
    TWarUnitSearch.TownHallOfRace(FContext.Players[LPlayer]^.Race) then
    raise EWarException.CreateFmt(SWarModelBadSelection, [ACommand.CommandType, 'the town hall of the player']);
  TargetSlotAt(ACommand.Target, LTileX, LTileY);
  FConstruction.PlaceWall(LPlayer, LTileX, LTileY);
  Result := wcoExecuted;
end;

function TWarCommands.DoBuildRoad(const ACommand: TWarCommand): TWarCommandOutcome;
var
  LTileX: Integer;
  LTileY: Integer;
  LTownHall: Integer;
  LPlayer: Integer;
begin
  LTownHall := FirstSelected(ACommand.CommandType);
  LPlayer := FContext.Pool.Slots[LTownHall]^.UnitData.Player;
  if FContext.Pool.Slots[LTownHall]^.UnitData.UnitType <>
    TWarUnitSearch.TownHallOfRace(FContext.Players[LPlayer]^.Race) then
    raise EWarException.CreateFmt(SWarModelBadSelection, [ACommand.CommandType, 'the town hall of the player']);
  TargetSlotAt(ACommand.Target, LTileX, LTileY);
  FConstruction.PlaceRoad(LPlayer, LTileX, LTileY);
  Result := wcoExecuted;
end;

function TWarCommands.DoSummon(const ACommand: TWarCommand): TWarCommandOutcome;
begin
  // the summons follow the spells both in the commands and in the spell types
  FSpells.Summon(ACommand.CommandType - WAR_COMMAND_SPELL_HEALING);
  Result := wcoExecuted;
end;

function TWarCommands.DoSpell(const ACommand: TWarCommand): TWarCommandOutcome;
var
  LTileX: Integer;
  LTileY: Integer;
  LTarget: Integer;
begin
  LTarget := TargetSlotAt(ACommand.Target, LTileX, LTileY);
  case ACommand.CommandType of
    WAR_COMMAND_SPELL_HEALING:
      FSpells.Healing(LTarget, ACommand.Target);
    WAR_COMMAND_SPELL_INVISIBILITY:
      FSpells.Invisibility(LTarget, ACommand.Target);
    WAR_COMMAND_SPELL_UNHOLY_ARMOR:
      FSpells.UnholyArmor(LTarget, ACommand.Target);
    WAR_COMMAND_SPELL_RAIN_OF_FIRE:
      FSpells.RainOfFire(ACommand.Target);
    WAR_COMMAND_SPELL_POISON_CLOUD:
      FSpells.PoisonCloud(ACommand.Target);
    WAR_COMMAND_SPELL_RAISE_DEAD:
      FSpells.RaiseDead(ACommand.Target);
  else
    FSpells.Sight(ACommand.Target);
  end;
  Result := wcoExecuted;
end;

function TWarCommands.DoCancel(const ACommand: TWarCommand): TWarCommandOutcome;
begin
  Cancel;
  Result := wcoExecuted;
end;

function TWarCommands.Cancel: Boolean;
var
  LIndex: Integer;
  LSlot: Integer;
begin
  Result := False;
  for LIndex := 0 to FCommander.Selection.Count - 1 do
  begin
    LSlot := FContext.Pool.FindSlot(FCommander.Selection[LIndex]);
    if LSlot = 0 then
      raise EWarException.CreateFmt(SWarModelSelectionGone, [FCommander.Selection[LIndex]]);
    if FContext.Pool.Slots[LSlot]^.HasUnit and FConstruction.Cancel(LSlot) then
      Result := True;
  end;
end;

function TWarCommands.RightClick(const ATarget: TWarVec2; AQueue: Boolean): Boolean;
var
  LTileX: Integer;
  LTileY: Integer;
  LTarget: Integer;
  LEntity: PWarEntity;
begin
  if FCommander.Selection.Count = 0 then
    Exit(False);
  Result := True;
  LTarget := TargetSlotAt(ATarget, LTileX, LTileY);
  if LTarget = 0 then
  begin
    FMovement.Move(ATarget, AQueue);
    Exit;
  end;
  if HarvestAt(ATarget, AQueue, True, LTarget, LTileX, LTileY) then
    Exit;
  LEntity := FContext.Pool.Slots[LTarget];
  if LEntity^.HasUnit and ((LEntity^.UnitData.UnitType = WAR_UNIT_TOWNHALL_HUMANS) or
    (LEntity^.UnitData.UnitType = WAR_UNIT_TOWNHALL_ORCS)) then
  begin
    if IsUnknown(LTarget) then
      FMovement.Move(ATarget, AQueue)
    else if IsEnemy(LTarget) then
      FAttack.Attack(LTarget, ATarget)
    else
      FGather.Deliver(LTarget);
  end
  // it does not matter whether the piece of wall is seen: the units walk to it
  else if LEntity^.EntityType = WAR_ENTITY_WALL then
    FMovement.Move(ATarget, AQueue)
  else if IsEnemy(LTarget) then
    FAttack.Attack(LTarget, ATarget)
  else
    FMovement.Follow(LTarget);
end;

end.
