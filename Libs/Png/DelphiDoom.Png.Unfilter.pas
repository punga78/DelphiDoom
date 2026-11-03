{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - reverses the filters of the scanlines                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.Unfilter;

interface

{$POINTERMATH ON}

type
  /// <summary>
  ///   Reconstructs a scanline from its filtered form (filters 0..4 of the
  ///   PNG specification)
  /// </summary>
  TPngUnfilter = class sealed
  public
    /// <summary>
    ///   Reverses AFilter in place on ARow, which holds ACount filtered
    ///   bytes. APrevious is the reconstructed row above it (all zeros for
    ///   the first row of a pass) and AStride is the distance in bytes to the
    ///   same byte of the previous pixel. Raises DDPNG_ERR_DATA for a filter
    ///   type that does not exist
    /// </summary>
    class procedure Apply(AFilter: Integer; ARow, APrevious: PByte; ACount,
      AStride: Integer); static;
  end;

implementation

uses
  DelphiDoom.Png.Intf, DelphiDoom.Png.Predictor;

{ TPngUnfilter }

class procedure TPngUnfilter.Apply(AFilter: Integer; ARow, APrevious: PByte;
  ACount, AStride: Integer);
var
  LIndex: Integer;
  LLeft: Integer;
  LUpperLeft: Integer;
begin
  case AFilter of
    0:
      ;
    1:
      for LIndex := AStride to ACount - 1 do
        ARow[LIndex] := Byte(ARow[LIndex] + ARow[LIndex - AStride]);
    2:
      for LIndex := 0 to ACount - 1 do
        ARow[LIndex] := Byte(ARow[LIndex] + APrevious[LIndex]);
    3:
      for LIndex := 0 to ACount - 1 do
      begin
        if LIndex >= AStride then
          LLeft := ARow[LIndex - AStride]
        else
          LLeft := 0;
        ARow[LIndex] := Byte(ARow[LIndex] + ((LLeft + APrevious[LIndex]) shr 1));
      end;
    4:
      for LIndex := 0 to ACount - 1 do
      begin
        if LIndex >= AStride then
        begin
          LLeft := ARow[LIndex - AStride];
          LUpperLeft := APrevious[LIndex - AStride];
        end
        else
        begin
          LLeft := 0;
          LUpperLeft := 0;
        end;
        ARow[LIndex] := Byte(ARow[LIndex] +
          TPngPredictor.Paeth(LLeft, APrevious[LIndex], LUpperLeft));
      end;
  else
    raise EPngException.CreateCode(DDPNG_ERR_DATA);
  end;
end;

end.
