{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a type of alien mission (RuleAlienMission)}
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleAlienMission;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.WeightedOptions;

type
  /// <summary>MissionWave: the UFOs of one step of a mission: type, how many, trajectory, delay, objective flag</summary>
  TXcomMissionWave = record
    UfoType: string;
    UfoCount: Cardinal;
    Trajectory: string;
    SpawnTimer: Cardinal;
    Objective: Boolean;
  end;

  /// <summary>
  ///   The fixed data of a type of mission: its waves of UFOs, the races that undertake it by month and its
  ///   weight by month (RuleAlienMission). It owns the race distributions. The numbers of months and waves are
  ///   32 bit (size_t of the Win32 build)
  /// </summary>
  TXcomRuleAlienMission = class
  public
    const
      /// <summary>MissionObjective: OBJECTIVE_SCORE, INFILTRATION, BASE, SITE, RETALIATION, SUPPLY</summary>
      OBJECTIVE_SCORE = 0;
      OBJECTIVE_INFILTRATION = 1;
      OBJECTIVE_BASE = 2;
      OBJECTIVE_SITE = 3;
      OBJECTIVE_RETALIATION = 4;
      OBJECTIVE_SUPPLY = 5;
  strict private
    FType: string;
    FSpawnUfo: string;
    FRaceMonths: TList<Cardinal>;
    FRaceOptions: TObjectList<TXcomWeightedOptions>;
    FWeightMonths: TList<Cardinal>;
    FWeightValues: TList<Integer>;
    FWaves: TArray<TXcomMissionWave>;
    FPoints: Integer;
    FObjective: Integer;
    FSpawnZone: Integer;
    FRetaliationOdds: Integer;
    FSiteType: string;
    procedure ReadWaves(const ANode: IYamlNode);
    procedure ReadWeights(const ANode: IYamlNode);
    procedure ReadRaces(const AWeights: IYamlNode);
    procedure SetWeight(AMonth: Cardinal; AValue: Integer);
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    /// <summary>Loads the mission from a YAML node; raceWeights are merged by month and empty ones dropped</summary>
    procedure Load(const ANode: IYamlNode);
    /// <summary>generateRace: one of the races of the last month at or before AMonthsPassed ('' if none)</summary>
    function GenerateRace(AMonthsPassed: Cardinal; const ARandom: IXcomRandom): string;
    /// <summary>getWeight: the weight of the last month at or before AMonthsPassed (1 if there are no weights)</summary>
    function GetWeight(AMonthsPassed: Cardinal): Integer;
    function WaveCount: Integer;
    property MissionType: string read FType;
    property Waves: TArray<TXcomMissionWave> read FWaves;
    property Points: Integer read FPoints;
    property Objective: Integer read FObjective;
    property SpawnUfo: string read FSpawnUfo;
    property SpawnZone: Integer read FSpawnZone;
    property RetaliationOdds: Integer read FRetaliationOdds;
    property SiteType: string read FSiteType;
    /// <summary>The number of months with a race distribution</summary>
    function RaceMonthCount: Integer;
    function RaceMonth(AIndex: Integer): Cardinal;
    function RaceOptions(AIndex: Integer): TXcomWeightedOptions;
    function WeightMonthCount: Integer;
    function WeightMonth(AIndex: Integer): Cardinal;
    function WeightValue(AIndex: Integer): Integer;
  end;

implementation

{ TXcomRuleAlienMission }

constructor TXcomRuleAlienMission.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FObjective := OBJECTIVE_SCORE;
  FSpawnZone := -1;
  FRetaliationOdds := -1;
  FRaceMonths := TList<Cardinal>.Create;
  FRaceOptions := TObjectList<TXcomWeightedOptions>.Create(True);
  FWeightMonths := TList<Cardinal>.Create;
  FWeightValues := TList<Integer>.Create;
end;

destructor TXcomRuleAlienMission.Destroy;
begin
  FWeightValues.Free;
  FWeightMonths.Free;
  FRaceOptions.Free;
  FRaceMonths.Free;
  inherited Destroy;
end;

