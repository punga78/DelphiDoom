{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib containers - TIdBTree, the balanced search tree           }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\containers\BTree.h.      }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Containers.BTree;

interface

uses
  System.Generics.Defaults;

type
  /// <summary>
  ///   A node of TIdBTree (idBTreeNode). A leaf node has <c>Obj</c> set; the other nodes are
  ///   internal. The tree owns its nodes, not the objects.
  /// </summary>
  TIdBTreeNode<TObj: class; TKey> = class
  public
    /// <summary>Key used for sorting</summary>
    Key: TKey;
    /// <summary>The object stored in a leaf node, nil in an internal node</summary>
    Obj: TObj;
    Parent: TIdBTreeNode<TObj, TKey>;
    Next: TIdBTreeNode<TObj, TKey>;
    Prev: TIdBTreeNode<TObj, TKey>;
    NumChildren: Integer;
    FirstChild: TIdBTreeNode<TObj, TKey>;
    LastChild: TIdBTreeNode<TObj, TKey>;
  end;

  /// <summary>
  ///   A balanced search tree (idBTree): objects stored in the leaves ordered by key, at most
  ///   <c>maxChildrenPerNode</c> children per node (at least 4, a constructor parameter instead
  ///   of a template parameter). The order of the keys comes from an <c>IComparer&lt;TKey&gt;</c>.
  ///   The original's <c>Init</c> is done by the constructor and <c>Shutdown</c> by the destructor.
  ///   Same algorithm and same shape of the tree as the original (the tests compare the whole tree).
  /// </summary>
  TIdBTree<TObj: class; TKey> = class
  public
    type
      TNode = TIdBTreeNode<TObj, TKey>;
  private
    FRoot: TNode;
    FMaxChildrenPerNode: Integer;
    FNodeCount: Integer;
    FComparer: IComparer<TKey>;
    function AllocNode: TNode;
    procedure FreeNode(const ANode: TNode);
    procedure SplitNode(const ANode: TNode);
    function MergeNodes(const ANode1, ANode2: TNode): TNode;
    procedure FreeAll(const ANode: TNode);
  public
    constructor Create(const AMaxChildrenPerNode: Integer; const AComparer: IComparer<TKey> = nil);
    destructor Destroy; override;
    /// <summary>Adds an object to the tree and returns its leaf node</summary>
    function Add(const AObject: TObj; const AKey: TKey): TNode;
    /// <summary>Removes an object node from the tree</summary>
    procedure Remove(const ANode: TNode);
    /// <summary>Finds an object using the given key, nil if there is none</summary>
    function Find(const AKey: TKey): TObj;
    /// <summary>Finds the object with the smallest key larger than or equal to the given key</summary>
    function FindSmallestLargerEqual(const AKey: TKey): TObj;
    /// <summary>Finds the object with the largest key smaller than or equal to the given key</summary>
    function FindLargestSmallerEqual(const AKey: TKey): TObj;
    function GetRoot: TNode;
    /// <summary>The total number of nodes in the tree</summary>
    function GetNodeCount: Integer;
    /// <summary>Goes through all nodes of the tree</summary>
    function GetNext(ANode: TNode): TNode;
    /// <summary>Goes through all leaf nodes of the tree</summary>
    function GetNextLeaf(ANode: TNode): TNode;
  end;

implementation

uses
  System.SysUtils;

{ TIdBTree<TObj, TKey> }

constructor TIdBTree<TObj, TKey>.Create(const AMaxChildrenPerNode: Integer; const AComparer: IComparer<TKey>);
begin
  inherited Create;
  if AMaxChildrenPerNode < 4 then
    raise EArgumentException.Create('TIdBTree: the maximum number of children per node must be at least 4');
  FMaxChildrenPerNode := AMaxChildrenPerNode;
  if Assigned(AComparer) then
    FComparer := AComparer
  else
    FComparer := TComparer<TKey>.Default;
  FRoot := AllocNode;
end;

destructor TIdBTree<TObj, TKey>.Destroy;
begin
  FreeAll(FRoot);
  FRoot := nil;
  inherited Destroy;
end;

procedure TIdBTree<TObj, TKey>.FreeAll(const ANode: TNode);
var
  LChild, LNext: TNode;
begin
  if not Assigned(ANode) then
    Exit;
  LChild := ANode.FirstChild;
  while Assigned(LChild) do
  begin
    LNext := LChild.Next;
    FreeAll(LChild);
    LChild := LNext;
  end;
  ANode.Free;
  Dec(FNodeCount);
end;

function TIdBTree<TObj, TKey>.AllocNode: TNode;
begin
  Result := TNode.Create;
  Result.Key := Default(TKey);
  Result.Obj := nil;
  Inc(FNodeCount);
end;

procedure TIdBTree<TObj, TKey>.FreeNode(const ANode: TNode);
begin
  ANode.Free;
  Dec(FNodeCount);
end;

function TIdBTree<TObj, TKey>.Add(const AObject: TObj; const AKey: TKey): TNode;
var
  LNode, LChild, LNewNode: TNode;
