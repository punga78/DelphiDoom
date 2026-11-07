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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//  DESCRIPTION:
//    Dynamic lights (OpenGL & software rendering)
//    LIGHTDEF/GLDEFS parsing, light animation and the records of every light are in
//    Libs\DynLights (IDynLightRenderCache, given by the composition root to r_main,
//    r_softlights and gl_render); this unit keeps the buffers that the renderers sort
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_dynlights;

interface

uses
  d_delphi,
  {$IFNDEF OPENGL}
  r_vislight,
  p_mobj_h,
  {$ENDIF}
  m_fixed,
  DelphiDoom.DynLights.Types;

type
  // The record of a light: Libs\DynLights fills it (r, g, b, radius, x, y, z, shadow)
  GLDRenderLight = TDynLightRender;
  PGLDRenderLight = PDynLightRender;
  GLDRenderLightArray = array[0..$FFF] of GLDRenderLight;
  PGLDRenderLightArray = ^GLDRenderLightArray;

var
  lightdeflumppresent: boolean = false;

type
  dlsortitem_t = record
    l: PGLDRenderLight;
    squaredist: single;
    x, y, z: {$IFDEF OPENGL}float{$ELSE}fixed_t{$ENDIF};
    {$IFNDEF OPENGL}
    radius: fixed_t;
    vis: Pvislight_t;
    mo: Pmobj_t;
    {$ENDIF}
  end;
  Pdlsortitem_t = ^dlsortitem_t;
  dlsortitem_tArray = array[0..$FFFF] of dlsortitem_t;
  Pdlsortitem_tArray = ^dlsortitem_tArray;

var
  dlbuffer: Pdlsortitem_tArray = nil;
  numdlitems: integer = 0;
  realdlitems: integer = 0;

const
  DLIGHTSDRAWRANGE = 2048 * FRACUNIT;

var
  gldefs_as_lightdef: boolean = true;

//==============================================================================
//
// R_FreeDynamicLightItems
//
// Frees the buffer of the lights to sort (dlbuffer), at the end of the renderer
//
//==============================================================================
procedure R_FreeDynamicLightItems;

implementation

//==============================================================================
//
// R_FreeDynamicLightItems
//
//==============================================================================
procedure R_FreeDynamicLightItems;
begin
  memfree(pointer(dlbuffer), realdlitems * SizeOf(dlsortitem_t));
  numdlitems := 0;
  realdlitems := 0;
end;

end.
