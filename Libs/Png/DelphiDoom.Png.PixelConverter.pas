{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - converts the pixels of a scanline to 8 bit                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.PixelConverter;

interface

{$POINTERMATH ON}

uses
  DelphiDoom.Png.Header, DelphiDoom.Png.Metadata;

type
  /// <summary>
  ///   Turns the samples of a reconstructed scanline (any color type and bit
  ///   depth) into BGRA pixels or into palette indices. The pixels of a pass
  ///   of an interlaced image are not adjacent: the destination advances by
  ///   ADestStep bytes from one pixel to the next
  /// </summary>
  TPngPixelConverter = class
  private
    FHeader: TPngHeader;
    FPalette: TPngPaletteTable;
    FHasKey: Boolean;
    FKeyGray: Integer;
    FKeyRed: Integer;
    FKeyGreen: Integer;
    FKeyBlue: Integer;

    class function Pack(ABlue, AGreen, ARed, AAlpha: Cardinal): Cardinal; static;
    function SampleAt(ASource: PByte; AIndex: Integer): Integer;
    procedure ConvertGray(ASource: PByte; ACount: Integer; ADest: PByte;
      ADestStep: Integer);
    procedure ConvertRgb(ASource: PByte; ACount: Integer; ADest: PByte;
      ADestStep: Integer);
    procedure ConvertPalette(ASource: PByte; ACount: Integer; ADest: PByte;
      ADestStep: Integer);
    procedure ConvertGrayAlpha(ASource: PByte; ACount: Integer; ADest: PByte;
      ADestStep: Integer);
    procedure ConvertRgba(ASource: PByte; ACount: Integer; ADest: PByte;
      ADestStep: Integer);
  public
    /// <summary>
    ///   AMetadata must have been resolved: its palette and transparency are
    ///   copied
    /// </summary>
    constructor Create(AMetadata: TPngMetadata);

    /// <summary>
    ///   Converts ACount pixels to BGRA (4 bytes each) written ADestStep bytes
    ///   apart. Alpha is 255 unless the image has an alpha channel or a
    ///   transparency (tRNS) that says otherwise
    /// </summary>
    procedure ToBgra(ASource: PByte; ACount: Integer; ADest: PByte;
      ADestStep: Integer);

    /// <summary>
    ///   Writes the palette index of ACount pixels (one byte each) ADestStep
    ///   bytes apart. Only for palette images
    /// </summary>
    procedure ToIndices(ASource: PByte; ACount: Integer; ADest: PByte;
      ADestStep: Integer);
  end;

implementation

uses
  DelphiDoom.Png.Intf, DelphiDoom.Png.ByteOrder;

{ TPngPixelConverter }

constructor TPngPixelConverter.Create(AMetadata: TPngMetadata);
begin
  inherited Create;
  FHeader := AMetadata.Header;
  AMetadata.CopyPaletteTo(@FPalette);
  FHasKey := AMetadata.HasKey;
  FKeyGray := AMetadata.KeyGray;
  FKeyRed := AMetadata.KeyRed;
  FKeyGreen := AMetadata.KeyGreen;
  FKeyBlue := AMetadata.KeyBlue;
end;

class function TPngPixelConverter.Pack(ABlue, AGreen, ARed,
  AAlpha: Cardinal): Cardinal;
begin
  // Little endian: the bytes in memory are B, G, R, A
  Result := ABlue or (AGreen shl 8) or (ARed shl 16) or (AAlpha shl 24);
end;

function TPngPixelConverter.SampleAt(ASource: PByte; AIndex: Integer): Integer;
var
  LBitOffset: Integer;
  LShift: Integer;
begin
  // Samples of 1, 2 or 4 bits: packed from the most significant bit
  LBitOffset := AIndex * FHeader.BitDepth;
  LShift := 8 - FHeader.BitDepth - (LBitOffset and 7);
  Result := (ASource[LBitOffset shr 3] shr LShift) and ((1 shl FHeader.BitDepth) - 1);
end;

procedure TPngPixelConverter.ConvertGray(ASource: PByte; ACount: Integer;
  ADest: PByte; ADestStep: Integer);
var
  LIndex: Integer;
  LSample: Integer;
  LGray: Cardinal;
  LAlpha: Cardinal;
  LMaximum: Integer;
begin
  LMaximum := (1 shl FHeader.BitDepth) - 1;
  for LIndex := 0 to ACount - 1 do
  begin
    case FHeader.BitDepth of
      16:
        begin
          LSample := Integer(TPngByteOrder.ReadWord(ASource + LIndex * 2));
          LGray := ASource[LIndex * 2];
        end;
      8:
        begin
          LSample := ASource[LIndex];
          LGray := Cardinal(LSample);
        end;
    else
      LSample := SampleAt(ASource, LIndex);
      LGray := Cardinal(LSample * 255 div LMaximum);
    end;

    if FHasKey and (LSample = FKeyGray) then
      LAlpha := 0
    else
      LAlpha := 255;

    PCardinal(ADest)^ := Pack(LGray, LGray, LGray, LAlpha);
    Inc(ADest, ADestStep);
  end;
end;

procedure TPngPixelConverter.ConvertRgb(ASource: PByte; ACount: Integer;
  ADest: PByte; ADestStep: Integer);
var
  LIndex: Integer;
  LPixel: PByte;
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
  LShift: Integer;
  LAlpha: Cardinal;
begin
  // Samples are compared with the key at their own depth and reduced to
  // 8 bits (the high byte of a 16 bit sample) for the pixel
  LShift := FHeader.BitDepth - 8;
  for LIndex := 0 to ACount - 1 do
  begin
    if FHeader.BitDepth = 16 then
    begin
      LPixel := ASource + LIndex * 6;
      LRed := Integer(TPngByteOrder.ReadWord(LPixel));
      LGreen := Integer(TPngByteOrder.ReadWord(LPixel + 2));
      LBlue := Integer(TPngByteOrder.ReadWord(LPixel + 4));
    end
    else
    begin
      LPixel := ASource + LIndex * 3;
      LRed := LPixel[0];
      LGreen := LPixel[1];
      LBlue := LPixel[2];
    end;

    if FHasKey and (LRed = FKeyRed) and (LGreen = FKeyGreen) and
       (LBlue = FKeyBlue) then
      LAlpha := 0
    else
      LAlpha := 255;

    PCardinal(ADest)^ := Pack(Cardinal(LBlue shr LShift),
      Cardinal(LGreen shr LShift), Cardinal(LRed shr LShift), LAlpha);
    Inc(ADest, ADestStep);
  end;
end;

procedure TPngPixelConverter.ConvertPalette(ASource: PByte; ACount: Integer;
  ADest: PByte; ADestStep: Integer);
var
  LIndex: Integer;
  LEntry: Integer;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    if FHeader.BitDepth = 8 then
      LEntry := ASource[LIndex]
    else
      LEntry := SampleAt(ASource, LIndex);
    // An index beyond the palette reads an opaque black entry
    PCardinal(ADest)^ := FPalette[LEntry];
    Inc(ADest, ADestStep);
  end;
end;

procedure TPngPixelConverter.ConvertGrayAlpha(ASource: PByte; ACount: Integer;
  ADest: PByte; ADestStep: Integer);
var
  LIndex: Integer;
  LPixel: PByte;
  LGray: Cardinal;
  LAlpha: Cardinal;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    // 8 bit: gray, alpha. 16 bit: the high bytes of the two samples
    if FHeader.BitDepth = 16 then
    begin
      LPixel := ASource + LIndex * 4;
      LGray := LPixel[0];
      LAlpha := LPixel[2];
    end
    else
    begin
      LPixel := ASource + LIndex * 2;
      LGray := LPixel[0];
      LAlpha := LPixel[1];
    end;
    PCardinal(ADest)^ := Pack(LGray, LGray, LGray, LAlpha);
    Inc(ADest, ADestStep);
  end;
end;

procedure TPngPixelConverter.ConvertRgba(ASource: PByte; ACount: Integer;
  ADest: PByte; ADestStep: Integer);
var
  LIndex: Integer;
  LPixel: PByte;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    // 8 bit: R, G, B, A. 16 bit: the high byte of each sample comes first
    if FHeader.BitDepth = 16 then
    begin
      LPixel := ASource + LIndex * 8;
      PCardinal(ADest)^ := Pack(LPixel[4], LPixel[2], LPixel[0], LPixel[6]);
    end
    else
    begin
      LPixel := ASource + LIndex * 4;
      PCardinal(ADest)^ := Pack(LPixel[2], LPixel[1], LPixel[0], LPixel[3]);
    end;
    Inc(ADest, ADestStep);
  end;
end;

procedure TPngPixelConverter.ToBgra(ASource: PByte; ACount: Integer;
  ADest: PByte; ADestStep: Integer);
begin
  case FHeader.ColorType of
    DDPNG_COLOR_GRAY:       ConvertGray(ASource, ACount, ADest, ADestStep);
    DDPNG_COLOR_RGB:        ConvertRgb(ASource, ACount, ADest, ADestStep);
    DDPNG_COLOR_PALETTE:    ConvertPalette(ASource, ACount, ADest, ADestStep);
    DDPNG_COLOR_GRAY_ALPHA: ConvertGrayAlpha(ASource, ACount, ADest, ADestStep);
    DDPNG_COLOR_RGBA:       ConvertRgba(ASource, ACount, ADest, ADestStep);
  end;
end;

procedure TPngPixelConverter.ToIndices(ASource: PByte; ACount: Integer;
  ADest: PByte; ADestStep: Integer);
var
  LIndex: Integer;
begin
  if FHeader.ColorType <> DDPNG_COLOR_PALETTE then
    raise EPngException.CreateCode(DDPNG_ERR_UNSUPPORTED);

  for LIndex := 0 to ACount - 1 do
  begin
    if FHeader.BitDepth = 8 then
      ADest^ := ASource[LIndex]
    else
      ADest^ := Byte(SampleAt(ASource, LIndex));
    Inc(ADest, ADestStep);
  end;
end;

end.
