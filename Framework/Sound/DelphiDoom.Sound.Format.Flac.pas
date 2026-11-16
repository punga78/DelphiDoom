{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - FLAC files                                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Flac;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   FLAC files of 8, 16 and 24 bit. The frames of the sound are what the
  ///   STREAMINFO block says (an unknown number counts as the biggest one);
  ///   what the frames really make may be less
  /// </summary>
  TFlacFormat = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

uses
  DelphiDoom.Sound.Codec.Flac;

{ TFlacFormat }

function TFlacFormat.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LDecoder: TFlacDecoder;
  LInfo: TFlacStreamInfo;
  LData: TArray<Integer>;
  LDecoded, LFrames: Int64;
  LEvents: TArray<TSoundErrorEvent>;
  LSoundInfo: TSoundFileInfo;
  LBytes: TBytes;
  LCodec: Integer;
  LMoreThanThere: Boolean;
begin
  ASamples := nil;
  if (Length(ASource) < 12) or (ASource[0] <> Ord('f')) or (ASource[1] <> Ord('L')) or
     (ASource[2] <> Ord('a')) or (ASource[3] <> Ord('C')) then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  LDecoder := TFlacDecoder.Create(ASource);
  try
    Result := LDecoder.Decode(LInfo, LData, LDecoded, LEvents);
  finally
    LDecoder.Free;
  end;
  if Result <> SNDFILE_OK then
    Exit;

  case LInfo.BitsPerSample of
    8: LCodec := SNDFILE_FORMAT_PCM_S8;
    16: LCodec := SNDFILE_FORMAT_PCM_16;
  else
    LCodec := SNDFILE_FORMAT_PCM_24;
  end;

  if LInfo.TotalSamples = 0 then
    LFrames := High(Int64)
  else
    LFrames := LInfo.TotalSamples;
  LMoreThanThere := LDecoded > LFrames;
  if LMoreThanThere then
    LDecoded := LFrames;

  FillChar(LSoundInfo, SizeOf(LSoundInfo), 0);
  LSoundInfo.Frames := LFrames;
  LSoundInfo.SampleRate := LInfo.SampleRate;
  LSoundInfo.Channels := LInfo.Channels;
  LSoundInfo.Format := SNDFILE_FORMAT_FLAC or LCodec;
  LSoundInfo.Sections := 1;
  LSoundInfo.Seekable := 1;

  SetLength(LBytes, LDecoded * LInfo.Channels * SizeOf(Integer));
  if LDecoded > 0 then
    Move(LData[0], LBytes[0], Length(LBytes));
  ASamples := TSoundSamples.Create(LSoundInfo, TSoundSampleKind.Int32, LBytes, LDecoded);
  // Decoded past the frames it keeps: libsndfile clears what follows them
  if LMoreThanThere then
    ASamples.ZeroFillChunk := -1;
  ASamples.ErrorEvents := LEvents;
  ASamples.SeekLimit := LDecoded;
  Result := SNDFILE_OK;
end;

end.
