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
//  DESCRIPTION:
//    External MD2 model support. The file is read by Libs\Models (IMd2Parser);
//    the model keeps the pointers to the vertexes of each frame and the OpenGL
//    display lists, and draws.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit mdl_md2;

interface

uses
  d_delphi,
  mdl_base,
  gl_types,
  DelphiDoom.Models.Intf;

type
  TMD2Model = class(TBaseModel)
  protected
    fNumFrames: integer;
    fNumVertexes: integer;
    fdata: IMd2Model;
    // the vertexes of each frame and the texture points: the memory is of fdata, the draw does
    // not call the interface
    fframes: array of PGLVertex;
    UV: PGLTexcoord;
    precalc: PGLuintArray;
    fname: string;
    procedure RefreshFrames;
  public
    constructor Create(const name: string;
      const xoffset, yoffset, zoffset: float;
      const xscale, yscale, zscale: float;
      const additionalframes: TDStringList); override;
    destructor Destroy; override;
    function MergeFrames(const m: TBaseModel): boolean; virtual;
    procedure Draw(const frm1, frm2: integer; const offset: float); override;
    procedure DrawSimple(const frm: integer); override;
    function StartFrame(const i: integer): integer; overload; virtual;
    function EndFrame(const i: integer): integer; overload; virtual;
    function StartFrame(const frame: string): integer; overload; virtual;
    function EndFrame(const frame: string): integer; overload; virtual;
    function FrameName(const i: integer): string; virtual;
    function FrameIndex(const frame: string): integer; virtual;
  end;

implementation

uses
  SysUtils,
  dglOpenGL,
  doomdef,
  i_system,
  w_folders,
  w_pak,
  gl_defs,
  DelphiDoom.Models.Types;

//==============================================================================
//
// TMD2Model.Create
//
//==============================================================================
constructor TMD2Model.Create(const name: string;
  const xoffset, yoffset, zoffset: float;
  const xscale, yscale, zscale: float;
  const additionalframes: TDStringList);
var
  strm: TPakStream;
  i: Integer;
  m: TMD2Model;
  placement: TModelPlacement;
  bytes: TBytes;
