{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Ogg files                                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Ogg;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   Ogg files with Vorbis audio (with the floor type 1 every encoder
  ///   makes). The frames of the sound are those libsndfile counts from the
  ///   granule positions of the pages; what really decodes may be less
  /// </summary>
  TOggFormat = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

uses
  DelphiDoom.Sound.Codec.Vorbis, DelphiDoom.Sound.Vorbis.Length;

{ TOggFormat }

function TOggFormat.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LDecoder: TVorbisFileDecoder;
  LData: TArray<Single>;
  LDecoded, LFrames: Int64;
  LSoundInfo: TSoundFileInfo;
  LBytes: TBytes;
  LMoreThanThere: Boolean;
begin
  ASamples := nil;
  if (Length(ASource) < 12) or (ASource[0] <> Ord('O')) or (ASource[1] <> Ord('g')) or
     (ASource[2] <> Ord('g')) or (ASource[3] <> Ord('S')) then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  LDecoder := TVorbisFileDecoder.Create(ASource);
  try
    Result := LDecoder.ReadHeaders;
    if Result <> SNDFILE_OK then
      Exit;

    FillChar(LSoundInfo, SizeOf(LSoundInfo), 0);
    LSoundInfo.SampleRate := LDecoder.Rate;
    LSoundInfo.Channels := LDecoder.Channels;
    LSoundInfo.Format := SNDFILE_FORMAT_OGG or SNDFILE_FORMAT_VORBIS;
    LSoundInfo.Sections := 1;
    LSoundInfo.Seekable := 1;
    LSoundInfo.Frames := TVorbisLength.Count(ASource);

    // headers that were wrong inside leave nothing to decode, and sf_open refuses it
    if (LSoundInfo.Channels < 1) or (LSoundInfo.SampleRate < 1) then
      Exit(SNDFILE_ERR_MALFORMED_FILE);

    LDecoder.Decode(LData, LDecoded);
  finally
    LDecoder.Free;
  end;

  LFrames := LSoundInfo.Frames;
  LMoreThanThere := LDecoded > LFrames;
  if LMoreThanThere then
    LDecoded := LFrames;

  SetLength(LBytes, LDecoded * LSoundInfo.Channels * SizeOf(Single));
  if LDecoded > 0 then
    Move(LData[0], LBytes[0], Length(LBytes));
  ASamples := TSoundSamples.Create(LSoundInfo, TSoundSampleKind.Float32, LBytes, LDecoded);
  ASamples.FullScaleFloats := True;
  ASamples.SeekStopsAtData := True;
  // decoded past the frames it keeps: libsndfile clears what follows them
  if LMoreThanThere then
    ASamples.ZeroFillChunk := -1;
  Result := SNDFILE_OK;
end;

end.
