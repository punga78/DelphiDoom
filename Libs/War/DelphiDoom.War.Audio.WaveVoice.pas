{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - one voice that plays a sound                      }
{                                                                              }
{  Port of wa_playWave of war_audio.c, war1 (acoto87/war1),                    }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-      }
{  war1.txt). This is an altered version, not the original.                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Audio.WaveVoice;

interface

uses
  DelphiDoom.AudioMix.UnsignedMonoVoice;

type
  /// <summary>
  ///   The state of a voice (sampleIndex, playbackTime, loop of WarAudioComponent) and wa_playWave: the voice of 8 bit
  ///   unsigned mono samples of Libs\AudioMix, which holds the code
  /// </summary>
  TWarWaveVoice = TPcmUnsignedMonoVoice;

implementation

end.
