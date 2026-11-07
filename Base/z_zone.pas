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
//      Zone Memory Allocation, perhaps NeXT ObjectiveC inspired.
//  Remark: this was the only stuff that, according
//   to John Carmack, might have been useful for
//   Quake.
//  The allocator is the class TZoneAllocator of Libs\Zone, given by
//  the composition root (Z_ConfigureZone): the functions here are
//  its facade for the rest of the engine.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit z_zone;

interface

uses
  d_delphi,
  DelphiDoom.Zone.Intf,
  DelphiDoom.Zone.Types;

//
// ZONE MEMORY
// PU - purge tags.
// Tags < 100 are not overwritten until freed.

const
  PU_LOTAG = 1;
  PU_STATIC = ZONE_TAG_STATIC;    // static entire execution time
  PU_SOUND = ZONE_TAG_SOUND;      // static while playing
  PU_MUSIC = ZONE_TAG_MUSIC;      // static while playing
  PU_DAVE = ZONE_TAG_DAVE;        // anything else Dave wants static
  PU_LEVEL = ZONE_TAG_LEVEL;      // static until level exited
  PU_LEVSPEC = ZONE_TAG_LEVSPEC;  // a special thinker in a level
  // Tags >= 100 are purgable whenever needed.
  PU_PURGELEVEL = ZONE_TAG_PURGELEVEL;
  PU_CACHE = ZONE_TAG_CACHE;
  PU_HITAG = 101;

//==============================================================================
//
// Z_ConfigureZone
// Gives the allocator (the composition root does it, before anything allocates).
//
//==============================================================================
procedure Z_ConfigureZone(const AAllocator: IZoneAllocator);

//==============================================================================
//
// Z_Init
//
//==============================================================================
procedure Z_Init;

//==============================================================================
//
// Z_ShutDown
//
//==============================================================================
procedure Z_ShutDown;

//==============================================================================
//
// Z_Malloc
//
//==============================================================================
function Z_Malloc(size: integer; tag: integer; user: pointer): pointer;

//==============================================================================
//
// Z_Malloc2
//
//==============================================================================
function Z_Malloc2(size: integer; tag: integer; user: pointer): pointer;

//==============================================================================
//
// Z_Realloc
//
//==============================================================================
function Z_Realloc(ptr: pointer; size: integer; tag: integer; user: pointer): pointer;

//==============================================================================
//
// Z_Free
//
//==============================================================================
procedure Z_Free(ptr: pointer);

//==============================================================================
//
// Z_Size
//
//==============================================================================
function Z_Size(ptr: pointer): integer;

//==============================================================================
//
// Z_FreeTags
//
//==============================================================================
function Z_FreeTags(lowtag: integer; hightag: integer): boolean;

//==============================================================================
//
// Z_MoveUsers
// A table of user pointers has been moved: the blocks follow it.
//
//==============================================================================
procedure Z_MoveUsers(oldstart: pointer; bytecount: integer; newstart: pointer);

//==============================================================================
//
// Z_DumpHeap
//
//==============================================================================
procedure Z_DumpHeap(lowtag: integer; hightag: integer);

//==============================================================================
//
// Z_FileDumpHeapf
//
//==============================================================================
procedure Z_FileDumpHeapf(var f: file);

//==============================================================================
//
// Z_FileDumpHeap
//
//==============================================================================
procedure Z_FileDumpHeap(const filename: string);

//==============================================================================
//
// Z_CheckMemory
//
//==============================================================================
procedure Z_CheckMemory;

//==============================================================================
//
// Z_CheckHeap
//
//==============================================================================
procedure Z_CheckHeap;

//==============================================================================
//
// Z_ChangeTag
//
//==============================================================================
procedure Z_ChangeTag(ptr: pointer; tag: integer);

implementation

uses
  c_cmds,
  i_system;

var
  // given by the composition root (Z_ConfigureZone)
  zone_allocator: IZoneAllocator = nil;

//==============================================================================
//
// Z_NotConfigured
//
//==============================================================================
procedure Z_NotConfigured;
begin
  I_Error('Z_ConfigureZone(): the zone allocator was not given');
