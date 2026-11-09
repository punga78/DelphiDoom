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
//    External model support
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit gl_models;

// JVAL: Support for MD2 models

interface

uses
  d_delphi,
  m_fixed,
  dglOpenGL,
  mdl_base,
  DelphiDoom.Scanner.Preprocessor.Intf,
  DelphiDoom.Models.Definition.Intf;

var
  gl_drawmodels: boolean = true;
  gl_smoothmodelmovement: boolean = true;
  gl_precachemodeltextures: boolean = true;

type
  modeltype_t = (
    mt_md2,     // md2 (Quake2) models
    mt_ddmodel, // DelphiDoom Procedural model (source code)
    mt_dmx,     // DelphiDoom Procedural model (binary)
    mt_dll,     // External DLL
    mt_unknown
  );

type
  TModel = class
  protected
    fmodel: TBaseModel;
    fmodeltype: modeltype_t;
    flastdrawframe: integer;
  public
    constructor Create(const name, proc: string; const xoffset, yoffset, zoffset,
      xscale, yscale, zscale: float; const additionalframes: TDStringList); virtual;
    destructor Destroy; override;
    procedure Draw(const frm1, frm2: integer; const offset: float);
    procedure DrawSimple(const frm: integer);
    property modeltype: modeltype_t read fmodeltype;
    property lastdrawframe: integer read flastdrawframe;
  end;

//==============================================================================
//
// gld_InitModels
//
//==============================================================================
procedure gld_InitModels;

//==============================================================================
//
// gld_CleanModelTextures
//
//==============================================================================
procedure gld_CleanModelTextures;

//==============================================================================
//
// gld_ModelsDone
//
//==============================================================================
procedure gld_ModelsDone;

//==============================================================================
//
// gld_ConfigureModelDefinitions
//
// The script preprocessor that MODELDEF goes through (given by ComposeEngine)
//
//==============================================================================
procedure gld_ConfigureModelDefinitions(const APreprocessor: IScriptTextPreprocessor;
  const AParser: IModelDefinitionParser; const ASink: IModelDefinitionSink);

const
  MDSTRLEN = 64;
  MDPROCLEN = 48;

type
  modelmanageritem_t = record
    name: string[MDSTRLEN];
    proc: string[MDPROCLEN]; // JVAL 20181117 - For dll models
    xoffset: float;
    yoffset: float;
    zoffset: float;
    xscale: float;
    yscale: float;
    zscale: float;
    framemerge: TDStringList;
    model: TModel;
  end;
  Pmodelmanageritem_t = ^modelmanageritem_t;
  modelmanageritem_tArray = array[0..$FFF] of modelmanageritem_t;
  Pmodelmanageritem_tArray = ^modelmanageritem_tArray;

  modelmanager_t = record
    size: integer;
    items: Pmodelmanageritem_tArray;
  end;

type
  texturemanagetitem_t = record
    name: string[MDSTRLEN];
    tex: GLUint;
  end;
  Ptexturemanagetitem_t = ^texturemanagetitem_t;
  texturemanagetitem_tArray = array[0..$FFF] of texturemanagetitem_t;
  Ptexturemanagetitem_tArray = ^texturemanagetitem_tArray;

  modeltexturemanager_t = record
    size: integer;
    items: Ptexturemanagetitem_tArray;
  end;

type
  modelstate_t = record
    modelidx: integer;  // index to modelmanager item
    texture: integer;   // index to modeltexturemanager item
    startframe,
    endframe: integer;
    nextframe: integer;
    state: integer;
    transparency: float;
  end;
  Pmodelstate_t = ^modelstate_t;
  modelstate_tArray = array[0..$FFF] of modelstate_t;
  Pmodelstate_tArray = ^modelstate_tArray;

var
  modelmanager: modelmanager_t;
  modeltexturemanager: modeltexturemanager_t;
  modelstates: Pmodelstate_tArray;
  nummodelstates: integer;

//==============================================================================
//
// gld_AddModel
//
// The registry of the models: a model with the name it already has gives its index
//
//==============================================================================
function gld_AddModel(const item: modelmanageritem_t): integer;

//==============================================================================
//
// gld_AddModelState
//
//==============================================================================
procedure gld_AddModelState(const item: modelstate_t);

//==============================================================================
//
// gld_AddModelTexture
//
//==============================================================================
function gld_AddModelTexture(const texturename: string): integer;

const
  MODELINTERPOLATERANGE = 512 * FRACUNIT;

implementation

uses
  c_cmds,
  d_main,
  i_system,
  info,
  mdl_md2,
  mdl_ddmodel,
  mdl_dllmodel,
  gl_tex,
  sc_states,
  w_pak,
  w_wad;

var
  modeldef_preprocessor: IScriptTextPreprocessor;
  modeldef_parser: IModelDefinitionParser;
  modeldef_sink: IModelDefinitionSink;

//==============================================================================
//
// gld_ConfigureModelDefinitions
//
//==============================================================================
procedure gld_ConfigureModelDefinitions(const APreprocessor: IScriptTextPreprocessor;
  const AParser: IModelDefinitionParser; const ASink: IModelDefinitionSink);
