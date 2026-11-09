{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - the OLD mesh optimizer             }
{                                                                              }
{  The text of TOldVoxelMeshOptimizer of gl_voxels.pas as it was before the       }
{  extraction (issue #177), without the drawing: the oracle of the parity      }
{  tests. Only the names of the class and the helpers of d_delphi (shims       }
{  below) differ.                                                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.OldMeshOptimizer;

{$R-}
{$Q-}

interface

uses
  System.Classes;

type
  float = Single;
  GLuint = Cardinal;

var
  vx_maxoptimizerpasscount: Integer = 0;
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

  TOldVoxelMeshOptimizer = class
  private
    fquads: voxelquad_pa;
    fnumquads: integer;
    frealnumquads: integer;
    procedure Grow;
    procedure TryMergeQuads(const q1, q2: voxelquad_p);
    procedure SortQuadVertexes(const q: voxelquad_p);
    procedure InnerOptimize;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure AddQuad(const c: GLuint; const x0, y0, z0, x1, y1, z1, x2, y2, z2, x3, y3, z3: float);
    procedure Optimize;
    procedure FastOptimize;
    /// <summary>The text of the old RenderGL: AKind 0 = base, 1 = KVX, 2 = DDVOX (the old subclasses); the calls as lines</summary>
    procedure RenderLines(const ALines: TStrings; const AKind: Integer; const AMidX, AMidY, AMidZ, AStep: float);
    property quads: voxelquad_pa read fquads;
    property numquads: integer read fnumquads;
  end;

implementation

uses
  System.SysUtils,
  System.Math;

function malloc(const size: integer): Pointer;
begin
  if size = 0 then
    Result := nil
  else
    GetMem(Result, size);
end;

procedure memfree(var p: pointer; const size: integer);
begin
  FreeMem(p);
  p := nil;
end;

procedure realloc(var p: pointer; const oldsize, newsize: integer);
begin
  if newsize = 0 then
    memfree(p, oldsize)
  else if newsize <> oldsize then
    ReallocMem(p, newsize);
end;

procedure printf(const AFormat: string; const AArgs: array of const);
begin
end;

function GetIntegerInRange(const val, f1, f2: integer): integer;
begin
  Result := EnsureRange(val, f1, f2);
end;

const
  MAX_VX_OPTIMIZE = 3;
//
// TOldVoxelMeshOptimizer.Create
//
//==============================================================================
constructor TOldVoxelMeshOptimizer.Create;
begin
  fquads := nil;
  fnumquads := 0;
  frealnumquads := 0;
end;

//==============================================================================
//
// TOldVoxelMeshOptimizer.Destroy
//
//==============================================================================
destructor TOldVoxelMeshOptimizer.Destroy;
begin
  memfree(Pointer(fquads), frealnumquads * SizeOf(voxelquad_t));
end;

//==============================================================================
//
// TOldVoxelMeshOptimizer.AddQuad
//
//==============================================================================
procedure TOldVoxelMeshOptimizer.AddQuad(const c: GLuint; const x0, y0, z0, x1, y1, z1, x2, y2, z2, x3, y3, z3: float);
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
// TOldVoxelMeshOptimizer.Grow
//
//==============================================================================
procedure TOldVoxelMeshOptimizer.Grow;
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
// TOldVoxelMeshOptimizer.SortQuadVertexes
//
//==============================================================================
procedure TOldVoxelMeshOptimizer.SortQuadVertexes(const q: voxelquad_p);
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
// TOldVoxelMeshOptimizer.Optimize
//
//==============================================================================
procedure TOldVoxelMeshOptimizer.Optimize;
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
    printf('    TOldVoxelMeshOptimizer.Optimize(): Mesh reduced from %d to %d quads, pass count = %d.'#13#10, [oldnumquads, fnumquads, passc])
  else
    printf('    TOldVoxelMeshOptimizer.Optimize(): Can not reduce mesh complexity, size is %d quads.'#13#10, [fnumquads]);
end;

const
  FASTOPTIMIZEAHEAD = 128;

//==============================================================================
// TOldVoxelMeshOptimizer.FastOptimize
//
// As simple as it looks, we check only the next FASTOPTIMIZEAHEAD quads of the array
// FastOptimize() reduces a typical voxel mesh fast.
// Optimize() reduces the mesh about 50% - 60% more than FastOptimize() but it's much slower,
// we can' afford it at load time
//
//==============================================================================
procedure TOldVoxelMeshOptimizer.FastOptimize;
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
    printf('    TOldVoxelMeshOptimizer.FastOptimize(): Mesh reduced from %d to %d quads.'#13#10, [oldnumquads, fnumquads])
  else
    printf('    TOldVoxelMeshOptimizer.FastOptimize(): Can not reduce mesh complexity, size is %d quads.'#13#10, [fnumquads]);
end;

//==============================================================================
//
// TOldVoxelMeshOptimizer.InnerOptimize
//
//==============================================================================
procedure TOldVoxelMeshOptimizer.InnerOptimize;
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
// TOldVoxelMeshOptimizer.TryMergeQuads
//
// jval
// Check if q1 & q2 quads can be merged to reduce mesh complexity
// Merged quad returned to q1, q2 is flaged as invalid (we will remove it later from list)
//
//==============================================================================
procedure TOldVoxelMeshOptimizer.TryMergeQuads(const q1, q2: voxelquad_p);
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

procedure TOldVoxelMeshOptimizer.RenderLines(const ALines: TStrings; const AKind: Integer;
  const AMidX, AMidY, AMidZ, AStep: float);

  procedure RenderVertexGL(const v: voxelvertex_p);
  var
    LX, LY, LZ: float;
  begin
    case AKind of
      1:
        begin
          LX := v.x;
          LY := v.z;
          LZ := -v.y;
        end;
    else
      begin
        LX := AMidX - v.x * AStep;
        LY := v.y * AStep - AMidY;
        LZ := v.z * AStep - AMidZ;
      end;
    end;
    ALines.Add(Format('v %.9g %.9g %.9g', [LX, LY, LZ]));
  end;

var
  i: integer;
  q: voxelquad_p;
  c: GLuint;
  r, g, b: LongWord;
  idx: LongWord;
  x, y: LongWord;
begin
  ALines.Add('begin');

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

      ALines.Add(Format('tex %.9g %.9g', [x / 512 + 1 / 1024, y / 512 + 1 / 1024]));

      RenderVertexGL(@q.vertexes[0]);

      RenderVertexGL(@q.vertexes[1]);

      RenderVertexGL(@q.vertexes[2]);

      RenderVertexGL(@q.vertexes[3]);
    end;
  end;

  ALines.Add('end');
end;

end.
