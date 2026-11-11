{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - who keeps the saved game that the      }
{  strategy screens use (Game::getSavedGame)                                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.SavedGameHolder.Intf;

interface

uses
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomMod.Random;

type
  /// <summary>
  ///   The saved game of the game in progress. The holder owns it (and what its objects need: the rules adapters),
  ///   a screen only borrows it for as long as the game lives
  /// </summary>
  IXcomSavedGameHolder = interface
    ['{E5C04B72-9A13-4D68-B2F7-31D8A6E0C459}']
    function SavedGame: TXcomSavedGame;
    /// <summary>The generator of the game (the RNG of the C++ that the screens use, for example for the cost of a research); nil if the holder has none</summary>
    function Random: IXcomRandom;
  end;

implementation

end.
