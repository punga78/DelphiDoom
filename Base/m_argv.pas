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
//  Command line parameters/ CD-ROM check
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit m_argv;

interface

uses
  DelphiDoom.CommandLine.Intf;

//
// MISC
//

const
  MAXARGS = 1024;

var
  myargc: integer;
  myargv: array[0..MAXARGS] of string;

{ Returns the position of the given parameter }
{ in the arg list (0 if not found). }

//==============================================================================
//
// M_CheckParm
//
//==============================================================================
function M_CheckParm(const check: string): integer;

//==============================================================================
//
// M_CheckParmCDROM
//
//==============================================================================
function M_CheckParmCDROM: boolean;

//==============================================================================
//
// M_InitArgv
//
//==============================================================================
procedure M_InitArgv;

//==============================================================================
//
// M_ConfigureArgv
// Gives the unit what builds the command line (the process and the default file), the command line that answers
// (and remembers) the questions and the names of the saved files. The composition root
// calls it before M_InitArgv; M_InitArgv attaches to ACommandLine what it builds
//
//==============================================================================
procedure M_ConfigureArgv(const AStartup: ICommandLineStartup;
  const ACommandLine: IQueriedCommandLine; const ASaveFileNames: ISaveFileNames);

//==============================================================================
//
// M_SaveFileName
//
//==============================================================================
function M_SaveFileName(const filename: string): string;

const
{$IFDEF DOOM}
  CD_WORKDIR = 'c:\doomdata\';
{$ENDIF}
{$IFDEF HERETIC}
  CD_WORKDIR = 'c:\heretic.cd\';
{$ENDIF}
{$IFDEF HEXEN}
  CD_WORKDIR = 'c:\hexen.cd\';
{$ENDIF}
{$IFDEF STRIFE}
  CD_WORKDIR = 'c:\strife.cd\';
{$ENDIF}

implementation

uses
  d_delphi,
  i_system;

var
  // given by the composition root (M_ConfigureArgv)
  argv_startup: ICommandLineStartup = nil;
  // answers the questions and remembers what was asked; M_InitArgv attaches the command line to it
  argv_queried: IQueriedCommandLine = nil;
  argv_savenames: ISaveFileNames = nil;
  // what M_InitArgv built: myargv/myargc are a copy of it for the code that reads them
  commandline: ICommandLine = nil;

//==============================================================================
//
// M_CheckParm
//
//==============================================================================
function M_CheckParm(const check: string): integer;
begin
  if argv_queried <> nil then
    result := argv_queried.IndexOf(check)
  else
    result := 0;
end;

//==============================================================================
//
// M_CheckParmCDROM
//
//==============================================================================
function M_CheckParmCDROM: boolean;
begin
  if argv_savenames = nil then
    I_Error('M_CheckParmCDROM(): the command line was not configured (M_ConfigureArgv)');
  result := argv_savenames.IsCdRomMode;
end;

//==============================================================================
//
// M_ConfigureArgv
//
//==============================================================================
procedure M_ConfigureArgv(const AStartup: ICommandLineStartup;
  const ACommandLine: IQueriedCommandLine; const ASaveFileNames: ISaveFileNames);
begin
  argv_startup := AStartup;
  argv_queried := ACommandLine;
  argv_savenames := ASaveFileNames;
end;

//==============================================================================
//
// M_InitArgv
//
//==============================================================================
procedure M_InitArgv;
var
  i: integer;
  cmdln: string;
begin
  if (argv_startup = nil) or (argv_queried = nil) then
    I_Error('M_InitArgv(): the command line was not configured (M_ConfigureArgv)');

  // the process, then the default file of the program (TCommandLineStartup)
  commandline := argv_startup.Collect;
  argv_queried.Attach(commandline);

  // myargv/myargc: the copy that the older code reads
  myargc := commandline.Count;
  for i := 0 to myargc - 1 do
    myargv[i] := commandline[i];
  for i := myargc to MAXARGS do
    myargv[i] := '';

  cmdln := fname(myargv[0]);
  for i := 1 to myargc - 1 do
    cmdln := cmdln + ' ' + myargv[i];
  printf('%s'#13#10, [cmdln]);

  ChDir(fpath(myargv[0]));
end;

//==============================================================================
//
// M_SaveFileName
//
//==============================================================================
function M_SaveFileName(const filename: string): string;
begin
  if argv_savenames = nil then
    I_Error('M_SaveFileName(): the command line was not configured (M_ConfigureArgv)');
  result := argv_savenames.ResolveName(filename);
end;

{$IFDEF DEBUG}
// the parameters that the program asked for
procedure SaveQueriedParameters;
var
  names: TArray<string>;
  list: TDStringList;
  i: integer;
begin
  if argv_queried = nil then
    exit;
  names := argv_queried.QueriedNames;
  list := TDStringList.Create;
  try
    for i := 0 to High(names) do
      list.Add(names[i]);
    list.SaveToFile('cmdparams.txt');
  finally
    list.Free;
  end;
end;

initialization

finalization
  SaveQueriedParameters;
{$ENDIF}

end.