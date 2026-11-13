{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the BSP of Quake III Arena: stitching of     }
{  patches                                                                     }
{                                                                              }
{  Port of R_StitchPatches, R_TryStitchingPatch and R_StitchAllPatches         }
{  (tr_bsp.c). Based on the Quake III Arena GPL Source Code (id Software).     }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.PatchStitcher;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.MathCore.Patch.Intf;

type
  /// <summary>
  ///   Finds the cracks that two patches of the same LOD group have at their highest level of
  ///   detail (one grid has a vertex on a shared edge that the other has not) and adds the
  ///   missing column or row with the grid editor of MathCore. A grid is a slot of an array
  ///   (nil for a surface that is not a grid), as the surfaces of the world in the original.
  ///   <para>
  ///     Defect of the original, kept: when the edge of the first grid is searched backwards (the third
  ///     and fourth block of R_StitchPatches) the error of the new vertex is read at index k + 1, and for
  ///     the last vertex that is one past the table. The table is a zone block of its own, so what is
  ///     read is the 4 byte marker the zone writes after every block (ZONEID, 0x001D4A11, a denormal
  ///     float of 2.7e-39): here 0, which compares the same.
  ///   </para>
  /// </summary>
  TBspPatchStitcher = class(TInterfacedObject, IBspPatchStitcher)
  strict private
    FEditor: IPatchGridEditor;
    // lodStitched of each slot, only while StitchAll runs
    FStitched: TArray<Boolean>;
    class function PositionOf(const AGrid: IPatchGrid; const AIndex: Integer): TIdVec3; static;
    class function WidthError(const AGrid: IPatchGrid; const AIndex: Integer): Single; static;
    class function HeightError(const AGrid: IPatchGrid; const AIndex: Integer): Single; static;
    class function SameGroup(const AFirst, ASecond: IPatchGrid): Boolean; static;
    function TryEdge(var AGrids: TArray<IPatchGrid>; const ASecond: Integer;
      const AVertexA, AVertexB, AMiddle: TIdVec3; const ALodError: Single): Boolean;
    function TryStitchingPatch(var AGrids: TArray<IPatchGrid>; const AFirst: Integer): Integer;
  public
    constructor Create(const AEditor: IPatchGridEditor);
    function StitchAll(var AGrids: TArray<IPatchGrid>): Integer;
    function StitchPair(var AGrids: TArray<IPatchGrid>; const AFirst, ASecond: Integer): Boolean;
  end;

implementation

uses
  DelphiDoom.MapFile.Bsp.GridEdges, DelphiDoom.MathCore.Patch.Types;

{ TBspPatchStitcher }

constructor TBspPatchStitcher.Create(const AEditor: IPatchGridEditor);
begin
  inherited Create;
  FEditor := AEditor;
end;

class function TBspPatchStitcher.PositionOf(const AGrid: IPatchGrid; const AIndex: Integer): TIdVec3;
begin
  Result := AGrid.Vertices[AIndex].Position;
end;

class function TBspPatchStitcher.WidthError(const AGrid: IPatchGrid; const AIndex: Integer): Single;
begin
  if AIndex < AGrid.Width then
    Result := AGrid.WidthLodError[AIndex]
  else
    Result := 0;
end;

class function TBspPatchStitcher.HeightError(const AGrid: IPatchGrid; const AIndex: Integer): Single;
begin
  if AIndex < AGrid.Height then
    Result := AGrid.HeightLodError[AIndex]
  else
    Result := 0;
end;

class function TBspPatchStitcher.SameGroup(const AFirst, ASecond: IPatchGrid): Boolean;
begin
  // grids in the same LOD group have the exact same lod radius and origin
  Result := (AFirst.LodRadius = ASecond.LodRadius) and
    (AFirst.LodOrigin.X = ASecond.LodOrigin.X) and
    (AFirst.LodOrigin.Y = ASecond.LodOrigin.Y) and
    (AFirst.LodOrigin.Z = ASecond.LodOrigin.Z);
