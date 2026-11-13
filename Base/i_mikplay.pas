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

// The facade of the tracker music (issue #185): TModuleMusicPlayer of Libs\EngineSystem does the work,
// ComposeEngine gives it (I_ConfigureMik). The engine calls these routines from TModuleMusicBackend.

interface

uses
  DelphiDoom.EngineSystem.Intf;

//==============================================================================
//
// I_ConfigureMik
// Gives the unit the tracker music player. The composition root calls it
//
//==============================================================================
procedure I_ConfigureMik(const APlayer: IModuleMusicPlayer);

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
  i_system;

var
  // given by the composition root (I_ConfigureMik)
  mik_player: IModuleMusicPlayer = nil;

//==============================================================================
//
// I_ConfigureMik
//
//==============================================================================
procedure I_ConfigureMik(const APlayer: IModuleMusicPlayer);
begin
  mik_player := APlayer;
end;

//==============================================================================
//
// I_InitMik
//
//==============================================================================
procedure I_InitMik;
begin
  if mik_player = nil then
    I_Error('I_InitMik(): the tracker music was not configured (ComposeEngine)');
  mik_player.Initialize;
end;

//==============================================================================
//
// I_ShutDownMik
//
//==============================================================================
procedure I_ShutDownMik;
begin
  if mik_player <> nil then
    mik_player.ShutDown;
end;

//==============================================================================
//
// I_PlayMik
//
//==============================================================================
procedure I_PlayMik(const data: pointer; const size: integer);
begin
  if mik_player <> nil then
    mik_player.Play(data, size);
end;

//==============================================================================
//
// I_PauseMik
//
//==============================================================================
procedure I_PauseMik;
begin
  if mik_player <> nil then
    mik_player.Pause;
end;

//==============================================================================
//
// I_ResumeMik
//
//==============================================================================
procedure I_ResumeMik;
begin
  if mik_player <> nil then
    mik_player.Resume;
end;

//==============================================================================
//
// I_StopMik
//
//==============================================================================
procedure I_StopMik;
begin
  if mik_player <> nil then
    mik_player.Stop;
end;

//==============================================================================
//
// I_SetMusicVolumeMik
//
//==============================================================================
procedure I_SetMusicVolumeMik(volume: integer);
begin
  if mik_player <> nil then
    mik_player.SetVolume(volume);
end;

//==============================================================================
//
// I_ProcessMik
//
//==============================================================================
procedure I_ProcessMik;
begin
  if mik_player <> nil then
    mik_player.Process;
end;

end.
