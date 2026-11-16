{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - jump and walk off ledge reachabilities between    }
{  areas that are apart                                                        }
{                                                                              }
{  Port of AAS_Reachability_Jump of be_aas_reach.c: the two closest points on  }
{  the ground of the areas are calculated, and if there are gaps between them  }
{  a jump is predicted. Based on the Quake III Arena GPL Source Code (id       }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Jump;

{$Q-}
{$R+}

interface

uses
  DelphiDoom.Aas.Reach.Part;

type
  /// <summary>Jump reachabilities (and the walk off ledge ones that need a run) between two areas</summary>
  TAasReachJump = class(TAasReachPart)
  public
    /// <summary>
    ///   AAS_Reachability_Jump: the original makes the reachability and returns False all the same (the result of a call
    ///   is False always)
    /// </summary>
    function Calculate(const AArea1, AArea2: Integer): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Move.Types,
  DelphiDoom.Aas.VectorMath, DelphiDoom.Aas.Reach.Types, DelphiDoom.Aas.Reach.Vectors, DelphiDoom.Aas.Reach.EdgePoints;

const
  // 0.7 is a double; 0.1f, 1.2f and 1.05f are floats
  CPointSeven: Double = 0.7;
  CTenthFloat: Single = 0.100000001490116119384765625;
  COnePointTwo: Single = 1.2000000476837158203125;
  COnePointZeroFive: Single = 1.0499999523162841796875;

{ TAasReachJump }

function TAasReachJump.Calculate(const AArea1, AArea2: Integer): Boolean;
var
  LIndex, LFace1Index, LFace2Index, LEdge1Index, LEdge2Index, LTravelType, LStopEvent, LNumAreas, LJ: Integer;
  LArea1, LArea2: TAasArea;
  LFace1, LFace2: TAasFace;
  LEdge1, LEdge2: TAasEdge;
  LPhysJumpVel, LMaxJumpDistance, LMaxJumpHeight, LBestDistance, LSpeed, LLimit, LHeight, LTime: Single;
  LBestStart, LBestStart2, LBestEnd, LBestEnd2: TVec3;
  LTestStart, LTestEnd, LDir, LVelocity, LCmdMove, LUp, LSidewards: TVec3;
  LPlane: TAasPlane;
  LTrace: TAasTrace;
  LMove: TAasClientMove;
  LLink: PAasLinkedReach;
  LAreas: TArray<Integer>;
  LPoints: TArray<TVec3>;
  LVertexes: TArray<TVec3>;
  LFound: Boolean;
  LSettings: TAasMoveSettings;

  // the trace of the client box 100 units down from the test point
  procedure TraceDown(const AStart: TVec3);
  begin
    LTestEnd := AStart;
    LTestEnd[2] := LTestEnd[2] - 100;
    LTrace := Context.Tracer.TraceClientBBox(AStart, LTestEnd, PRESENCE_NORMAL, -1);
  end;

begin
  if not Context.AreaGrounded(AArea1) or not Context.AreaGrounded(AArea2) then
    Exit(False);
  // cannot jump from or to a crouch area
  if Context.AreaCrouch(AArea1) or Context.AreaCrouch(AArea2) then
    Exit(False);
  LSettings := Context.Settings;
  LArea1 := Context.Areas[AArea1];
  LArea2 := Context.Areas[AArea2];
  LUp[0] := 0;
  LUp[1] := 0;
  LUp[2] := 1;
  LPhysJumpVel := LSettings.PhysJumpVel;
  // the maximum distance a player can jump
  LMaxJumpDistance := Context.Physics.MaxJumpDistance(LPhysJumpVel);
  LMaxJumpDistance := 2 * LMaxJumpDistance;
  // the maximum height a player can jump with the given initial z velocity
  LMaxJumpHeight := Context.Physics.MaxJumpHeight(LPhysJumpVel);
  // if the areas are not near enough in the x-y direction
  for LIndex := 0 to 1 do
  begin
    LLimit := LArea2.Maxs[LIndex] + LMaxJumpDistance;
    if LArea1.Mins[LIndex] > LLimit then
      Exit(False);
    LLimit := LArea2.Mins[LIndex] - LMaxJumpDistance;
    if LArea1.Maxs[LIndex] < LLimit then
      Exit(False);
  end;
  // if area 2 is way too high to jump up to
  LLimit := LArea1.Maxs[2] + LMaxJumpHeight;
  if LArea2.Mins[2] > LLimit then
    Exit(False);
  LBestDistance := 999999;
  FillChar(LBestStart, SizeOf(LBestStart), 0);
  FillChar(LBestStart2, SizeOf(LBestStart2), 0);
  FillChar(LBestEnd, SizeOf(LBestEnd), 0);
  FillChar(LBestEnd2, SizeOf(LBestEnd2), 0);
  LVertexes := Context.Vertexes;
  for LFace1Index := 0 to LArea1.NumFaces - 1 do
  begin
    LFace1 := Context.FaceTable[Abs(Context.FaceIndex[LArea1.FirstFace + LFace1Index])];
    // if not a ground face
    if (LFace1.FaceFlags and FACE_GROUND) = 0 then
      Continue;
    for LFace2Index := 0 to LArea2.NumFaces - 1 do
    begin
      LFace2 := Context.FaceTable[Abs(Context.FaceIndex[LArea2.FirstFace + LFace2Index])];
      if (LFace2.FaceFlags and FACE_GROUND) = 0 then
        Continue;
      for LEdge1Index := 0 to LFace1.NumEdges - 1 do
      begin
        LEdge1 := Context.Edges[Abs(Context.EdgeIndex[LFace1.FirstEdge + LEdge1Index])];
        for LEdge2Index := 0 to LFace2.NumEdges - 1 do
        begin
          LEdge2 := Context.Edges[Abs(Context.EdgeIndex[LFace2.FirstEdge + LEdge2Index])];
          // the minimum distance between the two edges, with the ground planes
          LBestDistance := TAasReachEdgePoints.Closest(LVertexes[LEdge1.Vertexes[0]], LVertexes[LEdge1.Vertexes[1]],
            LVertexes[LEdge2.Vertexes[0]], LVertexes[LEdge2.Vertexes[1]], Context.Planes[LFace1.PlaneNum],
            Context.Planes[LFace2.PlaneNum], LBestStart, LBestEnd, LBestStart2, LBestEnd2, LBestDistance);
        end;
      end;
    end;
  end;
  TAasReachVectors.Middle(LBestStart, LBestStart2, LBestStart);
  TAasReachVectors.Middle(LBestEnd, LBestEnd2, LBestEnd);
  if (LBestDistance > 4) and (LBestDistance < LMaxJumpDistance) then
  begin
    // if very close and almost no height difference then the bot can walk
    LLimit := LBestStart[2] - LBestEnd[2];
    if (LBestDistance <= 48) and (Abs(Double(LLimit)) < 8) then
    begin
      LSpeed := 400;
      LTravelType := TRAVEL_WALKOFFLEDGE;
    end
    else if Context.Movement.HorizontalVelocityForJump(0, LBestStart, LBestEnd, LSpeed) then
    begin
      LSpeed := LSpeed * COnePointTwo;
      LTravelType := TRAVEL_WALKOFFLEDGE;
    end
    else
    begin
      // if the speed cannot be calculated (the jump is not possible) there is no jump reachability
      if not Context.Movement.HorizontalVelocityForJump(LPhysJumpVel, LBestStart, LBestEnd, LSpeed) then
        Exit(False);
      LSpeed := LSpeed * COnePointZeroFive;
      LTravelType := TRAVEL_JUMP;
      // the horizontal distance is not too small
      TAasVectorMath.Subtract(LBestEnd, LBestStart, LDir);
      LDir[2] := 0;
      if TAasVectorMath.Length(LDir) < 10 then
        Exit(False);
    end;
    TAasVectorMath.Subtract(LBestEnd, LBestStart, LDir);
    TAasVectorMath.Normalize(LDir);
    TAasReachVectors.MultiplyAdd(LBestStart, 1, LDir, LTestStart);
    TraceDown(LTestStart);
    if LTrace.StartSolid then
      Exit(False);
    if LTrace.Fraction < 1 then
    begin
      LPlane := Context.Planes[LTrace.PlaneNum];
      // if the bot can stand on the surface
      if TAasVectorMath.Dot(LPlane.Normal, LUp) >= CPointSeven then
        // if no lava or slime below
        if (Context.World.PointContents(LTrace.EndPos) and (BSP_CONTENTS_LAVA or BSP_CONTENTS_SLIME)) = 0 then
        begin
          LLimit := LTestStart[2] - LTrace.EndPos[2];
          if LLimit <= LSettings.PhysMaxBarrier then
            Exit(False);
        end;
    end;
    TAasReachVectors.MultiplyAdd(LBestEnd, -1, LDir, LTestStart);
    TraceDown(LTestStart);
    if LTrace.StartSolid then
      Exit(False);
    if LTrace.Fraction < 1 then
    begin
      LPlane := Context.Planes[LTrace.PlaneNum];
      if TAasVectorMath.Dot(LPlane.Normal, LUp) >= CPointSeven then
        if (Context.World.PointContents(LTrace.EndPos) and (BSP_CONTENTS_LAVA or BSP_CONTENTS_SLIME)) = 0 then
        begin
          LLimit := LTestStart[2] - LTrace.EndPos[2];
          if LLimit <= LSettings.PhysMaxBarrier then
            Exit(False);
        end;
    end;
    // the command movement
    LCmdMove[0] := 0;
    LCmdMove[1] := 0;
    LCmdMove[2] := 0;
    if (LTravelType and TRAVELTYPE_MASK) = TRAVEL_JUMP then
      LCmdMove[2] := LSettings.PhysJumpVel
    else
      LCmdMove[2] := 0;
    TAasVectorMath.Subtract(LBestEnd, LBestStart, LDir);
    LDir[2] := 0;
    TAasVectorMath.Normalize(LDir);
    TAasVectorMath.Cross(LDir, LUp, LSidewards);
    LStopEvent := SE_HITGROUND or SE_ENTERWATER or SE_ENTERSLIME or SE_ENTERLAVA or SE_HITGROUNDDAMAGE;
    if not Context.AreaClusterPortal(AArea1) and not Context.AreaClusterPortal(AArea2) then
      LStopEvent := LStopEvent or SE_TOUCHCLUSTERPORTAL;
    LFound := False;
    LIndex := 0;
    while LIndex < 3 do
    begin
      if LIndex = 1 then
        TAasReachVectors.Add(LTestEnd, LSidewards, LTestEnd)
      else if LIndex = 2 then
        TAasVectorMath.Subtract(LBestEnd, LSidewards, LTestEnd)
      else
        LTestEnd := LBestEnd;
      TAasVectorMath.Subtract(LTestEnd, LBestStart, LDir);
      LDir[2] := 0;
      TAasVectorMath.Normalize(LDir);
      TAasReachVectors.Scale(LDir, LSpeed, LVelocity);
      Context.Movement.PredictClientMovement(LMove, -1, LBestStart, PRESENCE_NORMAL, True, LVelocity, LCmdMove, 3, 30,
        CTenthFloat, LStopEvent, 0, False);
      // if the prediction time was not enough to fully predict the movement
      if LMove.Frames >= 30 then
        Exit(False);
      // do not enter slime or lava and do not fall from too high
      if (LMove.StopEvent and (SE_ENTERSLIME or SE_ENTERLAVA)) <> 0 then
        Exit(False);
      // never jump or fall through a cluster portal
      if (LMove.StopEvent and SE_TOUCHCLUSTERPORTAL) <> 0 then
        Exit(False);
      // the end position should be in area 2, also a little bit back because the jump could have rushed through the area
      TAasReachVectors.MultiplyAdd(LMove.EndPos, -64, LDir, LTestStart);
      LTestStart[2] := LTestStart[2] + 1;
      LNumAreas := Context.TraceAreas(LMove.EndPos, LTestStart, 10, LAreas, LPoints);
      LJ := 0;
      while (LJ < LNumAreas) and (LAreas[LJ] <> AArea2) do
        Inc(LJ);
      if LJ < LNumAreas then
      begin
        LFound := True;
        Break;
      end;
      Inc(LIndex);
    end;
    if not LFound then
      Exit(False);
    LLink := Context.Heap.Allocate;
    if LLink = nil then
      Exit(False);
    LLink^.AreaNum := AArea2;
    LLink^.FaceNum := 0;
    LLink^.EdgeNum := 0;
    LLink^.Start := LBestStart;
    LLink^.EndPoint := LBestEnd;
    LLink^.TravelType := LTravelType;
    TAasVectorMath.Subtract(LBestEnd, LBestStart, LDir);
    LHeight := LDir[2];
    LDir[2] := 0;
    if ((LTravelType and TRAVELTYPE_MASK) = TRAVEL_WALKOFFLEDGE) and (LHeight > TAasVectorMath.Length(LDir)) then
    begin
      LTime := LHeight * 50;
      LTime := LTime / LSettings.PhysGravity;
      LTime := LSettings.RsStartWalkOffLedge + LTime;
    end
    else
    begin
      LTime := TAasReachVectors.Distance(LBestEnd, LBestStart);
      LTime := LTime * 240;
      LTime := LTime / LSettings.PhysMaxWalkVelocity;
      LTime := LSettings.RsStartJump + LTime;
    end;
    LLink^.TravelTime := TAasReachVectors.ToTravelTime(LTime);
    if not Context.AreaJumpPad(AArea2) then
    begin
      LLimit := LBestStart[2] - LBestEnd[2];
      if Context.Physics.FallDelta(LLimit) > LSettings.PhysFallDelta5 then
        LLink^.TravelTime := TAasReachVectors.AddTravelTime(LLink^.TravelTime, LSettings.RsFallDamage5)
      else if Context.Physics.FallDelta(LLimit) > LSettings.PhysFallDelta10 then
        LLink^.TravelTime := TAasReachVectors.AddTravelTime(LLink^.TravelTime, LSettings.RsFallDamage10);
    end;
    Context.Heap.Push(AArea1, LLink);
    if (LTravelType and TRAVELTYPE_MASK) = TRAVEL_JUMP then
      Inc(Context.Counters^.Jump)
    else
      Inc(Context.Counters^.WalkOffLedge);
  end;
  Result := False;
end;

end.
