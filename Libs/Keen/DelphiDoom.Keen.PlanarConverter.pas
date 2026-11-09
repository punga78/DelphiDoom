{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - from EGA planes to one byte for each pixel        }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  what VW_MemToScreen and VW_MaskBlock of id_vw_ae.asm put on the screen       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.PlanarConverter;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types;

type
  /// <summary>
  ///   The pictures, the tiles and the sprites are stored by planes: all the rows of the blue plane, then
  ///   the green, the red and the intensity plane (VW_MemToScreen writes each with the map mask 1, 2, 4,
  ///   8); a masked shape has first a plane of the mask. In a byte of a row the leftmost pixel is the
  ///   highest bit. The color of a pixel is the 4 bits of the 4 planes (blue is bit 0)
  /// </summary>
  TKeenPlanarConverter = class
  strict private
    class procedure CheckSize(AAvailable, AOffset, ANeeded: Integer); static;
    class function PixelAt(const APlanar: TBytes; AFirstPlane, APlaneSize, AIndex, AShift: Integer): Byte; static;
  public
    /// <summary>
    ///   A shape of 4 planes of AWidthBytes * AHeight bytes, from AOffset, as an image of
    ///   AWidthBytes * 8 pixels by AHeight with the colors 0..15
    /// </summary>
    class function ToChunky(const APlanar: TBytes; AOffset, AWidthBytes, AHeight: Integer): TKeenChunkyImage; static;
    /// <summary>
    ///   A masked shape: the mask plane and 4 planes. The image has the colors of the planes; AMask has $0F for
    ///   a pixel where the mask is 1 (the screen stays as it is: the screen becomes
    ///   (screen and mask) or color) and 0 where the shape is drawn
    /// </summary>
    class function ToChunkyMasked(const APlanar: TBytes; AOffset, AWidthBytes, AHeight: Integer;
      out AMask: TBytes): TKeenChunkyImage; static;
    /// <summary>A masked shape alone: the pixels that the mask leaves open are KEEN_PIXEL_TRANSPARENT</summary>
    class function ToChunkyTransparent(const APlanar: TBytes; AOffset, AWidthBytes,
      AHeight: Integer): TKeenChunkyImage; static;
  end;

implementation

{ TKeenPlanarConverter }

class procedure TKeenPlanarConverter.CheckSize(AAvailable, AOffset, ANeeded: Integer);
begin
  if (AOffset < 0) or (ANeeded < 0) or (Int64(AOffset) + ANeeded > AAvailable) then
    raise EKeenDataException.CreateFmt(SKeenPlanarTooShort, [ANeeded, AAvailable - AOffset]);
end;

class function TKeenPlanarConverter.PixelAt(const APlanar: TBytes; AFirstPlane, APlaneSize, AIndex,
  AShift: Integer): Byte;
var
  LPlane: Integer;
begin
  Result := 0;
  for LPlane := 0 to KEEN_EGA_PLANES - 1 do
    Result := Byte(Result or (((APlanar[AFirstPlane + LPlane * APlaneSize + AIndex] shr AShift) and 1) shl LPlane));
end;

class function TKeenPlanarConverter.ToChunky(const APlanar: TBytes; AOffset, AWidthBytes,
  AHeight: Integer): TKeenChunkyImage;
var
  LPlaneSize: Integer;
  LRow: Integer;
  LColumn: Integer;
  LBit: Integer;
begin
  if (AWidthBytes <= 0) or (AHeight <= 0) then
    raise EKeenException.CreateFmt(SKeenSizeInvalid, [AWidthBytes * 8, AHeight]);
  LPlaneSize := AWidthBytes * AHeight;
  CheckSize(Length(APlanar), AOffset, LPlaneSize * KEEN_EGA_PLANES);
  Result.Width := AWidthBytes * 8;
  Result.Height := AHeight;
  SetLength(Result.Pixels, Result.Width * Result.Height);
  for LRow := 0 to AHeight - 1 do
    for LColumn := 0 to AWidthBytes - 1 do
      for LBit := 0 to 7 do
        Result.Pixels[LRow * Result.Width + LColumn * 8 + LBit] :=
          PixelAt(APlanar, AOffset, LPlaneSize, LRow * AWidthBytes + LColumn, 7 - LBit);
end;

class function TKeenPlanarConverter.ToChunkyMasked(const APlanar: TBytes; AOffset, AWidthBytes,
  AHeight: Integer; out AMask: TBytes): TKeenChunkyImage;
var
  LPlaneSize: Integer;
  LRow: Integer;
  LColumn: Integer;
  LBit: Integer;
  LIndex: Integer;
begin
  if (AWidthBytes <= 0) or (AHeight <= 0) then
    raise EKeenException.CreateFmt(SKeenSizeInvalid, [AWidthBytes * 8, AHeight]);
  LPlaneSize := AWidthBytes * AHeight;
  CheckSize(Length(APlanar), AOffset, LPlaneSize * (KEEN_EGA_PLANES + 1));
  Result.Width := AWidthBytes * 8;
  Result.Height := AHeight;
  SetLength(Result.Pixels, Result.Width * Result.Height);
  SetLength(AMask, Result.Width * Result.Height);
  for LRow := 0 to AHeight - 1 do
    for LColumn := 0 to AWidthBytes - 1 do
      for LBit := 0 to 7 do
      begin
        LIndex := LRow * Result.Width + LColumn * 8 + LBit;
        Result.Pixels[LIndex] := PixelAt(APlanar, AOffset + LPlaneSize, LPlaneSize,
          LRow * AWidthBytes + LColumn, 7 - LBit);
        if ((APlanar[AOffset + LRow * AWidthBytes + LColumn] shr (7 - LBit)) and 1) <> 0 then
          AMask[LIndex] := $0F
        else
          AMask[LIndex] := 0;
      end;
end;

class function TKeenPlanarConverter.ToChunkyTransparent(const APlanar: TBytes; AOffset, AWidthBytes,
  AHeight: Integer): TKeenChunkyImage;
var
  LMask: TBytes;
  LIndex: Integer;
begin
  Result := ToChunkyMasked(APlanar, AOffset, AWidthBytes, AHeight, LMask);
  for LIndex := 0 to High(Result.Pixels) do
    if LMask[LIndex] <> 0 then
      Result.Pixels[LIndex] := KEEN_PIXEL_TRANSPARENT;
end;

end.
