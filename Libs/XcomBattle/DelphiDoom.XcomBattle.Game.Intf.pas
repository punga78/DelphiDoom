{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - what a step asks of the game in       }
{  progress (the part of BattlescapeGame the steps use)                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.Game.Intf;

interface

uses
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame,
  DelphiDoom.XcomBattle.TileEngine, DelphiDoom.XcomBattle.Pathfinding, DelphiDoom.XcomBattle.Host.Intf,
  DelphiDoom.XcomBattle.View.Intf, DelphiDoom.XcomBattle.Options, DelphiDoom.XcomBattle.Action;

type
  /// <summary>
  ///   The game in progress as the steps (ExplosionBState, UnitDieBState...) see it: the saved battle, the
  ///   engines, the rules, the options, the screen, and the operations of BattlescapeGame they call
  /// </summary>
  IXcomBattlescapeGame = interface(IXcomBattleHost)
    ['{0B52D7E9-14A6-4C3F-8E70-9A2D6F1B53C8}']
    function Save: TXcomSavedBattleGame;
    function TileEngine: TXcomTileEngine;
    function Pathfinding: TXcomPathfinding;
    function Ruleset: TXcomRuleset;
    function Options: TXcomBattleOptions;
    function View: IXcomBattleView;
    /// <summary>getDepth</summary>
    function Depth: Integer;
    /// <summary>checkForCasualties</summary>
    procedure CheckForCasualties(const AMurderWeapon: TXcomBattleItem; const AMurderer: TXcomBattleUnit;
      AHiddenExplosion: Boolean = False; ATerrainExplosion: Boolean = False);
    /// <summary>dropItem</summary>
    procedure DropItem(const APosition: TXcomPosition; const AItem: TXcomBattleItem; ANewItem: Boolean = False;
      ARemoveItem: Boolean = False);
    /// <summary>convertUnit: a zombie becomes the unit it turns into</summary>
    function ConvertUnit(const AUnit: TXcomBattleUnit): TXcomBattleUnit;
    /// <summary>BattleUnit::knockOut(BattlescapeGame*): stuns the unit (a zombie is converted first)</summary>
    procedure KnockOut(const AUnit: TXcomBattleUnit);
    /// <summary>kneel: toggles the kneeling of a soldier; false when it could not (no time units, floating...)</summary>
    function Kneel(const AUnit: TXcomBattleUnit): Boolean;
    /// <summary>TileEngine::checkReactionFire: true when a unit reacted</summary>
    function CheckReactionFire(const AUnit: TXcomBattleUnit): Boolean;
    /// <summary>convertInfected: the units that carry a spawn unit and survive turn into it</summary>
    function ConvertInfected: Boolean;
    /// <summary>setupCursor: the cursor of the current action (and the actor of the action when not targeting)</summary>
    procedure SetupCursor;
    /// <summary>autoEndBattle</summary>
    procedure AutoEndBattle;
    /// <summary>checkForProximityGrenades</summary>
    function CheckForProximityGrenades(const AUnit: TXcomBattleUnit): Boolean;
    /// <summary>getCurrentAction</summary>
    function GetCurrentAction: TXcomBattleAction;
    /// <summary>_debugPlay: the player plays the aliens (debug mode)</summary>
    function GetDebugPlay: Boolean;
    /// <summary>The number of missions in the saved game (the mission of the kill statistics)</summary>
    function GetMissionCount: Integer;
  end;

implementation

end.
