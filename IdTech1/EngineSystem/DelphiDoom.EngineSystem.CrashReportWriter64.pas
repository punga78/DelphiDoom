{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the crash report of a 64 bit process    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.CrashReportWriter64;

// The 64 bit form of the report of TCrashReportWriter (issue #40): the same layout, with the
// registers of x64 (Rip, Rsp, Rbp, Rax ... R15), 16 digit values and, instead of the walk of the
// EBP chain (x64 code has no frame pointer chain), the return addresses that the unwinder of
// Windows found and the caller put in the snapshot. Offsets are from the image base, to be looked
// up in the .map file next to the executable. Like the 32 bit writer it does not allocate: it
// runs inside the unhandled exception filter.

interface

uses
  DelphiDoom.EngineSystem.Types, DelphiDoom.EngineSystem.Intf;

const
  /// <summary>How many qwords of the stack the scan reads</summary>
  CRASH_STACK_QWORDS = 512;

type
  /// <summary>Writes the crash report of a 64 bit process to a sink, reading the stack from a memory</summary>
  TCrashReportWriter64 = class
  strict private
    FSink: ICrashSink;
    FMemory: ICrashMemory64;
    procedure WriteText(AText: PAnsiChar);
    procedure WriteHex(AValue: UInt64);
    procedure WriteLine(AName: PAnsiChar; AValue: UInt64);
    procedure WriteFrames(const ASnapshot: TCrashSnapshot64);
    procedure WriteStackScan(const ASnapshot: TCrashSnapshot64);
    function InsideImage(const ASnapshot: TCrashSnapshot64; AAddress: UInt64): Boolean;
  public
    /// <summary>The sink gets the text; the memory says what the stack scan can read. Both are needed</summary>
    constructor Create(const ASink: ICrashSink; const AMemory: ICrashMemory64);
    /// <summary>The whole report of ASnapshot</summary>
    procedure Write(const ASnapshot: TCrashSnapshot64);
  end;

implementation

uses
  System.SysUtils;

{ TCrashReportWriter64 }

constructor TCrashReportWriter64.Create(const ASink: ICrashSink; const AMemory: ICrashMemory64);
begin
  inherited Create;
  if not Assigned(ASink) then
    raise EArgumentNilException.CreateFmt(SNullPointerArgument, ['ASink']);
  if not Assigned(AMemory) then
    raise EArgumentNilException.CreateFmt(SNullPointerArgument, ['AMemory']);
  FSink := ASink;
  FMemory := AMemory;
end;

procedure TCrashReportWriter64.WriteText(AText: PAnsiChar);
begin
  FSink.Write(AText);
end;

procedure TCrashReportWriter64.WriteHex(AValue: UInt64);
const
  DIGITS: array[0..15] of AnsiChar = '0123456789ABCDEF';
var
  LBuffer: array[0..17] of AnsiChar;
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    LBuffer[LIndex] := DIGITS[(AValue shr ((15 - LIndex) * 4)) and $F];
  LBuffer[16] := ' ';
  LBuffer[17] := #0;
  WriteText(@LBuffer[0]);
end;

procedure TCrashReportWriter64.WriteLine(AName: PAnsiChar; AValue: UInt64);
begin
  WriteText(AName);
  WriteHex(AValue);
  WriteText(#13#10);
end;

function TCrashReportWriter64.InsideImage(const ASnapshot: TCrashSnapshot64; AAddress: UInt64): Boolean;
begin
  Result := (AAddress >= ASnapshot.ImageBase) and (AAddress - ASnapshot.ImageBase < ASnapshot.ImageSize);
end;

// The return addresses that the unwinder found, as offsets from the image base
procedure TCrashReportWriter64.WriteFrames(const ASnapshot: TCrashSnapshot64);
var
  LIndex: Integer;
  LCount: Integer;
begin
  WriteText(#13#10'Unwind chain (return address - ImageBase):'#13#10);
  LCount := ASnapshot.FrameCount;
  if LCount > CRASH_MAX_FRAMES_64 then
    LCount := CRASH_MAX_FRAMES_64;
  for LIndex := 0 to LCount - 1 do
    if InsideImage(ASnapshot, ASnapshot.Frames[LIndex]) then
      WriteLine('  ', ASnapshot.Frames[LIndex] - ASnapshot.ImageBase)
    else
      WriteLine('  (outside) ', ASnapshot.Frames[LIndex]);
end;

// Stack scan: any qword that looks like a code address inside the image
procedure TCrashReportWriter64.WriteStackScan(const ASnapshot: TCrashSnapshot64);
var
  LIndex: Integer;
  LStack: UInt64;
  LAddress: UInt64;
begin
  WriteText(#13#10'Stack scan (code addresses - ImageBase):'#13#10);
  LStack := ASnapshot.Rsp;
  for LIndex := 0 to CRASH_STACK_QWORDS - 1 do
  begin
    if not FMemory.IsReadable(LStack, 8) then
      Break;
    LAddress := FMemory.ReadQWord(LStack);
    if (LAddress >= ASnapshot.ImageBase + $1000) and InsideImage(ASnapshot, LAddress) then
      WriteLine('  ', LAddress - ASnapshot.ImageBase);
    Inc(LStack, 8);
  end;
end;

procedure TCrashReportWriter64.Write(const ASnapshot: TCrashSnapshot64);
begin
  WriteText('DelphiDoom crash report (64 bit)'#13#10);
  WriteLine('ExceptionCode   ', ASnapshot.ExceptionCode);
  WriteLine('ExceptionAddr   ', ASnapshot.ExceptionAddress);
  WriteLine('ImageBase       ', ASnapshot.ImageBase);
  WriteLine('ImageSize       ', ASnapshot.ImageSize);
  WriteLine('ThreadId        ', ASnapshot.ThreadId);
  if InsideImage(ASnapshot, ASnapshot.ExceptionAddress) then
    WriteLine('Addr-ImageBase  ', ASnapshot.ExceptionAddress - ASnapshot.ImageBase)
  else
    WriteText('Addr is outside the executable image'#13#10);
  if (ASnapshot.ExceptionCode = CRASH_EXCEPTION_ACCESS_VIOLATION) and
     (ASnapshot.ParameterCount >= 2) then
  begin
    WriteLine('AV operation    ', ASnapshot.Parameter0);
    WriteLine('AV address      ', ASnapshot.Parameter1);
  end;

  WriteLine('RIP ', ASnapshot.Rip);
  WriteLine('RSP ', ASnapshot.Rsp);
  WriteLine('RBP ', ASnapshot.Rbp);
  WriteLine('RAX ', ASnapshot.Rax);
  WriteLine('RBX ', ASnapshot.Rbx);
  WriteLine('RCX ', ASnapshot.Rcx);
  WriteLine('RDX ', ASnapshot.Rdx);
  WriteLine('RSI ', ASnapshot.Rsi);
  WriteLine('RDI ', ASnapshot.Rdi);
  WriteLine('R8  ', ASnapshot.R8);
  WriteLine('R9  ', ASnapshot.R9);
  WriteLine('R10 ', ASnapshot.R10);
  WriteLine('R11 ', ASnapshot.R11);
  WriteLine('R12 ', ASnapshot.R12);
  WriteLine('R13 ', ASnapshot.R13);
  WriteLine('R14 ', ASnapshot.R14);
  WriteLine('R15 ', ASnapshot.R15);

  WriteFrames(ASnapshot);
  WriteStackScan(ASnapshot);
end;

end.
