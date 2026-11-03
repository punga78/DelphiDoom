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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Node builder (glbsp wrapper)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit nd_main;

interface

uses
  d_delphi,
  doomdata,
  r_defs,
  m_fixed;

var
  glnodesver: integer = 0;

const
  gNd2 = $32644E67;
  gNd3 = $33644E67;
  gNd4 = $34644E67;
  gNd5 = $35644E67;
  ZNOD = $444F4E5A; // ZDOOM specific, not supported
  ZGLN = $4E4C475A; // ZDOOM specific, not supported

type
  glmaplumpdesc_t = (
    ML_GL_LABEL,  // A separator name, GL_ExMx or GL_MAPxx
    ML_GL_VERTS,  // Extra Vertices
    ML_GL_SEGS,   // Segs, from linedefs & minisegs
    ML_GL_SSECT,  // SubSectors, list of segs
    ML_GL_NODES,  // GL BSP nodes
    ML_GL_PVS     // Vavoom Engine GL_PVS
  );

// JVAL: glBSP GLVertex structures
//
// LUMP GL_VERT
// This lump contains extra vertices that are needed by the GL BSP tree. Often a
// GL seg will begin and/or end someplace where there isn't a normal vertex (in
// the VERTEXES lump), and these GL vertices are stored here.
//
// The V1 format of GL_VERT is the same as the normal VERTEXES lump.
//
// Version 2 of these specs introduces a new format for GL_VERT. The new format
// is distinguished from the old format by a 4-byte magic identifier at offset 0,
// namely: "gNd2". Following the magic ID are the vertices, each vertex is just
// two 32-bit integers for X and Y (actually 16.16 fixed point).
//
// Version 5 of these specs does not change the format of GL_VERT, but the magic
// identifier at offset 0 will be "gNd5" to indicate the presence of V5 GL nodes
// (and hence the format of the other GL lumps).

type
  GLVertex1_t = record
    x: smallint;
    y: smallint;
  end;
  PGLVertex1_t = ^GLVertex1_t;
  GLVertex1_tArray = array[0..$FFFF] of GLVertex1_t;
  PGLVertex1_tArray = ^GLVertex1_tArray;

  GLVertex2_t = record
    x: fixed_t;
    y: fixed_t;
  end;
  PGLVertex2_t = ^GLVertex2_t;
  GLVertex2_tArray = array[0..$FFFF] of GLVertex2_t;
  PGLVertex2_tArray = ^GLVertex2_tArray;

  GLVertex_t = ^GLVertex2_t;
  PGLVertex_t = ^GLVertex_t;
  GLVertex_tArray = array[0..$FFFF] of GLVertex_t;
  PGLVertex_tArray = ^GLVertex_tArray;

// JVAL: glBSP GLSeg structures
//
// LUMP GL_SEGS
//
// The GL_SEGS lump defines all the GL segs, which form the boundaries of each
// GL subsector. The format is different to the usual SEGS lump, but should look
// pretty familiar:
//
// struct GLSeg1
// {
//   unsigned short start_vertex;
//   unsigned short end_vertex;
//   unsigned short linedef;
//   unsigned short side;
//   unsigned short partner_seg;
// }
// #define VERT_IS_GL (1 << 15)

// The start and end vertex values define precisely where the seg lies. There is
// no 'offset' or 'angle' fields like in the normal SEGS lump, it is assumed
// that the engine can trivially compute these. Bit 15 plays a special role:
// when 0, the vertex is a normal one (from VERTEXES), when 1 the vertex is a
// GL vertex (from GL_VERT lump).

// The linedef number is the linedef that the seg lies along, or 0xFFFF if the
// seg does not lie along any linedef. Those segs are called "minisegs", since
// they are never drawn by the engine, they only serve to mark the boundary of
// the subsector (for creating plane polygons).

// The side number is 0 if the seg lies along the RIGHT side of the linedef,
// or 1 if the seg lies along the LEFT side. This is the same as the 'direction'
// field in the normal SEGS lump. Ignored for minisegs.

// The partner seg needs some explanation. For segs that lie along a one-sided
// linedef, this field is simply 0xFFFF. Otherwise this field contains the index
// for the GL seg in the adjacent subsector which borders on the current seg.
// There is guaranteed to be a one-to-one correspondence between the segs that
// lie on either side of the border between any two subsectors. A corollary is
// that a seg's start vertex is the same as its partner's end vertex, and vice
// versa.

// Version 3 of these specs introduces a new format for GL_SEGS. The new format is distinguished from the old format by a 4-byte magic identifier at offset 0, namely: "gNd3". After the magic ID are the segs, and each seg has this format:

// struct GLSeg3
// {
//    unsigned int start_vertex;
//    unsigned int end_vertex;
//    unsigned short linedef;
//    unsigned short side;
//    unsigned int partner_seg;
// }
// #define VERT_IS_GL (1 << 30)

// Bit 30 of the vertex number is used to indicate a GL Vertex (instead of bit
// 15 as in V1).

// Version 5 of these specs introduces a small change to the V3 format. The main
// difference is that there is no magic ID at the start of the lump, you must
// check the GL_VERT lump instead. Each seg has this format:

// struct GLSeg5
// {
//    unsigned int start_vertex;
//    unsigned int end_vertex;
//    unsigned short linedef;
//    unsigned short side;
//    unsigned int partner_seg;
// }
// #define VERT_IS_GL (1 << 31)

// Bit 31 of the vertex number is used to indicate a GL Vertex (instead of bit
// 30 as in V3).

// An Engine may use the same code to read both V3 and V5 segs by checking the
// top two bits of the vertex number (for a GL vertex), and clearing both bits
// to get the index. Builders, however, must take care to set the correct bit.

type
  GLSeg1_t = record
    start_vertex: word;
    end_vertex: word;
    linedef: word;
    side: word;
    partner_seg: word;
  end;
  PGLSeg1_t = ^GLSeg1_t;
  GLSeg1_tArray = array[0..$FFFF] of GLSeg1_t;
  PGLSeg1_tArray = ^GLSeg1_tArray;

  GLSeg3_t = record
    start_vertex: LongWord;
    end_vertex: LongWord;
    linedef: word;
    side: word;
    partner_seg: LongWord;
  end;
  PGLSeg3_t = ^GLSeg3_t;
  GLSeg3_tArray = array[0..$FFFF] of GLSeg3_t;
  PGLSeg3_tArray = ^GLSeg3_tArray;

  GLSeg_t = GLSeg3_t;
  PGLSeg_t = ^GLSeg_t;
  GLSeg_tArray = array[0..$FFFF] of GLSeg_t;
  PGLSeg_tArray = ^GLSeg_tArray;

