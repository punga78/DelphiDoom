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

unit gl_ambient;

interface

//==============================================================================
//
// gld_InitAmbient
//
//==============================================================================
procedure gld_InitAmbient;

//==============================================================================
//
// gld_AmbientDone
//
//==============================================================================
procedure gld_AmbientDone;

//==============================================================================
//
// gld_AmbientExecute
//
//==============================================================================

implementation

uses
  d_delphi,
  dglOpenGL,
  doomdef,
  gl_tex,
  DelphiDoom.Engine.Texture.Item;

const
  AMBIENTPRECISION = 8;

var
  xstep, ystep: float;
  ambient_tex: PTexture;
  tex: GLUint;

//==============================================================================
//
// gld_InitAmbient
//
//==============================================================================
procedure gld_InitAmbient;
begin
  xstep := SCREENWIDTH / (AMBIENTPRECISION - 1);
  ystep := SCREENHEIGHT / (AMBIENTPRECISION - 1);
  ambient_tex := new(PTexture, Create);
  ambient_tex.ScaleTo(AMBIENTPRECISION, AMBIENTPRECISION);
  ambient_tex.ConvertTo32bit;
  tex := gld_LoadExternalTexture(ambient_tex, True, GL_CLAMP);
end;

//==============================================================================
//
// gld_AmbientDone
//
//==============================================================================
procedure gld_AmbientDone;
begin
  glDeleteTextures(1, @tex);
  if ambient_tex <> nil then
    Dispose(ambient_tex, destroy);
end;

end.
