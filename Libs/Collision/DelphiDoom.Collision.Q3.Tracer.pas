{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  tracing                                                                     }
{                                                                              }
{  Port of CM_TraceThroughPatch, CM_TraceThroughBrush, CM_TraceThroughLeaf,    }
{  CM_TraceThroughTree, CM_Trace, CM_BoxTrace and CM_TransformedBoxTrace of    }
{  cm_trace.c from the Quake III Arena GPL Source Code (id Software).          }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.Tracer;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.ClipMap, DelphiDoom.Collision.Q3.PositionTester;

type
  /// <summary>
  ///   Sweeps a box (or a capsule) through the model. Where the C mixes float and double (the
  ///   0.125 epsilon is a double, 1.0/x is a double division) the same intermediate results
  ///   are made with Double, so that the answers are the ones of the C code compiled for SSE.
  ///   Not ported: the capsule against a capsule model (CM_TraceCapsuleThroughCapsule,
  ///   CM_TraceBoundingBoxThroughCapsule, CM_TestCapsuleInCapsule, CM_TestBoundingBoxInCapsule
  ///   and the sphere and cylinder functions under them): the original cannot reach them,
  ///   because CM_ClipHandleToModel raises the error for the capsule handle (see the README).
  /// </summary>
  TQ3Tracer = class
  strict private
    FMap: TQ3ClipMap;
    FPositionTester: TQ3PositionTester;
    procedure TraceThroughPatch(var AWork: TQ3TraceWork; const ASurface: Integer);
    procedure TraceThroughBrush(var AWork: TQ3TraceWork; const ABrush: PQ3Brush);
    procedure TraceThroughLeaf(var AWork: TQ3TraceWork; const ALeaf: PQ3Leaf);
    procedure TraceThroughTree(var AWork: TQ3TraceWork; ANum: Integer; const AP1F, AP2F: Single;
      const AP1, AP2: TQ3Vec3);
    function Trace(const AStart, AEnd, AMins, AMaxs: TQ3Vec3; const AModel: Integer; const AOrigin: TQ3Vec3;
      const ABrushMask: Integer; const ACapsule: Boolean; const ASphere: PQ3Sphere): TQ3Trace;
  public
    constructor Create(const AMap: TQ3ClipMap; const APositionTester: TQ3PositionTester);
    /// <summary>CM_BoxTrace</summary>
    function BoxTrace(const AStart, AEnd, AMins, AMaxs: TQ3Vec3; const AModel, ABrushMask: Integer;
      const ACapsule: Boolean): TQ3Trace;
    /// <summary>CM_TransformedBoxTrace: offsetting and rotation for moving and rotating entities</summary>
    function TransformedBoxTrace(const AStart, AEnd, AMins, AMaxs: TQ3Vec3; const AModel, ABrushMask: Integer;
      const AOrigin, AAngles: TQ3Vec3; const ACapsule: Boolean): TQ3Trace;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Math;

constructor TQ3Tracer.Create(const AMap: TQ3ClipMap; const APositionTester: TQ3PositionTester);
begin
  inherited Create;
  FMap := AMap;
  FPositionTester := APositionTester;
end;

procedure TQ3Tracer.TraceThroughPatch(var AWork: TQ3TraceWork; const ASurface: Integer);
var
  LOldFraction: Single;
begin
  Inc(FMap.PatchTraceCount);

  LOldFraction := AWork.Trace.Fraction;

  if Assigned(FMap.PatchCollides[ASurface]) then
    FMap.PatchCollides[ASurface].TraceThrough(AWork);

  if AWork.Trace.Fraction < LOldFraction then
  begin
    AWork.Trace.SurfaceFlags := FMap.Patches[ASurface].SurfaceFlags;
    AWork.Trace.Contents := FMap.Patches[ASurface].Contents;
  end;
end;

