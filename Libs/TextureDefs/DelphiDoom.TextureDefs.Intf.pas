{******************************************************************************}
{                                                                              }
{  DelphiDoom: texture definitions library - contracts                         }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TextureDefs.Intf;

interface

uses
  System.SysUtils, DelphiDoom.TextureDefs.Types;

type
  /// <summary>Where the bytes of a lump come from: the engine gives the lump that wins (the last one with that name)</summary>
  ITextureDefsLumpSource = interface
    ['{5B2E8C71-3F40-4A9D-B6E5-1D7C94A02F38}']
    /// <summary>False if no lump has this name</summary>
    function TryReadLump(const AName: string; out ABytes: TBytes): Boolean;
  end;

  /// <summary>The flats that the engine knows, to give a size to one of them</summary>
  ITextureDefsFlatCatalog = interface
    ['{C4A71E09-8D52-4B63-9F1A-60E3B5D87C24}']
    /// <summary>The index of the last flat with this name (upper case), -1 if there is none</summary>
    function LastIndexOf(const AUpperName: string): Integer;
  end;

  /// <summary>PNAMES: the names of the patches, in the order that the textures refer to</summary>
  ITextureDefsPatchNamesReader = interface
    ['{91D3F6A8-2E5B-4C07-A8D4-3B6E1F90C752}']
    /// <summary>Upper case names, the spaces around them cut</summary>
    function Read(const ABytes: TBytes): TArray<string>;
  end;

  /// <summary>One lump TEXTURE1, TEXTURE2 or TEXTURE3</summary>
  ITextureDefsTextureLumpReader = interface
    ['{2F8A5D13-B7C9-4E64-8A02-D51C73E96B40}']
    function Read(const ABytes: TBytes; AOrigin: TTextureDefsOrigin;
      const APatchNames: TArray<string>): TArray<TTextureDefsTexture>;
  end;

  /// <summary>TEXTURE0: the textures that the engine made from the pictures of a PK3, one patch each</summary>
  ITextureDefsPk3Reader = interface
    ['{E60B94C2-5A18-4D73-B3F7-8C2D01A5E964}']
    function Read(const ABytes: TBytes): TArray<TTextureDefsTexture>;
  end;

  /// <summary>The text of FLATINFO: it gives a size to some flats</summary>
  ITextureDefsFlatInfoParser = interface
    ['{7D15C8E3-F092-4B5A-86C1-A4E9370D2B68}']
    /// <summary>In the order of the text; a flat named twice appears twice and the last one wins</summary>
    function Parse(const AText: string; const ACatalog: ITextureDefsFlatCatalog): TArray<TTextureDefsFlatSize>;
  end;

  /// <summary>PNAMES and the lumps TEXTUREx of the game, as one model</summary>
  ITextureDefsLoader = interface
    ['{A3E4710B-9C56-4D28-B1F8-52D6C0E83A97}']
    /// <summary>
    ///   PNAMES and TEXTURE1 are needed, TEXTURE2 and TEXTURE3 are read if they exist. With
    ///   AIncludePk3 the textures of TEXTURE0 follow (the engine knows if it made them)
    /// </summary>
    /// <exception cref="ETextureDefsException">A lump is missing or wrong</exception>
    function Load(AIncludePk3: Boolean): TTextureDefsSet;
  end;

implementation

end.
