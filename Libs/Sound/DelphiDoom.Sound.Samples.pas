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
    FPartialBytes: TBytes;
    FReadsDirectly: Boolean;
    FBigEndian: Boolean;
    FZeroFillChunk: Integer;
    FAvailableFrames: Int64;
  public
    /// <summary>
    ///   AData must hold exactly AInfo.Frames * AInfo.Channels samples of AKind
    /// </summary>
    constructor Create(const AInfo: TSoundFileInfo; AKind: TSoundSampleKind;
      const AData: TBytes);
    /// <summary>Changes the description, for what only the codec knows (can the sound be seeked)</summary>
    procedure ReplaceInfo(const AInfo: TSoundFileInfo);

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
    /// <summary>
    ///   Bytes of a sample cut short by the end of the source, as stored in
    ///   the file. When libsndfile reads samples of the same width as the
    ///   caller's buffer it reads straight into it, so these bytes end up
    ///   there raw, right after the extra samples. Empty when the read goes
    ///   through a conversion buffer
    /// </summary>
    property PartialBytes: TBytes read FPartialBytes write FPartialBytes;
    /// <summary>
    ///   True for 16 and 32 bit integer samples, which libsndfile reads
    ///   straight into a buffer of the same width
    /// </summary>
    property ReadsDirectly: Boolean read FReadsDirectly write FReadsDirectly;
    /// <summary>
    ///   With ReadsDirectly, the file stores the samples big endian: libsndfile
    ///   then swaps the bytes of the whole buffer it was given, including the
    ///   part past the end of the sound that it left untouched
    /// </summary>
    property BigEndian: Boolean read FBigEndian write FBigEndian;
    /// <summary>
    ///   For the codecs that decode through a buffer of this many items: a read
    ///   that goes past the end of the sound has the buffers it used cleared,
    ///   so the part of the caller's buffer past the end is zero up to the end
    ///   of the chunk where the sound stopped (all of it for 16 bit reads).
    ///   Zero for the formats that leave the buffer alone
    /// </summary>
    property ZeroFillChunk: Integer read FZeroFillChunk write FZeroFillChunk;
    /// <summary>
    ///   How many frames the codec really has when that is less than Info.Frames
    ///   (GSM with more channels than it decodes); a read stops there. -1 when
    ///   the sound has all of Info.Frames
    /// </summary>
    property AvailableFrames: Int64 read FAvailableFrames write FAvailableFrames;
  end;

implementation

{ TSoundSamples }

procedure TSoundSamples.ReplaceInfo(const AInfo: TSoundFileInfo);
begin
  FInfo := AInfo;
end;

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
  FAvailableFrames := -1;
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
