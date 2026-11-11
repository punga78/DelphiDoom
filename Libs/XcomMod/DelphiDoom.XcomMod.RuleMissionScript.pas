{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a mission script (RuleMissionScript)      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleMissionScript;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.WeightedOptions, DelphiDoom.XcomMod.Random;

type
  /// <summary>
  ///   A rule that says when and where the aliens start a mission: the months it runs, the odds, the missions,
  ///   races and regions it picks from by month (RuleMissionScript). It owns the weights. The months of the
  ///   weights are 32 bit (size_t of the Win32 build); a key that is not a number is month 0
  /// </summary>
  TXcomRuleMissionScript = class
  strict private
    FType: string;
    FVarName: string;
    FFirstMonth: Integer;
    FLastMonth: Integer;
    FLabel: Integer;
    FExecutionOdds: Integer;
    FTargetBaseOdds: Integer;
    FMinDifficulty: Integer;
    FMaxRuns: Integer;
    FAvoidRepeats: Integer;
    FDelay: Integer;
    FConditionals: TArray<Integer>;
    FRegionMonths: TList<Cardinal>;
    FRegionWeights: TObjectList<TXcomWeightedOptions>;
    FMissionMonths: TList<Cardinal>;
    FMissionWeights: TObjectList<TXcomWeightedOptions>;
    FRaceMonths: TList<Cardinal>;
    FRaceWeights: TObjectList<TXcomWeightedOptions>;
    FResearchTriggers: TXcomStringMap<Boolean>;
    FUseTable: Boolean;
    FSiteType: Boolean;
    class procedure AppendWeights(const ANode: IYamlNode; AMonths: TList<Cardinal>;
      AWeights: TObjectList<TXcomWeightedOptions>); static;
    procedure ReadResearchTriggers(const ANode: IYamlNode);
  public
    const
      /// <summary>GenerationType</summary>
      GEN_REGION = 0;
      GEN_MISSION = 1;
      GEN_RACE = 2;
    constructor Create(const AType: string);
    destructor Destroy; override;
    /// <summary>
    ///   Loads the script from a YAML node (the weights are added to the ones there are). A script with maxRuns
    ///   or avoidRepeats and no varName is EXcomModException
    /// </summary>
    procedure Load(const ANode: IYamlNode);
    /// <summary>getAllMissionTypes: every mission of every month, without repeats, in the order of the names</summary>
    function AllMissionTypes: TArray<string>;
    /// <summary>
    ///   getMissionTypes: the missions of the last set of weights that starts at or before the month (the
    ///   first set if the month is earlier than all). A script with no mission weights is undefined in the C++:
    ///   EXcomModException
    /// </summary>
    function GetMissionTypes(AMonth: Integer): TArray<string>;
    /// <summary>getRegions: as GetMissionTypes for the weights of the regions</summary>
    function GetRegions(AMonth: Integer): TArray<string>;
    /// <summary>
    ///   generate: picks a region, mission or race (AType: 0 region, 1 mission, 2 race: GenerationType) from the
    ///   last set of weights at or before the month. No set at or before the month (the C++ reads past the
    ///   start of the vector) or no set at all is EXcomModException
    /// </summary>
    function Generate(AMonthsPassed: Cardinal; AType: Integer; const ARandom: IXcomRandom): string;
    function HasMissionWeights: Boolean;
    function HasRaceWeights: Boolean;
    function HasRegionWeights: Boolean;
    property ScriptType: string read FType;
    property VarName: string read FVarName;
    property FirstMonth: Integer read FFirstMonth;
    property LastMonth: Integer read FLastMonth;
    property ScriptLabel: Integer read FLabel;
    property ExecutionOdds: Integer read FExecutionOdds;
    property TargetBaseOdds: Integer read FTargetBaseOdds;
    property MinDifficulty: Integer read FMinDifficulty;
    property MaxRuns: Integer read FMaxRuns;
    property RepeatAvoidance: Integer read FAvoidRepeats;
    property Delay: Integer read FDelay;
    property Conditionals: TArray<Integer> read FConditionals;
    property RegionMonths: TList<Cardinal> read FRegionMonths;
    property RegionWeights: TObjectList<TXcomWeightedOptions> read FRegionWeights;
    property MissionMonths: TList<Cardinal> read FMissionMonths;
    property MissionWeights: TObjectList<TXcomWeightedOptions> read FMissionWeights;
    property RaceMonths: TList<Cardinal> read FRaceMonths;
    property RaceWeights: TObjectList<TXcomWeightedOptions> read FRaceWeights;
    property ResearchTriggers: TXcomStringMap<Boolean> read FResearchTriggers;
    property UseTable: Boolean read FUseTable;
    /// <summary>getSiteType / setSiteType: whether the missions of the script are terror sites (set by the ruleset)</summary>
    property SiteType: Boolean read FSiteType write FSiteType;
  end;

implementation

uses
  System.Generics.Defaults, DelphiDoom.Yaml.Types;

const
  SNoWeights = 'Xcom: mission script has no weights for the month';

resourcestring
  SScriptNoVarName = 'Error in mission script: %s: no varName provided for a script with maxRuns or repeatAvoidance.';

{ TXcomRuleMissionScript }

constructor TXcomRuleMissionScript.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FLastMonth := -1;
  FExecutionOdds := 100;
  FMaxRuns := -1;
  FUseTable := True;
  FRegionMonths := TList<Cardinal>.Create;
  FRegionWeights := TObjectList<TXcomWeightedOptions>.Create(True);
  FMissionMonths := TList<Cardinal>.Create;
  FMissionWeights := TObjectList<TXcomWeightedOptions>.Create(True);
  FRaceMonths := TList<Cardinal>.Create;
  FRaceWeights := TObjectList<TXcomWeightedOptions>.Create(True);
  FResearchTriggers := TXcomStringMap<Boolean>.Create;
end;

destructor TXcomRuleMissionScript.Destroy;
begin
  FResearchTriggers.Free;
  FRaceWeights.Free;
  FRaceMonths.Free;
  FMissionWeights.Free;
  FMissionMonths.Free;
  FRegionWeights.Free;
  FRegionMonths.Free;
  inherited Destroy;
end;

class procedure TXcomRuleMissionScript.AppendWeights(const ANode: IYamlNode; AMonths: TList<Cardinal>;
  AWeights: TObjectList<TXcomWeightedOptions>);
var
  LPair: TYamlPair;
  LOptions: TXcomWeightedOptions;
  LMonth: Cardinal;
begin
  for LPair in ANode.Pairs do
  begin
    LOptions := TXcomWeightedOptions.Create;
    try
      LOptions.Load(LPair.Value);
    except
      LOptions.Free;
      raise;
    end;
    // nn->first.as<size_t>(0)
    LMonth := LPair.Key.AsCardinal(0);
    AWeights.Add(LOptions);
    AMonths.Add(LMonth);
  end;
end;

procedure TXcomRuleMissionScript.ReadResearchTriggers(const ANode: IYamlNode);
var
  LField: IYamlNode;
  LPair: TYamlPair;
  LNew: TXcomStringMap<Boolean>;
begin
  LField := TXcomNodeReader.Field(ANode, 'researchTriggers');
  if not LField.IsDefined or not LField.IsMap then
    Exit;
  // as<std::map<std::string, bool>>(fallback): a new map that replaces the old one
  LNew := TXcomStringMap<Boolean>.Create;
  try
    for LPair in LField.Pairs do
      LNew.SetValue(TXcomNodeReader.TextOf(LPair.Key), LPair.Value.AsBoolean);
  except
    LNew.Free;
    raise;
  end;
  FResearchTriggers.Free;
  FResearchTriggers := LNew;
end;

procedure TXcomRuleMissionScript.Load(const ANode: IYamlNode);
var
  LField: IYamlNode;
begin
  FVarName := TXcomNodeReader.ReadString(ANode, 'varName', FVarName);
  FFirstMonth := TXcomNodeReader.ReadInteger(ANode, 'firstMonth', FFirstMonth);
  FLastMonth := TXcomNodeReader.ReadInteger(ANode, 'lastMonth', FLastMonth);
  FLabel := Integer(TXcomNodeReader.ReadSize(ANode, 'label', Cardinal(FLabel)));
  FExecutionOdds := TXcomNodeReader.ReadInteger(ANode, 'executionOdds', FExecutionOdds);
  FTargetBaseOdds := TXcomNodeReader.ReadInteger(ANode, 'targetBaseOdds', FTargetBaseOdds);
  FMinDifficulty := TXcomNodeReader.ReadInteger(ANode, 'minDifficulty', FMinDifficulty);
  FMaxRuns := TXcomNodeReader.ReadInteger(ANode, 'maxRuns', FMaxRuns);
  FAvoidRepeats := TXcomNodeReader.ReadInteger(ANode, 'avoidRepeats', FAvoidRepeats);
  FDelay := TXcomNodeReader.ReadInteger(ANode, 'startDelay', FDelay);
  FConditionals := TXcomNodeReader.ReadIntegers(ANode, 'conditionals', FConditionals);
  LField := TXcomNodeReader.Field(ANode, 'missionWeights');
  if LField.IsDefined then
    AppendWeights(LField, FMissionMonths, FMissionWeights);
  LField := TXcomNodeReader.Field(ANode, 'raceWeights');
  if LField.IsDefined then
    AppendWeights(LField, FRaceMonths, FRaceWeights);
  LField := TXcomNodeReader.Field(ANode, 'regionWeights');
  if LField.IsDefined then
    AppendWeights(LField, FRegionMonths, FRegionWeights);
  ReadResearchTriggers(ANode);
  FUseTable := TXcomNodeReader.ReadBoolean(ANode, 'useTable', FUseTable);
  if (FVarName = '') and ((FMaxRuns > 0) or (FAvoidRepeats > 0)) then
    raise EXcomModException.CreateFmt(SScriptNoVarName, [FType]);
end;

function TXcomRuleMissionScript.AllMissionTypes: TArray<string>;
var
  LTypes: TList<string>;
  LIndex: Integer;
  LName: string;
begin
  LTypes := TList<string>.Create;
  try
    for LIndex := 0 to FMissionWeights.Count - 1 do
      for LName in FMissionWeights[LIndex].Names do
        if not LTypes.Contains(LName) then
          LTypes.Add(LName);
    LTypes.Sort(TComparer<string>.Construct(
      function(const ALeft, ARight: string): Integer begin Result := XcomCompareUtf8(ALeft, ARight); end));
    Result := LTypes.ToArray;
  finally
    LTypes.Free;
  end;
end;

function TXcomRuleMissionScript.GetMissionTypes(AMonth: Integer): TArray<string>;
var
  LIndex: Integer;
begin
  if FMissionWeights.Count = 0 then
    raise EXcomModException.Create(SNoWeights);
  LIndex := FMissionWeights.Count - 1;
  // while (month < (int)first): the walk stops at the first set if the month is earlier than all
  while (LIndex > 0) and (AMonth < Integer(FMissionMonths[LIndex])) do
    Dec(LIndex);
  Result := FMissionWeights[LIndex].Names;
end;

function TXcomRuleMissionScript.GetRegions(AMonth: Integer): TArray<string>;
var
  LIndex: Integer;
begin
  if FRegionWeights.Count = 0 then
    raise EXcomModException.Create(SNoWeights);
  LIndex := FRegionWeights.Count - 1;
  while (LIndex > 0) and (AMonth < Integer(FRegionMonths[LIndex])) do
    Dec(LIndex);
  Result := FRegionWeights[LIndex].Names;
end;

function TXcomRuleMissionScript.Generate(AMonthsPassed: Cardinal; AType: Integer;
  const ARandom: IXcomRandom): string;
var
  LMonths: TList<Cardinal>;
  LWeights: TObjectList<TXcomWeightedOptions>;
  LIndex: Integer;
begin
  case AType of
    GEN_RACE:
      begin
        LMonths := FRaceMonths;
        LWeights := FRaceWeights;
      end;
    GEN_REGION:
      begin
        LMonths := FRegionMonths;
        LWeights := FRegionWeights;
      end;
  else
    LMonths := FMissionMonths;
    LWeights := FMissionWeights;
  end;
  if LWeights.Count = 0 then
    raise EXcomModException.Create(SNoWeights);
  LIndex := LWeights.Count - 1;
  while AMonthsPassed < LMonths[LIndex] do
  begin
    Dec(LIndex);
    if LIndex < 0 then
      raise EXcomModException.Create(SNoWeights);
  end;
  Result := LWeights[LIndex].Choose(ARandom);
end;

function TXcomRuleMissionScript.HasMissionWeights: Boolean;
begin
  Result := FMissionWeights.Count > 0;
end;

function TXcomRuleMissionScript.HasRaceWeights: Boolean;
begin
  Result := FRaceWeights.Count > 0;
end;

function TXcomRuleMissionScript.HasRegionWeights: Boolean;
begin
  Result := FRegionWeights.Count > 0;
end;

end.
