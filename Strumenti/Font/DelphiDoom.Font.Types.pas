{******************************************************************************}
{                                                                              }
{  DelphiDoom: font library - types and constants                               }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Font.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>The widest patch of a text: the width of the screen of Doom</summary>
  FONT_MAX_PATCH_WIDTH = 320;
  /// <summary>A pixel whose gray level is not above this is left transparent</summary>
  FONT_COLOR_THRESHOLD = 16;
  FONT_MIN_SIZE = 4;
  FONT_MAX_SIZE = 20;
  FONT_DEFAULT_NAME = 'Doom';
  FONT_DEFAULT_SIZE = 8;
  FONT_DEFAULT_HEIGHT = -11;
  FONT_DEFAULT_CELL = 16;
  FONT_DEFAULT_GRID = 16;
  /// <summary>DEFAULT_CHARSET of Windows</summary>
  FONT_CHARSET_DEFAULT = 1;
  FONT_COLOR_WHITE = $FFFFFF;
  FONT_COLOR_BLACK = 0;
  /// <summary>The bits of the style of a font, as the file of settings of DD_FONT wrote them</summary>
  FONT_STYLE_BOLD = 1;
  FONT_STYLE_ITALIC = 2;
  FONT_STYLE_UNDERLINE = 4;
  FONT_STYLE_STRIKEOUT = 8;
  /// <summary>The characters of the sequence of a font: from the exclamation mark to the last of the ASCII</summary>
  FONT_SEQUENCE_FIRST = 33;
  FONT_SEQUENCE_LAST = 127;
  /// <summary>The offsets of the patches of a WAD of DD_FONT</summary>
  FONT_WAD_OFFSET_X = 0;
  FONT_WAD_OFFSET_Y = 3;
  /// <summary>The lump with the settings that a WAD of DD_FONT starts with</summary>
  FONT_SETTINGS_LUMP_NAME = 'DDFONT';
  FONT_WAD_LUMP_NAME_LENGTH = 8;
  FONT_DEFAULT_TEXT = 'Doom Font Creator';
  FONT_DEFAULT_CHARACTER_PREFIX = 'STCFN';
  FONT_DEFAULT_DIGIT_PREFIX = 'STTNUM';
  /// <summary>The text that the sequence of characters shows in the preview</summary>
  FONT_CHARACTER_PREVIEW = '!@#$%+-AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz';
  FONT_DIGIT_PREVIEW = '1234567890';

resourcestring
  SFontBadImage = 'The picture of the font has a negative size or fewer pixels than its size says';
  SFontBadPalette = 'The palette of the font needs 256 colors and a range of colors inside them';
  SFontNothingToExport = 'There is nothing to export: the text is empty';
  SFontBadRasterizer = 'The rasterizer gave a picture of %dx%d for a character of %dx%d';

type
  /// <summary>Raised when what the font library is given can not make a font (an empty text, a wrong palette)</summary>
  EFontException = class(Exception);

  /// <summary>The pitch of the font that the settings ask for (the Pitch of the font of Windows)</summary>
  TFontPitchMode = (fpmDefault, fpmVariable, fpmFixed);

  /// <summary>What a WAD of DD_FONT holds: one text, the characters of the ASCII one by one, or the digits</summary>
  TFontSequenceKind = (fskText, fskCharacters, fskDigits);

  /// <summary>
  ///   A picture of pixels $00RRGGBB (the red one in the third byte), Height rows of Width pixels. The
  ///   rasterizer makes it, the colorizer reads it
  /// </summary>
  TFontImage = record
    Width: Integer;
    Height: Integer;
    Pixels: TArray<Cardinal>;
    /// <summary>A picture of the given size, all pixels 0</summary>
    class function Create(AWidth, AHeight: Integer): TFontImage; static;
    /// <summary>True when the size is not negative and the pixels are all there</summary>
    function IsValid: Boolean;
  end;

  /// <summary>The 256 colors that the pixels of a patch are chosen from, and the range of them that may be used</summary>
  TFontPaletteSelection = record
    /// <summary>256 colors $00RRGGBB</summary>
    Colors: TArray<Cardinal>;
    FirstIndex: Integer;
    LastIndex: Integer;
    class function Create(const AColors: TArray<Cardinal>; AFirstIndex, ALastIndex: Integer): TFontPaletteSelection; static;
    function IsValid: Boolean;
  end;

  /// <summary>The options of the export of one text to a patch</summary>
  TFontExportOptions = record
    /// <summary>The characters keep the width of the cell: they are not cut on the right</summary>
    FixedPitch: Boolean;
    /// <summary>A noise is added to the colors of the pixels (the "texture" of the old tool)</summary>
    PerlinNoise: Boolean;
    /// <summary>The columns of the patch have no transparent pixels: the whole picture is a post</summary>
    Solid: Boolean;
    /// <summary>The offsets of the patch are the default ones: half of the width and the height of the picture</summary>
    DefaultOffsets: Boolean;
    OffsetX: Integer;
    OffsetY: Integer;
    class function Create(AFixedPitch, APerlinNoise, ASolid: Boolean; AOffsetX, AOffsetY: Integer): TFontExportOptions; static;
    /// <summary>The same options with the default offsets of the patch (OffsetX and OffsetY are not used)</summary>
    class function CreateWithDefaultOffsets(AFixedPitch, APerlinNoise, ASolid: Boolean): TFontExportOptions; static;
  end;

  /// <summary>What a WAD of DD_FONT is made of</summary>
  TFontGenerationRequest = record
    Kind: TFontSequenceKind;
    /// <summary>For fskText: the text, which is also the name of the lump (without the spaces)</summary>
    Text: string;
    /// <summary>For fskCharacters and fskDigits: the start of the names of the lumps</summary>
    Prefix: string;
    FixedPitch: Boolean;
    PerlinNoise: Boolean;
    class function ForText(const AText: string; AFixedPitch, APerlinNoise: Boolean): TFontGenerationRequest; static;
    class function ForCharacters(const APrefix: string; AFixedPitch, APerlinNoise: Boolean): TFontGenerationRequest; static;
    class function ForDigits(const APrefix: string; AFixedPitch, APerlinNoise: Boolean): TFontGenerationRequest; static;
  end;