begin
  if FRoot.NumChildren >= FMaxChildrenPerNode then
  begin
    LNewNode := AllocNode;
    LNewNode.Key := FRoot.Key;
    LNewNode.FirstChild := FRoot;
    LNewNode.LastChild := FRoot;
    LNewNode.NumChildren := 1;
    FRoot.Parent := LNewNode;
    SplitNode(FRoot);
    FRoot := LNewNode;
  end;
  LNewNode := AllocNode;
  LNewNode.Key := AKey;
  LNewNode.Obj := AObject;
  LNode := FRoot;
  while LNode.FirstChild <> nil do
  begin
    if FComparer.Compare(AKey, LNode.Key) > 0 then
      LNode.Key := AKey;
    // find the first child with a key larger than or equal to the key of the new node
    LChild := LNode.FirstChild;
    while Assigned(LChild.Next) do
    begin
      if FComparer.Compare(AKey, LChild.Key) <= 0 then
        Break;
      LChild := LChild.Next;
    end;
    if Assigned(LChild.Obj) then
    begin
      if FComparer.Compare(AKey, LChild.Key) <= 0 then
      begin
        // insert new node before child
        if Assigned(LChild.Prev) then
          LChild.Prev.Next := LNewNode
        else
          LNode.FirstChild := LNewNode;
        LNewNode.Prev := LChild.Prev;
        LNewNode.Next := LChild;
        LChild.Prev := LNewNode;
      end
      else
      begin
        // insert new node after child
        if Assigned(LChild.Next) then
          LChild.Next.Prev := LNewNode
        else
          LNode.LastChild := LNewNode;
        LNewNode.Prev := LChild;
        LNewNode.Next := LChild.Next;
        LChild.Next := LNewNode;
      end;
      LNewNode.Parent := LNode;
      Inc(LNode.NumChildren);
      Exit(LNewNode);
    end;
    // make sure the child has room to store another node
    if LChild.NumChildren >= FMaxChildrenPerNode then
    begin
      SplitNode(LChild);
      if FComparer.Compare(AKey, LChild.Prev.Key) <= 0 then
        LChild := LChild.Prev;
    end;
    LNode := LChild;
  end;
  // we only end up here if the root node is empty
  LNewNode.Parent := FRoot;
  FRoot.Key := AKey;
  FRoot.FirstChild := LNewNode;
  FRoot.LastChild := LNewNode;
  Inc(FRoot.NumChildren);
  Result := LNewNode;
end;

procedure TIdBTree<TObj, TKey>.Remove(const ANode: TNode);
var
  LParent, LOldRoot: TNode;
begin
  // unlink the node from its parent
  if Assigned(ANode.Prev) then
    ANode.Prev.Next := ANode.Next
  else
    ANode.Parent.FirstChild := ANode.Next;
  if Assigned(ANode.Next) then
    ANode.Next.Prev := ANode.Prev
  else
    ANode.Parent.LastChild := ANode.Prev;
  Dec(ANode.Parent.NumChildren);
  // make sure there are no parent nodes with a single child
  LParent := ANode.Parent;
  while (LParent <> FRoot) and (LParent.NumChildren <= 1) do
  begin
    if Assigned(LParent.Next) then
      LParent := MergeNodes(LParent, LParent.Next)
    else if Assigned(LParent.Prev) then
      LParent := MergeNodes(LParent.Prev, LParent);
    // a parent may not use a key higher than the key of its last child
    if FComparer.Compare(LParent.Key, LParent.LastChild.Key) > 0 then
      LParent.Key := LParent.LastChild.Key;
    if LParent.NumChildren > FMaxChildrenPerNode then
    begin
      SplitNode(LParent);
      Break;
    end;
    LParent := LParent.Parent;
  end;
  while Assigned(LParent) and Assigned(LParent.LastChild) do
  begin
    // a parent may not use a key higher than the key of its last child
    if FComparer.Compare(LParent.Key, LParent.LastChild.Key) > 0 then
      LParent.Key := LParent.LastChild.Key;
    LParent := LParent.Parent;
  end;
  // free the node
  FreeNode(ANode);
  // remove the root node if it has a single internal node as child
  if (FRoot.NumChildren = 1) and (FRoot.FirstChild.Obj = nil) then
  begin
    LOldRoot := FRoot;
    FRoot.FirstChild.Parent := nil;
    FRoot := FRoot.FirstChild;
    FreeNode(LOldRoot);
  end;
end;

function TIdBTree<TObj, TKey>.Find(const AKey: TKey): TObj;
var
  LNode: TNode;
begin
  LNode := FRoot.FirstChild;
  while Assigned(LNode) do
  begin
    while Assigned(LNode.Next) do
    begin
      if FComparer.Compare(LNode.Key, AKey) >= 0 then
        Break;
      LNode := LNode.Next;
    end;
    if Assigned(LNode.Obj) then
    begin
      if FComparer.Compare(LNode.Key, AKey) = 0 then
        Exit(LNode.Obj)
      else
        Exit(nil);
    end;
    LNode := LNode.FirstChild;
  end;
  Result := nil;
