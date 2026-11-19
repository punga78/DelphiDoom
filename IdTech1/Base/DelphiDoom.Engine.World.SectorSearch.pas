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
//  Searches in the sectors and the lines around a sector (BOOM, jff 2/3/98):
//  next lowest and highest floor and ceiling, shortest texture, model sector.
//
//  Same code in Doom and Strife (issue #185, step 2g): one copy in Base, compiled
//  by the projects of those two games only.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit DelphiDoom.Engine.World.SectorSearch;

interface

uses
  m_fixed,
  r_defs,
  p_spec_h;

//==============================================================================
// P_SectorActive
//
// JVAL: BOOM compatibility
//
//==============================================================================
function P_SectorActive(const s: special_e; const sec: Psector_t): boolean;

//==============================================================================
//
// P_FindNextLowestFloor
//
//==============================================================================
function P_FindNextLowestFloor(sec: Psector_t; currentheight: fixed_t): fixed_t;

//==============================================================================
//
// P_FindNextLowestCeiling
//
//==============================================================================
function P_FindNextLowestCeiling(sec: Psector_t; currentheight: fixed_t): fixed_t;

//==============================================================================
//
// P_FindNextHighestCeiling
//
//==============================================================================
function P_FindNextHighestCeiling(sec: Psector_t; currentheight: fixed_t): fixed_t;

//==============================================================================
//
// P_FindShortestTextureAround
//
//==============================================================================
function P_FindShortestTextureAround(secnum: integer): fixed_t;

//==============================================================================
//
// P_FindShortestUpperAround
//
//==============================================================================
function P_FindShortestUpperAround(secnum: integer): fixed_t;

//==============================================================================
//
// P_FindModelFloorSector
//
//==============================================================================
function P_FindModelFloorSector(floordestheight: fixed_t; secnum: integer): Psector_t;

//==============================================================================
//
// P_FindModelCeilingSector
//
//==============================================================================
function P_FindModelCeilingSector(ceildestheight: fixed_t; secnum: integer): Psector_t;

//==============================================================================
//
// P_FindLineFromLineTag2
//
//==============================================================================
function P_FindLineFromLineTag2(line: Pline_t; var start: integer): integer;

implementation

uses
  d_delphi,
  g_game,
  r_data,
  p_setup,
  p_spec;

//==============================================================================
//
// getSector()
// Will return a sector_t*
//  given the number of the current sector,
//  the line number and the side (0/1) that you want.
//
//==============================================================================
function getSector(currentSector: integer; line: integer; side: integer): Psector_t;
var
  sidenum: integer;
begin
  sidenum := (sectors[currentSector].lines[line]).sidenum[side];
  if sidenum >= 0 then
    result := sides[sidenum].sector
  else
    result := nil;
end;

//==============================================================================
// P_SectorActive
//
// JVAL: BOOM compatibility
//
//==============================================================================
function P_SectorActive(const s: special_e; const sec: Psector_t): boolean;
begin
  case s of
    floor_special: result := sec.floordata <> nil;
    ceiling_special: result := sec.ceilingdata <> nil;
    lighting_special:  result := sec.lightingdata <> nil;
  else
    result := false;
  end;
end;

//==============================================================================
//
// P_FindNextLowestFloor()
//
// Passed a sector and a floor height, returns the fixed point value
// of the largest floor height in a surrounding sector smaller than
// the floor height passed. If no such height exists the floorheight
// passed is returned.
//
// jff 02/03/98 Twiddled Lee's P_FindNextHighestFloor to make this
//
// JVAL BOOM compatibility
//
//==============================================================================
function P_FindNextLowestFloor(sec: Psector_t; currentheight: fixed_t): fixed_t;
var
  other: Psector_t;
  i: integer;
begin
  i := 0;
  while i < sec.linecount - 1 do
  begin
    other := getNextSector(sec.lines[i], sec);
    if (other <> nil) and (other.floorheight < currentheight) then
    begin
      result := other.floorheight;
      inc(i);
      while i < sec.linecount do
      begin
        other := getNextSector(sec.lines[i], sec);
        if other <> nil then
          if (other.floorheight > result) and (other.floorheight < currentheight) then
            result := other.floorheight;
        inc(i);
      end;
      exit;
    end;
    inc(i);
  end;
  result := currentheight;
