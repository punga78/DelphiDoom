{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the panel of the commands of the selection        }
{                                                                              }
{  Port of war1 (acoto87/war1), updateCommandButtons of war_map.c and          }
{  wu_getUnitCommands and wu_getUnitCommandData of war_units.c, (c) 2019       }
{  Alejandro Coto Gutierrez, zlib License (see Games\War\LICENSE-war1.txt).    }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.CommandPanel;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.MapUi.Types;

type
  /// <summary>
  ///   updateCommandButtons: the six buttons and the lines of text of the panel for the selection, with the command that
  ///   waits for a target (a unit shows only CANCEL while one waits, a worker the menus of the buildings, a town hall CANCEL
  ///   while a road or a wall waits). The units that move (and the spell casters, with the spells the player has
  ///   researched), the workers, the farm and the gold mine and every building (train, research, cancel, road, wall) are
  ///   ported. The commands are the same for the units of the selection only where every one of them has the same one
  /// </summary>
  TWarMapCommandPanel = class
  strict private
    FContext: TWarModelContext;
    procedure GetCommands(ASlot, APending: Integer; out ACommands: array of Integer);
    procedure GetWorkerCommands(ASlot, APending: Integer; var ACommands: array of Integer);
    procedure GetCasterCommands(ASlot, APending: Integer; var ACommands: array of Integer);
    procedure GetBuildingCommands(ASlot, APending: Integer; var ACommands: array of Integer);
    function SlotData(ASlot, ACommand: Integer): TWarCommandSlot;
    function AttackFrame(ASlot: Integer): Integer;
    function CarryingResources(ASlot: Integer): Boolean;
    function PlayerHasBuilding(APlayer, AUnitType: Integer): Boolean;
    function FeatureAllowed(APlayer: PWarPlayerInfo; AFeature: Integer): Boolean;
    function HasAnyUpgrade(APlayer: PWarPlayerInfo; AUpgrade: Integer): Boolean;
    function HasRemainingUpgrade(APlayer: PWarPlayerInfo; AUpgrade: Integer): Boolean;
    /// <summary>getUpgradeLevel: the level of the upgrade of the player (the array is by upgrade / 2)</summary>
    function UpgradeLevel(APlayer: PWarPlayerInfo; AUpgrade: Integer): Integer;
  public
    constructor Create(const AContext: TWarModelContext);
    /// <summary>updateCommandButtons with the command of the map that waits for a target (0 if none)</summary>
    procedure Update(var APanel: TWarCommandPanel; APendingCommand: Integer); overload;
    /// <summary>updateCommandButtons when no command waits</summary>
    procedure Update(var APanel: TWarCommandPanel); overload;
  end;

implementation

uses
  System.Math, DelphiDoom.War.Types, DelphiDoom.War.Ui.Types, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.Stats.Types, DelphiDoom.War.Model.Construction.Types, DelphiDoom.War.Model.UnitClassifier,
  DelphiDoom.War.MapUi.CommandData.Data, DelphiDoom.War.MapUi.CommandCatalog, DelphiDoom.War.MapUi.UnitNames.Data;

{ TWarMapCommandPanel }

constructor TWarMapCommandPanel.Create(const AContext: TWarModelContext);
begin
  inherited Create;
  FContext := AContext;
end;

function TWarMapCommandPanel.CarryingResources(ASlot: Integer): Boolean;
var
  LUnit: PWarUnitComponent;
begin
  // wu_isCarryingResources: a full load of gold or wood
  LUnit := @FContext.Pool.Slots[ASlot]^.UnitData;
  case LUnit^.ResourceKind of
    wrkGold, wrkWood:
      Result := LUnit^.Amount = WAR_MODEL_MAX_CARRY;
  else
    Result := False;
  end;
end;

function TWarMapCommandPanel.PlayerHasBuilding(APlayer, AUnitType: Integer): Boolean;
begin
  Result := FContext.Queries.CountBuildingsOfType(APlayer, AUnitType, True) > 0;
end;

function TWarMapCommandPanel.FeatureAllowed(APlayer: PWarPlayerInfo; AFeature: Integer): Boolean;
begin
  // isFeatureAllowed: the array is by feature / 2
  Result := APlayer^.Features[AFeature div 2] <> 0;
end;

