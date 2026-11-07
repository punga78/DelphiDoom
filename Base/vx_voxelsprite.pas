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
//  Use Voxels as sprites without patch inside WAD
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit vx_voxelsprite;

interface

uses
  DelphiDoom.Voxel.Intf;

//==============================================================================
//
// VX_VoxelToSprite
//
//==============================================================================
procedure VX_VoxelToSprite;

//==============================================================================
//
// VX_ConfigureVoxelSprites
//
//==============================================================================
procedure VX_ConfigureVoxelSprites(const ALoader: IVoxelLoader; const ACubes: IVoxelCubeBuilder;
  const APatches: IVoxelPatchBuilder);

var
  r_generatespritesfromvoxels: boolean = true;

implementation

uses
  System.SysUtils,
  d_delphi,
  doomdef,
  i_tmp,
  m_argv,
  m_sha1,
  DelphiDoom.Voxel.Types,
  i_system,
  w_folders,
  w_pak,
  w_wad,
  w_wadwriter;

var
  vx_names: TDStringList = nil;
  vx_loader: IVoxelLoader = nil;
  vx_cubes: IVoxelCubeBuilder = nil;
  vx_patches: IVoxelPatchBuilder = nil;

//==============================================================================
//
// VX_ConfigureVoxelSprites
//
//==============================================================================
procedure VX_ConfigureVoxelSprites(const ALoader: IVoxelLoader; const ACubes: IVoxelCubeBuilder;
  const APatches: IVoxelPatchBuilder);
begin
  vx_loader := ALoader;
  vx_cubes := ACubes;
  vx_patches := APatches;
end;

//==============================================================================
//
// VX_SpriteExistsInWAD
//
//==============================================================================
function VX_SpriteExistsInWAD(const filename: string): boolean;
var
  check, lumpname: string;
  i: integer;
  in_loop: boolean;
begin
  check := firstword_ch(filename, '.'); // Input is uppercase
  SetLength(check, 5); // SPRITE & FRAME
  in_loop := false;
  for i := 0 to W_NumLumps - 1 do
  begin
    lumpname := char8tostring(W_GetNameForNum(i));
    if (lumpname = 'SS_START') or (lumpname = 'S_START') then
      in_loop := true
    else if (lumpname = 'SS_END') or (lumpname = 'S_END') then
      in_loop := false
    else if in_loop then
    begin
      if Pos1(check, lumpname) then
      begin
        result := true;
        exit;
      end;
    end;
  end;
  result := false;
end;

//==============================================================================
//
// VX_AddFileName
//
//==============================================================================
procedure VX_AddFileName(const filename: string);
var
  check: string;
  name: string;
  ext: string;
