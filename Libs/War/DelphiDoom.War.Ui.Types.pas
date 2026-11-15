{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - types of the immediate user interface and scenes  }
{                                                                              }
{  Port of war1 (acoto87/war1), war_enums.h (WarKeys, WarMouseButtons,         }
{  WarCursorType), war_ui.h (the CreateUI*Args), war.h (IMUI_*), (c) 2019      }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.Types;

interface

uses
  System.SysUtils, DelphiDoom.War.Render.Types, DelphiDoom.War.Text.Types;

const
  /// <summary>IMUI_SPRITE_CACHE_SIZE of war.h</summary>
  WAR_IMUI_SPRITE_CACHE_SIZE = 64;
  /// <summary>IMUI_TOOLTIP_TEXT_MAX of war.h: the tooltip is cut to this length minus one</summary>
  WAR_IMUI_TOOLTIP_TEXT_MAX = 256;
  /// <summary>WAR_CURSOR_ARROW of war_enums.h: the cursors are records of DATA.WAR, the type is the record</summary>
  WAR_CURSOR_ARROW = 263;
  /// <summary>WAR_UI_CLICK of war_enums.h (audio id)</summary>
  WAR_AUDIO_UI_CLICK = 485;
  /// <summary>WAR_LOGO of war_enums.h (audio id)</summary>
  WAR_AUDIO_LOGO = 472;
  /// <summary>WAR_MUSIC_00 of war_enums.h (audio id)</summary>
  WAR_AUDIO_MUSIC_00 = 0;
  /// <summary>CHEAT_TEXT_MAX_LENGTH of war_cheats.h</summary>
  WAR_CHEAT_TEXT_MAX_LENGTH = 32;
  /// <summary>STATUS_TEXT_MAX_LENGTH of war_cheats.h (the tab of the cheat panel is checked against this one)</summary>
  WAR_STATUS_TEXT_MAX_LENGTH = 40;
  /// <summary>The text of a record that is not a resource (what an invalid WarSpriteResourceRef holds)</summary>
  WAR_INVALID_RESOURCE = -1;
  /// <summary>Seconds a cheat feedback stays</summary>
  WAR_CHEAT_FEEDBACK_SECONDS = 3.0;
  /// <summary>WAR_COLOR_FOR the colors of war_color.h and war_font.h as the bytes R G B A (the C packs them as ABGR words)</summary>
  WAR_FONT_NORMAL_COLOR: TWarRgba = (R: $EF; G: $FF; B: $DB; A: $FF);
  WAR_FONT_HIGHLIGHT_COLOR: TWarRgba = (R: $FF; G: $E3; B: $49; A: $FF);
  WAR_COLOR_WHITE: TWarRgba = (R: 255; G: 255; B: 255; A: 255);
  /// <summary>WAR_COLOR_YELLOW is 0xFFC7C700: as bytes R=0, G=199, B=199, so it is a cyan (a defect of the C kept)</summary>
  WAR_COLOR_YELLOW: TWarRgba = (R: 0; G: $C7; B: $C7; A: $FF);

type
  /// <summary>WarKeys of war_enums.h, in the order of the original</summary>
  TWarKey = (wkNone, wkSpace, wkApostrophe, wkAsterisk, wkPlus, wkComma, wkMinus, wkPeriod, wkSlash,
    wk0, wk1, wk2, wk3, wk4, wk5, wk6, wk7, wk8, wk9, wkSemicolon, wkEqual,
    wkA, wkB, wkC, wkD, wkE, wkF, wkG, wkH, wkI, wkJ, wkK, wkL, wkM, wkN, wkO, wkP, wkQ, wkR, wkS, wkT, wkU, wkV,
    wkW, wkX, wkY, wkZ, wkLeftBracket, wkBackslash, wkRightBracket, wkGraveAccent,
    wkEsc, wkEnter, wkTab, wkBackspace, wkInsert, wkDelete, wkRight, wkLeft, wkDown, wkUp,
    wkPageUp, wkPageDown, wkHome, wkEnd, wkF1, wkF2, wkF3, wkF4, wkF5, wkF6, wkF7, wkF8, wkF9, wkF10, wkF11, wkF12,
    wkShift, wkCtrl, wkAlt);

  /// <summary>WarMouseButtons</summary>
  TWarMouseButton = (wmbLeft, wmbRight);

  /// <summary>WarSceneType, in the order of the original (the download scene is not ported)</summary>
  TWarSceneType = (wstDownload, wstBlizzard, wstMainMenu, wstBriefing, wstMap);

  /// <summary>WarMainMenuPanel</summary>
  TWarMenuPanel = (wmpMain, wmpSinglePlayer, wmpCustomGame);

  /// <summary>The state of a button or a key: held and the transitions of this frame (WarInputState)</summary>
  TWarInputState = record
    Held: Boolean;
    JustPressed: Boolean;
    JustReleased: Boolean;
  end;

  /// <summary>CreateUITextArgs; Default gives CREATE_UI_TEXT_ARGS_INIT with nothing set</summary>
  TWarUiTextArgs = record
    PositionX: Single;
    PositionY: Single;
    ScaleX: Single;
    ScaleY: Single;
    Text: AnsiString;
    FontIndex: Integer;
    FontSize: Single;
    LineHeight: Single;
    FontColor: TWarRgba;
    HighlightColor: TWarRgba;
    HighlightIndex: Integer;
    HighlightCount: Integer;
    BoundingsX: Single;
    BoundingsY: Single;
    HorizontalAlign: TWarTextAlignment;
    VerticalAlign: TWarTextAlignment;
    LineAlign: TWarTextAlignment;
    Wrapping: TWarTextWrapping;
    Trimming: TWarTextTrimming;
    Multiline: Boolean;
    class function Default: TWarUiTextArgs; static;
  end;

  /// <summary>CreateUIRectArgs</summary>
  TWarUiRectArgs = record
    PositionX: Single;
    PositionY: Single;
    ScaleX: Single;
    ScaleY: Single;
    SizeX: Single;
    SizeY: Single;
    Color: TWarRgba;
    class function Default: TWarUiRectArgs; static;
  end;

  /// <summary>CreateUIImageArgs: SpriteRef is the index of the record in DATA.WAR (WAR_INVALID_RESOURCE for none)</summary>
  TWarUiImageArgs = record
    SpriteRef: Integer;
    PositionX: Single;
    PositionY: Single;
    ScaleX: Single;
    ScaleY: Single;
    class function Default: TWarUiImageArgs; static;
  end;

  /// <summary>CreateUITextButtonArgs (the click handler is not a field: the button returns true when it is clicked)</summary>
  TWarUiTextButtonArgs = record
    PositionX: Single;
    PositionY: Single;
    ScaleX: Single;
    ScaleY: Single;
    FontIndex: Integer;
    FontSize: Single;
    Text: AnsiString;
    LineHeight: Single;
    FontColor: TWarRgba;
    HighlightColor: TWarRgba;
    HighlightIndex: Integer;
    HighlightCount: Integer;
    HorizontalAlign: TWarTextAlignment;
    VerticalAlign: TWarTextAlignment;
    LineAlign: TWarTextAlignment;
    Wrapping: TWarTextWrapping;
    Trimming: TWarTextTrimming;
    BackgroundNormal: Integer;
    BackgroundPressed: Integer;
    Interactive: Boolean;
    HotKey: TWarKey;
    Tooltip: AnsiString;
    TooltipHighlightIndex: Integer;
    TooltipHighlightCount: Integer;
    Gold: Integer;
    Wood: Integer;
    class function Default: TWarUiTextButtonArgs; static;
  end;

  /// <summary>CreateUIImageButtonArgs</summary>
  TWarUiImageButtonArgs = record
    BackgroundNormal: Integer;
    BackgroundPressed: Integer;
    Foreground: Integer;
    PositionX: Single;
    PositionY: Single;
    ScaleX: Single;
    ScaleY: Single;
    Interactive: Boolean;
    HotKey: TWarKey;
    Tooltip: AnsiString;
    TooltipHighlightIndex: Integer;
    TooltipHighlightCount: Integer;
    Gold: Integer;
    Wood: Integer;
    ForegroundFrameIndex: Integer;
    class function Default: TWarUiImageButtonArgs; static;
  end;