procedure TQ3Tracer.TraceThroughBrush(var AWork: TQ3TraceWork; const ABrush: PQ3Brush);
var
  LIndex: Integer;
  LPlane, LClipPlane: PQ3Plane;
  LSide, LLeadSide: PQ3BrushSide;
  LDist, LEnterFrac, LLeaveFrac, LD1, LD2, LFraction, LProduct: Single;
  LGetOut, LStartOut: Boolean;
  LStartPoint, LEndPoint: TQ3Vec3;
  LDiff: Double;
begin
  LEnterFrac := -1.0;
  LLeaveFrac := 1.0;
  LClipPlane := nil;

  if ABrush^.NumSides = 0 then
    Exit;

  Inc(FMap.BrushTraceCount);

  LGetOut := False;
  LStartOut := False;
  LLeadSide := nil;

  // compare the trace against all planes of the brush: find the latest time the trace crosses
  // a plane towards the interior and the earliest time it crosses a plane towards the exterior
  for LIndex := 0 to ABrush^.NumSides - 1 do
  begin
    LSide := @FMap.BrushSides[ABrush^.FirstSide + LIndex];
    LPlane := @FMap.Planes[LSide^.PlaneNum];

    if AWork.Sphere.Use then
    begin
      // adjust the plane distance apropriately for radius
      LDist := LPlane^.Dist + AWork.Sphere.Radius;

      // find the closest point on the capsule to the plane
      LProduct := TQ3Math.Dot(LPlane^.Normal, AWork.Sphere.Offset);
      if LProduct > 0 then
      begin
        LStartPoint[0] := AWork.Start[0] - AWork.Sphere.Offset[0];
        LStartPoint[1] := AWork.Start[1] - AWork.Sphere.Offset[1];
        LStartPoint[2] := AWork.Start[2] - AWork.Sphere.Offset[2];
        LEndPoint[0] := AWork.EndPoint[0] - AWork.Sphere.Offset[0];
        LEndPoint[1] := AWork.EndPoint[1] - AWork.Sphere.Offset[1];
        LEndPoint[2] := AWork.EndPoint[2] - AWork.Sphere.Offset[2];
      end
      else
      begin
        LStartPoint[0] := AWork.Start[0] + AWork.Sphere.Offset[0];
        LStartPoint[1] := AWork.Start[1] + AWork.Sphere.Offset[1];
        LStartPoint[2] := AWork.Start[2] + AWork.Sphere.Offset[2];
        LEndPoint[0] := AWork.EndPoint[0] + AWork.Sphere.Offset[0];
        LEndPoint[1] := AWork.EndPoint[1] + AWork.Sphere.Offset[1];
        LEndPoint[2] := AWork.EndPoint[2] + AWork.Sphere.Offset[2];
      end;

      LD1 := TQ3Math.Dot(LStartPoint, LPlane^.Normal);
      LD1 := LD1 - LDist;
      LD2 := TQ3Math.Dot(LEndPoint, LPlane^.Normal);
      LD2 := LD2 - LDist;
    end
    else
    begin
      // adjust the plane distance apropriately for mins/maxs
      LProduct := TQ3Math.Dot(AWork.Offsets[LPlane^.SignBits], LPlane^.Normal);
      LDist := LPlane^.Dist - LProduct;

      LD1 := TQ3Math.Dot(AWork.Start, LPlane^.Normal);
      LD1 := LD1 - LDist;
      LD2 := TQ3Math.Dot(AWork.EndPoint, LPlane^.Normal);
      LD2 := LD2 - LDist;
    end;

    if LD2 > 0 then
      LGetOut := True; // endpoint is not in solid
    if LD1 > 0 then
      LStartOut := True;

    // if completely in front of face, no intersection with the entire brush
    if (LD1 > 0) and ((LD2 >= Q3_SURFACE_CLIP_EPSILON) or (LD2 >= LD1)) then
      Exit;

    // if it doesn't cross the plane, the plane isn't relevent
    if (LD1 <= 0) and (LD2 <= 0) then
      Continue;

    // crosses face
    LDiff := Single(LD1 - LD2);
    if LD1 > LD2 then
    begin
      // enter: the epsilon is a double, so the division is made with doubles
      LFraction := (Double(LD1) - Q3_SURFACE_CLIP_EPSILON) / LDiff;
      if LFraction < 0 then
        LFraction := 0;
      if LFraction > LEnterFrac then
      begin
        LEnterFrac := LFraction;
        LClipPlane := LPlane;
        LLeadSide := LSide;
      end;
    end
    else
    begin
      // leave
      LFraction := (Double(LD1) + Q3_SURFACE_CLIP_EPSILON) / LDiff;
      if LFraction > 1 then
        LFraction := 1;
      if LFraction < LLeaveFrac then
        LLeaveFrac := LFraction;
    end;
  end;

  // all planes have been checked, and the trace was not completely outside the brush
  if not LStartOut then
  begin
    // original point was inside brush
    AWork.Trace.StartSolid := True;
    if not LGetOut then
    begin
      AWork.Trace.AllSolid := True;
      AWork.Trace.Fraction := 0;
      AWork.Trace.Contents := ABrush^.Contents;
    end;
    Exit;
  end;

  if LEnterFrac < LLeaveFrac then
    if (LEnterFrac > -1) and (LEnterFrac < AWork.Trace.Fraction) then
    begin
      if LEnterFrac < 0 then
        LEnterFrac := 0;
      AWork.Trace.Fraction := LEnterFrac;
      AWork.Trace.Plane := LClipPlane^;
      AWork.Trace.SurfaceFlags := LLeadSide^.SurfaceFlags;
      AWork.Trace.Contents := ABrush^.Contents;
    end;
