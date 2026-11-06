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
//  Palette generator
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit v_palettes;

interface

uses
  d_delphi,
  v_video,
  DelphiDoom.Palette.Intf;

//==============================================================================
//
// V_CreateDoomPalette
//
//==============================================================================
procedure V_CreateDoomPalette(const inppal: PByteArray; const outpal: PByteArray;
  const colormap: PByteArray; const fogmap: PByteArray);

//==============================================================================
//
// V_CreateTranslation
//
// From palette frompal to palette to pal create translation table
// All arrays must be allocated in memory before calling it
//
//==============================================================================
procedure V_CreateTranslation(const frompal, topal: PByteArray; const trans: PByteArray);

//==============================================================================
//
// V_ConfigurePalettes
//
//==============================================================================
procedure V_ConfigurePalettes(const ABuilder: IPaletteBuilder; const ATranslation: ITranslationBuilder);

//==============================================================================
//
// V_FixBufferPalette
//
//==============================================================================
procedure V_FixBufferPalette(const buf: PByteArray; const x1, x2: integer);

//==============================================================================
//
// V_AutoGeneratePalettes
//
//==============================================================================
procedure V_AutoGeneratePalettes(const base: string);

implementation

uses
  DelphiDoom.Palette.Types,
  i_system,
  i_tmp,
  w_wad,
  w_wadwriter,
  z_zone;

var
  pal_builder: IPaletteBuilder;
  pal_translation: ITranslationBuilder;

//==============================================================================
//
// V_ConfigurePalettes
//
//==============================================================================
procedure V_ConfigurePalettes(const ABuilder: IPaletteBuilder; const ATranslation: ITranslationBuilder);
begin
  pal_builder := ABuilder;
  pal_translation := ATranslation;
end;

//==============================================================================
//
// V_CreateDoomPalette
//
//==============================================================================
procedure V_CreateDoomPalette(const inppal: PByteArray; const outpal: PByteArray;
  const colormap: PByteArray; const fogmap: PByteArray);
var
  base: TArray<Byte>;
  palettes: TPaletteSet;
begin
  if pal_builder = nil then
    I_Error('V_CreateDoomPalette(): the palettes are not configured (ComposeEngine was not called)');

  SetLength(base, PALETTE_BYTE_COUNT);
  Move(inppal^, base[0], PALETTE_BYTE_COUNT);
  palettes := pal_builder.Build(base, colormap <> nil, fogmap <> nil);

  // a palette of 6 bits is multiplied by 4: the caller has always seen it in its own buffer
  Move(palettes.BasePalette[0], inppal^, PALETTE_BYTE_COUNT);
  Move(palettes.Playpal[0], outpal^, Length(palettes.Playpal));
  if colormap <> nil then
    Move(palettes.Colormap[0], colormap^, Length(palettes.Colormap));
  if fogmap <> nil then
    Move(palettes.Fogmap[0], fogmap^, Length(palettes.Fogmap));
end;

//==============================================================================
// V_CreateTranslation
//
// From palette frompal to palette topal create translation table
// All arrays must be allocated in memory before calling it
//
//==============================================================================
procedure V_CreateTranslation(const frompal, topal: PByteArray; const trans: PByteArray);
var
  fromb, tob, table: TArray<Byte>;
begin
  if pal_translation = nil then
    I_Error('V_CreateTranslation(): the palettes are not configured (ComposeEngine was not called)');

  SetLength(fromb, PALETTE_BYTE_COUNT);
  SetLength(tob, PALETTE_BYTE_COUNT);
  Move(frompal^, fromb[0], PALETTE_BYTE_COUNT);
  Move(topal^, tob[0], PALETTE_BYTE_COUNT);
  table := pal_translation.Build(fromb, tob);
  Move(table[0], trans^, Length(table));
end;

//==============================================================================
//
// V_FixBufferPalette
//
//==============================================================================
procedure V_FixBufferPalette(const buf: PByteArray; const x1, x2: integer);
var
  i: integer;
  x0: integer;
begin
  x0 := x1;
  if x0 = 0 then
    x0 := 1;
  for i := x0 to x2 do
    if (buf[i] < 16) or (buf[i] > 239) then
      buf[i] := buf[i - 1];
end;

var
  palettesgenerated: boolean = false;

//==============================================================================
//
// V_AutoGeneratePalettes
//
//==============================================================================
procedure V_AutoGeneratePalettes(const base: string);
const
  {$IFDEF HEXEN}
  NUMPALETTES = 28;
  {$ELSE}
  NUMPALETTES = 14;
  {$ENDIF}
var
  wad: TWadWriter;
  fn: string;
  pal: PByteArray;
  playpal: packed array[0..768 * NUMPALETTES - 1] of byte;
  colormap: packed array[0..34 * 256 - 1] of byte;
  {$IFNDEF HEXEN}
  fogmap: packed array[0..34 * 256 - 1] of byte;
  {$ENDIF}
begin
  if palettesgenerated then
    exit;

  if base = '' then
    pal := W_CacheLumpName('PLAYPAL', PU_STATIC)
  else
    pal := W_CacheLumpName(base, PU_STATIC);
  ZeroMemory(@playpal, SizeOf(playpal));
  ZeroMemory(@colormap, SizeOf(colormap));
  {$IFDEF HEXEN}
  V_CreateDoomPalette(pal, @playpal, @colormap, nil);
  {$ELSE}
  ZeroMemory(@fogmap, SizeOf(fogmap));
  V_CreateDoomPalette(pal, @playpal, @colormap, @fogmap);
  {$ENDIF}
  Z_Free(pal);

  fn := I_NewTempFile('auto_palette.wad');

  wad := TWadWriter.Create;
  wad.AddData('PLAYPAL', @playpal, SizeOf(playpal));
  wad.AddData('COLORMAP', @colormap, SizeOf(colormap));
  {$IFNDEF HEXEN}
  wad.AddData('FOGMAP', @fogmap, SizeOf(fogmap));
  {$ENDIF}
  wad.SaveToFile(fn);
  wad.Free;

  W_RuntimeLoad(fn, F_ORIGIN_WAD);
end;

end.

