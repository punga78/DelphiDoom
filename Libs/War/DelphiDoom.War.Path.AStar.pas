{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the A star                                        }
{                                                                              }
{  Port of war1 (acoto87/war1), war_pathfinder.c, wpath_astar, (c) 2019        }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Path.AStar;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, System.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.PathGrid, DelphiDoom.War.Path.Types,
  DelphiDoom.War.Path.NodeHeap;

type
  /// <summary>
  ///   wpath_astar: the path between two tiles on the grid of what is occupied. Eight directions, every step costs 1 and
  ///   the guess is the Manhattan distance, so the paths are not the shortest ones (defect of the original kept: the
  ///   result decides where a unit would go). A tile with something static on it is never entered, not even the end: if
  ///   the end cannot be reached the path goes to the closest tile that was reached (the first of the closed set, in the
  ///   memory order of the table of the original, when two are as close to the end and to the start). Nothing in the game
  ///   calls it (the units follow flow fields: TWarFlowFields); it is ported for the tools and for the tests
  /// </summary>
  TWarAStar = class
  strict private
    FGrid: TWarPathGrid;
    FHeap: TWarNodeHeap;
    FClosed: array[0..WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT - 1] of TWarPathNode;
    FStamp: array[0..WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT - 1] of Cardinal;
    FGeneration: Cardinal;
    FOrder: array[0..WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT - 1] of Integer;
    FOrderCount: Integer;
    class function Manhattan(const AFirst, ASecond: TWarPathNode): Integer; static; inline;
    class function DistanceSqr(const AFirst, ASecond: TWarPathNode): Integer; static; inline;
    class function CreateNode(AX, AY: Integer): TWarPathNode; static; inline;
    function ClosestClosed(const AStart, AEnd: TWarPathNode): TWarPathNode;
  public
    /// <summary>The grid is not owned</summary>
    constructor Create(const AGrid: TWarPathGrid);
    destructor Destroy; override;
    /// <summary>
    ///   Finds the path and writes it to APath (the tiles from the start, the end or the closest tile that was reached
    ///   last) and gives True. If the search closes only one tile (the start is the end, or it is shut in) the original
    ///   leaves the path as the caller had it: APath is not touched and the result is False. A tile outside the map is
    ///   EWarException (the original asserts)
    /// </summary>
    function FindPath(AStartX, AStartY, AEndX, AEndY: Integer; var APath: TWarMapPath): Boolean;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Path.ScatterTable;

{ TWarAStar }

constructor TWarAStar.Create(const AGrid: TWarPathGrid);
begin
  inherited Create;
  FGrid := AGrid;
  FHeap := TWarNodeHeap.Create;
end;

destructor TWarAStar.Destroy;
begin
  FHeap.Free;
  inherited;
end;

class function TWarAStar.Manhattan(const AFirst, ASecond: TWarPathNode): Integer;
begin
  Result := Abs(AFirst.X - ASecond.X) + Abs(AFirst.Y - ASecond.Y);
end;

class function TWarAStar.DistanceSqr(const AFirst, ASecond: TWarPathNode): Integer;
var
  LX: Integer;
  LY: Integer;
begin
  LX := AFirst.X - ASecond.X;
  LY := AFirst.Y - ASecond.Y;
  Result := LX * LX + LY * LY;
end;

class function TWarAStar.CreateNode(AX, AY: Integer): TWarPathNode;
begin
  Result.Id := AY * WAR_MAP_TILES_WIDTH + AX;
  Result.X := AX;
  Result.Y := AY;
  Result.Level := 0;
  Result.Parent := -1;
  Result.GScore := WAR_FLOW_UNREACHED;
  Result.FScore := WAR_FLOW_UNREACHED;
end;

function TWarAStar.ClosestClosed(const AStart, AEnd: TWarPathNode): TWarPathNode;
var
  LTable: TWarScatterTable;
  LIndex: Integer;
  LNode: TWarPathNode;
  LMinToEnd: Integer;
  LMinFromStart: Integer;
  LToEnd: Integer;
  LFromStart: Integer;
begin
  Result := Default(TWarPathNode);
  LTable := TWarScatterTable.Create;
  try
    // the closed set of the original is a hash table and the scan is by bucket: the same table, filled in the same order
    for LIndex := 0 to FOrderCount - 1 do
      LTable.Add(FOrder[LIndex]);
    LMinToEnd := WAR_FLOW_UNREACHED;
    LMinFromStart := WAR_FLOW_UNREACHED;
    for LIndex := 0 to LTable.Capacity - 1 do
    begin
      if not LTable.Active[LIndex] then
        Continue;
      LNode := FClosed[LTable.Keys[LIndex]];
      LToEnd := DistanceSqr(AEnd, LNode);
      if LToEnd < LMinToEnd then
      begin
        Result := LNode;
        LMinToEnd := LToEnd;
        LMinFromStart := DistanceSqr(AStart, LNode);
      end
      else if LToEnd = LMinToEnd then
      begin
        LFromStart := DistanceSqr(AStart, LNode);
        if LFromStart < LMinFromStart then
        begin
          Result := LNode;
          LMinToEnd := LToEnd;
          LMinFromStart := LFromStart;
        end;
      end;
    end;
  finally
    LTable.Free;
  end;
