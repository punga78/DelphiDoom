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
//  GL nodes: the structures of the lumps of glBSP, the GL vertexes and the node builder
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
  DelphiDoom.Glbsp.Client;

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
// gld_GetGLVertexes
//
//==============================================================================
procedure gld_GetGLVertexes(v: Pvertex_t; lump: integer; count: integer; ver: integer);

//==============================================================================
//
// gld_BuildNodes
//
//==============================================================================
function gld_BuildNodes(const wadfile, gwafile: string): boolean;

//==============================================================================
//
// ND_RunGlbsp
//
// Runs the node builder; what it prints goes to the log, as it did when the
// program was started from the engine
//
//==============================================================================
function ND_RunGlbsp(const wadfile, gwafile: string; const options: TGlbspOptions): boolean;

implementation

uses
  DelphiDoom.Glbsp.Intf,
  DelphiDoom.Glbsp.Provider,
  DelphiDoom.Nodes.Types,
  DelphiDoom.Nodes.GlParser,
  i_system,
  w_wad;

//==============================================================================
//
// gld_GetGLVertexes
//
//==============================================================================
procedure gld_GetGLVertexes(v: Pvertex_t; lump: integer; count: integer; ver: integer);
var
  i: integer;
  bytes: TBytes;
  glverts: TArray<TNodesGlVertex>;
begin
  if (count = 0) or (ver = 0) then
    exit;

  SetLength(bytes, W_LumpLength(lump));
  if Length(bytes) > 0 then
    W_ReadLump(lump, @bytes[0]);
  glverts := TNodesGlParser.ParseVertexes(bytes, ver);
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
// ND_RunGlbsp
//
//==============================================================================
function ND_RunGlbsp(const wadfile, gwafile: string; const options: TGlbspOptions): boolean;
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

end.
