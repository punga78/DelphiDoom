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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit deh_base;

interface

uses
  d_delphi,
  d_think,
  m_fixed,
  DelphiDoom.Actions.Intf,
  DelphiDoom.TableExport.Intf,
  DelphiDoom.Engine.Dehacked.Intf;

//==============================================================================
//
// DEH_ConfigureApplier
//
// What reads a patch and applies it to the tables of the game (the class of the
// game, with the parser of Libs\Dehacked): ComposeEngine gives it
//
//==============================================================================
procedure DEH_ConfigureApplier(const AApplier: IEngineDehackedApplier);

//==============================================================================
//
// DEH_ConfigureExport
//
// The writers of the current tables (patch, ACTORDEF, WEAPONDEF, owners of the
// states and CSV): ComposeEngine gives them
//
//==============================================================================
procedure DEH_ConfigureExport(const ADeh: IExportDehWriter; const ACsv: IExportCsvWriter;
  const AActorDef: IExportActorDefWriter; const AWeaponDef: IExportWeaponDefWriter;
  const AOwners: IExportStateOwnersWriter);

//==============================================================================
//
// DEH_CurrentSettings
//
//==============================================================================
function DEH_CurrentSettings: TDStringList;

//==============================================================================
//
// DEH_ActorDeclaration
//
//==============================================================================
function DEH_ActorDeclaration(const index: integer): string;
//==============================================================================
//
// DEH_ParseText
//
//==============================================================================
procedure DEH_ParseText(const deh_tx: string);

//==============================================================================
//
// DEH_ParseLumpName
//
//==============================================================================
function DEH_ParseLumpName(const lumpname: string): boolean;

//==============================================================================
//
// DEH_ParseLumpNames
//
//==============================================================================
function DEH_ParseLumpNames(const lumpname: string): boolean;

//==============================================================================
//
// DEH_ParseLumpNum
//
//==============================================================================
procedure DEH_ParseLumpNum(const lump: integer);

//==============================================================================
//
// DEH_ParseFile
//
//==============================================================================
procedure DEH_ParseFile(const filename: string);

//==============================================================================
//
// DEH_StringToCString
//
//==============================================================================

//==============================================================================
//
// DEH_CStringToString
//
//==============================================================================
function DEH_CStringToString(const s: string): string;

//==============================================================================
//
// DEH_StringValue
//
//==============================================================================
function DEH_StringValue(const s: string): string;

//==============================================================================
//
// DEH_PrintCurrentSettings
//
//==============================================================================
procedure DEH_PrintCurrentSettings;

//==============================================================================
//
// DEH_SaveCurrentSettings
//
//==============================================================================
procedure DEH_SaveCurrentSettings(const fname: string);

//==============================================================================
//
// DEH_CurrentActordef
//
//==============================================================================
function DEH_CurrentActordef: string;

//==============================================================================
//
// DEH_PrintActordef
//
//==============================================================================
procedure DEH_PrintActordef;

//==============================================================================
//
// DEH_SaveActordef
//
//==============================================================================
procedure DEH_SaveActordef(const fname: string);

//==============================================================================
//
// DEH_CurrentWeapondef
//
//==============================================================================
function DEH_CurrentWeapondef: string;

//==============================================================================
//
// DEH_PrintWeapondef
//
//==============================================================================
procedure DEH_PrintWeapondef;

//==============================================================================
//
// DEH_SaveWeapondef
//
//==============================================================================
procedure DEH_SaveWeapondef(const fname: string);

//==============================================================================
//
// DEH_CurrentStateOwners
//
//==============================================================================
function DEH_CurrentStateOwners: string;

//==============================================================================
//
// DEH_PrintStateOwners
//
//==============================================================================
procedure DEH_PrintStateOwners;

//==============================================================================
//
// DEH_SaveStateOwners
//
//==============================================================================
procedure DEH_SaveStateOwners(const fname: string);

//==============================================================================
//
// DEH_PrintActions
//
//==============================================================================
procedure DEH_PrintActions;

//==============================================================================
//
// DEH_MobjInfoCSV
//
//==============================================================================
function DEH_MobjInfoCSV: TDStringList;

