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
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.XcomMod.UnitStats, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.RuleCommendations, DelphiDoom.XcomSave.NodeWriter,
  DelphiDoom.XcomSave.SoldierCommendation, DelphiDoom.XcomSave.BattleUnitKills, DelphiDoom.XcomSave.UnitEnums,
  DelphiDoom.XcomSave.MissionStatistics, DelphiDoom.XcomSave.BattleUnitStatistics,
  DelphiDoom.XcomSave.DiaryRules.Intf, DelphiDoom.XcomMod.RuleItem;

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
    FKIA: Integer;
    FMIA: Integer;
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
    /// <summary>awardCommendation: a new level of the commendation with the noun, or a new commendation</summary>
    procedure AwardCommendation(const AType, ANoun: string);
    /// <summary>
    ///   updateDiary: moves the kills of the unit to the list of the diary and adds its counters. The missions
    ///   are those of the saved game; the last one is the mission just fought. Nothing happens without missions
    /// </summary>
    procedure UpdateDiary(const AUnitStatistics: TXcomBattleUnitStatistics;
      const AMissions: TObjectList<TXcomMissionStatistics>; const ARules: IXcomDiaryRules);
    /// <summary>The number of missions of this diary that satisfy the condition (getXxxMissionTotal)</summary>
    function CountMissions(const AMissions: TObjectList<TXcomMissionStatistics>;
      const APredicate: TFunc<TXcomMissionStatistics, Boolean>): Integer;
    /// <summary>getRegionTotal/getCountryTotal/getTypeTotal/getUFOTotal: missions by a name (the caller frees the map)</summary>
    function MissionTally(const AMissions: TObjectList<TXcomMissionStatistics>;
      const AKeyOf: TFunc<TXcomMissionStatistics, string>): TXcomStringMap<Integer>;
    /// <summary>getAlienRankTotal/getAlienRaceTotal/getWeaponTotal/getWeaponAmmoTotal (the caller frees the map)</summary>
    function KillTally(const AKeyOf: TFunc<TXcomBattleUnitKills, string>; AHostileOnly: Boolean)
      : TXcomStringMap<Integer>;
    function KillTotal: Integer;
    function StunTotal: Integer;
    function PanickTotal: Integer;
    function ControlTotal: Integer;
    function WinTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
    function ScoreTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
    function ValiantCruxTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
    function LootValueTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
    function TerrorMissionTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
    function NightMissionTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
    function NightTerrorMissionTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
    function BaseDefenseMissionTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
    function AlienBaseAssaultTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
    function ImportantMissionTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
    function TrapKillTotal(const ARules: IXcomDiaryRules): Integer;
    function ReactionFireKillTotal(const ARules: IXcomDiaryRules): Integer;
    function DaysWoundedTotal: Integer;
    function ShotsFiredTotal: Integer;
    function ShotsLandedTotal: Integer;
    /// <summary>getAccuracy: percent, 0 without shots</summary>
    function Accuracy: Integer;
    /// <summary>_KIA and _MIA: counted by updateDiary, not saved (the C++ loses them too)</summary>
    property KIA: Integer read FKIA write FKIA;
    property MIA: Integer read FMIA write FMIA;
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

procedure TXcomSoldierDiary.AwardCommendation(const AType, ANoun: string);
var
  LItem: TXcomSoldierCommendation;
begin
  for LItem in FCommendations do
    if (LItem.CommendationType = AType) and (LItem.Noun = ANoun) then
    begin
      LItem.AddDecoration;
      Exit;
    end;
  FCommendations.Add(TXcomSoldierCommendation.Create(AType, ANoun));
end;

function TXcomSoldierDiary.CountMissions(const AMissions: TObjectList<TXcomMissionStatistics>;
  const APredicate: TFunc<TXcomMissionStatistics, Boolean>): Integer;
var
  LMission: TXcomMissionStatistics;
  LId: Integer;
begin
  Result := 0;
  for LMission in AMissions do
    for LId in FMissionIdList do
      if (LId = LMission.Id) and APredicate(LMission) then
        Inc(Result);
end;

function TXcomSoldierDiary.MissionTally(const AMissions: TObjectList<TXcomMissionStatistics>;
  const AKeyOf: TFunc<TXcomMissionStatistics, string>): TXcomStringMap<Integer>;
var
  LMission: TXcomMissionStatistics;
  LId, LCurrent: Integer;
  LKey: string;
