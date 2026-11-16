{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what the program of the game asks to its parts   }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the contracts between the   }
{  loop of startup, dointro and maingame, the screens and the host              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Application.Intf;

interface

type
  /// <summary>
  ///   The keys of the keyboard that the screens read (the menu, the title screens, the movies): each one by its
  ///   scan code of the original (SC_* of d_ints_h.pas, 0..127). The window gives the keys that are down, a script
  ///   gives the ones that it presses
  /// </summary>
  IGreedKeyboard = interface
    ['{5C2E8A31-6F07-4B94-A8D3-91E0B47C2F65}']
    /// <summary>True while the key with that scan code is down</summary>
    function IsDown(AScanCode: Integer): Boolean;
  end;

  /// <summary>Who wants to know that a tic of the program is about to run (a script that presses keys at a tic)</summary>
  IGreedTicListener = interface
    ['{A7D14E92-0B58-4C36-9F2A-3E85C61D07B4}']
    /// <summary>ATic is the number of the tic that runs now: the first is 1</summary>
    procedure TicStarting(ATic: Integer);
  end;

  /// <summary>The size of the view that the status bar shows (currentViewSize of the original, 0 .. 4)</summary>
  IGreedViewSize = interface
    ['{E3B90C47-82A1-4D65-B7F0-5A2C84D91E36}']
    procedure SetSize(ASize: Integer);
  end;

  /// <summary>
  ///   What the game asks of the program while it plays and that takes the screen for a while: the menus, the
  ///   briefings, the endings, the movies. Each call returns when the original routine would have returned
  /// </summary>
  IGreedScreens = interface
    ['{1F6A3D58-C92E-47B0-8A14-D07E5B93C2A6}']
    /// <summary>ShowMenu(0): the menu over the game; True if the player chose to quit</summary>
    function ShowMenu: Boolean;
    procedure ShowHelp;
    procedure ShowPause;
    /// <summary>ShowQuit: True if the answer was yes</summary>
    function ConfirmQuit: Boolean;
    procedure MissionBriefing(AMap: Integer);
    procedure EndGame(AEpisode: Integer);
    /// <summary>The movie of a SPAWNFLI zone (0..2) and its line of text; the screen stays until the level restarts</summary>
    procedure PlayFli(AMovie: Integer);
    procedure StartWait;
    procedure UpdateWait;
    procedure EndWait;
    /// <summary>EndLevel: the palette goes to black over the last picture, then the screen is cleared</summary>
    procedure FadeOutLevel;
    /// <summary>resetdisplay: what a movie left on the screen goes away</summary>
    procedure ReleaseScreen;
  end;

implementation

end.
