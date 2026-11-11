{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - where the buttons of the basescape go   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.Navigator.Intf;

interface

uses
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseFacility;

type
  /// <summary>The screens that the basescape opens for a base</summary>
  TXcomBaseScreen = (bsNewBase, bsBaseInfo, bsSoldiers, bsCrafts, bsFacilities, bsResearch, bsManufacture,
    bsTransfer, bsPurchase, bsSell, bsPsiTraining, bsAlienContainment, bsCraftInfo, bsDismantle);

  /// <summary>
  ///   Opens the screens of the buttons and of the facilities of the basescape (btnSoldiersClick, viewRightClick...). The
  ///   basescape does not know them: the program that composes the game gives the object that creates and pushes
  ///   each one; a screen that is not ported does nothing
  /// </summary>
  IXcomBasescapeNavigator = interface
    ['{B1C46E09-7A25-4D83-9F41-0E58D3A72B96}']
    /// <param name="AFacility">The facility that was clicked (dismantle, craft info), nil otherwise</param>
    /// <param name="AParent">The state that opens the screen (the basescape; nil when it is not one): screens that change
    /// what it shows ask it to refresh (State::init) and use its base view</param>
    procedure Open(AScreen: TXcomBaseScreen; ABase: TXcomBase; AFacility: TXcomBaseFacility;
      AParent: TXcomState = nil);
  end;

implementation

end.
