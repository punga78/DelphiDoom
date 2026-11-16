{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - the mesh reducer of the voxel quads             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of TVoxelMeshOptimizer of gl_voxels.pas, without OpenGL: the algorithm }
{  is the same (and so are its defects), the drawing is an IVoxelMeshRenderer  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.MeshOptimizer;

// The vertexes are compared and merged exactly as before: the display lists of the engine have to
// be the same, so the arithmetic is not "cleaned up". The quads are a block of memory that grows by
// 256 elements, indexed past the declared size of the array type: range checking has to be off.
{$R-}
{$Q-}

interface

uses
  DelphiDoom.Voxel.MeshTypes,
  DelphiDoom.Voxel.MeshRenderer.Intf;

type
  /// <summary>
  ///   Mesh reducer for voxels. Optimize gives excellent results but is slow, FastOptimize gives
  ///   acceptable results and works significantly faster
  /// </summary>
  TVoxelMeshOptimizer = class
  strict private
    fquads: PVoxelMeshQuadArray;
    fnumquads: integer;
    frealnumquads: integer;
    procedure Grow;
    procedure TryMergeQuads(const q1, q2: PVoxelMeshQuad);
    procedure SortQuadVertexes(const q: PVoxelMeshQuad);
    procedure InnerOptimize;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Adds a quad; one that is not parallel to an axis is kept but marked not valid</summary>
    procedure AddQuad(const c: Cardinal; const x0, y0, z0, x1, y1, z1, x2, y2, z2, x3, y3, z3: Single);
    /// <summary>The full optimizer, AMaxPasses passes at most (0 calls FastOptimize; clamped to 0..3)</summary>
    function Optimize(const AMaxPasses: Integer): TVoxelMeshOptimizeResult;
    /// <summary>Looks only at the next 128 quads of each quad</summary>
    function FastOptimize: TVoxelMeshOptimizeResult;
    /// <summary>Sends the valid quads to ARenderer, the vertexes placed by AMap</summary>
    procedure Render(const ARenderer: IVoxelMeshRenderer; const AMap: IVoxelMeshVertexMap);
    property quads: PVoxelMeshQuadArray read fquads;
    property numquads: integer read fnumquads;
  end;

implementation

uses
  System.SysUtils;

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
  FreeMem(fquads);
end;

//==============================================================================
//
// TVoxelMeshOptimizer.AddQuad
//
//==============================================================================
procedure TVoxelMeshOptimizer.AddQuad(const c: Cardinal; const x0, y0, z0, x1, y1, z1, x2, y2, z2, x3, y3, z3: Single);
var
  q: PVoxelMeshQuad;
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
    ReallocMem(fquads, (frealnumquads + VXOGROWSTEP) * SizeOf(TVoxelMeshQuad));
    frealnumquads := frealnumquads + VXOGROWSTEP;
  end;
end;

//==============================================================================
//
// TVoxelMeshOptimizer.SortQuadVertexes
//
//==============================================================================
procedure TVoxelMeshOptimizer.SortQuadVertexes(const q: PVoxelMeshQuad);
var
  i, si: integer;
  sorttbl: array[0..3] of integer;
  mid1, mid2: Single;
  v: TVoxelMeshVertex;
  vp: PVoxelMeshVertex;
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
function TVoxelMeshOptimizer.Optimize(const AMaxPasses: Integer): TVoxelMeshOptimizeResult;
var
  cnt: integer;
  oldnumquads: integer;
  passc: integer;
  LMaxPasses: Integer;
begin
  LMaxPasses := AMaxPasses;
  if LMaxPasses < 0 then
    LMaxPasses := 0
  else if LMaxPasses > VOXEL_MESH_MAX_PASSES then
    LMaxPasses := VOXEL_MESH_MAX_PASSES;

  if LMaxPasses = 0 then
  begin
    Result := FastOptimize;
    exit;
  end;

  oldnumquads := fnumquads;
  passc := 0;
  repeat
    cnt := fnumquads;
    InnerOptimize;
    inc(passc);
    if passc = LMaxPasses then
      break;
  until cnt = fnumquads;
  Result.Kind := vokFull;
  Result.OldQuadCount := oldnumquads;
  Result.NewQuadCount := fnumquads;
  Result.Passes := passc;
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
function TVoxelMeshOptimizer.FastOptimize: TVoxelMeshOptimizeResult;
var
  i, j: integer;
  q1, q2: PVoxelMeshQuad;
  ori: Char;
  c: Cardinal;
  fnewquads: PVoxelMeshQuadArray;
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
    fnewquads := AllocMem(fnewrealnumquads * SizeOf(TVoxelMeshQuad));

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

    FreeMem(fquads);
    fquads := fnewquads;
    fnumquads := fnewnumquads;
    frealnumquads := fnewrealnumquads;
  end;
  Result.Kind := vokFast;
  Result.OldQuadCount := oldnumquads;
  Result.NewQuadCount := fnumquads;
  Result.Passes := 0;
end;

//==============================================================================
//
// TVoxelMeshOptimizer.InnerOptimize
//
//==============================================================================
procedure TVoxelMeshOptimizer.InnerOptimize;
var
  i, j: integer;
  q1, q2: PVoxelMeshQuad;
  ori: Char;
  c: Cardinal;
  fnewquads: PVoxelMeshQuadArray;
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
    fnewquads := AllocMem(fnewrealnumquads * SizeOf(TVoxelMeshQuad));

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

    FreeMem(fquads);
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
procedure TVoxelMeshOptimizer.TryMergeQuads(const q1, q2: PVoxelMeshQuad);
var
  match1, match2: array[0..3] of integer; // Matching points
  cnt: integer;
  i, j: integer;
  i2a, i2b: integer;
  x, y, z: Single;
  vp: PVoxelMeshVertex;
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
// TVoxelMeshOptimizer.Render
//
//==============================================================================
procedure TVoxelMeshOptimizer.Render(const ARenderer: IVoxelMeshRenderer; const AMap: IVoxelMeshVertexMap);
var
  i, k: integer;
  q: PVoxelMeshQuad;
  c: Cardinal;
  r, g, b: LongWord;
  idx: LongWord;
  x, y: LongWord;
  vx, vy, vz: Single;
begin
  ARenderer.BeginQuads;

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

      ARenderer.TexCoord(x / 512 + 1 / 1024, y / 512 + 1 / 1024);

      for k := 0 to 3 do
      begin
        AMap.Map(q.vertexes[k], vx, vy, vz);
        ARenderer.Vertex(vx, vy, vz);
      end;
    end;
  end;

  ARenderer.EndQuads;
end;

end.
