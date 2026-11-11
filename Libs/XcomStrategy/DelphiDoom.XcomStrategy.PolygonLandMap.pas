{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - the land of the globe from the polygons }
{  of the rules (Globe::getPolygonFromLonLat, without the drawing)             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.PolygonLandMap;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.RuleGlobe, DelphiDoom.XcomMod.Polygon, DelphiDoom.XcomStrategy.LandMap.Intf;

type
  /// <summary>
  ///   Tells whether a point is inside one of the polygons of the globe rules: a point is on the land when it is
  ///   in a polygon of the rules (the polygons that are drawn as land). The rules must outlive the map
  /// </summary>
  TXcomPolygonLandMap = class(TInterfacedObject, IXcomLandMap)
  strict private
    FRules: TXcomRuleGlobe;
  public
    constructor Create(const ARules: TXcomRuleGlobe);
    /// <summary>getPolygonFromLonLat: the first polygon that has the point inside, nil if none</summary>
    function PolygonAt(ALongitude, ALatitude: Double): TXcomPolygon;
    function InsideLand(ALongitude, ALatitude: Double): Boolean;
  end;

implementation

{ TXcomPolygonLandMap }

constructor TXcomPolygonLandMap.Create(const ARules: TXcomRuleGlobe);
begin
  inherited Create;
  if not Assigned(ARules) then
    raise EArgumentNilException.Create('ARules');
  FRules := ARules;
end;

function TXcomPolygonLandMap.PolygonAt(ALongitude, ALatitude: Double): TXcomPolygon;
const
  Z_DISCARD = 0.75;
var
  LCosLat, LSinLat, LX, LY, LZ, LX2, LY2, LCLat, LCLon: Double;
  LPolygon: TXcomPolygon;
  LPoint, LNext: Integer;
  LOdd: Boolean;
begin
  Result := nil;
  LCosLat := Cos(ALatitude);
  LSinLat := Sin(ALatitude);
  for LPolygon in FRules.Polygons do
  begin
    LZ := 0;
    for LPoint := 0 to LPolygon.Points - 1 do
    begin
      LZ := LCosLat * Cos(LPolygon.GetLatitude(LPoint)) * Cos(LPolygon.GetLongitude(LPoint) - ALongitude) +
        LSinLat * Sin(LPolygon.GetLatitude(LPoint));
      if LZ < Z_DISCARD then
        Break;
    end;
    // discarded: a point of the polygon is too far from the position
    if LZ < Z_DISCARD then
      Continue;
    LOdd := False;
    LCLat := LPolygon.GetLatitude(0);
    LCLon := LPolygon.GetLongitude(0);
    LX := Cos(LCLat) * Sin(LCLon - ALongitude);
    LY := LCosLat * Sin(LCLat) - LSinLat * Cos(LCLat) * Cos(LCLon - ALongitude);
    for LPoint := 0 to LPolygon.Points - 1 do
    begin
      LNext := (LPoint + 1) mod LPolygon.Points;
      LCLat := LPolygon.GetLatitude(LNext);
      LCLon := LPolygon.GetLongitude(LNext);
      LX2 := Cos(LCLat) * Sin(LCLon - ALongitude);
      LY2 := LCosLat * Sin(LCLat) - LSinLat * Cos(LCLat) * Cos(LCLon - ALongitude);
      if ((LY > 0) <> (LY2 > 0)) and (0 < (LX2 - LX) * (0 - LY) / (LY2 - LY) + LX) then
        LOdd := not LOdd;
      LX := LX2;
      LY := LY2;
    end;
    if LOdd then
      Exit(LPolygon);
  end;
end;

function TXcomPolygonLandMap.InsideLand(ALongitude, ALatitude: Double): Boolean;
begin
  Result := Assigned(PolygonAt(ALongitude, ALatitude));
end;

end.
