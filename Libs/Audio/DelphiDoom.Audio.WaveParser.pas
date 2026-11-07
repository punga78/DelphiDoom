{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the RIFF WAVE and DMX headers of a sound         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.WaveParser;

interface

uses
  System.SysUtils,
  DelphiDoom.Audio.Types,
  DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   Finds the format and the samples of a sound effect, as the old I_CacheSFX of i_sound did:
  ///   a WAV file out of the WAD is read like a stream (a chunk it does not know is skipped two
  ///   bytes at a time), a lump of the WAD a long word at a time (also at two bytes from the
  ///   alignment) and, if it is not a RIFF, it is a DMX sound. The problems are warnings to the
  ///   log, with the same text as before
  /// </summary>
  /// <remarks>
  ///   Bytes after the end of the buffer are read as zeros: the old code read the memory after
  ///   the lump or kept what it had read before
  /// </remarks>
  TSfxWaveParser = class
  public
    /// <summary>
    ///   A file out of the WAD. False if the file is not good (the lump of the WAD is used):
    ///   true does not mean that it has both the format and the samples
    /// </summary>
    class function ParseFile(const ABytes: TBytes; const AName: string; const ALog: ILog;
      var AChunks: TSfxWaveChunks): Boolean; static;
    /// <summary>
    ///   A lump of the WAD: a RIFF WAVE or a DMX sound. True if the lump gave the last of the two
    ///   parts (the sound is a WAV inside the WAD)
    /// </summary>
    class function ParseLump(AData: PByte; ALength: Integer; const AName: string;
      const ALog: ILog; var AChunks: TSfxWaveChunks): Boolean; static;
    /// <summary>The first four bytes are RIFF</summary>
    class function IsRiff(AData: PByte; ALength: Integer): Boolean; static;
  end;

implementation

const
  RIFF_ID = $46464952;
  WAVE_ID = $45564157;
  FMT_ID = $20746D66;
  DATA_ID = $61746164;

  WAVE_FORMAT_PCM = 1;
  // SizeOf(TWAVEFORMAT) and SizeOf(TWAVEFORMATEX) of MMSystem
  WAVEFORMAT_SIZE = 14;
  WAVEFORMATEX_SIZE = 18;
  // the RIFF header and a WAVEFORMATEX
  MINIMUM_SIZE = 8 + WAVEFORMATEX_SIZE;
  // the header of a DMX sound: format, rate, number of samples
  DMX_DATA_OFFSET = 8;

  SFileInvalidSize = 'CacheSFX(): Sound %s.wav has invalid size'#13#10;
  SFileInvalidHeader = 'CacheSFX(): Sound %s.wav has invalid header'#13#10;
  SFileNoWave = 'CacheSFX(): Sound %s.wav has not the WAVE file indicator'#13#10;
  SFileInvalidFormat = 'CacheSFX(): Sound %s.wav has invalid fmt CHUNK'#13#10;
  SFileNotPcm = 'CacheSFX(): Sound %s.wav is not a WAV file'#13#10;
  SFileInvalidData = 'CacheSFX(): Sound %s.wav has invalid data CHUNK'#13#10;
  SLumpInvalidSize = 'CacheSFX(): Sound %s has invalid size'#13#10;
  SLumpNoWave = 'CacheSFX(): Sound %s has not the WAVE file indicator'#13#10;
  SLumpInvalidFormat = 'CacheSFX(): Sound %s has invalid fmt CHUNK'#13#10;
  SLumpNotPcm = 'CacheSFX(): Sound %s is not a WAV file'#13#10;
  SLumpInvalidData = 'CacheSFX(): Sound %s has invalid data CHUNK'#13#10;

type
  /// <summary>The fields of a WAVEFORMATEX, read from the little endian bytes</summary>
  TWaveFormatBytes = packed array[0..WAVEFORMATEX_SIZE - 1] of Byte;

  /// <summary>
  ///   The bytes of a file seen as the stream of the old code: a read past the end gives what
  ///   is left (nothing before the start or after the end) and leaves the rest of the target
  /// </summary>
  TWaveStream = record
    Bytes: TBytes;
    Position: Int64;
    function Size: Integer;
    procedure Read(var ATarget; ACount: Integer);
    procedure Seek(AOffset: Int64);
  end;

function TWaveStream.Size: Integer;
begin
  Result := Length(Bytes);
end;

procedure TWaveStream.Read(var ATarget; ACount: Integer);
var
  LAvailable: Int64;
begin
  if (Position < 0) or (ACount <= 0) then
    Exit;
  LAvailable := Size - Position;
  if LAvailable <= 0 then
    Exit;
  if LAvailable > ACount then
    LAvailable := ACount;
  Move(Bytes[Position], ATarget, LAvailable);
  Position := Position + LAvailable;
end;

procedure TWaveStream.Seek(AOffset: Int64);
begin
  Position := Position + AOffset;
end;

function WordOf(const AFormat: TWaveFormatBytes; AIndex: Integer): Word;
begin
  Result := AFormat[AIndex] or (Word(AFormat[AIndex + 1]) shl 8);
end;

function LongOf(const AFormat: TWaveFormatBytes; AIndex: Integer): Cardinal;
begin
  Result := WordOf(AFormat, AIndex) or (Cardinal(WordOf(AFormat, AIndex + 2)) shl 16);
end;

function FormatOf(const AFormat: TWaveFormatBytes): TSfxFormat;
begin
  Result.Tag := WordOf(AFormat, 0);
  Result.Channels := WordOf(AFormat, 2);
  Result.SamplesPerSecond := LongOf(AFormat, 4);
  Result.AverageBytesPerSecond := LongOf(AFormat, 8);
  Result.BitsPerSample := WordOf(AFormat, 14);
end;

procedure Warn(const ALog: ILog; const AText, AName: string);
begin
  if Assigned(ALog) then
    ALog.Warning(Format(AText, [AName]));
end;

{ TSfxWaveParser }

class function TSfxWaveParser.IsRiff(AData: PByte; ALength: Integer): Boolean;
begin
  Result := Assigned(AData) and (ALength >= SizeOf(Cardinal)) and (PCardinal(AData)^ = RIFF_ID);
end;

class function TSfxWaveParser.ParseFile(const ABytes: TBytes; const AName: string;
  const ALog: ILog; var AChunks: TSfxWaveChunks): Boolean;
var
  LStream: TWaveStream;
  LId: Cardinal;
  LRiffLength: Integer;
  LChunkType: Cardinal;
  LChunkLength: Integer;
  LFormat: TWaveFormatBytes;
begin
  AChunks.FormatFound := False;
  AChunks.DataFound := False;
  LStream.Bytes := ABytes;
  LStream.Position := 0;
  LId := 0;
  LRiffLength := 0;
  LChunkType := 0;
  LChunkLength := 0;
  FillChar(LFormat, SizeOf(LFormat), 0);

  if LStream.Size < MINIMUM_SIZE then
  begin
    Warn(ALog, SFileInvalidSize, AName);
    Exit(False);
  end;

  LStream.Read(LId, SizeOf(Cardinal));
  if LId <> RIFF_ID then
  begin
    Warn(ALog, SFileInvalidHeader, AName);
    Exit(False);
  end;

  LStream.Read(LRiffLength, SizeOf(Integer));
  LStream.Read(LId, SizeOf(Cardinal));
  if LId <> WAVE_ID then
  begin
    Warn(ALog, SFileNoWave, AName);
    Exit(False);
  end;

  Result := True;
  while LStream.Position < LStream.Size - 8 do
  begin
    LStream.Read(LChunkType, SizeOf(Cardinal));
    LStream.Read(LChunkLength, SizeOf(Integer));
    if LChunkType = FMT_ID then
    begin
      // a second fmt chunk is read again: only the first one has to be long enough
      if (LChunkLength < WAVEFORMAT_SIZE) and not AChunks.FormatDone then
      begin
        Warn(ALog, SFileInvalidFormat, AName);
        Exit(False);
      end;
      AChunks.FormatDone := True;
      LStream.Read(LFormat, SizeOf(LFormat));
      if WordOf(LFormat, 0) <> WAVE_FORMAT_PCM then
      begin
        Warn(ALog, SFileNotPcm, AName);
        Exit(False);
      end;
      LStream.Seek(Int64(LChunkLength) - WAVEFORMATEX_SIZE);
      AChunks.FormatFound := True;
      AChunks.Format := FormatOf(LFormat);
    end
    else if (LChunkType = DATA_ID) and not AChunks.DataDone then
    begin
      // a negative length (more than 2 GB) gave a negative block to the old code
      if (LChunkLength < 0) or (LChunkLength > LStream.Size - LStream.Position) then
      begin
        Warn(ALog, SFileInvalidData, AName);
        Exit(False);
      end;
      AChunks.DataDone := True;
      AChunks.DataFound := True;
      AChunks.DataOffset := LStream.Position;
      AChunks.DataLength := LChunkLength;
      LStream.Seek(LChunkLength);
    end
    else
      // not a chunk that it knows: two bytes ahead (the eight of the header, less six)
      LStream.Seek(-6);
    if AChunks.FormatDone and AChunks.DataDone then
      Break;
    // the old stream could go before the start: nothing more can be read
    if LStream.Position < 0 then
      Break;
  end;
end;

class function TSfxWaveParser.ParseLump(AData: PByte; ALength: Integer; const AName: string;
  const ALog: ILog; var AChunks: TSfxWaveChunks): Boolean;

  function ByteAt(AOffset: Int64): Byte;
  begin
    if (AOffset >= 0) and (AOffset < ALength) then
      Result := PByte(NativeUInt(AData) + NativeUInt(AOffset))^
    else
      Result := 0;
  end;

  function LongAt(AOffset: Int64): Cardinal;
  begin
    Result := ByteAt(AOffset) or (Cardinal(ByteAt(AOffset + 1)) shl 8) or
      (Cardinal(ByteAt(AOffset + 2)) shl 16) or (Cardinal(ByteAt(AOffset + 3)) shl 24);
  end;

var
  LIndex: Integer;
  LChunkType: Cardinal;
  LChunkLength: Integer;
  LShifted: Boolean;
  LFormat: TWaveFormatBytes;
  LByte: Integer;
begin
  Result := False;
  AChunks.FormatFound := False;
  AChunks.DataFound := False;

  if not IsRiff(AData, ALength) then
  begin
    // a DMX sound: format, rate and number of samples, then the samples
    AChunks.FormatFound := True;
    AChunks.Format.Tag := WAVE_FORMAT_PCM;
    AChunks.Format.Channels := 1;
    AChunks.Format.SamplesPerSecond := ByteAt(2) or (Word(ByteAt(3)) shl 8);
    AChunks.Format.AverageBytesPerSecond := AChunks.Format.SamplesPerSecond;
    AChunks.Format.BitsPerSample := 8;
    AChunks.DataFound := True;
    AChunks.DataOffset := DMX_DATA_OFFSET;
    AChunks.DataLength := ALength;
    Exit;
  end;

  if ALength < MINIMUM_SIZE then
  begin
    Warn(ALog, SLumpInvalidSize, AName);
    Exit;
  end;

  // long word 1 is the length of the RIFF, never used
  LIndex := 2;
  if LongAt(LIndex * 4) <> WAVE_ID then
  begin
    Warn(ALog, SLumpNoWave, AName);
    Exit;
  end;

  while LIndex < (ALength div 4) - 2 do
  begin
    LChunkType := LongAt(LIndex * 4);
    LShifted := (LChunkType <> FMT_ID) and (LChunkType <> DATA_ID);
    if LShifted then
    begin
      // a chunk with an odd length before: it starts two bytes after the long word
      LChunkType := LongAt(LIndex * 4 + 2);
      LChunkLength := Integer(LongAt(LIndex * 4 + 6));
    end
    else
      LChunkLength := Integer(LongAt(LIndex * 4 + 4));
    LIndex := LIndex + 2;
    if (LChunkType = FMT_ID) and not AChunks.FormatDone then
    begin
      if LChunkLength < WAVEFORMAT_SIZE then
      begin
        Warn(ALog, SLumpInvalidFormat, AName);
        Exit;
      end;
      AChunks.FormatDone := True;
      // the format is read where the long word is, even when the chunk started two bytes after
      for LByte := 0 to WAVEFORMATEX_SIZE - 1 do
        LFormat[LByte] := ByteAt(Int64(LIndex) * 4 + LByte);
      if WordOf(LFormat, 0) <> WAVE_FORMAT_PCM then
      begin
        Warn(ALog, SLumpNotPcm, AName);
        Exit;
      end;
      LIndex := LIndex + LChunkLength div 4;
      AChunks.FormatFound := True;
      AChunks.Format := FormatOf(LFormat);
    end
    else if (LChunkType = DATA_ID) and not AChunks.DataDone then
    begin
      if (LChunkLength < 0) or (LChunkLength > ALength - LIndex * 4) then
      begin
        Warn(ALog, SLumpInvalidData, AName);
        Exit;
      end;
      AChunks.DataDone := True;
      AChunks.DataFound := True;
      AChunks.DataLength := LChunkLength;
      AChunks.DataOffset := LIndex * 4;
      if LShifted then
        AChunks.DataOffset := AChunks.DataOffset + 2;
    end
    else
      Dec(LIndex);
    if AChunks.FormatDone and AChunks.DataDone then
      Exit(True);
  end;
end;

end.
