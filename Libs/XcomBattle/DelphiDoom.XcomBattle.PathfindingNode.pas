{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - a node of the pathfinding             }
{  (PathfindingNode)                                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.PathfindingNode;

interface

uses
  System.Math, DelphiDoom.XcomMod.MapBlock;

type
  TXcomPathfindingNode = class;

  /// <summary>OpenSetEntry: a place in the queue; a discarded entry has no node</summary>
  TXcomOpenSetEntry = class
  public
    Cost: Integer;
    Node: TXcomPathfindingNode;
  end;

  /// <summary>One node per tile of the map, with the cost and the way it was reached (PathfindingNode)</summary>
  TXcomPathfindingNode = class
  strict private
    FPosition: TXcomPosition;
    FChecked: Boolean;
    FTuCost: Integer;
    FPreviousNode: TXcomPathfindingNode;
    FPreviousDirection: Integer;
    FTuGuess: Integer;
    FOpenEntry: TXcomOpenSetEntry;
  public
    constructor Create(const APosition: TXcomPosition);
    /// <summary>reset: forgets that the node was checked and that it is in the open set</summary>
    procedure Reset;
    /// <summary>getTUCost: a missile does not count the cost</summary>
    function GetTuCost(AMissile: Boolean): Integer;
    /// <summary>connect with a target: also gives the estimate (4 times the distance) if the node is not queued</summary>
    procedure Connect(ATuCost: Integer; const APreviousNode: TXcomPathfindingNode; APreviousDirection: Integer;
      const ATarget: TXcomPosition); overload;
    /// <summary>connect with no target: the estimate is 0 (Dijkstra)</summary>
    procedure Connect(ATuCost: Integer; const APreviousNode: TXcomPathfindingNode;
      APreviousDirection: Integer); overload;
    function InOpenSet: Boolean;
    procedure SetChecked;
    property Position: TXcomPosition read FPosition;
    property IsChecked: Boolean read FChecked;
    property PreviousNode: TXcomPathfindingNode read FPreviousNode;
    property PreviousDirection: Integer read FPreviousDirection;
    property TuGuess: Integer read FTuGuess;
    property OpenEntry: TXcomOpenSetEntry read FOpenEntry write FOpenEntry;
  end;

implementation

constructor TXcomPathfindingNode.Create(const APosition: TXcomPosition);
begin
  inherited Create;
  FPosition := APosition;
end;

procedure TXcomPathfindingNode.Reset;
begin
  FChecked := False;
  FOpenEntry := nil;
end;

function TXcomPathfindingNode.GetTuCost(AMissile: Boolean): Integer;
begin
  if AMissile then
    Result := 0
  else
    Result := FTuCost;
end;

procedure TXcomPathfindingNode.Connect(ATuCost: Integer; const APreviousNode: TXcomPathfindingNode;
  APreviousDirection: Integer; const ATarget: TXcomPosition);
var
  LDistance: TXcomPosition;
  LSum: Double;
begin
  FTuCost := ATuCost;
  FPreviousNode := APreviousNode;
  FPreviousDirection := APreviousDirection;
  if not InOpenSet then
  begin
    LDistance := ATarget - FPosition;
    LSum := Double(LDistance.X * LDistance.X) + LDistance.Y * LDistance.Y + LDistance.Z * LDistance.Z;
    FTuGuess := Trunc(4 * Sqrt(LSum));
  end;
end;

procedure TXcomPathfindingNode.Connect(ATuCost: Integer; const APreviousNode: TXcomPathfindingNode;
  APreviousDirection: Integer);
begin
  FTuCost := ATuCost;
  FPreviousNode := APreviousNode;
  FPreviousDirection := APreviousDirection;
  FTuGuess := 0;
end;

function TXcomPathfindingNode.InOpenSet: Boolean;
begin
  Result := Assigned(FOpenEntry);
end;

procedure TXcomPathfindingNode.SetChecked;
begin
  FChecked := True;
end;

end.
