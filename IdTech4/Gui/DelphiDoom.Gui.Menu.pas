{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - the model of a menu and its items                 }
{                                                                              }
{  Port of menuDef_t, itemDef_t, Window_Init, Item_Init, Menu_Init,            }
{  Item_ValidateTypeData, Item_SetScreenCoords, Item_UpdatePosition,           }
{  Menu_UpdatePosition, Menu_PostParse, Menu_FindItemByName,                   }
{  Menu_ItemsMatchingGroup and Menu_GetMatchingItemByNumber of ui_shared.c     }
{  (Quake III Arena, id Software, GPL v2 or later). Based on the Quake III     }
{  Arena GPL Source Code (id Software).                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Menu;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Gui.Types;

type
  TGuiMenu = class;

  /// <summary>
  ///   itemDef_t: one item of a menu. It is a data class (the fields are the fields of the original, which the
  ///   scripts and the painting code of a host read and write), with the few functions of ui_shared.c that
  ///   only touch the item. TGuiItem and TGuiMenu are in one unit because each one points to the other.
  /// </summary>
  TGuiItem = class
  public
    Window: TGuiWindowDef;
    TextRect: TGuiRect;
    /// <summary>The "type" keyword (ITEM_TYPE_*)</summary>
    ItemType: Integer;
    Alignment: Integer;
    TextAlignment: Integer;
    TextAlignX: Single;
    TextAlignY: Single;
    TextScale: Single;
    TextStyle: Integer;
    Text: AnsiString;
    /// <summary>The menu that owns the item; nil for an item that is not in a menu</summary>
    Parent: TGuiMenu;
    Asset: Integer;
    MouseEnterText: AnsiString;
    MouseExitText: AnsiString;
    MouseEnter: AnsiString;
    MouseExit: AnsiString;
    Action: AnsiString;
    OnFocus: AnsiString;
    LeaveFocus: AnsiString;
    Cvar: AnsiString;
    CvarTest: AnsiString;
    EnableCvar: AnsiString;
    CvarFlags: Integer;
    FocusSound: Integer;
    NumColors: Integer;
    ColorRanges: array[0..GUI_MAX_COLOR_RANGES - 1] of TGuiColorRange;
    Special: Single;
    CursorPos: Integer;
    /// <summary>Which of the type data exists (typeData of the original)</summary>
    DataKind: TGuiItemDataKind;
    ListBox: TGuiListBoxData;
    EditField: TGuiEditFieldData;
    Multi: TGuiMultiData;
    Model: TGuiModelData;
    /// <summary>Item_Init: zero, text scale 0.55, Window_Init</summary>
    constructor Create;
    /// <summary>
    ///   Item_ValidateTypeData: makes the type data the current type asks for, once; an item whose type
    ///   changes later keeps the data it has
    /// </summary>
    procedure ValidateTypeData;
    /// <summary>Item_SetScreenCoords</summary>
    procedure SetScreenCoords(const AX, AY: Single);
    /// <summary>Item_UpdatePosition: from the position of the menu; nothing without one</summary>
    procedure UpdatePosition;
  end;

  /// <summary>menuDef_t</summary>
  TGuiMenu = class
  strict private
    FItems: TObjectList<TGuiItem>;
  public
    Window: TGuiWindowDef;
    Font: AnsiString;
    FullScreen: Integer;
    FontIndex: Integer;
    CursorItem: Integer;
    FadeCycle: Integer;
    FadeClamp: Single;
    FadeAmount: Single;
    OnOpen: AnsiString;
    OnClose: AnsiString;
    OnESC: AnsiString;
    SoundName: AnsiString;
    FocusColor: TGuiColor;
    DisableColor: TGuiColor;
    /// <summary>Menu_Init: the fade values come from the assets of the display context</summary>
    constructor Create(const AFadeAmount, AFadeClamp: Single; const AFadeCycle: Integer);
    destructor Destroy; override;
    /// <summary>The items, owned by the menu (items[] and itemCount); at most GUI_MAX_MENUITEMS</summary>
    property Items: TObjectList<TGuiItem> read FItems;
    /// <summary>Menu_UpdatePosition</summary>
    procedure UpdatePosition;
    /// <summary>Menu_PostParse: a full screen menu is 640 x 480 at the origin; then the positions of the items</summary>
    procedure PostParse;
    /// <summary>Menu_FindItemByName: the first item with this name (without case), nil if none</summary>
    function FindItemByName(const AName: AnsiString): TGuiItem;
    /// <summary>Menu_ItemsMatchingGroup: items whose name or group is AName</summary>
    function ItemsMatchingGroup(const AName: AnsiString): Integer;
    /// <summary>Menu_GetMatchingItemByNumber: the AIndex-th item whose name or group is AName</summary>
    function GetMatchingItemByNumber(const AIndex: Integer; const AName: AnsiString): TGuiItem;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

{ TGuiItem }

constructor TGuiItem.Create;
begin
  inherited Create;
  Window := TGuiWindowDef.Create;
  TextScale := 0.55;
end;

procedure TGuiItem.ValidateTypeData;
begin
  if DataKind <> gdkNone then
    Exit;
  case ItemType of
    ITEM_TYPE_LISTBOX:
      DataKind := gdkListBox;
    ITEM_TYPE_EDITFIELD, ITEM_TYPE_NUMERICFIELD, ITEM_TYPE_YESNO, ITEM_TYPE_BIND, ITEM_TYPE_SLIDER,
      ITEM_TYPE_TEXT:
      begin
        DataKind := gdkEditField;
        if ItemType = ITEM_TYPE_EDITFIELD then
          EditField.MaxPaintChars := GUI_MAX_EDITFIELD;
      end;
    ITEM_TYPE_MULTI:
      DataKind := gdkMulti;
    ITEM_TYPE_MODEL:
      DataKind := gdkModel;
  end;
end;

procedure TGuiItem.SetScreenCoords(const AX, AY: Single);
var
  LX: Single;
  LY: Single;
begin
  LX := AX;
  LY := AY;
  if Window.Border <> 0 then
  begin
    LX := LX + Window.BorderSize;
    LY := LY + Window.BorderSize;
  end;
  Window.Rect.X := LX + Window.RectClient.X;
  Window.Rect.Y := LY + Window.RectClient.Y;
  Window.Rect.W := Window.RectClient.W;
  Window.Rect.H := Window.RectClient.H;
  // force the text rects to recompute
  TextRect.W := 0;
  TextRect.H := 0;
end;

procedure TGuiItem.UpdatePosition;
var
  LX: Single;
  LY: Single;
begin
  if not Assigned(Parent) then
    Exit;
  LX := Parent.Window.Rect.X;
  LY := Parent.Window.Rect.Y;
  if Parent.Window.Border <> 0 then
  begin
    LX := LX + Parent.Window.BorderSize;
    LY := LY + Parent.Window.BorderSize;
  end;
  SetScreenCoords(LX, LY);
end;

{ TGuiMenu }

constructor TGuiMenu.Create(const AFadeAmount, AFadeClamp: Single; const AFadeCycle: Integer);
begin
  inherited Create;
  FItems := TObjectList<TGuiItem>.Create(True);
  CursorItem := -1;
  FadeAmount := AFadeAmount;
  FadeClamp := AFadeClamp;
  FadeCycle := AFadeCycle;
  Window := TGuiWindowDef.Create;
end;

destructor TGuiMenu.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure TGuiMenu.UpdatePosition;
var
  LX: Single;
  LY: Single;
  LIndex: Integer;
begin
  LX := Window.Rect.X;
  LY := Window.Rect.Y;
  if Window.Border <> 0 then
  begin
    LX := LX + Window.BorderSize;
    LY := LY + Window.BorderSize;
  end;
  for LIndex := 0 to FItems.Count - 1 do
    FItems[LIndex].SetScreenCoords(LX, LY);
end;

procedure TGuiMenu.PostParse;
begin
  if FullScreen <> 0 then
  begin
    Window.Rect.X := 0;
    Window.Rect.Y := 0;
    Window.Rect.W := 640;
    Window.Rect.H := 480;
  end;
  UpdatePosition;
end;

function TGuiMenu.FindItemByName(const AName: AnsiString): TGuiItem;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FItems.Count - 1 do
    if TIdStrings.Icmp(AName, FItems[LIndex].Window.Name) = 0 then
      Exit(FItems[LIndex]);
  Result := nil;
end;

function TGuiMenu.ItemsMatchingGroup(const AName: AnsiString): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to FItems.Count - 1 do
    if (TIdStrings.Icmp(FItems[LIndex].Window.Name, AName) = 0) or
      ((FItems[LIndex].Window.Group <> '') and (TIdStrings.Icmp(FItems[LIndex].Window.Group, AName) = 0)) then
      Inc(Result);
end;

function TGuiMenu.GetMatchingItemByNumber(const AIndex: Integer; const AName: AnsiString): TGuiItem;
var
  LIndex: Integer;
  LCount: Integer;
begin
  LCount := 0;
  for LIndex := 0 to FItems.Count - 1 do
    if (TIdStrings.Icmp(FItems[LIndex].Window.Name, AName) = 0) or
      ((FItems[LIndex].Window.Group <> '') and (TIdStrings.Icmp(FItems[LIndex].Window.Group, AName) = 0)) then
    begin
      if LCount = AIndex then
        Exit(FItems[LIndex]);
      Inc(LCount);
    end;
  Result := nil;
end;

end.
