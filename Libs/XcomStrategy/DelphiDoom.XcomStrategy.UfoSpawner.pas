{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - the UFOs that a mission sends and the   }
{  points they fly to (AlienMission::spawnUfo, getWaypoint, getLandPoint)      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.UfoSpawner;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleRegion,
  DelphiDoom.XcomMod.RuleAlienMission, DelphiDoom.XcomMod.RuleUfo, DelphiDoom.XcomMod.UfoTrajectory,
  DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.Waypoint, DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomSave.AlienMission, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomStrategy.Types,
  DelphiDoom.XcomStrategy.LandMap.Intf;

type
  /// <summary>
  ///   Makes the UFO that a wave of a mission sends: where it starts, where it goes first, at what altitude and
  ///   speed. The random generator and the land checks are injected. The region and the trajectory come from the
  ///   rules of the ruleset
  /// </summary>
  TXcomUfoSpawner = class
  strict private
    FRuleset: TXcomRuleset;
    FLand: IXcomLandMap;
    FRandom: IXcomRandom;
    procedure RaiseMissionError(const AMission: TXcomAlienMission; AZone: Cardinal; const ARegion: TXcomRuleRegion);
    function FindMarkedBase(const AGame: TXcomSavedGame; const ARegion: TXcomRuleRegion): TXcomBase;
  public
    constructor Create(const ARuleset: TXcomRuleset; const ALand: IXcomLandMap; const ARandom: IXcomRandom);
    /// <summary>The rules of a region by name; an unknown one is EXcomStrategyException (Mod::getRegion with error)</summary>
    function Region(const AName: string): TXcomRuleRegion;
    /// <summary>The altitude of a waypoint of a trajectory as the UFOs name it (UfoTrajectory::getAltitude)</summary>
    class function AltitudeAt(const ATrajectory: TXcomUfoTrajectory; AWaypoint: Integer): string; static;
    /// <summary>
    ///   getLandPoint: a point of the zone that is on land and in the region (100 tries, then the last one); a
    ///   zone of points (a city) is not checked
    /// </summary>
    procedure LandPoint(const AMission: TXcomAlienMission; const ARegion: TXcomRuleRegion; AZone: Cardinal;
      out ALongitude, ALatitude: Double);
    /// <summary>
    ///   getWaypoint: where the UFO goes at a waypoint of the trajectory: the mission site area when the wave is
    ///   the one that makes the site, a land point when the next waypoint is on the ground, else a random point
    /// </summary>
    procedure Waypoint(const AMission: TXcomAlienMission; const ATrajectory: TXcomUfoTrajectory;
      ANextWaypoint: Cardinal; const ARegion: TXcomRuleRegion; out ALongitude, ALatitude: Double);
    /// <summary>
    ///   spawnUfo: the new UFO of a wave (owned by the caller, who adds it to the game), or nil when the mission
    ///   does not send one (a supply mission with no base to supply, a rule that is not a UFO)
    /// </summary>
    function SpawnUfo(const AMission: TXcomAlienMission; const AGame: TXcomSavedGame; const AWave: TXcomMissionWave;
      const ATrajectory: TXcomUfoTrajectory): TXcomUfo;
  end;

implementation

const
  SNotFound = '%s not found';
  SZoneError = 'Error occurred while trying to determine waypoint for mission type: %s in region: %s, mission ' +
    'tried to find a waypoint in zone %d but this region only has zones valid up to %d.';
  SNoZones = 'Error occurred while trying to determine waypoint for mission type: %s in region: %s, region has ' +
    'no valid zones.';

{ TXcomUfoSpawner }

constructor TXcomUfoSpawner.Create(const ARuleset: TXcomRuleset; const ALand: IXcomLandMap;
  const ARandom: IXcomRandom);
begin
  inherited Create;
  if not Assigned(ARuleset) then
    raise EArgumentNilException.Create('ARuleset');
  FRuleset := ARuleset;
  FLand := ALand;
  FRandom := ARandom;
end;

function TXcomUfoSpawner.Region(const AName: string): TXcomRuleRegion;
begin
  Result := FRuleset.Regions.Find(AName);
  if not Assigned(Result) then
    raise EXcomStrategyException.CreateFmt(SNotFound, [AName]);
end;

class function TXcomUfoSpawner.AltitudeAt(const ATrajectory: TXcomUfoTrajectory; AWaypoint: Integer): string;
begin
  Result := TXcomUfo.ALTITUDE_STRINGS[ATrajectory.Waypoints[AWaypoint].Altitude];
end;

procedure TXcomUfoSpawner.RaiseMissionError(const AMission: TXcomAlienMission; AZone: Cardinal;
  const ARegion: TXcomRuleRegion);
begin
  if Length(ARegion.MissionZones) > 0 then
    raise EXcomStrategyException.CreateFmt(SZoneError, [AMission.Rule.MissionType, ARegion.RegionType, AZone,
      Length(ARegion.MissionZones) - 1])
  else
    raise EXcomStrategyException.CreateFmt(SNoZones, [AMission.Rule.MissionType, ARegion.RegionType]);
end;

procedure TXcomUfoSpawner.LandPoint(const AMission: TXcomAlienMission; const ARegion: TXcomRuleRegion;
  AZone: Cardinal; out ALongitude, ALatitude: Double);
var
  LArea: TXcomMissionArea;
  LTries: Integer;
begin
  if (AZone >= Cardinal(Length(ARegion.MissionZones))) or (Length(ARegion.MissionZones[AZone].Areas) = 0) then
    RaiseMissionError(AMission, AZone, ARegion);
  LArea := ARegion.MissionZones[AZone].Areas[0];
  // if a UFO wants to land on a city, let it
  if TXcomTarget.SameAngle(LArea.LonMin, LArea.LonMax) and TXcomTarget.SameAngle(LArea.LatMin, LArea.LatMax) then
    ARegion.GetRandomPoint(AZone, FRandom, ALongitude, ALatitude)
  else
  begin
    LTries := 0;
    repeat
      ARegion.GetRandomPoint(AZone, FRandom, ALongitude, ALatitude);
      Inc(LTries);
    until (FLand.InsideLand(ALongitude, ALatitude) and ARegion.IsInside(ALongitude, ALatitude)) or (LTries >= 100);
  end;
end;

procedure TXcomUfoSpawner.Waypoint(const AMission: TXcomAlienMission; const ATrajectory: TXcomUfoTrajectory;
  ANextWaypoint: Cardinal; const ARegion: TXcomRuleRegion; out ALongitude, ALatitude: Double);
var
  LWaveNumber: Integer;
  LZone: Cardinal;
  LArea: TXcomMissionArea;
begin
  LWaveNumber := Integer(AMission.NextWave) - 1;
  if LWaveNumber < 0 then
    LWaveNumber := AMission.Rule.WaveCount - 1;
  LZone := ATrajectory.Waypoints[ANextWaypoint].Zone;
  if LZone >= Cardinal(Length(ARegion.MissionZones)) then
    RaiseMissionError(AMission, LZone, ARegion);
  if (AMission.MissionSiteZone <> -1) and AMission.Rule.Waves[LWaveNumber].Objective and
    (LZone = Cardinal(AMission.Rule.SpawnZone)) then
  begin
    LArea := ARegion.MissionZones[AMission.Rule.SpawnZone].Areas[AMission.MissionSiteZone];
    ALongitude := LArea.LonMin;
    ALatitude := LArea.LatMin;
    Exit;
  end;
  if (ATrajectory.WaypointCount > Integer(ANextWaypoint) + 1) and
    (AltitudeAt(ATrajectory, ANextWaypoint + 1) = 'STR_GROUND') then
    LandPoint(AMission, ARegion, LZone, ALongitude, ALatitude)
  else
    ARegion.GetRandomPoint(LZone, FRandom, ALongitude, ALatitude);
end;

function TXcomUfoSpawner.FindMarkedBase(const AGame: TXcomSavedGame; const ARegion: TXcomRuleRegion): TXcomBase;
var
  LBase: TXcomBase;
begin
  for LBase in AGame.Bases do
    if ARegion.IsInside(LBase.Longitude, LBase.Latitude) and LBase.RetaliationTarget then
      Exit(LBase);
  Result := nil;
end;

function TXcomUfoSpawner.SpawnUfo(const AMission: TXcomAlienMission; const AGame: TXcomSavedGame;
  const AWave: TXcomMissionWave; const ATrajectory: TXcomUfoTrajectory): TXcomUfo;
var
  LUfoRule, LBattleshipRule: TXcomRuleUfo;
  LRegion: TXcomRuleRegion;
  LBase: TXcomBase;
  LAssault: TXcomUfoTrajectory;
  LLon, LLat: Double;
  LWaypoint: TXcomWaypoint;
  LUfo: TXcomUfo;
begin
  LUfoRule := FRuleset.Ufos.Find(AWave.UfoType);
  if AMission.Rule.Objective = TXcomRuleAlienMission.OBJECTIVE_RETALIATION then
  begin
    LRegion := Region(AMission.Region);
    LBase := FindMarkedBase(AGame, LRegion);
    if Assigned(LBase) then
    begin
      // a battleship straight for the XCOM base
      LBattleshipRule := FRuleset.Ufos.Find(AMission.Rule.SpawnUfo);
      if not Assigned(LBattleshipRule) then
        raise EXcomStrategyException.CreateFmt(SNotFound, [AMission.Rule.SpawnUfo]);
      LAssault := FRuleset.UfoTrajectories.Find(TXcomUfoTrajectory.RETALIATION_ASSAULT_RUN);
      if not Assigned(LAssault) then
        raise EXcomStrategyException.CreateFmt(SNotFound, [TXcomUfoTrajectory.RETALIATION_ASSAULT_RUN]);
      LUfo := TXcomUfo.Create(LBattleshipRule);
      try
        LUfo.SetMissionInfo(AMission, LAssault);
        if AltitudeAt(ATrajectory, 0) = 'STR_GROUND' then
          LandPoint(AMission, LRegion, ATrajectory.Waypoints[0].Zone, LLon, LLat)
        else
          LRegion.GetRandomPoint(ATrajectory.Waypoints[0].Zone, FRandom, LLon, LLat);
        LUfo.SetAltitude(AltitudeAt(LAssault, 0));
        LUfo.SetSpeed(LAssault.ApplySpeedPercentage(0, LBattleshipRule.MaxSpeed));
        LUfo.SetLongitude(LLon);
        LUfo.SetLatitude(LLat);
        LWaypoint := TXcomWaypoint.Create;
        LWaypoint.SetLongitude(LBase.Longitude);
        LWaypoint.SetLatitude(LBase.Latitude);
        LUfo.SetDestination(LWaypoint);
      except
        LUfo.Free;
        raise;
      end;
      Exit(LUfo);
    end;
  end
  else if AMission.Rule.Objective = TXcomRuleAlienMission.OBJECTIVE_SUPPLY then
  begin
    if not Assigned(LUfoRule) or (AWave.Objective and not Assigned(AMission.AlienBase)) then
      // no base to supply
      Exit(nil);
    // the destination is always an alien base
    LUfo := TXcomUfo.Create(LUfoRule);
    try
      LUfo.SetMissionInfo(AMission, ATrajectory);
      LRegion := Region(AMission.Region);
      if AltitudeAt(ATrajectory, 0) = 'STR_GROUND' then
        LandPoint(AMission, LRegion, ATrajectory.Waypoints[0].Zone, LLon, LLat)
      else
        LRegion.GetRandomPoint(ATrajectory.Waypoints[0].Zone, FRandom, LLon, LLat);
      LUfo.SetAltitude(AltitudeAt(ATrajectory, 0));
      LUfo.SetSpeed(ATrajectory.ApplySpeedPercentage(0, LUfoRule.MaxSpeed));
      LUfo.SetLongitude(LLon);
      LUfo.SetLatitude(LLat);
      LWaypoint := TXcomWaypoint.Create;
      if AltitudeAt(ATrajectory, 1) = 'STR_GROUND' then
      begin
        if AWave.Objective then
        begin
          // supply ships on supply missions land on bases, ignore the trajectory zone
          LLon := AMission.AlienBase.Longitude;
          LLat := AMission.AlienBase.Latitude;
        end
        else
          // other ships can land where they want
          LandPoint(AMission, LRegion, ATrajectory.Waypoints[1].Zone, LLon, LLat);
      end
      else
        LRegion.GetRandomPoint(ATrajectory.Waypoints[1].Zone, FRandom, LLon, LLat);
      LWaypoint.SetLongitude(LLon);
      LWaypoint.SetLatitude(LLat);
      LUfo.SetDestination(LWaypoint);
    except
      LUfo.Free;
      raise;
    end;
    Exit(LUfo);
  end;
  if not Assigned(LUfoRule) then
    Exit(nil);
  // spawn according to the sequence
  LUfo := TXcomUfo.Create(LUfoRule);
  try
    LUfo.SetMissionInfo(AMission, ATrajectory);
    LRegion := Region(AMission.Region);
    Waypoint(AMission, ATrajectory, 0, LRegion, LLon, LLat);
    LUfo.SetAltitude(AltitudeAt(ATrajectory, 0));
    if AltitudeAt(ATrajectory, 0) = 'STR_GROUND' then
      LUfo.SecondsRemaining := ATrajectory.GroundTimer * 5;
    LUfo.SetSpeed(ATrajectory.ApplySpeedPercentage(0, LUfoRule.MaxSpeed));
    LUfo.SetLongitude(LLon);
    LUfo.SetLatitude(LLat);
    LWaypoint := TXcomWaypoint.Create;
    Waypoint(AMission, ATrajectory, 1, LRegion, LLon, LLat);
    LWaypoint.SetLongitude(LLon);
    LWaypoint.SetLatitude(LLat);
    LUfo.SetDestination(LWaypoint);
  except
    LUfo.Free;
    raise;
  end;
  Result := LUfo;
end;

end.
