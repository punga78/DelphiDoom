{******************************************************************************}
{                                                                              }
{  DelphiDoom: font library - from the text to the colors of a palette          }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Font.Colorizer;

interface

uses
  System.SysUtils,
  DelphiDoom.MathCore.SoftExtended,
  DelphiDoom.Palette.Intf,
  DelphiDoom.Font.Types;

type
  /// <summary>
  ///   The steps of FF_ExportFont that go from the picture of the text (white on black) to the palette indices of
  ///   the patch: gray level of each pixel, stretch of the levels, and the choice of the color: a mix of the
  ///   background and the foreground color, by the gray level (with the noise, if asked), turned into the nearest
  ///   color of the palette. A pixel that is not above FONT_COLOR_THRESHOLD is left as the index 0, which is
  ///   transparent
  /// </summary>
  TFontColorizer = class sealed
  strict private
    const
      FULL_LEVEL = 255;
      RED_WEIGHT = 0.299;
      GREEN_WEIGHT = 0.587;
      BLUE_WEIGHT = 0.114;
  public
    /// <summary>
    ///   The gray level as people see it: 0.299 red + 0.587 green + 0.114 blue, cut to an integer. It is
    ///   computed with Extended as the original did: in 32 bits the result is the one of the original (a few
    ///   levels, 63 for example, come out one less: 62.99999...). In 64 bits Extended is a Double, so the sum
    ///   is done with TSoftExtended, that rounds as the 64 bits of mantissa of the 32 bit FPU: the same level
    /// </summary>
    class function GrayLevel(ARed, AGreen, ABlue: Byte): Byte; static;
    /// <summary>The gray level of every pixel of the picture</summary>
    class function Grayscale(const AImage: TFontImage): TBytes; static;
    /// <summary>
    ///   "Stretch image color to max" of the original. The picture is stretched when its brightest level is
    ///   not 255 (and not 0): the original multiplied the whole 24 bit pixel and not the level, so every pixel
    ///   that was not black went to 255 and the stretch makes the picture black and white. The patches of the
    ///   old tool are like that, and the same text must give the same patch: the defect is kept
    /// </summary>
    class procedure StretchToMaximum(var AGray: TBytes); static;
    /// <summary>
    ///   The palette indices of the pixels: AGray holds AWidth * AHeight levels. Colors are $00BBGGRR (the
    ///   colors of the settings); the noise is the one of TFontPerlinNoise at the position of the pixel
    /// </summary>
    class function ToPaletteIndexes(const AGray: TBytes; AWidth, AHeight: Integer; AFrontColor,
      ABackColor: Integer; APerlinNoise: Boolean; const APalette: TFontPaletteSelection;
      const AMatcher: IColorMatcher): TBytes; static;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Font.Settings, DelphiDoom.Font.PerlinNoise;

{ TFontColorizer }

class function TFontColorizer.GrayLevel(ARed, AGreen, ABlue: Byte): Byte;
{$IF SizeOf(Extended) > SizeOf(Double)}
var
  LGray: Extended;
  LLevel: Integer;
begin
  LGray := ARed * RED_WEIGHT + AGreen * GREEN_WEIGHT + ABlue * BLUE_WEIGHT;
  LLevel := Trunc(LGray);
{$ELSE}
var
  LGray: TSoftExtended;
  LLevel: Int64;
begin
  // the literals 0.299, 0.587 and 0.114 are the Extended that the 32 bit compiler makes of them
  LGray := TSoftExtended.FromInt64(ARed) * TSoftExtended.FromRatio(299, 1000) +
    TSoftExtended.FromInt64(AGreen) * TSoftExtended.FromRatio(587, 1000) +
    TSoftExtended.FromInt64(ABlue) * TSoftExtended.FromRatio(114, 1000);
  LLevel := LGray.Truncate;
{$IFEND}
  if LLevel > FULL_LEVEL then
    LLevel := FULL_LEVEL;
  Result := Byte(LLevel);
end;

class function TFontColorizer.Grayscale(const AImage: TFontImage): TBytes;
var
  LIndex: Integer;
  LPixel: Cardinal;
