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
//  Play functions, animation, global header.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_local;

interface

uses
  doomtype,
  m_fixed,
  p_mobj_h,
  r_defs;

const
  TOCENTER = -8;
  TOFORWARD = -8;

{$IFDEF STRIFE}
  FLOATSPEED = FRACUNIT * 5;
{$ELSE}
  FLOATSPEED = FRACUNIT * 4;
{$ENDIF}

// Player VIEWHEIGHT
{$IFDEF HEXEN}
  PVIEWHEIGHT = 48 * FRACUNIT;
{$ELSE}
  PVIEWHEIGHT = 41 * FRACUNIT;
{$ENDIF}

// JVAL: 20211101 - Crouch
  PMAXCROUCHHEIGHT = 18 * FRACUNIT;

// mapblocks are used to check movement
// against lines and things
  MAPBLOCKUNITS = 128;
  MAPBLOCKSIZE = MAPBLOCKUNITS * FRACUNIT;

  MAPBLOCKSHIFT = FRACBITS + 7;
  MAPBTOFRAC = MAPBLOCKSHIFT - FRACBITS;

// MAXRADIUS is for precalculated sector block boxes
// the spider demon is larger,
// but we do not have any moving sectors nearby
  MAXRADIUS = 32 * FRACUNIT;

  GRAVITY = FRACUNIT;
  MAXMOVE = 30 * FRACUNIT;

  USERANGEINT = 64;
  USETHINGRANGEINT = 96;
  MELEERANGE = 64 * FRACUNIT;
{$IFDEF STRIFE}
  PLAYERMELEERANGE = 80 * FRACUNIT;
{$ENDIF}
  MISSILERANGE = (32 * 64) * FRACUNIT;

// follow a player exlusively for 3 seconds
  BASETHRESHOLD = 100;

{$IF DEFINED(HERETIC)}
const
  FLOOR_SOLID = 0;
  FLOOR_WATER = 1;
  FLOOR_LAVA = 2;
  FLOOR_SLUDGE = 3;
{$ELSEIF DEFINED(HEXEN)}
const
  FLOOR_SOLID = 0;
  FLOOR_ICE = 1;
  FLOOR_LIQUID = 2;
  FLOOR_WATER = 3;
  FLOOR_LAVA = 4;
  FLOOR_SLUDGE = 5;
{$ELSE}
  ONFLOORZ = MININT;

  ONCEILINGZ = MAXINT;

  ONFLOATZ = MAXINT - 1;

// the floors of Doom and Strife (they were in Doom\p_terrain.pas and Strife\p_terrain.pas)
  FLOOR_SOLID = 0;
  FLOOR_WATER = 1;
  FLOOR_LAVA = 2;
  FLOOR_SLUDGE = 3;
  FLOOR_NUKAGE = 4;
{$ENDIF}

{$IFDEF DOOM_OR_STRIFE}
var
  // the splashes of the things that fall in water, lava, sludge and nukage (Doom32.ini, menu, net)
  allowterrainsplashes: boolean;
{$ENDIF}

const
{$IF DEFINED(HERETIC)}
  STARTREDPALS = 1;
  STARTBONUSPALS = 9;
  NUMREDPALS = 8;
  NUMBONUSPALS = 4;

const
  ONFLOORZ = MININT;
  ONCEILINGZ = MAXINT;
  FLOATRANDZ = MAXINT - 1;
  ONFLOATZ = MAXINT - 2;
{$ELSEIF DEFINED(HEXEN)}
  STARTREDPALS = 1;
  STARTBONUSPALS = 9;
  STARTPOISONPALS = 13;
  STARTICEPAL = 21;
  STARTHOLYPAL = 22;
  STARTSCOURGEPAL = 25;
  NUMREDPALS = 8;
  NUMBONUSPALS = 4;
  NUMPOISONPALS = 8;

const
  ONFLOORZ = MININT;
  ONCEILINGZ = MAXINT;
  FLOATRANDZ = MAXINT - 1;
{$ELSEIF DEFINED(STRIFE)}
  FOOTCLIPSIZE = 13 * FRACUNIT;
{$ELSE}
  FOOTCLIPSIZE = 10 * FRACUNIT;
{$ENDIF}

