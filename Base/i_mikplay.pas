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
//  S3M & MOD music file playback using mikwin.dll
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit i_mikplay;

interface

uses
  i_music;

//==============================================================================
//
// I_PlayMik
//
//==============================================================================
procedure I_PlayMik(const data: pointer; const size: integer; const typ: music_t);

//==============================================================================
//
// I_PauseMik
//
//==============================================================================
procedure I_PauseMik(const typ: music_t);

//==============================================================================
//
// I_ResumeMik
//
//==============================================================================
procedure I_ResumeMik(const typ: music_t);

//==============================================================================
//
// I_StopMik
//
//==============================================================================
procedure I_StopMik(const typ: music_t);

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
procedure I_SetMusicVolumeMik(volume: integer; const typ: music_t);

//==============================================================================
//
// I_ProcessMik
//
//==============================================================================
procedure I_ProcessMik(const typ: music_t);

implementation

uses
  d_delphi,
  m_argv,
  m_sha1,
  m_misc,
  DelphiDoom.Mikmod.Intf,
  DelphiDoom.Mikmod.Provider,
  i_modmusic,
  i_s3mmusic,
  i_system,
  i_tmp,
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
  // The tracker written in Pascal in place of the embedded MikWin library
  TMikModProvider.UseTracker := M_CheckParm('-tracker') > 0;
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
procedure I_PlayMik(const data: pointer; const size: integer; const typ: music_t);
var
  mikfilename: string;
begin
  if not mik_init then
  begin
    if typ = m_s3m then
      I_PlayS3M(data, size)
    else if typ = m_mod then
      I_PlayMod(data, size);
    Exit;
  end;

  mikfilename := M_SaveFileName('DATA\');
  MkDir(mikfilename);
  mikfilename := mikfilename + 'TMP\';
  MkDir(mikfilename);
  mikfilename := mikfilename + 'mik_' + readablestring(SHA1_CalcSHA1Buf(data^, size)) + '.s3m';
  if not fexists(mikfilename) or (fsize(mikfilename) <> size) then
    M_WriteFile(mikfilename, data, size);
  I_DeclareTempFile(mikfilename);

  try
    TMikModProvider.Client.LoadFromFile(mikfilename);
    TMikModProvider.Client.Play(True);
  except
    on EMikModException do
    begin
      if typ = m_s3m then
        I_PlayS3M(data, size)
      else if typ = m_mod then
        I_PlayMOD(data, size);
      mik_init := False;
    end;
  end;
end;

//==============================================================================
//
// I_PauseMik
//
//==============================================================================
procedure I_PauseMik(const typ: music_t);
begin
  if not mik_init then
  begin
    if typ = m_s3m then
      I_PauseS3M
    else if typ = m_mod then
      I_PauseMod;
    Exit;
  end;

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
procedure I_ResumeMik(const typ: music_t);
begin
  if not mik_init then
  begin
    if typ = m_s3m then
      I_ResumeS3M
    else if typ = m_mod then
      I_ResumeMod;
    Exit;
  end;

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
procedure I_StopMik(const typ: music_t);
begin
  if not mik_init then
  begin
    if typ = m_s3m then
      I_StopS3M
    else if typ = m_mod then
      I_StopMod;
    Exit;
  end;

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
procedure I_SetMusicVolumeMik(volume: integer; const typ: music_t);
begin
  if not mik_init then
  begin
    if typ = m_s3m then
      I_SetMusicVolumeS3M(volume)
    else if typ = m_mod then
      I_SetMusicVolumeMod(volume);
    Exit;
  end;

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
procedure I_ProcessMik(const typ: music_t);
begin
  if not mik_init then
  begin
    if typ = m_s3m then
      I_ProcessS3M
    else if typ = m_mod then
      I_ProcessMod;
    Exit;
  end;

  try
    TMikModProvider.Client.Update;
  except
    on EMikModException do
      ; // Nothing is loaded: there is nothing to mix
  end;
end;

end.
