{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the battle that a saved game holds    }
{  (SavedBattleGame)                                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.SavedBattleGame;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Convert, DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomMod.MapData,
  DelphiDoom.XcomMod.MapDataSet, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleUnit, DelphiDoom.XcomMod.Armor, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomSave.PositionCodec, DelphiDoom.XcomSave.Node, DelphiDoom.XcomSave.NodeWriter,
  DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Intf,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.Services.Intf, DelphiDoom.XcomBattle.Directions,
  DelphiDoom.XcomBattle.AIModule;

type
  /// <summary>Looks up a soldier of the geoscape by id (SavedGame::getSoldier)</summary>
  TXcomSoldierLookup = reference to function(AId: Integer): TXcomSoldier;

  /// <summary>
  ///   The battlescape data that a saved game writes: the map of tiles, the nodes, the units and items, the
  ///   side and turn, the objectives and the settings of the mission (SavedBattleGame). It owns tiles, nodes,
  ///   units and items; the map data sets belong to the ruleset. The battle state (BattlescapeState), the pathfinding
  ///   and the tile engine are given through interfaces
  /// </summary>
  TXcomSavedBattleGame = class
  strict private
    FContext: IXcomBattleContext;
    FSizeX: Integer;
    FSizeY: Integer;
    FSizeZ: Integer;
    FMapDataSets: TList<TXcomMapDataSet>;
    FTiles: TObjectList<TXcomTile>;
    FSelectedUnit: TXcomBattleUnit;
    FLastSelectedUnit: TXcomBattleUnit;
    FNodes: TObjectList<TXcomNode>;
    FUnits: TObjectList<TXcomBattleUnit>;
    FAllItems: TObjectList<TXcomBattleItem>;
    FItems: TList<TXcomBattleItem>;
    FDeleted: TList<TXcomBattleItem>;
    FRecoverGuaranteed: TList<TXcomBattleItem>;
    FRecoverConditional: TList<TXcomBattleItem>;
    FPathfinder: IXcomBattlePathfinder;
    FTileEngine: IXcomBattleTileEngine;
    FMissionType: string;
    FGlobalShade: Integer;
    FSide: Integer;
    FTurn: Integer;
    FDebugMode: Boolean;
    FAborted: Boolean;
    FItemId: Integer;
    FObjectiveType: Integer;
    FObjectivesDestroyed: Integer;
    FObjectivesNeeded: Integer;
    FFallingUnits: TList<TXcomBattleUnit>;
    FUnitsFalling: Boolean;
    FCheating: Boolean;
    FTileSearch: TArray<TXcomPosition>;
    FStorageSpace: TList<TXcomPosition>;
    FTuReserved: Integer;
    FKneelReserved: Boolean;
    FBaseModules: TArray<TArray<TPair<Integer, Integer>>>;
    FDepth: Integer;
    FAmbience: Integer;
    FAmbientVolume: Double;
    FMusic: string;
    FTurnLimit: Integer;
    FCheatTurn: Integer;
    FChronoTrigger: Integer;
    FBeforeGame: Boolean;
    FScorchedEarth: TXcomMapData;
    procedure MapDataSetNotify(ASender: TObject; const AItem: TXcomMapDataSet; AAction: TCollectionNotification);
    function SelectPlayerUnit(ADirection: Integer; ACheckReselect, ASetReselect, ACheckInventory: Boolean)
      : TXcomBattleUnit;
    function GetTileCount: Integer;
    procedure LoadTiles(const ANode: IYamlNode);
    procedure LoadUnits(const ANode: IYamlNode; const ARuleset: TXcomRuleset; ADifficulty: Integer;
      const ASoldiers: TXcomSoldierLookup);
    procedure LoadItems(const ANode: IYamlNode; const ARuleset: TXcomRuleset);
    function FindUnit(AId: Integer): TXcomBattleUnit;
    /// <summary>node[key].as&lt;char&gt;(default) of the tile field sizes (written as one char by the C++)</summary>
    class function ReadCharCode(const ANode: IYamlNode; const AKey: string; ADefault: Byte): Byte; static;
    procedure ReadModuleMap(const ANode: IYamlNode);
    function ModuleMapNode: IYamlNode;
  public
    constructor Create(const AContext: IXcomBattleContext);
    destructor Destroy; override;
    /// <summary>
    ///   createItem of the special weapons: a new item that belongs to the unit, outside its inventory (the
    ///   C++ calls removeItem on it, which keeps it in the deleted list)
    /// </summary>
    function MakeSpecialItem(const ARules: TXcomRuleItem; const AUnit: TXcomBattleUnit): TXcomBattleItem;
    /// <summary>A new item with the next id of the battle, owned by the saved battle and in none of its lists</summary>
    function NewItem(const ARules: TXcomRuleItem): TXcomBattleItem;
    property Context: IXcomBattleContext read FContext;
    /// <summary>
    ///   load: AMapDataSet of the ruleset, the soldiers of the geoscape (a unit with a soldier id and no
    ///   soldier is an error: the C++ crashes), the difficulty for the stat adjustment
    /// </summary>
    procedure Load(const ANode: IYamlNode; const ARuleset: TXcomRuleset; ADifficulty: Integer;
      const ASoldiers: TXcomSoldierLookup);
    function Save: IYamlNode;
    /// <summary>loadMapResources without the tile engine: gives the tiles their parts from the loaded sets</summary>
    procedure ResolveMapData;
    procedure InitMap(ASizeX, ASizeY, ASizeZ: Integer; AResetTerrain: Boolean = True);
    function TileIndex(const APosition: TXcomPosition): Integer;
    function TileAt(const APosition: TXcomPosition): TXcomTile;
    function TileByIndex(AIndex: Integer): TXcomTile;
    procedure TileCoords(AIndex: Integer; out AX, AY, AZ: Integer);
    property MapSizeX: Integer read FSizeX;
    property MapSizeY: Integer read FSizeY;
    property MapSizeZ: Integer read FSizeZ;
    function MapSizeXyz: Integer;
    /// <summary>The generator of the battle (the one of the context)</summary>
    function Random: IXcomRandom;
    property MapDataSets: TList<TXcomMapDataSet> read FMapDataSets;
    property Nodes: TObjectList<TXcomNode> read FNodes;
    property Units: TObjectList<TXcomBattleUnit> read FUnits;
    property Items: TList<TXcomBattleItem> read FItems;
    property RecoverGuaranteed: TList<TXcomBattleItem> read FRecoverGuaranteed;
    property RecoverConditional: TList<TXcomBattleItem> read FRecoverConditional;
    property Deleted: TList<TXcomBattleItem> read FDeleted;
    property Pathfinder: IXcomBattlePathfinder read FPathfinder write FPathfinder;
    property TileEngine: IXcomBattleTileEngine read FTileEngine write FTileEngine;
    property MissionType: string read FMissionType write FMissionType;
    property GlobalShade: Integer read FGlobalShade write FGlobalShade;
    property Side: Integer read FSide;
    property Turn: Integer read FTurn;
    property DebugMode: Boolean read FDebugMode;
    property Aborted: Boolean read FAborted write FAborted;
    property ObjectiveType: Integer read FObjectiveType write FObjectiveType;
    property ObjectivesDestroyed: Integer read FObjectivesDestroyed;
    property ObjectivesNeeded: Integer read FObjectivesNeeded;
    property FallingUnits: TList<TXcomBattleUnit> read FFallingUnits;
    property UnitsFalling: Boolean read FUnitsFalling write FUnitsFalling;
    property Cheating: Boolean read FCheating;
    property TileSearch: TArray<TXcomPosition> read FTileSearch;
    property StorageSpace: TList<TXcomPosition> read FStorageSpace;
    property TuReserved: Integer read FTuReserved write FTuReserved;
    property KneelReserved: Boolean read FKneelReserved write FKneelReserved;
    property ModuleMap: TArray<TArray<TPair<Integer, Integer>>> read FBaseModules write FBaseModules;
    property Depth: Integer read FDepth write FDepth;
    property Ambience: Integer read FAmbience write FAmbience;
    property AmbientVolume: Double read FAmbientVolume write FAmbientVolume;
    property Music: string read FMusic write FMusic;
    property TurnLimit: Integer read FTurnLimit write FTurnLimit;
    property CheatTurn: Integer read FCheatTurn write FCheatTurn;
    property ChronoTrigger: Integer read FChronoTrigger write FChronoTrigger;
    property BeforeGame: Boolean read FBeforeGame;
    property SelectedUnit: TXcomBattleUnit read FSelectedUnit write FSelectedUnit;
    property CurrentItemId: Integer read FItemId write FItemId;
    /// <summary>The scorched earth tile of the BLANKS set (MapDataSet::getScorchedEarthTile)</summary>
    property ScorchedEarth: TXcomMapData read FScorchedEarth write FScorchedEarth;
    /// <summary>Gives the saved battle an item it owns, and puts it in the list of items</summary>
    procedure AddItem(const AItem: TXcomBattleItem);
    /// <summary>Gives the saved battle an item it owns without putting it in any list</summary>
    procedure OwnItem(const AItem: TXcomBattleItem);
    function SelectPreviousPlayerUnit(ACheckReselect: Boolean = False; ASetReselect: Boolean = False;
      ACheckInventory: Boolean = False): TXcomBattleUnit;
    function SelectNextPlayerUnit(ACheckReselect: Boolean = False; ASetReselect: Boolean = False;
      ACheckInventory: Boolean = False): TXcomBattleUnit;
    function SelectUnit(const APosition: TXcomPosition): TXcomBattleUnit;
    /// <summary>The units that are alive on each side (BattlescapeGame::tallyUnits)</summary>
    procedure TallyUnits(out ALiveAliens, ALiveSoldiers: Integer);
    /// <summary>endTurn</summary>
    procedure EndTurn;
    procedure SetDebugMode;
    procedure ResetUnitTiles;
    procedure RandomizeItemLocations(const ATile: TXcomTile);
    procedure RemoveItem(const AItem: TXcomBattleItem);
    procedure SetObjectiveCount(ACounter: Integer);
    /// <summary>addDestroyedObjective: true when this was the last one (the caller ends or wins the battle)</summary>
    function AddDestroyedObjective: Boolean;
    function AllObjectivesDestroyed: Boolean;
    function GetSpawnNode(ANodeRank: Integer; const AUnit: TXcomBattleUnit): TXcomNode;
    function GetPatrolNode(AScout: Boolean; const AUnit: TXcomBattleUnit; AFromNode: TXcomNode): TXcomNode;
    procedure PrepareNewTurn;
    procedure ReviveUnconsciousUnits;
    procedure RemoveUnconsciousBodyItem(const AUnit: TXcomBattleUnit);
    function SetUnitPosition(const AUnit: TXcomBattleUnit; const APosition: TXcomPosition;
      ATestOnly: Boolean = False): Boolean;
    function EyesOnTarget(AFaction: Integer; const AUnit: TXcomBattleUnit): Boolean;
    function AddFallingUnit(const AUnit: TXcomBattleUnit): Boolean;
    function GetHighestRankedXcom: TXcomBattleUnit;
    function GetMoraleModifier(const AUnit: TXcomBattleUnit = nil): Integer;
    function PlaceUnitNearPosition(const AUnit: TXcomBattleUnit; const AEntryPoint: TXcomPosition;
      ALargeFriend: Boolean): Boolean;
    procedure ResetTurnCounter;
    procedure ResetTiles;
    procedure CalculateModuleMap;
    /// <summary>getItemUsable: the text of the error, or ''</summary>
    function GetItemUsable(const AItem: TXcomBattleItem): string;
    function IsItemUsable(const AItem: TXcomBattleItem): Boolean;
    procedure ResetUnitHitStates;
  end;

implementation

{ TXcomSavedBattleGame }

constructor TXcomSavedBattleGame.Create(const AContext: IXcomBattleContext);
var
  LIndex: Integer;
begin
  inherited Create;
  FContext := AContext;
  FMapDataSets := TList<TXcomMapDataSet>.Create;
  // every set the battle takes is marked as used by it (see the destructor)
  FMapDataSets.OnNotify := MapDataSetNotify;
  FTiles := TObjectList<TXcomTile>.Create(True);
  FNodes := TObjectList<TXcomNode>.Create(True);
  FUnits := TObjectList<TXcomBattleUnit>.Create(True);
  FAllItems := TObjectList<TXcomBattleItem>.Create(True);
  FItems := TList<TXcomBattleItem>.Create;
  FDeleted := TList<TXcomBattleItem>.Create;
  FRecoverGuaranteed := TList<TXcomBattleItem>.Create;
  FRecoverConditional := TList<TXcomBattleItem>.Create;
  FFallingUnits := TList<TXcomBattleUnit>.Create;
  FStorageSpace := TList<TXcomPosition>.Create;
  FSide := FACTION_PLAYER;
  FTurn := 1;
  FObjectiveType := -1;
  FTuReserved := BA_NONE;
  FAmbience := -1;
  FAmbientVolume := 0.5;
  FCheatTurn := 20;
  FChronoTrigger := FORCE_LOSE;
  FBeforeGame := True;
  SetLength(FTileSearch, 11 * 11);
  for LIndex := 0 to 120 do
  begin
    FTileSearch[LIndex].X := (LIndex mod 11) - 5;
    FTileSearch[LIndex].Y := (LIndex div 11) - 5;
  end;
end;

destructor TXcomSavedBattleGame.Destroy;
var
  LSet: TXcomMapDataSet;
begin
  FSelectedUnit := nil;
  FPathfinder := nil;
  FTileEngine := nil;
  FTiles.Free;
  FNodes.Free;
  // the units hold items by reference, the items hold units by reference: both lists are freed in any order
  FUnits.Free;
  FAllItems.Free;
  FItems.Free;
  FDeleted.Free;
  FRecoverGuaranteed.Free;
  FRecoverConditional.Free;
  FFallingUnits.Free;
  FStorageSpace.Free;
  // the sets are shared with a battle that was loaded while this one was still alive: only the last one unloads
  for LSet in FMapDataSets do
    LSet.Release(Self);
  FMapDataSets.Free;
  inherited Destroy;
end;

procedure TXcomSavedBattleGame.MapDataSetNotify(ASender: TObject; const AItem: TXcomMapDataSet;
  AAction: TCollectionNotification);
begin
  if (AAction = cnAdded) and Assigned(AItem) then
    AItem.Retain(Self);
end;

function TXcomSavedBattleGame.Random: IXcomRandom;
begin
  Result := FContext.Random;
end;

procedure TXcomSavedBattleGame.AddItem(const AItem: TXcomBattleItem);
begin
  OwnItem(AItem);
  FItems.Add(AItem);
end;

procedure TXcomSavedBattleGame.OwnItem(const AItem: TXcomBattleItem);
begin
  FAllItems.Add(AItem);
end;

function TXcomSavedBattleGame.FindUnit(AId: Integer): TXcomBattleUnit;
var
  LUnit: TXcomBattleUnit;
begin
  for LUnit in FUnits do
    if LUnit.Id = AId then
      Exit(LUnit);
  Result := nil;
end;

class function TXcomSavedBattleGame.ReadCharCode(const ANode: IYamlNode; const AKey: string; ADefault: Byte): Byte;
var
  LField: IYamlNode;
  LChar: AnsiChar;
begin
  LField := TXcomNodeReader.Field(ANode, AKey);
  if LField.IsDefined and LField.TryAsChar(LChar) then
    Result := Byte(LChar)
  else
    Result := ADefault;
end;

function TXcomSavedBattleGame.GetTileCount: Integer;
begin
  Result := FSizeX * FSizeY * FSizeZ;
end;

function TXcomSavedBattleGame.MakeSpecialItem(const ARules: TXcomRuleItem; const AUnit: TXcomBattleUnit)
  : TXcomBattleItem;
begin
  Result := TXcomBattleItem.Create(ARules, FItemId);
  Result.SetOwner(AUnit);
  OwnItem(Result);
  // the item is outside the inventory: the C++ calls removeItem, which keeps it in the deleted list
  FDeleted.Add(Result);
end;

function TXcomSavedBattleGame.NewItem(const ARules: TXcomRuleItem): TXcomBattleItem;
begin
  Result := TXcomBattleItem.Create(ARules, FItemId);
  OwnItem(Result);
end;

procedure TXcomSavedBattleGame.LoadTiles(const ANode: IYamlNode);
var
  LTile: IYamlNode;
  LKey: TXcomTileSerializationKey;
  LTotalTiles: Cardinal;
  LData: TBytes;
  LOffset: Integer;
  LEnd: Integer;
  LIndex: Integer;
  LItem: IYamlNode;
  LPosition: TXcomPosition;
begin
  if not TXcomNodeReader.Field(ANode, 'tileTotalBytesPer').IsDefined then
  begin
    for LItem in TXcomNodeReader.Field(ANode, 'tiles').Items do
    begin
      LPosition := TXcomPosition.Make(0, 0, 0);
      LPosition.X := LItem.Find('position').Items[0].AsInteger;
      LPosition.Y := LItem.Find('position').Items[1].AsInteger;
      LPosition.Z := LItem.Find('position').Items[2].AsInteger;
      TileAt(LPosition).Load(LItem);
    end;
    Exit;
  end;
  LTotalTiles := TXcomNodeReader.ReadSize(ANode, 'totalTiles', 0);
  FillChar(LKey, SizeOf(LKey), 0);
  LKey.Index := ReadCharCode(ANode, 'tileIndexSize', LKey.Index);
  LKey.TotalBytes := TXcomNodeReader.ReadSize(ANode, 'tileTotalBytesPer', LKey.TotalBytes);
  LKey.Fire := ReadCharCode(ANode, 'tileFireSize', LKey.Fire);
  LKey.Smoke := ReadCharCode(ANode, 'tileSmokeSize', LKey.Smoke);
  LKey.MapDataId := ReadCharCode(ANode, 'tileIDSize', LKey.MapDataId);
  LKey.MapDataSetId := ReadCharCode(ANode, 'tileSetIDSize', LKey.MapDataSetId);
  LKey.BoolFields := ReadCharCode(ANode, 'tileBoolFieldsSize', 1);
  LTile := TXcomNodeReader.Field(ANode, 'binTiles');
  LData := TYamlConvert.DecodeBase64(LTile.Scalar);
  LOffset := 0;
  LEnd := Integer(LTotalTiles * LKey.TotalBytes);
  while LOffset < LEnd do
  begin
    case LKey.Index of
      1: LIndex := LData[LOffset];
      2: LIndex := SmallInt(Word(LData[LOffset]) or (Word(LData[LOffset + 1]) shl 8));
      4: LIndex := Integer(Cardinal(LData[LOffset]) or (Cardinal(LData[LOffset + 1]) shl 8) or
        (Cardinal(LData[LOffset + 2]) shl 16) or (Cardinal(LData[LOffset + 3]) shl 24));
    else
      raise EXcomBattleException.Create('Xcom: the tile index of a saved battle has an unsupported size');
    end;
    if (LIndex < 0) or (LIndex >= GetTileCount) then
      raise EXcomBattleException.Create('Xcom: a tile index of a saved battle is out of the map');
    FTiles[LIndex].LoadBinary(LData, LOffset + LKey.Index, LKey);
    Inc(LOffset, LKey.TotalBytes);
  end;
end;

procedure TXcomSavedBattleGame.LoadUnits(const ANode: IYamlNode; const ARuleset: TXcomRuleset;
  ADifficulty: Integer; const ASoldiers: TXcomSoldierLookup);
var
  LItem: IYamlNode;
  LFaction: Integer;
  LOriginalFaction: Integer;
  LId: Integer;
  LUnit: TXcomBattleUnit;
  LSoldier: TXcomSoldier;
  LUnitRules: TXcomRuleUnit;
  LArmor: TXcomArmor;
  LAI: IYamlNode;
  LModule: TXcomAIModule;
  LSelected: Integer;
  LCreated: TXcomBattleUnit;
begin
  LSelected := TXcomNodeReader.Field(ANode, 'selectedUnit').AsInteger;
  for LItem in TXcomNodeReader.Field(ANode, 'units').Items do
  begin
    LFaction := TXcomNodeReader.Field(LItem, 'faction').AsInteger;
    LOriginalFaction := TXcomNodeReader.ReadInteger(LItem, 'originalFaction', LFaction);
    LId := TXcomNodeReader.Field(LItem, 'id').AsInteger;
    if LId < MAX_SOLDIER_ID then
    begin
      LSoldier := ASoldiers(LId);
      if not Assigned(LSoldier) then
        raise EXcomBattleException.CreateFmt('Xcom: the saved battle has a unit of the soldier %d that the ' +
          'saved game does not have', [LId]);
      LUnit := TXcomBattleUnit.Create(FContext, LSoldier, FDepth);
    end
    else
    begin
      LUnitRules := ARuleset.Units.Find(TXcomNodeReader.TextOf(TXcomNodeReader.Field(LItem, 'genUnitType')));
      LArmor := ARuleset.Armors.Find(TXcomNodeReader.TextOf(TXcomNodeReader.Field(LItem, 'genUnitArmor')));
      if not Assigned(LUnitRules) or not Assigned(LArmor) then
        Continue;
      LUnit := TXcomBattleUnit.Create(FContext, LUnitRules, LOriginalFaction, LId, LArmor,
        ARuleset.Settings.StatAdjustment[ADifficulty], FDepth);
    end;
    LCreated := LUnit;
    LUnit.Load(LItem);
    LUnit.SetSpecialWeapon(ARuleset,
      function(ARules: TXcomRuleItem): TXcomBattleItem
      begin
        Result := MakeSpecialItem(ARules, LCreated);
      end);
    FUnits.Add(LUnit);
    if LFaction = FACTION_PLAYER then
      if (LUnit.Id = LSelected) or (not Assigned(FSelectedUnit) and not LUnit.IsOut) then
        FSelectedUnit := LUnit;
    if (LUnit.Status <> STATUS_DEAD) and (LUnit.Status <> STATUS_IGNORE_ME) then
    begin
      LAI := TXcomNodeReader.Field(LItem, 'AI');
      if LAI.IsDefined and (LFaction <> FACTION_PLAYER) then
        begin
          LModule := TXcomAIModule.Create(LUnit, nil);
          LModule.Load(LAI, FNodes);
          LUnit.AI := LModule;
        end;
    end;
  end;
end;

procedure TXcomSavedBattleGame.LoadItems(const ANode: IYamlNode; const ARuleset: TXcomRuleset);
const
  CONTAINER_NAMES: array[0..2] of string = ('items', 'recoverConditional', 'recoverGuaranteed');
var
  LPass: Integer;
  LTarget: TList<TXcomBattleItem>;
  LItem: IYamlNode;
  LType: string;
  LRules: TXcomRuleItem;
  LId: Integer;
  LBattleItem: TXcomBattleItem;
  LOwner: Integer;
  LPreviousOwner: Integer;
  LCorpse: Integer;
  LPosition: TXcomPosition;
  LWeaponIndex: Integer;
  LAmmoId: Integer;
  LCandidate: TXcomBattleItem;
  LUnit: TXcomBattleUnit;
begin
  for LPass := 0 to 2 do
  begin
    case LPass of
      0: LTarget := FItems;
      1: LTarget := FRecoverConditional;
    else
      LTarget := FRecoverGuaranteed;
    end;
    for LItem in TXcomNodeReader.Field(ANode, CONTAINER_NAMES[LPass]).Items do
    begin
      if TXcomNodeReader.Field(LItem, 'owner').IsDefined and
        not TXcomNodeReader.Field(LItem, 'inventoryslot').IsDefined then
        Continue;
      LType := TXcomNodeReader.TextOf(TXcomNodeReader.Field(LItem, 'type'));
      LRules := ARuleset.Items.Find(LType);
      if not Assigned(LRules) then
        Continue;
      LId := TXcomNodeReader.Field(LItem, 'id').AsInteger;
      FItemId := Max(FItemId, LId);
      LBattleItem := TXcomBattleItem.Create(LRules, LId);
      OwnItem(LBattleItem);
      LBattleItem.Load(LItem, ARuleset);
      LOwner := TXcomNodeReader.ReadInteger(LItem, 'owner', -1);
      LPreviousOwner := TXcomNodeReader.ReadInteger(LItem, 'previousOwner', -1);
      LCorpse := TXcomNodeReader.ReadInteger(LItem, 'unit', -1);
      if LOwner <> -1 then
      begin
        LUnit := FindUnit(LOwner);
        if Assigned(LUnit) then
          LBattleItem.MoveToOwner(LUnit);
      end;
      if LPreviousOwner <> -1 then
      begin
        LUnit := FindUnit(LPreviousOwner);
        if Assigned(LUnit) then
          LBattleItem.PreviousOwner := LUnit;
      end;
      if LCorpse <> -1 then
      begin
        LUnit := FindUnit(LCorpse);
        if Assigned(LUnit) then
          LBattleItem.CorpseUnit := LUnit;
      end;
      if Assigned(LBattleItem.Slot) and (LBattleItem.Slot.InventoryType = INV_GROUND) then
      begin
        LPosition := TXcomPositionCodec.Read(LItem, 'position', TXcomPosition.Make(-1, -1, -1));
        if LPosition.X <> -1 then
          TileAt(LPosition).AddItem(LBattleItem, ARuleset.Inventories.Find('STR_GROUND'));
      end;
      LTarget.Add(LBattleItem);
    end;
  end;
  Inc(FItemId);
  // ties the ammo to the weapons, running through the items again
  LWeaponIndex := 0;
  for LItem in TXcomNodeReader.Field(ANode, 'items').Items do
  begin
    if TXcomNodeReader.Field(LItem, 'owner').IsDefined and
      not TXcomNodeReader.Field(LItem, 'inventoryslot').IsDefined then
      Continue;
    if Assigned(ARuleset.Items.Find(TXcomNodeReader.TextOf(TXcomNodeReader.Field(LItem, 'type')))) then
    begin
      LAmmoId := TXcomNodeReader.ReadInteger(LItem, 'ammoItem', -1);
      if LAmmoId <> -1 then
        for LCandidate in FItems do
          if LCandidate.Id = LAmmoId then
          begin
            FItems[LWeaponIndex].SetAmmoItem(LCandidate);
            Break;
          end;
      Inc(LWeaponIndex);
    end;
  end;
end;

procedure TXcomSavedBattleGame.Load(const ANode: IYamlNode; const ARuleset: TXcomRuleset; ADifficulty: Integer;
  const ASoldiers: TXcomSoldierLookup);
var
  LName: IYamlNode;
  LSet: TXcomMapDataSet;
  LNodeItem: IYamlNode;
  LBattleNode: TXcomNode;
  LModules: IYamlNode;
begin
  InitMap(TXcomNodeReader.ReadInteger(ANode, 'width', FSizeX), TXcomNodeReader.ReadInteger(ANode, 'length',
    FSizeY), TXcomNodeReader.ReadInteger(ANode, 'height', FSizeZ));
  FMissionType := TXcomNodeReader.ReadString(ANode, 'missionType', FMissionType);
  FGlobalShade := TXcomNodeReader.ReadInteger(ANode, 'globalshade', FGlobalShade);
  FTurn := TXcomNodeReader.ReadInteger(ANode, 'turn', FTurn);
  FDepth := TXcomNodeReader.ReadInteger(ANode, 'depth', FDepth);
  TXcomNodeReader.Field(ANode, 'selectedUnit').AsInteger;
  for LName in TXcomNodeReader.Field(ANode, 'mapdatasets').Items do
    FMapDataSets.Add(ARuleset.MapDataSets.GetOrCreate(TXcomNodeReader.TextOf(LName)));
  LoadTiles(ANode);
  if FMissionType = 'STR_BASE_DEFENSE' then
  begin
    LModules := TXcomNodeReader.Field(ANode, 'moduleMap');
    if LModules.IsDefined then
      ReadModuleMap(LModules)
    else
      CalculateModuleMap;
  end;
  for LNodeItem in TXcomNodeReader.Field(ANode, 'nodes').Items do
  begin
    LBattleNode := TXcomNode.Create;
    LBattleNode.Load(LNodeItem);
    FNodes.Add(LBattleNode);
  end;
  LoadUnits(ANode, ARuleset, ADifficulty, ASoldiers);
  ResetUnitTiles;
  LoadItems(ANode, ARuleset);
  FObjectiveType := TXcomNodeReader.ReadInteger(ANode, 'objectiveType', FObjectiveType);
  FObjectivesDestroyed := TXcomNodeReader.ReadInteger(ANode, 'objectivesDestroyed', FObjectivesDestroyed);
  FObjectivesNeeded := TXcomNodeReader.ReadInteger(ANode, 'objectivesNeeded', FObjectivesNeeded);
  FTuReserved := TXcomNodeReader.ReadInteger(ANode, 'tuReserved', FTuReserved);
  FKneelReserved := TXcomNodeReader.ReadBoolean(ANode, 'kneelReserved', FKneelReserved);
  FAmbience := TXcomNodeReader.ReadInteger(ANode, 'ambience', FAmbience);
  FAmbientVolume := TXcomNodeReader.ReadDouble(ANode, 'ambientVolume', FAmbientVolume);
  FMusic := TXcomNodeReader.ReadString(ANode, 'music', FMusic);
  FTurnLimit := TXcomNodeReader.ReadInteger(ANode, 'turnLimit', FTurnLimit);
  FChronoTrigger := TXcomNodeReader.ReadInteger(ANode, 'chronoTrigger', FChronoTrigger);
  FCheatTurn := TXcomNodeReader.ReadInteger(ANode, 'cheatTurn', FCheatTurn);
  for LSet in FMapDataSets do
    if LSet.Name = 'BLANKS' then
      FScorchedEarth := LSet.ScorchedEarthTile;
end;

function TXcomSavedBattleGame.Save: IYamlNode;
var
  LIndex: Integer;
  LTile: TXcomTile;
  LKey: TXcomTileSerializationKey;
  LData: TBytes;
  LOffset: Integer;
  LCount: Integer;
  LBinary: IYamlNode;
  LUnit: TXcomBattleUnit;
  LItem: TXcomBattleItem;
  LSet: TXcomMapDataSet;
  LNode: TXcomNode;
begin
  Result := TXcomNodeWriter.NewMap;
  if FObjectivesNeeded <> 0 then
  begin
    TXcomNodeWriter.SetInteger(Result, 'objectivesDestroyed', FObjectivesDestroyed);
    TXcomNodeWriter.SetInteger(Result, 'objectivesNeeded', FObjectivesNeeded);
    TXcomNodeWriter.SetInteger(Result, 'objectiveType', FObjectiveType);
  end;
  TXcomNodeWriter.SetInteger(Result, 'width', FSizeX);
  TXcomNodeWriter.SetInteger(Result, 'length', FSizeY);
  TXcomNodeWriter.SetInteger(Result, 'height', FSizeZ);
  TXcomNodeWriter.SetString(Result, 'missionType', FMissionType);
  TXcomNodeWriter.SetInteger(Result, 'globalshade', FGlobalShade);
  TXcomNodeWriter.SetInteger(Result, 'turn', FTurn);
  if Assigned(FSelectedUnit) then
    TXcomNodeWriter.SetInteger(Result, 'selectedUnit', FSelectedUnit.Id)
  else
    TXcomNodeWriter.SetInteger(Result, 'selectedUnit', -1);
  for LSet in FMapDataSets do
    TXcomNodeWriter.PushBack(Result, 'mapdatasets', TYamlFactory.CreateScalar(YamlStringToText(LSet.Name)));
  LKey := TXcomTileSerializationKey.Current;
  TXcomNodeWriter.SetString(Result, 'tileIndexSize', Chr(LKey.Index));
  TXcomNodeWriter.SetInteger(Result, 'tileTotalBytesPer', Integer(LKey.TotalBytes));
  TXcomNodeWriter.SetString(Result, 'tileFireSize', Chr(LKey.Fire));
  TXcomNodeWriter.SetString(Result, 'tileSmokeSize', Chr(LKey.Smoke));
  TXcomNodeWriter.SetString(Result, 'tileIDSize', Chr(LKey.MapDataId));
  TXcomNodeWriter.SetString(Result, 'tileSetIDSize', Chr(LKey.MapDataSetId));
  TXcomNodeWriter.SetString(Result, 'tileBoolFieldsSize', Chr(LKey.BoolFields));
  SetLength(LData, Integer(LKey.TotalBytes) * GetTileCount);
  LOffset := 0;
  LCount := 0;
  for LIndex := 0 to GetTileCount - 1 do
  begin
    LTile := FTiles[LIndex];
    if not LTile.IsVoid then
    begin
      LData[LOffset] := Byte(LIndex and $FF);
      LData[LOffset + 1] := Byte((LIndex shr 8) and $FF);
      LData[LOffset + 2] := Byte((LIndex shr 16) and $FF);
      LData[LOffset + 3] := Byte((LIndex shr 24) and $FF);
      Inc(LOffset, LKey.Index);
      LTile.SaveBinary(LData, LOffset);
      Inc(LCount);
    end;
  end;
  SetLength(LData, LOffset);
  TXcomNodeWriter.SetInteger(Result, 'totalTiles', LCount);
  LBinary := TYamlFactory.CreateScalar(TYamlConvert.EncodeBase64(LData));
  TXcomNodeWriter.SetNode(Result, 'binTiles', LBinary);
  for LNode in FNodes do
    TXcomNodeWriter.PushBack(Result, 'nodes', LNode.Save);
  if FMissionType = 'STR_BASE_DEFENSE' then
    TXcomNodeWriter.SetNode(Result, 'moduleMap', ModuleMapNode);
  for LUnit in FUnits do
    TXcomNodeWriter.PushBack(Result, 'units', LUnit.Save);
  for LItem in FItems do
    TXcomNodeWriter.PushBack(Result, 'items', LItem.Save);
  TXcomNodeWriter.SetInteger(Result, 'tuReserved', FTuReserved);
  TXcomNodeWriter.SetBoolean(Result, 'kneelReserved', FKneelReserved);
  TXcomNodeWriter.SetInteger(Result, 'depth', FDepth);
  TXcomNodeWriter.SetInteger(Result, 'ambience', FAmbience);
  TXcomNodeWriter.SetDouble(Result, 'ambientVolume', FAmbientVolume);
  for LItem in FRecoverGuaranteed do
    TXcomNodeWriter.PushBack(Result, 'recoverGuaranteed', LItem.Save);
  for LItem in FRecoverConditional do
    TXcomNodeWriter.PushBack(Result, 'recoverConditional', LItem.Save);
  TXcomNodeWriter.SetString(Result, 'music', FMusic);
  TXcomNodeWriter.SetInteger(Result, 'turnLimit', FTurnLimit);
  TXcomNodeWriter.SetInteger(Result, 'chronoTrigger', FChronoTrigger);
  TXcomNodeWriter.SetInteger(Result, 'cheatTurn', FCheatTurn);
end;

procedure TXcomSavedBattleGame.ResolveMapData;
var
  LIndex: Integer;
  LPart: Integer;
  LDataId: Integer;
  LSetId: Integer;
  LSet: TXcomMapDataSet;
begin
  for LSet in FMapDataSets do
    if LSet.Name = 'BLANKS' then
      FScorchedEarth := LSet.ScorchedEarthTile;
  for LIndex := 0 to GetTileCount - 1 do
    for LPart := XCOM_PART_FLOOR to XCOM_PART_OBJECT do
    begin
      FTiles[LIndex].GetMapDataIds(LDataId, LSetId, LPart);
      if (LDataId <> -1) and (LSetId <> -1) then
        FTiles[LIndex].SetMapData(FMapDataSets[LSetId].GetObject(LDataId), LDataId, LSetId, LPart);
    end;
end;

procedure TXcomSavedBattleGame.InitMap(ASizeX, ASizeY, ASizeZ: Integer; AResetTerrain: Boolean);
var
  LIndex: Integer;
  LPosition: TXcomPosition;
begin
  FTiles.Clear;
  FNodes.Clear;
  if AResetTerrain then
    FMapDataSets.Clear;
  FSizeX := ASizeX;
  FSizeY := ASizeY;
  FSizeZ := ASizeZ;
  for LIndex := 0 to GetTileCount - 1 do
  begin
    TileCoords(LIndex, LPosition.X, LPosition.Y, LPosition.Z);
    FTiles.Add(TXcomTile.Create(LPosition, FContext));
  end;
end;

function TXcomSavedBattleGame.TileIndex(const APosition: TXcomPosition): Integer;
begin
  Result := APosition.Z * FSizeY * FSizeX + APosition.Y * FSizeX + APosition.X;
end;

function TXcomSavedBattleGame.TileAt(const APosition: TXcomPosition): TXcomTile;
begin
  if (APosition.X < 0) or (APosition.Y < 0) or (APosition.Z < 0) or (APosition.X >= FSizeX) or
    (APosition.Y >= FSizeY) or (APosition.Z >= FSizeZ) then
    Exit(nil);
  Result := FTiles[TileIndex(APosition)];
end;

function TXcomSavedBattleGame.TileByIndex(AIndex: Integer): TXcomTile;
begin
  Result := FTiles[AIndex];
end;

procedure TXcomSavedBattleGame.TileCoords(AIndex: Integer; out AX, AY, AZ: Integer);
begin
  AZ := AIndex div (FSizeY * FSizeX);
  AY := (AIndex mod (FSizeY * FSizeX)) div FSizeX;
  AX := (AIndex mod (FSizeY * FSizeX)) mod FSizeX;
end;

function TXcomSavedBattleGame.MapSizeXyz: Integer;
begin
  Result := FSizeX * FSizeY * FSizeZ;
end;


function TXcomSavedBattleGame.SelectPlayerUnit(ADirection: Integer; ACheckReselect, ASetReselect,
  ACheckInventory: Boolean): TXcomBattleUnit;
var
  LBegin: Integer;
  LEnd: Integer;
  LIndex: Integer;
begin
  if Assigned(FSelectedUnit) and ASetReselect then
    FSelectedUnit.DontReselect := True;
  if FUnits.Count = 0 then
    Exit(nil);
  LBegin := 0;
  LEnd := 0;
  if ADirection > 0 then
    LEnd := FUnits.Count - 1
  else if ADirection < 0 then
  begin
    LBegin := FUnits.Count - 1;
    LEnd := 0;
  end;
  LIndex := FUnits.IndexOf(FSelectedUnit);
  if LIndex < 0 then
    LIndex := FUnits.Count;
  // a "continue" of the do-while of the C++ goes to its condition, as it does in a repeat loop
  repeat
    if LIndex = FUnits.Count then
    begin
      LIndex := LBegin;
      Continue;
    end;
    if LIndex <> LEnd then
      Inc(LIndex, ADirection)
    else
      LIndex := LBegin;
    if FUnits[LIndex] = FSelectedUnit then
    begin
      if ACheckReselect and FSelectedUnit.DontReselect then
        FSelectedUnit := nil;
      Exit(FSelectedUnit);
    end
    else if not Assigned(FSelectedUnit) and (LIndex = LBegin) then
      Exit(FSelectedUnit);
  until FUnits[LIndex].IsSelectable(FSide, ACheckReselect, ACheckInventory);
  FSelectedUnit := FUnits[LIndex];
  Result := FSelectedUnit;
end;

function TXcomSavedBattleGame.SelectPreviousPlayerUnit(ACheckReselect, ASetReselect, ACheckInventory: Boolean)
  : TXcomBattleUnit;
begin
  Result := SelectPlayerUnit(-1, ACheckReselect, ASetReselect, ACheckInventory);
end;

function TXcomSavedBattleGame.SelectNextPlayerUnit(ACheckReselect, ASetReselect, ACheckInventory: Boolean)
  : TXcomBattleUnit;
begin
  Result := SelectPlayerUnit(1, ACheckReselect, ASetReselect, ACheckInventory);
end;

function TXcomSavedBattleGame.SelectUnit(const APosition: TXcomPosition): TXcomBattleUnit;
begin
  Result := TileAt(APosition).CurrentUnit;
  if Assigned(Result) and Result.IsOut then
    Result := nil;
end;

procedure TXcomSavedBattleGame.TallyUnits(out ALiveAliens, ALiveSoldiers: Integer);
var
  LUnit: TXcomBattleUnit;
begin
  ALiveSoldiers := 0;
  ALiveAliens := 0;
  for LUnit in FUnits do
    if not LUnit.IsOut then
    begin
      if LUnit.OriginalFaction = FACTION_HOSTILE then
      begin
        if not FContext.AllowPsionicCapture or (LUnit.Faction <> FACTION_PLAYER) or not LUnit.Capturable then
          Inc(ALiveAliens);
      end
      else if LUnit.OriginalFaction = FACTION_PLAYER then
      begin
        if LUnit.Faction = FACTION_PLAYER then
          Inc(ALiveSoldiers)
        else
          Inc(ALiveAliens);
      end;
    end;
end;

procedure TXcomSavedBattleGame.EndTurn;
var
  LLiveSoldiers: Integer;
  LLiveAliens: Integer;
  LUnit: TXcomBattleUnit;

  procedure StartPlayerTurn;
  begin
    PrepareNewTurn;
    Inc(FTurn);
    FSide := FACTION_PLAYER;
    if Assigned(FLastSelectedUnit) and FLastSelectedUnit.IsSelectable(FACTION_PLAYER, False, False) then
      FSelectedUnit := FLastSelectedUnit
    else
      SelectNextPlayerUnit;
    while Assigned(FSelectedUnit) and (FSelectedUnit.Faction <> FACTION_PLAYER) do
      SelectNextPlayerUnit;
  end;

begin
  if FSide = FACTION_PLAYER then
  begin
    if Assigned(FSelectedUnit) and (FSelectedUnit.OriginalFaction = FACTION_PLAYER) then
      FLastSelectedUnit := FSelectedUnit;
    FSelectedUnit := nil;
    FSide := FACTION_HOSTILE;
  end
  else if FSide = FACTION_HOSTILE then
  begin
    FSide := FACTION_NEUTRAL;
    // with no neutral team the turn of the player starts at once
    if SelectNextPlayerUnit = nil then
      StartPlayerTurn;
  end
  else if FSide = FACTION_NEUTRAL then
    StartPlayerTurn;
  TallyUnits(LLiveAliens, LLiveSoldiers);
  if ((FTurn > FCheatTurn div 2) and (LLiveAliens <= 2)) or (FTurn > FCheatTurn) then
    FCheating := True;
  if FSide = FACTION_PLAYER then
    for LUnit in FUnits do
    begin
      if LUnit.TurnsSinceSpotted < 255 then
        LUnit.TurnsSinceSpotted := LUnit.TurnsSinceSpotted + 1;
      if FCheating and (LUnit.Faction = FACTION_PLAYER) and not LUnit.IsOut then
        LUnit.TurnsSinceSpotted := 0;
      if Assigned(LUnit.AI) then
        LUnit.AI.Reset;
    end;
  for LUnit in FUnits do
  begin
    if LUnit.Faction = FSide then
      LUnit.PrepareNewTurn;
    if LUnit.Faction <> FACTION_PLAYER then
      LUnit.Visible := False;
  end;
  if Assigned(FTileEngine) then
    FTileEngine.RecalculateFov;
  if FSide <> FACTION_PLAYER then
    SelectNextPlayerUnit;
end;

procedure TXcomSavedBattleGame.SetDebugMode;
var
  LIndex: Integer;
begin
  for LIndex := 0 to GetTileCount - 1 do
    FTiles[LIndex].SetDiscovered(True, 2);
  FDebugMode := True;
end;

procedure TXcomSavedBattleGame.ResetUnitTiles;
var
  LUnit: TXcomBattleUnit;
  LSize: Integer;
  LX: Integer;
  LY: Integer;
  LTile: TXcomTile;
begin
  for LUnit in FUnits do
  begin
    if not LUnit.IsOut then
    begin
      LSize := LUnit.Armor.Size - 1;
      if Assigned(LUnit.Tile) and (LUnit.Tile.CurrentUnit = LUnit) then
        for LX := LSize downto 0 do
          for LY := LSize downto 0 do
            TileAt(LUnit.Tile.Position + TXcomPosition.Make(LX, LY, 0)).SetUnit(nil);
      for LX := LSize downto 0 do
        for LY := LSize downto 0 do
        begin
          LTile := TileAt(LUnit.Position + TXcomPosition.Make(LX, LY, 0));
          LTile.SetUnit(LUnit, TileAt(LTile.Position + TXcomPosition.Make(0, 0, -1)));
        end;
    end;
    if LUnit.Faction = FACTION_PLAYER then
      LUnit.Visible := True;
  end;
  FBeforeGame := False;
end;

procedure TXcomSavedBattleGame.RandomizeItemLocations(const ATile: TXcomTile);
var
  LIndex: Integer;
  LItem: TXcomBattleItem;
begin
  if FStorageSpace.Count = 0 then
    Exit;
  LIndex := 0;
  while LIndex < ATile.Inventory.Count do
  begin
    LItem := ATile.Inventory[LIndex];
    if LItem.Slot.Id = 'STR_GROUND' then
    begin
      TileAt(FStorageSpace[FContext.Random.Generate(0, FStorageSpace.Count - 1)]).AddItem(LItem, LItem.Slot);
      ATile.Inventory.Delete(LIndex);
    end
    else
      Inc(LIndex);
  end;
end;

procedure TXcomSavedBattleGame.RemoveItem(const AItem: TXcomBattleItem);
begin
  if FDeleted.IndexOf(AItem) >= 0 then
    Exit;
  if Assigned(AItem.Tile) then
    AItem.Tile.Inventory.Remove(AItem);
  if Assigned(AItem.Owner) then
    AItem.Owner.Inventory.Remove(AItem);
  FItems.Remove(AItem);
  FDeleted.Add(AItem);
end;

procedure TXcomSavedBattleGame.SetObjectiveCount(ACounter: Integer);
begin
  FObjectivesNeeded := ACounter;
  FObjectivesDestroyed := 0;
end;

function TXcomSavedBattleGame.AddDestroyedObjective: Boolean;
begin
  Result := False;
  if not AllObjectivesDestroyed then
  begin
    Inc(FObjectivesDestroyed);
    Result := AllObjectivesDestroyed;
  end;
end;

function TXcomSavedBattleGame.AllObjectivesDestroyed: Boolean;
begin
  Result := (FObjectivesNeeded > 0) and (FObjectivesDestroyed = FObjectivesNeeded);
end;

function TXcomSavedBattleGame.GetSpawnNode(ANodeRank: Integer; const AUnit: TXcomBattleUnit): TXcomNode;
var
  LHighest: Integer;
  LCompliant: TList<TXcomNode>;
  LNode: TXcomNode;
begin
  LHighest := -1;
  LCompliant := TList<TXcomNode>.Create;
  try
    for LNode in FNodes do
    begin
      if LNode.Dummy then
        Continue;
      if (LNode.Rank = ANodeRank) and (((LNode.NodeType and NODE_TYPE_SMALL) = 0) or (AUnit.Armor.Size = 1)) and
        (((LNode.NodeType and NODE_TYPE_FLYING) = 0) or (AUnit.MovementType = MT_FLY)) and (LNode.Priority > 0) and
        SetUnitPosition(AUnit, LNode.Position, True) then
      begin
        if LNode.Priority > LHighest then
        begin
          LHighest := LNode.Priority;
          LCompliant.Clear;
        end;
        if LNode.Priority = LHighest then
          LCompliant.Add(LNode);
      end;
    end;
    if LCompliant.Count = 0 then
      Exit(nil);
    Result := LCompliant[FContext.Random.Generate(0, LCompliant.Count - 1)];
  finally
    LCompliant.Free;
  end;
end;

function TXcomSavedBattleGame.GetPatrolNode(AScout: Boolean; const AUnit: TXcomBattleUnit;
  AFromNode: TXcomNode): TXcomNode;
var
  LCompliant: TList<TXcomNode>;
  LPreferred: TXcomNode;
  LEnd: Integer;
  LIndex: Integer;
  LNode: TXcomNode;
  LTile: TXcomTile;

  function NodeAt(AIndex: Integer): TXcomNode;
  begin
    if (AIndex < 0) or (AIndex >= FNodes.Count) then
      raise EXcomBattleException.Create('Xcom: a patrol node is out of the list of nodes');
    Result := FNodes[AIndex];
  end;

begin
  LPreferred := nil;
  LCompliant := TList<TXcomNode>.Create;
  try
    if not Assigned(AFromNode) then
    begin
      AFromNode := NodeAt(FContext.Random.Generate(0, FNodes.Count - 1));
      while AFromNode.Dummy do
        AFromNode := NodeAt(FContext.Random.Generate(0, FNodes.Count - 1));
    end;
    if AScout then
      LEnd := FNodes.Count
    else
      LEnd := Length(AFromNode.Links);
    for LIndex := 0 to LEnd - 1 do
    begin
      if not AScout and (AFromNode.Links[LIndex] < 1) then
        Continue;
      if AScout then
        LNode := NodeAt(LIndex)
      else
        LNode := NodeAt(AFromNode.Links[LIndex]);
      if not LNode.Dummy and ((LNode.Flags > 0) or (LNode.Rank > 0) or AScout) and
        (((LNode.NodeType and NODE_TYPE_SMALL) = 0) or (AUnit.Armor.Size = 1)) and
        (((LNode.NodeType and NODE_TYPE_FLYING) = 0) or (AUnit.MovementType = MT_FLY)) and not LNode.Allocated and
        ((LNode.NodeType and NODE_TYPE_DANGEROUS) = 0) and SetUnitPosition(AUnit, LNode.Position, True) then
      begin
        LTile := TileAt(LNode.Position);
        if Assigned(LTile) and (LTile.Fire = 0) and ((AUnit.Faction <> FACTION_HOSTILE) or not LTile.Dangerous) and
          (not AScout or (LNode <> AFromNode)) and (LNode.Position.X > 0) and (LNode.Position.Y > 0) then
        begin
          if not Assigned(LPreferred) or
            ((AUnit.RankInt >= 0) and (LPreferred.Rank = NODE_RANK[AUnit.RankInt, 0]) and
            (LPreferred.Flags < LNode.Flags)) or (LPreferred.Flags < LNode.Flags) then
            LPreferred := LNode;
          LCompliant.Add(LNode);
        end;
      end;
    end;
    if LCompliant.Count = 0 then
    begin
      if (AUnit.Armor.Size > 1) and not AScout then
        Exit(GetPatrolNode(True, AUnit, AFromNode));
      Exit(nil);
    end;
    if AScout then
      Exit(LCompliant[FContext.Random.Generate(0, LCompliant.Count - 1)]);
    Result := LPreferred;
  finally
    LCompliant.Free;
  end;
end;

procedure TXcomSavedBattleGame.PrepareNewTurn;
var
  LOnFire: TList<TXcomTile>;
  LOnSmoke: TList<TXcomTile>;
  LTile: TXcomTile;
  LIndex: Integer;
  LDirection: Integer;
  LTarget: TXcomTile;
  LAbove: TXcomTile;
  LPart: TXcomMapData;

  function Neighbour(const AFrom: TXcomTile; ADir: Integer): TXcomTile;
  begin
    Result := TileAt(AFrom.Position + TXcomDirections.ToVector(ADir));
  end;

begin
  LOnFire := TList<TXcomTile>.Create;
  LOnSmoke := TList<TXcomTile>.Create;
  try
    for LIndex := 0 to GetTileCount - 1 do
      if FTiles[LIndex].Fire > 0 then
        LOnFire.Add(FTiles[LIndex]);
    for LTile in LOnFire do
      if LTile.Overlaps = 0 then
      begin
        LTile.SetFire(LTile.Fire - 1);
        if LTile.Fire <> 0 then
        begin
          LDirection := 0;
          while LDirection <= 6 do
          begin
            LTarget := Neighbour(LTile, LDirection);
            if Assigned(LTarget) and (FTileEngine.HorizontalBlockage(LTile, LTarget, 2) = 0) then
              LTarget.Ignite(LTile.Smoke);
            Inc(LDirection, 2);
          end;
        end
        else
        begin
          LTile.SetSmoke(0);
          LPart := LTile.MapData[XCOM_PART_OBJECT];
          if Assigned(LPart) then
          begin
            if (LPart.Flammable <> 255) and (LPart.Armor <> 255) then
            begin
              if LTile.DestroyPart(XCOM_PART_OBJECT, FObjectiveType, FScorchedEarth) then
                AddDestroyedObjective;
              if LTile.DestroyPart(XCOM_PART_FLOOR, FObjectiveType, FScorchedEarth) then
                AddDestroyedObjective;
            end;
          end
          else if Assigned(LTile.MapData[XCOM_PART_FLOOR]) then
            if (LTile.MapData[XCOM_PART_FLOOR].Flammable <> 255) and (LTile.MapData[XCOM_PART_FLOOR].Armor <> 255) then
              if LTile.DestroyPart(XCOM_PART_FLOOR, FObjectiveType, FScorchedEarth) then
                AddDestroyedObjective;
          FTileEngine.ApplyGravity(LTile);
        end;
      end;
    for LIndex := 0 to GetTileCount - 1 do
    begin
      if FTiles[LIndex].Smoke > 0 then
        LOnSmoke.Add(FTiles[LIndex]);
      FTiles[LIndex].Dangerous := False;
    end;
    for LTile in LOnSmoke do
    begin
      if LTile.Fire = 0 then
      begin
        LTile.SetSmoke(LTile.Smoke - 1);
        if LTile.Smoke <> 0 then
        begin
          LDirection := 0;
          while LDirection <= 6 do
          begin
            LTarget := Neighbour(LTile, LDirection);
            if Assigned(LTarget) and (FTileEngine.HorizontalBlockage(LTile, LTarget, 9) = 0) then
              if (LTarget.Smoke = 0) or ((LTarget.Fire = 0) and (LTarget.Overlaps <> 0)) then
                LTarget.AddSmoke(LTile.Smoke);
            Inc(LDirection, 2);
          end;
        end;
      end
      else
      begin
        LAbove := TileAt(LTile.Position + TXcomPosition.Make(0, 0, 1));
        if Assigned(LAbove) and LAbove.HasNoFloor(LTile) then
          LAbove.AddSmoke(LTile.Smoke div 2);
        LDirection := 0;
        while LDirection <= 6 do
        begin
          LTarget := Neighbour(LTile, LDirection);
          if Assigned(LTarget) and (FTileEngine.HorizontalBlockage(LTile, LTarget, 9) = 0) then
            LTarget.AddSmoke(LTile.Smoke div 2);
          Inc(LDirection, 2);
        end;
      end;
    end;
    if (LOnFire.Count > 0) or (LOnSmoke.Count > 0) then
    begin
      for LIndex := 0 to GetTileCount - 1 do
        if FTiles[LIndex].Smoke <> 0 then
          FTiles[LIndex].PrepareNewTurn(FDepth = 0);
      FTileEngine.CalculateTerrainLighting;
    end;
  finally
    LOnFire.Free;
    LOnSmoke.Free;
  end;
  ReviveUnconsciousUnits;
end;

procedure TXcomSavedBattleGame.ReviveUnconsciousUnits;
var
  LUnit: TXcomBattleUnit;
  LItem: TXcomBattleItem;
  LOriginal: TXcomPosition;
  LTarget: TXcomTile;
  LLarge: Boolean;
begin
  for LUnit in FUnits do
    if LUnit.Armor.Size = 1 then
    begin
      LOriginal := LUnit.Position;
      if (LOriginal.X = -1) and (LOriginal.Y = -1) and (LOriginal.Z = -1) then
        for LItem in FItems do
          if Assigned(LItem.CorpseUnit) and (LItem.CorpseUnit = LUnit) and Assigned(LItem.Owner) then
            LOriginal := LItem.Owner.Position;
      if (LUnit.Status = STATUS_UNCONSCIOUS) and (LUnit.StunLevel < LUnit.Health) and (LUnit.Health > 0) then
      begin
        LTarget := TileAt(LOriginal);
        LLarge := Assigned(LTarget) and Assigned(LTarget.CurrentUnit) and (LTarget.CurrentUnit <> LUnit) and
          (LTarget.CurrentUnit.Armor.Size <> 1);
        if PlaceUnitNearPosition(LUnit, LOriginal, LLarge) then
        begin
          LUnit.Turn(False);
          LUnit.Kneel(False);
          LUnit.CacheInvalid := True;
          if Assigned(FTileEngine) then
          begin
            FTileEngine.CalculateFov(LUnit);
            FTileEngine.CalculateUnitLighting;
          end;
          RemoveUnconsciousBodyItem(LUnit);
        end;
      end;
    end;
end;

procedure TXcomSavedBattleGame.RemoveUnconsciousBodyItem(const AUnit: TXcomBattleUnit);
var
  LItem: TXcomBattleItem;
begin
  for LItem in FItems do
    if LItem.CorpseUnit = AUnit then
    begin
      RemoveItem(LItem);
      Break;
    end;
end;

function TXcomSavedBattleGame.SetUnitPosition(const AUnit: TXcomBattleUnit; const APosition: TXcomPosition;
  ATestOnly: Boolean): Boolean;
var
  LSize: Integer;
  LOffsetZ: Integer;
  LX: Integer;
  LY: Integer;
  LTile: TXcomTile;
  LBelow: TXcomTile;
  LDirection: Integer;
begin
  LSize := AUnit.Armor.Size - 1;
  LOffsetZ := 0;
  LX := LSize;
  while LX >= 0 do
  begin
    LY := LSize;
    while LY >= 0 do
    begin
      LTile := TileAt(APosition + TXcomPosition.Make(LX, LY, LOffsetZ));
      LBelow := TileAt(APosition + TXcomPosition.Make(LX, LY, LOffsetZ - 1));
      if not Assigned(LTile) or (Assigned(LTile.CurrentUnit) and (LTile.CurrentUnit <> AUnit)) or
        (LTile.GetTuCost(XCOM_PART_OBJECT, AUnit.MovementType) = 255) or
        (LTile.HasNoFloor(LBelow) and (AUnit.MovementType <> MT_FLY)) or
        (Assigned(LTile.MapData[XCOM_PART_OBJECT]) and (LTile.MapData[XCOM_PART_OBJECT].BigWall <> 0) and
        (LTile.MapData[XCOM_PART_OBJECT].BigWall <= 3)) then
        Exit(False);
      // move the unit up to the next level (desert and seabed terrains)
      if LTile.GetTerrainLevel = -24 then
      begin
        Inc(LOffsetZ);
        LX := LSize;
        LY := LSize + 1;
      end;
      Dec(LY);
    end;
    Dec(LX);
  end;
  if LSize > 0 then
  begin
    FPathfinder.SetUnit(AUnit);
    for LDirection := 2 to 4 do
      if FPathfinder.IsBlocked(TileAt(APosition + TXcomPosition.Make(0, 0, LOffsetZ)), nil, LDirection, nil) then
        Exit(False);
  end;
  if ATestOnly then
    Exit(True);
  for LX := LSize downto 0 do
    for LY := LSize downto 0 do
    begin
      if (LX = 0) and (LY = 0) then
        AUnit.SetPosition(APosition + TXcomPosition.Make(0, 0, LOffsetZ));
      TileAt(APosition + TXcomPosition.Make(LX, LY, LOffsetZ)).SetUnit(AUnit,
        TileAt(APosition + TXcomPosition.Make(LX, LY, LOffsetZ - 1)));
    end;
  Result := True;
end;

function TXcomSavedBattleGame.EyesOnTarget(AFaction: Integer; const AUnit: TXcomBattleUnit): Boolean;
var
  LUnit: TXcomBattleUnit;
begin
  for LUnit in FUnits do
    if (LUnit.Faction = AFaction) and (LUnit.VisibleUnits.IndexOf(AUnit) >= 0) then
      Exit(True);
  Result := False;
end;

function TXcomSavedBattleGame.AddFallingUnit(const AUnit: TXcomBattleUnit): Boolean;
begin
  Result := FFallingUnits.IndexOf(AUnit) < 0;
  if Result then
  begin
    FFallingUnits.Insert(0, AUnit);
    FUnitsFalling := True;
  end;
end;

function TXcomSavedBattleGame.GetHighestRankedXcom: TXcomBattleUnit;
var
  LUnit: TXcomBattleUnit;
begin
  Result := nil;
  for LUnit in FUnits do
    if (LUnit.OriginalFaction = FACTION_PLAYER) and not LUnit.IsOut then
      if not Assigned(Result) or (LUnit.RankInt > Result.RankInt) then
        Result := LUnit;
end;

function TXcomSavedBattleGame.GetMoraleModifier(const AUnit: TXcomBattleUnit): Integer;
var
  LLeader: TXcomBattleUnit;
begin
  Result := 100;
  if not Assigned(AUnit) then
  begin
    LLeader := GetHighestRankedXcom;
    if Assigned(LLeader) then
    begin
      // the cases of the switch fall through
      if LLeader.RankInt >= 5 then
        Inc(Result, 25);
      if LLeader.RankInt >= 4 then
        Inc(Result, 10);
      if LLeader.RankInt >= 3 then
        Inc(Result, 5);
      if LLeader.RankInt >= 2 then
        Inc(Result, 10);
    end;
  end
  else if AUnit.Faction = FACTION_PLAYER then
  begin
    if AUnit.RankInt = 5 then
      Inc(Result, 25 + 20 + 10 + 20)
    else if AUnit.RankInt = 4 then
      Inc(Result, 20 + 10 + 20)
    else if AUnit.RankInt = 3 then
      Inc(Result, 10 + 20)
    else if AUnit.RankInt = 2 then
      Inc(Result, 20);
  end;
end;

function TXcomSavedBattleGame.PlaceUnitNearPosition(const AUnit: TXcomBattleUnit; const AEntryPoint: TXcomPosition;
  ALargeFriend: Boolean): Boolean;
var
  LMe: Integer;
  LYou: Integer;
  LX: array[0..7] of Integer;
  LY: array[0..7] of Integer;
  LDirection: Integer;
  LOffset: TXcomPosition;
  LTile: TXcomTile;
  LAbove: TXcomTile;
begin
  if SetUnitPosition(AUnit, AEntryPoint) then
    Exit(True);
  LMe := 0 - AUnit.Armor.Size;
  if ALargeFriend then
    LYou := 2
  else
    LYou := 1;
  LX[0] := 0; LX[1] := LYou; LX[2] := LYou; LX[3] := LYou; LX[4] := 0; LX[5] := LMe; LX[6] := LMe; LX[7] := LMe;
  LY[0] := LMe; LY[1] := LMe; LY[2] := 0; LY[3] := LYou; LY[4] := LYou; LY[5] := LYou; LY[6] := 0; LY[7] := LMe;
  for LDirection := 0 to 7 do
  begin
    LOffset := TXcomPosition.Make(LX[LDirection], LY[LDirection], 0);
    LTile := TileAt(AEntryPoint + LOffset);
    if Assigned(LTile) and not FPathfinder.IsBlocked(TileAt(AEntryPoint + (LOffset div 2)), LTile, LDirection, nil) and
      SetUnitPosition(AUnit, AEntryPoint + LOffset) then
      Exit(True);
  end;
  if AUnit.MovementType = MT_FLY then
  begin
    LAbove := TileAt(AEntryPoint + TXcomPosition.Make(0, 0, 1));
    if Assigned(LAbove) and LAbove.HasNoFloor(TileAt(AEntryPoint)) and
      SetUnitPosition(AUnit, AEntryPoint + TXcomPosition.Make(0, 0, 1)) then
      Exit(True);
  end;
  Result := False;
end;

procedure TXcomSavedBattleGame.ResetTurnCounter;
begin
  FTurn := 1;
  FCheating := False;
  FSide := FACTION_PLAYER;
  FBeforeGame := True;
end;

procedure TXcomSavedBattleGame.ResetTiles;
var
  LIndex: Integer;
begin
  for LIndex := 0 to GetTileCount - 1 do
  begin
    FTiles[LIndex].SetDiscovered(False, 0);
    FTiles[LIndex].SetDiscovered(False, 1);
    FTiles[LIndex].SetDiscovered(False, 2);
  end;
end;

procedure TXcomSavedBattleGame.ReadModuleMap(const ANode: IYamlNode);
var
  LColumns: TArray<IYamlNode>;
  LCells: TArray<IYamlNode>;
  LColumn: Integer;
  LCell: Integer;
  LFirst: Integer;
  LSecond: Integer;
begin
  LColumns := ANode.Items;
  SetLength(FBaseModules, Length(LColumns));
  for LColumn := 0 to High(LColumns) do
  begin
    LCells := LColumns[LColumn].Items;
    SetLength(FBaseModules[LColumn], Length(LCells));
    for LCell := 0 to High(LCells) do
    begin
      TXcomNodeReader.RequireIntPair(LCells[LCell], LFirst, LSecond);
      FBaseModules[LColumn][LCell] := TPair<Integer, Integer>.Create(LFirst, LSecond);
    end;
  end;
end;

function TXcomSavedBattleGame.ModuleMapNode: IYamlNode;
var
  LColumn: Integer;
  LCell: Integer;
  LColumnNode: IYamlNode;
  LPair: IYamlNode;
begin
  Result := TXcomNodeWriter.NewSequence;
  for LColumn := 0 to High(FBaseModules) do
  begin
    LColumnNode := TXcomNodeWriter.NewSequence;
    for LCell := 0 to High(FBaseModules[LColumn]) do
    begin
      LPair := TXcomNodeWriter.NewSequence;
      LPair.Add(YamlStringToText(IntToStr(FBaseModules[LColumn][LCell].Key)));
      LPair.Add(YamlStringToText(IntToStr(FBaseModules[LColumn][LCell].Value)));
      LColumnNode.Add(LPair);
    end;
    Result.Add(LColumnNode);
  end;
end;

procedure TXcomSavedBattleGame.CalculateModuleMap;
var
  LColumn: Integer;
  LRow: Integer;
  LX: Integer;
  LY: Integer;
  LZ: Integer;
  LTile: TXcomTile;
  LCount: Integer;
  LCell: TPair<Integer, Integer>;
begin
  // resize(): the columns that exist stay, the new ones are filled with (-1, -1)
  LCount := Length(FBaseModules);
  if LCount < FSizeX div 10 then
  begin
    SetLength(FBaseModules, FSizeX div 10);
    for LColumn := LCount to High(FBaseModules) do
    begin
      SetLength(FBaseModules[LColumn], FSizeY div 10);
      for LRow := 0 to High(FBaseModules[LColumn]) do
        FBaseModules[LColumn][LRow] := TPair<Integer, Integer>.Create(-1, -1);
    end;
  end;
  for LX := 0 to FSizeX - 1 do
    for LY := 0 to FSizeY - 1 do
      for LZ := 0 to FSizeZ - 1 do
      begin
        LTile := TileAt(TXcomPosition.Make(LX, LY, LZ));
        if Assigned(LTile) and Assigned(LTile.MapData[XCOM_PART_OBJECT]) and
          LTile.MapData[XCOM_PART_OBJECT].IsBaseModule then
        begin
          LCell := FBaseModules[LX div 10][LY div 10];
          if LCell.Key > 0 then
            LCell := TPair<Integer, Integer>.Create(LCell.Key + 1, LCell.Key + 1)
          else
            LCell := TPair<Integer, Integer>.Create(LCell.Key + 2, LCell.Key + 2);
          FBaseModules[LX div 10][LY div 10] := LCell;
        end;
      end;
end;

function TXcomSavedBattleGame.GetItemUsable(const AItem: TXcomBattleItem): string;
begin
  if (FDepth = 0) and (AItem.Rules.UnderwaterOnly or (Assigned(AItem.AmmoItem) and AItem.AmmoItem.Rules.UnderwaterOnly)) then
    Exit('STR_UNDERWATER_EQUIPMENT');
  if (FDepth <> 0) and (AItem.Rules.LandOnly or (Assigned(AItem.AmmoItem) and AItem.AmmoItem.Rules.LandOnly)) then
    Exit('STR_LAND_EQUIPMENT');
  Result := '';
end;

function TXcomSavedBattleGame.IsItemUsable(const AItem: TXcomBattleItem): Boolean;
begin
  Result := GetItemUsable(AItem) = '';
end;

procedure TXcomSavedBattleGame.ResetUnitHitStates;
var
  LUnit: TXcomBattleUnit;
begin
  for LUnit in FUnits do
    LUnit.ResetHitState;
end;

end.
