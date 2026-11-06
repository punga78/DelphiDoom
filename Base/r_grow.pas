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
unit r_grow;

interface

uses
  r_cache_walls,
  r_cache_flats,
  r_hires,
  DelphiDoom.Imaging.Intf;

//==============================================================================
//
// R_ConfigureGrow
// The grower of spans of Libs\Imaging, given by the composition root
//
//==============================================================================
procedure R_ConfigureGrow(const AGrower: IImagingSpanGrower);

//==============================================================================
//
// R_GrowSpan64to128
//
//==============================================================================
procedure R_GrowSpan64to128(const p: Pds32cacheinfo_t);

//==============================================================================
//
// R_GrowSpan64to256
//
//==============================================================================
procedure R_GrowSpan64to256(const p: Pds32cacheinfo_t);

//==============================================================================
//
// R_GrowSpan64to512
//
// JVAL
//
// For extreme flat filtering, slow
//
//==============================================================================
procedure R_GrowSpan64to512(const p: Pds32cacheinfo_t);

implementation

uses
  d_delphi,
  i_system,
  r_flatinfo,
  DelphiDoom.Imaging.Types;

var
  span_grower: IImagingSpanGrower;

//==============================================================================
//
// R_ConfigureGrow
//
//==============================================================================
procedure R_ConfigureGrow(const AGrower: IImagingSpanGrower);
begin
  span_grower := AGrower;
end;

type
  growfunc_t = reference to function(const source: TImagingPixels): TImagingPixels;

// The cache keeps the pixels: a 64x64 span goes in, the bigger one goes out
procedure R_GrowSpan(const p: Pds32cacheinfo_t; const newscale: dsscale_t; const count: integer;
  const grow: growfunc_t);
var
  source: TImagingPixels;
  grown: TImagingPixels;
  p1, p2: Pds32_t;
begin
  if p.scale <> ds64x64 then
    exit;

  SetLength(source, 4096);
  p1 := R_Get_ds32(p);
  Move(p1[0], source[0], 4096 * SizeOf(LongWord));

  grown := grow(source);

  p.scale := newscale;
  p2 := R_Get_ds32(p);
  Move(grown[0], p2[0], count * SizeOf(LongWord));
end;

//==============================================================================
//
// R_GrowSpan64to128
//
//==============================================================================
procedure R_GrowSpan64to128(const p: Pds32cacheinfo_t);
begin
  if span_grower = nil then
    I_Error('R_GrowSpan64to128(): the images are not configured (ComposeEngine was not called)');
  R_GrowSpan(p, ds128x128, 128 * 128,
    function(const source: TImagingPixels): TImagingPixels
    begin
      result := span_grower.Grow64to128(source);
    end);
end;

//==============================================================================
//
// R_GrowSpan64to256
//
//==============================================================================
procedure R_GrowSpan64to256(const p: Pds32cacheinfo_t);
begin
  if span_grower = nil then
    I_Error('R_GrowSpan64to256(): the images are not configured (ComposeEngine was not called)');
  R_GrowSpan(p, ds256x256, 256 * 256,
    function(const source: TImagingPixels): TImagingPixels
    begin
      result := span_grower.Grow64to256(source);
    end);
end;

//==============================================================================
//
// R_GrowSpan64to512
//
//==============================================================================
procedure R_GrowSpan64to512(const p: Pds32cacheinfo_t);
begin
  if span_grower = nil then
    I_Error('R_GrowSpan64to512(): the images are not configured (ComposeEngine was not called)');
  R_GrowSpan(p, ds512x512, 512 * 512,
    function(const source: TImagingPixels): TImagingPixels
    begin
      result := span_grower.Grow64to512(source);
    end);
end;

end.
