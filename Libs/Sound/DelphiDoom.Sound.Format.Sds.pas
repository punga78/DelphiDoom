{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - MIDI Sample Dump Standard files                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Sds;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   SDS files: a header of 21 bytes (seven bit numbers) and packets of 127
  ///   bytes that hold 60, 40 or 30 samples of 2, 3 or 4 bytes of seven bits.
  ///   As libsndfile does, the samples of a last packet that is not whole are
  ///   zero, and a sound that is shorter than a packet has none
  /// </summary>
  TSdsFormat = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

const
  DATA_OFFSET = $15;
  BLOCK_SIZE = 127;
  AUDIO_BYTES_PER_BLOCK = 120;

/// <summary>The three bytes of a number of seven bit groups, as they come (least significant first)</summary>
function Decode3Bytes(AValue: Cardinal): Cardinal;
begin
  Result := (AValue and $7F) or ((AValue and $7F00) shr 1) or ((AValue and $7F0000) shr 2);
end;

{ TSdsFormat }

function TSdsFormat.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LLength: Integer;

  function At(AIndex: Integer): Cardinal;
  begin
    // the header reader of libsndfile gets zeros past the end
    if AIndex < LLength then
      Result := ASource[AIndex]
    else
      Result := 0;
  end;

  function Little(AIndex, ACount: Integer): Cardinal;
  var
    LByte: Integer;
  begin
    Result := 0;
    for LByte := ACount - 1 downto 0 do
      Result := (Result shl 8) or At(AIndex + LByte);
  end;

var
  LBitWidth: Integer;
  LPeriod, LFrames: Cardinal;
  LInfo: TSoundFileInfo;
  LBytesRead, LBlockCount, LPosition, LSamplesPerBlock, LBytesPerSample: Integer;
  LMarker: Cardinal;
  LBlocks, LBlock, LIndex, LSample, LAvailable: Integer;
  LData: TArray<Integer>;
  LBuffer: array[0..BLOCK_SIZE - 1] of Byte;
  LValue: Cardinal;
  LBytes: TBytes;
  LCodec: Integer;
begin
  ASamples := nil;
  LLength := Length(ASource);
  // The mask libsndfile uses: F0 7E, a channel of seven bits, 01
  if (LLength < 4) or (ASource[0] <> $F0) or (ASource[1] <> $7E) or
     ((ASource[2] and $80) <> 0) or (ASource[3] <> $01) then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  LBitWidth := At(6);
  if LBitWidth <= 1 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  LPeriod := Decode3Bytes(Little(7, 3));
  LFrames := Decode3Bytes(Little(10, 3));

  FillChar(LInfo, SizeOf(LInfo), 0);
  if LPeriod > 0 then
    LInfo.SampleRate := Integer(1000000000 div LPeriod)
  else
    LInfo.SampleRate := 16000;
  LInfo.Frames := LFrames;
  LInfo.Channels := 1;
  LInfo.Sections := 1;
  LInfo.Seekable := 1;

  // the packets in the file: they end at a marker of zero or at the end
  LBytesRead := DATA_OFFSET;
  LBlockCount := 0;
  LPosition := DATA_OFFSET;
  LMarker := $F07E;
  while LBytesRead < LLength do
  begin
    // an incomplete marker keeps the part that was not read
    if LPosition + 1 < LLength then
      LMarker := At(LPosition) or (At(LPosition + 1) shl 8)
    else if LPosition < LLength then
      LMarker := (LMarker and $FF00) or At(LPosition);
    if LLength - LPosition > 2 then
      Inc(LBytesRead, 2)
    else if LLength - LPosition > 0 then
      Inc(LBytesRead, LLength - LPosition);
    if LMarker = 0 then
      Break;
    Inc(LBytesRead, BLOCK_SIZE - 2);
    Inc(LPosition, BLOCK_SIZE);
    Inc(LBlockCount);
  end;

  if (LBitWidth < 8) or (LBitWidth > 28) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  if LBitWidth < 14 then
    LBytesPerSample := 2
  else if LBitWidth < 21 then
    LBytesPerSample := 3
  else
    LBytesPerSample := 4;
  LSamplesPerBlock := AUDIO_BYTES_PER_BLOCK div LBytesPerSample;

  case (LBitWidth + 7) div 8 of
    1: LCodec := SNDFILE_FORMAT_PCM_S8;
    2: LCodec := SNDFILE_FORMAT_PCM_16;
    3: LCodec := SNDFILE_FORMAT_PCM_24;
  else
    LCodec := SNDFILE_FORMAT_PCM_32;
  end;
  LInfo.Format := SNDFILE_FORMAT_SDS or LCodec;

  // A sound of one packet or less is not read at all
  if (LFrames <= Cardinal(LSamplesPerBlock)) and (LFrames > 0) then
  begin
    ASamples := TSoundSamples.Create(LInfo, TSoundSampleKind.Int32, nil, 0);
    ASamples.ZeroFillChunk := -1;
    ASamples.SeekLimit := Int64(LBlockCount + 1) * LSamplesPerBlock;
    Exit(SNDFILE_OK);
  end;

  SetLength(LData, LFrames);
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  LBlocks := Integer(LFrames) div LSamplesPerBlock;
  for LBlock := 0 to LBlocks - 1 do
  begin
    // a packet that the file does not have whole keeps what the last one left
    LPosition := DATA_OFFSET + LBlock * BLOCK_SIZE;
    LAvailable := LLength - LPosition;
    if LAvailable > BLOCK_SIZE then
      LAvailable := BLOCK_SIZE;
    if LAvailable > 0 then
      Move(ASource[LPosition], LBuffer[0], LAvailable);

    for LIndex := 0 to LSamplesPerBlock - 1 do
    begin
      LSample := 5 + LIndex * LBytesPerSample;
      case LBytesPerSample of
        2: LValue := (Cardinal(LBuffer[LSample]) shl 25) + (Cardinal(LBuffer[LSample + 1]) shl 18);
        3: LValue := (Cardinal(LBuffer[LSample]) shl 25) + (Cardinal(LBuffer[LSample + 1]) shl 18) +
             (Cardinal(LBuffer[LSample + 2]) shl 11);
      else
        LValue := (Cardinal(LBuffer[LSample]) shl 25) + (Cardinal(LBuffer[LSample + 1]) shl 18) +
          (Cardinal(LBuffer[LSample + 2]) shl 11) + (Cardinal(LBuffer[LSample + 3]) shl 4);
      end;
      LData[LBlock * LSamplesPerBlock + LIndex] := Integer(LValue - $80000000);
    end;
  end;
  // the samples of the last packet, when it is not whole, stay zero

  SetLength(LBytes, Length(LData) * SizeOf(Integer));
  if Length(LData) > 0 then
    Move(LData[0], LBytes[0], Length(LBytes));
  ASamples := TSoundSamples.Create(LInfo, TSoundSampleKind.Int32, LBytes, -1);
  ASamples.SeekLimit := Int64(LBlockCount + 1) * LSamplesPerBlock;
  Result := SNDFILE_OK;
end;

end.
