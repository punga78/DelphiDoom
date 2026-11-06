{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the contracts of the sound effects               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Intf;

interface

uses
  DelphiDoom.Audio.Types;

type
  /// <summary>One sound effect loaded in a buffer of the device, that can be played again and again</summary>
  IAudioVoice = interface
    ['{7C3A91E5-4D28-4B06-A1F9-E5B20D87C346}']
    /// <summary>Copies the bytes of the sample in the buffer; 0 when done, else the code of the device</summary>
    function Load(const ASample: TSfxSample): Integer;
    procedure Play;
    procedure Stop;
    /// <summary>The next Play starts from the first sample</summary>
    procedure Rewind;
    procedure SetPan(APan: Integer);
    procedure SetVolume(AVolume: Integer);
    function IsPlaying: Boolean;
  end;

  ISoundDevice = interface
    ['{1E8F5B27-C096-4A3D-8D74-92A0F6C1B53E}']
    /// <summary>
    ///   False when there is no device and the game goes on without sound (the device told why);
    ///   raises EAudioDeviceException when it cannot be used at all
    /// </summary>
    function Initialize: Boolean;
    procedure Shutdown;
    /// <summary>A buffer for a sample; 0 when done, else the code of the device (AVoice is nil)</summary>
    function CreateVoice(const ASample: TSfxSample; out AVoice: IAudioVoice): Integer;
  end;

  /// <summary>Where the samples come from: the engine finds them in the WAD, or outside it</summary>
  ISfxSampleSource = interface
    ['{B5D2074A-3F9E-4C81-A6E3-0D41C97F8B25}']
    /// <summary>The sample of a sound effect, loaded if it was not</summary>
    function Load(ASoundId: Integer): TSfxSample;
    /// <summary>The external sample of this sound caused a problem: it is not used again</summary>
    procedure DiscardExternal(ASoundId: Integer);
    /// <summary>The average bytes per second that the device accepted</summary>
    procedure StoreAverageBytes(ASoundId: Integer; AAverageBytes: Cardinal);
    function NameOf(ASoundId: Integer): string;
  end;

  ISfxPlayer = interface
    ['{F40B6C18-92D7-4E53-B1A4-6A5E3D07C892}']
    procedure Shutdown;
    /// <summary>
    ///   Plays a sound effect and gives its handle. Volume is 0..15, separation 0..255.
    ///   Without a device it only gives handles
    /// </summary>
    function Start(ASoundId, AVolume, ASeparation: Integer): Integer;
    procedure Stop(AHandle: Integer);
    function IsPlaying(AHandle: Integer): Boolean;
    procedure UpdateParams(AHandle, AVolume, ASeparation: Integer);
    /// <summary>The channels do not remember what they played: the samples were released</summary>
    procedure ForgetSounds;
  end;

implementation

end.
