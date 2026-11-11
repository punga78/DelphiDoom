{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - change of the sample rate (what             }
{  SDL_BuildAudioCVT does when a file and the mixer have different rates)       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.Resampler;

interface

type
  /// <summary>
  ///   Changes the rate of interleaved 16 bit stereo samples. When one rate is a power of two times the other
  ///   (11025 Hz at 22050 Hz, 44100 Hz at 22050 Hz) it takes the nearest earlier sample, as SDL 1.2 repeats or drops
  ///   samples; any other ratio is interpolated linearly
  /// </summary>
  TXcomResampler = class
  public
    /// <summary>The samples at ATargetRate; ASamples itself when the rates are equal</summary>
    class function Convert(const ASamples: TArray<SmallInt>; ASourceRate, ATargetRate: Integer): TArray<SmallInt>; static;
    /// <summary>True when the rates have a ratio that is a power of two (the conversions SDL does by repeating or dropping)</summary>
    class function IsPowerOfTwoRatio(ASourceRate, ATargetRate: Integer): Boolean; static;
  end;

implementation

class function TXcomResampler.IsPowerOfTwoRatio(ASourceRate, ATargetRate: Integer): Boolean;
var
  LLarge: Integer;
  LSmall: Integer;
  LRatio: Integer;
begin
  if ASourceRate >= ATargetRate then
  begin
    LLarge := ASourceRate;
    LSmall := ATargetRate;
  end
  else
  begin
    LLarge := ATargetRate;
    LSmall := ASourceRate;
  end;
  if (LSmall <= 0) or ((LLarge mod LSmall) <> 0) then
    Exit(False);
  LRatio := LLarge div LSmall;
  Result := (LRatio and (LRatio - 1)) = 0;
end;

class function TXcomResampler.Convert(const ASamples: TArray<SmallInt>; ASourceRate, ATargetRate: Integer): TArray<SmallInt>;
var
  LFrames: Integer;
  LOutFrames: Integer;
  LIndex: Integer;
  LSource: Integer;
  LNext: Integer;
  LPosition: Double;
  LFraction: Double;
  LNearest: Boolean;
  LChannel: Integer;
  LFirst: Integer;
  LSecond: Integer;
begin
  if (ASourceRate = ATargetRate) or (ASourceRate <= 0) or (ATargetRate <= 0) or (Length(ASamples) < 2) then
    Exit(ASamples);
  LFrames := Length(ASamples) div 2;
  LOutFrames := Integer((Int64(LFrames) * ATargetRate) div ASourceRate);
  SetLength(Result, LOutFrames * 2);
  LNearest := IsPowerOfTwoRatio(ASourceRate, ATargetRate);
  for LIndex := 0 to LOutFrames - 1 do
  begin
    if LNearest then
    begin
      LSource := Integer((Int64(LIndex) * ASourceRate) div ATargetRate);
      if LSource >= LFrames then
        LSource := LFrames - 1;
      Result[LIndex * 2] := ASamples[LSource * 2];
      Result[LIndex * 2 + 1] := ASamples[LSource * 2 + 1];
    end
    else
    begin
      LPosition := (Double(LIndex) * ASourceRate) / ATargetRate;
      LSource := Trunc(LPosition);
      LFraction := LPosition - LSource;
      if LSource >= LFrames then
        LSource := LFrames - 1;
      LNext := LSource + 1;
      if LNext >= LFrames then
        LNext := LSource;
      for LChannel := 0 to 1 do
      begin
        LFirst := ASamples[LSource * 2 + LChannel];
        LSecond := ASamples[LNext * 2 + LChannel];
        Result[LIndex * 2 + LChannel] := SmallInt(Round(LFirst + (LSecond - LFirst) * LFraction));
      end;
    end;
  end;
end;

end.
