{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - IRCAM / Berkeley / CARL sound files             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Ircam;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   IRCAM files: 1024 bytes of header (marker, sample rate as a float,
  ///   channels, encoding), then 16 or 32 bit PCM, float, mu-law or A-law.
  ///   The build of libsndfile this follows only opens the little endian
  ///   files: its test for the big endian marker has the wrong constant, so
  ///   the big endian ones are refused here too
  /// </summary>
  TIrcamFormat = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

uses
  DelphiDoom.Sound.ByteReader, DelphiDoom.Sound.PcmReader;

const
  DATA_OFFSET = 1024;
  MAX_CHANNELS = 1024;

  IRCAM_PCM_16 = $00002;
  IRCAM_FLOAT = $00004;
  IRCAM_ALAW = $10001;
  IRCAM_ULAW = $20001;
  IRCAM_PCM_32 = $40004;

  // The tests of ircam_read_header, on the marker read as libsndfile reads it
  BE_MASK = $FF00FFFF;
  BE_MARKER = $000064A3;
  LE_MASK = $FFFF00FF;
  LE_MARKER = $64A30000;

{ TIrcamFormat }

function TIrcamFormat.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LReader: TSoundByteReader;
  LMarker, LRawRate, LEncoding: Cardinal;
  LRate: Single;
  LChannels: Integer;
  LBigEndian: Boolean;
  LCodec, LByteWidth: Integer;
  LLayout: TSoundPcmLayout;
  LDataLength: Int64;
  LB0, LB1, LB2, LB3: Byte;
begin
  ASamples := nil;
  if Length(ASource) < 12 then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  // How libsndfile recognises them: the bytes of the marker, in file order
  LB0 := ASource[0];
  LB1 := ASource[1];
  LB2 := ASource[2];
  LB3 := ASource[3];
  if not (((LB0 = $64) and (LB1 = $A3) and ((LB2 and $F8) = 0) and (LB3 = 0)) or
          ((LB0 = 0) and ((LB1 and $F8) = 0) and (LB2 = $A3) and (LB3 = $64))) then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  // The marker as an integer made of the bytes, first byte lowest
  LMarker := LB0 or (Cardinal(LB1) shl 8) or (Cardinal(LB2) shl 16) or (Cardinal(LB3) shl 24);
  if ((LMarker and BE_MASK) <> BE_MARKER) and ((LMarker and LE_MASK) <> LE_MARKER) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  LReader := TSoundByteReader.Create(ASource);
  LReader.BigEndian := False;
  LReader.Position := 4;
  LRawRate := LReader.ReadUInt32;
  LChannels := Integer(LReader.ReadUInt32);
  LEncoding := LReader.ReadUInt32;
  LBigEndian := False;

  // Too many channels: perhaps the file is big endian after all
  if LChannels > MAX_CHANNELS then
  begin
    LReader.BigEndian := True;
    LReader.Position := 4;
    LRawRate := LReader.ReadUInt32;
    LChannels := Integer(LReader.ReadUInt32);
    LEncoding := LReader.ReadUInt32;
    if LChannels > MAX_CHANNELS then
      Exit(SNDFILE_ERR_MALFORMED_FILE);
    LBigEndian := True;
  end;
  Move(LRawRate, LRate, SizeOf(LRate));

  case LEncoding of
    IRCAM_PCM_16:
      begin
        LCodec := SNDFILE_FORMAT_PCM_16;
        LByteWidth := 2;
      end;
    IRCAM_PCM_32:
      begin
        LCodec := SNDFILE_FORMAT_PCM_32;
        LByteWidth := 4;
      end;
    IRCAM_FLOAT:
      begin
        LCodec := SNDFILE_FORMAT_FLOAT;
        LByteWidth := 4;
      end;
    IRCAM_ALAW:
      begin
        LCodec := SNDFILE_FORMAT_ALAW;
        LByteWidth := 1;
      end;
    IRCAM_ULAW:
      begin
        LCodec := SNDFILE_FORMAT_ULAW;
        LByteWidth := 1;
      end;
  else
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  end;

  FillChar(LLayout, SizeOf(LLayout), 0);
  LLayout.Encoding := LCodec;
  LLayout.BytesPerSample := LByteWidth;
  LLayout.Channels := LChannels;
  // A float cut to an integer; what does not fit is anyone's guess
  if (LRate > -2147483648.0) and (LRate < 2147483648.0) then
    LLayout.SampleRate := Trunc(LRate)
  else
    LLayout.SampleRate := Low(Integer);
  LLayout.Format := SNDFILE_FORMAT_IRCAM or LCodec;
  if LBigEndian then
    LLayout.Format := LLayout.Format or SNDFILE_FORMAT_ENDIAN_BIG
  else
    LLayout.Format := LLayout.Format or SNDFILE_FORMAT_ENDIAN_LITTLE;

  if Length(ASource) > DATA_OFFSET then
    LDataLength := Length(ASource) - DATA_OFFSET
  else
    LDataLength := 0;
  Result := TSoundPcmReader.Read(ASource, LLayout, DATA_OFFSET, LDataLength,
    Length(ASource), LBigEndian, ASamples);
end;

end.
