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
//  Basic Voxel Definitions
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit vx_base;

interface

uses
  DelphiDoom.Voxel.Types,
  DelphiDoom.Voxel.Intf,
{$IFDEF OPENGL}
  gl_defs,
  gl_voxels,
{$ELSE}
  m_fixed,
  r_voxels,
{$ENDIF}
  d_delphi;

const
  VX_FLG_CLIPPED = 1;

type
  voxelmanageritem_t = record
    name: string[64];
    offset: {$IFDEF OPENGL}float{$ELSE}fixed_t{$ENDIF};
    scale: {$IFDEF OPENGL}float{$ELSE}fixed_t{$ENDIF};
    angleoffset: integer;
    droppedspin: integer;
    placedspin: integer;
    flags: LongWord;
    voxel: TVoxelModel;
  end;

  Pvoxelmanageritem_t = ^voxelmanageritem_t;
  voxelmanageritem_tArray = array[0..$FFF] of voxelmanageritem_t;
  Pvoxelmanageritem_tArray = ^voxelmanageritem_tArray;

  voxelmanager_t = record
    size: integer;
    items: Pvoxelmanageritem_tArray;
  end;

type
  voxelstate_t = record
    voxelidx: integer;  // index to voxelmanager item
    frame: integer;
    state: integer;
  end;
  Pvoxelstate_t = ^voxelstate_t;
  voxelstate_tArray = array[0..$FFF] of voxelstate_t;
  Pvoxelstate_tArray = ^voxelstate_tArray;

var
  voxelmanager: voxelmanager_t;
  voxelstates: Pvoxelstate_tArray;
  numvoxelstates: integer;

//==============================================================================
//
// VX_InitVoxels
//
//==============================================================================
procedure VX_InitVoxels;

//==============================================================================
//
// VX_VoxelsDone
//
//==============================================================================
procedure VX_VoxelsDone;

//==============================================================================
//
// VX_ConfigureVoxels
//
//==============================================================================
procedure VX_ConfigureVoxels(const AParser: IVoxelDefinitionParser; const ASink: IVoxelDefinitionSink);

//==============================================================================
//
// VX_AddVoxel
//
//==============================================================================
function VX_AddVoxel(const item: voxelmanageritem_t): integer;

//==============================================================================
//
// VX_AddVoxelState
//
//==============================================================================
procedure VX_AddVoxelState(const item: voxelstate_t);

//==============================================================================
//
// VX_CheckVoxelSprite
//
//==============================================================================
procedure VX_CheckVoxelSprite(const sprname: string; const voxelsrc: string);

var
  voxelspritenames: TDStringList;

implementation

uses
  d_main,
  i_system,
  sc_utils,
  info,
  {$IFNDEF OPENGL}
  r_softgl,
  {$ENDIF}
  c_cmds,
  w_wad,
  w_pak;

var
  vx_definitionparser: IVoxelDefinitionParser = nil;
  vx_definitionsink: IVoxelDefinitionSink = nil;

//==============================================================================
//
// VX_AddVoxel
//
//==============================================================================
function VX_AddVoxel(const item: voxelmanageritem_t): integer;
var
  i: integer;
  voxelinf: Pvoxelmanageritem_t;
begin
  i := 0;
  while i < voxelmanager.size do
  begin
    if voxelmanager.items[i].name = item.name then
    begin
      result := i;
      exit;
    end;
    inc(i);
  end;

  realloc(pointer(voxelmanager.items), voxelmanager.size * SizeOf(voxelmanageritem_t), (1 + voxelmanager.size) * SizeOf(voxelmanageritem_t));
  result := voxelmanager.size;
  voxelinf := @voxelmanager.items[result];
  voxelinf.name := item.name;
  voxelinf.offset := item.offset;
  voxelinf.scale := item.scale;
  voxelinf.angleoffset := item.angleoffset;
  voxelinf.droppedspin := item.droppedspin;
  voxelinf.placedspin := item.placedspin;
  voxelinf.flags := item.flags;
  voxelinf.voxel := TVoxelModel.Create(voxelinf.name, voxelinf.offset, voxelinf.scale{$IFNDEF OPENGL}, voxelinf.flags{$ENDIF});

  inc(voxelmanager.size);
end;

//==============================================================================
//
// VX_AddVoxelState
//
//==============================================================================
procedure VX_AddVoxelState(const item: voxelstate_t);
begin
  if item.state < 0 then
    exit;

  realloc(pointer(voxelstates), numvoxelstates * SizeOf(voxelstate_t), (1 + numvoxelstates) * SizeOf(voxelstate_t));
  voxelstates[numvoxelstates] := item;
  if states[item.state].voxels = nil then
    states[item.state].voxels := TDNumberList.Create;
  states[item.state].voxels.Add(numvoxelstates);
  inc(numvoxelstates);
end;

const
  SPRITEFRAMECHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]';

//==============================================================================
//
// VX_CheckVoxelSprite
// JVAL 20191204
//    Add the sprname and the it's voxel source
//    Only one voxel (first parsed) per sprite though
//
//==============================================================================
procedure VX_CheckVoxelSprite(const sprname: string; const voxelsrc: string);
var
  s1, s2, check: string;
  i: integer;
