{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL level geometry - clips a polygon with partition lines    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  The idea and the algorithm to compute the flats with nodes and subsectors   }
{  are originally from JHexen; adapted by proff (2000).                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlLevel.FlatEdgeClipper;

interface

uses
  System.SysUtils,
  DelphiDoom.GlLevel.Types;

type
  /// <summary>A polygon being clipped: the points in order (room for the ones the clipping adds)</summary>
  TGlClipPolygon = record
    Count: Integer;
    Points: array[0..GLLEVEL_MAX_CARVER_SIDES] of TGlFixedPoint;
  end;

  /// <summary>
  ///   The old gld_FlatEdgeClipper with gld_PointOnSide and gld_CalcIntersectionVertex: the
  ///   polygon is clipped with each partition line, the left side of each line is discarded,
  ///   and consecutive identical points are removed. The arithmetic is the old one (Double,
  ///   the same expressions): the points are the same, bit for bit.
  /// </summary>
  TGlFlatEdgeClipper = class
  strict private
    class function Fix2Dbl(const AValue: Integer): Double; static;
    /// <summary>False if the point is on the left side of the line</summary>
    class function PointOnSide(const APoint: TGlFixedPoint; const ALine: TGlDivLine): Boolean; static;
    /// <summary>The point where the segment crosses the line (the two must intersect)</summary>
    class function Intersection(const AStart, AEnd: TGlFixedPoint; const ALine: TGlDivLine): TGlFixedPoint; static;
  public
    /// <summary>Clips the polygon; raises EGlLevelException if it gets more than 63 points</summary>
    class procedure Clip(var APolygon: TGlClipPolygon; const AClippers: array of TGlDivLine); static;
  end;

implementation

{ TGlFlatEdgeClipper }

class function TGlFlatEdgeClipper.Fix2Dbl(const AValue: Integer): Double;
begin
  Result := AValue / 1.0;
end;

class function TGlFlatEdgeClipper.PointOnSide(const APoint: TGlFixedPoint; const ALine: TGlDivLine): Boolean;
begin
  // We'll return false if the point is on the left side.
  Result := (Fix2Dbl(ALine.Y) - Fix2Dbl(APoint.Y)) * Fix2Dbl(ALine.DX) -
    (Fix2Dbl(ALine.X) - Fix2Dbl(APoint.X)) * Fix2Dbl(ALine.DY) >= 0;
end;

class function TGlFlatEdgeClipper.Intersection(const AStart, AEnd: TGlFixedPoint;
  const ALine: TGlDivLine): TGlFixedPoint;
var
  LAx, LAy, LBx, LBy, LCx, LCy, LDx, LDy, LRatio: Double;
begin
  LAx := Fix2Dbl(AStart.X);
  LAy := Fix2Dbl(AStart.Y);
  LBx := Fix2Dbl(AEnd.X);
  LBy := Fix2Dbl(AEnd.Y);
  LCx := Fix2Dbl(ALine.X);
  LCy := Fix2Dbl(ALine.Y);
  LDx := LCx + Fix2Dbl(ALine.DX);
  LDy := LCy + Fix2Dbl(ALine.DY);
  LRatio := ((LAy - LCy) * (LDx - LCx) - (LAx - LCx) * (LDy - LCy)) / ((LBx - LAx) * (LDy - LCy) - (LBy - LAy) * (LDx - LCx));
  Result.X := Round(Fix2Dbl(AStart.X) + LRatio * (Fix2Dbl(AEnd.X) - Fix2Dbl(AStart.X)));
  Result.Y := Round(Fix2Dbl(AStart.Y) + LRatio * (Fix2Dbl(AEnd.Y) - Fix2Dbl(AStart.Y)));
end;

class procedure TGlFlatEdgeClipper.Clip(var APolygon: TGlClipPolygon; const AClippers: array of TGlDivLine);
var
  LSides: array[0..GLLEVEL_MAX_CARVER_SIDES - 1] of Boolean;
  LClip, LIndex, LCount: Integer;
  LStart, LEnd, LPrevious: Integer;
  LNew: TGlFixedPoint;
begin
  LCount := APolygon.Count;
  // We'll clip the polygon with each of the divlines. The left side of
  // each divline is discarded.
  for LClip := 0 to High(AClippers) do
  begin
    // First we'll determine the side of each vertex. Points are allowed
    // to be on the line.
    for LIndex := 0 to LCount - 1 do
      LSides[LIndex] := PointOnSide(APolygon.Points[LIndex], AClippers[LClip]);

    LIndex := 0;
    while LIndex < LCount do
    begin
      LStart := LIndex;
      LEnd := LIndex + 1;
      // Check the end index.
      if LEnd = LCount then
        LEnd := 0; // Wrap-around.
      // Clipping will happen when the ends are on different sides.
      if LSides[LStart] <> LSides[LEnd] then
      begin
        LNew := Intersection(APolygon.Points[LStart], APolygon.Points[LEnd], AClippers[LClip]);

        // Add the new vertex. Also modify the sidelist.
        Inc(LCount);
        if LCount >= GLLEVEL_MAX_CARVER_SIDES then
          raise EGlLevelException.Create(SGlLevelTooManyPoints);

        // Make room for the new vertex.
        Move(APolygon.Points[LEnd], APolygon.Points[LEnd + 1], (LCount - LEnd - 1) * SizeOf(TGlFixedPoint));
        APolygon.Points[LEnd] := LNew;

        Move(LSides[LEnd], LSides[LEnd + 1], LCount - LEnd - 1);
        LSides[LEnd] := True;

        // Skip over the new vertex.
        Inc(LIndex);
      end;
      Inc(LIndex);
    end;

    // Now we must discard the points that are on the wrong side.
    LIndex := 0;
    while LIndex < LCount do
    begin
      if not LSides[LIndex] then
      begin
        Move(APolygon.Points[LIndex + 1], APolygon.Points[LIndex], (LCount - LIndex - 1) * SizeOf(TGlFixedPoint));
        Move(LSides[LIndex + 1], LSides[LIndex], LCount - LIndex - 1);
        Dec(LCount);
      end
      else
        Inc(LIndex);
    end;
  end;

  // Screen out consecutive identical points.
  LIndex := 0;
  while LIndex < LCount do
  begin
    LPrevious := LIndex - 1;
    if LPrevious < 0 then
      LPrevious := LCount - 1;
    if (APolygon.Points[LIndex].X = APolygon.Points[LPrevious].X) and
       (APolygon.Points[LIndex].Y = APolygon.Points[LPrevious].Y) then
    begin
      // This point must be removed.
      Move(APolygon.Points[LIndex + 1], APolygon.Points[LIndex], (LCount - LIndex - 1) * SizeOf(TGlFixedPoint));
      Dec(LCount);
    end
    else
      Inc(LIndex);
  end;

  APolygon.Count := LCount;
end;

end.
