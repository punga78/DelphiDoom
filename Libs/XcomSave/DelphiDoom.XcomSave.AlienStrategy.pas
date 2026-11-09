{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - what the aliens plan to do             }
{  (AlienStrategy)                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.AlienStrategy;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.WeightedOptions, DelphiDoom.XcomMod.RuleRegion,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.NodeWriter, DelphiDoom.XcomSave.Types;

type
  /// <summary>A region and a zone where a mission of a script already was (the pair of missionLocations)</summary>
  TXcomMissionLocation = record
    Region: string;
    Zone: Integer;
  end;

  /// <summary>
  ///   The odds of the regions and of the missions in them, the places where the missions of the scripts were
  ///   and how many times they ran (AlienStrategy)
  /// </summary>
  TXcomAlienStrategy = class
  strict private
    FRegionChances: TXcomWeightedOptions;
    FRegionMissions: TXcomStringMap<TXcomWeightedOptions>;
    FMissionLocations: TXcomStringMap<TArray<TXcomMissionLocation>>;
    FMissionRuns: TXcomStringMap<Integer>;
    procedure FreeMissions;
    function DecodeLocations(const ANode: IYamlNode): TArray<TXcomMissionLocation>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>init: every region of the ruleset with its weight and a copy of its missions</summary>
    procedure Init(const ARuleset: TXcomRuleset);
    /// <summary>
    ///   load: the regions, the possible missions by region (a region with no name is EYamlBadConversion), the
    ///   places and the runs (a node of another kind keeps what there is)
    /// </summary>
    procedure Load(const ANode: IYamlNode);
    function Save: IYamlNode;
    /// <summary>
    ///   chooseRandomRegion: a region by weight; if there are none left the lists start over. Nothing to
    ///   choose even then is EXcomSaveException (the C++ asserts)
    /// </summary>
    function ChooseRandomRegion(const ARuleset: TXcomRuleset; const ARandom: IXcomRandom): string;
    /// <summary>chooseRandomMission: a region that is not in the list is EXcomSaveException (assert)</summary>
    function ChooseRandomMission(const ARegion: string; const ARandom: IXcomRandom): string;
    /// <summary>removeMission: the region is dropped with its odds when it has no missions left; true if none are left</summary>
    function RemoveMission(const ARegion, AMission: string): Boolean;
    function MissionsRun(const AVarName: string): Integer;
    procedure AddMissionRun(const AVarName: string; AIncrement: Integer);
    /// <summary>
    ///   addMissionLocation: as the C++ does, when the list is over the maximum the FIRST VARIABLE of the map
    ///   is erased (not the first place of this one)
    /// </summary>
    procedure AddMissionLocation(const AVarName, ARegionName: string; AZoneNumber, AMaximum: Integer);
    function ValidMissionLocation(const AVarName, ARegionName: string; AZoneNumber: Integer): Boolean;
    function ValidMissionRegion(const ARegion: string): Boolean;
    property RegionChances: TXcomWeightedOptions read FRegionChances;
    property MissionRuns: TXcomStringMap<Integer> read FMissionRuns;
    property MissionLocations: TXcomStringMap<TArray<TXcomMissionLocation>> read FMissionLocations;
  end;

implementation

{ TXcomAlienStrategy }

constructor TXcomAlienStrategy.Create;
begin
  inherited Create;
  FRegionChances := TXcomWeightedOptions.Create;
  FRegionMissions := TXcomStringMap<TXcomWeightedOptions>.Create;
  FMissionLocations := TXcomStringMap<TArray<TXcomMissionLocation>>.Create;
  FMissionRuns := TXcomStringMap<Integer>.Create;
end;

destructor TXcomAlienStrategy.Destroy;
begin
  FreeMissions;
  FRegionMissions.Free;
  FRegionChances.Free;
  FMissionLocations.Free;
  FMissionRuns.Free;
  inherited Destroy;
end;

procedure TXcomAlienStrategy.FreeMissions;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FRegionMissions.Count - 1 do
    FRegionMissions.Value(LIndex).Free;
  FRegionMissions.Clear;
end;

procedure TXcomAlienStrategy.Init(const ARuleset: TXcomRuleset);
var
  LName: string;
  LRegion: TXcomRuleRegion;
  LOld: TXcomWeightedOptions;
begin
  for LName in ARuleset.Regions.Index do
  begin
    LRegion := ARuleset.Regions.Find(LName);
    FRegionChances.SetWeight(LName, LRegion.Weight);
    // map::insert does not replace a region that is already there
    if not FRegionMissions.TryGetValue(LName, LOld) then
      FRegionMissions.SetValue(LName, LRegion.MissionWeights.Copy);
  end;
end;

function TXcomAlienStrategy.DecodeLocations(const ANode: IYamlNode): TArray<TXcomMissionLocation>;
var
  LItems, LPair: TArray<IYamlNode>;
  LIndex: Integer;
begin
  if not ANode.IsSequence then
    raise TXcomNodeReader.BadConversion(ANode);
  LItems := ANode.Items;
  SetLength(Result, Length(LItems));
  for LIndex := 0 to High(LItems) do
  begin
    // convert<pair>: a sequence of exactly two elements
    if not LItems[LIndex].IsSequence or (LItems[LIndex].Size <> 2) then
      raise TXcomNodeReader.BadConversion(LItems[LIndex]);
    LPair := LItems[LIndex].Items;
    Result[LIndex].Region := TXcomNodeReader.TextOf(LPair[0]);
    Result[LIndex].Zone := LPair[1].AsInteger;
  end;
end;

procedure TXcomAlienStrategy.Load(const ANode: IYamlNode);
var
  LItem, LField, LRegionNode: IYamlNode;
  LOptions, LOld: TXcomWeightedOptions;
  LPair: TYamlPair;
  LName: string;
  LValues: TXcomStringMap<TArray<TXcomMissionLocation>>;
  LRuns: TXcomStringMap<Integer>;
begin
  FreeMissions;
  FRegionChances.Clear;
  FRegionChances.Load(TXcomNodeReader.Field(ANode, 'regions'));
  for LItem in TXcomNodeReader.Field(ANode, 'possibleMissions').Items do
  begin
    LRegionNode := TXcomNodeReader.Field(LItem, 'region');
    if not LRegionNode.IsDefined then
      raise TXcomNodeReader.BadConversion(LItem);
    LName := TXcomNodeReader.TextOf(LRegionNode);
    LOptions := TXcomWeightedOptions.Create;
    LOptions.Load(TXcomNodeReader.Field(LItem, 'missions'));
    if FRegionMissions.TryGetValue(LName, LOld) then
      // map::insert keeps the first one (the C++ leaks the new one)
      LOptions.Free
    else
      FRegionMissions.SetValue(LName, LOptions);
  end;
  LField := TXcomNodeReader.Field(ANode, 'missionLocations');
  if LField.IsDefined and LField.IsMap then
  begin
    LValues := FMissionLocations;
    LValues.Clear;
    for LPair in LField.Pairs do
      LValues.SetValue(TXcomNodeReader.TextOf(LPair.Key), DecodeLocations(LPair.Value));
  end;
  LField := TXcomNodeReader.Field(ANode, 'missionsRun');
  if LField.IsDefined and LField.IsMap then
  begin
    LRuns := FMissionRuns;
    LRuns.Clear;
    for LPair in LField.Pairs do
      LRuns.SetValue(TXcomNodeReader.TextOf(LPair.Key), LPair.Value.AsInteger);
  end;
end;

function TXcomAlienStrategy.Save: IYamlNode;
var
  LIndex, LPlace: Integer;
  LSubnode, LMap, LList, LPairNode: IYamlNode;
  LPlaces: TArray<TXcomMissionLocation>;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetNode(Result, 'regions', FRegionChances.Save);
  for LIndex := 0 to FRegionMissions.Count - 1 do
  begin
    LSubnode := TXcomNodeWriter.NewMap;
    TXcomNodeWriter.SetString(LSubnode, 'region', FRegionMissions.Key(LIndex));
    TXcomNodeWriter.SetNode(LSubnode, 'missions', FRegionMissions.Value(LIndex).Save);
    TXcomNodeWriter.PushBack(Result, 'possibleMissions', LSubnode);
  end;
  // a std::map assigned to a node is a map node, even when it is empty
  LMap := TXcomNodeWriter.NewEmptyMap;
  for LIndex := 0 to FMissionLocations.Count - 1 do
  begin
    LPlaces := FMissionLocations.Value(LIndex);
    LList := TXcomNodeWriter.NewSequence;
    for LPlace := 0 to High(LPlaces) do
    begin
      LPairNode := TXcomNodeWriter.NewSequence;
      LPairNode.Add(YamlStringToText(LPlaces[LPlace].Region));
      LPairNode.Add(YamlStringToText(IntToStr(LPlaces[LPlace].Zone)));
      LList.Add(LPairNode);
    end;
    LMap.Child(YamlStringToText(FMissionLocations.Key(LIndex))).Assign(LList);
  end;
  TXcomNodeWriter.SetNode(Result, 'missionLocations', LMap);
  LMap := TXcomNodeWriter.NewEmptyMap;
  for LIndex := 0 to FMissionRuns.Count - 1 do
    TXcomNodeWriter.SetInteger(LMap, FMissionRuns.Key(LIndex), FMissionRuns.Value(LIndex));
  TXcomNodeWriter.SetNode(Result, 'missionsRun', LMap);
end;

function TXcomAlienStrategy.ChooseRandomRegion(const ARuleset: TXcomRuleset; const ARandom: IXcomRandom): string;
begin
  Result := FRegionChances.Choose(ARandom);
  if Result = '' then
  begin
    // no more missions to choose from: refresh
    FreeMissions;
    Init(ARuleset);
    Result := FRegionChances.Choose(ARandom);
  end;
  if Result = '' then
    raise EXcomSaveException.Create('Xcom: the aliens have no region to choose');
end;

function TXcomAlienStrategy.ChooseRandomMission(const ARegion: string; const ARandom: IXcomRandom): string;
var
  LOptions: TXcomWeightedOptions;
begin
  if not FRegionMissions.TryGetValue(ARegion, LOptions) then
    raise EXcomSaveException.CreateFmt('Xcom: the region %s has no missions', [ARegion]);
  Result := LOptions.Choose(ARandom);
end;

function TXcomAlienStrategy.RemoveMission(const ARegion, AMission: string): Boolean;
var
  LOptions: TXcomWeightedOptions;
begin
  if FRegionMissions.TryGetValue(ARegion, LOptions) then
  begin
    LOptions.SetWeight(AMission, 0);
    if LOptions.IsEmpty then
    begin
      FRegionMissions.Remove(ARegion);
      LOptions.Free;
      FRegionChances.SetWeight(ARegion, 0);
    end;
  end;
  Result := FRegionMissions.Count = 0;
end;

function TXcomAlienStrategy.MissionsRun(const AVarName: string): Integer;
begin
  if not FMissionRuns.TryGetValue(AVarName, Result) then
    Result := 0;
end;

procedure TXcomAlienStrategy.AddMissionRun(const AVarName: string; AIncrement: Integer);
begin
  if AVarName = '' then
    Exit;
  FMissionRuns.SetValue(AVarName, MissionsRun(AVarName) + AIncrement);
end;

procedure TXcomAlienStrategy.AddMissionLocation(const AVarName, ARegionName: string; AZoneNumber, AMaximum: Integer);
var
  LPlaces: TArray<TXcomMissionLocation>;
begin
  if AMaximum <= 0 then
    Exit;
  if not FMissionLocations.TryGetValue(AVarName, LPlaces) then
    LPlaces := nil;
  SetLength(LPlaces, Length(LPlaces) + 1);
  LPlaces[High(LPlaces)].Region := ARegionName;
  LPlaces[High(LPlaces)].Zone := AZoneNumber;
  FMissionLocations.SetValue(AVarName, LPlaces);
  if Length(LPlaces) > AMaximum then
    FMissionLocations.Remove(FMissionLocations.Key(0));
end;

function TXcomAlienStrategy.ValidMissionLocation(const AVarName, ARegionName: string; AZoneNumber: Integer): Boolean;
var
  LPlaces: TArray<TXcomMissionLocation>;
  LPlace: TXcomMissionLocation;
begin
  if FMissionLocations.TryGetValue(AVarName, LPlaces) then
    for LPlace in LPlaces do
      if (LPlace.Region = ARegionName) and (LPlace.Zone = AZoneNumber) then
        Exit(False);
  Result := True;
end;

function TXcomAlienStrategy.ValidMissionRegion(const ARegion: string): Boolean;
begin
  Result := FRegionMissions.ContainsKey(ARegion);
end;

end.