//==============================================================================
//
// DEH_SaveMobjInfoCSV
//
//==============================================================================
procedure DEH_SaveMobjInfoCSV(const fname: string);

//==============================================================================
//
// DEH_StatesCSV
//
//==============================================================================
function DEH_StatesCSV: TDStringList;

//==============================================================================
//
// DEH_SaveStatesCSV
//
//==============================================================================
procedure DEH_SaveStatesCSV(const fname: string);

//==============================================================================
//
// DEH_SpritesCSV
//
//==============================================================================
function DEH_SpritesCSV: TDStringList;

//==============================================================================
//
// DEH_SaveSpritesCSV
//
//==============================================================================
procedure DEH_SaveSpritesCSV(const fname: string);

//==============================================================================
//
// DEH_ActionName
//
//==============================================================================
function DEH_ActionName(action: actionf_t): string;

//==============================================================================
//
// DEH_ConfigureActions
//
//==============================================================================
procedure DEH_ConfigureActions(const ARegistry: IActionRegistry);

//==============================================================================
//
// DEH_AddNullAction
//
//==============================================================================
procedure DEH_AddNullAction;

//==============================================================================
//
// DEH_ActionCount
//
//==============================================================================
function DEH_ActionCount: integer;

//==============================================================================
//
// DEH_ActionProc
//
//==============================================================================
function DEH_ActionProc(const index: integer): actionf_p1;

//==============================================================================
//
// DEH_ActionDeclaration
//
//==============================================================================
function DEH_ActionDeclaration(const index: integer): string;

//==============================================================================
//
// DEH_ActionEntry
//
//==============================================================================
function DEH_ActionEntry(const action: actionf_t; var entry: TActionEntry): boolean;

//==============================================================================
//
// DEH_SearchActionFromHash
//
//==============================================================================
function DEH_SearchActionFromHash(const act: string): integer;

//==============================================================================
//
// DEH_FindActionByName
//
//==============================================================================
function DEH_FindActionByName(const aname: string): integer;

//==============================================================================
//
// DEH_AmmoType
//
//==============================================================================
function DEH_AmmoType(const str: string): integer;

//==============================================================================
//
// DEH_WeaponType
//
//==============================================================================
function DEH_WeaponType(const str: string): integer;

//==============================================================================
//
// DEH_AddAction
//
//==============================================================================
procedure DEH_AddAction(const acp1: actionf_p1; const desc: string); overload;

//==============================================================================
//
// DEH_AddAction
//
//==============================================================================
procedure DEH_AddAction(const acp1: actionf_p1; const desc: string; const def_args: array of integer); overload;

{$IFDEF  HEXEN}

//==============================================================================
//
// DEH_PlayerClass
//
//==============================================================================
function DEH_PlayerClass(const str: string): integer;
{$ENDIF}
implementation

uses
  TypInfo,
  deh_main,
  doomdef,
  {$IFDEF DOOM_OR_STRIFE}
  d_items,
  {$ENDIF}
  i_system,
  info,
  info_h,
  m_argv,
  sc_states,
  w_folders,
  w_pak,
  w_wad,
  DelphiDoom.Actions.Names;

var
  // given by ComposeEngine (DEH_ConfigureActions)
  dehactions: IActionRegistry = nil;

//==============================================================================
//
// DEH_ActionRegistry
//
//==============================================================================
function DEH_ActionRegistry: IActionRegistry;
begin
  if dehactions = nil then
    I_Error('DEH_ActionRegistry(): the registry of the actions is not configured');
  Result := dehactions;
end;

//==============================================================================
//
// DEH_ConfigureActions
//
//==============================================================================
procedure DEH_ConfigureActions(const ARegistry: IActionRegistry);
begin
  dehactions := ARegistry;
end;

var
  // given by ComposeEngine (DEH_ConfigureApplier)
  dehapplier: IEngineDehackedApplier = nil;

//==============================================================================
//
// DEH_ConfigureApplier
//
//==============================================================================
procedure DEH_ConfigureApplier(const AApplier: IEngineDehackedApplier);
begin
  dehapplier := AApplier;
end;

