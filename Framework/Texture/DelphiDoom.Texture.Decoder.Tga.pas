{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - decoder of TGA files                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Port of t_tga.pas, from TEXLIB of Gertjan Schouten (1998)                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Decoder.Tga;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Texture.ByteReader;

type
  /// <summary>
  ///   Reads TGA files: color mapped images of 8 bit (types 1 and 9, maps of 15, 16, 24 and
  ///   32 bit) and true color of 16 (types 2 and 10), 24 and 32 bit; the types 9 and 10 are RLE
  /// </summary>
  /// <remarks>
  ///   As the old reader it takes the rows as stored from the bottom whatever the origin
  ///   bit of the header says, and the color map always starts at the first entry of
  ///   the table. Differences: a type that the old code could not read (gray scale, a type that does
  ///   not go with the pixel size) gave true with a blank image, now it gives false; a truncated file gives
  ///   the rows that it has and zeros for the others; the size is limited to TEXTURE_MAX_DIMENSION
  /// </remarks>
  TTextureTgaDecoder = class(TInterfacedObject, ITextureDecoder)
  strict private
    type
      TTgaHeader = packed record
        IdLength: Byte;
        ColorMapType: Byte;
        ImageType: Byte;
        ColorMapOrigin: Word;
        ColorMapLength: Word;
        ColorMapEntrySize: Byte;
        XOrigin: Word;
        YOrigin: Word;
        Width: Word;
        Height: Word;
        PixelSize: Byte;
        Descriptor: Byte;
      end;
    procedure ReadColorMap(const AReader: TTextureByteReader; const AHeader: TTgaHeader;
      const AImage: TTextureImage);
    function DecodePixels(const AReader: TTextureByteReader; const AHeader: TTgaHeader;
      const AImage: TTextureImage; ASourceBytes, ABits: Integer; AType, ARleType: Byte): Boolean;
    function GetExtension: string;
  public
    function Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
  end;

implementation

{ TTextureTgaDecoder }

function TTextureTgaDecoder.GetExtension: string;
begin
  Result := '.TGA';
end;

procedure TTextureTgaDecoder.ReadColorMap(const AReader: TTextureByteReader;
  const AHeader: TTgaHeader; const AImage: TTextureImage);
var
  LSize: Integer;
  LLayout: TTexturePaletteLayout;
  LBytes: TBytes;
begin
  if AHeader.ColorMapLength = 0 then
    Exit;
  case AHeader.ColorMapEntrySize of
    15, 16:
    begin
      LSize := 2;
      LLayout := TTexturePaletteLayout.Bgr5;
    end;
    24:
    begin
      LSize := 3;
      LLayout := TTexturePaletteLayout.Bgr8;
    end;
    32:
    begin
      LSize := 4;
      LLayout := TTexturePaletteLayout.Bgr8;
    end;
  else
    Exit;
  end;
  LBytes := AReader.ReadBytes(AHeader.ColorMapLength * LSize);
  AImage.SetPaletteFromRecords(LBytes, 0, AHeader.ColorMapLength, LSize, LLayout);
end;

function TTextureTgaDecoder.DecodePixels(const AReader: TTextureByteReader;
  const AHeader: TTgaHeader; const AImage: TTextureImage; ASourceBytes, ABits: Integer;
  AType, ARleType: Byte): Boolean;
var
  LWidth: Integer;
  LRow: TBytes;
  LPixel: TBytes;
  LX, LY, LIndex, LCount: Integer;
  LControl: Byte;
  LIsRun: Boolean;

  // a pixel of the file goes to the row; when the row is complete it goes to the image
  procedure Store;
  begin
    Move(LPixel[0], LRow[LX * ASourceBytes], ASourceBytes);
    Inc(LX);
    if LX >= LWidth then
    begin
      AImage.PutPixels(0, LY, LWidth, LRow, 0, ABits);
      Dec(LY);
      LX := 0;
    end;
  end;

begin
  Result := True;
  LWidth := AHeader.Width;
  // a pixel of 24 bit is read as 4 bytes: one more than the row
  SetLength(LRow, LWidth * ASourceBytes + 4);
  SetLength(LPixel, 4);
  if AHeader.ImageType = AType then
  begin
    for LIndex := AHeader.Height - 1 downto 0 do
    begin
      FillChar(LRow[0], Length(LRow), 0);
      AReader.Read(LRow[0], LWidth * ASourceBytes);
      AImage.PutPixels(0, LIndex, LWidth, LRow, 0, ABits);
    end;
  end
  else if AHeader.ImageType = ARleType then
  begin
    LX := 0;
    LY := AHeader.Height - 1;
    while LY >= 0 do
    begin
      LControl := AReader.ReadByte;
      LIsRun := LControl > 127;
      if LIsRun then
        LCount := LControl - 128
      else
        LCount := LControl;
      if LIsRun then
      begin
        FillChar(LPixel[0], 4, 0);
        AReader.Read(LPixel[0], ASourceBytes);
      end;
      for LIndex := 0 to LCount do
      begin
        if not LIsRun then
        begin
          FillChar(LPixel[0], 4, 0);
          AReader.Read(LPixel[0], ASourceBytes);
        end;
        Store;
        if LY < 0 then
          Break;
      end;
    end;
  end
  else
    Result := False;
end;

function TTextureTgaDecoder.Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
var
  LReader: TTextureByteReader;
  LHeader: TTgaHeader;
begin
  Result := False;
  LReader := TTextureByteReader.Create(ASource);
  try
    LReader.Read(LHeader, SizeOf(LHeader));
    if AImage.BytesPerPixel = 0 then
      case LHeader.PixelSize of
        8:
          AImage.SetBytesPerPixel(1);
        16:
          AImage.SetBytesPerPixel(2);
        24, 32:
          AImage.SetBytesPerPixel(4);
      end;
    if (LHeader.Width > TEXTURE_MAX_DIMENSION) or (LHeader.Height > TEXTURE_MAX_DIMENSION) then
      Exit;
    AImage.SetWidth(LHeader.Width);
    AImage.SetHeight(LHeader.Height);
    if not AImage.HasPixels then
      Exit;
    // the identification field, then the color map
    LReader.ReadBytes(LHeader.IdLength);
    ReadColorMap(LReader, LHeader, AImage);

    case LHeader.PixelSize of
      8:
        case LHeader.ImageType of
          1, 9:
            if LHeader.ColorMapEntrySize in [15, 16, 24, 32] then
              Result := DecodePixels(LReader, LHeader, AImage, 1, TEXTURE_FORMAT_8BIT, 1, 9);
        end;
      16:
        Result := DecodePixels(LReader, LHeader, AImage, 2, TEXTURE_FORMAT_16BIT, 2, 10);
      24:
        Result := DecodePixels(LReader, LHeader, AImage, 3, TEXTURE_FORMAT_24BIT, 2, 10);
      32:
        Result := DecodePixels(LReader, LHeader, AImage, 4, TEXTURE_FORMAT_32BIT, 2, 10);
    end;
  finally
    LReader.Free;
  end;
end;

end.
