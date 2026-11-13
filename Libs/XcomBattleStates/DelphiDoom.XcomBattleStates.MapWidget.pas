{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the map of the battle as a     }
{  surface of a state (the InteractiveSurface part of Map and the input of      }
{  Camera: the cursor of the tiles, the scrolling, the hidden movement)         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.MapWidget;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Timer,
  DelphiDoom.XcomUi.NumberText, DelphiDoom.XcomBattlescape.Map, DelphiDoom.XcomBattlescape.Camera,
  DelphiDoom.XcomBattleStates.Session.Intf, DelphiDoom.XcomBattleStates.BattlescapeMessage,
  DelphiDoom.XcomSurface.BlendOverlay, DelphiDoom.XcomEngine.TrueColor.Intf, DelphiDoom.XcomEngine.Screen;

type
  /// <summary>
  ///   The surface of the map in a state: it draws the TXcomBattleMap of the battle (or the message of the hidden
  ///   movement when the player must not see), moves the cursor of the tiles with the mouse and scrolls the camera
  ///   at the edges of the screen and with the arrow keys. Owns the map, the message and the timers; the session is
  ///   shared. Not ported: the scrolling by dragging (Options::battleDragScrollButton)
  /// </summary>
  TXcomMapWidget = class(TXcomInteractiveSurface)
  strict private
    FState: TXcomState;
    FSession: IXcomBattleSession;
    FMap: TXcomBattleMap;
    FMessage: TXcomBattlescapeMessage;
    FNumber: TXcomNumberText;
    FScrollMouseTimer: TXcomTimer;
    FScrollKeyTimer: TXcomTimer;
    FObstacleTimer: TXcomTimer;
    FScrollMouseX: Integer;
    FScrollMouseY: Integer;
    FScrollKeyX: Integer;
    FScrollKeyY: Integer;
    FScrollTrigger: Boolean;
    FMouseX: Integer;
    FMouseY: Integer;
    FIconWidth: Integer;
    FIconHeight: Integer;
    FVisibleMapHeight: Integer;
    FIsLaunchAction: TFunc<Boolean>;
    FHiddenMovement: Boolean;
    /// <summary>The blends of the map, made when the screen composes in true color (nil otherwise)</summary>
    FOverlay: TXcomBlendOverlay;
    procedure PrepareOverlay;
    procedure LeaveBlends(ATarget: TXcomSurface);
    procedure CameraMouseOver(AAction: TXcomAction);
    procedure UpdateKeyTimer;
    function Option(const AId: string): Integer;
  protected
    procedure MousePress(AAction: TXcomAction); override;
    procedure MouseRelease(AAction: TXcomAction); override;
    procedure MouseOver(AAction: TXcomAction); override;
    procedure KeyboardPress(AAction: TXcomAction); override;
    procedure KeyboardRelease(AAction: TXcomAction); override;
  public
    /// <param name="AState">The state of the battle (the clock, the options and the interface come from its host)</param>
    /// <param name="AVisibleMapHeight">The height of the screen that the panel of the icons leaves free</param>
    constructor Create(AState: TXcomState; const ASession: IXcomBattleSession; AWidth, AHeight, AX, AY,
      AVisibleMapHeight: Integer);
    destructor Destroy; override;
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256); override;
    procedure Think; override;
    procedure Draw; override;
    procedure Blit(ATarget: TXcomSurface); override;
    /// <summary>Map::refreshSelectorPosition: the cursor of the tiles goes back under the mouse</summary>
    procedure RefreshSelectorPosition;
    /// <summary>Map::enableObstacles: the tiles that block the shot are marked for two seconds and a half</summary>
    procedure EnableObstacles;
    /// <summary>Map::disableObstacles</summary>
    procedure DisableObstacles;
    /// <summary>Camera::stopMouseScrolling</summary>
    procedure StopMouseScrolling;
    /// <summary>The picture of the battle (camera, cursor, projectile, explosions)</summary>
    property Map: TXcomBattleMap read FMap;
    function Camera: TXcomCamera;
    property IconWidth: Integer read FIconWidth;
    property IconHeight: Integer read FIconHeight;
    /// <summary>Map::getMessageY: where the window of the hidden movement starts</summary>
    function MessageY: Integer;
    /// <summary>Says whether the current action is the launch of a guided missile (its waypoints are numbered)</summary>
    property IsLaunchAction: TFunc<Boolean> read FIsLaunchAction write FIsLaunchAction;
    /// <summary>The last draw showed the message of the hidden movement instead of the map</summary>
    property HiddenMovement: Boolean read FHiddenMovement;
  end;

