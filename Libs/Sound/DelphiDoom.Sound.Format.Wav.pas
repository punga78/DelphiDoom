{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - WAV (RIFF/RIFX)                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Wav;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format, DelphiDoom.Sound.ByteReader, DelphiDoom.Sound.PcmReader;

type
  /// <summary>
  ///   WAV files: PCM 8/16/24/32 bit, float and double, mu-law and A-law, also
  ///   inside WAVE_FORMAT_EXTENSIBLE, little endian (RIFF) or big endian (RIFX).
  ///   The header is read the way libsndfile does, including the corrections
  ///   it makes to damaged files
  /// </summary>
  TWavFormat = class(TInterfacedObject, ISoundFormat)
  private
    type
      /// <summary>What the 'fmt ' chunk says about the samples</summary>
      TWavLayout = record
        Encoding: Integer;     // SNDFILE_FORMAT_* of the samples (width not applied yet)
        Container: Integer;    // SNDFILE_FORMAT_WAV or SNDFILE_FORMAT_WAVEX
        Channels: Integer;
        SampleRate: Integer;
        BytesPerSample: Integer;
      end;
  private
    function ResolveEncoding(const ALayout: TWavLayout;
      out AEncoding: Integer): Boolean;
    function ReadFormatChunk(var AReader: TSoundByteReader; ASize: Cardinal;
      var ALayout: TWavLayout): Integer;
    function ReadExtensible(var AReader: TSoundByteReader; ABitWidth: Integer;
      var ALayout: TWavLayout): Integer;
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

const
  WAVE_FORMAT_PCM = $0001;
  WAVE_FORMAT_IEEE_FLOAT = $0003;
  WAVE_FORMAT_ALAW = $0006;
  WAVE_FORMAT_MULAW = $0007;
  WAVE_FORMAT_EXTENSIBLE = $FFFE;

  // Stages of the header
  HAVE_RIFF = 1;
  HAVE_WAVE = 2;
  HAVE_FMT = 4;

  MAX_CHANNELS = 1024;

var
  MARKER_RIFF, MARKER_RIFX, MARKER_WAVE, MARKER_FMT, MARKER_DATA,
  MARKER_WVPK, MARKER_OGGS: Cardinal;

function IsPrintable(AValue: Cardinal): Boolean;
begin
  Result := (AValue >= 32) and (AValue <= 126);
end;

{ TWavFormat }

function TWavFormat.ReadExtensible(var AReader: TSoundByteReader;
  ABitWidth: Integer; var ALayout: TWavLayout): Integer;
const
  // Tail of the GUID of the sub formats of Microsoft: 00000001-0000-0010-8000-00AA00389B71
  MS_TAIL: array[0..7] of Byte = ($80, $00, $00, $AA, $00, $38, $9B, $71);
  // Tail of the GUID of the Ambisonic B sub formats: 00000001-0721-11D3-8644-C8C1CA000000
  AMBISONIC_TAIL: array[0..7] of Byte = ($86, $44, $C8, $C1, $CA, $00, $00, $00);
var
  LField1: Cardinal;
  LField2, LField3: Word;
  LTail: array[0..7] of Byte;
  LIndex: Integer;
  LMicrosoft, LAmbisonic: Boolean;
begin
  AReader.ReadUInt16;    // extra bytes
  AReader.ReadUInt16;    // valid bits
  AReader.ReadUInt32;    // channel mask
  LField1 := AReader.ReadUInt32;
  LField2 := AReader.ReadUInt16;
  LField3 := AReader.ReadUInt16;
  for LIndex := 0 to 7 do
    LTail[LIndex] := AReader.ReadByte;

  LMicrosoft := (LField2 = $0000) and (LField3 = $0010) and CompareMem(@LTail, @MS_TAIL, 8);
  LAmbisonic := (LField2 = $0721) and (LField3 = $11D3) and CompareMem(@LTail, @AMBISONIC_TAIL, 8);

  ALayout.Container := SNDFILE_FORMAT_WAVEX;
  ALayout.BytesPerSample := (ABitWidth + 7) div 8;
  Result := SNDFILE_OK;

  if (LMicrosoft and (LField1 = WAVE_FORMAT_PCM)) or
     (LAmbisonic and (LField1 = WAVE_FORMAT_PCM)) then
    ALayout.Encoding := SNDFILE_FORMAT_PCM_16 // the width decides, see BuildSamples
  else if (LMicrosoft and (LField1 = WAVE_FORMAT_IEEE_FLOAT)) or
          (LAmbisonic and (LField1 = WAVE_FORMAT_IEEE_FLOAT)) then
    ALayout.Encoding := SNDFILE_FORMAT_FLOAT
  else if LMicrosoft and (LField1 = WAVE_FORMAT_ALAW) then
    ALayout.Encoding := SNDFILE_FORMAT_ALAW
  else if LMicrosoft and (LField1 = WAVE_FORMAT_MULAW) then
    ALayout.Encoding := SNDFILE_FORMAT_ULAW
  else
    Result := SNDFILE_ERR_UNSUPPORTED_ENCODING;
end;

function TWavFormat.ReadFormatChunk(var AReader: TSoundByteReader;
  ASize: Cardinal; var ALayout: TWavLayout): Integer;
var
  LStart: Int64;
  LTag, LChannels, LBitWidth: Word;
  LSampleRate: Cardinal;
begin
  if ASize < 16 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  LStart := AReader.Position;
  LTag := AReader.ReadUInt16;
  LChannels := AReader.ReadUInt16;
  LSampleRate := AReader.ReadUInt32;
  AReader.ReadUInt32;                       // bytes per second
  AReader.ReadUInt16;                       // block align
  LBitWidth := AReader.ReadUInt16;

  if AReader.Overrun then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  ALayout.Channels := LChannels;
  ALayout.SampleRate := Integer(LSampleRate);
  ALayout.Container := SNDFILE_FORMAT_WAV;
  Result := SNDFILE_OK;

  case LTag of
    WAVE_FORMAT_PCM:
      begin
        ALayout.BytesPerSample := (LBitWidth + 7) div 8;
        ALayout.Encoding := SNDFILE_FORMAT_PCM_16;
      end;
    WAVE_FORMAT_IEEE_FLOAT:
      begin
        ALayout.BytesPerSample := (LBitWidth + 7) div 8;
        ALayout.Encoding := SNDFILE_FORMAT_FLOAT;
      end;
    WAVE_FORMAT_ALAW, WAVE_FORMAT_MULAW:
      begin
        ALayout.BytesPerSample := 1;
        if ASize >= 18 then
          AReader.ReadUInt16;               // extra bytes
        if LTag = WAVE_FORMAT_ALAW then
          ALayout.Encoding := SNDFILE_FORMAT_ALAW
        else
          ALayout.Encoding := SNDFILE_FORMAT_ULAW;
      end;
    WAVE_FORMAT_EXTENSIBLE:
      Result := ReadExtensible(AReader, LBitWidth, ALayout);
  else
    // ADPCM, GSM and the other codecs of WAV are not read
    Result := SNDFILE_ERR_UNSUPPORTED_ENCODING;
  end;

  if Result <> SNDFILE_OK then
    Exit;

  if AReader.Position - LStart > ASize then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  AReader.Position := LStart + ASize;
end;

function TWavFormat.ResolveEncoding(const ALayout: TWavLayout;
  out AEncoding: Integer): Boolean;
begin
  AEncoding := ALayout.Encoding;
  Result := True;

  // The width of the sample picks the encoding of the PCM and float ones
  if AEncoding = SNDFILE_FORMAT_PCM_16 then
    case ALayout.BytesPerSample of
      1: AEncoding := SNDFILE_FORMAT_PCM_U8;
      2: AEncoding := SNDFILE_FORMAT_PCM_16;
      3: AEncoding := SNDFILE_FORMAT_PCM_24;
      4: AEncoding := SNDFILE_FORMAT_PCM_32;
    else
      Result := False;
    end
  else if AEncoding = SNDFILE_FORMAT_FLOAT then
    case ALayout.BytesPerSample of
      4: AEncoding := SNDFILE_FORMAT_FLOAT;
      8: AEncoding := SNDFILE_FORMAT_DOUBLE;
    else
      Result := False;
    end;
end;

function TWavFormat.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LReader: TSoundByteReader;
  LFileLength: Int64;
  LMarker, LChunkSize, LRiffSize: Cardinal;
  LStage: Integer;
  LDone: Boolean;
  LLayout: TWavLayout;
  LPcm: TSoundPcmLayout;
  LDataOffset, LDataLength, LDataEnd: Int64;
  LBlockWidth: Integer;
  LUsable: Int64;
begin
  ASamples := nil;
  LFileLength := Length(ASource);
  LReader := TSoundByteReader.Create(ASource);

  LMarker := LReader.ReadMarker;
  if (LFileLength < 12) or ((LMarker <> MARKER_RIFF) and (LMarker <> MARKER_RIFX)) then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);
  LReader.Position := 8;
  if LReader.ReadMarker <> MARKER_WAVE then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  LReader.Position := 0;
  LReader.BigEndian := LMarker = MARKER_RIFX;
  FillChar(LLayout, SizeOf(LLayout), 0);

  LStage := 0;
  LChunkSize := 0;
  LRiffSize := 0;
  LDataOffset := 0;
  LDataLength := 0;
  LDataEnd := 0;
  LDone := False;

  while not LDone do
  begin
    LReader.Skip(LChunkSize and 1);
    LMarker := LReader.ReadMarker;
    LChunkSize := LReader.ReadUInt32;
    if LReader.Overrun then
      LMarker := 0;
    if LMarker = 0 then
      Break;

    if (LMarker = MARKER_RIFF) or (LMarker = MARKER_RIFX) then
    begin
      if LStage <> 0 then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      LStage := LStage or HAVE_RIFF;
      LRiffSize := LChunkSize;
      if LReader.ReadMarker <> MARKER_WAVE then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      LStage := LStage or HAVE_WAVE;
      LChunkSize := 0;
    end
    else if LMarker = MARKER_FMT then
    begin
      if (LStage and (HAVE_RIFF or HAVE_WAVE)) <> (HAVE_RIFF or HAVE_WAVE) then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      // A second 'fmt ' chunk is ignored, and not even skipped, as in libsndfile
      if (LStage and HAVE_FMT) = 0 then
      begin
        LStage := LStage or HAVE_FMT;
        Result := ReadFormatChunk(LReader, LChunkSize, LLayout);
        if Result <> SNDFILE_OK then
          Exit;
      end;
    end
    else if LMarker = MARKER_DATA then
    begin
      if (LStage and (HAVE_RIFF or HAVE_WAVE or HAVE_FMT)) <> (HAVE_RIFF or HAVE_WAVE or HAVE_FMT) then
        Exit(SNDFILE_ERR_MALFORMED_FILE);

      LDataLength := LChunkSize;
      LDataOffset := LReader.Position;
      if LDataOffset > 0 then
      begin
        // A file that was not closed properly has no sizes: the data is the rest
        if (LChunkSize = 0) and (LRiffSize = 8) and (LFileLength > 44) then
          LDataLength := LFileLength - LDataOffset;
        if LDataLength > LFileLength - LDataOffset then
          LDataLength := LFileLength - LDataOffset;
        // Only when something follows the data: libsndfile needs it for mu-law and A-law
        if LDataLength + LDataOffset < LFileLength then
          LDataEnd := LDataLength + LDataOffset;
        Inc(LDataLength, LChunkSize and 1);
        LChunkSize := 0;
      end;
      LReader.Skip(LDataLength);
    end
    else
    begin
      // Every other chunk: skipped. The ones that libsndfile does not know
      // are skipped too when they look like a chunk
      if LChunkSize >= $FFFF0000 then
        LDone := True
      else if IsPrintable(LMarker shr 24) and IsPrintable((LMarker shr 16) and $FF) and
              IsPrintable((LMarker shr 8) and $FF) and IsPrintable(LMarker and $FF) then
        LReader.Skip(LChunkSize)
      else if (LReader.Position and 3) <> 0 then
        LReader.Skip(-3)
      else
        LDone := True;
    end;

    if LDone then
      Break;
    if LChunkSize >= LFileLength then
      Break;
    if LReader.Position >= LFileLength - 4 then
      Break;
  end;

  if LDataOffset <= 0 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  if LLayout.Channels < 1 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  if LLayout.Channels >= MAX_CHANNELS then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  // The data of a WAV is not another container
  LReader.Position := LDataOffset;
  LMarker := LReader.ReadMarker;
  if (LMarker = MARKER_WVPK) or (LMarker = MARKER_OGGS) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  LBlockWidth := LLayout.Channels * LLayout.BytesPerSample;
  if LBlockWidth <= 0 then
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);

  LUsable := LFileLength - LDataOffset;
  if LUsable < LDataLength then
    LDataLength := LUsable;

  // The decoders of libsndfile measure the data again, without the pad byte
  if LDataEnd > 0 then
    LDataLength := LDataEnd - LDataOffset
  else
    LDataLength := LUsable;

  if not ResolveEncoding(LLayout, LPcm.Encoding) then
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);
  LPcm.Channels := LLayout.Channels;
  LPcm.SampleRate := LLayout.SampleRate;
  if (LPcm.Encoding = SNDFILE_FORMAT_ULAW) or (LPcm.Encoding = SNDFILE_FORMAT_ALAW) then
    LPcm.BytesPerSample := 1
  else
    LPcm.BytesPerSample := LLayout.BytesPerSample;
  LPcm.Format := LLayout.Container or LPcm.Encoding;
  if LReader.BigEndian then
    LPcm.Format := LPcm.Format or SNDFILE_FORMAT_ENDIAN_BIG;

  Result := TSoundPcmReader.Read(ASource, LPcm, LDataOffset, LDataLength, LFileLength,
    LReader.BigEndian, ASamples);
end;

initialization
  MARKER_RIFF := TSoundByteReader.MarkerOf('RIFF');
  MARKER_RIFX := TSoundByteReader.MarkerOf('RIFX');
  MARKER_WAVE := TSoundByteReader.MarkerOf('WAVE');
  MARKER_FMT := TSoundByteReader.MarkerOf('fmt ');
  MARKER_DATA := TSoundByteReader.MarkerOf('data');
  MARKER_WVPK := TSoundByteReader.MarkerOf('wvpk');
  MARKER_OGGS := TSoundByteReader.MarkerOf('OggS');

end.
