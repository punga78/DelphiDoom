{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - ladder reachabilities                             }
{                                                                              }
{  Port of AAS_Reachability_Ladder of be_aas_reach.c. Based on the Quake III   }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{  abs() of the original is the integer abs(): "abs(DotProduct(..)) < 0.1" is  }
{  true for every dot product between -1 and 1 (the float is truncated to 0).  }
{  The port does the same.                                                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Ladder;

{$Q-}
{$R+}

interface

uses
  DelphiDoom.Aas.Reach.Part;

type
  /// <summary>Ladder reachabilities between two areas with ladder faces (and the walk off or jump ones that go with them)</summary>
  TAasReachLadder = class(TAasReachPart)
  public
    /// <summary>AAS_Reachability_Ladder: True if reachabilities between the two areas were made</summary>
    function Calculate(const AArea1, AArea2: Integer): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.VectorMath, DelphiDoom.Aas.Reach.Types,
  DelphiDoom.Aas.Reach.Vectors;

const
  CPointSeven: Double = 0.7;

{ TAasReachLadder }

function TAasReachLadder.Calculate(const AArea1, AArea2: Integer): Boolean;
var
  LIndex, LJ, LK, LL, LEdge1Num, LEdge2Num, LSharedEdgeNum, LLowestEdgeNum, LFace1Num, LFace2Num, LLadderFace1Num,
  LLadderFace2Num, LFirstV, LArea2Num: Integer;
  LFace1Area, LFace2Area, LBestFace1Area, LBestFace2Area, LPhysJumpVel, LMaxJumpHeight, LDot: Single;
  LArea1, LArea2: TAasArea;
  LFace1, LFace2, LLadderFace1, LLadderFace2: TAasFace;
  LHaveFaces, LShared, LVertical1, LVertical2: Boolean;
  LArea1Point, LArea2Point, LV1, LV2, LUp, LMid, LLowestPoint, LStart, LEnd, LSharedEdgeVec, LDir: TVec3;
  LPlane1, LPlane2: TAasPlane;
  LEdge: TAasEdge;
  LLink: PAasLinkedReach;
  LTrace: TAasTrace;
  LVertexes: TArray<TVec3>;
  LFound: Boolean;
  LLimit: Single;

  function NewLink(const AToArea, AFaceNum, AEdgeNum: Integer; const AStart, AEnd: TVec3; const ATravelType,
    ATravelTime: Integer; const AFromArea: Integer): PAasLinkedReach;
  begin
    Result := Context.Heap.Allocate;
    if Result = nil then
      Exit;
    Result^.AreaNum := AToArea;
    Result^.FaceNum := AFaceNum;
    Result^.EdgeNum := AEdgeNum;
    Result^.Start := AStart;
    Result^.EndPoint := AEnd;
    Result^.TravelType := ATravelType;
    Result^.TravelTime := ATravelTime;
    Context.Heap.Push(AFromArea, Result);
  end;

begin
  if not Context.AreaLadder(AArea1) or not Context.AreaLadder(AArea2) then
    Exit(False);
  LUp[0] := 0;
  LUp[1] := 0;
  LUp[2] := 1;
  LPhysJumpVel := Context.Settings.PhysJumpVel;
  // the maximum height a player can jump with the given initial z velocity
  LMaxJumpHeight := Context.Physics.MaxJumpHeight(LPhysJumpVel);
  LArea1 := Context.Areas[AArea1];
  LArea2 := Context.Areas[AArea2];
  LVertexes := Context.Vertexes;
  LHaveFaces := False;
  LLadderFace1Num := 0;
  LLadderFace2Num := 0;
  FillChar(LLadderFace1, SizeOf(LLadderFace1), 0);
  FillChar(LLadderFace2, SizeOf(LLadderFace2), 0);
  LBestFace1Area := -9999;
  LBestFace2Area := -9999;
  LSharedEdgeNum := 0;
  LLowestEdgeNum := 0;
  for LIndex := 0 to LArea1.NumFaces - 1 do
  begin
    LFace1Num := Context.FaceIndex[LArea1.FirstFace + LIndex];
    LFace1 := Context.FaceTable[Abs(LFace1Num)];
    // if not a ladder face
    if (LFace1.FaceFlags and FACE_LADDER) = 0 then
      Continue;
    for LJ := 0 to LArea2.NumFaces - 1 do
    begin
      LFace2Num := Context.FaceIndex[LArea2.FirstFace + LJ];
      LFace2 := Context.FaceTable[Abs(LFace2Num)];
      if (LFace2.FaceFlags and FACE_LADDER) = 0 then
        Continue;
      // check if the faces share an edge
      LK := 0;
      while LK < LFace1.NumEdges do
      begin
        LEdge1Num := Context.EdgeIndex[LFace1.FirstEdge + LK];
        LShared := False;
        LL := 0;
        while LL < LFace2.NumEdges do
        begin
          LEdge2Num := Context.EdgeIndex[LFace2.FirstEdge + LL];
          if Abs(LEdge1Num) = Abs(LEdge2Num) then
          begin
            // the face with the largest area
            LFace1Area := Context.Geometry.FaceArea(Abs(LFace1Num));
            LFace2Area := Context.Geometry.FaceArea(Abs(LFace2Num));
            if (LFace1Area > LBestFace1Area) and (LFace2Area > LBestFace2Area) then
            begin
              LBestFace1Area := LFace1Area;
              LBestFace2Area := LFace2Area;
              LHaveFaces := True;
              LLadderFace1 := LFace1;
              LLadderFace2 := LFace2;
              LLadderFace1Num := LFace1Num;
              LLadderFace2Num := LFace2Num;
              LSharedEdgeNum := LEdge1Num;
            end;
            LShared := True;
            Break;
          end;
          Inc(LL);
        end;
        if LShared then
          Break;
        Inc(LK);
      end;
    end;
  end;
  if not LHaveFaces then
    Exit(False);
  // the middle of the shared edge
  LEdge := Context.Edges[Abs(LSharedEdgeNum)];
  LFirstV := Ord(LSharedEdgeNum < 0);
  LV1 := LVertexes[LEdge.Vertexes[LFirstV]];
  LV2 := LVertexes[LEdge.Vertexes[1 - LFirstV]];
  TAasReachVectors.Add(LV1, LV2, LArea1Point);
  TAasReachVectors.Scale(LArea1Point, 0.5, LArea1Point);
  LArea2Point := LArea1Point;
  // if the face plane in area 1 is pretty much vertical
  LPlane1 := Context.Planes[LLadderFace1.PlaneNum xor Ord(LLadderFace1Num < 0)];
  LPlane2 := Context.Planes[LLadderFace2.PlaneNum xor Ord(LLadderFace2Num < 0)];
  // the points really into the areas
  TAasVectorMath.Subtract(LV2, LV1, LSharedEdgeVec);
  TAasVectorMath.Cross(LPlane1.Normal, LSharedEdgeVec, LDir);
  TAasVectorMath.Normalize(LDir);
  // 32 because that is larger than 16 (the x and y of the box of the bot)
  TAasReachVectors.MultiplyAdd(LArea1Point, -32, LDir, LArea1Point);
  TAasReachVectors.MultiplyAdd(LArea2Point, 32, LDir, LArea2Point);
  // abs() is the integer abs of the original: the dot product is truncated
  LDot := TAasVectorMath.Dot(LPlane1.Normal, LUp);
  LVertical1 := Trunc(LDot) = 0;
  LDot := TAasVectorMath.Dot(LPlane2.Normal, LUp);
  LVertical2 := Trunc(LDot) = 0;
  // there is only reachability between vertical ladder faces
  if not LVertical1 and not LVertical2 then
    Exit(False);
  // if both are vertical ladder faces that do not make a sharp corner and the shared edge is not too vertical
  if LVertical1 and LVertical2 and (TAasVectorMath.Dot(LPlane1.Normal, LPlane2.Normal) > CPointSeven) then
  begin
    LDot := TAasVectorMath.Dot(LSharedEdgeVec, LUp);
    if Trunc(LDot) = 0 then
    begin
      TAasReachVectors.MultiplyAdd(LArea2Point, -3, LPlane1.Normal, LEnd);
      LLink := NewLink(AArea2, LLadderFace1Num, Abs(LSharedEdgeNum), LArea1Point, LEnd, TRAVEL_LADDER, 10, AArea1);
      if LLink = nil then
        Exit(False);
      Inc(Context.Counters^.Ladder);
      TAasReachVectors.MultiplyAdd(LArea1Point, -3, LPlane1.Normal, LEnd);
      LLink := NewLink(AArea1, LLadderFace2Num, Abs(LSharedEdgeNum), LArea2Point, LEnd, TRAVEL_LADDER, 10, AArea2);
      if LLink = nil then
        Exit(False);
      Inc(Context.Counters^.Ladder);
      Exit(True);
    end;
  end;
  // if the second ladder face is also a ground face: a ladder end reachability and a walk off ledge one
  if LVertical1 and ((LLadderFace2.FaceFlags and FACE_GROUND) <> 0) then
  begin
    LEnd := LArea2Point;
    LEnd[2] := LEnd[2] + 16;
    TAasReachVectors.MultiplyAdd(LEnd, -15, LPlane1.Normal, LEnd);
    LLink := NewLink(AArea2, LLadderFace1Num, Abs(LSharedEdgeNum), LArea1Point, LEnd, TRAVEL_LADDER, 10, AArea1);
    if LLink = nil then
      Exit(False);
    Inc(Context.Counters^.Ladder);
    LLink := NewLink(AArea1, LLadderFace2Num, Abs(LSharedEdgeNum), LArea2Point, LArea1Point, TRAVEL_WALKOFFLEDGE, 10,
      AArea2);
    if LLink = nil then
      Exit(False);
    Inc(Context.Counters^.WalkOffLedge);
    Exit(True);
  end;
  if LVertical1 then
  begin
    // the lowest edge of the ladder face
    LLowestPoint[0] := 0;
    LLowestPoint[1] := 0;
    LLowestPoint[2] := 99999;
    for LIndex := 0 to LLadderFace1.NumEdges - 1 do
    begin
      LEdge1Num := Abs(Context.EdgeIndex[LLadderFace1.FirstEdge + LIndex]);
      LEdge := Context.Edges[LEdge1Num];
      LV1 := LVertexes[LEdge.Vertexes[0]];
      LV2 := LVertexes[LEdge.Vertexes[1]];
      TAasReachVectors.Add(LV1, LV2, LMid);
      TAasReachVectors.Scale(LMid, 0.5, LMid);
      if LMid[2] < LLowestPoint[2] then
      begin
        LLowestPoint := LMid;
        LLowestEdgeNum := LEdge1Num;
      end;
    end;
    LPlane1 := Context.Planes[LLadderFace1.PlaneNum];
    // trace down in the middle of this edge
    TAasReachVectors.MultiplyAdd(LLowestPoint, 5, LPlane1.Normal, LStart);
    LEnd := LStart;
    LStart[2] := LStart[2] + 5;
    LEnd[2] := LEnd[2] - 100;
    LTrace := Context.Tracer.TraceClientBBox(LStart, LEnd, PRESENCE_NORMAL, -1);
    LTrace.EndPos[2] := LTrace.EndPos[2] + 1;
    LArea2Num := Context.Sampler.PointAreaNum(LTrace.EndPos);
    LArea2 := Context.Areas[LArea2Num];
    // does the area have a vertical ladder face?
    LFound := False;
    LIndex := 0;
    while LIndex < LArea2.NumFaces do
    begin
      LFace2Num := Context.FaceIndex[LArea2.FirstFace + LIndex];
      LFace2 := Context.FaceTable[Abs(LFace2Num)];
      if (LFace2.FaceFlags and FACE_LADDER) <> 0 then
      begin
        LPlane2 := Context.Planes[LFace2.PlaneNum];
        LDot := TAasVectorMath.Dot(LPlane2.Normal, LUp);
        if Trunc(LDot) = 0 then
        begin
          LFound := True;
          Break;
        end;
      end;
      Inc(LIndex);
    end;
    // if from another area without vertical ladder faces and the reachabilities do not exist already
    if (not LFound) and (LArea2Num <> AArea1) and not Context.ReachabilityExists(AArea1, LArea2Num) and
       not Context.ReachabilityExists(LArea2Num, AArea1) then
    begin
      // if the height is jumpable
      LLimit := LStart[2] - LTrace.EndPos[2];
      if LLimit < LMaxJumpHeight then
      begin
        LLink := NewLink(LArea2Num, LLadderFace1Num, LLowestEdgeNum, LLowestPoint, LTrace.EndPos, TRAVEL_LADDER, 10,
          AArea1);
        if LLink = nil then
          Exit(False);
        Inc(Context.Counters^.Ladder);
        // the end point a little bit into the ladder and a little higher
        TAasReachVectors.MultiplyAdd(LLowestPoint, -5, LPlane1.Normal, LEnd);
        LEnd[2] := LEnd[2] + 10;
        LLink := NewLink(AArea1, LLadderFace1Num, LLowestEdgeNum, LTrace.EndPos, LEnd, TRAVEL_JUMP, 10, LArea2Num);
        if LLink = nil then
          Exit(False);
        Inc(Context.Counters^.Jump);
        Exit(True);
      end;
    end;
  end;
  Result := False;
end;

end.
