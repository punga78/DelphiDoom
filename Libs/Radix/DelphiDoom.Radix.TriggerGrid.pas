{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixTriggerGrid                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of radix_grid.pas of Rad-X (RX_PosInGrid, RX_GridToMap) without the    }
{  globals of the engine: the sector of a point is asked by the caller         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.TriggerGrid;

interface

uses
  DelphiDoom.Radix.Level.Types, DelphiDoom.Radix.LevelLogic.Types;

type
  /// <summary>
  ///   The grid of RADIX.DAT that covers a level with cells of 64 x 64 units: each cell names the
  ///   trigger that a craft sets off by being there. The grid is in the coordinates of Radix; a
  ///   point of the Doom map goes back to them with the position of its sector (RMAP)
  /// </summary>
  TRadixTriggerGrid = class
  strict private
    FWidth: Integer;
    FHeight: Integer;
    FCells: TArray<SmallInt>;
    FMapPoints: TArray<TRadixLevelMapPoint>;
    function GetHasGrid: Boolean;
  public
    /// <summary>AMapPoints can be empty: then no cell has a place in the map</summary>
    constructor Create(const AGrid: TRadixTriggerGridData; const AMapPoints: TArray<TRadixLevelMapPoint>);
    /// <summary>
    ///   The cell of a point of the Doom map (map units) that is in a sector with APosition. The
    ///   result is not checked: a point outside the grid gives a cell that IsCell refuses
    /// </summary>
    function CellAt(const APosition: TRadixSectorPosition; AMapX, AMapY: Integer): Integer;
    function IsCell(ACell: Integer): Boolean;
    /// <summary>The trigger of a cell; RADIX_NO_TRIGGER for a cell without one or outside the grid</summary>
    function TriggerAt(ACell: Integer): Integer;
    /// <summary>The upper left corner of a cell in the Doom map (map units); false without a grid or outside it</summary>
    function TryCellToMap(ACell: Integer; out AMapX, AMapY: Integer): Boolean;
    /// <summary>True when the craft has a momentum on the map: its way of this tic is sampled in three places</summary>
    class function IsMoving(AMomentumX, AMomentumY: Integer): Boolean; static;
    /// <summary>
    ///   The three places (map units) of a craft at AX, AY that moves by its momentum (all in
    ///   fixed point): two thirds of the way, one third, and where it is now
    /// </summary>
    class function MovementSamples(AX, AY, AMomentumX, AMomentumY: Integer): TRadixMovementSamples; static;
    /// <summary>False for a level without grid: no trigger is set off by a place</summary>
    property HasGrid: Boolean read GetHasGrid;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
  end;

implementation

const
  FIXED_UNIT = 65536;

{ TRadixTriggerGrid }

constructor TRadixTriggerGrid.Create(const AGrid: TRadixTriggerGridData;
  const AMapPoints: TArray<TRadixLevelMapPoint>);
begin
  inherited Create;
  FWidth := AGrid.Width;
  FHeight := AGrid.Height;
  FCells := Copy(AGrid.Cells);
  FMapPoints := Copy(AMapPoints);
end;

function TRadixTriggerGrid.GetHasGrid: Boolean;
begin
  Result := (FWidth <> 0) and (FHeight <> 0);
end;

function TRadixTriggerGrid.CellAt(const APosition: TRadixSectorPosition; AMapX, AMapY: Integer): Integer;
var
  LColumn: Integer;
  LRow: Integer;
begin
  // works because XMul and YMul are 1 or -1 (JVAL: 20200305)
  LColumn := (APosition.XMul * (AMapX - APosition.XAdd)) div RADIX_GRID_CELL_SIZE;
  LRow := (APosition.YMul * (AMapY - APosition.YAdd)) div RADIX_GRID_CELL_SIZE;
  Result := LRow * FWidth + LColumn;
end;

function TRadixTriggerGrid.IsCell(ACell: Integer): Boolean;
begin
  Result := (ACell >= 0) and (ACell < Length(FCells));
end;

function TRadixTriggerGrid.TriggerAt(ACell: Integer): Integer;
begin
  if IsCell(ACell) then
    Result := FCells[ACell]
  else
    Result := RADIX_NO_TRIGGER;
end;

function TRadixTriggerGrid.TryCellToMap(ACell: Integer; out AMapX, AMapY: Integer): Boolean;
begin
  AMapX := 0;
  AMapY := 0;
  Result := HasGrid and (ACell >= 0) and (ACell < Length(FMapPoints));
  if Result then
  begin
    AMapX := FMapPoints[ACell].X;
    AMapY := FMapPoints[ACell].Y;
  end;
end;

class function TRadixTriggerGrid.IsMoving(AMomentumX, AMomentumY: Integer): Boolean;
begin
  Result := (AMomentumX <> 0) or (AMomentumY <> 0);
end;

class function TRadixTriggerGrid.MovementSamples(AX, AY, AMomentumX,
  AMomentumY: Integer): TRadixMovementSamples;
var
  LX: Integer;
  LY: Integer;
  LNextX: Integer;
  LNextY: Integer;
begin
  LX := AX div FIXED_UNIT;
  LY := AY div FIXED_UNIT;
  LNextX := (AX + AMomentumX) div FIXED_UNIT;
  LNextY := (AY + AMomentumY) div FIXED_UNIT;
  Result[0].X := (LNextX * 2 + LX) div 3;
  Result[0].Y := (LNextY * 2 + LY) div 3;
  Result[1].X := (LNextX + LX * 2) div 3;
  Result[1].Y := (LNextY + LY * 2) div 3;
  Result[2].X := LX;
  Result[2].Y := LY;
end;

end.
