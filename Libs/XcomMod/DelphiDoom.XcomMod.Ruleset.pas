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
  DelphiDoom.XcomMod.RuleMissionScript, System.Generics.Collections, DelphiDoom.XcomMod.MapScript,
  DelphiDoom.XcomMod.ArticleDefinition, DelphiDoom.XcomMod.McdPatch, DelphiDoom.XcomMod.ExtraSprites,
  DelphiDoom.XcomMod.ExtraSounds, DelphiDoom.XcomMod.ExtraStrings, DelphiDoom.XcomMod.StatString,
  DelphiDoom.XcomMod.RuleInterface, DelphiDoom.XcomMod.RuleVideo, DelphiDoom.XcomMod.RuleConverter,
  DelphiDoom.XcomMod.ModConstants, DelphiDoom.XcomMod.RulesetSettings, System.Generics.Defaults,
  DelphiDoom.XcomMod.SoundDefinition;

type
  /// <summary>SDL_Color of the transparency lookup tables</summary>
  TXcomTransparencyColor = record
    R: Byte;
    G: Byte;
    B: Byte;
    Unused: Byte;
  end;

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
    FSoundDefinitions: TXcomRuleRegistry<TXcomSoundDefinition>;
    FTransparencies: TArray<TXcomTransparencyColor>;
    FMapScripts: TXcomStringMap<TObjectList<TXcomMapScript>>;
    FArticles: TXcomRuleRegistry<TXcomArticleDefinition>;
    FArticleSections: TXcomStringMap<Integer>;
    FArticleSectionIndex: TList<string>;
    FMcdPatches: TXcomStringMap<TXcomMcdPatch>;
    FExtraSprites: TXcomStringMap<TObjectList<TXcomExtraSprites>>;
    FExtraSounds: TObjectList<TXcomExtraSounds>;
    FExtraStrings: TXcomStringMap<TXcomExtraStrings>;
    FStatStrings: TObjectList<TXcomStatString>;
    FInterfaces: TXcomRuleRegistry<TXcomRuleInterface>;
    FVideos: TXcomRuleRegistry<TXcomRuleVideo>;
    FConverter: TXcomRuleConverter;
    FConstants: TXcomModConstants;
    FSettings: TXcomRulesetSettings;
    FStartingBase: TXcomStringMap<IYamlNode>;
    FStartingTime: IYamlNode;
    FModData: TArray<TXcomModData>;
    FCurrentMod: Integer;
    FArticleListOrder: Integer;
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
    class function StableSort(const ANames: TArray<string>; const AKey: TFunc<string, Int64>): TArray<string>; static;
    procedure LoadArticles(const ADocument: IYamlNode);
    procedure LoadMapScripts(const ADocument: IYamlNode);
    procedure LoadExtras(const ADocument: IYamlNode);
    procedure LoadInterfaceAndMisc(const ADocument: IYamlNode);
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
    /// <summary>
    ///   Mod::loadResourceConfigFile: the sound definitions and the transparency colors of a resource file of
    ///   the current mod (the lookup tables share the common set, 100 times smaller than the others). More colors
    ///   than the space of the mod, or a "colors" node that is not a sequence, is EXcomModException
    /// </summary>
    procedure LoadResourceConfig(const ADocument: IYamlNode);
    /// <summary>The transparency colors (R, G, B, unused) of the common set</summary>
    property Transparencies: TArray<TXcomTransparencyColor> read FTransparencies;
    property SoundDefinitions: TXcomRuleRegistry<TXcomSoundDefinition> read FSoundDefinitions;
    /// <summary>
    ///   Mod::sortLists: puts the indexes in the order of the list order of their rules (a craft weapon by its
    ///   launcher, an armor by its store item, the articles by section). Rules with the same order keep the order
    ///   they came (the std::sort of the C++ is not stable)
    /// </summary>
    procedure SortLists;
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
    /// <summary>The commands of the map script of each name (the key of the "mapScripts" node)</summary>
    property MapScripts: TXcomStringMap<TObjectList<TXcomMapScript>> read FMapScripts;
    /// <summary>The Ufopaedia articles by id (the index in the order they came is Articles.Index)</summary>
    property Articles: TXcomRuleRegistry<TXcomArticleDefinition> read FArticles;
    /// <summary>The sections of the Ufopaedia with the least listOrder of their articles; ArticleSectionIndex is the order they came</summary>
    property ArticleSections: TXcomStringMap<Integer> read FArticleSections;
    property ArticleSectionIndex: TList<string> read FArticleSectionIndex;
    property McdPatches: TXcomStringMap<TXcomMcdPatch> read FMcdPatches;
    property ExtraSprites: TXcomStringMap<TObjectList<TXcomExtraSprites>> read FExtraSprites;
    property ExtraSounds: TObjectList<TXcomExtraSounds> read FExtraSounds;
    property ExtraStrings: TXcomStringMap<TXcomExtraStrings> read FExtraStrings;
    property StatStrings: TObjectList<TXcomStatString> read FStatStrings;
    property Interfaces: TXcomRuleRegistry<TXcomRuleInterface> read FInterfaces;
    property Videos: TXcomRuleRegistry<TXcomRuleVideo> read FVideos;
    property Converter: TXcomRuleConverter read FConverter;
    property Constants: TXcomModConstants read FConstants;
    property Settings: TXcomRulesetSettings read FSettings;
    /// <summary>The starting base: the nodes of "startingBase" by key (the C++ keeps them for the saved game)</summary>
    property StartingBase: TXcomStringMap<IYamlNode> read FStartingBase;
    /// <summary>The "startingTime" node (the GameTime that reads it is in Libs\XcomSave)</summary>
    property StartingTime: IYamlNode read FStartingTime;
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
  FSoundDefinitions := TXcomRuleRegistry<TXcomSoundDefinition>.Create(
    function(AType: string): TXcomSoundDefinition begin Result := TXcomSoundDefinition.Create(AType); end);
  FMapScripts := TXcomStringMap<TObjectList<TXcomMapScript>>.Create;
  FArticles := TXcomRuleRegistry<TXcomArticleDefinition>.Create(nil);
  FArticleSections := TXcomStringMap<Integer>.Create;
  FArticleSectionIndex := TList<string>.Create;
  FMcdPatches := TXcomStringMap<TXcomMcdPatch>.Create;
  FExtraSprites := TXcomStringMap<TObjectList<TXcomExtraSprites>>.Create;
  FExtraSounds := TObjectList<TXcomExtraSounds>.Create(True);
  FExtraStrings := TXcomStringMap<TXcomExtraStrings>.Create;
  FStatStrings := TObjectList<TXcomStatString>.Create(True);
  FInterfaces := TXcomRuleRegistry<TXcomRuleInterface>.Create(
    function(AType: string): TXcomRuleInterface begin Result := TXcomRuleInterface.Create(AType); end);
  FVideos := TXcomRuleRegistry<TXcomRuleVideo>.Create(
    function(AType: string): TXcomRuleVideo begin Result := TXcomRuleVideo.Create(AType); end);
  FConverter := TXcomRuleConverter.Create;
  FConstants := TXcomModConstants.Create;
  FSettings := TXcomRulesetSettings.Create;
  FStartingBase := TXcomStringMap<IYamlNode>.Create;
  FAlienDeployments :=TXcomRuleRegistry<TXcomAlienDeployment>.Create(
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
  FSoundDefinitions.Free;
  FStartingBase.Free;
  FSettings.Free;
  FConstants.Free;
  FConverter.Free;
  FVideos.Free;
  FInterfaces.Free;
  FStatStrings.Free;
  for LIndex := 0 to FExtraStrings.Count - 1 do
    FExtraStrings.Value(LIndex).Free;
  FExtraStrings.Free;
  FExtraSounds.Free;
  for LIndex := 0 to FExtraSprites.Count - 1 do
    FExtraSprites.Value(LIndex).Free;
  FExtraSprites.Free;
  for LIndex := 0 to FMcdPatches.Count - 1 do
    FMcdPatches.Value(LIndex).Free;
  FMcdPatches.Free;
  FArticleSectionIndex.Free;
  FArticleSections.Free;
  FArticles.Free;
  for LIndex := 0 to FMapScripts.Count - 1 do
    FMapScripts.Value(LIndex).Free;
  FMapScripts.Free;
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
  FModData := AMods;
  FCurrentMod := ACurrent;
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

procedure TXcomRuleset.LoadArticles(const ADocument: IYamlNode);
var
  LItem: IYamlNode;
  LId, LKindText: string;
  LRule: TXcomArticleDefinition;
  LKind, LOrder: Integer;
begin
  for LItem in TXcomNodeReader.Field(ADocument, 'ufopaedia').Items do
  begin
    if TXcomNodeReader.Field(LItem, 'id').IsDefined then
    begin
      LId := TXcomNodeReader.TextOf(TXcomNodeReader.Field(LItem, 'id'));
      LRule := FArticles.Find(LId);
      if not Assigned(LRule) then
      begin
        LKind := TXcomNodeReader.Field(LItem, 'type_id').AsInteger;
        // the C++ makes no article for an unknown type and then uses it (a crash)
        if not TXcomArticleDefinition.IsKnownKind(LKind) then
        begin
          LKindText := IntToStr(LKind);
          raise EXcomModException.CreateFmt('Unknown Ufopaedia type_id %s in article %s', [LKindText, LId]);
        end;
        LRule := TXcomArticleDefinition.Create(LKind);
        FArticles.Add(LId, LRule);
      end;
      Inc(FArticleListOrder, 100);
      LRule.Load(LItem, FArticleListOrder);
      if LRule.Section <> 'STR_NOT_AVAILABLE' then
      begin
        if not FArticleSections.TryGetValue(LRule.Section, LOrder) then
        begin
          FArticleSections.SetValue(LRule.Section, LRule.ListOrder);
          FArticleSectionIndex.Add(LRule.Section);
        end
        else if LRule.ListOrder < LOrder then
          FArticleSections.SetValue(LRule.Section, LRule.ListOrder);
      end;
    end
    else if TXcomNodeReader.Field(LItem, 'delete').IsDefined then
      FArticles.Delete(TXcomNodeReader.TextOf(TXcomNodeReader.Field(LItem, 'delete')));
  end;
end;

procedure TXcomRuleset.LoadMapScripts(const ADocument: IYamlNode);
var
  LItem, LCommand: IYamlNode;
  LType: string;
  LList: TObjectList<TXcomMapScript>;
  LScript: TXcomMapScript;
begin
  for LItem in TXcomNodeReader.Field(ADocument, 'mapScripts').Items do
  begin
    LType := TXcomNodeReader.TextOf(TXcomNodeReader.Field(LItem, 'type'));
    if TXcomNodeReader.Field(LItem, 'delete').IsDefined then
      LType := TXcomNodeReader.ReadString(LItem, 'delete', LType);
    if FMapScripts.TryGetValue(LType, LList) then
      LList.Clear;
    for LCommand in TXcomNodeReader.Field(LItem, 'commands').Items do
    begin
      LScript := TXcomMapScript.Create;
      try
        LScript.Load(LCommand);
      except
        LScript.Free;
        raise;
      end;
      if not FMapScripts.TryGetValue(LType, LList) then
      begin
        LList := TObjectList<TXcomMapScript>.Create(True);
        FMapScripts.SetValue(LType, LList);
      end;
      LList.Add(LScript);
    end;
  end;
end;

procedure TXcomRuleset.LoadExtras(const ADocument: IYamlNode);
var
  LItem: IYamlNode;
  LType: string;
  LPatch: TXcomMcdPatch;
  LSprites: TXcomExtraSprites;
  LSpriteList: TObjectList<TXcomExtraSprites>;
  LSounds: TXcomExtraSounds;
  LStrings: TXcomExtraStrings;
  LStat: TXcomStatString;
  LData: TXcomModData;
begin
  for LItem in TXcomNodeReader.Field(ADocument, 'MCDPatches').Items do
  begin
    LType := TXcomNodeReader.TextOf(TXcomNodeReader.Field(LItem, 'type'));
    if not FMcdPatches.TryGetValue(LType, LPatch) then
    begin
      LPatch := TXcomMcdPatch.Create;
      FMcdPatches.SetValue(LType, LPatch);
    end;
    LPatch.Load(LItem);
  end;
  for LItem in TXcomNodeReader.Field(ADocument, 'extraSprites').Items do
  begin
    if TXcomNodeReader.Field(LItem, 'type').IsDefined then
    begin
      LType := TXcomNodeReader.TextOf(TXcomNodeReader.Field(LItem, 'type'));
      LData := FModData[FCurrentMod];
      // TEXTURE.DAT does not support a mod index: it is always the master
      if LType = 'TEXTURE.DAT' then
        LData := FModData[0];
      LSprites := TXcomExtraSprites.Create;
      try
        LSprites.Load(LItem, LData);
      except
        LSprites.Free;
        raise;
      end;
      if not FExtraSprites.TryGetValue(LType, LSpriteList) then
      begin
        LSpriteList := TObjectList<TXcomExtraSprites>.Create(True);
        FExtraSprites.SetValue(LType, LSpriteList);
      end;
      LSpriteList.Add(LSprites);
    end
    else if TXcomNodeReader.Field(LItem, 'delete').IsDefined then
    begin
      LType := TXcomNodeReader.TextOf(TXcomNodeReader.Field(LItem, 'delete'));
      if FExtraSprites.TryGetValue(LType, LSpriteList) then
      begin
        FExtraSprites.Remove(LType);
        LSpriteList.Free;
      end;
    end;
  end;
  for LItem in TXcomNodeReader.Field(ADocument, 'extraSounds').Items do
  begin
    // the type is read here as well as by the rule (the C++ does the same)
    TXcomNodeReader.TextOf(TXcomNodeReader.Field(LItem, 'type'));
    LSounds := TXcomExtraSounds.Create;
    FExtraSounds.Add(LSounds);
    LSounds.Load(LItem, FModData[FCurrentMod]);
  end;
  for LItem in TXcomNodeReader.Field(ADocument, 'extraStrings').Items do
  begin
    LType := TXcomNodeReader.TextOf(TXcomNodeReader.Field(LItem, 'type'));
    if not FExtraStrings.TryGetValue(LType, LStrings) then
    begin
      LStrings := TXcomExtraStrings.Create;
      FExtraStrings.SetValue(LType, LStrings);
    end;
    LStrings.Load(LItem);
  end;
  for LItem in TXcomNodeReader.Field(ADocument, 'statStrings').Items do
  begin
    LStat := TXcomStatString.Create;
    FStatStrings.Add(LStat);
    LStat.Load(LItem);
  end;
end;

procedure TXcomRuleset.LoadInterfaceAndMisc(const ADocument: IYamlNode);
var
  LItem: IYamlNode;
  LInterface: TXcomRuleInterface;
  LVideo: TXcomRuleVideo;
  LField: IYamlNode;
  LPair: TYamlPair;
begin
  for LPair in TXcomNodeReader.Field(ADocument, 'startingBase').Pairs do
    FStartingBase.SetValue(TXcomNodeReader.TextOf(LPair.Key), LPair.Value);
  if TXcomNodeReader.Field(ADocument, 'startingTime').IsDefined then
    FStartingTime := TXcomNodeReader.Field(ADocument, 'startingTime');
  for LItem in TXcomNodeReader.Field(ADocument, 'interfaces').Items do
  begin
    LInterface := FInterfaces.LoadRule(LItem, 'type', False);
    if Assigned(LInterface) then
      LInterface.Load(LItem);
  end;
  LField := TXcomNodeReader.Field(ADocument, 'converter');
  if LField.IsDefined then
    FConverter.Load(LField);
  LField := TXcomNodeReader.Field(ADocument, 'constants');
  if LField.IsDefined then
  begin
    // the old form was a list of nodes
    if LField.IsSequence then
      for LItem in LField.Items do
        FConstants.Load(LItem, FOffsets)
    else
      FConstants.Load(LField, FOffsets);
  end;
  for LItem in TXcomNodeReader.Field(ADocument, 'cutscenes').Items do
  begin
    LVideo := FVideos.LoadRule(LItem, 'type', False);
    if Assigned(LVideo) then
      LVideo.Load(LItem);
  end;
end;

class function TXcomRuleset.StableSort(const ANames: TArray<string>;
  const AKey: TFunc<string, Int64>): TArray<string>;
type
  TEntry = record
    Name: string;
    Key: Int64;
    Position: Integer;
  end;
var
  LEntries: TArray<TEntry>;
  LIndex: Integer;
begin
  SetLength(LEntries, Length(ANames));
  for LIndex := 0 to High(ANames) do
  begin
    LEntries[LIndex].Name := ANames[LIndex];
    LEntries[LIndex].Key := AKey(ANames[LIndex]);
    LEntries[LIndex].Position := LIndex;
  end;
  // std::sort of the C++ is not stable: the rules with the same list order come out in the order they came
  TArray.Sort<TEntry>(LEntries, TComparer<TEntry>.Construct(
    function(const ALeft, ARight: TEntry): Integer
    begin
      if ALeft.Key < ARight.Key then
        Result := -1
      else if ALeft.Key > ARight.Key then
        Result := 1
      else
        Result := ALeft.Position - ARight.Position;
    end));
  SetLength(Result, Length(ANames));
  for LIndex := 0 to High(Result) do
    Result[LIndex] := LEntries[LIndex].Name;
end;

procedure TXcomRuleset.SortLists;
var
  LSections: TArray<string>;
begin
  LSections := FArticleSectionIndex.ToArray;
  FItems.SetIndex(StableSort(FItems.Index,
    function(AName: string): Int64 begin Result := FItems.Find(AName).ListOrder; end));
  FCrafts.SetIndex(StableSort(FCrafts.Index,
    function(AName: string): Int64 begin Result := FCrafts.Find(AName).ListOrder; end));
  FFacilities.SetIndex(StableSort(FFacilities.Index,
    function(AName: string): Int64 begin Result := FFacilities.Find(AName).ListOrder; end));
  FResearch.SetIndex(StableSort(FResearch.Index,
    function(AName: string): Int64 begin Result := FResearch.Find(AName).ListOrder; end));
  FManufacture.SetIndex(StableSort(FManufacture.Index,
    function(AName: string): Int64 begin Result := FManufacture.Find(AName).ListOrder; end));
  FInventories.SetIndex(StableSort(FInventories.Index,
    function(AName: string): Int64 begin Result := FInventories.Find(AName).ListOrder; end));
  // special cases: a craft weapon takes the list order of its launcher, an armor of its store item (itemless
  // armor comes before all else)
  FCraftWeapons.SetIndex(StableSort(FCraftWeapons.Index,
    function(AName: string): Int64
    var
      LItem: TXcomRuleItem;
    begin
      LItem := FItems.Find(FCraftWeapons.Find(AName).LauncherItem);
      if not Assigned(LItem) then
        raise EXcomModException.CreateFmt('Item %s not found', [FCraftWeapons.Find(AName).LauncherItem]);
      Result := LItem.ListOrder;
    end));
  FArmors.SetIndex(StableSort(FArmors.Index,
    function(AName: string): Int64
    var
      LItem: TXcomRuleItem;
    begin
      LItem := FItems.Find(FArmors.Find(AName).StoreItem);
      if Assigned(LItem) then
        Result := LItem.ListOrder
      else
        Result := Low(Integer);
    end));
  FArticleSections.SetValue('STR_NOT_AVAILABLE', 0);
  // the articles: by the order of their section, then their own
  FArticles.SetIndex(StableSort(FArticles.Index,
    function(AName: string): Int64
    var
      LArticle: TXcomArticleDefinition;
      LSection: Integer;
    begin
      LArticle := FArticles.Find(AName);
      if not FArticleSections.TryGetValue(LArticle.Section, LSection) then
        raise EXcomModException.CreateFmt('map::at: section %s', [LArticle.Section]);
      // the section first, then the list order of the article
      Result := (Int64(LSection) shl 32) + Int64(LArticle.ListOrder);
    end));
  FArticleSectionIndex.Clear;
  FArticleSectionIndex.AddRange(StableSort(LSections,
    function(AName: string): Int64
    var
      LOrder: Integer;
    begin
      FArticleSections.TryGetValue(AName, LOrder);
      Result := LOrder;
    end));
end;

procedure TXcomRuleset.LoadResourceConfig(const ADocument: IYamlNode);
var
  LItem, LColors, LColor, LLuts: IYamlNode;
  LRule: TXcomSoundDefinition;
  LStart, LLimit, LCurrent: Cardinal;
  LValue: TXcomTransparencyColor;
begin
  for LItem in TXcomNodeReader.Field(ADocument, 'soundDefs').Items do
  begin
    LRule := FSoundDefinitions.LoadRule(LItem, 'type', False);
    if Assigned(LRule) then
      LRule.Load(LItem);
  end;
  LLuts := TXcomNodeReader.Field(ADocument, 'transparencyLUTs');
  if not LLuts.IsDefined then
    Exit;
  LStart := FModData[FCurrentMod].Offset div TXcomModOffsets.TRANSPARENCY_SIZE_REDUCTION;
  LLimit := FModData[FCurrentMod].Size div TXcomModOffsets.TRANSPARENCY_SIZE_REDUCTION;
  LCurrent := 0;
  if Cardinal(Length(FTransparencies)) < LStart + LLimit then
    SetLength(FTransparencies, LStart + LLimit);
  for LItem in LLuts.Items do
  begin
    LColors := TXcomNodeReader.Field(LItem, 'colors');
    if not LColors.IsSequence then
      raise EXcomModException.Create('unknown transparencyLUTs node type');
    for LColor in LColors.Items do
    begin
      if LCurrent = LLimit then
        raise EXcomModException.Create('transparencyLUTs mod limit reach');
      LValue.R := Byte(LColor.Find(0).AsInteger(0));
      LValue.G := Byte(LColor.Find(1).AsInteger(0));
      LValue.B := Byte(LColor.Find(2).AsInteger(0));
      LValue.Unused := Byte(LColor.Find(3).AsInteger(2));
      FTransparencies[LStart + LCurrent] := LValue;
      Inc(LCurrent);
    end;
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
  LoadArticles(ADocument);
  FSettings.Load(ADocument);
  for LItem in TXcomNodeReader.Field(ADocument, 'ufoTrajectories').Items do
  begin
    // loadRule(*i, &_ufoTrajectories, 0, "id"): no index
    LTrajectory := FUfoTrajectories.LoadRule(LItem, 'id', False);
    if Assigned(LTrajectory) then
      LTrajectory.Load(LItem);
  end;
  LoadAlienMissions(ADocument);
  LoadExtras(ADocument);
  LoadInterfaceAndMisc(ADocument);
  LoadMapScripts(ADocument);
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
