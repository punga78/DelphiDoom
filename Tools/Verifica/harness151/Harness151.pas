{******************************************************************************}
{                                                                              }
{  TEMPORARY HARNESS of issues #151 and #156 (never part of the engine         }
{  projects): the same unit is compiled in the old tree (31ee71e3) and in the  }
{  new one, with the same two hooks, so that the files it writes can be        }
{  compared line by line.                                                      }
{                                                                              }
{    V151_TraceLump  at the first line of W_ReadLump                           }
{    V151_AfterLevel at the end of TLevelLoader.SetupLevel                     }
{                                                                              }
{  Active only with  -verify151 <n>  on the command line: after the n-th       }
{  level has been loaded it writes the files and ends with Halt(0).            }
{  Files (current directory):                                                  }
{    verify151_lumps.txt      lump numbers in the order W_ReadLump got them,   }
{                             with a "# level <name>" line after each level    }
{    verify151_<MAP>.txt      count and FNV-1a of every level structure,       }
{                             then DUMP156 (map_length / inv_length of segs)   }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
{$Q-}
{$R-}
unit Harness151;

interface

procedure V151_TraceLump(ALump: Integer);

procedure V151_AfterLevel(const AMapName: string);

implementation

uses
  SysUtils,
  Classes,
  r_defs,
  p_setup;

var
  GFnv: Cardinal;
  GLines: TStringList = nil;
  GTrace: TStringList = nil;
  GEnabled: Boolean = False;
  GLevels: Integer = 0;
  GLimit: Integer = 1;

procedure FnvReset;
begin
  GFnv := $811C9DC5;
end;

procedure FnvByte(AValue: Byte);
begin
  GFnv := (GFnv xor AValue) * 16777619;
end;

