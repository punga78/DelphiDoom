{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - TDdsBlockDecoder, S3TC (DXT1, DXT3, DXT5)     }
{  block decompression to RGBA                                                 }
{                                                                              }
{  Written from the description of the S3TC formats (public specification:     }
{  EXT_texture_compression_s3tc and the DirectX documentation). Doom 3 does    }
{  not decompress in software, it hands the blocks to the GPU, so there is     }
{  no code of Doom 3 here; licensed under the GNU General Public License,      }
{  version 2 or later.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Dds.BlockDecoder;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Dds.Types, DelphiDoom.Imaging.Rgba.Image;

const
  DDS_BLOCK_SIZE_DXT1 = 8;
  DDS_BLOCK_SIZE_DXT35 = 16;

type
  /// <summary>The 16 texels of a block, row by row, 4 bytes each (R, G, B, A)</summary>
  TDdsBlockPixels = array[0..63] of Byte;

  /// <summary>
  ///   Decodes S3TC blocks. The colours are the 5:6:5 end points expanded to 8 bits by repeating
  ///   the top bits, the two in-between colours are (2a + b) / 3 and (a + 2b) / 3 with integer
  ///   division (the reference rounding of the specification; some GPUs round differently)
  /// </summary>
  TDdsBlockDecoder = class sealed
  strict private
    class procedure DecodeColorBlock(const ABlock: PByte; const AAllowTransparent: Boolean;
      var APixels: TDdsBlockPixels); static;
  public
    /// <summary>The size in bytes of a block of the format (8 for DXT1, 16 for DXT3 and DXT5)</summary>
    class function BlockSize(const AFormat: TDdsFormat): Integer; static;
    /// <summary>The bytes of a surface of AWidth x AHeight texels in DXT: whole blocks, at least one</summary>
    class function SurfaceSize(const AFormat: TDdsFormat; const AWidth, AHeight: Integer): Integer; static;
    /// <summary>
    ///   One block. For DXT1 with the first end point not above the second the fourth colour is
    ///   transparent black (alpha 0); otherwise alpha is 255
    /// </summary>
    class procedure DecodeBlock(const AFormat: TDdsFormat; const ABlock: PByte;
      var APixels: TDdsBlockPixels); static;
    /// <summary>
    ///   A whole surface; the blocks cover a multiple of 4 and what falls outside of
    ///   AWidth x AHeight is dropped. EDdsException when ASource has fewer bytes than SurfaceSize
    /// </summary>
    class function DecodeSurface(const AFormat: TDdsFormat; const ASource: TBytes; const AOffset,
      AWidth, AHeight: Integer): TImagingRgbaImage; static;
  end;

implementation

procedure Expand565(const AColor: Word; out ARed, AGreen, ABlue: Integer);
begin
  ARed := (AColor shr 11) and $1F;
  AGreen := (AColor shr 5) and $3F;
  ABlue := AColor and $1F;
  ARed := (ARed shl 3) or (ARed shr 2);
  AGreen := (AGreen shl 2) or (AGreen shr 4);
  ABlue := (ABlue shl 3) or (ABlue shr 2);
end;

{ TDdsBlockDecoder }

class function TDdsBlockDecoder.BlockSize(const AFormat: TDdsFormat): Integer;
begin
  if AFormat = TDdsFormat.Dxt1 then
    Result := DDS_BLOCK_SIZE_DXT1
  else
    Result := DDS_BLOCK_SIZE_DXT35;
end;

class function TDdsBlockDecoder.SurfaceSize(const AFormat: TDdsFormat; const AWidth,
  AHeight: Integer): Integer;
begin
  Result := ((AWidth + 3) div 4) * ((AHeight + 3) div 4) * BlockSize(AFormat);
end;

class procedure TDdsBlockDecoder.DecodeColorBlock(const ABlock: PByte;
  const AAllowTransparent: Boolean; var APixels: TDdsBlockPixels);
var
  LColor0, LColor1: Word;
  LPalette: array[0..3, 0..3] of Integer;
  LIndices: Cardinal;
  LTexel, LCode, LChannel: Integer;
begin
  LColor0 := ABlock[0] or (ABlock[1] shl 8);
  LColor1 := ABlock[2] or (ABlock[3] shl 8);
  Expand565(LColor0, LPalette[0, 0], LPalette[0, 1], LPalette[0, 2]);
  Expand565(LColor1, LPalette[1, 0], LPalette[1, 1], LPalette[1, 2]);
  LPalette[0, 3] := 255;
  LPalette[1, 3] := 255;
  LPalette[2, 3] := 255;
  LPalette[3, 3] := 255;
  if (LColor0 > LColor1) or (not AAllowTransparent) then
    for LChannel := 0 to 2 do
    begin
      LPalette[2, LChannel] := (2 * LPalette[0, LChannel] + LPalette[1, LChannel]) div 3;
      LPalette[3, LChannel] := (LPalette[0, LChannel] + 2 * LPalette[1, LChannel]) div 3;
    end
  else
  begin
    for LChannel := 0 to 2 do
    begin
      LPalette[2, LChannel] := (LPalette[0, LChannel] + LPalette[1, LChannel]) div 2;
      LPalette[3, LChannel] := 0;
    end;
    LPalette[3, 3] := 0;
  end;
  LIndices := Cardinal(ABlock[4]) or (Cardinal(ABlock[5]) shl 8) or (Cardinal(ABlock[6]) shl 16)
    or (Cardinal(ABlock[7]) shl 24);
  for LTexel := 0 to 15 do
  begin
    LCode := (LIndices shr (2 * LTexel)) and 3;
    for LChannel := 0 to 3 do
      APixels[LTexel * 4 + LChannel] := Byte(LPalette[LCode, LChannel]);
  end;
end;

class procedure TDdsBlockDecoder.DecodeBlock(const AFormat: TDdsFormat; const ABlock: PByte;
  var APixels: TDdsBlockPixels);
var
  LTexel, LAlpha0, LAlpha1, LCode: Integer;
  LBits: UInt64;
  LAlphas: array[0..7] of Integer;
begin
  case AFormat of
    TDdsFormat.Dxt1:
      DecodeColorBlock(ABlock, True, APixels);
    TDdsFormat.Dxt3:
      begin
        DecodeColorBlock(ABlock + 8, False, APixels);
        for LTexel := 0 to 15 do
        begin
          LCode := (ABlock[LTexel shr 1] shr ((LTexel and 1) * 4)) and $F;
          APixels[LTexel * 4 + 3] := Byte(LCode * 17);
        end;
      end;
    TDdsFormat.Dxt5:
      begin
        DecodeColorBlock(ABlock + 8, False, APixels);
        LAlpha0 := ABlock[0];
        LAlpha1 := ABlock[1];
        LAlphas[0] := LAlpha0;
        LAlphas[1] := LAlpha1;
        if LAlpha0 > LAlpha1 then
          for LCode := 2 to 7 do
            LAlphas[LCode] := ((8 - LCode) * LAlpha0 + (LCode - 1) * LAlpha1) div 7
        else
        begin
          for LCode := 2 to 5 do
            LAlphas[LCode] := ((6 - LCode) * LAlpha0 + (LCode - 1) * LAlpha1) div 5;
          LAlphas[6] := 0;
          LAlphas[7] := 255;
        end;
        LBits := 0;
        for LTexel := 0 to 5 do
          LBits := LBits or (UInt64(ABlock[2 + LTexel]) shl (8 * LTexel));
        for LTexel := 0 to 15 do
          APixels[LTexel * 4 + 3] := Byte(LAlphas[(LBits shr (3 * LTexel)) and 7]);
      end;
  else
    raise EDdsException.CreateFmt(SDdsUnsupported, ['not a compressed format']);
  end;
end;

class function TDdsBlockDecoder.DecodeSurface(const AFormat: TDdsFormat; const ASource: TBytes;
  const AOffset, AWidth, AHeight: Integer): TImagingRgbaImage;
var
  LBlocksX, LBlocksY, LBlockX, LBlockY, LRow, LColumn: Integer;
  LBlock: PByte;
  LPixels: TDdsBlockPixels;
  LX, LY: Integer;
begin
  if (AOffset < 0) or (Length(ASource) - AOffset < SurfaceSize(AFormat, AWidth, AHeight)) then
    raise EDdsException.Create(SDdsTooShort);
  Result := TImagingRgbaImage.Create(AWidth, AHeight);
  LBlocksX := (AWidth + 3) div 4;
  LBlocksY := (AHeight + 3) div 4;
  LBlock := @ASource[AOffset];
  for LBlockY := 0 to LBlocksY - 1 do
    for LBlockX := 0 to LBlocksX - 1 do
    begin
      DecodeBlock(AFormat, LBlock, LPixels);
      Inc(LBlock, BlockSize(AFormat));
      for LRow := 0 to 3 do
      begin
        LY := LBlockY * 4 + LRow;
        if LY >= AHeight then
          Break;
        for LColumn := 0 to 3 do
        begin
          LX := LBlockX * 4 + LColumn;
          if LX >= AWidth then
            Break;
          Move(LPixels[(LRow * 4 + LColumn) * 4], Result.Pixels[(LY * AWidth + LX) * 4], 4);
        end;
      end;
    end;
end;

end.
