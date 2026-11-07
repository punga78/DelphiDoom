{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - a program run in the background              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.ProcessRunner;

interface

uses
  DelphiDoom.Platform.Intf, DelphiDoom.Platform.Types;

type
  /// <summary>
  ///   IProcessRunner with CreateProcess: standard output and error of the child go to one
  ///   anonymous pipe that is read until the child closes it
  /// </summary>
  TProcessRunner = class(TInterfacedObject, IProcessRunner)
  strict private
    class procedure CloseIfOpen(var AHandle: THandle); static;
  public
    function Run(const ACommandLine: string; const AOutput: TProcessOutputEvent): Boolean;
  end;

implementation

uses
  Winapi.Windows;

{ TProcessRunner }

class procedure TProcessRunner.CloseIfOpen(var AHandle: THandle);
begin
  if AHandle <> 0 then
  begin
    CloseHandle(AHandle);
    AHandle := 0;
  end;
end;

function TProcessRunner.Run(const ACommandLine: string; const AOutput: TProcessOutputEvent): Boolean;
var
  LReadPipe: THandle;
  LWritePipe: THandle;
  LErrorPipe: THandle;
  LAttributes: TSecurityAttributes;
  LStartup: TStartupInfo;
  LProcess: TProcessInformation;
  LCommand: string;
  LBuffer: array[0..1023] of AnsiChar;
  LBytesRead: DWORD;
  LText: AnsiString;
  LReadOk: Boolean;
  LDone: Boolean;
begin
  Result := False;
  LReadPipe := 0;
  LWritePipe := 0;
  LErrorPipe := 0;
  LAttributes.nLength := SizeOf(TSecurityAttributes);
  LAttributes.lpSecurityDescriptor := nil;
  // the child must inherit the write end: the handle is inheritable
  LAttributes.bInheritHandle := True;
  if not CreatePipe(LReadPipe, LWritePipe, @LAttributes, 0) then
    Exit;
  try
    // the child must not inherit the read end, or the pipe never closes
    if not SetHandleInformation(LReadPipe, HANDLE_FLAG_INHERIT, 0) then
      Exit;
    // a distinct handle for the standard error: the child may close one of the two
    if not DuplicateHandle(GetCurrentProcess, LWritePipe, GetCurrentProcess, @LErrorPipe, 0, True,
      DUPLICATE_SAME_ACCESS) then
      Exit;

    FillChar(LStartup, SizeOf(LStartup), 0);
    LStartup.cb := SizeOf(LStartup);
    LStartup.hStdInput := LErrorPipe;
    LStartup.hStdOutput := LWritePipe;
    LStartup.hStdError := LErrorPipe;
    // wShowWindow is 0 (hidden)
    LStartup.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;

    // CreateProcess may write in the command line
    LCommand := ACommandLine;
    UniqueString(LCommand);
    if not CreateProcess(nil, PChar(LCommand), nil, nil, True, 0, nil, nil, LStartup, LProcess) then
      Exit;
    CloseHandle(LProcess.hThread);
    CloseHandle(LProcess.hProcess);

    // our copies of the write ends must go: the pipe closes when the child's go
    CloseIfOpen(LWritePipe);
    CloseIfOpen(LErrorPipe);

    Result := True;
    LDone := False;
    while not LDone do
    begin
      LReadOk := ReadFile(LReadPipe, LBuffer, SizeOf(LBuffer), LBytesRead, nil);
      if LReadOk then
      begin
        if (LBytesRead > 0) and Assigned(AOutput) then
        begin
          SetString(LText, PAnsiChar(@LBuffer[0]), LBytesRead);
          AOutput(LText);
        end;
      end
      else
      begin
        LDone := True;
        // a pipe that was closed is the normal end; anything else is an error
        Result := GetLastError = ERROR_BROKEN_PIPE;
      end;
    end;
  finally
    CloseIfOpen(LReadPipe);
    CloseIfOpen(LWritePipe);
    CloseIfOpen(LErrorPipe);
  end;
end;

end.