implementation

uses
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattleStates.OffsetBlit;

const
  SCROLL_INTERVAL = 15;
  SCROLL_BORDER = 5;
  SCROLL_DIAGONAL_EDGE = 60;
  SCROLL_TRIGGER = 1;
  SCROLL_AUTO = 2;
  OBSTACLE_INTERVAL = 2500;
  BACKGROUND_COLOR = 15;

constructor TXcomMapWidget.Create(AState: TXcomState; const ASession: IXcomBattleSession; AWidth, AHeight, AX, AY,
  AVisibleMapHeight: Integer);
var
  LSettings: TXcomBattleMapSettings;
  LInterface: TXcomRuleInterface;
  LElement: TXcomInterfaceElement;
  LMessageHeight: Integer;
  LMessageColor: Integer;
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FState := AState;
  FSession := ASession;
  FVisibleMapHeight := AVisibleMapHeight;
  LMessageColor := 0;
  LInterface := AState.Host.Resources.GetInterface('battlescape');
  if Assigned(LInterface) and LInterface.TryGetElement('icons', LElement) then
  begin
    FIconWidth := LElement.W;
    FIconHeight := LElement.H;
  end;
  if Assigned(LInterface) and LInterface.TryGetElement('messageWindows', LElement) then
    LMessageColor := LElement.Color;
  LSettings.Width := AWidth;
  LSettings.Height := AHeight;
  LSettings.IconWidth := FIconWidth;
  LSettings.IconHeight := FIconHeight;
  LSettings.SmokeOffset := ASession.Ruleset.Constants.SmokeOffset;
  LSettings.UnderwaterSmokeOffset := ASession.Ruleset.Constants.UnderwaterSmokeOffset;
  LSettings.Transparencies := ASession.Graphics.Transparencies(ASession.Battle.Depth);
  FMap := TXcomBattleMap.Create(ASession.Battle, ASession.Graphics.Sprites, LSettings);
  FMap.TileEngine := ASession.TileEngine;
  FMap.PreviewSetting := Option('battleNewPreviewPath');
  FMap.SmoothCamera := AState.Host.Options.GetBool('battleSmoothCamera');
  FMap.MessageColor := LMessageColor;
  FMap.Breathing := True;
  FNumber := TXcomNumberText.Create(15, 15, 20, 30);
  FMap.NumberSource :=
    function(AValue, AColor: Integer; ABordered: Boolean): TXcomSurface
    begin
      FNumber.SetValue(Cardinal(AValue));
      FNumber.SetColor(Byte(AColor));
      FNumber.SetBordered(ABordered);
      FNumber.Draw;
      Result := FNumber;
    end;
  if AVisibleMapHeight < 200 then
    LMessageHeight := AVisibleMapHeight
  else
    LMessageHeight := 200;
  FMessage := TXcomBattlescapeMessage.Create(AState, 320, LMessageHeight, 0, 0);
  FMessage.X := (AWidth - 320) div 2;
  FMessage.Y := (AVisibleMapHeight - FMessage.Height) div 2;
  FMessage.SetTextColor(Byte(LMessageColor));
  FScrollMouseTimer := TXcomTimer.Create(AState.Host.Clock, SCROLL_INTERVAL);
  FScrollMouseTimer.OnTimerSurface(
    procedure
    begin
      FMap.Camera.ScrollXY(FScrollMouseX, FScrollMouseY, True);
    end);
  FScrollKeyTimer := TXcomTimer.Create(AState.Host.Clock, SCROLL_INTERVAL);
  FScrollKeyTimer.OnTimerSurface(
    procedure
    begin
      FMap.Camera.ScrollXY(FScrollKeyX, FScrollKeyY, True);
    end);
  FObstacleTimer := TXcomTimer.Create(AState.Host.Clock, OBSTACLE_INTERVAL);
  FObstacleTimer.OnTimerSurface(
    procedure
    begin
      DisableObstacles;
    end);
