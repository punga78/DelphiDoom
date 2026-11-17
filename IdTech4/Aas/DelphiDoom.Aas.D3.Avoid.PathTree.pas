{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - obstacle avoidance, the path tree        }
{                                                                              }
{  Port of LineIntersectsPath, GetPathNodeDelta, BuildPathTree, PrunePathTree  }
{  and FreePathTree_r (AI_pathing.cpp), Doom 3 GPL Source Code. Based on the   }
{  Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011 id Software   }
{  LLC, a ZeniMax Media company. This unit is derived from the Doom 3 GPL      }
{  source code and is therefore available under the GNU General Public         }
{  License, version 3 or (at your option) any later version, with the          }
{  additional terms of the Doom 3 Source Code License                          }
{  (Reference\doom3\COPYING.txt: preservation of legal notices and             }
{  trademarks, no use of the licensors' names for publicity, warranty          }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.Avoid.PathTree;

interface

uses
  System.Generics.Collections, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.Geometry.Bounds,
  DelphiDoom.Aas.D3.Avoid.Types, DelphiDoom.Aas.D3.Avoid.PathNode, DelphiDoom.Aas.D3.Avoid.ObstacleSet;

type
  /// <summary>
  ///   The tree of the paths from a start to a goal around the obstacles: at every obstacle that blocks a path the
  ///   tree splits in a walk clockwise and one counter clockwise along the edges. The tree is made, then pruned to
  ///   the nodes nearest to the goal. The number of nodes that are alive is limited to AVOID_MAX_PATH_NODES.
  ///   The tree owns its nodes; the obstacles are not owned
  /// </summary>
  TAvoidPathTree = class
  strict private
    FObstacles: TAvoidObstacleSet;
    FNodes: TObjectList<TAvoidPathNode>;
    FRoot: TAvoidPathNode;
    FAllocCount: Integer;
    function NewNode: TAvoidPathNode;
    procedure FreeSubtree(const ANode: TAvoidPathNode);
    function LineIntersectsPath(const AStart, AEnd: TIdVec2; const ANode: TAvoidPathNode): Boolean;
  public
    constructor Create(const AObstacles: TAvoidObstacleSet);
    destructor Destroy; override;
    /// <summary>The root of the tree built by <c>Build</c></summary>
    property Root: TAvoidPathNode read FRoot;
    /// <summary>How many nodes are alive (pathNodeAllocator.GetAllocCount)</summary>
    property AllocCount: Integer read FAllocCount;
    /// <summary>
    ///   Finds where the movement of the node goes and whether it is worth following: False if the same edge was
    ///   already walked by a node nearer to the root (GetPathNodeDelta). An obstacle without edges that
    ///   can be walked is an EAasAvoidException
    /// </summary>
    function GetPathNodeDelta(const ANode: TAvoidPathNode; const ASeekPos: TIdVec2; const ABlocked: Boolean): Boolean;
    /// <summary>
    ///   Makes the tree from the start to the goal inside the clip bounds. <c>APath.FirstObstacle</c> is set to the
    ///   first obstacle that blocks a path if it was not set (BuildPathTree)
    /// </summary>
    procedure Build(const AClipBounds: TGeoBounds; const AStartPos, ASeekPos: TIdVec2; var APath: TAvoidPath);
    /// <summary>Cuts every path after its node nearest to the goal (PrunePathTree)</summary>
    procedure Prune(const ASeekPos: TIdVec2);
    /// <summary>Gives back all the nodes that are alive (FreePathTree_r of the root); the tree is empty after it</summary>
    procedure FreeTree;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Winding2D, DelphiDoom.Geometry.FloatMath,
  DelphiDoom.Aas.D3.Avoid.Obstacle;

resourcestring
  SObstacleNotInList = 'AAS obstacle avoidance: the path tree names obstacle %d, which the list does not hold';
  SNoEdgeToWalk = 'AAS obstacle avoidance: the winding of obstacle %d has no edge to walk along';

const
  CBestNumNodesStart = AVOID_MAX_OBSTACLE_PATH;
  // CLIP_BOUNDS_EPSILON and the float constants of the original
  CClipBoundsEpsilon: Single = 10.0;
  CTinyEdge: Single = 0.00999999977648258209228515625;

{ TAvoidPathTree }

constructor TAvoidPathTree.Create(const AObstacles: TAvoidObstacleSet);
begin
  inherited Create;
  FObstacles := AObstacles;
  FNodes := TObjectList<TAvoidPathNode>.Create(True);
end;

destructor TAvoidPathTree.Destroy;
begin
  FNodes.Free;
  inherited Destroy;
end;

function TAvoidPathTree.NewNode: TAvoidPathNode;
begin
  Result := TAvoidPathNode.Create;
  FNodes.Add(Result);
  Inc(FAllocCount);
end;

procedure TAvoidPathTree.FreeSubtree(const ANode: TAvoidPathNode);
begin
  if Assigned(ANode.Children[0]) then
    FreeSubtree(ANode.Children[0]);
  if Assigned(ANode.Children[1]) then
    FreeSubtree(ANode.Children[1]);
  // the memory stays with the tree until it is freed; the count is the one of the original
  Dec(FAllocCount);
end;

function TAvoidPathTree.LineIntersectsPath(const AStart, AEnd: TIdVec2; const ANode: TAvoidPathNode): Boolean;
var
  LD0, LD1, LD2, LD3: Single;
  LPlane1, LPlane2: TGeoVec3;
  LNode: TAvoidPathNode;
begin
  LNode := ANode;
  LPlane1 := TGeoWinding2D.Plane2DFromPoints(AStart, AEnd);
  LD0 := LPlane1.X * LNode.Pos.X + LPlane1.Y * LNode.Pos.Y + LPlane1.Z;
  while Assigned(LNode.Parent) do
  begin
    LD1 := LPlane1.X * LNode.Parent.Pos.X + LPlane1.Y * LNode.Parent.Pos.Y + LPlane1.Z;
    if (TGeoMath.FloatSignBitSet(LD0) xor TGeoMath.FloatSignBitSet(LD1)) <> 0 then
    begin
      LPlane2 := TGeoWinding2D.Plane2DFromPoints(LNode.Pos, LNode.Parent.Pos);
      LD2 := LPlane2.X * AStart.X + LPlane2.Y * AStart.Y + LPlane2.Z;
      LD3 := LPlane2.X * AEnd.X + LPlane2.Y * AEnd.Y + LPlane2.Z;
      if (TGeoMath.FloatSignBitSet(LD2) xor TGeoMath.FloatSignBitSet(LD3)) <> 0 then
        Exit(True);
    end;
    LD0 := LD1;
    LNode := LNode.Parent;
  end;
  Result := False;
end;

function TAvoidPathTree.GetPathNodeDelta(const ANode: TAvoidPathNode; const ASeekPos: TIdVec2;
  const ABlocked: Boolean): Boolean;
var
  LNumPoints, LEdgeNum, LTries: Integer;
  LFacing: Boolean;
  LSeekDelta: TIdVec2;
  LNode: TAvoidPathNode;
  LWinding: TGeoWinding2D;
begin
  if (ANode.Obstacle < 0) or (ANode.Obstacle >= FObstacles.Count) then
    raise EAasAvoidException.Create(Format(SObstacleNotInList, [ANode.Obstacle]));
  LWinding := FObstacles[ANode.Obstacle].Winding;
  LNumPoints := LWinding.NumPoints;
  if LNumPoints = 0 then
    raise EAasAvoidException.Create(Format(SNoEdgeToWalk, [ANode.Obstacle]));

  // get delta along the current edge
  LTries := 0;
  while True do
  begin
    LEdgeNum := (ANode.EdgeNum + ANode.Dir) mod LNumPoints;
    ANode.Delta := LWinding[LEdgeNum] - ANode.Pos;
    if ANode.Delta.LengthSqr > CTinyEdge then
      Break;
    ANode.EdgeNum := (ANode.EdgeNum + LNumPoints + (2 * ANode.Dir - 1)) mod LNumPoints;
    // the original goes round and round a winding whose points are all the same
    Inc(LTries);
    if LTries > LNumPoints then
      raise EAasAvoidException.Create(Format(SNoEdgeToWalk, [ANode.Obstacle]));
  end;

  // if not blocked
  if not ABlocked then
  begin
    // test if the current edge faces the goal
    LSeekDelta := ASeekPos - ANode.Pos;
    LFacing := ((2 * ANode.Dir - 1) * (ANode.Delta.X * LSeekDelta.Y - ANode.Delta.Y * LSeekDelta.X)) >= 0.0;

    // if the current edge faces goal and the line from the current
    // position to the goal does not intersect the current path
    if LFacing and not LineIntersectsPath(ANode.Pos, ASeekPos, ANode.Parent) then
    begin
      ANode.Delta := ASeekPos - ANode.Pos;
      ANode.EdgeNum := -1;
    end;
  end;

  // if the delta is along the obstacle edge
  if ANode.EdgeNum <> -1 then
  begin
    // if the edge is found going from this node to the root node
    LNode := ANode.Parent;
    while Assigned(LNode) do
    begin
      if (ANode.Obstacle <> LNode.Obstacle) or (ANode.EdgeNum <> LNode.EdgeNum) then
      begin
        LNode := LNode.Parent;
        Continue;
      end;
      // test whether or not the edge segments actually overlap
      if LNode.Pos * ANode.Delta > (ANode.Pos + ANode.Delta) * ANode.Delta then
      begin
        LNode := LNode.Parent;
        Continue;
      end;
      if ANode.Pos * ANode.Delta > (LNode.Pos + LNode.Delta) * ANode.Delta then
      begin
        LNode := LNode.Parent;
        Continue;
      end;
      Break;
    end;
    if Assigned(LNode) then
      Exit(False);
  end;
  Result := True;
end;

procedure TAvoidPathTree.Build(const AClipBounds: TGeoBounds; const AStartPos, ASeekPos: TIdVec2;
  var APath: TAvoidPath);
var
  LBlockingEdgeNum, LBlockingObstacle, LObstaclePoints, LBestNumNodes: Integer;
  LBlockingScale: Single;
  LNode, LChild, LChild0, LChild1: TAvoidPathNode;
  LQueue: TQueue<TAvoidPathNode>;
  LEndPos: TIdVec2;
begin
  LBestNumNodes := CBestNumNodesStart;
  LBlockingEdgeNum := -1;
  LBlockingObstacle := -1;
  LQueue := TQueue<TAvoidPathNode>.Create;
  try
    FRoot := NewNode;
    FRoot.Pos := AStartPos;
    FRoot.Delta := ASeekPos - FRoot.Pos;
    FRoot.NumNodes := 0;
    LQueue.Enqueue(FRoot);

    while True do
    begin
      if LQueue.Count = 0 then
        Break;
      LNode := LQueue.Dequeue;
      if FAllocCount >= AVOID_MAX_PATH_NODES then
        Break;

      // if this path has more than twice the number of nodes than the best path so far
      if LNode.NumNodes > LBestNumNodes * 2 then
        Continue;

      // don't move outside of the clip bounds
      LEndPos := LNode.Pos + LNode.Delta;
      if (LEndPos.X - CClipBoundsEpsilon < AClipBounds.Mins.X) or (LEndPos.X + CClipBoundsEpsilon > AClipBounds.Maxs.X) or
        (LEndPos.Y - CClipBoundsEpsilon < AClipBounds.Mins.Y) or (LEndPos.Y + CClipBoundsEpsilon > AClipBounds.Maxs.Y) then
        Continue;

      // if an obstacle is blocking the path
      if FObstacles.GetFirstBlockingObstacle(LNode.Obstacle, LNode.Pos, LNode.Delta, LBlockingScale, LBlockingObstacle,
        LBlockingEdgeNum) then
      begin
        if APath.FirstObstacle = AVOID_NO_ENTITY then
          APath.FirstObstacle := FObstacles[LBlockingObstacle].EntityId;

        LNode.Delta := LNode.Delta * LBlockingScale;

        if LNode.EdgeNum = -1 then
        begin
          LChild0 := NewNode;
          LChild1 := NewNode;
          LNode.Children[0] := LChild0;
          LNode.Children[1] := LChild1;
          LChild0.Dir := 0;
          LChild1.Dir := 1;
          LChild0.Parent := LNode;
          LChild1.Parent := LNode;
          LChild0.Pos := LNode.Pos + LNode.Delta;
          LChild1.Pos := LChild0.Pos;
          LChild0.Obstacle := LBlockingObstacle;
          LChild1.Obstacle := LBlockingObstacle;
          LChild0.EdgeNum := LBlockingEdgeNum;
          LChild1.EdgeNum := LBlockingEdgeNum;
          LChild0.NumNodes := LNode.NumNodes + 1;
          LChild1.NumNodes := LChild0.NumNodes;
          if GetPathNodeDelta(LChild0, ASeekPos, True) then
            LQueue.Enqueue(LChild0);
          if GetPathNodeDelta(LChild1, ASeekPos, True) then
            LQueue.Enqueue(LChild1);
        end
        else
        begin
          LChild := NewNode;
          LNode.Children[LNode.Dir] := LChild;
          LChild.Dir := LNode.Dir;
          LChild.Parent := LNode;
          LChild.Pos := LNode.Pos + LNode.Delta;
          LChild.Obstacle := LBlockingObstacle;
          LChild.EdgeNum := LBlockingEdgeNum;
          LChild.NumNodes := LNode.NumNodes + 1;
          if GetPathNodeDelta(LChild, ASeekPos, True) then
            LQueue.Enqueue(LChild);
        end;
      end
      else
      begin
        LChild := NewNode;
        LNode.Children[LNode.Dir] := LChild;
        LChild.Dir := LNode.Dir;
        LChild.Parent := LNode;
        LChild.Pos := LNode.Pos + LNode.Delta;
        LChild.NumNodes := LNode.NumNodes + 1;

        // there is a free path towards goal
        if LNode.EdgeNum = -1 then
        begin
          if LNode.NumNodes < LBestNumNodes then
            LBestNumNodes := LNode.NumNodes;
          Continue;
        end;

        LChild.Obstacle := LNode.Obstacle;
        LObstaclePoints := FObstacles[LNode.Obstacle].Winding.NumPoints;
        LChild.EdgeNum := (LNode.EdgeNum + LObstaclePoints + (2 * LNode.Dir - 1)) mod LObstaclePoints;

        if GetPathNodeDelta(LChild, ASeekPos, False) then
          LQueue.Enqueue(LChild);
      end;
    end;
  finally
    LQueue.Free;
  end;
end;

procedure TAvoidPathTree.FreeTree;
begin
  if Assigned(FRoot) then
    FreeSubtree(FRoot);
  FRoot := nil;
end;

procedure TAvoidPathTree.Prune(const ASeekPos: TIdVec2);
var
  LIndex: Integer;
  LBestDist: Single;
  LNode, LLastNode, LN, LBestNode: TAvoidPathNode;
  LDelta: TIdVec2;
begin
  LNode := FRoot;
  while Assigned(LNode) do
  begin
    LDelta := ASeekPos - LNode.Pos;
    LNode.Dist := LDelta.LengthSqr;

    if Assigned(LNode.Children[0]) then
      LNode := LNode.Children[0]
    else if Assigned(LNode.Children[1]) then
      LNode := LNode.Children[1]
    else
    begin
      // find the node closest to the goal along this path
      LBestDist := 1E30;
      LBestNode := LNode;
      LN := LNode;
      while Assigned(LN) do
      begin
        if Assigned(LN.Children[0]) and Assigned(LN.Children[1]) then
          Break;
        if LN.Dist < LBestDist then
        begin
          LBestDist := LN.Dist;
          LBestNode := LN;
        end;
        LN := LN.Parent;
      end;

      // free tree down from the best node
      for LIndex := 0 to 1 do
        if Assigned(LBestNode.Children[LIndex]) then
        begin
          FreeSubtree(LBestNode.Children[LIndex]);
          LBestNode.Children[LIndex] := nil;
        end;

      LLastNode := LBestNode;
      LNode := LBestNode.Parent;
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
end;

end.
