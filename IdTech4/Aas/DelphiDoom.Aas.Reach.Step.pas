{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - step, barrier jump, water jump and walk off       }
{  ledge reachabilities of two areas                                           }
{                                                                              }
{  Port of AAS_Reachability_Step_Barrier_WaterJump_WalkOffLedge of             }
{  be_aas_reach.c. Based on the Quake III Arena GPL Source Code (id Software). }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Step;

{$Q-}
{$R+}

interface

uses
  DelphiDoom.Aas.Reach.Part;

type
  /// <summary>
  ///   The reachabilities between areas that touch: the closest ground edges of the two areas decide if the second area is
  ///   a step up, a water jump or a barrier jump up, a walk down or a walk off a ledge
  /// </summary>
  TAasReachStep = class(TAasReachPart)
  public
    /// <summary>
    ///   AAS_Reachability_Step_Barrier_WaterJump_WalkOffLedge: True if a reachability from the first area to the second was
    ///   made
    /// </summary>
    function Calculate(const AArea1, AArea2: Integer): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.VectorMath, DelphiDoom.Aas.Reach.Types,
  DelphiDoom.Aas.Reach.Vectors;

const
  // the literals of the C code that are doubles
  CPointSeven: Double = 0.7;
  CTenth: Double = 0.1;
  CHalf: Double = 0.5;

type
  /// <summary>The best edge pair so far for the ground faces or for the water faces of the first area</summary>
  TBestEdge = record
    Found: Boolean;
    Distance: Single;
    Length: Single;
    EdgeNum: Integer;
    Start: TVec3;
    EndPoint: TVec3;
    Normal: TVec3;
  end;

{ TAasReachStep }

function TAasReachStep.Calculate(const AArea1, AArea2: Integer): Boolean;
var
  LIndex, LK, LJ, LL, LEdge1Num, LEdge2Num, LSide1, LFaceSide1, LGroundFace1Num, LNumAreas: Integer;
  LArea1Swim: Boolean;
  LDist, LDist1, LDist2, LDiff, LInvGravityDot, LOrtDot, LLength, LLimit, LTmp, LY: Single;
  LX1, LX2, LX3, LX4, LY1, LY2, LY3, LY4: Single;
  LV1, LV2, LV3, LV4, LTmpV, LP1Area1, LP1Area2, LP2Area1, LP2Area2: TVec3;
  LNormal, LOrt, LEdgeVec, LStart, LEnd, LDir, LTestPoint: TVec3;
  LInvGravity: TVec3;
  LGround, LWater: TBestEdge;
  LPlane: TAasPlane;
  LArea1Rec, LArea2Rec: TAasArea;
  LGroundFace1, LGroundFace2: TAasFace;
  LEdge1, LEdge2: TAasEdge;
  LLink: PAasLinkedReach;
  LTrace: TAasTrace;
  LAreas: TArray<Integer>;
  LPoints: TArray<TVec3>;
  LVertexes: TArray<TVec3>;
  LCrouchTime: Single;
  LTime: Double;
  LDistFall: Single;
  LOutside: Boolean;
