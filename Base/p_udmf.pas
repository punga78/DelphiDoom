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
//  Basic UDMF loader
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_udmf;

interface

uses
  d_delphi,
  doomdata,
  m_fixed,
  tables,
  DelphiDoom.Udmf.Types,
  DelphiDoom.Udmf.Intf,
  DelphiDoom.Udmf.Apply.Intf,
  DelphiDoom.Engine.Wad.Intf;

//==============================================================================
//
// UDMF_Check
//
//==============================================================================
function UDMF_Check(const mapname: string): boolean;

//==============================================================================
//
// P_ConfigureUdmf
// Gives the unit the converter of the text maps and the WAD services that write the converted
// map. The composition root calls it. The records of the converter have to be the ones of this
// game: the sizes are checked
//
//==============================================================================
procedure P_ConfigureUdmf(const AConverter: IUdmfConverter; const AWadServices: IEngineWadServices);

//==============================================================================
//
// P_ConfigureUdmfApply
// Gives the unit the objects that write the extra values of the converted map in sectors[],
// lines[], sides[] and segs[]. The composition root calls it
//
//==============================================================================
procedure P_ConfigureUdmfApply(const ASectors, ALines, ASides, ASegs: IUdmfMapPartApplier);

const
  ML_SCRIPT = Ord(ML_BEHAVIOR) + 1;
  ML_UDMFSTART = Ord(ML_BEHAVIOR) + 2;
  ML_THINGS2 = ML_UDMFSTART + 0;
  ML_SECTORS2 = ML_UDMFSTART + 1;
  ML_VERTEX2 = ML_UDMFSTART + 2;
  ML_LINEDEF2 = ML_UDMFSTART + 3;
  ML_SIDEDEF2 = ML_UDMFSTART + 4;
  ML_NSPACE = ML_UDMFSTART + 5;
  ML_NUMUDMFLUMPS = ML_UDMFSTART + 6;

  MLN_THINGS2 = 'THINGS2';
  MLN_SECTORS2 = 'SECTORS2';
  MLN_VERTEX2 = 'VERTEX2';
  MLN_LINEDEF2 = 'LINEDEF2';
  MLN_SIDEDEF2 = 'SIDEDEF2';
  MLN_NSPACE = 'NSPACE';

const
  UDMF_TF_SKILL1 = DelphiDoom.Udmf.Types.UDMF_TF_SKILL1;
  UDMF_TF_SKILL2 = DelphiDoom.Udmf.Types.UDMF_TF_SKILL2;
  UDMF_TF_SKILL3 = DelphiDoom.Udmf.Types.UDMF_TF_SKILL3;
  UDMF_TF_SKILL4 = DelphiDoom.Udmf.Types.UDMF_TF_SKILL4;
  UDMF_TF_SKILL5 = DelphiDoom.Udmf.Types.UDMF_TF_SKILL5;
  UDMF_TF_SKILL_MASK = DelphiDoom.Udmf.Types.UDMF_TF_SKILL_MASK;
  UDMF_TF_HASZ = DelphiDoom.Udmf.Types.UDMF_TF_HASZ;
  UDMF_TF_HASGRAVITY = DelphiDoom.Udmf.Types.UDMF_TF_HASGRAVITY;
  UDMF_TF_HASHEALTH = DelphiDoom.Udmf.Types.UDMF_TF_HASHEALTH;
  UDMF_TF_SINGLE = DelphiDoom.Udmf.Types.UDMF_TF_SINGLE;
  UDMF_TF_DM = DelphiDoom.Udmf.Types.UDMF_TF_DM;
  UDMF_TF_COOP = DelphiDoom.Udmf.Types.UDMF_TF_COOP;

type
  extrathing_t = record
    extraflags: Integer;
    x, y, z: fixed_t;
    id: Integer;
    gravity: float;
    health: float;
    {$IFNDEF HEXEN}
    special: integer;
    arg1: integer;
    arg2: integer;
    arg3: integer;
    arg4: integer;
    arg5: integer;
    {$ENDIF}
  end;
  Pextrathing_t = ^extrathing_t;
  extrathing_tArray = array[0..$FFFF] of extrathing_t;
  Pextrathing_tArray = ^extrathing_tArray;

type
  moreids_t = set of Byte;
  Pmoreids_t = ^moreids_t;

