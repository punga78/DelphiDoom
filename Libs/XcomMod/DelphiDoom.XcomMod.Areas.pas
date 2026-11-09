{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - the geographic areas of countries and     }
{  regions (the longitude and latitude boxes of RuleCountry and RuleRegion)     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.Areas;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader;

const
  /// <summary>M_PI of the C++ headers</summary>
  XCOM_PI: Double = 3.14159265358979323846;

type
  /// <summary>The boxes (in radians) that a country or a region covers on the globe</summary>
  TXcomGlobeAreas = record
  public
    LonMin: TArray<Double>;
    LonMax: TArray<Double>;
    LatMin: TArray<Double>;
    LatMax: TArray<Double>;
    /// <summary>
    ///   Adds the boxes of a node field "areas": rows of [lonMin, lonMax, latMin, latMax] in degrees; a reversed
    ///   latitude pair is swapped. The C++ reads rows of any length (undefined for a short one): here a row with
    ///   less than four numbers is EXcomModException
    /// </summary>
    procedure Load(const ANode: IYamlNode);
    /// <summary>insideCountry / insideRegion: whether the point (radians) is in one of the boxes</summary>
    function Contains(ALongitude, ALatitude: Double): Boolean;
  end;

/// <summary>Deg2Rad of fmath.h</summary>
function XcomDegToRad(ADegrees: Double): Double;
/// <summary>Rad2Deg of fmath.h</summary>
function XcomRadToDeg(ARadians: Double): Double;

implementation

uses
  DelphiDoom.XcomMod.Types;

function XcomDegToRad(ADegrees: Double): Double;
var
  LProduct: Double;
begin
  // every operation is rounded to a double, as the SSE code of the C++ does (the x87 would keep extra bits)
  LProduct := ADegrees * XCOM_PI;
  Result := LProduct / 180.0;
end;

function XcomRadToDeg(ARadians: Double): Double;
var
  LQuotient: Double;
begin
  LQuotient := ARadians / XCOM_PI;
  Result := LQuotient * 180.0;
end;

{ TXcomGlobeAreas }

procedure TXcomGlobeAreas.Load(const ANode: IYamlNode);
var
  LRows, LEmpty: TArray<TArray<Double>>;
  LIndex, LLast: Integer;
  LSwap: Double;
begin
  SetLength(LEmpty, 0);
  LRows := TXcomNodeReader.ReadDoubleRows(ANode, 'areas', LEmpty);
  for LIndex := 0 to High(LRows) do
  begin
    if Length(LRows[LIndex]) < 4 then
      raise EXcomModException.Create('Xcom: an area needs four numbers');
    LLast := Length(LonMin);
    SetLength(LonMin, LLast + 1);
    SetLength(LonMax, LLast + 1);
    SetLength(LatMin, LLast + 1);
    SetLength(LatMax, LLast + 1);
    LonMin[LLast] := XcomDegToRad(LRows[LIndex][0]);
    LonMax[LLast] := XcomDegToRad(LRows[LIndex][1]);
    LatMin[LLast] := XcomDegToRad(LRows[LIndex][2]);
    LatMax[LLast] := XcomDegToRad(LRows[LIndex][3]);
    if LatMin[LLast] > LatMax[LLast] then
    begin
      LSwap := LatMin[LLast];
      LatMin[LLast] := LatMax[LLast];
      LatMax[LLast] := LSwap;
    end;
  end;
end;

function TXcomGlobeAreas.Contains(ALongitude, ALatitude: Double): Boolean;
var
  LIndex: Integer;
  LInLon, LInLat: Boolean;
begin
  for LIndex := 0 to High(LonMin) do
  begin
    if LonMin[LIndex] <= LonMax[LIndex] then
      LInLon := (ALongitude >= LonMin[LIndex]) and (ALongitude < LonMax[LIndex])
    else
      LInLon := ((ALongitude >= LonMin[LIndex]) and (ALongitude < XCOM_PI * 2.0)) or
        ((ALongitude >= 0) and (ALongitude < LonMax[LIndex]));
    // both poles can be in some regions: M_PI == latMax or -M_PI == latMin
    if ALatitude > 0 then
      LInLat := (ALatitude > LatMin[LIndex]) and (ALatitude <= LatMax[LIndex])
    else
      LInLat := (ALatitude >= LatMin[LIndex]) and (ALatitude < LatMax[LIndex]);
    if LInLon and LInLat then
      Exit(True);
  end;
  Result := False;
end;

end.