function TWarMapCommandPanel.HasAnyUpgrade(APlayer: PWarPlayerInfo; AUpgrade: Integer): Boolean;
begin
  Result := (APlayer^.Upgrades[AUpgrade div 2].Allowed > 0) and (APlayer^.Upgrades[AUpgrade div 2].Level > 0);
end;

function TWarMapCommandPanel.HasRemainingUpgrade(APlayer: PWarPlayerInfo; AUpgrade: Integer): Boolean;
begin
  Result := APlayer^.Upgrades[AUpgrade div 2].Level < APlayer^.Upgrades[AUpgrade div 2].Allowed;
end;

function TWarMapCommandPanel.UpgradeLevel(APlayer: PWarPlayerInfo; AUpgrade: Integer): Integer;
begin
  Result := APlayer^.Upgrades[AUpgrade div 2].Level;
end;

procedure TWarMapCommandPanel.GetWorkerCommands(ASlot, APending: Integer; var ACommands: array of Integer);
var
  LUnit: PWarUnitComponent;
  LPlayer: PWarPlayerInfo;
  LHumans: Boolean;
begin
  LUnit := @FContext.Pool.Slots[ASlot]^.UnitData;
  LPlayer := FContext.Players[LUnit^.Player];
  LHumans := LUnit^.UnitType = WAR_UNIT_PEASANT;
  if APending <> WAR_CMD_NONE then
  begin
    if APending = WAR_CMD_BUILD_BASIC then
    begin
      if LHumans then
      begin
        ACommands[0] := WAR_CMD_BUILD_FARM_HUMANS;
        if FeatureAllowed(LPlayer, WAR_FEATURE_UNIT_LUMBER_MILL_HUMANS) then
          ACommands[1] := WAR_CMD_BUILD_LUMBERMILL_HUMANS;
        ACommands[2] := WAR_CMD_BUILD_BARRACKS_HUMANS;
      end
      else
      begin
        ACommands[0] := WAR_CMD_BUILD_FARM_ORCS;
        if FeatureAllowed(LPlayer, WAR_FEATURE_UNIT_LUMBER_MILL_ORCS) then
          ACommands[1] := WAR_CMD_BUILD_LUMBERMILL_ORCS;
        ACommands[2] := WAR_CMD_BUILD_BARRACKS_ORCS;
      end;
    end
    else if APending = WAR_CMD_BUILD_ADVANCED then
    begin
      if LHumans then
      begin
        ACommands[0] := WAR_CMD_BUILD_BLACKSMITH_HUMANS;
        ACommands[1] := WAR_CMD_BUILD_CHURCH;
        ACommands[2] := WAR_CMD_BUILD_STABLE;
        if PlayerHasBuilding(LUnit^.Player, WAR_UNIT_BLACKSMITH_HUMANS) then
          ACommands[3] := WAR_CMD_BUILD_TOWER_HUMANS;
      end
      else
      begin
        // the original lists the barracks first for the orcs too (and not the blacksmith: a defect that is kept)
        ACommands[0] := WAR_CMD_BUILD_BARRACKS_ORCS;
        ACommands[1] := WAR_CMD_BUILD_TEMPLE;
        ACommands[2] := WAR_CMD_BUILD_KENNEL;
        if PlayerHasBuilding(LUnit^.Player, WAR_UNIT_BLACKSMITH_ORCS) then
          ACommands[3] := WAR_CMD_BUILD_TOWER_ORCS;
      end;
    end;
    ACommands[5] := WAR_CMD_CANCEL;
    Exit;
  end;
  ACommands[0] := WAR_CMD_MOVE;
  ACommands[1] := WAR_CMD_STOP;
  ACommands[2] := WAR_CMD_REPAIR;
  if CarryingResources(ASlot) then
    ACommands[3] := WAR_CMD_DELIVER
  else
    ACommands[3] := WAR_CMD_HARVEST;
  ACommands[4] := WAR_CMD_BUILD_BASIC;
  if LHumans then
  begin
    if PlayerHasBuilding(LUnit^.Player, WAR_UNIT_LUMBERMILL_HUMANS) then
      ACommands[5] := WAR_CMD_BUILD_ADVANCED;
  end
  else if PlayerHasBuilding(LUnit^.Player, WAR_UNIT_LUMBERMILL_ORCS) then
    ACommands[5] := WAR_CMD_BUILD_ADVANCED;
end;

