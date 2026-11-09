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
//  The animations of ANIMDEFS played at every tic (TEngineAnimDefsLoader reads the lump)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_animdefs;

interface

uses
  d_delphi;

//==============================================================================
//
// P_AnimateSurfaces
//
//==============================================================================
procedure P_AnimateSurfaces;

const
  MAX_ANIM_DEFS = 128;
  MAX_FRAME_DEFS = 512;
  ANIM_FLAT = 0;
  ANIM_TEXTURE = 1;

// TYPES -------------------------------------------------------------------

type
  frameDef_t = record
    index: integer;
    tics: integer;
  end;
  PframeDef_t = ^frameDef_t;

  animDef_t = record
    _type: integer;
    index: integer;
    tics: integer;
    currentFrameDef: integer;
    startFrameDef: integer;
    endFrameDef: integer;
  end;
  PanimDef_t = ^animDef_t;

// The animations of ANIMDEFS: TEngineAnimDefsLoader writes them at the start, P_AnimateSurfaces
// plays them at every tic
var
  animatedflatslist: TDNumberList;
  animatedtextureslist: TDNumberList;
  AnimDefs: array[0..MAX_ANIM_DEFS - 1] of animDef_t;
  FrameDefs: array[0..MAX_FRAME_DEFS - 1] of frameDef_t;
  AnimDefCount: integer;

implementation

uses
  m_rnd,
  m_fixed,
  r_data,
  r_defs;

//==========================================================================
//
// P_AnimateSurfaces
//
//==========================================================================
//
//==============================================================================
procedure P_AnimateSurfaces;
var
  i: integer;
  ad: PanimDef_t;
begin
  // Animate flats and textures
  for i := 0 to AnimDefCount - 1 do
  begin
    ad := @AnimDefs[i];
    dec(ad.tics);
    if ad.tics = 0 then
    begin
      if ad.currentFrameDef = ad.endFrameDef then
        ad.currentFrameDef := ad.startFrameDef
      else
        inc(ad.currentFrameDef);
      ad.tics := FrameDefs[ad.currentFrameDef].tics;
      if ad.tics > 255 then
      begin // Random tics
        ad.tics := _SHR(ad.tics, 16) + P_Random mod _SHR(ad.tics and $ff00, 8);
      end;
      if ad._type = ANIM_FLAT then
      begin
        flats[ad.index].translation := FrameDefs[ad.currentFrameDef].index; // JVAL SOS
      end
      else
      begin // Texture
        texturetranslation[ad.index] := FrameDefs[ad.currentFrameDef].index;
      end;
    end;
  end;

end;

end.