procedure TXcomRuleAlienMission.ReadWaves(const ANode: IYamlNode);
var
  LField, LItem: IYamlNode;
  LItems: TArray<IYamlNode>;
  LIndex: Integer;
begin
  LField := TXcomNodeReader.Field(ANode, 'waves');
  if not LField.IsDefined or not LField.IsSequence then
    Exit;
  LItems := LField.Items;
  FWaves := nil;
  SetLength(FWaves, Length(LItems));
  for LIndex := 0 to High(LItems) do
  begin
    LItem := LItems[LIndex];
    if not LItem.IsMap then
      raise TXcomNodeReader.BadConversion(LItem);
    FWaves[LIndex].UfoType := TXcomNodeReader.TextOf(TXcomNodeReader.Field(LItem, 'ufo'));
    FWaves[LIndex].UfoCount := TXcomNodeReader.Field(LItem, 'count').AsCardinal;
    FWaves[LIndex].Trajectory := TXcomNodeReader.TextOf(TXcomNodeReader.Field(LItem, 'trajectory'));
    FWaves[LIndex].SpawnTimer := TXcomNodeReader.Field(LItem, 'timer').AsCardinal;
    FWaves[LIndex].Objective := TXcomNodeReader.ReadBoolean(LItem, 'objective', False);
  end;
end;

