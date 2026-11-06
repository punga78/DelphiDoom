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

unit w_pak;

interface

uses
  d_delphi,
  DelphiDoom.Wad.Intf,
  DelphiDoom.Pak.EntryReader;

type
  /// <summary>One file of the PAK file system, from a PAK, a ZIP (PK3/PK4), a WAD or a WAD2/WAD3</summary>
  TPakEntry = record // A Directory Entry Memory Image
    Pak: string[255];
    Name: string[255];
    ShortName: string[64];
    Offset, Size: Integer; // Offset: the number of the entry in its source
    Hash: Integer;
    Source: Integer; // the source of the entries: the number of the file in the manager
  end;
  PPakEntry = ^TPakEntry;

  TPakEntries = array[0..$FFFF] of TPakEntry;
  PPakEntries = ^TPakEntries;

  TPakFile = record
    Entry: Integer; // -1: a file on disk, F is open; else Z has the bytes of the entry
    F: file;
    Z: TPakEntryReader;
  end;
  PPakFile = ^TPakFile;

const
  PAKHASHSIZE = 8192;

type
  PPakHash = ^TPakHash;
  TPakHash = record
    index: integer;
    next: PPakHash;
  end;

  PPakHashArray = array[0..PAKHASHSIZE - 1] of PPakHash;
  PPakHashPArray = ^PPakHashArray;

  TPakManager = class
  private
    Entries: PPakEntries;
    NumEntries: Integer;
    MaxEntries: Integer;
    PAKS: TDStringList;
    Sources: array of IWadSource; // by the number of the file in PAKS
    HashTable: PPakHashPArray;
    fGlobalHash: LongWord;
    procedure Grow;
    procedure AddEntry(const aname, Pakn: string; const asource, aentry, asize: integer);
    function PLoadEntry(var F: TPakFile; pe: PPakEntry): boolean;
    function HashToHashTableIndex(const hash: integer): integer;
    procedure AddEntryToHashTable(const idx: integer);
    function POpenPreferedFileNameSearch(var F: TPakFile; const aName: string; prefdirs: TDStringList): boolean;
    function POpenPreferedFileNameHash(var F: TPakFile; const aName: string; prefdirs: TDStringList): boolean;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure GetEntries(var s: TDStringList);
    function GetMatchingEntries(Name: string): TDNumberList;
    function POpenFileName(var F: TPakFile; Name: string): boolean;
    function POpenEntry(var F: TPakFile; const idx: integer): boolean;
    function POpenShortFileName(var F: TPakFile; Name: string): boolean;
    function POpenFileNameWithDirectory(var F: TPakFile; Name: string): boolean;
    function POpenPreferedFileName(var F: TPakFile; const aName: string; prefdirs: TDStringList): boolean;
    function PClosefile(var F: TPakFile): boolean;
    function PBlockRead(var F: TPakFile; var Buf; const Size: Integer): integer;
    function PSeek(var F: TPakFile; const Pos: Integer): boolean;
    function PFilePos(var F: TPakFile): Integer;
    function PFileSize(var F: TPakFile): Integer;
    procedure PAddDirectory(const path: string);
    function PAddFile(const FileName: string): boolean;
    property GlobalHash: LongWord read fGlobalHash;
  end;

  pakmode_t = (
    pm_full,      // Full pathname match
    pm_short,     // Filename only match
    pm_prefered,  // Filename match but specified prefered directories
    pm_directory  // A dicectory will be provided
  );

//==============================================================================
//
// PAK_GetDirectoryListFromString
//
//==============================================================================
function PAK_GetDirectoryListFromString(const aprefdirs: string): TDStringList;

type
  TPakStream = class(TDStream)
  private
    entry: TPakFile;
    manager: TPakManager;
    mode: pakmode_t;
    prefdirs: TDStringList;
  public
    constructor Create(const FileName: string; amode: pakmode_t; const aprefdirs: string = ''; const adir: string = ''); overload;
    constructor Create(const FileName: string; amode: pakmode_t; const apreflist: TDStringList; const adir: string = ''); overload;
    constructor Create(const idx: integer); overload;
    destructor Destroy; override;
    function Read(var Buffer; Count: integer): integer; override;
    function Write(const Buffer; Count: integer): integer; override;
    function Seek(Offset: integer; Origin: Word): integer; override;
    function Size: integer; override;
    function Position: integer; override;
  end;

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
// PAK_AddDirectory
//
//==============================================================================
procedure PAK_AddDirectory(const path: string);

//==============================================================================
//
// PAK_AddFile
//
//==============================================================================
function PAK_AddFile(const FileName: string): boolean;

//==============================================================================
//
// PAK_GetMatchingEntries
//
//==============================================================================
function PAK_GetMatchingEntries(const Name: string): TDNumberList;

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

const
  s_TEX_PATH = 'TEXTURES\';

implementation

uses
  i_system,
  t_pcx,
  t_patch,
  t_flat,
  w_wad,
  DelphiDoom.Wad.Types,
  DelphiDoom.Wad.Factory;

//==============================================================================
//
// MkHash
//
//==============================================================================
function MkHash(const s: string): integer;
var
  i: integer;
