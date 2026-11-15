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
  DelphiDoom.War.MapUi.Picker, DelphiDoom.War.MapUi.Intf, DelphiDoom.War.MapUi.Selecting,
  DelphiDoom.War.MapUi.CommandPanel, DelphiDoom.War.MapUi.CommandState, DelphiDoom.War.MapUi.CommandRunner,
  DelphiDoom.War.MapUi.CommandPreview;

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
  TWarMapScene = class(TInterfacedObject, IWarScene, IWarPausableScene, IWarScriptedScene)
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
    FSelecting: TWarMapSelecting;
    FCommandBuilder: TWarMapCommandPanel;
    FCommandState: TWarMapCommandState;
    FCommandRunner: TWarMapCommandRunner;
    FCommandPreview: TWarMapCommandPreview;
    FAudio: IWarMapAudio;
    FCensus: IWarCensus;
    FPanels: TWarMapPanels;
    FCommandPanel: TWarCommandPanel;
    FStatus: TWarStatusLine;
    FPlaying: Boolean;
    FResult: TWarLevelResult;
    FObjectivesTime: Single;
    FMouseScrollSpeed: Integer;
    FKeyScrollSpeed: Integer;
    FGameSpeed: Integer;
    procedure UpdateObjectives;
    procedure UpdateStatus;
    procedure RenderMapUi;
    procedure UpdateMapCursor;
    procedure UpdateRightClick;
    procedure FillSelection(var AView: TWarHudView);
    procedure UpdateCamera;
    procedure StatusOfBuilding(ASlot: Integer);
    function CursorOnMap: Integer;
    function MapSpeedScale: Single;
  public
    constructor Create(const ASetup: TWarMapSceneSetup);
    destructor Destroy; override;
    function GetSceneType: TWarSceneType;
    procedure Enter;
    procedure Update;
    /// <summary>wmap_updateMapPaused: the camera and the status, nothing else moves</summary>
    procedure UpdatePaused;
    procedure Render;
    procedure Leave;
    procedure HandleTextInput(const AText: AnsiString);
    /// <summary>
    ///   The commands of the scripts of the harness that change the map: unit TYPE X Y PLAYER (a unit at rest on the tile under
    ///   the point of the screen), upgrade INDEX ALLOWED LEVEL, feature INDEX VALUE, gold GOLD WOOD (of the player 0)
    /// </summary>
    function ScriptCommand(const ACommand: string; const AArguments: TArray<string>): Boolean;
    property Camera: TWarMapCamera read FCamera;
    property Map: TWarGameMap read FMap;
    property Binding: TWarMapBinding read FBinding;
    property Playing: Boolean read FPlaying;
    property Result: TWarLevelResult read FResult;
  end;

implementation

