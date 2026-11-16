{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the closest points of two ground edges            }
{                                                                              }
{  Port of AAS_ClosestEdgePoints of be_aas_reach.c: a range of points closest  }
{  to each other on both edges. Based on the Quake III Arena GPL Source Code   }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is       }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.EdgePoints;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types;

type
  /// <summary>The range of the closest points of two edges</summary>
  TAasReachEdgePoints = class sealed
  public
    /// <summary>
    ///   AAS_ClosestEdgePoints: v1-v2 is an edge of the first area (ground plane APlane1), v3-v4 an edge of the second
    ///   (APlane2). The range of the closest points is BestStart1..BestStart2 on the first edge and BestEnd1..BestEnd2
    ///   on the second; the result is the distance (the best distance so far if the new one is not better)
    /// </summary>
    class function Closest(const V1, V2, V3, V4: TVec3; const APlane1, APlane2: TAasPlane; var ABestStart1, ABestEnd1,
      ABestStart2, ABestEnd2: TVec3; const ABestDistance: Single): Single; static;
  end;

implementation

uses
  DelphiDoom.Aas.VectorMath, DelphiDoom.Aas.Reach.Vectors;

const
  CHalf: Double = 0.5;

// a point of the new range that is as close as the best one: it widens the range if it is further from both ends
procedure WidenRange(var ARange1, ARange2: TVec3; const APoint: TVec3);
var
  LDistance1, LDistance2, LLength: Single;
begin
  LDistance1 := TAasReachVectors.Distance(ARange1, APoint);
  LDistance2 := TAasReachVectors.Distance(ARange2, APoint);
  if LDistance1 > LDistance2 then
  begin
    LLength := TAasReachVectors.Distance(ARange1, ARange2);
    if LDistance1 > LLength then
      ARange2 := APoint;
  end
  else
  begin
    LLength := TAasReachVectors.Distance(ARange1, ARange2);
    if LDistance2 > LLength then
      ARange1 := APoint;
  end;
end;

{ TAasReachEdgePoints }

class function TAasReachEdgePoints.Closest(const V1, V2, V3, V4: TVec3; const APlane1, APlane2: TAasPlane;
  var ABestStart1, ABestEnd1, ABestStart2, ABestEnd2: TVec3; const ABestDistance: Single): Single;
var
  LDir1, LDir2, LP1, LP2, LP3, LP4: TVec3;
  LA1, LA2, LB1, LB2, LDist, LBestDist, LTerm, LSum, LDot: Single;
  LFound: Boolean;

  function Near(const ADist: Single): Boolean;
  begin
    Result := (Double(ADist) > Double(LBestDist) - CHalf) and (Double(ADist) < Double(LBestDist) + CHalf);
  end;

  // the distance is not near the best one: it is a new best one if it is smaller
  procedure Better(const ARange1Start, ARange1End, ARange2Start, ARange2End: TVec3; const ADist: Single);
  begin
    LBestDist := ADist;
    ABestStart1 := ARange1Start;
    ABestStart2 := ARange1End;
    ABestEnd1 := ARange2Start;
    ABestEnd2 := ARange2End;
  end;

  function PointOnLine(const AV, ADir: TVec3; const AA, AB: Single): Single;
  begin
    // (DotProduct(v, dir) - (a * dir[0] + b * dir[1])) / dir[0]
    LDot := TAasVectorMath.Dot(AV, ADir);
    LTerm := AA * ADir[0];
    LSum := AB * ADir[1];
    LSum := LTerm + LSum;
    LDot := LDot - LSum;
    Result := LDot / ADir[0];
  end;

  procedure LineY(var AP: TVec3; const AA, AB: Single);
  begin
    LTerm := AA * AP[0];
    AP[1] := LTerm + AB;
  end;

  function PlaneZ(const APlane: TAasPlane; const AP: TVec3): Single;
  begin
    LDot := TAasVectorMath.Dot(APlane.Normal, AP);
    LDot := APlane.Dist - LDot;
    Result := LDot / APlane.Normal[2];
  end;

