{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the rotation of a trace model               }
{                                                                              }
{  Port of idCollisionModelManagerLocal::BoundsForRotation, Rotation180 and    }
{  Rotation (CollisionModel_rotate.cpp), Doom 3 GPL Source Code. Copyright     }
{  (C) 1999-2011 id Software LLC, a ZeniMax Media company. Based on the Doom 3 }
{  GPL Source Code (id Software). Doom 3 Source Code: GNU General Public      }
{  License version 3 with additional terms. This unit is a derived work        }
{  (GPL v3).                                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.RotationRunner;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3, DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Pluecker,
  DelphiDoom.Geometry.TraceModel, DelphiDoom.MathCore.Float.Rotation, DelphiDoom.Collision.Types, DelphiDoom.Collision.CheckCounter,
  DelphiDoom.Collision.Model, DelphiDoom.Collision.Tracer, DelphiDoom.Collision.ContentsRunner;

type
  /// <summary>
  ///   Rotates a trace model (or a point) about an axis through a model and finds the first
  ///   collision. Rotations of 180 degrees or more are split into steps below 180.
  /// </summary>
  TCollisionRotationRunner = class
  private
    FCounter: TCollisionCheckCounter;
    FTracer: TCollisionTracer;
    FContentsRunner: TCollisionContentsRunner;
    procedure Rotation180(var AResults: TCollisionTrace; const ARotationOrigin, AAxis: TGeoVec3;
      AStartAngle, AEndAngle: Single; const AStart: TGeoVec3; ATrm: TTraceModel; const ATrmAxis: TGeoMat3;
      AContentMask: Integer; AModel: TCollisionModel; const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3);
  public
    /// <summary>Nothing is owned; the tracer must have been given a rotator</summary>
    constructor Create(ACounter: TCollisionCheckCounter; ATracer: TCollisionTracer;
      AContentsRunner: TCollisionContentsRunner);
    /// <summary>
    ///   BoundsForRotation: the bounds of the arc of a point about an axis, only for rotations
    ///   below 180 degrees, enlarged by CM_BOX_EPSILON
    /// </summary>
    class function BoundsForRotation(const AOrigin, AAxis, AStart, AEnd: TGeoVec3): TGeoBounds; static;
    /// <summary>
    ///   Rotation: rotates a trm (nil for a point) from AStart by ARotation and reports the first
    ///   collision. A rotation by angle 0 is a position test
    /// </summary>
    procedure Rotate(var AResults: TCollisionTrace; const AStart: TGeoVec3; var ARotation: TIdRotation;
      ATrm: TTraceModel; const ATrmAxis: TGeoMat3; AContentMask: Integer; AModel: TCollisionModel;
      const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3);
  end;

implementation

uses
  System.SysUtils, System.Math, DelphiDoom.Geometry.FloatMath, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.MathCore.Float.GeometryAdapter, DelphiDoom.Collision.TraceWork, DelphiDoom.Collision.RotationMath;

const
  /// <summary>idMath::PI as the float of the original</summary>
  FLOAT_PI: Single = 3.14159265358979323846;

/// <summary>rotation.RotatePoint on geometry vectors</summary>
procedure RotatePointBy(var ARotation: TIdRotation; var APoint: TGeoVec3); inline;
var
  LPoint: TIdVec3;
begin
  LPoint := TIdGeometryAdapter.ToId(APoint);
  ARotation.RotatePoint(LPoint);
  APoint := TIdGeometryAdapter.ToGeo(LPoint);
end;

function MakeRotation(const AOrigin, AAxis: TGeoVec3; AAngle: Single): TIdRotation; inline;
begin
  Result := TIdRotation.Create(TIdGeometryAdapter.ToId(AOrigin), TIdGeometryAdapter.ToId(AAxis), AAngle);
end;

{ TCollisionRotationRunner }

constructor TCollisionRotationRunner.Create(ACounter: TCollisionCheckCounter; ATracer: TCollisionTracer;
  AContentsRunner: TCollisionContentsRunner);
begin
  inherited Create;
  FCounter := ACounter;
  FTracer := ATracer;
  FContentsRunner := AContentsRunner;
end;

class function TCollisionRotationRunner.BoundsForRotation(const AOrigin, AAxis, AStart,
  AEnd: TGeoVec3): TGeoBounds;
var
  LIndex: Integer;
  LRadiusSqr: Single;
  LV1: TGeoVec3;
  LV2: TGeoVec3;
begin
  Result.Clear;
  LRadiusSqr := (AStart - AOrigin).LengthSqr;
  LV1 := (AStart - AOrigin).Cross(AAxis);
  LV2 := (AEnd - AOrigin).Cross(AAxis);

  for LIndex := 0 to 2 do
  begin
    // if the derivative changes sign along this axis during the rotation from start to end
    if ((LV1[LIndex] > 0) and (LV2[LIndex] < 0)) or ((LV1[LIndex] < 0) and (LV2[LIndex] > 0)) then
    begin
      if (0.5 * (AStart[LIndex] + AEnd[LIndex]) - AOrigin[LIndex]) > 0 then
      begin
        Result.Mins[LIndex] := Min(AStart[LIndex], AEnd[LIndex]);
        Result.Maxs[LIndex] := AOrigin[LIndex] + TGeoMath.Sqrt(LRadiusSqr * (1.0 - AAxis[LIndex] * AAxis[LIndex]));
      end
      else
      begin
        Result.Mins[LIndex] := AOrigin[LIndex] - TGeoMath.Sqrt(LRadiusSqr * (1.0 - AAxis[LIndex] * AAxis[LIndex]));
        Result.Maxs[LIndex] := Max(AStart[LIndex], AEnd[LIndex]);
      end;
    end
    else if AStart[LIndex] > AEnd[LIndex] then
    begin
      Result.Mins[LIndex] := AEnd[LIndex];
      Result.Maxs[LIndex] := AStart[LIndex];
    end
    else
    begin
      Result.Mins[LIndex] := AStart[LIndex];
      Result.Maxs[LIndex] := AEnd[LIndex];
    end;
    // expand for epsilons
    Result.Mins[LIndex] := Result.Mins[LIndex] - CM_BOX_EPSILON;
    Result.Maxs[LIndex] := Result.Maxs[LIndex] + CM_BOX_EPSILON;
  end;
end;

procedure TCollisionRotationRunner.Rotation180(var AResults: TCollisionTrace; const ARotationOrigin,
  AAxis: TGeoVec3; AStartAngle, AEndAngle: Single; const AStart: TGeoVec3; ATrm: TTraceModel;
  const ATrmAxis: TGeoMat3; AContentMask: Integer; AModel: TCollisionModel; const AModelOrigin: TGeoVec3;
  const AModelAxis: TGeoMat3);
var
  LTw: TCmTraceWork;
  LIndex: Integer;
  LJ: Integer;
  LAxis: Integer;
  LEdgeNum: Integer;
  LDist: Single;
  LMaxErr: Single;
  LInitialTan: Single;
  LModelRotated: Boolean;
  LTrmRotated: Boolean;
  LInvModelAxis: TGeoMat3;
  LTmpAxis: TGeoMat3;
  LStartRotation: TIdRotation;
  LEndRotation: TIdRotation;
  LVr: TGeoVec3;
  LVup: TGeoVec3;
  LAt: TGeoVec3;
  LBt: TGeoVec3;
  LPlAxis: TGeoPluecker;
  LEdge: ^TCmTrmEdge;
  LPoly: ^TCmTrmPolygon;
  LVert: ^TCmTrmVertex;
  LRadiusSquare: Single;
begin
  FCounter.Next;

  LTw := TCmTraceWork.Create;
  try
    LTw.Trace.Fraction := 1;
    LTw.Trace.C.Contents := 0;
    LTw.Trace.C.ContactType := ctNone;
    LTw.Contents := AContentMask;
    LTw.IsConvex := True;
    LTw.Rotation := True;
    LTw.PositionTest := False;
    LTw.AxisIntersectsTrm := False;
    LTw.QuickExit := False;
    LTw.Angle := AEndAngle - AStartAngle;
    LInitialTan := TGeoMath.Fabs(Tan((FLOAT_PI / 360.0) * LTw.Angle));
    LTw.MaxTan := LInitialTan;
    LTw.Model := AModel;
    LTw.Start := AStart - AModelOrigin;
    // rotation axis, axis is assumed to be normalized
    LTw.Axis := AAxis;
    // rotation origin projected into rotation plane through tw.start
    LTw.Origin := ARotationOrigin - AModelOrigin;
    LDist := LTw.Axis.Dot(LTw.Origin) - LTw.Axis.Dot(LTw.Start);
    LTw.Origin := LTw.Origin - LTw.Axis * LDist;
    // radius of rotation
    LTw.Radius := (LTw.Start - LTw.Origin).Length;
    // maximum error of the circle approximation traced through the axial BSP tree
    LRadiusSquare := CIRCLE_APPROXIMATION_LENGTH * CIRCLE_APPROXIMATION_LENGTH * 0.25;
    LDist := LTw.Radius * LTw.Radius - LRadiusSquare;
    if LDist > 0 then
      LMaxErr := LTw.Radius - TGeoMath.Sqrt(LDist)
    else
      LMaxErr := LTw.Radius;

    LModelRotated := AModelAxis.IsRotated;
    if LModelRotated then
    begin
      LInvModelAxis := AModelAxis.Transpose;
      LTw.Axis := LTw.Axis * LInvModelAxis;
      LTw.Origin := LTw.Origin * LInvModelAxis;
    end;

    LStartRotation := MakeRotation(LTw.Origin, LTw.Axis, AStartAngle);
    LEndRotation := MakeRotation(LTw.Origin, LTw.Axis, AEndAngle);

    // create matrix which rotates the rotation axis to the z-axis
    LTw.Axis.NormalVectors(LVr, LVup);
    LTw.Matrix.Rows[0][0] := LVr[0];
    LTw.Matrix.Rows[1][0] := LVr[1];
    LTw.Matrix.Rows[2][0] := LVr[2];
    LTw.Matrix.Rows[0][1] := -LVup[0];
    LTw.Matrix.Rows[1][1] := -LVup[1];
    LTw.Matrix.Rows[2][1] := -LVup[2];
    LTw.Matrix.Rows[0][2] := LTw.Axis[0];
    LTw.Matrix.Rows[1][2] := LTw.Axis[1];
    LTw.Matrix.Rows[2][2] := LTw.Axis[2];

    // if optimized point trace
    if (not Assigned(ATrm)) or ((ATrm.Bounds.Maxs[0] - ATrm.Bounds.Mins[0] <= 0) and
      (ATrm.Bounds.Maxs[1] - ATrm.Bounds.Mins[1] <= 0) and (ATrm.Bounds.Maxs[2] - ATrm.Bounds.Mins[2] <= 0)) then
    begin
      if LModelRotated then
        // rotate trace instead of model
        LTw.Start := LTw.Start * LInvModelAxis;
      LTw.EndPoint := LTw.Start;
      // if we start at a specific angle
      if AStartAngle <> 0 then
        RotatePointBy(LStartRotation, LTw.Start);
      // calculate end position of rotation
      RotatePointBy(LEndRotation, LTw.EndPoint);

      // calculate rotation origin projected into rotation plane through the vertex
      LTw.NumVerts := 1;
      LTw.Vertices[0].P := LTw.Start;
      LTw.Vertices[0].EndP := LTw.EndPoint;
      LTw.Vertices[0].Used := True;
      LTw.Vertices[0].RotationOrigin := LTw.Origin + LTw.Axis * LTw.Axis.Dot(LTw.Vertices[0].P - LTw.Origin);
      LTw.Vertices[0].RotationBounds := BoundsForRotation(LTw.Vertices[0].RotationOrigin, LTw.Axis, LTw.Start,
        LTw.EndPoint);
      // rotation bounds
      LTw.Bounds := LTw.Vertices[0].RotationBounds;
      LTw.NumEdges := 0;
      LTw.NumPolys := 0;

      // collision with single point
      LTw.PointTrace := True;

      // extents is set to maximum error of the circle approximation traced through the axial BSP tree
      LTw.Extents.SetValues(LMaxErr + CM_BOX_EPSILON, LMaxErr + CM_BOX_EPSILON, LMaxErr + CM_BOX_EPSILON);

      // setup rotation heart plane
      LTw.HeartPlane1.SetNormal(LTw.Axis);
      LTw.HeartPlane1.FitThroughPoint(LTw.Start);
      LTw.MaxDistFromHeartPlane1 := CM_BOX_EPSILON;

      // trace through the model
      FTracer.TraceThroughModel(LTw);

      // store results
      AResults := LTw.Trace;
      AResults.EndPos := AStart;
      if LTw.MaxTan = LInitialTan then
        AResults.Fraction := 1
      else
        AResults.Fraction := TGeoMath.Fabs(ArcTan(LTw.MaxTan) * (2.0 * 180.0 / FLOAT_PI) / LTw.Angle);
      LEndRotation := MakeRotation(ARotationOrigin, AAxis,
        AStartAngle + (AEndAngle - AStartAngle) * AResults.Fraction);
      RotatePointBy(LEndRotation, AResults.EndPos);
      AResults.EndAxis := TGeoMat3.Identity;

      if AResults.Fraction < 1 then
      begin
        // rotate trace plane normal if there was a collision with a rotated model
        if LModelRotated then
        begin
          AResults.C.Normal := AResults.C.Normal * AModelAxis;
          AResults.C.Point := AResults.C.Point * AModelAxis;
        end;
        AResults.C.Point := AResults.C.Point + AModelOrigin;
        AResults.C.Dist := AResults.C.Dist + AModelOrigin.Dot(AResults.C.Normal);
      end;
      Exit;
    end;

    LTw.PointTrace := False;

    // setup trm structure
    LTw.SetupTrm(ATrm);

    LTrmRotated := ATrmAxis.IsRotated;

    // calculate vertex positions
    if LTrmRotated then
      for LIndex := 0 to LTw.NumVerts - 1 do
        // rotate trm around the start position
        LTw.Vertices[LIndex].P := LTw.Vertices[LIndex].P * ATrmAxis;
    for LIndex := 0 to LTw.NumVerts - 1 do
      // set trm at start position
      LTw.Vertices[LIndex].P := LTw.Vertices[LIndex].P + LTw.Start;
    if LModelRotated then
      for LIndex := 0 to LTw.NumVerts - 1 do
        LTw.Vertices[LIndex].P := LTw.Vertices[LIndex].P * LInvModelAxis;
    for LIndex := 0 to LTw.NumVerts - 1 do
      LTw.Vertices[LIndex].EndP := LTw.Vertices[LIndex].P;
    // if we start at a specific angle
    if AStartAngle <> 0 then
      for LIndex := 0 to LTw.NumVerts - 1 do
        RotatePointBy(LStartRotation, LTw.Vertices[LIndex].P);
    for LIndex := 0 to LTw.NumVerts - 1 do
      // end position of vertex
      RotatePointBy(LEndRotation, LTw.Vertices[LIndex].EndP);

    // add offset to start point
    if LTrmRotated then
      LTw.Start := LTw.Start + ATrm.Offset * ATrmAxis
    else
      LTw.Start := LTw.Start + ATrm.Offset;
    // if the model is rotated
    if LModelRotated then
      // rotate trace instead of model
      LTw.Start := LTw.Start * LInvModelAxis;
    LTw.EndPoint := LTw.Start;
    // if we start at a specific angle
    if AStartAngle <> 0 then
      RotatePointBy(LStartRotation, LTw.Start);
    // calculate end position of rotation
    RotatePointBy(LEndRotation, LTw.EndPoint);

    // setup trm vertices
    for LIndex := 0 to LTw.NumVerts - 1 do
    begin
      LVert := @LTw.Vertices[LIndex];
      // calculate rotation origin projected into rotation plane through the vertex
      LVert.RotationOrigin := LTw.Origin + LTw.Axis * LTw.Axis.Dot(LVert.P - LTw.Origin);
      // calculate rotation bounds for this vertex
      LVert.RotationBounds := BoundsForRotation(LVert.RotationOrigin, LTw.Axis, LVert.P, LVert.EndP);
      // if the rotation axis goes through the vertex then the vertex is not used
      LDist := (LVert.P - LVert.RotationOrigin).LengthSqr;
      if LDist > RotationAxisEpsilon * RotationAxisEpsilon then
        LVert.Used := True;
    end;

    // setup trm edges
    for LIndex := 1 to LTw.NumEdges do
    begin
      LEdge := @LTw.Edges[LIndex];
      // if the rotation axis goes through both the edge vertices then the edge is not used
      if LTw.Vertices[LEdge.VertexNum[0]].Used or LTw.Vertices[LEdge.VertexNum[1]].Used then
        LEdge.Used := True;
      // edge start, end and pluecker coordinate
      LEdge.Start := LTw.Vertices[LEdge.VertexNum[0]].P;
      LEdge.EndPoint := LTw.Vertices[LEdge.VertexNum[1]].P;
      LEdge.Pl.FromLine(LEdge.Start, LEdge.EndPoint);
      // pluecker coordinate for edge being rotated about the z-axis
      LAt := (LEdge.Start - LTw.Origin) * LTw.Matrix;
      LBt := (LEdge.EndPoint - LTw.Origin) * LTw.Matrix;
      LEdge.PlZAxis.FromLine(LAt, LBt);
      // get edge rotation bounds from the rotation bounds of both vertices
      LEdge.RotationBounds := LTw.Vertices[LEdge.VertexNum[0]].RotationBounds;
      LEdge.RotationBounds.AddBounds(LTw.Vertices[LEdge.VertexNum[1]].RotationBounds);
      // used to calculate if the rotation axis intersects the trm
      LEdge.BitNum := 0;
    end;

    LTw.Bounds.Clear;

    // rotate trm polygon planes
    if LTrmRotated and LModelRotated then
    begin
      LTmpAxis := ATrmAxis * LInvModelAxis;
      for LIndex := 0 to LTw.NumPolys - 1 do
        LTw.Polys[LIndex].Plane.RotateNormal(LTmpAxis);
    end
    else if LTrmRotated then
    begin
      for LIndex := 0 to LTw.NumPolys - 1 do
        LTw.Polys[LIndex].Plane.RotateNormal(ATrmAxis);
    end
    else if LModelRotated then
    begin
      for LIndex := 0 to LTw.NumPolys - 1 do
        LTw.Polys[LIndex].Plane.RotateNormal(LInvModelAxis);
    end;

    // setup trm polygons
    for LIndex := 0 to LTw.NumPolys - 1 do
    begin
      LPoly := @LTw.Polys[LIndex];
      LPoly.Used := True;
      // set trm polygon plane distance
      LPoly.Plane.FitThroughPoint(LTw.Edges[Abs(LPoly.Edges[0])].Start);
      // get polygon bounds from edge bounds
      LPoly.RotationBounds.Clear;
      for LJ := 0 to LPoly.NumEdges - 1 do
      begin
        // add edge rotation bounds to polygon rotation bounds
        LEdge := @LTw.Edges[Abs(LPoly.Edges[LJ])];
        LPoly.RotationBounds.AddBounds(LEdge.RotationBounds);
      end;
      // get trace bounds from polygon bounds
      LTw.Bounds.AddBounds(LPoly.RotationBounds);
    end;

    // extents including the maximum error of the circle approximation traced through the axial BSP tree
    for LAxis := 0 to 2 do
    begin
      LTw.Size.Mins[LAxis] := LTw.Bounds.Mins[LAxis] - LTw.Start[LAxis];
      LTw.Size.Maxs[LAxis] := LTw.Bounds.Maxs[LAxis] - LTw.Start[LAxis];
      if TGeoMath.Fabs(LTw.Size.Mins[LAxis]) > TGeoMath.Fabs(LTw.Size.Maxs[LAxis]) then
        LTw.Extents[LAxis] := TGeoMath.Fabs(LTw.Size.Mins[LAxis]) + LMaxErr + CM_BOX_EPSILON
      else
        LTw.Extents[LAxis] := TGeoMath.Fabs(LTw.Size.Maxs[LAxis]) + LMaxErr + CM_BOX_EPSILON;
    end;

    // for back-face culling
    if LTw.IsConvex then
    begin
      if LTw.Start.Compare(LTw.Origin) then
        LTw.AxisIntersectsTrm := True
      else
      begin
        // determine if the rotation axis intersects the trm
        LPlAxis.FromRay(LTw.Origin, LTw.Axis);
        for LIndex := 0 to LTw.NumPolys - 1 do
        begin
          LPoly := @LTw.Polys[LIndex];
          // back face cull polygons
          if LPoly.Plane.Normal.Dot(LTw.Axis) > 0 then
            Continue;
          // test if the axis goes between the polygon edges
          LJ := 0;
          while LJ < LPoly.NumEdges do
          begin
            LEdgeNum := LPoly.Edges[LJ];
            LEdge := @LTw.Edges[Abs(LEdgeNum)];
            if (LEdge.BitNum and 2) = 0 then
            begin
              LDist := LPlAxis.PermutedInnerProduct(LEdge.Pl);
              LEdge.BitNum := TGeoMath.FloatSignBitSet(LDist) or 2;
            end;
            if ((LEdge.BitNum xor TGeoMath.IntSignBitSet(LEdgeNum)) and 1) <> 0 then
              Break;
            Inc(LJ);
          end;
          if LJ >= LPoly.NumEdges then
          begin
            LTw.AxisIntersectsTrm := True;
            Break;
          end;
        end;
      end;
    end;

    // setup rotation heart plane
    LTw.HeartPlane1.SetNormal(LTw.Axis);
    LTw.HeartPlane1.FitThroughPoint(LTw.Start);
    LTw.MaxDistFromHeartPlane1 := 0;
    for LIndex := 0 to LTw.NumVerts - 1 do
    begin
      LDist := TGeoMath.Fabs(LTw.HeartPlane1.Distance(LTw.Vertices[LIndex].P));
      if LDist > LTw.MaxDistFromHeartPlane1 then
        LTw.MaxDistFromHeartPlane1 := LDist;
    end;
    LTw.MaxDistFromHeartPlane1 := LTw.MaxDistFromHeartPlane1 + CM_BOX_EPSILON;

    // inverse rotation to rotate model vertices towards trace model
    LTw.ModelVertexRotation := MakeRotation(LTw.Origin, LTw.Axis, -LTw.Angle);

    // trace through the model
    FTracer.TraceThroughModel(LTw);

    // store results
    AResults := LTw.Trace;
    AResults.EndPos := AStart;
    if LTw.MaxTan = LInitialTan then
      AResults.Fraction := 1
    else
      AResults.Fraction := TGeoMath.Fabs(ArcTan(LTw.MaxTan) * (2.0 * 180.0 / FLOAT_PI) / LTw.Angle);
    LEndRotation := MakeRotation(ARotationOrigin, AAxis, AStartAngle + (AEndAngle - AStartAngle) * AResults.Fraction);
    RotatePointBy(LEndRotation, AResults.EndPos);
    AResults.EndAxis := ATrmAxis * TIdGeometryAdapter.ToGeo(LEndRotation.ToMat3);

    if AResults.Fraction < 1 then
    begin
      // rotate trace plane normal if there was a collision with a rotated model
      if LModelRotated then
      begin
        AResults.C.Normal := AResults.C.Normal * AModelAxis;
        AResults.C.Point := AResults.C.Point * AModelAxis;
      end;
      AResults.C.Point := AResults.C.Point + AModelOrigin;
      AResults.C.Dist := AResults.C.Dist + AModelOrigin.Dot(AResults.C.Normal);
    end;
  finally
    LTw.Free;
  end;
end;

procedure TCollisionRotationRunner.Rotate(var AResults: TCollisionTrace; const AStart: TGeoVec3;
  var ARotation: TIdRotation; ATrm: TTraceModel; const ATrmAxis: TGeoMat3; AContentMask: Integer;
  AModel: TCollisionModel; const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3);
var
  LMaxAngle: Single;
  LStepAngle: Single;
  LAngle: Single;
  LLastAngle: Single;
  LOrigin: TGeoVec3;
  LVector: TGeoVec3;
begin
  AResults := Default(TCollisionTrace);

  // if special position test
  if ARotation.Angle = 0 then
  begin
    FContentsRunner.ContentsTrm(AResults, AStart, ATrm, ATrmAxis, AContentMask, AModel, AModelOrigin, AModelAxis);
    Exit;
  end;

  LOrigin := TIdGeometryAdapter.ToGeo(ARotation.Origin);
  LVector := TIdGeometryAdapter.ToGeo(ARotation.Vector);

  if (ARotation.Angle >= 180) or (ARotation.Angle <= -180) then
  begin
    if ARotation.Angle >= 360 then
    begin
      LMaxAngle := 360;
      // three steps strictly < 180 degrees
      LStepAngle := 120;
    end
    else if ARotation.Angle <= -360 then
    begin
      LMaxAngle := -360;
      LStepAngle := -120;
    end
    else
    begin
      LMaxAngle := ARotation.Angle;
      // two steps strictly < 180 degrees
      LStepAngle := ARotation.Angle * 0.5;
    end;
    LLastAngle := 0;
    LAngle := LStepAngle;
    while Abs(LAngle) < Abs(LMaxAngle) + 1.0 do
    begin
      // partial rotation
      Rotation180(AResults, LOrigin, LVector, LLastAngle, LAngle, AStart, ATrm, ATrmAxis, AContentMask, AModel,
        AModelOrigin, AModelAxis);
      // if there is a collision
      if AResults.Fraction < 1 then
      begin
        // fraction of total rotation
        AResults.Fraction := (LLastAngle + LStepAngle * AResults.Fraction) / ARotation.Angle;
        Exit;
      end;
      LLastAngle := LAngle;
      LAngle := LAngle + LStepAngle;
    end;
    AResults.Fraction := 1;
    Exit;
  end;

  Rotation180(AResults, LOrigin, LVector, 0, ARotation.Angle, AStart, ATrm, ATrmAxis, AContentMask, AModel,
    AModelOrigin, AModelAxis);
end;

end.
