{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - what the software renderer measures          }
{  when a level is loaded                                                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of R_CalcSectors and R_PrecalcSegs of r_segs2.pas                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.LevelPrecalc;

interface

uses
  System.SysUtils, DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf;

type
  /// <summary>
  ///   The height range of the sectors and the length of the segs of a level: numbers that
  ///   the renderer reads for every wall (so the engine keeps them in its own globals)
  /// </summary>
  TRendererLevelPrecalc = class(TInterfacedObject, IRendererLevelPrecalc)
  public
    function MeasureHeights(const AFloorHeights,
      ACeilingHeights: TArray<Integer>): TRendererHeightRange;
    procedure MeasureSegments(const AStartX, AStartY, AEndX, AEndY: TArray<Integer>;
      var AMapLength: TArray<Integer>; var AInverseLength: TArray<Double>);
  end;

implementation

// The differences of the coordinates wrap around in 32 bits before they become Double,
// as in the old code: the overflow checks are off on purpose
{$Q-}
{$R-}

const
  SSectorTablesDiffer = 'The floor and the ceiling tables have a different length';
  SSegTablesDiffer = 'The tables of the coordinates of the segs have a different length';
  SResultTooShort = 'The tables of the results are shorter than the segs';

{ TRendererLevelPrecalc }

function TRendererLevelPrecalc.MeasureHeights(const AFloorHeights,
  ACeilingHeights: TArray<Integer>): TRendererHeightRange;
var
  LIndex: Integer;
  LHeight: Int64;
begin
  if Length(AFloorHeights) <> Length(ACeilingHeights) then
    raise ERendererException.Create(SSectorTablesDiffer);

  Result.LowestFloor := MaxInt;
  Result.HighestCeiling := Low(Integer);
  for LIndex := 0 to High(AFloorHeights) do
  begin
    if AFloorHeights[LIndex] < Result.LowestFloor then
      Result.LowestFloor := AFloorHeights[LIndex];
    if ACeilingHeights[LIndex] > Result.HighestCeiling then
      Result.HighestCeiling := ACeilingHeights[LIndex];
  end;
  LHeight := Int64(Result.HighestCeiling) - Int64(Result.LowestFloor);
  Result.NeedsTallWalls := LHeight > RENDERER_TALL_WALL_OFFSET;
end;

procedure TRendererLevelPrecalc.MeasureSegments(const AStartX, AStartY, AEndX,
  AEndY: TArray<Integer>; var AMapLength: TArray<Integer>;
  var AInverseLength: TArray<Double>);
var
  LIndex: Integer;
  LDeltaX: Double;
  LDeltaY: Double;
  LLength: Double;
begin
  if (Length(AStartY) <> Length(AStartX)) or (Length(AEndX) <> Length(AStartX)) or
    (Length(AEndY) <> Length(AStartX)) then
    raise ERendererException.Create(SSegTablesDiffer);
  if (Length(AMapLength) < Length(AStartX)) or (Length(AInverseLength) < Length(AStartX)) then
    raise ERendererException.Create(SResultTooShort);

  for LIndex := 0 to High(AStartX) do
  begin
    LDeltaX := AEndX[LIndex] - AStartX[LIndex];
    LDeltaY := AEndY[LIndex] - AStartY[LIndex];
    LLength := Sqrt(LDeltaX * LDeltaX + LDeltaY * LDeltaY);
    AMapLength[LIndex] := Round(LLength / RENDERER_FRACUNIT);
    AInverseLength[LIndex] := 1 / LLength;
  end;
end;

end.
