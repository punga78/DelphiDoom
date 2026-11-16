{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the point in subsector grid                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of R_PrecalcPointInSubSector of r_subsectors.pas                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.SubsectorGrid;

interface

uses
  System.SysUtils, DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf;

type
  /// <summary>
  ///   Cuts the level in cells of 32 map units and finds the subsector of the cells that lie
  ///   in one subsector only, so that the renderer finds the subsector of an object with a
  ///   lookup in place of a walk down the nodes
  /// </summary>
  TRendererSubsectorGridBuilder = class(TInterfacedObject, IRendererSubsectorGridBuilder)
  public
    function Build(const AVertexX, AVertexY: TArray<Integer>;
      const ALocator: IRendererSubsectorLocator): TRendererSubsectorGrid;
  end;

implementation

// as in the engine: the product of the cell number and the cell size is a 32 bit integer
// that wraps around before it is added to the 64 bit corner
{$Q-}
{$R-}

const
  SNoVertexes = 'The level has no vertexes';
  SNoLocator = 'ALocator';
  /// <summary>The size of a cell: 32 map units in fixed point</summary>
  CELL_SIZE = 32 * RENDERER_FRACUNIT;

{ TRendererSubsectorGridBuilder }

function TRendererSubsectorGridBuilder.Build(const AVertexX, AVertexY: TArray<Integer>;
  const ALocator: IRendererSubsectorLocator): TRendererSubsectorGrid;
var
  LIndex: Integer;
  LColumn: Integer;
  LRow: Integer;
  LBound: Integer;
  LMaxX: Int64;
  LMaxY: Int64;
  LCellX: Int64;
  LCellY: Int64;
  LFirst: Integer;
  LOther: Integer;
begin
  if not Assigned(ALocator) then
    raise EArgumentNilException.Create(SNoLocator);
  if (Length(AVertexX) = 0) or (Length(AVertexX) <> Length(AVertexY)) then
    raise ERendererException.Create(SNoVertexes);

  Result.MinX := AVertexX[0];
  Result.MinY := AVertexY[0];
  LMaxX := AVertexX[0];
  LMaxY := AVertexY[0];
  for LIndex := 1 to High(AVertexX) do
  begin
    if AVertexX[LIndex] < Result.MinX then
      Result.MinX := AVertexX[LIndex]
    else if AVertexX[LIndex] > LMaxX then
      LMaxX := AVertexX[LIndex];
    if AVertexY[LIndex] < Result.MinY then
      Result.MinY := AVertexY[LIndex]
    else if AVertexY[LIndex] > LMaxY then
      LMaxY := AVertexY[LIndex];
  end;

  // the units of the map: the fixed point shifted, with the sign kept
  Result.MaxBound := Abs(Integer(Result.MinX div RENDERER_FRACUNIT));
  LBound := Abs(Integer(LMaxX div RENDERER_FRACUNIT));
  if LBound > Result.MaxBound then
    Result.MaxBound := LBound;
  LBound := Abs(Integer(Result.MinY div RENDERER_FRACUNIT));
  if LBound > Result.MaxBound then
    Result.MaxBound := LBound;
  LBound := Abs(Integer(LMaxY div RENDERER_FRACUNIT));
  if LBound > Result.MaxBound then
    Result.MaxBound := LBound;

  Result.Width := (LMaxX - Result.MinX) div CELL_SIZE + 1;
  Result.Height := (LMaxY - Result.MinY) div CELL_SIZE + 1;
  SetLength(Result.Cells, Integer(Result.Width * Result.Height));
  for LIndex := 0 to High(Result.Cells) do
    Result.Cells[LIndex] := -1;

  Result.HitCount := 0;
  for LColumn := 0 to Result.Width - 1 do
    for LRow := 0 to Result.Height - 1 do
    begin
      LCellX := Result.MinX + LColumn * CELL_SIZE;
      LCellY := Result.MinY + LRow * CELL_SIZE;
      LFirst := ALocator.Locate(Integer(LCellX), Integer(LCellY));
      LOther := ALocator.Locate(Integer(LCellX + CELL_SIZE - 1), Integer(LCellY));
      if (LFirst >= 0) and (LFirst = LOther) then
      begin
        LOther := ALocator.Locate(Integer(LCellX + CELL_SIZE - 1),
          Integer(LCellY + CELL_SIZE - 1));
        if (LOther >= 0) and (LFirst = LOther) then
        begin
          LOther := ALocator.Locate(Integer(LCellX), Integer(LCellY + CELL_SIZE - 1));
          if (LOther >= 0) and (LFirst = LOther) then
          begin
            Result.Cells[LRow * Result.Width + LColumn] := LOther;
            Inc(Result.HitCount);
          end;
        end;
      end;
    end;
end;

end.
