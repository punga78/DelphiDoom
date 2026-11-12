unit d_disk;
// stub of the harness: the names and the texts of the lumps come from the program (the scenarios or the archive of
// the complete game); cachehandle is a real file, opened by the program, where event.pas reads the sky
interface
uses d_video;
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
  // the pictures that CA_CacheLump gives: only their size, which the program decides
  DiskPictureWidth, DiskPictureHeight: function(const lump: integer): integer;
  pictures: array[0..$FFF] of pic_t;
function CA_CacheLump(const lump: integer): pointer;
procedure CA_FreeLump(const lump: integer);
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
function CA_CacheLump(const lump: integer): pointer;
begin
  pictures[lump].width := DiskPictureWidth(lump);
  pictures[lump].height := DiskPictureHeight(lump);
  Result := @pictures[lump];
end;
procedure CA_FreeLump(const lump: integer);
begin
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
