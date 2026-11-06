{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Imaging library - the synthetic data               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.Samples;

{ The inputs of the tests of parity. The harness that made Tests\Data\Imaging compiled the
  old code of the engine on these same inputs (this unit uses nothing of the library, so the
  harness can use it too), and the tests give them to the library. Each case has a name: the
  golden files have a line for each one }

interface

uses
  System.SysUtils;

type
  /// <summary>Numbers that do not change from a run to the next (a linear congruential generator)</summary>
  TSampleRandom = record
  private
    FState: Cardinal;
  public
    constructor Create(ASeed: Cardinal);
    function NextCardinal: Cardinal;
    function NextByte: Byte;
    /// <summary>A number from 0 to ALimit - 1</summary>
    function NextBelow(ALimit: Integer): Integer;
  end;

  /// <summary>A post as the tests write it: its topdelta, its length and the seed of its pixels</summary>
  TSamplePost = record
    TopDelta: Integer;
    Length: Integer;
    Seed: Integer;
  end;

  TSamplePainterCase = record
    Name: string;
    Column: TBytes;
    OriginY: Integer;
    CacheHeight: Integer;
  end;

  TSampleRebuildCase = record
    Name: string;
    Height: Integer;
    Marks: TBytes;
    Pixels: TBytes;
    /// <summary>The bytes of the block, from the header of the column on</summary>
    BlockSize: Integer;
  end;

  TSampleFixedCase = record
    Name: string;
    Column: TBytes;
    Height: Integer;
  end;

  TSamplePatchCase = record
    Name: string;
    Lump: TBytes;
  end;

  TSampleFlatCase = record
    Name: string;
    Lump: TBytes;
    InfoSizeIndex: Integer;
  end;

  TSampleWipeCase = record
    Name: string;
    Width: Integer;
    Height: Integer;
    Pitch: Integer;
    AlphaMask: Cardinal;
    Seed: Cardinal;
    Ticks: TArray<Integer>;
  end;

  TSampleScaleCase = record
    ViewAngle: Cardinal;
    NormalAngle: Cardinal;
    Distance: Integer;
    ProjectionY: Integer;
    MaxScale: Integer;
    Precise: Boolean;
    VisAngle: Cardinal;
  end;

  /// <summary>The inputs and the functions that the harness and the tests share</summary>
  TImagingSamples = class sealed
  public
    class function Hash(const ABytes: TBytes): UInt64; overload; static;
    class function Hash(const APixels: TArray<Cardinal>): UInt64; overload; static;
    class function Hash(const AValues: TArray<Integer>): UInt64; overload; static;
    class function Hex(AValue: UInt64): string; static;
    class function Column(const APosts: array of TSamplePost): TBytes; static;
    class function Patch(AWidth, AHeight, ALeft, ATop: Integer; const AColumns: array of TBytes;
      const AColumnIndexes: array of Integer): TBytes; static;
    /// <summary>The posts of a block that was rebuilt, as "topdelta:length:hash;" ending with "end"</summary>
    class function DumpPosts(const ABlock: TBytes; AOffset: Integer): string; static;
    /// <summary>Bytes that are 0 (SetLength does not clear what it adds)</summary>
    class function ZeroBytes(ACount: Integer): TBytes; static;
    class function ZeroPixels(ACount: Integer): TArray<Cardinal>; static;
    class function RandomBytes(ASeed: Cardinal; ACount: Integer): TBytes; static;
    class function RandomPixels(ASeed: Cardinal; ACount: Integer; AMask: Cardinal): TArray<Cardinal>; static;
    class function PainterCases: TArray<TSamplePainterCase>; static;
    class function RebuildCases: TArray<TSampleRebuildCase>; static;
    class function FixedRepeatCases: TArray<TSampleFixedCase>; static;
    class function FixedPostCases: TArray<TSampleFixedCase>; static;
    class function PatchCases: TArray<TSamplePatchCase>; static;
    class function FlatCases: TArray<TSampleFlatCase>; static;
    class function ShrinkLengths: TArray<Integer>; static;
    class function WipeCases: TArray<TSampleWipeCase>; static;
    class function ScaleCases: TArray<TSampleScaleCase>; static;
    class function ColorSamples: TArray<Cardinal>; static;
    class function Palette(ASeed: Cardinal): TArray<Cardinal>; static;
    /// <summary>Factors of 16.16 for the blends of two colors, inside and outside of 0..FRACUNIT</summary>
    class function ColorFactors: TArray<Integer>; static;
    /// <summary>Factors of light, some of them over FRACUNIT</summary>
    class function LightFactors: TArray<Integer>; static;
    /// <summary>Values for the channels of LightAdd, some over 255</summary>
    class function LightAddValues: TArray<Cardinal>; static;
  end;

implementation

{ TSampleRandom }

constructor TSampleRandom.Create(ASeed: Cardinal);
begin
  FState := ASeed;
end;

function TSampleRandom.NextCardinal: Cardinal;
begin
  FState := FState * 1664525 + 1013904223;
  Result := FState;
end;

function TSampleRandom.NextByte: Byte;
begin
  Result := Byte(NextCardinal shr 16);
end;

function TSampleRandom.NextBelow(ALimit: Integer): Integer;
begin
  Result := Integer((NextCardinal shr 8) mod Cardinal(ALimit));
end;

{ TImagingSamples }

class function TImagingSamples.Hash(const ABytes: TBytes): UInt64;
var
  LIndex: Integer;
begin
  Result := UInt64($CBF29CE484222325);
  for LIndex := 0 to Length(ABytes) - 1 do
    Result := (Result xor ABytes[LIndex]) * UInt64($100000001B3);
end;

class function TImagingSamples.Hash(const APixels: TArray<Cardinal>): UInt64;
var
  LIndex: Integer;
  LShift: Integer;
begin
  Result := UInt64($CBF29CE484222325);
  for LIndex := 0 to Length(APixels) - 1 do
    for LShift := 0 to 3 do
      Result := (Result xor ((APixels[LIndex] shr (LShift * 8)) and $FF)) * UInt64($100000001B3);
end;

class function TImagingSamples.Hash(const AValues: TArray<Integer>): UInt64;
var
  LIndex: Integer;
  LShift: Integer;
begin
  Result := UInt64($CBF29CE484222325);
  for LIndex := 0 to Length(AValues) - 1 do
    for LShift := 0 to 3 do
      Result := (Result xor ((Cardinal(AValues[LIndex]) shr (LShift * 8)) and $FF)) * UInt64($100000001B3);
end;

class function TImagingSamples.Hex(AValue: UInt64): string;
begin
  Result := IntToHex(Int64(AValue), 16);
end;

class function TImagingSamples.Column(const APosts: array of TSamplePost): TBytes;
var
  LIndex: Integer;
  LPixel: Integer;
  LRandom: TSampleRandom;
begin
  Result := nil;
  for LIndex := 0 to High(APosts) do
  begin
    SetLength(Result, Length(Result) + 4 + APosts[LIndex].Length);
    Result[Length(Result) - 4 - APosts[LIndex].Length] := Byte(APosts[LIndex].TopDelta);
    Result[Length(Result) - 3 - APosts[LIndex].Length] := Byte(APosts[LIndex].Length);
    Result[Length(Result) - 2 - APosts[LIndex].Length] := 0;
    LRandom := TSampleRandom.Create(Cardinal(APosts[LIndex].Seed));
    for LPixel := 0 to APosts[LIndex].Length - 1 do
      Result[Length(Result) - 1 - APosts[LIndex].Length + LPixel] := LRandom.NextByte or 1;
    Result[Length(Result) - 1] := 0;
  end;
  SetLength(Result, Length(Result) + 1);
  Result[Length(Result) - 1] := $FF;
end;

class function TImagingSamples.Patch(AWidth, AHeight, ALeft, ATop: Integer;
  const AColumns: array of TBytes; const AColumnIndexes: array of Integer): TBytes;
var
  LHeaderSize: Integer;
  LOffsets: array of Integer;
  LColumn: Integer;
  LPosition: Integer;
begin
  LHeaderSize := 8 + 4 * AWidth;
  SetLength(Result, LHeaderSize);
  PSmallInt(@Result[0])^ := AWidth;
  PSmallInt(@Result[2])^ := AHeight;
  PSmallInt(@Result[4])^ := ALeft;
  PSmallInt(@Result[6])^ := ATop;
  // the distinct columns one after the other; the indexes say which one each column uses
  SetLength(LOffsets, Length(AColumns));
  LPosition := LHeaderSize;
  for LColumn := 0 to High(AColumns) do
  begin
    LOffsets[LColumn] := LPosition;
    SetLength(Result, LPosition + Length(AColumns[LColumn]));
    if Length(AColumns[LColumn]) > 0 then
      Move(AColumns[LColumn][0], Result[LPosition], Length(AColumns[LColumn]));
    LPosition := LPosition + Length(AColumns[LColumn]);
  end;
  for LColumn := 0 to AWidth - 1 do
    PInteger(@Result[8 + 4 * LColumn])^ := LOffsets[AColumnIndexes[LColumn]];
end;

class function TImagingSamples.DumpPosts(const ABlock: TBytes; AOffset: Integer): string;
var
  LOffset: Integer;
  LLength: Integer;
  LData: TBytes;
begin
  Result := '';
  LOffset := AOffset;
  while (LOffset < Length(ABlock)) and (ABlock[LOffset] <> $FF) do
  begin
    LLength := ABlock[LOffset + 1];
    SetLength(LData, LLength);
    if LLength > 0 then
      Move(ABlock[LOffset + 3], LData[0], LLength);
    Result := Result + IntToStr(ABlock[LOffset]) + ':' + IntToStr(LLength) + ':' +
      IntToHex(Int64(Hash(LData)), 16) + ';';
    LOffset := LOffset + LLength + 4;
  end;
  Result := Result + 'end';
end;

class function TImagingSamples.ZeroBytes(ACount: Integer): TBytes;
begin
  SetLength(Result, ACount);
  if ACount > 0 then
    FillChar(Result[0], ACount, 0);
end;

class function TImagingSamples.ZeroPixels(ACount: Integer): TArray<Cardinal>;
begin
  SetLength(Result, ACount);
  if ACount > 0 then
    FillChar(Result[0], ACount * SizeOf(Cardinal), 0);
end;

class function TImagingSamples.RandomBytes(ASeed: Cardinal; ACount: Integer): TBytes;
var
  LRandom: TSampleRandom;
  LIndex: Integer;
begin
  LRandom := TSampleRandom.Create(ASeed);
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    Result[LIndex] := LRandom.NextByte;
end;

class function TImagingSamples.RandomPixels(ASeed: Cardinal; ACount: Integer;
  AMask: Cardinal): TArray<Cardinal>;
var
  LRandom: TSampleRandom;
  LIndex: Integer;
begin
  LRandom := TSampleRandom.Create(ASeed);
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    Result[LIndex] := LRandom.NextCardinal and AMask;
end;

class function TImagingSamples.Palette(ASeed: Cardinal): TArray<Cardinal>;
begin
  Result := RandomPixels(ASeed, 256, $00FFFFFF);
end;

function Post(ATopDelta, ALength, ASeed: Integer): TSamplePost;
begin
  Result.TopDelta := ATopDelta;
  Result.Length := ALength;
  Result.Seed := ASeed;
end;

class function TImagingSamples.PainterCases: TArray<TSamplePainterCase>;
  procedure Add(const AName: string; const AColumn: TBytes; AOriginY, AHeight: Integer);
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)].Name := AName;
    Result[High(Result)].Column := AColumn;
    Result[High(Result)].OriginY := AOriginY;
    Result[High(Result)].CacheHeight := AHeight;
  end;
