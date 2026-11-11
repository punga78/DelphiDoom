{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - what the game keeps for the strategy       }
{  screens (the saved game of Game::getSavedGame) and how a new game starts     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.Session.Intf;

interface

type
  /// <summary>
  ///   What NewGameState does when OK is clicked (Mod::newSave, Game::setSavedGame, the geoscape and the screen of the
  ///   first base). The menu does not know the geoscape: the program gives the game the object that does it
  /// </summary>
  IXcomNewGameStarter = interface
    ['{4A9E21C7-5D03-4B86-A1F8-6C27E0B93D15}']
    /// <param name="ADifficulty">0 (beginner) to 4 (superhuman)</param>
    procedure StartNewGame(ADifficulty: Integer; AIronman: Boolean);
  end;

implementation

end.