// JVAL: glBSP GLSubSector structures
// LUMP GL_SSECT
//
// This lump contains the info for all GL subsectors. Each GL subsector is made
// up of a sequence of GL segs (defined in the GL_SEGS lump).
//
// The GL_SSECT lump has some important properties that the usual SSECTORS lump
// does not have:
//
//    1. All edges of the subsector are included, even those that do not lie
// along linedefs (i.e. the minisegs).
//
//    2. There is a strict ordering: all the segs are in clockwise order (when
// looking from above). In other words: one seg's start vertex is the same as
// the previous seg's end vertex.
//
//    3. The subsector must be closed: i.e. all the segs form a continuous path,
// and the last seg's end vertex is the same as the first seg's start vertex.
//
// The V1 format of GL_SSECT is the same as the normal SSECTORS lump, reproduced
// here for convenience:
//
// struct SubSector1
// {
//    unsigned short count;
//    unsigned short first_seg;
// }
//
// Version 3 of these specs introduces a new format for GL_SSECT. The new format
// is distinguished from the old format by a 4-byte magic identifier at offset 0,
// namely: "gNd3". It's just like the old format except that 32-bit values are
// used for everything (the seg count and first seg number) instead of 16-bit
// values, as shown below:
//
// struct GLSubSector3
// {
//    unsigned int count;
//    unsigned int first_seg;
// }
//
// Version 5 of these specs introduces a small change to the V3 format. The only
// difference is that there is no magic ID at the start of the lump, you must
// check the GL_VERT lump instead.

type
  GLSubSector1_t = record
   count: word;
   first_seg: word;
  end;
  PGLSubSector1_t = ^GLSubSector1_t;
  GLSubSector1_tArray = array[0..$FFFF] of GLSubSector1_t;
  PGLSubSector1_tArray = ^GLSubSector3_tArray;

  GLSubSector3_t = record
   count: LongWord;
   first_seg: LongWord;
  end;
  PGLSubSector3_t = ^GLSubSector3_t;
  GLSubSector3_tArray = array[0..$FFFF] of GLSubSector3_t;
  PGLSubSector3_tArray = ^GLSubSector3_tArray;

// JVAL: glBSP GLNode structures
// LUMP GL_NODES
//
// The GL_NODES lump contains the information for the GL BSP tree. An important property which the normal NODES lump lacks is that the bounding boxes are guaranteed to cover the whole subsector, not just the segs that lie along linedefs (as happens with NODES).
//
// The format of GL_NODES is the same as the normal NODES lump, reproduced here for convenience:
//
// struct Node1
// {
//    short x; // partition line
//    short y;
//    short dx;
//    short dy;
//    short right_bbox[4];
//    short left_bbox[4];
//    unsigned short right_child;
//    unsigned short left_child;
// }
// #define CHILD_IS_SUBSEC (1 << 15)
//
// Version 5 of these specs introduces a new format for GL_NODES which makes the child indices 32-bits instead of 16-bits. Each node has the following new format:
//
// struct GLNode4
// {
//    short x; // partition line
//    short y;
//    short dx;
//    short dy;
//    short right_bbox[4];
//    short left_bbox[4];
//    unsigned int right_child;
//    unsigned int left_child;
// }
// #define CHILD_IS_SUBSEC (1 << 31)

type
  GLNode1_t = record
    x: smallint; // partition line
    y: smallint;
    dx: smallint;
    dy: smallint;
    right_bbox: packed array[0..3] of smallint;
    left_bbox: packed array[0..3] of smallint;
    right_child: word;
    left_child: word;
  end;
  PGLNode1_t = ^GLNode1_t;
  GLNode1_tArray = array[0..$FFFF] of GLNode1_t;
  PGLNode1_tArray = ^GLNode1_tArray;

  GLNode4_t = record
    x: smallint; // partition line
    y: smallint;
    dx: smallint;
    dy: smallint;
    right_bbox: packed array[0..3] of smallint;
    left_bbox: packed array[0..3] of smallint;
    right_child: LongWord;
    left_child: LongWord;
  end;
  PGLNode4_t = ^GLNode4_t;
  GLNode4_tArray = array[0..$FFFF] of GLNode4_t;
  PGLNode4_tArray = ^GLNode4_tArray;

  GLNode_t = GLNode4_t;
  PGLNode_t = ^GLNode_t;
  GLNode_tArray = array[0..$FFFF] of GLNode_t;
  PGLNode_tArray = ^GLNode_tArray;

//==============================================================================
//
// gld_GetGLNodesVersion
//
//==============================================================================
function gld_GetGLNodesVersion(const base: integer): integer;

//==============================================================================
//
// gld_GetGLVertexes
//
//==============================================================================
procedure gld_GetGLVertexes(v: Pvertex_t; lump: integer; count: integer; ver: integer);

//==============================================================================
//
// gld_GetGLMapLump
//
//==============================================================================
function gld_GetGLMapLump(const maplump: integer): integer;

//==============================================================================
//
// gld_BuildNodes
//
//==============================================================================
function gld_BuildNodes(const wadfile, gwafile: string): boolean;

//==============================================================================
//
// ND_GetNodes
//
//==============================================================================
function ND_GetNodes(const mapname: string): string;

type
  TGWAFile = class
  private
    ffilename: string;
    fnumglvertexes: integer;
    fglvertexes: PGLVertex2_tArray;
    fnummapsubsectors: integer;
    fmapsubsectors: PGLSubSector3_tArray;
    fnummapnodes: integer;
    fmapnodes: PGLNode4_tArray;
    fnummapsegs: integer;
    fmapsegs: PGLSeg3_tArray;
  public
    constructor Create(const afilename: string); virtual;
    destructor Destroy; override;
    property filename: string read ffilename;
    property numglvertexes: integer read fnumglvertexes;
    property glvertexes: PGLVertex2_tArray read fglvertexes;
    property nummapsubsectors: integer read fnummapsubsectors;
    property mapsubsectors: PGLSubSector3_tArray read fmapsubsectors;
    property nummapnodes: integer read fnummapnodes;
    property mapnodes: PGLNode4_tArray read fmapnodes;
    property nummapsegs: integer read fnummapsegs;
    property mapsegs: PGLSeg3_tArray read fmapsegs;
  end;

//==============================================================================
//
// ND_LoadVertexes
//
//==============================================================================
procedure ND_LoadVertexes(lump: integer; gwa: TGWAFile);

//==============================================================================
//
// ND_LoadSubsectors
//
//==============================================================================
procedure ND_LoadSubsectors(gwa: TGWAFile);

//==============================================================================
//
// ND_LoadNodes
//
//==============================================================================
procedure ND_LoadNodes(gwa: TGWAFile);

//==============================================================================
//
// ND_LoadSegs
//
//==============================================================================
procedure ND_LoadSegs(gwa: TGWAFile);

//==============================================================================
//
// ND_NodesCheck
//
//==============================================================================
procedure ND_NodesCheck(const lumpname: string);

implementation

uses
  acs,
  m_crc32,
  i_tmp,
  i_exec,
  DelphiDoom.Glbsp.Intf,
  DelphiDoom.Glbsp.Client,
  DelphiDoom.Glbsp.Provider,
  i_system,
  p_setup,
  w_wad,
  m_misc,
  m_argv,
  r_main,
  z_zone;

//==============================================================================
// gld_GetGLNodesVersion
//
// JVAL
//  Returns the glbsp nodes version.
//
//==============================================================================
function gld_GetGLNodesVersion(const base: integer): integer;
var
  data: pointer;
