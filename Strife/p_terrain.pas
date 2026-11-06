//------------------------------------------------------------------------------
//
//  DelphiStrife is a source port of the game Strife.
//
//  Based on:
//    - Linux Doom by "id Software"
//    - Chocolate Strife by "Simon Howard"
//    - DelphiDoom by "Jim Valavanis"
//
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2005 Simon Howard
//  Copyright (C) 2010 James Haley, Samuel Villarreal
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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_terrain;

interface

uses
  p_mobj_h,
  DelphiDoom.Definitions.Intf;

//==============================================================================
//
// P_TerrainTypeForName
//
//==============================================================================
function P_TerrainTypeForName(flatname: string): integer;

//==============================================================================
//
// P_GetTerrainType
//
//==============================================================================
function P_GetTerrainType(mobj: Pmobj_t): integer;

var
  allowterrainsplashes: boolean;

const
  FLOOR_SOLID = 0;
  FLOOR_WATER = 1;
  FLOOR_LAVA = 2;
  FLOOR_SLUDGE = 3;
  FLOOR_NUKAGE = 4;

procedure P_ConfigureTerrain(const ATable: IDefTerrainTable);

implementation

uses
  d_delphi,
  i_system,
  r_data,
  r_defs,
  w_wad,
  DelphiDoom.Definitions.Types;

var
  terrain_table: IDefTerrainTable;

procedure P_ConfigureTerrain(const ATable: IDefTerrainTable);
begin
  terrain_table := ATable;
end;

function P_TerrainTypeForName(flatname: string): integer;
begin
  if terrain_table = nil then
    I_Error('P_TerrainTypeForName(): the terrain table is not configured (ComposeEngine was not called)');

  case terrain_table.KindForName(strupper(flatname)) of
    TDefTerrainKind.Water: result := FLOOR_WATER;
    TDefTerrainKind.Lava: result := FLOOR_LAVA;
    TDefTerrainKind.Sludge: result := FLOOR_SLUDGE;
    TDefTerrainKind.Nukage: result := FLOOR_NUKAGE;
  else
    result := FLOOR_SOLID;
  end;
end;

function P_GetTerrainType(mobj: Pmobj_t): integer;
var
  ss: Psubsector_t;
begin
  ss := mobj.subsector;
  if mobj.z <= ss.sector.floorheight then
    result := P_TerrainTypeForName(char8tostring(flats[ss.sector.floorpic].name))
  else
    result := FLOOR_SOLID
end;

end.
