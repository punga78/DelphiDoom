{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the model of a game map                           }
{                                                                              }
{  Port of war1 (acoto87/war1), createStartingEntities and the entities that   }
{  wmap_enterMap of war_map.c makes, (c) 2019 Alejandro Coto Gutierrez, zlib   }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version, not    }
{  the original.                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.MapBinding;

interface

uses
  DelphiDoom.War.Map.Game, DelphiDoom.War.Model.World, DelphiDoom.War.Model.GatherWorld, DelphiDoom.War.Model.Commands.Intf, DelphiDoom.War.Model.Commands.Dispatcher;

type
  /// <summary>
  ///   The model of the game of a map that TWarMapBuilder made from a level: the entities of the map (forests, road,
  ///   wall, ruins) and its starting units are created again in the model with TWarEntityManager, in the same order,
  ///   so that they take the same ids (EWarException if one does not); the model works on the grid, the forests and the
  ///   fog of the map. From then on the units of the game are those of the model, and the list of units of the map
  ///   (which its fog and its minimap read) is what SyncUnits copies from them: the map has no units of its own any
  ///   more. The map is not owned; the binding owns the world and the commands of the player
  /// </summary>
  TWarMapBinding = class
  strict private
    FMap: TWarGameMap;
    FWorld: TWarModelWorld;
    FGather: TWarGatherWorld;
    FCommandMap: IWarCommandMap;
    FCommands: TWarCommands;
    procedure CreateTerrain;
    procedure CreateUnits;
  public
    /// <summary>
    ///   Made by TWarModelFactory.CreateMapBinding, which builds the parts: a new world over the grid of the map, the
    ///   gatherers' view of the map, the map of the commands and the commands of the player. The binding owns them
    /// </summary>
    constructor Create(const AMap: TWarGameMap; const AWorld: TWarModelWorld; const AGather: TWarGatherWorld;
      const ACommandMap: IWarCommandMap; const ACommands: TWarCommands);
    destructor Destroy; override;
    /// <summary>
    ///   The list of units of the map becomes the units of the model as they are now (tile, hit points, mana, who is
    ///   dying or collapsing): call it before the fog and the minimap of the map are updated
    /// </summary>
    procedure SyncUnits;
    /// <summary>A whole tic of the model (TWarModelWorld.Tick) and SyncUnits</summary>
    procedure Tick(ADeltaTime: Single);
    property Map: TWarGameMap read FMap;
    property World: TWarModelWorld read FWorld;
    /// <summary>The commands of the player, which see the grid and the fog of the map</summary>
    property Commands: TWarCommands read FCommands;
    property CommandMap: IWarCommandMap read FCommandMap;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Types, DelphiDoom.War.Level.Types,
  DelphiDoom.War.Map.Types, DelphiDoom.War.Autotile.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.TerrainEntities, DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.Construction.Types;

resourcestring
  SWarModelMapMismatch = 'The %s of the map has the id %d and the model gave it %d';

procedure CheckId(const AWhat: string; AExpected, AActual: Word);
begin
  if AExpected <> AActual then
    raise EWarException.CreateFmt(SWarModelMapMismatch, [AWhat, AExpected, AActual]);
end;

{ TWarMapBinding }

constructor TWarMapBinding.Create(const AMap: TWarGameMap; const AWorld: TWarModelWorld;
  const AGather: TWarGatherWorld; const ACommandMap: IWarCommandMap; const ACommands: TWarCommands);
var
  LPlayer: Integer;
begin
  inherited Create;
  FMap := AMap;
  FWorld := AWorld;
  FGather := AGather;
  FCommandMap := ACommandMap;
  FCommands := ACommands;
  FWorld.Context.Gather := FGather;
  for LPlayer := 0 to WAR_MAX_PLAYERS_COUNT - 1 do
    FWorld.Context.Players[LPlayer]^ := AMap.Players[LPlayer];
  FWorld.Context.PlayersCount := AMap.PlayersCount;
  // where the player looks at the start (the game writes it again when the view moves)
  FWorld.Context.ViewportTop := AMap.Viewport.Y;
  CreateTerrain;
  CreateUnits;
  SyncUnits;
end;

destructor TWarMapBinding.Destroy;
begin
  FCommands.Free;
  FCommandMap := nil;
  FWorld.Free;
  FGather.Free;
  inherited;
end;

// the entities that are not units, in the order in which the map made them: the forests (the one where the game plants
// trees is the last), the road, the wall and the ruins
procedure TWarMapBinding.CreateTerrain;
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LSlot: Integer;
  LPiece: TWarLinePiece;
  LWall: Integer;
begin
  LContext := FWorld.Context;
  for LIndex := 0 to FMap.Forests.Count - 1 do
  begin
    LSlot := LContext.Pool.CreateEntity(WAR_ENTITY_FOREST, True);
    CheckId('forest', FMap.Forests[LIndex].Id, LContext.Pool.Slots[LSlot]^.Id);
  end;
  LSlot := TWarTerrainEntities.CreateRoad(LContext);
  CheckId('road', FMap.RoadId, LContext.Pool.Slots[LSlot]^.Id);
  for LPiece in FMap.Road.Pieces do
    LContext.Roads.AddPiece(LPiece.TileX, LPiece.TileY, LPiece.Player);
  LContext.Roads.DetermineTypes;
  LSlot := TWarTerrainEntities.CreateWall(LContext, FWorld.Machine);
  CheckId('wall', FMap.WallId, LContext.Pool.Slots[LSlot]^.Id);
  for LPiece in FMap.Wall.Pieces do
  begin
    LWall := LContext.Walls.Add(LPiece.TileX, LPiece.TileY, LPiece.Player);
    LContext.Walls[LWall]^.Hp := WAR_WALL_MAX_HP;
    LContext.Walls[LWall]^.MaxHp := WAR_WALL_MAX_HP;
  end;
  LContext.Walls.DetermineTypes;
  LSlot := TWarTerrainEntities.CreateRuins(LContext);
  CheckId('ruins', FMap.RuinsId, LContext.Pool.Slots[LSlot]^.Id);
end;

// createStartingEntities: every unit of the level, with its idle state
procedure TWarMapBinding.CreateUnits;
var
  LStart: TArray<TWarMapUnit>;
  LUnit: TWarMapUnit;
  LSlot: Integer;
begin
  LStart := FMap.Units.ToArray;
  for LUnit in LStart do
  begin
    LSlot := FWorld.Entities.CreateUnit(LUnit.UnitType, LUnit.TileX, LUnit.TileY, LUnit.Player, LUnit.ResourceKind,
      Cardinal(LUnit.Amount), True);
    if LSlot = 0 then
      raise EWarException.CreateFmt(SWarModelEntityPoolFull, [WAR_MODEL_MAX_ENTITIES]);
    CheckId('unit', LUnit.Id, FWorld.Context.Pool.Slots[LSlot]^.Id);
    FWorld.Entities.SetInitialIdle(LSlot);
  end;
end;

procedure TWarMapBinding.SyncUnits;
var
  LUnits: TList<Integer>;
  LIndex: Integer;
  LSlot: Integer;
  LEntity: PWarEntity;
  LTile: TWarVec2;
  LMapUnit: TWarMapUnit;
begin
  // what the fog of the map wrote on its copies since the last time (a building that has been seen) goes to the model
  for LIndex := 0 to FMap.Units.Count - 1 do
    if FMap.Units[LIndex].HasBeenSeen then
    begin
      LSlot := FWorld.Context.Pool.FindSlot(FMap.Units[LIndex].Id);
      if LSlot <> 0 then
        FWorld.Context.Pool.Slots[LSlot]^.UnitData.HasBeenSeen := True;
    end;
  FMap.Units.Clear;
  LUnits := FWorld.Context.Pool.OfType[WAR_ENTITY_UNIT];
  for LIndex := 0 to LUnits.Count - 1 do
  begin
    LSlot := LUnits[LIndex];
    LEntity := FWorld.Context.Pool.Slots[LSlot];
    LTile := TWarUnitGeometry.Tile(LEntity);
    LMapUnit := Default(TWarMapUnit);
    LMapUnit.Id := LEntity^.Id;
    LMapUnit.UnitType := LEntity^.UnitData.UnitType;
    LMapUnit.Direction := LEntity^.UnitData.Direction;
    LMapUnit.TileX := Trunc(LTile.X);
    LMapUnit.TileY := Trunc(LTile.Y);
    LMapUnit.SizeX := LEntity^.UnitData.SizeX;
    LMapUnit.SizeY := LEntity^.UnitData.SizeY;
    LMapUnit.Player := LEntity^.UnitData.Player;
    LMapUnit.ResourceKind := LEntity^.UnitData.ResourceKind;
    LMapUnit.Amount := LEntity^.UnitData.Amount;
    LMapUnit.MaxHp := LEntity^.UnitData.MaxHp;
    LMapUnit.Hp := LEntity^.UnitData.Hp;
    LMapUnit.MaxMana := LEntity^.UnitData.MaxMana;
    LMapUnit.Mana := LEntity^.UnitData.Mana;
    LMapUnit.Armor := LEntity^.UnitData.Armor;
    LMapUnit.Range := LEntity^.UnitData.Range;
    LMapUnit.MinDamage := LEntity^.UnitData.MinDamage;
    LMapUnit.RndDamage := LEntity^.UnitData.RndDamage;
    LMapUnit.Decay := LEntity^.UnitData.Decay;
    LMapUnit.ManaTime := Trunc(LEntity^.UnitData.ManaTime);
    LMapUnit.HasBeenSeen := LEntity^.UnitData.HasBeenSeen;
    LMapUnit.IsGone := FWorld.Machine.IsDead(LSlot) or FWorld.Machine.IsCollapsing(LSlot);
    FMap.Units.Add(LMapUnit);
  end;
end;

procedure TWarMapBinding.Tick(ADeltaTime: Single);
begin
  FWorld.Tick(ADeltaTime);
  SyncUnits;
end;

end.