end;

function TIdBTree<TObj, TKey>.FindSmallestLargerEqual(const AKey: TKey): TObj;
var
  LNode: TNode;
begin
  LNode := FRoot.FirstChild;
  while Assigned(LNode) do
  begin
    while Assigned(LNode.Next) do
    begin
      if FComparer.Compare(LNode.Key, AKey) >= 0 then
        Break;
      LNode := LNode.Next;
    end;
    if Assigned(LNode.Obj) then
    begin
      if FComparer.Compare(LNode.Key, AKey) >= 0 then
        Exit(LNode.Obj)
      else
        Exit(nil);
    end;
    LNode := LNode.FirstChild;
  end;
  Result := nil;
end;

function TIdBTree<TObj, TKey>.FindLargestSmallerEqual(const AKey: TKey): TObj;
var
  LNode: TNode;
begin
  LNode := FRoot.LastChild;
  while Assigned(LNode) do
  begin
    while Assigned(LNode.Prev) do
    begin
      if FComparer.Compare(LNode.Key, AKey) <= 0 then
        Break;
      LNode := LNode.Prev;
    end;
    if Assigned(LNode.Obj) then
    begin
      if FComparer.Compare(LNode.Key, AKey) <= 0 then
        Exit(LNode.Obj)
      else
        Exit(nil);
    end;
    LNode := LNode.LastChild;
  end;
  Result := nil;
end;

function TIdBTree<TObj, TKey>.GetRoot: TNode;
begin
  Result := FRoot;
end;

function TIdBTree<TObj, TKey>.GetNodeCount: Integer;
begin
  Result := FNodeCount;
end;

function TIdBTree<TObj, TKey>.GetNext(ANode: TNode): TNode;
begin
  if Assigned(ANode.FirstChild) then
    Exit(ANode.FirstChild);
  while Assigned(ANode) and (ANode.Next = nil) do
    ANode := ANode.Parent;
  Result := ANode;
end;

function TIdBTree<TObj, TKey>.GetNextLeaf(ANode: TNode): TNode;
begin
  if Assigned(ANode.FirstChild) then
  begin
    while Assigned(ANode.FirstChild) do
      ANode := ANode.FirstChild;
    Exit(ANode);
  end;
  while Assigned(ANode) and (ANode.Next = nil) do
    ANode := ANode.Parent;
  if Assigned(ANode) then
  begin
    ANode := ANode.Next;
    while Assigned(ANode.FirstChild) do
      ANode := ANode.FirstChild;
    Result := ANode;
  end
  else
    Result := nil;
end;

procedure TIdBTree<TObj, TKey>.SplitNode(const ANode: TNode);
var
  LIndex: Integer;
  LChild, LNewNode: TNode;
begin
  // allocate a new node
  LNewNode := AllocNode;
  LNewNode.Parent := ANode.Parent;
  // divide the children over the two nodes
  LChild := ANode.FirstChild;
  LChild.Parent := LNewNode;
  LIndex := 3;
  while LIndex < ANode.NumChildren do
  begin
    LChild := LChild.Next;
    LChild.Parent := LNewNode;
    Inc(LIndex, 2);
  end;
  LNewNode.Key := LChild.Key;
  LNewNode.NumChildren := ANode.NumChildren div 2;
  LNewNode.FirstChild := ANode.FirstChild;
  LNewNode.LastChild := LChild;
  Dec(ANode.NumChildren, LNewNode.NumChildren);
  ANode.FirstChild := LChild.Next;
  LChild.Next.Prev := nil;
  LChild.Next := nil;
  // add the new child to the parent before the split node
  if Assigned(ANode.Prev) then
    ANode.Prev.Next := LNewNode
  else
    ANode.Parent.FirstChild := LNewNode;
  LNewNode.Prev := ANode.Prev;
  LNewNode.Next := ANode;
  ANode.Prev := LNewNode;
  Inc(ANode.Parent.NumChildren);
end;

function TIdBTree<TObj, TKey>.MergeNodes(const ANode1, ANode2: TNode): TNode;
var
  LChild: TNode;
begin
  LChild := ANode1.FirstChild;
  while Assigned(LChild.Next) do
  begin
    LChild.Parent := ANode2;
    LChild := LChild.Next;
  end;
  LChild.Parent := ANode2;
  LChild.Next := ANode2.FirstChild;
  ANode2.FirstChild.Prev := LChild;
  ANode2.FirstChild := ANode1.FirstChild;
  Inc(ANode2.NumChildren, ANode1.NumChildren);
  // unlink the first node from the parent
  if Assigned(ANode1.Prev) then
    ANode1.Prev.Next := ANode2
  else
    ANode1.Parent.FirstChild := ANode2;
  ANode2.Prev := ANode1.Prev;
  Dec(ANode2.Parent.NumChildren);
  FreeNode(ANode1);
  Result := ANode2;
end;

end.
