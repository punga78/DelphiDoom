{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the tree of nodes and leafs of a BSP         }
{                                                                              }
{  Port of R_LoadNodesAndLeafs and R_SetParent (tr_bsp.c), Quake III Arena     }
{  GPL Source Code.                                                            }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. GPL v2 or later.                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.TreeLoader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.MapFile.Bsp.Types, DelphiDoom.MapFile.Bsp.Intf,
  DelphiDoom.MapFile.Bsp.RenderTypes;

type
  /// <summary>
  ///   Builds the tree the way the renderer does: node i is at index i, leaf j at index
  ///   <c>numNodes + j</c>; a child >= 0 is a node, a child below 0 is the leaf -1 - child.
  ///   R_SetParent walks the tree with recursion; here the walk uses its own stack, so a deep
  ///   tree cannot exhaust the one of the thread, and a node with two parents (a cycle or a
  ///   shared subtree: the original would recurse for ever or chain the wrong parent) is an
  ///   error. Differences: a child >= 0 that is past the nodes is an error (the original points
  ///   into the leafs by accident)
  /// </summary>
  TBspTreeLoader = class(TInterfacedObject, IBspTreeLoader)
  strict private
    procedure SetParents(var ATree: TBspRenderTree);
  public
    function Load(const ANodes: TArray<TBspNode>; const ALeafs: TArray<TBspLeaf>;
      const APlaneCount: Integer): TBspRenderTree;
  end;

implementation

resourcestring
  SPlaneOutOfRange = 'node %d: plane %d is not in 0..%d';
  SChildOutOfRange = 'node %d: child %d is not a node or a leaf (%d nodes, %d leafs)';
  SNodeTwice = 'node %d is reached twice in the tree';

{ TBspTreeLoader }

function TBspTreeLoader.Load(const ANodes: TArray<TBspNode>; const ALeafs: TArray<TBspLeaf>;
  const APlaneCount: Integer): TBspRenderTree;
var
  LNumNodes, LNumLeafs, LIndex, LAxis, LSide, LChild: Integer;
  LNode: ^TBspRenderNode;
begin
  LNumNodes := Length(ANodes);
  LNumLeafs := Length(ALeafs);
  SetLength(Result.Nodes, LNumNodes + LNumLeafs);
  Result.NumDecisionNodes := LNumNodes;
  Result.NumClusters := 0;

  // load nodes
  for LIndex := 0 to LNumNodes - 1 do
  begin
    LNode := @Result.Nodes[LIndex];
    LNode^ := Default(TBspRenderNode);
    LNode^.IsNode := True;
    for LAxis := 0 to 2 do
    begin
      LNode^.Mins[LAxis] := ANodes[LIndex].Mins[LAxis];
      LNode^.Maxs[LAxis] := ANodes[LIndex].Maxs[LAxis];
    end;
    if (ANodes[LIndex].PlaneNum < 0) or (ANodes[LIndex].PlaneNum >= APlaneCount) then
      raise EBspFileException.Create(Format(SPlaneOutOfRange, [LIndex, ANodes[LIndex].PlaneNum, APlaneCount - 1]));
    LNode^.PlaneNum := ANodes[LIndex].PlaneNum;
    for LSide := 0 to 1 do
    begin
      LChild := ANodes[LIndex].Children[LSide];
      if LChild >= 0 then
      begin
        if LChild >= LNumNodes then
          raise EBspFileException.Create(Format(SChildOutOfRange, [LIndex, LChild, LNumNodes, LNumLeafs]));
        LNode^.Children[LSide] := LChild;
      end
      else
      begin
        if -1 - LChild >= LNumLeafs then
          raise EBspFileException.Create(Format(SChildOutOfRange, [LIndex, LChild, LNumNodes, LNumLeafs]));
        LNode^.Children[LSide] := LNumNodes + (-1 - LChild);
      end;
    end;
  end;

  // load leafs
  for LIndex := 0 to LNumLeafs - 1 do
  begin
    LNode := @Result.Nodes[LNumNodes + LIndex];
    LNode^ := Default(TBspRenderNode);
    for LAxis := 0 to 2 do
    begin
      LNode^.Mins[LAxis] := ALeafs[LIndex].Mins[LAxis];
      LNode^.Maxs[LAxis] := ALeafs[LIndex].Maxs[LAxis];
    end;
    LNode^.Cluster := ALeafs[LIndex].Cluster;
    LNode^.Area := ALeafs[LIndex].Area;
    if LNode^.Cluster >= Result.NumClusters then
      Result.NumClusters := LNode^.Cluster + 1;
    LNode^.FirstMarkSurface := ALeafs[LIndex].FirstLeafSurface;
    LNode^.NumMarkSurfaces := ALeafs[LIndex].NumLeafSurfaces;
  end;

  // chain descendants
  SetParents(Result);
end;

procedure TBspTreeLoader.SetParents(var ATree: TBspRenderTree);
var
  LStack: TArray<Integer>;
  LTop, LCurrent, LSide, LChild: Integer;
  LReached: TArray<Boolean>;
begin
  if Length(ATree.Nodes) = 0 then
    Exit;
  SetLength(LReached, Length(ATree.Nodes));
  SetLength(LStack, 64);
  ATree.Nodes[0].Parent := -1;
  LReached[0] := True;
  LStack[0] := 0;
  LTop := 1;
  while LTop > 0 do
  begin
    Dec(LTop);
    LCurrent := LStack[LTop];
    // a leaf ends the walk (contents != CONTENTS_NODE)
    if not ATree.Nodes[LCurrent].IsNode then
      Continue;
    for LSide := 0 to 1 do
    begin
      LChild := ATree.Nodes[LCurrent].Children[LSide];
      if LReached[LChild] then
        raise EBspFileException.Create(Format(SNodeTwice, [LChild]));
      LReached[LChild] := True;
      ATree.Nodes[LChild].Parent := LCurrent;
      if LTop >= Length(LStack) then
        SetLength(LStack, LTop * 2);
      LStack[LTop] := LChild;
      Inc(LTop);
    end;
  end;
end;

end.
