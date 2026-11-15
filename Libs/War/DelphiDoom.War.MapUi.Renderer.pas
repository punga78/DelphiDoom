{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the drawing of the map                            }
{                                                                              }
{  Port of war1 (acoto87/war1), renderMapPanel, renderTerrain, renderFoW of     }
{  war_map.c and the render functions of war_entities.c (renderRoad,            }
{  renderWall, renderRuin, renderForest, renderUnit, renderMinimap,             }
{  we_renderEntitiesOfType, we_renderUnitSelection), (c) 2019 Alejandro Coto    }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered  }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.Renderer;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.War.Types,
  DelphiDoom.War.Level.Types, DelphiDoom.War.Render.Types, DelphiDoom.War.Render.Transform, DelphiDoom.War.Map.Types,
  DelphiDoom.War.Map.Game, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine,
  DelphiDoom.War.Graphics.Types, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf, DelphiDoom.War.MapUi.Types,
  DelphiDoom.War.MapUi.Camera, DelphiDoom.War.MapUi.Sprites;

type
  TWarMapRenderer = class;

  /// <summary>One way of drawing an entity (a function of the table renderFuncs of we_renderEntity): the slot of the pool</summary>
  TWarEntityDraw = procedure(const ARenderer: TWarMapRenderer; ASlot: Integer);

  /// <summary>
  ///   renderMapPanel and what it calls: the terrain, the entities by type (the road, the wall, the ruins and the forests
  ///   first, then the units sorted for drawing, the selection, the projectiles and the effects), the fog in two passes
  ///   and the minimap. The entities go through a table of procedures by type, as in the original: no virtual call for a
  ///   tile or a sprite. It draws straight on the transform it is given and reads the model, never changes it, with one
  ///   exception that the original has too: the lists of the units and of the projectiles of the pool are SORTED IN
  ///   PLACE by drawing them, so from then on every walk of those lists (the minimap, the selection by rectangle, the
  ///   units the computer looks at) sees that order
  /// </summary>
  TWarMapRenderer = class
  strict private
    FTransform: TWarRenderTransform;
    FMap: TWarGameMap;
    FContext: TWarModelContext;
    FMachine: TWarStateMachine;
    FSprites: TWarMapSprites;
    FCamera: TWarMapCamera;
    FUnitComparer: IComparer<Integer>;
    FProjectileComparer: IComparer<Integer>;
    FTilesetForest: Boolean;
    /// <summary>The renderFuncs of we_renderEntity: a procedure by type of entity (nil: nothing to draw)</summary>
    class var FDrawTable: array[0..WAR_ENTITY_TYPE_COUNT - 1] of TWarEntityDraw;
    class constructor CreateDrawTable;
    function CompareUnits(const ALeft, ARight: Integer): Integer;
    function CompareProjectiles(const ALeft, ARight: Integer): Integer;
    function UnitIsDying(ASlot: Integer): Boolean;
    function IsEnemyPlayer(APlayer: Byte): Boolean;
    procedure RenderTerrain;
    procedure RenderFog;
    class procedure DrawRoad(const ARenderer: TWarMapRenderer; ASlot: Integer); static;
    class procedure DrawWall(const ARenderer: TWarMapRenderer; ASlot: Integer); static;
    class procedure DrawRuin(const ARenderer: TWarMapRenderer; ASlot: Integer); static;
    class procedure DrawForest(const ARenderer: TWarMapRenderer; ASlot: Integer); static;
    class procedure DrawUnit(const ARenderer: TWarMapRenderer; ASlot: Integer); static;
    procedure RenderTile(ATileIndex, AX, AY: Integer);
    procedure DrawSprite(const ASprite: IWarUiSprite; AScaleX, AScaleY: Single);
  public
    constructor Create(const ATransform: TWarRenderTransform; const AMap: TWarGameMap; const AContext: TWarModelContext;
      const AMachine: TWarStateMachine; const ASprites: TWarMapSprites; const ACamera: TWarMapCamera);
    /// <summary>renderMapPanel, without the debug drawings</summary>
    procedure RenderPanel;
    /// <summary>we_renderEntitiesOfType: sorts the units and the projectiles, then draws the entities of the type in the order of the list</summary>
    procedure RenderEntitiesOfType(AEntityType: Integer);
    /// <summary>we_renderUnitSelection</summary>
    procedure RenderUnitSelection;
    /// <summary>renderMinimap of the minimap entity: the pixels, then the window on the map</summary>
    procedure RenderMinimap(AX, AY: Single);
  end;

