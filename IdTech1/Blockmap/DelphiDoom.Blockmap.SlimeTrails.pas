{******************************************************************************}
{                                                                              }
{  DelphiDoom: blockmap - slime trails                                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Algorithm of killough (MBF, 10/98)                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Blockmap.SlimeTrails;

// The products are 64 bit and the coordinates 32 bit: the same wraparound as
// the original code is wanted
{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Blockmap.Intf,
  DelphiDoom.Blockmap.Types;

type
  /// <summary>
  ///   Slime trails come from the integer coordinates of the WAD: a node builder splits
  ///   segs at points that are not integer. For each seg of a slanted line, each
  ///   vertex that is not an end of the line and was not moved yet is projected onto
  ///   the line (law of cosines). Orthogonal lines are skipped, and so are minisegs
  /// </summary>
  TBlockmapSlimeTrailRemover = class(TInterfacedObject, ISlimeTrailRemover)
  strict private
    class procedure CheckIndex(const AIndex, ACount: Integer); static;
  public
    procedure Remove(var AVertexes: TArray<TBlockmapPoint>; const ASegs: TArray<TBlockmapSeg>);
  end;

implementation

{ TBlockmapSlimeTrailRemover }

class procedure TBlockmapSlimeTrailRemover.CheckIndex(const AIndex, ACount: Integer);
begin
  if (AIndex < 0) or (AIndex >= ACount) then
    raise EBlockmapException.CreateFmt(SBlockmapVertexOutOfRange, [AIndex, ACount]);
end;

procedure TBlockmapSlimeTrailRemover.Remove(var AVertexes: TArray<TBlockmapPoint>;
  const ASegs: TArray<TBlockmapSeg>);
var
  LHit: TArray<Boolean>;
  LSegIndex, LVertex, LSide: Integer;
  LSeg: TBlockmapSeg;
  LDeltaX, LDeltaY: Integer;
  LDeltaX2, LDeltaY2, LDeltaXY, LSum: Int64;
  LX0, LY0, LX1, LY1: Integer;
begin
  SetLength(LHit, Length(AVertexes));
  for LSegIndex := 0 to High(ASegs) do
  begin
    LSeg := ASegs[LSegIndex];
    if LSeg.Miniseg then
      Continue;
    // orthogonal lines almost never make slime
    if (LSeg.LineDeltaX = 0) or (LSeg.LineDeltaY = 0) then
      Continue;

    CheckIndex(LSeg.LineVertex1, Length(AVertexes));
    CheckIndex(LSeg.LineVertex2, Length(AVertexes));
    for LSide := 0 to 1 do
    begin
      if LSide = 0 then
        LVertex := LSeg.Vertex1
      else
        LVertex := LSeg.Vertex2;
      CheckIndex(LVertex, Length(AVertexes));
      if LHit[LVertex] then
        Continue;
      LHit[LVertex] := True;
      // the ends of the line stay where they are
      if (LVertex = LSeg.LineVertex1) or (LVertex = LSeg.LineVertex2) then
        Continue;

      // project the vertex back onto the parent line; truncation like the original
      LDeltaX := LSeg.LineDeltaX div BLOCKMAP_FRACUNIT;
      LDeltaY := LSeg.LineDeltaY div BLOCKMAP_FRACUNIT;
      LDeltaX2 := Int64(LDeltaX) * LDeltaX;
      LDeltaY2 := Int64(LDeltaY) * LDeltaY;
      LDeltaXY := Int64(LDeltaX) * LDeltaY;
      LSum := LDeltaX2 + LDeltaY2;
      LX0 := AVertexes[LVertex].X;
      LY0 := AVertexes[LVertex].Y;
      LX1 := AVertexes[LSeg.LineVertex1].X;
      LY1 := AVertexes[LSeg.LineVertex1].Y;
      AVertexes[LVertex].X := Round((LDeltaX2 * LX0 + LDeltaY2 * LX1 + LDeltaXY * (LY0 - LY1)) / LSum);
      AVertexes[LVertex].Y := Round((LDeltaY2 * LY0 + LDeltaX2 * LY1 + LDeltaXY * (LX0 - LX1)) / LSum);
    end;
  end;
end;

end.
