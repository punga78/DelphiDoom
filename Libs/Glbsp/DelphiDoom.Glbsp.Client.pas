{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - the class the engine uses in place of the node builder  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Client;

interface

uses
  System.SysUtils, DelphiDoom.Glbsp.Intf;

type
  /// <summary>
  ///   Options of glbsp: -q, -xp and -hexen
  /// </summary>
  TGlbspOption = (goQuiet, goNoProgress, goHexen);
  TGlbspOptions = set of TGlbspOption;

  /// <summary>
  ///   Stands for the glbsp node builder in the rest of the engine: works
  ///   with string and raises EGlbspException instead of returning error
  ///   codes
  /// </summary>
  /// <remarks>
  ///   Depends only on IGlbsp, so it works the same with the DLL (see
  ///   TGlbspLoader), with an engine linked in the executable, or with a fake
  ///   in the tests. The IGlbsp passed to the constructor is not owned
  /// </remarks>
  TGlbspClient = class
  private
    type
      TTextReader = reference to function(ABuffer: PAnsiChar;
        ABufferSize: Cardinal): Cardinal;
  private
    FGlbsp: IGlbsp;
    FOutput: string;
    FExitCode: Cardinal;
    class function ToAnsi(const APath: string): AnsiString; static;
    class function ReadText(const AReader: TTextReader): string; static;
  public
    constructor Create(const AGlbsp: IGlbsp);

    /// <summary>
    ///   Length in bytes of the glbsp program inside the library
    /// </summary>
    function ExecutableSize: Cardinal;

    /// <summary>
    ///   Builds the GL-friendly nodes of AWadPath into AGwaPath. Both paths
    ///   must be representable in the ANSI code page. Raises EGlbspException
    ///   (with the detail of the failure in its message) if the WAD does not
    ///   exist, glbsp fails, does not write the output file or does not
    ///   finish within ATimeoutMs. Output and ExitCode are updated also when
    ///   it raises
    /// </summary>
    procedure BuildNodes(const AWadPath, AGwaPath: string;
      AOptions: TGlbspOptions = [goQuiet, goNoProgress];
      ATimeoutMs: Cardinal = GLBSP_DEFAULT_TIMEOUT_MS);

    /// <summary>
    ///   What glbsp printed during the last BuildNodes (the code page of the
    ///   console is taken as the ANSI one)
    /// </summary>
    property Output: string read FOutput;

    /// <summary>
    ///   Exit code of glbsp in the last BuildNodes
    /// </summary>
    property ExitCode: Cardinal read FExitCode;
  end;

implementation

{ TGlbspClient }

constructor TGlbspClient.Create(const AGlbsp: IGlbsp);
begin
  inherited Create;
  if not Assigned(AGlbsp) then
    raise EArgumentNilException.Create('AGlbsp');
  FGlbsp := AGlbsp;
end;

class function TGlbspClient.ToAnsi(const APath: string): AnsiString;
begin
  Result := AnsiString(APath);
  if string(Result) <> APath then
    raise EGlbspException.CreateCode(GLBSP_ERR_INVALID_ARGUMENT,
      'The path cannot be written in the ANSI code page: ' + APath);
end;

class function TGlbspClient.ReadText(const AReader: TTextReader): string;
var
  LText: AnsiString;
  LLength: Cardinal;
begin
  LLength := AReader(nil, 0);
  if LLength = 0 then
    Exit('');

  SetLength(LText, LLength);
  // The buffer includes room for the terminator
  AReader(PAnsiChar(LText), LLength + 1);
  Result := string(LText);
end;

function TGlbspClient.ExecutableSize: Cardinal;
begin
  Result := FGlbsp.GetExecutableSize;
end;

procedure TGlbspClient.BuildNodes(const AWadPath, AGwaPath: string;
  AOptions: TGlbspOptions; ATimeoutMs: Cardinal);
var
  LWadPath: AnsiString;
  LGwaPath: AnsiString;
  LFlags: Cardinal;
  LCode: Integer;
begin
  LWadPath := ToAnsi(AWadPath);
  LGwaPath := ToAnsi(AGwaPath);

  LFlags := GLBSP_OPT_NONE;
  if goQuiet in AOptions then
    LFlags := LFlags or GLBSP_OPT_QUIET;
  if goNoProgress in AOptions then
    LFlags := LFlags or GLBSP_OPT_NO_PROGRESS;
  if goHexen in AOptions then
    LFlags := LFlags or GLBSP_OPT_HEXEN;

  LCode := FGlbsp.BuildNodes(PAnsiChar(LWadPath), PAnsiChar(LGwaPath), LFlags,
    ATimeoutMs);

  FExitCode := FGlbsp.GetExitCode;
  FOutput := ReadText(
    function(ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal
    begin
      Result := FGlbsp.GetOutput(ABuffer, ABufferSize);
    end);

  if LCode <> GLBSP_OK then
    raise EGlbspException.CreateCode(LCode, ReadText(
      function(ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal
      begin
        Result := FGlbsp.GetErrorText(ABuffer, ABufferSize);
      end));
end;

end.
