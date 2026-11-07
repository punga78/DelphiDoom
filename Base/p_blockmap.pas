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
//  DESCRIPTION:
//   Blockmap loading & slime trails: the facade of Libs\Blockmap. The
//   engine decides what to build and keeps the results in the globals of
//   p_setup; the algorithms are in the library.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_blockmap;

interface

uses
  DelphiDoom.Blockmap.Intf;

//==============================================================================
//
// P_ConfigureBlockmap
//
// Gives the blockmap library to the facade; ComposeEngine calls it
//
//==============================================================================
procedure P_ConfigureBlockmap(const ABuilder: IBlockmapBuilder;
  const AReader: IBlockmapLumpReader; const ARemover: ISlimeTrailRemover);

//==============================================================================
//
// P_LoadBlockMap
//
//==============================================================================
procedure P_LoadBlockMap(lump: integer);

//==============================================================================
//
// P_RemoveSlimeTrails
//
//==============================================================================
procedure P_RemoveSlimeTrails;  // killough 10/98

implementation

uses
  d_delphi,
  DelphiDoom.Blockmap.Types,
  doomtype,
  i_system,
  m_argv,
  m_fixed,
  p_setup,
  r_defs,
  sysutils,
  w_wad,
  z_zone;

var
  blockmap_builder: IBlockmapBuilder;
  blockmap_reader: IBlockmapLumpReader;
  slime_remover: ISlimeTrailRemover;

//==============================================================================
//
// P_ConfigureBlockmap
//
//==============================================================================
procedure P_ConfigureBlockmap(const ABuilder: IBlockmapBuilder;
  const AReader: IBlockmapLumpReader; const ARemover: ISlimeTrailRemover);
begin
  blockmap_builder := ABuilder;
  blockmap_reader := AReader;
  slime_remover := ARemover;
end;

//==============================================================================
//
// P_BuildBlockMapData
//
// Makes the blockmap from the vertexes and the lines of the level
//
//==============================================================================
function P_BuildBlockMapData: TBlockmapData;
var
  i: integer;
  verts: TArray<TBlockmapPoint>;
  lns: TArray<TBlockmapLine>;
begin
  SetLength(verts, numvertexes);
  for i := 0 to numvertexes - 1 do
  begin
    verts[i].X := vertexes[i].x;
    verts[i].Y := vertexes[i].y;
  end;
  SetLength(lns, numlines);
  for i := 0 to numlines - 1 do
  begin
    lns[i].X1 := lines[i].v1.x;
    lns[i].Y1 := lines[i].v1.y;
    lns[i].X2 := lines[i].v2.x;
    lns[i].Y2 := lines[i].v2.y;
  end;
  result := blockmap_builder.Build(verts, lns);
end;

//==============================================================================
//
// P_LoadBlockMap
//
//==============================================================================
procedure P_LoadBlockMap(lump: integer);
var
  count: integer;
  lumpbytes: TBytes;
  data: TBlockmapData;
  fromlump: boolean;
  size: integer;
begin
  if blockmap_builder = nil then
    I_Error('P_LoadBlockMap(): the blockmap library is not configured');

  // a missing, too small or too big lump, a large map or -blockmap: make the blockmap
  fromlump := false;
  count := W_LumpLength(lump);
  if (M_CheckParm('-blockmap') = 0) and not largemap and (count > 0) then
  begin
    SetLength(lumpbytes, count);
    W_ReadLump(lump, @lumpbytes[0]);
    fromlump := blockmap_reader.IsUsable(lumpbytes);
  end;

  try
    if fromlump then
      data := blockmap_reader.Read(lumpbytes)
    else
      data := P_BuildBlockMapData;
  except
    on E: EBlockmapException do
      I_Error('P_LoadBlockMap(): %s', [E.Message]);
  end;

  size := Length(data.Lump) * SizeOf(integer);
  blockmaplump := Z_Malloc(size, PU_LEVEL, nil);
  Move(data.Lump[0], blockmaplump[0], size);
  blockmapxneg := data.NegX;
  blockmapyneg := data.NegY;
  internalblockmapformat := data.Built;

  blockmap := @blockmaplump[4];

  bmaporgx := blockmaplump[0] * FRACUNIT;
  bmaporgy := blockmaplump[1] * FRACUNIT;
  bmapwidth := blockmaplump[2];
  bmapheight := blockmaplump[3];
  bmapsize := bmapwidth * bmapheight;
  // clear out mobj chains
  count := SizeOf(blocklinkitem_t) * bmapwidth * bmapheight;
  blocklinks := Z_Malloc(count, PU_LEVEL, nil);
  ZeroMemory(blocklinks, count);
end;

//==============================================================================
// P_RemoveSlimeTrails
//
// killough 10/98
//
// Remove slime trails.
//
// Slime trails are inherent to Doom's coordinate system: a node builder cannot
// avoid them because two lines through integer points may cross at a point
// that is not integer, and a WAD has no fractional coordinates. Inside the
// engine fractional coordinates are fine, so the vertex of a seg that is not
// an end of its linedef is moved onto the linedef (law of cosines). Orthogonal
// linedefs and minisegs are skipped. The calculation is TBlockmapSlimeTrailRemover.
//
//==============================================================================
procedure P_RemoveSlimeTrails;  // killough 10/98
var
  i: integer;
  verts: TArray<TBlockmapPoint>;
  sgs: TArray<TBlockmapSeg>;
begin
  if slime_remover = nil then
    I_Error('P_RemoveSlimeTrails(): the blockmap library is not configured');

  SetLength(verts, numvertexes);
  for i := 0 to numvertexes - 1 do
  begin
    verts[i].X := vertexes[i].x;
    verts[i].Y := vertexes[i].y;
  end;
  SetLength(sgs, numsegs);
  for i := 0 to numsegs - 1 do
  begin
    sgs[i].Vertex1 := (NativeInt(segs[i].v1) - NativeInt(vertexes)) div SizeOf(vertex_t);
    sgs[i].Vertex2 := (NativeInt(segs[i].v2) - NativeInt(vertexes)) div SizeOf(vertex_t);
    sgs[i].Miniseg := segs[i].miniseg;
    if not segs[i].miniseg then
    begin
      sgs[i].LineVertex1 := (NativeInt(segs[i].linedef.v1) - NativeInt(vertexes)) div SizeOf(vertex_t);
      sgs[i].LineVertex2 := (NativeInt(segs[i].linedef.v2) - NativeInt(vertexes)) div SizeOf(vertex_t);
      sgs[i].LineDeltaX := segs[i].linedef.dx;
      sgs[i].LineDeltaY := segs[i].linedef.dy;
    end;
  end;

  try
    slime_remover.Remove(verts, sgs);
  except
    on E: EBlockmapException do
      I_Error('P_RemoveSlimeTrails(): %s', [E.Message]);
  end;

  for i := 0 to numvertexes - 1 do
  begin
    vertexes[i].x := verts[i].X;
    vertexes[i].y := verts[i].Y;
  end;
end;

end.