var
  GDehWriter: IExportDehWriter;
  GCsvWriter: IExportCsvWriter;
  GActorDefWriter: IExportActorDefWriter;
  GWeaponDefWriter: IExportWeaponDefWriter;
  GOwnersWriter: IExportStateOwnersWriter;

//==============================================================================
//
// DEH_ConfigureExport
//
//==============================================================================
procedure DEH_ConfigureExport(const ADeh: IExportDehWriter; const ACsv: IExportCsvWriter;
  const AActorDef: IExportActorDefWriter; const AWeaponDef: IExportWeaponDefWriter;
  const AOwners: IExportStateOwnersWriter);
begin
  GDehWriter := ADeh;
  GCsvWriter := ACsv;
  GActorDefWriter := AActorDef;
  GWeaponDefWriter := AWeaponDef;
  GOwnersWriter := AOwners;
end;

//==============================================================================
//
// LinesToList
//
//==============================================================================
function LinesToList(const ALines: TArray<string>): TDStringList;
var
  i: integer;
begin
  result := TDStringList.Create;
  for i := 0 to Length(ALines) - 1 do
    result.Add(ALines[i]);
end;

//==============================================================================
//
// ListToLines
//
//==============================================================================
function ListToLines(const AList: TDStringList): TArray<string>;
var
  i: integer;
begin
  SetLength(result, AList.Count);
  for i := 0 to AList.Count - 1 do
    result[i] := AList.Strings[i];
end;

//==============================================================================
//
// DEH_ApplyList
// The patch goes to the class of the game (it was DEH_Parse of deh_main)
//
//==============================================================================
procedure DEH_ApplyList(const s: TDStringList);
begin
  if dehapplier = nil then
    I_Error('DEH_Parse(): the DEHACKED parser is not configured (ComposeEngine was not called)');
  dehapplier.Apply(ListToLines(s));
end;

//==============================================================================
//
// DEH_CurrentSettings
//
//==============================================================================
function DEH_CurrentSettings: TDStringList;
begin
  if not Assigned(GDehWriter) then
    I_Error('DEH_CurrentSettings(): the export is not configured (ComposeEngine was not called)');
  DEH_Init;
  result := LinesToList(GDehWriter.Write);
end;

//==============================================================================
//
// DEH_ActorDeclaration
//
//==============================================================================
function DEH_ActorDeclaration(const index: integer): string;
begin
  if not Assigned(GActorDefWriter) then
    I_Error('DEH_ActorDeclaration(): the export is not configured (ComposeEngine was not called)');
  result := GActorDefWriter.Write(index);
end;

//==============================================================================
//
// DEH_ParseText
//
//==============================================================================
procedure DEH_ParseText(const deh_tx: string);
var
  s: TDStringList;
begin
  s := TDStringList.Create;
  try
    s.Text := deh_tx;
    DEH_ApplyList(s);
  finally
    s.Free;
  end;
end;

//==============================================================================
//
// DEH_ParseLumpName
//
//==============================================================================
function DEH_ParseLumpName(const lumpname: string): boolean;
var
  lump: integer;
begin
  lump := W_CheckNumForName(lumpname);
  if lump >= 0 then
  begin
    DEH_ParseLumpNum(lump);
    result := true;
  end
  else
    result := false;
end;

//==============================================================================
//
// DEH_ParseLumpNames
//
//==============================================================================
function DEH_ParseLumpNames(const lumpname: string): boolean;
var
  i: integer;
  cnt: integer;
  uName: string;
begin
  cnt := 0;
  uName := strupper(lumpname);
  for i := 0 to W_NumLumps - 1 do
    if char8tostring(W_GetNameForNum(i)) = uName then
    begin
      DEH_ParseText(W_TextLumpNum(i));
      inc(cnt);
    end;

  cnt := cnt + PAK_StringIterator(lumpname, DEH_ParseText);
  cnt := cnt + PAK_StringIterator(lumpname + '.DEH', DEH_ParseText);
  cnt := cnt + PAK_StringIterator(lumpname + '.BEX', DEH_ParseText);

  result := cnt > 0;
end;

//==============================================================================
//
// DEH_ParseLumpNum
//
//==============================================================================
procedure DEH_ParseLumpNum(const lump: integer);
begin
  if lump < 0 then
    exit;

  DEH_ParseText(W_TextLumpNum(lump));
