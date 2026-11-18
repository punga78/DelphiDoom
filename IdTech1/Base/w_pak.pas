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

{
  The API of the PAK file system for the procedural modules of the engine (TPakStream and the
  PAK_* functions). The file system is TPakFileSystem (DelphiDoom.Pak.FileSystem), with the
  index and the rules of the paths of Framework\Wad; the composition root gives it with PAK_Configure.
  The classes of the engine receive IPakFileSystem from their constructor instead.
}

unit w_pak;

interface

uses
  d_delphi,
  DelphiDoom.Wad.Pak.Types,
  DelphiDoom.Pak.Intf,
  DelphiDoom.Pak.Stream;

type
  pakmode_t = TPakLookupMode;

const
  pm_full = TPakLookupMode.Full;            // Full pathname match
  pm_short = TPakLookupMode.Short;          // Filename only match
  pm_prefered = TPakLookupMode.Preferred;   // Filename match but specified prefered directories
  pm_directory = TPakLookupMode.Directory;  // A dicectory will be provided

  s_TEX_PATH = PAK_TEXTURE_PATH;

type
  /// <summary>A file of the PAK file system given by PAK_Configure (see TPakFileStream)</summary>
  TPakStream = class(TPakFileStream)
  public
    constructor Create(const FileName: string; amode: pakmode_t; const aprefdirs: string = ''; const adir: string = ''); overload;
    constructor Create(const FileName: string; amode: pakmode_t; const apreflist: TDStringList; const adir: string = ''); overload;
    constructor Create(const idx: integer); overload;
  end;

type
  stringparmproc_t = procedure(const atext: string);

//==============================================================================
//
// PAK_GetGlobalHash
//
//==============================================================================

type
  /// <summary>
  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #185,
  ///   wave 11): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TPakRoutines = class sealed
  public
    //==============================================================================
    //
    // PAK_GetDirectoryListFromString
    //
    //==============================================================================
    class function PAK_GetDirectoryListFromString(const aprefdirs: string): TDStringList; static;

    //==============================================================================
    //
    // PAK_Configure
    // Gives the unit the PAK file system. The composition root calls it
    // before PAK_InitFileSystem
    //
    //==============================================================================
    class procedure PAK_Configure(const AFiles: IPakFileSystem; const AContainers: IPakContainers); static;

    //==============================================================================
    //
    // PAK_InitFileSystem
    //
    //==============================================================================
    class procedure PAK_InitFileSystem; static;

    //==============================================================================
    //
    // PAK_ShutDown
    //
    //==============================================================================
    class procedure PAK_ShutDown; static;

    //==============================================================================
    //
    // PAK_AddFile
    //
    //==============================================================================
    class function PAK_AddFile(const FileName: string): boolean; static;

    //==============================================================================
    //
    // PAK_StringIterator
    //
    //==============================================================================
    class function PAK_StringIterator(const filename: string; proc: stringparmproc_t): integer; static;

    //==============================================================================
    //
    // PAK_FileNameIterator
    //
    //==============================================================================
    class function PAK_FileNameIterator(proc: stringparmproc_t): integer; static;

    //==============================================================================
    //
    // PAK_ReadFileAsString
    //
    //==============================================================================
    class function PAK_ReadFileAsString(const filename: string): string; static;

    //==============================================================================
    //
    // PAK_ReadAllFilesAsString
    //
    //==============================================================================
    class function PAK_ReadAllFilesAsString(const filename: string): string; static;

    //==============================================================================
    //
    // PAK_LoadPendingPaks
    //
    //==============================================================================
    class procedure PAK_LoadPendingPaks; static;
  end;


implementation

uses
  i_system,
  DelphiDoom.Wad.Pak.Names;

var
  // the PAK file system of the engine, given by the composition root (PAK_Configure)
  pakfilesystem: IPakFileSystem = nil;
  pakcontainers: IPakContainers = nil;

type
  /// <summary>
  ///   The routines that only this unit calls, as static methods with the text and the names of the old free routines
  ///   (issue #185, wave 11): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TPakLocalRoutines = class sealed
  public
    class function PAK_Files: IPakFileSystem; static;
    class function PAK_Containers: IPakContainers; static;
    class function PAK_DirectoryArray(const alist: TDStringList): TArray<string>; static;
  end;

//==============================================================================
//
// PAK_Files
//
//==============================================================================
class function TPakLocalRoutines.PAK_Files: IPakFileSystem;
begin
  if pakfilesystem = nil then
    I_Error('PAK_Files(): the PAK file system was not configured (PAK_Configure)');
  result := pakfilesystem;
