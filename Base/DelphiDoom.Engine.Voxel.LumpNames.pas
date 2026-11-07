//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the names of the lumps for the voxel sprites
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

unit DelphiDoom.Engine.Voxel.LumpNames;

interface

uses
  DelphiDoom.Voxel.Intf;

type
  /// <summary>The lumps of the WAD directory of the engine (w_wad), asked at each call</summary>
  TEngineVoxelLumpNames = class(TInterfacedObject, IVoxelLumpNames)
  public
    function LumpCount: Integer;
    function LumpName(const AIndex: Integer): string;
  end;

implementation

uses
  d_delphi,
  w_wad;

{ TEngineVoxelLumpNames }

function TEngineVoxelLumpNames.LumpCount: Integer;
begin
  Result := W_NumLumps;
end;

function TEngineVoxelLumpNames.LumpName(const AIndex: Integer): string;
begin
  Result := char8tostring(W_GetNameForNum(AIndex));
end;

end.