uses
  DelphiDoom.War.Model.Factory, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.Commands.Types,
  DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Model.State.Types, DelphiDoom.War.MapUi.CommandCatalog,
  DelphiDoom.War.MapUi.CommandCursor, DelphiDoom.War.Model.Combat.Intf, DelphiDoom.War.Sound.Factory, DelphiDoom.War.MapUi.Audio, DelphiDoom.War.Ui.Imui, System.Math;

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
  // the blows, the impacts and the spells tell the host, which makes their sounds (entities of the pool and numbers drawn)
  FBinding.World.Context.CombatEvents := FHost as IWarCombatEvents;
  FBinding.World.Context.SpellEvents := FHost as IWarSpellEvents;
  // wai_initAIPlayers: for now the player 1 is the only computer player
  FAi := TWarModelFactory.AttachComputerPlayers(FBinding.World, [1]);
  FCamera := TWarMapCamera.Create(FPanels, FMap.Viewport.X, FMap.Viewport.Y);
  FRenderer := TWarMapRenderer.Create(FSetup.Services.Canvas.Transform, FMap, FBinding.World.Context,
    FBinding.World.Machine, FSprites, FCamera);
  FHud := TWarMapHud.Create(FSetup.Services.Imui, FPanels);
  FPicker := TWarMapPicker.Create(FMap, FBinding.World.Context, FBinding.World.Machine);
  // the sounds that the model asks for and that the player's choices make: entities of the pool and numbers drawn
  FAudio := TWarMapAudio.Create(FBinding.World.Context, TWarSoundFactory.CreatePicker(FSetup.Random), FSetup.Random);
  FHost.AttachAudio(FAudio);
  FSelecting := TWarMapSelecting.Create(FMap, FBinding.World.Context, FBinding.World.Machine, FCamera, FPicker,
    FBinding.Commands.Selecting, FAudio);
  FCommandState := TWarMapCommandState.Create;
  FSelecting.CommandState := FCommandState;
  FCommandRunner := TWarMapCommandRunner.Create(FBinding.World.Context, FBinding.Commands, FCamera, FCommandState);
  FCommandPreview := TWarMapCommandPreview.Create(FSetup.Services.Canvas.Transform, FCamera, FBinding.World.Context,
    FBinding.Commands, FCommandState);
  FCommandBuilder := TWarMapCommandPanel.Create(FBinding.World.Context);
  // wmui_createMapUI makes the entity of the minimap; then the music, which is an entity too (not in the demo)
  FBinding.World.Context.Pool.CreateEntity(WAR_ENTITY_MINIMAP, True);
  if not FSetup.Services.Host.IsDemo then
    FAudio.PlaySound(0);
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
  FreeAndNil(FSelecting);
  FreeAndNil(FCommandPreview);
  FreeAndNil(FCommandRunner);
  FreeAndNil(FCommandState);
  FreeAndNil(FCommandBuilder);
  FAudio := nil;
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

function TWarMapScene.ScriptCommand(const ACommand: string; const AArguments: TArray<string>): Boolean;
var
  LMapX: Single;
  LMapY: Single;
  LTileX: Single;
  LTileY: Single;
  LSlot: Integer;
  LPlayer: PWarPlayerInfo;
begin
  Result := True;
  if not Assigned(FBinding) then
    Exit(False);
  LPlayer := FBinding.World.Context.Players[0];
  if ACommand = 'unit' then
  begin
    FCamera.ScreenToMap(StrToFloat(AArguments[1], TFormatSettings.Invariant),
      StrToFloat(AArguments[2], TFormatSettings.Invariant), LMapX, LMapY);
    TWarMapCamera.MapToTile(LMapX, LMapY, LTileX, LTileY);
    LSlot := FBinding.World.Entities.CreateUnit(StrToInt(AArguments[0]), Trunc(LTileX), Trunc(LTileY),
      StrToInt(AArguments[3]), wrkNone, 0, True);
    if LSlot = 0 then
      raise EWarException.Create('The pool of entities is full');
    FBinding.World.Entities.SetInitialIdle(LSlot);
  end
  else if ACommand = 'building' then
  begin
    FCamera.ScreenToMap(StrToFloat(AArguments[1], TFormatSettings.Invariant),
      StrToFloat(AArguments[2], TFormatSettings.Invariant), LMapX, LMapY);
    TWarMapCamera.MapToTile(LMapX, LMapY, LTileX, LTileY);
    LSlot := FBinding.World.Entities.CreateBuilding(StrToInt(AArguments[0]), Trunc(LTileX), Trunc(LTileY),
      StrToInt(AArguments[3]), False);
    if LSlot = 0 then
      raise EWarException.Create('The building could not be created');
  end
  else if ACommand = 'upgrade' then
  begin
    LPlayer^.Upgrades[StrToInt(AArguments[0]) div 2].Allowed := StrToInt(AArguments[1]);
    LPlayer^.Upgrades[StrToInt(AArguments[0]) div 2].Level := StrToInt(AArguments[2]);
  end
  else if ACommand = 'feature' then
    LPlayer^.Features[StrToInt(AArguments[0]) div 2] := StrToInt(AArguments[1])
  else if ACommand = 'gold' then
  begin
    LPlayer^.Gold := StrToInt(AArguments[0]);
    LPlayer^.Wood := StrToInt(AArguments[1]);
  end
  else
    Result := False;
