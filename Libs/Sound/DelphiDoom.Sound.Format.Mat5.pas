{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - MATLAB 5 files                                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Mat5;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   MATLAB 5 files as libsndfile writes them: one matrix "samplerate"
  ///   (optional) and one of the samples, channels by frames, as 8 bit
  ///   unsigned, 16 or 32 bit PCM, float or double, either byte order. The
  ///   header is walked in order, without looking at the sizes of the blocks
  /// </summary>
  TMat5Format = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

uses
  DelphiDoom.Sound.ByteReader, DelphiDoom.Sound.PcmReader, DelphiDoom.Sound.Convert;

const
  TEXT_LENGTH = 124;
  // Size of the buffer for the name of a matrix
  NAME_BUFFER = 32;
  IM_MARKER = $494D;
  MI_MARKER = $4D49;

  MAT5_TYPE_SCHAR = $1;
  MAT5_TYPE_UCHAR = $2;
  MAT5_TYPE_INT16 = $3;
  MAT5_TYPE_INT32 = $5;
  MAT5_TYPE_UINT32 = $6;
  MAT5_TYPE_FLOAT = $7;
  MAT5_TYPE_DOUBLE = $9;
  MAT5_TYPE_ARRAY = $E;
  MAT5_TYPE_COMP_USHORT = $00020004;
  MAT5_TYPE_COMP_UINT = $00040006;

function ReadDouble(var AReader: TSoundByteReader): Double;
var
  LFirst, LSecond: Cardinal;
  LBits: Int64;
begin
  LFirst := AReader.ReadUInt32;
  LSecond := AReader.ReadUInt32;
  if AReader.BigEndian then
    LBits := (Int64(LFirst) shl 32) or LSecond
  else
    LBits := (Int64(LSecond) shl 32) or LFirst;
  Move(LBits, Result, SizeOf(Result));
end;

/// <summary>
///   The head of an array: its tag, the flags, the dimensions and its name.
///   False (and an error) when it is not what libsndfile expects
/// </summary>
function ReadArrayHead(var AReader: TSoundByteReader; out ARows, ACols: Integer): Boolean;
var
  LType, LSize: Cardinal;
begin
  Result := False;
  LType := AReader.ReadUInt32;
  LSize := AReader.ReadUInt32;
  if LType <> MAT5_TYPE_ARRAY then
    Exit;
  LType := AReader.ReadUInt32;
  LSize := AReader.ReadUInt32;
  if LType <> MAT5_TYPE_UINT32 then
    Exit;
  AReader.ReadUInt32;                    // flags
  AReader.ReadUInt32;
  LType := AReader.ReadUInt32;
  LSize := AReader.ReadUInt32;
  if LType <> MAT5_TYPE_INT32 then
    Exit;
  ARows := Integer(AReader.ReadUInt32);
  ACols := Integer(AReader.ReadUInt32);
  Result := True;
end;

/// <summary>The name of an array: a block of its own, or packed in four bytes</summary>
function ReadName(var AReader: TSoundByteReader): Boolean;
var
  LType, LSize: Cardinal;
begin
  Result := False;
  LType := AReader.ReadUInt32;
  if LType = MAT5_TYPE_SCHAR then
  begin
    LSize := AReader.ReadUInt32;
    if LSize > NAME_BUFFER - 1 then
      Exit;
    AReader.Skip(LSize);
    AReader.Skip((8 - (LSize mod 8)) mod 8);
  end
  else if (LType and $FFFF) = MAT5_TYPE_SCHAR then
  begin
    LSize := LType shr 16;
    if LSize > 4 then
      Exit;
    AReader.ReadUInt32;
  end
  else
    Exit;
  Result := True;
end;

{ TMat5Format }

function TMat5Format.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LReader: TSoundByteReader;
  LFileLength: Int64;
  LIndex: Integer;
  LEndianMark: Word;
  LBigEndian, LHaveSampleRate, LTerminated: Boolean;
  LType, LSize: Cardinal;
  LRows, LCols, LSampleRate, LCodec, LByteWidth: Integer;
  LShort: Word;
  LLayout: TSoundPcmLayout;
  LDataOffset, LDataLength: Int64;
begin
  ASamples := nil;
  LFileLength := Length(ASource);
  LReader := TSoundByteReader.Create(ASource);
  if (LFileLength < 12) or (LReader.ReadMarker <> TSoundByteReader.MarkerOf('MATL')) or
     (LReader.ReadMarker <> TSoundByteReader.MarkerOf('AB 5')) then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  // The text of the header has to end inside its 124 bytes
  LTerminated := LFileLength < TEXT_LENGTH;
  for LIndex := 0 to TEXT_LENGTH - 1 do
    if (LIndex < LFileLength) and (ASource[LIndex] = 0) then
    begin
      LTerminated := True;
      Break;
    end;
  if not LTerminated then
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);

  LReader.Position := TEXT_LENGTH;
  LReader.BigEndian := True;
  LReader.ReadUInt16;                    // version
  LEndianMark := LReader.ReadUInt16;
  if LEndianMark = MI_MARKER then
    LBigEndian := True
  else if LEndianMark = IM_MARKER then
    LBigEndian := False
  else
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  LReader.BigEndian := LBigEndian;

  // The first array: the sample rate, unless it is the samples themselves
  if not ReadArrayHead(LReader, LRows, LCols) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  LSampleRate := 0;
  LHaveSampleRate := True;
  if (LRows <> 1) or (LCols <> 1) then
  begin
    LSampleRate := 44100;
    LHaveSampleRate := False;
  end;
  if not ReadName(LReader) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  LType := LReader.ReadUInt32;
  LSize := LReader.ReadUInt32;

  if LHaveSampleRate then
  begin
    case LType of
      MAT5_TYPE_DOUBLE:
        LSampleRate := TSoundConvert.RoundToLong(ReadDouble(LReader));
      MAT5_TYPE_COMP_USHORT:
        begin
          // The value sits in the second half of the tag
          LReader.Skip(-4);
          LShort := LReader.ReadUInt16;
          LReader.Skip(2);
          LSampleRate := LShort;
        end;
      MAT5_TYPE_COMP_UINT:
        LSampleRate := Integer(LSize);
    else
      Exit(SNDFILE_ERR_MALFORMED_FILE);
    end;

    // The second array: the samples
    if not ReadArrayHead(LReader, LRows, LCols) then
      Exit(SNDFILE_ERR_MALFORMED_FILE);
    if not ReadName(LReader) then
      Exit(SNDFILE_ERR_MALFORMED_FILE);
    LType := LReader.ReadUInt32;
    LSize := LReader.ReadUInt32;
  end;

  if (LRows = 0) and (LCols = 0) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  case LType of
    MAT5_TYPE_DOUBLE:
      begin
        LCodec := SNDFILE_FORMAT_DOUBLE;
        LByteWidth := 8;
      end;
    MAT5_TYPE_FLOAT:
      begin
        LCodec := SNDFILE_FORMAT_FLOAT;
        LByteWidth := 4;
      end;
    MAT5_TYPE_INT32:
      begin
        LCodec := SNDFILE_FORMAT_PCM_32;
        LByteWidth := 4;
      end;
    MAT5_TYPE_INT16:
      begin
        LCodec := SNDFILE_FORMAT_PCM_16;
        LByteWidth := 2;
      end;
    MAT5_TYPE_UCHAR:
      begin
        LCodec := SNDFILE_FORMAT_PCM_U8;
        LByteWidth := 1;
      end;
  else
    Exit(SNDFILE_ERR_UNSUPPORTED_ENCODING);
  end;

  LDataOffset := LReader.Position;
  if LFileLength > LDataOffset then
    LDataLength := LFileLength - LDataOffset
  else
    LDataLength := 0;

  FillChar(LLayout, SizeOf(LLayout), 0);
  LLayout.Encoding := LCodec;
  LLayout.BytesPerSample := LByteWidth;
  LLayout.Channels := LRows;
  LLayout.SampleRate := LSampleRate;
  LLayout.Format := SNDFILE_FORMAT_MAT5 or LCodec;
  if LBigEndian then
    LLayout.Format := LLayout.Format or SNDFILE_FORMAT_ENDIAN_BIG
  else
    LLayout.Format := LLayout.Format or SNDFILE_FORMAT_ENDIAN_LITTLE;

  Result := TSoundPcmReader.Read(ASource, LLayout, LDataOffset, LDataLength,
    LFileLength, LBigEndian, ASamples);
end;

end.
