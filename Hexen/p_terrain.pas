//------------------------------------------------------------------------------
//
//  DelphiHexen is a source port of the game Hexen and it is
//  based on original Linux Doom as published by "id Software", on
//  Hexen source as published by "Raven" software and DelphiDoom
//  as published by Jim Valavanis.
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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_terrain;

interface

uses
  DelphiDoom.Definitions.Intf;

//==============================================================================
//
// P_TerrainTypeForName
//
//==============================================================================
function P_TerrainTypeForName(flatname: string): integer;

procedure P_ConfigureTerrain(const ATable: IDefTerrainTable);

implementation

uses
  d_delphi,
  i_system,
  p_local,
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
    TDefTerrainKind.Ice: result := FLOOR_ICE;
  else
    result := FLOOR_SOLID;
  end;
end;

end.
