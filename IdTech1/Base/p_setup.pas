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
//   The structures of the level (TLevelLoader of DelphiDoom.Engine.Level.Loader loads them)
//   Do all the WAD I/O, get map description,
//   set up initial state and misc. LUTs.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_setup;

interface

uses
  d_delphi,
  doomdef,
  doomdata,
  m_fixed,
  p_mobj_h,
  p_udmf,
  r_defs;

{$IFDEF STRIFE}
const
  MAXRIFTSPOTS = 16;

var
// haleyjd 08/24/10: [STRIFE] rift spots for player spawning
  riftSpots: array[0..MAXRIFTSPOTS - 1] of mapthing_t;

{$ENDIF}
//==============================================================================
//
// P_GetMapName
//
//==============================================================================
{$IF DEFINED(DOOM)}
function P_GetMapName(const episode, map: integer): string;
{$ELSEIF DEFINED(HERETIC)}
function P_GetMapName(const episode, map: integer): string;

//==============================================================================
//
// P_GetMapTitle
//
//==============================================================================
function P_GetMapTitle(const ep, map: integer): string;
{$ELSE}
function P_GetMapName(const map: integer): string;
{$ENDIF}

var
// origin of block map
  bmaporgx: fixed_t;
  bmaporgy: fixed_t;

  numvertexes: integer;
  vertexes: Pvertex_tArray;

  numsegs: integer;
  segs: Pseg_tArray;

  numsectors: integer;
  sectors: Psector_tArray;

  numsubsectors: integer;
  subsectors: Psubsector_tArray;

  numnodes: integer;
  nodes: Pnode_tArray;

  numlines: integer;
  lines: Pline_tArray;

  numsides: integer;
  sides: Pside_tArray;

{$IFDEF DOOM}
  // Vanilla nodes
  numvanillasegs: integer;
  vanillasegs: Pvanillaseg_tArray;

  numvanillasubsectors: integer;
  vanillasubsectors: Pvanillasubsector_tArray;

  numvanillanodes: integer;
  vanillanodes: Pvanillanode_tArray;

  hasvanillanodes: boolean;

{$ENDIF}
//
// MAP related Lookup tables.
// Store VERTEXES, LINEDEFS, SIDEDEFS, etc.
//
var

// BLOCKMAP
// Created from axis aligned bounding box
// of the map, a rectangular array of
// blocks of size ...
// Used to speed up collision detection
// by spatial subdivision in 2D.
//
// Blockmap size.
  bmapwidth: integer;
  bmapheight: integer; // size in mapblocks
  bmapsize: integer;
  blockmap: PIntegerArray; // int for larger maps
// offsets in blockmap are from here
  blockmaplump: PIntegerArray;

  blockmapxneg: integer;
  blockmapyneg: integer;

  internalblockmapformat: boolean;

// for thing chains
type
  blocklinkitem_t = record
    size: integer;
    realsize: integer;
    links: Pmobj_tPArray;
  end;
  Pblocklinkitem_t = ^blocklinkitem_t;
  blocklinkarray_t = array[0..$FFFF] of blocklinkitem_t;
  Pblocklinkarray_t = ^blocklinkarray_t;

var
  blocklinks: Pblocklinkarray_t;
{$IFDEF DOOM}
  // for thing chains
  vanillablocklinks: Pmobj_tPArray;
{$ENDIF}

// REJECT
// For fast sight rejection.
// Speeds up enemy AI by skipping detailed
//  LineOf Sight calculation.
// Without special effect, this could be
//  used as a PVS lookup as well.
//
  rejectmatrix: PByteArray;
  rejectmatrixsize: integer;

  p_justspawned: boolean = false;

const
// Maintain single and multi player starting spots.
{$IFDEF HEXEN}
  MAX_DEATHMATCH_STARTS = 16;
  MAX_PLAYER_STARTS = 8;
{$ELSE}
  MAX_DEATHMATCH_STARTS = 10;
{$ENDIF}

var
  deathmatchstarts: array[0..MAX_DEATHMATCH_STARTS - 1] of mapthing_t;
  udeathmatchstarts: array[0..MAX_DEATHMATCH_STARTS - 1] of extrathing_t;
  deathmatch_p: integer;

{$IF DEFINED(HEXEN)}
  playerstarts: array[0..MAX_PLAYER_STARTS - 1, 0..MAXPLAYERS - 1] of mapthing_t;
  uplayerstarts: array[0..MAX_PLAYER_STARTS - 1, 0..MAXPLAYERS - 1] of extrathing_t;
{$ELSEIF DEFINED(STRIFE)}
  playerstarts: array[0..MAXPLAYERS - 1] of mapthing_t;
  uplayerstarts: array[0..MAXPLAYERS - 1] of extrathing_t;
{$ELSE}
  playerstarts: array[0..MAXPLAYERS - 1] of mapthing_t;
{$ENDIF}

//==============================================================================
//
// P_GameValidThing
//
//==============================================================================
function P_GameValidThing(const doomdnum: integer): boolean;

var
  useglnodesifavailable: boolean;

var
{$IFDEF DOOM}
  hidedoublicatedbarrels: boolean = true;

var
{$ENDIF}
  largemap: boolean;

implementation