begin
  check := strupper(filename);
  ext := fext(check);
  if (ext = '.DDVOX') or (ext = '.DDMESH') or (ext = '.KVX') or (ext = '.VOX') or
     ((ext = '') and (Pos(FOLDER_VOXELS + '\', fixpathname(check)) > 0)) then
  begin
    check := fname(check);
    name := firstword_ch(check, '.');
    if (Length(name) = 5) or ((Length(name) = 6) and (name[6] = '0')) then
      if vx_names.IndexOf(name) < 0 then
        if not VX_SpriteExistsInWAD(name) then
          vx_names.Add(name + ext)
  end;
end;

const
  LUMP0: array[0..434] of Byte = (
    $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44,
    $52, $00, $00, $00, $80, $00, $00, $00, $80, $08, $02, $00, $00, $00, $4C,
    $5C, $F6, $9C, $00, $00, $00, $08, $67, $72, $41, $62, $00, $00, $00, $40,
    $00, $00, $00, $80, $37, $F7, $B6, $0F, $00, $00, $00, $09, $70, $48, $59,
    $73, $00, $00, $0B, $13, $00, $00, $0B, $13, $01, $00, $9A, $9C, $18, $00,
    $00, $01, $51, $49, $44, $41, $54, $78, $9C, $ED, $D9, $B1, $09, $C0, $30,
    $10, $04, $41, $0B, $5C, $98, $FA, $6F, $4A, $2E, $C1, $3C, $08, $36, $99,
    $89, $DF, $D1, $82, $02, $DF, $3A, $67, $3F, $84, $46, $01, $A6, $B5, $DC,
    $FF, $DE, $BF, $A3, $0F, $B8, $4E, $80, $98, $00, $31, $01, $62, $02, $C4,
    $04, $88, $09, $10, $13, $20, $26, $40, $4C, $80, $98, $00, $31, $01, $62,
    $02, $C4, $96, $DF, $D1, $31, $BF, $A3, $DB, $7B, $4F, $50, $4C, $80, $98,
    $00, $31, $01, $62, $02, $C4, $04, $88, $09, $10, $13, $20, $26, $40, $4C,
    $80, $98, $00, $31, $01, $62, $02, $C4, $04, $88, $D9, $03, $6A, $F6, $80,
    $F6, $DE, $13, $14, $13, $20, $26, $40, $4C, $80, $98, $00, $31, $01, $62,
    $02, $C4, $04, $88, $09, $10, $13, $20, $26, $40, $4C, $80, $98, $00, $31,
    $01, $62, $F6, $80, $9A, $3D, $A0, $BD, $F7, $04, $C5, $04, $88, $09, $10,
    $13, $20, $26, $40, $4C, $80, $98, $00, $31, $01, $62, $02, $C4, $04, $88,
    $09, $10, $13, $20, $26, $40, $4C, $80, $98, $3D, $A0, $66, $0F, $68, $EF,
    $3D, $41, $31, $01, $62, $02, $C4, $04, $88, $09, $10, $13, $20, $26, $40,
    $4C, $80, $98, $00, $31, $01, $62, $02, $C4, $04, $88, $09, $10, $13, $20,
    $66, $0F, $A8, $D9, $03, $DA, $7B, $4F, $50, $4C, $80, $98, $00, $31, $01,
    $62, $02, $C4, $04, $88, $09, $10, $13, $20, $26, $40, $4C, $80, $98, $00,
    $31, $01, $62, $02, $C4, $04, $88, $D9, $03, $6A, $F6, $80, $F6, $DE, $13,
    $14, $13, $20, $26, $40, $4C, $80, $98, $00, $31, $01, $62, $02, $C4, $04,
    $88, $09, $10, $13, $20, $26, $40, $4C, $80, $98, $00, $31, $01, $62, $F6,
    $80, $9A, $3D, $A0, $BD, $F7, $04, $C5, $04, $88, $09, $10, $13, $20, $26,
    $40, $4C, $80, $98, $00, $31, $01, $62, $02, $C4, $04, $88, $09, $10, $13,
    $20, $26, $40, $4C, $80, $98, $3D, $20, $F6, $01, $68, $2F, $B7, $64, $73,
    $C2, $B3, $80, $00, $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60, $82
  );

//==============================================================================
//
// VX_VoxelToSprite
//
//==============================================================================
procedure VX_VoxelToSprite;
var
  wad: TWADWriter;
  wadfilename: string;
  i: integer;
  mem: TDMemoryStream;
  generate: boolean;
  model: IVoxelModel;
  patch: TBytes;

  function _vxsprname(const vxn: string): string;
  begin
    result := firstword_ch(vx_names.Strings[i], '.');
    if Length(result) = 5 then
      result := result + '0';
  end;

begin
  vx_names := TDStringList.Create;
  PAK_FileNameIterator(@VX_AddFileName);

  generate := r_generatespritesfromvoxels;
  if generate and ((vx_loader = nil) or (vx_cubes = nil) or (vx_patches = nil)) then
    I_Error('VX_VoxelToSprite(): The voxel sprites are not configured');

  if vx_names.Count > 0 then
  begin
    wad := TWADWriter.Create;

    wad.AddSeparator('SS_START');

    if not generate then
    begin
      for i := 0 to vx_names.Count - 1 do
        wad.AddData(_vxsprname(vx_names.Strings[i]), @LUMP0, SizeOf(LUMP0));
    end
    else
    begin
      for i := 0 to vx_names.Count - 1 do
      begin
        // a name without a known extension is a KVX, as it has always been
        model := vx_loader.Load(vx_names.Strings[i]);
        if model <> nil then
        begin
          patch := vx_patches.Build(vx_cubes.Build(model, cfSprite));
          wad.AddData(_vxsprname(vx_names.Strings[i]), @patch[0], Length(patch));
        end
        else
          wad.AddData(_vxsprname(vx_names.Strings[i]), @LUMP0, SizeOf(LUMP0));
      end;
    end;
    wad.AddSeparator('SS_END');

    mem := TDMemoryStream.Create;

    wad.SaveToStream(mem);

    wadfilename := M_SaveFileName('DATA\');
    MkDir(wadfilename);
    wadfilename := wadfilename + 'TMP\';
    MkDir(wadfilename);
    wadfilename := wadfilename + 'voxelsprite_' + readablestring(SHA1_CalcSHA1Buf(mem.memory^, mem.Size)) + '.wad';
    mem.Free;

    wad.SaveToFile(wadfilename);

    wad.Free;

    W_RuntimeLoad(wadfilename, F_ORIGIN_WAD);

    I_DeclareTempFile(wadfilename);
  end;

  vx_names.Free;
end;

end.