end;

// The two loops that every block of R_StitchPatches repeats: look for the two vertices of the
// first grid on an edge of the second one, and insert the middle one if the second has none
function TBspPatchStitcher.TryEdge(var AGrids: TArray<IPatchGrid>; const ASecond: Integer;
  const AVertexA, AVertexB, AMiddle: TIdVec3; const ALodError: Single): Boolean;
var
  LGrid2, LNewGrid: IPatchGrid;
  LM, LL, LOffset, LRowOrColumn: Integer;
begin
  LGrid2 := AGrids[ASecond];
  for LM := 0 to 1 do
  begin
    if LGrid2.Width >= MAX_GRID_SIZE then
      Break;
    if LM = 1 then
      LOffset := (LGrid2.Height - 1) * LGrid2.Width
    else
      LOffset := 0;
    for LL := 0 to LGrid2.Width - 2 do
    begin
      if not TBspGridEdges.Near(AVertexA, PositionOf(LGrid2, LL + LOffset)) then
        Continue;
      if not TBspGridEdges.Near(AVertexB, PositionOf(LGrid2, LL + 1 + LOffset)) then
        Continue;
      if TBspGridEdges.Same(PositionOf(LGrid2, LL + LOffset), PositionOf(LGrid2, LL + 1 + LOffset)) then
        Continue;
      // found highest LoD crack between two patches: insert a column right after column l
      if LM = 1 then
        LRowOrColumn := LGrid2.Height - 1
      else
        LRowOrColumn := 0;
      LNewGrid := FEditor.InsertColumn(LGrid2, LL + 1, LRowOrColumn, AMiddle, ALodError);
      AGrids[ASecond] := LNewGrid;
      if Length(FStitched) > ASecond then
        FStitched[ASecond] := False;
      Exit(True);
    end;
  end;
  for LM := 0 to 1 do
  begin
    if LGrid2.Height >= MAX_GRID_SIZE then
      Break;
    if LM = 1 then
      LOffset := LGrid2.Width - 1
    else
      LOffset := 0;
    for LL := 0 to LGrid2.Height - 2 do
    begin
      if not TBspGridEdges.Near(AVertexA, PositionOf(LGrid2, LGrid2.Width * LL + LOffset)) then
        Continue;
      if not TBspGridEdges.Near(AVertexB, PositionOf(LGrid2, LGrid2.Width * (LL + 1) + LOffset)) then
        Continue;
      if TBspGridEdges.Same(PositionOf(LGrid2, LGrid2.Width * LL + LOffset),
        PositionOf(LGrid2, LGrid2.Width * (LL + 1) + LOffset)) then
        Continue;
      // insert a row right after row l
      if LM = 1 then
        LRowOrColumn := LGrid2.Width - 1
      else
        LRowOrColumn := 0;
      LNewGrid := FEditor.InsertRow(LGrid2, LL + 1, LRowOrColumn, AMiddle, ALodError);
      AGrids[ASecond] := LNewGrid;
      if Length(FStitched) > ASecond then
        FStitched[ASecond] := False;
      Exit(True);
    end;
  end;
  Result := False;
end;

function TBspPatchStitcher.StitchPair(var AGrids: TArray<IPatchGrid>; const AFirst,
  ASecond: Integer): Boolean;
var
  LGrid1: IPatchGrid;
  LN, LK, LOffset1, LWidth, LHeight: Integer;
