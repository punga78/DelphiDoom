{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - the mission scripts of the month        }
{  (GeoscapeState::determineAlienMissions and processCommand)                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.MissionScriptRunner;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomMod.RuleMissionScript, DelphiDoom.XcomMod.RuleAlienMission, DelphiDoom.XcomMod.RuleResearch, DelphiDoom.XcomMod.RuleRegion,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.AlienMission, DelphiDoom.XcomSave.AlienStrategy,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Target, DelphiDoom.XcomStrategy.Types,
  DelphiDoom.XcomStrategy.Geography;

type
  /// <summary>
  ///   At the start of a month the mission scripts of the ruleset decide which missions the aliens begin: each
  ///   command that is in its months, has runs left and has its research triggers is run with its odds, and
  ///   picks a region, a mission type and a race (determineAlienMissions). The generator is injected
  /// </summary>
  TXcomMissionScriptRunner = class
  strict private
    FGame: TXcomSavedGame;
    FRuleset: TXcomRuleset;
    FRandom: IXcomRandom;
    function IsResearched(const AResearch: string): Boolean;
    class function Contains(const AList: TArray<string>; const AValue: string): Boolean; static;
    function BaseRegions: TArray<string>;
    function ChooseSiteTarget(const ACommand: TXcomRuleMissionScript; AMonth: Integer; var AMissionType: string;
      out ARegion: string; out AZone: Integer): Boolean;
    function ChooseBaseTarget(const ACommand: TXcomRuleMissionScript; AMonth: Integer; var AMissionType: string;
      out ARegion: string): Boolean;
    function ProcessCommand(const ACommand: TXcomRuleMissionScript): Boolean;
  public
    constructor Create(const AGame: TXcomSavedGame; const ARuleset: TXcomRuleset; const ARandom: IXcomRandom);
    /// <summary>determineAlienMissions: runs the scripts of the month that has begun</summary>
    procedure DetermineAlienMissions;
  end;

implementation

type
  TXcomValidArea = record
    Region: string;
    Zone: Integer;
  end;

{ TXcomMissionScriptRunner }

constructor TXcomMissionScriptRunner.Create(const AGame: TXcomSavedGame; const ARuleset: TXcomRuleset;
  const ARandom: IXcomRandom);
begin
  inherited Create;
  FGame := AGame;
  FRuleset := ARuleset;
  FRandom := ARandom;
end;

function TXcomMissionScriptRunner.IsResearched(const AResearch: string): Boolean;
var
  LResearch: TXcomRuleResearch;
begin
  Result := False;
  for LResearch in FGame.Discovered do
    if LResearch.Name = AResearch then
      Exit(True);
end;

class function TXcomMissionScriptRunner.Contains(const AList: TArray<string>; const AValue: string): Boolean;
var
  LItem: string;
begin
  for LItem in AList do
    if LItem = AValue then
      Exit(True);
  Result := False;
end;

function TXcomMissionScriptRunner.BaseRegions: TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, FGame.Bases.Count);
  for LIndex := 0 to FGame.Bases.Count - 1 do
    Result[LIndex] := TXcomGeography.LocateRegion(FGame, FGame.Bases[LIndex].Longitude,
      FGame.Bases[LIndex].Latitude).Rules.RegionType;
end;

function TXcomMissionScriptRunner.ChooseSiteTarget(const ACommand: TXcomRuleMissionScript; AMonth: Integer;
  var AMissionType: string; out ARegion: string; out AZone: Integer): Boolean;
var
  LMissions, LRegions, LKeep: TArray<string>;
  LTargetBase: Boolean;
  LMaxMissions, LCurrent, LHeight, LRegionIndex, LAreaIndex, LCounter, LMin, LMax, LCurr, LZone: Integer;
  LValid: TList<TXcomValidArea>;
  LRules: TXcomRuleAlienMission;
  LRegion: TXcomRuleRegion;
  LAreas: TArray<TXcomMissionArea>;
  LProcess: Boolean;
  LMission: TXcomAlienMission;
  LEntry: TXcomValidArea;
  LList: TList<string>;
