{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - types of the fonts                                }
{                                                                              }
{  Port of war1 (acoto87/war1), WarFontData of war_font.h, (c) 2019 Alejandro  }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Font.Types;

interface

const
  /// <summary>Fonts of the game: 0 for the texts in game, 1 for the menus</summary>
  WAR_FONT_COUNT = 2;
  /// <summary>Glyphs of a font: the printable ASCII characters from the space (32) to the tilde (126)</summary>
  WAR_FONT_GLYPH_COUNT = 95;

type
  /// <summary>Where a glyph is in the image of its font, in pixels of the image (rect of the original)</summary>
  TWarGlyph = record
    X: Word;
    Y: Word;
    Width: Word;
    Height: Word;
  end;

  /// <summary>The glyphs of a font, from the space to the tilde</summary>
  TWarGlyphTable = array[0..WAR_FONT_GLYPH_COUNT - 1] of TWarGlyph;

  /// <summary>
  ///   WarFontData: the size of the image of the font (the fonts were drawn in 64 x 64 and 64 x 96 pixels and
  ///   the game used them 8 times larger), the height of a line, the space between two glyphs and the glyphs
  /// </summary>
  TWarFontData = record
    SpriteWidth: Integer;
    SpriteHeight: Integer;
    LineHeight: Integer;
    Advance: Integer;
    Glyphs: TWarGlyphTable;
  end;

implementation

end.