implementation

uses
  System.Math, DelphiDoom.War.Map.Fog, DelphiDoom.War.Autotile.Types, DelphiDoom.War.Autotile.Data,
  DelphiDoom.War.Autotile.Line, DelphiDoom.War.Autotile.Ruins, DelphiDoom.War.Map.Forest, DelphiDoom.War.Map.Minimap,
  DelphiDoom.War.Model.Construction.Types, DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry,
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.EntityPool, DelphiDoom.War.Model.Walls, DelphiDoom.War.Model.Selection;

const
  TILE_SIZE = WAR_MEGA_TILE_SIZE;

{ TWarMapRenderer }

class constructor TWarMapRenderer.CreateDrawTable;
begin
  FDrawTable[WAR_ENTITY_ROAD] := TWarMapRenderer.DrawRoad;
  FDrawTable[WAR_ENTITY_WALL] := TWarMapRenderer.DrawWall;
  FDrawTable[WAR_ENTITY_RUIN] := TWarMapRenderer.DrawRuin;
  FDrawTable[WAR_ENTITY_FOREST] := TWarMapRenderer.DrawForest;
  FDrawTable[WAR_ENTITY_UNIT] := TWarMapRenderer.DrawUnit;
end;

constructor TWarMapRenderer.Create(const ATransform: TWarRenderTransform; const AMap: TWarGameMap;
  const AContext: TWarModelContext; const AMachine: TWarStateMachine; const ASprites: TWarMapSprites;
  const ACamera: TWarMapCamera);
begin
  inherited Create;
  FTransform := ATransform;
  FMap := AMap;
  FContext := AContext;
  FMachine := AMachine;
  FSprites := ASprites;
  FCamera := ACamera;
  FTilesetForest := AMap.Info.TilesetType = WAR_TILESET_FOREST;
  FUnitComparer := TComparer<Integer>.Construct(CompareUnits);
  FProjectileComparer := TComparer<Integer>.Construct(CompareProjectiles);
end;

function TWarMapRenderer.UnitIsDying(ASlot: Integer): Boolean;
begin
  Result := TWarUnitClassifier.IsCorpse(FContext.Pool.Slots[ASlot]^.UnitData.UnitType) or FMachine.IsDead(ASlot) or
    FMachine.IsGoingToDie(ASlot);
end;

function TWarMapRenderer.CompareUnits(const ALeft, ARight: Integer): Integer;
var
  LLeft: PWarEntity;
  LRight: PWarEntity;
  LLeftDead: Boolean;
  LRightDead: Boolean;
begin
  // renderCompareUnits: the corpses and the dying first, then by the y of the position, then by the id
  LLeft := FContext.Pool.Slots[ALeft];
  LRight := FContext.Pool.Slots[ARight];
  if LLeft^.Id = LRight^.Id then
    Exit(0);
  LLeftDead := UnitIsDying(ALeft);
  LRightDead := UnitIsDying(ARight);
  if LLeftDead and (not LRightDead) then
    Exit(-1);
  if (not LLeftDead) and LRightDead then
    Exit(1);
  if LLeft^.Position.Y <> LRight^.Position.Y then
  begin
    if LLeft^.Position.Y < LRight^.Position.Y then
      Exit(-1);
    Exit(1);
  end;
  if LLeft^.Id < LRight^.Id then
    Result := -1
  else
    Result := 1;
end;

function TWarMapRenderer.CompareProjectiles(const ALeft, ARight: Integer): Integer;
var
  LLeft: PWarEntity;
  LRight: PWarEntity;
