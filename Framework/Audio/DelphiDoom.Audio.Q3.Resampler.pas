{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - Quake III sound, ResampleSfx                    }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Q3.Resampler;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   ResampleSfx of snd_mem.c: decimates or repeats the samples to the rate of the
  ///   device with a step of 24.8 fixed point and no interpolation
  /// </summary>
  TQ3Resampler = class
  public
    /// <summary>
    ///   ResampleSfx on 16 bit samples. The result has ASourceCount / (rate / speed)
    ///   samples, as the C computes it in single precision
    /// </summary>
    class function ResampleShorts(const ASource: TArray<SmallInt>; ASourceCount, AInRate,
      ADmaSpeed: Integer): TArray<SmallInt>; static;
    /// <summary>
    ///   ResampleSfx on the bytes of a file: AInWidth 2 is 16 bit little endian, any other
    ///   width is 8 bit unsigned, as the C reads it
    /// </summary>
    class function ResampleBytes(const AData: TBytes; AOffset, ASourceCount, AInRate,
      AInWidth, ADmaSpeed: Integer): TArray<SmallInt>; static;
  end;

implementation

{$Q-}
{$R-}

uses
  DelphiDoom.Audio.Q3.Types;

const
  MAX_OUTPUT_SAMPLES = $4000000;

{ TQ3Resampler }

class function TQ3Resampler.ResampleShorts(const ASource: TArray<SmallInt>; ASourceCount,
  AInRate, ADmaSpeed: Integer): TArray<SmallInt>;
var
  LStepScale: Single;
  LRatio: Single;
  LOutCount, LFracStep, LFrac, LIndex, LSource: Integer;
begin
  if (AInRate <= 0) or (ADmaSpeed <= 0) then
    raise EQ3SoundException.CreateFmt(SQ3BadSoundRate, [AInRate]);
  if ASourceCount > Length(ASource) then
    ASourceCount := Length(ASource);
  if ASourceCount < 0 then
    ASourceCount := 0;
  LStepScale := Single(AInRate) / Single(ADmaSpeed);
  LRatio := Single(ASourceCount) / LStepScale;
  if LRatio >= MAX_OUTPUT_SAMPLES then
    raise EQ3SoundException.CreateFmt(SQ3BadSoundRate, [AInRate]);
  LOutCount := TQ3Math.TruncToInt(LRatio);
  LFracStep := TQ3Math.TruncToInt(Single(LStepScale * 256));
  SetLength(Result, LOutCount);
  LFrac := 0;
  for LIndex := 0 to LOutCount - 1 do
  begin
    LSource := TQ3Math.Sar(LFrac, 8);
    LFrac := LFrac + LFracStep;
    if (LSource >= 0) and (LSource < ASourceCount) then
      Result[LIndex] := ASource[LSource]
    else
      Result[LIndex] := 0;
  end;
end;

class function TQ3Resampler.ResampleBytes(const AData: TBytes; AOffset, ASourceCount,
  AInRate, AInWidth, ADmaSpeed: Integer): TArray<SmallInt>;
var
  LSamples: TArray<SmallInt>;
  LIndex, LAvailable: Integer;
begin
  if AOffset < 0 then
    AOffset := 0;
  LAvailable := Length(AData) - AOffset;
  if AInWidth = 2 then
    LAvailable := LAvailable div 2;
  if ASourceCount > LAvailable then
    ASourceCount := LAvailable;
  if ASourceCount < 0 then
    ASourceCount := 0;
  SetLength(LSamples, ASourceCount);
  for LIndex := 0 to ASourceCount - 1 do
    if AInWidth = 2 then
      LSamples[LIndex] := SmallInt(Word(AData[AOffset + LIndex * 2]) or
        (Word(AData[AOffset + LIndex * 2 + 1]) shl 8))
    else
      LSamples[LIndex] := SmallInt((Integer(AData[AOffset + LIndex]) - 128) shl 8);
  Result := ResampleShorts(LSamples, ASourceCount, AInRate, ADmaSpeed);
end;

end.
