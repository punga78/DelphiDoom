unit d_disk;
// stub of the harness: the lump cache of the original, read from the archive of the library (already checked against
// the original d_disk by the golden files of the data). A freed lump leaves the cache and is read again when asked
interface
uses SysUtils, DelphiDoom.Greed.Intf;
type
  lumpcache_t = record
    data: Pointer;
    usage: Boolean;
  end;
  lumpinfo_t = record
    size: LongWord;
  end;
var
  DiskArchive: IGreedArchive;
  lumpcache: array[0..$FFF] of lumpcache_t;
  infotable: array[0..$FFF] of lumpinfo_t;
  DISKPAL: packed array[0..767] of byte;
procedure CA_InitFromArchive(const AArchive: IGreedArchive);
function CA_CacheLump(const lump: integer): pointer;
function CA_CachePalette(const lump: integer): pointer;
function CA_GetNamedNum(const name: string): integer;
function CA_CheckNamedNum(const name: string): integer;
procedure CA_ReadLump(const lump: integer; const buffer: pointer);
procedure CA_FreeLump(const lump: integer);
procedure CA_FlushAll;
implementation
type
  TByteArr = array[0..$FFFFFF] of byte;
  PByteArr = ^TByteArr;
procedure CA_InitFromArchive(const AArchive: IGreedArchive);
var i: integer;
begin
  DiskArchive := AArchive;
  for i := 0 to AArchive.LumpCount - 1 do
    infotable[i].size := AArchive.GetLumpSize(i);
end;
function CA_CacheLump(const lump: integer): pointer;
var b: TBytes;
begin
  if (lumpcache[lump].data = nil) and (infotable[lump].size > 0) then
  begin
    b := DiskArchive.ReadLump(lump);
    GetMem(lumpcache[lump].data, Length(b) + 4096);
    FillChar(lumpcache[lump].data^, Length(b) + 4096, 0);
    if Length(b) > 0 then Move(b[0], lumpcache[lump].data^, Length(b));
  end;
  Result := lumpcache[lump].data;
end;
function CA_CachePalette(const lump: integer): pointer;
var
  p: PByteArr;
  i: integer;
begin
  p := CA_CacheLump(lump);
  for i := 0 to 767 do
    DISKPAL[i] := byte(p[i] * 4);
  result := @DISKPAL;
end;
function CA_GetNamedNum(const name: string): integer;
begin
  Result := DiskArchive.RequireIndexOf(name);
end;
function CA_CheckNamedNum(const name: string): integer;
begin
  Result := DiskArchive.IndexOf(name);
end;
procedure CA_ReadLump(const lump: integer; const buffer: pointer);
var b: TBytes;
begin
  b := DiskArchive.ReadLump(lump);
  if Length(b) > 0 then Move(b[0], buffer^, Length(b));
end;
procedure CA_FreeLump(const lump: integer);
begin
  lumpcache[lump].data := nil;
end;
procedure CA_FlushAll;
var i: integer;
begin
  for i := 0 to High(lumpcache) do
    lumpcache[i].data := nil;
end;
end.
