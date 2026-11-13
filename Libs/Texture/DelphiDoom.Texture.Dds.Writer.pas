{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - TDdsWriter, writes an uncompressed DDS file   }
{                                                                              }
{  Port of the header and the level loop of idImage::WritePrecompressedImage   }
{  (renderer\Image_load.cpp, id Software, Doom 3, GPL v3) for the BGRA case,   }
{  and of idImage::ImageProgramStringToCompressedFileName and NumLevels...     }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Dds.Writer;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Dds.Types, DelphiDoom.Imaging.Rgba.Image;

type
  /// <summary>
  ///   Writes the levels of an RGBA image as a 32 bit BGRA DDS file the way Doom 3 does for an
  ///   uncompressed texture (it needs BGRA "because DDS is a windows based format"): flags
  ///   CAPS, PIXELFORMAT, WIDTH, HEIGHT, PITCH and, with more than one level, MIPMAPCOUNT, caps
  ///   TEXTURE and MIPMAP | COMPLEX; masks 00FF0000, 0000FF00, 000000FF and FF000000
  /// </summary>
  TDdsWriter = class sealed
  public
    /// <summary>
    ///   ALevels[0] is the full image and each next one half the size, never below 1 (what
    ///   TImagingRgbaSampler.MipMap gives); at most DDS_MAX_LEVELS of them. EDdsException when the
    ///   chain is not like that. AMonochrome sets the DDSF_ID_MONOCHROME flag
    /// </summary>
    class function WriteUncompressed(const ALevels: TArray<TImagingRgbaImage>;
      const AMonochrome: Boolean = False): TBytes; static;
    /// <summary>
    ///   idImage::ImageProgramStringToCompressedFileName: "dds/" and the program with / \ ( as
    ///   directory separators (the first four, then spaces), < > : | " . as underscores, a space
    ///   after a slash and the characters ) and , dropped, then ".dds"
    /// </summary>
    class function CompressedFileName(const AImageProgram: string): string; static;
  end;

implementation

{ TDdsWriter }

class function TDdsWriter.WriteUncompressed(const ALevels: TArray<TImagingRgbaImage>;
  const AMonochrome: Boolean): TBytes;
var
  LHeader: TDdsHeader;
  LMagic: Cardinal;
  LWidth, LHeight, LLevel, LIndex, LTotal, LOffset: Integer;
begin
  if (Length(ALevels) < 1) or (Length(ALevels) > DDS_MAX_LEVELS) then
    raise EDdsException.Create(SDdsBadLevels);
  LWidth := ALevels[0].Width;
  LHeight := ALevels[0].Height;
  LTotal := DDS_FILE_PREFIX_SIZE;
  for LLevel := 0 to High(ALevels) do
  begin
    if (ALevels[LLevel].Width <> LWidth) or (ALevels[LLevel].Height <> LHeight)
      or (Length(ALevels[LLevel].Pixels) <> LWidth * LHeight * 4) then
      raise EDdsException.Create(SDdsBadLevels);
    Inc(LTotal, LWidth * LHeight * 4);
    if LWidth > 1 then
      LWidth := LWidth shr 1;
    if LHeight > 1 then
      LHeight := LHeight shr 1;
  end;

  LHeader := Default(TDdsHeader);
  LHeader.Size := SizeOf(LHeader);
  LHeader.Flags := DDSF_CAPS or DDSF_PIXELFORMAT or DDSF_WIDTH or DDSF_HEIGHT;
  LHeader.Height := ALevels[0].Height;
  LHeader.Width := ALevels[0].Width;
  if AMonochrome then
    LHeader.Flags := LHeader.Flags or DDSF_ID_MONOCHROME;
  LHeader.Flags := LHeader.Flags or DDSF_PITCH;
  LHeader.PitchOrLinearSize := Cardinal(((ALevels[0].Width * 32 + 31) and -32) shr 3);
  LHeader.Caps1 := DDSF_TEXTURE;
  if Length(ALevels) > 1 then
  begin
    LHeader.MipMapCount := Length(ALevels);
    LHeader.Flags := LHeader.Flags or DDSF_MIPMAPCOUNT;
    LHeader.Caps1 := LHeader.Caps1 or DDSF_MIPMAP or DDSF_COMPLEX;
  end;
  LHeader.PixelFormat.Size := SizeOf(LHeader.PixelFormat);
  LHeader.PixelFormat.Flags := DDSF_RGB or DDSF_ALPHAPIXELS;
  LHeader.PixelFormat.RGBBitCount := 32;
  LHeader.PixelFormat.ABitMask := $FF000000;
  LHeader.PixelFormat.RBitMask := $00FF0000;
  LHeader.PixelFormat.GBitMask := $0000FF00;
  LHeader.PixelFormat.BBitMask := $000000FF;

  SetLength(Result, LTotal);
  LMagic := DDS_MAGIC;
  Move(LMagic, Result[0], 4);
  Move(LHeader, Result[4], SizeOf(LHeader));
  LOffset := DDS_FILE_PREFIX_SIZE;
  for LLevel := 0 to High(ALevels) do
    for LIndex := 0 to ALevels[LLevel].Width * ALevels[LLevel].Height - 1 do
    begin
      // RGBA in memory to BGRA in the file
      Result[LOffset] := ALevels[LLevel].Pixels[LIndex * 4 + 2];
      Result[LOffset + 1] := ALevels[LLevel].Pixels[LIndex * 4 + 1];
      Result[LOffset + 2] := ALevels[LLevel].Pixels[LIndex * 4];
      Result[LOffset + 3] := ALevels[LLevel].Pixels[LIndex * 4 + 3];
      Inc(LOffset, 4);
    end;
end;

class function TDdsWriter.CompressedFileName(const AImageProgram: string): string;
var
  LResult: string;
  LDepth, LIndex: Integer;
  LChar: Char;
begin
  LResult := 'dds/';
  LDepth := 0;
  for LIndex := 1 to Length(AImageProgram) do
  begin
    LChar := AImageProgram[LIndex];
    if (LChar = '/') or (LChar = '\') or (LChar = '(') then
    begin
      if LDepth < 4 then
      begin
        LResult := LResult + '/';
        Inc(LDepth);
      end
      else
        LResult := LResult + ' ';
    end
    else if (LChar = '<') or (LChar = '>') or (LChar = ':') or (LChar = '|') or (LChar = '"')
      or (LChar = '.') then
      LResult := LResult + '_'
    else if (LChar = ' ') and (LResult[Length(LResult)] = '/') then
      // a space right after a slash is dropped
    else if (LChar = ')') or (LChar = ',') then
      // always dropped
    else
      LResult := LResult + LChar;
  end;
  Result := LResult + '.dds';
end;

end.