const
  UDMF_SF_CEILINGPLANE_A = DelphiDoom.Udmf.Types.UDMF_SF_CEILINGPLANE_A;
  UDMF_SF_CEILINGPLANE_B = DelphiDoom.Udmf.Types.UDMF_SF_CEILINGPLANE_B;
  UDMF_SF_CEILINGPLANE_C = DelphiDoom.Udmf.Types.UDMF_SF_CEILINGPLANE_C;
  UDMF_SF_CEILINGPLANE_D = DelphiDoom.Udmf.Types.UDMF_SF_CEILINGPLANE_D;
  UDMF_SF_CEILINGPLANE = UDMF_SF_CEILINGPLANE_A or UDMF_SF_CEILINGPLANE_B or UDMF_SF_CEILINGPLANE_C or UDMF_SF_CEILINGPLANE_D;
  UDMF_SF_FLOORPLANE_A = DelphiDoom.Udmf.Types.UDMF_SF_FLOORPLANE_A;
  UDMF_SF_FLOORPLANE_B = DelphiDoom.Udmf.Types.UDMF_SF_FLOORPLANE_B;
  UDMF_SF_FLOORPLANE_C = DelphiDoom.Udmf.Types.UDMF_SF_FLOORPLANE_C;
  UDMF_SF_FLOORPLANE_D = DelphiDoom.Udmf.Types.UDMF_SF_FLOORPLANE_D;
  UDMF_SF_FLOORPLANE = UDMF_SF_FLOORPLANE_A or UDMF_SF_FLOORPLANE_B or UDMF_SF_FLOORPLANE_C or UDMF_SF_FLOORPLANE_D;
  UDMF_SF_RIPPLECEILING = DelphiDoom.Udmf.Types.UDMF_SF_RIPPLECEILING;
  UDMF_SF_RIPPLEFLOOR = DelphiDoom.Udmf.Types.UDMF_SF_RIPPLEFLOOR;
  UDMF_SF_FOG = DelphiDoom.Udmf.Types.UDMF_SF_FOG;
  UDMF_SF_HIDDEN = DelphiDoom.Udmf.Types.UDMF_SF_HIDDEN;
  UDMF_SF_NOJUMP = DelphiDoom.Udmf.Types.UDMF_SF_NOJUMP;
  UDMF_SF_NOCROUCH = DelphiDoom.Udmf.Types.UDMF_SF_NOCROUCH;

type
  extrasector_t = record
    extraflags: Integer;
    floorheight: fixed_t;
    ceilingheight: fixed_t;
    {$IFDEF DOOM_OR_STRIFE}
    xpanningfloor: fixed_t;   // X texture offset of floor texture, Default = 0.0.
    ypanningfloor: fixed_t;   // Y texture offset of floor texture, Default = 0.0.
    xpanningceiling: fixed_t; // X texture offset of ceiling texture, Default = 0.0.
    ypanningceiling: fixed_t; // Y texture offset of ceiling texture, Default = 0.0.
    {$ENDIF}
    rotationfloor: angle_t;   // Rotation of floor texture (degrees in TEXMAP)
    rotationfloorx: fixed_t;  // x/y rover for rotating floor
    rotationfloory: fixed_t;
    rotationceiling: angle_t; // Rotation of ceiling texture (degrees in TEXMAP)
    rotationceilingx: fixed_t;// x/y rover for rotating ceiling
    rotationceilingy: fixed_t;// x/y rover for rotating ceiling
    gravity: fixed_t;         // Default is 1.0
    ceilingplane_a: float;    // Define the plane equation for the sector's ceiling. Default is a horizontal plane at 'heightceiling'.
    ceilingplane_b: float;    // 'heightceiling' will still be used to calculate texture alignment.
    ceilingplane_c: float;    // The plane equation will only be used if all 4 values are given.
    ceilingplane_d: float;
    floorplane_a: float;      // Define the plane equation for the sector's floor. Default is a horizontal plane at 'heightfloor'.
    floorplane_b: float;      // 'heightfloor' will still be used to calculate texture alignment.
    floorplane_c: float;      // The plane equation will only be used if all 4 values are given.
    floorplane_d: float;
    moreids: moreids_t;
    {$IFNDEF HEXEN}
    sound: integer;
    {$ENDIF}
    windthrust: fixed_t;
    windangle: angle_t;
  end;
  Pextrasector_t = ^extrasector_t;
  extrasector_tArray = array[0..$FFFF] of extrasector_t;
  Pextrasector_tArray = ^extrasector_tArray;

