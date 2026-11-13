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
// TWindowsCrashLogger and TCrashReportWriter of Libs\EngineSystem.

interface

//==============================================================================
//
// I_InstallCrashLogger
//
//==============================================================================
procedure I_InstallCrashLogger;

implementation

uses
  DelphiDoom.EngineSystem.WindowsCrashLogger;

//==============================================================================
//
// I_InstallCrashLogger
//
//==============================================================================
procedure I_InstallCrashLogger;
begin
  TWindowsCrashLogger.Install;
end;

end.
