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
  ///   (4 beside the body, 5 on its corners); the fonts of the geoscape have no outline. A rasterized character
  ///   has 256 levels of coverage and is brought to the same convention
  /// </summary>
  TXcomGlyphLevels = class sealed
  public
    const
      /// <summary>With an outline: the least coverage of a pixel of the body, and the least of the levels 2 and 1</summary>
      BODY_COVERAGE = 80;
      BODY_LEVEL_2 = 144;
      BODY_LEVEL_1 = 208;
      /// <summary>Without an outline a pixel covered less than this is left out</summary>
      FAINT_COVERAGE = 26;
    /// <summary>
    ///   Without an outline: the five levels spread over the coverage (205 and more is 1, then 2, 3, 4 every 51,
    ///   down to 26 that is 5); a character without antialiasing (coverage 0 or 255) is all 1
    /// </summary>
    class function LevelOf(ACoverage: Byte): Byte; static;
    /// <summary>With an outline the body only takes the levels 1 to 3 (4 and 5 are the outline); 0 is not body</summary>
    class function BodyLevelOf(ACoverage: Byte): Byte; static;
    /// <summary>
    ///   The character with the levels of the game. With AOutline the result is a pixel larger on every side
    ///   (Top one row higher): the pixels that are not body and touch it by a side are 4, by a corner only 5
    /// </summary>
    class function Reduce(const AGlyph: TXcomGlyphBitmap; AOutline: Boolean): TXcomGlyphBitmap; static;
  end;

implementation

class function TXcomGlyphLevels.LevelOf(ACoverage: Byte): Byte;
begin
  if ACoverage < FAINT_COVERAGE then
    Exit(0);
  Result := XCOM_GLYPH_LEVEL_LAST - ACoverage * XCOM_GLYPH_LEVEL_LAST div 256;
  if Result < XCOM_GLYPH_LEVEL_FIRST then
    Result := XCOM_GLYPH_LEVEL_FIRST;
end;

class function TXcomGlyphLevels.BodyLevelOf(ACoverage: Byte): Byte;
begin
  if ACoverage >= BODY_LEVEL_1 then
    Result := 1
  else if ACoverage >= BODY_LEVEL_2 then
    Result := 2
  else if ACoverage >= BODY_COVERAGE then
    Result := 3
  else
    Result := 0;
end;

class function TXcomGlyphLevels.Reduce(const AGlyph: TXcomGlyphBitmap; AOutline: Boolean): TXcomGlyphBitmap;
var
  LBody: TXcomGlyphBitmap;
  LX: Integer;
  LY: Integer;
  LLevel: Byte;
begin
  if not AOutline then
  begin
    Result := TXcomGlyphBitmap.Make(AGlyph.Width, AGlyph.Height, AGlyph.Top);
    for LY := 0 to AGlyph.Height - 1 do
      for LX := 0 to AGlyph.Width - 1 do
        Result.Pixels[LY * Result.Width + LX] := LevelOf(AGlyph.At(LX, LY));
    Exit;
  end;
  LBody := TXcomGlyphBitmap.Make(AGlyph.Width, AGlyph.Height, AGlyph.Top);
  for LY := 0 to AGlyph.Height - 1 do
    for LX := 0 to AGlyph.Width - 1 do
      LBody.Pixels[LY * LBody.Width + LX] := BodyLevelOf(AGlyph.At(LX, LY));
  Result := TXcomGlyphBitmap.Make(AGlyph.Width + 2, AGlyph.Height + 2, AGlyph.Top - 1);
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
