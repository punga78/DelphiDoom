{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - the keys of a menu                                }
{                                                                              }
{  Menu_HandleKey, Menus_HandleOOBClick and Display_HandleKey of ui_shared.c   }
{  (Quake III Arena, id Software, GPL v2 or later). Based on the Quake III     }
{  Arena GPL Source Code (id Software).                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Display.MenuKeys;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Gui.Types, DelphiDoom.Gui.Menu, DelphiDoom.Gui.Display.State, DelphiDoom.Gui.Display.Stack,
  DelphiDoom.Gui.Display.Pointer, DelphiDoom.Gui.Display.ItemKeys, DelphiDoom.Gui.Display.TextField;

type
  /// <summary>
  ///   The keys that reach a menu: first the field being edited, then the item with the focus, then the
  ///   default handling (the arrows and tab move the focus, escape runs <c>onESC</c>, enter and a click run the
  ///   action). A click outside the menu goes to the menus under it.
  /// </summary>
  TGuiMenuKeys = class
  strict private
    FState: TGuiDisplayState;
    FStack: TGuiMenuStack;
    FPointer: TGuiPointer;
    FItemKeys: TGuiItemKeys;
    FTextFields: TGuiTextFieldKeys;
    /// <summary>the <c>static qboolean inHandleKey</c> of Menu_HandleKey: an out of bounds click is not handled twice</summary>
    FInHandleKey: Boolean;
    procedure BeginEditing(const AItem: TGuiItem);
  public
    /// <summary>The parts are not owned</summary>
    constructor Create(const AState: TGuiDisplayState; const AStack: TGuiMenuStack; const APointer: TGuiPointer;
      const AItemKeys: TGuiItemKeys; const ATextFields: TGuiTextFieldKeys);
    /// <summary>Menu_HandleKey</summary>
    procedure HandleKey(const AMenu: TGuiMenu; const AKey: Integer; const ADown: Boolean);
    /// <summary>
    ///   Menus_HandleOOBClick: a click outside the menu closes it if it asks so, and activates the menu under the
    ///   pointer (the key then goes to that one)
    /// </summary>
    procedure HandleOOBClick(const AMenu: TGuiMenu; const AKey: Integer; const ADown: Boolean);
    /// <summary>
    ///   Display_HandleKey: the key goes to the menu under the point, or to the focused one
    /// </summary>
    procedure DisplayHandleKey(const AKey: Integer; const ADown: Boolean; const AX, AY: Integer);
  end;

implementation

uses
  DelphiDoom.Gui.Keys;

constructor TGuiMenuKeys.Create(const AState: TGuiDisplayState; const AStack: TGuiMenuStack;
  const APointer: TGuiPointer; const AItemKeys: TGuiItemKeys; const ATextFields: TGuiTextFieldKeys);
begin
  inherited Create;
  FState := AState;
  FStack := AStack;
  FPointer := APointer;
  FItemKeys := AItemKeys;
  FTextFields := ATextFields;
end;

procedure TGuiMenuKeys.BeginEditing(const AItem: TGuiItem);
begin
  AItem.CursorPos := 0;
  FState.EditingField := True;
  FState.EditItem := AItem;
  FState.Input.SetOverstrikeMode(True);
end;

procedure TGuiMenuKeys.HandleOOBClick(const AMenu: TGuiMenu; const AKey: Integer; const ADown: Boolean);
var
  LIndex: Integer;
begin
  if not Assigned(AMenu) then
    Exit;
  // basically the behaviour we are looking for is if there are windows in the stack.. see if the cursor is
  // within any of them.. if not close them otherwise activate them and pass the key on.. force a mouse move
  // to activate focus and script stuff
  if ADown and ((AMenu.Window.Flags and WINDOW_OOB_CLICK) <> 0) then
  begin
    FStack.RunCloseScript(AMenu);
    AMenu.Window.Flags := AMenu.Window.Flags and not (WINDOW_HASFOCUS or WINDOW_VISIBLE);
  end;
  for LIndex := 0 to FState.Menus.Count - 1 do
    if FPointer.OverActiveItem(FState.Menus[LIndex], FState.CursorX, FState.CursorY) then
    begin
      FStack.RunCloseScript(AMenu);
      AMenu.Window.Flags := AMenu.Window.Flags and not (WINDOW_HASFOCUS or WINDOW_VISIBLE);
      FStack.Activate(FState.Menus[LIndex]);
      FPointer.HandleMouseMove(FState.Menus[LIndex], FState.CursorX, FState.CursorY);
      HandleKey(FState.Menus[LIndex], AKey, ADown);
    end;
  if FStack.VisibleMenuCount = 0 then
    FState.Input.Pause(False);
  FStack.CloseCinematics;
end;

procedure TGuiMenuKeys.HandleKey(const AMenu: TGuiMenu; const AKey: Integer; const ADown: Boolean);
var
  LIndex: Integer;
  LItem, LScriptItem: TGuiItem;
begin
  // the bind item is not ported: no key is ever waited for
  if FState.EditingField and ADown then
  begin
    if not FTextFields.HandleKey(FState.EditItem, AKey) then
    begin
      FState.EditingField := False;
      FState.EditItem := nil;
      Exit;
    end
    else if (AKey = K_MOUSE1) or (AKey = K_MOUSE2) or (AKey = K_MOUSE3) then
    begin
      FState.EditingField := False;
      FState.EditItem := nil;
      FPointer.MouseMove(nil, FState.Input.CursorX, FState.Input.CursorY);
    end
    else if (AKey = K_TAB) or (AKey = K_UPARROW) or (AKey = K_DOWNARROW) then
      Exit;
  end;
  if not Assigned(AMenu) then
    Exit;
  // see if the mouse is within the window bounds and if so is this a mouse click
  if ADown and ((AMenu.Window.Flags and WINDOW_POPUP) = 0) and
    not TGuiDisplayState.RectContains(AMenu.Window.Rect, FState.CursorX, FState.CursorY) then
  begin
    if (not FInHandleKey) and ((AKey = K_MOUSE1) or (AKey = K_MOUSE2) or (AKey = K_MOUSE3)) then
    begin
      FInHandleKey := True;
      try
        HandleOOBClick(AMenu, AKey, ADown);
      finally
        FInHandleKey := False;
      end;
      Exit;
    end;
  end;
  // get the item with focus: the last one that has it
  LItem := nil;
  for LIndex := 0 to AMenu.Items.Count - 1 do
    if (AMenu.Items[LIndex].Window.Flags and WINDOW_HASFOCUS) <> 0 then
      LItem := AMenu.Items[LIndex];
  if Assigned(LItem) then
    if FItemKeys.HandleKey(LItem, AKey, ADown) then
    begin
      FItemKeys.Action(LItem);
      Exit;
    end;
  if not ADown then
    Exit;
  // default handling
  case AKey of
    K_F11:
      if Assigned(FState.Script) and (FState.Script.GetCvarValue('developer') <> 0) then
        FState.DebugMode := not FState.DebugMode;
    K_F12:
      if Assigned(FState.Script) and (FState.Script.GetCvarValue('developer') <> 0) then
        FState.Script.ExecuteText(GUI_EXEC_APPEND, 'screenshot'#10);
    K_KP_UPARROW, K_UPARROW:
      FPointer.SetPrevCursorItem(AMenu);
    K_ESCAPE:
      if AMenu.OnESC <> '' then
      begin
        LScriptItem := FState.MenuScriptItem(AMenu);
        try
          FState.Runner.Run(LScriptItem, AMenu.OnESC);
        finally
          LScriptItem.Free;
        end;
      end;
    K_TAB, K_KP_DOWNARROW, K_DOWNARROW:
      FPointer.SetNextCursorItem(AMenu);
    K_MOUSE1, K_MOUSE2:
      if Assigned(LItem) then
      begin
        if LItem.ItemType = ITEM_TYPE_TEXT then
        begin
          if TGuiDisplayState.RectContains(TGuiDisplayState.CorrectedTextRect(LItem), FState.CursorX, FState.CursorY) then
            FItemKeys.Action(LItem);
        end
        else if (LItem.ItemType = ITEM_TYPE_EDITFIELD) or (LItem.ItemType = ITEM_TYPE_NUMERICFIELD) then
        begin
          if TGuiDisplayState.RectContains(LItem.Window.Rect, FState.CursorX, FState.CursorY) then
            BeginEditing(LItem);
        end
        else if TGuiDisplayState.RectContains(LItem.Window.Rect, FState.CursorX, FState.CursorY) then
          FItemKeys.Action(LItem);
      end;
    K_KP_ENTER, K_ENTER:
      if Assigned(LItem) then
      begin
        if (LItem.ItemType = ITEM_TYPE_EDITFIELD) or (LItem.ItemType = ITEM_TYPE_NUMERICFIELD) then
          BeginEditing(LItem)
        else
          FItemKeys.Action(LItem);
      end;
  end;
end;

procedure TGuiMenuKeys.DisplayHandleKey(const AKey: Integer; const ADown: Boolean; const AX, AY: Integer);
var
  LMenu: TGuiMenu;
begin
  LMenu := FPointer.CaptureItem(AX, AY);
  if not Assigned(LMenu) then
    LMenu := FStack.GetFocused;
  if Assigned(LMenu) then
    HandleKey(LMenu, AKey, ADown);
end;

end.
