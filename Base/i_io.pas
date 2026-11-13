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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit i_io;

interface

uses
  d_delphi,
  DelphiDoom.EngineSystem.StdoutBuffer;

var
  debugfile: TFile;
  stderr: TFile;
  stdout: TFile;
  // what the engine printed, as lines (TStdoutBuffer of Libs\EngineSystem)
  stdoutbuffer: TStdoutBuffer;

//==============================================================================
//
// I_InitializeIO
//
//==============================================================================
procedure I_InitializeIO;

//==============================================================================
//
// I_ShutDownIO
//
//==============================================================================
procedure I_ShutDownIO;

//==============================================================================
//
// I_IOMessageBox
//
//==============================================================================
procedure I_IOMessageBox(const s: string);

//==============================================================================
//
// I_IOErrorMessageBox
//
//==============================================================================
procedure I_IOErrorMessageBox(const s: string);

//==============================================================================
//
// I_IOprintf
//
//==============================================================================
procedure I_IOprintf(const s: string);

//==============================================================================
//
// I_IOSetWindowHandle
//
//==============================================================================
procedure I_IOSetWindowHandle(const handle: integer);

implementation

uses
  Windows,
  d_main,
  g_game,
  i_mainwindow,
{$IFNDEF FPC}
  i_startup,
{$ENDIF}
  m_argv,
  DelphiDoom.EngineSystem.Types,
  DelphiDoom.EngineSystem.LogFileNames;

var
  msghandle: integer = 0;

//==============================================================================
//
// I_IOMessageBox
//
//==============================================================================
procedure I_IOMessageBox(const s: string);
begin
  MessageBox(msghandle, PChar(s), AppTitle, MB_OK);
end;

//==============================================================================
//
// I_IOErrorMessageBox
//
//==============================================================================
procedure I_IOErrorMessageBox(const s: string);
begin
  MessageBox(msghandle, PChar(s), AppTitle, MB_OK or MB_ICONERROR or MB_APPLMODAL);
end;

//==============================================================================
//
// I_IOprintf
//
//==============================================================================
procedure I_IOprintf(const s: string);
begin
  if Length(s) = 0 then
    exit;

  stdoutbuffer.Append(s);

  if IsConsole then
    write(s);
end;

const
{$IFDEF DOOM}
  basename = 'Doom';
{$ENDIF}
{$IFDEF HERETIC}
  basename = 'Heretic';
{$ENDIF}
{$IFDEF HEXEN}
  basename = 'Hexen';
{$ENDIF}
{$IFDEF STRIFE}
  basename = 'Strife';
{$ENDIF}

//==============================================================================
//
// I_InitializeIO
//
//==============================================================================
procedure I_InitializeIO;
var
  names: TLogFileSet;
  cdfolder: string;
begin
  cdfolder := '';
  if M_CheckParmCDROM then
    cdfolder := CD_WORKDIR;
  names := TLogFileNames.Build(basename,
{$IFDEF OPENGL}
    true,
{$ELSE}
    false,
{$ENDIF}
    M_CheckParm('-debugfile') <> 0, consoleplayer, cdfolder);

  MkDir(M_SaveFileName('DATA'));
  MkDir(M_SaveFileName('DATA\LOGS'));

  printf(' error output to: %s'#13#10, [names.ErrorFile]);
  stderr := TFile.Create(names.ErrorFile, fCreate);
  printf(' debug output to: %s'#13#10, [names.DebugFile]);
  debugfile := TFile.Create(names.DebugFile, fCreate);
  printf(' standard output to: %s'#13#10, [names.StdoutFile]);
  stdout := TFile.Create(names.StdoutFile, fCreate);
end;

//==============================================================================
//
// I_ShutDownIO
//
//==============================================================================
procedure I_ShutDownIO;
begin
  stderr.Free;
  debugfile.Free;
  stdout.Free;
  {$IFNDEF FPC}
  SUC_Close;
  {$ENDIF}
end;

//==============================================================================
//
// I_IOSetWindowHandle
//
//==============================================================================
procedure I_IOSetWindowHandle(const handle: integer);
begin
  if handle > 0 then
    msghandle := handle
  else
    msghandle := hMainWnd
end;

initialization

  stdoutbuffer := TStdoutBuffer.Create;

finalization

  stdoutbuffer.Free;

end.