const
  UDMF_VF_ZFLOOR = DelphiDoom.Udmf.Types.UDMF_VF_ZFLOOR;
  UDMF_VF_ZCEILING = DelphiDoom.Udmf.Types.UDMF_VF_ZCEILING;

type
  extravertex_t = record
    extraflags: integer;
    x, y: fixed_t;
    zfloor, zceiling: fixed_t; // Absolute floor & ceiling height
  end;
  Pextravertex_t = ^extravertex_t;
  extravertex_tArray = array[0..$FFFF] of extravertex_t;
  Pextravertex_tArray = ^extravertex_tArray;

const
  ULAC_DEFAULT = DelphiDoom.Udmf.Types.ULAC_DEFAULT;
  ULAC_REPEAT = DelphiDoom.Udmf.Types.ULAC_REPEAT;
  ULAC_CROSS = DelphiDoom.Udmf.Types.ULAC_CROSS;
  ULAC_USE = DelphiDoom.Udmf.Types.ULAC_USE;
  ULAC_MCROSS = DelphiDoom.Udmf.Types.ULAC_MCROSS;
  ULAC_IMPACT = DelphiDoom.Udmf.Types.ULAC_IMPACT;
  ULAC_PUSH = DelphiDoom.Udmf.Types.ULAC_PUSH;
  ULAC_PCROSS = DelphiDoom.Udmf.Types.ULAC_PCROSS;
  {$IFNDEF HEXEN}
  ULAC_MPUSH = DelphiDoom.Udmf.Types.ULAC_MPUSH;
  {$ENDIF}

type
  extraline_t = record
   {$IFNDEF HEXEN}
    arg1: integer;
    arg2: integer;
    arg3: integer;
    arg4: integer;
    arg5: integer;
    activators: integer;  // ULAC_????
    {$ENDIF}
    moreids: moreids_t;
  end;
  Pextraline_t = ^extraline_t;
  extraline_tArray = array[0..$FFFF] of extraline_t;
  Pextraline_tArray = ^extraline_tArray;

type
  extraside_t = record
    textureoffset: fixed_t;
    toptextureoffset: fixed_t;
    bottomtextureoffset: fixed_t;
    midtextureoffset: fixed_t;
    rowoffset: fixed_t;
    toprowoffset: fixed_t;
    bottomrowoffset: fixed_t;
    midrowoffset: fixed_t;
    flags: integer;
  end;
  Pextraside_t = ^extraside_t;
  extraside_tArray = array[0..$FFFF] of extraside_t;
  Pextraside_tArray = ^extraside_tArray;

var
  udmfthings: Pextrathing_tArray;
  numudmfthings: integer;
  udmfsectors: Pextrasector_tArray;
  numudmfsectors: integer;
  udmfvertexes: Pextravertex_tArray;
  numudmfvertexes: integer;
  udmflinedefs: Pextraline_tArray;
  numudmflinedefs: integer;
  udmfsidedefs: Pextraside_tArray;
  numudmfsidedefs: integer;
  hasudmfdata: boolean;
  udmfnamespace: string;
  udmflinetranslate: boolean;

//==============================================================================
//
// UDMF_MakeSectors
//
//==============================================================================
function UDMF_MakeSectors: boolean;

//==============================================================================
//
// UDMF_MakeLines
//
//==============================================================================
function UDMF_MakeLines: boolean;

//==============================================================================
//
// UDMF_MakeSides
//
//==============================================================================
function UDMF_MakeSides: boolean;

//==============================================================================
//
// UDMF_MakeSegs
//
//==============================================================================
function UDMF_MakeSegs: boolean;

const
{$IFNDEF HEXEN}
  UDMF_SPECIAL_START = 700;
  UDMF_SPECIAL_FINISH = UDMF_SPECIAL_START + 256;
  UDMF_NORMAL_ADD = 300;
{$ELSE}
  UDMF_SPECIAL_START = 0;
  UDMF_NORMAL_ADD = 0;
{$ENDIF}

implementation

uses
  doomdef,
  acs,
  m_argv,
  m_base,
  i_system,
  p_setup,
  p_common,
  r_defs,
  sounds,
  sc_tokens,
  z_zone,
  w_wad,
  DelphiDoom.Wad.Types,
  DelphiDoom.Wad.Intf;

