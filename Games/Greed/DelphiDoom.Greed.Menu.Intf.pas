{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what the menu asks to the game                   }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the calls of menu.pas to    }
{  utils.pas, raven.pas and m_defs.pas                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Menu.Intf;

interface

type
  /// <summary>
  ///   The game as the menu sees it. Each method is called at the point where menu.pas calls the routine or sets
  ///   the global of the original; the menu goes on (and closes itself where the original does) after the call
  /// </summary>
  IGreedMenuHost = interface
    ['{3B7C91E4-5A20-4D68-9F13-C6E8A0D4B725}']
    /// <summary>gameloaded: a game is being played (the save menu opens, the view size is applied at the end)</summary>
    function GameLoaded: Boolean;
    /// <summary>
    ///   newplayer(map, chartype, difficulty): the first map of the episode (0, 8 or 16), the character 0..4
    ///   (cyborg, lizard, moo, specimen, dominatrix) and the difficulty 5 (the first row of the menu) .. 0 (the
    ///   sixth). The menu has set its clock to 0 just before, as the original does with timecount
    /// </summary>
    procedure NewGame(AMap, ACharacter, ADifficulty: Integer);
    /// <summary>LoadGame(n): the saved game 0..9 (the menu does not check that it exists, as the original)</summary>
    procedure LoadGame(ASlot: Integer);
    /// <summary>SaveGame(n): the name is already written in the directory of the saved games</summary>
    procedure SaveGame(ASlot: Integer);
    /// <summary>quitgame := true: the player answered yes to "quit?" inside the menu</summary>
    procedure QuitGame;
    /// <summary>changelight := ambientlight and lighting := 1: the slider of the light has moved</summary>
    procedure AmbientLightChanged(ALight: Integer);
    /// <summary>
    ///   The loop of ChangeViewSize when the menu closes during a game: the view size that the settings ask
    ///   (0 the largest .. 4)
    /// </summary>
    procedure ApplyViewSize(ASize: Integer);
    /// <summary>M_SaveDefaults when the menu closes</summary>
    procedure SaveSettings;
    /// <summary>turnrate, moverate, fallrate and strafrate to 0 and ResetMouse</summary>
    procedure ResetControls;
  end;

implementation

end.
