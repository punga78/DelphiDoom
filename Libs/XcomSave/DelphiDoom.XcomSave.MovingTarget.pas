{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a target that moves over the globe     }
{  (MovingTarget)                                                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.MovingTarget;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.Areas,
  DelphiDoom.XcomSave.NodeWriter, DelphiDoom.XcomSave.Serialization, DelphiDoom.XcomSave.Target,
  DelphiDoom.XcomSave.FloatMode;

type
  /// <summary>
  ///   A target that goes to a destination at a speed in knots: crafts and UFOs (MovingTarget). The destination
  ///   is a reference (not owned) kept in step with the followers list of the destination. The motion uses the
  ///   trigonometry of System.Math (the C++ uses libm, so the last bit of a step can differ: the parity of
  ///   load and save does not depend on it). Whether the meeting point is used is a property (Options::meetingPoint)
  /// </summary>
  TXcomMovingTarget = class abstract(TXcomTarget)
  strict private
    FDestination: TXcomTarget;
    FSpeedLon: Double;
    FSpeedLat: Double;
    FSpeedRadian: Double;
    FMeetPointLon: Double;
    FMeetPointLat: Double;
    FSpeed: Integer;
    FMeetCalculated: Boolean;
    FMeetingPointEnabled: Boolean;
    procedure CalculateMeetPoint;
    procedure CalculateSpeedValues;
  strict protected
    /// <summary>
    ///   Sets the destination without the followers (the C++ of Ufo::load assigns _dest directly): the UFO
    ///   owns a waypoint that nobody follows
    /// </summary>
    procedure SetRawDestination(const ADestination: TXcomTarget);
    /// <summary>Forgets the destination without touching it (the destructor of Ufo frees the waypoint first)</summary>
    procedure ForgetDestination;
  public
    destructor Destroy; override;
    procedure Load(const ANode: IYamlNode); override;
    function Save: IYamlNode; override;
    /// <summary>getDestination</summary>
    property Destination: TXcomTarget read FDestination;
    /// <summary>
    ///   setDestination: leaves the followers of the old destination, joins those of the new one and makes
    ///   the followers of this target recalculate their meeting point
    /// </summary>
    procedure SetDestination(const ADestination: TXcomTarget);
    property Speed: Integer read FSpeed;
    property SpeedRadian: Double read FSpeedRadian;
    property SpeedLon: Double read FSpeedLon;
    property SpeedLat: Double read FSpeedLat;
    property MeetingPointEnabled: Boolean read FMeetingPointEnabled write FMeetingPointEnabled;
    /// <summary>calculateRadianSpeed: Nautical(speed) / 720</summary>
    class function CalculateRadianSpeed(ASpeed: Integer): Double; static;
    /// <summary>setSpeed</summary>
    procedure SetSpeed(ASpeed: Integer);
    /// <summary>calculateSpeed</summary>
    procedure CalculateSpeed; virtual;
    /// <summary>reachedDestination</summary>
    function ReachedDestination: Boolean;
    /// <summary>move: one step towards the meeting point (the destination)</summary>
    procedure Move;
    property MeetLatitude: Double read FMeetPointLat;
    property MeetLongitude: Double read FMeetPointLon;
    procedure ResetMeetPoint;
    property MeetCalculated: Boolean read FMeetCalculated;
  end;

implementation

{ TXcomMovingTarget }

destructor TXcomMovingTarget.Destroy;
begin
  SetDestination(nil);
  inherited Destroy;
end;

procedure TXcomMovingTarget.SetRawDestination(const ADestination: TXcomTarget);
begin
  FDestination := ADestination;
end;

procedure TXcomMovingTarget.ForgetDestination;
begin
  FDestination := nil;
end;

procedure TXcomMovingTarget.Load(const ANode: IYamlNode);
begin
  inherited Load(ANode);
  FSpeedLon := TXcomNodeReader.ReadDouble(ANode, 'speedLon', FSpeedLon);
  FSpeedLat := TXcomNodeReader.ReadDouble(ANode, 'speedLat', FSpeedLat);
  FSpeedRadian := TXcomNodeReader.ReadDouble(ANode, 'speedRadian', FSpeedRadian);
  FSpeed := TXcomNodeReader.ReadInteger(ANode, 'speed', FSpeed);
end;

function TXcomMovingTarget.Save: IYamlNode;
begin
  Result := inherited Save;
  if Assigned(FDestination) then
    TXcomNodeWriter.SetNode(Result, 'dest', FDestination.SaveId);
  TXcomNodeWriter.SetString(Result, 'speedLon', TXcomSerialization.SerializeDouble(FSpeedLon));
  TXcomNodeWriter.SetString(Result, 'speedLat', TXcomSerialization.SerializeDouble(FSpeedLat));
  TXcomNodeWriter.SetString(Result, 'speedRadian', TXcomSerialization.SerializeDouble(FSpeedRadian));
  TXcomNodeWriter.SetInteger(Result, 'speed', FSpeed);
end;

procedure TXcomMovingTarget.SetDestination(const ADestination: TXcomTarget);
var
  LFollower: TXcomTarget;
begin
  FMeetCalculated := False;
  if Assigned(FDestination) then
    FDestination.Followers.Remove(Self);
  FDestination := ADestination;
  if Assigned(FDestination) then
    FDestination.Followers.Add(Self);
  for LFollower in Followers do
    TXcomMovingTarget(LFollower).ResetMeetPoint;
  CalculateSpeed;
end;

class function TXcomMovingTarget.CalculateRadianSpeed(ASpeed: Integer): Double;
var
  LNautical: Double;
begin
  // Nautical(x) = x * (1 / 60.0) * (M_PI / 180.0)
  LNautical := ASpeed * (1 / 60.0);
  LNautical := LNautical * (XCOM_PI / 180.0);
  Result := LNautical / 720.0;
end;

procedure TXcomMovingTarget.SetSpeed(ASpeed: Integer);
var
  LFollower: TXcomTarget;
begin
  FSpeed := ASpeed;
  FSpeedRadian := CalculateRadianSpeed(FSpeed);
  for LFollower in Followers do
    TXcomMovingTarget(LFollower).ResetMeetPoint;
  CalculateSpeed;
end;

procedure TXcomMovingTarget.CalculateSpeed;
var
  LMode: TXcomFloatMode;
begin
  LMode := TXcomFloatMode.Enter;
  try
    CalculateSpeedValues;
  finally
    LMode.Leave;
  end;
end;

procedure TXcomMovingTarget.CalculateSpeedValues;
var
  LDeltaLon, LDeltaLat, LLength, LTerm1, LTerm2, LDifference, LArgument: Double;
begin
  CalculateMeetPoint;
  if Assigned(FDestination) then
  begin
    // every operation is rounded to a double (the precision of the C++ with SSE). The C++ of the reference build
    // is compiled for the x87 with -O3, whose extended intermediates cannot be reproduced: the last bit of a
    // speed can differ (the tests of the real saved games compare the speeds with a tolerance of 1e-15)
    LDifference := FMeetPointLon - Longitude;
    LTerm1 := Sin(LDifference);
    LTerm2 := Cos(FMeetPointLat);
    LDeltaLon := LTerm1 * LTerm2;
    LTerm1 := Cos(Latitude);
    LTerm1 := LTerm1 * Sin(FMeetPointLat);
    LTerm2 := Sin(Latitude);
    LTerm2 := LTerm2 * Cos(FMeetPointLat);
    LTerm2 := LTerm2 * Cos(LDifference);
    LDeltaLat := LTerm1 - LTerm2;
    LTerm1 := LDeltaLon * LDeltaLon;
    LTerm2 := LDeltaLat * LDeltaLat;
    LTerm1 := LTerm1 + LTerm2;
    LLength := Sqrt(LTerm1);
    LArgument := LDeltaLat / LLength;
    FSpeedLat := LArgument * FSpeedRadian;
    LArgument := LDeltaLon / LLength;
    LArgument := LArgument * FSpeedRadian;
    LTerm1 := Latitude + FSpeedLat;
    FSpeedLon := LArgument / Cos(LTerm1);
    // near-zero values: a division by zero gives not a number
    if IsNan(FSpeedLon) or IsNan(FSpeedLat) then
    begin
      FSpeedLon := 0;
      FSpeedLat := 0;
    end;
  end
  else
  begin
    FSpeedLon := 0;
    FSpeedLat := 0;
  end;
end;

function TXcomMovingTarget.ReachedDestination: Boolean;
begin
  if not Assigned(FDestination) then
    Exit(False);
  Result := SameAngle(FDestination.Longitude, Longitude) and SameAngle(FDestination.Latitude, Latitude);
end;

procedure TXcomMovingTarget.Move;
begin
  CalculateSpeed;
  if not Assigned(FDestination) then
    Exit;
  if Distance(FMeetPointLon, FMeetPointLat) > FSpeedRadian then
  begin
    SetLongitude(Longitude + FSpeedLon);
    SetLatitude(Latitude + FSpeedLat);
  end
  else
  begin
    if Distance(FDestination) > FSpeedRadian then
    begin
      SetLongitude(FMeetPointLon);
      SetLatitude(FMeetPointLat);
    end
    else
    begin
      SetLongitude(FDestination.Longitude);
      SetLatitude(FDestination.Latitude);
    end;
    ResetMeetPoint;
  end;
end;

procedure TXcomMovingTarget.CalculateMeetPoint;
var
  LTarget: TXcomMovingTarget;
  LDestination: TXcomTarget;
  LSpeedRatio, LNx, LNy, LNz, LNk, LPath, LDistance, LLonSign, LLatSign: Double;
begin
  if not FMeetingPointEnabled then
    FMeetCalculated := False;
  if FMeetCalculated then
    Exit;
  if Assigned(FDestination) then
  begin
    FMeetPointLat := FDestination.Latitude;
    FMeetPointLon := FDestination.Longitude;
  end
  else
  begin
    FMeetPointLat := Latitude;
    FMeetPointLon := Longitude;
  end;
  if (not Assigned(FDestination)) or (not FMeetingPointEnabled) or ReachedDestination then
    Exit;
  if not (FDestination is TXcomMovingTarget) then
    Exit;
  LTarget := TXcomMovingTarget(FDestination);
  if not Assigned(LTarget.Destination) then
    Exit;
  if SameAngle(LTarget.SpeedRadian, 0.0) then
    Exit;
  LDestination := LTarget.Destination;
  LSpeedRatio := FSpeedRadian / LTarget.SpeedRadian;
  LNx := Cos(LTarget.Latitude) * Sin(LTarget.Longitude) * Sin(LDestination.Latitude) -
    Sin(LTarget.Latitude) * Cos(LDestination.Latitude) * Sin(LDestination.Longitude);
  LNy := Sin(LTarget.Latitude) * Cos(LDestination.Latitude) * Cos(LDestination.Longitude) -
    Cos(LTarget.Latitude) * Cos(LTarget.Longitude) * Sin(LDestination.Latitude);
  LNz := Cos(LTarget.Latitude) * Cos(LDestination.Latitude) * Sin(LDestination.Longitude - LTarget.Longitude);
  LNk := FSpeedRadian / Sqrt(LNx * LNx + LNy * LNy + LNz * LNz);
  LNx := LNx * LNk;
  LNy := LNy * LNk;
  LNz := LNz * LNk;
  // do not search further than halfway across the globe
  LPath := 0;
  LDistance := 1;
  while (LPath < XCOM_PI) and (LDistance - LPath * LSpeedRatio > 0) and (LPath * LSpeedRatio < 1) do
  begin
    FMeetPointLat := FMeetPointLat + (LNx * Sin(FMeetPointLon) - LNy * Cos(FMeetPointLon));
    if Abs(FMeetPointLat) < XCOM_PI / 2 then
      FMeetPointLon := FMeetPointLon + (LNz - (LNx * Cos(FMeetPointLon) + LNy * Sin(FMeetPointLon)) *
        Tan(FMeetPointLat))
    else
      FMeetPointLon := FMeetPointLon + XCOM_PI;
    LDistance := ArcCos(Cos(Latitude) * Cos(FMeetPointLat) * Cos(FMeetPointLon - Longitude) +
      Sin(Latitude) * Sin(FMeetPointLat));
    LPath := LPath + FSpeedRadian;
    // a speed of zero never ends the loop: the C++ would hang
    if FSpeedRadian <= 0 then
      Break;
  end;
  LLonSign := Sign(FMeetPointLon);
  LLatSign := Sign(FMeetPointLat);
  while Abs(FMeetPointLon) > XCOM_PI do
    FMeetPointLon := FMeetPointLon - LLonSign * 2 * XCOM_PI;
  while Abs(FMeetPointLat) > XCOM_PI do
    FMeetPointLat := FMeetPointLat - LLatSign * 2 * XCOM_PI;
  if Abs(FMeetPointLat) > XCOM_PI / 2 then
  begin
    FMeetPointLat := LLatSign * Abs(2 * XCOM_PI - Abs(FMeetPointLat));
    FMeetPointLon := FMeetPointLon - LLonSign * XCOM_PI;
  end;
  FMeetCalculated := True;
end;

procedure TXcomMovingTarget.ResetMeetPoint;
begin
  FMeetCalculated := False;
end;

end.