begin
  if base + 4 > W_NumLumps then
  begin
    result := 0;
    exit;
  end;

  if base < 0 then
  begin
    result := 0;
    exit;
  end;

  if (strupper(char8tostring(W_GetNameForNum(base + Ord(ML_GL_VERTS)))) <> 'GL_VERT') or
     (strupper(char8tostring(W_GetNameForNum(base + Ord(ML_GL_SEGS)))) <> 'GL_SEGS') or
     (strupper(char8tostring(W_GetNameForNum(base + Ord(ML_GL_SSECT)))) <> 'GL_SSECT') or
     (strupper(char8tostring(W_GetNameForNum(base + Ord(ML_GL_NODES)))) <> 'GL_NODES') then
  begin
    result := 0;
    exit;
  end;

  data := W_CacheLumpNum(base + Ord(ML_GL_VERTS), PU_STATIC);
  if PLongWord(data)^ = gNd2 then
  begin
    Z_ChangeTag(data, PU_CACHE);
    data := W_CacheLumpNum(base + Ord(ML_GL_SEGS), PU_STATIC);
    if PLongWord(data)^ = gNd3 then
      result := 3
    else
      result := 2;
    printf('gld_GetGLNodesVersion(): GL v%d nodes found.'#13#10, [result]);
    Z_ChangeTag(data, PU_CACHE);
    exit;
  end;

  if PLongWord(data)^ = gNd4 then
  begin
    Z_ChangeTag(data, PU_CACHE);
    result := 4;
    printf('gld_GetGLNodesVersion(): GL v%d nodes found.'#13#10, [result]);
    exit;
  end;

  if PLongWord(data)^ = gNd5 then
  begin
    Z_ChangeTag(data, PU_CACHE);
    result := 5;
    printf('gld_GetGLNodesVersion(): GL v%d nodes found.'#13#10, [result]);
    exit;
  end;

  Z_ChangeTag(data, PU_CACHE);
  result := 0;
end;

//==============================================================================
//
// gld_GetGLVertexes
//
//==============================================================================
procedure gld_GetGLVertexes(v: Pvertex_t; lump: integer; count: integer; ver: integer);
var
  i: integer;
  data: pointer;
  glvert1: PGLVertex1_t;
  glvert2: PGLVertex2_t;
begin
  if (count = 0) or (ver = 0) then
    exit;

  data := W_CacheLumpNum(lump, PU_STATIC);
  if ver = 1 then
  begin
    glvert1 := data;
    for i := 0 to count - 1 do
    begin
      v.x := glvert1.x shl FRACBITS;
      v.y := glvert1.y shl FRACBITS;
      inc(v);
      inc(glvert1);
    end;
  end
  else
  begin
    glvert2 := PGLVertex2_t(integer(data) + 4);
    for i := 0 to count - 1 do
    begin
      v.x := glvert2.x;
      v.y := glvert2.y;
      inc(v);
      inc(glvert2);
    end;
  end;
  Z_Free(data);
end;

//
// GetMapAdler32()
// JVAL: Compute Adler-32 checksum
const
  MOD_ADLER = 65521;

//==============================================================================
//
// GetMapAdler32
//
//==============================================================================
function GetMapAdler32(maplump: integer): LongWord;
var
  data: PByteArray;
  A, B: LongWord;
  len: integer;

  procedure Adler32Loop(lump: integer);
  var
    b1, b2: PByte;
  begin
    data := W_CacheLumpNum(lump, PU_STATIC);
    len := W_LumpLength(lump);
    b1 := @data[0];
    b2 := @data[len];
    while b1 <> b2 do
    begin
      A := (A + b1^) mod MOD_ADLER;
      B := (B + A) mod MOD_ADLER;
      inc(b1);
    end;
    Z_ChangeTag(data, PU_CACHE);
  end;

begin
  A := 1;
  B := 0;

  Adler32Loop(maplump + Ord(ML_VERTEXES));
  Adler32Loop(maplump + Ord(ML_LINEDEFS));

  result := B * 65536 + A;

end;

//==============================================================================
//
// GetGLMapAdler32
// JVAL: This function returns the Adler-32 value of glBSP utility
//
//==============================================================================
function GetGLMapAdler32(glmaplump: integer; glmapname: string): LongWord;
var
  txt: string;
  sglinf: TDStringList;
  stmp: string;
  i: integer;
  s1, s2: string;
  check: boolean;
begin
  txt := W_TextLumpNum(glmaplump);

  sglinf := TDStringList.Create;

  stmp := '';

  for i := 1 to Length(txt) do
  begin
    if txt[i] in [#10, #13] then
    begin
      if stmp <> '' then
      begin
        sglinf.Add(stmp);
        stmp := '';
      end;
    end
    else
      stmp := stmp + toupper(txt[i]);
  end;
  if stmp <> '' then
    sglinf.Add(stmp);

  result := 0;
  check := strupper(glmapname) = strupper(char8tostring(W_GetNameForNum(glmaplump)));
  for i := 0 to sglinf.Count - 1 do
  begin
    splitstring_ch(sglinf.Strings[i], s1, s2, '=');
    if s1 = 'CHECKSUM' then
      result := atoui(s2)
    else if not check and (s1 = 'MAPNAME') then
    begin // Wrong map!
      check := (strupper(glmapname) = strupper(s2)) or (strupper(glmapname) = 'GL_' + strupper(s2));
      if not check then
        break;
    end;
  end;

  sglinf.Free;

  if not check then
    result := 0;
end;

//==============================================================================
//
// gld_GetGLMapLump
//
//==============================================================================
function gld_GetGLMapLump(const maplump: integer): integer;
var
  adler32: LongWord;
  glmapname: string;
  glmapname8: name8_t;
  defglmapname8: name8_t;
  glmaplump: integer;
  i: integer;
begin
  adler32 := GetMapAdler32(maplump);
  if adler32 = 0 then // JVAL: unused?
  begin
    result := -1;
    exit;
  end;

  glmapname8.s := W_GetNameForNum(maplump);
  glmapname := 'GL_' + char8tostring(glmapname8.s);
  if Length(glmapname) <= 8 then
  begin
  // Check the first lump to find
    glmaplump := W_CheckNumForName(glmapname);
    if GetGLMapAdler32(glmaplump, glmapname) = adler32 then
    begin
      result := glmaplump;
      exit;
    end;
  // Check all the lumps after the map
    for i := maplump + Ord(ML_BLOCKMAP) + 1 to W_NumLumps - 1 do
      if (lumpinfo[i].v1 = glmapname8.x[0]) and
         (lumpinfo[i].v2 = glmapname8.x[1]) then
        if i <> glmaplump then // We've already checked this!
        begin
          if GetGLMapAdler32(i, glmapname) = adler32 then
          begin
            result := i;
            exit;
          end;
        end;
  end;

  // Check for GL_LEVEL lumps
  defglmapname8.s := stringtochar8('GL_LEVEL');
  for i := 0 to W_NumLumps - 1 do
    if (lumpinfo[i].v1 = glmapname8.x[0]) and
       (lumpinfo[i].v2 = glmapname8.x[1]) then
      begin
        if GetGLMapAdler32(i, glmapname) = adler32 then
        begin
          result := i;
          exit;
        end;
      end;

  // No luck so far? Look for the lumps previous to map
  // Check all the lumps after the map
  for i := 0 to maplump - 1 do
    if (lumpinfo[i].v1 = glmapname8.x[0]) and
       (lumpinfo[i].v2 = glmapname8.x[1]) then
      begin
        if GetGLMapAdler32(i, glmapname) = adler32 then
        begin
          result := i;
          exit;
        end;
      end;

  result := -1;
end;

//==============================================================================
//
// ND_RunGlbsp
//
// Runs the node builder; what it prints goes to the log, as it did when the
// program was started from the engine
//
//==============================================================================
function ND_RunGlbsp(const wadfile, gwafile: string;
  const options: TGlbspOptions): boolean;
begin
  try
    TGlbspProvider.Client.BuildNodes(wadfile, gwafile, options,
      GLBSP_MAX_TIMEOUT_MS);
    result := True;
  except
    on E: EGlbspException do
    begin
      result := False;
      printf('%s'#13#10, [E.Message]);
    end;
  end;
  if TGlbspProvider.Client.Output <> '' then
    printf('%s', [TGlbspProvider.Client.Output]);
end;

//==============================================================================
//
// gld_BuildNodes
//
//==============================================================================
function gld_BuildNodes(const wadfile, gwafile: string): boolean;
begin
  printf(#13#10'  gld_BuildNodes: Building GL-Friendly nodes for %s'#13#10, [wadfile]);
  result := ND_RunGlbsp(wadfile, gwafile, [goQuiet, goNoProgress
    {$IFDEF HEXEN}, goHexen{$ENDIF}]);
  printf(#13#10);
  if not result then
    I_Warning('gld_BuildNodes(): Failed to build GL-Friendly nodes for %s'#13#10, [wadfile]);
end;

//==============================================================================
//
// HextW
//
//==============================================================================
function HextW(w: Word): string;
const
  h: array[0..15] of Char = '0123456789abcdef';
begin
  result := h[Hi(w) shr 4] + h[Hi(w) and $F] + h[Lo(w) shr 4] + h[Lo(w) and $F];
end;

//==============================================================================
//
// HextL
//
//==============================================================================
function HextL(l: Longint): string;
type
  Long = record
    LoWord: Word;
    HiWord: Word;
  end;
begin
  with Long(l) do
    result := HextW(HiWord) + HextW(LoWord);
end;

{$IFNDEF HEXEN}
type
  hexenmapthing_t = record
    tid: smallint;
    x: smallint;
    y: smallint;
    height: smallint;
    angle: smallint;
    _type: word;
    options: smallint;
    special: byte;
    arg1: byte;
    arg2: byte;
    arg3: byte;
    arg4: byte;
    arg5: byte;
  end;
  Phexenmapthing_t = ^hexenmapthing_t;
  hexenmapthing_tArray = array[0..$FFFF] of hexenmapthing_t;
  Phexenmapthing_tArray = ^hexenmapthing_tArray;

  hexenmaplinedef_t = record
    v1: smallint;
    v2: smallint;
    flags: smallint;
    special: byte;
    arg1: byte;
    arg2: byte;
    arg3: byte;
    arg4: byte;
    arg5: byte;
  // sidenum[1] will be -1 if one sided
    sidenum: array[0..1] of smallint;
  end;
  Phexenmaplinedef_t = ^hexenmaplinedef_t;
  hexenmaplinedef_tArray = array[0..$FFFF] of hexenmaplinedef_t;
  Phexenmaplinedef_tArray = ^hexenmaplinedef_tArray;
{$ENDIF}

//==============================================================================
//
// ND_GetNodes
//
//==============================================================================
function ND_GetNodes(const mapname: string): string;
var
  header: wadinfo_t;
  lump, maplump: integer;
  i, len: integer;
  f: TFile;
  adler32: LongWord;
  path: string;
  mapfilename: string;
  gwafilename: string;
  infotable: array[0..11] of filelump_t;
  ninfolumps: integer;
  buf: PByteArray;
  hasbehavior: boolean;
{$IFNDEF HEXEN}
  x: integer;
  hlen: integer;
  vthings: Pmapthing_tArray;
  hthings: Phexenmapthing_tArray;
  nthings: integer;
  vlinedefs: Pmaplinedef_tArray;
  hlinedefs: Phexenmaplinedef_tArray;
  nlinedefs: integer;
{$ENDIF}
begin
  maplump := W_GetNumForName(mapname);
  if M_CheckParm('-devparm') <> 0 then printf('    ND_GetNodes: maplump'#13#10);
  adler32 := GetMapAdler32(maplump);
  if M_CheckParm('-devparm') <> 0 then printf('    ND_GetNodes: adler32'#13#10);

  path := M_SaveFileName('DATA\');
  MkDir(path);
  path := path + 'BSP\';
  if M_CheckParm('-devparm') <> 0 then printf('    ND_GetNodes: path'#13#10);
  MkDir(path);

  gwafilename := fexpand(path + mapname + '_' + HextL(adler32) + '.gwa');
  if M_CheckParm('-devparm') <> 0 then printf('    ND_GetNodes: gwafilename'#13#10);

  if not fexists(gwafilename) then
  begin
    mapfilename := I_NewTempFile(mapname + '_' + HextL(adler32) + '.wad');
    if M_CheckParm('-devparm') <> 0 then printf('    ND_GetNodes: tempfile'#13#10);

    header.identification :=
      integer(Ord('P') or (Ord('W') shl 8) or (Ord('A') shl 16) or (Ord('D') shl 24));

    hasbehavior := acc_isbehaviorlump(maplump + Ord(ML_BEHAVIOR));
    if hasbehavior then
      ninfolumps := 12
    else
      ninfolumps := 11;
    header.numlumps := {$IFDEF HEXEN}12{$ELSE}ninfolumps{$ENDIF};

    if M_CheckParm('-devparm') <> 0 then printf('    ND_GetNodes: create'#13#10);
    f := TFile.Create(mapfilename, fCreate);
    f.Write(header, SizeOf(header));

    ZeroMemory(@infotable, SizeOf(infotable));

    for i := 0 to ninfolumps - 1 do
    begin
      lump := maplump + i;
      if lump >= W_NumLumps then
        Break;

      len := W_LumpLength(lump);
      if M_CheckParm('-devparm') <> 0 then printf('    ND_GetNodes: lump %d'#13#10, [i]);

      infotable[i].filepos := f.Position;
      infotable[i].name := lumpinfo[lump].name;

      {$IFNDEF HEXEN}
      if hasbehavior and (i = Ord(ML_THINGS)) then
      begin
        vthings := malloc(len);
        W_ReadLump(lump, vthings);
        nthings := len div SizeOf(mapthing_t);
        hlen := nthings * SizeOf(hexenmapthing_t);
        hthings := malloc(hlen);
        for x := 0 to nthings - 1 do
        begin
          hthings[x].tid := 0;
          hthings[x].x := vthings[x].x;
          hthings[x].y := vthings[x].y;
          hthings[x].height := 0;
          hthings[x].angle := vthings[x].angle;
          hthings[x]._type := vthings[x]._type;
          hthings[x].options := vthings[x].options;
          hthings[x].special := 0;
          hthings[x].arg1 := 0;
          hthings[x].arg2 := 0;
          hthings[x].arg3 := 0;
          hthings[x].arg4 := 0;
          hthings[x].arg5 := 0;
        end;
        infotable[i].size := hlen;
        f.Write(hthings^, hlen);
        memfree(pointer(vthings), len);
        memfree(pointer(hthings), hlen);
      end
      else if hasbehavior and (i = Ord(ML_LINEDEFS)) then
      begin
        vlinedefs := malloc(len);
        W_ReadLump(lump, vlinedefs);
        nlinedefs := len div SizeOf(maplinedef_t);
        hlen := nlinedefs * SizeOf(hexenmaplinedef_t);
        hlinedefs := malloc(hlen);
        for x := 0 to nlinedefs - 1 do
        begin
          hlinedefs[x].v1 := vlinedefs[x].v1;
          hlinedefs[x].v2 := vlinedefs[x].v2;
          hlinedefs[x].flags := vlinedefs[x].flags;
          if IsIntegerInRange(vlinedefs[x].special, 0, 255) then
            hlinedefs[x].special := vlinedefs[x].special
          else
            hlinedefs[x].special := 0;
          hlinedefs[x].arg1 := 0;
          hlinedefs[x].arg2 := 0;
          hlinedefs[x].arg3 := 0;
          hlinedefs[x].arg4 := 0;
          hlinedefs[x].arg5 := 0;
          // sidenum[1] will be -1 if one sided
          hlinedefs[x].sidenum[0] := vlinedefs[x].sidenum[0];
          hlinedefs[x].sidenum[1] := vlinedefs[x].sidenum[1];
        end;
        infotable[i].size := hlen;
        f.Write(hlinedefs^, hlen);
        memfree(pointer(vlinedefs), len);
        memfree(pointer(hlinedefs), hlen);
      end
      else
      {$ENDIF}
      begin
        infotable[i].size := len;

        buf := malloc(len);
        W_ReadLump(lump, buf);
        f.Write(buf^, len);
        memfree(pointer(buf), len);
      end;
    end;

    {$IFDEF HEXEN}
    if not hasbehavior then
    begin
      infotable[11].filepos := 0;
      infotable[11].size := 0;
      infotable[11].name := stringtochar8('BEHAVIOR');
    end;
    {$ENDIF}

    header.infotableofs := f.Position;
    f.Write(infotable, header.numlumps * SizeOf(filelump_t));
    f.Seek(0, sFromBeginning);
    f.Write(header, SizeOf(header));
    f.Free;

    if M_CheckParm('-devparm') <> 0 then printf('    ND_GetNodes: buildnodes'#13#10);
    gld_BuildNodes(mapfilename, gwafilename);

    if not fexists(gwafilename) then
    begin
      result := '';
      exit;
    end;
  end;

  result := gwafilename;
end;

var
  firstglvert: integer;

//==============================================================================
//
// TGWAFile.Create
//
//==============================================================================
constructor TGWAFile.Create(const afilename: string);
var
  f: TFile;
  h: wadinfo_t;
  infotable: array[0..9] of filelump_t;
  i, j: integer;
  ver, ver2: LongWord;
  seg1: GLSeg1_t;
  node1: GLNode1_t;
  subsector1: GLSubSector1_t;
begin
  ffilename := afilename;
  f := TFile.Create(ffilename, fOpenReadOnly);
  f.Read(h, SizeOf(wadinfo_t));
  if (h.numlumps > 10) or (h.numlumps < 1) then
  begin
    f.Free;
    I_Error('TGWAFile.Create(): Standalone GWA constains %d lumps', [h.numlumps]);
    Exit;
  end;

  f.Seek(h.infotableofs, sFromBeginning);
  f.Read(infotable, h.numlumps * SizeOf(filelump_t));

  fnumglvertexes := 0;
  fglvertexes := nil;
  fnummapsubsectors := 0;
  fmapsubsectors := nil;
  fnummapnodes := 0;
  fmapnodes := nil;
  fnummapsegs := 0;
  fmapsegs := nil;

  ver := 0;
  for i := 0 to h.numlumps - 1 do
  begin
    if strupper(char8tostring(infotable[i].name)) = 'GL_VERT' then
    begin
      f.Seek(infotable[i].filepos, sFromBeginning);
      f.Read(ver, SizeOf(ver));
    end
    else if strupper(char8tostring(infotable[i].name)) = 'GL_SEGS' then
    begin
      f.Seek(infotable[i].filepos, sFromBeginning);
      f.Read(ver2, SizeOf(ver2));
      if ver2 = gNd3 then
        ver := gNd3;
    end;
  end;

  if ver = gNd2 then
    glnodesver := 2
  else if ver = gNd3 then
    glnodesver := 3
  else if ver = gNd4 then
    glnodesver := 4
  else if ver = gNd5 then
    glnodesver := 5
  else
    glnodesver := 0;

  printf('TGWAFile.Create(): GL v%d nodes found.'#13#10, [glnodesver]);

  for i := 0 to h.numlumps - 1 do
  begin
    if strupper(char8tostring(infotable[i].name)) = 'GL_VERT' then
    begin
      if glnodesver > 0 then
      begin
        f.Seek(infotable[i].filepos + 4, sFromBeginning);
        fnumglvertexes := (infotable[i].size - 4) div SizeOf(GLVertex2_t);
      end
      else
        fnumglvertexes := infotable[i].size div SizeOf(GLVertex2_t);
      fglvertexes := malloc(fnumglvertexes * SizeOf(GLVertex2_t));
      f.Read(fglvertexes^, fnumglvertexes * SizeOf(GLVertex2_t));
    end
    else if strupper(char8tostring(infotable[i].name)) = 'GL_SSECT' then
    begin
      f.Seek(infotable[i].filepos, sFromBeginning);
      if glnodesver >= 3 then
      begin
        if glnodesver = 3 then
        begin
          fnummapsubsectors := (infotable[i].size - 4) div SizeOf(GLSubSector3_t);
          f.Seek(infotable[i].filepos + 4, sFromBeginning);
        end
        else
          fnummapsubsectors := infotable[i].size div SizeOf(GLSubSector3_t);
        fmapsubsectors := malloc(fnummapsubsectors * SizeOf(GLSubSector3_t));
        f.Read(fmapsubsectors^, fnummapsubsectors * SizeOf(GLSubSector3_t));
      end
      else
      begin
        fnummapsubsectors := infotable[i].size div SizeOf(GLSubSector1_t);
        fmapsubsectors := malloc(fnummapsubsectors * SizeOf(GLSubSector3_t));
        for j := 0 to fnummapsubsectors - 1 do
        begin
          f.Read(subsector1, SizeOf(GLSubSector1_t));
          fmapsubsectors[j].count := subsector1.count;
          fmapsubsectors[j].first_seg := subsector1.first_seg;
        end;
      end;
    end
    else if strupper(char8tostring(infotable[i].name)) = 'GL_NODES' then
    begin
      f.Seek(infotable[i].filepos, sFromBeginning);
      if glnodesver >= 4 then
      begin
        fnummapnodes := infotable[i].size div SizeOf(GLNode4_t);
        fmapnodes := malloc(fnummapnodes * SizeOf(GLNode4_t));
        f.Read(fmapnodes^, fnummapnodes * SizeOf(GLNode4_t));
      end
      else
      begin
        fnummapnodes := infotable[i].size div SizeOf(GLNode1_t);
        fmapnodes := malloc(fnummapnodes * SizeOf(GLNode4_t));
        for j := 0 to fnummapnodes - 1 do
        begin
          f.Read(node1, SizeOf(GLNode1_t));
          fmapnodes[j].x := node1.x;
          fmapnodes[j].y := node1.y;
          fmapnodes[j].dx := node1.dx;
          fmapnodes[j].dy := node1.dy;
          fmapnodes[j].right_bbox[0] := node1.right_bbox[0];
          fmapnodes[j].right_bbox[1] := node1.right_bbox[1];
          fmapnodes[j].right_bbox[2] := node1.right_bbox[2];
          fmapnodes[j].right_bbox[3] := node1.right_bbox[3];
          fmapnodes[j].left_bbox[0] := node1.left_bbox[0];
          fmapnodes[j].left_bbox[1] := node1.left_bbox[1];
          fmapnodes[j].left_bbox[2] := node1.left_bbox[2];
          fmapnodes[j].left_bbox[3] := node1.left_bbox[3];
          if node1.right_child and NF_SUBSECTOR <> 0 then
          begin
            node1.right_child := node1.right_child and not NF_SUBSECTOR;
            fmapnodes[j].right_child := node1.right_child;
            fmapnodes[j].right_child := fmapnodes[j].right_child or NF_SUBSECTOR_V5;
          end
          else
            fmapnodes[j].right_child := node1.right_child;
          if node1.left_child and NF_SUBSECTOR <> 0 then
          begin
            node1.left_child := node1.left_child and not NF_SUBSECTOR;
            fmapnodes[j].left_child := node1.left_child;
            fmapnodes[j].left_child := fmapnodes[j].left_child or NF_SUBSECTOR_V5;
          end
          else
            fmapnodes[j].left_child := node1.left_child;
        end;
      end;
    end
    else if strupper(char8tostring(infotable[i].name)) = 'GL_SEGS' then
    begin
      if glnodesver = 3 then
      begin
        f.Seek(infotable[i].filepos + 4, sFromBeginning);
        fnummapsegs := (infotable[i].size - 4) div SizeOf(GLSeg3_t);
      end
      else
      begin
        f.Seek(infotable[i].filepos, sFromBeginning);
        if glnodesver < 3 then
          fnummapsegs := infotable[i].size div SizeOf(GLSeg1_t)
        else
          fnummapsegs := infotable[i].size div SizeOf(GLSeg3_t);
      end;

      fmapsegs := malloc(fnummapsegs * SizeOf(GLSeg3_t));
      if glnodesver >= 3 then
        f.Read(fmapsegs^, fnummapsegs * SizeOf(GLSeg3_t))
      else
      begin
        for j := 0 to fnummapsegs - 1 do
        begin
          f.Read(seg1, SizeOf(GLSeg1_t));
          fmapsegs[j].start_vertex := seg1.start_vertex;
          fmapsegs[j].end_vertex := seg1.end_vertex;
          fmapsegs[j].linedef := seg1.linedef;
          fmapsegs[j].side := seg1.side;
          fmapsegs[j].partner_seg := seg1.partner_seg;
        end;
      end;
    end;

  end;
  f.Free;
end;

//==============================================================================
//
// TGWAFile.Destroy
//
//==============================================================================
destructor TGWAFile.Destroy;
begin
  memfree(pointer(fglvertexes), fnumglvertexes * SizeOf(GLVertex2_t));
  memfree(pointer(fmapsubsectors), fnummapsubsectors * SizeOf(GLSubSector3_t));
  memfree(pointer(fmapnodes), fnummapnodes * SizeOf(GLNode4_t));
  memfree(pointer(fmapsegs), fnummapsegs * SizeOf(GLSeg3_t));
  inherited;
end;

//==============================================================================
//
// ND_LoadVertexes
//
//==============================================================================
procedure ND_LoadVertexes(lump: integer; gwa: TGWAFile);
var
  data: pointer;
  i: integer;
  ml: Pmapvertex_t;
  li: Pvertex_t;
  numglverts: integer;
  minx: integer;
  maxx: integer;
  miny: integer;
  maxy: integer;
  dx, dy: integer;
begin
  // Determine number of lumps:
  //  total lump length / vertex record length.
  if gwa = nil then
    numglverts := 0
  else
    numglverts := gwa.numglvertexes;

  firstglvert := W_LumpLength(lump) div SizeOf(mapvertex_t);
  numvertexes := firstglvert + numglverts;

  // Allocate zone memory for buffer.
  vertexes := Z_Malloc(numvertexes * SizeOf(vertex_t), PU_LEVEL, nil);

  // Load data into cache.
  data := W_CacheLumpNum(lump, PU_STATIC);

  ml := Pmapvertex_t(data);

  // JVAL: 20200414 -> Find map boundaries
  minx := 100000;
  maxx := -100000;
  miny := 100000;
  maxy := -100000;

  // Copy and convert vertex coordinates,
  // internal representation as fixed.
  li := @vertexes[0];
  for i := 0 to firstglvert - 1 do
  begin
    if ml.x > maxx then
      maxx := ml.x;
    if ml.x < minx then
      minx := ml.x;
    if ml.y > maxy then
      maxy := ml.y;
    if ml.y < miny then
      miny := ml.y;
    li.x := ml.x * FRACUNIT;
    li.y := ml.y * FRACUNIT;
    li.amvalidcount := 0;
    li.interpvalidcount := 0;
    inc(ml);
    inc(li);
  end;

  dx := maxx - minx;
  dy := maxy - miny;

  largemap := (dx < -32767) or (dx > 32767) or (dy < -32767) or (dy > 32767);

  // Free buffer memory.
  Z_Free(data);

  for i := 0 to numglverts - 1 do
  begin
    li.x := gwa.glvertexes[i].x;
    li.y := gwa.glvertexes[i].y;
    li.amvalidcount := 0;
    li.interpvalidcount := 0;
    inc(li);
  end;
end;

//==============================================================================
// ND_LoadSubsectors
//
// P_LoadSubsectors
//
//==============================================================================
procedure ND_LoadSubsectors(gwa: TGWAFile);
var
  i: integer;
  ss: Psubsector_t;
begin
  numsubsectors := gwa.nummapsubsectors;
  subsectors := Z_Malloc(numsubsectors * SizeOf(subsector_t), PU_LEVEL, nil);
  ZeroMemory(subsectors, numsubsectors * SizeOf(subsector_t));

  ss := @subsectors[0];
  for i := 0 to numsubsectors - 1 do
  begin
    ss.numlines :=  gwa.mapsubsectors[i].count;
    ss.firstline := gwa.mapsubsectors[i].first_seg;
    inc(ss);
  end;
end;

//==============================================================================
//
// ND_LoadNodes
//
//==============================================================================
procedure ND_LoadNodes(gwa: TGWAFile);
var
  i: integer;
  k: integer;
  no: Pnode_t;
begin
  numnodes := gwa.nummapnodes;
  nodes := Z_Malloc(numnodes * SizeOf(node_t), PU_LEVEL, nil);
  ZeroMemory(nodes, numnodes * SizeOf(node_t));

  no := @nodes[0];
  for i := 0 to numnodes - 1 do
  begin
    no.x := gwa.mapnodes[i].x * FRACUNIT;
    no.y := gwa.mapnodes[i].y * FRACUNIT;
    no.dx := gwa.mapnodes[i].dx * FRACUNIT;
    no.dy := gwa.mapnodes[i].dy * FRACUNIT;
    no.children[0] := gwa.mapnodes[i].right_child;
    no.children[1] := gwa.mapnodes[i].left_child;
    for k := 0 to 3 do
      no.bbox[0, k] := gwa.mapnodes[i].right_bbox[k] * FRACUNIT;
    for k := 0 to 3 do
      no.bbox[1, k] := gwa.mapnodes[i].left_bbox[k] * FRACUNIT;
    inc(no);
  end;
end;

{$IFDEF OPENGL}

//==============================================================================
//
// gldist
//
//==============================================================================
function gldist(dx, dy: integer): float;
var
  fx, fy: float;
begin
  fx := dx / FRACUNIT;
  fy := dy / FRACUNIT;
  result := sqrt(fx * fx + fy * fy);
end;
{$ENDIF}

//==============================================================================
//
// CheckGLVertex
//
//==============================================================================
function CheckGLVertex(num: integer): integer;
begin
  if glnodesver <= 2 then
  begin
    if num and (1 shl 15) <> 0 then
    begin
      result := num and (1 shl 15 - 1) + firstglvert;
      exit;
    end
  end
  else if glnodesver <= 4 then
  begin
    if num and (1 shl 30) <> 0 then
    begin
      result := num and (1 shl 30 - 1) + firstglvert;
      exit;
    end
  end
  else if glnodesver = 5 then
  begin
    if num and (1 shl 31) <> 0 then
    begin
      result := LongWord(num) and LongWord(_SHLW(1, 31) - 1) + firstglvert;
      exit;
    end
  end;
  result := num;
end;

//==============================================================================
//
// GetOffset
//
//==============================================================================
function GetOffset(v1, v2: Pvertex_t): fixed_t;
var
  a, b: single;
begin
  a := (v1.x - v2.x) / FRACUNIT;
  b := (v1.y - v2.y) / FRACUNIT;
  result := round(sqrt(a * a + b * b) * FRACUNIT);
end;

//==============================================================================
//
// ND_LoadSegs
//
//==============================================================================
procedure ND_LoadSegs(gwa: TGWAFile);
var
  i: integer;
  ml: PGLSeg3_t;
  li: Pseg_t;
  ldef: Pline_t;
  linedef: integer;
  side: integer;
  sidenum: integer;
begin
  numsegs := gwa.nummapsegs;
  segs := Z_Malloc(numsegs * SizeOf(seg_t), PU_LEVEL, nil);
  ZeroMemory(segs, numsegs * SizeOf(seg_t));

  ml := @gwa.mapsegs[0];
  li := @segs[0];
  for i := 0 to numsegs - 1 do
  begin
    li.v1 := @vertexes[CheckGLVertex(ml.start_vertex)];
    li.v2 := @vertexes[CheckGLVertex(ml.end_vertex)];
    {$IFDEF OPENGL}
    li.iSegID := i;
    {$ENDIF}

    if PWord(@ml.linedef)^ = word(1 shl 16 - 1) then
    begin
      li.miniseg := true;
      li.angle := 0;
      li.offset := 0;
      {$IFDEF OPENGL}
      li.length := 0;
      {$ENDIF}
      li.linedef := nil;
      li.sidedef := nil;
      li.frontsector := nil;
      li.backsector := nil;
    end
    else
    begin
      li.miniseg := false;
      li.angle := R_PointToAngle2(li.v1.x, li.v1.y, li.v2.x, li.v2.y);
      linedef := ml.linedef;
      ldef := @lines[linedef];
      if ml.side <> 0 then
        li.offset := GetOffset(li.v1, ldef.v2)
      else
        li.offset := GetOffset(li.v1, ldef.v1);
      li.linedef := ldef;
      side := ml.side;
      li.sidedef := @sides[ldef.sidenum[side]];
      li.frontsector := li.sidedef.sector;
      if ldef.flags and ML_TWOSIDED <> 0 then
      begin
        sidenum := ldef.sidenum[side xor 1];
        if sidenum = -1 then
        begin
          I_Warning('ND_LoadSegs(): Line %d is marked with ML_TWOSIDED flag without backsector'#13#10, [linedef]);
          ldef.flags := ldef.flags and not ML_TWOSIDED;
          li.backsector := nil;
        end
        else
          li.backsector := sides[sidenum].sector;
      end
      else
        li.backsector := nil;
      {$IFDEF OPENGL}
      li.length := gldist(li.v2.x - li.v1.x, li.v2.y - li.v1.y);
      {$ENDIF}
    end;
    inc(ml);
    inc(li);
  end;
end;

//==============================================================================
//
// ND_NodesCheck
//
// Checks is nodes are available in wad map
// If not we will build the nodes.
// This routine allows to load levels without building the nodes (eg slige.out)
//
//==============================================================================
procedure ND_NodesCheck(const lumpname: string);
var
  lumpnum: integer;
  candonodes: boolean;
  has_things, has_lines, has_sides, has_vertexes, has_sectors: integer;
  has_segs, has_ssectors, has_nodes, has_reject, has_blockmap: integer;
  {$IFDEF HEXEN}
  has_behavior: integer;
  {$ENDIF}
  i: integer;
  crc32a, crc32b, crc32c, crc32d: string;
  outfilemap: string;
  wadfilemap: string;
  mapdir: string;
  lname: string;
  f: TFile;
  header: wadinfo_t;
  infotable: array[0..{$IFDEF HEXEN}11{$ELSE}10{$ENDIF}] of filelump_t;
  ldata: PByteArray;
  llen: integer;
begin
  lumpnum := W_GetNumForName(lumpname);
  if (lumpnum < 0) or (lumpnum >= W_NumLumps - 1) then
    exit;

  has_things := -1;
  has_lines := -1;
  has_sides := -1;
  has_vertexes := -1;
  has_sectors := -1;
  has_segs := -1;
  has_ssectors := -1;
  has_nodes := -1;
  has_reject := -1;
  has_blockmap := -1;
  {$IFDEF HEXEN}
  has_behavior := -1;
  {$ENDIF}

  if lumpnum <= W_NumLumps - {$IFDEF HEXEN}11{$ELSE}10{$ENDIF} then
  begin
    for i := 1 to {$IFDEF HEXEN}11{$ELSE}10{$ENDIF} do
    begin
      lname := strupper(char8tostring(W_GetNameForNum(lumpnum + i)));
      // JVAL: 20200222 - Fix bug of continous maps without all assets
      if (has_things = -1) and (lname = 'THINGS') then
        has_things := i
      else if (has_lines = -1) and (lname = 'LINEDEFS') then
        has_lines := i
      else if (has_sides = -1) and (lname = 'SIDEDEFS') then
        has_sides := i
      else if (has_vertexes = -1) and (lname = 'VERTEXES') then
        has_vertexes := i
      else if (has_segs = -1) and (lname = 'SEGS') then
        has_segs := i
      else if (has_ssectors = -1) and (lname = 'SSECTORS') then
        has_ssectors := i
      else if (has_nodes = -1) and (lname = 'NODES') then
        has_nodes := i
      else if (has_sectors = -1) and (lname = 'SECTORS') then
        has_sectors := i
      else if (has_reject = -1) and (lname = 'REJECT') then
        has_reject := i
      else if (has_blockmap = -1) and (lname = 'BLOCKMAP') then
        has_blockmap := i
      {$IFDEF HEXEN}
      else if (has_behavior = -1) and (lname = 'BEHAVIOR') then
        has_behavior := i{$ENDIF};
    end;
  end
  else if lumpnum <= W_NumLumps - {$IFDEF HEXEN}7{$ELSE}6{$ENDIF} then
  begin
    for i := 1 to {$IFDEF HEXEN}6{$ELSE}5{$ENDIF} do
    begin
      lname := strupper(char8tostring(W_GetNameForNum(lumpnum + i)));
      // JVAL: 20200222 - Fix bug of continous maps without all assets
      if (has_things = -1) and (lname = 'THINGS') then
        has_things := i
      else if (has_lines = -1) and (lname = 'LINEDEFS') then
        has_lines := i
      else if (has_sides = -1) and (lname = 'SIDEDEFS') then
        has_sides := i
      else if (has_vertexes = -1) and (lname = 'VERTEXES') then
        has_vertexes := i
      else if (has_sectors = -1) and (lname = 'SECTORS') then
        has_sectors := i
      {$IFDEF HEXEN}
      else if (has_behavior = -1) and (lname = 'BEHAVIOR') then
        has_behavior := i{$ENDIF};
    end;
  end;

  if has_things = 1 then
    if has_lines = 2 then
      if has_sides = 3 then
        if has_vertexes = 4 then
          if has_segs = 5 then
            if has_ssectors = 6 then
              if has_nodes = 7 then
                if has_sectors = 8 then
                  if has_reject = 9 then
                    if has_blockmap = 10 then
                    {$IFDEF HEXEN}
                     if has_behavior = 11 then
                     {$ENDIF}
                       exit; // Nothing to do

  // Check if we can build the nodes
  candonodes := false;

  if has_things > 0 then
    if has_lines > 0 then
      if has_sides > 0 then
        if has_vertexes > 0 then
          if has_sectors > 0 then
            candonodes := true;

  if not candonodes then
  begin
    I_Warning('ND_NodesCheck(): Missing critical map data to play the map'#13#10);
    exit;
  end;

  crc32a := GetLumpCRC32(lumpnum + has_lines);
  crc32b := GetLumpCRC32(lumpnum + has_sides);
  crc32c := GetLumpCRC32(lumpnum + has_vertexes);
  crc32d := GetLumpCRC32(lumpnum + has_sectors);

  mapdir := M_SaveFileName('DATA\');
  MkDir(mapdir);
  mapdir := mapdir + 'WADS\';
  MkDir(mapdir);
  wadfilemap := mapdir + lumpname + '_' + crc32a + '_' + crc32b + '_' + crc32c + '_' + crc32d + '.wad';

  if not fexists(wadfilemap) then
  begin
    outfilemap := mapdir + lumpname + '_' + crc32a + '_' + crc32b + '_' + crc32c + '_' + crc32d + '.out';
    I_DeclareTempFile(outfilemap);

    header.identification :=
      integer(Ord('P') or (Ord('W') shl 8) or (Ord('A') shl 16) or (Ord('D') shl 24));
    header.numlumps := {$IFDEF HEXEN}12{$ELSE}11{$ENDIF};

    f := TFile.Create(outfilemap, fCreate);
    f.Write(header, SizeOf(header));

    ZeroMemory(@infotable, SizeOf(infotable));

    infotable[0].filepos := f.Position;
    infotable[0].size := 0;
    infotable[0].name := stringtochar8(strupper(lumpname));

    if has_things > 0 then
      llen := W_LumpLength(lumpnum + has_things)
    else
      llen := 0;
    infotable[1].filepos := f.Position;
    infotable[1].size := llen;
    infotable[1].name := stringtochar8('THINGS');
    if llen > 0 then
    begin
      ldata := malloc(llen);
      W_ReadLump(lumpnum + has_things, ldata);
      f.Write(ldata^, llen);
      memfree(pointer(ldata), llen);
    end;

    if has_lines > 0 then
      llen := W_LumpLength(lumpnum + has_lines)
    else
      llen := 0;
    infotable[2].filepos := f.Position;
    infotable[2].size := llen;
    infotable[2].name := stringtochar8('LINEDEFS');
    if llen > 0 then
    begin
      ldata := malloc(llen);
      W_ReadLump(lumpnum + has_lines, ldata);
      f.Write(ldata^, llen);
      memfree(pointer(ldata), llen);
    end;

    if has_sides > 0 then
      llen := W_LumpLength(lumpnum + has_sides)
    else
      llen := 0;
    infotable[3].filepos := f.Position;
    infotable[3].size := llen;
    infotable[3].name := stringtochar8('SIDEDEFS');
    if llen > 0 then
    begin
      ldata := malloc(llen);
      W_ReadLump(lumpnum + has_sides, ldata);
      f.Write(ldata^, llen);
      memfree(pointer(ldata), llen);
    end;

    if has_sides > 0 then
      llen := W_LumpLength(lumpnum + has_sides)
    else
      llen := 0;
    infotable[4].filepos := f.Position;
    infotable[4].size := llen;
    infotable[4].name := stringtochar8('VERTEXES');
    if llen > 0 then
    begin
      ldata := malloc(llen);
      W_ReadLump(lumpnum + has_vertexes, ldata);
      f.Write(ldata^, llen);
      memfree(pointer(ldata), llen);
    end;

    infotable[5].filepos := f.Position;
    infotable[5].size := 0;
    infotable[5].name := stringtochar8('SEGS');

    infotable[6].filepos := f.Position;
    infotable[6].size := 0;
    infotable[6].name := stringtochar8('SSECTORS');

    infotable[7].filepos := f.Position;
    infotable[7].size := 0;
    infotable[7].name := stringtochar8('NODES');

    if has_sectors > 0 then
      llen := W_LumpLength(lumpnum + has_sectors)
    else
      llen := 0;
    infotable[8].filepos := f.Position;
    infotable[8].size := llen;
    infotable[8].name := stringtochar8('SECTORS');
    if llen > 0 then
    begin
      ldata := malloc(llen);
      W_ReadLump(lumpnum + has_sectors, ldata);
      f.Write(ldata^, llen);
      memfree(pointer(ldata), llen);
    end;

    infotable[9].filepos := f.Position;
    infotable[9].size := 0;
    infotable[9].name := stringtochar8('REJECT');

    infotable[10].filepos := f.Position;
    infotable[10].size := 0;
    infotable[10].name := stringtochar8('BLOCKMAP');

    {$IFDEF HEXEN}
    infotable[11].filepos := f.Position;
    if has_behavior > 0 then
    begin
      llen := W_LumpLength(lumpnum + has_behavior);
      infotable[11].size := llen;
      ldata := malloc(llen);
      W_ReadLump(lumpnum + has_behavior, ldata);
      f.Write(ldata^, llen);
      memfree(pointer(ldata), llen);
    end
    else
      infotable[11].size := 0;
    infotable[11].name := stringtochar8('BEHAVIOR');
    {$ENDIF}

    header.infotableofs := f.Position;
    f.Write(infotable, SizeOf(infotable));
    f.Seek(0, sFromBeginning);
    f.Write(header, SizeOf(header));
    f.Free;

    // Build the nodes
    printf(#13#10'  ND_NodesCheck: Building GL-Friendly nodes for %s'#13#10, [lumpname]);

    if not ND_RunGlbsp(outfilemap, wadfilemap, [{$IFDEF HEXEN}goHexen{$ENDIF}]) then
    begin
      printf(#13#10);
      I_Warning('ND_NodesCheck(): Failed to build GL-Friendly nodes for %s'#13#10, [outfilemap]);
      exit;
    end;
    printf(#13#10);

  end;

  W_RuntimeLoad(wadfilemap, F_ORIGIN_WAD);
end;

end.

