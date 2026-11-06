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
//  ANIMDEFS lump
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_animdefs;

interface

uses
  d_delphi,
  DelphiDoom.Definitions.Intf;

//==============================================================================
//
// P_InitFTAnims
//
//==============================================================================
procedure P_InitFTAnims;

//==============================================================================
//
// P_ConfigureAnimDefs
//
//==============================================================================
procedure P_ConfigureAnimDefs(const AParser: IDefAnimDefsParser);

//==============================================================================
//
// P_AnimateSurfaces
//
//==============================================================================
procedure P_AnimateSurfaces;

//==============================================================================
//
// P_InitAnimations
//
//==============================================================================
procedure P_InitAnimations;

//==============================================================================
//
// P_ShutDownAnimations
//
//==============================================================================
procedure P_ShutDownAnimations;

var
  animatedflatslist: TDNumberList;
  animatedtextureslist: TDNumberList;

implementation

uses
  m_rnd,
  m_fixed,
  i_system,
  r_data,
  r_defs,
  DelphiDoom.Definitions.Types,
  w_wad;

const
  ANIM_SCRIPT_NAME = 'ANIMDEFS';
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

// PRIVATE DATA DEFINITIONS ------------------------------------------------
var
  AnimDefs: array[0..MAX_ANIM_DEFS - 1] of animDef_t;
  FrameDefs: array[0..MAX_FRAME_DEFS - 1] of frameDef_t;
  AnimDefCount: integer;
  animdefs_parser: IDefAnimDefsParser;

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

//==========================================================================
//
// P_InitFTAnims
//
// Initialize flat and texture animation lists.
//
//==========================================================================
//
//==============================================================================
procedure P_InitFTAnims;
var
  fd: integer;
  ad: PanimDef_t;
  animlump: integer;
  anims: TArray<TDefAnimation>;
  anim: TDefAnimation;
  frame: TDefAnimFrame;
  base: integer;
  i, j: integer;
begin
  animlump := W_CheckNumForName(ANIM_SCRIPT_NAME);
  if animlump < 0 then
    exit;

  if animdefs_parser = nil then
    I_Error('P_InitFTAnims(): ANIMDEFS is not configured (ComposeEngine was not called)');

  animatedflatslist.Clear;
  animatedtextureslist.Clear;
  fd := 0;
  ad := @AnimDefs[0];
  AnimDefCount := 0;

  // The parser leaves out the animations of flats and textures that do not exist
  try
    anims := animdefs_parser.Parse(W_TextLumpNum(animlump));
  except
    on E: EDefinitionsException do
      I_Error('%s', [E.Message]);
  end;

  for i := 0 to Length(anims) - 1 do
  begin
    anim := anims[i];
    if anim.Kind = TDefAnimKind.Flat then
    begin
      ad._type := ANIM_FLAT;
      base := R_FlatNumForName(anim.Name);
    end
    else
    begin
      ad._type := ANIM_TEXTURE;
      base := R_TextureNumForName(anim.Name);
    end;
    ad.index := base;

    // The list of the animated pictures: the first one and the one of every pic line
    for j := 0 to Length(anim.AnimatedOffsets) - 1 do
      if ad._type = ANIM_FLAT then
        animatedflatslist.Add(base + anim.AnimatedOffsets[j])
      else
        animatedtextureslist.Add(base + anim.AnimatedOffsets[j]);

    ad.startFrameDef := fd;
    for j := 0 to Length(anim.Frames) - 1 do
    begin
      frame := anim.Frames[j];
      FrameDefs[fd].index := base + frame.PicNumber - 1;
      FrameDefs[fd].tics := frame.PackedTics;
      inc(fd);
    end;
    ad.endFrameDef := fd - 1;
    ad.currentFrameDef := ad.endFrameDef;
    ad.tics := 1; // Force 1st game tic to animate
    inc(AnimDefCount);
    inc(ad);
  end;
end;

//==============================================================================
//
// P_ConfigureAnimDefs
//
//==============================================================================
procedure P_ConfigureAnimDefs(const AParser: IDefAnimDefsParser);
begin
  animdefs_parser := AParser;
end;

//==============================================================================
//
// P_InitAnimations
//
//==============================================================================
procedure P_InitAnimations;
begin
  animatedflatslist := TDNumberList.Create;
  animatedtextureslist := TDNumberList.Create;
end;

//==============================================================================
//
// P_ShutDownAnimations
//
//==============================================================================
procedure P_ShutDownAnimations;
begin
  FreeAndNil(animatedflatslist);
  FreeAndNil(animatedtextureslist);
end;

end.

