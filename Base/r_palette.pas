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
//  Refresh module, data I/O, caching, retrieval of graphics
//  by name.
//  Preparation of data for rendering,
//  generation of lookups, caching, retrieval by name.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_palette;

interface

uses
  d_delphi,
  DelphiDoom.Palette.Intf;

type
  palette_t = array[0..255] of LongWord;
  palette_p = ^palette_t;

//==============================================================================
//
// R_DefaultPalette
//
//==============================================================================
function R_DefaultPalette: palette_p;

//==============================================================================
//
// R_ConfigurePalette
//
//==============================================================================
procedure R_ConfigurePalette(const AUnpacker: IPaletteUnpacker);

implementation

uses
  i_system,
  v_data,
  z_zone;

var
  dpal: palette_t;
  flag: boolean = false;
  pal_unpacker: IPaletteUnpacker;

//==============================================================================
//
// R_ConfigurePalette
//
//==============================================================================
procedure R_ConfigurePalette(const AUnpacker: IPaletteUnpacker);
begin
  pal_unpacker := AUnpacker;
end;

//==============================================================================
//
// R_DefaultPalette
//
//==============================================================================
function R_DefaultPalette: palette_p;
var
  palette: PByteArray;
  source: TArray<Byte>;
  colors: TArray<Cardinal>;
begin
  if flag then
  begin
    result := @dpal;
    exit;
  end;

  if pal_unpacker = nil then
    I_Error('R_DefaultPalette(): the palette is not configured (ComposeEngine was not called)');

  palette := V_ReadPalette(PU_STATIC);
  SetLength(source, 256 * 3);
  Move(palette^, source[0], 256 * 3);
  Z_ChangeTag(palette, PU_CACHE);

  colors := pal_unpacker.Unpack(source);
  Move(colors[0], dpal[0], SizeOf(palette_t));

  flag := True;
  result := @dpal;
end;

end.
