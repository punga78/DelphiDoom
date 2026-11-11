{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the screens that the           }
{  battlescape opens (the "new XState(...)" of BattlescapeState and of          }
{  BattlescapeGame) and the sounds of the battle                                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.Screens.Intf;

interface

uses
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.Action;

type
  /// <summary>
  ///   Makes the screens of the battle. The battlescape state only knows this interface: the factory of the library
  ///   knows the classes, the tests give a fake. Every function gives a state that the caller pushes (and the game
  ///   then owns), or nil when the screen does not exist: the button then does nothing
  /// </summary>
  IXcomBattleScreens = interface
    ['{3C71D9A4-5E20-4B86-9F13-176000000403}']
    /// <summary>ActionMenuState: the actions of the item of a hand; AParent is the battlescape state</summary>
    function ActionMenu(AParent: TXcomState; const AAction: TXcomBattleAction; AX, AY: Integer): TXcomState;
    /// <summary>
    ///   PrimeGrenadeState: the choice of the turns of the fuse. AInInventoryView: opened from the inventory, on
    ///   AGrenade (the action is then not used and can be nil)
    /// </summary>
    function PrimeGrenade(AParent: TXcomState; const AAction: TXcomBattleAction; AInInventoryView: Boolean;
      const AGrenade: TXcomBattleItem): TXcomState;
    /// <summary>MedikitState: the medi-kit of the action on the unit in front of its actor</summary>
    function Medikit(AParent: TXcomState; const ATarget: TXcomBattleUnit; const AAction: TXcomBattleAction)
      : TXcomState;
    /// <summary>ScannerState: the motion scanner of the action</summary>
    function Scanner(AParent: TXcomState; const AAction: TXcomBattleAction): TXcomState;
    /// <summary>UnitInfoState</summary>
    function UnitInfo(AParent: TXcomState; const AUnit: TXcomBattleUnit; AFromInventory, AMindProbe: Boolean)
      : TXcomState;
    /// <summary>InventoryState; ATimeUnits: moving an item costs time units (false in debug mode)</summary>
    function Inventory(AParent: TXcomState; ATimeUnits: Boolean): TXcomState;
    /// <summary>MiniMapState</summary>
    function MiniMap(AParent: TXcomState): TXcomState;
    /// <summary>PauseState(OPT_BATTLESCAPE)</summary>
    function Options(AParent: TXcomState): TXcomState;
    /// <summary>AbortMissionState</summary>
    function AbortMission(AParent: TXcomState): TXcomState;
    /// <summary>NextTurnState</summary>
    function NextTurn(AParent: TXcomState): TXcomState;
    /// <summary>InfoboxState: a message that goes away by itself</summary>
    function Infobox(AParent: TXcomState; const AMessage: string): TXcomState;
    /// <summary>InfoboxOKState: a message with an OK button</summary>
    function InfoboxOk(AParent: TXcomState; const AMessage: string): TXcomState;
    /// <summary>DebriefingState: the battle is over (the saved game is changed here)</summary>
    function Debriefing(AParent: TXcomState): TXcomState;
  end;

  /// <summary>
  ///   The sounds of the battle (Mod::getSoundByDepth()->play(-1, Map::getSoundAngle(position))). The program gives
  ///   the mixer; nil plays nothing
  /// </summary>
  IXcomBattleAudio = interface
    ['{3C71D9A4-5E20-4B86-9F13-176000000404}']
    /// <summary>Plays a sound of the battle on a free channel, panned by the angle (280 left, 360 middle, 440 right)</summary>
    procedure PlaySound(ADepth, ASound, AAngle: Integer);
    /// <summary>Sound::loop: the ambience of the battle on the reserved channel, until StopAmbience</summary>
    procedure LoopAmbience(ADepth, ASound: Integer);
    /// <summary>Sound::stopLoop</summary>
    procedure StopAmbience;
  end;

implementation

end.
