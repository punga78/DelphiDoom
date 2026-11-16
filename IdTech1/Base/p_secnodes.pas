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
//  The lists of the sectors a thing touches (Boom), moved out of p_map:
//  only the games whose sectors have touching_thinglist (Doom, Strife) use it.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_secnodes;

interface

uses
  m_fixed,
  p_mobj_h,
  r_defs;

//==============================================================================
// P_CreateSecNodeList
//
// Boom compatibility
//
//==============================================================================
procedure P_CreateSecNodeList(thing: Pmobj_t; x, y: fixed_t);

//==============================================================================
//
// P_DelSecnode
//
//==============================================================================
function P_DelSecnode(node: Pmsecnode_t): Pmsecnode_t;

//==============================================================================
//
// P_ChangeSectorNodes
//
// The part of P_DoChangeSector that walks the things touching the sector
//
//==============================================================================
procedure P_ChangeSectorNodes(sector: Psector_t);

var
  sector_list: Pmsecnode_t;

implementation

// p_map and the rules of the game last: this code was part of p_map
uses
  d_delphi,
  DelphiDoom.MathCore.Types,
  doomdef,
  p_local,
  p_maputl,
  p_setup,
  r_main,
  z_zone,
  DelphiDoom.Engine.World.MapRules,
  p_map;

// phares 3/16/98
//
// P_AddSecnode() searches the current list to see if this sector is
// already there. If not, it adds a sector node at the head of the list of
// sectors this object appears in. This is called when creating a list of
// nodes that will get linked in later. Returns a pointer to the new node.
//
//==============================================================================
function P_AddSecnode(s: Psector_t; thing: Pmobj_t; nextnode: Pmsecnode_t): Pmsecnode_t;
var
  node: Pmsecnode_t;
begin
  node := nextnode;
  while node <> nil do
  begin
    if node.m_sector = s then // Already have a node for this sector?
    begin
      node.m_thing := thing; // Yes. Setting m_thing says 'keep it'.
      result := nextnode;
      exit;
    end;
    // JVAL: 20200105 - Prevent infinite loop
    if node.m_tnext = nextnode then
      node.m_tnext := nil;
    node := node.m_tnext;
  end;

  // Couldn't find an existing node for this sector. Add one at the head
  // of the list.

  node := Z_Malloc(SizeOf(msecnode_t), PU_LEVEL, nil);

  // killough 4/4/98, 4/7/98: mark new nodes unvisited.
  node.visited := false;

  node.m_sector := s;       // sector
  node.m_thing := thing;    // mobj
  node.m_tprev := nil;      // prev node on Thing thread
  node.m_tnext := nextnode; // next node on Thing thread
  if nextnode <> nil then
    nextnode.m_tprev := node; // set back link on Thing

  // Add new node at head of sector thread starting at s.touching_thinglist

  node.m_sprev := nil;    // prev node on sector thread
  node.m_snext := s.touching_thinglist; // next node on sector thread
  if s.touching_thinglist <> nil then
    node.m_snext.m_sprev := node;
  s.touching_thinglist := node;
  result := node;
end;

// P_DelSecnode() deletes a sector node from the list of
// sectors this object appears in. Returns a pointer to the next node
// on the linked list, or nil.
//
//==============================================================================
function P_DelSecnode(node: Pmsecnode_t): Pmsecnode_t;
var
  tp: Pmsecnode_t;  // prev node on thing thread
  tn: Pmsecnode_t;  // next node on thing thread
  sp: Pmsecnode_t;  // prev node on sector thread
  sn: Pmsecnode_t;  // next node on sector thread
begin
  if node <> nil then
  begin

    // Unlink from the Thing thread. The Thing thread begins at
    // sector_list and not from mobj_t.touching_sectorlist.

    tp := node.m_tprev;
    tn := node.m_tnext;
    if tp <> nil then
      tp.m_tnext := tn;
    if tn <> nil then
      tn.m_tprev := tp;

    // Unlink from the sector thread. This thread begins at
    // sector_t.touching_thinglist.

    sp := node.m_sprev;
    sn := node.m_snext;
    if sp <> nil then
      sp.m_snext := sn
    else
      node.m_sector.touching_thinglist := sn;
    if sn <> nil then
      sn.m_sprev := sp;

    Z_Free(node);
    result := tn;
  end
  else
    result := nil;
end;  // phares 3/13/98

