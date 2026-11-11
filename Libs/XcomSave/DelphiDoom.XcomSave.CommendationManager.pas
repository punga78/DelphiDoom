{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the awarding of the medals of a        }
{  soldier (SoldierDiary::manageCommendations)                                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.CommendationManager;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.RuleCommendations,
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomSave.SoldierDiary, DelphiDoom.XcomSave.SoldierCommendation,
  DelphiDoom.XcomSave.BattleUnitKills, DelphiDoom.XcomSave.MissionStatistics, DelphiDoom.XcomSave.DiaryRules.Intf;

type
  /// <summary>
  ///   Awards the commendations that a soldier deserves from its diary. A commendation can be awarded more than
  ///   once in a call (the loop of the C++ looks at the same one again after an award), so a soldier can go up
  ///   several levels. The result is whether at least one was awarded
  /// </summary>
  TXcomCommendationManager = class
  strict private
    FDiary: TXcomSoldierDiary;
    FRules: IXcomDiaryRules;
    FMissions: TObjectList<TXcomMissionStatistics>;
    /// <summary>The value of a criterion that has no noun; false if the name is not one of them</summary>
    function NounlessValue(const AName: string; out AValue: Integer): Boolean;
    function NounlessFails(const AName: string; AThreshold: Integer): Boolean;
    function NounTally(const AName: string): TXcomStringMap<Integer>;
    function KillCriteriaMet(const ARule: TXcomRuleCommendations; const AName: string; AThreshold: Integer): Boolean;
    function KillMatches(const AKill: TXcomBattleUnitKills; const ACondition: TXcomKillCondition): Boolean;
  public
    constructor Create(const ADiary: TXcomSoldierDiary; const ARules: IXcomDiaryRules;
      const AMissions: TObjectList<TXcomMissionStatistics>);
    /// <summary>manageCommendations</summary>
    function Manage: Boolean;
  end;

implementation

const
  BATTLE_TYPES: array[0..12] of string = ('BT_NONE', 'BT_FIREARM', 'BT_AMMO', 'BT_MELEE', 'BT_GRENADE',
    'BT_PROXIMITYGRENADE', 'BT_MEDIKIT', 'BT_SCANNER', 'BT_MINDPROBE', 'BT_PSIAMP', 'BT_FLARE', 'BT_CORPSE',
    'BT_END');
  DAMAGE_TYPES: array[0..10] of string = ('DT_NONE', 'DT_AP', 'DT_IN', 'DT_HE', 'DT_LASER', 'DT_PLASMA', 'DT_STUN',
    'DT_MELEE', 'DT_ACID', 'DT_SMOKE', 'DT_END');
  NO_NOUN = 'noNoun';

{ TXcomCommendationManager }

constructor TXcomCommendationManager.Create(const ADiary: TXcomSoldierDiary; const ARules: IXcomDiaryRules;
  const AMissions: TObjectList<TXcomMissionStatistics>);
begin
  inherited Create;
  FDiary := ADiary;
  FRules := ARules;
  FMissions := AMissions;
end;

function TXcomCommendationManager.NounlessValue(const AName: string; out AValue: Integer): Boolean;
begin
  Result := True;
  if AName = 'totalKills' then AValue := FDiary.KillTotal
  else if AName = 'totalMissions' then AValue := FDiary.MissionTotal
  else if AName = 'totalWins' then AValue := FDiary.WinTotal(FMissions)
  else if AName = 'totalScore' then AValue := FDiary.ScoreTotal(FMissions)
  else if AName = 'totalStuns' then AValue := FDiary.StunTotal
  else if AName = 'totalDaysWounded' then AValue := FDiary.Counter('daysWoundedTotal')
  else if AName = 'totalBaseDefenseMissions' then AValue := FDiary.BaseDefenseMissionTotal(FMissions)
  else if AName = 'totalTerrorMissions' then AValue := FDiary.TerrorMissionTotal(FMissions)
  else if AName = 'totalNightMissions' then AValue := FDiary.NightMissionTotal(FMissions)
  else if AName = 'totalNightTerrorMissions' then AValue := FDiary.NightTerrorMissionTotal(FMissions)
  else if AName = 'totalMonthlyService' then AValue := FDiary.Counter('monthsService')
  else if AName = 'totalFellUnconcious' then AValue := FDiary.Counter('unconciousTotal')
  else if AName = 'totalShotAt10Times' then AValue := FDiary.Counter('shotAtCounter10in1Mission')
  else if AName = 'totalHit5Times' then AValue := FDiary.Counter('hitCounter5in1Mission')
  else if AName = 'totalFriendlyFired' then AValue := FDiary.Counter('totalShotByFriendlyCounter')
  else if AName = 'total_lone_survivor' then AValue := FDiary.Counter('loneSurvivorTotal')
  else if AName = 'totalIronMan' then AValue := FDiary.Counter('ironManTotal')
  else if AName = 'totalImportantMissions' then AValue := FDiary.ImportantMissionTotal(FMissions)
  else if AName = 'totalLongDistanceHits' then AValue := FDiary.Counter('longDistanceHitCounterTotal')
  else if AName = 'totalLowAccuracyHits' then AValue := FDiary.Counter('lowAccuracyHitCounterTotal')
  else if AName = 'totalReactionFire' then AValue := FDiary.ReactionFireKillTotal(FRules)
  else if AName = 'totalTimesWounded' then AValue := FDiary.Counter('timesWoundedTotal')
  else if AName = 'totalValientCrux' then AValue := FDiary.ValiantCruxTotal(FMissions)
  else if AName = 'isDead' then AValue := FDiary.KIA
  else if AName = 'totalTrapKills' then AValue := FDiary.TrapKillTotal(FRules)
  else if AName = 'totalAlienBaseAssaults' then AValue := FDiary.AlienBaseAssaultTotal(FMissions)
  else if AName = 'totalAllAliensKilled' then AValue := FDiary.Counter('allAliensKilledTotal')
  else if AName = 'totalAllAliensStunned' then AValue := FDiary.Counter('allAliensStunnedTotal')
  else if AName = 'totalWoundsHealed' then AValue := FDiary.Counter('woundsHealedTotal')
  else if AName = 'totalAllUFOs' then AValue := FDiary.Counter('allUFOs')
  else if AName = 'totalAllMissionTypes' then AValue := FDiary.Counter('allMissionTypes')
  else if AName = 'totalStatGain' then AValue := FDiary.Counter('statGainTotal')
  else if AName = 'totalRevives' then AValue := FDiary.Counter('revivedUnitTotal')
  else if AName = 'totalSoldierRevives' then AValue := FDiary.Counter('revivedSoldierTotal')
  else if AName = 'totalHostileRevives' then AValue := FDiary.Counter('revivedHostileTotal')
  else if AName = 'totalNeutralRevives' then AValue := FDiary.Counter('revivedNeutralTotal')
  else if AName = 'totalWholeMedikit' then AValue := FDiary.Counter('wholeMedikitTotal')
  else if AName = 'totalBraveryGain' then AValue := FDiary.Counter('braveryGainTotal')
  else if AName = 'bestOfRank' then AValue := FDiary.Counter('bestOfRank')
  else if AName = 'bestSoldier' then AValue := FDiary.Counter('bestSoldier')
  else if AName = 'isMIA' then AValue := FDiary.MIA
  else if AName = 'totalMartyrKills' then AValue := FDiary.Counter('martyrKillsTotal')
  else if AName = 'totalPostMortemKills' then AValue := FDiary.Counter('postMortemKills')
  else if AName = 'globeTrotter' then AValue := FDiary.Counter('globeTrotter')
  else if AName = 'totalSlaveKills' then AValue := FDiary.SlaveKillsTotal
  else
  begin
    AValue := 0;
    Result := False;
  end;
end;

function TXcomCommendationManager.NounlessFails(const AName: string; AThreshold: Integer): Boolean;
var
  LValue: Integer;
begin
  if not NounlessValue(AName, LValue) then
    Exit(False);
  // the comparisons of the kills and of the missions are unsigned in the C++
  if (AName = 'totalKills') or (AName = 'totalMissions') then
    Result := Cardinal(LValue) < Cardinal(AThreshold)
  else
    Result := LValue < AThreshold;
  if (AName = 'totalFriendlyFired') and ((FDiary.KIA <> 0) or (FDiary.MIA <> 0)) then
    Result := True;
end;

function TXcomCommendationManager.NounTally(const AName: string): TXcomStringMap<Integer>;
begin
  if AName = 'totalKillsWithAWeapon' then
    Result := FDiary.KillTally(
      function(AKill: TXcomBattleUnitKills): string
      begin
        Result := AKill.Weapon;
      end, True)
  else if AName = 'totalMissionsInARegion' then
    Result := FDiary.MissionTally(FMissions,
      function(AMission: TXcomMissionStatistics): string
      begin
        Result := AMission.Region;
      end)
  else if AName = 'totalKillsByRace' then
    Result := FDiary.KillTally(
      function(AKill: TXcomBattleUnitKills): string
      begin
        Result := AKill.Race;
      end, False)
  else
    Result := FDiary.KillTally(
      function(AKill: TXcomBattleUnitKills): string
      begin
        Result := AKill.Rank;
      end, False);
end;

function TXcomCommendationManager.KillMatches(const AKill: TXcomBattleUnitKills;
  const ACondition: TXcomKillCondition): Boolean;
var
  LDetail: string;
  LBattleType, LDamageType, LWeaponBattle, LWeaponDamage, LAmmoBattle, LAmmoDamage, LIndex: Integer;
begin
  Result := True;
  for LDetail in ACondition.Names do
  begin
    LBattleType := Length(BATTLE_TYPES);
    for LIndex := 0 to High(BATTLE_TYPES) do
      if BATTLE_TYPES[LIndex] = LDetail then
      begin
        LBattleType := LIndex;
        Break;
      end;
    LDamageType := Length(DAMAGE_TYPES);
    for LIndex := 0 to High(DAMAGE_TYPES) do
      if DAMAGE_TYPES[LIndex] = LDetail then
      begin
        LDamageType := LIndex;
        Break;
      end;
    // no match with any field of the kill: this condition is not met
    if not FRules.FindItem(AKill.Weapon, LWeaponBattle, LWeaponDamage)
      or not FRules.FindItem(AKill.WeaponAmmo, LAmmoBattle, LAmmoDamage)
      or ((AKill.Rank <> LDetail) and (AKill.Race <> LDetail) and (AKill.Weapon <> LDetail)
        and (AKill.WeaponAmmo <> LDetail) and (AKill.UnitStatusString <> LDetail)
        and (AKill.UnitFactionString <> LDetail) and (AKill.UnitSideString <> LDetail)
        and (AKill.UnitBodyPartString <> LDetail) and (LAmmoDamage <> LDamageType)
        and (LWeaponBattle <> LBattleType)) then
      Exit(False);
  end;
end;

function TXcomCommendationManager.KillCriteriaMet(const ARule: TXcomRuleCommendations; const AName: string;
  AThreshold: Integer): Boolean;
var
  LOrCriteria: TArray<TXcomKillCondition>;
  LReference, LCurrent: TArray<Integer>;
  LReferenceTotal, LCurrentTotal, LLastTimeSpan, LThisTimeSpan, LIndex, LGroups: Integer;
  LSkipTimeSpan, LAndMet: Boolean;
  LKill: TXcomBattleUnitKills;
begin
  Result := False;
  LGroups := 0;
  for LOrCriteria in ARule.KillCriteria do
  begin
    SetLength(LReference, Length(LOrCriteria));
    LReferenceTotal := 0;
    for LIndex := 0 to High(LOrCriteria) do
    begin
      LReference[LIndex] := LOrCriteria[LIndex].Count;
      Inc(LReferenceTotal, LOrCriteria[LIndex].Count);
    end;
    LCurrent := Copy(LReference);
    LCurrentTotal := LReferenceTotal;
    LLastTimeSpan := -1;
    LSkipTimeSpan := False;
    for LKill in FDiary.KillList do
    begin
      LThisTimeSpan := -1;
      if AName = 'killsWithCriteriaMission' then
        LThisTimeSpan := LKill.Mission
      else if AName = 'killsWithCriteriaTurn' then
        LThisTimeSpan := LKill.Turn;
      if LThisTimeSpan <> LLastTimeSpan then
      begin
        // next time span: the counters start again
        LLastTimeSpan := LThisTimeSpan;
        LSkipTimeSpan := False;
        LCurrent := Copy(LReference);
        LCurrentTotal := LReferenceTotal;
      end
      else if LSkipTimeSpan then
        Continue;
      LAndMet := False;
      for LIndex := 0 to High(LOrCriteria) do
        if KillMatches(LKill, LOrCriteria[LIndex]) then
        begin
          // the counters of a block can go below zero: this tallies the career kills in batches
          Dec(LCurrent[LIndex]);
          if (LCurrent[LIndex] + 1 > 0) then
          begin
            Dec(LCurrentTotal);
            if LCurrentTotal <= 0 then
            begin
              LAndMet := True;
              Break;
            end;
          end;
        end;
      if LAndMet then
      begin
        Inc(LGroups);
        if LGroups >= AThreshold then
          Exit(True);
        // the peak achievements count once per time span
        if (AName = 'killsWithCriteriaTurn') or (AName = 'killsWithCriteriaMission') then
          LSkipTimeSpan := True
        else if AName = 'killsWithCriteriaCareer' then
        begin
          LCurrentTotal := 0;
          for LIndex := 0 to High(LCurrent) do
          begin
            Inc(LCurrent[LIndex], LReference[LIndex]);
            if LCurrent[LIndex] > 0 then
              Inc(LCurrentTotal, LCurrent[LIndex]);
          end;
        end;
      end;
    end;
  end;
end;

function TXcomCommendationManager.Manage: Boolean;
var
  LCommendations: TXcomStringMap<TXcomRuleCommendations>;
  LIndex, LCriterion, LLevel, LNounLevel, LCriteriaValue, LTallyIndex: Integer;
  LRule: TXcomRuleCommendations;
  LNextLevel: TDictionary<string, Integer>;
  LModular: TList<string>;
  LAward: Boolean;
  LItem: TXcomSoldierCommendation;
  LName, LNoun: string;
  LThresholds: TArray<Integer>;
  LTally: TXcomStringMap<Integer>;
begin
  Result := False;
  LCommendations := FRules.Commendations;
  LNextLevel := TDictionary<string, Integer>.Create;
  LModular := TList<string>.Create;
  try
    LIndex := 0;
    while LIndex < LCommendations.Count do
    begin
      LRule := LCommendations.Value(LIndex);
      LAward := True;
      LNextLevel.Clear;
      LNextLevel.Add(NO_NOUN, 0);
      LModular.Clear;
      for LItem in FDiary.Commendations do
        if LItem.CommendationType = LCommendations.Key(LIndex) then
          LNextLevel.AddOrSetValue(LItem.Noun, LItem.DecorationLevel + 1);
      for LCriterion := 0 to LRule.Criteria.Count - 1 do
      begin
        LName := LRule.Criteria.Key(LCriterion);
        LThresholds := LRule.Criteria.Value(LCriterion);
        LLevel := LNextLevel[NO_NOUN];
        // the medal is at its last level
        if Cardinal(LLevel) >= Cardinal(Length(LThresholds)) then
        begin
          LAward := False;
          Break;
        end
        else if NounlessFails(LName, LThresholds[LLevel]) then
        begin
          LAward := False;
          Break;
        end
        else if (LName = 'totalKillsWithAWeapon') or (LName = 'totalMissionsInARegion')
          or (LName = 'totalKillsByRace') or (LName = 'totalKillsByRank') then
        begin
          LTally := NounTally(LName);
          try
            for LTallyIndex := 0 to LTally.Count - 1 do
            begin
              LNoun := LTally.Key(LTallyIndex);
              LCriteriaValue := -1;
              if not LNextLevel.TryGetValue(LNoun, LNounLevel) then
                LCriteriaValue := LThresholds[0]
              else if LNounLevel <> Length(LThresholds) then
                LCriteriaValue := LThresholds[LNounLevel];
              if (LCriteriaValue <> -1) and (LTally.Value(LTallyIndex) >= LCriteriaValue) then
                LModular.Add(LNoun);
            end;
          finally
            LTally.Free;
          end;
          if LModular.Count = 0 then
          begin
            LAward := False;
            Break;
          end;
        end
        else if (LName = 'killsWithCriteriaCareer') or (LName = 'killsWithCriteriaMission')
          or (LName = 'killsWithCriteriaTurn') then
        begin
          if not KillCriteriaMet(LRule, LName, LThresholds[LLevel]) then
            LAward := False;
        end;
      end;
      if LAward then
      begin
        // a medal without nouns has the noun "noNoun"
        if LModular.Count = 0 then
          LModular.Add(NO_NOUN);
        for LNoun in LModular do
          FDiary.AwardCommendation(LCommendations.Key(LIndex), LNoun);
        Result := True;
      end
      else
        Inc(LIndex);
    end;
  finally
    LModular.Free;
    LNextLevel.Free;
  end;
end;

end.
