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
  DelphiDoom.Sound.Format, DelphiDoom.Sound.ByteReader, DelphiDoom.Sound.PcmReader,
  DelphiDoom.Sound.WavLike.Fmt;

type
  /// <summary>
  ///   WAV files: PCM 8/16/24/32 bit, float and double, mu-law and A-law, also
  ///   inside WAVE_FORMAT_EXTENSIBLE, little endian (RIFF) or big endian (RIFX).
  ///   The header is read the way libsndfile does, including the corrections
  ///   it makes to damaged files
  /// </summary>
  TWavFormat = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

const
  // Stages of the header
  HAVE_RIFF = 1;
  HAVE_WAVE = 2;
  HAVE_FMT = 4;

  MAX_CHANNELS = 1024;

var
  MARKER_RIFF, MARKER_RIFX, MARKER_WAVE, MARKER_FMT, MARKER_DATA,
  MARKER_WVPK, MARKER_OGGS: Cardinal;

{ TWavFormat }

function TWavFormat.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LReader: TSoundByteReader;
  LFileLength: Int64;
  LMarker, LChunkSize, LRiffSize: Cardinal;
  LStage: Integer;
  LDone: Boolean;
  LLayout: TWavLikeLayout;
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
        Result := TWavLikeFmtChunk.Read(LReader, LChunkSize, LLayout);
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
      else if TSoundByteReader.IsPrintable(LMarker shr 24) and
              TSoundByteReader.IsPrintable((LMarker shr 16) and $FF) and
              TSoundByteReader.IsPrintable((LMarker shr 8) and $FF) and
              TSoundByteReader.IsPrintable(LMarker and $FF) then
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

  if not TWavLikeFmtChunk.ResolveEncoding(LLayout, LPcm.Encoding) then
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
