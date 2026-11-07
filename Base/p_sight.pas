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
//  LineOfSight/Visibility checks, uses REJECT Lookup Table.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_sight;

interface

uses
  m_fixed,
  p_mobj_h;

//==============================================================================
//
// P_CheckSight
//
//==============================================================================
function P_CheckSight(t1: Pmobj_t; t2: Pmobj_t): boolean;

//==============================================================================
//
// P_CheckSightXYZ
//
//==============================================================================
function P_CheckSightXYZ(const x, y, z: fixed_t; t2: Pmobj_t): boolean;

//==============================================================================
//
{$IFDEF HEXEN}
// P_SightPathTraverse
//
//==============================================================================
function P_SightPathTraverse(x1, y1, x2, y2: fixed_t): boolean;

//==============================================================================
//
{$ENDIF}
// P_CheckCameraSight
//
//==============================================================================
{$IFDEF HEXEN}
function P_CheckCameraSight(camx, camy, camz: fixed_t; mo: Pmobj_t): boolean;
{$ELSE}
function P_CheckCameraSight(const camx, camy, camz: fixed_t; const mo: Pmobj_t): boolean;
{$ENDIF}

{$IFDEF HEXEN}
var
  bottomslope: fixed_t; // slopes to top and bottom of target
  topslope: fixed_t;
  sightzstart: fixed_t; // eye z of looker
{$ELSE}
//==============================================================================
//
// P_CheckVisibility
//
//==============================================================================
function P_CheckVisibility(const atx, aty, atz: fixed_t; const atradious: fixed_t): boolean;
{$ENDIF}

implementation

uses
  d_delphi,
  doomdef,
{$IFDEF HEXEN}
  doomtype,
{$ELSE}
  doomdata,
{$ENDIF}
  g_game,
{$IFDEF HEXEN}
  g_demo,
{$ELSE}
  DelphiDoom.MathCore.Types,
{$ENDIF}
  p_local,
{$IFDEF HEXEN}
  p_maputl,
{$ELSE}
  p_map,
{$ENDIF}
  p_setup,
{$IFDEF HEXEN}
  po_man,
{$ELSE}
  p_slopes,
{$ENDIF}
  r_defs,
  r_main;
{$IFNDEF HEXEN}

//==============================================================================
//
// P_CheckSight
//
// P_DivlineSide
// Returns side 0 (front), 1 (back), or 2 (on).
//
//==============================================================================
function P_DivlineSide(const x, y: fixed_t; const node: Pdivline_t): integer;
var
  dx: fixed_t;
  dy: fixed_t;
  left: fixed_t;
  right: fixed_t;
begin
  if node.dx = 0 then
  begin
    if x = node.x then
    begin
      result := 2;
      exit;
    end;
    if x <= node.x then
    begin
      if node.dy > 0 then
        result := 1
      else
        result := 0;
      exit;
    end;
    if node.dy < 0 then
      result := 1
    else
      result := 0;
    exit;
  end;

  if node.dy = 0 then
  begin
    // JVAL: 20220219 - Fix wrong coordinates check
    // From EE:
    // haleyjd 11/11/02: applied cph's bug fix:
    // !node->dy ? x == node->y ? 2 ...
    //             ^          ^
    // This bug compared the wrong coordinates to each other,
    // and caused line-of-sight miscalculations. Turns out the
    // P_CrossSubsector optimization demo sync problem was caused by
    // masking this bug.
    if decide(G_PlayingEngineVersion < VERSION207, x, y) = node.y then
    begin
      result := 2;
      exit;
    end;
    if y <= node.y then
    begin
      if node.dx < 0 then
        result := 1
      else
        result := 0;
      exit;
    end;
    if node.dx > 0 then
      result := 1
    else
      result := 0;
    exit;
  end;

  dx := x - node.x;
  dy := y - node.y;

  left := FixedInt(node.dy) * FixedInt(dx);
  right := FixedInt(dy) * FixedInt(node.dx);

  if right < left then
  begin
    result := 0; // front side
    exit;
  end;

  if left = right then
    result := 2
  else
    result := 1; // back side
end;

//==============================================================================
//
// P_InterceptVector2
// Returns the fractional intercept point
// along the first divline.
// This is only called by the addthings and addlines traversers.
//
//==============================================================================
function P_InterceptVector2(v2, v1: Pdivline_t): fixed_t;
var
  num: fixed_t;
  den: fixed_t;
begin
  den := FixedMul8(v1.dy, v2.dx) - FixedMul8(v1.dx, v2.dy);

  if den = 0 then
  begin
    result := 0;
    exit;
    //  I_Error ("P_InterceptVector: parallel");
  end;

  num := FixedMul8(v1.x - v2.x, v1.dy) +
         FixedMul8(v2.y - v1.y, v1.dx);

  result := FixedDiv(num , den);
end;
{$ENDIF}

// JVAL: 3d Floors
type
  los_t = record
    sightzstart: fixed_t;
    t2x: fixed_t;
    t2y: fixed_t;
    strace: divline_t;
    topslope: fixed_t;
    bottomslope: fixed_t;
    bbox: array[0..3] of fixed_t;
  end;
  Plos_t = ^los_t;

//==============================================================================
//
{$IFDEF HEXEN}
//==============
{$ELSE}
// P_CrossSubsecPolyObj
{$ENDIF}
//
{$IFDEF HEXEN}
// PTR_SightTraverse
//
//==============
{$ELSE}
// haleyjd:
// Checks a line of sight against lines belonging to the given polyobject.
{$ENDIF}
//
//==============================================================================
{$IFDEF HEXEN}
function PTR_SightTraverse(_in: Pintercept_t): boolean;
{$ELSE}
function P_CrossSubsecPolyObj(const po: Ppolyobj_t; const los: Plos_t): boolean;
{$ENDIF}
var
{$IFDEF HEXEN}
  li: Pline_t;
  slope: fixed_t;
{$ELSE}
  i: integer;
  polySeg: PPseg_t;
  line: Pline_t;
  divl: divline_t;
  v1, v2: Pvertex_t;
{$ENDIF}
begin
{$IFDEF HEXEN}
  li := _in.d.line;

