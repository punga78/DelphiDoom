{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - implementation of IGlbsp on top of the embedded program }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Engine;

interface

uses
  DelphiDoom.Glbsp.Intf;

type
  /// <summary>
  ///   Implements IGlbsp by running the glbsp executable that is embedded in
  ///   DelphiDoom.Glbsp.Executable (see TGlbspProcess)
  /// </summary>
  /// <remarks>
  ///   Creating the engine is free: the program is written to disk only
  ///   while BuildNodes runs. Not thread safe: the engine keeps the result of
  ///   the last BuildNodes
  /// </remarks>
  TGlbspEngine = class(TInterfacedObject, IGlbsp)
  private
    FExecutable: Pointer;
    FExecutableSize: Cardinal;
    FExitCode: Cardinal;
    FOutput: AnsiString;
    FErrorText: AnsiString;
    class function IsValidPath(APath: PAnsiChar): Boolean; static;
    class function CopyText(const AText: AnsiString; ABuffer: PAnsiChar;
      ABufferSize: Cardinal): Cardinal; static;
    class function BuildArguments(const AWadPath, AGwaPath: string;
      AOptions: Cardinal): string; static;
    function Validate(AWadPath, AGwaPath: PAnsiChar; AOptions,
      ATimeoutMs: Cardinal): Integer;
    function Run(const AWadPath, AGwaPath: string; AOptions,
      ATimeoutMs: Cardinal): Integer;
  public
    /// <summary>
    ///   Uses the glbsp executable embedded in the DLL
    /// </summary>
    constructor Create; overload;

    /// <summary>
    ///   Uses another program in place of glbsp (for the tests); the bytes
    ///   must stay valid for the whole life of the engine
    /// </summary>
    constructor Create(AExecutable: Pointer; AExecutableSize: Cardinal); overload;

    // IGlbsp
    function GetExecutableSize: Cardinal; stdcall;
    function BuildNodes(AWadPath, AGwaPath: PAnsiChar; AOptions,
      ATimeoutMs: Cardinal): Integer; stdcall;
    function GetExitCode: Cardinal; stdcall;
    function GetOutput(ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal; stdcall;
    function GetErrorText(ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal; stdcall;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Glbsp.Executable, DelphiDoom.Glbsp.Runner;

{ TGlbspEngine }

constructor TGlbspEngine.Create;
begin
  Create(GlbspExecutableData, GlbspExecutableSize);
end;

constructor TGlbspEngine.Create(AExecutable: Pointer; AExecutableSize: Cardinal);
begin
  inherited Create;
  if not Assigned(AExecutable) then
    raise EArgumentNilException.Create('AExecutable');
  if AExecutableSize = 0 then
    raise EArgumentException.Create('AExecutableSize must be greater than zero');
  FExecutable := AExecutable;
  FExecutableSize := AExecutableSize;
end;

class function TGlbspEngine.IsValidPath(APath: PAnsiChar): Boolean;
var
  LLength: Integer;
begin
  Result := False;
  if not Assigned(APath) then
    Exit;

  // Never read past the limit: the caller's string may be unterminated
  LLength := 0;
  while APath[LLength] <> #0 do
  begin
    // The path is written between double quotes in the command line
    if (APath[LLength] < #32) or (APath[LLength] = '"') then
      Exit;
    Inc(LLength);
    if LLength > GLBSP_MAX_PATH_LENGTH then
      Exit;
  end;

  if LLength = 0 then
    Exit;
  // A leading dash would be read as an option by glbsp; a trailing backslash
  // would escape the closing double quote
  if (APath[0] = '-') or (APath[LLength - 1] = '\') then
    Exit;
  Result := True;
end;

class function TGlbspEngine.CopyText(const AText: AnsiString;
  ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal;
var
  LCount: Cardinal;
begin
  Result := Length(AText);
  if not Assigned(ABuffer) or (ABufferSize = 0) then
    Exit;

  LCount := Result;
  if LCount > ABufferSize - 1 then
    LCount := ABufferSize - 1;
  if LCount > 0 then
    Move(PAnsiChar(AText)^, ABuffer^, LCount);
  ABuffer[LCount] := #0;
end;

class function TGlbspEngine.BuildArguments(const AWadPath, AGwaPath: string;
  AOptions: Cardinal): string;
begin
  // Same order as the command lines the engine has always used:
  // "wad" -q -xp -o "gwa" -hexen
  Result := '"' + AWadPath + '"';
  if (AOptions and GLBSP_OPT_QUIET) <> 0 then
    Result := Result + ' -q';
  if (AOptions and GLBSP_OPT_NO_PROGRESS) <> 0 then
    Result := Result + ' -xp';
  Result := Result + ' -o "' + AGwaPath + '"';
  if (AOptions and GLBSP_OPT_HEXEN) <> 0 then
    Result := Result + ' -hexen';
end;

function TGlbspEngine.Validate(AWadPath, AGwaPath: PAnsiChar; AOptions,
  ATimeoutMs: Cardinal): Integer;
begin
  Result := GLBSP_ERR_INVALID_ARGUMENT;
  if not IsValidPath(AWadPath) then
    FErrorText := 'The WAD path is empty, too long or has invalid characters'
  else if not IsValidPath(AGwaPath) then
    FErrorText := 'The output path is empty, too long or has invalid characters'
  else if (AOptions and not Cardinal(GLBSP_OPT_ALL)) <> 0 then
    FErrorText := 'Unknown option flags'
  else if (ATimeoutMs < GLBSP_MIN_TIMEOUT_MS) or
    (ATimeoutMs > GLBSP_MAX_TIMEOUT_MS) then
    FErrorText := 'The timeout is out of range'
  else if SameText(ExpandFileName(string(AnsiString(AWadPath))),
    ExpandFileName(string(AnsiString(AGwaPath)))) then
    // glbsp would overwrite its own input
    FErrorText := 'The output file cannot be the WAD file'
  else
    Result := GLBSP_OK;
end;

function TGlbspEngine.Run(const AWadPath, AGwaPath: string; AOptions,
  ATimeoutMs: Cardinal): Integer;
var
  LProcess: TGlbspProcess;
  LStatus: TGlbspRunStatus;
begin
  LProcess := TGlbspProcess.Create(FExecutable, FExecutableSize);
  try
    LStatus := LProcess.Run(BuildArguments(AWadPath, AGwaPath, AOptions),
      ATimeoutMs);
    FOutput := LProcess.Output;
    FExitCode := LProcess.ExitCode;
    FErrorText := AnsiString(LProcess.ErrorText);
  finally
    LProcess.Free;
  end;

  case LStatus of
    grsTempFileFailed:
      Exit(GLBSP_ERR_TEMP_FILE);
    grsLaunchFailed:
      Exit(GLBSP_ERR_LAUNCH);
    grsTimedOut:
      Exit(GLBSP_ERR_TIMEOUT);
  end;

  // The process ran to its end: its verdict is the exit code, and the output
  // file is what proves that the nodes were really written
  if FExitCode <> 0 then
  begin
    FErrorText := AnsiString(Format('glbsp exited with code %d', [FExitCode]));
    Exit(GLBSP_ERR_PROCESS_FAILED);
  end;
  if not FileExists(AGwaPath) then
  begin
    FErrorText := 'glbsp exited with code 0 but the output file does not exist';
    Exit(GLBSP_ERR_NO_OUTPUT);
  end;
  Result := GLBSP_OK;
end;

function TGlbspEngine.GetExecutableSize: Cardinal;
begin
  Result := FExecutableSize;
end;

function TGlbspEngine.BuildNodes(AWadPath, AGwaPath: PAnsiChar; AOptions,
  ATimeoutMs: Cardinal): Integer;
var
  LWadPath: string;
  LGwaPath: string;
begin
  FExitCode := 0;
  FOutput := '';
  FErrorText := '';
  try
    Result := Validate(AWadPath, AGwaPath, AOptions, ATimeoutMs);
    if Result <> GLBSP_OK then
      Exit;

    // The paths are ANSI, as the callers of the DLL write them
    LWadPath := string(AnsiString(AWadPath));
    LGwaPath := string(AnsiString(AGwaPath));

    // glbsp would fail on a missing input as well, but a precise error is
    // better than the output of a process that could not do anything
    if not FileExists(LWadPath) then
    begin
      FErrorText := AnsiString('WAD file not found: ' + LWadPath);
      Exit(GLBSP_ERR_WAD_NOT_FOUND);
    end;

    Result := Run(LWadPath, LGwaPath, AOptions, ATimeoutMs);
  except
    // An exception must never cross the DLL boundary
    on E: Exception do
    begin
      FErrorText := AnsiString(E.Message);
      Result := GLBSP_ERR_INTERNAL;
    end;
  end;
end;

function TGlbspEngine.GetExitCode: Cardinal;
begin
  Result := FExitCode;
end;

function TGlbspEngine.GetOutput(ABuffer: PAnsiChar;
  ABufferSize: Cardinal): Cardinal;
begin
  Result := CopyText(FOutput, ABuffer, ABufferSize);
end;

function TGlbspEngine.GetErrorText(ABuffer: PAnsiChar;
  ABufferSize: Cardinal): Cardinal;
begin
  Result := CopyText(FErrorText, ABuffer, ABufferSize);
end;

end.
