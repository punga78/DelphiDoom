{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a base of the player (Base)            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.Base;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleSoldier,
  DelphiDoom.XcomMod.RuleResearch, DelphiDoom.XcomMod.RuleManufacture, DelphiDoom.XcomSave.NodeWriter,
  DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.BaseFacility,
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.ItemContainer,
  DelphiDoom.XcomSave.Transfer, DelphiDoom.XcomSave.ResearchProject, DelphiDoom.XcomSave.Production,
  DelphiDoom.XcomSave.TargetLookup.Intf, DelphiDoom.XcomSave.Settings.Intf, DelphiDoom.XcomSave.Rules.Intf;

type
  /// <summary>
  ///   A base: facilities, soldiers, crafts, transfers, research and production, stores and staff (Base). It owns
  ///   all of them. Not ported: the capacities, the maintenance, the radar detection, the defenses and the
  ///   removal of facilities (they need the sizes and capacities of the facility rules, which the saved game
  ///   sees only as a type name) and the transfer totals of getTotalSoldiers/Scientists/Engineers
  /// </summary>
  TXcomBase = class(TXcomTarget)
  strict private
    FFacilities: TObjectList<TXcomBaseFacility>;
    FSoldiers: TObjectList<TXcomSoldier>;
    FCrafts: TObjectList<TXcomCraft>;
    FTransfers: TObjectList<TXcomTransfer>;
    FItems: TXcomItemContainer;
    FScientists: Integer;
    FEngineers: Integer;
    FInBattlescape: Boolean;
    FResearch: TObjectList<TXcomResearchProject>;
    FProductions: TObjectList<TXcomProduction>;
    FRetaliationTarget: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   load: facilities, crafts, soldiers, items, transfers, research and production of types the ruleset does
    ///   not know are dropped (the C++ logs them); the staff of an unknown research or production goes back to
    ///   the base. A soldier is put in the craft of its saved id. ANewGame with ACustomInitialBase skips the
    ///   facilities (a base that the player lays out)
    /// </summary>
    procedure Load(const ANode: IYamlNode; const ARuleset: TXcomRuleset; const ARules: TXcomRulesetRules;
      const ATargets: IXcomTargetLookup; const ASettings: IXcomSaveSettings; ANewGame, ACustomInitialBase,
      ANewBattleGame: Boolean); reintroduce;
    function Save(const ASettings: IXcomSaveSettings): IYamlNode; reintroduce;
    function TargetType: string; override;
    /// <summary>getMarker: a base that is at 0, 0 (not placed yet) is hidden</summary>
    function Marker: Integer; override;
    property Facilities: TObjectList<TXcomBaseFacility> read FFacilities;
    property Soldiers: TObjectList<TXcomSoldier> read FSoldiers;
    property Crafts: TObjectList<TXcomCraft> read FCrafts;
    property Transfers: TObjectList<TXcomTransfer> read FTransfers;
    property StorageItems: TXcomItemContainer read FItems;
    property Scientists: Integer read FScientists write FScientists;
    property Engineers: Integer read FEngineers write FEngineers;
    property Research: TObjectList<TXcomResearchProject> read FResearch;
    property Productions: TObjectList<TXcomProduction> read FProductions;
    property InBattlescape: Boolean read FInBattlescape write FInBattlescape;
    property RetaliationTarget: Boolean read FRetaliationTarget write FRetaliationTarget;
    /// <summary>getAvailableSoldiers: soldiers with no craft, or (combat readiness) in a craft that is not out or healthy with none</summary>
    function AvailableSoldiers(ACheckCombatReadiness: Boolean = False): Integer;
    /// <summary>getTotalScientists: the staff, the scientists in transit are not counted (see the class remarks)</summary>
    function AssignedScientists: Integer;
    /// <summary>The engineers at work on productions</summary>
    function AssignedEngineers: Integer;
    /// <summary>addResearch / addProduction: the base owns the project from now on</summary>
    procedure AddResearch(const AProject: TXcomResearchProject);
    procedure AddProduction(const AProduction: TXcomProduction);
    /// <summary>
    ///   removeResearch: the scientists come back; an unfinished project that needs an item that it destroys
    ///   gives the item back to the stores. The project is freed
    /// </summary>
    procedure RemoveResearch(const AProject: TXcomResearchProject);
    /// <summary>removeProduction: the engineers come back; the production is freed</summary>
    procedure RemoveProduction(const AProduction: TXcomProduction);
    /// <summary>
    ///   removeCraft: takes the craft out of the list; it is not freed (the caller owns it from now on, nil if
    ///   it was not there)
    /// </summary>
    function RemoveCraft(const ACraft: TXcomCraft): TXcomCraft;
  end;

implementation

{ TXcomBase }

constructor TXcomBase.Create;
begin
  inherited Create;
  FFacilities := TObjectList<TXcomBaseFacility>.Create(True);
  FSoldiers := TObjectList<TXcomSoldier>.Create(True);
  FCrafts := TObjectList<TXcomCraft>.Create(True);
  FTransfers := TObjectList<TXcomTransfer>.Create(True);
  FResearch := TObjectList<TXcomResearchProject>.Create(True);
  FProductions := TObjectList<TXcomProduction>.Create(True);
  FItems := TXcomItemContainer.Create;
end;

destructor TXcomBase.Destroy;
begin
  // the C++ deletes the soldiers, then the crafts and so on; a craft must go before the base it follows
  FFacilities.Free;
  FSoldiers.Free;
  FCrafts.Free;
  FTransfers.Free;
  FProductions.Free;
  FItems.Free;
  FResearch.Free;
  inherited Destroy;
end;

function TXcomBase.TargetType: string;
begin
  Result := 'STR_BASE';
end;

function TXcomBase.Marker: Integer;
begin
  if SameAngle(Longitude, 0.0) and SameAngle(Latitude, 0.0) then
    Exit(-1);
  Result := 0;
end;

procedure TXcomBase.Load(const ANode: IYamlNode; const ARuleset: TXcomRuleset; const ARules: TXcomRulesetRules;
  const ATargets: IXcomTargetLookup; const ASettings: IXcomSaveSettings; ANewGame, ACustomInitialBase,
  ANewBattleGame: Boolean);
var
  LItem, LField, LTypeNode: IYamlNode;
  LType: string;
  LFacilityRules: IXcomFacilityRule;
  LFacility: TXcomBaseFacility;
  LCraft: TXcomCraft;
  LSoldierRules: TXcomRuleSoldier;
  LSoldier: TXcomSoldier;
  LCraftId: TXcomCraftId;
  LTransfer: TXcomTransfer;
  LResearch: TXcomRuleResearch;
  LManufacture: TXcomRuleManufacture;
  LNames: TArray<string>;
  LName: string;
  LIndex: Integer;
begin
  inherited Load(ANode);
  if not ANewGame or not ACustomInitialBase or ANewBattleGame then
    for LItem in TXcomNodeReader.Field(ANode, 'facilities').Items do
    begin
      LTypeNode := TXcomNodeReader.Field(LItem, 'type');
      if not LTypeNode.IsDefined then
        raise TXcomNodeReader.BadConversion(LItem);
      LFacilityRules := ARules.Facility(TXcomNodeReader.TextOf(LTypeNode));
      if Assigned(LFacilityRules) then
      begin
        LFacility := TXcomBaseFacility.Create(LFacilityRules);
        LFacility.Load(LItem);
        FFacilities.Add(LFacility);
      end;
    end;
  for LItem in TXcomNodeReader.Field(ANode, 'crafts').Items do
  begin
    LTypeNode := TXcomNodeReader.Field(LItem, 'type');
    if not LTypeNode.IsDefined then
      raise TXcomNodeReader.BadConversion(LItem);
    LType := TXcomNodeReader.TextOf(LTypeNode);
    if Assigned(ARuleset.Crafts.Find(LType)) then
    begin
      LCraft := TXcomCraft.Create(ARuleset.Crafts.Find(LType), Self, 0);
      LCraft.Load(LItem, ARules, ATargets);
      FCrafts.Add(LCraft);
    end;
  end;
  for LItem in TXcomNodeReader.Field(ANode, 'soldiers').Items do
  begin
    LTypeNode := TXcomNodeReader.Field(LItem, 'type');
    if LTypeNode.IsDefined then
      LType := TXcomNodeReader.TextOf(LTypeNode)
    else
      LType := ARuleset.Soldiers.Index[0];
    LSoldierRules := ARuleset.Soldiers.Find(LType);
    if Assigned(LSoldierRules) then
    begin
      LSoldier := TXcomSoldier.Create(LSoldierRules, nil, 0, nil);
      LSoldier.Load(LItem, ARuleset);
      LSoldier.Craft := nil;
      LField := TXcomNodeReader.Field(LItem, 'craft');
      if LField.IsDefined then
      begin
        LCraftId := TXcomCraft.LoadId(LField);
        for LCraft in FCrafts do
          if (LCraft.UniqueId.CraftType = LCraftId.CraftType) and (LCraft.UniqueId.Id = LCraftId.Id) then
          begin
            LSoldier.Craft := LCraft;
            Break;
          end;
      end;
      FSoldiers.Add(LSoldier);
    end;
  end;
  FItems.Load(TXcomNodeReader.Field(ANode, 'items'));
  LNames := nil;
  for LIndex := 0 to FItems.Contents.Count - 1 do
    if not Assigned(ARules.Item(FItems.Contents.Key(LIndex))) then
    begin
      SetLength(LNames, Length(LNames) + 1);
      LNames[High(LNames)] := FItems.Contents.Key(LIndex);
    end;
  for LName in LNames do
    FItems.Contents.Remove(LName);
  FScientists := TXcomNodeReader.ReadInteger(ANode, 'scientists', FScientists);
  FEngineers := TXcomNodeReader.ReadInteger(ANode, 'engineers', FEngineers);
  FInBattlescape := TXcomNodeReader.ReadBoolean(ANode, 'inBattlescape', FInBattlescape);
  for LItem in TXcomNodeReader.Field(ANode, 'transfers').Items do
  begin
    // int hours = (*i)["hours"].as<int>(): a transfer without hours is a bad conversion
    if not TXcomNodeReader.Field(LItem, 'hours').IsDefined then
      raise TXcomNodeReader.BadConversion(LItem);
    LTransfer := TXcomTransfer.Create(TXcomNodeReader.Field(LItem, 'hours').AsInteger);
    if LTransfer.Load(LItem, Self, ARuleset, ARules) then
      FTransfers.Add(LTransfer)
    else
      LTransfer.Free;
  end;
  for LItem in TXcomNodeReader.Field(ANode, 'research').Items do
  begin
    LTypeNode := TXcomNodeReader.Field(LItem, 'project');
    if not LTypeNode.IsDefined then
      raise TXcomNodeReader.BadConversion(LItem);
    LResearch := ARuleset.Research.Find(TXcomNodeReader.TextOf(LTypeNode));
    if Assigned(LResearch) then
    begin
      FResearch.Add(TXcomResearchProject.Create(LResearch, 0));
      FResearch.Last.Load(LItem);
    end
    else
      Inc(FScientists, TXcomNodeReader.ReadInteger(LItem, 'assigned', 0));
  end;
  for LItem in TXcomNodeReader.Field(ANode, 'productions').Items do
  begin
    LTypeNode := TXcomNodeReader.Field(LItem, 'item');
    if not LTypeNode.IsDefined then
      raise TXcomNodeReader.BadConversion(LItem);
    LManufacture := ARuleset.Manufacture.Find(TXcomNodeReader.TextOf(LTypeNode));
    if Assigned(LManufacture) then
    begin
      FProductions.Add(TXcomProduction.Create(LManufacture, 0));
      FProductions.Last.Load(LItem);
    end
    else
      Inc(FEngineers, TXcomNodeReader.ReadInteger(LItem, 'assigned', 0));
  end;
  FRetaliationTarget := TXcomNodeReader.ReadBoolean(ANode, 'retaliationTarget', FRetaliationTarget);
end;

function TXcomBase.Save(const ASettings: IXcomSaveSettings): IYamlNode;
var
  LFacility: TXcomBaseFacility;
  LSoldier: TXcomSoldier;
  LCraft: TXcomCraft;
  LTransfer: TXcomTransfer;
  LResearch: TXcomResearchProject;
  LProduction: TXcomProduction;
begin
  Result := inherited Save;
  for LFacility in FFacilities do
    TXcomNodeWriter.PushBack(Result, 'facilities', LFacility.Save);
  for LSoldier in FSoldiers do
    TXcomNodeWriter.PushBack(Result, 'soldiers', LSoldier.Save(ASettings));
  for LCraft in FCrafts do
    TXcomNodeWriter.PushBack(Result, 'crafts', LCraft.Save);
  TXcomNodeWriter.SetNode(Result, 'items', FItems.Save);
  TXcomNodeWriter.SetInteger(Result, 'scientists', FScientists);
  TXcomNodeWriter.SetInteger(Result, 'engineers', FEngineers);
  if FInBattlescape then
    TXcomNodeWriter.SetBoolean(Result, 'inBattlescape', True);
  for LTransfer in FTransfers do
    TXcomNodeWriter.PushBack(Result, 'transfers', LTransfer.Save(ASettings));
  for LResearch in FResearch do
    TXcomNodeWriter.PushBack(Result, 'research', LResearch.Save);
  for LProduction in FProductions do
    TXcomNodeWriter.PushBack(Result, 'productions', LProduction.Save);
  if FRetaliationTarget then
    TXcomNodeWriter.SetBoolean(Result, 'retaliationTarget', True);
end;

function TXcomBase.AvailableSoldiers(ACheckCombatReadiness: Boolean): Integer;
var
  LSoldier: TXcomSoldier;
begin
  Result := 0;
  for LSoldier in FSoldiers do
  begin
    if not ACheckCombatReadiness and not Assigned(LSoldier.Craft) then
      Inc(Result)
    else if ACheckCombatReadiness and ((Assigned(LSoldier.Craft) and (TXcomCraft(LSoldier.Craft).Status <> 'STR_OUT')) or
      (not Assigned(LSoldier.Craft) and (LSoldier.WoundRecovery = 0))) then
      Inc(Result);
  end;
end;

function TXcomBase.AssignedScientists: Integer;
var
  LResearch: TXcomResearchProject;
begin
  Result := FScientists;
  for LResearch in FResearch do
    Inc(Result, LResearch.Assigned);
end;

function TXcomBase.AssignedEngineers: Integer;
var
  LProduction: TXcomProduction;
begin
  Result := FEngineers;
  for LProduction in FProductions do
    Inc(Result, LProduction.AssignedEngineers);
end;

procedure TXcomBase.AddResearch(const AProject: TXcomResearchProject);
begin
  FResearch.Add(AProject);
end;

procedure TXcomBase.AddProduction(const AProduction: TXcomProduction);
begin
  FProductions.Add(AProduction);
end;

procedure TXcomBase.RemoveResearch(const AProject: TXcomResearchProject);
begin
  Inc(FScientists, AProject.Assigned);
  FResearch.Extract(AProject);
  try
    if not AProject.IsFinished then
      if AProject.Rules.NeedItem and AProject.Rules.DestroyItem then
        FItems.AddItem(AProject.Rules.Name, 1);
  finally
    AProject.Free;
  end;
end;

procedure TXcomBase.RemoveProduction(const AProduction: TXcomProduction);
begin
  Inc(FEngineers, AProduction.AssignedEngineers);
  FProductions.Remove(AProduction);
end;

function TXcomBase.RemoveCraft(const ACraft: TXcomCraft): TXcomCraft;
begin
  // the C++ only takes the craft out of the list (the caller deletes it); the hangar link is not ported
  Result := FCrafts.Extract(ACraft);
end;

end.
