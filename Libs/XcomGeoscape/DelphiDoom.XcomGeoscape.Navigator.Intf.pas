{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - where the buttons of the geoscape go     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.Navigator.Intf;

interface

uses
  DelphiDoom.XcomGeoscape.Globe, DelphiDoom.XcomSave.Base, DelphiDoom.XcomBasescape.Navigator.Intf;

type
  /// <summary>
  ///   The screens that the geoscape opens (btnInterceptClick, btnBasesClick...). The geoscape does not know them: the
  ///   program that composes the game gives the object that creates and pushes each one. A screen that is not
  ///   ported does nothing
  /// </summary>
  IXcomGeoscapeNavigator = interface
    ['{2D8B6F40-1E93-4A57-B0C8-A7E35D1F9264}']
    procedure OpenIntercept;
    /// <summary>The globe is given because the bases screen can send the player to choose the site of a new base</summary>
    procedure OpenBases(AGlobe: TXcomGlobe);
    procedure OpenGraphs;
    procedure OpenUfopaedia;
    procedure OpenOptions;
    procedure OpenFunding;
    /// <summary>The basescape of a base (BasescapeState(base, globe)), from the popups of the events</summary>
    procedure OpenBase(ABase: TXcomBase; AGlobe: TXcomGlobe);
    /// <summary>A screen of a base that a popup opens (ManufactureState(base), ResearchState(base)...)</summary>
    procedure OpenBaseScreen(AScreen: TXcomBaseScreen; ABase: TXcomBase);
  end;

implementation

end.