implementation

uses
  DelphiDoom.Palette.Types;

{ TFontImage }

class function TFontImage.Create(AWidth, AHeight: Integer): TFontImage;
begin
  Result.Width := AWidth;
  Result.Height := AHeight;
  SetLength(Result.Pixels, AWidth * AHeight);
end;

function TFontImage.IsValid: Boolean;
begin
  Result := (Width >= 0) and (Height >= 0) and (Int64(Length(Pixels)) >= Int64(Width) * Height);
end;

{ TFontPaletteSelection }

class function TFontPaletteSelection.Create(const AColors: TArray<Cardinal>; AFirstIndex,
  ALastIndex: Integer): TFontPaletteSelection;
begin
  Result.Colors := AColors;
  Result.FirstIndex := AFirstIndex;
  Result.LastIndex := ALastIndex;
end;

function TFontPaletteSelection.IsValid: Boolean;
begin
  Result := (Length(Colors) >= PALETTE_COLOR_COUNT) and (FirstIndex >= 0) and (LastIndex >= FirstIndex)
    and (LastIndex < PALETTE_COLOR_COUNT);
end;

{ TFontExportOptions }

class function TFontExportOptions.Create(AFixedPitch, APerlinNoise, ASolid: Boolean; AOffsetX,
  AOffsetY: Integer): TFontExportOptions;
begin
  Result.FixedPitch := AFixedPitch;
  Result.PerlinNoise := APerlinNoise;
  Result.Solid := ASolid;
  Result.DefaultOffsets := False;
  Result.OffsetX := AOffsetX;
  Result.OffsetY := AOffsetY;
end;

class function TFontExportOptions.CreateWithDefaultOffsets(AFixedPitch, APerlinNoise,
  ASolid: Boolean): TFontExportOptions;
begin
  Result := Create(AFixedPitch, APerlinNoise, ASolid, 0, 0);
  Result.DefaultOffsets := True;
end;

{ TFontGenerationRequest }

class function TFontGenerationRequest.ForText(const AText: string; AFixedPitch,
  APerlinNoise: Boolean): TFontGenerationRequest;
begin
  Result.Kind := fskText;
  Result.Text := AText;
  Result.Prefix := '';
  Result.FixedPitch := AFixedPitch;
  Result.PerlinNoise := APerlinNoise;
end;

class function TFontGenerationRequest.ForCharacters(const APrefix: string; AFixedPitch,
  APerlinNoise: Boolean): TFontGenerationRequest;
begin
  Result.Kind := fskCharacters;
  Result.Text := '';
  Result.Prefix := APrefix;
  Result.FixedPitch := AFixedPitch;
  Result.PerlinNoise := APerlinNoise;
end;

class function TFontGenerationRequest.ForDigits(const APrefix: string; AFixedPitch,
  APerlinNoise: Boolean): TFontGenerationRequest;
begin
  Result.Kind := fskDigits;
  Result.Text := '';
  Result.Prefix := APrefix;
  Result.FixedPitch := AFixedPitch;
  Result.PerlinNoise := APerlinNoise;
end;

end.
