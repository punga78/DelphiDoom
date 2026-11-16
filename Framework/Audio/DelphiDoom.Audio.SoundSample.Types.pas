{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - a sample of the sound cache of Doom 3           }
{                                                                              }
{  Port of the data of idSoundSample (sound\snd_cache.cpp, snd_local.h).       }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Framework\IdLib\README.md); the repository }
{  as a whole is GPL v2 or later. Copyright (C) 1999-2011 id Software LLC.     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.SoundSample.Types;

interface

uses
  System.SysUtils, DelphiDoom.Audio.WaveFile.Types;

const
  /// <summary>MIXBUFFER_SAMPLES: the length of the default sound is twice this</summary>
  SOUND_MIXBUFFER_SAMPLES = 4096;

type
  /// <summary>
  ///   What the sound cache knows about a sound (the fields of <c>idSoundSample</c> that the readers of the cache
  ///   use): its canonical name, the format, the size in 16-bit samples (<c>objectSize</c>), the size in bytes
  ///   (<c>objectMemSize</c>), the samples as the file gives them and whether it is the default sound
  /// </summary>
  TSoundSample = class
  strict private
    FName: string;
    FFormat: TWaveFormat;
    FSizeInSamples: Integer;
    FMemorySize: Integer;
    FData: TBytes;
    FIsDefault: Boolean;
  public
    constructor Create(const AName: string; const AFormat: TWaveFormat; ASizeInSamples, AMemorySize: Integer;
      const AData: TBytes; AIsDefault: Boolean);
    /// <summary>The name: slashes forward, lower case</summary>
    property Name: string read FName;
    /// <summary>objectInfo</summary>
    property Format: TWaveFormat read FFormat;
    /// <summary>objectSize, in 16-bit samples of all the channels</summary>
    property SizeInSamples: Integer read FSizeInSamples;
    /// <summary>objectMemSize, in bytes</summary>
    property MemorySize: Integer read FMemorySize;
    /// <summary>nonCacheData: the samples (little endian), as many bytes as <c>MemorySize</c> says</summary>
    property Data: TBytes read FData;
    /// <summary>defaultSound: the sound could not be loaded and this is the beep</summary>
    property IsDefault: Boolean read FIsDefault;
    /// <summary>objectInfo.wFormatTag = WAVE_FORMAT_TAG_OGG: an OGG file left encoded (real time decoding)</summary>
    function IsOgg: Boolean;
    /// <summary>LengthIn44kHzSamples: the size in samples at 44100 Hz (11025 and 22050 Hz sounds are 4 and 2 times)</summary>
    function Length44kHzSamples: Integer;
  end;

implementation

{ TSoundSample }

constructor TSoundSample.Create(const AName: string; const AFormat: TWaveFormat; ASizeInSamples,
  AMemorySize: Integer; const AData: TBytes; AIsDefault: Boolean);
begin
  inherited Create;
  FName := AName;
  FFormat := AFormat;
  FSizeInSamples := ASizeInSamples;
  FMemorySize := AMemorySize;
  FData := AData;
  FIsDefault := AIsDefault;
end;

function TSoundSample.IsOgg: Boolean;
begin
  Result := FFormat.Tag = WAVE_FORMAT_TAG_OGG;
end;

function TSoundSample.Length44kHzSamples: Integer;
begin
  // objectSize is samples
  if FFormat.SamplesPerSecond = 11025 then
    Result := FSizeInSamples shl 2
  else if FFormat.SamplesPerSecond = 22050 then
    Result := FSizeInSamples shl 1
  else
    Result := FSizeInSamples;
end;

end.
