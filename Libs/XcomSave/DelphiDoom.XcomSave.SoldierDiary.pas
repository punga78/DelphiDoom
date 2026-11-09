{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the diary of a soldier (SoldierDiary)  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.SoldierDiary;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.RuleCommendations, DelphiDoom.XcomSave.NodeWriter,
  DelphiDoom.XcomSave.SoldierCommendation, DelphiDoom.XcomSave.BattleUnitKills;

type
  /// <summary>
  ///   What a soldier did: commendations, kills, missions and the counters of the statistics (SoldierDiary).
  ///   Only the data, loading and saving are ported: updateDiary and manageCommendations (the awarding of
  ///   medals from the statistics of a battle) are not
  /// </summary>
  TXcomSoldierDiary = class
  public
    const
      /// <summary>The counters in the order that save() writes them; bestSoldier and globeTrotter are flags</summary>
      COUNTER_KEYS: array[0..32] of string = ('daysWoundedTotal', 'totalShotByFriendlyCounter',
        'totalShotFriendlyCounter', 'loneSurvivorTotal', 'monthsService', 'unconciousTotal', 'shotAtCounterTotal',
        'hitCounterTotal', 'ironManTotal', 'longDistanceHitCounterTotal', 'lowAccuracyHitCounterTotal',
        'shotsFiredCounterTotal', 'shotsLandedCounterTotal', 'shotAtCounter10in1Mission', 'hitCounter5in1Mission',
        'timesWoundedTotal', 'allAliensKilledTotal', 'allAliensStunnedTotal', 'woundsHealedTotal', 'allUFOs',
        'allMissionTypes', 'statGainTotal', 'revivedUnitTotal', 'revivedSoldierTotal', 'revivedHostileTotal',
        'revivedNeutralTotal', 'wholeMedikitTotal', 'braveryGainTotal', 'bestOfRank', 'bestSoldier',
        'martyrKillsTotal', 'postMortemKills', 'globeTrotter');
  strict private
    FCommendations: TObjectList<TXcomSoldierCommendation>;
    FKillList: TObjectList<TXcomBattleUnitKills>;
    FMissionIdList: TArray<Integer>;
    FCounters: array[0..32] of Integer;
    // slaveKillsTotal is the last one saved and the first of the rest
    FSlaveKillsTotal: Integer;
    class function IsFlag(AIndex: Integer): Boolean; static;
    class function IndexOfKey(const AKey: string): Integer; static;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   load: a commendation whose type the ruleset does not know is dropped (obsolete); AKnown tells which
    ///   types exist
    /// </summary>
    procedure Load(const ANode: IYamlNode; const ACommendationRules: TXcomStringMap<TXcomRuleCommendations>);
    function Save: IYamlNode;
    /// <summary>A counter by its key in the file (an unknown key is EXcomModException)</summary>
    function Counter(const AKey: string): Integer;
    procedure SetCounter(const AKey: string; AValue: Integer);
    property Commendations: TObjectList<TXcomSoldierCommendation> read FCommendations;
    property KillList: TObjectList<TXcomBattleUnitKills> read FKillList;
    property MissionIdList: TArray<Integer> read FMissionIdList write FMissionIdList;
    property SlaveKillsTotal: Integer read FSlaveKillsTotal write FSlaveKillsTotal;
    /// <summary>getMonthsService</summary>
    function MonthsService: Integer;
    /// <summary>addMonthlyService</summary>
    procedure AddMonthlyService;
    /// <summary>getMissionTotal: the number of missions in the list</summary>
    function MissionTotal: Integer;
    /// <summary>awardBestOfRank / awardBestOverall / awardPostMortemKill / awardOriginalEightCommendation</summary>
    procedure AwardBestOfRank(AScore: Integer);
    procedure AwardBestOverall(AScore: Integer);
    procedure AwardPostMortemKill(AKills: Integer);
    procedure AwardOriginalEightCommendation;
  end;

implementation

{ TXcomSoldierDiary }

constructor TXcomSoldierDiary.Create;
begin
  inherited Create;
  FCommendations := TObjectList<TXcomSoldierCommendation>.Create(True);
  FKillList := TObjectList<TXcomBattleUnitKills>.Create(True);
end;

destructor TXcomSoldierDiary.Destroy;
begin
  FKillList.Free;
  FCommendations.Free;
  inherited Destroy;
end;

class function TXcomSoldierDiary.IsFlag(AIndex: Integer): Boolean;
begin
  Result := (COUNTER_KEYS[AIndex] = 'bestSoldier') or (COUNTER_KEYS[AIndex] = 'globeTrotter');
end;

class function TXcomSoldierDiary.IndexOfKey(const AKey: string): Integer;
begin
  for Result := 0 to High(COUNTER_KEYS) do
    if COUNTER_KEYS[Result] = AKey then
      Exit;
  raise EXcomModException.CreateFmt('Xcom: unknown diary counter %s', [AKey]);
end;

function TXcomSoldierDiary.Counter(const AKey: string): Integer;
begin
  if AKey = 'slaveKillsTotal' then
    Exit(FSlaveKillsTotal);
  Result := FCounters[IndexOfKey(AKey)];
end;

procedure TXcomSoldierDiary.SetCounter(const AKey: string; AValue: Integer);
begin
  if AKey = 'slaveKillsTotal' then
    FSlaveKillsTotal := AValue
  else
    FCounters[IndexOfKey(AKey)] := AValue;
end;

procedure TXcomSoldierDiary.Load(const ANode: IYamlNode;
  const ACommendationRules: TXcomStringMap<TXcomRuleCommendations>);
var
  LField, LItem: IYamlNode;
  LCommendation: TXcomSoldierCommendation;
  LIndex: Integer;
begin
  LField := TXcomNodeReader.Field(ANode, 'commendations');
  if LField.IsDefined then
    for LItem in LField.Items do
    begin
      LCommendation := TXcomSoldierCommendation.Create(LItem);
      // an obsolete commendation is ignored
      if ACommendationRules.ContainsKey(LCommendation.CommendationType) then
        FCommendations.Add(LCommendation)
      else
        LCommendation.Free;
    end;
  LField := TXcomNodeReader.Field(ANode, 'killList');
  if LField.IsDefined then
    for LItem in LField.Items do
      FKillList.Add(TXcomBattleUnitKills.Create(LItem));
  FMissionIdList := TXcomNodeReader.ReadIntegers(ANode, 'missionIdList', FMissionIdList);
  for LIndex := 0 to High(COUNTER_KEYS) do
    if IsFlag(LIndex) then
      FCounters[LIndex] := Ord(TXcomNodeReader.ReadBoolean(ANode, COUNTER_KEYS[LIndex], FCounters[LIndex] <> 0))
    else
      FCounters[LIndex] := TXcomNodeReader.ReadInteger(ANode, COUNTER_KEYS[LIndex], FCounters[LIndex]);
  FSlaveKillsTotal := TXcomNodeReader.ReadInteger(ANode, 'slaveKillsTotal', FSlaveKillsTotal);
end;

function TXcomSoldierDiary.Save: IYamlNode;
var
  LIndex: Integer;
  LItem: TXcomSoldierCommendation;
  LKill: TXcomBattleUnitKills;
begin
  Result := TXcomNodeWriter.NewMap;
  for LItem in FCommendations do
    TXcomNodeWriter.PushBack(Result, 'commendations', LItem.Save);
  for LKill in FKillList do
    TXcomNodeWriter.PushBack(Result, 'killList', LKill.Save);
  if Length(FMissionIdList) > 0 then
    TXcomNodeWriter.SetIntegers(Result, 'missionIdList', FMissionIdList);
  for LIndex := 0 to High(COUNTER_KEYS) do
    if FCounters[LIndex] <> 0 then
    begin
      if IsFlag(LIndex) then
        TXcomNodeWriter.SetBoolean(Result, COUNTER_KEYS[LIndex], True)
      else
        TXcomNodeWriter.SetInteger(Result, COUNTER_KEYS[LIndex], FCounters[LIndex]);
    end;
  if FSlaveKillsTotal <> 0 then
    TXcomNodeWriter.SetInteger(Result, 'slaveKillsTotal', FSlaveKillsTotal);
end;

function TXcomSoldierDiary.MonthsService: Integer;
begin
  Result := Counter('monthsService');
end;

procedure TXcomSoldierDiary.AddMonthlyService;
begin
  SetCounter('monthsService', MonthsService + 1);
end;

function TXcomSoldierDiary.MissionTotal: Integer;
begin
  Result := Length(FMissionIdList);
end;

procedure TXcomSoldierDiary.AwardBestOfRank(AScore: Integer);
begin
  SetCounter('bestOfRank', AScore);
end;

procedure TXcomSoldierDiary.AwardBestOverall(AScore: Integer);
begin
  // _bestSoldier is a bool: any score but 0 is true
  SetCounter('bestSoldier', Ord(AScore <> 0));
end;

procedure TXcomSoldierDiary.AwardPostMortemKill(AKills: Integer);
begin
  SetCounter('postMortemKills', AKills);
end;

procedure TXcomSoldierDiary.AwardOriginalEightCommendation;
begin
  FCommendations.Add(TXcomSoldierCommendation.Create('STR_MEDAL_ORIGINAL8_NAME', 'NoNoun'));
end;

end.
