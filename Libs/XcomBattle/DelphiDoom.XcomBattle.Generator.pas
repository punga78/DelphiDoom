{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the generator of a battle             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.Generator;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleTerrain,
  DelphiDoom.XcomMod.MapScript, DelphiDoom.XcomMod.Texture, DelphiDoom.XcomMod.AlienDeployment,
  DelphiDoom.XcomMod.MapData, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomSave.Node, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Ufo,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.MissionSite,
  DelphiDoom.XcomSave.AlienBase, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Intf,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.Services.Intf,
  DelphiDoom.XcomBattle.LegacyRandom, DelphiDoom.XcomBattle.GeneratorState, DelphiDoom.XcomBattle.MapGenerator,
  DelphiDoom.XcomBattle.UnitDeployer, DelphiDoom.XcomBattle.AIModule;

type
  /// <summary>
  ///   Makes the battle of a mission (BattlescapeGenerator): the terrain from the deployment or the world
  ///   texture, the map from its script, the objectives, the X-COM units, the aliens, the civilians, the fuel and
  ///   explosion of a UFO, the music and the light; NextStage makes the next part of a mission in more parts on
  ///   the battle of the part before. Not ported: runInventory (the inventory screen)
  /// </summary>
  TXcomBattlescapeGenerator = class
  strict private
    FState: TXcomGeneratorState;
    FTarget: TXcomTarget;
    FTexture: TXcomTexture;
    FMapGenerator: TXcomMapGenerator;
    FDeployer: TXcomUnitDeployer;
    procedure SetupObjectives(const ADeployment: TXcomAlienDeployment);
    procedure SetDepth(const ADeployment: TXcomAlienDeployment; ANextStage: Boolean);
    procedure SetMusic(const ADeployment: TXcomAlienDeployment; ANextStage: Boolean);
    procedure DropCarriedUnits;
    function SendToTimeOut: Integer;
    procedure SortItems(AAliensAlive: Integer; const ATakeToNextStage: TList<TXcomBattleItem>);
    procedure PlaceSurvivors;
    function ScriptOf(const ADeployment: TXcomAlienDeployment): TObjectList<TXcomMapScript>;
    procedure Generate;
    procedure GenerateNextStage;
  public
    /// <param name="ASave">The empty saved battle that gets the battle; its mission type says what to make</param>
    /// <param name="ALegacyRandom">The C library rand() (srand done by the caller): only the look of the units</param>
    constructor Create(const ARuleset: TXcomRuleset; const ASave: TXcomSavedBattleGame; const AGame: TXcomSavedGame;
      const AContext: IXcomBattleContext; const ATileEngine: IXcomGeneratorTileEngine;
      const ALegacyRandom: TXcomLegacyRandom; AAllowAutoLoadout: Boolean = True);
    destructor Destroy; override;
    /// <summary>setCraft: the X-COM craft in the battle</summary>
    procedure SetCraft(const ACraft: TXcomCraft);
    /// <summary>setUfo</summary>
    procedure SetUfo(const AUfo: TXcomUfo);
    /// <summary>setBase: the X-COM base (a base defense, or a battle without craft)</summary>
    procedure SetBase(const ABase: TXcomBase);
    /// <summary>setMissionSite: the site decides the terrain of its texture</summary>
    procedure SetMissionSite(const ASite: TXcomMissionSite);
    /// <summary>setAlienBase</summary>
    procedure SetAlienBase(const ABase: TXcomAlienBase);
    /// <summary>setWorldTexture: the polygon of the globe where the UFO is; it gives the terrain</summary>
    procedure SetWorldTexture(const ATexture: TXcomTexture);
    /// <summary>setWorldShade: 0 to 15</summary>
    procedure SetWorldShade(AShade: Integer);
    procedure SetAlienRace(const ARace: string);
    procedure SetAlienItemLevel(ALevel: Integer);
    procedure SetTerrain(const ATerrain: TXcomRuleTerrain);
    /// <summary>
    ///   run. Placing a large unit, or a unit next to a friend, asks the pathfinder of the battle whether a step is
    ///   blocked (SavedBattleGame::initUtilities gives it in the C++): a battle that has none gets one for the run
    /// </summary>
    procedure Run;
    /// <summary>
    ///   nextStage: the saved battle keeps its X-COM units that are alive (after an abort only the ones on the exit),
    ///   what they carry and what the rules let go on; a new map, new aliens and civilians are made for the mission
    ///   type that the caller has already set in the saved battle (the next stage of the deployment). The items
    ///   that go home are in the recovery lists of the saved battle. Not for a generator that was given a craft, a
    ///   UFO or a base
    /// </summary>
    procedure NextStage;
  end;

implementation

uses
  DelphiDoom.XcomBattle.Pathfinding;

const
  SNoDeployment = 'Alien deployment %s not found.';
  SNoTerrain = 'Map generator encountered an error: No valid terrain found.';
  SScriptNotFound = 'Map generator encountered an error: %s script not found.';
  SNoAliens = 'Map generator encountered an error: no alien units could be placed on the map.';
  SNoXcomUnits = 'Map generator encountered an error: no xcom units could be placed on the map.';
  GROUND_INVENTORY = 'STR_GROUND';
  /// <summary>SpecialTileType START_POINT and END_POINT</summary>
  SPECIAL_START_POINT = 1;
  SPECIAL_END_POINT = 13;
  /// <summary>NodeRank NR_XCOM</summary>
  NODE_RANK_XCOM = 1;

{ TXcomBattlescapeGenerator }

constructor TXcomBattlescapeGenerator.Create(const ARuleset: TXcomRuleset; const ASave: TXcomSavedBattleGame;
  const AGame: TXcomSavedGame; const AContext: IXcomBattleContext; const ATileEngine: IXcomGeneratorTileEngine;
  const ALegacyRandom: TXcomLegacyRandom; AAllowAutoLoadout: Boolean);
begin
  inherited Create;
  FState := TXcomGeneratorState.Create(ARuleset, ASave, AGame, AContext, ATileEngine, ALegacyRandom,
    AAllowAutoLoadout);
  FMapGenerator := TXcomMapGenerator.Create(FState);
  FDeployer := TXcomUnitDeployer.Create(FState);
end;

destructor TXcomBattlescapeGenerator.Destroy;
begin
  FDeployer.Free;
  FMapGenerator.Free;
  FState.Free;
  inherited Destroy;
end;

procedure TXcomBattlescapeGenerator.SetCraft(const ACraft: TXcomCraft);
begin
  FState.Craft := ACraft;
  ACraft.SetInBattlescape(True);
end;

procedure TXcomBattlescapeGenerator.SetUfo(const AUfo: TXcomUfo);
begin
  FState.Ufo := AUfo;
  AUfo.SetInBattlescape(True);
end;

procedure TXcomBattlescapeGenerator.SetBase(const ABase: TXcomBase);
begin
  FState.Base := ABase;
  ABase.InBattlescape := True;
end;

procedure TXcomBattlescapeGenerator.SetMissionSite(const ASite: TXcomMissionSite);
begin
  FTarget := ASite;
  ASite.InBattlescape := True;
end;

procedure TXcomBattlescapeGenerator.SetAlienBase(const ABase: TXcomAlienBase);
begin
  ABase.InBattlescape := True;
end;

procedure TXcomBattlescapeGenerator.SetWorldTexture(const ATexture: TXcomTexture);
begin
  FTexture := ATexture;
end;

procedure TXcomBattlescapeGenerator.SetWorldShade(AShade: Integer);
begin
  if AShade > 15 then
    AShade := 15;
  if AShade < 0 then
    AShade := 0;
  FState.WorldShade := AShade;
end;

procedure TXcomBattlescapeGenerator.SetAlienRace(const ARace: string);
begin
  FState.AlienRace := ARace;
end;

procedure TXcomBattlescapeGenerator.SetAlienItemLevel(ALevel: Integer);
begin
  FState.AlienItemLevel := ALevel;
end;

procedure TXcomBattlescapeGenerator.SetTerrain(const ATerrain: TXcomRuleTerrain);
begin
  FState.Terrain := ATerrain;
end;

procedure TXcomBattlescapeGenerator.SetupObjectives(const ADeployment: TXcomAlienDeployment);
var
  LTargetType: Integer;
  LObjectives: Integer;
  LActualCount: Integer;
  LIndex: Integer;
  LPart: Integer;
  LTile: TXcomTile;
begin
  LTargetType := ADeployment.ObjectiveType;
  if LTargetType > -1 then
  begin
    LObjectives := ADeployment.ObjectivesRequired;
    LActualCount := 0;
    for LIndex := 0 to FState.Save.MapSizeXyz - 1 do
    begin
      LTile := FState.Save.TileByIndex(LIndex);
      for LPart := XCOM_PART_FLOOR to XCOM_PART_OBJECT do
        if Assigned(LTile.MapData[LPart]) and (LTile.MapData[LPart].SpecialType = LTargetType) then
          Inc(LActualCount);
    end;
    if LActualCount > 0 then
    begin
      FState.Save.ObjectiveType := LTargetType;
      if (LActualCount < LObjectives) or (LObjectives = 0) then
        FState.Save.SetObjectiveCount(LActualCount)
      else
        FState.Save.SetObjectiveCount(LObjectives);
    end;
  end;
end;

procedure TXcomBattlescapeGenerator.SetDepth(const ADeployment: TXcomAlienDeployment; ANextStage: Boolean);
begin
  if (FState.Save.Depth > 0) and (not ANextStage) then
    Exit;
  if ADeployment.MaxDepth > 0 then
    FState.Save.Depth := FState.Random.Generate(ADeployment.MinDepth, ADeployment.MaxDepth)
  else if (FState.Terrain.MaxDepth > 0) or ANextStage then
    FState.Save.Depth := FState.Random.Generate(FState.Terrain.MinDepth, FState.Terrain.MaxDepth);
end;

procedure TXcomBattlescapeGenerator.SetMusic(const ADeployment: TXcomAlienDeployment; ANextStage: Boolean);
begin
  if Length(ADeployment.Music) > 0 then
    FState.Save.Music := ADeployment.Music[FState.Random.Generate(0, Length(ADeployment.Music) - 1)]
  else if Length(FState.Terrain.Music) > 0 then
    FState.Save.Music := FState.Terrain.Music[FState.Random.Generate(0, Length(FState.Terrain.Music) - 1)]
  else if ANextStage then
    FState.Save.Music := '';
end;

procedure TXcomBattlescapeGenerator.Run;
var
  LPathfinder: IXcomBattlePathfinder;
begin
  if Assigned(FState.Save.Pathfinder) then
  begin
    Generate;
    Exit;
  end;
  // the blocked steps do not read the nodes of the pathfinder: it can be made before the map has its size
  LPathfinder := TXcomPathfinding.Create(FState.Save);
  FState.Save.Pathfinder := LPathfinder;
  try
    Generate;
  finally
    FState.Save.Pathfinder := nil;
  end;
end;

procedure TXcomBattlescapeGenerator.Generate;
var
  LDeployment: TXcomAlienDeployment;
  LName: string;
  LTerrainName: string;
  LPick: Integer;
  LTarget: TXcomTarget;
  LScript: TObjectList<TXcomMapScript>;
  LUnitCount: Integer;
begin
  if Assigned(FState.Ufo) then
    LName := FState.Ufo.Rules.UfoType
  else
    LName := FState.Save.MissionType;
  LDeployment := FState.Ruleset.AlienDeployments.Find(LName);
  if not Assigned(LDeployment) then
    raise EXcomBattleException.CreateFmt(SNoDeployment, [LName]);
  FState.Save.TurnLimit := LDeployment.TurnLimit;
  FState.Save.ChronoTrigger := LDeployment.ChronoTrigger;
  FState.Save.CheatTurn := LDeployment.CheatTurn;
  FState.MapSizeX := LDeployment.Width;
  FState.MapSizeY := LDeployment.MapLength;
  FState.MapSizeZ := LDeployment.Height;
  FState.UnitSequence := MAX_SOLDIER_ID;
  if not Assigned(FState.Terrain) then
  begin
    if (not Assigned(FTexture)) or (Length(FTexture.Terrain) = 0) or (Length(LDeployment.Terrains) > 0) then
    begin
      if Length(LDeployment.Terrains) > 0 then
      begin
        LPick := FState.Random.Generate(0, Length(LDeployment.Terrains) - 1);
        FState.Terrain := FState.Ruleset.Terrains.Find(LDeployment.Terrains[LPick]);
      end
      else
        FState.Terrain := FState.Ruleset.Terrains.Find(FState.Ruleset.Terrains.Index[0]);
    end
    else
    begin
      LTarget := FState.Ufo;
      if Assigned(FTarget) then
        LTarget := FTarget;
      LTerrainName := FTexture.GetRandomTerrain(LTarget.Longitude, LTarget.Latitude, FState.Random);
      FState.Terrain := FState.Ruleset.Terrains.Find(LTerrainName);
    end;
  end;
  if not Assigned(FState.Terrain) then
    raise EXcomBattleException.Create(SNoTerrain);
  SetDepth(LDeployment, False);
  if LDeployment.Shade <> -1 then
    FState.WorldShade := LDeployment.Shade;
  if not FState.Ruleset.MapScripts.TryGetValue(FState.Terrain.Script, LScript) then
    LScript := nil;
  if FState.Ruleset.MapScripts.ContainsKey(LDeployment.Script) then
    FState.Ruleset.MapScripts.TryGetValue(LDeployment.Script, LScript)
  else if LDeployment.Script <> '' then
    raise EXcomBattleException.CreateFmt(SScriptNotFound, [LDeployment.Script]);
  if not Assigned(LScript) then
    raise EXcomBattleException.CreateFmt(SScriptNotFound, [FState.Terrain.Script]);
  FMapGenerator.Generate(LScript);
  SetupObjectives(LDeployment);
  FDeployer.DeployXcom;
  LUnitCount := FState.Save.Units.Count;
  FDeployer.DeployAliens(LDeployment);
  if LUnitCount = FState.Save.Units.Count then
    raise EXcomBattleException.Create(SNoAliens);
  FDeployer.DeployCivilians(LDeployment.Civilians);
  if FState.GenerateFuel then
    FDeployer.FuelPowerSources;
  if Assigned(FState.Ufo) and (FState.Ufo.Status = TXcomUfo.STATUS_CRASHED) then
    FDeployer.ExplodePowerSources;
  SetMusic(LDeployment, False);
  FState.Save.GlobalShade := FState.WorldShade;
  FState.TileEngine.CalculateSunShading;
  FState.TileEngine.CalculateTerrainLighting;
  FState.TileEngine.CalculateUnitLighting;
end;

function TXcomBattlescapeGenerator.ScriptOf(const ADeployment: TXcomAlienDeployment): TObjectList<TXcomMapScript>;
begin
  if not FState.Ruleset.MapScripts.TryGetValue(FState.Terrain.Script, Result) then
    Result := nil;
  if FState.Ruleset.MapScripts.ContainsKey(ADeployment.Script) then
    FState.Ruleset.MapScripts.TryGetValue(ADeployment.Script, Result)
  else if ADeployment.Script <> '' then
    raise EXcomBattleException.CreateFmt(SScriptNotFound, [ADeployment.Script]);
  if not Assigned(Result) then
    raise EXcomBattleException.CreateFmt(SScriptNotFound, [FState.Terrain.Script]);
end;

procedure TXcomBattlescapeGenerator.DropCarriedUnits;
var
  LUnit: TXcomBattleUnit;
  LItem: TXcomBattleItem;
  LToDrop: TList<TXcomBattleItem>;
begin
  // preventively drop all units from the inventory of the soldiers (makes handling easier)
  LToDrop := TList<TXcomBattleItem>.Create;
  try
    for LUnit in FState.Save.Units do
      if (LUnit.OriginalFaction = FACTION_PLAYER) and not LUnit.IsOut then
      begin
        LToDrop.Clear;
        for LItem in LUnit.Inventory do
          if Assigned(LItem.CorpseUnit) then
            LToDrop.Add(LItem);
        for LItem in LToDrop do
        begin
          LItem.MoveToOwner(nil);
          LUnit.Tile.AddItem(LItem, FState.Equipper.Inventory(GROUND_INVENTORY));
          if LItem.CorpseUnit.Status = STATUS_UNCONSCIOUS then
            LItem.CorpseUnit.SetPosition(LUnit.Tile.Position);
        end;
      end;
  finally
    LToDrop.Free;
  end;
end;

function TXcomBattlescapeGenerator.SendToTimeOut: Integer;
var
  LUnit: TXcomBattleUnit;
  LTile: TXcomTile;
  LInExit: Boolean;
  LIndex: Integer;
  LItem: TXcomBattleItem;
  LPosition: TXcomPosition;
  LX, LY: Integer;
begin
  // all the enemy units, and the soldiers that are not on the exit after an abort, are out of the mission
  Result := 0;
  for LUnit in FState.Save.Units do
  begin
    LUnit.ClearVisibleUnits;
    LUnit.ClearVisibleTiles;
    LTile := FState.Save.TileAt(LUnit.Position);
    LInExit := LUnit.IsInExitArea(SPECIAL_END_POINT) or LUnit.LiesInExitArea(LTile, SPECIAL_END_POINT);
    if (LUnit.Status <> STATUS_DEAD) and (((LUnit.OriginalFaction = FACTION_PLAYER) and FState.Save.Aborted and
      not LInExit) or (LUnit.OriginalFaction <> FACTION_PLAYER)) then
    begin
      if (LUnit.OriginalFaction = FACTION_HOSTILE) and not LUnit.IsOut then
      begin
        if LUnit.OriginalFaction = LUnit.Faction then
          Inc(Result)
        else if Assigned(LUnit.Tile) then
        begin
          // a mind controlled alien leaves what it carries where it stands
          LIndex := 0;
          while LIndex < LUnit.Inventory.Count do
          begin
            LItem := LUnit.Inventory[LIndex];
            if not LItem.Rules.FixedWeapon then
            begin
              LUnit.Tile.AddItem(LItem, FState.Equipper.Inventory(GROUND_INVENTORY));
              LUnit.Inventory.Delete(LIndex);
            end
            else
              Inc(LIndex);
          end;
        end;
      end;
      LUnit.GoToTimeOut;
      LUnit.AI := nil;
    end;
    if Assigned(LUnit.Tile) then
    begin
      LPosition := LUnit.Position;
      for LX := 0 to LUnit.Armor.Size - 1 do
        for LY := 0 to LUnit.Armor.Size - 1 do
          FState.Save.TileAt(LPosition + TXcomPosition.Make(LX, LY, 0)).SetUnit(nil);
    end;
    // a unit that stays in the battle with its AI (a dead one): the nodes it knows are freed with the old map
    if Assigned(LUnit.AI) then
      (LUnit.AI as TXcomAIModule).ForgetNodes;
    LUnit.SetFire(0);
    LUnit.SetTile(nil);
    LUnit.SetPosition(TXcomPosition.Make(-1, -1, -1), False);
  end;
end;

procedure TXcomBattlescapeGenerator.SortItems(AAliensAlive: Integer; const ATakeToNextStage: TList<TXcomBattleItem>);
var
  LCarry, LRemove, LContainer: TList<TXcomBattleItem>;
  LItem, LAmmo: TXcomBattleItem;
  LTile: TXcomTile;
  LOfOtherSideOrDead: Boolean;
begin
  // the items that are guaranteed to go home (the ones in the craft), the ones that go home only on success (the
  // ones scattered on the ground), the ones that go on with the soldiers and the ones that are lost
  LCarry := TList<TXcomBattleItem>.Create;
  LRemove := TList<TXcomBattleItem>.Create;
  try
    FState.Save.ResetTurnCounter;
    for LItem in FState.Save.Items do
    begin
      // the ammo loaded into a weapon follows its weapon
      if LItem.IsAmmo then
        Continue;
      LContainer := LRemove;
      LOfOtherSideOrDead := Assigned(LItem.CorpseUnit) and ((LItem.CorpseUnit.OriginalFaction <> FACTION_PLAYER) or
        (LItem.CorpseUnit.Status = STATUS_DEAD));
      if ((Assigned(LItem.CorpseUnit) and Assigned(LItem.CorpseUnit.GeoscapeSoldier)) or LItem.Rules.Recoverable) and
        not Assigned(LItem.Owner) then
      begin
        // primed grenades on the floor do not count
        if LItem.FuseTimer = -1 then
        begin
          if AAliensAlive = 0 then
          begin
            // all the defenders are dead: corpses, unconscious units and what is not researched yet go to the craft
            if LOfOtherSideOrDead or not FState.Game.IsResearched(LItem.Rules.Requirements) then
              LContainer := FState.Save.RecoverGuaranteed
            else
              LContainer := ATakeToNextStage;
          end
          else
          begin
            // some aliens survived, so the squad ran to the exit: it depends on where the item was
            LTile := LItem.Tile;
            if Assigned(LTile) then
            begin
              LContainer := FState.Save.RecoverConditional;
              if Assigned(LTile.MapData[XCOM_PART_FLOOR]) then
              begin
                if LTile.MapData[XCOM_PART_FLOOR].SpecialType = SPECIAL_START_POINT then
                  LContainer := FState.Save.RecoverGuaranteed
                else if LTile.MapData[XCOM_PART_FLOOR].SpecialType = SPECIAL_END_POINT then
                begin
                  if LOfOtherSideOrDead then
                    LContainer := FState.Save.RecoverConditional
                  else
                    LContainer := ATakeToNextStage;
                end;
              end;
            end;
          end;
        end;
      end;
      // a soldier that already holds it keeps it
      if Assigned(LItem.Owner) and (LItem.Owner.Faction = FACTION_PLAYER) then
        LContainer := LCarry;
      // what happens to the item happens to its ammo; all the tiles are about to disappear
      LAmmo := LItem.AmmoItem;
      if Assigned(LAmmo) and (LAmmo <> LItem) then
      begin
        LAmmo.Tile := nil;
        LContainer.Add(LAmmo);
      end;
      LItem.Tile := nil;
      LContainer.Add(LItem);
    end;
    // the fixed weapons, and whatever else is still "equipped", leave their owners: the saved battle goes on
    // owning the items that are out of the game (the C++ deletes them)
    for LItem in LRemove do
      if Assigned(LItem.Owner) then
        LItem.Owner.Inventory.Remove(LItem);
    // only what the soldiers carry stays active; the items of the inventory tile are added after the map is made
    FState.Save.Items.Clear;
    for LItem in LCarry do
      FState.Save.Items.Add(LItem);
  finally
    LRemove.Free;
    LCarry.Free;
  end;
end;

procedure TXcomBattlescapeGenerator.PlaceSurvivors;
var
  LUnit: TXcomBattleUnit;
  LSelectedFirst: Boolean;
  LNode: TXcomNode;
begin
  LSelectedFirst := False;
  for LUnit in FState.Save.Units do
    if (LUnit.OriginalFaction = FACTION_PLAYER) and not LUnit.IsOut then
    begin
      LUnit.TurnsSinceSpotted := 255;
      LUnit.VisibleTiles.Clear;
      if (not LSelectedFirst) and Assigned(LUnit.GeoscapeSoldier) then
      begin
        FState.Save.SelectedUnit := LUnit;
        LSelectedFirst := True;
      end;
      LNode := FState.Save.GetSpawnNode(NODE_RANK_XCOM, LUnit);
      if Assigned(LNode) or FDeployer.PlaceUnitNearFriend(LUnit) then
      begin
        if Assigned(LNode) then
          FState.Save.SetUnitPosition(LUnit, LNode.Position);
        if not Assigned(FState.CraftInventoryTile) then
          FState.CraftInventoryTile := LUnit.Tile;
        FState.CraftInventoryTile.SetUnit(LUnit);
        LUnit.Visible := False;
        // reset the time units, regain energy, but take no damage and do not go berserk
        LUnit.PrepareNewTurn(False);
      end;
    end;
  if (not Assigned(FState.Save.SelectedUnit)) or FState.Save.SelectedUnit.IsOut or
    (FState.Save.SelectedUnit.Faction <> FACTION_PLAYER) then
    FState.Save.SelectNextPlayerUnit;
end;

procedure TXcomBattlescapeGenerator.NextStage;
var
  LPathfinder: IXcomBattlePathfinder;
begin
  if Assigned(FState.Save.Pathfinder) then
  begin
    GenerateNextStage;
    Exit;
  end;
  // as Run: the survivors and the new aliens are placed with a pathfinder that lasts as long as the stage is made
  LPathfinder := TXcomPathfinding.Create(FState.Save);
  FState.Save.Pathfinder := LPathfinder;
  try
    GenerateNextStage;
  finally
    FState.Save.Pathfinder := nil;
  end;
end;

procedure TXcomBattlescapeGenerator.GenerateNextStage;
var
  LAliensAlive: Integer;
  LTakeToNextStage: TList<TXcomBattleItem>;
  LDeployment: TXcomAlienDeployment;
  LItem: TXcomBattleItem;
  LUnitCount: Integer;
  LSite: TXcomMissionSite;
  LAlienBase: TXcomAlienBase;
begin
  DropCarriedUnits;
  LAliensAlive := SendToTimeOut;
  LTakeToNextStage := TList<TXcomBattleItem>.Create;
  try
    SortItems(LAliensAlive, LTakeToNextStage);
    LDeployment := FState.Ruleset.AlienDeployments.Find(FState.Save.MissionType);
    if not Assigned(LDeployment) then
      raise EXcomBattleException.CreateFmt(SNoDeployment, [FState.Save.MissionType]);
    FState.Save.TurnLimit := LDeployment.TurnLimit;
    FState.Save.ChronoTrigger := LDeployment.ChronoTrigger;
    FState.Save.CheatTurn := LDeployment.CheatTurn;
    FState.MapSizeX := LDeployment.Width;
    FState.MapSizeY := LDeployment.MapLength;
    FState.MapSizeZ := LDeployment.Height;
    if Length(LDeployment.Terrains) = 0 then
      raise EXcomBattleException.Create(SNoTerrain);
    FState.Terrain := FState.Ruleset.Terrains.Find(
      LDeployment.Terrains[FState.Random.Generate(0, Length(LDeployment.Terrains) - 1)]);
    if not Assigned(FState.Terrain) then
      raise EXcomBattleException.Create(SNoTerrain);
    SetDepth(LDeployment, True);
    FState.WorldShade := LDeployment.Shade;
    FMapGenerator.Generate(ScriptOf(LDeployment));
    SetupObjectives(LDeployment);
    PlaceSurvivors;
    for LItem in LTakeToNextStage do
    begin
      FState.Save.Items.Add(LItem);
      if not LItem.IsAmmo then
      begin
        // the C++ uses the null tile when no soldier could be placed
        if not Assigned(FState.CraftInventoryTile) then
          raise EXcomBattleException.Create(SNoXcomUnits);
        FState.CraftInventoryTile.AddItem(LItem, FState.Equipper.Inventory(GROUND_INVENTORY));
        if Assigned(LItem.CorpseUnit) then
        begin
          FState.CraftInventoryTile.SetUnit(LItem.CorpseUnit);
          LItem.CorpseUnit.SetPosition(FState.CraftInventoryTile.Position);
        end;
      end;
    end;
  finally
    LTakeToNextStage.Free;
  end;
  FState.UnitSequence := FState.Save.Units.Last.Id + 1;
  LUnitCount := FState.Save.Units.Count;
  // the race of the deployment, or the one of the site or of the alien base where the battle is
  FState.AlienRace := LDeployment.Race;
  if FState.AlienRace = '' then
    for LSite in FState.Game.MissionSites do
      if LSite.InBattlescape and (FState.AlienRace = '') then
        FState.AlienRace := LSite.AlienRace;
  if FState.AlienRace = '' then
    for LAlienBase in FState.Game.AlienBases do
      if LAlienBase.InBattlescape and (FState.AlienRace = '') then
        FState.AlienRace := LAlienBase.AlienRace;
  FDeployer.DeployAliens(LDeployment);
  if LUnitCount = FState.Save.Units.Count then
    raise EXcomBattleException.Create(SNoAliens);
  FDeployer.DeployCivilians(LDeployment.Civilians);
  FState.Save.Aborted := False;
  SetMusic(LDeployment, True);
  FState.Save.GlobalShade := FState.WorldShade;
  FState.TileEngine.CalculateSunShading;
  FState.TileEngine.CalculateTerrainLighting;
  FState.TileEngine.CalculateUnitLighting;
end;

end.
