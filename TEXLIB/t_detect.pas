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

{
  Tells which kind of image a lump or a file of a PAK is (patch, flat, PCX): the old
  T_IsValid* functions of t_patch, t_flat and t_pcx, now sitting on the classes of
  Libs\Texture.
}

unit t_detect;

interface

uses
  r_defs;

//==============================================================================
//
// T_IsValidPatchImage
//
//==============================================================================
function T_IsValidPatchImage(var f: file; const start, size: integer): boolean; overload;

//==============================================================================
//
// T_IsValidPatchImage
//
//==============================================================================
function T_IsValidPatchImage(patch: Ppatch_t; const size: integer): boolean; overload;

//==============================================================================
//
// T_IsValidFlatImage
//
//==============================================================================
function T_IsValidFlatImage(var f: file; const start, size: integer): boolean;

//==============================================================================
//
// T_IsValidPCXHeader
//
//==============================================================================
function T_IsValidPCXHeader(const p: Pointer): boolean;

implementation

uses
  System.SysUtils,
  DelphiDoom.Texture.PatchInspector,
  DelphiDoom.Texture.Decoder.Flat,
  DelphiDoom.Texture.Decoder.Pcx;

//==============================================================================
//
// T_IsValidPatchImage
//
//==============================================================================
function T_IsValidPatchImage(var f: file; const start, size: integer): boolean;
var
  N, pos: integer;
  lump: TBytes;
begin
  pos := FilePos(f);
  seek(f, start);

  SetLength(lump, size);
  N := 0;
  if size > 0 then
    BlockRead(f, lump[0], size, N);

  if N <> size then
    result := false
  else
    result := TTexturePatchInspector.IsValid(lump, N);

  seek(f, pos);
end;

//==============================================================================
//
// T_IsValidPatchImage
//
//==============================================================================
function T_IsValidPatchImage(patch: Ppatch_t; const size: integer): boolean;
var
  lump: TBytes;
begin
  if size <= 0 then
  begin
    result := false;
    exit;
  end;
  SetLength(lump, size);
  Move(patch^, lump[0], size);
  result := TTexturePatchInspector.IsValid(lump, size);
end;

//==============================================================================
//
// T_IsValidFlatImage
//
//==============================================================================
function T_IsValidFlatImage(var f: file; const start, size: integer): boolean;
begin
  result := TTextureFlatDecoder.IsFlatLength(size);
end;

//==============================================================================
//
// T_IsValidPCXHeader
//
//==============================================================================
function T_IsValidPCXHeader(const p: Pointer): boolean;
var
  header: TBytes;
begin
  SetLength(header, 128);
  Move(p^, header[0], 128);
  result := TTexturePcxDecoder.IsValidHeader(header);
end;

end.
