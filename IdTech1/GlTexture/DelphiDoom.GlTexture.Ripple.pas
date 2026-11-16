{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL texture buffers - the ripple effect of the liquid flats  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlTexture.Ripple;

{$R-}
{$Q-}

interface

uses
  System.SysUtils,
  DelphiDoom.GlTexture.Types;

type
  /// <summary>
  ///   The old gld_RippleTransform: the pixels of a buffer are moved by the values of one row of
  ///   the ripple table (r_defripple), in both directions, with wrap around. The expressions
  ///   are the old ones (the rounding of the shifts is the one of Round on the quotient), so
  ///   the result is the same as before.
  /// </summary>
  TGlTextureRipple = class
  public
    /// <summary>
    ///   Transforms a buffer of AWidth x AHeight pixels of ABytesPerPixel (1, 3 or 4) bytes with
    ///   the row of the table. Nothing happens if the row is nil
    /// </summary>
    class procedure Transform(const ABuffer: PByte; const AWidth, AHeight, ABytesPerPixel: Integer;
      const ARow: PGlRippleRow); static;
  end;

implementation

{ TGlTextureRipple }

class procedure TGlTextureRipple.Transform(const ABuffer: PByte; const AWidth, AHeight, ABytesPerPixel: Integer;
  const ARow: PGlRippleRow);
var
  LX, LY, LSourceX, LSourceY, LShiftX, LShiftY: Integer;
  LSize: Integer;
  LNew: TBytes;
  LNewPos, LSourcePos: Integer;
begin
  LSize := AWidth * AHeight * ABytesPerPixel;
  if not Assigned(ARow) or (LSize <= 0) then
    Exit;
  SetLength(LNew, LSize);
  for LX := 0 to AWidth - 1 do
    for LY := 0 to AHeight - 1 do
    begin
      LShiftX := Round((ARow[Round(LY * 128 / AHeight) and 127] / $10000) * AHeight / 64);
      LShiftY := Round((ARow[Round(LX * 128 / AWidth) and 127] / $10000) * AWidth / 64);
      LSourceX := (LX + LShiftX) mod AWidth;
      while LSourceX < 0 do
        LSourceX := LSourceX + AWidth;
      while LSourceX >= AWidth do
        LSourceX := LSourceX - AWidth;
      LSourceY := (LY + LShiftY) mod AHeight;
      while LSourceY < 0 do
        LSourceY := LSourceY + AHeight;
      // the old code added the height here, so a value out of the range would never end:
      // the modulo above keeps it in range
      while LSourceY >= AHeight do
        LSourceY := LSourceY - AHeight;
      LSourcePos := LSourceX + LSourceY * AWidth;
      LNewPos := LX + LY * AWidth;
      case ABytesPerPixel of
        1:
          LNew[LNewPos] := ABuffer[LSourcePos];
        4:
          PCardinal(@LNew[LNewPos * 4])^ := PCardinal(ABuffer + LSourcePos * 4)^;
        3:
          begin
            LNewPos := LNewPos * 3;
            LSourcePos := LSourcePos * 3;
            LNew[LNewPos] := ABuffer[LSourcePos];
            LNew[LNewPos + 1] := ABuffer[LSourcePos + 1];
            LNew[LNewPos + 2] := ABuffer[LSourcePos + 2];
          end;
      end;
    end;
  Move(LNew[0], ABuffer^, LSize);
end;

end.
