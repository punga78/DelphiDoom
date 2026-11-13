{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the crash logger of Windows             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.WindowsCrashLogger;

// Port of the filter of i_crashlog.pas (issue #185): the unhandled exception filter writes
// crash.txt next to the executable. It uses only Windows API calls and objects that were made
// when the logger was installed, so it works even if the heap is corrupted.
//
// A Win32 logger: the registers of the report are the ones of the x86 context. On Win64 Install
// does nothing (no crash.txt) until the report has a 64 bit form.

interface

{$IFDEF CPUX86}
uses
  Winapi.Windows;
{$ENDIF}

{$IFDEF CPUX86}
type
  /// <summary>What the unhandled exception filter receives (EXCEPTION_POINTERS)</summary>
  PCrashExceptionInfo = ^TExceptionPointers;

const
  CRASH_EXECUTE_HANDLER = 1;
{$ENDIF}

type
  /// <summary>Installs the unhandled exception filter that writes the crash report</summary>
  TWindowsCrashLogger = class
  public
    /// <summary>
    ///   Installs the filter; the report goes to AFileName, or to crash.txt in the folder of the
    ///   executable when AFileName is empty. Calling it again changes the file
    /// </summary>
    class procedure Install(const AFileName: string = ''); static;
{$IFDEF CPUX86}
    /// <summary>
    ///   Writes the report of AInfo to the file of the installed logger; false if the logger is not
    ///   installed or the file cannot be created. The filter calls it; the tests call it with a made-up exception
    /// </summary>
    class function Report(AInfo: PCrashExceptionInfo): Boolean; static;
{$ENDIF}
    /// <summary>Puts back the filter that was there before Install</summary>
    class procedure Uninstall; static;
  end;

implementation

{$IFDEF CPUX86}
uses
  DelphiDoom.EngineSystem.Types, DelphiDoom.EngineSystem.Intf,
  DelphiDoom.EngineSystem.CrashReportWriter, DelphiDoom.EngineSystem.FileCrashSink,
  DelphiDoom.EngineSystem.WindowsCrashMemory;

var
  // made by Install: the filter must not allocate when it runs
  GSink: ICrashFileSink = nil;
  GWriter: TCrashReportWriter = nil;
  GPath: array[0..MAX_PATH] of AnsiChar;
  GPathReady: Boolean = False;
  GCrashing: LongInt = 0;
  GPrevious: TFNTopLevelExceptionFilter = nil;

function CrashFilter(AInfo: PCrashExceptionInfo): LongInt; stdcall;
begin
  Result := CRASH_EXECUTE_HANDLER;
  if InterlockedExchange(GCrashing, 1) = 0 then
    TWindowsCrashLogger.Report(AInfo);
end;

{ TWindowsCrashLogger }

class procedure TWindowsCrashLogger.Install(const AFileName: string);
var
  LName: AnsiString;
  LLength: Integer;
  LLastSlash: Integer;
begin
  if not Assigned(GWriter) then
  begin
    GSink := TFileCrashSink.Create;
    GWriter := TCrashReportWriter.Create(GSink, TWindowsCrashMemory.Create);
  end;

  GPathReady := False;
  if AFileName <> '' then
  begin
    LName := AnsiString(AFileName);
    if Length(LName) > MAX_PATH then
      SetLength(LName, MAX_PATH);
    Move(Pointer(LName)^, GPath[0], Length(LName));
    GPath[Length(LName)] := #0;
    GPathReady := True;
  end
  else
  begin
    // the folder of the executable: everything up to the last backslash, then crash.txt
    LLength := GetModuleFileNameA(0, GPath, MAX_PATH);
    LLastSlash := -1;
    while LLength > 0 do
    begin
      Dec(LLength);
      if GPath[LLength] = '\' then
      begin
        LLastSlash := LLength;
        Break;
      end;
    end;
    if LLastSlash >= 0 then
    begin
      lstrcpyA(@GPath[LLastSlash + 1], 'crash.txt');
      GPathReady := True;
    end;
  end;

  if not Assigned(GPrevious) then
    GPrevious := SetUnhandledExceptionFilter(@CrashFilter);
end;

class function TWindowsCrashLogger.Report(AInfo: PCrashExceptionInfo): Boolean;
var
  LFile: THandle;
  LSnapshot: TCrashSnapshot;
  LNtHeaders: PImageNtHeaders;
  LContext: PContext;
  LRecord: PExceptionRecord;
begin
  Result := False;
  if not (Assigned(GWriter) and GPathReady) then
    Exit;

  LFile := CreateFileA(@GPath[0], GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if LFile = INVALID_HANDLE_VALUE then
    Exit;

  LSnapshot.ImageBase := Cardinal(GetModuleHandle(nil));
  LNtHeaders := PImageNtHeaders(NativeUInt(LSnapshot.ImageBase) +
    NativeUInt(PImageDosHeader(NativeUInt(LSnapshot.ImageBase))._lfanew));
  LSnapshot.ImageSize := LNtHeaders.OptionalHeader.SizeOfImage;
  LContext := AInfo.ContextRecord;
  LRecord := AInfo.ExceptionRecord;
  LSnapshot.ExceptionCode := LRecord.ExceptionCode;
  LSnapshot.ExceptionAddress := Cardinal(LRecord.ExceptionAddress);
  LSnapshot.ThreadId := GetCurrentThreadId;
  LSnapshot.ParameterCount := LRecord.NumberParameters;
  LSnapshot.Parameter0 := LRecord.ExceptionInformation[0];
  LSnapshot.Parameter1 := LRecord.ExceptionInformation[1];
  LSnapshot.Eip := LContext.Eip;
  LSnapshot.Esp := LContext.Esp;
  LSnapshot.Ebp := LContext.Ebp;
  LSnapshot.Eax := LContext.Eax;
  LSnapshot.Ebx := LContext.Ebx;
  LSnapshot.Ecx := LContext.Ecx;
  LSnapshot.Edx := LContext.Edx;
  LSnapshot.Esi := LContext.Esi;
  LSnapshot.Edi := LContext.Edi;

  GSink.SetTarget(LFile);
  GWriter.Write(LSnapshot);
  CloseHandle(LFile);
  Result := True;
end;

class procedure TWindowsCrashLogger.Uninstall;
begin
  if Assigned(GPrevious) then
  begin
    SetUnhandledExceptionFilter(GPrevious);
    GPrevious := nil;
  end;
  GCrashing := 0;
end;

{$ELSE}

{ TWindowsCrashLogger }

class procedure TWindowsCrashLogger.Install(const AFileName: string);
begin
  // no report for a 64 bit process yet
end;

class procedure TWindowsCrashLogger.Uninstall;
begin
end;

{$ENDIF}

end.
