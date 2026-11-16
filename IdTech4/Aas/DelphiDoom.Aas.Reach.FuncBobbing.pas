{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - func_bobbing reachabilities                       }
{                                                                              }
{  Port of AAS_FindFaceReachabilities and AAS_Reachability_FuncBobbing of      }
{  be_aas_reach.c. Based on the Quake III Arena GPL Source Code (id Software). }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.FuncBobbing;

{$Q-}
{$R+}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Reach.Types, DelphiDoom.Aas.Reach.Part;

type
  /// <summary>Reachabilities onto a platform that goes up and down (func_bobbing) at both ends of its movement</summary>
  TAasReachFuncBobbing = class(TAasReachPart)
  strict private
    function FindFaceReachabilities(const AFacePoints: array of TVec3; const APlane: TAasPlane;
      const ATowardsFace: Boolean): PAasLinkedReach;
    procedure Process(const AEnt: Integer);
  public
    /// <summary>AAS_Reachability_FuncBobbing: for every func_bobbing of the map</summary>
    procedure Calculate;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.Types, DelphiDoom.Aas.Bsp.CNumbers, DelphiDoom.Aas.Printer,
  DelphiDoom.Aas.VectorMath, DelphiDoom.Aas.Reach.Vectors, DelphiDoom.Aas.Reach.EdgePoints;

{ TAasReachFuncBobbing }

function TAasReachFuncBobbing.FindFaceReachabilities(const AFacePoints: array of TVec3; const APlane: TAasPlane;
  const ATowardsFace: Boolean): PAasLinkedReach;
var
  LArea, LJ, LK, LL, LFaceNum, LBestFaceNum, LEdgeNum, LNumPoints: Integer;
  LBestDistance, LDist, LHorizontalDistance, LSpeed, LLimit: Single;
  LBestStart, LBestStart2, LBestEnd, LBestEnd2, LTmp, LHorizontalDir, LTestPoint: TVec3;
  LAreaRec: TAasArea;
  LFace: TAasFace;
  LEdge: TAasEdge;
  LFacePlane, LBestFacePlane: TAasPlane;
  LReach: PAasLinkedReach;
  LVertexes: TArray<TVec3>;
