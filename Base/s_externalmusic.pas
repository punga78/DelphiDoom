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
//  DESCRIPTION:
//   External track music
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit s_externalmusic;

interface

uses
  DelphiDoom.Audio.Intf,
  sounddata;

//==============================================================================
//
// S_ConfigureExternalMusic
//
// The cache of the external songs is given by the composition root (ComposeEngine);
// without it the functions of this unit stop with I_Error.
//
//==============================================================================
procedure S_ConfigureExternalMusic(const ACache: IExternalMusicCache);

//==============================================================================
//
// S_ExternalMusicInit
//
//==============================================================================
procedure S_ExternalMusicInit;

//==============================================================================
//
// S_ShutDownExternalMusic
//
//==============================================================================
procedure S_ShutDownExternalMusic;

//==============================================================================
//
// S_TryLoadExternalMusic
//
//==============================================================================
function S_TryLoadExternalMusic(music: Pmusicinfo_t): boolean;

implementation

uses
  doomdef,
  i_music,
  i_system,
  w_wad;

var
  // given by the composition root (S_ConfigureExternalMusic)
  engine_externalmusic: IExternalMusicCache = nil;

//==============================================================================
//
// S_ConfigureExternalMusic
//
//==============================================================================
procedure S_ConfigureExternalMusic(const ACache: IExternalMusicCache);
begin
  engine_externalmusic := ACache;
end;

//==============================================================================
//
// ExternalMusicCache
//
//==============================================================================
function ExternalMusicCache: IExternalMusicCache;
begin
  if engine_externalmusic = nil then
    I_Error('S_ConfigureExternalMusic() was not called: the external music cannot be loaded');
  result := engine_externalmusic;
end;

//==============================================================================
//
// S_ExternalMusicInit
//
//==============================================================================
procedure S_ExternalMusicInit;
begin
  ExternalMusicCache.Clear;
end;

//==============================================================================
//
// S_ShutDownExternalMusic
//
//==============================================================================
procedure S_ShutDownExternalMusic;
begin
  if engine_externalmusic <> nil then
    engine_externalmusic.Clear;
end;

//==============================================================================
//
// S_TryLoadExternalMusic
//
//==============================================================================
function S_TryLoadExternalMusic(music: Pmusicinfo_t): boolean;
var
  clip: IExternalMusicClip;
begin
  clip := ExternalMusicCache.Find(char8tostring(W_GetNameForNum(music.lumpnum)));
  if clip = nil then
  begin
    result := False;
    exit;
  end;

  music.data := clip.Data;
  music.handle := I_RegisterSong(music.data, clip.Size);
  result := True;
end;

end.
