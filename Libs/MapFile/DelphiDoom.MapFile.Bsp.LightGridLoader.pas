{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the light grid of a BSP                      }
{                                                                              }
{  Port of R_LoadLightGrid (tr_bsp.c), Quake III Arena GPL Source Code.        }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. GPL v2 or later.                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.LightGridLoader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.MapFile.Bsp.RenderTypes;

type
  /// <summary>
  ///   The grid is aligned to multiples of the cell size inside the box of model 0. The sizes
  ///   are floats and the products with <c>ceil</c> and <c>floor</c> are doubles narrowed to a
  ///   float, as in the original; the number of cells is a 32 bit integer that wraps like
  ///   the one of the C code
  /// </summary>
  TBspLightGridLoader = class(TInterfacedObject, IBspLightGridLoader)
  strict private
    FLog: IIdLibLog;
  public
    /// <summary>The log may be nil</summary>
    constructor Create(const ALog: IIdLibLog = nil);
    function Load(const AWorldBounds: TGeoBounds; const AGridSize: TGeoVec3; const ALump: TBytes;
      const AShift: Integer): TBspLightGrid;
  end;

implementation

uses
  DelphiDoom.MapFile.Bsp.Types, DelphiDoom.MapFile.Bsp.ColorShift;

resourcestring
  SGridSize = 'light grid size %g is not positive';
  SGridBounds = 'light grid bounds are out of range';
  SGridMismatch = 'WARNING: light grid mismatch'#10;

/// <summary>ceil of the C library: a double, with the sign of a zero kept</summary>
function DoubleCeil(const AValue: Double): Double;
begin
  Result := Int(AValue);
  if (AValue > 0) and (Result <> AValue) then
    Result := Result + 1
  else if (AValue < 0) and (Result = 0) then
    // the ceil of -0.5 is -0: the x87 unit keeps the sign in Int, SSE does not
    Result := -Abs(Result);
end;

/// <summary>floor of the C library: a double</summary>
function DoubleFloor(const AValue: Double): Double;
begin
  Result := Int(AValue);
  if (AValue < 0) and (Result <> AValue) then
    Result := Result - 1;
end;

{ TBspLightGridLoader }

constructor TBspLightGridLoader.Create(const ALog: IIdLibLog);
begin
  inherited Create;
  FLog := ALog;
end;

function TBspLightGridLoader.Load(const AWorldBounds: TGeoBounds; const AGridSize: TGeoVec3;
  const ALump: TBytes; const AShift: Integer): TBspLightGrid;
var
  LAxis, LCell, LNumGridPoints: Integer;
  LRatio, LMaxs, LDifference, LQuotient, LCells, LOne: Single;
  LCeil, LFloor, LProduct: Double;
  LColor, LShifted: TBspColor;
begin
  for LAxis := 0 to 2 do
    if not (AGridSize[LAxis] > 0) then
      raise EBspFileException.Create(Format(SGridSize, [Double(AGridSize[LAxis])]));
  Result.Size := AGridSize;
  LOne := 1.0;
  Result.InverseSize.X := LOne / AGridSize.X;
  Result.InverseSize.Y := LOne / AGridSize.Y;
  Result.InverseSize.Z := LOne / AGridSize.Z;
  Result.Data := nil;

  for LAxis := 0 to 2 do
  begin
    // lightGridOrigin = size * ceil(mins / size); maxs = size * floor(maxs / size)
    LRatio := AWorldBounds.Mins[LAxis] / AGridSize[LAxis];
    LCeil := DoubleCeil(Double(LRatio));
    LProduct := Double(AGridSize[LAxis]) * LCeil;
    Result.Origin[LAxis] := LProduct;
    LRatio := AWorldBounds.Maxs[LAxis] / AGridSize[LAxis];
    LFloor := DoubleFloor(Double(LRatio));
    LProduct := Double(AGridSize[LAxis]) * LFloor;
    LMaxs := LProduct;
    LDifference := LMaxs - Result.Origin[LAxis];
    LQuotient := LDifference / AGridSize[LAxis];
    LCells := LQuotient + LOne;
    if not ((LCells >= -2147483648.0) and (LCells < 2147483648.0)) then
      raise EBspFileException.Create(SGridBounds);
    Result.Bounds[LAxis] := Trunc(LCells);
  end;

  LNumGridPoints := Result.Bounds[0] * Result.Bounds[1] * Result.Bounds[2];
  if Length(ALump) <> LNumGridPoints * 8 then
  begin
    if Assigned(FLog) then
      FLog.Warning(SGridMismatch);
    Exit;
  end;

  Result.Data := Copy(ALump);
  // deal with overbright bits: the colour at 0 and the one at 3 of every cell
  for LCell := 0 to LNumGridPoints - 1 do
  begin
    LColor[0] := Result.Data[LCell * 8];
    LColor[1] := Result.Data[LCell * 8 + 1];
    LColor[2] := Result.Data[LCell * 8 + 2];
    LColor[3] := Result.Data[LCell * 8 + 3];
    TBspColorShift.Apply(AShift, LColor, LShifted);
    Result.Data[LCell * 8] := LShifted[0];
    Result.Data[LCell * 8 + 1] := LShifted[1];
    Result.Data[LCell * 8 + 2] := LShifted[2];
    Result.Data[LCell * 8 + 3] := LShifted[3];
    // the second colour starts at byte 3: it overlaps the alpha of the first, which the
    // first shift left unchanged
    LColor[0] := Result.Data[LCell * 8 + 3];
    LColor[1] := Result.Data[LCell * 8 + 4];
    LColor[2] := Result.Data[LCell * 8 + 5];
    LColor[3] := Result.Data[LCell * 8 + 6];
    TBspColorShift.Apply(AShift, LColor, LShifted);
    Result.Data[LCell * 8 + 3] := LShifted[0];
    Result.Data[LCell * 8 + 4] := LShifted[1];
    Result.Data[LCell * 8 + 5] := LShifted[2];
    Result.Data[LCell * 8 + 6] := LShifted[3];
  end;
end;

end.