var
  // given by the composition root (P_ConfigureUdmf)
  udmf_converter: IUdmfConverter = nil;
  udmf_wadservices: IEngineWadServices = nil;
  udmf_sectorapplier: IUdmfMapPartApplier = nil;
  udmf_lineapplier: IUdmfMapPartApplier = nil;
  udmf_sideapplier: IUdmfMapPartApplier = nil;
  udmf_segapplier: IUdmfMapPartApplier = nil;

//==============================================================================
//
// UDMF_CheckRecordSize
//
//==============================================================================
procedure UDMF_CheckRecordSize(const what: string; const enginesize, librarysize: integer);
begin
  if enginesize <> librarysize then
    I_Error('P_ConfigureUdmf(): the %s of the engine is %d bytes, the one of the UDMF library %d',
      [what, enginesize, librarysize]);
end;

//==============================================================================
//
// P_ConfigureUdmf
//
//==============================================================================
procedure P_ConfigureUdmf(const AConverter: IUdmfConverter; const AWadServices: IEngineWadServices);
begin
  UDMF_CheckRecordSize('record of a thing', SizeOf(mapthing_t), AConverter.Profile.Things.BaseSize);
  UDMF_CheckRecordSize('extra record of a thing', SizeOf(extrathing_t), AConverter.Profile.Things.ExtraSize);
  UDMF_CheckRecordSize('record of a line', SizeOf(maplinedef_t), AConverter.Profile.Lines.BaseSize);
  UDMF_CheckRecordSize('extra record of a line', SizeOf(extraline_t), AConverter.Profile.Lines.ExtraSize);
  UDMF_CheckRecordSize('record of a side', SizeOf(mapsidedef_t), AConverter.Profile.Sides.BaseSize);
  UDMF_CheckRecordSize('extra record of a side', SizeOf(extraside_t), AConverter.Profile.Sides.ExtraSize);
  UDMF_CheckRecordSize('record of a vertex', SizeOf(mapvertex_t), AConverter.Profile.Vertexes.BaseSize);
  UDMF_CheckRecordSize('extra record of a vertex', SizeOf(extravertex_t), AConverter.Profile.Vertexes.ExtraSize);
  UDMF_CheckRecordSize('record of a sector', SizeOf(mapsector_t), AConverter.Profile.Sectors.BaseSize);
  UDMF_CheckRecordSize('extra record of a sector', SizeOf(extrasector_t), AConverter.Profile.Sectors.ExtraSize);
  udmf_converter := AConverter;
  udmf_wadservices := AWadServices;
end;

//==============================================================================
//
// UDMF_ExtraToMemory
// The extra records of a converted map for the engine, in the memory of the level
//
//==============================================================================
function UDMF_ExtraToMemory(const data: System.TArray<Byte>): pointer;
begin
  result := Z_Malloc(Length(data), PU_LEVEL, nil);
  memcpy(result, @data[0], Length(data));
end;

//==============================================================================
//
// UDMF_UpdateGlobalStructs
//
//==============================================================================
procedure UDMF_UpdateGlobalStructs(const converted: IUdmfConvertedMap);
begin
  numudmfthings := converted.ThingCount;
  if numudmfthings > 0 then
    udmfthings := UDMF_ExtraToMemory(converted.ExtraThings);

  numudmfsectors := converted.SectorCount;
  if numudmfsectors > 0 then
    udmfsectors := UDMF_ExtraToMemory(converted.ExtraSectors);

  numudmfvertexes := converted.VertexCount;
  if numudmfvertexes > 0 then
    udmfvertexes := UDMF_ExtraToMemory(converted.ExtraVertexes);

  numudmflinedefs := converted.LineCount;
  if numudmflinedefs > 0 then
    udmflinedefs := UDMF_ExtraToMemory(converted.ExtraLines);

  numudmfsidedefs := converted.SideCount;
  if numudmfsidedefs > 0 then
    udmfsidedefs := UDMF_ExtraToMemory(converted.ExtraSides);
end;

//==============================================================================
//
// UDMF_LumpToBytes
// The bytes of a lump of the level; none if it is not a lump
//
//==============================================================================
function UDMF_LumpToBytes(const lump: integer): System.TArray<Byte>;
var
  ldata: PByteArray;
  llen: integer;
