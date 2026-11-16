{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - wave files of Doom 3, shared types              }
{                                                                              }
{  Port of the data of idWaveFile (sound\snd_local.h, snd_wavefile.cpp).       }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Framework\IdLib\README.md); the repository }
{  as a whole is GPL v2 or later. Copyright (C) 1999-2011 id Software LLC.     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.WaveFile.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>WAVE_FORMAT_TAG_PCM</summary>
  WAVE_FORMAT_TAG_PCM = 1;
  /// <summary>WAVE_FORMAT_TAG_OGG: the format tag of a file left encoded in memory (real time decoding)</summary>
  WAVE_FORMAT_TAG_OGG = 2;

type
  /// <summary>An error that Doom 3 reports with <c>common->FatalError</c> (seeking an OGG file)</summary>
  EWaveFileException = class(Exception);

  /// <summary>waveformatex_t: the format of the samples of a sound</summary>
  TWaveFormat = record
    Tag: Word;
    Channels: Word;
    SamplesPerSecond: Cardinal;
    AverageBytesPerSecond: Cardinal;
    BlockAlign: Word;
    BitsPerSample: Word;
    ExtraSize: Word;
  end;

implementation

end.