begin
  LLeft := FContext.Pool.Slots[ALeft];
  LRight := FContext.Pool.Slots[ARight];
  if LLeft^.Id = LRight^.Id then
    Exit(0);
  if LLeft^.Position.Y <> LRight^.Position.Y then
  begin
    if LLeft^.Position.Y < LRight^.Position.Y then
      Exit(-1);
    Exit(1);
  end;
  if LLeft^.Id < LRight^.Id then
    Result := -1
  else
    Result := 1;
end;

function TWarMapRenderer.IsEnemyPlayer(APlayer: Byte): Boolean;
begin
  // wu_isEnemyUnit: not the player 0 and not a neutral player
  Result := (APlayer <> 0) and (FMap.Players[APlayer].Race <> wraNeutral);
end;

procedure TWarMapRenderer.RenderTile(ATileIndex, AX, AY: Integer);
var
  LSource: TWarRectF;
  LDestination: TWarRectF;
begin
  LSource.X := (ATileIndex mod WAR_TILESET_TILES_PER_ROW) * TILE_SIZE;
  LSource.Y := (ATileIndex div WAR_TILESET_TILES_PER_ROW) * TILE_SIZE;
  LSource.Width := TILE_SIZE;
  LSource.Height := TILE_SIZE;
  LDestination.X := AX * TILE_SIZE;
  LDestination.Y := AY * TILE_SIZE;
  LDestination.Width := TILE_SIZE;
  LDestination.Height := TILE_SIZE;
  FTransform.SubImageOf(FSprites.Tileset, LSource, LDestination, 1, 1);
end;

procedure TWarMapRenderer.RenderTerrain;
var
  LVisual: TArray<Word>;
  LX: Integer;
  LY: Integer;
  LTile: TWarMapTile;
  LIndex: Integer;
  LSource: TWarRectF;
  LDestination: TWarRectF;
begin
  LVisual := FMap.Visual;
  LDestination.X := 0;
  LDestination.Y := 0;
  LDestination.Width := TILE_SIZE;
  LDestination.Height := TILE_SIZE;
  LSource.Width := TILE_SIZE;
  LSource.Height := TILE_SIZE;
  for LY := 0 to WAR_MAP_TILES_HEIGHT - 1 do
    for LX := 0 to WAR_MAP_TILES_WIDTH - 1 do
    begin
      LTile := FMap.Fog.GetTile(LX, LY);
      if (not FMap.Fog.Enabled) or (LTile.State = wtsVisible) or (LTile.State = wtsFog) then
      begin
        LIndex := LVisual[LY * WAR_MAP_TILES_WIDTH + LX];
        LSource.X := (LIndex mod WAR_TILESET_TILES_PER_ROW) * TILE_SIZE;
        LSource.Y := (LIndex div WAR_TILESET_TILES_PER_ROW) * TILE_SIZE;
        FTransform.Save;
        FTransform.Translate(LX * TILE_SIZE, LY * TILE_SIZE);
        FTransform.SubImageOf(FSprites.Tileset, LSource, LDestination, 1, 1);
        FTransform.Restore;
      end;
    end;
end;

procedure TWarMapRenderer.RenderFog;
var
  LX: Integer;
  LY: Integer;
  LTile: TWarMapTile;
  LSource: TWarRectF;
  LDestination: TWarRectF;
begin
  if not FMap.Fog.Enabled then
    Exit;
  LSource := WarRectI(0, 0, TILE_SIZE, TILE_SIZE);
  // pass 1: the boundary of the unknown and the unknown tiles, fully opaque
  for LY := 0 to WAR_MAP_TILES_HEIGHT - 1 do
    for LX := 0 to WAR_MAP_TILES_WIDTH - 1 do
    begin
      LTile := FMap.Fog.GetTile(LX, LY);
      if (LTile.PieceType <> 0) and (LTile.Boundary = wfbUnknown) then
        RenderTile(LTile.PieceType, LX, LY);
      if LTile.State = wtsUnknown then
      begin
        LDestination := WarRectI(LX * TILE_SIZE, LY * TILE_SIZE, TILE_SIZE, TILE_SIZE);
        FTransform.SubImageOf(FSprites.Black, LSource, LDestination, 1, 1);
      end;
    end;
  // pass 2: the boundary of the fog and the tiles in fog, at half opacity
  FTransform.Save;
  FTransform.GlobalAlpha(0.5);
  for LY := 0 to WAR_MAP_TILES_HEIGHT - 1 do
    for LX := 0 to WAR_MAP_TILES_WIDTH - 1 do
    begin
      LTile := FMap.Fog.GetTile(LX, LY);
      if (LTile.PieceType <> 0) and (LTile.State = wtsVisible) and (LTile.Boundary = wfbFog) then
        RenderTile(LTile.PieceType, LX, LY);
      if LTile.State = wtsFog then
      begin
        LDestination := WarRectI(LX * TILE_SIZE, LY * TILE_SIZE, TILE_SIZE, TILE_SIZE);
        FTransform.SubImageOf(FSprites.Black, LSource, LDestination, 1, 1);
      end;
    end;
  FTransform.Restore;
