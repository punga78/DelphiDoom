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
// At 32 bit the report has the registers of the x86 context and walks the EBP chain
// (TCrashReportWriter). At 64 bit (issue #40) it has the registers of the x64 context, the return
// addresses that the unwinder of Windows finds (RtlVirtualUnwind: x64 code has no frame pointer
// chain) and a stack scan (TCrashReportWriter64).

interface

uses
  Winapi.Windows;

type
  /// <summary>What the unhandled exception filter receives (EXCEPTION_POINTERS)</summary>
  PCrashExceptionInfo = ^TExceptionPointers;

const
  CRASH_EXECUTE_HANDLER = 1;

type
  /// <summary>Installs the unhandled exception filter that writes the crash report</summary>
  TWindowsCrashLogger = class
  public
    /// <summary>
    ///   Installs the filter; the report goes to AFileName, or to crash.txt in the folder of the
    ///   executable when AFileName is empty. Calling it again changes the file
    /// </summary>
    class procedure Install(const AFileName: string = ''); static;
    /// <summary>
    ///   Writes the report of AInfo to the file of the installed logger; false if the logger is not
    ///   installed or the file cannot be created. The filter calls it; the tests call it with a made-up exception
    /// </summary>
    class function Report(AInfo: PCrashExceptionInfo): Boolean; static;
    /// <summary>Puts back the filter that was there before Install</summary>
    class procedure Uninstall; static;
  end;

implementation

uses
  DelphiDoom.EngineSystem.Types, DelphiDoom.EngineSystem.Intf, DelphiDoom.EngineSystem.FileCrashSink,
{$IFDEF CPUX86}
  DelphiDoom.EngineSystem.CrashReportWriter, DelphiDoom.EngineSystem.WindowsCrashMemory;
{$ELSE}
  DelphiDoom.EngineSystem.CrashReportWriter64, DelphiDoom.EngineSystem.WindowsCrashMemory64;
{$ENDIF}

var
  // made by Install: the filter must not allocate when it runs
  GSink: ICrashFileSink = nil;
{$IFDEF CPUX86}
  GWriter: TCrashReportWriter = nil;
{$ELSE}
  GWriter: TCrashReportWriter64 = nil;
  GMemory: ICrashMemory64 = nil;
{$ENDIF}
  GPath: array[0..MAX_PATH] of AnsiChar;
  GPathReady: Boolean = False;
  GCrashing: LongInt = 0;
  GPrevious: TFNTopLevelExceptionFilter = nil;

{$IFNDEF CPUX86}
type
  PRuntimeFunctionEntry = Pointer;

const
  UNW_FLAG_NHANDLER = 0;

// kernel32 exports them; the RTL does not declare them
function RtlLookupFunctionEntry(AControlPc: UInt64; var AImageBase: UInt64;
  AHistoryTable: Pointer): PRuntimeFunctionEntry; stdcall; external kernel32;

function RtlVirtualUnwind(AHandlerType: DWORD; AImageBase, AControlPc: UInt64;
  AFunctionEntry: PRuntimeFunctionEntry; var AContext: TContext; var AHandlerData: Pointer;
  var AEstablisherFrame: UInt64; AContextPointers: Pointer): Pointer; stdcall; external kernel32;

// The return addresses of the crashed code, innermost first, by unwinding a copy of the context
// with the unwind data of the executable. A function without unwind data is a leaf: its return
// address is at the top of the stack. Nothing is allocated.
procedure CollectFrames(AContext: PContext; var ASnapshot: TCrashSnapshot64);
var
  LContext: TContext;
  LEntry: PRuntimeFunctionEntry;
  LUnwindBase: UInt64;
  LHandlerData: Pointer;
  LEstablisher: UInt64;
  LPreviousStack: UInt64;
  LIndex: Integer;
begin
  LContext := AContext^;
  ASnapshot.FrameCount := 0;
  for LIndex := 0 to CRASH_MAX_FRAMES_64 - 1 do
  begin
    LPreviousStack := LContext.Rsp;
    LUnwindBase := 0;
    LEntry := RtlLookupFunctionEntry(LContext.Rip, LUnwindBase, nil);
    if LEntry = nil then
    begin
      if not GMemory.IsReadable(LContext.Rsp, 8) then
        Break;
      LContext.Rip := GMemory.ReadQWord(LContext.Rsp);
      Inc(LContext.Rsp, 8);
    end
    else
    begin
      LHandlerData := nil;
      LEstablisher := 0;
      RtlVirtualUnwind(UNW_FLAG_NHANDLER, LUnwindBase, LContext.Rip, LEntry, LContext,
        LHandlerData, LEstablisher, nil);
    end;
    // the end of the chain, or a stack that does not go up: stop
    if (LContext.Rip = 0) or (LContext.Rsp <= LPreviousStack) then
      Break;
    ASnapshot.Frames[ASnapshot.FrameCount] := LContext.Rip;
    Inc(ASnapshot.FrameCount);
  end;
end;
{$ENDIF}

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
{$IFDEF CPUX86}
    GWriter := TCrashReportWriter.Create(GSink, TWindowsCrashMemory.Create);
{$ELSE}
    GMemory := TWindowsCrashMemory64.Create;
    GWriter := TCrashReportWriter64.Create(GSink, GMemory);
{$ENDIF}
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
{$IFDEF CPUX86}
  LSnapshot: TCrashSnapshot;
{$ELSE}
  LSnapshot: TCrashSnapshot64;
{$ENDIF}
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

{$IFDEF CPUX86}
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
{$ELSE}
  FillChar(LSnapshot, SizeOf(LSnapshot), 0);
  LSnapshot.ImageBase := UInt64(GetModuleHandle(nil));
  LNtHeaders := PImageNtHeaders(NativeUInt(LSnapshot.ImageBase) +
    NativeUInt(PImageDosHeader(NativeUInt(LSnapshot.ImageBase))._lfanew));
  LSnapshot.ImageSize := LNtHeaders.OptionalHeader.SizeOfImage;
  LContext := AInfo.ContextRecord;
  LRecord := AInfo.ExceptionRecord;
  LSnapshot.ExceptionCode := LRecord.ExceptionCode;
  LSnapshot.ExceptionAddress := UInt64(LRecord.ExceptionAddress);
  LSnapshot.ThreadId := GetCurrentThreadId;
  LSnapshot.ParameterCount := LRecord.NumberParameters;
  LSnapshot.Parameter0 := LRecord.ExceptionInformation[0];
  LSnapshot.Parameter1 := LRecord.ExceptionInformation[1];
  LSnapshot.Rip := LContext.Rip;
  LSnapshot.Rsp := LContext.Rsp;
  LSnapshot.Rbp := LContext.Rbp;
  LSnapshot.Rax := LContext.Rax;
  LSnapshot.Rbx := LContext.Rbx;
  LSnapshot.Rcx := LContext.Rcx;
  LSnapshot.Rdx := LContext.Rdx;
  LSnapshot.Rsi := LContext.Rsi;
  LSnapshot.Rdi := LContext.Rdi;
  LSnapshot.R8 := LContext.R8;
  LSnapshot.R9 := LContext.R9;
  LSnapshot.R10 := LContext.R10;
  LSnapshot.R11 := LContext.R11;
  LSnapshot.R12 := LContext.R12;
  LSnapshot.R13 := LContext.R13;
  LSnapshot.R14 := LContext.R14;
  LSnapshot.R15 := LContext.R15;
  CollectFrames(LContext, LSnapshot);
{$ENDIF}

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

end.
