{******************************************************************************}
{                                                                              }
{  DelphiDoom: libsndfile - ISoundFile on top of the C code                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sndfile.SoundFile;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sndfile.Native;

type
  /// <summary>
  ///   One sound opened from memory: owns a copy of the data and the
  ///   SNDFILE handle that reads it through the virtual I/O callbacks
  /// </summary>
  /// <remarks>
  ///   Not thread safe: use one per thread. No exception leaves a method that
  ///   is part of ISoundFile: they are reported as SNDFILE_ERR_UNEXPECTED
  /// </remarks>
  TSndfileSoundFile = class(TInterfacedObject, ISoundFile)
  private
    type
      /// <summary>
      ///   Kind of sample a read converts to
      /// </summary>
      TSampleKind = (Bits16, Bits32, Float64);
  private
    FData: TBytes;
    FPosition: Int64;
    FVirtualIO: TSfVirtualIO;
    FInfo: TSfInfo;
    FHandle: TSndfileHandle;
    function ReadFrames(AKind: TSampleKind; ABuffer: Pointer; AFrames: Int64;
      out AFramesRead: Int64): Integer;
  public
    destructor Destroy; override;

    /// <summary>
    ///   Copies ASource and opens it. Must be called once, before any other
    ///   method; if it does not return SNDFILE_OK the object is unusable
    /// </summary>
    function Open(ASource: Pointer; ASourceSize: Cardinal): Integer;

    function GetInfo(out AInfo: TSoundFileInfo): Integer; stdcall;
    function ReadShort(ABuffer: Pointer; AFrames: Int64;
      out AFramesRead: Int64): Integer; stdcall;
    function ReadInt(ABuffer: Pointer; AFrames: Int64;
      out AFramesRead: Int64): Integer; stdcall;
    function ReadDouble(ABuffer: Pointer; AFrames: Int64;
      out AFramesRead: Int64): Integer; stdcall;
    function Seek(AFrame: Int64; AWhence: Integer;
      out APosition: Int64): Integer; stdcall;
    function GetErrorText: PAnsiChar; stdcall;
  end;

implementation

const
  // The C code expects the FPU exceptions masked, as in a C program. Same
  // value the engine sets in its main program
  NATIVE_CONTROL_WORD = $133F;

  MAX_SOURCE_SIZE = Cardinal(High(Integer));

// Masks the FPU exceptions and returns the previous control word
function EnterNativeCode: Word;
begin
  Result := Get8087CW;
  Set8087CW(NATIVE_CONTROL_WORD);
end;

procedure LeaveNativeCode(ASavedControlWord: Word);
begin
  Set8087CW(ASavedControlWord);
end;

// Callbacks of the virtual I/O: AUserData is the TSndfileSoundFile that owns
// the data. They are called by the C code, so no exception may escape

function MemoryGetLength(AUserData: Pointer): TSfCount; cdecl;
begin
  Result := Length(TSndfileSoundFile(AUserData).FData);
end;

function MemorySeek(AOffset: TSfCount; AWhence: Integer;
  AUserData: Pointer): TSfCount; cdecl;
var
  LSoundFile: TSndfileSoundFile;
  LTarget: Int64;
begin
  LSoundFile := TSndfileSoundFile(AUserData);
  case AWhence of
    SF_SEEK_SET: LTarget := AOffset;
    SF_SEEK_CUR: LTarget := LSoundFile.FPosition + AOffset;
    SF_SEEK_END: LTarget := Length(LSoundFile.FData) + AOffset;
  else
    Exit(-1);
  end;

  if LTarget < 0 then
    Exit(-1);

  // Like a file, the position may be past the end: reads then return nothing
  LSoundFile.FPosition := LTarget;
  Result := LTarget;
end;

function MemoryRead(ABuffer: Pointer; ACount: TSfCount;
  AUserData: Pointer): TSfCount; cdecl;
var
  LSoundFile: TSndfileSoundFile;
  LAvailable: Int64;
begin
  LSoundFile := TSndfileSoundFile(AUserData);
  LAvailable := Length(LSoundFile.FData) - LSoundFile.FPosition;
  if (ACount <= 0) or (LAvailable <= 0) then
    Exit(0);

  if ACount < LAvailable then
    Result := ACount
  else
    Result := LAvailable;

  Move(LSoundFile.FData[Integer(LSoundFile.FPosition)], ABuffer^, Integer(Result));
  Inc(LSoundFile.FPosition, Result);
end;

// The sound is opened read only
function MemoryWrite(ABuffer: Pointer; ACount: TSfCount;
  AUserData: Pointer): TSfCount; cdecl;
begin
  Result := 0;
end;

function MemoryTell(AUserData: Pointer): TSfCount; cdecl;
begin
  Result := TSndfileSoundFile(AUserData).FPosition;
end;

{ TSndfileSoundFile }

destructor TSndfileSoundFile.Destroy;
var
  LSavedControlWord: Word;
begin
  if Assigned(FHandle) then
  begin
    LSavedControlWord := EnterNativeCode;
    try
      _sf_close(FHandle);
    finally
      LeaveNativeCode(LSavedControlWord);
    end;
    FHandle := nil;
  end;
  inherited;
end;

function TSndfileSoundFile.Open(ASource: Pointer; ASourceSize: Cardinal): Integer;
var
  LSavedControlWord: Word;
begin
  if (ASource = nil) or (ASourceSize = 0) or (ASourceSize > MAX_SOURCE_SIZE) then
    Exit(SNDFILE_ERR_INVALID_ARGUMENT);

  SetLength(FData, ASourceSize);
  Move(ASource^, FData[0], ASourceSize);
  FPosition := 0;

  FVirtualIO.get_filelen := MemoryGetLength;
  FVirtualIO.seek := MemorySeek;
  FVirtualIO.read := MemoryRead;
  FVirtualIO.write := MemoryWrite;
  FVirtualIO.tell := MemoryTell;

  FillChar(FInfo, SizeOf(FInfo), 0);

  LSavedControlWord := EnterNativeCode;
  try
    try
      FHandle := _sf_open_virtual(@FVirtualIO, SF_MODE_READ, @FInfo, Self);
      if Assigned(FHandle) then
        Result := SNDFILE_OK
      else
      begin
        // With no handle the error of the last open is the one to report
        Result := _sf_error(nil);
        if Result = SNDFILE_OK then
          Result := SNDFILE_ERR_UNEXPECTED;
      end;
    except
      FHandle := nil;
      Result := SNDFILE_ERR_UNEXPECTED;
    end;
  finally
    LeaveNativeCode(LSavedControlWord);
  end;
end;

function TSndfileSoundFile.GetInfo(out AInfo: TSoundFileInfo): Integer;
begin
  FillChar(AInfo, SizeOf(AInfo), 0);
  if not Assigned(FHandle) then
    Exit(SNDFILE_ERR_INVALID_ARGUMENT);

  AInfo.Frames := FInfo.frames;
  AInfo.SampleRate := FInfo.samplerate;
  AInfo.Channels := FInfo.channels;
  AInfo.Format := FInfo.format;
  AInfo.Sections := FInfo.sections;
  AInfo.Seekable := FInfo.seekable;
  Result := SNDFILE_OK;
end;

function TSndfileSoundFile.ReadFrames(AKind: TSampleKind; ABuffer: Pointer;
  AFrames: Int64; out AFramesRead: Int64): Integer;
var
  LSavedControlWord: Word;
begin
  AFramesRead := 0;
  if not Assigned(FHandle) or (AFrames < 0) or
     ((AFrames > 0) and (ABuffer = nil)) then
    Exit(SNDFILE_ERR_INVALID_ARGUMENT);
  if AFrames = 0 then
    Exit(SNDFILE_OK);

  LSavedControlWord := EnterNativeCode;
  try
    try
      case AKind of
        TSampleKind.Bits16:
          AFramesRead := _sf_readf_short(FHandle, ABuffer, AFrames);
        TSampleKind.Bits32:
          AFramesRead := _sf_readf_int(FHandle, ABuffer, AFrames);
        TSampleKind.Float64:
          AFramesRead := _sf_readf_double(FHandle, ABuffer, AFrames);
      end;
      // Fewer frames than requested is the end of the sound, not an error:
      // libsndfile reports an error only for damaged data
      Result := _sf_error(FHandle);
    except
      AFramesRead := 0;
      Result := SNDFILE_ERR_UNEXPECTED;
    end;
  finally
    LeaveNativeCode(LSavedControlWord);
  end;
end;

function TSndfileSoundFile.ReadShort(ABuffer: Pointer; AFrames: Int64;
  out AFramesRead: Int64): Integer;
begin
  Result := ReadFrames(TSampleKind.Bits16, ABuffer, AFrames, AFramesRead);
end;

function TSndfileSoundFile.ReadInt(ABuffer: Pointer; AFrames: Int64;
  out AFramesRead: Int64): Integer;
begin
  Result := ReadFrames(TSampleKind.Bits32, ABuffer, AFrames, AFramesRead);
end;

function TSndfileSoundFile.ReadDouble(ABuffer: Pointer; AFrames: Int64;
  out AFramesRead: Int64): Integer;
begin
  Result := ReadFrames(TSampleKind.Float64, ABuffer, AFrames, AFramesRead);
end;

function TSndfileSoundFile.Seek(AFrame: Int64; AWhence: Integer;
  out APosition: Int64): Integer;
var
  LSavedControlWord: Word;
begin
  APosition := 0;
  if not Assigned(FHandle) or (AWhence < SNDFILE_SEEK_SET) or
     (AWhence > SNDFILE_SEEK_END) then
    Exit(SNDFILE_ERR_INVALID_ARGUMENT);

  LSavedControlWord := EnterNativeCode;
  try
    try
      APosition := _sf_seek(FHandle, AFrame, AWhence);
      if APosition >= 0 then
        Result := SNDFILE_OK
      else
      begin
        APosition := 0;
        Result := _sf_error(FHandle);
        if Result = SNDFILE_OK then
          Result := SNDFILE_ERR_INVALID_ARGUMENT;
      end;
    except
      APosition := 0;
      Result := SNDFILE_ERR_UNEXPECTED;
    end;
  finally
    LeaveNativeCode(LSavedControlWord);
  end;
end;

function TSndfileSoundFile.GetErrorText: PAnsiChar;
begin
  Result := _sf_strerror(FHandle);
end;

end.
