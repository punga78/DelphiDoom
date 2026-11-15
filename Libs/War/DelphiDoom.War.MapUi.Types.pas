{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - constants and types of the map interface          }
{                                                                              }
{  Port of war1 (acoto87/war1), war.h and war_map.h (the panels of the map and  }
{  the state of its interface), (c) 2019 Alejandro Coto Gutierrez, zlib        }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version, not    }
{  the original.                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.Types;

interface

uses
  DelphiDoom.War.Render.Types, DelphiDoom.War.Text.Types, DelphiDoom.War.Ui.Types;

const
  /// <summary>MAP_WIDTH and MAP_HEIGHT of war.h: the map in pixels</summary>
  WAR_MAPUI_MAP_PIXELS = 1024;
  /// <summary>MAP_SELECTION_DRAG_THRESHOLD of war_map.h: pixels the mouse must move for a drag to be a rectangle</summary>
  WAR_MAPUI_DRAG_THRESHOLD = 3;
  /// <summary>WAR_CURSOR_* of war_enums.h (the records of the cursors of DATA.WAR)</summary>
  WAR_CURSOR_YELLOW_CROSSHAIR = 265;
  WAR_CURSOR_RED_CROSSHAIR = 266;
  WAR_CURSOR_MAGNIFYING_GLASS = 268;
  WAR_CURSOR_GREEN_CROSSHAIR = 269;
  WAR_CURSOR_ARROW_UP = 271;
  WAR_CURSOR_ARROW_UP_RIGHT = 272;
  WAR_CURSOR_ARROW_RIGHT = 273;
  WAR_CURSOR_ARROW_BOTTOM_RIGHT = 274;
  WAR_CURSOR_ARROW_BOTTOM = 275;
  WAR_CURSOR_ARROW_BOTTOM_LEFT = 276;
  WAR_CURSOR_ARROW_LEFT = 277;
  WAR_CURSOR_ARROW_UP_LEFT = 278;
  /// <summary>WAR_SPEED_NORMAL of war_enums.h (WarMapSpeed: slowest 0 ... fastest 4)</summary>
  WAR_SPEED_SLOWEST = 0;
  WAR_SPEED_SLOW = 1;
  WAR_SPEED_NORMAL = 2;
  WAR_SPEED_FASTER = 3;
  WAR_SPEED_FASTEST = 4;

  /// <summary>WAR_COLOR_GREEN_SELECTION, WAR_COLOR_RED_SELECTION, WAR_COLOR_WHITE_SELECTION (packed ABGR words of war_color.h)</summary>
  WAR_MAPUI_GREEN_SELECTION: TWarRgba = (R: 0; G: 199; B: 0; A: 255);
  WAR_MAPUI_RED_SELECTION: TWarRgba = (R: 199; G: 0; B: 0; A: 255);
  WAR_MAPUI_WHITE_SELECTION: TWarRgba = (R: 199; G: 199; B: 199; A: 255);
  /// <summary>WAR_COLOR_BLUE_INVULNERABLE (0xFFC70000)</summary>
  WAR_MAPUI_BLUE_INVULNERABLE: TWarRgba = (R: 0; G: 0; B: 199; A: 255);
  /// <summary>WAR_COLOR_GRAY_TRANSPARENT (0x80808080) and WAR_COLOR_RED_TRANSPARENT (0x80000080)</summary>
  WAR_MAPUI_GRAY_TRANSPARENT: TWarRgba = (R: 128; G: 128; B: 128; A: 128);
  WAR_MAPUI_RED_TRANSPARENT: TWarRgba = (R: 128; G: 0; B: 0; A: 128);
  /// <summary>WAR_COLOR_RED, WAR_COLOR_GREEN of war_color.h and the yellow of the life bars (0xFFC7C700 is a cyan: see Ui.Types)</summary>
  WAR_MAPUI_RED: TWarRgba = (R: 199; G: 0; B: 0; A: 255);
  WAR_MAPUI_GREEN: TWarRgba = (R: 0; G: 199; B: 0; A: 255);

type
  /// <summary>WarMapDragStatus</summary>
  TWarDragStatus = (wdsNone, wdsStarted, wdsActive, wdsReleased);

  /// <summary>WarMapEditMode: what a click on the map does when the cheats "Edit", "Add unit", "Rain of fire", ... are on</summary>
  TWarMapEditMode = (wemNone, wemTrees, wemWalls, wemRoads, wemRuins, wemRainOfFire, wemPoisonCloud, wemRaiseDead,
    wemAddUnit);

  /// <summary>WarMapMenuState: which menu of the map is open (the original keeps it in map->menuState)</summary>
  TWarMenuState = (wmsNone, wmsMain, wmsOptions, wmsObjectives, wmsRestart, wmsGameOver, wmsQuit, wmsDemoEnd);

  /// <summary>
  ///   WarMapSettings: the speed of the game and of the scrolling (WarMapSpeed 0..4) and the volumes (0..100) that the options
  ///   menu of the map shows and changes
  /// </summary>
  TWarMapSettings = record
    GameSpeed: Integer;
    MouseScrollSpeed: Integer;
    KeyScrollSpeed: Integer;
    MusicVolume: Integer;
    SoundVolume: Integer;
  end;

  /// <summary>
  ///   The panels of the map (map->ui): where the interface and the map are on the screen of 320 x 200. All are fixed
  /// </summary>
  TWarMapPanels = record
    LeftTop: TWarRectF;
    LeftBottom: TWarRectF;
    RightPanel: TWarRectF;
    TopPanel: TWarRectF;
    BottomPanel: TWarRectF;
    MapPanel: TWarRectF;
    MinimapPanel: TWarRectF;
    MenuPanel: TWarRectF;
    MessagePanel: TWarRectF;
    SaveLoadPanel: TWarRectF;
    class function Standard: TWarMapPanels; static;
  end;

type
  /// <summary>WarUnitCommandData as the panel shows it: the image (a frame of record 361), the key, the tooltip and its prices</summary>
  TWarCommandSlot = record
    /// <summary>The command of the model that the button gives (WarUnitCommandType); 0 none</summary>
    Command: Integer;
    FrameIndex: Integer;
    HotKey: TWarKey;
    Tooltip: AnsiString;
    HighlightIndex: Integer;
    HighlightCount: Integer;
    Gold: Integer;
    Wood: Integer;
  end;

  /// <summary>map->commandPanel: six buttons and four lines of text of the panel at the bottom left</summary>
  TWarCommandPanel = record
    SlotsActive: array[0..5] of Boolean;
    Slots: array[0..5] of TWarCommandSlot;
    TextsVisible: array[0..3] of Boolean;
    Texts: array[0..3] of AnsiString;
    TextsHighlightIndex: array[0..3] of Integer;
    TextsHighlightCount: array[0..3] of Integer;
    /// <summary>Everything off: what updateCommandButtons does first</summary>
    procedure Clear;
  end;

  /// <summary>map->status: the line the status bar shows (the tooltip of what the mouse is on, or a message)</summary>
  TWarStatusLine = record
    Text: AnsiString;
    HighlightIndex: Integer;
    HighlightCount: Integer;
    Gold: Integer;
    Wood: Integer;
  end;

/// <summary>rect_containsf: the edges count</summary>
function WarRectContains(const ARect: TWarRectF; AX, AY: Single): Boolean; inline;
/// <summary>recti(x, y, w, h)</summary>
function WarRectI(AX, AY, AWidth, AHeight: Integer): TWarRectF; inline;

implementation

function WarRectContains(const ARect: TWarRectF; AX, AY: Single): Boolean;
var
  LRight: Single;
  LBottom: Single;
begin
  LRight := ARect.X + ARect.Width;
  LBottom := ARect.Y + ARect.Height;
  Result := (AX >= ARect.X) and (AX <= LRight) and (AY >= ARect.Y) and (AY <= LBottom);
end;

function WarRectI(AX, AY, AWidth, AHeight: Integer): TWarRectF;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Width := AWidth;
  Result.Height := AHeight;
end;

{ TWarCommandPanel }

procedure TWarCommandPanel.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 5 do
  begin
    SlotsActive[LIndex] := False;
    Slots[LIndex] := Default(TWarCommandSlot);
  end;
  for LIndex := 0 to 3 do
  begin
    TextsVisible[LIndex] := False;
    Texts[LIndex] := '';
    TextsHighlightIndex[LIndex] := WAR_NO_HIGHLIGHT;
    TextsHighlightCount[LIndex] := 0;
  end;
end;

{ TWarMapPanels }

class function TWarMapPanels.Standard: TWarMapPanels;
begin
  Result.LeftTop := WarRectI(0, 0, 72, 72);
  Result.LeftBottom := WarRectI(0, 72, 72, 128);
  Result.RightPanel := WarRectI(312, 0, 8, 200);
  Result.TopPanel := WarRectI(72, 0, 240, 12);
  Result.BottomPanel := WarRectI(72, 188, 240, 12);
  Result.MapPanel := WarRectI(72, 12, 240, 176);
  Result.MinimapPanel := WarRectI(3, 6, 64, 64);
  Result.MenuPanel := WarRectI(84, 32, 152, 136);
  Result.MessagePanel := WarRectI(17, 76, 286, 48);
  Result.SaveLoadPanel := WarRectI(48, 27, 223, 146);
end;

end.
