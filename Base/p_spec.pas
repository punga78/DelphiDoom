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
//  Implements special effects:
//  Texture animation, height or lighting changes
//   according to adjacent sectors, respective
//   utility functions, etc.
//  Line Tag handling. Line and Sector triggers.
//
//  One copy for the four games (issue #185, step 2g). The types of the
//  specials (the thinker records, the enumerations) are in the unit p_spec_h
//  of the folder of the game; what a game does differently is in
//  TSpecGameRules, the class of the unit DelphiDoom.Engine.World.SpecRules of
//  the folder of the game (chosen by the project: static calls, no virtual
//  call and no interface), together with the routines that only that game has.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_spec;

interface

uses
  m_fixed,
  r_defs;

//
// P_FindNextHighestFloor
// FIND NEXT HIGHEST FLOOR IN SURROUNDING SECTORS
// Note: this should be doable w/o a fixed array.

// 20 adjoining sectors max!  // JVAL changed to 64
const
  MAX_ADJOINING_SECTORS = 64; // JVAL was = 20

//==============================================================================
// UTILITIES
//
// getSide()
// Will return a side_t*
//  given the number of the current sector,
//  the line number, and the side (0/1) that you want.
//
//==============================================================================
function getSide(currentSector: integer; line: integer; side: integer): Pside_t;

//==============================================================================
//
// twoSided()
// Given the sector number and the line number,
//  it will tell you whether the line is two-sided or not.
//
//==============================================================================
function twoSided(sector: integer; line: integer): boolean;

//==============================================================================
//
// twoSidedS
//
//==============================================================================
function twoSidedS(sector: Psector_t; line: integer): boolean;

//==============================================================================
//
// getNextSector()
// Return sector_t * of sector next to current.
// NULL if not two-sided line
//
//==============================================================================
function getNextSector(line: Pline_t; sec: Psector_t): Psector_t;

//==============================================================================
//
// P_FindLowestFloorSurrounding()
// FIND LOWEST FLOOR HEIGHT IN SURROUNDING SECTORS
//
//==============================================================================
function P_FindLowestFloorSurrounding(sec: Psector_t): fixed_t;

//==============================================================================
//
// P_FindHighestFloorSurrounding()
// FIND HIGHEST FLOOR HEIGHT IN SURROUNDING SECTORS
//
//==============================================================================
function P_FindHighestFloorSurrounding(sec: Psector_t): fixed_t;

//==============================================================================
//
// P_FindNextHighestFloor
// FIND NEXT HIGHEST FLOOR IN SURROUNDING SECTORS
//
//==============================================================================
function P_FindNextHighestFloor(sec: Psector_t; currentheight: integer): fixed_t;

//==============================================================================
//
// P_FindLowestCeilingSurrounding()
// FIND LOWEST CEILING IN THE SURROUNDING SECTORS
//
//==============================================================================
function P_FindLowestCeilingSurrounding(sec: Psector_t): fixed_t;

//==============================================================================
//
// P_FindHighestCeilingSurrounding()
// FIND HIGHEST CEILING IN THE SURROUNDING SECTORS
//
//==============================================================================
function P_FindHighestCeilingSurrounding(sec: Psector_t): fixed_t;

//==============================================================================
//
// P_FindSectorFromLineTag
//
// RETURN NEXT SECTOR # THAT LINE TAG REFERS TO
//
//==============================================================================
function P_FindSectorFromLineTag(line: Pline_t; start: integer): integer;

//==============================================================================
//
// P_FindSectorFromLineTag2
//
//==============================================================================
function P_FindSectorFromLineTag2(line: Pline_t; var start: integer): integer;

implementation

uses
  d_delphi,
  doomdata,
  i_system,
  p_setup,
  DelphiDoom.Engine.World.SpecRules;

//==============================================================================
//
// getSide
//
//==============================================================================
function getSide(currentSector: integer; line: integer; side: integer): Pside_t;
begin
  result := @sides[(sectors[currentSector].lines[line]).sidenum[side]];
end;

//==============================================================================
//
// twoSided
//
//==============================================================================
function twoSided(sector: integer; line: integer): boolean;
begin
  if TSpecGameRules.TwoSidedByFlag then
    result := sectors[sector].lines[line].flags and ML_TWOSIDED <> 0
  else
    result := sectors[sector].lines[line].sidenum[1] <> -1;
end;

//==============================================================================
//
// twoSidedS
//
//==============================================================================
function twoSidedS(sector: Psector_t; line: integer): boolean;
begin
  result := sector.lines[line].sidenum[1] <> -1;
end;

//==============================================================================
//
// getNextSector
//
//==============================================================================
function getNextSector(line: Pline_t; sec: Psector_t): Psector_t;
var
  oldcompatibility: boolean;
