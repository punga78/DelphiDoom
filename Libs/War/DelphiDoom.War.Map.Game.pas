{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - a level in play                                   }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (WarMap: the data of the map that    }
{  wmap_enterMap makes), (c) 2019 Alejandro Coto Gutierrez, zlib License (see  }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Map.Game;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Level.Types, DelphiDoom.War.Autotile.Line,
  DelphiDoom.War.Autotile.Ruins, DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Intf, DelphiDoom.War.Map.PathGrid,
  DelphiDoom.War.Map.Fog, DelphiDoom.War.Map.FogUpdater, DelphiDoom.War.Map.Forests, DelphiDoom.War.Map.Minimap,
  DelphiDoom.War.Map.TilePainter;

type
  /// <summary>
  ///   A level in play as the data of WarMap: the occupation grid, the fog, the minimap, the forests, the roads, the
  ///   walls and the ruins, the players and the units. The map owns its parts. No rule of the game runs here (no
  ///   movement, no combat, no state machines): a map is what wmap_enterMap leaves, and what planting, chopping and the
  ///   fog change in it
  /// </summary>
  TWarGameMap = class
  strict private
    FInfo: TWarLevelInfo;
    FCatalog: IWarUnitCatalog;
    FGrid: TWarPathGrid;
    FFog: TWarFogOfWar;
    FMinimap: TWarMinimap;
    FPainter: IWarTilePainter;
    FForests: TWarMapForests;
    FRoad: TWarLine;
    FWall: TWarLine;
    FRuins: TWarRuins;
    FUnits: TList<TWarMapUnit>;
    FFogUpdater: TWarFogUpdater;
    FNextEntityId: Cardinal;
    FRoadId: Word;
    FWallId: Word;
    FRuinsId: Word;
    FPlayers: array[0..WAR_MAX_PLAYERS_COUNT - 1] of TWarPlayerInfo;
    FPlayersCount: Integer;
    FViewport: TWarViewport;
    function GetPlayer(AIndex: Integer): TWarPlayerInfo;
    function GetVisual: TArray<Word>;
  public
    /// <summary>The map takes the parts (it frees them); the painter is the one the forests write the felled trees with</summary>
    constructor Create(const AInfo: TWarLevelInfo; const ACatalog: IWarUnitCatalog; const AGrid: TWarPathGrid;
      const AFog: TWarFogOfWar; const AMinimap: TWarMinimap; const APainter: IWarTilePainter);
    destructor Destroy; override;
    /// <summary>The forests need the grid, the fog and the painter of the map: they are made after it</summary>
    procedure AttachForests(const AForests: TWarMapForests);
    /// <summary>The roads, walls and ruins, with the ids of their entities (taken in the order of wmap_enterMap)</summary>
    procedure AttachConstructions(const ARoad, AWall: TWarLine; const ARuins: TWarRuins; ARoadId, AWallId, ARuinsId: Word);
    /// <summary>Sets the players of the level (initPlayersInfo), counting those that are not neutral</summary>
    procedure SetPlayers(const APlayers: array of TWarPlayerInfo);
    procedure SetViewport(const AViewport: TWarViewport);
    /// <summary>we_createEntity: the next id (16 bits, from 1)</summary>
    function AllocateEntityId: Word;
    /// <summary>
    ///   we_createUnit and we_setInitialIdleState: a unit with the next id; its tiles are occupied in the grid. EWarException
    ///   if the type is not in the tables
    /// </summary>
    function SpawnUnit(AUnitType, ATileX, ATileY: Integer; APlayer: Byte; AResourceKind: TWarResourceKind;
      AAmount: Cardinal): TWarMapUnit;
    /// <summary>updateFoW and determineFoWTypes</summary>
    procedure UpdateFog;
    /// <summary>The pixels of the minimap as renderMinimap leaves them (R, G, B, A, 64 x 64)</summary>
    function RenderMinimap: TBytes;
    property Info: TWarLevelInfo read FInfo;
    property Grid: TWarPathGrid read FGrid;
    property Fog: TWarFogOfWar read FFog;
    property Minimap: TWarMinimap read FMinimap;
    property Forests: TWarMapForests read FForests;
    property Road: TWarLine read FRoad;
    property Wall: TWarLine read FWall;
    property Ruins: TWarRuins read FRuins;
    /// <summary>The units, buildings and gold mines in the order they were made (the list belongs to the map)</summary>
    property Units: TList<TWarMapUnit> read FUnits;
    property RoadId: Word read FRoadId;
    property WallId: Word read FWallId;
    property RuinsId: Word read FRuinsId;
    property PlayersCount: Integer read FPlayersCount;
    property Players[AIndex: Integer]: TWarPlayerInfo read GetPlayer;
    property Viewport: TWarViewport read FViewport;
    /// <summary>The tile of the tileset in each cell, as the felled trees leave it</summary>
    property Visual: TArray<Word> read GetVisual;
    /// <summary>How many ids were given: the next entity would get this plus one</summary>
    property LastEntityId: Cardinal read FNextEntityId;
  end;