end;

procedure TWarMapScene.StatusOfBuilding(ASlot: Integer);
var
  LMachine: TWarStateMachine;
  LEntity: PWarEntity;
  LState: PWarStateBase;
  LCost: Single;
begin
  // updateStatus for a selected building: what it trains or researches, or what the repair would cost
  LMachine := FBinding.World.Machine;
  LEntity := FBinding.World.Context.Pool.Slots[ASlot];
  if LMachine.Contains(ASlot, WAR_STATE_TRAIN) or LMachine.HasPending(ASlot, WAR_STATE_TRAIN) then
  begin
    // wst_getTrainState looks in the stack only: the original stops on a request that did not start yet, here the line stays
    LState := LMachine.FindState(ASlot, WAR_STATE_TRAIN);
    if Assigned(LState) then
      FStatus.Text := TWarCommandCatalog.Base(TWarCommandCatalog.CommandOfUnit(PWarStateTrain(LState)^.UnitToBuild)).Tooltip2;
  end
  else if LMachine.Contains(ASlot, WAR_STATE_UPGRADE) or LMachine.HasPending(ASlot, WAR_STATE_UPGRADE) then
  begin
    LState := LMachine.FindState(ASlot, WAR_STATE_UPGRADE);
    if Assigned(LState) then
      FStatus.Text := TWarCommandCatalog.Base(
        TWarCommandCatalog.CommandOfUpgrade(PWarStateUpgrade(LState)^.UpgradeToBuild)).Tooltip2;
  end
  else if LEntity^.UnitData.Hp < LEntity^.UnitData.MaxHp then
  begin
    // 12% of the damage, in gold and lumber
    LCost := (LEntity^.UnitData.MaxHp - LEntity^.UnitData.Hp) * Single(0.12);
    FStatus.Text := AnsiString(Format('FULL REPAIRS WILL COST %d GOLD & LUMBER', [Ceil(LCost)]));
  end;
end;

procedure TWarMapScene.UpdateStatus;
var
  LFlash: TWarFlashStatus;
  LContext: TWarModelContext;
  LIndex: Integer;
  LSlot: Integer;
  LEntity: PWarEntity;
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
  // what the selection says: the cost to repair a building that is hurt, what a worker carries (the line of a building
  // that trains or researches is not ported). Each selected entity may replace the line, the last one stays
  LContext := FBinding.World.Context;
  for LIndex := 0 to LContext.Selection.Count - 1 do
  begin
    LSlot := LContext.Pool.FindSlot(LContext.Selection[LIndex]);
    if LSlot = 0 then
      Continue;
    LEntity := LContext.Pool.Slots[LSlot];
    if TWarUnitClassifier.IsBuilding(LEntity^.UnitData.UnitType) then
      StatusOfBuilding(LSlot)
    else if TWarUnitClassifier.IsWorker(LEntity^.UnitData.UnitType) and
      (((LEntity^.UnitData.ResourceKind = wrkGold) or (LEntity^.UnitData.ResourceKind = wrkWood)) and
      (LEntity^.UnitData.Amount = WAR_MODEL_MAX_CARRY)) then
    begin
      if LEntity^.UnitData.ResourceKind = wrkGold then
        FStatus.Text := 'CARRYING GOLD'
      else
        FStatus.Text := 'CARRYING LUMBER';
    end;
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

procedure TWarMapScene.UpdateCamera;
var
  LContext: TWarCameraContext;
  LHost: IWarSceneHost;
  LSuppress: Boolean;
