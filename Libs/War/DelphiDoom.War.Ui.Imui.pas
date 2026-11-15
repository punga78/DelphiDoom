{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the immediate mode interface                      }
{                                                                              }
{  Port of war1 (acoto87/war1), war_imui.c and war_ui.c (wui_changeCursorType, }
{  wui_updateUICursor), (c) 2019 Alejandro Coto Gutierrez, zlib License (see   }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.Imui;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Graphics.Types, DelphiDoom.War.Render.Types,
  DelphiDoom.War.Font.Types, DelphiDoom.War.Text.Types, DelphiDoom.War.Sprite.Sheet, DelphiDoom.War.Ui.Types,
  DelphiDoom.War.Ui.Intf, DelphiDoom.War.Ui.Canvas, DelphiDoom.War.Ui.SpriteCache, DelphiDoom.War.Ui.Sprite;

type
  /// <summary>
  ///   The immediate mode interface of the game: every frame the scene says what it draws and the buttons answer
  ///   whether they were clicked. imui_begin and imui_end are Begin and Finish. State kept between frames: the item
  ///   pressed with the left button (ActiveItem) and the sprite cache. The ids of the items are the FNV-1a of
  ///   the string, as in the original (two ids with the same hash are the same item)
  /// </summary>
  TWarImui = class
  strict private
    FCanvas: TWarUiCanvas;
    FInput: IWarUiInput;
    FSprites: IWarUiSprites;
    FCache: TWarUiSpriteCache;
    FAudio: IWarSceneAudio;
    FGameFrame: Integer;
    FMapActive: Boolean;
    FMapPanelX: Single;
    FMapPanelY: Single;
    FActiveItem: Cardinal;
    FHotItem: Cardinal;
    FIsMouseOverUi: Boolean;
    FCursorType: Integer;
    FHotkeysEnabled: Boolean;
    FShowTooltip: Boolean;
    FTooltipText: AnsiString;
    FTooltipHighlightIndex: Integer;
    FTooltipHighlightCount: Integer;
    FTooltipGold: Integer;
    FTooltipWood: Integer;
    function Sprite(AResourceIndex, AFrameIndex: Integer): IWarUiSprite;
    procedure RenderSprite(const ASprite: IWarUiSprite);
    function EvaluateButton(AItemId: Cardinal; AX, AY, AWidth, AHeight: Single; AHotKey: TWarKey): Boolean;
    procedure RenderTooltip;
    procedure RenderCursor;
  public
    /// <summary>The audio may be nil (no sound)</summary>
    constructor Create(const ACanvas: TWarUiCanvas; const AInput: IWarUiInput; const ASprites: IWarUiSprites;
      const AAudio: IWarSceneAudio);
    destructor Destroy; override;
    /// <summary>imui_hashCString: FNV-1a of the bytes of the id</summary>
    class function HashId(const AId: AnsiString): Cardinal; static;
    /// <summary>imui_begin: hot item, tooltip, cursor and hotkeys are reset; ActiveItem and the cache are kept</summary>
    procedure Start;
    /// <summary>imui_end: ActiveItem is cleared if the left button is up, then the tooltip and the cursor are drawn</summary>
    procedure Finish;
    /// <summary>imui_text</summary>
    procedure Text(const AId: AnsiString; const AArgs: TWarUiTextArgs);
    /// <summary>imui_rect</summary>
    procedure Rect(const AId: AnsiString; const AArgs: TWarUiRectArgs);
    /// <summary>imui_image: the frame 0 of the record</summary>
    procedure Image(const AId: AnsiString; const AArgs: TWarUiImageArgs);
    /// <summary>imui_image_frame; EWarException if the frame is not in the sprite (the original asserts)</summary>
    procedure ImageFrame(const AId: AnsiString; const AArgs: TWarUiImageArgs; AFrameIndex: Integer);
    /// <summary>imui_deferTooltip: the text is cut to 255 characters</summary>
    procedure DeferTooltip(const ATooltip: AnsiString; AHighlightIndex, AHighlightCount, AGold, AWood: Integer);
    /// <summary>imui_image_button: true the frame it is clicked</summary>
    function ImageButton(const AId: AnsiString; const AArgs: TWarUiImageButtonArgs): Boolean;
    /// <summary>imui_text_button: true the frame it is clicked</summary>
    function TextButton(const AId: AnsiString; const AArgs: TWarUiTextButtonArgs): Boolean;
    /// <summary>wui_changeCursorType: the record of the cursor to draw in Finish</summary>
    procedure ChangeCursorType(ACursorType: Integer);
    /// <summary>
    ///   The tooltip is drawn only with a map (context->map): the top left of its bottom panel. A scene has none
    /// </summary>
    procedure SetMapPanel(AActive: Boolean; AX, AY: Single);
    /// <summary>The frame of the game, for the eviction of the cache</summary>
    property GameFrame: Integer read FGameFrame write FGameFrame;
    property ActiveItem: Cardinal read FActiveItem;
    property HotItem: Cardinal read FHotItem;
    property IsMouseOverUi: Boolean read FIsMouseOverUi;
    property CursorType: Integer read FCursorType;
    /// <summary>False while the cheat panel is open: the keys do not click buttons</summary>
    property HotkeysEnabled: Boolean read FHotkeysEnabled write FHotkeysEnabled;
    property ShowTooltip: Boolean read FShowTooltip;
    property TooltipText: AnsiString read FTooltipText;
    property SpriteCache: TWarUiSpriteCache read FCache;
  end;

implementation

{ TWarImui }

constructor TWarImui.Create(const ACanvas: TWarUiCanvas; const AInput: IWarUiInput; const ASprites: IWarUiSprites;
  const AAudio: IWarSceneAudio);
begin
  inherited Create;
  FCanvas := ACanvas;
  FInput := AInput;
  FSprites := ASprites;
  FAudio := AAudio;
  FCache := TWarUiSpriteCache.Create(ASprites);
  FCursorType := WAR_CURSOR_ARROW;
  FHotkeysEnabled := True;
  FTooltipHighlightIndex := WAR_NO_HIGHLIGHT;
end;

destructor TWarImui.Destroy;
begin
  FCache.Free;
  inherited Destroy;
end;

class function TWarImui.HashId(const AId: AnsiString): Cardinal;
var
  LIndex: Integer;
begin
  Result := 2166136261;
  for LIndex := 1 to Length(AId) do
  begin
    Result := Result xor Byte(AId[LIndex]);
    Result := Result * 16777619;
  end;
end;

function TWarImui.Sprite(AResourceIndex, AFrameIndex: Integer): IWarUiSprite;
begin
  Result := FCache.GetOrCreate(AResourceIndex, AFrameIndex, FGameFrame);
end;

procedure TWarImui.RenderSprite(const ASprite: IWarUiSprite);
begin
  TWarUiSprite.Draw(FCanvas.Transform, ASprite);
end;

procedure TWarImui.Start;
begin
  FHotItem := 0;
  FIsMouseOverUi := False;
  FShowTooltip := False;
  FTooltipText := '';
  FTooltipHighlightIndex := WAR_NO_HIGHLIGHT;
  FTooltipHighlightCount := 0;
  FTooltipGold := 0;
  FTooltipWood := 0;
  FCursorType := WAR_CURSOR_ARROW;
  FHotkeysEnabled := True;
  // ActiveItem and the cache stay
end;

procedure TWarImui.SetMapPanel(AActive: Boolean; AX, AY: Single);
begin
  FMapActive := AActive;
  FMapPanelX := AX;
  FMapPanelY := AY;
end;

procedure TWarImui.ChangeCursorType(ACursorType: Integer);
begin
  FCursorType := ACursorType;
end;

procedure TWarImui.DeferTooltip(const ATooltip: AnsiString; AHighlightIndex, AHighlightCount, AGold, AWood: Integer);
begin
  FShowTooltip := True;
  FTooltipHighlightIndex := AHighlightIndex;
  FTooltipHighlightCount := AHighlightCount;
  FTooltipGold := AGold;
  FTooltipWood := AWood;
  FTooltipText := Copy(ATooltip, 1, WAR_IMUI_TOOLTIP_TEXT_MAX - 1);
end;

procedure TWarImui.RenderTooltip;
var
  LParams: TWarFontParams;
  LSprite: IWarUiSprite;
  LIconX: Single;
  LIconY: Single;
  LTextX: Single;
  LTextY: Single;
begin
  LParams := Default(TWarFontParams);
  LParams.FontSize := 6;
  LParams.LineHeight := 0;
  LParams.FontColor := WAR_FONT_NORMAL_COLOR;
  LParams.HighlightColor := WAR_FONT_HIGHLIGHT_COLOR;
  LParams.HighlightIndex := FTooltipHighlightIndex;
  LParams.HighlightCount := FTooltipHighlightCount;
  LParams.HorizontalAlign := wtaLeft;
  LParams.VerticalAlign := wtaTop;
  LParams.LineAlign := wtaLeft;
  LParams.Wrapping := wtwNone;
  LParams.Trimming := wttNone;
  LParams.FontData := FCanvas.FontData(0);
  // rendered at the position of the status bar of the map
  FCanvas.Transform.Save;
  FCanvas.RenderText(FTooltipText, 74, 193, 0, LParams, False);
  FCanvas.Transform.Restore;
  // the cost: the icon and the amount to the right of the text, the wood first
  if FTooltipWood > 0 then
  begin
    LSprite := Sprite(407, 0);
    if Assigned(LSprite) then
    begin
      LIconX := FMapPanelX + 163;
      LIconY := FMapPanelY + 3;
      LTextX := FMapPanelX + 179;
      LTextY := FMapPanelY + 5;
      FCanvas.Transform.Save;
      FCanvas.Transform.Translate(LIconX, LIconY);
      RenderSprite(LSprite);
      FCanvas.Transform.Restore;
      FCanvas.RenderText(AnsiString(IntToStr(FTooltipWood)), LTextX, LTextY, 0, LParams, False);
    end;
  end;
  if FTooltipGold > 0 then
  begin
    LSprite := Sprite(406, 0);
    if Assigned(LSprite) then
    begin
      LIconX := FMapPanelX + 200;
      LIconY := FMapPanelY + 5;
      LTextX := FMapPanelX + 218;
      LTextY := FMapPanelY + 5;
      FCanvas.Transform.Save;
      FCanvas.Transform.Translate(LIconX, LIconY);
      RenderSprite(LSprite);
      FCanvas.Transform.Restore;
      FCanvas.RenderText(AnsiString(IntToStr(FTooltipGold)), LTextX, LTextY, 0, LParams, False);
    end;
  end;
end;

procedure TWarImui.RenderCursor;
var
  LSprite: IWarUiSprite;
  LHotX: Integer;
  LHotY: Integer;
  LX: Single;
  LY: Single;
begin
  // the sprite is positioned so that the pointer tip is at the mouse
  LSprite := Sprite(FCursorType, 0);
  if not Assigned(LSprite) then
    Exit;
  FSprites.CursorHotspot(FCursorType, LHotX, LHotY);
  LX := FInput.PositionX - LHotX;
  LY := FInput.PositionY - LHotY;
  FCanvas.Transform.Save;
  FCanvas.Transform.Translate(LX, LY);
  RenderSprite(LSprite);
  FCanvas.Transform.Restore;
end;

procedure TWarImui.Finish;
begin
  if not FInput.IsButtonHeld(wmbLeft) then
    FActiveItem := 0;
  if FShowTooltip and (FTooltipText <> '') and FMapActive then
    RenderTooltip;
  RenderCursor;
end;

procedure TWarImui.Text(const AId: AnsiString; const AArgs: TWarUiTextArgs);
var
  LParams: TWarFontParams;
begin
  LParams := Default(TWarFontParams);
  LParams.FontSize := AArgs.FontSize;
  LParams.LineHeight := AArgs.LineHeight;
  LParams.FontColor := AArgs.FontColor;
  LParams.HighlightColor := AArgs.HighlightColor;
  LParams.HighlightIndex := AArgs.HighlightIndex;
  LParams.HighlightCount := AArgs.HighlightCount;
  LParams.BoundingsX := AArgs.BoundingsX;
  LParams.BoundingsY := AArgs.BoundingsY;
  LParams.HorizontalAlign := AArgs.HorizontalAlign;
  LParams.VerticalAlign := AArgs.VerticalAlign;
  LParams.LineAlign := AArgs.LineAlign;
  LParams.Wrapping := AArgs.Wrapping;
  LParams.Trimming := AArgs.Trimming;
  LParams.FontData := FCanvas.FontData(AArgs.FontIndex);
  FCanvas.Transform.Save;
  FCanvas.Transform.Translate(AArgs.PositionX, AArgs.PositionY);
  FCanvas.Transform.Scale(AArgs.ScaleX, AArgs.ScaleY);
  FCanvas.RenderText(AArgs.Text, 0, 0, AArgs.FontIndex, LParams, AArgs.Multiline);
  FCanvas.Transform.Restore;
end;

procedure TWarImui.Rect(const AId: AnsiString; const AArgs: TWarUiRectArgs);
var
  LRect: TWarRectF;
begin
  FCanvas.Transform.Save;
  FCanvas.Transform.Translate(AArgs.PositionX, AArgs.PositionY);
  FCanvas.Transform.Scale(AArgs.ScaleX, AArgs.ScaleY);
  LRect.X := 0;
  LRect.Y := 0;
  LRect.Width := AArgs.SizeX;
  LRect.Height := AArgs.SizeY;
  FCanvas.Transform.FillRect(LRect, AArgs.Color);
  FCanvas.Transform.Restore;
end;

procedure TWarImui.Image(const AId: AnsiString; const AArgs: TWarUiImageArgs);
var
  LSprite: IWarUiSprite;
begin
  LSprite := Sprite(AArgs.SpriteRef, 0);
  if not Assigned(LSprite) then
    Exit;
  FCanvas.Transform.Save;
  FCanvas.Transform.Translate(AArgs.PositionX, AArgs.PositionY);
  FCanvas.Transform.Scale(AArgs.ScaleX, AArgs.ScaleY);
  RenderSprite(LSprite);
  FCanvas.Transform.Restore;
end;

procedure TWarImui.ImageFrame(const AId: AnsiString; const AArgs: TWarUiImageArgs; AFrameIndex: Integer);
var
  LSprite: IWarUiSprite;
  LFrame: TWarSpriteFrame;
  LOffsetX: Single;
  LOffsetY: Single;
begin
  LSprite := Sprite(AArgs.SpriteRef, AFrameIndex);
  if not Assigned(LSprite) then
    Exit;
  LFrame := LSprite.GetFrame(AFrameIndex);
  LOffsetX := -LFrame.Dx;
  LOffsetY := -LFrame.Dy;
  FCanvas.Transform.Save;
  FCanvas.Transform.Translate(LOffsetX, LOffsetY);
  FCanvas.Transform.Translate(AArgs.PositionX, AArgs.PositionY);
  FCanvas.Transform.Scale(AArgs.ScaleX, AArgs.ScaleY);
  RenderSprite(LSprite);
  FCanvas.Transform.Restore;
end;

function TWarImui.EvaluateButton(AItemId: Cardinal; AX, AY, AWidth, AHeight: Single; AHotKey: TWarKey): Boolean;
var
  LRight: Single;
  LBottom: Single;
  LHovered: Boolean;
begin
  Result := False;
  LRight := AX + AWidth;
  LBottom := AY + AHeight;
  // rect_containsf: the edges are inside
  LHovered := (FInput.PositionX >= AX) and (FInput.PositionX <= LRight) and (FInput.PositionY >= AY)
    and (FInput.PositionY <= LBottom);
  if LHovered then
  begin
    FHotItem := AItemId;
    FIsMouseOverUi := True;
    if FInput.IsButtonJustPressed(wmbLeft) then
      FActiveItem := AItemId;
  end;
  // the hotkey fires when the key is released, wherever the mouse is
  if FHotkeysEnabled and (AHotKey <> wkNone) and FInput.IsKeyJustReleased(AHotKey) then
    Exit(True);
  // the click fires when the button is released over the item that was pressed
  if FInput.IsButtonJustReleased(wmbLeft) and (FActiveItem = AItemId) then
  begin
    if LHovered then
    begin
      if Assigned(FAudio) then
        FAudio.Play(WAR_AUDIO_UI_CLICK, False);
      Exit(True);
    end;
  end;
end;

function TWarImui.ImageButton(const AId: AnsiString; const AArgs: TWarUiImageButtonArgs): Boolean;
var
  LItemId: Cardinal;
  LNormal: IWarUiSprite;
  LPressed: IWarUiSprite;
  LForeground: IWarUiSprite;
  LWidth: Single;
  LHeight: Single;
  LX: Single;
  LY: Single;
  LActive: Boolean;
  LBackground: IWarUiSprite;
  LOffsetX: Single;
  LOffsetY: Single;
begin
  if not AArgs.Interactive then
    Exit(False);
  LItemId := HashId(AId);
  LNormal := Sprite(AArgs.BackgroundNormal, 0);
  LPressed := Sprite(AArgs.BackgroundPressed, 0);
  LForeground := Sprite(AArgs.Foreground, AArgs.ForegroundFrameIndex);
  LWidth := 16;
  LHeight := 16;
  if Assigned(LNormal) then
  begin
    if LNormal.FrameWidth > 0 then
      LWidth := LNormal.FrameWidth;
    if LNormal.FrameHeight > 0 then
      LHeight := LNormal.FrameHeight;
  end;
  LX := AArgs.PositionX * AArgs.ScaleX;
  LY := AArgs.PositionY * AArgs.ScaleY;
  LWidth := LWidth * AArgs.ScaleX;
  LHeight := LHeight * AArgs.ScaleY;
  Result := EvaluateButton(LItemId, LX, LY, LWidth, LHeight, AArgs.HotKey);
  LActive := (FActiveItem = LItemId) and FInput.IsButtonHeld(wmbLeft) and (FHotItem = LItemId);
  if (FHotItem = LItemId) and (Length(AArgs.Tooltip) > 0) then
    DeferTooltip(AArgs.Tooltip, AArgs.TooltipHighlightIndex, AArgs.TooltipHighlightCount, AArgs.Gold, AArgs.Wood);
  FCanvas.Transform.Save;
  FCanvas.Transform.Translate(AArgs.PositionX, AArgs.PositionY);
  FCanvas.Transform.Scale(AArgs.ScaleX, AArgs.ScaleY);
  if LActive then
    LBackground := LPressed
  else
    LBackground := LNormal;
  if Assigned(LBackground) then
    RenderSprite(LBackground);
  // the foreground icon, centered in the background
  if Assigned(LForeground) and (LForeground.FrameCount > 0) then
  begin
    LOffsetX := 0;
    LOffsetY := 0;
    if Assigned(LNormal) then
    begin
      LOffsetX := LNormal.FrameWidth - LForeground.FrameWidth;
      LOffsetY := LNormal.FrameHeight - LForeground.FrameHeight;
    end
    else
    begin
      LOffsetX := -LForeground.FrameWidth;
      LOffsetY := -LForeground.FrameHeight;
    end;
    LOffsetX := LOffsetX * 0.5;
    LOffsetY := LOffsetY * 0.5;
    if LActive then
      LOffsetY := LOffsetY + 1;
    FCanvas.Transform.Translate(LOffsetX, LOffsetY);
    RenderSprite(LForeground);
  end;
  FCanvas.Transform.Restore;
end;

function TWarImui.TextButton(const AId: AnsiString; const AArgs: TWarUiTextButtonArgs): Boolean;
var
  LItemId: Cardinal;
  LNormal: IWarUiSprite;
  LPressed: IWarUiSprite;
  LWidth: Single;
  LHeight: Single;
  LX: Single;
  LY: Single;
  LScaledWidth: Single;
  LScaledHeight: Single;
  LActive: Boolean;
  LHot: Boolean;
  LBackground: IWarUiSprite;
  LParams: TWarFontParams;
begin
  if not AArgs.Interactive then
    Exit(False);
  LItemId := HashId(AId);
  LNormal := Sprite(AArgs.BackgroundNormal, 0);
  LPressed := Sprite(AArgs.BackgroundPressed, 0);
  LWidth := 64;
  LHeight := 16;
  if Assigned(LNormal) then
  begin
    if LNormal.FrameWidth > 0 then
      LWidth := LNormal.FrameWidth;
    if LNormal.FrameHeight > 0 then
      LHeight := LNormal.FrameHeight;
  end;
  LX := AArgs.PositionX * AArgs.ScaleX;
  LY := AArgs.PositionY * AArgs.ScaleY;
  LScaledWidth := LWidth * AArgs.ScaleX;
  LScaledHeight := LHeight * AArgs.ScaleY;
  Result := EvaluateButton(LItemId, LX, LY, LScaledWidth, LScaledHeight, AArgs.HotKey);
  LActive := (FActiveItem = LItemId) and FInput.IsButtonHeld(wmbLeft) and (FHotItem = LItemId);
  LHot := FHotItem = LItemId;
  if LHot and (Length(AArgs.Tooltip) > 0) then
    DeferTooltip(AArgs.Tooltip, AArgs.TooltipHighlightIndex, AArgs.TooltipHighlightCount, AArgs.Gold, AArgs.Wood);
  FCanvas.Transform.Save;
  FCanvas.Transform.Translate(AArgs.PositionX, AArgs.PositionY);
  FCanvas.Transform.Scale(AArgs.ScaleX, AArgs.ScaleY);
  if LActive then
    LBackground := LPressed
  else
    LBackground := LNormal;
  if Assigned(LBackground) then
    RenderSprite(LBackground);
  if Length(AArgs.Text) > 0 then
  begin
    LParams := Default(TWarFontParams);
    LParams.FontSize := AArgs.FontSize;
    LParams.LineHeight := AArgs.LineHeight;
    LParams.FontColor := AArgs.FontColor;
    LParams.HighlightColor := AArgs.HighlightColor;
    // the whole label is highlighted when the mouse is over the button
    if LHot then
      LParams.HighlightIndex := WAR_ALL_HIGHLIGHT
    else
      LParams.HighlightIndex := AArgs.HighlightIndex;
    LParams.HighlightCount := AArgs.HighlightCount;
    LParams.BoundingsX := LWidth;
    LParams.BoundingsY := LHeight;
    LParams.HorizontalAlign := AArgs.HorizontalAlign;
    LParams.VerticalAlign := AArgs.VerticalAlign;
    LParams.LineAlign := AArgs.LineAlign;
    LParams.Wrapping := AArgs.Wrapping;
    LParams.Trimming := AArgs.Trimming;
    LParams.FontData := FCanvas.FontData(AArgs.FontIndex);
    FCanvas.RenderText(AArgs.Text, 0, 0, AArgs.FontIndex, LParams, False);
  end;
  FCanvas.Transform.Restore;
end;

end.