procedure TWarMapCommandPanel.GetCasterCommands(ASlot, APending: Integer; var ACommands: array of Integer);
var
  LUnit: PWarUnitComponent;
  LPlayer: PWarPlayerInfo;

  procedure Spell(AIndex, AFeature, AUpgrade, ACommand: Integer);
  begin
    // only if the spell is allowed and researched
    if FeatureAllowed(LPlayer, AFeature) and HasAnyUpgrade(LPlayer, AUpgrade) then
      ACommands[AIndex] := ACommand;
  end;

begin
  if APending <> WAR_CMD_NONE then
  begin
    ACommands[5] := WAR_CMD_CANCEL;
    Exit;
  end;
  LUnit := @FContext.Pool.Slots[ASlot]^.UnitData;
  LPlayer := FContext.Players[LUnit^.Player];
  ACommands[0] := WAR_CMD_MOVE;
  ACommands[1] := WAR_CMD_STOP;
  ACommands[2] := WAR_CMD_ATTACK;
  case LUnit^.UnitType of
    WAR_UNIT_CONJURER:
      begin
        Spell(3, WAR_FEATURE_SPELL_RAIN_OF_FIRE, WAR_UPGRADE_RAIN_OF_FIRE, WAR_CMD_SPELL_RAIN_OF_FIRE);
        Spell(4, WAR_FEATURE_SPELL_SCORPION, WAR_UPGRADE_SCORPIONS, WAR_CMD_SUMMON_SCORPION);
        Spell(5, WAR_FEATURE_SPELL_WATER_ELEMENTAL, WAR_UPGRADE_WATER_ELEMENTAL, WAR_CMD_SUMMON_WATER_ELEMENTAL);
      end;
    WAR_UNIT_WARLOCK:
      begin
        Spell(3, WAR_FEATURE_SPELL_POISON_CLOUD, WAR_UPGRADE_POISON_CLOUD, WAR_CMD_SPELL_POISON_CLOUD);
        Spell(4, WAR_FEATURE_SPELL_SPIDER, WAR_UPGRADE_SPIDERS, WAR_CMD_SUMMON_SPIDER);
        Spell(5, WAR_FEATURE_SPELL_DAEMON, WAR_UPGRADE_DAEMON, WAR_CMD_SUMMON_DAEMON);
      end;
    WAR_UNIT_CLERIC:
      begin
        Spell(3, WAR_FEATURE_SPELL_HEALING, WAR_UPGRADE_HEALING, WAR_CMD_SPELL_HEALING);
        Spell(4, WAR_FEATURE_SPELL_FAR_SIGHT, WAR_UPGRADE_FAR_SIGHT, WAR_CMD_SPELL_FAR_SIGHT);
        Spell(5, WAR_FEATURE_SPELL_INVISIBILITY, WAR_UPGRADE_INVISIBILITY, WAR_CMD_SPELL_INVISIBILITY);
      end;
    WAR_UNIT_NECROLYTE:
      begin
        Spell(3, WAR_FEATURE_SPELL_RAISE_DEAD, WAR_UPGRADE_RAISE_DEAD, WAR_CMD_SPELL_RAISE_DEAD);
        Spell(4, WAR_FEATURE_SPELL_DARK_VISION, WAR_UPGRADE_DARK_VISION, WAR_CMD_SPELL_DARK_VISION);
        Spell(5, WAR_FEATURE_SPELL_UNHOLY_ARMOR, WAR_UPGRADE_UNHOLY_ARMOR, WAR_CMD_SPELL_UNHOLY_ARMOR);
      end;
  end;
end;

procedure TWarMapCommandPanel.GetBuildingCommands(ASlot, APending: Integer; var ACommands: array of Integer);
var
  LUnit: PWarUnitComponent;
  LPlayer: PWarPlayerInfo;
  LIndex: Integer;

  // a research that is offered only while the player has not done it
  procedure Research(AIndex, AFeature, AUpgrade, ACommand: Integer);
  begin
    if FeatureAllowed(LPlayer, AFeature) and HasRemainingUpgrade(LPlayer, AUpgrade) then
      ACommands[AIndex] := ACommand;
  end;

