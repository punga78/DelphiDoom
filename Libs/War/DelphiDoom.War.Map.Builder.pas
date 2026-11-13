{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - a level becomes a game map                        }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (wmap_enterMap: initCamera,          }
{  initPathFinder, setInitialTileState, createMapAndMinimapSprites,            }
{  createForestEntities, createStartingRoads, createStartingWalls,             }
{  createRuinEntity, initPlayersInfo, createStartingEntities), (c) 2019        }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Map.Builder;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Level.Intf,
  DelphiDoom.War.Autotile.Line, DelphiDoom.War.Autotile.Ruins, DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Intf,
  DelphiDoom.War.Map.PathGrid, DelphiDoom.War.Map.Fog, DelphiDoom.War.Map.Minimap, DelphiDoom.War.Map.TilePainter,
  DelphiDoom.War.Map.Forests, DelphiDoom.War.Map.Game;

type
  /// <summary>
  ///   wmap_enterMap, the part that makes data: from a level and the image of its tileset it makes the map of a game.
  ///   The entities get their ids in the order of the original: the forests (a tree group at a time, in reading order),
  ///   the forest of the game, the road, the wall, the ruins and then the starting units
  /// </summary>
  TWarMapBuilder = class
  strict private
    FCatalog: IWarUnitCatalog;
    function CreatePlayers(const AInfo: TWarLevelInfo): TArray<TWarPlayerInfo>;
    function CreateViewport(const AInfo: TWarLevelInfo): TWarViewport;
  public
    constructor Create(const ACatalog: IWarUnitCatalog);
    /// <summary>
    ///   Makes the map of the level. ATilesetPixels is the image of the tileset of the level (IWarGraphics.GetTileset,
    ///   512 x 256 pixels of 4 bytes). EWarException if a starting unit has a type the tables do not know, a map is
    ///   short or a tile of the visual map is not in the image. The caller frees the map
    /// </summary>
    function Build(const ALevel: IWarLevel; const ATilesetPixels: TBytes): TWarGameMap;
  end;

implementation

{ TWarMapBuilder }

constructor TWarMapBuilder.Create(const ACatalog: IWarUnitCatalog);
begin
  inherited Create;
  if not Assigned(ACatalog) then
    raise EWarException.Create(SWarMapNoBuilder);
  FCatalog := ACatalog;
end;

function TWarMapBuilder.CreateViewport(const AInfo: TWarLevelInfo): TWarViewport;
begin
  // initCamera (a level that is not a custom game starts where the level says)
  Result.X := AInfo.StartX * WAR_MEGA_TILE_SIZE;
  Result.Y := AInfo.StartY * WAR_MEGA_TILE_SIZE;
  Result.Width := WAR_MAP_VIEWPORT_WIDTH;
  Result.Height := WAR_MAP_VIEWPORT_HEIGHT;
end;

function TWarMapBuilder.CreatePlayers(const AInfo: TWarLevelInfo): TArray<TWarPlayerInfo>;
var
  LPlayer: Integer;
  LIndex: Integer;
begin
  SetLength(Result, WAR_MAX_PLAYERS_COUNT);
  for LPlayer := 0 to WAR_MAX_PLAYERS_COUNT - 1 do
  begin
    Result[LPlayer] := Default(TWarPlayerInfo);
    Result[LPlayer].Index := LPlayer;
    Result[LPlayer].Race := AInfo.Races[LPlayer];
    Result[LPlayer].Gold := Integer(AInfo.Gold[LPlayer]);
    Result[LPlayer].Wood := Integer(AInfo.Lumber[LPlayer]);
    for LIndex := 0 to WAR_MAX_FEATURES_COUNT - 1 do
      Result[LPlayer].Features[LIndex] := AInfo.AllowedFeatures[LIndex];
    for LIndex := 0 to WAR_MAX_UPGRADES_COUNT - 1 do
    begin
      Result[LPlayer].Upgrades[LIndex].Allowed := AInfo.AllowedUpgrades[LIndex, LPlayer];
      Result[LPlayer].Upgrades[LIndex].Level := 0;
    end;
  end;
end;

function TWarMapBuilder.Build(const ALevel: IWarLevel; const ATilesetPixels: TBytes): TWarGameMap;
var
  LInfo: TWarLevelInfo;
  LPassable: TArray<Word>;
  LGrid: TWarPathGrid;
  LFog: TWarFogOfWar;
  LMinimap: TWarMinimap;
  LPainter: IWarTilePainter;
  LForests: TWarMapForests;
  LRoad: TWarLine;
  LWall: TWarLine;
  LRuins: TWarRuins;
  LConstruct: TWarLevelConstruct;
  LUnit: TWarLevelUnit;
  LRoadId: Word;
  LWallId: Word;
  LRuinsId: Word;
  LMap: TWarGameMap;
begin
  LInfo := ALevel.Info;
  LPassable := ALevel.Passable;
  LGrid := nil;
  LFog := nil;
  LMinimap := nil;
  LRoad := nil;
  LWall := nil;
  LRuins := nil;
  Result := nil;
  try
    LGrid := TWarPathGrid.Create(LPassable);
    LFog := TWarFogOfWar.Create;
    LMinimap := TWarMinimap.Create(ATilesetPixels);
    LMinimap.BuildTerrain(ALevel.Visual);
    LPainter := TWarMapTilePainter.Create(ALevel.Visual, LMinimap, LFog);
    Result := TWarGameMap.Create(LInfo, FCatalog, LGrid, LFog, LMinimap, LPainter);
    // the map owns the parts now
    LGrid := nil;
    LFog := nil;
    LMinimap := nil;
    Result.SetViewport(CreateViewport(LInfo));
    LForests := TWarMapForests.Create(Result.Grid, Result.Fog, LPainter, LInfo.TilesetType);
    Result.AttachForests(LForests);
    LMap := Result;
    LForests.CreateFromPassable(LPassable, LMap.AllocateEntityId);
    // the forest where the game plants trees
    LForests.EditingForest := LForests.AddForest(LMap.AllocateEntityId);

    LRoadId := Result.AllocateEntityId;
    LRoad := TWarLine.CreateRoad;
    for LConstruct in LInfo.StartRoads do
      if LConstruct.ConstructType = wctRoad then
        LRoad.AddFromConstruct(LConstruct);
    LRoad.DetermineTypes;

    LWallId := Result.AllocateEntityId;
    LWall := TWarLine.CreateWall;
    for LConstruct in LInfo.StartWalls do
      if LConstruct.ConstructType = wctWall then
        LWall.AddFromConstruct(LConstruct);
    LWall.DetermineTypes;

    LRuinsId := Result.AllocateEntityId;
    LRuins := TWarRuins.Create;
    Result.AttachConstructions(LRoad, LWall, LRuins, LRoadId, LWallId, LRuinsId);
    LRoad := nil;
    LWall := nil;
    LRuins := nil;

    Result.SetPlayers(CreatePlayers(LInfo));
    for LUnit in LInfo.StartEntities do
      Result.SpawnUnit(LUnit.UnitType, LUnit.X, LUnit.Y, LUnit.Player, LUnit.ResourceKind, LUnit.Amount);
  except
    LGrid.Free;
    LFog.Free;
    LMinimap.Free;
    LRoad.Free;
    LWall.Free;
    LRuins.Free;
    FreeAndNil(Result);
    raise;
  end;
end;

end.
