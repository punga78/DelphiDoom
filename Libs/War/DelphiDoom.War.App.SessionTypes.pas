{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what a session of the program is made of          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.App.SessionTypes;

interface

uses
  System.SysUtils, DelphiDoom.GameHost.Types, DelphiDoom.War.Ui.Intf;

type
  /// <summary>How a game starts: it decides everything that the frames that follow do</summary>
  TWarSessionStart = record
    /// <summary>Where the generator of random numbers of the game starts</summary>
    Seed: Cardinal;
    /// <summary>1 humans, 2 orcs: the mission of the campaign that the game goes to at once; 0 = from the title</summary>
    Race: Byte;
    Mission: Byte;
  end;

  /// <summary>
  ///   The game as a session sees it: events in, frames out. The game of the scenes (TWarUiGame) is one; a fake is
  ///   another, in the tests
  /// </summary>
  IWarSessionGame = interface
    ['{5C7A2E90-D381-4B64-9F05-86A1E3B0C7D2}']
    /// <summary>An event of the window reaches the game as the adapter of the events makes it</summary>
    procedure Post(const AEvent: TGameHostEvent);
    /// <summary>One frame of the game and then the end of its input frame</summary>
    procedure RunFrame(ADelta: Single);
    /// <summary>The game asked to end (the menu of the map, the window)</summary>
    function QuitRequested: Boolean;
    /// <summary>The settings of the game: the volumes and the switches the sound follows</summary>
    function Settings: IWarGameSettings;
    /// <summary>The picture of the last frame: RGBA, Width x Height</summary>
    function Pixels: TArray<Byte>;
    function Width: Integer;
    function Height: Integer;
  end;

  /// <summary>
  ///   Makes a game at its start. It is called when the session begins and every time a saved game is loaded, so it
  ///   makes a new generator of random numbers and new everything. The requests are the program's: they go to the
  ///   services of the game, which hands them to the Save and Load buttons of the menus
  /// </summary>
  TWarGameBuilder = reference to function(const AStart: TWarSessionStart;
    const ARequests: IWarSessionRequests): IWarSessionGame;

implementation

end.
