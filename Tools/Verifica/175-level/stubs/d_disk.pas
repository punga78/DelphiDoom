unit d_disk;
// stub of the harness: no lumps; the names that are asked and the reads go in the trace
interface
uses SysUtils;
type
  lumpcache_t = record
    data: Pointer;
    usage: Boolean;
  end;
  lumpinfo_t = record
    size: LongWord;
  end;
var
  lumpcache: array[0..$FFF] of lumpcache_t;
  infotable: array[0..$FFF] of lumpinfo_t;
function CA_CacheLump(const lump: integer): pointer;
function CA_GetNamedNum(const name: string): integer;
procedure CA_ReadLump(const lump: integer; const buffer: pointer);
function CA_CachePalette(const lump: integer): pointer;
implementation
uses harness_level;
function CA_CacheLump(const lump: integer): pointer; begin Result := lumpcache[lump].data; end;
function CA_GetNamedNum(const name: string): integer;
begin
  HarnessTrace.AddText(name, 'CA_GetNamedNum');
  Result := 0;
end;
procedure CA_ReadLump(const lump: integer; const buffer: pointer);
begin
  HarnessTrace.Call('CA_ReadLump', []);
end;
function CA_CachePalette(const lump: integer): pointer; begin Result := nil; end;
end.
