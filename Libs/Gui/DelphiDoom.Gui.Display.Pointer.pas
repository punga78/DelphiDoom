{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - focus and the pointer                             }
{                                                                              }
{  Item_SetFocus, Menu_SetPrevCursorItem, Menu_SetNextCursorItem,              }
{  Item_MouseEnter, Item_MouseLeave, Item_SetMouseOver, Menu_HitTest,          }
{  Menu_HandleMouseMove, Menu_OverActiveItem, Display_CaptureItem,             }
{  Display_MouseMove and Display_CursorType of ui_shared.c (Quake III Arena,   }
{  id Software, GPL v2 or later). Based on the Quake III Arena GPL Source      }
{  Code (id Software).                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Display.Pointer;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Gui.Types, DelphiDoom.Gui.Menu, DelphiDoom.Gui.Display.State, DelphiDoom.Gui.Display.ListBox,
  DelphiDoom.Gui.Display.CvarItems, DelphiDoom.Gui.Display.Stack;

type
  /// <summary>Which item has the focus, and what the pointer over the menus does to the items</summary>
  TGuiPointer = class
  strict private
    FState: TGuiDisplayState;
    FListBoxes: TGuiListBoxLogic;
    FCvarItems: TGuiCvarItems;
    FStack: TGuiMenuStack;
    function PassesCvarTests(const AItem: TGuiItem): Boolean;
  public
    /// <summary>The parts are not owned</summary>
    constructor Create(const AState: TGuiDisplayState; const AListBoxes: TGuiListBoxLogic;
      const ACvarItems: TGuiCvarItems; const AStack: TGuiMenuStack);
    /// <summary>
    ///   Item_SetFocus: gives the item the focus if it can have it (visible, not a decoration, not focused,
    ///   enabled by its cvars; a text item only if the point is over its text); the focus sound plays and the
    ///   menu remembers the item as its cursor item
    /// </summary>
    function SetFocus(const AItem: TGuiItem; const AX, AY: Single): Boolean;
    /// <summary>
    ///   Menu_SetPrevCursorItem: the previous item that takes the focus, wrapping once; nil (and the cursor item
    ///   as it was) if none does. The original reads <c>items[-1]</c> after a full turn: here the search stops.
    /// </summary>
    function SetPrevCursorItem(const AMenu: TGuiMenu): TGuiItem;
    /// <summary>Menu_SetNextCursorItem (see the previous one for the end of the search)</summary>
    function SetNextCursorItem(const AMenu: TGuiMenu): TGuiItem;
    /// <summary>Item_MouseEnter: runs the enter scripts and tells a list box where the pointer is</summary>
    procedure MouseEnter(const AItem: TGuiItem; const AX, AY: Single);
    /// <summary>Item_MouseLeave</summary>
    procedure MouseLeave(const AItem: TGuiItem);
    /// <summary>Item_SetMouseOver</summary>
    class procedure SetMouseOver(const AItem: TGuiItem; const AFocus: Boolean); static;
    /// <summary>Menu_HitTest: the first item whose rect has the point</summary>
    function HitTest(const AMenu: TGuiMenu; const AX, AY: Single): TGuiItem;
    /// <summary>
    ///   Menu_HandleMouseMove: two passes over the items (the second one enters the item under the point and gives it
    ///   the focus); nothing while an item is captured or a field is edited
    /// </summary>
    procedure HandleMouseMove(const AMenu: TGuiMenu; const AX, AY: Single);
    /// <summary>Menu_OverActiveItem: the point is over an item of the menu that can be used</summary>
    function OverActiveItem(const AMenu: TGuiMenu; const AX, AY: Single): Boolean;
    /// <summary>Display_CaptureItem: the first menu whose rect has the point</summary>
    function CaptureItem(const AX, AY: Integer): TGuiMenu;
    /// <summary>
    ///   Display_MouseMove: without a menu the pointer moves over the focused popup or over every menu; with
    ///   one the menu is dragged by (X, Y)
    /// </summary>
    function MouseMove(const AMenu: TGuiMenu; const AX, AY: Integer): Boolean;
    /// <summary>Display_CursorType: GUI_CURSOR_SIZER over a corner of a menu, GUI_CURSOR_ARROW elsewhere</summary>
    function CursorType(const AX, AY: Integer): Integer;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Gui.Keys;

constructor TGuiPointer.Create(const AState: TGuiDisplayState; const AListBoxes: TGuiListBoxLogic;
  const ACvarItems: TGuiCvarItems; const AStack: TGuiMenuStack);
begin
  inherited Create;
  FState := AState;
  FListBoxes := AListBoxes;
  FCvarItems := ACvarItems;
  FStack := AStack;
end;

// items can be enabled and disabled, shown and hidden, based on cvars
function TGuiPointer.PassesCvarTests(const AItem: TGuiItem): Boolean;
begin
  Result := False;
  if ((AItem.CvarFlags and (CVAR_ENABLE or CVAR_DISABLE)) <> 0) and not FCvarItems.EnableShowViaCvar(AItem, CVAR_ENABLE) then
    Exit;
  if ((AItem.CvarFlags and (CVAR_SHOW or CVAR_HIDE)) <> 0) and not FCvarItems.EnableShowViaCvar(AItem, CVAR_SHOW) then
    Exit;
  Result := True;
end;

function TGuiPointer.SetFocus(const AItem: TGuiItem; const AX, AY: Single): Boolean;
var
  LOldFocus: TGuiItem;
  LRect: TGuiRect;
  LSound: Integer;
  LPlaySound: Boolean;
  LIndex: Integer;
begin
  Result := False;
  // sanity check, non-null, not a decoration and does not already have the focus
  if (not Assigned(AItem)) or ((AItem.Window.Flags and WINDOW_DECORATION) <> 0) or
    ((AItem.Window.Flags and WINDOW_HASFOCUS) <> 0) or ((AItem.Window.Flags and WINDOW_VISIBLE) = 0) then
    Exit;
  if not PassesCvarTests(AItem) then
    Exit;
  LSound := FState.Menus.Assets.ItemFocusSound;
  LPlaySound := False;
  LOldFocus := FState.Runner.ClearFocus(AItem.Parent);
  if AItem.ItemType = ITEM_TYPE_TEXT then
  begin
    LRect := AItem.TextRect;
    LRect.Y := LRect.Y - LRect.H;
    if TGuiDisplayState.RectContains(LRect, AX, AY) then
    begin
      AItem.Window.Flags := AItem.Window.Flags or WINDOW_HASFOCUS;
      if AItem.FocusSound <> 0 then
        LSound := AItem.FocusSound;
      LPlaySound := True;
    end
    else if Assigned(LOldFocus) then
    begin
      LOldFocus.Window.Flags := LOldFocus.Window.Flags or WINDOW_HASFOCUS;
      if LOldFocus.OnFocus <> '' then
        FState.Runner.Run(LOldFocus, LOldFocus.OnFocus);
    end;
  end
  else
  begin
    AItem.Window.Flags := AItem.Window.Flags or WINDOW_HASFOCUS;
    if AItem.OnFocus <> '' then
      FState.Runner.Run(AItem, AItem.OnFocus);
    if AItem.FocusSound <> 0 then
      LSound := AItem.FocusSound;
    LPlaySound := True;
  end;
  if LPlaySound and Assigned(FState.Media) then
    FState.Media.StartLocalSound(LSound, GUI_CHAN_LOCAL_SOUND);
  if Assigned(AItem.Parent) then
    for LIndex := 0 to AItem.Parent.Items.Count - 1 do
      if AItem.Parent.Items[LIndex] = AItem then
      begin
        AItem.Parent.CursorItem := LIndex;
        Break;
      end;
  Result := True;
end;

function TGuiPointer.SetPrevCursorItem(const AMenu: TGuiMenu): TGuiItem;
var
  LWrapped: Boolean;
  LOldCursor: Integer;
begin
  LWrapped := False;
  LOldCursor := AMenu.CursorItem;
  if AMenu.CursorItem < 0 then
  begin
    AMenu.CursorItem := AMenu.Items.Count - 1;
    LWrapped := True;
  end;
  while AMenu.CursorItem > -1 do
  begin
    Dec(AMenu.CursorItem);
    if (AMenu.CursorItem < 0) and not LWrapped then
    begin
      LWrapped := True;
      AMenu.CursorItem := AMenu.Items.Count - 1;
    end;
    // a full turn without a taker leaves the index at -1: the original reads items[-1] there
    if (AMenu.CursorItem < 0) or (AMenu.CursorItem >= AMenu.Items.Count) then
      Break;
    if SetFocus(AMenu.Items[AMenu.CursorItem], FState.CursorX, FState.CursorY) then
    begin
      HandleMouseMove(AMenu, AMenu.Items[AMenu.CursorItem].Window.Rect.X + 1,
        AMenu.Items[AMenu.CursorItem].Window.Rect.Y + 1);
      Exit(AMenu.Items[AMenu.CursorItem]);
    end;
  end;
  AMenu.CursorItem := LOldCursor;
  Result := nil;
end;

function TGuiPointer.SetNextCursorItem(const AMenu: TGuiMenu): TGuiItem;
var
  LWrapped: Boolean;
  LOldCursor: Integer;
begin
  LWrapped := False;
  LOldCursor := AMenu.CursorItem;
  if AMenu.CursorItem = -1 then
  begin
    AMenu.CursorItem := 0;
    LWrapped := True;
  end;
  while AMenu.CursorItem < AMenu.Items.Count do
  begin
    Inc(AMenu.CursorItem);
    if (AMenu.CursorItem >= AMenu.Items.Count) and not LWrapped then
    begin
      LWrapped := True;
      AMenu.CursorItem := 0;
    end;
    // after a wrap the index can reach the count: the original reads items[itemCount] there
    if (AMenu.CursorItem < 0) or (AMenu.CursorItem >= AMenu.Items.Count) then
      Break;
    if SetFocus(AMenu.Items[AMenu.CursorItem], FState.CursorX, FState.CursorY) then
    begin
      HandleMouseMove(AMenu, AMenu.Items[AMenu.CursorItem].Window.Rect.X + 1,
        AMenu.Items[AMenu.CursorItem].Window.Rect.Y + 1);
      Exit(AMenu.Items[AMenu.CursorItem]);
    end;
  end;
  AMenu.CursorItem := LOldCursor;
  Result := nil;
end;

procedure TGuiPointer.MouseEnter(const AItem: TGuiItem; const AX, AY: Single);
var
  LRect: TGuiRect;
begin
  if not Assigned(AItem) then
    Exit;
  LRect := AItem.TextRect;
  LRect.Y := LRect.Y - LRect.H;
  if not PassesCvarTests(AItem) then
    Exit;
  if TGuiDisplayState.RectContains(LRect, AX, AY) then
  begin
    if (AItem.Window.Flags and WINDOW_MOUSEOVERTEXT) = 0 then
    begin
      FState.Runner.Run(AItem, AItem.MouseEnterText);
      AItem.Window.Flags := AItem.Window.Flags or WINDOW_MOUSEOVERTEXT;
    end;
    if (AItem.Window.Flags and WINDOW_MOUSEOVER) = 0 then
    begin
      FState.Runner.Run(AItem, AItem.MouseEnter);
      AItem.Window.Flags := AItem.Window.Flags or WINDOW_MOUSEOVER;
    end;
  end
  else
  begin
    // not in the text rect
    if (AItem.Window.Flags and WINDOW_MOUSEOVERTEXT) <> 0 then
    begin
      FState.Runner.Run(AItem, AItem.MouseExitText);
      AItem.Window.Flags := AItem.Window.Flags and not WINDOW_MOUSEOVERTEXT;
    end;
    if (AItem.Window.Flags and WINDOW_MOUSEOVER) = 0 then
    begin
      FState.Runner.Run(AItem, AItem.MouseEnter);
      AItem.Window.Flags := AItem.Window.Flags or WINDOW_MOUSEOVER;
    end;
    if AItem.ItemType = ITEM_TYPE_LISTBOX then
      FListBoxes.MouseEnter(AItem, AX, AY);
  end;
end;

procedure TGuiPointer.MouseLeave(const AItem: TGuiItem);
begin
  if not Assigned(AItem) then
    Exit;
  if (AItem.Window.Flags and WINDOW_MOUSEOVERTEXT) <> 0 then
  begin
    FState.Runner.Run(AItem, AItem.MouseExitText);
    AItem.Window.Flags := AItem.Window.Flags and not WINDOW_MOUSEOVERTEXT;
  end;
  FState.Runner.Run(AItem, AItem.MouseExit);
  AItem.Window.Flags := AItem.Window.Flags and not (WINDOW_LB_RIGHTARROW or WINDOW_LB_LEFTARROW);
end;

class procedure TGuiPointer.SetMouseOver(const AItem: TGuiItem; const AFocus: Boolean);
begin
  if not Assigned(AItem) then
    Exit;
  if AFocus then
    AItem.Window.Flags := AItem.Window.Flags or WINDOW_MOUSEOVER
  else
    AItem.Window.Flags := AItem.Window.Flags and not WINDOW_MOUSEOVER;
end;

function TGuiPointer.HitTest(const AMenu: TGuiMenu; const AX, AY: Single): TGuiItem;
var
  LIndex: Integer;
begin
  for LIndex := 0 to AMenu.Items.Count - 1 do
    if TGuiDisplayState.RectContains(AMenu.Items[LIndex].Window.Rect, AX, AY) then
      Exit(AMenu.Items[LIndex]);
  Result := nil;
end;

procedure TGuiPointer.HandleMouseMove(const AMenu: TGuiMenu; const AX, AY: Single);
var
  LPass, LIndex: Integer;
  LFocusSet: Boolean;
  LItem: TGuiItem;
begin
  if not Assigned(AMenu) then
    Exit;
  if (AMenu.Window.Flags and (WINDOW_VISIBLE or WINDOW_FORCED)) = 0 then
    Exit;
  if Assigned(FState.ItemCapture) then
    Exit;
  if FState.EditingField then
    Exit;
  LFocusSet := False;
  for LPass := 0 to 1 do
    for LIndex := 0 to AMenu.Items.Count - 1 do
    begin
      LItem := AMenu.Items[LIndex];
      if (LItem.Window.Flags and (WINDOW_VISIBLE or WINDOW_FORCED)) = 0 then
        Continue;
      if not PassesCvarTests(LItem) then
        Continue;
      if TGuiDisplayState.RectContains(LItem.Window.Rect, AX, AY) then
      begin
        if LPass = 1 then
        begin
          if (LItem.ItemType = ITEM_TYPE_TEXT) and (LItem.Text <> '') then
            if not TGuiDisplayState.RectContains(TGuiDisplayState.CorrectedTextRect(LItem), AX, AY) then
              Continue;
          // if we are over an item
          if TGuiDisplayState.IsVisible(LItem.Window.Flags) then
          begin
            MouseEnter(LItem, AX, AY);
            // if item is not a decoration see if it can take focus
            if not LFocusSet then
              LFocusSet := SetFocus(LItem, AX, AY);
          end;
        end;
      end
      else if (LItem.Window.Flags and WINDOW_MOUSEOVER) <> 0 then
      begin
        MouseLeave(LItem);
        SetMouseOver(LItem, False);
      end;
    end;
end;

function TGuiPointer.OverActiveItem(const AMenu: TGuiMenu; const AX, AY: Single): Boolean;
var
  LIndex: Integer;
  LItem: TGuiItem;
begin
  Result := False;
  if Assigned(AMenu) and ((AMenu.Window.Flags and (WINDOW_VISIBLE or WINDOW_FORCED)) <> 0) then
  begin
    if TGuiDisplayState.RectContains(AMenu.Window.Rect, AX, AY) then
      for LIndex := 0 to AMenu.Items.Count - 1 do
      begin
        LItem := AMenu.Items[LIndex];
        if (LItem.Window.Flags and (WINDOW_VISIBLE or WINDOW_FORCED)) = 0 then
          Continue;
        if (LItem.Window.Flags and WINDOW_DECORATION) <> 0 then
          Continue;
        if TGuiDisplayState.RectContains(LItem.Window.Rect, AX, AY) then
        begin
          if (LItem.ItemType = ITEM_TYPE_TEXT) and (LItem.Text <> '') then
          begin
            if TGuiDisplayState.RectContains(TGuiDisplayState.CorrectedTextRect(LItem), AX, AY) then
              Exit(True)
            else
              Continue;
          end
          else
            Exit(True);
        end;
      end;
  end;
end;

function TGuiPointer.CaptureItem(const AX, AY: Integer): TGuiMenu;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FState.Menus.Count - 1 do
    if TGuiDisplayState.RectContains(FState.Menus[LIndex].Window.Rect, AX, AY) then
      Exit(FState.Menus[LIndex]);
  Result := nil;
end;

function TGuiPointer.MouseMove(const AMenu: TGuiMenu; const AX, AY: Integer): Boolean;
var
  LFocused: TGuiMenu;
  LIndex: Integer;
begin
  if not Assigned(AMenu) then
  begin
    LFocused := FStack.GetFocused;
    if Assigned(LFocused) and ((LFocused.Window.Flags and WINDOW_POPUP) <> 0) then
    begin
      HandleMouseMove(LFocused, AX, AY);
      Exit(True);
    end;
    for LIndex := 0 to FState.Menus.Count - 1 do
      HandleMouseMove(FState.Menus[LIndex], AX, AY);
  end
  else
  begin
    AMenu.Window.Rect.X := AMenu.Window.Rect.X + AX;
    AMenu.Window.Rect.Y := AMenu.Window.Rect.Y + AY;
    AMenu.UpdatePosition;
  end;
  Result := True;
end;

function TGuiPointer.CursorType(const AX, AY: Integer): Integer;
var
  LIndex: Integer;
  LRect: TGuiRect;
begin
  for LIndex := 0 to FState.Menus.Count - 1 do
  begin
    LRect.X := FState.Menus[LIndex].Window.Rect.X - 3;
    LRect.Y := FState.Menus[LIndex].Window.Rect.Y - 3;
    LRect.W := 7;
    LRect.H := 7;
    if TGuiDisplayState.RectContains(LRect, AX, AY) then
      Exit(GUI_CURSOR_SIZER);
  end;
  Result := GUI_CURSOR_ARROW;
end;

end.