begin
  LGrid1 := AGrids[AFirst];
  LWidth := LGrid1.Width;
  LHeight := LGrid1.Height;

  // first block: the rows of the first grid, from the start
  for LN := 0 to 1 do
  begin
    if LN = 1 then
      LOffset1 := (LHeight - 1) * LWidth
    else
      LOffset1 := 0;
    if TBspGridEdges.MergedWidthPoints(LGrid1, LOffset1) then
      Continue;
    LK := 0;
    while LK < LWidth - 2 do
    begin
      if TryEdge(AGrids, ASecond, PositionOf(LGrid1, LK + LOffset1), PositionOf(LGrid1, LK + 2 + LOffset1),
        PositionOf(LGrid1, LK + 1 + LOffset1), WidthError(LGrid1, LK + 1)) then
        Exit(True);
      Inc(LK, 2);
    end;
  end;

  // second block: the columns of the first grid, from the start
  for LN := 0 to 1 do
  begin
    if LN = 1 then
      LOffset1 := LWidth - 1
    else
      LOffset1 := 0;
    if TBspGridEdges.MergedHeightPoints(LGrid1, LOffset1) then
      Continue;
    LK := 0;
    while LK < LHeight - 2 do
    begin
      if TryEdge(AGrids, ASecond, PositionOf(LGrid1, LWidth * LK + LOffset1),
        PositionOf(LGrid1, LWidth * (LK + 2) + LOffset1), PositionOf(LGrid1, LWidth * (LK + 1) + LOffset1),
        HeightError(LGrid1, LK + 1)) then
        Exit(True);
      Inc(LK, 2);
    end;
  end;

  // third block: the rows, from the end (the error is read at k + 1 as in the original)
  for LN := 0 to 1 do
  begin
    if LN = 1 then
      LOffset1 := (LHeight - 1) * LWidth
    else
      LOffset1 := 0;
    if TBspGridEdges.MergedWidthPoints(LGrid1, LOffset1) then
      Continue;
    LK := LWidth - 1;
    while LK > 1 do
    begin
      if TryEdge(AGrids, ASecond, PositionOf(LGrid1, LK + LOffset1), PositionOf(LGrid1, LK - 2 + LOffset1),
        PositionOf(LGrid1, LK - 1 + LOffset1), WidthError(LGrid1, LK + 1)) then
        Exit(True);
      Dec(LK, 2);
    end;
  end;

  // fourth block: the columns, from the end
  for LN := 0 to 1 do
  begin
    if LN = 1 then
      LOffset1 := LWidth - 1
    else
      LOffset1 := 0;
    if TBspGridEdges.MergedHeightPoints(LGrid1, LOffset1) then
      Continue;
    LK := LHeight - 1;
    while LK > 1 do
    begin
      if TryEdge(AGrids, ASecond, PositionOf(LGrid1, LWidth * LK + LOffset1),
        PositionOf(LGrid1, LWidth * (LK - 2) + LOffset1), PositionOf(LGrid1, LWidth * (LK - 1) + LOffset1),
        HeightError(LGrid1, LK + 1)) then
        Exit(True);
      Dec(LK, 2);
    end;
  end;
  Result := False;
end;

// R_TryStitchingPatch: the first grid is read once, as the original does (after a stitch into
// its own slot the old grid is still the one compared, with the same origin and radius)
function TBspPatchStitcher.TryStitchingPatch(var AGrids: TArray<IPatchGrid>;
  const AFirst: Integer): Integer;
var
  LGrid1: IPatchGrid;
  LJ: Integer;
begin
  Result := 0;
  LGrid1 := AGrids[AFirst];
  for LJ := 0 to High(AGrids) do
  begin
    if not Assigned(AGrids[LJ]) then
      Continue;
    if not SameGroup(LGrid1, AGrids[LJ]) then
      Continue;
    while StitchPair(AGrids, AFirst, LJ) do
      Inc(Result);
  end;
end;

function TBspPatchStitcher.StitchAll(var AGrids: TArray<IPatchGrid>): Integer;
var
  LI: Integer;
  LStitched: Boolean;
begin
  Result := 0;
  SetLength(FStitched, Length(AGrids));
  try
    repeat
      LStitched := False;
      for LI := 0 to High(AGrids) do
      begin
        if not Assigned(AGrids[LI]) then
          Continue;
        if FStitched[LI] then
          Continue;
        FStitched[LI] := True;
        LStitched := True;
        Inc(Result, TryStitchingPatch(AGrids, LI));
      end;
    until not LStitched;
  finally
    FStitched := nil;
  end;
end;

end.
