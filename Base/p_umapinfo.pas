//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2023 by Jim Valavanis
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
//  UMAPINFO support: the text is read by Libs\MapInfo, here the records that the rest
//  of the engine reads are made from what the library found
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_umapinfo;

interface

uses
  DelphiDoom.MapInfo.Intf;

const
  BIGSTRINGSIZE = 1024;

type
  ubigstring_t = array[0..BIGSTRINGSIZE - 1] of AnsiChar;

type
  bossaction_t = record
    typ: integer;
    special: integer;
    tag: integer;
  end;
  bossaction_tArray = array[0..$FF] of bossaction_t;
  Pbossaction_tArray = ^bossaction_tArray;

  ulumpname_t = string[8];

  mapentry_t = record
    mapname: ulumpname_t;
    levelname: string[255];
    mlabel: string[255];
    intertext: ubigstring_t;
    intertextsecret: ubigstring_t;
    levelpic: ulumpname_t;
    nextmap: ulumpname_t;
    nextsecret: ulumpname_t;
    music: ulumpname_t;
    musicnum: integer;
    skytexture: ulumpname_t;
    skytexture2: ulumpname_t;
    endpic: ulumpname_t;
    exitpic: ulumpname_t;
    enterpic: ulumpname_t;
    interbackdrop: ulumpname_t;
    intermusic: ulumpname_t;
    intermusicnum: integer;
    partime: integer;
    nointermission: boolean;
    lightning: boolean;
    nojump: boolean;
    nocrouch: boolean;
    numbossactions: integer;
    bossactions: Pbossaction_tArray;
  end;
  Pmapentry_t = ^mapentry_t;
  mapentry_tArray = array[0..$FF] of mapentry_t;
  Pmapentry_tArray = ^mapentry_tArray;

  umapinfo_t = record
    mapcount: integer;
    maps: Pmapentry_tArray;
  end;

var
  u_mapinfo: umapinfo_t;
  default_mapinfo: umapinfo_t;

//==============================================================================
//
// U_ParseMapInfo
//
//==============================================================================
procedure U_ParseMapInfo(const is_default: boolean; const lumppname: string);

//==============================================================================
//
// U_FreeMapInfo
//
//==============================================================================
procedure U_FreeMapInfo;

//==============================================================================
//
// ubigstringtostring
//
//==============================================================================
function ubigstringtostring(const ub: ubigstring_t): string;

//==============================================================================
//
// U_ConfigureMapInfo
// The loader and the catalog of the UMAPINFO library, given by the composition root
//
//==============================================================================
procedure U_ConfigureMapInfo(const ALoader: IMapInfoLoader; const ACatalog: IMapInfoCatalog);


implementation

uses
  d_delphi,
  DelphiDoom.MapInfo.Types,
  i_system,
  z_zone;

var
  map_loader: IMapInfoLoader = nil;
  map_catalog: IMapInfoCatalog = nil;

//==============================================================================
//
// U_ConfigureMapInfo
//
//==============================================================================
procedure U_ConfigureMapInfo(const ALoader: IMapInfoLoader; const ACatalog: IMapInfoCatalog);
begin
  map_loader := ALoader;
  map_catalog := ACatalog;
end;

//==============================================================================
//
// ubigstringtostring
//
//==============================================================================
function ubigstringtostring(const ub: ubigstring_t): string;
var
  i: integer;
begin
  result := '';
  i := 0;
  while ub[i] <> #0 do
  begin
    result := result + ub[i];
    inc(i);
    if i = BIGSTRINGSIZE then
      exit;
  end;
end;

//==============================================================================
//
// stringtoubigstring
// The whole text, up to what fits with the terminator
//
//==============================================================================
function stringtoubigstring(const s: string): ubigstring_t;
var
  i, len: integer;
begin
  ZeroMemory(@result, SizeOf(result));
  len := Length(s);
  if len > BIGSTRINGSIZE - 1 then
    len := BIGSTRINGSIZE - 1;
  for i := 1 to len do
    result[i - 1] := AnsiChar(s[i]);
end;

//==============================================================================
//
// FreeMap
//
//==============================================================================
procedure FreeMap(mape: Pmapentry_t);
begin
  mape.mapname := '';
  mape.levelname := '';
  mape.mlabel := '';
  if mape.bossactions <> nil then
    Z_Free(mape.bossactions);
  mape.bossactions := nil;
