{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a polygon of the globe (Polygon)          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.Polygon;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomMod.Areas;

type
  /// <summary>
  ///   A polygon of the world map (land or sea) with the points in polar coordinates (radians) and on the
  ///   screen, and the texture of the ground (Polygon). The C++ checks no index: a point outside the polygon
  ///   is EXcomModException here
  /// </summary>
  TXcomPolygon = class
  strict private
    FLatitude: TArray<Double>;
    FLongitude: TArray<Double>;
    FX: TArray<SmallInt>;
    FY: TArray<SmallInt>;
    FTexture: Integer;
    procedure CheckIndex(AIndex: Integer);
  public
    /// <param name="APoints">The number of points, all at zero</param>
    constructor Create(APoints: Integer);
    /// <summary>The copy constructor of Polygon</summary>
    constructor CreateCopy(const AOther: TXcomPolygon);
    /// <summary>
    ///   Polygon::load: the texture and then pairs longitude, latitude in degrees. The C++ reads an empty list
    ///   or a list with an even number of numbers out of its bounds (undefined): here EXcomModException
    /// </summary>
    procedure Load(const ANode: IYamlNode);
    function GetLatitude(AIndex: Integer): Double;
    procedure SetLatitude(AIndex: Integer; AValue: Double);
    function GetLongitude(AIndex: Integer): Double;
    procedure SetLongitude(AIndex: Integer; AValue: Double);
    function GetX(AIndex: Integer): SmallInt;
    procedure SetX(AIndex: Integer; AValue: SmallInt);
    function GetY(AIndex: Integer): SmallInt;
    procedure SetY(AIndex: Integer; AValue: SmallInt);
    property Texture: Integer read FTexture write FTexture;
    /// <summary>getPoints</summary>
    function Points: Integer;
  end;

implementation

const
  SBadPolygon = 'Xcom: a polygon needs a texture and pairs of coordinates';
  SBadPoint = 'Xcom: point of a polygon out of range';

{ TXcomPolygon }

constructor TXcomPolygon.Create(APoints: Integer);
begin
  inherited Create;
  if APoints < 0 then
    raise EXcomModException.Create(SBadPolygon);
  SetLength(FLatitude, APoints);
  SetLength(FLongitude, APoints);
  SetLength(FX, APoints);
  SetLength(FY, APoints);
end;

constructor TXcomPolygon.CreateCopy(const AOther: TXcomPolygon);
begin
  inherited Create;
  FLatitude := Copy(AOther.FLatitude);
  FLongitude := Copy(AOther.FLongitude);
  FX := Copy(AOther.FX);
  FY := Copy(AOther.FY);
  FTexture := AOther.FTexture;
end;

procedure TXcomPolygon.CheckIndex(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= Length(FLatitude)) then
    raise EXcomModException.Create(SBadPoint);
end;

procedure TXcomPolygon.Load(const ANode: IYamlNode);
var
  LCoordinates: TArray<Double>;
  LIndex, LPoint: Integer;
begin
  LCoordinates := TXcomNodeReader.DoublesOf(ANode);
  if (Length(LCoordinates) = 0) or (Length(LCoordinates) mod 2 = 0) then
    raise EXcomModException.Create(SBadPolygon);
  if (LCoordinates[0] >= 2147483648.0) or (LCoordinates[0] <= -2147483649.0) then
    raise EXcomModException.Create(SBadPolygon);
  SetLength(FLatitude, (Length(LCoordinates) - 1) div 2);
  SetLength(FLongitude, Length(FLatitude));
  SetLength(FX, Length(FLatitude));
  SetLength(FY, Length(FLatitude));
  FTexture := Trunc(LCoordinates[0]);
  LIndex := 1;
  while LIndex < Length(LCoordinates) do
  begin
    LPoint := (LIndex - 1) div 2;
    FLongitude[LPoint] := XcomDegToRad(LCoordinates[LIndex]);
    FLatitude[LPoint] := XcomDegToRad(LCoordinates[LIndex + 1]);
    FX[LPoint] := 0;
    FY[LPoint] := 0;
    Inc(LIndex, 2);
  end;
end;

function TXcomPolygon.GetLatitude(AIndex: Integer): Double;
begin
  CheckIndex(AIndex);
  Result := FLatitude[AIndex];
end;

procedure TXcomPolygon.SetLatitude(AIndex: Integer; AValue: Double);
begin
  CheckIndex(AIndex);
  FLatitude[AIndex] := AValue;
end;

function TXcomPolygon.GetLongitude(AIndex: Integer): Double;
begin
  CheckIndex(AIndex);
  Result := FLongitude[AIndex];
end;

procedure TXcomPolygon.SetLongitude(AIndex: Integer; AValue: Double);
begin
  CheckIndex(AIndex);
  FLongitude[AIndex] := AValue;
end;

function TXcomPolygon.GetX(AIndex: Integer): SmallInt;
begin
  CheckIndex(AIndex);
  Result := FX[AIndex];
end;

procedure TXcomPolygon.SetX(AIndex: Integer; AValue: SmallInt);
begin
  CheckIndex(AIndex);
  FX[AIndex] := AValue;
end;

function TXcomPolygon.GetY(AIndex: Integer): SmallInt;
begin
  CheckIndex(AIndex);
  Result := FY[AIndex];
end;

procedure TXcomPolygon.SetY(AIndex: Integer; AValue: SmallInt);
begin
  CheckIndex(AIndex);
  FY[AIndex] := AValue;
end;

function TXcomPolygon.Points: Integer;
begin
  Result := Length(FLatitude);
end;

end.