begin
  result := nil;
  if lump > 0 then
  begin
    ldata := W_CacheLumpNum(lump, PU_STATIC);
    llen := W_LumpLength(lump);
    SetLength(result, llen);
    if llen > 0 then
      memcpy(@result[0], ldata, llen);
    Z_Free(ldata);
  end;
end;

//==============================================================================
//
// UDMF_SaveToVanilla
// The converted map as a PWAD: the lumps of a vanilla map, then the extra ones
//
//==============================================================================
procedure UDMF_SaveToVanilla(const converted: IUdmfConvertedMap; const amapname: string;
  const afilename: string; const bl, sl: integer);
var
  builder: IWadBuilder;
  lumps: TArray<TUdmfLump>;
  i: integer;
begin
  lumps := converted.GetLumps(amapname, UDMF_LumpToBytes(bl), UDMF_LumpToBytes(sl));
  builder := udmf_wadservices.CreateBuilder(TWadKind.PWad);
  for i := 0 to Length(lumps) - 1 do
    builder.AddLump(lumps[i].Name, lumps[i].Data);
  builder.SaveToFile(afilename);
end;
//==============================================================================
// UDMF_Check
//
//------------------------------------------------------------------------------
//
//==============================================================================
function UDMF_Check(const mapname: string): boolean;
const
  MAXLUMPCHECK = 10;
var
  converted: IUdmfConvertedMap;
  i: integer;
  lumpnum: integer;
  crc32: string;
  wadfilemap: string;
  behav_lump: integer;
  script_lump: integer;