resourcestring
  SWarUiFontIndex = 'The font %d does not exist (the fonts are 0 and 1)';
  SWarUiResourceType = 'The record %d is not an image, a sprite or a cursor';
  SWarUiFrameIndex = 'The frame %d of the record %d is not in the sprite, that has %d';

implementation

{ TWarUiTextArgs }

class function TWarUiTextArgs.Default: TWarUiTextArgs;
begin
  Result := System.Default(TWarUiTextArgs);
  Result.ScaleX := 1;
  Result.ScaleY := 1;
  Result.FontSize := 10;
  Result.FontColor := WAR_FONT_NORMAL_COLOR;
  Result.HighlightColor := WAR_FONT_HIGHLIGHT_COLOR;
  Result.HighlightIndex := WAR_NO_HIGHLIGHT;
  Result.VerticalAlign := wtaTop;
  Result.LineAlign := wtaLeft;
  Result.Wrapping := wtwNone;
end;

{ TWarUiRectArgs }

class function TWarUiRectArgs.Default: TWarUiRectArgs;
begin
  Result := System.Default(TWarUiRectArgs);
  Result.ScaleX := 1;
  Result.ScaleY := 1;
end;

{ TWarUiImageArgs }

class function TWarUiImageArgs.Default: TWarUiImageArgs;
begin
  Result := System.Default(TWarUiImageArgs);
  Result.SpriteRef := WAR_INVALID_RESOURCE;
  Result.ScaleX := 1;
  Result.ScaleY := 1;
end;

{ TWarUiTextButtonArgs }

class function TWarUiTextButtonArgs.Default: TWarUiTextButtonArgs;
begin
  Result := System.Default(TWarUiTextButtonArgs);
  Result.ScaleX := 1;
  Result.ScaleY := 1;
  Result.FontSize := 10;
  Result.FontColor := WAR_FONT_NORMAL_COLOR;
  Result.HighlightColor := WAR_FONT_HIGHLIGHT_COLOR;
  Result.HighlightIndex := WAR_NO_HIGHLIGHT;
  Result.BackgroundNormal := WAR_INVALID_RESOURCE;
  Result.BackgroundPressed := WAR_INVALID_RESOURCE;
  Result.Interactive := True;
  Result.HotKey := wkNone;
  Result.TooltipHighlightIndex := WAR_NO_HIGHLIGHT;
  Result.HorizontalAlign := wtaCenter;
  Result.VerticalAlign := wtaMiddle;
end;

{ TWarUiImageButtonArgs }

class function TWarUiImageButtonArgs.Default: TWarUiImageButtonArgs;
begin
  Result := System.Default(TWarUiImageButtonArgs);
  Result.BackgroundNormal := WAR_INVALID_RESOURCE;
  Result.BackgroundPressed := WAR_INVALID_RESOURCE;
  Result.Foreground := WAR_INVALID_RESOURCE;
  Result.ScaleX := 1;
  Result.ScaleY := 1;
  Result.Interactive := True;
  Result.HotKey := wkNone;
  Result.TooltipHighlightIndex := WAR_NO_HIGHLIGHT;
end;

end.
