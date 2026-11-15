{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the map of the game as a scene                    }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (wmap_enterMap, wmap_updateMap,       }
{  wmap_renderMap, wmap_leaveMap) and war_map_ui.c (wmui_renderMapUI),          }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                         }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.Scene;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Level.Intf,
  DelphiDoom.War.Campaign.Intf, DelphiDoom.War.Campaign.Types, DelphiDoom.War.Sound.Intf, DelphiDoom.War.Map.Intf,
  DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Builder, DelphiDoom.War.Map.Game, DelphiDoom.War.Text.Types,
  DelphiDoom.War.Model.Intf, DelphiDoom.War.Model.Construction.Intf, DelphiDoom.War.Model.MapBinding, DelphiDoom.War.Ai.Players, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf,
  DelphiDoom.War.Ui.SceneBase, DelphiDoom.War.MapUi.Types, DelphiDoom.War.MapUi.Camera, DelphiDoom.War.MapUi.Sprites,
  DelphiDoom.War.MapUi.Renderer, DelphiDoom.War.MapUi.Hud, DelphiDoom.War.MapUi.Host, DelphiDoom.War.MapUi.Census,
  DelphiDoom.War.MapUi.Picker;

type
  /// <summary>What the scene of a map is made from: the level and its tileset, the tables and the services of the game</summary>
  TWarMapSceneSetup = record
    Services: TWarSceneServices;
    Level: IWarLevel;
    TilesetPixels: TBytes;
    Units: IWarUnitCatalog;
    Objectives: IWarObjectives;
    Random: IWarRandom;
    /// <summary>The map type of the original (the index of the level info)</summary>
    MapType: Integer;
    /// <summary>
    ///   True for the directions of a C built with gcc (the enum is unsigned, a unit that turns from north to the left
    ///   keeps north), which is what the reference of the parity is; False is MSVC
    /// </summary>
    UnsignedDirections: Boolean;
  end;

  /// <summary>
  ///   The map in play, as a scene that the game runs: Enter is wmap_enterMap (the map, the model, the computer player,
  ///   the camera and the images), Update is wmap_updateMap and Render is wmap_renderMap. The order of Update is the one of
  ///   the original: the camera, what the player asks for, the model (the computer player, every state, the actions, the
  ///   projectiles, the spells and the fog), then the panel of the commands, the status bar and the objectives
  /// </summary>
  TWarMapScene = class(TInterfacedObject, IWarScene)
  strict private
    FSetup: TWarMapSceneSetup;
    FHost: IWarMapHost;
    FMap: TWarGameMap;
    FBinding: TWarMapBinding;
    FAi: TWarComputerPlayers;
    FCamera: TWarMapCamera;
    FSprites: TWarMapSprites;
    FRenderer: TWarMapRenderer;
    FHud: TWarMapHud;
    FPicker: TWarMapPicker;
    FCensus: IWarCensus;
    FPanels: TWarMapPanels;
    FCommandPanel: TWarCommandPanel;
    FStatus: TWarStatusLine;
    FPlaying: Boolean;
    FResult: TWarLevelResult;
    FObjectivesTime: Single;
    FSuppressMinimap: Boolean;
    FMouseScrollSpeed: Integer;
    FKeyScrollSpeed: Integer;
    FGameSpeed: Integer;
    procedure UpdateObjectives;
    procedure UpdateStatus;
    procedure RenderMapUi;
    procedure UpdateMapCursor;
    function CursorOnMap: Integer;
    function MapSpeedScale: Single;
  public
    constructor Create(const ASetup: TWarMapSceneSetup);
    destructor Destroy; override;
    function GetSceneType: TWarSceneType;
    procedure Enter;
    procedure Update;
    procedure Render;
    procedure Leave;
    procedure HandleTextInput(const AText: AnsiString);
    property Camera: TWarMapCamera read FCamera;
    property Map: TWarGameMap read FMap;
    property Binding: TWarMapBinding read FBinding;
    property Playing: Boolean read FPlaying;
    property Result: TWarLevelResult read FResult;
  end;

implementation

uses
  DelphiDoom.War.Model.Factory, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Ui.Imui;

{ TWarMapScene }

constructor TWarMapScene.Create(const ASetup: TWarMapSceneSetup);
begin
  inherited Create;
  FSetup := ASetup;
  FPanels := TWarMapPanels.Standard;
end;

destructor TWarMapScene.Destroy;
begin
  Leave;
  inherited Destroy;
end;

function TWarMapScene.GetSceneType: TWarSceneType;
begin
  Result := wstMap;
