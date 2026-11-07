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

unit m_crc32;

// What is left of the facade of the CRC-32 (issue #133): the engine computes the
// checksums with TCrc32 of Libs\MathCore (W_LumpCRC32 for a lump, TCrc32.CalculateStream
// for a file). GetLumpCRC32 stays only for p_udmf, which another piece of work of the
// same wave changes: when p_udmf calls W_LumpCRC32 this unit can be deleted.

interface

//==============================================================================
//
// GetLumpCRC32
// The same as W_LumpCRC32 of w_wad
//
//==============================================================================
function GetLumpCRC32(const LumpNum: integer): string;

implementation

uses
  w_wad;

//==============================================================================
//
// GetLumpCRC32
//
//==============================================================================
function GetLumpCRC32(const LumpNum: integer): string;
begin
  result := W_LumpCRC32(LumpNum);
end;

end.