end;

procedure TQ3Tracer.TraceThroughLeaf(var AWork: TQ3TraceWork; const ALeaf: PQ3Leaf);
var
  LK, LBrushNum, LSurface: Integer;
  LBrush: PQ3Brush;
  LPatch: PQ3Patch;
begin
  // trace line against all brushes in the leaf
  for LK := 0 to ALeaf^.NumLeafBrushes - 1 do
  begin
    LBrushNum := FMap.LeafBrushes[ALeaf^.FirstLeafBrush + LK];

    LBrush := @FMap.Brushes[LBrushNum];
    if LBrush^.CheckCount = FMap.CheckCount then
      Continue; // already checked this brush in another leaf
    LBrush^.CheckCount := FMap.CheckCount;

    if (LBrush^.Contents and AWork.Contents) = 0 then
      Continue;

    TraceThroughBrush(AWork, LBrush);
    if AWork.Trace.Fraction = 0 then
      Exit;
  end;

  // trace line against all patches in the leaf
  if not FMap.NoCurves then
    for LK := 0 to ALeaf^.NumLeafSurfaces - 1 do
    begin
      LSurface := FMap.LeafSurfaces[ALeaf^.FirstLeafSurface + LK];
      LPatch := @FMap.Patches[LSurface];
      if not LPatch^.Present then
        Continue;
      if LPatch^.CheckCount = FMap.CheckCount then
        Continue; // already checked this patch in another leaf
      LPatch^.CheckCount := FMap.CheckCount;

      if (LPatch^.Contents and AWork.Contents) = 0 then
        Continue;

      TraceThroughPatch(AWork, LSurface);
      if AWork.Trace.Fraction = 0 then
        Exit;
    end;
end;

procedure TQ3Tracer.TraceThroughTree(var AWork: TQ3TraceWork; ANum: Integer; const AP1F, AP2F: Single;
  const AP1, AP2: TQ3Vec3);
var
  LNode: PQ3Node;
  LPlane: PQ3Plane;
  LT1, LT2, LOffset, LFrac, LFrac2, LIDist, LMidF, LSum: Single;
  LMid: TQ3Vec3;
  LSide: Integer;
  LTemp: Double;