begin
  Result := False;
  AZone := -1;
  ARegion := '';
  AMissionType := ACommand.Generate(Cardinal(AMonth), TXcomRuleMissionScript.GEN_MISSION, FRandom);
  LMissions := ACommand.GetMissionTypes(AMonth);
  LMaxMissions := Length(LMissions);
  LTargetBase := FRandom.Generate(0, 99) < ACommand.TargetBaseOdds;
  LCurrent := 0;
  while LCurrent <> LMaxMissions do
  begin
    if LMissions[LCurrent] = AMissionType then
      Break;
    Inc(LCurrent);
  end;
  LValid := TList<TXcomValidArea>.Create;
  LList := TList<string>.Create;
  try
    for LHeight := 0 to LMaxMissions - 1 do
    begin
      if ACommand.HasRegionWeights then
        LRegions := ACommand.GetRegions(AMonth)
      else
        LRegions := Copy(FRuleset.Regions.Index);
      LRules := FRuleset.AlienMissions.Find(AMissionType);
      if not Assigned(LRules) then
        raise EXcomStrategyException.CreateFmt('%s not found', [AMissionType]);
      AZone := LRules.SpawnZone;
      if LTargetBase then
      begin
        LKeep := BaseRegions;
        LList.Clear;
        for LRegionIndex := 0 to High(LRegions) do
          if Contains(LKeep, LRegions[LRegionIndex]) then
            LList.Add(LRegions[LRegionIndex]);
        LRegions := LList.ToArray;
      end;
      LList.Clear;
      for LRegionIndex := 0 to High(LRegions) do
      begin
        LProcess := True;
        for LMission in FGame.ActiveMissions do
          if (LMission.Rule.MissionType = LRules.MissionType) and (LMission.Region = LRegions[LRegionIndex]) then
          begin
            LProcess := False;
            Break;
          end;
        if not LProcess then
          Continue;
        LRegion := FRuleset.Regions.Find(LRegions[LRegionIndex]);
        if Length(LRegion.MissionZones) > AZone then
        begin
          LAreas := LRegion.MissionZones[AZone].Areas;
          LCounter := 0;
          for LAreaIndex := 0 to High(LAreas) do
          begin
            if TXcomTarget.SameAngle(LAreas[LAreaIndex].LonMin, LAreas[LAreaIndex].LonMax) and
              TXcomTarget.SameAngle(LAreas[LAreaIndex].LatMin, LAreas[LAreaIndex].LatMax) and
              FGame.AlienStrategy.ValidMissionLocation(ACommand.VarName, LRegion.RegionType, LCounter) then
            begin
              LEntry.Region := LRegion.RegionType;
              LEntry.Zone := LCounter;
              LValid.Add(LEntry);
            end;
            Inc(LCounter);
          end;
        end;
      end;
      if LValid.Count = 0 then
      begin
        if LMaxMissions > 1 then
        begin
          Inc(LCurrent);
          if LCurrent = LMaxMissions then
            LCurrent := 0;
        end;
        if LCurrent >= LMaxMissions then
          raise EXcomStrategyException.Create('Mission script: the mission type is not in the list of the command');
        AMissionType := LMissions[LCurrent];
      end
      else
        Break;
    end;
    if LValid.Count = 0 then
      Exit(False);
    AZone := -1;
    ARegion := '';
    while AZone = -1 do
    begin
      if ACommand.HasRegionWeights then
        ARegion := ACommand.Generate(Cardinal(AMonth), TXcomRuleMissionScript.GEN_REGION, FRandom)
      else
        ARegion := FRuleset.Regions.Index[FRandom.Generate(0, Length(FRuleset.Regions.Index) - 1)];
      LMin := -1;
      LMax := -1;
      LCurr := 0;
      for LEntry in LValid do
      begin
        if LEntry.Region = ARegion then
        begin
          if LMin = -1 then
            LMin := LCurr;
          LMax := LCurr;
        end
        else if LMin > -1 then
          Break;
        Inc(LCurr);
      end;
      if LMin <> -1 then
      begin
        LZone := FRandom.Generate(LMin, LMax);
        AZone := LValid[LZone].Zone;
      end;
    end;
    FGame.AlienStrategy.AddMissionLocation(ACommand.VarName, ARegion, AZone, ACommand.RepeatAvoidance);
    Result := True;
  finally
    LList.Free;
    LValid.Free;
  end;
