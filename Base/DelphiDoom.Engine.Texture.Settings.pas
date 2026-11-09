//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - settings of the external textures
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

unit DelphiDoom.Engine.Texture.Settings;

interface

type
  /// <summary>
  ///   The options of the external textures that the configuration file sets (they were the
  ///   variables of t_png). The class has no instances: the table of the defaults and the menus
  ///   take the address of each field, the decoders and the texture files read them
  /// </summary>
  TEngineTextureSettings = class
  public
    /// <summary>
    ///   Color (in the byte order of a Windows COLORREF) that the PNG textures treat as
    ///   transparent, besides the one of the tRNS chunk
    /// </summary>
    class var PngTransparentColor: Integer;
    /// <summary>The second color that the PNG textures treat as transparent</summary>
    class var PngTransparentColor2: Integer;
    /// <summary>
    ///   Also treat as transparent the colors made only of 00 and FF bytes with at least two
    ///   FF (magenta, cyan, yellow, white...)
    /// </summary>
    class var AssumeCommonTransparentColors: Boolean;
    /// <summary>Look for the external textures in the game folders first (else in TEXTURES\)</summary>
    class var PreferGameDirectory: Boolean;
    class constructor Create;
  end;

implementation

{ TEngineTextureSettings }

class constructor TEngineTextureSettings.Create;
begin
  PngTransparentColor := $FF00FF;
  PngTransparentColor2 := $FFFF;
  AssumeCommonTransparentColors := True;
  PreferGameDirectory := False;
end;

end.