{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - a model with a forest and a mine     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.GatherRig;

interface

uses
  System.SysUtils, DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Intf, DelphiDoom.War.Map.Fog,
  DelphiDoom.War.Map.Forests, DelphiDoom.War.Map.Forest, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.GatherWorld,
  DelphiDoom.Tests.War.ModelRig, DelphiDoom.Tests.War.GatherScenario;

type
  /// <summary>
  ///   A TModelRig that has also the map of the gatherers: forests on its grid (fog disabled, a painter that records),
  ///   gold mines and town halls that are one call away. The humans are the player 0 and the orcs the player 1
  /// </summary>
  TGatherRig = class
  strict private
    FRig: TModelRig;
    FFog: TWarFogOfWar;
    FForests: TWarMapForests;
    FPainter: TRecordingPainter;
    FPainterRef: IWarTilePainter;
    FGather: TWarGatherWorld;
  public
    /// <summary>
    ///   Without ARealFollow the follow states stay where they are (they are updated by the follow slice, tested there): the
    ///   tests of the gatherers look at the follow state that they push. With it the workers really walk
    /// </summary>
    constructor Create(ASeed: Cardinal = 1; ARealFollow: Boolean = False);
    destructor Destroy; override;
    /// <summary>A gold mine of the neutral player with that much gold, with its idle state; the slot</summary>
    function AddMine(AX, AY, AGold: Integer): Integer;
    /// <summary>A town hall of the race of the player (humans: player 0); the slot</summary>
    function AddTownHall(AX, AY: Integer; APlayer: Byte = 0): Integer;
    /// <summary>A forest entity with trees at the tiles (all with that much wood); the id of the forest</summary>
    function AddForest(const ATiles: array of Integer; AWood: Integer): Word;
    /// <summary>
    ///   A forest that is a block of trees (a lone tree has no neighbors and is not kept: it gets no tile) at (AX, AY)
    ///   with that much wood each; the id of the forest
    /// </summary>
    function AddForestBlock(AX, AY, AWidth, AHeight, AWood: Integer): Word;
    /// <summary>Sets the wood of the tree at the tile</summary>
    procedure SetWood(AForest: Word; AX, AY, AWood: Integer);
    /// <summary>The center of a tile, in pixels</summary>
    function TileCenter(AX, AY: Integer): TWarVec2;
    property Rig: TModelRig read FRig;
    property Forests: TWarMapForests read FForests;
    property Painter: TRecordingPainter read FPainter;
    property Gather: TWarGatherWorld read FGather;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Autotile.Types, DelphiDoom.War.Model.Math;

{ TGatherRig }

constructor TGatherRig.Create(ASeed: Cardinal; ARealFollow: Boolean);
begin
  inherited Create;
  FRig := TModelRig.Create(ASeed);
  if not ARealFollow then
    FRig.World.Machine.RegisterHooks(WAR_STATE_FOLLOW, nil, nil, nil);
  FFog := TWarFogOfWar.Create;
  FFog.Enabled := False;
  FPainter := TRecordingPainter.Create;
  FPainterRef := FPainter;
  FForests := TWarMapForests.Create(FRig.Grid, FFog, FPainterRef, WAR_TILESET_FOREST);
  FGather := TWarGatherWorld.Create(FRig.Grid, FForests, FRig.Observer);
  FRig.World.Context.Gather := FGather;
end;

destructor TGatherRig.Destroy;
begin
  FRig.Free;
  FGather.Free;
  FForests.Free;
  FFog.Free;
  FPainterRef := nil;
  inherited;
end;

function TGatherRig.AddMine(AX, AY, AGold: Integer): Integer;
begin
  Result := FRig.World.Entities.CreateUnit(WAR_UNIT_GOLDMINE, AX, AY, 4, wrkGold, Cardinal(AGold), True);
  FRig.World.Entities.SetInitialIdle(Result);
  FRig.Tick;
end;

function TGatherRig.AddTownHall(AX, AY: Integer; APlayer: Byte): Integer;
begin
  if APlayer = 0 then
    Result := FRig.AddBuilding(WAR_UNIT_TOWNHALL_HUMANS, AX, AY, APlayer)
  else
    Result := FRig.AddBuilding(WAR_UNIT_TOWNHALL_ORCS, AX, AY, APlayer);
end;

function TGatherRig.AddForest(const ATiles: array of Integer; AWood: Integer): Word;
var
  LSlot: Integer;
  LForest: TWarMapForest;
  LTree: TWarTree;
  LIndex: Integer;
begin
  LSlot := FRig.World.Context.Pool.CreateEntity(WAR_ENTITY_FOREST, True);
  Result := FRig.World.Context.Pool.Slots[LSlot]^.Id;
  LForest := FForests.AddForest(Result);
  LIndex := 0;
  while LIndex < Length(ATiles) do
  begin
    LTree := Default(TWarTree);
    LTree.TileX := ATiles[LIndex];
    LTree.TileY := ATiles[LIndex + 1];
    LTree.Amount := AWood;
    LForest.Trees.Add(LTree);
    FRig.Grid.SetStaticEntity(LTree.TileX, LTree.TileY, 1, 1, Result);
    Inc(LIndex, 2);
  end;
  FForests.DetermineTiles(LForest);
end;

function TGatherRig.AddForestBlock(AX, AY, AWidth, AHeight, AWood: Integer): Word;
var
  LTiles: TArray<Integer>;
  LX: Integer;
  LY: Integer;
begin
  SetLength(LTiles, 0);
  for LY := AY to AY + AHeight - 1 do
    for LX := AX to AX + AWidth - 1 do
      LTiles := LTiles + [LX, LY];
  Result := AddForest(LTiles, AWood);
end;

procedure TGatherRig.SetWood(AForest: Word; AX, AY, AWood: Integer);
var
  LForest: TWarMapForest;
  LIndex: Integer;
  LTree: TWarTree;
begin
  LForest := FForests.FindForest(AForest);
  LIndex := LForest.IndexOfTile(AX, AY);
  LTree := LForest.Trees[LIndex];
  LTree.Amount := AWood;
  LForest.Trees[LIndex] := LTree;
end;

function TGatherRig.TileCenter(AX, AY: Integer): TWarVec2;
begin
  Result := TWarModelMath.TileToMap(TWarModelMath.Vec(AX, AY), True);
end;

end.
