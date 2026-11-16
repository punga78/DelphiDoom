{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixPerlinNoise                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the noise functions of GenerateBigFonts (radix_xlat_wad.pas)        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.PerlinNoise;

// the hash of Noise wraps around on 32 bits, as the original did
{$Q-}{$R-}

interface

type
  /// <summary>The noise that gives the texture to the big fonts</summary>
  TRadixPerlinNoise = class
  strict private
    class function Interpolate(AFirst, ASecond, AFraction: Double): Double; static;
    class function Noise(AX, AY: Double): Double; static;
    class function SmoothedNoise(AX, AY: Double): Double; static;
    class function InterpolatedNoise(AX, AY: Double): Double; static;
  public
    /// <summary>Three octaves of persistence 0.5, times 16</summary>
    class function Value(AX, AY: Integer): Double; static;
  end;

implementation

uses
  System.Math;

{ TRadixPerlinNoise }

class function TRadixPerlinNoise.Interpolate(AFirst, ASecond, AFraction: Double): Double;
begin
  Result := (1.0 - Cos(Pi * AFraction)) * 0.5;
  Result := AFirst * (1 - Result) + ASecond * Result;
end;

class function TRadixPerlinNoise.Noise(AX, AY: Double): Double;
var
  LValue: Integer;
begin
  LValue := Trunc(AX + AY * 57);
  LValue := (LValue shl 13) xor LValue;
  Result := 1.0 - ((LValue * (LValue * LValue * $EC4D + $131071F) + $5208DD0D) and $7FFFFFFF) / $40000000;
end;

class function TRadixPerlinNoise.SmoothedNoise(AX, AY: Double): Double;
var
  LCorners: Double;
  LSides: Double;
  LCenter: Double;
begin
  LCorners := (Noise(AX - 1, AY - 1) + Noise(AX + 1, AY - 1) + Noise(AX - 1, AY + 1) +
    Noise(AX + 1, AY + 1)) / 16;
  LSides := (Noise(AX - 1, AY) + Noise(AX + 1, AY) + Noise(AX, AY - 1) + Noise(AX, AY + 1)) / 8;
  LCenter := Noise(AX, AY) / 4;
  Result := LCorners + LSides + LCenter;
end;

class function TRadixPerlinNoise.InterpolatedNoise(AX, AY: Double): Double;
var
  LIntX: Double;
  LIntY: Double;
  LFractionX: Double;
  LFractionY: Double;
begin
  LIntX := Int(AX);
  LFractionX := Frac(AX);
  LIntY := Int(AY);
  LFractionY := Frac(AY);
  Result := Interpolate(
    Interpolate(SmoothedNoise(LIntX, LIntY), SmoothedNoise(LIntX + 1, LIntY), LFractionX),
    Interpolate(SmoothedNoise(LIntX, LIntY + 1), SmoothedNoise(LIntX + 1, LIntY + 1), LFractionX),
    LFractionY);
end;

class function TRadixPerlinNoise.Value(AX, AY: Integer): Double;
const
  Persistence = 0.50;
  LoopCount = 3;
  Variation = 16;
var
  LOctave: Integer;
  LFrequency: Integer;
begin
  LFrequency := 1;
  Result := 0.0;
  for LOctave := 0 to LoopCount - 1 do
  begin
    Result := Result + InterpolatedNoise(AX * LFrequency, AY * LFrequency) * Power(Persistence, LOctave);
    LFrequency := LFrequency shl 1;
  end;
  Result := Result * Variation;
end;

end.
