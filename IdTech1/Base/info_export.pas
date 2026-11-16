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

unit info_export;

interface

uses
  DelphiDoom.TableExport.Intf,
  DelphiDoom.TableExport.Saver.Intf;

//==============================================================================
//
// Info_ConfigureExport
//
// The writer of the Pascal tables and what saves it to a file: ComposeEngine gives them
//
//==============================================================================
procedure Info_ConfigureExport(const AWriter: IExportPascalWriter; const ASaver: ITableExportSaver);

//==============================================================================
//
// Info_GetMobjinfoPascal
//
//==============================================================================
function Info_GetMobjinfoPascal(const astart: integer = 0; const afinish: integer = -1): string;

//==============================================================================
//
// Info_GetMobjinfoPascalConst
//
//==============================================================================
function Info_GetMobjinfoPascalConst(const astart: integer = 0; const afinish: integer = -1): string;

//==============================================================================
//
// Info_GetStatesPascal
//
//==============================================================================
function Info_GetStatesPascal(const astart: integer = 0; const afinish: integer = -1): string;

//==============================================================================
//
// Info_InitExportCommands
//
//==============================================================================
procedure Info_InitExportCommands;

implementation

uses
  d_delphi,
  c_cmds,
  i_system,
  info_h,
  m_argv;

var
  pascal_writer: IExportPascalWriter;
  pascal_saver: ITableExportSaver;

//==============================================================================
//
// Info_ConfigureExport
//
//==============================================================================
procedure Info_ConfigureExport(const AWriter: IExportPascalWriter; const ASaver: ITableExportSaver);
begin
  pascal_writer := AWriter;
  pascal_saver := ASaver;
end;

//==============================================================================
//
// Info_PascalWriter
//
//==============================================================================
function Info_PascalWriter: IExportPascalWriter;
begin
  if not Assigned(pascal_writer) then
    I_Error('Info_PascalWriter(): the export is not configured (ComposeEngine was not called)');
  result := pascal_writer;
end;

//==============================================================================
//
// Info_GetMobjinfoPascal
//
//==============================================================================
function Info_GetMobjinfoPascal(const astart: integer = 0; const afinish: integer = -1): string;
begin
  result := Info_PascalWriter.Things(astart, afinish);
end;

//==============================================================================
//
// Info_GetMobjinfoPascalConst
//
//==============================================================================
function Info_GetMobjinfoPascalConst(const astart: integer = 0; const afinish: integer = -1): string;
begin
  result := Info_PascalWriter.ThingConstants(astart, afinish);
end;

//==============================================================================
//
// Info_GetStatesPascal
//
//==============================================================================
function Info_GetStatesPascal(const astart: integer = 0; const afinish: integer = -1): string;
begin
  result := Info_PascalWriter.States(astart, afinish);
end;

//==============================================================================
//
// Info_SavePascal
//
//==============================================================================
procedure Info_SavePascal(const fname: string; const s: string);
begin
  if not Assigned(pascal_saver) then
    I_Error('Info_SavePascal(): the export is not configured (ComposeEngine was not called)');
  pascal_saver.SaveText(fname, '.txt', 'Please specify the filename to save info export'#13#10,
    'Info settings saved to %s'#13#10,
    function: string
    begin
      Result := s;
    end);
end;

//==============================================================================
//
// CmdExportInfoPascal
//
//==============================================================================
procedure CmdExportInfoPascal(const fname: string);
begin
  Info_SavePascal(fname, Info_GetMobjinfoPascal + Info_GetStatesPascal);
end;

//==============================================================================
//
// CmdExportInfoPascalBI
//
//==============================================================================
procedure CmdExportInfoPascalBI(const fname: string);
begin
  Info_SavePascal(fname,
    Info_GetMobjinfoPascal(0, Ord(DO_NUMMOBJTYPES) - 1) + Info_GetStatesPascal(0, Ord(DO_NUMSTATES) - 1));
end;

//==============================================================================
//
// CmdExportInfoPascalConst
//
//==============================================================================
procedure CmdExportInfoPascalConst(const fname: string);
begin
  Info_SavePascal(fname, Info_GetMobjinfoPascalConst);
end;

//==============================================================================
//
// CmdExportInfoPascalConstBI
//
//==============================================================================
procedure CmdExportInfoPascalConstBI(const fname: string);
begin
  Info_SavePascal(fname, Info_GetMobjinfoPascalConst(0, Ord(DO_NUMMOBJTYPES) - 1));
end;

var
  export_commands_registered: boolean = false;

//==============================================================================
//
// Info_InitExportCommands
//
//==============================================================================
procedure Info_InitExportCommands;
begin
  if export_commands_registered then
    exit;
  C_AddCmd('ExportInfoPascal, InfoExportPascal', @CmdExportInfoPascal);
  C_AddCmd('SaveInfoPascal, InfoSavePascal', @CmdExportInfoPascal);
  C_AddCmd('ExportInfoPascalBI, InfoExportPascalBI, ExportInfoPascalBuiltIn, InfoExportPascalBuiltIn', @CmdExportInfoPascalBI);
  C_AddCmd('SaveInfoPascalBI, InfoSavePascalBI, SaveInfoPascalBuiltIn, InfoSavePascalBuiltIn', @CmdExportInfoPascalBI);
  C_AddCmd('ExportInfoPascalConst, InfoExportPascalConst, SaveInfoPascalConst, InfoSavePascalConst', @CmdExportInfoPascalConst);
  C_AddCmd('ExportInfoPascalConstBI, InfoExportPascalConstBI, SaveInfoPascalConstBI, InfoSavePascalConstBI', @CmdExportInfoPascalConstBI);

  export_commands_registered := true;
end;

end.
