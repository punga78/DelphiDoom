{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the saved game of the geoscape         }
{  (SavedGame)                                                                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.SavedGame;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleResearch, DelphiDoom.XcomSave.NodeWriter,
  DelphiDoom.XcomSave.Serialization, DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.Settings.Intf,
  DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.TargetLookup.Intf, DelphiDoom.XcomSave.MissionLookup.Intf,
  DelphiDoom.XcomSave.GameTime, DelphiDoom.XcomSave.Country, DelphiDoom.XcomSave.Region,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomSave.Waypoint,
  DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomSave.AlienBase, DelphiDoom.XcomSave.AlienMission,
  DelphiDoom.XcomSave.AlienStrategy, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.MissionStatistics,
  DelphiDoom.XcomSave.Rules.Intf, DelphiDoom.XcomSave.Types;

type
  /// <summary>
  ///   What a save file says about the program that wrote it (the version, engine, build and mods of the brief
  ///   header): the C++ takes them from build constants and from Options, here they are given
  /// </summary>
  TXcomSaveBriefInfo = record
    Version: string;
    Engine: string;
    Build: string;
    Mods: TArray<string>;
  end;

  /// <summary>
  ///   The saved game of the geoscape: the time, funds, countries, regions, bases, UFOs, waypoints, sites,
  ///   alien bases, missions and strategy, research, dead soldiers and statistics (SavedGame). It owns what it
  ///   holds. The battlescape (SavedBattleGame: tiles, units, items), the save list and the screens'
  ///   queries (research available, promotions...) are not ported; the "battleGame" document is kept as it is read
  ///   (BattleGame) and Libs.XcomBattle turns it into a battle
  /// </summary>
  TXcomSavedGame = class
  strict private
    FName: string;
    FDifficulty: Integer;
    FEnd: Integer;
    FIronman: Boolean;
    FGlobeLon: Double;
    FGlobeLat: Double;
    FGlobeZoom: Integer;
    FFunds: TArray<Int64>;
    FMaintenance: TArray<Int64>;
    FResearchScores: TArray<Integer>;
    FIncomes: TArray<Int64>;
    FExpenditures: TArray<Int64>;
    FWarned: Boolean;
    FMonthsPassed: Integer;
    FGraphRegionToggles: string;
    FGraphCountryToggles: string;
    FGraphFinanceToggles: string;
    FTime: TXcomGameTime;
    FCountries: TObjectList<TXcomCountry>;
    FRegions: TObjectList<TXcomRegion>;
    FBases: TObjectList<TXcomBase>;
    FUfos: TObjectList<TXcomUfo>;
    FWaypoints: TObjectList<TXcomWaypoint>;
    FMissionSites: TObjectList<TXcomMissionSite>;
    FAlienBases: TObjectList<TXcomAlienBase>;
    FActiveMissions: TObjectList<TXcomAlienMission>;
    FAlienStrategy: TXcomAlienStrategy;
    FDeadSoldiers: TObjectList<TXcomSoldier>;
    FMissionStatistics: TObjectList<TXcomMissionStatistics>;
    FBattleGame: IYamlNode;
    FDiscovered: TList<TXcomRuleResearch>;
    FPoppedResearch: TList<TXcomRuleResearch>;
    FIds: TXcomStringMap<Integer>;
    FLastSelectedArmor: string;
    FRngSeed: UInt64;
    FHasRngSeed: Boolean;
    class function ReadInt64s(const ANode: IYamlNode; const AKey: string; const ADefault: TArray<Int64>)
      : TArray<Int64>; static;
    class function Int64Sequence(const AValues: TArray<Int64>): IYamlNode; static;
    class procedure DropFirst(var AValues: TArray<Int64>); overload; static;
    class procedure DropFirst(var AValues: TArray<Integer>); overload; static;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   load: AFile is the two documents of a .sav (the brief header and the data). The rules are the
    ///   ruleset and its small interfaces; the lists are read in the order that the C++ needs (alien bases
    ///   before missions, missions before UFOs, discoveries before bases). An unknown type is dropped (the
    ///   C++ logs it); a "battleGame" is kept in BattleGame; fewer than two documents is EXcomSaveException
    /// </summary>
    procedure Load(const AFile: TArray<IYamlNode>; const ARuleset: TXcomRuleset; const ARules: TXcomRulesetRules;
      const ASettings: IXcomSaveSettings; ANewSeedOnLoad: Boolean; const ARandom: IXcomRandom);
    /// <summary>
    ///   save: the text of the file (the brief header, "---" and the data) as the emitter of yaml-cpp writes it.
    ///   The seed of the generator is the one of ARandom
    /// </summary>
    function Save(const AInfo: TXcomSaveBriefInfo; const ASettings: IXcomSaveSettings;
      const ARandom: IXcomRandom): TYamlText;
    property Name: string read FName write FName;
    property Difficulty: Integer read FDifficulty write FDifficulty;
    property EndingKind: Integer read FEnd write FEnd;
    property Ironman: Boolean read FIronman write FIronman;
    property GlobeLongitude: Double read FGlobeLon write FGlobeLon;
    property GlobeLatitude: Double read FGlobeLat write FGlobeLat;
    property GlobeZoom: Integer read FGlobeZoom write FGlobeZoom;
    property Warned: Boolean read FWarned write FWarned;
    property MonthsPassed: Integer read FMonthsPassed write FMonthsPassed;
    /// <summary>getGraphRegionToggles: one '0' or '1' per region and the total (the buttons of GraphsState)</summary>
    property GraphRegionToggles: string read FGraphRegionToggles write FGraphRegionToggles;
    property GraphCountryToggles: string read FGraphCountryToggles write FGraphCountryToggles;
    property GraphFinanceToggles: string read FGraphFinanceToggles write FGraphFinanceToggles;
    property Time: TXcomGameTime read FTime;
    property Countries: TObjectList<TXcomCountry> read FCountries;
    property Regions: TObjectList<TXcomRegion> read FRegions;
    property Bases: TObjectList<TXcomBase> read FBases;
    property Ufos: TObjectList<TXcomUfo> read FUfos;
    property Waypoints: TObjectList<TXcomWaypoint> read FWaypoints;
    property MissionSites: TObjectList<TXcomMissionSite> read FMissionSites;
    property AlienBases: TObjectList<TXcomAlienBase> read FAlienBases;
    property ActiveMissions: TObjectList<TXcomAlienMission> read FActiveMissions;
    property AlienStrategy: TXcomAlienStrategy read FAlienStrategy;
    property DeadSoldiers: TObjectList<TXcomSoldier> read FDeadSoldiers;
    property MissionStatistics: TObjectList<TXcomMissionStatistics> read FMissionStatistics;
    /// <summary>
    ///   The "battleGame" document of a saved game in a battle (SavedBattleGame::save), kept as read and written
    ///   back; nil if the game is not in a battle. LibsXcomBattle reads and writes it (this library does not
    ///   depend on it)
    /// </summary>
    property BattleGame: IYamlNode read FBattleGame write FBattleGame;
    property Discovered: TList<TXcomRuleResearch> read FDiscovered;
    property PoppedResearch: TList<TXcomRuleResearch> read FPoppedResearch;
    property Ids: TXcomStringMap<Integer> read FIds;
    property LastSelectedArmor: string read FLastSelectedArmor write FLastSelectedArmor;
    property FundsList: TArray<Int64> read FFunds;
    property IncomesList: TArray<Int64> read FIncomes;
    property ExpendituresList: TArray<Int64> read FExpenditures;
    property MaintenanceList: TArray<Int64> read FMaintenance;
    property ResearchScores: TArray<Integer> read FResearchScores;
    /// <summary>getFunds: the funds of the current month</summary>
    function Funds: Int64;
    /// <summary>setFunds: the difference counts as income or expenditure of the month</summary>
    procedure SetFunds(AFunds: Int64);
    /// <summary>getId: the next number of a kind of object (the counter starts at 1)</summary>
    function GetId(const AName: string): Integer;
    /// <summary>getCountryFunding: the sum of the last funding of every country</summary>
    function CountryFunding: Integer;
    /// <summary>
    ///   monthlyFunding: closes the month. The maintenance of the bases (which needs the capacities of the
    ///   facilities, not ported) is given by the caller
    /// </summary>
    procedure MonthlyFunding(ABaseMaintenance: Integer);
    procedure AddMonth;
    /// <summary>addPoppedResearch / wasResearchPopped / removePoppedResearch</summary>
    procedure AddPoppedResearch(const AResearch: TXcomRuleResearch);
    function WasResearchPopped(const AResearch: TXcomRuleResearch): Boolean;
    procedure RemovePoppedResearch(const AResearch: TXcomRuleResearch);
    /// <summary>addResearchScore: the points of a finished topic go to the score of the current month</summary>
    procedure AddResearchScore(AScore: Integer);
    /// <summary>getResearchScores().at(AIndex) += AScore: the score of a month that is not the current one</summary>
    procedure AddResearchScoreAt(AIndex, AScore: Integer);
    /// <summary>isResearched(name): the topic is in the discovered ones (the debug mode is not ported: AConsiderDebug does nothing)</summary>
    function IsResearched(const AResearch: string; AConsiderDebug: Boolean = True): Boolean; overload;
    /// <summary>isResearched(list): every topic of the list is discovered; an empty list is always researched</summary>
    function IsResearched(const AResearch: TArray<string>; AConsiderDebug: Boolean = True): Boolean; overload;
  end;

implementation

type
  /// <summary>
  ///   What Craft::load and Ufo::load ask of the saved game, over the lists of the game (not owned). It is
  ///   counted by reference, and the saved game outlives it
  /// </summary>
  TXcomSavedGameLookup = class(TInterfacedObject, IXcomTargetLookup, IXcomMissionLookup)
  strict private
    FGame: TXcomSavedGame;
  public
    constructor Create(const AGame: TXcomSavedGame);
    function FindUfo(AId: Integer): TXcomTarget;
    function FindWaypoint(AId: Integer): TXcomTarget;
    function FindMissionSite(AId: Integer; const AMarkerName: string): TXcomTarget;
    function FindAlienBase(AId: Integer; const AMarkerName: string): TXcomTarget;
    function MonthsPassed: Integer;
    function FindMission(AId: Integer): TXcomAlienMission;
  end;

const
  SNeedsTwoDocuments = 'Xcom: the file is not a valid save file';

{ TXcomSavedGameLookup }

constructor TXcomSavedGameLookup.Create(const AGame: TXcomSavedGame);
begin
  inherited Create;
  FGame := AGame;
end;

function TXcomSavedGameLookup.FindUfo(AId: Integer): TXcomTarget;
var
  LUfo: TXcomUfo;
begin
  for LUfo in FGame.Ufos do
    if LUfo.Id = AId then
      Exit(LUfo);
  Result := nil;
end;

function TXcomSavedGameLookup.FindWaypoint(AId: Integer): TXcomTarget;
var
  LWaypoint: TXcomWaypoint;
begin
  for LWaypoint in FGame.Waypoints do
    if LWaypoint.Id = AId then
      Exit(LWaypoint);
  Result := nil;
end;

function TXcomSavedGameLookup.FindMissionSite(AId: Integer; const AMarkerName: string): TXcomTarget;
var
  LSite: TXcomMissionSite;
begin
  for LSite in FGame.MissionSites do
    if (LSite.Id = AId) and (LSite.Deployment.MarkerName = AMarkerName) then
      Exit(LSite);
  Result := nil;
end;

function TXcomSavedGameLookup.FindAlienBase(AId: Integer; const AMarkerName: string): TXcomTarget;
var
  LBase: TXcomAlienBase;
begin
  for LBase in FGame.AlienBases do
    if (LBase.Id = AId) and (LBase.Deployment.MarkerName = AMarkerName) then
      Exit(LBase);
  Result := nil;
end;

function TXcomSavedGameLookup.MonthsPassed: Integer;
begin
  Result := FGame.MonthsPassed;
end;

function TXcomSavedGameLookup.FindMission(AId: Integer): TXcomAlienMission;
var
  LMission: TXcomAlienMission;
begin
  for LMission in FGame.ActiveMissions do
    if LMission.Id = AId then
      Exit(LMission);
  Result := nil;
end;

{ TXcomSavedGame }

constructor TXcomSavedGame.Create;
begin
  inherited Create;
  FTime := TXcomGameTime.Create(6, 1, 1, 1999, 12, 0, 0);
  FAlienStrategy := TXcomAlienStrategy.Create;
  FCountries := TObjectList<TXcomCountry>.Create(True);
  FRegions := TObjectList<TXcomRegion>.Create(True);
  FBases := TObjectList<TXcomBase>.Create(True);
  FUfos := TObjectList<TXcomUfo>.Create(True);
  FWaypoints := TObjectList<TXcomWaypoint>.Create(True);
  FMissionSites := TObjectList<TXcomMissionSite>.Create(True);
  FAlienBases := TObjectList<TXcomAlienBase>.Create(True);
  FActiveMissions := TObjectList<TXcomAlienMission>.Create(True);
  FDeadSoldiers := TObjectList<TXcomSoldier>.Create(True);
  FMissionStatistics := TObjectList<TXcomMissionStatistics>.Create(True);
  FDiscovered := TList<TXcomRuleResearch>.Create;
  FPoppedResearch := TList<TXcomRuleResearch>.Create;
  FIds := TXcomStringMap<Integer>.Create;
  FMonthsPassed := -1;
  SetLength(FFunds, 1);
  SetLength(FMaintenance, 1);
  SetLength(FResearchScores, 1);
  SetLength(FIncomes, 1);
  SetLength(FExpenditures, 1);
  FLastSelectedArmor := 'STR_NONE_UC';
end;

destructor TXcomSavedGame.Destroy;
begin
  // the order of the C++: the UFOs go before the missions they count on, the bases before the targets they follow
  FTime.Free;
  FCountries.Free;
  FRegions.Free;
  FBases.Free;
  FUfos.Free;
  FWaypoints.Free;
  FMissionSites.Free;
  FAlienBases.Free;
  FAlienStrategy.Free;
  FActiveMissions.Free;
  FDeadSoldiers.Free;
  FMissionStatistics.Free;
  FDiscovered.Free;
  FPoppedResearch.Free;
  FIds.Free;
  inherited Destroy;
end;

class function TXcomSavedGame.ReadInt64s(const ANode: IYamlNode; const AKey: string;
  const ADefault: TArray<Int64>): TArray<Int64>;
var
  LField: IYamlNode;
  LItems: TArray<IYamlNode>;
  LIndex: Integer;
begin
  LField := TXcomNodeReader.Field(ANode, AKey);
  if not LField.IsDefined or not LField.IsSequence then
    Exit(ADefault);
  LItems := LField.Items;
  SetLength(Result, Length(LItems));
  for LIndex := 0 to High(LItems) do
    Result[LIndex] := LItems[LIndex].AsInt64;
end;

class function TXcomSavedGame.Int64Sequence(const AValues: TArray<Int64>): IYamlNode;
var
  LValue: Int64;
  LItem: IYamlNode;
begin
  Result := TXcomNodeWriter.NewSequence;
  for LValue in AValues do
  begin
    LItem := TYamlFactory.CreateNode;
    LItem.AssignInt64(LValue);
    Result.Add(LItem);
  end;
end;

class procedure TXcomSavedGame.DropFirst(var AValues: TArray<Int64>);
begin
  Delete(AValues, 0, 1);
end;

class procedure TXcomSavedGame.DropFirst(var AValues: TArray<Integer>);
begin
  Delete(AValues, 0, 1);
end;

procedure TXcomSavedGame.Load(const AFile: TArray<IYamlNode>; const ARuleset: TXcomRuleset;
  const ARules: TXcomRulesetRules; const ASettings: IXcomSaveSettings; ANewSeedOnLoad: Boolean;
  const ARandom: IXcomRandom);
var
  LBrief, LDoc, LItem, LField, LTypeNode: IYamlNode;
  LLookup: IInterface;
  LTargets: IXcomTargetLookup;
  LMissions: IXcomMissionLookup;
  LType, LDeployment, LName: string;
  LCountry: TXcomCountry;
  LRegion: TXcomRegion;
  LAlienBase: TXcomAlienBase;
  LMission: TXcomAlienMission;
  LUfo: TXcomUfo;
  LWaypoint: TXcomWaypoint;
  LSite: TXcomMissionSite;
  LBase: TXcomBase;
  LSoldier: TXcomSoldier;
  LStatistics: TXcomMissionStatistics;
  LResearch: TXcomRuleResearch;
  LDeploymentRules: IXcomDeploymentRule;
  LMissionRules: IXcomMissionRule;
  LIds: TXcomStringMap<Integer>;
begin
  if Length(AFile) < 2 then
    raise EXcomSaveException.Create(SNeedsTwoDocuments);
  LBrief := AFile[0];
  LDoc := AFile[1];
  LLookup := TXcomSavedGameLookup.Create(Self);
  LTargets := LLookup as IXcomTargetLookup;
  LMissions := LLookup as IXcomMissionLookup;
  FTime.Load(TXcomNodeReader.Field(LBrief, 'time'));
  LField := TXcomNodeReader.Field(LBrief, 'name');
  if LField.IsDefined then
    FName := TXcomNodeReader.TextOf(LField);
  FIronman := TXcomNodeReader.ReadBoolean(LBrief, 'ironman', FIronman);
  FDifficulty := TXcomNodeReader.ReadInteger(LDoc, 'difficulty', FDifficulty);
  FEnd := TXcomNodeReader.ReadInteger(LDoc, 'end', FEnd);
  LField := TXcomNodeReader.Field(LDoc, 'rng');
  if LField.IsDefined and (FIronman or not ANewSeedOnLoad) then
    ARandom.SetSeed(LField.AsUInt64);
  FMonthsPassed := TXcomNodeReader.ReadInteger(LDoc, 'monthsPassed', FMonthsPassed);
  FGraphRegionToggles := TXcomNodeReader.ReadString(LDoc, 'graphRegionToggles', FGraphRegionToggles);
  FGraphCountryToggles := TXcomNodeReader.ReadString(LDoc, 'graphCountryToggles', FGraphCountryToggles);
  FGraphFinanceToggles := TXcomNodeReader.ReadString(LDoc, 'graphFinanceToggles', FGraphFinanceToggles);
  FFunds := ReadInt64s(LDoc, 'funds', FFunds);
  FMaintenance := ReadInt64s(LDoc, 'maintenance', FMaintenance);
  FResearchScores := TXcomNodeReader.ReadIntegers(LDoc, 'researchScores', FResearchScores);
  FIncomes := ReadInt64s(LDoc, 'incomes', FIncomes);
  FExpenditures := ReadInt64s(LDoc, 'expenditures', FExpenditures);
  FWarned := TXcomNodeReader.ReadBoolean(LDoc, 'warned', FWarned);
  FGlobeLon := TXcomNodeReader.ReadDouble(LDoc, 'globeLon', FGlobeLon);
  FGlobeLat := TXcomNodeReader.ReadDouble(LDoc, 'globeLat', FGlobeLat);
  FGlobeZoom := TXcomNodeReader.ReadInteger(LDoc, 'globeZoom', FGlobeZoom);
  LIds := FIds;
  TXcomNodeReader.ReadStringIntMap(LDoc, 'ids', LIds);
  for LItem in TXcomNodeReader.Field(LDoc, 'countries').Items do
  begin
    LTypeNode := TXcomNodeReader.Field(LItem, 'type');
    if not LTypeNode.IsDefined then
      raise TXcomNodeReader.BadConversion(LItem);
    if Assigned(ARuleset.Countries.Find(TXcomNodeReader.TextOf(LTypeNode))) then
    begin
      LCountry := TXcomCountry.Create(ARuleset.Countries.Find(TXcomNodeReader.TextOf(LTypeNode)), False, ARandom);
      LCountry.Load(LItem);
      FCountries.Add(LCountry);
    end;
  end;
  for LItem in TXcomNodeReader.Field(LDoc, 'regions').Items do
  begin
    LTypeNode := TXcomNodeReader.Field(LItem, 'type');
    if not LTypeNode.IsDefined then
      raise TXcomNodeReader.BadConversion(LItem);
    if Assigned(ARuleset.Regions.Find(TXcomNodeReader.TextOf(LTypeNode))) then
    begin
      LRegion := TXcomRegion.Create(ARuleset.Regions.Find(TXcomNodeReader.TextOf(LTypeNode)));
      LRegion.Load(LItem);
      FRegions.Add(LRegion);
    end;
  end;
  // alien bases must be loaded before alien missions
  for LItem in TXcomNodeReader.Field(LDoc, 'alienBases').Items do
  begin
    LDeployment := TXcomNodeReader.ReadString(LItem, 'deployment', 'STR_ALIEN_BASE_ASSAULT');
    LDeploymentRules := ARules.Deployment(LDeployment);
    if Assigned(LDeploymentRules) then
    begin
      LAlienBase := TXcomAlienBase.Create(LDeploymentRules);
      LAlienBase.Load(LItem);
      FAlienBases.Add(LAlienBase);
    end;
  end;
  // missions must be loaded before UFOs
  for LItem in TXcomNodeReader.Field(LDoc, 'alienMissions').Items do
  begin
    LTypeNode := TXcomNodeReader.Field(LItem, 'type');
    if not LTypeNode.IsDefined then
      raise TXcomNodeReader.BadConversion(LItem);
    LType := TXcomNodeReader.TextOf(LTypeNode);
    if Assigned(ARuleset.AlienMissions.Find(LType)) then
    begin
      LMission := TXcomAlienMission.Create(ARuleset.AlienMissions.Find(LType));
      LMission.Load(LItem, LTargets);
      FActiveMissions.Add(LMission);
    end;
  end;
  for LItem in TXcomNodeReader.Field(LDoc, 'ufos').Items do
  begin
    LTypeNode := TXcomNodeReader.Field(LItem, 'type');
    if not LTypeNode.IsDefined then
      raise TXcomNodeReader.BadConversion(LItem);
    LType := TXcomNodeReader.TextOf(LTypeNode);
    if Assigned(ARuleset.Ufos.Find(LType)) then
    begin
      LUfo := TXcomUfo.Create(ARuleset.Ufos.Find(LType));
      FUfos.Add(LUfo);
      LUfo.Load(LItem, ARuleset, LMissions);
    end;
  end;
  for LItem in TXcomNodeReader.Field(LDoc, 'waypoints').Items do
  begin
    LWaypoint := TXcomWaypoint.Create;
    LWaypoint.Load(LItem);
    FWaypoints.Add(LWaypoint);
  end;
  // backwards compatibility
  for LItem in TXcomNodeReader.Field(LDoc, 'terrorSites').Items do
  begin
    LMissionRules := ARules.Mission('STR_ALIEN_TERROR');
    LDeploymentRules := ARules.Deployment('STR_TERROR_MISSION');
    if Assigned(LMissionRules) and Assigned(LDeploymentRules) then
    begin
      LSite := TXcomMissionSite.Create(LMissionRules, LDeploymentRules);
      LSite.Load(LItem);
      FMissionSites.Add(LSite);
    end;
  end;
  for LItem in TXcomNodeReader.Field(LDoc, 'missionSites').Items do
  begin
    LTypeNode := TXcomNodeReader.Field(LItem, 'type');
    if not LTypeNode.IsDefined then
      raise TXcomNodeReader.BadConversion(LItem);
    LDeployment := TXcomNodeReader.ReadString(LItem, 'deployment', 'STR_TERROR_MISSION');
    LMissionRules := ARules.Mission(TXcomNodeReader.TextOf(LTypeNode));
    LDeploymentRules := ARules.Deployment(LDeployment);
    if Assigned(LMissionRules) and Assigned(LDeploymentRules) then
    begin
      LSite := TXcomMissionSite.Create(LMissionRules, LDeploymentRules);
      LSite.Load(LItem);
      FMissionSites.Add(LSite);
    end;
  end;
  // discovered technologies are loaded before the bases
  for LItem in TXcomNodeReader.Field(LDoc, 'discovered').Items do
  begin
    LResearch := ARuleset.Research.Find(TXcomNodeReader.TextOf(LItem));
    if Assigned(LResearch) then
      FDiscovered.Add(LResearch);
  end;
  for LItem in TXcomNodeReader.Field(LDoc, 'bases').Items do
  begin
    LBase := TXcomBase.Create;
    FBases.Add(LBase);
    LBase.Load(LItem, ARuleset, ARules, LTargets, ASettings, False, False, False);
  end;
  for LItem in TXcomNodeReader.Field(LDoc, 'poppedResearch').Items do
  begin
    LResearch := ARuleset.Research.Find(TXcomNodeReader.TextOf(LItem));
    if Assigned(LResearch) then
      FPoppedResearch.Add(LResearch);
  end;
  FAlienStrategy.Load(TXcomNodeReader.Field(LDoc, 'alienStrategy'));
  for LItem in TXcomNodeReader.Field(LDoc, 'deadSoldiers').Items do
  begin
    LTypeNode := TXcomNodeReader.Field(LItem, 'type');
    if LTypeNode.IsDefined then
      LName := TXcomNodeReader.TextOf(LTypeNode)
    else
      LName := ARuleset.Soldiers.Index[0];
    if Assigned(ARuleset.Soldiers.Find(LName)) then
    begin
      LSoldier := TXcomSoldier.Create(ARuleset.Soldiers.Find(LName), nil, 0, nil);
      LSoldier.Load(LItem, ARuleset);
      FDeadSoldiers.Add(LSoldier);
    end;
  end;
  for LItem in TXcomNodeReader.Field(LDoc, 'missionStatistics').Items do
  begin
    LStatistics := TXcomMissionStatistics.Create;
    LStatistics.Load(LItem);
    FMissionStatistics.Add(LStatistics);
  end;
  if TXcomNodeReader.Field(LDoc, 'battleGame').IsDefined then
    FBattleGame := TXcomNodeReader.Field(LDoc, 'battleGame');
end;

function TXcomSavedGame.Save(const AInfo: TXcomSaveBriefInfo; const ASettings: IXcomSaveSettings;
  const ARandom: IXcomRandom): TYamlText;
var
  LBrief, LNode, LMods, LItem: IYamlNode;
  LEmitter: IYamlEmitter;
  LIndex: Integer;
  LBuild, LMod: string;
  LIds: IYamlNode;
  LCountry: TXcomCountry;
  LRegion: TXcomRegion;
  LBase: TXcomBase;
  LWaypoint: TXcomWaypoint;
  LSite: TXcomMissionSite;
  LAlienBase: TXcomAlienBase;
  LMission: TXcomAlienMission;
  LUfo: TXcomUfo;
  LResearch: TXcomRuleResearch;
  LSoldier: TXcomSoldier;
  LStatistics: TXcomMissionStatistics;
begin
  LBrief := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetString(LBrief, 'name', FName);
  TXcomNodeWriter.SetString(LBrief, 'version', AInfo.Version);
  TXcomNodeWriter.SetString(LBrief, 'engine', AInfo.Engine);
  LBuild := AInfo.Build;
  if (LBuild <> '') and (LBuild[1] = '.') then
    Delete(LBuild, 1, 1);
  TXcomNodeWriter.SetString(LBrief, 'build', LBuild);
  TXcomNodeWriter.SetNode(LBrief, 'time', FTime.Save);
  if Assigned(FBattleGame) then
  begin
    TXcomNodeWriter.SetString(LBrief, 'mission', TXcomNodeReader.ReadString(FBattleGame, 'missionType', ''));
    TXcomNodeWriter.SetInteger(LBrief, 'turn', TXcomNodeReader.ReadInteger(FBattleGame, 'turn', 0));
  end;
  LMods := TXcomNodeWriter.NewSequence;
  for LMod in AInfo.Mods do
    LMods.Add(YamlStringToText(LMod));
  TXcomNodeWriter.SetNode(LBrief, 'mods', LMods);
  if FIronman then
    TXcomNodeWriter.SetBoolean(LBrief, 'ironman', True);
  LNode := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetInteger(LNode, 'difficulty', FDifficulty);
  TXcomNodeWriter.SetInteger(LNode, 'end', FEnd);
  TXcomNodeWriter.SetInteger(LNode, 'monthsPassed', FMonthsPassed);
  TXcomNodeWriter.SetString(LNode, 'graphRegionToggles', FGraphRegionToggles);
  TXcomNodeWriter.SetString(LNode, 'graphCountryToggles', FGraphCountryToggles);
  TXcomNodeWriter.SetString(LNode, 'graphFinanceToggles', FGraphFinanceToggles);
  LItem := TYamlFactory.CreateNode;
  LItem.AssignUInt64(ARandom.Seed);
  TXcomNodeWriter.SetNode(LNode, 'rng', LItem);
  TXcomNodeWriter.SetNode(LNode, 'funds', Int64Sequence(FFunds));
  TXcomNodeWriter.SetNode(LNode, 'maintenance', Int64Sequence(FMaintenance));
  LItem := TXcomNodeWriter.NewSequence;
  for LIndex := 0 to High(FResearchScores) do
    LItem.Add(YamlStringToText(IntToStr(FResearchScores[LIndex])));
  TXcomNodeWriter.SetNode(LNode, 'researchScores', LItem);
  TXcomNodeWriter.SetNode(LNode, 'incomes', Int64Sequence(FIncomes));
  TXcomNodeWriter.SetNode(LNode, 'expenditures', Int64Sequence(FExpenditures));
  TXcomNodeWriter.SetBoolean(LNode, 'warned', FWarned);
  TXcomNodeWriter.SetString(LNode, 'globeLon', TXcomSerialization.SerializeDouble(FGlobeLon));
  TXcomNodeWriter.SetString(LNode, 'globeLat', TXcomSerialization.SerializeDouble(FGlobeLat));
  TXcomNodeWriter.SetInteger(LNode, 'globeZoom', FGlobeZoom);
  LIds := TXcomNodeWriter.NewEmptyMap;
  for LIndex := 0 to FIds.Count - 1 do
    TXcomNodeWriter.SetInteger(LIds, FIds.Key(LIndex), FIds.Value(LIndex));
  TXcomNodeWriter.SetNode(LNode, 'ids', LIds);
  for LCountry in FCountries do
    TXcomNodeWriter.PushBack(LNode, 'countries', LCountry.Save);
  for LRegion in FRegions do
    TXcomNodeWriter.PushBack(LNode, 'regions', LRegion.Save);
  for LBase in FBases do
    TXcomNodeWriter.PushBack(LNode, 'bases', LBase.Save(ASettings));
  for LWaypoint in FWaypoints do
    TXcomNodeWriter.PushBack(LNode, 'waypoints', LWaypoint.Save);
  for LSite in FMissionSites do
    TXcomNodeWriter.PushBack(LNode, 'missionSites', LSite.Save);
  // alien bases before the missions; the missions before the UFOs
  for LAlienBase in FAlienBases do
    TXcomNodeWriter.PushBack(LNode, 'alienBases', LAlienBase.Save);
  for LMission in FActiveMissions do
    TXcomNodeWriter.PushBack(LNode, 'alienMissions', LMission.Save);
  for LUfo in FUfos do
    TXcomNodeWriter.PushBack(LNode, 'ufos', LUfo.Save(FMonthsPassed = -1));
  for LResearch in FDiscovered do
    TXcomNodeWriter.PushBack(LNode, 'discovered', TYamlFactory.CreateScalar(YamlStringToText(LResearch.Name)));
  for LResearch in FPoppedResearch do
    TXcomNodeWriter.PushBack(LNode, 'poppedResearch', TYamlFactory.CreateScalar(YamlStringToText(LResearch.Name)));
  TXcomNodeWriter.SetNode(LNode, 'alienStrategy', FAlienStrategy.Save);
  for LSoldier in FDeadSoldiers do
    TXcomNodeWriter.PushBack(LNode, 'deadSoldiers', LSoldier.Save(ASettings));
  if ASettings.SoldierDiaries then
    for LStatistics in FMissionStatistics do
      TXcomNodeWriter.PushBack(LNode, 'missionStatistics', LStatistics.Save);
  if Assigned(FBattleGame) then
    TXcomNodeWriter.SetNode(LNode, 'battleGame', FBattleGame);
  LEmitter := TYamlFactory.CreateEmitter;
  LEmitter.WriteNode(LBrief);
  LEmitter.Manip(ymBeginDoc);
  LEmitter.WriteNode(LNode);
  Result := LEmitter.Text;
end;

function TXcomSavedGame.Funds: Int64;
begin
  Result := FFunds[High(FFunds)];
end;

procedure TXcomSavedGame.SetFunds(AFunds: Int64);
begin
  if FFunds[High(FFunds)] > AFunds then
    Inc(FExpenditures[High(FExpenditures)], FFunds[High(FFunds)] - AFunds)
  else
    Inc(FIncomes[High(FIncomes)], AFunds - FFunds[High(FFunds)]);
  FFunds[High(FFunds)] := AFunds;
end;

function TXcomSavedGame.GetId(const AName: string): Integer;
begin
  if not FIds.TryGetValue(AName, Result) then
    Result := 1;
  FIds.SetValue(AName, Result + 1);
end;

function TXcomSavedGame.CountryFunding: Integer;
var
  LCountry: TXcomCountry;
begin
  Result := 0;
  for LCountry in FCountries do
    Inc(Result, LCountry.Funding[High(LCountry.Funding)]);
end;

procedure TXcomSavedGame.MonthlyFunding(ABaseMaintenance: Integer);
begin
  Inc(FFunds[High(FFunds)], CountryFunding - ABaseMaintenance);
  SetLength(FFunds, Length(FFunds) + 1);
  FFunds[High(FFunds)] := FFunds[High(FFunds) - 1];
  FMaintenance[High(FMaintenance)] := ABaseMaintenance;
  SetLength(FMaintenance, Length(FMaintenance) + 1);
  FMaintenance[High(FMaintenance)] := 0;
  SetLength(FIncomes, Length(FIncomes) + 1);
  FIncomes[High(FIncomes)] := CountryFunding;
  SetLength(FExpenditures, Length(FExpenditures) + 1);
  FExpenditures[High(FExpenditures)] := ABaseMaintenance;
  SetLength(FResearchScores, Length(FResearchScores) + 1);
  FResearchScores[High(FResearchScores)] := 0;
  if Length(FIncomes) > 12 then
    DropFirst(FIncomes);
  if Length(FExpenditures) > 12 then
    DropFirst(FExpenditures);
  if Length(FResearchScores) > 12 then
    DropFirst(FResearchScores);
  if Length(FFunds) > 12 then
    DropFirst(FFunds);
  if Length(FMaintenance) > 12 then
    DropFirst(FMaintenance);
end;

procedure TXcomSavedGame.AddMonth;
begin
  Inc(FMonthsPassed);
end;

procedure TXcomSavedGame.AddPoppedResearch(const AResearch: TXcomRuleResearch);
begin
  if not WasResearchPopped(AResearch) then
    FPoppedResearch.Add(AResearch);
end;

function TXcomSavedGame.WasResearchPopped(const AResearch: TXcomRuleResearch): Boolean;
begin
  Result := FPoppedResearch.IndexOf(AResearch) >= 0;
end;

procedure TXcomSavedGame.RemovePoppedResearch(const AResearch: TXcomRuleResearch);
begin
  FPoppedResearch.Remove(AResearch);
end;

procedure TXcomSavedGame.AddResearchScore(AScore: Integer);
begin
  Inc(FResearchScores[High(FResearchScores)], AScore);
end;

procedure TXcomSavedGame.AddResearchScoreAt(AIndex, AScore: Integer);
begin
  Inc(FResearchScores[AIndex], AScore);
end;

function TXcomSavedGame.IsResearched(const AResearch: string; AConsiderDebug: Boolean): Boolean;
var
  LDiscovered: TXcomRuleResearch;
begin
  for LDiscovered in FDiscovered do
    if LDiscovered.Name = AResearch then
      Exit(True);
  Result := False;
end;

function TXcomSavedGame.IsResearched(const AResearch: TArray<string>; AConsiderDebug: Boolean): Boolean;
var
  LName: string;
begin
  // every name must be discovered (the C++ erases the matches from a copy of the list: the same answer)
  for LName in AResearch do
    if not IsResearched(LName, AConsiderDebug) then
      Exit(False);
  Result := True;
end;

end.
