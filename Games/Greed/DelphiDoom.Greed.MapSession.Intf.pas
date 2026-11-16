{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what the life of a map asks of the game          }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the calls that newmap,      }
{  LoadNewMap, resetengine, respawnplayer, SaveGame and LoadGame of utils.pas   }
{  make to the music, the screens, the pictures and the script of the map       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.MapSession.Intf;

interface

type
  /// <summary>
  ///   The parts of the game that the life of a map calls and that are not the spawner, the events, the archive or
  ///   the saved games: who builds the game gives them
  /// </summary>
  IGreedMapSessionHost = interface
    ['{B4E82C61-5D09-47A3-8F1E-62A9D0C3E7B5}']
    /// <summary>selectsong(map) of utils.pas: the music of a map starts</summary>
    procedure SelectSong(AMap: Integer);
    /// <summary>StopMusic of modplay.pas: the last map of an episode has no music of its own</summary>
    procedure StopMusic;
    /// <summary>MissionBriefing(map): the screens before a map of a new game</summary>
    procedure MissionBriefing(AMap: Integer);
    /// <summary>EndGame1, EndGame2 or EndGame3: the end of the episode 1, 2 or 3, shown instead of its last map</summary>
    procedure EndGame(AEpisode: Integer);
    /// <summary>
    ///   LoadTextures of utils.pas, at the end of LoadNewMap: the pictures of the walls and of the flats that the
    ///   new map uses, and the ones of the character of the player
    /// </summary>
    procedure LoadTextures;
    /// <summary>StartWait, UpdateWait and EndWait of menu.pas: the picture that turns while the game works</summary>
    procedure StartWait;
    procedure UpdateWait;
    procedure EndWait;
    /// <summary>ResetMouse of d_ints.pas, at the end of resetengine</summary>
    procedure ResetMouse;
    /// <summary>
    ///   bloodcount := 0 and metalcount := 0 of RF_ClearWorld (TGreedSpawner.ResetCounts): the session empties the
    ///   lists of the sprites and of the elevators itself
    /// </summary>
    procedure ResetSpawnCounts;
    /// <summary>clock of i_windows.pas: respawnplayer adds it to a random number to choose where the player starts</summary>
    function GetClock: Cardinal;
    /// <summary>lowresolution of raven.pas: a saved game made at the other resolution gets its scroll range changed</summary>
    function GetLowResolution: Boolean;
  end;

implementation

end.
