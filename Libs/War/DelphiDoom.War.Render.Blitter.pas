{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the pixels of a drawing                           }
{                                                                              }
{  Port of war1 (acoto87/war1), the use the renderer makes of SDL3             }
{  (SDL_RenderTexture, SDL_RenderTextureRotated, SDL_RenderFillRect,           }
{  SDL_RenderRect: software renderer on a 320 x 200 RGBA surface), (c) 2019    }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). The }
{  pixels follow the software renderer of SDL3 (zlib License, (c) Sam Lantinga)}
{  as it behaves, proved against the real SDL3.dll. This is an altered version,}
{  not the original.                                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Render.Blitter;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, System.Math, DelphiDoom.War.Types, DelphiDoom.War.Graphics.Types, DelphiDoom.War.Render.Types;

type
  /// <summary>
  ///   An image of RGBA bytes that drawings are made on, as the software renderer of SDL3 makes them. A blit takes a
  ///   part of a source image to a rectangle of the canvas with the nearest pixel, flipped as the blit says, multiplied
  ///   by its color (the color mod of the texture: 255 leaves a channel as it is) and by its opacity (the alpha mod),
  ///   and blended on what is there with the alpha of the source (SDL_BLENDMODE_BLEND). The rectangles are cut to
  ///   integers as SDL does ((int) of each float), so a drawing is the same as the real renderer
  /// </summary>
  TWarImageBlitter = class
  strict private
    FWidth: Integer;
    FHeight: Integer;
    FPixels: TBytes;
    procedure BlendPixel(AOffset: Integer; ARed, AGreen, ABlue, AAlpha: Integer); inline;
    procedure BlendLinePixel(AOffset: Integer; const AColor: TWarRgba); inline;
    procedure BlendPacked(AOffset: Integer; ARed, AGreen, ABlue, AAlpha: Cardinal);
    procedure BlendSum(AOffset: Integer; ARed, AGreen, ABlue, AAlpha: Integer);
    procedure DrawLineHorizontal(AX1, AX2, AY: Integer; const AColor: TWarRgba);
    procedure DrawLineVertical(AX, AY1, AY2: Integer; const AColor: TWarRgba);
  public
    /// <summary>A transparent canvas of AWidth x AHeight pixels</summary>
    constructor Create(AWidth, AHeight: Integer);
    /// <summary>Every pixel to the color (SDL_RenderClear)</summary>
    procedure Clear(const AColor: TWarRgba);
    /// <summary>Draws one blit from the source (Width * Height * 4 bytes); EWarException if the part is outside the source</summary>
    procedure Draw(const ASource: TWarImage; const ABlit: TWarBlit);
    /// <summary>SDL_RenderFillRect with the blend mode SDL_BLENDMODE_BLEND (wr_fillRect)</summary>
    procedure FillRect(const ARect: TWarRectF; const AColor: TWarRgba);
    /// <summary>SDL_RenderRect with the blend mode SDL_BLENDMODE_BLEND (wr_strokeRect): one pixel of outline</summary>
    procedure StrokeRect(const ARect: TWarRectF; const AColor: TWarRgba);
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    /// <summary>The pixels, row by row, R G B A</summary>
    property Pixels: TBytes read FPixels;
  end;

implementation

{ TWarImageBlitter }

constructor TWarImageBlitter.Create(AWidth, AHeight: Integer);
begin
  inherited Create;
  FWidth := AWidth;
  FHeight := AHeight;
  SetLength(FPixels, AWidth * AHeight * WAR_PIXEL_SIZE);
end;

procedure TWarImageBlitter.Clear(const AColor: TWarRgba);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FWidth * FHeight - 1 do
  begin
    FPixels[LIndex * 4] := AColor.R;
    FPixels[LIndex * 4 + 1] := AColor.G;
    FPixels[LIndex * 4 + 2] := AColor.B;
    FPixels[LIndex * 4 + 3] := AColor.A;
  end;
end;

procedure TWarImageBlitter.BlendPixel(AOffset: Integer; ARed, AGreen, ABlue, AAlpha: Integer);
var
  LInverse: Integer;
begin
  // SDL_Blit_Slow / SDL_BlendFillRect: every product is divided by 255 and cut on its own
  LInverse := 255 - AAlpha;
  FPixels[AOffset] := Byte((ARed * AAlpha) div 255 + (FPixels[AOffset] * LInverse) div 255);
  FPixels[AOffset + 1] := Byte((AGreen * AAlpha) div 255 + (FPixels[AOffset + 1] * LInverse) div 255);
  FPixels[AOffset + 2] := Byte((ABlue * AAlpha) div 255 + (FPixels[AOffset + 2] * LInverse) div 255);
  FPixels[AOffset + 3] := Byte(AAlpha + (FPixels[AOffset + 3] * LInverse) div 255);
end;

procedure TWarImageBlitter.BlendPacked(AOffset: Integer; ARed, AGreen, ABlue, AAlpha: Cardinal);
var
  LSourceRedBlue: Cardinal;
  LDestRedBlue: Cardinal;
  LSourceGreen: Cardinal;
  LDestGreen: Cardinal;
  LDestAlpha: Cardinal;
begin
  // BlitRGBtoRGBPixelAlpha of SDL_blit_A.c (no color or alpha mod): red and blue are calculated together in one word
  // and the products are divided by 256, so the result is not the one of the generic blit; opaque pixels are copied
  // (the alpha of the canvas is kept) and transparent ones skipped
  if AAlpha = 0 then
    Exit;
  if AAlpha = 255 then
  begin
    FPixels[AOffset] := ARed;
    FPixels[AOffset + 1] := AGreen;
    FPixels[AOffset + 2] := ABlue;
    Exit;
  end;
  LDestAlpha := FPixels[AOffset + 3];
  LSourceRedBlue := ARed or (ABlue shl 16);
  LDestRedBlue := FPixels[AOffset] or (Cardinal(FPixels[AOffset + 2]) shl 16);
  LDestRedBlue := (LDestRedBlue + (((LSourceRedBlue - LDestRedBlue) * AAlpha) shr 8)) and $00FF00FF;
  LSourceGreen := AGreen shl 8;
  LDestGreen := Cardinal(FPixels[AOffset + 1]) shl 8;
  LDestGreen := (LDestGreen + (((LSourceGreen - LDestGreen) * AAlpha) shr 8)) and $0000FF00;
  LDestAlpha := AAlpha + (LDestAlpha * (255 - AAlpha)) div 255;
  FPixels[AOffset] := Byte(LDestRedBlue);
  FPixels[AOffset + 1] := Byte(LDestGreen shr 8);
  FPixels[AOffset + 2] := Byte(LDestRedBlue shr 16);
  FPixels[AOffset + 3] := Byte(LDestAlpha);
end;

procedure TWarImageBlitter.BlendSum(AOffset: Integer; ARed, AGreen, ABlue, AAlpha: Integer);
var
  LInverse: Integer;
begin
  // the copy of a flipped picture: every channel is one division of the sum
  LInverse := 255 - AAlpha;
  FPixels[AOffset] := Byte((ARed * AAlpha + FPixels[AOffset] * LInverse) div 255);
  FPixels[AOffset + 1] := Byte((AGreen * AAlpha + FPixels[AOffset + 1] * LInverse) div 255);
  FPixels[AOffset + 2] := Byte((ABlue * AAlpha + FPixels[AOffset + 2] * LInverse) div 255);
  FPixels[AOffset + 3] := Byte(AAlpha + (FPixels[AOffset + 3] * LInverse) div 255);
end;

procedure TWarImageBlitter.BlendLinePixel(AOffset: Integer; const AColor: TWarRgba);
var
  LInverse: Integer;
begin
  // SDL_BlendLine: one division of the sum, not the sum of two divisions
  LInverse := 255 - AColor.A;
  FPixels[AOffset] := Byte((AColor.R * AColor.A + FPixels[AOffset] * LInverse) div 255);
  FPixels[AOffset + 1] := Byte((AColor.G * AColor.A + FPixels[AOffset + 1] * LInverse) div 255);
  FPixels[AOffset + 2] := Byte((AColor.B * AColor.A + FPixels[AOffset + 2] * LInverse) div 255);
  FPixels[AOffset + 3] := Byte(AColor.A + (FPixels[AOffset + 3] * LInverse) div 255);
end;

procedure TWarImageBlitter.Draw(const ASource: TWarImage; const ABlit: TWarBlit);
var
  LSourceX: Integer;
  LSourceY: Integer;
  LSourceWidth: Integer;
  LSourceHeight: Integer;
  LDestX: Integer;
  LDestY: Integer;
  LDestWidth: Integer;
  LDestHeight: Integer;
  LStepX: Integer;
  LStepY: Integer;
  LX: Integer;
  LY: Integer;
  LRow: Integer;
  LColumn: Integer;
  LSourceRow: Integer;
  LSourceColumn: Integer;
  LSource: Integer;
  LAlpha: Integer;
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
  LPacked: Boolean;
  LFlipped: Boolean;
begin
  if (ABlit.Source.X < 0) or (ABlit.Source.Y < 0) or (ABlit.Source.X + ABlit.Source.Width > ASource.Width) or
    (ABlit.Source.Y + ABlit.Source.Height > ASource.Height) or
    (Length(ASource.Pixels) < ASource.Width * ASource.Height * WAR_PIXEL_SIZE) then
    raise EWarException.CreateFmt(SWarRenderImageSize, [Length(ASource.Pixels), ASource.Width, ASource.Height,
      ASource.Width * ASource.Height * WAR_PIXEL_SIZE]);
  // SW_QueueCopy: (int) of every float
  LSourceX := Trunc(ABlit.Source.X);
  LSourceY := Trunc(ABlit.Source.Y);
  LSourceWidth := Trunc(ABlit.Source.Width);
  LSourceHeight := Trunc(ABlit.Source.Height);
  LDestX := Trunc(ABlit.Destination.X);
  LDestY := Trunc(ABlit.Destination.Y);
  LDestWidth := Trunc(ABlit.Destination.Width);
  LDestHeight := Trunc(ABlit.Destination.Height);
  if (LDestWidth <= 0) or (LDestHeight <= 0) or (LSourceWidth <= 0) or (LSourceHeight <= 0) then
    Exit;
  // without a color or alpha mod SDL picks a blitter by the shape of the copy: a plain 1:1 copy uses the packed blit, a
  // flipped one (a scaled picture is made first and then copied 1:1) the one with one division of the sum, a scaled one
  // the generic blit that modulates and divides every product
  LPacked := False;
  LFlipped := False;
  if (ABlit.Color.A = 255) and (ABlit.Color.R = 255) and (ABlit.Color.G = 255) and (ABlit.Color.B = 255) then
  begin
    LFlipped := ABlit.FlipHorizontal or ABlit.FlipVertical;
    LPacked := (not LFlipped) and (((LSourceWidth = LDestWidth) and (LSourceHeight = LDestHeight)) or (LDestX < 0) or
      (LDestY < 0) or (LDestX + LDestWidth > FWidth) or (LDestY + LDestHeight > FHeight));
  end;
  // the nearest scale of SDL_Blit_Slow: 16.16 steps starting in the middle of the first pixel
  LStepX := (LSourceWidth shl 16) div LDestWidth;
  LStepY := (LSourceHeight shl 16) div LDestHeight;
  for LRow := 0 to LDestHeight - 1 do
  begin
    LY := LDestY + LRow;
    if (LY < 0) or (LY >= FHeight) then
      Continue;
    if ABlit.FlipVertical then
      LSourceRow := ((LDestHeight - 1 - LRow) * LStepY + LStepY div 2) shr 16
    else
      LSourceRow := (LRow * LStepY + LStepY div 2) shr 16;
    for LColumn := 0 to LDestWidth - 1 do
    begin
      LX := LDestX + LColumn;
      if (LX < 0) or (LX >= FWidth) then
        Continue;
      if ABlit.FlipHorizontal then
        LSourceColumn := ((LDestWidth - 1 - LColumn) * LStepX + LStepX div 2) shr 16
      else
        LSourceColumn := (LColumn * LStepX + LStepX div 2) shr 16;
      LSource := ((LSourceY + LSourceRow) * ASource.Width + LSourceX + LSourceColumn) * WAR_PIXEL_SIZE;
      if LPacked then
      begin
        BlendPacked((LY * FWidth + LX) * WAR_PIXEL_SIZE, ASource.Pixels[LSource], ASource.Pixels[LSource + 1],
          ASource.Pixels[LSource + 2], ASource.Pixels[LSource + 3]);
        Continue;
      end;
      if LFlipped then
      begin
        BlendSum((LY * FWidth + LX) * WAR_PIXEL_SIZE, ASource.Pixels[LSource], ASource.Pixels[LSource + 1],
          ASource.Pixels[LSource + 2], ASource.Pixels[LSource + 3]);
        Continue;
      end;
      LAlpha := (ASource.Pixels[LSource + 3] * ABlit.Color.A) div 255;
      LRed := (ASource.Pixels[LSource] * ABlit.Color.R) div 255;
      LGreen := (ASource.Pixels[LSource + 1] * ABlit.Color.G) div 255;
      LBlue := (ASource.Pixels[LSource + 2] * ABlit.Color.B) div 255;
      BlendPixel((LY * FWidth + LX) * WAR_PIXEL_SIZE, LRed, LGreen, LBlue, LAlpha);
    end;
  end;
end;

procedure TWarImageBlitter.FillRect(const ARect: TWarRectF; const AColor: TWarRgba);
var
  LX: Integer;
  LY: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LColumn: Integer;
  LRow: Integer;
begin
  LX := Trunc(ARect.X);
  LY := Trunc(ARect.Y);
  LWidth := Trunc(ARect.Width);
  LHeight := Trunc(ARect.Height);
  for LRow := Max(LY, 0) to Min(LY + LHeight, FHeight) - 1 do
    for LColumn := Max(LX, 0) to Min(LX + LWidth, FWidth) - 1 do
      BlendPixel((LRow * FWidth + LColumn) * WAR_PIXEL_SIZE, AColor.R, AColor.G, AColor.B, AColor.A);
end;

procedure TWarImageBlitter.DrawLineHorizontal(AX1, AX2, AY: Integer; const AColor: TWarRgba);
var
  LColumn: Integer;
begin
  if (AY < 0) or (AY >= FHeight) then
    Exit;
  for LColumn := Max(Min(AX1, AX2), 0) to Min(Max(AX1, AX2), FWidth - 1) do
    BlendLinePixel((AY * FWidth + LColumn) * WAR_PIXEL_SIZE, AColor);
end;

procedure TWarImageBlitter.DrawLineVertical(AX, AY1, AY2: Integer; const AColor: TWarRgba);
var
  LRow: Integer;
begin
  if (AX < 0) or (AX >= FWidth) then
    Exit;
  for LRow := Max(Min(AY1, AY2), 0) to Min(Max(AY1, AY2), FHeight - 1) do
    BlendLinePixel((LRow * FWidth + AX) * WAR_PIXEL_SIZE, AColor);
end;

procedure TWarImageBlitter.StrokeRect(const ARect: TWarRectF; const AColor: TWarRgba);
var
  LRight: Single;
  LBottom: Single;
  LX0: Integer;
  LY0: Integer;
  LX1: Integer;
  LY1: Integer;
begin
  // SDL_RenderRect draws the five points x, x + w - 1, y, y + h - 1 as a line strip; each end is cut to an int
  LRight := ARect.X + ARect.Width;
  LRight := LRight - 1;
  LBottom := ARect.Y + ARect.Height;
  LBottom := LBottom - 1;
  LX0 := Floor(ARect.X);
  LY0 := Floor(ARect.Y);
  LX1 := Floor(LRight);
  LY1 := Floor(LBottom);
  // every pixel of the outline is blended once (a rectangle of 1 or 0 pixels is drawn several times by SDL: not kept,
  // nobody in the game draws a translucent outline)
  if (LX1 < LX0) or (LY1 < LY0) then
  begin
    // a rectangle with no area (the one that the mouse drags before it moves): the line strip still goes from corner to
    // corner, backwards, so a small square of pixels around the corner is drawn (SDL_RenderLines of the five points)
    DrawLineHorizontal(Min(LX0, LX1), Max(LX0, LX1), LY0, AColor);
    DrawLineVertical(LX1, Min(LY0, LY1), Max(LY0, LY1), AColor);
    DrawLineHorizontal(Min(LX0, LX1), Max(LX0, LX1), LY1, AColor);
    DrawLineVertical(LX0, Min(LY0, LY1), Max(LY0, LY1), AColor);
    Exit;
  end;
  DrawLineHorizontal(LX0, LX1, LY0, AColor);
  if LY1 > LY0 then
    DrawLineHorizontal(LX0, LX1, LY1, AColor);
  if LY1 - LY0 > 1 then
  begin
    DrawLineVertical(LX0, LY0 + 1, LY1 - 1, AColor);
    if LX1 > LX0 then
      DrawLineVertical(LX1, LY0 + 1, LY1 - 1, AColor);
  end;
end;

end.
