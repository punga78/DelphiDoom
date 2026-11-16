//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - sizes of the dynamic lightmap of the OpenGL scene
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

unit DelphiDoom.Engine.GlLightmap.Types;

interface

const
  /// <summary>Cells of the 3D lightmap texture along x, y (up) and z</summary>
  LIGHTMAPSIZEX = 256;
  LIGHTMAPSIZEY = 64;
  LIGHTMAPSIZEZ = 256;
  /// <summary>Size of a cell in map units</summary>
  LIGHTMAPUNIT = 16;
  /// <summary>Bytes of the RGBA buffer of the whole lightmap</summary>
  LIGHTMAPBUFFERSIZE = LIGHTMAPSIZEX * LIGHTMAPSIZEY * LIGHTMAPSIZEZ * 4;

implementation

end.
