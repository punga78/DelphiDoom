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

unit r_precalc;

//
// JVAL
//  Precalculate as much as possible :)
//

interface

uses
  d_delphi,
  m_fixed,
  DelphiDoom.Palette.Intf;

//==============================================================================
//
// R_ConfigurePrecalc
// The precalculated tables of Libs\Palette, given by the composition root
//
//==============================================================================
procedure R_ConfigurePrecalc(const ATables: IPrecalcTables);

//==============================================================================
//
// R_InitPrecalc
//
//==============================================================================
procedure R_InitPrecalc;

//==============================================================================
//
// R_ShutDownPrecalc
//
//==============================================================================
procedure R_ShutDownPrecalc;

//==============================================================================
//
// R_GetPrecalc32Tables
//
//==============================================================================
procedure R_GetPrecalc32Tables(const f: fixed_t; var tr, tg, tb: PIntegerArray; const fog: boolean);  // JVAL: Mars fog sectors

{$IFDEF HEXEN}

//==============================================================================
//
// R_GetFogPrecalc32Tables
//
//==============================================================================
procedure R_GetFogPrecalc32Tables(const f: fixed_t; var tr, tg, tb: PIntegerArray);
{$ENDIF}

var
  // Invert colormap precalc
  precal32_ic: array[0..767] of LongWord;
  precal8_tolong: array[0..255] of LongWord;
  precal8_toword: array[0..255] of LongWord;
  precalc_fog_r: array[0..255] of PIntegerArray;
  precalc_fog_g: array[0..255] of PIntegerArray;
  precalc_fog_b: array[0..255] of PIntegerArray;
  average_byte: array[0..511] of Byte;
  average_r: array[0..511] of LongWord;
  average_g: array[0..511] of LongWord;
  average_b: array[0..511] of LongWord;
  add32_c: array[0..511] of Byte;

implementation

uses
  i_system;

var
  precalc32_r: array[0..255] of PIntegerArray;
  precalc32_g: array[0..255] of PIntegerArray;
  precalc32_b: array[0..255] of PIntegerArray;
  precalc_tables: IPrecalcTables = nil;

//==============================================================================
//
// R_ConfigurePrecalc
//
//==============================================================================
procedure R_ConfigurePrecalc(const ATables: IPrecalcTables);
begin
  precalc_tables := ATables;
end;

//==============================================================================
//
// CopyRows
// Gives each light level its own row of 256 values, like the engine reads them
//
//==============================================================================
procedure CopyRows(const values: TArray<Integer>; var rows: array of PIntegerArray);
var
  i: integer;
  p: PIntegerArray;
begin
  for i := 0 to 255 do
  begin
    p := malloc(256 * SizeOf(Integer));
    memcpy(p, @values[i * 256], 256 * SizeOf(Integer));
    rows[i] := p;
  end;
end;

//==============================================================================
//
// R_InitPrecalc
//
//==============================================================================
procedure R_InitPrecalc;
var
  i: integer;
  longs, words: TArray<Cardinal>;
  inverse: TArray<Cardinal>;
  byteavg, ravg, gavg, bavg: TArray<Cardinal>;
  addclamp: TArray<Byte>;
begin
  if precalc_tables = nil then
    I_Error('R_InitPrecalc(): the precalculated tables are not configured (ComposeEngine was not called)');

  CopyRows(precalc_tables.Multiply(0), precalc32_r);
  CopyRows(precalc_tables.Multiply(1), precalc32_g);
  CopyRows(precalc_tables.Multiply(2), precalc32_b);
  CopyRows(precalc_tables.Fog(0), precalc_fog_r);
  CopyRows(precalc_tables.Fog(1), precalc_fog_g);
  CopyRows(precalc_tables.Fog(2), precalc_fog_b);

  longs := precalc_tables.ByteToLong;
  words := precalc_tables.ByteToWord;
  for i := 0 to 255 do
  begin
    precal8_tolong[i] := longs[i];
    precal8_toword[i] := words[i];
  end;

  inverse := precalc_tables.InverseColor;
  for i := 0 to 767 do
    precal32_ic[i] := inverse[i];

  byteavg := precalc_tables.Average(0);
  ravg := precalc_tables.Average(1);
  gavg := precalc_tables.Average(2);
  bavg := precalc_tables.Average(3);
  addclamp := precalc_tables.AddClamp;
  for i := 0 to 511 do
  begin
    average_byte[i] := byteavg[i];
    average_r[i] := ravg[i];
    average_g[i] := gavg[i];
    average_b[i] := bavg[i];
    add32_c[i] := addclamp[i];
  end;

end;
//==============================================================================
//
// R_ShutDownPrecalc
//
//==============================================================================
procedure R_ShutDownPrecalc;
var
  i: integer;
begin
  for i := 0 to 255 do
  begin
    memfree(pointer(precalc32_r[i]), 256 * SizeOf(Integer));
    memfree(pointer(precalc32_g[i]), 256 * SizeOf(Integer));
    memfree(pointer(precalc32_b[i]), 256 * SizeOf(Integer));
    memfree(pointer(precalc_fog_r[i]), 256 * SizeOf(Integer));
    memfree(pointer(precalc_fog_g[i]), 256 * SizeOf(Integer));
    memfree(pointer(precalc_fog_b[i]), 256 * SizeOf(Integer));
  end;
end;

//==============================================================================
//
// R_GetPrecalc32Tables
//
//==============================================================================
procedure R_GetPrecalc32Tables(const f: fixed_t; var tr, tg, tb: PIntegerArray; const fog: boolean);  // JVAL: Mars fog sectors
var
  lf: Integer;
begin
  lf := f shr 8;
  if lf > 255 then
    lf := 255;
  if fog then
  begin
    tr := precalc_fog_r[lf];
    tg := precalc_fog_g[lf];
    tb := precalc_fog_b[lf];
  end
  else
  begin
    tr := precalc32_r[lf];
    tg := precalc32_g[lf];
    tb := precalc32_b[lf];
  end;
end;

{$IFDEF HEXEN}

//==============================================================================
//
// R_GetFogPrecalc32Tables
//
//==============================================================================
procedure R_GetFogPrecalc32Tables(const f: fixed_t; var tr, tg, tb: PIntegerArray);
var
  lf: Integer;
begin
  lf := f shr 8;
  if lf > 255 then
    lf := 255;
  tr := precalc_fog_r[lf];
  tg := precalc_fog_g[lf];
  tb := precalc_fog_b[lf];
end;
{$ENDIF}

end.
