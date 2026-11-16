{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the BSP of Quake III Arena: LOD errors of    }
{  shared vertices                                                             }
{                                                                              }
{  Port of R_FixSharedVertexLodError and R_FixSharedVertexLodError_r           }
{  (tr_bsp.c). Based on the Quake III Arena GPL Source Code (id Software).     }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.LodFixer;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.MathCore.Patch.Intf;

type
  /// <summary>
  ///   Makes the vertices that two grids of the same LOD group share on their edges have the
  ///   same error, so that the group subdivides as one and does not crack. The errors are
  ///   written into the grids of the array (nil slots are surfaces that are not grids). The
  ///   recursion of the original goes through every grid it touches, here as well.
  /// </summary>
  TBspLodFixer = class(TInterfacedObject, IBspLodFixer)
  strict private
    // lodFixed of each slot: 0, or 2 once the errors of the grid have been fixed
    FFixed: TArray<Integer>;
    procedure FixRecursive(const AGrids: TArray<IPatchGrid>; const AStart: Integer;
      const AGrid1: IPatchGrid);
  public
    procedure Fix(const AGrids: TArray<IPatchGrid>);
  end;

implementation

uses
  DelphiDoom.MapFile.Bsp.GridEdges;

{ TBspLodFixer }

procedure TBspLodFixer.Fix(const AGrids: TArray<IPatchGrid>);
var
  LI: Integer;
begin
  SetLength(FFixed, Length(AGrids));
  try
    for LI := 0 to High(AGrids) do
    begin
      // if this surface is not a grid
      if not Assigned(AGrids[LI]) then
        Continue;
      if FFixed[LI] <> 0 then
        Continue;
      FFixed[LI] := 2;
      // recursively fix other patches in the same LOD group
      FixRecursive(AGrids, LI + 1, AGrids[LI]);
    end;
  finally
    FFixed := nil;
  end;
end;

procedure TBspLodFixer.FixRecursive(const AGrids: TArray<IPatchGrid>; const AStart: Integer;
  const AGrid1: IPatchGrid);
var
  LGrid2: IPatchGrid;
  LJ, LK, LL, LM, LN, LOffset1, LOffset2: Integer;
  LTouch: Boolean;
begin
  for LJ := AStart to High(AGrids) do
  begin
    LGrid2 := AGrids[LJ];
    if not Assigned(LGrid2) then
      Continue;
    // if the LOD errors are already fixed for this patch
    if FFixed[LJ] = 2 then
      Continue;
    // grids in the same LOD group should have the exact same lod radius and origin
    if AGrid1.LodRadius <> LGrid2.LodRadius then
      Continue;
    if AGrid1.LodOrigin.X <> LGrid2.LodOrigin.X then
      Continue;
    if AGrid1.LodOrigin.Y <> LGrid2.LodOrigin.Y then
      Continue;
    if AGrid1.LodOrigin.Z <> LGrid2.LodOrigin.Z then
      Continue;

    LTouch := False;
    // the rows of the first grid against the rows and the columns of the second
    for LN := 0 to 1 do
    begin
      if LN = 1 then
        LOffset1 := (AGrid1.Height - 1) * AGrid1.Width
      else
        LOffset1 := 0;
      if TBspGridEdges.MergedWidthPoints(AGrid1, LOffset1) then
        Continue;
      for LK := 1 to AGrid1.Width - 2 do
      begin
        for LM := 0 to 1 do
        begin
          if LM = 1 then
            LOffset2 := (LGrid2.Height - 1) * LGrid2.Width
          else
            LOffset2 := 0;
          if TBspGridEdges.MergedWidthPoints(LGrid2, LOffset2) then
            Continue;
          for LL := 1 to LGrid2.Width - 2 do
          begin
            if not TBspGridEdges.Near(AGrid1.Vertices[LK + LOffset1].Position,
              LGrid2.Vertices[LL + LOffset2].Position) then
              Continue;
            // ok the points are equal and should have the same lod error
            LGrid2.SetWidthLodError(LL, AGrid1.WidthLodError[LK]);
            LTouch := True;
          end;
        end;
        for LM := 0 to 1 do
        begin
          if LM = 1 then
            LOffset2 := LGrid2.Width - 1
          else
            LOffset2 := 0;
          if TBspGridEdges.MergedHeightPoints(LGrid2, LOffset2) then
            Continue;
          for LL := 1 to LGrid2.Height - 2 do
          begin
            if not TBspGridEdges.Near(AGrid1.Vertices[LK + LOffset1].Position,
              LGrid2.Vertices[LGrid2.Width * LL + LOffset2].Position) then
              Continue;
            LGrid2.SetHeightLodError(LL, AGrid1.WidthLodError[LK]);
            LTouch := True;
          end;
        end;
      end;
    end;
    // the columns of the first grid
    for LN := 0 to 1 do
    begin
      if LN = 1 then
        LOffset1 := AGrid1.Width - 1
      else
        LOffset1 := 0;
      if TBspGridEdges.MergedHeightPoints(AGrid1, LOffset1) then
        Continue;
      for LK := 1 to AGrid1.Height - 2 do
      begin
        for LM := 0 to 1 do
        begin
          if LM = 1 then
            LOffset2 := (LGrid2.Height - 1) * LGrid2.Width
          else
            LOffset2 := 0;
          if TBspGridEdges.MergedWidthPoints(LGrid2, LOffset2) then
            Continue;
          for LL := 1 to LGrid2.Width - 2 do
          begin
            if not TBspGridEdges.Near(AGrid1.Vertices[AGrid1.Width * LK + LOffset1].Position,
              LGrid2.Vertices[LL + LOffset2].Position) then
              Continue;
            LGrid2.SetWidthLodError(LL, AGrid1.HeightLodError[LK]);
            LTouch := True;
          end;
        end;
        for LM := 0 to 1 do
        begin
          if LM = 1 then
            LOffset2 := LGrid2.Width - 1
          else
            LOffset2 := 0;
          if TBspGridEdges.MergedHeightPoints(LGrid2, LOffset2) then
            Continue;
          for LL := 1 to LGrid2.Height - 2 do
          begin
            if not TBspGridEdges.Near(AGrid1.Vertices[AGrid1.Width * LK + LOffset1].Position,
              LGrid2.Vertices[LGrid2.Width * LL + LOffset2].Position) then
              Continue;
            LGrid2.SetHeightLodError(LL, AGrid1.HeightLodError[LK]);
            LTouch := True;
          end;
        end;
      end;
    end;
    if LTouch then
    begin
      FFixed[LJ] := 2;
      FixRecursive(AGrids, AStart, LGrid2);
    end;
  end;
end;

end.
