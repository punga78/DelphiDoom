{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - 'fmt ' chunk shared by WAV, W64 and RF64        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.WavLike.Fmt;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.ByteReader;

type
  /// <summary>What the 'fmt ' chunk says about the samples</summary>
  TWavLikeLayout = record
    /// <summary>The format tag of the chunk (WAVE_FORMAT_*)</summary>
    Tag: Word;
    /// <summary>SNDFILE_FORMAT_* of the samples (width not applied yet)</summary>
    Encoding: Integer;
    /// <summary>SNDFILE_FORMAT_WAV or SNDFILE_FORMAT_WAVEX</summary>
    Container: Integer;
    Channels: Integer;
    SampleRate: Integer;
    BytesPerSample: Integer;
  end;

  /// <summary>
  ///   Reads the 'fmt ' chunk the way wavlike_read_fmt_chunk of libsndfile
  ///   does: WAV, W64 and RF64 files share it
  /// </summary>
  TWavLikeFmtChunk = class
  public
    const
      WAVE_FORMAT_PCM = $0001;
      WAVE_FORMAT_IEEE_FLOAT = $0003;
      WAVE_FORMAT_ALAW = $0006;
      WAVE_FORMAT_MULAW = $0007;
      WAVE_FORMAT_EXTENSIBLE = $FFFE;
    /// <summary>
    ///   Reads a chunk of ASize bytes from the position of AReader and leaves
    ///   the reader at its end
    /// </summary>
    class function Read(var AReader: TSoundByteReader; ASize: Cardinal;
      var ALayout: TWavLikeLayout): Integer; static;
    /// <summary>The encoding of the samples: the width picks PCM and float ones</summary>
    class function ResolveEncoding(const ALayout: TWavLikeLayout;
      out AEncoding: Integer): Boolean; static;
  end;

implementation

function ReadExtensible(var AReader: TSoundByteReader; ABitWidth: Integer;
  var ALayout: TWavLikeLayout): Integer;
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

  if (LMicrosoft and (LField1 = TWavLikeFmtChunk.WAVE_FORMAT_PCM)) or
     (LAmbisonic and (LField1 = TWavLikeFmtChunk.WAVE_FORMAT_PCM)) then
    ALayout.Encoding := SNDFILE_FORMAT_PCM_16 // the width decides, see ResolveEncoding
  else if (LMicrosoft and (LField1 = TWavLikeFmtChunk.WAVE_FORMAT_IEEE_FLOAT)) or
          (LAmbisonic and (LField1 = TWavLikeFmtChunk.WAVE_FORMAT_IEEE_FLOAT)) then
    ALayout.Encoding := SNDFILE_FORMAT_FLOAT
  else if LMicrosoft and (LField1 = TWavLikeFmtChunk.WAVE_FORMAT_ALAW) then
    ALayout.Encoding := SNDFILE_FORMAT_ALAW
  else if LMicrosoft and (LField1 = TWavLikeFmtChunk.WAVE_FORMAT_MULAW) then
    ALayout.Encoding := SNDFILE_FORMAT_ULAW
  else
    Result := SNDFILE_ERR_UNSUPPORTED_ENCODING;
end;

{ TWavLikeFmtChunk }

class function TWavLikeFmtChunk.Read(var AReader: TSoundByteReader;
  ASize: Cardinal; var ALayout: TWavLikeLayout): Integer;
var
  LStart: Int64;
  LChannels, LBitWidth: Word;
  LSampleRate: Cardinal;
begin
  if ASize < 16 then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  LStart := AReader.Position;
  ALayout.Tag := AReader.ReadUInt16;
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

  case ALayout.Tag of
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
        if ALayout.Tag = WAVE_FORMAT_ALAW then
          ALayout.Encoding := SNDFILE_FORMAT_ALAW
        else
          ALayout.Encoding := SNDFILE_FORMAT_ULAW;
      end;
    WAVE_FORMAT_EXTENSIBLE:
      Result := ReadExtensible(AReader, LBitWidth, ALayout);
  else
    // ADPCM, GSM and the other codecs are not read
    Result := SNDFILE_ERR_UNSUPPORTED_ENCODING;
  end;

  if Result <> SNDFILE_OK then
    Exit;

  if AReader.Position - LStart > ASize then
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  AReader.Position := LStart + ASize;
end;

class function TWavLikeFmtChunk.ResolveEncoding(const ALayout: TWavLikeLayout;
  out AEncoding: Integer): Boolean;
begin
  AEncoding := ALayout.Encoding;
  Result := True;

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

end.
