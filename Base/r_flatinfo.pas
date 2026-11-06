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
//  FLATINFO lump
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_flatinfo;

interface

uses
  DelphiDoom.TextureDefs.Types,
  DelphiDoom.TextureDefs.Intf,
  DelphiDoom.Imaging.Intf;

//==============================================================================
//
// R_ParseFlatInfoLumps
//
//==============================================================================
procedure R_ParseFlatInfoLumps;

//==============================================================================
//
// R_ConfigureFlatInfo
//
//==============================================================================
procedure R_ConfigureFlatInfo(const AParser: ITextureDefsFlatInfoParser; const ACatalog: ITextureDefsFlatCatalog);

//==============================================================================
//
// R_FlatSizeFromSize
//
//==============================================================================
function R_FlatSizeFromSize(const size: integer): integer;

type
  dsscale_t = (ds64x64, ds128x128, ds256x256, ds512x512, NUMDSSCALES);

var
  ds_scale: dsscale_t;

const
  FS64x64 = 0;
  FS128x128 = 1;
  FS256x256 = 2;
  FS512x512 = 3;
  FS1024x1024 = 4;
  FS2048x2048 = 5;
  FS4096x4096 = 6;

type
  dsscalesizeitem_t = record
    memsize: integer;
    flatsize: integer;
  end;

const
  dsscalesize: array[FS64x64..FS4096x4096] of dsscalesizeitem_t = (
    (memsize:   64 *   64; flatsize:   64),
    (memsize:  128 *  128; flatsize:  128),
    (memsize:  256 *  256; flatsize:  256),
    (memsize:  512 *  512; flatsize:  512),
    (memsize: 1024 * 1024; flatsize: 1024),
    (memsize: 2048 * 2048; flatsize: 2048),
    (memsize: 4096 * 4096; flatsize: 4096)
  );

//==============================================================================
//
// R_ShrinkFlatTo64x64
//
//==============================================================================
function R_ShrinkFlatTo64x64(const fin: Pointer; const sz: Integer; const fout: Pointer): Boolean;

//==============================================================================
//
// R_ConfigureFlatShrink
//
//==============================================================================
procedure R_ConfigureFlatShrink(const AShrinker: IImagingFlatShrinker);

implementation

uses
  d_delphi,
  i_system,
  r_defs,
  r_data,

  w_pak,
  w_wad;

var
  flatinfo_parser: ITextureDefsFlatInfoParser;
  flatinfo_catalog: ITextureDefsFlatCatalog;
  flat_shrinker: IImagingFlatShrinker;

//==============================================================================
//
// R_ParseFlatInfoText
//
//==============================================================================
procedure R_ParseFlatInfoText(const in_text: string);
var
  sizes: TArray<TTextureDefsFlatSize>;
  i: integer;
begin
  if flatinfo_parser = nil then
    I_Error('R_ParseFlatInfoText(): FLATINFO is not configured (ComposeEngine was not called)');

  sizes := flatinfo_parser.Parse(in_text, flatinfo_catalog);
  for i := 0 to Length(sizes) - 1 do
    flats[sizes[i].FlatIndex].size := sizes[i].SizeCode;
end;

//==============================================================================
//
// R_ConfigureFlatInfo
//
//==============================================================================
procedure R_ConfigureFlatInfo(const AParser: ITextureDefsFlatInfoParser; const ACatalog: ITextureDefsFlatCatalog);
begin
  flatinfo_parser := AParser;
  flatinfo_catalog := ACatalog;
end;


const
  FLATINFOLUMPNAME = 'FLATINFO';

var
  fl_text: string;

//==============================================================================
//
// R_RetrieveFlatInfo
//
//==============================================================================
procedure R_RetrieveFlatInfo(const in_text: string);
begin
  if fl_text = '' then
    fl_text := in_text
  else
    fl_text := fl_text + #13#10 + in_text;
end;

//==============================================================================
//
// R_ParseFlatInfoLumps
//
//==============================================================================
procedure R_ParseFlatInfoLumps;
var
  i: integer;
begin
  fl_text := '';
  for i := 0 to W_NumLumps - 1 do
    if char8tostring(W_GetNameForNum(i)) = FLATINFOLUMPNAME then
      R_RetrieveFlatInfo(W_TextLumpNum(i));

  PAK_StringIterator(FLATINFOLUMPNAME, R_RetrieveFlatInfo);
  PAK_StringIterator(FLATINFOLUMPNAME + '.txt', R_RetrieveFlatInfo);

  R_ParseFlatInfoText(fl_text);
  fl_text := '';
end;

//==============================================================================
//
// R_FlatSizeFromSize
//
//==============================================================================
function R_FlatSizeFromSize(const size: integer): integer;
begin
  if size = 128 then
    Result := FS128x128
  else if size = 256 then
    Result := FS256x256
  else if size = 512 then
    Result := FS512x512
  else if size = 1024 then
    Result := FS1024x1024
  else if size = 2048 then
    Result := FS2048x2048
  else if size = 4096 then
    Result := FS4096x4096
  else
    Result := FS64x64;
end;

//==============================================================================
//
// R_ShrinkFlatTo64x64
//
//==============================================================================
function R_ShrinkFlatTo64x64(const fin: Pointer; const sz: Integer; const fout: Pointer): Boolean;
var
  flat: TArray<Byte>;
  shrunk: TArray<Byte>;
begin
  result := false;
  if flat_shrinker = nil then
    I_Error('R_ShrinkFlatTo64x64(): the images are not configured (ComposeEngine was not called)');

  if sz <= 0 then
    exit;

  SetLength(flat, sz);
  Move(fin^, flat[0], sz);
  if flat_shrinker.Shrink(flat, shrunk) then
  begin
    Move(shrunk[0], fout^, Length(shrunk));
    result := true;
  end;
end;

//==============================================================================
//
// R_ConfigureFlatShrink
//
//==============================================================================
procedure R_ConfigureFlatShrink(const AShrinker: IImagingFlatShrinker);
begin
  flat_shrinker := AShrinker;
end;

end.
