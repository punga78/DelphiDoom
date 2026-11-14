{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the list of the thinkers and its turn        }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.List;

interface

uses
  System.SysUtils;

type
  PThinkerNode = ^TThinkerNode;

  /// <summary>What a thinker does at its turn; it receives its own node</summary>
  TThinkerProc = procedure(ANode: Pointer);

  /// <summary>
  ///   A node of the list. It has the layout of the thinker_t of the engine (prev, next, function),
  ///   which is the first field of every thinker and is written as it is in the saved games
  /// </summary>
  TThinkerNode = record
    Prev: PThinkerNode;
    Next: PThinkerNode;
    Think: TThinkerProc;
  end;

  TThinkerListProc = procedure;
  TThinkerNodeProc = procedure(ANode: PThinkerNode);
  TThinkerNodeFilter = function(ANode: PThinkerNode): Boolean;

  /// <summary>
  ///   What the list asks to who owns the thinkers. Plain procedures given once: the turn runs for
  ///   every thinker at every tic and must not pay an interface or a virtual call
  /// </summary>
  TThinkerListHooks = record
    /// <summary>The list was emptied (before the links are reset)</summary>
    Cleared: TThinkerListProc;
    /// <summary>A node is about to be linked at the end of the list</summary>
    Added: TThinkerNodeProc;
    /// <summary>A node is about to be marked as removed (its function is still the one it had)</summary>
    Removed: TThinkerNodeProc;
    /// <summary>Frees a removed node, after it was unlinked at its turn</summary>
    Release: TThinkerNodeProc;
    /// <summary>Whether a node with a function thinks while the game is frozen</summary>
    RunsWhenFrozen: TThinkerNodeFilter;
  end;

  /// <summary>
  ///   The doubly linked list of the thinkers of a level (P_InitThinkers, P_AddThinker,
  ///   P_RemoveThinker, P_ThinkerIsRemoved and P_RunThinkers of p_tick). The head is a node that
  ///   belongs to the caller: the list links the thinkers to it and never frees it
  /// </summary>
  /// <remarks>
  ///   The removal is lazy: Remove only marks the node, which is unlinked and released when its
  ///   turn comes. The order of the turn, the moment of the release and the reading of the next
  ///   node after the thinker ran (a thinker may add or remove others) are the ones of the old
  ///   code: demos and net games depend on them
  /// </remarks>
  TThinkerList = class sealed
  strict private
    FHead: PThinkerNode;
    FRelease: TThinkerNodeProc;
    FRunsWhenFrozen: TThinkerNodeFilter;
    FCleared: TThinkerListProc;
    FAdded: TThinkerNodeProc;
    FRemoved: TThinkerNodeProc;
  public
    /// <param name="AHead">The node that is both the head and the tail of the list</param>
    /// <param name="AHooks">What the owner does; every procedure is required</param>
    /// <exception cref="EArgumentNilException">The head or a procedure is nil</exception>
    constructor Create(AHead: PThinkerNode; const AHooks: TThinkerListHooks);

    /// <summary>Empties the list: the nodes that were in it are forgotten, not released</summary>
    procedure Clear;
    /// <summary>Adds a node at the end of the list</summary>
    procedure Add(ANode: PThinkerNode);
    /// <summary>Marks a node as removed; it is unlinked and released at its next turn</summary>
    procedure Remove(ANode: PThinkerNode);
    /// <summary>True for a node marked by Remove and for one without a function</summary>
    class function IsRemoved(ANode: PThinkerNode): Boolean; static;
    /// <summary>The turn of a tic: releases the removed nodes and runs the others</summary>
    procedure Run;
    /// <summary>
    ///   The turn of a tic while the game is frozen: releases the removed nodes and runs only
    ///   the ones that the owner lets think
    /// </summary>
    procedure RunFrozen;

    property Head: PThinkerNode read FHead;
  end;

implementation

// The function of a removed node: never called, only its address is compared
procedure ThinkerRemovedMarker;
begin
end;

{ TThinkerList }

constructor TThinkerList.Create(AHead: PThinkerNode; const AHooks: TThinkerListHooks);
begin
  inherited Create;
  if not Assigned(AHead) then
    raise EArgumentNilException.Create('AHead');
  if not Assigned(AHooks.Cleared) then
    raise EArgumentNilException.Create('AHooks.Cleared');
  if not Assigned(AHooks.Added) then
    raise EArgumentNilException.Create('AHooks.Added');
  if not Assigned(AHooks.Removed) then
    raise EArgumentNilException.Create('AHooks.Removed');
  if not Assigned(AHooks.Release) then
    raise EArgumentNilException.Create('AHooks.Release');
  if not Assigned(AHooks.RunsWhenFrozen) then
    raise EArgumentNilException.Create('AHooks.RunsWhenFrozen');
  FHead := AHead;
  FCleared := AHooks.Cleared;
  FAdded := AHooks.Added;
  FRemoved := AHooks.Removed;
  FRelease := AHooks.Release;
  FRunsWhenFrozen := AHooks.RunsWhenFrozen;
end;

procedure TThinkerList.Clear;
begin
  FCleared;
  FHead.Prev := FHead;
  FHead.Next := FHead;
end;

procedure TThinkerList.Add(ANode: PThinkerNode);
var
  LHead: PThinkerNode;
begin
  FAdded(ANode);

  LHead := FHead;
  LHead.Prev.Next := ANode;
  ANode.Next := LHead;
  ANode.Prev := LHead.Prev;
  LHead.Prev := ANode;
end;

procedure TThinkerList.Remove(ANode: PThinkerNode);
begin
  FRemoved(ANode);
  @ANode.Think := @ThinkerRemovedMarker;
end;

class function TThinkerList.IsRemoved(ANode: PThinkerNode): Boolean;
begin
  Result := (@ANode.Think = @ThinkerRemovedMarker) or not Assigned(ANode.Think);
end;

procedure TThinkerList.Run;
var
  LHead: PThinkerNode;
  LCurrent: PThinkerNode;
  LNext: PThinkerNode;
begin
  LHead := FHead;
  LCurrent := LHead.Next;
  while LCurrent <> LHead do
  begin
    if @LCurrent.Think = @ThinkerRemovedMarker then
    begin
      // time to remove it
      LCurrent.Next.Prev := LCurrent.Prev;
      LCurrent.Prev.Next := LCurrent.Next;
      LNext := LCurrent.Next;
      FRelease(LCurrent);
      LCurrent := LNext;
    end
    else
    begin
      if Assigned(LCurrent.Think) then
        LCurrent.Think(LCurrent);
      // read after the call: the thinker may have added a node after itself
      LCurrent := LCurrent.Next;
    end;
  end;
end;

procedure TThinkerList.RunFrozen;
var
  LHead: PThinkerNode;
  LCurrent: PThinkerNode;
  LNext: PThinkerNode;
begin
  LHead := FHead;
  LCurrent := LHead.Next;
  while LCurrent <> LHead do
  begin
    if @LCurrent.Think = @ThinkerRemovedMarker then
    begin
      // time to remove it
      LCurrent.Next.Prev := LCurrent.Prev;
      LCurrent.Prev.Next := LCurrent.Next;
      LNext := LCurrent.Next;
      FRelease(LCurrent);
      LCurrent := LNext;
    end
    else
    begin
      if Assigned(LCurrent.Think) then
        if FRunsWhenFrozen(LCurrent) then
          LCurrent.Think(LCurrent);
      LCurrent := LCurrent.Next;
    end;
  end;
end;

end.
