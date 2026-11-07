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
//    View frustum: the facade of Libs\GlMath (IGlFrustum). The unit only reads
//    the matrices from OpenGL, the planes and the tests are in the library.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit gl_frustum;

interface

uses
  DelphiDoom.GlMath.Intf;

//==============================================================================
//
// GL_ConfigureFrustum
//
//==============================================================================
procedure GL_ConfigureFrustum(const AFrustum: IGlFrustum);

//==============================================================================
//
// fr_CalculateFrustum
//
//==============================================================================
procedure fr_CalculateFrustum;

//==============================================================================
//
// fr_PointInFrustum
//
//==============================================================================
function fr_PointInFrustum(X, Y, Z: single): boolean;

//==============================================================================
//
// fr_SphereInFrustum
//
//==============================================================================
function fr_SphereInFrustum(X, Y, Z, Radius: single): boolean;

//==============================================================================
//
// fr_CubeInFrustum
//
//==============================================================================
function fr_CubeInFrustum(X, Y, Z, Size: single): boolean;

//==============================================================================
//
// fr_BoxInFrustum
//
//==============================================================================
function fr_BoxInFrustum(X, Y, Z, sizeX, sizeY, sizeZ: single): boolean;

implementation

uses
  dglOpenGL,
  DelphiDoom.GlMath.Types,
  i_system;

var
  frustum_service: IGlFrustum = nil;

//==============================================================================
//
// GL_ConfigureFrustum
//
//==============================================================================
procedure GL_ConfigureFrustum(const AFrustum: IGlFrustum);
begin
  frustum_service := AFrustum;
end;

//==============================================================================
//
// CheckFrustum
//
//==============================================================================
procedure CheckFrustum;
begin
  if not Assigned(frustum_service) then
    I_Error('gl_frustum: the frustum is not configured (call ComposeEngine first)');
end;

//==============================================================================
//
// fr_CalculateFrustum
//
//==============================================================================
procedure fr_CalculateFrustum;
var
  proj, modl: TGlMatrix4;
begin
  CheckFrustum;

  // glGetFloatv() is used to extract information about our OpenGL world.
  // Below, we pass in GL_PROJECTION_MATRIX to abstract our projection matrix.
  glGetFloatv(GL_PROJECTION_MATRIX, @proj);

  // By passing in GL_MODELVIEW_MATRIX, we can abstract our model view matrix.
  glGetFloatv(GL_MODELVIEW_MATRIX, @modl);

  // The planes come from the two matrices multiplied (Libs\GlMath)
  frustum_service.Calculate(proj, modl);
end;

//==============================================================================
//
// fr_PointInFrustum
//
//==============================================================================
function fr_PointInFrustum(X, Y, Z: single): boolean;
begin
  CheckFrustum;
  result := frustum_service.ContainsPoint(X, Y, Z);
end;

//==============================================================================
//
// fr_SphereInFrustum
//
//==============================================================================
function fr_SphereInFrustum(X, Y, Z, Radius: single): boolean;
begin
  CheckFrustum;
  result := frustum_service.ContainsSphere(X, Y, Z, Radius);
end;

//==============================================================================
//
// fr_BoxInFrustum
//
//==============================================================================
function fr_BoxInFrustum(X, Y, Z, sizeX, sizeY, sizeZ: single): boolean;
begin
  CheckFrustum;
  result := frustum_service.ContainsBox(X, Y, Z, sizeX, sizeY, sizeZ);
end;

//==============================================================================
//
// fr_CubeInFrustum
//
//==============================================================================
function fr_CubeInFrustum(X, Y, Z, Size: single): boolean;
begin
  CheckFrustum;
  result := frustum_service.ContainsCube(X, Y, Z, Size);
end;

end.
