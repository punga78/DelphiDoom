{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the batch operations on pixels (r_mmx)      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.PixelBatch;

interface

type
  /// <summary>
  ///   The operations of r_mmx on a run of pixels in pure Pascal, for the targets where the MMX and
  ///   3DNow versions are not compiled (64 bit). They give the same bytes as the assembler ones.
  /// </summary>
  /// <remarks>
  ///   They have no state. The pixels are 32 bit values, the bytes of a pixel are blue, green,
  ///   red and the fourth one (little endian, as the engine keeps them).
  /// </remarks>
  TPixelBatch = class
  public
    /// <summary>
    ///   Adds AColor to every pixel of the run, byte by byte, stopping at 255 (the old
    ///   R_BatchColorAdd32_MMX: paddusb). AByteCount is the length of the run in bytes.
    /// </summary>
    class procedure AddSaturated(ADestination: PByte; AColor: Cardinal; AByteCount: Integer); static;
    /// <summary>
    ///   Halves the bytes of the run (the old R_BatchColorShade_AMD). The first AByteCount and not 7
    ///   bytes are the average with zero rounded up, (b + 1) shr 1, as pavgusb gives; the last
    ///   bytes (fewer than 8) are b shr 1, as the old tail loop did.
    /// </summary>
    class procedure HalveBytes(ADestination: PByte; AByteCount: Integer); static;
  end;

implementation

{ TPixelBatch }

class procedure TPixelBatch.AddSaturated(ADestination: PByte; AColor: Cardinal; AByteCount: Integer);
var
  LAddends: array[0..3] of Byte;
  LIndex: Integer;
  LSum: Integer;
begin
  LAddends[0] := Byte(AColor and $FF);
  LAddends[1] := Byte((AColor shr 8) and $FF);
  LAddends[2] := Byte((AColor shr 16) and $FF);
  LAddends[3] := Byte((AColor shr 24) and $FF);
  for LIndex := 0 to AByteCount - 1 do
  begin
    LSum := Integer(ADestination^) + LAddends[LIndex and 3];
    if LSum > 255 then
      LSum := 255;
    ADestination^ := Byte(LSum);
    Inc(ADestination);
  end;
end;

class procedure TPixelBatch.HalveBytes(ADestination: PByte; AByteCount: Integer);
var
  LRounded: Integer;
  LIndex: Integer;
begin
  if AByteCount <= 0 then
    Exit;
  LRounded := AByteCount and not 7;
  for LIndex := 0 to AByteCount - 1 do
  begin
    if LIndex < LRounded then
      ADestination^ := Byte((Integer(ADestination^) + 1) shr 1)
    else
      ADestination^ := Byte(ADestination^ shr 1);
    Inc(ADestination);
  end;
end;

end.
