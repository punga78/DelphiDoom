{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the engine system library - the old crash filter       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.EngineSystem.LegacyCrash;

// CrashFilter of i_crashlog.pas as it was at cb5a45e3 (git show cb5a45e3:Base\i_crashlog.pas). The body is
// the old one; what changed is the file name (a parameter instead of crash.txt next to the executable)
// and the types of the exception, which are the ones of Winapi.Windows. A 32 bit unit: on Win64 it is empty.

{$Q-}
{$R-}

interface

{$IFDEF CPUX86}
uses
  Winapi.Windows;

type
  PLegacyExceptionInfo = ^TExceptionPointers;

procedure LegacyCrashFilter(ep: PLegacyExceptionInfo; const filename: AnsiString);
{$ENDIF}

implementation

{$IFDEF CPUX86}
const
  CL_EXCEPTION_ACCESS_VIOLATION = $C0000005;

var
  crashfile: THandle = INVALID_HANDLE_VALUE;

procedure CL_Write(const s: PAnsiChar);
var
  written: DWORD;
begin
  WriteFile(crashfile, s^, lstrlenA(s), written, nil);
end;

procedure CL_Hex(const v: Cardinal);
const
  digits: array[0..15] of AnsiChar = '0123456789ABCDEF';
var
  buf: array[0..9] of AnsiChar;
  i: integer;
begin
  for i := 0 to 7 do
    buf[i] := digits[(v shr ((7 - i) * 4)) and $F];
  buf[8] := ' ';
  buf[9] := #0;
  CL_Write(buf);
end;

procedure CL_Line(const name: PAnsiChar; const v: Cardinal);
begin
  CL_Write(name);
  CL_Hex(v);
  CL_Write(#13#10);
end;

procedure LegacyCrashFilter(ep: PLegacyExceptionInfo; const filename: AnsiString);
var
  i: integer;
  imgbase, imgsize: Cardinal;
  ctx: PContext;
  sp: PCardinal;
  fp: PCardinal;
  v: Cardinal;
  nt: PImageNtHeaders;
begin
  crashfile := CreateFileA(PAnsiChar(filename), GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if crashfile = INVALID_HANDLE_VALUE then
    Exit;

  imgbase := Cardinal(GetModuleHandle(nil));
  nt := PImageNtHeaders(imgbase + Cardinal(PImageDosHeader(imgbase)._lfanew));
  imgsize := nt.OptionalHeader.SizeOfImage;
  ctx := ep.ContextRecord;

  CL_Write('DelphiDoom crash report'#13#10);
  CL_Line('ExceptionCode   ', ep.ExceptionRecord.ExceptionCode);
  CL_Line('ExceptionAddr   ', Cardinal(ep.ExceptionRecord.ExceptionAddress));
  CL_Line('ImageBase       ', imgbase);
  CL_Line('ImageSize       ', imgsize);
  CL_Line('ThreadId        ', GetCurrentThreadId);
  v := Cardinal(ep.ExceptionRecord.ExceptionAddress);
  if (v >= imgbase) and (v < imgbase + imgsize) then
    CL_Line('Addr-ImageBase  ', v - imgbase)
  else
    CL_Write('Addr is outside the executable image'#13#10);
  if (ep.ExceptionRecord.ExceptionCode = CL_EXCEPTION_ACCESS_VIOLATION) and
     (ep.ExceptionRecord.NumberParameters >= 2) then
  begin
    CL_Line('AV operation    ', ep.ExceptionRecord.ExceptionInformation[0]);
    CL_Line('AV address      ', ep.ExceptionRecord.ExceptionInformation[1]);
  end;

  CL_Line('EIP ', ctx.Eip);
  CL_Line('ESP ', ctx.Esp);
  CL_Line('EBP ', ctx.Ebp);
  CL_Line('EAX ', ctx.Eax);
  CL_Line('EBX ', ctx.Ebx);
  CL_Line('ECX ', ctx.Ecx);
  CL_Line('EDX ', ctx.Edx);
  CL_Line('ESI ', ctx.Esi);
  CL_Line('EDI ', ctx.Edi);

  // Walk the EBP chain: return addresses as offsets from the image base
  CL_Write(#13#10'EBP chain (return address - ImageBase):'#13#10);
  fp := PCardinal(ctx.Ebp);
  for i := 0 to 31 do
  begin
    if (fp = nil) or IsBadReadPtr(fp, 8) then
      Break;
    v := PCardinal(Cardinal(fp) + 4)^;
    if (v >= imgbase) and (v < imgbase + imgsize) then
      CL_Line('  ', v - imgbase)
    else
      CL_Line('  (outside) ', v);
    if PCardinal(fp)^ <= Cardinal(fp) then
      Break;
    fp := PCardinal(fp^);
  end;

  // Stack scan: any dword that looks like a code address inside the image
  CL_Write(#13#10'Stack scan (code addresses - ImageBase):'#13#10);
  sp := PCardinal(ctx.Esp);
  for i := 0 to 511 do
  begin
    if IsBadReadPtr(sp, 4) then
      Break;
    v := sp^;
    if (v >= imgbase + $1000) and (v < imgbase + imgsize) then
      CL_Line('  ', v - imgbase);
    Inc(sp);
  end;

  CloseHandle(crashfile);
end;
{$ENDIF}

end.
