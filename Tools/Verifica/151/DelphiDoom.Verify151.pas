{******************************************************************************}
{                                                                              }
{  TEMPORARY harness of issue #151 (not committed to the engine projects):     }
{  fingerprints of the level data and of the zone, to compare the engine       }
{  before and after the move of the level loading to IEngineLumps and          }
{  IZoneAllocator. Never compiled by the author: see RUN.md.                   }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Verify151;

interface

/// <summary>
///   Writes verify151_&lt;tag&gt;.txt in the current directory: counts and FNV-1a fingerprints
///   of the level structures that P_SetupLevel built (only fields that do not hold addresses),
///   and the statistics of the zone. Call it right after a level is loaded
/// </summary>
procedure V151_DumpLevel(const ATag: string);

/// <summary>
///   Appends the number of a lump to verify151_lumps.txt: put a call at the start of
///   W_ReadLump (the same patch on the old and on the new tree)
/// </summary>
procedure V151_TraceLump(ALump: Integer);

implementation

uses
  System.SysUtils,
  System.Classes,
  d_delphi,
  r_defs,
  p_setup,
  z_zone;

var
  GFnv: Cardinal;
  GOutput: TStringList;

procedure FnvReset;
begin
  GFnv := $811C9DC5;
end;

procedure FnvInt(AValue: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
  begin
    GFnv := (GFnv xor Cardinal((AValue shr (8 * LIndex)) and $FF)) * 16777619;
  end;
end;

procedure FnvBytes(const ABuffer: Pointer; ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ACount - 1 do
    GFnv := (GFnv xor PByte(ABuffer)[LIndex]) * 16777619;
end;

procedure Line(const AName: string; ACount: Integer);
begin
  GOutput.Add(Format('%s count=%d fnv=%.8x', [AName, ACount, GFnv]));
end;

procedure V151_DumpLevel(const ATag: string);
var
  LIndex: Integer;
begin
  GOutput := TStringList.Create;
  try
    FnvReset;
    for LIndex := 0 to numvertexes - 1 do
    begin
      FnvInt(vertexes[LIndex].x);
      FnvInt(vertexes[LIndex].y);
    end;
    Line('vertexes', numvertexes);

    FnvReset;
    for LIndex := 0 to numsectors - 1 do
    begin
      FnvInt(sectors[LIndex].floorheight);
      FnvInt(sectors[LIndex].ceilingheight);
      FnvInt(sectors[LIndex].lightlevel);
      FnvInt(sectors[LIndex].special);
      FnvInt(sectors[LIndex].tag);
    end;
    Line('sectors', numsectors);

    FnvReset;
    for LIndex := 0 to numlines - 1 do
    begin
      FnvInt(lines[LIndex].dx);
      FnvInt(lines[LIndex].dy);
      FnvInt(lines[LIndex].flags);
      FnvInt(lines[LIndex].special);
    end;
    Line('lines', numlines);

    FnvReset;
    for LIndex := 0 to numsides - 1 do
    begin
      FnvInt(sides[LIndex].textureoffset);
      FnvInt(sides[LIndex].rowoffset);
    end;
    Line('sides', numsides);

    FnvReset;
    for LIndex := 0 to numsubsectors - 1 do
    begin
      FnvInt(subsectors[LIndex].numlines);
      FnvInt(subsectors[LIndex].firstline);
    end;
    Line('subsectors', numsubsectors);

    FnvReset;
    for LIndex := 0 to numnodes - 1 do
    begin
      FnvInt(nodes[LIndex].x);
      FnvInt(nodes[LIndex].y);
      FnvInt(nodes[LIndex].dx);
      FnvInt(nodes[LIndex].dy);
    end;
    Line('nodes', numnodes);

    FnvReset;
    if (rejectmatrix <> nil) and (rejectmatrixsize > 0) then
      FnvBytes(rejectmatrix, rejectmatrixsize);
    Line('reject', rejectmatrixsize);

    FnvReset;
    FnvInt(bmapwidth);
    FnvInt(bmapheight);
    FnvInt(bmaporgx);
    FnvInt(bmaporgy);
    if blockmaplump <> nil then
      for LIndex := 0 to 3 + bmapwidth * bmapheight do
        FnvInt(blockmaplump[LIndex]);
    Line('blockmap', bmapwidth * bmapheight);

    GOutput.SaveToFile('verify151_' + ATag + '.txt');
  finally
    GOutput.Free;
    GOutput := nil;
  end;
end;

procedure V151_TraceLump(ALump: Integer);
var
  LFile: TextFile;
begin
  AssignFile(LFile, 'verify151_lumps.txt');
  if FileExists('verify151_lumps.txt') then
    Append(LFile)
  else
    Rewrite(LFile);
  Writeln(LFile, ALump);
  CloseFile(LFile);
end;

end.
