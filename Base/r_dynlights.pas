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
//    LIGHTDEF/GLDEFS parsing and light animation are in LibsDynLights,
//    this unit keeps the render records that the renderers use
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
  DelphiDoom.DynLights.Intf;

type
  GLDRenderLight = record
    r, g, b: float;     // Color
    radius: float;      // radius
    x, y, z: float;     // Offset
    shadow: boolean;    // Shadow
  end;
  PGLDRenderLight = ^GLDRenderLight;
  GLDRenderLightArray = array[0..$FFF] of GLDRenderLight;
  PGLDRenderLightArray = ^GLDRenderLightArray;

//==============================================================================
//
// R_ConfigureDynamicLights
// The loader, the registry and the animator of Libs\DynLights, given by the
// composition root
//
//==============================================================================
procedure R_ConfigureDynamicLights(const ALoader: IDynLightLoader;
  const ARegistry: IDynLightRegistry; const AAnimator: IDynLightAnimator);

//==============================================================================
//
// R_InitDynamicLights
//
//==============================================================================
procedure R_InitDynamicLights;

//==============================================================================
//
// R_DynamicLightsDone
//
//==============================================================================
procedure R_DynamicLightsDone;

//==============================================================================
//
// R_GetDynamicLight
//
//==============================================================================
function R_GetDynamicLight(const index: integer): PGLDRenderLight;

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

implementation

uses
  DelphiDoom.DynLights.Types,
  i_system,
  p_tick;

var
  dl_loader: IDynLightLoader;
  dl_registry: IDynLightRegistry;
  dl_animator: IDynLightAnimator;
  // The lights that R_GetDynamicLight gives are pointers that the renderers keep for a frame:
  // one stable record for each light, and the tic at which it was last calculated
  dl_renderinfo: array of GLDRenderLight;
  dl_hasrender: array of boolean;
  dl_rendertime: array of integer;

//==============================================================================
//
// R_ConfigureDynamicLights
//
//==============================================================================
procedure R_ConfigureDynamicLights(const ALoader: IDynLightLoader;
  const ARegistry: IDynLightRegistry; const AAnimator: IDynLightAnimator);
begin
  dl_loader := ALoader;
  dl_registry := ARegistry;
  dl_animator := AAnimator;
end;

//==============================================================================
//
// R_InitDynamicLights
//
//==============================================================================
procedure R_InitDynamicLights;
begin
  if dl_loader = nil then
    I_Error('R_InitDynamicLights(): the dynamic lights are not configured (ComposeEngine was not called)');

  dl_registry.Clear;
  dl_animator.Reset;
  {$IFDEF OPENGL}
  printf('SC_ParceDynamicLights: Parsing LIGHTDEF lumps.'#13#10);
  {$ENDIF}
  if dl_loader.Load(gldefs_as_lightdef) then
    lightdeflumppresent := true;

  SetLength(dl_renderinfo, dl_registry.Count);
  SetLength(dl_hasrender, dl_registry.Count);
  SetLength(dl_rendertime, dl_registry.Count);
  if Length(dl_renderinfo) > 0 then
  begin
    FillChar(dl_renderinfo[0], Length(dl_renderinfo) * SizeOf(GLDRenderLight), 0);
    FillChar(dl_hasrender[0], Length(dl_hasrender) * SizeOf(boolean), 0);
  end;
end;

//==============================================================================
//
// R_DynamicLightsDone
//
//==============================================================================
procedure R_DynamicLightsDone;
begin
  if dl_registry <> nil then
    dl_registry.Clear;
  if dl_animator <> nil then
    dl_animator.Reset;
  SetLength(dl_renderinfo, 0);
  SetLength(dl_hasrender, 0);
  SetLength(dl_rendertime, 0);

  memfree(pointer(dlbuffer), realdlitems * SizeOf(dlsortitem_t));
  numdlitems := 0;
  realdlitems := 0;
end;

//==============================================================================
//
// R_GetDynamicLight
//       Dynamic lights animations
//
//==============================================================================
function R_GetDynamicLight(const index: integer): PGLDRenderLight;
var
  render: TDynLightRender;
begin
  result := @dl_renderinfo[index];
  result.shadow := false;

  // The animation of a light is the same during one tic
  if dl_hasrender[index] and (dl_rendertime[index] = leveltime) then
    exit;

  render := dl_animator.GetRender(index, leveltime);
  result.r := render.R;
  result.g := render.G;
  result.b := render.B;
  result.radius := render.Radius;
  result.x := render.X;
  result.y := render.Y;
  result.z := render.Z;
  dl_hasrender[index] := true;
  dl_rendertime[index] := leveltime;
end;

end.