begin
  LUnit := @FContext.Pool.Slots[ASlot]^.UnitData;
  LPlayer := FContext.Players[LUnit^.Player];
  LIndex := LUnit^.Player;
  // the town hall also shows CANCEL while a road or a wall waits for its tile; the rest only while they are built
  if (LUnit^.UnitType = WAR_UNIT_TOWNHALL_HUMANS) or (LUnit^.UnitType = WAR_UNIT_TOWNHALL_ORCS) then
  begin
    if (APending = WAR_CMD_BUILD_WALL) or (APending = WAR_CMD_BUILD_ROAD) or LUnit^.Building then
      ACommands[5] := WAR_CMD_CANCEL
    else
    begin
      if LUnit^.UnitType = WAR_UNIT_TOWNHALL_HUMANS then
        ACommands[0] := WAR_CMD_TRAIN_PEASANT
      else
        ACommands[0] := WAR_CMD_TRAIN_PEON;
      ACommands[1] := WAR_CMD_BUILD_ROAD;
      if FeatureAllowed(LPlayer, WAR_FEATURE_UNIT_WALL) then
        ACommands[2] := WAR_CMD_BUILD_WALL;
    end;
    Exit;
  end;
  if LUnit^.Building then
  begin
    ACommands[5] := WAR_CMD_CANCEL;
    Exit;
  end;
  case LUnit^.UnitType of
    WAR_UNIT_BARRACKS_HUMANS:
      begin
        ACommands[0] := WAR_CMD_TRAIN_FOOTMAN;
        if PlayerHasBuilding(LIndex, WAR_UNIT_LUMBERMILL_HUMANS) then
          ACommands[1] := WAR_CMD_TRAIN_ARCHER;
        if PlayerHasBuilding(LIndex, WAR_UNIT_BLACKSMITH_HUMANS) then
        begin
          ACommands[2] := WAR_CMD_TRAIN_CATAPULT_HUMANS;
          if PlayerHasBuilding(LIndex, WAR_UNIT_STABLE) then
            ACommands[3] := WAR_CMD_TRAIN_KNIGHT;
        end;
      end;
    WAR_UNIT_BARRACKS_ORCS:
      begin
        ACommands[0] := WAR_CMD_TRAIN_GRUNT;
        if PlayerHasBuilding(LIndex, WAR_UNIT_LUMBERMILL_ORCS) then
          ACommands[1] := WAR_CMD_TRAIN_SPEARMAN;
        if PlayerHasBuilding(LIndex, WAR_UNIT_BLACKSMITH_ORCS) then
        begin
          ACommands[2] := WAR_CMD_TRAIN_CATAPULT_ORCS;
          if PlayerHasBuilding(LIndex, WAR_UNIT_KENNEL) then
            ACommands[3] := WAR_CMD_TRAIN_RAIDER;
        end;
      end;
    WAR_UNIT_CHURCH:
      begin
        ACommands[0] := WAR_CMD_TRAIN_CLERIC;
        Research(1, WAR_FEATURE_SPELL_HEALING, WAR_UPGRADE_HEALING, WAR_CMD_UPGRADE_HEALING);
        Research(2, WAR_FEATURE_SPELL_FAR_SIGHT, WAR_UPGRADE_FAR_SIGHT, WAR_CMD_UPGRADE_FAR_SIGHT);
        Research(3, WAR_FEATURE_SPELL_INVISIBILITY, WAR_UPGRADE_INVISIBILITY, WAR_CMD_UPGRADE_INVISIBILITY);
      end;
    WAR_UNIT_TEMPLE:
      begin
        ACommands[0] := WAR_CMD_TRAIN_NECROLYTE;
        Research(1, WAR_FEATURE_SPELL_RAISE_DEAD, WAR_UPGRADE_RAISE_DEAD, WAR_CMD_UPGRADE_RAISE_DEAD);
        Research(2, WAR_FEATURE_SPELL_DARK_VISION, WAR_UPGRADE_DARK_VISION, WAR_CMD_UPGRADE_DARK_VISION);
        Research(3, WAR_FEATURE_SPELL_UNHOLY_ARMOR, WAR_UPGRADE_UNHOLY_ARMOR, WAR_CMD_UPGRADE_UNHOLY_ARMOR);
      end;
    WAR_UNIT_TOWER_HUMANS:
      begin
        ACommands[0] := WAR_CMD_TRAIN_CONJURER;
        Research(1, WAR_FEATURE_SPELL_SCORPION, WAR_UPGRADE_SCORPIONS, WAR_CMD_UPGRADE_SCORPION);
        Research(2, WAR_FEATURE_SPELL_RAIN_OF_FIRE, WAR_UPGRADE_RAIN_OF_FIRE, WAR_CMD_UPGRADE_RAIN_OF_FIRE);
        Research(3, WAR_FEATURE_SPELL_WATER_ELEMENTAL, WAR_UPGRADE_WATER_ELEMENTAL, WAR_CMD_UPGRADE_WATER_ELEMENTAL);
      end;
    WAR_UNIT_TOWER_ORCS:
      begin
        ACommands[0] := WAR_CMD_TRAIN_WARLOCK;
        Research(1, WAR_FEATURE_SPELL_SPIDER, WAR_UPGRADE_SPIDERS, WAR_CMD_UPGRADE_SPIDER);
        Research(2, WAR_FEATURE_SPELL_POISON_CLOUD, WAR_UPGRADE_POISON_CLOUD, WAR_CMD_UPGRADE_POISON_CLOUD);
        Research(3, WAR_FEATURE_SPELL_DAEMON, WAR_UPGRADE_DAEMON, WAR_CMD_UPGRADE_DAEMON);
      end;
    WAR_UNIT_LUMBERMILL_HUMANS:
      if HasRemainingUpgrade(LPlayer, WAR_UPGRADE_ARROWS) then
        ACommands[0] := WAR_CMD_UPGRADE_ARROWS;
    WAR_UNIT_LUMBERMILL_ORCS:
      if HasRemainingUpgrade(LPlayer, WAR_UPGRADE_SPEARS) then
        ACommands[0] := WAR_CMD_UPGRADE_SPEARS;
    WAR_UNIT_STABLE:
      if HasRemainingUpgrade(LPlayer, WAR_UPGRADE_HORSES) then
        ACommands[0] := WAR_CMD_UPGRADE_HORSES;
    WAR_UNIT_KENNEL:
      if HasRemainingUpgrade(LPlayer, WAR_UPGRADE_WOLVES) then
        ACommands[0] := WAR_CMD_UPGRADE_WOLVES;
    WAR_UNIT_BLACKSMITH_HUMANS:
      begin
        if HasRemainingUpgrade(LPlayer, WAR_UPGRADE_SWORDS) then
          ACommands[0] := WAR_CMD_UPGRADE_SWORDS;
        if HasRemainingUpgrade(LPlayer, WAR_UPGRADE_SHIELD) then
          ACommands[1] := WAR_CMD_UPGRADE_SHIELD_HUMANS;
      end;
    WAR_UNIT_BLACKSMITH_ORCS:
      begin
        if HasRemainingUpgrade(LPlayer, WAR_UPGRADE_AXES) then
          ACommands[0] := WAR_CMD_UPGRADE_AXES;
        if HasRemainingUpgrade(LPlayer, WAR_UPGRADE_SHIELD) then
          ACommands[1] := WAR_CMD_UPGRADE_SHIELD_ORCS;
      end;
  end;
