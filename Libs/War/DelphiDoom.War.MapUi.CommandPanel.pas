{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the panel of the commands of the selection        }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (updateCommandButtons) and            }
{  war_units.c (wu_getUnitCommands, wu_getUnitCommandData, commandsBaseData),   }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                         }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.CommandPanel;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.MapUi.Types;

type
  /// <summary>
  ///   updateCommandButtons for a selection when no command waits for a target: the six buttons and the lines of text.
  ///   Ported: the farm and the gold mine (text only), and the commands of the units that move: move, stop, attack, repair,
  ///   harvest or deliver, build basic and build advanced, and the commands that are the same for the spell casters while
  ///   the player has researched none of their spells. NOT ported (the panel stays empty for them): the buildings (train,
  ///   upgrade, cancel, wall, road), the spells and the summons, and the menus that a command with a target opens
  ///   (build, cast): they need the pending command of the interface, which is not here yet
  /// </summary>
  TWarMapCommandPanel = class
  strict private
    FContext: TWarModelContext;
    function GetCommands(ASlot: Integer; out ACommands: array of Integer): Boolean;
    function SlotData(ASlot, ACommand: Integer): TWarCommandSlot;
    function CarryingResources(ASlot: Integer): Boolean;
    function PlayerHasBuilding(APlayer, AUnitType: Integer): Boolean;
    function ResearchedAny(APlayer: Integer): Boolean;
    /// <summary>getUpgradeLevel: the level of the upgrade of the player (the array is by upgrade / 2)</summary>
    function UpgradeLevel(APlayer, AUpgrade: Integer): Integer;
  public
    constructor Create(const AContext: TWarModelContext);
    /// <summary>updateCommandButtons: the panel for the selection of the context</summary>
    procedure Update(var APanel: TWarCommandPanel);
  end;

implementation

uses
  System.Math, DelphiDoom.War.Types, DelphiDoom.War.Ui.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Commands.Types,
  DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.MapUi.UnitNames.Data;

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

function TWarMapCommandPanel.UpgradeLevel(APlayer, AUpgrade: Integer): Integer;
begin
  Result := FContext.Players[APlayer]^.Upgrades[AUpgrade div 2].Level;
end;

function TWarMapCommandPanel.ResearchedAny(APlayer: Integer): Boolean;
var
  LUpgrade: Integer;
begin
  Result := False;
  for LUpgrade := 0 to WAR_MAX_UPGRADES_COUNT - 1 do
    if (FContext.Players[APlayer]^.Upgrades[LUpgrade].Allowed > 0) and
      (FContext.Players[APlayer]^.Upgrades[LUpgrade].Level > 0) then
      Exit(True);
end;

function TWarMapCommandPanel.GetCommands(ASlot: Integer; out ACommands: array of Integer): Boolean;
var
  LUnit: PWarUnitComponent;
  LPlayer: PWarPlayerInfo;
  LIndex: Integer;
