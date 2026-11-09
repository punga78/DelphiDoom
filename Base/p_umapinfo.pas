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

// The records are made from the catalog of Libs\MapInfo by TEngineMapInfoRecords
// (DelphiDoom.Engine.MapInfo.Records)

implementation

end.
