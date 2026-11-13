//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Midi file playback (Legacy)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit i_midi_legacy;

// The facade of the legacy MIDI player (issue #185): TLegacyMidiPlayer of Libs\EngineSystem does the
// work (the play list, the MCI sequencer and the notification window), ComposeEngine gives it
// (I_ConfigureLegacyMidi). i_midi chooses between this player and the internal one.

interface

uses
  DelphiDoom.EngineSystem.Intf;

//==============================================================================
//
// I_ConfigureLegacyMidi
// Gives the unit the legacy MIDI player. The composition root calls it
//
//==============================================================================
procedure I_ConfigureLegacyMidi(const APlayer: ILegacyMidiPlayer);

//==============================================================================
//
// I_PlayMidi_Legacy
//
//==============================================================================
procedure I_PlayMidi_Legacy(index: integer);

//==============================================================================
//
// I_StopMidi_Legacy
//
//==============================================================================
procedure I_StopMidi_Legacy;

//==============================================================================
//
// AddMidiFileToPlayList_Legacy
//
//==============================================================================
procedure AddMidiFileToPlayList_Legacy(const MidiFile: string);

//==============================================================================
//
// ClearMidiFilePlayList_Legacy
//
//==============================================================================
procedure ClearMidiFilePlayList_Legacy;

//==============================================================================
//
// I_ResumeMidi_Legacy
//
//==============================================================================
procedure I_ResumeMidi_Legacy;

//==============================================================================
//
// I_PauseMidi_Legacy
//
//==============================================================================
procedure I_PauseMidi_Legacy;

//==============================================================================
//
// I_InitMidi_Legacy
//
//==============================================================================
procedure I_InitMidi_Legacy;

//==============================================================================
//
// I_ShutDownMidi_Legacy
//
//==============================================================================
procedure I_ShutDownMidi_Legacy;

//==============================================================================
//
// I_SetMusicVolumeMidi_Legacy
//
//==============================================================================
procedure I_SetMusicVolumeMidi_Legacy(const v: integer);

//==============================================================================
//
// I_ProcessMidi_Legacy
//
//==============================================================================
procedure I_ProcessMidi_Legacy;

implementation

uses
  i_system;

var
  // given by the composition root (I_ConfigureLegacyMidi)
  legacy_player: ILegacyMidiPlayer = nil;

//==============================================================================
//
// I_ConfigureLegacyMidi
//
//==============================================================================
procedure I_ConfigureLegacyMidi(const APlayer: ILegacyMidiPlayer);
begin
  legacy_player := APlayer;
end;

//==============================================================================
//
// RequireLegacyPlayer
//
//==============================================================================
function RequireLegacyPlayer: ILegacyMidiPlayer;
begin
  if legacy_player = nil then
    I_Error('The legacy MIDI player was not configured (ComposeEngine)');
  result := legacy_player;
end;

//==============================================================================
//
// AddMidiFileToPlayList_Legacy
//
//==============================================================================
procedure AddMidiFileToPlayList_Legacy(const MidiFile: string);
begin
  RequireLegacyPlayer.AddFile(MidiFile);
end;

//==============================================================================
//
// ClearMidiFilePlayList_Legacy
//
//==============================================================================
procedure ClearMidiFilePlayList_Legacy;
begin
  RequireLegacyPlayer.ClearPlayList;
end;

//==============================================================================
//
// I_PlayMidi_Legacy
//
//==============================================================================
procedure I_PlayMidi_Legacy(index: integer);
begin
  RequireLegacyPlayer.Play(index);
end;

//==============================================================================
//
// I_StopMidi_Legacy
//
//==============================================================================
procedure I_StopMidi_Legacy;
begin
  RequireLegacyPlayer.Stop;
end;

//==============================================================================
//
// I_ResumeMidi_Legacy
//
//==============================================================================
procedure I_ResumeMidi_Legacy;
begin
  RequireLegacyPlayer.Resume;
end;

//==============================================================================
//
// I_PauseMidi_Legacy
//
//==============================================================================
procedure I_PauseMidi_Legacy;
begin
  RequireLegacyPlayer.Pause;
end;

//==============================================================================
//
// I_InitMidi_Legacy
//
//==============================================================================
procedure I_InitMidi_Legacy;
begin
  RequireLegacyPlayer.Initialize;
end;

//==============================================================================
//
// I_ShutDownMidi_Legacy
//
//==============================================================================
procedure I_ShutDownMidi_Legacy;
begin
  RequireLegacyPlayer.ShutDown;
end;

//==============================================================================
//
// I_SetMusicVolumeMidi_Legacy
//
//==============================================================================
procedure I_SetMusicVolumeMidi_Legacy(const v: integer);
begin
  RequireLegacyPlayer.SetVolume(v);
end;

//==============================================================================
//
// I_ProcessMidi_Legacy
//
//==============================================================================
procedure I_ProcessMidi_Legacy;
begin
  RequireLegacyPlayer.Process;
end;

end.
