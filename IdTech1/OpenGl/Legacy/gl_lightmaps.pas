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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

//
// JVAL
//
// Volumetric dynamic lightmap using a single 3D texture
//

unit gl_lightmaps;

interface

uses
  d_delphi,
  dglOpenGL,
  DelphiDoom.Engine.GlLightmap.Types;

var
  gl_uselightmaps: boolean = true;
  canuselightmaps: boolean = true;

//==============================================================================
//
// gld_InitLightmap
//
//==============================================================================
procedure gld_InitLightmap;

//==============================================================================
//
// gld_LightmapDone
//
//==============================================================================
procedure gld_LightmapDone;

//==============================================================================
//
// gld_ActivateLightmap
//
//==============================================================================
procedure gld_ActivateLightmap;

//==============================================================================
//
// gld_DeactivateLightmap
//
//==============================================================================
procedure gld_DeactivateLightmap;

//==============================================================================
//
// gld_PauseLightmap
//
//==============================================================================
procedure gld_PauseLightmap;

//==============================================================================
//
// gld_ResumeLightmap
//
//==============================================================================
procedure gld_ResumeLightmap;


implementation

uses
  System.SysUtils,
  c_cmds,
  gl_defs,
  DelphiDoom.Engine.GlLightmap.Calculator;

var
  // The state and the calculation of the lightmap (DelphiDoom.Engine.GlLightmap.Calculator)
  FLightmap: TEngineGlLightmapCalculator;
  lightmap_tex_num: GLUint;

//==============================================================================
//
// Vox_ExportLightmap
//
//==============================================================================
procedure Vox_ExportLightmap(const fname: string);
begin
  FLightmap.Export(fname);
end;

//==============================================================================
//
// gld_InitLightmap
//
//==============================================================================
procedure gld_InitLightmap;
begin
  glGenTextures(1, @lightmap_tex_num);

  FLightmap := TEngineGlLightmapCalculator.Create;

  C_AddCmd('vox_exportlightmap', @Vox_ExportLightmap);
end;

//==============================================================================
//
// gld_LightmapDone
//
//==============================================================================
procedure gld_LightmapDone;
begin
  FreeAndNil(FLightmap);
  glDeleteTextures(1, @lightmap_tex_num);
end;

//==============================================================================
// gld_ActivateLightmap
//
// JVAL
//
// Activate Lightmap 3D texture, calls gld_CalculateLightmap
//
//==============================================================================
procedure gld_ActivateLightmap;
var
  TexGenSPlane, TexGenTPlane, TexGenRPlane: TVector4f;
begin
  glActiveTextureARB(GL_TEXTURE1_ARB);
  glEnable(GL_TEXTURE_3D);

  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE_ARB);
  glTexEnvi(GL_TEXTURE_ENV, GL_RGB_SCALE_ARB, 2);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 4);

  glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_S, GL_CLAMP);
  glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_T, GL_CLAMP);
  glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_R, GL_CLAMP);

  glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); //GL_NEAREST); //gl_tex_filter);
  glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); //GL_NEAREST); //gl_tex_filter);

  glEnable(GL_TEXTURE_GEN_S);
  glEnable(GL_TEXTURE_GEN_T);
  glEnable(GL_TEXTURE_GEN_R);

  glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_OBJECT_LINEAR);
  glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_OBJECT_LINEAR);
  glTexGeni(GL_R, GL_TEXTURE_GEN_MODE, GL_OBJECT_LINEAR);

  TexGenSPlane[0] := MAP_COEFF / (LIGHTMAPSIZEX * LIGHTMAPUNIT);
  TexGenSPlane[1] := 0.0;
  TexGenSPlane[2] := 0.0;
  TexGenSPlane[3] := 0.0;

  TexGenTPlane[0] := 0.0;
  TexGenTPlane[1] := MAP_COEFF / (LIGHTMAPSIZEY * LIGHTMAPUNIT);
  TexGenTPlane[2] := 0.0;
  TexGenTPlane[3] := 0.0;

  TexGenRPlane[0] := 0.0;
  TexGenRPlane[1] := 0.0;
  TexGenRPlane[2] := MAP_COEFF / (LIGHTMAPSIZEZ * LIGHTMAPUNIT);
  TexGenRPlane[3] := 0.0;

  glTexGenfv(GL_S, GL_OBJECT_PLANE, @TexGenSPlane);
  glTexGenfv(GL_T, GL_OBJECT_PLANE, @TexGenTPlane);
  glTexGenfv(GL_R, GL_OBJECT_PLANE, @TexGenRPlane);

  if not FLightmap.Defined then
  begin
    glBindTexture(GL_TEXTURE_3D, lightmap_tex_num);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_BASE_LEVEL, 0);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MAX_LEVEL, 0);
  end;

  FLightmap.Calculate;
  FLightmap.PlaceTexture;

  glActiveTextureARB(GL_TEXTURE0_ARB);
  glEnable(GL_TEXTURE_2D);
end;

//==============================================================================
// gld_DeactivateLightmap
//
// JVAL
//
// Deactivate Lightmap
//
//==============================================================================
procedure gld_DeactivateLightmap;
begin
  glActiveTextureARB(GL_TEXTURE1_ARB);
  glMatrixMode(GL_TEXTURE);
  glPopMatrix;
  glMatrixMode(GL_MODELVIEW);
  glDisable(GL_TEXTURE_3D);
  glActiveTextureARB(GL_TEXTURE0_ARB);
  glEnable(GL_TEXTURE_2D);
end;

//==============================================================================
//
// gld_PauseLightmap
//
//==============================================================================
procedure gld_PauseLightmap;
begin
  glActiveTextureARB(GL_TEXTURE1_ARB);
  glDisable(GL_TEXTURE_3D);
  glActiveTextureARB(GL_TEXTURE0_ARB);
end;

//==============================================================================
//
// gld_ResumeLightmap
//
//==============================================================================
procedure gld_ResumeLightmap;
begin
  glActiveTextureARB(GL_TEXTURE1_ARB);
  glEnable(GL_TEXTURE_3D);
  glActiveTextureARB(GL_TEXTURE0_ARB);
end;


end.
