{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - TTgaIdReader, the TGA loader of idTech 4      }
{                                                                              }
{  Port of LoadTGA of renderer\Image_files.cpp (id Software, Doom 3, GPL v3).  }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Tga.IdReader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Imaging.Rgba.Image;

const
  STgaType = 'TGA: only type 2 (RGB), 3 (gray) and 10 (RLE RGB) images are supported';
  STgaColorMap = 'TGA: colour maps are not supported';
  STgaDepth = 'TGA: only 32 or 24 bit images are supported (8 bit only for type 3)';
  STgaIncomplete = 'TGA: incomplete file';
  STgaSize = 'TGA: the size of the image is not valid';

type
  /// <summary>
  ///   Reads a TGA file as Doom 3 does, to RGBA: types 2 and 3 (uncompressed: colour at 24 and
  ///   32 bit, gray at 8 bit) and 10 (RLE, 24 and 32 bit), no colour maps. The rows of the file
  ///   go from the bottom to the top and the bit 5 of the descriptor (origin at the top) flips
  ///   the result. The errors that the C++ reports with common->Error are ETextureException
  /// </summary>
  /// <remarks>
  ///   Quirks of the C++ that are kept: a type 3 image is accepted with any pixel size that
  ///   passes the size test (8, 24 and 32 work, 16 is refused as "illegal pixel_size"); a run of
  ///   pixels can span rows; the image is flipped after reading. Differences: what the C++
  ///   would read past the end of a damaged file (RLE has no size test) is an error here, and a
  ///   size of 0 or above TEXTURE_MAX_DIMENSION is an error (the C++ makes an empty image or
  ///   asks for gigabytes)
  /// </remarks>
  TTgaIdReader = class sealed
  public
    class function Read(const ASource: TBytes): TImagingRgbaImage; static;
  end;

implementation

uses
  DelphiDoom.Imaging.Rgba.Sampler;

type
  TByteCursor = record
    Data: TBytes;
    Position: Integer;
    function Next: Byte;
  end;

function TByteCursor.Next: Byte;
begin
  if Position >= Length(Data) then
    raise ETextureException.Create(STgaIncomplete);
  Result := Data[Position];
  Inc(Position);
end;

{ TTgaIdReader }

class function TTgaIdReader.Read(const ASource: TBytes): TImagingRgbaImage;
var
  LCursor: TByteCursor;
  LIdLength, LColorMapType, LImageType, LPixelSize, LAttributes: Byte;
  LWidth, LHeight, LRow, LColumn, LNumBytes, LJ, LPacketSize: Integer;
  LPacketHeader: Byte;
  LRed, LGreen, LBlue, LAlpha: Byte;
  LOut: Integer;

  function ReadSmall(const AOffset: Integer): Integer;
  begin
    // unsigned short in the C++
    Result := ASource[AOffset] or (ASource[AOffset + 1] shl 8);
  end;

  procedure ReadPixel(const AWithAlpha: Boolean; const AGray: Boolean);
  begin
    if AGray then
    begin
      LBlue := LCursor.Next;
      LGreen := LBlue;
      LRed := LBlue;
      LAlpha := 255;
    end
    else
    begin
      LBlue := LCursor.Next;
      LGreen := LCursor.Next;
      LRed := LCursor.Next;
      if AWithAlpha then
        LAlpha := LCursor.Next
      else
        LAlpha := 255;
    end;
  end;

  procedure Put;
  begin
    Result.Pixels[LOut] := LRed;
    Result.Pixels[LOut + 1] := LGreen;
    Result.Pixels[LOut + 2] := LBlue;
    Result.Pixels[LOut + 3] := LAlpha;
    Inc(LOut, 4);
  end;

  // moves to the row below in the file (up in the image) after a full row
  function NextRow(var ARowIndex: Integer): Boolean;
  begin
    LColumn := 0;
    if ARowIndex > 0 then
    begin
      Dec(ARowIndex);
      LOut := ARowIndex * LWidth * 4;
      Result := True;
    end
    else
      Result := False;
  end;

begin
  if Length(ASource) < 18 then
    raise ETextureException.Create(STgaIncomplete);
  LIdLength := ASource[0];
  LColorMapType := ASource[1];
  LImageType := ASource[2];
  LWidth := ReadSmall(12);
  LHeight := ReadSmall(14);
  LPixelSize := ASource[16];
  LAttributes := ASource[17];

  if not (LImageType in [2, 3, 10]) then
    raise ETextureException.Create(STgaType);
  if LColorMapType <> 0 then
    raise ETextureException.Create(STgaColorMap);
  if not (LPixelSize in [24, 32]) and (LImageType <> 3) then
    raise ETextureException.Create(STgaDepth);
  if (LWidth < 1) or (LHeight < 1) or (LWidth > TEXTURE_MAX_DIMENSION)
    or (LHeight > TEXTURE_MAX_DIMENSION) then
    raise ETextureException.Create(STgaSize);
  if LImageType in [2, 3] then
  begin
    LNumBytes := LWidth * LHeight * (LPixelSize shr 3);
    if LNumBytes > Length(ASource) - 18 - LIdLength then
      raise ETextureException.Create(STgaIncomplete);
  end;

  Result := TImagingRgbaImage.Create(LWidth, LHeight);
  LCursor.Data := ASource;
  LCursor.Position := 18 + LIdLength;

  if LImageType in [2, 3] then
  begin
    // uncompressed: the last row of the image comes first in the file
    for LRow := LHeight - 1 downto 0 do
    begin
      LOut := LRow * LWidth * 4;
      for LColumn := 0 to LWidth - 1 do
      begin
        case LPixelSize of
          8:
            ReadPixel(False, True);
          24:
            ReadPixel(False, False);
          32:
            ReadPixel(True, False);
        else
          raise ETextureException.Create(STgaDepth);
        end;
        Put;
      end;
    end;
  end
  else
  begin
    LRed := 0;
    LGreen := 0;
    LBlue := 0;
    LAlpha := 255;
    LRow := LHeight - 1;
    LOut := LRow * LWidth * 4;
    LColumn := 0;
    while (LRow >= 0) and (LColumn < LWidth) do
    begin
      LPacketHeader := LCursor.Next;
      LPacketSize := 1 + (LPacketHeader and $7F);
      if (LPacketHeader and $80) <> 0 then
      begin
        ReadPixel(LPixelSize = 32, False);
        for LJ := 0 to LPacketSize - 1 do
        begin
          Put;
          Inc(LColumn);
          if LColumn = LWidth then
          begin
            // a run can span rows
            if not NextRow(LRow) then
            begin
              LRow := -1;
              Break;
            end;
          end;
        end;
      end
      else
        for LJ := 0 to LPacketSize - 1 do
        begin
          ReadPixel(LPixelSize = 32, False);
          Put;
          Inc(LColumn);
          if LColumn = LWidth then
          begin
            if not NextRow(LRow) then
            begin
              LRow := -1;
              Break;
            end;
          end;
        end;
      if LRow < 0 then
        Break;
    end;
  end;

  if (LAttributes and (1 shl 5)) <> 0 then
    TImagingRgbaSampler.VerticalFlip(Result);
end;

end.
