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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit sounds;

interface

uses
  d_delphi,
  DelphiDoom.ActorDef.Intf;

//==============================================================================
//
// S_ConfigureSoundAliases
//
// The aliases of SNDINFO (the table that the ACTORDEF lumps fill), given by the
// composition root; without it S_GetSoundNumForName stops with I_Error
//
//==============================================================================
procedure S_ConfigureSoundAliases(const AResolver: IActorDefSoundResolver);

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
  w_wad;

var
  // given by the composition root (S_ConfigureSoundAliases)
  sound_aliases: IActorDefSoundResolver = nil;

//==============================================================================
//
// S_ConfigureSoundAliases
//
//==============================================================================
procedure S_ConfigureSoundAliases(const AResolver: IActorDefSoundResolver);
begin
  sound_aliases := AResolver;
end;

//==============================================================================
//
// S_SoundAlias
//
//==============================================================================
function S_SoundAlias(const snd: string): string;
begin
  if sound_aliases = nil then
    I_Error('S_SoundAlias(): the sound aliases are not configured (ComposeEngine was not called)');
  result := sound_aliases.Resolve(snd);
end;

{$IFDEF DOOM}
var
  lastfreesfx: integer = 1;

{$ENDIF}
//==============================================================================
//
// S_GetSoundNumForName
//
//==============================================================================
function S_GetSoundNumForName(const sfx_name: string): integer;
var
  i: integer;
  name: string;
{$IFNDEF HEXEN}
  check: string;
{$ENDIF}
  sfx: Psfxinfo_t;
{$IFDEF DOOM}
  isnumber: boolean;
{$ENDIF}
begin
  result := atoi(sfx_name, -1);
{$IFDEF DOOM}
  isnumber := itoa(result) = sfx_name;
  if isnumber then
  begin
    if (result >= 0) and (result < numsfx) and isnumber then
      if S_sfx[result].name <> '' then
        exit;

    if (result >= 500) and (result < 700) then
      if S_sfx[result].name = 'fre' + IntToStrZfill(3, result) then // DEHEXTRA
      begin
        if numsfx <= result then
          numsfx := result + 1;
        sfx := @S_sfx[result];
        sfx.name := 'fre' + IntToStrZfill(3, result);
        sfx.singularity := false;
        sfx.priority := 72;
        sfx.link := nil;
        sfx.pitch := -1;
        sfx.volume := -1;
        sfx.data := nil;
        sfx.usefulness := 0;
        sfx.lumpnum := -1; // JVAL: was = 0;
        sfx.randomsoundlist := nil;
        exit;
      end;
  end;
{$ELSE}
  if (result >= 0) and (result < numsfx) and (itoa(result) = sfx_name) then
    exit;
{$ENDIF}

  if sfx_name = '' then
  begin
    I_Warning('S_GetSoundNumForName(): No sound name specified, using default'#13#10);
{$IF DEFINED(HERETIC)}
    result := Ord(sfx_gldhit);
{$ELSEIF DEFINED(HEXEN)}
    result := Ord(SFX_CHAT);
{$ELSEIF DEFINED(STRIFE)}
    result := Ord(sfx_mtalht);
{$ELSE}
    result := Ord(sfx_pistol);
{$ENDIF}
    exit;
  end;

  name := strupper(S_SoundAlias(sfx_name));
  for i := 1 to numsfx - 1 do
  begin
{$IFDEF HEXEN}
    sfx := @S_sfx[i];
    if (strupper(sfx.tagname) = name) or (strupper(sfx.name) = name) or ('DS' + strupper(sfx.name) = name) then
{$ELSE}
    check := strupper(S_sfx[i].name);
    if (check = name) or ('DS' + check = name) then
{$ENDIF}
    begin
      result := i;
      exit;
    end;
  end;

{$IFDEF DOOM}
  // JVAL: Not found, trying to find an empty slot
  for i := lastfreesfx to numsfx - 1 do
    if S_sfx[i].name = '' then
    begin
      result := i;
      lastfreesfx := i + 1;
      sfx := @S_sfx[result];
      sfx.name := name;
      sfx.singularity := false;
      sfx.priority := 72;
      sfx.link := nil;
      sfx.pitch := -1;
      sfx.volume := -1;
      sfx.data := nil;
      sfx.usefulness := 0;
      sfx.lumpnum := -1; // JVAL: was = 0;
      sfx.randomsoundlist := nil;
      exit;
    end;
{$ELSE}
  // JVAL: Not found, we will add a new sound
{$ENDIF}

{$IF DEFINED(DOOM)}
  // JVAL: Not found, we will add a new sound
  if numsfx >= MAX_NUMSFX - 1 then // JVAL: Limit exceeded, we will use default pistol sound :(
{$ELSEIF DEFINED(STRIFE)}
  if numsfx >= MAX_NUMSFX - 1 then // JVAL: Limit exceeded, we will use default pistol sound :(
{$ELSE}
  if numsfx >= MAX_NUMSFX - 1 then // JVAL: Limit exceeded, we will use default sound :(
{$ENDIF}
  begin
    I_Warning('S_GetSoundNumForName(): Can not add %s sound, limit of %d sounds exceeded'#13#10, [sfx_name, numsfx]);
{$IF DEFINED(HERETIC)}
    result := Ord(sfx_gldhit);
{$ELSEIF DEFINED(HEXEN)}
    result := Ord(SFX_CHAT);
{$ELSEIF DEFINED(STRIFE)}
    result := Ord(sfx_mtalht);
{$ELSE}
    result := Ord(sfx_pistol);
{$ENDIF}
    exit;
  end;

  // JVAL: Register the new sound

  if Pos1('DS', name) then
    name := Copy(name, 3, Length(name) - 2);
  if name = '' then // JVAL: Normally this should not happen!
  begin
    I_Warning('S_GetSoundNumForName(): No sound name specified, using default'#13#10);
{$IF DEFINED(HERETIC)}
    result := Ord(sfx_gldhit);
{$ELSEIF DEFINED(HEXEN)}
    result := Ord(SFX_CHAT);
{$ELSEIF DEFINED(STRIFE)}
    result := Ord(sfx_mtalht);
{$ELSE}
    result := Ord(sfx_pistol);
{$ENDIF}
    exit;
  end;

  result := numsfx;
  sfx := @S_sfx[result];
{$IFDEF HEXEN}
  sfx.tagname := sfx_name;
{$ENDIF}
  sfx.name := name;
{$IFNDEF HEXEN}
  sfx.singularity := false;
{$ENDIF}
  sfx.priority := 72;
{$IFNDEF HEXEN}
  sfx.link := nil;
{$ENDIF}
  sfx.pitch := -1;
{$IFNDEF HEXEN}
  sfx.volume := -1;
{$ENDIF}
  sfx.data := nil;
  sfx.usefulness := 0;
  sfx.lumpnum := -1; // JVAL: was = 0;
{$IFDEF HEXEN}
  sfx.numchannels := 1;
  sfx.changePitch := false;
{$ENDIF}
  sfx.randomsoundlist := nil;
  inc(numsfx);
end;

//==============================================================================
//
// S_GetSoundNameForNum
//
//==============================================================================
function S_GetSoundNameForNum(const sfx_num: integer): string;
begin
  if (sfx_num < 0) or (sfx_num >= numsfx) then
  begin
    result := '';
    exit;
  end;

  // JVAL: strupper -> for safety
  result := strupper(S_sfx[sfx_num].name);
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
//
//==============================================================================
function S_GetRandomSoundList(const sfx_num: integer): TDNumberList;
var
  sfxname: string;
  sfxname1: string;
  sfxname2: string;
  sfxname3: string;
  sfxnum: integer;
  check: integer;
  c: char;
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

  check := Ord(sfxname[Length(sfxname)]);
  if (check < Ord('0')) or (check > Ord('9')) then
  begin
    result.Add(sfx_num);  // This sound for sure!
    exit;
  end;

  // JVAL: look first for 'ds....' sound names
  if Pos1('DS', sfxname) then
  begin
    sfxname1 := sfxname;
    sfxname2 := Copy(sfxname, 3, Length(sfxname) - 2)
  end
  else
  begin
    sfxname1 := 'DS' + sfxname;
    sfxname2 := sfxname;
  end;
  sfxname3 := '';
  if Length(sfxname1) > 8 then
    SetLength(sfxname1, 8);
  if Length(sfxname2) > 8 then
    SetLength(sfxname2, 8);
  for c := '0' to '9' do
  begin
    sfxname1[Length(sfxname1)] := c;
    check := W_CheckNumForName(sfxname1);
    if check = -1 then
    begin
      sfxname2[Length(sfxname2)] := c;
      check := W_CheckNumForName(sfxname2);
      if check >= 0 then
        sfxname3 := sfxname2;
    end
    else
      sfxname3 := sfxname1;

    if check >= 0 then
    begin
      sfxnum := S_GetSoundNumForName(sfxname3);
      result.Add(sfxnum);
      S_sfx[sfxnum].lumpnum := check; // Save the lump number
      if S_sfx[sfxnum].randomsoundlist = nil then
        S_sfx[sfxnum].randomsoundlist := result;
    end;
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
var
  i: integer;
  name: string;
  check: string;
  pmus: Pmusicinfo_t;
begin
  result := atoi(mus_name, -1);
  if (result >= 0) and (result < nummusic) and (itoa(result) = mus_name) then
    exit;

  if mus_name = '' then
  begin
    I_Warning('S_GetMusicNumForName(): No music name specified, using default'#13#10);
    result := 0;
    exit;
  end;

  name := strupper(mus_name);
  for i := 1 to nummusic - 1 do
  begin
    check := strupper(S_music[i].name);
    if (check = name) or ('D_' + check = name) then
    begin
      result := i;
      exit;
    end;
  end;

  // JVAL: Not found, we will add a new sound

  if nummusic >= MAX_MUS - 1 then // JVAL: Limit exceeded, we will use default music :(
  begin
    I_Warning('S_GetMusicNumForName(): Can not add "%s" music, limit of %d music lumps exceeded'#13#10, [mus_name, nummusic]);
    result := 0;
    exit;
  end;

  // JVAL: Register the new music

  if Pos1('D_', name) then
    name := Copy(name, 3, Length(name) - 2);
  if name = '' then // JVAL: Normally this should not happen!
  begin
    I_Warning('S_GetMusicNumForName(): No sound name specified, using default'#13#10);
    result := 0;
    exit;
  end;

  result := nummusic;
  pmus := @S_Music[result];
  pmus.name := name;
  pmus.lumpnum := W_CheckNumForName('D_' + name);
  if pmus.lumpnum < 0 then
    pmus.lumpnum := W_CheckNumForName(name);
  inc(nummusic);
end;

end.

