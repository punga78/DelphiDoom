{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixLevelFixOps                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the fix_* helpers of RX_CreateDoomLevel (radix_level.pas): the      }
{  small operations that the corrections of a level are made of               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Level.FixOps;

interface

uses
  System.SysUtils, System.Math,
  DelphiDoom.Radix.Level.Types, DelphiDoom.Radix.Level.DoomMap;

type
  TRadixLevelFixOps = class
  public
    /// <summary>fix_changevertexes: the lines that use the vertex (x1, y1) use the vertex (x2, y2)</summary>
    class procedure ChangeVertexes(const AMap: TRadixDoomMap; AX1, AY1, AX2, AY2: Integer); static;
    /// <summary>fix_movevertex: the first vertex at (x1, y1) goes to (x2, y2)</summary>
    class procedure MoveVertex(const AMap: TRadixDoomMap; AX1, AY1, AX2, AY2: Integer); static;
    /// <summary>fix_cloneandmovewall: the wall of the level (its coordinates are Doom ones) is added again, moved</summary>
    class procedure CloneAndMoveWall(const AMap: TRadixDoomMap; AWall, ADeltaX, ADeltaY: Integer); static;
    /// <summary>fix_slide_line: floor slide things along a segment, one every 64 units or so</summary>
    class procedure SlideSegment(const AMap: TRadixDoomMap; AX1, AY1, AX2, AY2: Integer); static;
    /// <summary>fix_slide_line of a line of the map</summary>
    class procedure SlideLine(const AMap: TRadixDoomMap; ALine: Integer); static;
    /// <summary>fix_slide_corridor: slide things along the middle of two lines</summary>
    class procedure SlideCorridor(const AMap: TRadixDoomMap; ALine1, ALine2: Integer); static;
    /// <summary>make_slide_line</summary>
    class procedure MakeSlideLine(const AMap: TRadixDoomMap; ALine: Integer); static;
    /// <summary>make_blocking_line</summary>
    class procedure MakeBlockingLine(const AMap: TRadixDoomMap; ALine: Integer); static;
    /// <summary>Every side that is in the sector OLD goes in the sector NEW</summary>
    class procedure ReplaceSideSector(const AMap: TRadixDoomMap; AOld, ANew: Integer); static;
    /// <summary>A line that becomes a wall with one side (the side NEW), blocking</summary>
    class procedure MakeOneSided(const AMap: TRadixDoomMap; ALine, ASide: Integer); static;
  end;

implementation

{$Q-}
{$R-}

{ TRadixLevelFixOps }

class procedure TRadixLevelFixOps.ChangeVertexes(const AMap: TRadixDoomMap; AX1, AY1, AX2, AY2: Integer);
var
  LVertex1: Integer;
  LVertex2: Integer;
  LIndex: Integer;
begin
  LVertex1 := -1;
  for LIndex := 0 to AMap.Vertexes.Count - 1 do
    if (AMap.Vertexes[LIndex].X = SmallInt(AX1)) and (AMap.Vertexes[LIndex].Y = SmallInt(AY1)) then
    begin
      LVertex1 := LIndex;
      Break;
    end;
  LVertex2 := -1;
  for LIndex := 0 to AMap.Vertexes.Count - 1 do
    if (AMap.Vertexes[LIndex].X = SmallInt(AX2)) and (AMap.Vertexes[LIndex].Y = SmallInt(AY2)) then
    begin
      LVertex2 := LIndex;
      Break;
    end;
  if (LVertex1 >= 0) and (LVertex2 >= 0) then
    for LIndex := 0 to AMap.LineDefs.Count - 1 do
    begin
      if AMap.LineDefs[LIndex].V1 = LVertex1 then
        AMap.LineDefs[LIndex].V1 := SmallInt(LVertex2);
      if AMap.LineDefs[LIndex].V2 = LVertex1 then
        AMap.LineDefs[LIndex].V2 := SmallInt(LVertex2);
    end;
end;

class procedure TRadixLevelFixOps.MoveVertex(const AMap: TRadixDoomMap; AX1, AY1, AX2, AY2: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to AMap.Vertexes.Count - 1 do
    if (AMap.Vertexes[LIndex].X = SmallInt(AX1)) and (AMap.Vertexes[LIndex].Y = SmallInt(AY1)) then
    begin
      AMap.Vertexes[LIndex].X := SmallInt(AX2);
      AMap.Vertexes[LIndex].Y := SmallInt(AY2);
      Exit;
    end;
end;

class procedure TRadixLevelFixOps.CloneAndMoveWall(const AMap: TRadixDoomMap; AWall, ADeltaX,
  ADeltaY: Integer);
var
  LWall: TRadixLevelWall;
begin
  LWall := AMap.Level.Walls[AWall];
  LWall.V1X := LWall.V1X + ADeltaX;
  LWall.V1Y := LWall.V1Y + ADeltaY;
  LWall.V2X := LWall.V2X + ADeltaX;
  LWall.V2Y := LWall.V2Y + ADeltaY;
  AMap.AddWall(LWall);
end;

class procedure TRadixLevelFixOps.SlideSegment(const AMap: TRadixDoomMap; AX1, AY1, AX2, AY2: Integer);
var
  LDeltaX: Integer;
  LDeltaY: Integer;
  LStepX: Integer;
  LStepY: Integer;
  LX: Integer;
  LY: Integer;
  LIterations: Integer;
  LIndex: Integer;
  LSquare: Integer;
begin
  LDeltaX := AX2 - AX1;
  LDeltaY := AY2 - AY1;
  // the old code used Extended here (x87); the sum is exact in a Double
  LSquare := LDeltaX * LDeltaX + LDeltaY * LDeltaY;
  LIterations := Round(Sqrt(LSquare) / 64 + 0.4999);
  if LIterations < 1 then
    LIterations := 1;
  LX := AX1;
  LY := AY1;
  for LIndex := 0 to LIterations - 1 do
  begin
    LStepX := LDeltaX div (LIterations - LIndex);
    LStepY := LDeltaY div (LIterations - LIndex);
    AMap.AddDoomThing(LX + LStepX div 2, LY + LStepY div 2, 0, MT_PLAYERFLOORSLIDE64,
      MTF_EASY or MTF_NORMAL or MTF_HARD);
    LX := LX + LStepX;
    LY := LY + LStepY;
    LDeltaX := LDeltaX - LStepX;
    LDeltaY := LDeltaY - LStepY;
  end;
end;

class procedure TRadixLevelFixOps.SlideLine(const AMap: TRadixDoomMap; ALine: Integer);
begin
  SlideSegment(AMap, AMap.Vertexes[AMap.LineDefs[ALine].V1].X, AMap.Vertexes[AMap.LineDefs[ALine].V1].Y,
    AMap.Vertexes[AMap.LineDefs[ALine].V2].X, AMap.Vertexes[AMap.LineDefs[ALine].V2].Y);
end;

class procedure TRadixLevelFixOps.SlideCorridor(const AMap: TRadixDoomMap; ALine1, ALine2: Integer);
var
  LVertex21: Integer;
  LVertex22: Integer;
  LDistance1: Integer;
  LDistance2: Integer;
  LDeltaX: Integer;
  LDeltaY: Integer;
begin
  LDeltaX := AMap.Vertexes[AMap.LineDefs[ALine1].V1].X - AMap.Vertexes[AMap.LineDefs[ALine2].V1].X;
  LDeltaY := AMap.Vertexes[AMap.LineDefs[ALine1].V1].Y - AMap.Vertexes[AMap.LineDefs[ALine2].V1].Y;
  LDistance1 := LDeltaX * LDeltaX + LDeltaY * LDeltaY;
  LDeltaX := AMap.Vertexes[AMap.LineDefs[ALine1].V1].X - AMap.Vertexes[AMap.LineDefs[ALine2].V2].X;
  LDeltaY := AMap.Vertexes[AMap.LineDefs[ALine1].V1].Y - AMap.Vertexes[AMap.LineDefs[ALine2].V2].Y;
  LDistance2 := LDeltaX * LDeltaX + LDeltaY * LDeltaY;
  if LDistance1 < LDistance2 then
  begin
    LVertex21 := AMap.LineDefs[ALine2].V1;
    LVertex22 := AMap.LineDefs[ALine2].V2;
  end
  else
  begin
    LVertex21 := AMap.LineDefs[ALine2].V2;
    LVertex22 := AMap.LineDefs[ALine2].V1;
  end;
  SlideSegment(AMap,
    (AMap.Vertexes[AMap.LineDefs[ALine1].V1].X + AMap.Vertexes[LVertex21].X) div 2,
    (AMap.Vertexes[AMap.LineDefs[ALine1].V1].Y + AMap.Vertexes[LVertex21].Y) div 2,
    (AMap.Vertexes[AMap.LineDefs[ALine1].V2].X + AMap.Vertexes[LVertex22].X) div 2,
    (AMap.Vertexes[AMap.LineDefs[ALine1].V2].Y + AMap.Vertexes[LVertex22].Y) div 2);
end;

class procedure TRadixLevelFixOps.MakeSlideLine(const AMap: TRadixDoomMap; ALine: Integer);
begin
  AMap.LineDefs[ALine].Flags := AMap.LineDefs[ALine].Flags or ML_SLIDELINE;
end;

class procedure TRadixLevelFixOps.MakeBlockingLine(const AMap: TRadixDoomMap; ALine: Integer);
begin
  AMap.LineDefs[ALine].Flags := AMap.LineDefs[ALine].Flags or ML_BLOCKING;
end;

class procedure TRadixLevelFixOps.ReplaceSideSector(const AMap: TRadixDoomMap; AOld, ANew: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to AMap.SideDefs.Count - 1 do
    if AMap.SideDefs[LIndex].Sector = AOld then
      AMap.SideDefs[LIndex].Sector := SmallInt(ANew);
end;

class procedure TRadixLevelFixOps.MakeOneSided(const AMap: TRadixDoomMap; ALine, ASide: Integer);
begin
  AMap.LineDefs[ALine].SideNum[1] := -1;
  AMap.LineDefs[ALine].SideNum[0] := SmallInt(ASide);
  AMap.LineDefs[ALine].Flags := AMap.LineDefs[ALine].Flags and not ML_TWOSIDED;
  AMap.LineDefs[ALine].Flags := AMap.LineDefs[ALine].Flags or ML_BLOCKING;
end;

end.
