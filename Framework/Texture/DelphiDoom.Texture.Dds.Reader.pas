{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - TDdsReader, reads a DDS file into RGBA levels }
{                                                                              }
{  Written from the header of renderer\Image.h (id Software, Doom 3, GPL v3:   }
{  the records and flags, see DelphiDoom.Texture.Dds.Types) and from the       }
{  public description of the DDS format. Doom 3 only writes DDS files, so      }
{  the reading is new code; licensed under the GNU General Public License,     }
{  version 2 or later (the types unit carries the Doom 3 notice).              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Dds.Reader;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Texture.Dds.Types,
  DelphiDoom.Imaging.Rgba.Image;

type
  /// <summary>
  ///   Reads the DDS files that Doom 3 writes (DXT1, DXT3, DXT5, BGRA and RGB with masks, 8 bit
  ///   luminance or alpha) and the common ones of other tools, with all their mip levels.
  ///   Not read, with EDdsException: cube maps and volumes, the DX10 header, DXT2 and DXT4
  ///   (premultiplied alpha), palettised files (the file has no palette), other FourCC codes
  /// </summary>
  /// <remarks>
  ///   The levels of an uncompressed file are read without padding at the end of the row (as
  ///   Doom 3 writes them), whatever the pitch of the header says
  /// </remarks>
  TDdsReader = class sealed
  strict private
    class function Shift(const AMask: Cardinal): Integer; static;
    class function Channel(const APixel, AMask: Cardinal; const ADefault: Byte): Byte; static;
    class function DecodeUncompressed(const AFormat: TDdsPixelFormat; const ASource: TBytes;
      const AOffset, AWidth, AHeight: Integer; const ALevel: Integer): TImagingRgbaImage; static;
  public
    /// <summary>The number of levels of a full chain for a size: 1 for 1x1, 3 for 4x4 ...</summary>
    class function LevelCount(const AWidth, AHeight: Integer): Integer; static;
    /// <summary>Reads a whole file; EDdsException when it is damaged or not supported</summary>
    class function Read(const ASource: TBytes): TDdsImage; static;
  end;

implementation

uses
  System.Math, DelphiDoom.Texture.Dds.BlockDecoder;

{ TDdsReader }

class function TDdsReader.LevelCount(const AWidth, AHeight: Integer): Integer;
var
  LWidth, LHeight: Integer;
begin
  Result := 1;
  LWidth := AWidth;
  LHeight := AHeight;
  while (LWidth > 1) or (LHeight > 1) do
  begin
    Inc(Result);
    LWidth := LWidth shr 1;
    LHeight := LHeight shr 1;
  end;
end;

class function TDdsReader.Shift(const AMask: Cardinal): Integer;
begin
  Result := 0;
  while (Result < 32) and (((AMask shr Result) and 1) = 0) do
    Inc(Result);
end;

class function TDdsReader.Channel(const APixel, AMask: Cardinal; const ADefault: Byte): Byte;
var
  LShift, LMax: Cardinal;
begin
  if AMask = 0 then
    Exit(ADefault);
  LShift := Shift(AMask);
  LMax := AMask shr LShift;
  Result := Byte(((APixel and AMask) shr LShift) * 255 div LMax);
end;

class function TDdsReader.DecodeUncompressed(const AFormat: TDdsPixelFormat; const ASource: TBytes;
  const AOffset, AWidth, AHeight: Integer; const ALevel: Integer): TImagingRgbaImage;
var
  LBytes, LCount, LIndex, LByte: Integer;
  LPixel: Cardinal;
  LOut: Integer;
  LAlphaOnly, LLuminance: Boolean;
begin
  LBytes := Integer(AFormat.RGBBitCount) shr 3;
  LCount := AWidth * AHeight;
  if Int64(LCount) * LBytes > Length(ASource) - AOffset then
    raise EDdsException.CreateFmt(SDdsTruncated, [ALevel]);
  Result := TImagingRgbaImage.Create(AWidth, AHeight);
  LAlphaOnly := ((AFormat.Flags and DDSF_RGB) = 0) and ((AFormat.Flags and DDSF_ALPHAPIXELS) <> 0);
  // the 8 bit luminance of Doom 3 has the masks of a 32 bit image (00FF0000, 0000FF00,
  // 000000FF): the red one is outside of the byte, which no real 8 bit format has
  LLuminance := (LBytes = 1) and (not LAlphaOnly) and ((AFormat.RBitMask and $FF) = 0);
  LOut := 0;
  for LIndex := 0 to LCount - 1 do
  begin
    LPixel := 0;
    for LByte := 0 to LBytes - 1 do
      LPixel := LPixel or (Cardinal(ASource[AOffset + LIndex * LBytes + LByte]) shl (8 * LByte));
    if LAlphaOnly then
    begin
      Result.Pixels[LOut + 3] := Byte(LPixel and $FF);
      if LBytes > 1 then
        Result.Pixels[LOut + 3] := Channel(LPixel, AFormat.ABitMask, 255);
    end
    else if LLuminance then
    begin
      Result.Pixels[LOut] := Byte(LPixel);
      Result.Pixels[LOut + 1] := Byte(LPixel);
      Result.Pixels[LOut + 2] := Byte(LPixel);
      Result.Pixels[LOut + 3] := 255;
    end
    else
    begin
      Result.Pixels[LOut] := Channel(LPixel, AFormat.RBitMask, 0);
      Result.Pixels[LOut + 1] := Channel(LPixel, AFormat.GBitMask, 0);
      Result.Pixels[LOut + 2] := Channel(LPixel, AFormat.BBitMask, 0);
      Result.Pixels[LOut + 3] := Channel(LPixel, AFormat.ABitMask, 255);
    end;
    Inc(LOut, 4);
  end;
end;

class function TDdsReader.Read(const ASource: TBytes): TDdsImage;
var
  LHeader: TDdsHeader;
  LMagic: Cardinal;
  LOffset, LWidth, LHeight, LLevel, LLevels, LSize: Integer;
  LFormat: TDdsPixelFormat;
  LLevelImage: TImagingRgbaImage;
  LIndex: Integer;
begin
  if Length(ASource) < DDS_FILE_PREFIX_SIZE then
    raise EDdsException.Create(SDdsTooShort);
  Move(ASource[0], LMagic, 4);
  if LMagic <> DDS_MAGIC then
    raise EDdsException.Create(SDdsBadMagic);
  Move(ASource[4], LHeader, SizeOf(LHeader));
  if (LHeader.Size <> DDS_HEADER_SIZE) or (LHeader.PixelFormat.Size <> DDS_PIXEL_FORMAT_SIZE) then
    raise EDdsException.Create(SDdsBadHeader);
  if ((LHeader.Flags and DDSF_DEPTH) <> 0) or ((LHeader.Caps2 and $FE00) <> 0) or ((LHeader.Caps2 and $200000) <> 0) then
    raise EDdsException.CreateFmt(SDdsUnsupported, ['cube map or volume']);
  if (LHeader.Width < 1) or (LHeader.Height < 1) or (LHeader.Width > TEXTURE_MAX_DIMENSION)
    or (LHeader.Height > TEXTURE_MAX_DIMENSION) then
    raise EDdsException.CreateFmt(SDdsBadSize, [Integer(LHeader.Width), Integer(LHeader.Height)]);
  LWidth := LHeader.Width;
  LHeight := LHeader.Height;
  LFormat := LHeader.PixelFormat;

  Result := Default(TDdsImage);
  Result.IsMonochrome := (LHeader.Flags and DDSF_ID_MONOCHROME) <> 0;
  if (LFormat.Flags and DDSF_FOURCC) <> 0 then
  begin
    case LFormat.FourCC of
      DDS_FOURCC_DXT1:
        Result.Format := TDdsFormat.Dxt1;
      DDS_FOURCC_DXT3:
        Result.Format := TDdsFormat.Dxt3;
      DDS_FOURCC_DXT5:
        Result.Format := TDdsFormat.Dxt5;
    else
      raise EDdsException.CreateFmt(SDdsUnsupported, ['FourCC ' + IntToHex(LFormat.FourCC, 8)]);
    end;
    Result.HasAlpha := (Result.Format <> TDdsFormat.Dxt1) or ((LFormat.Flags and DDSF_ALPHAPIXELS) <> 0);
  end
  else
  begin
    if (LFormat.Flags and DDSF_ID_INDEXCOLOR) <> 0 then
      raise EDdsException.CreateFmt(SDdsUnsupported, ['palettised image']);
    if not (LFormat.RGBBitCount in [8, 16, 24, 32]) then
      raise EDdsException.CreateFmt(SDdsUnsupported, [Format('%d bits per pixel', [LFormat.RGBBitCount])]);
    if (LFormat.Flags and (DDSF_RGB or DDSF_ALPHAPIXELS)) = 0 then
      raise EDdsException.CreateFmt(SDdsUnsupported, ['pixel format flags ' + IntToHex(LFormat.Flags, 8)]);
    Result.Format := TDdsFormat.Uncompressed;
    Result.HasAlpha := (LFormat.Flags and DDSF_ALPHAPIXELS) <> 0;
  end;

  LLevels := 1;
  if (LHeader.Flags and DDSF_MIPMAPCOUNT) <> 0 then
    LLevels := Max(1, Min(Integer(LHeader.MipMapCount), LevelCount(LWidth, LHeight)));
  SetLength(Result.Levels, LLevels);
  LOffset := DDS_FILE_PREFIX_SIZE;
  for LLevel := 0 to LLevels - 1 do
  begin
    if Result.Format = TDdsFormat.Uncompressed then
    begin
      LLevelImage := DecodeUncompressed(LFormat, ASource, LOffset, LWidth, LHeight, LLevel);
      LSize := LWidth * LHeight * (Integer(LFormat.RGBBitCount) shr 3);
    end
    else
    begin
      LSize := ((LWidth + 3) div 4) * ((LHeight + 3) div 4);
      if Result.Format = TDdsFormat.Dxt1 then
        LSize := LSize * 8
      else
        LSize := LSize * 16;
      if Length(ASource) - LOffset < LSize then
        raise EDdsException.CreateFmt(SDdsTruncated, [LLevel]);
      LLevelImage := TDdsBlockDecoder.DecodeSurface(Result.Format, ASource, LOffset, LWidth, LHeight);
      if not Result.HasAlpha then
        for LIndex := 0 to LWidth * LHeight - 1 do
          LLevelImage.Pixels[LIndex * 4 + 3] := 255;
    end;
    Result.Levels[LLevel] := LLevelImage;
    Inc(LOffset, LSize);
    LWidth := Max(1, LWidth shr 1);
    LHeight := Max(1, LHeight shr 1);
  end;
end;

end.