begin
  result := 0;
  for i := 1 to length(s) do
  begin
    result := ((result shl 7) or (result shr 25)) + Ord(toupper(s[i]));
  end;
end;

{********* TPackDir *********}

//==============================================================================
//
// TPakManager.Create
//
//==============================================================================
constructor TPakManager.Create;
begin
  PAKS := TDStringList.Create;

  Entries := nil;
  NumEntries := 0;
  MaxEntries := 0;
  fGlobalHash := 0;

  HashTable := mallocz(SizeOf(PPakHashArray));
end;

//==============================================================================
//
// TPakManager.PAddDirectory
//
//==============================================================================
procedure TPakManager.PAddDirectory(const path: string);

  procedure DoLoad(const msk: string);
  var
    mask: string;
    sl: TDStringList;
    i: integer;
  begin
    mask := msk;
    if path <> '' then
      mask := path + '\' + mask;

    sl := findfiles(mask);
    for i := 0 to sl.Count - 1 do
      PAddFile(sl[i]);
    sl.Free;
  end;

begin
// JVAL
// Autoload file types in directory
// Does not load ZIP files, only PK3/PK4 files as well as PAK files and new WAD format.
  DoLoad('*.PAK');
{$IFNDEF FPC}
  DoLoad('*.PK3');
  DoLoad('*.PK4');
{$ENDIF}
  DoLoad('*.WAD');
  DoLoad('*.IWAD');
end;

//==============================================================================
//
// TPakManager.Grow
//
//==============================================================================
procedure TPakManager.Grow;
var
  newentries: integer;
begin
  inc(NumEntries);
  if NumEntries > MaxEntries then
  begin
    newentries := MaxEntries + 512;
    realloc(pointer(Entries), MaxEntries * Sizeof(TPakentry), newentries * SizeOf(TPakentry));
    MaxEntries := newentries;
  end;
end;

//==============================================================================
//
// TPakManager.AddEntry
// Adds the entry number aentry (of asize bytes) of the file number asource
//
//==============================================================================
procedure TPakManager.AddEntry(const aname, Pakn: string; const asource, aentry, asize: integer);
var
  e: PPakEntry;
begin
  Grow;

  e := @Entries[NumEntries - 1];
  // the global hash reads the bytes of the strings: no leftovers after their end
  ZeroMemory(e, SizeOf(TPakEntry));
  e.Pak := Pakn;
  e.Name := fixpathname(strupper(aname));
  e.ShortName := fshortname(e.Name);
  e.Hash := MkHash(e.ShortName);
  e.Offset := aentry;
  e.Size := asize;
  e.Source := asource;

  AddEntryToHashTable(NumEntries - 1);
end;