begin
  Result := nil;
  Add('empty', Column([]), 0, 16);
  Add('single', Column([Post(2, 5, 1)]), 0, 16);
  Add('two_posts', Column([Post(0, 3, 2), Post(8, 4, 3)]), 0, 16);
  Add('full', Column([Post(0, 16, 4)]), 0, 16);
  Add('zero_length', Column([Post(4, 0, 5), Post(6, 2, 6)]), 0, 16);
  Add('clip_bottom', Column([Post(10, 12, 7)]), 0, 16);
  Add('outside_bottom', Column([Post(20, 4, 8)]), 0, 16);
  Add('origin_negative', Column([Post(2, 6, 9), Post(10, 4, 10)]), -5, 16);
  Add('origin_negative_all_out', Column([Post(1, 3, 11)]), -9, 16);
  Add('origin_positive', Column([Post(0, 4, 12)]), 9, 16);
  Add('origin_positive_clip', Column([Post(0, 12, 13)]), 9, 16);
  Add('overlap', Column([Post(2, 8, 14), Post(6, 8, 15)]), 0, 16);
  Add('decreasing_offsets', Column([Post(10, 3, 16), Post(2, 3, 17)]), 0, 16);
  Add('tall_height', Column([Post(0, 200, 18), Post(250, 50, 19)]), 0, 320);
  Add('post_254', Column([Post(1, 254, 20)]), 0, 300);
  Add('height_one', Column([Post(0, 1, 21)]), 0, 1);
  Add('height_zero', Column([Post(0, 1, 22)]), 0, 0);
