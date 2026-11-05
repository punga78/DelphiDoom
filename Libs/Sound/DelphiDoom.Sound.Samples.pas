{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - decoded samples of one sound                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Samples;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf;

type
  /// <summary>
  ///   How the samples of a decoded sound are stored
  /// </summary>
  /// <remarks>
  ///   Integer samples are always left justified: an 8 bit sound is stored as
  ///   Int16 (value shl 8), a 24 bit one as Int32 (value shl 8). Reading them
  ///   as 16 bit, 32 bit or double then needs only a shift or a division, with
  ///   the same result libsndfile gives
  /// </remarks>
  TSoundSampleKind = (Int16, Int32, Float32, Float64);

  /// <summary>
  ///   The result of decoding a sound: its description and all its samples,
  ///   interleaved. Produced by an ISoundFormat, consumed by TSoundFile
  /// </summary>
  TSoundSamples = class
  private
    FInfo: TSoundFileInfo;
    FKind: TSoundSampleKind;
    FData: TBytes;
    FExtraItems: Int64;
    FTail: TBytes;
  public
    /// <summary>
    ///   AData must hold exactly AInfo.Frames * AInfo.Channels samples of AKind
    /// </summary>
    constructor Create(const AInfo: TSoundFileInfo; AKind: TSoundSampleKind;
      const AData: TBytes);

    class function BytesPerSample(AKind: TSoundSampleKind): Integer; static;

    property Info: TSoundFileInfo read FInfo;
    property Kind: TSoundSampleKind read FKind;
    property Data: TBytes read FData;
    /// <summary>
    ///   Samples that the source holds after the end of the sound (padding,
    ///   chunks that follow the data). libsndfile reads them with the rest: if
    ///   they make at least a frame it clears the part of the caller's buffer
    ///   past the end of the sound, otherwise they end up in the buffer as they
    ///   are. Zero for sources that never have them
    /// </summary>
    property ExtraItems: Int64 read FExtraItems write FExtraItems;
    /// <summary>
    ///   The first extra samples, up to one frame, decoded like the others
    /// </summary>
    property Tail: TBytes read FTail write FTail;
  end;

implementation

{ TSoundSamples }

constructor TSoundSamples.Create(const AInfo: TSoundFileInfo;
  AKind: TSoundSampleKind; const AData: TBytes);
begin
  inherited Create;
  if (AInfo.Frames < 0) or (AInfo.Channels < 1) or
     (Int64(Length(AData)) <> AInfo.Frames * AInfo.Channels * BytesPerSample(AKind)) then
    raise EArgumentException.Create('Size of the samples does not match the description of the sound');

  FInfo := AInfo;
  FKind := AKind;
  FData := AData;
end;

class function TSoundSamples.BytesPerSample(AKind: TSoundSampleKind): Integer;
begin
  case AKind of
    TSoundSampleKind.Int16:   Result := 2;
    TSoundSampleKind.Int32:   Result := 4;
    TSoundSampleKind.Float32: Result := 4;
  else
    Result := 8;
  end;
end;

end.