end;

//==============================================================================
//
// P_FindNextLowestCeiling()
//
// Passed a sector and a ceiling height, returns the fixed point value
// of the largest ceiling height in a surrounding sector smaller than
// the ceiling height passed. If no such height exists the ceiling height
// passed is returned.
//
// jff 02/03/98 Twiddled Lee's P_FindNextHighestFloor to make this
//
// JVAL BOOM compatibility
//
//==============================================================================
function P_FindNextLowestCeiling(sec: Psector_t; currentheight: fixed_t): fixed_t;
var
  other: Psector_t;
  i: integer;
begin
  i := 0;
  while i < sec.linecount - 1 do
  begin
    other := getNextSector(sec.lines[i], sec);
    if (other <> nil) and (other.ceilingheight < currentheight) then
    begin
      result := other.ceilingheight;
      inc(i);
      while i < sec.linecount do
      begin
        other := getNextSector(sec.lines[i], sec);
        if other <> nil then
          if (other.ceilingheight > result) and (other.ceilingheight < currentheight) then
            result := other.ceilingheight;
        inc(i);
      end;
      exit;
    end;
    inc(i);
  end;
  result := currentheight;
end;

//==============================================================================
//
// P_FindNextHighestCeiling()
//
// Passed a sector and a ceiling height, returns the fixed point value
// of the smallest ceiling height in a surrounding sector larger than
// the ceiling height passed. If no such height exists the ceiling height
// passed is returned.
//
// jff 02/03/98 Twiddled Lee's P_FindNextHighestFloor to make this
//
// JVAL BOOM compatibility
//
//==============================================================================
function P_FindNextHighestCeiling(sec: Psector_t; currentheight: fixed_t): fixed_t;
var
  other: Psector_t;
  i: integer;
begin
  i := 0;
  while i < sec.linecount - 1 do
  begin
    other := getNextSector(sec.lines[i], sec);
    if (other <> nil) and (other.ceilingheight > currentheight) then
    begin
      result := other.ceilingheight;
      inc(i);
      while i < sec.linecount do
      begin
        other := getNextSector(sec.lines[i], sec);
        if other <> nil then
          if (other.ceilingheight < result) and (other.ceilingheight > currentheight) then
            result := other.ceilingheight;
        inc(i);
      end;
      exit;
    end;
    inc(i);
  end;
  result := currentheight;
end;

//==============================================================================
//
// P_FindShortestTextureAround()
//
// Passed a sector number, returns the shortest lower texture on a
// linedef bounding the sector.
//
// Note: If no lower texture exists 32000*FRACUNIT is returned.
//       but if compatibility then MAXINT is returned
//
// jff 02/03/98 Add routine to find shortest lower texture
//
// JVAL BOOM compatibility
//
//==============================================================================
function P_FindShortestTextureAround(secnum: integer): fixed_t;
var
  side: Pside_t;
  i: integer;
  sec: Psector_t;
begin
  sec := @sectors[secnum];

  result := 32000 * FRACUNIT; //jff 3/13/98 prevent overflow in height calcs

  for i := 0 to sec.linecount - 1 do
    if twoSidedS(sec, i) then
    begin
      side := getSide(secnum, i, 0);
      if side.bottomtexture > 0 then  //jff 8/14/98 texture 0 is a placeholder
        if textureheight[side.bottomtexture] < result then
          result := textureheight[side.bottomtexture];
      side := getSide(secnum, i, 1);
      if side.bottomtexture > 0 then  //jff 8/14/98 texture 0 is a placeholder
        if textureheight[side.bottomtexture] < result then
          result := textureheight[side.bottomtexture];
    end;

end;

//==============================================================================
//
// P_FindShortestUpperAround()
//
// Passed a sector number, returns the shortest upper texture on a
// linedef bounding the sector.
//
// Note: If no upper texture exists 32000*FRACUNIT is returned.
//       but if compatibility then MAXINT is returned
//
// jff 03/20/98 Add routine to find shortest upper texture
//
// JVAL BOOM compatibility
//
//==============================================================================
function P_FindShortestUpperAround(secnum: integer): fixed_t;
var
  side: Pside_t;
  i: integer;
  sec: Psector_t;
