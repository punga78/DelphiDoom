{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - AU / SND (Sun, NeXT)                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Au;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   AU files (".snd" big endian, "dns." little endian): mu-law, A-law, PCM
  ///   8/16/24/32 bit with sign, float and double. The ADPCM encodings of the
  ///   format are not read
  /// </summary>
  TAuFormat = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

uses
  DelphiDoom.Sound.ByteReader, DelphiDoom.Sound.PcmReader,
  DelphiDoom.Sound.Codec.G72x, DelphiDoom.Sound.CodecSamples;

const
  AU_ENCODING_ULAW_8 = 1;
  AU_ENCODING_PCM_8 = 2;
  AU_ENCODING_PCM_16 = 3;
  AU_ENCODING_PCM_24 = 4;
  AU_ENCODING_PCM_32 = 5;
  AU_ENCODING_FLOAT = 6;
  AU_ENCODING_DOUBLE = 7;
  AU_ENCODING_ALAW_8 = 27;
  AU_ENCODING_G721_32 = 23;
  AU_ENCODING_G723_24 = 25;
  AU_ENCODING_G723_40 = 26;

  MAX_CHANNELS = 1024;

{ TAuFormat }

function TAuFormat.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LReader: TSoundByteReader;
  LMarker: Cardinal;
  LBigEndian: Boolean;
  LDataOffset, LDataSize, LFileLength: Int64;
  LEncoding, LChannels, LSampleRate: Integer;
  LLayout: TSoundPcmLayout;
  LBits: Integer;
  LDataLength, LFrames: Int64;
  LData: TBytes;
begin
  ASamples := nil;
  LReader := TSoundByteReader.Create(ASource);
  LMarker := LReader.ReadMarker;
  if Length(ASource) < 12 then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  if LMarker = TSoundByteReader.MarkerOf('.snd') then
    LBigEndian := True
  else if LMarker = TSoundByteReader.MarkerOf('dns.') then
    LBigEndian := False
  else
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  LReader.BigEndian := LBigEndian;
  LDataOffset := Integer(LReader.ReadUInt32);
  LDataSize := Integer(LReader.ReadUInt32);
  LEncoding := Integer(LReader.ReadUInt32);
  LSampleRate := Integer(LReader.ReadUInt32);
  LChannels := Integer(LReader.ReadUInt32);
  if LReader.Overrun then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  // The size in the header is trusted only when it is smaller than the file
  LFileLength := Length(ASource);
  if (LDataSize <> -1) and (LDataOffset + LDataSize < LFileLength) then
    LFileLength := LDataOffset + LDataSize;

  if (LDataOffset < 0) or (LDataOffset > LFileLength) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  FillChar(LLayout, SizeOf(LLayout), 0);
  case LEncoding of
    AU_ENCODING_ULAW_8:
      begin
        LLayout.Encoding := SNDFILE_FORMAT_ULAW;
        LLayout.BytesPerSample := 1;
      end;
    AU_ENCODING_PCM_8:
      begin
        LLayout.Encoding := SNDFILE_FORMAT_PCM_S8;
        LLayout.BytesPerSample := 1;
      end;
    AU_ENCODING_PCM_16:
      begin
        LLayout.Encoding := SNDFILE_FORMAT_PCM_16;
        LLayout.BytesPerSample := 2;
      end;
    AU_ENCODING_PCM_24:
      begin
        LLayout.Encoding := SNDFILE_FORMAT_PCM_24;
        LLayout.BytesPerSample := 3;
      end;
    AU_ENCODING_PCM_32:
      begin
        LLayout.Encoding := SNDFILE_FORMAT_PCM_32;
        LLayout.BytesPerSample := 4;
      end;
    AU_ENCODING_FLOAT:
      begin
        LLayout.Encoding := SNDFILE_FORMAT_FLOAT;
        LLayout.BytesPerSample := 4;
      end;
    AU_ENCODING_DOUBLE:
      begin
        LLayout.Encoding := SNDFILE_FORMAT_DOUBLE;
        LLayout.BytesPerSample := 8;
      end;
    AU_ENCODING_ALAW_8:
      begin
        LLayout.Encoding := SNDFILE_FORMAT_ALAW;
        LLayout.BytesPerSample := 1;
      end;
    AU_ENCODING_G721_32:
      LLayout.Encoding := SNDFILE_FORMAT_G721_32;
    AU_ENCODING_G723_24:
      LLayout.Encoding := SNDFILE_FORMAT_G723_24;
    AU_ENCODING_G723_40:
      LLayout.Encoding := SNDFILE_FORMAT_G723_40;
  else
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);
  end;

  if (LChannels < 1) or (LChannels > MAX_CHANNELS) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  LLayout.Channels := LChannels;
  LLayout.SampleRate := LSampleRate;
  LLayout.Format := SNDFILE_FORMAT_AU or LLayout.Encoding;
  if not LBigEndian then
    LLayout.Format := LLayout.Format or SNDFILE_FORMAT_ENDIAN_LITTLE;

  if (LLayout.Encoding = SNDFILE_FORMAT_G721_32) or (LLayout.Encoding = SNDFILE_FORMAT_G723_24) or
     (LLayout.Encoding = SNDFILE_FORMAT_G723_40) then
  begin
    // The ADPCM of G.72x is mono, and it measures the real length of the file
    if LChannels <> 1 then
      Exit(SNDFILE_ERR_MALFORMED_FILE);
    case LLayout.Encoding of
      SNDFILE_FORMAT_G721_32: LBits := 4;
      SNDFILE_FORMAT_G723_24: LBits := 3;
    else
      LBits := 5;
    end;
    LDataLength := Length(ASource) - LDataOffset;
    if LDataLength < 0 then
      LDataLength := 0;
    Result := TG72xDecoder.Decode(ASource, LDataOffset, LDataLength, LBits, LData, LFrames);
    if Result = SNDFILE_OK then
      ASamples := TSoundCodecSamples.WrapG72x(LLayout.Format, 1, LSampleRate, LFrames, LData);
    Exit;
  end;

  Result := TSoundPcmReader.Read(ASource, LLayout, LDataOffset,
    LFileLength - LDataOffset, Length(ASource), LBigEndian, ASamples);
end;

end.