end;

//==============================================================================
//
// FreeMaps
//
//==============================================================================
procedure FreeMaps(var info: umapinfo_t);
var
  i: integer;
begin
  for i := 0 to info.mapcount - 1 do
    FreeMap(@info.maps[i]);
  if info.maps <> nil then
    Z_Free(info.maps);
  info.maps := nil;
  info.mapcount := 0;
end;

//==============================================================================
//
// MakeMapEntry
// The record of the engine from the entry of the library
//
//==============================================================================
procedure MakeMapEntry(const e: TMapInfoEntry; mape: Pmapentry_t);
var
  i: integer;
begin
  ZeroMemory(mape, SizeOf(mapentry_t));
  mape.mapname := e.MapName;
  mape.levelname := e.LevelName;
  mape.mlabel := e.MapLabel;
  mape.intertext := stringtoubigstring(e.InterText);
  mape.intertextsecret := stringtoubigstring(e.InterTextSecret);
  mape.levelpic := e.LevelPic;
  mape.nextmap := e.NextMap;
  mape.nextsecret := e.NextSecret;
  mape.music := e.Music;
  mape.musicnum := e.MusicNumber;
  mape.skytexture := e.SkyTexture;
  mape.skytexture2 := e.SkyTexture2;
  mape.endpic := e.EndPic;
  mape.exitpic := e.ExitPic;
  mape.enterpic := e.EnterPic;
  mape.interbackdrop := e.InterBackdrop;
  mape.intermusic := e.InterMusic;
  mape.intermusicnum := e.InterMusicNumber;
  mape.partime := e.ParTime;
  mape.nointermission := e.NoIntermission;
  mape.lightning := e.Lightning;
  mape.nojump := e.NoJump;
  mape.nocrouch := e.NoCrouch;
  if e.BossActionsCleared then
    mape.numbossactions := -1
  else
    mape.numbossactions := Length(e.BossActions);
  if mape.numbossactions > 0 then
  begin
    mape.bossactions := Z_Malloc(SizeOf(bossaction_t) * mape.numbossactions, PU_STATIC, nil);
    for i := 0 to mape.numbossactions - 1 do
    begin
      mape.bossactions[i].typ := e.BossActions[i].ActorType;
      mape.bossactions[i].special := e.BossActions[i].Special;
      mape.bossactions[i].tag := e.BossActions[i].Tag;
    end;
  end;
end;

//==============================================================================
//
// U_ParseMapInfo
// The library reads the text and merges the maps; the records are made again from
// its catalog (the pointers to a record are taken afterwards, when a level starts)
//
//==============================================================================
procedure U_ParseMapInfo(const is_default: boolean; const lumppname: string);
var
  i: integer;
begin
  if map_loader = nil then
    I_Error('U_ParseMapInfo(): the UMAPINFO loader was not configured (U_ConfigureMapInfo)');

  map_loader.Load(lumppname, is_default);

  FreeMaps(default_mapinfo);
  default_mapinfo.mapcount := map_catalog.DefaultCount;
  if default_mapinfo.mapcount > 0 then
  begin
    default_mapinfo.maps := Z_Malloc(SizeOf(mapentry_t) * default_mapinfo.mapcount, PU_LEVEL, nil);
    for i := 0 to default_mapinfo.mapcount - 1 do
      MakeMapEntry(map_catalog.GetDefault(i), @default_mapinfo.maps[i]);
  end;

  FreeMaps(u_mapinfo);
  u_mapinfo.mapcount := map_catalog.MapCount;
  if u_mapinfo.mapcount > 0 then
  begin
    u_mapinfo.maps := Z_Malloc(SizeOf(mapentry_t) * u_mapinfo.mapcount, PU_STATIC, nil);
    for i := 0 to u_mapinfo.mapcount - 1 do
      MakeMapEntry(map_catalog.GetMap(i), @u_mapinfo.maps[i]);
  end;
end;

//==============================================================================
//
// U_FreeMapInfo
//
//==============================================================================
procedure U_FreeMapInfo;
begin
  FreeMaps(u_mapinfo);
  if map_catalog <> nil then
    map_catalog.ClearMaps;
end;

end.