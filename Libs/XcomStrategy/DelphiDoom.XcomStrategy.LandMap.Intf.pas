{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - the land checks of the globe            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.LandMap.Intf;

interface

type
  /// <summary>
  ///   What the logic of the missions asks of the globe (Globe::insideLand): whether a point (radians) is inside
  ///   the land. The globe of the geoscape and the polygon map of the rules both give it, a fake does in tests
  /// </summary>
  IXcomLandMap = interface
    ['{6F2B4C1D-9A3E-4B75-8D10-176000000101}']
    function InsideLand(ALongitude, ALatitude: Double): Boolean;
  end;

implementation

end.
