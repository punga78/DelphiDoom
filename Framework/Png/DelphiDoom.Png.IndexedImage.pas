{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG library - a picture of 8 bit pixels that index a palette     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.IndexedImage;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The picture the old games draw: Height rows of Width pixels, one byte each, top row first. The byte is an
  ///   index into a palette that travels apart (each game has its own: EGA, VGA at 6 bit, per picture). It is the
  ///   common shape of the pictures of the games outside the engine of Doom when they are handed to a PNG file
  /// </summary>
  TIndexedImage = record
  public
    Width: Integer;
    Height: Integer;
    Pixels: TBytes;
    /// <summary>A picture of the given size with every pixel 0</summary>
    class function Create(AWidth, AHeight: Integer): TIndexedImage; static;
    /// <summary>A picture over pixels that already exist: the bytes are shared, not copied</summary>
    class function Wrap(AWidth, AHeight: Integer; const APixels: TBytes): TIndexedImage; static;
    /// <summary>True when the size is positive and the pixels are exactly Width * Height</summary>
    function IsValid: Boolean;
  end;

implementation

class function TIndexedImage.Create(AWidth, AHeight: Integer): TIndexedImage;
begin
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.Pixels := nil;
  if (AWidth > 0) and (AHeight > 0) then
  begin
    SetLength(Result.Pixels, AWidth * AHeight);
    // SetLength does not clear the bytes of an array that grows from a reused block
    FillChar(Result.Pixels[0], Length(Result.Pixels), 0);
  end;
end;

class function TIndexedImage.Wrap(AWidth, AHeight: Integer; const APixels: TBytes): TIndexedImage;
begin
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.Pixels := APixels;
end;

function TIndexedImage.IsValid: Boolean;
begin
  Result := (Width > 0) and (Height > 0) and (Int64(Length(Pixels)) = Int64(Width) * Height);
end;

end.
