{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - the second reader of PCX files                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Port of t_pcx4.pas, a PCX loader with the VGA palettes of 6 bits            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Decoder.PcxLegacy;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Texture.ByteReader;

type
  /// <summary>
  ///   The reader that the old code used for the PCX files that the main one does not take: other
  ///   versions than 5, the images of 16 colors in planes and the 8 bit ones that have no signed palette.
  ///   It works as the old PCXLoad of t_pcx4.pas with the colors set to 24 bit: the palette
  ///   entries are cut to 6 bits and brought back as (value div 4) * 4 + 3, so black is (3, 3, 3)
  /// </summary>
  /// <remarks>
  ///   Taken: 1 bit with 1 to 4 planes (2 to 16 colors), 8 bit with 1 plane (palette in the 769
  ///   last bytes) and 8 bit with 3 planes (true color). The others (4, 16 and 32 bit, planes that
  ///   the old code did not draw) crashed the old loader or gave a blank image: here they are false.
  ///   The palette entries that a file does not have are 0 (the old code kept those of the
  ///   previous file); the old buffers of a line overflowed on a damaged file, these do not
  /// </remarks>
  TTexturePcxLegacyReader = class sealed
  strict private
    type
      TVgaPalette = array[0..255, 1..3] of Byte;
    const
      // The palette that version 3 files have in place of the one in the header
      DEFAULT_PALETTE: array[0..15, 1..3] of Byte = (
        (0, 0, 0), (0, 0, 32), (0, 32, 0), (0, 32, 32),
        (32, 0, 0), (32, 0, 32), (32, 32, 0), (42, 42, 42),
        (21, 21, 21), (0, 0, 63), (0, 63, 0), (0, 63, 63),
        (63, 0, 0), (63, 0, 63), (63, 63, 0), (63, 63, 63));
    class procedure ReadColorMap(const AReader: TTextureByteReader; ACount, AVersion: Integer;
      var APalette: TVgaPalette); static;
    class procedure ReadLine(const AReader: TTextureByteReader; ABitsPerPixel, APlanes,
      ABytesPerLine: Integer; var ALine: TBytes); static;
  public
    /// <summary>The pixels as $00RRGGBB, row by row from the top</summary>
    class function Read(const ASource: TBytes; out AWidth, AHeight: Integer;
      out APixels: TTexturePixels): Boolean; static;
  end;

implementation

{ TTexturePcxLegacyReader }

class procedure TTexturePcxLegacyReader.ReadColorMap(const AReader: TTextureByteReader;
  ACount, AVersion: Integer; var APalette: TVgaPalette);
var
  LIndex: Integer;
  LChannel: Integer;
  LValue: Byte;
begin
  for LIndex := 0 to ACount - 1 do
    for LChannel := 1 to 3 do
    begin
      LValue := AReader.ReadByte;
      // version 2 files keep the colors of the first 4 levels of the EGA
      if (AVersion = 2) and (LValue < 4) then
        LValue := LValue * $55;
      APalette[LIndex, LChannel] := LValue div 4;
    end;
end;

class procedure TTexturePcxLegacyReader.ReadLine(const AReader: TTextureByteReader;
  ABitsPerPixel, APlanes, ABytesPerLine: Integer; var ALine: TBytes);
var
  LCount: Integer;
  LMaximum: Integer;
  LZ: Integer;
  LPlane: Integer;
  LFirst, LValue: Byte;
  LRun: Integer;
  LBit: Integer;

  procedure Put(AByte: Byte);
  var
    LShift: Integer;
  begin
    case ABitsPerPixel of
      8:
      begin
        if LZ < Length(ALine) then
          ALine[LZ] := AByte;
        Inc(LZ);
      end;
      1:
        for LShift := 7 downto 0 do
        begin
          if ((AByte shr LShift) and 1) <> 0 then
            LBit := 1
          else
            LBit := 0;
          if (LZ < Length(ALine)) and (LPlane < 8) then
            ALine[LZ] := Byte(ALine[LZ] + (LBit shl LPlane));
          Inc(LZ);
          if LZ >= ABytesPerLine * 8 then
          begin
            LZ := 0;
            Inc(LPlane);
          end;
        end;
    end;
  end;

begin
  LCount := 0;
  LZ := 0;
  LPlane := 0;
  LMaximum := ABytesPerLine * APlanes;
  repeat
    LFirst := AReader.ReadByte;
    if (LFirst and $C0) = $C0 then
    begin
      LRun := LFirst and $3F;
      LValue := AReader.ReadByte;
      while LRun > 0 do
      begin
        Put(LValue);
        Dec(LRun);
        Inc(LCount);
      end;
    end
    else
    begin
      Put(LFirst);
      Inc(LCount);
    end;
  until (LCount >= LMaximum) or AReader.Overrun;
end;

class function TTexturePcxLegacyReader.Read(const ASource: TBytes; out AWidth, AHeight: Integer;
  out APixels: TTexturePixels): Boolean;
var
  LReader: TTextureByteReader;
  LPalette: TVgaPalette;
  LVersion, LBitsPerPixel, LPlanes: Integer;
  LLeft, LTop, LRight, LBottom: Word;
  LBytesPerLine: Integer;
  LLine: TBytes;
  LY, LX: Integer;
  LIndex: Integer;
  LRed, LGreen, LBlue: Byte;
  LSkip: Integer;
begin
  Result := False;
  AWidth := 0;
  AHeight := 0;
  APixels := nil;
  FillChar(LPalette, SizeOf(LPalette), 0);
  LReader := TTextureByteReader.Create(ASource);
  try
    if LReader.ReadByte <> 10 then
      Exit;
    LVersion := LReader.ReadByte;
    LReader.ReadByte; // encoding
    LBitsPerPixel := LReader.ReadByte;
    LLeft := LReader.ReadWord;
    LTop := LReader.ReadWord;
    LRight := LReader.ReadWord;
    LBottom := LReader.ReadWord;
    AWidth := Word(LRight - LLeft + 1);
    AHeight := Word(LBottom - LTop + 1);
    LReader.ReadWord; // resolution
    LReader.ReadWord;
    ReadColorMap(LReader, 16, LVersion, LPalette);
    LReader.ReadByte; // reserved
    LPlanes := LReader.ReadByte;
    LBytesPerLine := LReader.ReadWord;
    LReader.ReadWord; // palette type
    for LSkip := 1 to 58 do
      LReader.ReadByte;
    if not (LBitsPerPixel in [1, 4, 8, 16, 24, 32]) then
      Exit;

    // the combinations that the old code drew; the others failed on it
    if not (((LBitsPerPixel = 1) and (LPlanes in [1..4])) or
            ((LBitsPerPixel = 8) and (LPlanes in [1, 3]))) then
      Exit;
    if (AWidth <= 0) or (AHeight <= 0) or (AWidth > TEXTURE_MAX_DIMENSION) or
       (AHeight > TEXTURE_MAX_DIMENSION) or (LBytesPerLine <= 0) then
      Exit;

    if LVersion = 3 then
      for LIndex := 0 to 15 do
        for LY := 1 to 3 do
          LPalette[LIndex, LY] := DEFAULT_PALETTE[LIndex, LY];
    if (LBitsPerPixel = 1) and (LPlanes = 1) then
    begin
      LPalette[0, 1] := 0;
      LPalette[0, 2] := 0;
      LPalette[0, 3] := 0;
      LPalette[1, 1] := 63;
      LPalette[1, 2] := 63;
      LPalette[1, 3] := 63;
    end;
    if (LBitsPerPixel = 8) and (LPlanes = 1) then
    begin
      // the palette is in the last 769 bytes: the byte $0C and 256 entries. The old
      // code read the entries also when the byte is not there
      LIndex := LReader.Position;
      LReader.Seek(LReader.Size - 769);
      LReader.ReadByte;
      ReadColorMap(LReader, 256, LVersion, LPalette);
      LReader.Seek(LIndex);
    end;

    SetLength(APixels, AWidth * AHeight);
    // a run can go past the end of a line by 63 bytes
    SetLength(LLine, LBytesPerLine * LPlanes + 64 + AWidth * 4);
    for LY := 0 to AHeight - 1 do
    begin
      if LBitsPerPixel <> 8 then
        FillChar(LLine[0], Length(LLine), 0);
      ReadLine(LReader, LBitsPerPixel, LPlanes, LBytesPerLine, LLine);
      for LX := 0 to AWidth - 1 do
      begin
        if (LBitsPerPixel = 8) and (LPlanes = 3) then
        begin
          LRed := LLine[LX];
          LGreen := LLine[LBytesPerLine + LX];
          LBlue := LLine[2 * LBytesPerLine + LX];
        end
        else
        begin
          LIndex := LLine[LX];
          LRed := Byte(LPalette[LIndex, 1] * 4 + 3);
          LGreen := Byte(LPalette[LIndex, 2] * 4 + 3);
          LBlue := Byte(LPalette[LIndex, 3] * 4 + 3);
        end;
        APixels[LY * AWidth + LX] := (Cardinal(LRed) shl 16) or (Cardinal(LGreen) shl 8) or LBlue;
      end;
    end;
    // a file that ends before the image does is not an image (the old loader stopped on it)
    if LReader.Overrun then
    begin
      APixels := nil;
      Exit;
    end;
    Result := True;
  finally
    LReader.Free;
  end;
end;

end.
