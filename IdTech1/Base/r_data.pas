//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Refresh module, data I/O, caching, retrieval of graphics
//  by name.
//  Preparation of data for rendering,
//  generation of lookups, caching, retrieval by name.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_data;

interface

uses
  d_delphi,
  m_fixed,
  r_defs,
  w_wad,
  DelphiDoom.TextureDefs.Intf,
  DelphiDoom.Imaging.Intf,
  DelphiDoom.Palette.Intf,
  DelphiDoom.Engine.Palette.Intf,
  DelphiDoom.Engine.Voxel.Intf,
  DelphiDoom.MathCore.Intf,
  DelphiDoom.Pak.Intf,
  DelphiDoom.Renderer.Types,
  DelphiDoom.Renderer.Intf;

// Retrieve column data for span blitting.
{$IFNDEF OPENGL}

{$ENDIF}

{$IFNDEF OPENGL}

//==============================================================================
// R_GetDSs
//
// Retrieve ds_sources
//
//==============================================================================
procedure R_GetDSs(const flat: integer);
{$ENDIF}

//==============================================================================
//
// R_GetLumpForFlat
//
//==============================================================================
function R_GetLumpForFlat(const flat: integer): integer;

{$IFNDEF OPENGL}

//==============================================================================
// R_GetDCs
//
// Retrieve dc_sources
//
//==============================================================================
procedure R_GetDCs(const tex: integer; const col: integer);
{$ENDIF}

//==============================================================================
// R_InitData
//
// I/O, setting up the stuff.
//
//==============================================================================
procedure R_InitData;

//==============================================================================
//
// R_ConfigureTextureDefs
//
//==============================================================================
procedure R_ConfigureTextureDefs(const ALoader: ITextureDefsLoader);

//==============================================================================
//
// R_ConfigureFlatInfo
// The parser of FLATINFO, the catalog of the flats and the PAK file system
// (FLATINFO files), given by the composition root
//
//==============================================================================
procedure R_ConfigureFlatInfo(const AParser: ITextureDefsFlatInfoParser; const ACatalog: ITextureDefsFlatCatalog;
  const APakFiles: IPakFileSystem);

//==============================================================================
//
// R_ConfigureColormaps
//
//==============================================================================
procedure R_ConfigureColormaps(const AMatcher: IColorMatcher; const APreparer: IColormapPreparer;
  const APalette: IEngineDefaultPalette);

//==============================================================================
//
// R_ConfigureComposite
//
//==============================================================================
procedure R_ConfigureComposite(const APainter: IImagingColumnPainter;
  const ARebuilder: IImagingColumnRebuilder);

//==============================================================================
//
// R_ConfigureVoxelSprites
// The maker of the sprites of the voxels without a patch (R_InitSpriteLumps)
//
//==============================================================================
procedure R_ConfigureVoxelSprites(const ASprites: IEngineVoxelSprites);

//==============================================================================
//
// R_ConfigureNameHash
//
//==============================================================================
procedure R_ConfigureNameHash(const ATable: IStringHashTable);

//==============================================================================
//
// R_ConfigureTextureLookup
// The builder of the column tables of the textures (R_GenerateLookup)
//
//==============================================================================
procedure R_ConfigureTextureLookup(const ALookup: IRendererTextureLookup);

//==============================================================================
//
// R_ConfigureLumpRanges
// The finder of the ranges of the flats and of the sprites and the reader of the
// sprite headers (R_InitFlats, R_InitSpriteLumps)
//
//==============================================================================
procedure R_ConfigureLumpRanges(const ARanges: IRendererLumpRanges;
  const ASpriteTable: IRendererSpriteTableBuilder);

//==============================================================================
//
// R_ConfigurePrecache
// The planner of what a level uses (R_PrecacheLevel) and the rules of the game for the
// textures of the sides
//
//==============================================================================
procedure R_ConfigurePrecache(const APlanner: IRendererPrecachePlanner;
  const AProfile: TRendererProfile);

//==============================================================================
//
// R_FreeMemory
//
//==============================================================================
procedure R_FreeMemory;

//==============================================================================
//
// R_PrecacheLevel
//
//==============================================================================
procedure R_PrecacheLevel;

//==============================================================================
// R_FlatNumForName
//
// Retrieval.
// Floor/ceiling opaque texture tiles,
// lookup by name. For animation?
//
//==============================================================================
function R_FlatNumForName(const name: string): integer;

//==============================================================================
//
// R_SafeFlatNumForName
//
//==============================================================================
function R_SafeFlatNumForName(const name: string): integer;

//==============================================================================
//
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
// R_NewFlatNumForLump
//
//==============================================================================
function R_NewFlatNumForLump(const lump: integer): integer;

//==============================================================================
//
{$ENDIF}
// R_CacheFlat
//
//==============================================================================

//==============================================================================
// R_CheckTextureNumForName
//
// Called by P_Ticker for switches and animations,
// returns the texture number for the texture name.
//
//==============================================================================
function R_CheckTextureNumForName(const name: string): integer;

//==============================================================================
//
// R_SafeTextureNumForName
//
//==============================================================================
function R_SafeTextureNumForName(const name: string): integer;

//==============================================================================
//
// R_NameForSideTexture
//
//==============================================================================
function R_NameForSideTexture(const sn: SmallInt): char8_t;

//==============================================================================
//
// R_TextureNumForName
//
//==============================================================================
function R_TextureNumForName(const name: string): integer;

var
// for global animation
  texturetranslation: PIntegerArray;

// needed for texture pegging
  textureheight: Pfixed_tArray;
// JVAL: 20200112 - For tall textures
  texturecolumnheight: PIntegerArray;
  texturecolumnheightfrac: PIntegerArray;
  texturecompositesize: PIntegerArray;

  firstspritelump: integer;
  lastspritelump: integer;

// needed for pre rendering
  spritewidth: Pfixed_tArray;
  spriteoffset: Pfixed_tArray;
  spritetopoffset: Pfixed_tArray;
  spritepresent: PBooleanArray;

