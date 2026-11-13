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
//  Fix tutti frutti bug
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_patch;

interface

uses
  d_delphi,
  DelphiDoom.Imaging.Intf;

//==============================================================================
//
// R_ConfigureFixedColumn
// The builder of fixed columns of Libs\Imaging, given by the composition root
//
//==============================================================================
procedure R_ConfigureFixedColumn(const ABuilder: IImagingFixedColumnBuilder);

//==============================================================================
//
// R_InitFixedColumn
//
//==============================================================================
procedure R_InitFixedColumn;

//==============================================================================
//
// R_GetFixedColumn
//
//==============================================================================
function R_GetFixedColumn(const src: PByteArray; const tex, col: integer; const multipatch: boolean): PByteArray;

//==============================================================================
//
// R_EnableFixedColumn
//
//==============================================================================
procedure R_EnableFixedColumn;

//==============================================================================
//
// R_DisableFixedColumn
//
//==============================================================================
procedure R_DisableFixedColumn;

implementation

uses
  i_system,
  r_data,
  z_zone,
  DelphiDoom.Imaging.Types;

const
  FIXEDCOLUMNSIZE = $10000;
  FIXEDCOLUMNMASK = FIXEDCOLUMNSIZE - 1;

type
  Pfixedcolumnitem_t = ^fixedcolumnitem_t;
  fixedcolumnitem_t = record
    tex, column: integer;
    size: integer;
    data: PByteArray;
    next: Pfixedcolumnitem_t;
  end;

var
  fixedcolumns: array[0..FIXEDCOLUMNSIZE - 1] of Pfixedcolumnitem_t;
  fix_col_enabled: boolean = true;
  fixed_builder: IImagingFixedColumnBuilder = nil;

//==============================================================================
//
// R_ConfigureFixedColumn
//
//==============================================================================
procedure R_ConfigureFixedColumn(const ABuilder: IImagingFixedColumnBuilder);
begin
  fixed_builder := ABuilder;
end;

//==============================================================================
//
// R_InitFixedColumn
//
//==============================================================================
procedure R_InitFixedColumn;
begin
  ZeroMemory(@fixedcolumns, SizeOf(fixedcolumns));
end;

//==============================================================================
// R_GetFixedColumnHash
//
// JVAL: Cantor pairing function (https://en.wikipedia.org/wiki/Pairing_function#Cantor_pairing_function)
//
//==============================================================================
function R_GetFixedColumnHash(const tex, col: integer): LongWord;
var
  l: LongWord;
begin
  l := LongWord(tex + 1) + LongWord(col);
  result := ((l * (l + 1)) div 2) and FIXEDCOLUMNMASK;
end;

//==============================================================================
//
// R_GetFixedColumn
//
//==============================================================================
function R_GetFixedColumn(const src: PByteArray; const tex, col: integer; const multipatch: boolean): PByteArray;
var
  hash: LongWord;
  h1, h2: integer;
  item: Pfixedcolumnitem_t;

  procedure _generatedata128;
  var
    source, repeated: TArray<Byte>;
  begin
    SetLength(source, h1);
    memcpy(@source[0], src, h1);
    try
      repeated := fixed_builder.Repeat128(source, 0, h1);
    except
      on E: EImagingException do
        I_Error('R_GetFixedColumn(): %s (texture %d, column %d)', [E.Message, tex, col]);
    end;
    item.data := Z_Malloc(h2, PU_LEVEL, nil);
    memcpy(item.data, @repeated[0], h2);
  end;

  procedure _generatedataTL;
  var
    posts: PByteArray;
    size: integer;
    column, fixed: TArray<Byte>;
  begin
    // the posts end with 255 and each one takes its length plus 4 bytes
    posts := PByteArray(NativeInt(src) - 3);
    size := 0;
    while posts[size] <> $FF do
      size := size + posts[size + 1] + 4;
    inc(size);
    SetLength(column, size);
    memcpy(@column[0], posts, size);
    try
      fixed := fixed_builder.FromPosts(column, 0, h2);
    except
      on E: EImagingException do
        I_Error('R_GetFixedColumn(): %s (texture %d, column %d)', [E.Message, tex, col]);
    end;
    item.data := Z_Malloc(h2, PU_LEVEL, nil);
    if h2 > 0 then
      memcpy(item.data, @fixed[0], h2);
  end;

begin
  if not fix_col_enabled then
  begin
    result := src;
    exit;
  end;

  h1 := textures[tex].height;
  if h1 = 128 then
  begin
    result := src;
    exit;
  end;

  if h1 in [2, 4, 8, 16, 32, 64] then
  begin
    h2 := 128;
    hash := R_GetFixedColumnHash(tex, col);
    item := fixedcolumns[hash];
    while item <> nil do
    begin
      if (item.tex = tex) and (item.column = col) and (item.size = h2) then
      begin
        if item.data = nil then
          _generatedata128;
        result := item.data;
        exit;
      end;
      item := item.next;
    end;

    item := Z_Malloc(SizeOf(fixedcolumnitem_t), PU_LEVEL, nil);
    item.tex := tex;
    item.column := col;
    item.size := h2;

    _generatedata128;

    item.next := fixedcolumns[hash];
    fixedcolumns[hash] := item;

    result := item.data;
  end
  else if not multipatch then
  begin
    h2 := h1;
    hash := R_GetFixedColumnHash(tex, col);
    item := fixedcolumns[hash];
    while item <> nil do
    begin
      if (item.tex = tex) and (item.column = col) and (item.size = h2) then
      begin
        if item.data = nil then
          _generatedataTL;
        result := item.data;
        exit;
      end;
      item := item.next;
    end;

    item := Z_Malloc(SizeOf(fixedcolumnitem_t), PU_LEVEL, nil);
    item.tex := tex;
    item.column := col;
    item.size := h2;

    _generatedataTL;

    item.next := fixedcolumns[hash];
    fixedcolumns[hash] := item;

    result := item.data;
  end
  else
    result := src;
end;

//==============================================================================
//
// R_EnableFixedColumn
//
//==============================================================================
procedure R_EnableFixedColumn;
begin
  fix_col_enabled := true;
end;

//==============================================================================
//
// R_DisableFixedColumn
//
//==============================================================================
procedure R_DisableFixedColumn;
begin
  fix_col_enabled := false;
end;

end.
