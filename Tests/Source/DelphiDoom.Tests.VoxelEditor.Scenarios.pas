{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel editor - the scenarios (issue #167)           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.Scenarios;

// The scenarios are the shared script of the tests and of the harness that ran the old code of DD_VOXEL (Tools\Verifica\167): both build
// the same voxels, pictures and files from a generator of their own (no RTL Random), so the golden file
// Tests\Data\VoxelEditor\voxel.golden.txt, written by the old code, is compared with what the library answers. The unit does not use the
// library: the harness compiles it with the old units.

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes;

type
  TVoxelScenarios = class sealed
  public
    const
      MODEL_COUNT = 10;
      KVX_COUNT = 6;
      VOX_COUNT = 5;
    /// <summary>The name of a model of the scenarios</summary>
    class function ModelName(AIndex: Integer): string; static;
    class function ModelSize(AIndex: Integer): Integer; static;
    /// <summary>The cells of a model, (x * size + y) * size + z, each 0 or a color $00BBGGRR</summary>
    class function ModelCells(AIndex: Integer): TArray<Cardinal>; static;
    /// <summary>A picture of size x size with some zeros, for painting on a view or for a texture</summary>
    class function ProbeImage(ASize, ASalt: Integer; AZeroPercent: Integer = 25): TArray<Cardinal>; static;
    /// <summary>A KVX file of the scenario (sides, pivot and palette change from one to the other)</summary>
    class function KvxBytes(AIndex: Integer): TBytes; static;
    class function VoxBytes(AIndex: Integer): TBytes; static;
    /// <summary>The impronta FNV-1a 64 of cells, as 16 hexadecimal digits</summary>
    class function Digest(const ACells: TArray<Cardinal>): string; static;
    class function DigestBytes(const ABytes: TBytes): string; static;
    class function DigestIntegers(const AValues: TArray<Integer>): string; static;
  end;

implementation

type
  TGenerator = record
    State: Cardinal;
    procedure Start(ASeed: Cardinal);
    function Next: Cardinal;
    function Below(ARange: Cardinal): Cardinal;
    function Color: Cardinal;
  end;

procedure TGenerator.Start(ASeed: Cardinal);
begin
  State := ASeed * 2654435761 + 12345;
end;

function TGenerator.Next: Cardinal;
begin
  State := State * 1664525 + 1013904223;
  Result := State shr 8;
end;

function TGenerator.Below(ARange: Cardinal): Cardinal;
begin
  Result := Next mod ARange;
end;

function TGenerator.Color: Cardinal;
begin
  Result := Next and $FFFFFF;
  if Result = 0 then
    Result := 1;
end;

{ TVoxelScenarios }

class function TVoxelScenarios.ModelName(AIndex: Integer): string;
const
  NAMES: array[0..MODEL_COUNT - 1] of string = ('empty16', 'box8', 'sparse16', 'sparse32', 'sphere32', 'terrain16',
    'dense16', 'sparse64', 'colors64', 'sparse256');
begin
  Result := NAMES[AIndex];
end;

class function TVoxelScenarios.ModelSize(AIndex: Integer): Integer;
const
  SIZES: array[0..MODEL_COUNT - 1] of Integer = (16, 8, 16, 32, 32, 16, 16, 64, 64, 256);
begin
  Result := SIZES[AIndex];
end;

class function TVoxelScenarios.ModelCells(AIndex: Integer): TArray<Cardinal>;
var
  LSize, LX, LY, LZ, LIndex, LHeight, LCount: Integer;
  LGenerator: TGenerator;
  LDistance: Double;
  LDensity: Cardinal;
begin
  LSize := ModelSize(AIndex);
  SetLength(Result, LSize * LSize * LSize);
  if Length(Result) > 0 then
    FillChar(Result[0], Length(Result) * SizeOf(Cardinal), 0);
  LGenerator.Start(AIndex + 1);
  case AIndex of
    0:
      ;
    1:
      for LX := 0 to LSize - 1 do
        for LY := 0 to LSize - 1 do
          for LZ := 0 to LSize - 1 do
            Result[(LX * LSize + LY) * LSize + LZ] := (Cardinal(LX + 1) * $101010) or Cardinal(LZ + 1);
    4:
      for LX := 0 to LSize - 1 do
        for LY := 0 to LSize - 1 do
          for LZ := 0 to LSize - 1 do
          begin
            LDistance := Sqrt(Sqr(LX - 15.5) + Sqr(LY - 15.5) + Sqr(LZ - 15.5));
            if LDistance < 14 then
              Result[(LX * LSize + LY) * LSize + LZ] :=
                (Cardinal(Round(LDistance * 17)) and $FF) or (Cardinal(LX * 8) shl 8) or (Cardinal(LZ * 8) shl 16) or 1;
          end;
    5:
      for LX := 0 to LSize - 1 do
        for LZ := 0 to LSize - 1 do
        begin
          LHeight := 3 + (LX * 5 + LZ * 3) mod 11;
          for LY := LSize - LHeight to LSize - 1 do
            Result[(LX * LSize + LY) * LSize + LZ] := LGenerator.Color;
        end;
    9:
      begin
        // 256 cells a side: some thousands of voxels and a few at the faces of the cube
        LCount := 40000;
        for LIndex := 1 to LCount do
          Result[(Integer(LGenerator.Below(LSize)) * LSize + Integer(LGenerator.Below(LSize))) * LSize
            + Integer(LGenerator.Below(LSize))] := LGenerator.Color;
        for LIndex := 0 to LSize - 1 do
        begin
          Result[(LIndex * LSize + 0) * LSize + 0] := LGenerator.Color;
          Result[(LIndex * LSize + (LSize - 1)) * LSize + (LSize - 1)] := LGenerator.Color;
        end;
      end;
  else
    begin
      case AIndex of
        2: LDensity := 20;
        3: LDensity := 35;
        6: LDensity := 90;
        7: LDensity := 5;
      else
        LDensity := 6;
      end;
      for LIndex := 0 to High(Result) do
        if LGenerator.Below(100) < LDensity then
        begin
          if AIndex = 8 then
            Result[LIndex] := LGenerator.Color
          else
            Result[LIndex] := (LGenerator.Below(7) + 1) * $030507 + LGenerator.Below(3);
        end;
    end;
  end;
end;

class function TVoxelScenarios.ProbeImage(ASize, ASalt: Integer; AZeroPercent: Integer): TArray<Cardinal>;
var
  LGenerator: TGenerator;
  LIndex: Integer;
begin
  SetLength(Result, ASize * ASize);
  LGenerator.Start(1000 + ASalt);
  for LIndex := 0 to High(Result) do
    if Integer(LGenerator.Below(100)) < AZeroPercent then
      Result[LIndex] := 0
    else
      Result[LIndex] := LGenerator.Color;
end;

class function TVoxelScenarios.KvxBytes(AIndex: Integer): TBytes;
const
  // x, y, z sides; pivot x, y, z (in 1/256 of a cell); the palette: 0 full range, 1 VGA (6 bits), 2 dark
  SPECS: array[0..KVX_COUNT - 1, 0..6] of Integer = (
    (10, 12, 14, 5 * 256, 6 * 256, 7 * 256, 0),
    (16, 16, 16, 8 * 256, 8 * 256, 16 * 256, 0),
    (30, 20, 25, 15 * 256, 10 * 256, 12 * 256, 1),
    (40, 33, 17, 0, 0, 0, 0),
    (64, 64, 64, 32 * 256, 32 * 256, 64 * 256, 2),
    (9, 3, 7, 4 * 256 + 100, -300, 3 * 256, 1));
var
  LGenerator: TGenerator;
  LXSize, LYSize, LZSize, LX, LY, LZ, LRun, LPosition, LIndex: Integer;
  LSlices: array of TBytes;
  LColumn: TBytes;
  LColumnOffsets: array of Integer;
  LStream: TBytesStream;
  LValue: Integer;
  LByte: Byte;
  LNumBytes, LHeader: Integer;
  LCell: Integer;
  LStart: Integer;
  LSliceBytes: TBytes;
  LCells: array of Integer;
begin
  LGenerator.Start(500 + AIndex);
  LXSize := SPECS[AIndex, 0];
  LYSize := SPECS[AIndex, 1];
  LZSize := SPECS[AIndex, 2];
  SetLength(LCells, LXSize * LYSize * LZSize);
  for LIndex := 0 to High(LCells) do
    if LGenerator.Below(100) < 30 then
      LCells[LIndex] := Integer(LGenerator.Below(256))
    else
      LCells[LIndex] := -1;
  LStream := TBytesStream.Create;
  try
    SetLength(LSlices, LXSize);
    LHeader := (LXSize + 1) * 4 + LXSize * (LYSize + 1) * 2;
    // the slabs of each x: for each y a list of runs of z
    for LX := 0 to LXSize - 1 do
    begin
      LSliceBytes := nil;
      SetLength(LColumnOffsets, LYSize + 1);
      for LY := 0 to LYSize - 1 do
      begin
        LColumnOffsets[LY] := Length(LSliceBytes);
        LZ := 0;
        while LZ < LZSize do
        begin
          if LCells[(LX * LYSize + LY) * LZSize + LZ] < 0 then
          begin
            Inc(LZ);
            Continue;
          end;
          LRun := 0;
          while (LZ + LRun < LZSize) and (LCells[(LX * LYSize + LY) * LZSize + LZ + LRun] >= 0) do
            Inc(LRun);
          LPosition := Length(LSliceBytes);
          SetLength(LSliceBytes, LPosition + 3 + LRun);
          LSliceBytes[LPosition] := LZ;
          LSliceBytes[LPosition + 1] := LRun;
          LSliceBytes[LPosition + 2] := 0;
          for LIndex := 0 to LRun - 1 do
            LSliceBytes[LPosition + 3 + LIndex] := LCells[(LX * LYSize + LY) * LZSize + LZ + LIndex];
          Inc(LZ, LRun);
        end;
      end;
      LColumnOffsets[LYSize] := Length(LSliceBytes);
      // the offsets of the columns of the slice go in front of the data: they are written below
      LColumn := nil;
      SetLength(LColumn, (LYSize + 1) * 2);
      for LY := 0 to LYSize do
        PWord(@LColumn[LY * 2])^ := LColumnOffsets[LY];
      LSlices[LX] := LColumn + LSliceBytes;
    end;
    LNumBytes := 24 + LHeader;
    for LX := 0 to LXSize - 1 do
      Inc(LNumBytes, Length(LSlices[LX]) - (LYSize + 1) * 2);
    LValue := LNumBytes;
    LStream.Write(LValue, 4);
    LValue := LXSize;
    LStream.Write(LValue, 4);
    LValue := LYSize;
    LStream.Write(LValue, 4);
    LValue := LZSize;
    LStream.Write(LValue, 4);
    for LIndex := 3 to 5 do
    begin
      LValue := SPECS[AIndex, LIndex];
      LStream.Write(LValue, 4);
    end;
    // xoffset: where the data of each slice starts (the first one follows the offsets)
    LStart := LHeader;
    for LX := 0 to LXSize do
    begin
      LValue := LStart;
      LStream.Write(LValue, 4);
      if LX < LXSize then
        Inc(LStart, Length(LSlices[LX]) - (LYSize + 1) * 2);
    end;
    for LX := 0 to LXSize - 1 do
      LStream.Write(LSlices[LX][0], (LYSize + 1) * 2);
    for LX := 0 to LXSize - 1 do
      if Length(LSlices[LX]) > (LYSize + 1) * 2 then
        LStream.Write(LSlices[LX][(LYSize + 1) * 2], Length(LSlices[LX]) - (LYSize + 1) * 2);
    // the palette: blue, green, red of 256 colors
    for LIndex := 0 to 255 do
      for LCell := 0 to 2 do
      begin
        case SPECS[AIndex, 6] of
          1: LByte := LGenerator.Below(64);
          2: LByte := LGenerator.Below(40);
        else
          LByte := LGenerator.Below(256);
        end;
        if (LIndex = 7) and (LCell < 3) then
          LByte := 0; // a black color of the palette (it becomes 1)
        LStream.Write(LByte, 1);
      end;
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

class function TVoxelScenarios.VoxBytes(AIndex: Integer): TBytes;
const
  SPECS: array[0..VOX_COUNT - 1, 0..3] of Integer = ((8, 8, 8, 0), (10, 6, 12, 1), (16, 20, 9, 0), (33, 33, 33, 2), (1, 5, 2, 0));
var
  LGenerator: TGenerator;
  LXSize, LYSize, LZSize, LIndex, LValue: Integer;
  LStream: TBytesStream;
  LByte: Byte;
begin
  LGenerator.Start(800 + AIndex);
  LXSize := SPECS[AIndex, 0];
  LYSize := SPECS[AIndex, 1];
  LZSize := SPECS[AIndex, 2];
  LStream := TBytesStream.Create;
  try
    LValue := LXSize;
    LStream.Write(LValue, 4);
    LValue := LYSize;
    LStream.Write(LValue, 4);
    LValue := LZSize;
    LStream.Write(LValue, 4);
    for LIndex := 1 to LXSize * LYSize * LZSize do
    begin
      if LGenerator.Below(100) < 35 then
        LByte := LGenerator.Below(255)
      else
        LByte := 255;
      LStream.Write(LByte, 1);
    end;
    for LIndex := 0 to 767 do
    begin
      case SPECS[AIndex, 3] of
        1: LByte := LGenerator.Below(64);
        2: LByte := LGenerator.Below(1) * 0;
      else
        LByte := LGenerator.Below(256);
      end;
      LStream.Write(LByte, 1);
    end;
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

class function TVoxelScenarios.DigestBytes(const ABytes: TBytes): string;
var
  LHash: UInt64;
  LIndex: Integer;
begin
  LHash := $CBF29CE484222325;
  for LIndex := 0 to High(ABytes) do
    LHash := (LHash xor UInt64(ABytes[LIndex])) * UInt64($100000001B3);
  Result := IntToHex(LHash, 16);
end;

class function TVoxelScenarios.Digest(const ACells: TArray<Cardinal>): string;
var
  LHash: UInt64;
  LIndex, LByte: Integer;
begin
  LHash := $CBF29CE484222325;
  for LIndex := 0 to High(ACells) do
    for LByte := 0 to 3 do
      LHash := (LHash xor UInt64((ACells[LIndex] shr (8 * LByte)) and $FF)) * UInt64($100000001B3);
  Result := IntToHex(LHash, 16);
end;

class function TVoxelScenarios.DigestIntegers(const AValues: TArray<Integer>): string;
var
  LCells: TArray<Cardinal>;
  LIndex: Integer;
begin
  SetLength(LCells, Length(AValues));
  for LIndex := 0 to High(AValues) do
    LCells[LIndex] := Cardinal(AValues[LIndex]);
  Result := Digest(LCells);
end;

end.
