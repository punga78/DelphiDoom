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
  index and the rules of the paths of Libs\Wad; the composition root gives it with PAK_Configure.
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

//==============================================================================
//
// PAK_GetDirectoryListFromString
//
//==============================================================================
function PAK_GetDirectoryListFromString(const aprefdirs: string): TDStringList;

type
  /// <summary>A file of the PAK file system given by PAK_Configure (see TPakFileStream)</summary>
  TPakStream = class(TPakFileStream)
  public
    constructor Create(const FileName: string; amode: pakmode_t; const aprefdirs: string = ''; const adir: string = ''); overload;
    constructor Create(const FileName: string; amode: pakmode_t; const apreflist: TDStringList; const adir: string = ''); overload;
    constructor Create(const idx: integer); overload;
  end;

//==============================================================================
//
// PAK_Configure
// Gives the unit the PAK file system. The composition root calls it
// before PAK_InitFileSystem
//
//==============================================================================
procedure PAK_Configure(const AFiles: IPakFileSystem; const AContainers: IPakContainers);

//==============================================================================
//
// PAK_InitFileSystem
//
//==============================================================================
procedure PAK_InitFileSystem;

//==============================================================================
//
// PAK_ShutDown
//
//==============================================================================
procedure PAK_ShutDown;

//==============================================================================
//
// PAK_AddFile
//
//==============================================================================
function PAK_AddFile(const FileName: string): boolean;

type
  stringparmproc_t = procedure(const atext: string);

//==============================================================================
//
// PAK_StringIterator
//
//==============================================================================
function PAK_StringIterator(const filename: string; proc: stringparmproc_t): integer;

//==============================================================================
//
// PAK_FileNameIterator
//
//==============================================================================
function PAK_FileNameIterator(proc: stringparmproc_t): integer;

//==============================================================================
//
// PAK_ReadFileAsString
//
//==============================================================================
function PAK_ReadFileAsString(const filename: string): string;

//==============================================================================
//
// PAK_ReadAllFilesAsString
//
//==============================================================================
function PAK_ReadAllFilesAsString(const filename: string): string;

//==============================================================================
//
// PAK_LoadPendingPaks
//
//==============================================================================
procedure PAK_LoadPendingPaks;

//==============================================================================
//
// PAK_GetGlobalHash
//
//==============================================================================
function PAK_GetGlobalHash: LongWord;

implementation

uses
  i_system,
  DelphiDoom.Wad.Pak.Names;

var
  // the PAK file system of the engine, given by the composition root (PAK_Configure)
  pakfilesystem: IPakFileSystem = nil;
  pakcontainers: IPakContainers = nil;

//==============================================================================
//
// PAK_Files
//
//==============================================================================
function PAK_Files: IPakFileSystem;
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
function PAK_Containers: IPakContainers;
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
function PAK_DirectoryArray(const alist: TDStringList): TArray<string>;
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
function PAK_GetDirectoryListFromString(const aprefdirs: string): TDStringList;
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
  inherited Create(PAK_Files, FileName, amode, PAK_DirectoryArray(apreflist), adir);
end;

//==============================================================================
//
// TPakStream.Create
//
//==============================================================================
constructor TPakStream.Create(const FileName: string; amode: pakmode_t; const aprefdirs: string = ''; const adir: string = '');
begin
  inherited Create(PAK_Files, FileName, amode, TPakNames.DirectoryList(aprefdirs), adir);
end;

//==============================================================================
//
// TPakStream.Create
//
//==============================================================================
constructor TPakStream.Create(const idx: integer);
begin
  inherited CreateEntry(PAK_Files, idx);
end;

//==============================================================================
//
// PAK_Configure
//
//==============================================================================
procedure PAK_Configure(const AFiles: IPakFileSystem; const AContainers: IPakContainers);
begin
  pakfilesystem := AFiles;
  pakcontainers := AContainers;
end;

//==============================================================================
//
// PAK_InitFileSystem
//
//==============================================================================
procedure PAK_InitFileSystem;
begin
  PAK_Containers.Initialize;
end;

//==============================================================================
//
// PAK_ShutDown
//
//==============================================================================
procedure PAK_ShutDown;
begin
  PAK_Containers.ShutDown;
end;

//==============================================================================
//
// PAK_LoadPendingPaks
//
//==============================================================================
procedure PAK_LoadPendingPaks;
begin
  PAK_Containers.LoadPending;
end;

//==============================================================================
//
// PAK_AddFile
//
//==============================================================================
function PAK_AddFile(const FileName: string): boolean;
begin
  result := PAK_Containers.AddFile(FileName);
end;

//==============================================================================
//
// PAK_StringIterator
//
//==============================================================================
function PAK_StringIterator(const filename: string; proc: stringparmproc_t): integer;
var
  text: string;
begin
  result := 0;
  for text in PAK_Files.Texts(filename) do
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
function PAK_FileNameIterator(proc: stringparmproc_t): integer;
var
  i: integer;
  files: IPakFileSystem;
begin
  files := PAK_Files;
  result := files.EntryCount;
  for i := 0 to result - 1 do
    proc(files.EntryName(i));
end;

//==============================================================================
//
// PAK_ReadFileAsString
//
//==============================================================================
function PAK_ReadFileAsString(const filename: string): string;
begin
  result := PAK_Files.ReadText(filename);
end;

//==============================================================================
//
// PAK_ReadAllFilesAsString
//
//==============================================================================
function PAK_ReadAllFilesAsString(const filename: string): string;
begin
  result := PAK_Files.ReadAllTexts(filename);
end;

//==============================================================================
//
// PAK_GetGlobalHash
//
//==============================================================================
function PAK_GetGlobalHash: LongWord;
begin
  result := PAK_Files.GlobalHash;
end;

end.
