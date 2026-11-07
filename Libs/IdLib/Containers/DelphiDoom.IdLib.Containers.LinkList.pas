{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib containers - TIdLinkList, the circular linked list        }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\containers\LinkList.h.   }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Containers.LinkList;

interface

type
  /// <summary>
  ///   A node of a circular intrusive linked list (idLinkList): an object that can be in a list
  ///   has one node and sets itself as its owner. A node starts as the head of an empty list.
  ///   The nodes do not own anything: the lists link nodes, the owners are references. Freeing a
  ///   node removes it from its list, freeing the head of a list empties it.
  /// </summary>
  TIdLinkList<T: class> = class
  private
    FHead: TIdLinkList<T>;
    FNext: TIdLinkList<T>;
    FPrev: TIdLinkList<T>;
    FOwner: T;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>True if the list is empty (when called on the head)</summary>
    function IsListEmpty: Boolean;
    /// <summary>True if the node is in a list; always false on the head of a list</summary>
    function InList: Boolean;
    /// <summary>The number of nodes in the list of this node, the head not counted</summary>
    function Num: Integer;
    /// <summary>On the head: empties the list; on a node: removes it from the list</summary>
    procedure Clear;
    /// <summary>Places the node before the given one (at the end of the list if that is the head)</summary>
    procedure InsertBefore(const ANode: TIdLinkList<T>);
    /// <summary>Places the node after the given one (at the beginning of the list if that is the head)</summary>
    procedure InsertAfter(const ANode: TIdLinkList<T>);
    procedure AddToEnd(const ANode: TIdLinkList<T>);
    procedure AddToFront(const ANode: TIdLinkList<T>);
    procedure Remove;
    /// <summary>The next owner, nil at the end of the list</summary>
    function Next: T;
    function Prev: T;
    function Owner: T;
    procedure SetOwner(const AObject: T);
    /// <summary>The head of the list; the node itself if it is not in a list</summary>
    function ListHead: TIdLinkList<T>;
    /// <summary>The next node, nil at the end of the list</summary>
    function NextNode: TIdLinkList<T>;
    function PrevNode: TIdLinkList<T>;
  end;

implementation

{ TIdLinkList<T> }

constructor TIdLinkList<T>.Create;
begin
  inherited Create;
  FOwner := nil;
  FHead := Self;
  FNext := Self;
  FPrev := Self;
end;

destructor TIdLinkList<T>.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TIdLinkList<T>.IsListEmpty: Boolean;
begin
  Result := FHead.FNext = FHead;
end;

function TIdLinkList<T>.InList: Boolean;
begin
  Result := FHead <> Self;
end;

function TIdLinkList<T>.Num: Integer;
var
  LNode: TIdLinkList<T>;
begin
  Result := 0;
  LNode := FHead.FNext;
  while LNode <> FHead do
  begin
    Inc(Result);
    LNode := LNode.FNext;
  end;
end;

procedure TIdLinkList<T>.Clear;
begin
  if FHead = Self then
  begin
    while FNext <> Self do
      FNext.Remove;
  end
  else
    Remove;
end;

procedure TIdLinkList<T>.Remove;
begin
  FPrev.FNext := FNext;
  FNext.FPrev := FPrev;
  FNext := Self;
  FPrev := Self;
  FHead := Self;
end;

procedure TIdLinkList<T>.InsertBefore(const ANode: TIdLinkList<T>);
begin
  Remove;
  FNext := ANode;
  FPrev := ANode.FPrev;
  ANode.FPrev := Self;
  FPrev.FNext := Self;
  FHead := ANode.FHead;
end;

procedure TIdLinkList<T>.InsertAfter(const ANode: TIdLinkList<T>);
begin
  Remove;
  FPrev := ANode;
  FNext := ANode.FNext;
  ANode.FNext := Self;
  FNext.FPrev := Self;
  FHead := ANode.FHead;
end;

procedure TIdLinkList<T>.AddToEnd(const ANode: TIdLinkList<T>);
begin
  InsertBefore(ANode.FHead);
end;

procedure TIdLinkList<T>.AddToFront(const ANode: TIdLinkList<T>);
begin
  InsertAfter(ANode.FHead);
end;

function TIdLinkList<T>.Next: T;
begin
  if (not Assigned(FNext)) or (FNext = FHead) then
    Exit(nil);
  Result := FNext.FOwner;
end;

function TIdLinkList<T>.Prev: T;
begin
  if (not Assigned(FPrev)) or (FPrev = FHead) then
    Exit(nil);
  Result := FPrev.FOwner;
end;

function TIdLinkList<T>.Owner: T;
begin
  Result := FOwner;
end;

procedure TIdLinkList<T>.SetOwner(const AObject: T);
begin
  FOwner := AObject;
end;

function TIdLinkList<T>.ListHead: TIdLinkList<T>;
begin
  Result := FHead;
end;

function TIdLinkList<T>.NextNode: TIdLinkList<T>;
begin
  if FNext = FHead then
    Exit(nil);
  Result := FNext;
end;

function TIdLinkList<T>.PrevNode: TIdLinkList<T>;
begin
  if FPrev = FHead then
    Exit(nil);
  Result := FPrev;
end;

end.
