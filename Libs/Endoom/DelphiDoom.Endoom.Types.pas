{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - sizes, colors and the exception                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>Character cells in a row of the text screen</summary>
  ENDOOM_COLUMNS = 80;
  /// <summary>Rows of the text screen</summary>
  ENDOOM_ROWS = 25;
  /// <summary>Cells of the screen</summary>
  ENDOOM_CELLS = ENDOOM_COLUMNS * ENDOOM_ROWS;
  /// <summary>Bytes of the lump: a character and an attribute for each cell</summary>
  ENDOOM_LUMP_SIZE = ENDOOM_CELLS * 2;
  /// <summary>Width of a character, in pixels (the same for the height)</summary>
  ENDOOM_CELL_SIZE = 8;
  /// <summary>Width of the picture, in pixels</summary>
  ENDOOM_WIDTH = ENDOOM_COLUMNS * ENDOOM_CELL_SIZE;
  /// <summary>Height of the picture, in pixels (the screen is 640x200)</summary>
  ENDOOM_HEIGHT = ENDOOM_ROWS * ENDOOM_CELL_SIZE;
  /// <summary>Width of the picture of the font (DOSFONT): 16 characters of 8 pixels in a row</summary>
  ENDOOM_FONT_WIDTH = 128;
  /// <summary>Bytes of the font: 128x128 pixels, one byte each, 0 is the background</summary>
  ENDOOM_FONT_SIZE = ENDOOM_FONT_WIDTH * ENDOOM_FONT_WIDTH;
  /// <summary>Colors of a DOS text screen</summary>
  ENDOOM_COLOR_COUNT = 16;
  /// <summary>Entries of the palette that the 32 bit conversion reads</summary>
  ENDOOM_PALETTE_SIZE = 256;

  /// <summary>
  ///   The 16 colors of the text mode as $00RRGGBB: black, blue, green, cyan, red, magenta,
  ///   brown, light gray, dark gray, light blue, light green, light cyan, light red,
  ///   light magenta, yellow, white
  /// </summary>
  ENDOOM_COLORS: array[0..ENDOOM_COLOR_COUNT - 1] of Cardinal = (
    $000000, $0000AA, $00AA00, $00AAAA, $AA0000, $AA00AA, $AA5500, $AAAAAA,
    $555555, $5555FF, $55FF55, $55FFFF, $FF5555, $FF55FF, $FFFF55, $FFFFFF
  );

resourcestring
  SEndoomBadColorTable = 'ENDOOM: the table of the colors needs 16 entries, not %d';
  SEndoomBadPalette = 'ENDOOM: the palette needs 256 entries, not %d';
  SEndoomBadStride = 'ENDOOM: the row of the 32 bit picture needs at least 640 pixels, not %d';

type
  /// <summary>A wrong argument given to the ENDOOM renderer</summary>
  EEndoomException = class(Exception);

implementation

end.
