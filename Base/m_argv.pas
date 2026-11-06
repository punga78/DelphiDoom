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
// Gives the unit what it builds the command line with. The composition root calls it
// before M_InitArgv
//
//==============================================================================
procedure M_ConfigureArgv(const ABuilder: ICommandLineBuilder);

//==============================================================================
//
// M_CmdShowCommandLineParams
//
//==============================================================================
procedure M_CmdShowCommandLineParams(const parm: string);

//==============================================================================
//
// M_CmdShowCmdline
//
//==============================================================================
procedure M_CmdShowCmdline(const parm: string);

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
  c_cmds,
  m_base,
  i_system,
  DelphiDoom.CommandLine.DefaultFile;

var
  cdchecked: integer = -1;

var
  cmdparams: TDStringList;
  // given by the composition root (M_ConfigureArgv)
  argv_builder: ICommandLineBuilder = nil;
  // what M_InitArgv built: myargv/myargc are a copy of it for the code that reads them
  commandline: ICommandLine = nil;

//==============================================================================
//
// M_CheckParm
//
//==============================================================================
function M_CheckParm(const check: string): integer;
begin
  if cmdparams.IndexOf(check) < 0 then
    cmdparams.Add(check);

  if commandline <> nil then
    result := commandline.IndexOf(check)
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
  if cdchecked = -1 then
  begin
    if I_IsCDRomDrive then
      cdchecked := 1
    else
      cdchecked := M_CheckParm('-cdrom');
    if cdchecked > 0 then
      MakeDir(CD_WORKDIR);
  end;
  result := cdchecked > 0;
end;

//==============================================================================
//
// M_ConfigureArgv
//
//==============================================================================
procedure M_ConfigureArgv(const ABuilder: ICommandLineBuilder);
begin
  argv_builder := ABuilder;
end;

//==============================================================================
//
// M_InitArgv
//
//==============================================================================
procedure M_InitArgv;
var
  i: integer;
  defargv: string;
  cmdln: string;
  programname: string;
  argument: string;

  procedure LoadFromDefaultCMD(trywrite: boolean);
  var
    str: TDStringList;
  begin
    str := TDStringList.Create;
    try
      if fexists(defargv) then
      begin
        str.LoadFromFile(defargv);
        argv_builder.AddDefaultFile(str.Text);
      end
      else if trywrite then
      begin
        str.Text := TDefaultArgumentsFile.Template(APPNAME, fname(programname));
        if (str.Count > 0) and (str[str.Count - 1] = '') then
          str.Delete(str.Count - 1);
        str.SaveToFile(defargv);
      end;
    finally
      str.Free;
    end;
  end;

begin
  if argv_builder = nil then
    I_Error('M_InitArgv(): the command line was not configured (M_ConfigureArgv)');

  for i := 0 to ParamCount do
  begin
    argument := strupper(ParamStr(i));
    if argument <> '' then
      if argument[1] <> '-' then
        if fexists(argument) then
          argument := fexpand(argument);
    if i = 0 then
      programname := argument;
    argv_builder.Add(argument);
  end;

  defargv := DEFARGVFILENAME;
  LoadFromDefaultCMD(not I_IsCDRomDrive);

  if I_IsCDRomDrive then
  begin
    defargv := M_SaveFileName(DEFARGVFILENAME);
    LoadFromDefaultCMD(not I_IsCDRomDrive(defargv[1]));
  end;

  commandline := argv_builder.Build;

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
// M_CmdShowCommandLineParams
//
//==============================================================================
procedure M_CmdShowCommandLineParams(const parm: string);
var
  i: integer;
  mlist: TDStringList;
  mask: string;
begin
  if parm = '' then
    mask := '*'
  else
    mask := parm;
  mlist := C_GetMachingList(cmdparams, mask);
  printf('Command line parameters: '#13#10);
  for i := 0 to mlist.Count - 1 do
    printf(' %s'#13#10, [mlist[i]]);
  mlist.Free;
end;

//==============================================================================
//
// M_CmdShowCmdline
//
//==============================================================================
procedure M_CmdShowCmdline(const parm: string);
var
  i: integer;
begin
  for i := 1 to myargc - 1 do
    printf('%s ', [myargv[i]]);
  printf(#13#10);
end;

//==============================================================================
//
// M_SaveFileName
//
//==============================================================================
function M_SaveFileName(const filename: string): string;
begin
  if M_CheckParmCDROM then
    result := CD_WORKDIR + filename
  else
    result := filename;
end;

initialization
  cmdparams := TDStringList.Create;

finalization
{$IFDEF DEBUG}
  cmdparams.SaveToFile('cmdparams.txt');
{$ENDIF}
  cmdparams.Free;

end.

