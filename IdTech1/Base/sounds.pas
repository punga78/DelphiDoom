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
//   Created by the sound utility written by Dave Taylor.
//   Kept as a sample, DOOM2  sounds. Frozen.
//
//   The tables S_sfx and S_music are data (sounddata.pas); the numbers of sounds and
//   songs come from the rules of Framework\Audio (TSfxNumberResolver, TMusicNumberResolver),
//   that the composition root gives here
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit sounds;

interface

uses
  d_delphi,
  DelphiDoom.Audio.Sound.Intf;

//==============================================================================
//
// S_ConfigureSoundNumbers
//
// The rules of the numbers of the sounds (TSfxNumberResolver of Framework\Audio, on the
// table of the game and the aliases of SNDINFO that the ACTORDEF lumps fill), given
// by the composition root; without them S_GetSoundNumForName stops with I_Error
//
//==============================================================================
procedure S_ConfigureSoundNumbers(const AResolver: ISfxNumberResolver);

//==============================================================================
//
// S_ConfigureMusicNumbers
//
// The rules of the numbers of the songs (TMusicNumberResolver of Framework\Audio), given by
// the composition root; without them S_GetMusicNumForName stops with I_Error
//
//==============================================================================
procedure S_ConfigureMusicNumbers(const AResolver: IMusicNumberResolver);

//==============================================================================
//
// S_GetSoundNumForName
//
//==============================================================================
function S_GetSoundNumForName(const sfx_name: string): integer;

//==============================================================================
//
// S_GetSoundNameForNum
//
//==============================================================================
function S_GetSoundNameForNum(const sfx_num: integer): string;

//==============================================================================
//
// S_GetRandomSoundList
//
//==============================================================================
function S_GetRandomSoundList(const sfx_num: integer): TDNumberList;

//==============================================================================
//
// S_FreeRandomSoundLists
//
//==============================================================================
procedure S_FreeRandomSoundLists;

//==============================================================================
//
// S_FreeMP3Streams
//
//==============================================================================
procedure S_FreeMP3Streams;

//==============================================================================
//
// S_GetMusicNumForName
//
//==============================================================================
function S_GetMusicNumForName(const mus_name: string): integer;

implementation

uses
  i_system,
  sounddata,
  w_wad,
  DelphiDoom.Audio.SfxRandomGroup;

var
  // given by the composition root (S_ConfigureSoundNumbers)
  sound_numbers: ISfxNumberResolver = nil;
  // given by the composition root (S_ConfigureMusicNumbers)
  music_numbers: IMusicNumberResolver = nil;

//==============================================================================
//
// S_ConfigureSoundNumbers
//
//==============================================================================
procedure S_ConfigureSoundNumbers(const AResolver: ISfxNumberResolver);
begin
  sound_numbers := AResolver;
end;

//==============================================================================
//
// S_ConfigureMusicNumbers
//
//==============================================================================
procedure S_ConfigureMusicNumbers(const AResolver: IMusicNumberResolver);
begin
  music_numbers := AResolver;
end;

//==============================================================================
//
// S_GetSoundNumForName
//
//==============================================================================
function S_GetSoundNumForName(const sfx_name: string): integer;
begin
  if sound_numbers = nil then
    I_Error('S_GetSoundNumForName(): the sound numbers are not configured (ComposeEngine was not called)');
  result := sound_numbers.NumberForName(sfx_name);
end;

//==============================================================================
//
// S_GetSoundNameForNum
//
//==============================================================================
function S_GetSoundNameForNum(const sfx_num: integer): string;
begin
  if sound_numbers = nil then
    I_Error('S_GetSoundNameForNum(): the sound numbers are not configured (ComposeEngine was not called)');
  // JVAL: strupper -> for safety
  result := sound_numbers.NameForNumber(sfx_num);
end;

//==============================================================================
// S_GetRandomSoundList
//
// JVAL
// Retrieve the random sound list for a sfx number
// Note
//  Random list is in range of '0'..'9', of the last char of sound name eg
//    dsxxx0
//    dsxxx1
//    dsxxx2
//    dsxxx3
//    dsxxx7
//    dsxxx9
// It is not required to be all the numbers in last char
// Random sound list is saved not only to the sfx_num, but also to other sounds numbers
// of the same 'random' group
// Check WAD for presence of lumps
// The names and lumps of the group are TSfxRandomGroup; the list of numbers is here,
// because it is shared by the records of the table
//
//==============================================================================
function S_GetRandomSoundList(const sfx_num: integer): TDNumberList;
var
  sfxname: string;
  sfxnum: integer;
  members: TArray<TSfxRandomMember>;
  i: integer;
begin
  sfxname := S_GetSoundNameForNum(sfx_num);
  if sfxname = '' then
  begin
    result := nil;
    exit;
  end;

  if S_sfx[sfx_num].randomsoundlist = nil then
    S_sfx[sfx_num].randomsoundlist := TDNumberList.Create;

  result := S_sfx[sfx_num].randomsoundlist;

  if result.Count > 0 then
    exit;

  if not TSfxRandomGroup.IsGroupName(sfxname) then
  begin
    result.Add(sfx_num);  // This sound for sure!
    exit;
  end;

  members := TSfxRandomGroup.Members(sfxname,
    function(const AName: string): Integer
    begin
      Result := W_CheckNumForName(AName);
    end);
  for i := 0 to Length(members) - 1 do
  begin
    sfxnum := S_GetSoundNumForName(members[i].Name);
    result.Add(sfxnum);
    S_sfx[sfxnum].lumpnum := members[i].LumpNumber; // Save the lump number
    if S_sfx[sfxnum].randomsoundlist = nil then
      S_sfx[sfxnum].randomsoundlist := result;
  end;
end;

//==============================================================================
//
// S_FreeRandomSoundLists
//
//==============================================================================
procedure S_FreeRandomSoundLists;
var
  i, j: integer;
  l: TDNumberList;
begin
  for i := 1 to numsfx - 1 do
  begin
    if S_sfx[i].randomsoundlist <> nil then
    begin
      l := S_sfx[i].randomsoundlist;
      for j := i + 1 to numsfx - 1 do
        if S_sfx[j].randomsoundlist = l then
          S_sfx[i].randomsoundlist := nil;
      FreeAndNil(S_sfx[i].randomsoundlist);
    end;
  end;
end;

//==============================================================================
//
// S_FreeMP3Streams
//
//==============================================================================
procedure S_FreeMP3Streams;
var
  i, j: integer;
  s: TDStream;
begin
  for i := 0 to nummusic - 1 do
    if S_music[i].mp3stream <> nil then
    begin
      s := S_music[i].mp3stream;
      for j := i + 1 to nummusic - 1 do
        if S_music[j].mp3stream = s then
          S_music[j].mp3stream := nil;
      FreeAndNil(S_music[i].mp3stream);
    end;
end;

//==============================================================================
//
// S_GetMusicNumForName
//
//==============================================================================
function S_GetMusicNumForName(const mus_name: string): integer;
begin
  if music_numbers = nil then
    I_Error('S_GetMusicNumForName(): the music numbers are not configured (ComposeEngine was not called)');
  result := music_numbers.NumberForName(mus_name);
end;

end.