begin
  if not AImage.IsValid then
    raise EFontException.Create(SFontBadImage);
  SetLength(Result, AImage.Width * AImage.Height);
  for LIndex := 0 to Length(Result) - 1 do
  begin
    LPixel := AImage.Pixels[LIndex];
    Result[LIndex] := GrayLevel(Byte(LPixel shr 16), Byte(LPixel shr 8), Byte(LPixel));
  end;
end;

class procedure TFontColorizer.StretchToMaximum(var AGray: TBytes);
var
  LIndex: Integer;
  LMaximum: Byte;
begin
  LMaximum := 0;
  for LIndex := 0 to Length(AGray) - 1 do
    if AGray[LIndex] > LMaximum then
      LMaximum := AGray[LIndex];
  if (LMaximum = 0) or (LMaximum = FULL_LEVEL) then
    Exit;
  // the original: Round(Pixel * 255 / Maximum) with Pixel the 24 bit gray ($010101 times the level): above
  // 255 for any level that is not 0, then cut to 255
  for LIndex := 0 to Length(AGray) - 1 do
    if AGray[LIndex] <> 0 then
      AGray[LIndex] := FULL_LEVEL;
end;

class function TFontColorizer.ToPaletteIndexes(const AGray: TBytes; AWidth, AHeight: Integer; AFrontColor,
  ABackColor: Integer; APerlinNoise: Boolean; const APalette: TFontPaletteSelection;
  const AMatcher: IColorMatcher): TBytes;
var
  LColumn: Integer;
  LRow: Integer;
  LIndex: Integer;
  LGray: Integer;
  LInverse: Integer;
  LNoise: Double;
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
  LBackRed: Integer;
  LBackGreen: Integer;
  LBackBlue: Integer;
  LFrontRed: Integer;
  LFrontGreen: Integer;
  LFrontBlue: Integer;
begin
  if (AWidth < 0) or (AHeight < 0) or (Int64(Length(AGray)) < Int64(AWidth) * AHeight) then
    raise EFontException.Create(SFontBadImage);
  if (not APalette.IsValid) or (not Assigned(AMatcher)) then
    raise EFontException.Create(SFontBadPalette);
  LBackRed := TFontSettings.RedOf(ABackColor);
  LBackGreen := TFontSettings.GreenOf(ABackColor);
  LBackBlue := TFontSettings.BlueOf(ABackColor);
  LFrontRed := TFontSettings.RedOf(AFrontColor);
  LFrontGreen := TFontSettings.GreenOf(AFrontColor);
  LFrontBlue := TFontSettings.BlueOf(AFrontColor);
  SetLength(Result, AWidth * AHeight);
  LIndex := 0;
  for LRow := 0 to AHeight - 1 do
    for LColumn := 0 to AWidth - 1 do
    begin
      LGray := AGray[LIndex];
      if LGray > FONT_COLOR_THRESHOLD then
      begin
        LInverse := FULL_LEVEL - LGray;
        LNoise := 0;
        if APerlinNoise then
          LNoise := TFontPerlinNoise.Value(LColumn, LRow);
        LRed := EnsureRange(Round(LBackRed * LInverse / FULL_LEVEL + LFrontRed * LGray / FULL_LEVEL + LNoise),
          0, FULL_LEVEL);
        LGreen := EnsureRange(Round(LBackGreen * LInverse / FULL_LEVEL + LFrontGreen * LGray / FULL_LEVEL +
          LNoise), 0, FULL_LEVEL);
        LBlue := EnsureRange(Round(LBackBlue * LInverse / FULL_LEVEL + LFrontBlue * LGray / FULL_LEVEL +
          LNoise), 0, FULL_LEVEL);
        Result[LIndex] := Byte(AMatcher.FindApproximateIndex(APalette.Colors,
          (Cardinal(LRed) shl 16) or (Cardinal(LGreen) shl 8) or Cardinal(LBlue), APalette.FirstIndex,
          APalette.LastIndex));
      end;
      Inc(LIndex);
    end;
end;

end.