end;

class function TImagingSamples.RebuildCases: TArray<TSampleRebuildCase>;
  procedure Add(const AName: string; AHeight: Integer; const ARuns: array of Integer;
    ASeed: Cardinal);
  var
    LIndex: Integer;
    LRun: Integer;
    LItem: TSampleRebuildCase;
  begin
    LItem.Name := AName;
    LItem.Height := AHeight;
    LItem.Marks := ZeroBytes(AHeight);
    // the runs are pairs: first row, number of rows
    LRun := 0;
    while LRun < Length(ARuns) do
    begin
      for LIndex := ARuns[LRun] to ARuns[LRun] + ARuns[LRun + 1] - 1 do
        LItem.Marks[LIndex] := $FF;
      Inc(LRun, 2);
    end;
    LItem.Pixels := RandomBytes(ASeed, AHeight);
    for LIndex := 0 to AHeight - 1 do
      LItem.Pixels[LIndex] := LItem.Pixels[LIndex] or 1;
    LItem.BlockSize := 3 + 5 * AHeight + 16;
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := LItem;
  end;
begin
  Result := nil;
  Add('short_empty', 16, [], 1);
  Add('short_full', 16, [0, 16], 2);
  Add('short_one_run', 16, [3, 5], 3);
  Add('short_two_runs', 32, [2, 4, 10, 20], 4);
  Add('short_alternate', 20, [0, 1, 2, 1, 4, 1, 6, 1, 8, 1, 10, 1, 12, 1, 14, 1, 16, 1, 18, 1], 5);
  Add('short_last_row', 16, [15, 1], 6);
  Add('short_first_row', 16, [0, 1], 7);
  Add('short_height_one', 1, [0, 1], 8);
  Add('short_128', 128, [0, 64, 70, 58], 9);
  Add('short_254_full', 254, [0, 254], 10);
  Add('short_254_runs', 254, [10, 100, 120, 134], 11);
  Add('tall_255_full', 255, [0, 255], 12);
  Add('tall_300_full', 300, [0, 300], 13);
  Add('tall_300_runs', 300, [0, 100, 200, 100], 14);
  Add('tall_300_far_run', 300, [10, 40, 260, 40], 15);
  Add('tall_256_empty', 256, [], 16);
  Add('tall_400_runs', 400, [5, 20, 100, 30, 270, 130], 17);
  Add('tall_300_one_row_each', 300, [0, 1, 254, 1, 299, 1], 18);
  Add('tall_300_254_run', 300, [0, 254], 19);
  Add('tall_600_runs', 600, [100, 100, 300, 250, 540, 40], 20);
