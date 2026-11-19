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
//   Subsector precalc
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_subsectors;

interface

uses
  r_defs,
  m_fixed,
  DelphiDoom.Renderer.Intf;

var
  map_max_bound: integer;

type
  /// <summary>
  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #247,
  ///   wave 12): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TRendererSubsectors = class sealed
  public
    //==============================================================================
    //
    // R_PrecalcPointInSubSector
    //
    //==============================================================================
    class procedure R_PrecalcPointInSubSector; static;
    //==============================================================================
    //
    // R_PointInSubsectorPrecalc
    //
    //==============================================================================
    class function R_PointInSubsectorPrecalc(const x: fixed_t; const y: fixed_t): Psubsector_t; static;
    //==============================================================================
    //
    // R_ConfigureSubsectorGrid
    //
    //==============================================================================
    class procedure R_ConfigureSubsectorGrid(const ABuilder: IRendererSubsectorGridBuilder;
      const ALocator: IRendererSubsectorLocator); static;
  end;


implementation

uses
  d_delphi,
  i_system,
  DelphiDoom.Renderer.Types,
  p_setup,
  z_zone;

//
// R_PrecalcPointInSubSector
//
type
  pointinsubsector_t = array[0..$FFFF] of Psubsector_t;
  pointinsubsector_p = ^pointinsubsector_t;

const
  POINTINSUBSECTORACCURACY = 32 * FRACUNIT;

var
  pointinsubsector: pointinsubsector_p;
  // JVAL: 20200106 - Variables made int64, prevent overflow on big maps (eg Lost Civilization - MAP04)
  p_in_ss_width: int64;
  p_in_ss_height: int64;
  p_in_ss_minx, p_in_ss_miny: int64;
  p_in_ss_size: integer = -1;
  grid_builder: IRendererSubsectorGridBuilder;
  grid_locator: IRendererSubsectorLocator;

//==============================================================================
//
// R_PrecalcPointInSubSector
//
//==============================================================================
class procedure TRendererSubsectors.R_PrecalcPointInSubSector;
var
  i: integer;
  vertexx: TArray<Integer>;
  vertexy: TArray<Integer>;
  grid: TRendererSubsectorGrid;
begin
  if (grid_builder = nil) or (grid_locator = nil) then
    I_Error('R_PrecalcPointInSubSector(): R_ConfigureSubsectorGrid() was not called');

  printf('R_PrecalcPointInSubSector: Generating matrix.'#13#10);

  SetLength(vertexx, numvertexes);
  SetLength(vertexy, numvertexes);
  for i := 0 to numvertexes - 1 do
  begin
    vertexx[i] := vertexes[i].x;
    vertexy[i] := vertexes[i].y;
  end;

  try
    grid := grid_builder.Build(vertexx, vertexy, grid_locator);
  except
    on E: ERendererException do
      I_Error('%s', [E.Message]);
  end;

  map_max_bound := grid.MaxBound;
  p_in_ss_minx := grid.MinX;
  p_in_ss_miny := grid.MinY;
  p_in_ss_width := grid.Width;
  p_in_ss_height := grid.Height;

  p_in_ss_size := p_in_ss_width * p_in_ss_height;
  pointinsubsector := Z_Malloc(p_in_ss_size * SizeOf(Psubsector_t), PU_LEVEL, nil);
  ZeroMemory(pointinsubsector, p_in_ss_size * SizeOf(Psubsector_t));

  // the lookup of the renderer keeps pointers: it is read for every object
  for i := 0 to p_in_ss_size - 1 do
    if grid.Cells[i] >= 0 then
      pointinsubsector[i] := @subsectors[grid.Cells[i]];

  printf('  Hit rate is %2.2f%s (%d/%d)'#13#10,
    [grid.HitCount / (p_in_ss_width * p_in_ss_height) * 100, '%', grid.HitCount, p_in_ss_width * p_in_ss_height]);
end;

//==============================================================================
//
// R_ConfigureSubsectorGrid
// The builder of the grid of IdTech1\Renderer and the finder of the subsector of a point,
// given by the composition root
//
//==============================================================================
class procedure TRendererSubsectors.R_ConfigureSubsectorGrid(const ABuilder: IRendererSubsectorGridBuilder;
  const ALocator: IRendererSubsectorLocator);
begin
  grid_builder := ABuilder;
  grid_locator := ALocator;
end;
//==============================================================================
//
// R_PointInSubsectorPrecalc
//
//==============================================================================
class function TRendererSubsectors.R_PointInSubsectorPrecalc(const x: fixed_t; const y: fixed_t): Psubsector_t;
var
  idx: integer;
begin
  idx := ((x - p_in_ss_minx) div POINTINSUBSECTORACCURACY) + p_in_ss_width * ((y - p_in_ss_miny) div POINTINSUBSECTORACCURACY);
  if (idx < 0) or (idx >= p_in_ss_size) then
  begin
    result := nil;
    exit;
  end;
  result := pointinsubsector[idx];
end;

end.
