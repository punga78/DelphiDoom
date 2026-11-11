{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a city on the globe (City)             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.City;

interface

uses
  System.SysUtils, DelphiDoom.XcomSave.Target;

type
  /// <summary>
  ///   A city: a target with the name of a text of the language and a position, made from the areas of a region
  ///   that are a point with a name (City). The name for the user is the language text of CityName, which the
  ///   interface looks up (getName(Language) is not ported)
  /// </summary>
  TXcomCity = class(TXcomTarget)
  public
    /// <param name="AName">The key of the text of the language</param>
    /// <param name="ALongitude">In radians; SetLongitude keeps it between 0 and 2 pi</param>
    constructor Create(const AName: string; ALongitude, ALatitude: Double);
    /// <summary>getType: a city has no type (the C++ returns the empty text)</summary>
    function TargetType: string; override;
    /// <summary>getMarker: the marker of the cities</summary>
    function Marker: Integer; override;
    /// <summary>The key of the text of the name</summary>
    function CityName: string;
  end;

implementation

{ TXcomCity }

constructor TXcomCity.Create(const AName: string; ALongitude, ALatitude: Double);
begin
  inherited Create;
  Name := AName;
  // the C++ assigns the members directly: no wrapping of the angles
  SetLongitude(ALongitude);
  SetLatitude(ALatitude);
end;

function TXcomCity.TargetType: string;
begin
  Result := '';
end;

function TXcomCity.Marker: Integer;
begin
  Result := 8;
end;

function TXcomCity.CityName: string;
begin
  Result := Name;
end;

end.
