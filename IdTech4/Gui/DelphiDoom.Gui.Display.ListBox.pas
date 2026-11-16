{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - list boxes                                        }
{                                                                              }
{  Item_ListBox_MaxScroll, _ThumbPosition, _ThumbDrawPosition, _OverLB,        }
{  _MouseEnter and _HandleKey of ui_shared.c (Quake III Arena, id Software,    }
{  GPL v2 or later). SCROLLBAR_SIZE is a double constant in the original, so   }
{  the arithmetic that touches it is done in double. Based on the Quake III    }
{  Arena GPL Source Code (id Software).                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Display.ListBox;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Gui.Types, DelphiDoom.Gui.Menu, DelphiDoom.Gui.Display.State;

type
  /// <summary>The behaviour of a list box item: scrolling, selecting, the mouse over its parts</summary>
  TGuiListBoxLogic = class
  strict private
    FState: TGuiDisplayState;
  public
    constructor Create(const AState: TGuiDisplayState);
    /// <summary>Item_ListBox_MaxScroll</summary>
    function MaxScroll(const AItem: TGuiItem): Integer;
    /// <summary>Item_ListBox_ThumbPosition</summary>
    function ThumbPosition(const AItem: TGuiItem): Integer;
    /// <summary>Item_ListBox_ThumbDrawPosition: follows the cursor while the thumb is captured</summary>
    function ThumbDrawPosition(const AItem: TGuiItem): Integer;
    /// <summary>Item_ListBox_OverLB: the WINDOW_LB_* part under a point, 0 for none</summary>
    function OverLB(const AItem: TGuiItem; const AX, AY: Single): Integer;
    /// <summary>Item_ListBox_MouseEnter</summary>
    procedure MouseEnter(const AItem: TGuiItem; const AX, AY: Single);
    /// <summary>
    ///   Item_ListBox_HandleKey: true when the key was used. <c>AForce</c> skips the check that the cursor is over
    ///   a focused item (the scrolling by a feeder and the auto-scroll of a held arrow).
    /// </summary>
    function HandleKey(const AItem: TGuiItem; const AKey: Integer; const ADown, AForce: Boolean): Boolean;
  end;

implementation

uses
  DelphiDoom.Gui.Keys, DelphiDoom.Gui.Display.FloatMask;

// ( a + b ) - SCROLLBAR_SIZE: the sum is a float, the constant a double
function FarEdge(const AStart, ALength: Single): Single;
var
  LSum: Single;
begin
  LSum := AStart + ALength;
  Result := Double(LSum) - GUI_SCROLLBAR_SIZE;
end;

constructor TGuiListBoxLogic.Create(const AState: TGuiDisplayState);
begin
  inherited Create;
  FState := AState;
end;

function TGuiListBoxLogic.MaxScroll(const AItem: TGuiItem): Integer;
var
  LCount: Integer;
  LValue, LView: Single;
  LMask: IInterface;
begin
  LMask := TGuiFloatMask.Enter;
  LCount := FState.Input.FeederCount(AItem.Special);
  if (AItem.Window.Flags and WINDOW_HORIZONTAL) <> 0 then
    LView := AItem.Window.Rect.W / AItem.ListBox.ElementWidth
  else
    LView := AItem.Window.Rect.H / AItem.ListBox.ElementHeight;
  LValue := LCount;
  LValue := LValue - LView;
  LValue := LValue + 1;
  Result := TGuiDisplayState.FloatToInt(LValue);
  if Result < 0 then
    Result := 0;
end;

function TGuiListBoxLogic.ThumbPosition(const AItem: TGuiItem): Integer;
var
  LMax, LPos, LSize: Single;
  LMask: IInterface;
begin
  LMask := TGuiFloatMask.Enter;
  LMax := MaxScroll(AItem);
  if (AItem.Window.Flags and WINDOW_HORIZONTAL) <> 0 then
    LSize := Double(AItem.Window.Rect.W) - GUI_SCROLLBAR_SIZE * 2 - 2
  else
    LSize := Double(AItem.Window.Rect.H) - GUI_SCROLLBAR_SIZE * 2 - 2;
  if LMax > 0 then
    LPos := (Double(LSize) - GUI_SCROLLBAR_SIZE) / Double(LMax)
  else
    LPos := 0;
  LPos := LPos * AItem.ListBox.StartPos;
  if (AItem.Window.Flags and WINDOW_HORIZONTAL) <> 0 then
    Result := TGuiDisplayState.FloatToInt(Double(AItem.Window.Rect.X + 1) + GUI_SCROLLBAR_SIZE + Double(LPos))
  else
    Result := TGuiDisplayState.FloatToInt(Double(AItem.Window.Rect.Y + 1) + GUI_SCROLLBAR_SIZE + Double(LPos));
end;

function TGuiListBoxLogic.ThumbDrawPosition(const AItem: TGuiItem): Integer;
var
  LMin, LMax: Integer;
  LCursor: Integer;
begin
  if FState.ItemCapture = AItem then
  begin
    if (AItem.Window.Flags and WINDOW_HORIZONTAL) <> 0 then
    begin
      LMin := TGuiDisplayState.FloatToInt(Double(AItem.Window.Rect.X) + GUI_SCROLLBAR_SIZE + 1);
      LMax := TGuiDisplayState.FloatToInt(Double(AItem.Window.Rect.X + AItem.Window.Rect.W) -
        2 * GUI_SCROLLBAR_SIZE - 1);
      LCursor := FState.Input.CursorX;
      if (LCursor >= LMin + 8) and (LCursor <= LMax + 8) then
        Exit(LCursor - 8);
    end
    else
    begin
      LMin := TGuiDisplayState.FloatToInt(Double(AItem.Window.Rect.Y) + GUI_SCROLLBAR_SIZE + 1);
      LMax := TGuiDisplayState.FloatToInt(Double(AItem.Window.Rect.Y + AItem.Window.Rect.H) -
        2 * GUI_SCROLLBAR_SIZE - 1);
      LCursor := FState.Input.CursorY;
      if (LCursor >= LMin + 8) and (LCursor <= LMax + 8) then
        Exit(LCursor - 8);
    end;
  end;
  Result := ThumbPosition(AItem);
end;

function TGuiListBoxLogic.OverLB(const AItem: TGuiItem; const AX, AY: Single): Integer;
var
  LRect: TGuiRect;
  LThumbStart: Integer;
  LWindow: TGuiRect;
begin
  LWindow := AItem.Window.Rect;
  if (AItem.Window.Flags and WINDOW_HORIZONTAL) <> 0 then
  begin
    LRect.X := LWindow.X;
    LRect.Y := FarEdge(LWindow.Y, LWindow.H);
    LRect.H := GUI_SCROLLBAR_SIZE;
    LRect.W := GUI_SCROLLBAR_SIZE;
    if TGuiDisplayState.RectContains(LRect, AX, AY) then
      Exit(WINDOW_LB_LEFTARROW);
    LRect.X := FarEdge(LWindow.X, LWindow.W);
    if TGuiDisplayState.RectContains(LRect, AX, AY) then
      Exit(WINDOW_LB_RIGHTARROW);
    LThumbStart := ThumbPosition(AItem);
    LRect.X := LThumbStart;
    if TGuiDisplayState.RectContains(LRect, AX, AY) then
      Exit(WINDOW_LB_THUMB);
    LRect.X := LWindow.X + GUI_SCROLLBAR_SIZE;
    LRect.W := LThumbStart - LRect.X;
    if TGuiDisplayState.RectContains(LRect, AX, AY) then
      Exit(WINDOW_LB_PGUP);
    LRect.X := LThumbStart + GUI_SCROLLBAR_SIZE;
    LRect.W := FarEdge(LWindow.X, LWindow.W);
    if TGuiDisplayState.RectContains(LRect, AX, AY) then
      Exit(WINDOW_LB_PGDN);
  end
  else
  begin
    LRect.X := FarEdge(LWindow.X, LWindow.W);
    LRect.Y := LWindow.Y;
    LRect.H := GUI_SCROLLBAR_SIZE;
    LRect.W := GUI_SCROLLBAR_SIZE;
    if TGuiDisplayState.RectContains(LRect, AX, AY) then
      Exit(WINDOW_LB_LEFTARROW);
    LRect.Y := FarEdge(LWindow.Y, LWindow.H);
    if TGuiDisplayState.RectContains(LRect, AX, AY) then
      Exit(WINDOW_LB_RIGHTARROW);
    LThumbStart := ThumbPosition(AItem);
    LRect.Y := LThumbStart;
    if TGuiDisplayState.RectContains(LRect, AX, AY) then
      Exit(WINDOW_LB_THUMB);
    LRect.Y := LWindow.Y + GUI_SCROLLBAR_SIZE;
    LRect.H := LThumbStart - LRect.Y;
    if TGuiDisplayState.RectContains(LRect, AX, AY) then
      Exit(WINDOW_LB_PGUP);
    LRect.Y := LThumbStart + GUI_SCROLLBAR_SIZE;
    LRect.H := FarEdge(LWindow.Y, LWindow.H);
    if TGuiDisplayState.RectContains(LRect, AX, AY) then
      Exit(WINDOW_LB_PGDN);
  end;
  Result := 0;
end;

procedure TGuiListBoxLogic.MouseEnter(const AItem: TGuiItem; const AX, AY: Single);
const
  LB_PARTS = WINDOW_LB_LEFTARROW or WINDOW_LB_RIGHTARROW or WINDOW_LB_THUMB or WINDOW_LB_PGUP or WINDOW_LB_PGDN;
var
  LRect: TGuiRect;
  LValue: Single;
  LMask: IInterface;
begin
  LMask := TGuiFloatMask.Enter;
  AItem.Window.Flags := AItem.Window.Flags and not LB_PARTS;
  AItem.Window.Flags := AItem.Window.Flags or OverLB(AItem, AX, AY);
  if (AItem.Window.Flags and WINDOW_HORIZONTAL) <> 0 then
  begin
    if (AItem.Window.Flags and LB_PARTS) = 0 then
    begin
      // check for selection hit as we have exhausted buttons and thumb
      if AItem.ListBox.ElementStyle = GUI_LISTBOX_IMAGE then
      begin
        LRect.X := AItem.Window.Rect.X;
        LRect.Y := AItem.Window.Rect.Y;
        LRect.H := AItem.Window.Rect.H - GUI_SCROLLBAR_SIZE;
        LRect.W := AItem.Window.Rect.W - AItem.ListBox.DrawPadding;
        if TGuiDisplayState.RectContains(LRect, AX, AY) then
        begin
          LValue := AX - LRect.X;
          LValue := LValue / AItem.ListBox.ElementWidth;
          AItem.ListBox.CursorPos := TGuiDisplayState.FloatToInt(LValue) + AItem.ListBox.StartPos;
          if AItem.ListBox.CursorPos >= AItem.ListBox.EndPos then
            AItem.ListBox.CursorPos := AItem.ListBox.EndPos;
        end;
      end;
    end;
  end
  else if (AItem.Window.Flags and LB_PARTS) = 0 then
  begin
    LRect.X := AItem.Window.Rect.X;
    LRect.Y := AItem.Window.Rect.Y;
    LRect.W := AItem.Window.Rect.W - GUI_SCROLLBAR_SIZE;
    LRect.H := AItem.Window.Rect.H - AItem.ListBox.DrawPadding;
    if TGuiDisplayState.RectContains(LRect, AX, AY) then
    begin
      LValue := AY - 2;
      LValue := LValue - LRect.Y;
      LValue := LValue / AItem.ListBox.ElementHeight;
      AItem.ListBox.CursorPos := TGuiDisplayState.FloatToInt(LValue) + AItem.ListBox.StartPos;
      if AItem.ListBox.CursorPos > AItem.ListBox.EndPos then
        AItem.ListBox.CursorPos := AItem.ListBox.EndPos;
    end;
  end;
end;

function TGuiListBoxLogic.HandleKey(const AItem: TGuiItem; const AKey: Integer; const ADown, AForce: Boolean): Boolean;
var
  LCount, LMax, LViewMax: Integer;
  LMask: IInterface;

  // the cursor moved: keep it in the view, tell the feeder
  procedure Select(const AShowMax: Boolean);
  begin
    if AItem.ListBox.CursorPos < AItem.ListBox.StartPos then
      AItem.ListBox.StartPos := AItem.ListBox.CursorPos;
    if AItem.ListBox.CursorPos >= AItem.ListBox.StartPos + LViewMax then
      AItem.ListBox.StartPos := AItem.ListBox.CursorPos - LViewMax + 1;
    AItem.CursorPos := AItem.ListBox.CursorPos;
    FState.Input.FeederSelection(AItem.Special, AItem.CursorPos);
  end;

  procedure MoveBack(const ASteps: Integer);
  begin
    if not AItem.ListBox.NotSelectable then
    begin
      AItem.ListBox.CursorPos := AItem.ListBox.CursorPos - ASteps;
      if AItem.ListBox.CursorPos < 0 then
        AItem.ListBox.CursorPos := 0;
      Select(False);
    end
    else
    begin
      AItem.ListBox.StartPos := AItem.ListBox.StartPos - ASteps;
      if AItem.ListBox.StartPos < 0 then
        AItem.ListBox.StartPos := 0;
    end;
  end;

  procedure MoveForward(const ASteps: Integer; const AScrollLimit: Integer);
  begin
    if not AItem.ListBox.NotSelectable then
    begin
      AItem.ListBox.CursorPos := AItem.ListBox.CursorPos + ASteps;
      if AItem.ListBox.CursorPos < AItem.ListBox.StartPos then
        AItem.ListBox.StartPos := AItem.ListBox.CursorPos;
      if AItem.ListBox.CursorPos >= LCount then
        AItem.ListBox.CursorPos := LCount - 1;
      if AItem.ListBox.CursorPos >= AItem.ListBox.StartPos + LViewMax then
        AItem.ListBox.StartPos := AItem.ListBox.CursorPos - LViewMax + 1;
      AItem.CursorPos := AItem.ListBox.CursorPos;
      FState.Input.FeederSelection(AItem.Special, AItem.CursorPos);
    end
    else
    begin
      AItem.ListBox.StartPos := AItem.ListBox.StartPos + ASteps;
      if AItem.ListBox.StartPos > AScrollLimit then
        AItem.ListBox.StartPos := AScrollLimit;
    end;
  end;

begin
  Result := False;
  LMask := TGuiFloatMask.Enter;
  LCount := FState.Input.FeederCount(AItem.Special);
  if not (AForce or (TGuiDisplayState.RectContains(AItem.Window.Rect, FState.CursorX, FState.CursorY) and
    ((AItem.Window.Flags and WINDOW_HASFOCUS) <> 0))) then
    Exit;
  LMax := MaxScroll(AItem);
  if (AItem.Window.Flags and WINDOW_HORIZONTAL) <> 0 then
  begin
    LViewMax := TGuiDisplayState.FloatToInt(AItem.Window.Rect.W / AItem.ListBox.ElementWidth);
    if (AKey = K_LEFTARROW) or (AKey = K_KP_LEFTARROW) then
    begin
      MoveBack(1);
      Exit(True);
    end;
    if (AKey = K_RIGHTARROW) or (AKey = K_KP_RIGHTARROW) then
    begin
      // the original limits the view of an unselectable list to count - 1, not to the scroll maximum
      MoveForward(1, LCount - 1);
      Exit(True);
    end;
  end
  else
  begin
    LViewMax := TGuiDisplayState.FloatToInt(AItem.Window.Rect.H / AItem.ListBox.ElementHeight);
    if (AKey = K_UPARROW) or (AKey = K_KP_UPARROW) then
    begin
      MoveBack(1);
      Exit(True);
    end;
    if (AKey = K_DOWNARROW) or (AKey = K_KP_DOWNARROW) then
    begin
      MoveForward(1, LMax);
      Exit(True);
    end;
  end;
  // mouse hit
  if (AKey = K_MOUSE1) or (AKey = K_MOUSE2) then
  begin
    if (AItem.Window.Flags and WINDOW_LB_LEFTARROW) <> 0 then
    begin
      Dec(AItem.ListBox.StartPos);
      if AItem.ListBox.StartPos < 0 then
        AItem.ListBox.StartPos := 0;
    end
    else if (AItem.Window.Flags and WINDOW_LB_RIGHTARROW) <> 0 then
    begin
      Inc(AItem.ListBox.StartPos);
      if AItem.ListBox.StartPos > LMax then
        AItem.ListBox.StartPos := LMax;
    end
    else if (AItem.Window.Flags and WINDOW_LB_PGUP) <> 0 then
    begin
      AItem.ListBox.StartPos := AItem.ListBox.StartPos - LViewMax;
      if AItem.ListBox.StartPos < 0 then
        AItem.ListBox.StartPos := 0;
    end
    else if (AItem.Window.Flags and WINDOW_LB_PGDN) <> 0 then
    begin
      AItem.ListBox.StartPos := AItem.ListBox.StartPos + LViewMax;
      if AItem.ListBox.StartPos > LMax then
        AItem.ListBox.StartPos := LMax;
    end
    else if (AItem.Window.Flags and WINDOW_LB_THUMB) <> 0 then
    begin
      // Display_SetCaptureItem(item): commented out in the original
    end
    else
    begin
      // select an item
      if (FState.Input.RealTime < FState.LastListBoxClickTime) and (AItem.ListBox.DoubleClick <> '') then
        FState.Runner.Run(AItem, AItem.ListBox.DoubleClick);
      FState.LastListBoxClickTime := FState.Input.RealTime + GUI_DOUBLE_CLICK_DELAY;
      if AItem.CursorPos <> AItem.ListBox.CursorPos then
      begin
        AItem.CursorPos := AItem.ListBox.CursorPos;
        FState.Input.FeederSelection(AItem.Special, AItem.CursorPos);
      end;
    end;
    Exit(True);
  end;
  if (AKey = K_HOME) or (AKey = K_KP_HOME) then
  begin
    AItem.ListBox.StartPos := 0;
    Exit(True);
  end;
  if (AKey = K_END) or (AKey = K_KP_END) then
  begin
    AItem.ListBox.StartPos := LMax;
    Exit(True);
  end;
  if (AKey = K_PGUP) or (AKey = K_KP_PGUP) then
  begin
    MoveBack(LViewMax);
    Exit(True);
  end;
  if (AKey = K_PGDN) or (AKey = K_KP_PGDN) then
  begin
    MoveForward(LViewMax, LMax);
    Exit(True);
  end;
end;

end.
