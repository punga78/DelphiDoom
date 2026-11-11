{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - what the aliens do as the time goes on: }
{  their missions, the sites, the bases and the search for the XCOM bases      }
{  (the alien parts of GeoscapeState::time10Minutes, time30Minutes and         }
{  time1Day)                                                                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.AlienPlanner;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleAlienMission,
  DelphiDoom.XcomMod.AlienDeployment, DelphiDoom.XcomMod.UfoTrajectory, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomSave.Ufo,
  DelphiDoom.XcomSave.AlienMission, DelphiDoom.XcomSave.AlienBase, DelphiDoom.XcomSave.MissionSite,
  DelphiDoom.XcomSave.Region, DelphiDoom.XcomStrategy.Types, DelphiDoom.XcomStrategy.Settings.Intf,
  DelphiDoom.XcomStrategy.Geography, DelphiDoom.XcomStrategy.MissionThinker;

type
  /// <summary>
  ///   The missions of the aliens think every half hour and the ones that are over are removed; the sites count
  ///   down and expire; every day the alien bases score and may start a supply mission; every ten minutes the
  ///   UFOs of the retaliation missions look for an XCOM base
  /// </summary>
  TXcomAlienPlanner = class
  strict private
    FGame: TXcomSavedGame;
    FRuleset: TXcomRuleset;
    FRandom: IXcomRandom;
    FThinker: TXcomMissionThinker;
    FSettings: IXcomStrategySettings;
    FCapacity: TXcomBaseCapacity;
    function DetectsBase(const AUfo: TXcomUfo; const ABase: TXcomBase): Boolean;
    function ProcessSite(const ASite: TXcomMissionSite): Boolean;
    procedure GenerateSupplyMission(const ABase: TXcomAlienBase);
  public
    /// <param name="AThinker">Makes the missions think (not owned)</param>
    constructor Create(const AGame: TXcomSavedGame; const ARuleset: TXcomRuleset; const ARandom: IXcomRandom;
      const AThinker: TXcomMissionThinker; const ASettings: IXcomStrategySettings);
    destructor Destroy; override;
    /// <summary>
    ///   The part of time10Minutes about retaliation: a base that a UFO of a retaliation mission finds becomes
    ///   a target (with the option of aggressive retaliation any UFO finds it)
    /// </summary>
    procedure ScanForBases;
    /// <summary>
    ///   The first part of time30Minutes: every mission thinks and the missions that are over are removed
    /// </summary>
    procedure ThinkMissions;
    /// <summary>The mission sites count down and the ones that ran out are removed (the end of time30Minutes)</summary>
    procedure ProcessSites;
    /// <summary>The alien base part of time1Day: the points of the bases and their supply missions</summary>
    procedure Daily;
  end;

implementation

{ TXcomAlienPlanner }

constructor TXcomAlienPlanner.Create(const AGame: TXcomSavedGame; const ARuleset: TXcomRuleset;
  const ARandom: IXcomRandom; const AThinker: TXcomMissionThinker; const ASettings: IXcomStrategySettings);
begin
  inherited Create;
  FGame := AGame;
  FRuleset := ARuleset;
  FRandom := ARandom;
  FThinker := AThinker;
  FSettings := ASettings;
  FCapacity := TXcomBaseCapacity.Create(ARuleset);
end;

destructor TXcomAlienPlanner.Destroy;
begin
  FCapacity.Free;
  inherited Destroy;
end;

function TXcomAlienPlanner.DetectsBase(const AUfo: TXcomUfo; const ABase: TXcomBase): Boolean;
begin
  Result := False;
  if AUfo.TrajectoryPoint <= 1 then
    Exit;
  if AUfo.Trajectory.Waypoints[AUfo.TrajectoryPoint].Zone = 5 then
    Exit;
  // only the UFOs of the retaliation missions scan for bases, but not the ones that attack a base, and not the
  // crashed ones, and only up to their sight range
  if ((AUfo.Mission.Rule.Objective <> TXcomRuleAlienMission.OBJECTIVE_RETALIATION) and
    not FSettings.AggressiveRetaliation) or (AUfo.Trajectory.Id = TXcomUfoTrajectory.RETALIATION_ASSAULT_RUN) or
    AUfo.IsCrashed or (ABase.Distance(AUfo) >= TXcomGeography.Nautical(AUfo.Rules.SightRange)) then
    Exit;
  Result := FRandom.Generate(0, 99) < FCapacity.DetectionChance(ABase);
end;

procedure TXcomAlienPlanner.ScanForBases;
var
  LBase, LOther: TXcomBase;
  LUfo: TXcomUfo;
  LFound: Boolean;
  LRegions: TArray<TXcomRegion>;
  LTargets: TArray<TXcomBase>;
  LIndex, LCount: Integer;
  LRegion: TXcomRegion;
  LSeen: Boolean;
begin
  if FSettings.AggressiveRetaliation then
  begin
    for LBase in FGame.Bases do
    begin
      LFound := False;
      for LUfo in FGame.Ufos do
        if DetectsBase(LUfo, LBase) then
        begin
          LFound := True;
          Break;
        end;
      if LFound then
        LBase.RetaliationTarget := True;
    end;
    Exit;
  end;
  // one base per region: the last that was found there
  SetLength(LRegions, 0);
  SetLength(LTargets, 0);
  for LBase in FGame.Bases do
  begin
    LFound := False;
    for LUfo in FGame.Ufos do
      if DetectsBase(LUfo, LBase) then
      begin
        LFound := True;
        Break;
      end;
    if not LFound then
      Continue;
    LRegion := TXcomGeography.LocateRegion(FGame, LBase.Longitude, LBase.Latitude);
    LCount := Length(LRegions);
    LSeen := False;
    for LIndex := 0 to LCount - 1 do
      if LRegions[LIndex] = LRegion then
      begin
        LTargets[LIndex] := LBase;
        LSeen := True;
      end;
    if not LSeen then
    begin
      SetLength(LRegions, LCount + 1);
      SetLength(LTargets, LCount + 1);
      LRegions[LCount] := LRegion;
      LTargets[LCount] := LBase;
    end;
  end;
  for LOther in LTargets do
    LOther.RetaliationTarget := True;
end;

function TXcomAlienPlanner.ProcessSite(const ASite: TXcomMissionSite): Boolean;
var
  LRemove: Boolean;
  LDeployment: TXcomAlienDeployment;
  LScore: Integer;
begin
  LRemove := ASite.SecondsRemaining < 30 * 60;
  if not LRemove then
    ASite.SecondsRemaining := ASite.SecondsRemaining - 30 * 60
  else
    // cheeky exploit: a site that a craft is going to does not expire
    LRemove := ASite.Followers.Count = 0;
  LDeployment := FRuleset.AlienDeployments.Find(ASite.Deployment.DeploymentType);
  if LRemove then
    LScore := LDeployment.DespawnPenalty
  else
    LScore := LDeployment.Points;
  TXcomGeography.AddAlienActivity(FGame, ASite.Longitude, ASite.Latitude, LScore);
  Result := LRemove;
end;

procedure TXcomAlienPlanner.ThinkMissions;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FGame.ActiveMissions.Count - 1 do
    FThinker.Think(FGame.ActiveMissions[LIndex], FGame);
  LIndex := 0;
  while LIndex < FGame.ActiveMissions.Count do
    if FGame.ActiveMissions[LIndex].IsOver then
      FGame.ActiveMissions.Delete(LIndex)
    else
      Inc(LIndex);
end;

procedure TXcomAlienPlanner.ProcessSites;
var
  LIndex: Integer;
begin
  LIndex := 0;
  while LIndex < FGame.MissionSites.Count do
    if ProcessSite(FGame.MissionSites[LIndex]) then
      FGame.MissionSites.Delete(LIndex)
    else
      Inc(LIndex);
end;

procedure TXcomAlienPlanner.GenerateSupplyMission(const ABase: TXcomAlienBase);
var
  LDeployment: TXcomAlienDeployment;
  LName: string;
  LRule: TXcomRuleAlienMission;
  LMission: TXcomAlienMission;
  LRegion: TXcomRegion;
begin
  LDeployment := FRuleset.AlienDeployments.Find(ABase.Deployment.DeploymentType);
  LName := LDeployment.GenMission.Choose(FRandom);
  LRule := FRuleset.AlienMissions.Find(LName);
  if Assigned(LRule) then
  begin
    if FRandom.Generate(0, 99) < LDeployment.GenMissionFrequency then
    begin
      LRegion := TXcomGeography.LocateRegion(FGame, ABase.Longitude, ABase.Latitude);
      if not Assigned(LRegion) then
        raise EXcomStrategyException.Create('An alien base is not inside any region');
      LMission := TXcomAlienMission.Create(LRule);
      FGame.ActiveMissions.Add(LMission);
      LMission.SetRegion(LRegion.Rules.RegionType, FRuleset.Regions.Find(LRegion.Rules.RegionType));
      LMission.SetId(FGame.GetId('ALIEN_MISSIONS'));
      LMission.Race := ABase.AlienRace;
      LMission.AlienBase := ABase;
      LMission.Start(0, FRandom);
    end;
  end
  else if LName <> '' then
    raise EXcomStrategyException.Create('Alien Base tried to generate undefined mission: ' + LName);
end;

procedure TXcomAlienPlanner.Daily;
var
  LBase: TXcomAlienBase;
  LIndex: Integer;
begin
  for LBase in FGame.AlienBases do
    TXcomGeography.AddAlienActivity(FGame, LBase.Longitude, LBase.Latitude,
      FRuleset.AlienDeployments.Find(LBase.Deployment.DeploymentType).Points);
  // the list of the bases does not change while the missions are made
  for LIndex := 0 to FGame.AlienBases.Count - 1 do
    GenerateSupplyMission(FGame.AlienBases[LIndex]);
end;

end.