end;

//==============================================================================
//
// PAK_Containers
//
//==============================================================================
class function TPakLocalRoutines.PAK_Containers: IPakContainers;
begin
  if pakcontainers = nil then
    I_Error('PAK_Containers(): the PAK file system was not configured (PAK_Configure)');
  result := pakcontainers;
end;

//==============================================================================
//
// PAK_DirectoryArray
//
//==============================================================================
class function TPakLocalRoutines.PAK_DirectoryArray(const alist: TDStringList): TArray<string>;
var
  i: integer;
begin
  result := nil;
  if alist = nil then
    exit;
  SetLength(result, alist.Count);
  for i := 0 to alist.Count - 1 do
    result[i] := alist[i];
end;

//==============================================================================
//
// PAK_GetDirectoryListFromString
//
//==============================================================================
class function TPakRoutines.PAK_GetDirectoryListFromString(const aprefdirs: string): TDStringList;
var
  dir: string;
begin
  result := TDStringList.Create;
  for dir in TPakNames.DirectoryList(aprefdirs) do
    result.Add(dir);
end;

//==============================================================================
//
// TPakStream.Create
//
//==============================================================================
constructor TPakStream.Create(const FileName: string; amode: pakmode_t; const apreflist: TDStringList; const adir: string = '');
begin
  inherited Create(TPakLocalRoutines.PAK_Files, FileName, amode, TPakLocalRoutines.PAK_DirectoryArray(apreflist), adir);
end;

//==============================================================================
//
// TPakStream.Create
//
//==============================================================================
constructor TPakStream.Create(const FileName: string; amode: pakmode_t; const aprefdirs: string = ''; const adir: string = '');
begin
  inherited Create(TPakLocalRoutines.PAK_Files, FileName, amode, TPakNames.DirectoryList(aprefdirs), adir);
end;

//==============================================================================
//
// TPakStream.Create
//
//==============================================================================
constructor TPakStream.Create(const idx: integer);
begin
  inherited CreateEntry(TPakLocalRoutines.PAK_Files, idx);
end;

//==============================================================================
//
// PAK_Configure
//
//==============================================================================
class procedure TPakRoutines.PAK_Configure(const AFiles: IPakFileSystem; const AContainers: IPakContainers);
begin
  pakfilesystem := AFiles;
  pakcontainers := AContainers;
end;

//==============================================================================
//
// PAK_InitFileSystem
//
//==============================================================================
class procedure TPakRoutines.PAK_InitFileSystem;
begin
  TPakLocalRoutines.PAK_Containers.Initialize;
end;

//==============================================================================
//
// PAK_ShutDown
//
//==============================================================================
class procedure TPakRoutines.PAK_ShutDown;
begin
  TPakLocalRoutines.PAK_Containers.ShutDown;
end;

//==============================================================================
//
// PAK_LoadPendingPaks
//
//==============================================================================
class procedure TPakRoutines.PAK_LoadPendingPaks;
begin
  TPakLocalRoutines.PAK_Containers.LoadPending;
end;

//==============================================================================
//
// PAK_AddFile
//
//==============================================================================
class function TPakRoutines.PAK_AddFile(const FileName: string): boolean;
begin
  result := TPakLocalRoutines.PAK_Containers.AddFile(FileName);
end;

//==============================================================================
//
// PAK_StringIterator
//
//==============================================================================
class function TPakRoutines.PAK_StringIterator(const filename: string; proc: stringparmproc_t): integer;
var
  text: string;
begin
  result := 0;
  for text in TPakLocalRoutines.PAK_Files.Texts(filename) do
  begin
    proc(text);
    inc(result);
  end;
end;

//==============================================================================
//
// PAK_FileNameIterator
//
//==============================================================================
class function TPakRoutines.PAK_FileNameIterator(proc: stringparmproc_t): integer;
var
  i: integer;
  files: IPakFileSystem;
begin
  files := TPakLocalRoutines.PAK_Files;
  result := files.EntryCount;
  for i := 0 to result - 1 do
    proc(files.EntryName(i));
end;

//==============================================================================
//
// PAK_ReadFileAsString
//
//==============================================================================
class function TPakRoutines.PAK_ReadFileAsString(const filename: string): string;
begin
  result := TPakLocalRoutines.PAK_Files.ReadText(filename);
end;

//==============================================================================
//
// PAK_ReadAllFilesAsString
//
//==============================================================================
class function TPakRoutines.PAK_ReadAllFilesAsString(const filename: string): string;
begin
  result := TPakLocalRoutines.PAK_Files.ReadAllTexts(filename);
end;

end.
