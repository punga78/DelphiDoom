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
//  Voxel stuff (OpenGL)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit gl_voxels;

interface

uses
  d_delphi,
  tables,
  gl_types,
  DelphiDoom.Voxel.Types,
  DelphiDoom.Voxel.Intf;

var
  gl_drawvoxels: boolean = true;

type
  TVoxelModel = class
  private
    precalc: PGLuintArray;
    fnumframes: integer;
  public
    constructor Create(const name: string; const offset, scale: float);
    destructor Destroy; override;
    procedure Draw(const frm: Integer; const rot: angle_t);
  end;

//==============================================================================
//
// gld_InitVoxels
//
//==============================================================================
procedure gld_InitVoxels;

//==============================================================================
//
// gld_VoxelsDone
//
//==============================================================================
procedure gld_VoxelsDone;

//==============================================================================
//
// gld_ConfigureVoxelLoading
//
//==============================================================================
procedure gld_ConfigureVoxelLoading(const ALoader: IVoxelLoader; const ACubes: IVoxelCubeBuilder);

var
  // When = 0 we use TVoxelMeshOptimizer.FastOptimize(),
  // otherwize indicate the pass count for TVoxelMeshOptimizer.Optimize()
  vx_maxoptimizerpasscount: integer = 0;  // OpenGL

const
  MAX_VX_OPTIMIZE = 3;

implementation

uses
  dglOpenGL,
  doomdef,
  gl_defs,
  i_system,
  vx_base;

var
  vx_membuffer: pointer = nil;
  gl_voxelloader: IVoxelLoader = nil;
  gl_voxelcubes: IVoxelCubeBuilder = nil;

const
  FLG_SKIPX0 = 1;
  FLG_SKIPX1 = 2;
  FLG_SKIPY0 = 4;
  FLG_SKIPY1 = 8;
  FLG_SKIPZ0 = 16;
  FLG_SKIPZ1 = 32;

const
  MAXVOXELSIZE = 256;

type
  voxelitem_t = record
    color: LongWord;
    flags: byte;
  end;
  voxelitem_p = ^voxelitem_t;
  voxelbuffer_t = array[0..MAXVOXELSIZE - 1, 0..MAXVOXELSIZE - 1, 0..MAXVOXELSIZE - 1] of voxelitem_t;
  voxelbuffer_p = ^voxelbuffer_t;

// jval
//  class TVoxelMeshOptimizer()
//  Mesh reducer for voxels
//  Optimize() method gives excellent results, but unfortunatelly is slow.
//  FastOptimize() method gives acceptable results and works significally faster
//  Note: I must make voxelquad_t a class, but never mind, it works :)
//
type
  voxelvertex_t = record
    x, y, z: float;
  end;
  voxelvertex_p = ^voxelvertex_t;

  voxelquad_t = record
    color: GLuint;
    vertexes: array[0..3] of voxelvertex_t;
    valid: Boolean;
    orientation: Char;
  end;

  voxelquad_p = ^voxelquad_t;
  voxelquad_a = array[0..$FFF] of voxelquad_t;
  voxelquad_pa = ^voxelquad_a;

  TVoxelMeshOptimizer = class
  private
    fquads: voxelquad_pa;
    fnumquads: integer;
    frealnumquads: integer;
    procedure Grow;
    procedure TryMergeQuads(const q1, q2: voxelquad_p);
    procedure SortQuadVertexes(const q: voxelquad_p);
    procedure InnerOptimize;
  protected
    procedure RenderVertexGL(const v: voxelvertex_p); virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure AddQuad(const c: GLuint; const x0, y0, z0, x1, y1, z1, x2, y2, z2, x3, y3, z3: float);
    procedure Optimize;
    procedure FastOptimize;
    procedure RenderGL;
    property quads: voxelquad_pa read fquads;
    property numquads: integer read fnumquads;
  end;

  TVoxelMeshOptimizerKVX = class(TVoxelMeshOptimizer)
  protected
    procedure RenderVertexGL(const v: voxelvertex_p); override;
  end;

  TVoxelMeshOptimizerDDVOX = class(TVoxelMeshOptimizer)
  protected
    midx, midy, midz: float;
    step: float;
    procedure RenderVertexGL(const v: voxelvertex_p); override;
  end;

//==============================================================================
//
// TVoxelMeshOptimizer.Create
//
//==============================================================================
constructor TVoxelMeshOptimizer.Create;
begin
  fquads := nil;
  fnumquads := 0;
  frealnumquads := 0;
end;

//==============================================================================
//
// TVoxelMeshOptimizer.Destroy
//
//==============================================================================
destructor TVoxelMeshOptimizer.Destroy;
begin
  memfree(Pointer(fquads), frealnumquads * SizeOf(voxelquad_t));
end;

//==============================================================================
//
// TVoxelMeshOptimizer.AddQuad
//
//==============================================================================
procedure TVoxelMeshOptimizer.AddQuad(const c: GLuint; const x0, y0, z0, x1, y1, z1, x2, y2, z2, x3, y3, z3: float);
var
  q: voxelquad_p;