end;

procedure TWarMapCommandPanel.GetCommands(ASlot, APending: Integer; out ACommands: array of Integer);
var
  LUnit: PWarUnitComponent;
  LIndex: Integer;
begin
  // wu_getUnitCommands
  for LIndex := 0 to High(ACommands) do
    ACommands[LIndex] := WAR_CMD_NONE;
  LUnit := @FContext.Pool.Slots[ASlot]^.UnitData;
  // a unit of a race that is not the player's has no commands
  if FContext.Players[LUnit^.Player]^.Race <> TWarUnitClassifier.RaceOf(LUnit^.UnitType) then
    Exit;
  case LUnit^.UnitType of
    WAR_UNIT_FOOTMAN, WAR_UNIT_GRUNT, WAR_UNIT_CATAPULT_HUMANS, WAR_UNIT_CATAPULT_ORCS, WAR_UNIT_KNIGHT,
    WAR_UNIT_RAIDER, WAR_UNIT_ARCHER, WAR_UNIT_SPEARMAN, WAR_UNIT_WATER_ELEMENTAL, WAR_UNIT_DAEMON,
    WAR_UNIT_SCORPION, WAR_UNIT_SPIDER, WAR_UNIT_SKELETON:
      if APending <> WAR_CMD_NONE then
        ACommands[5] := WAR_CMD_CANCEL
      else
      begin
        ACommands[0] := WAR_CMD_MOVE;
        ACommands[1] := WAR_CMD_STOP;
        ACommands[2] := WAR_CMD_ATTACK;
      end;
    WAR_UNIT_PEASANT, WAR_UNIT_PEON:
      GetWorkerCommands(ASlot, APending, ACommands);
    WAR_UNIT_CONJURER, WAR_UNIT_WARLOCK, WAR_UNIT_CLERIC, WAR_UNIT_NECROLYTE:
      GetCasterCommands(ASlot, APending, ACommands);
    WAR_UNIT_FARM_HUMANS, WAR_UNIT_FARM_ORCS:
      if LUnit^.Building then
        ACommands[5] := WAR_CMD_CANCEL;
    WAR_UNIT_BARRACKS_HUMANS, WAR_UNIT_BARRACKS_ORCS, WAR_UNIT_CHURCH, WAR_UNIT_TEMPLE, WAR_UNIT_TOWER_HUMANS,
    WAR_UNIT_TOWER_ORCS, WAR_UNIT_TOWNHALL_HUMANS, WAR_UNIT_TOWNHALL_ORCS, WAR_UNIT_LUMBERMILL_HUMANS,
    WAR_UNIT_LUMBERMILL_ORCS, WAR_UNIT_STABLE, WAR_UNIT_KENNEL, WAR_UNIT_BLACKSMITH_HUMANS,
    WAR_UNIT_BLACKSMITH_ORCS:
      GetBuildingCommands(ASlot, APending, ACommands);
  end;
  // the rest (the neutral units and the corpses) has no commands: the original only warns
