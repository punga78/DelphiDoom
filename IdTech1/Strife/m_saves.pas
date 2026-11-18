//------------------------------------------------------------------------------
//
//  DelphiStrife is a source port of the game Strife.
//
//  Based on:
//    - Linux Doom by "id Software"
//    - Chocolate Strife by "Simon Howard"
//    - DelphiDoom by "Jim Valavanis"
//
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2005 Simon Howard
//  Copyright (C) 2010 James Haley, Samuel Villarreal
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
// Strife Hub Saving Code
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit m_saves;

interface

//
// File Paths
//
// Strife maintains multiple file paths related to savegames.
//
var
  savepath: string;     // The actual path of the selected saveslot
  savepathtemp: string; // The path of the temporary saveslot (strfsav6.ssg)
  loadpath: string;     // Path used while loading the game

var
  character_name: string; // Name of "character" for saveslot

type
  /// <summary>
  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #185,
  ///   wave 11): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TSaveSlotRoutines = class sealed
  public
    //==============================================================================
    //
    // M_SafeFilePath
    //
    //==============================================================================
    class function M_SafeFilePath(basepath, newcomponent: string): string; static;

    //==============================================================================
    //
    // M_MakeStrifeSaveDir
    //
    //==============================================================================
    class function M_MakeStrifeSaveDir(const slotnum: integer; const extra: string): string; static;

    //==============================================================================
    //
    // M_ToCurr
    //
    //==============================================================================
    class procedure M_ToCurr; static;

    //==============================================================================
    //
    // M_FromCurr
    //
    //==============================================================================
    class procedure M_FromCurr; static;

    //==============================================================================
    //
    // M_ClearSlot
    //
    //==============================================================================
    class procedure M_ClearSlot; static;

    //==============================================================================
    //
    // M_ClearTmp
    //
    //==============================================================================
    class procedure M_ClearTmp; static;

    //==============================================================================
    //
    // M_SaveMoveHereToMap
    //
    //==============================================================================
    class procedure M_SaveMoveHereToMap; static;

    //==============================================================================
    //
    // M_ReadMisObj
    //
    //==============================================================================
    class procedure M_ReadMisObj; static;

    //==============================================================================
    //
    // M_ReadWorldVars
    //
    //==============================================================================
    class procedure M_ReadWorldVars; static;

    //==============================================================================
    //
    // M_SaveMoveMapToHere
    //
    //==============================================================================
    class procedure M_SaveMoveMapToHere; static;

    //==============================================================================
    //
    // M_SaveMisObj
    //
    //==============================================================================
    class procedure M_SaveMisObj(const path: string); static;

    //==============================================================================
    //
    // M_SaveWorldVars
    //
    //==============================================================================
    class procedure M_SaveWorldVars(const path: string); static;

    //==============================================================================
    //
    // M_SaveSaveScreenShot
    //
    //==============================================================================
    class procedure M_SaveSaveScreenShot(const path: string); static;

    //==============================================================================
    //
    // M_CreateSaveDirs
    //
    //==============================================================================
    class procedure M_CreateSaveDirs(const savedir: string); static;

    //==============================================================================
    //
    // M_ClearSlotNum
    //
    //==============================================================================
    class procedure M_ClearSlotNum(const num: integer); static;
  end;


implementation

uses
  d_delphi,
  i_system,
  p_dialog,
  p_saveg,
  m_argv,
  g_game;

type
  /// <summary>
  ///   The routines that only this unit calls, as static methods with the text and the names of the old free routines
  ///   (issue #185, wave 11): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TSaveSlotLocalRoutines = class sealed
  public
    class function M_NormalizeSlashes(const str: string): string; static;
  end;

//==============================================================================
//
// M_ClearSlotNum
//
//==============================================================================
class procedure TSaveSlotRoutines.M_ClearSlotNum(const num: integer);
var
  files: TDSTringList;
  filepath: string;
  i: integer;
  path: string;
begin
  path := M_SafeFilePath(M_SaveFileName(''), M_MakeStrifeSaveDir(num, ''));
  if path = '' then
    I_Error('M_ClearSlotNum(): you fucked up savedir man!');

  files := findfiles(path + '\*');
  if (files = nil) or (files.Count = 0) then
    I_Error('M_ClearTmp(): Couldn''t open dir %s', [path]);

  for i := 0 to files.Count - 1 do
  begin
    if (files.Strings[i] = '.') or (files.Strings[i] = '..') then
      continue;

    // haleyjd: use M_SafeFilePath, not sprintf
    filepath := M_SafeFilePath(path, files.Strings[i]);
    fdelete(filepath);
  end;
  files.Free;
end;

