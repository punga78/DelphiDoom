//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - PNG files for the texture decoders
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

unit DelphiDoom.Engine.Texture.PngReader;

interface

uses
  System.SysUtils,
  DelphiDoom.Texture.Intf;

type
  /// <summary>
  ///   Reads a PNG file with the PNG library of the engine (TPngProvider). A file with a palette
  ///   is read as indices and palette, the others as BGRA pixels
  /// </summary>
  TEngineTexturePngReader = class(TInterfacedObject, ITexturePngReader)
  public
    function Read(const ASource: TBytes; out AData: TTexturePngData; out AMessage: string): Boolean;
  end;

implementation

uses
  DelphiDoom.Png.Intf,
  DelphiDoom.Png.Client,
  DelphiDoom.Png.Provider;

{ TEngineTexturePngReader }

function TEngineTexturePngReader.Read(const ASource: TBytes; out AData: TTexturePngData;
  out AMessage: string): Boolean;
var
  LInfo: TPngInfo;
  LImage: TPngImage;
  LIndexed: TPngIndexedImage;
begin
  Result := False;
  AData := Default(TTexturePngData);
  AMessage := '';
  try
    LInfo := TPngProvider.Client.GetInfo(ASource);
    if LInfo.ColorType = DDPNG_COLOR_PALETTE then
    begin
      LIndexed := TPngProvider.Client.DecodeIndexed(ASource);
      LInfo := LIndexed.Info;
      AData.Indexed := True;
      AData.Pixels := LIndexed.Pixels;
      AData.Palette := LIndexed.Palette;
    end
    else
    begin
      LImage := TPngProvider.Client.Decode(ASource);
      LInfo := LImage.Info;
      AData.Pixels := LImage.Pixels;
    end;
  except
    on E: EPngException do
    begin
      AMessage := E.Message;
      Exit;
    end;
  end;
  AData.Width := LInfo.Width;
  AData.Height := LInfo.Height;
  AData.HasAlphaChannel := (LInfo.ColorType = DDPNG_COLOR_RGBA) or
                           (LInfo.ColorType = DDPNG_COLOR_GRAY_ALPHA);
  AData.HasPaletteAlpha := LInfo.HasAlpha <> 0;
  AData.HasTransparentColor := LInfo.HasTransparentColor <> 0;
  AData.TransparentColor := LInfo.TransparentColor;
  AData.OffsetX := LInfo.OffsetX;
  AData.OffsetY := LInfo.OffsetY;
  Result := True;
end;

end.