begin
  if AWork.Trace.Fraction <= AP1F then
    Exit; // already hit something nearer

  // if < 0, we are in a leaf node
  if ANum < 0 then
  begin
    TraceThroughLeaf(AWork, @FMap.Leafs[-1 - ANum]);
    Exit;
  end;

  // find the point distances to the seperating plane and the offset for the size of the box
  LNode := @FMap.Nodes[ANum];
  LPlane := @FMap.Planes[LNode^.PlaneNum];

  // adjust the plane distance apropriately for mins/maxs
  if LPlane^.PlaneType < 3 then
  begin
    LT1 := AP1[LPlane^.PlaneType] - LPlane^.Dist;
    LT2 := AP2[LPlane^.PlaneType] - LPlane^.Dist;
    LOffset := AWork.Extents[LPlane^.PlaneType];
  end
  else
  begin
    LT1 := TQ3Math.Dot(LPlane^.Normal, AP1);
    LT1 := LT1 - LPlane^.Dist;
    LT2 := TQ3Math.Dot(LPlane^.Normal, AP2);
    LT2 := LT2 - LPlane^.Dist;
    if AWork.IsPoint then
      LOffset := 0
    else
      LOffset := 2048; // this is silly
  end;

  // see which sides we need to consider
  LSum := LOffset + 1;
  if (LT1 >= LSum) and (LT2 >= LSum) then
  begin
    TraceThroughTree(AWork, LNode^.Children[0], AP1F, AP2F, AP1, AP2);
    Exit;
  end;
  LSum := -LOffset - 1;
  if (LT1 < LSum) and (LT2 < LSum) then
  begin
    TraceThroughTree(AWork, LNode^.Children[1], AP1F, AP2F, AP1, AP2);
    Exit;
  end;

  // put the crosspoint SURFACE_CLIP_EPSILON pixels on the near side
  if LT1 < LT2 then
  begin
    LSum := LT1 - LT2;
    LIDist := 1.0 / Double(LSum);
    LSide := 1;
    LSum := LT1 + LOffset;
    LTemp := Double(LSum) + Q3_SURFACE_CLIP_EPSILON;
    LFrac2 := LTemp * Double(LIDist);
    LSum := LT1 - LOffset;
    LTemp := Double(LSum) + Q3_SURFACE_CLIP_EPSILON;
    LFrac := LTemp * Double(LIDist);
  end
  else if LT1 > LT2 then
  begin
    LSum := LT1 - LT2;
    LIDist := 1.0 / Double(LSum);
    LSide := 0;
    LSum := LT1 - LOffset;
    LTemp := Double(LSum) - Q3_SURFACE_CLIP_EPSILON;
    LFrac2 := LTemp * Double(LIDist);
    LSum := LT1 + LOffset;
    LTemp := Double(LSum) + Q3_SURFACE_CLIP_EPSILON;
    LFrac := LTemp * Double(LIDist);
  end
  else
  begin
    LSide := 0;
    LFrac := 1;
    LFrac2 := 0;
  end;

  // move up to the node
  if LFrac < 0 then
    LFrac := 0;
  if LFrac > 1 then
    LFrac := 1;

  LSum := AP2F - AP1F;
  LSum := LSum * LFrac;
  LMidF := AP1F + LSum;

  LSum := AP2[0] - AP1[0];
  LSum := LFrac * LSum;
  LMid[0] := AP1[0] + LSum;
  LSum := AP2[1] - AP1[1];
  LSum := LFrac * LSum;
  LMid[1] := AP1[1] + LSum;
  LSum := AP2[2] - AP1[2];
  LSum := LFrac * LSum;
  LMid[2] := AP1[2] + LSum;

  TraceThroughTree(AWork, LNode^.Children[LSide], AP1F, LMidF, AP1, LMid);

  // go past the node
  if LFrac2 < 0 then
    LFrac2 := 0;
  if LFrac2 > 1 then
    LFrac2 := 1;

  LSum := AP2F - AP1F;
  LSum := LSum * LFrac2;
  LMidF := AP1F + LSum;

  LSum := AP2[0] - AP1[0];
  LSum := LFrac2 * LSum;
  LMid[0] := AP1[0] + LSum;
  LSum := AP2[1] - AP1[1];
  LSum := LFrac2 * LSum;
  LMid[1] := AP1[1] + LSum;
  LSum := AP2[2] - AP1[2];
  LSum := LFrac2 * LSum;
  LMid[2] := AP1[2] + LSum;

  TraceThroughTree(AWork, LNode^.Children[LSide xor 1], LMidF, AP2F, LMid, AP2);