//==============================================================================
//
// TPakManager.PLoadEntry
// Reads the bytes of an entry of the PAK file system
//
//==============================================================================
function TPakManager.PLoadEntry(var F: TPakFile; pe: PPakEntry): boolean;
begin
  try
    F.Z := TPakEntryReader.Create(Sources[pe.Source], pe.Offset);
    result := true;
  except
    on E: EWadException do
    begin
      I_Warning('TPakManager.PLoadEntry(): %s'#13#10, [E.Message]);
      F.Z := nil;
      result := false;
    end;
  end;
end;
//==============================================================================
//
// TPakManager.HashToHashTableIndex
//
//==============================================================================
function TPakManager.HashToHashTableIndex(const hash: integer): integer;
begin
  result := abs(hash) mod PAKHASHSIZE;
end;

//==============================================================================
//
// TPakManager.AddEntryToHashTable
//
//==============================================================================
procedure TPakManager.AddEntryToHashTable(const idx: integer);
var
  hashidx: integer;
  parent: PPakHash;
  pb: PByte;
  i: integer;
begin
  hashidx := HashToHashTableIndex(Entries[idx].Hash);

  parent := HashTable[hashidx];

  HashTable[hashidx] := malloc(SizeOf(TPakHash));
  HashTable[hashidx].index := idx;
  HashTable[hashidx].next := parent;

  pb := @Entries[idx];
  for i := 0 to Integer(@PPakEntry(nil).Hash) - 1 do
  begin
    if pb^ = 0 then
      Inc(fGlobalHash)
    else
      fGlobalHash := ((fGlobalHash shl 7) or (fGlobalHash shr 25)) + pb^;
    inc(pb);
  end;
end;

//==============================================================================
//
// TPakManager.PAddFile
//
//==============================================================================
function TPakManager.PAddFile(const FileName: string): boolean; // Add A Pak file
var
  N, Id: Integer;
  F: file;
  I, J: Integer;
  pkid: Integer;
  Fn: string;
  inHIRES: boolean;
  inTX: boolean;
  b4: packed array[0..127] of byte;
  pk3lumps: TDStringList;
  pk3lump: string;
  lumpbytes: TArray<Byte>;
  wadlumpname: string;
  pc: integer;
  stmp: string;
  wads: TDStringList;
  source: IWadSource;
  ent: TWadEntry;
  iswad: boolean;

  procedure CheckWadEntry(const wadname: string);
  var
    uext: string;
  begin
    uext := strupper(fext(wadname));
    if (uext = '.WAD') or (uext = '.IWAD') then
    begin
      if wads = nil then
        wads := TDStringList.Create;
      wads.Add(wadname);
    end;
  end;

begin
  result := false;
  Fn := strupper(FileName);
  if PAKS.IndexOf(Fn) > -1 then
  begin
    I_Warning('TPakManager.PAddFile(): Trying to add twice file "%s"'#13#10, [FileName]);
    exit;
  end;

  if not fopen(F, Fn, fOpenReadOnly) then
  begin
    I_Warning('TPakManager.PAddFile(): Can not open file "%s"'#13#10, [FileName]);
    exit;
  end;

  Blockread(F, Id, 4, N);
  if N <> 4 then
  begin
    close(F);
    I_Warning('TPakManager.PAddFile(): Can not read file "%s"'#13#10, [FileName]);
    exit;
  end;
  iswad := (Id = IWAD) or (Id = PWAD) or (Id = DWAD);
  if (Id <> PAK_ID) and (Id <> WAD2_ID) and (Id <> WAD3_ID) and (Id <> ZIP_ID) and not iswad then
  begin
    close(F);
    I_Warning('TPakManager.PAddFile(): Unknown file type "%s"'#13#10, [FileName]);
    exit;
  end;

  // The directory of the file is read by the WAD library; F is kept open only for a WAD,
  // to look at the first bytes of its textures
  if not iswad then
    close(F);

  pkid := PAKS.Add(Fn);
  PAKS.Objects[pkid] := nil;
  SetLength(Sources, PAKS.Count);

  try
    source := TWadFactory.OpenPath(Fn);
  except
    on E: EWadException do
    begin
      if iswad then
        close(F);
      I_Warning('TPakManager.PAddFile(): Can not read file "%s": %s'#13#10, [FileName, E.Message]);
      exit;
    end;
  end;
  Sources[pkid] := source;

  wads := nil;

  if not iswad then
  begin
    // PAK, ZIP (PK3/PK4), WAD2/WAD3: the entries are the files
    for i := 0 to source.Count - 1 do
    begin
      ent := source.Entries[i];
      AddEntry(ent.Name, Fn, pkid, i, ent.Size);
      CheckWadEntry(ent.Name);
    end;
  end
  else
  begin
    // DOOM WAD
    inHIRES := false;
    inTX := false;
    pk3lumps := TDStringList.Create;
    for i := 0 to source.Count - 1 do
    begin
      ent := source.Entries[i];
      // 'PK3ENTRY' wad lump contains aliases for wad lumps (8 characters - short filename)
      // to the PK3/PAK filesystem (long filenames).
      wadlumpname := ent.Name;
      if wadlumpname = 'PK3ENTRY' then
      begin
        lumpbytes := source.ReadEntry(i);
        SetLength(pk3lump, Length(lumpbytes));
        for j := 1 to Length(lumpbytes) do
          pk3lump[j] := Chr(lumpbytes[j - 1]);
        pk3lumps.Text := pk3lumps.Text + pk3lump + #13#10;
      end
      else if wadlumpname = 'HI_START' then
        inHIRES := True
      else if wadlumpname = 'HI_END' then
        inHIRES := False
      else if wadlumpname = 'TX_START' then
        inTX := True
      else if wadlumpname = 'TX_END' then
        inTX := False
      else if inHIRES or inTX then
      begin
        Seek(F, ent.Offset);
        ZeroMemory(@b4, SizeOf(b4));
        BlockRead(F, b4, 128, N);
        if (b4[0] = 0) and (b4[1] = 0) and (b4[2] = 2) and (b4[3] = 0) then // TGA
          AddEntry(s_TEX_PATH + wadlumpname + '.TGA', Fn, pkid, i, ent.Size)
        else if (b4[1] = $50) and (b4[2] = $4E) and (b4[3] = $47) then // PNG
          AddEntry(s_TEX_PATH + wadlumpname + '.PNG', Fn, pkid, i, ent.Size)
        else if (b4[0] = $42) and (b4[1] = $4D) then // BMP
          AddEntry(s_TEX_PATH + wadlumpname + '.BMP', Fn, pkid, i, ent.Size)
        else if (b4[6] = $4A) and (b4[7] = $46) and (b4[8] = $49) and (b4[9] = $46) then // JPEG
          AddEntry(s_TEX_PATH + wadlumpname + '.JPG', Fn, pkid, i, ent.Size)
        else if (N >= 128) and T_IsValidPCXHeader(@b4) then // PCX detection
          AddEntry(s_TEX_PATH + wadlumpname + '.PCX', Fn, pkid, i, ent.Size)
        else if (N >= 4) and T_IsValidPatchImage(f, ent.Offset, ent.Size) then
          AddEntry(s_TEX_PATH + wadlumpname + '.PATCH', Fn, pkid, i, ent.Size)
        else if T_IsValidFlatImage(f, ent.Offset, ent.Size) then
          AddEntry(s_TEX_PATH + wadlumpname + '.FLAT', Fn, pkid, i, ent.Size);
      end;
    end;
    // JVAL: 20190913 Allow comments inside PK3ENTRY lumps
    pk3lump := '';
    for i := 0 to pk3lumps.Count - 1 do
    begin
      stmp := pk3lumps.Strings[i];
      pc := Pos('//', stmp);
      if pc > 0 then
        SetLength(stmp, pc - 1);
      stmp := strremovespaces(stmp);
      if stmp <> '' then
        pk3lump := pk3lump + stmp + #13#10;
    end;
    pk3lumps.Text := pk3lump;
    // JVAL: 20170904 Remove blanc entries
    for i := pk3lumps.Count - 1 downto 0 do
      if pk3lumps.Strings[i] = '' then
        pk3lumps.Delete(i);
    if pk3lumps.Count > 0 then
      for i := 0 to source.Count - 1 do
      begin
        ent := source.Entries[i];
        if pk3lumps.IndexOfName(ent.Name) > -1 then
          AddEntry(pk3lumps.Values[ent.Name], Fn, pkid, i, ent.Size);
      end;
    pk3lumps.Free;
    close(F);
  end;

  result := true;
  printf(' adding %s'#13#10, [FileName]);

  if wads <> nil then
  begin
    for i := 0 to wads.Count - 1 do
      W_AddPendingWADfromPAK(wads.Strings[i]);
    wads.Free;
  end;
end;
//==============================================================================
//
// TPakManager.GetEntries
//
//==============================================================================
procedure TPakManager.GetEntries(var s: TDStringList);
var i: integer;
begin
  if s = nil then
    s := TDStringList.Create;
  for i := NumEntries - 1 downto 0 do
    s.Add(Entries[I].Name);
end;

//==============================================================================
//
// TPakManager.GetMatchingEntries
//
//==============================================================================
function TPakManager.GetMatchingEntries(Name: string): TDNumberList;
var
  i: integer;
  hcode: integer;
  pe: PPakEntry;
begin
  result := TDNumberList.Create;

  Name := strupper(fshortname(Name));
  hcode := MkHash(Name);

  for i := 0 to NumEntries - 1 do
  begin
    pe := @Entries[i];
    if hcode = pe.Hash then
      if pe.ShortName = Name then
      begin // Found In Pak
        result.Add(i)
      end;
  end;

end;

//==============================================================================
// TPakManager.POpenFileName
//
// Opens a file
//
//==============================================================================
function TPakManager.POpenFileName(var F: TPakFile; Name: string): boolean;
var
  I: Integer;
  hcode: integer;
  pe: PPakEntry;
  hashcheck: PPakHash;
begin
  result := false;
  F.Z := nil;

  if fopen(F.F, Name, fOpenReadOnly) then
  begin
    F.Entry := -1;
    result := true;
    Exit;
  end; // Disk file Overrides Pak file

  strupperproc(Name);
  hcode := MkHash(fshortname(Name));

  hashcheck := HashTable[HashToHashTableIndex(hcode)];
  while hashcheck <> nil do
  begin
    pe := @Entries[hashcheck.index];
    if hcode = pe.Hash then   // Fast compare the hash values
      if pe.Name = Name then  // Slow compare strings
      begin // Found In Pak
        if not PLoadEntry(F, pe) then
          exit;
        F.Entry := hashcheck.index;
        result := true;
        exit;
      end;
    hashcheck := hashcheck.next;
  end;

  // Highly unlikely that we get to this point....
  for i := NumEntries - 1 downto 0 do // From last entry to zero, last file has priority
  begin
    pe := @Entries[i];
    if hcode = pe.Hash then   // Fast compare the hash values
      if pe.Name = Name then  // Slow compare strings
      begin // Found In Pak
        if not PLoadEntry(F, pe) then
          exit;
        F.Entry := i;
        result := true;
        exit;
      end;
  end;
end;

//==============================================================================
//
// TPakManager.POpenEntry
//
//==============================================================================
function TPakManager.POpenEntry(var F: TPakFile; const idx: integer): boolean;
var
  pe: PPakEntry;
begin
  result := false;

  if idx < 0 then
    exit;

  if idx >= NumEntries then
    exit;

  pe := @Entries[idx];
  if not PLoadEntry(F, pe) then
    exit;
  F.Entry := idx;
  result := true;
end;

//==============================================================================
// TPakManager.POpenShortFileName
//
// Opens a file without extensive search, checks filenames only, not directory structure!!
//
//==============================================================================
function TPakManager.POpenShortFileName(var F: TPakFile; Name: string): boolean;
var
  I: Integer;
  hcode: integer;
  pe: PPakEntry;
  hashcheck: PPakHash;
begin
  result := false;
  F.Z := nil;

  if fopen(F.F, Name, fOpenReadOnly) then
  begin
    F.Entry := -1;
    result := true;
    Exit;
  end; // Disk file Overrides Pak file

  Name := strupper(fshortname(Name));
  hcode := MkHash(Name);

  hashcheck := HashTable[HashToHashTableIndex(hcode)];
  while hashcheck <> nil do
  begin
    pe := @Entries[hashcheck.index];
    if hcode = pe.Hash then   // Fast compare the hash values
      if pe.ShortName = Name then  // Slow compare strings
      begin // Found In Pak
        if not PLoadEntry(F, pe) then
          exit;
        F.Entry := hashcheck.index;
        result := true;
        exit;
      end;
    hashcheck := hashcheck.next;
  end;

  // Highly unlikely that we get to this point....
  for I := NumEntries - 1 downto 0 do
  begin
    pe := @Entries[i];
    if hcode = pe.Hash then
      if pe.ShortName = Name then
      begin // Found In Pak
        if not PLoadEntry(F, pe) then
          exit;
        F.Entry := I;
        result := true;
        Exit;
      end;
  end;
end;

//==============================================================================
// TPakManager.POpenFileNameWithDirectory
//
// Name contains a directory
//
//==============================================================================
function TPakManager.POpenFileNameWithDirectory(var F: TPakFile; Name: string): boolean;
var
  I, p: Integer;
  hcode: integer;
  pe: PPakEntry;
  hashcheck: PPakHash;
begin
  result := false;

  Name := fixpathname(Name);

  p := CharPos('\', Name);
  if p = 1 then
  begin
    Delete(Name, 1, 1);
    p := CharPos('\', Name);
    if p = 1 then
      Exit;
  end;

  trimproc(Name);
  if Name = '' then
    Exit;

  F.Z := nil;

  if fopen(F.F, Name, fOpenReadOnly) then
  begin
    F.Entry := -1;
    result := true;
    Exit;
  end; // Disk file Overrides Pak file

  Name := strupper(fshortname(Name));
  hcode := MkHash(Name);

  hashcheck := HashTable[HashToHashTableIndex(hcode)];
  while hashcheck <> nil do
  begin
    pe := @Entries[hashcheck.index];
    if hcode = pe.Hash then   // Fast compare the hash values
      if (pe.Name = Name) or (RightStr(pe.Name, Length(Name) + 1) =  '\' + Name) then
      begin // Found In Pak
        if not PLoadEntry(F, pe) then
          exit;
        F.Entry := hashcheck.index;
        result := true;
        exit;
      end;
    hashcheck := hashcheck.next;
  end;

  // Highly unlikely that we get to this point....
  for I := NumEntries - 1 downto 0 do
  begin
    pe := @Entries[i];
    if hcode = pe.Hash then
      if (pe.Name = Name) or (RightStr(pe.Name, Length(Name) + 1) =  '\' + Name) then
      begin // Found In Pak
        if not PLoadEntry(F, pe) then
          exit;
        F.Entry := I;
        result := true;
        Exit;
      end;
  end;
end;

type
  Ppref_rec = ^pref_rec;
  pref_rec = record
    index: integer;
    priority: integer;
    next: Ppref_rec;
  end;

//==============================================================================
//
// recourcefreememlist
//
//==============================================================================
procedure recourcefreememlist(var list: Ppref_rec);
begin
  if list <> nil then
  begin
    recourcefreememlist(list.next);
    memfree(pointer(list), SizeOf(pref_rec));
  end;
end;

//==============================================================================
// TPakManager.POpenPreferedFileNameSearch
//
// Opens a file with extensive search prefering the pathname to be contained to prefdirs
// Serial search, does not use hash table
//
//==============================================================================
function TPakManager.POpenPreferedFileNameSearch(var F: TPakFile; const aName: string; prefdirs: TDStringList): boolean;
var
  I: Integer;
  hcode: integer;
  pe: PPakEntry;
  pref_head: Ppref_rec;
  pref_list: Ppref_rec;
  j: integer;
  bestpriority: integer;
  Name: string;
begin
  result := false;
  F.Z := nil;

  pref_head := malloc(SizeOf(pref_rec));
  pref_head.index := -1;
  pref_head.priority := MAXINT;
  pref_head.next := nil;
  pref_list := pref_head;

  Name := strupper(fshortname(aName));
  hcode := MkHash(Name);
  for I := NumEntries - 1 downto 0 do
  begin
    pe := @Entries[i];
    if hcode = pe.Hash then
      if pe.ShortName = Name then
      begin // Found In Pak
        pref_list.index := i;
        pref_list.priority := prefdirs.Count;
        for j := 0 to prefdirs.Count - 1 do
          if Pos(prefdirs[j], pe.Name) > 0 then
          begin
            pref_list.priority := j;
            break;
          end;
        pref_list.next := malloc(SizeOf(pref_rec));
        pref_list := pref_list.next;
        pref_list.index := -1;
        pref_list.next := nil;
      end;
  end;

  pref_list := pref_head;
  bestpriority := MAXINT;
  i := -1;
  while pref_list.index >= 0 do
  begin
    if pref_list.priority < bestpriority then
    begin
      i := pref_list.index;
      bestpriority := pref_list.priority;
    end;
    pref_list := pref_list.next;
  end;

  recourcefreememlist(pref_head);

  if i < 0 then
    exit;

  pe := @Entries[i];
  if not PLoadEntry(F, pe) then
    exit;
  F.Entry := I;
  result := true;
end;

//==============================================================================
// TPakManager.POpenPreferedFileNameHash
//
// Opens a file with extensive search prefering the pathname to be contained to prefdirs
// Fast search using hash table
//
//==============================================================================
function TPakManager.POpenPreferedFileNameHash(var F: TPakFile; const aName: string; prefdirs: TDStringList): boolean;
var
  I: Integer;
  hcode: integer;
  pe: PPakEntry;
  pref_head: Ppref_rec;
  pref_list: Ppref_rec;
  j: integer;
  bestpriority: integer;
  Name: string;
  hashcheck: PPakHash;
begin
  result := false;
  F.Z := nil;

  if fopen(F.F, aName, fOpenReadOnly) then
  begin
    F.Entry := -1;
    result := true;
    Exit;
  end; // Disk file Overrides Pak file

  pref_head := malloc(SizeOf(pref_rec));
  pref_head.index := -1;
  pref_head.priority := MAXINT;
  pref_head.next := nil;
  pref_list := pref_head;

  Name := strupper(fshortname(aName));
  hcode := MkHash(Name);

  hashcheck := HashTable[HashToHashTableIndex(hcode)];
  while hashcheck <> nil do
  begin
    pe := @Entries[hashcheck.index];
    if hcode = pe.Hash then
      if pe.ShortName = Name then
      begin // Found In Pak
        pref_list.index := hashcheck.index;
        pref_list.priority := MAXINT - 1;
        for j := 0 to prefdirs.Count - 1 do
        begin
          if prefdirs[j] + Name = pe.Name then
          begin
            pref_list.priority := j;
            break;
          end
          else if Pos(prefdirs[j], pe.Name) > 0 then
          begin
            pref_list.priority := prefdirs.Count + j;
            break;
          end;
        end;
        pref_list.next := malloc(SizeOf(pref_rec));
        pref_list := pref_list.next;
        pref_list.index := -1;
        pref_list.next := nil;
      end;
    hashcheck := hashcheck.next;
  end;

  pref_list := pref_head;
  bestpriority := MAXINT;
  i := -1;
  while pref_list.index >= 0 do
  begin
    if pref_list.priority < bestpriority then
    begin
      i := pref_list.index;
      bestpriority := pref_list.priority;
    end;
    pref_list := pref_list.next;
  end;

  recourcefreememlist(pref_head);

  if i < 0 then
    exit;

  pe := @Entries[i];
  if not PLoadEntry(F, pe) then
    exit;
  F.Entry := I;
  result := true;
end;

//==============================================================================
//
// TPakManager.POpenPreferedFileName
//
//==============================================================================
function TPakManager.POpenPreferedFileName(var F: TPakFile; const aName: string; prefdirs: TDStringList): boolean;
begin
  result := POpenPreferedFileNameHash(F, aName, prefdirs);
  if not result then
    result := POpenPreferedFileNameSearch(F, aName, prefdirs);
end;

//==============================================================================
//
// TPakManager.PClosefile
//
//==============================================================================
function TPakManager.PClosefile(var F: TPakFile): boolean;
begin
  if F.Z <> nil then
  begin
    F.Z.Free;
    F.Z := nil;
    result := true;
  end
  else
  begin
    {$I-}
    Close(F.F);
    {$I+}
    result := IOResult = 0;
  end;
end;

//==============================================================================
//
// TPakManager.PBlockRead
//
//==============================================================================
function TPakManager.PBlockRead(var F: TPakFile; var Buf; const Size: Integer): integer;
begin
  if F.Z <> nil then
    result := F.Z.Read(Buf, Size)
  else
  begin
    {$I-}
    Blockread(F.F, Buf, Size, result);
    {$I+}
  end;
end;

//==============================================================================
//
// TPakManager.PSeek
//
//==============================================================================
function TPakManager.PSeek(var F: TPakFile; const Pos: Integer): boolean;
begin
  if F.Z <> nil then
    result := F.Z.Seek(Pos)
  else
  begin
    {$I-}
    Seek(F.F, Pos);
    {$I+}
    result := IOResult = 0;
  end;
end;

//==============================================================================
//
// TPakManager.PFilePos
//
//==============================================================================
function TPakManager.PFilePos(var F: TPakFile): Integer;
begin
  if F.Z <> nil then
    result := F.Z.Position
  else
    result := FilePos(F.F);
end;

//==============================================================================
//
// TPakManager.PFileSize
//
//==============================================================================
function TPakManager.PFileSize(var F: TPakFile): Integer;
begin
  if F.Z <> nil then
    result := F.Z.Size
  else
  begin
  {$I-}
    result := Filesize(F.F);
  {$I+}
    if IOResult <> 0 then
      result := 0;
  end;
end;
//==============================================================================
//
// TPakManager.Destroy
//
//==============================================================================
destructor TPakManager.Destroy;
var
  i: integer;

  procedure recoursivefreehashitem(var h: PPakHash);
  begin
    if h.next <> nil then
      recoursivefreehashitem(h.next);
    memfree(pointer(h), SizeOf(TPakHash));
  end;

begin
  for i := 0 to PAKHASHSIZE - 1 do
    if HashTable[i] <> nil then
      recoursivefreehashitem(HashTable[i]);

  memfree(pointer(HashTable), SizeOf(PPakHashArray));

  realloc(pointer(Entries), MaxEntries * Sizeof(TPakentry), 0);

  Sources := nil;
  PAKS.Free;
end;

// Global Pak Loader Object
var
  pakmanager: TPakManager;

//==============================================================================
//
// PAK_GetDirectoryListFromString
//
//==============================================================================
function PAK_GetDirectoryListFromString(const aprefdirs: string): TDStringList;
var
  i: integer;
  stmp: string;
  stmp2: string;
begin
  result := TDStringList.Create;
  if aprefdirs <> '' then
  begin
    stmp := '';
    for i := 1 to Length(aprefdirs) do
      if aprefdirs[i] in [' ', ','] then
        stmp := stmp + #13#10
      else
        stmp := stmp + toupper(aprefdirs[i]);
    result.Text := stmp;
    for i := result.count - 1 downto 0 do
      if result.strings[i] = '' then
        result.Delete(i);
    stmp := '';
    for i := 0 to result.Count - 1 do
    begin
      stmp2 := strtrim(result[i]);
      if Length(stmp2) > 0 then
      begin
        if stmp2[Length(stmp2)] <> '\' then
          stmp := stmp + stmp2 + '\'#13#10
        else
          stmp := stmp + stmp2 + #13#10;
      end;
    end;
    result.Text := stmp;
  end;
end;

//==============================================================================
// TPakStream.Create
//
// TPakStream
//
//==============================================================================
constructor TPakStream.Create(const FileName: string; amode: pakmode_t; const apreflist: TDStringList; const adir: string = '');
var
  ok, diddir: boolean;
  i: integer;
begin
  Inherited Create;

  OnBeginBusy := nil;
  OnEndBusy := nil;

  prefdirs := TDStringList.Create;

  if apreflist <> nil then
    for i := 0 to apreflist.Count - 1 do
      prefdirs.Add(apreflist[i]);

  manager := pakmanager;
  mode := amode;
  diddir := false;
  if (adir <> '') and (mode <> pm_full) then
  begin
    ok := manager.POpenFileNameWithDirectory(entry, adir + '\' + FileName);
    diddir := true;
  end
  else if mode = pm_full then
    ok := manager.POpenFileName(entry, FileName)
  else if mode = pm_short then
    ok := manager.POpenShortFileName(entry, FileName)
  else if mode = pm_prefered then
    ok := manager.POpenPreferedFileName(entry, FileName, prefdirs)
  else
    ok := false;

  if not ok then
  begin
    ok := manager.POpenFileNameWithDirectory(entry, FileName);
    if not ok then
      if not diddir then
        if adir <> '' then
          ok := manager.POpenFileNameWithDirectory(entry, adir + '\' + FileName);
  end;

  if not ok then
    FIOResult := 1
  else
    FIOResult := 0;
end;

//==============================================================================
//
// TPakStream.Create
//
//==============================================================================
constructor TPakStream.Create(const FileName: string; amode: pakmode_t; const aprefdirs: string = ''; const adir: string = '');
var
  apreflist: TDStringList;
begin
  apreflist := PAK_GetDirectoryListFromString(aprefdirs);
  Create(FileName, amode, apreflist, adir);
  apreflist.Free;
end;

//==============================================================================
//
// TPakStream.Create
//
//==============================================================================
constructor TPakStream.Create(const idx: integer);
var
  ok: boolean;
begin
  Inherited Create;

  OnBeginBusy := nil;
  OnEndBusy := nil;

  prefdirs := TDStringList.Create;

  manager := pakmanager;
  mode := pm_short;
  ok := manager.POpenEntry(entry, idx);
  if not ok then
    FIOResult := 1
  else
    FIOResult := 0;
end;

//==============================================================================
//
// TPakStream.Destroy
//
//==============================================================================
destructor TPakStream.Destroy;
begin
  manager.PClosefile(entry);
  prefdirs.Free;
  Inherited;
end;

//==============================================================================
//
// TPakStream.Read
//
//==============================================================================
function TPakStream.Read(var Buffer; Count: integer): integer;
begin
  result := manager.PBlockRead(entry, Buffer, Count);
  if system.IOResult <> 0 then
    inc(FIOResult);
end;

//==============================================================================
//
// TPakStream.Write
//
//==============================================================================
function TPakStream.Write(const Buffer; Count: integer): integer;
begin
  I_Warning('TPakStream::Write(): Pak managment is read-only'#13#10);
  inc(FIOResult);
  result := 0;
end;

//==============================================================================
//
// TPakStream.Seek
//
//==============================================================================
function TPakStream.Seek(Offset: integer; Origin: Word): integer;
var
  p: integer;
begin
  if Origin = sFromBeginning then
    p := Offset
  else if Origin = sFromCurrent then
    p := manager.PFilePos(entry) + Offset
  else {sFromEnd}
    p := manager.PFileSize(entry) - Offset;

  if not manager.PSeek(entry, p) then
    inc(FIOResult);
  result := p;
end;

//==============================================================================
//
// TPakStream.Size
//
//==============================================================================
function TPakStream.Size: integer;
begin
  result := manager.PFileSize(entry)
end;

//==============================================================================
//
// TPakStream.Position
//
//==============================================================================
function TPakStream.Position: integer;
begin
  result := manager.PFilePos(entry);
end;

//==============================================================================
//
// PAK_InitFileSystem
//
//==============================================================================
procedure PAK_InitFileSystem;
begin
  pakmanager := TPakManager.Create;
end;

//==============================================================================
//
// PAK_ShutDown
//
//==============================================================================
procedure PAK_ShutDown;
begin
  pakmanager.Free;
end;

var
  pendingpaks: TDStringList;

//==============================================================================
//
// PAK_LoadPendingPaks
//
//==============================================================================
procedure PAK_LoadPendingPaks;
var
  i: integer;
begin
  if pendingpaks.Count = 0 then
    Exit;

  for i := 0 to pendingpaks.Count - 1 do
    if I_DirectoryExists(pendingpaks.Strings[i]) then
      pakmanager.PAddDirectory(pendingpaks.Strings[i])
    else
      pakmanager.PAddFile(pendingpaks.Strings[i]);
  pendingpaks.Clear;
end;

//==============================================================================
//
// PAK_AddDirectory
//
//==============================================================================
procedure PAK_AddDirectory(const path: string);
begin
  if pakmanager = nil then
  begin
    pendingpaks.Add(path);
    exit;
  end;

  PAK_LoadPendingPaks;

  printf(' adding directory %s'#13#10, [path]);
  pakmanager.PAddDirectory(path);
end;

//==============================================================================
//
// PAK_AddFile
//
//==============================================================================
function PAK_AddFile(const FileName: string): boolean;
begin
  if pakmanager = nil then
  begin
    pendingpaks.Add(FileName);
    Result := false;
    exit;
  end;

  PAK_LoadPendingPaks;

  if I_DirectoryExists(FileName) then
  begin
    result := true;
    PAK_AddDirectory(FileName)
  end
  else
    result := pakmanager.PAddFile(FileName);
end;

//==============================================================================
//
// PAK_GetMatchingEntries
//
//==============================================================================
function PAK_GetMatchingEntries(const Name: string): TDNumberList;
begin
  result := pakmanager.GetMatchingEntries(Name);
end;

//==============================================================================
//
// PAK_StringIterator
//
//==============================================================================
function PAK_StringIterator(const filename: string; proc: stringparmproc_t): integer;
var
  entries: TDNumberList;
  strm: TPakStream;
  list: TDStringList;
  i: integer;
begin
  result := 0;
  entries := PAK_GetMatchingEntries(filename);
  list := TDStringList.Create;
  for i := 0 to entries.Count - 1 do
  begin
    strm := TPakStream.Create(entries.Numbers[i]);
    if strm.IOResult = 0 then
    begin
      list.LoadFromStream(strm);
      proc(list.Text);
      inc(result);
    end;
    strm.Free;
  end;
  list.Free;
  entries.Free;
end;

//==============================================================================
//
// PAK_FileNameIterator
//
//==============================================================================
function PAK_FileNameIterator(proc: stringparmproc_t): integer;
var
  i: integer;
begin
  result := pakmanager.NumEntries;
  for i := 0 to result - 1 do
    proc(pakmanager.Entries[i].Name);
end;

//==============================================================================
//
// PAK_ReadFileAsString
//
//==============================================================================
function PAK_ReadFileAsString(const filename: string): string;
var
  entries: TDNumberList;
  strm: TPakStream;
  list: TDStringList;
begin
  entries := PAK_GetMatchingEntries(filename);
  if entries.Count > 0 then
  begin
    list := TDStringList.Create;
    strm := TPakStream.Create(entries.Numbers[entries.Count - 1]);
    if strm.IOResult = 0 then
    begin
      list.LoadFromStream(strm);
      Result := list.Text;
    end;
    strm.Free;
    list.Free;
  end
  else
    Result := '';
  entries.Free;
end;

//==============================================================================
//
// PAK_ReadAllFilesAsString
//
//==============================================================================
function PAK_ReadAllFilesAsString(const filename: string): string;
var
  entries: TDNumberList;
  strm: TPakStream;
  list: TDStringList;
  i: integer;
begin
  entries := PAK_GetMatchingEntries(filename);
  Result := '';
  for i := 0 to entries.Count - 1 do
  begin
    list := TDStringList.Create;
    strm := TPakStream.Create(entries.Numbers[i]);
    if strm.IOResult = 0 then
    begin
      list.LoadFromStream(strm);
      Result := Result + list.Text + #13#10;
    end;
    strm.Free;
    list.Free;
  end;
  entries.Free;
end;

//==============================================================================
//
// PAK_GetGlobalHash
//
//==============================================================================
function PAK_GetGlobalHash: LongWord;
begin
  Result := pakmanager.GlobalHash;
end;

initialization
  pendingpaks := TDStringList.Create;

finalization
  pendingpaks.Free;

end.

