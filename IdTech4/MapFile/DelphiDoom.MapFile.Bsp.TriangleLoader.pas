{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the BSP of Quake III Arena: triangle soups   }
{                                                                              }
{  Port of ParseTriSurf (tr_bsp.c). Based on the Quake III Arena GPL Source    }
{  Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is  }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.TriangleLoader;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.MapFile.Bsp.RenderTypes, DelphiDoom.MapFile.Bsp.Types;

type
  /// <summary>
  ///   ParseTriSurf: copies the vertices (the colour is shifted), the bounds with ClearBounds
  ///   and AddPointToBounds of q_math.c, and the indexes, which must point at a vertex
  /// </summary>
  TBspTriangleLoader = class(TInterfacedObject, IBspTriangleLoader)
  strict private
    FColorShift: Integer;
  public
    /// <param name="AColorShift">r_mapOverBrightBits - overbrightBits (see TBspColorShift)</param>
    constructor Create(const AColorShift: Integer);
    function Parse(const ASurface: TBspSurface; const AVerts: TArray<TBspDrawVert>;
      const AIndexes: TArray<Integer>; const AShaderCount: Integer): TBspTriangleSurface;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MapFile.Bsp.ColorShift, DelphiDoom.MapFile.Bsp.SurfaceGuard;

const
  /// <summary>The 99999 of ClearBounds</summary>
  BOUNDS_LIMIT = 99999.0;

resourcestring
  STriangleBadIndex = 'Bad index in triangle surface';
  STriangleVerts = 'vertexes';
  STriangleIndexes = 'indexes';

{ TBspTriangleLoader }

constructor TBspTriangleLoader.Create(const AColorShift: Integer);
begin
  inherited Create;
  FColorShift := AColorShift;
end;

function TBspTriangleLoader.Parse(const ASurface: TBspSurface; const AVerts: TArray<TBspDrawVert>;
  const AIndexes: TArray<Integer>; const AShaderCount: Integer): TBspTriangleSurface;
var
  LNumVerts, LNumIndexes, LIndex, LAxis: Integer;
  LColor, LShifted: TBspColor;
begin
  TBspSurfaceGuard.CheckShaderNum(ASurface.ShaderNum, AShaderCount);
  // get fog volume
  Result.FogIndex := ASurface.FogNum + 1;
  Result.ShaderNum := ASurface.ShaderNum;

  LNumVerts := ASurface.NumVerts;
  LNumIndexes := ASurface.NumIndexes;
  if LNumVerts < 0 then
    LNumVerts := 0;
  if LNumIndexes < 0 then
    LNumIndexes := 0;
  TBspSurfaceGuard.CheckRange(STriangleVerts, ASurface.FirstVert, LNumVerts, Length(AVerts));
  TBspSurfaceGuard.CheckRange(STriangleIndexes, ASurface.FirstIndex, LNumIndexes, Length(AIndexes));

  // ClearBounds
  for LAxis := 0 to 2 do
  begin
    Result.Mins[LAxis] := BOUNDS_LIMIT;
    Result.Maxs[LAxis] := -BOUNDS_LIMIT;
  end;

  // copy vertexes
  SetLength(Result.Verts, LNumVerts);
  for LIndex := 0 to LNumVerts - 1 do
  begin
    Result.Verts[LIndex] := AVerts[ASurface.FirstVert + LIndex];
    // AddPointToBounds
    for LAxis := 0 to 2 do
    begin
      if Result.Verts[LIndex].Xyz[LAxis] < Result.Mins[LAxis] then
        Result.Mins[LAxis] := Result.Verts[LIndex].Xyz[LAxis];
      if Result.Verts[LIndex].Xyz[LAxis] > Result.Maxs[LAxis] then
        Result.Maxs[LAxis] := Result.Verts[LIndex].Xyz[LAxis];
    end;
    for LAxis := 0 to 3 do
      LColor[LAxis] := Result.Verts[LIndex].Color[LAxis];
    TBspColorShift.Apply(FColorShift, LColor, LShifted);
    for LAxis := 0 to 3 do
      Result.Verts[LIndex].Color[LAxis] := LShifted[LAxis];
  end;

  // copy indexes
  SetLength(Result.Indexes, LNumIndexes);
  for LIndex := 0 to LNumIndexes - 1 do
  begin
    Result.Indexes[LIndex] := AIndexes[ASurface.FirstIndex + LIndex];
    if (Result.Indexes[LIndex] < 0) or (Result.Indexes[LIndex] >= LNumVerts) then
      raise EBspFileException.Create(STriangleBadIndex);
  end;
end;

end.