end;

function TWarMapCommandPanel.AttackFrame(ASlot: Integer): Integer;
var
  LUnit: PWarUnitComponent;
  LPlayer: PWarPlayerInfo;
  LHumans: Boolean;

  function Level(AHumansUpgrade, AOrcsUpgrade: Integer): Integer;
  begin
    if LHumans then
      Result := UpgradeLevel(LPlayer, AHumansUpgrade)
    else
      Result := UpgradeLevel(LPlayer, AOrcsUpgrade);
  end;

begin
  Result := 0;
  LUnit := @FContext.Pool.Slots[ASlot]^.UnitData;
  LPlayer := FContext.Players[LUnit^.Player];
  LHumans := LPlayer^.Race = wraHumans;
  case LUnit^.UnitType of
    WAR_UNIT_FOOTMAN, WAR_UNIT_GRUNT, WAR_UNIT_KNIGHT, WAR_UNIT_RAIDER, WAR_UNIT_CATAPULT_HUMANS,
    WAR_UNIT_CATAPULT_ORCS, WAR_UNIT_SCORPION, WAR_UNIT_SPIDER, WAR_UNIT_DAEMON:
      begin
        // the sword of the humans or the axe of the orcs, by the level of the upgrade
        if LHumans then
          Result := WAR_PORTRAIT_SWORD_1
        else
          Result := WAR_PORTRAIT_AXE_1;
        if Level(WAR_UPGRADE_SWORDS, WAR_UPGRADE_AXES) = 2 then
          Inc(Result, 2)
        else if Level(WAR_UPGRADE_SWORDS, WAR_UPGRADE_AXES) = 1 then
          Inc(Result, 1);
      end;
    WAR_UNIT_ARCHER, WAR_UNIT_SPEARMAN:
      begin
        if LHumans then
          Result := WAR_PORTRAIT_ARROW_1
        else
          Result := WAR_PORTRAIT_SPEAR_1;
        if Level(WAR_UPGRADE_ARROWS, WAR_UPGRADE_SPEARS) = 2 then
          Inc(Result, 2)
        else if Level(WAR_UPGRADE_ARROWS, WAR_UPGRADE_SPEARS) = 1 then
          Inc(Result, 1);
      end;
    WAR_UNIT_CONJURER, WAR_UNIT_WATER_ELEMENTAL:
      Result := WAR_PORTRAIT_ELEMENTAL_BLAST;
    WAR_UNIT_CLERIC:
      Result := WAR_PORTRAIT_HOLY_LANCE;
    WAR_UNIT_NECROLYTE:
      Result := WAR_PORTRAIT_SHADOW_SPEAR;
    WAR_UNIT_WARLOCK:
      Result := WAR_PORTRAIT_FIREBALL;
  end;
end;