begin
  Result := TXcomStringMap<Integer>.Create;
  for LMission in AMissions do
    for LId in FMissionIdList do
      if LId = LMission.Id then
      begin
        LKey := AKeyOf(LMission);
        if not Result.TryGetValue(LKey, LCurrent) then
          LCurrent := 0;
        Result.SetValue(LKey, LCurrent + 1);
      end;
end;

function TXcomSoldierDiary.KillTally(const AKeyOf: TFunc<TXcomBattleUnitKills, string>; AHostileOnly: Boolean)
  : TXcomStringMap<Integer>;
var
  LKill: TXcomBattleUnitKills;
  LCurrent: Integer;
  LKey: string;
begin
  Result := TXcomStringMap<Integer>.Create;
  for LKill in FKillList do
    if (not AHostileOnly) or (LKill.Faction = XcomFactionHostile) then
    begin
      LKey := AKeyOf(LKill);
      if not Result.TryGetValue(LKey, LCurrent) then
        LCurrent := 0;
      Result.SetValue(LKey, LCurrent + 1);
    end;
end;

function TXcomSoldierDiary.KillTotal: Integer;
var
  LKill: TXcomBattleUnitKills;
begin
  Result := 0;
  for LKill in FKillList do
    if (LKill.Status = XcomStatusDead) and (LKill.Faction = XcomFactionHostile) then
      Inc(Result);
end;

function TXcomSoldierDiary.StunTotal: Integer;
var
  LKill: TXcomBattleUnitKills;
begin
  Result := 0;
  for LKill in FKillList do
    if (LKill.Status = XcomStatusUnconscious) and (LKill.Faction = XcomFactionHostile) then
      Inc(Result);
end;

function TXcomSoldierDiary.PanickTotal: Integer;
var
  LKill: TXcomBattleUnitKills;
begin
  Result := 0;
  for LKill in FKillList do
    if (LKill.Status = XcomStatusPanicking) and (LKill.Faction = XcomFactionHostile) then
      Inc(Result);
end;

function TXcomSoldierDiary.ControlTotal: Integer;
var
  LKill: TXcomBattleUnitKills;
begin
  Result := 0;
  for LKill in FKillList do
    if (LKill.Status = XcomStatusTurning) and (LKill.Faction = XcomFactionHostile) then
      Inc(Result);
end;

function TXcomSoldierDiary.WinTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
begin
  Result := CountMissions(AMissions,
    function(AMission: TXcomMissionStatistics): Boolean
    begin
      Result := AMission.Success;
    end);
end;

function TXcomSoldierDiary.ScoreTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
var
  LMission: TXcomMissionStatistics;
  LId: Integer;
begin
  Result := 0;
  for LMission in AMissions do
    for LId in FMissionIdList do
      if LId = LMission.Id then
        Inc(Result, LMission.Score);
end;

function TXcomSoldierDiary.ValiantCruxTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
begin
  Result := CountMissions(AMissions,
    function(AMission: TXcomMissionStatistics): Boolean
    begin
      Result := AMission.ValiantCrux;
    end);
end;

function TXcomSoldierDiary.LootValueTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
var
  LMission: TXcomMissionStatistics;
  LId: Integer;
begin
  Result := 0;
  for LMission in AMissions do
    for LId in FMissionIdList do
      if LId = LMission.Id then
        Inc(Result, LMission.LootValue);
end;

function TXcomSoldierDiary.TerrorMissionTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
begin
  // not a UFO, not the base, not the alien base or colony
  Result := CountMissions(AMissions,
    function(AMission: TXcomMissionStatistics): Boolean
    begin
      Result := AMission.Success and not AMission.IsBaseDefense and not AMission.IsUfoMission
        and not AMission.IsAlienBase;
    end);
end;

function TXcomSoldierDiary.NightMissionTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
begin
  Result := CountMissions(AMissions,
    function(AMission: TXcomMissionStatistics): Boolean
    begin
      Result := AMission.Success and AMission.IsDarkness and not AMission.IsBaseDefense
        and not AMission.IsAlienBase;
    end);
end;

function TXcomSoldierDiary.NightTerrorMissionTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
begin
  Result := CountMissions(AMissions,
    function(AMission: TXcomMissionStatistics): Boolean
    begin
      Result := AMission.Success and AMission.IsDarkness and not AMission.IsBaseDefense
        and not AMission.IsUfoMission and not AMission.IsAlienBase;
    end);
end;

