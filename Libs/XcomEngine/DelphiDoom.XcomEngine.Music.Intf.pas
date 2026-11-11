{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the music of the game as the states ask    }
{  for it (Mod::playMusic of OpenXcom)                                          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.Music.Intf;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Resources.Intf;

type
  /// <summary>The music of the game: what a state starts and stops (Mod::playMusic, Music::stop, pause, resume)</summary>
  IXcomMusicPlayer = interface
    ['{4E90B2D7-8A15-43C6-A1F0-52D8C7E36B91}']
    /// <summary>
    ///   The musics of the data in use (Mod::loadExtraResources): the previous ones stop and go away. Called when the
    ///   game adopts new data
    /// </summary>
    procedure Reload(const AResources: IXcomResources);
    /// <summary>
    ///   Mod::playMusic: starts the track unless it is already playing. With AId = 0 one of the tracks whose name
    ///   contains AName is chosen at random; otherwise the track AName + AId is played
    /// </summary>
    procedure PlayMusic(const AName: string; AId: Integer = 0);
    /// <summary>Music::stop</summary>
    procedure Stop;
    /// <summary>Music::pause: the game lost the focus</summary>
    procedure Pause;
    /// <summary>Music::resume</summary>
    procedure Resume;
    function IsPlaying: Boolean;
    /// <summary>Mix_GetMusicType as the audio options screen shows it ('Adlib' while no digital file plays)</summary>
    function CurrentFormat: string;
    /// <summary>The number of musics that loaded from the data (Mod::_musics.size())</summary>
    function LoadedCount: Integer;
  end;

implementation

end.