{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  def_colormaps: PByteArray;
{$ENDIF}
  fog_colormaps: PByteArray;  // JVAL: Mars fog sectors
  colormaps: PByteArray;
  colormaps32: PLongWordArray;
  fog_colormaps32: PLongWordArray;  // JVAL: Mars fog sectors
{$IFDEF DOOM}
  inversecolormap32: array[0..255] of LongWord;
{$ENDIF}

var
  firstflat: integer;
  lastflat: integer;
  numflats: integer;
  maxvisplane: integer = -1;

//==============================================================================
//
// R_SetupLevel
//
//==============================================================================
procedure R_SetupLevel;

var
  numtextures: integer;
  textures: Ptexture_tPArray;
  flats: PflatPArray;
{$IF DEFINED(HERETIC)}
  aprox_black: byte = 254;
  aprox_red: byte = 160;
{$ELSEIF DEFINED(HEXEN)}
  aprox_black: byte = 186;
  aprox_red: byte = 181;
  LevelUseFog: boolean;
  fogmaplump: integer = -1;
  colormaplump: integer = -1;

var
  enableflatscrolling: boolean;

//==============================================================================
//
// R_ChangeColormap
//
//==============================================================================
procedure R_ChangeColormap(const lumpname: string);
{$ELSEIF DEFINED(STRIFE)}
  aprox_black: byte = 239;
  aprox_red: byte = 234;
{$ELSE}
  aprox_black: byte = 247;
  aprox_red: byte = 176;
{$ENDIF}

type
  /// <summary>
  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #247,
  ///   wave 12): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TRendererData = class sealed
  public
{$IFNDEF OPENGL}
    //==============================================================================
    //
    // R_GetColumn
    //
    //==============================================================================
    class function R_GetColumn(const tex: integer; col: integer): PByteArray; static;
{$ENDIF}
  end;


implementation

uses
  DelphiDoom.Renderer.Profiles,
  DelphiDoom.TextureDefs.Types,
  DelphiDoom.Imaging.Types,
  DelphiDoom.Palette.Types,
  DelphiDoom.Definitions.Types,
  DelphiDoom.Definitions.TerrainTables,
{$IFDEF FPC}
  d_fpc,
{$ENDIF}
  d_think,
{$IFDEF STRIFE}
  d_check,
{$ENDIF}
  i_system,
  p_setup,
  p_tick,
  p_mobj_h,
  p_mobj,
  p_local,
{$IFDEF HEXEN}
  p_anim,
{$ENDIF}
  r_sky,
  r_things,
  r_bsp,
  r_hires,
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  r_colormaps,
{$ENDIF}
  r_pk3textures,
{$IFNDEF OPENGL}
  r_column,
  r_tallcolumn,
  r_span,
  r_cache_walls,
  r_cache_flats,
{$IFNDEF STRIFE}
  r_col_fz,
{$ENDIF}
  r_3dfloors, // JVAL: 3d Floors
  r_slopes, // JVAL: Slopes
  r_patch,
{$ENDIF}
  r_flatinfo,
{$IFDEF HEXEN}
  r_main,
{$ENDIF}
  v_data,
  v_video,
  w_sprite,
  z_zone;

var
  voxel_sprites: IEngineVoxelSprites = nil;
  color_matcher: IColorMatcher = nil;
  colormap_preparer: IColormapPreparer = nil;
  default_palette: IEngineDefaultPalette = nil;
  texturedefs_loader: ITextureDefsLoader;
  flatinfo_parser: ITextureDefsFlatInfoParser = nil;
  flatinfo_catalog: ITextureDefsFlatCatalog = nil;
  flatinfo_pakfiles: IPakFileSystem = nil;
  composite_painter: IImagingColumnPainter = nil;
  composite_rebuilder: IImagingColumnRebuilder = nil;
  texture_lookup: IRendererTextureLookup = nil;
  lump_ranges: IRendererLumpRanges = nil;
  sprite_table_builder: IRendererSpriteTableBuilder = nil;
  precache_planner: IRendererPrecachePlanner = nil;
  renderer_profile: TRendererProfile;
  // the last index found for a name of a flat or of a texture (one table for both, as the
  // old global hash of m_hash): every answer is checked against flats[] or textures[]
  name_hash: IStringHashTable = nil;

//==============================================================================
//
// R_ConfigureNameHash
// The hash table of the names of Framework\MathCore, given by the composition root
//
//==============================================================================
procedure R_ConfigureNameHash(const ATable: IStringHashTable);
begin
  name_hash := ATable;
end;

//==============================================================================
//
// R_ConfigureTextureLookup
// The builder of the column tables of IdTech1\Renderer, given by the composition root
//
//==============================================================================
procedure R_ConfigureTextureLookup(const ALookup: IRendererTextureLookup);
begin
  texture_lookup := ALookup;
end;

//==============================================================================
//
// R_ConfigureLumpRanges
// The finder of the ranges of the flats and of the sprites and the reader of the
// sprite headers, given by the composition root
//
//==============================================================================
procedure R_ConfigureLumpRanges(const ARanges: IRendererLumpRanges;
  const ASpriteTable: IRendererSpriteTableBuilder);
begin
  lump_ranges := ARanges;
  sprite_table_builder := ASpriteTable;
end;

//==============================================================================
//
// R_ConfigurePrecache
// The planner of what a level uses and the rules of the game, given by the composition root
//
//==============================================================================
procedure R_ConfigurePrecache(const APlanner: IRendererPrecachePlanner;
  const AProfile: TRendererProfile);
begin
  precache_planner := APlanner;
  renderer_profile := AProfile;
end;

//==============================================================================
//
// R_RendererProfile
//
//==============================================================================
function R_RendererProfile: TRendererProfile;
begin
  if precache_planner = nil then
    I_Error('R_RendererProfile(): R_ConfigurePrecache() was not called');
  Result := renderer_profile;
end;

//==============================================================================
//
// R_NameHash
//
//==============================================================================
function R_NameHash: IStringHashTable;
begin
  if not Assigned(name_hash) then
    I_Error('R_NameHash(): R_ConfigureNameHash() was not called');
  result := name_hash;
end;

//==============================================================================
//
// R_ConfigureColormaps
// The color matcher and the colormap preparer of Framework\Palette, given by the
// composition root
//
//==============================================================================
procedure R_ConfigureColormaps(const AMatcher: IColorMatcher; const APreparer: IColormapPreparer;
  const APalette: IEngineDefaultPalette);
begin
  color_matcher := AMatcher;
  colormap_preparer := APreparer;
  default_palette := APalette;
end;

//==============================================================================
//
// R_ConfigureComposite
// The painter and the rebuilder of columns of Framework\Imaging, given by the
// composition root
//
//==============================================================================
procedure R_ConfigureComposite(const APainter: IImagingColumnPainter;
  const ARebuilder: IImagingColumnRebuilder);
begin
  composite_painter := APainter;
  composite_rebuilder := ARebuilder;
end;

//==============================================================================
//
// Graphics.
// DOOM graphics for walls and sprites
// is stored in vertical runs of opaque pixels (posts).
// A column is composed of zero or more posts,
// a patch or sprite is composed of zero or more columns.
//
// R_GenerateCompositeInto
// Using the texture definition,
//  the composite texture is created from the patches,
//  and each column is cached.
// The columns are clipped and drawn by the painter and the multipatched
//  ones are rebuilt from the transparency marks by the rebuilder
//
//==============================================================================
procedure R_GenerateCompositeInto(const texnum: integer; block: PByteArray);
var
  texture: Ptexture_t;
  patch: Ptexpatch_t;
  realpatch: Ppatch_t;
  x1: integer;
  x2: integer;
  i: integer;
  cofs: PIntegerArray;
  collump: PSmallIntArray;
  colofs: PIntegerArray;
  twidth: integer;
  theight: integer;
  lumpsize: integer;
  composite: TArray<Byte>;
  patchbytes: TArray<Byte>;
  marks: TArray<Byte>;
begin
  if (composite_painter = nil) or (composite_rebuilder = nil) then
    I_Error('R_GenerateComposite(): the composite builders are not configured (ComposeEngine was not called)');

  texture := textures[texnum];
  twidth := texture.width;
  theight := texture.height;

  SetLength(composite, texturecompositesize[texnum]);
  if texture.patchcount > 1 then
    SetLength(marks, twidth * theight);

  collump := texturecolumnlump[texnum];
  colofs := texturecolumnofs[texnum];

  patch := @(texture.patches[0]);

  try
    // Composite the columns together.
    for i := 0 to texture.patchcount - 1 do
    begin
{$IFDEF DOOM}
      // the same patches that R_GenerateLookup counted: it ignores what is not a patch
      if (patch.patch < 0) or (TWadRoutines.W_LumpFlags(patch.patch) and (TYPE_PATCH or TYPE_SPRITE) = 0) then
      begin
        inc(patch);
        Continue;
      end;
{$ENDIF}
      realpatch := TWadRoutines.W_CacheLumpNum(patch.patch, PU_STATIC);
      lumpsize := TWadRoutines.W_LumpLength(patch.patch);
      SetLength(patchbytes, lumpsize);
      if lumpsize > 0 then
        memcpy(@patchbytes[0], realpatch, lumpsize);
      Z_ChangeTag(realpatch, PU_CACHE);

      x1 := patch.originx;
      x2 := x1 + Ppatch_t(@patchbytes[0]).width;

      cofs := PIntegerArray(NativeInt(@Ppatch_t(@patchbytes[0]).columnofs) - x1 * SizeOf(integer));

      if x1 < 0 then
        x1 := 0;

      if x2 > twidth then
        x2 := twidth;

      while x1 < x2 do
      begin
        // Column does not have multiple patches?
        if collump[x1] < 0 then
          composite_painter.Paint(patchbytes, cofs[x1], composite, colofs[x1], patch.originy,
            theight, marks, x1 * theight);
        inc(x1);
      end;
      inc(patch);
    end;

    if texture.patchcount > 1 then
      for i := 0 to twidth - 1 do
        if collump[i] < 0 then // process only multipatched columns
          composite_rebuilder.Rebuild(composite, colofs[i] - 3, marks, i * theight, theight);
  except
    on E: EImagingException do
      I_Error('R_GenerateComposite(): %s (texture %s, %dx%d, %d patches)', [E.Message, TWadRoutines.char8tostring(texture.name), twidth, theight, texture.patchcount]);
  end;

  if Length(composite) > 0 then
    memcpy(block, @composite[0], Length(composite));
end;

//==============================================================================
//
// R_GenerateComposite
// Using the texture definition,
//  the composite texture is created from the patches,
//  and each column is cached.
//
//==============================================================================
procedure R_GenerateComposite(const texnum: integer);
var
  block: PByteArray;
begin
  block := Z_Malloc(texturecompositesize[texnum], PU_STATIC, @texturecomposite[texnum]);

  R_GenerateCompositeInto(texnum, block);

  // Now that the texture has been built in column cache,
  //  it is purgable from zone memory.
  Z_ChangeTag(block, PU_CACHE);
end;

//==============================================================================
//
// R_GenerateLookup
//
//==============================================================================
procedure R_GenerateLookup(const texnum: integer);
var
  texture: Ptexture_t;
  patch: Ptexpatch_t;
  collump: PSmallIntArray;
  colofs: PIntegerArray;  //PWordArray; // 64k
  info: TRendererTextureInfo;
  lookuplump: TArray<Integer>;
  lookupofs: TArray<Integer>;
  i: integer;
begin
  if texture_lookup = nil then
    I_Error('R_GenerateLookup(): the texture lookup is not configured (ComposeEngine was not called)');

  texture := textures[texnum];

  // Composited texture not created yet.
  texturecomposite[texnum] := nil;

  texturecompositesize[texnum] := 0;
  collump := texturecolumnlump[texnum];
  colofs := texturecolumnofs[texnum];

  // The placement of the patches on the texture
  info.Number := texnum;
  info.Name := TWadRoutines.char8tostring(texture.name);
  info.Width := texture.width;
  info.Height := texture.height;
  SetLength(info.Patches, texture.patchcount);
  patch := @texture.patches[0];
  for i := 0 to texture.patchcount - 1 do
  begin
    info.Patches[i].Lump := patch.patch;
    info.Patches[i].OriginX := patch.originx;
    inc(patch);
  end;

  // The columns that the library does not write keep what they have now
  SetLength(lookuplump, texture.width);
  SetLength(lookupofs, texture.width);
  for i := 0 to texture.width - 1 do
  begin
    lookuplump[i] := collump[i];
    lookupofs[i] := colofs[i];
  end;

  // Now count the number of columns
  //  that are covered by more than one patch.
  // Fill in the lump / offset, so columns
  //  with only a single patch are all done.
  texturecompositesize[texnum] := texture_lookup.Build(info, lookuplump, lookupofs);

  for i := 0 to texture.width - 1 do
  begin
    collump[i] := lookuplump[i];
    colofs[i] := lookupofs[i];
  end;
end;

//
// R_GetColumn
//
{$IFNDEF OPENGL}
type
  blancpost_t = packed record
    topdelta: byte;
    length: byte;
    pad: byte;
    data: byte;
  end;

const
  blancpost: blancpost_t = (
    topdelta: $ff;
    length: 0;
    pad: 0;
    data: 0
  );

//==============================================================================
//
// R_GetColumn
//
//==============================================================================
class function TRendererData.R_GetColumn(const tex: integer; col: integer): PByteArray;
var
  lump: integer;
  ofs: integer;
begin
// JVAL: 20200105 - Texture width is not requiered to be power of 2
  col := col mod texturewidth[tex];
  if col < 0 then
    col := col + texturewidth[tex];
  lump := texturecolumnlump[tex][col];
  ofs := texturecolumnofs[tex][col];

// JVAL: 20200112 - For tall textures
  dc_height := texturecolumnheight[tex];

  if lump = -2 then
  begin
    result := @blancpost.data;
    exit;
  end;

  if lump > 0 then
  begin
    result := R_GetFixedColumn(PByteArray(NativeInt(TWadRoutines.W_CacheLumpNum(lump, PU_LEVEL)) + ofs), tex, col, false);
    exit;
  end;

  if texturecomposite[tex] = nil then
    R_GenerateComposite(tex);

  result := R_GetFixedColumn(PByteArray(NativeInt(texturecomposite[tex]) + ofs), tex, col, true);
end;
{$ENDIF}

{$IFNDEF OPENGL}

//==============================================================================
//
// R_GetDSs
//
//==============================================================================
procedure R_GetDSs(const flat: integer);
var
  lump: integer;
begin
  if videomode = vm8bit then
  begin
    lump := R_GetLumpForFlat(flat);
    ds_source := TWadRoutines.W_CacheLumpNum(lump, PU_STATIC);
    ds_scale := TRendererCacheFlats.R_FlatScaleFromSize(flat, TWadRoutines.W_LumpLength(lump));
    ds_size := flats[flats[flat].translation].size;
  end
  else
    TRendererCacheFlats.R_ReadDS32Cache(flat);
end;
{$ENDIF}

//==============================================================================
//
// R_GetLumpForFlat
//
//==============================================================================
function R_GetLumpForFlat(const flat: integer): integer;
begin
  result := flats[flats[flat].translation].lump;
end;

{$IFNDEF OPENGL}

//==============================================================================
//
// R_GetDCs
//
//==============================================================================
procedure R_GetDCs(const tex: integer; const col: integer);
begin
  if videomode = vm8bit then
    dc_source := TRendererData.R_GetColumn(tex, col)
  else
    TRendererCacheWalls.R_ReadDC32Cache(tex, col);
end;
{$ENDIF}

//==============================================================================
{$IFDEF STRIFE}
// R_InitTexturesOld
{$ENDIF}
//
// R_InitTextures
// Initializes the texture list
//  with the textures from the world map.
{$IFDEF STRIFE}
//
//==============================================================================
procedure R_InitTexturesOld;
var
  mtexture2: Pmaptexture2_t;
  mtexture: Pmaptexture_t;
  texture: Ptexture_t;
  mpatch2: Pmappatch2_t;
  mpatch: Pmappatch_t;
  patch: Ptexpatch_t;
  i: integer;
  j: integer;
  maptex: PIntegerArray;
  maptex0: PIntegerArray;
  maptex1: PIntegerArray;
  maptex2: PIntegerArray;
  maptex3: PIntegerArray;
  name: char8_t;
  names: PByteArray;
  name_p: PByteArray;
  patchlookup: PIntegerArray;
  nummappatches: integer;
  offset: integer;
  maxoff: integer;
  maxoff2: integer;
  maxoff3: integer;
  numtextures0: integer;
  numtextures1: integer;
  numtextures2: integer;
  numtextures3: integer;
  directory: PIntegerArray;
  t2lump: integer;
  t3lump: integer;
  pname: string;
begin
  {$IFNDEF OPENGL}
  R_InitFixedColumn;
  {$ENDIF}
  // Load the patch names from pnames.lmp.
  ZeroMemory(@name, SizeOf(char8_t));
  names := TWadRoutines.W_CacheLumpName('PNAMES', PU_STATIC);
  nummappatches := PInteger(names)^;
  name_p := PByteArray(NativeInt(names) + 4);

  patchlookup := malloc(nummappatches * SizeOf(integer));

  for i := 0 to nummappatches - 1 do
  begin
    j := 0;
    while j < 8 do
    begin
      name[j] := toupper(AnsiChar(name_p[i * 8 + j]));
      if name[j] = #0 then
      begin
        inc(j);
        break;
      end;
      inc(j);
    end;
    while j < 8 do
    begin
      name[j] := #0;
      inc(j);
    end;
    pname := strtrim(TWadRoutines.char8tostring(name));
    patchlookup[i] := TWadRoutines.W_CheckNumForName(pname, TYPE_PATCH or TYPE_SPRITE);
    if patchlookup[i] = -1 then
    begin
      I_DevWarning('R_InitTextures(): Can not find patch "%s" inside patch or sprite markers, retrying...'#13#10, [pname]);
      patchlookup[i] := TWadRoutines.W_CheckNumForName(pname);
      if patchlookup[i] = -1 then
      // JVAL: Display warning only if not teaser
        if teaser = 0 then
          I_Warning('R_InitTextures(): Can not find patch "%s"'#13#10, [pname]);
    end;
  end;
  Z_Free(names);

  // Load the map texture definitions from textures.lmp.
  // The data is contained in one or two lumps,
  //  TEXTURE1 for shareware, plus TEXTURE2 for commercial.
  // JVAL: TEXTURE3 for more textures
  maptex1 := TWadRoutines.W_CacheLumpName('TEXTURE1', PU_STATIC);
  maptex := maptex1;
  numtextures1 := maptex[0];
  maxoff := TWadRoutines.W_LumpLength(TWadRoutines.W_GetNumForName('TEXTURE1'));
  directory := PintegerArray(NativeInt(maptex) + SizeOf(integer));

  t2lump := TWadRoutines.W_CheckNumForName('TEXTURE2');
  if t2lump <> -1 then
  begin
    maptex2 := TWadRoutines.W_CacheLumpNum(t2lump, PU_STATIC);
    numtextures2 := maptex2[0];
    maxoff2 := TWadRoutines.W_LumpLength(t2lump);
  end
  else
  begin
    maptex2 := nil;
    numtextures2 := 0;
    maxoff2 := 0;
  end;

  t3lump := TWadRoutines.W_CheckNumForName('TEXTURE3');
  if t3lump <> -1 then
  begin
    maptex3 := TWadRoutines.W_CacheLumpNum(t3lump, PU_STATIC);
    numtextures3 := maptex3[0];
    maxoff3 := TWadRoutines.W_LumpLength(t3lump);
  end
  else
  begin
    maptex3 := nil;
    numtextures3 := 0;
    maxoff3 := 0;
  end;

  numtextures := numtextures1 + numtextures2 + numtextures3;

  textures := mallocz(numtextures * SizeOf(Ptexture_t));
  texturecolumnlump := mallocz(numtextures * SizeOf(PSmallIntArray));
  texturecolumnofs := mallocz(numtextures * SizeOf(PIntegerArray));
  texturecomposite := mallocz(numtextures * SizeOf(PByteArray));
  texturecompositesize := mallocz(numtextures * SizeOf(integer));
  texturewidth := mallocz(numtextures * SizeOf(integer));
  textureheight := mallocz(numtextures * SizeOf(fixed_t));
// JVAL: 20200112 - For tall textures
  texturecolumnheight := mallocz(numtextures * SizeOf(integer));
  texturecolumnheightfrac := mallocz(numtextures * SizeOf(integer));

  for i := 0 to numtextures - 1 do
  begin
    if i = numtextures1 then
    begin
      // Start looking in second texture file.
      maptex := maptex2;
      maxoff := maxoff2;
      directory := PIntegerArray(NativeInt(maptex) + SizeOf(integer));
    end;
    if i = numtextures1 + numtextures2 then
    begin
      // Start looking in third texture file.
      maptex := maptex3;
      maxoff := maxoff3;
      directory := PIntegerArray(NativeInt(maptex) + SizeOf(integer));
    end;

    offset := directory[0];

    if offset > maxoff then
      I_Error('R_InitTextures(): bad texture directory');

    mtexture2 := Pmaptexture2_t(NativeInt(maptex) + offset);

    textures[i] := malloc(SizeOf(texture_t) + SizeOf(texpatch_t) * (mtexture2.patchcount - 1));
    texture := textures[i];

    texture.width := mtexture2.width;
    texture.height := mtexture2.height;
    texture.patchcount := mtexture2.patchcount;
    {$IFNDEF OPENGL}
    texture.texture32 := nil;
    {$ENDIF}

    j := 0;
    while j < 8 do
    begin
      if mtexture2.name[j] = #0 then
        break;
      texture.name[j] := toupper(mtexture2.name[j]);
      inc(j);
    end;
    while j < 8 do
    begin
      texture.name[j] := #0;
      inc(j);
    end;

    mpatch2 := @mtexture2.patches[0];
    patch := @texture.patches[0];

    for j := 0 to texture.patchcount - 1 do
    begin
      patch.originx := mpatch2.originx;
      patch.originy := mpatch2.originy;
      patch.patch := patchlookup[mpatch2.patch];
      if patch.patch = -1 then
        I_Error('R_InitTextures(): Missing patch in texture %s', [TWadRoutines.char8tostring(texture.name)]);
      inc(mpatch2);
      inc(patch);
    end;
    texturecolumnlump[i] := malloc(texture.width * SizeOf(texturecolumnlump[0][0]));
    texturecolumnofs[i] := malloc(texture.width * SizeOf(texturecolumnofs[0][0]));

    texturewidth[i] := texture.width;
    textureheight[i] := texture.height * FRACUNIT;
    // JVAL: 20200112 - For tall textures
    texturecolumnheight[i] := texture.height;
    if texturecolumnheight[i] < 128 then
      texturecolumnheight[i] := 128;
    texturecolumnheightfrac[i] := texturecolumnheight[i] * FRACUNIT;

    incp(pointer(directory), SizeOf(integer));
  end;

  memfree(pointer(patchlookup), nummappatches * SizeOf(integer));

  Z_Free(maptex1);
  if maptex2 <> nil then
    Z_Free(maptex2);
  if maptex3 <> nil then
    Z_Free(maptex3);

  if R_InitPK3Textures then
  begin
    // Load the map textures directly from PK3
    maptex0 := TWadRoutines.W_CacheLumpName('TEXTURE0', PU_STATIC);
    maptex := maptex0;
    numtextures0 := maptex[0];

    realloc(pointer(textures), numtextures * SizeOf(Ptexture_t), (numtextures0 + numtextures) * SizeOf(Ptexture_t));
    realloc(pointer(texturecolumnlump), numtextures * SizeOf(PSmallIntArray), (numtextures0 + numtextures) * SizeOf(PSmallIntArray));
    realloc(pointer(texturecolumnofs), numtextures * SizeOf(PIntegerArray), (numtextures0 + numtextures) * SizeOf(PIntegerArray));
    realloc(pointer(texturecomposite), numtextures * SizeOf(PByteArray), (numtextures0 + numtextures) * SizeOf(PByteArray));
    realloc(pointer(texturecompositesize), numtextures * SizeOf(integer), (numtextures0 + numtextures) * SizeOf(integer));
    realloc(pointer(texturewidth), numtextures * SizeOf(integer), (numtextures0 + numtextures) * SizeOf(integer));
    realloc(pointer(textureheight), numtextures * SizeOf(fixed_t), (numtextures0 + numtextures) * SizeOf(fixed_t));
    // JVAL: 20200112 - For tall textures
    realloc(pointer(texturecolumnheight), numtextures * SizeOf(integer), (numtextures0 + numtextures) * SizeOf(integer));
    realloc(pointer(texturecolumnheightfrac), numtextures * SizeOf(integer), (numtextures0 + numtextures) * SizeOf(integer));

    mtexture := Pmaptexture_t(NativeInt(maptex) + SizeOf(integer));
    for i := numtextures to numtextures0 + numtextures - 1 do
    begin
      textures[i] := malloc(SizeOf(texture_t) + SizeOf(texpatch_t));
      texture := textures[i];

      texture.width := mtexture.width;
      texture.height := mtexture.height;
      texture.patchcount := 1;
      {$IFNDEF OPENGL}
      texture.texture32 := nil;
      {$ENDIF}

      j := 0;
      while j < 8 do
      begin
        if mtexture.name[j] = #0 then
          break;
        texture.name[j] := toupper(mtexture.name[j]);
        inc(j);
      end;
      while j < 8 do
      begin
        texture.name[j] := #0;
        inc(j);
      end;

      mpatch := @mtexture.patches[0];
      patch := @texture.patches[0];

      patch.originx := mpatch.originx;
      patch.originy := mpatch.originy;
      patch.patch := TWadRoutines.W_CheckNumForName(TWadRoutines.char8tostring(texture.name), TYPE_PATCH);

      texturecolumnlump[i] := malloc(texture.width * SizeOf(texturecolumnlump[0][0]));
      texturecolumnofs[i] := malloc(texture.width * SizeOf(texturecolumnofs[0][0]));

      texturewidth[i] := texture.width;
      textureheight[i] := texture.height * FRACUNIT;
      // JVAL: 20200112 - For tall textures
      texturecolumnheight[i] := texture.height;
      if texturecolumnheight[i] < 128 then
        texturecolumnheight[i] := 128;
      texturecolumnheightfrac[i] := texturecolumnheight[i] * FRACUNIT;

      inc(mtexture);
    end;

    numtextures := numtextures + numtextures0;

    Z_Free(maptex0);
  end;

  // Precalculate whatever possible.
  for i := 0 to numtextures - 1 do
    R_GenerateLookup(i);

  // Create translation table for global animation.
  texturetranslation := malloc((numtextures + 1) * SizeOf(integer));

  for i := 0 to numtextures - 1 do
    texturetranslation[i] := i;
end;

//==============================================================================
//
// R_InitTextures
{$ENDIF}
//
//==============================================================================
procedure R_InitTextures;
var
  texture: Ptexture_t;
  patch: Ptexpatch_t;
  i: integer;
  j: integer;
  patchlookup: PIntegerArray;
  numpatchnames: integer;
  texdefs: TTextureDefsSet;
  texdef: TTextureDefsTexture;
  numtextures0: integer;
  firstpk3: integer;
  pname: string;

  // The tables of the textures: the ones of the textures of the WADs and the ones of the PK3
  procedure _SetTextureTables(const idx: integer; const w, h: integer);
  begin
    texturecolumnlump[idx] := malloc(w * SizeOf(texturecolumnlump[0][0]));
    texturecolumnofs[idx] := malloc(w * SizeOf(texturecolumnofs[0][0]));

    texturewidth[idx] := w;
    textureheight[idx] := h * FRACUNIT;
    // JVAL: 20200112 - For tall textures
    texturecolumnheight[idx] := h;
    if texturecolumnheight[idx] < 128 then
      texturecolumnheight[idx] := 128;
    texturecolumnheightfrac[idx] := texturecolumnheight[idx] * FRACUNIT;
  end;

  procedure _SetTextureName(const tex: Ptexture_t; const aname: string);
  var
    k: integer;
  begin
    k := 0;
    while (k < 8) and (k < Length(aname)) do
    begin
      tex.name[k] := toupper(AnsiChar(aname[k + 1]));
      inc(k);
    end;
    while k < 8 do
    begin
      tex.name[k] := #0;
      inc(k);
    end;
  end;

  function _Load(const withpk3: boolean): TTextureDefsSet;
  begin
    try
      result := texturedefs_loader.Load(withpk3);
    except
      on E: ETextureDefsException do
        if E.Code = TTextureDefsError.BadDirectory then
          I_Error('R_InitTextures(): bad texture directory')
        else
          I_Error('R_InitTextures(): %s', [E.Message]);
    end;
  end;

begin
  if texturedefs_loader = nil then
    I_Error('R_InitTextures(): the texture definitions are not configured (ComposeEngine was not called)');

  {$IFNDEF OPENGL}
  R_InitFixedColumn;
  {$ENDIF}

  // The patch names from PNAMES and the definitions from TEXTURE1, TEXTURE2 and TEXTURE3
  texdefs := _Load(false);

  numpatchnames := Length(texdefs.PatchNames);
  patchlookup := malloc(numpatchnames * SizeOf(integer));

  for i := 0 to numpatchnames - 1 do
  begin
    pname := texdefs.PatchNames[i];
    patchlookup[i] := TWadRoutines.W_CheckNumForName(pname, TYPE_PATCH or TYPE_SPRITE);
    if patchlookup[i] = -1 then
    begin
      I_DevWarning('R_InitTextures(): Can not find patch "%s" inside patch or sprite markers, retrying...'#13#10, [pname]);
      patchlookup[i] := TWadRoutines.W_CheckNumForName(pname);
      if patchlookup[i] = -1 then
{$IFDEF STRIFE}
      // JVAL: Display warning only if not teaser
        if teaser = 0 then
          I_Warning('R_InitTextures(): Can not find patch "%s"'#13#10, [pname]);
{$ELSE}
      begin
        I_Warning('R_InitTextures(): Can not find patch "%s"'#13#10, [pname]);
        patchlookup[i] := TWadRoutines.W_CheckNumForName('NULLA0');
      end;
{$ENDIF}
    end;
  end;

  numtextures := Length(texdefs.Textures);

  textures := mallocz(numtextures * SizeOf(Ptexture_t));
  texturecolumnlump := mallocz(numtextures * SizeOf(PSmallIntArray));
  texturecolumnofs := mallocz(numtextures * SizeOf(PIntegerArray));
  texturecomposite := mallocz(numtextures * SizeOf(PByteArray));
  texturecompositesize := mallocz(numtextures * SizeOf(integer));
  texturewidth := mallocz(numtextures * SizeOf(integer));
  textureheight := mallocz(numtextures * SizeOf(fixed_t));
// JVAL: 20200112 - For tall textures
  texturecolumnheight := mallocz(numtextures * SizeOf(integer));
  texturecolumnheightfrac := mallocz(numtextures * SizeOf(integer));

  for i := 0 to numtextures - 1 do
  begin
    texdef := texdefs.Textures[i];

    textures[i] := malloc(SizeOf(texture_t) + SizeOf(texpatch_t) * (Length(texdef.Patches) - 1));
    texture := textures[i];

    texture.width := texdef.Width;
    texture.height := texdef.Height;
    texture.patchcount := Length(texdef.Patches);
    {$IFNDEF OPENGL}
    texture.texture32 := nil;
    {$ENDIF}
    _SetTextureName(texture, texdef.Name);

    patch := @texture.patches[0];
    for j := 0 to texture.patchcount - 1 do
    begin
      patch.originx := texdef.Patches[j].OriginX;
      patch.originy := texdef.Patches[j].OriginY;
      patch.patch := patchlookup[texdef.Patches[j].PatchIndex];
      if patch.patch = -1 then
        I_Error('R_InitTextures(): Missing patch in texture %s', [TWadRoutines.char8tostring(texture.name)]);
      inc(patch);
    end;

    _SetTextureTables(i, texture.width, texture.height);
  end;

  memfree(pointer(patchlookup), numpatchnames * SizeOf(integer));

  if R_InitPK3Textures then
  begin
    // Load the map textures directly from PK3
    firstpk3 := numtextures;
    texdefs := _Load(true);
    numtextures0 := Length(texdefs.Textures) - firstpk3;

    realloc(pointer(textures), numtextures * SizeOf(Ptexture_t), (numtextures0 + numtextures) * SizeOf(Ptexture_t));
    realloc(pointer(texturecolumnlump), numtextures * SizeOf(PSmallIntArray), (numtextures0 + numtextures) * SizeOf(PSmallIntArray));
    realloc(pointer(texturecolumnofs), numtextures * SizeOf(PIntegerArray), (numtextures0 + numtextures) * SizeOf(PIntegerArray));
    realloc(pointer(texturecomposite), numtextures * SizeOf(PByteArray), (numtextures0 + numtextures) * SizeOf(PByteArray));
    realloc(pointer(texturecompositesize), numtextures * SizeOf(integer), (numtextures0 + numtextures) * SizeOf(integer));
    realloc(pointer(texturewidth), numtextures * SizeOf(integer), (numtextures0 + numtextures) * SizeOf(integer));
    realloc(pointer(textureheight), numtextures * SizeOf(fixed_t), (numtextures0 + numtextures) * SizeOf(fixed_t));
    // JVAL: 20200112 - For tall textures
    realloc(pointer(texturecolumnheight), numtextures * SizeOf(integer), (numtextures0 + numtextures) * SizeOf(integer));
    realloc(pointer(texturecolumnheightfrac), numtextures * SizeOf(integer), (numtextures0 + numtextures) * SizeOf(integer));

    for i := numtextures to numtextures0 + numtextures - 1 do
    begin
      texdef := texdefs.Textures[i];

      textures[i] := malloc(SizeOf(texture_t) + SizeOf(texpatch_t));
      texture := textures[i];

      texture.width := texdef.Width;
      texture.height := texdef.Height;
      texture.patchcount := 1;
      {$IFNDEF OPENGL}
      texture.texture32 := nil;
      {$ENDIF}
      _SetTextureName(texture, texdef.Name);

      patch := @texture.patches[0];
      patch.originx := texdef.Patches[0].OriginX;
      patch.originy := texdef.Patches[0].OriginY;
      patch.patch := TWadRoutines.W_CheckNumForName(TWadRoutines.char8tostring(texture.name), TYPE_PATCH);

      _SetTextureTables(i, texture.width, texture.height);
    end;

    numtextures := numtextures + numtextures0;
  end;

  // Precalculate whatever possible.
  for i := 0 to numtextures - 1 do
    R_GenerateLookup(i);

  // Create translation table for global animation.
  texturetranslation := malloc((numtextures + 1) * SizeOf(integer));

  for i := 0 to numtextures - 1 do
    texturetranslation[i] := i;
end;

//==============================================================================
//
// R_ConfigureTextureDefs
//
//==============================================================================
procedure R_ConfigureTextureDefs(const ALoader: ITextureDefsLoader);
begin
  texturedefs_loader := ALoader;
end;

// The terrain of the flats is the compiled list of IdTech1\Definitions (TTerrainTables, without
// state); the numbers of the floors are the FLOOR_* of p_local, different in every game.
// Before, they were the four p_terrain.pas (P_TerrainTypeForName).
const
{$IF DEFINED(DOOM)}
  TERRAIN_GAME = TDefGame.Doom;
{$ELSEIF DEFINED(HERETIC)}
  TERRAIN_GAME = TDefGame.Heretic;
{$ELSEIF DEFINED(HEXEN)}
  TERRAIN_GAME = TDefGame.Hexen;
{$ELSE}
  TERRAIN_GAME = TDefGame.Strife;
{$ENDIF}

  // Solid, Water, Lava, Sludge, Nukage, Ice
{$IF DEFINED(HEXEN)}
  TERRAIN_FLOORS: array[TDefTerrainKind] of integer = (
    FLOOR_SOLID, FLOOR_WATER, FLOOR_LAVA, FLOOR_SLUDGE, FLOOR_SOLID, FLOOR_ICE
  );
{$ELSEIF DEFINED(HERETIC)}
  TERRAIN_FLOORS: array[TDefTerrainKind] of integer = (
    FLOOR_SOLID, FLOOR_WATER, FLOOR_LAVA, FLOOR_SLUDGE, FLOOR_SOLID, FLOOR_SOLID
  );
{$ELSE}
  TERRAIN_FLOORS: array[TDefTerrainKind] of integer = (
    FLOOR_SOLID, FLOOR_WATER, FLOOR_LAVA, FLOOR_SLUDGE, FLOOR_NUKAGE, FLOOR_SOLID
  );
{$ENDIF}

//==============================================================================
//
// R_FlatTerrainType
//
// JVAL: 9 December 2007, Added terrain types
//
//==============================================================================
function R_FlatTerrainType(const flatname: string): integer;
begin
  result := TERRAIN_FLOORS[TTerrainTables.KindForName(TERRAIN_GAME, strupper(flatname))];
end;

//==============================================================================
//
// R_ConfigureVoxelSprites
//
//==============================================================================
procedure R_ConfigureVoxelSprites(const ASprites: IEngineVoxelSprites);
begin
  voxel_sprites := ASprites;
end;

//==============================================================================
//
// R_ConfigureFlatInfo
// The parser of FLATINFO of IdTech1\TextureDefs and the catalog of the flats of
// the engine, given by the composition root
//
//==============================================================================
procedure R_ConfigureFlatInfo(const AParser: ITextureDefsFlatInfoParser; const ACatalog: ITextureDefsFlatCatalog;
  const APakFiles: IPakFileSystem);
begin
  flatinfo_parser := AParser;
  flatinfo_catalog := ACatalog;
  flatinfo_pakfiles := APakFiles;
end;

const
  FLATINFOLUMPNAME = 'FLATINFO';

var
  fl_text: string;

//==============================================================================
//
// R_RetrieveFlatInfo
//
//==============================================================================
procedure R_RetrieveFlatInfo(const in_text: string);
begin
  if fl_text = '' then
    fl_text := in_text
  else
    fl_text := fl_text + #13#10 + in_text;
end;

//==============================================================================
//
// R_ParseFlatInfoLumps
// The FLATINFO lumps of the WADs and the PAKs give their sizes to the flats
// (it was in r_flatinfo.pas)
//
//==============================================================================
procedure R_ParseFlatInfoLumps;
var
  i: integer;
  sizes: TArray<TTextureDefsFlatSize>;
  text: string;
begin
  if flatinfo_parser = nil then
    I_Error('R_ParseFlatInfoLumps(): FLATINFO is not configured (ComposeEngine was not called)');

  fl_text := '';
  for i := 0 to TWadRoutines.W_NumLumps - 1 do
    if TWadRoutines.char8tostring(TWadRoutines.W_GetNameForNum(i)) = FLATINFOLUMPNAME then
      R_RetrieveFlatInfo(TWadRoutines.W_TextLumpNum(i));

  for text in flatinfo_pakfiles.Texts(FLATINFOLUMPNAME) do
    R_RetrieveFlatInfo(text);
  for text in flatinfo_pakfiles.Texts(FLATINFOLUMPNAME + '.txt') do
    R_RetrieveFlatInfo(text);

  sizes := flatinfo_parser.Parse(fl_text, flatinfo_catalog);
  for i := 0 to Length(sizes) - 1 do
    flats[sizes[i].FlatIndex].size := sizes[i].SizeCode;
  fl_text := '';
end;

//==============================================================================
//
// R_InitFlats
//
//==============================================================================
procedure R_InitFlats;
var
  i: integer;
  flat: Pflat_t;
  range: TRendererLumpRange;
begin
  if lump_ranges = nil then
    I_Error('R_InitFlats(): R_ConfigureLumpRanges() was not called');
  try
    range := lump_ranges.FlatRange;
  except
    on E: ERendererException do
      I_Error('%s', [E.Message]);
  end;
  firstflat := range.First;
  lastflat := range.Last;
  numflats := lastflat - firstflat + 1;

  // Create translation table for global animation.
{$IFDEF STRIFE}
  flats := malloc(numflats * SizeOf(pointer));
{$ELSE}
  flats := mallocz(numflats * SizeOf(pointer));
{$ENDIF}

  for i := 0 to numflats - 1 do
  begin
    flat := malloc(SizeOf(flat_t));
    flat.name := TWadRoutines.W_GetNameForNum(firstflat + i);
    flat.translation := i;
    flat.lump := TWadRoutines.W_GetNumForName(flat.name);
    {$IFNDEF OPENGL}
    flat.flat32 := nil;
    {$ENDIF}
    // JVAL: 9 December 2007, Added terrain types
    flat.terraintype := R_FlatTerrainType(flat.name);
    flats[i] := flat;
    flats[i].size := 0;
  end;
  R_ParseFlatInfoLumps;
end;

//==============================================================================
//
// R_InitSpriteLumps
// Finds the width and hoffset of all sprites in the wad,
//  so the sprite does not need to be cached completely
//  just for having the header info ready during rendering.
//
//==============================================================================
procedure R_InitSpriteLumps;
var
  i: integer;
  range: TRendererLumpRange;
  table: TRendererSpriteTable;
begin
  if not Assigned(voxel_sprites) then
    I_Error('R_InitSpriteLumps(): the voxel sprites are not configured (call ComposeEngine first)');
  voxel_sprites.Generate;

  if (lump_ranges = nil) or (sprite_table_builder = nil) then
    I_Error('R_InitSpriteLumps(): R_ConfigureLumpRanges() was not called');

  try
    range := lump_ranges.SpriteRange;
  except
    on E: ERendererException do
      I_Error('%s', [E.Message]);
  end;
  firstspritelump := range.First;
  lastspritelump := range.Last;

  W_InitSprites; // JVAL: Images as sprites
  numspritelumps := lastspritelump - firstspritelump + 1;
  spritewidth := malloc(numspritelumps * SizeOf(fixed_t));
  spriteoffset := malloc(numspritelumps * SizeOf(fixed_t));
  spritetopoffset := malloc(numspritelumps * SizeOf(fixed_t));
  spritepresent := malloc(numspritelumps * SizeOf(boolean));

  table := sprite_table_builder.Build(range);
  for i := 0 to numspritelumps - 1 do
  begin
    spritewidth[i] := table.Width[i];
    spriteoffset[i] := table.LeftOffset[i];
    spritetopoffset[i] := table.TopOffset[i];
    spritepresent[i] := table.Present[i];
  end;
end;
//==============================================================================
// R_SafeFreeMemory
//
// R_FreeMemory
// JVAL: Free memory allocated without using zone
//
//==============================================================================
procedure R_SafeFreeMemory;
var
  i: integer;
begin
// textures
  for i := 0 to numtextures - 1 do
    if textures[i] <> nil then
    begin
      memfree(pointer(texturecolumnlump[i]), textures[i].width * SizeOf(texturecolumnlump[0][0]));
      memfree(pointer(texturecolumnofs[i]), textures[i].width * SizeOf(texturecolumnofs[0][0]));
      memfree(pointer(textures[i]), SizeOf(texture_t) + SizeOf(texpatch_t) * (textures[i].patchcount - 1));
    end;

  memfree(pointer(textures), numtextures * SizeOf(Ptexture_t));
  memfree(pointer(texturecolumnlump), numtextures * SizeOf(PSmallIntArray));
  memfree(pointer(texturecolumnofs), numtextures * SizeOf(PIntegerArray));
  memfree(pointer(texturecomposite), numtextures * SizeOf(PByteArray));
  memfree(pointer(texturecompositesize), numtextures * SizeOf(integer));
  memfree(pointer(texturewidth), numtextures * SizeOf(integer));
  memfree(pointer(textureheight), numtextures * SizeOf(fixed_t));
// JVAL: 20200112 - For tall textures
  memfree(pointer(texturecolumnheight), numtextures * SizeOf(integer));
  memfree(pointer(texturecolumnheightfrac), numtextures * SizeOf(integer));
  memfree(pointer(texturetranslation), (numtextures + 1) * SizeOf(integer));

// flats
  if flats <> nil then
    for i := 0 to numflats - 1 do
      memfree(pointer(flats[i]), SizeOf(flat_t));
  memfree(pointer(flats), numflats * SizeOf(pointer));

// sprites
  memfree(pointer(spritewidth), numspritelumps * SizeOf(fixed_t));
  memfree(pointer(spriteoffset), numspritelumps * SizeOf(fixed_t));
  memfree(pointer(spritetopoffset), numspritelumps * SizeOf(fixed_t));
  memfree(pointer(spritepresent), numspritelumps * SizeOf(boolean));

end;

//==============================================================================
//
// R_FreeMemory
//
//==============================================================================
procedure R_FreeMemory;
var
  i: integer;
begin
  if in_i_error then
  begin
    R_SafeFreeMemory;
    exit;
  end;
// textures
  for i := 0 to numtextures - 1 do
  begin
    memfree(pointer(texturecolumnlump[i]), textures[i].width * SizeOf(texturecolumnlump[0][0]));
    memfree(pointer(texturecolumnofs[i]), textures[i].width * SizeOf(texturecolumnofs[0][0]));
    memfree(pointer(textures[i]), SizeOf(texture_t) + SizeOf(texpatch_t) * (textures[i].patchcount - 1));
  end;

  memfree(pointer(textures), numtextures * SizeOf(Ptexture_t));
  memfree(pointer(texturecolumnlump), numtextures * SizeOf(PSmallIntArray));
  memfree(pointer(texturecolumnofs), numtextures * SizeOf(PIntegerArray));
  memfree(pointer(texturecomposite), numtextures * SizeOf(PByteArray));
  memfree(pointer(texturecompositesize), numtextures * SizeOf(integer));
  memfree(pointer(texturewidth), numtextures * SizeOf(integer));
  memfree(pointer(textureheight), numtextures * SizeOf(fixed_t));
// JVAL: 20200112 - For tall textures
  memfree(pointer(texturecolumnheight), numtextures * SizeOf(integer));
  memfree(pointer(texturecolumnheightfrac), numtextures * SizeOf(integer));
  memfree(pointer(texturetranslation), (numtextures + 1) * SizeOf(integer));

// flats
  for i := 0 to numflats - 1 do
    memfree(pointer(flats[i]), SizeOf(flat_t));
  memfree(pointer(flats), numflats * SizeOf(pointer));

// sprites
  memfree(pointer(spritewidth), numspritelumps * SizeOf(fixed_t));
  memfree(pointer(spriteoffset), numspritelumps * SizeOf(fixed_t));
  memfree(pointer(spritetopoffset), numspritelumps * SizeOf(fixed_t));
  memfree(pointer(spritepresent), numspritelumps * SizeOf(boolean));

  W_ShutDownSprites; // JVAL: Images as sprites
end;

//==============================================================================
//
// R_InitColormaps
//
//==============================================================================
procedure R_InitColormaps;
var
  lump: integer;
  length: integer;
  i: integer;
  cpal: array[0..255] of LongWord;
  colors: TArray<Cardinal>;
  colormapbytes: TArray<Byte>;
  fogbytes: TArray<Byte>;
  fogdata: TFogMapData;
{$IFDEF DOOM}
  inverse: TArray<Cardinal>;
{$ENDIF}
begin
  if (color_matcher = nil) or (colormap_preparer = nil) or (default_palette = nil) then
    I_Error('R_InitColormaps(): the colormap services are not configured (ComposeEngine was not called)');

  Move(default_palette.Colors^, cpal, SizeOf(cpal));
  SetLength(colors, 256);
  for i := 0 to 255 do
    colors[i] := cpal[i];

  aprox_black := color_matcher.FindApproximateIndex(colors, $0, 1, 255);
  aprox_red := color_matcher.FindApproximateIndex(colors, $FF0000, 1, 255);

  // Load in the light tables,
  //  256 byte align tables.
{$IFDEF HEXEN}
  fogmaplump := TWadRoutines.W_GetNumForName('FOGMAP');
{$ENDIF}
  lump := TWadRoutines.W_GetNumForName('COLORMAP');
{$IFDEF HEXEN}
  colormaplump := lump;
{$ENDIF}
  length := TWadRoutines.W_LumpLength(lump);
  SetLength(colormapbytes, length);
  TWadRoutines.W_ReadLump(lump, @colormapbytes[0]);
  // where the colormap is 0 the color is the nearest to black
  colormapbytes := colormap_preparer.ReplaceZeros(colormapbytes, aprox_black);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  colormaps := Z_Malloc(length, PU_STATIC, nil);
  memcpy(colormaps, @colormapbytes[0], length);
  v_translation := colormaps;
{$ELSE}
  def_colormaps := Z_Malloc(length, PU_STATIC, nil);
  memcpy(def_colormaps, @colormapbytes[0], length);
  v_translation := def_colormaps;
{$ENDIF}
  colormaps32 := Z_Malloc(length * SizeOf(LongWord), PU_STATIC, nil);
{$IFDEF DOOM}
  inverse := colormap_preparer.RowColors(colormapbytes, NUMCOLORMAPS, colors);
  for i := 0 to 255 do
    inversecolormap32[i] := inverse[i];
{$ENDIF}

  // JVAL: Mars fog sectors
{$IFDEF HEXEN}
  length := TWadRoutines.W_LumpLength(fogmaplump);
{$ELSE}
  lump := TWadRoutines.W_GetNumForName('FOGMAP');
  length := TWadRoutines.W_LumpLength(lump);
{$ENDIF}
  fog_colormaps := Z_Malloc(length, PU_STATIC, nil);
  fog_colormaps32 := Z_Malloc(length * SizeOf(LongWord), PU_STATIC, nil);
  SetLength(fogbytes, length);
{$IFDEF HEXEN}
  TWadRoutines.W_ReadLump(fogmaplump, @fogbytes[0]);
{$ELSE}
  TWadRoutines.W_ReadLump(lump, @fogbytes[0]);
{$ENDIF}
  fogdata := colormap_preparer.PrepareFog(fogbytes, colormapbytes, aprox_black, colors);
  memcpy(fog_colormaps, @fogdata.Indexes[0], length);
  for i := 0 to length - 1 do
    fog_colormaps32[i] := fogdata.Colors[i]; // JVAL: Mars fog sectors

{$IFDEF HEXEN}
end;

//==============================================================================
//
// R_ChangeColormap
//
//==============================================================================
procedure R_ChangeColormap(const lumpname: string);
var
  lump: integer;
  length: integer;
  bytes: TArray<Byte>;
begin
  // Load in the light tables,
  //  256 byte align tables.
  lump := TWadRoutines.W_GetNumForName(lumpname);
  LevelUseFog := lump = fogmaplump;
  length := TWadRoutines.W_LumpLength(lump);
  SetLength(bytes, length);
  TWadRoutines.W_ReadLump(lump, @bytes[0]);
  bytes := colormap_preparer.ReplaceZeros(bytes, aprox_black);
  memcpy(colormaps, @bytes[0], length);
  v_translation := colormaps;
  {$IFNDEF OPENGL}
  TRendererMain.R_SetRenderingFunctions;
  TRendererMain.R_SetPalette64;
  if usemultithread then
    TRendererHires.R_CalcHiResTables_MultiThread
  else
    TRendererHires.R_CalcHiResTables_SingleThread;
  {$ENDIF}
{$ENDIF}
end;

//==============================================================================
//
// R_InitData
// Locates all the lumps
//  that will be used by all views
// Must be called after W_Init.
//
//==============================================================================
procedure R_InitData;
begin
  TRendererHires.R_InitHiRes;
{$IFDEF STRIFE}
  if D_UseOldTexture1 then
    R_InitTexturesOld
  else
    R_InitTextures;
{$ELSE}
  R_InitTextures;
{$ENDIF}
  R_InitFlats;
  R_InitSpriteLumps;
  R_InitColormaps;
{$IFNDEF STRIFE}
{$IFNDEF OPENGL}
  R_InitFuzzTable;
{$ENDIF}
{$ENDIF}
end;

//==============================================================================
//
// R_FlatNumForName
// Retrieval, get a flat number for a flat name.
//
//==============================================================================
function R_FlatNumForName(const name: string): integer;
var
  i: integer;
  s: string;
begin
{$IFDEF STRIFE}
  i := TWadRoutines.W_CheckNumForName(name, TYPE_FLOOR);
{$ELSE}
  i := TWadRoutines.W_CheckNumForName2(name, firstflat, lastflat);
{$ENDIF}
  if i > -1 then
    result := i - firstflat
  else
  begin
    i := TWadRoutines.W_CheckNumForName(name);
    if i = -1 then  // JVAL: VERSION 204
    begin
      i := TWadRoutines.W_CheckNumForName('-NO-FLAT');
      if i = -1 then
        I_Error('R_FlatNumForName(): %s not found!', [name]);
    end;

    s := strupper(name);
    result := R_NameHash.IndexOf(s);
    if result >= 0 then
      if result < numflats then
        if flats[result].lump = i then
          Exit;

    result := numflats;
    while result > 0 do
    begin
      dec(result);
      if flats[result].lump = i then
      begin
        R_NameHash.Update(s, result);
        exit;
      end;
    end;

    // JVAL: Found a flat outside F_START, F_END
    result := numflats;
    realloc(pointer(flats), numflats * SizeOf(pointer), (numflats + 1) * SizeOf(pointer));
    inc(numflats);

    flats[result] := malloc(SizeOf(flat_t));
    flats[result].name := TWadRoutines.W_GetNameForNum(i);
    flats[result].translation := result;
    flats[result].lump := i;
    {$IFNDEF OPENGL}
    flats[result].flat32 := nil;
    {$ENDIF}
    // JVAL: 9 December 2007, Added terrain types
    flats[result].terraintype := R_FlatTerrainType(flats[result].name);
    R_NameHash.Update(s, result);
  end;
end;

//==============================================================================
//
// R_SafeFlatNumForName
//
//==============================================================================
function R_SafeFlatNumForName(const name: string): integer;
var
  i: integer;
  s: string;
begin
  i := TWadRoutines.W_CheckNumForName2(name, firstflat, lastflat);
  if i > -1 then
    result := i - firstflat
  else
  begin
    i := TWadRoutines.W_CheckNumForName(name);
    if i = -1 then
    begin
      result := -1;
      exit;
    end;

    s := strupper(name);
    result := R_NameHash.IndexOf(s);
    if result >= 0 then
      if result < numflats then
        if flats[result].lump = i then
          Exit;

    result := numflats;
    while result > 0 do
    begin
      dec(result);
      if flats[result].lump = i then
      begin
        R_NameHash.Update(s, result);
        exit;
      end;
    end;

    // JVAL: Found a flat outside F_START, F_END
    result := numflats;
    realloc(pointer(flats), numflats * SizeOf(pointer), (numflats + 1) * SizeOf(pointer));
    inc(numflats);

    flats[result] := malloc(SizeOf(flat_t));
    flats[result].name := TWadRoutines.W_GetNameForNum(i);
    flats[result].translation := result;
    flats[result].lump := i;
    {$IFNDEF OPENGL}
    flats[result].flat32 := nil;
    {$ENDIF}
    // JVAL: 9 December 2007, Added terrain types
    flats[result].terraintype := R_FlatTerrainType(flats[result].name);
    R_NameHash.Update(s, result);
  end
end;

//==============================================================================
//
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
// R_NewFlatNumForLump
//
//==============================================================================
function R_NewFlatNumForLump(const lump: integer): integer;
begin
  if (lump >= firstflat) and (lump <= lastflat) then
    result := lump - firstflat
  else
  begin
    if (lump < 0) or (lump >= TWadRoutines.W_NumLumps) then
      I_Error('R_NewFlatNumForLump(): Invalid lump = %d', [lump]);

    // JVAL: Found a flat outside F_START, F_END
    result := numflats;
    realloc(pointer(flats), numflats * SizeOf(pointer), (numflats + 1) * SizeOf(pointer));
    inc(numflats);

    flats[result] := malloc(SizeOf(flat_t));
    flats[result].name := TWadRoutines.W_GetNameForNum(lump);
    flats[result].translation := result;
    flats[result].lump := lump;
    {$IFNDEF OPENGL}
    flats[result].flat32 := nil;
    {$ENDIF}
    // JVAL: 9 December 2007, Added terrain types
    flats[result].terraintype := R_FlatTerrainType(flats[result].name);
    flats[result].size := 0;
  end
end;

//==============================================================================
//
{$ENDIF}
// R_CheckTextureNumForName
// Check whether texture is available.
// Filter out NoTexture indicator.
//
//==============================================================================
function R_CheckTextureNumForName(const name: string): integer;
var
  i: integer;
  s: string;
  check: name8_t;
begin
  // "NoTexture" marker.
  if name = '' then
  begin
    result := -1;
    exit;
  end;

  // "NoTexture" marker.
  if name[1] = '-' then
  begin
    result := 0;
    exit;
  end;

  s := strupper(name);
  check.s := TWadRoutines.stringtochar8(s);
  result := R_NameHash.IndexOf(s);
  if result >= 0 then
    if result < numtextures then
      if name8_t(textures[result].name).x[0] = check.x[0] then
        if name8_t(textures[result].name).x[1] = check.x[1] then
          exit;

  for i := 0 to numtextures - 1 do
    if name8_t(textures[i].name).x[0] = check.x[0] then
      if name8_t(textures[i].name).x[1] = check.x[1] then
      begin
        result := i;
        R_NameHash.Update(s, result);
        exit;
      end;

  result := -1;
end;

//==============================================================================
//
// R_SafeTextureNumForName
//
//==============================================================================
function R_SafeTextureNumForName(const name: string): integer;
var
  i: integer;
  s: string;
  check: name8_t;
begin
  if name = '' then
  begin
    I_Warning('R_SafeTextureNumForName(): Texture name is null.'#13#10);
    result := R_RendererProfile.MissingTexture;
    exit;
  end;

  // "NoTexture" marker.
  if name[1] = '-' then
  begin
    result := R_RendererProfile.MissingTexture;
    exit;
  end;

  s := strupper(name);
  check.s := TWadRoutines.stringtochar8(s);
  result := R_NameHash.IndexOf(s);
  if result >= 0 then
    if result < numtextures then
      if name8_t(textures[result].name).x[0] = check.x[0] then
        if name8_t(textures[result].name).x[1] = check.x[1] then
          exit;

  for i := 0 to numtextures - 1 do
    if name8_t(textures[i].name).x[0] = check.x[0] then
      if name8_t(textures[i].name).x[1] = check.x[1] then
      begin
        result := i;
        R_NameHash.Update(s, result);
        exit;
      end;

{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  I_Warning('R_SafeTextureNumForName(): %s not found.'#13#10, [name]);
{$ELSE}
  // the name of a custom colormap is not missing
  if R_CustomColorMapForName(name) < 0 then
    I_Warning('R_SafeTextureNumForName(): %s not found.'#13#10, [name]);
{$ENDIF}
  result := renderer_profile.MissingTexture;
end;

//==============================================================================
//
// R_TextureNumForName
// Calls R_CheckTextureNumForName,
//  aborts with error message.
//
//==============================================================================
function R_TextureNumForName(const name: string): integer;
begin
  result := R_CheckTextureNumForName(name);

  if result = -1 then
    I_Error('R_TextureNumForName(): %s not found!', [name]);
end;

//==============================================================================
//
// R_NameForSideTexture
//
//==============================================================================
function R_NameForSideTexture(const sn: SmallInt): char8_t;
begin
  ZeroMemory(@result, SizeOf(Result));
  Result[0] := '-';

  if TRendererProfiles.IsNoSideTexture(R_RendererProfile, sn) then
    exit;

  if sn >= numtextures then
    exit;

  if (sn > 0) or not renderer_profile.CustomColormapsOnSides then
  begin
    Result := textures[sn].name;
    Exit;
  end;

{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  // the games that have custom colormaps on the sides (the profile says which)
  if sn < -numcustomcolormaps then
    exit;
  Result := TWadRoutines.stringtochar8(customcolormaps[- sn - 1].name);
{$ENDIF}
end;

//==============================================================================
//
// R_PrecacheLevel
// Preloads all relevant graphics for the level.
//
//==============================================================================
procedure R_PrecacheLevel;
var
  plan: TRendererPrecachePlan;
  planinput: TRendererPrecacheInput;
  nextra: integer;
  i: integer;
  j: integer;
  k: integer;
  lump: integer;
  texture: Ptexture_t;
  th: Pthinker_t;
  sf: Pspriteframe_t;
  flatmemory: integer;
  texturememory: integer;
  spritememory: integer;
  allocmemory: integer;
{$IFNDEF OPENGL}
  flat: pointer;
{$ENDIF}
begin
  printf('R_PrecacheLevel()'#13#10);

  if precache_planner = nil then
    I_Error('R_PrecacheLevel(): R_ConfigurePrecache() was not called');

  // What the level uses is decided by TRendererPrecachePlanner; here the numbers are collected.
  planinput.FlatCount := numflats;
  planinput.TextureCount := numtextures;
  planinput.SpriteCount := numspritespresent;

  SetLength(planinput.SectorFlats, numsectors * 2);
  for i := 0 to numsectors - 1 do
  begin
    planinput.SectorFlats[i * 2] := sectors[i].floorpic;
    planinput.SectorFlats[i * 2 + 1] := sectors[i].ceilingpic;
  end;
{$IFDEF HEXEN}
  // JVAL: Precaching animated flats
  SetLength(planinput.ExtraFlats, animatedflatslist.Count);
  for i := 0 to animatedflatslist.Count - 1 do
    planinput.ExtraFlats[i] := animatedflatslist[i];
{$ENDIF}

  SetLength(planinput.SideTextures, numsides * 3);
  for i := 0 to numsides - 1 do
  begin
    planinput.SideTextures[i * 3] := sides[i].toptexture;
    planinput.SideTextures[i * 3 + 1] := sides[i].midtexture;
    planinput.SideTextures[i * 3 + 2] := sides[i].bottomtexture;
  end;
{$IFDEF HEXEN}
  // JVAL: Precaching animated textures
  nextra := animatedtextureslist.Count;
{$ENDIF}
  // Sky texture is always present.
  // Note that F_SKY1 is the name used to
  //  indicate a sky floor/ceiling as a flat,
  //  while the sky texture is stored like
  //  a wall texture, with an episode dependend
  //  name.
{$IFDEF HEXEN}
  SetLength(planinput.ExtraTextures, nextra + 2);
  for i := 0 to nextra - 1 do
    planinput.ExtraTextures[i] := animatedtextureslist[i];
  planinput.ExtraTextures[nextra] := SkyTexture;
  planinput.ExtraTextures[nextra + 1] := Sky2Texture;
{$ELSE}
  SetLength(planinput.ExtraTextures, 1);
  planinput.ExtraTextures[0] := skytexture;
{$ENDIF}

  nextra := 0;
  th := TTickState.ThinkerCap.next;
  while th <> @TTickState.ThinkerCap do
  begin
    if @th._function.acp1 = @P_MobjThinker then
      inc(nextra);
    th := th.next;
  end;
  SetLength(planinput.ObjectSprites, nextra);
  nextra := 0;
  th := TTickState.ThinkerCap.next;
  while th <> @TTickState.ThinkerCap do
  begin
    if @th._function.acp1 = @P_MobjThinker then
    begin
      planinput.ObjectSprites[nextra] := Pmobj_t(th).sprite;
      inc(nextra);
    end;
    th := th.next;
  end;

  plan := precache_planner.Plan(planinput);

  // Precache flats.
  flatmemory := 0;
  allocmemory := GetAllocMemSize;

  printf(' Precaching flats'#13#10);
  for i := 0 to numflats - 1 do
  begin
    if plan.FlatPresent[i] then
    begin
      lump := R_GetLumpForFlat(i);
{$IFDEF OPENGL}
      TWadRoutines.W_CacheLumpNum(lump, PU_CACHE);
{$ELSE}
      flat := TWadRoutines.W_CacheLumpNum(lump, PU_STATIC);
      TRendererCacheFlats.R_ReadDS32Cache(i);
      Z_ChangeTag(flat, PU_CACHE);
{$ENDIF}
      flatmemory := flatmemory + TWadRoutines.W_LumpLength(lump);
    end;
  end;

  allocmemory := GetAllocMemSize - allocmemory;
  printf('%6d KB memory usage for flats'#13#10, [(flatmemory + allocmemory) div 1024]);

  // Precache textures.
  texturememory := 0;
  allocmemory := GetAllocMemSize;

  printf(' Precaching textures'#13#10);
{$IFNDEF OPENGL}
  dc_mod := 0;
  dc_texturemod := 0;
{$ENDIF}
  for i := 0 to numtextures - 1 do
  begin
    if not plan.TexturePresent[i] then
      continue;

    texture := textures[i];

    for j := 0 to texture.patchcount - 1 do
    begin
      lump := texture.patches[j].patch;
      texturememory := texturememory + TWadRoutines.W_LumpLength(lump);
      TWadRoutines.W_CacheLumpNum(lump, PU_CACHE);
    end;
{$IFNDEF OPENGL}
    TRendererCacheWalls.R_Precache32bittexture(i);
{$ENDIF}
  end;
  allocmemory := GetAllocMemSize - allocmemory;
  printf('%6d KB memory usage for textures'#13#10, [(texturememory + allocmemory) div 1024]);

  // Precache sprites.
  spritememory := 0;
  allocmemory := GetAllocMemSize;

  printf(' Precaching sprites'#13#10);
  for i := 0 to numspritespresent - 1 do
  begin
    if plan.SpritePresent[i] then
    begin
      for j := 0 to sprites[i].numframes - 1 do
      begin
        sf := @sprites[i].spriteframes[j];
        for k := 0 to 7 do
        begin
          lump := firstspritelump + sf.lump[k];
          spritememory := spritememory + TWadRoutines.W_LumpLength(lump);
          TWadRoutines.W_CacheLumpNum(lump, PU_CACHE);
        end;
      end;
    end;
  end;
  allocmemory := GetAllocMemSize - allocmemory;
  printf('%6d KB memory usage for sprites'#13#10, [(spritememory + allocmemory) div 1024]);
end;

//==============================================================================
//
// R_SetupLevel
//
//==============================================================================
procedure R_SetupLevel;
begin
  maxvisplane := -1;
  {$IFNDEF OPENGL}
  R_InitFixedColumn;
  maxvisplane3d := -1;  // JVAL: 3d Floors
  maxvisslope := -1;  // JVAL: Slopes
  {$ENDIF}
  max_ds_p := -1;
  maxvissprite := -1;
end;

end.

