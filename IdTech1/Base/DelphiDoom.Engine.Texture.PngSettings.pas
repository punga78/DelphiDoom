//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - transparent colors of the PNG textures
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

unit DelphiDoom.Engine.Texture.PngSettings;

interface

uses
  DelphiDoom.Texture.Intf;

type
  /// <summary>
  ///   The settings of the game (PngTransparentColor, PngTransparentColor2 and
  ///   AssumeCommonTransparentColors of TEngineTextureSettings, set by the configuration file) read when
  ///   a PNG is decoded
  /// </summary>
  TEngineTexturePngSettings = class(TInterfacedObject, ITexturePngSettings)
  public
    function GetTransparentColor: Cardinal;
    function GetTransparentColor2: Cardinal;
    function GetAssumeCommonColors: Boolean;
  end;

implementation

uses
  DelphiDoom.Engine.Texture.Settings;

{ TEngineTexturePngSettings }

function TEngineTexturePngSettings.GetTransparentColor: Cardinal;
begin
  Result := Cardinal(TEngineTextureSettings.PngTransparentColor);
end;

function TEngineTexturePngSettings.GetTransparentColor2: Cardinal;
begin
  Result := Cardinal(TEngineTextureSettings.PngTransparentColor2);
end;

function TEngineTexturePngSettings.GetAssumeCommonColors: Boolean;
begin
  Result := TEngineTextureSettings.AssumeCommonTransparentColors;
end;

end.
