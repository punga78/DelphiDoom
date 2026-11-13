{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - contract of the font metrics                      }
{                                                                              }
{  Port of war1 (acoto87/war1), war_font.h, (c) 2019 Alejandro Coto            }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an         }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Font.Intf;

interface

uses
  DelphiDoom.War.Font.Types;

type
  /// <summary>
  ///   Where the glyphs of the two fonts of the game are in the image of each. The images are not in DATA.WAR:
  ///   the remake draws them in two PNG files of its own (war1_font_1.png, war1_font_2.png), that the
  ///   rendering (#197) loads
  /// </summary>
  IWarFontMetrics = interface
    ['{C1B6E083-5F2D-47A9-8E4B-6A3D90F7E512}']
    function GetFontCount: Integer;
    /// <summary>getFontData: the data of the font AFont; False if it is not 0 or 1</summary>
    function TryGetFont(AFont: Integer; out AData: TWarFontData): Boolean;
    /// <summary>
    ///   The index of the glyph of a character (getCharIndex): the characters above 32 are the glyph
    ///   Ord(AChar) - 32; the space, the control characters and, as the original reads char with a sign, those
    ///   from 128 up are the glyph 0. A result outside 0..94 (a control character from 1 to 31 or the DEL) is
    ///   not a glyph: the original read the table past its ends
    /// </summary>
    function GlyphIndex(AChar: AnsiChar): Integer;
    /// <summary>The glyph of a character in a font; False if the font does not exist or the character has no glyph</summary>
    function TryGetGlyph(AFont: Integer; AChar: AnsiChar; out AGlyph: TWarGlyph): Boolean;
    property FontCount: Integer read GetFontCount;
  end;

implementation

end.
