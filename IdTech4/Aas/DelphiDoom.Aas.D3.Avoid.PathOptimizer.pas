{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - obstacle avoidance, the best path        }
{                                                                              }
{  Port of OptimizePath, PathLength and FindOptimalPath (AI_pathing.cpp),      }
{  Doom 3 GPL Source Code. Based on the Doom 3 GPL Source Code (id Software).  }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. This      }
{  unit is derived from the Doom 3 GPL source code and is therefore available  }
{  under the GNU General Public License, version 3 or (at your option) any     }
{  later version, with the additional terms of the Doom 3 Source Code License  }
{  (Reference\doom3\COPYING.txt: preservation of legal notices and             }
{  trademarks, no use of the licensors' names for publicity, warranty          }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.Avoid.PathOptimizer;

interface

uses
  DelphiDoom.IdLib.Math.Vec2, DelphiDoom.Geometry.Vec3, DelphiDoom.Aas.D3.Avoid.PathNode,
  DelphiDoom.Aas.D3.Avoid.ObstacleSet;

type
  /// <summary>
  ///   The points of an optimized path: at most AVOID_MAX_OBSTACLE_PATH. An array that the original does not
  ///   clear: the entries after the last point are zero here
  /// </summary>
  TAvoidOptimizedPath = array[0..63] of TIdVec2;

  /// <summary>
  ///   Chooses the path of a pruned tree and shortens it: shortcuts from one obstacle to another, the shortest
  ///   of the paths that end near the goal, a penalty for a path that goes against the current direction. The
  ///   obstacles are not owned
  /// </summary>
  TAvoidPathOptimizer = class
  strict private
    FObstacles: TAvoidObstacleSet;
  public
    constructor Create(const AObstacles: TAvoidObstacleSet);
    /// <summary>
    ///   The path from the root to the leaf with the shortcuts that no obstacle prevents; the result is the number
    ///   of points. A path with more than AVOID_MAX_OBSTACLE_PATH points is an EAasAvoidException (the original
    ///   writes past the array)
    /// </summary>
    function OptimizePath(const ARoot, ALeafNode: TAvoidPathNode; var APath: TAvoidOptimizedPath): Integer;
    /// <summary>The length of the path, plus 100 if it does not start in the current direction (PathLength)</summary>
    function PathLength(const APath: TAvoidOptimizedPath; const ANumPathPoints: Integer; const ACurDir: TIdVec2): Single;
    /// <summary>
    ///   The place to go to along the best path (the third coordinate is <c>AHeight</c>); True if there is a path all the way to
    ///   the goal (FindOptimalPath)
    /// </summary>
    function FindOptimalPath(const ARoot: TAvoidPathNode; const AHeight: Single; const ACurDir: TGeoVec3;
      out ASeekPos: TGeoVec3): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.FloatMath, DelphiDoom.Aas.D3.Avoid.Types, DelphiDoom.Aas.D3.Avoid.Obstacle;

resourcestring
  SPathTooLong = 'AAS obstacle avoidance: an optimized path with more than %d points';
  SNoFirstStep = 'AAS obstacle avoidance: the path tree has no first step to follow';

const
  CBoxEpsilon: Single = 1.0;
  CHalf: Single = 0.5;
  CTenth: Single = 0.100000001490116119384765625;
  CTinyShortcut: Single = 0.5;
  CTurnPenalty: Single = 100.0;
  CInfinity: Single = 1E30;

{ TAvoidPathOptimizer }

constructor TAvoidPathOptimizer.Create(const AObstacles: TAvoidObstacleSet);
begin
  inherited Create;
  FObstacles := AObstacles;
end;

function TAvoidPathOptimizer.OptimizePath(const ARoot, ALeafNode: TAvoidPathNode;
  var APath: TAvoidOptimizedPath): Integer;
var
  LIndex, LNumPathPoints: Integer;
  LEdgeNums: array[0..1] of Integer;
  LCurNode, LNextNode: TAvoidPathNode;
  LCurPos, LCurDelta: TIdVec2;
  LBounds: array[0..1] of TIdVec2;
  LScale1, LScale2, LCurLength: Single;
  LObstacle: TAvoidObstacle;
begin
  // the entries after the last point keep what the array held (FindOptimalPath reuses one array)
  APath[0] := ARoot.Pos;
  LNumPathPoints := 1;

  LCurNode := ARoot;
  while LCurNode <> ALeafNode do
  begin
    LNextNode := ALeafNode;
    while LNextNode.Parent <> LCurNode do
    begin
      // can only take shortcuts when going from one object to another
      if LNextNode.Obstacle = LCurNode.Obstacle then
      begin
        LNextNode := LNextNode.Parent;
        Continue;
      end;

      LCurPos := LCurNode.Pos;
      LCurDelta := LNextNode.Pos - LCurPos;
      LCurLength := LCurDelta.Length;

      // get bounds for the current movement delta
      LBounds[0] := LCurPos - TIdVec2.Create(CBoxEpsilon, CBoxEpsilon);
      LBounds[1] := LCurPos + TIdVec2.Create(CBoxEpsilon, CBoxEpsilon);
      LBounds[TGeoMath.FloatSignBitNotSet(LCurDelta.X)].X := LBounds[TGeoMath.FloatSignBitNotSet(LCurDelta.X)].X + LCurDelta.X;
      LBounds[TGeoMath.FloatSignBitNotSet(LCurDelta.Y)].Y := LBounds[TGeoMath.FloatSignBitNotSet(LCurDelta.Y)].Y + LCurDelta.Y;

      // test if the shortcut intersects with any obstacles
      LIndex := 0;
      while LIndex < FObstacles.Count do
      begin
        LObstacle := FObstacles[LIndex];
        if (LBounds[0].X > LObstacle.BoundsMax.X) or (LBounds[0].Y > LObstacle.BoundsMax.Y) or
          (LBounds[1].X < LObstacle.BoundsMin.X) or (LBounds[1].Y < LObstacle.BoundsMin.Y) then
        begin
          Inc(LIndex);
          Continue;
        end;
        if LObstacle.Winding.RayIntersection(LCurPos, LCurDelta, LScale1, LScale2, LEdgeNums[0], LEdgeNums[1]) then
        begin
          if (LScale1 >= 0.0) and (LScale1 <= 1.0) and ((LIndex <> LNextNode.Obstacle) or
            (LScale1 * LCurLength < LCurLength - CTinyShortcut)) then
            Break;
          if (LScale2 >= 0.0) and (LScale2 <= 1.0) and ((LIndex <> LNextNode.Obstacle) or
            (LScale2 * LCurLength < LCurLength - CTinyShortcut)) then
            Break;
        end;
        Inc(LIndex);
      end;
      if LIndex >= FObstacles.Count then
        Break;
      LNextNode := LNextNode.Parent;
    end;

    // store the next position along the optimized path
    if LNumPathPoints >= AVOID_MAX_OBSTACLE_PATH then
      raise EAasAvoidException.Create(Format(SPathTooLong, [AVOID_MAX_OBSTACLE_PATH]));
    APath[LNumPathPoints] := LNextNode.Pos;
    Inc(LNumPathPoints);
    LCurNode := LNextNode;
  end;
  Result := LNumPathPoints;
end;

function TAvoidPathOptimizer.PathLength(const APath: TAvoidOptimizedPath; const ANumPathPoints: Integer;
  const ACurDir: TIdVec2): Single;
var
  LIndex: Integer;
  LDelta: TIdVec2;
begin
  // calculate the path length
  Result := 0.0;
  for LIndex := 0 to ANumPathPoints - 2 do
  begin
    LDelta := APath[LIndex + 1] - APath[LIndex];
    Result := Result + LDelta.LengthFast;
  end;
  // add penalty if this path does not go in the current direction
  LDelta := APath[1] - APath[0];
  if ACurDir * LDelta < 0.0 then
    Result := Result + CTurnPenalty;
end;

function TAvoidPathOptimizer.FindOptimalPath(const ARoot: TAvoidPathNode; const AHeight: Single;
  const ACurDir: TGeoVec3; out ASeekPos: TGeoVec3): Boolean;
var
  LNumPathPoints: Integer;
  LNode, LLastNode, LBestNode: TAvoidPathNode;
  LPath: TAvoidOptimizedPath;
  LPathLength, LBestPathLength: Single;
  LPathToGoalExists, LOptimizedPathCalculated: Boolean;
  LCurDir: TIdVec2;
begin
  LCurDir := TIdVec2.Create(ACurDir.X, ACurDir.Y);
  FillChar(LPath, SizeOf(LPath), 0);
  ASeekPos.Zero;
  ASeekPos.Z := AHeight;

  LPathToGoalExists := False;
  LOptimizedPathCalculated := False;

  LBestNode := ARoot;
  LBestPathLength := CInfinity;

  LNode := ARoot;
  while Assigned(LNode) do
  begin
    LPathToGoalExists := LPathToGoalExists or (LNode.Dist < CTenth);

    if LNode.Dist <= LBestNode.Dist then
    begin
      if TGeoMath.Fabs(LNode.Dist - LBestNode.Dist) < CTenth then
      begin
        if not LOptimizedPathCalculated then
        begin
          LNumPathPoints := OptimizePath(ARoot, LBestNode, LPath);
          LBestPathLength := PathLength(LPath, LNumPathPoints, LCurDir);
          ASeekPos.X := LPath[1].X;
          ASeekPos.Y := LPath[1].Y;
        end;

        LNumPathPoints := OptimizePath(ARoot, LNode, LPath);
        LPathLength := PathLength(LPath, LNumPathPoints, LCurDir);

        if LPathLength < LBestPathLength then
        begin
          LBestNode := LNode;
          LBestPathLength := LPathLength;
          ASeekPos.X := LPath[1].X;
          ASeekPos.Y := LPath[1].Y;
        end;
        LOptimizedPathCalculated := True;
      end
      else
      begin
        LBestNode := LNode;
        LOptimizedPathCalculated := False;
      end;
    end;

    if Assigned(LNode.Children[0]) then
      LNode := LNode.Children[0]
    else if Assigned(LNode.Children[1]) then
      LNode := LNode.Children[1]
    else
    begin
      LLastNode := LNode;
      LNode := LNode.Parent;
      while Assigned(LNode) do
      begin
        if Assigned(LNode.Children[1]) and (LNode.Children[1] <> LLastNode) then
        begin
          LNode := LNode.Children[1];
          Break;
        end;
        LLastNode := LNode;
        LNode := LNode.Parent;
      end;
    end;
  end;

  if not LPathToGoalExists then
  begin
    if not Assigned(ARoot.Children[0]) then
      raise EAasAvoidException.Create(SNoFirstStep);
    ASeekPos.X := ARoot.Children[0].Pos.X;
    ASeekPos.Y := ARoot.Children[0].Pos.Y;
  end
  else if not LOptimizedPathCalculated then
  begin
    OptimizePath(ARoot, LBestNode, LPath);
    ASeekPos.X := LPath[1].X;
    ASeekPos.Y := LPath[1].Y;
  end;
  Result := LPathToGoalExists;
end;

end.