function TWarMapCommandPanel.SlotData(ASlot, ACommand: Integer): TWarCommandSlot;
var
  LUnit: PWarUnitComponent;
  LPlayer: PWarPlayerInfo;
  LHuman: Boolean;
  LBase: TWarCommandBase;
  LMapped: Integer;
  LLevel: Integer;
  LUnitStats: TWarUnitStatsFull;
  LBuildingStats: TWarBuildingStatsFull;
  LUpgradeStats: TWarUpgradeStats;
begin
  // wu_getUnitCommandData: the base data of the command (key, tooltip) and the frame of its image
  LUnit := @FContext.Pool.Slots[ASlot]^.UnitData;
  LPlayer := FContext.Players[LUnit^.Player];
  LHuman := LPlayer^.Race = wraHumans;
  LBase := TWarCommandCatalog.Base(ACommand);
  Result := Default(TWarCommandSlot);
  Result.Command := ACommand;
  Result.HotKey := LBase.HotKey;
  Result.Tooltip := LBase.Tooltip;
  Result.HighlightIndex := LBase.HighlightIndex;
  Result.HighlightCount := LBase.HighlightCount;
  case ACommand of
    WAR_CMD_MOVE:
      if LHuman then
        Result.FrameIndex := WAR_PORTRAIT_MOVE_HUMANS
      else
        Result.FrameIndex := WAR_PORTRAIT_MOVE_ORCS;
    WAR_CMD_STOP:
      begin
        // the shield of the third level, of the second, or the first
        LLevel := UpgradeLevel(LPlayer, WAR_UPGRADE_SHIELD);
        if LLevel = 2 then
          if LHuman then
            Result.FrameIndex := WAR_PORTRAIT_SHIELD_3_HUMANS
          else
            Result.FrameIndex := WAR_PORTRAIT_SHIELD_3_ORCS
        else if LLevel = 1 then
          if LHuman then
            Result.FrameIndex := WAR_PORTRAIT_SHIELD_2_HUMANS
          else
            Result.FrameIndex := WAR_PORTRAIT_SHIELD_2_ORCS
        else if LHuman then
          Result.FrameIndex := WAR_PORTRAIT_SHIELD_1_HUMANS
        else
          Result.FrameIndex := WAR_PORTRAIT_SHIELD_1_ORCS;
      end;
    WAR_CMD_HARVEST:
      Result.FrameIndex := WAR_PORTRAIT_HARVEST;
    WAR_CMD_DELIVER:
      Result.FrameIndex := WAR_PORTRAIT_DELIVER;
    WAR_CMD_REPAIR:
      Result.FrameIndex := WAR_PORTRAIT_REPAIR;
    WAR_CMD_BUILD_BASIC:
      Result.FrameIndex := WAR_PORTRAIT_BUILD_BASIC;
    WAR_CMD_BUILD_ADVANCED:
      Result.FrameIndex := WAR_PORTRAIT_BUILD_ADVANCED;
    WAR_CMD_ATTACK:
      Result.FrameIndex := AttackFrame(ASlot);
    WAR_CMD_TRAIN_FOOTMAN .. WAR_CMD_TRAIN_NECROLYTE:
      begin
        LMapped := TWarCommandCatalog.MappedType(ACommand);
        LUnitStats := FContext.Database.GetUnitStats(LMapped);
        Result.Gold := LUnitStats.GoldCost;
        Result.Wood := LUnitStats.WoodCost;
        Result.FrameIndex := TWarCommandCatalog.PortraitOfUnit(LMapped);
      end;
    WAR_CMD_BUILD_FARM_HUMANS .. WAR_CMD_BUILD_BLACKSMITH_ORCS:
      begin
        LMapped := TWarCommandCatalog.MappedType(ACommand);
        LBuildingStats := FContext.Database.GetBuildingStats(LMapped);
        Result.Gold := LBuildingStats.GoldCost;
        Result.Wood := LBuildingStats.WoodCost;
        Result.FrameIndex := TWarCommandCatalog.PortraitOfUnit(LMapped);
      end;
    WAR_CMD_BUILD_ROAD:
      begin
        Result.Gold := 50;
        Result.FrameIndex := WAR_PORTRAIT_ROAD;
      end;
    WAR_CMD_BUILD_WALL:
      begin
        Result.Gold := WAR_WALL_GOLD_COST;
        Result.FrameIndex := WAR_PORTRAIT_WALL;
      end;
    WAR_CMD_UPGRADE_SWORDS .. WAR_CMD_UPGRADE_UNHOLY_ARMOR:
      begin
        LMapped := TWarCommandCatalog.MappedType(ACommand);
        LLevel := UpgradeLevel(LPlayer, LMapped);
        LUpgradeStats := FContext.Database.GetUpgradeStats(LMapped);
        // the cost of the level that the player has now (the table has two levels)
        if LLevel = 0 then
          Result.Gold := LUpgradeStats.GoldCost1
        else
          Result.Gold := LUpgradeStats.GoldCost2;
        Result.FrameIndex := TWarCommandCatalog.UpgradeFrame(LMapped, LLevel);
      end;
    WAR_CMD_SUMMON_SPIDER .. WAR_CMD_SUMMON_WATER_ELEMENTAL, WAR_CMD_SPELL_HEALING .. WAR_CMD_SPELL_UNHOLY_ARMOR:
      Result.FrameIndex := TWarCommandCatalog.SpellPortrait(TWarCommandCatalog.MappedType(ACommand));
    WAR_CMD_CANCEL:
      Result.FrameIndex := WAR_PORTRAIT_CANCEL;
  end;
