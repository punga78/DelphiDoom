{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - an image of 8 bits per pixel              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.Image;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette;

type
  /// <summary>
  ///   A picture where every pixel is an index of a palette (the indexed Surface of OpenXcom without SDL).
  ///   Pixels are in rows from the top, Width bytes each; the palette is optional (HasPalette)
  /// </summary>
  TXcomImage = record
  public
    Width: Integer;
    Height: Integer;
    Pixels: TBytes;
    HasPalette: Boolean;
    Palette: TXcomPalette;
    /// <summary>An image of AWidth x AHeight pixels of index 0 (a new Surface is all zero), without palette</summary>
    class function Create(AWidth, AHeight: Integer): TXcomImage; static;
    /// <summary>The pixel; 0 for a position outside the image (Surface::getPixel)</summary>
    function GetPixel(AX, AY: Integer): Byte;
    /// <summary>Changes a pixel; a position outside the image is ignored (Surface::setPixel)</summary>
    procedure SetPixel(AX, AY: Integer; AValue: Byte);
    /// <summary>
    ///   Changes the pixel and goes to the next one, row after row (Surface::setPixelIterative): when AX gets
    ///   to the width it goes back to 0 and AY grows. Positions below the last row are ignored
    /// </summary>
    procedure SetPixelIterative(var AX, AY: Integer; AValue: Byte);
  end;

implementation

{ TXcomImage }

class function TXcomImage.Create(AWidth, AHeight: Integer): TXcomImage;
begin
  if (AWidth <= 0) or (AHeight <= 0) or (Int64(AWidth) * AHeight > MaxInt) then
    raise EXcomException.CreateFmt(SXcomSizeInvalid, [AWidth, AHeight]);
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.HasPalette := False;
  SetLength(Result.Pixels, AWidth * AHeight);
  // SetLength does not clear the bytes of a new array
  FillChar(Result.Pixels[0], Length(Result.Pixels), 0);
  FillChar(Result.Palette, SizeOf(Result.Palette), 0);
end;

function TXcomImage.GetPixel(AX, AY: Integer): Byte;
begin
  if (AX < 0) or (AX >= Width) or (AY < 0) or (AY >= Height) then
    Exit(0);
  Result := Pixels[AY * Width + AX];
end;

procedure TXcomImage.SetPixel(AX, AY: Integer; AValue: Byte);
begin
  if (AX < 0) or (AX >= Width) or (AY < 0) or (AY >= Height) then
    Exit;
  Pixels[AY * Width + AX] := AValue;
end;

procedure TXcomImage.SetPixelIterative(var AX, AY: Integer; AValue: Byte);
begin
  SetPixel(AX, AY, AValue);
  Inc(AX);
  if AX = Width then
  begin
    Inc(AY);
    AX := 0;
  end;
end;

end.
