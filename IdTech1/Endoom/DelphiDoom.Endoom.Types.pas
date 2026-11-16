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
  System.SysUtils, System.Math;

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

  /// <summary>Bits of the attribute of a cell: the foreground color (0..15)</summary>
  ENDOOM_FOREGROUND_MASK = $0F;
  /// <summary>Bits of the attribute of a cell: the background color (0..7)</summary>
  ENDOOM_BACKGROUND_MASK = $70;
  /// <summary>Bit of the attribute of a cell: the character blinks</summary>
  ENDOOM_BLINK_MASK = $80;
  /// <summary>Shift of the background color in the attribute</summary>
  ENDOOM_BACKGROUND_SHIFT = 4;
  /// <summary>Colors that a background can have (the text mode has 3 bits for it)</summary>
  ENDOOM_BACKGROUND_COLOR_COUNT = 8;

resourcestring
  SEndoomBadColorTable = 'ENDOOM: the table of the colors needs 16 entries, not %d';
  SEndoomBadPalette = 'ENDOOM: the palette needs 256 entries, not %d';
  SEndoomBadStride = 'ENDOOM: the row of the 32 bit picture needs at least 640 pixels, not %d';
  SEndoomBadCell = 'ENDOOM: the cell (%d, %d) is outside of the screen';
  SEndoomBadColorIndex = 'ENDOOM: the color %d does not exist (a foreground has 16, a background 8)';
  SEndoomBadScreenSize = 'ENDOOM: a text screen needs %d bytes, not %d';
  SEndoomBadBlock = 'ENDOOM: a block of %dx%d cells needs %d cells, not %d';

type
  /// <summary>A wrong argument given to the ENDOOM classes</summary>
  EEndoomException = class(Exception);

  /// <summary>
  ///   A cell of the text screen as it is in the lump: the character (the code of the font, 0 is
  ///   an empty cell) and the attribute (see ENDOOM_*_MASK)
  /// </summary>
  TEndoomCell = packed record
    Code: Byte;
    Attributes: Byte;
  end;

  /// <summary>A rectangle of cells; both corners are inside the rectangle</summary>
  TEndoomRect = record
    Left: Integer;
    Top: Integer;
    Right: Integer;
    Bottom: Integer;
    /// <summary>The rectangle between two corners given in any order</summary>
    class function Between(AX1, AY1, AX2, AY2: Integer): TEndoomRect; static;
    function Width: Integer;
    function Height: Integer;
    function Contains(AX, AY: Integer): Boolean;
  end;

  /// <summary>A rectangle of cells taken from a screen (a selection that was copied)</summary>
  TEndoomBlock = record
    Width: Integer;
    Height: Integer;
    Cells: TArray<TEndoomCell>;
  end;

  /// <summary>The characters that draw the frame of a rectangle (the old tools had five)</summary>
  TEndoomFrameStyle = (
    /// <summary>Single lines</summary>
    efsSingle,
    /// <summary>Double horizontal lines, single vertical ones</summary>
    efsDoubleHorizontal,
    /// <summary>Single horizontal lines, double vertical ones</summary>
    efsDoubleVertical,
    /// <summary>Double lines</summary>
    efsDouble,
    /// <summary>Full blocks</summary>
    efsBlock
  );

implementation

{ TEndoomRect }

class function TEndoomRect.Between(AX1, AY1, AX2, AY2: Integer): TEndoomRect;
begin
  Result.Left := Min(AX1, AX2);
  Result.Right := Max(AX1, AX2);
  Result.Top := Min(AY1, AY2);
  Result.Bottom := Max(AY1, AY2);
end;

function TEndoomRect.Width: Integer;
begin
  Result := Right - Left + 1;
end;

function TEndoomRect.Height: Integer;
begin
  Result := Bottom - Top + 1;
end;

function TEndoomRect.Contains(AX, AY: Integer): Boolean;
begin
  Result := (AX >= Left) and (AX <= Right) and (AY >= Top) and (AY <= Bottom);
end;

end.
