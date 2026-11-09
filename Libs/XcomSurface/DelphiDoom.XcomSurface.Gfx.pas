{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - the SDL_gfx primitives that Surface uses  }
{  (lineColor, filledCircleColor, filledPolygonColor, texturedPolygon,          }
{  stringColor) on 8 bit surfaces                                               }
{  Port of the parts of SDL_gfx 2.0.26 (zlib license, Andreas Schiffler) that   }
{  OpenXcom calls; derived from OpenXcom (the OpenXcom Developers), GPL v3 or   }
{  later: see Libs\XcomFormats\README.md for the license of this unit           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.Gfx;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.XcomSurface.Types,
  DelphiDoom.XcomSurface.Surface;

type
  /// <summary>
  ///   Surface::drawLine, drawCircle, drawPolygon, drawTexturedPolygon and drawString: the primitives of SDL_gfx on a
  ///   surface of 8 bits whose clip rectangle is the whole surface. The color is an index of the palette of the
  ///   surface, that OpenXcom turns into 0xRRGGBBFF (Palette::getRGBA); SDL_gfx then takes the palette color that
  ///   is the nearest to that RGB (SDL_MapRGBA, so a color that the palette repeats is drawn with the first
  ///   one). Positions are signed 16 bit like the Sint16 of the C++ and wrap the same way. Cases where the C++ is
  ///   undefined (a float that does not fit a Sint16 in the clipping of a line, a sum of the scan of a polygon
  ///   that overflows 32 bits, a texture with no pixels) are EXcomSurfaceException
  /// </summary>
  TXcomGfx = class
  strict private
    class function Narrow(AValue: Integer): SmallInt; static; inline;
    class function MapColor(ATarget: TXcomSurface; AColor: Byte): Byte; static;
    class function ShiftRight(AValue, ABits: Integer): Integer; static; inline;
    class function FloatToSmall(AValue: Single): SmallInt; static;
    class function ClipLine(ATarget: TXcomSurface; var AX1, AY1, AX2, AY2: SmallInt): Boolean; static;
    class procedure Pixel(ATarget: TXcomSurface; AX, AY: SmallInt; AMapped: Byte); static;
    class procedure HLine(ATarget: TXcomSurface; AX1, AX2, AY: SmallInt; AMapped: Byte); static;
    class procedure VLine(ATarget: TXcomSurface; AX, AY1, AY2: SmallInt; AMapped: Byte); static;
    class procedure HLineTextured(ATarget: TXcomSurface; AX1, AX2, AY: SmallInt; ATexture: TXcomSurface;
      ATextureDx, ATextureDy: Integer); static;
    class procedure ScanPolygon(ATarget: TXcomSurface; const AX, AY: array of SmallInt; AMapped: Byte;
      ATexture: TXcomSurface; ATextureDx, ATextureDy: Integer); static;
    class procedure Character(ATarget: TXcomSurface; AX, AY: SmallInt; AChar: Byte; AColor: Byte;
      const ATable: array of Byte); static;
  public
    /// <summary>lineColor: a line from (AX1, AY1) to (AX2, AY2), both ends included</summary>
    class procedure DrawLine(ATarget: TXcomSurface; AX1, AY1, AX2, AY2: Integer; AColor: Byte); static;
    /// <summary>filledCircleColor; a negative radius draws nothing</summary>
    class procedure DrawCircle(ATarget: TXcomSurface; AX, AY, ARadius: Integer; AColor: Byte); static;
    /// <summary>filledPolygonColor of the points (AX[i], AY[i]); fewer than 3 points draw nothing</summary>
    class procedure DrawPolygon(ATarget: TXcomSurface; const AX, AY: array of SmallInt; AColor: Byte); static;
    /// <summary>
    ///   texturedPolygon: the polygon filled with ATexture (index 0 is transparent), that is repeated and moved
    ///   by (ADx, ADy) relative to the screen
    /// </summary>
    class procedure DrawTexturedPolygon(ATarget: TXcomSurface; const AX, AY: array of SmallInt;
      ATexture: TXcomSurface; ADx, ADy: Integer); static;
    /// <summary>
    ///   stringColor: the bytes of AText (up to the first 0) with the font of 8 x 8 pixels of SDL_gfx, 8 pixels
    ///   apart. A character is drawn as a 32 bit picture with alpha and SDL blits it on the 8 bit surface with
    ///   BlitNto1PixelAlpha: the color that lands on the surface is the one of a 3-3-2 table (SDL_DitherColors)
    ///   searched in the palette, not the nearest one to the color
    /// </summary>
    class procedure DrawString(ATarget: TXcomSurface; AX, AY: Integer; const AText: RawByteString;
      AColor: Byte); static;
  end;

implementation

uses
  System.Generics.Collections, System.Generics.Defaults, DelphiDoom.XcomSurface.Sdl,
  DelphiDoom.XcomSurface.GfxFont;

resourcestring
  SXcomGfxFloatRange = 'XcomGfx: the clipping of the line gives %s, that does not fit a signed 16 bit number';
  SXcomGfxScanOverflow = 'XcomGfx: the scan of the polygon overflows 32 bits';
  SXcomGfxOddCrossings = 'XcomGfx: the scan line %d of the polygon crosses %d edges';
  SXcomGfxTextureEmpty = 'XcomGfx: the texture has no pixels';

{ TXcomGfx }

class function TXcomGfx.Narrow(AValue: Integer): SmallInt;
begin
  Result := SmallInt(AValue and $FFFF);
end;

class function TXcomGfx.MapColor(ATarget: TXcomSurface; AColor: Byte): Byte;
var
  LColor: TXcomColor;
begin
  LColor := ATarget.Palette.Colors[AColor];
  Result := TXcomSdl.FindColor(ATarget.Palette, LColor.Red, LColor.Green, LColor.Blue);
end;

class function TXcomGfx.ShiftRight(AValue, ABits: Integer): Integer;
begin
  // the arithmetic shift of the C++ on a negative number
  if AValue >= 0 then
    Result := AValue shr ABits
  else
    Result := not ((not AValue) shr ABits);
end;

class function TXcomGfx.FloatToSmall(AValue: Single): SmallInt;
begin
  if (AValue >= 32768.0) or (AValue <= -32769.0) or (AValue <> AValue) then
    raise EXcomSurfaceException.CreateFmt(SXcomGfxFloatRange, [FloatToStr(AValue)]);
  Result := SmallInt(Trunc(AValue));
end;

class procedure TXcomGfx.Pixel(ATarget: TXcomSurface; AX, AY: SmallInt; AMapped: Byte);
begin
  if (AX >= 0) and (AX < ATarget.Width) and (AY >= 0) and (AY < ATarget.Height) then
    ATarget.PixelPointer(AX, AY)^ := AMapped;
end;

class procedure TXcomGfx.HLine(ATarget: TXcomSurface; AX1, AX2, AY: SmallInt; AMapped: Byte);
var
  LTemporary: SmallInt;
begin
  if (ATarget.Width = 0) or (ATarget.Height = 0) then
    Exit;
  if AX1 > AX2 then
  begin
    LTemporary := AX1;
    AX1 := AX2;
    AX2 := LTemporary;
  end;
  if AX2 < 0 then
    Exit;
  if AX1 > ATarget.Width - 1 then
    Exit;
  if (AY < 0) or (AY > ATarget.Height - 1) then
    Exit;
  if AX1 < 0 then
    AX1 := 0;
  if AX2 > ATarget.Width - 1 then
    AX2 := ATarget.Width - 1;
  FillChar(ATarget.PixelPointer(AX1, AY)^, AX2 - AX1 + 1, AMapped);
end;

class procedure TXcomGfx.VLine(ATarget: TXcomSurface; AX, AY1, AY2: SmallInt; AMapped: Byte);
var
  LTemporary: SmallInt;
  LY: Integer;
begin
  if (ATarget.Width = 0) or (ATarget.Height = 0) then
    Exit;
  if AY1 > AY2 then
  begin
    LTemporary := AY1;
    AY1 := AY2;
    AY2 := LTemporary;
  end;
  if (AX < 0) or (AX > ATarget.Width - 1) then
    Exit;
  if AY2 < 0 then
    Exit;
  if AY1 > ATarget.Height - 1 then
    Exit;
  if AY1 < 0 then
    AY1 := 0;
  if AY2 > ATarget.Height - 1 then
    AY2 := ATarget.Height - 1;
  for LY := AY1 to AY2 do
    ATarget.PixelPointer(AX, LY)^ := AMapped;
end;

class function TXcomGfx.ClipLine(ATarget: TXcomSurface; var AX1, AY1, AX2, AY2: SmallInt): Boolean;
const
  CLIP_LEFT_EDGE = 1;
  CLIP_RIGHT_EDGE = 2;
  CLIP_BOTTOM_EDGE = 4;
  CLIP_TOP_EDGE = 8;

  function Encode(AX, AY: SmallInt; ALeft, ATop, ARight, ABottom: SmallInt): Integer;
  begin
    Result := 0;
    if AX < ALeft then
      Result := Result or CLIP_LEFT_EDGE
    else if AX > ARight then
      Result := Result or CLIP_RIGHT_EDGE;
    if AY < ATop then
      Result := Result or CLIP_TOP_EDGE
    else if AY > ABottom then
      Result := Result or CLIP_BOTTOM_EDGE;
  end;

var
  LLeft, LRight, LTop, LBottom: SmallInt;
  LCode1, LCode2, LCodeTemporary: Integer;
  LTemporary: SmallInt;
  LSlope: Single;
  LStep: Single;
begin
  LLeft := 0;
  LRight := Narrow(ATarget.Width - 1);
  LTop := 0;
  LBottom := Narrow(ATarget.Height - 1);
  Result := False;
  while True do
  begin
    LCode1 := Encode(AX1, AY1, LLeft, LTop, LRight, LBottom);
    LCode2 := Encode(AX2, AY2, LLeft, LTop, LRight, LBottom);
    if (LCode1 or LCode2) = 0 then
    begin
      Result := True;
      Break;
    end
    else if (LCode1 and LCode2) <> 0 then
      Break
    else
    begin
      if LCode1 = 0 then
      begin
        LTemporary := AX2;
        AX2 := AX1;
        AX1 := LTemporary;
        LTemporary := AY2;
        AY2 := AY1;
        AY1 := LTemporary;
        LCodeTemporary := LCode2;
        LCode2 := LCode1;
        LCode1 := LCodeTemporary;
      end;
      // float of the C++: every operation is rounded to a single
      if AX2 <> AX1 then
      begin
        LStep := AY2 - AY1;
        LSlope := LStep / Single(AX2 - AX1);
      end
      else
        LSlope := 1.0;
      if (LCode1 and CLIP_LEFT_EDGE) <> 0 then
      begin
        LStep := (LLeft - AX1) * LSlope;
        AY1 := Narrow(AY1 + FloatToSmall(LStep));
        AX1 := LLeft;
      end
      else if (LCode1 and CLIP_RIGHT_EDGE) <> 0 then
      begin
        LStep := (LRight - AX1) * LSlope;
        AY1 := Narrow(AY1 + FloatToSmall(LStep));
        AX1 := LRight;
      end
      else if (LCode1 and CLIP_BOTTOM_EDGE) <> 0 then
      begin
        if AX2 <> AX1 then
        begin
          LStep := (LBottom - AY1) / LSlope;
          AX1 := Narrow(AX1 + FloatToSmall(LStep));
        end;
        AY1 := LBottom;
      end
      else if (LCode1 and CLIP_TOP_EDGE) <> 0 then
      begin
        if AX2 <> AX1 then
        begin
          LStep := (LTop - AY1) / LSlope;
          AX1 := Narrow(AX1 + FloatToSmall(LStep));
        end;
        AY1 := LTop;
      end;
    end;
  end;
end;

class procedure TXcomGfx.DrawLine(ATarget: TXcomSurface; AX1, AY1, AX2, AY2: Integer; AColor: Byte);
var
  LX1, LY1, LX2, LY2: SmallInt;
  LMapped: Byte;
  LDx, LDy, LSx, LSy, LPixx, LPixy, LSwap, LX, LY, LOffset: Integer;
  LBase: PByte;
begin
  LX1 := Narrow(AX1);
  LY1 := Narrow(AY1);
  LX2 := Narrow(AX2);
  LY2 := Narrow(AY2);
  LMapped := MapColor(ATarget, AColor);
  if not ClipLine(ATarget, LX1, LY1, LX2, LY2) then
    Exit;
  if LX1 = LX2 then
  begin
    if LY1 < LY2 then
      VLine(ATarget, LX1, LY1, LY2, LMapped)
    else if LY1 > LY2 then
      VLine(ATarget, LX1, LY2, LY1, LMapped)
    else
      Pixel(ATarget, LX1, LY1, LMapped);
    Exit;
  end;
  if LY1 = LY2 then
  begin
    if LX1 < LX2 then
      HLine(ATarget, LX1, LX2, LY1, LMapped)
    else if LX1 > LX2 then
      HLine(ATarget, LX2, LX1, LY1, LMapped);
    Exit;
  end;
  LDx := LX2 - LX1;
  LDy := LY2 - LY1;
  if LDx >= 0 then
    LSx := 1
  else
    LSx := -1;
  if LDy >= 0 then
    LSy := 1
  else
    LSy := -1;
  LDx := LSx * LDx + 1;
  LDy := LSy * LDy + 1;
  LBase := ATarget.PixelPointer(0, 0);
  LOffset := LY1 * ATarget.Width + LX1;
  LPixx := LSx;
  LPixy := ATarget.Width * LSy;
  if LDx < LDy then
  begin
    LSwap := LDx;
    LDx := LDy;
    LDy := LSwap;
    LSwap := LPixx;
    LPixx := LPixy;
    LPixy := LSwap;
  end;
  LX := 0;
  LY := 0;
  while LX < LDx do
  begin
    (LBase + LOffset)^ := LMapped;
    Inc(LY, LDy);
    if LY >= LDx then
    begin
      Dec(LY, LDx);
      Inc(LOffset, LPixy);
    end;
    Inc(LX);
    Inc(LOffset, LPixx);
  end;
end;

class procedure TXcomGfx.DrawCircle(ATarget: TXcomSurface; AX, AY, ARadius: Integer; AColor: Byte);
var
  LX, LY, LRadius: SmallInt;
  LLeft, LRight, LTop, LBottom: SmallInt;
  LX1, LY1, LX2, LY2: SmallInt;
  LCx, LCy, LOcx, LOcy, LDf, LDe, LDse: SmallInt;
  LXpCx, LXmCx, LXpCy, LXmCy, LYpCy, LYmCy, LYpCx, LYmCx: SmallInt;
  LMapped: Byte;
begin
  LX := Narrow(AX);
  LY := Narrow(AY);
  LRadius := Narrow(ARadius);
  LMapped := MapColor(ATarget, AColor);
  if (ATarget.Width = 0) or (ATarget.Height = 0) then
    Exit;
  if LRadius < 0 then
    Exit;
  if LRadius = 0 then
  begin
    Pixel(ATarget, LX, LY, LMapped);
    Exit;
  end;
  LX2 := Narrow(LX + LRadius);
  LLeft := 0;
  if LX2 < LLeft then
    Exit;
  LX1 := Narrow(LX - LRadius);
  LRight := Narrow(ATarget.Width - 1);
  if LX1 > LRight then
    Exit;
  LY2 := Narrow(LY + LRadius);
  LTop := 0;
  if LY2 < LTop then
    Exit;
  LY1 := Narrow(LY - LRadius);
  LBottom := Narrow(ATarget.Height - 1);
  if LY1 > LBottom then
    Exit;
  LCx := 0;
  LCy := LRadius;
  LOcx := -1;
  LOcy := -1;
  LDf := Narrow(1 - LRadius);
  LDe := 3;
  LDse := Narrow(-2 * LRadius + 5);
  repeat
    LXpCx := Narrow(LX + LCx);
    LXmCx := Narrow(LX - LCx);
    LXpCy := Narrow(LX + LCy);
    LXmCy := Narrow(LX - LCy);
    if LOcy <> LCy then
    begin
      if LCy > 0 then
      begin
        LYpCy := Narrow(LY + LCy);
        LYmCy := Narrow(LY - LCy);
        HLine(ATarget, LXmCx, LXpCx, LYpCy, LMapped);
        HLine(ATarget, LXmCx, LXpCx, LYmCy, LMapped);
      end
      else
        HLine(ATarget, LXmCx, LXpCx, LY, LMapped);
      LOcy := LCy;
    end;
    if LOcx <> LCx then
    begin
      if LCx <> LCy then
      begin
        if LCx > 0 then
        begin
          LYpCx := Narrow(LY + LCx);
          LYmCx := Narrow(LY - LCx);
          HLine(ATarget, LXmCy, LXpCy, LYmCx, LMapped);
          HLine(ATarget, LXmCy, LXpCy, LYpCx, LMapped);
        end
        else
          HLine(ATarget, LXmCy, LXpCy, LY, LMapped);
      end;
      LOcx := LCx;
    end;
    if LDf < 0 then
    begin
      LDf := Narrow(LDf + LDe);
      LDe := Narrow(LDe + 2);
      LDse := Narrow(LDse + 2);
    end
    else
    begin
      LDf := Narrow(LDf + LDse);
      LDe := Narrow(LDe + 2);
      LDse := Narrow(LDse + 4);
      LCy := Narrow(LCy - 1);
    end;
    LCx := Narrow(LCx + 1);
  until LCx > LCy;
end;

class procedure TXcomGfx.HLineTextured(ATarget: TXcomSurface; AX1, AX2, AY: SmallInt; ATexture: TXcomSurface;
  ATextureDx, ATextureDy: Integer);
var
  LTemporary: SmallInt;
  LWidth: Integer;
  LWalker, LStartY, LWritten, LWriteWidth: Integer;
  LSource: TXcomRect;

  procedure Copy(ASourceX, ASourceWidth, ADestX: Integer);
  begin
    LSource := TXcomRect.Make(ASourceX, LStartY, ASourceWidth, 1);
    TXcomSdl.BlitKeyed(ATexture.PixelPointer(0, 0), ATexture.Width, ATexture.Height, ATexture.Palette, @LSource,
      ATarget.PixelPointer(0, 0), ATarget.Width, ATarget.Height, ATarget.Palette, ADestX, AY);
  end;

begin
  if (ATarget.Width = 0) or (ATarget.Height = 0) then
    Exit;
  if AX1 > AX2 then
  begin
    LTemporary := AX1;
    AX1 := AX2;
    AX2 := LTemporary;
  end;
  if AX2 < 0 then
    Exit;
  if AX1 > ATarget.Width - 1 then
    Exit;
  if (AY < 0) or (AY > ATarget.Height - 1) then
    Exit;
  if AX1 < 0 then
    AX1 := 0;
  if AX2 > ATarget.Width - 1 then
    AX2 := ATarget.Width - 1;
  LWidth := Narrow(AX2 - AX1 + 1);
  LWalker := (AX1 - ATextureDx) mod ATexture.Width;
  if LWalker < 0 then
    LWalker := ATexture.Width + LWalker;
  LStartY := (AY + ATextureDy) mod ATexture.Height;
  if LStartY < 0 then
    LStartY := ATexture.Height + LStartY;
  if LWidth <= ATexture.Width - LWalker then
    Copy(LWalker, LWidth, AX1)
  else
  begin
    LWritten := ATexture.Width - LWalker;
    Copy(LWalker, LWritten, AX1);
    LWriteWidth := ATexture.Width;
    while LWritten < LWidth do
    begin
      if LWriteWidth >= LWidth - LWritten then
        LWriteWidth := LWidth - LWritten;
      Copy(0, LWriteWidth, AX1 + LWritten);
      Inc(LWritten, LWriteWidth);
    end;
  end;
end;

class procedure TXcomGfx.ScanPolygon(ATarget: TXcomSurface; const AX, AY: array of SmallInt; AMapped: Byte;
  ATexture: TXcomSurface; ATextureDx, ATextureDy: Integer);
var
  LCount, LIndex, LY, LMinY, LMaxY, LInts, LIndex1, LIndex2: Integer;
  LX1, LY1, LX2, LY2, LXa, LXb: Integer;
  LCrossings: TArray<Integer>;
  LValue: Int64;
  LLow, LHigh: Integer;
begin
  LCount := Length(AX);
  LMinY := AY[0];
  LMaxY := AY[0];
  for LIndex := 1 to LCount - 1 do
    if AY[LIndex] < LMinY then
      LMinY := AY[LIndex]
    else if AY[LIndex] > LMaxY then
      LMaxY := AY[LIndex];
  SetLength(LCrossings, LCount);
  for LY := LMinY to LMaxY do
  begin
    LInts := 0;
    for LIndex := 0 to LCount - 1 do
    begin
      if LIndex = 0 then
      begin
        LIndex1 := LCount - 1;
        LIndex2 := 0;
      end
      else
      begin
        LIndex1 := LIndex - 1;
        LIndex2 := LIndex;
      end;
      LY1 := AY[LIndex1];
      LY2 := AY[LIndex2];
      if LY1 < LY2 then
      begin
        LX1 := AX[LIndex1];
        LX2 := AX[LIndex2];
      end
      else if LY1 > LY2 then
      begin
        LY2 := AY[LIndex1];
        LY1 := AY[LIndex2];
        LX2 := AX[LIndex1];
        LX1 := AX[LIndex2];
      end
      else
        Continue;
      if ((LY >= LY1) and (LY < LY2)) or ((LY = LMaxY) and (LY > LY1) and (LY <= LY2)) then
      begin
        // the products of the C++ are int: one that does not fit is undefined there
        if Int64(65536) * (LY - LY1) > High(Integer) then
          raise EXcomSurfaceException.Create(SXcomGfxScanOverflow);
        LValue := Int64((65536 * (LY - LY1)) div (LY2 - LY1)) * (LX2 - LX1) + Int64(65536) * LX1;
        if (LValue < Low(Integer)) or (LValue > High(Integer)) then
          raise EXcomSurfaceException.Create(SXcomGfxScanOverflow);
        LCrossings[LInts] := Integer(LValue);
        Inc(LInts);
      end;
    end;
    if LInts > 0 then
      TArray.Sort<Integer>(LCrossings, TComparer<Integer>.Default, 0, LInts);
    if Odd(LInts) then
      raise EXcomSurfaceException.CreateFmt(SXcomGfxOddCrossings, [LY, LInts]);
    // qsort compares with a - b, that overflows when two crossings are 2^31 apart
    if (LInts > 0) and (Int64(LCrossings[LInts - 1]) - LCrossings[0] > High(Integer)) then
      raise EXcomSurfaceException.Create(SXcomGfxScanOverflow);
    LIndex := 0;
    while LIndex < LInts do
    begin
      LLow := LCrossings[LIndex];
      LHigh := LCrossings[LIndex + 1];
      if (LLow = High(Integer)) or (LHigh = Low(Integer)) then
        raise EXcomSurfaceException.Create(SXcomGfxScanOverflow);
      LXa := LLow + 1;
      LXa := ShiftRight(LXa, 16) + ((LXa and 32768) shr 15);
      LXb := LHigh - 1;
      LXb := ShiftRight(LXb, 16) + ((LXb and 32768) shr 15);
      if Assigned(ATexture) then
        HLineTextured(ATarget, Narrow(LXa), Narrow(LXb), Narrow(LY), ATexture, ATextureDx, ATextureDy)
      else
        HLine(ATarget, Narrow(LXa), Narrow(LXb), Narrow(LY), AMapped);
      Inc(LIndex, 2);
    end;
  end;
end;

class procedure TXcomGfx.DrawPolygon(ATarget: TXcomSurface; const AX, AY: array of SmallInt; AColor: Byte);
begin
  if (ATarget.Width = 0) or (ATarget.Height = 0) then
    Exit;
  if (Length(AX) < 3) or (Length(AY) < Length(AX)) then
    Exit;
  ScanPolygon(ATarget, Slice(AX, Length(AX)), Slice(AY, Length(AX)), MapColor(ATarget, AColor), nil, 0, 0);
end;

class procedure TXcomGfx.DrawTexturedPolygon(ATarget: TXcomSurface; const AX, AY: array of SmallInt;
  ATexture: TXcomSurface; ADx, ADy: Integer);
var
  LIndex, LMinX, LMaxX, LMinY, LMaxY: Integer;
begin
  if (ATarget.Width = 0) or (ATarget.Height = 0) then
    Exit;
  if (Length(AX) < 3) or (Length(AY) < Length(AX)) then
    Exit;
  if (ATexture.Width <= 0) or (ATexture.Height <= 0) then
    raise EXcomSurfaceException.Create(SXcomGfxTextureEmpty);
  LMinX := AX[0];
  LMaxX := AX[0];
  LMinY := AY[0];
  LMaxY := AY[0];
  for LIndex := 1 to Length(AX) - 1 do
  begin
    if AY[LIndex] < LMinY then
      LMinY := AY[LIndex]
    else if AY[LIndex] > LMaxY then
      LMaxY := AY[LIndex];
    if AX[LIndex] < LMinX then
      LMinX := AX[LIndex]
    else if AX[LIndex] > LMaxX then
      LMaxX := AX[LIndex];
  end;
  if (LMaxX < 0) or (LMinX > ATarget.Width) then
    Exit;
  if (LMaxY < 0) or (LMinY > ATarget.Height) then
    Exit;
  ScanPolygon(ATarget, Slice(AX, Length(AX)), Slice(AY, Length(AX)), 0, ATexture, ADx, ADy);
end;

class procedure TXcomGfx.Character(ATarget: TXcomSurface; AX, AY: SmallInt; AChar: Byte; AColor: Byte;
  const ATable: array of Byte);
var
  LX2, LY2: SmallInt;
  LClip: TXcomBlitClip;
  LRow, LColumn: Integer;
  LPattern: Byte;
  LDest: PByte;
  LColor: TXcomColor;
  LSourceRed, LSourceGreen, LSourceBlue, LRed, LGreen, LBlue: Integer;

  function Blend(ASource, ADest: Integer): Integer;
  var
    LValue: Integer;
  begin
    // ALPHA_BLEND with an alpha of 255: ((s - d) * 255 + 255) >> 8 + d, kept in a byte
    LValue := (ASource - ADest) * 255 + 255;
    Result := (ShiftRight(LValue, 8) + ADest) and $FF;
  end;

begin
  if (ATarget.Width = 0) or (ATarget.Height = 0) then
    Exit;
  LX2 := Narrow(AX + XCOM_GFX_CHAR_SIZE);
  if LX2 < 0 then
    Exit;
  if AX > ATarget.Width - 1 then
    Exit;
  LY2 := Narrow(AY + XCOM_GFX_CHAR_SIZE);
  if LY2 < 0 then
    Exit;
  if AY > ATarget.Height - 1 then
    Exit;
  if not TXcomSdl.ClipBlit(XCOM_GFX_CHAR_SIZE, XCOM_GFX_CHAR_SIZE, nil, ATarget.Width, ATarget.Height, AX, AY,
    LClip) then
    Exit;
  LColor := ATarget.Palette.Colors[AColor];
  LSourceRed := LColor.Red;
  LSourceGreen := LColor.Green;
  LSourceBlue := LColor.Blue;
  for LRow := 0 to LClip.Height - 1 do
  begin
    LPattern := XCOM_GFX_FONT[AChar * XCOM_GFX_CHAR_SIZE + LClip.SourceY + LRow];
    for LColumn := 0 to LClip.Width - 1 do
    begin
      // BlitNto1PixelAlpha does not skip the pixels with alpha 0: they keep their color but go through the
      // 3-3-2 table too, so the palette color that the table finds replaces the one that was there
      LDest := ATarget.PixelPointer(LClip.DestX + LColumn, LClip.DestY + LRow);
      LColor := ATarget.Palette.Colors[LDest^];
      if (LPattern and ($80 shr (LClip.SourceX + LColumn))) <> 0 then
      begin
        LRed := Blend(LSourceRed, LColor.Red);
        LGreen := Blend(LSourceGreen, LColor.Green);
        LBlue := Blend(LSourceBlue, LColor.Blue);
      end
      else
      begin
        LRed := LColor.Red;
        LGreen := LColor.Green;
        LBlue := LColor.Blue;
      end;
      LDest^ := ATable[((LRed shr 5) shl 5) or ((LGreen shr 5) shl 2) or (LBlue shr 6)];
    end;
  end;
end;
class procedure TXcomGfx.DrawString(ATarget: TXcomSurface; AX, AY: Integer; const AText: RawByteString;
  AColor: Byte);
var
  LTable: array[0..255] of Byte;
  LIndex: Integer;
  LRed, LGreen, LBlue: Integer;
  LCurrentX: SmallInt;
begin
  // the table of SDL_Map1to1(SDL_DitherColors(8), palette of the surface): 3-3-2 color -> palette index
  for LIndex := 0 to 255 do
  begin
    LRed := LIndex and $E0;
    LRed := LRed or (LRed shr 3) or (LRed shr 6);
    LGreen := (LIndex shl 3) and $E0;
    LGreen := LGreen or (LGreen shr 3) or (LGreen shr 6);
    LBlue := LIndex and 3;
    LBlue := LBlue or (LBlue shl 2);
    LBlue := LBlue or (LBlue shl 4);
    LTable[LIndex] := TXcomSdl.FindColor(ATarget.Palette, LRed, LGreen, LBlue);
  end;
  LCurrentX := Narrow(AX);
  for LIndex := 1 to Length(AText) do
  begin
    if AText[LIndex] = #0 then
      Break;
    Character(ATarget, LCurrentX, Narrow(AY), Byte(AText[LIndex]), AColor, LTable);
    LCurrentX := Narrow(LCurrentX + XCOM_GFX_CHAR_SIZE);
  end;
end;

end.