//
// crosses a two sided line
//
  P_LineOpening(li, false);

  if openbottom >= opentop then // quick test for totally closed doors
{$ELSE}
  polySeg := po.segs;
  for i := 0 to po.numsegs - 1 do
{$ENDIF}
  begin
{$IFDEF HEXEN}
    result := false;   // stop
{$ELSE}
    if polySeg^.miniseg then // JVAL: skip minisegs
    begin
      inc(polySeg);
      continue;
    end;

    line := polySeg^.linedef;
    // already checked other side?
    if line.validcount = validcount then
    begin
      inc(polySeg);
      continue;
    end;

    line.validcount := validcount;

    // OPTIMIZE: killough 4/20/98: Added quick bounding-box rejection test
    if (line.bbox[BOX_LEFT] > los.bbox[BOX_RIGHT]) or
       (line.bbox[BOX_RIGHT] < los.bbox[BOX_LEFT]) or
       (line.bbox[BOX_BOTTOM] > los.bbox[BOX_TOP]) or
       (line.bbox[BOX_TOP] < los.bbox[BOX_BOTTOM]) then
    begin
      inc(polySeg);
      continue;
    end;

    v1 := line.v1;
    v2 := line.v2;

    // line isn't crossed?
    if P_DivlineSide(v1.x, v1.y, @los.strace) = P_DivlineSide(v2.x, v2.y, @los.strace) then
    begin
      inc(polySeg);
      continue;
    end;

    divl.x := v1.x;
    divl.y := v1.y;
    divl.dx := v2.x - v1.x;
    divl.dy := v2.y - v1.y;

    // line isn't crossed?
    if P_DivlineSide(los.strace.x, los.strace.y, @divl) = P_DivlineSide(los.t2x, los.t2y, @divl) then
    begin
      inc(polySeg);
      continue;
    end;

    // stop because it is not two sided
    result := false;
{$ENDIF}
    exit;
  end;

{$IFDEF HEXEN}
  if li.frontsector.floorheight <> li.backsector.floorheight then
  begin
    slope := FixedDiv(openbottom - sightzstart, _in.frac);
    if slope > bottomslope then
      bottomslope := slope;
  end;

  if li.frontsector.ceilingheight <> li.backsector.ceilingheight then
  begin
    slope := FixedDiv(opentop - sightzstart, _in.frac);
    if slope < topslope then
      topslope := slope;
  end;

  result := topslope > bottomslope;
{$ELSE}
  result := true;
{$ENDIF}
end;

//==============================================================================
//
{$IFDEF HEXEN}
//==================
//
// P_SightBlockLinesIterator
//
//===================
{$ELSE}
// P_CrossSubsector
// Returns true
//  if strace crosses the given subsector successfully.
{$ENDIF}
//
//==============================================================================
{$IFDEF HEXEN}
function P_SightBlockLinesIterator(x, y: integer): boolean;
{$ELSE}
function P_CrossSubsector(const num: integer; const los: Plos_t): boolean;
{$ENDIF}
var
{$IFDEF HEXEN}
  offset: integer;
  list: PSmallInt;
  ld: Pline_t;
  s1, s2: integer;
  dl: divline_t;
  polyLink: Ppolyblock_t;
  segList: PPseg_t;
{$ELSE}
  seg: Pseg_t;
  line: Pline_t;
  s1: integer;
  s2: integer;
{$ENDIF}
  i: integer;
{$IFNDEF HEXEN}
  sub: Psubsector_t;
  front: Psector_t;
  back: Psector_t;
  mid: Psector_t;
  opentop: fixed_t;
  openbottom: fixed_t;
  divl: divline_t;
  v1: Pvertex_t;
  v2: Pvertex_t;
  frac: fixed_t;
  slope: fixed_t;
  front_floorheight: fixed_t;
  back_floorheight: fixed_t;
  front_ceilingheight: fixed_t;
  back_ceilingheight: fixed_t;
  vmidx: fixed_t;
  vmidy: fixed_t;
{$ENDIF}
begin
{$IFDEF HEXEN}
  offset := y * bmapwidth + x;
{$ELSE}
  sub := @subsectors[num];
{$ENDIF}

{$IFDEF HEXEN}
  polyLink := PolyBlockMap[offset];
  while polyLink <> nil do
{$ELSE}
  if sub.poly <> nil then
{$ENDIF}
  begin
{$IFDEF HEXEN}
    if polyLink.polyobj <> nil then
    begin // only check non-empty links
      if polyLink.polyobj.validcount <> validcount then
      begin
        segList := polyLink.polyobj.segs;
        for i := 0 to polyLink.polyobj.numsegs - 1 do
        begin
          if segList^.miniseg then
          begin
            inc(segList);
            continue; // line isn't crossed
          end;
          ld := segList^.linedef;
          if ld.validcount = validcount then
          begin
            inc(segList);
            continue;
          end;

          ld.validcount := validcount;
          s1 := P_PointOnDivlineSide(ld.v1.x, ld.v1.y, @trace);
          s2 := P_PointOnDivlineSide(ld.v2.x, ld.v2.y, @trace);
          if s1 = s2 then
          begin
            inc(segList);
            continue; // line isn't crossed
          end;

          P_MakeDivline(ld, @dl);
          s1 := P_PointOnDivlineSide(trace.x, trace.y, @dl);
          s2 := P_PointOnDivlineSide(trace.x + trace.dx, trace.y + trace.dy, @dl);
          if s1 = s2 then
          begin
            inc(segList);
            continue; // line isn't crossed
          end;

        // try to early out the check
          if ld.backsector = nil then
          begin
            result := false;  // stop checking
            exit;
          end;

        // store the line for later intersection testing
          P_GrowIntercepts;
          intercepts[intercept_p].d.line := ld;
          inc(intercept_p);
          inc(segList);
        end;
        polyLink.polyobj.validcount := validcount;
      end;
    end;
    polyLink := polyLink.next;
{$ELSE}
    result := P_CrossSubsecPolyObj(sub.poly, los);
    if not result then
      exit;
{$ENDIF}
  end;

{$IFDEF HEXEN}
  offset := blockmap[offset];

  list := @blockmaplump[offset];
  while list^ <> -1 do
{$ELSE}
  // check lines
  seg := @segs[sub.firstline - 1];
  for i := 0 to sub.numlines - 1 do
{$ENDIF}
  begin
{$IFDEF HEXEN}
    ld := @lines[list^];
    if ld.validcount = validcount then
    begin
      inc(list);
      continue; // line has already been checked
    end;
    ld.validcount := validcount;
{$ELSE}
    inc(seg);
    if seg.miniseg then // JVAL: skip minisegs
      continue;
{$ENDIF}

{$IFDEF HEXEN}
    s1 := P_PointOnDivlineSide (ld.v1.x, ld.v1.y, @trace);
    s2 := P_PointOnDivlineSide (ld.v2.x, ld.v2.y, @trace);
    if s1 = s2 then
    begin
      inc(list);
      continue; // line isn't crossed
    end;
    P_MakeDivline(ld, @dl);
    s1 := P_PointOnDivlineSide (trace.x, trace.y, @dl);
    s2 := P_PointOnDivlineSide (trace.x + trace.dx, trace.y + trace.dy, @dl);
    if s1 = s2 then
    begin
      inc(list);
      continue; // line isn't crossed
    end;
{$ELSE}
    line := seg.linedef;
{$ENDIF}

