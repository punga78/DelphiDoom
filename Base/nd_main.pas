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
  System.SysUtils,
  d_delphi,
  doomdata,
  r_defs,
  m_fixed,
  DelphiDoom.Nodes.Intf;

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
// ND_Configure
//
// The services of the Nodes library (Libs\Nodes), given by ComposeEngine. Without
// them the functions of this unit stop the game with an error.
//
//==============================================================================
procedure ND_Configure(const ASource: INodesLumpSource; const ADetector: INodesGlDetector;
  const AFinder: INodesGlMapFinder; const AInputBuilder: INodesGlbspInputBuilder;
  AHexen: boolean);

//==============================================================================
//
// ND_ReadLumpBytes
//
// All the bytes of a lump of the directory.
//
//==============================================================================
function ND_ReadLumpBytes(const lump: integer): TBytes;

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

//==============================================================================
//
// ND_ReadGwa
//
// Reads a GWA file; sets glnodesver to its version of GL nodes.
//
//==============================================================================
function ND_ReadGwa(const afilename: string): INodesGwa;

//==============================================================================
//
// ND_LoadVertexes
//
//==============================================================================
procedure ND_LoadVertexes(lump: integer; const gwa: INodesGwa);

//==============================================================================
//
// ND_LoadSubsectors
//
//==============================================================================
procedure ND_LoadSubsectors(const gwa: INodesGwa);

//==============================================================================
//
// ND_LoadNodes
//
//==============================================================================
procedure ND_LoadNodes(const gwa: INodesGwa);

//==============================================================================
//
// ND_LoadSegs
//
//==============================================================================
procedure ND_LoadSegs(const gwa: INodesGwa);

//==============================================================================
//
// ND_NodesCheck
//
//==============================================================================
procedure ND_NodesCheck(const lumpname: string);

implementation

uses
  System.Classes,
  m_crc32,
  i_tmp,
  i_exec,
  DelphiDoom.Glbsp.Intf,
  DelphiDoom.Glbsp.Client,
  DelphiDoom.Glbsp.Provider,
  DelphiDoom.Nodes.Types,
  DelphiDoom.Nodes.Adler32,
  DelphiDoom.Nodes.GlParser,
  DelphiDoom.Nodes.Factory,
  DelphiDoom.Nodes.MapScanner,
  i_system,
  p_setup,
  w_wad,
  m_misc,
  m_argv,
  r_main,
  z_zone;

var
  nd_source: INodesLumpSource = nil;
  nd_detector: INodesGlDetector = nil;
  nd_finder: INodesGlMapFinder = nil;
  nd_inputbuilder: INodesGlbspInputBuilder = nil;
  nd_hexen: boolean = false;

//==============================================================================
//
// ND_Configure
//
//==============================================================================
procedure ND_Configure(const ASource: INodesLumpSource; const ADetector: INodesGlDetector;
  const AFinder: INodesGlMapFinder; const AInputBuilder: INodesGlbspInputBuilder;
  AHexen: boolean);
begin
  nd_source := ASource;
  nd_detector := ADetector;
  nd_finder := AFinder;
  nd_inputbuilder := AInputBuilder;
  nd_hexen := AHexen;
end;

//==============================================================================
//
// ND_CheckConfigured
//
//==============================================================================
procedure ND_CheckConfigured;
begin
  if (nd_source = nil) or (nd_detector = nil) or (nd_finder = nil) or (nd_inputbuilder = nil) then
    I_Error('ND_CheckConfigured(): ND_Configure() was not called');
end;

//==============================================================================
//
// ND_ReadLumpBytes
//
//==============================================================================
function ND_ReadLumpBytes(const lump: integer): TBytes;
begin
  ND_CheckConfigured;
  result := nd_source.ReadLump(lump);
end;

//==============================================================================
//
// ND_WriteBytes
//
//==============================================================================
procedure ND_WriteBytes(const afile: string; const bytes: TBytes);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(afile, fmCreate);
  try
    if Length(bytes) > 0 then
      fs.WriteBuffer(bytes[0], Length(bytes));
  finally
    fs.Free;
  end;
end;

