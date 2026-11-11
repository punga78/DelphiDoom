{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the queue of the nodes to check       }
{  (PathfindingOpenSet)                                                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.PathfindingOpenSet;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.PathfindingNode;

type
  /// <summary>
  ///   The queue of the nodes to check, cheapest first (PathfindingOpenSet over std::priority_queue). The heap
  ///   is the one of libstdc++ (push_heap, pop_heap and the adjustment of the hole), so nodes with the same cost
  ///   come out in the same order as in the C++ and A* chooses the same path
  /// </summary>
  TXcomPathfindingOpenSet = class
  strict private
    FHeap: TList<TXcomOpenSetEntry>;
    /// <summary>EntryCompare: the left entry is cheaper than the right one is NOT what it asks: b.cost &lt; a.cost</summary>
    class function Less(const AFirst, ASecond: TXcomOpenSetEntry): Boolean; static; inline;
    procedure PushHeap(AHole, ATop: Integer; const AValue: TXcomOpenSetEntry);
    procedure AdjustHeap(AHole, ALength: Integer; const AValue: TXcomOpenSetEntry);
    procedure PopTop;
    procedure RemoveDiscarded;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>pop: the node with the lowest cost plus estimate (an empty set is an error)</summary>
    function Pop: TXcomPathfindingNode;
    /// <summary>push: a node that is already queued has its old entry discarded</summary>
    procedure Push(const ANode: TXcomPathfindingNode);
    function IsEmpty: Boolean;
  end;

implementation

constructor TXcomPathfindingOpenSet.Create;
begin
  inherited Create;
  FHeap := TList<TXcomOpenSetEntry>.Create;
end;

destructor TXcomPathfindingOpenSet.Destroy;
var
  LEntry: TXcomOpenSetEntry;
begin
  for LEntry in FHeap do
    LEntry.Free;
  FHeap.Free;
  inherited Destroy;
end;

class function TXcomPathfindingOpenSet.Less(const AFirst, ASecond: TXcomOpenSetEntry): Boolean;
begin
  // the comparison of std::priority_queue is "a is below b": b.cost < a.cost
  Result := ASecond.Cost < AFirst.Cost;
end;

procedure TXcomPathfindingOpenSet.PushHeap(AHole, ATop: Integer; const AValue: TXcomOpenSetEntry);
var
  LParent: Integer;
begin
  LParent := (AHole - 1) div 2;
  while (AHole > ATop) and Less(FHeap[LParent], AValue) do
  begin
    FHeap[AHole] := FHeap[LParent];
    AHole := LParent;
    LParent := (AHole - 1) div 2;
  end;
  FHeap[AHole] := AValue;
end;

procedure TXcomPathfindingOpenSet.AdjustHeap(AHole, ALength: Integer; const AValue: TXcomOpenSetEntry);
var
  LTop: Integer;
  LChild: Integer;
begin
  LTop := AHole;
  LChild := AHole;
  while LChild < (ALength - 1) div 2 do
  begin
    LChild := 2 * (LChild + 1);
    if Less(FHeap[LChild], FHeap[LChild - 1]) then
      Dec(LChild);
    FHeap[AHole] := FHeap[LChild];
    AHole := LChild;
  end;
  if ((ALength and 1) = 0) and (LChild = (ALength - 2) div 2) then
  begin
    LChild := 2 * (LChild + 1);
    FHeap[AHole] := FHeap[LChild - 1];
    AHole := LChild - 1;
  end;
  PushHeap(AHole, LTop, AValue);
end;

procedure TXcomPathfindingOpenSet.PopTop;
var
  LValue: TXcomOpenSetEntry;
  LLast: Integer;
begin
  // std::pop_heap: the last entry goes to the top and the old top to the last place, then the hole is adjusted
  LLast := FHeap.Count - 1;
  LValue := FHeap[LLast];
  FHeap[LLast] := FHeap[0];
  if LLast > 0 then
    AdjustHeap(0, LLast, LValue);
  FHeap.Delete(LLast);
end;

procedure TXcomPathfindingOpenSet.RemoveDiscarded;
var
  LEntry: TXcomOpenSetEntry;
begin
  while (FHeap.Count > 0) and not Assigned(FHeap[0].Node) do
  begin
    LEntry := FHeap[0];
    PopTop;
    LEntry.Free;
  end;
end;

function TXcomPathfindingOpenSet.Pop: TXcomPathfindingNode;
var
  LEntry: TXcomOpenSetEntry;
begin
  if FHeap.Count = 0 then
    raise EXcomBattleException.Create('Xcom: pop of an empty open set');
  LEntry := FHeap[0];
  Result := LEntry.Node;
  PopTop;
  LEntry.Free;
  Result.OpenEntry := nil;
  RemoveDiscarded;
end;

procedure TXcomPathfindingOpenSet.Push(const ANode: TXcomPathfindingNode);
var
  LEntry: TXcomOpenSetEntry;
begin
  LEntry := TXcomOpenSetEntry.Create;
  LEntry.Node := ANode;
  LEntry.Cost := ANode.GetTuCost(False) + ANode.TuGuess;
  if Assigned(ANode.OpenEntry) then
    ANode.OpenEntry.Node := nil;
  ANode.OpenEntry := LEntry;
  FHeap.Add(LEntry);
  PushHeap(FHeap.Count - 1, 0, LEntry);
end;

function TXcomPathfindingOpenSet.IsEmpty: Boolean;
begin
  Result := FHeap.Count = 0;
end;

end.
