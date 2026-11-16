{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL texture buffers - paints a flat into a buffer            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlTexture.FlatPainter;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.GlTexture.Types;

type
  /// <summary>
  ///   The old gld_AddFlatToTexture without the ripple: the colors of a flat (one byte per
  ///   pixel, in rows of the real width) go to a buffer as the palette map (paletted buffer)
  ///   or as R, G, B, 255. The ripple is applied by the caller with TGlTextureRipple.
  /// </summary>
  TGlTextureFlatPainter = class
  public
    class procedure Paint(const ATarget: TGlTextureTarget; const AFlat: PByte;
      const APalette: TGlTexturePaletteData; const APaletted: Boolean); static;
  end;

implementation

{ TGlTextureFlatPainter }

class procedure TGlTextureFlatPainter.Paint(const ATarget: TGlTextureTarget; const AFlat: PByte;
  const APalette: TGlTexturePaletteData; const APaletted: Boolean);
var
  LX, LY, LPos, LRow, LColor: Integer;
begin
  if not Assigned(ATarget.Pixels) or not Assigned(AFlat) then
    Exit;

  if APaletted then
  begin
    for LY := 0 to ATarget.RealHeight - 1 do
    begin
      LPos := LY * ATarget.BufferWidth;
      LRow := LY * ATarget.RealWidth;
      for LX := 0 to ATarget.RealWidth - 1 do
      begin
        ATarget.Pixels[LPos] := APalette.ColorMap[AFlat[LRow + LX]];
        Inc(LPos);
      end;
    end;
  end
  else
  begin
    for LY := 0 to ATarget.RealHeight - 1 do
    begin
      LPos := 4 * (LY * ATarget.BufferWidth);
      for LX := 0 to ATarget.RealWidth - 1 do
      begin
        LColor := AFlat[LY * ATarget.RealWidth + LX] * 3;
        ATarget.Pixels[LPos] := APalette.Colors[LColor];
        ATarget.Pixels[LPos + 1] := APalette.Colors[LColor + 1];
        ATarget.Pixels[LPos + 2] := APalette.Colors[LColor + 2];
        ATarget.Pixels[LPos + 3] := 255;
        Inc(LPos, 4);
      end;
    end;
  end;
end;

end.
