{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the equations of the rotational collision   }
{                                                                              }
{  Port of CM_RotatePoint, CM_RotateEdge, CollisionBetweenEdgeBounds,          }
{  RotateEdgeThroughEdge, EdgeFurthestFromEdge, RotatePointThroughPlane,       }
{  PointFurthestFromPlane and RotatePointThroughEpsilonPlane                   }
{  (CollisionModel_rotate.cpp), Doom 3 GPL Source Code. Copyright (C)          }
{  1999-2011 id Software LLC, a ZeniMax Media company. Based on the Doom 3     }
{  GPL Source Code (id Software). This unit is derived from the Doom 3 GPL     }
{  source code and is therefore available under the GNU General Public         }
{  License, version 3 or (at your option) any later version, with the          }
{  additional terms of the Doom 3 Source Code License                          }
{  (Reference\doom3\COPYING.txt: preservation of legal notices and             }
{  trademarks, no use of the licensors' names for publicity, warranty          }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.RotationMath;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Pluecker,
  DelphiDoom.Collision.TraceWork;

type
  /// <summary>
  ///   The closed-form parts of the rotational collision. A rotation is described by the
  ///   tangent of half the angle (r = tan(a/2), sin(a) = 2r/(1+r*r), cos(a) = (1-r*r)/(1+r*r)),
  ///   which turns the condition "the point or edge touches the plane or edge" into a
  ///   quadratic. All of them are stateless; the trace work only supplies the axis, the
  ///   origin, the matrix that takes the axis to the z-axis, the angle and the current MaxTan.
  ///   The locals the original keeps in double are Double here.
  /// </summary>
  TCollisionRotationMath = class sealed
  private
    /// <summary>
    ///   The two roots of (v0 - v2) r*r + 2 v1 r + (v0 + v2) = 0 as the original picks them:
    ///   false if there is no real root, frac2 is 1e10 (= tan(pi/2)) for a linear equation
    /// </summary>
    class function SolveHalfAngleTangents(AA, AB, AC: Double; out AFrac1, AFrac2: Double): Boolean; static;
  public
    /// <summary>CM_RotatePoint: rotates a point about an arbitrary axis using the tangent of half the angle</summary>
    class procedure RotatePoint(var APoint: TGeoVec3; const AOrigin, AAxis: TGeoVec3;
      ATanHalfAngle: Single); static;
    /// <summary>CM_RotateEdge</summary>
    class procedure RotateEdge(var AStart, AEnd: TGeoVec3; const AOrigin, AAxis: TGeoVec3;
      ATanHalfAngle: Single); static;
    /// <summary>
    ///   CollisionBetweenEdgeBounds: true if the two edges collide between the edge bounds;
    ///   also gives the collision point and the normal of the collision plane
    /// </summary>
    class function CollisionBetweenEdgeBounds(ATraceWork: TCmTraceWork; const AVa, AVb, AVc, AVd: TGeoVec3;
      ATanHalfAngle: Single; out ACollisionPoint, ACollisionNormal: TGeoVec3): Boolean; static;
    /// <summary>RotateEdgeThroughEdge: the tangent of half the angle at which the edges collide</summary>
    class function RotateEdgeThroughEdge(ATraceWork: TCmTraceWork; const APl1: TGeoPluecker;
      const AVc, AVd: TGeoVec3; AMinTan: Single; var ATanHalfAngle: Single): Boolean; static;
    /// <summary>
    ///   EdgeFurthestFromEdge: the direction of motion at the start (ADir &lt; 0: the edges move
    ///   towards each other) and, when they move apart, the tangent at which they are furthest
    /// </summary>
    class function EdgeFurthestFromEdge(ATraceWork: TCmTraceWork; const APl1: TGeoPluecker;
      const AVc, AVd: TGeoVec3; var ATanHalfAngle, ADir: Single): Boolean; static;
    /// <summary>RotatePointThroughPlane: the tangent of half the angle at which the point meets the plane</summary>
    class function RotatePointThroughPlane(ATraceWork: TCmTraceWork; const APoint: TGeoVec3;
      const APlane: TGeoPlane; AAngle, AMinTan: Single; var ATanHalfAngle: Single): Boolean; static;
    /// <summary>PointFurthestFromPlane</summary>
    class function PointFurthestFromPlane(ATraceWork: TCmTraceWork; const APoint: TGeoVec3;
      const APlane: TGeoPlane; AAngle: Single; var ATanHalfAngle, ADir: Single): Boolean; static;
    /// <summary>RotatePointThroughEpsilonPlane</summary>
    class function RotatePointThroughEpsilonPlane(ATraceWork: TCmTraceWork; const APoint, AEndPoint: TGeoVec3;
      const APlane: TGeoPlane; AAngle: Single; const AOrigin: TGeoVec3; var ATanHalfAngle: Single;
      out ACollisionPoint, AEndDir: TGeoVec3): Boolean; static;
  end;

const
  /// <summary>CM_PL_RANGE_EPSILON: epsilon for round-off errors in epsilon calculations</summary>
  CM_PL_RANGE_EPSILON: Single = 1e-4;

/// <summary>
///   ROTATION_AXIS_EPSILON: a collision this close to the rotation axis is not a collision
///   (CM_CLIP_EPSILON * 0.25)
/// </summary>
function RotationAxisEpsilon: Single; inline;

implementation

uses
  DelphiDoom.Collision.Types;

function RotationAxisEpsilon: Single;
begin
  Result := CM_CLIP_EPSILON * 0.25;
end;

{ TCollisionRotationMath }

class function TCollisionRotationMath.SolveHalfAngleTangents(AA, AB, AC: Double; out AFrac1,
  AFrac2: Double): Boolean;
var
  LD: Double;
  LSqrtD: Double;
  LQ: Double;
begin
  AFrac1 := 0;
  AFrac2 := 0;
  if AA = 0 then
  begin
    if AB = 0 then
      Exit(False);
    AFrac1 := -AC / (2.0 * AB);
    // = tan( idMath::HALF_PI )
    AFrac2 := 1E10;
  end
  else
  begin
    LD := AB * AB - AC * AA;
    if LD <= 0 then
      Exit(False);
    LSqrtD := Sqrt(LD);
    if AB > 0 then
      LQ := -AB + LSqrtD
    else
      LQ := -AB - LSqrtD;
    AFrac1 := LQ / AA;
    AFrac2 := AC / LQ;
  end;
  Result := True;
end;

class procedure TCollisionRotationMath.RotatePoint(var APoint: TGeoVec3; const AOrigin, AAxis: TGeoVec3;
  ATanHalfAngle: Single);
var
  LD: Double;
  LT: Double;
  LS: Double;
  LC: Double;
  LProj: TGeoVec3;
  LV1: TGeoVec3;
  LV2: TGeoVec3;
begin
  APoint := APoint - AOrigin;
  LProj := AAxis * AAxis.Dot(APoint);
  LV1 := APoint - LProj;
  LV2 := AAxis.Cross(LV1);
  // r = tan( a / 2 );
  // sin(a) = 2*r/(1+r*r);
  // cos(a) = (1-r*r)/(1+r*r);
  LT := ATanHalfAngle * ATanHalfAngle;
  LD := 1.0 / (1.0 + LT);
  LS := 2.0 * ATanHalfAngle * LD;
  LC := (1.0 - LT) * LD;
  APoint := LV1 * LC - LV2 * LS + LProj + AOrigin;
end;

class procedure TCollisionRotationMath.RotateEdge(var AStart, AEnd: TGeoVec3; const AOrigin,
  AAxis: TGeoVec3; ATanHalfAngle: Single);
var
  LD: Double;
  LT: Double;
  LS: Double;
  LC: Double;
  LProj: TGeoVec3;
  LV1: TGeoVec3;
  LV2: TGeoVec3;
begin
  LT := ATanHalfAngle * ATanHalfAngle;
  LD := 1.0 / (1.0 + LT);
  LS := 2.0 * ATanHalfAngle * LD;
  LC := (1.0 - LT) * LD;

  AStart := AStart - AOrigin;
  LProj := AAxis * AAxis.Dot(AStart);
  LV1 := AStart - LProj;
  LV2 := AAxis.Cross(LV1);
  AStart := LV1 * LC - LV2 * LS + LProj + AOrigin;

  AEnd := AEnd - AOrigin;
  LProj := AAxis * AAxis.Dot(AEnd);
  LV1 := AEnd - LProj;
  LV2 := AAxis.Cross(LV1);
  AEnd := LV1 * LC - LV2 * LS + LProj + AOrigin;
end;

class function TCollisionRotationMath.CollisionBetweenEdgeBounds(ATraceWork: TCmTraceWork; const AVa, AVb,
  AVc, AVd: TGeoVec3; ATanHalfAngle: Single; out ACollisionPoint, ACollisionNormal: TGeoVec3): Boolean;
var
  LD1: Single;
  LD2: Single;
  LD: Single;
  LAt: TGeoVec3;
  LBt: TGeoVec3;
  LDir: TGeoVec3;
  LDir1: TGeoVec3;
  LDir2: TGeoVec3;
  LPl1: TGeoPluecker;
  LPl2: TGeoPluecker;
begin
  ACollisionPoint.Zero;
  ACollisionNormal.Zero;
  LAt := AVa;
  LBt := AVb;
  if ATanHalfAngle <> 0 then
    RotateEdge(LAt, LBt, ATraceWork.Origin, ATraceWork.Axis, ATanHalfAngle);

  LDir1 := (LAt - ATraceWork.Origin).Cross(ATraceWork.Axis);
  LDir2 := (LBt - ATraceWork.Origin).Cross(ATraceWork.Axis);
  if LDir1.Dot(LDir1) > LDir2.Dot(LDir2) then
    LDir := LDir1
  else
    LDir := LDir2;
  if ATraceWork.Angle < 0 then
    LDir := -LDir;

  LPl1.FromLine(LAt, LBt);
  LPl2.FromRay(AVc, LDir);
  LD1 := LPl1.PermutedInnerProduct(LPl2);
  LPl2.FromRay(AVd, LDir);
  LD2 := LPl1.PermutedInnerProduct(LPl2);
  if ((LD1 > 0) and (LD2 > 0)) or ((LD1 < 0) and (LD2 < 0)) then
    Exit(False);

  LPl1.FromLine(AVc, AVd);
  LPl2.FromRay(LAt, LDir);
  LD1 := LPl1.PermutedInnerProduct(LPl2);
  LPl2.FromRay(LBt, LDir);
  LD2 := LPl1.PermutedInnerProduct(LPl2);
  if ((LD1 > 0) and (LD2 > 0)) or ((LD1 < 0) and (LD2 < 0)) then
    Exit(False);

  // collision point on the edge at-bt
  LDir1 := (AVd - AVc).Cross(LDir);
  LD := LDir1.Dot(AVc);
  LD1 := LDir1.Dot(LAt) - LD;
  LD2 := LDir1.Dot(LBt) - LD;
  if LD1 = LD2 then
    Exit(False);
  ACollisionPoint := LAt + (LBt - LAt) * (LD1 / (LD1 - LD2));

  // normal is cross product of the rotated edge va-vb and the edge vc-vd
  ACollisionNormal := (LBt - LAt).Cross(AVd - AVc);

  Result := True;
end;

class function TCollisionRotationMath.RotateEdgeThroughEdge(ATraceWork: TCmTraceWork; const APl1: TGeoPluecker;
  const AVc, AVd: TGeoVec3; AMinTan: Single; var ATanHalfAngle: Single): Boolean;
var
  LV0: Double;
  LV1: Double;
  LV2: Double;
  LFrac1: Double;
  LFrac2: Double;
  LCt: TGeoVec3;
  LDt: TGeoVec3;
  LPl2: TGeoPluecker;
begin
  ATanHalfAngle := ATraceWork.MaxTan;

  // transform rotation axis to z-axis
  LCt := (AVc - ATraceWork.Origin) * ATraceWork.Matrix;
  LDt := (AVd - ATraceWork.Origin) * ATraceWork.Matrix;

  LPl2.FromLine(LCt, LDt);

  LV0 := LPl2.P[0] * APl1.P[4] + LPl2.P[4] * APl1.P[0];
  LV1 := LPl2.P[1] * APl1.P[2] - LPl2.P[2] * APl1.P[1] + LPl2.P[5] * APl1.P[3] - LPl2.P[3] * APl1.P[5];
  LV2 := LPl2.P[1] * APl1.P[5] + LPl2.P[2] * APl1.P[3] + LPl2.P[5] * APl1.P[1] + LPl2.P[3] * APl1.P[2];

  if not SolveHalfAngleTangents(LV0 - LV2, LV1, LV0 + LV2, LFrac1, LFrac2) then
    Exit(False);

  if ATraceWork.Angle < 0 then
  begin
    LFrac1 := -LFrac1;
    LFrac2 := -LFrac2;
  end;

  // get smallest tangent for which a collision occurs
  if (LFrac1 >= AMinTan) and (LFrac1 < ATanHalfAngle) then
    ATanHalfAngle := LFrac1;
  if (LFrac2 >= AMinTan) and (LFrac2 < ATanHalfAngle) then
    ATanHalfAngle := LFrac2;

  if ATraceWork.Angle < 0 then
    ATanHalfAngle := -ATanHalfAngle;

  Result := True;
end;

class function TCollisionRotationMath.EdgeFurthestFromEdge(ATraceWork: TCmTraceWork; const APl1: TGeoPluecker;
  const AVc, AVd: TGeoVec3; var ATanHalfAngle, ADir: Single): Boolean;
var
  LV0: Double;
  LV1: Double;
  LV2: Double;
  LC: Double;
  LFrac1: Double;
  LFrac2: Double;
  LCt: TGeoVec3;
  LDt: TGeoVec3;
  LPl2: TGeoPluecker;
begin
  ATanHalfAngle := 0;

  // transform rotation axis to z-axis
  LCt := (AVc - ATraceWork.Origin) * ATraceWork.Matrix;
  LDt := (AVd - ATraceWork.Origin) * ATraceWork.Matrix;

  LPl2.FromLine(LCt, LDt);

  LV0 := LPl2.P[0] * APl1.P[4] + LPl2.P[4] * APl1.P[0];
  LV1 := LPl2.P[1] * APl1.P[2] - LPl2.P[2] * APl1.P[1] + LPl2.P[5] * APl1.P[3] - LPl2.P[3] * APl1.P[5];
  LV2 := LPl2.P[1] * APl1.P[5] + LPl2.P[2] * APl1.P[3] + LPl2.P[5] * APl1.P[1] + LPl2.P[3] * APl1.P[2];

  // get the direction of motion at the initial position
  LC := LV0 + LV2;
  if ATraceWork.Angle > 0 then
  begin
    if LC > 0 then
      ADir := LV1
    else
      ADir := -LV1;
  end
  else
  begin
    if LC > 0 then
      ADir := -LV1
    else
      ADir := LV1;
  end;
  // negative direction means the edges move towards each other at the initial position
  if ADir <= 0 then
    Exit(True);

  if not SolveHalfAngleTangents(-LV1, -LV2, LV1, LFrac1, LFrac2) then
    Exit(False);

  if ATraceWork.Angle < 0 then
  begin
    LFrac1 := -LFrac1;
    LFrac2 := -LFrac2;
  end;

  if (LFrac1 < 0) and (LFrac2 < 0) then
    Exit(False);

  if LFrac1 > LFrac2 then
    ATanHalfAngle := LFrac1
  else
    ATanHalfAngle := LFrac2;

  if ATraceWork.Angle < 0 then
    ATanHalfAngle := -ATanHalfAngle;

  Result := True;
end;

class function TCollisionRotationMath.RotatePointThroughPlane(ATraceWork: TCmTraceWork; const APoint: TGeoVec3;
  const APlane: TGeoPlane; AAngle, AMinTan: Single; var ATanHalfAngle: Single): Boolean;
var
  LV0: Double;
  LV1: Double;
  LV2: Double;
  LD: Double;
  LFrac1: Double;
  LFrac2: Double;
  LP: TGeoVec3;
  LNormal: TGeoVec3;
begin
  ATanHalfAngle := ATraceWork.MaxTan;

  // transform rotation axis to z-axis
  LP := (APoint - ATraceWork.Origin) * ATraceWork.Matrix;
  // plane[3] of the original is the raw d of the plane equation, which is -Dist
  LD := APlane.D + APlane.Normal.Dot(ATraceWork.Origin);
  LNormal := APlane.Normal * ATraceWork.Matrix;

  LV0 := LNormal.Z * LP.Z + LD;
  LV1 := LNormal.X * LP.Y - LNormal.Y * LP.X;
  LV2 := LNormal.X * LP.X + LNormal.Y * LP.Y;

  if not SolveHalfAngleTangents(LV0 - LV2, LV1, LV0 + LV2, LFrac1, LFrac2) then
    Exit(False);

  if AAngle < 0 then
  begin
    LFrac1 := -LFrac1;
    LFrac2 := -LFrac2;
  end;

  // get smallest tangent for which a collision occurs
  if (LFrac1 >= AMinTan) and (LFrac1 < ATanHalfAngle) then
    ATanHalfAngle := LFrac1;
  if (LFrac2 >= AMinTan) and (LFrac2 < ATanHalfAngle) then
    ATanHalfAngle := LFrac2;

  if AAngle < 0 then
    ATanHalfAngle := -ATanHalfAngle;

  Result := True;
end;

class function TCollisionRotationMath.PointFurthestFromPlane(ATraceWork: TCmTraceWork; const APoint: TGeoVec3;
  const APlane: TGeoPlane; AAngle: Single; var ATanHalfAngle, ADir: Single): Boolean;
var
  LV1: Double;
  LV2: Double;
  LFrac1: Double;
  LFrac2: Double;
  LP: TGeoVec3;
  LNormal: TGeoVec3;
begin
  ATanHalfAngle := 0;

  // transform rotation axis to z-axis
  LP := (APoint - ATraceWork.Origin) * ATraceWork.Matrix;
  LNormal := APlane.Normal * ATraceWork.Matrix;

  LV1 := LNormal.X * LP.Y - LNormal.Y * LP.X;
  LV2 := LNormal.X * LP.X + LNormal.Y * LP.Y;

  // the point will always start at the front of the plane, therefore v0 + v2 > 0 is always true
  if AAngle < 0 then
    ADir := -LV1
  else
    ADir := LV1;
  // negative direction means the point moves towards the plane at the initial position
  if ADir <= 0 then
    Exit(True);

  if not SolveHalfAngleTangents(-LV1, -LV2, LV1, LFrac1, LFrac2) then
    Exit(False);

  if AAngle < 0 then
  begin
    LFrac1 := -LFrac1;
    LFrac2 := -LFrac2;
  end;

  if (LFrac1 < 0) and (LFrac2 < 0) then
    Exit(False);

  if LFrac1 > LFrac2 then
    ATanHalfAngle := LFrac1
  else
    ATanHalfAngle := LFrac2;

  if AAngle < 0 then
    ATanHalfAngle := -ATanHalfAngle;

  Result := True;
end;

class function TCollisionRotationMath.RotatePointThroughEpsilonPlane(ATraceWork: TCmTraceWork; const APoint,
  AEndPoint: TGeoVec3; const APlane: TGeoPlane; AAngle: Single; const AOrigin: TGeoVec3;
  var ATanHalfAngle: Single; out ACollisionPoint, AEndDir: TGeoVec3): Boolean;
var
  LD: Single;
  LDir: Single;
  LStartTan: Single;
  LVec: TGeoVec3;
  LStartDir: TGeoVec3;
  LEpsPlane: TGeoPlane;
begin
  ACollisionPoint.Zero;
  AEndDir.Zero;
  // epsilon expanded plane
  LEpsPlane := APlane;
  LEpsPlane.SetDist(LEpsPlane.Dist + CM_CLIP_EPSILON);

  // if the rotation sphere at the rotation origin is too far away from the polygon plane
  LD := LEpsPlane.Distance(AOrigin);
  LVec := APoint - AOrigin;
  if LD * LD > LVec.Dot(LVec) then
    Exit(False);

  // calculate direction of motion at vertex start position
  LStartDir := (APoint - AOrigin).Cross(ATraceWork.Axis);
  if AAngle < 0 then
    LStartDir := -LStartDir;
  // if moving away from plane at start position
  if LStartDir.Dot(LEpsPlane.Normal) >= 0 then
  begin
    // if end position is outside epsilon range
    LD := LEpsPlane.Distance(AEndPoint);
    if LD >= 0 then
      Exit(False); // no collision
    // calculate direction of motion at vertex end position
    AEndDir := (AEndPoint - AOrigin).Cross(ATraceWork.Axis);
    if AAngle < 0 then
      AEndDir := -AEndDir;
    // if also moving away from plane at end position
    if AEndDir.Dot(LEpsPlane.Normal) > 0 then
      Exit(False); // no collision
  end;

  // if the start position is in the epsilon range
  LD := LEpsPlane.Distance(APoint);
  if LD <= CM_PL_RANGE_EPSILON then
  begin
    // calculate tangent of half the rotation for which the vertex is furthest away from the plane
    if not PointFurthestFromPlane(ATraceWork, APoint, APlane, AAngle, LStartTan, LDir) then
      Exit(False);

    if LDir <= 0 then
      // moving towards the polygon plane so stop immediately
      ATanHalfAngle := 0
    else if Abs(LStartTan) >= ATraceWork.MaxTan then
      // never going to get beyond the start tangent during the current rotation
      Exit(False)
    else
    begin
      // calculate collision with epsilon expanded plane
      if not RotatePointThroughPlane(ATraceWork, APoint, LEpsPlane, AAngle, Abs(LStartTan), ATanHalfAngle) then
        ATanHalfAngle := LStartTan;
    end;
  end
  else
  begin
    // calculate collision with epsilon expanded plane
    if not RotatePointThroughPlane(ATraceWork, APoint, LEpsPlane, AAngle, 0, ATanHalfAngle) then
      Exit(False);
  end;

  // calculate collision point
  ACollisionPoint := APoint;
  if ATanHalfAngle <> 0 then
    RotatePoint(ACollisionPoint, ATraceWork.Origin, ATraceWork.Axis, ATanHalfAngle);
  // calculate direction of motion at collision point
  AEndDir := (ACollisionPoint - AOrigin).Cross(ATraceWork.Axis);
  if AAngle < 0 then
    AEndDir := -AEndDir;
  Result := True;
end;

end.
