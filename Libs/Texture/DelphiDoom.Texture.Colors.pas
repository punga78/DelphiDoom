{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - conversions of single colors                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Colors;

interface

uses
  DelphiDoom.Texture.Types;

type
  /// <summary>
  ///   The color operations of TEXLIB (t_main, t_colors), without state and in Pascal: the
  ///   old ones were assembler
  /// </summary>
  TTextureColors = class sealed
  public
    /// <summary>
    ///   A word 0rrrrrgggggbbbbb as a 24 bit color, each field shifted by 3 so that the
    ///   top bit of the field is the top bit of the byte. Bit 15 is ignored
    /// </summary>
    /// <remarks>
    ///   The old pixel15to24 was assembler that began with "xor eax, eax" and then read its
    ///   parameter from the register that it had just cleared, so it always gave 0: the
    ///   images of 16 bit (the 16 bit TGA files) were black. This one does what it was written for
    /// </remarks>
    class function Pixel15To24(AColor: Word): Cardinal; static;
    /// <summary>Exchanges the red and the blue bytes, keeps the others</summary>
    class function SwapRedBlue(AColor: Cardinal): Cardinal; static;
    /// <summary>The mean of the three channels of a $00RRGGBB color (the old gray scale)</summary>
    class function Gray(AColor: Cardinal): Cardinal; static;
    /// <summary>
    ///   An entry of a palette file as $00RRGGBB. ARaw is the 4 bytes that begin at the
    ///   entry (a record can be shorter than that: the rest is what comes after it)
    /// </summary>
    /// <remarks>
    ///   For Bgr5 the blue channel comes from the bits 29..31 of ARaw, not from the low bits
    ///   of the word (the old code shifted by a negative number and the hardware used the
    ///   low 5 bits of it), and the result is masked with $F8: the blue is always 0. Kept,
    ///   it gives the same colors as before
    /// </remarks>
    class function PaletteEntry(ARaw: Cardinal; ALayout: TTexturePaletteLayout): Cardinal; static;
  end;

implementation

{ TTextureColors }

class function TTextureColors.Pixel15To24(AColor: Word): Cardinal;
begin
  Result := (Cardinal(AColor shr 10) and $1F) shl 19 or
            (Cardinal(AColor shr 5) and $1F) shl 11 or
            (Cardinal(AColor) and $1F) shl 3;
end;

class function TTextureColors.SwapRedBlue(AColor: Cardinal): Cardinal;
begin
  Result := (AColor and $FF00FF00) or ((AColor and $FF) shl 16) or ((AColor shr 16) and $FF);
end;

class function TTextureColors.Gray(AColor: Cardinal): Cardinal;
begin
  AColor := AColor and $FFFFFF;
  Result := ((AColor shr 16) + ((AColor shr 8) and $FF) + (AColor and $FF)) div 3;
end;

class function TTextureColors.PaletteEntry(ARaw: Cardinal; ALayout: TTexturePaletteLayout): Cardinal;
var
  LRed, LGreen, LBlue: Byte;
begin
  case ALayout of
    TTexturePaletteLayout.Bgr5:
    begin
      LRed := Byte((ARaw shr 7) and $F8);
      LGreen := Byte((ARaw shr 2) and $F8);
      LBlue := Byte((ARaw shr 29) and $F8);
    end;
  else
    LRed := Byte(ARaw shr 16);
    LGreen := Byte(ARaw shr 8);
    LBlue := Byte(ARaw);
  end;
  Result := (Cardinal(LRed) shl 16) or (Cardinal(LGreen) shl 8) or LBlue;
end;

end.
