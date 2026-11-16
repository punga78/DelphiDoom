{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore - patches of Quake III Arena: inserting columns/rows   }
{                                                                              }
{  Port of R_GridInsertColumn and R_GridInsertRow (tr_curve.c), used by the    }
{  stitching of neighbouring patches. Based on the Quake III Arena GPL Source  }
{  Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is  }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Patch.GridEditor;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Patch.Intf;

type
  /// <summary>
  ///   Adds a column or a row to a grid (the new vertices are the middle of the two
  ///   neighbours, one of them is moved to the given point), recomputes the normals and keeps
  ///   the LOD origin and radius of the grid. The original reads outside the grid when the
  ///   position is 0 or the last one; here those positions raise <c>EPatchException</c>.
  /// </summary>
  TPatchGridEditor = class(TInterfacedObject, IPatchGridEditor)
  public
    function InsertColumn(const AGrid: IPatchGrid; const AColumn, ARow: Integer;
      const APoint: TIdVec3; const ALodError: Single): IPatchGrid;
    function InsertRow(const AGrid: IPatchGrid; const ARow, AColumn: Integer;
      const APoint: TIdVec3; const ALodError: Single): IPatchGrid;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Patch.ControlMesh, DelphiDoom.MathCore.Patch.Grid,
  DelphiDoom.MathCore.Patch.Normals, DelphiDoom.MathCore.Patch.Types,
  DelphiDoom.MathCore.Patch.VertexMath;

type
  TErrors = array[0..MAX_GRID_SIZE - 1] of Single;

function TPatchGridEditor.InsertColumn(const AGrid: IPatchGrid; const AColumn, ARow: Integer;
  const APoint: TIdVec3; const ALodError: Single): IPatchGrid;
var
  LMesh: TPatchControlMesh;
  LWidthErrors, LHeightErrors: TErrors;
  LWidth, LHeight, LOldWidth, LI, LJ: Integer;
  LVertex: TPatchVertex;
begin
  if (AColumn < 1) or (AColumn > AGrid.Width - 1) then
    raise EPatchException.CreateFmt(SPatchInsertPositionInvalid, [AColumn, AGrid.Width - 1]);
  LWidth := AGrid.Width + 1;
  if LWidth > MAX_GRID_SIZE then
    Exit(nil);
  LHeight := AGrid.Height;
  FillChar(LWidthErrors, SizeOf(LWidthErrors), 0);
  FillChar(LHeightErrors, SizeOf(LHeightErrors), 0);
  LMesh := TPatchControlMesh.Create;
  try
    LOldWidth := 0;
    for LI := 0 to LWidth - 1 do
    begin
      if LI = AColumn then
      begin
        // insert new column
        for LJ := 0 to AGrid.Height - 1 do
        begin
          LVertex := TPatchVertexMath.Lerp(AGrid.Vertices[LJ * AGrid.Width + LI - 1],
            AGrid.Vertices[LJ * AGrid.Width + LI]);
          if LJ = ARow then
            LVertex.Position := APoint;
          LMesh[LJ, LI] := LVertex;
        end;
        LWidthErrors[LI] := ALodError;
        Continue;
      end;
      LWidthErrors[LI] := AGrid.WidthLodError[LOldWidth];
      for LJ := 0 to AGrid.Height - 1 do
        LMesh[LJ, LI] := AGrid.Vertices[LJ * AGrid.Width + LOldWidth];
      Inc(LOldWidth);
    end;
    for LJ := 0 to AGrid.Height - 1 do
      LHeightErrors[LJ] := AGrid.HeightLodError[LJ];
    TPatchNormals.Compute(LMesh, LWidth, LHeight);

    Result := TPatchGrid.Create(LMesh, LWidth, LHeight, LWidthErrors, LHeightErrors);
    Result.LodOrigin := AGrid.LodOrigin;
    Result.LodRadius := AGrid.LodRadius;
  finally
    LMesh.Free;
  end;
end;

function TPatchGridEditor.InsertRow(const AGrid: IPatchGrid; const ARow, AColumn: Integer;
  const APoint: TIdVec3; const ALodError: Single): IPatchGrid;
var
  LMesh: TPatchControlMesh;
  LWidthErrors, LHeightErrors: TErrors;
  LWidth, LHeight, LOldHeight, LI, LJ: Integer;
  LVertex: TPatchVertex;
begin
  if (ARow < 1) or (ARow > AGrid.Height - 1) then
    raise EPatchException.CreateFmt(SPatchInsertPositionInvalid, [ARow, AGrid.Height - 1]);
  LWidth := AGrid.Width;
  LHeight := AGrid.Height + 1;
  if LHeight > MAX_GRID_SIZE then
    Exit(nil);
  FillChar(LWidthErrors, SizeOf(LWidthErrors), 0);
  FillChar(LHeightErrors, SizeOf(LHeightErrors), 0);
  LMesh := TPatchControlMesh.Create;
  try
    LOldHeight := 0;
    for LI := 0 to LHeight - 1 do
    begin
      if LI = ARow then
      begin
        // insert new row
        for LJ := 0 to AGrid.Width - 1 do
        begin
          LVertex := TPatchVertexMath.Lerp(AGrid.Vertices[(LI - 1) * AGrid.Width + LJ],
            AGrid.Vertices[LI * AGrid.Width + LJ]);
          if LJ = AColumn then
            LVertex.Position := APoint;
          LMesh[LI, LJ] := LVertex;
        end;
        LHeightErrors[LI] := ALodError;
        Continue;
      end;
      LHeightErrors[LI] := AGrid.HeightLodError[LOldHeight];
      for LJ := 0 to AGrid.Width - 1 do
        LMesh[LI, LJ] := AGrid.Vertices[LOldHeight * AGrid.Width + LJ];
      Inc(LOldHeight);
    end;
    for LJ := 0 to AGrid.Width - 1 do
      LWidthErrors[LJ] := AGrid.WidthLodError[LJ];
    TPatchNormals.Compute(LMesh, LWidth, LHeight);

    Result := TPatchGrid.Create(LMesh, LWidth, LHeight, LWidthErrors, LHeightErrors);
    Result.LodOrigin := AGrid.LodOrigin;
    Result.LodRadius := AGrid.LodRadius;
  finally
    LMesh.Free;
  end;
end;

end.
