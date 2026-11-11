{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - the contracts of the music and of the       }
{  mixer (the parts of SDL_mixer that OpenXcom uses)                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   What the mixer has produced, for the programs that cannot listen: the bytes it was asked for and the root
  ///   mean square of the samples (a mixer that plays something has a value above zero)
  /// </summary>
  TXcomMixerStatistics = record
    RenderedBytes: Int64;
    /// <summary>Root mean square of all the samples rendered so far (0..32767)</summary>
    Rms: Double;
    /// <summary>The largest absolute sample</summary>
    Peak: Integer;
    SoundsStarted: Integer;
  end;

  /// <summary>Starting and stopping the mixer (Mix_OpenAudio, Mix_CloseAudio) and a way to see what it plays without a loudspeaker</summary>
  IXcomMixerMeter = interface
    ['{E4C71A06-8B3D-45F2-9D58-0A6F2B93C1E7}']
    /// <summary>Opens the output; false when there is none (the game goes on without sound)</summary>
    function Open: Boolean;
    procedure Close;
    function Statistics: TXcomMixerStatistics;
    /// <summary>The number of channels that play a sound now</summary>
    function ActiveChannels: Integer;
  end;

  /// <summary>
  ///   One piece of music of the game (Music and AdlibMusic): it makes its own samples, 16 bit stereo at the rate of
  ///   the mixer, when the mixer asks for them (Mix_HookMusic and the music callback of SDL_mixer)
  /// </summary>
  IXcomMusicTrack = interface
    ['{91C5E8A2-3B47-4D0F-A6E1-7F28D3B09C54}']
    /// <summary>The format as the audio options show it: Adlib, Wav...</summary>
    function Format: string;
    /// <summary>Music::play: starts from the beginning; ALoop as Mix_PlayMusic (-1 forever)</summary>
    procedure Start(ALoop: Integer);
    /// <summary>Music::stop: silences the track</summary>
    procedure Stop;
    function IsPlaying: Boolean;
    /// <summary>
    ///   Adds ABytes bytes (a multiple of 4) of samples to ABuffer (16 bit, left and right); AVolume is the volume of
    ///   the music (0..1, Game::volumeExponent of the option)
    /// </summary>
    procedure Render(ABuffer: PSmallInt; ABytes: Integer; AVolume: Single);
  end;

  /// <summary>What the music player asks of the mixer (the music part of SDL_mixer)</summary>
  IXcomMusicSink = interface
    ['{2D8A4F63-90B1-4E75-8C32-A5E1F7B6D084}']
    /// <summary>Mix_PlayMusic or Mix_HookMusic: the track plays from now on and the previous one stops</summary>
    procedure PlayTrack(const ATrack: IXcomMusicTrack; ALoop: Integer);
    /// <summary>Mix_HaltMusic: the track that plays stops</summary>
    procedure StopTrack;
    /// <summary>Mix_PauseMusic and Mix_ResumeMusic</summary>
    procedure PauseTrack(APaused: Boolean);
    function CurrentTrack: IXcomMusicTrack;
  end;

  /// <summary>The options of the game that the music reads (Options::mute, musicAlwaysLoop, preferredMusic)</summary>
  IXcomMusicSettings = interface
    ['{B3E07D19-5C84-42A6-91F0-6D2A8C45E7B3}']
    function Mute: Boolean;
    function AlwaysLoop: Boolean;
    /// <summary>MusicFormat of Options::preferredMusic (0 auto, 1 flac, 2 ogg, 3 mp3, 4 mod, 5 wav, 6 adlib, 7 gm, 8 midi)</summary>
    function PreferredFormat: Integer;
  end;

  /// <summary>Where the music player finds the songs of the Adlib containers (ADLIB.CAT, AINTRO.CAT)</summary>
  IXcomAdlibSongs = interface
    ['{7A41C0E5-D2F8-4B96-83A3-1E5B09D6C728}']
    /// <summary>The songs of ADLIB.CAT; 0 when there is none</summary>
    function Count: Integer;
    /// <summary>The song as AdlibMusic is given it (the name kept)</summary>
    function Song(AIndex: Integer): TBytes;
    /// <summary>The songs of AINTRO.CAT (the separate intro music); 0 when there is none</summary>
    function IntroCount: Integer;
    function IntroSong(AIndex: Integer): TBytes;
  end;

implementation

end.
