{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL texture buffers - the palette of the paletted textures   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlTexture.Palette;

{$R-}
{$Q-}

interface

type
  /// <summary>256 colors of 32 bits; the bytes in memory are R, G, B, A (see BuildRgba)</summary>
  TGlTextureRgbaPalette = array[0..255] of Cardinal;

  /// <summary>The old gld_InitPalettedTextures and the palette of gld_SetTexturePalette</summary>
  TGlTexturePalette = class
  public
    /// <summary>
    ///   Finds the first pair of colors of the palette (3 bytes each, R, G, B) that are the same:
    ///   the second one is the "transparent" index and maps to the first in the color map
    ///   (every other color maps to itself). The index is -1 if all the colors differ.
    /// </summary>
    class function BuildColorMap(const AColors: PByte; var AColorMap: array of Byte): Integer; static;
    /// <summary>
    ///   The palette for the driver: each color is its three bytes in memory order R, G, B
    ///   followed by 255 (the value is R or G shl 8 or B shl 16 or $FF000000), and the transparent
    ///   color, if there is one (index of 0..255), is all zero
    /// </summary>
    class procedure BuildRgba(const AColors: PByte; const ATransparentIndex: Integer;
      out APalette: TGlTextureRgbaPalette); static;
  end;

implementation

{ TGlTexturePalette }

class function TGlTexturePalette.BuildColorMap(const AColors: PByte; var AColorMap: array of Byte): Integer;
var
  LPalette: array[0..255] of Cardinal;
  LIndex, LOther: Integer;
begin
  for LIndex := 0 to 255 do
  begin
    LPalette[LIndex] := (Cardinal(AColors[LIndex * 3]) shl 16) or (Cardinal(AColors[LIndex * 3 + 1]) shl 8) or
      AColors[LIndex * 3 + 2];
    AColorMap[LIndex] := LIndex;
  end;
  Result := -1;
  for LIndex := 0 to 255 do
  begin
    for LOther := LIndex + 1 to 255 do
      if LPalette[LIndex] = LPalette[LOther] then
      begin
        Result := LOther;
        AColorMap[LOther] := LIndex;
        Break;
      end;
    if Result >= 0 then
      Break;
  end;
end;

class procedure TGlTexturePalette.BuildRgba(const AColors: PByte; const ATransparentIndex: Integer;
  out APalette: TGlTextureRgbaPalette);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 255 do
    APalette[LIndex] := Cardinal(AColors[LIndex * 3]) or (Cardinal(AColors[LIndex * 3 + 1]) shl 8) or
      (Cardinal(AColors[LIndex * 3 + 2]) shl 16) or $FF000000;
  // the old code wrote at index -1 (before the palette) when there was no transparent color
  if (ATransparentIndex >= 0) and (ATransparentIndex <= 255) then
    APalette[ATransparentIndex] := 0;
end;

end.