end;

function TWarAStar.FindPath(AStartX, AStartY, AEndX, AEndY: Integer; var APath: TWarMapPath): Boolean;
var
  LStart: TWarPathNode;
  LEnd: TWarPathNode;
  LCurrent: TWarPathNode;
  LNeighbor: TWarPathNode;
  LDirection: Integer;
  LX: Integer;
  LY: Integer;
  LId: Integer;
  LScore: Integer;
  LIndex: Integer;
  LNode: TWarPathNode;
  LLow: Integer;
  LHigh: Integer;
  LSwap: TPoint;
begin
  if not TWarPathGrid.IsInside(AStartX, AStartY) then
    raise EWarException.CreateFmt(SWarMapTileOutside, [AStartX, AStartY]);
  if not TWarPathGrid.IsInside(AEndX, AEndY) then
    raise EWarException.CreateFmt(SWarMapTileOutside, [AEndX, AEndY]);
  Inc(FGeneration);
  if FGeneration = 0 then
  begin
    FillChar(FStamp, SizeOf(FStamp), 0);
    FGeneration := 1;
  end;
  FHeap.Clear;
  FOrderCount := 0;
  LStart := CreateNode(AStartX, AStartY);
  LEnd := CreateNode(AEndX, AEndY);
  // the cost of going from the start to the start is zero; the guess for the first node is only the heuristic
  LStart.GScore := 0;
  LStart.FScore := Manhattan(LStart, LEnd);
  LEnd.GScore := WAR_FLOW_UNREACHED;
  LEnd.FScore := 0;
  FHeap.Push(LStart);
  while FHeap.Count > 0 do
  begin
    LCurrent := FHeap.Pop;
    FClosed[LCurrent.Id] := LCurrent;
    FStamp[LCurrent.Id] := FGeneration;
    FOrder[FOrderCount] := LCurrent.Id;
    Inc(FOrderCount);
    if (LCurrent.X = LEnd.X) and (LCurrent.Y = LEnd.Y) then
      Break;
    for LDirection := 0 to WAR_PATH_DIRECTION_COUNT - 1 do
    begin
      LX := LCurrent.X + WAR_PATH_DIR_X[LDirection];
      LY := LCurrent.Y + WAR_PATH_DIR_Y[LDirection];
      if not TWarPathGrid.IsInside(LX, LY) then
        Continue;
      LId := LY * WAR_MAP_TILES_WIDTH + LX;
      // a tile with something static on it is not considered, so that a unit goes around it
      if FGrid.IsStaticAt(LId) then
        Continue;
      if FStamp[LId] = FGeneration then
        Continue;
      LNeighbor := CreateNode(LX, LY);
      LScore := LCurrent.GScore + 1;
      LIndex := FHeap.IndexOf(LId);
      if LIndex >= 0 then
      begin
        LNeighbor := FHeap[LIndex];
        if LScore >= LNeighbor.GScore then
          Continue;
      end;
      LNeighbor.Parent := LCurrent.Id;
      LNeighbor.GScore := LScore;
      LNeighbor.FScore := LNeighbor.GScore + Manhattan(LNeighbor, LEnd);
      if LIndex >= 0 then
        FHeap.Update(LIndex, LNeighbor)
      else
        FHeap.Push(LNeighbor);
    end;
  end;
  Result := FOrderCount > 1;
  if not Result then
    Exit;
  if FStamp[LEnd.Id] <> FGeneration then
    // the end is unreachable: the closest tile that was reached
    LNode := ClosestClosed(LStart, LEnd)
  else
    LNode := FClosed[LEnd.Id];
  APath.Count := 0;
  while LNode.Parent >= 0 do
  begin
    APath.Nodes[APath.Count].X := LNode.X;
    APath.Nodes[APath.Count].Y := LNode.Y;
    Inc(APath.Count);
    LNode := FClosed[LNode.Parent];
  end;
  APath.Nodes[APath.Count].X := LStart.X;
  APath.Nodes[APath.Count].Y := LStart.Y;
  Inc(APath.Count);
  LLow := 0;
  LHigh := APath.Count - 1;
  while LLow < LHigh do
  begin
    LSwap := APath.Nodes[LLow];
    APath.Nodes[LLow] := APath.Nodes[LHigh];
    APath.Nodes[LHigh] := LSwap;
    Inc(LLow);
    Dec(LHigh);
  end;
end;

end.
