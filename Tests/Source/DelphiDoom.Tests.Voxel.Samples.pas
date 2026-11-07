{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - the files of test                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.Samples;

{$Q-}
{$R-}

interface

uses
  System.SysUtils;

const
  /// <summary>How many files of each kind the scenarios use</summary>
  SAMPLE_DDVOX_COUNT = 30;
  SAMPLE_DDMESH_COUNT = 24;
  SAMPLE_KVX_COUNT = 40;
  SAMPLE_KVX_EXTREME_COUNT = 24;
  SAMPLE_SLAB6_COUNT = 30;
  SAMPLE_DEFINITION_COUNT = 16;

type
  /// <summary>The same inputs for the old code and the new one: xorshift32 with a fixed seed</summary>
  TVoxelRandom = class
  strict private
    FState: Cardinal;
  public
    constructor Create(const ASeed: Cardinal);
    function NextCardinal: Cardinal;
    /// <summary>A number from 0 to ARange - 1</summary>
    function NextInteger(const ARange: Integer): Integer;
  end;

  /// <summary>What a test builds in memory: voxel files of the four formats and texts of VOXELDEF</summary>
  TVoxelSamples = class
  strict private
    class procedure AppendInteger(var ABytes: TBytes; const AValue: Integer); static;
    class procedure AppendWord(var ABytes: TBytes; const AValue: Integer); static;
    class procedure AppendByte(var ABytes: TBytes; const AValue: Integer); static;
    class procedure AppendPalette(var ABytes: TBytes; const ARandom: TVoxelRandom;
      const AMode: Integer); static;
    class function BuildKvx(const ARandom: TVoxelRandom; const ASizeX, ASizeY, ASizeZ: Integer;
      const APivotX, APivotY, APivotZ: Integer; const APaletteMode: Integer): TBytes; static;
  public
    /// <summary>A DDVOX text: sides from 2 to 12, columns of colors and "skip n"</summary>
    class function Ddvox(const AIndex: Integer): TBytes; static;
    /// <summary>A DDMESH file: sides from 2 to 16, 0 to 8 quads, up to half of the cube of voxels</summary>
    class function Ddmesh(const AIndex: Integer): TBytes; static;
    /// <summary>A KVX file with the pivot near the middle (the sprite loader stays in the cube)</summary>
    class function Kvx(const AIndex: Integer): TBytes; static;
    /// <summary>A KVX file with any pivot (for the renderers, that keep the model in the cube)</summary>
    class function KvxExtreme(const AIndex: Integer): TBytes; static;
    /// <summary>A VOX file of Slab6</summary>
    class function Slab6(const AIndex: Integer): TBytes; static;
    /// <summary>Files that no loader accepts: a name for each and the bytes</summary>
    class function Rejects: TArray<TBytes>; static;
    class function RejectNames: TArray<string>; static;
    /// <summary>A text of VOXELDEF</summary>
    class function Definition(const AIndex: Integer): string; static;
    /// <summary>The integers as little endian bytes</summary>
    class function Integers(const AValues: array of Integer): TBytes; static;
    /// <summary>The bytes of A and then the bytes of B</summary>
    class function Join(const A, B: TBytes): TBytes; static;
    /// <summary>A palette of 768 bytes: color I is (I, I div 2, 1) when AGradient, else all AValue</summary>
    class function Palette(const AGradient: Boolean; const AValue: Integer): TBytes; static;
    /// <summary>The color of the palette of the patches: any function will do, the same for old and new</summary>
    class function PaletteIndexOf(const AColor: Cardinal): Byte; static;
  end;

implementation

uses
  System.Classes;

{ TVoxelRandom }

constructor TVoxelRandom.Create(const ASeed: Cardinal);
begin
  inherited Create;
  FState := ASeed;
  if FState = 0 then
    FState := $9E3779B9;
end;

function TVoxelRandom.NextCardinal: Cardinal;
begin
  FState := FState xor (FState shl 13);
  FState := FState xor (FState shr 17);
  FState := FState xor (FState shl 5);
  Result := FState;
end;

function TVoxelRandom.NextInteger(const ARange: Integer): Integer;
begin
  Result := Integer((NextCardinal shr 3) mod Cardinal(ARange));
end;

{ TVoxelSamples }

class procedure TVoxelSamples.AppendByte(var ABytes: TBytes; const AValue: Integer);
begin
  SetLength(ABytes, Length(ABytes) + 1);
  ABytes[High(ABytes)] := Byte(AValue and $FF);
end;

class procedure TVoxelSamples.AppendWord(var ABytes: TBytes; const AValue: Integer);
begin
  AppendByte(ABytes, AValue);
  AppendByte(ABytes, AValue shr 8);
end;

class procedure TVoxelSamples.AppendInteger(var ABytes: TBytes; const AValue: Integer);
begin
  AppendWord(ABytes, AValue);
  AppendWord(ABytes, AValue shr 16);
end;

class procedure TVoxelSamples.AppendPalette(var ABytes: TBytes; const ARandom: TVoxelRandom;
  const AMode: Integer);
var
  LIndex, LComponent: Integer;
  LValue: Integer;
begin
  for LIndex := 0 to 255 do
    for LComponent := 0 to 2 do
    begin
      case AMode of
        0:
          LValue := ARandom.NextInteger(64);
        1:
          LValue := ARandom.NextInteger(256);
        2:
          LValue := ARandom.NextInteger(4);
        3:
          if ARandom.NextInteger(4) = 0 then
            LValue := 0
          else
            LValue := ARandom.NextInteger(64);
        4:
          LValue := 0;
      else
        LValue := ARandom.NextInteger(200);
      end;
      if (AMode = 1) and (LIndex = 7) then
        LValue := 255;
      AppendByte(ABytes, LValue);
    end;
end;

class function TVoxelSamples.Ddvox(const AIndex: Integer): TBytes;
var
  LRandom: TVoxelRandom;
  LSide: Integer;
  LEmptyPercent: Integer;
  LBuilder: TStringBuilder;
  LX, LY, LZ: Integer;
  LRun: Integer;
  LSeparator: string;

  procedure FlushRun;
  begin
    if LRun > 0 then
    begin
      LBuilder.Append('skip ').Append(LRun).Append(LSeparator);
      LRun := 0;
    end;
  end;

begin
  LRandom := TVoxelRandom.Create(Cardinal(AIndex) * 7919 + 17);
  try
    LSide := 2 + AIndex mod 11;
    case AIndex mod 4 of
      0: LEmptyPercent := 20;
      1: LEmptyPercent := 50;
      2: LEmptyPercent := 80;
    else
      LEmptyPercent := 0;
    end;
    if AIndex mod 3 = 0 then
      LSeparator := ' '
    else if AIndex mod 3 = 1 then
      LSeparator := #13#10
    else
      LSeparator := #10#9;
    LBuilder := TStringBuilder.Create;
    try
      if AIndex mod 5 = 0 then
        LBuilder.Append('// a comment of the file'#13#10);
      LBuilder.Append(LSide).Append(#13#10);
      for LX := 0 to LSide - 1 do
        for LY := 0 to LSide - 1 do
        begin
          LRun := 0;
          for LZ := 0 to LSide - 1 do
            if LRandom.NextInteger(100) < LEmptyPercent then
              Inc(LRun)
            else
            begin
              FlushRun;
              LBuilder.Append(1 + LRandom.NextInteger($FFFFFF)).Append(LSeparator);
            end;
          FlushRun;
        end;
      Result := TEncoding.ANSI.GetBytes(LBuilder.ToString);
    finally
      LBuilder.Free;
    end;
  finally
    LRandom.Free;
  end;
end;

class function TVoxelSamples.Ddmesh(const AIndex: Integer): TBytes;
var
  LRandom: TVoxelRandom;
  LSide, LQuads, LVoxels: Integer;
  LIndex, LCorner: Integer;
begin
  LRandom := TVoxelRandom.Create(Cardinal(AIndex) * 6361 + 5);
  try
    LSide := 2 + AIndex mod 15;
    LQuads := AIndex mod 9;
    LVoxels := LRandom.NextInteger(LSide * LSide * LSide div 2 + 1);
    Result := nil;
    AppendInteger(Result, $534D4444);
    AppendInteger(Result, 1);
    AppendInteger(Result, LSide);
    AppendInteger(Result, LQuads);
    for LIndex := 0 to LQuads - 1 do
    begin
      AppendInteger(Result, Integer(LRandom.NextCardinal and $FFFFFF));
      for LCorner := 0 to 11 do
        AppendInteger(Result, LRandom.NextInteger(LSide + 1));
    end;
    AppendInteger(Result, LVoxels);
    for LIndex := 0 to LVoxels - 1 do
    begin
      AppendByte(Result, LRandom.NextInteger(LSide));
      AppendByte(Result, LRandom.NextInteger(LSide));
      AppendByte(Result, LRandom.NextInteger(LSide));
      AppendInteger(Result, Integer(LRandom.NextCardinal and $FFFFFF));
    end;
  finally
    LRandom.Free;
  end;
end;

class function TVoxelSamples.BuildKvx(const ARandom: TVoxelRandom; const ASizeX, ASizeY, ASizeZ: Integer;
  const APivotX, APivotY, APivotZ: Integer; const APaletteMode: Integer): TBytes;
var
  LEmptyPercent: Integer;
  LColumns: array of TBytes;
  LRowOffsets: array of array of Integer;
  LCell: array of Integer;
  LX, LY, LZ, LStart, LIndex: Integer;
  LColumnBase: Integer;
  LTotal: Integer;
begin
  LEmptyPercent := 10 + ARandom.NextInteger(70);
  SetLength(LCell, ASizeZ);
  SetLength(LColumns, ASizeX);
  SetLength(LRowOffsets, ASizeX);
  for LX := 0 to ASizeX - 1 do
  begin
    LColumns[LX] := nil;
    SetLength(LRowOffsets[LX], ASizeY + 1);
    for LY := 0 to ASizeY - 1 do
    begin
      LRowOffsets[LX][LY] := Length(LColumns[LX]);
      for LZ := 0 to ASizeZ - 1 do
        if ARandom.NextInteger(100) < LEmptyPercent then
          LCell[LZ] := -1
        else
          LCell[LZ] := ARandom.NextInteger(256);
      LZ := 0;
      while LZ < ASizeZ do
      begin
        if LCell[LZ] < 0 then
        begin
          Inc(LZ);
          Continue;
        end;
        LStart := LZ;
        while (LZ < ASizeZ) and (LCell[LZ] >= 0) do
          Inc(LZ);
        AppendByte(LColumns[LX], LStart);
        AppendByte(LColumns[LX], LZ - LStart);
        AppendByte(LColumns[LX], ARandom.NextInteger(64));
        for LIndex := LStart to LZ - 1 do
          AppendByte(LColumns[LX], LCell[LIndex]);
      end;
    end;
    LRowOffsets[LX][ASizeY] := Length(LColumns[LX]);
  end;

  LTotal := 0;
  for LX := 0 to ASizeX - 1 do
    Inc(LTotal, Length(LColumns[LX]));
  LColumnBase := (ASizeX + 1) * 4 + ASizeX * (ASizeY + 1) * 2;

  Result := nil;
  AppendInteger(Result, 24 + LColumnBase + LTotal);
  AppendInteger(Result, ASizeX);
  AppendInteger(Result, ASizeY);
  AppendInteger(Result, ASizeZ);
  AppendInteger(Result, APivotX);
  AppendInteger(Result, APivotY);
  AppendInteger(Result, APivotZ);
  LStart := LColumnBase;
  for LX := 0 to ASizeX - 1 do
  begin
    AppendInteger(Result, LStart);
    Inc(LStart, Length(LColumns[LX]));
  end;
  AppendInteger(Result, LStart);
  for LX := 0 to ASizeX - 1 do
    for LY := 0 to ASizeY do
      AppendWord(Result, LRowOffsets[LX][LY]);
  for LX := 0 to ASizeX - 1 do
    if Length(LColumns[LX]) > 0 then
    begin
      LIndex := Length(Result);
      SetLength(Result, LIndex + Length(LColumns[LX]));
      Move(LColumns[LX][0], Result[LIndex], Length(LColumns[LX]));
    end;
  AppendPalette(Result, ARandom, APaletteMode);
end;

class function TVoxelSamples.Kvx(const AIndex: Integer): TBytes;
var
  LRandom: TVoxelRandom;
  LSizeX, LSizeY, LSizeZ: Integer;
begin
  LRandom := TVoxelRandom.Create(Cardinal(AIndex) * 4099 + 3);
  try
    LSizeX := 1 + LRandom.NextInteger(14);
    LSizeY := 1 + LRandom.NextInteger(14);
    LSizeZ := 1 + LRandom.NextInteger(14);
    Result := BuildKvx(LRandom, LSizeX, LSizeY, LSizeZ,
      LSizeX * 128 + LRandom.NextInteger(513) - 256,
      LSizeY * 128 + LRandom.NextInteger(513) - 256,
      LSizeZ * 128 + LRandom.NextInteger(LSizeZ * 128 + 1),
      AIndex mod 6);
  finally
    LRandom.Free;
  end;
end;

class function TVoxelSamples.KvxExtreme(const AIndex: Integer): TBytes;
var
  LRandom: TVoxelRandom;
  LSizeX, LSizeY, LSizeZ: Integer;
begin
  LRandom := TVoxelRandom.Create(Cardinal(AIndex) * 2237 + 11);
  try
    LSizeX := 1 + LRandom.NextInteger(18);
    LSizeY := 1 + LRandom.NextInteger(18);
    LSizeZ := 1 + LRandom.NextInteger(18);
    Result := BuildKvx(LRandom, LSizeX, LSizeY, LSizeZ,
      LRandom.NextInteger(LSizeX * 512 + 1) - LSizeX * 128,
      LRandom.NextInteger(LSizeY * 512 + 1) - LSizeY * 128,
      LRandom.NextInteger(LSizeZ * 512 + 1) - LSizeZ * 128,
      AIndex mod 6);
  finally
    LRandom.Free;
  end;
end;

class function TVoxelSamples.Slab6(const AIndex: Integer): TBytes;
var
  LRandom: TVoxelRandom;
  LSizeX, LSizeY, LSizeZ, LIndex: Integer;
  LEmptyPercent: Integer;
begin
  LRandom := TVoxelRandom.Create(Cardinal(AIndex) * 3331 + 7);
  try
    LSizeX := 1 + LRandom.NextInteger(14);
    LSizeY := 1 + LRandom.NextInteger(14);
    LSizeZ := 1 + LRandom.NextInteger(14);
    LEmptyPercent := 10 + LRandom.NextInteger(70);
    Result := nil;
    AppendInteger(Result, LSizeX);
    AppendInteger(Result, LSizeY);
    AppendInteger(Result, LSizeZ);
    for LIndex := 0 to LSizeX * LSizeY * LSizeZ - 1 do
      if LRandom.NextInteger(100) < LEmptyPercent then
        AppendByte(Result, 255)
      else
        AppendByte(Result, LRandom.NextInteger(255));
    AppendPalette(Result, LRandom, AIndex mod 6);
  finally
    LRandom.Free;
  end;
end;

class function TVoxelSamples.RejectNames: TArray<string>;
begin
  Result := TArray<string>.Create('kvx.short', 'vox.short', 'vox.zerosize', 'vox.bigsize',
    'ddmesh.magic', 'ddmesh.version');
end;

class function TVoxelSamples.Rejects: TArray<TBytes>;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  SetLength(Result, 6);
  // a KVX that cannot hold the header and the palette
  SetLength(Result[0], 28 + 768 - 1);
  // a VOX that cannot hold the header and the palette
  SetLength(Result[1], 12 + 768 - 1);
  // a VOX with a side of zero
  LBytes := nil;
  AppendInteger(LBytes, 0);
  AppendInteger(LBytes, 4);
  AppendInteger(LBytes, 4);
  for LIndex := 1 to 768 do
    AppendByte(LBytes, 0);
  Result[2] := LBytes;
  // a VOX with a side of 257
  LBytes := nil;
  AppendInteger(LBytes, 2);
  AppendInteger(LBytes, 257);
  AppendInteger(LBytes, 2);
  for LIndex := 1 to 768 do
    AppendByte(LBytes, 0);
  Result[3] := LBytes;
  // a DDMESH with another magic
  LBytes := nil;
  AppendInteger(LBytes, $12345678);
  AppendInteger(LBytes, 1);
  AppendInteger(LBytes, 4);
  AppendInteger(LBytes, 0);
  AppendInteger(LBytes, 0);
  Result[4] := LBytes;
  // a DDMESH of another version
  LBytes := nil;
  AppendInteger(LBytes, $534D4444);
  AppendInteger(LBytes, 2);
  AppendInteger(LBytes, 4);
  AppendInteger(LBytes, 0);
  AppendInteger(LBytes, 0);
  Result[5] := LBytes;
end;

class function TVoxelSamples.Definition(const AIndex: Integer): string;
begin
  case AIndex of
    0: Result := 'voxeldef barrel offset 1.5 scale 2.0 clipped replaces sprite TROO';
    1: Result := 'VOXELDEFINITION "imp.kvx" scale 0.001 anglEoffset 45 spin 3 replacing SPRITE POSSA';
    2: Result := 'STATE S_ONE VOXEL "A.DDVOX" FRAME 3'#13#10'STATE S_TWO FRAME 2 VOXEL B offset 9';
    3: Result := 'STATE S_UNKNOWN VOXEL X'#13#10'STATE S_THREE';
    4: Result := 'TROO imp.kvx offset 2 scale 3 CLIPPED POSS cacodemon scale 1';
    5: Result := 'XXXX foo { } bar';
    6: Result := 'VOXELDEF lonely';
    7: Result := 'VOXELDEF'#13#10;
    8: Result := 'STATE';
    9: Result := 'VOXELDEF a REPLACE';
    10: Result := 'VOXELDEF a REPLACE TROO'#13#10'VOXELDEF b replace sprite UNKN dummy';
    11: Result := 'VOXELDEF a offset abc scale';
    12: Result := 'VOXELDEF = a = offset = 4 = placedspin 7 droppedspin -2 = replace = sprite = CYBR';
    13: Result := '// a comment'#13#10'voxeldef c scale 5 // x'#13#10' replace sprite cybr'#13#10'POSS "my model.kvx" scale 0.5 offset -3.25';
    14: Result := 'VOXELDEF d clipped'#13#10'VOXELDEF d scale 0.0005 replace sprite TROO'#13#10'STATE S_ONE frame 4 VOXEL d STATE S_THREE voxel e frame -1';
    15: Result := 'TROO a.kvx POSS b.kvx offset 1 CYBR';
  else
    Result := '';
  end;
end;

class function TVoxelSamples.Integers(const AValues: array of Integer): TBytes;
var
  LIndex: Integer;
begin
  Result := nil;
  for LIndex := 0 to High(AValues) do
    AppendInteger(Result, AValues[LIndex]);
end;

class function TVoxelSamples.Join(const A, B: TBytes): TBytes;
begin
  SetLength(Result, Length(A) + Length(B));
  if Length(A) > 0 then
    Move(A[0], Result[0], Length(A));
  if Length(B) > 0 then
    Move(B[0], Result[Length(A)], Length(B));
end;

class function TVoxelSamples.Palette(const AGradient: Boolean; const AValue: Integer): TBytes;
var
  LIndex: Integer;
begin
  Result := nil;
  for LIndex := 0 to 255 do
    if AGradient then
    begin
      AppendByte(Result, LIndex);
      AppendByte(Result, LIndex div 2);
      AppendByte(Result, 1);
    end
    else
    begin
      AppendByte(Result, AValue);
      AppendByte(Result, AValue);
      AppendByte(Result, AValue);
    end;
end;

class function TVoxelSamples.PaletteIndexOf(const AColor: Cardinal): Byte;
begin
  Result := Byte(((AColor and $FF) * 3 + ((AColor shr 8) and $FF) * 5 + ((AColor shr 16) and $FF) * 7) and $FF);
end;

end.
