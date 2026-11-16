{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the slopes of the map                            }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): ActivateSlopes of utils.pas }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Slopes;

interface

type
  /// <summary>The table of ActivateSlopes: a byte of the plane mapslopes says the shape of the floor and of the ceiling</summary>
  TGreedSlopes = class
  public
    /// <summary>
    ///   The flags to add to mapflags for a byte of mapslopes: floor in bits 0..2, ceiling in bits 3..5. Only the
    ///   values 49..63 are slopes; any other is 0
    /// </summary>
    class function FlagsOf(ASlope: Byte): Byte; static;
  end;

implementation

uses
  DelphiDoom.Greed.World.Intf;

const
  FLAT = GREED_POLY_FLAT;
  SLOPE = GREED_POLY_SLOPE;
  UL_TO_LR = GREED_POLY_UL_TO_LR;
  UR_TO_LL = GREED_POLY_UR_TO_LL;

  // floor, ceiling of the values 49..63
  SHAPES: array[49..63, 0..1] of Byte = (
    (FLAT, SLOPE), (FLAT, UR_TO_LL), (FLAT, UL_TO_LR), (SLOPE, FLAT), (SLOPE, UR_TO_LL), (SLOPE, UL_TO_LR),
    (UR_TO_LL, SLOPE), (UR_TO_LL, FLAT), (UR_TO_LL, UL_TO_LR), (UL_TO_LR, SLOPE), (UL_TO_LR, UR_TO_LL),
    (UL_TO_LR, FLAT), (SLOPE, SLOPE), (UR_TO_LL, UR_TO_LL), (UL_TO_LR, UL_TO_LR));

{ TGreedSlopes }

class function TGreedSlopes.FlagsOf(ASlope: Byte): Byte;
begin
  if (ASlope < 49) or (ASlope > 63) then
    Exit(0);
  Result := Byte((SHAPES[ASlope, 0] shl GREED_FLS_FLOOR) or (SHAPES[ASlope, 1] shl GREED_FLS_CEILING));
end;

end.
