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
  DelphiDoom.XcomMod.RuleMusic, DelphiDoom.XcomMod.RuleCommendations, DelphiDoom.XcomMod.RuleCraftWeapon;

type
  /// <summary>
  ///   The ruleset of the game: the rules of every kind, by name, filled by LoadFile from the YAML files of the
  ///   mods in load order (Mod). It does not hold the resources (surfaces, sounds, palettes): the sets that the
  ///   offsets need come from IXcomSharedResources
  /// </summary>
  TXcomRuleset = class
  strict private
    FShared: IXcomSharedResources;
    FMods: TArray<TXcomModData>;
    FCurrent: Integer;
    FOffsets: TXcomModOffsets;
    FCountries: TXcomRuleRegistry<TXcomRuleCountry>;
    FRegions: TXcomRuleRegistry<TXcomRuleRegion>;
    FCraftWeapons: TXcomRuleRegistry<TXcomRuleCraftWeapon>;
    FInventories: TXcomRuleRegistry<TXcomRuleInventory>;
    FResearch: TXcomRuleRegistry<TXcomRuleResearch>;
    FManufacture: TXcomRuleRegistry<TXcomRuleManufacture>;
    FAlienRaces: TXcomRuleRegistry<TXcomAlienRace>;
    FUfoTrajectories: TXcomRuleRegistry<TXcomUfoTrajectory>;
    FMusics: TXcomRuleRegistry<TXcomRuleMusic>;
    FCommendations: TXcomStringMap<TXcomRuleCommendations>;
    FInventoryListOrder: Integer;
    FResearchListOrder: Integer;
    FManufactureListOrder: Integer;
    FFinalResearch: string;
    procedure LoadCommendations(const ADocument: IYamlNode);
    procedure LoadResearch(const ADocument: IYamlNode);
  public
    /// <param name="AShared">The sizes of the common resource sets (the offsets of the rules need them)</param>
    constructor Create(const AShared: IXcomSharedResources);
    destructor Destroy; override;
    /// <summary>
    ///   Sets the mods that share the sets (_modData) and the one that is being loaded (_modCurrent), the
    ///   position in AMods of the next file to load
    /// </summary>
    procedure SetMods(const AMods: TArray<TXcomModData>; ACurrent: Integer);
    /// <summary>Mod::loadFile: the rules of a ruleset file; rules with the same name overwrite those that exist</summary>
    procedure LoadFile(const ADocument: IYamlNode);
    property Offsets: TXcomModOffsets read FOffsets;
    property Countries: TXcomRuleRegistry<TXcomRuleCountry> read FCountries;
    property Regions: TXcomRuleRegistry<TXcomRuleRegion> read FRegions;
    property CraftWeapons: TXcomRuleRegistry<TXcomRuleCraftWeapon> read FCraftWeapons;
    property Inventories: TXcomRuleRegistry<TXcomRuleInventory> read FInventories;
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

constructor TXcomRuleset.Create(const AShared: IXcomSharedResources);
begin
  inherited Create;
  if not Assigned(AShared) then
    raise EArgumentNilException.Create('AShared');
  FShared := AShared;
  FCountries := TXcomRuleRegistry<TXcomRuleCountry>.Create(
    function(AType: string): TXcomRuleCountry begin Result := TXcomRuleCountry.Create(AType); end);
  FRegions := TXcomRuleRegistry<TXcomRuleRegion>.Create(
    function(AType: string): TXcomRuleRegion begin Result := TXcomRuleRegion.Create(AType); end);
  FCraftWeapons := TXcomRuleRegistry<TXcomRuleCraftWeapon>.Create(
    function(AType: string): TXcomRuleCraftWeapon begin Result := TXcomRuleCraftWeapon.Create(AType); end);
  FInventories := TXcomRuleRegistry<TXcomRuleInventory>.Create(
    function(AType: string): TXcomRuleInventory begin Result := TXcomRuleInventory.Create(AType); end);
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
  FInventories.Free;
  FCraftWeapons.Free;
  FRegions.Free;
  FCountries.Free;
  FOffsets.Free;
  inherited Destroy;
end;

procedure TXcomRuleset.SetMods(const AMods: TArray<TXcomModData>; ACurrent: Integer);
begin
  FMods := AMods;
  FCurrent := ACurrent;
  FOffsets.Free;
  FOffsets := TXcomModOffsets.Create(AMods, ACurrent, FShared);
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
  for LItem in TXcomNodeReader.Field(ADocument, 'craftWeapons').Items do
  begin
    LWeapon := FCraftWeapons.LoadRule(LItem);
    if Assigned(LWeapon) then
      LWeapon.Load(LItem, FOffsets);
  end;
  for LItem in TXcomNodeReader.Field(ADocument, 'invs').Items do
  begin
    LInventory := FInventories.LoadRule(LItem, 'id');
    if Assigned(LInventory) then
    begin
      Inc(FInventoryListOrder, 10);
      LInventory.Load(LItem, FInventoryListOrder);
    end;
  end;
  for LItem in TXcomNodeReader.Field(ADocument, 'alienRaces').Items do
  begin
    LRace := FAlienRaces.LoadRule(LItem, 'id');
    if Assigned(LRace) then
      LRace.Load(LItem);
  end;
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
  for LItem in TXcomNodeReader.Field(ADocument, 'musics').Items do
  begin
    LMusic := FMusics.LoadRule(LItem, 'type', False);
    if Assigned(LMusic) then
      LMusic.Load(LItem);
  end;
  LoadCommendations(ADocument);
end;

end.
