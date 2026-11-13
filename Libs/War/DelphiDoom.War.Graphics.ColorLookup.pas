{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - palette indices to RGBA pixels                    }
{                                                                              }
{  Port of war1 (acoto87/war1), buildRgbaLut of war_resources.c,               }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-      }
{  war1.txt). This is an altered version, not the original.                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Graphics.ColorLookup;

interface

uses
  System.SysUtils, DelphiDoom.War.Graphics.Types;

type
  /// <summary>The table that turns a palette index into the 4 bytes R G B A of a pixel</summary>
  TWarColorLookupBuilder = class
  public
    /// <summary>
    ///   The color 0 is transparent (all four bytes zero, whatever the palette says); the others are opaque.
    ///   APalette has 768 bytes
    /// </summary>
    class function Build(const APalette: TBytes): TWarColorLookup; static;
    /// <summary>Writes the pixel of the color AColor at ABuffer[AOffset..AOffset + 3] (R, G, B, A)</summary>
    class procedure PutPixel(const ALookup: TWarColorLookup; AColor: Byte; var ABuffer: TBytes; AOffset: Integer); static; inline;
  end;

implementation

{ TWarColorLookupBuilder }

class function TWarColorLookupBuilder.Build(const APalette: TBytes): TWarColorLookup;
var
  LColor: Integer;
begin
  if Length(APalette) <> WAR_PALETTE_LENGTH then
    raise EArgumentException.CreateFmt(SWarGraphicsPaletteLength, [Length(APalette), WAR_PALETTE_LENGTH]);
  Result[0] := 0;
  for LColor := 1 to WAR_PALETTE_COLORS - 1 do
    Result[LColor] := Cardinal(APalette[LColor * 3]) or (Cardinal(APalette[LColor * 3 + 1]) shl 8) or
      (Cardinal(APalette[LColor * 3 + 2]) shl 16) or $FF000000;
end;

class procedure TWarColorLookupBuilder.PutPixel(const ALookup: TWarColorLookup; AColor: Byte; var ABuffer: TBytes;
  AOffset: Integer);
var
  LValue: Cardinal;
begin
  // the four bytes are in memory order of a little endian number, as the original copies the 32 bit value
  LValue := ALookup[AColor];
  ABuffer[AOffset] := Byte(LValue);
  ABuffer[AOffset + 1] := Byte(LValue shr 8);
  ABuffer[AOffset + 2] := Byte(LValue shr 16);
  ABuffer[AOffset + 3] := Byte(LValue shr 24);
end;

end.