begin
  Grow;
  q := @fquads[fnumquads - 1];
  q.color := c;
  q.vertexes[0].x := x0;
  q.vertexes[0].y := y0;
  q.vertexes[0].z := z0;
  q.vertexes[1].x := x1;
  q.vertexes[1].y := y1;
  q.vertexes[1].z := z1;
  q.vertexes[2].x := x2;
  q.vertexes[2].y := y2;
  q.vertexes[2].z := z2;
  q.vertexes[3].x := x3;
  q.vertexes[3].y := y3;
  q.vertexes[3].z := z3;
  q.valid := true;
  if (x0 = x1) and (x0 = x2) and (x0 = x3) then
    q.orientation := 'x'
  else if (y0 = y1) and (y0 = y2) and (y0 = y3) then
    q.orientation := 'y'
  else if (z0 = z1) and (z0 = z2) and (z0 = z3) then
    q.orientation := 'z'
  else
  begin
    q.orientation := ' ';
    q.valid := false;
  end;
end;

const
  VXOGROWSTEP = 256;

//==============================================================================
//
// TVoxelMeshOptimizer.Grow
//
//==============================================================================
procedure TVoxelMeshOptimizer.Grow;
begin
  Inc(fnumquads);
  if fnumquads > frealnumquads then
  begin
    realloc(Pointer(fquads), frealnumquads * SizeOf(voxelquad_t), (frealnumquads + VXOGROWSTEP) * SizeOf(voxelquad_t));
    frealnumquads := frealnumquads + VXOGROWSTEP;
  end;
end;

//==============================================================================
//
// TVoxelMeshOptimizer.SortQuadVertexes
//
//==============================================================================
procedure TVoxelMeshOptimizer.SortQuadVertexes(const q: voxelquad_p);
var
  i, si: integer;
  sorttbl: array[0..3] of integer;
  mid1, mid2: float;
  v: voxelvertex_t;
  vp: voxelvertex_p;
  done: boolean;
begin
  mid1 := 0;
  mid2 := 0;
  if q.orientation = 'x' then
  begin
    for i := 0 to 3 do
    begin
      mid1 := mid1 + q.vertexes[i].y;
      mid2 := mid2 + q.vertexes[i].z;
    end;
    mid1 := mid1 / 4;
    mid2 := mid2 / 4;
    vp := @q.vertexes[0];
    for i := 0 to 3 do
    begin
      if vp.y < mid1 then
      begin
        if vp.z < mid2 then
          sorttbl[i] := 0
        else
          sorttbl[i] := 1;
      end
      else
      begin
        if vp.z < mid2 then
          sorttbl[i] := 3
        else
          sorttbl[i] := 2;
      end;
      inc(vp);
    end;
    repeat
      done := true;
      for i := 0 to 3 do
        if sorttbl[i] <> i then
        begin
          v := q.vertexes[i];
          si := sorttbl[i];
          q.vertexes[i] := q.vertexes[si];
          q.vertexes[si] := v;
          sorttbl[si] := si;
          sorttbl[i] := i;
          done := false;
          break;
        end;
    until done;
  end
  else if q.orientation = 'y' then
  begin
    for i := 0 to 3 do
    begin
      mid1 := mid1 + q.vertexes[i].x;
      mid2 := mid2 + q.vertexes[i].z;
    end;
    mid1 := mid1 / 4;
    mid2 := mid2 / 4;
    vp := @q.vertexes[0];
    for i := 0 to 3 do
    begin
      if vp.x < mid1 then
      begin
        if vp.z < mid2 then
          sorttbl[i] := 0
        else
          sorttbl[i] := 1;
      end
      else
      begin
        if vp.z < mid2 then
          sorttbl[i] := 3
        else
          sorttbl[i] := 2;
      end;
      inc(vp);
    end;
    repeat
      done := true;
      for i := 0 to 3 do
        if sorttbl[i] <> i then
        begin
          v := q.vertexes[i];
          si := sorttbl[i];
          q.vertexes[i] := q.vertexes[si];
          q.vertexes[si] := v;
          sorttbl[si] := si;
          sorttbl[i] := i;
          done := false;
          break;
        end;
    until done;
  end
  else if q.orientation = 'z' then
  begin
    for i := 0 to 3 do
    begin
      mid1 := mid1 + q.vertexes[i].x;
      mid2 := mid2 + q.vertexes[i].y;
    end;
    mid1 := mid1 / 4;
    mid2 := mid2 / 4;
    vp := @q.vertexes[0];
    for i := 0 to 3 do
    begin
      if vp.x < mid1 then
      begin
        if vp.y < mid2 then
          sorttbl[i] := 0
        else
          sorttbl[i] := 1;
      end
      else
      begin
        if vp.y < mid2 then
          sorttbl[i] := 3
        else
          sorttbl[i] := 2;
      end;
      inc(vp);
    end;
    repeat
      done := true;
      for i := 0 to 3 do
        if sorttbl[i] <> i then
        begin
          v := q.vertexes[i];
          si := sorttbl[i];
          q.vertexes[i] := q.vertexes[si];
          q.vertexes[si] := v;
          sorttbl[si] := si;
          sorttbl[i] := i;
          done := false;
          break;
        end;
    until done;
  end;

end;

//==============================================================================
//
// TVoxelMeshOptimizer.Optimize
//
//==============================================================================
procedure TVoxelMeshOptimizer.Optimize;
var
  cnt: integer;
  oldnumquads: integer;
  passc: integer;