begin
  sec := @sectors[secnum];

  result := 32000 * FRACUNIT; //jff 3/13/98 prevent overflow in height calcs

  for i := 0 to sec.linecount - 1 do
    if twoSidedS(sec, i) then
    begin
      side := getSide(secnum, i, 0);
      if side.toptexture > 0 then  //jff 8/14/98 texture 0 is a placeholder
        if textureheight[side.toptexture] < result then
          result := textureheight[side.toptexture];
      side := getSide(secnum, i, 1);
      if side.toptexture > 0 then  //jff 8/14/98 texture 0 is a placeholder
        if textureheight[side.toptexture] < result then
          result := textureheight[side.toptexture];
    end;

end;

//==============================================================================
//
// P_FindModelFloorSector()
//
// Passed a floor height and a sector number, return a pointer to a
// a sector with that floor height across the lowest numbered two sided
// line surrounding the sector.
//
// Note: If no sector at that height bounds the sector passed, return NULL
//
// jff 02/03/98 Add routine to find numeric model floor
//  around a sector specified by sector number
// jff 3/14/98 change first parameter to plain height to allow call
//  from routine not using floormove_t
//
// JVAL BOOM compatibility
//
//==============================================================================
function P_FindModelFloorSector(floordestheight: fixed_t; secnum: integer): Psector_t;
var
  i: integer;
  linecount: integer;

  function _getLcount(const sec: Psector_t): integer;
  begin
    if G_NeedsCompatibilityMode and (sec.linecount < linecount) then
      result := sec.linecount
    else
      result := linecount;
  end;

begin
  result := @sectors[secnum]; //jff 3/2/98 woops! better do this
  //jff 5/23/98 don't disturb sec->linecount while searching
  // but allow early exit in old demos
  linecount := result.linecount;
  i := 0;
  while i < _getLcount(result) do
  begin
    if twoSided(secnum, i) then
    begin
      if pDiff(getSide(secnum, i, 0).sector, sectors, SizeOf(sector_t)) = secnum then
        result := getSector(secnum, i, 1)
      else
        result := getSector(secnum, i, 0);

      if result <> nil then
        if result.floorheight = floordestheight then
          exit;
    end;
    inc(i);
  end;
  result := nil;
end;

//==============================================================================
//
// P_FindModelCeilingSector()
//
// Passed a ceiling height and a sector number, return a pointer to a
// a sector with that ceiling height across the lowest numbered two sided
// line surrounding the sector.
//
// Note: If no sector at that height bounds the sector passed, return NULL
//
// jff 02/03/98 Add routine to find numeric model ceiling
//  around a sector specified by sector number
//  used only from generalized ceiling types
// jff 3/14/98 change first parameter to plain height to allow call
//  from routine not using ceiling_t
//
// JVAL BOOM compatibility
//
//==============================================================================
function P_FindModelCeilingSector(ceildestheight: fixed_t; secnum: integer): Psector_t;
var
  i: integer;
  linecount: integer;

  function _getLcount(const sec: Psector_t): integer;
  begin
    if G_NeedsCompatibilityMode and (sec.linecount < linecount) then
      result := sec.linecount
    else
      result := linecount;
  end;

begin
  result := @sectors[secnum]; //jff 3/2/98 woops! better do this
  //jff 5/23/98 don't disturb sec->linecount while searching
  // but allow early exit in old demos
  linecount := result.linecount;
  i := 0;
  while i < _getLcount(result) do
  begin
    if twoSided(secnum, i) then
    begin
      if pDiff(getSide(secnum, i, 0).sector, sectors, SizeOf(sector_t)) = secnum then
        result := getSector(secnum, i, 1)
      else
        result := getSector(secnum, i, 0);

      if result <> nil then
        if result.ceilingheight = ceildestheight then
          exit;
    end;
    inc(i);
  end;
  result := nil;
end;

//==============================================================================
//
// P_FindLineFromLineTag2
//
//==============================================================================
function P_FindLineFromLineTag2(line: Pline_t; var start: integer): integer;
var
  i: integer;
begin
  for i := start + 1 to numlines - 1 do
    if lines[i].tag = line.tag then
    begin
      result := i;
      start := result;
      exit;
    end;

  result := -1;
  start := -1;
end;

end.