begin
  splitstring_ch(fname(sprname), s1, s2, '.');
  check := strupper(s1);
  if Length(check) = 4 then
  begin
    for i := 1 to Length(SPRITEFRAMECHARS) do
      if voxelspritenames.IndexOfName(check + SPRITEFRAMECHARS[i]) < 0 then
        voxelspritenames.Add(check + SPRITEFRAMECHARS[i] + '0' + '=' + strupper(voxelsrc));
  end
  else if Length(check) = 5 then
  begin
    if voxelspritenames.IndexOfName(check) < 0 then
      voxelspritenames.Add(check + '0' + '=' + strupper(voxelsrc));
  end
  else if Length(check) = 6 then
  begin
    if check[6] = '0' then
      if voxelspritenames.IndexOfName(check) < 0 then
        voxelspritenames.Add(check + '=' + strupper(voxelsrc));
  end;
end;

const
  VOXELDEFLUMPNAME = 'VOXELDEF';

//==============================================================================
// SC_DoParseVoxelDefinition
//
// SC_ParseVoxelDefinition
// JVAL: Parse VOXELDEF LUMP
//
//==============================================================================
procedure SC_DoParseVoxelDefinition(const in_text: string);
var
  slist: TDStringList;
  i: integer;
begin
  if devparm then
  begin
    printf('--------'#13#10);
    printf('SC_ParseVoxelDefinition(): Parsing %s lump:'#13#10, [VOXELDEFLUMPNAME]);

    slist := TDStringList.Create;
    try
      slist.Text := in_text;
      for i := 0 to slist.Count - 1 do
        printf('%s: %s'#13#10, [IntToStrZFill(6, i + 1), slist[i]]);
    finally
      slist.Free;
    end;

    printf('--------'#13#10);
  end;

  if (vx_definitionparser = nil) or (vx_definitionsink = nil) then
    I_Error('SC_ParseVoxelDefinition(): The VOXELDEF parser is not configured');

  vx_definitionparser.Parse(in_text, vx_definitionsink);
end;

//==============================================================================
//
// VX_ConfigureVoxels
//
//==============================================================================
procedure VX_ConfigureVoxels(const AParser: IVoxelDefinitionParser; const ASink: IVoxelDefinitionSink);
begin
  vx_definitionparser := AParser;
  vx_definitionsink := ASink;
end;

//==============================================================================
//
// SC_ParseVoxelDefinition
//
//==============================================================================
procedure SC_ParseVoxelDefinition(const in_text: string);
begin
  SC_DoParseVoxelDefinition(SC_Preprocess(in_text, false));
end;

//==============================================================================
//
// SC_ParseVoxelDefinitions
// JVAL: Parse all VOXELDEF lumps
//
//==============================================================================
procedure SC_ParseVoxelDefinitions;
var
  i: integer;
{$IFNDEF OPENGL}
  j: integer;
  radius: integer;
{$ENDIF}
begin
// Retrive voxeldef lumps
  for i := 0 to W_NumLumps - 1 do
    if char8tostring(W_GetNameForNum(i)) = VOXELDEFLUMPNAME then
      SC_ParseVoxelDefinition(W_TextLumpNum(i));

  PAK_StringIterator(VOXELDEFLUMPNAME, SC_ParseVoxelDefinition);
  PAK_StringIterator(VOXELDEFLUMPNAME + '.txt', SC_ParseVoxelDefinition);

{$IFNDEF OPENGL}
  for i := 0 to numstates - 1 do
  begin
    radius := 0;
    if states[i].voxels <> nil then
      for j := 0 to states[i].voxels.Count - 1 do
        if voxelmanager.items[voxelstates[states[i].voxels.Numbers[j]].voxelidx].voxel.radius > radius then
          radius := voxelmanager.items[voxelstates[states[i].voxels.Numbers[j]].voxelidx].voxel.radius;
    states[i].voxelradius := 2 * radius;
  end;
{$ENDIF}
end;

//==============================================================================
//
// Cmd_VoxelMapping
//
//==============================================================================
procedure Cmd_VoxelMapping;
var
  i: integer;
  mapped: boolean;
begin
  for i := 0 to nummobjtypes - 1 do
  begin
    mapped := false;
    if mobjinfo[i].spawnstate > 0 then
      if states[mobjinfo[i].spawnstate].voxels <> nil then
        if states[mobjinfo[i].spawnstate].voxels.Count > 0 then
          mapped := True;
    if mapped then
      printf('%s -> voxel mapped'#13#10, [mobjinfo[i].name])
    else
      printf('%s -> voxel unmapped'#13#10, [mobjinfo[i].name]);
  end;
end;

//==============================================================================
//
// VX_InitVoxels
//
//==============================================================================
procedure VX_InitVoxels;
begin
  voxelmanager.size := 0;
  voxelmanager.items := nil;
  numvoxelstates := 0;
  voxelstates := nil;
  voxelspritenames := TDStringList.Create;
  printf('SC_ParseVoxelDefinitions: Parsing VOXELDEF lumps.'#13#10);
  SC_ParseVoxelDefinitions;
  C_AddCmd('voxelmapping', @Cmd_VoxelMapping);
end;

//==============================================================================
//
// VX_VoxelsDone
//
//==============================================================================
procedure VX_VoxelsDone;
var
  i: integer;
begin
  for i := 0 to voxelmanager.size - 1 do
  begin
    if voxelmanager.items[i].voxel <> nil then
    begin
      voxelmanager.items[i].voxel.Free;
      voxelmanager.items[i].voxel := nil;
    end;
  end;

  memfree(pointer(voxelmanager.items), voxelmanager.size * SizeOf(voxelmanageritem_t));
  voxelmanager.size := 0;

  if numvoxelstates > 0 then
  begin
    memfree(pointer(voxelstates), numvoxelstates * SizeOf(voxelstate_t));
    numvoxelstates := 0;
  end;

  voxelspritenames.Free;
end;

end.