end;

procedure TWarMapRenderer.DrawSprite(const ASprite: IWarUiSprite; AScaleX, AScaleY: Single);
var
  LRect: TWarRectF;
begin
  // wspr_renderSprite(sprite, VEC2_ZERO, scale)
  LRect := WarRectI(0, 0, ASprite.FrameWidth, ASprite.FrameHeight);
  FTransform.SubImageOf(ASprite.Texture, LRect, LRect, AScaleX, AScaleY);
end;

class procedure TWarMapRenderer.DrawRoad(const ARenderer: TWarMapRenderer; ASlot: Integer);
var
  LPiece: TWarLinePiece;
  LTile: Integer;
begin
  for LPiece in ARenderer.FContext.Roads.Pieces do
  begin
    if ARenderer.FTilesetForest then
      LTile := WAR_ROAD_DATA[LPiece.PieceType].Forest
    else
      LTile := WAR_ROAD_DATA[LPiece.PieceType].Swamp;
    ARenderer.FTransform.Save;
    ARenderer.FTransform.Translate(LPiece.TileX * TILE_SIZE, LPiece.TileY * TILE_SIZE);
    ARenderer.RenderTile(LTile, 0, 0);
    ARenderer.FTransform.Restore;
  end;
end;

class procedure TWarMapRenderer.DrawWall(const ARenderer: TWarMapRenderer; ASlot: Integer);
var
  LWalls: TWarWalls;
  LIndex: Integer;
  LPiece: PWarWallPiece;
  LPercent: Integer;
  LTile: Integer;
begin
  LWalls := ARenderer.FContext.Walls;
  for LIndex := 0 to LWalls.Count - 1 do
  begin
    LPiece := LWalls[LIndex];
    LPercent := TWarModelMath.PercentOf(LPiece^.Hp, LPiece^.MaxHp);
    if ARenderer.FTilesetForest then
    begin
      if LPercent <= 0 then
        LTile := WAR_WALL_DATA[LPiece^.PieceType].DestroyedForest
      else if LPercent < 50 then
        LTile := WAR_WALL_DATA[LPiece^.PieceType].DamagedForest
      else
        LTile := WAR_WALL_DATA[LPiece^.PieceType].Forest;
    end
    else
    begin
      if LPercent <= 0 then
        LTile := WAR_WALL_DATA[LPiece^.PieceType].DestroyedSwamp
      else if LPercent < 50 then
        LTile := WAR_WALL_DATA[LPiece^.PieceType].DamagedSwamp
      else
        LTile := WAR_WALL_DATA[LPiece^.PieceType].Swamp;
    end;
    ARenderer.FTransform.Save;
    ARenderer.FTransform.Translate(LPiece^.TileX * TILE_SIZE, LPiece^.TileY * TILE_SIZE);
    ARenderer.RenderTile(LTile, 0, 0);
    ARenderer.FTransform.Restore;
  end;
end;

class procedure TWarMapRenderer.DrawRuin(const ARenderer: TWarMapRenderer; ASlot: Integer);
var
  LPiece: TWarRuinPiece;
  LTile: Integer;
