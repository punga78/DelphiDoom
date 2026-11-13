{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the music: types and constants                    }
{                                                                              }
{  Port of wa_playMidi of war_audio.c, war1 (acoto87/war1), (c) 2019 Alejandro  }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an     }
{  altered version, not the original.                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Music.Types;

interface

const
  /// <summary>TSF_RENDER_EFFECTSAMPLEBLOCK of tsf.h: the song advances and the synth renders this many samples at a time</summary>
  WAR_MUSIC_RENDER_BLOCK = 64;
  /// <summary>The samples the player renders before it mixes them into the output (a longer request is served in pieces)</summary>
  WAR_MUSIC_SCRATCH_SAMPLES = 8192;
  /// <summary>The bytes of the stream of events that the timeline asks the sequencer for at a time (256 events)</summary>
  WAR_MUSIC_STREAM_BYTES = 256 * 12;
  /// <summary>The channel of the drums: the synth gets the preset as percussion (channel == 9)</summary>
  WAR_MUSIC_DRUM_CHANNEL = 9;
  /// <summary>The gain of the fade at full volume (16.16)</summary>
  WAR_MUSIC_GAIN_FULL = 65536;

type
  /// <summary>The events of a song that the original plays (wa_playMidi); wmkIgnored is a message it reads but does not play (pressure, tempo): it counts for the time of the song</summary>
  TWarMusicEventKind = (wmkNoteOff, wmkNoteOn, wmkProgramChange, wmkPitchBend, wmkControlChange, wmkIgnored);

  /// <summary>An event of the song at a time in whole milliseconds, as tml_load gives it</summary>
  TWarMusicEvent = record
    TimeMs: Cardinal;
    Kind: TWarMusicEventKind;
    Channel: Byte;
    /// <summary>The key of a note, the program of a program change, the controller of a control change</summary>
    Key: Byte;
    /// <summary>The velocity of a note, the value of a controller, the 14 bit value of a pitch bend</summary>
    Value: Integer;
  end;

  /// <summary>What the player is doing</summary>
  TWarMusicState = (
    wmsStopped,
    wmsPlaying,
    /// <summary>The song fades out; it stops when the fade ends</summary>
    wmsFadingOut,
    /// <summary>A song that does not loop has reached its last event</summary>
    wmsEnded
  );

implementation

end.