end;

class function TImagingSamples.FixedRepeatCases: TArray<TSampleFixedCase>;
  procedure Add(AHeight: Integer);
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)].Name := 'repeat_' + IntToStr(AHeight);
    Result[High(Result)].Height := AHeight;
    // the column is raw pixels, with the three bytes of a header before them
    Result[High(Result)].Column := RandomBytes(Cardinal(AHeight) * 7, AHeight + 3);
  end;
begin
  Result := nil;
  Add(2);
  Add(4);
  Add(8);
  Add(16);
  Add(32);
  Add(64);
  Add(3);
  Add(100);
  Add(127);
end;

class function TImagingSamples.FixedPostCases: TArray<TSampleFixedCase>;
  procedure Add(const AName: string; const AColumn: TBytes; AHeight: Integer);
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)].Name := AName;
    Result[High(Result)].Column := AColumn;
    Result[High(Result)].Height := AHeight;
  end;
begin
  Result := nil;
  Add('empty', Column([]), 64);
  Add('single', Column([Post(5, 10, 1)]), 64);
  Add('two_increasing', Column([Post(2, 4, 2), Post(20, 6, 3)]), 64);
  Add('full', Column([Post(0, 64, 4)]), 64);
  Add('clip_bottom', Column([Post(50, 30, 5)]), 64);
  Add('outside', Column([Post(70, 4, 6)]), 64);
  Add('non_power_height', Column([Post(1, 20, 7), Post(30, 40, 8)]), 100);
  Add('decreasing_adds_up', Column([Post(30, 5, 9), Post(10, 5, 10), Post(10, 5, 11)]), 100);
  Add('equal_offsets_tall', Column([Post(0, 10, 12), Post(0, 10, 13), Post(0, 10, 14)]), 64);
  Add('tall_height', Column([Post(0, 200, 15), Post(250, 40, 16), Post(5, 30, 17)]), 300);
  Add('zero_length', Column([Post(4, 0, 18), Post(8, 3, 19)]), 64);
  Add('height_one', Column([Post(0, 1, 20)]), 1);
  Add('height_zero', Column([Post(0, 1, 21)]), 0);
