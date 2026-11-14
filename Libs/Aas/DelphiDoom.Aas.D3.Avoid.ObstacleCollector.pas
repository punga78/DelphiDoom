{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - obstacle avoidance, finding obstacles    }
{                                                                              }
{  Port of GetObstacles (AI_pathing.cpp), Doom 3 GPL Source Code. The choice of  }
{  the entities that are obstacles is the game's (IAvoidBody); the boxes, the   }
{  windings and the walls of the AAS are here.                                  }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.Avoid.ObstacleCollector;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.Aas.D3.Intf, DelphiDoom.Aas.D3.Avoid.Intf,
  DelphiDoom.Aas.D3.Avoid.ObstacleSet;

type
  /// <summary>
  ///   Makes the obstacles around the path of a body: a 2D winding for every box that is in the way (its silhouette
  ///   seen along gravity, expanded for the box of the body), and, if there is any, the walls of the AAS around the
  ///   area as obstacles too. The navigator is not owned
  /// </summary>
  TAvoidObstacleCollector = class
  strict private
    FNavigator: IAasNavigator;
  public
    constructor Create(const ANavigator: IAasNavigator);
    /// <summary>
    ///   Fills the set (which is cleared first) and the bounds of the search; returns how many obstacles there are.
    ///   None if no box is in the way, or if the straight path from the start to the goal crosses none of them:
    ///   then the path should be through valid AAS space (GetObstacles)
    /// </summary>
    function Collect(const ABody: IAvoidBody; const AAreaNum: Integer; const AStartPos, ASeekPos: TGeoVec3;
      const AObstacles: TAvoidObstacleSet; out AClipBounds: TGeoBounds): Integer;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.Geometry.Box, DelphiDoom.MapFile.Aas.Types,
  DelphiDoom.Aas.D3.Avoid.Types, DelphiDoom.Aas.D3.Avoid.Obstacle;

const
  CBoxEpsilon: Single = 1.0;
  CHalf: Single = 0.5;

function ToVec2(const AVector: TGeoVec3): TIdVec2;
begin
  Result := TIdVec2.Create(AVector.X, AVector.Y);
end;

{ TAvoidObstacleCollector }

constructor TAvoidObstacleCollector.Create(const ANavigator: IAasNavigator);
begin
  inherited Create;
  FNavigator := ANavigator;
end;

function TAvoidObstacleCollector.Collect(const ABody: IAvoidBody; const AAreaNum: Integer; const AStartPos,
  ASeekPos: TGeoVec3; const AObstacles: TAvoidObstacleSet; out AClipBounds: TGeoBounds): Integer;
var
  LIndex, LNumVerts, LNumWallEdges, LBlockingObstacle, LBlockingEdgeNum: Integer;
  LVerts, LLastVerts, LNextVerts: array[0..1] of Integer;
  LWallEdges: TArray<Integer>;
  LStepHeight, LHeadHeight, LMin, LMax, LHalfBoundsSize, LBlockingScale: Single;
  LSeekDelta, LStart, LEnd, LNextStart, LNextEnd, LGravity, LNegGravity: TGeoVec3;
  LSilVerts: array[0..31] of TGeoVec3;
  LExpMins, LExpMaxs, LEdgeDir, LEdgeNormal, LNextEdgeDir, LNextEdgeNormal, LLastEdgeNormal, LPoint: TIdVec2;
  LBounds: TGeoBounds;
  LModels: TArray<TAvoidClipModel>;
  LModel: TAvoidClipModel;
  LBox: TGeoBox;
  LObstacle: TAvoidObstacle;
  LJ: Integer;
begin
  AObstacles.Clear;
  LSeekDelta := ASeekPos - AStartPos;
  LBounds := ABody.GetBounds;
  LExpMins := ToVec2(LBounds.Mins) - TIdVec2.Create(CBoxEpsilon, CBoxEpsilon);
  LExpMaxs := ToVec2(LBounds.Maxs) + TIdVec2.Create(CBoxEpsilon, CBoxEpsilon);

  LGravity := ABody.GetGravityNormal;
  LNegGravity := -LGravity;
  ABody.GetAbsBounds.AxisProjection(LNegGravity, LStepHeight, LHeadHeight);
  LStepHeight := LStepHeight + FNavigator.GetSettings.MaxStepHeight;

  // clip bounds for the obstacle search space
  AClipBounds.Mins := AStartPos;
  AClipBounds.Maxs := AStartPos;
  AClipBounds.AddPoint(ASeekPos);
  AClipBounds.ExpandSelf(AVOID_MAX_OBSTACLE_RADIUS);

  // find all obstacles touching the clip bounds
  LModels := ABody.ObstaclesTouchingBounds(AClipBounds);

  for LIndex := 0 to High(LModels) do
  begin
    if AObstacles.Count >= AVOID_MAX_OBSTACLES then
      Break;
    LModel := LModels[LIndex];

    // check if we can step over the object
    LModel.AbsBounds.AxisProjection(LNegGravity, LMin, LMax);
    if (LMax < LStepHeight) or (LMin > LHeadHeight) then
      // can step over this one
      Continue;

    // project a box containing the obstacle onto the floor plane
    LBox := TGeoBox.Make(LModel.Bounds, LModel.Origin, LModel.Axis);
    LNumVerts := LBox.GetParallelProjectionSilhouetteVerts(LGravity, LSilVerts);

    // create a 2D winding for the obstacle
    LObstacle := AObstacles.Add;
    for LJ := 0 to LNumVerts - 1 do
      LObstacle.Winding.AddPoint(ToVec2(LSilVerts[LJ]));

    // expand the 2D winding for collision with a 2D box
    LObstacle.Winding.ExpandForAxialBox(LExpMins, LExpMaxs);
    LObstacle.UpdateBounds;
    LObstacle.EntityId := LModel.EntityId;
  end;

  // if there are no dynamic obstacles the path should be through valid AAS space
  if AObstacles.Count = 0 then
    Exit(0);

  // if the current path doesn't intersect any dynamic obstacles the path should be through valid AAS space
  if AObstacles.PointInsideObstacle(ToVec2(AStartPos)) = -1 then
  begin
    LBlockingObstacle := -1;
    LBlockingEdgeNum := -1;
    if not AObstacles.GetFirstBlockingObstacle(-1, ToVec2(AStartPos), ToVec2(LSeekDelta), LBlockingScale,
      LBlockingObstacle, LBlockingEdgeNum) then
      Exit(0);
  end;

  // create obstacles for AAS walls
  LHalfBoundsSize := (LExpMaxs.X - LExpMins.X) * CHalf;

  SetLength(LWallEdges, AVOID_MAX_AAS_WALL_EDGES);
  LNumWallEdges := FNavigator.GetWallEdges(AAreaNum, AClipBounds, TFL_WALK, LWallEdges, AVOID_MAX_AAS_WALL_EDGES);
  FNavigator.SortWallEdges(LWallEdges, LNumWallEdges);

  LLastVerts[0] := 0;
  LLastVerts[1] := 0;
  LLastEdgeNormal.Zero;
  LNextVerts[0] := 0;
  LNextVerts[1] := 0;
  LNextEdgeNormal.Zero;
  LIndex := 0;
  while (LIndex < LNumWallEdges) and (AObstacles.Count < AVOID_MAX_OBSTACLES) do
  begin
    FNavigator.GetEdge(LWallEdges[LIndex], LStart, LEnd);
    FNavigator.GetEdgeVertexNumbers(LWallEdges[LIndex], LVerts[0], LVerts[1]);
    LEdgeDir := ToVec2(LEnd) - ToVec2(LStart);
    LEdgeDir.Normalize;
    LEdgeNormal.X := LEdgeDir.Y;
    LEdgeNormal.Y := -LEdgeDir.X;
    if LIndex < LNumWallEdges - 1 then
    begin
      FNavigator.GetEdge(LWallEdges[LIndex + 1], LNextStart, LNextEnd);
      FNavigator.GetEdgeVertexNumbers(LWallEdges[LIndex + 1], LNextVerts[0], LNextVerts[1]);
      LNextEdgeDir := ToVec2(LNextEnd) - ToVec2(LNextStart);
      LNextEdgeDir.Normalize;
      LNextEdgeNormal.X := LNextEdgeDir.Y;
      LNextEdgeNormal.Y := -LNextEdgeDir.X;
    end;

    LObstacle := AObstacles.Add;
    LObstacle.Winding.AddPoint(ToVec2(LEnd));
    LObstacle.Winding.AddPoint(ToVec2(LStart));
    LObstacle.Winding.AddPoint(ToVec2(LStart) - LEdgeDir - LEdgeNormal * LHalfBoundsSize);
    LObstacle.Winding.AddPoint(ToVec2(LEnd) + LEdgeDir - LEdgeNormal * LHalfBoundsSize);
    if LLastVerts[1] = LVerts[0] then
    begin
      LPoint := LObstacle.Winding[2] - LLastEdgeNormal * LHalfBoundsSize;
      LObstacle.Winding[2] := LPoint;
    end
    else
    begin
      LPoint := LObstacle.Winding[1] - LEdgeDir;
      LObstacle.Winding[1] := LPoint;
    end;
    if LVerts[1] = LNextVerts[0] then
    begin
      LPoint := LObstacle.Winding[3] - LNextEdgeNormal * LHalfBoundsSize;
      LObstacle.Winding[3] := LPoint;
    end
    else
    begin
      LPoint := LObstacle.Winding[0] + LEdgeDir;
      LObstacle.Winding[0] := LPoint;
    end;
    LObstacle.UpdateBounds;
    LObstacle.EntityId := AVOID_NO_ENTITY;

    LLastVerts[0] := LVerts[0];
    LLastVerts[1] := LVerts[1];
    LLastEdgeNormal := LEdgeNormal;
    Inc(LIndex);
  end;

  Result := AObstacles.Count;
end;

end.
