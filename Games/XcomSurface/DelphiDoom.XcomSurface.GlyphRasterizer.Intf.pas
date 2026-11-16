{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - the contract of who draws the characters  }
{  of a font of the system (GDI in the program, a fake in the tests)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.GlyphRasterizer.Intf;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Glyph.Types;

type
  /// <summary>Draws the characters of one font at one size: the only part of the fonts of the system that needs the system</summary>
  IXcomGlyphRasterizer = interface
    ['{2F6B9D14-8A3E-4C75-B0D2-71E5A9C3F846}']
    /// <summary>Whether the font itself has the character (a font that the system would take from another one does not)</summary>
    function HasGlyph(ACode: Cardinal): Boolean;
    /// <summary>
    ///   The pixels of the character that have ink and how much each is covered (0 to 255); false when the
    ///   character has no ink (a space) or cannot be drawn. Top is counted from the same row for every character
    /// </summary>
    function Rasterize(ACode: Cardinal; out AGlyph: TXcomGlyphBitmap): Boolean;
    /// <summary>
    ///   The row of the baseline of the font, counted as Top is: the same text drawn at another scale is lined
    ///   up on it
    /// </summary>
    function Baseline: Integer;
  end;

  /// <summary>Opens the fonts of the system</summary>
  IXcomGlyphRasterizerFactory = interface
    ['{9C41E7A3-5D02-4B8F-A6E1-3B7F0D2C8A59}']
    /// <summary>
    ///   The rasterizer of a font, or nil with the reason when the font is not there. AScale multiplies the size:
    ///   1 for the 320 x 200 screen; a larger whole number gives the same characters for a screen that many times
    ///   larger (the text at the real resolution of the display, which the game does not draw yet)
    /// </summary>
    function CreateRasterizer(const AFace: TXcomFontFace; AScale: Integer; out AReason: string): IXcomGlyphRasterizer;
  end;

implementation

end.
