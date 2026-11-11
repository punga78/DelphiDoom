{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - shared types                                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>The audio data cannot be used (a WAV file that is not PCM, a buffer of a wrong size)</summary>
  EXcomAudioException = class(Exception);

  /// <summary>MusicFormat of OpenXcom (Options::preferredMusic and the order Mod::loadExtraResources tries)</summary>
  TXcomMusicFormat = (mfAuto, mfFlac, mfOgg, mfMp3, mfMod, mfWav, mfAdlib, mfGm, mfMidi);

const
  /// <summary>The rate OpenXcom opens the audio with (Options::audioSampleRate)</summary>
  XCOM_AUDIO_RATE = 22050;

resourcestring
  SXcomWaveNotPcm = 'The sound is not a PCM WAV file with 1 or 2 channels and 8 or 16 bits';
  SXcomBufferNotWhole = 'The buffer size must be a multiple of 4 bytes (16 bit samples, left and right)';

implementation

end.
