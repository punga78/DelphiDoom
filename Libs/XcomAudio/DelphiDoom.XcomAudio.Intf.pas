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
  System.SysUtils, DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomAudio.Types;

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

  /// <summary>
  ///   Turns the bytes of a sound or of a music file into samples (what Mix_LoadWAV_RW and Mix_LoadMUS_RW do): the
  ///   decoders of the other libraries (Libs\Sound, Libs\Mp3) stay behind this contract
  /// </summary>
  IXcomSampleDecoder = interface
    ['{5B1D7E92-C3A4-4F08-9E26-D0A87B14F5C3}']
    /// <summary>True when the first bytes look like a file this decoder reads (the check SDL_mixer does on the content)</summary>
    function Accepts(const AData: TBytes): Boolean;
    /// <summary>16 bit stereo, interleaved, at ARate; false when the data is not a file of this decoder or is damaged</summary>
    function TryDecode(const AData: TBytes; ARate: Integer; out ASamples: TArray<SmallInt>): Boolean;
  end;

  /// <summary>
  ///   The channels of the mixer as the battlescape uses them (Mix_PlayChannel, Mix_SetPosition, Mix_HaltChannel,
  ///   Mix_Volume, Mix_GroupAvailable): channel 0 to 3 are reserved, 3 is the ambience
  /// </summary>
  IXcomChannelMixer = interface
    ['{A93E40C7-6D15-4B82-8F7A-2C1E9D05B364}']
    /// <summary>
    ///   Mix_PlayChannel: AChannel -1 takes the first free channel from 4; ALoops -1 plays forever. The volume of the
    ///   channel applies (Mix_Volume). Returns the channel, or -1 when none is free or the sound cannot be read
    /// </summary>
    function PlayChannel(const AWave: TBytes; AChannel, ALoops: Integer): Integer;
    /// <summary>Mix_SetPosition: AAngle in degrees (0 front, 90 right, 270 left), ADistance 0 (near) to 255 (far)</summary>
    procedure SetPosition(AChannel, AAngle, ADistance: Integer);
    /// <summary>Mix_HaltChannel; -1 stops them all</summary>
    procedure HaltChannel(AChannel: Integer);
    function IsChannelPlaying(AChannel: Integer): Boolean;
    /// <summary>Mix_Volume (0..128); -1 sets every channel</summary>
    procedure SetChannelVolume(AChannel, AVolume: Integer);
    /// <summary>Mix_GroupAvailable of the group of the interface sounds (channels 1 and 2): -1 when both play</summary>
    function FreeInterfaceChannel: Integer;
    /// <summary>The ambience of the battle (SavedBattleGame::getAmbientVolume) that scales channel 3</summary>
    procedure SetAmbientVolume(AValue: Double);
  end;

  /// <summary>A track that has work to do before it plays (decoding a file): the player calls it outside the mixer</summary>
  IXcomMusicPreparation = interface
    ['{C6F2A185-7E40-4D93-B1A8-3D5E09F72B46}']
    procedure Prepare;
  end;

  /// <summary>
  ///   One format of music (an entry of the priority list of Mod::loadExtraResources): it makes the track of a rule
  ///   or gives nil, so that the next format is tried
  /// </summary>
  IXcomMusicFormatLoader = interface
    ['{18E7D3B0-A5C9-4264-8F1B-60C4E2A9D758}']
    function Format: TXcomMusicFormat;
    /// <summary>The game adopted new data: the loader reads what it needs of it (the CAT files)</summary>
    procedure Reload(const AResources: IXcomResources);
    /// <summary>nil when the format has no music for the rule or it cannot be read</summary>
    function Load(const ARule: TXcomMusicRule): IXcomMusicTrack;
  end;

  /// <summary>A synthesizer of MIDI messages (the part of the device that makes the sound of the MIDI music)</summary>
  IXcomMidiSynth = interface
    ['{F40B6A29-D1E3-47C5-9A80-B7E25C3D1964}']
    /// <summary>A channel message (status with the channel, two data bytes)</summary>
    procedure Send(AStatus, AData1, AData2: Byte);
    /// <summary>All the sounds stop and the controllers go back to the start</summary>
    procedure Reset;
    /// <summary>Adds ABytes bytes (a multiple of 4) of 16 bit stereo samples to ABuffer</summary>
    procedure Render(ABuffer: PSmallInt; ABytes: Integer);
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
