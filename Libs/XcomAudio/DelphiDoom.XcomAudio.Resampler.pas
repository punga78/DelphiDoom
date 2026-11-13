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
  ///   samples; any other ratio is interpolated linearly. The code is the strategy TPcmFramePositionResampler of
  ///   Libs\AudioMix
  /// </summary>
  TXcomResampler = class
  public
    /// <summary>The samples at ATargetRate; ASamples itself when the rates are equal</summary>
    class function Convert(const ASamples: TArray<SmallInt>; ASourceRate, ATargetRate: Integer): TArray<SmallInt>; static;
    /// <summary>True when the rates have a ratio that is a power of two (the conversions SDL does by repeating or dropping)</summary>
    class function IsPowerOfTwoRatio(ASourceRate, ATargetRate: Integer): Boolean; static;
  end;

implementation

uses
  DelphiDoom.AudioMix.FramePositionResampler;

class function TXcomResampler.IsPowerOfTwoRatio(ASourceRate, ATargetRate: Integer): Boolean;
begin
  Result := TPcmFramePositionResampler.IsPowerOfTwoRatio(ASourceRate, ATargetRate);
end;

class function TXcomResampler.Convert(const ASamples: TArray<SmallInt>; ASourceRate, ATargetRate: Integer): TArray<SmallInt>;
begin
  Result := TPcmFramePositionResampler.ConvertStereo16(ASamples, ASourceRate, ATargetRate);
end;

end.
