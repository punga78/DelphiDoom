{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - walking and flying paths                }
{                                                                              }
{  Port of idAASLocal::EdgeSplitPoint, FloorEdgeSplitPoint, WalkPathValid,     }
{  SubSampleWalkPath, WalkPathToGoal, FlyPathValid, SubSampleFlyPath and       }
{  FlyPathToGoal (AAS_pathing.cpp), Doom 3 GPL Source Code.                    }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.PathFinder;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane, DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Aas.Intf,
  DelphiDoom.Aas.D3.Types, DelphiDoom.Aas.D3.Topology, DelphiDoom.Aas.D3.Router;

type
  /// <summary>
  ///   The point where an actor should move to follow the route towards a goal, on the floor of the
  ///   areas (walking) or in a straight line (flying). The topology, the router, the sampler and the
  ///   log are not owned
  /// </summary>
  TAasPathFinder = class
  strict private
    FTopology: TAasTopology;
    FRouter: TAasRouter;
    FSampler: IAasSampler;
    FLog: IIdLibLog;
    function EdgeSplitPoint(out ASplit: TGeoVec3; const AEdgeNum: Integer; const APlane: TGeoPlane): Boolean;
    function FloorEdgeSplitPoint(var ABestSplit: TGeoVec3; const AAreaNum: Integer; const APathPlane,
      AFrontPlane: TGeoPlane; const AClosest: Boolean): Boolean;
    function SubSampleWalkPath(const AAreaNum: Integer; const AOrigin, AStart, AEnd: TGeoVec3;
      const ATravelFlags: Integer; var AEndAreaNum: Integer): TGeoVec3;
    function SubSampleFlyPath(const AAreaNum: Integer; const AOrigin, AStart, AEnd: TGeoVec3;
      const ATravelFlags: Integer; var AEndAreaNum: Integer): TGeoVec3;
  public
    constructor Create(const ATopology: TAasTopology; const ARouter: TAasRouter; const ASampler: IAasSampler;
      const ALog: IIdLibLog);
    /// <summary>True if one can walk in a straight line between the origin and the goal origin</summary>
    function WalkPathValid(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum: Integer;
      const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer; out AEndPos: TGeoVec3;
      out AEndAreaNum: Integer): Boolean;
    function WalkPathToGoal(out APath: TAasPath; const AAreaNum: Integer; const AOrigin: TGeoVec3;
      const AGoalAreaNum: Integer; const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer): Boolean;
    /// <summary>True if one can fly in a straight line between the origin and the goal origin</summary>
    function FlyPathValid(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum: Integer;
      const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer; out AEndPos: TGeoVec3;
      out AEndAreaNum: Integer): Boolean;
    function FlyPathToGoal(out APath: TAasPath; const AAreaNum: Integer; const AOrigin: TGeoVec3;
      const AGoalAreaNum: Integer; const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.FloatMath, DelphiDoom.MapFile.Aas.Types, DelphiDoom.MapFile.Aas.Area,
  DelphiDoom.MapFile.Aas.Reachability, DelphiDoom.MapFile.Aas.Trace, DelphiDoom.MapFile.Aas.AasFile;

resourcestring
  SLocalMinimumWalk = 'idAASLocal::WalkPathToGoal: local routing minimum going from area %d to area %d';
  SLocalMinimumFly = 'idAASLocal::FlyPathToGoal: local routing minimum going from area %d to area %d';
  SEdgeOutOfRange = 'AAS path: edge %d is not in the file';

const
  CMaxWalkPathDistance: Single = 500.0;
  CWalkPathSampleDistance: Single = 8.0;
  CMaxFlyPathDistance: Single = 500.0;
  CFlyPathSampleDistance: Single = 8.0;
  // -0.1f, 0.5f and 0.2f
  CMinusTenth: Single = -0.100000001490116119384765625;
  CHalf: Single = 0.5;
  CFifth: Single = 0.20000000298023223876953125;

{ TAasPathFinder }

constructor TAasPathFinder.Create(const ATopology: TAasTopology; const ARouter: TAasRouter;
  const ASampler: IAasSampler; const ALog: IIdLibLog);
begin
  inherited Create;
  FTopology := ATopology;
  FRouter := ARouter;
  FSampler := ASampler;
  FLog := ALog;
end;

function TAasPathFinder.EdgeSplitPoint(out ASplit: TGeoVec3; const AEdgeNum: Integer;
  const APlane: TGeoPlane): Boolean;
var
  LEdge: TAasEdge;
  LV1, LV2, LDelta: TGeoVec3;
  LD1, LD2, LRatio, LDifference: Single;
begin
  if (AEdgeNum < 0) or (AEdgeNum >= FTopology.AasFile.NumEdges) then
    raise EAasRoutingException.Create(Format(SEdgeOutOfRange, [AEdgeNum]));
  LEdge := FTopology.AasFile.Edges[AEdgeNum];
  LV1 := FTopology.AasFile.Vertices[LEdge.VertexNum[0]];
  LV2 := FTopology.AasFile.Vertices[LEdge.VertexNum[1]];
  LD1 := LV1.Dot(APlane.Normal);
  LD1 := LD1 - APlane.Dist;
  LD2 := LV2.Dot(APlane.Normal);
  LD2 := LD2 - APlane.Dist;

  if TGeoMath.FloatSignBitSet(LD1) = TGeoMath.FloatSignBitSet(LD2) then
    Exit(False);
  LDifference := LD1 - LD2;
  LRatio := LD1 / LDifference;
  LDelta := LV2 - LV1;
  LDelta := LDelta * LRatio;
  ASplit := LV1 + LDelta;
  Result := True;
end;

function TAasPathFinder.FloorEdgeSplitPoint(var ABestSplit: TGeoVec3; const AAreaNum: Integer; const APathPlane,
  AFrontPlane: TGeoPlane; const AClosest: Boolean): Boolean;
var
  LIndex, LEdgeIndex, LFaceNum, LEdgeNum: Integer;
  LArea: TAasArea;
  LFace: TAasFace;
  LSplit: TGeoVec3;
  LDist, LBestDist: Single;
begin
  if AClosest then
    LBestDist := CMaxWalkPathDistance
  else
    LBestDist := CMinusTenth;

  LArea := FTopology.Areas[AAreaNum];

  for LIndex := 0 to LArea.NumFaces - 1 do
  begin
    LFaceNum := FTopology.AasFile.FaceIndex[LArea.FirstFace + LIndex];
    LFace := FTopology.AasFile.Faces[Abs(LFaceNum)];

    if (LFace.Flags and FACE_FLOOR) = 0 then
      Continue;

    for LEdgeIndex := 0 to LFace.NumEdges - 1 do
    begin
      LEdgeNum := FTopology.AasFile.EdgeIndex[LFace.FirstEdge + LEdgeIndex];

      if not EdgeSplitPoint(LSplit, Abs(LEdgeNum), APathPlane) then
        Continue;
      LDist := AFrontPlane.Distance(LSplit);
      if AClosest then
      begin
        if (LDist >= CMinusTenth) and (LDist < LBestDist) then
        begin
          LBestDist := LDist;
          ABestSplit := LSplit;
        end;
      end
      else
      begin
        if LDist > LBestDist then
        begin
          LBestDist := LDist;
          ABestSplit := LSplit;
        end;
      end;
    end;
  end;

  if AClosest then
    Result := LBestDist < CMaxWalkPathDistance
  else
    Result := LBestDist > CMinusTenth;
end;

function TAasPathFinder.WalkPathValid(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum: Integer;
  const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer; out AEndPos: TGeoVec3;
  out AEndAreaNum: Integer): Boolean;
var
  LCurAreaNum, LLastAreaIndex, LReachIndex: Integer;
  LLastAreas: array[0..3] of Integer;
  LPathPlane, LFrontPlane, LFarPlane: TGeoPlane;
  LReach: TAasReachability;
  LReaches: TArray<TAasReachability>;
  LFound: Boolean;
  LGravityDir, LP, LDir, LDirectionEnd, LDirectionP, LDelta: TGeoVec3;
  LTemp, LStepHeight, LEpsilon, LLength: Single;
  LToArea: TAasArea;
begin
  LLastAreas[0] := AAreaNum;
  LLastAreas[1] := AAreaNum;
  LLastAreas[2] := AAreaNum;
  LLastAreas[3] := AAreaNum;
  LLastAreaIndex := 0;
  LGravityDir := FTopology.AasFile.Settings.GravityDir;

  LDelta := AGoalOrigin - AOrigin;
  LDelta := LDelta.Cross(LGravityDir);
  LPathPlane.SetNormal(LDelta);
  LPathPlane.NormalizeSelf;
  LPathPlane.FitThroughPoint(AOrigin);

  LDelta := AGoalOrigin - AOrigin;
  LFrontPlane.SetNormal(LDelta);
  LFrontPlane.NormalizeSelf;
  LFrontPlane.FitThroughPoint(AOrigin);

  LFarPlane.SetNormal(LFrontPlane.Normal);
  LFarPlane.FitThroughPoint(AGoalOrigin);

  LCurAreaNum := AAreaNum;
  AEndAreaNum := 0;
  AEndPos := AGoalOrigin;

  while True do
  begin
    // find the furthest floor face split point on the path
    if not FloorEdgeSplitPoint(AEndPos, LCurAreaNum, LPathPlane, LFrontPlane, False) then
      AEndPos := AOrigin;

    // if we found a point near or further than the goal we're done
    if LFarPlane.Distance(AEndPos) > -CHalf then
      Break;

    // if we reached the goal area we're done
    if LCurAreaNum = AGoalAreaNum then
      Break;

    LTemp := LFrontPlane.Normal.Dot(AEndPos);
    LFrontPlane.SetDist(LTemp);

    LReaches := FTopology.Reach[LCurAreaNum];
    LFound := False;
    LReach := nil;
    for LReachIndex := 0 to Length(LReaches) - 1 do
    begin
      LReach := LReaches[LReachIndex];
      if LReach.TravelType <> TFL_WALK then
        Continue;

      // if the reachability goes back to a previous area
      if (LReach.ToAreaNum = LLastAreas[0]) or (LReach.ToAreaNum = LLastAreas[1]) or
        (LReach.ToAreaNum = LLastAreas[2]) or (LReach.ToAreaNum = LLastAreas[3]) then
        Continue;

      LToArea := FTopology.Areas[LReach.ToAreaNum];

      // if undesired travel flags are required to travel through the area
      if (LToArea.TravelFlags and not ATravelFlags) <> 0 then
        Continue;

      // don't optimize through an area near a ledge
      if (LToArea.Flags and AREA_LEDGE) <> 0 then
        Continue;

      // find the closest floor face split point on the path
      if not FloorEdgeSplitPoint(LP, LReach.ToAreaNum, LPathPlane, LFrontPlane, True) then
        Continue;

      // direction parallel to gravity
      LTemp := LGravityDir.Dot(AEndPos);
      LDirectionEnd := LGravityDir * LTemp;
      LTemp := LGravityDir.Dot(LP);
      LDirectionP := LGravityDir * LTemp;
      LDir := LDirectionEnd - LDirectionP;
      LStepHeight := FTopology.AasFile.Settings.MaxStepHeight;
      LStepHeight := LStepHeight * LStepHeight;
      if LDir.LengthSqr > LStepHeight then
        Continue;

      // direction orthogonal to gravity
      LDelta := AEndPos - LP;
      LDir := LDelta - LDir;
      LEpsilon := CFifth * CFifth;
      LLength := LDir.LengthSqr;
      if LLength > LEpsilon then
        Continue;

      LFound := True;
      Break;
    end;

    if not LFound then
      Exit(False);

    LLastAreas[LLastAreaIndex] := LCurAreaNum;
    LLastAreaIndex := (LLastAreaIndex + 1) and 3;

    LCurAreaNum := LReach.ToAreaNum;
  end;

  AEndAreaNum := LCurAreaNum;
  Result := True;
end;

function TAasPathFinder.SubSampleWalkPath(const AAreaNum: Integer; const AOrigin, AStart, AEnd: TGeoVec3;
  const ATravelFlags: Integer; var AEndAreaNum: Integer): TGeoVec3;
var
  LIndex, LNumSamples, LCurAreaNum: Integer;
  LDir, LPoint, LNextPoint, LEndPos, LDelta: TGeoVec3;
  LLength, LFraction, LMaxDistance: Single;
begin
  LDir := AEnd - AStart;
  LLength := LDir.Length;
  LLength := LLength / CWalkPathSampleDistance;
  LNumSamples := Trunc(LLength) + 1;

  LMaxDistance := CMaxWalkPathDistance * CMaxWalkPathDistance;
  LPoint := AStart;
  for LIndex := 1 to LNumSamples - 1 do
  begin
    LFraction := Single(LIndex) / Single(LNumSamples);
    LNextPoint := LDir * LFraction;
    LNextPoint := AStart + LNextPoint;
    LDelta := LPoint - LNextPoint;
    if LDelta.LengthSqr > LMaxDistance then
      Exit(LPoint);
    if not WalkPathValid(AAreaNum, AOrigin, 0, LNextPoint, ATravelFlags, LEndPos, LCurAreaNum) then
      Exit(LPoint);
    LPoint := LNextPoint;
    AEndAreaNum := LCurAreaNum;
  end;
  Result := LPoint;
end;

function TAasPathFinder.WalkPathToGoal(out APath: TAasPath; const AAreaNum: Integer; const AOrigin: TGeoVec3;
  const AGoalAreaNum: Integer; const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer): Boolean;
var
  LIndex, LTravelTime, LCurAreaNum, LLastAreaIndex, LEndAreaNum: Integer;
  LLastAreas: array[0..3] of Integer;
  LReach: TAasReachability;
  LEndPos, LDelta: TGeoVec3;
  LMaxDistance: Single;
begin
  APath.Kind := PATHTYPE_WALK;
  APath.MoveGoal := AOrigin;
  APath.MoveAreaNum := AAreaNum;
  APath.SecondaryGoal := AOrigin;
  APath.Reachability := nil;

  if AAreaNum = AGoalAreaNum then
  begin
    APath.MoveGoal := AGoalOrigin;
    Exit(True);
  end;

  LLastAreas[0] := AAreaNum;
  LLastAreas[1] := AAreaNum;
  LLastAreas[2] := AAreaNum;
  LLastAreas[3] := AAreaNum;
  LLastAreaIndex := 0;
  LMaxDistance := CMaxWalkPathDistance * CMaxWalkPathDistance;

  LCurAreaNum := AAreaNum;
  LReach := nil;

  for LIndex := 0 to AAS_MAX_PATH_ITERATIONS - 1 do
  begin
    if not FRouter.RouteToGoalArea(LCurAreaNum, APath.MoveGoal, AGoalAreaNum, ATravelFlags, LTravelTime, LReach) then
      Break;

    if not Assigned(LReach) then
      Exit(False);

    // no need to check through the first area
    if AAreaNum <> LCurAreaNum then
    begin
      // only optimize a limited distance ahead
      LDelta := LReach.StartPoint - AOrigin;
      if LDelta.LengthSqr > LMaxDistance then
      begin
        APath.MoveGoal := SubSampleWalkPath(AAreaNum, AOrigin, APath.MoveGoal, LReach.StartPoint, ATravelFlags,
          APath.MoveAreaNum);
        Exit(True);
      end;

      if not WalkPathValid(AAreaNum, AOrigin, 0, LReach.StartPoint, ATravelFlags, LEndPos, LEndAreaNum) then
      begin
        APath.MoveGoal := SubSampleWalkPath(AAreaNum, AOrigin, APath.MoveGoal, LReach.StartPoint, ATravelFlags,
          APath.MoveAreaNum);
        Exit(True);
      end;
    end;

    APath.MoveGoal := LReach.StartPoint;
    APath.MoveAreaNum := LCurAreaNum;

    if LReach.TravelType <> TFL_WALK then
      Break;

    if not WalkPathValid(AAreaNum, AOrigin, 0, LReach.EndPoint, ATravelFlags, LEndPos, LEndAreaNum) then
      Exit(True);

    APath.MoveGoal := LReach.EndPoint;
    APath.MoveAreaNum := LReach.ToAreaNum;

    if LReach.ToAreaNum = AGoalAreaNum then
    begin
      if not WalkPathValid(AAreaNum, AOrigin, 0, AGoalOrigin, ATravelFlags, LEndPos, LEndAreaNum) then
      begin
        APath.MoveGoal := SubSampleWalkPath(AAreaNum, AOrigin, APath.MoveGoal, AGoalOrigin, ATravelFlags,
          APath.MoveAreaNum);
        Exit(True);
      end;
      APath.MoveGoal := AGoalOrigin;
      APath.MoveAreaNum := AGoalAreaNum;
      Exit(True);
    end;

    LLastAreas[LLastAreaIndex] := LCurAreaNum;
    LLastAreaIndex := (LLastAreaIndex + 1) and 3;

    LCurAreaNum := LReach.ToAreaNum;

    if (LCurAreaNum = LLastAreas[0]) or (LCurAreaNum = LLastAreas[1]) or (LCurAreaNum = LLastAreas[2]) or
      (LCurAreaNum = LLastAreas[3]) then
    begin
      if Assigned(FLog) then
        FLog.Warning(Format(SLocalMinimumWalk, [AAreaNum, AGoalAreaNum]));
      Break;
    end;
  end;

  if not Assigned(LReach) then
    Exit(False);

  case LReach.TravelType of
    TFL_WALKOFFLEDGE:
      begin
        APath.Kind := PATHTYPE_WALKOFFLEDGE;
        APath.SecondaryGoal := LReach.EndPoint;
        APath.Reachability := LReach;
      end;
    TFL_BARRIERJUMP:
      begin
        APath.Kind := APath.Kind or PATHTYPE_BARRIERJUMP;
        APath.SecondaryGoal := LReach.EndPoint;
        APath.Reachability := LReach;
      end;
    TFL_JUMP:
      begin
        APath.Kind := APath.Kind or PATHTYPE_JUMP;
        APath.SecondaryGoal := LReach.EndPoint;
        APath.Reachability := LReach;
      end;
  end;

  Result := True;
end;

function TAasPathFinder.FlyPathValid(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum: Integer;
  const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer; out AEndPos: TGeoVec3;
  out AEndAreaNum: Integer): Boolean;
var
  LTrace: TAasTrace;
begin
  LTrace := TAasTrace.Init;
  FSampler.Trace(LTrace, AOrigin, AGoalOrigin);

  AEndPos := LTrace.EndPos;
  AEndAreaNum := LTrace.LastAreaNum;

  Result := LTrace.Fraction >= 1.0;
end;

function TAasPathFinder.SubSampleFlyPath(const AAreaNum: Integer; const AOrigin, AStart, AEnd: TGeoVec3;
  const ATravelFlags: Integer; var AEndAreaNum: Integer): TGeoVec3;
var
  LIndex, LNumSamples, LCurAreaNum: Integer;
  LDir, LPoint, LNextPoint, LEndPos, LDelta: TGeoVec3;
  LLength, LFraction, LMaxDistance: Single;
begin
  LDir := AEnd - AStart;
  LLength := LDir.Length;
  LLength := LLength / CFlyPathSampleDistance;
  LNumSamples := Trunc(LLength) + 1;

  LMaxDistance := CMaxFlyPathDistance * CMaxFlyPathDistance;
  LPoint := AStart;
  for LIndex := 1 to LNumSamples - 1 do
  begin
    LFraction := Single(LIndex) / Single(LNumSamples);
    LNextPoint := LDir * LFraction;
    LNextPoint := AStart + LNextPoint;
    LDelta := LPoint - LNextPoint;
    if LDelta.LengthSqr > LMaxDistance then
      Exit(LPoint);
    if not FlyPathValid(AAreaNum, AOrigin, 0, LNextPoint, ATravelFlags, LEndPos, LCurAreaNum) then
      Exit(LPoint);
    LPoint := LNextPoint;
    AEndAreaNum := LCurAreaNum;
  end;
  Result := LPoint;
end;

function TAasPathFinder.FlyPathToGoal(out APath: TAasPath; const AAreaNum: Integer; const AOrigin: TGeoVec3;
  const AGoalAreaNum: Integer; const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer): Boolean;
var
  LIndex, LTravelTime, LCurAreaNum, LLastAreaIndex, LEndAreaNum: Integer;
  LLastAreas: array[0..3] of Integer;
  LReach: TAasReachability;
  LEndPos, LDelta: TGeoVec3;
  LMaxDistance: Single;
begin
  APath.Kind := PATHTYPE_WALK;
  APath.MoveGoal := AOrigin;
  APath.MoveAreaNum := AAreaNum;
  APath.SecondaryGoal := AOrigin;
  APath.Reachability := nil;

  if AAreaNum = AGoalAreaNum then
  begin
    APath.MoveGoal := AGoalOrigin;
    Exit(True);
  end;

  LLastAreas[0] := AAreaNum;
  LLastAreas[1] := AAreaNum;
  LLastAreas[2] := AAreaNum;
  LLastAreas[3] := AAreaNum;
  LLastAreaIndex := 0;
  LMaxDistance := CMaxFlyPathDistance * CMaxFlyPathDistance;

  LCurAreaNum := AAreaNum;
  LReach := nil;

  for LIndex := 0 to AAS_MAX_PATH_ITERATIONS - 1 do
  begin
    if not FRouter.RouteToGoalArea(LCurAreaNum, APath.MoveGoal, AGoalAreaNum, ATravelFlags, LTravelTime, LReach) then
      Break;

    if not Assigned(LReach) then
      Exit(False);

    // no need to check through the first area (SUBSAMPLE_FLY_PATH is 0: the path is not subsampled)
    if AAreaNum <> LCurAreaNum then
    begin
      LDelta := LReach.StartPoint - AOrigin;
      if LDelta.LengthSqr > LMaxDistance then
        Exit(True);

      if not FlyPathValid(AAreaNum, AOrigin, 0, LReach.StartPoint, ATravelFlags, LEndPos, LEndAreaNum) then
        Exit(True);
    end;

    APath.MoveGoal := LReach.StartPoint;
    APath.MoveAreaNum := LCurAreaNum;

    if not FlyPathValid(AAreaNum, AOrigin, 0, LReach.EndPoint, ATravelFlags, LEndPos, LEndAreaNum) then
      Exit(True);

    APath.MoveGoal := LReach.EndPoint;
    APath.MoveAreaNum := LReach.ToAreaNum;

    if LReach.ToAreaNum = AGoalAreaNum then
    begin
      if not FlyPathValid(AAreaNum, AOrigin, 0, AGoalOrigin, ATravelFlags, LEndPos, LEndAreaNum) then
        Exit(True);
      APath.MoveGoal := AGoalOrigin;
      APath.MoveAreaNum := AGoalAreaNum;
      Exit(True);
    end;

    LLastAreas[LLastAreaIndex] := LCurAreaNum;
    LLastAreaIndex := (LLastAreaIndex + 1) and 3;

    LCurAreaNum := LReach.ToAreaNum;

    if (LCurAreaNum = LLastAreas[0]) or (LCurAreaNum = LLastAreas[1]) or (LCurAreaNum = LLastAreas[2]) or
      (LCurAreaNum = LLastAreas[3]) then
    begin
      if Assigned(FLog) then
        FLog.Warning(Format(SLocalMinimumFly, [AAreaNum, AGoalAreaNum]));
      Break;
    end;
  end;

  Result := Assigned(LReach);
end;

end.
