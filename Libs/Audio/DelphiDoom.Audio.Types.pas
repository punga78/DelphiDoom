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
  ///   What the WAV parser found in the bytes of a sound. FormatDone and DataDone are also an
  ///   input: a lump does not look again for a part that the file out of the WAD already gave
  ///   (that is how the old I_CacheSFX of i_sound went on from the file to the lump)
  /// </summary>
  TSfxWaveChunks = record
    /// <summary>A fmt chunk was read (now or before)</summary>
    FormatDone: Boolean;
    /// <summary>A data chunk was read (now or before)</summary>
    DataDone: Boolean;
    /// <summary>This call read a format: Format is the last one</summary>
    FormatFound: Boolean;
    Format: TSfxFormat;
    /// <summary>This call read the samples: DataOffset and DataLength say where they are</summary>
    DataFound: Boolean;
    DataOffset: Integer;
    DataLength: Integer;
  end;

  /// <summary>
  ///   An event of the midi stream of Windows (MIDIEVENT without the parameters): 12 bytes
  /// </summary>
  TMusMidiEvent = packed record
    /// <summary>Ticks since the last event</summary>
    Time: Cardinal;
    /// <summary>Always zero</summary>
    StreamId: Cardinal;
    case Integer of
      0: (Data: packed array[0..2] of Byte; EventType: Byte);
      1: (Event: Cardinal);
  end;
  PMusMidiEvent = ^TMusMidiEvent;

  /// <summary>A MUS song that cannot become midi events (the old code stopped with I_Error)</summary>
  EMusConversionException = class(Exception);

  /// <summary>What a music backend says about the bytes of a song</summary>
  TMusicRegisterResult = (
    /// <summary>It is not a song of this backend: another one may take it</summary>
    NotRecognized,
    /// <summary>It is a song of this backend, but it cannot be played (the player was told why)</summary>
    Failed,
    Registered
  );

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
