{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the palette                                      }
{  Port of xGreed (Jim Valavanis): CA_CachePalette of d_disk                    }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Palette;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The lump "palette" has 768 bytes, the R, G, B of 256 colors with 6 bits of value as the VGA wants them.
  ///   CA_CachePalette multiplies each by 4 in a byte (a value over 63 wraps), and so does this
  /// </summary>
  TGreedPalette = class
  public
    /// <summary>The 768 bytes R, G, B of 8 bits; EGreedDataException if the lump has less than 768</summary>
    class function FromLump(const ALump: TBytes): TBytes; static;
  end;

implementation

uses
  DelphiDoom.Greed.Types;

{ TGreedPalette }

class function TGreedPalette.FromLump(const ALump: TBytes): TBytes;
var
  LIndex: Integer;
begin
  if Length(ALump) < GREED_PALETTE_BYTES then
    raise EGreedDataException.CreateFmt(SGreedPaletteTooShort, [Length(ALump), GREED_PALETTE_BYTES]);
  SetLength(Result, GREED_PALETTE_BYTES);
  for LIndex := 0 to GREED_PALETTE_BYTES - 1 do
    Result[LIndex] := Byte(ALump[LIndex] shl 2);
end;

end.
