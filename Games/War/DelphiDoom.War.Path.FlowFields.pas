{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the flow fields of the map                        }
{                                                                              }
{  Port of war1 (acoto87/war1), war_pathfinder.c, wpath_flowField,             }
{  wpath_computeFlowField, wpath_getFlowField and wpath_ensureFlowField,       }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see Games\War\LICENSE-     }
{  war1.txt). This is an altered version, not the original.                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Path.FlowFields;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.PathGrid, DelphiDoom.War.Path.Types,
  DelphiDoom.War.Path.NodeHeap, DelphiDoom.War.Path.FlowField;

type
  /// <summary>
  ///   The flow fields of a map, one per goal tile, made when a unit asks for them. A field is the Dijkstra search from the
  ///   goal over the tiles with nothing static on them (the units that stand still count: the original keeps them in the
  ///   same grid) and it is kept: nothing in the original invalidates it, a field is made again only when a move command
  ///   goes to its goal or when a unit is stuck for half a second (TWarFlowFields.Compute). So what the field knew when it
  ///   was made is game data, and the tests keep a signature of every field computed. The costs are 100 along an axis and
  ///   141 along a diagonal, and a diagonal step may cut the corner between two static tiles (defects of the original kept)
  /// </summary>
  TWarFlowFields = class
  strict private
    FGrid: TWarPathGrid;
    FHeap: TWarNodeHeap;
    FFields: array[0..WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT - 1] of TWarFlowField;
    FClosed: array[0..WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT - 1] of TWarPathNode;
    FStamp: array[0..WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT - 1] of Cardinal;
    FOrder: array[0..WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT - 1] of Integer;
    FGeneration: Cardinal;
    FCount: Integer;
    FComputeCount: Integer;
    FSignature: Cardinal;
    FTrackSignature: Boolean;
    procedure CheckTile(ATileX, ATileY: Integer);
    procedure Search(AGoalX, AGoalY: Integer; const AField: TWarFlowField);
    procedure MixSignature(AIndex: Integer; const AField: TWarFlowField);
  public
    /// <summary>The grid of what is occupied is not owned</summary>
    constructor Create(const AGrid: TWarPathGrid);
    destructor Destroy; override;
    /// <summary>
    ///   wpath_computeFlowField: makes the field of the goal tile again, always (the old one of the same goal is
    ///   overwritten, whoever holds it sees the new one). A tile outside the map is EWarException (the original asserts)
    /// </summary>
    function Compute(ATileX, ATileY: Integer): TWarFlowField;
    /// <summary>wpath_getFlowField: the field of the goal tile if it was made, nil if not</summary>
    function Get(ATileX, ATileY: Integer): TWarFlowField;
    /// <summary>wpath_ensureFlowField: the field of the goal tile, made now only if it was never made</summary>
    function Ensure(ATileX, ATileY: Integer): TWarFlowField;
    /// <summary>How many goals have a field</summary>
    property Count: Integer read FCount;
    /// <summary>How many fields were computed (a goal computed twice counts twice)</summary>
    property ComputeCount: Integer read FComputeCount;
    /// <summary>
    ///   Off by default. When on, a running FNV-1a over the goal and the costs and directions of every field computed:
    ///   two games that ran the same orders have the same signature, and the first tic where it differs is where a field
    ///   was made at another time or from another grid (what the parity tests use)
    /// </summary>
    property TrackSignature: Boolean read FTrackSignature write FTrackSignature;
    /// <summary>The signature (the FNV-1a offset basis while no field was computed)</summary>
    property Signature: Cardinal read FSignature;
  end;

implementation

uses
  DelphiDoom.War.Map.Types, DelphiDoom.War.Types;

const
  FNV_BASIS = 2166136261;
  FNV_PRIME = 16777619;

{ TWarFlowFields }

constructor TWarFlowFields.Create(const AGrid: TWarPathGrid);
begin
  inherited Create;
  FGrid := AGrid;
  FHeap := TWarNodeHeap.Create;
  FSignature := FNV_BASIS;
end;

destructor TWarFlowFields.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to Length(FFields) - 1 do
    FFields[LIndex].Free;
  FHeap.Free;
  inherited;
end;

procedure TWarFlowFields.CheckTile(ATileX, ATileY: Integer);
begin
  if not TWarPathGrid.IsInside(ATileX, ATileY) then
    raise EWarException.CreateFmt(SWarMapTileOutside, [ATileX, ATileY]);
end;

procedure TWarFlowFields.Search(AGoalX, AGoalY: Integer; const AField: TWarFlowField);
var
  LStart: TWarPathNode;
  LCurrent: TWarPathNode;
  LNeighbor: TWarPathNode;
  LDirection: Integer;
  LX: Integer;
  LY: Integer;
  LId: Integer;
  LScore: Integer;
  LIndex: Integer;
  LOrderCount: Integer;
  LNode: TWarPathNode;
  LParentX: Integer;
  LParentY: Integer;
  LDeltaX: Integer;
  LDeltaY: Integer;
  LStep: Integer;
