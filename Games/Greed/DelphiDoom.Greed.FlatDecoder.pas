{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - a flat (floor or ceiling texture)                }
{  Port of xGreed (Jim Valavanis): MapRow of r_spans.pas                        }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.FlatDecoder;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  /// <summary>
  ///   A flat is 64 x 64 bytes: MapRow reads the pixel of the column x and the row y at index y * 64 + x
  /// </summary>
  TGreedFlatDecoder = class(TInterfacedObject, IGreedImageDecoder)
  public
    function Decode(const ALump: TBytes): TGreedImage;
  end;

implementation

{ TGreedFlatDecoder }

function TGreedFlatDecoder.Decode(const ALump: TBytes): TGreedImage;
begin
  if Length(ALump) < GREED_FLAT_BYTES then
    raise EGreedDataException.CreateFmt(SGreedImageTooShort, ['flat', Length(ALump), GREED_FLAT_BYTES]);
  Result.Width := GREED_FLAT_SIZE;
  Result.Height := GREED_FLAT_SIZE;
  Result.OriginX := 0;
  Result.OriginY := 0;
  Result.Pixels := Copy(ALump, 0, GREED_FLAT_BYTES);
end;

end.
