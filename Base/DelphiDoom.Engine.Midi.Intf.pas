{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the contract of the player of the MIDI files            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Midi.Intf;

interface

type
  /// <summary>
  ///   Plays a MIDI file on the midi stream of Windows, one song at a time (the old
  ///   i_midi_new). i_midi chooses between it and the legacy MCI player
  /// </summary>
  IEngineMidiSongPlayer = interface
    ['{C3A91E52-6B07-4D18-A5E4-0F7D2B96C834}']
    /// <summary>Reads, converts and starts a MIDI file in a loop; a file that is not a MIDI file gives a warning and no song</summary>
    procedure Play(const AFileName: string);
    /// <summary>Stops the current song; nothing if there is none</summary>
    procedure Stop;
    /// <summary>Pauses the current song; nothing if there is none</summary>
    procedure Pause;
    /// <summary>Resumes the current song; nothing if there is none</summary>
    procedure Resume;
    /// <summary>Starts with no song</summary>
    procedure Initialize;
    /// <summary>Stops and frees the current song</summary>
    procedure ShutDown;
    /// <summary>Sets the volume of the song, from the 0..15 level of the menu</summary>
    procedure SetVolume(ALevel: Integer);
    /// <summary>Writes the volume again on the channels (called at every tic)</summary>
    procedure Process;
  end;

implementation

end.