procedure TXcomRuleAlienMission.SetWeight(AMonth: Cardinal; AValue: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FWeightMonths.Count - 1 do
    if FWeightMonths[LIndex] = AMonth then
    begin
      FWeightValues[LIndex] := AValue;
      Exit;
    end
    else if FWeightMonths[LIndex] > AMonth then
    begin
      FWeightMonths.Insert(LIndex, AMonth);
      FWeightValues.Insert(LIndex, AValue);
      Exit;
    end;
  FWeightMonths.Add(AMonth);
  FWeightValues.Add(AValue);
end;

procedure TXcomRuleAlienMission.ReadWeights(const ANode: IYamlNode);
var
  LField: IYamlNode;
  LPair: TYamlPair;
  LOldMonths: TList<Cardinal>;
  LOldValues: TList<Integer>;
begin
  LField := TXcomNodeReader.Field(ANode, 'missionWeights');
  if not LField.IsDefined or not LField.IsMap then
    Exit;
  // as<std::map<size_t, int>>(fallback) builds a new map: the old weights are replaced, not merged
  LOldMonths := TList<Cardinal>.Create;
  LOldValues := TList<Integer>.Create;
  try
    LOldMonths.AddRange(FWeightMonths);
    LOldValues.AddRange(FWeightValues);
    FWeightMonths.Clear;
    FWeightValues.Clear;
    try
      for LPair in LField.Pairs do
        SetWeight(LPair.Key.AsCardinal, LPair.Value.AsInteger);
    except
      FWeightMonths.Clear;
      FWeightValues.Clear;
      FWeightMonths.AddRange(LOldMonths);
      FWeightValues.AddRange(LOldValues);
      raise;
    end;
  finally
    LOldValues.Free;
    LOldMonths.Free;
  end;
end;

procedure TXcomRuleAlienMission.ReadRaces(const AWeights: IYamlNode);
var
  LMonths: TList<Cardinal>;
  LOptions: TObjectList<TXcomWeightedOptions>;
  LPair: TYamlPair;
  LMonth: Cardinal;
  LPosition, LIndex: Integer;
  LNew: TXcomWeightedOptions;
begin
  // the existing entries go in a table by month; the ones in the node are merged; empty ones are dropped
  LMonths := TList<Cardinal>.Create;
  LOptions := TObjectList<TXcomWeightedOptions>.Create(False);
  try
    for LIndex := 0 to FRaceMonths.Count - 1 do
    begin
      LMonths.Add(FRaceMonths[LIndex]);
      LOptions.Add(FRaceOptions[LIndex]);
    end;
    for LPair in AWeights.Pairs do
    begin
      LMonth := LPair.Key.AsCardinal;
      LPosition := LMonths.IndexOf(LMonth);
      if LPosition < 0 then
      begin
        LNew := TXcomWeightedOptions.Create;
        try
          LNew.Load(LPair.Value);
        except
          LNew.Free;
          raise;
        end;
        // keep the months sorted (std::map)
        LPosition := 0;
        while (LPosition < LMonths.Count) and (LMonths[LPosition] < LMonth) do
          Inc(LPosition);
        LMonths.Insert(LPosition, LMonth);
        LOptions.Insert(LPosition, LNew);
      end
      else
        LOptions[LPosition].Load(LPair.Value);
    end;
    // replace the members: the non-empty entries stay (and are owned again), the empty ones are freed
    FRaceOptions.OwnsObjects := False;
    FRaceOptions.Clear;
    FRaceOptions.OwnsObjects := True;
    FRaceMonths.Clear;
    for LIndex := 0 to LMonths.Count - 1 do
      if LOptions[LIndex].IsEmpty then
        LOptions[LIndex].Free
      else
      begin
        FRaceMonths.Add(LMonths[LIndex]);
        FRaceOptions.Add(LOptions[LIndex]);
      end;
  finally
    LOptions.Free;
    LMonths.Free;
  end;
end;

procedure TXcomRuleAlienMission.Load(const ANode: IYamlNode);
var
  LWeights: IYamlNode;
begin
  FType := TXcomNodeReader.ReadString(ANode, 'type', FType);
  FPoints := TXcomNodeReader.ReadInteger(ANode, 'points', FPoints);
  ReadWaves(ANode);
  FObjective := TXcomNodeReader.ReadInteger(ANode, 'objective', FObjective);
  FSpawnUfo := TXcomNodeReader.ReadString(ANode, 'spawnUfo', FSpawnUfo);
  FSpawnZone := TXcomNodeReader.ReadInteger(ANode, 'spawnZone', FSpawnZone);
  ReadWeights(ANode);
  FRetaliationOdds := TXcomNodeReader.ReadInteger(ANode, 'retaliationOdds', FRetaliationOdds);
  FSiteType := TXcomNodeReader.ReadString(ANode, 'siteType', FSiteType);
  // only a full replacement of the racial distribution is allowed
  LWeights := TXcomNodeReader.Field(ANode, 'raceWeights');
  if LWeights.IsDefined then
    ReadRaces(LWeights);
end;

function TXcomRuleAlienMission.GenerateRace(AMonthsPassed: Cardinal; const ARandom: IXcomRandom): string;
var
  LIndex: Integer;
begin
  LIndex := FRaceMonths.Count - 1;
  while (LIndex >= 0) and (AMonthsPassed < FRaceMonths[LIndex]) do
    Dec(LIndex);
  if LIndex < 0 then
    Exit('');
  Result := FRaceOptions[LIndex].Choose(ARandom);
end;

function TXcomRuleAlienMission.GetWeight(AMonthsPassed: Cardinal): Integer;
var
  LIndex: Integer;
begin
  if FWeightMonths.Count = 0 then
    Exit(1);
  Result := 0;
  for LIndex := 0 to FWeightMonths.Count - 1 do
  begin
    if FWeightMonths[LIndex] > AMonthsPassed then
      Break;
    Result := FWeightValues[LIndex];
  end;
end;

function TXcomRuleAlienMission.WaveCount: Integer;
begin
  Result := Length(FWaves);
end;

function TXcomRuleAlienMission.RaceMonthCount: Integer;
begin
  Result := FRaceMonths.Count;
end;

function TXcomRuleAlienMission.RaceMonth(AIndex: Integer): Cardinal;
begin
  Result := FRaceMonths[AIndex];
end;

function TXcomRuleAlienMission.RaceOptions(AIndex: Integer): TXcomWeightedOptions;
begin
  Result := FRaceOptions[AIndex];
end;

function TXcomRuleAlienMission.WeightMonthCount: Integer;
begin
  Result := FWeightMonths.Count;
end;

function TXcomRuleAlienMission.WeightMonth(AIndex: Integer): Cardinal;
begin
  Result := FWeightMonths[AIndex];
end;

function TXcomRuleAlienMission.WeightValue(AIndex: Integer): Integer;
begin
  Result := FWeightValues[AIndex];
end;

end.