end;

class function TImagingSamples.PatchCases: TArray<TSamplePatchCase>;
  procedure Add(const AName: string; const ALump: TBytes);
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)].Name := AName;
    Result[High(Result)].Lump := ALump;
  end;
var
  LIndex: Integer;
  LColumns: array of TBytes;
  LIndexes: array of Integer;
begin
  Result := nil;
  Add('empty_0x0', Patch(0, 0, 0, 0, [], []));
  Add('width_without_height', Patch(3, 0, 1, 1, [Column([])], [0, 0, 0]));
  Add('one_pixel', Patch(1, 1, 0, 0, [Column([Post(0, 1, 1)])], [0]));
  Add('small_4x6', Patch(4, 6, 2, 5,
    [Column([Post(1, 3, 1)]), Column([Post(0, 6, 2)]), Column([]),
     Column([Post(0, 2, 3), Post(4, 2, 4)])], [0, 1, 2, 3]));
  Add('shared_column', Patch(3, 8, 0, 0, [Column([Post(2, 4, 5)])], [0, 0, 0]));
  Add('post_past_bottom', Patch(2, 8, 0, 0,
    [Column([Post(5, 10, 6)]), Column([Post(9, 4, 7)])], [0, 1]));
  Add('overlapping_posts', Patch(1, 16, 0, 0, [Column([Post(2, 8, 8), Post(6, 8, 9)])], [0]));
  Add('zero_length_post', Patch(2, 8, 0, 0, [Column([Post(2, 0, 10), Post(4, 3, 11)]),
    Column([Post(0, 8, 12)])], [0, 1]));
  Add('tall_300', Patch(2, 300, 1, 2,
    [Column([Post(0, 200, 13), Post(250, 50, 14)]), Column([Post(1, 254, 15)])], [0, 1]));
  // a wide one: two kinds of column, one after the other
  SetLength(LIndexes, 301);
  for LIndex := 0 to 300 do
    LIndexes[LIndex] := LIndex mod 2;
  Add('wide_301x2', Patch(301, 2, 150, 1, [Column([Post(0, 2, 16)]), Column([Post(1, 1, 17)])],
    LIndexes));
  // a graphic of 64x64 with posts of different sizes in every column
  SetLength(LColumns, 64);
  SetLength(LIndexes, 64);
  for LIndex := 0 to 63 do
  begin
    LColumns[LIndex] := Column([Post(LIndex mod 7, 1 + LIndex mod 11, LIndex), Post(30 + LIndex mod 5, 1 + LIndex mod 9, LIndex + 100)]);
    LIndexes[LIndex] := LIndex;
  end;
  Add('graphic_64x64', Patch(64, 64, 32, 64, LColumns, LIndexes));
end;

class function TImagingSamples.FlatCases: TArray<TSampleFlatCase>;
  procedure Add(const AName: string; ALength: Integer; AInfoSizeIndex: Integer);
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)].Name := AName;
    Result[High(Result)].Lump := RandomBytes(Cardinal(ALength) + 11, ALength);
    Result[High(Result)].InfoSizeIndex := AInfoSizeIndex;
  end;
begin
  Result := nil;
  Add('flat_64', 4096, 0);
  Add('flat_64x128', 8192, 0);
  Add('flat_128', 16384, 0);
  Add('flat_256', 65536, 0);
  Add('flat_512', 262144, 0);
  Add('flat_1024', 1048576, 0);
  Add('flat_odd_length', 5000, 0);
  Add('flat_empty', 0, 0);
  Add('flat_one_byte', 1, 0);
  Add('flat_63_bytes', 63, 0);
  Add('flat_64_bytes', 64, 0);
  Add('flat_130_bytes', 130, 0);
  Add('flat_4095_bytes', 4095, 0);
  Add('flat_4097_bytes', 4097, 0);
  Add('flat_info_128_full', 65536, 1);
  Add('flat_info_128_exact', 16384, 1);
  Add('flat_info_128_short', 4096, 1);
end;

class function TImagingSamples.ShrinkLengths: TArray<Integer>;
begin
  Result := [4096, 8192, 16384, 65536, 262144, 1048576, 4194304, 16777216, 100, 5000, 0, 12288];
end;

