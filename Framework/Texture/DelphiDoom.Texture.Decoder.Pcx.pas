{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - decoder of PCX files                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Port of t_pcx.pas (TPCXImage of M. de Haan, 2001-2002) without the VCL      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Decoder.Pcx;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Texture.ByteReader, DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   Reads PCX files. The main reader takes version 5 files that are 24 bit in three planes
  ///   or 8 bit with the palette in the last 769 bytes (and 1 bit with such a palette); the
  ///   others go to TTexturePcxLegacyReader. The result is always a 32 bit image
  /// </summary>
  /// <remarks>
  ///   The old code saved the file in a temporary file, read it with the VCL (a TGraphic
  ///   and a TBitmap) and read it again with another loader when the first failed; it also
  ///   crashed the game on the files that the second one could not draw. Here nothing
  ///   touches the disk or the VCL and a file that cannot be read gives a warning and false.
  ///   Kept as they were: the run codes ($C0 is a plain byte for the main reader), a line takes as
  ///   many bytes as the width (the padding byte of an odd width belongs to the next line
  ///   then) and the width of a 1 bit image goes up to a multiple of 8
  /// </remarks>
  TTexturePcxDecoder = class(TInterfacedObject, ITextureDecoder)
  strict private
    const
      HEADER_SIZE = 128;
      MAX_WIDTH = $FFF;
      MAX_HEIGHT = 8192;
      PALETTE_SIZE = 769;
      SFormatError = 'Illegal identification byte in PCX file header';
      SVersionError = 'Only PC Paintbrush (plus) V3.0 and higher are supported';
      SWidthError = 'Illegal width entry in PCX file header';
      SHeightError = 'Illegal height entry in PCX file header';
      SWidthTooLarge = 'Width of PCX image is too large to handle';
      SUnsupported = 'Unsupported PCX format';
      SPaletteError = 'Invalid palette signature found';
      SOutOfMemory = 'Out of memory';
      SEmptyImage = 'The PCX image is empty';
      STruncated = 'The PCX data end before the image';
    type
      TPcxHeader = packed record
        Identifier: Byte;
        Version: Byte;
        Compressed: Byte;
        BitsPerPixel: Byte;
        Left: Word;
        Top: Word;
        Right: Word;
        Bottom: Word;
        HorizontalResolution: Word;
        VerticalResolution: Word;
        ColorMap: array[0..47] of Byte;
        Reserved: Byte;
        Planes: Byte;
        BytesPerLine: Word;
        PaletteInfo: Word;
        Filler: array[0..57] of Byte;
      end;
    var
      FLog: ILog;
    class procedure DecodeLine(const AData: TBytes; var APosition: Integer; AWidth: Integer;
      var ALine: TBytes); static;
    function ReadStandard(const ASource: TBytes; out AWidth, AHeight: Integer;
      out APixels: TTexturePixels; out AMessage: string): Boolean;
    function GetExtension: string;
  public
    constructor Create(const ALog: ILog);
    function Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
    /// <summary>
    ///   True when the first 128 bytes look like the header of a PCX file that this
    ///   reader may take (the engine uses it to tell a PCX in a PAK from other lumps)
    /// </summary>
    class function IsValidHeader(const ABytes: TBytes): Boolean; static;
  end;

implementation

uses
  DelphiDoom.Texture.Decoder.PcxLegacy;

{ TTexturePcxDecoder }

constructor TTexturePcxDecoder.Create(const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FLog := ALog;
end;

function TTexturePcxDecoder.GetExtension: string;
begin
  Result := '.PCX';
end;

class function TTexturePcxDecoder.IsValidHeader(const ABytes: TBytes): Boolean;
var
  LHeader: TPcxHeader;
  LWidth, LHeight: Integer;
  LFormat: Byte;
begin
  Result := False;
  if Length(ABytes) < HEADER_SIZE then
    Exit;
  Move(ABytes[0], LHeader, SizeOf(LHeader));
  if LHeader.Identifier <> $0A then
    Exit;
  if not (LHeader.Version in [0, 2, 3, 4, 5]) then
    Exit;
  if not (LHeader.Compressed in [0, 1]) then
    Exit;
  LWidth := LHeader.Right - LHeader.Left + 1;
  // a width or a height of 1 is not accepted
  if (LWidth <= 1) or (LWidth > MAX_WIDTH) then
    Exit;
  LHeight := LHeader.Bottom - LHeader.Top + 1;
  if (LHeight <= 1) or (LHeight > MAX_HEIGHT) then
    Exit;
  LFormat := Byte(LHeader.Planes * LHeader.BitsPerPixel);
  Result := LFormat in [1, 4, 8, 16, 24, 32];
end;

// One line of a plane of the run length coding: a byte up to $C0 is itself, a byte above it
// counts the next one ($C1 is one time). A run does not stop at the end of the line, the part
// that goes over it is dropped
class procedure TTexturePcxDecoder.DecodeLine(const AData: TBytes; var APosition: Integer;
  AWidth: Integer; var ALine: TBytes);
var
  LX: Integer;
  LByte: Byte;
  LCount: Integer;
  LIndex: Integer;

  function NextByte: Byte;
  begin
    if APosition < Length(AData) then
      Result := AData[APosition]
    else
      Result := 0;
    Inc(APosition);
  end;

begin
  LX := 0;
  repeat
    LByte := NextByte;
    if LByte < $C1 then
    begin
      if LX <= AWidth then
      begin
        ALine[LX] := LByte;
        Inc(LX);
      end;
    end
    else
    begin
      LCount := LByte and $3F;
      LByte := NextByte;
      for LIndex := 1 to LCount do
        if LX <= AWidth then
        begin
          ALine[LX] := LByte;
          Inc(LX);
        end;
    end;
  until LX >= AWidth;
end;

function TTexturePcxDecoder.ReadStandard(const ASource: TBytes; out AWidth, AHeight: Integer;
  out APixels: TTexturePixels; out AMessage: string): Boolean;
var
  LHeader: TPcxHeader;
  LFormat: Byte;
  LData: TBytes;
  LDataLength: Int64;
  LPalette: array[0..255] of Cardinal;
  LPosition: Integer;
  LY, LX: Integer;
  LRed, LGreen, LBlue, LLine: TBytes;
  LBytes: Integer;
  LPaletteStart: Integer;
  LIndex: Integer;
begin
  Result := False;
  AWidth := 0;
  AHeight := 0;
  APixels := nil;
  AMessage := '';
  if Length(ASource) < HEADER_SIZE then
  begin
    FillChar(LHeader, SizeOf(LHeader), 0);
    if Length(ASource) > 0 then
      Move(ASource[0], LHeader, Length(ASource));
  end
  else
    Move(ASource[0], LHeader, SizeOf(LHeader));

  if LHeader.Identifier <> $0A then
  begin
    AMessage := SFormatError;
    Exit;
  end;
  if LHeader.Version <> 5 then
  begin
    AMessage := SVersionError;
    Exit;
  end;
  AWidth := Integer(LHeader.Right) - Integer(LHeader.Left) + 1;
  if AWidth < 0 then
  begin
    AMessage := SWidthError;
    Exit;
  end;
  AHeight := Integer(LHeader.Bottom) - Integer(LHeader.Top) + 1;
  if AHeight < 0 then
  begin
    AMessage := SHeightError;
    Exit;
  end;
  if AWidth > MAX_WIDTH then
  begin
    AMessage := SWidthTooLarge;
    Exit;
  end;
  LFormat := Byte(LHeader.Planes * LHeader.BitsPerPixel);
  if not (LFormat in [1, 8, 24]) then
  begin
    AMessage := SUnsupported;
    Exit;
  end;
  if (AWidth = 0) or (AHeight = 0) or (AHeight > TEXTURE_MAX_DIMENSION) then
  begin
    AMessage := SEmptyImage;
    Exit;
  end;

  if LFormat = 24 then
  begin
    LDataLength := Int64(Length(ASource)) - HEADER_SIZE;
    if LDataLength < 0 then
      LDataLength := 0;
    SetLength(LData, LDataLength);
    if LDataLength > 0 then
      Move(ASource[HEADER_SIZE], LData[0], LDataLength);
  end
  else
  begin
    // the data end where the palette begins
    LDataLength := Int64(Length(ASource)) - HEADER_SIZE - PALETTE_SIZE;
    if LDataLength < 0 then
    begin
      AMessage := SOutOfMemory;
      Exit;
    end;
    SetLength(LData, LDataLength);
    if LDataLength > 0 then
      Move(ASource[HEADER_SIZE], LData[0], LDataLength);
    LPaletteStart := HEADER_SIZE + Integer(LDataLength);
    if ASource[LPaletteStart] <> $0C then
    begin
      AMessage := SPaletteError;
      Exit;
    end;
    for LIndex := 0 to 255 do
      LPalette[LIndex] := (Cardinal(ASource[LPaletteStart + 1 + LIndex * 3]) shl 16) or
                          (Cardinal(ASource[LPaletteStart + 2 + LIndex * 3]) shl 8) or
                          ASource[LPaletteStart + 3 + LIndex * 3];
  end;

  LPosition := 0;
  if LFormat = 24 then
  begin
    SetLength(APixels, AWidth * AHeight);
    SetLength(LRed, MAX_WIDTH + 2);
    SetLength(LGreen, MAX_WIDTH + 2);
    SetLength(LBlue, MAX_WIDTH + 2);
    for LY := 0 to AHeight - 1 do
    begin
      DecodeLine(LData, LPosition, AWidth, LRed);
      DecodeLine(LData, LPosition, AWidth, LGreen);
      DecodeLine(LData, LPosition, AWidth, LBlue);
      for LX := 0 to AWidth - 1 do
        APixels[LY * AWidth + LX] := (Cardinal(LRed[LX]) shl 16) or (Cardinal(LGreen[LX]) shl 8) or
                                     LBlue[LX];
    end;
  end
  else
  begin
    LBytes := AWidth;
    if LFormat = 1 then
    begin
      // one bit per pixel: a line is made of bytes, the bitmap gets a width that is a multiple of 8
      LBytes := AWidth div 8;
      if (AWidth mod 8) > 0 then
        Inc(LBytes);
      AWidth := LBytes * 8;
    end;
    SetLength(APixels, AWidth * AHeight);
    SetLength(LLine, MAX_WIDTH + 2);
    for LY := 0 to AHeight - 1 do
    begin
      DecodeLine(LData, LPosition, LBytes, LLine);
      for LX := 0 to AWidth - 1 do
        if LFormat = 1 then
          APixels[LY * AWidth + LX] := LPalette[(LLine[LX div 8] shr (7 - (LX and 7))) and 1]
        else
          APixels[LY * AWidth + LX] := LPalette[LLine[LX]];
    end;
  end;
  if LPosition > Length(LData) then
  begin
    // the data end before the image does
    AMessage := STruncated;
    APixels := nil;
    Exit;
  end;
  Result := True;
end;

function TTexturePcxDecoder.Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
var
  LWidth, LHeight: Integer;
  LPixels: TTexturePixels;
  LMessage: string;
begin
  Result := ReadStandard(ASource, LWidth, LHeight, LPixels, LMessage);
  if not Result then
    Result := TTexturePcxLegacyReader.Read(ASource, LWidth, LHeight, LPixels);
  if not Result then
  begin
    if LMessage = '' then
      LMessage := SUnsupported;
    FLog.Warning('TPCXTextureManager(): ' + LMessage + #13#10);
    Exit;
  end;

  AImage.TransparentColor := 0;
  AImage.SetBytesPerPixel(4);
  AImage.SetWidth(LWidth);
  AImage.SetHeight(LHeight);
  if Length(AImage.Pixels) = Length(LPixels) * SizeOf(Cardinal) then
    Move(LPixels[0], AImage.Pixels[0], Length(AImage.Pixels));
  AImage.TransparentColor := 0;
  AImage.TransparentColor2 := 0;
  AImage.TransparentColor3 := 0;
end;

end.
