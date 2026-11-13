{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - the keys of an item and the mouse capture         }
{                                                                              }
{  Item_HandleKey, Item_StartCapture, Item_StopCapture, Item_Action,           }
{  Item_OwnerDraw_HandleKey, Scroll_ListBox_AutoFunc, Scroll_ListBox_          }
{  ThumbFunc and Menu_ScrollFeeder of ui_shared.c (Quake III Arena, id         }
{  Software, GPL v2 or later). Based on the Quake III Arena GPL Source Code    }
{  (id Software).                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Display.ItemKeys;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Gui.Types, DelphiDoom.Gui.Menu, DelphiDoom.Gui.Display.State, DelphiDoom.Gui.Display.ListBox,
  DelphiDoom.Gui.Display.Slider, DelphiDoom.Gui.Display.CvarItems;

type
  /// <summary>What a key does to the item that has the focus, and the capture of the mouse by a scroll bar or a slider</summary>
  TGuiItemKeys = class
  strict private
    FState: TGuiDisplayState;
    FListBoxes: TGuiListBoxLogic;
    FSliders: TGuiSliderLogic;
    FCvarItems: TGuiCvarItems;
    procedure DragListBoxThumb;
    procedure AutoScrollListBox;
  public
    /// <summary>The parts are not owned</summary>
    constructor Create(const AState: TGuiDisplayState; const AListBoxes: TGuiListBoxLogic;
      const ASliders: TGuiSliderLogic; const ACvarItems: TGuiCvarItems);
    /// <summary>
    ///   Item_StartCapture: a click on a scroll arrow (auto scroll) or the thumb of a list box or slider
    ///   captures the mouse. The original also lets an edit field go through the list box code (it has no
    ///   <c>break</c>) and reads its data as a list box's: not ported, an edit field captures nothing.
    /// </summary>
    procedure StartCapture(const AItem: TGuiItem; const AKey: Integer);
    /// <summary>
    ///   Item_HandleKey: a pending capture ends first; then the item gets the key by its type (list box,
    ///   yes/no, multi, owner draw, slider). Only a key that goes down is used. The bind item is not ported
    ///   (false), the edit fields are the menu's.
    /// </summary>
    function HandleKey(const AItem: TGuiItem; const AKey: Integer; const ADown: Boolean): Boolean;
    /// <summary>Item_Action: runs the <c>action</c> script</summary>
    procedure Action(const AItem: TGuiItem);
    /// <summary>
    ///   The call of <c>captureFunc( captureData )</c> that Menu_PaintAll makes every frame: scrolls a list box
    ///   while an arrow is held or follows the drag of a thumb. Nothing without a capture.
    /// </summary>
    procedure RunCapture;
    /// <summary>Menu_ScrollFeeder: one line up or down in the list box of a feeder</summary>
    procedure ScrollFeeder(const AMenu: TGuiMenu; const AFeeder: Single; const ADown: Boolean);
  end;

implementation

uses
  DelphiDoom.Gui.Keys, DelphiDoom.Gui.Display.FloatMask;

constructor TGuiItemKeys.Create(const AState: TGuiDisplayState; const AListBoxes: TGuiListBoxLogic;
  const ASliders: TGuiSliderLogic; const ACvarItems: TGuiCvarItems);
begin
  inherited Create;
  FState := AState;
  FListBoxes := AListBoxes;
  FSliders := ASliders;
  FCvarItems := ACvarItems;
end;

procedure TGuiItemKeys.StartCapture(const AItem: TGuiItem; const AKey: Integer);
var
  LFlags: Integer;
begin
  case AItem.ItemType of
    ITEM_TYPE_LISTBOX:
      begin
        LFlags := FListBoxes.OverLB(AItem, FState.CursorX, FState.CursorY);
        if (LFlags and (WINDOW_LB_LEFTARROW or WINDOW_LB_RIGHTARROW)) <> 0 then
        begin
          FState.ScrollInfo.NextScrollTime := FState.Input.RealTime + GUI_SCROLL_TIME_START;
          FState.ScrollInfo.NextAdjustTime := FState.Input.RealTime + GUI_SCROLL_TIME_ADJUST;
          FState.ScrollInfo.AdjustValue := GUI_SCROLL_TIME_START;
          FState.ScrollInfo.ScrollKey := AKey;
          FState.ScrollInfo.ScrollDir := (LFlags and WINDOW_LB_LEFTARROW) <> 0;
          FState.ScrollInfo.Item := AItem;
          FState.CaptureKind := gckListBoxAuto;
          FState.ItemCapture := AItem;
        end
        else if (LFlags and WINDOW_LB_THUMB) <> 0 then
        begin
          FState.ScrollInfo.ScrollKey := AKey;
          FState.ScrollInfo.Item := AItem;
          FState.ScrollInfo.XStart := FState.Input.CursorX;
          FState.ScrollInfo.YStart := FState.Input.CursorY;
          FState.CaptureKind := gckListBoxThumb;
          FState.ItemCapture := AItem;
        end;
      end;
    ITEM_TYPE_SLIDER:
      begin
        LFlags := FSliders.OverSlider(AItem, FState.CursorX, FState.CursorY);
        if (LFlags and WINDOW_LB_THUMB) <> 0 then
        begin
          FState.ScrollInfo.ScrollKey := AKey;
          FState.ScrollInfo.Item := AItem;
          FState.ScrollInfo.XStart := FState.Input.CursorX;
          FState.ScrollInfo.YStart := FState.Input.CursorY;
          FState.CaptureKind := gckSliderThumb;
          FState.ItemCapture := AItem;
        end;
      end;
  end;
end;

function TGuiItemKeys.HandleKey(const AItem: TGuiItem; const AKey: Integer; const ADown: Boolean): Boolean;
begin
  if Assigned(FState.ItemCapture) then
  begin
    // Item_StopCapture does nothing
    FState.ItemCapture := nil;
    FState.CaptureKind := gckNone;
  end
  else if ADown and ((AKey = K_MOUSE1) or (AKey = K_MOUSE2) or (AKey = K_MOUSE3)) then
    StartCapture(AItem, AKey);
  if not ADown then
    Exit(False);
  case AItem.ItemType of
    ITEM_TYPE_LISTBOX:
      Result := FListBoxes.HandleKey(AItem, AKey, ADown, False);
    ITEM_TYPE_YESNO:
      Result := FCvarItems.YesNoHandleKey(AItem, AKey);
    ITEM_TYPE_MULTI:
      Result := FCvarItems.MultiHandleKey(AItem, AKey);
    ITEM_TYPE_OWNERDRAW:
      Result := FState.Input.OwnerDrawHandleKey(AItem.Window.OwnerDraw, AItem.Window.OwnerDrawFlags, AItem.Special,
        AKey);
    ITEM_TYPE_SLIDER:
      Result := FSliders.HandleKey(AItem, AKey, ADown);
  else
    Result := False;
  end;
end;

procedure TGuiItemKeys.Action(const AItem: TGuiItem);
begin
  if Assigned(AItem) then
    FState.Runner.Run(AItem, AItem.Action);
end;

procedure TGuiItemKeys.AutoScrollListBox;
begin
  if FState.Input.RealTime > FState.ScrollInfo.NextScrollTime then
  begin
    // need to scroll which is done by simulating a click to the item
    FListBoxes.HandleKey(FState.ScrollInfo.Item, FState.ScrollInfo.ScrollKey, True, False);
    FState.ScrollInfo.NextScrollTime := FState.Input.RealTime + FState.ScrollInfo.AdjustValue;
  end;
  if FState.Input.RealTime > FState.ScrollInfo.NextAdjustTime then
  begin
    FState.ScrollInfo.NextAdjustTime := FState.Input.RealTime + GUI_SCROLL_TIME_ADJUST;
    if FState.ScrollInfo.AdjustValue > GUI_SCROLL_TIME_FLOOR then
      FState.ScrollInfo.AdjustValue := FState.ScrollInfo.AdjustValue - GUI_SCROLL_TIME_ADJUSTOFFSET;
  end;
end;

procedure TGuiItemKeys.DragListBoxThumb;
var
  LItem: TGuiItem;
  LRect: TGuiRect;
  LPos, LMax: Integer;
  LNumerator: Double;
  LMask: IInterface;
begin
  LMask := TGuiFloatMask.Enter;
  LItem := FState.ScrollInfo.Item;
  if (LItem.Window.Flags and WINDOW_HORIZONTAL) <> 0 then
  begin
    if FState.Input.CursorX = FState.ScrollInfo.XStart then
      Exit;
    LRect.X := Double(LItem.Window.Rect.X) + GUI_SCROLLBAR_SIZE + 1;
    LRect.Y := Double(LItem.Window.Rect.Y + LItem.Window.Rect.H) - GUI_SCROLLBAR_SIZE - 1;
    LRect.H := GUI_SCROLLBAR_SIZE;
    LRect.W := Double(LItem.Window.Rect.W) - GUI_SCROLLBAR_SIZE * 2 - 2;
    LMax := FListBoxes.MaxScroll(LItem);
    LNumerator := (Double(FState.Input.CursorX) - LRect.X - GUI_SCROLLBAR_SIZE / 2) * LMax;
    LPos := TGuiDisplayState.FloatToInt(LNumerator / (Double(LRect.W) - GUI_SCROLLBAR_SIZE));
    if LPos < 0 then
      LPos := 0
    else if LPos > LMax then
      LPos := LMax;
    LItem.ListBox.StartPos := LPos;
    FState.ScrollInfo.XStart := FState.Input.CursorX;
  end
  else if FState.Input.CursorY <> FState.ScrollInfo.YStart then
  begin
    LRect.X := Double(LItem.Window.Rect.X + LItem.Window.Rect.W) - GUI_SCROLLBAR_SIZE - 1;
    LRect.Y := Double(LItem.Window.Rect.Y) + GUI_SCROLLBAR_SIZE + 1;
    LRect.H := Double(LItem.Window.Rect.H) - GUI_SCROLLBAR_SIZE * 2 - 2;
    LRect.W := GUI_SCROLLBAR_SIZE;
    LMax := FListBoxes.MaxScroll(LItem);
    LNumerator := (Double(FState.Input.CursorY) - LRect.Y - GUI_SCROLLBAR_SIZE / 2) * LMax;
    LPos := TGuiDisplayState.FloatToInt(LNumerator / (Double(LRect.H) - GUI_SCROLLBAR_SIZE));
    if LPos < 0 then
      LPos := 0
    else if LPos > LMax then
      LPos := LMax;
    LItem.ListBox.StartPos := LPos;
    FState.ScrollInfo.YStart := FState.Input.CursorY;
  end;
  AutoScrollListBox;
end;

procedure TGuiItemKeys.RunCapture;
begin
  case FState.CaptureKind of
    gckListBoxAuto:
      AutoScrollListBox;
    gckListBoxThumb:
      DragListBoxThumb;
    gckSliderThumb:
      FSliders.DragThumb;
  end;
end;

procedure TGuiItemKeys.ScrollFeeder(const AMenu: TGuiMenu; const AFeeder: Single; const ADown: Boolean);
var
  LIndex, LKey: Integer;
begin
  if not Assigned(AMenu) then
    Exit;
  for LIndex := 0 to AMenu.Items.Count - 1 do
    if AMenu.Items[LIndex].Special = AFeeder then
    begin
      if ADown then
        LKey := K_DOWNARROW
      else
        LKey := K_UPARROW;
      FListBoxes.HandleKey(AMenu.Items[LIndex], LKey, True, True);
      Exit;
    end;
end;

end.
