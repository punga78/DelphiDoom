{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - walk reachabilities on equal floor height         }
{                                                                              }
{  Port of AAS_Reachability_EqualFloorHeight of be_aas_reach.c. Based on the   }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id   }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.EqualFloor;

{$Q-}
{$R+}

interface

uses
  DelphiDoom.Aas.Reach.Part;

type
  /// <summary>Walk reachabilities between adjacent areas with ground faces that share an edge</summary>
  TAasReachEqualFloor = class(TAasReachPart)
  public
    /// <summary>AAS_Reachability_EqualFloorHeight: True if a reachability from the first area to the second was made</summary>
    function Calculate(const AArea1, AArea2: Integer): Boolean;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.VectorMath, DelphiDoom.Aas.Reach.Types,
  DelphiDoom.Aas.Reach.Vectors;

{ TAasReachEqualFloor }

function TAasReachEqualFloor.Calculate(const AArea1, AArea2: Integer): Boolean;
var
  LIndex, LFace1Index, LFace2Index, LEdge1Index, LEdge2Index, LEdgeNum, LSide: Integer;
  LArea1, LArea2: TAasArea;
  LFace1, LFace2: TAasFace;
  LEdge: TAasEdge;
  LFound: Boolean;
  LHeight, LBestHeight, LLength, LBestLength, LLimit: Single;
  LDirection, LStart, LEnd, LNormal, LInverseGravity, LGravityDirection, LEdgeVector: TVec3;
  LRecord: TAasLinkedReach;
  LLink: PAasLinkedReach;
  LVertexes: TArray<TVec3>;
begin
  if not Context.AreaGrounded(AArea1) or not Context.AreaGrounded(AArea2) then
    Exit(False);
  LArea1 := Context.Areas[AArea1];
  LArea2 := Context.Areas[AArea2];
  // if the areas are not near enough in the x-y direction
  for LIndex := 0 to 1 do
  begin
    LLimit := LArea2.Maxs[LIndex] + 10;
    if LArea1.Mins[LIndex] > LLimit then
      Exit(False);
    LLimit := LArea2.Mins[LIndex] - 10;
    if LArea1.Maxs[LIndex] < LLimit then
      Exit(False);
  end;
  // if area 2 is too high above area 1
  if LArea2.Mins[2] > LArea1.Maxs[2] then
    Exit(False);
  // the inverse of {0, 0, -1}: the zeros are negative zeros
  LGravityDirection[0] := 0;
  LGravityDirection[1] := 0;
  LGravityDirection[2] := -1;
  LInverseGravity[0] := -LGravityDirection[0];
  LInverseGravity[1] := -LGravityDirection[1];
  LInverseGravity[2] := -LGravityDirection[2];
  LBestHeight := 99999;
  LBestLength := 0;
  LFound := False;
  FillChar(LRecord, SizeOf(LRecord), 0);
  LVertexes := Context.Vertexes;
  // the areas have ground faces with a common edge: the lowest common edge is used for the reachability
  for LFace1Index := 0 to LArea1.NumFaces - 1 do
  begin
    LFace1 := Context.FaceTable[Abs(Context.FaceIndex[LArea1.FirstFace + LFace1Index])];
    if (LFace1.FaceFlags and FACE_GROUND) = 0 then
      Continue;
    for LFace2Index := 0 to LArea2.NumFaces - 1 do
    begin
      LFace2 := Context.FaceTable[Abs(Context.FaceIndex[LArea2.FirstFace + LFace2Index])];
      if (LFace2.FaceFlags and FACE_GROUND) = 0 then
        Continue;
      for LEdge1Index := 0 to LFace1.NumEdges - 1 do
        for LEdge2Index := 0 to LFace2.NumEdges - 1 do
        begin
          if Abs(Context.EdgeIndex[LFace1.FirstEdge + LEdge1Index]) <>
             Abs(Context.EdgeIndex[LFace2.FirstEdge + LEdge2Index]) then
            Continue;
          LEdgeNum := Context.EdgeIndex[LFace1.FirstEdge + LEdge1Index];
          LSide := Ord(LEdgeNum < 0);
          LEdge := Context.Edges[Abs(LEdgeNum)];
          // the length of the edge
          TAasVectorMath.Subtract(LVertexes[LEdge.Vertexes[1]], LVertexes[LEdge.Vertexes[0]], LDirection);
          LLength := TAasVectorMath.Length(LDirection);
          // the start point
          TAasReachVectors.Add(LVertexes[LEdge.Vertexes[0]], LVertexes[LEdge.Vertexes[1]], LStart);
          TAasReachVectors.Scale(LStart, 0.5, LStart);
          LEnd := LStart;
          // the end point several units inside area 2 and the start point inside area 1: the normal points into area 2
          // because the edges of the faces are stored counter clockwise
          TAasVectorMath.Subtract(LVertexes[LEdge.Vertexes[LSide]], LVertexes[LEdge.Vertexes[1 - LSide]], LEdgeVector);
          TAasVectorMath.Cross(LEdgeVector, Context.Planes[LFace2.PlaneNum].Normal, LNormal);
          TAasVectorMath.Normalize(LNormal);
          TAasReachVectors.MultiplyAdd(LEnd, INSIDEUNITS_WALKEND, LNormal, LEnd);
          TAasVectorMath.MultiplyAdd(LStart, LNormal, INSIDEUNITS_WALKSTART, LStart);
          LEnd[2] := LEnd[2] + 0.125;
          LHeight := TAasVectorMath.Dot(LInverseGravity, LStart);
          // the longest lowest edge
          LLimit := LBestHeight + 1;
          if (LHeight < LBestHeight) or ((LHeight < LLimit) and (LLength > LBestLength)) then
          begin
            LBestHeight := LHeight;
            LBestLength := LLength;
            LRecord.AreaNum := AArea2;
            LRecord.FaceNum := 0;
            LRecord.EdgeNum := LEdgeNum;
            LRecord.Start := LStart;
            LRecord.EndPoint := LEnd;
            LRecord.TravelType := TRAVEL_WALK;
            LRecord.TravelTime := 1;
            LFound := True;
          end;
        end;
    end;
  end;
  if not LFound then
    Exit(False);
  LLink := Context.Heap.Allocate;
  if LLink = nil then
    Exit(False);
  LLink^.AreaNum := LRecord.AreaNum;
  LLink^.FaceNum := LRecord.FaceNum;
  LLink^.EdgeNum := LRecord.EdgeNum;
  LLink^.Start := LRecord.Start;
  LLink^.EndPoint := LRecord.EndPoint;
  LLink^.TravelType := LRecord.TravelType;
  LLink^.TravelTime := LRecord.TravelTime;
  Context.Heap.Push(AArea1, LLink);
  // going into a crouch area
  if not Context.AreaCrouch(AArea1) and Context.AreaCrouch(AArea2) then
    LLink^.TravelTime := TAasReachVectors.AddTravelTime(LLink^.TravelTime, Context.Settings.RsStartCrouch);
  Inc(Context.Counters^.EqualFloor);
  Result := True;
end;

end.
