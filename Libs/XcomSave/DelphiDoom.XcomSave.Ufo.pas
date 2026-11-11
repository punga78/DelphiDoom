{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a UFO (Ufo)                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.Ufo;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.Areas, DelphiDoom.XcomMod.RuleUfo, DelphiDoom.XcomMod.UfoTrajectory, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomSave.NodeWriter, DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.MovingTarget,
  DelphiDoom.XcomSave.Waypoint, DelphiDoom.XcomSave.AlienMission, DelphiDoom.XcomSave.MissionLookup.Intf,
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Types;

type
  /// <summary>
  ///   A UFO of the aliens (Ufo). It owns the waypoint that is its destination; the mission and the trajectory
  ///   are references (the saved game and the ruleset own them). The names for the interface are not ported
  /// </summary>
  TXcomUfo = class(TXcomMovingTarget)
  public
    const
      /// <summary>UfoStatus</summary>
      STATUS_FLYING = 0;
      STATUS_LANDED = 1;
      STATUS_CRASHED = 2;
      STATUS_DESTROYED = 3;
      ALTITUDE_STRINGS: array[0..4] of string = ('STR_GROUND', 'STR_VERY_LOW', 'STR_LOW_UC', 'STR_HIGH_UC',
        'STR_VERY_HIGH');
  strict private
    FRules: TXcomRuleUfo;
    FCrashId: Integer;
    FLandId: Integer;
    FDamage: Integer;
    FDirection: string;
    FAltitude: string;
    FStatus: Integer;
    FSecondsRemaining: Cardinal;
    FInBattlescape: Boolean;
    FMission: TXcomAlienMission;
    FTrajectory: TXcomUfoTrajectory;
    FTrajectoryPoint: Cardinal;
    FDetected: Boolean;
    FHyperDetected: Boolean;
    FProcessedIntercept: Boolean;
    FShootingAt: Integer;
    FHitFrame: Integer;
    FFireCountdown: Integer;
    FEscapeCountdown: Integer;
    FShotDownBy: TXcomCraftId;
    procedure ReleaseWaypoint;
  public
    constructor Create(const ARules: TXcomRuleUfo);
    destructor Destroy; override;
    /// <summary>
    ///   load: the destination is a new waypoint at the "dest" position (or at the UFO); a missing status is
    ///   worked out from the damage and altitude. In a saved game with months passed the mission (by id) and
    ///   trajectory must exist or it is EXcomSaveException (corrupt save)
    /// </summary>
    procedure Load(const ANode: IYamlNode; const ARuleset: TXcomRuleset; const AMissions: IXcomMissionLookup);
      reintroduce;
    /// <summary>save(newBattle): a UFO of a saved game that is only a battle has no mission, trajectory and point</summary>
    function Save(ANewBattle: Boolean): IYamlNode; reintroduce; overload;
    function Save: IYamlNode; overload; override;
    function TargetType: string; override;
    function Marker: Integer; override;
    function MarkerName: string; override;
    function MarkerId: Integer; override;
    property Rules: TXcomRuleUfo read FRules write FRules;
    property Damage: Integer read FDamage;
    procedure SetDamage(ADamage: Integer);
    property Detected: Boolean read FDetected write FDetected;
    property HyperDetected: Boolean read FHyperDetected write FHyperDetected;
    property SecondsRemaining: Cardinal read FSecondsRemaining write FSecondsRemaining;
    property Direction: string read FDirection;
    property Altitude: string read FAltitude;
    property Status: Integer read FStatus write FStatus;
    property LandId: Integer read FLandId write FLandId;
    property CrashId: Integer read FCrashId write FCrashId;
    property InBattlescape: Boolean read FInBattlescape;
    property Mission: TXcomAlienMission read FMission;
    property Trajectory: TXcomUfoTrajectory read FTrajectory;
    property TrajectoryPoint: Cardinal read FTrajectoryPoint write FTrajectoryPoint;
    property ShotDownByCraftId: TXcomCraftId read FShotDownBy write FShotDownBy;
    property ShootingAt: Integer read FShootingAt write FShootingAt;
    property HitFrame: Integer read FHitFrame write FHitFrame;
    property FireCountdown: Integer read FFireCountdown write FFireCountdown;
    property EscapeCountdown: Integer read FEscapeCountdown write FEscapeCountdown;
    property InterceptionProcessed: Boolean read FProcessedIntercept write FProcessedIntercept;
    /// <summary>getAltitudeInt: the number of the altitude, -1 if unknown</summary>
    function AltitudeInt: Integer;
    /// <summary>setAltitude: flying above the ground; on the ground landed or crashed</summary>
    procedure SetAltitude(const AAltitude: string);
    function IsCrashed: Boolean;
    function IsDestroyed: Boolean;
    /// <summary>calculateSpeed: also the compass direction</summary>
    procedure CalculateSpeed; override;
    /// <summary>think: a step by status (flying moves; landed counts the seconds down; the ground time needs 5 s)</summary>
    procedure Think;
    procedure SetInBattlescape(AInBattle: Boolean);
    /// <summary>getVisibility: by size and altitude</summary>
    function Visibility: Integer;
    /// <summary>setMissionInfo: the mission counts one more UFO alive</summary>
    procedure SetMissionInfo(const AMission: TXcomAlienMission; const ATrajectory: TXcomUfoTrajectory);
    /// <summary>setDestination: the waypoint that was the destination is freed</summary>
    procedure SetDestination(const ADestination: TXcomTarget); reintroduce;
    function AlienRace: string;
    function MissionType: string;
  end;

implementation

{ TXcomUfo }

constructor TXcomUfo.Create(const ARules: TXcomRuleUfo);
begin
  inherited Create;
  FRules := ARules;
  FDirection := 'STR_NORTH';
  FAltitude := 'STR_HIGH_UC';
  FStatus := STATUS_FLYING;
end;

destructor TXcomUfo.Destroy;
begin
  if Assigned(FMission) then
    FMission.DecreaseLiveUfos;
  ReleaseWaypoint;
  inherited Destroy;
end;

procedure TXcomUfo.ReleaseWaypoint;
var
  LWaypoint: TXcomTarget;
begin
  LWaypoint := Destination;
  if LWaypoint is TXcomWaypoint then
  begin
    ForgetDestination;
    LWaypoint.Free;
  end;
end;

procedure TXcomUfo.Load(const ANode: IYamlNode; const ARuleset: TXcomRuleset; const AMissions: IXcomMissionLookup);
var
  LField, LStatus, LMission, LTrajectory: IYamlNode;
  LLon, LLat: Double;
  LWaypoint: TXcomWaypoint;
  LMissionId: Integer;
  LId: string;
begin
  inherited Load(ANode);
  FCrashId := TXcomNodeReader.ReadInteger(ANode, 'crashId', FCrashId);
  FLandId := TXcomNodeReader.ReadInteger(ANode, 'landId', FLandId);
  FDamage := TXcomNodeReader.ReadInteger(ANode, 'damage', FDamage);
  FAltitude := TXcomNodeReader.ReadString(ANode, 'altitude', FAltitude);
  FDirection := TXcomNodeReader.ReadString(ANode, 'direction', FDirection);
  FDetected := TXcomNodeReader.ReadBoolean(ANode, 'detected', FDetected);
  FHyperDetected := TXcomNodeReader.ReadBoolean(ANode, 'hyperDetected', FHyperDetected);
  FSecondsRemaining := TXcomNodeReader.ReadSize(ANode, 'secondsRemaining', FSecondsRemaining);
  FInBattlescape := TXcomNodeReader.ReadBoolean(ANode, 'inBattlescape', FInBattlescape);
  LLon := Longitude;
  LLat := Latitude;
  LField := TXcomNodeReader.Field(ANode, 'dest');
  if LField.IsDefined then
  begin
    if not TXcomNodeReader.Field(LField, 'lon').IsDefined or not TXcomNodeReader.Field(LField, 'lat').IsDefined then
      raise TXcomNodeReader.BadConversion(LField);
    LLon := TXcomNodeReader.Field(LField, 'lon').AsDouble;
    LLat := TXcomNodeReader.Field(LField, 'lat').AsDouble;
  end;
  ReleaseWaypoint;
  LWaypoint := TXcomWaypoint.Create;
  LWaypoint.SetLongitude(LLon);
  LWaypoint.SetLatitude(LLat);
  SetRawDestination(LWaypoint);
  LStatus := TXcomNodeReader.Field(ANode, 'status');
  if LStatus.IsDefined then
    FStatus := LStatus.AsInteger
  else if IsDestroyed then
    FStatus := STATUS_DESTROYED
  else if IsCrashed then
    FStatus := STATUS_CRASHED
  else if FAltitude = 'STR_GROUND' then
    FStatus := STATUS_LANDED
  else
    FStatus := STATUS_FLYING;
  if AMissions.MonthsPassed <> -1 then
  begin
    LMission := TXcomNodeReader.Field(ANode, 'mission');
    if not LMission.IsDefined then
      raise TXcomNodeReader.BadConversion(ANode);
    LMissionId := LMission.AsInteger;
    FMission := AMissions.FindMission(LMissionId);
    if not Assigned(FMission) then
      raise EXcomSaveException.Create('Unknown UFO mission, save file is corrupt.');
    LTrajectory := TXcomNodeReader.Field(ANode, 'trajectory');
    if not LTrajectory.IsDefined then
      raise TXcomNodeReader.BadConversion(ANode);
    LId := TXcomNodeReader.TextOf(LTrajectory);
    FTrajectory := ARuleset.UfoTrajectories.Find(LId);
    if not Assigned(FTrajectory) then
      raise EXcomSaveException.Create('Unknown UFO trajectory, save file is corrupt.');
    FTrajectoryPoint := TXcomNodeReader.ReadSize(ANode, 'trajectoryPoint', FTrajectoryPoint);
  end;
  FFireCountdown := TXcomNodeReader.ReadInteger(ANode, 'fireCountdown', FFireCountdown);
  FEscapeCountdown := TXcomNodeReader.ReadInteger(ANode, 'escapeCountdown', FEscapeCountdown);
  if FInBattlescape then
    SetSpeed(0);
end;

function TXcomUfo.Save: IYamlNode;
begin
  Result := Save(False);
end;

function TXcomUfo.Save(ANewBattle: Boolean): IYamlNode;
begin
  Result := inherited Save;
  TXcomNodeWriter.SetString(Result, 'type', FRules.UfoType);
  if FCrashId <> 0 then
    TXcomNodeWriter.SetInteger(Result, 'crashId', FCrashId)
  else if FLandId <> 0 then
    TXcomNodeWriter.SetInteger(Result, 'landId', FLandId);
  TXcomNodeWriter.SetInteger(Result, 'damage', FDamage);
  TXcomNodeWriter.SetString(Result, 'altitude', FAltitude);
  TXcomNodeWriter.SetString(Result, 'direction', FDirection);
  TXcomNodeWriter.SetInteger(Result, 'status', FStatus);
  if FDetected then
    TXcomNodeWriter.SetBoolean(Result, 'detected', True);
  if FHyperDetected then
    TXcomNodeWriter.SetBoolean(Result, 'hyperDetected', True);
  if FSecondsRemaining <> 0 then
    TXcomNodeWriter.SetString(Result, 'secondsRemaining', UIntToStr(FSecondsRemaining));
  if FInBattlescape then
    TXcomNodeWriter.SetBoolean(Result, 'inBattlescape', True);
  if not ANewBattle then
  begin
    if not Assigned(FMission) or not Assigned(FTrajectory) then
      raise EXcomSaveException.Create('Xcom: the UFO has no mission or trajectory');
    TXcomNodeWriter.SetInteger(Result, 'mission', FMission.Id);
    TXcomNodeWriter.SetString(Result, 'trajectory', FTrajectory.Id);
    TXcomNodeWriter.SetString(Result, 'trajectoryPoint', UIntToStr(FTrajectoryPoint));
  end;
  TXcomNodeWriter.SetInteger(Result, 'fireCountdown', FFireCountdown);
  TXcomNodeWriter.SetInteger(Result, 'escapeCountdown', FEscapeCountdown);
end;

function TXcomUfo.TargetType: string;
begin
  Result := 'STR_UFO';
end;

function TXcomUfo.MarkerName: string;
begin
  case FStatus of
    STATUS_LANDED: Result := 'STR_LANDING_SITE_';
    STATUS_CRASHED: Result := 'STR_CRASH_SITE_';
  else
    Result := 'STR_UFO_';
  end;
end;

function TXcomUfo.MarkerId: Integer;
begin
  case FStatus of
    STATUS_LANDED: Result := FLandId;
    STATUS_CRASHED: Result := FCrashId;
  else
    Result := Id;
  end;
end;

function TXcomUfo.Marker: Integer;
begin
  if not FDetected then
    Exit(-1);
  case FStatus of
    STATUS_LANDED:
      if FRules.LandMarker = -1 then Result := 3 else Result := FRules.LandMarker;
    STATUS_CRASHED:
      if FRules.CrashMarker = -1 then Result := 4 else Result := FRules.CrashMarker;
  else
    if FRules.Marker = -1 then Result := 2 else Result := FRules.Marker;
  end;
end;

procedure TXcomUfo.SetDamage(ADamage: Integer);
begin
  FDamage := ADamage;
  if FDamage < 0 then
    FDamage := 0;
  if IsDestroyed then
    FStatus := STATUS_DESTROYED
  else if IsCrashed then
    FStatus := STATUS_CRASHED;
end;

function TXcomUfo.AltitudeInt: Integer;
begin
  for Result := 0 to 4 do
    if ALTITUDE_STRINGS[Result] = FAltitude then
      Exit;
  Result := -1;
end;

procedure TXcomUfo.SetAltitude(const AAltitude: string);
begin
  FAltitude := AAltitude;
  if FAltitude <> 'STR_GROUND' then
    FStatus := STATUS_FLYING
  else if IsCrashed then
    FStatus := STATUS_CRASHED
  else
    FStatus := STATUS_LANDED;
end;

function TXcomUfo.IsCrashed: Boolean;
begin
  Result := FDamage > FRules.MaxDamage div 2;
end;

function TXcomUfo.IsDestroyed: Boolean;
begin
  Result := FDamage >= FRules.MaxDamage;
end;

procedure TXcomUfo.CalculateSpeed;
var
  LX, LY, LTheta: Double;
begin
  inherited CalculateSpeed;
  LX := SpeedLon;
  LY := -SpeedLat;
  // guards against the division by zero
  if SameAngle(LX, 0.0) or SameAngle(LY, 0.0) then
  begin
    if SameAngle(LX, 0.0) and SameAngle(LY, 0.0) then
      FDirection := 'STR_NONE_UC'
    else if SameAngle(LX, 0.0) then
    begin
      if LY > 0 then
        FDirection := 'STR_NORTH'
      else if LY < 0 then
        FDirection := 'STR_SOUTH';
    end
    else
    begin
      if LX > 0 then
        FDirection := 'STR_EAST'
      else if LX < 0 then
        FDirection := 'STR_WEST';
    end;
    Exit;
  end;
  LTheta := ArcTan2(LY, LX);
  LTheta := LTheta * 180.0 / XCOM_PI;
  if (LTheta < 22.5) and (LTheta > -22.5) then
    FDirection := 'STR_EAST'
  else if (LTheta < -22.5) and (LTheta > -67.5) then
    FDirection := 'STR_SOUTH_EAST'
  else if (LTheta < -67.5) and (LTheta > -112.5) then
    FDirection := 'STR_SOUTH'
  else if (LTheta < -112.5) and (LTheta > -157.5) then
    FDirection := 'STR_SOUTH_WEST'
  else if (LTheta < -157.5) or (LTheta > 157.5) then
    FDirection := 'STR_WEST'
  else if (LTheta < 157.5) and (LTheta > 112.5) then
    FDirection := 'STR_NORTH_WEST'
  else if (LTheta < 112.5) and (LTheta > 67.5) then
    FDirection := 'STR_NORTH'
  else
    FDirection := 'STR_NORTH_EAST';
end;

procedure TXcomUfo.Think;
begin
  case FStatus of
    STATUS_FLYING:
      begin
        Move;
        if ReachedDestination then
          SetSpeed(0);
      end;
    STATUS_LANDED:
      begin
        if FSecondsRemaining < 5 then
          raise EXcomSaveException.Create('Xcom: wrong time management of a landed UFO');
        Dec(FSecondsRemaining, 5);
      end;
    STATUS_CRASHED:
      FDetected := True;
  end;
end;

procedure TXcomUfo.SetInBattlescape(AInBattle: Boolean);
begin
  if AInBattle then
    SetSpeed(0);
  FInBattlescape := AInBattle;
end;

function TXcomUfo.Visibility: Integer;
var
  LSize: Integer;
begin
  LSize := 0;
  if FRules.Size = 'STR_VERY_SMALL' then
    LSize := -30
  else if FRules.Size = 'STR_SMALL' then
    LSize := -15
  else if FRules.Size = 'STR_MEDIUM_UC' then
    LSize := 0
  else if FRules.Size = 'STR_LARGE' then
    LSize := 15
  else if FRules.Size = 'STR_VERY_LARGE' then
    LSize := 30;
  Result := 0;
  if FAltitude = 'STR_GROUND' then
    Result := -30
  else if FAltitude = 'STR_VERY_LOW' then
    Result := LSize - 20
  else if FAltitude = 'STR_LOW_UC' then
    Result := LSize - 10
  else if FAltitude = 'STR_HIGH_UC' then
    Result := LSize
  else if FAltitude = 'STR_VERY_HIGH' then
    Result := LSize - 10;
end;

procedure TXcomUfo.SetMissionInfo(const AMission: TXcomAlienMission; const ATrajectory: TXcomUfoTrajectory);
begin
  if Assigned(FMission) or not Assigned(AMission) or not Assigned(ATrajectory) then
    raise EXcomSaveException.Create('Xcom: the mission of a UFO is set once, with a mission and a trajectory');
  FMission := AMission;
  FMission.IncreaseLiveUfos;
  FTrajectoryPoint := 0;
  FTrajectory := ATrajectory;
end;

procedure TXcomUfo.SetDestination(const ADestination: TXcomTarget);
var
  LOld: TXcomTarget;
begin
  LOld := Destination;
  if not (LOld is TXcomWaypoint) then
    LOld := nil;
  inherited SetDestination(ADestination);
  LOld.Free;
end;

function TXcomUfo.AlienRace: string;
begin
  Result := FMission.Race;
end;

function TXcomUfo.MissionType: string;
begin
  Result := FMission.Rule.MissionType;
end;

end.
