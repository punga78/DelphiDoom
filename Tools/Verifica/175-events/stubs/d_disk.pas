unit d_disk;
// stub of the harness: the names and the texts of the lumps come from the program (the scenarios or the archive of
// the complete game); cachehandle is a real file, opened by the program, where event.pas reads the sky
interface
type
  lumpinfo_t = packed record
    filepos: integer;
    size: LongWord;
    nameofs: smallint;
    compress: smallint;
  end;
var
  infotable: array[0..$FFF] of lumpinfo_t;
  cachehandle: file;
  DiskNumber: function(const name: string): integer;
  DiskText: function(const lump: integer): AnsiString;
function CA_GetNamedNum(const name: string): integer;
function CA_LumpName(const lump: integer): string;
function CA_LumpAsText(const lump: integer): string;
function CA_FileAsText(const fname: string): string;
// MS_CheckParm of d_misc.pas: the program has no parameters
function MS_CheckParm(const check: string): integer;
implementation
uses d_misc;
function CA_GetNamedNum(const name: string): integer;
begin
  Result := DiskNumber(name);
  if Result < 0 then
    MS_Error('CA_GetNamedNum: %s not found!', [name]);
end;
function CA_LumpName(const lump: integer): string;
begin
  Result := '';
end;
function CA_LumpAsText(const lump: integer): string;
begin
  Result := string(DiskText(lump));
end;
function CA_FileAsText(const fname: string): string;
begin
  Result := '';
end;
function MS_CheckParm(const check: string): integer;
begin
  Result := 0;
end;
end.