end;

function TQ3Tracer.Trace(const AStart, AEnd, AMins, AMaxs: TQ3Vec3; const AModel: Integer;
  const AOrigin: TQ3Vec3; const ABrushMask: Integer; const ACapsule: Boolean;
  const ASphere: PQ3Sphere): TQ3Trace;
var
  LWork: TQ3TraceWork;
  LModel: PQ3Model;
  LOffset: TQ3Vec3;
  LIndex: Integer;
  LSum: Single;
  LTemp: Double;
begin
  LModel := FMap.ClipHandleToModel(AModel);

  Inc(FMap.CheckCount); // for multi-check avoidance
  Inc(FMap.TraceCount); // for statistics, may be zeroed

  // fill in a default trace
  FillChar(LWork, SizeOf(LWork), 0);
  LWork.Trace.Fraction := 1; // assume it goes the entire distance until shown otherwise
  LWork.ModelOrigin := AOrigin;

  if FMap.NumNodes = 0 then
    Exit(LWork.Trace); // map not loaded, shouldn't happen

  // set basic parms
  LWork.Contents := ABrushMask;

  // adjust so that mins and maxs are always symetric, which avoids some complications with
  // plane expanding of rotated bmodels
  for LIndex := 0 to 2 do
  begin
    LSum := AMins[LIndex] + AMaxs[LIndex];
    LOffset[LIndex] := Double(LSum) * 0.5;
    LWork.Size[0][LIndex] := AMins[LIndex] - LOffset[LIndex];
    LWork.Size[1][LIndex] := AMaxs[LIndex] - LOffset[LIndex];
    LWork.Start[LIndex] := AStart[LIndex] + LOffset[LIndex];
    LWork.EndPoint[LIndex] := AEnd[LIndex] + LOffset[LIndex];
  end;

  // if a sphere is already specified
  if Assigned(ASphere) then
    LWork.Sphere := ASphere^
  else
  begin
    LWork.Sphere.Use := ACapsule;
    if LWork.Size[1][0] > LWork.Size[1][2] then
      LWork.Sphere.Radius := LWork.Size[1][2]
    else
      LWork.Sphere.Radius := LWork.Size[1][0];
    LWork.Sphere.HalfHeight := LWork.Size[1][2];
    LWork.Sphere.Offset[0] := 0;
    LWork.Sphere.Offset[1] := 0;
    LWork.Sphere.Offset[2] := LWork.Size[1][2] - LWork.Sphere.Radius;
  end;

  LSum := LWork.Size[1][0] + LWork.Size[1][1];
  LWork.MaxOffset := LSum + LWork.Size[1][2];

  // tw.offsets[signbits] = vector to apropriate corner from origin
  for LIndex := 0 to 7 do
  begin
    LWork.Offsets[LIndex][0] := LWork.Size[LIndex and 1][0];
    LWork.Offsets[LIndex][1] := LWork.Size[(LIndex shr 1) and 1][1];
    LWork.Offsets[LIndex][2] := LWork.Size[(LIndex shr 2) and 1][2];
  end;

  // calculate bounds
  for LIndex := 0 to 2 do
    if LWork.Sphere.Use then
    begin
      // fabs() returns a double, so the sums are double
      if LWork.Start[LIndex] < LWork.EndPoint[LIndex] then
      begin
        LTemp := Double(LWork.Start[LIndex]) - Double(Abs(LWork.Sphere.Offset[LIndex]));
        LWork.Bounds[0][LIndex] := LTemp - Double(LWork.Sphere.Radius);
        LTemp := Double(LWork.EndPoint[LIndex]) + Double(Abs(LWork.Sphere.Offset[LIndex]));
        LWork.Bounds[1][LIndex] := LTemp + Double(LWork.Sphere.Radius);
      end
      else
      begin
        LTemp := Double(LWork.EndPoint[LIndex]) - Double(Abs(LWork.Sphere.Offset[LIndex]));
        LWork.Bounds[0][LIndex] := LTemp - Double(LWork.Sphere.Radius);
        LTemp := Double(LWork.Start[LIndex]) + Double(Abs(LWork.Sphere.Offset[LIndex]));
        LWork.Bounds[1][LIndex] := LTemp + Double(LWork.Sphere.Radius);
      end;
    end
    else if LWork.Start[LIndex] < LWork.EndPoint[LIndex] then
    begin
      LWork.Bounds[0][LIndex] := LWork.Start[LIndex] + LWork.Size[0][LIndex];
      LWork.Bounds[1][LIndex] := LWork.EndPoint[LIndex] + LWork.Size[1][LIndex];
    end
    else
    begin
      LWork.Bounds[0][LIndex] := LWork.EndPoint[LIndex] + LWork.Size[0][LIndex];
      LWork.Bounds[1][LIndex] := LWork.Start[LIndex] + LWork.Size[1][LIndex];
    end;

  // check for position test special case
  if (AStart[0] = AEnd[0]) and (AStart[1] = AEnd[1]) and (AStart[2] = AEnd[2]) then
  begin
    if AModel <> 0 then
      FPositionTester.TestInLeaf(LWork, @LModel^.Leaf)
    else
      FPositionTester.PositionTest(LWork);
  end
  else
  begin
    // check for point special case
    if (LWork.Size[0][0] = 0) and (LWork.Size[0][1] = 0) and (LWork.Size[0][2] = 0) then
    begin
      LWork.IsPoint := True;
      LWork.Extents[0] := 0;
      LWork.Extents[1] := 0;
      LWork.Extents[2] := 0;
    end
    else
    begin
      LWork.IsPoint := False;
      LWork.Extents[0] := LWork.Size[1][0];
      LWork.Extents[1] := LWork.Size[1][1];
      LWork.Extents[2] := LWork.Size[1][2];
    end;

    // general sweeping through world
    if AModel <> 0 then
      TraceThroughLeaf(LWork, @LModel^.Leaf)
    else
      TraceThroughTree(LWork, 0, 0, 1, LWork.Start, LWork.EndPoint);
  end;

  // generate endpos from the original, unmodified start/end
  if LWork.Trace.Fraction = 1 then
    LWork.Trace.EndPos := AEnd
  else
    for LIndex := 0 to 2 do
    begin
      LSum := AEnd[LIndex] - AStart[LIndex];
      LSum := LWork.Trace.Fraction * LSum;
      LWork.Trace.EndPos[LIndex] := AStart[LIndex] + LSum;
    end;

  Result := LWork.Trace;
