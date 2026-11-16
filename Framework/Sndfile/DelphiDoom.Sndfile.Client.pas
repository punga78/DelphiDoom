{******************************************************************************}
{                                                                              }
{  DelphiDoom: libsndfile - the class the engine uses in place of the library  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sndfile.Client;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf;

const
  // Frames read at a time by the methods that decode a whole sound
  SNDFILE_CLIENT_BLOCK_FRAMES = 4096;

  // Largest sound (in samples) the methods that decode a whole sound accept
  SNDFILE_CLIENT_MAX_SAMPLES = 256 * 1024 * 1024;

type
  /// <summary>
  ///   Stands for the libsndfile library in the rest of the engine: works
  ///   with TBytes and raises ESndfileException instead of returning error
  ///   codes
  /// </summary>
  /// <remarks>
  ///   Depends only on ISndfile, so it works the same with the DLL (see
  ///   TSndfileLoader) and with an engine linked in the executable, or with a
  ///   fake in the tests
  /// </remarks>
  TSndfileClient = class
  private
    FSndfile: ISndfile;
    function ReadAllShort(const ASoundFile: ISoundFile;
      const AInfo: TSoundFileInfo): TArray<SmallInt>;
    function ReadAllNormalized(const ASoundFile: ISoundFile;
      const AInfo: TSoundFileInfo): TArray<SmallInt>;
    function SampleCountOf(const AInfo: TSoundFileInfo): Integer;
  public
    constructor Create(const ASndfile: ISndfile);

    /// <summary>
    ///   Raises ESndfileException if ACode is not SNDFILE_OK
    /// </summary>
    class procedure Check(ACode: Integer); static;

    function Version: string;

    /// <summary>
    ///   Opens the sound stored in ASource, detecting its format. The data
    ///   is copied: ASource may be released as soon as the call returns
    /// </summary>
    function Open(const ASource: TBytes): ISoundFile; overload;
    function Open(ASource: Pointer; ASourceSize: Cardinal): ISoundFile; overload;

    /// <summary>
    ///   Description of an opened sound
    /// </summary>
    function InfoOf(const ASoundFile: ISoundFile): TSoundFileInfo;

    /// <summary>
    ///   Decodes the whole sound stored in ASource to interleaved 16 bit
    ///   samples, whatever its format. With ANormalize (and always for
    ///   floating point and Vorbis sounds, which have no fixed range) the
    ///   samples are scaled so that the loudest one reaches the full 16 bit
    ///   range; a silent sound stays silent. AInfo describes the source
    /// </summary>
    function Decode16(const ASource: TBytes; ANormalize: Boolean;
      out AInfo: TSoundFileInfo): TArray<SmallInt>; overload;
    function Decode16(ASource: Pointer; ASourceSize: Cardinal; ANormalize: Boolean;
      out AInfo: TSoundFileInfo): TArray<SmallInt>; overload;
  end;

implementation

uses
  System.Math;

{ TSndfileClient }

constructor TSndfileClient.Create(const ASndfile: ISndfile);
begin
  inherited Create;
  if not Assigned(ASndfile) then
    raise EArgumentNilException.Create('ASndfile');
  FSndfile := ASndfile;
end;

class procedure TSndfileClient.Check(ACode: Integer);
begin
  if ACode <> SNDFILE_OK then
    raise ESndfileException.CreateCode(ACode);
end;

function TSndfileClient.Version: string;
begin
  Result := string(AnsiString(FSndfile.GetVersion));
end;

function TSndfileClient.Open(const ASource: TBytes): ISoundFile;
begin
  Result := Open(Pointer(ASource), Length(ASource));
end;

function TSndfileClient.Open(ASource: Pointer; ASourceSize: Cardinal): ISoundFile;
var
  LCode: Integer;
begin
  LCode := FSndfile.OpenMemory(ASource, ASourceSize, Result);
  if LCode <> SNDFILE_OK then
    raise ESndfileException.CreateCode(LCode);
end;

function TSndfileClient.InfoOf(const ASoundFile: ISoundFile): TSoundFileInfo;
begin
  Check(ASoundFile.GetInfo(Result));
end;

function TSndfileClient.SampleCountOf(const AInfo: TSoundFileInfo): Integer;
begin
  if (AInfo.Channels <= 0) or (AInfo.Frames < 0) or
     (AInfo.Frames > SNDFILE_CLIENT_MAX_SAMPLES div AInfo.Channels) then
    raise ESndfileException.CreateCode(SNDFILE_ERR_INVALID_ARGUMENT);
  Result := Integer(AInfo.Frames) * AInfo.Channels;
end;

function TSndfileClient.ReadAllShort(const ASoundFile: ISoundFile;
  const AInfo: TSoundFileInfo): TArray<SmallInt>;
var
  LSampleCount: Integer;
  LFramesDone: Int64;
  LFramesRead: Int64;
  LFrames: Int64;
begin
  LSampleCount := SampleCountOf(AInfo);
  SetLength(Result, LSampleCount);

  LFramesDone := 0;
  while LFramesDone < AInfo.Frames do
  begin
    LFrames := Min(Int64(SNDFILE_CLIENT_BLOCK_FRAMES), AInfo.Frames - LFramesDone);
    Check(ASoundFile.ReadShort(@Result[Integer(LFramesDone) * AInfo.Channels],
      LFrames, LFramesRead));
    if LFramesRead <= 0 then
      Break;
    Inc(LFramesDone, LFramesRead);
  end;

  // A shorter sound than declared in its header: keep what was decoded
  if LFramesDone < AInfo.Frames then
    SetLength(Result, Integer(LFramesDone) * AInfo.Channels);
end;

function TSndfileClient.ReadAllNormalized(const ASoundFile: ISoundFile;
  const AInfo: TSoundFileInfo): TArray<SmallInt>;
var
  LBlock: array of Double;
  LSampleCount: Integer;
  LFramesRead: Int64;
  LItemCount: Integer;
  LIndex: Integer;
  LOutIndex: Integer;
  LPeak: Double;
  LScale: Double;
  LValue: Int64;
  LPosition: Int64;
begin
  LSampleCount := SampleCountOf(AInfo);
  SetLength(LBlock, SNDFILE_CLIENT_BLOCK_FRAMES * AInfo.Channels);

  // First pass: loudest sample of the sound
  LPeak := 0.0;
  repeat
    Check(ASoundFile.ReadDouble(@LBlock[0], SNDFILE_CLIENT_BLOCK_FRAMES, LFramesRead));
    LItemCount := Integer(LFramesRead) * AInfo.Channels;
    for LIndex := 0 to LItemCount - 1 do
      LPeak := Max(LPeak, Abs(LBlock[LIndex]));
  until LFramesRead <= 0;

  if LPeak > 0.0 then
    LScale := 32768.0 / LPeak
  else
    LScale := 0.0;

  // Second pass: scale to the 16 bit range
  Check(ASoundFile.Seek(0, SNDFILE_SEEK_SET, LPosition));
  SetLength(Result, LSampleCount);
  LOutIndex := 0;
  repeat
    Check(ASoundFile.ReadDouble(@LBlock[0], SNDFILE_CLIENT_BLOCK_FRAMES, LFramesRead));
    LItemCount := Integer(LFramesRead) * AInfo.Channels;
    if LOutIndex + LItemCount > LSampleCount then
      LItemCount := LSampleCount - LOutIndex;
    for LIndex := 0 to LItemCount - 1 do
    begin
      LValue := Round(LBlock[LIndex] * LScale);
      Result[LOutIndex + LIndex] := SmallInt(EnsureRange(LValue, -32768, 32767));
    end;
    Inc(LOutIndex, LItemCount);
  until (LFramesRead <= 0) or (LOutIndex >= LSampleCount);

  if LOutIndex < LSampleCount then
    SetLength(Result, LOutIndex);
end;

function TSndfileClient.Decode16(const ASource: TBytes; ANormalize: Boolean;
  out AInfo: TSoundFileInfo): TArray<SmallInt>;
begin
  Result := Decode16(Pointer(ASource), Length(ASource), ANormalize, AInfo);
end;

function TSndfileClient.Decode16(ASource: Pointer; ASourceSize: Cardinal;
  ANormalize: Boolean; out AInfo: TSoundFileInfo): TArray<SmallInt>;
var
  LSoundFile: ISoundFile;
  LEncoding: Integer;
begin
  LSoundFile := Open(ASource, ASourceSize);
  AInfo := InfoOf(LSoundFile);
  LEncoding := AInfo.Format and SNDFILE_FORMAT_SUBMASK;

  if ANormalize or (LEncoding = SNDFILE_FORMAT_FLOAT) or
     (LEncoding = SNDFILE_FORMAT_DOUBLE) or (LEncoding = SNDFILE_FORMAT_VORBIS) then
    Result := ReadAllNormalized(LSoundFile, AInfo)
  else
    Result := ReadAllShort(LSoundFile, AInfo);
end;

end.
