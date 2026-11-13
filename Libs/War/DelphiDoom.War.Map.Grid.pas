{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the spatial grid of the units                     }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map_grid.c, (c) 2019 Alejandro Coto        }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an         }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Map.Grid;

interface

uses
  System.SysUtils, DelphiDoom.War.Level.Types;

const
  /// <summary>MAP_GRID_TILE_SIZE: tiles of the map in a cell of the grid, per side</summary>
  WAR_MAP_GRID_TILE_SIZE = 4;
  /// <summary>MAP_GRID_TILES_WIDTH and HEIGHT: 16 x 16 cells</summary>
  WAR_MAP_GRID_TILES_WIDTH = WAR_MAP_TILES_WIDTH div WAR_MAP_GRID_TILE_SIZE;
  WAR_MAP_GRID_TILES_HEIGHT = WAR_MAP_TILES_HEIGHT div WAR_MAP_GRID_TILE_SIZE;
  /// <summary>MAP_GRID_CELLS</summary>
  WAR_MAP_GRID_CELLS = WAR_MAP_GRID_TILES_WIDTH * WAR_MAP_GRID_TILES_HEIGHT;

type
  /// <summary>What the grid needs of a unit of the game (the entity and its components in the original)</summary>
  TWarGridUnit = record
    /// <summary>The slot of the unit in the entity table (0..1023)</summary>
    Slot: Integer;
    /// <summary>
    ///   The unit is in the grid: it has its transform enabled and is neither going to die nor collapsing nor
    ///   going to collapse
    /// </summary>
    Active: Boolean;
    /// <summary>The tile of the center of the unit (wu_getUnitCenterTile)</summary>
    TileX: Single;
    TileY: Single;
  end;

  /// <summary>
  ///   Each cell of 4 x 4 tiles has the list of the units in it as a chain of slots (head per cell, next per
  ///   slot, -1 ends); the last unit put in is the first of the chain
  /// </summary>
  TWarMapGrid = class
  strict private
    FHead: array[0..WAR_MAP_GRID_CELLS - 1] of Integer;
    FNext: array[0..WAR_MAX_ENTITIES_COUNT - 1] of Integer;
  public
    constructor Create;
    /// <summary>wgrid_clear: every cell and slot empty</summary>
    procedure Clear;
    /// <summary>
    ///   wgrid_build: clears the grid and puts the active units in their cell, in the order of the list; a unit
    ///   outside the map is not put. A slot outside the table is EWarException (the original asserted)
    /// </summary>
    procedure Build(const AUnits: array of TWarGridUnit);
    /// <summary>wgrid_tileFromMapTile: the cell of a tile (the quotient truncated toward zero)</summary>
    class procedure TileFromMapTile(ATileX, ATileY: Single; out ACellX, ACellY: Integer); static;
    /// <summary>wgrid_getTileIndex: the number of the cell, -1 if it is not in the 16 x 16 grid</summary>
    class function GetTileIndex(ACellX, ACellY: Integer): Integer; static;
    /// <summary>The first slot of a cell (-1 if empty)</summary>
    function Head(ACell: Integer): Integer;
    /// <summary>The slot after ASlot in its chain (-1 at the end)</summary>
    function Next(ASlot: Integer): Integer;
    /// <summary>The slots of a cell, from the first of the chain</summary>
    function UnitsInCell(ACell: Integer): TArray<Integer>;
  end;

implementation

uses
  DelphiDoom.War.Types;

{ TWarMapGrid }

constructor TWarMapGrid.Create;
begin
  inherited Create;
  Clear;
end;

procedure TWarMapGrid.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to WAR_MAP_GRID_CELLS - 1 do
    FHead[LIndex] := -1;
  for LIndex := 0 to WAR_MAX_ENTITIES_COUNT - 1 do
    FNext[LIndex] := -1;
end;

procedure TWarMapGrid.Build(const AUnits: array of TWarGridUnit);
var
  LUnit: TWarGridUnit;
  LCellX: Integer;
  LCellY: Integer;
  LCell: Integer;
begin
  Clear;
  for LUnit in AUnits do
  begin
    if (LUnit.Slot < 0) or (LUnit.Slot >= WAR_MAX_ENTITIES_COUNT) then
      raise EWarException.CreateFmt(SWarIndexOutOfRange, [LUnit.Slot, WAR_MAX_ENTITIES_COUNT]);
    if not LUnit.Active then
      Continue;
    TileFromMapTile(LUnit.TileX, LUnit.TileY, LCellX, LCellY);
    LCell := GetTileIndex(LCellX, LCellY);
    if LCell < 0 then
      Continue;
    FNext[LUnit.Slot] := FHead[LCell];
    FHead[LCell] := LUnit.Slot;
  end;
end;

class procedure TWarMapGrid.TileFromMapTile(ATileX, ATileY: Single; out ACellX, ACellY: Integer);
begin
  ACellX := Trunc(ATileX / WAR_MAP_GRID_TILE_SIZE);
  ACellY := Trunc(ATileY / WAR_MAP_GRID_TILE_SIZE);
end;

class function TWarMapGrid.GetTileIndex(ACellX, ACellY: Integer): Integer;
begin
  if (ACellX < 0) or (ACellX >= WAR_MAP_GRID_TILES_WIDTH) or (ACellY < 0) or (ACellY >= WAR_MAP_GRID_TILES_HEIGHT) then
    Exit(-1);
  Result := ACellY * WAR_MAP_GRID_TILES_WIDTH + ACellX;
end;

function TWarMapGrid.Head(ACell: Integer): Integer;
begin
  if (ACell < 0) or (ACell >= WAR_MAP_GRID_CELLS) then
    raise EWarException.CreateFmt(SWarIndexOutOfRange, [ACell, WAR_MAP_GRID_CELLS]);
  Result := FHead[ACell];
end;

function TWarMapGrid.Next(ASlot: Integer): Integer;
begin
  if (ASlot < 0) or (ASlot >= WAR_MAX_ENTITIES_COUNT) then
    raise EWarException.CreateFmt(SWarIndexOutOfRange, [ASlot, WAR_MAX_ENTITIES_COUNT]);
  Result := FNext[ASlot];
end;

function TWarMapGrid.UnitsInCell(ACell: Integer): TArray<Integer>;
var
  LSlot: Integer;
begin
  Result := nil;
  LSlot := Head(ACell);
  // a slot listed twice in Build makes a loop in the chain; the original would follow it forever
  while (LSlot >= 0) and (Length(Result) < WAR_MAX_ENTITIES_COUNT) do
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := LSlot;
    LSlot := FNext[LSlot];
  end;
end;

end.
