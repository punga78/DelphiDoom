{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the blockmap library - the levels of the golden files  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Blockmap.Cases;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  DelphiDoom.Blockmap.Types;

type
  /// <summary>
  ///   A level as the engine had it, and what the old code of the engine (P_CreateBlockMap and
  ///   P_RemoveSlimeTrails) made of it. Tests\Data\Blockmap\*.bmcase are 32 bit little endian
  ///   numbers: the magic $31434D42, the counts of vertexes, lines and segs, the vertexes (x, y),
  ///   the lines (x1, y1, x2, y2), the segs (vertex 1, vertex 2, miniseg, line vertex 1, line
  ///   vertex 2, line dx, line dy), then columns, rows and size of the blockmap, its fingerprint
  ///   (low, high) and the fingerprint of the vertexes after the slime trails (low, high)
  /// </summary>
  TBlockmapCase = class sealed
  public
    Name: string;
    Vertexes: TArray<TBlockmapPoint>;
    Lines: TArray<TBlockmapLine>;
    Segs: TArray<TBlockmapSeg>;
    Columns: Integer;
    Rows: Integer;
    LumpSize: Integer;
    BlockmapFingerprint: UInt64;
    SlimeFingerprint: UInt64;
    class function DataDir: string; static;
    /// <summary>Names of the files of the cases, without the folder</summary>
    class function FileNames: TArray<string>; static;
    class function Load(const AFileName: string): TBlockmapCase; static;
  end;

implementation

{ TBlockmapCase }

class function TBlockmapCase.DataDir: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Blockmap\'));
end;

class function TBlockmapCase.FileNames: TArray<string>;
var
  LPaths: TArray<string>;
  LIndex: Integer;
begin
  if not TDirectory.Exists(DataDir) then
    Exit(nil);
  LPaths := TDirectory.GetFiles(DataDir, '*.bmcase');
  SetLength(Result, Length(LPaths));
  for LIndex := 0 to High(LPaths) do
    Result[LIndex] := TPath.GetFileName(LPaths[LIndex]);
  TArray.Sort<string>(Result);
end;

class function TBlockmapCase.Load(const AFileName: string): TBlockmapCase;
var
  LBytes: TBytes;
  LPosition: Integer;

  function Next: Integer;
  begin
    Result := PInteger(@LBytes[LPosition])^;
    Inc(LPosition, 4);
  end;

var
  LVertexCount, LLineCount, LSegCount, LIndex: Integer;
  LLow, LHigh: Cardinal;
begin
  LBytes := TFile.ReadAllBytes(TPath.Combine(DataDir, AFileName));
  LPosition := 0;
  Result := TBlockmapCase.Create;
  try
    Result.Name := TPath.GetFileNameWithoutExtension(AFileName);
    if Next <> $31434D42 then
      raise Exception.CreateFmt('%s is not a case of the blockmap tests', [AFileName]);
    LVertexCount := Next;
    LLineCount := Next;
    LSegCount := Next;
    SetLength(Result.Vertexes, LVertexCount);
    for LIndex := 0 to LVertexCount - 1 do
    begin
      Result.Vertexes[LIndex].X := Next;
      Result.Vertexes[LIndex].Y := Next;
    end;
    SetLength(Result.Lines, LLineCount);
    for LIndex := 0 to LLineCount - 1 do
    begin
      Result.Lines[LIndex].X1 := Next;
      Result.Lines[LIndex].Y1 := Next;
      Result.Lines[LIndex].X2 := Next;
      Result.Lines[LIndex].Y2 := Next;
    end;
    SetLength(Result.Segs, LSegCount);
    for LIndex := 0 to LSegCount - 1 do
    begin
      Result.Segs[LIndex].Vertex1 := Next;
      Result.Segs[LIndex].Vertex2 := Next;
      Result.Segs[LIndex].Miniseg := Next <> 0;
      Result.Segs[LIndex].LineVertex1 := Next;
      Result.Segs[LIndex].LineVertex2 := Next;
      Result.Segs[LIndex].LineDeltaX := Next;
      Result.Segs[LIndex].LineDeltaY := Next;
    end;
    Result.Columns := Next;
    Result.Rows := Next;
    Result.LumpSize := Next;
    LLow := Cardinal(Next);
    LHigh := Cardinal(Next);
    Result.BlockmapFingerprint := (UInt64(LHigh) shl 32) or LLow;
    LLow := Cardinal(Next);
    LHigh := Cardinal(Next);
    Result.SlimeFingerprint := (UInt64(LHigh) shl 32) or LLow;
  except
    Result.Free;
    raise;
  end;
end;

end.