end;

function TWarMapScene.MapSpeedScale: Single;
begin
  // wg_beginFrame: the speed of the map scales the time of the game
  Result := 1;
  if FGameSpeed < WAR_SPEED_NORMAL then
    Result := 1.0 - (WAR_SPEED_NORMAL - FGameSpeed) * Single(0.25)
  else if FGameSpeed > WAR_SPEED_NORMAL then
    Result := 1.0 + (FGameSpeed - WAR_SPEED_NORMAL) * Single(0.5);
end;

procedure TWarMapScene.Enter;
var
  LBuilder: TWarMapBuilder;
  LHost: TWarMapHost;
begin
  // wmap_enterMap
  FPlaying := True;
  FResult := wlrNone;
  FObjectivesTime := 1;
  FGameSpeed := WAR_SPEED_NORMAL;
  FMouseScrollSpeed := WAR_SPEED_NORMAL;
  FKeyScrollSpeed := WAR_SPEED_NORMAL;
  LHost := TWarMapHost.Create(FSetup.Units);
  FHost := LHost;
  LBuilder := TWarMapBuilder.Create(FSetup.Units);
  try
    FMap := LBuilder.Build(FSetup.Level, FSetup.TilesetPixels);
  finally
    LBuilder.Free;
  end;
  FSprites := TWarMapSprites.Create(FSetup.Services.Sprites, FSetup.TilesetPixels);
  FHost.Attach(nil, FMap.Fog, FSprites);
  FBinding := TWarModelFactory.CreateMapBinding(FMap, FSetup.Random, FHost as IWarModelEvents,
    FHost as IWarConstructionHost, FSetup.UnsignedDirections);
  FHost.Attach(FBinding.World.Context.Selection, FMap.Fog, FSprites);
  // wai_initAIPlayers: for now the player 1 is the only computer player
  FAi := TWarModelFactory.AttachComputerPlayers(FBinding.World, [1]);
  FCamera := TWarMapCamera.Create(FPanels, FMap.Viewport.X, FMap.Viewport.Y);
  FRenderer := TWarMapRenderer.Create(FSetup.Services.Canvas.Transform, FMap, FBinding.World.Context,
    FBinding.World.Machine, FSprites, FCamera);
  FHud := TWarMapHud.Create(FSetup.Services.Imui, FPanels);
  FPicker := TWarMapPicker.Create(FMap, FBinding.World.Context, FBinding.World.Machine);
  FCensus := TWarMapCensus.Create(FBinding.World.Context);
  FCommandPanel.Clear;
  FStatus.HighlightIndex := WAR_NO_HIGHLIGHT;
  // the tooltip is drawn where the bottom panel starts
  FSetup.Services.Imui.SetMapPanel(True, FPanels.BottomPanel.X, FPanels.BottomPanel.Y);
end;

procedure TWarMapScene.Leave;
begin
  if Assigned(FSetup.Services.Imui) then
    FSetup.Services.Imui.SetMapPanel(False, 0, 0);
  FreeAndNil(FRenderer);
  FreeAndNil(FHud);
  FreeAndNil(FPicker);
  FreeAndNil(FCamera);
  FCensus := nil;
  if Assigned(FHost) then
    FHost.Detach;
  FreeAndNil(FBinding);
  FreeAndNil(FSprites);
  FreeAndNil(FMap);
  FHost := nil;
end;

procedure TWarMapScene.HandleTextInput(const AText: AnsiString);
begin
end;

procedure TWarMapScene.UpdateStatus;
var
  LFlash: TWarFlashStatus;
begin
  // updateStatus: the status line is cleared, then the message that flashes, if it still lasts
  FStatus.Text := '';
  FStatus.HighlightIndex := WAR_NO_HIGHLIGHT;
  FStatus.HighlightCount := 0;
  FStatus.Gold := 0;
  FStatus.Wood := 0;
  LFlash := FHost.GetFlash;
  if LFlash.Enabled then
  begin
    if FSetup.Services.Host.RealTime <= LFlash.EndRealTime then
    begin
      FStatus.Text := Copy(LFlash.Text, 1, 255);
      Exit;
    end;
    LFlash.Enabled := False;
    FHost.SetFlash(LFlash);
  end;
end;

procedure TWarMapScene.UpdateObjectives;
var
  LResult: TWarLevelResult;