begin
  // must be able to walk or swim in the first area
  if not Context.AreaGrounded(AArea1) and not Context.AreaSwim(AArea1) then
    Exit(False);
  if not Context.AreaGrounded(AArea2) and not Context.AreaSwim(AArea2) then
    Exit(False);
  LArea1Rec := Context.Areas[AArea1];
  LArea2Rec := Context.Areas[AArea2];
  LArea1Swim := Context.AreaSwim(AArea1);
  // if the areas are not near enough in the x-y direction
  for LIndex := 0 to 1 do
  begin
    LLimit := LArea2Rec.Maxs[LIndex] + 10;
    if LArea1Rec.Mins[LIndex] > LLimit then
      Exit(False);
    LLimit := LArea2Rec.Mins[LIndex] - 10;
    if LArea1Rec.Maxs[LIndex] < LLimit then
      Exit(False);
  end;
  LInvGravity[0] := 0;
  LInvGravity[1] := 0;
  LInvGravity[2] := 1;
  FillChar(LGround, SizeOf(LGround), 0);
  FillChar(LWater, SizeOf(LWater), 0);
  LGround.Distance := 99999;
  LWater.Distance := 99999;
  LVertexes := Context.Vertexes;
  for LIndex := 0 to LArea1Rec.NumFaces - 1 do
  begin
    LGroundFace1Num := Context.FaceIndex[LArea1Rec.FirstFace + LIndex];
    LFaceSide1 := Ord(LGroundFace1Num < 0);
    LGroundFace1 := Context.FaceTable[Abs(LGroundFace1Num)];
    // if this is not a ground face
    if (LGroundFace1.FaceFlags and FACE_GROUND) = 0 then
    begin
      // if we can swim in the first area the face plane must be more or less horizontal
      if LArea1Swim then
      begin
        LPlane := Context.Planes[LGroundFace1.PlaneNum xor (1 - LFaceSide1)];
        if TAasVectorMath.Dot(LPlane.Normal, LInvGravity) < CPointSeven then
          Continue;
      end
      else
        // if we cannot swim in the area it must be a ground face
        Continue;
    end;
    for LK := 0 to LGroundFace1.NumEdges - 1 do
    begin
      LEdge1Num := Context.EdgeIndex[LGroundFace1.FirstEdge + LK];
      LSide1 := Ord(LEdge1Num < 0);
      // for water faces the side the first area is on is taken into account: the face is shared
      if (LGroundFace1.FaceFlags and FACE_GROUND) = 0 then
        LSide1 := Ord(LSide1 = LFaceSide1);
      LEdge1Num := Abs(LEdge1Num);
      LEdge1 := Context.Edges[LEdge1Num];
      // the vertexes of the edge
      LV1 := LVertexes[LEdge1.Vertexes[1 - LSide1]];
      LV2 := LVertexes[LEdge1.Vertexes[LSide1]];
      // a vertical plane through the edge; the normal points into area 2
      TAasVectorMath.Subtract(LV2, LV1, LEdgeVec);
      TAasVectorMath.Cross(LEdgeVec, LInvGravity, LNormal);
      TAasVectorMath.Normalize(LNormal);
      LDist := TAasVectorMath.Dot(LNormal, LV1);
      // the faces of the second area
      for LJ := 0 to LArea2Rec.NumFaces - 1 do
      begin
        LGroundFace2 := Context.FaceTable[Abs(Context.FaceIndex[LArea2Rec.FirstFace + LJ])];
        // must be a ground face
        if (LGroundFace2.FaceFlags and FACE_GROUND) = 0 then
          Continue;
        // the edges of this ground face
        for LL := 0 to LGroundFace2.NumEdges - 1 do
        begin
          LEdge2Num := Abs(Context.EdgeIndex[LGroundFace2.FirstEdge + LL]);
          LEdge2 := Context.Edges[LEdge2Num];
          LV3 := LVertexes[LEdge2.Vertexes[0]];
          LV4 := LVertexes[LEdge2.Vertexes[1]];
          // the distance of the two points to the vertical plane through the edge of area 1
          LDiff := TAasVectorMath.Dot(LNormal, LV3);
          LDiff := LDiff - LDist;
          if (Double(LDiff) < -CTenth) or (Double(LDiff) > CTenth) then
            Continue;
          LDiff := TAasVectorMath.Dot(LNormal, LV4);
          LDiff := LDiff - LDist;
          if (Double(LDiff) < -CTenth) or (Double(LDiff) > CTenth) then
            Continue;
          // project the two ground edges into the step side plane
          TAasVectorMath.Cross(LInvGravity, LNormal, LOrt);
          LInvGravityDot := TAasVectorMath.Dot(LInvGravity, LInvGravity);
          LOrtDot := TAasVectorMath.Dot(LOrt, LOrt);
          // since gravity is vertical this is just the z coordinate
          LY1 := LV1[2];
          LY2 := LV2[2];
          LY3 := LV3[2];
          LY4 := LV4[2];
          LX1 := TAasVectorMath.Dot(LV1, LOrt);
          LX1 := LX1 / LOrtDot;
          LX2 := TAasVectorMath.Dot(LV2, LOrt);
          LX2 := LX2 / LOrtDot;
          LX3 := TAasVectorMath.Dot(LV3, LOrt);
          LX3 := LX3 / LOrtDot;
          LX4 := TAasVectorMath.Dot(LV4, LOrt);
          LX4 := LX4 / LOrtDot;
          if LX1 > LX2 then
          begin
            LTmp := LX1; LX1 := LX2; LX2 := LTmp;
            LTmp := LY1; LY1 := LY2; LY2 := LTmp;
            LTmpV := LV1; LV1 := LV2; LV2 := LTmpV;
          end;
          if LX3 > LX4 then
          begin
            LTmp := LX3; LX3 := LX4; LX4 := LTmp;
            LTmp := LY3; LY3 := LY4; LY4 := LTmp;
            LTmpV := LV3; LV3 := LV4; LV4 := LTmpV;
          end;
          // if the two projected edge lines have no overlap
          if (LX2 <= LX3) or (LX4 <= LX1) then
            Continue;
          // if the two lines fully overlap
          if ((Double(LX1) - CHalf < LX3) and (LX4 < Double(LX2) + CHalf)) and
             ((Double(LX3) - CHalf < LX1) and (LX2 < Double(LX4) + CHalf)) then
          begin
            LDist1 := LY3 - LY1;
            LDist2 := LY4 - LY2;
            LP1Area1 := LV1;
            LP2Area1 := LV2;
            LP1Area2 := LV3;
            LP2Area2 := LV4;
          end
          else
          begin
            // if the points are equal
            if (LX1 > Double(LX3) - CTenth) and (LX1 < Double(LX3) + CTenth) then
            begin
              LDist1 := LY3 - LY1;
              LP1Area1 := LV1;
              LP1Area2 := LV3;
            end
            else if LX1 < LX3 then
            begin
              LY := LX3 - LX1;
              LTmp := LY2 - LY1;
              LY := LY * LTmp;
              LTmp := LX2 - LX1;
              LY := LY / LTmp;
              LY := LY1 + LY;
              LDist1 := LY3 - LY;
              LP1Area1 := LV3;
              LP1Area1[2] := LY;
              LP1Area2 := LV3;
            end
            else
            begin
              LY := LX1 - LX3;
              LTmp := LY4 - LY3;
              LY := LY * LTmp;
              LTmp := LX4 - LX3;
              LY := LY / LTmp;
              LY := LY3 + LY;
              LDist1 := LY - LY1;
              LP1Area1 := LV1;
              LP1Area2 := LV1;
              LP1Area2[2] := LY;
            end;
            // if the points are equal
            if (LX2 > Double(LX4) - CTenth) and (LX2 < Double(LX4) + CTenth) then
            begin
              LDist2 := LY4 - LY2;
              LP2Area1 := LV2;
              LP2Area2 := LV4;
            end
            else if LX2 < LX4 then
            begin
              LY := LX2 - LX3;
              LTmp := LY4 - LY3;
              LY := LY * LTmp;
              LTmp := LX4 - LX3;
              LY := LY / LTmp;
              LY := LY3 + LY;
              LDist2 := LY - LY2;
              LP2Area1 := LV2;
              LP2Area2 := LV2;
              LP2Area2[2] := LY;
            end
            else
            begin
              LY := LX4 - LX1;
              LTmp := LY2 - LY1;
              LY := LY * LTmp;
              LTmp := LX2 - LX1;
              LY := LY / LTmp;
              LY := LY1 + LY;
              LDist2 := LY4 - LY;
              LP2Area1 := LV4;
              LP2Area1[2] := LY;
              LP2Area2 := LV4;
            end;
          end;
          // if both distances are pretty much equal then the middle of the points is taken
          LLimit := LDist2 - 1;
          LTmp := LDist2 + 1;
          if (LDist1 > LLimit) and (LDist1 < LTmp) then
          begin
            LDist := LDist1;
            TAasReachVectors.Add(LP1Area1, LP2Area1, LStart);
            TAasReachVectors.Scale(LStart, 0.5, LStart);
            TAasReachVectors.Add(LP1Area2, LP2Area2, LEnd);
            TAasReachVectors.Scale(LEnd, 0.5, LEnd);
          end
          else if LDist1 < LDist2 then
          begin
            LDist := LDist1;
            LStart := LP1Area1;
            LEnd := LP1Area2;
          end
          else
          begin
            LDist := LDist2;
            LStart := LP2Area1;
            LEnd := LP2Area2;
          end;
          // the length of the overlapping part of the edges of the two areas
          TAasVectorMath.Subtract(LP2Area2, LP1Area2, LDir);
          LLength := TAasVectorMath.Length(LDir);
          if (LGroundFace1.FaceFlags and FACE_GROUND) <> 0 then
          begin
            // if the vertical distance is smaller or the same but the overlapping part of the edges is longer
            LLimit := LGround.Distance + 1;
            if (LDist < LGround.Distance) or ((LDist < LLimit) and (LLength > LGround.Length)) then
            begin
              LGround.Distance := LDist;
              LGround.Length := LLength;
              LGround.Found := True;
              LGround.EdgeNum := LEdge1Num;
              LGround.Start := LStart;
              LGround.Normal := LNormal;
              LGround.EndPoint := LEnd;
            end;
          end
          else
          begin
            LLimit := LWater.Distance + 1;
            if (LDist < LWater.Distance) or ((LDist < LLimit) and (LLength > LWater.Length)) then
            begin
              LWater.Distance := LDist;
              LWater.Length := LLength;
              LWater.Found := True;
              LWater.EdgeNum := LEdge1Num;
              LWater.Start := LStart;
              LWater.Normal := LNormal;
              LWater.EndPoint := LEnd;
            end;
          end;
        end;
      end;
    end;
  end;
  // a step: area 2 is higher but lower than the maximum step height (a distance of 0 also gives equal floor reachabilities)
  if LGround.Found then
  begin
    if (LGround.Distance >= 0) and (LGround.Distance < Context.Settings.PhysMaxStep) then
    begin
      LLink := Context.Heap.Allocate;
      if LLink = nil then
        Exit(False);
      LLink^.AreaNum := AArea2;
      LLink^.FaceNum := 0;
      LLink^.EdgeNum := LGround.EdgeNum;
      TAasVectorMath.MultiplyAdd(LGround.Start, LGround.Normal, INSIDEUNITS_WALKSTART, LLink^.Start);
      TAasReachVectors.MultiplyAdd(LGround.EndPoint, INSIDEUNITS_WALKEND, LGround.Normal, LLink^.EndPoint);
      LLink^.TravelType := TRAVEL_WALK;
      LLink^.TravelTime := 0;
      // going into a crouch area
      if not Context.AreaCrouch(AArea1) and Context.AreaCrouch(AArea2) then
        LLink^.TravelTime := TAasReachVectors.AddTravelTime(LLink^.TravelTime, Context.Settings.RsStartCrouch);
      Context.Heap.Push(AArea1, LLink);
      Inc(Context.Counters^.Step);
      Exit(True);
    end;
  end;
  // a water jump
  if LWater.Found then
  begin
    // a test point a little bit towards area 1, the maximum water jump height down
    TAasReachVectors.MultiplyAdd(LWater.EndPoint, -INSIDEUNITS, LWater.Normal, LTestPoint);
    LTestPoint[2] := LTestPoint[2] - Context.Settings.PhysMaxWaterJump;
    // if there IS water the maximum water jump height below the end point
    if (Context.AreaSettings[Context.Sampler.PointAreaNum(LTestPoint)].AreaFlags and AREA_LIQUID) <> 0 then
    begin
      // no ridiculous water jumps from areas very far below the water surface
      LLimit := Context.Settings.PhysMaxWaterJump + 24;
      if LWater.Distance < LLimit then
      begin
        // waterjumping from or towards a crouch only area is not possible
        if not Context.AreaCrouch(AArea1) and not Context.AreaCrouch(AArea2) then
        begin
          LLink := Context.Heap.Allocate;
          if LLink = nil then
            Exit(False);
          LLink^.AreaNum := AArea2;
          LLink^.FaceNum := 0;
          LLink^.EdgeNum := LWater.EdgeNum;
          LLink^.Start := LWater.Start;
          TAasReachVectors.MultiplyAdd(LWater.EndPoint, INSIDEUNITS_WATERJUMP, LWater.Normal, LLink^.EndPoint);
          LLink^.TravelType := TRAVEL_WATERJUMP;
          LLink^.TravelTime := TAasReachVectors.ToTravelTime(Context.Settings.RsWaterJump);
          Context.Heap.Push(AArea1, LLink);
          Inc(Context.Counters^.WaterJump);
          Exit(True);
        end;
      end;
    end;
  end;
  // a barrier jump: area 2 is higher but lower than the maximum barrier height
  if LGround.Found then
  begin
    if (LGround.Distance > 0) and (LGround.Distance < Context.Settings.PhysMaxBarrier) then
    begin
      // no water in area 1 or a very thin layer of water on the ground
      LLimit := LGround.Distance - LWater.Distance;
      if not LWater.Found or (LLimit < 16) then
      begin
        // no barrier jump towards or from a crouch area
        if not Context.AreaCrouch(AArea1) and not Context.AreaCrouch(AArea2) then
        begin
          LLink := Context.Heap.Allocate;
          if LLink = nil then
            Exit(False);
          LLink^.AreaNum := AArea2;
          LLink^.FaceNum := 0;
          LLink^.EdgeNum := LGround.EdgeNum;
          TAasVectorMath.MultiplyAdd(LGround.Start, LGround.Normal, INSIDEUNITS_WALKSTART, LLink^.Start);
          TAasReachVectors.MultiplyAdd(LGround.EndPoint, INSIDEUNITS_WALKEND, LGround.Normal, LLink^.EndPoint);
          LLink^.TravelType := TRAVEL_BARRIERJUMP;
          LLink^.TravelTime := TAasReachVectors.ToTravelTime(Context.Settings.RsBarrierJump);
          Context.Heap.Push(AArea1, LLink);
          Inc(Context.Counters^.Barrier);
          Exit(True);
        end;
      end;
    end;
  end;
  // walk and walk off ledge
  if LGround.Found then
  begin
    if LGround.Distance < 0 then
    begin
      LLimit := -Context.Settings.PhysMaxStep;
      if LGround.Distance > LLimit then
      begin
        // a walk reachability: the bot can walk or step back
        LLink := Context.Heap.Allocate;
        if LLink = nil then
          Exit(False);
        LLink^.AreaNum := AArea2;
        LLink^.FaceNum := 0;
        LLink^.EdgeNum := LGround.EdgeNum;
        TAasVectorMath.MultiplyAdd(LGround.Start, LGround.Normal, INSIDEUNITS_WALKSTART, LLink^.Start);
        TAasReachVectors.MultiplyAdd(LGround.EndPoint, INSIDEUNITS_WALKEND, LGround.Normal, LLink^.EndPoint);
        LLink^.TravelType := TRAVEL_WALK;
        LLink^.TravelTime := 1;
        Context.Heap.Push(AArea1, LLink);
        Inc(Context.Counters^.Walk);
        Exit(True);
      end;
      // if no maximum fall height is set or less than the max
      if (Context.Settings.RsMaxFallHeight = 0) or
         (Abs(Double(LGround.Distance)) < Double(Context.Settings.RsMaxFallHeight)) then
      begin
        // trace a bounding box vertically to check for solids
        TAasReachVectors.MultiplyAdd(LGround.EndPoint, INSIDEUNITS, LGround.Normal, LGround.EndPoint);
        LStart := LGround.EndPoint;
        LStart[2] := LGround.Start[2];
        LEnd := LGround.EndPoint;
        LEnd[2] := LEnd[2] + 4;
        LTrace := Context.Tracer.TraceClientBBox(LStart, LEnd, PRESENCE_NORMAL, -1);
        // if no solids were found
        if (not LTrace.StartSolid) and (LTrace.Fraction >= 1.0) then
        begin
          // the trace end point must be in the goal area
          LTrace.EndPos[2] := LTrace.EndPos[2] + 1;
          if Context.Sampler.PointAreaNum(LTrace.EndPos) = AArea2 then
          begin
            // if not going through a cluster portal
            LNumAreas := Context.TraceAreas(LStart, LEnd, 10, LAreas, LPoints);
            LOutside := True;
            for LIndex := 0 to LNumAreas - 1 do
              if Context.AreaClusterPortal(LAreas[LIndex]) then
              begin
                LOutside := False;
                Break;
              end;
            if LOutside then
            begin
              // a walk off ledge reachability
              LLink := Context.Heap.Allocate;
              if LLink = nil then
                Exit(False);
              LLink^.AreaNum := AArea2;
              LLink^.FaceNum := 0;
              LLink^.EdgeNum := LGround.EdgeNum;
              LLink^.Start := LGround.Start;
              LLink^.EndPoint := LGround.EndPoint;
              LLink^.TravelType := TRAVEL_WALKOFFLEDGE;
              // rs + fabs(distance) * 50 / gravity: all doubles
              LTime := Abs(Double(LGround.Distance));
              LTime := LTime * 50;
              LTime := LTime / Context.Settings.PhysGravity;
              LTime := Context.Settings.RsStartWalkOffLedge + LTime;
              LLink^.TravelTime := TAasReachVectors.ToTravelTime(LTime);
              // if falling from too high and not falling into water
              if not Context.AreaSwim(AArea2) and not Context.AreaJumpPad(AArea2) then
              begin
                if Context.Physics.FallDelta(LGround.Distance) > Context.Settings.PhysFallDelta5 then
                  LLink^.TravelTime := TAasReachVectors.AddTravelTime(LLink^.TravelTime, Context.Settings.RsFallDamage5);
                if Context.Physics.FallDelta(LGround.Distance) > Context.Settings.PhysFallDelta10 then
                  LLink^.TravelTime := TAasReachVectors.AddTravelTime(LLink^.TravelTime, Context.Settings.RsFallDamage10);
              end;
              Context.Heap.Push(AArea1, LLink);
              Inc(Context.Counters^.WalkOffLedge);
              Exit(True);
            end;
          end;
        end;
      end;
    end;
  end;
  Result := False;
end;

end.
