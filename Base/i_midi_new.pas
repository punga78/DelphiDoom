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
//  Midi file playback with the midi stream (the facade of
//  DelphiDoom.Engine.Midi.StreamPlayer)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit i_midi_new;

interface

uses
  DelphiDoom.Midi.Intf;

//==============================================================================
//
// I_ConfigureMidiStream
// Gives the maker of the sequencers of the songs (ComposeEngine). Without it
// I_PlayMidi_New stops the game
//
//==============================================================================
procedure I_ConfigureMidiStream(const ASequencers: IMidiStreamSequencerFactory);

//==============================================================================
//
// I_PlayMidi_New
//
//==============================================================================
procedure I_PlayMidi_New(const aMidiFile: string);

//==============================================================================
//
// I_StopMidi_New
//
//==============================================================================
procedure I_StopMidi_New;

//==============================================================================
//
// I_PauseMidi_New
//
//==============================================================================
procedure I_PauseMidi_New;

//==============================================================================
//
// I_ResumeMidi_New
//
//==============================================================================
procedure I_ResumeMidi_New;

//==============================================================================
//
// I_InitMidi_New
//
//==============================================================================
procedure I_InitMidi_New;

//==============================================================================
//
// I_ShutDownMidi_New
//
//==============================================================================
procedure I_ShutDownMidi_New;

//==============================================================================
//
// I_SetMusicVolumeMidi_New
//
//==============================================================================
procedure I_SetMusicVolumeMidi_New(volume: integer);

//==============================================================================
//
// I_ProcessMidi_New
//
//==============================================================================
procedure I_ProcessMidi_New;

implementation

uses
  System.SysUtils,
  d_delphi,
  i_system,
  i_midi,
  DelphiDoom.Midi.Volume,
  DelphiDoom.Engine.Midi.StreamPlayer;

var
  midi: TEngineMidiStreamPlayer;
  sequencers: IMidiStreamSequencerFactory;
  ws_volume: integer;

//==============================================================================
//
// I_ConfigureMidiStream
//
//==============================================================================
procedure I_ConfigureMidiStream(const ASequencers: IMidiStreamSequencerFactory);
begin
  sequencers := ASequencers;
end;

//==============================================================================
//
// I_PlayMidi_New
//
//==============================================================================
procedure I_PlayMidi_New(const aMidiFile: string);
var
  f: TFile;
  data: TBytes;
  sequencer: IMidiStreamSequencer;
begin
  if not Assigned(sequencers) then
    I_Error('I_PlayMidi(): the MIDI sequencers are not configured (ComposeEngine)');

  FreeAndNil(midi);

  f := TFile.Create(aMidiFile, fOpenReadOnly);
  try
    SetLength(data, f.Size);
    if Length(data) > 0 then
      f.Read(data[0], Length(data));
  finally
    f.Free;
  end;

  // a file that is not a MIDI file that can be read is a warning of the sequencer and no song
  sequencer := sequencers.CreateSequencer;
  if (Length(data) = 0) or not sequencer.Load(@data[0], Length(data)) then
  begin
    I_Warning('I_PlayMidi(): %s is not a MIDI file that can be played'#13#10, [aMidiFile]);
    exit;
  end;

  midi := TEngineMidiStreamPlayer.Create(sequencer, I_SelectDefaultMidiDevice);
  if not midi.Load then
    I_Error('I_PlayMidi(): Can not setup stream buffer');
  midi.Play(True);
end;

//==============================================================================
//
// I_StopMidi
//
//==============================================================================
procedure I_StopMidi_New;
begin
  if midi <> nil then
  begin
    midi.Stop;
    FreeAndNil(midi);
  end;
end;

//==============================================================================
//
// I_PauseMidi_New
//
//==============================================================================
procedure I_PauseMidi_New;
begin
  if midi <> nil then
    midi.Pause;
end;

//==============================================================================
//
// I_ResumeMidi
//
//==============================================================================
procedure I_ResumeMidi_New;
begin
  if midi <> nil then
    midi.Resume;
end;

//==============================================================================
//
// I_InitMidi
//
//==============================================================================
procedure I_InitMidi_New;
begin
  midi := nil;
end;

//==============================================================================
//
// I_ShutDownMidi_New
//
//==============================================================================
procedure I_ShutDownMidi_New;
begin
  FreeAndNil(midi);
end;

//==============================================================================
//
// I_SetMusicVolumeMidi_New
//
//==============================================================================
procedure I_SetMusicVolumeMidi_New(volume: integer);
begin
  if midi <> nil then
  begin
    ws_volume := TMidiVolume.PercentOfLevel(volume);
    midi.SetMasterVolume(ws_volume);
  end;
end;

//==============================================================================
//
// I_ProcessMidi_New
//
//==============================================================================
procedure I_ProcessMidi_New;
begin
  if midi <> nil then
    midi.SetMasterVolume(ws_volume);
end;

end.
