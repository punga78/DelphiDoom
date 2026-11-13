{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - the numbers of the game so far           }
{  (StatisticsState::listStats without the screen)                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.GameStatistics;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomSave.MissionStatistics, DelphiDoom.XcomSave.BattleUnitKills;

type
  /// <summary>One line of the list: the key of the text and the value (a number, or the key of a text if ValueIsKey)</summary>
  TXcomGameStatistic = record
    LabelKey: string;
    Value: string;
    ValueIsKey: Boolean;
  end;

  /// <summary>
  ///   The numbers that the Statistics screen lists for the game in progress (the same ones, in the same order and with
  ///   the same formats as StatisticsState): difficulty, rating, income, missions, soldiers, kills, accuracy, the best
  ///   weapon and the best alien, the UFOs, the bases, the staff, the countries lost and the research done
  /// </summary>
  TXcomGameStatistics = class
  public
    /// <summary>The lines of the list (ARuleset: the ruleset of the game, for the list of the crafts)</summary>
    class function Calculate(const ASave: TXcomSavedGame; const ARuleset: TXcomRuleset): TArray<TXcomGameStatistic>;
      static;
    /// <summary>The key of the title: victory, defeat or statistics, by the ending of the game</summary>
    class function TitleKey(const ASave: TXcomSavedGame): string; static;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Funding;

const
  DIFFICULTIES: array[0..4] of string = ('STR_1_BEGINNER', 'STR_2_EXPERIENCED', 'STR_3_VETERAN', 'STR_4_GENIUS',
    'STR_5_SUPERHUMAN');
  END_WIN = 1;
  END_LOSE = 2;

function Sum(const AValues: TArray<Integer>): Integer; overload;
var
  LValue: Integer;
begin
  Result := 0;
  for LValue in AValues do
    Inc(Result, LValue);
end;

function Sum(const AValues: TArray<Int64>): Int64; overload;
var
  LValue: Int64;
begin
  Result := 0;
  for LValue in AValues do
    Inc(Result, LValue);
end;

class function TXcomGameStatistics.TitleKey(const ASave: TXcomSavedGame): string;
begin
  case ASave.EndingKind of
    END_WIN:
      Result := 'STR_VICTORY';
    END_LOSE:
      Result := 'STR_DEFEAT';
  else
    Result := 'STR_STATISTICS';
  end;
end;

class function TXcomGameStatistics.Calculate(const ASave: TXcomSavedGame;
  const ARuleset: TXcomRuleset): TArray<TXcomGameStatistic>;
var
  LRows: TList<TXcomGameStatistic>;
  LCapacity: TXcomBaseCapacity;
  LMission: TXcomMissionStatistics;
  LBase: TXcomBase;
  LSoldier: TXcomSoldier;
  LAll: TList<TXcomSoldier>;
  LWeaponKills, LAlienKills, LTally: TXcomStringMap<Integer>;
  LRegionIndex, LIndex, LValue, LCount: Integer;
  LTotalScore, LMonthly, LMissionsWin, LMissionsLoss, LNight, LBest, LWorst, LAlienBasesDestroyed, LXcomBasesLost: Integer;
  LRecruited, LLost, LKilled, LCaptured, LFriendly, LDaysWounded, LLongest, LShotsFired, LShotsLanded, LAccuracy: Integer;
  LMaxWeapon, LMaxAlien, LAlienBases, LUfos, LTerror, LCrafts, LScientists, LEngineers, LCountriesLost: Integer;
  LHighestWeapon, LHighestAlien, LName: string;
  LCause: TXcomBattleUnitKills;

  procedure Add(const ALabel, AValue: string; AIsKey: Boolean = False);
  var
    LRow: TXcomGameStatistic;
  begin
    LRow.LabelKey := ALabel;
    LRow.Value := AValue;
    LRow.ValueIsKey := AIsKey;
    LRows.Add(LRow);
  end;

  function Number(AValue: Int64): string;
  begin
    Result := TXcomFunding.FormatNumber(AValue, '');
  end;

  function IdOf(const AKey: string): Integer;
  begin
    if not ASave.Ids.TryGetValue(AKey, Result) then
      Result := 0;
  end;

  procedure Count(const AMap: TXcomStringMap<Integer>; const AKey: string; AAmount: Integer);
  var
    LOld: Integer;
  begin
    if not AMap.TryGetValue(AKey, LOld) then
      LOld := 0;
    AMap.SetValue(AKey, LOld + AAmount);
  end;

begin
  LRows := TList<TXcomGameStatistic>.Create;
  LCapacity := TXcomBaseCapacity.Create(ARuleset);
  LAll := TList<TXcomSoldier>.Create;
  LWeaponKills := TXcomStringMap<Integer>.Create;
  LAlienKills := TXcomStringMap<Integer>.Create;
  try
    LTotalScore := Sum(ASave.ResearchScores);
    for LRegionIndex := 0 to ASave.Regions.Count - 1 do
      Inc(LTotalScore, Sum(ASave.Regions[LRegionIndex].ActivityXcom) - Sum(ASave.Regions[LRegionIndex].ActivityAlien));
    LMonthly := LTotalScore div Length(ASave.ResearchScores);
    LMissionsWin := 0;
    LMissionsLoss := 0;
    LNight := 0;
    LBest := -9999;
    LWorst := 9999;
    LAlienBasesDestroyed := 0;
    LXcomBasesLost := 0;
    for LMission in ASave.MissionStatistics do
    begin
      if LMission.Success then
        Inc(LMissionsWin)
      else
        Inc(LMissionsLoss);
      LBest := Max(LBest, LMission.Score);
      LWorst := Min(LWorst, LMission.Score);
      if LMission.IsDarkness then
        Inc(LNight);
      if LMission.IsAlienBase and LMission.Success then
        Inc(LAlienBasesDestroyed);
      if LMission.IsBaseDefense and (not LMission.Success) then
        Inc(LXcomBasesLost);
    end;
    // dummy values are not left in
    if LBest = -9999 then
      LBest := 0;
    if LWorst = 9999 then
      LWorst := 0;
    for LBase in ASave.Bases do
      for LSoldier in LBase.Soldiers do
        LAll.Add(LSoldier);
    for LSoldier in ASave.DeadSoldiers do
      LAll.Add(LSoldier);
    LRecruited := LAll.Count;
    LLost := ASave.DeadSoldiers.Count;
    LKilled := 0;
    LCaptured := 0;
    LFriendly := 0;
    LDaysWounded := 0;
    LLongest := 0;
    LShotsFired := 0;
    LShotsLanded := 0;
    for LSoldier in LAll do
    begin
      Inc(LKilled, LSoldier.Diary.KillTotal);
      Inc(LCaptured, LSoldier.Diary.StunTotal);
      Inc(LDaysWounded, LSoldier.Diary.DaysWoundedTotal);
      LLongest := Max(LLongest, LSoldier.Diary.MonthsService);
      Inc(LShotsFired, LSoldier.Diary.ShotsFiredTotal);
      Inc(LShotsLanded, LSoldier.Diary.ShotsLandedTotal);
      LTally := LSoldier.Diary.KillTally(
        function(AKill: TXcomBattleUnitKills): string
        begin
          Result := AKill.Weapon;
        end, True);
      try
        for LIndex := 0 to LTally.Count - 1 do
          Count(LWeaponKills, LTally.Key(LIndex), LTally.Value(LIndex));
      finally
        LTally.Free;
      end;
      if Assigned(LSoldier.Death) and Assigned(LSoldier.Death.Cause) then
      begin
        LCause := LSoldier.Death.Cause;
        if LCause.Faction = 0 then
          Inc(LFriendly);
        if LCause.Race <> '' then
          Count(LAlienKills, LCause.Race, 1);
      end;
    end;
    LAccuracy := 0;
    if LShotsFired > 0 then
      LAccuracy := 100 * LShotsLanded div LShotsFired;
    LMaxWeapon := 0;
    LHighestWeapon := 'STR_NONE';
    for LIndex := 0 to LWeaponKills.Count - 1 do
      if LWeaponKills.Value(LIndex) > LMaxWeapon then
      begin
        LMaxWeapon := LWeaponKills.Value(LIndex);
        LHighestWeapon := LWeaponKills.Key(LIndex);
      end;
    LMaxAlien := 0;
    LHighestAlien := 'STR_NONE';
    for LIndex := 0 to LAlienKills.Count - 1 do
      if LAlienKills.Value(LIndex) > LMaxAlien then
      begin
        LMaxAlien := LAlienKills.Value(LIndex);
        LHighestAlien := LAlienKills.Key(LIndex);
      end;
    LAlienBases := LAlienBasesDestroyed;
    for LIndex := 0 to ASave.AlienBases.Count - 1 do
      if ASave.AlienBases[LIndex].Discovered then
        Inc(LAlienBases);
    LUfos := Max(0, IdOf('STR_UFO') - 1);
    LTerror := Max(0, IdOf('STR_TERROR_SITE') - 1);
    LCrafts := 0;
    for LIndex := 0 to ARuleset.Crafts.Count - 1 do
    begin
      LName := ARuleset.Crafts.Name(LIndex);
      Inc(LCrafts, Max(0, IdOf(LName) - 1));
    end;
    LScientists := 0;
    LEngineers := 0;
    for LBase in ASave.Bases do
    begin
      Inc(LScientists, LCapacity.TotalScientists(LBase));
      Inc(LEngineers, LCapacity.TotalEngineers(LBase));
    end;
    LCountriesLost := 0;
    for LIndex := 0 to ASave.Countries.Count - 1 do
      if ASave.Countries[LIndex].Pact then
        Inc(LCountriesLost);
    LValue := ASave.Discovered.Count;
    LCount := ASave.Bases.Count + LXcomBasesLost;
    Add('STR_DIFFICULTY', DIFFICULTIES[ASave.Difficulty], True);
    Add('STR_AVERAGE_MONTHLY_RATING', Number(LMonthly));
    Add('STR_TOTAL_INCOME', TXcomFunding.Format(Sum(ASave.IncomesList)));
    Add('STR_TOTAL_EXPENDITURE', TXcomFunding.Format(Sum(ASave.ExpendituresList)));
    Add('STR_MISSIONS_WON', Number(LMissionsWin));
    Add('STR_MISSIONS_LOST', Number(LMissionsLoss));
    Add('STR_NIGHT_MISSIONS', Number(LNight));
    Add('STR_BEST_RATING', Number(LBest));
    Add('STR_WORST_RATING', Number(LWorst));
    Add('STR_SOLDIERS_RECRUITED', Number(LRecruited));
    Add('STR_SOLDIERS_LOST', Number(LLost));
    Add('STR_ALIEN_KILLS', Number(LKilled));
    Add('STR_ALIEN_CAPTURES', Number(LCaptured));
    Add('STR_FRIENDLY_KILLS', Number(LFriendly));
    Add('STR_AVERAGE_ACCURACY', IntToStr(LAccuracy) + '%');
    Add('STR_WEAPON_MOST_KILLS', LHighestWeapon, True);
    Add('STR_ALIEN_MOST_KILLS', LHighestAlien, True);
    Add('STR_LONGEST_SERVICE', Number(LLongest));
    Add('STR_TOTAL_DAYS_WOUNDED', Number(LDaysWounded));
    Add('STR_TOTAL_UFOS', Number(LUfos));
    Add('STR_TOTAL_ALIEN_BASES', Number(LAlienBases));
    Add('STR_COUNTRIES_LOST', Number(LCountriesLost));
    Add('STR_TOTAL_TERROR_SITES', Number(LTerror));
    Add('STR_TOTAL_BASES', Number(LCount));
    Add('STR_TOTAL_CRAFT', Number(LCrafts));
    Add('STR_TOTAL_SCIENTISTS', Number(LScientists));
    Add('STR_TOTAL_ENGINEERS', Number(LEngineers));
    Add('STR_TOTAL_RESEARCH', Number(LValue));
    Result := LRows.ToArray;
  finally
    LAlienKills.Free;
    LWeaponKills.Free;
    LAll.Free;
    LCapacity.Free;
    LRows.Free;
  end;
end;

end.