begin
  Inc(FGeneration);
  if FGeneration = 0 then
  begin
    FillChar(FStamp, SizeOf(FStamp), 0);
    FGeneration := 1;
  end;
  FHeap.Clear;
  LOrderCount := 0;
  // the goal: the cost of going from the goal to the goal is zero and so is the score
  LStart.Id := AGoalY * WAR_MAP_TILES_WIDTH + AGoalX;
  LStart.X := AGoalX;
  LStart.Y := AGoalY;
  LStart.Level := 0;
  LStart.Parent := -1;
  LStart.GScore := 0;
  LStart.FScore := 0;
  FHeap.Push(LStart);
  while FHeap.Count > 0 do
  begin
    LCurrent := FHeap.Pop;
    FClosed[LCurrent.Id] := LCurrent;
    FStamp[LCurrent.Id] := FGeneration;
    FOrder[LOrderCount] := LCurrent.Id;
    Inc(LOrderCount);
    for LDirection := 0 to WAR_PATH_DIRECTION_COUNT - 1 do
    begin
      LX := LCurrent.X + WAR_PATH_DIR_X[LDirection];
      LY := LCurrent.Y + WAR_PATH_DIR_Y[LDirection];
      if not TWarPathGrid.IsInside(LX, LY) then
        Continue;
      LId := LY * WAR_MAP_TILES_WIDTH + LX;
      if FGrid.IsStaticAt(LId) then
        Continue;
      if FStamp[LId] = FGeneration then
        Continue;
      LNeighbor.Id := LId;
      LNeighbor.X := LX;
      LNeighbor.Y := LY;
      LNeighbor.Level := 0;
      LNeighbor.Parent := -1;
      LNeighbor.GScore := WAR_FLOW_UNREACHED;
      LNeighbor.FScore := WAR_FLOW_UNREACHED;
      // the odd directions are the diagonals
      if (LDirection and 1) <> 0 then
        LStep := WAR_FLOW_COST_DIAGONAL
      else
        LStep := WAR_FLOW_COST_STRAIGHT;
      LScore := LCurrent.GScore + LStep;
      LIndex := FHeap.IndexOf(LId);
      if LIndex >= 0 then
      begin
        LNeighbor := FHeap[LIndex];
        if LScore >= LNeighbor.GScore then
          Continue;
      end;
      LNeighbor.Parent := LCurrent.Id;
      LNeighbor.GScore := LScore;
      LNeighbor.FScore := LScore;
      if LIndex >= 0 then
        FHeap.Update(LIndex, LNeighbor)
      else
        FHeap.Push(LNeighbor);
    end;
  end;
  if LOrderCount <= 1 then
    Exit;
  for LIndex := 0 to LOrderCount - 1 do
  begin
    LNode := FClosed[FOrder[LIndex]];
    if LNode.Parent < 0 then
      Continue;
    LParentX := LNode.Parent mod WAR_MAP_TILES_WIDTH;
    LParentY := LNode.Parent div WAR_MAP_TILES_WIDTH;
    LDeltaX := LParentX - LNode.X;
    LDeltaY := LParentY - LNode.Y;
    for LDirection := 0 to WAR_PATH_DIRECTION_COUNT - 1 do
      if (LDeltaX = WAR_PATH_DIR_X[LDirection]) and (LDeltaY = WAR_PATH_DIR_Y[LDirection]) then
      begin
        AField.SetTile(LNode.Id, LNode.GScore, LDirection);
        Break;
      end;
  end;
end;

procedure TWarFlowFields.MixSignature(AIndex: Integer; const AField: TWarFlowField);
var
  LHash: Cardinal;
  LIndex: Integer;
begin
  LHash := FNV_BASIS;
  for LIndex := 0 to WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT - 1 do
    LHash := (LHash xor Cardinal(AField.Cost[LIndex])) * FNV_PRIME;
  for LIndex := 0 to WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT - 1 do
    LHash := (LHash xor Cardinal(AField.Direction[LIndex])) * FNV_PRIME;
  FSignature := (FSignature xor Cardinal(AIndex)) * FNV_PRIME;
  FSignature := (FSignature xor LHash) * FNV_PRIME;
end;

function TWarFlowFields.Compute(ATileX, ATileY: Integer): TWarFlowField;
var
  LIndex: Integer;
begin
  CheckTile(ATileX, ATileY);
  LIndex := ATileY * WAR_MAP_TILES_WIDTH + ATileX;
  if not Assigned(FFields[LIndex]) then
  begin
    FFields[LIndex] := TWarFlowField.Create;
    Inc(FCount);
  end;
  Result := FFields[LIndex];
  Result.Clear;
  Search(ATileX, ATileY, Result);
  Inc(FComputeCount);
  if FTrackSignature then
    MixSignature(LIndex, Result);
end;

function TWarFlowFields.Get(ATileX, ATileY: Integer): TWarFlowField;
begin
  CheckTile(ATileX, ATileY);
  Result := FFields[ATileY * WAR_MAP_TILES_WIDTH + ATileX];
end;

function TWarFlowFields.Ensure(ATileX, ATileY: Integer): TWarFlowField;
begin
  Result := Get(ATileX, ATileY);
  if not Assigned(Result) then
    Result := Compute(ATileX, ATileY);
end;

end.
