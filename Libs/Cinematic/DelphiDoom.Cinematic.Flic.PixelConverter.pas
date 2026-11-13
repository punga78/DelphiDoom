{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - FLIC animations: indexed picture to 32 bit  }
{  pixels (issue #199)                                                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Flic.PixelConverter;

interface

uses
  System.SysUtils,
  DelphiDoom.Imaging.Types,
  DelphiDoom.Cinematic.Flic.Types;

type
  /// <summary>Turns the 8 bit picture of a FLIC and its palette into pixels $AABBGGRR</summary>
  TFlicPixelConverter = class
  public
    /// <summary>The color of a palette entry as a pixel (alpha $FF; the red one is the low byte)</summary>
    class function ColorToPixel(ARed, AGreen, ABlue: Byte): Cardinal; static;
    /// <summary>One pixel for every byte of AIndices</summary>
    class function ToPixels(const AIndices: TBytes; const APalette: TFlicPalette): TImagingPixels; static;
  end;

implementation

{ TFlicPixelConverter }

class function TFlicPixelConverter.ColorToPixel(ARed, AGreen, ABlue: Byte): Cardinal;
begin
  Result := (Cardinal(FLIC_ALPHA_OPAQUE) shl 24) or (Cardinal(ABlue) shl 16) or
    (Cardinal(AGreen) shl 8) or ARed;
end;

class function TFlicPixelConverter.ToPixels(const AIndices: TBytes;
  const APalette: TFlicPalette): TImagingPixels;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AIndices));
  for LIndex := 0 to High(AIndices) do
    Result[LIndex] := APalette[AIndices[LIndex]];
end;

end.