begin
  Result := nil;
  LBestFaceNum := 0;
  FillChar(LBestFacePlane, SizeOf(LBestFacePlane), 0);
  FillChar(LBestStart, SizeOf(LBestStart), 0);
  FillChar(LBestStart2, SizeOf(LBestStart2), 0);
  FillChar(LBestEnd, SizeOf(LBestEnd), 0);
  FillChar(LBestEnd2, SizeOf(LBestEnd2), 0);
  LNumPoints := Length(AFacePoints);
  LVertexes := Context.Vertexes;
  for LArea := 1 to Context.NumAreas - 1 do
  begin
    LAreaRec := Context.Areas[LArea];
    // the shortest distance between one of the func_bobbing edges and one of the face edges of the area
    LBestDistance := 999999;
    for LJ := 0 to LAreaRec.NumFaces - 1 do
    begin
      LFaceNum := Context.FaceIndex[LAreaRec.FirstFace + LJ];
      LFace := Context.FaceTable[Abs(LFaceNum)];
      // if not a ground face
      if (LFace.FaceFlags and FACE_GROUND) = 0 then
        Continue;
      LFacePlane := Context.Planes[LFace.PlaneNum];
      for LK := 0 to LFace.NumEdges - 1 do
      begin
        LEdgeNum := Abs(Context.EdgeIndex[LFace.FirstEdge + LK]);
        LEdge := Context.Edges[LEdgeNum];
        for LL := 0 to LNumPoints - 1 do
        begin
          LDist := TAasReachEdgePoints.Closest(LVertexes[LEdge.Vertexes[0]], LVertexes[LEdge.Vertexes[1]],
            AFacePoints[LL], AFacePoints[(LL + 1) mod LNumPoints], LFacePlane, APlane, LBestStart, LBestEnd,
            LBestStart2, LBestEnd2, LBestDistance);
          if LDist < LBestDistance then
          begin
            LBestFaceNum := LFaceNum;
            LBestFacePlane := LFacePlane;
            LBestDistance := LDist;
          end;
        end;
      end;
    end;
    if LBestDistance > 192 then
      Continue;
    TAasReachVectors.Middle(LBestStart, LBestStart2, LBestStart);
    TAasReachVectors.Middle(LBestEnd, LBestEnd2, LBestEnd);
    if not ATowardsFace then
    begin
      LTmp := LBestStart;
      LBestStart := LBestEnd;
      LBestEnd := LTmp;
    end;
    TAasVectorMath.Subtract(LBestEnd, LBestStart, LHorizontalDir);
    LHorizontalDir[2] := 0;
    LHorizontalDistance := TAasVectorMath.Length(LHorizontalDir);
    LLimit := Context.Physics.MaxJumpDistance(Context.Settings.PhysJumpVel);
    LLimit := 2 * LLimit;
    if LHorizontalDistance > LLimit then
      Continue;
    // the end point should not be significantly higher than the start point
    LLimit := LBestEnd[2] - 32;
    if LLimit > LBestStart[2] then
      Continue;
    // do not fall down too far
    LLimit := LBestStart[2] - 128;
    if LBestEnd[2] < LLimit then
      Continue;
    // the distance should not be too far: a walk off ledge must be possible
    if LHorizontalDistance > 32 then
      if not Context.Movement.HorizontalVelocityForJump(0, LBestStart, LBestEnd, LSpeed) then
        Continue;
    LBestStart[2] := LBestStart[2] + 1;
    LBestEnd[2] := LBestEnd[2] + 1;
    if ATowardsFace then
      LTestPoint := LBestEnd
    else
      LTestPoint := LBestStart;
    LTestPoint[2] := 0;
    LDist := TAasVectorMath.Dot(LBestFacePlane.Normal, LTestPoint);
    LDist := LBestFacePlane.Dist - LDist;
    LTestPoint[2] := LDist / LBestFacePlane.Normal[2];
    if not Context.FaceTester.PointInsideFace(LBestFaceNum, LTestPoint, 0.1) then
    begin
      // if the faces are not overlapping then only go down
      LLimit := LBestEnd[2] - 16;
      if LLimit > LBestStart[2] then
        Continue;
    end;
    LReach := Context.Heap.Allocate;
    if LReach = nil then
      Exit(Result);
    LReach^.AreaNum := LArea;
    LReach^.FaceNum := 0;
    LReach^.EdgeNum := 0;
    LReach^.Start := LBestStart;
    LReach^.EndPoint := LBestEnd;
    LReach^.TravelType := 0;
    LReach^.TravelTime := 0;
    LReach^.Next := Result;
    Result := LReach;
  end;
end;

procedure TAasReachFuncBobbing.Process(const AEnt: Integer);
var
  LClassName, LModel: AnsiString;
  LSpawnFlags, LModelNum, LAxis, LI, LNumAreas: Integer;
  LHeight, LOffset: Single;
  LOrigin, LMoveEnd, LMoveStart, LMoveStartTop, LMoveEndTop, LMins, LMaxs, LMid, LOrg, LStart, LEnd, LDir, LAngles,
  LModelOrigin: TVec3;
  LStartEdgeVerts, LEndEdgeVerts: array[0..3] of TVec3;
  LStartPlane, LEndPlane: TAasPlane;
  LStartReach, LEndReach, LNextStart, LNextEnd, LFirstStart, LFirstEnd, LReach: PAasLinkedReach;
  LAreas: TArray<Integer>;
  LPoints: TArray<TVec3>;

  procedure Offsets(const AMove: TVec3; var AVerts: array of TVec3);
  var
    LCorner: Integer;
  begin
    for LCorner := 0 to 3 do
    begin
      AVerts[LCorner] := AMove;
      // the z of the bbox maxs, then the distance of the player origin to the ground
      LOffset := LMaxs[2] - LMid[2];
      AVerts[LCorner][2] := AVerts[LCorner][2] + LOffset;
      AVerts[LCorner][2] := AVerts[LCorner][2] + 24;
    end;
    LOffset := LMaxs[0] - LMid[0];
    AVerts[0][0] := AVerts[0][0] + LOffset;
    LOffset := LMaxs[1] - LMid[1];
    AVerts[0][1] := AVerts[0][1] + LOffset;
    LOffset := LMaxs[0] - LMid[0];
    AVerts[1][0] := AVerts[1][0] + LOffset;
    LOffset := LMins[1] - LMid[1];
    AVerts[1][1] := AVerts[1][1] + LOffset;
    LOffset := LMins[0] - LMid[0];
    AVerts[2][0] := AVerts[2][0] + LOffset;
    LOffset := LMins[1] - LMid[1];
    AVerts[2][1] := AVerts[2][1] + LOffset;
    LOffset := LMins[0] - LMid[0];
    AVerts[3][0] := AVerts[3][0] + LOffset;
    LOffset := LMaxs[1] - LMid[1];
    AVerts[3][1] := AVerts[3][1] + LOffset;
  end;

  function EdgeNumber(const AFirst, ASecond: TVec3): Integer;
  begin
    Result := (Integer(Trunc(AFirst[LAxis])) shl 16) or (Integer(Trunc(ASecond[LAxis])) and $0000FFFF);
  end;