{$IF DEFINED(HERETIC)}
    // allready checked other side?
    if line.validcount = validcount then
      continue;

    line.validcount := validcount;

    // JVAL: 3d Floors
    if G_PlayingEngineVersion >= VERSION115 then
      if (line.bbox[BOX_LEFT] > los.bbox[BOX_RIGHT]) or
         (line.bbox[BOX_RIGHT] < los.bbox[BOX_LEFT]) or
         (line.bbox[BOX_BOTTOM] > los.bbox[BOX_TOP]) or
         (line.bbox[BOX_TOP] < los.bbox[BOX_BOTTOM]) then
        continue;

    v1 := line.v1;
    v2 := line.v2;
    s1 := P_DivlineSide(v1.x, v1.y, @los.strace);
    s2 := P_DivlineSide(v2.x, v2.y, @los.strace);

    // line isn't crossed?
    if s1 = s2 then
      continue;

    divl.x := v1.x;
    divl.y := v1.y;
    divl.dx := v2.x - v1.x;
    divl.dy := v2.y - v1.y;
    s1 := P_DivlineSide(los.strace.x, los.strace.y, @divl);
    s2 := P_DivlineSide(los.t2x, los.t2y, @divl);

    // line isn't crossed?
    if s1 = s2 then
      continue;

    // stop because it is not two sided anyway
    // might do this after updating validcount?
    if line.flags and ML_TWOSIDED = 0 then
{$ELSEIF DEFINED(HEXEN)}
  // try to early out the check
    if ld.backsector = nil then
{$ELSE}
    // allready checked other side?
    if line.validcount = validcount then
      continue;

    line.validcount := validcount;

    // JVAL: 3d Floors
    if G_PlayingEngineVersion >= VERSION122 then
      if (line.bbox[BOX_LEFT] > los.bbox[BOX_RIGHT]) or
         (line.bbox[BOX_RIGHT] < los.bbox[BOX_LEFT]) or
         (line.bbox[BOX_BOTTOM] > los.bbox[BOX_TOP]) or
         (line.bbox[BOX_TOP] < los.bbox[BOX_BOTTOM]) then
        continue;

    v1 := line.v1;
    v2 := line.v2;
    s1 := P_DivlineSide(v1.x, v1.y, @los.strace);
    s2 := P_DivlineSide(v2.x, v2.y, @los.strace);

    // line isn't crossed?
    if s1 = s2 then
      continue;

    divl.x := v1.x;
    divl.y := v1.y;
    divl.dx := v2.x - v1.x;
    divl.dy := v2.y - v1.y;
    s1 := P_DivlineSide(los.strace.x, los.strace.y, @divl);
    s2 := P_DivlineSide(los.t2x, los.t2y, @divl);

    // line isn't crossed?
    if s1 = s2 then
      continue;

    // stop because it is not two sided anyway
    // might do this after updating validcount?
    if line.flags and ML_TWOSIDED = 0 then
{$ENDIF}
    begin
{$IFDEF HEXEN}
      result := false;  // stop checking
{$ELSE}
      result := false;
{$ENDIF}
      exit;
    end;

{$IF DEFINED(HERETIC)}
    // crosses a two sided line
    back := seg.backsector;
    if back = nil then
    begin
      result := false;
      exit;
    end;

    // JVAL: 3d Floors
    if back.midsec >= 0 then
    begin
      mid := @sectors[back.midsec];
      if los.sightzstart <= mid.ceilingheight then
        if los.sightzstart >= mid.floorheight then
        begin
          result := false;
          exit;
        end;
    end;

    front := seg.frontsector;

    if G_PlayingEngineVersion >= VERSION115 then
    begin
      vmidx := (v1.x + v2.x) div 2;
      vmidy := (v1.y + v2.y) div 2;
      front_floorheight := P_FloorHeight(front, vmidx, vmidy);
      back_floorheight := P_FloorHeight(back, vmidx, vmidy);
      front_ceilingheight := P_CeilingHeight(front, vmidx, vmidy);
      back_ceilingheight := P_CeilingHeight(back, vmidx, vmidy);
    end
    else
    begin
      front_floorheight := front.floorheight;
      back_floorheight := back.floorheight;
      front_ceilingheight := front.ceilingheight;
      back_ceilingheight := back.ceilingheight;
    end;

    // no wall to block sight with?
    if (front_floorheight = back_floorheight) and
       (front_ceilingheight = back_ceilingheight) then
      continue;

    // possible occluder
    // because of ceiling height differences
    if front_ceilingheight < back_ceilingheight then
      opentop := front_ceilingheight + P_SectorJumpOverhead(front)
    else
      opentop := back_ceilingheight + P_SectorJumpOverhead(back);

    // because of ceiling height differences
    if front_floorheight > back_floorheight then
      openbottom := front_floorheight
    else
      openbottom := back_floorheight;

    // quick test for totally closed doors
    if openbottom >= opentop then
    begin
      result := false; // stop
      exit;
    end;

    frac := P_InterceptVector2(@los.strace, @divl);

    if front_floorheight <> back_floorheight then
    begin
      slope := FixedDiv(openbottom - los.sightzstart, frac);
      if slope > los.bottomslope then
        los.bottomslope := slope;
    end;

    if front_ceilingheight <> back_ceilingheight then
    begin
      slope := FixedDiv(opentop - los.sightzstart, frac);
      if slope < los.topslope then
        los.topslope := slope;
    end;

    if los.topslope <= los.bottomslope then
    begin
      result := false; // stop
      exit;
    end;
{$ELSEIF DEFINED(HEXEN)}
    P_GrowIntercepts;
    // store the line for later intersection testing
    intercepts[intercept_p].d.line := ld;
    inc(intercept_p);
    inc(list);
{$ELSE}
    // crosses a two sided line
    back := seg.backsector;
    if back = nil then
    begin
      result := false;
      exit;
    end;

    // JVAL: 3d Floors
    if back.midsec >= 0 then
    begin
      mid := @sectors[back.midsec];
      if los.sightzstart <= mid.ceilingheight then
        if los.sightzstart >= mid.floorheight then
        begin
          result := false;
          exit;
        end;
    end;

    front := seg.frontsector;

    if G_PlayingEngineVersion >= VERSION122 then
    begin
      vmidx := (v1.x + v2.x) div 2;
      vmidy := (v1.y + v2.y) div 2;
      front_floorheight := P_FloorHeight(front, vmidx, vmidy);
      back_floorheight := P_FloorHeight(back, vmidx, vmidy);
      front_ceilingheight := P_CeilingHeight(front, vmidx, vmidy);
      back_ceilingheight := P_CeilingHeight(back, vmidx, vmidy);
    end
    else
    begin
      front_floorheight := front.floorheight;
      back_floorheight := back.floorheight;
      front_ceilingheight := front.ceilingheight;
      back_ceilingheight := back.ceilingheight;
    end;

    // no wall to block sight with?
    if (front_floorheight = back_floorheight) and
       (front_ceilingheight = back_ceilingheight) then
      continue;

    // possible occluder
    // because of ceiling height differences
    if front_ceilingheight < back_ceilingheight then
      opentop := front_ceilingheight + P_SectorJumpOverhead(front)
    else
      opentop := back_ceilingheight + P_SectorJumpOverhead(back);

    // because of ceiling height differences
    if front_floorheight > back_floorheight then
      openbottom := front_floorheight
    else
      openbottom := back_floorheight;

    // quick test for totally closed doors
    if openbottom >= opentop then
    begin
      result := false; // stop
      exit;
    end;

    frac := P_InterceptVector2(@los.strace, @divl);

    if front_floorheight <> back_floorheight then
    begin
      slope := FixedDiv(openbottom - los.sightzstart, frac);
      if slope > los.bottomslope then
        los.bottomslope := slope;
    end;

    if front_ceilingheight <> back_ceilingheight then
    begin
      slope := FixedDiv(opentop - los.sightzstart, frac);
      if slope < los.topslope then
        los.topslope := slope;
    end;

    if los.topslope <= los.bottomslope then
    begin
      result := false; // stop
      exit;
    end;
{$ENDIF}
  end;

