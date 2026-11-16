{******************************************************************************}
{                                                                              }
{  DelphiDoom: Speed library - a software rasterizer of textured triangles     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The cold part of the 3D of Speed Haste (r_soft3d of the fork, S6): it       }
{  draws the cars of the game once, at the conversion of the data, into the    }
{  pictures that the sprites of the engine show. Never called while playing    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.TriangleRasterizer;

interface

uses
  System.SysUtils;

type
  /// <summary>A vertex on the screen: pixels, depth (the nearer, the smaller) and the point of the texture (0..1, wrapping)</summary>
  TSpeedRasterVertex = record
    X: Single;
    Y: Single;
    Depth: Single;
    U: Single;
    V: Single;
  end;

  /// <summary>
  ///   Draws triangles into an image of palette indexes (one byte a pixel, rows from the top) with a
  ///   depth buffer. The pixels are sampled at their centers
  /// </summary>
  TSpeedTriangleRasterizer = class
  strict private
    FWidth: Integer;
    FHeight: Integer;
    FTransparent: Byte;
    FPixels: TBytes;
    FDepth: TArray<Single>;
  public
    /// <exception cref="EArgumentException">The size is not positive</exception>
    constructor Create(AWidth, AHeight: Integer; ATransparent: Byte);
    /// <summary>Every pixel transparent and as far as possible</summary>
    procedure Clear;
    /// <summary>
    ///   A triangle of a texture: the pixels of the texture (indexes of a palette) go through AColorMap
    ///   (256 bytes: the color of the picture for each index), then through AShadeMap (256 bytes, or
    ///   nil for none: the darker version of each color)
    /// </summary>
    procedure DrawTextured(const A, B, C: TSpeedRasterVertex; const ATexture: TBytes;
      ATextureWidth, ATextureHeight: Integer; const AColorMap, AShadeMap: TBytes);
    /// <summary>A triangle of one color (the index of the picture)</summary>
    procedure DrawFlat(const A, B, C: TSpeedRasterVertex; AColor: Byte);
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Transparent: Byte read FTransparent;
    /// <summary>The image: Width * Height indexes, row after row from the top</summary>
    property Pixels: TBytes read FPixels;
  end;

implementation

uses
  System.Math;

resourcestring
  SSpeedRasterizerSize = 'The size of the picture of the rasterizer must be positive (%d x %d)';

{ TSpeedTriangleRasterizer }

constructor TSpeedTriangleRasterizer.Create(AWidth, AHeight: Integer; ATransparent: Byte);
begin
  inherited Create;
  if (AWidth <= 0) or (AHeight <= 0) then
    raise EArgumentException.CreateFmt(SSpeedRasterizerSize, [AWidth, AHeight]);
  FWidth := AWidth;
  FHeight := AHeight;
  FTransparent := ATransparent;
  SetLength(FPixels, AWidth * AHeight);
  SetLength(FDepth, AWidth * AHeight);
  Clear;
end;

procedure TSpeedTriangleRasterizer.Clear;
var
  LIndex: Integer;
begin
  FillChar(FPixels[0], Length(FPixels), FTransparent);
  for LIndex := 0 to High(FDepth) do
    FDepth[LIndex] := MaxSingle;
end;

procedure TSpeedTriangleRasterizer.DrawTextured(const A, B, C: TSpeedRasterVertex;
  const ATexture: TBytes; ATextureWidth, ATextureHeight: Integer; const AColorMap, AShadeMap: TBytes);
var
  LArea, LW0, LW1, LW2, LDepth, LU, LV: Single;
  LMinX, LMaxX, LMinY, LMaxY, LX, LY, LIndex, LTexelX, LTexelY: Integer;
  LColor: Byte;
begin
  LArea := (B.X - A.X) * (C.Y - A.Y) - (B.Y - A.Y) * (C.X - A.X);
  if Abs(LArea) < 1E-6 then
    Exit;
  LMinX := Max(0, Floor(Min(A.X, Min(B.X, C.X))));
  LMaxX := Min(FWidth - 1, Ceil(Max(A.X, Max(B.X, C.X))));
  LMinY := Max(0, Floor(Min(A.Y, Min(B.Y, C.Y))));
  LMaxY := Min(FHeight - 1, Ceil(Max(A.Y, Max(B.Y, C.Y))));
  for LY := LMinY to LMaxY do
    for LX := LMinX to LMaxX do
    begin
      // the barycentric weights of the center of the pixel
      LW0 := ((B.X - (LX + 0.5)) * (C.Y - (LY + 0.5)) - (B.Y - (LY + 0.5)) * (C.X - (LX + 0.5))) / LArea;
      LW1 := ((C.X - (LX + 0.5)) * (A.Y - (LY + 0.5)) - (C.Y - (LY + 0.5)) * (A.X - (LX + 0.5))) / LArea;
      LW2 := 1 - LW0 - LW1;
      if (LW0 < 0) or (LW1 < 0) or (LW2 < 0) then
        Continue;
      LDepth := LW0 * A.Depth + LW1 * B.Depth + LW2 * C.Depth;
      LIndex := LY * FWidth + LX;
      if LDepth >= FDepth[LIndex] then
        Continue;
      LU := LW0 * A.U + LW1 * B.U + LW2 * C.U;
      LV := LW0 * A.V + LW1 * B.V + LW2 * C.V;
      LU := LU - Floor(LU);
      LV := LV - Floor(LV);
      LTexelX := Min(ATextureWidth - 1, Trunc(LU * ATextureWidth));
      LTexelY := Min(ATextureHeight - 1, Trunc(LV * ATextureHeight));
      LColor := AColorMap[ATexture[LTexelY * ATextureWidth + LTexelX]];
      if Length(AShadeMap) = 256 then
        LColor := AShadeMap[LColor];
      FDepth[LIndex] := LDepth;
      FPixels[LIndex] := LColor;
    end;
end;

procedure TSpeedTriangleRasterizer.DrawFlat(const A, B, C: TSpeedRasterVertex; AColor: Byte);
var
  LArea, LW0, LW1, LW2, LDepth: Single;
  LMinX, LMaxX, LMinY, LMaxY, LX, LY, LIndex: Integer;
begin
  LArea := (B.X - A.X) * (C.Y - A.Y) - (B.Y - A.Y) * (C.X - A.X);
  if Abs(LArea) < 1E-6 then
    Exit;
  LMinX := Max(0, Floor(Min(A.X, Min(B.X, C.X))));
  LMaxX := Min(FWidth - 1, Ceil(Max(A.X, Max(B.X, C.X))));
  LMinY := Max(0, Floor(Min(A.Y, Min(B.Y, C.Y))));
  LMaxY := Min(FHeight - 1, Ceil(Max(A.Y, Max(B.Y, C.Y))));
  for LY := LMinY to LMaxY do
    for LX := LMinX to LMaxX do
    begin
      LW0 := ((B.X - (LX + 0.5)) * (C.Y - (LY + 0.5)) - (B.Y - (LY + 0.5)) * (C.X - (LX + 0.5))) / LArea;
      LW1 := ((C.X - (LX + 0.5)) * (A.Y - (LY + 0.5)) - (C.Y - (LY + 0.5)) * (A.X - (LX + 0.5))) / LArea;
      LW2 := 1 - LW0 - LW1;
      if (LW0 < 0) or (LW1 < 0) or (LW2 < 0) then
        Continue;
      LDepth := LW0 * A.Depth + LW1 * B.Depth + LW2 * C.Depth;
      LIndex := LY * FWidth + LX;
      if LDepth >= FDepth[LIndex] then
        Continue;
      FDepth[LIndex] := LDepth;
      FPixels[LIndex] := AColor;
    end;
end;

end.
