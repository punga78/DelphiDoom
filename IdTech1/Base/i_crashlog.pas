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

// The facade of the crash logger (issue #185): the filter, the report and the file are
// TWindowsCrashLogger and TCrashReportWriter of IdTech1\EngineSystem.

interface

//==============================================================================
//
// I_InstallCrashLogger
//
//==============================================================================
procedure I_InstallCrashLogger;

//==============================================================================
//
// I_ReportMainException
// For the "except" of the main loop of a program (the try ... except around DoomMain): writes
// crash.txt with the class, the message and the address of the exception that is being handled
// (the unhandled exception filter never sees it) and sets the exit code to 1. At 32 and at 64 bit
//
//==============================================================================
procedure I_ReportMainException;

implementation

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  DelphiDoom.EngineSystem.WindowsCrashLogger,
  DelphiDoom.EngineSystem.MainExceptionReport;

//==============================================================================
//
// I_InstallCrashLogger
//
//==============================================================================
procedure I_InstallCrashLogger;
begin
  TWindowsCrashLogger.Install;
end;

//==============================================================================
//
// I_ReportMainException
//
//==============================================================================
procedure I_ReportMainException;
var
  LObject: TObject;
  LClass, LMessage, LPath: string;
  LText: TBytes;
  LStream: TFileStream;
begin
  LObject := ExceptObject;
  LClass := '';
  LMessage := '';
  if LObject is Exception then
  begin
    LClass := LObject.ClassName;
    LMessage := Exception(LObject).Message;
  end
  else if LObject <> nil then
    LClass := LObject.ClassName;
  LText := TEncoding.ANSI.GetBytes(TMainExceptionReport.Build(LClass, LMessage, NativeUInt(ExceptAddr),
    NativeUInt(HInstance)));
  LPath := ExtractFilePath(ParamStr(0)) + 'crash.txt';
  try
    LStream := TFileStream.Create(LPath, fmCreate);
    try
      LStream.WriteBuffer(LText[0], Length(LText));
    finally
      LStream.Free;
    end;
  except
    on EFCreateError do
      // the folder of the program cannot be written: the exit code still tells
      ;
  end;
  ExitCode := TMainExceptionReport.ExitCode;
end;

end.
