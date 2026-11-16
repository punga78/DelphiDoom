{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - an image in memory                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Port of TTexture (t_main.pas), from TEXLIB of Gertjan Schouten (1998)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Image;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types;

type
  TTextureColorArray = array[0..(MaxInt div SizeOf(Cardinal)) - 1] of Cardinal;
  PTextureColorArray = ^TTextureColorArray;

  /// <summary>
  ///   An image that the decoders fill and the engine reads: 1 byte per pixel with a
  ///   palette of 256 colors, 2 bytes (15 bit) or 4 bytes ($00RRGGBB, alpha in the top
  ///   byte). The rows go from top to bottom without padding. The pixels are in a
  ///   TBytes, so a pointer to them stays valid until the size or the format change
  /// </summary>
  /// <remarks>
  ///   Differences from the old TTexture, all of them where it used memory that it never
  ///   wrote: new buffers are zero, not garbage; the transformed palette starts as a copy
  ///   of the palette (before it had whatever the heap held until SetPaletteColor got a
  ///   color that is not 0), and it is rebuilt with all the 256 entries (the old copy
  ///   stopped at 255); writes outside of the buffer are dropped; a number of bytes per
  ///   pixel other than 1, 2 and 4 is refused
  /// </remarks>
  TTextureImage = class
  strict private
    FWidth: Integer;
    FHeight: Integer;
    FBytesPerPixel: Integer;
    FPixels: TBytes;
    FPalette: TTexturePixels;
    FTransformedPalette: TTexturePixels;
    FPaletteColor: Cardinal;
    FTransparentColor: Cardinal;
    FTransparentColor2: Cardinal;
    FTransparentColor3: Cardinal;
    FNeedsSwapRGB: Boolean;
    FExternalAlphaPresent: Boolean;
    FLeftOffset: Integer;
    FLeftOffsetSet: Boolean;
    FTopOffset: Integer;
    FTopOffsetSet: Boolean;
    procedure RebuildTransformedPalette;
    function PaletteColor32(AIndex: Integer): Cardinal;
    function SourcePixel(AColumn, ARow: Integer): Cardinal;
    function TransformedPixel(AColumn, ARow: Integer): Cardinal;
    function GetLeftOffset: Integer;
    function GetTopOffset: Integer;
    function GetHasOffsets: Boolean;
    function GetHasPalette: Boolean;
    function GetHasPixels: Boolean;
    procedure PutPixelAsColor(AIndex: Integer; AColor: Cardinal);
    procedure SetLeftOffset(AValue: Integer);
    procedure SetTopOffset(AValue: Integer);
  public
    constructor Create;
    /// <summary>
    ///   Frees the pixels and the palettes and sets the size to 0. The number of bytes
    ///   per pixel stays (the old Empty did not change it either)
    /// </summary>
    procedure Clear;
    procedure SetWidth(AValue: Integer);
    procedure SetHeight(AValue: Integer);
    /// <summary>
    ///   Changes the number of bytes per pixel (1, 2 or 4; any other value is ignored): the
    ///   pixels are lost and the image is blank
    /// </summary>
    procedure SetBytesPerPixel(AValue: Integer);
    /// <summary>Raw colors $00RRGGBB, up to 256 of them; the rest of the palette is 0</summary>
    procedure SetPalette(const AColors: TTexturePixels);
    /// <summary>
    ///   Colors as a file stores them: ACount records of ARecordSize bytes from AOffset
    ///   (up to 256 of them; what the source does not have is 0)
    /// </summary>
    procedure SetPaletteFromRecords(const ASource: TBytes; AOffset, ACount, ARecordSize: Integer;
      ALayout: TTexturePaletteLayout);
    /// <summary>
    ///   Adds a color to the palette that GetPalettedColumn32 and GetPalettedRow32 give
    ///   (the gamma and the flash of the screen); 0 gives the palette as it is
    /// </summary>
    procedure SetPaletteColor(AColor: Cardinal);
    /// <summary>
    ///   Writes ACount pixels from ASource (at ASourceOffset, in the format ABitsPerPixel)
    ///   to the row AY from the column AX; the row goes on in the next one as the memory
    ///   does. Where the bits per pixel are those of the image the bytes are copied;
    ///   otherwise the source is converted to 32 bit through the palette when it has one.
    ///   What would fall outside of the image is dropped
    /// </summary>
    procedure PutPixels(AX, AY, ACount: Integer; const ASource: TBytes; ASourceOffset,
      ABitsPerPixel: Integer);
    /// <summary>The colors of a column from the top, as many as ASize (it repeats the column)</summary>
    procedure GetColumn32(AColumn, ASize: Integer; ADest: PCardinal);
    /// <summary>The colors of a row from the left, as many as ASize (it repeats the row)</summary>
    procedure GetRow32(ARow, ASize: Integer; ADest: PCardinal);
    /// <summary>As GetColumn32 for an image with a palette, with the added color; false for the others</summary>
    function GetPalettedColumn32(AColumn, ASize: Integer; ADest: PCardinal;
      APaletteColor: Cardinal): Boolean;
    /// <summary>
    ///   As GetRow32 for an image with a palette; false for the others. The added color is
    ///   set but the row is read without it: the old function did the same (a defect, kept
    ///   because the full screen pictures that use it look as they always did)
    /// </summary>
    function GetPalettedRow32(ARow, ASize: Integer; ADest: PCardinal;
      APaletteColor: Cardinal): Boolean;
    /// <summary>Converts the image to 32 bit and sets a column</summary>
    procedure SetColumn32(AColumn: Integer; const AColors: PCardinal);
    /// <summary>Converts the image to 32 bit and sets a row</summary>
    procedure SetRow32(ARow: Integer; const AColors: PCardinal);
    procedure ConvertTo32bit;
    /// <summary>1 byte per pixel with a palette of grays; the gray is the mean of the channels</summary>
    procedure ConvertToGrayScale;
    /// <summary>Resizes with the nearest pixel, each side independently</summary>
    procedure ScaleTo(AWidth, AHeight: Integer);
    /// <summary>Flips the image horizontally (it is 32 bit after it)</summary>
    procedure Mirror;
    /// <summary>
    ///   Exchanges red and blue, once: the palette of an image with a palette, the pixels
    ///   (converted to 32 bit) of the others. It does nothing the second time
    /// </summary>
    procedure SwapRGB;
    /// <summary>A copy with the same format, size, pixels and palette (not the offsets and the transparent colors)</summary>
    function Clone: TTextureImage;
    /// <summary>The address of the first pixel; nil when the image is empty</summary>
    function PixelsPointer: PByte;
    /// <summary>The palette, or the web safe one when the image has none</summary>
    function PalettePointer: PCardinal;
    /// <summary>The palette with the added color, or the web safe one when the image has none</summary>
    function TransformedPalettePointer: PCardinal;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property BytesPerPixel: Integer read FBytesPerPixel;
    property Pixels: TBytes read FPixels;
    property Palette: TTexturePixels read FPalette;
    property HasPalette: Boolean read GetHasPalette;
    /// <summary>True when the image has a size and a format, so there are pixels to read</summary>
    property HasPixels: Boolean read GetHasPixels;
    property TransparentColor: Cardinal read FTransparentColor write FTransparentColor;
    property TransparentColor2: Cardinal read FTransparentColor2 write FTransparentColor2;
    property TransparentColor3: Cardinal read FTransparentColor3 write FTransparentColor3;
    /// <summary>True until SwapRGB is done: the decoders that already swap the channels clear it</summary>
    property NeedsSwapRGB: Boolean read FNeedsSwapRGB write FNeedsSwapRGB;
    property ExternalAlphaPresent: Boolean read FExternalAlphaPresent write FExternalAlphaPresent;
    /// <summary>The offset of the image (half of the width until it is set)</summary>
    property LeftOffset: Integer read GetLeftOffset write SetLeftOffset;
    /// <summary>The offset of the image (the height until it is set)</summary>
    property TopOffset: Integer read GetTopOffset write SetTopOffset;
    property HasOffsets: Boolean read GetHasOffsets;
  end;

implementation

uses
  DelphiDoom.Texture.Colors, DelphiDoom.Imaging.ColorMath;

{ TTextureImage }

constructor TTextureImage.Create;
begin
  inherited Create;
  FNeedsSwapRGB := True;
end;

procedure TTextureImage.Clear;
begin
  FPixels := nil;
  FPalette := nil;
  FTransformedPalette := nil;
  FWidth := 0;
  FHeight := 0;
end;

function TTextureImage.GetHasPalette: Boolean;
begin
  Result := Length(FPalette) > 0;
end;

function TTextureImage.GetHasPixels: Boolean;
begin
  Result := (FWidth > 0) and (FHeight > 0) and (FBytesPerPixel > 0);
end;

function TTextureImage.GetLeftOffset: Integer;
begin
  if FLeftOffsetSet then
    Result := FLeftOffset
  else
    Result := FWidth div 2;
end;

function TTextureImage.GetTopOffset: Integer;
begin
  if FTopOffsetSet then
    Result := FTopOffset
  else
    Result := FHeight;
end;

function TTextureImage.GetHasOffsets: Boolean;
begin
  Result := FLeftOffsetSet and FTopOffsetSet;
end;

procedure TTextureImage.SetLeftOffset(AValue: Integer);
begin
  FLeftOffset := AValue;
  FLeftOffsetSet := True;
end;

procedure TTextureImage.SetTopOffset(AValue: Integer);
begin
  FTopOffset := AValue;
  FTopOffsetSet := True;
end;

procedure TTextureImage.SetWidth(AValue: Integer);
var
  LNew: TBytes;
  LRow: Integer;
  LCopy: Integer;
begin
  if AValue = FWidth then
    Exit;
  if AValue < 0 then
    AValue := 0;
  if FHeight = 0 then
    FWidth := AValue
  else if AValue = 0 then
  begin
    FPixels := nil;
    FWidth := 0;
  end
  else
  begin
    SetLength(LNew, AValue * FHeight * FBytesPerPixel);
    if Length(LNew) > 0 then
      FillChar(LNew[0], Length(LNew), 0);
    if Length(FPixels) > 0 then
    begin
      LCopy := FBytesPerPixel * FWidth;
      if LCopy > FBytesPerPixel * AValue then
        LCopy := FBytesPerPixel * AValue;
      for LRow := 0 to FHeight - 1 do
        if LCopy > 0 then
          Move(FPixels[FBytesPerPixel * FWidth * LRow], LNew[FBytesPerPixel * AValue * LRow], LCopy);
    end;
    FPixels := LNew;
    FWidth := AValue;
  end;
end;

procedure TTextureImage.SetHeight(AValue: Integer);
var
  LNew: TBytes;
  LCopy: Integer;
begin
  if AValue = FHeight then
    Exit;
  if AValue < 0 then
    AValue := 0;
  if FWidth = 0 then
    FHeight := AValue
  else if AValue = 0 then
  begin
    FPixels := nil;
    FHeight := 0;
  end
  else
  begin
    SetLength(LNew, FWidth * AValue * FBytesPerPixel);
    if Length(LNew) > 0 then
      FillChar(LNew[0], Length(LNew), 0);
    LCopy := Length(FPixels);
    if LCopy > Length(LNew) then
      LCopy := Length(LNew);
    if LCopy > 0 then
      Move(FPixels[0], LNew[0], LCopy);
    FPixels := LNew;
    FHeight := AValue;
  end;
end;

procedure TTextureImage.SetBytesPerPixel(AValue: Integer);
begin
  if (FBytesPerPixel = AValue) or not (AValue in [1, 2, 4]) then
    Exit;
  FBytesPerPixel := AValue;
  FPixels := nil;
  if (FWidth > 0) and (FHeight > 0) then
  begin
    SetLength(FPixels, FWidth * FHeight * FBytesPerPixel);
    FillChar(FPixels[0], Length(FPixels), 0);
  end;
end;

procedure TTextureImage.RebuildTransformedPalette;
var
  LIndex: Integer;
begin
  if Length(FPalette) = 0 then
  begin
    FTransformedPalette := nil;
    Exit;
  end;
  SetLength(FTransformedPalette, TEXTURE_PALETTE_SIZE);
  for LIndex := 0 to TEXTURE_PALETTE_SIZE - 1 do
    if FPaletteColor <> 0 then
      FTransformedPalette[LIndex] := TImagingColorMath.Add(FPaletteColor, FPalette[LIndex])
    else
      FTransformedPalette[LIndex] := FPalette[LIndex];
end;

procedure TTextureImage.SetPalette(const AColors: TTexturePixels);
var
  LCount: Integer;
begin
  SetLength(FPalette, TEXTURE_PALETTE_SIZE);
  FillChar(FPalette[0], TEXTURE_PALETTE_SIZE * SizeOf(Cardinal), 0);
  LCount := Length(AColors);
  if LCount > TEXTURE_PALETTE_SIZE then
    LCount := TEXTURE_PALETTE_SIZE;
  if LCount > 0 then
    Move(AColors[0], FPalette[0], LCount * SizeOf(Cardinal));
  FPaletteColor := 0;
  RebuildTransformedPalette;
end;

procedure TTextureImage.SetPaletteFromRecords(const ASource: TBytes; AOffset, ACount,
  ARecordSize: Integer; ALayout: TTexturePaletteLayout);
var
  LIndex: Integer;
  LRaw: Cardinal;
  LPosition: Integer;
  LByte: Integer;
begin
  SetLength(FPalette, TEXTURE_PALETTE_SIZE);
  FillChar(FPalette[0], TEXTURE_PALETTE_SIZE * SizeOf(Cardinal), 0);
  if ACount > TEXTURE_PALETTE_SIZE then
    ACount := TEXTURE_PALETTE_SIZE;
  for LIndex := 0 to ACount - 1 do
  begin
    LRaw := 0;
    LPosition := AOffset + LIndex * ARecordSize;
    // the four bytes at the entry, as the old code read them: a record of 2 or 3 bytes
    // brings in the bytes of the next one
    for LByte := 0 to 3 do
      if (LPosition + LByte >= 0) and (LPosition + LByte < Length(ASource)) then
        LRaw := LRaw or (Cardinal(ASource[LPosition + LByte]) shl (8 * LByte));
    FPalette[LIndex] := TTextureColors.PaletteEntry(LRaw, ALayout);
  end;
  FPaletteColor := 0;
  RebuildTransformedPalette;
end;

procedure TTextureImage.SetPaletteColor(AColor: Cardinal);
begin
  if FPaletteColor <> AColor then
  begin
    FPaletteColor := AColor;
    RebuildTransformedPalette;
  end;
end;

function TTextureImage.PaletteColor32(AIndex: Integer): Cardinal;
begin
  if Length(FPalette) > 0 then
    Result := FPalette[AIndex and $FF]
  else
    Result := TEXTURE_DEFAULT_PALETTE[AIndex and $FF];
end;

procedure TTextureImage.PutPixelAsColor(AIndex: Integer; AColor: Cardinal);
begin
  // only a 32 bit image takes a converted color (the converters for 1 and 2 bytes
  // per pixel were never reachable: they needed an image that was given its format
  // before the decoder)
  if (FBytesPerPixel = 4) and (AIndex >= 0) and (AIndex < FWidth * FHeight) then
    PCardinal(@FPixels[AIndex * 4])^ := AColor and $FFFFFF;
end;

procedure TTextureImage.PutPixels(AX, AY, ACount: Integer; const ASource: TBytes;
  ASourceOffset, ABitsPerPixel: Integer);
var
  LIndex: Integer;
  LStart: Integer;
  LCopy: Integer;
  LByte: Integer;
  LRaw: Cardinal;
  LPaletteIndex: Cardinal;

  function SourceByte(AOffset: Integer): Cardinal;
  begin
    if (AOffset >= 0) and (AOffset < Length(ASource)) then
      Result := ASource[AOffset]
    else
      Result := 0;
  end;

  function SourceWord(AOffset: Integer): Cardinal;
  begin
    Result := SourceByte(AOffset) or (SourceByte(AOffset + 1) shl 8);
  end;

begin
  if (FBytesPerPixel = 0) or (Length(FPixels) = 0) or (ACount <= 0) then
    Exit;
  LStart := AX + AY * FWidth;
  if (ABitsPerPixel and 255) = FBytesPerPixel * 8 then
  begin
    for LIndex := 0 to ACount - 1 do
      if (LStart + LIndex >= 0) and (LStart + LIndex < FWidth * FHeight) then
      begin
        LCopy := (LStart + LIndex) * FBytesPerPixel;
        for LByte := 0 to FBytesPerPixel - 1 do
          FPixels[LCopy + LByte] := Byte(SourceByte(ASourceOffset + LIndex * FBytesPerPixel + LByte));
      end;
    Exit;
  end;

  for LIndex := 0 to ACount - 1 do
  begin
    LPaletteIndex := 0;
    case ABitsPerPixel and 255 of
      TEXTURE_FORMAT_1BIT:
      begin
        LPaletteIndex := (SourceByte(ASourceOffset + LIndex div 8) shr (7 - (LIndex and 7))) and 1;
        LRaw := PaletteColor32(LPaletteIndex);
      end;
      TEXTURE_FORMAT_4BIT:
      begin
        if (LIndex and 1) = 0 then
          LPaletteIndex := SourceByte(ASourceOffset + LIndex div 2) shr 4
        else
          LPaletteIndex := SourceByte(ASourceOffset + LIndex div 2) and 15;
        LRaw := PaletteColor32(LPaletteIndex);
      end;
      TEXTURE_FORMAT_8BIT:
        LRaw := PaletteColor32(SourceByte(ASourceOffset + LIndex));
      TEXTURE_FORMAT_15BIT:
        LRaw := TTextureColors.Pixel15To24(Word(SourceWord(ASourceOffset + LIndex * 2)));
      TEXTURE_FORMAT_24BIT:
        LRaw := SourceWord(ASourceOffset + LIndex * 3) or (SourceByte(ASourceOffset + LIndex * 3 + 2) shl 16);
      TEXTURE_FORMAT_32BIT:
        LRaw := SourceWord(ASourceOffset + LIndex * 4) or (SourceWord(ASourceOffset + LIndex * 4 + 2) shl 16);
    else
      Exit;
    end;
    if (FBytesPerPixel = 1) and ((ABitsPerPixel and 255) in [TEXTURE_FORMAT_1BIT, TEXTURE_FORMAT_4BIT]) then
    begin
      // an image of 1 byte per pixel keeps the indices of the palette: the pixels of 1 and 4
      // bits (BMP files) are written as the index they have
      if (LStart + LIndex >= 0) and (LStart + LIndex < FWidth * FHeight) then
        FPixels[LStart + LIndex] := Byte(LPaletteIndex);
    end
    else
      PutPixelAsColor(LStart + LIndex, LRaw);
  end;
end;

function TTextureImage.SourcePixel(AColumn, ARow: Integer): Cardinal;
var
  LOffset: Integer;
begin
  LOffset := (ARow * FWidth + AColumn) * FBytesPerPixel;
  case FBytesPerPixel of
    1: Result := PaletteColor32(FPixels[LOffset]);
    2: Result := TTextureColors.Pixel15To24(PWord(@FPixels[LOffset])^);
    4: Result := PCardinal(@FPixels[LOffset])^;
  else
    Result := 0;
  end;
end;

function TTextureImage.TransformedPixel(AColumn, ARow: Integer): Cardinal;
var
  LIndex: Byte;
begin
  LIndex := FPixels[ARow * FWidth + AColumn];
  if Length(FTransformedPalette) > 0 then
    Result := FTransformedPalette[LIndex]
  else
    Result := TEXTURE_DEFAULT_PALETTE[LIndex];
end;

procedure TTextureImage.GetColumn32(AColumn, ASize: Integer; ADest: PCardinal);
var
  LRow: Integer;
  LSourceRow: Integer;
begin
  if not GetHasPixels or (Length(FPixels) = 0) then
    Exit;
  AColumn := AColumn mod FWidth;
  if AColumn < 0 then
    Inc(AColumn, FWidth);
  LSourceRow := 0;
  for LRow := 0 to ASize - 1 do
  begin
    PTextureColorArray(ADest)^[LRow] := SourcePixel(AColumn, LSourceRow);
    Inc(LSourceRow);
    if LSourceRow >= FHeight then
      LSourceRow := 0;
  end;
end;

procedure TTextureImage.GetRow32(ARow, ASize: Integer; ADest: PCardinal);
var
  LSource: PByte;
  LDest: PCardinal;
  LColumn, LChunk, LIndex: Integer;
  LColors: PTextureColorArray;
begin
  if not GetHasPixels or (Length(FPixels) = 0) then
    Exit;
  ARow := ARow mod FHeight;
  if ARow < 0 then
    Inc(ARow, FHeight);
  LSource := @FPixels[ARow * FWidth * FBytesPerPixel];
  LDest := ADest;
  LColumn := 0;
  // the row goes on from its start when it is asked for more pixels than it has; the pixels
  // are converted a row at a time (this is used for each line of a full screen picture)
  while LColumn < ASize do
  begin
    LChunk := FWidth;
    if LChunk > ASize - LColumn then
      LChunk := ASize - LColumn;
    case FBytesPerPixel of
      4:
        Move(LSource^, LDest^, LChunk * 4);
      1:
      begin
        LColors := PTextureColorArray(PalettePointer);
        for LIndex := 0 to LChunk - 1 do
          PTextureColorArray(LDest)^[LIndex] := LColors^[PByte(NativeUInt(LSource) + NativeUInt(LIndex))^];
      end;
    else
      for LIndex := 0 to LChunk - 1 do
        PTextureColorArray(LDest)^[LIndex] :=
          TTextureColors.Pixel15To24(PWord(NativeUInt(LSource) + NativeUInt(LIndex) * 2)^);
    end;
    LDest := PCardinal(NativeUInt(LDest) + NativeUInt(LChunk) * 4);
    Inc(LColumn, LChunk);
  end;
end;

function TTextureImage.GetPalettedColumn32(AColumn, ASize: Integer; ADest: PCardinal;
  APaletteColor: Cardinal): Boolean;
var
  LRow: Integer;
begin
  Result := FBytesPerPixel = 1;
  if not Result then
    Exit;
  if (Length(FPixels) = 0) or (FWidth <= 0) or (FHeight <= 0) then
    Exit;
  AColumn := AColumn mod FWidth;
  if AColumn < 0 then
    Inc(AColumn, FWidth);
  SetPaletteColor(APaletteColor);
  for LRow := 0 to ASize - 1 do
    PTextureColorArray(ADest)^[LRow] := TransformedPixel(AColumn, LRow mod FHeight);
end;

function TTextureImage.GetPalettedRow32(ARow, ASize: Integer; ADest: PCardinal;
  APaletteColor: Cardinal): Boolean;
var
  LColumn: Integer;
begin
  Result := FBytesPerPixel = 1;
  if not Result then
    Exit;
  if (Length(FPixels) = 0) or (FWidth <= 0) or (FHeight <= 0) then
    Exit;
  ARow := ARow mod FHeight;
  if ARow < 0 then
    Inc(ARow, FHeight);
  SetPaletteColor(APaletteColor);
  // as the old code, which asked for the added color and then read the palette without it
  for LColumn := 0 to ASize - 1 do
    PTextureColorArray(ADest)^[LColumn] := SourcePixel(LColumn mod FWidth, ARow);
end;

procedure TTextureImage.SetColumn32(AColumn: Integer; const AColors: PCardinal);
var
  LRow: Integer;
begin
  if (AColumn < 0) or (AColumn >= FWidth) then
    Exit;
  ConvertTo32bit;
  if Length(FPixels) = 0 then
    Exit;
  for LRow := 0 to FHeight - 1 do
    PCardinal(@FPixels[(LRow * FWidth + AColumn) * 4])^ := PTextureColorArray(AColors)^[LRow];
end;

procedure TTextureImage.SetRow32(ARow: Integer; const AColors: PCardinal);
var
  LColumn: Integer;
begin
  if (ARow < 0) or (ARow >= FHeight) then
    Exit;
  ConvertTo32bit;
  if Length(FPixels) = 0 then
    Exit;
  for LColumn := 0 to FWidth - 1 do
    PCardinal(@FPixels[(ARow * FWidth + LColumn) * 4])^ := PTextureColorArray(AColors)^[LColumn];
end;

procedure TTextureImage.ConvertTo32bit;
var
  LNew: TBytes;
  LRow: Integer;
  LColumn: Integer;
begin
  if FBytesPerPixel = 4 then
    Exit;
  if (FWidth > 0) and (FHeight > 0) and (FBytesPerPixel > 0) and (Length(FPixels) > 0) then
  begin
    SetLength(LNew, FWidth * FHeight * 4);
    for LRow := 0 to FHeight - 1 do
      for LColumn := 0 to FWidth - 1 do
        PCardinal(@LNew[(LRow * FWidth + LColumn) * 4])^ := SourcePixel(LColumn, LRow);
    FPixels := LNew;
    FBytesPerPixel := 4;
  end
  else
  begin
    // nothing to convert: as before, the image gets a blank 32 bit buffer if it has a size
    FBytesPerPixel := 0;
    SetBytesPerPixel(4);
  end;
end;

procedure TTextureImage.ConvertToGrayScale;
var
  LSource: TTextureImage;
  LNew: TBytes;
  LColors: TTexturePixels;
  LIndex: Integer;
  LGray: Cardinal;
begin
  LSource := Clone;
  try
    LSource.ConvertTo32bit;
    SetLength(LNew, FWidth * FHeight);
    for LIndex := 0 to FWidth * FHeight - 1 do
    begin
      LGray := TTextureColors.Gray(PTextureColorArray(LSource.PixelsPointer)^[LIndex]);
      if LGray > 255 then
        LGray := 255;
      LNew[LIndex] := Byte(LGray);
    end;
  finally
    LSource.Free;
  end;
  SetLength(LColors, TEXTURE_PALETTE_SIZE);
  for LIndex := 0 to TEXTURE_PALETTE_SIZE - 1 do
    LColors[LIndex] := (Cardinal(LIndex) shl 16) + (Cardinal(LIndex) shl 8) + Cardinal(LIndex);
  FBytesPerPixel := 1;
  FPixels := LNew;
  SetPalette(LColors);
end;

procedure TTextureImage.ScaleTo(AWidth, AHeight: Integer);
var
  LNew: TBytes;
  LXStep, LYStep: Int64;
  LX, LY: Integer;
  LXSource, LYSource: Int64;
  LFrom: Integer;
begin
  if (AWidth <= 0) or (AHeight <= 0) then
    Exit;
  if Length(FPixels) = 0 then
  begin
    SetWidth(AWidth);
    SetHeight(AHeight);
    Exit;
  end;
  if (AWidth = FWidth) and (AHeight = FHeight) then
    Exit;
  LXStep := (Int64(FWidth) shl 16) div AWidth;
  LYStep := (Int64(FHeight) shl 16) div AHeight;
  SetLength(LNew, AWidth * AHeight * FBytesPerPixel);
  LYSource := 0;
  for LY := 0 to AHeight - 1 do
  begin
    LXSource := 0;
    for LX := 0 to AWidth - 1 do
    begin
      LFrom := (Integer(LYSource shr 16) * FWidth + Integer(LXSource shr 16)) * FBytesPerPixel;
      Move(FPixels[LFrom], LNew[(LY * AWidth + LX) * FBytesPerPixel], FBytesPerPixel);
      Inc(LXSource, LXStep);
    end;
    Inc(LYSource, LYStep);
  end;
  FPixels := LNew;
  FWidth := AWidth;
  FHeight := AHeight;
end;

procedure TTextureImage.Mirror;
var
  LRow: Integer;
  LColumn: Integer;
  LPixel: Cardinal;
  LColors: PTextureColorArray;
begin
  ConvertTo32bit;
  if Length(FPixels) = 0 then
    Exit;
  for LRow := 0 to FHeight - 1 do
  begin
    LColors := PTextureColorArray(@FPixels[LRow * FWidth * 4]);
    for LColumn := 0 to FWidth div 2 - 1 do
    begin
      LPixel := LColors^[LColumn];
      LColors^[LColumn] := LColors^[FWidth - 1 - LColumn];
      LColors^[FWidth - 1 - LColumn] := LPixel;
    end;
  end;
end;

procedure TTextureImage.SwapRGB;
var
  LIndex: Integer;
begin
  if not FNeedsSwapRGB then
    Exit;
  FNeedsSwapRGB := False;
  if FBytesPerPixel = 1 then
  begin
    for LIndex := 0 to Length(FPalette) - 1 do
      FPalette[LIndex] := TTextureColors.SwapRedBlue(FPalette[LIndex]);
    RebuildTransformedPalette;
    Exit;
  end;
  ConvertTo32bit;
  for LIndex := 0 to FWidth * FHeight - 1 do
    PTextureColorArray(@FPixels[0])^[LIndex] :=
      TTextureColors.SwapRedBlue(PTextureColorArray(@FPixels[0])^[LIndex]);
end;

function TTextureImage.Clone: TTextureImage;
begin
  Result := TTextureImage.Create;
  Result.FBytesPerPixel := FBytesPerPixel;
  Result.FWidth := FWidth;
  Result.FHeight := FHeight;
  Result.FPixels := Copy(FPixels);
  if HasPalette then
    Result.SetPalette(FPalette);
  Result.FExternalAlphaPresent := FExternalAlphaPresent;
end;

function TTextureImage.PixelsPointer: PByte;
begin
  if Length(FPixels) > 0 then
    Result := @FPixels[0]
  else
    Result := nil;
end;

function TTextureImage.PalettePointer: PCardinal;
begin
  if Length(FPalette) > 0 then
    Result := @FPalette[0]
  else
    Result := @TEXTURE_DEFAULT_PALETTE[0];
end;

function TTextureImage.TransformedPalettePointer: PCardinal;
begin
  if Length(FTransformedPalette) > 0 then
    Result := @FTransformedPalette[0]
  else
    Result := @TEXTURE_DEFAULT_PALETTE[0];
end;

end.