procedure FnvInt(AValue: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    FnvByte(Byte((AValue shr (8 * LIndex)) and $FF));
end;

procedure FnvDouble(AValue: Double);
var
  LBytes: PByteArray;
  LIndex: Integer;
begin
  LBytes := PByteArray(@AValue);
  for LIndex := 0 to SizeOf(Double) - 1 do
    FnvByte(LBytes[LIndex]);
end;

// index of a pointer inside an array of records, or -1 (a nil or foreign pointer)
function IndexOfRecord(APointer: Pointer; ABase: Pointer; ASize: Integer; ACount: Integer): Integer;
var
  LDelta: NativeInt;
begin
  Result := -1;
  if (APointer = nil) or (ABase = nil) then
    Exit;
  LDelta := NativeInt(APointer) - NativeInt(ABase);
  if (LDelta < 0) or (LDelta mod ASize <> 0) then
    Exit;
  LDelta := LDelta div ASize;
  if LDelta < ACount then
    Result := Integer(LDelta);
end;

procedure Line(const AName: string; ACount: Integer);
begin
  GLines.Add(Format('%s count=%d fnv=%.8x', [AName, ACount, GFnv]));
end;

procedure DumpStructures;
var
  LIndex: Integer;
  LCell: Integer;
  LPos: Integer;
  LSteps: Integer;
begin
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
    FnvInt(sectors[LIndex].floorpic);
    FnvInt(sectors[LIndex].ceilingpic);
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
{$IFDEF HEXEN}
    FnvInt(lines[LIndex].arg1);
    FnvInt(lines[LIndex].arg2);
    FnvInt(lines[LIndex].arg3);
    FnvInt(lines[LIndex].arg4);
    FnvInt(lines[LIndex].arg5);
{$ELSE}
    FnvInt(lines[LIndex].tag);
{$ENDIF}
    FnvInt(lines[LIndex].sidenum[0]);
    FnvInt(lines[LIndex].sidenum[1]);
    FnvInt(IndexOfRecord(lines[LIndex].v1, vertexes, SizeOf(vertex_t), numvertexes));
    FnvInt(IndexOfRecord(lines[LIndex].v2, vertexes, SizeOf(vertex_t), numvertexes));
  end;
  Line('lines', numlines);

  FnvReset;
  for LIndex := 0 to numsides - 1 do
  begin
    FnvInt(sides[LIndex].textureoffset);
    FnvInt(sides[LIndex].rowoffset);
    FnvInt(sides[LIndex].toptexture);
    FnvInt(sides[LIndex].bottomtexture);
    FnvInt(sides[LIndex].midtexture);
    FnvInt(IndexOfRecord(sides[LIndex].sector, sectors, SizeOf(sector_t), numsectors));
  end;
  Line('sides', numsides);

  FnvReset;
  for LIndex := 0 to numsubsectors - 1 do
  begin
    FnvInt(subsectors[LIndex].numlines);
    FnvInt(subsectors[LIndex].firstline);
    FnvInt(IndexOfRecord(subsectors[LIndex].sector, sectors, SizeOf(sector_t), numsectors));
  end;
  Line('subsectors', numsubsectors);

  FnvReset;
  for LIndex := 0 to numnodes - 1 do
  begin
    FnvInt(nodes[LIndex].x);
    FnvInt(nodes[LIndex].y);
    FnvInt(nodes[LIndex].dx);
    FnvInt(nodes[LIndex].dy);
    for LCell := 0 to 7 do
      FnvInt(nodes[LIndex].bbox[LCell div 4, LCell mod 4]);
    FnvInt(Integer(nodes[LIndex].children[0]));
    FnvInt(Integer(nodes[LIndex].children[1]));
  end;
  Line('nodes', numnodes);

  FnvReset;
  if (rejectmatrix <> nil) and (rejectmatrixsize > 0) then
    for LIndex := 0 to rejectmatrixsize - 1 do
      FnvByte(rejectmatrix[LIndex]);
  Line('reject', rejectmatrixsize);

  // header, offsets and the lists (each ends with -1; a cap protects from a damaged map)
  FnvReset;
  FnvInt(bmapwidth);
  FnvInt(bmapheight);
  FnvInt(bmaporgx);
  FnvInt(bmaporgy);
  FnvInt(Ord(internalblockmapformat));
  if (blockmaplump <> nil) and (blockmap <> nil) then
  begin
    for LIndex := 0 to 3 do
      FnvInt(blockmaplump[LIndex]);
    for LCell := 0 to bmapwidth * bmapheight - 1 do
    begin
      LPos := blockmap[LCell];
      FnvInt(LPos);
      LSteps := 0;
      while (LPos >= 0) and (LSteps < 4096) do
      begin
        FnvInt(blockmaplump[LPos]);
        if blockmaplump[LPos] = -1 then
          Break;
        Inc(LPos);
        Inc(LSteps);
      end;
    end;
  end;
  Line('blockmap', bmapwidth * bmapheight);

  // topology of the segs: pointers become indexes
  FnvReset;
  for LIndex := 0 to numsegs - 1 do
  begin
    FnvInt(segs[LIndex].offset);
    FnvInt(Integer(segs[LIndex].angle));
    FnvInt(IndexOfRecord(segs[LIndex].v1, vertexes, SizeOf(vertex_t), numvertexes));
    FnvInt(IndexOfRecord(segs[LIndex].v2, vertexes, SizeOf(vertex_t), numvertexes));
    FnvInt(IndexOfRecord(segs[LIndex].sidedef, sides, SizeOf(side_t), numsides));
    FnvInt(IndexOfRecord(segs[LIndex].linedef, lines, SizeOf(line_t), numlines));
    FnvInt(IndexOfRecord(segs[LIndex].frontsector, sectors, SizeOf(sector_t), numsectors));
    FnvInt(IndexOfRecord(segs[LIndex].backsector, sectors, SizeOf(sector_t), numsectors));
    FnvInt(Ord(segs[LIndex].miniseg));
  end;
  Line('segs-topology', numsegs);

{$IFNDEF OPENGL}
  // issue 156: only the two fields that R_PrecalcSegs writes (same as Tools\Verifica\156\LevelDump.txt)
  FnvReset;
  for LIndex := 0 to numsegs - 1 do
  begin
    FnvInt(segs[LIndex].map_length);
    FnvDouble(segs[LIndex].inv_length);
  end;
  GLines.Add(Format('DUMP156 segs=%d fnv=%.8x', [numsegs, GFnv]));
{$ELSE}
  GLines.Add('DUMP156 not available (OPENGL has no R_PrecalcSegs)');
{$ENDIF}
end;

procedure V151_TraceLump(ALump: Integer);
begin
  if GEnabled then
    GTrace.Add(IntToStr(ALump));
end;

procedure V151_AfterLevel(const AMapName: string);
begin
  if not GEnabled then
    Exit;
  Inc(GLevels);
  GLines := TStringList.Create;
  try
    DumpStructures;
    GLines.SaveToFile('verify151_' + AMapName + '.txt');
  finally
    GLines.Free;
    GLines := nil;
  end;
  GTrace.Add('# level ' + AMapName);
  GTrace.SaveToFile('verify151_lumps.txt');
  if GLevels >= GLimit then
    Halt(0);
end;

procedure Initialize;
var
  LIndex: Integer;
begin
  for LIndex := 1 to ParamCount do
    if SameText(ParamStr(LIndex), '-verify151') then
    begin
      GEnabled := True;
      if LIndex < ParamCount then
        GLimit := StrToIntDef(ParamStr(LIndex + 1), 1);
      if GLimit < 1 then
        GLimit := 1;
    end;
  if GEnabled then
  begin
    GTrace := TStringList.Create;
    GTrace.Capacity := 65536;
  end;
end;

initialization
  Initialize;

end.