begin
  Inherited;
  printf('  Found external model %s'#13#10, [name]);
  fname := name;
  fNumFrames := 0;
  fNumVertexes := 0;
  UV := nil;
  // the offsets and the scales are in map units: the library gets them divided by MAP_COEFF
  placement.OffsetX := xoffset / MAP_COEFF;
  placement.OffsetY := yoffset / MAP_COEFF;
  placement.OffsetZ := zoffset / MAP_COEFF;
  placement.ScaleX := xscale / MAP_COEFF;
  placement.ScaleY := yscale / MAP_COEFF;
  placement.ScaleZ := zscale / MAP_COEFF;
  strm := TPakStream.Create(fname, pm_prefered, gamedirectories);
  if strm.IOResult <> 0 then
  begin
    strm.Free;
    strm := TPakStream.Create(fname, pm_short, '', FOLDER_MODELS);
  end;
  if strm.IOResult <> 0 then
    I_Error('TMD2Model.Create(): Can not find model %s!', [fname]);

  SetLength(bytes, strm.Size);
  if Length(bytes) > 0 then
    strm.Read(bytes[0], Length(bytes));
  strm.Free;

  try
    fdata := MDL_Md2Parser.Parse(bytes, placement);
  except
    on E: EModelsException do
      I_Error('TMD2Model.Create(): %s (%s)', [E.Message, fname]);
  end;

  fNumFrames := fdata.FrameCount;
  fNumVertexes := fdata.VertexCount;
  RefreshFrames;
  precalc := mallocz(fNumFrames * SizeOf(GLuint));

  if additionalframes <> nil then
    for i := 0 to additionalframes.Count - 1 do
    begin
      m := TMD2Model.Create(additionalframes.strings[i],
        xoffset, yoffset, zoffset,
        xscale, yscale, zscale, nil);
      if not MergeFrames(m) then
        I_Error('TMD2Model.MergeFrames(): Can not merge model "%s" into model "%s"', [additionalframes.strings[i], fname]);
      m.Free;
    end;

end;

//==============================================================================
//
// TMD2Model.RefreshFrames
//
//==============================================================================
procedure TMD2Model.RefreshFrames;
var
  i: integer;
begin
  SetLength(fframes, fdata.FrameCount);
  for i := 0 to fdata.FrameCount - 1 do
    fframes[i] := PGLVertex(fdata.GetFrameVertices(i));
  UV := PGLTexcoord(fdata.GetTexCoords);
end;

//==============================================================================
//
// TMD2Model.MergeFrames
//
//==============================================================================
function TMD2Model.MergeFrames(const m: TBaseModel): boolean;
var
  model: TMD2Model;
  oldframes: integer;
  i: integer;
begin
  if not (m is TMD2Model) then
  begin
    Result := False;
    Exit;
  end;

  model := m as TMD2Model;
  if not fdata.MergeFrames(model.fdata) then
  begin
    Result := False;
    Exit;
  end;

  oldframes := fNumFrames;
  fNumFrames := fdata.FrameCount;

  realloc(pointer(precalc),
    oldframes * SizeOf(GLuint),
    fNumFrames * SizeOf(GLuint));
  for i := oldframes to fNumFrames - 1 do
    precalc[i] := 0;

  RefreshFrames;

  Result := True;
end;

//==============================================================================
//
// TMD2Model.Destroy
//
//==============================================================================
destructor TMD2Model.Destroy;
var
  i: integer;
begin
  for i := 0 to fNumFrames - 1 do
    if precalc[i] > 0 then
      glDeleteLists(precalc[i], 1);
  memfree(pointer(precalc), fNumFrames * SizeOf(GLuint));
  fframes := nil;
  UV := nil;
  fdata := nil;

  Inherited;
end;

//==============================================================================
//
// TMD2Model.Draw
//
//==============================================================================
procedure TMD2Model.Draw(const frm1, frm2: integer; const offset: float);
var
  w2: float;
  v1, v2, mark: PGLVertex;
  x, y, z: float;
  coord: PGLTexcoord;
begin
{$IFDEF DEBUG}
  printf('gametic=%d, frm1=%d, frm2=%d, offset=%2.2f'#13#10, [gametic, frm1, frm2, offset]);
{$ENDIF}
  if (frm1 = frm2) or (frm2 < 0) or (offset < 0.01) then
  begin
    DrawSimple(frm1);
    exit;
  end;

  if offset > 0.99 then
  begin
    DrawSimple(frm2);
    exit;
  end;

  w2 := 1.0 - offset;

  v1 := fframes[frm1];
  mark := PGLVertex(NativeUInt(fframes[frm1]) + NativeUInt(fNumVertexes) * SizeOf(GLVertex));
  v2 := fframes[frm2];
  coord := UV;

  glBegin(GL_TRIANGLES);
    while NativeUInt(v1) < NativeUInt(mark) do
    begin
      x := v1.x * w2 + v2.x * offset;
      y := v1.y * w2 + v2.y * offset;
      z := v1.z * w2 + v2.z * offset;
      glTexCoord2fv(@coord.u);
      glVertex3f(x, y, z);
      inc(v1);
      inc(v2);
      inc(coord);
    end;
  glEnd;
end;

//==============================================================================
//
// TMD2Model.DrawSimple
//
//==============================================================================
procedure TMD2Model.DrawSimple(const frm: integer);
var
  i: integer;
  vert: PGLVertex;
  coord: PGLTexcoord;
begin
  if precalc[frm] > 0 then
    glCallList(precalc[frm])
  else
  begin
    precalc[frm] := glGenLists(1);

    glNewList(precalc[frm], GL_COMPILE_AND_EXECUTE);

      vert := fframes[frm];
      coord := UV;
      glBegin(GL_TRIANGLES);
        for i := 0 to fNumVertexes - 1 do
        begin
          glTexCoord2f(coord.u, coord.v);
          glVertex3fv(@vert.x);
          inc(vert);
          inc(coord);
        end;
      glEnd;

    glEndList;
  end;
end;

//==============================================================================
//
// TMD2Model.StartFrame
//
//==============================================================================
function TMD2Model.StartFrame(const i: integer): integer;
begin
  result := fdata.GetGroupStartFrame(i);
end;

//==============================================================================
//
// TMD2Model.EndFrame
//
//==============================================================================
function TMD2Model.EndFrame(const i: integer): integer;
begin
  result := fdata.GetGroupEndFrame(i);
end;

//==============================================================================
//
// TMD2Model.StartFrame
//
//==============================================================================
function TMD2Model.StartFrame(const frame: string): integer;
begin
  result := StartFrame(fdata.FindGroup(frame));
  if result = -1 then
    result := StartFrame(fdata.FindGroup(d_delphi.strupper(frame)));
end;

//==============================================================================
//
// TMD2Model.EndFrame
//
//==============================================================================
function TMD2Model.EndFrame(const frame: string): integer;
begin
  result := EndFrame(fdata.FindGroup(frame));
  if result = -1 then
    result := EndFrame(fdata.FindGroup(d_delphi.strupper(frame)));
end;

//==============================================================================
//
// TMD2Model.FrameName
//
//==============================================================================
function TMD2Model.FrameName(const i: integer): string;
begin
  result := fdata.GetGroupName(i);
end;

//==============================================================================
//
// TMD2Model.FrameIndex
//
//==============================================================================
function TMD2Model.FrameIndex(const frame: string): integer;
begin
  result := fdata.FindGroup(frame);
  if result = -1 then
    result := fdata.FindGroup(d_delphi.strupper(frame));
end;

//------------------------------------------------------------------------------

end.
