{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the contracts of the sound                       }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): modplay.pas                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Sound.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types;

type
  /// <summary>One sound effect that is playing: what the original asks of a BASS channel</summary>
  IGreedEffectChannel = interface
    ['{3B5E9A71-0C84-4D2F-A6E1-8F7D2C40B953}']
    /// <summary>-1.0 (left) .. 1.0 (right)</summary>
    procedure SetPan(APan: Single);
    /// <summary>0.0 .. 1.0</summary>
    procedure SetVolume(AVolume: Single);
    /// <summary>False when the sound has ended (BASS_ACTIVE_STOPPED)</summary>
    function IsActive: Boolean;
    procedure Stop;
  end;

  /// <summary>The song that is playing</summary>
  IGreedMusicChannel = interface
    ['{91C4F2D8-6A37-4E05-B8D9-1A5E7C3042F6}']
    /// <summary>0.0 .. 1.0</summary>
    procedure SetVolume(AVolume: Single);
    procedure Stop;
  end;

  /// <summary>
  ///   What plays the sound (BASS in the original). Samples are the bytes of a WAV file and songs the bytes of
  ///   a module (S3M, MOD)
  /// </summary>
  IGreedSoundDevice = interface
    ['{E70B3C59-2D16-4F84-9A0E-5C8D1B6F7A32}']
    /// <summary>False when there is no device: the game goes on without sound</summary>
    function Initialize: Boolean;
    procedure Shutdown;
    /// <summary>Starts the sample; nil when the device cannot play it</summary>
    function StartEffect(const AWave: TBytes): IGreedEffectChannel;
    /// <summary>Starts the song, looping; nil when the device cannot play it</summary>
    function StartMusic(const AModule: TBytes; AVolume: Single): IGreedMusicChannel;
  end;

  /// <summary>Where the player is: the effects are heard from there (player.x, player.y, player.angle)</summary>
  IGreedListener = interface
    ['{5A2D8E46-B031-4C97-83F5-D6E09A1C7B84}']
    function GetX: TGreedFixed;
    function GetY: TGreedFixed;
    /// <summary>0..1023</summary>
    function GetAngle: Integer;
  end;

  /// <summary>The volumes of the music and of the effects, 0..255 (SC.musicvol, SC.sfxvol)</summary>
  IGreedSoundVolumes = interface
    ['{C4F17B20-9E65-4A38-B2D0-3E8A5F916C07}']
    function GetMusicVolume: Integer;
    function GetSfxVolume: Integer;
    /// <summary>Each over 255 becomes 255 (SetVolumes)</summary>
    procedure SetVolumes(AMusic, ASfx: Integer);
    property MusicVolume: Integer read GetMusicVolume;
    property SfxVolume: Integer read GetSfxVolume;
  end;

  /// <summary>The time of the game, in tics (Wait of the original)</summary>
  IGreedTics = interface
    ['{08D6A3E1-47B9-4C52-A1F8-E5B07D294C63}']
    procedure Wait(ATics: Integer);
  end;

  /// <summary>The sound effects of the game: up to 64 at a time, heard from the listener</summary>
  IGreedSoundEffects = interface
    ['{B2E85F04-1D7A-4936-8C0B-A9F3E6D52174}']
    /// <summary>SoundEffect: nothing if it is too far, or there is no free channel, or the lump is empty</summary>
    procedure Start(ASoundNumber, AVariation: Integer; AX, AY: TGreedFixed);
    /// <summary>UpdateSound: frees the channels that ended, and moves the others as the listener moved</summary>
    procedure Update;
    /// <summary>Stops every effect</summary>
    procedure StopAll;
  end;

  /// <summary>The music of the game: a song at a time</summary>
  IGreedMusic = interface
    ['{7F31C9D5-A248-4B60-95E7-2D0B8E1A4C36}']
    /// <summary>PlaySong: stops the song that plays and starts that; the pattern is not used (BASS ignores it)</summary>
    procedure Play(const AFileName: string; APattern: Integer);
    /// <summary>StopMusic: the volume goes down to 0 and the song stops (not in a net game)</summary>
    procedure Stop;
  end;

implementation

end.
