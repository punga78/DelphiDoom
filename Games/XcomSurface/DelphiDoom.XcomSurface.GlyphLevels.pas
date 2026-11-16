{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - reduces the coverage of a rasterized      }
{  character to the five levels of the fonts of the game                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.GlyphLevels;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Glyph.Types;

type
  /// <summary>
  ///   The pixels of a font of the game are 0 (transparent) or 1 to 5, an offset in the shades of the color of the
  ///   text: 1 the brightest. The big and small fonts draw the body with 1 and 2 and put around it a dark outline
  ///   (4 beside the body, 5 on its corners); the fonts of the geoscape have no outline and only use 1 and 2. A
  ///   rasterized character has 256 levels of coverage and is brought to the same convention: the body takes the
  ///   levels 1 to 3 and the levels 4 and 5 are left to the outline (on the buttons of the geoscape they are
  ///   darker than the background: a half covered pixel drawn with them is a dark dot, not a lighter edge).
  ///   The thresholds are low on purpose: at the sizes of a 320 x 200 screen a stroke is thinner than a pixel,
  ///   and with a threshold at half coverage the diagonals of x, w and M disappeared; a pixel of level 3 beside
  ///   an outline of level 4 is nearly invisible, so most of the body must be 1 or 2
  /// </summary>
  TXcomGlyphLevels = class sealed
  strict private
    /// <summary>Without the rows and the columns on the sides that have no pixel; nothing left gives a size of 0</summary>
    class function Trim(const AGlyph: TXcomGlyphBitmap): TXcomGlyphBitmap; static;
  public
    const
      /// <summary>The least coverage of a pixel of the body (level 3), and the least of the levels 2 and 1</summary>
      BODY_COVERAGE = 40;
      BODY_LEVEL_2 = 72;
      BODY_LEVEL_1 = 120;
      BODY_LEVEL_LAST = 3;
    /// <summary>
    ///   The level of a pixel of the body, or 0 when it is covered too little to be drawn. A character without
    ///   antialiasing (coverage 0 or 255) is all 1
    /// </summary>
    class function LevelOf(ACoverage: Byte): Byte; static;
    /// <summary>
    ///   The character with the levels of the game. With AOutline the result is a pixel larger on every side
    ///   (Top one row higher): the pixels that are not body and touch it by a side are 4, by a corner only 5
    /// </summary>
    class function Reduce(const AGlyph: TXcomGlyphBitmap; AOutline: Boolean): TXcomGlyphBitmap; static;
  end;

implementation

class function TXcomGlyphLevels.LevelOf(ACoverage: Byte): Byte;
begin
  if ACoverage >= BODY_LEVEL_1 then
    Result := XCOM_GLYPH_LEVEL_FIRST
  else if ACoverage >= BODY_LEVEL_2 then
    Result := 2
  else if ACoverage >= BODY_COVERAGE then
    Result := BODY_LEVEL_LAST
  else
    Result := 0;
end;

class function TXcomGlyphLevels.Trim(const AGlyph: TXcomGlyphBitmap): TXcomGlyphBitmap;
var
  LX: Integer;
  LY: Integer;
  LLeft: Integer;
  LRight: Integer;
  LTop: Integer;
  LBottom: Integer;
begin
  LLeft := AGlyph.Width;
  LRight := -1;
  LTop := AGlyph.Height;
  LBottom := -1;
  for LY := 0 to AGlyph.Height - 1 do
    for LX := 0 to AGlyph.Width - 1 do
      if AGlyph.At(LX, LY) <> 0 then
      begin
        if LX < LLeft then
          LLeft := LX;
        if LX > LRight then
          LRight := LX;
        if LY < LTop then
          LTop := LY;
        LBottom := LY;
      end;
  if LRight < 0 then
    Exit(TXcomGlyphBitmap.Make(0, 0, AGlyph.Top));
  Result := TXcomGlyphBitmap.Make(LRight - LLeft + 1, LBottom - LTop + 1, AGlyph.Top + LTop);
  for LY := 0 to Result.Height - 1 do
    for LX := 0 to Result.Width - 1 do
      Result.Pixels[LY * Result.Width + LX] := AGlyph.At(LLeft + LX, LTop + LY);
end;

class function TXcomGlyphLevels.Reduce(const AGlyph: TXcomGlyphBitmap; AOutline: Boolean): TXcomGlyphBitmap;
var
  LBody: TXcomGlyphBitmap;
  LX: Integer;
  LY: Integer;
  LLevel: Byte;
begin
  LBody := TXcomGlyphBitmap.Make(AGlyph.Width, AGlyph.Height, AGlyph.Top);
  for LY := 0 to AGlyph.Height - 1 do
    for LX := 0 to AGlyph.Width - 1 do
      LBody.Pixels[LY * LBody.Width + LX] := LevelOf(AGlyph.At(LX, LY));
  // what was covered too little is gone: the sides may have become empty
  LBody := Trim(LBody);
  if (LBody.Width = 0) or not AOutline then
    Exit(LBody);
  Result := TXcomGlyphBitmap.Make(LBody.Width + 2, LBody.Height + 2, LBody.Top - 1);
  for LY := 0 to Result.Height - 1 do
    for LX := 0 to Result.Width - 1 do
    begin
      // the result is the body moved by one pixel
      LLevel := LBody.At(LX - 1, LY - 1);
      if LLevel = 0 then
      begin
        if (LBody.At(LX - 2, LY - 1) <> 0) or (LBody.At(LX, LY - 1) <> 0) or (LBody.At(LX - 1, LY - 2) <> 0) or
          (LBody.At(LX - 1, LY) <> 0) then
          LLevel := XCOM_GLYPH_LEVEL_OUTLINE
        else if (LBody.At(LX - 2, LY - 2) <> 0) or (LBody.At(LX, LY - 2) <> 0) or (LBody.At(LX - 2, LY) <> 0) or
          (LBody.At(LX, LY) <> 0) then
          LLevel := XCOM_GLYPH_LEVEL_CORNER;
      end;
      Result.Pixels[LY * Result.Width + LX] := LLevel;
    end;
end;

end.
