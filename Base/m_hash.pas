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
//  General purpose global hash
//  (sdbm hash implementation)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit m_hash;

interface

uses
  DelphiDoom.MathCore.Intf;

//==============================================================================
//
// M_ConfigureHash
// The hash table of Libs\MathCore, given by the composition root
//
//==============================================================================
procedure M_ConfigureHash(const ATable: IStringHashTable);

//==============================================================================
//
// M_HashIndex
//
//==============================================================================
function M_HashIndex(const s: string): integer;

//==============================================================================
//
// M_HashUpdate
//
//==============================================================================
procedure M_HashUpdate(const s: string; const idx: integer);

implementation

var
  globalhashmanager: IStringHashTable;

//==============================================================================
//
// M_ConfigureHash
//
//==============================================================================
procedure M_ConfigureHash(const ATable: IStringHashTable);
begin
  globalhashmanager := ATable;
end;

//==============================================================================
//
// M_HashIndex
//
//==============================================================================
function M_HashIndex(const s: string): integer;
begin
  result := globalhashmanager.IndexOf(s);
end;

//==============================================================================
//
// M_HashUpdate
//
//==============================================================================
procedure M_HashUpdate(const s: string; const idx: integer);
begin
  globalhashmanager.Update(s, idx);
end;

end.
