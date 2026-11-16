{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - raw samples of the usual encodings              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.PcmReader;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples;

type
  /// <summary>
  ///   What a container header says about the samples of its data
  /// </summary>
  TSoundPcmLayout = record
    /// <summary>
    ///   One SNDFILE_FORMAT_* encoding: PCM_S8, PCM_U8, PCM_16, PCM_24, PCM_32,
    ///   FLOAT, DOUBLE, ULAW or ALAW
    /// </summary>
    Encoding: Integer;
    /// <summary>The Format reported to the caller: container, encoding and endian flag</summary>
    Format: Integer;
    Channels: Integer;
    SampleRate: Integer;
    /// <summary>Bytes of one sample in the file (1 for mu-law and A-law)</summary>
    BytesPerSample: Integer;
  end;

  /// <summary>
  ///   Turns the data chunk of a container into samples. Shared by every
  ///   container that stores plain PCM, float or companded samples
  /// </summary>
  TSoundPcmReader = class
  public
    /// <summary>
    ///   Reads ADataLength bytes at ADataOffset of ASource. AFileLength is what
    ///   libsndfile considers the end of the file: the bytes between the data
    ///   and it are kept as the extra samples of TSoundSamples
    /// </summary>
    class function Read(const ASource: TBytes; const ALayout: TSoundPcmLayout;
      ADataOffset, ADataLength, AFileLength: Int64; ABigEndian: Boolean;
      out ASamples: TSoundSamples): Integer; static;
  end;

implementation

{$POINTERMATH ON}

uses
  DelphiDoom.Sound.Companding;

{ TSoundPcmReader }

class function TSoundPcmReader.Read(const ASource: TBytes;
  const ALayout: TSoundPcmLayout; ADataOffset, ADataLength, AFileLength: Int64;
  ABigEndian: Boolean; out ASamples: TSoundSamples): Integer;
var
  LKind: TSoundSampleKind;
  LEncoding: Integer;
  LBlockWidth: Integer;
  LFrames: Int64;
  LCount: Integer;
  LData: TBytes;
  LIndex: Integer;
  LInput: PByte;
  LInfo: TSoundFileInfo;
  LValue: Cardinal;
  LItemBytes, LExtraItems, LTailItems: Integer;
  LSampleBytes: Integer;
  LPartialCount: Integer;
  LPartial: TBytes;
  LRemaining: Int64;

  function Fetch16(AOffset: Integer): Word;
  begin
    if ABigEndian then
      Result := (Word(LInput[AOffset]) shl 8) or LInput[AOffset + 1]
    else
      Result := (Word(LInput[AOffset + 1]) shl 8) or LInput[AOffset];
  end;

  function Fetch32(AOffset: Integer): Cardinal;
  begin
    if ABigEndian then
      Result := (Cardinal(LInput[AOffset]) shl 24) or (Cardinal(LInput[AOffset + 1]) shl 16) or
        (Cardinal(LInput[AOffset + 2]) shl 8) or LInput[AOffset + 3]
    else
      Result := (Cardinal(LInput[AOffset + 3]) shl 24) or (Cardinal(LInput[AOffset + 2]) shl 16) or
        (Cardinal(LInput[AOffset + 1]) shl 8) or LInput[AOffset];
  end;

begin
  ASamples := nil;
  LEncoding := ALayout.Encoding;
  if (ALayout.Channels < 1) or (ALayout.BytesPerSample < 1) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  case LEncoding of
    SNDFILE_FORMAT_PCM_S8, SNDFILE_FORMAT_PCM_U8, SNDFILE_FORMAT_ULAW,
    SNDFILE_FORMAT_ALAW, SNDFILE_FORMAT_PCM_16:
      LKind := TSoundSampleKind.Int16;
    SNDFILE_FORMAT_PCM_24, SNDFILE_FORMAT_PCM_32:
      LKind := TSoundSampleKind.Int32;
    SNDFILE_FORMAT_FLOAT:
      LKind := TSoundSampleKind.Float32;
  else
    LKind := TSoundSampleKind.Float64;
  end;

  LBlockWidth := ALayout.Channels * ALayout.BytesPerSample;
  if (LEncoding = SNDFILE_FORMAT_ULAW) or (LEncoding = SNDFILE_FORMAT_ALAW) then
    LBlockWidth := ALayout.Channels;

  LFrames := ADataLength div LBlockWidth;
  LCount := Integer(LFrames * ALayout.Channels);

  // What the file holds after the last frame: libsndfile reads it too
  if LBlockWidth = ALayout.Channels then
    LItemBytes := 1
  else
    LItemBytes := ALayout.BytesPerSample;
  LRemaining := AFileLength - ADataOffset - LFrames * LBlockWidth;
  if LRemaining < 0 then
    LRemaining := 0;
  LExtraItems := Integer(LRemaining div LItemBytes);
  LTailItems := LExtraItems;
  if LTailItems > ALayout.Channels then
    LTailItems := ALayout.Channels;

  LSampleBytes := TSoundSamples.BytesPerSample(LKind);
  SetLength(LData, (LCount + LTailItems) * LSampleBytes);

  if LCount + LTailItems > 0 then
  begin
    LInput := @ASource[Integer(ADataOffset)];
    for LIndex := 0 to LCount + LTailItems - 1 do
      case LEncoding of
        SNDFILE_FORMAT_PCM_S8:
          PSmallInt(LData)[LIndex] := SmallInt(ShortInt(LInput[LIndex])) shl 8;
        SNDFILE_FORMAT_PCM_U8:
          PSmallInt(LData)[LIndex] := SmallInt((Integer(LInput[LIndex]) - 128) shl 8);
        SNDFILE_FORMAT_ULAW:
          PSmallInt(LData)[LIndex] := ULAW_DECODE[LInput[LIndex]];
        SNDFILE_FORMAT_ALAW:
          PSmallInt(LData)[LIndex] := ALAW_DECODE[LInput[LIndex]];
        SNDFILE_FORMAT_PCM_16:
          PSmallInt(LData)[LIndex] := SmallInt(Fetch16(LIndex * 2));
        SNDFILE_FORMAT_PCM_24:
          begin
            if ABigEndian then
              LValue := (Cardinal(LInput[LIndex * 3]) shl 24) or
                (Cardinal(LInput[LIndex * 3 + 1]) shl 16) or (Cardinal(LInput[LIndex * 3 + 2]) shl 8)
            else
              LValue := (Cardinal(LInput[LIndex * 3 + 2]) shl 24) or
                (Cardinal(LInput[LIndex * 3 + 1]) shl 16) or (Cardinal(LInput[LIndex * 3]) shl 8);
            PInteger(LData)[LIndex] := Integer(LValue);
          end;
        SNDFILE_FORMAT_PCM_32, SNDFILE_FORMAT_FLOAT:
          PCardinal(LData)[LIndex] := Fetch32(LIndex * 4);
      else
        begin
          // 64 bit: the two halves in the order of the file
          if ABigEndian then
            PCardinal(LData)[LIndex * 2] := Fetch32(LIndex * 8 + 4)
          else
            PCardinal(LData)[LIndex * 2] := Fetch32(LIndex * 8);
          if ABigEndian then
            PCardinal(LData)[LIndex * 2 + 1] := Fetch32(LIndex * 8)
          else
            PCardinal(LData)[LIndex * 2 + 1] := Fetch32(LIndex * 8 + 4);
        end;
      end;
  end;

  FillChar(LInfo, SizeOf(LInfo), 0);
  LInfo.Frames := LFrames;
  LInfo.SampleRate := ALayout.SampleRate;
  LInfo.Channels := ALayout.Channels;
  LInfo.Format := ALayout.Format;
  LInfo.Sections := 1;
  LInfo.Seekable := 1;

  ASamples := TSoundSamples.Create(LInfo, LKind, Copy(LData, 0, LCount * LSampleBytes));
  ASamples.ExtraItems := LExtraItems;
  ASamples.Tail := Copy(LData, LCount * LSampleBytes, LTailItems * LSampleBytes);

  // 16 and 32 bit samples are read straight into a buffer of the same width
  if (LEncoding = SNDFILE_FORMAT_PCM_16) or (LEncoding = SNDFILE_FORMAT_PCM_32) then
  begin
    ASamples.ReadsDirectly := True;
    ASamples.BigEndian := ABigEndian;
    LPartialCount := Integer(LRemaining mod LItemBytes);
    if LPartialCount > 0 then
    begin
      SetLength(LPartial, LPartialCount);
      Move(ASource[Integer(ADataOffset + LFrames * LBlockWidth) + LExtraItems * LItemBytes],
        LPartial[0], LPartialCount);
      ASamples.PartialBytes := LPartial;
    end;
  end;
  Result := SNDFILE_OK;
end;

end.
