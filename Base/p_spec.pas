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
// P_FindLowestFloorSurrounding()
// FIND LOWEST FLOOR HEIGHT IN SURROUNDING SECTORS
//
//==============================================================================
function P_FindLowestFloorSurrounding(sec: Psector_t): fixed_t;

implementation

uses
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

end.