{$IFDEF HEXEN}
  result := true; // everything was checked
{$ELSE}
  // passed the subsector ok
  result := true;
{$ENDIF}
end;

//==============================================================================
//
{$IFDEF HEXEN}
//====================
//
// P_SightTraverseIntercepts
//
// Returns true if the traverser function returns true for all lines
//====================
{$ELSE}
// P_CrossBSPNode
// Returns true
//  if strace crosses the given node successfully.
{$ENDIF}
//
//==============================================================================
{$IFDEF HEXEN}
function P_SightTraverseIntercepts: boolean;
{$ELSE}
function P_CrossBSPNode(bspnum: integer; const los: Plos_t): boolean;
{$ENDIF}
var
{$IFDEF HEXEN}
  i: integer;
  count: integer;
  dist: fixed_t;
  scan, _in: Pintercept_t;
  dl: divline_t;
{$ELSE}
  bsp: Pnode_t;
  side: integer;
{$ENDIF}
begin
{$IFDEF HEXEN}
  count := intercept_p;
//
// calculate intercept distance
//
  for i := 0 to count - 1 do
{$ELSE}
  if bspnum and NF_SUBSECTOR_V5 <> 0 then
{$ENDIF}
  begin
{$IFDEF HEXEN}
    scan := @intercepts[i];
    P_MakeDivline(scan.d.line, @dl);
    scan.frac := P_InterceptVector (@trace, @dl);
{$ELSE}
    if bspnum = -1 then
      result := P_CrossSubsector(0, los)
    else
      result := P_CrossSubsector(bspnum and not NF_SUBSECTOR_V5, los);
    exit;
{$ENDIF}
  end;

{$IFDEF HEXEN}
//
// go through in order
//
  _in := nil; // shut up compiler warning
{$ELSE}
  bsp := @nodes[bspnum];
{$ENDIF}

{$IFDEF HEXEN}
  while count > 0 do
  begin
    dist := MAXINT;
    for i := 0 to intercept_p - 1 do
    begin
      scan := @intercepts[i];
      if scan.frac < dist then
      begin
        dist := scan.frac;
        _in := scan;
      end;
    end;
{$ELSE}
  // decide which side the start point is on
  side := P_DivlineSide(los.strace.x, los.strace.y, Pdivline_t(bsp));
  if side = 2 then
    side := 0; // an "on" should cross both sides
{$ENDIF}

{$IFDEF HEXEN}
    if not PTR_SightTraverse(_in) then
    begin
      result := false;  // don't bother going farther
      exit;
    end;
    _in.frac := MAXINT;
    dec(count);
  end;

  result := true; // everything was traversed
end;

//==============================================================================
// P_SightPathTraverse32
//
//==================
//
// P_SightPathTraverse
//
// Traces a line from x1,y1 to x2,y2, calling the traverser function for each
// Returns true if the traverser function returns true for all lines
//==================
//
//==============================================================================
function P_SightPathTraverse32(x1, y1, x2, y2: fixed_t): boolean;
var
  xt1, yt1, xt2, yt2: fixed_t;
  xstep, ystep: fixed_t;
  partial: fixed_t;
  xintercept, yintercept: fixed_t;
  mapx, mapy, mapxstep, mapystep: integer;
  count: integer;
begin
  inc(validcount);
  intercept_p := 0;

  if (x1 - bmaporgx) and (MAPBLOCKSIZE - 1) = 0 then
    x1 := x1 + FRACUNIT;  // don't side exactly on a line
  if (y1 - bmaporgy) and (MAPBLOCKSIZE - 1) = 0 then
    y1 := y1 + FRACUNIT;  // don't side exactly on a line
  trace.x := x1;
  trace.y := y1;
  trace.dx := x2 - x1;
  trace.dy := y2 - y1;

  x1 := x1 - bmaporgx;
  y1 := y1 - bmaporgy;
  xt1 := MapBlockInt(x1);
  yt1 := MapBlockInt(y1);

  x2 := x2 - bmaporgx;
  y2 := y2 - bmaporgy;
  xt2 := MapBlockInt(x2);
  yt2 := MapBlockInt(y2);

// points should never be out of bounds, but check once instead of
// each block
  if (xt1 < 0) or (yt1 < 0) or (xt1 >= bmapwidth) or (yt1 >= bmapheight) or
     (xt2 < 0) or (yt2 < 0) or (xt2 >= bmapwidth) or (yt2 >= bmapheight) then
{$ELSE}
  // cross the starting side
  if not P_CrossBSPNode(bsp.children[side], los) then
{$ENDIF}
  begin
    result := false;
    exit;
  end;

{$IFDEF HEXEN}
  if xt2 > xt1 then
{$ELSE}
  // the partition plane is crossed here
  if side = P_DivlineSide(los.t2x, los.t2y, Pdivline_t(bsp)) then
{$ENDIF}
  begin
{$IFDEF HEXEN}
    mapxstep := 1;
    partial := FRACUNIT - MapToFrac(x1) and (FRACUNIT - 1);
    ystep := FixedDiv(y2 - y1, abs(x2 - x1));
  end
  else if xt2 < xt1 then
  begin
    mapxstep := -1;
    partial := MapToFrac(x1) and (FRACUNIT - 1);
    ystep := FixedDiv(y2 - y1, abs(x2 - x1));
  end
  else
  begin
    mapxstep := 0;
    partial := FRACUNIT;
    ystep := 256 * FRACUNIT;
  end;
  yintercept := MapToFrac(y1) + FixedMul(partial, ystep);

  if yt2 > yt1 then
  begin
    mapystep := 1;
    partial := FRACUNIT - MapToFrac(y1) and (FRACUNIT - 1);
    xstep := FixedDiv(x2 - x1, abs(y2 - y1));
  end
  else if yt2 < yt1 then
  begin
    mapystep := -1;
    partial := MapToFrac(y1) and (FRACUNIT - 1);
    xstep := FixedDiv(x2 - x1, abs(y2 - y1));
  end
  else
  begin
    mapystep := 0;
    partial := FRACUNIT;
    xstep := 256 * FRACUNIT;
  end;
  xintercept := MapToFrac(x1) + FixedMul(partial, xstep);