begin
  Result := True;
  for LIndex := 0 to High(ACommands) do
    ACommands[LIndex] := WAR_COMMAND_NONE;
  LUnit := @FContext.Pool.Slots[ASlot]^.UnitData;
  LPlayer := FContext.Players[LUnit^.Player];
  // a unit of a race that is not the player's has no commands
  if LPlayer^.Race <> TWarUnitClassifier.RaceOf(LUnit^.UnitType) then
    Exit;
  case LUnit^.UnitType of
    WAR_UNIT_FOOTMAN, WAR_UNIT_GRUNT, WAR_UNIT_CATAPULT_HUMANS, WAR_UNIT_CATAPULT_ORCS, WAR_UNIT_KNIGHT,
    WAR_UNIT_RAIDER, WAR_UNIT_ARCHER, WAR_UNIT_SPEARMAN, WAR_UNIT_WATER_ELEMENTAL, WAR_UNIT_DAEMON,
    WAR_UNIT_SCORPION, WAR_UNIT_SPIDER, WAR_UNIT_SKELETON:
      begin
        ACommands[0] := WAR_COMMAND_MOVE;
        ACommands[1] := WAR_COMMAND_STOP;
        ACommands[2] := WAR_COMMAND_ATTACK;
      end;
    WAR_UNIT_PEASANT, WAR_UNIT_PEON:
      begin
        ACommands[0] := WAR_COMMAND_MOVE;
        ACommands[1] := WAR_COMMAND_STOP;
        ACommands[2] := WAR_COMMAND_REPAIR;
        if CarryingResources(ASlot) then
          ACommands[3] := WAR_COMMAND_DELIVER
        else
          ACommands[3] := WAR_COMMAND_HARVEST;
        ACommands[4] := WAR_COMMAND_BUILD_BASIC;
        if (LUnit^.UnitType = WAR_UNIT_PEASANT) and PlayerHasBuilding(LUnit^.Player, WAR_UNIT_LUMBERMILL_HUMANS) then
          ACommands[5] := WAR_COMMAND_BUILD_ADVANCED
        else if (LUnit^.UnitType = WAR_UNIT_PEON) and PlayerHasBuilding(LUnit^.Player, WAR_UNIT_LUMBERMILL_ORCS) then
          ACommands[5] := WAR_COMMAND_BUILD_ADVANCED;
      end;
    WAR_UNIT_CONJURER, WAR_UNIT_WARLOCK, WAR_UNIT_CLERIC, WAR_UNIT_NECROLYTE:
      begin
        // the first three buttons; the spells only once researched (not ported: the panel is empty then)
        if ResearchedAny(LUnit^.Player) then
          Exit(False);
        ACommands[0] := WAR_COMMAND_MOVE;
        ACommands[1] := WAR_COMMAND_STOP;
        ACommands[2] := WAR_COMMAND_ATTACK;
      end;
  else
    // the buildings and the rest: not ported
    Result := False;
  end;
end;

function TWarMapCommandPanel.SlotData(ASlot, ACommand: Integer): TWarCommandSlot;
var
  LUnit: PWarUnitComponent;
  LHuman: Boolean;
  LLevel: Integer;
