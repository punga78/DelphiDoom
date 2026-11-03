{******************************************************************************}
{                                                                              }
{  DelphiDoom: decoded JPEG image -> Windows bitmap for TBMPTextureManager     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.JpegBitmap;

{$POINTERMATH ON}

interface

uses
  System.SysUtils, DelphiDoom.Jpeg.Client;

type
  /// <summary>
  ///   Builds the bitmap file that TJPGTextureManager hands to the bitmap
  ///   loader: bottom-up rows padded to 4 bytes, 24 bits for a color image,
  ///   8 bits with a linear gray palette for a grayscale one
  /// </summary>
  /// <remarks>
  ///   The columns of every row are written in reverse order, exactly as the
  ///   old JPEG writer did: the texture loader mirrors the image afterwards
  /// </remarks>
  TJpegBitmapBuilder = class
  public
    class function Build(const AImage: TJpegImage): TBytes; static;
  end;

implementation

uses
  DelphiDoom.Jpeg.Intf;

type
  TBitmapFileHeader = packed record
    Signature: Word;
    FileSize: Cardinal;
    Reserved: Cardinal;
    PixelsOffset: Cardinal;
  end;

  TBitmapInfoHeader = packed record
    HeaderSize: Cardinal;
    Width: Integer;
    Height: Integer;
    Planes: Word;
    BitCount: Word;
    Compression: Cardinal;
    ImageSize: Cardinal;
    XPelsPerMeter: Integer;
    YPelsPerMeter: Integer;
    ColorsUsed: Cardinal;
    ColorsImportant: Cardinal;
  end;

const
  BITMAP_SIGNATURE = $4D42; // 'BM'
  GRAY_PALETTE_ENTRIES = 256;

{ TJpegBitmapBuilder }

class function TJpegBitmapBuilder.Build(const AImage: TJpegImage): TBytes;
var
  LFileHeader: TBitmapFileHeader;
  LInfoHeader: TBitmapInfoHeader;
  LComponents: Integer;
  LPaletteSize: Integer;
  LHeadersSize: Integer;
  LSourceRowSize: Integer;
  LRowSize: Integer;
  LRow: Integer;
  LColumn: Integer;
  LSource: PByte;
  LDest: PByte;
  LPalette: Integer;
begin
  LComponents := AImage.Components;
  if not (LComponents in [1, 3]) or (AImage.Width <= 0) or (AImage.Height <= 0) or
     (Length(AImage.Pixels) < AImage.Width * AImage.Height * LComponents) then
    raise EJpegException.CreateCode(DDJPEG_ERR_INVALID_ARGUMENT);

  if LComponents = 1 then
    LPaletteSize := GRAY_PALETTE_ENTRIES * 4
  else
    LPaletteSize := 0;
  LHeadersSize := SizeOf(LFileHeader) + SizeOf(LInfoHeader) + LPaletteSize;
  LSourceRowSize := AImage.Width * LComponents;
  LRowSize := (LSourceRowSize + 3) and not 3;

  FillChar(LFileHeader, SizeOf(LFileHeader), 0);
  LFileHeader.Signature := BITMAP_SIGNATURE;
  LFileHeader.FileSize := LHeadersSize + LRowSize * AImage.Height;
  LFileHeader.PixelsOffset := LHeadersSize;

  FillChar(LInfoHeader, SizeOf(LInfoHeader), 0);
  LInfoHeader.HeaderSize := SizeOf(LInfoHeader);
  LInfoHeader.Width := AImage.Width;
  LInfoHeader.Height := AImage.Height;
  LInfoHeader.Planes := 1;
  LInfoHeader.BitCount := LComponents * 8;
  LInfoHeader.ColorsUsed := LPaletteSize div 4;

  SetLength(Result, LFileHeader.FileSize);
  FillChar(Result[0], Length(Result), 0);
  Move(LFileHeader, Result[0], SizeOf(LFileHeader));
  Move(LInfoHeader, Result[SizeOf(LFileHeader)], SizeOf(LInfoHeader));

  // Linear gray palette: blue, green, red, unused
  for LPalette := 0 to LPaletteSize div 4 - 1 do
  begin
    LDest := @Result[SizeOf(LFileHeader) + SizeOf(LInfoHeader) + LPalette * 4];
    LDest[0] := Byte(LPalette);
    LDest[1] := Byte(LPalette);
    LDest[2] := Byte(LPalette);
  end;

  // The first row of the image goes to the end of the file
  for LRow := 0 to AImage.Height - 1 do
  begin
    LSource := @AImage.Pixels[LRow * LSourceRowSize];
    LDest := @Result[LHeadersSize + (AImage.Height - 1 - LRow) * LRowSize];
    for LColumn := 0 to AImage.Width - 1 do
    begin
      Move(LSource[LColumn * LComponents],
        LDest[(AImage.Width - 1 - LColumn) * LComponents], LComponents);
    end;
  end;
end;

end.