//
// step through map blocks
// Count is present to prevent a round off error from skipping the break
  mapx := xt1;
  mapy := yt1;

  for count := 0 to 63 do
  begin
    if not P_SightBlockLinesIterator(mapx, mapy) then
    begin
      result := false;   // early out
      exit;
    end;

    if (mapx = xt2) and (mapy = yt2) then
      break;

    if FixedInt(yintercept) = mapy then
    begin
      yintercept := yintercept + ystep;
      mapx := mapx + mapxstep;
    end
    else if FixedInt(xintercept) = mapx then
    begin
      xintercept := xintercept + xstep;
      mapy := mapy + mapystep;
    end;

{$ELSE}
    // the line doesn't touch the other side
    result := true;
    exit;
{$ENDIF}
  end;

{$IFDEF HEXEN}
//
// couldn't early out, so go through the sorted list
//
  result := P_SightTraverseIntercepts;
{$ELSE}
  // cross the ending side
  result := P_CrossBSPNode(bsp.children[side xor 1], los);
{$ENDIF}
end;

//==============================================================================
//
{$IF DEFINED(DOOM)}
// P_CrossVanillaSubsector
// Returns true
//  if strace crosses the given subsector successfully.
//
//==============================================================================
function P_CrossVanillaSubsector(num: integer; const los: Plos_t): boolean;
var
  seg: Pvanillaseg_t;
  line: Pline_t;
  s1: integer;
  s2: integer;
  i: integer;
  sub: Pvanillasubsector_t;
  front: Psector_t;
  back: Psector_t;
  opentop: fixed_t;
  openbottom: fixed_t;
  divl: divline_t;
  v1: Pvertex_t;
  v2: Pvertex_t;
  frac: fixed_t;
  slope: fixed_t;
begin
  sub := @vanillasubsectors[num];

  // check lines
  for i := sub.firstline to sub.firstline + sub.numlines - 1 do
  begin
    seg := @vanillasegs[i];
    line := seg.linedef;

    // allready checked other side?
    if line.validcount = validcount then
      continue;

    line.validcount := validcount;

    v1 := line.v1;
    v2 := line.v2;
    s1 := P_DivlineSide(v1.x, v1.y, @los.strace);
    s2 := P_DivlineSide(v2.x, v2.y, @los.strace);

    // line isn't crossed?
    if s1 = s2 then
      continue;

    divl.x := v1.x;
    divl.y := v1.y;
    divl.dx := v2.x - v1.x;
    divl.dy := v2.y - v1.y;
    s1 := P_DivlineSide(los.strace.x, los.strace.y, @divl);
    s2 := P_DivlineSide(los.t2x, los.t2y, @divl);

    // line isn't crossed?
    if s1 = s2 then
      continue;

    // stop because it is not two sided anyway
    // might do this after updating validcount?
    if line.flags and ML_TWOSIDED = 0 then
    begin
      Result := False;
      exit;
    end;

    // crosses a two sided line
    front := seg.frontsector;
    back := seg.backsector;

    // no wall to block sight with?
    if (front.floorheight = back.floorheight) and
      (front.ceilingheight = back.ceilingheight) then
      continue;

    // possible occluder
    // because of ceiling height differences
    if front.ceilingheight < back.ceilingheight then
      opentop := front.ceilingheight
    else
      opentop := back.ceilingheight;

    // because of ceiling height differences
    if front.floorheight > back.floorheight then
      openbottom := front.floorheight
    else
      openbottom := back.floorheight;

    // quick test for totally closed doors
    if openbottom >= opentop then
    begin
      Result := False; // stop
      exit;
    end;

    frac := P_InterceptVector2(@los.strace, @divl);

    if front.floorheight <> back.floorheight then
    begin
      slope := FixedDiv(openbottom - los.sightzstart, frac);
      if slope > los.bottomslope then
        los.bottomslope := slope;
    end;

    if front.ceilingheight <> back.ceilingheight then
    begin
      slope := FixedDiv(opentop - los.sightzstart, frac);
      if slope < los.topslope then
        los.topslope := slope;
    end;

    if los.topslope <= los.bottomslope then
    begin
      Result := False; // stop
      exit;
    end;
  end;

  // passed the subsector ok
  Result := True;
end;

//==============================================================================
//
// P_CrossVanillaBSPNode
// Returns true
//  if strace crosses the given node successfully.
//
//==============================================================================
function P_CrossVanillaBSPNode(bspnum: integer; const los: Plos_t): boolean;
var
  bsp: Pvanillanode_t;
  side: integer;
begin
  if bspnum and NF_SUBSECTOR <> 0 then
  begin
    if bspnum = -1 then
      Result := P_CrossVanillaSubsector(0, los)
    else
      Result := P_CrossVanillaSubsector(bspnum and not NF_SUBSECTOR, los);
    exit;
  end;

  bsp := @vanillanodes[bspnum];

  // decide which side the start point is on
  side := P_DivlineSide(los.strace.x, los.strace.y, Pdivline_t(bsp));
  if side = 2 then
    side := 0; // an "on" should cross both sides

  // cross the starting side
  if not P_CrossVanillaBSPNode(bsp.children[side], los) then
  begin
    Result := False;
    exit;
  end;

  // the partition plane is crossed here
  if side = P_DivlineSide(los.t2x, los.t2y, Pdivline_t(bsp)) then
  begin
    // the line doesn't touch the other side
    Result := True;
    exit;
  end;

  // cross the ending side
  Result := P_CrossVanillaBSPNode(bsp.children[side xor 1], los);
end;

//==============================================================================
//
{$ELSEIF DEFINED(HEXEN)}
// P_SightPathTraverse64
//
//==============================================================================
function P_SightPathTraverse64(x1, y1, x2, y2: fixed_t): boolean;
var
  _x1, _x2, _y1, _y2: int64;
  xt1, yt1, xt2, yt2: fixed_t;
  xstep, ystep: fixed_t;
  partial: fixed_t;
  xintercept, yintercept: fixed_t;
  mapx, mapy, mapxstep, mapystep: integer;
  count: integer;
begin
  inc(validcount);
  intercept_p := 0;

  if (x1 - bmaporgx) and (MAPBLOCKSIZE - 1) = 0 then
    x1 := x1 + FRACUNIT;  // don't side exactly on a line
  if (y1 - bmaporgy) and (MAPBLOCKSIZE - 1) = 0 then
    y1 := y1 + FRACUNIT;  // don't side exactly on a line
  trace.x := x1;
  trace.y := y1;
  trace.dx := x2 - x1;
  trace.dy := y2 - y1;

  _x1 := x1 - bmaporgx;
  _y1 := y1 - bmaporgy;
  if (_x1 < MININT) or (_x1 > MAXINT) or (_y1 < MININT) or (_y1 > MAXINT) then
  begin
    result := false;
    exit;
  end;

  x1 := _x1;
  y1 := _y1;
  xt1 := MapBlockIntX(x1);
  yt1 := MapBlockIntY(y1);

  _x2 := x2 - bmaporgx;
  _y2 := y2 - bmaporgy;
  if (_x2 < MININT) or (_x2 > MAXINT) or (_y2 < MININT) or (_y2 > MAXINT) then
  begin
    result := false;
    exit;
  end;

  x1 := _x1;
  x2 := _x2;
  xt2 := MapBlockIntX(x2);
  yt2 := MapBlockIntY(y2);