begin
  if not Context.Entities.ValueForKey(AEnt, 'classname', LClassName) then
    Exit;
  if LClassName <> 'func_bobbing' then
    Exit;
  Context.Entities.FloatForKey(AEnt, 'height', LHeight);
  if LHeight = 0 then
    LHeight := 32;
  if not Context.Entities.ValueForKey(AEnt, 'model', LModel) then
  begin
    TAasPrinter.Print(Context.Import, PRT_ERROR, 'func_bobbing without model'#10);
    Exit;
  end;
  LModelNum := TAasCNumbers.AtoI(Copy(LModel, 2, MaxInt));
  if LModelNum <= 0 then
  begin
    TAasPrinter.Print(Context.Import, PRT_ERROR, 'func_bobbing with invalid model number'#10);
    Exit;
  end;
  // if the entity has an origin set then it is used
  if not Context.Entities.VectorForKey(AEnt, 'origin', LOrigin) then
  begin
    LOrigin[0] := 0;
    LOrigin[1] := 0;
    LOrigin[2] := 0;
  end;
  LAngles[0] := 0;
  LAngles[1] := 0;
  LAngles[2] := 0;
  Context.Models.ModelMinsMaxsOrigin(LModelNum, LAngles, LMins, LMaxs, LModelOrigin);
  TAasReachVectors.Add(LMins, LOrigin, LMins);
  TAasReachVectors.Add(LMaxs, LOrigin, LMaxs);
  TAasReachVectors.Add(LMins, LMaxs, LMid);
  TAasReachVectors.Scale(LMid, 0.5, LMid);
  LOrigin := LMid;
  LMoveEnd := LOrigin;
  LMoveStart := LOrigin;
  Context.Entities.IntForKey(AEnt, 'spawnflags', LSpawnFlags);
  // the axis of bobbing
  if (LSpawnFlags and 1) <> 0 then
    LAxis := 0
  else if (LSpawnFlags and 2) <> 0 then
    LAxis := 1
  else
    LAxis := 2;
  LMoveStart[LAxis] := LMoveStart[LAxis] - LHeight;
  LMoveEnd[LAxis] := LMoveEnd[LAxis] + LHeight;
  Offsets(LMoveStart, LStartEdgeVerts);
  LStartPlane.Normal[0] := 0;
  LStartPlane.Normal[1] := 0;
  LStartPlane.Normal[2] := 1;
  LStartPlane.Dist := LStartEdgeVerts[0][2];
  LStartPlane.PlaneType := 0;
  Offsets(LMoveEnd, LEndEdgeVerts);
  LEndPlane.Normal[0] := 0;
  LEndPlane.Normal[1] := 0;
  LEndPlane.Normal[2] := 1;
  LEndPlane.Dist := LEndEdgeVerts[0][2];
  LEndPlane.PlaneType := 0;
  // += maxs[2] - mid[2] + 24: the sum is made first
  LMoveStartTop := LMoveStart;
  LOffset := LMaxs[2] - LMid[2];
  LOffset := LOffset + 24;
  LMoveStartTop[2] := LMoveStartTop[2] + LOffset;
  LMoveEndTop := LMoveEnd;
  LOffset := LMaxs[2] - LMid[2];
  LOffset := LOffset + 24;
  LMoveEndTop[2] := LMoveEndTop[2] + LOffset;
  if Context.Sampler.PointAreaNum(LMoveStartTop) = 0 then
    Exit;
  if Context.Sampler.PointAreaNum(LMoveEndTop) = 0 then
    Exit;
  for LI := 0 to 1 do
  begin
    if LI = 0 then
    begin
      LFirstStart := FindFaceReachabilities(LStartEdgeVerts, LStartPlane, True);
      LFirstEnd := FindFaceReachabilities(LEndEdgeVerts, LEndPlane, False);
    end
    else
    begin
      LFirstStart := FindFaceReachabilities(LEndEdgeVerts, LEndPlane, True);
      LFirstEnd := FindFaceReachabilities(LStartEdgeVerts, LStartPlane, False);
    end;
    // the reachabilities from the start to the end
    LStartReach := LFirstStart;
    while LStartReach <> nil do
    begin
      LNextStart := LStartReach^.Next;
      LEndReach := LFirstEnd;
      while LEndReach <> nil do
      begin
        LNextEnd := LEndReach^.Next;
        if LI = 0 then
          LOrg := LMoveStartTop
        else
          LOrg := LMoveEndTop;
        TAasVectorMath.Subtract(LStartReach^.Start, LOrg, LDir);
        LDir[2] := 0;
        TAasVectorMath.Normalize(LDir);
        TAasReachVectors.MultiplyAdd(LStartReach^.Start, 1, LDir, LStart);
        LStart[2] := LStart[2] + 1;
        TAasReachVectors.MultiplyAdd(LStartReach^.Start, 16, LDir, LEnd);
        LEnd[2] := LEnd[2] + 1;
        LNumAreas := Context.TraceAreas(LStart, LEnd, 10, LAreas, LPoints);
        if LNumAreas > 0 then
        begin
          if LNumAreas > 1 then
            LStartReach^.Start := LPoints[1]
          else
            LStartReach^.Start := LEnd;
          if (Context.Sampler.PointAreaNum(LStartReach^.Start) <> 0) and
             (Context.Sampler.PointAreaNum(LEndReach^.EndPoint) <> 0) then
          begin
            LReach := Context.AllocateLink;
            LReach^.AreaNum := LEndReach^.AreaNum;
            if LI = 0 then
              LReach^.EdgeNum := EdgeNumber(LMoveStart, LMoveEnd)
            else
              LReach^.EdgeNum := EdgeNumber(LMoveEnd, LMoveStart);
            LReach^.FaceNum := (LSpawnFlags shl 16) or LModelNum;
            LReach^.Start := LStartReach^.Start;
            LReach^.EndPoint := LEndReach^.EndPoint;
            LReach^.TravelType := TRAVEL_FUNCBOB or Context.TravelFlagsForTeam(AEnt);
            LReach^.TravelTime := TAasReachVectors.ToTravelTime(Context.Settings.RsFuncBob);
            Inc(Context.Counters^.FuncBob);
            Context.Heap.Push(LStartReach^.AreaNum, LReach);
          end;
        end;
        LEndReach := LNextEnd;
      end;
      LStartReach := LNextStart;
    end;
    LStartReach := LFirstStart;
    while LStartReach <> nil do
    begin
      LNextStart := LStartReach^.Next;
      Context.Heap.Release(LStartReach);
      LStartReach := LNextStart;
    end;
    LEndReach := LFirstEnd;
    while LEndReach <> nil do
    begin
      LNextEnd := LEndReach^.Next;
      Context.Heap.Release(LEndReach);
      LEndReach := LNextEnd;
    end;
    // only go up with func_bobbing entities that go up and down
    if ((LSpawnFlags and 1) = 0) and ((LSpawnFlags and 2) = 0) then
      Break;
  end;
end;

procedure TAasReachFuncBobbing.Calculate;
var
  LEnt: Integer;
begin
  LEnt := Context.Entities.NextEntity(0);
  while LEnt <> 0 do
  begin
    Process(LEnt);
    LEnt := Context.Entities.NextEntity(LEnt);
  end;
end;

end.