//==============================================================================
// M_ClearTmp
//
// ClearTmp
//
// Clear the temporary save directory
//
//==============================================================================
class procedure TSaveSlotRoutines.M_ClearTmp;
var
  files: TDSTringList;
  filepath: string;
  i: integer;
begin
  if savepathtemp = '' then
    I_Error('M_ClearTmp(): you fucked up savedir man!');

  files := findfiles(savepathtemp + '\*');
  if (files = nil) or (files.Count = 0) then
    I_Error('M_ClearTmp(): Couldn''t open dir %s', [savepathtemp]);

  for i := 0 to files.Count - 1 do
  begin
    if (files.Strings[i] = '.') or (files.Strings[i] = '..') then
      continue;

    // haleyjd: use M_SafeFilePath, not sprintf
    filepath := M_SafeFilePath(savepathtemp, files.Strings[i]);
    fdelete(filepath);
  end;
  files.Free;
end;

//==============================================================================
// M_ClearSlot
//
// ClearSlot
//
// Clear a single save slot folder
//
//==============================================================================
class procedure TSaveSlotRoutines.M_ClearSlot;
var
  files: TDSTringList;
  filepath: string;
  i: integer;
begin
  if savepath = '' then
    I_Error('userdir is fucked up man!');

  files := findfiles(savepath + '\*');
  if (files = nil) or (files.Count = 0) then
    I_Error('M_ClearSlot(): Couldn''t open dir %s', [savepath]);

  for i := 0 to files.Count - 1 do
  begin
    if (files.Strings[i] = '.') or (files.Strings[i] = '..') then
      continue;

    // haleyjd: use M_SafeFilePath, not sprintf
    filepath := M_SafeFilePath(savepath, files.Strings[i]);
    fdelete(filepath);
  end;
  files.Free;
end;

//==============================================================================
// M_FromCurr
//
// FromCurr
//
// Copying files from savepathtemp to savepath
//
//==============================================================================
class procedure TSaveSlotRoutines.M_FromCurr;
var
  files: TDSTringList;
  srcfilename: string;
  dstfilename: string;
  i: integer;
begin
  files := findfiles(savepathtemp + '\*');
  if (files = nil) or (files.Count = 0) then
    I_Error('ClearSlot(): Couldn''t open dir %s', [savepathtemp]);

  for i := 0 to files.Count - 1 do
  begin
    if (files.Strings[i] = '.') or (files.Strings[i] = '..') then
      continue;

    // haleyjd: use M_SafeFilePath, not sprintf
    srcfilename := M_SafeFilePath(savepathtemp, files.Strings[i]);
    dstfilename := M_SafeFilePath(savepath, files.Strings[i]);
    CopyFile2(srcfilename, dstfilename);
  end;
  files.Free;
end;

//==============================================================================
// M_ToCurr
//
// ToCurr
//
// Copying files from savepath to savepathtemp
//
//==============================================================================
class procedure TSaveSlotRoutines.M_ToCurr;
var
  files: TDSTringList;
  srcfilename: string;
  dstfilename: string;
  i: integer;
begin
  M_ClearTmp;
  files := findfiles(savepath + '\*');
  if (files = nil) or (files.Count = 0) then
    I_Error('ToCurr(): Couldn''t open dir %s', [savepath]);

  for i := 0 to files.Count - 1 do
  begin
    if (files.Strings[i] = '.') or (files.Strings[i] = '..') then
      continue;

    // haleyjd: use M_SafeFilePath, not sprintf
    srcfilename := M_SafeFilePath(savepath,     files.Strings[i]);
    dstfilename := M_SafeFilePath(savepathtemp, files.Strings[i]);
    CopyFile2(srcfilename, dstfilename);
  end;
  files.Free;
end;

//==============================================================================
//
// M_SaveMoveMapToHere
//
// Moves a map to the "HERE" save.
//
//==============================================================================
class procedure TSaveSlotRoutines.M_SaveMoveMapToHere;
var
 mapsave: string;
 heresave: string;
begin
  // haleyjd: use M_SafeFilePath, not sprintf
  mapsave := M_SafeFilePath(savepath, itoa(TGameSession.GameMap));
  heresave := M_SafeFilePath(savepath, 'here');

  frename(mapsave, heresave);
end;

//==============================================================================
//
// M_SaveMoveHereToMap
//
// Moves the "HERE" save to a map.
//
//==============================================================================
class procedure TSaveSlotRoutines.M_SaveMoveHereToMap;
var
 mapsave: string;
 heresave: string;
begin
  // haleyjd: use M_SafeFilePath, not sprintf
  mapsave := M_SafeFilePath(savepathtemp, itoa(TGameSession.GameMap));
  heresave := M_SafeFilePath(savepathtemp, 'here');

  frename(mapsave, heresave);
end;