// points should never be out of bounds, but check once instead of
// each block
  if (xt1 < 0) or (yt1 < 0) or (xt1 >= bmapwidth) or (yt1 >= bmapheight) or
     (xt2 < 0) or (yt2 < 0) or (xt2 >= bmapwidth) or (yt2 >= bmapheight) then
  begin
    result := false;
    exit;
  end;

  if xt2 > xt1 then
  begin
    mapxstep := 1;
    partial := FRACUNIT - MapToFrac(x1) and (FRACUNIT - 1);
    ystep := FixedDiv(y2 - y1, abs(x2 - x1));
  end
  else if xt2 < xt1 then
  begin
    mapxstep := -1;
    partial := MapToFrac(x1) and (FRACUNIT - 1);
    ystep := FixedDiv(y2 - y1, abs(x2 - x1));
  end
  else
  begin
    mapxstep := 0;
    partial := FRACUNIT;
    ystep := 256 * FRACUNIT;
  end;
  yintercept := MapToFrac(y1) + FixedMul(partial, ystep);

  if yt2 > yt1 then
  begin
    mapystep := 1;
    partial := FRACUNIT - MapToFrac(y1) and (FRACUNIT - 1);
    xstep := FixedDiv(x2 - x1, abs(y2 - y1));
  end
  else if yt2 < yt1 then
  begin
    mapystep := -1;
    partial := MapToFrac(y1) and (FRACUNIT - 1);
    xstep := FixedDiv(x2 - x1, abs(y2 - y1));
  end
  else
  begin
    mapystep := 0;
    partial := FRACUNIT;
    xstep := 256 * FRACUNIT;
  end;
  xintercept := MapToFrac(x1) + FixedMul(partial, xstep);

//
// step through map blocks
// Count is present to prevent a round off error from skipping the break
  mapx := xt1;
  mapy := yt1;

  for count := 0 to 63 do
  begin
    if not P_SightBlockLinesIterator(mapx, mapy) then
    begin
      result := false;   // early out
      exit;
    end;

    if (mapx = xt2) and (mapy = yt2) then
      break;

    if FixedInt(yintercept) = mapy then
    begin
      yintercept := yintercept + ystep;
      mapx := mapx + mapxstep;
    end
    else if FixedInt(xintercept) = mapx then
    begin
      xintercept := xintercept + xstep;
      mapy := mapy + mapystep;
    end;

  end;

//
// couldn't early out, so go through the sorted list
//
  result := P_SightTraverseIntercepts;
end;

//==============================================================================
//
// P_SightPathTraverse
//
//==============================================================================
function P_SightPathTraverse(x1, y1, x2, y2: fixed_t): boolean;
begin
  if largemap or internalblockmapformat then
    result := P_SightPathTraverse64(x1, y1, x2, y2)
  else
    result := P_SightPathTraverse32(x1, y1, x2, y2);
end;

//==============================================================================
//
//=====================
//
{$ENDIF}
// P_CheckSight
{$IFDEF HEXEN}
//
// Returns true if a straight line between t1 and t2 is unobstructed
// look from eyes of t1 to any part of t2
//
//=====================
{$ELSE}
// Returns true
//  if a straight line between t1 and t2 is unobstructed.
// Uses REJECT.
{$ENDIF}
//
//==============================================================================
function P_CheckSight(t1: Pmobj_t; t2: Pmobj_t): boolean;
var
  s1: integer;
  s2: integer;
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  hsec1: integer;
  hsec2: integer;
{$ENDIF}
  pnum: integer;
  bytenum: integer;
  bitnum: integer;
{$IFNDEF HEXEN}
  los: los_t;
{$ENDIF}
  mid: Psector_t; // JVAL: 3d Floors
  midn: integer;
begin
  // First check for trivial rejection.

  // Determine subsector entries in REJECT table.
{$IF DEFINED(HERETIC)}
  s1 := pDiff(Psubsector_t(t1.subsector).sector, @sectors[0], SizeOf(sectors[0]));
  s2 := pDiff(Psubsector_t(t2.subsector).sector, @sectors[0], SizeOf(sectors[0]));
{$ELSEIF DEFINED(HEXEN)}
  s1 := (integer(Psubsector_t(t1.subsector).sector) - integer(sectors)) div SizeOf(sector_t);
  s2 := (integer(Psubsector_t(t2.subsector).sector) - integer(sectors)) div SizeOf(sector_t);
{$ELSE}
  s1 := pDiff(Psubsector_t(t1.subsector).sector, sectors, SizeOf(sector_t));
  s2 := pDiff(Psubsector_t(t2.subsector).sector, sectors, SizeOf(sector_t));
{$ENDIF}

  if numsectors > 1 then
  begin
    pnum := s1 * numsectors + s2;
    bytenum := pnum div 8;
    bitnum := 1 shl (pnum and 7);

    // Check in REJECT table.
    if bytenum >= 0 then
      if bytenum < rejectmatrixsize then
        if rejectmatrix[bytenum] and bitnum <> 0 then
        begin
          // can't possibly be connected
          result := false;
          exit;
        end;

  end;

  // JVAL: 3D floors
  midn := sectors[s2].midsec;
  if midn > -1 then
  begin
    mid := @sectors[midn];
    if ((t1.z + t1.height <= mid.floorheight) and (t2.z >= mid.floorheight)) or
       ((t1.z >= mid.ceilingheight) and (t2.z + t1.height <= mid.ceilingheight)) then
    begin
      result := false;
      exit;
    end;
  end;

