{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - writes the program to a temporary file, runs it,        }
{  captures its output and cleans up                                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Runner;

interface

uses
  Winapi.Windows;

type
  /// <summary>
  ///   How a run of TGlbspProcess ended
  /// </summary>
  TGlbspRunStatus = (
    /// <summary>The process ran to its end (look at ExitCode)</summary>
    grsCompleted,
    /// <summary>The executable could not be written to a temporary file</summary>
    grsTempFileFailed,
    /// <summary>The pipe or the process could not be created</summary>
    grsLaunchFailed,
    /// <summary>The process did not finish in time and was terminated</summary>
    grsTimedOut
  );

  /// <summary>
  ///   Runs a program that is held in memory: writes it to a uniquely named
  ///   file in the temporary folder of the system, starts it hidden with
  ///   its standard output and error captured through an anonymous pipe,
  ///   waits for it up to a timeout and deletes the file
  /// </summary>
  /// <remarks>
  ///   The output is 8 bit text (the code page of the console), kept as
  ///   AnsiString and truncated to 1 MiB. One instance can be used for any
  ///   number of runs, one at a time: every run starts from a clean state.
  ///   Knows nothing about glbsp or about the engine
  /// </remarks>
  TGlbspProcess = class
  private
    const
      MAX_OUTPUT_SIZE = 1024 * 1024;
      PIPE_BUFFER_SIZE = 64 * 1024;
      POLL_INTERVAL_MS = 20;
      TERMINATE_WAIT_MS = 5000;
      DELETE_ATTEMPTS = 10;
      DELETE_RETRY_MS = 50;
  private
    FExecutable: Pointer;
    FExecutableSize: Cardinal;
    FExecutablePath: string;
    FOutput: AnsiString;
    FExitCode: Cardinal;
    FErrorText: string;
    procedure Reset;
    procedure AppendOutput(ABuffer: PAnsiChar; ACount: Integer);
    procedure DrainPipe(APipe: THandle);
    function WriteExecutable: Boolean;
    procedure DeleteExecutable;
    function StartProcess(const ACommandLine: string; AOutput: THandle;
      out AInfo: TProcessInformation): Boolean;
    function Supervise(AProcess, APipe: THandle;
      ATimeoutMs: Cardinal): TGlbspRunStatus;
    function Execute(const ACommandLine: string;
      ATimeoutMs: Cardinal): TGlbspRunStatus;
  public
    /// <param name="AExecutable">
    ///   First byte of the program; the bytes are only read, and must stay
    ///   valid for the whole life of this object
    /// </param>
    /// <param name="AExecutableSize">Length of the program in bytes</param>
    constructor Create(AExecutable: Pointer; AExecutableSize: Cardinal);

    /// <summary>
    ///   Writes the program to a temporary file, runs it with the given
    ///   arguments (everything after the program name) and deletes the file
    ///   in every case
    /// </summary>
    function Run(const AArguments: string; ATimeoutMs: Cardinal): TGlbspRunStatus;

    /// <summary>
    ///   Runs a complete command line of an executable that already exists
    ///   on disk, with the same pipe, output capture and timeout. The first
    ///   token is the program, quoted if its path has spaces
    /// </summary>
    function RunCommandLine(const ACommandLine: string;
      ATimeoutMs: Cardinal): TGlbspRunStatus;

    /// <summary>Text the process wrote to its standard output and error</summary>
    property Output: AnsiString read FOutput;

    /// <summary>
    ///   Exit code of the process after grsCompleted, zero otherwise
    /// </summary>
    property ExitCode: Cardinal read FExitCode;

    /// <summary>Detail of the last failure, empty if the run ended well</summary>
    property ErrorText: string read FErrorText;

    /// <summary>
    ///   Path of the temporary file of the last Run: it does not exist any
    ///   more once Run returns (unless the system refused to delete it)
    /// </summary>
    property ExecutablePath: string read FExecutablePath;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Diagnostics;

{ TGlbspProcess }

constructor TGlbspProcess.Create(AExecutable: Pointer; AExecutableSize: Cardinal);
begin
  inherited Create;
  if not Assigned(AExecutable) then
    raise EArgumentNilException.Create('AExecutable');
  if AExecutableSize = 0 then
    raise EArgumentException.Create('AExecutableSize must be greater than zero');
  FExecutable := AExecutable;
  FExecutableSize := AExecutableSize;
end;

procedure TGlbspProcess.Reset;
begin
  FOutput := '';
  FExitCode := 0;
  FErrorText := '';
  FExecutablePath := '';
end;

procedure TGlbspProcess.AppendOutput(ABuffer: PAnsiChar; ACount: Integer);
var
  LOldLength: Integer;
begin
  LOldLength := Length(FOutput);
  // The pipe is still emptied when the text is too long, so that the process
  // never blocks on a full pipe; the exceeding text is dropped
  if LOldLength + ACount > MAX_OUTPUT_SIZE then
    ACount := MAX_OUTPUT_SIZE - LOldLength;
  if ACount <= 0 then
    Exit;

  SetLength(FOutput, LOldLength + ACount);
  Move(ABuffer^, FOutput[LOldLength + 1], ACount);
end;

procedure TGlbspProcess.DrainPipe(APipe: THandle);
var
  LBuffer: array[0..4095] of AnsiChar;
  LAvailable: DWORD;
  LRead: DWORD;
begin
  // PeekNamedPipe never blocks, so the timeout can be honoured
  while PeekNamedPipe(APipe, nil, 0, nil, @LAvailable, nil) and
    (LAvailable > 0) do
  begin
    if not ReadFile(APipe, LBuffer, SizeOf(LBuffer), LRead, nil) or
      (LRead = 0) then
      Break;
    AppendOutput(@LBuffer[0], Integer(LRead));
  end;
end;

function TGlbspProcess.WriteExecutable: Boolean;
var
  LStream: TFileStream;
  LGuid: string;
begin
  Result := False;
  // A GUID makes the name unique even between processes that run together
  LGuid := Copy(GUIDToString(TGUID.NewGuid), 2, 36);
  FExecutablePath := TPath.Combine(TPath.GetTempPath, 'ddglbsp_' + LGuid + '.exe');
  try
    LStream := TFileStream.Create(FExecutablePath, fmCreate or fmShareExclusive);
    try
      LStream.WriteBuffer(FExecutable^, FExecutableSize);
    finally
      LStream.Free;
    end;
    Result := True;
  except
    on E: Exception do
    begin
      FErrorText := 'Cannot write ' + FExecutablePath + ': ' + E.Message;
      DeleteExecutable;
    end;
  end;
end;

procedure TGlbspProcess.DeleteExecutable;
var
  LAttempt: Integer;
begin
  if FExecutablePath = '' then
    Exit;

  // An antivirus may keep the file open for a moment after the process ends
  for LAttempt := 1 to DELETE_ATTEMPTS do
  begin
    if System.SysUtils.DeleteFile(FExecutablePath) or
      not FileExists(FExecutablePath) then
      Exit;
    Sleep(DELETE_RETRY_MS);
  end;
end;

function TGlbspProcess.StartProcess(const ACommandLine: string;
  AOutput: THandle; out AInfo: TProcessInformation): Boolean;
var
  LSecurity: TSecurityAttributes;
  LStartup: TStartupInfo;
  LInput: THandle;
  LCommandLine: string;
begin
  FillChar(AInfo, SizeOf(AInfo), 0);

  FillChar(LSecurity, SizeOf(LSecurity), 0);
  LSecurity.nLength := SizeOf(LSecurity);
  LSecurity.bInheritHandle := True;

  // The process gets an empty standard input, so it can never wait for a key
  LInput := CreateFile('NUL', GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE,
    @LSecurity, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if LInput = INVALID_HANDLE_VALUE then
  begin
    FErrorText := 'Cannot open the null device: ' + SysErrorMessage(GetLastError);
    Exit(False);
  end;

  try
    FillChar(LStartup, SizeOf(LStartup), 0);
    LStartup.cb := SizeOf(LStartup);
    LStartup.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
    LStartup.wShowWindow := SW_HIDE;
    LStartup.hStdInput := LInput;
    LStartup.hStdOutput := AOutput;
    LStartup.hStdError := AOutput;

    // CreateProcess may write into the command line buffer: it must not be
    // the shared buffer of a string constant or of the caller
    LCommandLine := ACommandLine;
    UniqueString(LCommandLine);

    Result := CreateProcess(nil, PChar(LCommandLine), nil, nil, True,
      CREATE_NO_WINDOW, nil, nil, LStartup, AInfo);
    if not Result then
      FErrorText := 'Cannot start the process: ' + SysErrorMessage(GetLastError);
  finally
    CloseHandle(LInput);
  end;
end;

function TGlbspProcess.Supervise(AProcess, APipe: THandle;
  ATimeoutMs: Cardinal): TGlbspRunStatus;
var
  LWatch: TStopwatch;
  LWaitResult: DWORD;
  LExitCode: DWORD;
begin
  LWatch := TStopwatch.StartNew;
  repeat
    DrainPipe(APipe);

    LWaitResult := WaitForSingleObject(AProcess, POLL_INTERVAL_MS);
    if LWaitResult = WAIT_OBJECT_0 then
    begin
      // What the process wrote before exiting is still in the pipe
      DrainPipe(APipe);
      if GetExitCodeProcess(AProcess, LExitCode) then
        FExitCode := LExitCode;
      Exit(grsCompleted);
    end;

    if LWaitResult <> WAIT_TIMEOUT then
    begin
      FErrorText := 'Cannot wait for the process: ' + SysErrorMessage(GetLastError);
      TerminateProcess(AProcess, 1);
      WaitForSingleObject(AProcess, TERMINATE_WAIT_MS);
      Exit(grsLaunchFailed);
    end;

    if LWatch.ElapsedMilliseconds >= Int64(ATimeoutMs) then
    begin
      TerminateProcess(AProcess, 1);
      // The file of the program cannot be deleted while the process lives
      WaitForSingleObject(AProcess, TERMINATE_WAIT_MS);
      DrainPipe(APipe);
      FErrorText := Format('The process did not finish within %d ms', [ATimeoutMs]);
      Exit(grsTimedOut);
    end;
  until False;
end;

function TGlbspProcess.Execute(const ACommandLine: string;
  ATimeoutMs: Cardinal): TGlbspRunStatus;
var
  LSecurity: TSecurityAttributes;
  LReadPipe: THandle;
  LWritePipe: THandle;
  LInfo: TProcessInformation;
  LStarted: Boolean;
begin
  FillChar(LSecurity, SizeOf(LSecurity), 0);
  LSecurity.nLength := SizeOf(LSecurity);
  LSecurity.bInheritHandle := True;

  if not CreatePipe(LReadPipe, LWritePipe, @LSecurity, PIPE_BUFFER_SIZE) then
  begin
    FErrorText := 'Cannot create the pipe: ' + SysErrorMessage(GetLastError);
    Exit(grsLaunchFailed);
  end;

  try
    // Only the write end is inherited: the process must not hold the read end
    SetHandleInformation(LReadPipe, HANDLE_FLAG_INHERIT, 0);

    LStarted := StartProcess(ACommandLine, LWritePipe, LInfo);
    // The process has its own copy of the write end (or never started)
    CloseHandle(LWritePipe);
    if not LStarted then
      Exit(grsLaunchFailed);

    try
      Result := Supervise(LInfo.hProcess, LReadPipe, ATimeoutMs);
    finally
      CloseHandle(LInfo.hThread);
      CloseHandle(LInfo.hProcess);
    end;
  finally
    CloseHandle(LReadPipe);
  end;
end;

function TGlbspProcess.Run(const AArguments: string;
  ATimeoutMs: Cardinal): TGlbspRunStatus;
begin
  Reset;
  if not WriteExecutable then
    Exit(grsTempFileFailed);

  try
    Result := Execute('"' + FExecutablePath + '" ' + AArguments, ATimeoutMs);
  finally
    DeleteExecutable;
  end;
end;

function TGlbspProcess.RunCommandLine(const ACommandLine: string;
  ATimeoutMs: Cardinal): TGlbspRunStatus;
begin
  Reset;
  Result := Execute(ACommandLine, ATimeoutMs);
end;

end.
