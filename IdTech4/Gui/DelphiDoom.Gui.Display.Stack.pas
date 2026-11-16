{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - the menus that are open                           }
{                                                                              }
{  Menus_FindByName, Menus_Activate, Menus_ActivateByName (Menus_OpenByName),  }
{  Menus_ShowByName, Menus_CloseByName, Menus_CloseAll, Menu_RunCloseScript,   }
{  Menu_GetFocused, Menu_GetFocusedItem, Menus_AnyFullScreenVisible,           }
{  Display_VisibleMenuCount, Display_CloseCinematics and                       }
{  Menu_SetFeederSelection of ui_shared.c (Quake III Arena, id Software, GPL   }
{  v2 or later). Based on the Quake III Arena GPL Source Code (id Software).   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Display.Stack;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Gui.Types, DelphiDoom.Gui.Menu, DelphiDoom.Gui.Display.State;

type
  /// <summary>
  ///   Which menus are visible and have the focus, and the stack of the menus that were focused when another was
  ///   opened (<c>menuStack</c>, 16 deep). The menus themselves are the menu set's.
  /// </summary>
  TGuiMenuStack = class
  strict private
    FState: TGuiDisplayState;
    procedure CloseMenuCinematics(const AMenu: TGuiMenu);
  public
    constructor Create(const AState: TGuiDisplayState);
    /// <summary>Menus_FindByName</summary>
    function FindByName(const AName: AnsiString): TGuiMenu;
    /// <summary>
    ///   Menus_Activate: the menu is visible and focused, its <c>onOpen</c> script runs, its music starts and
    ///   the cinematics of every menu stop
    /// </summary>
    procedure Activate(const AMenu: TGuiMenu);
    /// <summary>
    ///   Menus_ActivateByName, which is also Menus_OpenByName: activates the menus with that name, takes the
    ///   focus off every other one and pushes the menu that had the focus (if there is room). The last menu
    ///   with the name, nil if none.
    /// </summary>
    function ActivateByName(const AName: AnsiString): TGuiMenu;
    /// <summary>Menus_OpenByName</summary>
    procedure OpenByName(const AName: AnsiString);
    /// <summary>Menus_ShowByName: activates the first menu with that name, without touching the stack</summary>
    procedure ShowByName(const AName: AnsiString);
    /// <summary>Menu_RunCloseScript: the <c>onClose</c> of a visible menu</summary>
    procedure RunCloseScript(const AMenu: TGuiMenu);
    /// <summary>Menus_CloseByName: the close script, then no longer visible nor focused</summary>
    procedure CloseByName(const AName: AnsiString);
    /// <summary>Menus_CloseAll</summary>
    procedure CloseAll;
    /// <summary>Menu_GetFocused: the first menu that is visible and has the focus</summary>
    function GetFocused: TGuiMenu;
    /// <summary>Menu_GetFocusedItem: the first item with the focus, nil if none</summary>
    function GetFocusedItem(const AMenu: TGuiMenu): TGuiItem;
    /// <summary>Menus_AnyFullScreenVisible</summary>
    function AnyFullScreenVisible: Boolean;
    /// <summary>Display_VisibleMenuCount: menus that are visible or forced</summary>
    function VisibleMenuCount: Integer;
    /// <summary>Display_CloseCinematics: stops the cinematics of every menu and item</summary>
    procedure CloseCinematics;
    /// <summary>
    ///   Menu_SetFeederSelection: tells the feeder which line is selected (a menu of nil is the focused menu, or
    ///   the one named). Line 0 also puts the list back at its start.
    /// </summary>
    procedure SetFeederSelection(const AMenu: TGuiMenu; const AFeeder: Single; const AIndex: Integer;
      const AName: AnsiString; const AHasName: Boolean);
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.Gui.Keys;

constructor TGuiMenuStack.Create(const AState: TGuiDisplayState);
begin
  inherited Create;
  FState := AState;
end;

function TGuiMenuStack.FindByName(const AName: AnsiString): TGuiMenu;
begin
  Result := FState.Menus.FindByName(AName);
end;

procedure TGuiMenuStack.CloseMenuCinematics(const AMenu: TGuiMenu);
var
  LIndex: Integer;

  procedure CloseWindow(var AWindow: TGuiWindowDef);
  begin
    if (AWindow.Style = GUI_WINDOW_STYLE_CINEMATIC) and (AWindow.Cinematic >= 0) then
    begin
      if Assigned(FState.Media) then
        FState.Media.StopCinematic(AWindow.Cinematic);
      AWindow.Cinematic := -1;
    end;
  end;

begin
  if not Assigned(AMenu) then
    Exit;
  CloseWindow(AMenu.Window);
  for LIndex := 0 to AMenu.Items.Count - 1 do
  begin
    CloseWindow(AMenu.Items[LIndex].Window);
    if (AMenu.Items[LIndex].ItemType = ITEM_TYPE_OWNERDRAW) and Assigned(FState.Media) then
      FState.Media.StopCinematic(0 - AMenu.Items[LIndex].Window.OwnerDraw);
  end;
end;

procedure TGuiMenuStack.CloseCinematics;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FState.Menus.Count - 1 do
    CloseMenuCinematics(FState.Menus[LIndex]);
end;

procedure TGuiMenuStack.Activate(const AMenu: TGuiMenu);
var
  LItem: TGuiItem;
begin
  AMenu.Window.Flags := AMenu.Window.Flags or WINDOW_HASFOCUS or WINDOW_VISIBLE;
  if AMenu.OnOpen <> '' then
  begin
    LItem := FState.MenuScriptItem(AMenu);
    try
      FState.Runner.Run(LItem, AMenu.OnOpen);
    finally
      LItem.Free;
    end;
  end;
  if (AMenu.SoundName <> '') and Assigned(FState.Media) then
    FState.Media.StartBackgroundTrack(AMenu.SoundName, AMenu.SoundName);
  CloseCinematics;
end;

function TGuiMenuStack.ActivateByName(const AName: AnsiString): TGuiMenu;
var
  LIndex: Integer;
  LFocus, LMenu: TGuiMenu;
begin
  Result := nil;
  LFocus := GetFocused;
  for LIndex := 0 to FState.Menus.Count - 1 do
  begin
    LMenu := FState.Menus[LIndex];
    if TIdStrings.Icmp(LMenu.Window.Name, AName) = 0 then
    begin
      Result := LMenu;
      Activate(LMenu);
      if (FState.OpenMenuCount < GUI_MAX_OPEN_MENUS) and Assigned(LFocus) then
      begin
        FState.MenuStack[FState.OpenMenuCount] := LFocus;
        Inc(FState.OpenMenuCount);
      end;
    end
    else
      LMenu.Window.Flags := LMenu.Window.Flags and not WINDOW_HASFOCUS;
  end;
  CloseCinematics;
end;

procedure TGuiMenuStack.OpenByName(const AName: AnsiString);
begin
  ActivateByName(AName);
end;

procedure TGuiMenuStack.ShowByName(const AName: AnsiString);
var
  LMenu: TGuiMenu;
begin
  LMenu := FindByName(AName);
  if Assigned(LMenu) then
    Activate(LMenu);
end;

procedure TGuiMenuStack.RunCloseScript(const AMenu: TGuiMenu);
var
  LItem: TGuiItem;
begin
  if Assigned(AMenu) and ((AMenu.Window.Flags and WINDOW_VISIBLE) <> 0) and (AMenu.OnClose <> '') then
  begin
    LItem := FState.MenuScriptItem(AMenu);
    try
      FState.Runner.Run(LItem, AMenu.OnClose);
    finally
      LItem.Free;
    end;
  end;
end;

procedure TGuiMenuStack.CloseByName(const AName: AnsiString);
var
  LMenu: TGuiMenu;
begin
  LMenu := FindByName(AName);
  if Assigned(LMenu) then
  begin
    RunCloseScript(LMenu);
    LMenu.Window.Flags := LMenu.Window.Flags and not (WINDOW_VISIBLE or WINDOW_HASFOCUS);
  end;
end;

procedure TGuiMenuStack.CloseAll;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FState.Menus.Count - 1 do
  begin
    RunCloseScript(FState.Menus[LIndex]);
    FState.Menus[LIndex].Window.Flags := FState.Menus[LIndex].Window.Flags and
      not (WINDOW_HASFOCUS or WINDOW_VISIBLE);
  end;
end;

function TGuiMenuStack.GetFocused: TGuiMenu;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FState.Menus.Count - 1 do
    if ((FState.Menus[LIndex].Window.Flags and WINDOW_HASFOCUS) <> 0) and
      ((FState.Menus[LIndex].Window.Flags and WINDOW_VISIBLE) <> 0) then
      Exit(FState.Menus[LIndex]);
  Result := nil;
end;

function TGuiMenuStack.GetFocusedItem(const AMenu: TGuiMenu): TGuiItem;
var
  LIndex: Integer;
begin
  if Assigned(AMenu) then
    for LIndex := 0 to AMenu.Items.Count - 1 do
      if (AMenu.Items[LIndex].Window.Flags and WINDOW_HASFOCUS) <> 0 then
        Exit(AMenu.Items[LIndex]);
  Result := nil;
end;

function TGuiMenuStack.AnyFullScreenVisible: Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FState.Menus.Count - 1 do
    if ((FState.Menus[LIndex].Window.Flags and WINDOW_VISIBLE) <> 0) and (FState.Menus[LIndex].FullScreen <> 0) then
      Exit(True);
  Result := False;
end;

function TGuiMenuStack.VisibleMenuCount: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to FState.Menus.Count - 1 do
    if (FState.Menus[LIndex].Window.Flags and (WINDOW_FORCED or WINDOW_VISIBLE)) <> 0 then
      Inc(Result);
end;

procedure TGuiMenuStack.SetFeederSelection(const AMenu: TGuiMenu; const AFeeder: Single; const AIndex: Integer;
  const AName: AnsiString; const AHasName: Boolean);
var
  LMenu: TGuiMenu;
  LIndex: Integer;
  LItem: TGuiItem;
begin
  LMenu := AMenu;
  if not Assigned(LMenu) then
  begin
    if not AHasName then
      LMenu := GetFocused
    else
      LMenu := FindByName(AName);
  end;
  if not Assigned(LMenu) then
    Exit;
  for LIndex := 0 to LMenu.Items.Count - 1 do
  begin
    LItem := LMenu.Items[LIndex];
    if LItem.Special = AFeeder then
    begin
      if AIndex = 0 then
      begin
        LItem.ListBox.CursorPos := 0;
        LItem.ListBox.StartPos := 0;
      end;
      LItem.CursorPos := AIndex;
      FState.Input.FeederSelection(LItem.Special, LItem.CursorPos);
      Exit;
    end;
  end;
end;

end.
