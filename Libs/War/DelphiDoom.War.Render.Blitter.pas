{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the pixels of a blit                              }
{                                                                              }
{  Port of war1 (acoto87/war1), the use the renderer makes of SDL_RenderTexture }
{  and SDL_RenderTextureRotated (nearest scale, flip, color and alpha mod,     }
{  blend), (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\      }
{  LICENSE-war1.txt). This is an altered version, not the original.            }
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
  ///   An image of RGBA bytes that blits are drawn on. A blit takes a part of a source image to a rectangle of the canvas
  ///   with the nearest pixel (the sprites of the game are set to SDL_SCALEMODE_NEAREST), flipped as the blit says,
  ///   multiplied by its color (the color mod of the texture: 255 leaves a channel as it is) and by its opacity, and
  ///   blended on what is there with the alpha of the source (SDL_BLENDMODE_BLEND). A destination pixel is drawn if
  ///   its center is in the rectangle. The rounding of the products is ours (SDL rounds in its own way): the
  ///   positions and the geometry are the ones of the original, the last bit of a blended color is not promised
  /// </summary>
  TWarImageBlitter = class
  strict private
    FWidth: Integer;
    FHeight: Integer;
    FPixels: TBytes;
    class function Divide255(AValue: Integer): Integer; static;
  public
    /// <summary>A transparent canvas of AWidth x AHeight pixels</summary>
    constructor Create(AWidth, AHeight: Integer);
    /// <summary>Every pixel to the color (SDL_RenderClear)</summary>
    procedure Clear(const AColor: TWarRgba);
    /// <summary>Draws one blit from the source (Width * Height * 4 bytes); EWarException if the part is outside the source</summary>
    procedure Draw(const ASource: TWarImage; const ABlit: TWarBlit);
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

class function TWarImageBlitter.Divide255(AValue: Integer): Integer;
begin
  Result := (AValue + 127) div 255;
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

procedure TWarImageBlitter.Draw(const ASource: TWarImage; const ABlit: TWarBlit);
var
  LFromX: Integer;
  LToX: Integer;
  LFromY: Integer;
  LToY: Integer;
  LX: Integer;
  LY: Integer;
  LU: Double;
  LV: Double;
  LSourceX: Integer;
  LSourceY: Integer;
  LSource: Integer;
  LTarget: Integer;
  LAlpha: Integer;
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
  LDestinationAlpha: Integer;
begin
  if (ABlit.Source.X < 0) or (ABlit.Source.Y < 0) or (ABlit.Source.X + ABlit.Source.Width > ASource.Width) or
    (ABlit.Source.Y + ABlit.Source.Height > ASource.Height) or
    (Length(ASource.Pixels) < ASource.Width * ASource.Height * WAR_PIXEL_SIZE) then
    raise EWarException.CreateFmt(SWarRenderImageSize, [Length(ASource.Pixels), ASource.Width, ASource.Height,
      ASource.Width * ASource.Height * WAR_PIXEL_SIZE]);
  if (ABlit.Destination.Width <= 0) or (ABlit.Destination.Height <= 0) or (ABlit.Source.Width <= 0) or
    (ABlit.Source.Height <= 0) then
    Exit;
  LFromX := Max(0, Ceil(ABlit.Destination.X - 0.5));
  LToX := Min(FWidth - 1, Ceil(ABlit.Destination.X + ABlit.Destination.Width - 0.5) - 1);
  LFromY := Max(0, Ceil(ABlit.Destination.Y - 0.5));
  LToY := Min(FHeight - 1, Ceil(ABlit.Destination.Y + ABlit.Destination.Height - 0.5) - 1);
  for LY := LFromY to LToY do
    for LX := LFromX to LToX do
    begin
      LU := (LX + 0.5 - ABlit.Destination.X) / ABlit.Destination.Width;
      LV := (LY + 0.5 - ABlit.Destination.Y) / ABlit.Destination.Height;
      if ABlit.FlipHorizontal then
        LU := 1 - LU;
      if ABlit.FlipVertical then
        LV := 1 - LV;
      LSourceX := Min(Trunc(ABlit.Source.X + LU * ABlit.Source.Width), Trunc(ABlit.Source.X + ABlit.Source.Width) - 1);
      LSourceY := Min(Trunc(ABlit.Source.Y + LV * ABlit.Source.Height), Trunc(ABlit.Source.Y + ABlit.Source.Height) - 1);
      LSource := (LSourceY * ASource.Width + LSourceX) * WAR_PIXEL_SIZE;
      LTarget := (LY * FWidth + LX) * WAR_PIXEL_SIZE;
      LAlpha := Divide255(ASource.Pixels[LSource + 3] * ABlit.Color.A);
      LRed := Divide255(ASource.Pixels[LSource] * ABlit.Color.R);
      LGreen := Divide255(ASource.Pixels[LSource + 1] * ABlit.Color.G);
      LBlue := Divide255(ASource.Pixels[LSource + 2] * ABlit.Color.B);
      FPixels[LTarget] := Byte(Divide255(LRed * LAlpha + FPixels[LTarget] * (255 - LAlpha)));
      FPixels[LTarget + 1] := Byte(Divide255(LGreen * LAlpha + FPixels[LTarget + 1] * (255 - LAlpha)));
      FPixels[LTarget + 2] := Byte(Divide255(LBlue * LAlpha + FPixels[LTarget + 2] * (255 - LAlpha)));
      LDestinationAlpha := LAlpha + Divide255(FPixels[LTarget + 3] * (255 - LAlpha));
      FPixels[LTarget + 3] := Byte(Min(255, LDestinationAlpha));
    end;
end;

end.
