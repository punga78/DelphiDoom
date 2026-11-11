{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom debriefing library - what a mission changes in the saved     }
{  game (DebriefingState::prepareDebriefing)                                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomDebriefing.Calculator;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.UnitStats, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomMod.AlienDeployment, DelphiDoom.XcomMod.MapData, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomMod.RuleAlienMission,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Ufo,
  DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomSave.AlienBase, DelphiDoom.XcomSave.AlienMission, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.MissionStatistics,
  DelphiDoom.XcomSave.Target, DelphiDoom.XcomStrategy.Geography, DelphiDoom.XcomBattle.Types,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomDebriefing.Types,
  DelphiDoom.XcomDebriefing.Recovery, DelphiDoom.XcomDebriefing.CraftReequipper,
  DelphiDoom.XcomDebriefing.BaseFacilityRemover;

type
  /// <summary>
  ///   prepareDebriefing: after a battle the units, the items and the map are evaluated. The craft comes back (or
  ///   is lost), the soldiers that were left behind are missing in action, the aliens, the items and the parts of
  ///   the UFO or of the alien base are recovered, the base that was attacked loses what the battle destroyed, the
  ///   mission site disappears. Fills the report; the saved game, the battle and the ruleset are not owned
  /// </summary>
  TXcomDebriefingCalculator = class
  strict private
    const
      SPECIAL_START_POINT = 1;
      SPECIAL_ALIEN_ALLOYS = 10;
      SPECIAL_END_POINT = 13;
      ESCAPE_NONE = 0;
      ESCAPE_EXIT = 1;
      ESCAPE_ENTRY = 2;
  strict private
    FGame: TXcomSavedGame;
    FBattle: TXcomSavedBattleGame;
    FRuleset: TXcomRuleset;
    FRules: TXcomRulesetRules;
    FOptions: TXcomDebriefingOptions;
    FReport: TXcomDebriefingReport;
    FCapacity: TXcomBaseCapacity;
    FRecovery: TXcomMissionRecovery;
    FRemover: TXcomBaseFacilityRemover;
    FReequipper: TXcomCraftReequipper;
    function FindSoldier(AId: Integer): TXcomSoldier;
    function FindAlienMission(const ARegion: string; AObjective: Integer): Integer;
    procedure ListRecoveryItems(const AMissionStatistics: TXcomMissionStatistics);
    procedure LocateMission(const AMissionStatistics: TXcomMissionStatistics; ALongitude, ALatitude: Double);
    procedure DropToTile(const AUnit: TXcomBattleUnit; const AItem: TXcomBattleItem);
    procedure RecoverTank(const AUnit: TXcomBattleUnit; const ABase: TXcomBase);
  public
    /// <param name="AZombieConverter">SavedBattleGame::convertUnit for a zombie that is recovered (can be nil)</param>
    constructor Create(const AGame: TXcomSavedGame; const ABattle: TXcomSavedBattleGame;
      const ARuleset: TXcomRuleset; const ARules: TXcomRulesetRules; const AOptions: TXcomDebriefingOptions;
      const AReport: TXcomDebriefingReport; const AZombieConverter: TFunc<TXcomBattleUnit, TXcomBattleUnit>);
    destructor Destroy; override;
    /// <summary>prepareDebriefing</summary>
    procedure Prepare;
  end;

implementation

uses
  DelphiDoom.XcomBasescape.PsiRequirements;

{ TXcomDebriefingCalculator }

constructor TXcomDebriefingCalculator.Create(const AGame: TXcomSavedGame; const ABattle: TXcomSavedBattleGame;
  const ARuleset: TXcomRuleset; const ARules: TXcomRulesetRules; const AOptions: TXcomDebriefingOptions;
  const AReport: TXcomDebriefingReport; const AZombieConverter: TFunc<TXcomBattleUnit, TXcomBattleUnit>);
begin
  inherited Create;
  FGame := AGame;
  FBattle := ABattle;
  FRuleset := ARuleset;
  FRules := ARules;
  FOptions := AOptions;
  FReport := AReport;
  FCapacity := TXcomBaseCapacity.Create(ARuleset);
  FRecovery := TXcomMissionRecovery.Create(AGame, ARuleset, AReport, FCapacity, AOptions, AZombieConverter);
  FRemover := TXcomBaseFacilityRemover.Create(ARuleset);
  FReequipper := TXcomCraftReequipper.Create(ARuleset, ARules, AOptions, AReport.MissingItems);
end;

destructor TXcomDebriefingCalculator.Destroy;
begin
  FReequipper.Free;
  FRemover.Free;
  FRecovery.Free;
  FCapacity.Free;
  inherited Destroy;
end;

function TXcomDebriefingCalculator.FindSoldier(AId: Integer): TXcomSoldier;
var
  LBase: TXcomBase;
  LSoldier: TXcomSoldier;
begin
  for LBase in FGame.Bases do
    for LSoldier in LBase.Soldiers do
      if LSoldier.Id = AId then
        Exit(LSoldier);
  for LSoldier in FGame.DeadSoldiers do
    if LSoldier.Id = AId then
      Exit(LSoldier);
  Result := nil;
end;

function TXcomDebriefingCalculator.FindAlienMission(const ARegion: string; AObjective: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FGame.ActiveMissions.Count - 1 do
    if (FGame.ActiveMissions[LIndex].Region = ARegion) and
      (FGame.ActiveMissions[LIndex].Rule.Objective = AObjective) then
      Exit(LIndex);
  Result := -1;
end;

procedure TXcomDebriefingCalculator.ListRecoveryItems(const AMissionStatistics: TXcomMissionStatistics);
var
  LName: string;
  LRule: TXcomRuleItem;
begin
  for LName in FRuleset.Items.Index do
  begin
    LRule := FRuleset.Items.Find(LName);
    if LRule.SpecialType > 1 then
    begin
      FReport.RecoveryStats.AddOrSetValue(LRule.SpecialType, TXcomRecoveryItem.Create(LName, LRule.RecoveryPoints));
      AMissionStatistics.LootValue := LRule.RecoveryPoints;
    end;
  end;
end;

procedure TXcomDebriefingCalculator.LocateMission(const AMissionStatistics: TXcomMissionStatistics;
  ALongitude, ALatitude: Double);
begin
  FReport.Region := TXcomGeography.LocateRegion(FGame, ALongitude, ALatitude);
  if Assigned(FReport.Region) then
    AMissionStatistics.Region := FReport.Region.Rules.RegionType;
  FReport.Country := TXcomGeography.LocateCountry(FGame, ALongitude, ALatitude);
  if Assigned(FReport.Country) then
    AMissionStatistics.Country := FReport.Country.Rules.CountryType;
end;

procedure TXcomDebriefingCalculator.DropToTile(const AUnit: TXcomBattleUnit; const AItem: TXcomBattleItem);
begin
  // Tile::addItem does not take the item from the unit
  AUnit.Tile.AddItem(AItem, FRuleset.Inventories.Find('STR_GROUND'));
end;

procedure TXcomDebriefingCalculator.RecoverTank(const AUnit: TXcomBattleUnit; const ABase: TXcomBase);
var
  LTankRule: TXcomRuleItem;

  procedure StoreAmmo(const AHand: string; const ARule: TXcomRuleItem);
  var
    LHand, LAmmoItem: TXcomBattleItem;
    LRule: TXcomRuleItem;
    LTotal: Integer;
  begin
    LHand := AUnit.GetItem(AHand);
    if not Assigned(LHand) then
      Exit;
    LRule := ARule;
    if not Assigned(LRule) then
      LRule := LHand.Rules;
    LAmmoItem := LHand.AmmoItem;
    if (Length(LRule.CompatibleAmmo) > 0) and Assigned(LAmmoItem) and (LAmmoItem.AmmoQuantity > 0) then
    begin
      LTotal := LAmmoItem.AmmoQuantity;
      // the tank can store several clips
      if LRule.ClipSize <> 0 then
        LTotal := LTotal div LAmmoItem.Rules.ClipSize;
      ABase.StorageItems.AddItem(LRule.CompatibleAmmo[0], LTotal);
    end;
  end;

begin
  // a player unit that is not a soldier is a tank
  ABase.StorageItems.AddItem(AUnit.UnitType, 1);
  LTankRule := FRuleset.Items.Find(AUnit.UnitType);
  if Assigned(AUnit.GetItem('STR_RIGHT_HAND')) then
    StoreAmmo('STR_RIGHT_HAND', LTankRule);
  if Assigned(AUnit.GetItem('STR_LEFT_HAND')) then
    StoreAmmo('STR_LEFT_HAND', nil);
end;

procedure TXcomDebriefingCalculator.Prepare;
var
  LStatistics: TXcomMissionStatistics;
  LDeployment: TXcomAlienDeployment;
  LAborted, LSuccess: Boolean;
  LCraft: TXcomCraft;
  LBase: TXcomBase;
  LTarget: string;
  LPlayersInExitArea, LPlayersSurvived, LPlayersUnconscious, LPlayersInEntryArea, LPlayersMia: Integer;
  LObjectiveCompleteText, LObjectiveFailedText: string;
  LObjectiveCompleteScore, LObjectiveFailedScore: Integer;

  LCandidateBase: TXcomBase;
  LCandidateCraft: TXcomCraft;
  LIndex, LDeadSoldiers, LPart, LTileIndex: Integer;
  LUnit: TXcomBattleUnit;
  LUfo: TXcomUfo;
  LItem: TXcomBattleItem;
  LSoldier: TXcomSoldier;
  LStatus, LFaction, LOldFaction, LValue: Integer;
  LPosition: TXcomPosition;
  LStatIncrease: TXcomUnitStats;
  LImprovement: TXcomSoldierImprovement;
  LLostCraft: Boolean;
  LUfoIndex, LFacilityIndex, LAlienBaseIndex: Integer;
  LDestroyAlienBase: Boolean;
  LAlloy: TXcomRecoveryItem;
  LDivider, LMissionIndex, LVictoryStat: Integer;
  LStat: TXcomDebriefingStat;
  LNonRecoverType, LSpecialType: Integer;
  LPersons: TArray<TXcomBattleUnit>;
  LTile: TXcomTile;
  LRecoveryItem: TXcomRecoveryItem;
begin
  LStatistics := TXcomMissionStatistics.Create;
  FReport.MissionStatistics := LStatistics;
  ListRecoveryItems(LStatistics);
  LDeployment := FRuleset.AlienDeployments.Find(FBattle.MissionType);
  LAborted := FBattle.Aborted;
  LSuccess := (not LAborted) or FBattle.AllObjectivesDestroyed;
  LCraft := nil;
  LBase := nil;
  LTarget := '';
  LPlayersInExitArea := 0;
  LPlayersSurvived := 0;
  LPlayersUnconscious := 0;
  LPlayersInEntryArea := 0;
  LPlayersMia := 0;
  FReport.Stats.Add(TXcomDebriefingStat.Create('STR_ALIENS_KILLED', False));
  FReport.Stats.Add(TXcomDebriefingStat.Create('STR_ALIEN_CORPSES_RECOVERED', False));
  FReport.Stats.Add(TXcomDebriefingStat.Create('STR_LIVE_ALIENS_RECOVERED', False));
  FReport.Stats.Add(TXcomDebriefingStat.Create('STR_ALIEN_ARTIFACTS_RECOVERED', False));
  LObjectiveCompleteText := '';
  LObjectiveFailedText := '';
  LObjectiveCompleteScore := 0;
  LObjectiveFailedScore := 0;
  if Assigned(LDeployment) then
  begin
    if LDeployment.ObjectiveCompleteText <> '' then
    begin
      LObjectiveCompleteText := LDeployment.ObjectiveCompleteText;
      LObjectiveCompleteScore := LDeployment.ObjectiveCompleteScore;
      FReport.Stats.Add(TXcomDebriefingStat.Create(LObjectiveCompleteText, False));
    end;
    if LDeployment.ObjectiveFailedText <> '' then
    begin
      LObjectiveFailedText := LDeployment.ObjectiveFailedText;
      LObjectiveFailedScore := LDeployment.ObjectiveFailedScore;
      FReport.Stats.Add(TXcomDebriefingStat.Create(LObjectiveFailedText, False));
    end;
  end;
  FReport.Stats.Add(TXcomDebriefingStat.Create('STR_CIVILIANS_KILLED_BY_ALIENS', False));
  FReport.Stats.Add(TXcomDebriefingStat.Create('STR_CIVILIANS_KILLED_BY_XCOM_OPERATIVES', False));
  FReport.Stats.Add(TXcomDebriefingStat.Create('STR_CIVILIANS_SAVED', False));
  FReport.Stats.Add(TXcomDebriefingStat.Create('STR_XCOM_OPERATIVES_KILLED', False));
  FReport.Stats.Add(TXcomDebriefingStat.Create('STR_XCOM_OPERATIVES_MISSING_IN_ACTION', False));
  FReport.Stats.Add(TXcomDebriefingStat.Create('STR_TANKS_DESTROYED', False));
  FReport.Stats.Add(TXcomDebriefingStat.Create('STR_XCOM_CRAFT_LOST', False));
  // the objects worth points, in the order of their special type (std::map)
  LPersons := nil;
  for LIndex := 0 to 255 do
    if FReport.RecoveryStats.TryGetValue(LIndex, LRecoveryItem) then
      FReport.Stats.Add(TXcomDebriefingStat.Create(LRecoveryItem.Name, True));
  LStatistics.Time.Assign(FGame.Time);
  LStatistics.MissionType := FBattle.MissionType;
  FReport.Stats.Add(TXcomDebriefingStat.Create(FRuleset.Settings.AlienFuelName, True));

  for LCandidateBase in FGame.Bases do
  begin
    // in case we have a craft: check which craft it is about
    for LCandidateCraft in LCandidateBase.Crafts do
    begin
      if LCandidateCraft.InBattlescape then
      begin
        LocateMission(LStatistics, LCandidateCraft.Longitude, LCandidateCraft.Latitude);
        LCraft := LCandidateCraft;
        LBase := LCandidateBase;
        if Assigned(LCraft.Destination) then
        begin
          LStatistics.MarkerName := LCraft.Destination.MarkerName;
          LStatistics.MarkerId := LCraft.Destination.MarkerId;
          LTarget := LCraft.Destination.TargetType;
          // custom mission names are ignored
          if LCraft.Destination is TXcomAlienBase then
            LTarget := 'STR_ALIEN_BASE'
          else if LCraft.Destination is TXcomMissionSite then
            LTarget := 'STR_MISSION_SITE';
        end;
        LCraft.ReturnToBase;
        LCraft.MissionComplete := True;
        LCraft.SetInBattlescape(False);
      end
      else if Assigned(LCandidateCraft.Destination) then
      begin
        if (LCandidateCraft.Destination is TXcomUfo) and TXcomUfo(LCandidateCraft.Destination).InBattlescape then
          LCandidateCraft.ReturnToBase;
        if (LCandidateCraft.Destination is TXcomMissionSite) and
          TXcomMissionSite(LCandidateCraft.Destination).InBattlescape then
          LCandidateCraft.ReturnToBase;
      end;
    end;
    // in case we do not have a craft (base defense)
    if LCandidateBase.InBattlescape then
    begin
      LBase := LCandidateBase;
      LTarget := LBase.TargetType;
      LBase.InBattlescape := False;
      LocateMission(LStatistics, LBase.Longitude, LBase.Latitude);
      // the UFO that sits on top of the base is probably the one that attacks it
      for LUfo in FGame.Ufos do
        if TXcomTarget.SameAngle(LUfo.Longitude, LBase.Longitude) and TXcomTarget.SameAngle(LUfo.Latitude, LBase.Latitude) then
        begin
          LStatistics.Ufo := LUfo.Rules.UfoType;
          LStatistics.AlienRace := LUfo.AlienRace;
          Break;
        end;
      if LAborted then
        FReport.DestroyBase := True;
      LFacilityIndex := 0;
      while LFacilityIndex < LBase.Facilities.Count do
        // this facility was demolished
        if FBattle.ModuleMap[LBase.Facilities[LFacilityIndex].X][LBase.Facilities[LFacilityIndex].Y].Value = 0 then
        begin
          FRemover.DestroyFacility(LBase, LFacilityIndex);
          LFacilityIndex := 0;
        end
        else
          Inc(LFacilityIndex);
      // this may cause the base to become disjointed: the disconnected parts are destroyed
      FRemover.DestroyDisconnectedFacilities(LBase);
    end;
  end;

  // the mission site disappears (even when you abort)
  for LIndex := 0 to FGame.MissionSites.Count - 1 do
    if FGame.MissionSites[LIndex].InBattlescape then
    begin
      LStatistics.AlienRace := FGame.MissionSites[LIndex].AlienRace;
      FGame.MissionSites.Delete(LIndex);
      Break;
    end;

  // the units: how many surviving X-COM units there are, how many are conscious and how many died
  LDeadSoldiers := 0;
  for LUnit in FBattle.Units do
  begin
    if (LUnit.OriginalFaction = FACTION_PLAYER) and (LUnit.Status <> STATUS_DEAD) then
    begin
      if (LUnit.Status = STATUS_UNCONSCIOUS) or (LUnit.Faction = FACTION_HOSTILE) then
        Inc(LPlayersUnconscious)
      else if (LUnit.Status = STATUS_IGNORE_ME) and (LUnit.StunLevel >= LUnit.Health) then
        // even for ignored units we need to know if they are conscious
        Inc(LPlayersUnconscious)
      else if LUnit.IsInExitArea(SPECIAL_END_POINT) then
        Inc(LPlayersInExitArea)
      else if LUnit.IsInExitArea(SPECIAL_START_POINT) then
        Inc(LPlayersInEntryArea)
      else if LAborted then
        // if aborted, a conscious unit that is not on the start or the end point is missing in action
        Inc(LPlayersMia);
      Inc(LPlayersSurvived);
    end
    else if (LUnit.OriginalFaction = FACTION_PLAYER) and (LUnit.Status = STATUS_DEAD) then
      Inc(LDeadSoldiers);
  end;
  // if all our men are unconscious, the aliens get to have their way with them
  if LPlayersUnconscious + LPlayersMia = LPlayersSurvived then
  begin
    LPlayersSurvived := LPlayersMia;
    for LUnit in FBattle.Units do
      if (LUnit.OriginalFaction = FACTION_PLAYER) and (LUnit.Status <> STATUS_DEAD) then
      begin
        if (LUnit.Status = STATUS_UNCONSCIOUS) or (LUnit.Faction = FACTION_HOSTILE) then
          LUnit.InstaKill
        else if (LUnit.Status = STATUS_IGNORE_ME) and (LUnit.StunLevel >= LUnit.Health) then
          LUnit.InstaKill;
      end;
  end;

  // if it is a UFO, what happens to it
  for LUfoIndex := 0 to FGame.Ufos.Count - 1 do
  begin
    LUfo := FGame.Ufos[LUfoIndex];
    if LUfo.InBattlescape then
    begin
      LStatistics.Ufo := LUfo.Rules.UfoType;
      if FGame.MonthsPassed <> -1 then
        LStatistics.AlienRace := LUfo.AlienRace;
      FReport.RecoveryTitle := 'STR_UFO_RECOVERY';
      LUfo.SetInBattlescape(False);
      // if X-COM failed to secure the landing zone the UFO takes off immediately; if it succeeded, or it is a
      // crash site, the UFO disappears
      if (LUfo.Status = TXcomUfo.STATUS_LANDED) and (LAborted or (LPlayersSurvived = 0)) then
        LUfo.SecondsRemaining := 5
      else
        FGame.Ufos.Delete(LUfoIndex);
      Break;
    end;
  end;

  if Assigned(LDeployment) and (LDeployment.EscapeType <> ESCAPE_NONE) then
  begin
    if LDeployment.EscapeType <> ESCAPE_EXIT then
      LSuccess := LPlayersInEntryArea > 0;
    if LDeployment.EscapeType <> ESCAPE_ENTRY then
      LSuccess := LSuccess or (LPlayersInExitArea > 0);
  end;
  LPlayersInExitArea := 0;

  if LPlayersSurvived = 1 then
    for LUnit in FBattle.Units do
    begin
      // if only one soldier survived, a medal (unless he killed all the others)
      if (LUnit.Status <> STATUS_DEAD) and (LUnit.OriginalFaction = FACTION_PLAYER) and
        (not LUnit.Statistics.HasFriendlyFired) and (LDeadSoldiers <> 0) then
      begin
        LUnit.Statistics.LoneSurvivor := True;
        Break;
      end;
      // if only one soldier survived and none died, only one soldier went on the mission
      if (LUnit.Status <> STATUS_DEAD) and (LUnit.OriginalFaction = FACTION_PLAYER) and (LDeadSoldiers = 0) then
        LUnit.Statistics.IronMan := True;
    end;

  // the alien base disappears (if you did not abort)
  for LAlienBaseIndex := 0 to FGame.AlienBases.Count - 1 do
    if FGame.AlienBases[LAlienBaseIndex].InBattlescape then
    begin
      FReport.RecoveryTitle := 'STR_ALIEN_BASE_RECOVERY';
      LDestroyAlienBase := True;
      if LAborted or (LPlayersSurvived = 0) then
        if not FBattle.AllObjectivesDestroyed then
          LDestroyAlienBase := False;
      if Assigned(LDeployment) and (LDeployment.NextStage <> '') then
      begin
        LStatistics.AlienRace := FGame.AlienBases[LAlienBaseIndex].AlienRace;
        LDestroyAlienBase := False;
      end;
      LSuccess := LDestroyAlienBase;
      if LDestroyAlienBase then
      begin
        if LObjectiveCompleteText <> '' then
          FReport.AddStat(LObjectiveCompleteText, 1, LObjectiveCompleteScore);
        // the supply missions of this base lose it
        for LIndex := 0 to FGame.ActiveMissions.Count - 1 do
          if FGame.ActiveMissions[LIndex].AlienBase = FGame.AlienBases[LAlienBaseIndex] then
            FGame.ActiveMissions[LIndex].AlienBase := nil;
        FGame.AlienBases.Delete(LAlienBaseIndex);
      end
      else
        FGame.AlienBases[LAlienBaseIndex].InBattlescape := False;
      Break;
    end;

  // time to care for the units
  LIndex := 0;
  while LIndex < FBattle.Units.Count do
  begin
    LUnit := FBattle.Units[LIndex];
    Inc(LIndex);
    LStatus := LUnit.Status;
    LFaction := LUnit.Faction;
    LOldFaction := LUnit.OriginalFaction;
    LValue := LUnit.Value;
    LSoldier := FindSoldier(LUnit.Id);
    if not Assigned(LUnit.Tile) then
    begin
      LPosition := LUnit.Position;
      if (LPosition.X = -1) and (LPosition.Y = -1) and (LPosition.Z = -1) then
        for LItem in FBattle.Items do
          if Assigned(LItem.CorpseUnit) and (LItem.CorpseUnit = LUnit) then
          begin
            if Assigned(LItem.Owner) then
              LPosition := LItem.Owner.Position
            else if Assigned(LItem.Tile) then
              LPosition := LItem.Tile.Position;
          end;
      LUnit.SetTile(FBattle.TileAt(LPosition));
    end;
    if LStatus = STATUS_DEAD then
    begin
      if (LOldFaction = FACTION_HOSTILE) and (LUnit.KilledBy = FACTION_PLAYER) then
        FReport.AddStat('STR_ALIENS_KILLED', 1, LValue)
      else if LOldFaction = FACTION_PLAYER then
      begin
        if Assigned(LSoldier) then
        begin
          FReport.AddStat('STR_XCOM_OPERATIVES_KILLED', 1, -LValue);
          LSoldier.AddMissionCount;
          LSoldier.AddKillCount(LUnit.Kills);
          LUnit.Statistics.KIA := True;
          // in case we missed the soldier death in the battlescape
          TXcomGeography.KillSoldier(FGame, LSoldier);
        end
        else
          // a player unit that is not a soldier is a tank
          FReport.AddStat('STR_TANKS_DESTROYED', 1, -LValue);
      end
      else if LOldFaction = FACTION_NEUTRAL then
      begin
        if LUnit.KilledBy = FACTION_PLAYER then
          FReport.AddStat('STR_CIVILIANS_KILLED_BY_XCOM_OPERATIVES', 1, -LUnit.Value - (2 * (LUnit.Value div 3)))
        else
          // if civilians kill themselves X-COM gets no penalty
          FReport.AddStat('STR_CIVILIANS_KILLED_BY_ALIENS', 1, -LUnit.Value);
      end;
    end
    else
    begin
      if LOldFaction = FACTION_PLAYER then
      begin
        if (((LUnit.IsInExitArea(SPECIAL_START_POINT) or (LUnit.Status = STATUS_IGNORE_ME)) and
          ((FBattle.MissionType <> 'STR_BASE_DEFENSE') or LSuccess)) or (not LAborted) or
          (LAborted and LUnit.IsInExitArea(SPECIAL_END_POINT))) then
        begin
          // the game is not aborted, or it is aborted and the unit is on the exit area
          LStatIncrease := Default(TXcomUnitStats);
          LUnit.PostMissionProcedures(LSoldier, LStatIncrease);
          if Assigned(LUnit.GeoscapeSoldier) then
          begin
            LImprovement.Name := LUnit.GeoscapeSoldier.Name;
            LImprovement.Stats := LStatIncrease;
            FReport.SoldierStats.Add(LImprovement);
          end;
          Inc(LPlayersInExitArea);
          FRecovery.RecoverItems(LUnit.Inventory, LBase);
          if Assigned(LSoldier) then
            // the stats changed: the stat string is worked out again
            LSoldier.CalcStatString(FRuleset.StatStrings, FOptions.PsiStrengthEval and
              FGame.IsResearched(TXcomPsiRequirements.Resolve(FRuleset)))
          else
            RecoverTank(LUnit, LBase);
        end
        else
        begin
          // aborted and the unit is not on the exit area
          FReport.AddStat('STR_XCOM_OPERATIVES_MISSING_IN_ACTION', 1, -LValue);
          Dec(LPlayersSurvived);
          if Assigned(LSoldier) then
          begin
            LSoldier.AddMissionCount;
            LSoldier.AddKillCount(LUnit.Kills);
            LUnit.Statistics.MIA := True;
            TXcomGeography.KillSoldier(FGame, LSoldier);
          end;
        end;
      end
      else if (LOldFaction = FACTION_HOSTILE) and ((not LAborted) or LUnit.IsInExitArea(SPECIAL_START_POINT)) and
        (not FReport.DestroyBase) and (LFaction = FACTION_PLAYER) and ((not LUnit.IsOut) or (LUnit.Status = STATUS_IGNORE_ME)) then
      begin
        if Assigned(LUnit.Tile) then
          for LItem in LUnit.Inventory.ToArray do
            if not LItem.Rules.FixedWeapon then
              DropToTile(LUnit, LItem);
        FRecovery.RecoverAlien(LUnit, LBase);
      end
      else if LOldFaction = FACTION_NEUTRAL then
      begin
        // if the mission fails all the civilians die
        if LAborted or (LPlayersSurvived = 0) then
          FReport.AddStat('STR_CIVILIANS_KILLED_BY_ALIENS', 1, -LUnit.Value)
        else
          FReport.AddStat('STR_CIVILIANS_SAVED', 1, LUnit.Value);
      end;
    end;
  end;

  LLostCraft := False;
  if Assigned(LCraft) and (((LPlayersInExitArea = 0) and LAborted) or (LPlayersSurvived = 0)) then
  begin
    FReport.AddStat('STR_XCOM_CRAFT_LOST', 1, -LCraft.Rules.Score);
    LBase.RemoveCraft(LCraft);
    LCraft.Free;
    LCraft := nil;
    LLostCraft := True;
    // assuming that you aborted and left everyone behind
    LPlayersSurvived := 0;
    LSuccess := False;
  end;
  if (LAborted or (LPlayersSurvived = 0)) and (LTarget = 'STR_BASE') then
  begin
    for LCandidateCraft in LBase.Crafts do
      FReport.AddStat('STR_XCOM_CRAFT_LOST', 1, -LCandidateCraft.Rules.Score);
    LPlayersSurvived := 0;
    LSuccess := False;
  end;

  if ((not LAborted) or LSuccess) and (LPlayersSurvived > 0) then
  begin
    // recover the UFO: all the tiles are run through for the components and the items
    if LTarget = 'STR_BASE' then
      FReport.Title := 'STR_BASE_IS_SAVED'
    else if LTarget = 'STR_UFO' then
      FReport.Title := 'STR_UFO_IS_RECOVERED'
    else if LTarget = 'STR_ALIEN_BASE' then
      FReport.Title := 'STR_ALIEN_BASE_DESTROYED'
    else
    begin
      FReport.Title := 'STR_ALIENS_DEFEATED';
      if LObjectiveCompleteText <> '' then
      begin
        LVictoryStat := 0;
        if LDeployment.EscapeType <> ESCAPE_NONE then
        begin
          if LDeployment.EscapeType <> ESCAPE_EXIT then
            Inc(LVictoryStat, LPlayersInEntryArea);
          if LDeployment.EscapeType <> ESCAPE_ENTRY then
            Inc(LVictoryStat, LPlayersInExitArea);
        end
        else
          LVictoryStat := 1;
        FReport.AddStat(LObjectiveCompleteText, LVictoryStat, LObjectiveCompleteScore);
      end;
    end;
    if not LAborted then
    begin
      // a two-stage mission that was not aborted: the items of the earlier stages too
      FRecovery.RecoverItems(FBattle.RecoverConditional, LBase);
      LNonRecoverType := 0;
      if Assigned(LDeployment) and (LDeployment.ObjectiveType <> 0) then
        LNonRecoverType := LDeployment.ObjectiveType;
      for LTileIndex := 0 to FBattle.MapSizeXyz - 1 do
      begin
        LTile := FBattle.TileByIndex(LTileIndex);
        // the recoverable parts of the map
        for LPart := XCOM_PART_FLOOR to XCOM_PART_OBJECT do
          if Assigned(LTile.MapData[LPart]) then
          begin
            LSpecialType := LTile.MapData[LPart].SpecialType;
            if (LSpecialType <> LNonRecoverType) and FReport.RecoveryStats.TryGetValue(LSpecialType, LRecoveryItem) then
              FReport.AddStat(LRecoveryItem.Name, 1, LRecoveryItem.Value);
          end;
        // the items on the floor
        FRecovery.RecoverItems(LTile.Inventory, LBase);
      end;
    end
    else
      for LTileIndex := 0 to FBattle.MapSizeXyz - 1 do
      begin
        LTile := FBattle.TileByIndex(LTileIndex);
        if Assigned(LTile.MapData[XCOM_PART_FLOOR]) and (LTile.MapData[XCOM_PART_FLOOR].SpecialType = SPECIAL_START_POINT) then
          FRecovery.RecoverItems(LTile.Inventory, LBase);
      end;
  end
  else
  begin
    if LLostCraft then
      FReport.Title := 'STR_CRAFT_IS_LOST'
    else if LTarget = 'STR_BASE' then
    begin
      FReport.Title := 'STR_BASE_IS_LOST';
      FReport.DestroyBase := True;
    end
    else if LTarget = 'STR_UFO' then
      FReport.Title := 'STR_UFO_IS_NOT_RECOVERED'
    else if LTarget = 'STR_ALIEN_BASE' then
      FReport.Title := 'STR_ALIEN_BASE_STILL_INTACT'
    else
    begin
      FReport.Title := 'STR_TERROR_CONTINUES';
      if LObjectiveFailedText <> '' then
        FReport.AddStat(LObjectiveFailedText, 1, LObjectiveFailedScore);
    end;
    if (LPlayersSurvived > 0) and (not FReport.DestroyBase) then
      // the items of the craft floor
      for LTileIndex := 0 to FBattle.MapSizeXyz - 1 do
      begin
        LTile := FBattle.TileByIndex(LTileIndex);
        if Assigned(LTile.MapData[XCOM_PART_FLOOR]) and (LTile.MapData[XCOM_PART_FLOOR].SpecialType = SPECIAL_START_POINT) then
          FRecovery.RecoverItems(LTile.Inventory, LBase);
      end;
  end;

  // recover all our goodies
  if LPlayersSurvived > 0 then
  begin
    if LTarget = 'STR_UFO' then
      LDivider := 10
    else
      LDivider := 150;
    for LStat in FReport.Stats do
    begin
      // the values of the alien alloys are divided by 10, or by 150 for an alien base
      if FReport.RecoveryStats.TryGetValue(SPECIAL_ALIEN_ALLOYS, LAlloy) and (LStat.Item = LAlloy.Name) then
      begin
        LStat.Quantity := LStat.Quantity div LDivider;
        LStat.Score := LStat.Score div LDivider;
      end;
      // the recoverable parts of the map become items in the stores
      if LStat.Recovery and (LStat.Quantity > 0) then
        LBase.StorageItems.AddItem(LStat.Item, LStat.Quantity);
    end;
    // a multi-stage mission: everything that was in the craft of the previous stage
    FRecovery.RecoverItems(FBattle.RecoverGuaranteed, LBase);
  end;

  // the clips that the recovered rounds make
  FRecovery.StoreClips(LBase);

  // the craft takes its equipment again (if it is not lost)
  if Assigned(LCraft) then
    FReequipper.Reequip(LBase, LCraft);

  if LTarget = 'STR_BASE' then
  begin
    if not FReport.DestroyBase then
    begin
      // the crafts that are at the base, after a base defense
      for LCandidateCraft in LBase.Crafts do
        if LCandidateCraft.Status <> 'STR_OUT' then
          FReequipper.Reequip(LBase, LCandidateCraft);
    end
    else if FGame.MonthsPassed <> -1 then
    begin
      LIndex := FGame.Bases.IndexOf(LBase);
      if LIndex >= 0 then
      begin
        FGame.Bases.Delete(LIndex);
        LBase := nil;
      end;
    end;
    if Assigned(FReport.Region) then
    begin
      LMissionIndex := FindAlienMission(FReport.Region.Rules.RegionType, TXcomRuleAlienMission.OBJECTIVE_RETALIATION);
      LIndex := 0;
      while LIndex < FGame.Ufos.Count do
        if (LMissionIndex >= 0) and (FGame.Ufos[LIndex].Mission = FGame.ActiveMissions[LMissionIndex]) then
          FGame.Ufos.Delete(LIndex)
        else if (LMissionIndex < 0) and (FGame.Ufos[LIndex].Mission = nil) then
          FGame.Ufos.Delete(LIndex)
        else
          Inc(LIndex);
      if LMissionIndex >= 0 then
        FGame.ActiveMissions.Delete(LMissionIndex);
    end;
  end;
  LStatistics.Success := LSuccess;
  FReport.Base := LBase;
end;

end.
