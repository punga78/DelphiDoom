{******************************************************************************}
{                                                                              }
{  DelphiDoom: speed library - TSpeedFontBuilder                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Copyright (C) 1995 by Noriaworks (Speed Haste)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of GenerateFonts (speed_xlat_wad.pas)                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.FontBuilder;

// the noise is made with the wrap around of the integers, as it was in the old code
{$OVERFLOWCHECKS OFF}
{$RANGECHECKS OFF}

interface

uses
  System.SysUtils,
  DelphiDoom.Palette.Intf, DelphiDoom.GameData.Intf, DelphiDoom.Speed.Intf;

type
  /// <summary>
  ///   Makes the fonts of the game as patches: the small one (SFNTcNNN, 8 x 8 pixels) and the big
  ///   one (BFNTcNNN, 16 x 16 pixels, trimmed on the right) for the characters 33 to 127, once for
  ///   each of five colors (c is A to E). The pictures are in the white of the tables and are
  ///   tinted with the color and with a noise, and then matched to the palette of the game
  /// </summary>
  TSpeedFontBuilder = class(TInterfacedObject, ISpeedFontBuilder)
  strict private
    FPatches: IGamePatchBuilder;
    FMatcher: IColorMatcher;
    class function Interpolate(const AFirst, ASecond, AFraction: Double): Double; static;
    class function Noise(const AX, AY: Double): Double; static;
    class function SmoothedNoise(const AX, AY: Double): Double; static;
    class function InterpolatedNoise(const AX, AY: Double): Double; static;
    class function PerlinNoise(AX, AY: Integer): Double; static;
    class function Clamp(AValue: Integer): Integer; static;
    procedure BuildSmallFont(const AColors: TArray<Cardinal>; const AWad: IGameWadComposer);
    procedure BuildBigFont(const AColors: TArray<Cardinal>; const AWad: IGameWadComposer);
  public
    /// <param name="APatches">Makes the patches (the options of Speed)</param>
    /// <param name="AMatcher">Matches the colors to the palette</param>
    constructor Create(const APatches: IGamePatchBuilder; const AMatcher: IColorMatcher);
    procedure Build(const AColors: TArray<Cardinal>; const AWad: IGameWadComposer);
  end;

implementation

uses
  System.Math,
  DelphiDoom.Speed.Names, DelphiDoom.Speed.FontData;

const
  FONT_COLOR_COUNT = 5;
  FONT_COLORS: array[0..FONT_COLOR_COUNT - 1] of Cardinal = ($E2CE4A, $F0F0F0, $0F0F0F, $F00000, $C0C0C0);
  PALETTE_LOW = 16;
  PALETTE_HIGH = 239;
  BIG_FONT_ROW = 1520;
  PERSISTENCE = 0.50;
  LOOP_COUNT = 3;
  VARIATION = 16;

{ TSpeedFontBuilder }

constructor TSpeedFontBuilder.Create(const APatches: IGamePatchBuilder; const AMatcher: IColorMatcher);
begin
  inherited Create;
  if not Assigned(APatches) then
    raise EArgumentNilException.Create('APatches');
  if not Assigned(AMatcher) then
    raise EArgumentNilException.Create('AMatcher');
  FPatches := APatches;
  FMatcher := AMatcher;
end;

class function TSpeedFontBuilder.Clamp(AValue: Integer): Integer;
begin
  if AValue > 255 then
    Result := 255
  else if AValue < 0 then
    Result := 0
  else
    Result := AValue;
end;

class function TSpeedFontBuilder.Interpolate(const AFirst, ASecond, AFraction: Double): Double;
begin
  Result := (1.0 - Cos(Pi * AFraction)) * 0.5;
  Result := AFirst * (1 - Result) + ASecond * Result;
end;

class function TSpeedFontBuilder.Noise(const AX, AY: Double): Double;
var
  LValue: Integer;
begin
  LValue := Trunc(AX + AY * 57);
  LValue := (LValue shl 13) xor LValue;
  Result := (1.0 - ((LValue * (LValue * LValue * $EC4D + $131071F) + $5208DD0D) and $7FFFFFFF) / $40000000);
end;

class function TSpeedFontBuilder.SmoothedNoise(const AX, AY: Double): Double;
var
  LCorners: Double;
  LSides: Double;
  LCenter: Double;
begin
  LCorners := (Noise(AX - 1, AY - 1) + Noise(AX + 1, AY - 1) + Noise(AX - 1, AY + 1) + Noise(AX + 1, AY + 1)) / 16;
  LSides := (Noise(AX - 1, AY) + Noise(AX + 1, AY) + Noise(AX, AY - 1) + Noise(AX, AY + 1)) / 8;
  LCenter := Noise(AX, AY) / 4;
  Result := LCorners + LSides + LCenter;
end;

class function TSpeedFontBuilder.InterpolatedNoise(const AX, AY: Double): Double;
var
  LFirst: Double;
  LSecond: Double;
  LV1: Double;
  LV2: Double;
  LV3: Double;
  LV4: Double;
  LXInt: Double;
  LYInt: Double;
  LXFrac: Double;
  LYFrac: Double;
begin
  LXInt := Int(AX);
  LXFrac := Frac(AX);
  LYInt := Int(AY);
  LYFrac := Frac(AY);

  LV1 := SmoothedNoise(LXInt, LYInt);
  LV2 := SmoothedNoise(LXInt + 1, LYInt);
  LV3 := SmoothedNoise(LXInt, LYInt + 1);
  LV4 := SmoothedNoise(LXInt + 1, LYInt + 1);

  LFirst := Interpolate(LV1, LV2, LXFrac);
  LSecond := Interpolate(LV3, LV4, LXFrac);

  Result := Interpolate(LFirst, LSecond, LYFrac);
end;

class function TSpeedFontBuilder.PerlinNoise(AX, AY: Integer): Double;
var
  LAmplitude: Double;
  LOctave: Integer;
  LFrequency: Integer;
begin
  LFrequency := 1;
  Result := 0.0;
  for LOctave := 0 to LOOP_COUNT - 1 do
  begin
    LAmplitude := Power(PERSISTENCE, LOctave);
    Result := Result + InterpolatedNoise(AX * LFrequency, AY * LFrequency) * LAmplitude;
    LFrequency := LFrequency shl 1;
  end;
  Result := Result * VARIATION;
end;

procedure TSpeedFontBuilder.BuildSmallFont(const AColors: TArray<Cardinal>; const AWad: IGameWadComposer);
var
  LColor: Integer;
  LRed1: Cardinal;
  LGreen1: Cardinal;
  LBlue1: Cardinal;
  LImage: TBytes;
  LChar: Integer;
  LCellX: Integer;
  LCellY: Integer;
  LRow: Integer;
  LColumn: Integer;
  LSource: Integer;
  LPixel: Integer;
  LNoise: Double;
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
  LRgb: Cardinal;
begin
  SetLength(LImage, 8 * 8);
  for LColor := 0 to FONT_COLOR_COUNT - 1 do
  begin
    LRed1 := (FONT_COLORS[LColor] shr 16) and $FF;
    LGreen1 := (FONT_COLORS[LColor] shr 8) and $FF;
    LBlue1 := FONT_COLORS[LColor] and $FF;
    AWad.AddMarker('FN_START');
    for LChar := 33 to 127 do
    begin
      LCellX := (LChar - 31 - 1) mod 16;
      LCellY := (LChar - 31 - 1) div 16;
      for LRow := 0 to 7 do
      begin
        LSource := LCellX * 8 + (LCellY * 8 + LRow) * 128;
        for LColumn := 0 to 7 do
        begin
          LImage[LColumn * 8 + LRow] := SPEED_SMALL_FONT_DATA[LSource];
          Inc(LSource);
        end;
      end;
      for LPixel := 0 to 63 do
        if LImage[LPixel] <> 0 then
        begin
          LNoise := PerlinNoise((LPixel + LCellX * 8) mod 128, (LPixel * LCellY + LCellX * 8) div 128);
          LRed := Clamp(Round(LRed1 * LImage[LPixel] / 256 + LNoise));
          LGreen := Clamp(Round(LGreen1 * LImage[LPixel] / 256 + LNoise));
          LBlue := Clamp(Round(LBlue1 * LImage[LPixel] / 256 + LNoise));
          LRgb := (Cardinal(LRed) shl 16) + (Cardinal(LGreen) shl 8) + Cardinal(LBlue);
          LImage[LPixel] := Byte(FMatcher.FindApproximateIndex(AColors, LRgb, PALETTE_LOW, PALETTE_HIGH));
        end
        else
          LImage[LPixel] := 255;
      AWad.AddLump('SFNT' + Chr(Ord('A') + LColor) + TSpeedNames.ZeroFill(3, LChar),
        FPatches.FromColumns(LImage, 8, 8, False, 0, 0));
    end;
    AWad.AddMarker('FN_END');
  end;
end;

procedure TSpeedFontBuilder.BuildBigFont(const AColors: TArray<Cardinal>; const AWad: IGameWadComposer);
var
  LColor: Integer;
  LRed1: Cardinal;
  LGreen1: Cardinal;
  LBlue1: Cardinal;
  LInput: TBytes;
  LGlyph: TBytes;
  LTrimmed: TBytes;
  LIndex: Integer;
  LNoise: Double;
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
  LRgb: Cardinal;
  LChar: Integer;
  LOffset: Integer;
  LPixel: Integer;
  LRowIndex: Integer;
  LColumnIndex: Integer;
  LLast: Integer;
  LWidth: Integer;
  LTemp: TBytes;
begin
  SetLength(LInput, Length(SPEED_BIG_FONT_DATA));
  SetLength(LGlyph, 16 * 16);
  SetLength(LTemp, 16 * 16);
  for LColor := 0 to FONT_COLOR_COUNT - 1 do
  begin
    LRed1 := (FONT_COLORS[LColor] shr 16) and $FF;
    LGreen1 := (FONT_COLORS[LColor] shr 8) and $FF;
    LBlue1 := FONT_COLORS[LColor] and $FF;
    for LIndex := 0 to High(LInput) do
    begin
      if SPEED_BIG_FONT_DATA[LIndex] = 0 then
        LInput[LIndex] := 255
      else
      begin
        if SPEED_BIG_FONT_DATA[LIndex] = 255 then
          LNoise := PerlinNoise(LIndex mod BIG_FONT_ROW, LIndex div BIG_FONT_ROW)
        else
          LNoise := 0.0;
        LRed := Clamp(Round(LRed1 * SPEED_BIG_FONT_DATA[LIndex] / 256 + LNoise));
        LGreen := Clamp(Round(LGreen1 * SPEED_BIG_FONT_DATA[LIndex] / 256 + LNoise));
        LBlue := Clamp(Round(LBlue1 * SPEED_BIG_FONT_DATA[LIndex] / 256 + LNoise));
        LRgb := (Cardinal(LRed) shl 16) + (Cardinal(LGreen) shl 8) + Cardinal(LBlue);
        LInput[LIndex] := Byte(FMatcher.FindApproximateIndex(AColors, LRgb, PALETTE_LOW, PALETTE_HIGH));
        if AColors[LInput[LIndex]] = 0 then
          LInput[LIndex] := 255;
      end;
    end;

    AWad.AddMarker('FN_START');
    for LChar := 33 to 127 do
    begin
      LOffset := (LChar - 32 - 1) * 16 * 16;
      for LPixel := 0 to 16 * 16 - 1 do
        LGlyph[LPixel] := LInput[LOffset + LPixel];
      // a turn of 90 degrees: the rows of the table are the columns of the patch
      for LRowIndex := 0 to 15 do
        for LColumnIndex := 0 to 15 do
          LTemp[LRowIndex * 16 + LColumnIndex] := LGlyph[LColumnIndex * 16 + LRowIndex];
      LGlyph := Copy(LTemp);
      // the right side of the glyph that is empty is cut
      LLast := 16 * 16 - 1;
      while LLast > 0 do
      begin
        if LGlyph[LLast] <> 255 then
          Break;
        Dec(LLast);
      end;
      if LLast < 14 * 16 then
      begin
        LWidth := (LLast div 16) + 1;
        LTrimmed := Copy(LGlyph, 0, LWidth * 16);
        AWad.AddLump('BFNT' + Chr(Ord('A') + LColor) + TSpeedNames.ZeroFill(3, LChar),
          FPatches.FromColumns(LTrimmed, LWidth, 16, False, 1, 3));
      end
      else
        AWad.AddLump('BFNT' + Chr(Ord('A') + LColor) + TSpeedNames.ZeroFill(3, LChar),
          FPatches.FromColumns(LGlyph, 16, 16, False, 1, 3));
    end;
    AWad.AddMarker('FN_END');
  end;
end;

procedure TSpeedFontBuilder.Build(const AColors: TArray<Cardinal>; const AWad: IGameWadComposer);
begin
  if not Assigned(AWad) then
    raise EArgumentNilException.Create('AWad');
  BuildSmallFont(AColors, AWad);
  BuildBigFont(AColors, AWad);
end;

end.
