{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL level geometry - the OLD flat carver        }
{                                                                              }
{  The text of gld_PointOnSide, gld_CalcIntersectionVertex,                     }
{  gld_FlatEdgeClipper, gld_FlatConvexCarver, gld_CarveFlats and               }
{  gld_GetSubSectorVertices of gl_render.pas as they were before issue #177    }
{  (slice 4), with shims where they touched the engine: the BSP is a set of    }
{  arrays of the test, and the places where the polygon was written into the   }
{  vertex arrays and the loops of the sector call OldRecordLoop instead. It    }
{  is the reference of the parity tests. Win32 only (pointers as Integer).     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.OldFlatCarver;

interface

uses
  System.SysUtils,
  System.Classes;

type
  fixed_t = integer;

  vertex_t = packed record
    x: fixed_t;
    y: fixed_t;
    amvalidcount: integer;
    interpvalidcount: integer;
  end;
  Pvertex_t = ^vertex_t;
  vertex_tArray = packed array[0..$FFFF] of vertex_t;
  Pvertex_tArray = ^vertex_tArray;

  divline_t = record
    x: fixed_t;
    y: fixed_t;
    dx: fixed_t;
    dy: fixed_t;
  end;
  Pdivline_t = ^divline_t;
  divline_tArray = array[0..$FFFF] of divline_t;
  Pdivline_tArray = ^divline_tArray;

  OldNode = record
    x, y, dx, dy: fixed_t;
    children: array[0..1] of LongWord;
  end;
  POldNode = ^OldNode;

  OldSubsector = record
    sectorid: integer;
    numlines: LongWord;
    firstline: LongWord;
  end;
  POldSubsector = ^OldSubsector;

  OldSeg = record
    v1: Pvertex_t;
    v2: Pvertex_t;
  end;
  POldSeg = ^OldSeg;

  PBooleanArray = ^TBooleanArray;
  TBooleanArray = array[0..$FFFF] of boolean;

var
  // the BSP of the test
  old_nodes: array of OldNode;
  old_subsectors: array of OldSubsector;
  old_segs: array of OldSeg;
  // what the old code wrote: one line per polygon, "sector:x,y;x,y;..."
  old_loops: TStringList;

function gld_FlatEdgeClipper(numpoints: PInteger; points: Pvertex_tArray; numclippers: integer; clippers: Pdivline_tArray): Pvertex_tArray;
procedure gld_CarveFlats(bspnode: integer; numdivlines: integer; divlines: Pdivline_tArray; sectorclosed: PBooleanArray);
procedure gld_GetSubSectorVertices(sectorclosed: PBooleanArray);

implementation

const
  NF_SUBSECTOR = $8000;
  MAXINT = High(Integer);
  MININT = Low(Integer);
  MAX_CC_SIDES = 64;

procedure realloc(var p: pointer; const oldsize, newsize: integer);
begin
  ReallocMem(p, newsize);
end;

function malloc(const size: integer): pointer;
begin
  GetMem(Result, size);
end;

procedure memfree(var p: pointer; const size: integer);
begin
  FreeMem(p);
  p := nil;
end;

procedure memmove(dest, src: pointer; count: integer);
begin
  Move(src^, dest^, count);
end;

procedure memcpy(dest, src: pointer; count: integer);
begin
  Move(src^, dest^, count);
end;

procedure I_Error(const s: string);
begin
  raise Exception.Create(s);
end;

procedure OldRecordLoop(const sectorid: integer; const points: Pvertex_tArray; const count: integer);
var
  i: integer;
  s: string;
begin
  s := IntToStr(sectorid) + ':';
  for i := 0 to count - 1 do
    s := s + IntToStr(points[i].x) + ',' + IntToStr(points[i].y) + ';';
  old_loops.Add(s);
end;

// ------------------------- the old text starts here ---------------------------

function FIX2DBL(const x: fixed_t): double;
begin
  result := x / 1.0;
end;

function gld_PointOnSide(p: Pvertex_t; d: Pdivline_t): boolean;
begin
  // We'll return false if the point c is on the left side.
  result := (FIX2DBL(d.y) - FIX2DBL(p.y)) * FIX2DBL(d.dx) - (FIX2DBL(d.x) - FIX2DBL(p.x)) * FIX2DBL(d.dy) >= 0;
end;

procedure gld_CalcIntersectionVertex(s: Pvertex_t; e: Pvertex_t; d: Pdivline_t; i: Pvertex_t);
var
  ax: double;
  ay: double;
  bx: double;
  by: double;
  cx: double;
  cy: double;
  dx: double;
  dy: double;
  r: double;
begin
  ax := FIX2DBL(s.x);
  ay := FIX2DBL(s.y);
  bx := FIX2DBL(e.x);
  by := FIX2DBL(e.y);
  cx := FIX2DBL(d.x);
  cy := FIX2DBL(d.y);
  dx := cx + FIX2DBL(d.dx);
  dy := cy + FIX2DBL(d.dy);
  r := ((ay - cy) * (dx - cx) - (ax - cx) * (dy - cy)) / ((bx - ax) * (dy - cy) - (by - ay) * (dx - cx));
  i.x := round(FIX2DBL(s.x) + r * (FIX2DBL(e.x) - FIX2DBL(s.x)));
  i.y := round(FIX2DBL(s.y) + r * (FIX2DBL(e.y) - FIX2DBL(s.y)));
end;

function gld_FlatEdgeClipper(numpoints: PInteger; points: Pvertex_tArray; numclippers: integer; clippers: Pdivline_tArray): Pvertex_tArray;
var
  sidelist: array[0..MAX_CC_SIDES - 1] of boolean;
  i, k, num: integer;
  curclip: Pdivline_t;
  startIdx, endIdx: integer;
  newvert: vertex_t;
  previdx: integer;
begin
  num := numpoints^;
  // We'll clip the polygon with each of the divlines. The left side of
  // each divline is discarded.
  for i := 0 to numclippers - 1 do
  begin
    curclip := @clippers[i];

    // First we'll determine the side of each vertex. Points are allowed
    // to be on the line.
    for k := 0 to num - 1 do
      sidelist[k] := gld_PointOnSide(@points[k], curclip);

    k := 0;
    while k < num do
    begin
      startIdx := k;
      endIdx := k + 1;
      // Check the end index.
      if endIdx = num then
        endIdx := 0; // Wrap-around.
      // Clipping will happen when the ends are on different sides.
      if sidelist[startIdx] <> sidelist[endIdx] then
      begin
        gld_CalcIntersectionVertex(@points[startIdx], @points[endIdx], curclip, @newvert);

        // Add the new vertex. Also modify the sidelist.
        inc(num);
        realloc(pointer(points), (num - 1) * SizeOf(vertex_t), num * SizeOf(vertex_t));
        if num >= MAX_CC_SIDES then
          I_Error('gld_FlatEdgeClipper(): Too many points in carver');

        // Make room for the new vertex.
        memmove(@points[endIdx + 1], @points[endIdx], (num - endIdx - 1) * SizeOf(vertex_t)); // VJ SOS
        memcpy(@points[endIdx], @newvert, SizeOf(newvert));

        memmove(@sidelist[endIdx + 1], @sidelist[endIdx], num - endIdx - 1);
        sidelist[endIdx] := true;

        // Skip over the new vertex.
        inc(k);
      end;
      inc(k);
    end;

    // Now we must discard the points that are on the wrong side.
    k := 0;
    while k < num do
    begin
      if not sidelist[k] then
      begin
        memmove(@points[k], @points[k + 1], (num - k - 1) * SizeOf(vertex_t));
        memmove(@sidelist[k], @sidelist[k + 1], num - k - 1);
        dec(num);
      end
      else
        inc(k);
    end;
  end;

  // Screen out consecutive identical points.
  i := 0;
  while i < num do
  begin
    previdx := i - 1;
    if previdx < 0 then
      previdx := num - 1;
    if (points[i].x = points[previdx].x) and (points[i].y = points[previdx].y) then
    begin
      // This point (i) must be removed.
      memmove(@points[i], @points[i + 1], (num - i - 1) * SizeOf(vertex_t));
      dec(num)
    end
    else
      inc(i);
  end;

  numpoints^ := num;
  result := points;
end;

procedure gld_FlatConvexCarver(ssidx: integer; num: integer; list: Pdivline_tArray);
var
  ssec: POldSubsector;
  numclippers: integer;
  clippers: Pdivline_tArray;
  i, numedgepoints: integer;
  edgepoints: Pvertex_tArray;
  seg: POldSeg;
  plist: Pdivline_t;
  snum: integer;
begin
  ssec := @old_subsectors[ssidx];
  snum := ssec.numlines;
  numclippers := num + snum;

  clippers := malloc(numclippers * SizeOf(divline_t));
  for i := 0 to num - 1 do
  begin
    plist := @list[num - i - 1];
    clippers[i].x := plist.x;
    clippers[i].y := plist.y;
    clippers[i].dx := plist.dx;
    clippers[i].dy := plist.dy;
  end;
  for i := num to numclippers - 1 do
  begin
    snum := ssec.firstline;
    seg := @old_segs[snum + i - num];
    clippers[i].x := seg.v1.x;
    clippers[i].y := seg.v1.y;
    clippers[i].dx := seg.v2.x - seg.v1.x;
    clippers[i].dy := seg.v2.y - seg.v1.y;
  end;

  // Setup the 'worldwide' polygon.
  numedgepoints := 4;
  edgepoints := malloc(numedgepoints * Sizeof(vertex_t));

  edgepoints[0].x := MININT;
  edgepoints[0].y := MAXINT;

  edgepoints[1].x := MAXINT;
  edgepoints[1].y := MAXINT;

  edgepoints[2].x := MAXINT;
  edgepoints[2].y := MININT;

  edgepoints[3].x := MININT;
  edgepoints[3].y := MININT;

  // Do some clipping, <snip> <snip>
  edgepoints := gld_FlatEdgeClipper(@numedgepoints, edgepoints, numclippers, clippers);

  if numedgepoints >= 3 then
    OldRecordLoop(ssec.sectorid, edgepoints, numedgepoints);
  // We're done, free the edgepoints memory.
  memfree(pointer(edgepoints), numedgepoints * SizeOf(vertex_t));
  memfree(pointer(clippers), numclippers * SizeOf(divline_t));
end;

procedure gld_CarveFlats(bspnode: integer; numdivlines: integer; divlines: Pdivline_tArray; sectorclosed: PBooleanArray);
var
  nod: POldNode;
  dl: Pdivline_t;
  childlist: Pdivline_tArray;
  childlistsize: integer;
  ssidx: integer;
begin
  childlistsize := numdivlines + 1;

  if bspnode = -1 then
  begin
    if not sectorclosed[old_subsectors[0].sectorid] then
      gld_FlatConvexCarver(0, numdivlines, divlines);
    exit;
  end;

  // If this is a subsector we are dealing with, begin carving with the
  // given list.
  if bspnode and NF_SUBSECTOR <> 0 then
  begin
    // We have arrived at a subsector. The divline list contains all
    // the partition lines that carve out the subsector.
    ssidx := bspnode and not NF_SUBSECTOR;
    if not sectorclosed[old_subsectors[ssidx].sectorid] then
      gld_FlatConvexCarver(ssidx, numdivlines, divlines);
    exit;
  end;

  // Get a pointer to the node.
  nod := @old_nodes[bspnode];

  // Allocate a new list for each child.
  childlist := malloc(childlistsize * SizeOf(divline_t));

  // Copy the previous lines.
  if divlines <> nil then
    memcpy(childlist, divlines, numdivlines * SizeOf(divline_t));

  dl := @childlist[numdivlines];
  dl.x := nod.x;
  dl.y := nod.y;
  // The right child gets the original line (LEFT side clipped).
  dl.dx := nod.dx;
  dl.dy := nod.dy;
  gld_CarveFlats(nod.children[0], childlistsize, childlist, sectorclosed);

  // The left side. We must reverse the line, otherwise the wrong
  // side would get clipped.
  dl.dx := -nod.dx;
  dl.dy := -nod.dy;
  gld_CarveFlats(nod.children[1], childlistsize, childlist, sectorclosed);

  // We are finishing with this node, free the allocated list.
  memfree(pointer(childlist), childlistsize * SizeOf(divline_t));
end;

procedure gld_GetSubSectorVertices(sectorclosed: PBooleanArray);
var
  i, j: integer;
  numedgepoints: integer;
  ssector: POldSubsector;
  seg: POldSeg;
  pts: array of vertex_t;
begin
  for i := 0 to Length(old_subsectors) - 1 do
  begin
    ssector := @old_subsectors[i];

    if sectorclosed[ssector.sectorid] then
      continue;

    numedgepoints := ssector.numlines;
    if numedgepoints < 3 then
      continue;

    SetLength(pts, numedgepoints);
    seg := @old_segs[ssector.firstline];
    for j := 0 to numedgepoints - 1 do
    begin
      pts[j].x := seg.v1.x;
      pts[j].y := seg.v1.y;
      inc(seg);
    end;
    OldRecordLoop(ssector.sectorid, Pvertex_tArray(@pts[0]), numedgepoints);
  end;
end;

end.
