{******************************************************************************}
{                                                                              }
{  DelphiDoom: texture library - LoadPCX32 of Doom 3                           }
{                                                                              }
{  Port of renderer\Image_files.cpp of the Doom 3 GPL Source Code (id          }
{  Software). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.}
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.IdImage.Pcx;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Rgba.Image;

type
  /// <summary>
  ///   Reads a PCX file as <c>LoadPCX32</c> of Doom 3: version 5, RLE, 8 bit pixels with the palette of 768 bytes
  ///   at the end of the file, to RGBA with alpha 255. Sides above 1024 are refused (the original prints
  ///   "Bad pcx file" and loads nothing). Quirks kept: <c>bytes_per_line</c> is not used (a row is
  ///   <c>xmax + 1</c> pixels) and a run can go past the end of a row (the extra pixels go into the next row, the
  ///   last ones are lost). Difference: a file that ends before the pixels are read is "malformed"
  ///   (the original reads past the buffer and says so afterwards)
  /// </summary>
  TIdPcxReader = class sealed
  public
    /// <summary>False (an empty image) when the file is not a valid PCX: nothing is raised, as in the original</summary>
    class function TryRead(const ASource: TBytes; out AImage: TImagingRgbaImage): Boolean; static;
  end;

implementation

const
  HEADER_SIZE = 128;
  PALETTE_SIZE = 768;

{ TIdPcxReader }

class function TIdPcxReader.TryRead(const ASource: TBytes; out AImage: TImagingRgbaImage): Boolean;
var
  LXMax, LYMax, LWidth, LHeight, LRaw, LX, LY, LDataByte, LRunLength, LPixel, LPalette: Integer;
  LIndexed: TBytes;
begin
  AImage := Default(TImagingRgbaImage);
  Result := False;
  if Length(ASource) < HEADER_SIZE then
    Exit;
  LXMax := SmallInt(Word(ASource[8]) or (Word(ASource[9]) shl 8));
  LYMax := SmallInt(Word(ASource[10]) or (Word(ASource[11]) shl 8));
  if (ASource[0] <> $0A) or (ASource[1] <> 5) or (ASource[2] <> 1) or (ASource[3] <> 8) or (LXMax >= 1024) or
    (LYMax >= 1024) or (LXMax < 0) or (LYMax < 0) then
    Exit;
  if Length(ASource) < HEADER_SIZE + PALETTE_SIZE then
    Exit;
  LWidth := LXMax + 1;
  LHeight := LYMax + 1;
  SetLength(LIndexed, LWidth * LHeight);
  LRaw := HEADER_SIZE;
  LPixel := 0;
  for LY := 0 to LYMax do
  begin
    LX := 0;
    while LX <= LXMax do
    begin
      if LRaw >= Length(ASource) then
        Exit;
      LDataByte := ASource[LRaw];
      Inc(LRaw);
      if (LDataByte and $C0) = $C0 then
      begin
        LRunLength := LDataByte and $3F;
        if LRaw >= Length(ASource) then
          Exit;
        LDataByte := ASource[LRaw];
        Inc(LRaw);
      end
      else
        LRunLength := 1;
      while LRunLength > 0 do
      begin
        // pix[x++] = dataByte: a run past the end of the row goes on in the next row (and out of the image)
        if LPixel + LX < Length(LIndexed) then
          LIndexed[LPixel + LX] := Byte(LDataByte);
        Inc(LX);
        Dec(LRunLength);
      end;
    end;
    Inc(LPixel, LWidth);
  end;
  // the original checks the position after reading; the file must also hold the palette after the pixels
  if LRaw > Length(ASource) then
    Exit;
  AImage := TImagingRgbaImage.Create(LWidth, LHeight);
  LPalette := Length(ASource) - PALETTE_SIZE;
  for LPixel := 0 to LWidth * LHeight - 1 do
  begin
    AImage.Pixels[LPixel * 4] := ASource[LPalette + LIndexed[LPixel] * 3];
    AImage.Pixels[LPixel * 4 + 1] := ASource[LPalette + LIndexed[LPixel] * 3 + 1];
    AImage.Pixels[LPixel * 4 + 2] := ASource[LPalette + LIndexed[LPixel] * 3 + 2];
    AImage.Pixels[LPixel * 4 + 3] := 255;
  end;
  Result := True;
end;

end.