//==============================================================================
//
// M_SaveMisObj
//
// Writes the mission objective into the MIS_OBJ file.
//
//==============================================================================
class procedure TSaveSlotRoutines.M_SaveMisObj(const path: string);
var
 destpath: string;
 l: TDStringList;
begin
  // haleyjd 20110210: use M_SafeFilePath, not sprintf
  destpath := M_SafeFilePath(path, 'mis_obj');
  l := TDStringList.Create;
  l.Text := mission_objective;
  l.SaveToFile(destpath);
  l.Free;
end;

//==============================================================================
//
// M_SaveWorldVars
//
//==============================================================================
class procedure TSaveSlotRoutines.M_SaveWorldVars(const path: string);
begin
  P_ArchiveWorldVariables(M_SafeFilePath(path, 'world_vars'));
end;

//==============================================================================
//
// M_SaveSaveScreenShot
//
//==============================================================================
class procedure TSaveSlotRoutines.M_SaveSaveScreenShot(const path: string);
begin
  P_ArchiveScreenShot(M_SafeFilePath(path, 'sshot'));
end;

//==============================================================================
//
// M_ReadMisObj
//
// Reads the mission objective from the MIS_OBJ file.
//
//==============================================================================
class procedure TSaveSlotRoutines.M_ReadMisObj;
var
  srcpath: string;
  l: TDStringList;
begin
  // haleyjd: use M_SafeFilePath, not sprintf
  srcpath := M_SafeFilePath(savepathtemp, 'mis_obj');
  l := TDStringList.Create;
  l.LoadFromFile(srcpath);
  if l.Count = 0 then
    I_Warning('M_ReadMisObj(): Can not load mission objective'#13#10);
  mission_objective := l.Text;
  l.Free;
end;

//==============================================================================
//
// M_ReadWorldVars
//
//==============================================================================
class procedure TSaveSlotRoutines.M_ReadWorldVars;
begin
  P_UnarchiveWorldVariables(M_SafeFilePath(savepathtemp, 'world_vars'));
end;

//==============================================================================
//
// M_NormalizeSlashes
//
// Remove trailing slashes, translate backslashes to slashes
// The string to normalize is passed and returned in str
//
// killough 11/98: rewritten
//
// [STRIFE] - haleyjd 20110210: Borrowed from Eternity and adapted to respect
// the DIR_SEPARATOR define used by Choco Doom. This routine originated in
// BOOM.
//
//==============================================================================
class function TSaveSlotLocalRoutines.M_NormalizeSlashes(const str: string): string;
var
  i: integer;
  lastsl: boolean;
  len: integer;
begin
  lastsl := true;
  result := '';
  for i := 1 to length(str) do
  begin
    if not (str[i] in ['/', '\']) then
    begin
      result := result + str[i];
      lastsl := false;
    end
    else
    begin
      if not lastsl then
      begin
        result := result + '\';
        lastsl := true;
      end;
    end;
  end;
  len := length(result);
  if len > 0 then
    if result[len] = '\' then
      setlength(result, len - 1);
end;

//==============================================================================
//
// M_SafeFilePath
//
//==============================================================================
class function TSaveSlotRoutines.M_SafeFilePath(basepath, newcomponent: string): string;
begin
  if basepath = '' then
    basepath := '.';

  // Always throw in a slash. M_NormalizeSlashes will remove it in the case
  // that either basepath or newcomponent includes a redundant slash at the
  // end or beginning respectively.
  result := TSaveSlotLocalRoutines.M_NormalizeSlashes(basepath + '\' + newcomponent);
end;

//==============================================================================
//
// M_MakeStrifeSaveDir
//
// haleyjd 20110211: Convenience routine
//
//==============================================================================
class function TSaveSlotRoutines.M_MakeStrifeSaveDir(const slotnum: integer; const extra: string): string;
begin
  sprintf(result, 'strfsav%d.ssg%s', [slotnum, extra]);
end;

//==============================================================================
//
// M_CreateSaveDirs
//
// haleyjd 20110210: Vanilla Strife went tits-up if it didn't have the full set
// of save folders which were created externally by the installer. fraggle says
// that's no good for Choco purposes, and I agree, so this routine will create
// the full set of folders under the configured savegamedir.
//
//==============================================================================
class procedure TSaveSlotRoutines.M_CreateSaveDirs(const savedir: string);
var
  i: integer;
  compositedir: string;
begin
  for i := 0 to 8 do
  begin
    // compose the full path by concatenating with savedir
    compositedir := M_SafeFilePath(savedir, M_MakeStrifeSaveDir(i, ''));

    if not MkDir(compositedir) then
      I_Warning('M_CreateSaveDirs(): Can not create directory %s'#13#10, [compositedir]);
  end;
end;

end.
