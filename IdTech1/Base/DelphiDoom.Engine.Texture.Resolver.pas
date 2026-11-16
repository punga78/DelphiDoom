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
  DelphiDoom.Texture.Intf,
  DelphiDoom.Engine.Texture.Intf;

type
  /// <summary>
  ///   Finds the external textures that a material names, in the folders and the PAK files of the
  ///   game (T_LoadHiResImage of t_main). The decoders need the resolver and the files need the
  ///   decoders: the files are attached after both are made, and the reference is weak so that the
  ///   two do not keep each other alive
  /// </summary>
  TEngineTextureResolver = class(TInterfacedObject, ITextureResolver)
  strict private
    [weak] FFiles: IEngineTextureFiles;
  public
    /// <summary>The files that Load reads (the composition root gives them)</summary>
    procedure Attach(const AFiles: IEngineTextureFiles);
    /// <summary>The image of AName, or nil (also before Attach)</summary>
    function Load(const AName: string): TTextureImage;
  end;

implementation

{ TEngineTextureResolver }

procedure TEngineTextureResolver.Attach(const AFiles: IEngineTextureFiles);
begin
  FFiles := AFiles;
end;

function TEngineTextureResolver.Load(const AName: string): TTextureImage;
begin
  if Assigned(FFiles) then
    Result := FFiles.LoadImage(AName)
  else
    Result := nil;
end;

end.
