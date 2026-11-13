{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - shared types, constants and exceptions            }
{                                                                              }
{  Port of the menu code of Quake III Arena / Team Arena (id Software, GPL v2  }
{  or later): ui_shared.h, menudef.h. Based on the Quake III Arena GPL Source  }
{  Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>MAX_MENUS</summary>
  GUI_MAX_MENUS = 64;
  /// <summary>MAX_MENUITEMS: items past this count are not stored (the original does not even skip their text)</summary>
  GUI_MAX_MENUITEMS = 96;
  /// <summary>MAX_COLOR_RANGES</summary>
  GUI_MAX_COLOR_RANGES = 10;
  /// <summary>MAX_LB_COLUMNS</summary>
  GUI_MAX_LB_COLUMNS = 16;
  /// <summary>MAX_MULTI_CVARS</summary>
  GUI_MAX_MULTI_CVARS = 32;
  /// <summary>MAX_EDITFIELD</summary>
  GUI_MAX_EDITFIELD = 256;
  /// <summary>STRING_POOL_SIZE of the ui module (384 KB); the cgame module has 128 KB</summary>
  GUI_STRING_POOL_SIZE = 384 * 1024;
  /// <summary>The script buffer of PC_Script_Parse and Item_RunScript is char[1024]</summary>
  GUI_SCRIPT_BUFFER_SIZE = 1024;
  /// <summary>CHAN_LOCAL_SOUND</summary>
  GUI_CHAN_LOCAL_SOUND = 6;
  /// <summary>EXEC_APPEND</summary>
  GUI_EXEC_APPEND = 2;

  // window flags (WINDOW_*)
  WINDOW_MOUSEOVER = $00000001;
  WINDOW_HASFOCUS = $00000002;
  WINDOW_VISIBLE = $00000004;
  WINDOW_GREY = $00000008;
  WINDOW_DECORATION = $00000010;
  WINDOW_FADINGOUT = $00000020;
  WINDOW_FADINGIN = $00000040;
  WINDOW_MOUSEOVERTEXT = $00000080;
  WINDOW_INTRANSITION = $00000100;
  WINDOW_FORECOLORSET = $00000200;
  WINDOW_HORIZONTAL = $00000400;
  WINDOW_LB_LEFTARROW = $00000800;
  WINDOW_LB_RIGHTARROW = $00001000;
  WINDOW_LB_THUMB = $00002000;
  WINDOW_LB_PGUP = $00004000;
  WINDOW_LB_PGDN = $00008000;
  WINDOW_ORBITING = $00010000;
  WINDOW_OOB_CLICK = $00020000;
  WINDOW_WRAPPED = $00040000;
  WINDOW_AUTOWRAPPED = $00080000;
  WINDOW_FORCED = $00100000;
  WINDOW_POPUP = $00200000;
  WINDOW_BACKCOLORSET = $00400000;
  WINDOW_TIMEDVISIBLE = $00800000;

  // item types (ITEM_TYPE_*)
  ITEM_TYPE_TEXT = 0;
  ITEM_TYPE_BUTTON = 1;
  ITEM_TYPE_RADIOBUTTON = 2;
  ITEM_TYPE_CHECKBOX = 3;
  ITEM_TYPE_EDITFIELD = 4;
  ITEM_TYPE_COMBO = 5;
  ITEM_TYPE_LISTBOX = 6;
  ITEM_TYPE_MODEL = 7;
  ITEM_TYPE_OWNERDRAW = 8;
  ITEM_TYPE_NUMERICFIELD = 9;
  ITEM_TYPE_SLIDER = 10;
  ITEM_TYPE_YESNO = 11;
  ITEM_TYPE_MULTI = 12;
  ITEM_TYPE_BIND = 13;

  // enableCvar actions (CVAR_ENABLE ...)
  CVAR_ENABLE = 1;
  CVAR_DISABLE = 2;
  CVAR_SHOW = 4;
  CVAR_HIDE = 8;

type
  /// <summary>Every failure of the Gui library that is not a diagnostic of a menu file</summary>
  EGuiException = class(Exception);

  /// <summary>A menu file (or the list of menu files) could not be found</summary>
  EGuiFileNotFoundException = class(EGuiException)
  strict private
    FFileName: AnsiString;
  public
    constructor Create(const AFileName: AnsiString);
    property FileName: AnsiString read FFileName;
  end;

  /// <summary>A syntax error of a menu file, with the file and the line where the precompiler was</summary>
  EGuiParseException = class(EGuiException)
  strict private
    FFileName: AnsiString;
    FLine: Integer;
  public
    constructor Create(const AFileName: AnsiString; const ALine: Integer; const AText: string);
    property FileName: AnsiString read FFileName;
    property Line: Integer read FLine;
  end;

  /// <summary>A font file that is not a fontInfo_t of 20548 bytes</summary>
  EGuiFontException = class(EGuiException);

  /// <summary>rectDef_t</summary>
  TGuiRect = record
    X: Single;
    Y: Single;
    W: Single;
    H: Single;
  end;

  /// <summary>vec4_t</summary>
  TGuiColor = array[0..3] of Single;

  /// <summary>
  ///   pc_token_t: a token read by the precompiler. Strings come without their quotes (PC_ReadTokenHandle
  ///   strips them); numbers have their values (IntValue is the low 32 bits of the unsigned value).
  /// </summary>
  TGuiToken = record
    Text: AnsiString;
    TokenType: Integer;
    SubType: Integer;
    IntValue: Integer;
    FloatValue: Single;
  end;

  /// <summary>colorRangeDef_t</summary>
  TGuiColorRange = record
    Color: TGuiColor;
    Low: Single;
    High: Single;
  end;

  /// <summary>columnInfo_t</summary>
  TGuiColumnInfo = record
    Pos: Integer;
    Width: Integer;
    MaxChars: Integer;
  end;

  /// <summary>windowDef_t: what menus and items have in common</summary>
  TGuiWindowDef = record
    Rect: TGuiRect;
    RectClient: TGuiRect;
    Name: AnsiString;
    Group: AnsiString;
    CinematicName: AnsiString;
    Cinematic: Integer;
    Style: Integer;
    Border: Integer;
    OwnerDraw: Integer;
    OwnerDrawFlags: Integer;
    BorderSize: Single;
    Flags: Integer;
    RectEffects: TGuiRect;
    RectEffects2: TGuiRect;
    OffsetTime: Integer;
    NextTime: Integer;
    ForeColor: TGuiColor;
    BackColor: TGuiColor;
    BorderColor: TGuiColor;
    OutlineColor: TGuiColor;
    Background: Integer;
    /// <summary>Window_Init: zero, border size 1, white text, no cinematic</summary>
    class function Create: TGuiWindowDef; static;
  end;

  /// <summary>listBoxDef_t</summary>
  TGuiListBoxData = record
    StartPos: Integer;
    EndPos: Integer;
    DrawPadding: Integer;
    CursorPos: Integer;
    ElementWidth: Single;
    ElementHeight: Single;
    ElementStyle: Integer;
    NumColumns: Integer;
    ColumnInfo: array[0..GUI_MAX_LB_COLUMNS - 1] of TGuiColumnInfo;
    DoubleClick: AnsiString;
    NotSelectable: Boolean;
  end;

  /// <summary>editFieldDef_t</summary>
  TGuiEditFieldData = record
    MinVal: Single;
    MaxVal: Single;
    DefVal: Single;
    Range: Single;
    MaxChars: Integer;
    MaxPaintChars: Integer;
    PaintOffset: Integer;
  end;

  /// <summary>multiDef_t</summary>
  TGuiMultiData = record
    CvarList: array[0..GUI_MAX_MULTI_CVARS - 1] of AnsiString;
    CvarStr: array[0..GUI_MAX_MULTI_CVARS - 1] of AnsiString;
    CvarValue: array[0..GUI_MAX_MULTI_CVARS - 1] of Single;
    Count: Integer;
    StrDef: Boolean;
  end;

  /// <summary>modelDef_t</summary>
  TGuiModelData = record
    Angle: Integer;
    Origin: array[0..2] of Single;
    FovX: Single;
    FovY: Single;
    RotationSpeed: Integer;
  end;

  /// <summary>Which of the type data of an item exists (the pointer typeData of itemDef_t)</summary>
  TGuiItemDataKind = (gdkNone, gdkListBox, gdkEditField, gdkMulti, gdkModel);

implementation

{ EGuiFileNotFoundException }

constructor EGuiFileNotFoundException.Create(const AFileName: AnsiString);
begin
  inherited Create('menu file not found: ' + string(AFileName));
  FFileName := AFileName;
end;

{ EGuiParseException }

constructor EGuiParseException.Create(const AFileName: AnsiString; const ALine: Integer; const AText: string);
begin
  inherited Create(Format('%s, line %d: %s', [string(AFileName), ALine, AText]));
  FFileName := AFileName;
  FLine := ALine;
end;

{ TGuiWindowDef }

class function TGuiWindowDef.Create: TGuiWindowDef;
var
  LIndex: Integer;
begin
  Result := Default(TGuiWindowDef);
  Result.BorderSize := 1;
  for LIndex := 0 to 3 do
    Result.ForeColor[LIndex] := 1.0;
  Result.Cinematic := -1;
end;

end.