end;

destructor TXcomMapWidget.Destroy;
begin
  FMap.BlendOverlay := nil;
  FOverlay.Free;
  FObstacleTimer.Free;
  FScrollKeyTimer.Free;
  FScrollMouseTimer.Free;
  FMessage.Free;
  FMap.Free;
  FNumber.Free;
  inherited Destroy;
end;

function TXcomMapWidget.Option(const AId: string): Integer;
begin
  Result := FState.Host.Options.GetValue(AId);
end;

function TXcomMapWidget.Camera: TXcomCamera;
begin
  Result := FMap.Camera;
end;

function TXcomMapWidget.MessageY: Integer;
begin
  Result := FMessage.Y;
end;

procedure TXcomMapWidget.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
begin
  inherited SetPalette(AColors, AFirst, ACount);
  FNumber.SetPalette(AColors, AFirst, ACount);
  FMessage.SetPalette(AColors, AFirst, ACount);
  FMessage.SetBackground(FSession.Graphics.Surface('TAC00.SCR'));
  if FState.Host.Language <> nil then
  begin
    FMessage.InitText(FState.Host.Resources.GetFont('FONT_BIG'), FState.Host.Resources.GetFont('FONT_SMALL'),
      FState.Host.Language);
    FMessage.SetText(FState.Tr('STR_HIDDEN_MOVEMENT').Text);
  end;
end;

procedure TXcomMapWidget.Think;
begin
  FScrollMouseTimer.Think(False, True);
  FScrollKeyTimer.Think(False, True);
  FObstacleTimer.Think(False, True);
end;

procedure TXcomMapWidget.Draw;
begin
  Redraw := False;
  PrepareOverlay;
  FMap.UpdateFieldOfView;
  FMap.PathPreviewed := FSession.Pathfinding.PathPreviewed;
  FMap.NumberedWaypoints := Assigned(FIsLaunchAction) and FIsLaunchAction();
  // the steps of the battle change what is shown without telling: the map is drawn again every time
  FMap.Invalidate;
  FHiddenMovement := not FMap.Draw;
  if FHiddenMovement then
  begin
    // the message is not drawn here: it goes on the target by Blit, so that its text can be drawn at the
    // resolution of the screen (issue 188)
    Clear(BACKGROUND_COLOR);
  end
  else
    Move(FMap.Surface.PixelPointer(0, 0)^, PixelPointer(0, 0)^, Width * Height);
end;

procedure TXcomMapWidget.PrepareOverlay;
var
  LScreen: TXcomScreen;
begin
  LScreen := FState.Host.Screen;
  if (LScreen = nil) or (LScreen.BlendLayers = nil) then
  begin
    // the 8 bit path: the map draws what it always drew and tells nobody
    FMap.BlendOverlay := nil;
    Exit;
  end;
  if (not Assigned(FOverlay)) or (FOverlay.Width <> Width) or (FOverlay.Height <> Height) then
  begin
    FOverlay.Free;
    FOverlay := TXcomBlendOverlay.Create(Width, Height);
  end;
  // the palette of the screen as it is now (a fade changes it, the map is drawn again at every frame)
  FOverlay.SetPalette(LScreen.Palette^);
  FMap.BlendOverlay := FOverlay;
end;

procedure TXcomMapWidget.LeaveBlends(ATarget: TXcomSurface);
var
  LScreen: TXcomScreen;
  LLayers: IXcomBlendLayers;
begin
  LScreen := FState.Host.Screen;
  if (FOverlay = nil) or (FMap.BlendOverlay = nil) or (not FOverlay.HasBlends) or FHiddenMovement or (not Visible)
    or Hidden or (LScreen = nil) or (ATarget <> LScreen.GetSurface) then
    Exit;
  LLayers := LScreen.BlendLayers;
  if Assigned(LLayers) then
    LLayers.AddBlendLayer(ATarget, X, Y, Width, Height, FOverlay.Valid, FOverlay.Colors, Width);
end;

