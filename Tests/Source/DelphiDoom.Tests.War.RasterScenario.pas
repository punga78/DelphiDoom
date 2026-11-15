unit DelphiDoom.Tests.War.RasterScenario;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Graphics.Types, DelphiDoom.War.Render.Types, DelphiDoom.War.Render.Blitter;

type
  /// <summary>
  ///   The scenarios of Tools\Verifica\197\sdl_raster_ref.c (the software renderer of the real SDL3), written a second
  ///   time: the same LCG and the same order of draws, every random number drawn in its own statement. Mode bits: 1 =
  ///   partial alpha in the textures, 2 = all inside the screen, 4 = integer positions and sizes, 8 = no flips,
  ///   16 = no scaling
  /// </summary>
  TRasterScenario = class
  strict private
    FState: Cardinal;
    function Next(AModulo: Cardinal): Integer;
    class function Fraction(AValue, ADivisor: Integer): Single; static;
  public
    /// <summary>Runs the scenario of the seed and mode on the canvas, that the caller owns</summary>
    function Run(ASeed: Cardinal; AMode: Integer): TWarImageBlitter;
    /// <summary>The hash of the scenario as sdl_raster_ref.exe prints it: per row FNV-1a, folded as h = row xor (h * 31)</summary>
    class function Hash(const ACanvas: TWarImageBlitter): Cardinal; static;
  end;

implementation

{ TRasterScenario }

function TRasterScenario.Next(AModulo: Cardinal): Integer;
begin
  FState := FState * 1664525 + 1013904223;
  if AModulo = 0 then
    Result := 0
  else
    Result := Integer((FState shr 8) mod AModulo);
end;

class function TRasterScenario.Fraction(AValue, ADivisor: Integer): Single;
begin
  Result := Single(AValue) / Single(ADivisor);
end;

function TRasterScenario.Run(ASeed: Cardinal; AMode: Integer): TWarImageBlitter;
type
  TTexture = record
    Image: TWarImage;
  end;
var
  LTextures: array[0..2] of TTexture;
  LColor: TWarRgba;
  LIndex: Integer;
  LPixel: Integer;
  LAlpha: Integer;
  LQuery: Integer;
  LOperation: Integer;
  LKind: Integer;
  LTextureIndex: Integer;
  LSourceX: Integer;
  LSourceY: Integer;
  LSourceWidth: Integer;
  LSourceHeight: Integer;
  LFractionIndex: Integer;
  LSource: TWarRectF;
  LDest: TWarRectF;
  LDestX: Integer;
  LDestY: Integer;
  LMode: Integer;
  LRandomWidth: Integer;
  LRandomHeight: Integer;
  LAlphaMod: Integer;
  LBlit: TWarBlit;
  LFlip: Integer;
  LRectX: Integer;
  LRectY: Integer;
  LRectWidth: Integer;
  LRectHeight: Integer;
  LRect: TWarRectF;
  LSum: Single;