end;

//==============================================================================
//
// Z_ConfigureZone
//
//==============================================================================
procedure Z_ConfigureZone(const AAllocator: IZoneAllocator);
begin
  zone_allocator := AAllocator;
end;

//==============================================================================
//
// Z_CmdZoneMem
//
//==============================================================================
procedure Z_CmdZoneMem;
var
  stat: TZoneStatistics;
begin
  if zone_allocator = nil then
    Z_NotConfigured;
  stat := zone_allocator.Statistics;
  printf('%6d      blocks allocated in the zone.'#13#10, [stat.BlockCount]);
  printf('%6d KB memory taken by the zone, headers included.'#13#10, [stat.TotalBytes div 1024]);
  printf('%6d KB zone memory used for static memory allocation.'#13#10, [(stat.TotalBytes - stat.PurgableBytes) div 1024]);
  printf('%6d KB zone memory used for cache.'#13#10, [stat.PurgableBytes div 1024]);
end;

//==============================================================================
//
// Z_CmdMem
//
//==============================================================================
procedure Z_CmdMem;
var
  imgsize: integer;
begin
  imgsize := I_GetExeImageSize;
  printf('%6d KB total memory in use.'#13#10, [(memoryusage + imgsize) div 1024]);
  printf('%6d KB program image size.'#13#10, [imgsize div 1024]);
  {$IFNDEF FPC}
  printf('%6d KB program memory allocation.'#13#10, [GetAllocMemSize div 1024]);
  {$ENDIF}
  printf('%6d KB total memory dynamically allocated.'#13#10, [memoryusage div 1024]);
  printf(#13#10);
  Z_CmdZoneMem;
end;

//==============================================================================
//
// Z_CmdZoneMemDump
//
//==============================================================================
procedure Z_CmdZoneMemDump(const parm1, parm2: string);
var
  lowtag: integer;
  hightag: integer;
begin
  if parm1 <> '' then
  begin
    lowtag := atoi(parm1);
    if parm2 = '' then
      hightag := lowtag
    else
      hightag := atoi(parm2);
    if hightag < lowtag then
      Z_DumpHeap(hightag, lowtag)
    else
      Z_DumpHeap(lowtag, hightag);
  end
  else
    Z_DumpHeap(PU_LOTAG, PU_HITAG);
end;

//==============================================================================
//
// Z_Init
//
//==============================================================================
procedure Z_Init;
begin
  if zone_allocator = nil then
    Z_NotConfigured;

  C_AddCmd('mem', @Z_CmdMem);
  C_AddCmd('zonemem', @Z_CmdZoneMem);
  C_AddCmd('zonedump', @Z_CmdZoneMemDump);
  C_AddCmd('zonefiledump', @Z_FileDumpHeap);
end;

//==============================================================================
//
// Z_ShutDown
//
//==============================================================================
procedure Z_ShutDown;
begin
  zone_allocator := nil;
end;

//==============================================================================
//
// Z_Free
//
//==============================================================================
procedure Z_Free(ptr: pointer);
begin
  if zone_allocator = nil then
    Z_NotConfigured;
  try
    zone_allocator.FreeBlock(ptr);
  except
    on E: EZoneException do
      I_Error('Z_Free(): %s', [E.Message]);
  end;
end;

//==============================================================================
//
// Z_Size
//
//==============================================================================
function Z_Size(ptr: pointer): integer;
begin
  if zone_allocator = nil then
    Z_NotConfigured;
  try
    result := zone_allocator.BlockSize(ptr);
  except
    on E: EZoneException do
    begin
      result := 0;
      I_Error('Z_Size(): %s', [E.Message]);
    end;
  end;
end;

//==============================================================================
//
// Z_Malloc
// You can pass a NULL user if the tag is < PU_PURGELEVEL.
//
//==============================================================================
function Z_Malloc(size: integer; tag: integer; user: pointer): pointer;
begin
  if zone_allocator = nil then
    Z_NotConfigured;
  result := zone_allocator.Allocate(size, tag, System.PPointer(user));
end;

//==============================================================================
//
// Z_Malloc2
//
//==============================================================================
function Z_Malloc2(size: integer; tag: integer; user: pointer): pointer;
begin
  if zone_allocator = nil then
    Z_NotConfigured;
  result := zone_allocator.Allocate(size, tag, System.PPointer(user));
end;

//==============================================================================
//
// Z_Realloc
//
//==============================================================================
function Z_Realloc(ptr: pointer; size: integer; tag: integer; user: pointer): pointer;
begin
  if zone_allocator = nil then
    Z_NotConfigured;
  try
    result := zone_allocator.Reallocate(ptr, size, tag, System.PPointer(user));
  except
    on E: EZoneException do
    begin
      result := nil;
      I_Error('Z_Realloc(): %s', [E.Message]);
    end;
  end;
end;

//==============================================================================
//
// Z_FreeTags
//
//==============================================================================
function Z_FreeTags(lowtag: integer; hightag: integer): boolean;
begin
  if zone_allocator = nil then
    Z_NotConfigured;
  zone_allocator.FreeTags(lowtag, hightag);
  result := True;
end;

//==============================================================================
//
// Z_MoveUsers
//
//==============================================================================
procedure Z_MoveUsers(oldstart: pointer; bytecount: integer; newstart: pointer);
begin
  if zone_allocator = nil then
    Z_NotConfigured;
  zone_allocator.MoveUsers(oldstart, bytecount, newstart);
end;

//==============================================================================
//
// Z_DumpHeap
//
//==============================================================================
procedure Z_DumpHeap(lowtag: integer; hightag: integer);
var
  lines: TArray<string>;
  i: integer;
begin
  if zone_allocator = nil then
    Z_NotConfigured;
  lines := zone_allocator.Describe(lowtag, hightag);
  for i := 0 to Length(lines) - 1 do
    printf('%s'#13#10, [lines[i]]);
end;

//==============================================================================
//
// Z_FileDumpHeapf
//
//==============================================================================
procedure Z_FileDumpHeapf(var f: file);
var
  lines: TArray<string>;
  i: integer;
begin
  if zone_allocator = nil then
    Z_NotConfigured;
  lines := zone_allocator.Describe(Low(integer), High(integer));
  for i := 0 to Length(lines) - 1 do
    fprintf(f, '%s'#13#10, [lines[i]]);
end;

//==============================================================================
//
// Z_FileDumpHeap
//
//==============================================================================
procedure Z_FileDumpHeap(const filename: string);
var
  f: file;
begin
  if filename = '' then
  begin
    printf('Please specify the filename to dump the Zone Heap'#13#10);
    exit;
  end;

  if fopen(f, filename, fCreate) then
  begin
    Z_FileDumpHeapf(f);
    close(f);
  end
  else
    I_Warning('Z_FileDumpHeap(): Can not create output file: %s'#13#10, [filename]);
end;

//==============================================================================
//
// Z_CheckMemory
//
//==============================================================================
procedure Z_CheckMemory;
begin
  if zone_allocator = nil then
    Z_NotConfigured;
  try
    zone_allocator.CheckUsers;
  except
    on E: EZoneException do
      I_Error('Z_CheckMemory(): %s', [E.Message]);
  end;
end;

//==============================================================================
//
// Z_CheckHeap
//
//==============================================================================
procedure Z_CheckHeap;
begin
  if zone_allocator = nil then
    Z_NotConfigured;
  try
    zone_allocator.CheckHeap;
  except
    on E: EZoneException do
      I_Error('Z_CheckHeap(): %s', [E.Message]);
  end;
end;

//==============================================================================
//
// Z_ChangeTag
//
//==============================================================================
procedure Z_ChangeTag(ptr: pointer; tag: integer);
begin
  if zone_allocator = nil then
    Z_NotConfigured;
  try
    zone_allocator.ChangeTag(ptr, tag);
  except
    on E: EZoneException do
      I_Error('Z_ChangeTag(): %s', [E.Message]);
  end;
end;

end.
