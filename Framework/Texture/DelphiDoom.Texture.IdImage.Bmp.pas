{******************************************************************************}
{                                                                              }
{  DelphiDoom: texture library - LoadBMP of Doom 3                             }
{                                                                              }
{  Port of renderer\Image_files.cpp of the Doom 3 GPL Source Code (id          }
{  Software). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.}
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Framework\IdLib); the repository as a whole is GPL v2 or later.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.IdImage.Bmp;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Rgba.Image;

const
  SBmpTooShort = 'LoadBMP: the file is too short (%s)';
  SBmpId = 'LoadBMP: only Windows-style BMP files supported (%s)';
  SBmpFileSize = 'LoadBMP: header size does not match file size (%d vs. %d) (%s)';
  SBmpCompression = 'LoadBMP: only uncompressed BMP files supported (%s)';
  SBmpBits = 'LoadBMP: monochrome and 4-bit BMP files not supported (%s)';
  SBmp16 = 'LoadBMP: 16 bit BMP files are not supported (%s)';
  SBmpPixelSize = 'LoadBMP: illegal pixel_size ''%d'' in file ''%s''';

type
  /// <summary>
  ///   Reads a BMP file as <c>LoadBMP</c> of Doom 3: uncompressed, 8 bit with a palette, 24 and 32 bit, to RGBA.
  ///   The errors the original reports with common->Error are <c>ETextureException</c>.
  /// </summary>
  /// <remarks>
  ///   Quirks kept: the rows are not padded to four bytes (a file whose width is not a multiple of four, with
  ///   the padding BMP requires, shifts every row), the data starts right after the header (and the palette of an
  ///   8 bit file), the header size is not used, the check of the signature is <c>id[0] != 'B' &amp;&amp; id[1] != 'M'</c>
  ///   (it only fails when neither is right), the rows are put bottom to top whatever the sign of the height, the
  ///   alpha of 8 and 24 bit files is 255. Differences: a file with fewer bytes than the header or the pixels needs
  ///   is an error (the original reads past the buffer); 16 bit files are refused (the original reads its own
  ///   output buffer and writes past it); with <c>AHonorRowPadding</c> the rows are padded to four bytes, which a
  ///   BMP written by a converter has (the JPEG of the engine goes through such a file).
  /// </remarks>
  TIdBmpReader = class sealed
  public
    class function Read(const ASource: TBytes; const AName: string;
      const AHonorRowPadding: Boolean = False): TImagingRgbaImage; static;
  end;

implementation

uses
  DelphiDoom.Texture.Types;

function Int32At(const ASource: TBytes; const AOffset: Integer): Integer; inline;
begin
  Result := Integer(Cardinal(ASource[AOffset]) or (Cardinal(ASource[AOffset + 1]) shl 8) or
    (Cardinal(ASource[AOffset + 2]) shl 16) or (Cardinal(ASource[AOffset + 3]) shl 24));
end;

function Int16At(const ASource: TBytes; const AOffset: Integer): Integer; inline;
begin
  Result := Integer(Word(ASource[AOffset]) or (Word(ASource[AOffset + 1]) shl 8));
end;

{ TIdBmpReader }

class function TIdBmpReader.Read(const ASource: TBytes; const AName: string;
  const AHonorRowPadding: Boolean): TImagingRgbaImage;
const
  HEADER_SIZE = 54;
var
  LFileSize, LColumns, LRows, LBits, LCompression, LPosition, LRow, LColumn, LPixel, LPalette, LRowBytes: Integer;
  LPaletteStart, LRowStart: Integer;
  LNeeded: Int64;
begin
  if Length(ASource) < HEADER_SIZE then
    raise ETextureException.CreateFmt(SBmpTooShort, [AName]);
  LFileSize := Int32At(ASource, 2);
  LColumns := Int32At(ASource, 18);
  LRows := Int32At(ASource, 22);
  LBits := Int16At(ASource, 28);
  LCompression := Int32At(ASource, 30);
  // bmpHeader.id[0] != 'B' && bmpHeader.id[1] != 'M'
  if (ASource[0] <> Ord('B')) and (ASource[1] <> Ord('M')) then
    raise ETextureException.CreateFmt(SBmpId, [AName]);
  if LFileSize <> Length(ASource) then
    raise ETextureException.CreateFmt(SBmpFileSize, [LFileSize, Length(ASource), AName]);
  if LCompression <> 0 then
    raise ETextureException.CreateFmt(SBmpCompression, [AName]);
  if LBits < 8 then
    raise ETextureException.CreateFmt(SBmpBits, [AName]);
  if LBits = 16 then
    raise ETextureException.CreateFmt(SBmp16, [AName]);
  if (LBits <> 8) and (LBits <> 24) and (LBits <> 32) then
    raise ETextureException.CreateFmt(SBmpPixelSize, [LBits, AName]);
  if LRows < 0 then
    LRows := -LRows;
  LPosition := HEADER_SIZE;
  LPaletteStart := HEADER_SIZE;
  if LBits = 8 then
    Inc(LPosition, 1024);
  if (LColumns < 1) or (LRows < 1) then
    raise ETextureException.CreateFmt(SBmpTooShort, [AName]);
  LRowBytes := LColumns * (LBits div 8);
  if AHonorRowPadding then
    LRowBytes := (LRowBytes + 3) and not 3;
  LNeeded := Int64(LPosition) + Int64(LRowBytes) * LRows;
  if LNeeded > Length(ASource) then
    raise ETextureException.CreateFmt(SBmpTooShort, [AName]);
  Result := TImagingRgbaImage.Create(LColumns, LRows);
  for LRow := LRows - 1 downto 0 do
  begin
    LPixel := LRow * LColumns * 4;
    LRowStart := LPosition;
    for LColumn := 0 to LColumns - 1 do
    begin
      case LBits of
        8:
          begin
            LPalette := LPaletteStart + ASource[LPosition] * 4;
            Inc(LPosition);
            Result.Pixels[LPixel] := ASource[LPalette + 2];
            Result.Pixels[LPixel + 1] := ASource[LPalette + 1];
            Result.Pixels[LPixel + 2] := ASource[LPalette];
            Result.Pixels[LPixel + 3] := 255;
          end;
        24:
          begin
            Result.Pixels[LPixel + 2] := ASource[LPosition];
            Result.Pixels[LPixel + 1] := ASource[LPosition + 1];
            Result.Pixels[LPixel] := ASource[LPosition + 2];
            Result.Pixels[LPixel + 3] := 255;
            Inc(LPosition, 3);
          end;
      else
        begin
          Result.Pixels[LPixel + 2] := ASource[LPosition];
          Result.Pixels[LPixel + 1] := ASource[LPosition + 1];
          Result.Pixels[LPixel] := ASource[LPosition + 2];
          Result.Pixels[LPixel + 3] := ASource[LPosition + 3];
          Inc(LPosition, 4);
        end;
      end;
      Inc(LPixel, 4);
    end;
    if AHonorRowPadding then
      LPosition := LRowStart + LRowBytes;
  end;
end;

end.