implementation

{ TWarGameMap }

constructor TWarGameMap.Create(const AInfo: TWarLevelInfo; const ACatalog: IWarUnitCatalog; const AGrid: TWarPathGrid;
  const AFog: TWarFogOfWar; const AMinimap: TWarMinimap; const APainter: IWarTilePainter);
begin
  inherited Create;
  FInfo := AInfo;
  FCatalog := ACatalog;
  FGrid := AGrid;
  FFog := AFog;
  FMinimap := AMinimap;
  FPainter := APainter;
  FUnits := TList<TWarMapUnit>.Create;
  FFogUpdater := TWarFogUpdater.Create(ACatalog, 0);
end;

destructor TWarGameMap.Destroy;
begin
  FForests.Free;
  FRuins.Free;
  FWall.Free;
  FRoad.Free;
  FFogUpdater.Free;
  FUnits.Free;
  FPainter := nil;
  FMinimap.Free;
  FFog.Free;
  FGrid.Free;
  inherited;
end;

procedure TWarGameMap.AttachForests(const AForests: TWarMapForests);
begin
  FForests := AForests;
end;

procedure TWarGameMap.AttachConstructions(const ARoad, AWall: TWarLine; const ARuins: TWarRuins; ARoadId, AWallId,
  ARuinsId: Word);
begin
  FRoad := ARoad;
  FWall := AWall;
  FRuins := ARuins;
  FRoadId := ARoadId;
  FWallId := AWallId;
  FRuinsId := ARuinsId;
end;

procedure TWarGameMap.SetPlayers(const APlayers: array of TWarPlayerInfo);
var
  LIndex: Integer;
begin
  FPlayersCount := 0;
  for LIndex := 0 to High(FPlayers) do
  begin
    FPlayers[LIndex] := APlayers[LIndex];
    if FPlayers[LIndex].Race <> wraNeutral then
      Inc(FPlayersCount);
  end;
end;

procedure TWarGameMap.SetViewport(const AViewport: TWarViewport);
begin
  FViewport := AViewport;
end;

function TWarGameMap.AllocateEntityId: Word;
begin
  Inc(FNextEntityId);
  Result := Word(FNextEntityId);
end;

function TWarGameMap.SpawnUnit(AUnitType, ATileX, ATileY: Integer; APlayer: Byte; AResourceKind: TWarResourceKind;
  AAmount: Cardinal): TWarMapUnit;
begin
  Result := FCatalog.CreateUnit(AllocateEntityId, AUnitType, ATileX, ATileY, APlayer, AResourceKind, AAmount);
  FUnits.Add(Result);
  // the initial idle state occupies the tiles of the unit
  FGrid.SetStaticEntity(ATileX, ATileY, Result.SizeX, Result.SizeY, Result.Id);
end;

procedure TWarGameMap.UpdateFog;
begin
  FFogUpdater.Update(FFog, FUnits);
  FFog.DetermineTypes;
end;

function TWarGameMap.RenderMinimap: TBytes;
begin
  FMinimap.Compose(FFog, FUnits);
  Result := Copy(FMinimap.Frame);
end;

function TWarGameMap.GetPlayer(AIndex: Integer): TWarPlayerInfo;
begin
  Result := FPlayers[AIndex];
end;

function TWarGameMap.GetVisual: TArray<Word>;
begin
  Result := FPainter.GetVisual;
end;

end.
