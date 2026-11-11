{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the units and items of a battle       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.UnitDeployer;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.MapData, DelphiDoom.XcomMod.RuleInventory,
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomMod.RuleUnit, DelphiDoom.XcomMod.Armor,
  DelphiDoom.XcomMod.AlienDeployment, DelphiDoom.XcomMod.AlienRace, DelphiDoom.XcomMod.RulesetSettings,
  DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomSave.Node, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomSave.Vehicle, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.EquipmentLayoutItem,
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.AIModule,
  DelphiDoom.XcomBattle.GeneratorState;

type
  /// <summary>
  ///   Puts the units and the items on the map of a battle (the units part of BattlescapeGenerator): the soldiers
  ///   and vehicles of the craft or base, the equipment with the layouts, the aliens of the deployment with their
  ///   weapons, the civilians, and the fuel and explosion of the power sources of a UFO
  /// </summary>
  TXcomUnitDeployer = class
  strict private
    FState: TXcomGeneratorState;
    function Ground: TXcomRuleInventory;
    function MakeSpecialItem(const ARules: TXcomRuleItem; const AUnit: TXcomBattleUnit): TXcomBattleItem;
    procedure FinishUnit(const AUnit: TXcomBattleUnit);
    function PlaceItemByLayout(const AItem: TXcomBattleItem): Boolean;
    procedure LoadWeapons;
    function AddXcomVehicle(const AVehicle: TXcomVehicle): TXcomBattleUnit;
    function AddXcomUnit(const AUnit: TXcomBattleUnit): TXcomBattleUnit;
    function CanPlaceXcomUnit(const ATile: TXcomTile): Boolean;
    function AddAlien(const ARules: TXcomRuleUnit; AAlienRank: Integer; AOutside: Boolean): TXcomBattleUnit;
    function AddCivilian(const ARules: TXcomRuleUnit): TXcomBattleUnit;
    procedure AddBuiltInWeapons(const AUnit: TXcomBattleUnit; const ARules: TXcomRuleUnit; ALevel: Integer);
    function IsResearched(const ARequirements: TArray<string>): Boolean;
    function UnitRules(const AType: string): TXcomRuleUnit;
    function ArmorRules(const AName: string): TXcomArmor;
    function NoAdjustment: TXcomStatAdjustment;
  public
    constructor Create(const AState: TXcomGeneratorState);
    /// <summary>deployXCOM: the soldiers, vehicles and equipment of the craft (or base) onto the map</summary>
    procedure DeployXcom;
    /// <summary>placeUnitNearFriend: next to a unit of its side that is on the map (up to ten tries)</summary>
    function PlaceUnitNearFriend(const AUnit: TXcomBattleUnit): Boolean;
    /// <summary>deployAliens</summary>
    procedure DeployAliens(const ADeployment: TXcomAlienDeployment);
    /// <summary>deployCivilians</summary>
    procedure DeployCivilians(AMaximum: Integer);
    /// <summary>fuelPowerSources</summary>
    procedure FuelPowerSources;
    /// <summary>explodePowerSources</summary>
    procedure ExplodePowerSources;
  end;

implementation

const
  NR_XCOM = 1;
  /// <summary>SpecialTileType UFO_POWER_SOURCE</summary>
  SPECIAL_UFO_POWER_SOURCE = 2;
  SPECIAL_START_POINT = 1;
  DIFFICULTY_VETERAN = 2;
  DIFFICULTY_SUPERHUMAN = 4;
  SNoXcomUnits = 'Map generator encountered an error: no xcom units could be placed on the map.';
  SUnknownRace = 'Map generator encountered an error: Unknown race: %s defined in deployment: %s';
  SNoItemSet = 'Unit generator encountered an error: item set not defined';
  SUnitNotFound = 'Unit %s not found.';
  SArmorNotFound = 'Armor %s not found.';
  SNoInventoryTile = 'Map generator encountered an error: no tile to put the equipment on.';
  SNoCivilianTypes = 'Map generator encountered an error: the terrain has no civilian types.';

constructor TXcomUnitDeployer.Create(const AState: TXcomGeneratorState);
begin
  inherited Create;
  FState := AState;
end;

function TXcomUnitDeployer.Ground: TXcomRuleInventory;
begin
  Result := FState.Equipper.Inventory('STR_GROUND');
end;

function TXcomUnitDeployer.UnitRules(const AType: string): TXcomRuleUnit;
begin
  Result := FState.Ruleset.Units.Find(AType);
  if not Assigned(Result) then
    raise EXcomBattleException.CreateFmt(SUnitNotFound, [AType]);
end;

function TXcomUnitDeployer.ArmorRules(const AName: string): TXcomArmor;
begin
  Result := FState.Ruleset.Armors.Find(AName);
  if not Assigned(Result) then
    raise EXcomBattleException.CreateFmt(SArmorNotFound, [AName]);
end;

function TXcomUnitDeployer.NoAdjustment: TXcomStatAdjustment;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.AimAndArmorMultiplier := 1.0;
end;

function TXcomUnitDeployer.MakeSpecialItem(const ARules: TXcomRuleItem;
  const AUnit: TXcomBattleUnit): TXcomBattleItem;
begin
  // createItem: the item is the unit's own and outside the inventory (the C++ calls removeItem on it)
  Result := FState.NewItem(ARules);
  Result.SetOwner(AUnit);
  FState.Save.Deleted.Add(Result);
end;

procedure TXcomUnitDeployer.FinishUnit(const AUnit: TXcomBattleUnit);
begin
  AUnit.SetSpecialWeapon(FState.Ruleset,
    function(ARules: TXcomRuleItem): TXcomBattleItem
    begin
      Result := MakeSpecialItem(ARules, AUnit);
    end);
end;

function TXcomUnitDeployer.IsResearched(const ARequirements: TArray<string>): Boolean;
var
  LMatches: TList<string>;
  LName: string;
  LIndex: Integer;
  LItem: Integer;
begin
  if Length(ARequirements) = 0 then
    Exit(True);
  LMatches := TList<string>.Create;
  try
    LMatches.AddRange(ARequirements);
    for LItem := 0 to FState.Game.Discovered.Count - 1 do
    begin
      LName := FState.Game.Discovered[LItem].Name;
      for LIndex := 0 to LMatches.Count - 1 do
        if LMatches[LIndex] = LName then
        begin
          LMatches.Delete(LIndex);
          Break;
        end;
      if LMatches.Count = 0 then
        Exit(True);
    end;
    Result := False;
  finally
    LMatches.Free;
  end;
end;

function TXcomUnitDeployer.PlaceItemByLayout(const AItem: TXcomBattleItem): Boolean;
var
  LRightHand: TXcomRuleInventory;
  LUnit: TXcomBattleUnit;
  LLayout: TXcomEquipmentLayoutItem;
  LLoaded: Boolean;
  LOther: TXcomBattleItem;
  LIndex: Integer;
begin
  if AItem.Slot = Ground then
  begin
    LRightHand := FState.Equipper.Inventory('STR_RIGHT_HAND');
    for LUnit in FState.Save.Units do
    begin
      if (LUnit.Armor.Size > 1) or (not Assigned(LUnit.GeoscapeSoldier)) or
        (LUnit.GeoscapeSoldier.EquipmentLayout.Count = 0) then
        Continue;
      for LLayout in LUnit.GeoscapeSoldier.EquipmentLayout do
      begin
        if (AItem.Rules.ItemType <> LLayout.ItemType) or
          Assigned(LUnit.GetItem(LLayout.Slot, LLayout.SlotX, LLayout.SlotY)) then
          Continue;
        if LLayout.AmmoItem = 'NONE' then
          LLoaded := True
        else
        begin
          LLoaded := False;
          LIndex := 0;
          while (not LLoaded) and (LIndex < FState.CraftInventoryTile.Inventory.Count) do
          begin
            LOther := FState.CraftInventoryTile.Inventory[LIndex];
            if (LOther.Rules.ItemType = LLayout.AmmoItem) and (LOther.Slot = Ground) and
              (AItem.SetAmmoItem(LOther) = 0) then
            begin
              FState.Save.Items.Add(LOther);
              LOther.Slot := LRightHand;
              LLoaded := True;
            end;
            Inc(LIndex);
          end;
        end;
        if LLoaded then
        begin
          AItem.MoveToOwner(LUnit);
          AItem.Slot := FState.Equipper.Inventory(LLayout.Slot);
          AItem.SlotX := LLayout.SlotX;
          AItem.SlotY := LLayout.SlotY;
          FState.Save.Items.Add(AItem);
          Exit(True);
        end;
      end;
    end;
  end;
  Result := False;
end;

procedure TXcomUnitDeployer.LoadWeapons;
var
  LIndex: Integer;
  LItem: TXcomBattleItem;
  LOther: TXcomBattleItem;
  LLoaded: Boolean;
  LOtherIndex: Integer;
  LInventory: TList<TXcomBattleItem>;
begin
  LInventory := FState.CraftInventoryTile.Inventory;
  for LIndex := 0 to LInventory.Count - 1 do
  begin
    LItem := LInventory[LIndex];
    if (not LItem.Rules.FixedWeapon) and (Length(LItem.Rules.CompatibleAmmo) > 0) and
      (not Assigned(LItem.AmmoItem)) and ((LItem.Rules.BattleType = TXcomRuleItem.BT_FIREARM) or
      (LItem.Rules.BattleType = TXcomRuleItem.BT_MELEE)) then
    begin
      LLoaded := False;
      LOtherIndex := 0;
      while (LOtherIndex < LInventory.Count) and (not LLoaded) do
      begin
        LOther := LInventory[LOtherIndex];
        if (LOther.Slot = Ground) and (LItem.SetAmmoItem(LOther) = 0) then
        begin
          FState.Save.Items.Add(LOther);
          LOther.Slot := FState.Equipper.Inventory('STR_RIGHT_HAND');
          LLoaded := True;
        end;
        Inc(LOtherIndex);
      end;
    end;
  end;
  LIndex := 0;
  while LIndex < LInventory.Count do
  begin
    if LInventory[LIndex].Slot <> Ground then
      LInventory.Delete(LIndex)
    else
      Inc(LIndex);
  end;
end;

function TXcomUnitDeployer.AddXcomVehicle(const AVehicle: TXcomVehicle): TXcomBattleUnit;
var
  LVehicle: string;
  LRules: TXcomRuleUnit;
  LItem: TXcomBattleItem;
  LAmmoItem: TXcomBattleItem;
  LVehicleItem: TXcomRuleItem;
  LWeapons: TArray<string>;
  LName: string;
  LRuleItem: TXcomRuleItem;
  LWeapon: TXcomBattleItem;
begin
  LVehicle := AVehicle.Rules.ItemType;
  LRules := UnitRules(LVehicle);
  Inc(FState.UnitSequence);
  Result := AddXcomUnit(TXcomBattleUnit.Create(FState.Context, LRules, FACTION_PLAYER, FState.UnitSequence - 1,
    ArmorRules(LRules.Armor), NoAdjustment, FState.Save.Depth));
  if Assigned(Result) then
  begin
    LVehicleItem := FState.ItemRules(LVehicle);
    LItem := FState.NewItem(LVehicleItem);
    FState.Equipper.AddItem(LItem, Result);
    if Length(LVehicleItem.CompatibleAmmo) > 0 then
    begin
      LAmmoItem := FState.NewItem(FState.ItemRules(LVehicleItem.CompatibleAmmo[0]));
      FState.Equipper.AddItem(LAmmoItem, Result);
      LAmmoItem.SetAmmoQuantity(AVehicle.Ammo);
    end;
    Result.TurretType := LVehicleItem.TurretType;
    if Length(LRules.BuiltInWeapons) > 0 then
    begin
      LWeapons := LRules.BuiltInWeapons[0];
      for LName in LWeapons do
      begin
        LRuleItem := FState.Ruleset.Items.Find(LName);
        if Assigned(LRuleItem) then
        begin
          LWeapon := FState.NewItem(LRuleItem);
          FState.Equipper.AddItem(LWeapon, Result);
        end;
      end;
    end;
  end;
end;

function TXcomUnitDeployer.CanPlaceXcomUnit(const ATile: TXcomTile): Boolean;
begin
  if Assigned(ATile) and Assigned(ATile.MapData[XCOM_PART_FLOOR]) and
    (ATile.MapData[XCOM_PART_FLOOR].SpecialType = SPECIAL_START_POINT) and
    (not Assigned(ATile.MapData[XCOM_PART_OBJECT])) and
    (ATile.MapData[XCOM_PART_FLOOR].GetTuCost(MT_WALK) < 255) then
  begin
    if not Assigned(FState.CraftInventoryTile) then
      FState.CraftInventoryTile := ATile;
    Exit(True);
  end;
  Result := False;
end;

function TXcomUnitDeployer.AddXcomUnit(const AUnit: TXcomBattleUnit): TXcomBattleUnit;
var
  LNode: TXcomNode;
  LRow: TArray<Integer>;
  LPosition: TXcomPosition;
  LCanPlace: Boolean;
  LX: Integer;
  LY: Integer;
  LIndex: Integer;
begin
  if FState.BaseInventory then
  begin
    if AUnit.HasInventory then
    begin
      FState.Save.Units.Add(AUnit);
      FinishUnit(AUnit);
      Exit(AUnit);
    end;
  end
  else
  begin
    if (not Assigned(FState.Craft)) or (not FState.CraftDeployed) then
    begin
      LNode := FState.Save.GetSpawnNode(NR_XCOM, AUnit);
      if Assigned(LNode) then
      begin
        FState.Save.SetUnitPosition(AUnit, LNode.Position);
        FState.CraftInventoryTile := FState.Save.TileAt(LNode.Position);
        AUnit.SetDirection(FState.Random.Generate(0, 7));
        FState.Save.Units.Add(AUnit);
        FState.TileEngine.CalculateFov(AUnit);
        FinishUnit(AUnit);
        Exit(AUnit);
      end
      else if FState.Save.MissionType <> 'STR_BASE_DEFENSE' then
      begin
        if PlaceUnitNearFriend(AUnit) then
        begin
          FState.CraftInventoryTile := FState.Save.TileAt(AUnit.Position);
          AUnit.SetDirection(FState.Random.Generate(0, 7));
          FState.Save.Units.Add(AUnit);
          FState.TileEngine.CalculateFov(AUnit);
          FinishUnit(AUnit);
          Exit(AUnit);
        end;
      end;
    end
    else if Assigned(FState.Craft) and (Length(FState.Craft.Rules.Deployment) > 0) then
    begin
      for LRow in FState.Craft.Rules.Deployment do
      begin
        LPosition := TXcomPosition.Make(LRow[0] + FState.CraftPos.X * 10, LRow[1] + FState.CraftPos.Y * 10,
          LRow[2] + FState.CraftZ);
        LCanPlace := True;
        for LX := 0 to AUnit.Armor.Size - 1 do
          for LY := 0 to AUnit.Armor.Size - 1 do
            LCanPlace := LCanPlace and CanPlaceXcomUnit(FState.Save.TileAt(LPosition + TXcomPosition.Make(LX, LY, 0)));
        if LCanPlace then
        begin
          if FState.Save.SetUnitPosition(AUnit, LPosition) then
          begin
            FState.Save.Units.Add(AUnit);
            AUnit.SetDirection(LRow[3]);
            FinishUnit(AUnit);
            Exit(AUnit);
          end;
        end;
      end;
    end
    else
    begin
      for LIndex := 0 to FState.MapSizeX * FState.MapSizeY * FState.MapSizeZ - 1 do
      begin
        if CanPlaceXcomUnit(FState.Save.TileByIndex(LIndex)) then
        begin
          if FState.Save.SetUnitPosition(AUnit, FState.Save.TileByIndex(LIndex).Position) then
          begin
            FState.Save.Units.Add(AUnit);
            FinishUnit(AUnit);
            Exit(AUnit);
          end;
        end;
      end;
    end;
  end;
  AUnit.Free;
  Result := nil;
end;

procedure TXcomUnitDeployer.DeployXcom;
var
  LBase: TXcomBase;
  LVehicle: TXcomVehicle;
  LCraft: TXcomCraft;
  LUnit: TXcomBattleUnit;
  LSoldier: TXcomSoldier;
  LIndex: Integer;
  LCount: Integer;
  LPair: Integer;
  LRules: TXcomRuleItem;
  LItem: TXcomBattleItem;
  LName: string;
  LContents: TArray<TPair<string, Integer>>;
  LInventory: TList<TXcomBattleItem>;
  LInCraft: Boolean;
  LStorage: Integer;
  LUnits: TArray<TXcomBattleUnit>;
  LNames: TArray<string>;
begin
  if Assigned(FState.Craft) then
    FState.Base := FState.Craft.Base as TXcomBase;
  LBase := FState.Base;
  if not FState.BaseInventory then
  begin
    if Assigned(FState.Craft) then
    begin
      for LVehicle in FState.Craft.Vehicles do
      begin
        LUnit := AddXcomVehicle(LVehicle);
        if Assigned(LUnit) and (not Assigned(FState.Save.SelectedUnit)) then
          FState.Save.SelectedUnit := LUnit;
      end;
    end
    else if Assigned(LBase) then
    begin
      // the vehicles of the base come from Base::setupDefenses, which the saved game does not keep
      if FState.Game.MonthsPassed = -1 then
      begin
        for LCraft in LBase.Crafts do
          for LVehicle in LCraft.Vehicles do
          begin
            LUnit := AddXcomVehicle(LVehicle);
            if Assigned(LUnit) and (not Assigned(FState.Save.SelectedUnit)) then
              FState.Save.SelectedUnit := LUnit;
          end;
      end;
    end;
  end;
  for LSoldier in LBase.Soldiers do
  begin
    LInCraft := Assigned(FState.Craft) and (LSoldier.Craft = FState.Craft);
    if LInCraft or ((not Assigned(FState.Craft)) and (LSoldier.WoundRecovery = 0) and
      ((not Assigned(LSoldier.Craft)) or ((LSoldier.Craft as TXcomCraft).Status <> 'STR_OUT'))) then
    begin
      LUnit := AddXcomUnit(TXcomBattleUnit.Create(FState.Context, LSoldier, FState.Save.Depth));
      if Assigned(LUnit) and (not Assigned(FState.Save.SelectedUnit)) then
        FState.Save.SelectedUnit := LUnit;
    end;
  end;
  if FState.Save.Units.Count = 0 then
    raise EXcomBattleException.Create(SNoXcomUnits);
  if not Assigned(FState.CraftInventoryTile) then
    raise EXcomBattleException.Create(SNoInventoryTile);
  for LUnit in FState.Save.Units do
    if LUnit.Faction = FACTION_PLAYER then
    begin
      FState.CraftInventoryTile.SetUnit(LUnit);
      LUnit.Visible := False;
    end;
  if Assigned(FState.Craft) then
  begin
    for LPair := 0 to FState.Craft.Items.Contents.Count - 1 do
      for LCount := 0 to FState.Craft.Items.Contents.Value(LPair) - 1 do
        FState.CraftInventoryTile.AddItem(FState.NewItem(FState.ItemRules(FState.Craft.Items.Contents.Key(LPair))),
          Ground);
  end
  else
  begin
    if FState.Game.MonthsPassed <> -1 then
    begin
      LNames := nil;
      for LPair := 0 to LBase.StorageItems.Contents.Count - 1 do
      begin
        SetLength(LNames, Length(LNames) + 1);
        LNames[High(LNames)] := LBase.StorageItems.Contents.Key(LPair);
      end;
      for LName in LNames do
      begin
        LRules := FState.ItemRules(LName);
        if (not LRules.IgnoreInBaseDefense) and (LRules.BigSprite > -1) and
          (LRules.BattleType <> TXcomRuleItem.BT_NONE) and (LRules.BattleType <> TXcomRuleItem.BT_CORPSE) and
          (not LRules.FixedWeapon) and IsResearched(LRules.Requirements) then
        begin
          LStorage := LBase.StorageItems.GetItem(LName);
          for LCount := 0 to LStorage - 1 do
            FState.CraftInventoryTile.AddItem(FState.NewItem(LRules), Ground);
          LBase.StorageItems.RemoveItem(LName, LStorage);
        end;
      end;
    end;
    for LCraft in LBase.Crafts do
    begin
      if LCraft.Status = 'STR_OUT' then
        Continue;
      for LPair := 0 to LCraft.Items.Contents.Count - 1 do
        for LCount := 0 to LCraft.Items.Contents.Value(LPair) - 1 do
          FState.CraftInventoryTile.AddItem(FState.NewItem(FState.ItemRules(LCraft.Items.Contents.Key(LPair))),
            Ground);
    end;
  end;
  LInventory := FState.CraftInventoryTile.Inventory;
  for LIndex := 0 to LInventory.Count - 1 do
  begin
    LItem := LInventory[LIndex];
    LItem.XcomProperty := True;
    if LItem.Rules.BattleType = TXcomRuleItem.BT_AMMO then
      Continue;
    PlaceItemByLayout(LItem);
  end;
  LoadWeapons;
  LInventory := FState.CraftInventoryTile.Inventory;
  for LIndex := 0 to LInventory.Count - 1 do
  begin
    LItem := LInventory[LIndex];
    if LItem.Rules.BattleType <> TXcomRuleItem.BT_AMMO then
      Continue;
    PlaceItemByLayout(LItem);
  end;
  SetLength(LUnits, FState.Save.Units.Count);
  for LIndex := 0 to FState.Save.Units.Count - 1 do
    LUnits[LIndex] := FState.Save.Units[LIndex];
  FState.Equipper.AutoEquip(LUnits, FState.CraftInventoryTile.Inventory, Ground, FState.WorldShade, False);
end;

function TXcomUnitDeployer.PlaceUnitNearFriend(const AUnit: TXcomBattleUnit): Boolean;
var
  LAttempt: Integer;
  LEntry: TXcomPosition;
  LTries: Integer;
  LLarge: Boolean;
  LOther: TXcomBattleUnit;
begin
  if FState.Save.Units.Count = 0 then
    Exit(False);
  for LAttempt := 0 to 9 do
  begin
    LEntry := TXcomPosition.Make(-1, -1, -1);
    LTries := 100;
    LLarge := False;
    while (LEntry = TXcomPosition.Make(-1, -1, -1)) and (LTries <> 0) do
    begin
      LOther := FState.Save.Units[FState.Random.Generate(0, FState.Save.Units.Count - 1)];
      if (LOther.Faction = AUnit.Faction) and (LOther.Position <> TXcomPosition.Make(-1, -1, -1)) and
        (LOther.Armor.Size >= AUnit.Armor.Size) then
      begin
        LEntry := LOther.Position;
        LLarge := LOther.Armor.Size <> 1;
      end;
      Dec(LTries);
    end;
    if (LTries <> 0) and FState.Save.PlaceUnitNearPosition(AUnit, LEntry, LLarge) then
      Exit(True);
  end;
  Result := False;
end;

function TXcomUnitDeployer.AddAlien(const ARules: TXcomRuleUnit; AAlienRank: Integer;
  AOutside: Boolean): TXcomBattleUnit;
var
  LNode: TXcomNode;
  LIndex: Integer;
  LDifficulty: Integer;
  LDirection: Integer;
  LCraftPosition: TXcomPosition;
  LBasicLook: Integer;
  LUtileLook: Integer;
begin
  // std::rand() % 8 twice in the arguments of setRecolor: the compiler evaluates the last argument first
  LUtileLook := FState.LegacyRandom.Next mod 8;
  LBasicLook := FState.LegacyRandom.Next mod 8;
  Inc(FState.UnitSequence);
  Result := TXcomBattleUnit.Create(FState.Context, ARules, FACTION_HOSTILE, FState.UnitSequence - 1,
    ArmorRules(ARules.Armor), FState.Ruleset.Settings.StatAdjustment[FState.Game.Difficulty], FState.Save.Depth,
    LBasicLook, LUtileLook, -1);
  LNode := nil;
  if AAlienRank > 7 then
    AAlienRank := 7;
  LIndex := 0;
  while (LIndex < 7) and (not Assigned(LNode)) do
  begin
    if AOutside then
      LNode := FState.Save.GetSpawnNode(0, Result)
    else
      LNode := FState.Save.GetSpawnNode(NODE_RANK[AAlienRank][LIndex], Result);
    Inc(LIndex);
  end;
  LDifficulty := FState.Ruleset.Settings.DifficultyCoefficient[FState.Game.Difficulty];
  if Assigned(LNode) and FState.Save.SetUnitPosition(Result, LNode.Position) then
  begin
    Result.AI := TXcomAIModule.Create(Result, LNode);
    Result.RankInt := AAlienRank;
    FinishUnit(Result);
    LDirection := FState.TileEngine.FaceWindow(LNode.Position);
    LCraftPosition := FState.Save.Units[0].Position;
    if (FState.TileEngine.Distance(LNode.Position, LCraftPosition) <= 20) and
      TXcomBattleRandom.Percent(FState.Random, 20 * LDifficulty) then
      LDirection := Result.DirectionTo(LCraftPosition);
    if LDirection <> -1 then
      Result.SetDirection(LDirection)
    else
      Result.SetDirection(FState.Random.Generate(0, 7));
    FState.Save.Units.Add(Result);
  end
  else
  begin
    if FState.Ruleset.Settings.DifficultyDemigod and PlaceUnitNearFriend(Result) then
    begin
      Result.AI := TXcomAIModule.Create(Result, nil);
      Result.RankInt := AAlienRank;
      FinishUnit(Result);
      LDirection := FState.TileEngine.FaceWindow(Result.Position);
      LCraftPosition := FState.Save.Units[0].Position;
      if (FState.TileEngine.Distance(Result.Position, LCraftPosition) <= 20) and
        TXcomBattleRandom.Percent(FState.Random, 20 * LDifficulty) then
        LDirection := Result.DirectionTo(LCraftPosition);
      if LDirection <> -1 then
        Result.SetDirection(LDirection)
      else
        Result.SetDirection(FState.Random.Generate(0, 7));
      FState.Save.Units.Add(Result);
    end
    else
    begin
      Result.Free;
      Result := nil;
    end;
  end;
end;

function TXcomUnitDeployer.AddCivilian(const ARules: TXcomRuleUnit): TXcomBattleUnit;
var
  LNode: TXcomNode;
  LRankLook: Integer;
  LBasicLook: Integer;
  LUtileLook: Integer;
begin
  // BattleUnit: the rank look first, then the two arguments of setRecolor from the last to the first
  LRankLook := FState.LegacyRandom.Next mod 8;
  LUtileLook := FState.LegacyRandom.Next mod 8;
  LBasicLook := FState.LegacyRandom.Next mod 8;
  Inc(FState.UnitSequence);
  Result := TXcomBattleUnit.Create(FState.Context, ARules, FACTION_NEUTRAL, FState.UnitSequence - 1,
    ArmorRules(ARules.Armor), NoAdjustment, FState.Save.Depth, LBasicLook, LUtileLook, LRankLook);
  LNode := FState.Save.GetSpawnNode(0, Result);
  if Assigned(LNode) then
  begin
    FState.Save.SetUnitPosition(Result, LNode.Position);
    Result.AI := TXcomAIModule.Create(Result, LNode);
    Result.SetDirection(FState.Random.Generate(0, 7));
    FState.Save.Units.Add(Result);
  end
  else if PlaceUnitNearFriend(Result) then
  begin
    Result.AI := TXcomAIModule.Create(Result, nil);
    Result.SetDirection(FState.Random.Generate(0, 7));
    FState.Save.Units.Add(Result);
  end
  else
  begin
    Result.Free;
    Result := nil;
  end;
end;

procedure TXcomUnitDeployer.AddBuiltInWeapons(const AUnit: TXcomBattleUnit; const ARules: TXcomRuleUnit;
  ALevel: Integer);
var
  LName: string;
  LRuleItem: TXcomRuleItem;
  LItem: TXcomBattleItem;
begin
  for LName in ARules.BuiltInWeapons[ALevel] do
  begin
    LRuleItem := FState.Ruleset.Items.Find(LName);
    if Assigned(LRuleItem) then
    begin
      LItem := FState.NewItem(LRuleItem);
      if FState.Equipper.AddItem(LItem, AUnit) and (LRuleItem.TurretType <> -1) and
        (AUnit.Faction = FACTION_NEUTRAL) then
        AUnit.TurretType := LRuleItem.TurretType;
    end;
  end;
end;

procedure TXcomUnitDeployer.DeployAliens(const ADeployment: TXcomAlienDeployment);
var
  LRace: TXcomAlienRace;
  LMonth: Integer;
  LData: TXcomDeploymentData;
  LAlienName: string;
  LQuantity: Integer;
  LDelta: Integer;
  LIndex: Integer;
  LOutside: Boolean;
  LRules: TXcomRuleUnit;
  LUnit: TXcomBattleUnit;
  LItemLevel: Integer;
  LName: string;
  LRuleItem: TXcomRuleItem;
  LItem: TXcomBattleItem;
  LTerroristWeapon: string;
  LDemigod: Boolean;
  LDifficulty: Integer;
begin
  if (ADeployment.Race <> '') and (FState.Game.MonthsPassed > -1) then
    FState.AlienRace := ADeployment.Race;
  if (FState.Save.Depth > 0) and (Pos('_UNDERWATER', FState.AlienRace) = 0) then
    FState.AlienRace := FState.AlienRace + '_UNDERWATER';
  LRace := FState.Ruleset.AlienRaces.Find(FState.AlienRace);
  if not Assigned(LRace) then
    raise EXcomBattleException.CreateFmt(SUnknownRace, [FState.AlienRace, ADeployment.DeploymentType]);
  LMonth := FState.AlienMonth;
  LDemigod := FState.Ruleset.Settings.DifficultyDemigod;
  LDifficulty := FState.Game.Difficulty;
  for LData in ADeployment.Data do
  begin
    LAlienName := LRace.GetMember(LData.AlienRank);
    if LDemigod then
      LDelta := LData.DQty
    else
      LDelta := FState.Random.Generate(0, LData.DQty);
    if LDifficulty < DIFFICULTY_VETERAN then
      LQuantity := LData.LowQty + LDelta
    else if LDifficulty < DIFFICULTY_SUPERHUMAN then
      LQuantity := LData.LowQty + ((LData.HighQty - LData.LowQty) div 2) + LDelta
    else
      LQuantity := LData.HighQty + LDelta;
    if LDemigod then
      Inc(LQuantity, LData.ExtraQty)
    else
      Inc(LQuantity, FState.Random.Generate(0, LData.ExtraQty));
    for LIndex := 0 to LQuantity - 1 do
    begin
      LOutside := FState.Random.Generate(0, 99) < LData.PercentageOutsideUfo;
      if not Assigned(FState.Ufo) then
        LOutside := False;
      LRules := UnitRules(LAlienName);
      LUnit := AddAlien(LRules, LData.AlienRank, LOutside);
      LItemLevel := FState.Ruleset.Settings.AlienItemLevels[LMonth][FState.Random.Generate(0, 9)];
      if Assigned(LUnit) then
      begin
        if Length(LRules.BuiltInWeapons) > 0 then
        begin
          if LItemLevel >= Length(LRules.BuiltInWeapons) then
            LItemLevel := Length(LRules.BuiltInWeapons) - 1;
          for LName in LRules.BuiltInWeapons[LItemLevel] do
          begin
            LRuleItem := FState.Ruleset.Items.Find(LName);
            if Assigned(LRuleItem) then
            begin
              LItem := FState.NewItem(LRuleItem);
              FState.Equipper.AddItem(LItem, LUnit);
            end;
          end;
        end;
        if LRules.LivingWeapon then
        begin
          LTerroristWeapon := Copy(LRules.Race, 5, MaxInt) + '_WEAPON';
          LRuleItem := FState.Ruleset.Items.Find(LTerroristWeapon);
          if Assigned(LRuleItem) then
          begin
            LItem := FState.NewItem(LRuleItem);
            if FState.Equipper.AddItem(LItem, LUnit) then
              LUnit.TurretType := LItem.Rules.TurretType;
          end;
        end
        else
        begin
          if Length(LData.ItemSets) = 0 then
            raise EXcomBattleException.Create(SNoItemSet);
          if LItemLevel >= Length(LData.ItemSets) then
            LItemLevel := Length(LData.ItemSets) - 1;
          for LName in LData.ItemSets[LItemLevel].Items do
          begin
            LRuleItem := FState.Ruleset.Items.Find(LName);
            if Assigned(LRuleItem) then
            begin
              LItem := FState.NewItem(LRuleItem);
              FState.Equipper.AddItem(LItem, LUnit);
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TXcomUnitDeployer.DeployCivilians(AMaximum: Integer);
var
  LNumber: Integer;
  LMonth: Integer;
  LIndex: Integer;
  LPick: Integer;
  LRules: TXcomRuleUnit;
  LCivilian: TXcomBattleUnit;
  LItemLevel: Integer;
begin
  if AMaximum <> 0 then
  begin
    LNumber := FState.Random.Generate(AMaximum div 2, AMaximum);
    if LNumber > 0 then
    begin
      LMonth := FState.AlienMonth;
      for LIndex := 0 to LNumber - 1 do
      begin
        if Length(FState.Terrain.CivilianTypes) = 0 then
          raise EXcomBattleException.Create(SNoCivilianTypes);
        LPick := FState.Random.Generate(0, Length(FState.Terrain.CivilianTypes) - 1);
        LRules := UnitRules(FState.Terrain.CivilianTypes[LPick]);
        LCivilian := AddCivilian(LRules);
        if Assigned(LCivilian) then
        begin
          LItemLevel := FState.Ruleset.Settings.AlienItemLevels[LMonth][FState.Random.Generate(0, 9)];
          if Length(LRules.BuiltInWeapons) > 0 then
          begin
            if LItemLevel >= Length(LRules.BuiltInWeapons) then
              LItemLevel := Length(LRules.BuiltInWeapons) - 1;
            AddBuiltInWeapons(LCivilian, LRules, LItemLevel);
          end;
        end;
      end;
    end;
  end;
end;

procedure TXcomUnitDeployer.FuelPowerSources;
var
  LIndex: Integer;
  LTile: TXcomTile;
  LFuel: TXcomBattleItem;
begin
  for LIndex := 0 to FState.Save.MapSizeXyz - 1 do
  begin
    LTile := FState.Save.TileByIndex(LIndex);
    if Assigned(LTile.MapData[XCOM_PART_OBJECT]) and
      (LTile.MapData[XCOM_PART_OBJECT].SpecialType = SPECIAL_UFO_POWER_SOURCE) then
    begin
      LFuel := FState.NewItem(FState.ItemRules(FState.Ruleset.Settings.AlienFuelName));
      FState.Save.Items.Add(LFuel);
      LTile.AddItem(LFuel, Ground);
    end;
  end;
end;

procedure TXcomUnitDeployer.ExplodePowerSources;
var
  LIndex: Integer;
  LTile: TXcomTile;
  LPosition: TXcomPosition;
begin
  for LIndex := 0 to FState.Save.MapSizeXyz - 1 do
  begin
    LTile := FState.Save.TileByIndex(LIndex);
    if Assigned(LTile.MapData[XCOM_PART_OBJECT]) and
      (LTile.MapData[XCOM_PART_OBJECT].SpecialType = SPECIAL_UFO_POWER_SOURCE) and
      TXcomBattleRandom.Percent(FState.Random, 75) then
    begin
      LPosition := TXcomPosition.Make(LTile.Position.X * 16, LTile.Position.Y * 16, LTile.Position.Z * 24 + 12);
      FState.TileEngine.Explode(LPosition, 180 + FState.Random.Generate(0, 70), TXcomRuleItem.DT_HE, 10);
    end;
  end;
  LTile := FState.TileEngine.CheckForTerrainExplosions;
  while Assigned(LTile) do
  begin
    LPosition := TXcomPosition.Make(LTile.Position.X * 16 + 8, LTile.Position.Y * 16 + 8, LTile.Position.Z * 24);
    FState.TileEngine.Explode(LPosition, LTile.Explosive, TXcomRuleItem.DT_HE, LTile.Explosive div 10);
    LTile := FState.TileEngine.CheckForTerrainExplosions;
  end;
end;

end.
