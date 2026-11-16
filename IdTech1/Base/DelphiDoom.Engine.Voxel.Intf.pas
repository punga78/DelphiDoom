//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the voxel services that the renderers ask for
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

unit DelphiDoom.Engine.Voxel.Intf;

interface

type
  /// <summary>
  ///   Makes the sprites of the voxels that have no patch in the WADs: a WAD with a sprite for
  ///   each of them, written in DATA\TMP and loaded at runtime (the old VX_VoxelToSprite)
  /// </summary>
  IEngineVoxelSprites = interface
    ['{C3E81A27-5F40-4B9D-A6E2-0D7B94F13C58}']
    procedure Generate;
  end;

implementation

end.
