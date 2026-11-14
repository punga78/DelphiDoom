{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - additional walk off ledge reachabilities of an    }
{  area                                                                        }
{                                                                              }
{  Port of AAS_Reachability_WalkOffLedge of be_aas_reach.c. Based on the       }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id   }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.WalkOffLedge;

{$Q-}
{$R+}

interface

uses
  DelphiDoom.Aas.Types, DelphiDoom.Aas.Reach.Part;

type
  /// <summary>
  ///   Walk off ledge reachabilities from the ground edges of an area where a non ground face of the area (a wall
  ///   below the ledge) is shared with an area that is not grounded or has a gap
  /// </summary>
  TAasReachWalkOffLedge = class(TAasReachPart)
  strict private
    function HasGap(const AOtherArea, AFace2Num, AEdge1Num: Integer): Boolean;
    function ProcessSharedEdge(const AAreaNum: Integer; const AFace1, AFace2: TAasFace; const AFace2Num,
      AEdge1Num: Integer): Boolean;
  public
    /// <summary>AAS_Reachability_WalkOffLedge: the reachabilities from the area</summary>
    procedure Calculate(const AAreaNum: Integer);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Aas.VectorMath, DelphiDoom.Aas.Reach.Types,
  DelphiDoom.Aas.Reach.Vectors;

{ TAasReachWalkOffLedge }

// the gap test: a face of the other area that shares the edge with the ground face decides
function TAasReachWalkOffLedge.HasGap(const AOtherArea, AFace2Num, AEdge1Num: Integer): Boolean;
var
  LArea2: TAasArea;
  LN, LM, LFace3Num: Integer;
  LFace3: TAasFace;
  LFoundEdge: Boolean;
begin
  Result := False;
  LArea2 := Context.Areas[AOtherArea];
  for LN := 0 to LArea2.NumFaces - 1 do
  begin
    LFace3Num := Context.FaceIndex[LArea2.FirstFace + LN];
    // may not be the shared face of the two areas
    if Abs(LFace3Num) = Abs(AFace2Num) then
      Continue;
    LFace3 := Context.FaceTable[Abs(LFace3Num)];
    // an edge shared by all three faces
    LFoundEdge := False;
    LM := 0;
    while LM < LFace3.NumEdges do
    begin
      if Abs(Context.EdgeIndex[LFace3.FirstEdge + LM]) = Abs(AEdge1Num) then
      begin
        LFoundEdge := True;
        if (LFace3.FaceFlags and FACE_SOLID) = 0 then
          Result := True
        else if (LFace3.FaceFlags and FACE_GROUND) <> 0 then
          Result := False
        else
          // FIXME of the original: there are more situations to be handled
          Result := True;
        Break;
      end;
      Inc(LM);
    end;
    if LFoundEdge then
      Break;
  end;
end;

// the walk off ledge reachability at an edge shared by a ground face and a wall face; False when the original
// breaks out of the loop over the edges of the wall face, True when it goes on with the next edge
function TAasReachWalkOffLedge.ProcessSharedEdge(const AAreaNum: Integer; const AFace1, AFace2: TAasFace;
  const AFace2Num, AEdge1Num: Integer): Boolean;
var
  LOtherArea, LSide, LReachArea, LNumAreas, LIndex: Integer;
  LEdge: TAasEdge;
  LV1, LV2, LSharedEdgeVec, LDir, LMid, LTestEnd: TVec3;
  LTrace: TAasTrace;
  LLink: PAasLinkedReach;
  LAreas: TArray<Integer>;
  LPoints: TArray<TVec3>;
  LDifference: Single;
  LTime: Double;
  LClusterPortal: Boolean;
  LVertexes: TArray<TVec3>;