begin
  modeldef_preprocessor := APreprocessor;
  modeldef_parser := AParser;
  modeldef_sink := ASink;
end;

//==============================================================================
//
// gld_AddModel
//
//==============================================================================
function gld_AddModel(const item: modelmanageritem_t): integer;
var
  i: integer;
  modelinf: Pmodelmanageritem_t;
begin
  i := 0;
  while i < modelmanager.size do
  begin
    if modelmanager.items[i].name = item.name then
    begin
      result := i;
      exit;
    end;
    inc(i);
  end;

  realloc(pointer(modelmanager.items), modelmanager.size * SizeOf(modelmanageritem_t), (1 + modelmanager.size) * SizeOf(modelmanageritem_t));
  result := modelmanager.size;
  modelinf := @modelmanager.items[result];
  modelinf.name := item.name;
  modelinf.proc := item.proc;
  modelinf.xoffset := item.xoffset;
  modelinf.yoffset := item.yoffset;
  modelinf.zoffset := item.zoffset;
  modelinf.xscale := item.xscale;
  modelinf.yscale := item.yscale;
  modelinf.zscale := item.zscale;
  if item.framemerge.Count > 0 then
  begin
    modelinf.framemerge := TDStringList.Create;
    modelinf.framemerge.AddStrings(item.framemerge);
  end
  else
    modelinf.framemerge := nil;
  modelinf.model := TModel.Create(modelinf.name, modelinf.proc,
    modelinf.xoffset, modelinf.yoffset, modelinf.zoffset,
    modelinf.xscale, modelinf.yscale, modelinf.zscale,
    modelinf.framemerge);

  inc(modelmanager.size);
end;

//==============================================================================
//
// gld_AddModelState
//
//==============================================================================
procedure gld_AddModelState(const item: modelstate_t);
begin
  if item.state < 0 then
    exit;

  realloc(pointer(modelstates), nummodelstates * SizeOf(modelstate_t), (1 + nummodelstates) * SizeOf(modelstate_t));
  modelstates[nummodelstates] := item;
  if states[item.state].models = nil then
    states[item.state].models := TDNumberList.Create;
  states[item.state].models.Add(nummodelstates);
  inc(nummodelstates);
end;

//==============================================================================
//
// gld_AddModelTexture
//
//==============================================================================
function gld_AddModelTexture(const texturename: string): integer;
var
  i: integer;
begin
  i := 0;
  while i < modeltexturemanager.size do
  begin
    if modeltexturemanager.items[i].name = texturename then
    begin
      result := i;
      exit;
    end;
    inc(i);
  end;
  realloc(pointer(modeltexturemanager.items), modeltexturemanager.size * SizeOf(texturemanagetitem_t), (1 + modeltexturemanager.size) * SizeOf(texturemanagetitem_t));
  result := modeltexturemanager.size;
  modeltexturemanager.items[result].name := texturename;
  if gl_precachemodeltextures then
    modeltexturemanager.items[result].tex := gld_LoadExternalTexture(texturename, true, GL_REPEAT)
  else
    modeltexturemanager.items[result].tex := 0;
  inc(modeltexturemanager.size);
end;

const
  MODELDEFLUMPNAME = 'MODELDEF';

//==============================================================================
//
// SC_ParseModelDefinition
//
// JVAL: Parse a MODELDEF lump. The text is read by the parser of Libs\Models
// (issue #177), the models, textures and states go to modeldef_sink.
//
//==============================================================================
procedure SC_ParseModelDefinition(const in_text: string);
var
  text: string;
  slist: TDStringList;
  i: integer;
