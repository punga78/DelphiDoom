//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - palette of the game for the texture decoders
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

unit DelphiDoom.Engine.Texture.PaletteSource;

interface

uses
  DelphiDoom.Texture.Types,
  DelphiDoom.Texture.Intf;

type
  /// <summary>
  ///   The palette that the patches and the flats are read with: default_palette of the video
  ///   unit, as it is when the decoder asks (it is created after the start of the game).
  ///   Without it (not loaded yet) every color is black
  /// </summary>
  TEngineTexturePaletteSource = class(TInterfacedObject, ITexturePaletteSource)
  public
    function GetColors: TTexturePixels;
  end;

implementation

uses
  v_video;

{ TEngineTexturePaletteSource }

function TEngineTexturePaletteSource.GetColors: TTexturePixels;
var
  LIndex: Integer;
begin
  SetLength(Result, TEXTURE_PALETTE_SIZE);
  for LIndex := 0 to TEXTURE_PALETTE_SIZE - 1 do
    if default_palette <> nil then
      Result[LIndex] := default_palette[LIndex]
    else
      Result[LIndex] := 0;
end;

end.
