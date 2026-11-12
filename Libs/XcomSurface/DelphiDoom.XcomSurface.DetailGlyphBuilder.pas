{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - makes the character of the text at the    }
{  resolution of the display from its coverage: the body and, for the fonts     }
{  that have one, the dark outline of the fonts of the game                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.DetailGlyphBuilder;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Glyph.Types, DelphiDoom.XcomSurface.Ink.Types;

type
  /// <summary>
  ///   A rasterized character (256 levels of coverage, drawn AScale times larger than for the 320 x 200 screen)
  ///   as the text at the resolution of the display wants it. The coverage stays what it is: it becomes the alpha
  ///   of the color of the text, not one of the three levels of the pictures. The outline of the big and small
  ///   fonts, one pixel of the game wide, is AScale pixels wide here: the pixels within that distance of the body
  ///   have the level 4, the ones only on its corners the level 5, as in the pictures of the game
  /// </summary>
  TXcomDetailGlyphBuilder = class sealed
  public
    /// <summary>
    ///   Left and Top of the result are the position of the rectangle relative to the one of the coverage (0, or
    ///   minus the width of the outline): the caller adds where the character goes in its cell
    /// </summary>
    class function Build(const ACoverage: TXcomGlyphBitmap; AOutline: Boolean; AScale: Integer): TXcomDetailGlyph;
      static;
  end;

implementation

class function TXcomDetailGlyphBuilder.Build(const ACoverage: TXcomGlyphBitmap; AOutline: Boolean;
  AScale: Integer): TXcomDetailGlyph;
var
  LMargin: Integer;
  LX: Integer;
  LY: Integer;
  LDeltaX: Integer;
  LDeltaY: Integer;
  LNear: Byte;
  LFar: Byte;
  LValue: Byte;
  LIndex: Integer;
begin
  LMargin := 0;
  if AOutline then
    LMargin := AScale;
  Result.Width := ACoverage.Width + 2 * LMargin;
  Result.Height := ACoverage.Height + 2 * LMargin;
  Result.Left := -LMargin;
  Result.Top := -LMargin;
  Result.Body := nil;
  Result.Outline := nil;
  Result.OutlineLevel := nil;
  SetLength(Result.Body, Result.Width * Result.Height);
  for LY := 0 to ACoverage.Height - 1 do
    for LX := 0 to ACoverage.Width - 1 do
      Result.Body[(LY + LMargin) * Result.Width + LX + LMargin] := ACoverage.Pixels[LY * ACoverage.Width + LX];
  if not AOutline then
    Exit;
  SetLength(Result.Outline, Result.Width * Result.Height);
  SetLength(Result.OutlineLevel, Result.Width * Result.Height);
  for LY := 0 to Result.Height - 1 do
    for LX := 0 to Result.Width - 1 do
    begin
      // the strongest body pixel within the width of the outline (a disk) and within the square around it
      LNear := 0;
      LFar := 0;
      for LDeltaY := -LMargin to LMargin do
        for LDeltaX := -LMargin to LMargin do
        begin
          LValue := ACoverage.At(LX - LMargin + LDeltaX, LY - LMargin + LDeltaY);
          if LValue = 0 then
            Continue;
          if LValue > LFar then
            LFar := LValue;
          if (LValue > LNear) and (LDeltaX * LDeltaX + LDeltaY * LDeltaY <= LMargin * LMargin) then
            LNear := LValue;
        end;
      LIndex := LY * Result.Width + LX;
      Result.Outline[LIndex] := LFar;
      if LNear = LFar then
        Result.OutlineLevel[LIndex] := XCOM_GLYPH_LEVEL_OUTLINE
      else
        Result.OutlineLevel[LIndex] := XCOM_GLYPH_LEVEL_CORNER;
    end;
end;

end.
