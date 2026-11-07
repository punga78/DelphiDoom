//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - JPEG files for the texture decoders
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

unit DelphiDoom.Engine.Texture.JpegConverter;

interface

uses
  System.SysUtils,
  DelphiDoom.Texture.Intf;

type
  /// <summary>
  ///   Decodes a JPEG with the JPEG library of the engine (TJpegProvider) and writes it as a
  ///   BMP file. A file that cannot be decoded stops the game with an error, as it always did
  /// </summary>
  TEngineTextureJpegConverter = class(TInterfacedObject, ITextureJpegConverter)
  public
    function ToBitmap(const ASource: TBytes): TBytes;
  end;

implementation

uses
  i_system,
  DelphiDoom.Texture.Types,
  DelphiDoom.Jpeg.Intf,
  DelphiDoom.Jpeg.Client,
  DelphiDoom.Jpeg.Provider,
  DelphiDoom.Texture.JpegBitmap;

{ TEngineTextureJpegConverter }

function TEngineTextureJpegConverter.ToBitmap(const ASource: TBytes): TBytes;
var
  LImage: TJpegImage;
begin
  Result := nil;
  if Length(ASource) = 0 then
    Exit;
  try
    LImage := TJpegProvider.Client.Decode(@ASource[0], Length(ASource));
    Result := TJpegBitmapBuilder.Build(LImage);
  except
    on E: EJpegException do
    begin
      I_Error('TJPGTextureManager(): %s', [E.Message]);
      raise ETextureException.Create(E.Message);
    end;
  end;
end;

end.