begin
  for LPiece in ARenderer.FContext.Ruins.Pieces do
  begin
    if LPiece.PieceType = WAR_PIECE_NONE then
      Continue;
    if ARenderer.FTilesetForest then
      LTile := WAR_RUIN_DATA[LPiece.PieceType].Forest
    else
      LTile := WAR_RUIN_DATA[LPiece.PieceType].Swamp;
    ARenderer.FTransform.Save;
    ARenderer.FTransform.Translate(LPiece.TileX * TILE_SIZE, LPiece.TileY * TILE_SIZE);
    ARenderer.RenderTile(LTile, 0, 0);
    ARenderer.FTransform.Restore;
  end;
end;

class procedure TWarMapRenderer.DrawForest(const ARenderer: TWarMapRenderer; ASlot: Integer);
var
  LForest: TWarMapForest;
  LIndex: Integer;
  LTree: TWarTree;
  LTile: Integer;
begin
  // renderForest draws nothing: it writes the tile of every tree in the map (and its pixel of the minimap), every frame;
  // the terrain of the same frame was drawn before, so the first frame shows the tiles of the level
  LForest := ARenderer.FMap.Forests.FindForest(ARenderer.FContext.Pool.Slots[ASlot]^.Id);
  if not Assigned(LForest) then
    Exit;
  for LIndex := 0 to LForest.Trees.Count - 1 do
  begin
    LTree := LForest.Trees[LIndex];
    if LTree.TileType = WAR_PIECE_NONE then
      Continue;
    if ARenderer.FTilesetForest then
      LTile := WAR_TREE_DATA[LTree.TileType].Forest
    else
      LTile := WAR_TREE_DATA[LTree.TileType].Swamp;
    ARenderer.FMap.Painter.SetTileIndex(LTree.TileX, LTree.TileY, LTile);
  end;
end;

class procedure TWarMapRenderer.DrawUnit(const ARenderer: TWarMapRenderer; ASlot: Integer);
var
  LEntity: PWarEntity;
  LSprite: IWarUiSprite;
  LSpriteEnabled: Boolean;
  LFrameWidth: Single;
  LFrameHeight: Single;
  LUnitWidth: Single;
  LUnitHeight: Single;
  LVisible: Boolean;
  LTile: TWarVec2;
  LRect: TWarRectF;
  LHalf: Single;
begin
  LEntity := ARenderer.FContext.Pool.Slots[ASlot];
  LSpriteEnabled := LEntity^.HasSprite and LEntity^.SpriteEnabled;
  LFrameWidth := 0;
  LFrameHeight := 0;
  LSprite := nil;
  if LSpriteEnabled then
  begin
    LSprite := ARenderer.FSprites.Get(LEntity^.SpriteResource);
    LFrameWidth := LSprite.FrameWidth;
    LFrameHeight := LSprite.FrameHeight;
  end;
  LUnitWidth := LEntity^.UnitData.SizeX * TILE_SIZE;
  LUnitHeight := LEntity^.UnitData.SizeY * TILE_SIZE;
  // the unit is seen if any of its tiles is in sight
  LTile := TWarUnitGeometry.Tile(LEntity);
  LVisible := ARenderer.FMap.Fog.IsAnyTileInState(Trunc(LTile.X), Trunc(LTile.Y), LEntity^.UnitData.SizeX,
    LEntity^.UnitData.SizeY, wtsVisible);
  // to the centre of its frame, then to the centre of its sprite, then to its position
  LHalf := -0.5;
  ARenderer.FTransform.Translate(LHalf * LFrameWidth, LHalf * LFrameHeight);
  LHalf := 0.5;
  ARenderer.FTransform.Translate(LHalf * LUnitWidth, LHalf * LUnitHeight);
  ARenderer.FTransform.Translate(LEntity^.Position.X, LEntity^.Position.Y);
  if LSpriteEnabled and (LVisible or LEntity^.UnitData.HasBeenSeen) then
  begin
    ARenderer.FTransform.Save;
    if TWarUnitClassifier.IsDude(LEntity^.UnitData.UnitType) then
    begin
      if LEntity^.UnitData.Invisible then
        ARenderer.FTransform.GlobalAlpha(0.5);
      if LEntity^.UnitData.Invulnerable then
      begin
        // the sprite rectangle, one pixel inside (rect_expand by -1)
        LRect.X := 0.5 * (LFrameWidth - LUnitWidth);
        LRect.Y := 0.5 * (LFrameHeight - LUnitHeight);
        LRect.Width := LUnitWidth;
        LRect.Height := LUnitHeight;
        LRect.X := LRect.X - (-1);
        LRect.Y := LRect.Y - (-1);
        LRect.Width := LRect.Width + (-1) * 2;
        LRect.Height := LRect.Height + (-1) * 2;
        ARenderer.FTransform.StrokeRect(LRect, WAR_MAPUI_BLUE_INVULNERABLE);
      end;
    end;
    LSprite.UpdateImage(LEntity^.SpriteFrame);
    ARenderer.DrawSprite(LSprite, LEntity^.ScaleX, 1);
    ARenderer.FTransform.Restore;
  end;
