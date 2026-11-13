{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio mix library - resampler by frame position                 }
{                                                                              }
{  Moved from DelphiDoom.XcomAudio.Resampler (what SDL_BuildAudioCVT does      }
{  when a file and the mixer have different rates). Derived from OpenXcom      }
{  (the OpenXcom Developers), GPL v3 or later: see Libs\XcomFormats\README.md  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.AudioMix.FramePositionResampler;

interface

uses
  System.SysUtils, DelphiDoom.AudioMix.Types, DelphiDoom.AudioMix.Intf;

type
  /// <summary>
  ///   Strategy of IPcmResampler for the sounds of OpenXcom: interleaved 16 bit stereo samples. When one rate is a
  ///   power of two times the other (11025 Hz at 22050 Hz, 44100 Hz at 22050 Hz) it takes the nearest earlier
  ///   sample, as SDL 1.2 repeats or drops samples; any other ratio is interpolated linearly
  /// </summary>
  TPcmFramePositionResampler = class(TInterfacedObject, IPcmResampler)
  public
    /// <summary>The samples at ATargetRate; ASamples itself when the rates are equal</summary>
    class function ConvertStereo16(const ASamples: TArray<SmallInt>; ASourceRate,
      ATargetRate: Integer): TArray<SmallInt>; static;
    /// <summary>True when the rates have a ratio that is a power of two (the conversions SDL does by repeating or dropping)</summary>
    class function IsPowerOfTwoRatio(ASourceRate, ATargetRate: Integer): Boolean; static;
    /// <summary>The same conversion on a buffer; EAudioMixException unless it is 16 bit stereo</summary>
    function Resample(const ASource: TPcmBuffer; ATargetRate: Cardinal): TPcmBuffer;
  end;

implementation

{ TPcmFramePositionResampler }

class function TPcmFramePositionResampler.IsPowerOfTwoRatio(ASourceRate, ATargetRate: Integer): Boolean;
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

class function TPcmFramePositionResampler.ConvertStereo16(const ASamples: TArray<SmallInt>; ASourceRate,
  ATargetRate: Integer): TArray<SmallInt>;
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

function TPcmFramePositionResampler.Resample(const ASource: TPcmBuffer; ATargetRate: Cardinal): TPcmBuffer;
var
  LSamples: TArray<SmallInt>;
begin
  if (ASource.Channels <> 2) or (ASource.BitsPerSample <> 16) then
    raise EAudioMixException.CreateFmt(SAudioMixBadFormat, [ASource.Channels, ASource.BitsPerSample]);
  SetLength(LSamples, Length(ASource.Data) div 2);
  if Length(LSamples) > 0 then
    Move(ASource.Data[0], LSamples[0], Length(LSamples) * SizeOf(SmallInt));
  LSamples := ConvertStereo16(LSamples, Integer(ASource.SampleRate), Integer(ATargetRate));
  Result.Channels := 2;
  Result.BitsPerSample := 16;
  Result.SampleRate := ATargetRate;
  SetLength(Result.Data, Length(LSamples) * SizeOf(SmallInt));
  if Length(LSamples) > 0 then
    Move(LSamples[0], Result.Data[0], Length(Result.Data));
end;

end.
