{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - the state of the menu display                     }
{                                                                              }
{  The static variables of ui_shared.c that the input and the stack of menus   }
{  share (itemCapture, captureFunc, scrollInfo, g_editingField, g_editItem,    }
{  menuStack, openMenuCount, lastListBoxClickTime, debugMode) as the fields    }
{  of an object, with the small functions every part uses (IsVisible,          }
{  Rect_ContainsPoint, Item_CorrectedTextRect). Quake III Arena, id Software,  }
{  GPL v2 or later. Based on the Quake III Arena GPL Source Code (id           }
{  Software).                                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Display.State;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Gui.Types, DelphiDoom.Gui.Intf, DelphiDoom.Gui.Menu, DelphiDoom.Gui.MenuSet,
  DelphiDoom.Gui.ScriptRunner, DelphiDoom.Gui.Keys, DelphiDoom.Gui.Display.Intf;

type
  /// <summary>Which capture function runs while an item has the mouse (captureFunc)</summary>
  TGuiCaptureKind = (gckNone, gckListBoxAuto, gckListBoxThumb, gckSliderThumb);

  /// <summary>scrollInfo_t</summary>
  TGuiScrollInfo = record
    NextScrollTime: Integer;
    NextAdjustTime: Integer;
    AdjustValue: Integer;
    ScrollKey: Integer;
    XStart: Single;
    YStart: Single;
    Item: TGuiItem;
    ScrollDir: Boolean;
  end;

  /// <summary>
  ///   Everything the parts of the input code share: the menus, the script runner, the three hosts and the
  ///   state that ui_shared.c keeps in <c>static</c> variables. Two displays share nothing. The bind item
  ///   (<c>g_waitingForKey</c>, <c>Item_Bind_HandleKey</c>) is not ported: the key is never "pending".
  /// </summary>
  TGuiDisplayState = class
  public
    Menus: TGuiMenuSet;
    Runner: TGuiScriptRunner;
    Input: IGuiInputHost;
    Script: IGuiScriptHost;
    Media: IGuiMediaHost;
    /// <summary>itemCapture and captureFunc / captureData</summary>
    ItemCapture: TGuiItem;
    CaptureKind: TGuiCaptureKind;
    ScrollInfo: TGuiScrollInfo;
    EditingField: Boolean;
    EditItem: TGuiItem;
    LastListBoxClickTime: Integer;
    DebugMode: Boolean;
    MenuStack: array[0..GUI_MAX_OPEN_MENUS - 1] of TGuiMenu;
    OpenMenuCount: Integer;
    /// <summary>The menus, the runner and the hosts are not owned; Script and Media may be nil</summary>
    constructor Create(const AMenus: TGuiMenuSet; const ARunner: TGuiScriptRunner; const AInput: IGuiInputHost;
      const AScript: IGuiScriptHost; const AMedia: IGuiMediaHost);
    /// <summary>Rect_ContainsPoint: strictly inside</summary>
    class function RectContains(const ARect: TGuiRect; const AX, AY: Single): Boolean; static;
    /// <summary>IsVisible: visible and not fading out</summary>
    class function IsVisible(const AFlags: Integer): Boolean; static;
    /// <summary>
    ///   Item_CorrectedTextRect: the text rect, one line up (the text is drawn above its baseline); an empty
    ///   rect for an item without a text width
    /// </summary>
    class function CorrectedTextRect(const AItem: TGuiItem): TGuiRect; static;
    /// <summary><c>(int)f</c>: truncation; NaN and out of range give the smallest integer, as the processor does</summary>
    class function FloatToInt(const AValue: Double): Integer; static;
    /// <summary>The item the C code builds on its stack to run a script of a menu (<c>item.parent = menu</c>)</summary>
    function MenuScriptItem(const AMenu: TGuiMenu): TGuiItem;
    /// <summary>The cursor of the host as floats (the original passes the ints to float parameters)</summary>
    function CursorX: Single;
    function CursorY: Single;
  end;

implementation

uses
  System.Math;

constructor TGuiDisplayState.Create(const AMenus: TGuiMenuSet; const ARunner: TGuiScriptRunner;
  const AInput: IGuiInputHost; const AScript: IGuiScriptHost; const AMedia: IGuiMediaHost);
begin
  inherited Create;
  Menus := AMenus;
  Runner := ARunner;
  Input := AInput;
  Script := AScript;
  Media := AMedia;
end;

class function TGuiDisplayState.RectContains(const ARect: TGuiRect; const AX, AY: Single): Boolean;
var
  LRight, LBottom: Single;
begin
  LRight := ARect.X + ARect.W;
  LBottom := ARect.Y + ARect.H;
  Result := (AX > ARect.X) and (AX < LRight) and (AY > ARect.Y) and (AY < LBottom);
end;

class function TGuiDisplayState.IsVisible(const AFlags: Integer): Boolean;
begin
  Result := ((AFlags and WINDOW_VISIBLE) <> 0) and ((AFlags and WINDOW_FADINGOUT) = 0);
end;

class function TGuiDisplayState.CorrectedTextRect(const AItem: TGuiItem): TGuiRect;
begin
  Result := Default(TGuiRect);
  if Assigned(AItem) then
  begin
    Result := AItem.TextRect;
    if Result.W <> 0 then
      Result.Y := Result.Y - Result.H;
  end;
end;

class function TGuiDisplayState.FloatToInt(const AValue: Double): Integer;
begin
  if IsNan(AValue) or (AValue >= 2147483648.0) or (AValue < -2147483648.0) then
    Result := Low(Integer)
  else
    Result := Trunc(AValue);
end;

function TGuiDisplayState.MenuScriptItem(const AMenu: TGuiMenu): TGuiItem;
begin
  Result := TGuiItem.Create;
  Result.Parent := AMenu;
end;

function TGuiDisplayState.CursorX: Single;
begin
  Result := Input.CursorX;
end;

function TGuiDisplayState.CursorY: Single;
begin
  Result := Input.CursorY;
end;

end.
