{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom debriefing library - the score of a mission, the rating,     }
{  the diaries and the commendations of the soldiers and the promotions         }
{  (the part of DebriefingState::init that follows prepareDebriefing)           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomDebriefing.Scorer;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Math, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomSave.BattleUnitKills, DelphiDoom.XcomSave.CommendationManager, DelphiDoom.XcomSave.DiaryRules.Intf,
  DelphiDoom.XcomSave.MissionStatistics, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomDebriefing.Types, DelphiDoom.XcomDebriefing.Promotions;

type
  /// <summary>
  ///   Adds up the lines of the report, rates the mission, records it for the diaries, awards the best-of
  ///   commendations and the crosses, updates the diary of every soldier and handles the promotions. At the end the battle
  ///   is over: the saved game forgets it. Nothing is owned
  /// </summary>
  TXcomDebriefingScorer = class
  strict private
    FGame: TXcomSavedGame;
    FBattle: TXcomSavedBattleGame;
    FRules: IXcomDiaryRules;
    FOptions: TXcomDebriefingOptions;
    FReport: TXcomDebriefingReport;
    FAliensKilled: Integer;
    FAliensStunned: Integer;
    procedure AddUp;
    procedure AwardBestOf;
    procedure UpdateSoldiers;
    procedure SetInjury(const AStatistics: TXcomMissionStatistics; ASoldierId, ARecovery: Integer);
    class function RatingOf(ATotal: Integer): string; static;
  public
    constructor Create(const AGame: TXcomSavedGame; const ABattle: TXcomSavedBattleGame;
      const ARules: IXcomDiaryRules; const AOptions: TXcomDebriefingOptions; const AReport: TXcomDebriefingReport);
    /// <summary>The part of init() after prepareDebriefing</summary>
    procedure Score;
  end;

implementation

{ TXcomDebriefingScorer }

constructor TXcomDebriefingScorer.Create(const AGame: TXcomSavedGame; const ABattle: TXcomSavedBattleGame;
  const ARules: IXcomDiaryRules; const AOptions: TXcomDebriefingOptions; const AReport: TXcomDebriefingReport);
begin
  inherited Create;
  FGame := AGame;
  FBattle := ABattle;
  FRules := ARules;
  FOptions := AOptions;
  FReport := AReport;
end;

class function TXcomDebriefingScorer.RatingOf(ATotal: Integer): string;
begin
  if ATotal <= -200 then
    Result := 'STR_RATING_TERRIBLE'
  else if ATotal <= 0 then
    Result := 'STR_RATING_POOR'
  else if ATotal <= 200 then
    Result := 'STR_RATING_OK'
  else if ATotal <= 500 then
    Result := 'STR_RATING_GOOD'
  else
    Result := 'STR_RATING_EXCELLENT';
end;

procedure TXcomDebriefingScorer.AddUp;
var
  LStat: TXcomDebriefingStat;
  LCiviliansSaved, LCiviliansDead: Integer;
  LRecoveryRows: Integer;
begin
  LRecoveryRows := 0;
  FReport.Total := 0;
  LCiviliansSaved := 0;
  LCiviliansDead := 0;
  FAliensKilled := 0;
  FAliensStunned := 0;
  for LStat in FReport.Stats do
  begin
    if LStat.Quantity = 0 then
      Continue;
    FReport.Total := FReport.Total + LStat.Score;
    if LStat.Recovery then
      Inc(LRecoveryRows);
    if LStat.Item = 'STR_CIVILIANS_SAVED' then
      LCiviliansSaved := LStat.Quantity;
    if (LStat.Item = 'STR_CIVILIANS_KILLED_BY_XCOM_OPERATIVES') or (LStat.Item = 'STR_CIVILIANS_KILLED_BY_ALIENS') then
      Inc(LCiviliansDead, LStat.Quantity);
    if LStat.Item = 'STR_ALIENS_KILLED' then
      Inc(FAliensKilled, LStat.Quantity);
    if LStat.Item = 'STR_LIVE_ALIENS_RECOVERED' then
      Inc(FAliensStunned, LStat.Quantity);
  end;
  // without a row of recovered objects the heading of the second list is empty
  if LRecoveryRows = 0 then
    FReport.RecoveryTitle := '';
  if (LCiviliansSaved <> 0) and (LCiviliansDead = 0) and FReport.MissionStatistics.Success then
    FReport.MissionStatistics.ValiantCrux := True;
end;

procedure TXcomDebriefingScorer.AwardBestOf;
var
  LBestScoreId: array[0..6] of Integer;
  LBestScore: array[0..6] of Integer;
  LBestOverallId, LBestOverall: Integer;
  LDead, LKiller: TXcomBattleUnit;
  LKill: TXcomBattleUnitKills;
  LKillTurn, LPostMortem, LScore, LRank: Integer;
  LSoldier: TXcomSoldier;
begin
  FillChar(LBestScoreId, SizeOf(LBestScoreId), 0);
  FillChar(LBestScore, SizeOf(LBestScore), 0);
  LBestOverallId := 0;
  LBestOverall := 0;
  // were any of the dead soldiers exceptional?
  for LDead in FBattle.Units do
  begin
    if (not Assigned(LDead.GeoscapeSoldier)) or (LDead.Status <> STATUS_DEAD) then
      Continue;
    // the post-mortem kill award
    LKillTurn := -1;
    for LKiller in FBattle.Units do
    begin
      for LKill in LKiller.Statistics.Kills do
        if LKill.Id = LDead.Id then
        begin
          LKillTurn := LKill.Turn;
          Break;
        end;
      if LKillTurn <> -1 then
        Break;
    end;
    LPostMortem := 0;
    if LKillTurn <> -1 then
      for LKill in LDead.Statistics.Kills do
        if (LKill.Turn > LKillTurn) and (LKill.Faction = FACTION_HOSTILE) then
          Inc(LPostMortem);
    LDead.GeoscapeSoldier.Diary.AwardPostMortemKill(LPostMortem);
    LRank := LDead.GeoscapeSoldier.Rank;
    // the rookies do not get the next award
    if LRank = TXcomSoldier.RANK_ROOKIE then
      Continue;
    // the best soldier of each rank, by score
    for LSoldier in FGame.DeadSoldiers do
    begin
      LScore := LSoldier.Diary.ScoreTotal(FGame.MissionStatistics);
      // do not forget the score of this mission
      if LSoldier.Id = LDead.Id then
        Inc(LScore, FReport.MissionStatistics.Score);
      if LScore > LBestScore[LRank] then
      begin
        LBestScoreId[LRank] := LDead.Id;
        LBestScore[LRank] := LScore;
        if LScore > LBestOverall then
        begin
          LBestOverallId := LDead.Id;
          LBestOverall := LScore;
        end;
      end;
    end;
  end;
  // now the commendations
  for LDead in FBattle.Units do
  begin
    if (not Assigned(LDead.GeoscapeSoldier)) or (LDead.Status <> STATUS_DEAD) then
      Continue;
    if LDead.Id = LBestScoreId[LDead.GeoscapeSoldier.Rank] then
      LDead.GeoscapeSoldier.Diary.AwardBestOfRank(LBestScore[LDead.GeoscapeSoldier.Rank]);
    if LDead.Id = LBestOverallId then
      LDead.GeoscapeSoldier.Diary.AwardBestOverall(LBestOverall);
  end;
end;

procedure TXcomDebriefingScorer.SetInjury(const AStatistics: TXcomMissionStatistics; ASoldierId, ARecovery: Integer);
var
  LList: TArray<TXcomInjury>;
  LIndex: Integer;
  LInjury: TXcomInjury;
begin
  // injuryList is a map by the id of the soldier
  LList := AStatistics.InjuryList;
  for LIndex := 0 to High(LList) do
    if LList[LIndex].Wounds = ASoldierId then
    begin
      LList[LIndex].Soldiers := ARecovery;
      AStatistics.InjuryList := LList;
      Exit;
    end;
  LInjury.Wounds := ASoldierId;
  LInjury.Soldiers := ARecovery;
  SetLength(LList, Length(LList) + 1);
  LIndex := High(LList);
  while (LIndex > 0) and (LList[LIndex - 1].Wounds > ASoldierId) do
  begin
    LList[LIndex] := LList[LIndex - 1];
    Dec(LIndex);
  end;
  LList[LIndex] := LInjury;
  AStatistics.InjuryList := LList;
end;

procedure TXcomDebriefingScorer.UpdateSoldiers;
var
  LUnit: TXcomBattleUnit;
  LKill: TXcomBattleUnitKills;
  LSoldierKills, LSoldierStuns, LMartyrKills, LMartyrTurn: Integer;
  LManager: TXcomCommendationManager;
  LAwarded: Boolean;
begin
  for LUnit in FBattle.Units do
  begin
    if not Assigned(LUnit.GeoscapeSoldier) then
      Continue;
    LSoldierKills := 0;
    LSoldierStuns := 0;
    for LKill in LUnit.Statistics.Kills do
    begin
      if (LKill.Faction = FACTION_HOSTILE) and (LKill.Status = STATUS_DEAD) then
        Inc(LSoldierKills);
      if (LKill.Faction = FACTION_HOSTILE) and (LKill.Status = STATUS_UNCONSCIOUS) then
        Inc(LSoldierStuns);
    end;
    if (FAliensKilled <> 0) and (FAliensKilled = LSoldierKills) and FReport.MissionStatistics.Success and
      (FAliensStunned = LSoldierStuns) then
      LUnit.Statistics.NikeCross := True;
    if (FAliensStunned <> 0) and (FAliensStunned = LSoldierStuns) and FReport.MissionStatistics.Success and
      (FAliensKilled = 0) then
      LUnit.Statistics.MercyCross := True;
    LUnit.Statistics.DaysWounded := LUnit.GeoscapeSoldier.WoundRecovery;
    SetInjury(FReport.MissionStatistics, LUnit.GeoscapeSoldier.Id, LUnit.GeoscapeSoldier.WoundRecovery);
    // the martyr medal
    if (LUnit.MurdererId = LUnit.Id) and (LUnit.Statistics.Kills.Count <> 0) then
    begin
      LMartyrKills := 0;
      LMartyrTurn := -1;
      for LKill in LUnit.Statistics.Kills do
        if LKill.Id = LUnit.Id then
        begin
          LMartyrTurn := LKill.Turn;
          Break;
        end;
      for LKill in LUnit.Statistics.Kills do
        if (LKill.Turn = LMartyrTurn) and (LKill.Faction = FACTION_HOSTILE) then
          Inc(LMartyrKills);
      if LMartyrKills > 0 then
        LUnit.Statistics.Martyr := Min(LMartyrKills, 10);
    end;
    LUnit.Statistics.Delta := LUnit.GeoscapeSoldier.CurrentStats - LUnit.GeoscapeSoldier.InitialStats;
    LUnit.GeoscapeSoldier.Diary.UpdateDiary(LUnit.Statistics, FGame.MissionStatistics, FRules);
    LManager := TXcomCommendationManager.Create(LUnit.GeoscapeSoldier.Diary, FRules, FGame.MissionStatistics);
    try
      LAwarded := LManager.Manage;
    finally
      LManager.Free;
    end;
    if (not LUnit.Statistics.MIA) and (not LUnit.Statistics.KIA) and LAwarded then
      FReport.SoldiersCommended.Add(LUnit.GeoscapeSoldier)
    else if LUnit.Statistics.MIA or LUnit.Statistics.KIA then
      FReport.DeadSoldiersCommended.Add(LUnit.GeoscapeSoldier);
  end;
end;

procedure TXcomDebriefingScorer.Score;
var
  LStatistics: TXcomMissionStatistics;
  LParticipants: TList<TXcomSoldier>;
  LUnit: TXcomBattleUnit;
  LPromotions: TXcomSoldierPromotions;
begin
  AddUp;
  // the points are added to the activity score
  if Assigned(FReport.Region) then
    FReport.Region.AddActivityXcom(FReport.Total);
  if Assigned(FReport.Country) then
    FReport.Country.AddActivityXcom(FReport.Total);
  FReport.Rating := RatingOf(FReport.Total);
  LStatistics := FReport.MissionStatistics;
  LStatistics.Rating := FReport.Rating;
  LStatistics.Score := FReport.Total;
  LStatistics.Daylight := FBattle.GlobalShade;
  LStatistics.Id := FGame.MissionStatistics.Count;
  FGame.MissionStatistics.Add(LStatistics);
  AwardBestOf;
  UpdateSoldiers;
  FReport.PositiveScore := FReport.Total > 0;
  LParticipants := TList<TXcomSoldier>.Create;
  try
    for LUnit in FBattle.Units do
      if Assigned(LUnit.GeoscapeSoldier) then
        LParticipants.Add(LUnit.GeoscapeSoldier);
    LPromotions := TXcomSoldierPromotions.Create(FGame, FOptions.FieldPromotions);
    try
      FReport.Promotions := LPromotions.Handle(LParticipants);
    finally
      LPromotions.Free;
    end;
  finally
    LParticipants.Free;
  end;
  // the battle is over: the saved game forgets it
  FGame.BattleGame := nil;
end;

end.