procedure TXcomMapWidget.Blit(ATarget: TXcomSurface);
begin
  Redraw := True;
  inherited Blit(ATarget);
  LeaveBlends(ATarget);
  // the hidden movement: the window and its text on the target itself (a separate layer over the map), as the text
  // of a widget drawn on the screen leaves its ink only there
  if FHiddenMovement and Visible and not Hidden then
    TXcomOffsetBlit.Blit(FMessage, ATarget, X, Y);
end;

procedure TXcomMapWidget.RefreshSelectorPosition;
begin
  FMap.SetSelectorFromScreen(FMouseX, FMouseY);
end;

procedure TXcomMapWidget.EnableObstacles;
begin
  FMap.EnableObstacles;
  FObstacleTimer.Stop;
  FObstacleTimer.Start;
end;

procedure TXcomMapWidget.DisableObstacles;
begin
  FMap.DisableObstacles;
  FObstacleTimer.Stop;
end;

procedure TXcomMapWidget.StopMouseScrolling;
begin
  FScrollMouseTimer.Stop;
end;

procedure TXcomMapWidget.MousePress(AAction: TXcomAction);
begin
  inherited MousePress(AAction);
  // Camera::mousePress
  if (AAction.Details.Button = XCOM_BUTTON_LEFT) and (Option('battleEdgeScroll') = SCROLL_TRIGGER) then
  begin
    FScrollTrigger := True;
    CameraMouseOver(AAction);
  end
  else if AAction.Details.Button = XCOM_BUTTON_WHEELUP then
    FMap.Camera.Up
  else if AAction.Details.Button = XCOM_BUTTON_WHEELDOWN then
    FMap.Camera.Down;
end;

procedure TXcomMapWidget.MouseRelease(AAction: TXcomAction);
var
  LX: Integer;
  LY: Integer;
begin
  inherited MouseRelease(AAction);
  // Camera::mouseRelease
  if (AAction.Details.Button = XCOM_BUTTON_LEFT) and (Option('battleEdgeScroll') = SCROLL_TRIGGER) then
  begin
    FScrollMouseX := 0;
    FScrollMouseY := 0;
    FScrollMouseTimer.Stop;
    FScrollTrigger := False;
    LX := AAction.XMouse;
    LY := AAction.YMouse;
    if ((LX < SCROLL_BORDER * AAction.XScale) and (LX > 0)) or (LX > (Width - SCROLL_BORDER) * AAction.XScale) or
      ((LY < SCROLL_BORDER * AAction.YScale) and (LY > 0)) or (LY > (Height - SCROLL_BORDER) * AAction.YScale) then
      // a cheap hack to avoid handling this event as a click on the map when the mouse is on the scroll-border
      AAction.Details.Button := 0;
  end;
end;

procedure TXcomMapWidget.MouseOver(AAction: TXcomAction);
begin
  inherited MouseOver(AAction);
  CameraMouseOver(AAction);
  FMouseX := Trunc(AAction.AbsoluteXMouse);
  FMouseY := Trunc(AAction.AbsoluteYMouse);
  FMap.SetSelectorFromScreen(FMouseX, FMouseY);
end;

procedure TXcomMapWidget.CameraMouseOver(AAction: TXcomAction);
var
  LX: Integer;
  LY: Integer;
  LSpeed: Integer;
  LScaleX: Double;
  LScaleY: Double;
