{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - what a mission leaves on the globe:     }
{  mission sites, alien bases and the score (AlienMission::spawnMissionSite,   }
{  spawnAlienBase, addScore)                                                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.MissionSites;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleRegion,
  DelphiDoom.XcomMod.AlienDeployment, DelphiDoom.XcomMod.RuleAlienMission, DelphiDoom.XcomMod.Texture,
  DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.AlienMission,
  DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomSave.AlienBase, DelphiDoom.XcomSave.Region,
  DelphiDoom.XcomSave.Country, DelphiDoom.XcomStrategy.Types;

type
  /// <summary>
  ///   Puts on the globe what a mission sends once the UFOs are done: a mission site, an alien base, and gives
  ///   the score of the mission to the region and the country. The generator is injected
  /// </summary>
  TXcomMissionSites = class
  strict private
    FRuleset: TXcomRuleset;
    FRules: TXcomRulesetRules;
    FRandom: IXcomRandom;
  public
    /// <param name="ARuleset">Not owned</param>
    /// <param name="ARules">The rules as interfaces for the targets that are made (not owned)</param>
    constructor Create(const ARuleset: TXcomRuleset; const ARules: TXcomRulesetRules; const ARandom: IXcomRandom);
    /// <summary>The deployment by name; an unknown one is EXcomStrategyException (Mod::getDeployment with error)</summary>
    function Deployment(const AName: string): TXcomAlienDeployment;
    /// <summary>
    ///   The deployment of a site of a mission: the one that the type names, else a random one of the texture of
    ///   the area. A texture that is not there is the error of the C++
    /// </summary>
    function SiteDeployment(const AMission: TXcomAlienMission; const ATypeName: string; const ATexture: TXcomTexture)
      : TXcomAlienDeployment;
    /// <summary>
    ///   addScore: the points of the mission go to the first region and the first country that have the point
    ///   inside (an infiltration gives none: the pact is a special case)
    /// </summary>
    procedure AddScore(const AMission: TXcomAlienMission; const AGame: TXcomSavedGame; ALongitude, ALatitude: Double);
    /// <summary>
    ///   spawnMissionSite: a site at a random point of the area, with its duration; added to the game. nil if the
    ///   deployment is nil
    /// </summary>
    function SpawnMissionSite(const AMission: TXcomAlienMission; const AGame: TXcomSavedGame;
      const ADeployment: TXcomAlienDeployment; const AArea: TXcomMissionArea): TXcomMissionSite;
    /// <summary>spawnAlienBase: the base that the aliens build when the last UFO is sent</summary>
    procedure SpawnAlienBase(const AMission: TXcomAlienMission; const AGame: TXcomSavedGame;
      const AArea: TXcomMissionArea; ALongitude, ALatitude: Double);
  end;

implementation

const
  SNotFound = '%s not found';
  SSiteError = 'Error occurred while spawning mission site: %s';

{ TXcomMissionSites }

constructor TXcomMissionSites.Create(const ARuleset: TXcomRuleset; const ARules: TXcomRulesetRules;
  const ARandom: IXcomRandom);
begin
  inherited Create;
  if not Assigned(ARuleset) then
    raise EArgumentNilException.Create('ARuleset');
  FRuleset := ARuleset;
  FRules := ARules;
  FRandom := ARandom;
end;

function TXcomMissionSites.Deployment(const AName: string): TXcomAlienDeployment;
begin
  // Mod::getRule gives nil for an empty name even when the caller asks for the error
  if AName = '' then
    Exit(nil);
  Result := FRuleset.AlienDeployments.Find(AName);
  if not Assigned(Result) then
    raise EXcomStrategyException.CreateFmt(SNotFound, [AName]);
end;

function TXcomMissionSites.SiteDeployment(const AMission: TXcomAlienMission; const ATypeName: string;
  const ATexture: TXcomTexture): TXcomAlienDeployment;
begin
  Result := FRuleset.AlienDeployments.Find(ATypeName);
  if Assigned(Result) then
    Exit;
  if not Assigned(ATexture) then
    raise EXcomStrategyException.CreateFmt(SSiteError, [AMission.Rule.MissionType]);
  Result := Deployment(ATexture.GetRandomDeployment(FRandom));
end;

procedure TXcomMissionSites.AddScore(const AMission: TXcomAlienMission; const AGame: TXcomSavedGame; ALongitude,
  ALatitude: Double);
var
  LRegion: TXcomRegion;
  LCountry: TXcomCountry;
begin
  // pact score is a special case
  if AMission.Rule.Objective = TXcomRuleAlienMission.OBJECTIVE_INFILTRATION then
    Exit;
  for LRegion in AGame.Regions do
    if LRegion.Rules.IsInside(ALongitude, ALatitude) then
    begin
      LRegion.AddActivityAlien(AMission.Rule.Points);
      Break;
    end;
  for LCountry in AGame.Countries do
    if LCountry.Rules.IsInside(ALongitude, ALatitude) then
    begin
      LCountry.AddActivityAlien(AMission.Rule.Points);
      Break;
    end;
end;

function TXcomMissionSites.SpawnMissionSite(const AMission: TXcomAlienMission; const AGame: TXcomSavedGame;
  const ADeployment: TXcomAlienDeployment; const AArea: TXcomMissionArea): TXcomMissionSite;
begin
  if not Assigned(ADeployment) then
    Exit(nil);
  Result := TXcomMissionSite.Create(FRules.Mission(AMission.Rule.MissionType),
    FRules.Deployment(ADeployment.DeploymentType));
  try
    Result.SetLongitude(FRandom.Generate(AArea.LonMin, AArea.LonMax));
    Result.SetLatitude(FRandom.Generate(AArea.LatMin, AArea.LatMax));
    Result.Id := AGame.GetId(ADeployment.MarkerName);
    Result.SecondsRemaining := Cardinal(FRandom.Generate(ADeployment.DurationMin, ADeployment.DurationMax) * 3600);
    Result.AlienRace := AMission.Race;
    Result.Texture := AArea.Texture;
    Result.City := AArea.Name;
    AGame.MissionSites.Add(Result);
  except
    Result.Free;
    raise;
  end;
end;

procedure TXcomMissionSites.SpawnAlienBase(const AMission: TXcomAlienMission; const AGame: TXcomSavedGame;
  const AArea: TXcomMissionArea; ALongitude, ALatitude: Double);
var
  LDeployment: TXcomAlienDeployment;
  LTexture: TXcomTexture;
  LBase: TXcomAlienBase;
begin
  // once the last UFO is spawned, the aliens build their base
  LTexture := FRuleset.Globe.GetTexture(AArea.Texture);
  if Assigned(FRuleset.AlienDeployments.Find(AMission.Rule.SiteType)) then
    LDeployment := FRuleset.AlienDeployments.Find(AMission.Rule.SiteType)
  else if Assigned(LTexture) and (LTexture.Deployments.Count > 0) then
    LDeployment := Deployment(LTexture.GetRandomDeployment(FRandom))
  else
    LDeployment := Deployment('STR_ALIEN_BASE_ASSAULT');
  // the C++ reads through a null pointer here
  if not Assigned(LDeployment) then
    raise EXcomStrategyException.CreateFmt(SNotFound, ['deployment of an alien base']);
  LBase :=TXcomAlienBase.Create(FRules.Deployment(LDeployment.DeploymentType));
  try
    LBase.AlienRace := AMission.Race;
    LBase.Id := AGame.GetId(LDeployment.MarkerName);
    LBase.SetLongitude(ALongitude);
    LBase.SetLatitude(ALatitude);
    AGame.AlienBases.Add(LBase);
  except
    LBase.Free;
    raise;
  end;
  AddScore(AMission, AGame, LBase.Longitude, LBase.Latitude);
end;

end.