begin
  if (modeldef_preprocessor = nil) or (modeldef_parser = nil) or (modeldef_sink = nil) then
    I_Error('SC_ParseModelDefinition(): the parser is not configured (ComposeEngine was not called)');
  text := modeldef_preprocessor.Preprocess(in_text, false);

  if devparm then
  begin
    printf('--------'#13#10);
    printf('SC_ParseModelDefinition(): Parsing %s lump:'#13#10, [MODELDEFLUMPNAME]);

    slist := TDStringList.Create;
    try
      slist.Text := text;
      for i := 0 to slist.Count - 1 do
        printf('%s: %s'#13#10, [IntToStrZFill(6, i + 1), slist[i]]);
    finally
      slist.Free;
    end;

    printf('--------'#13#10);
  end;

  modeldef_parser.Parse(text, modeldef_sink);
end;

//==============================================================================
//
// SC_ParseModelDefinitions
// JVAL: Parse all MODELDEF lumps
//
//==============================================================================
procedure SC_ParseModelDefinitions;
var
  i: integer;
begin
// Retrive modeldef lumps
  for i := 0 to W_NumLumps - 1 do
    if char8tostring(W_GetNameForNum(i)) = MODELDEFLUMPNAME then
      SC_ParseModelDefinition(W_TextLumpNum(i));

  PAK_StringIterator(MODELDEFLUMPNAME, SC_ParseModelDefinition);
  PAK_StringIterator(MODELDEFLUMPNAME + '.txt', SC_ParseModelDefinition);
end;

//==============================================================================
//
// Cmd_ModelMapping
//
//==============================================================================
procedure Cmd_ModelMapping;
var
  i: integer;
  mapped: boolean;
begin
  for i := 0 to nummobjtypes - 1 do
  begin
    mapped := false;
    if mobjinfo[i].spawnstate > 0 then
      if states[mobjinfo[i].spawnstate].models <> nil then
        if states[mobjinfo[i].spawnstate].models.Count > 0 then
          mapped := True;
    if mapped then
      printf('%s -> model mapped'#13#10, [mobjinfo[i].name])
    else
      printf('%s -> model unmapped'#13#10, [mobjinfo[i].name]);
  end;
end;

//==============================================================================
//
// gld_InitModels
//
//==============================================================================
procedure gld_InitModels;
begin
  modelmanager.size := 0;
  modelmanager.items := nil;
  modeltexturemanager.size := 0;
  modeltexturemanager.items := nil;
  nummodelstates := 0;
  modelstates := nil;
  printf('SC_ParseModelDefinitions: Parsing MODELDEF lumps.'#13#10);
  SC_ParseModelDefinitions;
  C_AddCmd('modelmapping', @Cmd_ModelMapping);
end;

//==============================================================================
//
// gld_CleanModelTextures
//
//==============================================================================
procedure gld_CleanModelTextures;
var
  i: integer;
begin
  if gl_precachemodeltextures then
    exit;

  for i := 0 to modeltexturemanager.size - 1 do
  begin
    if modeltexturemanager.items[i].tex <> 0 then
    begin
      glDeleteTextures(1, @modeltexturemanager.items[i].tex);
      modeltexturemanager.items[i].tex := 0;
    end;
  end;
end;

//==============================================================================
//
// gld_ModelsDone
//
//==============================================================================
procedure gld_ModelsDone;
var
  i: integer;
begin
  for i := 0 to modelmanager.size - 1 do
  begin
    if modelmanager.items[i].model <> nil then
    begin
      modelmanager.items[i].model.Free;
      modelmanager.items[i].model := nil;
    end;
    modelmanager.items[i].framemerge.Free;
  end;

  memfree(pointer(modelmanager.items), modelmanager.size * SizeOf(modelmanageritem_t));
  modelmanager.size := 0;

  for i := 0 to modeltexturemanager.size - 1 do
  begin
    if modeltexturemanager.items[i].tex <> 0 then
    begin
      glDeleteTextures(1, @modeltexturemanager.items[i].tex);
      modeltexturemanager.items[i].tex := 0;
    end;
  end;
  memfree(pointer(modeltexturemanager.items), modeltexturemanager.size * SizeOf(texturemanagetitem_t));
  modeltexturemanager.size := 0;

  if nummodelstates > 0 then
  begin
    memfree(pointer(modelstates), nummodelstates * SizeOf(modelstate_t));
    nummodelstates := 0;
  end;
end;

//------------------------------------------------------------------------------
//------------------------------ TModel Class ----------------------------------
//------------------------------------------------------------------------------

//==============================================================================
//
// TModel.Create
//
//==============================================================================
constructor TModel.Create(const name, proc: string; const xoffset, yoffset, zoffset,
  xscale, yscale, zscale: float; const additionalframes: TDStringList);
var
  ext: string;
begin
  fmodeltype := mt_unknown;
  ext := strupper(fext(name));
  if ext = '.MD2' then
  begin
    fmodel := TMD2Model.Create(name, xoffset, yoffset, zoffset, xscale, yscale, zscale, additionalframes);
    fmodeltype := mt_md2;
  end
  else if (ext = '.DDMODEL') or (ext = '.TXT') then
  begin
    fmodel := TDDModel.Create(name, xoffset, yoffset, zoffset, xscale, yscale, zscale, additionalframes);
    fmodeltype := mt_ddmodel;
  end
  else if ext = '.DMX' then
  begin
    fmodel := TDDModel.Create(name, xoffset, yoffset, zoffset, xscale, yscale, zscale, additionalframes);
    fmodeltype := mt_dmx;
  end
  else if ext = '.DLL' then
  begin
    fmodel := TDLLModel.CreateWithProc(name, proc, xoffset, yoffset, zoffset, xscale, yscale, zscale, additionalframes);
    fmodeltype := mt_dll;
  end
  else
    I_Error('TModel.Create(): Invalid model type "%s"', [ext]);
  flastdrawframe := 0;
end;

//==============================================================================
//
// TModel.Destroy
//
//==============================================================================
destructor TModel.Destroy;
begin
  fmodel.Free;
end;

//==============================================================================
//
// TModel.Draw
//
//==============================================================================
procedure TModel.Draw(const frm1, frm2: integer; const offset: float);
begin
  fmodel.Draw(frm1, frm2, offset);
  flastdrawframe := Round(frm1 * (1.0 - offset) + frm2 * offset);
end;

//==============================================================================
//
// TModel.DrawSimple
//
//==============================================================================
procedure TModel.DrawSimple(const frm: integer);
begin
  fmodel.DrawSimple(frm);
  flastdrawframe := frm;
end;

//------------------------------------------------------------------------------

end.
