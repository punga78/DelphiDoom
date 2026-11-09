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
  // the sprites of the voxels without a patch are made from the voxel (otherwise an empty picture)
  r_generatespritesfromvoxels: boolean = true;

type
  TVoxelModel = class
  private
    precalc: PGLuintArray;
    fnumframes: integer;
  public
    /// <summary>The display list of the voxel file name, read by ALoader (ACubes for DDVOX and VOX)</summary>
    constructor Create(const name: string; const offset, scale: float;
      const ALoader: IVoxelLoader; const ACubes: IVoxelCubeBuilder);
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
  vx_base,
  DelphiDoom.Voxel.MeshTypes,
  DelphiDoom.Voxel.MeshRenderer.Intf,
  DelphiDoom.Voxel.MeshOptimizer,
  DelphiDoom.Voxel.MeshKvxMap,
  DelphiDoom.Voxel.MeshDdvoxMap,
  DelphiDoom.Engine.Voxel.MeshRenderer;

var
  vx_membuffer: pointer = nil;

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
//==============================================================================
//
// gld_BuildMeshList
// Optimizes the mesh and compiles it into a display list (vx_maxoptimizerpasscount = 0
// is the fast optimizer)
//
//==============================================================================
function gld_BuildMeshList(const vmx: TVoxelMeshOptimizer; const map: IVoxelMeshVertexMap): GLuint;
var
  optimized: TVoxelMeshOptimizeResult;
  renderer: IVoxelMeshRenderer;
begin
  vx_maxoptimizerpasscount := GetIntegerInRange(vx_maxoptimizerpasscount, 0, MAX_VX_OPTIMIZE);
  optimized := vmx.Optimize(vx_maxoptimizerpasscount);
  if optimized.Kind = vokFast then
  begin
    if optimized.OldQuadCount > optimized.NewQuadCount then
      printf('    TVoxelMeshOptimizer.FastOptimize(): Mesh reduced from %d to %d quads.'#13#10, [optimized.OldQuadCount, optimized.NewQuadCount])
    else
      printf('    TVoxelMeshOptimizer.FastOptimize(): Can not reduce mesh complexity, size is %d quads.'#13#10, [optimized.NewQuadCount]);
  end
  else
  begin
    if optimized.OldQuadCount > optimized.NewQuadCount then
      printf('    TVoxelMeshOptimizer.Optimize(): Mesh reduced from %d to %d quads, pass count = %d.'#13#10, [optimized.OldQuadCount, optimized.NewQuadCount, optimized.Passes])
    else
      printf('    TVoxelMeshOptimizer.Optimize(): Can not reduce mesh complexity, size is %d quads.'#13#10, [optimized.NewQuadCount]);
  end;

  result := glGenLists(1);

  glNewList(result, GL_COMPILE);

    renderer := TEngineVoxelMeshRenderer.Create;
    vmx.Render(renderer, map);

  glEndList;
end;

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
  vmx: TVoxelMeshOptimizer;
  vstep, vmidx, vmidy, vmidz: float;
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

  vmx := TVoxelMeshOptimizer.Create;

  vstep := - 1 / MAP_COEFF * scale;
  vmidx := vstep * voxelsize / 2;
  vmidy := vstep * voxelsize + offset / MAP_COEFF; // Align down
  vmidz := vstep * voxelsize / 2;

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

  result := gld_BuildMeshList(vmx, TVoxelMeshDdvoxMap.Create(vmidx, vmidy, vmidz, vstep));

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
  vmx: TVoxelMeshOptimizer;

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

  vmx := TVoxelMeshOptimizer.Create;

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

  result := gld_BuildMeshList(vmx, TVoxelMeshKvxMap.Create);

  vmx.Free;
end;

//==============================================================================
//
// gld_LoadVoxelList
// The file is read by the loader of Libs\Voxel; each format makes its list
//
//==============================================================================
function gld_LoadVoxelList(const name: string; const offset, scale: float;
  const loader: IVoxelLoader; const cubes: IVoxelCubeBuilder): GLuint;
var
  model: IVoxelModel;
begin
  result := GL_BAD_LIST;
  model := loader.Load(name);
  if model = nil then
    Exit;

  case model.Format of
    vfDdmesh: result := gld_ListFromQuads(model, offset, scale);
    vfKvx: result := gld_ListFromKvx(model, offset, scale);
  else
    result := gld_ListFromCube(cubes.Build(model, cfRenderer), offset, scale);
  end;
end;

//==============================================================================
//
// TVoxelModel.Create
//
//==============================================================================
constructor TVoxelModel.Create(const name: string; const offset, scale: float;
  const ALoader: IVoxelLoader; const ACubes: IVoxelCubeBuilder);
var
  ext: string;
begin
  printf('  Found external voxel %s'#13#10, [name]);

  ext := strupper(fext(name));

  if ALoader.IsSupported(name) then
  begin
    fnumframes := 1;
    precalc := mallocz(fNumFrames * SizeOf(GLuint));
    precalc[0] := gld_LoadVoxelList(name, offset, scale, ALoader, ACubes);
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
