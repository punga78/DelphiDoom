{******************************************************************************}
{                                                                              }
{  DelphiDoom: Radix game - the trigger grid of a level                        }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of radix_grid.pas of Rad-X. The grid is TRadixTriggerGrid of           }
{  Libs\Radix; here the sector of a point is asked to the engine. The position }
{  of a sector (radixmapXmult... of the sector_t of Rad-X) is the one of RMAP  }
{  in radixsectorinfo                                                          }
{                                                                              }
{******************************************************************************}

{$I Doom32.inc}

unit radix_grid;

interface

uses
  p_mobj_h,
  DelphiDoom.Radix.Level.Types,
  DelphiDoom.Radix.LevelLogic.Types,
  DelphiDoom.Radix.TriggerGrid;

var
  // The grid of the level; nil before the first level is loaded
  radixgrid: TRadixTriggerGrid = nil;

//==============================================================================
//
// RX_InitRadixGrid
// The grid of the level that is being loaded (RGRID and RMAPGRID read)
//
//==============================================================================
procedure RX_InitRadixGrid(const grid: TRadixTriggerGridData; const mappoints: TArray<TRadixLevelMapPoint>);

//==============================================================================
//
// RX_PosInGrid
// The cells of the grid that a craft is in during this tic
//
//==============================================================================
function RX_PosInGrid(const mo: Pmobj_t): TRadixGridPositions;

//==============================================================================
//
// RX_GridToMap
// Returns the upper-left corner of the grid rect in map coordinates
//
//==============================================================================
function RX_GridToMap(const grid_id: integer; var x, y: integer): boolean;

implementation

uses
  SysUtils,
  d_delphi,
  m_fixed,
  r_defs,
  r_main,
  radix_map_extra;

//==============================================================================
//
// RX_InitRadixGrid
//
//==============================================================================
procedure RX_InitRadixGrid(const grid: TRadixTriggerGridData; const mappoints: TArray<TRadixLevelMapPoint>);
begin
  FreeAndNil(radixgrid);
  radixgrid := TRadixTriggerGrid.Create(grid, mappoints);
end;

//==============================================================================
//
// RX_SectorPosition
// How the coordinates of RADIX.DAT became the ones of the sector
//
//==============================================================================
function RX_SectorPosition(const sec: Psector_t): TRadixSectorPosition;
var
  id: integer;
begin
  id := RX_SectorIndex(sec);
  if (id >= 0) and (id < Length(radixsectorinfo)) then
  begin
    result.XMul := radixsectorinfo[id].XMul;
    result.XAdd := radixsectorinfo[id].XAdd;
    result.YMul := radixsectorinfo[id].YMul;
    result.YAdd := radixsectorinfo[id].YAdd;
  end
  else
  begin
    result.XMul := 1;
    result.XAdd := 0;
    result.YMul := 1;
    result.YAdd := 0;
  end;
end;

//==============================================================================
//
// RX_PosInGrid
//
//==============================================================================
function RX_PosInGrid(const mo: Pmobj_t): TRadixGridPositions;
var
  samples: TRadixMovementSamples;
  sec: Psector_t;
  i: integer;
begin
  result := TRadixGridPositions.Empty;
  if (radixgrid = nil) or not radixgrid.HasGrid or (mo = nil) then
    exit;

  if not TRadixTriggerGrid.IsMoving(mo.momx, mo.momy) then
  begin
    sec := R_PointInSubSector(mo.x, mo.y).sector;
    result.Add(radixgrid.CellAt(RX_SectorPosition(sec), mo.x div FRACUNIT, mo.y div FRACUNIT));
    exit;
  end;

  // 3 steps between the mo movement
  samples := TRadixTriggerGrid.MovementSamples(mo.x, mo.y, mo.momx, mo.momy);
  for i := 0 to RADIX_MAX_GRID_POSITIONS - 1 do
  begin
    if i = RADIX_MAX_GRID_POSITIONS - 1 then
      sec := Psubsector_t(mo.subsector).sector // Current mo Position
    else
      sec := R_PointInSubSector(samples[i].X * FRACUNIT, samples[i].Y * FRACUNIT).sector;
    result.Add(radixgrid.CellAt(RX_SectorPosition(sec), samples[i].X, samples[i].Y));
  end;
end;

//==============================================================================
//
// RX_GridToMap
//
//==============================================================================
function RX_GridToMap(const grid_id: integer; var x, y: integer): boolean;
begin
  if radixgrid = nil then
  begin
    result := false;
    exit;
  end;
  result := radixgrid.TryCellToMap(grid_id, x, y);
end;

initialization

finalization
  FreeAndNil(radixgrid);

end.
