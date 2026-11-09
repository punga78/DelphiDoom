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
//  WAD I/O functions.
//  Handles WAD file header, directory, lump I/O.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit w_wad;

interface

uses
  d_delphi,
  DelphiDoom.Wad.Intf,
  DelphiDoom.Engine.Wad.Intf,
  DelphiDoom.Engine.Wad.Converter.Intf;

//
// TYPES
//

type
  char8_t = array[0..7] of AnsiChar;
  Pchar8_t = ^char8_t;

const
  IND_FLOOR = 1;
  IND_SPRITE = 2;
  IND_PATCH = 3;
  IND_VOXEL = 4;
  IND_HIRES = 5;
  IND_MAX = 6;
  TYPE_FLOOR = 1 shl IND_FLOOR;
  TYPE_SPRITE = 1 shl IND_SPRITE;
  TYPE_PATCH = 1 shl IND_PATCH;
  TYPE_VOXEL = 1 shl IND_VOXEL;
  TYPE_HIRES = 1 shl IND_HIRES;


type
  wadinfo_t = packed record
    // Should be "IWAD" or "PWAD".
    identification: integer;
    numlumps: integer;
    infotableofs: integer;
  end;

  filelump_t = packed record
    filepos: integer;
    size: integer;
    name: char8_t;
  end;
  Pfilelump_t = ^filelump_t;
  Tfilelump_tArray = packed array[0..$FFFF] of filelump_t;
  Pfilelump_tArray = ^Tfilelump_tArray;

//
// WADFILE I/O related stuff.
//
  lumpinfo_t = record
    handle: TDStream;
    position: integer;
    size: integer;
    flags: LongWord;
    case integer of
      0: (name: char8_t);
      1: (v1, v2: integer);
    end;

  Plumpinfo_t = ^lumpinfo_t;
  lumpinfo_tArray = array[0..$FFFF] of lumpinfo_t;
  Plumpinfo_tArray = ^lumpinfo_tArray;

type
  name8_t = record
    case integer of
      0: (s: char8_t);
      1: (x: array[0..1] of integer);
    end;

  PTransProcedure = procedure (const src: pointer; const size: integer; const dest: PPointer; const tag: integer);

//==============================================================================
//
// char8tostring
//
//==============================================================================
function char8tostring(src: char8_t): string;

//==============================================================================
//
// stringtochar8
//
//==============================================================================
function stringtochar8(src: string): char8_t;

//==============================================================================
//
// W_Configure
// Gives the unit the WAD services it works on. The composition root calls it
// before anything else of this unit
//
//==============================================================================
procedure W_Configure(const AServices: IEngineWadServices);

//==============================================================================
//
// W_ConfigureConverter
// Gives the unit the converter of the data container of the game (Radix:
// RADIX.DAT); a game whose data are WADs does not call it
//
//==============================================================================
procedure W_ConfigureConverter(const AConverter: IEngineWadConverter);

//==============================================================================
//
// W_InitMultipleFiles
//
//==============================================================================
function W_InitMultipleFiles(const filenames: TDStringList): integer;

//==============================================================================
//
// W_ShutDown
//
//==============================================================================
procedure W_ShutDown;

//==============================================================================
//
// W_Reload
//
//==============================================================================
procedure W_Reload;

const
  F_ORIGIN_WAD = 0;
  F_ORIGIN_PAK = 1;

//==============================================================================
//
// W_RuntimeLoad
//
//==============================================================================
procedure W_RuntimeLoad(fname: string; const origin: integer);

//==============================================================================
//
// W_AddPendingWADfromPAK
//
//==============================================================================
procedure W_AddPendingWADfromPAK(const fname: string);

//==============================================================================
//
// W_NumLumps
//
//==============================================================================
function W_NumLumps: integer;

//==============================================================================
//
// W_CheckNumForName
//
//==============================================================================
function W_CheckNumForName(const name: string; const flags: LongWord = $0): integer;

