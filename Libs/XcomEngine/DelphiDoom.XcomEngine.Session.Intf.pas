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

  /// <summary>
  ///   What LoadGameState does when it has drawn its screen: loads the file as the saved game of the game and sets the
  ///   geoscape as the state (Game::setSavedGame and Game::setState). A file that cannot be loaded is an exception:
  ///   the message goes in the error window. The menu does not know the geoscape: the program gives the game this
  /// </summary>
  IXcomSavedGameLoader = interface
    ['{4A9E21C7-5D03-4B86-A1F8-6C27E0B93D16}']
    procedure LoadGame(const AFileName: string);
  end;

  /// <summary>
  ///   What the pause menu needs of the saved game in progress (Game::getSavedGame() of ListSaveState, SaveGameState
  ///   and AbandonGameState): its name and ironman flag, writing it to a file of the folder of the saved games, and
  ///   leaving it for the main menu. The menu does not know the saved game: the program gives the game this
  /// </summary>
  IXcomSavedGameSaver = interface
    ['{4A9E21C7-5D03-4B86-A1F8-6C27E0B93D17}']
    function IsIronman: Boolean;
    /// <summary>SavedGame::setName</summary>
    procedure SetName(const AName: string);
    function GetName: string;
    /// <summary>SavedGame::save: an error is an exception whose message the error window shows</summary>
    procedure SaveGame(const AFileName: string);
    /// <summary>Game::setState(MainMenuState) and Game::setSavedGame(0): the saved game in progress is gone</summary>
    procedure AbandonGame;
  end;

implementation

end.
