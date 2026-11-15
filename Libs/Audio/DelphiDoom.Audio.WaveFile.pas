{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - idWaveFile                                      }
{                                                                              }
{  Port of idWaveFile (sound\snd_wavefile.cpp, snd_decoder.cpp: OpenOGG,       }
{  ReadOGG, CloseOGG). Open for a WAV file uses TWaveHeaderReader, which has   }
{  the ReadMMIO and ResetFile of the original with its golden.                 }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later. Copyright (C) 1999-2011 id Software LLC.     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.WaveFile;

interface

uses
  System.SysUtils, DelphiDoom.Audio.WaveFile.Types, DelphiDoom.Audio.WaveFile.Intf;

type
  /// <summary>
  ///   A sound as the sound cache of Doom 3 reads it: a WAV file (or an OGG file with the same name and the
  ///   extension .ogg, which wins), or samples already in memory. The calls and the results (0, -1, sizes) are
  ///   those of <c>idWaveFile</c>. Differences: the file is read whole at <c>Open</c> (an <c>idFile</c> is a stream
  ///   of the file system), <c>OpenFromMemory</c> copies the samples (the original keeps the pointer and frees it),
  ///   the OGG file is decoded whole at <c>Open</c> and <c>Read</c> hands out the decoded bytes (the original
  ///   decodes while reading: same bytes). Quirks kept: <c>Read</c> of a file goes on past the data chunk to the
  ///   end of the file; <c>Seek</c> of samples in memory moves the position and answers -1; <c>Seek</c> of an OGG
  ///   file is a fatal error (<c>EWaveFileException</c>)
  /// </summary>
  TWaveFile = class
  strict private
    FFileSystem: IWaveFileSystem;
    FOggDecoder: IWaveOggDecoder;
    FFormat: TWaveFormat;
    FData: TBytes;
    FPosition: Integer;
    FSeekBase: Integer;
    FHasFile: Boolean;
    FFromMemory: Boolean;
    FMemoryPosition: Integer;
    FOggPcm: TBytes;
    FOggPosition: Integer;
    FHasOgg: Boolean;
    FIsOgg: Boolean;
    FSizeInSamples: Integer;
    FMemorySize: Integer;
    FFileTime: Int64;
    FRealTimeDecoding: Boolean;

    function OpenOgg(const AName: string; out AFormat: TWaveFormat): Integer;
    function ReadOgg(ABuffer: Pointer; ASizeToRead: Integer; var ASizeRead: Integer): Integer;
  public
    /// <summary>The name with its extension replaced by .ogg (idStr::SetFileExtension)</summary>
    class function OggName(const AName: string): string; static;
    /// <summary>The OGG decoder is optional: without it an .ogg file is not opened (as without the Vorbis library)</summary>
    constructor Create(const AFileSystem: IWaveFileSystem; const AOggDecoder: IWaveOggDecoder = nil);
    /// <summary>
    ///   <c>idWaveFile::Open</c>: 0 and the format, or -1. An OGG file with the same name and the extension
    ///   .ogg is opened instead of the WAV one
    /// </summary>
    function Open(const AName: string; out AFormat: TWaveFormat): Integer;
    /// <summary>
    ///   <c>idWaveFile::OpenFromMemory</c>: the samples in ASize bytes at AData and their format; always 0.
    ///   The bytes are copied
    /// </summary>
    function OpenFromMemory(AData: Pointer; ASize: Integer; const AFormat: TWaveFormat): Integer;
    /// <summary>
    ///   <c>idWaveFile::Read</c>: up to ASizeToRead bytes of the samples from the current position into ABuffer;
    ///   the result and ASizeRead are the bytes read; -1 if nothing is open (or the buffer is nil), and then ASizeRead
    ///   is left as it was (pdwSizeRead is not written)
    /// </summary>
    function Read(ABuffer: Pointer; ASizeToRead: Integer; var ASizeRead: Integer): Integer;
    /// <summary><c>idWaveFile::Seek</c>: a byte offset from the start of the samples</summary>
    function Seek(AOffset: Integer): Integer;
    /// <summary><c>idWaveFile::ResetFile</c>: back to the start of the samples</summary>
    function ResetFile: Integer;
    /// <summary><c>idWaveFile::Close</c>: always 0 (<c>CloseOGG</c> is only called for an OGG file that is open)</summary>
    function Close: Integer;
    /// <summary>s_realTimeDecoding: an OGG file is left encoded (the format tag is OGG and <c>Read</c> gives the file)</summary>
    property RealTimeDecoding: Boolean read FRealTimeDecoding write FRealTimeDecoding;
    /// <summary>mpwfx</summary>
    property Format: TWaveFormat read FFormat;
    /// <summary>GetOutputSize: the size in 16-bit samples (mdwSize)</summary>
    property OutputSize: Integer read FSizeInSamples;
    /// <summary>GetMemorySize: the size in bytes (mMemSize)</summary>
    property MemorySize: Integer read FMemorySize;
    property IsOgg: Boolean read FIsOgg;
    /// <summary>mfileTime</summary>
    property FileTime: Int64 read FFileTime;
    /// <summary>mseekBase: where the samples start in the file</summary>
    property SeekBase: Integer read FSeekBase;
  end;

