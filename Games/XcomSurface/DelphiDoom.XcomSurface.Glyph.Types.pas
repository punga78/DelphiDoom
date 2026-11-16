{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - the types of the glyphs drawn from a      }
{  font of the system (a TrueType font in place of the pictures of the game)    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.Glyph.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>The brightest and the darkest value of a pixel of a font of the game (0 is transparent)</summary>
  XCOM_GLYPH_LEVEL_FIRST = 1;
  XCOM_GLYPH_LEVEL_LAST = 5;
  /// <summary>The outline of the fonts of the game: the pixels beside the body and the ones on its corners</summary>
  XCOM_GLYPH_LEVEL_OUTLINE = 4;
  XCOM_GLYPH_LEVEL_CORNER = 5;
  /// <summary>
  ///   How much larger than the cells of the original font a font may be when nothing is said: this percent, or
  ///   this many pixels when they are more (the fonts of the geoscape have cells 5 pixels wide: a quarter of them
  ///   is one pixel, and no font of the system fits)
  /// </summary>
  XCOM_FONT_DEFAULT_TOLERANCE = 25;
  XCOM_FONT_DEFAULT_ALLOWANCE = 2;
  /// <summary>The value of Tolerance that asks for the default above</summary>
  XCOM_FONT_AUTO_TOLERANCE = -1;
  /// <summary>The smallest size a font is reduced to when it is asked to shrink until it fits</summary>
  XCOM_FONT_SMALLEST_SIZE = 4;

type
  /// <summary>The font that replaces the pictures: a font of Windows by name, or a file to register first</summary>
  TXcomFontFace = record
    /// <summary>The family name ("Tahoma"); empty with a file: the name written in the file</summary>
    Name: string;
    /// <summary>A .ttf file to register for this program only; empty for a font that is installed</summary>
    FileName: string;
    /// <summary>
    ///   Which font of a collection file (.ttc) when no name is given: the family of that font is used (0, the
    ///   default, the first one). A single font file has only the index 0
    /// </summary>
    FaceIndex: Integer;
    /// <summary>The height of the em square in pixels of the 320 x 200 screen</summary>
    Size: Integer;
    Bold: Boolean;
    /// <summary>
    ///   Gray levels from the outlines of the font; without it the pixels the system draws, each either in the
    ///   character or not: right for the bitmap fonts and for a font at a size it is hinted for (below about 9
    ///   pixels Tahoma and Verdana lose pieces of the letters), wrong for the rest
    /// </summary>
    Antialias: Boolean;
  end;

  /// <summary>
  ///   A character as a rasterizer draws it: the rectangle of the pixels that have ink, row after row, with how
  ///   much each pixel is covered (0 nothing, 255 all), or after the reduction with the levels of the game (0 to 5)
  /// </summary>
  TXcomGlyphBitmap = record
    Width: Integer;
    Height: Integer;
    /// <summary>The row of the line where the first row of the rectangle goes (the same origin for every character of a font)</summary>
    Top: Integer;
    Pixels: TBytes;
    /// <summary>The pixel, or 0 outside the rectangle</summary>
    function At(AX, AY: Integer): Byte;
    class function Make(AWidth, AHeight, ATop: Integer): TXcomGlyphBitmap; static;
  end;

  /// <summary>Whether the characters get the dark outline of the big and small fonts of the game</summary>
  TXcomGlyphOutline = (goAuto, goOn, goOff);

  /// <summary>What the options say for one font of the game (FONT_BIG, FONT_SMALL, FONT_GEO_BIG, FONT_GEO_SMALL)</summary>
  TXcomFontOverlaySettings = record
    /// <summary>The id of the font in Font.dat</summary>
    FontId: string;
    Face: TXcomFontFace;
    /// <summary>goAuto: as the original font (outlined when its pictures use the levels of the outline)</summary>
    Outline: TXcomGlyphOutline;
    /// <summary>The pixels between two characters; used only with HasSpacing, otherwise derived from the original</summary>
    Spacing: Integer;
    HasSpacing: Boolean;
    /// <summary>
    ///   How much taller or wider than the original cell the font may be, in percent; XCOM_FONT_AUTO_TOLERANCE (what
    ///   Make gives): the default percent or the default pixels, whichever allows more
    /// </summary>
    Tolerance: Integer;
    /// <summary>
    ///   A font too tall or too wide for the cells is tried again one pixel smaller, down to
    ///   XCOM_FONT_SMALLEST_SIZE, instead of being refused at once
    /// </summary>
    Shrink: Boolean;
    /// <summary>Rows added to the position of every character (positive: lower)</summary>
    OffsetY: Integer;
    class function Make(const AFontId, AName: string; ASize: Integer): TXcomFontOverlaySettings; static;
  end;

  /// <summary>Why a font of the system was not used for a font of the game</summary>
  TXcomFontOverlayRefusal = (frNone, frNoGlyphs, frTooTall, frTooWide);

  /// <summary>What happened when a font of the system was laid over a font of the game</summary>
  TXcomFontOverlayReport = record
    Refusal: TXcomFontOverlayRefusal;
    /// <summary>The characters now drawn with the font of the system</summary>
    Replaced: Integer;
    /// <summary>The characters the font of the system does not have (or draws empty): they stay the original ones</summary>
    Missing: Integer;
    /// <summary>The characters wider than the tolerance allows: they stay the original ones</summary>
    TooWide: Integer;
    /// <summary>The characters that lost rows above or below the cell</summary>
    Clipped: Integer;
    /// <summary>The height and the largest width of the reference characters (the printable ASCII ones), outline included</summary>
    Height: Integer;
    Width: Integer;
    /// <summary>The limits they were compared with</summary>
    HeightLimit: Integer;
    WidthLimit: Integer;
    /// <summary>
    ///   What the same text drawn at another scale needs to fall on the same cells: the first picture that was
    ///   added, the row of the rasterizer that is the first row of a cell, the row of its baseline, and whether
    ///   the characters got the outline
    /// </summary>
    FirstImage: Integer;
    LineTop: Integer;
    Baseline: Integer;
    Outlined: Boolean;
  end;

implementation

{ TXcomGlyphBitmap }

function TXcomGlyphBitmap.At(AX, AY: Integer): Byte;
begin
  if (AX < 0) or (AY < 0) or (AX >= Width) or (AY >= Height) then
    Exit(0);
  Result := Pixels[AY * Width + AX];
end;

class function TXcomGlyphBitmap.Make(AWidth, AHeight, ATop: Integer): TXcomGlyphBitmap;
begin
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.Top := ATop;
  Result.Pixels := nil;
  SetLength(Result.Pixels, AWidth * AHeight);
end;

{ TXcomFontOverlaySettings }

class function TXcomFontOverlaySettings.Make(const AFontId, AName: string; ASize: Integer): TXcomFontOverlaySettings;
begin
  Result := Default(TXcomFontOverlaySettings);
  Result.FontId := AFontId;
  Result.Face.Name := AName;
  Result.Face.Size := ASize;
  Result.Face.Antialias := True;
  Result.Outline := goAuto;
  Result.Tolerance := XCOM_FONT_AUTO_TOLERANCE;
end;

end.
