{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - the ruleset (the rules part of Mod:       }
{  loadFile and the tables of rules)                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.Ruleset;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomMod.ModOffsets, DelphiDoom.XcomMod.RuleRegistry, DelphiDoom.XcomMod.RuleCountry,
  DelphiDoom.XcomMod.RuleRegion, DelphiDoom.XcomMod.RuleInventory, DelphiDoom.XcomMod.RuleResearch,
  DelphiDoom.XcomMod.RuleManufacture, DelphiDoom.XcomMod.AlienRace, DelphiDoom.XcomMod.UfoTrajectory,
  DelphiDoom.XcomMod.RuleMusic, DelphiDoom.XcomMod.RuleCommendations, DelphiDoom.XcomMod.RuleCraftWeapon,
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomMod.RuleBaseFacility, DelphiDoom.XcomMod.RuleCraft,
  DelphiDoom.XcomMod.RuleUfo, DelphiDoom.XcomMod.RuleTerrain, DelphiDoom.XcomMod.MapDataSet,
  DelphiDoom.XcomMod.Armor, DelphiDoom.XcomMod.RuleSoldier, DelphiDoom.XcomMod.RuleUnit,
  DelphiDoom.XcomMod.ModFiles.Intf, DelphiDoom.XcomMod.AlienDeployment, DelphiDoom.XcomMod.RuleAlienMission,
  DelphiDoom.XcomMod.RuleMissionScript;

type
  /// <summary>
  ///   The ruleset of the game: the rules of every kind, by name, filled by LoadFile from the YAML files of the
  ///   mods in load order (Mod). It does not hold the resources (surfaces, sounds, palettes): the sets that the
  ///   offsets need come from IXcomSharedResources
  /// </summary>
  TXcomRuleset = class
  strict private
    FShared: IXcomSharedResources;
    FFiles: IXcomModFiles;
    FOffsets: TXcomModOffsets;
    FAlienDeployments: TXcomRuleRegistry<TXcomAlienDeployment>;
    FAlienMissions: TXcomRuleRegistry<TXcomRuleAlienMission>;
    FMissionScripts: TXcomRuleRegistry<TXcomRuleMissionScript>;
    FArmors: TXcomRuleRegistry<TXcomArmor>;
    FSoldiers: TXcomRuleRegistry<TXcomRuleSoldier>;
    FUnits: TXcomRuleRegistry<TXcomRuleUnit>;
    FCountries: TXcomRuleRegistry<TXcomRuleCountry>;
    FRegions: TXcomRuleRegistry<TXcomRuleRegion>;
    FFacilities: TXcomRuleRegistry<TXcomRuleBaseFacility>;
    FCrafts: TXcomRuleRegistry<TXcomRuleCraft>;
    FCraftWeapons: TXcomRuleRegistry<TXcomRuleCraftWeapon>;
    FItems: TXcomRuleRegistry<TXcomRuleItem>;
    FUfos: TXcomRuleRegistry<TXcomRuleUfo>;
    FInventories: TXcomRuleRegistry<TXcomRuleInventory>;
    FTerrains: TXcomRuleRegistry<TXcomRuleTerrain>;
    FMapDataSets: TXcomRuleRegistry<TXcomMapDataSet>;
    FResearch: TXcomRuleRegistry<TXcomRuleResearch>;
    FManufacture: TXcomRuleRegistry<TXcomRuleManufacture>;
    FAlienRaces: TXcomRuleRegistry<TXcomAlienRace>;
    FUfoTrajectories: TXcomRuleRegistry<TXcomUfoTrajectory>;
    FMusics: TXcomRuleRegistry<TXcomRuleMusic>;
    FCommendations: TXcomStringMap<TXcomRuleCommendations>;
    FFacilityListOrder: Integer;
    FCraftListOrder: Integer;
    FItemListOrder: Integer;
    FInventoryListOrder: Integer;
    FResearchListOrder: Integer;
    FManufactureListOrder: Integer;
    FFinalResearch: string;
    procedure LoadFacilities(const ADocument: IYamlNode);
    procedure LoadCrafts(const ADocument: IYamlNode);
    procedure LoadUfos(const ADocument: IYamlNode);
    procedure LoadTerrains(const ADocument: IYamlNode);
    procedure LoadPeople(const ADocument: IYamlNode);
    procedure LoadDeployments(const ADocument: IYamlNode);
    procedure LoadAlienMissions(const ADocument: IYamlNode);
    procedure LoadMissionScripts(const ADocument: IYamlNode);
    procedure LoadCommendations(const ADocument: IYamlNode);
    procedure LoadResearch(const ADocument: IYamlNode);
  public
    /// <param name="AShared">The sizes of the common resource sets (the offsets of the rules need them)</param>
    /// <param name="AFiles">The virtual files of the mods (the lists of soldier names); nil if there are none</param>
    constructor Create(const AShared: IXcomSharedResources; const AFiles: IXcomModFiles = nil);
    destructor Destroy; override;
    /// <summary>
    ///   Sets the mods that share the sets (_modData) and the one that is being loaded (_modCurrent), the
    ///   position in AMods of the next file to load
    /// </summary>
    procedure SetMods(const AMods: TArray<TXcomModData>; ACurrent: Integer);
    /// <summary>Mod::loadFile: the rules of a ruleset file; rules with the same name overwrite those that exist</summary>
    procedure LoadFile(const ADocument: IYamlNode);
    /// <summary>
    ///   The checks that Mod::loadMod makes when the files of a mod are loaded: the missions of the scripts and
    ///   the missions that the regions pick from must be defined, and must not mix terror sites with the others
    ///   (EXcomModException with the message of the C++)
    /// </summary>
    procedure ValidateMissions;
    property Offsets: TXcomModOffsets read FOffsets;
    property Countries: TXcomRuleRegistry<TXcomRuleCountry> read FCountries;
    property Regions: TXcomRuleRegistry<TXcomRuleRegion> read FRegions;
    property Facilities: TXcomRuleRegistry<TXcomRuleBaseFacility> read FFacilities;
    property Crafts: TXcomRuleRegistry<TXcomRuleCraft> read FCrafts;
    property CraftWeapons: TXcomRuleRegistry<TXcomRuleCraftWeapon> read FCraftWeapons;
    property Items: TXcomRuleRegistry<TXcomRuleItem> read FItems;
    property Ufos: TXcomRuleRegistry<TXcomRuleUfo> read FUfos;
    property Inventories: TXcomRuleRegistry<TXcomRuleInventory> read FInventories;
    property Terrains: TXcomRuleRegistry<TXcomRuleTerrain> read FTerrains;
    property AlienDeployments: TXcomRuleRegistry<TXcomAlienDeployment> read FAlienDeployments;
    property AlienMissions: TXcomRuleRegistry<TXcomRuleAlienMission> read FAlienMissions;
    property MissionScripts: TXcomRuleRegistry<TXcomRuleMissionScript> read FMissionScripts;
    property Armors: TXcomRuleRegistry<TXcomArmor> read FArmors;
    property Soldiers: TXcomRuleRegistry<TXcomRuleSoldier> read FSoldiers;
    property Units: TXcomRuleRegistry<TXcomRuleUnit> read FUnits;
    /// <summary>The map data files that the terrains refer to (Mod::getMapDataSet makes them on demand)</summary>
    property MapDataSets: TXcomRuleRegistry<TXcomMapDataSet> read FMapDataSets;
    property Research: TXcomRuleRegistry<TXcomRuleResearch> read FResearch;
    property Manufacture: TXcomRuleRegistry<TXcomRuleManufacture> read FManufacture;
    property AlienRaces: TXcomRuleRegistry<TXcomAlienRace> read FAlienRaces;
    property UfoTrajectories: TXcomRuleRegistry<TXcomUfoTrajectory> read FUfoTrajectories;
    property Musics: TXcomRuleRegistry<TXcomRuleMusic> read FMusics;
    property Commendations: TXcomStringMap<TXcomRuleCommendations> read FCommendations;
    /// <summary>getFinalResearch: the research that unlocks the final mission</summary>
    property FinalResearch: string read FFinalResearch;
  end;

implementation

{ TXcomRuleset }

constructor TXcomRuleset.Create(const AShared: IXcomSharedResources; const AFiles: IXcomModFiles);
begin
  inherited Create;
  if not Assigned(AShared) then
    raise EArgumentNilException.Create('AShared');
  FShared := AShared;
  FFiles := AFiles;
  FAlienDeployments := TXcomRuleRegistry<TXcomAlienDeployment>.Create(
    function(AType: string): TXcomAlienDeployment begin Result := TXcomAlienDeployment.Create(AType); end);
  FAlienMissions := TXcomRuleRegistry<TXcomRuleAlienMission>.Create(
    function(AType: string): TXcomRuleAlienMission begin Result := TXcomRuleAlienMission.Create(AType); end);
  FMissionScripts := TXcomRuleRegistry<TXcomRuleMissionScript>.Create(
    function(AType: string): TXcomRuleMissionScript begin Result := TXcomRuleMissionScript.Create(AType); end);
  FArmors := TXcomRuleRegistry<TXcomArmor>.Create(
    function(AType: string): TXcomArmor begin Result := TXcomArmor.Create(AType); end);
  FSoldiers := TXcomRuleRegistry<TXcomRuleSoldier>.Create(
    function(AType: string): TXcomRuleSoldier begin Result := TXcomRuleSoldier.Create(AType); end);
  FUnits := TXcomRuleRegistry<TXcomRuleUnit>.Create(
    function(AType: string): TXcomRuleUnit begin Result := TXcomRuleUnit.Create(AType); end);
  FCountries := TXcomRuleRegistry<TXcomRuleCountry>.Create(
    function(AType: string): TXcomRuleCountry begin Result := TXcomRuleCountry.Create(AType); end);
  FRegions := TXcomRuleRegistry<TXcomRuleRegion>.Create(
    function(AType: string): TXcomRuleRegion begin Result := TXcomRuleRegion.Create(AType); end);
  FFacilities := TXcomRuleRegistry<TXcomRuleBaseFacility>.Create(
    function(AType: string): TXcomRuleBaseFacility begin Result := TXcomRuleBaseFacility.Create(AType); end);
  FCrafts := TXcomRuleRegistry<TXcomRuleCraft>.Create(
    function(AType: string): TXcomRuleCraft begin Result := TXcomRuleCraft.Create(AType); end);
  FCraftWeapons := TXcomRuleRegistry<TXcomRuleCraftWeapon>.Create(
    function(AType: string): TXcomRuleCraftWeapon begin Result := TXcomRuleCraftWeapon.Create(AType); end);
  FItems := TXcomRuleRegistry<TXcomRuleItem>.Create(
    function(AType: string): TXcomRuleItem begin Result := TXcomRuleItem.Create(AType); end);
  FUfos := TXcomRuleRegistry<TXcomRuleUfo>.Create(
    function(AType: string): TXcomRuleUfo begin Result := TXcomRuleUfo.Create(AType); end);
  FInventories := TXcomRuleRegistry<TXcomRuleInventory>.Create(
    function(AType: string): TXcomRuleInventory begin Result := TXcomRuleInventory.Create(AType); end);
  FTerrains := TXcomRuleRegistry<TXcomRuleTerrain>.Create(
    function(AType: string): TXcomRuleTerrain begin Result := TXcomRuleTerrain.Create(AType); end);
  FMapDataSets := TXcomRuleRegistry<TXcomMapDataSet>.Create(
    function(AType: string): TXcomMapDataSet begin Result := TXcomMapDataSet.Create(AType); end);
  FResearch := TXcomRuleRegistry<TXcomRuleResearch>.Create(
    function(AType: string): TXcomRuleResearch begin Result := TXcomRuleResearch.Create(AType); end);
  FManufacture := TXcomRuleRegistry<TXcomRuleManufacture>.Create(
    function(AType: string): TXcomRuleManufacture begin Result := TXcomRuleManufacture.Create(AType); end);
  FAlienRaces := TXcomRuleRegistry<TXcomAlienRace>.Create(
    function(AType: string): TXcomAlienRace begin Result := TXcomAlienRace.Create(AType); end);
  FUfoTrajectories := TXcomRuleRegistry<TXcomUfoTrajectory>.Create(
    function(AType: string): TXcomUfoTrajectory begin Result := TXcomUfoTrajectory.Create(AType); end);
  FMusics := TXcomRuleRegistry<TXcomRuleMusic>.Create(
    function(AType: string): TXcomRuleMusic begin Result := TXcomRuleMusic.Create(AType); end);
  FCommendations := TXcomStringMap<TXcomRuleCommendations>.Create;
end;

destructor TXcomRuleset.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FCommendations.Count - 1 do
    FCommendations.Value(LIndex).Free;
  FCommendations.Free;
  FMusics.Free;
  FUfoTrajectories.Free;
  FAlienRaces.Free;
  FManufacture.Free;
  FResearch.Free;
  FMissionScripts.Free;
  FAlienMissions.Free;
  FAlienDeployments.Free;
  FUnits.Free;
  FSoldiers.Free;
  FArmors.Free;
  FUfos.Free;
  FCrafts.Free;
  FTerrains.Free;
  FMapDataSets.Free;
  FInventories.Free;
  FItems.Free;
  FCraftWeapons.Free;
  FFacilities.Free;
  FRegions.Free;
  FCountries.Free;
  FOffsets.Free;
  inherited Destroy;
end;

procedure TXcomRuleset.SetMods(const AMods: TArray<TXcomModData>; ACurrent: Integer);
begin
  FOffsets.Free;
  FOffsets := TXcomModOffsets.Create(AMods, ACurrent, FShared);
end;

procedure TXcomRuleset.LoadFacilities(const ADocument: IYamlNode);
var
  LItem: IYamlNode;
  LRule: TXcomRuleBaseFacility;
begin
  for LItem in TXcomNodeReader.Field(ADocument, 'facilities').Items do
  begin
    LRule := FFacilities.LoadRule(LItem);
    if Assigned(LRule) then
    begin
      Inc(FFacilityListOrder, 100);
      LRule.Load(LItem, FOffsets, FFacilityListOrder);
    end;
  end;
end;

procedure TXcomRuleset.LoadCrafts(const ADocument: IYamlNode);
var
  LItem: IYamlNode;
  LRule: TXcomRuleCraft;
begin
  for LItem in TXcomNodeReader.Field(ADocument, 'crafts').Items do
  begin
    LRule := FCrafts.LoadRule(LItem);
    if Assigned(LRule) then
    begin
      Inc(FCraftListOrder, 100);
      LRule.Load(LItem, FOffsets, FMapDataSets, FCraftListOrder);
    end;
  end;
end;

procedure TXcomRuleset.LoadUfos(const ADocument: IYamlNode);
var
  LItem: IYamlNode;
  LRule: TXcomRuleUfo;
begin
  for LItem in TXcomNodeReader.Field(ADocument, 'ufos').Items do
  begin
    LRule := FUfos.LoadRule(LItem);
    if Assigned(LRule) then
      LRule.Load(LItem, FOffsets, FMapDataSets);
  end;
end;

procedure TXcomRuleset.LoadTerrains(const ADocument: IYamlNode);
var
  LItem: IYamlNode;
  LRule: TXcomRuleTerrain;
begin
  for LItem in TXcomNodeReader.Field(ADocument, 'terrains').Items do
  begin
    LRule := FTerrains.LoadRule(LItem, 'name');
    if Assigned(LRule) then
      LRule.Load(LItem, FOffsets, FMapDataSets);
  end;
end;

procedure TXcomRuleset.LoadPeople(const ADocument: IYamlNode);
var
  LItem: IYamlNode;
  LArmor: TXcomArmor;
  LSoldier: TXcomRuleSoldier;
  LUnit: TXcomRuleUnit;
begin
  for LItem in TXcomNodeReader.Field(ADocument, 'armors').Items do
  begin
    LArmor := FArmors.LoadRule(LItem);
    if Assigned(LArmor) then
      LArmor.Load(LItem);
  end;
  for LItem in TXcomNodeReader.Field(ADocument, 'soldiers').Items do
  begin
    LSoldier := FSoldiers.LoadRule(LItem);
    if Assigned(LSoldier) then
      LSoldier.Load(LItem, FOffsets, FFiles);
  end;
  for LItem in TXcomNodeReader.Field(ADocument, 'units').Items do
  begin
    // loadRule(*i, &_units): no index
    LUnit := FUnits.LoadRule(LItem, 'type', False);
    if Assigned(LUnit) then
      LUnit.Load(LItem, FOffsets);
  end;
end;

procedure TXcomRuleset.LoadDeployments(const ADocument: IYamlNode);
var
  LItem: IYamlNode;
  LRule: TXcomAlienDeployment;
begin
  for LItem in TXcomNodeReader.Field(ADocument, 'alienDeployments').Items do
  begin
    LRule := FAlienDeployments.LoadRule(LItem);
    if Assigned(LRule) then
      LRule.Load(LItem, FOffsets);
  end;
end;

procedure TXcomRuleset.LoadAlienMissions(const ADocument: IYamlNode);
var
  LItem: IYamlNode;
  LRule: TXcomRuleAlienMission;
begin
  for LItem in TXcomNodeReader.Field(ADocument, 'alienMissions').Items do
  begin
    LRule := FAlienMissions.LoadRule(LItem);
    if Assigned(LRule) then
      LRule.Load(LItem);
  end;
end;

procedure TXcomRuleset.LoadMissionScripts(const ADocument: IYamlNode);
var
  LItem: IYamlNode;
  LRule: TXcomRuleMissionScript;
begin
  for LItem in TXcomNodeReader.Field(ADocument, 'missionScripts').Items do
  begin
    LRule := FMissionScripts.LoadRule(LItem, 'type');
    if Assigned(LRule) then
      LRule.Load(LItem);
  end;
end;

procedure TXcomRuleset.ValidateMissions;
var
  LIndex, LName: Integer;
  LScript: TXcomRuleMissionScript;
  LMissions, LNames: TArray<string>;
  LMission: TXcomRuleAlienMission;
  LIsSite: Boolean;
  LText: string;
begin
  for LIndex := 0 to FMissionScripts.Count - 1 do
  begin
    LScript := FMissionScripts.Rule(LIndex);
    LMissions := LScript.AllMissionTypes;
    if Length(LMissions) = 0 then
      Continue;
    LMission := FAlienMissions.Find(LMissions[0]);
    if not Assigned(LMission) then
      raise EXcomModException.Create('Error with MissionScript: ' + FMissionScripts.Name(LIndex) +
        ': alien mission type: ' + LMissions[0] + ' not defined, do not incite the judgement of Amaunator.');
    LIsSite := LMission.Objective = TXcomRuleAlienMission.OBJECTIVE_SITE;
    LScript.SiteType := LIsSite;
    for LText in LMissions do
    begin
      LMission := FAlienMissions.Find(LText);
      if Assigned(LMission) and ((LMission.Objective = TXcomRuleAlienMission.OBJECTIVE_SITE) <> LIsSite) then
        raise EXcomModException.Create('Error with MissionScript: ' + FMissionScripts.Name(LIndex) +
          ': cannot mix terror/non-terror missions in a single command, so sayeth the wise Alaundo.');
    end;
  end;
  // the regions pick their missions here: a mission that is not defined, or a terror site, is an error
  for LIndex := 0 to FRegions.Count - 1 do
  begin
    LNames := FRegions.Rule(LIndex).MissionWeights.Names;
    for LName := 0 to High(LNames) do
    begin
      LMission := FAlienMissions.Find(LNames[LName]);
      if not Assigned(LMission) then
        raise EXcomModException.Create('Error with MissionWeights: Region: ' + FRegions.Name(LIndex) +
          ': alien mission type: ' + LNames[LName] + ' not defined, do not incite the judgement of Amaunator.');
      if LMission.Objective = TXcomRuleAlienMission.OBJECTIVE_SITE then
        raise EXcomModException.Create('Error with MissionWeights: Region: ' + FRegions.Name(LIndex) + ' has ' +
          LNames[LName] + ' listed. Terror mission can only be invoked via missionScript, so sayeth the Spider Queen.');
    end;
  end;
end;

procedure TXcomRuleset.LoadCommendations(const ADocument: IYamlNode);
var
  LItem: IYamlNode;
  LType: string;
  LRule: TXcomRuleCommendations;
  LOld: TXcomRuleCommendations;
begin
  for LItem in TXcomNodeReader.Field(ADocument, 'commendations').Items do
  begin
    LType := TXcomNodeReader.TextOf(TXcomNodeReader.Field(LItem, 'type'));
    LRule := TXcomRuleCommendations.Create;
    LRule.Load(LItem);
    // _commendations[type] = rule: the C++ leaks the rule it replaces
    if FCommendations.TryGetValue(LType, LOld) then
      LOld.Free;
    FCommendations.SetValue(LType, LRule);
  end;
end;

procedure TXcomRuleset.LoadResearch(const ADocument: IYamlNode);
var
  LItem: IYamlNode;
  LRule: TXcomRuleResearch;
begin
  for LItem in TXcomNodeReader.Field(ADocument, 'research').Items do
  begin
    LRule := FResearch.LoadRule(LItem, 'name');
    if Assigned(LRule) then
    begin
      Inc(FResearchListOrder, 100);
      LRule.Load(LItem, FResearchListOrder);
      if TXcomNodeReader.ReadBoolean(LItem, 'unlockFinalMission', False) then
        FFinalResearch := TXcomNodeReader.ReadString(LItem, 'name', FFinalResearch);
    end;
  end;
end;

procedure TXcomRuleset.LoadFile(const ADocument: IYamlNode);
var
  LItem: IYamlNode;
  LCountry: TXcomRuleCountry;
  LRegion: TXcomRuleRegion;
  LWeapon: TXcomRuleCraftWeapon;
  LInventory: TXcomRuleInventory;
  LItemRule: TXcomRuleItem;
  LManufacture: TXcomRuleManufacture;
  LRace: TXcomAlienRace;
  LTrajectory: TXcomUfoTrajectory;
  LMusic: TXcomRuleMusic;
begin
  for LItem in TXcomNodeReader.Field(ADocument, 'countries').Items do
  begin
    LCountry := FCountries.LoadRule(LItem);
    if Assigned(LCountry) then
      LCountry.Load(LItem);
  end;
  for LItem in TXcomNodeReader.Field(ADocument, 'regions').Items do
  begin
    LRegion := FRegions.LoadRule(LItem);
    if Assigned(LRegion) then
      LRegion.Load(LItem);
  end;
  LoadFacilities(ADocument);
  LoadCrafts(ADocument);
  for LItem in TXcomNodeReader.Field(ADocument, 'craftWeapons').Items do
  begin
    LWeapon := FCraftWeapons.LoadRule(LItem);
    if Assigned(LWeapon) then
      LWeapon.Load(LItem, FOffsets);
  end;
  for LItem in TXcomNodeReader.Field(ADocument, 'items').Items do
  begin
    LItemRule := FItems.LoadRule(LItem);
    if Assigned(LItemRule) then
    begin
      Inc(FItemListOrder, 100);
      LItemRule.Load(LItem, FOffsets, FItemListOrder);
    end;
  end;
  LoadUfos(ADocument);
  for LItem in TXcomNodeReader.Field(ADocument, 'invs').Items do
  begin
    LInventory := FInventories.LoadRule(LItem, 'id');
    if Assigned(LInventory) then
    begin
      Inc(FInventoryListOrder, 10);
      LInventory.Load(LItem, FInventoryListOrder);
    end;
  end;
  LoadTerrains(ADocument);
  LoadPeople(ADocument);
  for LItem in TXcomNodeReader.Field(ADocument, 'alienRaces').Items do
  begin
    LRace := FAlienRaces.LoadRule(LItem, 'id');
    if Assigned(LRace) then
      LRace.Load(LItem);
  end;
  LoadDeployments(ADocument);
  LoadResearch(ADocument);
  for LItem in TXcomNodeReader.Field(ADocument, 'manufacture').Items do
  begin
    LManufacture := FManufacture.LoadRule(LItem, 'name');
    if Assigned(LManufacture) then
    begin
      Inc(FManufactureListOrder, 100);
      LManufacture.Load(LItem, FManufactureListOrder);
    end;
  end;
  for LItem in TXcomNodeReader.Field(ADocument, 'ufoTrajectories').Items do
  begin
    // loadRule(*i, &_ufoTrajectories, 0, "id"): no index
    LTrajectory := FUfoTrajectories.LoadRule(LItem, 'id', False);
    if Assigned(LTrajectory) then
      LTrajectory.Load(LItem);
  end;
  LoadAlienMissions(ADocument);
  LoadMissionScripts(ADocument);
  for LItem in TXcomNodeReader.Field(ADocument, 'musics').Items do
  begin
    LMusic := FMusics.LoadRule(LItem, 'type', False);
    if Assigned(LMusic) then
      LMusic.Load(LItem);
  end;
  LoadCommendations(ADocument);
end;

end.
