{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Fasttracker 2 extended instruments (XI)         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Xi;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   XI instruments: a header of 298 bytes plus 40 for each sample, then the
  ///   samples as differences from the one before, 8 or 16 bit, mono at 44100
  ///   Hz. libsndfile takes the first sample and reads to the end of the file;
  ///   the sound cannot be seeked
  /// </summary>
  TXiFormat = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

const
  MAX_XI_SAMPLES = 16;
  SAMPLE_RATE = 44100;
  SAMPLE_HEADER_SIZE = 40;
  EXTENDED_SAMPLE_COUNT_OFFSET = 296;
  FIRST_SAMPLE_HEADER_OFFSET = 298;

{ TXiFormat }

function TXiFormat.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
const
  SIGNATURE: AnsiString = 'Extended Instrument:';
var
  LLength, LIndex, LSampleCount, LFlagsOffset, LDataOffset, LFrames: Integer;
  LInfo: TSoundFileInfo;
  LSixteen: Boolean;
  LSizes: array[0..MAX_XI_SAMPLES - 1] of Integer;
  LData: TArray<SmallInt>;
  LBytes: TBytes;
  LLast: SmallInt;
  LDelta: Integer;

  function At(AIndex: Integer): Cardinal;
  begin
    // the header reader of libsndfile gets zeros past the end
    if (AIndex >= 0) and (AIndex < LLength) then
      Result := ASource[AIndex]
    else
      Result := 0;
  end;

begin
  ASamples := nil;
  LLength := Length(ASource);
  // What libsndfile looks at to tell: "Extended Ins"
  if (LLength < 12) or (not CompareMem(@ASource[0], PAnsiChar('Extended Ins'), 12)) then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  for LIndex := 1 to Length(SIGNATURE) do
    if At(LIndex - 1) <> Ord(SIGNATURE[LIndex]) then
      Exit(SNDFILE_ERR_MALFORMED_FILE);
  // the name of the instrument ends with a 1A
  if At(21 + 22) <> $1A then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  LSampleCount := SmallInt(At(EXTENDED_SAMPLE_COUNT_OFFSET) or (At(EXTENDED_SAMPLE_COUNT_OFFSET + 1) shl 8));
  if LSampleCount > MAX_XI_SAMPLES then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  FillChar(LSizes, SizeOf(LSizes), 0);
  LSixteen := False;
  LFlagsOffset := FIRST_SAMPLE_HEADER_OFFSET;
  for LIndex := 0 to LSampleCount - 1 do
  begin
    LSizes[LIndex] := Integer(At(LFlagsOffset) or (At(LFlagsOffset + 1) shl 8) or
      (At(LFlagsOffset + 2) shl 16) or (At(LFlagsOffset + 3) shl 24));
    // volume, fine tune, flags, pan, note and the length of the name follow the three numbers
    if LIndex = 0 then
      LSixteen := (At(LFlagsOffset + 12 + 2) and 16) <> 0;
    Inc(LFlagsOffset, SAMPLE_HEADER_SIZE);
  end;
  // no sample: libsndfile has no codec for the sound and refuses it
  if LSampleCount < 1 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  while (LSampleCount > 1) and (LSizes[LSampleCount - 1] = 0) do
    Dec(LSampleCount);
  // only one sample can be had
  if LSampleCount > 2 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  LDataOffset := LFlagsOffset;
  FillChar(LInfo, SizeOf(LInfo), 0);
  LInfo.Channels := 1;
  LInfo.SampleRate := SAMPLE_RATE;
  LInfo.Sections := 1;
  // there is no seeking in the DPCM: libsndfile does not allow it
  LInfo.Seekable := 0;
  if LSixteen then
    LInfo.Format := SNDFILE_FORMAT_XI or SNDFILE_FORMAT_DPCM_16
  else
    LInfo.Format := SNDFILE_FORMAT_XI or SNDFILE_FORMAT_DPCM_8;

  // to the end of the file, whatever the size of the sample says
  if LSixteen then
    LFrames := (LLength - LDataOffset) div 2
  else
    LFrames := LLength - LDataOffset;
  if LFrames < 0 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  LInfo.Frames := LFrames;

  SetLength(LData, LFrames);
  LLast := 0;
  for LIndex := 0 to LFrames - 1 do
    if LSixteen then
    begin
      LDelta := SmallInt(At(LDataOffset + LIndex * 2) or (At(LDataOffset + LIndex * 2 + 1) shl 8));
      LLast := SmallInt(LLast + LDelta);
      LData[LIndex] := LLast;
    end
    else
    begin
      // sums of signed bytes that wrap, kept in the high byte
      LDelta := ShortInt(At(LDataOffset + LIndex));
      LLast := SmallInt(ShortInt((LLast shr 8) + LDelta) shl 8);
      LData[LIndex] := LLast;
    end;

  SetLength(LBytes, LFrames * SizeOf(SmallInt));
  if LFrames > 0 then
    Move(LData[0], LBytes[0], Length(LBytes));
  ASamples := TSoundSamples.Create(LInfo, TSoundSampleKind.Int16, LBytes, -1);
  Result := SNDFILE_OK;
end;

end.