begin
  hasudmfdata := false;
  udmfnamespace := '';
  udmflinetranslate := false;
  udmfthings := nil;
  numudmfthings := 0;
  udmfsectors := nil;
  numudmfsectors := 0;
  udmfvertexes := nil;
  numudmfvertexes := 0;
  udmflinedefs := nil;
  numudmflinedefs := 0;

  lumpnum := W_GetNumForName(mapname);
  if (lumpnum < 0) or (lumpnum >= W_NumLumps - 1) then
  begin
    result := false;
    exit;
  end;

  if strupper(char8tostring(W_GetNameForNum(lumpnum + 1))) <> 'TEXTMAP' then
  begin
    if lumpnum + ML_THINGS2 < W_NumLumps then
      if strupper(char8tostring(W_GetNameForNum(lumpnum + ML_THINGS2))) = MLN_THINGS2 then
      begin
        udmfthings := W_CacheLumpNum(lumpnum + ML_THINGS2, PU_LEVEL);
        numudmfthings := W_LumpLength(lumpnum + ML_THINGS2) div SizeOf(extrathing_t);
      end;
    if lumpnum + ML_SECTORS2 < W_NumLumps then
      if strupper(char8tostring(W_GetNameForNum(lumpnum + ML_SECTORS2))) = MLN_SECTORS2 then
      begin
        udmfsectors := W_CacheLumpNum(lumpnum + ML_SECTORS2, PU_LEVEL);
        numudmfsectors := W_LumpLength(lumpnum + ML_SECTORS2) div SizeOf(extrasector_t);
      end;
    if lumpnum + ML_VERTEX2 < W_NumLumps then
      if strupper(char8tostring(W_GetNameForNum(lumpnum + ML_VERTEX2))) = MLN_VERTEX2 then
      begin
        udmfvertexes := W_CacheLumpNum(lumpnum + ML_VERTEX2, PU_LEVEL);
        numudmfvertexes := W_LumpLength(lumpnum + ML_VERTEX2) div SizeOf(extravertex_t);
      end;
    if lumpnum + ML_LINEDEF2 < W_NumLumps then
      if strupper(char8tostring(W_GetNameForNum(lumpnum + ML_LINEDEF2))) = MLN_LINEDEF2 then
      begin
        udmflinedefs := W_CacheLumpNum(lumpnum + ML_LINEDEF2, PU_LEVEL);
        numudmflinedefs := W_LumpLength(lumpnum + ML_LINEDEF2) div SizeOf(extraline_t);
      end;
    if lumpnum + ML_SIDEDEF2 < W_NumLumps then
      if strupper(char8tostring(W_GetNameForNum(lumpnum + ML_SIDEDEF2))) = MLN_SIDEDEF2 then
      begin
        udmfsidedefs := W_CacheLumpNum(lumpnum + ML_SIDEDEF2, PU_LEVEL);
        numudmfsidedefs := W_LumpLength(lumpnum + ML_SIDEDEF2) div SizeOf(extraside_t);
      end;
    if lumpnum + ML_NSPACE < W_NumLumps then
      if strupper(char8tostring(W_GetNameForNum(lumpnum + ML_NSPACE))) = MLN_NSPACE then
      begin
        udmfnamespace := W_TextLumpNum(lumpnum + ML_NSPACE);
        udmflinetranslate := (udmfnamespace <> strupper(_GAME)) and (udmfnamespace <> 'ZDOOMTRANSLATED');
      end;
    hasudmfdata := (numudmfthings <> 0) and (numudmfsectors <> 0) and (numudmfvertexes <> 0) and (numudmflinedefs <> 0) and (numudmfsidedefs <> 0);
    result := false;
    exit;
  end;

  behav_lump := -1;
  for i := lumpnum + 1 to lumpnum + MAXLUMPCHECK do
  begin
    if i >= W_NumLumps then
      break;
    if strupper(char8tostring(W_GetNameForNum(i))) = 'ENDMAP' then
      break;
    if strupper(char8tostring(W_GetNameForNum(i))) = 'BEHAVIOR' then
    begin
      behav_lump := i;
      break;
    end;
  end;

  script_lump := -1;
  for i := lumpnum + 1 to lumpnum + MAXLUMPCHECK do
  begin
    if i >= W_NumLumps then
      break;
    if strupper(char8tostring(W_GetNameForNum(i))) = 'ENDMAP' then
      break;
    if acc_isscriptlump(i) then
    begin
      script_lump := i;
      break;
    end;
  end;

  inc(lumpnum);
  crc32 := W_LumpCRC32(lumpnum);

  wadfilemap := M_SaveFileName('DATA\');
  MkDir(wadfilemap);
  wadfilemap := wadfilemap + 'WADS\';
  MkDir(wadfilemap);
  wadfilemap := wadfilemap + mapname + '_' + crc32 + '.wad';

  converted := udmf_converter.Convert(W_TextLumpNum(lumpnum));
  UDMF_UpdateGlobalStructs(converted);
  UDMF_SaveToVanilla(converted, mapname, wadfilemap, behav_lump, script_lump);
  udmfnamespace := converted.Namespace;
  udmflinetranslate := (udmfnamespace <> strupper(_GAME)) and (udmfnamespace <> 'ZDOOMTRANSLATED');

  W_RuntimeLoad(wadfilemap, F_ORIGIN_WAD);

  result := true;
  hasudmfdata := true;
end;

//==============================================================================
//
// P_ConfigureUdmfApply
//
//==============================================================================
procedure P_ConfigureUdmfApply(const ASectors, ALines, ASides, ASegs: IUdmfMapPartApplier);
begin
  udmf_sectorapplier := ASectors;
  udmf_lineapplier := ALines;
  udmf_sideapplier := ASides;
  udmf_segapplier := ASegs;
end;

//==============================================================================
//
// UDMF_ApplyPart
//
//==============================================================================
function UDMF_ApplyPart(const what: string; const applier: IUdmfMapPartApplier): boolean;
begin
  if applier = nil then
    I_Error('UDMF_Make%s(): P_ConfigureUdmfApply() has not been called', [what]);
  result := applier.Apply;
end;

//==============================================================================
//
// UDMF_MakeSectors
//
//==============================================================================
function UDMF_MakeSectors: boolean;
begin
  result := UDMF_ApplyPart('Sectors', udmf_sectorapplier);
end;

//==============================================================================
//
// UDMF_MakeLines
//
//==============================================================================
function UDMF_MakeLines: boolean;
begin
  result := UDMF_ApplyPart('Lines', udmf_lineapplier);
end;

//==============================================================================
//
// UDMF_MakeSides
//
//==============================================================================
function UDMF_MakeSides: boolean;
begin
  result := UDMF_ApplyPart('Sides', udmf_sideapplier);
end;

//==============================================================================
//
// UDMF_MakeSegs
//
//==============================================================================
function UDMF_MakeSegs: boolean;
begin
  result := UDMF_ApplyPart('Segs', udmf_segapplier);
end;

end.
