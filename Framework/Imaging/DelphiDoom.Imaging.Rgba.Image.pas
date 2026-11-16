{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - an image of 4 bytes per pixel (R, G, B, A)    }
{                                                                              }
{  The canonical in-memory form of an image of idTech 4 (the renderer calls    }
{  it "byte *pic": width * height * 4 bytes, rows from the top, red first).    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.Rgba.Image;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types;

const
  /// <summary>The biggest side of an RGBA image that the library creates</summary>
  IMAGING_RGBA_MAX_SIDE = 16384;

  SRgbaInvalidSize = 'The size of the RGBA image is not valid: %d x %d';

type
  /// <summary>
  ///   Width * Height pixels of 4 bytes in the order R, G, B, A (in memory, like the
  ///   byte arrays of idTech 4), rows from top to bottom, no padding
  /// </summary>
  TImagingRgbaImage = record
    Width: Integer;
    Height: Integer;
    Pixels: TBytes;
    /// <summary>A zeroed image; EImagingException when a side is not in 1..IMAGING_RGBA_MAX_SIDE</summary>
    class function Create(const AWidth, AHeight: Integer): TImagingRgbaImage; static;
    /// <summary>An image that takes the bytes as they are (the length must be Width * Height * 4)</summary>
    class function FromBytes(const AWidth, AHeight: Integer; const APixels: TBytes): TImagingRgbaImage; static;
    /// <summary>No pixels at all (a default record)</summary>
    function IsEmpty: Boolean;
    /// <summary>Same size and same bytes</summary>
    function SameAs(const AOther: TImagingRgbaImage): Boolean;
  end;

implementation

{ TImagingRgbaImage }

class function TImagingRgbaImage.Create(const AWidth, AHeight: Integer): TImagingRgbaImage;
begin
  if (AWidth < 1) or (AHeight < 1) or (AWidth > IMAGING_RGBA_MAX_SIDE)
    or (AHeight > IMAGING_RGBA_MAX_SIDE) then
    raise EImagingException.CreateFmt(SRgbaInvalidSize, [AWidth, AHeight]);
  Result.Width := AWidth;
  Result.Height := AHeight;
  SetLength(Result.Pixels, AWidth * AHeight * 4);
end;

class function TImagingRgbaImage.FromBytes(const AWidth, AHeight: Integer;
  const APixels: TBytes): TImagingRgbaImage;
begin
  Result := Create(AWidth, AHeight);
  if Length(APixels) <> Length(Result.Pixels) then
    raise EImagingException.CreateFmt(SRgbaInvalidSize, [AWidth, AHeight]);
  Move(APixels[0], Result.Pixels[0], Length(APixels));
end;

function TImagingRgbaImage.IsEmpty: Boolean;
begin
  Result := Length(Pixels) = 0;
end;

function TImagingRgbaImage.SameAs(const AOther: TImagingRgbaImage): Boolean;
begin
  Result := (Width = AOther.Width) and (Height = AOther.Height)
    and (Length(Pixels) = Length(AOther.Pixels))
    and ((Length(Pixels) = 0) or CompareMem(@Pixels[0], @AOther.Pixels[0], Length(Pixels)));
end;

end.