function TXcomSoldierDiary.BaseDefenseMissionTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
begin
  Result := CountMissions(AMissions,
    function(AMission: TXcomMissionStatistics): Boolean
    begin
      Result := AMission.Success and AMission.IsBaseDefense;
    end);
end;

function TXcomSoldierDiary.AlienBaseAssaultTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
begin
  Result := CountMissions(AMissions,
    function(AMission: TXcomMissionStatistics): Boolean
    begin
      Result := AMission.Success and AMission.IsAlienBase;
    end);
end;

function TXcomSoldierDiary.ImportantMissionTotal(const AMissions: TObjectList<TXcomMissionStatistics>): Integer;
begin
  Result := CountMissions(AMissions,
    function(AMission: TXcomMissionStatistics): Boolean
    begin
      Result := AMission.Success and (AMission.MissionType <> 'STR_UFO_CRASH_RECOVERY');
    end);
end;

function TXcomSoldierDiary.TrapKillTotal(const ARules: IXcomDiaryRules): Integer;
var
  LKill: TXcomBattleUnitKills;
  LBattle, LDamage: Integer;
begin
  Result := 0;
  for LKill in FKillList do
    if LKill.HostileTurn and (not ARules.FindItem(LKill.Weapon, LBattle, LDamage)
      or (LBattle = TXcomRuleItem.BT_GRENADE) or (LBattle = TXcomRuleItem.BT_PROXIMITYGRENADE)) then
      Inc(Result);
end;

function TXcomSoldierDiary.ReactionFireKillTotal(const ARules: IXcomDiaryRules): Integer;
var
  LKill: TXcomBattleUnitKills;
  LBattle, LDamage: Integer;
begin
  Result := 0;
  for LKill in FKillList do
    if LKill.HostileTurn and ARules.FindItem(LKill.Weapon, LBattle, LDamage)
      and (LBattle <> TXcomRuleItem.BT_GRENADE) and (LBattle <> TXcomRuleItem.BT_PROXIMITYGRENADE) then
      Inc(Result);
end;

function TXcomSoldierDiary.DaysWoundedTotal: Integer;
begin
  Result := Counter('daysWoundedTotal');
end;

function TXcomSoldierDiary.ShotsFiredTotal: Integer;
begin
  Result := Counter('shotsFiredCounterTotal');
end;

function TXcomSoldierDiary.ShotsLandedTotal: Integer;
begin
  Result := Counter('shotsLandedCounterTotal');
end;

function TXcomSoldierDiary.Accuracy: Integer;
begin
  if ShotsFiredTotal <> 0 then
    Result := 100 * ShotsLandedTotal div ShotsFiredTotal
  else
    Result := 0;
end;

procedure TXcomSoldierDiary.UpdateDiary(const AUnitStatistics: TXcomBattleUnitStatistics;
  const AMissions: TObjectList<TXcomMissionStatistics>; const ARules: IXcomDiaryRules);
var
  LMission: TXcomMissionStatistics;
  LKill: TXcomBattleUnitKills;
  LDelta: TXcomUnitStats;
  LTotal: Integer;
  LTally: TXcomStringMap<Integer>;