begin
  // updateObjectives and checkObjectives: once the first second has passed the rule of the map is asked every tic
  if FResult = wlrNone then
  begin
    FObjectivesTime := FObjectivesTime - FSetup.Services.Host.RealDeltaTime;
    LResult := wlrNone;
    if FObjectivesTime <= 0 then
      LResult := FSetup.Objectives.Check(FSetup.MapType, FCensus);
    FResult := LResult;
    Exit;
  end;
  // the map is over: nothing plays (the menu of the end is the part of the interface that is not here yet)
  FPlaying := False;
end;

procedure TWarMapScene.Update;
var
  LContext: TWarCameraContext;
  LHost: IWarSceneHost;
  LDelta: Single;
  LScale: Single;
begin
  LHost := FSetup.Services.Host;
  if not FPlaying then
    Exit;
  LContext.Dragging := False;
  LContext.CommandActive := False;
  LContext.CheatsOpen := False;
  LContext.ScreenWidth := LHost.OriginalWidth;
  LContext.ScreenHeight := LHost.OriginalHeight;
  LContext.RealDeltaTime := LHost.RealDeltaTime;
  LContext.MouseScrollSpeed := FMouseScrollSpeed;
  LContext.KeyScrollSpeed := FKeyScrollSpeed;
  FCamera.Update(FSetup.Services.Input, LContext, FSuppressMinimap);
  FBinding.World.Context.ViewportTop := FCamera.Y;
  // the real time of the game and the length of this tic of the game (wg_beginFrame)
  FHost.SetRealTime(LHost.RealTime);
  FBinding.World.Context.RealTime := LHost.RealTime;
  LScale := LHost.GlobalSpeed;
  LScale := LScale * MapSpeedScale;
  LDelta := LHost.RealDeltaTime * LScale;
  FBinding.World.Context.Clock^.GlobalSpeed := LHost.GlobalSpeed;
  FBinding.World.Context.Clock^.GameSpeed := FGameSpeed;
  FBinding.Tick(LDelta);
  FCommandPanel.Clear;
  UpdateStatus;
  UpdateObjectives;
end;

procedure TWarMapScene.RenderMapUi;
var
  LView: TWarHudView;
  LClicks: TWarHudClicks;
  LPlayer: TWarPlayerInfo;
begin
  // wmui_renderMapUI: the panels, the rectangle of the selection, the command that waits, the minimap, then the HUD
  FSetup.Services.Canvas.Transform.Save;
  LPlayer := FMap.Players[0];
  FHud.RenderStaticPanels(LPlayer.Race);
  FRenderer.RenderMinimap(FPanels.MinimapPanel.X, FPanels.MinimapPanel.Y);
  LView.Race := LPlayer.Race;
  LView.Gold := FBinding.World.Context.Players[0]^.Gold;
  LView.Wood := FBinding.World.Context.Players[0]^.Wood;
  LView.Panel := FCommandPanel;
  LView.Status := FStatus;
  LView.MenuOpen := False;
  LView.CheatsOpen := False;
  FHud.RenderHud(LView, LClicks);
  FSetup.Services.Canvas.Transform.Restore;
end;

function TWarMapScene.CursorOnMap: Integer;
var
  LContext: TWarModelContext;
  LInput: IWarUiInput;
  LMapX: Single;
  LMapY: Single;
  LTileX: Single;
  LTileY: Single;
  LKind: Integer;
  LUnder: Integer;
  LSelected: Integer;
  LUnderEntity: PWarEntity;
  LSelectedEntity: PWarEntity;
  LTile: TWarVec2;
  LUnderUnit: Boolean;
