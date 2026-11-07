{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib containers - TIdHierarchy, the intrusive tree             }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\containers\Hierarchy.h.  }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Containers.Hierarchy;

interface

type
  /// <summary>
  ///   A node of a hierarchy (idHierarchy): parent, first child and next sibling. An object that is
  ///   in a tree has one node and sets itself as its owner. The nodes do not own anything.
  ///   Freeing a node takes it out of the hierarchy (its children go to its parent).
  ///   <c>GetPriorSibling</c> raises EIdLibException if the links are inconsistent (idLib::Error).
  /// </summary>
  TIdHierarchy<T: class> = class
  private
    FParent: TIdHierarchy<T>;
    FSibling: TIdHierarchy<T>;
    FChild: TIdHierarchy<T>;
    FOwner: T;
    function GetPriorSiblingNode: TIdHierarchy<T>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetOwner(const AObject: T);
    function Owner: T;
    /// <summary>Makes the given node the parent</summary>
    procedure ParentTo(const ANode: TIdHierarchy<T>);
    /// <summary>Makes this node a sibling after the given one</summary>
    procedure MakeSiblingAfter(const ANode: TIdHierarchy<T>);
    /// <summary>True if the given node is the parent or an ancestor</summary>
    function ParentedBy(const ANode: TIdHierarchy<T>): Boolean;
    procedure RemoveFromParent;
    /// <summary>Removes the node from the hierarchy and gives its children to its parent</summary>
    procedure RemoveFromHierarchy;
    function GetParent: T;
    function GetChild: T;
    function GetSibling: T;
    /// <summary>The previous node with the same parent; nil for the first child</summary>
    function GetPriorSibling: T;
    /// <summary>Goes through all the nodes of the hierarchy</summary>
    function GetNext: T;
    /// <summary>Goes through all the leaf nodes of the hierarchy</summary>
    function GetNextLeaf: T;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Exceptions;

{ TIdHierarchy<T> }

constructor TIdHierarchy<T>.Create;
begin
  inherited Create;
  FOwner := nil;
  FParent := nil;
  FSibling := nil;
  FChild := nil;
end;

destructor TIdHierarchy<T>.Destroy;
begin
  RemoveFromHierarchy;
  inherited Destroy;
end;

procedure TIdHierarchy<T>.SetOwner(const AObject: T);
begin
  FOwner := AObject;
end;

function TIdHierarchy<T>.Owner: T;
begin
  Result := FOwner;
end;

function TIdHierarchy<T>.ParentedBy(const ANode: TIdHierarchy<T>): Boolean;
begin
  if FParent = ANode then
    Exit(True)
  else if Assigned(FParent) then
    Exit(FParent.ParentedBy(ANode));
  Result := False;
end;

procedure TIdHierarchy<T>.ParentTo(const ANode: TIdHierarchy<T>);
begin
  RemoveFromParent;
  FParent := ANode;
  FSibling := ANode.FChild;
  ANode.FChild := Self;
end;

procedure TIdHierarchy<T>.MakeSiblingAfter(const ANode: TIdHierarchy<T>);
begin
  RemoveFromParent;
  FParent := ANode.FParent;
  FSibling := ANode.FSibling;
  ANode.FSibling := Self;
end;

procedure TIdHierarchy<T>.RemoveFromParent;
var
  LPrevious: TIdHierarchy<T>;
begin
  if Assigned(FParent) then
  begin
    LPrevious := GetPriorSiblingNode;
    if Assigned(LPrevious) then
      LPrevious.FSibling := FSibling
    else
      FParent.FChild := FSibling;
  end;
  FParent := nil;
  FSibling := nil;
end;

procedure TIdHierarchy<T>.RemoveFromHierarchy;
var
  LParentNode, LNode: TIdHierarchy<T>;
begin
  LParentNode := FParent;
  RemoveFromParent;
  if Assigned(LParentNode) then
  begin
    while Assigned(FChild) do
    begin
      LNode := FChild;
      LNode.RemoveFromParent;
      LNode.ParentTo(LParentNode);
    end;
  end
  else
  begin
    while Assigned(FChild) do
      FChild.RemoveFromParent;
  end;
end;

function TIdHierarchy<T>.GetParent: T;
begin
  if Assigned(FParent) then
    Exit(FParent.FOwner);
  Result := nil;
end;

function TIdHierarchy<T>.GetChild: T;
begin
  if Assigned(FChild) then
    Exit(FChild.FOwner);
  Result := nil;
end;

function TIdHierarchy<T>.GetSibling: T;
begin
  if Assigned(FSibling) then
    Exit(FSibling.FOwner);
  Result := nil;
end;

function TIdHierarchy<T>.GetPriorSiblingNode: TIdHierarchy<T>;
var
  LPrevious, LNode: TIdHierarchy<T>;
begin
  if (not Assigned(FParent)) or (FParent.FChild = Self) then
    Exit(nil);
  LNode := FParent.FChild;
  LPrevious := nil;
  while (LNode <> Self) and (LNode <> nil) do
  begin
    LPrevious := LNode;
    LNode := LNode.FSibling;
  end;
  if LNode <> Self then
    raise EIdLibException.Create('idHierarchy::GetPriorSibling: could not find node in parent''s list of children');
  Result := LPrevious;
end;

function TIdHierarchy<T>.GetPriorSibling: T;
var
  LPrior: TIdHierarchy<T>;
begin
  LPrior := GetPriorSiblingNode;
  if Assigned(LPrior) then
    Exit(LPrior.FOwner);
  Result := nil;
end;

function TIdHierarchy<T>.GetNext: T;
var
  LNode: TIdHierarchy<T>;
begin
  if Assigned(FChild) then
    Exit(FChild.FOwner);
  LNode := Self;
  while Assigned(LNode) and (LNode.FSibling = nil) do
    LNode := LNode.FParent;
  if Assigned(LNode) then
    Result := LNode.FSibling.FOwner
  else
    Result := nil;
end;

function TIdHierarchy<T>.GetNextLeaf: T;
var
  LNode: TIdHierarchy<T>;
begin
  if Assigned(FChild) then
  begin
    LNode := FChild;
    while Assigned(LNode.FChild) do
      LNode := LNode.FChild;
    Exit(LNode.FOwner);
  end;
  LNode := Self;
  while Assigned(LNode) and (LNode.FSibling = nil) do
    LNode := LNode.FParent;
  if Assigned(LNode) then
  begin
    LNode := LNode.FSibling;
    while Assigned(LNode.FChild) do
      LNode := LNode.FChild;
    Result := LNode.FOwner;
  end
  else
    Result := nil;
end;

end.
