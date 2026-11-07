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
//  Autoload pak files from AUTOLOAD entries inside wads
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit w_autoload;

interface

uses
  DelphiDoom.Scanner.AutoLoad.Intf;

//==============================================================================
//
// W_ConfigureAutoLoad
//
// The reader of the AUTOLOAD lumps is given by the composition root (ComposeEngine);
// without it W_AutoLoadPakFiles stops with I_Error.
//
//==============================================================================
procedure W_ConfigureAutoLoad(const AReader: IAutoLoadReader);

//==============================================================================
//
// W_AutoLoadPakFiles
//
//==============================================================================
procedure W_AutoLoadPakFiles;

implementation

uses
  i_system;

var
  // given by the composition root (W_ConfigureAutoLoad)
  engine_autoload: IAutoLoadReader = nil;

//==============================================================================
//
// W_ConfigureAutoLoad
//
//==============================================================================
procedure W_ConfigureAutoLoad(const AReader: IAutoLoadReader);
begin
  engine_autoload := AReader;
end;

//==============================================================================
//
// W_AutoLoadPakFiles
//
//==============================================================================
procedure W_AutoLoadPakFiles;
begin
  if engine_autoload = nil then
    I_Error('W_ConfigureAutoLoad() was not called: the AUTOLOAD lumps cannot be read');
  engine_autoload.Load;
end;

end.