begin
  // updateViewport: what the camera reads of the map besides the mouse (the drag, the command that waits, the flag of the minimap)
  LHost := FSetup.Services.Host;
  LContext.Dragging := FSelecting.IsDragging;
  LContext.CommandActive := FCommandState.Pending;
  LContext.CheatsOpen := False;
  LContext.ScreenWidth := LHost.OriginalWidth;
  LContext.ScreenHeight := LHost.OriginalHeight;
  LContext.RealDeltaTime := LHost.RealDeltaTime;
  LContext.MouseScrollSpeed := FMouseScrollSpeed;
  LContext.KeyScrollSpeed := FKeyScrollSpeed;
  LSuppress := FCommandState.SuppressMinimapViewportOnRelease;
  FCamera.Update(FSetup.Services.Input, LContext, LSuppress);
  FCommandState.SuppressMinimapViewportOnRelease := LSuppress;
end;

procedure TWarMapScene.UpdatePaused;
var
  LHost: IWarSceneHost;
begin
  // wmap_updateMapPaused: updateViewport and updateStatus (the debug shortcuts are not ported)
  LHost := FSetup.Services.Host;
  if (not Assigned(FCamera)) or (not FPlaying) then
    Exit;
  UpdateCamera;
  FHost.SetRealTime(LHost.RealTime);
  UpdateStatus;
end;

procedure TWarMapScene.Update;
var
  LHost: IWarSceneHost;
  LDelta: Single;
  LScale: Single;
begin
  LHost := FSetup.Services.Host;
  if not FPlaying then
    Exit;
  // the real time of this frame, before anything can ask for a message of the status line (the command of a click does)
  FHost.SetRealTime(LHost.RealTime);
  FBinding.World.Context.RealTime := LHost.RealTime;
  UpdateCamera;
  FSelecting.UpdateDragRect(FSetup.Services.Input);
  // only the clicks that no command takes select: some commands run with the click that selects
  if not FCommandRunner.Execute(FSetup.Services.Input) then
    FSelecting.UpdateSelection(FSetup.Services.Input);
  FSelecting.UpdateGroups(FSetup.Services.Input);
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
  FCommandBuilder.Update(FCommandPanel, FCommandState.CommandType);
  UpdateRightClick;
  UpdateStatus;
  UpdateObjectives;
end;

procedure TWarMapScene.UpdateRightClick;
var
  LInput: IWarUiInput;
  LMapX: Single;
  LMapY: Single;
  LTarget: TWarVec2;
  LTileX: Single;
  LTileY: Single;
begin
  // updateCommandFromRightClick with no command waiting: an order to what is selected
  LInput := FSetup.Services.Input;
  if not LInput.IsButtonJustPressed(wmbRight) then
    Exit;
  // with a command waiting the right click cancels it
  if FCommandState.Pending then
  begin
    FCommandRunner.CancelWithRightClick;
    Exit;
  end;
  if FBinding.World.Context.Selection.Count = 0 then
    Exit;
  if WarRectContains(FPanels.MapPanel, LInput.PositionX, LInput.PositionY) then
  begin
    FCamera.ScreenToMap(LInput.PositionX, LInput.PositionY, LMapX, LMapY);
    LTarget.X := LMapX;
    LTarget.Y := LMapY;
    FBinding.Commands.RightClick(LTarget);
  end
  else if WarRectContains(FPanels.MinimapPanel, LInput.PositionX, LInput.PositionY) then
  begin
    // on the minimap: the tile, in the middle
    LTileX := LInput.PositionX - FPanels.MinimapPanel.X;
    LTileY := LInput.PositionY - FPanels.MinimapPanel.Y;
    TWarMapCamera.TileToMap(LTileX, LTileY, True, LMapX, LMapY);
    LTarget.X := LMapX;
    LTarget.Y := LMapY;
    FBinding.Commands.Execute(WAR_COMMAND_MOVE, LTarget);
  end;
end;

procedure TWarMapScene.FillSelection(var AView: TWarHudView);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LSlot: Integer;
  LEntity: PWarEntity;
