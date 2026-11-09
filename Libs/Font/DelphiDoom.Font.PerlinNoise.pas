{******************************************************************************}
{                                                                              }
{  DelphiDoom: font library - the noise of the texture of a font                }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Font.PerlinNoise;

// The integer noise is a hash: its sums and products are meant to wrap around (as they do in 32 bits in the
// original). They are done on Cardinal so that the result is the same with and without the overflow checks
{$OVERFLOWCHECKS OFF}
{$RANGECHECKS OFF}

interface

type
  /// <summary>
  ///   The "Perlin noise" of FF_ExportFont: three octaves of a smoothed integer noise, with a persistence of a
  ///   half, scaled by 16. It is a pure function of the position: the same pixel gets the same value every
  ///   time, so the same text gives the same patch. The original did the integer part of the hash with
  ///   Integer, that wraps around in Delphi without checks; here it is a Cardinal
  /// </summary>
  TFontPerlinNoise = class sealed
  strict private
    const
      LOOP_COUNT = 3;
      VARIATION = 16;
      HASH_NOISE_SHIFT = 13;
      HASH_MULTIPLIER = Cardinal($EC4D);
      HASH_ADDEND1 = Cardinal($131071F);
      HASH_ADDEND2 = Cardinal($5208DD0D);
      HASH_MASK = Cardinal($7FFFFFFF);
      HASH_SCALE = $40000000;
      Y_STRIDE = 57;
    class function Interpolate(AFirst, ASecond, AFraction: Double): Double; static;
    class function Noise(AX, AY: Double): Double; static;
    class function SmoothedNoise(AX, AY: Double): Double; static;
    class function InterpolatedNoise(AX, AY: Double): Double; static;
  public
    /// <summary>The noise that is added to the three channels of the pixel in the column AX and the row AY</summary>
    class function Value(AX, AY: Integer): Double; static;
  end;

implementation

uses
  System.Math;

{ TFontPerlinNoise }

class function TFontPerlinNoise.Interpolate(AFirst, ASecond, AFraction: Double): Double;
var
  LWeight: Double;
begin
  LWeight := (1.0 - Cos(Pi * AFraction)) * 0.5;
  Result := AFirst * (1 - LWeight) + ASecond * LWeight;
end;

class function TFontPerlinNoise.Noise(AX, AY: Double): Double;
var
  LN: Cardinal;
  LHash: Cardinal;
begin
  LN := Cardinal(Integer(Trunc(AX + AY * Y_STRIDE)));
  LN := (LN shl HASH_NOISE_SHIFT) xor LN;
  LHash := LN * (LN * LN * HASH_MULTIPLIER + HASH_ADDEND1) + HASH_ADDEND2;
  Result := 1.0 - (LHash and HASH_MASK) / HASH_SCALE;
end;

class function TFontPerlinNoise.SmoothedNoise(AX, AY: Double): Double;
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

class function TFontPerlinNoise.InterpolatedNoise(AX, AY: Double): Double;
var
  LXInt: Double;
  LYInt: Double;
  LXFrac: Double;
  LYFrac: Double;
  LFirst: Double;
  LSecond: Double;
begin
  LXInt := Int(AX);
  LXFrac := Frac(AX);
  LYInt := Int(AY);
  LYFrac := Frac(AY);
  LFirst := Interpolate(SmoothedNoise(LXInt, LYInt), SmoothedNoise(LXInt + 1, LYInt), LXFrac);
  LSecond := Interpolate(SmoothedNoise(LXInt, LYInt + 1), SmoothedNoise(LXInt + 1, LYInt + 1), LXFrac);
  Result := Interpolate(LFirst, LSecond, LYFrac);
end;

class function TFontPerlinNoise.Value(AX, AY: Integer): Double;
var
  LAmplitude: Double;
  LOctave: Integer;
  LFrequency: Integer;
begin
  LFrequency := 1;
  LAmplitude := 1.0;
  Result := 0.0;
  for LOctave := 0 to LOOP_COUNT - 1 do
  begin
    Result := Result + InterpolatedNoise(AX * LFrequency, AY * LFrequency) * LAmplitude;
    LFrequency := LFrequency shl 1;
    LAmplitude := LAmplitude * 0.5;
  end;
  Result := Result * VARIATION;
end;

end.
