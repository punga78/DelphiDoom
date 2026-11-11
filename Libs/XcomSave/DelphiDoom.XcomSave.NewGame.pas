{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the saved game of a new game           }
{  (Mod::newSave and Mod::genSoldier)                                           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.NewGame;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleSoldier, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomMod.RuleCountry, DelphiDoom.XcomMod.RuleRegion, DelphiDoom.XcomSave.SoldierCommendation,
  DelphiDoom.XcomSave.Transfer,
  DelphiDoom.XcomSave.Types, DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.Settings.Intf,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Country, DelphiDoom.XcomSave.Region,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.Vehicle,
  DelphiDoom.XcomSave.TargetLookup.Intf;

type
  /// <summary>
  ///   Makes the saved game of a new game from the ruleset: the countries with their funding, the regions, the
  ///   starting base with its crafts, and the random soldiers (Mod::newSave, Mod::genSoldier). The generator is
  ///   injected (the C++ uses the global one). Not ported: the stat string of the soldiers
  /// </summary>
  TXcomNewGame = class
  strict private
    FRuleset: TXcomRuleset;
    FRules: TXcomRulesetRules;
    FSettings: IXcomSaveSettings;
    FRandom: IXcomRandom;
    FCustomInitialBase: Boolean;
    function StartingBaseNode: IYamlNode;
    function RandomSoldierTypes(const ANode: IYamlNode; const ABase: TXcomBase): TArray<string>;
    procedure AdjustFunding(const ASave: TXcomSavedGame);
    procedure BuildSave(const ASave: TXcomSavedGame);
  public
    constructor Create(const ARuleset: TXcomRuleset; const ARules: TXcomRulesetRules;
      const ASettings: IXcomSaveSettings; const ARandom: IXcomRandom);
    /// <summary>
    ///   newSave: the caller frees the saved game. A ruleset with no soldier types, no countries or no
    ///   starting soldiers that need a type is EXcomSaveException (the C++ divides by zero or reads past a vector)
    /// </summary>
    function NewSave: TXcomSavedGame;
    /// <summary>
    ///   Options::customInitialBase: the first base starts without facilities (Base::load skips them) and the
    ///   player places the ones of the starting base. False unless set before NewSave
    /// </summary>
    property CustomInitialBase: Boolean read FCustomInitialBase write FCustomInitialBase;
    /// <summary>
    ///   genSoldier: a soldier of the type (the first type if ''), with a name that no other soldier of the bases
    ///   has (it gives up after 10 tries, as the original game does). The caller owns the soldier
    /// </summary>
    function GenSoldier(const ASave: TXcomSavedGame; const AType: string): TXcomSoldier;
  end;

implementation

const
  SNoSoldierTypes = 'Xcom: the ruleset has no soldier type for a new game';
  SNoCountries = 'Xcom: the ruleset has no country for a new game';

{ TXcomNewGame }

constructor TXcomNewGame.Create(const ARuleset: TXcomRuleset; const ARules: TXcomRulesetRules;
  const ASettings: IXcomSaveSettings; const ARandom: IXcomRandom);
begin
  inherited Create;
  FRuleset := ARuleset;
  FRules := ARules;
  FSettings := ASettings;
  FRandom := ARandom;
end;

function TXcomNewGame.StartingBaseNode: IYamlNode;
var
  LIndex: Integer;
begin
  // Mod keeps the keys of "startingBase" one by one; Base::load wants them as one map node
  Result := TYamlFactory.CreateNode(ntMap);
  for LIndex := 0 to FRuleset.StartingBase.Count - 1 do
    Result.Child(YamlStringToText(FRuleset.StartingBase.Key(LIndex))).Assign(FRuleset.StartingBase.Value(LIndex));
end;

procedure TXcomNewGame.AdjustFunding(const ASave: TXcomSavedGame);
var
  LMissing, LFunding: Integer;
  LCountry: TXcomCountry;
begin
  if ASave.Countries.Count = 0 then
    raise EXcomSaveException.Create(SNoCountries);
  // adjust the funding to the initial funding of the ruleset (6 million in the original)
  LMissing := ((FRuleset.Settings.InitialFunding - ASave.CountryFunding div 1000) div ASave.Countries.Count) * 1000;
  for LCountry in ASave.Countries do
  begin
    LFunding := LCountry.Funding[High(LCountry.Funding)] + LMissing;
    if LFunding < 0 then
      LFunding := LCountry.Funding[High(LCountry.Funding)];
    LCountry.SetFunding(LFunding);
  end;
  ASave.SetFunds(ASave.CountryFunding);
end;

function TXcomNewGame.RandomSoldierTypes(const ANode: IYamlNode; const ABase: TXcomBase): TArray<string>;
var
  LTypes: TList<string>;
  LAvailable: TArray<string>;
  LName, LKey: string;
  LIndex, LCount, LSoldiers: Integer;
  LPairs: TArray<TYamlPair>;
  LMap: TXcomStringMap<Integer>;
begin
  LTypes := TList<string>.Create;
  try
    LAvailable := nil;
    for LName in FRuleset.Soldiers.Index do
      if Length(FRuleset.Soldiers.Find(LName).Requirements) = 0 then
      begin
        SetLength(LAvailable, Length(LAvailable) + 1);
        LAvailable[High(LAvailable)] := LName;
      end;
    if ANode.IsDefined then
    begin
      if ANode.IsMap then
      begin
        // as<std::map<std::string, int>>: the types in the order of the names
        LMap := TXcomStringMap<Integer>.Create;
        try
          LPairs := ANode.Pairs;
          for LIndex := 0 to High(LPairs) do
            LMap.SetValue(TXcomNodeReader.TextOf(LPairs[LIndex].Key), LPairs[LIndex].Value.AsInteger);
          for LIndex := 0 to LMap.Count - 1 do
          begin
            LKey := LMap.Key(LIndex);
            for LCount := 1 to LMap.Value(LIndex) do
              LTypes.Add(LKey);
          end;
        finally
          LMap.Free;
        end;
      end
      else if ANode.IsScalar then
      begin
        LSoldiers := ANode.AsInteger(0);
        if (LSoldiers > 0) and (Length(LAvailable) = 0) then
          raise EXcomSaveException.Create(SNoSoldierTypes);
        for LCount := 1 to LSoldiers do
          LTypes.Add(LAvailable[FRandom.Generate(0, Length(LAvailable) - 1)]);
      end;
    end;
    Result := LTypes.ToArray;
  finally
    LTypes.Free;
  end;
end;

function TXcomNewGame.GenSoldier(const ASave: TXcomSavedGame; const AType: string): TXcomSoldier;
var
  LNewId, LTries: Integer;
  LType: string;
  LRules: TXcomRuleSoldier;
  LDuplicate: Boolean;
  LBase: TXcomBase;
  LOther: TXcomSoldier;
  LTransfer: TXcomTransfer;
begin
  LNewId := ASave.GetId('STR_SOLDIER');
  LType := AType;
  if LType = '' then
    LType := FRuleset.Soldiers.Index[0];
  LRules := FRuleset.Soldiers.Find(LType);
  if not Assigned(LRules) then
    raise EXcomSaveException.CreateFmt('Xcom: unknown soldier type %s', [LType]);
  Result := nil;
  LDuplicate := True;
  LTries := 0;
  while (LTries < 10) and LDuplicate do
  begin
    Result.Free;
    Result := TXcomSoldier.Create(LRules, FRuleset.Armors.Find(LRules.ArmorName), LNewId, FRandom);
    LDuplicate := False;
    for LBase in ASave.Bases do
    begin
      if LDuplicate then
        Break;
      for LOther in LBase.Soldiers do
        if LOther.Name = Result.Name then
        begin
          LDuplicate := True;
          Break;
        end;
      if LDuplicate then
        Break;
      for LTransfer in LBase.Transfers do
        if Assigned(LTransfer.Soldier) and (LTransfer.Soldier.Name = Result.Name) then
        begin
          LDuplicate := True;
          Break;
        end;
    end;
    Inc(LTries);
  end;
end;

procedure TXcomNewGame.BuildSave(const ASave: TXcomSavedGame);
var
  LName: string;
  LCountryRules: TXcomRuleCountry;
  LRegionRules: TXcomRuleRegion;
  LBase: TXcomBase;
  LCraft, LTransport: TXcomCraft;
  LTypes: TArray<string>;
  LSoldier: TXcomSoldier;
  LCommendation: TXcomSoldierCommendation;
  LMaxSoldiers: Cardinal;
  LVehicle: TXcomVehicle;
  LIndex: Integer;
  LAmmoRules: TXcomRuleItem;
  LItemRules: TXcomRuleItem;
  LRandomNode: IYamlNode;
begin
  for LName in FRuleset.Countries.Index do
  begin
    LCountryRules := FRuleset.Countries.Find(LName);
    if Length(LCountryRules.Areas.LonMin) > 0 then
      ASave.Countries.Add(TXcomCountry.Create(LCountryRules, True, FRandom));
  end;
  AdjustFunding(ASave);
  for LName in FRuleset.Regions.Index do
  begin
    LRegionRules := FRuleset.Regions.Find(LName);
    if Length(LRegionRules.Areas.LonMin) > 0 then
      ASave.Regions.Add(TXcomRegion.Create(LRegionRules));
  end;
  // set up the starting base
  LBase := TXcomBase.Create;
  ASave.Bases.Add(LBase);
  LBase.Load(StartingBaseNode, FRuleset, FRules, nil, FSettings, True, FCustomInitialBase, False);
  // correct the ids
  for LCraft in LBase.Crafts do
    ASave.GetId(LCraft.Rules.CraftType);
  // the starting transport craft
  LTransport := nil;
  for LCraft in LBase.Crafts do
    if LCraft.Rules.Soldiers > 0 then
    begin
      LTransport := LCraft;
      Break;
    end;
  LRandomNode := TXcomNodeReader.Field(StartingBaseNode, 'randomSoldiers');
  if LRandomNode.IsDefined then
  begin
    LTypes := RandomSoldierTypes(LRandomNode, LBase);
    LMaxSoldiers := 0;
    if Assigned(LTransport) then
    begin
      LMaxSoldiers := LTransport.Rules.Soldiers;
      LIndex := 0;
      while LIndex < LTransport.Vehicles.Count do
      begin
        LVehicle := LTransport.Vehicles[LIndex];
        if Integer(LMaxSoldiers) < LVehicle.Size then
        begin
          // a vehicle that does not fit goes to the stores with its ammo
          LBase.StorageItems.AddItem(LVehicle.Rules.ItemType, 1);
          LItemRules := FRuleset.Items.Find(LVehicle.Rules.ItemType);
          if (LVehicle.Ammo > 0) and Assigned(LItemRules) and (Length(LItemRules.CompatibleAmmo) > 0) then
          begin
            LAmmoRules := FRuleset.Items.Find(LItemRules.CompatibleAmmo[0]);
            if not Assigned(LAmmoRules) or (LAmmoRules.ClipSize = 0) then
              raise EXcomSaveException.Create('Xcom: the ammo of a vehicle has no clip size');
            LBase.StorageItems.AddItem(LItemRules.CompatibleAmmo[0], LVehicle.Ammo div LAmmoRules.ClipSize);
          end;
          LTransport.Vehicles.Delete(LIndex);
        end
        else
        begin
          Dec(LMaxSoldiers, Cardinal(LVehicle.Size));
          Inc(LIndex);
        end;
      end;
    end;
    for LIndex := 0 to High(LTypes) do
    begin
      LSoldier := GenSoldier(ASave, LTypes[LIndex]);
      if Assigned(LTransport) and (Cardinal(LIndex) < LMaxSoldiers) then
        LSoldier.Craft := LTransport;
      LBase.Soldiers.Add(LSoldier);
      // award the soldier the special 'original eight' commendation
      if FRuleset.Commendations.ContainsKey('STR_MEDAL_ORIGINAL8_NAME') then
      begin
        LSoldier.Diary.AwardOriginalEightCommendation;
        for LCommendation in LSoldier.Diary.Commendations do
          LCommendation.MakeOld;
      end;
    end;
  end;
  // set up the alien strategy
  ASave.AlienStrategy.Init(FRuleset);
  if FRuleset.StartingTime.IsDefined then
    ASave.Time.Load(FRuleset.StartingTime);
end;

function TXcomNewGame.NewSave: TXcomSavedGame;
begin
  Result := TXcomSavedGame.Create;
  try
    BuildSave(Result);
  except
    Result.Free;
    raise;
  end;
end;

end.