//==============================================================================
//
// W_CheckNumForName2
//
//==============================================================================
function W_CheckNumForName2(const name: string; first: integer; last: integer): integer;

//==============================================================================
//
// W_CheckFirstNumForName
//
//==============================================================================
function W_CheckFirstNumForName(const name: string): integer;

//==============================================================================
//
// W_GetNumForName
//
//==============================================================================
function W_GetNumForName(const name: string; const flags: LongWord = $0): integer;

//==============================================================================
//
// W_GetFirstNumForName
//
//==============================================================================
function W_GetFirstNumForName(const name: string): integer;

//==============================================================================
//
// W_GetNameForNum
//
//==============================================================================
function W_GetNameForNum(const lump: integer): char8_t;

//==============================================================================
//
// W_LumpIsNamed
// True when the lump has exactly that name
//
//==============================================================================

//==============================================================================
//
// W_LumpFlags
// TYPE_* bits of the marker pairs (F_START/F_END, S_START/S_END, ...) around the lump
//
//==============================================================================
function W_LumpFlags(const lump: integer): LongWord;

//==============================================================================
//
// W_LumpLength
//
//==============================================================================
function W_LumpLength(const lump: integer): integer;

//==============================================================================
//
// W_LumpCRC32
//
//==============================================================================
function W_LumpCRC32(const lump: integer): string;

//==============================================================================
//
// W_ReadLump
//
//==============================================================================
procedure W_ReadLump(const lump: integer; dest: pointer);

//==============================================================================
//
// W_CacheLumpNum
//
//==============================================================================
function W_CacheLumpNum(const lump: integer; const tag: integer): pointer;

//==============================================================================
//
// W_CacheLumpNum2
//
//==============================================================================

//==============================================================================
//
// W_CacheLumpName
//
//==============================================================================
function W_CacheLumpName(const name: string; const tag: integer; const flags: LongWord = $0): pointer;

//==============================================================================
//
// W_TextLumpNum
//
//==============================================================================
function W_TextLumpNum(const lump: integer): string;

//==============================================================================
//
// W_TextLumpName
//
//==============================================================================
function W_TextLumpName(const name: string): string;

//==============================================================================
//
// ExtractFileBase8
//
//==============================================================================
procedure ExtractFileBase8(const path: string; var dest: char8_t);

const
  IWAD = integer(Ord('I') or
                (Ord('W') shl 8) or
                (Ord('A') shl 16) or
                (Ord('D') shl 24));

  PWAD = integer(Ord('P') or
                (Ord('W') shl 8) or
                (Ord('A') shl 16) or
                (Ord('D') shl 24));

// DelphiDoom specific
  DWAD = integer(Ord('D') or
                (Ord('W') shl 8) or
                (Ord('A') shl 16) or
                (Ord('D') shl 24));

implementation

uses
  i_system,
  w_pak,
  z_zone,
  DelphiDoom.MathCore.Crc32,
  DelphiDoom.Wad.Types,
  DelphiDoom.Wad.Text,
  DelphiDoom.Wad.FileBase;

//
// The directory of the lumps is kept by the WAD library (Libs\Wad): it reads the
// directories of the files, orders the lumps, finds them by name and knows which
// ones are between the F_START/F_END, S_START/S_END, ... marker pairs.
// lumpinfo[] is a view of it that W_SyncLumpInfo makes again whenever the
// directory changes: the rest of the engine reads it, nobody else writes it.
// The bytes of the lumps are still read through the streams of the engine.
//
var
  lumpinfo: Plumpinfo_tArray = nil; // a view of wad_directory, written only by W_SyncLumpInfo
  lumpcache: PPointerArray;
  numlumps: integer = 0;
  lumpinfoalloc: integer = 0; // lumps that lumpinfo has room for

  wad_services: IEngineWadServices = nil;
  wad_converter: IEngineWadConverter = nil;
  wad_directory: IWadDirectory = nil;
  wad_finder: IWadFinder = nil;
  wad_reader: ILumpReader = nil;
  // The engine stream of each source of the directory (nil for a reloadable file)
  wad_handles: array of TDStream;

