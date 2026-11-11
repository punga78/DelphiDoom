{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a target on the globe (Target)        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.Target;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomSave.Types,
  DelphiDoom.XcomSave.NodeWriter, DelphiDoom.XcomSave.Serialization;

type
  /// <summary>
  ///   Base class for the things on the globe: a point of longitude and latitude (radians), an id and a custom
  ///   name. Not ported: the list of the followers (MovingTarget, Craft) and the names that need Language
  ///   (getName, getDefaultName)
  /// </summary>
  TXcomTarget = class abstract
  strict private
    FLongitude: Double;
    FLatitude: Double;
    FId: Integer;
    FName: string;
    FFollowers: TList<TXcomTarget>;
    class function AreSame(ALeft, ARight: Double): Boolean; static;
  protected
    /// <summary>
    ///   The target that this one was following is going away: a craft returns to its base (the destructor of
    ///   Target makes the crafts that chase it return to their base); the others do nothing
    /// </summary>
    procedure FollowedTargetGone; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   getFollowers: the moving targets that go to this one (not owned). A target must be released from its
    ///   destination (SetDestination(nil)) before it is freed, as the destructor of MovingTarget does
    /// </summary>
    property Followers: TList<TXcomTarget> read FFollowers;
    /// <summary>The same angles test as the C++ (AreSame of fmath.h)</summary>
    class function SameAngle(ALeft, ARight: Double): Boolean; static;
    /// <summary>Loads the target; a name that is not a scalar raises EYamlBadConversion</summary>
    procedure Load(const ANode: IYamlNode); virtual;
    /// <summary>Saves the target: lon and lat as 17 digit text, the id and the name when they are not empty</summary>
    function Save: IYamlNode; virtual;
    /// <summary>saveId: the unique identifiers of the target (lon, lat, type, id)</summary>
    function SaveId: IYamlNode;
    /// <summary>getType: the type used in the saved game</summary>
    function TargetType: string; virtual; abstract;
    /// <summary>getMarker: the marker sprite on the globe, -1 if none</summary>
    function Marker: Integer; virtual; abstract;
    /// <summary>getMarkerName</summary>
    function MarkerName: string; virtual;
    /// <summary>getMarkerId</summary>
    function MarkerId: Integer; virtual;
    property Longitude: Double read FLongitude;
    property Latitude: Double read FLatitude;
    property Id: Integer read FId write FId;
    /// <summary>The custom name ('' if none: the language default is used by the caller)</summary>
    property Name: string read FName write FName;
    /// <summary>setLongitude: keeps the value between 0 and 2 pi (a value that never ends the loop is an error)</summary>
    procedure SetLongitude(AValue: Double);
    /// <summary>setLatitude: past a pole the target continues on the other side of the globe</summary>
    procedure SetLatitude(AValue: Double);
    /// <summary>getDistance: the great circle distance in radians</summary>
    function Distance(ALongitude, ALatitude: Double): Double; overload;
    function Distance(const AOther: TXcomTarget): Double; overload;
  end;

implementation

const
  SBadAngle = 'Xcom: the angle is not a finite number';

{ TXcomTarget }

class function TXcomTarget.AreSame(ALeft, ARight: Double): Boolean;
var
  LDifference, LScale: Double;
begin
  // fabs(l - r) <= DBL_EPSILON * max(1, max(|l|, |r|)), rounded to double at every step
  LDifference := Abs(ALeft - ARight);
  LScale := Max(1.0, Max(Abs(ALeft), Abs(ARight)));
  LScale := 2.2204460492503131E-16 * LScale;
  Result := LDifference <= LScale;
end;

constructor TXcomTarget.Create;
begin
  inherited Create;
  FFollowers := TList<TXcomTarget>.Create;
end;

destructor TXcomTarget.Destroy;
var
  LFollower: TXcomTarget;
begin
  // make sure no crafts are chasing this target (a copy: the crafts leave the list as they return)
  for LFollower in FFollowers.ToArray do
    LFollower.FollowedTargetGone;
  FFollowers.Free;
  inherited Destroy;
end;

procedure TXcomTarget.FollowedTargetGone;
begin
  // only a craft reacts
end;

class function TXcomTarget.SameAngle(ALeft, ARight: Double): Boolean;
begin
  Result := AreSame(ALeft, ARight);
end;

procedure TXcomTarget.Load(const ANode: IYamlNode);
var
  LField: IYamlNode;
begin
  FLongitude := TXcomNodeReader.ReadDouble(ANode, 'lon', FLongitude);
  FLatitude := TXcomNodeReader.ReadDouble(ANode, 'lat', FLatitude);
  FId := TXcomNodeReader.ReadInteger(ANode, 'id', FId);
  LField := TXcomNodeReader.Field(ANode, 'name');
  if LField.IsDefined then
    FName := TXcomNodeReader.TextOf(LField);
end;

function TXcomTarget.Save: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetString(Result, 'lon', TXcomSerialization.SerializeDouble(FLongitude));
  TXcomNodeWriter.SetString(Result, 'lat', TXcomSerialization.SerializeDouble(FLatitude));
  if FId <> 0 then
    TXcomNodeWriter.SetInteger(Result, 'id', FId);
  if FName <> '' then
    TXcomNodeWriter.SetString(Result, 'name', FName);
end;

function TXcomTarget.SaveId: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetString(Result, 'lon', TXcomSerialization.SerializeDouble(FLongitude));
  TXcomNodeWriter.SetString(Result, 'lat', TXcomSerialization.SerializeDouble(FLatitude));
  TXcomNodeWriter.SetString(Result, 'type', TargetType);
  TXcomNodeWriter.SetInteger(Result, 'id', FId);
end;

function TXcomTarget.MarkerName: string;
begin
  Result := TargetType + '_';
end;

function TXcomTarget.MarkerId: Integer;
begin
  Result := FId;
end;

procedure TXcomTarget.SetLongitude(AValue: Double);
const
  TwoPi: Double = 6.283185307179586;
begin
  if IsInfinite(AValue) or IsNan(AValue) then
    raise EXcomSaveException.Create(SBadAngle);
  FLongitude := AValue;
  while FLongitude < 0 do
    FLongitude := FLongitude + TwoPi;
  while FLongitude >= TwoPi do
    FLongitude := FLongitude - TwoPi;
end;

procedure TXcomTarget.SetLatitude(AValue: Double);
const
  Pi1: Double = 3.141592653589793;
  HalfPi: Double = 1.5707963267948966;
begin
  if IsNan(AValue) then
    raise EXcomSaveException.Create(SBadAngle);
  FLatitude := AValue;
  if FLatitude < -HalfPi then
  begin
    FLatitude := -Pi1 - FLatitude;
    SetLongitude(FLongitude + Pi1);
  end
  else if FLatitude > HalfPi then
  begin
    FLatitude := Pi1 - FLatitude;
    SetLongitude(FLongitude - Pi1);
  end;
end;

function TXcomTarget.Distance(ALongitude, ALatitude: Double): Double;
var
  LCosine: Double;
begin
  if AreSame(ALongitude, FLongitude) and AreSame(ALatitude, FLatitude) then
    Exit(0.0);
  LCosine := Cos(FLatitude) * Cos(ALatitude) * Cos(ALongitude - FLongitude) + Sin(FLatitude) * Sin(ALatitude);
  // acos of a value outside -1..1 is nan in C; the rounding of the sum can leave it just outside
  if (LCosine > 1.0) or (LCosine < -1.0) then
    Exit(NaN);
  Result := ArcCos(LCosine);
end;

function TXcomTarget.Distance(const AOther: TXcomTarget): Double;
begin
  Result := Distance(AOther.Longitude, AOther.Latitude);
end;

end.
