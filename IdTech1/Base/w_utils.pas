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

unit w_utils;

interface

uses
  DelphiDoom.Console.Intf;

//==============================================================================
//
// W_RegisterUtilityCommands
//
//==============================================================================
procedure W_RegisterUtilityCommands;

//==============================================================================
//
// W_ConfigureLumpCommands
// The group of the commands lumpsize, lumpnum, numlumps and savelumptodisk
// (composition root)
//
//==============================================================================
procedure W_ConfigureLumpCommands(const AGroup: IConsoleCommandGroup);

implementation

uses
  i_system;

var
  // given by the composition root
  lump_commands: IConsoleCommandGroup = nil;

//==============================================================================
//
// W_ConfigureLumpCommands
//
//==============================================================================
procedure W_ConfigureLumpCommands(const AGroup: IConsoleCommandGroup);
begin
  lump_commands := AGroup;
end;

//==============================================================================
//
// W_RegisterUtilityCommands
//
//==============================================================================
procedure W_RegisterUtilityCommands;
begin
  if lump_commands = nil then
    I_Error('W_RegisterUtilityCommands(): The lump commands are not configured (ComposeEngine was not called)');
  lump_commands.Register;
end;

end.
