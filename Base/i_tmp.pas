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
//  Temporary files managment.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit i_tmp;

// What is left of the facade of the temporary files (issue #133). The classes of the
// engine receive the ITempFiles of Libs\Platform from ComposeEngine (the backends of the
// MIDI and XMI songs, nd_main with ND_Configure). These functions stay for the
// procedural code that has no object to give it to: the savegames (the PascalScript
// state of the map goes through a file), ps_dll (a DLL in a PAK is copied to a file
// before LoadLibrary), s_pk3sounds, and vx_voxelsprite and v_palettes (other pieces of
// work of the same wave); i_system deletes the files at the shut down.

interface

uses
  DelphiDoom.Platform.Intf;

//==============================================================================
//
// I_ConfigureTempFiles
// Gives the unit the temporary files it uses. The composition root calls it
//
//==============================================================================
procedure I_ConfigureTempFiles(const ATempFiles: ITempFiles);

//==============================================================================
//
// I_ShutDownTempFiles
//
//==============================================================================
procedure I_ShutDownTempFiles;

//==============================================================================
//
// I_NewTempFile
//
//==============================================================================
function I_NewTempFile(const name: string): string;

//==============================================================================
//
// I_DeclareTempFile
//
//==============================================================================
procedure I_DeclareTempFile(const name: string);

implementation

uses
  i_system;

var
  // given by the composition root (I_ConfigureTempFiles)
  engine_tempfiles: ITempFiles = nil;

//==============================================================================
//
// I_ConfigureTempFiles
//
//==============================================================================
procedure I_ConfigureTempFiles(const ATempFiles: ITempFiles);
begin
  engine_tempfiles := ATempFiles;
end;

//==============================================================================
//
// I_ShutDownTempFiles
//
//==============================================================================
procedure I_ShutDownTempFiles;
begin
  if Assigned(engine_tempfiles) then
    engine_tempfiles.DeleteAll;
end;

//==============================================================================
//
// I_NewTempFile
//
//==============================================================================
function I_NewTempFile(const name: string): string;
begin
  if not Assigned(engine_tempfiles) then
    I_Error('I_NewTempFile(): the temporary files were not configured');
  result := engine_tempfiles.NewTempFile(name);
end;

//==============================================================================
//
// I_DeclareTempFile
//
//==============================================================================
procedure I_DeclareTempFile(const name: string);
begin
  if not Assigned(engine_tempfiles) then
    I_Error('I_DeclareTempFile(): the temporary files were not configured');
  engine_tempfiles.Declare(name);
end;

end.