end;

function TXcomMissionScriptRunner.ChooseBaseTarget(const ACommand: TXcomRuleMissionScript; AMonth: Integer;
  var AMissionType: string; out ARegion: string): Boolean;
var
  LTypes, LMaster, LRegions: TArray<string>;
  LList: TList<string>;
  LIndex, LMax, LEntry, LRegionIndex: Integer;
  LMission: TXcomAlienMission;
begin
  Result := True;
  ARegion := '';
  LTypes := ACommand.GetMissionTypes(AMonth);
  LMaster := BaseRegions;
  if Length(LTypes) = 0 then
  begin
    LList := TList<string>.Create;
    try
      for LIndex := 0 to High(LMaster) do
        if FGame.AlienStrategy.ValidMissionRegion(LMaster[LIndex]) then
          LList.Add(LMaster[LIndex]);
      LMaster := LList.ToArray;
    finally
      LList.Free;
    end;
    if Length(LMaster) = 0 then
      Exit(False);
    ARegion := LMaster[FRandom.Generate(0, Length(LMaster) - 1)];
    Exit;
  end;
  LMax := Length(LTypes);
  LEntry := FRandom.Generate(0, LMax - 1);
  for LIndex := 0 to LMax - 1 do
  begin
    LList := TList<string>.Create;
    try
      LList.AddRange(LMaster);
      for LMission in FGame.ActiveMissions do
        if LTypes[LEntry] = LMission.Rule.MissionType then
          for LRegionIndex := LList.Count - 1 downto 0 do
            if LList[LRegionIndex] = LMission.Region then
              LList.Delete(LRegionIndex);
      LRegions := LList.ToArray;
    finally
      LList.Free;
    end;
    if Length(LRegions) > 0 then
    begin
      AMissionType := LTypes[LEntry];
      ARegion := LRegions[FRandom.Generate(0, Length(LRegions) - 1)];
      Break;
    end;
    if LMax > 1 then
    begin
      Inc(LEntry);
      if LEntry = LMax then
        LEntry := 0;
    end;
  end;
end;

function TXcomMissionScriptRunner.ProcessCommand(const ACommand: TXcomRuleMissionScript): Boolean;
var
  LMonth, LZone: Integer;
  LRegion, LMissionType, LRace: string;
  LRules: TXcomRuleAlienMission;
  LMission: TXcomAlienMission;
begin
  LMonth := FGame.MonthsPassed;
  LRegion := '';
  LMissionType := '';
  LZone := -1;
  if ACommand.SiteType then
  begin
    if not ChooseSiteTarget(ACommand, LMonth, LMissionType, LRegion, LZone) then
      Exit(False);
  end
  else if FRandom.Generate(0, 99) < ACommand.TargetBaseOdds then
  begin
    if not ChooseBaseTarget(ACommand, LMonth, LMissionType, LRegion) then
      Exit(False);
  end
  else if not ACommand.HasRegionWeights then
    LRegion := FGame.AlienStrategy.ChooseRandomRegion(FRuleset, FRandom)
  else
    LRegion := ACommand.Generate(Cardinal(LMonth), TXcomRuleMissionScript.GEN_REGION, FRandom);
  if LRegion = '' then
    Exit(False);
  if not Assigned(FRuleset.Regions.Find(LRegion)) then
    raise EXcomStrategyException.CreateFmt('Error proccessing mission script named: %s, region named: %s is not ' +
      'defined', [ACommand.ScriptType, LRegion]);
  // not a terror mission, not targeting a base, or otherwise not already chosen
  if LMissionType = '' then
  begin
    if not ACommand.HasMissionWeights then
      LMissionType := FGame.AlienStrategy.ChooseRandomMission(LRegion, FRandom)
    else
      LMissionType := ACommand.Generate(Cardinal(LMonth), TXcomRuleMissionScript.GEN_MISSION, FRandom);
  end;
  if LMissionType = '' then
    Exit(False);
  LRules := FRuleset.AlienMissions.Find(LMissionType);
  if not Assigned(LRules) then
    raise EXcomStrategyException.CreateFmt('Error proccessing mission script named: %s, mission type: %s is not ' +
      'defined', [ACommand.ScriptType, LMissionType]);
  if not ACommand.HasRaceWeights then
    LRace := LRules.GenerateRace(Cardinal(LMonth), FRandom)
  else
    LRace := ACommand.Generate(Cardinal(LMonth), TXcomRuleMissionScript.GEN_RACE, FRandom);
  if LRace = '' then
    raise EXcomStrategyException.CreateFmt('Error proccessing mission script named: %s, mission type: %s has no ' +
      'available races', [ACommand.ScriptType, LMissionType]);
  if not Assigned(FRuleset.AlienRaces.Find(LRace)) then
    raise EXcomStrategyException.CreateFmt('Error proccessing mission script named: %s, race: %s is not defined',
      [ACommand.ScriptType, LRace]);
  LMission := TXcomAlienMission.Create(LRules);
  FGame.ActiveMissions.Add(LMission);
  LMission.Race := LRace;
  LMission.SetId(FGame.GetId('ALIEN_MISSIONS'));
  LMission.SetRegion(LRegion, FRuleset.Regions.Find(LRegion));
  LMission.MissionSiteZone := LZone;
  FGame.AlienStrategy.AddMissionRun(ACommand.VarName, 1);
  LMission.Start(Cardinal(ACommand.Delay), FRandom);
  if ACommand.UseTable then
    FGame.AlienStrategy.RemoveMission(LRegion, LMissionType);
  Result := True;