begin
  // wu_getUnitCommandData: the base data of the command (key, tooltip) and the frame of its image
  LUnit := @FContext.Pool.Slots[ASlot]^.UnitData;
  LHuman := FContext.Players[LUnit^.Player]^.Race = wraHumans;
  Result := Default(TWarCommandSlot);
  Result.Command := ACommand;
  Result.HighlightIndex := 0;
  Result.HighlightCount := 1;
  case ACommand of
    WAR_COMMAND_MOVE:
      begin
        Result.HotKey := wkM;
        Result.Tooltip := 'MOVE';
        if LHuman then
          Result.FrameIndex := WAR_PORTRAIT_MOVE_HUMANS
        else
          Result.FrameIndex := WAR_PORTRAIT_MOVE_ORCS;
      end;
    WAR_COMMAND_STOP:
      begin
        Result.HotKey := wkS;
        Result.Tooltip := 'STOP';
        LLevel := UpgradeLevel(LUnit^.Player, WAR_UPGRADE_SHIELD);
        if LHuman then
          Result.FrameIndex := WAR_PORTRAIT_SHIELD_1_HUMANS + Min(LLevel, 2)
        else
          Result.FrameIndex := WAR_PORTRAIT_SHIELD_1_ORCS + Min(LLevel, 2);
      end;
    WAR_COMMAND_HARVEST:
      begin
        Result.HotKey := wkH;
        Result.Tooltip := 'HARVEST LUMBER/MINE GOLD';
        Result.FrameIndex := WAR_PORTRAIT_HARVEST;
      end;
    WAR_COMMAND_DELIVER:
      begin
        Result.HotKey := wkT;
        Result.HighlightIndex := 16;
        Result.Tooltip := 'RETURN GOODS TO TOWN HALL';
        Result.FrameIndex := WAR_PORTRAIT_DELIVER;
      end;
    WAR_COMMAND_REPAIR:
      begin
        Result.HotKey := wkR;
        Result.Tooltip := 'REPAIR';
        Result.FrameIndex := WAR_PORTRAIT_REPAIR;
      end;
    WAR_COMMAND_BUILD_BASIC:
      begin
        Result.HotKey := wkB;
        Result.Tooltip := 'BUILD BASIC STRUCTURE';
        Result.FrameIndex := WAR_PORTRAIT_BUILD_BASIC;
      end;
    WAR_COMMAND_BUILD_ADVANCED:
      begin
        Result.HotKey := wkA;
        Result.HighlightIndex := 6;
        Result.Tooltip := 'BUILD ADVANCED STRUCTURE';
        Result.FrameIndex := WAR_PORTRAIT_BUILD_ADVANCED;
      end;
    WAR_COMMAND_ATTACK:
      begin
        Result.HotKey := wkA;
        Result.Tooltip := 'ATTACK';
        case LUnit^.UnitType of
          WAR_UNIT_FOOTMAN, WAR_UNIT_GRUNT, WAR_UNIT_KNIGHT, WAR_UNIT_RAIDER, WAR_UNIT_CATAPULT_HUMANS,
          WAR_UNIT_CATAPULT_ORCS, WAR_UNIT_SCORPION, WAR_UNIT_SPIDER, WAR_UNIT_DAEMON:
            // the sword of the humans or the axe of the orcs, by the level of the upgrade
            if LHuman then
              Result.FrameIndex := WAR_PORTRAIT_SWORD_1 + Min(UpgradeLevel(LUnit^.Player, WAR_UPGRADE_SWORDS), 2)
            else
              Result.FrameIndex := WAR_PORTRAIT_AXE_1 + Min(UpgradeLevel(LUnit^.Player, WAR_UPGRADE_AXES), 2);
          WAR_UNIT_ARCHER, WAR_UNIT_SPEARMAN:
            if LHuman then
              Result.FrameIndex := WAR_PORTRAIT_ARROW_1 + Min(UpgradeLevel(LUnit^.Player, WAR_UPGRADE_ARROWS), 2)
            else
              Result.FrameIndex := WAR_PORTRAIT_SPEAR_1 + Min(UpgradeLevel(LUnit^.Player, WAR_UPGRADE_SPEARS), 2);
          WAR_UNIT_CONJURER, WAR_UNIT_WATER_ELEMENTAL:
            Result.FrameIndex := WAR_PORTRAIT_ELEMENTAL_BLAST;
          WAR_UNIT_CLERIC:
            Result.FrameIndex := WAR_PORTRAIT_HOLY_LANCE;
          WAR_UNIT_NECROLYTE:
            Result.FrameIndex := WAR_PORTRAIT_SHADOW_SPEAR;
          WAR_UNIT_WARLOCK:
            Result.FrameIndex := WAR_PORTRAIT_FIREBALL;
        end;
      end;
  end;
end;

procedure TWarMapCommandPanel.Update(var APanel: TWarCommandPanel);
var
  LSelection: TArray<Word>;
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
  if not GetCommands(LSlot, LCommands) then
    Exit;
  // with several selected, only the commands that all of them have
  for LIndex := 1 to LCount - 1 do
  begin
    LOtherIndex := FContext.Pool.FindSlot(FContext.Selection[LIndex]);
    if LOtherIndex = 0 then
      Continue;
    if not GetCommands(LOtherIndex, LOther) then
      Exit;
    for LSlot := 0 to 5 do
      if LCommands[LSlot] <> LOther[LSlot] then
        LCommands[LSlot] := WAR_COMMAND_NONE;
  end;
  LSlot := FContext.Pool.FindSlot(FContext.Selection[0]);
  for LIndex := 0 to 5 do
    if LCommands[LIndex] <> WAR_COMMAND_NONE then
    begin
      APanel.Slots[LIndex] := SlotData(LSlot, LCommands[LIndex]);
      APanel.SlotsActive[LIndex] := True;
    end;
end;

end.