// Location of each lump on disk.
var
  lumpcacherealsize: integer;

//==============================================================================
//
// char8tostring
//
//==============================================================================
function char8tostring(src: char8_t): string;
var
  i: integer;
begin
  result := '';
  i := 0;
  while (i < 8) and (src[i] <> #0) do
  begin
    result := result + src[i];
    inc(i);
  end;
end;

//==============================================================================
//
// stringtochar8
//
//==============================================================================
function stringtochar8(src: string): char8_t;
var
  i: integer;
  len: integer;
begin
  len := length(src);
  if len > 8 then
    I_Error('stringtochar8(): length of %s is > 8', [src]);

  i := 1;
  while (i <= len) do
  begin
    result[i - 1] := AnsiChar(src[i]);
    inc(i);
  end;

  for i := len to 7 do
    result[i] := #0;
end;

//==============================================================================
//
// filelength
//
//==============================================================================
function filelength(handle: TCachedFile): integer;
begin
  try
    result := handle.Size;
  except
    result := 0;
    I_Error('filelength(): Error fstating');
  end;
end;

//==============================================================================
//
// ExtractFileBase
//
//==============================================================================
procedure ExtractFileBase(const path: string; var dest: string);
begin
  // the rule of the base name is TWadFileBase of Libs\Wad
  try
    dest := TWadFileBase.Extract(path);
  except
    on E: EWadException do
      I_Error('ExtractFileBase(): Filename base of %s >8 chars', [path]);
  end;
end;

//==============================================================================
//
// ExtractFileBase8
//
//==============================================================================
procedure ExtractFileBase8(const path: string; var dest: char8_t);
var
  dst: string;
begin
  dst := char8tostring(dest);
  ExtractFileBase(path, dst);
  dest := stringtochar8(dst);
end;

//==============================================================================
//
// W_SyncLumpInfo
// Makes lumpinfo[] again from the directory of the library
//
//==============================================================================
procedure W_SyncLumpInfo;
var
  i: integer;
  count: integer;
  lump_p: Plumpinfo_t;
begin
  count := wad_directory.Count;
  if count <> lumpinfoalloc then
  begin
    realloc(pointer(lumpinfo), lumpinfoalloc * SizeOf(lumpinfo_t), count * SizeOf(lumpinfo_t));
    lumpinfoalloc := count;
  end;

  if (lumpinfo = nil) and (count > 0) then
    I_Error('W_SyncLumpInfo(): Couldn''t realloc lumpinfo');

  for i := 0 to count - 1 do
  begin
    lump_p := @lumpinfo[i];
    lump_p.handle := wad_handles[wad_directory.LumpSourceIndex(i)];
    lump_p.position := wad_directory.LumpOffset(i);
    lump_p.size := wad_directory.LumpSize(i);
    lump_p.flags := wad_directory.LumpFlags(i);
    lump_p.name := stringtochar8(wad_directory.LumpName(i));
  end;

  numlumps := count;
end;

//==============================================================================
//
// W_CreateWadSource
// A source of the library over a stream of the engine. The source owns the
// adapter, not the stream
//
//==============================================================================
function W_CreateWadSource(const aname: string; handle: TDStream; const singlelump: boolean): IWadSource;
begin
  result := wad_services.OpenStream(aname, handle, singlelump);
end;

//==============================================================================
//
// LUMP BASED ROUTINES.
//

//
// W_AddFile
// All files are optional, but at least one file must be
//  found (PWAD, if all required lumps are present).
// Files with a .wad extension are wadlink files
//  with multiple lumps.
// Other files are single lumps with the base filename
//  for the lump name.
//
// If filename starts with a tilde, the file is handled
//  specially to allow map reloads.
// But: the reload feature is a fragile hack...
var
  reloadlump: integer;
  reloadsource: integer;
  reloadname: string;

//==============================================================================
//
// W_AddFile
//
//==============================================================================
function W_AddFile(var filename: string): TDStream;
var
  header: wadinfo_t;
  handle: TCachedFile;
  ext: string;
  iswad: boolean;
  source: IWadSource;
  base8: char8_t;
  converted: TArray<Byte>;
  memory: TDMemoryStream;
begin
  // open the file and add to directory
  // handle reload indicator.
  if filename[1] = '~' then
  begin
    reloadname := Copy(filename, 2, Length(filename) - 1);
    Delete(filename, 1, 1);
    reloadlump := numlumps;
    reloadsource := wad_directory.SourceCount;
  end
  else
    reloadname := '';

  if not fexists(filename) then
  begin
    I_Warning('W_AddFile(): File %s does not exist'#13#10, [filename]);
    result := nil;
    exit;
  end;

  if Assigned(wad_converter) and (strupper(fext(filename)) = '.DAT') and
    wad_converter.TryConvert(filename, converted) then
  begin
    // the data of the game are not a WAD: the translated lumps are one, in memory
    memory := TDMemoryStream.Create;
    memory.Write(converted[0], Length(converted));
    memory.Seek(0, sFromBeginning);
    result := memory;
    source := W_CreateWadSource(filename, memory, false);
    printf(' adding %s (%d lump' + decide(source.Count = 1, '', 's') + ' translated)'#13#10, [filename, source.Count]);
    wad_directory.AddSource(source);
    SetLength(wad_handles, wad_directory.SourceCount);
    wad_handles[High(wad_handles)] := memory;
    W_SyncLumpInfo;
    exit;
  end;

  try
    handle := TCachedFile.Create(filename, fOpenReadOnly);
  except
    I_Warning('W_AddFile(): couldn''t open %s'#13#10, [filename]);
    result := nil;
    exit;
  end;

  result := handle;

  handle.OnBeginBusy := I_BeginDiskBusy;

  ext := strupper(fext(filename));

  iswad := false;
  if ext = '.OUT' then
  begin
    // Potential WAD file
    handle.Read(header, SizeOf(header));
    if (header.identification = IWAD) or
       (header.identification = PWAD) or
       (header.identification = DWAD) then
      iswad := true;
    handle.Seek(0, sFromBeginning);
  end;

  if not iswad and (ext <> '.WAD') and (ext <> '.IWAD') and (ext <> '.SWD') {$IFDEF OPENGL} and (ext <> '.GWA'){$ENDIF} then
  begin
    // single lump file, named after the file
    ZeroMemory(@base8, SizeOf(base8));
    ExtractFileBase8(filename, base8);
    source := W_CreateWadSource(char8tostring(base8) + '.lmp', handle, true);
    printf(' adding %s'#13#10, [filename]);
  end
  else
  begin
    // WAD file: IWAD, PWAD or the DelphiDoom system DWAD
    try
      source := W_CreateWadSource(filename, handle, false);
    except
      on E: EWadException do
        I_Error('W_AddFile(): Wad file %s doesn''t have IWAD, PWAD or DWAD id, or is damaged: %s'#13#10, [filename, E.Message]);
    end;
    printf(' adding %s (%d lump' + decide(source.Count = 1, '', 's') + ')'#13#10, [filename, source.Count]);
  end;

  if reloadname <> '' then
    // the file is not kept open: it is opened again whenever a lump is read
    source := wad_services.MakeReloadable(filename, source);

  wad_directory.AddSource(source);
  SetLength(wad_handles, wad_directory.SourceCount);
  if reloadname <> '' then
  begin
    wad_handles[High(wad_handles)] := nil;
    handle.Free;
  end
  else
    wad_handles[High(wad_handles)] := handle;

  W_SyncLumpInfo;
end;

//==============================================================================
//
// W_Reload
// Flushes any of the reloadable lumps in memory
//  and reloads the directory.
//
//==============================================================================
procedure W_Reload;
var
  lumpcount: integer;
  i: integer;
  handle: TCachedFile;
  source: IWadSource;
begin
  if reloadname = '' then
    exit;

  if not fexists(reloadname) then
    I_Error('W_Reload(): File %s does not exist'#13#10, [reloadname]);

  handle := nil;
  try
    handle := TCachedFile.Create(reloadname, fOpenReadOnly);
  except
    handle.Free;
    I_Error('W_Reload(): couldn''t open %s', [reloadname]);
  end;

  handle.OnBeginBusy := I_BeginDiskBusy;

  try
    source := W_CreateWadSource(reloadname, handle, false);
    lumpcount := source.Count;
    if lumpcount <> wad_directory.Sources[reloadsource].Count then
      I_Error('W_Reload(): File %s has %d lumps, it had %d'#13#10,
        [reloadname, lumpcount, wad_directory.Sources[reloadsource].Count]);

    // Flush the lumps that change
    for i := reloadlump to reloadlump + lumpcount - 1 do
      if lumpcache[i] <> nil then
        Z_Free(lumpcache[i]);

    wad_directory.ReplaceSource(reloadsource, wad_services.MakeReloadable(reloadname, source));
  except
    on E: EWadException do
      I_Error('W_Reload(): %s'#13#10, [E.Message]);
  end;

  // The file is opened again whenever a lump is read
  handle.Free;

  W_SyncLumpInfo;
end;

var
  rtllist: TDStringList = nil; // JVAL: Runtime wads

type
  rtlinfo_t = class
    filename: string;
    startlump: integer;
    numlumps: integer;
    sourceindex: integer;
    stream: TDStream;
    constructor Create(const aname: string); virtual;
    destructor Destroy; override;
  end;

//==============================================================================
//
// rtlinfo_t.Create
//
//==============================================================================
constructor rtlinfo_t.Create(const aname: string);
begin
  filename := aname;
  startlump := -1;
  numlumps := -1;
  sourceindex := -1;
  stream := nil;
end;

//==============================================================================
//
// rtlinfo_t.Destroy
//
//==============================================================================
destructor rtlinfo_t.Destroy;
begin
  stream.Free;
  inherited;
end;

//==============================================================================
//
// W_RuntimeLoad
//
//==============================================================================
procedure W_RuntimeLoad(fname: string; const origin: integer);
var
  lumpcount: integer;
  i: integer;
  handle: TDStream;
  idx: integer;
  rtlinf: rtlinfo_t;
  start, finish: integer;
  oldcache: pointer;
  ioret: integer;
  source: IWadSource;
begin
  printf('W_RuntimeLoad(): adding %s'#13#10, [fname]);

  strupperproc(fname);

  if origin = F_ORIGIN_WAD then
    if not fexists(fname) then
    begin
      I_Warning('W_RuntimeLoad(): File %s does not exist'#13#10, [fname]);
      exit;
    end;

  if rtllist = nil then
    rtllist := TDStringList.Create;

  handle := nil;
  try
    if origin = F_ORIGIN_WAD then
      handle := TCachedFile.Create(fname, fOpenReadOnly)
    else
      handle := TPakStream.Create(fname, pm_full);
  except
    handle.Free;
    I_Warning('W_RuntimeLoad(): couldn''t open %s'#13#10, [fname]);
    exit;
  end;

  ioret := handle.IOResult;
  if ioret <> 0 then
  begin
    I_Warning('W_RuntimeLoad(): couldn''t open %s, IOResult = %d'#13#10, [fname, ioret]);
    handle.Free;
    exit;
  end;

  handle.OnBeginBusy := I_BeginDiskBusy;

  try
    source := W_CreateWadSource(fname, handle, false);
  except
    on E: EWadException do
    begin
      I_Warning('W_RuntimeLoad(): %s is not a valid WAD: %s'#13#10, [fname, E.Message]);
      handle.Free;
      exit;
    end;
  end;
  lumpcount := source.Count;

  idx := rtllist.IndexOf(fname);
  if idx < 0 then
  begin
    idx := rtllist.Add(fname);
    rtlinf := rtlinfo_t.Create(fname);
    rtllist.Objects[idx] := rtlinf;
  end
  else
    rtlinf := rtllist.Objects[idx] as rtlinfo_t;

  if (rtlinf.startlump >= 0) and (rtlinf.numlumps = lumpcount) then
  begin
    // The same file again: the lumps keep their numbers
    start := rtlinf.startlump;
    finish := start + lumpcount - 1;
    wad_directory.ReplaceSource(rtlinf.sourceindex, source);
    wad_handles[rtlinf.sourceindex] := handle;
  end
  else
  begin
    if lumpcacherealsize < numlumps + lumpcount then
    begin
      oldcache := @lumpcache[0];
      realloc(pointer(lumpcache), lumpcacherealsize * SizeOf(pointer), (numlumps + lumpcount + 1024) * SizeOf(pointer));
      lumpcacherealsize := numlumps + lumpcount + 1024;

      // The blocks of the zone that are used by the lumps follow the table if it moved
      if @lumpcache[0] <> oldcache then
        Z_MoveUsers(oldcache, numlumps * SizeOf(pointer), @lumpcache[0]);
    end;

    start := numlumps;
    finish := start + lumpcount - 1;
    for i := start to finish do
      lumpcache[i] := nil;

    rtlinf.startlump := start;
    rtlinf.numlumps := lumpcount;
    rtlinf.sourceindex := wad_directory.SourceCount;
    wad_directory.AddSource(source);
    SetLength(wad_handles, wad_directory.SourceCount);
    wad_handles[High(wad_handles)] := handle;
  end;
  if rtlinf.stream <> nil then
    rtlinf.stream.Free;
  rtlinf.stream := handle;

  // The lumps that were in memory are not the new ones
  for i := start to finish do
    if lumpcache[i] <> nil then
      Z_Free(lumpcache[i]);

  W_SyncLumpInfo;
end;

var
  pendingwadsfrompak: TDStringList = nil;

//==============================================================================
//
// W_AddPendingWADfromPAK
//
//==============================================================================
procedure W_AddPendingWADfromPAK(const fname: string);
begin
  if pendingwadsfrompak = nil then
    pendingwadsfrompak := TDStringList.Create;
  pendingwadsfrompak.Add(fname);
end;

//==============================================================================
//
// W_Configure
//
//==============================================================================
procedure W_Configure(const AServices: IEngineWadServices);
begin
  wad_services := AServices;
end;

//==============================================================================
//
// W_ConfigureConverter
//
//==============================================================================
procedure W_ConfigureConverter(const AConverter: IEngineWadConverter);
begin
  wad_converter := AConverter;
end;

//==============================================================================
//
// W_InitMultipleFiles
// Pass a null terminated list of files to use.
// All files are optional, but at least one file
//  must be found.
// Files with a .wad extension are idlink files
//  with multiple lumps.
// Other files are single lumps with the base filename
//  for the lump name.
// Lump names can appear multiple times.
// The name searcher looks backwards, so a later file
//  does override all earlier ones.
//
//==============================================================================
function W_InitMultipleFiles(const filenames: TDStringList): integer;
var
  size: integer;
  filename: string;
  i: integer;
begin
  if rtllist <> nil then
    rtllist := TDStringList.Create;

  if wad_services = nil then
    I_Error('W_InitMultipleFiles(): the WAD services were not configured (W_Configure)');
  wad_directory := wad_services.CreateDirectory;
  wad_finder := wad_services.CreateFinder(wad_directory);
  wad_reader := wad_services.CreateReader(wad_directory);
  SetLength(wad_handles, 0);

  // open all the files, load headers, and count lumps
  numlumps := 0;

  for i := 0 to filenames.Count - 1 do
  begin
    filename := filenames[i];
    filenames.Objects[i] := W_AddFile(filename);
    filenames[i] := filename;
  end;

  result := numlumps;

  if result > 0 then
  begin
    // set up caching
    lumpcacherealsize := numlumps + 1024;
    size := lumpcacherealsize * SizeOf(pointer);
    lumpcache := mallocz(size);

    if lumpcache = nil then
      I_Error('W_InitMultipleFiles(): Couldn''t allocate lumpcache');

  end;

  if pendingwadsfrompak <> nil then
  begin
    for i := 0 to pendingwadsfrompak.Count - 1 do
      W_RuntimeLoad(pendingwadsfrompak.Strings[i], F_ORIGIN_PAK);
    pendingwadsfrompak.Clear;
  end;
end;

//==============================================================================
//
// W_ShutDown
//
//==============================================================================
procedure W_ShutDown;
var
  i: integer;
begin
  if pendingwadsfrompak <> nil then
    pendingwadsfrompak.Free;

  memfree(pointer(lumpcache), lumpcacherealsize * SizeOf(pointer));
  memfree(pointer(lumpinfo), lumpinfoalloc * SizeOf(lumpinfo_t));
  lumpinfoalloc := 0;
  wad_reader := nil;
  wad_finder := nil;
  wad_directory := nil;
  SetLength(wad_handles, 0);
  if rtllist <> nil then
  begin
    for i := 0 to rtllist.Count - 1 do
      rtllist.Objects[i].Free;
    rtllist.Free;
  end;
end;

//==============================================================================
//
// W_NumLumps
//
//==============================================================================
function W_NumLumps: integer;
begin
  result := numlumps;
end;

//==============================================================================
//
// W_CheckNumForName
// Returns -1 if name not found.
//
//==============================================================================
function W_CheckNumForName(const name: string; const flags: LongWord = $0): integer;
var
  lname: string;
begin
  lname := name;
  if Length(lname) > 8 then // JVAL: Original an I_Error ocurred. Now we call I_DevError
  begin
    I_Warning('W_CheckNumForName(): name string has more than 8 characters: %s'#13#10, [name]);
    SetLength(lname, 8);
  end;

  // the last lump with the name takes precedence (case insensitive)
  result := wad_finder.CheckNumForName(lname, flags);
end;

//==============================================================================
//
// W_CheckFirstNumForName
//
//==============================================================================
function W_CheckFirstNumForName(const name: string): integer;
var
  lname: string;
begin
  lname := name;
  if Length(lname) > 8 then // JVAL: Original an I_Error ocurred. Now we call I_DevError
  begin
    I_DevError('W_CheckNumForName(): name string has more than 8 characters: %s'#13#10, [name]);
    SetLength(lname, 8);
  end;

  result := wad_finder.CheckFirstNumForName(lname);
end;

//==============================================================================
//
// W_CheckNumForName2
//
//==============================================================================
function W_CheckNumForName2(const name: string; first: integer; last: integer): integer;
var
  lname: string;
begin
  lname := name;
  if Length(lname) > 8 then // JVAL: Original an I_Error ocurred. Now we call I_DevError
  begin
    I_DevError('W_CheckNumForName(): name string has more than 8 characters: %s'#13#10, [name]);
    SetLength(lname, 8);
  end;

  result := wad_finder.CheckNumForNameInRange(lname, first, last);
end;

//==============================================================================
//
// W_GetNumForName
// Calls W_CheckNumForName, but bombs out if not found.
//
//==============================================================================
function W_GetNumForName(const name: string; const flags: LongWord = $0): integer;
begin
  result := W_CheckNumForName(name, flags);
  if result = -1 then
    I_Error('W_GetNumForName(): %s not found!', [name]);
end;

//==============================================================================
//
// W_GetFirstNumForName
//
//==============================================================================
function W_GetFirstNumForName(const name: string): integer;
begin
  result := W_CheckFirstNumForName(name);
  if result = -1 then
    I_Error('W_GetNumForName(): %s not found!', [name]);
end;

//==============================================================================
//
// W_GetNameForNum
//
//==============================================================================
function W_GetNameForNum(const lump: integer): char8_t;
begin
  result := lumpinfo[lump].name;
end;

//==============================================================================
//
// W_LumpFlags
//
//==============================================================================
function W_LumpFlags(const lump: integer): LongWord;
begin
  if (lump < 0) or (lump >= numlumps) then
    I_Error('W_LumpFlags(): %d is not a lump (numlumps = %d)', [lump, numlumps]);

  result := lumpinfo[lump].flags;
end;

//==============================================================================
//
// W_LumpLength
//
//==============================================================================
function W_LumpLength(const lump: integer): integer;
begin
  if lump >= numlumps then
    I_Error('W_LumpLength(): %d >= numlumps', [lump]);

  result := lumpinfo[lump].size;
end;

//==============================================================================
//
// W_LumpCRC32
// The CRC-32 of the bytes of a lump (TCrc32 of Libs\MathCore) in 8 hexadecimal
// digits in lower case; 'DEADDEAD' if lump < 0 (the old GetLumpCRC32 of m_crc32)
//
//==============================================================================
function W_LumpCRC32(const lump: integer): string;
var
  data: pointer;
begin
  if lump < 0 then
  begin
    result := 'DEADDEAD';
    exit;
  end;
  data := W_CacheLumpNum(lump, PU_STATIC);
  result := TCrc32.ToHex(TCrc32.Calculate(data^, W_LumpLength(lump)));
  Z_ChangeTag(data, PU_CACHE);
end;

//==============================================================================
//
// W_ReadLump
// Loads the lump into the given buffer,
//  which must be >= W_LumpLength().
//
//==============================================================================
procedure W_ReadLump(const lump: integer; dest: pointer);
begin
  if lump >= numlumps then
    I_Error('W_ReadLump(): %d >= numlumps', [lump]);

  // straight from the source of the lump into dest: the library checks that the lump is in the file
  try
    wad_reader.ReadLumpInto(lump, dest);
  except
    on E: EWadException do
      I_Error('W_ReadLump(): lump %d: %s', [lump, E.Message]);
  end;
end;

//==============================================================================
//
// W_CacheLumpNum
//
//==============================================================================
function W_CacheLumpNum(const lump: integer; const tag: integer): pointer;
begin
  if lump >= numlumps then
    I_Error('W_CacheLumpNum(): lump = %d, >= numlumps', [lump]);

  if lump < 0 then
    I_Error('W_CacheLumpNum(): lump = %d, < 0', [lump]);

  if lumpcache[lump] = nil then
  begin
    // read the lump in
    //printf ("cache miss on lump %i\n",lump);
    Z_Malloc(W_LumpLength(lump), tag, @lumpcache[lump]);
    W_ReadLump(lump, lumpcache[lump]);
  end
  else
  begin
    //printf ("cache hit on lump %i\n",lump);
    Z_ChangeTag(lumpcache[lump], tag);
  end;

  result := lumpcache[lump];
end;

//==============================================================================
//
// W_CacheLumpName
//
//==============================================================================
function W_CacheLumpName(const name: string; const tag: integer; const flags: LongWord = $0): pointer;
begin
  result := W_CacheLumpNum(W_GetNumForName(name, flags), tag);
end;

//==============================================================================
//
// W_TextLumpNum
//
//==============================================================================
function W_TextLumpNum(const lump: integer): string;
var
  p: PByteArray;
begin
  if lump < 0 then
  begin
    result := '';
    exit;
  end;

  p := W_CacheLumpNum(lump, PU_STATIC);
  // one character per byte, a #0 is a space (TWadLumpText of Libs\Wad)
  result := TWadLumpText.FromBuffer(p, W_LumpLength(lump));

  Z_Free(p);
end;

//==============================================================================
//
// W_TextLumpName
//
//==============================================================================
function W_TextLumpName(const name: string): string;
begin
  result := W_TextLumpNum(W_GetNumForName(name));
end;

end.
