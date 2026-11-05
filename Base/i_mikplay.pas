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
//  MOD, S3M, XM and IT music playback with the tracker written in Pascal
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit i_mikplay;

interface

//==============================================================================
//
// I_PlayMik
//
//==============================================================================
procedure I_PlayMik(const data: pointer; const size: integer);

//==============================================================================
//
// I_PauseMik
//
//==============================================================================
procedure I_PauseMik;

//==============================================================================
//
// I_ResumeMik
//
//==============================================================================
procedure I_ResumeMik;

//==============================================================================
//
// I_StopMik
//
//==============================================================================
procedure I_StopMik;

//==============================================================================
//
// I_InitMik
//
//==============================================================================
procedure I_InitMik;

//==============================================================================
//
// I_ShutDownMik
//
//==============================================================================
procedure I_ShutDownMik;

//==============================================================================
//
// I_SetMusicVolumeMik
//
//==============================================================================
procedure I_SetMusicVolumeMik(volume: integer);

//==============================================================================
//
// I_ProcessMik
//
//==============================================================================
procedure I_ProcessMik;

implementation

uses
  d_delphi,
  DelphiDoom.Mikmod.Intf,
  DelphiDoom.Mikmod.Provider,
  i_system,
  i_mainwindow;

var
  mik_init: boolean = false;

const
  MIK_FREQ = 44100;

//==============================================================================
//
// I_InitMik
//
//==============================================================================
procedure I_InitMik;
begin
  try
    TMikModProvider.Client.Initialize(MIK_FREQ, True, True, True,
      NativeUInt(hMainWnd), 0);
    mik_init := True;
  except
    on E: EMikModException do
    begin
      mik_init := False;
      I_Warning('I_InitMik(): %s'#13#10, [E.Message]);
    end;
  end;
end;

//==============================================================================
//
// I_ShutDownMik
//
//==============================================================================
procedure I_ShutDownMik;
begin
  mik_init := False;
  TMikModProvider.Release;
end;

//==============================================================================
//
// I_PlayMik
//
//==============================================================================
procedure I_PlayMik(const data: pointer; const size: integer);
begin
  if not mik_init then
    Exit;

  // The tracker reads the module from memory: no temporary file
  try
    TMikModProvider.Client.LoadFromMemory(data, size);
    TMikModProvider.Client.Play(True);
  except
    on E: EMikModException do
      I_Warning('I_PlayMik(): %s'#13#10, [E.Message]);
  end;
end;

//==============================================================================
//
// I_PauseMik
//
//==============================================================================
procedure I_PauseMik;
begin
  if not mik_init then
    Exit;

  try
    if not TMikModProvider.Client.IsPaused then
      TMikModProvider.Client.Pause;
  except
    on EMikModException do
      ; // Nothing is loaded: there is nothing to pause
  end;
end;

//==============================================================================
//
// I_ResumeMik
//
//==============================================================================
procedure I_ResumeMik;
begin
  if not mik_init then
    Exit;

  try
    if TMikModProvider.Client.IsPaused then
      TMikModProvider.Client.Resume;
  except
    on EMikModException do
      ; // Nothing is loaded: there is nothing to resume
  end;
end;

//==============================================================================
//
// I_StopMik
//
//==============================================================================
procedure I_StopMik;
begin
  if not mik_init then
    Exit;

  try
    TMikModProvider.Client.Stop;
  except
    on EMikModException do
      ; // Nothing is loaded: there is nothing to stop
  end;
end;

const
  MIK_VOLUME_CONTROL: array[0..15] of word = (
      0,     9,     17,    26,
     34,    43,     51,    60,
     68,    77,     85,    94,
    102,   111,    119,   127
  );

//==============================================================================
//
// I_SetMusicVolumeMik
//
//==============================================================================
procedure I_SetMusicVolumeMik(volume: integer);
begin
  if not mik_init then
    Exit;

  try
    TMikModProvider.Client.SetVolume(MIK_VOLUME_CONTROL[ibetween(volume, 1, 15)]);
  except
    on EMikModException do
      ; // Nothing is loaded yet: the volume is set when the music starts
  end;
end;

//==============================================================================
//
// I_ProcessMik
//
//==============================================================================
procedure I_ProcessMik;
begin
  if not mik_init then
    Exit;

  try
    TMikModProvider.Client.Update;
  except
    on EMikModException do
      ; // Nothing is loaded: there is nothing to mix
  end;
end;

end.
