{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - obstacle avoidance, a node of the tree  }
{                                                                              }
{  Port of pathNode_t (AI_pathing.cpp), Doom 3 GPL Source Code.                 }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Framework\IdLib); the repository as a whole is }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.Avoid.PathNode;

interface

uses
  DelphiDoom.IdLib.Math.Vec2;

type
  /// <summary>
  ///   A point of a path around the obstacles: where it is, the movement from it (along an edge of an obstacle or
  ///   towards the goal), the obstacle and the edge it walks along (-1 for a free movement), how many nodes
  ///   there are from the root, and the nodes around it. The tree owns the nodes
  /// </summary>
  TAvoidPathNode = class
  public
    /// <summary>0: counter clockwise, 1: clockwise along the edges</summary>
    Dir: Integer;
    Pos: TIdVec2;
    Delta: TIdVec2;
    /// <summary>The squared distance to the goal (PrunePathTree)</summary>
    Dist: Single;
    Obstacle: Integer;
    EdgeNum: Integer;
    NumNodes: Integer;
    Parent: TAvoidPathNode;
    Children: array[0..1] of TAvoidPathNode;
    /// <summary>pathNode_s::Init: the state of a new node</summary>
    constructor Create;
  end;

implementation

{ TAvoidPathNode }

constructor TAvoidPathNode.Create;
begin
  inherited Create;
  Dir := 0;
  Pos.Zero;
  Delta.Zero;
  Dist := 0;
  Obstacle := -1;
  EdgeNum := -1;
  NumNodes := 0;
  Parent := nil;
  Children[0] := nil;
  Children[1] := nil;
end;

end.
