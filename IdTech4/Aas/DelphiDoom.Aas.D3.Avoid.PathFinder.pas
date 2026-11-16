{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - obstacle avoidance, the path around      }
{                                                                              }
{  Port of idAI::FindPathAroundObstacles (AI_pathing.cpp), Doom 3 GPL Source    }
{  Code.                                                                        }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Framework\IdLib); the repository as a whole is }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.Avoid.PathFinder;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Aas.D3.Intf, DelphiDoom.Aas.D3.Avoid.Types,
  DelphiDoom.Aas.D3.Avoid.Intf;

type
  /// <summary>
  ///   Finds a path around the dynamic obstacles with a tree of walks clockwise and counter clockwise along the edges
  ///   of the obstacles: gathers the obstacles, pushes the start and the goal out of them, builds the tree, prunes it
  ///   and chooses the shortest path. The navigator and the log are not owned
  /// </summary>
  TAvoidPathFinder = class
  strict private
    FNavigator: IAasNavigator;
    FLog: IIdLibLog;
  public
    /// <summary>
    ///   The navigator gives the areas and the walls (nil, or one without a file: every path is free); the log gets the
    ///   warning of GetPointOutsideObstacles (nil is silent)
    /// </summary>
    constructor Create(const ANavigator: IAasNavigator; const ALog: IIdLibLog = nil);
    /// <summary>
    ///   True if there is a path all the way to the goal; <c>APath.SeekPos</c> is where to go to. False if the start and
    ///   the goal are pushed to the same point but were not near each other. EAasAvoidException for a tree that has no
    ///   path to follow
    /// </summary>
    function FindPathAroundObstacles(const ABody: IAvoidBody; const AStartPos, ASeekPos: TGeoVec3;
      out APath: TAvoidPath): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.Geometry.Bounds, DelphiDoom.MapFile.Aas.Types,
  DelphiDoom.Aas.D3.Avoid.ObstacleSet, DelphiDoom.Aas.D3.Avoid.ObstacleCollector, DelphiDoom.Aas.D3.Avoid.PathTree,
  DelphiDoom.Aas.D3.Avoid.PathOptimizer;

const
  CMaxBoundsHeight: Single = 32.0;
  CSquareOne: Single = 1.0;
  CSquareTwo: Single = 4.0;

{ TAvoidPathFinder }

constructor TAvoidPathFinder.Create(const ANavigator: IAasNavigator; const ALog: IIdLibLog);
begin
  inherited Create;
  FNavigator := ANavigator;
  FLog := ALog;
end;

function TAvoidPathFinder.FindPathAroundObstacles(const ABody: IAvoidBody; const AStartPos, ASeekPos: TGeoVec3;
  out APath: TAvoidPath): Boolean;
var
  LAreaNum, LInsideObstacle, LEdgeNum: Integer;
  LBounds, LClipBounds: TGeoBounds;
  LObstacles: TAvoidObstacleSet;
  LCollector: TAvoidObstacleCollector;
  LTree: TAvoidPathTree;
  LOptimizer: TAvoidPathOptimizer;
  LPoint: TIdVec2;
  LDelta: TIdVec2;
  LBox: TGeoVec3;
begin
  APath.SeekPos := ASeekPos;
  APath.FirstObstacle := AVOID_NO_ENTITY;
  APath.StartPosOutsideObstacles := AStartPos;
  APath.StartPosObstacle := AVOID_NO_ENTITY;
  APath.SeekPosOutsideObstacles := ASeekPos;
  APath.SeekPosObstacle := AVOID_NO_ENTITY;

  if (not Assigned(FNavigator)) or (not Assigned(FNavigator.GetSettings)) then
    Exit(True);

  LBox := FNavigator.GetSettings.BoundingBoxes[0].Maxs;
  LBounds.Maxs := LBox;
  LBounds.Mins := -LBox;
  LBounds.Maxs.Z := CMaxBoundsHeight;

  // get the AAS area number and a valid point inside that area
  LAreaNum := FNavigator.PointReachableAreaNum(APath.StartPosOutsideObstacles, LBounds,
    AREA_REACHABLE_WALK or AREA_REACHABLE_FLY);
  FNavigator.PushPointIntoAreaNum(LAreaNum, APath.StartPosOutsideObstacles);

  LObstacles := TAvoidObstacleSet.Create(FLog);
  try
    LCollector := TAvoidObstacleCollector.Create(FNavigator);
    try
      // get all the nearby obstacles
      LCollector.Collect(ABody, LAreaNum, APath.StartPosOutsideObstacles,
        APath.SeekPosOutsideObstacles, LObstacles, LClipBounds);
    finally
      LCollector.Free;
    end;

    // get a source position outside the obstacles
    LPoint := TIdVec2.Create(APath.StartPosOutsideObstacles.X, APath.StartPosOutsideObstacles.Y);
    LObstacles.GetPointOutsideObstacles(LPoint, LInsideObstacle, LEdgeNum);
    APath.StartPosOutsideObstacles.X := LPoint.X;
    APath.StartPosOutsideObstacles.Y := LPoint.Y;
    if LInsideObstacle <> -1 then
      APath.StartPosObstacle := LObstacles[LInsideObstacle].EntityId;

    // get a goal position outside the obstacles
    LPoint := TIdVec2.Create(APath.SeekPosOutsideObstacles.X, APath.SeekPosOutsideObstacles.Y);
    LObstacles.GetPointOutsideObstacles(LPoint, LInsideObstacle, LEdgeNum);
    APath.SeekPosOutsideObstacles.X := LPoint.X;
    APath.SeekPosOutsideObstacles.Y := LPoint.Y;
    if LInsideObstacle <> -1 then
      APath.SeekPosObstacle := LObstacles[LInsideObstacle].EntityId;

    // if start and destination are pushed to the same point, we don't have a path around the obstacle
    LDelta := TIdVec2.Create(APath.SeekPosOutsideObstacles.X, APath.SeekPosOutsideObstacles.Y) -
      TIdVec2.Create(APath.StartPosOutsideObstacles.X, APath.StartPosOutsideObstacles.Y);
    if LDelta.LengthSqr < CSquareOne then
    begin
      LDelta := TIdVec2.Create(ASeekPos.X, ASeekPos.Y) - TIdVec2.Create(AStartPos.X, AStartPos.Y);
      if LDelta.LengthSqr > CSquareTwo then
        Exit(False);
    end;

    LTree := TAvoidPathTree.Create(LObstacles);
    try
      // build a path tree
      LTree.Build(LClipBounds, TIdVec2.Create(APath.StartPosOutsideObstacles.X, APath.StartPosOutsideObstacles.Y),
        TIdVec2.Create(APath.SeekPosOutsideObstacles.X, APath.SeekPosOutsideObstacles.Y), APath);
      // prune the tree
      LTree.Prune(TIdVec2.Create(APath.SeekPosOutsideObstacles.X, APath.SeekPosOutsideObstacles.Y));
      // find the optimal path
      LOptimizer := TAvoidPathOptimizer.Create(LObstacles);
      try
        Result := LOptimizer.FindOptimalPath(LTree.Root, ABody.GetOrigin.Z, ABody.GetLinearVelocity, APath.SeekPos);
      finally
        LOptimizer.Free;
      end;
    finally
      LTree.Free;
    end;
  finally
    LObstacles.Free;
  end;
end;

end.
