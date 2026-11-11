{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - a UFO of a mission that reached its     }
{  waypoint or lifts off (AlienMission::ufoReachedWaypoint, ufoLifting)        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.UfoWaypointHandler;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleAlienMission,
  DelphiDoom.XcomMod.RuleRegion, DelphiDoom.XcomMod.AlienDeployment, DelphiDoom.XcomMod.UfoTrajectory,
  DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.Waypoint, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.AlienMission, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Ufo,
  DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomStrategy.Types, DelphiDoom.XcomStrategy.LandMap.Intf,
  DelphiDoom.XcomStrategy.UfoSpawner, DelphiDoom.XcomStrategy.MissionSites;

type
  /// <summary>
  ///   What happens to the UFO of a mission at the end of a leg of its trajectory and when it leaves the ground:
  ///   it goes on to the next waypoint, lands, is replaced by a mission site or by the assault of a base, or is
  ///   destroyed; a UFO on the ground lifts off, or expires when it was shot down
  /// </summary>
  TXcomUfoWaypointHandler = class
  strict private
    FRuleset: TXcomRuleset;
    FLand: IXcomLandMap;
    FSpawner: TXcomUfoSpawner;
    FSites: TXcomMissionSites;
    function FindBaseAt(const AGame: TXcomSavedGame; ALongitude, ALatitude: Double): TXcomBase;
    procedure ReplaceWithSite(const AMission: TXcomAlienMission; const AUfo: TXcomUfo; const AGame: TXcomSavedGame;
      const ARegion: TXcomRuleRegion; const AWave: TXcomMissionWave; ACurrentWaypoint: Integer);
  public
    constructor Create(const ARuleset: TXcomRuleset; const ALand: IXcomLandMap; const ASpawner: TXcomUfoSpawner;
      const ASites: TXcomMissionSites);
    /// <summary>
    ///   ufoReachedWaypoint: the UFO sets its next waypoint; it has arrived at the end of its trajectory (it is
    ///   destroyed), lands (a timer on the ground when there is land, a mission site or the assault of a base)
    ///   or flies on at the speed of the waypoint
    /// </summary>
    procedure UfoReachedWaypoint(const AMission: TXcomAlienMission; const AUfo: TXcomUfo;
      const AGame: TXcomSavedGame);
    /// <summary>
    ///   ufoLifting: a landed UFO scores and takes off; a crashed one expires. A UFO that is flying or destroyed
    ///   is EXcomStrategyException (the C++ asserts)
    /// </summary>
    procedure UfoLifting(const AMission: TXcomAlienMission; const AUfo: TXcomUfo; const AGame: TXcomSavedGame);
  end;

implementation

const
  SNotFound = '%s not found';
  SUfoIsFlying = 'Ufo is already on the air!';
  SUfoDestroyed = 'UFO can''t fly!';

{ TXcomUfoWaypointHandler }

constructor TXcomUfoWaypointHandler.Create(const ARuleset: TXcomRuleset; const ALand: IXcomLandMap;
  const ASpawner: TXcomUfoSpawner; const ASites: TXcomMissionSites);
begin
  inherited Create;
  FRuleset := ARuleset;
  FLand := ALand;
  FSpawner := ASpawner;
  FSites := ASites;
end;

function TXcomUfoWaypointHandler.FindBaseAt(const AGame: TXcomSavedGame; ALongitude, ALatitude: Double): TXcomBase;
var
  LBase: TXcomBase;
begin
  for LBase in AGame.Bases do
    if TXcomTarget.SameAngle(LBase.Longitude, ALongitude) and TXcomTarget.SameAngle(LBase.Latitude, ALatitude) then
      Exit(LBase);
  Result := nil;
end;

procedure TXcomUfoWaypointHandler.ReplaceWithSite(const AMission: TXcomAlienMission; const AUfo: TXcomUfo;
  const AGame: TXcomSavedGame; const ARegion: TXcomRuleRegion; const AWave: TXcomMissionWave;
  ACurrentWaypoint: Integer);
var
  LArea: TXcomMissionArea;
  LDeployment: TXcomAlienDeployment;
  LSite: TXcomMissionSite;
  LFollowers: TList<TXcomTarget>;
  LFollower: TXcomTarget;
  LCraft: TXcomCraft;
begin
  // remove the UFO, replace it with a mission site
  FSites.AddScore(AMission, AGame, AUfo.Longitude, AUfo.Latitude);
  AUfo.Status := TXcomUfo.STATUS_DESTROYED;
  LArea := ARegion.MissionZones[AUfo.Trajectory.Waypoints[ACurrentWaypoint].Zone].Areas[AMission.MissionSiteZone];
  LDeployment := FSites.SiteDeployment(AMission, AMission.Rule.SiteType, FRuleset.Globe.GetTexture(LArea.Texture));
  LSite := FSites.SpawnMissionSite(AMission, AGame, LDeployment, LArea);
  if Assigned(LSite) then
  begin
    // the crafts that follow the UFO go to the site if they carry soldiers (the list changes as they go)
    LFollowers := TList<TXcomTarget>.Create;
    try
      LFollowers.AddRange(AUfo.Followers);
      for LFollower in LFollowers do
      begin
        if not (LFollower is TXcomCraft) then
          Continue;
        LCraft := TXcomCraft(LFollower);
        if LCraft.NumSoldiers(TXcomBase(LCraft.Base).Soldiers) <> 0 then
          LCraft.SetDestination(LSite);
      end;
    finally
      LFollowers.Free;
    end;
  end;
end;

procedure TXcomUfoWaypointHandler.UfoReachedWaypoint(const AMission: TXcomAlienMission; const AUfo: TXcomUfo;
  const AGame: TXcomSavedGame);
var
  LCurrent, LNext, LWaveNumber: Integer;
  LTrajectory: TXcomUfoTrajectory;
  LWave: TXcomMissionWave;
  LRegion: TXcomRuleRegion;
  LLon, LLat: Double;
  LWaypoint: TXcomWaypoint;
  LBase: TXcomBase;
begin
  LCurrent := Integer(AUfo.TrajectoryPoint);
  LNext := LCurrent + 1;
  LTrajectory := AUfo.Trajectory;
  LWaveNumber := Integer(AMission.NextWave) - 1;
  if LWaveNumber < 0 then
    LWaveNumber := AMission.Rule.WaveCount - 1;
  LWave := AMission.Rule.Waves[LWaveNumber];
  if LNext >= LTrajectory.WaypointCount then
  begin
    AUfo.Detected := False;
    AUfo.Status := TXcomUfo.STATUS_DESTROYED;
    Exit;
  end;
  AUfo.SetAltitude(TXcomUfoSpawner.AltitudeAt(LTrajectory, LNext));
  AUfo.TrajectoryPoint := Cardinal(LNext);
  LRegion := FSpawner.Region(AMission.Region);
  FSpawner.Waypoint(AMission, LTrajectory, Cardinal(LNext), LRegion, LLon, LLat);
  LWaypoint := TXcomWaypoint.Create;
  LWaypoint.SetLongitude(LLon);
  LWaypoint.SetLatitude(LLat);
  AUfo.SetDestination(LWaypoint);
  if AUfo.Altitude <> 'STR_GROUND' then
  begin
    if AUfo.LandId <> 0 then
      AUfo.LandId := 0;
    // set the speed for the next waypoint
    AUfo.SetSpeed(LTrajectory.ApplySpeedPercentage(LNext, AUfo.Rules.MaxSpeed));
    Exit;
  end;
  // the UFO landed
  if (AMission.MissionSiteZone <> -1) and LWave.Objective and
    (LTrajectory.Waypoints[LCurrent].Zone = Cardinal(AMission.Rule.SpawnZone)) then
    ReplaceWithSite(AMission, AUfo, AGame, LRegion, LWave, LCurrent)
  else if LTrajectory.Id = TXcomUfoTrajectory.RETALIATION_ASSAULT_RUN then
  begin
    // ignore what the trajectory might say, this is a base assault: the base is attacked
    AUfo.Detected := False;
    LBase := FindBaseAt(AGame, AUfo.Longitude, AUfo.Latitude);
    if not Assigned(LBase) then
    begin
      // only spawn the mission if the base is still there
      AUfo.Status := TXcomUfo.STATUS_DESTROYED;
      Exit;
    end;
    AUfo.SetDestination(LBase);
  end
  else if FLand.InsideLand(AUfo.Longitude, AUfo.Latitude) then
  begin
    // set the timer for the UFO on the ground
    AUfo.SecondsRemaining := LTrajectory.GroundTimer * 5;
    if AUfo.Detected and (AUfo.LandId = 0) then
      AUfo.LandId := AGame.GetId('STR_LANDING_SITE');
  end
  else
    // there is nothing to land on
    AUfo.SecondsRemaining := 5;
end;

procedure TXcomUfoWaypointHandler.UfoLifting(const AMission: TXcomAlienMission; const AUfo: TXcomUfo;
  const AGame: TXcomSavedGame);
begin
  case AUfo.Status of
    TXcomUfo.STATUS_FLYING:
      raise EXcomStrategyException.Create(SUfoIsFlying);
    TXcomUfo.STATUS_LANDED:
      begin
        // base missions only get points when they are completed
        if (AMission.Rule.Points > 0) and (AMission.Rule.Objective <> TXcomRuleAlienMission.OBJECTIVE_BASE) then
          FSites.AddScore(AMission, AGame, AUfo.Longitude, AUfo.Latitude);
        AUfo.SetAltitude('STR_VERY_LOW');
        AUfo.SetSpeed(AUfo.Trajectory.ApplySpeedPercentage(Integer(AUfo.TrajectoryPoint), AUfo.Rules.MaxSpeed));
      end;
    TXcomUfo.STATUS_CRASHED:
      begin
        // the mission expired
        AUfo.Detected := False;
        AUfo.Status := TXcomUfo.STATUS_DESTROYED;
      end;
    TXcomUfo.STATUS_DESTROYED:
      raise EXcomStrategyException.Create(SUfoDestroyed);
  end;
end;

end.