begin
  if AMissions.Count = 0 then
    Exit;
  LMission := AMissions.Last;
  while AUnitStatistics.Kills.Count > 0 do
  begin
    LKill := AUnitStatistics.Kills.Extract(AUnitStatistics.Kills.First);
    LKill.MakeTurnUnique;
    FKillList.Add(LKill);
  end;
  if LMission.Success then
  begin
    if AUnitStatistics.LoneSurvivor then
      SetCounter('loneSurvivorTotal', Counter('loneSurvivorTotal') + 1);
    if AUnitStatistics.IronMan then
      SetCounter('ironManTotal', Counter('ironManTotal') + 1);
    if AUnitStatistics.NikeCross then
      SetCounter('allAliensKilledTotal', Counter('allAliensKilledTotal') + 1);
    if AUnitStatistics.MercyCross then
      SetCounter('allAliensStunnedTotal', Counter('allAliensStunnedTotal') + 1);
  end;
  SetCounter('daysWoundedTotal', Counter('daysWoundedTotal') + AUnitStatistics.DaysWounded);
  if AUnitStatistics.DaysWounded <> 0 then
    SetCounter('timesWoundedTotal', Counter('timesWoundedTotal') + 1);
  if AUnitStatistics.WasUnconscious then
    SetCounter('unconciousTotal', Counter('unconciousTotal') + 1);
  SetCounter('shotAtCounterTotal', Counter('shotAtCounterTotal') + AUnitStatistics.ShotAtCounter);
  SetCounter('shotAtCounter10in1Mission', Counter('shotAtCounter10in1Mission') + AUnitStatistics.ShotAtCounter div 10);
  SetCounter('hitCounterTotal', Counter('hitCounterTotal') + AUnitStatistics.HitCounter);
  SetCounter('hitCounter5in1Mission', Counter('hitCounter5in1Mission') + AUnitStatistics.HitCounter div 5);
  SetCounter('totalShotByFriendlyCounter', Counter('totalShotByFriendlyCounter') + AUnitStatistics.ShotByFriendlyCounter);
  SetCounter('totalShotFriendlyCounter', Counter('totalShotFriendlyCounter') + AUnitStatistics.ShotFriendlyCounter);
  SetCounter('longDistanceHitCounterTotal', Counter('longDistanceHitCounterTotal') + AUnitStatistics.LongDistanceHitCounter);
  SetCounter('lowAccuracyHitCounterTotal', Counter('lowAccuracyHitCounterTotal') + AUnitStatistics.LowAccuracyHitCounter);
  SetCounter('shotsFiredCounterTotal', Counter('shotsFiredCounterTotal') + AUnitStatistics.ShotsFiredCounter);
  SetCounter('shotsLandedCounterTotal', Counter('shotsLandedCounterTotal') + AUnitStatistics.ShotsLandedCounter);
  if AUnitStatistics.KIA then
    Inc(FKIA);
  if AUnitStatistics.MIA then
    Inc(FMIA);
  SetCounter('woundsHealedTotal', Counter('woundsHealedTotal') + AUnitStatistics.WoundsHealed);
  LTally := MissionTally(AMissions,
    function(AItem: TXcomMissionStatistics): string
    begin
      Result := AItem.Ufo;
    end);
  try
    if LTally.Count >= ARules.UfoCount then
      SetCounter('allUFOs', 1);
    LTotal := LTally.Count;
  finally
    LTally.Free;
  end;
  LTally := MissionTally(AMissions,
    function(AItem: TXcomMissionStatistics): string
    begin
      Result := AItem.MissionType;
    end);
  try
    if LTotal + LTally.Count = ARules.UfoCount + ARules.DeploymentCount - 2 then
      SetCounter('allMissionTypes', 1);
  finally
    LTally.Free;
  end;
  LTally := MissionTally(AMissions,
    function(AItem: TXcomMissionStatistics): string
    begin
      Result := AItem.Country;
    end);
  try
    if LTally.Count = ARules.CountryCount then
      SetCounter('globeTrotter', 1);
  finally
    LTally.Free;
  end;
  SetCounter('martyrKillsTotal', Counter('martyrKillsTotal') + AUnitStatistics.Martyr);
  FSlaveKillsTotal := FSlaveKillsTotal + AUnitStatistics.SlaveKills;
  // the gain of the stats is calculated again each time
  LDelta := AUnitStatistics.Delta;
  SetCounter('statGainTotal', LDelta.TimeUnits + LDelta.Stamina + LDelta.Health + LDelta.Bravery div 10
    + LDelta.Reactions + LDelta.Firing + LDelta.Throwing + LDelta.Strength + LDelta.PsiStrength + LDelta.Melee
    + LDelta.PsiSkill);
  SetCounter('braveryGainTotal', LDelta.Bravery);
  SetCounter('revivedUnitTotal', Counter('revivedUnitTotal') + AUnitStatistics.RevivedSoldier
    + AUnitStatistics.RevivedHostile + AUnitStatistics.RevivedNeutral);
  SetCounter('revivedSoldierTotal', Counter('revivedSoldierTotal') + AUnitStatistics.RevivedSoldier);
  SetCounter('revivedNeutralTotal', Counter('revivedNeutralTotal') + AUnitStatistics.RevivedNeutral);
  SetCounter('revivedHostileTotal', Counter('revivedHostileTotal') + AUnitStatistics.RevivedHostile);
  SetCounter('wholeMedikitTotal', Counter('wholeMedikitTotal') + Min(Min(AUnitStatistics.WoundsHealed,
    AUnitStatistics.AppliedStimulant), AUnitStatistics.AppliedPainKill));
  SetLength(FMissionIdList, Length(FMissionIdList) + 1);
  FMissionIdList[High(FMissionIdList)] := LMission.Id;
end;

end.
