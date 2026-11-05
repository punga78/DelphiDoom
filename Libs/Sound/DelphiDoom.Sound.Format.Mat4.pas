{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - MATLAB 4 (GNU Octave 2.0) files                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Mat4;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   MATLAB 4 files as libsndfile writes them: a matrix "samplerate" with
  ///   one value, then a matrix "wavedata" of channels (rows) by frames
  ///   (columns): 16 or 32 bit PCM, float or double, either byte order
  /// </summary>
  TMat4Format = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

uses
  DelphiDoom.Sound.ByteReader, DelphiDoom.Sound.PcmReader, DelphiDoom.Sound.Convert;

const
  // The markers as libsndfile reads them: the four bytes with the first one lowest
  MAT4_BE_DOUBLE = $E8030000;
  MAT4_LE_DOUBLE = $00000000;
  MAT4_BE_FLOAT = $F2030000;
  MAT4_LE_FLOAT = $0000000A;
  MAT4_BE_PCM_32 = $FC030000;
  MAT4_LE_PCM_32 = $00000014;
  MAT4_BE_PCM_16 = $06040000;
  MAT4_LE_PCM_16 = $0000001E;

  MAX_CHANNELS = 1024;
  // Size of the buffer for the name of a matrix
  NAME_BUFFER = 64;

  // The first twelve bytes of a file, as libsndfile tells MAT4 files apart
  BIG_ENDIAN_START: array[0..11] of Byte = (0, 0, $03, $E8, 0, 0, 0, 1, 0, 0, 0, 1);
  LITTLE_ENDIAN_START: array[0..11] of Byte = (0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0);

function ReadFileMarker(var AReader: TSoundByteReader): Cardinal;
var
  LValue: Cardinal;
begin
  LValue := AReader.ReadMarker;
  Result := (LValue shr 24) or ((LValue shr 8) and $FF00) or
    ((LValue shl 8) and $FF0000) or (LValue shl 24);
end;

function ReadDouble(var AReader: TSoundByteReader): Double;
var
  LFirst, LSecond: Cardinal;
  LBits: Int64;
begin
  LFirst := AReader.ReadUInt32;
  LSecond := AReader.ReadUInt32;
  // In the byte order of the reader: the first number read is the low half
  // of a little endian double and the high half of a big endian one
  if AReader.BigEndian then
    LBits := (Int64(LFirst) shl 32) or LSecond
  else
    LBits := (Int64(LSecond) shl 32) or LFirst;
  Move(LBits, Result, SizeOf(Result));
end;

{ TMat4Format }

function TMat4Format.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LReader: TSoundByteReader;
  LFileLength: Int64;
  LMarker, LNameSize: Cardinal;
  LRows, LCols, LImaginary, LSampleRate, LCodec, LByteWidth: Integer;
  LBigEndian: Boolean;
  LValue: Double;
  LDataOffset, LDataEnd, LDataLength, LExpected: Int64;
  LLayout: TSoundPcmLayout;
begin
  ASamples := nil;
  LFileLength := Length(ASource);
  if LFileLength < 12 then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);
  if CompareMem(@ASource[0], @BIG_ENDIAN_START[0], 12) then
    LBigEndian := True
  else if CompareMem(@ASource[0], @LITTLE_ENDIAN_START[0], 12) then
    LBigEndian := False
  else
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  LReader := TSoundByteReader.Create(ASource);
  LReader.BigEndian := LBigEndian;
  LReader.Position := 4;

  // The matrix of the sample rate
  LRows := Integer(LReader.ReadUInt32);
  LCols := Integer(LReader.ReadUInt32);
  LImaginary := Integer(LReader.ReadUInt32);
  LNameSize := LReader.ReadUInt32;
  if LNameSize >= NAME_BUFFER then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  LReader.Skip(LNameSize);
  LValue := ReadDouble(LReader);
  if (LRows <> 1) or (LCols <> 1) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  LSampleRate := TSoundConvert.RoundToLong(LValue);

  // The matrix of the samples
  LMarker := ReadFileMarker(LReader);
  LRows := Integer(LReader.ReadUInt32);
  LCols := Integer(LReader.ReadUInt32);
  LImaginary := Integer(LReader.ReadUInt32);
  LNameSize := LReader.ReadUInt32;
  if LNameSize >= NAME_BUFFER then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  LReader.Skip(LNameSize);
  LDataOffset := LReader.Position;

  if LRows = 0 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  if LRows > MAX_CHANNELS then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  case LMarker of
    MAT4_BE_DOUBLE, MAT4_LE_DOUBLE:
      begin
        LCodec := SNDFILE_FORMAT_DOUBLE;
        LByteWidth := 8;
      end;
    MAT4_BE_FLOAT, MAT4_LE_FLOAT:
      begin
        LCodec := SNDFILE_FORMAT_FLOAT;
        LByteWidth := 4;
      end;
    MAT4_BE_PCM_32, MAT4_LE_PCM_32:
      begin
        LCodec := SNDFILE_FORMAT_PCM_32;
        LByteWidth := 4;
      end;
    MAT4_BE_PCM_16, MAT4_LE_PCM_16:
      begin
        LCodec := SNDFILE_FORMAT_PCM_16;
        LByteWidth := 2;
      end;
  else
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);
  end;

  // A file with more than the matrix needs: the sound stops where the matrix does
  // (32 bit arithmetic, as in libsndfile)
  LDataEnd := 0;
  LExpected := Int64(LRows) * LCols * LByteWidth;
  if LFileLength - LDataOffset > LExpected then
    LDataEnd := LDataOffset + Int64(Integer(Int64(LRows) * LCols)) * LByteWidth;

  FillChar(LLayout, SizeOf(LLayout), 0);
  LLayout.Encoding := LCodec;
  LLayout.BytesPerSample := LByteWidth;
  LLayout.Channels := LRows;
  LLayout.SampleRate := LSampleRate;
  LLayout.Format := SNDFILE_FORMAT_MAT4 or LCodec;
  if LBigEndian then
    LLayout.Format := LLayout.Format or SNDFILE_FORMAT_ENDIAN_BIG
  else
    LLayout.Format := LLayout.Format or SNDFILE_FORMAT_ENDIAN_LITTLE;

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
    LFileLength, LBigEndian, ASamples);
end;

end.
