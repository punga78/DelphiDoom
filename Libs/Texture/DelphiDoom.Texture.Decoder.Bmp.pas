{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - decoder of BMP files                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Port of t_bmp.pas, from TEXLIB of Gertjan Schouten (1998), with the 1 and   }
{  4 bit support of Matthias Koeppe                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Decoder.Bmp;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Texture.ByteReader;

type
  /// <summary>
  ///   Reads BMP files of 1, 4 and 8 bit with a palette (8 bit also with RLE), and of 24 bit.
  ///   The rows are stored from the bottom, each one padded to 4 bytes
  /// </summary>
  /// <remarks>
  ///   Differences from the old reader: 1 and 4 bit images did not work (they crashed for
  ///   they had no palette: now they are read, with the palette that follows the headers);
  ///   a size that is zero, negative or above TEXTURE_MAX_DIMENSION gives false (the old
  ///   one passed it to a Word); the pixels are read from the offset that the header gives
  ///   when it is not 54; what the file does not have is 0 and what an RLE code would write
  ///   outside the image is dropped. Not read (false, as before): 32 bit, RLE of 4 bit
  /// </remarks>
  TTextureBmpDecoder = class(TInterfacedObject, ITextureDecoder)
  strict private
    const
      HEADERS_SIZE = 54;
      MAX_PALETTE_BYTES = TEXTURE_PALETTE_SIZE * 4;
      COMPRESSION_RGB = 0;
      COMPRESSION_RLE8 = 1;
    type
      TBitmapFileHeader = packed record
        FileType: Word;
        FileSize: LongWord;
        Reserved1: Word;
        Reserved2: Word;
        DataOffset: LongWord;
      end;
      TBitmapInfoHeader = packed record
        Size: Integer;
        Width: Integer;
        Height: Integer;
        Planes: Word;
        BitCount: Word;
        Compression: Integer;
        SizeImage: Integer;
        XPelsPerMeter: Integer;
        YPelsPerMeter: Integer;
        ColorsUsed: Integer;
        ColorsImportant: Integer;
      end;
    procedure ReadPalette(const AReader: TTextureByteReader; const AFile: TBitmapFileHeader;
      const AInfo: TBitmapInfoHeader; const AImage: TTextureImage);
    procedure DecodeRle8(const AReader: TTextureByteReader; const AInfo: TBitmapInfoHeader;
      const AImage: TTextureImage);
    procedure DecodeRows(const AReader: TTextureByteReader; const AInfo: TBitmapInfoHeader;
      const AImage: TTextureImage);
    function GetExtension: string;
  public
    function Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
  end;

implementation

{ TTextureBmpDecoder }

function TTextureBmpDecoder.GetExtension: string;
begin
  Result := '.BMP';
end;

procedure TTextureBmpDecoder.ReadPalette(const AReader: TTextureByteReader;
  const AFile: TBitmapFileHeader; const AInfo: TBitmapInfoHeader; const AImage: TTextureImage);
var
  LCount: Integer;
  LBytes: TBytes;
begin
  // the entries are between the headers and the data, 4 bytes each: B, G, R, 0
  LCount := Integer(AFile.DataOffset) - HEADERS_SIZE;
  if LCount < 0 then
    LCount := 0;
  if LCount > MAX_PALETTE_BYTES then
    LCount := MAX_PALETTE_BYTES;
  LBytes := AReader.ReadBytes(LCount);
  AImage.SetPaletteFromRecords(LBytes, 0, TEXTURE_PALETTE_SIZE, 4, TTexturePaletteLayout.Bgr8);
end;

procedure TTextureBmpDecoder.DecodeRle8(const AReader: TTextureByteReader;
  const AInfo: TBitmapInfoHeader; const AImage: TTextureImage);
var
  LX, LY: Integer;
  LFirst, LSecond: Byte;
  LCount: Integer;
  LBuffer: TBytes;
  LDeltaX, LDeltaY: Byte;
begin
  LY := AInfo.Height - 1;
  LX := 0;
  SetLength(LBuffer, 256);
  while (LY >= 0) and not AReader.Overrun do
  begin
    LFirst := AReader.ReadByte;
    LSecond := AReader.ReadByte;
    if LFirst <> 0 then
    begin
      // LFirst pixels of the color LSecond
      FillChar(LBuffer[0], LFirst, LSecond);
      AImage.PutPixels(LX, LY, LFirst, LBuffer, 0, TEXTURE_FORMAT_8BIT);
      Inc(LX, LFirst);
    end
    else
      case LSecond of
        0:
        begin
          Dec(LY);
          LX := 0;
        end;
        1:
          Break;
        2:
        begin
          LDeltaX := AReader.ReadByte;
          LDeltaY := AReader.ReadByte;
          Inc(LX, LDeltaX);
          Dec(LY, LDeltaY);
        end;
      else
        begin
          LCount := LSecond;
          // the pixels go in words
          AReader.Read(LBuffer[0], (LCount + 1) and $FFFE);
          AImage.PutPixels(LX, LY, LCount, LBuffer, 0, TEXTURE_FORMAT_8BIT);
          Inc(LX, LCount);
        end;
      end;
  end;
end;

procedure TTextureBmpDecoder.DecodeRows(const AReader: TTextureByteReader;
  const AInfo: TBitmapInfoHeader; const AImage: TTextureImage);
var
  LStride: Integer;
  LRow: TBytes;
  LY: Integer;
begin
  LStride := ((AInfo.Width * AInfo.BitCount + 31) div 32) * 4;
  // a pixel of 24 bit is read as 4 bytes: one more than the row
  SetLength(LRow, LStride + 4);
  for LY := AInfo.Height - 1 downto 0 do
  begin
    FillChar(LRow[0], Length(LRow), 0);
    AReader.Read(LRow[0], LStride);
    AImage.PutPixels(0, LY, AInfo.Width, LRow, 0, AInfo.BitCount);
  end;
end;

function TTextureBmpDecoder.Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
var
  LReader: TTextureByteReader;
  LFile: TBitmapFileHeader;
  LInfo: TBitmapInfoHeader;
begin
  Result := False;
  LReader := TTextureByteReader.Create(ASource);
  try
    LReader.Read(LFile, SizeOf(LFile));
    LReader.Read(LInfo, SizeOf(LInfo));
    if (LInfo.Width <= 0) or (LInfo.Height <= 0) or (LInfo.Width > TEXTURE_MAX_DIMENSION) or
       (LInfo.Height > TEXTURE_MAX_DIMENSION) then
      Exit;

    if AImage.BytesPerPixel = 0 then
      case LInfo.BitCount of
        1, 4, 8:
          AImage.SetBytesPerPixel(1);
      else
        AImage.SetBytesPerPixel(4);
      end;
    AImage.SetWidth(LInfo.Width);
    AImage.SetHeight(LInfo.Height);
    if not AImage.HasPixels then
      Exit;

    if LInfo.BitCount in [1, 4, 8] then
      ReadPalette(LReader, LFile, LInfo, AImage);
    if (LFile.DataOffset >= HEADERS_SIZE) and (LFile.DataOffset <= Cardinal(Length(ASource))) then
      LReader.Seek(Integer(LFile.DataOffset));

    case LInfo.BitCount of
      1, 4:
        if LInfo.Compression = COMPRESSION_RGB then
        begin
          DecodeRows(LReader, LInfo, AImage);
          Result := True;
        end;
      8:
        if LInfo.Compression = COMPRESSION_RGB then
        begin
          DecodeRows(LReader, LInfo, AImage);
          Result := True;
        end
        else if LInfo.Compression = COMPRESSION_RLE8 then
        begin
          DecodeRle8(LReader, LInfo, AImage);
          Result := True;
        end;
      24:
      begin
        DecodeRows(LReader, LInfo, AImage);
        Result := True;
      end;
    end;
  finally
    LReader.Free;
  end;
end;

end.
