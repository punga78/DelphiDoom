{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the crash report                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.CrashReportWriter;

// Port of the text of CrashFilter of i_crashlog.pas (issue #185): the exception, the registers, a
// walk of the EBP chain and a scan of the stack, all as offsets from the image base so that the
// linker map file can resolve them.
//
// The report is written while the program is crashing, perhaps with a corrupt heap: nothing here
// allocates (no string, no dynamic array, no exception), only the stack and the sink are used.
// The 32 bit wraparound of the additions of addresses is wanted (see the directives below).

{$Q-}
{$R-}

interface

uses
  DelphiDoom.EngineSystem.Types, DelphiDoom.EngineSystem.Intf;

type
  /// <summary>Writes the crash report of a 32 bit process to a sink, reading the stack from a memory</summary>
  TCrashReportWriter = class
  strict private
    FSink: ICrashSink;
    FMemory: ICrashMemory;
    procedure WriteText(AText: PAnsiChar);
    procedure WriteHex(AValue: Cardinal);
    procedure WriteLine(AName: PAnsiChar; AValue: Cardinal);
    procedure WriteFrames(const ASnapshot: TCrashSnapshot);
    procedure WriteStackScan(const ASnapshot: TCrashSnapshot);
  public
    /// <summary>The sink gets the text; the memory says what the stack scan can read. Both are needed</summary>
    constructor Create(const ASink: ICrashSink; const AMemory: ICrashMemory);
    /// <summary>The whole report of ASnapshot</summary>
    procedure Write(const ASnapshot: TCrashSnapshot);
  end;

const
  /// <summary>How many return addresses the walk of the EBP chain follows</summary>
  CRASH_MAX_FRAMES = 32;
  /// <summary>How many dwords of the stack the scan reads</summary>
  CRASH_STACK_DWORDS = 512;

implementation

{ TCrashReportWriter }

constructor TCrashReportWriter.Create(const ASink: ICrashSink; const AMemory: ICrashMemory);
begin
  inherited Create;
  FSink := ASink;
  FMemory := AMemory;
end;

procedure TCrashReportWriter.WriteText(AText: PAnsiChar);
begin
  FSink.Write(AText);
end;

procedure TCrashReportWriter.WriteHex(AValue: Cardinal);
const
  DIGITS: array[0..15] of AnsiChar = '0123456789ABCDEF';
var
  LBuffer: array[0..9] of AnsiChar;
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    LBuffer[LIndex] := DIGITS[(AValue shr ((7 - LIndex) * 4)) and $F];
  LBuffer[8] := ' ';
  LBuffer[9] := #0;
  WriteText(@LBuffer[0]);
end;

procedure TCrashReportWriter.WriteLine(AName: PAnsiChar; AValue: Cardinal);
begin
  WriteText(AName);
  WriteHex(AValue);
  WriteText(#13#10);
end;

// Walk the EBP chain: return addresses as offsets from the image base
procedure TCrashReportWriter.WriteFrames(const ASnapshot: TCrashSnapshot);
var
  LIndex: Integer;
  LFrame: Cardinal;
  LAddress: Cardinal;
begin
  WriteText(#13#10'EBP chain (return address - ImageBase):'#13#10);
  LFrame := ASnapshot.Ebp;
  for LIndex := 0 to CRASH_MAX_FRAMES - 1 do
  begin
    if (LFrame = 0) or not FMemory.IsReadable(LFrame, 8) then
      Break;
    LAddress := FMemory.ReadDWord(LFrame + 4);
    if (LAddress >= ASnapshot.ImageBase) and (LAddress < ASnapshot.ImageBase + ASnapshot.ImageSize) then
      WriteLine('  ', LAddress - ASnapshot.ImageBase)
    else
      WriteLine('  (outside) ', LAddress);
    if FMemory.ReadDWord(LFrame) <= LFrame then
      Break;
    LFrame := FMemory.ReadDWord(LFrame);
  end;
end;

// Stack scan: any dword that looks like a code address inside the image
procedure TCrashReportWriter.WriteStackScan(const ASnapshot: TCrashSnapshot);
var
  LIndex: Integer;
  LStack: Cardinal;
  LAddress: Cardinal;
begin
  WriteText(#13#10'Stack scan (code addresses - ImageBase):'#13#10);
  LStack := ASnapshot.Esp;
  for LIndex := 0 to CRASH_STACK_DWORDS - 1 do
  begin
    if not FMemory.IsReadable(LStack, 4) then
      Break;
    LAddress := FMemory.ReadDWord(LStack);
    if (LAddress >= ASnapshot.ImageBase + $1000) and
       (LAddress < ASnapshot.ImageBase + ASnapshot.ImageSize) then
      WriteLine('  ', LAddress - ASnapshot.ImageBase);
    Inc(LStack, 4);
  end;
end;

procedure TCrashReportWriter.Write(const ASnapshot: TCrashSnapshot);
begin
  WriteText('DelphiDoom crash report'#13#10);
  WriteLine('ExceptionCode   ', ASnapshot.ExceptionCode);
  WriteLine('ExceptionAddr   ', ASnapshot.ExceptionAddress);
  WriteLine('ImageBase       ', ASnapshot.ImageBase);
  WriteLine('ImageSize       ', ASnapshot.ImageSize);
  WriteLine('ThreadId        ', ASnapshot.ThreadId);
  if (ASnapshot.ExceptionAddress >= ASnapshot.ImageBase) and
     (ASnapshot.ExceptionAddress < ASnapshot.ImageBase + ASnapshot.ImageSize) then
    WriteLine('Addr-ImageBase  ', ASnapshot.ExceptionAddress - ASnapshot.ImageBase)
  else
    WriteText('Addr is outside the executable image'#13#10);
  if (ASnapshot.ExceptionCode = CRASH_EXCEPTION_ACCESS_VIOLATION) and
     (ASnapshot.ParameterCount >= 2) then
  begin
    WriteLine('AV operation    ', ASnapshot.Parameter0);
    WriteLine('AV address      ', ASnapshot.Parameter1);
  end;

  WriteLine('EIP ', ASnapshot.Eip);
  WriteLine('ESP ', ASnapshot.Esp);
  WriteLine('EBP ', ASnapshot.Ebp);
  WriteLine('EAX ', ASnapshot.Eax);
  WriteLine('EBX ', ASnapshot.Ebx);
  WriteLine('ECX ', ASnapshot.Ecx);
  WriteLine('EDX ', ASnapshot.Edx);
  WriteLine('ESI ', ASnapshot.Esi);
  WriteLine('EDI ', ASnapshot.Edi);

  WriteFrames(ASnapshot);
  WriteStackScan(ASnapshot);
end;

end.