end;

function TQ3Tracer.BoxTrace(const AStart, AEnd, AMins, AMaxs: TQ3Vec3; const AModel, ABrushMask: Integer;
  const ACapsule: Boolean): TQ3Trace;
const
  ORIGIN: TQ3Vec3 = (0, 0, 0);
begin
  Result := Trace(AStart, AEnd, AMins, AMaxs, AModel, ORIGIN, ABrushMask, ACapsule, nil);
end;

function TQ3Tracer.TransformedBoxTrace(const AStart, AEnd, AMins, AMaxs: TQ3Vec3; const AModel,
  ABrushMask: Integer; const AOrigin, AAngles: TQ3Vec3; const ACapsule: Boolean): TQ3Trace;
var
  LStartLocal, LEndLocal, LOffset: TQ3Vec3;
  LSymmetricSize: array[0..1] of TQ3Vec3;
  LMatrix, LTranspose: TQ3Mat3;
  LSphere: TQ3Sphere;
  LRotated: Boolean;
  LIndex: Integer;
  LHalfWidth, LHalfHeight, LT, LSum: Single;
begin
  // adjust so that mins and maxs are always symetric, which avoids some complications with
  // plane expanding of rotated bmodels
  for LIndex := 0 to 2 do
  begin
    LSum := AMins[LIndex] + AMaxs[LIndex];
    LOffset[LIndex] := Double(LSum) * 0.5;
    LSymmetricSize[0][LIndex] := AMins[LIndex] - LOffset[LIndex];
    LSymmetricSize[1][LIndex] := AMaxs[LIndex] - LOffset[LIndex];
    LStartLocal[LIndex] := AStart[LIndex] + LOffset[LIndex];
    LEndLocal[LIndex] := AEnd[LIndex] + LOffset[LIndex];
  end;

  // subtract origin offset
  for LIndex := 0 to 2 do
  begin
    LStartLocal[LIndex] := LStartLocal[LIndex] - AOrigin[LIndex];
    LEndLocal[LIndex] := LEndLocal[LIndex] - AOrigin[LIndex];
  end;

  // rotate start and end into the models frame of reference
  LRotated := (AModel <> Q3_BOX_MODEL_HANDLE) and ((AAngles[0] <> 0) or (AAngles[1] <> 0) or (AAngles[2] <> 0));

  LHalfWidth := LSymmetricSize[1][0];
  LHalfHeight := LSymmetricSize[1][2];

  LSphere.Use := ACapsule;
  if LHalfWidth > LHalfHeight then
    LSphere.Radius := LHalfHeight
  else
    LSphere.Radius := LHalfWidth;
  LSphere.HalfHeight := LHalfHeight;
  LT := LHalfHeight - LSphere.Radius;

  if LRotated then
  begin
    // rotation on trace line (start-end) instead of rotating the bmodel; this is still incorrect
    // for bounding boxes (the box that is swept is not rotated), but right for capsules
    TQ3Math.CreateRotationMatrix(AAngles, LMatrix);
    TQ3Math.RotatePoint(LStartLocal, LMatrix);
    TQ3Math.RotatePoint(LEndLocal, LMatrix);
    // rotated sphere offset for capsule
    LSphere.Offset[0] := LMatrix[0][2] * LT;
    LSphere.Offset[1] := -LMatrix[1][2] * LT;
    LSphere.Offset[2] := LMatrix[2][2] * LT;
  end
  else
  begin
    LSphere.Offset[0] := 0;
    LSphere.Offset[1] := 0;
    LSphere.Offset[2] := LT;
  end;

  // sweep the box through the model
  Result := Trace(LStartLocal, LEndLocal, LSymmetricSize[0], LSymmetricSize[1], AModel, AOrigin, ABrushMask,
    ACapsule, @LSphere);

  // if the bmodel was rotated and there was a collision
  if LRotated and (Result.Fraction <> 1.0) then
  begin
    // rotation of bmodel collision plane
    TQ3Math.TransposeMatrix(LMatrix, LTranspose);
    TQ3Math.RotatePoint(Result.Plane.Normal, LTranspose);
  end;

  // re-calculate the end position of the trace because the trace.endpos calculated by CM_Trace
  // could be rotated and have an offset
  for LIndex := 0 to 2 do
  begin
    LSum := AEnd[LIndex] - AStart[LIndex];
    LSum := Result.Fraction * LSum;
    Result.EndPos[LIndex] := AStart[LIndex] + LSum;
  end;
end;

end.
