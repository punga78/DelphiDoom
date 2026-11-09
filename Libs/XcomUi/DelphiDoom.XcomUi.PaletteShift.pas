{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - the PaletteShift shader of Text.cpp     }
{  (ShaderDraw with the pixel function of Text) used to draw the characters     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.PaletteShift;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Surface;

type
  /// <summary>
  ///   ShaderDraw&lt;PaletteShift&gt;(ShaderSurface(dest), ShaderCrop(glyph), color, mul, mid): the cropped part of the
  ///   glyph, placed at the position of the glyph surface, is drawn on the destination; each non transparent pixel
  ///   becomes color + pixel * mul + (mid ? 2 * (mid - pixel) : 0), wrapped to a byte
  /// </summary>
  TXcomPaletteShift = class
  public
    class procedure Draw(ADestination, AGlyph: TXcomSurface; AColor, AMultiplier, AMiddle: Integer); static;
  end;

implementation

class procedure TXcomPaletteShift.Draw(ADestination, AGlyph: TXcomSurface; AColor, AMultiplier, AMiddle: Integer);
var
  LCrop: TXcomRect;
  LSourceX0: Integer;
  LSourceY0: Integer;
  LSourceX1: Integer;
  LSourceY1: Integer;
  LMoveX: Integer;
  LMoveY: Integer;
  LX: Integer;
  LY: Integer;
  LStartX: Integer;
  LEndX: Integer;
  LStartY: Integer;
  LEndY: Integer;
  LSource: Integer;
  LInverse: Integer;
  LDestination: PByte;
begin
  LCrop := AGlyph.Crop;
  if (LCrop.W <> 0) and (LCrop.H <> 0) then
  begin
    LSourceX0 := LCrop.X;
    LSourceY0 := LCrop.Y;
    LSourceX1 := LCrop.X + LCrop.W;
    LSourceY1 := LCrop.Y + LCrop.H;
    LMoveX := AGlyph.X - LCrop.X;
    LMoveY := AGlyph.Y - LCrop.Y;
  end
  else
  begin
    LSourceX0 := 0;
    LSourceY0 := 0;
    LSourceX1 := AGlyph.Width;
    LSourceY1 := AGlyph.Height;
    LMoveX := AGlyph.X;
    LMoveY := AGlyph.Y;
  end;
  // the domain of the source, in destination coordinates, cut by the destination and by the source surface
  LStartX := LSourceX0;
  if LStartX < 0 then
    LStartX := 0;
  LEndX := LSourceX1;
  if LEndX > AGlyph.Width then
    LEndX := AGlyph.Width;
  LStartY := LSourceY0;
  if LStartY < 0 then
    LStartY := 0;
  LEndY := LSourceY1;
  if LEndY > AGlyph.Height then
    LEndY := AGlyph.Height;
  for LY := LStartY to LEndY - 1 do
  begin
    if (LY + LMoveY < 0) or (LY + LMoveY >= ADestination.Height) then
      Continue;
    for LX := LStartX to LEndX - 1 do
    begin
      if (LX + LMoveX < 0) or (LX + LMoveX >= ADestination.Width) then
        Continue;
      LSource := AGlyph.GetPixel(LX, LY);
      if LSource <> 0 then
      begin
        if AMiddle <> 0 then
          LInverse := 2 * (AMiddle - LSource)
        else
          LInverse := 0;
        LDestination := ADestination.PixelPointer(LX + LMoveX, LY + LMoveY);
        LDestination^ := Byte((AColor + LSource * AMultiplier + LInverse) and $FF);
      end;
    end;
  end;
end;

end.