class function TImagingSamples.WipeCases: TArray<TSampleWipeCase>;
  procedure Add(const AName: string; AWidth, AHeight, APitch: Integer; AAlpha, ASeed: Cardinal;
    const ATicks: array of Integer);
  var
    LItem: TSampleWipeCase;
    LIndex: Integer;
  begin
    LItem.Name := AName;
    LItem.Width := AWidth;
    LItem.Height := AHeight;
    LItem.Pitch := APitch;
    LItem.AlphaMask := AAlpha;
    LItem.Seed := ASeed;
    SetLength(LItem.Ticks, Length(ATicks));
    for LIndex := 0 to High(ATicks) do
      LItem.Ticks[LIndex] := ATicks[LIndex];
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := LItem;
  end;
var
  LOnes: array[0..119] of Integer;
  LIndex: Integer;
begin
  Result := nil;
  for LIndex := 0 to High(LOnes) do
    LOnes[LIndex] := 1;
  Add('small_one_tick', 8, 10, 8, 0, 1, LOnes);
  Add('screen_320x200', 320, 200, 320, 0, 2, LOnes);
  Add('screen_640x400', 640, 400, 640, 0, 3, LOnes);
  Add('opengl_320x200', 320, 200, 512, $FF000000, 4, LOnes);
  Add('narrow_1x40', 1, 40, 1, 0, 5, LOnes);
  Add('wide_700x20', 700, 20, 700, 0, 6, LOnes);
  Add('batches', 160, 100, 160, 0, 7, [2, 3, 1, 5, 1, 1, 4, 2, 1, 1, 9, 1, 1, 1, 6, 1, 1, 1, 1, 1,
    2, 2, 2, 2, 2, 2, 2, 2, 7, 1, 30, 1, 100, 1]);
  Add('zero_ticks', 40, 40, 40, 0, 8, [0, 1, 0, 1, 1, 1]);
  Add('width_not_multiple', 333, 120, 340, $FF000000, 9, [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]);
end;

class function TImagingSamples.ScaleCases: TArray<TSampleScaleCase>;
var
  LRandom: TSampleRandom;
  LIndex: Integer;
begin
  LRandom := TSampleRandom.Create(777);
  SetLength(Result, 3000);
  for LIndex := 0 to High(Result) do
  begin
    Result[LIndex].ViewAngle := LRandom.NextCardinal;
    Result[LIndex].NormalAngle := LRandom.NextCardinal;
    Result[LIndex].VisAngle := LRandom.NextCardinal;
    case LIndex mod 4 of
      0: Result[LIndex].Distance := LRandom.NextBelow(2000 * 65536) + 1;
      1: Result[LIndex].Distance := LRandom.NextBelow(64 * 65536) + 1;
      2: Result[LIndex].Distance := LRandom.NextBelow(8 * 65536) - 4 * 65536;
    else
      Result[LIndex].Distance := Integer(LRandom.NextCardinal);
    end;
    Result[LIndex].ProjectionY := (160 + LRandom.NextBelow(400)) * 65536;
    Result[LIndex].MaxScale := 64 * 65536;
    Result[LIndex].Precise := Odd(LIndex shr 1);
  end;
  // the angles that are on the axes
  Result[0].VisAngle := Result[0].ViewAngle;
  Result[1].VisAngle := Result[1].NormalAngle;
  Result[2].VisAngle := Result[2].ViewAngle + $40000000;
  Result[3].VisAngle := Result[3].NormalAngle + $80000000;
end;

class function TImagingSamples.ColorFactors: TArray<Integer>;
begin
  Result := [0, 1, 100, 4096, 16384, 32768, 49152, 65534, 65535, 65536, 70000, -1000];
end;

class function TImagingSamples.LightFactors: TArray<Integer>;
begin
  Result := [0, 1, 1000, 32768, 65535, 65536, 100000, 200000];
end;

class function TImagingSamples.LightAddValues: TArray<Cardinal>;
begin
  Result := [0, 1, 100, 255, 256, 300];
end;

class function TImagingSamples.ColorSamples: TArray<Cardinal>;
var
  LRandom: TSampleRandom;
  LIndex: Integer;
begin
  LRandom := TSampleRandom.Create(4242);
  SetLength(Result, 48);
  Result[0] := 0;
  Result[1] := $00FFFFFF;
  Result[2] := $000000FF;
  Result[3] := $0000FF00;
  Result[4] := $00FF0000;
  Result[5] := $00808080;
  Result[6] := $FF123456;
  Result[7] := $00010101;
  for LIndex := 8 to High(Result) do
    Result[LIndex] := LRandom.NextCardinal and $00FFFFFF;
end;

end.
