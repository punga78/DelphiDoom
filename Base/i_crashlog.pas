//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Unhandled exception filter: writes crash.txt (exception, registers, a
//  stack walk and a stack dump, all as offsets from the image base) next to
//  the executable. Offsets can be resolved with the linker map file.
//  It uses only Windows API calls, so it works even if the heap is corrupted.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit i_crashlog;

interface

//==============================================================================
//
// I_InstallCrashLogger
//
//==============================================================================
procedure I_InstallCrashLogger;

implementation

uses
  Windows;

type
  PExcRec = ^TExcRec;
  TExcRec = record
    ExceptionCode: DWORD;
    ExceptionFlags: DWORD;
    ExceptionRecord: PExcRec;
    ExceptionAddress: Pointer;
    NumberParameters: DWORD;
    ExceptionInformation: array[0..14] of DWORD;
  end;

  PExcPointers = ^TExcPointers;
  TExcPointers = record
    ExceptionRecord: PExcRec;
    ContextRecord: PContext;
  end;

const
  CL_EXCEPTION_ACCESS_VIOLATION = $C0000005;
  CL_EXCEPTION_EXECUTE_HANDLER = 1;

function CL_SetUEF(lpFilter: Pointer): Pointer; stdcall; external 'kernel32.dll' name 'SetUnhandledExceptionFilter';

var
  crashing: LongInt = 0;
  crashfile: THandle = INVALID_HANDLE_VALUE;
  crashpath: array[0..MAX_PATH] of AnsiChar;

//==============================================================================
//
// CL_Write
//
//==============================================================================
procedure CL_Write(const s: PAnsiChar);
var
  written: DWORD;
begin
  WriteFile(crashfile, s^, lstrlenA(s), written, nil);
end;

//==============================================================================
//
// CL_Hex
//
//==============================================================================
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

//==============================================================================
//
// CL_Line
//
//==============================================================================
procedure CL_Line(const name: PAnsiChar; const v: Cardinal);
begin
  CL_Write(name);
  CL_Hex(v);
  CL_Write(#13#10);
end;

//==============================================================================
//
// CrashFilter
//
//==============================================================================
function CrashFilter(ep: PExcPointers): LongInt; stdcall;
var
  i: integer;
  imgbase, imgsize: Cardinal;
  ctx: PContext;
  sp: PCardinal;
  fp: PCardinal;
  v: Cardinal;
  p: PAnsiChar;
  lastslash: PAnsiChar;
  nt: PImageNtHeaders;
begin
  Result := CL_EXCEPTION_EXECUTE_HANDLER;
  if InterlockedExchange(crashing, 1) <> 0 then
    Exit;

  GetModuleFileNameA(0, crashpath, MAX_PATH);
  lastslash := nil;
  p := crashpath;
  while p^ <> #0 do
  begin
    if p^ = '\' then
      lastslash := p;
    Inc(p);
  end;
  if lastslash <> nil then
  begin
    Inc(lastslash);
    lstrcpyA(lastslash, 'crash.txt');
  end;

  crashfile := CreateFileA(crashpath, GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
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

//==============================================================================
//
// I_InstallCrashLogger
//
//==============================================================================
procedure I_InstallCrashLogger;
begin
  CL_SetUEF(@CrashFilter);
end;

end.