// phares 3/14/98
//
// PIT_GetSectors
// Locates all the sectors the object is in by looking at the lines that
// cross through it. You have already decided that the object is allowed
// at this location, so don't bother with checking impassable or
// blocking lines.
//
//==============================================================================
function PIT_GetSectors(ld: Pline_t): boolean;
begin
  if (TMapCheck.BBox[BOX_RIGHT] <= ld.bbox[BOX_LEFT]) or
     (TMapCheck.BBox[BOX_LEFT] >= ld.bbox[BOX_RIGHT]) or
     (TMapCheck.BBox[BOX_TOP] <= ld.bbox[BOX_BOTTOM]) or
     (TMapCheck.BBox[BOX_BOTTOM] >= ld.bbox[BOX_TOP]) then
  begin
    result := true;
    exit;
  end;

  if P_BoxOnLineSide(@TMapCheck.BBox, ld) <> -1 then
  begin
    result := true;
    exit;
  end;

  // This line crosses through the object.

  // Collect the sector(s) from the line and add to the
  // sector_list you're examining. If the Thing ends up being
  // allowed to move to this position, then the sector_list
  // will be attached to the Thing's mobj_t at touching_sectorlist.

  sector_list := P_AddSecnode(ld.frontsector, TMapCheck.Thing, sector_list);

  // Don't assume all lines are 2-sided, since some Things
  // like MT_TFOG are allowed regardless of whether their radius takes
  // them beyond an impassable linedef.

  // killough 3/27/98, 4/4/98:
  // Use sidedefs instead of 2s flag to determine two-sidedness.

  if ld.backsector <> nil then
    if ld.backsector <> ld.frontsector then
      sector_list := P_AddSecnode(ld.backsector, TMapCheck.Thing, sector_list);

  result := true;
end;

// phares 3/14/98
//
// P_CreateSecNodeList alters/creates the sector_list that shows what sectors
// the object resides in.
//
//==============================================================================
procedure P_CreateSecNodeList(thing: Pmobj_t; x, y: fixed_t);
var
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  bx: integer;
  by: integer;
  node: Pmsecnode_t;
  r: fixed_t;
begin
  // First, clear out the existing m_thing fields. As each node is
  // added or verified as needed, m_thing will be set properly. When
  // finished, delete all nodes where m_thing is still nil. These
  // represent the sectors the Thing has vacated.

  node := sector_list;
  while node <> nil do
  begin
    node.m_thing := nil;
    node := node.m_tnext;
  end;

  TMapCheck.Thing := thing;
  TMapCheck.Flags := thing.flags;

  TMapCheck.X := x;
  TMapCheck.Y := y;

  r := TMapCheck.Thing.radius;
  TMapCheck.BBox[BOX_TOP] := y + r;
  TMapCheck.BBox[BOX_BOTTOM] := y - r;
  TMapCheck.BBox[BOX_RIGHT] := x + r;
  TMapCheck.BBox[BOX_LEFT] := x - r;

  inc(validcount); // used to make sure we only process a line once

  if internalblockmapformat then
  begin
    xl := MapBlockIntX(int64(TMapCheck.BBox[BOX_LEFT]) - int64(bmaporgx));
    xh := MapBlockIntX(int64(TMapCheck.BBox[BOX_RIGHT]) - int64(bmaporgx));
    yl := MapBlockIntY(int64(TMapCheck.BBox[BOX_BOTTOM]) - int64(bmaporgy));
    yh := MapBlockIntY(int64(TMapCheck.BBox[BOX_TOP]) - int64(bmaporgy));
  end
  else
  begin
    xl := MapBlockInt(TMapCheck.BBox[BOX_LEFT] - bmaporgx);
    xh := MapBlockInt(TMapCheck.BBox[BOX_RIGHT] - bmaporgx);
    yl := MapBlockInt(TMapCheck.BBox[BOX_BOTTOM] - bmaporgy);
    yh := MapBlockInt(TMapCheck.BBox[BOX_TOP] - bmaporgy);
  end;

  for bx := xl to xh do
    for by := yl to yh do
      P_BlockLinesIterator(bx, by, PIT_GetSectors);

  // Add the sector of the (x,y) point to sector_list.

  sector_list := P_AddSecnode(Psubsector_t(thing.subsector).sector, thing, sector_list);

  // Now delete any nodes that won't be used. These are the ones where
  // m_thing is still nil.

  node := sector_list;
  while node <> nil do
  begin
    if node.m_thing = nil then
    begin
      if node = sector_list then
        sector_list := node.m_tnext;
      node := P_DelSecnode(node);
    end
    else
      node := node.m_tnext;
  end;

end;

//==============================================================================
//
// P_ChangeSectorNodes
//
//==============================================================================
procedure P_ChangeSectorNodes(sector: Psector_t);
var
  n: Pmsecnode_t;
begin
  // killough 4/4/98: scan list front-to-back until empty or exhausted,
  // restarting from beginning after each thing is processed. Avoids
  // crashes, and is sure to examine all things in the sector, and only
  // the things which are in the sector, until a steady-state is reached.
  // Things can arbitrarily be inserted and removed and it won't mess up.
  //
  // killough 4/7/98: simplified to avoid using complicated counter

  // Mark all things invalid

  n := sector.touching_thinglist;
  while n <> nil do
  begin
    n.visited := false;
    n := n.m_snext;
  end;

  repeat
    n := sector.touching_thinglist;
    while n <> nil do
    begin
      if not n.visited then
      begin
        n.visited := true;  // mark thing as processed
        if n.m_thing.flags and MF_NOBLOCKMAP = 0 then//jff 4/7/98 don't do these
          PIT_ChangeSector(n.m_thing);    // process it
        break;
      end;
      n := n.m_snext;
    end;
  until n = nil;
end;

end.
