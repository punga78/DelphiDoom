{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - what the popups ask of the geoscape      }
{  (GeoscapeState::timerReset, getGlobe, popup)                                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.Control.Intf;

interface

uses
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomSave.Base, DelphiDoom.XcomGeoscape.Globe,
  DelphiDoom.XcomBasescape.Navigator.Intf, DelphiDoom.XcomEngine.Types;

type
  /// <summary>
  ///   What a popup of the geoscape does to the geoscape that opened it. The popups never see the geoscape state:
  ///   the state gives this object, the tests give a fake
  /// </summary>
  IXcomGeoscapeControl = interface
    ['{3C71D9A4-5E20-4B86-9F13-176000000201}']
    /// <summary>GeoscapeState::timerReset: the speed of the time goes back to 5 seconds</summary>
    procedure TimerReset;
    /// <summary>The globe of the geoscape (not owned)</summary>
    function Globe: TXcomGlobe;
    /// <summary>GeoscapeState::popup: the state is shown at the next think and the time stops; it is owned by the game then</summary>
    procedure Popup(AState: TXcomState);
    /// <summary>The basescape of a base (BasescapeState with the globe)</summary>
    procedure OpenBase(ABase: TXcomBase);
    /// <summary>A screen of the basescape for a base (ManufactureState, ResearchState...), through the navigator</summary>
    procedure OpenBaseScreen(AScreen: TXcomBaseScreen; ABase: TXcomBase);
    /// <summary>The palette of the geoscape (the popups of messages take it, as the C++ passes _palette)</summary>
    function Palette: PXcomColors;
  end;

  /// <summary>
  ///   Receives the geoscape when it is created: the simulation that is given to a geoscape can implement this to
  ///   open popups on it
  /// </summary>
  IXcomGeoscapeAware = interface
    ['{3C71D9A4-5E20-4B86-9F13-176000000202}']
    procedure AttachGeoscape(const AControl: IXcomGeoscapeControl);
  end;

implementation

end.
