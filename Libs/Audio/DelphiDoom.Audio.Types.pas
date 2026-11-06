{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the shared types                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>The range of the pan and of the volume of a voice (hundredths of a decibel, like DirectSound)</summary>
  AUDIO_PAN_LEFT = -10000;
  AUDIO_PAN_CENTER = 0;
  AUDIO_PAN_RIGHT = 10000;
  AUDIO_VOLUME_MIN = -10000;
  AUDIO_VOLUME_MAX = 0;

type
  /// <summary>The format of the samples of a sound effect</summary>
  TSfxFormat = record
    Tag: Word;
    Channels: Word;
    SamplesPerSecond: Cardinal;
    AverageBytesPerSecond: Cardinal;
    BitsPerSample: Word;
  end;

  /// <summary>
  ///   A sound effect ready to be played. The buffer of the voice is Length bytes; the bytes
  ///   that are copied in it are the ones after Offset (Length - Offset of them)
  /// </summary>
  TSfxSample = record
    Format: TSfxFormat;
    Data: PByte;
    Offset: Integer;
    Length: Integer;
    /// <summary>It comes from a file out of the WAD (wav, ogg, flac...)</summary>
    IsExternal: Boolean;
  end;

  /// <summary>
  ///   A sound that could not start, in a way that is a problem of the developer: the engine
  ///   decides whether it is a warning or an error
  /// </summary>
  ESfxStartException = class(Exception);

  /// <summary>The player is in a state that cannot be: always an error of the program</summary>
  ESfxFatalException = class(Exception);

  /// <summary>An audio device that could not start</summary>
  EAudioDeviceException = class(Exception);

implementation

end.
