//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - external textures by name for the materials
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

unit DelphiDoom.Engine.Texture.Resolver;

interface

uses
  DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf;

type
  /// <summary>
  ///   Finds the external textures that a material names, in the folders and the PAK files of the
  ///   game (T_LoadHiResImage of t_main)
  /// </summary>
  TEngineTextureResolver = class(TInterfacedObject, ITextureResolver)
  public
    function Load(const AName: string): TTextureImage;
  end;

implementation

uses
  t_main;

{ TEngineTextureResolver }

function TEngineTextureResolver.Load(const AName: string): TTextureImage;
begin
  Result := T_LoadHiResImage(AName);
end;

end.
