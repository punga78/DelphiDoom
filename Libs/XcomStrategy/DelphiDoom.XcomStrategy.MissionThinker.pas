{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - the half hour of a mission              }
{  (AlienMission::think)                                                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.MissionThinker;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleRegion,
  DelphiDoom.XcomMod.RuleAlienMission, DelphiDoom.XcomMod.AlienDeployment, DelphiDoom.XcomMod.UfoTrajectory,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.AlienMission, DelphiDoom.XcomSave.Country,
  DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomStrategy.Types, DelphiDoom.XcomStrategy.LandMap.Intf,
  DelphiDoom.XcomStrategy.UfoSpawner, DelphiDoom.XcomStrategy.MissionSites;

type
  /// <summary>
  ///   What a mission does every half hour: counts down to the next wave, sends the UFO of the wave (or a mission
  ///   site), and when the last wave is out builds the alien base or makes a country sign a pact (think). The
  ///   spawners and the land checks are injected
  /// </summary>
  TXcomMissionThinker = class
  strict private
    FRuleset: TXcomRuleset;
    FRandom: IXcomRandom;
    FLand: IXcomLandMap;
    FSpawner: TXcomUfoSpawner;
    FSites: TXcomMissionSites;
    procedure PickBasePoint(const AMission: TXcomAlienMission; const ARegion: TXcomRuleRegion;
      out AArea: TXcomMissionArea; out ALongitude, ALatitude: Double);
  public
    /// <param name="ARuleset">Not owned</param>
    /// <param name="ASpawner">Makes the UFOs (not owned)</param>
    /// <param name="ASites">Makes the sites and bases (not owned)</param>
    constructor Create(const ARuleset: TXcomRuleset; const ALand: IXcomLandMap; const ARandom: IXcomRandom;
      const ASpawner: TXcomUfoSpawner; const ASites: TXcomMissionSites);
    /// <summary>
    ///   think: one step of the mission, every 30 minutes of game time. A UFO that is sent is added to the UFOs
    ///   of the game
    /// </summary>
    procedure Think(const AMission: TXcomAlienMission; const AGame: TXcomSavedGame);
  end;

implementation

{ TXcomMissionThinker }

constructor TXcomMissionThinker.Create(const ARuleset: TXcomRuleset; const ALand: IXcomLandMap;
  const ARandom: IXcomRandom; const ASpawner: TXcomUfoSpawner; const ASites: TXcomMissionSites);
begin
  inherited Create;
  FRuleset := ARuleset;
  FLand := ALand;
  FRandom := ARandom;
  FSpawner := ASpawner;
  FSites := ASites;
end;

procedure TXcomMissionThinker.PickBasePoint(const AMission: TXcomAlienMission; const ARegion: TXcomRuleRegion;
  out AArea: TXcomMissionArea; out ALongitude, ALatitude: Double);
var
  LAreas: TArray<TXcomMissionArea>;
  LTries: Integer;
begin
  LAreas := ARegion.MissionZones[AMission.Rule.SpawnZone].Areas;
  LTries := 0;
  repeat
    AArea := LAreas[FRandom.Generate(0, Length(LAreas) - 1)];
    ALongitude := FRandom.Generate(Min(AArea.LonMin, AArea.LonMax), Max(AArea.LonMin, AArea.LonMax));
    ALatitude := FRandom.Generate(Min(AArea.LatMin, AArea.LatMax), Max(AArea.LatMin, AArea.LatMax));
    Inc(LTries);
  until (FLand.InsideLand(ALongitude, ALatitude) and ARegion.IsInside(ALongitude, ALatitude)) or (LTries >= 100);
end;

procedure TXcomMissionThinker.Think(const AMission: TXcomAlienMission; const AGame: TXcomSavedGame);
var
  LWave: TXcomMissionWave;
  LTrajectory: TXcomUfoTrajectory;
  LUfo: TXcomUfo;
  LRegion: TXcomRuleRegion;
  LAreas: TArray<TXcomMissionArea>;
  LArea: TXcomMissionArea;
  LDeployment: TXcomAlienDeployment;
  LCountry: TXcomCountry;
  LZone: Integer;
  LLon, LLat: Double;
  LSpawnTimer: Cardinal;
begin
  if Integer(AMission.NextWave) >= AMission.Rule.WaveCount then
    Exit;
  if AMission.SpawnCountdown > 30 then
  begin
    AMission.SpawnCountdown := AMission.SpawnCountdown - 30;
    Exit;
  end;
  LWave := AMission.Rule.Waves[AMission.NextWave];
  LTrajectory := FRuleset.UfoTrajectories.Find(LWave.Trajectory);
  if not Assigned(LTrajectory) then
    raise EXcomStrategyException.CreateFmt('%s not found', [LWave.Trajectory]);
  LUfo := FSpawner.SpawnUfo(AMission, AGame, LWave, LTrajectory);
  if Assigned(LUfo) then
    // some missions may not spawn a UFO
    AGame.Ufos.Add(LUfo)
  else if (Assigned(FRuleset.AlienDeployments.Find(LWave.UfoType)) and not Assigned(FRuleset.Ufos.Find(LWave.UfoType))
    and (FRuleset.AlienDeployments.Find(LWave.UfoType).MarkerName <> '')) or
    ((AMission.Rule.Objective = TXcomRuleAlienMission.OBJECTIVE_SITE) and LWave.Objective) then
  begin
    // a mission site that we want to spawn directly, or at random according to our terrain
    if AMission.Rule.SpawnZone = -1 then
      LZone := Integer(LTrajectory.Waypoints[0].Zone)
    else
      LZone := AMission.Rule.SpawnZone;
    LAreas := FSpawner.Region(AMission.Region).MissionZones[LZone].Areas;
    if AMission.MissionSiteZone = -1 then
      LArea := LAreas[FRandom.Generate(0, Length(LAreas) - 1)]
    else
      LArea := LAreas[AMission.MissionSiteZone];
    LDeployment := FSites.SiteDeployment(AMission, LWave.UfoType, FRuleset.Globe.GetTexture(LArea.Texture));
    FSites.SpawnMissionSite(AMission, AGame, LDeployment, LArea);
  end;
  AMission.NextUfoCounter := AMission.NextUfoCounter + 1;
  if AMission.NextUfoCounter >= LWave.UfoCount then
  begin
    AMission.NextUfoCounter := 0;
    AMission.NextWave := AMission.NextWave + 1;
  end;
  if (AMission.Rule.Objective = TXcomRuleAlienMission.OBJECTIVE_INFILTRATION) and
    (Integer(AMission.NextWave) = AMission.Rule.WaveCount) then
  begin
    LRegion := FSpawner.Region(AMission.Region);
    for LCountry in AGame.Countries do
      if not LCountry.Pact and not LCountry.NewPact and
        LRegion.IsInside(LCountry.Rules.LabelLongitude, LCountry.Rules.LabelLatitude) then
      begin
        LCountry.NewPact := True;
        PickBasePoint(AMission, LRegion, LArea, LLon, LLat);
        FSites.SpawnAlienBase(AMission, AGame, LArea, LLon, LLat);
        Break;
      end;
    // infiltrations loop for ever
    AMission.NextWave := 0;
  end;
  if (AMission.Rule.Objective = TXcomRuleAlienMission.OBJECTIVE_BASE) and
    (Integer(AMission.NextWave) = AMission.Rule.WaveCount) then
  begin
    LRegion := FSpawner.Region(AMission.Region);
    PickBasePoint(AMission, LRegion, LArea, LLon, LLat);
    FSites.SpawnAlienBase(AMission, AGame, LArea, LLon, LLat);
  end;
  if Integer(AMission.NextWave) <> AMission.Rule.WaveCount then
  begin
    LSpawnTimer := AMission.Rule.Waves[AMission.NextWave].SpawnTimer div 30;
    AMission.SpawnCountdown := (LSpawnTimer div 2 + Cardinal(FRandom.Generate(0, Integer(LSpawnTimer)))) * 30;
  end;
end;

end.
