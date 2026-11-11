{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Amiga 8SVX and 16SV files                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Svx;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   IFF 8SVX (8 bit) and 16SV (16 bit) files, uncompressed, big endian.
  ///   As in libsndfile, the sound is everything after the BODY header, not
  ///   only what the size of the BODY chunk says
  /// </summary>
  TSvxFormat = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

uses
  DelphiDoom.Sound.ByteReader, DelphiDoom.Sound.PcmReader;

const
  HAVE_FORM = $01;
  HAVE_SVX = $02;
  HAVE_VHDR = $04;
  HAVE_BODY = $08;

  // Size of the buffer libsndfile keeps the name of the file in
  MAX_NAME_LENGTH = 255;

var
  MARKER_FORM, MARKER_SVX8, MARKER_SV16, MARKER_VHDR, MARKER_BODY, MARKER_COPYRIGHT,
  MARKER_NAME, MARKER_AUTH, MARKER_ANNO, MARKER_CHAN: Cardinal;

{ TSvxFormat }

function TSvxFormat.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LReader: TSoundByteReader;
  LFileLength: Int64;
  LMarker, LChunkSize, LFileType: Cardinal;
  LStage: Integer;
  LDone: Boolean;
  LSampleRate: Word;
  LCompression: Byte;
  LChannels, LByteWidth, LByteCount, LNameLength: Integer;
  LDataOffset, LDataLength: Int64;
  LCodec: Integer;
  LLayout: TSoundPcmLayout;
begin
  ASamples := nil;
  LFileLength := Length(ASource);
  LReader := TSoundByteReader.Create(ASource);
  LReader.BigEndian := True;
  // What libsndfile looks for to pick this format
  if LFileLength < 12 then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);
  if LReader.ReadMarker <> MARKER_FORM then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);
  LReader.Position := 8;
  LMarker := LReader.ReadMarker;
  if (LMarker <> MARKER_SVX8) and (LMarker <> MARKER_SV16) then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);
  LReader.Position := 0;

  LStage := 0;
  LDone := False;
  LFileType := 0;
  LSampleRate := 0;
  LCompression := 0;
  LChannels := 1;
  LByteWidth := 0;
  LByteCount := 0;
  LNameLength := 0;
  LDataOffset := 0;
  LCodec := 0;

  while not LDone do
  begin
    LMarker := LReader.ReadMarker;
    LChunkSize := LReader.ReadUInt32;

    if LMarker = MARKER_FORM then
    begin
      if LStage <> 0 then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      LStage := LStage or HAVE_FORM;
      LFileType := LReader.ReadMarker;
      LStage := LStage or HAVE_SVX;
    end
    else if LMarker = MARKER_VHDR then
    begin
      if (LStage and (HAVE_FORM or HAVE_SVX)) = 0 then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      // One shot, repeat and cycle sizes
      LReader.Skip(12);
      LSampleRate := LReader.ReadUInt16;
      LReader.ReadByte;                  // octave
      LCompression := LReader.ReadByte;
      LReader.ReadUInt32;                // volume
      if LFileType = MARKER_SVX8 then
      begin
        LCodec := SNDFILE_FORMAT_PCM_S8;
        LByteWidth := 1;
      end
      else if LFileType = MARKER_SV16 then
      begin
        LCodec := SNDFILE_FORMAT_PCM_16;
        LByteWidth := 2;
      end;
      LStage := LStage or HAVE_VHDR;
    end
    else if LMarker = MARKER_BODY then
    begin
      if (LStage and HAVE_VHDR) = 0 then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      LDataLength := LChunkSize;
      LDataOffset := LReader.Position;
      if LDataLength > LFileLength - LDataOffset then
        LDataLength := LFileLength - LDataOffset;
      LStage := LStage or HAVE_BODY;
      LReader.Skip(LDataLength);
    end
    else if LMarker = MARKER_NAME then
    begin
      if (LStage and HAVE_SVX) = 0 then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      // libsndfile stores the text as the name of the file
      if LNameLength <> Integer(LChunkSize) then
      begin
        if LChunkSize > MAX_NAME_LENGTH then
          Exit(SNDFILE_ERR_MALFORMED_FILE);
        LNameLength := Integer(LChunkSize);
      end;
      LReader.Skip(LChunkSize);
    end
    else if LMarker = MARKER_CHAN then
    begin
      if (LStage and HAVE_SVX) = 0 then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      LByteCount := LByteCount + 4;
      if Integer(LReader.ReadUInt32) = 6 then
        LChannels := 2;
      // The count carries over from one CHAN chunk to the next
      LReader.Skip(Integer(LChunkSize) - LByteCount);
    end
    else if (LMarker = MARKER_ANNO) or (LMarker = MARKER_AUTH) or (LMarker = MARKER_COPYRIGHT) then
    begin
      if (LStage and HAVE_SVX) = 0 then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
      LReader.Skip(LChunkSize);
    end
    else
    begin
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
    if LReader.Position >= LFileLength - 4 then
      Break;
  end;

  if LCompression <> 0 then
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);
  if LDataOffset <= 0 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  if LCodec = 0 then
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);

  FillChar(LLayout, SizeOf(LLayout), 0);
  LLayout.Encoding := LCodec;
  LLayout.BytesPerSample := LByteWidth;
  LLayout.Channels := LChannels;
  LLayout.SampleRate := LSampleRate;
  LLayout.Format := SNDFILE_FORMAT_SVX or LCodec;

  // The decoders measure the data again: up to the end of the file
  if LFileLength > LDataOffset then
    LDataLength := LFileLength - LDataOffset
  else
    LDataLength := 0;
  Result := TSoundPcmReader.Read(ASource, LLayout, LDataOffset, LDataLength,
    LFileLength, True, ASamples);
end;

initialization
  MARKER_FORM := TSoundByteReader.MarkerOf('FORM');
  MARKER_SVX8 := TSoundByteReader.MarkerOf('8SVX');
  MARKER_SV16 := TSoundByteReader.MarkerOf('16SV');
  MARKER_VHDR := TSoundByteReader.MarkerOf('VHDR');
  MARKER_BODY := TSoundByteReader.MarkerOf('BODY');
  MARKER_COPYRIGHT := TSoundByteReader.MarkerOf('{c} ');
  MARKER_NAME := TSoundByteReader.MarkerOf('NAME');
  MARKER_AUTH := TSoundByteReader.MarkerOf('AUTH');
  MARKER_ANNO := TSoundByteReader.MarkerOf('ANNO');
  MARKER_CHAN := TSoundByteReader.MarkerOf('CHAN');

end.
