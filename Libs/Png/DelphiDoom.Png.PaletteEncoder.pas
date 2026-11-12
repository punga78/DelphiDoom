{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG library - from a picture with a palette to an indexed PNG    }
{  file (color type 3)                                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.PaletteEncoder;

interface

uses
  System.SysUtils, DelphiDoom.Zlib.Client, DelphiDoom.Png.IndexedImage, DelphiDoom.Png.PaletteEncoder.Intf;

type
  /// <summary>
  ///   IPngPaletteEncoder: IHDR (8 bit, color type 3), PLTE, tRNS when an index is transparent, one IDAT with the
  ///   rows unfiltered and compressed by the zlib client, IEND
  /// </summary>
  TPngPaletteEncoder = class(TInterfacedObject, IPngPaletteEncoder)
  strict private
    FZlib: TZlibClient;
    class procedure AppendChunk(var AFile: TBytes; const AType: AnsiString; const AData: TBytes); static;
    class procedure PutLong(var ABytes: TBytes; AOffset: Integer; AValue: Cardinal); static;
  public
    /// <param name="AZlib">The compressor; not owned</param>
    constructor Create(AZlib: TZlibClient);
    function Encode(const AImage: TIndexedImage; const APalette: TBytes;
      ATransparentIndex: Integer = PNG_PALETTE_OPAQUE): TBytes;
  end;

implementation

uses
  DelphiDoom.Png.Crc;

const
  SIGNATURE: array[0..7] of Byte = ($89, $50, $4E, $47, $0D, $0A, $1A, $0A);
  BIT_DEPTH = 8;
  COLOR_TYPE_PALETTE = 3;
  MAX_PALETTE_BYTES = 768;
  SImageSize = 'A picture of %d x %d pixels cannot have %d bytes';
  SPaletteSize = 'A palette cannot have %d bytes';
  SPixelWithoutColor = 'The pixel %d has the index %d and the palette has %d colors';

constructor TPngPaletteEncoder.Create(AZlib: TZlibClient);
begin
  inherited Create;
  if not Assigned(AZlib) then
    raise EArgumentNilException.Create('AZlib');
  FZlib := AZlib;
end;

class procedure TPngPaletteEncoder.PutLong(var ABytes: TBytes; AOffset: Integer; AValue: Cardinal);
begin
  ABytes[AOffset] := Byte(AValue shr 24);
  ABytes[AOffset + 1] := Byte(AValue shr 16 and $FF);
  ABytes[AOffset + 2] := Byte(AValue shr 8 and $FF);
  ABytes[AOffset + 3] := Byte(AValue and $FF);
end;

class procedure TPngPaletteEncoder.AppendChunk(var AFile: TBytes; const AType: AnsiString; const AData: TBytes);
var
  LStart: Integer;
  LCrc: Cardinal;
begin
  LStart := Length(AFile);
  SetLength(AFile, LStart + 12 + Length(AData));
  PutLong(AFile, LStart, Cardinal(Length(AData)));
  Move(AType[1], AFile[LStart + 4], 4);
  if Length(AData) > 0 then
    Move(AData[0], AFile[LStart + 8], Length(AData));
  // the CRC covers the type and the data
  LCrc := TPngCrc.Compute(@AFile[LStart + 4], Cardinal(4 + Length(AData)));
  PutLong(AFile, LStart + 8 + Length(AData), LCrc);
end;

function TPngPaletteEncoder.Encode(const AImage: TIndexedImage; const APalette: TBytes;
  ATransparentIndex: Integer): TBytes;
var
  LColors: Integer;
  LHeader: TBytes;
  LAlpha: TBytes;
  LRows: TBytes;
  LIndex: Integer;
  LY: Integer;
begin
  if not AImage.IsValid then
    raise EPngPaletteEncoderException.CreateFmt(SImageSize, [AImage.Width, AImage.Height, Length(AImage.Pixels)]);
  if (Length(APalette) = 0) or (Length(APalette) mod 3 <> 0) or (Length(APalette) > MAX_PALETTE_BYTES) then
    raise EPngPaletteEncoderException.CreateFmt(SPaletteSize, [Length(APalette)]);
  LColors := Length(APalette) div 3;
  for LIndex := 0 to High(AImage.Pixels) do
    if AImage.Pixels[LIndex] >= LColors then
      raise EPngPaletteEncoderException.CreateFmt(SPixelWithoutColor, [LIndex, AImage.Pixels[LIndex], LColors]);
  SetLength(Result, Length(SIGNATURE));
  Move(SIGNATURE[0], Result[0], Length(SIGNATURE));
  SetLength(LHeader, 13);
  PutLong(LHeader, 0, Cardinal(AImage.Width));
  PutLong(LHeader, 4, Cardinal(AImage.Height));
  LHeader[8] := BIT_DEPTH;
  LHeader[9] := COLOR_TYPE_PALETTE;
  LHeader[10] := 0;
  LHeader[11] := 0;
  LHeader[12] := 0;
  AppendChunk(Result, 'IHDR', LHeader);
  AppendChunk(Result, 'PLTE', APalette);
  if (ATransparentIndex >= 0) and (ATransparentIndex < LColors) then
  begin
    // one alpha for every color up to the transparent one; the colors after it are opaque by default
    SetLength(LAlpha, ATransparentIndex + 1);
    for LIndex := 0 to ATransparentIndex - 1 do
      LAlpha[LIndex] := 255;
    LAlpha[ATransparentIndex] := 0;
    AppendChunk(Result, 'tRNS', LAlpha);
  end;
  // every row starts with its filter: 0, none
  SetLength(LRows, (AImage.Width + 1) * AImage.Height);
  for LY := 0 to AImage.Height - 1 do
  begin
    LRows[LY * (AImage.Width + 1)] := 0;
    Move(AImage.Pixels[LY * AImage.Width], LRows[LY * (AImage.Width + 1) + 1], AImage.Width);
  end;
  AppendChunk(Result, 'IDAT', FZlib.Compress(LRows));
  AppendChunk(Result, 'IEND', nil);
end;

end.
