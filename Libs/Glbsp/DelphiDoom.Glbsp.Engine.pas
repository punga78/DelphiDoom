{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - implementation of IGlbsp on top of the Pascal node      }
{  builder                                                                     }
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
  ///   Implements IGlbsp with TGlbspWadBuilder: the nodes are built in the
  ///   process, with no external program
  /// </summary>
  /// <remarks>
  ///   An output path that ends with ".gwa" gets only the new lumps (a GWA
  ///   file), as with the glbsp program; any other output is the whole WAD
  ///   with the new lumps. The output file is written only when the build
  ///   succeeded. Not thread safe: the engine keeps the result of the last
  ///   BuildNodes
  /// </remarks>
  TGlbspEngine = class(TInterfacedObject, IGlbsp)
  private
    FExitCode: Cardinal;
    FOutput: AnsiString;
    FErrorText: AnsiString;
    class function IsValidPath(APath: PAnsiChar): Boolean; static;
    class function CopyText(const AText: AnsiString; ABuffer: PAnsiChar;
      ABufferSize: Cardinal): Cardinal; static;
    function Validate(AWadPath, AGwaPath: PAnsiChar; AOptions,
      ATimeoutMs: Cardinal): Integer;
    function Run(const AWadPath, AGwaPath: string; AOptions: Cardinal): Integer;
  public
    // IGlbsp
    function BuildNodes(AWadPath, AGwaPath: PAnsiChar; AOptions,
      ATimeoutMs: Cardinal): Integer; stdcall;
    function GetExitCode: Cardinal; stdcall;
    function GetOutput(ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal; stdcall;
    function GetErrorText(ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal; stdcall;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  DelphiDoom.Glbsp.Level.Types,
  DelphiDoom.Glbsp.Options,
  DelphiDoom.Glbsp.Wad.Builder,
  DelphiDoom.Glbsp.Wad.Types;

{ TGlbspEngine }

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
    // The contract keeps the rules of the time when the paths were put in a
    // command line: no quotes and no control characters
    if (APath[LLength] < #32) or (APath[LLength] = '"') then
      Exit;
    Inc(LLength);
    if LLength > GLBSP_MAX_PATH_LENGTH then
      Exit;
  end;

  if LLength = 0 then
    Exit;
  // A leading dash and a trailing backslash are refused for the same reason
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
    // The input would be overwritten
    FErrorText := 'The output file cannot be the WAD file'
  else
    Result := GLBSP_OK;
end;

function TGlbspEngine.Run(const AWadPath, AGwaPath: string; AOptions: Cardinal): Integer;
var
  LOptions: TGlbspOptions;
  LBuilder: TGlbspWadBuilder;
  LInput: TFileStream;
  LOutput: TBytesStream;
begin
  LOptions := TGlbspOptions.Default;
  LOptions.ForceHexen := (AOptions and GLBSP_OPT_HEXEN) <> 0;
  // A GWA file gets only the new lumps, as the glbsp program does
  LOptions.GwaMode := SameText(ExtractFileExt(AGwaPath), '.gwa');

  LBuilder := TGlbspWadBuilder.Create(LOptions);
  try
    LOutput := TBytesStream.Create;
    try
      try
        LInput := TFileStream.Create(AWadPath, fmOpenRead or fmShareDenyNone);
        try
          LBuilder.Build(LInput, LOutput);
        finally
          LInput.Free;
        end;
      except
        // The WAD or the level is not valid: the program would exit with an error
        on E: EGlbspWadException do
        begin
          FExitCode := 2;
          FErrorText := AnsiString(E.Message);
          Exit(GLBSP_ERR_PROCESS_FAILED);
        end;
        on E: EGlbspLevelException do
        begin
          FExitCode := 2;
          FErrorText := AnsiString(E.Message);
          Exit(GLBSP_ERR_PROCESS_FAILED);
        end;
        on E: EGlbspBuildException do
        begin
          FExitCode := 2;
          FErrorText := AnsiString(E.Message);
          Exit(GLBSP_ERR_PROCESS_FAILED);
        end;
      end;

      FOutput := AnsiString(LBuilder.Messages.Text);

      // The output file exists only if the whole build succeeded
      try
        TFile.WriteAllBytes(AGwaPath, Copy(LOutput.Bytes, 0, LOutput.Size));
      except
        on E: Exception do
        begin
          FErrorText := AnsiString('Cannot write the output file: ' + E.Message);
          Exit(GLBSP_ERR_NO_OUTPUT);
        end;
      end;
    finally
      LOutput.Free;
    end;
  finally
    LBuilder.Free;
  end;
  Result := GLBSP_OK;
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

    if not FileExists(LWadPath) then
    begin
      FErrorText := AnsiString('WAD file not found: ' + LWadPath);
      Exit(GLBSP_ERR_WAD_NOT_FOUND);
    end;

    // The timeout is accepted, but the build runs in this process and is not
    // interrupted
    Result := Run(LWadPath, LGwaPath, AOptions);
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

