{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Texture library - the inputs that the golden       }
{  files and the tests share                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.Samples;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image, DelphiDoom.Texture.Intf;

type
  /// <summary>One file of an image format that the old code and the library must read the same way</summary>
  TTextureSampleFile = record
    Name: string;
    Extension: string;
    Bytes: TBytes;
    /// <summary>
    ///   The old code left some memory as it found it for this file (a truncated one): only
    ///   the size and the format are compared, not the pixels
    /// </summary>
    ShapeOnly: Boolean;
    /// <summary>How many entries of the palette the old code wrote (the others had what the heap held)</summary>
    PaletteCompare: Integer;
    /// <summary>
    ///   The old code did something that the library does not copy (it crashed, or gave a blank
    ///   image for a file that it did not read): the golden file has what it did and the tests
    ///   check the new answer by hand
    /// </summary>
    KnownDifference: Boolean;
  end;
  TTextureSampleFiles = TArray<TTextureSampleFile>;

  /// <summary>A PNG that a fake PNG library gives back, with the answers the real one would give</summary>
  TTextureSamplePng = record
    Name: string;
    /// <summary>The file given to the decoders: only its first 4 bytes, a number that the fake reads</summary>
    Token: TBytes;
    /// <summary>DDPNG_COLOR_xxx of the file</summary>
    ColorType: Integer;
    Data: TTexturePngData;
  end;
  TTextureSamplePngs = TArray<TTextureSamplePng>;

  /// <summary>Builds the inputs of the tests: files of each format, images, patches</summary>
  TTextureSamples = class sealed
  public
    /// <summary>FNV-1a, 64 bit</summary>
    class function Hash(const ABytes: TBytes; AOffset: Integer = 0; ACount: Integer = -1): UInt64; static;
    class function HashColors(const AColors: PCardinal; ACount: Integer): UInt64; static;
    class function Hex(AValue: UInt64): string; static;
    class function NextRandom(var AState: Cardinal): Cardinal; static;
    class function RandomBytes(ASeed: Cardinal; ACount: Integer): TBytes; static;
    /// <summary>The line of a golden file for an image: shape, offsets, colors and hashes</summary>
    class function Describe(AResult: Boolean; const AImage: TTextureImage;
      AShapeOnly: Boolean; APaletteCompare: Integer): string; static;
    /// <summary>The same line from the pieces (the harness takes them from the old objects)</summary>
    class function DescribeParts(AResult: Boolean; AWidth, AHeight, ABytesPerPixel: Integer;
      AHasPalette: Boolean; ALeftOffset, ATopOffset: Integer; AHasOffsets, AExternalAlpha: Boolean;
      AColor1, AColor2, AColor3: Cardinal; const APixels: PByte; APixelBytes: Integer;
      const APalette: PCardinal; AShapeOnly: Boolean; APaletteCompare: Integer): string; static;
    class function BmpFiles: TTextureSampleFiles; static;
    class function TgaFiles: TTextureSampleFiles; static;
    class function PcxFiles: TTextureSampleFiles; static;
    class function FlatFiles: TTextureSampleFiles; static;
    class function PatchFiles: TTextureSampleFiles; static;
    /// <summary>Files of random size and content in the formats that have no problem, for the parity runs</summary>
    class function FuzzFiles(ACount: Integer): TTextureSampleFiles; static;
    class function PngCases: TTextureSamplePngs; static;
    /// <summary>A BMP file: the headers, the palette (entries of B, G, R, 0) and the rows as they are in the file</summary>
    class function Bmp(AWidth, AHeight, ABits, ACompression: Integer; const APalette, AData: TBytes): TBytes; static;
    /// <summary>A TGA file: the header, the identification field, the color map and the data</summary>
    class function Tga(AIdLength, AColorMapType, AImageType, AColorMapLength, AColorMapEntrySize, AWidth,
      AHeight, APixelSize: Integer; const AId, AColorMap, AData: TBytes): TBytes; static;
    /// <summary>The header of a PCX file of 128 bytes</summary>
    class function PcxHeaderBytes(AVersion, ABitsPerPixel, AWidth, AHeight, APlanes,
      ABytesPerLine: Integer): TBytes; static;
    /// <summary>A line of a PCX plane with the run length coding of the encoders</summary>
    class function PcxLine(const ALine: TBytes): TBytes; static;
    /// <summary>The 769 bytes of the palette at the end of a PCX file</summary>
    class function PcxTrailer(ASeed: Cardinal): TBytes; static;
    /// <summary>A 4 byte image id: the first four bytes of a fake PNG file</summary>
    class function PngToken(AIndex: Integer): TBytes; static;
    /// <summary>A palette of 256 entries from a seed</summary>
    class function Palette(ASeed: Cardinal): TTexturePixels; static;
    /// <summary>The 256 colors that the patches and the flats are read with</summary>
    class function GamePalette: TTexturePixels; static;
    /// <summary>An image of the format with pseudo random pixels (and palette for 1 byte)</summary>
    class procedure FillImage(const AImage: TTextureImage; AWidth, AHeight, ABytesPerPixel: Integer;
      ASeed: Cardinal); static;
  end;

implementation

{ TTextureSamples }

class function TTextureSamples.Hash(const ABytes: TBytes; AOffset, ACount: Integer): UInt64;
var
  LIndex: Integer;
begin
  Result := UInt64($CBF29CE484222325);
  if ACount < 0 then
    ACount := Length(ABytes) - AOffset;
  for LIndex := AOffset to AOffset + ACount - 1 do
    Result := (Result xor ABytes[LIndex]) * UInt64($100000001B3);
end;

class function TTextureSamples.HashColors(const AColors: PCardinal; ACount: Integer): UInt64;
var
  LIndex: Integer;
  LColor: Cardinal;
  LByte: Integer;
begin
  Result := UInt64($CBF29CE484222325);
  for LIndex := 0 to ACount - 1 do
  begin
    LColor := PCardinal(NativeUInt(AColors) + NativeUInt(LIndex) * 4)^;
    for LByte := 0 to 3 do
      Result := (Result xor ((LColor shr (8 * LByte)) and $FF)) * UInt64($100000001B3);
  end;
end;

class function TTextureSamples.Hex(AValue: UInt64): string;
begin
  Result := IntToHex(Int64(AValue), 16);
end;

class function TTextureSamples.NextRandom(var AState: Cardinal): Cardinal;
begin
  AState := AState * 1664525 + 1013904223;
  Result := AState shr 8;
end;

class function TTextureSamples.RandomBytes(ASeed: Cardinal; ACount: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    Result[LIndex] := Byte(NextRandom(ASeed));
end;

class function TTextureSamples.DescribeParts(AResult: Boolean; AWidth, AHeight,
  ABytesPerPixel: Integer; AHasPalette: Boolean; ALeftOffset, ATopOffset: Integer;
  AHasOffsets, AExternalAlpha: Boolean; AColor1, AColor2, AColor3: Cardinal; const APixels: PByte;
  APixelBytes: Integer; const APalette: PCardinal; AShapeOnly: Boolean;
  APaletteCompare: Integer): string;
var
  LPixelHash, LPaletteHash: string;
  LBytes: TBytes;
begin
  // what is left in an image that was not read is not part of the contract
  if not AResult then
    Exit('0');
  Result := Format('%d:%dx%d:%d', [Ord(AResult), AWidth, AHeight, ABytesPerPixel]);
  if AShapeOnly then
    Exit;
  LPixelHash := '-';
  if (APixels <> nil) and (APixelBytes > 0) then
  begin
    SetLength(LBytes, APixelBytes);
    Move(APixels^, LBytes[0], APixelBytes);
    LPixelHash := Hex(Hash(LBytes));
  end;
  LPaletteHash := '-';
  if AHasPalette and (APaletteCompare > 0) then
    LPaletteHash := Hex(HashColors(APalette, APaletteCompare));
  Result := Result + Format(':pal%d:off%d,%d,%d:alpha%d:tc%.8x,%.8x,%.8x:%s:%s',
    [Ord(AHasPalette), ALeftOffset, ATopOffset, Ord(AHasOffsets), Ord(AExternalAlpha), AColor1,
     AColor2, AColor3, LPixelHash, LPaletteHash]);
end;

class function TTextureSamples.Describe(AResult: Boolean; const AImage: TTextureImage;
  AShapeOnly: Boolean; APaletteCompare: Integer): string;
begin
  Result := DescribeParts(AResult, AImage.Width, AImage.Height, AImage.BytesPerPixel,
    AImage.HasPalette, AImage.LeftOffset, AImage.TopOffset, AImage.HasOffsets,
    AImage.ExternalAlphaPresent, AImage.TransparentColor, AImage.TransparentColor2,
    AImage.TransparentColor3, AImage.PixelsPointer, Length(AImage.Pixels),
    AImage.PalettePointer, AShapeOnly, APaletteCompare);
end;

class function TTextureSamples.Palette(ASeed: Cardinal): TTexturePixels;
var
  LIndex: Integer;
begin
  SetLength(Result, 256);
  for LIndex := 0 to 255 do
    Result[LIndex] := NextRandom(ASeed) and $FFFFFF;
end;

class function TTextureSamples.GamePalette: TTexturePixels;
begin
  Result := Palette(777);
end;

class procedure TTextureSamples.FillImage(const AImage: TTextureImage; AWidth, AHeight,
  ABytesPerPixel: Integer; ASeed: Cardinal);
var
  LBytes: TBytes;
begin
  AImage.SetBytesPerPixel(ABytesPerPixel);
  AImage.SetWidth(AWidth);
  AImage.SetHeight(AHeight);
  LBytes := RandomBytes(ASeed, AWidth * AHeight * ABytesPerPixel);
  Move(LBytes[0], AImage.Pixels[0], Length(LBytes));
  if ABytesPerPixel = 1 then
    AImage.SetPalette(Palette(ASeed + 1));
end;

// ---------------------------------------------------------------------------
// Files
// ---------------------------------------------------------------------------

function MakeFile(const AName, AExtension: string; const ABytes: TBytes; AShapeOnly: Boolean = False;
  APaletteCompare: Integer = 256; AKnownDifference: Boolean = False): TTextureSampleFile;
begin
  Result.Name := AName;
  Result.Extension := AExtension;
  Result.Bytes := ABytes;
  Result.ShapeOnly := AShapeOnly;
  Result.PaletteCompare := APaletteCompare;
  Result.KnownDifference := AKnownDifference;
end;

procedure Append(var ADest: TBytes; const ASource: TBytes);
begin
  if Length(ASource) > 0 then
  begin
    SetLength(ADest, Length(ADest) + Length(ASource));
    Move(ASource[0], ADest[Length(ADest) - Length(ASource)], Length(ASource));
  end;
end;

procedure AppendByte(var ADest: TBytes; AValue: Byte);
begin
  SetLength(ADest, Length(ADest) + 1);
  ADest[High(ADest)] := AValue;
end;

procedure AppendWord(var ADest: TBytes; AValue: Word);
begin
  AppendByte(ADest, Byte(AValue));
  AppendByte(ADest, Byte(AValue shr 8));
end;

procedure AppendLong(var ADest: TBytes; AValue: Cardinal);
begin
  AppendWord(ADest, Word(AValue));
  AppendWord(ADest, Word(AValue shr 16));
end;

function BmpFile(AWidth, AHeight, ABits, ACompression: Integer; const APalette, AData: TBytes): TBytes;
begin
  Result := nil;
  AppendWord(Result, $4D42);
  AppendLong(Result, 54 + Length(APalette) + Length(AData));
  AppendLong(Result, 0);
  AppendLong(Result, 54 + Length(APalette));
  AppendLong(Result, 40);
  AppendLong(Result, Cardinal(AWidth));
  AppendLong(Result, Cardinal(AHeight));
  AppendWord(Result, 1);
  AppendWord(Result, ABits);
  AppendLong(Result, Cardinal(ACompression));
  AppendLong(Result, Length(AData));
  AppendLong(Result, 2835);
  AppendLong(Result, 2835);
  AppendLong(Result, 0);
  AppendLong(Result, 0);
  Append(Result, APalette);
  Append(Result, AData);
end;

function BmpPaletteBytes(ACount: Integer; ASeed: Cardinal): TBytes;
var
  LIndex: Integer;
begin
  Result := nil;
  for LIndex := 0 to ACount - 1 do
  begin
    AppendByte(Result, Byte(TTextureSamples.NextRandom(ASeed)));
    AppendByte(Result, Byte(TTextureSamples.NextRandom(ASeed)));
    AppendByte(Result, Byte(TTextureSamples.NextRandom(ASeed)));
    AppendByte(Result, 0);
  end;
end;

// the rows of a BMP: ABytesPerRow bytes of pixels, padded to 4
function BmpRows(AHeight, ABytesPerRow, AIndexLimit: Integer; ASeed: Cardinal): TBytes;
var
  LRow, LColumn, LStride: Integer;
begin
  Result := nil;
  LStride := (ABytesPerRow + 3) and not 3;
  for LRow := 0 to AHeight - 1 do
    for LColumn := 0 to LStride - 1 do
      if LColumn < ABytesPerRow then
        AppendByte(Result, Byte(TTextureSamples.NextRandom(ASeed) mod Cardinal(AIndexLimit)))
      else
        AppendByte(Result, 0);
end;

class function TTextureSamples.BmpFiles: TTextureSampleFiles;
var
  LList: TTextureSampleFiles;
  LRle: TBytes;
  LTruncated: TBytes;
  LRow: Integer;

  procedure Add(const AFile: TTextureSampleFile);
  begin
    SetLength(LList, Length(LList) + 1);
    LList[High(LList)] := AFile;
  end;

begin
  LList := nil;
  Add(MakeFile('bmp8-4x4', '.BMP', BmpFile(4, 4, 8, 0, BmpPaletteBytes(256, 1), BmpRows(4, 4, 256, 2))));
  Add(MakeFile('bmp8-5x3-padding', '.BMP', BmpFile(5, 3, 8, 0, BmpPaletteBytes(256, 3), BmpRows(3, 5, 256, 4))));
  Add(MakeFile('bmp8-1x1', '.BMP', BmpFile(1, 1, 8, 0, BmpPaletteBytes(256, 5), BmpRows(1, 1, 256, 6))));
  Add(MakeFile('bmp8-32x16', '.BMP', BmpFile(32, 16, 8, 0, BmpPaletteBytes(256, 7), BmpRows(16, 32, 256, 8))));
  Add(MakeFile('bmp8-short-palette', '.BMP', BmpFile(6, 5, 8, 0, BmpPaletteBytes(16, 9), BmpRows(5, 6, 16, 10)),
    False, 16));

  // RLE: four rows of a run of 5 and a literal of 3 (odd: padded), each ending with end of line
  LRle := nil;
  for LRow := 0 to 3 do
  begin
    AppendByte(LRle, 5); AppendByte(LRle, Byte(17 + LRow));
    AppendByte(LRle, 0); AppendByte(LRle, 3); AppendByte(LRle, Byte(40 + LRow));
    AppendByte(LRle, Byte(41 + LRow)); AppendByte(LRle, Byte(42 + LRow)); AppendByte(LRle, 0);
    AppendByte(LRle, 0); AppendByte(LRle, 0);
  end;
  AppendByte(LRle, 0); AppendByte(LRle, 1);
  Add(MakeFile('bmp8-rle', '.BMP', BmpFile(8, 4, 8, 1, BmpPaletteBytes(256, 11), LRle)));

  // RLE with codes that skip pixels (the old code left them as the heap had them): a run of
  // 5, a literal of 3, end of line, a run of 2, a delta of (1, 1), a literal of 4, end of line, end
  LRle := nil;
  AppendByte(LRle, 5); AppendByte(LRle, 17);
  AppendByte(LRle, 0); AppendByte(LRle, 3); AppendByte(LRle, 40); AppendByte(LRle, 41);
  AppendByte(LRle, 42); AppendByte(LRle, 0);
  AppendByte(LRle, 0); AppendByte(LRle, 0);
  AppendByte(LRle, 2); AppendByte(LRle, 99);
  AppendByte(LRle, 0); AppendByte(LRle, 2); AppendByte(LRle, 1); AppendByte(LRle, 1);
  AppendByte(LRle, 0); AppendByte(LRle, 4); AppendByte(LRle, 50); AppendByte(LRle, 51);
  AppendByte(LRle, 52); AppendByte(LRle, 53);
  AppendByte(LRle, 0); AppendByte(LRle, 0);
  AppendByte(LRle, 0); AppendByte(LRle, 1);
  Add(MakeFile('bmp8-rle-delta', '.BMP', BmpFile(8, 4, 8, 1, BmpPaletteBytes(256, 12), LRle), True));

  Add(MakeFile('bmp24-4x4', '.BMP', BmpFile(4, 4, 24, 0, nil, BmpRows(4, 12, 256, 12))));
  Add(MakeFile('bmp24-5x4-padding', '.BMP', BmpFile(5, 4, 24, 0, nil, BmpRows(4, 15, 256, 13))));
  Add(MakeFile('bmp24-1x7', '.BMP', BmpFile(1, 7, 24, 0, nil, BmpRows(7, 3, 256, 14))));
  Add(MakeFile('bmp24-32x32', '.BMP', BmpFile(32, 32, 24, 0, nil, BmpRows(32, 96, 256, 15))));
  Add(MakeFile('bmp32-not-read', '.BMP', BmpFile(4, 4, 32, 0, nil, BmpRows(4, 16, 256, 16)), True));
  Add(MakeFile('bmp24-zero-width', '.BMP', BmpFile(0, 4, 24, 0, nil, nil), True));

  LTruncated := BmpFile(16, 16, 24, 0, nil, BmpRows(16, 48, 256, 17));
  SetLength(LTruncated, 54 + 48 * 5);
  Add(MakeFile('bmp24-truncated', '.BMP', LTruncated, True));
  LTruncated := BmpFile(16, 16, 8, 0, BmpPaletteBytes(256, 18), BmpRows(16, 16, 256, 19));
  SetLength(LTruncated, 54 + 1024 + 16 * 5);
  Add(MakeFile('bmp8-truncated', '.BMP', LTruncated, True));

  // the data far from the headers with 24 bit: the old code read it from byte 54
  Result := LList;
end;

function TgaFile(AIdLength, AColorMapType, AImageType, AColorMapLength, AColorMapEntrySize, AWidth,
  AHeight, APixelSize: Integer; const AId, AColorMap, AData: TBytes): TBytes;
begin
  Result := nil;
  AppendByte(Result, Byte(AIdLength));
  AppendByte(Result, Byte(AColorMapType));
  AppendByte(Result, Byte(AImageType));
  AppendWord(Result, 0);
  AppendWord(Result, Word(AColorMapLength));
  AppendByte(Result, Byte(AColorMapEntrySize));
  AppendWord(Result, 0);
  AppendWord(Result, 0);
  AppendWord(Result, Word(AWidth));
  AppendWord(Result, Word(AHeight));
  AppendByte(Result, Byte(APixelSize));
  AppendByte(Result, 0);
  Append(Result, AId);
  Append(Result, AColorMap);
  Append(Result, AData);
end;

// RLE of a TGA: packets of runs and of raw pixels; the run lengths cross the lines on purpose
function TgaRle(const APixels: TBytes; ABytesPerPixel, AWidth, AHeight: Integer; ASeed: Cardinal): TBytes;
var
  LCount, LDone, LRun, LIndex, LRaw: Integer;
begin
  Result := nil;
  LCount := AWidth * AHeight;
  LDone := 0;
  while LDone < LCount do
  begin
    LRun := 1 + Integer(TTextureSamples.NextRandom(ASeed) mod 9);
    if LDone + LRun > LCount then
      LRun := LCount - LDone;
    if (TTextureSamples.NextRandom(ASeed) and 1) = 0 then
    begin
      // a run of the pixel at LDone
      AppendByte(Result, Byte(128 + LRun - 1));
      for LIndex := 0 to ABytesPerPixel - 1 do
        AppendByte(Result, APixels[LDone * ABytesPerPixel + LIndex]);
    end
    else
    begin
      AppendByte(Result, Byte(LRun - 1));
      for LRaw := 0 to LRun - 1 do
        for LIndex := 0 to ABytesPerPixel - 1 do
          AppendByte(Result, APixels[(LDone + LRaw) * ABytesPerPixel + LIndex]);
    end;
    Inc(LDone, LRun);
  end;
end;

class function TTextureSamples.TgaFiles: TTextureSampleFiles;
var
  LList: TTextureSampleFiles;
  LPixels: TBytes;
  LMap: TBytes;

  procedure Add(const AFile: TTextureSampleFile);
  begin
    SetLength(LList, Length(LList) + 1);
    LList[High(LList)] := AFile;
  end;

  function Indices(AWidth, AHeight: Integer; ASeed: Cardinal): TBytes;
  begin
    Result := RandomBytes(ASeed, AWidth * AHeight);
  end;

begin
  LList := nil;
  // color mapped, 8 bit
  LMap := RandomBytes(21, 256 * 3);
  Add(MakeFile('tga-cm8-24-raw-5x3', '.TGA', TgaFile(0, 1, 1, 256, 24, 5, 3, 8, nil, LMap, Indices(5, 3, 22))));
  LMap := RandomBytes(23, 256 * 4);
  Add(MakeFile('tga-cm8-32-raw-4x4', '.TGA', TgaFile(0, 1, 1, 256, 32, 4, 4, 8, nil, LMap, Indices(4, 4, 24))));
  LMap := RandomBytes(25, 256 * 3);
  LPixels := Indices(7, 5, 26);
  Add(MakeFile('tga-cm8-24-rle-7x5', '.TGA', TgaFile(0, 1, 9, 256, 24, 7, 5, 8, nil, LMap,
    TgaRle(LPixels, 1, 7, 5, 27))));
  LMap := RandomBytes(28, 256 * 3);
  Add(MakeFile('tga-cm8-24-id-1x6', '.TGA', TgaFile(5, 1, 1, 256, 24, 1, 6, 8, TBytes.Create(1, 2, 3, 4, 5),
    LMap, Indices(1, 6, 29))));
  // color maps of 15 and 16 bits: the old code took the last entry from memory it did not write
  LMap := RandomBytes(30, 256 * 2);
  Add(MakeFile('tga-cm8-16-raw-3x3', '.TGA', TgaFile(0, 1, 1, 256, 16, 3, 3, 8, nil, LMap, Indices(3, 3, 31)),
    False, 255));
  LMap := RandomBytes(32, 256 * 2);
  Add(MakeFile('tga-cm8-15-raw-3x3', '.TGA', TgaFile(0, 1, 1, 256, 15, 3, 3, 8, nil, LMap, Indices(3, 3, 33)),
    False, 255));
  // a small map: the other entries of the palette were not written by the old code
  LMap := RandomBytes(34, 16 * 3);
  Add(MakeFile('tga-cm8-24-small-map-4x2', '.TGA', TgaFile(0, 1, 1, 16, 24, 4, 2, 8, nil, LMap,
    BmpRows(2, 4, 16, 35)), False, 16));

  // true color
  Add(MakeFile('tga-true16-raw-5x4', '.TGA', TgaFile(0, 0, 2, 0, 0, 5, 4, 16, nil, nil, RandomBytes(36, 5 * 4 * 2))));
  LPixels := RandomBytes(37, 6 * 5 * 2);
  Add(MakeFile('tga-true16-rle-6x5', '.TGA', TgaFile(0, 0, 10, 0, 0, 6, 5, 16, nil, nil,
    TgaRle(LPixels, 2, 6, 5, 38))));
  Add(MakeFile('tga-true24-raw-5x4', '.TGA', TgaFile(0, 0, 2, 0, 0, 5, 4, 24, nil, nil, RandomBytes(39, 5 * 4 * 3))));
  LPixels := RandomBytes(40, 9 * 7 * 3);
  Add(MakeFile('tga-true24-rle-9x7', '.TGA', TgaFile(0, 0, 10, 0, 0, 9, 7, 24, nil, nil,
    TgaRle(LPixels, 3, 9, 7, 41))));
  Add(MakeFile('tga-true24-id-3x3', '.TGA', TgaFile(3, 0, 2, 0, 0, 3, 3, 24, TBytes.Create(7, 8, 9), nil,
    RandomBytes(42, 3 * 3 * 3))));
  Add(MakeFile('tga-true32-raw-4x5', '.TGA', TgaFile(0, 0, 2, 0, 0, 4, 5, 32, nil, nil, RandomBytes(43, 4 * 5 * 4))));
  LPixels := RandomBytes(44, 8 * 8 * 4);
  Add(MakeFile('tga-true32-rle-8x8', '.TGA', TgaFile(0, 0, 10, 0, 0, 8, 8, 32, nil, nil,
    TgaRle(LPixels, 4, 8, 8, 45))));
  Add(MakeFile('tga-true24-1x1', '.TGA', TgaFile(0, 0, 2, 0, 0, 1, 1, 24, nil, nil, RandomBytes(46, 3))));
  Add(MakeFile('tga-true24-64x64', '.TGA', TgaFile(0, 0, 2, 0, 0, 64, 64, 24, nil, nil, RandomBytes(47, 64 * 64 * 3))));

  // what is not read
  Add(MakeFile('tga-bad-pixel-size', '.TGA', TgaFile(0, 0, 2, 0, 0, 4, 4, 12, nil, nil, RandomBytes(48, 64)), True));
  Add(MakeFile('tga-zero-size', '.TGA', TgaFile(0, 0, 2, 0, 0, 0, 0, 24, nil, nil, nil), True));
  // the old code gave true and a blank image for a color map that it could not read
  Add(MakeFile('tga-cm8-bad-entry-size', '.TGA', TgaFile(0, 1, 1, 256, 8, 4, 4, 8, nil, RandomBytes(49, 256),
    Indices(4, 4, 50)), True, 256, True));
  Add(MakeFile('tga-gray8', '.TGA', TgaFile(0, 0, 3, 0, 0, 4, 4, 8, nil, nil, Indices(4, 4, 51)), True, 256, True));
  Result := LList;
end;

// RLE of a PCX line: the way the encoders do it (a byte from $C0 up goes after a count)
function PcxEncodeLine(const ALine: TBytes): TBytes;
var
  LIndex, LRun: Integer;
begin
  Result := nil;
  LIndex := 0;
  while LIndex < Length(ALine) do
  begin
    LRun := 1;
    while (LIndex + LRun < Length(ALine)) and (ALine[LIndex + LRun] = ALine[LIndex]) and (LRun < 63) do
      Inc(LRun);
    if (LRun > 1) or (ALine[LIndex] >= $C0) then
      AppendByte(Result, Byte($C0 or LRun));
    AppendByte(Result, ALine[LIndex]);
    Inc(LIndex, LRun);
  end;
end;

function PcxHeader(AVersion, ABitsPerPixel, AWidth, AHeight, APlanes, ABytesPerLine: Integer;
  const AColorMap: TBytes): TBytes;
var
  LIndex: Integer;
begin
  Result := nil;
  AppendByte(Result, $0A);
  AppendByte(Result, Byte(AVersion));
  AppendByte(Result, 1);
  AppendByte(Result, Byte(ABitsPerPixel));
  AppendWord(Result, 0);
  AppendWord(Result, 0);
  AppendWord(Result, Word(AWidth - 1));
  AppendWord(Result, Word(AHeight - 1));
  AppendWord(Result, 72);
  AppendWord(Result, 72);
  for LIndex := 0 to 47 do
    if LIndex < Length(AColorMap) then
      AppendByte(Result, AColorMap[LIndex])
    else
      AppendByte(Result, 0);
  AppendByte(Result, 0);
  AppendByte(Result, Byte(APlanes));
  AppendWord(Result, Word(ABytesPerLine));
  AppendWord(Result, 1);
  for LIndex := 1 to 58 do
    AppendByte(Result, 0);
end;

// ARows: planes of AHeight lines of ABytesPerLine bytes, line after line
function PcxData(AHeight, APlanes, ABytesPerLine: Integer; ASeed: Cardinal; AIndexLimit: Integer;
  ARepeats: Boolean): TBytes;
var
  LLine: TBytes;
  LRow, LPlane, LIndex: Integer;
begin
  Result := nil;
  for LRow := 0 to AHeight - 1 do
    for LPlane := 0 to APlanes - 1 do
    begin
      SetLength(LLine, ABytesPerLine);
      for LIndex := 0 to ABytesPerLine - 1 do
      begin
        LLine[LIndex] := Byte(TTextureSamples.NextRandom(ASeed) mod Cardinal(AIndexLimit));
        if ARepeats and (LIndex > 0) and ((TTextureSamples.NextRandom(ASeed) and 3) = 0) then
          LLine[LIndex] := LLine[LIndex - 1];
      end;
      Append(Result, PcxEncodeLine(LLine));
    end;
end;

function PcxPalette(ASeed: Cardinal; ASignature: Byte): TBytes;
begin
  Result := nil;
  AppendByte(Result, ASignature);
  Append(Result, TTextureSamples.RandomBytes(ASeed, 768));
end;

class function TTextureSamples.PcxFiles: TTextureSampleFiles;
var
  LList: TTextureSampleFiles;
  LFile: TBytes;
  LBad: TBytes;

  procedure Add(const AFile: TTextureSampleFile);
  begin
    SetLength(LList, Length(LList) + 1);
    LList[High(LList)] := AFile;
  end;

  function Assemble(const AHeader, AData, APalette: TBytes): TBytes;
  begin
    Result := nil;
    Append(Result, AHeader);
    Append(Result, AData);
    Append(Result, APalette);
  end;

begin
  LList := nil;
  // main reader
  Add(MakeFile('pcx5-8bit-8x6', '.PCX', Assemble(PcxHeader(5, 8, 8, 6, 1, 8, nil),
    PcxData(6, 1, 8, 61, 256, True), PcxPalette(62, $0C))));
  Add(MakeFile('pcx5-8bit-odd-7x5', '.PCX', Assemble(PcxHeader(5, 8, 7, 5, 1, 8, nil),
    PcxData(5, 1, 8, 63, 256, True), PcxPalette(64, $0C))));
  Add(MakeFile('pcx5-8bit-c0-bytes', '.PCX', Assemble(PcxHeader(5, 8, 6, 3, 1, 6, nil),
    PcxData(3, 1, 6, 65, 256, False), PcxPalette(66, $0C))));
  Add(MakeFile('pcx5-24bit-6x5', '.PCX', Assemble(PcxHeader(5, 8, 6, 5, 3, 6, nil),
    PcxData(5, 3, 6, 67, 256, True), nil)));
  Add(MakeFile('pcx5-24bit-16x16', '.PCX', Assemble(PcxHeader(5, 8, 16, 16, 3, 16, nil),
    PcxData(16, 3, 16, 68, 256, True), nil)));
  Add(MakeFile('pcx5-1bit-with-palette-16x4', '.PCX', Assemble(PcxHeader(5, 1, 16, 4, 1, 2, nil),
    PcxData(4, 1, 2, 69, 256, False), PcxPalette(70, $0C))));
  Add(MakeFile('pcx5-1bit-with-palette-12x4', '.PCX', Assemble(PcxHeader(5, 1, 12, 4, 1, 2, nil),
    PcxData(4, 1, 2, 71, 256, False), PcxPalette(72, $0C))));

  // the second reader
  Add(MakeFile('pcx3-8bit-8x6', '.PCX', Assemble(PcxHeader(3, 8, 8, 6, 1, 8, nil),
    PcxData(6, 1, 8, 73, 256, True), PcxPalette(74, $0C))));
  Add(MakeFile('pcx2-8bit-8x4', '.PCX', Assemble(PcxHeader(2, 8, 8, 4, 1, 8, RandomBytes(75, 48)),
    PcxData(4, 1, 8, 76, 256, True), PcxPalette(77, $0C))));
  Add(MakeFile('pcx4-8bit-odd-7x5', '.PCX', Assemble(PcxHeader(4, 8, 7, 5, 1, 8, nil),
    PcxData(5, 1, 8, 78, 256, True), PcxPalette(79, $0C))));
  Add(MakeFile('pcx5-8bit-bad-signature', '.PCX', Assemble(PcxHeader(5, 8, 8, 4, 1, 8, nil),
    PcxData(4, 1, 8, 80, 256, True), PcxPalette(81, $0D))));
  Add(MakeFile('pcx5-1bit-no-palette-16x4', '.PCX', Assemble(PcxHeader(5, 1, 16, 4, 1, 2, nil),
    PcxData(4, 1, 2, 82, 256, False), nil)));
  Add(MakeFile('pcx5-16colors-4planes-16x4', '.PCX', Assemble(PcxHeader(5, 1, 16, 4, 4, 2, RandomBytes(83, 48)),
    PcxData(4, 4, 2, 84, 256, False), nil)));
  Add(MakeFile('pcx3-16colors-4planes-16x4', '.PCX', Assemble(PcxHeader(3, 1, 16, 4, 4, 2, RandomBytes(85, 48)),
    PcxData(4, 4, 2, 86, 256, False), nil)));
  Add(MakeFile('pcx2-16colors-2planes-8x3', '.PCX', Assemble(PcxHeader(2, 1, 8, 3, 2, 1, RandomBytes(87, 48)),
    PcxData(3, 2, 1, 88, 256, False), nil)));
  Add(MakeFile('pcx3-24bit-6x5', '.PCX', Assemble(PcxHeader(3, 8, 6, 5, 3, 6, nil),
    PcxData(5, 3, 6, 89, 256, True), nil)));
  // the old code wrote the 18 bytes of a line over the 16 of a scan line: the first pixel of the
  // line above got other bytes
  Add(MakeFile('pcx4-24bit-odd-5x4', '.PCX', Assemble(PcxHeader(4, 8, 5, 4, 3, 6, nil),
    PcxData(4, 3, 6, 90, 256, True), nil), False, 256, True));

  // what no reader takes
  LBad := Assemble(PcxHeader(5, 8, 8, 4, 1, 8, nil), PcxData(4, 1, 8, 91, 256, True), PcxPalette(92, $0C));
  LBad[0] := $0B;
  Add(MakeFile('pcx-bad-identifier', '.PCX', LBad, True));
  // the old code gave true and a blank image for the 4 bit, and failed with an error on the others
  Add(MakeFile('pcx-4bit-one-plane', '.PCX', Assemble(PcxHeader(5, 4, 8, 4, 1, 4, RandomBytes(93, 48)),
    PcxData(4, 1, 4, 94, 256, False), nil), True, 256, True));
  Add(MakeFile('pcx-empty', '.PCX', nil, True));
  LFile := PcxHeader(5, 8, 8, 4, 1, 8, nil);
  Add(MakeFile('pcx-header-only', '.PCX', LFile, True, 256, True));
  Result := LList;
end;

class function TTextureSamples.FlatFiles: TTextureSampleFiles;
var
  LList: TTextureSampleFiles;

  procedure Add(const AName: string; ALength: Integer; ASeed: Cardinal);
  begin
    SetLength(LList, Length(LList) + 1);
    LList[High(LList)] := MakeFile(AName, '.FLAT', RandomBytes(ASeed, ALength));
  end;

begin
  LList := nil;
  Add('flat-64x64', 64 * 64, 101);
  Add('flat-64x128', 64 * 128, 102);
  Add('flat-128x128', 128 * 128, 103);
  Add('flat-256x256', 256 * 256, 104);
  Add('flat-512x512', 512 * 512, 105);
  Add('flat-1024x1024', 1024 * 1024, 106);
  Add('flat-not-a-flat-5000', 5000, 107);
  Add('flat-not-a-flat-4095', 4095, 108);
  Add('flat-empty', 0, 109);
  Result := LList;
end;

// a patch: columns of posts (topdelta, pixels), each post with a padding byte before and after
function PatchBytes(AWidth, AHeight, ALeft, ATop: Integer; ASeed: Cardinal; ATall: Boolean): TBytes;
var
  LColumns: array of TBytes;
  LColumn, LPost, LPosts, LRow, LLength, LTopDelta, LPrevious, LIndex, LOffset: Integer;
  LBody: TBytes;
begin
  SetLength(LColumns, AWidth);
  for LColumn := 0 to AWidth - 1 do
  begin
    LBody := nil;
    LRow := 0;
    LPrevious := -1;
    LPosts := 1 + Integer(TTextureSamples.NextRandom(ASeed) mod 3);
    for LPost := 0 to LPosts - 1 do
    begin
      if LRow >= AHeight then
        Break;
      LTopDelta := LRow + Integer(TTextureSamples.NextRandom(ASeed) mod 3);
      if LTopDelta >= AHeight then
        Break;
      LLength := 1 + Integer(TTextureSamples.NextRandom(ASeed) mod 6);
      if LTopDelta + LLength > AHeight then
        LLength := AHeight - LTopDelta;
      if ATall and (AHeight > 255) then
      begin
        // the offset from the end of the last post once the rows pass 254
        if LTopDelta > 254 then
        begin
          if LPrevious < 0 then
            LTopDelta := 254
          else
            LTopDelta := LTopDelta - LPrevious;
        end
        else if LPrevious >= 0 then
          LTopDelta := LTopDelta - LPrevious;
      end;
      AppendByte(LBody, Byte(LTopDelta));
      AppendByte(LBody, Byte(LLength));
      AppendByte(LBody, 0);
      for LIndex := 0 to LLength - 1 do
        AppendByte(LBody, Byte(TTextureSamples.NextRandom(ASeed)));
      AppendByte(LBody, 0);
      LPrevious := LRow;
      LRow := LRow + LLength + 3;
      if LRow >= AHeight then
        Break;
    end;
    AppendByte(LBody, $FF);
    LColumns[LColumn] := LBody;
  end;
  Result := nil;
  AppendWord(Result, Word(AWidth));
  AppendWord(Result, Word(AHeight));
  AppendWord(Result, Word(ALeft));
  AppendWord(Result, Word(ATop));
  LOffset := 8 + AWidth * 4;
  for LColumn := 0 to AWidth - 1 do
  begin
    AppendLong(Result, Cardinal(LOffset));
    Inc(LOffset, Length(LColumns[LColumn]));
  end;
  for LColumn := 0 to AWidth - 1 do
    Append(Result, LColumns[LColumn]);
end;

class function TTextureSamples.PatchFiles: TTextureSampleFiles;
var
  LList: TTextureSampleFiles;
  LTruncated: TBytes;
  LBad: TBytes;

  procedure Add(const AFile: TTextureSampleFile);
  begin
    SetLength(LList, Length(LList) + 1);
    LList[High(LList)] := AFile;
  end;

begin
  LList := nil;
  Add(MakeFile('patch-8x8', '.PATCH', PatchBytes(8, 8, 4, 8, 201, False)));
  Add(MakeFile('patch-1x1', '.PATCH', PatchBytes(1, 1, 0, 0, 202, False)));
  Add(MakeFile('patch-16x32-offsets', '.PATCH', PatchBytes(16, 32, 7, 30, 203, False)));
  Add(MakeFile('patch-negative-offsets', '.PATCH', PatchBytes(10, 20, -5, -3, 204, False)));
  Add(MakeFile('patch-64x128', '.PATCH', PatchBytes(64, 128, 32, 120, 205, False)));
  Add(MakeFile('patch-24x200', '.PATCH', PatchBytes(24, 200, 12, 190, 206, False)));
  Add(MakeFile('patch-tall-12x300', '.PATCH', PatchBytes(12, 300, 6, 290, 207, True)));
  Add(MakeFile('patch-wide-300x16', '.PATCH', PatchBytes(300, 16, 150, 14, 208, False)));
  // not patches
  LTruncated := PatchBytes(8, 8, 0, 0, 209, False);
  SetLength(LTruncated, 20);
  // the old code read the memory past the lump
  Add(MakeFile('patch-truncated-table', '.PATCH', LTruncated, True, 256, True));
  LBad := PatchBytes(8, 8, 0, 0, 210, False);
  LBad[8] := $FF;
  LBad[9] := $7F;
  Add(MakeFile('patch-column-outside', '.PATCH', LBad, True, 256, True));
  Add(MakeFile('patch-too-wide', '.PATCH', TBytes.Create($01, $30, 8, 0, 0, 0, 0, 0), True));
  Add(MakeFile('patch-zero-width', '.PATCH', TBytes.Create(0, 0, 8, 0, 0, 0, 0, 0), True));
  Result := LList;
end;

class function TTextureSamples.FuzzFiles(ACount: Integer): TTextureSampleFiles;
var
  LList: TTextureSampleFiles;
  LSeed: Cardinal;
  LIndex: Integer;
  LWidth, LHeight, LKind: Integer;
  LName: string;
  LPixels: TBytes;
  LHeader, LData: TBytes;

  procedure Add(const AName, AExtension: string; const ABytes: TBytes);
  begin
    SetLength(LList, Length(LList) + 1);
    LList[High(LList)] := MakeFile(AName, AExtension, ABytes);
  end;

  function Join(const AFirst, ASecond, AThird: TBytes): TBytes;
  begin
    Result := nil;
    Append(Result, AFirst);
    Append(Result, ASecond);
    Append(Result, AThird);
  end;

begin
  LList := nil;
  LSeed := 90210;
  for LIndex := 0 to ACount - 1 do
  begin
    LWidth := 1 + Integer(NextRandom(LSeed) mod 37);
    LHeight := 1 + Integer(NextRandom(LSeed) mod 23);
    LKind := Integer(NextRandom(LSeed) mod 11);
    LName := Format('fuzz%.3d-k%d-%dx%d', [LIndex, LKind, LWidth, LHeight]);
    case LKind of
      0: Add(LName + '-bmp8', '.BMP', BmpFile(LWidth, LHeight, 8, 0, BmpPaletteBytes(256, LSeed),
           BmpRows(LHeight, LWidth, 256, LSeed + 1)));
      1: Add(LName + '-bmp24', '.BMP', BmpFile(LWidth, LHeight, 24, 0, nil,
           BmpRows(LHeight, LWidth * 3, 256, LSeed + 2)));
      2: Add(LName + '-tga-cm8-raw', '.TGA', TgaFile(0, 1, 1, 256, 24, LWidth, LHeight, 8, nil,
           RandomBytes(LSeed + 3, 768), RandomBytes(LSeed + 4, LWidth * LHeight)));
      3:
      begin
        LPixels := RandomBytes(LSeed + 5, LWidth * LHeight);
        Add(LName + '-tga-cm8-rle', '.TGA', TgaFile(0, 1, 9, 256, 32, LWidth, LHeight, 8, nil,
          RandomBytes(LSeed + 6, 1024), TgaRle(LPixels, 1, LWidth, LHeight, LSeed + 7)));
      end;
      4: Add(LName + '-tga-true24-raw', '.TGA', TgaFile(0, 0, 2, 0, 0, LWidth, LHeight, 24, nil, nil,
           RandomBytes(LSeed + 8, LWidth * LHeight * 3)));
      5:
      begin
        LPixels := RandomBytes(LSeed + 9, LWidth * LHeight * 3);
        Add(LName + '-tga-true24-rle', '.TGA', TgaFile(0, 0, 10, 0, 0, LWidth, LHeight, 24, nil, nil,
          TgaRle(LPixels, 3, LWidth, LHeight, LSeed + 10)));
      end;
      6: Add(LName + '-tga-true32-raw', '.TGA', TgaFile(0, 0, 2, 0, 0, LWidth, LHeight, 32, nil, nil,
           RandomBytes(LSeed + 11, LWidth * LHeight * 4)));
      7:
      begin
        LPixels := RandomBytes(LSeed + 12, LWidth * LHeight * 4);
        Add(LName + '-tga-true32-rle', '.TGA', TgaFile(0, 0, 10, 0, 0, LWidth, LHeight, 32, nil, nil,
          TgaRle(LPixels, 4, LWidth, LHeight, LSeed + 13)));
      end;
      8:
      begin
        // PCX with even widths: the line is as long as the width
        LWidth := 2 * ((LWidth + 1) div 2);
        LHeader := PcxHeader(5, 8, LWidth, LHeight, 1, LWidth, nil);
        LData := PcxData(LHeight, 1, LWidth, LSeed + 14, 256, True);
        Add(LName + '-pcx5-8bit', '.PCX', Join(LHeader, LData, PcxPalette(LSeed + 15, $0C)));
      end;
      9:
      begin
        LWidth := 2 * ((LWidth + 1) div 2);
        LHeader := PcxHeader(5, 8, LWidth, LHeight, 3, LWidth, nil);
        LData := PcxData(LHeight, 3, LWidth, LSeed + 16, 256, True);
        Add(LName + '-pcx5-24bit', '.PCX', Join(LHeader, LData, nil));
      end;
    else
      begin
        LWidth := 2 * ((LWidth + 1) div 2);
        LHeader := PcxHeader(3, 8, LWidth, LHeight, 1, LWidth, nil);
        LData := PcxData(LHeight, 1, LWidth, LSeed + 17, 256, True);
        Add(LName + '-pcx3-8bit', '.PCX', Join(LHeader, LData, PcxPalette(LSeed + 18, $0C)));
      end;
    end;
  end;
  Result := LList;
end;

class function TTextureSamples.Bmp(AWidth, AHeight, ABits, ACompression: Integer; const APalette,
  AData: TBytes): TBytes;
begin
  Result := BmpFile(AWidth, AHeight, ABits, ACompression, APalette, AData);
end;

class function TTextureSamples.Tga(AIdLength, AColorMapType, AImageType, AColorMapLength,
  AColorMapEntrySize, AWidth, AHeight, APixelSize: Integer; const AId, AColorMap, AData: TBytes): TBytes;
begin
  Result := TgaFile(AIdLength, AColorMapType, AImageType, AColorMapLength, AColorMapEntrySize, AWidth,
    AHeight, APixelSize, AId, AColorMap, AData);
end;

class function TTextureSamples.PcxHeaderBytes(AVersion, ABitsPerPixel, AWidth, AHeight, APlanes,
  ABytesPerLine: Integer): TBytes;
begin
  Result := PcxHeader(AVersion, ABitsPerPixel, AWidth, AHeight, APlanes, ABytesPerLine, nil);
end;

class function TTextureSamples.PcxLine(const ALine: TBytes): TBytes;
begin
  Result := PcxEncodeLine(ALine);
end;

class function TTextureSamples.PcxTrailer(ASeed: Cardinal): TBytes;
begin
  Result := PcxPalette(ASeed, $0C);
end;

class function TTextureSamples.PngToken(AIndex: Integer): TBytes;
begin
  Result := TBytes.Create(Byte(AIndex), 0, 0, 0);
end;

class function TTextureSamples.PngCases: TTextureSamplePngs;
var
  LList: TTextureSamplePngs;
  LSeed: Cardinal;

  function PixelsOf(AWidth, AHeight: Integer; AMakeAlpha: Boolean): TBytes;
  var
    LIndex: Integer;
  begin
    SetLength(Result, AWidth * AHeight * 4);
    for LIndex := 0 to AWidth * AHeight - 1 do
    begin
      Result[LIndex * 4] := Byte(NextRandom(LSeed));
      Result[LIndex * 4 + 1] := Byte(NextRandom(LSeed));
      Result[LIndex * 4 + 2] := Byte(NextRandom(LSeed));
      case LIndex mod 7 of
        0: begin Result[LIndex * 4] := 0; Result[LIndex * 4 + 1] := 0; Result[LIndex * 4 + 2] := 0; end;
        1: begin Result[LIndex * 4] := $FF; Result[LIndex * 4 + 1] := 0; Result[LIndex * 4 + 2] := $FF; end;
        2: begin Result[LIndex * 4] := $FF; Result[LIndex * 4 + 1] := $FF; Result[LIndex * 4 + 2] := 0; end;
        3: begin Result[LIndex * 4] := $FF; Result[LIndex * 4 + 1] := $FF; Result[LIndex * 4 + 2] := $FF; end;
        4: begin Result[LIndex * 4] := 0; Result[LIndex * 4 + 1] := 1; Result[LIndex * 4 + 2] := 1; end;
      end;
      if AMakeAlpha then
        Result[LIndex * 4 + 3] := Byte((LIndex mod 3) * 100)
      else
        Result[LIndex * 4 + 3] := $FF;
    end;
  end;

  function IndicesOf(AWidth, AHeight, ALimit: Integer): TBytes;
  var
    LIndex: Integer;
  begin
    SetLength(Result, AWidth * AHeight);
    for LIndex := 0 to AWidth * AHeight - 1 do
      Result[LIndex] := Byte(NextRandom(LSeed) mod Cardinal(ALimit));
  end;

  function PaletteOf(AAlpha: Boolean): TBytes;
  var
    LIndex: Integer;
  begin
    SetLength(Result, 1024);
    for LIndex := 0 to 255 do
    begin
      Result[LIndex * 4] := Byte(NextRandom(LSeed));
      Result[LIndex * 4 + 1] := Byte(NextRandom(LSeed));
      Result[LIndex * 4 + 2] := Byte(NextRandom(LSeed));
      case LIndex of
        0: begin Result[0] := 0; Result[1] := 0; Result[2] := 0; end;
        1: begin Result[4] := $FF; Result[5] := 0; Result[6] := $FF; end;
        2: begin Result[8] := 0; Result[9] := $FF; Result[10] := $FF; end;
        3: begin Result[12] := 1; Result[13] := 1; Result[14] := 0; end;
        4: begin Result[16] := 0; Result[17] := 1; Result[18] := 0; end;
        5: begin Result[20] := 9; Result[21] := 8; Result[22] := 7; end;
      end;
      if AAlpha and ((LIndex mod 4) = 2) then
        Result[LIndex * 4 + 3] := 0
      else
        Result[LIndex * 4 + 3] := $FF;
    end;
  end;

  procedure Add(const AName: string; AColorType, AWidth, AHeight: Integer; AIndexed, AAlphaChannel,
    APaletteAlpha, AHasColor: Boolean; AColor: Cardinal; AOffsetX, AOffsetY: Integer);
  var
    LCase: TTextureSamplePng;
  begin
    LCase.Name := AName;
    LCase.Token := PngToken(Length(LList));
    LCase.ColorType := AColorType;
    LCase.Data.Width := AWidth;
    LCase.Data.Height := AHeight;
    LCase.Data.Indexed := AIndexed;
    LCase.Data.HasAlphaChannel := AAlphaChannel;
    LCase.Data.HasPaletteAlpha := APaletteAlpha;
    LCase.Data.HasTransparentColor := AHasColor;
    LCase.Data.TransparentColor := AColor;
    LCase.Data.OffsetX := AOffsetX;
    LCase.Data.OffsetY := AOffsetY;
    if AIndexed then
    begin
      LCase.Data.Pixels := IndicesOf(AWidth, AHeight, 8);
      LCase.Data.Palette := PaletteOf(APaletteAlpha);
    end
    else
    begin
      LCase.Data.Pixels := PixelsOf(AWidth, AHeight, AAlphaChannel);
      LCase.Data.Palette := nil;
    end;
    SetLength(LList, Length(LList) + 1);
    LList[High(LList)] := LCase;
  end;

begin
  LList := nil;
  LSeed := 3001;
  Add('indexed-5x4', 3, 5, 4, True, False, False, False, 0, 0, 0);
  Add('indexed-with-color-5x4', 3, 5, 4, True, False, False, True, $090807, 1, 2);
  Add('indexed-black-color-5x4', 3, 5, 4, True, False, False, True, $010100, 0, 0);
  Add('indexed-palette-alpha-6x4', 3, 6, 4, True, False, True, True, $010100, 3, 4);
  Add('indexed-palette-alpha-no-color-6x4', 3, 6, 4, True, False, True, False, 0, 0, 0);
  Add('rgba-7x5', 6, 7, 5, False, True, True, False, 0, 2, 3);
  Add('rgba-with-near-black-key-7x5', 6, 7, 5, False, True, True, True, $010100, 0, 0);
  Add('gray-alpha-4x4', 4, 4, 4, False, True, True, False, 0, 0, 0);
  Add('rgb-8x6', 2, 8, 6, False, False, False, False, 0, 0, 0);
  Add('rgb-with-color-8x6', 2, 8, 6, False, False, False, True, $FF00FF, 5, 5);
  Add('rgb-with-black-color-8x6', 2, 8, 6, False, False, False, True, $010100, 0, 0);
  Add('gray-9x3', 0, 9, 3, False, False, False, False, 0, 0, 0);
  Add('rgb-1x1', 2, 1, 1, False, False, False, False, 0, 0, 0);
  Result := LList;
end;

end.
