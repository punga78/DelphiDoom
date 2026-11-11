{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a line of the globe (Polyline)            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.Polyline;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomMod.Areas;

type
  /// <summary>A line of the world map (a border) with the points in polar coordinates, in radians (Polyline)</summary>
  TXcomPolyline = class
  strict private
    FLatitude: TArray<Double>;
    FLongitude: TArray<Double>;
    procedure CheckIndex(AIndex: Integer);
  public
    /// <param name="APoints">The number of points; the C++ leaves them uninitialized, here they are zero</param>
    constructor Create(APoints: Integer);
    /// <summary>
    ///   Polyline::load: pairs longitude, latitude in degrees. A list with an odd number of numbers is read out
    ///   of its bounds by the C++ (undefined): here EXcomModException
    /// </summary>
    procedure Load(const ANode: IYamlNode);
    function GetLatitude(AIndex: Integer): Double;
    procedure SetLatitude(AIndex: Integer; AValue: Double);
    function GetLongitude(AIndex: Integer): Double;
    procedure SetLongitude(AIndex: Integer; AValue: Double);
    /// <summary>getPoints</summary>
    function Points: Integer;
  end;

implementation

const
  SBadPolyline = 'Xcom: a line needs pairs of coordinates';
  SBadPoint = 'Xcom: point of a line out of range';

{ TXcomPolyline }

constructor TXcomPolyline.Create(APoints: Integer);
begin
  inherited Create;
  if APoints < 0 then
    raise EXcomModException.Create(SBadPolyline);
  SetLength(FLatitude, APoints);
  SetLength(FLongitude, APoints);
end;

procedure TXcomPolyline.CheckIndex(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= Length(FLatitude)) then
    raise EXcomModException.Create(SBadPoint);
end;

procedure TXcomPolyline.Load(const ANode: IYamlNode);
var
  LCoordinates: TArray<Double>;
  LIndex: Integer;
begin
  LCoordinates := TXcomNodeReader.DoublesOf(ANode);
  if Length(LCoordinates) mod 2 <> 0 then
    raise EXcomModException.Create(SBadPolyline);
  SetLength(FLatitude, Length(LCoordinates) div 2);
  SetLength(FLongitude, Length(FLatitude));
  LIndex := 0;
  while LIndex < Length(LCoordinates) do
  begin
    FLongitude[LIndex div 2] := XcomDegToRad(LCoordinates[LIndex]);
    FLatitude[LIndex div 2] := XcomDegToRad(LCoordinates[LIndex + 1]);
    Inc(LIndex, 2);
  end;
end;

function TXcomPolyline.GetLatitude(AIndex: Integer): Double;
begin
  CheckIndex(AIndex);
  Result := FLatitude[AIndex];
end;

procedure TXcomPolyline.SetLatitude(AIndex: Integer; AValue: Double);
begin
  CheckIndex(AIndex);
  FLatitude[AIndex] := AValue;
end;

function TXcomPolyline.GetLongitude(AIndex: Integer): Double;
begin
  CheckIndex(AIndex);
  Result := FLongitude[AIndex];
end;

procedure TXcomPolyline.SetLongitude(AIndex: Integer; AValue: Double);
begin
  CheckIndex(AIndex);
  FLongitude[AIndex] := AValue;
end;

function TXcomPolyline.Points: Integer;
begin
  Result := Length(FLatitude);
end;

end.
