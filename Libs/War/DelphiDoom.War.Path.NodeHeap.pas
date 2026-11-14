{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the binary heap of the path finding               }
{                                                                              }
{  Port of the WarMapNodeHeap of war1 (acoto87/war1, war_pathfinder.c over     }
{  shl/binary_heap.h by the same author, MIT), (c) 2018-2019 Alejandro Coto    }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an         }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Path.NodeHeap;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Path.Types;

type
  /// <summary>
  ///   The open set of the A star and of the flow field: a min heap on FScore with the exact sift up and sift down of
  ///   shl/binary_heap.h. The order in which equal scores come out decides which parent a tile gets, so the heap is a
  ///   copy, not a better heap. The only difference is the search by tile (IndexOf): the original scans the heap, here
  ///   a table keeps the position of every tile; it gives the same answer because a tile is never twice in the heap
  /// </summary>
  TWarNodeHeap = class
  strict private
    FItems: array[0..WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT - 1] of TWarPathNode;
    // the position in the heap plus one of the node of a tile, 0 if the tile is not in the heap
    FPosition: array[0..WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT - 1] of SmallInt;
    FCount: Integer;
    procedure Swap(AFirst, ASecond: Integer); inline;
    procedure HeapUp(AIndex: Integer);
    procedure HeapDown(AIndex: Integer);
    function Compare(AFirst, ASecond: Integer): Integer; inline;
    function GetItem(AIndex: Integer): TWarPathNode;
  public
    /// <summary>Empties the heap</summary>
    procedure Clear;
    /// <summary>WarMapNodeHeapPush; the tile of the node must not be in the heap (the callers look it up first)</summary>
    procedure Push(const ANode: TWarPathNode);
    /// <summary>WarMapNodeHeapPop; the node with the lowest FScore (the heap must not be empty)</summary>
    function Pop: TWarPathNode;
    /// <summary>WarMapNodeHeapIndexOf: the position of the node of the tile ATileId, -1 if it is not in the heap</summary>
    function IndexOf(ATileId: Integer): Integer; inline;
    /// <summary>WarMapNodeHeapUpdate: replaces the node at AIndex and restores the order</summary>
    procedure Update(AIndex: Integer; const ANode: TWarPathNode);
    property Count: Integer read FCount;
    property Items[AIndex: Integer]: TWarPathNode read GetItem; default;
  end;

implementation

{ TWarNodeHeap }

procedure TWarNodeHeap.Clear;
var
  LIndex: Integer;
begin
  // only the tiles that are still in the heap have a position
  for LIndex := 0 to FCount - 1 do
    FPosition[FItems[LIndex].Id] := 0;
  FCount := 0;
end;

function TWarNodeHeap.Compare(AFirst, ASecond: Integer): Integer;
begin
  // compareFScore: the difference of the two scores
  Result := FItems[AFirst].FScore - FItems[ASecond].FScore;
end;

procedure TWarNodeHeap.Swap(AFirst, ASecond: Integer);
var
  LTemp: TWarPathNode;
begin
  LTemp := FItems[AFirst];
  FItems[AFirst] := FItems[ASecond];
  FItems[ASecond] := LTemp;
  FPosition[FItems[AFirst].Id] := SmallInt(AFirst + 1);
  FPosition[FItems[ASecond].Id] := SmallInt(ASecond + 1);
end;

procedure TWarNodeHeap.HeapUp(AIndex: Integer);
var
  LParent: Integer;
begin
  LParent := (AIndex - 1) shr 1;
  while (AIndex > 0) and (Compare(AIndex, LParent) < 0) do
  begin
    Swap(AIndex, LParent);
    AIndex := LParent;
    LParent := (AIndex - 1) shr 1;
  end;
end;

procedure TWarNodeHeap.HeapDown(AIndex: Integer);
var
  LLeft: Integer;
  LRight: Integer;
  LMin: Integer;
begin
  while AIndex < FCount do
  begin
    LLeft := 2 * AIndex + 1;
    if LLeft >= FCount then
      Break;
    LMin := LLeft;
    LRight := 2 * AIndex + 2;
    if LRight < FCount then
      if Compare(LRight, LMin) < 0 then
        LMin := LRight;
    if Compare(LMin, AIndex) >= 0 then
      Break;
    Swap(AIndex, LMin);
    AIndex := LMin;
  end;
end;

procedure TWarNodeHeap.Push(const ANode: TWarPathNode);
begin
  FItems[FCount] := ANode;
  FPosition[ANode.Id] := SmallInt(FCount + 1);
  HeapUp(FCount);
  Inc(FCount);
end;

function TWarNodeHeap.Pop: TWarPathNode;
begin
  Result := FItems[0];
  FPosition[Result.Id] := 0;
  Dec(FCount);
  if FCount > 0 then
  begin
    FItems[0] := FItems[FCount];
    FPosition[FItems[0].Id] := 1;
    HeapDown(0);
  end;
end;

function TWarNodeHeap.IndexOf(ATileId: Integer): Integer;
begin
  Result := FPosition[ATileId] - 1;
end;

procedure TWarNodeHeap.Update(AIndex: Integer; const ANode: TWarPathNode);
var
  LCompare: Integer;
  LOldScore: Integer;
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    Exit;
  LOldScore := FItems[AIndex].FScore;
  FItems[AIndex] := ANode;
  LCompare := ANode.FScore - LOldScore;
  if LCompare < 0 then
    HeapUp(AIndex)
  else if LCompare > 0 then
    HeapDown(AIndex);
end;

function TWarNodeHeap.GetItem(AIndex: Integer): TWarPathNode;
begin
  Result := FItems[AIndex];
end;

end.
