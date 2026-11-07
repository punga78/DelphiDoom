//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - what the renderers ask of the external textures
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

unit DelphiDoom.Engine.Texture.Intf;

interface

uses
  d_delphi,
  DelphiDoom.Texture.Image,
  DelphiDoom.Engine.Texture.Item;

type
  /// <summary>
  ///   The external textures (hi-resolution textures and sprites) of the folders and of the PAK
  ///   file system, read with the decoders of Libs\Texture (the old T_LoadHiResTexture and
  ///   T_IsTextureExtension of t_main)
  /// </summary>
  IEngineTextureFiles = interface
    ['{5F1C9A2E-7D34-4B86-A0E3-C82B16F9D457}']
    /// <summary>
    ///   The first file named AFileName plus the extension of a decoder (in the order of the
    ///   decoders) that is found and decoded; nil if none. The caller owns the image
    /// </summary>
    function LoadImage(const AFileName: string; ASilent: Boolean = False): TTextureImage;
    /// <summary>LoadImage in a new texture (New(PTexture, Create)); nil if none</summary>
    function LoadTexture(const AFileName: string; ASilent: Boolean = False): PTexture;
    /// <summary>
    ///   Decodes AStream with the decoder of the extension of AAlias ('.PNG' ...) into ATexture,
    ///   whose image is replaced also when it fails (TTexture.LoadFromStream of the old code)
    /// </summary>
    function Decode(const AStream: TDStream; const AAlias: string; ATexture: PTexture): Boolean;
    /// <summary>True for the extensions of the decoders ('.PNG', '.BMP'...)</summary>
    function IsTextureExtension(const AExtension: string): Boolean;
  end;

implementation

end.
