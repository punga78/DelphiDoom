{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the map seen from above of     }
{  the minimap screen (MiniMapView)                                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.MiniMapView;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomBattle.SavedBattleGame,
  DelphiDoom.XcomBattlescape.Camera;

type
  /// <summary>The settings of the scrolling by dragging of the minimap (Options::battleDragScroll...)</summary>
  TXcomMiniMapDragOptions = record
    /// <summary>battleDragScrollButton: the mouse button that drags the map</summary>
    Button: Integer;
    /// <summary>battleDragScrollInvert</summary>
    Invert: Boolean;
    /// <summary>dragScrollTimeTolerance: a shorter drag that did not move is a click (milliseconds)</summary>
    TimeTolerance: Integer;
    /// <summary>dragScrollPixelTolerance: a drag longer than this is never a click</summary>
    PixelTolerance: Integer;
  end;

  /// <summary>
  ///   The map of the battle seen from above, four pixels a tile, centered where the camera is: the parts of the
  ///   tiles with the sprites of SCANG.DAT, the units and the items that blink in three frames, the cross in the
  ///   middle. A left click centers the camera, a right click asks to close, the drag button scrolls. Nothing is
  ///   owned: the set, the camera and the battle are the caller's.
  ///   Unlike the C++ the drag does not hold the mouse cursor still (no warp of the mouse) and reads the movement
  ///   from the positions of the events; the recovery of a lost release of the button is not ported
  /// </summary>
  TXcomMiniMapView = class(TXcomInteractiveSurface)
  strict private
    FSet: TXcomSurfaceSet;
    FCamera: TXcomCamera;
    FBattle: TXcomSavedBattleGame;
    FClock: IXcomClock;
    FDrag: TXcomMiniMapDragOptions;
    FRedColor: Integer;
    FFrame: Integer;
    FOnClose: TXcomActionHandler;
    FIsMouseScrolling: Boolean;
    FIsMouseScrolled: Boolean;
    FLastMouseX: Integer;
    FLastMouseY: Integer;
    FMouseScrollX: Integer;
    FMouseScrollY: Integer;
    FPositionBeforeMouseScrolling: TXcomPosition;
    FMouseScrollingStartTime: Cardinal;
    FTotalMouseMoveX: Integer;
    FTotalMouseMoveY: Integer;
    FMouseMovedOverThreshold: Boolean;
    function WasClick: Boolean;
  protected
    procedure MousePress(AAction: TXcomAction); override;
    procedure MouseClick(AAction: TXcomAction); override;
    procedure MouseOver(AAction: TXcomAction); override;
    procedure MouseIn(AAction: TXcomAction); override;
  public
    /// <param name="ASet">SCANG.DAT; nil: nothing is drawn</param>
    /// <param name="ACamera">The camera of the battlescape: the minimap moves it</param>
    /// <param name="AClock">The time of the drag</param>
    /// <param name="ARedColor">Pathfinding::red: the color group of a big neutral unit</param>
    constructor Create(AWidth, AHeight, AX, AY: Integer; ASet: TXcomSurfaceSet; ACamera: TXcomCamera;
      ABattle: TXcomSavedBattleGame; const AClock: IXcomClock; const ADrag: TXcomMiniMapDragOptions;
      ARedColor: Integer);
    procedure Draw; override;
    /// <summary>up: the level above; gives the new level of the camera</summary>
    function Up: Integer;
    /// <summary>down: the level below; gives the new level of the camera</summary>
    function Down: Integer;
    /// <summary>animate: the next of the three frames of the blinking</summary>
    procedure Animate;
    /// <summary>The frame of the blinking, 0..2</summary>
    property Frame: Integer read FFrame;
    /// <summary>MiniMapState::btnOkClick, called by a right click on the map</summary>
    property OnClose: TXcomActionHandler read FOnClose write FOnClose;
  end;

implementation

uses
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Shade, DelphiDoom.XcomSurface.Gfx,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomMod.MapData, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.Types;

const
  CELL_WIDTH = 4;
  CELL_HEIGHT = 4;
  MAX_FRAME = 2;
  // the sprites of the parts of the tiles come after the ones of the units and of the items
  TERRAIN_FRAMES = 35;
  ITEM_FRAME = 9;
  UNDISCOVERED_SHADE = 16;
  DARKEST_SHADE = 7;
  DISCOVERED_PART = 2;

constructor TXcomMiniMapView.Create(AWidth, AHeight, AX, AY: Integer; ASet: TXcomSurfaceSet; ACamera: TXcomCamera;
  ABattle: TXcomSavedBattleGame; const AClock: IXcomClock; const ADrag: TXcomMiniMapDragOptions;
  ARedColor: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FSet := ASet;
  FCamera := ACamera;
  FBattle := ABattle;
  FClock := AClock;
  FDrag := ADrag;
  FRedColor := ARedColor;
end;

procedure TXcomMiniMapView.Draw;
var
  LStartX, LStartY, LLevel, LMapX, LMapY, LX, LY, LPart, LShade, LFrame, LSize, LCenterX, LCenterY: Integer;
  LTile: TXcomTile;
  LData: TXcomMapData;
  LUnit: TXcomBattleUnit;
  LSprite: TXcomSurface;
  LColor: Byte;
begin
  LStartX := FCamera.CenterPosition.X - ((Width div CELL_WIDTH) div 2);
  LStartY := FCamera.CenterPosition.Y - ((Height div CELL_HEIGHT) div 2);
  inherited Draw;
  if not Assigned(FSet) then
    Exit;
  DrawRect(0, 0, Width, Height, 15);
  for LLevel := 0 to FCamera.CenterPosition.Z do
  begin
    LMapY := LStartY;
    LY := Y;
    while LY < Height + Y do
    begin
      LMapX := LStartX;
      LX := X;
      while LX < Width + X do
      begin
        LTile := FBattle.TileAt(TXcomPosition.Make(LMapX, LMapY, LLevel));
        if Assigned(LTile) then
        begin
          for LPart := XCOM_PART_FLOOR to XCOM_PART_OBJECT do
          begin
            LData := LTile.MapData[LPart];
            if Assigned(LData) and (LData.MiniMapIndex <> 0) then
            begin
              LSprite := FSet.GetFrame(LData.MiniMapIndex + TERRAIN_FRAMES);
              if Assigned(LSprite) then
              begin
                LShade := UNDISCOVERED_SHADE;
                if LTile.IsDiscovered(DISCOVERED_PART) then
                begin
                  LShade := LTile.GetShade;
                  // vanilla
                  if LShade > DARKEST_SHADE then
                    LShade := DARKEST_SHADE;
                end;
                TXcomSurfaceShader.Blit(LSprite, Self, LX, LY, LShade);
              end;
            end;
          end;
          // alive units
          LUnit := LTile.CurrentUnit;
          if Assigned(LUnit) and LUnit.GetVisible then
          begin
            LSize := LUnit.Armor.Size;
            LFrame := LUnit.GetMiniMapSpriteIndex + (LTile.Position.Y - LUnit.Position.Y) * LSize +
              LTile.Position.X - LUnit.Position.X + FFrame * LSize * LSize;
            LSprite := FSet.GetFrame(LFrame);
            if Assigned(LSprite) then
            begin
              if (LSize > 1) and (LUnit.Faction = FACTION_NEUTRAL) then
                TXcomSurfaceShader.Blit(LSprite, Self, LX, LY, 0, False, FRedColor)
              else
                TXcomSurfaceShader.Blit(LSprite, Self, LX, LY, 0);
            end;
          end;
          // perhaps (at least one) item on this tile?
          if LTile.IsDiscovered(DISCOVERED_PART) and (LTile.Inventory.Count > 0) then
          begin
            LSprite := FSet.GetFrame(ITEM_FRAME + FFrame);
            if Assigned(LSprite) then
              TXcomSurfaceShader.Blit(LSprite, Self, LX, LY, 0);
          end;
        end;
        Inc(LMapX);
        Inc(LX, CELL_WIDTH);
      end;
      Inc(LMapY);
      Inc(LY, CELL_HEIGHT);
    end;
  end;
  // the cross that marks the center
  LCenterX := Width div 2 - 1;
  LCenterY := Height div 2 - 1;
  LColor := Byte(1 + FFrame * 3);
  TXcomGfx.DrawLine(Self, LCenterX - CELL_WIDTH, LCenterY - CELL_HEIGHT, LCenterX - CELL_WIDTH div 2,
    LCenterY - CELL_HEIGHT div 2, LColor);
  TXcomGfx.DrawLine(Self, LCenterX + CELL_WIDTH div 2, LCenterY - CELL_HEIGHT div 2, LCenterX + CELL_WIDTH,
    LCenterY - CELL_HEIGHT, LColor);
  TXcomGfx.DrawLine(Self, LCenterX - CELL_WIDTH, LCenterY + CELL_HEIGHT, LCenterX - CELL_WIDTH div 2,
    LCenterY + CELL_HEIGHT div 2, LColor);
  TXcomGfx.DrawLine(Self, LCenterX + CELL_WIDTH, LCenterY + CELL_HEIGHT, LCenterX + CELL_WIDTH div 2,
    LCenterY + CELL_HEIGHT div 2, LColor);
end;

function TXcomMiniMapView.Up: Integer;
begin
  FCamera.SetViewLevel(FCamera.ViewLevel + 1);
  Redraw := True;
  Result := FCamera.ViewLevel;
end;

function TXcomMiniMapView.Down: Integer;
begin
  FCamera.SetViewLevel(FCamera.ViewLevel - 1);
  Redraw := True;
  Result := FCamera.ViewLevel;
end;

procedure TXcomMiniMapView.Animate;
begin
  Inc(FFrame);
  if FFrame > MAX_FRAME then
    FFrame := 0;
  Redraw := True;
end;

function TXcomMiniMapView.WasClick: Boolean;
begin
  // the scrolling was too short in time and in space: it was a click
  Result := (not FMouseMovedOverThreshold) and
    (Integer(FClock.Ticks - FMouseScrollingStartTime) <= FDrag.TimeTolerance);
end;

procedure TXcomMiniMapView.MousePress(AAction: TXcomAction);
begin
  inherited MousePress(AAction);
  if AAction.Details.Button = FDrag.Button then
  begin
    FIsMouseScrolling := True;
    FIsMouseScrolled := False;
    FLastMouseX := AAction.Details.X;
    FLastMouseY := AAction.Details.Y;
    FPositionBeforeMouseScrolling := FCamera.CenterPosition;
    FMouseScrollX := 0;
    FMouseScrollY := 0;
    FTotalMouseMoveX := 0;
    FTotalMouseMoveY := 0;
    FMouseMovedOverThreshold := False;
    FMouseScrollingStartTime := FClock.Ticks;
  end;
end;

procedure TXcomMiniMapView.MouseClick(AAction: TXcomAction);
var
  LOrigX, LOrigY, LOffsetX, LOffsetY: Integer;
begin
  inherited MouseClick(AAction);
  // drag-scroll release: release mouse-scroll-mode
  if FIsMouseScrolling then
  begin
    // while scrolling, other buttons are ineffective
    if AAction.Details.Button <> FDrag.Button then
      Exit;
    FIsMouseScrolling := False;
    if WasClick then
    begin
      FIsMouseScrolled := False;
      FCamera.CenterOnPosition(FPositionBeforeMouseScrolling);
      Redraw := True;
    end;
    if FIsMouseScrolled then
      Exit;
  end;
  if (AAction.Details.Button = XCOM_BUTTON_RIGHT) and Assigned(FOnClose) then
    FOnClose(AAction);
  if AAction.Details.Button = XCOM_BUTTON_LEFT then
  begin
    LOrigX := Trunc(AAction.RelativeXMouse / AAction.XScale);
    LOrigY := Trunc(AAction.RelativeYMouse / AAction.YScale);
    // the offset (in cells) of the click relative to the center of the screen
    LOffsetX := (LOrigX div CELL_WIDTH) - ((Width div 2) div CELL_WIDTH);
    LOffsetY := (LOrigY div CELL_HEIGHT) - ((Height div 2) div CELL_HEIGHT);
    FCamera.CenterOnPosition(TXcomPosition.Make(FCamera.CenterPosition.X + LOffsetX,
      FCamera.CenterPosition.Y + LOffsetY, FCamera.ViewLevel));
    Redraw := True;
  end;
end;

procedure TXcomMiniMapView.MouseOver(AAction: TXcomAction);
var
  LMoveX, LMoveY, LScrollX, LScrollY, LNewX, LNewY: Integer;
begin
  inherited MouseOver(AAction);
  if not (FIsMouseScrolling and (AAction.Details.Kind = ekMouseMotion)) then
    Exit;
  FIsMouseScrolled := True;
  // motion.xrel and yrel: the events carry only the position
  LMoveX := AAction.Details.X - FLastMouseX;
  LMoveY := AAction.Details.Y - FLastMouseY;
  FLastMouseX := AAction.Details.X;
  FLastMouseY := AAction.Details.Y;
  Inc(FTotalMouseMoveX, LMoveX);
  Inc(FTotalMouseMoveY, LMoveY);
  if not FMouseMovedOverThreshold then
    FMouseMovedOverThreshold := (Abs(FTotalMouseMoveX) > FDrag.PixelTolerance) or
      (Abs(FTotalMouseMoveY) > FDrag.PixelTolerance);
  if FDrag.Invert then
  begin
    LScrollX := LMoveX;
    LScrollY := LMoveY;
  end
  else
  begin
    LScrollX := -LMoveX;
    LScrollY := -LMoveY;
  end;
  Inc(FMouseScrollX, LScrollX);
  Inc(FMouseScrollY, LScrollY);
  LNewX := FPositionBeforeMouseScrolling.X + Trunc(FMouseScrollX / AAction.XScale / 4);
  LNewY := FPositionBeforeMouseScrolling.Y + Trunc(FMouseScrollY / AAction.YScale / 4);
  // keep the limits
  if (LNewX < -1) or (FBattle.MapSizeX < LNewX) then
  begin
    Dec(FMouseScrollX, LScrollX);
    LNewX := FPositionBeforeMouseScrolling.X + FMouseScrollX div 4;
  end;
  if (LNewY < -1) or (FBattle.MapSizeY < LNewY) then
  begin
    Dec(FMouseScrollY, LScrollY);
    LNewY := FPositionBeforeMouseScrolling.Y + FMouseScrollY div 4;
  end;
  FCamera.CenterOnPosition(TXcomPosition.Make(LNewX, LNewY, FCamera.ViewLevel));
  Redraw := True;
end;

procedure TXcomMiniMapView.MouseIn(AAction: TXcomAction);
begin
  inherited MouseIn(AAction);
  FIsMouseScrolling := False;
  SetButtonPressed(XCOM_BUTTON_RIGHT, False);
end;

end.
