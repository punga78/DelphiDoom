{******************************************************************************}
{                                                                              }
{  DelphiDoom: texture definitions library - the types of the model            }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TextureDefs.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>The longest name of a texture, of a patch and of a flat (a lump name)</summary>
  TEXTUREDEFS_NAME_LENGTH = 8;

  /// <summary>Codes of the size of a flat (the old FS64x64 .. FS4096x4096)</summary>
  FLAT_SIZE_64 = 0;
  FLAT_SIZE_128 = 1;
  FLAT_SIZE_256 = 2;
  FLAT_SIZE_512 = 3;
  FLAT_SIZE_1024 = 4;
  FLAT_SIZE_2048 = 5;
  FLAT_SIZE_4096 = 6;

type
  /// <summary>Records of the lumps TEXTUREx and PNAMES, as they are on disk (little endian)</summary>
  TTextureDefsMapPatchStandard = packed record
    OriginX: SmallInt;
    OriginY: SmallInt;
    PatchIndex: SmallInt;
    StepDir: SmallInt; // unused
    ColorMap: SmallInt; // unused
  end;

  /// <summary>The patch of the textures of Strife: no StepDir and no ColorMap</summary>
  TTextureDefsMapPatchStrife = packed record
    OriginX: SmallInt;
    OriginY: SmallInt;
    PatchIndex: SmallInt;
  end;

  /// <summary>The header of a texture of Doom, Heretic and Hexen; the patches follow it</summary>
  TTextureDefsMapTextureStandard = packed record
    Name: array[0..TEXTUREDEFS_NAME_LENGTH - 1] of AnsiChar;
    Masked: Integer;
    Width: SmallInt;
    Height: SmallInt;
    Filler: LongWord; // unused
    PatchCount: SmallInt;
  end;

  /// <summary>The header of a texture of Strife: it has no column directory</summary>
  TTextureDefsMapTextureStrife = packed record
    Name: array[0..TEXTUREDEFS_NAME_LENGTH - 1] of AnsiChar;
    Masked: Integer;
    Width: SmallInt;
    Height: SmallInt;
    PatchCount: SmallInt;
  end;

  /// <summary>Which layout the lumps TEXTUREx have</summary>
  TTextureDefsFormat = (
    /// <summary>Doom, Heretic and Hexen: header of 22 bytes, patches of 10</summary>
    Standard,
    /// <summary>Strife: header of 18 bytes, patches of 6</summary>
    Strife);

  /// <summary>Where a texture was defined: the lump TEXTURE1, TEXTURE2, TEXTURE3 or TEXTURE0 (made from a PK3)</summary>
  TTextureDefsOrigin = (Texture1, Texture2, Texture3, Pk3);

  /// <summary>A piece of a texture: the patch is looked for by name, in the lumps of the game</summary>
  TTextureDefsPatch = record
    OriginX: SmallInt;
    OriginY: SmallInt;
    /// <summary>The index in PNAMES that the lump said; -1 for a texture from a PK3, that has no PNAMES</summary>
    PatchIndex: Integer;
    /// <summary>Upper case; for PNAMES the spaces around it are cut; for a PK3 it is the name of the texture</summary>
    PatchName: string;
  end;

  /// <summary>A wall texture: the patches are drawn in this order, one over the other</summary>
  TTextureDefsTexture = record
    /// <summary>Upper case, 1 to 8 characters</summary>
    Name: string;
    Masked: Integer;
    Width: SmallInt;
    Height: SmallInt;
    Origin: TTextureDefsOrigin;
    Patches: TArray<TTextureDefsPatch>;
  end;

  /// <summary>All the textures, in the order of the engine: TEXTURE1, TEXTURE2, TEXTURE3 and the ones of the PK3</summary>
  TTextureDefsSet = record
    /// <summary>The names of PNAMES, as the textures refer to them</summary>
    PatchNames: TArray<string>;
    Textures: TArray<TTextureDefsTexture>;
  end;

  /// <summary>The size of a flat that FLATINFO says, for the flat of this index</summary>
  TTextureDefsFlatSize = record
    /// <summary>The index in the catalog of the flats, as the catalog gave it</summary>
    FlatIndex: Integer;
    FlatName: string;
    /// <summary>One of the FLAT_SIZE_xxx</summary>
    SizeCode: Integer;
  end;

  /// <summary>What was wrong in a lump</summary>
  TTextureDefsError = (
    MissingLump,
    TruncatedLump,
    BadDirectory,
    BadPatchIndex);

  ETextureDefsException = class(Exception)
  strict private
    FCode: TTextureDefsError;
  public
    constructor Create(ACode: TTextureDefsError; const AMessage: string);
    property Code: TTextureDefsError read FCode;
  end;

const
  /// <summary>Sizes of the records: the tests check them, they have to be the same at 32 and 64 bit</summary>
  TEXTUREDEFS_PATCH_SIZE_STANDARD = 10;
  TEXTUREDEFS_PATCH_SIZE_STRIFE = 6;
  TEXTUREDEFS_HEADER_SIZE_STANDARD = 22;
  TEXTUREDEFS_HEADER_SIZE_STRIFE = 18;

implementation

{ ETextureDefsException }

constructor ETextureDefsException.Create(ACode: TTextureDefsError; const AMessage: string);
begin
  inherited Create(AMessage);
  FCode := ACode;
end;

end.