begin
  if FMap.CursorType = CT_NONE then
    Exit;
  if (Option('battleEdgeScroll') <> SCROLL_AUTO) and (not FScrollTrigger) then
    Exit;
  LX := AAction.XMouse;
  LY := AAction.YMouse;
  LScaleX := AAction.XScale;
  LScaleY := AAction.YScale;
  LSpeed := Option('battleScrollSpeed');
  if (LX < SCROLL_BORDER * LScaleX) and (LX >= 0) then
  begin
    // left scroll; close to top or bottom, also scroll diagonally
    FScrollMouseX := LSpeed;
    if (LY < SCROLL_DIAGONAL_EDGE * LScaleY) and (LY >= 0) then
      FScrollMouseY := LSpeed div 2
    else if LY > (Height - SCROLL_DIAGONAL_EDGE) * LScaleY then
      FScrollMouseY := -LSpeed div 2
    else
      FScrollMouseY := 0;
  end
  else if LX > (Width - SCROLL_BORDER) * LScaleX then
  begin
    // right scroll
    FScrollMouseX := -LSpeed;
    if (LY <= SCROLL_DIAGONAL_EDGE * LScaleY) and (LY >= 0) then
      FScrollMouseY := LSpeed div 2
    else if LY > (Height - SCROLL_DIAGONAL_EDGE) * LScaleY then
      FScrollMouseY := -LSpeed div 2
    else
      FScrollMouseY := 0;
  end
  else if LX <> 0 then
    FScrollMouseX := 0;
  if (LY < SCROLL_BORDER * LScaleY) and (LY >= 0) then
  begin
    // up; close to the left or right edge, also scroll diagonally
    FScrollMouseY := LSpeed;
    if (LX < SCROLL_DIAGONAL_EDGE * LScaleX) and (LX >= 0) then
    begin
      FScrollMouseX := LSpeed;
      FScrollMouseY := FScrollMouseY div 2;
    end
    else if LX > (Width - SCROLL_DIAGONAL_EDGE) * LScaleX then
    begin
      FScrollMouseX := -LSpeed;
      FScrollMouseY := FScrollMouseY div 2;
    end;
  end
  else if LY > (Height - SCROLL_BORDER) * LScaleY then
  begin
    // down
    FScrollMouseY := -LSpeed;
    if (LX < SCROLL_DIAGONAL_EDGE * LScaleX) and (LX >= 0) then
    begin
      FScrollMouseX := LSpeed;
      FScrollMouseY := FScrollMouseY div 2;
    end
    else if LX > (Width - SCROLL_DIAGONAL_EDGE) * LScaleX then
    begin
      FScrollMouseX := -LSpeed;
      FScrollMouseY := FScrollMouseY div 2;
    end;
  end
  else if (LY <> 0) and (FScrollMouseX = 0) then
    FScrollMouseY := 0;
  if ((FScrollMouseX <> 0) or (FScrollMouseY <> 0)) and (not FScrollMouseTimer.IsRunning) and
    (not FScrollKeyTimer.IsRunning) then
    FScrollMouseTimer.Start
  else if (FScrollMouseX = 0) and (FScrollMouseY = 0) and FScrollMouseTimer.IsRunning then
    FScrollMouseTimer.Stop;
end;

procedure TXcomMapWidget.UpdateKeyTimer;
begin
  if ((FScrollKeyX <> 0) or (FScrollKeyY <> 0)) and (not FScrollKeyTimer.IsRunning) and
    (not FScrollMouseTimer.IsRunning) then
    FScrollKeyTimer.Start
  else if (FScrollKeyX = 0) and (FScrollKeyY = 0) and FScrollKeyTimer.IsRunning then
    FScrollKeyTimer.Stop;
end;

procedure TXcomMapWidget.KeyboardPress(AAction: TXcomAction);
var
  LKey: Integer;
  LSpeed: Integer;
begin
  inherited KeyboardPress(AAction);
  // Camera::keyboardPress
  if FMap.CursorType = CT_NONE then
    Exit;
  LKey := AAction.Details.Key;
  LSpeed := Option('battleScrollSpeed');
  if LKey = Option('keyBattleLeft') then
    FScrollKeyX := LSpeed
  else if LKey = Option('keyBattleRight') then
    FScrollKeyX := -LSpeed
  else if LKey = Option('keyBattleUp') then
    FScrollKeyY := LSpeed
  else if LKey = Option('keyBattleDown') then
    FScrollKeyY := -LSpeed;
  UpdateKeyTimer;
end;

procedure TXcomMapWidget.KeyboardRelease(AAction: TXcomAction);
var
  LKey: Integer;
begin
  inherited KeyboardRelease(AAction);
  // Camera::keyboardRelease
  if FMap.CursorType = CT_NONE then
    Exit;
  LKey := AAction.Details.Key;
  if (LKey = Option('keyBattleLeft')) or (LKey = Option('keyBattleRight')) then
    FScrollKeyX := 0
  else if (LKey = Option('keyBattleUp')) or (LKey = Option('keyBattleDown')) then
    FScrollKeyY := 0;
  UpdateKeyTimer;
end;

end.
