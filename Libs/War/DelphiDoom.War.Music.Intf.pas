{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the music: contracts                              }
{                                                                              }
{  Port of wa_playMidi of war_audio.c, war1 (acoto87/war1), (c) 2019 Alejandro  }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an     }
{  altered version, not the original.                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Music.Intf;

interface

uses
  System.SysUtils, DelphiDoom.War.Music.Types;

type
  /// <summary>
  ///   What turns the notes into samples: the tsf_* calls of the original. The original uses TinySoundFont and a
  ///   SoundFont whose license is not declared, so no synth is ported here: the engine gets one that is chosen
  ///   later (a test uses a fake that writes down the calls). It renders mono 16 bit at WAR_PLAYBACK_RATE
  /// </summary>
  IWarMusicSynth = interface
    ['{3A6E1D87-B2C4-4F90-A538-9C07D4E1F6B2}']
    /// <summary>tsf_channel_set_presetnumber(channel, program, channel == 9)</summary>
    procedure ProgramChange(AChannel, AProgram: Integer; AIsDrums: Boolean);
    /// <summary>tsf_channel_note_on: AVelocity is velocity / 127 already scaled by the volume of the music</summary>
    procedure NoteOn(AChannel, AKey: Integer; AVelocity: Single);
    procedure NoteOff(AChannel, AKey: Integer);
    procedure PitchBend(AChannel, AValue: Integer);
    procedure ControlChange(AChannel, AController, AValue: Integer);
    /// <summary>tsf_note_off_all(TRUE): every note stops at once, without a release</summary>
    procedure AllNotesOff;
    /// <summary>tsf_render_short(..., mixing = TRUE): adds ASampleCount samples of the notes that play to ABuffer</summary>
    procedure Render(ABuffer: PSmallInt; ASampleCount: Integer);
  end;

  /// <summary>
  ///   The events of a song, in order and with the time in whole milliseconds, built on the MIDI stream sequencer
  ///   of Libs\Midi (what tml_load gives the original)
  /// </summary>
  IWarMusicTimeline = interface
    ['{C85B2F40-1E93-47A6-8D0C-6A3F57E9B124}']
    /// <summary>Reads a Standard MIDI file; False if it cannot be read (the timeline is empty)</summary>
    function Load(const AMidi: TBytes): Boolean;
    /// <summary>The next event that the original plays; False at the end of the song</summary>
    function TryNext(out AEvent: TWarMusicEvent): Boolean;
    /// <summary>The song goes back to its first event</summary>
    procedure Rewind;
  end;

  /// <summary>One song at a time, mixed into the output of the game</summary>
  IWarMusicPlayer = interface
    ['{F19D7A26-5B03-4C8E-B6A1-02E4C93D8570}']
    /// <summary>
    ///   Starts a song, the one that plays stops at once. AFadeInMs is the milliseconds the volume takes to
    ///   rise from silence (0: full at once). False if the bytes are not a song that can be read
    /// </summary>
    function Play(const AMidi: TBytes; ALoop: Boolean; AFadeInMs: Integer): Boolean;
    /// <summary>The song fades out in AFadeOutMs and then stops; 0 stops it at once (wa_removeAudiosOfType)</summary>
    procedure Stop(AFadeOutMs: Integer);
    /// <summary>musicVolume (clamped to 0..1) and musicEnabled of the context; at volume 0 the song does not advance</summary>
    procedure SetVolume(AVolume: Single; AEnabled: Boolean);
    /// <summary>While True nothing is heard and the song does not advance (the change of scene of the original)</summary>
    procedure SetSilenced(ASilenced: Boolean);
    /// <summary>Adds ASampleCount samples of the music to ABuffer (it does not clear it)</summary>
    procedure Mix(ABuffer: PSmallInt; ASampleCount: Integer);
    function GetState: TWarMusicState;
    property State: TWarMusicState read GetState;
  end;

implementation

end.
