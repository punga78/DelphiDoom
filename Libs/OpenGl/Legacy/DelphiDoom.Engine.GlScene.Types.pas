//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the records of the OpenGL scene
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit DelphiDoom.Engine.GlScene.Types;

// The records of a wall, a flat and a sprite of a frame (they were in the implementation of
// gl_render.pas): the classes that collect them and gl_render, which draws them, share them.
// The names and the layout are the ones of the old code.

interface

uses
  d_delphi,
  m_fixed,
  r_defs,
  p_mobj_h,
  gl_defs;

type
  TGLSeg = record
    x1, x2: float;
    z1, z2: float;
    frontsector: Psector_t;
    backsector: Psector_t;
  end;
  PGLSeg = ^TGLSeg;
  GLSegArray = array[0..$FFFF] of TGLSeg;
  PGLSegArray = ^GLSegArray;

const
  GLDWF_TOP = 1;
  GLDWF_M1S = 2;
  GLDWF_MTS = 3;  // Thick Side
  GLDWF_M2S = 4;
  GLDWF_BOT = 5;
  GLDWF_TOPFLUD = 6; //e6y: project the ceiling plane into the gap
  GLDWF_BOTFLUD = 7; //e6y: project the floor plane into the gap
  GLDWF_SKY = 8;
  GLDWF_SKYFLIP = 9;

type
  GLWall = record
    glseg: PGLSeg;
    ytop, ybottom, ymid: float;
    ul, ur, vt, vb: float;
    light: float;
    light2: float;
    whitefog: boolean;  // JVAL: Mars fog sectors
    whitefog2: boolean; // JVAL: Mars fog sectors
    doublelight: boolean;
    alpha: float;
    skyymid: float;
    skyyaw: float;
    gltexture: PGLTexture;
    flag: byte;
    blend: boolean;
  end;
  PGLWall = ^GLWall;
  GLWallArray = array[0..$FFFF] of GLWall;
  PGLWallArray = ^GLWallArray;

  GLFlat = record
    sectornum: integer;
    light: float; // the lightlevel of the flat
    z: float; // the z position of the flat (height)
    angle: float;
    anglex, angley: float;
    hasangle: boolean;
    gltexture: PGLTexture;
    {$IFNDEF HERETIC}
    uoffs, voffs: float; // the texture coordinates
    hasoffset: boolean;
    {$ENDIF}
    ripple: boolean;
    whitefog: boolean; // JVAL: Mars fog sectors
    ceiling: boolean;
  end;
  PGLFlat = ^GLFlat;
  GLFlatArray = array[0..$FFFF] of GLFlat;
  PGLFlatArray = ^GLFlatArray;

const
  GLS_SHADOW = 1;
  GLS_TRANSPARENT = 2;
  GLS_CLIPPED = 4;
  GLS_WHITELIGHT = 8;
  GLS_REDLIGHT = 16;
  GLS_GREENLIGHT = 32;
  GLS_BLUELIGHT = 64;
  GLS_YELLOWLIGHT = 128;
  GLS_LIGHT = GLS_WHITELIGHT or GLS_REDLIGHT or GLS_GREENLIGHT or GLS_BLUELIGHT or GLS_YELLOWLIGHT;
  GLS_ADDITIVE = 256;
  GLS_SUBTRACTIVE = 512;

type
  GLSprite = record
    cm: integer;
    x, y, z: float;
    vt, vb: float;
    ul, ur: float;
    x1, y1: float;
    x2, y2: float;
    light: float;
    scale: fixed_t;
    gltexture: PGLTexture;
    flags: integer;
    alpha: float;
    dlights: T2DNumberList;
    models: TDNumberList;
    voxels: TDNumberList;
    mo: Pmobj_t;
    aproxdist: fixed_t;
  end;
  PGLSprite = ^GLSprite;
  GLSpriteArray = array[0..$FFFF] of GLSprite;
  PGLSpriteArray = ^GLSpriteArray;

implementation

end.
