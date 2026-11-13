{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the BSP of Quake III Arena: edges of grids   }
{                                                                              }
{  Port of R_MergedWidthPoints and R_MergedHeightPoints (tr_bsp.c) and of the  }
{  comparison of positions that the stitching repeats. Based on the Quake III  }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.GridEdges;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Patch.Intf;

type
  /// <summary>
  ///   Questions about the vertices on the edges of a grid. The tolerances are the doubles of
  ///   the original (.1 and .01): the difference of two coordinates is a Single, as in C
  /// </summary>
  TBspGridEdges = class
  public
    /// <summary>
    ///   True if two points of the edge that starts at AOffset (a row of the grid: Offset =
    ///   0 or (Height - 1) * Width) are less than .1 apart on every axis, the first and last
    ///   excluded (R_MergedWidthPoints)
    /// </summary>
    class function MergedWidthPoints(const AGrid: IPatchGrid; const AOffset: Integer): Boolean; static;
    /// <summary>The same for a column: Offset = 0 or Width - 1 (R_MergedHeightPoints)</summary>
    class function MergedHeightPoints(const AGrid: IPatchGrid; const AOffset: Integer): Boolean; static;
    /// <summary>True if no coordinate differs by more than .1 (fabs(..) &gt; .1 on any axis is "no")</summary>
    class function Near(const AFirst, ASecond: TIdVec3): Boolean; static;
    /// <summary>True if every coordinate differs by less than .01 (two points that are the same one)</summary>
    class function Same(const AFirst, ASecond: TIdVec3): Boolean; static;
  end;

implementation

const
  NEAR_TOLERANCE: Double = 0.1;
  SAME_TOLERANCE: Double = 0.01;

class function TBspGridEdges.Near(const AFirst, ASecond: TIdVec3): Boolean;
var
  LDifference: Single;
begin
  LDifference := AFirst.X - ASecond.X;
  if Abs(LDifference) > NEAR_TOLERANCE then
    Exit(False);
  LDifference := AFirst.Y - ASecond.Y;
  if Abs(LDifference) > NEAR_TOLERANCE then
    Exit(False);
  LDifference := AFirst.Z - ASecond.Z;
  Result := not (Abs(LDifference) > NEAR_TOLERANCE);
end;

class function TBspGridEdges.Same(const AFirst, ASecond: TIdVec3): Boolean;
var
  LDifference: Single;
begin
  LDifference := AFirst.X - ASecond.X;
  if not (Abs(LDifference) < SAME_TOLERANCE) then
    Exit(False);
  LDifference := AFirst.Y - ASecond.Y;
  if not (Abs(LDifference) < SAME_TOLERANCE) then
    Exit(False);
  LDifference := AFirst.Z - ASecond.Z;
  Result := Abs(LDifference) < SAME_TOLERANCE;
end;

class function TBspGridEdges.MergedWidthPoints(const AGrid: IPatchGrid;
  const AOffset: Integer): Boolean;
var
  LI, LJ: Integer;
begin
  for LI := 1 to AGrid.Width - 2 do
    for LJ := LI + 1 to AGrid.Width - 2 do
      if Near(AGrid.Vertices[LI + AOffset].Position, AGrid.Vertices[LJ + AOffset].Position) then
        Exit(True);
  Result := False;
end;

class function TBspGridEdges.MergedHeightPoints(const AGrid: IPatchGrid;
  const AOffset: Integer): Boolean;
var
  LI, LJ: Integer;
begin
  for LI := 1 to AGrid.Height - 2 do
    for LJ := LI + 1 to AGrid.Height - 2 do
      if Near(AGrid.Vertices[AGrid.Width * LI + AOffset].Position,
        AGrid.Vertices[AGrid.Width * LJ + AOffset].Position) then
        Exit(True);
  Result := False;
end;

end.
