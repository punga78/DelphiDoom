{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - where the options screens lead to            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.OptionsNavigator.Intf;

interface

uses
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomMenu.OptionsTypes;

type
  /// <summary>
  ///   What the options screens need to move between them and back to the game: the screen of a category (a
  ///   factory: the screens do not know each other) and the states to restart when the options are left
  ///   (OptionsBaseState::restart)
  /// </summary>
  IXcomOptionsNavigator = interface
    ['{D5A83C61-0E47-49B2-8F1A-6C7B20E9D354}']
    /// <summary>The screen of a category, nil when it is not available</summary>
    function CreateCategory(ACategory: TXcomOptionsCategory; AOrigin: TXcomOptionsOrigin;
      AHost: TXcomStateHost): TXcomState;
    /// <summary>OptionsBaseState::restart: the game goes back to what the options were opened from</summary>
    procedure Restart(AOrigin: TXcomOptionsOrigin; AHost: TXcomStateHost);
  end;

implementation

end.
