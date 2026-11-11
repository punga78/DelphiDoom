{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - Globe::insideLand for the logic          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.GlobeLandMap;

interface

uses
  DelphiDoom.XcomGeoscape.Globe, DelphiDoom.XcomStrategy.LandMap.Intf;

type
  /// <summary>The globe of the geoscape as the land map that the logic asks (not owned; it must outlive the object)</summary>
  TXcomGlobeLandMap = class(TInterfacedObject, IXcomLandMap)
  strict private
    FGlobe: TXcomGlobe;
  public
    constructor Create(AGlobe: TXcomGlobe);
    function InsideLand(ALongitude, ALatitude: Double): Boolean;
  end;

implementation

{ TXcomGlobeLandMap }

constructor TXcomGlobeLandMap.Create(AGlobe: TXcomGlobe);
begin
  inherited Create;
  FGlobe := AGlobe;
end;

function TXcomGlobeLandMap.InsideLand(ALongitude, ALatitude: Double): Boolean;
begin
  Result := FGlobe.InsideLand(ALongitude, ALatitude);
end;

end.
