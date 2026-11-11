{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - a battle in progress and its   }
{  engines (what the states of the battle share)                                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.Session.Intf;

interface

uses
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.TileEngine, DelphiDoom.XcomBattle.Pathfinding,
  DelphiDoom.XcomBattle.View.Intf, DelphiDoom.XcomBattle.Options, DelphiDoom.XcomBattle.BattlescapeGame,
  DelphiDoom.XcomBattleStates.Graphics.Intf;

type
  /// <summary>
  ///   The battle that is being played: the saved battle (owned by the session), the engine of the tiles and the
  ///   pathfinding around it, the rules and the pictures. The screens of the battle hold it; when the last one lets
  ///   go the battle is freed
  /// </summary>
  IXcomBattleSession = interface
    ['{3C71D9A4-5E20-4B86-9F13-176000000402}']
    function Battle: TXcomSavedBattleGame;
    function TileEngine: TXcomTileEngine;
    function Pathfinding: TXcomPathfinding;
    function Ruleset: TXcomRuleset;
    function Random: IXcomRandom;
    function Graphics: IXcomBattleGraphics;
    /// <summary>The saved game of the campaign the battle belongs to (not owned)</summary>
    function SavedGame: TXcomSavedGame;
    /// <summary>
    ///   new BattlescapeGame(save, parentState): the rules of the turn around the battle, with the AI and the reaction
    ///   fire attached; the caller owns it and frees it before letting the session go
    /// </summary>
    function CreateGame(const AView: IXcomBattleView; const AOptions: TXcomBattleOptions): TXcomBattlescapeGame;
    /// <summary>SavedGame::setBattleGame(battle) as the saved game stores it: the document of the battle is written again</summary>
    procedure StoreInSavedGame;
  end;

implementation

end.