implementation

uses
  DelphiDoom.Audio.WaveHeader;

const
  OGG_READ_BLOCK = 4096;

{ TWaveFile }

constructor TWaveFile.Create(const AFileSystem: IWaveFileSystem; const AOggDecoder: IWaveOggDecoder);
begin
  inherited Create;
  FFileSystem := AFileSystem;
  FOggDecoder := AOggDecoder;
end;

class function TWaveFile.OggName(const AName: string): string;
var
  LDot: Integer;
  LIndex: Integer;
begin
  // idStr::SetFileExtension: the extension after the last dot of the last path element is replaced
  Result := AName;
  LDot := 0;
  for LIndex := Length(AName) downto 1 do
  begin
    if (AName[LIndex] = '/') or (AName[LIndex] = '\') or (AName[LIndex] = ':') then
      Break;
    if AName[LIndex] = '.' then
    begin
      LDot := LIndex;
      Break;
    end;
  end;
  if LDot > 0 then
    Result := Copy(AName, 1, LDot - 1);
  Result := Result + '.ogg';
end;

function TWaveFile.OpenOgg(const AName: string; out AFormat: TWaveFormat): Integer;
var
  LData: TBytes;
  LChannels: Integer;
  LRate: Cardinal;
  LPcm: TBytes;
begin
  AFormat := Default(TWaveFormat);
  Result := -1;
  if not FFileSystem.TryReadFile(AName, LData) then
    Exit;
  if (not Assigned(FOggDecoder)) or not FOggDecoder.TryDecode(LData, LChannels, LRate, LPcm) then
    Exit;
  FFileTime := FFileSystem.Timestamp(AName);
  FFormat := Default(TWaveFormat);
  FFormat.SamplesPerSecond := LRate;
  FFormat.Channels := LChannels;
  FFormat.BitsPerSample := SizeOf(SmallInt) * 8;
  // pcm samples * number of channels
  FSizeInSamples := Length(LPcm) div SizeOf(SmallInt);
  if FRealTimeDecoding then
  begin
    FFormat.Tag := WAVE_FORMAT_TAG_OGG;
    FData := LData;
    FHasFile := True;
    FPosition := 0;
    FMemorySize := Length(LData);
  end
  else
  begin
    FFormat.Tag := WAVE_FORMAT_TAG_PCM;
    FOggPcm := LPcm;
    FOggPosition := 0;
    FHasOgg := True;
    FMemorySize := FSizeInSamples * SizeOf(SmallInt);
  end;
  AFormat := FFormat;
  FFromMemory := False;
  FIsOgg := True;
  Result := 0;
end;

function TWaveFile.Open(const AName: string; out AFormat: TWaveFormat): Integer;
var
  LHeader: TWaveHeader;
  LName: string;
begin
  AFormat := Default(TWaveFormat);
  FFromMemory := False;
  FData := nil;
  FHasFile := False;
  FHasOgg := False;
  FIsOgg := False;
  if AName = '' then
    Exit(-1);
  LName := OggName(AName);
  if FFileSystem.FileLength(LName) <> -1 then
    Exit(OpenOgg(LName, AFormat));
  FFormat := Default(TWaveFormat);
  if not FFileSystem.TryReadFile(AName, FData) then
  begin
    FSizeInSamples := 0;
    Exit(-1);
  end;
  if Length(FData) <= 0 then
    Exit(-1);
  // ReadMMIO and ResetFile (a stream that is too short or has no data chunk are refused)
  if not TWaveHeaderReader.TryRead(FData, LHeader) then
  begin
    Close;
    Exit(-1);
  end;
  FHasFile := True;
  FFileTime := FFileSystem.Timestamp(AName);
  FFormat.Tag := LHeader.FormatTag;
  FFormat.Channels := LHeader.Channels;
  FFormat.SamplesPerSecond := LHeader.SamplesPerSecond;
  FFormat.AverageBytesPerSecond := LHeader.AverageBytesPerSecond;
  FFormat.BlockAlign := LHeader.BlockAlign;
  FFormat.BitsPerSample := LHeader.BitsPerSample;
  FSeekBase := Integer(LHeader.DataOffset);
  FPosition := FSeekBase;
  FSizeInSamples := Integer(LHeader.SizeInSamples);
  FMemorySize := Integer(LHeader.DataSize);
  AFormat := FFormat;
  Result := 0;
end;

function TWaveFile.OpenFromMemory(AData: Pointer; ASize: Integer; const AFormat: TWaveFormat): Integer;
begin
  FFormat := AFormat;
  SetLength(FData, ASize);
  if ASize > 0 then
    Move(AData^, FData[0], ASize);
  FMemoryPosition := 0;
  FSizeInSamples := ASize div SizeOf(SmallInt);
  FMemorySize := ASize;
  FFromMemory := True;
  FHasFile := False;
  FHasOgg := False;
  Result := 0;
end;

function TWaveFile.ReadOgg(ABuffer: Pointer; ASizeToRead: Integer; var ASizeRead: Integer): Integer;
var
  LTotal: Integer;
  LBlock: Integer;
  LAvailable: Integer;
  LPointer: PByte;
begin
  // ReadOGG: ov_read in blocks of at most 4096 bytes until the request is met or the stream ends
  LTotal := ASizeToRead;
  LPointer := ABuffer;
  while LTotal > 0 do
  begin
    LBlock := LTotal;
    if LBlock > OGG_READ_BLOCK then
      LBlock := OGG_READ_BLOCK;
    LAvailable := Length(FOggPcm) - FOggPosition;
    if LAvailable <= 0 then
      Break;
    if LBlock > LAvailable then
      LBlock := LAvailable;
    Move(FOggPcm[FOggPosition], LPointer^, LBlock);
    Inc(FOggPosition, LBlock);
    Inc(LPointer, LBlock);
    Dec(LTotal, LBlock);
  end;
  ASizeRead := ASizeToRead - LTotal;
  Result := ASizeRead;
end;

function TWaveFile.Read(ABuffer: Pointer; ASizeToRead: Integer; var ASizeRead: Integer): Integer;
var
  LAvailable: Integer;
begin
  if FHasOgg then
    Exit(ReadOgg(ABuffer, ASizeToRead, ASizeRead));
  if FFromMemory then
  begin
    // the samples are cut at the end of the data
    if FMemoryPosition < 0 then
      ASizeToRead := 0
    else if FMemoryPosition + ASizeToRead > Length(FData) then
      ASizeToRead := Length(FData) - FMemoryPosition;
    if ASizeToRead < 0 then
      ASizeToRead := 0;
    if ASizeToRead > 0 then
      Move(FData[FMemoryPosition], ABuffer^, ASizeToRead);
    Inc(FMemoryPosition, ASizeToRead);
    ASizeRead := ASizeToRead;
    Exit(ASizeToRead);
  end;
  if (not FHasFile) or (ABuffer = nil) then
    Exit(-1);
  // idFile::Read: what there is up to the end of the file, not of the data chunk
  if FPosition < 0 then
    LAvailable := 0
  else
    LAvailable := Length(FData) - FPosition;
  if LAvailable < 0 then
    LAvailable := 0;
  if ASizeToRead > LAvailable then
    ASizeToRead := LAvailable;
  if ASizeToRead < 0 then
    ASizeToRead := 0;
  if ASizeToRead > 0 then
    Move(FData[FPosition], ABuffer^, ASizeToRead);
  Inc(FPosition, ASizeToRead);
  ASizeRead := ASizeToRead;
  Result := ASizeToRead;
end;

function TWaveFile.Seek(AOffset: Integer): Integer;
begin
  if FHasOgg then
    raise EWaveFileException.Create('idWaveFile::Seek: cannot seek on an OGG file');
  if FFromMemory then
  begin
    // the original sets the pointer and falls out of the if with -1
    FMemoryPosition := AOffset;
    Exit(-1);
  end;
  if not FHasFile then
    Exit(-1);
  FPosition := AOffset + FSeekBase;
  Result := 0;
end;

function TWaveFile.ResetFile: Integer;
begin
  if FFromMemory then
  begin
    FMemoryPosition := 0;
    Exit(0);
  end;
  if not FHasFile then
    Exit(-1);
  FPosition := FSeekBase;
  Result := 0;
end;

function TWaveFile.Close: Integer;
begin
  Result := 0;
  if FHasOgg then
  begin
    FHasOgg := False;
    FOggPcm := nil;
    Exit(0);
  end;
  FHasFile := False;
  if not FFromMemory then
    FData := nil;
end;

end.
