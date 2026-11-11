{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - what the tile engine and the steps    }
{  ask of the game in progress (the part of BattlescapeGame they use)           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.Host.Intf;

interface

uses
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.State.Intf;

type
  /// <summary>
  ///   The small part of BattlescapeGame that TileEngine and Projectile read: whether the player's panicking
  ///   units are handled, the action being carried out, the reserved time units and the list of steps
  ///   (SavedBattleGame::getBattleGame()). A fake gives it in the tests
  /// </summary>
  IXcomBattleHost = interface
    ['{A1D3F5B7-6C28-4E90-B4A1-7F0C2E8D5936}']
    /// <summary>getPanicHandled</summary>
    function PanicHandled: Boolean;
    /// <summary>getCurrentAction()->type</summary>
    function CurrentActionType: Integer;
    /// <summary>getReservedAction</summary>
    function ReservedAction: Integer;
    /// <summary>checkReservedTU: whether the unit may spend the time units without touching its reserve</summary>
    function CheckReservedTu(const AUnit: TXcomBattleUnit; ATimeUnits: Integer; AJustChecking: Boolean = False)
      : Boolean;
    /// <summary>statePushNext: second in the list (first, and started, when the list is empty)</summary>
    procedure StatePushNext(const AState: IXcomBattleState);
    /// <summary>statePushFront</summary>
    procedure StatePushFront(const AState: IXcomBattleState);
    /// <summary>statePushBack</summary>
    procedure StatePushBack(const AState: IXcomBattleState);
    /// <summary>popState</summary>
    procedure PopState;
  end;

implementation

end.
