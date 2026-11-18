{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of p_setup for the rule tests}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for the real p_setup in DelphiDoom.Tests.Rules only: the level structures of the real unit (the real implementation loads levels and reads the whole engine).
{$I Doom32.inc}
unit p_setup;

interface

uses
  d_delphi,
  doomdef,
  doomdata,
  m_fixed,
  p_mobj_h,
  p_udmf,
  r_defs;

var
  bmaporgx: fixed_t;
  bmaporgy: fixed_t;
  numvertexes: integer;
  vertexes: Pvertex_tArray;
  numsegs: integer;
  segs: Pseg_tArray;
  numsectors: integer;
  sectors: Psector_tArray;
  numsubsectors: integer;
  subsectors: Psubsector_tArray;
  numnodes: integer;
  nodes: Pnode_tArray;
  numlines: integer;
  lines: Pline_tArray;
  numsides: integer;
  sides: Pside_tArray;
  numvanillasegs: integer;
  vanillasegs: Pvanillaseg_tArray;
  numvanillasubsectors: integer;
  vanillasubsectors: Pvanillasubsector_tArray;
  numvanillanodes: integer;
  vanillanodes: Pvanillanode_tArray;
  hasvanillanodes: boolean;
  bmapwidth: integer;
  bmapheight: integer;
  bmapsize: integer;
  blockmap: PIntegerArray;
  blockmaplump: PIntegerArray;
  blockmapxneg: integer;
  blockmapyneg: integer;
  internalblockmapformat: boolean;

type
  blocklinkitem_t = record
    size: integer;
    realsize: integer;
    links: Pmobj_tPArray;
  end;
  Pblocklinkitem_t = ^blocklinkitem_t;
  blocklinkarray_t = array[0..$FFFF] of blocklinkitem_t;
  Pblocklinkarray_t = ^blocklinkarray_t;

var
  blocklinks: Pblocklinkarray_t;
  vanillablocklinks: Pmobj_tPArray;
  rejectmatrix: PByteArray;
  rejectmatrixsize: integer;
  largemap: boolean;

implementation

end.