end;

procedure TWarMapRenderer.RenderEntitiesOfType(AEntityType: Integer);
var
  LList: TList<Integer>;
  LIndex: Integer;
  LSlot: Integer;
  LDraw: TWarEntityDraw;
begin
  LList := FContext.Pool.OfType[AEntityType];
  // the order of the drawing is the order of the list: the units and the projectiles are sorted in it
  if AEntityType = WAR_ENTITY_UNIT then
    LList.Sort(FUnitComparer)
  else if AEntityType = WAR_ENTITY_PROJECTILE then
    LList.Sort(FProjectileComparer);
  LDraw := FDrawTable[AEntityType];
  if not Assigned(LDraw) then
    Exit;
  for LIndex := 0 to LList.Count - 1 do
  begin
    LSlot := LList[LIndex];
    if FContext.Pool.Slots[LSlot]^.Id <> 0 then
    begin
      FTransform.Save;
      LDraw(Self, LSlot);
      FTransform.Restore;
    end;
  end;
end;

procedure TWarMapRenderer.RenderUnitSelection;
var
  LSelection: TWarSelection;
  LIndex: Integer;
  LSlot: Integer;
  LEntity: PWarEntity;
  LSprite: IWarUiSprite;
  LFrameWidth: Single;
  LFrameHeight: Single;
  LUnitWidth: Single;
  LUnitHeight: Single;
  LRect: TWarRectF;
  LColor: TWarRgba;
  LHalf: Single;
begin
  LSelection := FContext.Selection;
  for LIndex := 0 to LSelection.Count - 1 do
  begin
    LSlot := FContext.Pool.FindSlot(LSelection[LIndex]);
    if LSlot = 0 then
      Continue;
    LEntity := FContext.Pool.Slots[LSlot];
    if (not LEntity^.HasUnit) or (not (LEntity^.HasSprite and LEntity^.SpriteEnabled)) then
      Continue;
    LSprite := FSprites.Get(LEntity^.SpriteResource);
    LFrameWidth := LSprite.FrameWidth;
    LFrameHeight := LSprite.FrameHeight;
    LUnitWidth := LEntity^.UnitData.SizeX * TILE_SIZE;
    LUnitHeight := LEntity^.UnitData.SizeY * TILE_SIZE;
    FTransform.Save;
    LHalf := -0.5;
    FTransform.Translate(LHalf * LFrameWidth, LHalf * LFrameHeight);
    LHalf := 0.5;
    FTransform.Translate(LHalf * LUnitWidth, LHalf * LUnitHeight);
    FTransform.Translate(LEntity^.Position.X, LEntity^.Position.Y);
    LRect.X := 0.5 * (LFrameWidth - LUnitWidth);
    LRect.Y := 0.5 * (LFrameHeight - LUnitHeight);
    LRect.Width := LUnitWidth;
    LRect.Height := LUnitHeight;
    LColor := WAR_MAPUI_WHITE_SELECTION;
    if LEntity^.UnitData.Player = 0 then
      LColor := WAR_MAPUI_GREEN_SELECTION
    else if IsEnemyPlayer(LEntity^.UnitData.Player) then
      LColor := WAR_MAPUI_RED_SELECTION;
    FTransform.StrokeRect(LRect, LColor);
    FTransform.Restore;
  end;
end;