begin
  vx_maxoptimizerpasscount := GetIntegerInRange(vx_maxoptimizerpasscount, 0, MAX_VX_OPTIMIZE);

  if vx_maxoptimizerpasscount = 0 then
  begin
    FastOptimize;
    exit;
  end;

  oldnumquads := fnumquads;
  passc := 0;
  repeat
    cnt := fnumquads;
    InnerOptimize;
    inc(passc);
    if passc = vx_maxoptimizerpasscount then
      break;
  until cnt = fnumquads;
  if oldnumquads > fnumquads then
    printf('    TVoxelMeshOptimizer.Optimize(): Mesh reduced from %d to %d quads, pass count = %d.'#13#10, [oldnumquads, fnumquads, passc])
  else
    printf('    TVoxelMeshOptimizer.Optimize(): Can not reduce mesh complexity, size is %d quads.'#13#10, [fnumquads]);
end;

const
  FASTOPTIMIZEAHEAD = 128;

//==============================================================================
// TVoxelMeshOptimizer.FastOptimize
//
// As simple as it looks, we check only the next FASTOPTIMIZEAHEAD quads of the array
// FastOptimize() reduces a typical voxel mesh fast.
// Optimize() reduces the mesh about 50% - 60% more than FastOptimize() but it's much slower,
// we can' afford it at load time
//
//==============================================================================
procedure TVoxelMeshOptimizer.FastOptimize;
var
  i, j: integer;
  q1, q2: voxelquad_p;
  ori: Char;
  c: GLuint;
  fnewquads: voxelquad_pa;
  fnewnumquads: integer;
  fnewrealnumquads: integer;
  oldnumquads: integer;
begin
  oldnumquads := fnumquads;
  for i := 0 to fnumquads - FASTOPTIMIZEAHEAD - 1 do
  begin
    q1 := @fquads[i];
    if q1.valid then
    begin
      ori := q1.orientation;
      c := q1.color;
      for j := i + 1 to i + FASTOPTIMIZEAHEAD do
      begin
        q2 := @fquads[j];
        if q2.valid then
          if (q2.orientation = ori) and (q2.color = c) then
            TryMergeQuads(q1, q2);
      end;
    end;
  end;

  fnewnumquads := 0;
  for i := 0 to fnumquads - 1 do
    if fquads[i].valid then
      Inc(fnewnumquads);

  fnewrealnumquads := (fnewnumquads + VXOGROWSTEP) and (not (VXOGROWSTEP - 1));

  if fnewrealnumquads = frealnumquads then
  begin
    j := 0;
    for i := 0 to fnumquads - 1 do
    begin
      q1 := @fquads[i];
      if q1.valid then
        if i <> j then
        begin
          fquads[j] := q1^;
          SortQuadVertexes(@fquads[j]);
          Inc(j);
        end;
    end;
  end
  else
  begin
    fnewquads := malloc(fnewrealnumquads * SizeOf(voxelquad_t));

    q2 := @fnewquads[0];

    for i := 0 to fnumquads - 1 do
    begin
      q1 := @fquads[i];
      if q1.valid then
      begin
        q2^ := q1^;
        SortQuadVertexes(q2);
        Inc(q2);
      end;
    end;

    memfree(Pointer(fquads), frealnumquads * SizeOf(voxelquad_t));
    fquads := fnewquads;
    fnumquads := fnewnumquads;
    frealnumquads := fnewrealnumquads;
  end;
  if oldnumquads > fnumquads then
    printf('    TVoxelMeshOptimizer.FastOptimize(): Mesh reduced from %d to %d quads.'#13#10, [oldnumquads, fnumquads])
  else
    printf('    TVoxelMeshOptimizer.FastOptimize(): Can not reduce mesh complexity, size is %d quads.'#13#10, [fnumquads]);
end;

//==============================================================================
//
// TVoxelMeshOptimizer.InnerOptimize
//
//==============================================================================
procedure TVoxelMeshOptimizer.InnerOptimize;
var
  i, j: integer;
  q1, q2: voxelquad_p;
  ori: Char;
  c: GLuint;
  fnewquads: voxelquad_pa;
  fnewnumquads: integer;
  fnewrealnumquads: integer;
begin
  for i := 0 to fnumquads - 2 do
  begin
    q1 := @fquads[i];
    if q1.valid then
    begin
      ori := q1.orientation;
      c := q1.color;
      for j := i + 1 to fnumquads - 1 do
      begin
        q2 := @fquads[j];
        if q2.valid then
          if (q2.orientation = ori) and (q2.color = c) then
            TryMergeQuads(q1, q2);
      end;
    end;
  end;

  fnewnumquads := 0;
  for i := 0 to fnumquads - 1 do
    if fquads[i].valid then
      Inc(fnewnumquads);

  fnewrealnumquads := (fnewnumquads + VXOGROWSTEP) and (not (VXOGROWSTEP - 1));

  if fnewrealnumquads = frealnumquads then
  begin
    j := 0;
    for i := 0 to fnumquads - 1 do
    begin
      q1 := @fquads[i];
      if q1.valid then
        if i <> j then
        begin
          fquads[j] := q1^;
          SortQuadVertexes(@fquads[j]);
          Inc(j);
        end;
    end;
  end
  else
  begin
    fnewquads := malloc(fnewrealnumquads * SizeOf(voxelquad_t));

    q2 := @fnewquads[0];

    for i := 0 to fnumquads - 1 do
    begin
      q1 := @fquads[i];
      if q1.valid then
      begin
        q2^ := q1^;
        SortQuadVertexes(q2);
        Inc(q2);
      end;
    end;

    memfree(Pointer(fquads), frealnumquads * SizeOf(voxelquad_t));
    fquads := fnewquads;
    fnumquads := fnewnumquads;
    frealnumquads := fnewrealnumquads;
  end;
end;

//==============================================================================
// TVoxelMeshOptimizer.TryMergeQuads
//
// jval
// Check if q1 & q2 quads can be merged to reduce mesh complexity
// Merged quad returned to q1, q2 is flaged as invalid (we will remove it later from list)
//
//==============================================================================
procedure TVoxelMeshOptimizer.TryMergeQuads(const q1, q2: voxelquad_p);
var
  match1, match2: array[0..3] of integer; // Matching points
  cnt: integer;
  i, j: integer;
  i2a, i2b: integer;
  x, y, z: float;
  vp: voxelvertex_p;
begin
  for i := 0 to 3 do
  begin
    match1[i] := -1;
    match2[i] := -1;
  end;
  if q1.orientation = 'x' then
  begin
    if q1.vertexes[0].x <> q2.vertexes[0].x then
      exit;
    for i := 0 to 3 do
    begin
      y := q1.vertexes[i].y;
      z := q1.vertexes[i].z;
      vp := @q2.vertexes[0];
      for j := 0 to 3 do
      begin
        if (y = vp.y) and (z = vp.z) then
        begin
          match1[i] := j;
          match2[j] := i;
        end;
        inc(vp);
      end;
    end;

    cnt := 0;
    for i := 0 to 3 do
      if match1[i] = -1 then
        Inc(cnt);
    if cnt = 2 then
    begin
      i2a := -1;
      for i := 0 to 3 do
        if match2[i] = -1 then
        begin
          i2a := i;
          Break;
        end;
      i2b := -1;
      for i := 3 downto 0 do
        if match2[i] = -1 then
        begin
          i2b := i;
          Break;
        end;

      if (i2a <> -1) and (i2a <> i2b) then
      begin
        for i := 0 to 3 do
          if match1[i] <> -1 then
          begin
            q1.vertexes[i].y := q2.vertexes[i2a].y;
            q1.vertexes[i].z := q2.vertexes[i2a].z;
            break;
          end;
        for i := 3 downto 0 do
          if match1[i] <> -1 then
          begin
            q1.vertexes[i].y := q2.vertexes[i2b].y;
            q1.vertexes[i].z := q2.vertexes[i2b].z;
            break;
          end;
        q2.valid := false;
      end;
    end;
  end
  else if q1.orientation = 'y' then
  begin
    if q1.vertexes[0].y <> q2.vertexes[0].y then
      exit;
    for i := 0 to 3 do
    begin
      x := q1.vertexes[i].x;
      z := q1.vertexes[i].z;
      vp := @q2.vertexes[0];
      for j := 0 to 3 do
      begin
        if (x = vp.x) and (z = vp.z) then
        begin
          match1[i] := j;
          match2[j] := i;
        end;
        inc(vp);
      end;
    end;

    cnt := 0;
    for i := 0 to 3 do
      if match1[i] = -1 then
        Inc(cnt);
    if cnt = 2 then
    begin
      i2a := -1;
      for i := 0 to 3 do
        if match2[i] = -1 then
        begin
          i2a := i;
          Break;
        end;
      i2b := -1;
      for i := 3 downto 0 do
        if match2[i] = -1 then
        begin
          i2b := i;
          Break;
        end;

      if (i2a <> -1) and (i2a <> i2b) then
      begin
        for i := 0 to 3 do
          if match1[i] <> -1 then
          begin
            q1.vertexes[i].x := q2.vertexes[i2a].x;
            q1.vertexes[i].z := q2.vertexes[i2a].z;
            break;
          end;
        for i := 3 downto 0 do
          if match1[i] <> -1 then
          begin
            q1.vertexes[i].x := q2.vertexes[i2b].x;
            q1.vertexes[i].z := q2.vertexes[i2b].z;
            break;
          end;
        q2.valid := false;
      end;
    end;
  end
  else if q1.orientation = 'z' then
  begin
    if q1.vertexes[0].z <> q2.vertexes[0].z then
      exit;
    for i := 0 to 3 do
    begin
      x := q1.vertexes[i].x;
      y := q1.vertexes[i].y;
      vp := @q2.vertexes[0];
      for j := 0 to 3 do
      begin
        if (x = vp.x) and (y = vp.y) then
        begin
          match1[i] := j;
          match2[j] := i;
        end;
        inc(vp);
      end;
    end;

    cnt := 0;
    for i := 0 to 3 do
      if match1[i] = -1 then
        Inc(cnt);
    if cnt = 2 then
    begin
      i2a := -1;
      for i := 0 to 3 do
        if match2[i] = -1 then
        begin
          i2a := i;
          Break;
        end;
      i2b := -1;
      for i := 3 downto 0 do
        if match2[i] = -1 then
        begin
          i2b := i;
          Break;
        end;

      if (i2a <> -1) and (i2a <> i2b) then
      begin
        for i := 0 to 3 do
          if match1[i] <> -1 then
          begin
            q1.vertexes[i].x := q2.vertexes[i2a].x;
            q1.vertexes[i].y := q2.vertexes[i2a].y;
            break;
          end;
        for i := 3 downto 0 do
          if match1[i] <> -1 then
          begin
            q1.vertexes[i].x := q2.vertexes[i2b].x;
            q1.vertexes[i].y := q2.vertexes[i2b].y;
            break;
          end;
        q2.valid := false;
      end;
    end;
  end;

end;

//==============================================================================
//
// TVoxelMeshOptimizer.RenderVertexGL
//
//==============================================================================
procedure TVoxelMeshOptimizer.RenderVertexGL(const v: voxelvertex_p);
begin
  glVertex3fv(@v);
end;

//==============================================================================
//
// TVoxelMeshOptimizerKVX.RenderVertexGL
//
//==============================================================================
procedure TVoxelMeshOptimizerKVX.RenderVertexGL(const v: voxelvertex_p);
begin
  glVertex3f(v.x, v.z, -v.y);
end;

//==============================================================================
//
// TVoxelMeshOptimizerDDVOX.RenderVertexGL
//
//==============================================================================
procedure TVoxelMeshOptimizerDDVOX.RenderVertexGL(const v: voxelvertex_p);
begin
  glVertex3f(midx - v.x * step, v.y * step - midy, v.z * step - midz);
end;

//==============================================================================
//
// TVoxelMeshOptimizer.RenderGL
//
//==============================================================================
procedure TVoxelMeshOptimizer.RenderGL;
var
  i: integer;
  q: voxelquad_p;
  c: GLuint;
  r, g, b: LongWord;
  idx: LongWord;
  x, y: LongWord;
begin
  glBegin(GL_QUADS);

  for i := 0 to fnumquads - 1 do
  begin
    q := @fquads[i];
    if q.valid then
    begin
      c := q.color;
      // Get the index to the (procedurally generated) voxeltexture
      r := (c shr 16) and $FF;
      g := (c shr  8) and $FF;
      b := (c       ) and $FF;
      idx := (r div 4) + (g div 4) * 64 + (b div 4) * 64 * 64;
      x := idx and 511;
      y := idx shr 9;

      glTexCoord2f(x / 512 + 1 / 1024, y / 512 + 1 / 1024);

      RenderVertexGL(@q.vertexes[0]);

      RenderVertexGL(@q.vertexes[1]);

      RenderVertexGL(@q.vertexes[2]);

      RenderVertexGL(@q.vertexes[3]);
    end;
  end;

  glEnd;
end;

//==============================================================================
//
// gld_BuildVoxelbufferFlags
//
//==============================================================================
procedure gld_BuildVoxelbufferFlags(const voxelbuffer: voxelbuffer_p; const voxelsize: integer);
var
  xx, yy, zz: integer;
  vp: voxelitem_p;
begin
  for xx := 1 to voxelsize - 2 do
    for yy := 1 to voxelsize - 2 do
      for zz := 1 to voxelsize - 2 do
      begin
        vp := @voxelbuffer[xx, yy, zz];
        if voxelbuffer[xx - 1, yy, zz].color <> 0 then
          vp.flags := vp.flags or FLG_SKIPX0;
        if voxelbuffer[xx + 1, yy, zz].color <> 0 then
          vp.flags := vp.flags or FLG_SKIPX1;
        if voxelbuffer[xx, yy - 1, zz].color <> 0 then
          vp.flags := vp.flags or FLG_SKIPY0;
        if voxelbuffer[xx, yy + 1, zz].color <> 0 then
          vp.flags := vp.flags or FLG_SKIPY1;
        if voxelbuffer[xx, yy, zz - 1].color <> 0 then
          vp.flags := vp.flags or FLG_SKIPZ0;
        if voxelbuffer[xx, yy, zz + 1].color <> 0 then
          vp.flags := vp.flags or FLG_SKIPZ1;
      end;
end;

//==============================================================================
//
// gld_ClearVoxelBuffer
//
//==============================================================================
procedure gld_ClearVoxelBuffer(const voxelbuffer: voxelbuffer_p; const voxelsize: integer);
var
  xx, yy, zz: integer;
begin
  for xx := 0 to voxelsize - 1 do
    for yy := 0 to voxelsize - 1 do
      for zz := 0 to voxelsize - 1 do
      begin
        voxelbuffer[xx, yy, zz].color := 0;
        voxelbuffer[xx, yy, zz].flags := 0;
      end;
end;

//==============================================================================
//
// gld_ListFromCube
// The list of a DDVOX or VOX model (the loader of Libs\Voxel puts it in a cube)
//
//==============================================================================
function gld_ListFromCube(const cube: IVoxelCube; const offset, scale: float): GLuint;
var
  cells: TArray<LongWord>;
  voxelbuffer: voxelbuffer_p;
  voxelsize: integer;
  xx, yy, zz: integer;
  idx: integer;
  vp: voxelitem_p;
  xxx, yyy, zzz: float;
  xxx1, yyy1, zzz1: float;
  c: GLuint;
  skip_x0, skip_x1: boolean;
  skip_y0, skip_y1: boolean;
  skip_z0, skip_z1: boolean;
  vmx: TVoxelMeshOptimizerDDVOX;
begin
  voxelsize := cube.Size;
  cells := cube.Cells;

  voxelbuffer := vx_membuffer;
  gld_ClearVoxelBuffer(voxelbuffer, voxelsize);
  idx := 0;
  for xx := 0 to voxelsize - 1 do
    for yy := 0 to voxelsize - 1 do
      for zz := 0 to voxelsize - 1 do
      begin
        voxelbuffer[xx, yy, zz].color := cells[idx];
        Inc(idx);
      end;

  gld_BuildVoxelbufferFlags(voxelbuffer, voxelsize);

  vmx := TVoxelMeshOptimizerDDVOX.Create;

  vmx.step := - 1 / MAP_COEFF * scale;
  vmx.midx := vmx.step * voxelsize / 2;
  vmx.midy := vmx.step * voxelsize + offset / MAP_COEFF; // Align down
  vmx.midz := vmx.step * voxelsize / 2;

  for xx := 0 to voxelsize - 1 do
  begin
    xxx := xx;
    xxx1 := xx + 1;
    for yy := 0 to voxelsize - 1 do
    begin
      yyy := yy;
      yyy1 := yy + 1;
      for zz := 0 to voxelsize - 1 do
      begin
        vp := @voxelbuffer[xx, yy, zz];
        c := vp.color;

        if c <> 0 then
        begin
          zzz := zz;
          zzz1 := zz + 1;

          skip_x0 := vp.flags and FLG_SKIPX0 <> 0;
          skip_x1 := vp.flags and FLG_SKIPX1 <> 0;
          skip_y0 := vp.flags and FLG_SKIPY0 <> 0;
          skip_y1 := vp.flags and FLG_SKIPY1 <> 0;
          skip_z0 := vp.flags and FLG_SKIPZ0 <> 0;
          skip_z1 := vp.flags and FLG_SKIPZ1 <> 0;

          if not skip_z0 then
          begin
            vmx.AddQuad(c,
                        xxx, yyy, zzz,
                        xxx, yyy1, zzz,
                        xxx1, yyy1, zzz,
                        xxx1, yyy, zzz);
          end;

          if not skip_y0 then
          begin
            vmx.AddQuad(c,
                        xxx, yyy, zzz,
                        xxx, yyy, zzz1,
                        xxx1, yyy, zzz1,
                        xxx1, yyy, zzz);
          end;

          if not skip_x0 then
          begin
            vmx.AddQuad(c,
                        xxx, yyy, zzz,
                        xxx, yyy, zzz1,
                        xxx, yyy1, zzz1,
                        xxx, yyy1, zzz);
          end;

          if not skip_z1 then
          begin
            vmx.AddQuad(c,
                        xxx, yyy, zzz1,
                        xxx, yyy1, zzz1,
                        xxx1, yyy1, zzz1,
                        xxx1, yyy, zzz1);
          end;

          if not skip_y1 then
          begin
            vmx.AddQuad(c,
                        xxx, yyy1, zzz,
                        xxx, yyy1, zzz1,
                        xxx1, yyy1, zzz1,
                        xxx1, yyy1, zzz);
          end;

          if not skip_x1 then
          begin
            vmx.AddQuad(c,
                        xxx1, yyy, zzz,
                        xxx1, yyy1, zzz,
                        xxx1, yyy1, zzz1,
                        xxx1, yyy , zzz1);
          end;
        end;
      end;
    end;
  end;

  // If vx_maxoptimizerpasscount = 0 then vmx.Optimize() will call vmx.FastOptimize()
  vmx.Optimize;

  result := glGenLists(1);

  glNewList(result, GL_COMPILE);

    vmx.RenderGL;

  glEndList;

  vmx.Free;
end;

//==============================================================================
//
// gld_ListFromQuads
// The list of a DDMESH model: the faces that the file already has
//
//==============================================================================
function gld_ListFromQuads(const model: IVoxelModel; const offset, scale: float): GLuint;
var
  voxelsize: integer;
  step: float;
  midx, midy, midz: float;
  quad: TVoxelQuad;
  c: LongWord;
  i, j: integer;
  r, g, b: LongWord;
  idx: LongWord;
  x, y: LongWord;

  procedure _vertex(const v: TVoxelQuadVertex);
  begin
    glVertex3f(midx - v.X * step, v.Y * step - midy, v.Z * step - midz);
  end;

begin
  voxelsize := model.SizeX;
  step := - 1 / MAP_COEFF * scale;
  midx := step * voxelsize / 2;
  midy := step * voxelsize + offset / MAP_COEFF; // Align down
  midz := step * voxelsize / 2;

  result := glGenLists(1);

  glNewList(result, GL_COMPILE);

    glBegin(GL_QUADS);

      for i := 0 to model.QuadCount - 1 do
      begin
        quad := model.Quad(i);
        c := quad.Color;
        // Get the index to the (procedurally generated) voxeltexture
        r := (c shr 16) and $FF;
        g := (c shr  8) and $FF;
        b := (c       ) and $FF;
        idx := (r div 4) + (g div 4) * 64 + (b div 4) * 64 * 64;
        x := idx and 511;
        y := idx shr 9;

        glTexCoord2f(x / 512 + 1 / 1024, y / 512 + 1 / 1024);
        for j := 0 to 3 do
          _vertex(quad.Vertexes[j]);
      end;

    glEnd;

  glEndList;
end;

//==============================================================================
//
// gld_ListFromKvx
// The list of a KVX model: the voxels as the file has them, with the pivot of the file
//
//==============================================================================
function gld_ListFromKvx(const model: IVoxelModel; const offset, scale: float): GLuint;
var
  cells: TArray<LongWord>;
  xsiz, ysiz, zsiz: integer;
  xx, yy, zz: integer;
  i: integer;
  step: float;
  midx, midy, midz: float;
  xxx, yyy, zzz,
  xxx1, yyy1, zzz1: float;
  c: GLuint;
  skip_x0, skip_x1: boolean;
  skip_y0, skip_y1: boolean;
  skip_z0, skip_z1: boolean;
  old_skip_x0, old_skip_x1: boolean;
  old_skip_y0, old_skip_y1: boolean;
  old_skip_z0, old_skip_z1: boolean;
  skip: integer;
  vmx: TVoxelMeshOptimizerKVX;

  function _solid(const ax, ay, az: integer): boolean;
  begin
    result := cells[(ax * ysiz + ay) * zsiz + az] <> 0;
  end;

  function _color(const ax, ay, az: integer): LongWord;
  begin
    result := cells[(ax * ysiz + ay) * zsiz + az];
  end;

begin
  cells := model.Cells;
  xsiz := model.SizeX;
  ysiz := model.SizeY;
  zsiz := model.SizeZ;

  step := - 1 / MAP_COEFF * scale;
  midx := step * model.PivotX / 256;
  midy := step * model.PivotY / 256;
  midz := step * model.PivotZ / 256;

  skip := 0;

  vmx := TVoxelMeshOptimizerKVX.Create;

  for xx := 0 to xsiz - 1 do
  begin
    xxx := midx - xx * step;
    xxx1 := midx - (1 + xx) * step;
    for yy := 0 to ysiz - 1 do
    begin
      old_skip_x0 := true;
      old_skip_x1 := true;
      old_skip_y0 := true;
      old_skip_y1 := true;
      old_skip_z0 := true;
      old_skip_z1 := true;
      yyy := yy * step - midy;
      yyy1 := (1 + yy) * step - midy;
      for zz := 0 to zsiz - 1 do
      begin
        if skip > 0 then
        begin
          dec(skip);
          Continue;
        end;
        skip := 0;

        if _solid(xx, yy, zz) then
        begin
          for i := zz to zsiz - 1 do
          begin
            skip_x0 := (xx > 0) and _solid(xx - 1, yy, i);
            skip_x1 := (xx < xsiz - 1) and _solid(xx + 1, yy, i);
            skip_y0 := (yy > 0) and _solid(xx, yy - 1, i);
            skip_y1 := (yy < ysiz - 1) and _solid(xx, yy + 1, i);
            skip_z0 := (i > 0) and _solid(xx, yy, i - 1);
            skip_z1 := (i < zsiz - 1) and _solid(xx, yy, i + 1);

            if (old_skip_x0 = skip_x0) and
               (old_skip_x1 = skip_x1) and
               (old_skip_y0 = skip_y0) and
               (old_skip_y1 = skip_y1) and
               (old_skip_z0 = skip_z0) and
               (old_skip_z1 = skip_z1) and
               (_color(xx, yy, i) = _color(xx, yy, zz)) then
              Inc(skip)
            else
              break;
          end;

          skip_x0 := (xx > 0) and _solid(xx - 1, yy, zz);
          skip_x1 := (xx < xsiz - 1) and _solid(xx + 1, yy, zz);
          skip_y0 := (yy > 0) and _solid(xx, yy - 1, zz);
          skip_y1 := (yy < ysiz - 1) and _solid(xx, yy + 1, zz);
          skip_z0 := (zz > 0) and _solid(xx, yy, zz - 1);
          skip_z1 := (zz < zsiz - 1) and _solid(xx, yy, zz + 1);

          zzz := zz * step - midz;
          if skip > 0 then
            dec(skip);
          zzz1 := (1 + skip + zz) * step - midz;

          old_skip_x0 := skip_x0;
          old_skip_x1 := skip_x1;
          old_skip_y0 := skip_y0;
          old_skip_y1 := skip_y1;
          old_skip_z0 := skip_z0;
          old_skip_z1 := skip_z1;

          c := _color(xx, yy, zz);

          if not skip_z0 then
          begin
            vmx.AddQuad(c,
                        xxx, yyy, zzz,
                        xxx, yyy1, zzz,
                        xxx1, yyy1, zzz,
                        xxx1, yyy, zzz);
          end;

          if not skip_y0 then
          begin
            vmx.AddQuad(c,
                        xxx, yyy, zzz,
                        xxx, yyy, zzz1,
                        xxx1, yyy, zzz1,
                        xxx1, yyy, zzz);
          end;

          if not skip_x0 then
          begin
            vmx.AddQuad(c,
                        xxx, yyy, zzz,
                        xxx, yyy, zzz1,
                        xxx, yyy1, zzz1,
                        xxx, yyy1, zzz);
          end;

          if not skip_z1 then
          begin
            vmx.AddQuad(c,
                        xxx, yyy, zzz1,
                        xxx, yyy1, zzz1,
                        xxx1, yyy1, zzz1,
                        xxx1, yyy, zzz1);
          end;

          if not skip_y1 then
          begin
            vmx.AddQuad(c,
                        xxx, yyy1, zzz,
                        xxx, yyy1, zzz1,
                        xxx1, yyy1, zzz1,
                        xxx1, yyy1, zzz);
          end;

          if not skip_x1 then
          begin
            vmx.AddQuad(c,
                        xxx1, yyy, zzz,
                        xxx1, yyy1, zzz,
                        xxx1, yyy1, zzz1,
                        xxx1, yyy , zzz1);
          end;
        end;

      end;
    end;
  end;

  // If vx_maxoptimizerpasscount = 0 then vmx.Optimize() will call vmx.FastOptimize()
  vmx.Optimize;

  result := glGenLists(1);

  glNewList(result, GL_COMPILE);

    vmx.RenderGL;

  glEndList;

  vmx.Free;
end;

//==============================================================================
//
// gld_LoadVoxelList
// The file is read by the loader of Libs\Voxel; each format makes its list
//
//==============================================================================
function gld_LoadVoxelList(const name: string; const offset, scale: float): GLuint;
var
  model: IVoxelModel;
begin
  result := GL_BAD_LIST;
  if (gl_voxelloader = nil) or (gl_voxelcubes = nil) then
    I_Error('gld_LoadVoxelList(): The voxel loader is not configured');

  model := gl_voxelloader.Load(name);
  if model = nil then
    Exit;

  case model.Format of
    vfDdmesh: result := gld_ListFromQuads(model, offset, scale);
    vfKvx: result := gld_ListFromKvx(model, offset, scale);
  else
    result := gld_ListFromCube(gl_voxelcubes.Build(model, cfRenderer), offset, scale);
  end;
end;

//==============================================================================
//
// gld_ConfigureVoxelLoading
//
//==============================================================================
procedure gld_ConfigureVoxelLoading(const ALoader: IVoxelLoader; const ACubes: IVoxelCubeBuilder);
begin
  gl_voxelloader := ALoader;
  gl_voxelcubes := ACubes;
end;

//==============================================================================
//
// TVoxelModel.Create
//
//==============================================================================
constructor TVoxelModel.Create(const name: string; const offset, scale: float);
var
  ext: string;
begin
  printf('  Found external voxel %s'#13#10, [name]);

  ext := strupper(fext(name));

  if (gl_voxelloader <> nil) and gl_voxelloader.IsSupported(name) then
  begin
    fnumframes := 1;
    precalc := mallocz(fNumFrames * SizeOf(GLuint));
    precalc[0] := gld_LoadVoxelList(name, offset, scale);
  end
  else
    I_Error('TVoxelModel.Create(): Can not identify voxel type "%s"', [name]);
end;

//==============================================================================
//
// TVoxelModel.Destroy
//
//==============================================================================
destructor TVoxelModel.Destroy;
var
  i: integer;
begin
  for i := 0 to fNumFrames - 1 do
    if precalc[i] <> GL_BAD_LIST then
      glDeleteLists(precalc[i], 1);
end;

var
  voxeltexture: TGLuint;

//==============================================================================
//
// TVoxelModel.Draw
//
//==============================================================================
procedure TVoxelModel.Draw(const frm: Integer; const rot: angle_t);
begin
  glBindTexture(GL_TEXTURE_2D, voxeltexture);
  if rot = 0 then
    glCallList(precalc[frm])
  else
  begin
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix;
    glRotatef(rot / (ANGLE_MAX / 360.0), 0.0, 1.0, 0.0);
    glCallList(precalc[frm]);
    glPopMatrix;
  end;
end;

//==============================================================================
// gld_InitVoxelTexture
//
// JVAL
//  Create the palette texture, 512x512
//
//==============================================================================
procedure gld_InitVoxelTexture;
var
  buffer: PLongWordArray;
  r, g, b: integer;
  dest: PLongWord;
begin
  buffer := malloc(512 * 512 * SizeOf(LongWord));
  dest := @buffer[0];
  for r := 0 to 63 do
    for g := 0 to 63 do
      for b := 0 to 63 do
      begin
        dest^ := 255 shl 24 + (r * 4 + 2) shl 16 + (g * 4 + 2) shl 8 + (b * 4 + 2);
        inc(dest);
      end;

  glGenTextures(1, @voxeltexture);
  glBindTexture(GL_TEXTURE_2D, voxeltexture);

  glTexImage2D(GL_TEXTURE_2D, 0, gl_tex_format,
               512, 512,
               0, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

  memfree(pointer(buffer), 512 * 512 * SizeOf(LongWord));
end;

//==============================================================================
//
// gld_InitVoxels
//
//==============================================================================
procedure gld_InitVoxels;
var
  size: integer;
begin
  size := SizeOf(voxelbuffer_t);

  gld_InitVoxelTexture;
  vx_membuffer := malloc(size);
  VX_InitVoxels;
  memfree(vx_membuffer, size);
end;

//==============================================================================
//
// gld_VoxelsDone
//
//==============================================================================
procedure gld_VoxelsDone;
begin
  VX_VoxelsDone;
  glDeleteTextures(1, @voxeltexture);
end;

end.