end;

procedure TXcomMissionScriptRunner.DetermineAlienMissions;
var
  LMonth, LIndex, LCondition: Integer;
  LAvailable: TList<TXcomRuleMissionScript>;
  LCommand: TXcomRuleMissionScript;
  LConditions: TDictionary<Integer, Boolean>;
  LTriggerHappy, LProcess, LSuccess, LFound, LValue: Boolean;
  LTrigger: Integer;
begin
  LMonth := FGame.MonthsPassed;
  LAvailable := TList<TXcomRuleMissionScript>.Create;
  LConditions := TDictionary<Integer, Boolean>.Create;
  try
    for LIndex := 0 to FRuleset.MissionScripts.Count - 1 do
    begin
      LCommand := FRuleset.MissionScripts.Find(FRuleset.MissionScripts.Index[LIndex]);
      if (LCommand.FirstMonth <= LMonth) and ((LCommand.LastMonth >= LMonth) or (LCommand.LastMonth = -1)) and
        ((LCommand.MaxRuns = -1) or (LCommand.MaxRuns > FGame.AlienStrategy.MissionsRun(LCommand.VarName))) and
        (LCommand.MinDifficulty <= FGame.Difficulty) then
      begin
        LTriggerHappy := True;
        LTrigger := 0;
        while LTriggerHappy and (LTrigger < LCommand.ResearchTriggers.Count) do
        begin
          LTriggerHappy := IsResearched(LCommand.ResearchTriggers.Key(LTrigger)) =
            LCommand.ResearchTriggers.Value(LTrigger);
          Inc(LTrigger);
        end;
        if LTriggerHappy then
          LAvailable.Add(LCommand);
      end;
    end;
    for LCommand in LAvailable do
    begin
      LProcess := True;
      LSuccess := False;
      LIndex := 0;
      while LProcess and (LIndex < Length(LCommand.Conditionals)) do
      begin
        LCondition := LCommand.Conditionals[LIndex];
        LFound := LConditions.TryGetValue(Abs(LCondition), LValue);
        LProcess := not LFound or (LValue and (LCondition > 0)) or (not LValue and (LCondition < 0));
        Inc(LIndex);
      end;
      if (LCommand.ScriptLabel > 0) and LConditions.ContainsKey(LCommand.ScriptLabel) then
        raise EXcomStrategyException.CreateFmt('Mission generator encountered an error: multiple commands: %s are ' +
          'sharing the same label: %d', [LCommand.ScriptType, LCommand.ScriptLabel]);
      if LProcess and (FRandom.Generate(0, 99) < LCommand.ExecutionOdds) then
        LSuccess := ProcessCommand(LCommand);
      if LCommand.ScriptLabel > 0 then
        LConditions.AddOrSetValue(LCommand.ScriptLabel, LSuccess);
    end;
  finally
    LConditions.Free;
    LAvailable.Free;
  end;
end;

end.
