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
  DelphiDoom.Texture.Intf,
  DelphiDoom.Engine.Shutdown.Intf;

type
  /// <summary>
  ///   Decodes a JPEG with the JPEG library of the engine (TJpegProvider) and writes it as a
  ///   BMP file. A file that cannot be decoded stops the game with an error, as it always did
  /// </summary>
  TEngineTextureJpegConverter = class(TInterfacedObject, ITextureJpegConverter)
  strict private
    FShutdown: IEngineShutdown;
  public
    /// <param name="AShutdown">Stops the game on a file that can not be decoded (I_Error)</param>
    /// <remarks>Raises EArgumentNilException if AShutdown is nil</remarks>
    constructor Create(const AShutdown: IEngineShutdown);
    function ToBitmap(const ASource: TBytes): TBytes;
  end;

implementation

uses
  DelphiDoom.Texture.Types,
  DelphiDoom.Jpeg.Intf,
  DelphiDoom.Jpeg.Client,
  DelphiDoom.Jpeg.Provider,
  DelphiDoom.Texture.JpegBitmap;

{ TEngineTextureJpegConverter }

constructor TEngineTextureJpegConverter.Create(const AShutdown: IEngineShutdown);
begin
  inherited Create;
  if not Assigned(AShutdown) then
    raise EArgumentNilException.Create('AShutdown');
  FShutdown := AShutdown;
end;

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
      FShutdown.Fail('TJPGTextureManager(): ' + E.Message);
      raise ETextureException.Create(E.Message);
    end;
  end;
end;

end.