begin
  Result := TWarImageBlitter.Create(320, 200);
  FState := ASeed * 2654435761 + 12345;
  LColor.R := Byte(Next(256));
  LColor.G := Byte(Next(256));
  LColor.B := Byte(Next(256));
  LColor.A := 255;
  Result.Clear(LColor);

  for LIndex := 0 to 2 do
  begin
    LTextures[LIndex].Image.Width := 1 + Next(20);
    LTextures[LIndex].Image.Height := 1 + Next(20);
    SetLength(LTextures[LIndex].Image.Pixels, LTextures[LIndex].Image.Width * LTextures[LIndex].Image.Height * 4);
    for LPixel := 0 to LTextures[LIndex].Image.Width * LTextures[LIndex].Image.Height - 1 do
    begin
      LQuery := Next(100);
      if LQuery < 60 then
        LAlpha := 255
      else if (AMode and 1) = 0 then
        LAlpha := 0
      else
      begin
        LQuery := Next(100);
        if LQuery < 60 then
          LAlpha := 0
        else
          LAlpha := Next(256);
      end;
      LTextures[LIndex].Image.Pixels[LPixel * 4] := Byte(Next(256));
      LTextures[LIndex].Image.Pixels[LPixel * 4 + 1] := Byte(Next(256));
      LTextures[LIndex].Image.Pixels[LPixel * 4 + 2] := Byte(Next(256));
      LTextures[LIndex].Image.Pixels[LPixel * 4 + 3] := Byte(LAlpha);
    end;
  end;

  for LOperation := 0 to 23 do
  begin
    LKind := Next(10);
    if LKind < 6 then
    begin
      LTextureIndex := Next(3);
      LSourceX := Next(LTextures[LTextureIndex].Image.Width);
      LSourceY := Next(LTextures[LTextureIndex].Image.Height);
      LSourceWidth := 1 + Next(LTextures[LTextureIndex].Image.Width - LSourceX);
      LSourceHeight := 1 + Next(LTextures[LTextureIndex].Image.Height - LSourceY);
      LSource.X := LSourceX;
      LSource.Y := LSourceY;
      LSource.Width := LSourceWidth;
      LSource.Height := LSourceHeight;
      if Next(10) = 0 then
      begin
        LFractionIndex := Next(4);
        LSource.X := Fraction(LSourceX * 4 + LFractionIndex, 4);
        LSum := LSource.X + LSource.Width;
        if LSum > LTextures[LTextureIndex].Image.Width then
          LSource.X := LSourceX;
      end;
      LDestX := Next(370 * 8);
      LDestY := Next(240 * 8);
      LDest.X := Fraction(LDestX - 40 * 8, 8);
      LDest.Y := Fraction(LDestY - 30 * 8, 8);
      LMode := Next(8);
      if LMode < 4 then
      begin
        LDest.Width := LSourceWidth;
        LDest.Height := LSourceHeight;
      end
      else if LMode = 4 then
      begin
        LDest.Width := LSourceWidth * 2;
        LDest.Height := LSourceHeight * 2;
      end
      else if LMode = 5 then
      begin
        LDest.Width := LSourceWidth * 3;
        LDest.Height := LSourceHeight * 3;
      end
      else if LMode = 6 then
      begin
        LDest.Width := Fraction(LSourceWidth * 5, 2);
        LDest.Height := Fraction(LSourceHeight * 3, 2);
      end
      else
      begin
        LRandomWidth := Next(120);
        LRandomHeight := Next(120);
        LDest.Width := Fraction(1 + LRandomWidth, 4);
        LDest.Height := Fraction(1 + LRandomHeight, 4);
      end;
      if Next(4) = 0 then
      begin
        LDest.X := Trunc(LDest.X);
        LDest.Y := Trunc(LDest.Y);
      end;
      if (AMode and 2) <> 0 then
      begin
        LDest.X := Fraction(LDestX mod (250 * 8), 8);
        LDest.Y := Fraction(LDestY mod (130 * 8), 8);
      end;
      if (AMode and 4) <> 0 then
      begin
        LDest.X := Trunc(LDest.X);
        LDest.Y := Trunc(LDest.Y);
        LDest.Width := Trunc(LDest.Width);
        LDest.Height := Trunc(LDest.Height);
        if LDest.Width < 1 then
          LDest.Width := 1;
        if LDest.Height < 1 then
          LDest.Height := 1;
      end;
      if (AMode and 16) <> 0 then
      begin
        LDest.Width := LSourceWidth;
        LDest.Height := LSourceHeight;
      end;
      LQuery := Next(10);
      if LQuery < 5 then
        LAlphaMod := 255
      else if Next(2) <> 0 then
        LAlphaMod := 127
      else
        LAlphaMod := Next(256);
      if Next(10) < 6 then
      begin
        LBlit.Color.R := 255;
        LBlit.Color.G := 255;
        LBlit.Color.B := 255;
      end
      else
      begin
        LBlit.Color.R := Byte(Next(256));
        LBlit.Color.G := Byte(Next(256));
        LBlit.Color.B := Byte(Next(256));
      end;
      LBlit.Color.A := Byte(LAlphaMod);
      LFlip := Next(4);
      LBlit.Source := LSource;
      LBlit.Destination := LDest;
      if ((AMode and 8) <> 0) or ((LKind < 3) and (LFlip = 0)) then
      begin
        LBlit.FlipHorizontal := False;
        LBlit.FlipVertical := False;
      end
      else
      begin
        LBlit.FlipHorizontal := (LFlip and 1) <> 0;
        LBlit.FlipVertical := (LFlip and 2) <> 0;
      end;
      if (AMode and 64) = 0 then
        Result.Draw(LTextures[LTextureIndex].Image, LBlit);
    end
    else
    begin
      LColor.R := Byte(Next(256));
      LColor.G := Byte(Next(256));
      LColor.B := Byte(Next(256));
      if Next(2) <> 0 then
        LColor.A := 255
      else
        LColor.A := Byte(Next(256));
      LRectX := Next(340 * 4);
      LRectY := Next(220 * 4);
      LRectWidth := Next(100 * 4);
      LRectHeight := Next(60 * 4);
      LRect.X := Fraction(LRectX - 10 * 4, 4);
      LRect.Y := Fraction(LRectY - 10 * 4, 4);
      LRect.Width := Fraction(LRectWidth, 4);
      LRect.Height := Fraction(LRectHeight, 4);
      if (AMode and 2) <> 0 then
      begin
        LRect.X := Fraction(LRectX mod (250 * 4), 4);
        LRect.Y := Fraction(LRectY mod (150 * 4), 4);
      end;
      if (AMode and 4) <> 0 then
      begin
        LRect.X := Trunc(LRect.X);
        LRect.Y := Trunc(LRect.Y);
        LRect.Width := Trunc(LRect.Width);
        LRect.Height := Trunc(LRect.Height);
      end;
      if LKind >= 8 then
      begin
        if LRect.Width < 2 then
          LRect.Width := 2;
        if LRect.Height < 2 then
          LRect.Height := 2;
      end;
      if GetEnvironmentVariable('RTRACE') <> '' then
        Writeln(ErrOutput, Format('K%d r %.4f %.4f %.4f %.4f c %d,%d,%d,%d', [LKind, LRect.X, LRect.Y, LRect.Width, LRect.Height,
          LColor.R, LColor.G, LColor.B, LColor.A], TFormatSettings.Invariant));
      if (AMode and 32) = 0 then
      begin
        if LKind < 8 then
          Result.FillRect(LRect, LColor)
        else
          Result.StrokeRect(LRect, LColor);
      end;
    end;
  end;
end;

class function TRasterScenario.Hash(const ACanvas: TWarImageBlitter): Cardinal;
var
  LRow: Integer;
  LColumn: Integer;
  LRowHash: Cardinal;
begin
  Result := 2166136261;
  for LRow := 0 to ACanvas.Height - 1 do
  begin
    LRowHash := 2166136261;
    for LColumn := 0 to ACanvas.Width * 4 - 1 do
      LRowHash := (LRowHash xor ACanvas.Pixels[LRow * ACanvas.Width * 4 + LColumn]) * 16777619;
    Result := LRowHash xor (Result * 31);
  end;
end;

end.
