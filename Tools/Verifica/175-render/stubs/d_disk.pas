unit d_disk;
// stub of the harness: the lump cache of the original, read from the archive of the library (already checked against
// the original d_disk by the golden files of the data)
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
procedure CA_InitFromArchive(const AArchive: IGreedArchive);
function CA_CacheLump(const lump: integer): pointer;
function CA_GetNamedNum(const name: string): integer;
procedure CA_ReadLump(const lump: integer; const buffer: pointer);
implementation
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
function CA_GetNamedNum(const name: string): integer;
begin
  Result := DiskArchive.RequireIndexOf(name);
end;
procedure CA_ReadLump(const lump: integer; const buffer: pointer);
var b: TBytes;
begin
  b := DiskArchive.ReadLump(lump);
  if Length(b) > 0 then Move(b[0], buffer^, Length(b));
end;
end.
