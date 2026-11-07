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
//  The sizes of the flats that the renderers share.
//  The FLATINFO lump is read by R_InitFlats (r_data) with the parser of
//  Libs\TextureDefs, the reduction to 64x64 is done by V_TileScreen8
//  (v_video) with the shrinker of Libs\Imaging.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_flatinfo;

interface

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

implementation

end.
