{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - types of the text                                 }
{                                                                              }
{  Port of war1 (acoto87/war1), war_font.h and war_enums.h (WarTextAlignment,  }
{  WarTextWrapping, WarTextTrimming, WarFontParams), (c) 2019 Alejandro Coto   }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Text.Types;

interface

uses
  System.SysUtils, DelphiDoom.War.Font.Types, DelphiDoom.War.Render.Types;

const
  /// <summary>NO_HIGHLIGHT of war_font.h</summary>
  WAR_NO_HIGHLIGHT = -1;
  /// <summary>ALL_HIGHLIGHT of war_font.h: the whole text in the highlight color</summary>
  WAR_ALL_HIGHLIGHT = -2;
  /// <summary>TAB_WIDTH of war_font.h: a tab is this many spaces</summary>
  WAR_TAB_WIDTH = 2;
  /// <summary>MAX_LINES of war_font.h: the most lines of a text</summary>
  WAR_MAX_LINES = 48;

type
  /// <summary>WarTextAlignment (the values are the ones of the original)</summary>
  TWarTextAlignment = (wtaLeft, wtaCenter, wtaRight, wtaTop, wtaMiddle, wtaBottom);

  /// <summary>WarTextWrapping</summary>
  TWarTextWrapping = (wtwNone, wtwChar);

  /// <summary>WarTextTrimming</summary>
  TWarTextTrimming = (wttNone, wttSpaces, wttAll);

  /// <summary>
  ///   WarFontParams (without the sprite): how a text is laid out. The size is in the units of the drawing, the glyphs
  ///   are scaled by FontSize / FontData.LineHeight. LineHeight 0 means the one of the font
  /// </summary>
  TWarFontParams = record
    FontData: TWarFontData;
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
  end;

  /// <summary>WarTextSpan: a line of the text (from where, how many characters, how wide)</summary>
  TWarTextSpan = record
    Start: Integer;
    Length: Integer;
    Width: Single;
  end;

  /// <summary>The size of a text, or an offset (vec2)</summary>
  TWarTextSize = record
    X: Single;
    Y: Single;
  end;

resourcestring
  SWarTextNoGlyph = 'The character %d has no glyph in the font';
  SWarTextOutside = 'The span of %d characters from %d goes past the end of the text, that has %d';

implementation

end.