//==============================================================================
// gld_GetGLNodesVersion
//
// JVAL
//  Returns the glbsp nodes version.
//
//==============================================================================
function gld_GetGLNodesVersion(const base: integer): integer;
begin
  ND_CheckConfigured;
  result := nd_detector.DetectVersion(base);
  if result > 0 then
    printf('gld_GetGLNodesVersion(): GL v%d nodes found.'#13#10, [result]);
end;

//==============================================================================
//
// gld_GetGLVertexes
//
//==============================================================================
procedure gld_GetGLVertexes(v: Pvertex_t; lump: integer; count: integer; ver: integer);
var
  i: integer;
  glverts: TArray<TNodesGlVertex>;
begin
  if (count = 0) or (ver = 0) then
    exit;

  glverts := TNodesGlParser.ParseVertexes(ND_ReadLumpBytes(lump), ver);
  if count > Length(glverts) then
    count := Length(glverts);
  for i := 0 to count - 1 do
  begin
    v.x := glverts[i].X;
    v.y := glverts[i].Y;
    inc(v);
  end;
end;

//==============================================================================
//
// gld_GetGLMapLump
//
//==============================================================================
function gld_GetGLMapLump(const maplump: integer): integer;
begin
  ND_CheckConfigured;
  result := nd_finder.FindGlMapLump(maplump);
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

//==============================================================================
//
// ND_GetNodes
//
//==============================================================================
function ND_GetNodes(const mapname: string): string;
var
  maplump: integer;
  adler32: LongWord;
  path: string;
  mapfilename: string;
  gwafilename: string;
begin
  ND_CheckConfigured;
  maplump := W_GetNumForName(mapname);
  adler32 := TNodesAdler32.OfMap(nd_source, maplump);

  path := M_SaveFileName('DATA\');
  MkDir(path);
  path := path + 'BSP\';
  MkDir(path);

  gwafilename := fexpand(path + mapname + '_' + HextL(adler32) + '.gwa');

  if not fexists(gwafilename) then
  begin
    mapfilename := I_NewTempFile(mapname + '_' + HextL(adler32) + '.wad');
    ND_WriteBytes(mapfilename, nd_inputbuilder.BuildForMap(maplump));

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
// ND_ReadGwa
//
//==============================================================================
function ND_ReadGwa(const afilename: string): INodesGwa;
var
  fs: TFileStream;
  bytes: TBytes;
begin
  fs := TFileStream.Create(afilename, fmOpenRead or fmShareDenyNone);
  try
    SetLength(bytes, fs.Size);
    if fs.Size > 0 then
      fs.ReadBuffer(bytes[0], fs.Size);
  finally
    fs.Free;
  end;

  try
    result := TNodesFactory.ReadGwa(bytes);
  except
    on E: ENodesException do
    begin
      result := nil;
      I_Error('ND_ReadGwa(): %s (%s)', [E.Message, afilename]);
    end;
  end;

  glnodesver := result.Version;
  printf('ND_ReadGwa(): GL v%d nodes found.'#13#10, [glnodesver]);
end;

//==============================================================================
//
// ND_LoadVertexes
//
//==============================================================================
procedure ND_LoadVertexes(lump: integer; const gwa: INodesGwa);
var
  data: pointer;
  i: integer;
  ml: Pmapvertex_t;
  li: Pvertex_t;
  numglverts: integer;
  glverts: TArray<TNodesGlVertex>;
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
  begin
    glverts := gwa.GlVertexes;
    numglverts := Length(glverts);
  end;

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
    li.x := glverts[i].X;
    li.y := glverts[i].Y;
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
procedure ND_LoadSubsectors(const gwa: INodesGwa);
var
  i: integer;
  ss: Psubsector_t;
  glsubsectors: TArray<TNodesGlSubsector>;
begin
  glsubsectors := gwa.Subsectors;
  numsubsectors := Length(glsubsectors);
  subsectors := Z_Malloc(numsubsectors * SizeOf(subsector_t), PU_LEVEL, nil);
  ZeroMemory(subsectors, numsubsectors * SizeOf(subsector_t));

  ss := @subsectors[0];
  for i := 0 to numsubsectors - 1 do
  begin
    ss.numlines := glsubsectors[i].Count;
    ss.firstline := glsubsectors[i].FirstSeg;
    inc(ss);
  end;
end;

//==============================================================================
//
// ND_LoadNodes
//
//==============================================================================
procedure ND_LoadNodes(const gwa: INodesGwa);
var
  i: integer;
  k: integer;
  no: Pnode_t;
  glnodes: TArray<TNodesGlNode>;
begin
  glnodes := gwa.Nodes;
  numnodes := Length(glnodes);
  nodes := Z_Malloc(numnodes * SizeOf(node_t), PU_LEVEL, nil);
  ZeroMemory(nodes, numnodes * SizeOf(node_t));

  no := @nodes[0];
  for i := 0 to numnodes - 1 do
  begin
    no.x := glnodes[i].X * FRACUNIT;
    no.y := glnodes[i].Y * FRACUNIT;
    no.dx := glnodes[i].DeltaX * FRACUNIT;
    no.dy := glnodes[i].DeltaY * FRACUNIT;
    no.children[0] := glnodes[i].RightChild;
    no.children[1] := glnodes[i].LeftChild;
    for k := 0 to 3 do
      no.bbox[0, k] := glnodes[i].RightBoundingBox[k] * FRACUNIT;
    for k := 0 to 3 do
      no.bbox[1, k] := glnodes[i].LeftBoundingBox[k] * FRACUNIT;
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
procedure ND_LoadSegs(const gwa: INodesGwa);
var
  i: integer;
  ml: TNodesGlSeg;
  glsegs: TArray<TNodesGlSeg>;
  li: Pseg_t;
  ldef: Pline_t;
  linedef: integer;
  side: integer;
  sidenum: integer;
begin
  glsegs := gwa.Segs;
  numsegs := Length(glsegs);
  segs := Z_Malloc(numsegs * SizeOf(seg_t), PU_LEVEL, nil);
  ZeroMemory(segs, numsegs * SizeOf(seg_t));

  li := @segs[0];
  for i := 0 to numsegs - 1 do
  begin
    ml := glsegs[i];
    li.v1 := @vertexes[CheckGLVertex(ml.StartVertex)];
    li.v2 := @vertexes[CheckGLVertex(ml.EndVertex)];
    {$IFDEF OPENGL}
    li.iSegID := i;
    {$ENDIF}

    if ml.Linedef = word(1 shl 16 - 1) then
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
      linedef := ml.Linedef;
      ldef := @lines[linedef];
      if ml.Side <> 0 then
        li.offset := GetOffset(li.v1, ldef.v2)
      else
        li.offset := GetOffset(li.v1, ldef.v1);
      li.linedef := ldef;
      side := ml.Side;
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
  layout: TNodesMapLayout;
  crc32a, crc32b, crc32c, crc32d: string;
  outfilemap: string;
  wadfilemap: string;
  mapdir: string;
begin
  ND_CheckConfigured;
  lumpnum := W_GetNumForName(lumpname);
  if (lumpnum < 0) or (lumpnum >= W_NumLumps - 1) then
    exit;

  layout := TNodesMapScanner.Scan(nd_source, lumpnum, nd_hexen);

  if layout.IsComplete(nd_hexen) then
    exit; // Nothing to do

  // Check if we can build the nodes
  if not layout.CanBuildNodes then
  begin
    I_Warning('ND_NodesCheck(): Missing critical map data to play the map'#13#10);
    exit;
  end;

  crc32a := GetLumpCRC32(lumpnum + layout.Linedefs);
  crc32b := GetLumpCRC32(lumpnum + layout.Sidedefs);
  crc32c := GetLumpCRC32(lumpnum + layout.Vertexes);
  crc32d := GetLumpCRC32(lumpnum + layout.Sectors);

  mapdir := M_SaveFileName('DATA\');
  MkDir(mapdir);
  mapdir := mapdir + 'WADS\';
  MkDir(mapdir);
  wadfilemap := mapdir + lumpname + '_' + crc32a + '_' + crc32b + '_' + crc32c + '_' + crc32d + '.wad';

  if not fexists(wadfilemap) then
  begin
    outfilemap := mapdir + lumpname + '_' + crc32a + '_' + crc32b + '_' + crc32c + '_' + crc32d + '.out';
    I_DeclareTempFile(outfilemap);

    ND_WriteBytes(outfilemap, nd_inputbuilder.BuildForMapWithoutNodes(lumpnum, layout));

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
