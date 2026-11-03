{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - contract shared by the DLL and its clients              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Intf;

interface

uses
  System.SysUtils;

const
  // Result codes (zero is success, every error is negative)
  GLBSP_OK = 0;
  GLBSP_ERR_INVALID_ARGUMENT = -1;
  GLBSP_ERR_WAD_NOT_FOUND = -2;
  GLBSP_ERR_TEMP_FILE = -3;
  GLBSP_ERR_LAUNCH = -4;
  GLBSP_ERR_TIMEOUT = -5;
  GLBSP_ERR_PROCESS_FAILED = -6;
  GLBSP_ERR_NO_OUTPUT = -7;
  GLBSP_ERR_LOAD_LIBRARY = -8;
  GLBSP_ERR_INTERNAL = -9;

  // Options of IGlbsp.BuildNodes (flags that can be combined)
  GLBSP_OPT_NONE = 0;
  /// <summary>glbsp -q: quiet, only the errors are printed</summary>
  GLBSP_OPT_QUIET = 1;
  /// <summary>glbsp -xp: no progress indicator in the output</summary>
  GLBSP_OPT_NO_PROGRESS = 2;
  /// <summary>glbsp -hexen: the map is in Hexen format</summary>
  GLBSP_OPT_HEXEN = 4;
  GLBSP_OPT_ALL = GLBSP_OPT_QUIET or GLBSP_OPT_NO_PROGRESS or GLBSP_OPT_HEXEN;

  // Limits checked by the engine before starting the process
  GLBSP_MAX_PATH_LENGTH = 1024;
  GLBSP_MIN_TIMEOUT_MS = 1;
  GLBSP_MAX_TIMEOUT_MS = 60 * 60 * 1000;
  GLBSP_DEFAULT_TIMEOUT_MS = 5 * 60 * 1000;

  // Name of the DLL and of its only export
  DDGLBSP_LIBRARY_NAME = 'DDGlbsp.dll';
  DDGLBSP_CREATE_EXPORT = 'DDGlbspCreate';

type
  /// <summary>
  ///   Contract of the glbsp DLL: builds the GL-friendly nodes of a WAD
  /// </summary>
  /// <remarks>
  ///   glbsp is not a library but a console program. The DLL carries it as an
  ///   array of bytes, writes it to a unique temporary file, runs it hidden
  ///   with its output captured through a pipe, waits for it (with a timeout)
  ///   and deletes the file. Only ANSI strings and integers cross the DLL
  ///   boundary: the caller owns every buffer and the DLL never allocates
  ///   memory the caller has to free. Methods are stdcall so that the binary
  ///   layout does not depend on the compiler settings of the client.
  ///   One IGlbsp keeps the result of its last BuildNodes: call it from a
  ///   single thread, or use one IGlbsp per thread
  /// </remarks>
  IGlbsp = interface
    ['{7C2F4E18-3B6A-4D95-A1E0-5D8B9C3F2A64}']

    /// <summary>
    ///   Length in bytes of the glbsp executable inside the DLL
    /// </summary>
    function GetExecutableSize: Cardinal; stdcall;

    /// <summary>
    ///   Builds the nodes of AWadPath and writes them to AGwaPath, running
    ///   glbsp as: glbsp "AWadPath" [-q] [-xp] -o "AGwaPath" [-hexen]
    /// </summary>
    /// <param name="AWadPath">
    ///   Existing WAD file (ANSI). It must not be empty, longer than
    ///   GLBSP_MAX_PATH_LENGTH, start with a dash (it would be read as an
    ///   option), end with a backslash or contain a double quote or a control
    ///   character
    /// </param>
    /// <param name="AGwaPath">
    ///   Output file (ANSI), with the same rules; it must be a different file
    ///   from AWadPath. The directory must exist
    /// </param>
    /// <param name="AOptions">
    ///   Combination of GLBSP_OPT_* flags
    /// </param>
    /// <param name="ATimeoutMs">
    ///   Maximum time the process may run, GLBSP_MIN_TIMEOUT_MS..
    ///   GLBSP_MAX_TIMEOUT_MS. When it expires the process is killed
    /// </param>
    /// <returns>
    ///   GLBSP_OK if glbsp exited with code zero and AGwaPath exists;
    ///   GLBSP_ERR_INVALID_ARGUMENT, GLBSP_ERR_WAD_NOT_FOUND,
    ///   GLBSP_ERR_TEMP_FILE (the executable cannot be written),
    ///   GLBSP_ERR_LAUNCH (the process cannot be started),
    ///   GLBSP_ERR_TIMEOUT, GLBSP_ERR_PROCESS_FAILED (non zero exit code),
    ///   GLBSP_ERR_NO_OUTPUT (exit code zero but no output file) or
    ///   GLBSP_ERR_INTERNAL. The output of the process and its exit code are
    ///   available through GetOutput and GetExitCode even after a failure
    /// </returns>
    function BuildNodes(AWadPath, AGwaPath: PAnsiChar; AOptions,
      ATimeoutMs: Cardinal): Integer; stdcall;

    /// <summary>
    ///   Exit code of the process of the last BuildNodes (zero if the
    ///   process did not run to its end)
    /// </summary>
    function GetExitCode: Cardinal; stdcall;

    /// <summary>
    ///   Copies into ABuffer the text the process of the last BuildNodes
    ///   printed (zero terminated, 8 bit, truncated to ABufferSize - 1
    ///   characters)
    /// </summary>
    /// <returns>
    ///   Length of the whole text, without the terminator: when it is not
    ///   less than ABufferSize the text was truncated. ABuffer may be nil to
    ///   ask for the length only
    /// </returns>
    function GetOutput(ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal; stdcall;

    /// <summary>
    ///   Same as GetOutput, for the textual detail of the last failure
    ///   (for instance the system message of a process that cannot start)
    /// </summary>
    function GetErrorText(ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal; stdcall;
  end;

  /// <summary>
  ///   Signature of the export DDGLBSP_CREATE_EXPORT of the DLL. Returns
  ///   GLBSP_OK and an IGlbsp on success; nothing is written or started until
  ///   IGlbsp.BuildNodes is called
  /// </summary>
  TDDGlbspCreate = function(out AGlbsp: IGlbsp): Integer; stdcall;

  /// <summary>
  ///   Raised by the classes that wrap the DLL
  /// </summary>
  EGlbspException = class(Exception)
  private
    FCode: Integer;
  public
    constructor CreateCode(ACode: Integer); overload;
    constructor CreateCode(ACode: Integer; const ADetail: string); overload;
    class function TextOf(ACode: Integer): string; static;
    property Code: Integer read FCode;
  end;

implementation

{ EGlbspException }

constructor EGlbspException.CreateCode(ACode: Integer);
begin
  FCode := ACode;
  inherited CreateFmt('glbsp error %d: %s', [ACode, TextOf(ACode)]);
end;

constructor EGlbspException.CreateCode(ACode: Integer; const ADetail: string);
begin
  FCode := ACode;
  if ADetail = '' then
    inherited CreateFmt('glbsp error %d: %s', [ACode, TextOf(ACode)])
  else
    inherited CreateFmt('glbsp error %d: %s (%s)',
      [ACode, TextOf(ACode), ADetail]);
end;

class function EGlbspException.TextOf(ACode: Integer): string;
begin
  case ACode of
    GLBSP_OK:                   Result := 'OK';
    GLBSP_ERR_INVALID_ARGUMENT: Result := 'Invalid argument';
    GLBSP_ERR_WAD_NOT_FOUND:    Result := 'WAD file not found';
    GLBSP_ERR_TEMP_FILE:        Result := 'Cannot write the glbsp program to a temporary file';
    GLBSP_ERR_LAUNCH:           Result := 'Cannot start the glbsp process';
    GLBSP_ERR_TIMEOUT:          Result := 'The glbsp process did not finish in time';
    GLBSP_ERR_PROCESS_FAILED:   Result := 'The glbsp process failed';
    GLBSP_ERR_NO_OUTPUT:        Result := 'glbsp did not create the output file';
    GLBSP_ERR_LOAD_LIBRARY:     Result := 'Cannot load the glbsp library';
    GLBSP_ERR_INTERNAL:         Result := 'Internal error';
  else
    Result := 'Unknown error';
  end;
end;

end.
