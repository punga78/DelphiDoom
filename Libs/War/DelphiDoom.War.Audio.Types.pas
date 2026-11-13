{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - audio types and constants                         }
{                                                                              }
{  Port of war1 (acoto87/war1), war_audio.c and war_enums.h (WarAudioId),      }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-      }
{  war1.txt). This is an altered version, not the original.                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Audio.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>PLAYBACK_FREQ of war.h: every sound is resampled to this rate</summary>
  WAR_PLAYBACK_RATE = 44100;
  /// <summary>MIN_ACK_SOUND_INTERVAL of war.h, in seconds</summary>
  WAR_MIN_ACK_SOUND_INTERVAL = 0.15;

  // Records of the music (WAR_MUSIC_00..44 of WarAudioId): XMI, converted to MIDI
  WAR_MUSIC_FIRST = 0;
  WAR_MUSIC_LAST = 44;

  // A few sounds of WarAudioId (the record index of DATA.WAR), with the ranges the game picks at random from
  WAR_SOUND_LOGO = 472;
  WAR_SOUND_BUILDING = 474;
  WAR_SOUND_UI_CLICK = 485;
  WAR_SOUND_SWORD_ATTACK_FIRST = 487;
  WAR_SOUND_SWORD_ATTACK_LAST = 489;
  WAR_SOUND_ORC_ACKNOWLEDGEMENT_FIRST = 509;
  WAR_SOUND_ORC_ACKNOWLEDGEMENT_LAST = 512;
  WAR_SOUND_HUMAN_ACKNOWLEDGEMENT_FIRST = 513;
  WAR_SOUND_HUMAN_ACKNOWLEDGEMENT_LAST = 514;
  WAR_SOUND_ORC_SELECTED_FIRST = 515;
  WAR_SOUND_ORC_SELECTED_LAST = 519;
  WAR_SOUND_HUMAN_SELECTED_FIRST = 520;
  WAR_SOUND_HUMAN_SELECTED_LAST = 524;
  WAR_SOUND_ORC_ANNOYED_FIRST = 525;
  WAR_SOUND_ORC_ANNOYED_LAST = 527;
  WAR_SOUND_HUMAN_ANNOYED_FIRST = 528;
  WAR_SOUND_HUMAN_ANNOYED_LAST = 530;
  WAR_SOUND_LAST = 582;

  // The audible range of a positional sound outside the viewport, in pixels from its center
  WAR_AUDIBLE_NEAR = 120;
  WAR_AUDIBLE_RANGE = 80;

type
  /// <summary>WarAudioType: what a record of the audio table plays</summary>
  TWarAudioKind = (wakMidi, wakWave);

  /// <summary>
  ///   Samples as the VOC and WAV readers of the original give them (mv_audio_buffer, mw_audio_buffer): the bytes
  ///   of the samples, interleaved by channel, 8 bits unsigned or 16 bits signed little endian
  /// </summary>
  TWarPcmBuffer = record
    Channels: Cardinal;
    SampleRate: Cardinal;
    BitsPerSample: Cardinal;
    Data: TBytes;
  end;

resourcestring
  SWarAudioNotSound = 'The record %d is not a sound (VOC or WAVE)';
  SWarAudioNotMusic = 'The record %d is not a song (XMID)';
  SWarAudioBadSound = 'The sound of the record %d cannot be decoded';
  SWarAudioBadMusic = 'The song of the record %d cannot be converted to MIDI';
  SWarAudioBadFormat = 'Cannot resample %d channels of %d bits';

implementation

end.