end;

procedure TWarMapCommandPanel.Update(var APanel: TWarCommandPanel);
begin
  Update(APanel, WAR_CMD_NONE);
end;

procedure TWarMapCommandPanel.Update(var APanel: TWarCommandPanel; APendingCommand: Integer);
var
  LSlot: Integer;
  LEntity: PWarEntity;
  LCommands: array[0..5] of Integer;
  LOther: array[0..5] of Integer;
  LIndex: Integer;
  LOtherIndex: Integer;
  LCount: Integer;
  LFarms: Integer;
begin
  APanel.Clear;
  LCount := FContext.Selection.Count;
  if LCount = 0 then
    Exit;
  LSlot := FContext.Pool.FindSlot(FContext.Selection[0]);
  if LSlot = 0 then
    Exit;
  LEntity := FContext.Pool.Slots[LSlot];
  if not LEntity^.HasUnit then
    Exit;
  // a farm that is built: only the food (the original shows it even for the enemy)
  if (LEntity^.UnitData.UnitType = WAR_UNIT_FARM_HUMANS) or (LEntity^.UnitData.UnitType = WAR_UNIT_FARM_ORCS) then
    if not LEntity^.UnitData.Building then
    begin
      LFarms := FContext.Queries.CountBuildingsOfType(LEntity^.UnitData.Player, LEntity^.UnitData.UnitType, True);
      APanel.Texts[0] := 'FOOD USAGE:';
      APanel.TextsVisible[0] := True;
      APanel.Texts[1] := AnsiString(Format('GROWN %d', [LFarms * 4 + 1]));
      APanel.TextsVisible[1] := True;
      APanel.Texts[2] := AnsiString(Format(' USED %d', [FContext.Queries.CountDudes(LEntity^.UnitData.Player)]));
      APanel.TextsVisible[2] := True;
      Exit;
    end;
  if LEntity^.UnitData.UnitType = WAR_UNIT_GOLDMINE then
  begin
    APanel.Texts[0] := 'GOLD LEFT';
    APanel.TextsVisible[0] := True;
    APanel.Texts[3] := AnsiString(IntToStr(LEntity^.UnitData.Amount));
    APanel.TextsVisible[3] := True;
    Exit;
  end;
  GetCommands(LSlot, APendingCommand, LCommands);
  // with several selected, only the commands that all of them have
  for LIndex := 1 to LCount - 1 do
  begin
    LOtherIndex := FContext.Pool.FindSlot(FContext.Selection[LIndex]);
    if LOtherIndex = 0 then
      Continue;
    GetCommands(LOtherIndex, APendingCommand, LOther);
    for LSlot := 0 to 5 do
      if LCommands[LSlot] <> LOther[LSlot] then
        LCommands[LSlot] := WAR_CMD_NONE;
  end;
  LSlot := FContext.Pool.FindSlot(FContext.Selection[0]);
  for LIndex := 0 to 5 do
    if LCommands[LIndex] <> WAR_CMD_NONE then
    begin
      APanel.Slots[LIndex] := SlotData(LSlot, LCommands[LIndex]);
      APanel.SlotsActive[LIndex] := True;
    end;
end;

end.