procedure TWarMapRenderer.RenderMinimap(AX, AY: Single);
var
  LMinimap: TWarMinimap;
  LUnits: TList<Integer>;
  LIndex: Integer;
  LSlot: Integer;
  LEntity: PWarEntity;
  LTile: TWarVec2;
  LVisible: Boolean;
  LColor: TWarMinimapColor;
  LDisplay: Boolean;
  LRect: TWarRectF;
  LSource: TWarRectF;
  LRatio: Single;
  LOffsetX: Single;
  LOffsetY: Single;
begin
  LMinimap := FMap.Minimap;
  // the terrain where the player has seen, and the units, in the order of the list of the units now
  LMinimap.BeginFrame(FMap.Fog);
  LUnits := FContext.Pool.OfType[WAR_ENTITY_UNIT];
  for LIndex := 0 to LUnits.Count - 1 do
  begin
    LSlot := LUnits[LIndex];
    LEntity := FContext.Pool.Slots[LSlot];
    if (not LEntity^.HasUnit) or (not LEntity^.HasTransform) then
      Continue;
    // wu_displayUnitOnMinimap
    LDisplay := not (TWarUnitClassifier.IsCorpse(LEntity^.UnitData.UnitType) or FMachine.IsDead(LSlot) or
      FMachine.IsGoingToDie(LSlot) or FMachine.IsCollapsing(LSlot) or FMachine.IsGoingToCollapse(LSlot));
    if not LDisplay then
      Continue;
    LTile := TWarUnitGeometry.Tile(LEntity);
    LVisible := FMap.Fog.IsAnyTileInState(Trunc(LTile.X), Trunc(LTile.Y), LEntity^.UnitData.SizeX,
      LEntity^.UnitData.SizeY, wtsVisible);
    if not (LVisible or LEntity^.UnitData.HasBeenSeen) then
      Continue;
    LColor := TWarMinimap.UnitColorOf(LEntity^.UnitData.UnitType, LEntity^.UnitData.Player);
    LMinimap.PaintUnit(Trunc(LEntity^.Position.X / TILE_SIZE), Trunc(LEntity^.Position.Y / TILE_SIZE),
      LEntity^.UnitData.SizeX, LEntity^.UnitData.SizeY, LColor);
  end;
  FSprites.SetMinimapPixels(LMinimap.Frame);
  FTransform.Save;
  FTransform.Translate(AX, AY);
  LSource := WarRectI(0, 0, WAR_MINIMAP_SIZE, WAR_MINIMAP_SIZE);
  FTransform.SubImageOf(FSprites.Minimap, LSource, LSource, 1, 1);
  // the window on the map: MINIMAP_MAP_WIDTH_RATIO and HEIGHT_RATIO are 64 / 1024
  LRatio := 0.0625;
  LOffsetX := FCamera.X * LRatio;
  LOffsetY := FCamera.Y * LRatio;
  FTransform.Translate(LOffsetX, LOffsetY);
  LRect.X := 0;
  LRect.Y := 0;
  LRect.Width := 15;
  LRect.Height := 11;
  FTransform.StrokeRect(LRect, WAR_COLOR_WHITE);
  FTransform.Restore;
end;

procedure TWarMapRenderer.RenderPanel;
begin
  FTransform.Save;
  FTransform.Translate(FCamera.Panels.MapPanel.X, FCamera.Panels.MapPanel.Y);
  FTransform.Translate(-FCamera.X, -FCamera.Y);
  RenderTerrain;
  RenderEntitiesOfType(WAR_ENTITY_RUIN);
  RenderEntitiesOfType(WAR_ENTITY_ROAD);
  RenderEntitiesOfType(WAR_ENTITY_WALL);
  RenderEntitiesOfType(WAR_ENTITY_FOREST);
  RenderEntitiesOfType(WAR_ENTITY_UNIT);
  RenderUnitSelection;
  RenderEntitiesOfType(WAR_ENTITY_PROJECTILE);
  RenderEntitiesOfType(WAR_ENTITY_POISON_CLOUD);
  RenderEntitiesOfType(WAR_ENTITY_ANIMATION);
  RenderFog;
  FTransform.Restore;
end;

end.
