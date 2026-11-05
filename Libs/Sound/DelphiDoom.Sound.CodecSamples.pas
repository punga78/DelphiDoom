{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - samples produced by the block codecs            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.CodecSamples;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples;

type
  /// <summary>
  ///   Wraps what a codec decoded (16 bit samples) as the samples of a sound.
  ///   libsndfile fills the rest of the buffer of a read that goes past the
  ///   end of such a sound with zeros, which is what the samples ask for
  /// </summary>
  TSoundCodecSamples = class
  public
    class function Wrap(AFormat, AChannels, ASampleRate: Integer; AFrames: Int64;
      const AData: TBytes; AZeroAll: Boolean = False): TSoundSamples; static;
    /// <summary>
    ///   GSM 6.10: a sound that cannot be seeked, whose reads are cleared to
    ///   the end. AChannels may be more than one (AIFF): the decoded samples
    ///   then fill the start and zeros the rest
    /// </summary>
    class function WrapGsm(AFormat, AChannels, ASampleRate: Integer; AFrames: Int64;
      const AData: TBytes): TSoundSamples; static;
  end;

implementation

const
  // Items of the buffer of 16 bit samples the codecs convert through
  CODEC_BUFFER_ITEMS = 4096;

{ TSoundCodecSamples }

class function TSoundCodecSamples.Wrap(AFormat, AChannels, ASampleRate: Integer;
  AFrames: Int64; const AData: TBytes; AZeroAll: Boolean): TSoundSamples;
var
  LInfo: TSoundFileInfo;
begin
  FillChar(LInfo, SizeOf(LInfo), 0);
  LInfo.Frames := AFrames;
  LInfo.SampleRate := ASampleRate;
  LInfo.Channels := AChannels;
  LInfo.Format := AFormat;
  LInfo.Sections := 1;
  LInfo.Seekable := 1;
  Result := TSoundSamples.Create(LInfo, TSoundSampleKind.Int16, AData);
  // Zeros past the end, in the chunks of the buffer libsndfile decodes through
  if AZeroAll then
    // The codec decoded more than the sound has: libsndfile clears all that follows
    Result.ZeroFillChunk := -1
  else
    Result.ZeroFillChunk := CODEC_BUFFER_ITEMS;
end;

class function TSoundCodecSamples.WrapGsm(AFormat, AChannels, ASampleRate: Integer;
  AFrames: Int64; const AData: TBytes): TSoundSamples;
var
  LData: TBytes;
  LInfo: TSoundFileInfo;
begin
  LData := AData;
  SetLength(LData, AFrames * AChannels * SizeOf(SmallInt));
  Result := Wrap(AFormat, AChannels, ASampleRate, AFrames, LData, True);
  // Its reads convert chunk after chunk, offset by what was really decoded
  Result.ZeroFillChunk := -2;
  // Only what the codec decoded is there: more channels do not make more samples
  Result.AvailableFrames := Length(AData) div SizeOf(SmallInt) div AChannels;
  LInfo := Result.Info;
  LInfo.Seekable := 0;
  Result.ReplaceInfo(LInfo);
end;

end.
