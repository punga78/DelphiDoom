//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the palette color nearest to a voxel color
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

unit DelphiDoom.Engine.Voxel.ColorMapper;

interface

uses
  DelphiDoom.Voxel.Intf,
  DelphiDoom.Engine.Video.Screens.Intf;

type
  /// <summary>
  ///   The color of the palette of the game that is the nearest to a voxel color (the old
  ///   V_FindAproxColorIndex on default_palette); it runs once for each pixel of a sprite at start
  /// </summary>
  TEngineVoxelColorMapper = class(TInterfacedObject, IVoxelColorMapper)
  strict private
    FScreens: IEngineScreens;
  public
    /// <remarks>Raises EArgumentNilException if AScreens is nil</remarks>
    constructor Create(const AScreens: IEngineScreens);
    function PaletteIndex(const AColor: Cardinal): Byte;
  end;

implementation

uses
  System.SysUtils;

{ TEngineVoxelColorMapper }

constructor TEngineVoxelColorMapper.Create(const AScreens: IEngineScreens);
begin
  inherited Create;
  if not Assigned(AScreens) then
    raise EArgumentNilException.Create('AScreens');
  FScreens := AScreens;
end;

function TEngineVoxelColorMapper.PaletteIndex(const AColor: Cardinal): Byte;
begin
  Result := FScreens.NearestColorInDefaultPalette(AColor);
end;

end.