begin
  // updateMapCursor over the map with no command waiting: what is under the mouse and what is selected
  LContext := FBinding.World.Context;
  LInput := FSetup.Services.Input;
  FCamera.ScreenToMap(LInput.PositionX, LInput.PositionY, LMapX, LMapY);
  TWarMapCamera.MapToTile(LMapX, LMapY, LTileX, LTileY);
  LKind := FPicker.Find(LMapX, LMapY, True, True, LUnder);
  if LKind = WAR_ENTITY_NONE then
    Exit(WAR_CURSOR_ARROW);
  LUnderEntity := LContext.Pool.Slots[LUnder];
  LSelected := 0;
  if LContext.Selection.Count > 0 then
    LSelected := LContext.Pool.FindSlot(LContext.Selection[0]);
  if LSelected <> 0 then
  begin
    LSelectedEntity := LContext.Pool.Slots[LSelected];
    if (LSelectedEntity^.UnitData.Player = 0) and TWarUnitClassifier.IsDude(LSelectedEntity^.UnitData.UnitType) then
    begin
      LUnderUnit := LKind = WAR_ENTITY_UNIT;
      if LUnderUnit and (LUnderEntity^.UnitData.UnitType = WAR_UNIT_GOLDMINE) then
      begin
        LTile := TWarUnitGeometry.Tile(LUnderEntity);
        if (not FMap.Fog.AreAllTilesInState(Trunc(LTile.X), Trunc(LTile.Y), LUnderEntity^.UnitData.SizeX,
          LUnderEntity^.UnitData.SizeY, wtsUnknown)) and TWarUnitClassifier.IsWorker(LSelectedEntity^.UnitData.UnitType) then
          Exit(WAR_CURSOR_YELLOW_CROSSHAIR);
      end;
      if (LKind = WAR_ENTITY_FOREST) and (not FMap.Fog.IsTileUnknown(Trunc(LTileX), Trunc(LTileY))) and
        TWarUnitClassifier.IsWorker(LSelectedEntity^.UnitData.UnitType) then
        Exit(WAR_CURSOR_YELLOW_CROSSHAIR);
      if (LKind = WAR_ENTITY_WALL) and (not FMap.Fog.IsTileUnknown(Trunc(LTileX), Trunc(LTileY))) and
        TWarUnitClassifier.IsWarrior(LSelectedEntity^.UnitData.UnitType) and
        LContext.Queries.CanAttack(LSelected, LUnder) then
        Exit(WAR_CURSOR_RED_CROSSHAIR);
      // wu_isFriendlyUnit of what is not a unit is false
      if ((not LUnderUnit) or (LUnderEntity^.UnitData.Player <> 0)) and
        TWarUnitClassifier.IsWarrior(LSelectedEntity^.UnitData.UnitType) and
        LContext.Queries.CanAttack(LSelected, LUnder) then
        Exit(WAR_CURSOR_RED_CROSSHAIR);
    end;
  end;
  if (LKind = WAR_ENTITY_FOREST) or (LKind = WAR_ENTITY_WALL) then
    Result := WAR_CURSOR_ARROW
  else
    Result := WAR_CURSOR_MAGNIFYING_GLASS;
end;

procedure TWarMapScene.UpdateMapCursor;
var
  LInput: IWarUiInput;
  LImui: TWarImui;
  LDirX: Single;
  LDirY: Single;
begin
  // updateMapCursor: the cursor follows what the mouse is on
  LInput := FSetup.Services.Input;
  LImui := FSetup.Services.Imui;
  if not FPlaying then
  begin
    LImui.ChangeCursorType(WAR_CURSOR_ARROW);
    Exit;
  end;
  if WarRectContains(FPanels.MapPanel, LInput.PositionX, LInput.PositionY) then
    LImui.ChangeCursorType(CursorOnMap)
  else if WarRectContains(FPanels.MinimapPanel, LInput.PositionX, LInput.PositionY) then
    LImui.ChangeCursorType(WAR_CURSOR_ARROW)
  else
  begin
    // at the edge of the screen the arrow points where the map scrolls
    TWarMapCamera.DirFromMousePosition(LInput, FSetup.Services.Host.OriginalWidth, FSetup.Services.Host.OriginalHeight,
      LDirX, LDirY);
    if (LDirX < 0) and (LDirY < 0) then
      LImui.ChangeCursorType(WAR_CURSOR_ARROW_UP_LEFT)
    else if (LDirX < 0) and (LDirY > 0) then
      LImui.ChangeCursorType(WAR_CURSOR_ARROW_BOTTOM_LEFT)
    else if (LDirX > 0) and (LDirY < 0) then
      LImui.ChangeCursorType(WAR_CURSOR_ARROW_UP_RIGHT)
    else if (LDirX > 0) and (LDirY > 0) then
      LImui.ChangeCursorType(WAR_CURSOR_ARROW_BOTTOM_RIGHT)
    else if LDirX < 0 then
      LImui.ChangeCursorType(WAR_CURSOR_ARROW_LEFT)
    else if LDirX > 0 then
      LImui.ChangeCursorType(WAR_CURSOR_ARROW_RIGHT)
    else if LDirY < 0 then
      LImui.ChangeCursorType(WAR_CURSOR_ARROW_UP)
    else if LDirY > 0 then
      LImui.ChangeCursorType(WAR_CURSOR_ARROW_BOTTOM)
    else
      LImui.ChangeCursorType(WAR_CURSOR_ARROW);
  end;
end;

procedure TWarMapScene.Render;
begin
  // wmap_renderMap: the cursor of the mouse, the map, then the interface
  UpdateMapCursor;
  FRenderer.RenderPanel;
  RenderMapUi;
end;

end.
