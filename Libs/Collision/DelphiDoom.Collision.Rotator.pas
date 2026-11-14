{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - rotation of a trace model through the       }
{  polygons of a model                                                         }
{                                                                              }
{  Port of RotateTrmEdgeThroughPolygon, RotateTrmVertexThroughPolygon,         }
{  RotateVertexThroughTrmPolygon and RotateTrmThroughPolygon                   }
{  (CollisionModel_rotate.cpp), Doom 3 GPL Source Code. Copyright (C)          }
{  1999-2011 id Software LLC, a ZeniMax Media company. Based on the Doom 3     }
{  GPL Source Code (id Software). Doom 3 Source Code: GNU General Public      }
{  License version 3 with additional terms. This unit is a derived work        }
{  (GPL v3).                                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Rotator;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Collision.CheckCounter, DelphiDoom.Collision.TraceWork,
  DelphiDoom.Collision.Model.Types, DelphiDoom.Collision.Model.Polygon;

type
  /// <summary>
  ///   The collision tests of a rotating trace model against one polygon: the vertices and
  ///   the edges of the trace model are rotated through the polygon and the polygon vertices
  ///   are rotated through the polygons of the trace model. The first collision (the smallest
  ///   tangent of half the angle, ATraceWork.MaxTan) is kept in the trace work.
  /// </summary>
  TCollisionRotator = class
  private
    FCounter: TCollisionCheckCounter;
    procedure RotateTrmEdgeThroughPolygon(ATraceWork: TCmTraceWork; APolygon: TCmPolygon; ATrmEdgeIndex: Integer);
    procedure RotateTrmVertexThroughPolygon(ATraceWork: TCmTraceWork; APolygon: TCmPolygon; AVertexIndex: Integer);
    procedure RotateVertexThroughTrmPolygon(ATraceWork: TCmTraceWork; ATrmPolyIndex: Integer;
      APolygon: TCmPolygon; AVertex: PCmVertex; AVertexIndex: Integer; const ARotationOrigin: TGeoVec3);
  public
    constructor Create(ACounter: TCollisionCheckCounter);
    /// <summary>Returns true if the polygon blocks the complete rotation (RotateTrmThroughPolygon)</summary>
    function RotateTrmThroughPolygon(ATraceWork: TCmTraceWork; APolygon: TCmPolygon): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Types, DelphiDoom.Geometry.FloatMath, DelphiDoom.Geometry.Plane,
  DelphiDoom.Geometry.Pluecker, DelphiDoom.Geometry.Bounds, DelphiDoom.Collision.Types,
  DelphiDoom.Collision.Model, DelphiDoom.Collision.RotationMath, DelphiDoom.MathCore.Float.GeometryAdapter,
  DelphiDoom.IdLib.Math.Vec3;

{ TCollisionRotator }

constructor TCollisionRotator.Create(ACounter: TCollisionCheckCounter);
begin
  inherited Create;
  FCounter := ACounter;
end;

procedure TCollisionRotator.RotateTrmEdgeThroughPolygon(ATraceWork: TCmTraceWork; APolygon: TCmPolygon;
  ATrmEdgeIndex: Integer);
var
  LIndex: Integer;
  LAxis: Integer;
  LEdgeNum: Integer;
  LF1: Single;
  LF2: Single;
  LStartTan: Single;
  LDir: Single;
  LTanHalfAngle: Single;
  LEdge: PCmEdge;
  LV1: PCmVertex;
  LV2: PCmVertex;
  LTrmEdge: ^TCmTrmEdge;
  LModel: TCollisionModel;
  LCollisionPoint: TGeoVec3;
  LCollisionNormal: TGeoVec3;
  LOrigin: TGeoVec3;
  LEpsDir: TGeoVec3;
  LEpsPl: TGeoPluecker;
  LBounds: TGeoBounds;
begin
  LModel := ATraceWork.Model;
  LTrmEdge := @ATraceWork.Edges[ATrmEdgeIndex];

  // if the trm is convex and the rotation axis intersects the trm
  if ATraceWork.IsConvex and ATraceWork.AxisIntersectsTrm then
    // if both points are behind the polygon the edge cannot collide within a 180 degrees rotation
    if (ATraceWork.Vertices[LTrmEdge.VertexNum[0]].PolygonSide and
      ATraceWork.Vertices[LTrmEdge.VertexNum[1]].PolygonSide) <> 0 then
      Exit;

  // if the trace model edge rotation bounds do not intersect the polygon bounds
  if not LTrmEdge.RotationBounds.IntersectsBounds(APolygon.Bounds) then
    Exit;

  // edge rotation bounds should cross polygon plane
  if LTrmEdge.RotationBounds.PlaneSide(APolygon.Plane) <> PLANESIDE_CROSS then
    Exit;

  // check edges for a collision
  for LIndex := 0 to APolygon.NumEdges - 1 do
  begin
    LEdgeNum := APolygon.Edges[LIndex];
    LEdge := @LModel.Edges[Abs(LEdgeNum)];

    // if this edge is already checked
    if LEdge.CheckCount = FCounter.Value then
      Continue;

    // can never collide with internal edges
    if LEdge.Internal <> 0 then
      Continue;

    LV1 := @LModel.Vertices[LEdge.VertexNum[TGeoMath.IntSignBitSet(LEdgeNum)]];
    LV2 := @LModel.Vertices[LEdge.VertexNum[TGeoMath.IntSignBitNotSet(LEdgeNum)]];

    // edge bounds
    for LAxis := 0 to 2 do
      if LV1.P[LAxis] > LV2.P[LAxis] then
      begin
        LBounds.Mins[LAxis] := LV2.P[LAxis];
        LBounds.Maxs[LAxis] := LV1.P[LAxis];
      end
      else
      begin
        LBounds.Mins[LAxis] := LV1.P[LAxis];
        LBounds.Maxs[LAxis] := LV2.P[LAxis];
      end;

    // if the trace model edge rotation bounds do not intersect the polygon edge bounds
    if not LTrmEdge.RotationBounds.IntersectsBounds(LBounds) then
      Continue;

    LF1 := LTrmEdge.Pl.PermutedInnerProduct(ATraceWork.PolygonEdgePlueckerCache[LIndex]);

    // pluecker coordinate for epsilon expanded edge
    LEpsDir := LEdge.Normal * (CM_CLIP_EPSILON + CM_PL_RANGE_EPSILON);
    LEpsPl.FromLine(LModel.Vertices[LEdge.VertexNum[0]].P + LEpsDir,
      LModel.Vertices[LEdge.VertexNum[1]].P + LEpsDir);

    LF2 := LTrmEdge.Pl.PermutedInnerProduct(LEpsPl);

    // if the rotating edge is inbetween the polygon edge and the epsilon expanded edge
    if ((LF1 < 0) and (LF2 > 0)) or ((LF1 > 0) and (LF2 < 0)) then
    begin
      if not TCollisionRotationMath.EdgeFurthestFromEdge(ATraceWork, LTrmEdge.PlZAxis, LV1.P, LV2.P,
        LStartTan, LDir) then
        Continue;

      if LDir <= 0 then
        // moving towards the polygon edge so stop immediately
        LTanHalfAngle := 0
      else if TGeoMath.Fabs(LStartTan) >= ATraceWork.MaxTan then
        // never going to get beyond the start tangent during the current rotation
        Continue
      else
      begin
        // collide with the epsilon expanded edge
        if not TCollisionRotationMath.RotateEdgeThroughEdge(ATraceWork, LTrmEdge.PlZAxis, LV1.P + LEpsDir,
          LV2.P + LEpsDir, TGeoMath.Fabs(LStartTan), LTanHalfAngle) then
          LTanHalfAngle := LStartTan;
      end;
    end
    else
    begin
      // collide with the epsilon expanded edge
      LEpsDir := LEdge.Normal * CM_CLIP_EPSILON;
      if not TCollisionRotationMath.RotateEdgeThroughEdge(ATraceWork, LTrmEdge.PlZAxis, LV1.P + LEpsDir,
        LV2.P + LEpsDir, 0, LTanHalfAngle) then
        Continue;
    end;

    if TGeoMath.Fabs(LTanHalfAngle) >= ATraceWork.MaxTan then
      Continue;

    // check if the collision is between the edge bounds
    if not TCollisionRotationMath.CollisionBetweenEdgeBounds(ATraceWork, LTrmEdge.Start, LTrmEdge.EndPoint,
      LV1.P, LV2.P, LTanHalfAngle, LCollisionPoint, LCollisionNormal) then
      Continue;

    // allow rotation if the rotation axis goes through the collisionPoint
    LOrigin := ATraceWork.Origin + ATraceWork.Axis * ATraceWork.Axis.Dot(LCollisionPoint - ATraceWork.Origin);
    if (LCollisionPoint - LOrigin).LengthSqr < RotationAxisEpsilon * RotationAxisEpsilon then
      Continue;

    // fill in trace structure
    ATraceWork.MaxTan := TGeoMath.Fabs(LTanHalfAngle);
    ATraceWork.Trace.C.Normal := LCollisionNormal;
    ATraceWork.Trace.C.Normal.NormalizeSelf;
    ATraceWork.Trace.C.Dist := ATraceWork.Trace.C.Normal.Dot(LV1.P);
    // make sure the collision plane faces the trace model
    if ATraceWork.Trace.C.Normal.Dot(LTrmEdge.Start) - ATraceWork.Trace.C.Dist < 0 then
    begin
      ATraceWork.Trace.C.Normal := -ATraceWork.Trace.C.Normal;
      ATraceWork.Trace.C.Dist := -ATraceWork.Trace.C.Dist;
    end;
    ATraceWork.Trace.C.Contents := APolygon.Contents;
    ATraceWork.Trace.C.Material := APolygon.Material;
    ATraceWork.Trace.C.ContactType := ctEdge;
    ATraceWork.Trace.C.ModelFeature := LEdgeNum;
    ATraceWork.Trace.C.TrmFeature := ATrmEdgeIndex;
    ATraceWork.Trace.C.Point := LCollisionPoint;
    // if no collision can be closer
    if ATraceWork.MaxTan = 0 then
      Break;
  end;
end;

procedure TCollisionRotator.RotateTrmVertexThroughPolygon(ATraceWork: TCmTraceWork; APolygon: TCmPolygon;
  AVertexIndex: Integer);
var
  LIndex: Integer;
  LTanHalfAngle: Single;
  LEndDir: TGeoVec3;
  LCollisionPoint: TGeoVec3;
  LPl: TGeoPluecker;
  LVertex: ^TCmTrmVertex;
begin
  LVertex := @ATraceWork.Vertices[AVertexIndex];

  // if the trm vertex is behind the polygon plane it cannot collide with the polygon within a 180 degrees rotation
  if ATraceWork.IsConvex and ATraceWork.AxisIntersectsTrm and (LVertex.PolygonSide <> 0) then
    Exit;

  // if the trace model vertex rotation bounds do not intersect the polygon bounds
  if not LVertex.RotationBounds.IntersectsBounds(APolygon.Bounds) then
    Exit;

  // vertex rotation bounds should cross polygon plane
  if LVertex.RotationBounds.PlaneSide(APolygon.Plane) <> PLANESIDE_CROSS then
    Exit;

  // rotate the vertex through the epsilon plane
  if not TCollisionRotationMath.RotatePointThroughEpsilonPlane(ATraceWork, LVertex.P, LVertex.EndP,
    APolygon.Plane, ATraceWork.Angle, LVertex.RotationOrigin, LTanHalfAngle, LCollisionPoint, LEndDir) then
    Exit;

  if TGeoMath.Fabs(LTanHalfAngle) < ATraceWork.MaxTan then
  begin
    // verify if 'collisionPoint' moving along 'endDir' moves between polygon edges
    LPl.FromRay(LCollisionPoint, LEndDir);
    for LIndex := 0 to APolygon.NumEdges - 1 do
    begin
      if APolygon.Edges[LIndex] < 0 then
      begin
        if LPl.PermutedInnerProduct(ATraceWork.PolygonEdgePlueckerCache[LIndex]) > 0 then
          Exit;
      end
      else
      begin
        if LPl.PermutedInnerProduct(ATraceWork.PolygonEdgePlueckerCache[LIndex]) < 0 then
          Exit;
      end;
    end;
    ATraceWork.MaxTan := TGeoMath.Fabs(LTanHalfAngle);
    // collision plane is the polygon plane
    ATraceWork.Trace.C.Normal := APolygon.Plane.Normal;
    ATraceWork.Trace.C.Dist := APolygon.Plane.Dist;
    ATraceWork.Trace.C.Contents := APolygon.Contents;
    ATraceWork.Trace.C.Material := APolygon.Material;
    ATraceWork.Trace.C.ContactType := ctTrmVertex;
    ATraceWork.Trace.C.ModelFeature := APolygon.Id;
    ATraceWork.Trace.C.TrmFeature := AVertexIndex;
    ATraceWork.Trace.C.Point := LCollisionPoint;
  end;
end;

procedure TCollisionRotator.RotateVertexThroughTrmPolygon(ATraceWork: TCmTraceWork; ATrmPolyIndex: Integer;
  APolygon: TCmPolygon; AVertex: PCmVertex; AVertexIndex: Integer; const ARotationOrigin: TGeoVec3);
var
  LIndex: Integer;
  LEdgeNum: Integer;
  LTanHalfAngle: Single;
  LDir: TGeoVec3;
  LEndP: TGeoVec3;
  LEndDir: TGeoVec3;
  LCollisionPoint: TGeoVec3;
  LPl: TGeoPluecker;
  LEdge: ^TCmTrmEdge;
  LTrmPoly: ^TCmTrmPolygon;
  LIdPoint: TIdVec3;
begin
  LTrmPoly := @ATraceWork.Polys[ATrmPolyIndex];

  // if the polygon vertex is behind the trm plane it cannot collide with the trm polygon within a 180 degrees rotation
  if ATraceWork.IsConvex and ATraceWork.AxisIntersectsTrm and (LTrmPoly.Plane.Distance(AVertex.P) < 0) then
    Exit;

  // if the model vertex is outside the trm polygon rotation bounds
  if not LTrmPoly.RotationBounds.ContainsPoint(AVertex.P) then
    Exit;

  // if the rotation axis goes through the polygon vertex
  LDir := AVertex.P - ARotationOrigin;
  if LDir.Dot(LDir) < RotationAxisEpsilon * RotationAxisEpsilon then
    Exit;

  // calculate vertex end position
  LIdPoint := TIdGeometryAdapter.ToId(AVertex.P);
  ATraceWork.ModelVertexRotation.RotatePoint(LIdPoint);
  LEndP := TIdGeometryAdapter.ToGeo(LIdPoint);

  // rotate the vertex through the epsilon plane
  if not TCollisionRotationMath.RotatePointThroughEpsilonPlane(ATraceWork, AVertex.P, LEndP, LTrmPoly.Plane,
    -ATraceWork.Angle, ARotationOrigin, LTanHalfAngle, LCollisionPoint, LEndDir) then
    Exit;

  if TGeoMath.Fabs(LTanHalfAngle) < ATraceWork.MaxTan then
  begin
    // verify if 'collisionPoint' moving along 'endDir' moves between polygon edges
    LPl.FromRay(LCollisionPoint, LEndDir);
    for LIndex := 0 to LTrmPoly.NumEdges - 1 do
    begin
      LEdgeNum := LTrmPoly.Edges[LIndex];
      LEdge := @ATraceWork.Edges[Abs(LEdgeNum)];
      if LEdgeNum < 0 then
      begin
        if LPl.PermutedInnerProduct(LEdge.Pl) > 0 then
          Exit;
      end
      else
      begin
        if LPl.PermutedInnerProduct(LEdge.Pl) < 0 then
          Exit;
      end;
    end;
    ATraceWork.MaxTan := TGeoMath.Fabs(LTanHalfAngle);
    // collision plane is the flipped trm polygon plane
    ATraceWork.Trace.C.Normal := -LTrmPoly.Plane.Normal;
    ATraceWork.Trace.C.Dist := ATraceWork.Trace.C.Normal.Dot(AVertex.P);
    ATraceWork.Trace.C.Contents := APolygon.Contents;
    ATraceWork.Trace.C.Material := APolygon.Material;
    ATraceWork.Trace.C.ContactType := ctModelVertex;
    ATraceWork.Trace.C.ModelFeature := AVertexIndex;
    ATraceWork.Trace.C.TrmFeature := ATrmPolyIndex;
    ATraceWork.Trace.C.Point := AVertex.P;
  end;
end;

function TCollisionRotator.RotateTrmThroughPolygon(ATraceWork: TCmTraceWork; APolygon: TCmPolygon): Boolean;
var
  LIndex: Integer;
  LJ: Integer;
  LK: Integer;
  LEdgeNum: Integer;
  LDist: Single;
  LVertex: PCmVertex;
  LEdge: PCmEdge;
  LModel: TCollisionModel;
  LRotationOrigin: TGeoVec3;
begin
  // if already checked this polygon
  if APolygon.CheckCount = FCounter.Value then
    Exit(False);
  APolygon.CheckCount := FCounter.Value;

  // if this polygon does not have the right contents behind it
  if (APolygon.Contents and ATraceWork.Contents) = 0 then
    Exit(False);

  // if the the trace bounds do not intersect the polygon bounds
  if not ATraceWork.Bounds.IntersectsBounds(APolygon.Bounds) then
    Exit(False);

  LModel := ATraceWork.Model;

  // back face culling
  if ATraceWork.IsConvex then
    // if the center of the convex trm is behind the polygon plane
    if APolygon.Plane.Distance(ATraceWork.Start) < 0 then
      // if the rotation axis intersects the trace model
      if ATraceWork.AxisIntersectsTrm then
        Exit(False);

  // if the polygon is too far from the first heart plane
  LDist := APolygon.Bounds.PlaneDistance(ATraceWork.HeartPlane1);
  if TGeoMath.Fabs(LDist) > ATraceWork.MaxDistFromHeartPlane1 then
    Exit(False);

  // rotation bounds should cross polygon plane
  case ATraceWork.Bounds.PlaneSide(APolygon.Plane) of
    PLANESIDE_CROSS:
      ;
    PLANESIDE_FRONT:
      begin
        if LModel.IsConvex then
        begin
          ATraceWork.QuickExit := True;
          Exit(True);
        end;
        Exit(False);
      end;
  else
    Exit(False);
  end;

  for LIndex := 0 to ATraceWork.NumVerts - 1 do
  begin
    // calculate polygon side this vertex is on
    LDist := APolygon.Plane.Distance(ATraceWork.Vertices[LIndex].P);
    ATraceWork.Vertices[LIndex].PolygonSide := TGeoMath.FloatSignBitSet(LDist);
  end;

  for LIndex := 0 to APolygon.NumEdges - 1 do
  begin
    LEdgeNum := APolygon.Edges[LIndex];
    LEdge := @LModel.Edges[Abs(LEdgeNum)];
    LVertex := @LModel.Vertices[LEdge.VertexNum[TGeoMath.IntSignBitSet(LEdgeNum)]];

    // pluecker coordinate for edge
    ATraceWork.PolygonEdgePlueckerCache[LIndex].FromLine(LModel.Vertices[LEdge.VertexNum[0]].P,
      LModel.Vertices[LEdge.VertexNum[1]].P);

    // calculate rotation origin projected into rotation plane through the vertex
    ATraceWork.PolygonRotationOriginCache[LIndex] := ATraceWork.Origin +
      ATraceWork.Axis * ATraceWork.Axis.Dot(LVertex.P - ATraceWork.Origin);
  end;
  // copy first to last so we can easily cycle through
  ATraceWork.PolygonRotationOriginCache[APolygon.NumEdges] := ATraceWork.PolygonRotationOriginCache[0];

  // fast point rotation
  if ATraceWork.PointTrace then
    RotateTrmVertexThroughPolygon(ATraceWork, APolygon, 0)
  else
  begin
    // rotate trm vertices through polygon
    for LIndex := 0 to ATraceWork.NumVerts - 1 do
      if ATraceWork.Vertices[LIndex].Used then
        RotateTrmVertexThroughPolygon(ATraceWork, APolygon, LIndex);

    // rotate trm edges through polygon
    for LIndex := 1 to ATraceWork.NumEdges do
      if ATraceWork.Edges[LIndex].Used then
        RotateTrmEdgeThroughPolygon(ATraceWork, APolygon, LIndex);

    // rotate all polygon vertices through the trm
    for LIndex := 0 to APolygon.NumEdges - 1 do
    begin
      LEdgeNum := APolygon.Edges[LIndex];
      LEdge := @LModel.Edges[Abs(LEdgeNum)];

      if LEdge.CheckCount = FCounter.Value then
        Continue;
      // set edge check count
      LEdge.CheckCount := FCounter.Value;
      // can never collide with internal edges
      if LEdge.Internal <> 0 then
        Continue;
      // got to check both vertices because we skip internal edges
      for LK := 0 to 1 do
      begin
        LVertex := @LModel.Vertices[LEdge.VertexNum[LK xor Integer(TGeoMath.IntSignBitSet(LEdgeNum))]];

        // if this vertex is already checked
        if LVertex.CheckCount = FCounter.Value then
          Continue;
        // set vertex check count
        LVertex.CheckCount := FCounter.Value;

        // if the vertex is outside the trm rotation bounds
        if not ATraceWork.Bounds.ContainsPoint(LVertex.P) then
          Continue;

        LRotationOrigin := ATraceWork.PolygonRotationOriginCache[LIndex + LK];

        for LJ := 0 to ATraceWork.NumPolys - 1 do
          if ATraceWork.Polys[LJ].Used then
            RotateVertexThroughTrmPolygon(ATraceWork, LJ, APolygon, LVertex,
              LEdge.VertexNum[LK xor Integer(TGeoMath.IntSignBitSet(LEdgeNum))], LRotationOrigin);
      end;
    end;
  end;

  Result := ATraceWork.MaxTan = 0;
end;

end.
