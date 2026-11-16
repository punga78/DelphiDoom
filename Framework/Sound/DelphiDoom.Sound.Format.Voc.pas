{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Creative Voice File (VOC)                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Voc;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   VOC files with one block of sound: unsigned 8 bit (also with the
  ///   "extended" block for stereo), and the "extended II" block with 8 or 16
  ///   bit PCM, mu-law and A-law. Like libsndfile, a file made of several
  ///   blocks of sound is refused
  /// </summary>
  TVocFormat = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

uses
  DelphiDoom.Sound.ByteReader, DelphiDoom.Sound.PcmReader;

const
  VOC_SOUND_DATA = 1;
  VOC_ASCII = 5;
  VOC_REPEAT = 6;
  VOC_EXTENDED = 8;
  VOC_EXTENDED_II = 9;

  VOC_VERSION_1_10 = $010A;
  VOC_VERSION_1_20 = $0114;

  // Size of the "Creative Voice File" text, its terminator and the rest of the header
  VOC_SIGNATURE_SIZE = 20;
  VOC_SIGNATURE_END = $1A;

function ReadUInt24(var AReader: TSoundByteReader): Cardinal;
var
  LLow, LMiddle, LHigh: Cardinal;
begin
  // The numbers of the blocks are always little endian
  LLow := AReader.ReadByte;
  LMiddle := AReader.ReadByte;
  LHigh := AReader.ReadByte;
  Result := LLow or (LMiddle shl 8) or (LHigh shl 16);
end;

{ TVocFormat }

function TVocFormat.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
const
  SIGNATURE = 'Creative Voice File';
var
  LReader: TSoundByteReader;
  LFileLength: Int64;
  LIndex: Integer;
  LVersion: Word;
  LBlockType: Byte;
  LSize: Cardinal;
  LRateByte: Byte;
  LRateShort: Word;
  LStereo: Byte;
  LBitWidth, LChannels: Byte;
  LEncoding: Word;
  LOffset: Int64;
  LDataEnd: Int64;
  LDataOffset: Int64;
  LDataLength: Int64;
  LSampleRate: Integer;
  LLayout: TSoundPcmLayout;
begin
  ASamples := nil;
  LFileLength := Length(ASource);
  if LFileLength < 8 then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  LReader := TSoundByteReader.Create(ASource);
  if (LReader.ReadMarker <> TSoundByteReader.MarkerOf('Crea')) or
     (LReader.ReadMarker <> TSoundByteReader.MarkerOf('tive')) then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  if LFileLength < VOC_SIGNATURE_SIZE + 6 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  if ASource[VOC_SIGNATURE_SIZE - 1] <> VOC_SIGNATURE_END then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  for LIndex := 1 to Length(SIGNATURE) do
    if ASource[LIndex - 1] <> Byte(SIGNATURE[LIndex]) then
      Exit(SNDFILE_ERR_MALFORMED_FILE);

  // The blocks follow the fixed header, wherever its data offset says
  LReader.Position := VOC_SIGNATURE_SIZE;
  LReader.ReadUInt16;                      // data offset
  LVersion := LReader.ReadUInt16;
  LReader.ReadUInt16;                      // checksum
  if (LVersion <> VOC_VERSION_1_10) and (LVersion <> VOC_VERSION_1_20) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  // Text and repeat blocks do not matter: they are skipped
  while True do
  begin
    LBlockType := LReader.ReadByte;
    if LReader.Overrun then
      Exit(SNDFILE_ERR_MALFORMED_FILE);
    if LBlockType = VOC_ASCII then
    begin
      LSize := ReadUInt24(LReader);
      LReader.Skip(LSize);
    end
    else if LBlockType = VOC_REPEAT then
    begin
      ReadUInt24(LReader);
      LReader.ReadUInt16;
    end
    else
      Break;
  end;

  FillChar(LLayout, SizeOf(LLayout), 0);
  LLayout.Channels := 1;
  LLayout.Encoding := SNDFILE_FORMAT_PCM_U8;
  LLayout.BytesPerSample := 1;
  LDataEnd := LFileLength - 1;

  if (LBlockType = VOC_SOUND_DATA) or (LBlockType = VOC_EXTENDED) then
  begin
    LSampleRate := 0;
    if LBlockType = VOC_EXTENDED then
    begin
      ReadUInt24(LReader);                   // size, 4 in a good file
      LRateShort := LReader.ReadUInt16;
      LReader.ReadByte;                      // pack
      LStereo := LReader.ReadByte;
      if LStereo <> 0 then
      begin
        LLayout.Channels := 2;
        LSampleRate := 128000000 div (65536 - LRateShort);
      end
      else
        LSampleRate := 256000000 div (65536 - LRateShort);

      if LReader.ReadByte <> VOC_SOUND_DATA then
        Exit(SNDFILE_ERR_MALFORMED_FILE);
    end;

    LSize := ReadUInt24(LReader);
    LRateByte := LReader.ReadByte;
    LReader.ReadByte;                        // compression, not looked at
    if LBlockType = VOC_SOUND_DATA then
      LSampleRate := 1000000 div (256 - LRateByte);
    if LReader.Overrun then
      Exit(SNDFILE_ERR_MALFORMED_FILE);

    LOffset := LReader.Position;
    if LOffset + LSize - 1 > LFileLength then
      Exit(SNDFILE_ERR_MALFORMED_FILE);     // truncated
    if LBlockType = VOC_SOUND_DATA then
    begin
      if LFileLength - LOffset - LSize > 4 then
        Exit(SNDFILE_ERR_MALFORMED_FILE);   // more blocks of sound
    end
    else if LOffset + LSize - 1 < LFileLength then
      Exit(SNDFILE_ERR_MALFORMED_FILE);

    LLayout.SampleRate := LSampleRate;
    LDataOffset := LOffset;
  end
  else if LBlockType = VOC_EXTENDED_II then
  begin
    LSize := ReadUInt24(LReader);
    LLayout.SampleRate := Integer(LReader.ReadUInt32);
    LBitWidth := LReader.ReadByte;
    LChannels := LReader.ReadByte;
    LEncoding := LReader.ReadUInt16;
    LReader.ReadUInt32;                      // reserved
    if LReader.Overrun then
      Exit(SNDFILE_ERR_MALFORMED_FILE);

    // Bugs of SoX that libsndfile has learnt to live with
    if Int64(LSize) * 2 = LFileLength - 39 then
      LSize := Cardinal(LFileLength - 31);
    if (LBitWidth = 16) and (LEncoding = 0) then
      LEncoding := 4;

    LDataOffset := LReader.Position;
    if Int64(LSize) + 31 = LFileLength + 1 then
      LDataEnd := 0;                         // no terminator at the end

    case LEncoding of
      0:
        begin
          LLayout.Encoding := SNDFILE_FORMAT_PCM_U8;
          LLayout.BytesPerSample := 1;
        end;
      4:
        begin
          LLayout.Encoding := SNDFILE_FORMAT_PCM_16;
          LLayout.BytesPerSample := 2;
        end;
      6:
        begin
          LLayout.Encoding := SNDFILE_FORMAT_ALAW;
          LLayout.BytesPerSample := 1;
        end;
      7:
        begin
          LLayout.Encoding := SNDFILE_FORMAT_ULAW;
          LLayout.BytesPerSample := 1;
        end;
    else
      Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);
    end;

    if LChannels < 1 then
      Exit(SNDFILE_ERR_MALFORMED_FILE);
    LLayout.Channels := LChannels;
  end
  else
    // A terminator, silence, a marker...: no sound where libsndfile looks
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);

  LLayout.Format := SNDFILE_FORMAT_VOC or LLayout.Encoding;

  if LFileLength > LDataOffset then
  begin
    if LDataEnd > 0 then
      LDataLength := LDataEnd - LDataOffset
    else
      LDataLength := LFileLength - LDataOffset;
  end
  else
    LDataLength := 0;
  if LDataLength < 0 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  Result := TSoundPcmReader.Read(ASource, LLayout, LDataOffset, LDataLength,
    LFileLength, False, ASamples);
end;

end.
