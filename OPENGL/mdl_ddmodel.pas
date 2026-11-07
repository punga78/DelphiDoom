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
//    DelphiDoom procedural models (DDMODEL source, DMX binary): the commands are
//    in a list of Libs\Models (IModelCommandStream), the model keeps the OpenGL
//    display lists.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit mdl_ddmodel;

interface

uses
  d_delphi,
  gl_types,
  mdl_base,
  DelphiDoom.Models.Intf;

type
  TDDModel = class(TBaseModel)
  protected
    fmdl: IModelCommandStream;
    fRenderer: IModelRenderer;
    fNumFrames: integer;
    precalc: PGLuintArray;
    fname: string;
    fxoffset, fyoffset, fzoffset: float;
    fxscale, fyscale, fzscale: float;
    procedure LoadFrom(const fn: string); virtual;
    procedure DrawSimpleIdx(const idx: integer); virtual;
  public
    constructor Create(const name: string;
      const xoffset, yoffset, zoffset: float;
      const xscale, yscale, zscale: float;
      const additionalframes: TDStringList); override;
    destructor Destroy; override;
    procedure Draw(const frm1, frm2: integer; const offset: float); override;
    procedure DrawSimple(const frm: integer); override;
  end;

implementation

uses
  SysUtils,
  dglOpenGL,
  doomdef,
  gl_defs,
  i_system,
  mdl_script_model,
  w_folders,
  w_pak,
  DelphiDoom.Models.Types,
  DelphiDoom.Engine.Models.Renderer;

//==============================================================================
//
// TDDModel.Create
//
//==============================================================================
constructor TDDModel.Create(const name: string;
  const xoffset, yoffset, zoffset: float;
  const xscale, yscale, zscale: float;
  const additionalframes: TDStringList);
var
  i: integer;
begin
  Inherited;
  printf('  Found external model %s'#13#10, [name]);
  fname := name;
  fxoffset := xoffset / MAP_COEFF;
  fyoffset := yoffset / MAP_COEFF;
  fzoffset := zoffset / MAP_COEFF;
  fxscale := xscale / MAP_COEFF;
  fyscale := yscale / MAP_COEFF;
  fzscale := zscale / MAP_COEFF;

  fmdl := MDL_NewCommandStream;
  fRenderer := TEngineModelRenderer.Create;
  fNumFrames := 0;
  precalc := nil;

  LoadFrom(name);

  if additionalframes <> nil then
    for i := 0 to additionalframes.Count - 1 do
      LoadFrom(additionalframes.Strings[i]);

  fNumFrames := fmdl.FrameCount;

  precalc := mallocz(fNumFrames * SizeOf(GLuint));
end;

//==============================================================================
//
// TDDModel.LoadFrom
//
//==============================================================================
procedure TDDModel.LoadFrom(const fn: string);
var
  strm: TPakStream;
  ext: string;
  source: TDStringList;
  bytes: TBytes;
begin
  // JVAL: the file opened is always the one of the model, not fn (as the old code did)
  strm := TPakStream.Create(fname, pm_prefered, gamedirectories);
  if strm.IOResult <> 0 then
  begin
    strm.Free;
    strm := TPakStream.Create(fname, pm_short, '', FOLDER_MODELS);
  end;
  if strm.IOResult <> 0 then
    I_Error('TDDModel.LoadFrom(): Can not find model %s!', [fname]);

  ext := d_delphi.strupper(fext(fn));
  if (ext = '.DDMODEL') or (ext = '.TXT') then
  begin
    source := TDStringList.Create;
    source.LoadFromStream(strm);
    MDL_AppendFromScript(fmdl, source.Text);
    source.Free;
  end
  else if ext = '.DMX' then
  begin
    SetLength(bytes, strm.Size);
    if Length(bytes) > 0 then
      strm.Read(bytes[0], Length(bytes));
    try
      fmdl.LoadFromBytes(bytes);
    except
      on E: EModelsException do
        I_Error('TDDModel.LoadFrom(): %s (%s)', [E.Message, fname]);
    end;
  end
  else
    I_Error('TDDModel.LoadFrom(): Invalid model type %s!', [fname]);
  strm.Free;
end;

//==============================================================================
//
// TDDModel.Destroy
//
//==============================================================================
destructor TDDModel.Destroy;
var
  i: integer;
begin
  for i := 0 to fNumFrames - 1 do
    if precalc[i] > 0 then
      glDeleteLists(precalc[i], 1);

  memfree(pointer(precalc), fNumFrames * SizeOf(GLuint));
  fmdl := nil;
  fRenderer := nil;

  Inherited;
end;

//==============================================================================
//
// TDDModel.Draw
//
//==============================================================================
procedure TDDModel.Draw(const frm1, frm2: integer; const offset: float);
var
  idx1, idx2: integer;
  idx: integer;
begin
  if (frm1 = frm2) or (frm2 < 0) or (offset < 0.01) then
  begin
    DrawSimple(frm1);
    Exit;
  end;
  if offset > 0.999 then
  begin
    DrawSimple(frm2);
    exit;
  end;

  idx1 := fmdl.IndexOfFrame(frm1);
  idx2 := fmdl.IndexOfFrame(frm2);

  if (idx1 >= 0) and (idx2 >= 0) then
  begin
    idx := Round(idx1 * (1.0 - offset) + idx2 * offset);
    DrawSimpleIdx(idx);
    Exit;
  end;

  if idx1 >= 0 then
  begin
    DrawSimpleIdx(idx1);
    Exit;
  end;

  if idx2 >= 0 then
  begin
    DrawSimpleIdx(idx2);
    Exit;
  end;
end;

//==============================================================================
//
// TDDModel.DrawSimpleIdx
//
//==============================================================================
procedure TDDModel.DrawSimpleIdx(const idx: integer);
begin
  if precalc[idx] > 0 then
    glCallList(precalc[idx])
  else
  begin
    precalc[idx] := glGenLists(1);

    glNewList(precalc[idx], GL_COMPILE_AND_EXECUTE);

    glMatrixMode(GL_MODELVIEW);
    glPushMatrix;
    glScalef(fxscale, fyscale, fzscale);
    glTranslatef(fxoffset, fyoffset, fzoffset);

    fmdl.Play(fmdl.Frames[idx], fRenderer);

    glPopMatrix;

    glEndList;
  end;
end;

//==============================================================================
//
// TDDModel.DrawSimple
//
//==============================================================================
procedure TDDModel.DrawSimple(const frm: integer);
var
  idx: integer;
begin
  idx := fmdl.IndexOfFrame(frm);
  if idx >= 0 then
  begin
    DrawSimpleIdx(idx);
    Exit;
  end;
  if fmdl.FrameCount = 1 then
    DrawSimpleIdx(0);
end;

end.
