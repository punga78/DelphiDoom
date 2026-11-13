{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - PCM resampler                                     }
{                                                                              }
{  Port of mv_resample_pcm and mw_resample_pcm (the same code twice) of        }
{  shl/voc.h and shl/wav.h of war1 (acoto87/war1), MIT License, (c) 2026       }
{  Alejandro Coto Gutierrez; war1 is under the zlib License (see Libs\War\     }
{  LICENSE-war1.txt). This is an altered version, not the original.            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Audio.Resampler;

{$Q-}
{$R-}
// the original relies on the wraparound of 32 bit integers in (b - a) * frac: overflow checks must stay off

interface

uses
  System.SysUtils, DelphiDoom.War.Audio.Types;

type
  /// <summary>
  ///   Same rate: a copy. 8 bit mono and a ratio of 2 or 4: the fast paths (linear interpolation up, average
  ///   down). Everything else (8 or 16 bit, any channels): linear interpolation with a 16.16 position
  /// </summary>
  TWarPcmResampler = class
  strict private
    class function Sar(AValue: Integer; AShift: Integer): Integer; static; inline;
    class function Sample16(const AData: TBytes; AIndex: Integer): Integer; static; inline;
    class procedure Upsample2(const ASource: TBytes; var ADest: TBytes; ASamples: Integer); static;
    class procedure Upsample4(const ASource: TBytes; var ADest: TBytes; ASamples: Integer); static;
    class procedure Downsample2(const ASource: TBytes; var ADest: TBytes; ATargetSamples: Integer); static;
    class procedure Downsample4(const ASource: TBytes; var ADest: TBytes; ATargetSamples: Integer); static;
    class procedure Interpolate(const ASource: TWarPcmBuffer; var ADest: TWarPcmBuffer; ATotalSource,
      ATotalDest: Integer; AStep: Cardinal); static;
  public
    /// <summary>
    ///   The samples at ATargetRate. EWarException where the original returns 0 (no samples, rate 0) and for a
    ///   sample format it cannot interpolate (not 8 or 16 bits, no channels), which the original would read as
    ///   a division by zero or leave unwritten
    /// </summary>
    class function Resample(const ASource: TWarPcmBuffer; ATargetRate: Cardinal): TWarPcmBuffer; static;
  end;

implementation

uses
  DelphiDoom.War.Types;

{ TWarPcmResampler }

class function TWarPcmResampler.Sar(AValue: Integer; AShift: Integer): Integer;
begin
  // >> of a negative number is arithmetic in the C of the original
  if AValue >= 0 then
    Result := AValue shr AShift
  else
    Result := not ((not AValue) shr AShift);
end;

class function TWarPcmResampler.Sample16(const AData: TBytes; AIndex: Integer): Integer;
begin
  Result := SmallInt(Word(AData[AIndex * 2]) or (Word(AData[AIndex * 2 + 1]) shl 8));
end;

class procedure TWarPcmResampler.Upsample2(const ASource: TBytes; var ADest: TBytes; ASamples: Integer);
var
  LIndex, LDest, LA, LB: Integer;
begin
  LDest := 0;
  for LIndex := 0 to ASamples - 2 do
  begin
    LA := ASource[LIndex];
    LB := ASource[LIndex + 1];
    ADest[LDest] := Byte(LA);
    ADest[LDest + 1] := Byte(LA + Sar(LB - LA, 1));
    Inc(LDest, 2);
  end;
  ADest[LDest] := ASource[ASamples - 1];
  ADest[LDest + 1] := ASource[ASamples - 1];
end;

class procedure TWarPcmResampler.Upsample4(const ASource: TBytes; var ADest: TBytes; ASamples: Integer);
var
  LIndex, LDest, LA, LB, LDiff, LTail: Integer;
begin
  LDest := 0;
  for LIndex := 0 to ASamples - 2 do
  begin
    LA := ASource[LIndex];
    LB := ASource[LIndex + 1];
    LDiff := LB - LA;
    ADest[LDest] := Byte(LA);
    ADest[LDest + 1] := Byte(LA + Sar(LDiff * 1, 2));
    ADest[LDest + 2] := Byte(LA + Sar(LDiff * 2, 2));
    ADest[LDest + 3] := Byte(LA + Sar(LDiff * 3, 2));
    Inc(LDest, 4);
  end;
  for LTail := 0 to 3 do
    ADest[LDest + LTail] := ASource[ASamples - 1];
end;

class procedure TWarPcmResampler.Downsample2(const ASource: TBytes; var ADest: TBytes; ATargetSamples: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ATargetSamples - 1 do
    ADest[LIndex] := Byte((Integer(ASource[LIndex * 2]) + ASource[LIndex * 2 + 1]) shr 1);
end;

class procedure TWarPcmResampler.Downsample4(const ASource: TBytes; var ADest: TBytes; ATargetSamples: Integer);
var
  LIndex, LStart: Integer;
begin
  for LIndex := 0 to ATargetSamples - 1 do
  begin
    LStart := LIndex * 4;
    ADest[LIndex] := Byte((Integer(ASource[LStart]) + ASource[LStart + 1] + ASource[LStart + 2] +
      ASource[LStart + 3]) shr 2);
  end;
end;

class procedure TWarPcmResampler.Interpolate(const ASource: TWarPcmBuffer; var ADest: TWarPcmBuffer; ATotalSource,
  ATotalDest: Integer; AStep: Cardinal);
var
  LPosition: Cardinal;
  LIndex, LFirst, LSecond, LFraction, LChannel, LA, LB: Integer;
  LValue: Integer;
  LTarget: Integer;
begin
  LPosition := 0;
  for LIndex := 0 to ATotalDest - 1 do
  begin
    LFirst := Integer(LPosition shr 16);
    // the original reads one sample past the buffer here when the step rounds up; the last sample is used
    if LFirst > ATotalSource - 1 then
      LFirst := ATotalSource - 1;
    LSecond := LFirst + 1;
    if LSecond >= ATotalSource then
      LSecond := LFirst;
    LFraction := Integer(LPosition and $FFFF);
    for LChannel := 0 to Integer(ASource.Channels) - 1 do
    begin
      LTarget := LIndex * Integer(ASource.Channels) + LChannel;
      if ASource.BitsPerSample = 8 then
      begin
        LA := ASource.Data[LFirst * Integer(ASource.Channels) + LChannel];
        LB := ASource.Data[LSecond * Integer(ASource.Channels) + LChannel];
        ADest.Data[LTarget] := Byte(LA + Sar((LB - LA) * LFraction, 16));
      end
      else
      begin
        LA := Sample16(ASource.Data, LFirst * Integer(ASource.Channels) + LChannel);
        LB := Sample16(ASource.Data, LSecond * Integer(ASource.Channels) + LChannel);
        LValue := LA + Sar((LB - LA) * LFraction, 16);
        ADest.Data[LTarget * 2] := Byte(LValue);
        ADest.Data[LTarget * 2 + 1] := Byte(LValue shr 8);
      end;
    end;
    Inc(LPosition, AStep);
  end;
end;

class function TWarPcmResampler.Resample(const ASource: TWarPcmBuffer; ATargetRate: Cardinal): TWarPcmBuffer;
var
  LBytesPerSample: Cardinal;
  LTotalSource, LTotalDest: Integer;
  LRatio, LQuotient, LStepValue: Double;
begin
  if (Length(ASource.Data) = 0) or (ATargetRate = 0) then
    raise EWarException.CreateFmt(SWarAudioBadFormat, [ASource.Channels, ASource.BitsPerSample]);
  Result.Channels := ASource.Channels;
  Result.BitsPerSample := ASource.BitsPerSample;
  Result.SampleRate := ATargetRate;
  if ASource.SampleRate = ATargetRate then
  begin
    Result.Data := Copy(ASource.Data);
    Exit;
  end;
  if ((ASource.BitsPerSample <> 8) and (ASource.BitsPerSample <> 16)) or (ASource.Channels = 0) then
    raise EWarException.CreateFmt(SWarAudioBadFormat, [ASource.Channels, ASource.BitsPerSample]);
  LBytesPerSample := (ASource.BitsPerSample div 8) * ASource.Channels;
  LTotalSource := Length(ASource.Data) div Integer(LBytesPerSample);
  if (ASource.Channels = 1) and (ASource.BitsPerSample = 8) then
  begin
    if ATargetRate = ASource.SampleRate * 2 then
    begin
      SetLength(Result.Data, Length(ASource.Data) * 2);
      Upsample2(ASource.Data, Result.Data, LTotalSource);
      Exit;
    end;
    if ATargetRate = ASource.SampleRate * 4 then
    begin
      SetLength(Result.Data, Length(ASource.Data) * 4);
      Upsample4(ASource.Data, Result.Data, LTotalSource);
      Exit;
    end;
    if ASource.SampleRate = ATargetRate * 2 then
    begin
      SetLength(Result.Data, Length(ASource.Data) div 2);
      Downsample2(ASource.Data, Result.Data, LTotalSource div 2);
      Exit;
    end;
    if ASource.SampleRate = ATargetRate * 4 then
    begin
      SetLength(Result.Data, Length(ASource.Data) div 4);
      Downsample4(ASource.Data, Result.Data, LTotalSource div 4);
      Exit;
    end;
  end;
  LRatio := ASource.SampleRate / ATargetRate;
  // each operation is rounded to a Double, as the C does (the x87 would keep more bits between them)
  LQuotient := LTotalSource / LRatio;
  LTotalDest := Trunc(LQuotient);
  LStepValue := LRatio * 65536.0;
  LStepValue := LStepValue + 0.5;
  SetLength(Result.Data, LTotalDest * Integer(LBytesPerSample));
  Interpolate(ASource, Result, LTotalSource, LTotalDest, Cardinal(Trunc(LStepValue)));
end;

end.