begin
  LContext := FBinding.World.Context;
  AView.SelectedCount := Min(LContext.Selection.Count, 4);
  for LIndex := 0 to 3 do
    AView.Selected[LIndex] := Default(TWarHudSelected);
  for LIndex := 0 to AView.SelectedCount - 1 do
  begin
    LSlot := LContext.Pool.FindSlot(LContext.Selection[LIndex]);
    if LSlot = 0 then
      Continue;
    LEntity := LContext.Pool.Slots[LSlot];
    if not LEntity^.HasUnit then
      Continue;
    AView.Selected[LIndex].Valid := True;
    AView.Selected[LIndex].UnitType := LEntity^.UnitData.UnitType;
    AView.Selected[LIndex].Hp := LEntity^.UnitData.Hp;
    AView.Selected[LIndex].MaxHp := LEntity^.UnitData.MaxHp;
    AView.Selected[LIndex].Mana := LEntity^.UnitData.Mana;
    AView.Selected[LIndex].MaxMana := LEntity^.UnitData.MaxMana;
    AView.Selected[LIndex].IsDude := TWarUnitClassifier.IsDude(LEntity^.UnitData.UnitType);
    AView.Selected[LIndex].IsMagic := TWarUnitClassifier.IsMagic(LEntity^.UnitData.UnitType);
    AView.Selected[LIndex].IsBuilding := TWarUnitClassifier.IsBuilding(LEntity^.UnitData.UnitType);
    AView.Selected[LIndex].UnderConstruction := LEntity^.UnitData.Building;
    AView.Selected[LIndex].BuildPercent := LEntity^.UnitData.BuildPercent;
  end;
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
  if FSelecting.IsDragging then
  begin
    FSetup.Services.Canvas.Transform.Save;
    FSetup.Services.Canvas.Transform.StrokeRect(FSelecting.DragRect, WAR_MAPUI_GREEN_SELECTION);
    FSetup.Services.Canvas.Transform.Restore;
  end;
  FCommandPreview.Render(FSetup.Services.Input);
  FRenderer.RenderMinimap(FPanels.MinimapPanel.X, FPanels.MinimapPanel.Y);
  FillSelection(LView);
  LView.Race := LPlayer.Race;
  LView.Gold := FBinding.World.Context.Players[0]^.Gold;
  LView.Wood := FBinding.World.Context.Players[0]^.Wood;
  LView.Panel := FCommandPanel;
  LView.Status := FStatus;
  LView.MenuOpen := False;
  LView.CheatsOpen := False;
  FHud.RenderHud(LView, LClicks);
  // the click handler of a button runs while the HUD is drawn: it chooses the command (or cancels), the next update executes it
  if LClicks.Command >= 0 then
    FCommandRunner.ClickCommand(FCommandPanel.Slots[LClicks.Command].Command);
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
  LCursor: Integer;
begin
  // updateMapCursor: the cursor follows what the mouse is on
  LInput := FSetup.Services.Input;
  LImui := FSetup.Services.Imui;
  if not FPlaying then
  begin
    LImui.ChangeCursorType(WAR_CURSOR_ARROW);
    Exit;
  end;
  if FSelecting.IsDragging then
  begin
    LImui.ChangeCursorType(WAR_CURSOR_GREEN_CROSSHAIR);
    Exit;
  end;
  if WarRectContains(FPanels.MapPanel, LInput.PositionX, LInput.PositionY) then
  begin
    // a command that waits has its cursor; with none (or one that does not choose) it is what is under the mouse
    LCursor := TWarCommandCursor.OverMap(FCommandState.CommandType);
    if LCursor < 0 then
      LCursor := CursorOnMap;
    LImui.ChangeCursorType(LCursor);
  end
  else if WarRectContains(FPanels.MinimapPanel, LInput.PositionX, LInput.PositionY) then
    LImui.ChangeCursorType(TWarCommandCursor.OverMinimap(FCommandState.CommandType))
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
