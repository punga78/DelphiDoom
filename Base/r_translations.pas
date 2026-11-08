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
//
// DESCRIPTION:
//  Translation tables
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_translations;

interface

uses
  p_mobj_h,
  DelphiDoom.Palette.Intf,
  DelphiDoom.Pak.Intf;

type
  translationtable_t = array[0..255] of byte;
  Ptranslationtable_t = ^translationtable_t;
  translationtable_tArray = array[0..$FF] of translationtable_t;
  Ptranslationtable_tArray = ^translationtable_tArray;

//==============================================================================
//
// R_ConfigureTranslations
// The names of the translations of Libs\Palette and the PAK file system (a table can be a
// file of 256 bytes), given by the composition root. The blood colors are TTranslationBlood
//
//==============================================================================
procedure R_ConfigureTranslations(const ANames: ITranslationNames; const APakFiles: IPakFileSystem);

//==============================================================================
//
// R_InitTranslations
//
//==============================================================================
procedure R_InitTranslations;

//==============================================================================
//
// R_ShutDownTranslations
//
//==============================================================================
procedure R_ShutDownTranslations;

//==============================================================================
//
// R_InitMobjTranslation
//
//==============================================================================
procedure R_InitMobjTranslation(const mo: Pmobj_t);

//==============================================================================
//
// R_SetMobjBloodTranslation
//
//==============================================================================
procedure R_SetMobjBloodTranslation(const mo: Pmobj_t; const blood: integer);

implementation

uses
  Classes,
  d_delphi,
  i_system,
  r_draw,
  w_wad,
  z_zone,
  DelphiDoom.Wad.Pak.Types,
  DelphiDoom.Palette.Types,
  DelphiDoom.Palette.TranslationBlood;

var
  translation_names: ITranslationNames = nil;
  translation_pakfiles: IPakFileSystem = nil;
  // the table of each slot of translation_names: the first ones are the color regions
  translation_tables: TList = nil;

//==============================================================================
//
// R_ConfigureTranslations
//
//==============================================================================
procedure R_ConfigureTranslations(const ANames: ITranslationNames; const APakFiles: IPakFileSystem);
begin
  translation_names := ANames;
  translation_pakfiles := APakFiles;
end;

//==============================================================================
//
// R_InitTranslations
//
//==============================================================================
procedure R_InitTranslations;
var
  i: integer;
begin
  if translation_names = nil then
    I_Error('R_InitTranslations(): the translation names are not configured (ComposeEngine was not called)');

  translation_tables := TList.Create;
  for i := 0 to REGION_COUNT - 1 do
    translation_tables.Add(colorregions[i]);
end;

//==============================================================================
//
// R_ShutDownTranslations
//
//==============================================================================
procedure R_ShutDownTranslations;
begin
  translation_tables.Free;
  translation_tables := nil;
end;

//==============================================================================
//
// R_GetTranslationTable
//
//==============================================================================
function R_GetTranslationTable(const name: string): Ptranslationtable_t;
var
  key: string;
  slot: integer;
  candidates: TArray<string>;
  candidate: string;
  found: boolean;
  newtrans: Ptranslationtable_t;

  function _dotry_pk3(const pk3name: string): Boolean;
  var
    strm: TDStream;
  begin
    strm := translation_pakfiles.Open(pk3name, TPakLookupMode.Short, nil, '');
    strm.OnBeginBusy := I_BeginDiskBusy;
    Result := (strm.IOResult = 0) and (strm.Size = SizeOf(translationtable_t));
    if Result then
    begin
      newtrans := Z_Malloc(SizeOf(translationtable_t), PU_STATIC, nil);
      strm.Read(newtrans^, SizeOf(translationtable_t));
    end;
    strm.Free;
  end;

  function _dotry_wad(const wadname: string): Boolean;
  var
    lumpname: string;
    lump: integer;
  begin
    lumpname := char8tostring(stringtochar8(wadname));
    lump := W_CheckNumForName(lumpname);
    if lump >= 0 then
      if W_LumpLength(lump) = SizeOf(translationtable_t) then
      begin
        newtrans := Z_Malloc(SizeOf(translationtable_t), PU_STATIC, nil);
        W_ReadLump(lump, newtrans);
        Result := True;
        Exit;
      end;
    Result := False;
  end;

  // The old code passed the nested functions as plain function pointers, which
  // lost the frame of this function: a table in a lump or a PK3 could not be loaded
  function _try_load(const viapk3: boolean): Boolean;
  var
    c: string;
  begin
    for c in candidates do
      if (viapk3 and _dotry_pk3(c)) or (not viapk3 and _dotry_wad(c)) then
      begin
        Result := True;
        Exit;
      end;
    Result := False;
  end;

begin
  slot := translation_names.FindSlot(name, key);
  if slot >= 0 then
  begin
    Result := Ptranslationtable_t(translation_tables[slot]);
    Exit;
  end;

  newtrans := nil;
  candidates := translation_names.LumpCandidates(name);
  found := _try_load(true);
  if not found then
    _try_load(false);

  Result := newtrans;
  if Result <> nil then
  begin
    slot := translation_names.AddSlot(key);
    while translation_tables.Count <= slot do
      translation_tables.Add(nil);
    translation_tables[slot] := Result;
  end;
end;

//==============================================================================
//
// R_InitMobjTranslation
//
//==============================================================================
procedure R_InitMobjTranslation(const mo: Pmobj_t);
begin
  if mo.translationname = '' then
    mo.translationtable := nil
  else
    mo.translationtable := R_GetTranslationTable(mo.translationname);
end;

//==============================================================================
//
// R_SetMobjBloodTranslation
//
//==============================================================================
procedure R_SetMobjBloodTranslation(const mo: Pmobj_t; const blood: integer);
begin
  mo.translationname := TTranslationBlood.NameOf(blood);
  mo.translationtable := R_GetTranslationTable(mo.translationname);
end;

end.