begin
  oldcompatibility := TSpecGameRules.NextSectorCompatible;
  if oldcompatibility then
  begin
    if line.flags and ML_TWOSIDED = 0 then
    begin
      result := nil;
      exit;
    end;
  end;

  if line.frontsector = sec then
  begin
    if oldcompatibility or (line.backsector <> sec) then
      result := line.backsector
    else
      result := nil;
    exit;
  end;

  result := line.frontsector;
end;

//==============================================================================
//
// P_FindLowestFloorSurrounding
//
//==============================================================================
function P_FindLowestFloorSurrounding(sec: Psector_t): fixed_t;
var
  i: integer;
  check: Pline_t;
  other: Psector_t;
begin
  result := sec.floorheight;

  for i := 0 to sec.linecount - 1 do
  begin
    check := sec.lines[i];
    other := getNextSector(check, sec);

    if other <> nil then
      if other.floorheight < result then
        result := other.floorheight;
  end;
end;

//==============================================================================
//
// P_FindHighestFloorSurrounding
//
//==============================================================================
function P_FindHighestFloorSurrounding(sec: Psector_t): fixed_t;
var
  i: integer;
  check: Pline_t;
  other: Psector_t;
begin
  result := TSpecGameRules.HighestFloorStart;

  for i := 0 to sec.linecount - 1 do
  begin
    check := sec.lines[i];
    other := getNextSector(check, sec);

    if other <> nil then
      if other.floorheight > result then
        result := other.floorheight;
  end;
end;

//==============================================================================
//
// P_FindNextHighestFloor
//
//==============================================================================
function P_FindNextHighestFloor(sec: Psector_t; currentheight: integer): fixed_t;
var
  i: integer;
  h: integer;
  check: Pline_t;
  other: Psector_t;
  height: fixed_t;
  heightlist: array[0..MAX_ADJOINING_SECTORS] of fixed_t;
  maxsecs: integer;
begin
  maxsecs := TSpecGameRules.AdjoiningSectorsLimit;
  height := currentheight;

  h := 0;
  for i := 0 to sec.linecount - 1 do
  begin
    check := sec.lines[i];
    other := getNextSector(check, sec);

    if other <> nil then
    begin
      if other.floorheight > height then
      begin
        heightlist[h] := other.floorheight;
        inc(h);
      end;

      // Check for overflow. Exit.
      if h >= maxsecs then
      begin
        I_Warning('P_FindNextHighestFloor(): Sector with more than %d adjoining sectors.'#13#10, [maxsecs]);
        break;
      end;
    end;
  end;

  // Find lowest height in list
  if h = 0 then
  begin
    result := currentheight;
    exit;
  end;

  result := heightlist[0];

  // Range checking?
  for i := 1 to h - 1 do
    if heightlist[i] < result then
      result := heightlist[i];
end;

//==============================================================================
//
// P_FindLowestCeilingSurrounding
//
//==============================================================================
function P_FindLowestCeilingSurrounding(sec: Psector_t): fixed_t;
var
  i: integer;
  check: Pline_t;
  other: Psector_t;
begin
  result := TSpecGameRules.LowestCeilingStart;

  for i := 0 to sec.linecount - 1 do
  begin
    check := sec.lines[i];
    other := getNextSector(check, sec);

    if other <> nil then
      if other.ceilingheight < result then
        result := other.ceilingheight;
  end;
end;

//==============================================================================
//
// P_FindHighestCeilingSurrounding
//
//==============================================================================
function P_FindHighestCeilingSurrounding(sec: Psector_t): fixed_t;
var
  i: integer;
  check: Pline_t;
  other: Psector_t;
begin
  result := TSpecGameRules.HighestCeilingStart;

  for i := 0 to sec.linecount - 1 do
  begin
    check := sec.lines[i];
    other := getNextSector(check, sec);

    if other <> nil then
      if other.ceilingheight > result then
        result := other.ceilingheight;
  end;
end;

//==============================================================================
//
// P_FindSectorFromLineTag
//
//==============================================================================
function P_FindSectorFromLineTag(line: Pline_t; start: integer): integer;
var
  i: integer;
  tag: integer;
begin
  tag := TSpecGameRules.LineSectorTag(line);
  for i := start + 1 to numsectors - 1 do
    if sectors[i].tag = tag then
    begin
      result := i;
      exit;
    end;

  result := -1;
end;

//==============================================================================
//
// P_FindSectorFromLineTag2
//
//==============================================================================
function P_FindSectorFromLineTag2(line: Pline_t; var start: integer): integer;
var
  i: integer;
  tag: integer;
begin
  tag := TSpecGameRules.LineSectorTag(line);
  for i := start + 1 to numsectors - 1 do
    if sectors[i].tag = tag then
    begin
      result := i;
      start := result;
      exit;
    end;

  result := -1;
  start := -1;
end;

end.