end;

//==============================================================================
//
// DEH_ParseFile
//
//==============================================================================
procedure DEH_ParseFile(const filename: string);
var
  fname: string;
  fnames: TDStringList;
  s: TDStringList;
  i: integer;
  done: boolean;
  strm: TPakStream;
begin
  if filename = '' then
  begin
    I_Warning('DEH_ParseFile(): Please specify the dehacked file to parse'#13#10);
    exit;
  end;

  fnames := TDStringList.Create;
  s := TDStringList.Create;
  try
    if CharPos('.', filename) = 0 then
    begin
      fnames.Add('%s.%s', [filename, 'deh']);
      fnames.Add('%s.%s', [filename, 'bex']);
    end
    else
      fnames.Add(filename);

    for i := fnames.Count - 1 downto 0 do
      if M_SaveFileName(fnames[i]) <> fnames[i] then
        fnames.Add(M_SaveFileName(fnames[i]));

    fname := '';
    done := false;
    for i := 0 to fnames.Count - 1 do
    begin
      strm := TPakStream.Create(fnames[i], pm_short, '', FOLDER_DEHACKED);
      strm.OnBeginBusy := I_BeginDiskBusy;
      if strm.IOResult = 0 then
        done := s.LoadFromStream(strm) and (strm.IOResult = 0);
      strm.Free;
      if done then
      begin
        fname := fnames[i];
        break;
      end;
    end;

    if not done then
    begin
      I_Warning('DEH_ParseFile(): %s not found'#13#10, [filename]);
      exit;
    end;

    printf(' parsing file %s'#13#10, [fname]);
    DEH_ApplyList(s);

  finally
    s.Free;
    fnames.Free;
  end;
end;

//==============================================================================
//
// DEH_CStringToString
//
//==============================================================================
function DEH_CStringToString(const s: string): string;
var
  i, len: integer;
begin
  result := '';
  if s = '' then
  begin
    exit;
  end;

  result := s[1];

  len := Length(s);
  for i := 2 to len do
  begin
    if s[i] = 'N' then
    begin
      if (Length(result) > 0) and (result[Length(result)] = '\') then
      begin
        result[Length(result)] := #13;
        result := result + #10
      end
      else
        result := result + 'N'
    end
    else if s[i] = 'R' then
    begin
      if (Length(result) > 0) and (result[Length(result)] = '\') then
        SetLength(result, Length(result) - 1)
      else
        result := result + 'R';
    end
    else if s[i] = #10 then
    begin
      if (Length(result) > 0) and (result[Length(result)] <> #13) then
        result := result + #13#10
      else
        result := result + #10;
    end
    else
      result := result + s[i];
  end;
end;

//==============================================================================
//
// DEH_StringValue
//
//==============================================================================
function DEH_StringValue(const s: string): string;
var
  i: integer;
begin
  result := '';
  for i := 1 to Length(s) do
  begin
    if toupper(s[i]) in ['A'..'Z', '1'..'9', '0'] then
      result := result + toupper(s[i]);
  end;
end;

//==============================================================================
//
// DEH_PrintCurrentSettings
//
//==============================================================================
procedure DEH_PrintCurrentSettings;
var
  s: TDSTringList;
  i: integer;
begin
  s := DEH_CurrentSettings;
  try
    for i := 0 to s.Count - 1 do
      printf('%s'#13#10, [s[i]]);
  finally
    s.Free;
  end;
end;

//==============================================================================
//
// DEH_SaveCurrentSettings
//
//==============================================================================
procedure DEH_SaveCurrentSettings(const fname: string);
var
  s: TDSTringList;
  fname1: string;
begin
  if fname = '' then
  begin
    printf('Please specify the filename to save current DEHACKED settings'#13#10);
    exit;
  end;

  if CharPos('.', fname) = 0 then
    fname1 := fname + '.bex'
  else
    fname1 := fname;

  fname1 := M_SaveFileName(fname1);

  s := DEH_CurrentSettings;
  try
    s.SaveToFile(fname1);
    printf('DEHACKED settings saved to %s'#13#10, [fname1]);
  finally
    s.Free;
  end;
end;

//==============================================================================
//
// DEH_CurrentActordef
//
//==============================================================================
function DEH_CurrentActordef: string;
begin
  if not Assigned(GActorDefWriter) then
    I_Error('DEH_CurrentActordef(): the export is not configured (ComposeEngine was not called)');
  result := GActorDefWriter.WriteAll;
end;

//==============================================================================
//
// DEH_PrintActordef
//
//==============================================================================
procedure DEH_PrintActordef;
var
  s: TDSTringList;
  i: integer;
begin
  s := TDSTringList.Create;
  try
    s.Text := DEH_CurrentActordef;
    for i := 0 to s.Count - 1 do
      printf('%s'#13#10, [s[i]]);
  finally
    s.Free;
  end;
end;

//==============================================================================
//
// DEH_SaveActordef
//
//==============================================================================
procedure DEH_SaveActordef(const fname: string);
var
  s: TDSTringList;
  fname1: string;
begin
  if fname = '' then
  begin
    printf('Please specify the filename to save current ACTORDEF settings'#13#10);
    exit;
  end;

  if CharPos('.', fname) = 0 then
    fname1 := fname + '.txt'
  else
    fname1 := fname;

  fname1 := M_SaveFileName(fname1);

  s := TDSTringList.Create;
  try
    s.Text := DEH_CurrentActordef;
    s.SaveToFile(fname1);
    printf('ACTORDEF settings saved to %s'#13#10, [fname1]);
  finally
    s.Free;
  end;
end;

//==============================================================================
//
// DEH_CurrentWeapondef
//
//==============================================================================
function DEH_CurrentWeapondef: string;
begin
  if not Assigned(GWeaponDefWriter) then
    I_Error('DEH_CurrentWeapondef(): the export is not configured (ComposeEngine was not called)');
  result := GWeaponDefWriter.WriteAll;
end;

//==============================================================================
//
// DEH_PrintWeapondef
//
//==============================================================================
procedure DEH_PrintWeapondef;
var
  s: TDSTringList;
  i: integer;
begin
  s := TDSTringList.Create;
  try
    s.Text := DEH_CurrentWeapondef;
    for i := 0 to s.Count - 1 do
      printf('%s'#13#10, [s[i]]);
  finally
    s.Free;
  end;
end;

//==============================================================================
//
// DEH_SaveWeapondef
//
//==============================================================================
procedure DEH_SaveWeapondef(const fname: string);
var
  s: TDSTringList;
  fname1: string;
begin
  if fname = '' then
  begin
    printf('Please specify the filename to save current WEAPONDEF settings'#13#10);
    exit;
  end;

  if CharPos('.', fname) = 0 then
    fname1 := fname + '.txt'
  else
    fname1 := fname;

  fname1 := M_SaveFileName(fname1);

  s := TDSTringList.Create;
  try
    s.Text := DEH_CurrentWeapondef;
    s.SaveToFile(fname1);
    printf('WEAPONDEF settings saved to %s'#13#10, [fname1]);
  finally
    s.Free;
  end;
end;

//==============================================================================
//
// DEH_CurrentStateOwners
//
//==============================================================================
function DEH_CurrentStateOwners: string;
begin
  if not Assigned(GOwnersWriter) then
    I_Error('DEH_CurrentStateOwners(): the export is not configured (ComposeEngine was not called)');
  result := GOwnersWriter.Write;
end;

//==============================================================================
//
// DEH_PrintStateOwners
//
//==============================================================================
procedure DEH_PrintStateOwners;
var
  s: TDSTringList;
  i: integer;
begin
  s := TDSTringList.Create;
  try
    s.Text := DEH_CurrentStateOwners;
    for i := 0 to s.Count - 1 do
      printf('%s'#13#10, [s[i]]);
  finally
    s.Free;
  end;
end;

//==============================================================================
//
// DEH_SaveStateOwners
//
//==============================================================================
procedure DEH_SaveStateOwners(const fname: string);
var
  s: TDSTringList;
  fname1: string;
begin
  if fname = '' then
  begin
    printf('Please specify the filename to save current state owners'#13#10);
    exit;
  end;

  if CharPos('.', fname) = 0 then
    fname1 := fname + '.txt'
  else
    fname1 := fname;

  fname1 := M_SaveFileName(fname1);

  s := TDSTringList.Create;
  try
    s.Text := DEH_CurrentStateOwners;
    s.SaveToFile(fname1);
    printf('State owners saved to %s'#13#10, [fname1]);
  finally
    s.Free;
  end;
end;

//==============================================================================
//
// DEH_PrintActions
//
//==============================================================================
procedure DEH_PrintActions;
var
  i: integer;
begin
  for i := 0 to DEH_ActionCount - 1 do
    printf('A_%s'#13#10, [DEH_ActionRegistry.Entry(i).Name]);
end;

//==============================================================================
//
// DEH_MobjInfoCSV
//
//==============================================================================
function DEH_MobjInfoCSV: TDStringList;
var
  cs: TDStringList;
begin
  DEH_Init;
  cs := DEH_CurrentSettings;
  try
    result := LinesToList(GCsvWriter.MobjInfo(ListToLines(cs)));
  finally
    cs.Free;
  end;
end;

//==============================================================================
//
// DEH_SaveMobjInfoCSV
//
//==============================================================================
procedure DEH_SaveMobjInfoCSV(const fname: string);
var
  s: TDSTringList;
  fname1: string;
begin
  if fname = '' then
  begin
    printf('Please specify the filename to save current MobjInfo'#13#10);
    exit;
  end;

  if CharPos('.', fname) = 0 then
    fname1 := fname + '.csv'
  else
    fname1 := fname;

  fname1 := M_SaveFileName(fname1);

  s := DEH_MobjInfoCSV;
  try
    s.SaveToFile(fname1);
    printf('MobjInfo saved to %s'#13#10, [fname1]);
  finally
    s.Free;
  end;
end;

//==============================================================================
//
// DEH_StatesCSV
//
//==============================================================================
function DEH_StatesCSV: TDStringList;
var
  cs: TDStringList;
begin
  DEH_Init;
  cs := DEH_CurrentSettings;
  try
    result := LinesToList(GCsvWriter.States(ListToLines(cs)));
  finally
    cs.Free;
  end;
end;

//==============================================================================
//
// DEH_SaveStatesCSV
//
//==============================================================================
procedure DEH_SaveStatesCSV(const fname: string);
var
  s: TDSTringList;
  fname1: string;
begin
  if fname = '' then
  begin
    printf('Please specify the filename to save current States'#13#10);
    exit;
  end;

  if CharPos('.', fname) = 0 then
    fname1 := fname + '.csv'
  else
    fname1 := fname;

  fname1 := M_SaveFileName(fname1);

  s := DEH_StatesCSV;
  try
    s.SaveToFile(fname1);
    printf('States saved to %s'#13#10, [fname1]);
  finally
    s.Free;
  end;
end;

//==============================================================================
//
// DEH_SpritesCSV
//
//==============================================================================
function DEH_SpritesCSV: TDStringList;
begin
  if not Assigned(GCsvWriter) then
    I_Error('DEH_SpritesCSV(): the export is not configured (ComposeEngine was not called)');
  result := LinesToList(GCsvWriter.Sprites);
end;

//==============================================================================
//
// DEH_SaveSpritesCSV
//
//==============================================================================
procedure DEH_SaveSpritesCSV(const fname: string);
var
  s: TDSTringList;
  fname1: string;
begin
  if fname = '' then
  begin
    printf('Please specify the filename to save current Sprites'#13#10);
    exit;
  end;

  if CharPos('.', fname) = 0 then
    fname1 := fname + '.csv'
  else
    fname1 := fname;

  fname1 := M_SaveFileName(fname1);

  s := DEH_SpritesCSV;
  try
    s.SaveToFile(fname1);
    printf('Sprites saved to %s'#13#10, [fname1]);
  finally
    s.Free;
  end;
end;

//==============================================================================
//
// DEH_ActionName
//
//==============================================================================
function DEH_ActionName(action: actionf_t): string;
begin
  result := DEH_ActionRegistry.NameOfHandler(@action.acp1);
end;

//==============================================================================
//
// DEH_AddNullAction
//
//==============================================================================
procedure DEH_AddNullAction;
begin
  DEH_ActionRegistry.Register('NULL', nil, [], '');
end;

//==============================================================================
//
// DEH_ActionCount
//
//==============================================================================
function DEH_ActionCount: integer;
begin
  result := DEH_ActionRegistry.Count;
end;

//==============================================================================
//
// DEH_ActionProc
//
//==============================================================================
function DEH_ActionProc(const index: integer): actionf_p1;
begin
  result := actionf_p1(DEH_ActionRegistry.Entry(index).Handler);
end;

//==============================================================================
//
// DEH_ActionDeclaration
//
//==============================================================================
function DEH_ActionDeclaration(const index: integer): string;
begin
  result := DEH_ActionRegistry.Entry(index).Declaration;
end;

//==============================================================================
//
// DEH_ActionEntry
//
//==============================================================================
function DEH_ActionEntry(const action: actionf_t; var entry: TActionEntry): boolean;
var
  idx: integer;
begin
  idx := DEH_ActionRegistry.IndexOfHandler(@action.acp1);
  result := idx >= 0;
  if result then
    entry := DEH_ActionRegistry.Entry(idx);
end;

//==============================================================================
//
// DEH_SearchActionFromHash
//
//==============================================================================
function DEH_SearchActionFromHash(const act: string): integer;
begin
  result := DEH_ActionRegistry.IndexOfName(act);
end;

//==============================================================================
//
// DEH_FindActionByName
//
//==============================================================================
function DEH_FindActionByName(const aname: string): integer;
begin
  result := DEH_ActionRegistry.IndexOfName(aname);
end;

//==============================================================================
//
// DEH_AmmoType
//
//==============================================================================
function DEH_AmmoType(const str: string): integer;
var
  stmp: string;
begin
  if ammotype_tokens = nil then
  begin
    result := atoi(str, -1);
    exit;
  end;

  if StrIsInteger(str) then
  begin
    result := atoi(str, -1);
    exit;
  end;

  stmp := strupper(str);
  {$IFNDEF HEXEN}
  if not Pos1('AM_', stmp) then
    stmp := stmp + 'AM_';
  {$ENDIF}

  result := ammotype_tokens.IndexOf(stmp);
end;

//==============================================================================
//
// DEH_WeaponType
//
//==============================================================================
function DEH_WeaponType(const str: string): integer;
var
  stmp: string;
begin
  if weapontype_tokens = nil then
  begin
    result := atoi(str, -1);
    exit;
  end;

  if StrIsInteger(str) then
  begin
    result := atoi(str, -1);
    exit;
  end;

  stmp := strupper(str);
  if not Pos1('WP_', stmp) then
    stmp := stmp + 'WP_';

  result := weapontype_tokens.IndexOf(stmp);
end;

//==============================================================================
//
// DEH_AddAction
//
//==============================================================================
procedure DEH_AddAction(const acp1: actionf_p1; const desc: string);
begin
  try
    DEH_ActionRegistry.Register(TActionNames.FromDeclaration(desc), @acp1, [], desc);
  except
    on E: EActionRegistryException do
      I_Error('DEH_AddAction(): %s', [E.Message]);
  end;
end;

//==============================================================================
//
// DEH_AddAction
//
//==============================================================================
procedure DEH_AddAction(const acp1: actionf_p1; const desc: string; const def_args: array of integer); overload;
begin
  try
    DEH_ActionRegistry.Register(TActionNames.FromDeclaration(desc), @acp1, def_args, desc);
  except
    on E: EActionRegistryException do
      I_Error('DEH_AddAction(): %s', [E.Message]);
  end;
end;

{$IFDEF HEXEN}

//==============================================================================
//
// DEH_PlayerClass
//
//==============================================================================
function DEH_PlayerClass(const str: string): integer;
var
  stmp: string;
begin
  if playerclass_tokens = nil then
  begin
    result := atoi(str, -1);
    exit;
  end;

  if StrIsInteger(str) then
  begin
    result := atoi(str, -1);
    exit;
  end;

  stmp := strupper(str);
  if not Pos1('PCLASS_', stmp) then
    stmp := stmp + 'PCLASS_';

  result := playerclass_tokens.IndexOf(stmp);
end;
{$ENDIF}

end.