{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  hsec1 := sectors[s1].heightsec;
  if (hsec1 <> -1) and
       (((t1.z + t1.height <= sectors[hsec1].floorheight) and
         (t2.z >= sectors[hsec1].floorheight)) or
        ((t1.z >= sectors[hsec1].ceilingheight) and
         (t2.z + t1.height <= sectors[hsec1].ceilingheight))) then
  begin
    result := false;
    exit;
  end;

  hsec2 := sectors[s2].heightsec;
  if (hsec2 <> -1) and
       (((t2.z + t2.height <= sectors[hsec2].floorheight) and
         (t1.z >= sectors[hsec2].floorheight)) or
        ((t2.z >= sectors[hsec2].ceilingheight) and
         (t1.z + t2.height <= sectors[hsec2].ceilingheight))) then
  begin
    result := false;
    exit;
  end;

{$ENDIF}
  // JVAL: 3D floors
{$IF DEFINED(HERETIC)}
  if G_PlayingEngineVersion >= VERSION115 then
{$ELSEIF DEFINED(HEXEN)}
  if G_PlayingEngineVersion >= VERSION142 then
{$ELSE}
  if G_PlayingEngineVersion >= VERSION122 then
{$ENDIF}
  begin
    if (G_PlayingEngineVersion < VERSION204) or ((G_PlayingEngineVersion = VERSION204) and (demoplayback or demorecording)) then
    begin
      if Psubsector_t(t1.subsector).sector = Psubsector_t(t2.subsector).sector then
      begin
        result := t1.floorz = t2.floorz;
        exit;
      end;
    end
    // JVAL 20191206 - Fix problem reported by slayermbm
    // https://www.doomworld.com/forum/topic/92113-delphidoom-204720-updated-oct-12-2019/?do=findComment&comment=2051252
    else
    begin
      if midn > -1 then
        if Psubsector_t(t1.subsector).sector = Psubsector_t(t2.subsector).sector then
        begin
          result := t1.floorz = t2.floorz;
          exit;
        end;
    end;
  end;

{$IFDEF HEXEN}
//
// check precisely
//
  sightzstart := t1.z + t1.height - _SHR2(t1.height);
  topslope := (t2.z + t2.height) - sightzstart;
  bottomslope := t2.z - sightzstart;
{$ELSE}
  // An unobstructed LOS is possible.
  // Now look from eyes of t1 to any part of t2.
  inc(validcount);
{$ENDIF}

{$IF DEFINED(DOOM)}
  los.sightzstart := t1.z + t1.height - (t1.height div 4);
  los.topslope := (t2.z + t2.height) - los.sightzstart;
  los.bottomslope := t2.z - los.sightzstart;

  los.strace.x := t1.x;
  los.strace.y := t1.y;
  los.t2x := t2.x;
  los.t2y := t2.y;
  los.strace.dx := t2.x - t1.x;
  los.strace.dy := t2.y - t1.y;

  if t1.x > t2.x then
  begin
    los.bbox[BOX_RIGHT] := t1.x;
    los.bbox[BOX_LEFT] := t2.x;
  end
  else
  begin
    los.bbox[BOX_RIGHT] := t2.x;
    los.bbox[BOX_LEFT] := t1.x;
  end;

  if t1.y > t2.y then
  begin
    los.bbox[BOX_TOP] := t1.y;
    los.bbox[BOX_BOTTOM] := t2.y;
  end
  else
  begin
    los.bbox[BOX_TOP] := t2.y;
    los.bbox[BOX_BOTTOM] := t1.y;
  end;

  // the head node is the last node output
  if G_IsOldDemoPlaying and hasvanillanodes then
    result := P_CrossVanillaBSPNode(numvanillanodes - 1, @los)
  else
    result := P_CrossBSPNode(numnodes - 1, @los);
end;

//==============================================================================
//
// P_CheckCameraSight
//
// JVAL: To determine if camera chase view can see the player
//
//==============================================================================
function P_CheckCameraSight(const camx, camy, camz: fixed_t; const mo: Pmobj_t): boolean;
var
  los: los_t;
begin
  if mo = nil then
  begin
    result := false;
    exit;
  end;

  // An unobstructed LOS is possible.
  // Now look from eyes of t1 to any part of t2.
  inc(validcount);

  los.sightzstart := camz + mo.height - (mo.height div 4);
  los.topslope := (mo.z + mo.height) - los.sightzstart;
  los.bottomslope := mo.z - los.sightzstart;

  los.strace.x := camx;
  los.strace.y := camy;
  los.t2x := mo.x;
  los.t2y := mo.y;
  los.strace.dx := mo.x - camx;
  los.strace.dy := mo.y - camy;

  if camx > mo.x then
  begin
    los.bbox[BOX_RIGHT] := camx;
    los.bbox[BOX_LEFT] := mo.x;
  end
  else
  begin
    los.bbox[BOX_RIGHT] := mo.x;
    los.bbox[BOX_LEFT] := camx;
  end;

  if camy > mo.y then
  begin
    los.bbox[BOX_TOP] := camy;
    los.bbox[BOX_BOTTOM] := mo.y;
  end
  else
  begin
    los.bbox[BOX_TOP] := mo.y;
    los.bbox[BOX_BOTTOM] := camy;
  end;

  // the head node is the last node output
  result := P_CrossBSPNode(numnodes - 1, @los);
{$ELSEIF DEFINED(HEXEN)}
  result := P_SightPathTraverse(t1.x, t1.y, t2.x, t2.y);
{$ELSE}
  los.sightzstart := t1.z + t1.height - (t1.height div 4);
  los.topslope := (t2.z + t2.height) - los.sightzstart;
  los.bottomslope := t2.z - los.sightzstart;

  los.strace.x := t1.x;
  los.strace.y := t1.y;
  los.t2x := t2.x;
  los.t2y := t2.y;
  los.strace.dx := t2.x - t1.x;
  los.strace.dy := t2.y - t1.y;

  if t1.x > t2.x then
  begin
    los.bbox[BOX_RIGHT] := t1.x;
    los.bbox[BOX_LEFT] := t2.x;
  end
  else
  begin
    los.bbox[BOX_RIGHT] := t2.x;
    los.bbox[BOX_LEFT] := t1.x;
  end;

  if t1.y > t2.y then
  begin
    los.bbox[BOX_TOP] := t1.y;
    los.bbox[BOX_BOTTOM] := t2.y;
  end
  else
  begin
    los.bbox[BOX_TOP] := t2.y;
    los.bbox[BOX_BOTTOM] := t1.y;
  end;

  // the head node is the last node output
  result := P_CrossBSPNode(numnodes - 1, @los);
end;

//==============================================================================
//
// P_CheckCameraSight
//
// JVAL: To determine if camera chase view can see the player
//
//==============================================================================
function P_CheckCameraSight(const camx, camy, camz: fixed_t; const mo: Pmobj_t): boolean;
var
  los: los_t;
begin
  if mo = nil then
  begin
    result := false;
    exit;
  end;

  // An unobstructed LOS is possible.
  // Now look from eyes of t1 to any part of t2.
  inc(validcount);

  los.sightzstart := camz + mo.height - (mo.height div 4);
  los.topslope := (mo.z + mo.height) - los.sightzstart;
  los.bottomslope := mo.z - los.sightzstart;

  los.strace.x := camx;
  los.strace.y := camy;
  los.t2x := mo.x;
  los.t2y := mo.y;
  los.strace.dx := mo.x - camx;
  los.strace.dy := mo.y - camy;

  if camx > mo.x then
  begin
    los.bbox[BOX_RIGHT] := camx;
    los.bbox[BOX_LEFT] := mo.x;
  end
  else
  begin
    los.bbox[BOX_RIGHT] := mo.x;
    los.bbox[BOX_LEFT] := camx;
  end;

  if camy > mo.y then
  begin
    los.bbox[BOX_TOP] := camy;
    los.bbox[BOX_BOTTOM] := mo.y;
  end
  else
  begin
    los.bbox[BOX_TOP] := mo.y;
    los.bbox[BOX_BOTTOM] := camy;
  end;

  // the head node is the last node output
  result := P_CrossBSPNode(numnodes - 1, @los);
{$ENDIF}
end;

//==============================================================================
//
// P_CheckSightXYZ
//
//==============================================================================
function P_CheckSightXYZ(const x, y, z: fixed_t; t2: Pmobj_t): boolean;
{$IFDEF DOOM}
var
  s1: integer;
  s2: integer;
  hsec1: integer;
  hsec2: integer;
  pnum: integer;
  bytenum: integer;
  bitnum: integer;
  los: los_t;
  mid: Psector_t; // JVAL: 3d Floors
  midn: integer;
{$ENDIF}
begin
{$IF DEFINED(DOOM)}
  if t2 = nil then
  begin
    result := false;
    exit;
  end;

  // First check for trivial rejection.

  // Determine subsector entries in REJECT table.
  s1 := R_PointInSubsector(x, y).sector.iSectorID;
  s2 := Psubsector_t(t2.subsector).sector.iSectorID;

  if numsectors > 1 then
  begin
    pnum := s1 * numsectors + s2;
    bytenum := pnum div 8;
    bitnum := 1 shl (pnum and 7);

    // Check in REJECT table.
    if bytenum >= 0 then
      if bytenum < rejectmatrixsize then
        if rejectmatrix[bytenum] and bitnum <> 0 then
        begin
          // can't possibly be connected
          result := false;
          exit;
        end;

  end;

  // JVAL: 3D floors
  midn := sectors[s2].midsec;
  if midn > -1 then
  begin
    mid := @sectors[midn];
    if ((z <= mid.floorheight) and (t2.z >= mid.floorheight)) or
       ((z >= mid.ceilingheight) and (t2.z <= mid.ceilingheight)) then
    begin
      result := false;
      exit;
    end;
  end;

  hsec1 := sectors[s1].heightsec;
  if (hsec1 <> -1) and
       (((z <= sectors[hsec1].floorheight) and
         (t2.z >= sectors[hsec1].floorheight)) or
        ((z >= sectors[hsec1].ceilingheight) and
         (t2.z <= sectors[hsec1].ceilingheight))) then
  begin
    result := false;
    exit;
  end;

  hsec2 := sectors[s2].heightsec;
  if (hsec2 <> -1) and
       (((t2.z + t2.height <= sectors[hsec2].floorheight) and
         (z >= sectors[hsec2].floorheight)) or
        ((t2.z >= sectors[hsec2].ceilingheight) and
         (z + t2.height <= sectors[hsec2].ceilingheight))) then
  begin
    result := false;
    exit;
  end;

  // An unobstructed LOS is possible.
  // Now look from eyes of t1 to any part of t2.
  inc(validcount);

  los.sightzstart := z;
  los.topslope := (t2.z + t2.height) - los.sightzstart;
  los.bottomslope := t2.z - los.sightzstart;

  los.strace.x := x;
  los.strace.y := y;
  los.t2x := t2.x;
  los.t2y := t2.y;
  los.strace.dx := t2.x - x;
  los.strace.dy := t2.y - y;

  if x > t2.x then
  begin
    los.bbox[BOX_RIGHT] := x;
    los.bbox[BOX_LEFT] := t2.x;
  end
  else
  begin
    los.bbox[BOX_RIGHT] := t2.x;
    los.bbox[BOX_LEFT] := x;
  end;

  if y > t2.y then
  begin
    los.bbox[BOX_TOP] := y;
    los.bbox[BOX_BOTTOM] := t2.y;
  end
  else
  begin
    los.bbox[BOX_TOP] := t2.y;
    los.bbox[BOX_BOTTOM] := y;
  end;

  // the head node is the last node output
  result := P_CrossBSPNode(numnodes - 1, @los);
end;

//==============================================================================
//
// P_CheckVisibility
//
// JVAL: General visibility check
// Checks if an object at (atx, aty, atz) with radious = atradious can be
// possibly visible
//
//==============================================================================
function P_CheckVisibility(const atx, aty, atz: fixed_t; const atradious: fixed_t): boolean;
var
  los: los_t;
begin
  inc(validcount);

  los.sightzstart := viewz + atradious - (atradious div 4);
  los.topslope := (atz + atradious) - los.sightzstart;
  los.bottomslope := atz - los.sightzstart;

  los.strace.x := viewx;
  los.strace.y := viewy;
  los.t2x := atx;
  los.t2y := aty;
  los.strace.dx := atx - viewx;
  los.strace.dy := aty - viewy;

  if viewx > atx then
  begin
    los.bbox[BOX_RIGHT] := viewx;
    los.bbox[BOX_LEFT] := atx;
  end
  else
  begin
    los.bbox[BOX_RIGHT] := atx;
    los.bbox[BOX_LEFT] := viewx;
  end;

  if viewy > aty then
  begin
    los.bbox[BOX_TOP] := viewy;
    los.bbox[BOX_BOTTOM] := aty;
  end
  else
  begin
    los.bbox[BOX_TOP] := aty;
    los.bbox[BOX_BOTTOM] := viewy;
  end;

  // the head node is the last node output
  result := P_CrossBSPNode(numnodes - 1, @los);
{$ELSEIF DEFINED(HEXEN)}
  Result := P_CheckCameraSight(x, y, z, t2);
end;

//==============================================================================
//
// P_CheckCameraSight
//
// JVAL: Check if the camera can see mo (=player.mo)
//
//==============================================================================
function P_CheckCameraSight(camx, camy, camz: fixed_t; mo: Pmobj_t): boolean;
begin
  if mo = nil then
  begin
    result := false;
    exit;
  end;

  inc(validcount);

  sightzstart := camz + mo.height - _SHR2(mo.height);
  topslope := (mo.z + mo.height) - sightzstart;
  bottomslope := mo.z - sightzstart;

  result := P_SightPathTraverse(camx, camy, mo.x, mo.y);
{$ELSE}
  Result := P_CheckCameraSight(x, y, z, t2);
end;

//==============================================================================
//
// P_CheckVisibility
//
// JVAL: General visibility check
// Checks if an object at (atx, aty, atz) with radious = atradious can be
// possibly visible
//
//==============================================================================
function P_CheckVisibility(const atx, aty, atz: fixed_t; const atradious: fixed_t): boolean;
var
  los: los_t;
begin
  inc(validcount);

  los.sightzstart := viewz + atradious - (atradious div 4);
  los.topslope := (atz + atradious) - los.sightzstart;
  los.bottomslope := atz - los.sightzstart;

  los.strace.x := viewx;
  los.strace.y := viewy;
  los.t2x := atx;
  los.t2y := aty;
  los.strace.dx := atx - viewx;
  los.strace.dy := aty - viewy;

  if viewx > atx then
  begin
    los.bbox[BOX_RIGHT] := viewx;
    los.bbox[BOX_LEFT] := atx;
  end
  else
  begin
    los.bbox[BOX_RIGHT] := atx;
    los.bbox[BOX_LEFT] := viewx;
  end;

  if viewy > aty then
  begin
    los.bbox[BOX_TOP] := viewy;
    los.bbox[BOX_BOTTOM] := aty;
  end
  else
  begin
    los.bbox[BOX_TOP] := aty;
    los.bbox[BOX_BOTTOM] := viewy;
  end;

  // the head node is the last node output
  result := P_CrossBSPNode(numnodes - 1, @los);
{$ENDIF}
end;

end.