begin
  Result := False;
  // the area at the other side of the face
  if AFace2.FrontArea = AAreaNum then
    LOtherArea := AFace2.BackArea
  else
    LOtherArea := AFace2.FrontArea;
  // if the other area is grounded
  if (Context.AreaSettings[LOtherArea].AreaFlags and AREA_GROUNDED) <> 0 then
    if not HasGap(LOtherArea, AFace2Num, AEdge1Num) then
      Exit;
  // a walk off ledge reachability
  LEdge := Context.Edges[Abs(AEdge1Num)];
  LSide := Ord(AEdge1Num < 0);
  LVertexes := Context.Vertexes;
  LV1 := LVertexes[LEdge.Vertexes[LSide]];
  LV2 := LVertexes[LEdge.Vertexes[1 - LSide]];
  // the points really into the areas
  TAasVectorMath.Subtract(LV2, LV1, LSharedEdgeVec);
  TAasVectorMath.Cross(Context.Planes[AFace1.PlaneNum].Normal, LSharedEdgeVec, LDir);
  TAasVectorMath.Normalize(LDir);
  TAasReachVectors.Add(LV1, LV2, LMid);
  TAasReachVectors.Scale(LMid, 0.5, LMid);
  TAasReachVectors.MultiplyAdd(LMid, 8, LDir, LMid);
  LTestEnd := LMid;
  LTestEnd[2] := LTestEnd[2] - 1000;
  LTrace := Context.Tracer.TraceClientBBox(LMid, LTestEnd, PRESENCE_CROUCH, -1);
  if LTrace.StartSolid then
    Exit;
  LReachArea := Context.Sampler.PointAreaNum(LTrace.EndPos);
  if LReachArea = AAreaNum then
    Exit;
  if Context.ReachabilityExists(AAreaNum, LReachArea) then
    Exit;
  if not Context.AreaGrounded(LReachArea) and not Context.AreaSwim(LReachArea) then
    Exit;
  if (Context.AreaSettings[LReachArea].Contents and (AREACONTENTS_SLIME or AREACONTENTS_LAVA)) <> 0 then
    Exit;
  // if not going through a cluster portal
  LNumAreas := Context.TraceAreas(LMid, LTestEnd, 10, LAreas, LPoints);
  LClusterPortal := False;
  for LIndex := 0 to LNumAreas - 1 do
    if Context.AreaClusterPortal(LAreas[LIndex]) then
    begin
      LClusterPortal := True;
      Break;
    end;
  if LClusterPortal then
    Exit;
  // if a maximum fall height is set and the bot would fall down further
  LDifference := LMid[2] - LTrace.EndPos[2];
  if (Context.Settings.RsMaxFallHeight <> 0) and
     (Abs(Double(LDifference)) > Double(Context.Settings.RsMaxFallHeight)) then
    Exit;
  LLink := Context.Heap.Allocate;
  if LLink = nil then
    Exit;
  LLink^.AreaNum := LReachArea;
  LLink^.FaceNum := 0;
  LLink^.EdgeNum := AEdge1Num;
  LLink^.Start := LMid;
  LLink^.EndPoint := LTrace.EndPos;
  LLink^.TravelType := TRAVEL_WALKOFFLEDGE;
  // rs + fabs(height) * 50 / gravity: all doubles
  LTime := Abs(Double(LDifference));
  LTime := LTime * 50;
  LTime := LTime / Context.Settings.PhysGravity;
  LTime := Context.Settings.RsStartWalkOffLedge + LTime;
  LLink^.TravelTime := TAasReachVectors.ToTravelTime(LTime);
  if not Context.AreaSwim(LReachArea) and not Context.AreaJumpPad(LReachArea) then
  begin
    if Context.Physics.FallDelta(LDifference) > Context.Settings.PhysFallDelta5 then
      LLink^.TravelTime := TAasReachVectors.AddTravelTime(LLink^.TravelTime, Context.Settings.RsFallDamage5)
    else if Context.Physics.FallDelta(LDifference) > Context.Settings.PhysFallDelta10 then
      LLink^.TravelTime := TAasReachVectors.AddTravelTime(LLink^.TravelTime, Context.Settings.RsFallDamage10);
  end;
  Context.Heap.Push(AAreaNum, LLink);
  // another walk off ledge reachability
  Inc(Context.Counters^.WalkOffLedge);
  Result := True;
end;

procedure TAasReachWalkOffLedge.Calculate(const AAreaNum: Integer);
var
  LArea: TAasArea;
  LI, LK, LJ, LL, LFace1Num, LFace2Num, LEdge1Num, LEdge2Num: Integer;
  LFace1, LFace2: TAasFace;
begin
  if not Context.AreaGrounded(AAreaNum) or Context.AreaSwim(AAreaNum) then
    Exit;
  LArea := Context.Areas[AAreaNum];
  for LI := 0 to LArea.NumFaces - 1 do
  begin
    LFace1Num := Context.FaceIndex[LArea.FirstFace + LI];
    LFace1 := Context.FaceTable[Abs(LFace1Num)];
    // face 1 must be a ground face
    if (LFace1.FaceFlags and FACE_GROUND) = 0 then
      Continue;
    // all the edges of this ground face
    for LK := 0 to LFace1.NumEdges - 1 do
    begin
      LEdge1Num := Context.EdgeIndex[LFace1.FirstEdge + LK];
      // another face that is not a ground face and uses the same edge
      for LJ := 0 to LArea.NumFaces - 1 do
      begin
        LFace2Num := Context.FaceIndex[LArea.FirstFace + LJ];
        LFace2 := Context.FaceTable[Abs(LFace2Num)];
        // face 2 may not be a ground face
        if (LFace2.FaceFlags and FACE_GROUND) <> 0 then
          Continue;
        // compare all the edges
        LL := 0;
        while LL < LFace2.NumEdges do
        begin
          LEdge2Num := Context.EdgeIndex[LFace2.FirstEdge + LL];
          if Abs(LEdge1Num) = Abs(LEdge2Num) then
            if not ProcessSharedEdge(AAreaNum, LFace1, LFace2, LFace2Num, LEdge1Num) then
              Break;
          Inc(LL);
        end;
      end;
    end;
  end;
end;

end.
