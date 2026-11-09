{******************************************************************************}
{                                                                              }
{  DelphiDoom: X-COM Adlib player - the contracts                               }
{                                                                              }
{  Port of adlplayer.cpp and AdlibMusic.cpp (X-COM Adlib Player by Volutar,     }
{  OpenXcom, GPL v3 or later): see Libs\Opl\README.md for the license           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAdlib.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>adlib_reg: where the sequencer writes the registers of the Adlib</summary>
  IXcomAdlibRegisterWriter = interface
    ['{5E8A3D17-94B2-4C60-A1F5-7B0E26C93D84}']
    /// <summary>One register of the Adlib (both chips: the second one gets the transposed copy)</summary>
    procedure WriteRegister(ARegister: Integer; AValue: Integer);
  end;

  /// <summary>The sequencer of adlplayer.cpp (func_*): the song, the tracks, the channels, the tempo, the fade</summary>
  IXcomAdlibSequencer = interface
    ['{B2D96F40-1A7E-4358-8C3B-E5094F7A1D62}']
    /// <summary>init_music_data of a song; ALength is what the C is given as the length of the data</summary>
    procedure Setup(const ASong: TBytes; ALength: Integer);
    /// <summary>func_play_tick: one tick of the music according to the tempo</summary>
    procedure Tick;
    /// <summary>func_mute: stops the music and silences every channel</summary>
    procedure Mute;
    /// <summary>func_fade: the volume goes down with each tick, then the music stops</summary>
    procedure Fade;
    function IsPlaying: Boolean;
    /// <summary>func_set_music_tempo: the tick increment (the larger, the slower)</summary>
    procedure SetTempo(AValue: Integer);
    /// <summary>func_set_music_volume: 0..127</summary>
    procedure SetVolume(AValue: Integer);
    function Polyphony: Integer;
    procedure SaveState(AIndex: Integer);
    procedure LoadState(AIndex: Integer);
  end;

  /// <summary>The music a game keeps in its Adlib container (ADLIB.CAT, GM.CAT)</summary>
  IXcomAdlibMusicSource = interface
    ['{0F73A8C5-6B21-4E94-9D07-3C85B1E4A6F2}']
    function TrackCount: Integer;
    /// <summary>The bytes of a song (the name of the CAT entry is skipped)</summary>
    function LoadTrack(AIndex: Integer): TBytes;
  end;

  /// <summary>AdlibMusic: a song played on two chips (left and right) with the sound produced by the caller</summary>
  IXcomAdlibPlayer = interface
    ['{D4A1E6B8-3F59-4072-B8C6-9E21F0D7A53B}']
    /// <summary>AdlibMusic::load: the song to play (the data are kept)</summary>
    procedure Load(const ASong: TBytes);
    /// <summary>AdlibMusic::play: starts the song; AVolume is the music volume modifier of the constructor (1.0 = 100%)</summary>
    procedure Play(AVolume: Single);
    procedure Stop;
    procedure Fade;
    function IsPlaying: Boolean;
    procedure SetTempo(AValue: Integer);
    procedure SetVolume(AValue: Integer);
    function Polyphony: Integer;
    procedure SaveState(AIndex: Integer);
    procedure LoadState(AIndex: Integer);
    /// <summary>delay of AdlibMusic: the bytes of sound that Render still gives before the next tick</summary>
    function PendingBytes: Integer;
    /// <summary>
    ///   AdlibMusic::player: fills ABytes bytes (a multiple of 4: 16 bit samples, left and right) of the buffer, ticking
    ///   the sequencer when its time has come. AVolume is the volume of the output (Options::musicVolume)
    /// </summary>
    procedure Render(const ABuffer: TArray<SmallInt>; ABytes: Integer; AVolume: Single);
  end;

implementation

end.