begin
  LBestDist := ABestDistance;
  // the edge vectors, with the horizontal directions
  TAasVectorMath.Subtract(V2, V1, LDir1);
  TAasVectorMath.Subtract(V4, V3, LDir2);
  LDir1[2] := 0;
  LDir2[2] := 0;
  // p1 and p2 are the points on the edge vector of the second area that are closest to v1 and v2, p3 and p4 the points
  // on the edge vector of the first area that are closest to v3 and v4
  LA2 := 0;
  LB2 := 0;
  if LDir2[0] <> 0 then
  begin
    LA2 := LDir2[1] / LDir2[0];
    LTerm := LA2 * V3[0];
    LB2 := V3[1] - LTerm;
    LP1[0] := PointOnLine(V1, LDir2, LA2, LB2);
    LineY(LP1, LA2, LB2);
    LP2[0] := PointOnLine(V2, LDir2, LA2, LB2);
    LineY(LP2, LA2, LB2);
  end
  else
  begin
    LP1[0] := V3[0];
    LP1[1] := V1[1];
    LP2[0] := V3[0];
    LP2[1] := V2[1];
  end;
  LA1 := 0;
  LB1 := 0;
  if LDir1[0] <> 0 then
  begin
    LA1 := LDir1[1] / LDir1[0];
    LTerm := LA1 * V1[0];
    LB1 := V1[1] - LTerm;
    LP3[0] := PointOnLine(V3, LDir1, LA1, LB1);
    LineY(LP3, LA1, LB1);
    LP4[0] := PointOnLine(V4, LDir1, LA1, LB1);
    LineY(LP4, LA1, LB1);
  end
  else
  begin
    LP3[0] := V1[0];
    LP3[1] := V3[1];
    LP4[0] := V1[0];
    LP4[1] := V4[1];
  end;
  // the z coordinates from the ground planes
  LP1[2] := 0;
  LP2[2] := 0;
  LP3[2] := 0;
  LP4[2] := 0;
  LP1[2] := PlaneZ(APlane2, LP1);
  LP2[2] := PlaneZ(APlane2, LP2);
  LP3[2] := PlaneZ(APlane1, LP3);
  LP4[2] := PlaneZ(APlane1, LP4);
  LFound := False;
  if TAasReachVectors.Between(LP1, V3, V4) then
  begin
    LDist := TAasReachVectors.Distance(V1, LP1);
    if Near(LDist) then
    begin
      WidenRange(ABestStart1, ABestStart2, V1);
      WidenRange(ABestEnd1, ABestEnd2, LP1);
    end
    else if LDist < LBestDist then
      Better(V1, V1, LP1, LP1, LDist);
    LFound := True;
  end;
  if TAasReachVectors.Between(LP2, V3, V4) then
  begin
    LDist := TAasReachVectors.Distance(V2, LP2);
    if Near(LDist) then
    begin
      WidenRange(ABestStart1, ABestStart2, V2);
      WidenRange(ABestEnd1, ABestEnd2, LP2);
    end
    else if LDist < LBestDist then
      Better(V2, V2, LP2, LP2, LDist);
    LFound := True;
  end;
  if TAasReachVectors.Between(LP3, V1, V2) then
  begin
    LDist := TAasReachVectors.Distance(V3, LP3);
    if Near(LDist) then
    begin
      WidenRange(ABestStart1, ABestStart2, LP3);
      WidenRange(ABestEnd1, ABestEnd2, V3);
    end
    else if LDist < LBestDist then
      Better(LP3, LP3, V3, V3, LDist);
    LFound := True;
  end;
  if TAasReachVectors.Between(LP4, V1, V2) then
  begin
    LDist := TAasReachVectors.Distance(V4, LP4);
    if Near(LDist) then
    begin
      WidenRange(ABestStart1, ABestStart2, LP4);
      WidenRange(ABestEnd1, ABestEnd2, V4);
    end
    else if LDist < LBestDist then
      Better(LP4, LP4, V4, V4, LDist);
    LFound := True;
  end;
  // if no shortest distance was found it is between one of the vertexes of the first edge and one of the second
  if not LFound then
  begin
    LDist := TAasReachVectors.Distance(V1, V3);
    if LDist < LBestDist then
      Better(V1, V1, V3, V3, LDist);
    LDist := TAasReachVectors.Distance(V1, V4);
    if LDist < LBestDist then
      Better(V1, V1, V4, V4, LDist);
    LDist := TAasReachVectors.Distance(V2, V3);
    if LDist < LBestDist then
      Better(V2, V2, V3, V3, LDist);
    LDist := TAasReachVectors.Distance(V2, V4);
    if LDist < LBestDist then
      Better(V2, V2, V4, V4, LDist);
  end;
  Result := LBestDist;
end;

end.