type
  divline_t = record
    x: fixed_t;
    y: fixed_t;
    dx: fixed_t;
    dy: fixed_t;
  end;
  Pdivline_t = ^divline_t;
  divline_tArray = array[0..$FFFF] of divline_t;
  Pdivline_tArray = ^divline_tArray;

  thingORline_t = record
    case integer of
      0: (thing: Pmobj_t);
      1: (line: Pline_t);
    end;

  intercept_t = record
    frac: fixed_t; // along trace line
    isaline: boolean;
    d: thingORline_t;
  end;
  Pintercept_t = ^intercept_t;
  intercept_tArray = array[0..$FFFF] of intercept_t;
  Pintercept_tArray = ^intercept_tArray;

const
  MAXINTERCEPTS = 128;

type
  traverser_t = function(f: Pintercept_t): boolean;
  ltraverser_t = function(p: Pline_t): boolean;
  ttraverser_t = function(p: Pmobj_t): boolean;

const
  PT_ADDLINES = 1;
  PT_ADDTHINGS = 2;
  PT_EARLYOUT = 4;

{$IF DEFINED(HERETIC)}
const
  FOOTCLIPSIZE = 10 * FRACUNIT;

{$ELSEIF DEFINED(HEXEN)}
const
  USE_GWND_AMMO_1 = 1;
  USE_GWND_AMMO_2 = 1;
  USE_CBOW_AMMO_1 = 1;
  USE_CBOW_AMMO_2 = 1;
  USE_BLSR_AMMO_1 = 1;
  USE_BLSR_AMMO_2 = 5;
  USE_SKRD_AMMO_1 = 1;
  USE_SKRD_AMMO_2 = 5;
  USE_PHRD_AMMO_1 = 1;
  USE_PHRD_AMMO_2 = 1;
  USE_MACE_AMMO_1 = 1;
  USE_MACE_AMMO_2 = 5;

const
  FOOTCLIPSIZE = 10 * FRACUNIT;

{$ENDIF}
//==============================================================================
//
// MapBlockInt
//
//==============================================================================
function MapBlockInt(const x: integer): integer;

//==============================================================================
//
// MapBlockIntX
//
//==============================================================================
function MapBlockIntX(const x: int64): integer;

//==============================================================================
//
// MapBlockIntY
//
//==============================================================================
function MapBlockIntY(const y: int64): integer;

//==============================================================================
//
// MapToFrac
//
//==============================================================================
function MapToFrac(const x: integer): integer;

{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
//==============================================================================
//
// HITDICE
//
//==============================================================================
function HITDICE(a: integer): integer;

{$ENDIF}
implementation

uses
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  m_rnd,
{$ENDIF}
{$IFNDEF CPUX86}
  DelphiDoom.MathCore.FixedMath,
{$ENDIF}
  p_setup;

//==============================================================================
//
// MapBlockInt
//
//==============================================================================
{$IFDEF CPUX86}
function MapBlockInt(const x: integer): integer; assembler;
asm
  sar eax, MAPBLOCKSHIFT
end;
{$ELSE}
function MapBlockInt(const x: integer): integer;
begin
  // arithmetic shift: the Delphi shr is a logical one
  result := TFixedMath.ShiftRight(x, MAPBLOCKSHIFT);
end;
{$ENDIF}

//==============================================================================
//
// MapBlockIntX
//
//==============================================================================
function MapBlockIntX(const x: int64): integer;
begin
  result := x shr MAPBLOCKSHIFT;
  if result <= blockmapxneg then
    result := result and $1FF;
end;

//==============================================================================
//
// MapBlockIntY
//
//==============================================================================
function MapBlockIntY(const y: int64): integer;
begin
  result := y shr MAPBLOCKSHIFT;
  if result <= blockmapyneg then
    result := result and $1FF;
end;

//==============================================================================
//
// MapToFrac
//
//==============================================================================
{$IFDEF CPUX86}
function MapToFrac(const x: integer): integer; assembler;
asm
  sar eax, MAPBTOFRAC
end;
{$ELSE}
function MapToFrac(const x: integer): integer;
begin
  // arithmetic shift: the Delphi shr is a logical one
  result := TFixedMath.ShiftRight(x, MAPBTOFRAC);
end;
{$ENDIF}

{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
//==============================================================================
//
// HITDICE
//
//==============================================================================
function HITDICE(a: integer): integer;
begin
  result :=  (1 + (P_Random and 7)) * a;
end;

{$ENDIF}
end.