uses
  doomtype,
  g_game,
  info,
{$IF DEFINED(HERETIC)}
  info_h,
  hu_stuff,
  p_umapinfo,
{$ELSEIF DEFINED(STRIFE)}
{$ELSE}
  info_h,
{$ENDIF}
  p_easyslope,
  doomstat;

// The level itself is loaded by TLevelLoader (DelphiDoom.Engine.Level.Loader), that the
// composition root gives to g_game and d_main: this unit keeps the structures of the level

//==============================================================================
//
// P_GameValidThing
//
//==============================================================================
function P_GameValidThing(const doomdnum: integer): boolean;
begin
  // Don't spawn DoomBuilder 3D Editing mode camera
  if doomdnum = 32000 then
  begin
    result := false;
    exit;
  end;
  if P_IsEasySlopeItem(doomdnum) then
  begin
    result := false;
    exit;
  end;
{$IF DEFINED(HERETIC)}
  // Do not registered monsters if shareware
  if gamemode = shareware then
  begin
    if (doomdnum = mobjinfo[Ord(MT_WSKULLROD)].doomednum) or
       (doomdnum = mobjinfo[Ord(MT_WPHOENIXROD)].doomednum) or
       (doomdnum = mobjinfo[Ord(MT_AMSKRDWIMPY)].doomednum) or
       (doomdnum = mobjinfo[Ord(MT_AMSKRDHEFTY)].doomednum) or
       (doomdnum = mobjinfo[Ord(MT_AMPHRDWIMPY)].doomednum) or
       (doomdnum = mobjinfo[Ord(MT_AMPHRDHEFTY)].doomednum) or
       (doomdnum = mobjinfo[Ord(MT_AMMACEWIMPY)].doomednum) or
       (doomdnum = mobjinfo[Ord(MT_AMMACEHEFTY)].doomednum) or
       (doomdnum = mobjinfo[Ord(MT_ARTISUPERHEAL)].doomednum) or
       (doomdnum = mobjinfo[Ord(MT_ARTITELEPORT)].doomednum) or
       (doomdnum = mobjinfo[Ord(MT_ITEMSHIELD2)].doomednum) then
    begin
      result := false;
      exit;
    end;
    // Enemies
    case doomdnum of
       7, // MTSORCERER1
       9, // MT_MINOTAUR
      70, // MT_BEAST
      90, // MT_CLINK
      92: // MT_SNAKE
        begin
          result := false;
          exit;
        end;
      end;
  end;

{$ELSEIF DEFINED(HEXEN)}
  // Do not registered monsters if shareware
  if gamemode = shareware then
  begin
    case doomdnum of
      34,     // MT_WRAITG
      114,    // MT_BISHOP
      254,    // MT_DRAGON
      8101,   // MT_ZSHRUB1
      8080,   // MT_DEMON2
      8102,   // MT_ZSHRUB2
      10080,  // MT_SORCBOSS
      10200:  // MT_KORAX
        begin
          result := false;
          exit;
        end;
    end;
  end;

{$ELSEIF DEFINED(STRIFE)}
{$ELSE}
  // Do not spawn cool, new monsters if !commercial
  if gamemode <> commercial then
  begin
    case doomdnum of
      68, // Arachnotron
      64, // Archvile
      88, // Boss Brain
      89, // Boss Shooter
      69, // Hell Knight
      67, // Mancubus
      71, // Pain Elemental
      65, // Former Human Commando
      66, // Revenant
      84: // Wolf SS
        begin
          result := false;
          exit;
        end;
    end;
  end;

{$ENDIF}
  result := true;
end;

//==============================================================================
//
// P_GetMapName
//
//==============================================================================
{$IF DEFINED(HEXEN) OR DEFINED(STRIFE)}
function P_GetMapName(const map: integer): string;
{$ELSE}
function P_GetMapName(const episode, map: integer): string;
{$ENDIF}
begin
  // find map name
{$IF DEFINED(HERETIC)}
  sprintf(result, 'E%dM%d', [episode, map]);
{$ELSEIF DEFINED(HEXEN)}
  if map < 10 then
    sprintf(result,'MAP0%d', [map])
  else
    sprintf(result,'MAP%d', [map]);
{$ELSEIF DEFINED(STRIFE)}
  if map < 10 then
    sprintf(result,'map0%d', [map])
  else
    sprintf(result,'map%d', [map]);
{$ELSE}
  if gamemode = commercial then
  begin
    if map < 10 then
      sprintf(result,'map0%d', [map])
    else
      sprintf(result,'map%d', [map]);
  end
  else
    sprintf(result, 'E%dM%d', [episode, map]);
{$ENDIF}
end;

{$IFDEF HERETIC}
//==============================================================================
//
// P_GetMapTitle
//
//==============================================================================
function P_GetMapTitle(const ep, map: integer): string;
var
  entry: Pmapentry_t;
  idx: integer;
begin
  entry := G_LookupMapinfo(ep, map);
  if (entry <> nil) and (entry.levelname <> '') and (entry.levelname <> '-') then
  begin
    result := entry.levelname
  end
  else
  begin
    idx := (ep - 1) * 9 + map - 1;
    if IsIntegerInRange(idx, 0, 44) then
      result := mapnames[idx]
    else
      result := P_GetMapName(ep, map);
  end;
end;
{$ENDIF}

end.
