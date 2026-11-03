{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - image header (IHDR chunk)                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.Header;

interface

{$POINTERMATH ON}

const
  // Size of the data of the IHDR chunk
  PNG_HEADER_SIZE = 13;

type
  /// <summary>
  ///   The content of an IHDR chunk, checked
  /// </summary>
  TPngHeader = record
    Width: Integer;
    Height: Integer;
    BitDepth: Integer;
    ColorType: Integer;
    Interlaced: Boolean;

    /// <summary>
    ///   Reads and checks the PNG_HEADER_SIZE bytes of an IHDR chunk. Raises
    ///   EPngException if the header is not valid or declares an image that
    ///   is larger than the library accepts
    /// </summary>
    procedure Parse(AData: PByte; ASize: Cardinal);

    /// <summary>
    ///   Number of samples of a pixel (1 for grayscale and palette, 2 for
    ///   grayscale with alpha, 3 for RGB, 4 for RGB with alpha)
    /// </summary>
    function ChannelCount: Integer;

    function BitsPerPixel: Integer;

    /// <summary>
    ///   Distance in bytes between a byte and the same byte of the previous
    ///   pixel, which the filters use: the size of a pixel, at least 1
    /// </summary>
    function FilterStride: Integer;

    /// <summary>
    ///   Bytes of a row of AWidth pixels, without the filter type byte
    /// </summary>
    function RowBytes(AWidth: Integer): Integer;
  end;

implementation

uses
  DelphiDoom.Png.Intf, DelphiDoom.Png.ByteOrder;

{ TPngHeader }

procedure TPngHeader.Parse(AData: PByte; ASize: Cardinal);
var
  LWidth: Cardinal;
  LHeight: Cardinal;
  LCombinationValid: Boolean;
begin
  if ASize <> PNG_HEADER_SIZE then
    raise EPngException.CreateCode(DDPNG_ERR_DATA);

  LWidth := TPngByteOrder.ReadCardinal(AData);
  LHeight := TPngByteOrder.ReadCardinal(AData + 4);
  BitDepth := AData[8];
  ColorType := AData[9];

  // Zero and sizes above 2^31 - 1 are invalid, large sizes are only refused
  if (LWidth = 0) or (LHeight = 0) or (LWidth > $7FFFFFFF) or
     (LHeight > $7FFFFFFF) then
    raise EPngException.CreateCode(DDPNG_ERR_DATA);

  // Methods of compression and filtering: only 0 exists. Interlace: 0 or 1
  if (AData[10] <> 0) or (AData[11] <> 0) or (AData[12] > 1) then
    raise EPngException.CreateCode(DDPNG_ERR_DATA);
  Interlaced := AData[12] = 1;

  case ColorType of
    DDPNG_COLOR_GRAY:
      LCombinationValid := BitDepth in [1, 2, 4, 8, 16];
    DDPNG_COLOR_PALETTE:
      LCombinationValid := BitDepth in [1, 2, 4, 8];
    DDPNG_COLOR_RGB, DDPNG_COLOR_GRAY_ALPHA, DDPNG_COLOR_RGBA:
      LCombinationValid := BitDepth in [8, 16];
  else
    LCombinationValid := False;
  end;
  if not LCombinationValid then
    raise EPngException.CreateCode(DDPNG_ERR_DATA);

  if (LWidth > DDPNG_MAX_DIMENSION) or (LHeight > DDPNG_MAX_DIMENSION) or
     (Int64(LWidth) * Int64(LHeight) > DDPNG_MAX_PIXELS) then
    raise EPngException.CreateCode(DDPNG_ERR_TOO_LARGE);

  Width := Integer(LWidth);
  Height := Integer(LHeight);
end;

function TPngHeader.ChannelCount: Integer;
begin
  case ColorType of
    DDPNG_COLOR_RGB:        Result := 3;
    DDPNG_COLOR_GRAY_ALPHA: Result := 2;
    DDPNG_COLOR_RGBA:       Result := 4;
  else
    Result := 1;
  end;
end;

function TPngHeader.BitsPerPixel: Integer;
begin
  Result := ChannelCount * BitDepth;
end;

function TPngHeader.FilterStride: Integer;
begin
  Result := (BitsPerPixel + 7) div 8;
end;

function TPngHeader.RowBytes(AWidth: Integer): Integer;
begin
  Result := (AWidth * BitsPerPixel + 7) div 8;
end;

end.
