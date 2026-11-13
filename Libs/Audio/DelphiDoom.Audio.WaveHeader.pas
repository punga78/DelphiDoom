{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the WAVE header as the sound cache of Doom 3    }
{  reads it                                                                    }
{                                                                              }
{  Port of the WAVE reader of Doom 3 (id Software, GPL v3): sound\             }
{  snd_wavefile.cpp (idWaveFile::Open, ReadMMIO, ResetFile). Copyright (C)     }
{  1999-2011 id Software LLC, a ZeniMax Media company.                         }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.WaveHeader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   What <c>idWaveFile::Open</c> finds in the header of a WAV file: the PCM format (<c>mpwfx</c>) and where
  ///   the samples are
  /// </summary>
  TWaveHeader = record
    /// <summary>wFormatTag: always 1 (PCM), the reader refuses any other</summary>
    FormatTag: Word;
    Channels: Word;
    SamplesPerSecond: Cardinal;
    AverageBytesPerSecond: Cardinal;
    BlockAlign: Word;
    BitsPerSample: Word;
    /// <summary>The offset of the first byte of the samples in the file (<c>mseekBase</c>)</summary>
    DataOffset: Cardinal;
    /// <summary>
    ///   The size of the data chunk as the header says (<c>mck.cksize</c>, <c>GetMemorySize</c>): it is not
    ///   checked against the length of the file
    /// </summary>
    DataSize: Cardinal;
    /// <summary>The size in 16-bit samples (<c>GetOutputSize</c>, <c>mdwSize</c>): the data size divided by two</summary>
    SizeInSamples: Cardinal;
  end;

  /// <summary>
  ///   The reading of the header of a WAV file with the rules of the sound cache of Doom 3, which are not those of a
  ///   general reader (<c>Libs\Sound</c> decodes any WAV; <c>TSfxWaveParser</c> reads the sound effects of the
  ///   Doom engine): PCM only; the <c>fmt </c> chunk is looked for in steps of 8 bytes from the offset 12 and
  ///   the other chunks are <b>not</b> skipped by their size (a chunk before <c>fmt </c> only works if it has no
  ///   data); the data chunk is looked for byte by byte from the offset 16; a data size of $FFFFFFFF is
  ///   refused. What the original leaves undefined (a file shorter than 12 bytes, or a size cut off by the end of the
  ///   file: it reads stale memory) is a refusal here.
  /// </summary>
  TWaveHeaderReader = class sealed
  public
    /// <summary>False where <c>idWaveFile::Open</c> returns -1 (and for the two cases above)</summary>
    class function TryRead(const ABytes: TBytes; out AHeader: TWaveHeader): Boolean; static;
  end;

implementation

const
  RIFF_ID = $46464952;
  WAVE_ID = $45564157;
  FMT_ID = $20746D66;
  DATA_ID = $61746164;
  WAVE_FORMAT_TAG_PCM = 1;
  RIFF_HEADER_SIZE = 12;
  CHUNK_HEADER_SIZE = 8;
  // sizeof(pcmwaveformat_t)
  PCM_FORMAT_SIZE = 16;
  // mckRiff.dwDataOffset + sizeof(fourcc)
  DATA_SEARCH_START = RIFF_HEADER_SIZE + 4;
  UNKNOWN_SIZE = $FFFFFFFF;

{ TWaveHeaderReader }

class function TWaveHeaderReader.TryRead(const ABytes: TBytes; out AHeader: TWaveHeader): Boolean;
var
  LPosition: Integer;
  LId: Cardinal;
  LSize: Cardinal;

  function Available(const ACount: Integer): Boolean;
  begin
    Result := LPosition + ACount <= Length(ABytes);
  end;

  function ReadWord(const AOffset: Integer): Word;
  begin
    Result := ABytes[AOffset] or (Word(ABytes[AOffset + 1]) shl 8);
  end;

  function ReadLong(const AOffset: Integer): Cardinal;
  begin
    Result := Cardinal(ReadWord(AOffset)) or (Cardinal(ReadWord(AOffset + 2)) shl 16);
  end;

begin
  AHeader := Default(TWaveHeader);
  Result := False;
  if Length(ABytes) < RIFF_HEADER_SIZE then
    Exit;

  // ReadMMIO: the RIFF header
  if (ReadLong(0) <> RIFF_ID) or (ReadLong(8) <> WAVE_ID) then
    Exit;

  // search the input file for the fmt chunk
  LPosition := RIFF_HEADER_SIZE;
  repeat
    if not Available(CHUNK_HEADER_SIZE) then
      Exit;
    LId := ReadLong(LPosition);
    LSize := ReadLong(LPosition + 4);
    Inc(LPosition, CHUNK_HEADER_SIZE);
  until LId = FMT_ID;

  // the chunk is at least as large as a PCMWAVEFORMAT; the extra bytes are ignored
  if LSize < PCM_FORMAT_SIZE then
    Exit;
  if not Available(PCM_FORMAT_SIZE) then
    Exit;
  AHeader.FormatTag := ReadWord(LPosition);
  AHeader.Channels := ReadWord(LPosition + 2);
  AHeader.SamplesPerSecond := ReadLong(LPosition + 4);
  AHeader.AverageBytesPerSecond := ReadLong(LPosition + 8);
  AHeader.BlockAlign := ReadWord(LPosition + 12);
  AHeader.BitsPerSample := ReadWord(LPosition + 14);
  // we don't handle the other formats (32 bit wave files, ADPCM...)
  if AHeader.FormatTag <> WAVE_FORMAT_TAG_PCM then
    Exit;

  // ResetFile: seek to the offset 16 and search the data chunk byte by byte
  LPosition := DATA_SEARCH_START;
  LId := 0;
  repeat
    if not Available(1) then
      Exit;
    LId := (LId shr 8) or (Cardinal(ABytes[LPosition]) shl 24);
    Inc(LPosition);
  until LId = DATA_ID;
  if not Available(4) then
    Exit;
  AHeader.DataSize := ReadLong(LPosition);
  AHeader.DataOffset := LPosition + 4;
  AHeader.SizeInSamples := AHeader.DataSize div SizeOf(SmallInt);
  Result := AHeader.DataSize <> UNKNOWN_SIZE;
end;

end.
