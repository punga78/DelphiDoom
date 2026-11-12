unit d_disk;
// stub of the harness: CA_GetNamedNum gives the number of the scenarios, CA_CacheLump writes down which lumps
// DemandLoadMonster asks for and gives an empty picture
interface
type
  lumpcache_t = record
    data: Pointer;
    usage: Boolean;
  end;
var
  lumpcache: array[0..$7FFF] of lumpcache_t;
  cachedlumps: array[0..255] of integer;
  numcachedlumps: integer = 0;
function CA_CacheLump(const lump: integer): pointer;
function CA_GetNamedNum(const name: string): integer;
procedure CA_ForgetLumps;
implementation
uses DelphiDoom.Tests.Greed.SpawnScenarios;
var
  emptypic: array[0..1023] of byte;
function CA_CacheLump(const lump: integer): pointer;
begin
  cachedlumps[numcachedlumps] := lump;
  inc(numcachedlumps);
  lumpcache[lump].data := @emptypic;
  Result := lumpcache[lump].data;
end;
function CA_GetNamedNum(const name: string): integer;
begin
  Result := TSpawnScenarios.LumpNumber(name);
end;
procedure CA_ForgetLumps;
var i: integer;
begin
  for i := 0 to numcachedlumps - 1 do
    lumpcache[cachedlumps[i]].data := nil;
  numcachedlumps := 0;
end;
end.
